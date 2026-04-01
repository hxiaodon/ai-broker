---
name: type-definitions
description: REST API 中数据类型的序列化规则（decimal、timestamp、enum、quantity）
type: reference-doc
created: 2026-03-31
---

# 数据类型序列化规范

**应用范围**：所有 Trading Engine REST API 和 WebSocket 消息
**版本**：1.0
**最后更新**：2026-03-31

---

## 1. Decimal（金额和价格）

**规则**：所有金额、价格、费用、P&L 必须使用 **string 类型**，禁止使用 number（JSON 中的 float64）。

### 1.1 小数位数规范

| 数据类型 | 美股 | 港股 | 说明 |
|---------|------|------|------|
| **股票价格** | 4 位 | 3 位 | 美股：$150.2567；港股：HK$350.225 |
| **费用（佣金、手续费）** | 2 位 | 2 位 | $0.30，HK$0.30 |
| **持仓成本/市值** | 2 位 | 2 位 | $30045.00，HK$10500.00 |
| **P&L（盈亏）** | 2 位 | 2 位 | $381.00，HK$500.50 |
| **汇率** | 6 位 | 6 位 | 1.125642 |
| **百分比字段** | 整数/小数 | 整数/小数 | 1.29（表示 1.29%）；不带 % 符号 |

### 1.2 JSON 序列化示例

```json
{
  // ✅ 正确示例
  "limit_price": "150.2567",          // 美股价格，4 位小数
  "hk_price": "350.225",              // 港股价格，3 位小数
  "commission": "0.00",               // 费用，2 位小数
  "exchange_fee": "0.30",             // 费用，2 位小数
  "market_value": "30045.00",         // 市值，2 位小数
  "unrealized_pnl": "381.00",         // P&L，2 位小数
  "unrealized_pnl_pct": "1.29",       // 百分比（数字，已乘以 100），无 % 符号
  "fx_rate": "1.125642",              // 汇率，6 位小数

  // ❌ 错误示例
  "price": 150.25,                    // 错误：number 类型，可能精度丢失
  "pnl": "381.005",                   // 错误：3 位小数，应为 2 位
  "percentage": "1.29%",              // 错误：带 % 符号，应为纯数字
  "fx_rate": "1.12564",               // 错误：5 位小数，应为 6 位
}
```

### 1.3 后端处理

**Go 示例**：
```go
import "github.com/shopspring/decimal"

// 读取 API 请求参数
var req struct {
  LimitPrice string `json:"limit_price"` // 从 JSON 读取为 string
}

// 转换为 decimal
price := decimal.NewFromString(req.LimitPrice) // "150.2567" → Decimal

// 计算（使用 decimal，不用 float64）
commissionRate := decimal.NewFromString("0.001")
commission := price.Mul(decimal.NewFromInt(100)).Mul(commissionRate).Round(2)

// 序列化回 JSON
response := map[string]interface{}{
  "limit_price": price.String(),      // Decimal → "150.2567"
  "commission": commission.String(),   // Decimal → "0.30"
}

json.Marshal(response) // → {"limit_price": "150.2567", "commission": "0.30"}
```

**Dart 示例**：
```dart
import 'package:decimal/decimal.dart';

// 读取请求参数
final limitPrice = Decimal.parse('150.2567');

// 计算
final commission = (limitPrice * Decimal.fromInt(100) * Decimal.parse('0.001'))
    .toDecimal(scaleOnInfinitePrecision: 2);

// 序列化回 JSON
final json = {
  'limit_price': limitPrice.toString(),    // "150.2567"
  'commission': commission.toString(),     // "0.30"
};
```

---

## 2. Timestamp（时间戳）

**规则**：所有时间戳使用 **ISO 8601 格式，带 Z 表示 UTC**，精度到**毫秒**。

### 2.1 格式规范

```
标准格式：2026-03-31T09:30:00.123Z
           │        │ │ │  │  │  │
           年       月 日 时 分 秒 毫秒（3 位）+ Z（UTC 标记）
```

### 2.2 示例

```json
{
  // ✅ 正确示例
  "created_at": "2026-03-31T09:30:00.123Z",    // 标准格式，UTC
  "updated_at": "2026-03-31T09:45:00.456Z",    // 毫秒精度
  "expires_at": "2026-03-31T20:00:00.000Z",    // 整秒时毫秒为 .000

  // ❌ 错误示例
  "created_at": "2026-03-31 09:30:00",         // 错误：无 T、无 Z
  "created_at": "2026-03-31T09:30:00+08:00",   // 错误：含时区偏移，应为 UTC
  "created_at": "1711863000",                  // 错误：Unix timestamp，难以阅读
  "created_at": "2026-03-31T09:30:00.1234Z",   // 错误：4 位毫秒，应为 3 位
}
```

