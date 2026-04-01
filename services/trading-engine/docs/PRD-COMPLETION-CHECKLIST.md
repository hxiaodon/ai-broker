---
name: PRD 完整性检查清单
type: trading-engineer-review
created: 2026-03-31
last_updated: 2026-03-31
---

# Domain PRD 完整性检查 — 缺失项清单

**评审日期**：2026-03-31
**评审人**：trading-engineer
**评审范围**：4 个 Domain PRD + 契约文件的一致性
**目标**：确保移动端工程师有完整的 API 集成指导

---

## 📋 整体评估

| 层级 | 完整性 | 缺失内容 | 优先级 |
|------|--------|---------|--------|
| **业务逻辑** | ✅ 95% | PDT 限制的具体效果（权益要求、清仓模式） | LOW |
| **API 响应** | ⚠️ 30% | REST/WebSocket 的完整 JSON schema | **P0** |
| **错误处理** | ⚠️ 20% | 标准错误响应格式（code + message + details） | **P0** |
| **签名算法** | ❌ 0% | HMAC-SHA256 的具体算法和参数 | **P1** |
| **类型定义** | ⚠️ 50% | decimal/timestamp 的序列化规则 | **P1** |

---

## 🔴 P0 Critical (本周必须完成)

### 1. order-lifecycle.md — 缺少 POST /orders 的 201 响应定义

**问题**：
- 定义了订单状态机，但没说 `POST /api/v1/orders` 返回什么
- 移动端不知道响应中应包含哪些字段

**缺失的信息**：
```json
// POST /api/v1/orders 201 Created 响应应包含：
{
  "order_id": "ord-abc123",           // 生成的订单 ID
  "status": "PENDING",                // 初始状态（见 §4 映射表）
  "symbol": "AAPL",
  "side": "BUY" | "SELL",
  "order_type": "LIMIT" | "MARKET",
  "quantity": 100,
  "limit_price": "150.00",            // 限价单才有（string decimal）
  "time_in_force": "DAY" | "GTC",
  "created_at": "2026-03-31T09:30:00.123Z",  // UTC ISO 8601
  "expires_at": "2026-03-31T20:00:00Z",      // DAY/GTC 过期时间
  "idempotency_key": "550e8400-e29b-41d4..."  // 原请求的幂等键（回显）
}
```

**修正方案**：在 order-lifecycle.md §3 后添加新章节 "API 响应定义"

---

### 2. order-lifecycle.md — 缺少 GET /orders/:id 和 DELETE /orders/:id 的响应

**问题**：
- DELETE 返回 202，但没定义消息体
- GET /orders/:id 返回什么？包含成交明细吗？

**缺失的信息**：
```json
// GET /api/v1/orders/:id 200 OK
{
  "order_id": "ord-abc123",
  "status": "PARTIAL_FILL",           // 当前状态
  "symbol": "AAPL",
  "side": "BUY",
  "order_type": "LIMIT",
  "quantity": 100,
  "filled_qty": 50,                   // 已成交数量
  "avg_fill_price": "150.1500",       // 平均成交价（加权）
  "limit_price": "150.00",
  "time_in_force": "DAY",
  "created_at": "2026-03-31T09:30:00.123Z",
  "expires_at": "2026-03-31T20:00:00Z",
  "updated_at": "2026-03-31T09:45:00.456Z",
  "fills": [                          // 成交明细数组
    {
      "fill_id": "fill-001",
      "fill_qty": 30,
      "fill_price": "150.1200",
      "fill_time": "2026-03-31T09:35:00.000Z",
      "venue": "NASDAQ"               // 成交交易所
    },
    {
      "fill_id": "fill-002",
      "fill_qty": 20,
      "fill_price": "150.1800",
      "fill_time": "2026-03-31T09:40:00.000Z",
      "venue": "NYSE"
    }
  ],
  "fees": {                           // 费用明细
    "commission": "0.00",             // 免佣
    "exchange_fee": "0.30",
    "sec_fee": "0.00",                // 卖出才有
    "total": "0.30"
  }
}

// DELETE /api/v1/orders/:id 202 Accepted
{
  "order_id": "ord-abc123",
  "message": "撤单请求已提交，结果将通过 WebSocket 推送"
}
```

---

### 3. position-pnl.md — 缺少 GET /positions 和 GET /positions/:symbol 的完整响应

**问题**：
- 定义了 P&L 计算方法，但没列出 GET /positions 应返回的所有字段
- 移动端需知道：cost, market_value, unrealized_pnl, account_ratio 等字段来源

