---
name: order-lifecycle
description: 订单生命周期、状态转换矩阵、DAY/GTC 有效期规则、幂等性要求
type: domain-prd
surface_prd: mobile/docs/prd/04-trading.md (§五 订单状态生命周期、§十一 合规要求)
version: 1
status: DRAFT
created: 2026-03-30T00:00+08:00
last_updated: 2026-03-30T00:00+08:00
revisions:
  - rev: 1
    date: 2026-03-30T00:00+08:00
    author: trading-engineer
    summary: "初始版本：从 Surface PRD 提取订单状态机、有效期规则、审计要求"
---

# 订单生命周期 (Order Lifecycle) — Domain PRD

> **对应 Surface PRD**：`mobile/docs/prd/04-trading.md` §五（用户可见状态）、§十一（合规）
> **依赖 Spec**：`services/trading-engine/docs/specs/domains/01-order-management.md`

---

## 1. 订单内部状态转换矩阵

订单从创建到终结的完整生命周期由以下状态转换定义：

```
CREATED (用户提交)
  ↓
VALIDATED (字段校验通过)
  ↓
RISK_APPROVED (风控检查通过) / RISK_REJECTED (风控拒绝 → 已拒绝)
  ↓
PENDING (发送至交易所)
  ↓
OPEN (交易所接收)
  ├─→ PARTIAL_FILL (部分成交) ──┐
  │                             ↓
  ├─→ FILLED (全部成交)        FILLED
  │
  ├─→ CANCELLED (用户撤销) / EXCHANGE_REJECTED (交易所拒绝)
  │
  └─→ EXPIRED (DAY 单收盘 / GTC 单满期)
```

### 状态转换表

| 当前状态 | 触发条件 | 目标状态 | 说明 |
|---------|---------|---------|------|
| CREATED | 格式校验通过 | VALIDATED | 订单字段合法性检查 |
| CREATED | 格式校验失败 | REJECTED | 返回错误给用户，不计入审计 |
| VALIDATED | 风控检查通过 | RISK_APPROVED | 8 道风控检查全通过 |
| VALIDATED | 风控检查失败 | RISK_REJECTED | 风控拒绝（资金不足/限制/合规）；计入审计 |
| RISK_APPROVED | FIX 发送成功 | PENDING | 订单发送至交易所 |
| RISK_APPROVED | FIX 发送失败 | PENDING_RETRY | 重试机制（可配置重试次数），失败超限后标记异常 |
| PENDING | 交易所 ExecutionReport (ExecType=NEW) | OPEN | 交易所确认接收 |
| PENDING | 交易所 ExecutionReport (ExecType=REJECTED) | EXCHANGE_REJECTED | 交易所拒绝 |
| OPEN | ExecutionReport (ExecType=PARTIAL_FILL) | PARTIAL_FILL | 部分数量成交 |
| OPEN/PARTIAL_FILL | ExecutionReport (ExecType=FILL) | FILLED | 全部成交 |
| OPEN/PARTIAL_FILL | 用户撤单请求 + ExecutionReport (ExecType=CANCELLED) | CANCELLED | 用户成功撤销 |
| OPEN/PARTIAL_FILL | DAY 单收盘时间到达 | EXPIRED | 当日有效单自动过期 |
| OPEN/PARTIAL_FILL | GTC 单满 90 天 | EXPIRED | GTC 有效期上限过期 |

### 终止状态（不可转移）

- **FILLED**：全部成交，进入持仓和结算流程
- **REJECTED**：风控拒绝，用户原订单取消
- **RISK_REJECTED**：风控失败，用户原订单取消
- **CANCELLED**：用户撤销，部分成交的部分继续持仓
- **EXCHANGE_REJECTED**：交易所拒绝，不计入成交
- **EXPIRED**：DAY/GTC 到期，自动取消

---

## 2. 订单有效期规则（DAY / GTC）

### 2.1 当日有效（DAY）

**定义**：下单当日收盘时自动取消未成交部分。

