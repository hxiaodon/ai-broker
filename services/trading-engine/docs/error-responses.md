---
name: error-responses
description: REST API 标准错误响应格式、错误码定义、错误场景示例
type: reference-doc
created: 2026-03-31
---

# REST API 错误响应规范

**应用范围**：所有 Trading Engine REST API 端点
**版本**：1.0
**最后更新**：2026-03-31

---

## 1. 标准错误响应格式

所有错误响应（4xx / 5xx）都遵循以下 JSON 格式：

```json
{
  "code": "ERROR_CODE",                    // 机器可读的错误码（必需）
  "message": "Human-readable message",     // 用户友好的错误说明（必需）
  "details": {                             // 可选，包含错误的额外信息
    "field": "quantity",                   // 出错的字段名（可选）
    "reason": "must be positive",          // 错误原因（可选）
    "value": -10,                          // 提交的值（可选）
    "constraint": "minimum is 1"           // 约束条件（可选）
  },
  "request_id": "req-550e8400-e29b"        // 请求追踪 ID（用于日志查询）
}
```

**字段说明**：
- `code`：机器可读，全大写下划线分隔，用于客户端程序化处理
- `message`：中文或英文，面向用户显示，解释发生了什么和可能的解决方案
- `details`：结构灵活，根据错误类型包含不同信息
- `request_id`：便于用户反馈时快速定位日志

---

## 2. HTTP 状态码与错误码映射

| HTTP 状态码 | 含义 | 常见错误码 |
|-----------|------|--------|
| **400** | Bad Request — 请求参数错误 | INVALID_*, MISSING_*, MALFORMED_* |
| **401** | Unauthorized — 认证失败 | INVALID_TOKEN, TOKEN_EXPIRED, UNAUTHORIZED |
| **403** | Forbidden — 风控拒绝 | INSUFFICIENT_*, ACCOUNT_*, PDT_*, POSITION_* |
| **404** | Not Found — 资源不存在 | ORDER_NOT_FOUND, POSITION_NOT_FOUND |
| **409** | Conflict — 冲突（幂等性错误） | IDEMPOTENCY_KEY_MISMATCH |
| **422** | Unprocessable Entity — 业务逻辑错误 | ORDER_*, STATUS_INVALID |
| **429** | Too Many Requests — 频率超限 | RATE_LIMIT_EXCEEDED |
| **503** | Service Unavailable — 服务不可用 | SERVICE_UNAVAILABLE, FIX_CONNECTION_LOST |

---

## 3. 订单相关错误（POST /orders, DELETE /orders/:id）

### 3.1 请求参数错误 (400)

```json
// 缺少必要字段
{
  "code": "MISSING_REQUIRED_FIELD",
  "message": "缺少必要字段：symbol",
  "details": {
    "field": "symbol",
    "reason": "This field is required"
  },
  "request_id": "req-abc123"
}

// 无效的 symbol 格式
{
  "code": "INVALID_SYMBOL_FORMAT",
  "message": "无效的股票代码格式。美股代码应为 1-5 个大写字母（如 AAPL）",
  "details": {
    "field": "symbol",
    "value": "aapl",  // 小写，应该大写
    "format": "^[A-Z]{1,5}$"
  },
  "request_id": "req-def456"
}

// 无效的数量
{
  "code": "INVALID_QUANTITY",
  "message": "委托数量必须为正整数",
  "details": {
    "field": "quantity",
    "value": -10,
    "constraint": "must be positive integer > 0"
  },
  "request_id": "req-ghi789"
}

// 无效的价格
{
  "code": "INVALID_PRICE",
  "message": "委托价格无效。美股价格应为正数，最多 4 位小数（如 150.2567）",
  "details": {
    "field": "limit_price",
    "value": "150.25670",  // 5 位小数，超过最大值
    "max_decimal_places": 4
  },
  "request_id": "req-jkl012"
}

// 限价单缺少价格
{
  "code": "MISSING_REQUIRED_FIELD",
  "message": "限价单必须指定 limit_price",
  "details": {
    "field": "limit_price",
    "order_type": "LIMIT"
  },
  "request_id": "req-mno345"
}
```

---

### 3.2 认证失败 (401)