**缺失的信息**：
```json
// GET /api/v1/positions 200 OK
{
  "positions": [
    {
      "symbol": "AAPL",
      "market": "US",
      "quantity": 200,                    // 总持仓数 = settled_qty + unsettled_qty
      "settled_qty": 100,                 // 已结算数量（可卖出）
      "unsettled_qty": 100,               // 未结算数量（不可卖出）
      "settlement_date": "2026-04-01T00:00:00Z",  // 未结算部分的结算日期

      // 成本基础（来自 position-pnl.md §1）
      "avg_cost": "148.3200",             // 加权均价法 (string decimal)
      "cost_basis": "29664.00",           // 总成本 = quantity × avg_cost

      // 实时市价（来自 Market Data）
      "current_price": "150.2500",        // 最新市价
      "market_value": "30045.00",         // 持仓市值 = quantity × current_price

      // P&L（来自 position-pnl.md §2）
      "unrealized_pnl": "381.00",         // 未实现盈亏 = market_value - cost_basis
      "unrealized_pnl_pct": "1.29",       // 未实现盈亏率 (%)
      "today_pnl": "125.30",              // 当日浮动盈亏（仅当日变化）
      "today_pnl_pct": "0.42",            // 当日盈亏率 (%)

      // 风险指标
      "account_ratio": "0.2134",          // 占账户总资产比例（用于集中度预警）

      // 交易历史
      "updated_at": "2026-03-31T09:45:00.000Z",  // 最后更新时间（市价变动时）
      "first_buy_date": "2026-03-15T00:00:00Z"   // 首次买入日期
    }
  ],

  "summary": {
    "total_market_value": "140726.50",    // 全部持仓市值
    "total_cost_basis": "138945.20",      // 全部持仓成本
    "total_unrealized_pnl": "1781.30",    // 全部持仓未实现盈亏
    "updated_at": "2026-03-31T09:45:00.000Z"
  }
}

// GET /api/v1/positions/:symbol 200 OK
{
  // 单只持仓详情（与上面一个持仓的字段相同）
  "symbol": "AAPL",
  "market": "US",
  ...

  // 扩展：该持仓的成交历史
  "trades": [
    {
      "trade_id": "trade-001",
      "trade_date": "2026-03-15T00:00:00Z",
      "side": "BUY",
      "quantity": 100,
      "price": "147.5000",
      "total_cost": "14750.00",
      "fees": "0.30",
      "net_cost": "14750.30"
    },
    {
      "trade_id": "trade-002",
      "trade_date": "2026-03-20T00:00:00Z",
      "side": "BUY",
      "quantity": 100,
      "price": "149.1400",
      "total_cost": "14914.00",
      "fees": "0.30",
      "net_cost": "14914.30"
    }
  ]
}
```

**关键点**：
- `settled_qty` 和 `unsettled_qty` 来自 settlement.md §2
- `avg_cost` 来自 position-pnl.md §1（加权均价法）
- `unrealized_pnl` 来自 position-pnl.md §2.1
- `account_ratio` 用于 PRD-06 的集中度预警（> 30% 显示警告）

---

### 4. settlement.md — 缺少 settlement.updated WebSocket 消息格式

**问题**：
- 契约中提到 `settlement.updated` 频道，但没定义消息体
- 移动端需知道：哪只股票、多少股数、何时结算

**缺失的信息**：
```json
// settlement.updated WebSocket 消息
{
  "channel": "settlement.updated",
  "data": {
    "symbol": "AAPL",
    "market": "US",
    "settled_qty_added": 50,            // 本次新结算的股数
    "new_total_settled_qty": 150,       // 结算后该股总已结算数量
    "settlement_date": "2026-03-31T00:00:00Z",  // 结算完成日期（UTC）
    "timestamp": "2026-03-31T04:00:00Z",        // 消息推送时间

    // 扩展字段
    "previous_unsettled_qty": 50,       // 结算前的未结算数量
    "trade_date": "2026-03-30T00:00:00Z"        // 原成交日期（用于验证 T+1）
  }
}
```

**关键点**：
- 结算完成通常在美股盘前 4:00 AM ET（= 17:00 CST）
- 消息应包含 symbol, settled_qty_added, settlement_date，让移动端更新持仓界面

---

### 5. position-pnl.md 和 settlement.md — 缺少 GET /portfolio/summary 的完整响应

**问题**：
- 契约说返回"总资产、日盈亏、持仓分布"，但没列出所有字段
- 需明确：`unsettled_cash`, `cumulative_pnl`, `cumulative_pnl_pct` 来自哪里

