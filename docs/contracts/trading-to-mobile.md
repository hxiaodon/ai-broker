---
provider: services/trading-engine
consumer: mobile
protocol: REST + WebSocket
status: APPROVED
version: 3
created: 2026-03-13
last_updated: 2026-04-20
last_reviewed: 2026-04-20
sync_strategy: provider-owns
---

# Trading Engine → Mobile 接口契约

## 契约范围

移动端交易下单、订单管理、持仓查看、盈亏展示。Trading Engine 为 Flutter 移动客户端提供完整的交易能力，包括订单提交与撤销、订单状态实时推送、持仓与 P&L 查询、以及投资组合概览。

## REST Endpoints

| 方法 | 路径 | 用途 | SLA (P95) | 实现策略 | 详见 Domain PRD |
|------|------|------|----------|---------|--------|
| POST | /api/v1/orders | 提交订单（需生物识别确认 + HMAC 签名） | **<300ms** | 风控检查走 Redis 缓存；AMS 账户状态 TTL 60s 缓存 | [order-lifecycle.md §8.1](../../services/trading-engine/docs/prd/order-lifecycle.md#8-rest-api-响应定义) |
| GET | /api/v1/orders | 订单列表（按状态、日期、市场筛选） | **<200ms** | DB 索引：(account_id, created_at DESC) | [order-lifecycle.md §8.2](../../services/trading-engine/docs/prd/order-lifecycle.md#8-rest-api-响应定义) |
| GET | /api/v1/orders/:id | 订单详情（含成交明细） | **<100ms** | Redis 热路径缓存 | [order-lifecycle.md §8.2](../../services/trading-engine/docs/prd/order-lifecycle.md#8-rest-api-响应定义) |
| DELETE | /api/v1/orders/:id | 撤单（仅限 PENDING / OPEN 状态） | **<400ms** | 异步模式：202 立即返回，结果通过 WebSocket 推送 | [order-lifecycle.md §8.4](../../services/trading-engine/docs/prd/order-lifecycle.md#8-rest-api-响应定义) |
| GET | /api/v1/positions | 持仓列表（含实时市值与盈亏） | **<200ms** | 市价走 Redis 缓存（Kafka 消费 Market Data 更新） | [position-pnl.md §6.1](../../services/trading-engine/docs/prd/position-pnl.md#6-rest-api-响应定义) |
| GET | /api/v1/positions/:symbol | 单只持仓详情 + P&L 明细 | **<100ms** | 同上 | [position-pnl.md §6.2](../../services/trading-engine/docs/prd/position-pnl.md#6-rest-api-响应定义) |
| GET | /api/v1/portfolio/summary | 组合概览：总资产、日盈亏、持仓分布 | **<150ms** | 现金余额缓存 + 昨日市值缓存（每日 16:30 更新） | [settlement.md §9.2](../../services/trading-engine/docs/prd/settlement.md#9-rest-api-响应定义) |
| POST | /api/v1/auth/session-key | 获取动态 HMAC session key（登录后 + refresh 时调用） | **<100ms** | Redis 存储，30min TTL，5min 宽限期 | [security-protocol.md §2](../../services/trading-engine/docs/prd/security-protocol.md#2-s-01-动态-hmac-session-key) |
| GET | /api/v1/trading/nonce | 获取服务端一次性 nonce（下单/撤单前调用） | **<50ms** | Redis SETNX，60s TTL；支持批量 `?count=N`（最多 10） | [security-protocol.md §3](../../services/trading-engine/docs/prd/security-protocol.md#3-s-02-服务端-nonce) |
| GET | /api/v1/trading/bio-challenge | 获取生物识别 challenge（下单前调用） | **<50ms** | Redis 存储，30s TTL，一次性 | [security-protocol.md §4](../../services/trading-engine/docs/prd/security-protocol.md#4-s-03-生物识别-challenge-response) |

> **SLA 定义**: 仅计算 API Gateway 收到请求到返回响应的后端处理时间，不含客户端网络传输延迟（预估移动端网络 150-300ms）。

### SLA 备注

- `DELETE /orders/:id`：采用**异步撤单模式**，接口立即返回 `202 Accepted`；撤单最终状态（成功/失败）通过 `order.updated` WebSocket 频道推送。客户端在 10s 内若未收到推送，应主动 GET /orders/:id 查询。
- `POST /orders`：后端 SLA 为 **<300ms**（较原始建议的 <500ms 更严格），为客户端留出网络 + 生物识别时间预算（总体用户感知 <1s）。

---

## WebSocket Channels

服务端地址：`wss://api.example.com/ws/trading`

| Channel | 用途 | 触发方式 | 推送频率 | 优先级 |
|---------|------|---------|---------|--------|
| `order.updated` | 订单状态变化推送（PENDING→FILLED/CANCELLED/REJECTED 等） | 事件驱动 | 每次状态变更立即推送 | **必需** |
| `position.updated` | 持仓数量/均价变化（成交或结算后） | 事件驱动 | 每次持仓变更立即推送 | **必需** |
| `portfolio.summary` | 资产总览聚合推送（总资产/今日盈亏） | 定时 + 事件驱动 | 每 **5-10s** 推送（高频行情时段可降至 5s） | 重要 |
| `settlement.updated` | 结算状态变化（T+1/T+2 结算完成，影响可卖数量） | 事件驱动 | 日终 1 次 | 应有 |

> **注意**：行情实时价格（`quote.updated`）由 **Market Data 服务**提供，不在本契约范围内。持仓列表中的实时市值通过 GET /positions 配合行情 WebSocket 由客户端本地计算。

### WebSocket 消息格式

```json
// order.updated — 订单状态变化（详见 order-lifecycle.md §8.5）
{
  "channel": "order.updated",
  "data": {
    "order_id": "ord-abc123",
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 100,
    "status": "FILLED",
    "display_status": "已成交",
    "filled_qty": 100,
    "avg_fill_price": "150.2500",
    "order_type": "LIMIT",
    "limit_price": "150.2500",
    "created_at": "2026-03-30T09:30:00.000Z",
    "updated_at": "2026-03-30T09:45:00.123Z",
    "cancel_status": null,
    "reject_reason": null
  }
}

// position.updated — 持仓变化（详见 position-pnl.md §6.3）
{
  "channel": "position.updated",
  "data": {
    "symbol": "AAPL",
    "market": "US",
    "quantity": 200,
    "settled_qty": 100,
    "unsettled_qty": 100,
    "settlement_date": "2026-04-01T00:00:00.000Z",
    "avg_cost": "148.3200",
    "cost_basis": "29664.00",
    "current_price": "150.5600",
    "market_value": "30112.00",
    "unrealized_pnl": "448.00",
    "unrealized_pnl_pct": "1.51",
    "today_pnl": "125.50",
    "today_pnl_pct": "0.42",
    "updated_at": "2026-03-30T09:45:00.456Z"
  }
}

// portfolio.summary — 资产概览（详见 settlement.md §9.3）
{
  "channel": "portfolio.summary",
  "data": {
    "total_equity": "52341.20",
    "total_market_value": "47200.00",
    "cash_balance": "5141.20",
    "unsettled_cash": "2500.00",
    "day_pnl": "823.50",
    "day_pnl_pct": "1.60",
    "cumulative_unrealized_pnl": "3250.75",
    "cumulative_realized_pnl": "1200.50",
    "cumulative_pnl": "4451.25",
    "cumulative_pnl_pct": "9.28",
    "buying_power": "7641.20",
    "margin_requirement": "0.00",
    "updated_at": "2026-03-30T09:45:05.000Z"
  }
}

// settlement.updated — 结算状态变化（详见 settlement.md §9.1）
{
  "channel": "settlement.updated",
  "data": {
    "symbol": "AAPL",
    "market": "US",
    "settled_qty_added": 50,
    "new_total_settled_qty": 150,
    "previous_unsettled_qty": 100,
    "settlement_date": "2026-03-31T00:00:00.000Z",
    "trade_date": "2026-03-29T00:00:00.000Z",
    "timestamp": "2026-03-31T16:30:00.000Z"
  }
}
```

---

## 认证与安全

> **完整安全协议**：[security-protocol.md](../../services/trading-engine/docs/prd/security-protocol.md)

- **所有端点均需 JWT Bearer token**
- 订单提交（POST /orders）和撤单（DELETE /orders/:id）额外要求以下请求头：

| Header | 说明 | 来源 |
|--------|------|------|
| `X-Key-Id` | 动态 session key 标识 | `POST /auth/session-key` 返回 |
| `X-Timestamp` | Unix 毫秒时间戳 | 客户端生成，服务端校验 ±30s |
| `X-Nonce` | 服务端签发一次性 nonce | `GET /trading/nonce` 返回，60s TTL |
| `X-Device-Id` | 已绑定设备 ID | 设备注册时持久化 |
| `X-Signature` | HMAC-SHA256 签名 | 见 security-protocol.md §7 |
| `Idempotency-Key` | UUID v4，网络重试幂等 | 客户端生成 |
| `X-Biometric-Token` | 生物识别 token（仅 POST /orders） | 客户端生物识别后计算 |
| `X-Bio-Challenge` | 生物识别 challenge（仅 POST /orders） | `GET /trading/bio-challenge` 返回 |
| `X-Bio-Timestamp` | 生物识别时间戳（仅 POST /orders） | 客户端生成 |

- **HMAC 签名 payload（6 段）**：`METHOD\nPATH\nTIMESTAMP\nNONCE\nDEVICE_ID\nBODY_HASH`
- **WebSocket 认证**：连接后 10 秒内发送 auth 消息（token 不在 URL 中），见 security-protocol.md §5
- 限速：**10 orders/sec per user**
- **所有金额字段使用 string 编码的 decimal**，禁止浮点数

---

## 关键技术依赖（Trading Engine 实现计划）

为满足上述 SLA，Trading Engine 需完成以下 5 个技术条件（目标完成日期 **2026-05-11**）：

| 条件 | 说明 | 目标完成 |
|------|------|---------|
| 1. 市价本地缓存 | Kafka 消费 Market Data 的 `market.quote` → Redis，5min TTL | Week 1-3 |
| 2. AMS 账户信息缓存 | Redis TTL 60s，事件驱动失效；补充 kyc_status/kyc_tier/account_type/is_restricted 字段 | Week 2（依赖 AMS 补充字段，预计 2026-04-02） |
| 3. 现金余额+昨日市值缓存 | Fund Transfer `fund.balance_changed` → Redis；每日 16:30 刷新昨日市值 | Week 2-3 |
| 4. DB 索引优化 | 新增 5 个查询索引，在线变更（pt-online-schema-change） | Week 1-2 |
| 5. 撤单异步模式 | DELETE 返回 202，Cancel Worker 异步处理 FIX，WebSocket 推送最终结果 | Week 3-4 |

---

## 错误码约定

| HTTP 状态码 | 含义 | 示例场景 |
|------------|------|---------|
| 200 | 成功 | GET 查询成功 |
| 202 | 已受理（异步） | DELETE 撤单已受理 |
| 400 | 请求参数错误 | 无效的 symbol、数量为负 |
| 401 | 未认证 | JWT 过期或无效 |
| 403 | 风控拒绝 | 购买力不足、PDT 触发、账户受限 |
| 422 | 业务逻辑错误 | 撤单时订单已成交 |
| 429 | 频率超限 | 超过 10 orders/sec |
| 503 | 服务不可用 | FIX 连接断开，暂停下单 |

---

## 权威来源（唯一真实来源）

本契约定义接口的 SLA、基本拓扑和安全要求。详细的字段定义、计算方法、错误处理规则由以下 Domain PRD 文档定义，这些文档是**唯一的真实来源**。若契约与 Domain PRD 之间存在冲突，以 Domain PRD 为准。

| 关注点 | 权威来源 | 内容范围 |
|-------|---------|---------|
| **订单 REST API 字段** | [order-lifecycle.md §8](../../services/trading-engine/docs/prd/order-lifecycle.md#8-rest-api-响应定义) | POST /orders 201 响应、GET /orders 列表、GET /orders/:id 详情、DELETE /orders/:id 202、WebSocket order.updated 字段定义 |
| **持仓 REST API 字段** | [position-pnl.md §6](../../services/trading-engine/docs/prd/position-pnl.md#6-rest-api-响应定义) | GET /positions 列表、GET /positions/:symbol 详情、WebSocket position.updated 字段定义 |
| **账户概览 REST API 字段** | [settlement.md §9](../../services/trading-engine/docs/prd/settlement.md#9-rest-api-响应定义) | GET /portfolio/summary 响应、WebSocket settlement.updated、WebSocket portfolio.summary 字段定义 |
| **订单状态转移** | [order-lifecycle.md §2-4](../../services/trading-engine/docs/prd/order-lifecycle.md) | 订单状态机、用户可见状态映射、不可逆状态 |
| **成本计算方法** | [position-pnl.md §1](../../services/trading-engine/docs/prd/position-pnl.md#1-成本基础与估值方法) | 加权均价法（US）、先进先出法（HK）、成本基础公式 |
| **P&L 定义** | [position-pnl.md §2](../../services/trading-engine/docs/prd/position-pnl.md#2-盈亏定义与实时计算) | 未实现 P&L、已实现 P&L、日 P&L、公式与示例 |
| **结算规则** | [settlement.md §1-2](../../services/trading-engine/docs/prd/settlement.md#1-结算周期与核心逻辑) | T+1（US）/ T+2（HK）、settled_qty vs unsettled_qty、withdrawal eligibility |
| **错误响应格式** | [error-responses.md §1-6](../../services/trading-engine/docs/error-responses.md) | 标准错误格式、HTTP 状态码映射、30+ 错误码示例、前端处理最佳实践 |
| **数据类型规范** | [type-definitions.md](../../services/trading-engine/docs/type-definitions.md) | Decimal 序列化（4位 US / 3位 HK）、Timestamp ISO 8601、Quantity 整数、Enum 大写下划线 |
| **买入力计算** | [risk-rules.md](../../services/trading-engine/docs/specs/domains/02-pre-trade-risk.md) | 买入力公式、融资率、维持保证金、现金限制 |
| **安全协议** | [security-protocol.md](../../services/trading-engine/docs/prd/security-protocol.md) | session-key、nonce、bio-challenge、WS 连接后认证、设备绑定、HMAC payload 规范 |

---

## 契约变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 若涉及字段定义变更，**先更新对应 Domain PRD**，然后更新本契约
4. 达成一致后：Domain PRD 版本 +1 → 本契约版本 +1 → Thread 标记 RESOLVED

---

## Changelog

| 版本 | 日期 | 变更 | 协商方 |
|------|------|------|--------|
| v3 | 2026-04-20 | **安全加固协议同步**。新增 3 个安全端点（session-key、nonce、bio-challenge）；更新认证与安全章节（新增请求头规范表、HMAC 6 段 payload、WS 连接后认证）；权威来源表新增 security-protocol.md | trading-engineer（基于 mobile-engineer TRADING-SECURITY-HARDENING.md 评审） |
| v2 | 2026-03-31 | **升级为 APPROVED 状态**。补充 REST Endpoints 表的 Domain PRD 交叉引用；增强 WebSocket 消息格式示例（补充完整字段定义）；新增"权威来源"部分，明确每个关注点的权威文档来源 | trading-engineer + mobile-engineer |
| v1 | 2026-03-30 | 明确 SLA（POST <300ms, DELETE <400ms 异步）；新增 WebSocket 频道定义（position.updated, portfolio.summary, settlement.updated）；补充消息格式；记录 5 个技术依赖 | trading-engineer + mobile-engineer |
