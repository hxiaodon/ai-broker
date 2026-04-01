# Trading Engine REST API SLA 可行性评估

**评估日期**: 2026-03-30
**评估人**: trading-engineer
**涉及地理**: 美股 (US) / 港股 (HK)
**参考规范**:
- `docs/specs/research-index.md` 性能指标
- `docs/specs/trading-system.md` 系统架构
- `docs/specs/domains/02-pre-trade-risk.md` 风控流水线

---

## 1. SLA 可行性评估表

| 端点 | 建议 SLA | **评估结论** | 详细理由 | 关键条件 |
|------|---------|-----------|--------|---------|
| **POST /orders** | <500ms P95 | **✓ 可承诺** | 核心处理 <20ms (per research-index.md L143-144)；加网络往返 30-50ms；SLA 宽松度足够 | 1. 风控检查 <5ms P99<br>2. DB 事务 <10ms<br>3. 不阻塞 Kafka 发布 |
| **GET /orders** | <200ms P95 | **✓ 可承诺** | DB 查询 (indexed) <20ms + 组装 <5ms + 网络 30ms = 55-75ms P95 | 1. 订单表需要 (account_id, created_at) 复合索引<br>2. 分页限制 (max 100 rows)<br>3. 高并发(>1000 QPS)需 Redis 缓存 |
| **DELETE /orders/:id** | <500ms P95 | **⚠️ 可承诺但有风险** | FIX 往返延迟 50-200ms（NYSE/NASDAQ <100ms, HKEX <200ms）+ 本地处理 10ms + 网络 30ms = 90-250ms | 1. 设置 FIX 请求超时 400ms<br>2. 建议异步模式：返回 202 Accepted，订单状态通过 WebSocket 推送<br>3. 网络抖动可能导致超时 |
| **GET /positions** | <200ms P95 | **✓ 可承诺** | 持仓查询 <20ms (indexed) + 市价聚合 <10ms (cached) + 计算 <10ms + 网络 30ms = 70-150ms | 1. **市价必须来自本地缓存**（由 Market Data 通过 Kafka 推送）<br>2. 不能远程调用 Market Data 服务<br>3. 持仓表 (account_id) 索引 |
| **GET /portfolio/summary** | <150ms P95 | **✓ 可承诺** | 现金 <2ms + 持仓 <10ms + 市价 <10ms + P&L 计算 <10ms + 网络 30ms = 60-100ms | 1. 现金余额缓存（Fund Transfer 推送）<br>2. 市价缓存（Market Data 推送）<br>3. 昨日市值缓存（每日开盘时快照）<br>4. 不能远程调用下游服务 |

---

## 2. 详细瓶颈分析

### 2.1 POST /orders 瓶颈分解

```
订单提交流程时间分布：

幂等检查 (Redis)     →  1-2ms
  ├─ Redis GET
  └─ 幂等 Key 检查

格式校验            →  1-2ms
  └─ 内存操作，symbol/qty/price 验证

风控流水线 8 道检查  →  5-8ms P99
  ├─ 1. Account Check
  │     风险: 若需远程调用 AMS gRPC → +50-100ms ⚠️
  │     建议: 账户信息缓存到 Redis (TTL 60s)
  │
  ├─ 2. Symbol Check
  │     市值表 (缓存) <1ms
  │
  ├─ 3. BuyingPowerCheck
  │     Redis 读取 (缓存) <1ms
  │
  ├─ 4. PositionLimitCheck
  │     Redis 读取 <1ms
  │
  ├─ 5. OrderRateCheck
  │     Redis 读取 <1ms
  │
  ├─ 6. PDTCheck
  │     Redis 读取 <1ms
  │
  ├─ 7. MarginCheck
  │     内存计算 <1ms
  │
  └─ 8. PostTradeCheck
       内存计算 <1ms

状态转换 + DB 事务 →  5-10ms
  ├─ Order 表 INSERT
  └─ order_events 表 INSERT (Append-Only)

Kafka 事件发布     →  1-2ms (async)
  └─ order.created, order.risk_approved 等

返回响应          →  <1ms

总计 (P99):        ~15-25ms 核心处理 + 30-50ms 网络 RTT = 45-75ms

P95 应该在 40-60ms 范围内，远低于 500ms SLA
```