### 2.3 后端处理

**Go 示例**：
```go
import "time"

// 始终使用 UTC
now := time.Now().UTC()
createdAt := now.Format(time.RFC3339Nano)[:23] + "Z"  // "2026-03-31T09:30:00.123Z"

// JSON 序列化
response := map[string]interface{}{
  "created_at": createdAt,
}

// 反序列化
var req struct {
  CreatedAt string `json:"created_at"`
}
timestamp, _ := time.Parse(time.RFC3339, req.CreatedAt)  // 自动解析 Z 为 UTC
```

**Dart 示例**：
```dart
// 使用 UTC
final now = DateTime.now().toUtc();
final createdAt = now.toIso8601String();  // "2026-03-31T09:30:00.123Z"

// JSON 序列化
final json = {
  'created_at': createdAt,
};
```

---

## 3. Quantity（数量）

**规则**：持仓数量、成交数量使用 **number 类型**（JSON 中的整数或小数），不使用 string。

### 3.1 格式规范

| 字段 | 类型 | 说明 |
|------|------|------|
| `quantity` | integer | 整数（美股 100 股、港股 100 股） |
| `filled_qty` | integer | 整数 |
| `settled_qty` | integer | 整数 |
| `unsettled_qty` | integer | 整数 |

### 3.2 示例

```json
{
  // ✅ 正确示例
  "quantity": 100,                // 整数（number 类型）
  "filled_qty": 50,
  "settled_qty": 100,
  "unsettled_qty": 0,

  // ❌ 错误示例
  "quantity": "100",              // 错误：string 类型，应为 number
  "quantity": 100.5,              // 错误：小数（Phase 1 不支持碎股）
}
```

---

## 4. Enum（枚举值）

**规则**：枚举值使用 **string 类型，全大写下划线分隔**。

### 4.1 常见枚举

| 枚举类型 | 允许值 | 说明 |
|---------|--------|------|
| `side` | "BUY", "SELL" | 订单方向 |
| `order_type` | "LIMIT", "MARKET" | 订单类型 |
| `status` | 见 order-lifecycle.md §1 | 订单内部状态 |
| `display_status` | 见 order-lifecycle.md §4 | 用户可见状态 |
| `time_in_force` | "DAY", "GTC" | 有效期 |
| `market` | "US", "HK" | 市场 |
| `orde_type` | "LIMIT", "MARKET" | 订单类型 |

### 4.2 示例

```json
{
  // ✅ 正确示例
  "side": "BUY",                  // 全大写
  "order_type": "LIMIT",          // 全大写，无空格
  "status": "FILLED",
  "time_in_force": "DAY",
  "market": "US",

  // ❌ 错误示例
  "side": "buy",                  // 错误：小写
  "side": "Buy",                  // 错误：首字母大写
  "order_type": "limit_order",    // 错误：全大写下划线，不是驼峰
  "status": "FILLED_PARTIAL",     // 错误：自定义值（应使用定义的枚举）
}
```

---

## 5. Percentage（百分比）

**规则**：百分比值使用 **number 类型，已乘以 100，不含 % 符号**。

### 5.1 格式

```json
{
  // ✅ 正确示例
  "unrealized_pnl_pct": 1.29,          // 表示 1.29%（数字，已乘以 100）
  "concentration_ratio": 35.5,         // 表示 35.5%
  "day_pnl_pct": 0.42,                 // 表示 0.42%

  // ❌ 错误示例
  "pnl_pct": "1.29%",                  // 错误：含 % 符号，应为纯数字
  "pnl_pct": "1.29",                   // 错误：string 类型，应为 number
  "pnl_pct": 0.0129,                   // 错误：未乘以 100（表示 1.29%）
}
```

### 5.2 前端显示

```javascript
// 后端返回
const response = {
  unrealized_pnl_pct: 1.29
};

// 前端显示
const displayText = response.unrealized_pnl_pct + '%';  // "1.29%"
```

---

## 6. Boolean（布尔值）

**规则**：使用 JSON 标准 `true`/`false`（小写，不含引号）。

### 6.1 示例

```json
{
  // ✅ 正确示例
  "allow_premarket": true,            // 小写 true
  "wash_sale_flag": false,            // 小写 false
  "is_restricted": true,

  // ❌ 错误示例
  "allow_premarket": "true",          // 错误：string 类型
  "allow_premarket": True,            // 错误：Python 风格大写
  "allow_premarket": 1,               // 错误：用数字代替
}
```

---

## 7. Currency Code（货币代码）

**规则**：货币代码使用 ISO 4217 标准，全大写（3 字母）。

### 7.1 示例

```json
{
  // ✅ 正确示例
  "currency": "USD",                  // 美元
  "currency": "HKD",                  // 港币
  "currency": "CNY",                  // 人民币

  // ❌ 错误示例
  "currency": "usd",                  // 错误：小写
  "currency": "US$",                  // 错误：带符号
  "currency": "DOLLAR",               // 错误：全名
}
```

