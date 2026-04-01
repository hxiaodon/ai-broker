# 交易引擎REST API SLA — 5个技术条件完整实现规划

**文档版本**: v1.0
**编制日期**: 2026-03-30
**计划完成日期**: 2026-05-11
**剩余时间**: 42 天
**优先级**: 🔴 关键路径（上线拦路虎）

---

## 执行摘要

**结论**: ✅ **完全可行，42天充足，前提是严格遵循依赖序列和缓存策略**

本文为5个关键技术条件提供了分层的实现方案、DB变更、监控指标和时间表。通过关键路径法分析，**最长链路是市价缓存消费端（15天）+ 撤单异步模式（8天）= 23天**，留有19天缓冲用于集成测试、性能验证和上线准备。

| 条件 | 工作量 | 优先级 | 依赖关系 |
|------|-------|-------|--------|
| 1️⃣ 市价本地缓存 | 15天 | 最高 | 无（可并行） |
| 2️⃣ AMS账户缓存 | 6天 | 高 | AMS 补充4字段 |
| 3️⃣ 现金余额+昨日市值缓存 | 5天 | 高 | Fund Transfer 推送接口 |
| 4️⃣ DB索引优化 | 3天 | 中 | 无 |
| 5️⃣ 撤单异步模式 | 8天 | 中高 | 市价缓存 + WebSocket 基础设施 |

**关键路径**: 条件1 (15天) → 条件5 (8天) = 23天
**总项目时间**: 23天 (关键路径) + 19天 (缓冲/集成/验证)

---

# 第一部分：5个条件详细设计方案

## 条件1：市价本地缓存 (Kafka → Redis) ⭐⭐⭐ 最高优先级

### 1.1 高层架构

```
Market Data Service (上游)
  ↓ Kafka Topic: market.quote
    - schema: {symbol, bid, ask, last, timestamp}
    - 美股: 每秒最多 100+ 条
    - 港股: 每秒最多 50+ 条

Trading Engine Kafka Consumer (我们的部分)
  ├─ ConsumerGroup: "trading-engine-quote-cache"
  ├─ 并发: 8-16 个消费者（按分区数）
  ├─ 消费模式: at-least-once + 幂等处理
  │  └─ 重复消息通过 (symbol + timestamp) 去重
  │
  └─ 处理逻辑:
     ├─ 1. 解析 Kafka 消息 → Quote struct
     ├─ 2. 验证数据完整性（symbol 格式、价格正数）
     ├─ 3. 在 Redis 中更新: "quote:{symbol}" → {bid, ask, last, timestamp}
     ├─ 4. 同时更新: "quote:all_symbols" → Set (用于快速查找)
     ├─ 5. 发布 Redis Pub/Sub "quote-updated" 通知
     └─ 6. 定期清理过期数据（>5分钟无更新的行情）

Redis 数据结构:
  ├─ String: quote:AAPL → {"bid": 150.25, "ask": 150.26, "last": 150.25, "ts": 1711868400123}
  ├─ String: quote:0700.HK → {"bid": 76.50, "ask": 76.55, "last": 76.50, "ts": ...}
  ├─ Set: quote:all_symbols → {AAPL, MSFT, TSLA, 0700.HK, ...}
  └─ Set: quote:us_symbols, quote:hk_symbols (分市场快速查找)

TTL 策略:
  ├─ quote:{symbol}: TTL = 5 分钟
  │  └─ 若5分钟无更新，该报价被认为陈旧，API 查询时返回缓存但标记为 stale: true
  ├─ quote:all_symbols: TTL = 永不过期（维护交易池）
  └─ 每日开盘前: 清空所有 quote:{symbol}，准备新一天数据
```

### 1.2 API 契约（内部使用，Trading Engine 内部调用）

```go
// pkg/quote/cache.go

type QuoteCache interface {
    // 获取单个标的的报价
    GetQuote(ctx context.Context, symbol string) (*Quote, error)

    // 批量获取报价（用于 GET /positions）
    GetQuotes(ctx context.Context, symbols []string) (map[string]*Quote, error)

    // 检查是否有缓存（可用于降级判断）
    HasQuote(symbol string) bool

    // 订阅报价变更事件（用于 WebSocket 推送）
    SubscribeQuoteUpdates(symbol string) <-chan *Quote
}

type Quote struct {
    Symbol    string    // e.g., "AAPL" or "0700.HK"
    Bid       decimal.Decimal
    Ask       decimal.Decimal
    Last      decimal.Decimal
    Timestamp int64     // Unix milliseconds
    Stale     bool      // true if >5min old
}
```

### 1.3 Kafka 消费端实现关键点

```yaml
KafkaConsumer Configuration:
  Topic: "market.quote"
  ConsumerGroup: "trading-engine-quote-cache"

  Partition Strategy:
    - 按 symbol hash 分配到不同分区
    - Trading Engine 部署 N 个 Pod，自动分配分区
    - 建议至少 8 个分区以支持并发消费

  Offset Management:
    - 使用 Kafka 内部存储（__consumer_offsets）
    - 自动提交：disabled（手动 commit after success）
    - CommitInterval: 10s（避免过于频繁的 commit）

  Error Handling:
    - 消息解析失败 → DLQ (dead-letter-queue) + 告警
    - Redis 写入失败 → 重试 3 次，后退式延迟
    - 若连续 5 条消息失败 → 暂停消费，告警
    - 网络恢复后自动重新消费

Performance Tuning:
  - FetchMinBytes: 1024 (1KB) — 低延迟优先
  - FetchMaxWaitMs: 100ms
  - MaxConcurrentFetches: 16
  - 预期吞吐量: 10,000 quotes/s
  - 预期消费延迟: 50-100ms (from publish to Redis)
```

### 1.4 DB Schema 变更（无需变更，纯 Redis 缓存）

**无 DB 变更**。行情缓存完全存储在 Redis，不持久化到 DB。

### 1.5 监控与告警

```yaml
监控指标:
  1. kafka_quote_messages_consumed_total
     - Label: symbol, market (US|HK)
     - 告警: 连续 2 分钟无消息（交易时段）→ 高

  2. quote_cache_redis_latency_ms (p50, p95, p99)
     - 预期: p95 < 2ms
     - 告警: p95 > 5ms → 中

  3. quote_cache_stale_count
     - 统计: 返回给 API 的陈旧报价数
     - 告警: >5% 的查询返回陈旧数据 → 中

  4. quote_cache_hit_rate
     - 缓存命中率 (应接近 100%)
     - 告警: <95% → 低

  5. kafka_consumer_lag
     - Kafka 消费延迟（offset lag）
     - 告警: >10000 条消息积压 → 中

  6. quote_cache_dlq_messages
     - DLQ 中的消息数
     - 告警: >100 条 → 高

告警规则:
  # 行情数据丢失
  - name: MarketQuoteDataLoss
    expr: rate(quote_cache_dlq_messages_total[5m]) > 0.1
    severity: critical
    action: 页面告警，Engineering On Call

  # 缓存延迟过高
  - name: QuoteCacheLatencyHigh
    expr: quote_cache_redis_latency_p95 > 5
    severity: warning
    action: 降级通知 (返回磁盘缓存或陈旧数据)

  # 消费积压
  - name: KafkaConsumerLagHigh
    expr: kafka_consumer_lag > 50000
    severity: high
    action: 自动扩展消费者 Pod

Dashboards:
  - Grafana Panel: Quote Cache Overview
    - 消费 QPS
    - 缓存命中率
    - Redis 延迟分布 (p50/p95/p99)
    - DLQ 消息数
    - 在线 symbol 计数 (US + HK)
```

### 1.6 工作量估算

| 任务 | 时间 | 说明 |
|------|------|------|
| Kafka Consumer 框架搭建 | 3天 | 基于现有 Kafka 基础设施 |
| 解析 market.quote schema | 1天 | 与 Market Data 服务协调 |
| Redis 数据结构设计 + 实现 | 2天 | TTL、去重、清理逻辑 |
| 错误处理 + DLQ 集成 | 2天 | 消息丢失风险缓解 |
| 性能测试 + 优化 | 3天 | 吞吐量 10K+/s，延迟 <100ms |
| 监控告警 + Grafana | 2天 | 5个关键指标 + 2个仪表盘 |
| 集成测试 + 冒烟测试 | 2天 | 与风控、持仓系统联调 |
| **总计** | **15天** | 包含 10% 缓冲 |

