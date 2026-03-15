---
type: api-spec
version: v2.0
date: 2026-03-14
supersedes: v1.2.0 (2026-03-09)
surface_prd: mobile/docs/prd/03-market.md
status: ACTIVE
---

# 行情模块 REST API 规范

> 本文档是行情模块 REST API 的权威规范，与 PRD-03 v1.1 完全对齐。所有接口实现和客户端集成须以本文档为准。
>
> WebSocket 推送协议详见 `docs/specs/websocket-mock.md`。

---

## 1. 总体约定

### 1.1 基础路径

```
https://api.example.com
```

所有接口均以 `/v1` 为前缀。

### 1.2 数据类型规范

| 约定 | 规则 | 示例 |
|------|------|------|
| 价格字段 | 统一使用 **string** 类型，禁止 float/double | `"182.5200"` |
| 涨跌幅 | string 类型，保留 2 位小数，含正负号 | `"1.35"` / `"-0.82"` |
| 时间戳 | ISO 8601 UTC 格式，精确到毫秒 | `"2026-03-13T14:30:00.000Z"` |
| 整数量 | int64，不加引号 | `45200000` |
| 金额大值 | string 类型，带单位后缀 | `"2.80T"` / `"780.00B"` |

**价格精度**

| 市场 | 价格精度 | 涨跌额精度 |
|------|---------|-----------|
| 美股 (US) | 4 位小数 | 4 位小数 |
| 港股 (HK) | 3 位小数 | 3 位小数 |

### 1.3 响应格式

接口直接返回业务数据对象，不使用 `code/message/data` 三层包装。错误通过 HTTP 状态码区分，响应体为统一错误对象（详见第 9 节）。

**成功响应示例（HTTP 200）**

```json
{
  "quotes": { ... },
  "as_of": "2026-03-13T14:30:00.000Z"
}
```

**错误响应示例（HTTP 400）**

```json
{
  "error": "TOO_MANY_SYMBOLS",
  "message": "symbols 参数最多允许 50 个",
  "details": { "max": 50, "provided": 55 }
}
```

### 1.4 市场状态枚举

`market_status` 字段的合法值：

| 值 | 含义 |
|----|------|
| `REGULAR` | 常规交易时段 |
| `PRE_MARKET` | 盘前交易（美股） |
| `AFTER_HOURS` | 盘后交易（美股） |
| `CLOSED` | 已收盘 |
| `HALTED` | 临时停牌 |

### 1.5 认证规则

| 接口前缀 | 认证要求 | delayed 行为 |
|---------|---------|-------------|
| `GET /v1/market/*` | 不强制认证 | 携带有效 JWT → `delayed: false`；未携带或无效 → `delayed: true` |
| `GET /v1/watchlist` | 必须 `Authorization: Bearer <JWT>` | 始终 `delayed: false` |
| `POST /v1/watchlist` | 必须 `Authorization: Bearer <JWT>` | — |
| `DELETE /v1/watchlist/{symbol}` | 必须 `Authorization: Bearer <JWT>` | — |

未携带 JWT 或 JWT 无效时，`/v1/watchlist` 返回 `401 UNAUTHORIZED`。

### 1.6 限流规则

| 接口类型 | 限流 | 窗口 |
|---------|------|------|
| 行情相关 (`/v1/market/*`) | 100 req/s | per IP |
| 自选股 (`/v1/watchlist`) | 30 req/s | per user |
| 搜索 (`/v1/market/search`) | 30 req/s | per IP |

触发限流返回 `429 RATE_LIMIT_EXCEEDED`，响应头包含 `Retry-After: <秒数>`。

### 1.7 数据质量字段（`is_stale`）

所有包含行情价格的响应均须携带 `is_stale` 字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_stale` | bool | `true` = 数据超过展示阈值（5s），提示用户数据可能延迟 |
| `stale_since_ms` | int | 数据陈旧持续时长（毫秒），`is_stale=false` 时为 0 |

> 注：`is_stale` 用于前端展示警告。交易引擎使用更严格的 1s 阈值（通过 gRPC 内部接口），两者阈值不同，不要混淆。

### 1.8 涨跌幅（`change` / `change_pct`）计算基准

```
change     = last_price - prev_regular_close
change_pct = (change / prev_regular_close) × 100

基准价 = 前一个交易日 Regular Session 收盘价（NYSE/NASDAQ 16:00:00 ET）
       ≠ 盘后收盘价（After-Hours Close）