**关键风险**:
1. **AMS 账户检查** - 如果需要远程调用，+50-100ms（需要缓存）
2. **DB 插入延迟** - 高并发(>1000 orders/s)下可能有锁争用
3. **Kafka 发布** - 若同步等待，+10-50ms（应异步）

---

### 2.2 DELETE /orders/:id 瓶颈分解（撤单最复杂）

```
撤单流程时间分布：

验证请求 + 幂等检查   →  2-3ms
  ├─ Order 状态检查 (可撤销?)
  └─ Redis 幂等 Key 检查

发送 FIX CancelRequest →  2-5ms
  └─ QuickFIX/Go 编码 + 网络发送

等待 FIX CancelResponse  →  **50-300ms** ⚠️⚠️⚠️
  │
  ├─ NYSE/NASDAQ 通常 <100ms
  ├─ HKEX 通常 <200ms
  └─ 网络抖动可能 +100-200ms

状态转换 (OPEN → CANCELLED) →  5ms
  └─ DB 更新 + Kafka 发布

返回响应          →  <1ms

总计 (P95):        ~60-310ms

在 500ms SLA 范围内，但风险较大 ⚠️
```

**风险等级**: 🔴 高
- FIX 往返时间不可控（取决于交易所网络）
- 高并发撤单可能导致队列积压

**建议优化**:
1. **异步撤单模式**
   - 接收撤单请求 → 验证 → 发送 FIX → 立即返回 `202 Accepted`
   - 撤单结果通过 WebSocket 推送给客户端
   - 时间: <50ms

2. **超时处理**
   - FIX 请求超时设为 400ms
   - 超时后返回 202 Accepted，记录待处理
   - 通过重试机制最终确认

---

### 2.3 GET /positions 瓶颈分解

```
持仓查询流程时间分布：

查询持仓列表 (indexed)    →  5-20ms
  ├─ SELECT * FROM positions
  │   WHERE account_id = ?
  │   AND deleted_at IS NULL
  └─ 假设账户有 10-100 个持仓

获取实时市价              →  **5-10ms (cached)** ✓
  │                        **或 50-100ms (remote call)** ✗
  │
  ├─ 如果市价来自本地缓存（Kafka 更新）→ <5ms ✓
  ├─ 如果远程调用 Market Data gRPC   → +50-100ms ✗
  └─ 推荐: 本地缓存 (Redis) + 毫秒级更新

计算持仓市值和P&L        →  5-10ms
  ├─ 对每个持仓：quantity × market_price
  ├─ 对每个持仓：(market_price - cost_price) × quantity
  └─ 都是内存操作，很快

组装 JSON 响应            →  1-2ms

总计 (P95, 有缓存):       ~20-40ms 核心 + 30-50ms 网络 = 50-90ms ✓

总计 (P95, 无缓存):       ~60-120ms 核心 + 30-50ms 网络 = 90-170ms ✓

都在 200ms SLA 范围内
```

**关键条件** (必须满足):
1. ✅ **市价必须本地缓存** - 通过 Kafka `market.quote` topic 实时更新
2. ✅ **不能同步调用 Market Data** - 否则延迟翻倍
3. ✅ **持仓表索引** - (account_id, market) 复合索引

---

### 2.4 GET /portfolio/summary 瓶颈分解

```
账户总资产流程时间分布：

查询账户现金余额        →  1-3ms
  └─ Redis GET account:{id}:cash
     或 SELECT FROM fund_ledger

查询所有持仓            →  5-10ms
  └─ SELECT FROM positions WHERE account_id = ?

获取市价（所有标的）    →  5-10ms (cached)
  └─ 批量从 Redis 读取，不能循环调用

计算总资产              →  3-5ms
  ├─ cash_balance = Redis
  ├─ positions_value = Σ(qty × price)
  ├─ total_assets = cash_balance + positions_value
  └─ 都是内存操作

计算日盈亏              →  5-10ms
  ├─ today_pnl = Σ((market_price - open_price) × qty)
  ├─ 其中 open_price 来自昨日收盘缓存
  └─ 如果缓存丢失，需要 DB 查询 →  +50ms

计算其他指标            →  1-3ms
  ├─ margin_ratio
  ├─ buying_power
  └─ 从 Redis 读取

组装响应                →  1-2ms

总计 (P95, 完全缓存):    ~25-50ms 核心 + 30-50ms 网络 = 55-100ms ✓

总计 (P95, 缺昨日缓存):  ~75-100ms 核心 + 30-50ms 网络 = 105-150ms ✓

都在 150ms SLA 范围内
```