---

## 条件2：AMS 账户信息缓存 (TTL 60s) + 补充 4 字段

### 2.1 高层架构

```
AMS Service (上游，需补充字段)
  ├─ gRPC API: GetAccountStatus()
  │  └─ 返回: account_status, kyc_status, kyc_tier, account_type, is_restricted
  │
Trading Engine (缓存层)
  ├─ 首次查询 → gRPC 远程调用 AMS
  ├─ 缓存到 Redis: "account:{account_id}:status"
  ├─ TTL = 60s (平衡新鲜度与性能)
  │
  ├─ 事件驱动缓存失效 (可选，高级)
  │  ├─ Kafka Topic: "ams.account_changed"
  │  └─ 当 KYC 状态、账户限制变更时，发送事件
  │     Trading Engine 消费 → 立即清理缓存
  │
  └─ 使用场景:
     ├─ POST /orders 前: 检查 kyc_status + is_restricted
     ├─ Risk Engine 风控检查: 使用 kyc_tier, account_type
     └─ 可容忍的缓存延迟: 最多 60s 内的账户变更未反映
```

### 2.2 需要补充的 4 字段（AMS 侧）

这是**对 AMS 的强制需求**，需要在 AMS PRD 中明确记录。

```protobuf
// ams/api/v1/account.proto

message GetAccountStatusResponse {
  // 现有字段
  string account_id = 1;
  string account_name = 2;
  string status = 3;

  // ===== 必须新增字段 (Trading Engine 强制依赖) =====

  // 4. KYC 状态 (Trading Engine 风控 Gate #1)
  string kyc_status = 4;
  // enum: PENDING | APPROVED | REJECTED | SUSPENDED
  // Trading 规则:
  //   - PENDING/REJECTED/SUSPENDED → 不能交易
  //   - APPROVED → 可以交易

  // 5. KYC 等级 (Trading Engine BuyingPower 计算)
  int32 kyc_tier = 5;
  // 值: 1 | 2
  // 1: 基础等级，购买力限额 (e.g., <$25K)
  // 2: 高级等级，无限制

  // 6. 账户类型 (Trading Engine PDT 规则)
  string account_type = 6;
  // enum: CASH | MARGIN
  // CASH: 现金账户，不受 PDT 规则
  // MARGIN: 保证金账户，受 PDT 规则

  // 7. 账户限制标记 (Trading Engine 综合检查)
  bool is_restricted = 7;
  // true: 账户受限 (PDT 冻结、AML 警告、Margin Call 未补缴等)
  // false: 账户无限制
}
```

### 2.3 缓存策略与失效机制

```yaml
缓存策略:
  Key: "account:{account_id}:status"
  Value: JSON 序列化的 GetAccountStatusResponse
  TTL: 60 秒

  缓存击穿防护 (Cache Stampede):
    - 使用 Single Entrant Locking Pattern
    - 当多个请求同时缓存 miss 时，只有第一个进行 AMS gRPC 调用
    - 其他请求等待第一个的结果（max wait = 100ms）
    - 若 gRPC 失败，允许返回上一次缓存的值（soft TTL）

缓存失效触发机制:
  Option A: 基于 TTL（简单，推荐 Phase 1）
    - 每 60s 自动过期
    - 每次风控检查时，若缓存 miss → 远程调用 AMS

  Option B: 事件驱动（复杂，推荐 Phase 2）
    - AMS 发布 Kafka Topic: "ams.account_changed"
    - schema: {account_id, change_type, timestamp}
    - change_type: KYCSATUS_CHANGED | RESTRICTION_ADDED | RESTRICTION_REMOVED
    - Trading Engine 消费 → 立即 REVOKE Redis key
    - 优点: 账户变更立即反映
    - 缺点: 增加 AMS-Trading 耦合度

建议:
  - Phase 1 (当前): TTL-based (简单快速)
  - Phase 2 (后续): 补充事件驱动 (可选优化)
```

### 2.4 风控检查中使用 AMS 缓存的示例

```go
// internal/risk/checks/account_check.go

type AccountCheck struct {
    accountCache *cache.AccountStatusCache
    amsClient    ams.AccountServiceClient
}

func (c *AccountCheck) Execute(ctx context.Context, order *Order) *Result {
    // 1. 尝试从 Redis 缓存读取
    cachedStatus, err := c.accountCache.Get(ctx, order.AccountID)
    if err != nil {
        // 缓存 miss 或过期
        cachedStatus, err = c.amsClient.GetAccountStatus(ctx, order.AccountID)
        if err != nil {
            // AMS 调用失败
            return &Result{
                Approved: false,
                Reason:   fmt.Sprintf("AMS service unavailable: %v", err),
            }
        }
        // 写回缓存 (TTL 60s)
        c.accountCache.Set(ctx, order.AccountID, cachedStatus, 60*time.Second)
    }

    // 2. 检查 KYC 状态
    if cachedStatus.KycStatus != "APPROVED" {
        return &Result{
            Approved: false,
            Reason:   fmt.Sprintf("KYC status is %s, trading not allowed", cachedStatus.KycStatus),
        }
    }

    // 3. 检查账户限制
    if cachedStatus.IsRestricted {
        return &Result{
            Approved: false,
            Reason:   "Account is restricted (possible PDT lock or AML flag)",
        }
    }

    // 通过
    return &Result{Approved: true}
}
```

### 2.5 DB Schema 变更（无需变更）

**无 DB 变更**。缓存纯 Redis 操作。

### 2.6 监控与告警

```yaml
监控指标:
  1. ams_cache_hit_rate (%)
     - 预期: >95%（说明大部分请求命中缓存）
     - 告警: <90% → 可能存在大量新账户

  2. ams_gRPC_latency_ms (p50, p95, p99)
     - 预期: p95 < 100ms
     - 告警: p95 > 200ms → AMS 性能下降

  3. ams_gRPC_error_rate (%)
     - 预期: <0.1%
     - 告警: >1% → AMS 故障

  4. account_restriction_changes_per_minute
     - 统计: 限制状态变更事件
     - 告警: >10 changes/min → 异常

  5. cache_stampede_events
     - 缓存击穿事件计数
     - 告警: >100/min → 考虑增加 TTL

告警规则:
  - name: AMSServiceLatencyHigh
    expr: ams_grpc_latency_p95 > 200
    severity: warning
    action: 告知 AMS team，考虑 fallback

  - name: AccountCacheHitRateLow
    expr: ams_cache_hit_rate < 90
    severity: info
    action: 分析是否合理（新账户激增）

Dashboards:
  - Grafana Panel: AMS Cache Performance
    - 缓存命中率
    - gRPC 延迟分布
    - 错误率
    - 限制变更频率
```

### 2.7 工作量估算

| 任务 | 时间 | 说明 |
|------|------|------|
| AMS 需求协调（补充4字段） | 2天 | 与 AMS team 确认，修改 proto |
| Trading Engine 缓存层实现 | 2天 | Redis 缓存、Single Entrant Lock、TTL |
| 风控集成（8道检查接入缓存） | 1天 | 修改 Risk Engine 依赖 |
| 监控告警 | 1天 | 5个指标 + Grafana 面板 |
| **总计** | **6天** | 需要 AMS 完成4字段补充 |

---

## 条件3：现金余额 + 昨日市值缓存

### 3.1 高层架构