盘前/盘后阶段的 change/change_pct 同样以 prev_regular_close 为基准
```

Polygon.io 推送的 `change` 字段遵循此定义，无需在应用层二次计算。

### 1.9 复权说明

历史 K 线数据（日线/周线/月线）使用 **Split + Dividend 全复权（后复权）**：
- 最新价格保持不变，历史价格已按累积系数调整
- 分时图（当日）和实时报价使用原始价格，不复权
- 详细计算规范见 `market-data-system.md` 附录 C

---

## 2. 接口列表

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | `/v1/market/quotes` | 批量行情快照 | 可选 |
| GET | `/v1/market/kline` | K 线数据 | 可选 |
| GET | `/v1/market/search` | 股票搜索 | 可选 |
| GET | `/v1/market/movers` | 涨跌幅榜 / 热门榜 | 可选 |
| GET | `/v1/market/stocks/{symbol}` | 股票详情 | 可选 |
| GET | `/v1/market/news/{symbol}` | 相关新闻 | 可选 |
| GET | `/v1/market/financials/{symbol}` | 财报数据 | 可选 |
| GET | `/v1/watchlist` | 获取自选股 | 必须 |
| POST | `/v1/watchlist` | 添加自选股 | 必须 |
| DELETE | `/v1/watchlist/{symbol}` | 删除自选股 | 必须 |

---

## 3. GET /v1/market/quotes — 批量行情快照

### 3.1 接口描述

批量获取多只股票的实时行情快照。支持混合市场查询（美股 + 港股在同一请求中）。

未认证用户返回延时行情（`delayed: true`），持有有效 JWT 的用户返回实时行情（`delayed: false`）。

### 3.2 请求参数

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| `symbols` | query | string | 是 | 逗号分隔的股票代码，最多 50 个。美股用字母代码（如 `AAPL`），港股用数字代码（如 `0700`） |

**示例**

```
GET /v1/market/quotes?symbols=AAPL,TSLA,MSFT,0700
Authorization: Bearer <JWT>   (可选)
```

### 3.3 响应字段说明

**顶层字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `quotes` | object | 以 symbol 为 key 的行情快照 map |
| `as_of` | string (ISO 8601) | 数据快照时间 |

**quotes[symbol] 字段**

| 字段 | 类型 | 精度 | 说明 |
|------|------|------|------|
| `symbol` | string | — | 股票代码 |
| `name` | string | — | 公司英文名称 |
| `name_zh` | string | — | 公司中文名称 |
| `market` | string | — | 市场：`US` / `HK` |
| `price` | string | 4位 | 最新成交价 |
| `change` | string | 4位 | 涨跌额（相对前收盘价） |
| `change_pct` | string | 2位 | 涨跌幅（%），含正负号 |
| `volume` | int64 | — | 当日累计成交量（股） |
| `bid` | string | 4位 | 买一价 |
| `ask` | string | 4位 | 卖一价 |
| `turnover` | string | — | 当日成交额，带单位（如 `"1.23B"`） |
| `prev_close` | string | 4位 | 前一交易日收盘价 |
| `open` | string | 4位 | 当日开盘价 |
| `high` | string | 4位 | 当日最高价 |
| `low` | string | 4位 | 当日最低价 |
| `market_cap` | string | — | 市值，带单位（如 `"2.80T"`） |
| `pe_ratio` | string | — | 市盈率（TTM） |
| `delayed` | bool | — | `true` 表示延时行情（15 分钟），`false` 表示实时行情 |
| `market_status` | string | — | 市场状态枚举（见 1.4 节） |

### 3.4 成功响应示例

```json
{
  "quotes": {
    "AAPL": {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "name_zh": "苹果",
      "market": "US",
      "price": "182.5200",
      "change": "2.3400",
      "change_pct": "1.30",
      "volume": 45200000,
      "bid": "182.5100",
      "ask": "182.5300",
      "turnover": "8.24B",
      "prev_close": "180.1800",
      "open": "180.5000",
      "high": "183.1200",
      "low": "180.2500",
      "market_cap": "2.80T",
      "pe_ratio": "28.50",
      "delayed": false,
      "market_status": "REGULAR"
    },
    "TSLA": {
      "symbol": "TSLA",
      "name": "Tesla, Inc.",
      "name_zh": "特斯拉",
      "market": "US",
      "price": "241.3800",
      "change": "-3.2100",
      "change_pct": "-1.31",
      "volume": 52100000,
      "bid": "241.3500",
      "ask": "241.4200",
      "turnover": "12.57B",
      "prev_close": "244.5900",
      "open": "244.0000",
      "high": "245.8800",
      "low": "240.1100",
      "market_cap": "768.00B",
      "pe_ratio": "65.30",
      "delayed": false,
      "market_status": "REGULAR"
    }
  },
  "as_of": "2026-03-13T14:30:00.000Z"
}
```

### 3.5 错误响应示例

**symbols 超过 50 个（HTTP 400）**

```json
{
  "error": "TOO_MANY_SYMBOLS",
  "message": "symbols 参数最多允许 50 个",
  "details": { "max": 50, "provided": 55 }
}
```

**symbols 参数缺失（HTTP 400）**

```json
{
  "error": "INVALID_SYMBOL",
  "message": "symbols 参数不能为空"
}
```

### 3.6 备注

- 若某个 symbol 不存在或无法找到行情，该 symbol 的 key 不出现在 `quotes` map 中，而非返回错误。
- 港股代码需保持与交易所一致的格式（如 `0700`，前置零不可省略）。
- 当市场已收盘时，`price` 返回当日收盘价，`market_status` 为 `CLOSED`。

---

## 4. GET /v1/market/kline — K 线数据

### 4.1 接口描述

查询股票 OHLCV K 线数据，支持多个时间周期。日线及以上周期支持 cursor 分页；分钟线（`period=1min`，仅日内查询）一次性返回当日完整交易时段数据，不支持 cursor。

### 4.2 请求参数

| 参数 | 位置 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|------|--------|------|
| `symbol` | query | string | 是 | — | 股票代码 |
| `period` | query | string | 是 | — | 时间周期，见枚举表 |
| `from` | query | string | 否 | — | 查询起始时间，ISO 8601（`1min` 时为 `YYYY-MM-DD`） |
| `to` | query | string | 否 | 当前时间 | 查询截止时间，ISO 8601 |
| `limit` | query | int | 否 | `100` | 返回 K 线数量上限，最大 `500`（`1min` 无效） |
| `cursor` | query | string | 否 | — | 分页游标，来自上一页响应的 `next_cursor`（`1min` 无效） |

**period 枚举**

| 值 | 说明 |
|----|------|
| `1min` | 1 分钟 K 线（仅日内，配合 `from=YYYY-MM-DD` 使用） |
| `5min` | 5 分钟 K 线 |
| `15min` | 15 分钟 K 线 |
| `30min` | 30 分钟 K 线 |
| `60min` | 60 分钟（1 小时）K 线 |
| `1d` | 日 K |
| `1w` | 周 K |
| `1mo` | 月 K |

**示例请求**

```
# 查询日 K（cursor 分页）
GET /v1/market/kline?symbol=AAPL&period=1d&from=2026-01-01T00:00:00Z&to=2026-03-13T23:59:59Z&limit=100