**关键条件** (必须满足):
1. ✅ 现金余额必须缓存到 Redis
2. ✅ 市价必须本地缓存
3. ✅ 昨日收盘价必须每日快照缓存
4. ❌ 不能远程调用任何下游服务

---

## 3. WebSocket 实时推送技术可行性

### 3.1 position.updated 频道

**要求**: 每次市价变动时推送持仓更新

**数据源**: Market Data Kafka `market.quote` topic
- 美股: 每股价变推送 (每秒可能 100+ 条)
- 港股: 每报价变推送 (每秒可能 50+ 条)

**实现方案**:

```
Market Data Service
  ↓ (Kafka market.quote)

Kafka Consumer (Trading Engine)
  ├─ 消费每条 market.quote 事件
  ├─ 解析 symbol
  ├─ 查询相关持仓 (Redis: positions_by_symbol)
  ├─ 计算持仓市值和 P&L
  ├─ 发布 WebSocket position.updated
  └─ 推送到所有在线客户端

预期延迟:
  ├─ Kafka 消费: 5-10ms
  ├─ 持仓查询: 1-2ms (Redis)
  ├─ P&L 计算: 1-2ms
  ├─ WebSocket 推送: 5-10ms
  └─ 总计: ~15-30ms (从市价变动到客户端看到)
```

**可行性**: ✅ 完全可行
- 足够快，市场数据延迟 <50ms 的情况下，客户端感知延迟 <100ms
- 需要 WebSocket 连接管理 (connection pooling, heartbeat)
- 高并发处理: 1000+ 用户 × 100+ 持仓 = 1M+ 消息/s

**风险**:
- 高连接数时 WebSocket 内存占用
- Kafka 消费速度慢于市价发布速度时会积压

---

### 3.2 portfolio.summary 频道

**要求**: 秒级推送账户总资产、日盈亏更新

**数据源**: Position Engine 或 Margin Engine 的聚合结果

**实现方案**:

```
Option A: 基于 market.quote 聚合 (推荐)
Market Data Service
  ↓ (Kafka market.quote)

Kafka Consumer (Trading Engine - Portfolio Aggregator)
  ├─ 消费 market.quote 并去重 (同账户、同秒合并)
  ├─ 每秒产生一个聚合快照
  ├─ 计算 total_assets, day_pnl, margin_ratio
  ├─ 发布 WebSocket portfolio.summary
  └─ 推送到客户端

Option B: 定时计算 (简单但延迟高)
Timer (每秒)
  ├─ 遍历所有在线用户
  ├─ 计算每个用户的 portfolio summary
  ├─ 发布 WebSocket portfolio.summary
  └─ 风险: 用户多时 CPU 占用高

推荐 Option A (基于 Kafka 驱动)
延迟: ~50-200ms (从某笔成交或市价变动到看到 summary 更新)
```

**可行性**: ✅ 可行
- 秒级推送足以满足业务需求
- 与 market.quote 解耦，降低复杂性

**风险**:
- 如果秒级聚合失败，可能出现 summary 延迟更新
- 需要处理用户快速上线/离线时的状态管理

---

## 4. AMS 契约补充需求

### 4.1 GetAccountStatus 返回字段补充

当前假设 AMS 提供的账户信息：