```
Fund Transfer Service (上游)
  ├─ 每笔入金/出金 → Kafka Topic: "fund.balance_changed"
  │  └─ schema: {account_id, new_balance, balance_change, timestamp}
  │
  └─ 每日收盘后 (16:30 ET / 16:00 HKT)
     └─ Kafka Topic: "fund.daily_snapshot"
        └─ schema: {account_id, date, closing_balance, holdings_value}

Trading Engine (缓存层)
  │
  ├─ 消费 "fund.balance_changed"
  │  ├─ 更新 Redis: "account:{account_id}:cash_balance"
  │  └─ TTL: 永不过期（由事件驱动）
  │
  ├─ 消费 "fund.daily_snapshot"
  │  ├─ 计算昨日市值：前一交易日的 holdings_value
  │  ├─ 存储 Redis: "account:{account_id}:yesterday_holdings_value"
  │  └─ TTL: 7 天（保留最近7个交易日快照）
  │
  └─ GET /portfolio/summary 使用这两个缓存:
     ├─ 现金余额: Redis GET "account:{account_id}:cash_balance"
     ├─ 昨日市值: Redis GET "account:{account_id}:yesterday_holdings_value"
     ├─ 今日市值: 实时计算 (Σ quantity × market_price)
     └─ 今日盈亏: today_holdings_value - yesterday_holdings_value

Data Flow:
  出金请求 ────────────► Fund Transfer Service ──┐
                                                  │
                         ┌───────────────────────┘
                         │ Kafka: fund.balance_changed
                         ▼
                   Trading Engine
                   (Quote Cache)
                         │
                   Redis 更新:
                   account:{id}:cash_balance
                         │
                   GET /portfolio/summary 调用时:
                         │
                      ┌─┴──────────────────────────┐
                      │                             │
              ┌──────▼──────┐          ┌──────────▼─────────┐
              │ Redis GET   │          │ 实时计算持仓市值   │
              │ cash_balance│          │ (qty × market_price)
              └──────┬──────┘          └──────────┬─────────┘
                     │                            │
                     │      ┌────────────────────┘
                     │      │
                  ┌──┴──────▼──────┐
                  │ 总资产 = cash   │
                  │   + 持仓市值    │
                  │                │
                  │ 昨日市值（缓存）
                  │ 今日盈亏        │
                  └────────────────┘
```

### 3.2 Redis 数据结构

```yaml
String 类型:
  account:{account_id}:cash_balance
    - value: 现金余额（Decimal 序列化为 string）
    - example: "50000.00"
    - TTL: 永不过期（由事件驱动更新）
    - 更新频率: 每笔出入金后立即更新

  account:{account_id}:yesterday_holdings_value
    - value: 昨日持仓市值快照
    - example: "125000.50"
    - TTL: 7 天（保留最近7个交易日）
    - 更新频率: 每日开盘前更新（前一交易日收盘数据）

Hash 类型 (可选扩展):
  account:{account_id}:holdings_history
    - field: "2026-03-28", value: "125000.50"
    - field: "2026-03-27", value: "123500.00"
    - ...
    - TTL: 7 天
    - 用于前端展示 7 日持仓趋势图
```

### 3.3 事件处理逻辑

```yaml
消费 "fund.balance_changed" 事件:
  │
  ├─ 验证事件完整性
  │  ├─ account_id 非空
  │  ├─ new_balance >= 0
  │  └─ timestamp 有效
  │
  ├─ 在 Redis 中更新现金余额
  │  ├─ SET "account:{account_id}:cash_balance" "{new_balance}"
  │  ├─ 无 TTL（永不过期）
  │  └─ 成功后 → RPUSH 到 ACL (append-only change log)
  │
  ├─ 发布 Redis Pub/Sub "account-balance-updated:{account_id}"
  │  └─ WebSocket 推送层订阅此频道
  │
  └─ 错误处理:
     ├─ Redis 写入失败 → DLQ + 告警
     └─ 幂等处理 (通过 Kafka offset tracking)

消费 "fund.daily_snapshot" 事件:
  │
  ├─ 事件仅在每日收盘后发送
  │  └─ 触发条件: 美股 16:30 ET OR 港股 16:00 HKT
  │
  ├─ 提取上一交易日的 holdings_value
  │  └─ schema: {account_id, date, holdings_value, cash_balance}
  │
  ├─ 在 Redis 中存储:
  │  ├─ SET "account:{account_id}:yesterday_holdings_value" "{holdings_value}"
  │  ├─ HSET "account:{account_id}:holdings_history" "{date}" "{holdings_value}"
  │  ├─ TTL: 7 天
  │  └─ 备注: 这个值在整个交易日内不变（昨日收盘价 fix 不变）
  │
  ├─ 发布 Redis Pub/Sub "account-summary-updated:{account_id}"
  │  └─ WebSocket 推送层订阅此频道 → 推送新的 portfolio summary
  │
  └─ 错误处理:
     ├─ 如果某个账户的 snapshot 处理失败
     └─ → 降级: 使用上上个交易日的数据（如果有） + 告警

备注: 昨日市值为什么不能在 GET /portfolio/summary 时动态计算?
  1. 需要 7 日内所有成交记录 + 企业行动处理 → 数据库查询复杂
  2. 性能瓶颈: 若每次 API 调用都计算 → P95 可能 >200ms
  3. 使用缓存快照 → 保证 <150ms SLA 的必要条件
  4. 日结快照通常由后端 Settlement Engine 计算，结果可靠
```

### 3.4 DB Schema 变更（无需变更）

**无 DB 变更**。缓存纯 Redis 操作。

### 3.5 监控与告警

```yaml
监控指标:
  1. fund_balance_updated_events_per_minute
     - 统计: 收到的 fund.balance_changed 事件数
     - 预期: 出金时段 (9:30-16:00) 有一定频率
     - 告警: 若预期中零事件 → 可能 Fund Transfer 故障

  2. cash_balance_cache_freshness_max_age_seconds
     - 统计: 缓存的最大年龄
     - 预期: <30s（最后一次更新距离现在 <30s）
     - 告警: >5min → Fund Transfer 推送中断

  3. daily_snapshot_events_received
     - 统计: 每日接收的 fund.daily_snapshot 事件数
     - 预期: 每天 1 次（开盘前）
     - 告警: 若某天未收到 → 高优先级告警

  4. cash_balance_redis_latency_ms
     - 预期: <1ms
     - 告警: >5ms → Redis 性能下降

  5. portfolio_summary_cache_hit_rate (%)
     - 预期: >98% (几乎所有查询命中)
     - 告警: <95% → 分析原因

告警规则:
  - name: FundBalanceCacheMissing
    expr: cash_balance_cache_freshness_max_age > 300
    severity: high
    action: 告知 Fund Transfer team，考虑手动补充

  - name: DailySnapshotMissing
    expr: daily_snapshot_events_received == 0 AND time() > "09:00"
    severity: critical
    action: 页面告警，Engineering On Call

  - name: PortfolioSummaryLatencyHigh
    expr: portfolio_summary_api_latency_p95 > 200
    severity: warning
    action: 检查缓存命中率、Redis 延迟

Dashboards:
  - Grafana Panel: Fund & Holdings Cache
    - 出金事件频率
    - 现金余额缓存新鲜度
    - 昨日持仓值缓存
    - Redis 操作延迟
```

### 3.6 工作量估算

| 任务 | 时间 | 说明 |
|------|------|------|
| Fund Transfer 事件契约协商 | 1天 | balance_changed + daily_snapshot schema |
| Kafka 消费端实现 | 2天 | 事件解析、幂等处理、错误处理 |
| Redis 缓存写入 + 过期管理 | 1天 | TTL、历史记录维护 |
| GET /portfolio/summary 集成 | 1天 | 调用缓存计算总资产、日盈亏 |
| **总计** | **5天** | 需要 Fund Transfer 完成事件推送 |

---

## 条件4：DB 索引优化（5个必要索引）

### 4.1 索引设计表

| 表 | 索引名 | 列 | 说明 | 优先级 |
|----|----|-----|-----|--------|
| `orders` | `idx_orders_account_created` | `(account_id, created_at DESC)` | GET /orders 查询 | P0 |
| `orders` | `idx_orders_idempotency` | `(idempotency_key)` | 幂等性检查 | P0 |
| `positions` | `idx_positions_account` | `(account_id)` | GET /positions 查询 | P0 |
| `positions` | `idx_positions_account_market` | `(account_id, market)` | 市场分组查询 | P1 |
| `day_trade_counts` | `idx_day_trade_counts_unique` | `UNIQUE (account_id, trade_date, symbol)` | PDT 检查 + 防重 | P0 |

### 4.2 完整索引 SQL

