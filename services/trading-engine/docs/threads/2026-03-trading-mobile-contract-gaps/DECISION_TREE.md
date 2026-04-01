# Trading Engine SLA 决策流程

**评估日期**: 2026-03-30
**决策权**: mobile-engineer, ams-engineer, trading-engineer

---

## ❓ 快速决策路径

```
Q: Trading Engine 能承诺 Mobile 建议的 REST API SLA 吗?

A: 看情况 ⚠️

  ┌─ 如果 [5个关键条件] 全部满足
  │  └─→ ✅ 可以承诺 (99.5% 确定)
  │
  └─ 如果 [5个关键条件] 有任何一个无法满足
     └─→ ❌ 无法承诺 (需要重新协商 SLA)
```

---

## 🔑 5 个关键条件

### Condition 1: 市价本地缓存 ⚙️

```
需求:
  市价数据 (stock quote) 必须部署在 Trading Engine 本地或 Redis 缓存中
  不能每次查询时远程调用 Market Data 服务

原因:
  远程调用延迟 +50-100ms
  会导致 GET /positions, GET /portfolio/summary 性能衰退

实施方案:
  ① Market Data 发布 market.quote 到 Kafka
  ② Trading Engine 消费 Kafka
  ③ 实时更新 Redis 缓存
  ④ GET /positions 时从 Redis 读取 (<1ms)

当前状态: ❌ 未实现
负责人: trading-engineer

影响的端点:
  - GET /positions (受影响最大)
  - GET /portfolio/summary
```

**Decision Point**:
- [ ] **YES** - 我们实现 Kafka 驱动的市价缓存
  - → 继续评估 Condition 2
  - 工作量: 中等 (2-3周)

- [ ] **NO** - 我们不实现本地缓存，改用远程调用
  - → ❌ **无法承诺** GET /positions <200ms P95
  - 建议提升 SLA 至 <300ms P95 或 <500ms P99
  - 工作量: 0 (无需实施)

---

### Condition 2: AMS 账户信息缓存 ⚙️

```
需求:
  Trading Engine 缓存 AMS GetAccountStatus 结果到 Redis
  TTL = 60 秒

原因:
  远程调用 AMS 每次 +50-100ms
  会导致 POST /orders P95 超过 500ms

实施方案:
  ① Trading Engine: gRPC 调用 AMS GetAccountStatus
  ② 缓存结果到 Redis (TTL 60s)
  ③ 后续查询直接读 Redis (<2ms)
  ④ 缓存失效: AMS 推送 Kafka account.status_changed 事件

当前状态: ❌ 缺少 AMS 新字段 (kyc_status, kyc_tier, account_type, is_restricted)
负责人: ams-engineer (补充字段) + trading-engineer (实施缓存)

影响的端点:
  - POST /orders (最关键)
  - 所有依赖风控的端点
```

**Decision Point**:
- [ ] **YES** - AMS 补充 4 个新字段，Trading Engine 实现缓存
  - → 继续评估 Condition 3
  - 工作量: 低 (1-2周)

- [ ] **NO** - AMS 无法补充字段或 Trading Engine 无法实施缓存
  - → ❌ **无法承诺** POST /orders <500ms P95
  - 建议提升 SLA 至 <1000ms P95
  - 工作量: 0

---

### Condition 3: 现金余额 + 昨日市值缓存 ⚙️

```
需求:
  ① 现金余额来自 Redis 缓存 (由 Fund Transfer 推送更新)
  ② 昨日市值来自 Redis 缓存 (由 Position Engine 每日快照)

原因:
  如果这些数据需要 DB 查询或远程调用
  会导致 GET /portfolio/summary P95 超过 150ms

实施方案:
  ① Fund Transfer: 每笔出入金时更新 Redis cash_balance
  ② Position Engine: 每日 09:00 快照昨日市值到 Redis
  ③ GET /portfolio/summary: 批量读 Redis (<5ms)

当前状态: ❌ 未实现
负责人: fund-engineer (现金推送) + trading-engineer (昨日市值快照)

影响的端点:
  - GET /portfolio/summary (最关键)
```