| 场景 | 有效期截止时间 | 说明 |
|------|-----------------|------|
| 常规盘中下单 | 16:00 ET（当日收盘） | US 主市场收盘时间 |
| 盘前下单 | 20:00 ET（当日 20 点） | 盘前有效期延伸至收市后 4 小时 |
| 盘后下单 | 16:00 ET（次日收盘） | 盘后 DAY 单视为次日 DAY 单 |
| 港股（HK Market） | 16:00 HKT（当日收盘） | HK 主市场收盘时间 |

**实现约束**：
- DAY 单需在系统中记录有效期截止时间（`expires_at` 字段）
- Scheduler 在截止时间前 5 分钟检查未成交订单，发起撤销流程
- DAY 单到期后自动转换为 EXPIRED 状态（不需用户手动撤销）

### 2.2 长期有效（GTC）

**定义**：订单保持有效直到用户撤销或 90 天到期。

| 规则 | 约束 |
|------|------|
| 有效期上限 | 最多 90 天；到期前 3 天和 1 天推送通知提醒 |
| 到期处理 | 自动转换为 EXPIRED 状态 |
| 成交不受限 | GTC 单成交不受 90 天限制（可随时成交） |
| 撤销后重下 | 用户撤销 GTC 单后重新下单，新订单作为新 GTC 单，重新计算 90 天 |

**监管合规：**
> **GTC 90 天上限的合理性**（PM 确认）：
> 
> - **SEC/美股**：SEC Rule 10b-4 未明确限制 GTC 有效期。大多数美国经纪商（如 Fidelity、Charles Schwab）采用 60-90 天限制，符合行业惯例。
> - **SFC/港股**：SFO 未明确规定 GTC 有效期。HKEX 建议 90-180 天；我们采用 90 天保守估计，满足港股要求。
> - **FINRA/风险管理**：Rule 4210 未涉及订单有效期。90 天是平衡的选择，既保护用户（避免订单遗忘），也降低系统风险。
>
> **法务最终确认状态**：待确认（PM 已确认业务方案，法务评审预计 2026-04-05）
> 如法务有异议，需在 Phase 1 上线前（下周）完成调整和确认。

---

## 3. 幂等性与重复检测

### 3.1 Idempotency-Key 机制

所有订单提交请求都必须包含 `Idempotency-Key` 头，用于检测重复请求。

```
POST /api/v1/orders
Headers:
  Idempotency-Key: "550e8400-e29b-41d4-a716-446655440000" (UUID v4)
Body:
  {
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 100,
    ...
  }
```

### 3.2 重复检测规则

| 场景 | 处理方式 | 缓存时长 |
|------|---------|---------|
| 首次请求 | 创建订单，记录 Idempotency-Key | 72 小时 |
| 重复请求（同 Key，同参数） | 返回缓存的第一次请求结果（订单 ID + 状态） | 72 小时 |
| 重复请求（同 Key，不同参数） | 拒绝请求，返回 409 Conflict + 错误信息 | — |
| 超过缓存时长 | 生成新订单（用户需重新生成新 Key 并下单） | — |

**实现细节**：
- 幂等性缓存存储在 Redis，格式：`idempotency:{key} → {order_id, status, created_at}`
- 网络超时场景：客户端可以用**相同的 Key** 重新请求，系统会返回原订单状态（不会创建重单）
- 缓存 Key 包含用户 ID，确保跨用户的相同 Key 不会冲突

### 3.3 银行渠道幂等性

对于通过经纪商发送的 FIX 订单，使用 FIX `ClOrdID` 作为交易所层的幂等 ID：
- `ClOrdID` = `{account_id}_{order_id}_{timestamp}`
- 交易所记录 `ClOrdID`，相同 `ClOrdID` 的重复请求自动去重

---

## 4. 用户可见状态与内部状态映射

Surface PRD 中用户界面展示的状态名称与后端内部状态的映射关系如下：