```json
// JWT 令牌过期
{
  "code": "TOKEN_EXPIRED",
  "message": "登录令牌已过期，请重新登录",
  "details": {
    "expired_at": "2026-03-31T09:30:00.000Z"
  },
  "request_id": "req-pqr678"
}

// 无效的签名
{
  "code": "INVALID_SIGNATURE",
  "message": "请求签名校验失败。请确认使用了正确的 API Secret",
  "details": {
    "reason": "HMAC-SHA256 signature mismatch"
  },
  "request_id": "req-stu901"
}

// 时间戳过期（防重放）
{
  "code": "TIMESTAMP_TOO_OLD",
  "message": "请求时间戳已过期（超过 30 秒）。请更新系统时间后重试",
  "details": {
    "sent_timestamp": "2026-03-31T09:00:00.000Z",
    "current_time": "2026-03-31T09:31:00.000Z",
    "max_age_seconds": 30
  },
  "request_id": "req-vwx234"
}
```

---

### 3.3 风控拒绝 (403)

```json
// 账户被冻结
{
  "code": "ACCOUNT_RESTRICTED",
  "message": "您的账户已被冻结，无法进行交易",
  "details": {
    "reason": "PDT_CALL",  // 或 COMPLIANCE_HOLD, KYC_SUSPENDED 等
    "message_for_user": "您的账户触发了 Pattern Day Trader 限制。当前仅允许卖出操作。"
  },
  "request_id": "req-yza567"
}

// KYC 未通过
{
  "code": "ACCOUNT_NOT_APPROVED",
  "message": "您的账户未通过 KYC 验证，无法交易",
  "details": {
    "kyc_status": "PENDING",
    "next_check_date": "2026-04-05T00:00:00.000Z"
  },
  "request_id": "req-bcd890"
}

// 购买力不足
{
  "code": "INSUFFICIENT_BALANCE",
  "message": "可用资金不足，无法完成委托",
  "details": {
    "required": "2500.00",             // 所需金额（含费用）
    "available": "1500.00",            // 可用现金
    "shortfall": "1000.00",            // 缺少的金额
    "suggestion": "请充值或卖出持仓增加可用资金"
  },
  "request_id": "req-efg123"
}

// 持仓不足（卖出）
{
  "code": "INSUFFICIENT_POSITION",
  "message": "持仓数量不足，无法完成卖出",
  "details": {
    "symbol": "AAPL",
    "requested_qty": 100,
    "available_settled_qty": 50,       // 可卖的已结算数量
    "unsettled_qty": 50,               // 待结算数量（不可卖）
    "settlement_date": "2026-04-01T00:00:00.000Z"
  },
  "request_id": "req-hij456"
}

// PDT 限制
{
  "code": "PDT_RESTRICTION",
  "message": "您已触发 Pattern Day Trader 限制，当前不允许买入",
  "details": {
    "pdt_mark_date": "2026-03-25T14:30:00.000Z",
    "day_trades_in_5_days": 4,
    "restriction_type": "CLOSING_ONLY",
    "restriction_until": "2026-06-25T00:00:00.000Z"  // 90 天后解除
  },
  "request_id": "req-klm789"
}

// 股票停牌
{
  "code": "SECURITY_HALTED",
  "message": "AAPL 目前因新闻公告而停牌，无法交易",
  "details": {
    "symbol": "AAPL",
    "halt_reason": "NEWS_ANNOUNCEMENT",
    "halt_time": "2026-03-31T11:30:00.000Z",
    "expected_resume": "2026-03-31T14:00:00.000Z"
  },
  "request_id": "req-nop012"
}

// 集中度警告（Phase 1 仅警告，不阻断）
{
  "code": "CONCENTRATION_WARNING",
  "message": "警告：该委托完成后，AAPL 持仓占比将达到 35%，集中度较高",
  "details": {
    "symbol": "AAPL",
    "current_ratio": "0.25",           // 当前占比
    "projected_ratio": "0.35",         // 完成后的占比
    "warning_threshold": "0.30"        // 警告阈值
  },
  "request_id": "req-qrs345"
}
```

---

### 3.4 撤单错误 (422)

```json
// 订单已成交，无法撤销
{
  "code": "ORDER_ALREADY_FILLED",
  "message": "该委托已全部成交，无法撤销",
  "details": {
    "order_id": "ord-550e8400-e29b",
    "status": "FILLED",
    "filled_qty": 100
  },
  "request_id": "req-tuv678"
}

// 订单已过期
{
  "code": "ORDER_ALREADY_EXPIRED",
  "message": "该委托已过期，无法撤销",
  "details": {
    "order_id": "ord-550e8400-e29b",
    "status": "EXPIRED",
    "expires_at": "2026-03-30T20:00:00.000Z"
  },
  "request_id": "req-wxy901"
}

// 订单不存在
{
  "code": "ORDER_NOT_FOUND",
  "message": "找不到该订单",
  "details": {
    "order_id": "ord-nonexistent"
  },
  "request_id": "req-zab234"
}
```

