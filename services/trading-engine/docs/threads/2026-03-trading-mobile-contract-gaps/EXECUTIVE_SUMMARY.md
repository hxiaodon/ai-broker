# Trading Engine SLA 评估 - 执行摘要

**生成时间**: 2026-03-30
**评估范围**: REST API 5 个端点 + WebSocket 2 个频道
**评估基础**: research-index.md, trading-system.md, 02-pre-trade-risk.md

---

## 核心结论

| 端点 | 建议 SLA | **评估** | **可行性** |
|------|---------|--------|---------|
| POST /orders | <500ms P95 | ✅ **可承诺** | 99% 确定 |
| GET /orders | <200ms P95 | ✅ **可承诺** | 95% 确定 |
| DELETE /orders/:id | <500ms P95 | ⚠️ **可承诺但有风险** | 85% 确定 (依赖FIX往返) |
| GET /positions | <200ms P95 | ✅ **可承诺** | 95% 确定 |
| GET /portfolio/summary | <150ms P95 | ✅ **可承诺** | 95% 确定 |

---

## 5 个关键技术条件 (必须全部满足)

### ✅ Condition 1: 市价本地缓存 (Market Data → Kafka → Redis)
- **影响端点**: GET /positions, GET /portfolio/summary
- **风险**: 若市价需要远程调用，P95 从 150ms 变成 300ms+，违反 SLA
- **实施**: Kafka 消费 market.quote topic，毫秒级推送到 Redis
- **状态**: 需要实现

### ✅ Condition 2: AMS 账户信息缓存 (60s TTL)
- **影响端点**: POST /orders (风控 AccountCheck)
- **风险**: 若每次下单都远程调用 AMS，+50-100ms，导致 P95 超过 500ms
- **实施**: 首次 gRPC 调用后，缓存到 Redis；TTL 60s 或 KYC 状态变更时刷新
- **状态**: 需要与 AMS 协商补充字段 (见下表)

### ✅ Condition 3: 现金余额 + 昨日市值缓存
- **影响端点**: GET /portfolio/summary
- **风险**: 缺少缓存时，需要多次 DB 查询，延迟 200ms+
- **实施**: Fund Transfer 服务推送现金变更；Position Engine 每日快照昨日市值
- **状态**: 需要实现

### ✅ Condition 4: 数据库索引优化
- **影响端点**: GET /orders, GET /positions
- **风险**: 无索引时，复杂查询 100+ 条订单/持仓 P95 可能 200ms+
- **实施**:
  ```sql
  CREATE INDEX idx_orders_account_created ON orders(account_id, created_at DESC);
  CREATE INDEX idx_positions_account ON positions(account_id);
  CREATE INDEX idx_positions_account_market ON positions(account_id, market);
  ```
- **状态**: 需要实施

### ✅ Condition 5: 撤单异步模式 (推荐) 或 FIX 超时 400ms (备选)
- **影响端点**: DELETE /orders/:id
- **风险**: FIX 往返延迟 50-300ms（取决于交易所），同步等待时 P95 可能 400ms，接近 SLA 上限
- **实施选项**:
  - **推荐**: 异步模式，返回 `202 Accepted`，通过 WebSocket 推送撤单结果 (时间 <50ms)
  - **备选**: 同步等待，但设置 FIX 超时 400ms，超时后返回 202 Accepted
- **状态**: 需要架构评估

---

## AMS 契约补充 (关键字段)

当前 AMS 的 GetAccountStatus 缺失以下字段，需要补充到契约中：

```protobuf
message GetAccountStatusResponse {
  // 现有字段
  string account_id = 1;
  string status = 2;  // ACTIVE | SUSPENDED | CLOSED

  // ===== 新增字段 (Trading Engine 风控必需) =====
  string kyc_status = 4;    // PENDING | APPROVED | REJECTED | SUSPENDED
  int32 kyc_tier = 5;       // 1 | 2 (影响购买力和保证金额度)
  string account_type = 6;  // CASH | MARGIN (影响 PDT 规则)
  bool is_restricted = 7;   // true 时账户受限（PDT冻结等）
}
```