**Decision Point**:
- [ ] **YES** - 实现缓存推送和快照
  - → 继续评估 Condition 4
  - 工作量: 中等 (1-2周)

- [ ] **NO** - 无法实施
  - → ⚠️ **可能超过 SLA** GET /portfolio/summary
  - 建议提升 SLA 至 <300ms P95 或 <500ms P99
  - 工作量: 0

---

### Condition 4: 数据库索引优化 ⚙️

```
需求:
  建立 5 个必要索引，确保查询 <20ms

索引列表:
  ① orders(account_id, created_at DESC)
  ② positions(account_id)
  ③ positions(account_id, market)
  ④ executions(account_id, symbol)
  ⑤ day_trade_counts(account_id, trade_date, symbol) UNIQUE

原因:
  没有索引时，复杂查询可能 50-200ms
  会导致 GET /orders, GET /positions 性能衰退

当前状态: ❓ 未知 (需要检查)
负责人: trading-engineer + devops-engineer (索引创建和监控)

影响的端点:
  - GET /orders
  - GET /positions
```

**Decision Point**:
- [ ] **YES** - 我们创建并验证所有索引
  - → 继续评估 Condition 5
  - 工作量: 低 (1 天)

- [ ] **NO** - 无法创建索引 (可能原因: DB 锁、业务冲突等)
  - → ⚠️ **可能超过 SLA** GET /orders, GET /positions
  - 建议: 使用 Redis 缓存热数据
  - 工作量: 中等

---

### Condition 5: 撤单异步模式 ⚙️

```
需求:
  实现异步撤单，返回 202 Accepted
  撤单结果通过 WebSocket 推送客户端

或备选方案:
  同步撤单，但设置 FIX 超时 400ms

原因:
  FIX 往返延迟不可控 (50-300ms)
  同步等待时 P95 可能 400-500ms，接近 SLA 上限

实施方案 A (推荐):
  ① 客户端 DELETE /orders/:id
  ② Trading Engine 发送 FIX CancelRequest，立即返回 202 Accepted
  ③ 订单状态变更通过 WebSocket 推送
  ④ 时间: <50ms

实施方案 B (备选):
  ① 客户端 DELETE /orders/:id
  ② Trading Engine 发送 FIX CancelRequest
  ③ 等待交易所回复 (超时 400ms)
  ④ 返回 200 OK 或 202 Accepted (timeout)
  ⑤ 时间: 50-400ms

当前状态: ❓ 未决定
负责人: trading-engineer + mobile-engineer (协调)

影响的端点:
  - DELETE /orders/:id (撤单最复杂的操作)
```

**Decision Point**:
- [ ] **YES** - 使用方案 A (异步模式 + WebSocket)
  - ✅ **推荐** - 最优性能 (<50ms)
  - 工作量: 高 (3-4周)
  - → **可以承诺** <500ms P95

- [ ] **YES** - 使用方案 B (同步等待 + FIX 超时)
  - ✓ **可接受** - 性能中等 (50-400ms)
  - 工作量: 低 (1-2周)
  - → **可以承诺** <500ms P95，但风险较大

- [ ] **NO** - 同步等待，无超时控制
  - ❌ **无法承诺** <500ms P95 (可能 500-1000ms)
  - 建议提升 SLA 至 <1000ms P95 或 <1500ms P99
  - 工作量: 0

---

## 📋 协商决策矩阵