```sql
-- 注意: MySQL 8.0 语法，非 PostgreSQL

-- orders 表索引
ALTER TABLE orders
ADD INDEX idx_orders_account_created (account_id, created_at DESC);

ALTER TABLE orders
ADD INDEX idx_orders_idempotency (idempotency_key);

-- positions 表索引
ALTER TABLE positions
ADD INDEX idx_positions_account (account_id);

ALTER TABLE positions
ADD INDEX idx_positions_account_market (account_id, market);

-- day_trade_counts 表索引
ALTER TABLE day_trade_counts
ADD UNIQUE INDEX idx_day_trade_counts_unique (account_id, trade_date, symbol);
```

### 4.3 查询执行计划验证

```sql
-- 验证 GET /orders 使用了复合索引
EXPLAIN SELECT * FROM orders
WHERE account_id = 'acc-123'
ORDER BY created_at DESC
LIMIT 100;

预期输出:
  key: idx_orders_account_created ✓
  rows: ~100 ✓
  Extra: Using index

---

-- 验证 GET /positions 使用了索引
EXPLAIN SELECT * FROM positions
WHERE account_id = 'acc-123';

预期输出:
  key: idx_positions_account ✓
  rows: ~10-100 (平均持仓数)
  Extra: (无额外计算)

---

-- 验证 PDT 检查的唯一性约束
EXPLAIN SELECT * FROM day_trade_counts
WHERE account_id = 'acc-123' AND trade_date = '2026-03-30' AND symbol = 'AAPL';

预期输出:
  key: idx_day_trade_counts_unique ✓
  rows: 1 (精确匹配)
```

### 4.4 性能基准测试（迁移前后）

```bash
# 使用 sysbench 或 mysqlslap 模拟高并发查询

命令:
mysqlslap --concurrency=100 \
  --iterations=10 \
  --query="SELECT * FROM orders WHERE account_id = 'acc-123' ORDER BY created_at DESC LIMIT 100;"

预期结果:
  迁移前 (无索引):
    - 平均响应时间: 150-300ms
    - 扫描行数: 100,000+ (全表扫描)
    - 吞吐量: 50-100 QPS

  迁移后 (有索引):
    - 平均响应时间: 10-20ms ✓ (10-15倍提升)
    - 扫描行数: ~100 (精确 seek)
    - 吞吐量: 1,000+ QPS ✓ (10-20倍提升)
```

### 4.5 索引维护策略

```yaml
实时监控:
  1. 索引碎片检查 (每周)
     ```sql
     SELECT object_name, count_read, count_write, count_delete, count_update
     FROM performance_schema.table_io_waits_summary_by_index_usage
     WHERE object_name IN ('orders', 'positions', 'day_trade_counts');
     ```

  2. 慢查询日志 (启用)
     ```sql
     SET GLOBAL slow_query_log = 'ON';
     SET GLOBAL long_query_time = 0.2;  -- 200ms 以上的查询记录
     ```

  3. 索引大小监控
     ```sql
     SELECT table_name, index_name, stat_value * @@innodb_page_size / 1024 / 1024 AS size_mb
     FROM mysql.innodb_index_stats
     WHERE stat_name = 'size';
     ```

碎片整理 (每月或需要时):
  ```sql
  -- 使用 OPTIMIZE TABLE 重建索引（可能导致表锁）
  OPTIMIZE TABLE orders;  -- 在低流量时段执行

  -- 或使用 pt-online-schema-change（Percona Toolkit）
  pt-online-schema-change --alter="ENGINE=InnoDB" D=trading,t=orders
  ```

索引变更流程 (非常重要):
  1. 开发环境验证 (sysbench 基准测试)
  2. 灰度环境验证 (1 个副本 Pod)
  3. 生产环境上线 (分步骤，从 read replicas 开始)
     - 先在 read replicas 上 CREATE INDEX
     - 等待索引创建完成 (监控 DDL 延迟)
     - 主库上 CREATE INDEX (设置超时机制)
     - 监控索引创建期间的慢查询
```

### 4.6 DB Schema 变更脚本

使用 Goose 数据库迁移框架：

```go
// src/migrations/00008_add_trading_indexes.sql

-- +goose Up
ALTER TABLE orders
ADD INDEX idx_orders_account_created (account_id, created_at DESC);

ALTER TABLE orders
ADD INDEX idx_orders_idempotency (idempotency_key);

ALTER TABLE positions
ADD INDEX idx_positions_account (account_id);

ALTER TABLE positions
ADD INDEX idx_positions_account_market (account_id, market);

ALTER TABLE day_trade_counts
ADD UNIQUE INDEX idx_day_trade_counts_unique (account_id, trade_date, symbol);

-- +goose Down
ALTER TABLE orders DROP INDEX idx_orders_account_created;
ALTER TABLE orders DROP INDEX idx_orders_idempotency;
ALTER TABLE positions DROP INDEX idx_positions_account;
ALTER TABLE positions DROP INDEX idx_positions_account_market;
ALTER TABLE day_trade_counts DROP INDEX idx_day_trade_counts_unique;
```

### 4.7 工作量估算

| 任务 | 时间 | 说明 |
|------|------|------|
| 索引设计 + EXPLAIN 分析 | 1天 | 确认各索引有效性 |
| Goose 迁移脚本编写 | 0.5天 | 包含 Up/Down |
| 灰度环境测试 + 基准测试 | 1.5天 | 模拟高并发，验证性能提升 |
| **总计** | **3天** | 无依赖，可并行进行 |

---

## 条件5：撤单异步模式或 FIX 超时 400ms

### 5.1 两个方案对比

| 维度 | 异步模式 (推荐) | 同步超时 400ms (备选) |
|------|----------------|------------------|
| **API 响应时间** | <50ms (202 Accepted) ✓✓✓ | 90-250ms (200 OK) ✓ |
| **SLA 达成难度** | 简单 | 困难（网络抖动风险） |
| **用户体验** | 实时 WebSocket 推送通知 | 立即获得响应，但不知道交易所结果 |
| **客户端复杂度** | 高（需要 WebSocket）| 低（简单 HTTP） |
| **服务端实现** | 中等（需要 WebSocket 基础） | 简单（改改超时） |
| **故障容错** | 好（异步重试）| 差（超时后失败） |
| **推荐** | ✅ Phase 1-2 | ❌ 仅作 fallback |

### 5.2 异步撤单模式详细设计

```
DELETE /orders/{order_id} (同步入口)
  │
  ├─ 1. 验证 (5ms)
  │  ├─ 订单是否存在
  │  ├─ 状态是否可撤销 (PENDING / OPEN)
  │  └─ 是否属于当前用户
  │
  ├─ 2. 发送撤单请求给 FIX Engine (异步)
  │  ├─ Enqueue: {order_id, cancel_timestamp}
  │  ├─ 发送 CancelRequest → 交易所
  │  └─ 监听 CancelResponse
  │
  ├─ 3. 立即返回 202 Accepted (30ms)
  │  └─ Response: {order_id, status: "CANCEL_PENDING"}
  │
  └─ 4. 后续流程 (异步，无阻塞)
     │
     ├─ FIX 接收 CancelResponse (50-300ms)
     │  └─ Kafka: order.cancelled event
     │
     ├─ OMS 消费此事件
     │  └─ 更新 order.status = CANCELLED
     │
     ├─ Mobile WebSocket 推送
     │  └─ channel: "order.{order_id}.status_changed"
     │  └─ payload: {status: "CANCELLED", cancelled_at, reason}
     │
     └─ 用户 App 收到推送 (在线时)
        └─ 显示确认通知 (交易所已确认撤单)

总响应时间: ~30ms (P95 < 50ms) ✓✓✓ 远低于 500ms SLA
```

### 5.3 异步撤单的消息流