---

### 3.5 幂等性错误 (409)

```json
// 幂等键重复，但参数不同
{
  "code": "IDEMPOTENCY_KEY_MISMATCH",
  "message": "该幂等键已被使用，但请求参数不同。请使用新的幂等键重试",
  "details": {
    "idempotency_key": "550e8400-e29b-41d4-a716-446655440000",
    "previous_request": {
      "symbol": "AAPL",
      "side": "BUY",
      "quantity": 100
    },
    "current_request": {
      "symbol": "AAPL",
      "side": "BUY",
      "quantity": 50   // 数量不同
    }
  },
  "request_id": "req-cde567"
}
```

---

### 3.6 频率限制 (429)

```json
{
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "下单频率超出限制（每用户最多 10 orders/sec）。请稍后再试",
  "details": {
    "limit": "10/sec",
    "window": "1 second",
    "reset_after_seconds": 2
  },
  "request_id": "req-fgh890"
}
```

---

### 3.7 服务不可用 (503)

```json
// FIX 连接断开
{
  "code": "FIX_CONNECTION_LOST",
  "message": "与交易所的连接已断开，暂停接收新订单。请稍后再试",
  "details": {
    "venue": "NASDAQ",
    "last_heartbeat": "2026-03-31T09:45:00.000Z",
    "status": "RECONNECTING"
  },
  "request_id": "req-ijk123"
}

// Market Data 服务不可用
{
  "code": "MARKET_DATA_UNAVAILABLE",
  "message": "行情服务暂时不可用，无法验证当前市价。请稍后再试",
  "details": {
    "service": "market-data",
    "reason": "connection_lost"
  },
  "request_id": "req-lmn456"
}
```

---

## 4. 查询相关错误

### 4.1 订单列表 (GET /orders)

```json
// 无效的查询参数
{
  "code": "INVALID_QUERY_PARAMETER",
  "message": "无效的查询参数：status",
  "details": {
    "parameter": "status",
    "value": "INVALID_STATUS",
    "allowed_values": ["PENDING", "OPEN", "PARTIAL_FILL", "FILLED", "CANCELLED", "EXPIRED", "REJECTED"]
  },
  "request_id": "req-opq789"
}

// 日期范围无效
{
  "code": "INVALID_DATE_RANGE",
  "message": "日期范围无效：开始日期不能晚于结束日期",
  "details": {
    "date_from": "2026-03-31",
    "date_to": "2026-03-25"
  },
  "request_id": "req-rst012"
}
```

---

## 5. 持仓相关错误

### 5.1 持仓不存在 (404)

```json
{
  "code": "POSITION_NOT_FOUND",
  "message": "未找到该持仓",
  "details": {
    "symbol": "UNKNOWN",
    "market": "US"
  },
  "request_id": "req-uvw345"
}
```

---

## 6. 错误处理最佳实践

### 前端/移动端处理

```javascript
// 伪代码示例
async function submitOrder(orderData) {
  try {
    const response = await api.post('/orders', orderData);
    return response.data;
  } catch (error) {
    const errorResponse = error.response.data;

    // 根据 code 分类处理
    switch (errorResponse.code) {
      case 'INSUFFICIENT_BALANCE':
        // 显示充值提示
        showDialog("可用资金不足，请充值", {
          action: "跳转到入金页面"
        });
        break;

      case 'INSUFFICIENT_POSITION':
        // 显示持仓不足提示
        showDialog(
          `可卖数量：${errorResponse.details.available_settled_qty}`,
          { action: "返回" }
        );
        break;

      case 'RATE_LIMIT_EXCEEDED':
        // 显示稍后重试提示
        showToast("下单过于频繁，请稍后再试");
        break;

      case 'FIX_CONNECTION_LOST':
        // 显示服务不可用提示
        showDialog("交易通道暂时不可用，请稍后再试", {
          retry: true
        });
        break;

      default:
        // 通用错误提示
        showToast(errorResponse.message);
        // 记录日志便于问题排查
        logError(errorResponse.request_id, errorResponse);
    }
  }
}
```

---

## 7. 日志追踪

所有错误响应都包含 `request_id`，用于关联后端日志。用户可将 `request_id` 提供给客服，便于快速定位问题。

**后端日志格式**：
```
timestamp=2026-03-31T09:30:00.000Z request_id=req-550e8400-e29b error_code=INSUFFICIENT_BALANCE user_id=user-123 order_id=ord-abc123 symbol=AAPL required=2500.00 available=1500.00
```