# 查询 1 分钟 K（日内全量，无 cursor）
GET /v1/market/kline?symbol=AAPL&period=1min&from=2026-03-13
```

### 4.3 响应字段说明

**顶层字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `symbol` | string | 股票代码 |
| `period` | string | 时间周期 |
| `candles` | array | K 线数组，按时间升序排列 |
| `next_cursor` | string \| null | 下一页游标，`null` 表示已到最后一页；`1min` 模式始终为 `null` |
| `total` | int | 本次响应返回的 K 线根数 |

**candles[i] 字段**

| 字段 | 类型 | 精度 | 说明 |
|------|------|------|------|
| `t` | string (ISO 8601) | — | K 线开始时间（UTC） |
| `o` | string | 4位 | 开盘价 |
| `h` | string | 4位 | 最高价 |
| `l` | string | 4位 | 最低价 |
| `c` | string | 4位 | 收盘价 |
| `v` | int64 | — | 成交量（股） |
| `n` | int | — | 成交笔数 |

### 4.4 成功响应示例

**日 K 查询（有下一页）**

```json
{
  "symbol": "AAPL",
  "period": "1d",
  "candles": [
    {
      "t": "2026-01-02T14:30:00.000Z",
      "o": "185.0000",
      "h": "187.2500",
      "l": "184.1300",
      "c": "186.8800",
      "v": 48320000,
      "n": 312450
    },
    {
      "t": "2026-01-05T14:30:00.000Z",
      "o": "186.5000",
      "h": "188.9000",
      "l": "185.7700",
      "c": "187.4200",
      "v": 41100000,
      "n": 278310
    }
  ],
  "next_cursor": "eyJsYXN0X3QiOiIyMDI2LTAxLTA1VDE0OjMwOjAwWiJ9",
  "total": 2
}
```

**1 分钟 K（日内，无 cursor）**

```json
{
  "symbol": "AAPL",
  "period": "1min",
  "candles": [
    {
      "t": "2026-03-13T14:30:00.000Z",
      "o": "181.5000",
      "h": "181.8800",
      "l": "181.4200",
      "c": "181.7500",
      "v": 1250300,
      "n": 8420
    },
    {
      "t": "2026-03-13T14:31:00.000Z",
      "o": "181.7500",
      "h": "182.1000",
      "l": "181.6800",
      "c": "182.0200",
      "v": 980100,
      "n": 6510
    }
  ],
  "next_cursor": null,
  "total": 390
}
```

### 4.5 错误响应示例

**不合法的 period 值（HTTP 400）**

```json
{
  "error": "INVALID_PERIOD",
  "message": "period 参数不合法，合法值为：1min, 5min, 15min, 30min, 60min, 1d, 1w, 1mo",
  "details": { "provided": "2h" }
}
```

**cursor 格式错误或已过期（HTTP 400）**

```json
{
  "error": "INVALID_CURSOR",
  "message": "cursor 无效或已过期，请重新查询第一页"
}
```

**symbol 不存在（HTTP 404）**

```json
{
  "error": "SYMBOL_NOT_FOUND",
  "message": "股票代码 AAPL 不存在或暂无数据"
}
```

**指定时间范围内无数据（HTTP 404）**

```json
{
  "error": "NO_DATA",
  "message": "指定时间范围内无 K 线数据"
}
```

### 4.6 备注

- `1min` 模式：`from` 参数格式为 `YYYY-MM-DD`，返回该交易日常规交易时段（NYSE/NASDAQ 为 09:30–16:00 ET，约 390 根）全量数据；`limit` 和 `cursor` 参数在此模式下无效。
- K 线时间戳 `t` 表示该根 K 线的**开始**时间，均为 UTC。
- 日 K 及以上周期，当最后一页时 `next_cursor` 为 `null`。
- 历史数据可用范围：日线最多 5 年，分钟线最多 90 天（在线），逐笔数据最多 5 天（在线）。

---

## 5. GET /v1/market/search — 股票搜索

### 5.1 接口描述

模糊搜索股票，支持代码精确/前缀匹配、英文名前缀/包含匹配、中文名包含匹配、拼音首字母匹配。客户端建议对用户输入做 300ms debounce 后再发起请求。

**Phase 1 限制**：当前阶段仅返回美股（US）市场结果，`market` 参数暂不生效。

### 5.2 请求参数

| 参数 | 位置 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|------|--------|------|
| `q` | query | string | 是 | — | 搜索关键词，最少 1 个字符 |
| `market` | query | string | 否 | `US` | 市场筛选：`US` / `HK`（Phase 1 仅 `US` 生效） |
| `limit` | query | int | 否 | `10` | 返回数量上限，最大 `50` |

**示例**

```
GET /v1/market/search?q=apple&market=US&limit=20
GET /v1/market/search?q=AAPL&limit=5
GET /v1/market/search?q=yy&limit=10
```

### 5.3 响应字段说明

**顶层字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `results` | array | 搜索结果列表，按相关度降序 |
| `total` | int | 命中结果总数（可能多于 `limit`） |

**results[i] 字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `symbol` | string | 股票代码 |
| `name` | string | 公司英文名称 |
| `name_zh` | string | 公司中文名称 |
| `market` | string | 市场：`US` / `HK` |
| `price` | string | 最新价（4 位小数） |
| `change_pct` | string | 涨跌幅（%，2 位小数） |
| `delayed` | bool | 是否为延时行情 |

### 5.4 成功响应示例

```json
{
  "results": [
    {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "name_zh": "苹果",
      "market": "US",
      "price": "182.5200",
      "change_pct": "1.30",
      "delayed": true
    },
    {
      "symbol": "APLE",
      "name": "Apple Hospitality REIT, Inc.",
      "name_zh": "苹果酒店房产投资信托",
      "market": "US",
      "price": "15.8800",
      "change_pct": "-0.44",
      "delayed": true
    }
  ],
  "total": 2
}
```

### 5.5 错误响应示例

**q 参数缺失（HTTP 400）**

```json
{
  "error": "INVALID_SYMBOL",
  "message": "搜索关键词 q 不能为空"
}
```

### 5.6 备注

- 搜索排序优先级：代码精确匹配 > 代码前缀匹配 > 名称精确匹配 > 名称前缀匹配 > 名称包含匹配。
- 拼音首字母支持常见中文名，如 `pg` 可匹配"苹果"（`pínguǒ`）。
- 搜索结果中的行情数据遵循认证规则（未认证则 `delayed: true`）。
- Phase 1 仅支持 US 市场；HK 市场将在后续版本开放。

---

## 6. GET /v1/market/movers — 涨跌幅榜 / 热门榜

### 6.1 接口描述

获取当日涨幅榜、跌幅榜或热门成交榜。涨跌榜仅收录成交量大于 100 万股的标的，以过滤低流动性股票。

### 6.2 请求参数

| 参数 | 位置 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|------|--------|------|
| `type` | query | string | 是 | — | 榜单类型：`gainers`（涨幅榜）/ `losers`（跌幅榜）/ `hot`（热门榜） |
| `market` | query | string | 否 | `US` | 市场：`US` / `HK` |
| `limit` | query | int | 否 | `20` | 返回数量上限，最大 `50` |

**示例**

```
GET /v1/market/movers?type=gainers&market=US&limit=20
GET /v1/market/movers?type=hot&market=US&limit=10
```

### 6.3 响应字段说明

**顶层字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `type` | string | 榜单类型（与请求一致） |
| `market` | string | 市场 |
| `items` | array | 榜单条目 |
| `as_of` | string (ISO 8601) | 数据更新时间 |

**items[i] 字段**

| 字段 | 类型 | 精度 | 说明 |
|------|------|------|------|
| `rank` | int | — | 排名（从 1 开始） |
| `symbol` | string | — | 股票代码 |
| `name` | string | — | 公司英文名称 |
| `name_zh` | string | — | 公司中文名称 |
| `price` | string | 4位 | 最新价 |
| `change` | string | 4位 | 涨跌额 |
| `change_pct` | string | 2位 | 涨跌幅（%） |
| `volume` | int64 | — | 当日成交量（股） |
| `turnover` | string | — | 当日成交额，带单位 |
| `market_status` | string | — | 市场状态枚举 |

### 6.4 成功响应示例

```json
{
  "type": "gainers",
  "market": "US",
  "items": [
    {
      "rank": 1,
      "symbol": "NVDA",
      "name": "NVIDIA Corporation",
      "name_zh": "英伟达",
      "price": "865.2100",
      "change": "52.3300",
      "change_pct": "6.44",
      "volume": 38500000,
      "turnover": "33.31B",
      "market_status": "REGULAR"
    },
    {
      "rank": 2,
      "symbol": "META",
      "name": "Meta Platforms, Inc.",
      "name_zh": "Meta",
      "price": "482.7500",
      "change": "21.5000",
      "change_pct": "4.66",
      "volume": 15200000,
      "turnover": "7.34B",
      "market_status": "REGULAR"
    }
  ],
  "as_of": "2026-03-13T14:30:00.000Z"
}
```

### 6.5 错误响应示例

**type 参数不合法（HTTP 400）**

```json
{
  "error": "INVALID_PERIOD",
  "message": "type 参数不合法，合法值为：gainers, losers, hot",
  "details": { "provided": "winners" }
}
```

### 6.6 备注

- `gainers` / `losers` 仅收录当日成交量 > 1,000,000 股的标的，防止低流动性股票刷榜。
- `hot` 榜按综合热度排序（成交额 + 搜索热度加权），无最低成交量要求。
- 非交易时段（`CLOSED`）返回当日最终数据并标注 `as_of`。

---

## 7. GET /v1/market/stocks/{symbol} — 股票详情

### 7.1 接口描述

获取单只股票的完整信息，包含实时行情、基本面、52 周高低、换手率等。

### 7.2 路径参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `symbol` | string | 是 | 股票代码（如 `AAPL`、`0700`） |

**示例**

```
GET /v1/market/stocks/AAPL
Authorization: Bearer <JWT>   (可选)
```

### 7.3 响应字段说明

**行情字段**

| 字段 | 类型 | 精度 | 说明 |
|------|------|------|------|
| `symbol` | string | — | 股票代码 |
| `name` | string | — | 公司英文名称 |
| `name_zh` | string | — | 公司中文名称 |
| `market` | string | — | 市场：`US` / `HK` |
| `price` | string | 4位 | 最新价 |
| `change` | string | 4位 | 涨跌额 |
| `change_pct` | string | 2位 | 涨跌幅（%） |
| `open` | string | 4位 | 当日开盘价 |
| `high` | string | 4位 | 当日最高价 |
| `low` | string | 4位 | 当日最低价 |
| `prev_close` | string | 4位 | 前收盘价 |
| `volume` | int64 | — | 当日成交量 |
| `turnover` | string | — | 当日成交额，带单位 |
| `bid` | string | 4位 | 买一价 |
| `ask` | string | 4位 | 卖一价 |
| `delayed` | bool | — | 是否延时行情 |
| `market_status` | string | — | 市场状态枚举 |
| `session` | string | — | 当前交易时段描述，如 `"Regular Trading Hours"` |

**基本面字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `market_cap` | string | 市值，带单位（如 `"2.80T"`） |
| `pe_ratio` | string | 市盈率（TTM） |
| `pb_ratio` | string | 市净率 |
| `dividend_yield` | string | 股息率（%），无分红则为 `"0.00"` |
| `shares_outstanding` | int64 | 总股本（股） |
| `avg_volume` | int64 | 近 30 日日均成交量 |
| `week52_high` | string | 52 周最高价（4 位小数） |
| `week52_low` | string | 52 周最低价（4 位小数） |
| `turnover_rate` | string | 换手率（%，2 位小数）= 当日成交量 / 总股本 × 100 |
| `exchange` | string | 上市交易所（如 `"NASDAQ"`、`"HKEX"`） |
| `sector` | string | 行业板块（英文） |
| `as_of` | string (ISO 8601) | 数据快照时间 |

### 7.4 成功响应示例

```json
{
  "symbol": "AAPL",
  "name": "Apple Inc.",
  "name_zh": "苹果",
  "market": "US",
  "price": "182.5200",
  "change": "2.3400",
  "change_pct": "1.30",
  "open": "180.5000",
  "high": "183.1200",
  "low": "180.2500",
  "prev_close": "180.1800",
  "volume": 45200000,
  "turnover": "8.24B",
  "bid": "182.5100",
  "ask": "182.5300",
  "delayed": false,
  "market_status": "REGULAR",
  "session": "Regular Trading Hours",
  "market_cap": "2.80T",
  "pe_ratio": "28.50",
  "pb_ratio": "42.30",
  "dividend_yield": "0.52",
  "shares_outstanding": 15204137000,
  "avg_volume": 48500000,
  "week52_high": "199.6200",
  "week52_low": "164.0800",
  "turnover_rate": "0.30",
  "exchange": "NASDAQ",
  "sector": "Technology",
  "as_of": "2026-03-13T14:30:00.000Z"
}
```

### 7.5 错误响应示例

**symbol 不存在（HTTP 404）**

```json
{
  "error": "SYMBOL_NOT_FOUND",
  "message": "股票代码 XXXX 不存在"
}
```

### 7.6 备注

- `turnover_rate` 计算公式：`当日成交量 / shares_outstanding × 100`，保留 2 位小数。
- 盘前/盘后时段，`price` 反映延伸时段最新成交价，`market_status` 相应为 `PRE_MARKET` 或 `AFTER_HOURS`。
- 基本面数据每日收盘后更新；`as_of` 精确反映最新数据时间。

---

## 8. GET /v1/market/news/{symbol} — 相关新闻

### 8.1 接口描述

获取指定股票的相关新闻列表，按发布时间降序排列，支持分页。

### 8.2 路径 + 请求参数

| 参数 | 位置 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|------|--------|------|
| `symbol` | path | string | 是 | — | 股票代码 |
| `page` | query | int | 否 | `1` | 页码（从 1 开始） |
| `page_size` | query | int | 否 | `10` | 每页条数，最大 `50` |

**示例**

```
GET /v1/market/news/AAPL?page=1&page_size=20
```

### 8.3 响应字段说明

**顶层字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `symbol` | string | 股票代码 |
| `news` | array | 新闻列表 |
| `page` | int | 当前页码 |
| `page_size` | int | 当前页实际条数 |
| `total` | int | 可用新闻总数 |

**news[i] 字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 新闻唯一 ID |
| `title` | string | 新闻标题 |
| `summary` | string | 摘要（约 2 行，≤ 150 字符） |
| `source` | string | 新闻来源（如 `"路透社"`、`"彭博社"`） |
| `published_at` | string (ISO 8601) | 发布时间（UTC） |
| `url` | string | 原文链接 |

### 8.4 成功响应示例

```json
{
  "symbol": "AAPL",
  "news": [
    {
      "id": "news_20260313_001",
      "title": "苹果发布 M4 Ultra 芯片，性能提升 40%",
      "summary": "苹果公司今日宣布推出新一代 M4 Ultra 芯片，相比上代产品性能提升幅度高达 40%，能效比亦显著改善。",
      "source": "路透社",
      "published_at": "2026-03-13T12:30:00.000Z",
      "url": "https://example.com/news/20260313/001"
    },
    {
      "id": "news_20260312_005",
      "title": "Q1 2026 财报超预期，营收同比增长 8%",
      "summary": "苹果 Q1 2026 财报显示营收达 1,241 亿美元，同比增长 8%，净利润 339 亿美元，每股收益 2.18 美元，均超分析师预期。",
      "source": "彭博社",
      "published_at": "2026-03-12T21:00:00.000Z",
      "url": "https://example.com/news/20260312/005"
    }
  ],
  "page": 1,
  "page_size": 2,
  "total": 25
}
```

### 8.5 错误响应示例

**symbol 不存在（HTTP 404）**

```json
{
  "error": "SYMBOL_NOT_FOUND",
  "message": "股票代码 XXXX 不存在"
}
```

### 8.6 备注

- 新闻来源可能包含第三方供应商（如 Benzinga、NewsAPI），`source` 字段展示原始媒体名称。
- 新闻数据每 5 分钟刷新一次，热点事件期间可能更频繁。

---

## 9. GET /v1/market/financials/{symbol} — 财报数据

### 9.1 接口描述

获取指定股票的季度财务报告数据，包含最近 4 个季度的业绩，以及下次财报披露日期。

### 9.2 路径参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `symbol` | string | 是 | 股票代码 |

**示例**

```
GET /v1/market/financials/AAPL
```

### 9.3 响应字段说明

**顶层字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `symbol` | string | 股票代码 |
| `next_earnings_date` | string (ISO 8601 日期) | 下次财报披露预期日期（格式 `YYYY-MM-DD`） |
| `next_earnings_quarter` | string | 下次财报对应季度（如 `"Q2 2026"`） |
| `quarters` | array | 最近 4 个季度财报，按时间降序 |

**quarters[i] 字段**

| 字段 | 类型 | 说明 |
|------|------|------|
| `period` | string | 财报季度（如 `"Q1 2026"`） |
| `report_date` | string | 财报发布日期（`YYYY-MM-DD`） |
| `revenue` | string | 营收，带单位（如 `"124.10B"`） |
| `net_income` | string | 净利润，带单位（如 `"33.90B"`） |
| `eps` | string | 每股收益（实际值，4 位小数） |
| `eps_estimate` | string | 每股收益（分析师预期，4 位小数） |
| `revenue_growth` | string | 营收同比增长率（%，2 位小数） |
| `net_income_growth` | string | 净利润同比增长率（%，2 位小数） |

### 9.4 成功响应示例

```json
{
  "symbol": "AAPL",
  "next_earnings_date": "2026-04-28",
  "next_earnings_quarter": "Q2 2026",
  "quarters": [
    {
      "period": "Q1 2026",
      "report_date": "2026-01-28",
      "revenue": "124.10B",
      "net_income": "33.90B",
      "eps": "2.1800",
      "eps_estimate": "2.1100",
      "revenue_growth": "8.20",
      "net_income_growth": "15.30"
    },
    {
      "period": "Q4 2025",
      "report_date": "2025-10-30",
      "revenue": "119.60B",
      "net_income": "32.10B",
      "eps": "2.0200",
      "eps_estimate": "1.9800",
      "revenue_growth": "6.10",
      "net_income_growth": "10.50"
    },
    {
      "period": "Q3 2025",
      "report_date": "2025-07-31",
      "revenue": "110.50B",
      "net_income": "29.50B",
      "eps": "1.8700",
      "eps_estimate": "1.8300",
      "revenue_growth": "4.80",
      "net_income_growth": "7.20"
    },
    {
      "period": "Q2 2025",
      "report_date": "2025-04-30",
      "revenue": "95.30B",
      "net_income": "25.80B",
      "eps": "1.6400",
      "eps_estimate": "1.6000",
      "revenue_growth": "3.20",
      "net_income_growth": "5.10"
    }
  ]
}
```

### 9.5 错误响应示例

**symbol 不存在（HTTP 404）**

```json
{
  "error": "SYMBOL_NOT_FOUND",
  "message": "股票代码 XXXX 不存在"
}
```

**尚无财报数据（HTTP 404）**

```json
{
  "error": "NO_DATA",
  "message": "暂无该股票的财报数据"
}
```

### 9.6 备注

- 财报数据来源为 Financial Modeling Prep，每日收盘后同步更新。
- `eps_estimate` 为财报发布前分析师一致预期，财报发布后保留历史预期值供对比。
- `revenue_growth` / `net_income_growth` 为同比（Year-over-Year）增长率，带正负号。

---

## 10. GET /v1/watchlist — 获取自选股

### 10.1 接口描述

获取当前用户的自选股列表，并附带每只股票的实时行情快照（格式与 `/v1/market/quotes` 一致）。

**认证**：必须携带 `Authorization: Bearer <JWT>`，否则返回 `401`。

### 10.2 请求参数

无。

**示例**

```
GET /v1/watchlist
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 10.3 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `symbols` | array[string] | 用户自选股代码列表，按添加时间升序 |
| `quotes` | object | 以 symbol 为 key 的行情快照 map，格式同 `/v1/market/quotes` 中的 `quotes[symbol]` |
| `as_of` | string (ISO 8601) | 行情快照时间 |