**缺失的信息**：
```json
// GET /api/v1/portfolio/summary 200 OK
{
  "account_summary": {
    // 资产构成（来自 settlement.md §1.1）
    "total_equity": "52341.20",         // 账户总资产 = cash + unsettled_cash + market_value
    "cash_balance": "5141.20",          // 可用现金（可买入 / 可出金）
    "unsettled_cash": "0.00",           // 待结算资金（T+1 结算中）
    "total_market_value": "47200.00",   // 全部持仓市值

    // 日盈亏（来自 position-pnl.md §2.3）
    "day_pnl": "823.50",                // 当日浮动盈亏
    "day_pnl_pct": "1.60",              // 当日盈亏率 (%)

    // 累计盈亏（来自 position-pnl.md §2.1 + §2.2）
    "cumulative_unrealized_pnl": "1581.30",      // 当前持仓未实现盈亏总和
    "cumulative_realized_pnl": "3200.15",        // 历史卖出的已实现盈亏总和
    "cumulative_pnl": "4781.45",                 // 累计总盈亏
    "cumulative_pnl_pct": "9.97",                // 累计盈亏率 (%)

    // 时间戳
    "updated_at": "2026-03-31T09:45:05.000Z"    // 最后更新时间
  },

  // 扩展：资产分布分析
  "sector_breakdown": [
    {
      "sector": "Technology",
      "market_value": "20000.00",
      "ratio": "0.3779",                // 占持仓总市值的比例
      "symbol_count": 3
    },
    {
      "sector": "Consumer Discretionary",
      "market_value": "15200.00",
      "ratio": "0.2877",
      "symbol_count": 2
    }
  ]
}
```

---

## 🟡 P1 Important (1 周内完成)

### 6. 新建 error-responses.md — 统一的错误响应格式

**问题**：
- 契约定义了 HTTP 状态码（400, 401, 403 等），但没定义 JSON 响应体格式
- 移动端无法统一处理错误（缺 `code` 字段）

**应包含**：
```markdown
## 标准错误响应格式

所有错误响应（4xx / 5xx）都遵循以下格式：

\`\`\`json
{
  "code": "ERROR_CODE",              // 机器可读的错误码（推荐全大写下划线分隔）
  "message": "Human-readable message",  // 用户友好的错误说明
  "details": {                       // 可选，包含错误的额外信息
    "field": "quantity",             // 哪个字段出错
    "reason": "must be positive",
    "value": -10
  },
  "request_id": "req-abc123"         // 便于日志追踪
}
```

### 示例

#### 400 Bad Request - 请求参数错误
\`\`\`json
{
  "code": "INVALID_QUANTITY",
  "message": "委托数量必须为正整数",
  "details": {"value": -10}
}
```

#### 403 Forbidden - 风控拒绝
\`\`\`json
{
  "code": "INSUFFICIENT_BALANCE",
  "message": "可用资金不足，当前可用 $1500.00",
  "details": {
    "required": "2000.00",
    "available": "1500.00"
  }
}
```

#### 422 Unprocessable Entity - 业务逻辑错误
\`\`\`json
{
  "code": "ORDER_ALREADY_FILLED",
  "message": "该委托已全部成交，无法撤销",
  "details": {
    "order_id": "ord-abc123",
    "filled_qty": 100
  }
}
```
```

---

### 7. 新建 type-definitions.md — 数据类型序列化规则

**问题**：
- 文档说"所有金额字段使用 string decimal"，但没说具体规则
- timestamp 是 ISO 8601 还是 Unix？price 保留几位小数？

**应包含**：
```markdown
## 数据类型序列化规则

### Decimal（金额和价格）

**规则**：
- 所有金额（价格、手续费、P&L）必须用 string 类型，禁止使用 float64
- 小数位数：
  - 美股价格：4 位小数（AAPL @ 150.2567）
  - 港股价格：3 位小数（0700 @ 350.225）
  - 佣金、费用：2 位小数（$0.30）
  - 汇率：6 位小数（1.125642）
- JSON 序列化：`{"price": "150.2567"}` （string，不是 number）

**示例**：
\`\`\`json
{
  "limit_price": "150.2567",      // 美股 4 位
  "exchange_fee": "0.30",         // 费用 2 位
  "market_value": "30045.0000",   // 市值 4 位（与价格对齐）
  "unrealized_pnl": "381.00"      // P&L 2 位
}
\`\`\`

### Timestamp（时间戳）

**规则**：
- 使用 ISO 8601 格式，带 Z 表示 UTC：`2026-03-31T09:45:00.123Z`
- 精度：毫秒级（.123）
- 始终使用 UTC，不转换为本地时间

**示例**：
\`\`\`json
{
  "created_at": "2026-03-31T09:30:00.123Z",
  "updated_at": "2026-03-31T09:45:00.456Z"
}
\`\`\`

### Quantity（数量）

**规则**：
- 整数或分数（Phase 1 仅整数，Phase 2 支持碎股）
- 美股：整数 (100 股)
- 港股：整数，需满足"手数"要求（通常 100 股最小）
- JSON 序列化：number 类型（不是 string）

\`\`\`json
{
  "quantity": 100,                // 整数
  "filled_qty": 50
}
\`\`\`

### Enum（枚举）

**规则**：
- 字符串格式，全大写：`"BUY"`, `"LIMIT"`, `"FILLED"`
- 避免使用数字代码

\`\`\`json
{
  "side": "BUY",
  "order_type": "LIMIT",
  "status": "FILLED"
}
\`\`\`
```