| 用户可见状态 | 内部状态（枚举） | 颜色 | 何时出现 |
|-------------|------------------|------|---------|
| 审核中 | RISK_APPROVED（processing） | 蓝色（加载动画） | 风控通过，但尚未 FIX 发送或未获交易所确认 |
| 待成交 | OPEN | 蓝色 | 交易所确认接收，但未成交 |
| 部分成交 | PARTIAL_FILL | 橙色 | 部分成交，还有待成交部分 |
| 已成交 | FILLED | 绿色 | 全部成交 |
| 已撤销 | CANCELLED | 灰色 | 用户撤单成功 |
| 部分成交后撤销 | CANCELLED（with `filled_qty > 0`） | 橙色 | 部分成交后用户撤单 |
| 已过期 | EXPIRED | 灰色 | DAY 或 GTC 单到期 |
| 已拒绝 | REJECTED / RISK_REJECTED | 红色 | 风控拒绝或格式校验失败 |
| 交易所拒绝 | EXCHANGE_REJECTED | 红色 | 交易所拒绝订单 |

**注意**：`CREATED` 和 `VALIDATED` 状态用户不可见；只有 `PENDING` 以后的状态才会通过 WebSocket 推送给客户端。

---

## 5. 订单事件与审计追踪（SEC Rule 17a-4）

所有订单状态转换都必须生成**不可变的事件记录**，用于审计和 CAT 上报。

### 5.1 事件结构

```json
{
  "event_id": "evt-550e8400-e29b",
  "order_id": "ord-1234",
  "event_type": "ORDER_CREATED",
  "timestamp": "2026-03-30T09:30:00.123456Z",
  "actor_id": "user-5678",
  "actor_type": "CUSTOMER",
  "previous_state": null,
  "new_state": "CREATED",
  "details": {
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 100,
    "order_type": "LIMIT",
    "price": "150.00",
    "time_in_force": "DAY",
    "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
  },
  "ip_address": "192.168.1.1",
  "device_id": "device-abc123",
  "correlation_id": "req-xyz789"
}
```

### 5.2 必须记录的事件

| 事件类型 | 何时触发 | 强制性 |
|---------|---------|--------|
| ORDER_CREATED | 订单创建 | ✅ |
| ORDER_VALIDATED | 校验通过 | ✅ |
| ORDER_RISK_APPROVED | 风控通过 | ✅ |
| ORDER_RISK_REJECTED | 风控拒绝 | ✅ |
| ORDER_SENT_TO_EXCHANGE | FIX 发送 | ✅ |
| ORDER_ACCEPTED_BY_EXCHANGE | 交易所 NEW | ✅ |
| ORDER_PARTIALLY_FILLED | ExecutionReport PARTIAL_FILL | ✅ |
| ORDER_FILLED | ExecutionReport FILL | ✅ |
| ORDER_CANCELLED | 用户撤销 + EXCHANGE CANCELLED | ✅ |
| ORDER_EXPIRED | DAY/GTC 到期 | ✅ |
| ORDER_REJECTED | 交易所拒绝 | ✅ |

### 5.3 存储要求（WORM 合规）

- **表结构**：`order_events` append-only 表，禁止 UPDATE 或 DELETE
- **保留期**：最少 7 年（前 2 年热存储，后 5 年冷存储）
- **可追溯性**：系统需支持按 `order_id` 重建完整订单历史（Event Replay）
- **CAT 上报**：`timestamp` 需精确到纳秒；其他字段见 tech spec

---

## 6. 交易所回报处理（FIX ExecutionReport）

交易所通过 FIX 4.4 `ExecutionReport` 消息通知订单状态变化。系统需要：

1. **解析 ExecutionReport**：提取 `ExecType`、`OrdStatus`、`ExecQty`、`Price` 等关键字段
2. **去重处理**：按 FIX `ExecID` 去重，防止处理重复的交易所消息
3. **状态转换**：根据 ExecType 更新订单内部状态（见 §1 转换矩阵）
4. **持仓更新**：成交后触发 Position Engine 更新（见 05-position-pnl.md）
5. **事件发布**：发布 Kafka `order.executed` 事件供下游消费