### 10.4 成功响应示例

```json
{
  "symbols": ["AAPL", "TSLA", "NVDA"],
  "quotes": {
    "AAPL": {
      "symbol": "AAPL",
      "name": "Apple Inc.",
      "name_zh": "苹果",
      "market": "US",
      "price": "182.5200",
      "change": "2.3400",
      "change_pct": "1.30",
      "volume": 45200000,
      "bid": "182.5100",
      "ask": "182.5300",
      "turnover": "8.24B",
      "prev_close": "180.1800",
      "open": "180.5000",
      "high": "183.1200",
      "low": "180.2500",
      "market_cap": "2.80T",
      "pe_ratio": "28.50",
      "delayed": false,
      "market_status": "REGULAR"
    },
    "TSLA": {
      "symbol": "TSLA",
      "name": "Tesla, Inc.",
      "name_zh": "特斯拉",
      "market": "US",
      "price": "241.3800",
      "change": "-3.2100",
      "change_pct": "-1.31",
      "volume": 52100000,
      "bid": "241.3500",
      "ask": "241.4200",
      "turnover": "12.57B",
      "prev_close": "244.5900",
      "open": "244.0000",
      "high": "245.8800",
      "low": "240.1100",
      "market_cap": "768.00B",
      "pe_ratio": "65.30",
      "delayed": false,
      "market_status": "REGULAR"
    },
    "NVDA": {
      "symbol": "NVDA",
      "name": "NVIDIA Corporation",
      "name_zh": "英伟达",
      "market": "US",
      "price": "865.2100",
      "change": "52.3300",
      "change_pct": "6.44",
      "volume": 38500000,
      "bid": "865.1800",
      "ask": "865.2500",
      "turnover": "33.31B",
      "prev_close": "812.8800",
      "open": "813.0000",
      "high": "868.5000",
      "low": "812.1100",
      "market_cap": "2.13T",
      "pe_ratio": "38.20",
      "delayed": false,
      "market_status": "REGULAR"
    }
  },
  "as_of": "2026-03-13T14:30:00.000Z"
}
```