```protobuf
message GetAccountStatusResponse {
  // 现有字段
  string account_id = 1;
  string account_name = 2;
  string status = 3;  // ACTIVE | SUSPENDED | CLOSED

  // ===== 以下为新增字段 =====

  // 4.1 KYC 状态 (用于风控 AccountCheck)
  string kyc_status = 4;
  // 枚举: PENDING | APPROVED | REJECTED | SUSPENDED
  // Trading Engine 风控规则:
  //   - PENDING: 账户不能交易
  //   - APPROVED: 可以交易
  //   - REJECTED: 账户关闭
  //   - SUSPENDED: 账户冻结（可能因为 AML 原因）

  // 4.2 KYC 等级 (用于风控 BuyingPowerCheck, MarginCheck)
  int32 kyc_tier = 5;
  // 值: 1 | 2
  // Tier 1: 基础等级，购买力/保证金额度受限
  // Tier 2: 高级等级，购买力/保证金额度更高
  // 美股: Tier 1 可能限制 <$25K, Tier 2 无限制
  // 港股: 类似分级，由 SFC 指引决定

  // 4.3 账户类型 (用于风控 PDTCheck)
  string account_type = 6;
  // 枚举: CASH | MARGIN
  // CASH: 现金账户，不受 PDT 规则约束
  // MARGIN: 保证金账户，需要执行 PDT 规则

  // 4.4 账户限制标记 (用于风控 PostTradeCheck)
  bool is_restricted = 7;
  // true: 账户受限（可能原因: PDT 冻结, AML 警告, Margin Call 未补缴等）
  // 当 is_restricted = true 时：
  //   - 美股: PDT 日内交易受限 (仅允许 3 次/5天)
  //   - 港股: 可能无交易权限
  //   - 下单时需要给用户明确提示

  // 4.5 (可选) 账户风险评分 (用于风控 PostTradeCheck)
  int32 risk_score = 8;
  // 范围: 0-100
  // 0-30: LOW (正常)
  // 31-70: MEDIUM (警告)
  // 71-100: HIGH (高风险，可能触发人工审核)
}
```

### 4.2 风控检查与 AMS 字段的对应关系

| 风控检查 | 依赖 AMS 字段 | 检查逻辑 |
|---------|-------------|--------|
| **AccountCheck** | kyc_status, is_restricted | ✅ kyc_status == APPROVED && !is_restricted |
| **SymbolCheck** | (无依赖) | 标的是否可交易 (from Market Data) |
| **BuyingPowerCheck** | kyc_tier | Tier 1: 限额较低; Tier 2: 无限制 |
| **PositionLimitCheck** | account_type | MARGIN 允许融资; CASH 仅 settlement 后 |
| **OrderRateCheck** | (无依赖) | 订单频率反操纵检查 |
| **PDTCheck** | account_type, is_restricted | account_type == MARGIN && !is_restricted 才执行 PDT |
| **MarginCheck** | kyc_tier | Tier 等级决定保证金比例 |
| **PostTradeCheck** | risk_score | 高风险账户订单可能需要人工审核 |

### 4.3 建议的 AMS-Trading 缓存策略

```
Trading Engine (gRPC 客户端)
  │
  ├─ 首次查询时: gRPC 调用 AMS GetAccountStatus
  │  ├─ 获取完整账户信息
  │  └─ 存储到 Redis: key = "account:{account_id}:status"
  │     TTL = 60s
  │
  ├─ 后续查询: Redis 读取 (如果 key 存在)
  │  └─ <2ms 延迟
  │
  └─ 缓存失效场景:
     ├─ 用户 KYC 状态变更 (AMS 主动推送或 Kafka 事件)
     ├─ 用户账户被限制 (AMS Webhook)
     └─ 定时过期刷新 (60s TTL)
```

**为什么需要缓存**:
- 如果每次下单都远程调用 AMS，+50-100ms 延迟，导致 POST /orders 从 60ms 变成 150ms
- 缓存后，延迟回到 2ms，SLA 可控

---

## 5. 并发与峰值负载场景分析

### 5.1 正常业务负载 (日间交易)

```
交易时段:
  ├─ 美股: 09:30-16:00 ET (6.5 小时)
  ├─ 港股: 09:30-12:00, 13:00-16:00 HKT (6 小时)

预期负载:
  ├─ 日均订单数: 100,000 (假设 10,000 活跃用户)
  ├─ QPS 峰值: 200-300 orders/s (开盘头 30 分钟)
  ├─ 查询 QPS: 1,000+ (position, portfolio, orders 查询)

系统容量:
  ├─ POST /orders: 目标 1,000 orders/s (research-index.md)
  ├─ GET /positions: 目标 10,000 queries/s (Redis + indexed DB)
  └─ GET /portfolio/summary: 目标 10,000 queries/s
```

### 5.2 性能瓶颈应对

#### 关键优化措施