---

## 7. 依赖与风险

| 项目 | 说明 |
|------|------|
| **FIX 协议实现** | 依赖 QuickFIX/Go 库；需完成对接 UAT 测试 |
| **GTC 90 天法律确认** | 待法务确认 GTC 上限是否符合 SEC/SFC 监管要求 |
| **用户状态映射** | 前端需要根据内部状态映射展示用户可见状态；建议在 API response 中同时返回内部状态和用户状态 |
| **Event Replay** | 审计和问题排查时需支持按 order_id 重建完整历史 |

---

## 8. REST API 响应定义

所有订单 API 端点的返回格式在本章定义。**所有金额字段使用 string decimal；所有时间戳使用 ISO 8601 UTC。**

### 8.1 POST /api/v1/orders — 201 Created

**请求**（必须包含 Idempotency-Key 头和 HMAC 签名，见§3.1 和§6.2）：
```json
{
  "symbol": "AAPL",
  "side": "BUY",
  "quantity": 100,
  "order_type": "LIMIT",
  "limit_price": "150.00",           // 限价单必填（string decimal）
  "time_in_force": "DAY",            // DAY | GTC
  "allow_premarket": false,          // 可选，默认 false
  "allow_postmarket": false          // 可选，默认 false
}
```

**响应 201 Created**：
```json
{
  "order_id": "ord-550e8400-e29b",       // 生成的订单 ID（UUID）
  "status": "PENDING",                    // 初始内部状态（见§1 转换矩阵）
  "symbol": "AAPL",
  "side": "BUY",
  "order_type": "LIMIT",
  "quantity": 100,
  "limit_price": "150.00",                // string decimal，仅限价单有
  "time_in_force": "DAY",
  "created_at": "2026-03-31T09:30:00.123Z",    // ISO 8601 UTC
  "expires_at": "2026-03-31T20:00:00Z",       // DAY 单收盘时间；GTC 单为 90 天后
  "allow_premarket": false,
  "allow_postmarket": false,
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"  // 原请求的幂等键（回显）
}
```

**失败响应**：见 error-responses.md

---

### 8.2 GET /api/v1/orders — 200 OK

列表查询，支持分页和过滤。

**请求查询参数**：
```
GET /api/v1/orders?status=FILLED&date_from=2026-03-25&date_to=2026-03-31&page=1&page_size=20
```

**响应 200 OK**：
```json
{
  "orders": [
    {
      "order_id": "ord-550e8400-e29b",
      "status": "FILLED",                    // 当前内部状态
      "display_status": "已成交",             // 用户可见状态（见§4 映射表）
      "symbol": "AAPL",
      "side": "BUY",
      "order_type": "LIMIT",
      "quantity": 100,
      "limit_price": "150.00",
      "time_in_force": "DAY",

      // 成交信息
      "filled_qty": 100,                     // 已成交数量
      "avg_fill_price": "150.1525",          // 加权平均成交价（string decimal）
      "remaining_qty": 0,                    // 待成交数量

      // 时间戳
      "created_at": "2026-03-31T09:30:00.123Z",
      "expires_at": "2026-03-31T20:00:00Z",
      "filled_at": "2026-03-31T09:35:45.456Z"   // 全部成交时间（仅 FILLED 状态有）
    }
  ],

  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_count": 47,
    "total_pages": 3
  }
}
```

---

### 8.3 GET /api/v1/orders/:id — 200 OK

订单详情，包含完整成交记录和费用明细。