| 字段 | 用途 | 对应风控检查 |
|------|------|-----------|
| `kyc_status` | 检查账户是否可以交易 | AccountCheck |
| `kyc_tier` | 决定购买力和保证金比例 | BuyingPowerCheck, MarginCheck |
| `account_type` | 确定是否适用 PDT 规则 | PDTCheck |
| `is_restricted` | 账户是否被冻结 | AccountCheck, PDTCheck |

---

## WebSocket 推送可行性

### ✅ position.updated 频道
- **触发**: 每次市价变动 (stock price update)
- **延迟**: 15-30ms (市价变动 → Kafka → WebSocket)
- **可行性**: 完全可行，流量可控 (<1M messages/s for 1000 users)

### ✅ portfolio.summary 频道
- **触发**: 秒级汇总 (every 1 second)
- **延迟**: 50-200ms (聚合 → WebSocket)
- **可行性**: 完全可行，低流量 (<1000 updates/s for 1000 users)

---

## 性能瓶颈排序 (优先修复)

| 序号 | 瓶颈 | 影响端点 | P95 延迟 | 修复难度 | 优先级 |
|-----|------|--------|---------|--------|-------|
| 1️⃣ | AMS 账户信息缺缓存 | POST /orders | +50-100ms | 低 | 🔴 P0 |
| 2️⃣ | 市价无本地缓存 | GET /positions, /portfolio/summary | +50-100ms | 中 | 🔴 P0 |
| 3️⃣ | FIX 同步等待撤单 | DELETE /orders/:id | 可能 400-500ms | 中 | 🟡 P1 |
| 4️⃣ | 数据库查询无索引 | GET /orders, /positions | +50-100ms | 低 | 🟡 P1 |
| 5️⃣ | 高并发时 DB 锁争用 | POST /orders (>500 orders/s) | +50-200ms | 高 | 🟢 P2 |

---

## 建议的契约协调步骤

### Phase 1: 需求确认 (本周)
- [ ] Mobile 确认 SLA 建议是否满足用户体验需求
- [ ] AMS 评估是否可补充 4 个新字段到 GetAccountStatus

### Phase 2: 技术实施 (2-3 周)
- [ ] Trading Engine 实现 5 个关键技术条件
- [ ] AMS 补充字段到 GetAccountStatus 契约
- [ ] Fund Transfer 推送现金变更事件

### Phase 3: 测试与验证 (1 周)
- [ ] 性能测试 (JMeter 或 K6): 500+ orders/s, 1000+ QPS 查询
- [ ] 压力测试：验证 P95 SLA 是否满足
- [ ] 故障模拟：Market Data 延迟、AMS 不可用、FIX 丢包

### Phase 4: 签署契约 (签字日期: TBD)
- [ ] 更新 `docs/contracts/trading-to-mobile.md` 添加 SLA
- [ ] 更新 `docs/contracts/ams-to-trading.md` 添加新字段
- [ ] 标记 Thread `2026-03-trading-mobile-contract-gaps` 为 RESOLVED

---

## 风险等级评估

| 端点 | 风险等级 | 主要风险 | 缓解措施 |
|------|--------|--------|--------|
| POST /orders | 🟡 低 | AMS 缓存失效 | 实施缓存策略 + 监控 |
| GET /orders | 🟢 低 | DB 索引缺失 | 建立索引 + 性能测试 |
| DELETE /orders/:id | 🔴 中 | FIX 往返延迟 | 异步撤单模式 |
| GET /positions | 🟢 低 | 市价缓存不同步 | Kafka 驱动更新 |
| GET /portfolio/summary | 🟢 低 | 缓存丢失 | 多层缓存 + 快照 |

---

## 成功指标

**契约协调成功** = 满足以下条件：

✅ 所有 5 个端点在 **生产环境** 下能稳定承诺相应 SLA
✅ P95 延迟 **持续 7 天** 以上不超过 SLA
✅ 无因技术原因导致 SLA 违反的告警
✅ WebSocket 推送延迟 <100ms (position.updated) / <300ms (portfolio.summary)

---

## 联系与问题

- **技术评审**: trading-engineer@company.com
- **契约协调**: mobile-engineer@company.com + ams-engineer@company.com
- **详细报告**: [SLA_FEASIBILITY_ASSESSMENT.md](./SLA_FEASIBILITY_ASSESSMENT.md)