```yaml
1. DELETE /orders/{order_id} (REST API)
   │
   ├─ 验证 + 权限检查 (5ms)
   │
   ├─ Enqueue Cancel Command to Redis Queue
   │  └─ Key: "cancel_queue"
   │  └─ Value: {order_id, account_id, timestamp, idempotency_key}
   │  └─ 确保幂等: 使用 idempotency_key 防重复
   │
   └─ Return 202 Accepted (30ms)
      └─ Response: {
           order_id: "ord-123",
           status: "CANCEL_PENDING",  // 客户端需识别此状态
           message: "Cancel request submitted. Awaiting exchange confirmation."
         }

2. Cancel Worker (后台 goroutine)
   │
   ├─ 消费 Redis Queue (BLPOP)
   │
   ├─ 发送 FIX CancelRequest
   │  └─ QuickFIX/Go → Exchange
   │
   ├─ 等待 ExecutionReport (FIX CancelResponse) (50-300ms)
   │  │ 可能的结果:
   │  ├─ CancelAck (ClOrdID, CancelledQty) → 撤单成功
   │  ├─ CancelReject (reason) → 撤单失败 (订单已成交)
   │  └─ Timeout (400ms) → 视为失败，记录待处理
   │
   └─ 发布 Kafka: order.cancel_response
      └─ schema: {order_id, success, reason, cancelled_at}

3. OMS 消费 order.cancel_response
   │
   ├─ 若 success = true
   │  ├─ UPDATE orders SET status = 'CANCELLED' WHERE order_id = ?
   │  ├─ INSERT INTO order_events (event_type = 'CANCELLED', ...)
   │  └─ 发布 Kafka: order.cancelled
   │
   └─ 若 success = false
      ├─ UPDATE orders SET cancel_attempt_count += 1
      ├─ 发布 Kafka: order.cancel_failed
      └─ 若尝试 >= 3 次 → 标记为异常，人工审核

4. Position/Settlement Engine
   │
   └─ 消费 order.cancelled
      ├─ 若订单未成交 → 无操作
      └─ 若订单部分成交 → 结算部分成交部分
         └─ 发布 Kafka: settlement.event

5. WebSocket 推送层
   │
   └─ 消费 order.cancelled + order.cancel_failed
      ├─ 查询订单详情
      ├─ 发布 WebSocket 频道: "order.{order_id}.status_changed"
      └─ 推送给在线客户端
         └─ payload: {
              order_id, new_status, cancelled_qty, reason, cancelled_at
            }
```

### 5.4 异步撤单的数据库表变更

```sql
-- 增加两个字段到 orders 表，用于追踪异步撤单状态

ALTER TABLE orders
ADD COLUMN cancel_status VARCHAR(32) DEFAULT 'NONE'
COMMENT 'NONE | PENDING | SUCCESS | FAILED | PARTIAL';

ALTER TABLE orders
ADD COLUMN cancel_attempt_count INT DEFAULT 0
COMMENT '撤单尝试次数，用于防止无限重试';

ALTER TABLE orders
ADD COLUMN last_cancel_attempt_at DATETIME(3) DEFAULT NULL
COMMENT '最后一次撤单尝试时间';

ALTER TABLE orders
ADD COLUMN cancel_reason VARCHAR(255) DEFAULT NULL
COMMENT '撤单失败原因 (e.g., "Order already filled")';

-- 索引（便于查询待处理撤单）
ALTER TABLE orders
ADD INDEX idx_orders_cancel_status (account_id, cancel_status);
```

### 5.5 FIX 超时 400ms 的同步模式（备选）

如果由于某些原因必须采用同步模式：

```go
// internal/fix/engine.go

const (
    CancelTimeout = 400 * time.Millisecond  // 400ms 最大等待
)

func (e *Engine) CancelOrder(ctx context.Context, order *Order) error {
    // 创建一个带超时的 context
    cancelCtx, cancel := context.WithTimeout(ctx, CancelTimeout)
    defer cancel()

    // 发送 FIX CancelRequest
    fix.SendCancelRequest(order.FixOrderID)

    // 等待 ExecutionReport (或超时)
    select {
    case resp := <-e.responses[order.ID]:
        // 已收到响应
        if resp.CancelRejected() {
            return fmt.Errorf("cancel rejected: %s", resp.CancelRejectReason())
        }
        return nil  // 撤单成功

    case <-cancelCtx.Done():
        // 超时
        e.logger.Warn("cancel request timeout",
            slog.String("order_id", order.ID),
            slog.Duration("timeout", CancelTimeout))

        // 返回什么？
        // Option A: 返回错误，让客户端重试
        //   缺点: 客户端重复撤单风险
        // Option B: 返回成功，记录为 pending，后续异步处理
        //   优点: 保证幂等，用户体验好
        // 推荐 Option B

        return ErrCancelPending  // 客户端知道需要查询状态
    }
}
```

**风险**：FIX 超时 400ms 意味着网络延迟占预算的大部分，任何网络抖动可能导致超时。建议值为 500-600ms，但这会加重 REST API 的响应时间（P95 可能 200-250ms，仍在 500ms SLA 内，但较为紧张）。

### 5.6 撤单异步模式的监控与告警

```yaml
监控指标:
  1. cancel_request_received_total
     - 统计: 接收到的撤单请求数
     - 告警: 若异常低 → 可能 REST API 故障

  2. cancel_success_rate (%)
     - 预期: >95% (大部分撤单成功)
     - 告警: <90% → 可能 FIX 连接问题

  3. cancel_latency_p50/p95/p99 (ms)
     - 预期: p95 < 500ms (FIX 往返 50-300ms + 异步处理)
     - 告警: p99 > 1000ms → 追查原因

  4. cancel_api_response_latency_ms
     - 预期: p95 < 50ms (202 Accepted)
     - 告警: >100ms → 异步队列可能积压

  5. cancel_attempt_count_distribution
     - 统计: 需要重试的撤单数量
     - 预期: 1 次成功率 >95%，2-3 次重试 <5%

  6. fix_cancel_response_timeout_count
     - 统计: FIX 超时次数
     - 告警: >10/min → FIX 连接问题，需要故障排查

告警规则:
  - name: CancelSuccessRateLow
    expr: cancel_success_rate < 90
    severity: high
    action: 页面告警，检查 FIX 连接状态

  - name: CancelQueueBacklog
    expr: cancel_queue_size > 1000  # Redis 队列中待处理
    severity: warning
    action: 自动扩展 Cancel Worker，告知 team

  - name: FIXCancelTimeoutFrequent
    expr: rate(fix_cancel_timeout_total[5m]) > 0.1
    severity: critical
    action: Engineering On Call，检查交易所网络

Dashboards:
  - Grafana Panel: Cancel Order Workflow
    - 撤单请求频率
    - 撤单成功率
    - API 响应时间分布
    - FIX 往返延迟
    - 队列积压情况
```

### 5.7 工作量估算

| 任务 | 时间 | 说明 |
|------|------|------|
| Redis 异步队列设计 | 2天 | 幂等性设计、防重复 |
| Cancel Worker 实现 | 2天 | FIX 发送、重试逻辑、超时处理 |
| OMS 状态转换集成 | 1.5天 | 消费 Kafka 事件，更新订单状态 |
| WebSocket 推送集成 | 1.5天 | 频道设计、推送逻辑 |
| DB Schema 变更 (cancel_status 等字段) | 0.5天 | Goose 迁移脚本 |
| 监控告警 | 1天 | 6个关键指标 + Grafana 面板 |
| **总计** | **8天** | 依赖于市价缓存（WebSocket 基础） |

---

# 第二部分：集成依赖关系与关键路径分析

## 依赖图

```
条件1: 市价本地缓存 (15天) ─┐
                        │
条件2: AMS账户缓存 (6天) ◄─┤─── (AMS team 补充4字段, 2天)
                        │
条件3: 现金余额+昨日市值 (5天) ◄─ (Fund Transfer team 推送接口, 1天)
                        │
条件4: DB索引优化 (3天) ◄─────────── (无依赖)
                        │
条件5: 撤单异步模式 (8天) ◄─────────┤
                                   └─ WebSocket 基础设施 (条件1)

关键链: 条件1 (15天) → 条件5 (8天) = 23天 (关键路径)
其他: 条件2, 3, 4 可并行, 但 2/3 需要上游 team 配合
```

## 关键路径时间表