---

### 8. order-lifecycle.md — 补充 HMAC 签名算法细节

**问题**：
- 契约说"HMAC-SHA256 签名（覆盖 method + path + timestamp + body hash）"，但没给具体算法
- 移动端无法实现签名

**应补充**：
```markdown
## POST /orders 的请求签名

### 签名流程

1. **准备签名数据**（按顺序拼接）：
   \`\`\`
   {HTTP_METHOD}|{PATH}|{TIMESTAMP}|{BODY_HASH}

   示例：
   POST|/api/v1/orders|2026-03-31T09:30:00.123Z|a3c5f8e9d2b1...
   \`\`\`

2. **计算 BODY_HASH**：
   - 对请求体（JSON）计算 SHA256，返回 hex string
   - 空 body 时：hash 值为 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`（SHA256("")）

3. **计算签名**：
   - 使用 HMAC-SHA256，密钥为用户的 API Secret（来自 AMS 的 oauth_token）
   - \`signature = HMAC-SHA256(signing_string, api_secret)\`
   - 结果编码为 hex string

### HTTP 请求头

\`\`\`
POST /api/v1/orders HTTP/1.1
Authorization: Bearer {JWT_TOKEN}
X-Signature: {SIGNATURE}
X-Timestamp: 2026-03-31T09:30:00.123Z
Content-Type: application/json

{...}
\`\`\`

### 验证规则

- 时间戳有效期：±30 秒（防重放）
- 签名不匹配：返回 401 Unauthorized
- 时间戳过期：返回 401 Unauthorized

### 示例代码（伪代码）

\`\`\`go
// Go 示例
import "crypto/hmac"
import "crypto/sha256"
import "encoding/hex"

func CreateSignature(method, path, timestamp, bodyHash, apiSecret string) string {
    signingString := fmt.Sprintf("%s|%s|%s|%s", method, path, timestamp, bodyHash)
    h := hmac.New(sha256.New, []byte(apiSecret))
    h.Write([]byte(signingString))
    return hex.EncodeToString(h.Sum(nil))
}
\`\`\`
```

---

## 📊 修正优先级总表

| # | 文件 | 修正项 | 优先级 | 工作量 | 依赖 |
|----|------|--------|--------|--------|------|
| 1 | order-lifecycle.md | POST /orders 201 响应 + GET/DELETE 响应 | **P0** | 2h | 无 |
| 2 | position-pnl.md | GET /positions 和 /positions/:symbol 完整响应 | **P0** | 2h | 无 |
| 3 | settlement.md | settlement.updated WebSocket 消息格式 | **P0** | 1h | 无 |
| 4 | position-pnl.md + settlement.md | GET /portfolio/summary 完整响应 | **P0** | 1.5h | 无 |
| 5 | 新建 error-responses.md | 统一错误响应格式（code + message + details） | **P1** | 1.5h | 1-4 完成 |
| 6 | 新建 type-definitions.md | decimal/timestamp 序列化规则 | **P1** | 1.5h | 无 |
| 7 | order-lifecycle.md | HMAC 签名算法详细说明 | **P1** | 1h | 无 |

**总工作量**：P0 = 6.5h，P1 = 4h，合计 **10.5 小时**

---

## ✅ 验收标准

当以上所有修正完成时，应满足：

1. **移动端工程师角度**：
   - [ ] 可以仅读契约文件，完全理解 API 接口（无需查阅其他文档）
   - [ ] 可以快速定位字段的含义、类型、计算方法
   - [ ] 错误处理逻辑清晰（知道如何处理各种错误码）

2. **审计角度**：
   - [ ] 所有金额字段都明确了 decimal 处理
   - [ ] 所有时间戳都明确了 UTC 和格式
   - [ ] 所有敏感操作（下单、撤单）都明确了签名要求

3. **维护角度**：
   - [ ] 当交易引擎业务逻辑改变时，Domain PRD 更新后，移动端只需查看相同位置
   - [ ] 无需修改契约文件本身（仅需更新版本号）

---

## 📝 后续行动

### 立即（今天）
- [ ] trading-engineer 开始补充 order-lifecycle.md (P0 #1)
- [ ] trading-engineer 开始补充 position-pnl.md (P0 #2)

### 本周（48h 内）
- [ ] 完成 P0 的 4 个修正项
- [ ] 创建 error-responses.md 和 type-definitions.md（P1）
- [ ] 移动端工程师 review 并提交反馈

### 下周
- [ ] 根据反馈迭代
- [ ] 更新契约文件添加引用（trading-to-mobile.md）
- [ ] 标记 Domain PRD 为 APPROVED（从 DRAFT 升级）