---

## 11. POST /v1/watchlist — 添加自选股

### 11.1 接口描述

向用户自选股列表中添加一只股票。接口幂等：若该股票已在列表中，直接返回成功，不报错。

**认证**：必须携带 `Authorization: Bearer <JWT>`。

### 11.2 请求参数

**请求头**

```
Content-Type: application/json
Authorization: Bearer <JWT>
```

**请求体**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `symbol` | string | 是 | 待添加的股票代码 |

**示例**

```
POST /v1/watchlist
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "symbol": "AAPL"
}
```

### 11.3 成功响应示例（HTTP 200）

```json
{
  "symbol": "AAPL",
  "added_at": "2026-03-13T14:30:00.000Z"
}
```

### 11.4 错误响应示例

**股票代码不存在（HTTP 404）**

```json
{
  "error": "SYMBOL_NOT_FOUND",
  "message": "股票代码 XXXX 不存在"
}
```

**自选股已达上限（HTTP 400）**

```json
{
  "error": "WATCHLIST_FULL",
  "message": "自选股数量已达上限",
  "details": { "max": 100, "current": 100 }
}
```

### 11.5 备注

- 自选股上限为每用户 100 只。
- 幂等实现：底层执行 `INSERT OR IGNORE`，已存在时 `added_at` 返回原始添加时间。
- 添加前验证 symbol 是否在系统股票库中，不存在则返回 `404 SYMBOL_NOT_FOUND`。