```
Week 1 (D1-D5: 2026-03-31 ~ 2026-04-04)
├─ 条件1: 启动 Kafka Consumer 框架 (D1-D3)
├─ 条件4: DB 索引迁移脚本编写 + 灰度测试 (D1-D3)
└─ 上游协调:
   ├─ AMS team: 启动 proto 补充 (kyc_status, kyc_tier, account_type, is_restricted)
   └─ Fund Transfer team: 启动事件推送接口开发 (balance_changed, daily_snapshot)

Week 2 (D6-D10: 2026-04-07 ~ 2026-04-11)
├─ 条件1: 消费端 + 去重 + 错误处理 (D4-D7)
├─ 条件2: 等待 AMS proto 完成，启动缓存层开发 (D6+)
├─ 条件3: 等待 Fund Transfer 推送接口，启动消费端 (D6+)
└─ 条件4: DB 索引上线到测试环境 (D7-D9)

Week 3 (D11-D15: 2026-04-14 ~ 2026-04-18)
├─ 条件1: 性能测试 + 监控告警 (D8-D10)
├─ 条件2: 集成到风控引擎 (D7-D8)
├─ 条件3: Redis 消费 + API 集成 (D7-D9)
└─ 条件5: 启动 Redis 队列 + Cancel Worker 框架 (D11+)

Week 4 (D16-D20: 2026-04-21 ~ 2026-04-25)
├─ 条件1: 上线到生产 (D12-D14)
├─ 条件5: FIX 集成 + WebSocket 推送 (D12-D16)
├─ 条件2/3: 完整集成测试 (D10-D14)
└─ 整体: 烟雾测试 (D15)

Week 5 (D21-D25: 2026-04-28 ~ 2026-05-02)
├─ 条件5: 监控告警 + 异常重试逻辑 (D17-D18)
├─ 整体: 并发负载测试 (D19-D21)
├─ 整体: REST API SLA 基准测试 (D22-D23)
└─ 整体: 文档编写 + 交接 (D24-D25)

Week 6 (D26-D30: 2026-05-05 ~ 2026-05-09)
├─ 缓冲 + 问题修复 (D26-D29)
└─ 上线检查清单 (D30-D31)

上线日: 2026-05-11 (D32, 提前一周)
```

## 并行能力分析

```
可完全并行 (无依赖):
  - 条件1 (市价缓存) ✓
  - 条件4 (DB 索引) ✓

可并行但需上游支持:
  - 条件2 (AMS 缓存) ← 需 AMS 补充字段 (2天)
  - 条件3 (现金余额) ← 需 Fund Transfer 推送接口 (1天)

有依赖:
  - 条件5 (撤单异步) ← 依赖条件1 (WebSocket 基础)

建议分批推进:
  Batch A (并行, D1-D14): 条件1, 2, 3, 4 (14天)
  Batch B (串行, D15-D23): 条件5 (8天) + 整体集成 (7天)
  Batch C (缓冲, D24-D31): 性能验证、文档、上线准备 (8天)
```

---

# 第三部分：数据库 Schema 变更清单

## 变更概览

| 表 | 操作 | 列 | 优先级 |
|----|------|-----|--------|
| `orders` | ADD | `cancel_status, cancel_attempt_count, last_cancel_attempt_at, cancel_reason` | P0 |
| `orders` | CREATE INDEX | `(account_id, created_at DESC)` | P0 |
| `orders` | CREATE INDEX | `(idempotency_key)` | P0 |
| `orders` | CREATE INDEX | `(cancel_status)` (复合) | P1 |
| `positions` | CREATE INDEX | `(account_id)` | P0 |
| `positions` | CREATE INDEX | `(account_id, market)` | P0 |
| `day_trade_counts` | CREATE UNIQUE INDEX | `(account_id, trade_date, symbol)` | P0 |

## Goose 迁移脚本

```go
// src/migrations/00008_add_trading_indexes.sql

-- +goose Up

-- orders 表: 新增撤单跟踪字段
ALTER TABLE orders
ADD COLUMN cancel_status VARCHAR(32) DEFAULT 'NONE'
COMMENT 'NONE | PENDING | SUCCESS | FAILED | PARTIAL';

ALTER TABLE orders
ADD COLUMN cancel_attempt_count INT DEFAULT 0
COMMENT '撤单尝试次数';

ALTER TABLE orders
ADD COLUMN last_cancel_attempt_at DATETIME(3) NULL
COMMENT '最后一次撤单尝试时间';

ALTER TABLE orders
ADD COLUMN cancel_reason VARCHAR(255) NULL
COMMENT '撤单失败原因';

-- orders 表: 新增索引
ALTER TABLE orders
ADD INDEX idx_orders_account_created (account_id, created_at DESC),
ADD INDEX idx_orders_idempotency (idempotency_key),
ADD INDEX idx_orders_cancel_status (account_id, cancel_status);

-- positions 表: 新增索引
ALTER TABLE positions
ADD INDEX idx_positions_account (account_id),
ADD INDEX idx_positions_account_market (account_id, market);

-- day_trade_counts 表: 新增唯一索引
ALTER TABLE day_trade_counts
ADD UNIQUE INDEX idx_day_trade_counts_unique (account_id, trade_date, symbol);

-- +goose Down

ALTER TABLE orders
DROP COLUMN cancel_status,
DROP COLUMN cancel_attempt_count,
DROP COLUMN last_cancel_attempt_at,
DROP COLUMN cancel_reason;

ALTER TABLE orders
DROP INDEX idx_orders_account_created,
DROP INDEX idx_orders_idempotency,
DROP INDEX idx_orders_cancel_status;

ALTER TABLE positions
DROP INDEX idx_positions_account,
DROP INDEX idx_positions_account_market;

ALTER TABLE day_trade_counts
DROP INDEX idx_day_trade_counts_unique;
```

---

# 第四部分：监控与告警策略

## 关键指标汇总表

| 条件 | 指标名 | 告警阈值 | 严重级别 | 检查频率 |
|------|--------|---------|---------|---------|
| 条件1 | `kafka_quote_messages_consumed_total` | 0 msg in 2min (交易时段) | 🔴 高 | 1min |
| 条件1 | `quote_cache_hit_rate` | <95% | 🟡 中 | 5min |
| 条件1 | `quote_cache_redis_latency_p95` | >5ms | 🟡 中 | 1min |
| 条件1 | `quote_cache_dlq_messages` | >100 | 🔴 高 | 1min |
| 条件2 | `ams_cache_hit_rate` | <90% | 🟡 中 | 5min |
| 条件2 | `ams_grpc_latency_p95` | >200ms | 🟡 中 | 1min |
| 条件2 | `ams_grpc_error_rate` | >1% | 🔴 高 | 1min |
| 条件3 | `cash_balance_cache_freshness` | >300s | 🔴 高 | 1min |
| 条件3 | `daily_snapshot_events_received` | 0/day | 🔴 高 | 1h (off-hours) |
| 条件4 | `orders_query_p95_latency` | >200ms (post-index) | 🟡 中 | 1min |
| 条件5 | `cancel_success_rate` | <90% | 🔴 高 | 1min |
| 条件5 | `cancel_api_response_latency_p95` | >50ms | 🟡 中 | 1min |
| 条件5 | `fix_cancel_timeout_count` | >10/min | 🔴 高 | 1min |

## Prometheus 告警规则

```yaml
# prometheus/rules/trading-engine-sla.yml

groups:
  - name: trading-engine-sla
    interval: 1m
    rules:
      # 条件1: 市价缓存
      - alert: QuoteCacheDataLoss
        expr: rate(quote_cache_dlq_messages_total[5m]) > 0.1
        for: 2m
        severity: critical
        annotations:
          summary: "行情缓存数据丢失"
          description: "DLQ 消息速率 {{ $value }}/s，可能影响 P&L 计算"

      - alert: QuoteCacheLatencyHigh
        expr: quote_cache_redis_latency_p95 > 5
        for: 5m
        severity: warning
        annotations:
          summary: "行情缓存延迟过高 (p95 > 5ms)"
          description: "可能影响 GET /positions 延迟"

      # 条件2: AMS 缓存
      - alert: AMSServiceUnavailable
        expr: ams_grpc_error_rate > 0.01
        for: 2m
        severity: critical
        annotations:
          summary: "AMS 服务故障"
          description: "错误率 {{ $value }}%，无法获取账户信息"

      # 条件3: 现金余额缓存
      - alert: CashBalanceCacheStale
        expr: cash_balance_cache_freshness_seconds > 300
        for: 5m
        severity: critical
        annotations:
          summary: "现金余额缓存过期"
          description: "最后更新距离现在 {{ $value }} 秒，可能 Fund Transfer 推送中断"

      - alert: DailySnapshotMissing
        expr: daily_snapshot_events_received == 0 AND hour() >= 9 AND hour() < 17
        for: 30m
        severity: critical
        annotations:
          summary: "昨日市值快照未接收"
          description: "可能影响 portfolio summary 的 day_pnl 计算"

      # 条件4: DB 索引性能
      - alert: OrdersQueryLatencyHigh
        expr: orders_query_latency_p95 > 200
        for: 5m
        severity: warning
        annotations:
          summary: "订单查询性能下降"
          description: "P95 延迟 {{ $value }}ms，建议检查索引"

      # 条件5: 撤单
      - alert: CancelSuccessRateLow
        expr: cancel_success_rate < 0.9
        for: 2m
        severity: critical
        annotations:
          summary: "撤单成功率低于 90%"
          description: "可能 FIX 连接问题，需要检查"

      - alert: FIXCancelTimeoutFrequent
        expr: rate(fix_cancel_timeout_total[5m]) > 0.1
        for: 2m
        severity: critical
        annotations:
          summary: "FIX 撤单超时频繁"
          description: "超时速率 {{ $value }}/s，交易所网络问题"
```