1. **POST /orders 优化**
   - ✅ 风控 8 道检查串行 → 考虑并行化部分检查 (e.g., Symbol + Position 并行)
   - ✅ DB 事务 → 使用连接池 (最小 20, 最大 100 连接)
   - ✅ 幂等检查 → Redis 集群化，支持 10,000+ QPS
   - ❌ 若 AMS 调用不缓存 → 瓶颈: AMS gRPC 连接饱和

2. **GET /positions 优化**
   - ✅ Redis 本地市价缓存 → Kafka 驱动更新
   - ✅ 订单表索引 → 确保 DB 查询 <20ms
   - ✅ 分页限制 (max 100) → 避免超大结果集

3. **GET /portfolio/summary 优化**
   - ✅ 现金余额 + 市价 + 昨日市值全缓存
   - ✅ 不允许远程调用 → 本地完成所有计算
   - ✅ 限制并发用户数 (e.g., <10K 在线用户)

#### 监控指标

```yaml
SLA 监控:
  POST /orders:
    - P50: <50ms
    - P95: <200ms
    - P99: <500ms
    - 目标 SLA: <500ms P95 ✅

  GET /positions:
    - P50: <50ms
    - P95: <150ms
    - P99: <300ms
    - 目标 SLA: <200ms P95 ✅

  GET /portfolio/summary:
    - P50: <40ms
    - P95: <120ms
    - P99: <200ms
    - 目标 SLA: <150ms P95 ✅

告警阈值:
  - 若 P95 > 1.5 × SLA → 触发告警
  - 若连续 5min 超过 SLA → 降级处理 (返回缓存数据)
```

---

## 6. 一句话结论

**可启动契约协调的条件**：
> Trading Engine 可承诺 POST/GET /orders <500ms/200ms P95、GET /positions/<portfolio/summary> <200ms/<150ms P95，前提是 **(1) 市价必须本地缓存，(2) AMS 账户信息缓存 TTL 60s，(3) 撤单采用异步模式 + WebSocket，(4) 所有表均有必要的数据库索引**；如无法满足这些条件，建议提升 SLA 门槛或实现后再协商。

---

## 7. 后续行动清单

- [ ] **mobile-engineer** 评估建议的 SLA 是否满足用户体验需求
- [ ] **ams-engineer** 评估可否在 GetAccountStatus 中补充 `kyc_status`, `kyc_tier`, `account_type`, `is_restricted` 字段
- [ ] **trading-engineer** 完成数据库索引规划 (见第 8 节)
- [ ] **trading-engineer** 实现 Kafka 驱动的市价缓存更新
- [ ] **trading-engineer** 评估撤单是否采用异步模式或同步等待
- [ ] **devops-engineer** 规划 Redis 集群化、DB 连接池配置
- [ ] 迭代 2-3 轮后，签署最终契约文件

---

## 8. 数据库索引规划

### 8.1 必要的索引

```sql
-- orders 表
CREATE INDEX idx_orders_account_created
  ON orders(account_id, created_at DESC);

CREATE INDEX idx_orders_idempotency
  ON orders(idempotency_key);

-- positions 表
CREATE INDEX idx_positions_account
  ON positions(account_id);

CREATE INDEX idx_positions_account_market
  ON positions(account_id, market);

-- executions 表
CREATE INDEX idx_executions_account_symbol
  ON executions(account_id, symbol);

-- day_trade_counts 表
CREATE UNIQUE INDEX idx_day_trade_counts_unique
  ON day_trade_counts(account_id, trade_date, symbol);
```

### 8.2 查询计划验证

```bash
# 验证查询是否使用索引
EXPLAIN SELECT * FROM orders
  WHERE account_id = ?
  ORDER BY created_at DESC
  LIMIT 100;
# 应使用 idx_orders_account_created

EXPLAIN SELECT * FROM positions
  WHERE account_id = ?;
# 应使用 idx_positions_account
```

---

## Appendix: 架构假设清单

- [ ] Trading Engine 与 Market Data 同进程或相邻节点（网络延迟 <5ms）
- [ ] Redis 集群就地部署（延迟 <1ms）
- [ ] MySQL 主从配置，读副本用于查询（延迟 <5ms）
- [ ] Kafka 消费的 market.quote 延迟 <50ms
- [ ] FIX 连接使用 TLS，但无代理（直连交易所）
- [ ] 预期 POST /orders 并发数 <300/s；查询并发 <1000/s