---

## 12. DELETE /v1/watchlist/{symbol} — 删除自选股

### 12.1 接口描述

从用户自选股列表中移除指定股票。接口幂等：若该股票本不在列表中，也返回 `200`。

**认证**：必须携带 `Authorization: Bearer <JWT>`。

### 12.2 路径参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `symbol` | string | 是 | 待删除的股票代码 |

**示例**

```
DELETE /v1/watchlist/AAPL
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 12.3 成功响应示例（HTTP 200）

```json
{
  "symbol": "AAPL",
  "removed": true
}
```

当 symbol 本不在列表中时（幂等场景）：

```json
{
  "symbol": "AAPL",
  "removed": false
}
```

### 12.4 错误响应示例

**未认证（HTTP 401）**

```json
{
  "error": "UNAUTHORIZED",
  "message": "需要有效的 Authorization Bearer JWT"
}
```

### 12.5 备注

- 不论 symbol 是否在列表中，HTTP 状态码均为 `200`；`removed` 字段指示是否实际执行了删除。
- 不验证 symbol 是否在股票库中，允许删除已退市标的的自选记录。

---

## 13. 错误响应规范

### 13.1 错误响应格式

所有错误均使用以下统一格式：

```json
{
  "error": "ERROR_CODE",
  "message": "面向开发者的人类可读描述（中文）",
  "details": {}
}
```

`details` 为可选字段，仅在提供额外上下文时出现。

### 13.2 错误码一览

| HTTP 状态码 | error 值 | 触发场景 |
|------------|---------|---------|
| 400 | `TOO_MANY_SYMBOLS` | `/v1/market/quotes` 的 symbols 超过 50 个 |
| 400 | `INVALID_PERIOD` | K 线 period 或 movers type 参数不合法 |
| 400 | `INVALID_CURSOR` | cursor 格式错误或已过期 |
| 400 | `WATCHLIST_FULL` | 自选股数量已达 100 只上限 |
| 400 | `INVALID_SYMBOL` | symbol 格式不合法 / 必填参数缺失 |
| 401 | `UNAUTHORIZED` | 未携带 JWT 或 JWT 无效（仅 `/v1/watchlist`） |
| 404 | `SYMBOL_NOT_FOUND` | 股票代码不存在于系统股票库中 |
| 404 | `NO_DATA` | 股票存在但指定时间范围/条件下无数据 |
| 429 | `RATE_LIMIT_EXCEEDED` | 超过限流阈值 |
| 500 | `INTERNAL_ERROR` | 服务内部错误 |
| 500 | `DATA_SOURCE_UNAVAILABLE` | 上游数据源（Polygon、HKEX）不可用 |

### 13.3 限流响应示例（HTTP 429）

```json
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "请求过于频繁，请稍后重试",
  "details": { "retry_after_seconds": 5 }
}
```

响应头：

```
Retry-After: 5
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 2026-03-13T14:30:05.000Z
```

---

## 14. 附录

### 14.1 delayed 字段行为矩阵

| 场景 | delayed 值 | 数据延迟 |
|------|-----------|---------|
| 携带有效 JWT | `false` | 实时（< 500ms） |
| 未携带 JWT | `true` | 15 分钟 |
| 携带无效 JWT（`/v1/market/*`） | `true` | 15 分钟 |
| 携带无效 JWT（`/v1/watchlist`） | — | 返回 401，不返回行情 |

### 14.2 市场交易时段参考

| 市场 | 交易所 | 时区 | 常规交易时段（本地时间） | UTC 对应（冬季） |
|------|--------|------|----------------------|----------------|
| US | NYSE / NASDAQ | ET (UTC-5/UTC-4) | 09:30–16:00 | 14:30–21:00 |
| HK | HKEX | HKT (UTC+8) | 09:30–16:00 | 01:30–08:00 |

### 14.3 更新日志

| 版本 | 日期 | 变更摘要 |
|------|------|---------|
| v2.0 | 2026-03-14 | 与 PRD-03 v1.1 完全对齐：路径统一为 `/v1/`；价格字段改为 string；时间戳改为 ISO 8601；去除 code/message 包装；新增 `delayed`、`market_status`、cursor 分页；自选股路径移至 `/v1/watchlist`；补全 movers、financials 接口；删除价格提醒接口（移交通知服务） |
| v1.2.0 | 2026-03-09 | 新增盘口深度 REST API；WebSocket 深度行情及逐笔成交订阅 |
| v1.1.0 | 2026-03-07 | 新增 WebSocket 实时推送；Kafka 消费；心跳保活 |
| v1.0.0 | 2026-03-07 | 初始版本，9 个 REST 接口 |
