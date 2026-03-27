---
thread: trading-mobile-contract-gaps
type: lightweight
status: OPEN
priority: P1
opened_by: trading-engineer
opened_date: 2026-03-27T16:15+08:00
resolved_date: null
incorporated_date: null
participants:
  - trading-engineer
  - mobile-engineer
requires_input_from:
  - mobile-engineer
affects_specs:
  - docs/contracts/trading-to-mobile.md
  - mobile/docs/prd/06-portfolio.md (§六.3 WebSocket 实时推送需求)
  - services/trading-engine/docs/specs/api/rest/
resolution: null
incorporated_commits: []
---

# Trading → Mobile 契约 Gap：SLA 缺失 + WebSocket 频道不足

## 背景

`docs/contracts/trading-to-mobile.md`（status: DRAFT, v0）缺少关键 SLA 定义，
且 WebSocket 频道设计不足以支持 `mobile/docs/prd/06-portfolio.md` 的实时推送需求。

## Gap 1: 所有 REST 端点 SLA 均为 TBD

### 受影响的端点

| 端点 | 当前 SLA | 建议值 | 影响 |
|------|---------|--------|------|
| POST `/orders` | TBD | <500ms P95 | 用户点击"提交"后需快速反馈 |
| GET `/orders` | TBD | <200ms P95 | 订单列表打开延迟 |
| GET `/positions` | TBD | <200ms P95 | 持仓页加载延迟 |
| GET `/portfolio/summary` | TBD | <150ms P95 | 资产总览刷新延迟 |
| DELETE `/orders/:id` | TBD | <500ms P95 | 撤单操作反馈速度 |

### 为什么重要

- **用户体验**：订单提交超过 1 秒用户会怀疑是否成功，可能重复点击
- **测试和 SLA 监控**：没有 SLA 无法写 integration test 或 monitor alert
- **依赖链上游**：Market Data 已定义 <50ms P99 for GetQuote，Trading Engine 需要定义自己的 SLA

---

## Gap 2: WebSocket 频道不足

### 当前定义

```yaml
Channel: order.status
Format: {"subscribe": "order.status"}
说明: 订单状态实时推送（PENDING → FILLED / REJECTED / CANCELLED）
```

### PRD 需求（`06-portfolio.md` §六.3）

```
价格刷新规则
| 场景 | 行为 |
|------|------|
| 交易时段内（盘中/盘前/盘后） | WebSocket 实时推送，持仓市值和盈亏自动计算更新 |
| 休市期间 | 显示最后收盘价，不实时更新 |
```

### 缺失的频道

为了支持"持仓市值和盈亏实时更新"，需要：

| 频道 | 消息格式 | 推送频率 | 优先级 |
|------|---------|---------|--------|
| `position.updated` | `{symbol, qty, avg_cost, current_price, market_value, unrealized_pnl}` | 每次市价变动 | MUST |
| `portfolio.summary` | `{total_assets, cash, unsettled, day_pnl, cumulative_pnl}` | 秒级或每次成交 | MUST |

**为什么不用 HTTP polling？**
- 持仓页需要高频刷新市价（秒级），HTTP polling 会导致大量请求
- WebSocket 推送更高效、更低延迟

---

## Gap 3: AMS 契约中 `GetAccountStatus` 返回字段不明确

`docs/contracts/ams-to-trading.md` 中 `GetAccountStatus` 缺少返回字段定义。
`04-trading.md` §1.3 要求检查：

```
| 账户类型 | Phase 1 仅现金账户（Cash Account） |
| 账户 KYC 状态 | 必须为 `APPROVED`（Tier 1 或 Tier 2） |
```

这些字段需要来自 AMS，但契约未定义返回结构。

### 建议

`ams-to-trading.md` 中补充：

```protobuf
message GetAccountStatusResponse {
  enum KYCStatus {
    PENDING = 0;
    APPROVED = 1;
    REJECTED = 2;
    SUSPENDED = 3;
  }
  enum AccountType {
    CASH = 0;
    MARGIN = 1;
  }

  KYCStatus kyc_status = 1;
  int32 kyc_tier = 2;          // 1 or 2
  AccountType account_type = 3;
  bool is_restricted = 4;      // PDT / 账户冻结
  string restriction_reason = 5;
}
```

---

## 行动项

### 短期（必做）

- [ ] **trading-engineer**: 填充 `trading-to-mobile.md` 所有 REST 端点的 SLA（P95/P99）
- [ ] **trading-engineer**: 在 `trading-to-mobile.md` 中补充 `position.updated` 和 `portfolio.summary` WebSocket 频道定义
- [ ] **ams-engineer**: 在 `ams-to-trading.md` 中定义 `GetAccountStatus` 返回字段（需 PM 或 product-manager 确认 kyc_tier 定义）

### 中期（推荐）

- [ ] **trading-engineer** + **mobile-engineer**: 评估是否需要增量订阅（subscribe 单个 symbol 的 position update）
- [ ] **trading-engineer**: 定义 WebSocket message format 的版本化策略和兼容性保证

---

## 附注：Thread 内部讨论模式

建议：
1. trading-engineer 填充 SLA 提议
2. mobile-engineer 评估建议的 SLA 是否可接受；如果不可接受，给出反馈 + 替代方案
3. 两方在 thread 中迭代 2-3 轮后，更新契约文件，标记 RESOLVED