**响应 200 OK**：
```json
{
  "order_id": "ord-550e8400-e29b",
  "status": "PARTIAL_FILL",
  "display_status": "部分成交",
  "symbol": "AAPL",
  "market": "US",                    // US | HK
  "side": "BUY",
  "order_type": "LIMIT",
  "quantity": 100,
  "limit_price": "150.00",
  "time_in_force": "DAY",
  "allow_premarket": false,
  "allow_postmarket": false,

  // 成交统计
  "filled_qty": 50,
  "avg_fill_price": "150.1200",
  "remaining_qty": 50,

  // 时间戳
  "created_at": "2026-03-31T09:30:00.123Z",
  "expires_at": "2026-03-31T20:00:00Z",
  "updated_at": "2026-03-31T09:45:00.789Z",

  // 成交明细（按成交时间排序）
  "fills": [
    {
      "fill_id": "fill-001",
      "fill_qty": 30,
      "fill_price": "150.1000",      // string decimal
      "fill_time": "2026-03-31T09:35:00.000Z",
      "venue": "NASDAQ",              // 成交交易所
      "execution_id": "exec-12345"    // 交易所的执行 ID（用于对账）
    },
    {
      "fill_id": "fill-002",
      "fill_qty": 20,
      "fill_price": "150.1400",
      "fill_time": "2026-03-31T09:40:00.000Z",
      "venue": "NYSE",
      "execution_id": "exec-12346"
    }
  ],

  // 费用明细
  "fees": {
    "commission": "0.00",            // string decimal
    "exchange_fee": "0.30",
    "sec_fee": "0.00",               // 美股卖出才有
    "finra_fee": "0.00",             // 美股卖出才有
    "total_fees": "0.30"
  },

  // 订单风险属性
  "risk_checks": {
    "account_status": "APPROVED",    // 账户状态检查结果
    "buying_power_check": "PASSED",  // 购买力检查（买入订单才有）
    "position_check": "PASSED",      // 持仓检查（卖出订单才有）
    "pdt_check": "NOT_APPLICABLE",   // PDT 检查
    "concentration_check": "WARNING" // 集中度检查：PASSED | WARNING
  }
}
```

---

### 8.4 DELETE /api/v1/orders/:id — 202 Accepted

撤单请求（异步处理）。

**响应 202 Accepted**：
```json
{
  "order_id": "ord-550e8400-e29b",
  "message": "撤单请求已提交，结果将通过 WebSocket order.updated 频道推送"
}
```

**说明**：
- 返回 202 表示请求已被系统接收，但撤单操作仍在处理中
- 移动端应通过 WebSocket `order.updated` 频道监听撤单结果
- 如果 10 秒内未收到 WebSocket 推送，移动端应主动 GET /orders/:id 查询最新状态

**失败响应**：见 error-responses.md（如订单已成交、已过期等）

---

### 8.5 WebSocket order.updated 消息

推送时机：订单任何状态变化时立即推送。

**消息格式**：
```json
{
  "channel": "order.updated",
  "data": {
    "order_id": "ord-550e8400-e29b",
    "status": "FILLED",                    // 新的内部状态
    "display_status": "已成交",             // 新的用户可见状态（见§4）
    "symbol": "AAPL",
    "side": "BUY",
    "filled_qty": 100,
    "avg_fill_price": "150.1525",          // 最新平均成交价
    "remaining_qty": 0,
    "updated_at": "2026-03-31T09:35:45.123Z",

    // 撤单特有字段（仅当 status=CANCELLED 时）
    "cancel_status": "SUCCESS",            // SUCCESS | FAILED
    "cancel_reason": "USER_REQUESTED",     // 撤销原因

    // 拒绝特有字段（status=REJECTED 或 RISK_REJECTED）
    "reject_reason": "INSUFFICIENT_BALANCE",  // 拒绝原因代码
    "reject_message": "可用资金不足"            // 拒绝原因说明
  }
}
```

---

## 9. 与其他 Domain PRD 的关系

- **risk-rules.md**：定义 RISK_APPROVED → RISK_REJECTED 的风控检查规则
- **settlement.md**：FILLED 订单的后续结算流程（T+1/T+2）
- **position-pnl.md**：FILLED 订单对持仓和 P&L 的影响
- **type-definitions.md**：decimal、timestamp 的序列化规则
- **error-responses.md**：错误响应的标准格式
- **交易契约 (trading-to-mobile.md)**：API 应返回用户可见状态（display_status），而非内部状态（status）