---

## 8. Null 值处理

**规则**：字段不存在时用 **`null`**，不要省略字段。

### 8.1 示例

```json
{
  // ✅ 正确示例
  "limit_price": "150.00",            // 有价格
  "filled_at": "2026-03-31T09:35:00Z",  // 有成交时间

  // 当没有价格时（市价单）
  "limit_price": null,                // 显式为 null
  "filled_at": null,                  // 未成交时为 null

  // ❌ 错误示例
  // "limit_price": <不包含此字段>  // 错误：省略字段
  // "filled_at": <不包含此字段>    // 错误：省略字段
}
```

---

## 9. 数组 vs 对象

**规则**：
- **数组**：相同类型的多个元素（如成交明细列表）
- **对象**：不同属性的集合（如订单详情）

### 9.1 示例

```json
{
  // ✅ 正确示例（成交明细数组）
  "fills": [
    {
      "fill_id": "fill-001",
      "fill_qty": 30,
      "fill_price": "150.10"
    },
    {
      "fill_id": "fill-002",
      "fill_qty": 20,
      "fill_price": "150.14"
    }
  ],

  // ✅ 正确示例（汇总对象）
  "summary": {
    "total_market_value": "30045.00",
    "total_cost_basis": "29664.00"
  },

  // ❌ 错误示例（混淆）
  "fills": {                          // 错误：应为数组，不是对象
    "fill-001": {...},
    "fill-002": {...}
  }
}
```

---

## 10. 嵌套对象深度

**规则**：嵌套深度不超过 3 层，保持 JSON 结构清晰。

### 10.1 示例

```json
{
  // ✅ 正确（深度 3）
  "order_id": "ord-abc123",           // 1 层
  "details": {                        // 2 层
    "risk_checks": {                  // 3 层
      "account_status": "APPROVED"
    }
  },

  // ❌ 避免（深度 4+）
  "order": {                          // 1 层
    "details": {                      // 2 层
      "risk": {                       // 3 层
        "checks": {                   // 4 层（过深）
          "account": "APPROVED"
        }
      }
    }
  }
}
```

---

## 11. 字段命名规范

**规则**：使用**蛇形命名法**（snake_case），不使用驼峰或其他风格。

### 11.1 示例

```json
{
  // ✅ 正确（蛇形命名法）
  "order_id": "...",
  "limit_price": "...",
  "filled_qty": "...",
  "avg_fill_price": "...",
  "risk_checks": {...},
  "settlement_date": "...",

  // ❌ 错误
  "orderId": "...",                   // 驼峰
  "LimitPrice": "...",                // 帕斯卡
  "limit-price": "...",               // 肉串
  "LIMIT_PRICE": "...",               // 全大写
}
```

---

## 12. 兼容性与扩展

### 12.1 字段添加（向前兼容）

新增字段时，不要修改现有字段的类型或名称，只在末尾追加新字段。

```json
// v1 响应
{
  "order_id": "ord-abc123",
  "status": "FILLED"
}

// v2 响应（向前兼容）
{
  "order_id": "ord-abc123",
  "status": "FILLED",
  "display_status": "已成交"    // 新增字段
}
```

### 12.2 字段弃用

不要删除字段，改为标记为弃用，并通知客户端。

---

## 13. 工具和验证

### Go 中的验证

```go
import "github.com/shopspring/decimal"

// 验证 decimal 格式
func ValidatePrice(priceStr string, maxDecimalPlaces int) error {
  price, err := decimal.NewFromString(priceStr)
  if err != nil {
    return fmt.Errorf("invalid decimal format: %v", err)
  }

  actualPlaces := price.Exponent() * -1
  if actualPlaces > int32(maxDecimalPlaces) {
    return fmt.Errorf("too many decimal places: %d, max: %d", actualPlaces, maxDecimalPlaces)
  }

  return nil
}

// 验证 ISO 8601 timestamp
func ValidateTimestamp(ts string) error {
  _, err := time.Parse(time.RFC3339, ts)
  return err
}
```

### 移动端中的验证

```dart
// 验证 decimal 格式
bool isValidPrice(String price, int maxDecimalPlaces) {
  try {
    final decimal = Decimal.parse(price);
    final parts = price.split('.');
    if (parts.length == 2 && parts[1].length > maxDecimalPlaces) {
      return false;
    }
    return true;
  } catch (e) {
    return false;
  }
}

// 验证 ISO 8601 timestamp
bool isValidTimestamp(String ts) {
  try {
    DateTime.parse(ts);
    return ts.endsWith('Z');  // 必须是 UTC
  } catch (e) {
    return false;
  }
}
```