## Grafana 仪表盘设计

### Dashboard 1: REST API SLA 总览

```json
{
  "dashboard": {
    "title": "Trading Engine REST API SLA Monitoring",
    "panels": [
      {
        "title": "POST /orders 延迟分布",
        "targets": [
          "histogram_quantile(0.95, rate(rest_api_latency_bucket{endpoint=\"POST /orders\"}[5m]))"
        ]
      },
      {
        "title": "GET /positions 延迟分布",
        "targets": [
          "histogram_quantile(0.95, rate(rest_api_latency_bucket{endpoint=\"GET /positions\"}[5m]))"
        ]
      },
      {
        "title": "GET /portfolio/summary 延迟分布",
        "targets": [
          "histogram_quantile(0.95, rate(rest_api_latency_bucket{endpoint=\"GET /portfolio/summary\"}[5m]))"
        ]
      },
      {
        "title": "DELETE /orders 延迟分布 (异步模式 202 响应)",
        "targets": [
          "histogram_quantile(0.95, rate(rest_api_latency_bucket{endpoint=\"DELETE /orders\"}[5m]))"
        ]
      }
    ]
  }
}
```

### Dashboard 2: 缓存性能详情

```json
{
  "panels": [
    {
      "title": "Quote Cache Hit Rate",
      "targets": ["quote_cache_hit_rate"]
    },
    {
      "title": "AMS Cache Hit Rate",
      "targets": ["ams_cache_hit_rate"]
    },
    {
      "title": "Redis 操作延迟 (ms)",
      "targets": [
        "redis_latency_p50",
        "redis_latency_p95",
        "redis_latency_p99"
      ]
    },
    {
      "title": "Kafka 消费延迟 (offset lag)",
      "targets": ["kafka_consumer_lag"]
    }
  ]
}
```

### Dashboard 3: 撤单工作流

```json
{
  "panels": [
    {
      "title": "撤单请求频率 (QPS)",
      "targets": ["rate(cancel_requests_total[1m])"]
    },
    {
      "title": "撤单成功率 (%)",
      "targets": ["cancel_success_rate * 100"]
    },
    {
      "title": "API 响应时间 (202 Accepted)",
      "targets": ["rest_api_latency_p95{endpoint=\"DELETE /orders\"}"]
    },
    {
      "title": "FIX 往返延迟 (ms)",
      "targets": ["fix_roundtrip_latency_p95"]
    },
    {
      "title": "撤单队列积压",
      "targets": ["cancel_queue_size"]
    }
  ]
}
```

---

# 第五部分：性能基准与 SLA 可行性验证

## POST /orders 性能预测

```
输入条件:
  - 并发: 300 orders/s (峰值)
  - 风控: 8 道检查 <5ms P99
  - DB: MySQL 单主 + 3 从，连接池 20-100
  - Redis: 3 节点集群，TTL 60s
  - Kafka: 发布异步（不阻塞 API 返回）

处理时间分解 (P95):
  幂等检查 (Redis GET)     →  1-2ms
  格式校验              →  1-2ms
  风控 8 道检查          →  2-5ms
    - 账户检查 (Redis) →  2ms (有缓存)
    - 其他 7 道 (内存) →  0-3ms
  DB 事务 (INSERT)        →  5-10ms
  Kafka 异步发布         →  不阻塞 (async)
  ─────────────────────────
  总计 (核心)           ~10-20ms
  网络往返 (RTT)         ~30-50ms
  ─────────────────────────
  P95 总耗时            ~40-70ms ✓✓✓

结论: 远低于 500ms SLA，充分安全边际 ✓
```

## GET /positions 性能预测

```
输入条件:
  - 并发: 1000 queries/s (峰值)
  - 平均持仓数: 10-50
  - 市价必须缓存到 Redis (来自 Kafka 驱动)

处理时间分解 (P95):
  验证权限 + 参数       →  1-2ms
  DB 查询 (indexed)     →  5-20ms
    - idx_positions_account 确保快速 seek
    - 返回 ~10-50 行持仓
  Redis 批量获取市价     →  2-5ms
    - MGET [symbol1, symbol2, ...]
  计算市值 + P&L         →  3-5ms
    - 内存操作, quantity × price
  JSON 组装             →  1-2ms
  ─────────────────────────
  总计 (核心)          ~15-35ms
  网络往返 (RTT)        ~30-50ms
  ─────────────────────────
  P95 总耗时           ~45-85ms ✓✓✓

结论: 远低于 200ms SLA ✓
```

## GET /portfolio/summary 性能预测

```
输入条件:
  - 并发: 1000 queries/s (峰值)
  - 现金余额缓存 (Redis)
  - 持仓快速查询 (indexed DB)
  - 市价缓存 (Redis)
  - 昨日市值缓存 (Redis)

处理时间分解 (P95):
  验证权限            →  1ms
  Redis GET 现金余额   →  1ms
  DB 查询持仓         →  5-10ms (indexed)
  Redis MGET 市价      →  2-5ms
  Redis GET 昨日市值   →  1ms
  计算总资产 + 日盈亏  →  3-5ms
  JSON 组装           →  1-2ms
  ─────────────────────────
  总计 (核心)        ~15-25ms
  网络往返 (RTT)      ~30-50ms
  ─────────────────────────
  P95 总耗时         ~45-75ms ✓✓✓

结论: 远低于 150ms SLA ✓
```

## DELETE /orders (异步撤单) 性能预测

```
输入条件:
  - 并发: 100 cancels/s (峰值，远低于下单频率)
  - 异步模式: 返回 202 Accepted
  - 后续 FIX 往返: 50-300ms (取决于交易所)

处理时间分解 (P95):
  验证权限            →  1-2ms
  状态检查            →  2-3ms
  Enqueue 到 Redis    →  1-2ms
  返回 202 Accepted   →  <1ms
  ─────────────────────────
  总计 (同步部分)     ~5-10ms
  网络往返 (RTT)      ~30-50ms
  ─────────────────────────
  P95 总耗时         ~35-60ms ✓✓✓

FIX 后续处理 (异步，不阻塞):
  FIX Cancel Request    →  2-5ms
  交易所处理           →  50-300ms (不在 API 响应路径上)
  FIX Cancel Response   →  消费，更新 order.status
  WebSocket 推送       →  客户端接收

结论: API 响应时间极短 <50ms P95，SLA 轻松达成 ✓✓✓
```

---

# 第六部分：风险评估与缓解方案

## 风险矩阵

| 风险 | 概率 | 影响 | 优先级 | 缓解方案 |
|------|------|------|--------|---------|
| AMS 补充字段延期 | 中 | 高 | P1 | 早期协调，写入 AMS PRD；备选: 使用旧字段 fallback |
| Fund Transfer 推送接口不稳定 | 中 | 高 | P1 | 双向验证机制；定期对账；event replay 支持 |
| 市价缓存消费延迟过高 | 低 | 高 | P1 | 增加消费者 Pod；Redis 集群扩容；分区优化 |
| DB 索引创建阻塞写入 | 低 | 高 | P2 | 使用 pt-online-schema-change；低流量时段执行 |
| FIX 网络延迟超过 400ms | 中 | 中 | P2 | 异步模式规避；故障转移到备用路线 |
| Redis 缓存雪崩 | 低 | 中 | P2 | 随机 TTL；本地备份缓存；降级策略 |
| 高并发下 DB 连接池耗尽 | 中 | 中 | P2 | 连接池扩容至 100+；异步池化 |
| WebSocket 连接数过多 | 中 | 中 | P3 | 连接限流；心跳优化；负载均衡 |