```
┌─────────────────────────────────────────────────────────────┐
│ 5个条件全满足  │ 3-4个满足       │ ≤2个满足                │
├─────────────────────────────────────────────────────────────┤
│ ✅ 可承诺      │ ⚠️  部分承诺    │ ❌ 无法承诺 (重新协商)  │
│ 99.5% 确定    │ (需要调整SLA)   │                          │
│               │                │                          │
│ 投入: 4-6周   │ 投入: 2-4周    │ 投入: 重新评估           │
│ 成本: 中等    │ 成本: 低-中    │ 成本: 低 (但SLA宽松)    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 签署流程

### Step 1: Requirement Signoff (本周)

**Checklist**:
- [ ] mobile-engineer 确认 SLA 建议的业务可接受性
- [ ] ams-engineer 评估补充 4 个字段的可行性
- [ ] trading-engineer 评估 5 个条件的实施工作量

**文件**:
- EXECUTIVE_SUMMARY.md (给管理层)
- SLA_FEASIBILITY_ASSESSMENT.md (给技术团队)

---

### Step 2: Technical Approval (1-2 周)

**审核人员**:
- [ ] trading-engineer 审核详细方案
- [ ] ams-engineer 同意补充契约字段
- [ ] devops-engineer 评估基础设施改造

**文件**:
- AMS_CONTRACT_SUPPLEMENT.md (AMS 新增字段)
- Database indexing plan (DB 优化)
- Cache strategy document (缓存策略)

---

### Step 3: Signature (最终)

**签署方**:
- [ ] mobile-engineer (接收方)
- [ ] trading-engineer (提供方)
- [ ] ams-engineer (依赖方)
- [ ] product-manager (业务方)

**产出契约**:
- `docs/contracts/trading-to-mobile.md` (更新 SLA 部分)
- `docs/contracts/ams-to-trading.md` (新增字段定义)

---

## ✋ 红旗问题 🚩

如果以下问题答案为 **YES**，立即暂停协商，重新评估：

| 问题 | YES = 风险 | 建议 |
|-----|-----------|------|
| 市价数据是否来自第三方 API (Bloomberg, IEX)?| 延迟不可控 | 考虑缓存或升级 SLA |
| Market Data 服务是否频繁宕机? | 缓存可能过期 | 实施多层缓存 + 降级方案 |
| FIX 连接是否经过代理或 VPN? | 延迟 +200-500ms | 改用直连或升级 SLA |
| 是否需要 360 度持仓重估 (所有资产类别)? | 计算复杂，延迟翻倍 | 只支持股票持仓聚合 |
| 数据库是否单点，无读副本? | 查询饱和 | 添加读副本 |
| Redis 是否单点，无集群? | 缓存 SLA 无法保证 | Redis Cluster 改造 |

---

## 🎯 终局状态

### Best Case (所有条件满足)
```
┌─────────────────────────────────┐
│ ✅ 所有 SLA 可承诺              │
│ ├─ POST /orders <500ms P95      │
│ ├─ GET /orders <200ms P95       │
│ ├─ DELETE /orders/:id <500ms P95│
│ ├─ GET /positions <200ms P95    │
│ └─ GET /portfolio/summary <150ms│
│                                 │
│ WebSocket 推送延迟 <100ms       │
│ 签署 Final Contract             │
└─────────────────────────────────┘
```

### Worst Case (多数条件无法满足)
```
┌─────────────────────────────────┐
│ ❌ SLA 重新协商                  │
│                                 │
│ 建议方案:                        │
│ ├─ POST /orders <1000ms P95     │
│ ├─ GET /orders <500ms P95       │
│ ├─ DELETE /orders/:id <1000ms   │
│ ├─ GET /positions <500ms P95    │
│ └─ GET /portfolio/summary <500ms│
│                                 │
│ 或: 降级支持功能集              │
│     (仅支持热路径，不支持冷数据) │
└─────────────────────────────────┘
```

---

## 📞 联系与后续

**建议下一步行动**:

1. **本周**: 各方基于此文档给出初步意见
2. **下周**: 周会讨论 5 个条件的实施计划
3. **3 周内**: 完成所有条件评估和开发
4. **4 周内**: 签署最终契约

**联系人**:
- **Trading Engineer**: trading-engineer@company.com
- **Mobile Engineer**: mobile-engineer@company.com
- **AMS Engineer**: ams-engineer@company.com
- **Product Manager**: product-manager@company.com