## 缓解方案详情

### A. AMS 补充字段风险

**风险**: AMS team 可能无法在 2 周内完成 proto 修改

**缓解**:
1. 立即启动跨团队协调（第一周 D1）
2. 将需求写入 AMS PRD，正式立项
3. 备选方案: 不等 AMS 补充，交易引擎先实现缓存框架（framework），使用旧接口中的部分字段作 fallback
4. 并行开发: 开发缓存层时使用 mock 数据，AMS 完成后只需修改数据源

### B. Fund Transfer 推送接口风险

**风险**: balance_changed 或 daily_snapshot 事件推送不稳定

**缓解**:
1. 契约明确: 要求 Fund Transfer 保证 at-least-once 交付
2. 交易引擎消费端实现幂等处理 (deduplication by account_id + timestamp)
3. 定期对账: 每小时对比 Redis 缓存的现金余额 vs Fund Transfer 数据库的实际余额
4. Event Replay: 若发现缺失，可向 Fund Transfer 请求补送历史事件

### C. 市价缓存消费延迟风险

**风险**: Kafka quote.updated 消费跟不上，缓存里行情陈旧

**缓解**:
1. 分区优化: 确保 market.quote topic 有 8-16 个分区，充分利用并行消费
2. Pod 扩容: 最多部署 16 个消费端 Pod（与分区数相等）
3. 降级策略: 若缓存延迟 >2 分钟，API 返回的行情标记为 stale: true，UI 可提示用户"行情延迟"
4. 本地备份: 重启前从 DB 中快速恢复最近的行情快照

### D. FIX 网络延迟超过 400ms 风险

**风险**: 网络抖动导致撤单同步模式超时

**缓解**:
1. 采用异步模式，完全规避此风险
2. 若必须同步: 超时时间设为 600ms（而非 400ms），给网络留出缓冲
3. 断路器: 若连续 3 个撤单超时，自动切换到异步模式，告警 team

### E. Redis 缓存雪崩风险

**风险**: 大量缓存在同一时刻过期（如 TTL 全是 60s）

**缓解**:
1. 随机 TTL: 不是固定 60s，而是 55-65s 随机
2. 本地备份: 内存中保存上一次的缓存值（soft TTL），缓存 miss 时返回旧值 + 标记 stale: true
3. 降级: 若 Redis 不可用，短期内允许返回 5 分钟以内的行情数据

---

# 第七部分：总体时间表与上线清单

## 甘特图

```
Week 1  ▓▓▓▓▓  条件1 (框架) + 条件4 (索引测试) + 上游协调
Week 2  ▓▓▓▓▓  条件1 (消费逻辑) + 条件2/3 (等待上游) + 整体架构审视
Week 3  ▓▓▓▓▓  条件1 (性能测试) + 条件2 (集成) + 条件5 (框架)
Week 4  ▓▓▓▓▓  条件1 (上线) + 条件2/3/4 (集成) + 条件5 (逻辑) + 烟雾测试
Week 5  ▓▓▓▓▓  条件5 (完成) + 并发测试 + SLA 基准测试
Week 6  ▓▓▓▓  缓冲 + 问题修复 + 文档 + 上线准备
```

## 上线前检查清单

### Phase 1: 单元测试与集成测试 (D15-D20)

- [ ] 条件1 市价缓存: 单元测试 >90% 覆盖率
- [ ] 条件2 AMS 缓存: 缓存 hit/miss 分支测试
- [ ] 条件3 现金余额: event 幂等处理测试
- [ ] 条件4 DB 索引: EXPLAIN 验证所有查询
- [ ] 条件5 撤单: 异步队列重试逻辑测试
- [ ] 风控集成: 8 道检查与缓存交互测试

### Phase 2: 性能基准测试 (D21-D24)

- [ ] 吞吐量测试: 1000 QPS 并发，查看 P95/P99
  ```bash
  ab -n 100000 -c 1000 http://trading-engine:8080/positions
  ```
- [ ] 缓存命中率验证: >95% hit rate
- [ ] Kafka 消费延迟: <100ms （从市价发布到缓存更新）
- [ ] 数据库查询延迟: P95 <20ms （单表查询）
- [ ] 网络延迟: P95 <50ms （包含 RTT）

### Phase 3: SLA 验证 (D25-D29)

- [ ] POST /orders P95 <500ms ✓
- [ ] GET /orders P95 <200ms ✓
- [ ] GET /positions P95 <200ms ✓
- [ ] GET /portfolio/summary P95 <150ms ✓
- [ ] DELETE /orders P95 <50ms (202 响应) ✓
- [ ] 错误率 <0.1% ✓
- [ ] Kafka 消费无丢失 ✓

### Phase 4: 灾难恢复测试 (D29-D30)

- [ ] Redis 故障: 缓存 fallback 是否正常工作
- [ ] Kafka 故障: 消费端恢复逻辑是否正确
- [ ] AMS 故障: 缓存过期的账户信息是否可用
- [ ] FIX 超时: 撤单重试是否正确
- [ ] DB 连接池耗尽: 超时重试是否正确

### Phase 5: 上线准备 (D31)

- [ ] 告警规则已加载到 Prometheus
- [ ] Grafana Dashboard 已准备并验证
- [ ] Runbook 已编写（常见问题 + 解决方案）
- [ ] 值班 Engineer 已培训
- [ ] Rollback 计划已准备
- [ ] 公告已发送给 Mobile/Admin 团队

---

# 第八部分：一句话结论与建议

## 可行性结论

> **✅ 完全可行。5 个技术条件在 42 天内可全部完成，前提是：(1) 遵循关键路径优先级，(2) 依赖上游团队（AMS + Fund Transfer）在 W1 完成需求协调，(3) 数据库索引在低流量时段上线，(4) 撤单采用异步模式 + WebSocket。若上游延期或异步模式受阻，可能导致上线延期 1-2 周。建议成立跨团队协调委员会，每日同步进度。**

## 关键依赖确认清单

| 依赖 | 所有者 | 完成期限 | 风险等级 |
|------|--------|---------|---------|
| AMS 补充 4 字段 (kyc_status, kyc_tier, account_type, is_restricted) | AMS team | W1 (D7) | 🟡 中 |
| Fund Transfer 推送 balance_changed + daily_snapshot 事件 | Fund Transfer team | W2 (D10) | 🟡 中 |
| Market Data 保证 market.quote 吞吐量 10K+/s，延迟 <100ms | Market Data team | W1 (D5) | 🟢 低 (已有) |
| Trading Engine WebSocket 基础设施 (存量能力) | Trading team | W1 (D1) | 🟢 低 |
| 数据库主从延迟 <5ms，连接池支持 100+ 并发 | DevOps/DBA | W1 (D3) | 🟢 低 |

## 后续行动（立即执行）

1. **本周 (D1-D2)**:
   - [ ] 制品此文档发送给 AMS/Fund Transfer/Market Data team
   - [ ] 调度跨团队 kickoff 会，确认上游需求和时间表
   - [ ] Trading team 启动条件1、4 的开发框架

2. **下周 (D5-D7)**:
   - [ ] AMS proto 完成 review 和 merge
   - [ ] Fund Transfer 事件推送接口联调
   - [ ] 条件1 进入消费逻辑开发

3. **第三周 (D10-D15)**:
   - [ ] 条件 1-4 完成集成测试
   - [ ] 条件5 启动开发
   - [ ] 并发性能测试

4. **第四周 (D21-D25)**:
   - [ ] 全量 SLA 基准测试
   - [ ] 灾难恢复演练
   - [ ] 文档和 runbook 编写

5. **第五周 (D28-D31)**:
   - [ ] 上线前检查清单
   - [ ] Rollback 计划验证
   - [ ] 值班 Engineer 培训

---

**文档编制者**: Trading Engineer
**审核日期**: 2026-03-30
**最后更新**: 2026-03-30
**版本**: v1.0 (Initial Release)
