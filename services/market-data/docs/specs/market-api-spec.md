# 行情模块 API 规范

> 为 APP 端提供行情数据接口
> 版本：v1.0
> 日期：2026-03-07

---

## 1. 概述

### 1.1 功能范围

行情模块为移动端 APP 提供以下数据：

- **实时行情**：股票实时报价、涨跌幅、成交量
- **股票列表**：自选股、美股、港股、热门股票
- **股票详情**：基本面数据、K线数据、新闻、财报
- **搜索功能**：股票代码/名称搜索
- **价格提醒**：价格到达提醒设置

### 1.2 数据更新方式

- **HTTP REST API**：初始数据加载、历史数据查询
- **WebSocket**：实时行情推送（自选股）

---

## 2. REST API 接口

### 2.1 获取股票列表

**接口**: `GET /api/v1/market/stocks`

**描述**: 获取股票列表（支持分类筛选）

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | 否 | 分类：`watchlist`(自选)、`us`(美股)、`hk`(港股)、`hot`(热门)，默认 `watchlist` |
| page | int | 否 | 页码，默认 1 |
| pageSize | int | 否 | 每页数量，默认 20，最大 100 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "total": 6,
    "page": 1,
    "pageSize": 20,
    "stocks": [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "nameCN": "苹果",
        "market": "US",
        "price": 175.23,
        "change": 2.34,
        "changePercent": 1.35,
        "marketCap": "2.8T",
        "pe": 28.5,
        "volume": "45.2M",
        "timestamp": 1709798400000
      },
      {
        "symbol": "TSLA",
        "name": "Tesla Inc.",
        "nameCN": "特斯拉",
        "market": "US",
        "price": 245.67,
        "change": -3.21,
        "changePercent": -1.29,
        "marketCap": "780B",
        "pe": 65.3,
        "volume": "52.1M",
        "timestamp": 1709798400000
      }
    ]
  }
}
```

---

### 2.2 获取股票详情

**接口**: `GET /api/v1/market/stocks/{symbol}`

**描述**: 获取单个股票的详细信息

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| symbol | string | 是 | 股票代码，如 `AAPL` |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "nameCN": "苹果",
    "market": "US",
    "price": 175.23,
    "change": 2.34,
    "changePercent": 1.35,
    "open": 173.50,
    "high": 176.00,
    "low": 172.80,
    "volume": "45.2M",
    "marketCap": "2.8T",
    "pe": 28.5,
    "pb": 42.3,
    "dividendYield": 0.52,
    "week52High": 199.62,
    "week52Low": 164.08,
    "avgVolume": "48.5M",
    "timestamp": 1709798400000
  }
}
```

---

### 2.3 获取 K 线数据

**接口**: `GET /api/v1/market/kline/{symbol}`

**描述**: 获取股票 K 线数据

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| symbol | string | 是 | 股票代码 |

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| interval | string | 是 | 时间间隔：`1m`(分时)、`1d`(日K)、`1w`(周K)、`1M`(月K) |
| startTime | long | 否 | 开始时间戳（毫秒），默认最近 100 条 |
| endTime | long | 否 | 结束时间戳（毫秒），默认当前时间 |
| limit | int | 否 | 返回数量，默认 100，最大 500 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "symbol": "AAPL",
    "interval": "1d",
    "klines": [
      {
        "timestamp": 1709712000000,
        "open": 173.50,
        "high": 176.00,
        "low": 172.80,
        "close": 175.23,
        "volume": 45200000
      },
      {
        "timestamp": 1709625600000,
        "open": 172.00,
        "high": 174.50,
        "low": 171.20,
        "close": 173.50,
        "volume": 42100000
      }
    ]
  }
}
```

---

### 2.4 搜索股票

**接口**: `GET /api/v1/market/search`

**描述**: 搜索股票（支持代码、名称、拼音）

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| keyword | string | 是 | 搜索关键词 |
| limit | int | 否 | 返回数量，默认 10，最大 50 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "keyword": "AAPL",
    "results": [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "nameCN": "苹果",
        "market": "US",
        "price": 175.23,
        "change": 2.34,
        "changePercent": 1.35
      }
    ]
  }
}
```

---

### 2.5 获取热门搜索

**接口**: `GET /api/v1/market/hot-searches`

**描述**: 获取热门搜索股票列表

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 返回数量，默认 10，最大 20 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "hotSearches": [
      {
        "rank": 1,
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "nameCN": "苹果",
        "price": 175.23,
        "changePercent": 1.35
      },
      {
        "rank": 2,
        "symbol": "NVDA",
        "name": "NVIDIA",
        "nameCN": "英伟达",
        "price": 823.45,
        "changePercent": 1.56
      }
    ]
  }
}
```

---

### 2.6 获取股票新闻

**接口**: `GET /api/v1/market/news/{symbol}`

**描述**: 获取股票相关新闻

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| symbol | string | 是 | 股票代码 |

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| page | int | 否 | 页码，默认 1 |
| pageSize | int | 否 | 每页数量，默认 10，最大 50 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "total": 25,
    "page": 1,
    "pageSize": 10,
    "news": [
      {
        "id": "news_001",
        "title": "苹果发布新款 iPhone 16",
        "summary": "苹果公司今日发布新款 iPhone 16...",
        "source": "路透社",
        "publishTime": 1709798400000,
        "url": "https://example.com/news/001"
      },
      {
        "id": "news_002",
        "title": "Q1 财报超预期，营收增长 12%",
        "summary": "苹果公司 Q1 财报显示...",
        "source": "彭博社",
        "publishTime": 1709712000000,
        "url": "https://example.com/news/002"
      }
    ]
  }
}
```

---

### 2.7 获取财报数据

**接口**: `GET /api/v1/market/financials/{symbol}`

**描述**: 获取股票财报数据

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| symbol | string | 是 | 股票代码 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "symbol": "AAPL",
    "nextEarningsDate": "2026-04-28",
    "nextEarningsQuarter": "Q2 2026",
    "latestFinancials": {
      "quarter": "Q1 2026",
      "reportDate": "2026-01-28",
      "revenue": "119.6B",
      "netIncome": "33.9B",
      "eps": 2.18,
      "revenueGrowth": 12.5,
      "netIncomeGrowth": 15.3
    }
  }
}
```

---

### 2.8 获取盘口深度数据

**接口**: `GET /api/v1/market/depth/{symbol}`

**描述**: 获取股票的盘口深度数据（买卖挂单）

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| symbol | string | 是 | 股票代码，如 `AAPL` |

**请求参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| levels | int | 否 | 档位数，默认 5，最大 20 |

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "symbol": "AAPL",
    "market": "US",
    "bids": [
      { "price": "175.20", "volume": 1200, "orderCount": 8 },
      { "price": "175.18", "volume": 800, "orderCount": 5 },
      { "price": "175.15", "volume": 2500, "orderCount": 12 },
      { "price": "175.12", "volume": 600, "orderCount": 3 },
      { "price": "175.10", "volume": 1500, "orderCount": 7 }
    ],
    "asks": [
      { "price": "175.25", "volume": 900, "orderCount": 6 },
      { "price": "175.28", "volume": 1100, "orderCount": 4 },
      { "price": "175.30", "volume": 3000, "orderCount": 15 },
      { "price": "175.35", "volume": 700, "orderCount": 2 },
      { "price": "175.40", "volume": 2000, "orderCount": 9 }
    ],
    "timestamp": 1709798400000
  }
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| price | string | 价格（使用字符串避免精度丢失） |
| volume | long | 该价位挂单总量 |
| orderCount | int | 该价位挂单笔数 |
| bids | array | 买盘，按价格从高到低排列 |
| asks | array | 卖盘，按价格从低到高排列 |

---

### 2.9 管理自选股

#### 2.9.1 添加自选股

**接口**: `POST /api/v1/market/watchlist`

**描述**: 添加股票到自选列表

**请求体**:

```json
{
  "symbol": "AAPL"
}
```

**响应示例**:

```json
{
  "code": 0,
  "message": "添加成功",
  "data": {
    "symbol": "AAPL",
    "addedAt": 1709798400000
  }
}
```

#### 2.9.2 删除自选股

**接口**: `DELETE /api/v1/market/watchlist/{symbol}`

**描述**: 从自选列表删除股票

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| symbol | string | 是 | 股票代码 |

**响应示例**:

```json
{
  "code": 0,
  "message": "删除成功"
}
```

---

### 2.10 价格提醒

#### 2.10.1 创建价格提醒

**接口**: `POST /api/v1/market/alerts`

**描述**: 创建价格提醒

**请求体**:

```json
{
  "symbol": "AAPL",
  "type": "price",
  "condition": ">=",
  "targetPrice": 180.00,
  "enabled": true
}
```

**响应示例**:

```json
{
  "code": 0,
  "message": "创建成功",
  "data": {
    "alertId": "alert_001",
    "symbol": "AAPL",
    "type": "price",
    "condition": ">=",
    "targetPrice": 180.00,
    "enabled": true,
    "createdAt": 1709798400000
  }
}
```

#### 2.10.2 获取价格提醒列表

**接口**: `GET /api/v1/market/alerts`

**描述**: 获取用户的价格提醒列表

**响应示例**:

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "alerts": [
      {
        "alertId": "alert_001",
        "symbol": "AAPL",
        "type": "price",
        "condition": ">=",
        "targetPrice": 180.00,
        "currentPrice": 175.23,
        "enabled": true,
        "createdAt": 1709798400000
      }
    ]
  }
}
```

#### 2.10.3 删除价格提醒

**接口**: `DELETE /api/v1/market/alerts/{alertId}`

**描述**: 删除价格提醒

**路径参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| alertId | string | 是 | 提醒 ID |

**响应示例**:

```json
{
  "code": 0,
  "message": "删除成功"
}
```

---

## 3. WebSocket 实时推送

### 3.1 连接地址

```
wss://api.example.com/ws/market
```

### 3.2 认证

连接时需要在 URL 参数中传递 token：

```
wss://api.example.com/ws/market?token=<access_token>
```

### 3.3 订阅行情

**订阅消息**:

```json
{
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA", "MSFT"]
}
```

**推送消息**:

```json
{
  "type": "quote",
  "data": {
    "symbol": "AAPL",
    "price": 175.25,
    "change": 2.36,
    "changePercent": 1.36,
    "volume": "45.3M",
    "timestamp": 1709798401000
  }
}
```

### 3.4 取消订阅

**取消订阅消息**:

```json
{
  "action": "unsubscribe",
  "symbols": ["AAPL"]
}
```

### 3.5 深度行情订阅 *(2026-03-09 新增)*

**订阅深度行情**:

```json
{
  "action": "subscribe_depth",
  "symbol": "AAPL"
}
```

**深度行情推送**:

```json
{
  "action": "depth",
  "data": {
    "symbol": "AAPL",
    "bids": [
      { "price": "175.20", "volume": 1200, "orderCount": 8 },
      { "price": "175.18", "volume": 800, "orderCount": 5 }
    ],
    "asks": [
      { "price": "175.25", "volume": 900, "orderCount": 6 },
      { "price": "175.28", "volume": 1100, "orderCount": 4 }
    ],
    "timestamp": 1709798401000
  }
}
```

**取消订阅深度**:

```json
{
  "action": "unsubscribe_depth",
  "symbol": "AAPL"
}
```

### 3.6 逐笔成交推送 *(2026-03-09 新增)*

**成交记录推送**:

```json
{
  "action": "trade",
  "data": {
    "symbol": "AAPL",
    "price": "175.23",
    "volume": 100,
    "timestamp": 1709798401000,
    "tradeId": "T001",
    "side": "BUY"
  }
}
```

### 3.7 心跳

客户端每 30 秒发送一次 ping：

```json
{
  "action": "ping"
}
```

服务端响应 pong：

```json
{
  "action": "pong",
  "timestamp": 1709798400000
}
```

---

## 4. 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 1001 | 参数错误 |
| 1002 | 股票代码不存在 |
| 1003 | 数据源异常 |
| 2001 | 未登录 |
| 2002 | Token 过期 |
| 2003 | 无权限 |
| 5000 | 服务器内部错误 |

**错误响应示例**:

```json
{
  "code": 1002,
  "message": "股票代码不存在",
  "data": null
}
```

---

## 5. 数据源

### 5.1 实时行情数据源

- **美股**: IEX Cloud / Polygon.io / Alpha Vantage
- **港股**: 富途 OpenAPI / 老虎 OpenAPI

### 5.2 基本面数据源

- **财报数据**: Financial Modeling Prep / Alpha Vantage
- **新闻数据**: NewsAPI / Benzinga

### 5.3 数据更新频率

- **实时行情**: WebSocket 推送（延迟 < 100ms）
- **K 线数据**: 每分钟更新（分时图）、每日更新（日K/周K/月K）
- **基本面数据**: 每日更新
- **新闻数据**: 每 5 分钟更新

---

## 6. 性能要求

| 指标 | 要求 |
|------|------|
| API 响应时间 | P95 < 200ms |
| WebSocket 延迟 | < 100ms |
| 并发连接数 | > 10,000 |
| QPS | > 5,000 |

---

## 7. 安全要求

1. **认证**: 所有接口需要 JWT Token 认证
2. **限流**:
   - REST API: 100 req/min/user
   - WebSocket: 最多订阅 50 个股票
3. **数据加密**: HTTPS/WSS 传输
4. **防重放**: WebSocket 消息带时间戳，5 秒内有效

---

## 8. 开发优先级

### P0（MVP 必须）

- ✅ 获取股票列表
- ✅ 获取股票详情
- ✅ 获取 K 线数据
- ✅ 获取盘口深度数据
- ✅ 搜索股票
- ✅ 管理自选股
- ✅ WebSocket 实时推送（报价 + 深度 + 成交）

### P1（后续迭代）

- 获取热门搜索
- 获取股票新闻
- 获取财报数据
- 价格提醒

---

## 9. 测试数据

开发阶段提供 Mock 数据：

- **股票列表**: 6 只美股（AAPL, TSLA, MSFT, GOOGL, AMZN, NVDA）
- **K 线数据**: 最近 100 天日K数据
- **实时推送**: 每秒随机波动 ±0.5%

---

## 附录：数据字段说明

### 股票基本信息

| 字段 | 类型 | 说明 |
|------|------|------|
| symbol | string | 股票代码 |
| name | string | 公司名称（英文） |
| nameCN | string | 公司名称（中文） |
| market | string | 市场：US/HK |
| price | float | 当前价格 |
| change | float | 涨跌额 |
| changePercent | float | 涨跌幅（%） |
| marketCap | string | 市值（格式化） |
| pe | float | 市盈率 |
| pb | float | 市净率 |
| volume | string | 成交量（格式化） |
| timestamp | long | 数据时间戳（毫秒） |

---

**文档版本**: v1.0
**创建日期**: 2026-03-07
**维护人**: Backend Team

---

## 3. WebSocket 实时推送

### 3.1 连接地址

**WebSocket URL**: `ws://localhost:8080/api/v1/market/realtime`

**协议**: WebSocket

### 3.2 连接流程

1. 客户端发起 WebSocket 连接
2. 服务器返回欢迎消息
3. 客户端订阅股票代码
4. 服务器推送实时行情数据
5. 客户端可随时订阅/取消订阅

### 3.3 消息格式

#### 3.3.1 客户端 → 服务器

**订阅股票**:
```json
{
  "type": "subscribe",
  "symbols": ["AAPL", "TSLA", "MSFT"]
}
```

**取消订阅**:
```json
{
  "type": "unsubscribe",
  "symbols": ["AAPL"]
}
```

**心跳检测**:
```json
{
  "type": "ping"
}
```

#### 3.3.2 服务器 → 客户端

**欢迎消息**:
```json
{
  "type": "welcome",
  "data": {
    "message": "Connected to Market Service WebSocket",
    "clientId": "uuid-string"
  },
  "time": 1709798400000
}
```

**订阅确认**:
```json
{
  "type": "ack",
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA"],
  "time": 1709798400000
}
```

**实时行情推送**:
```json
{
  "type": "quote",
  "symbol": "AAPL",
  "data": {
    "symbol": "AAPL",
    "price": 175.23,
    "change": 2.34,
    "changePercent": 1.35,
    "volume": 45200000,
    "timestamp": 1709798400000
  },
  "time": 1709798400000
}
```

**心跳响应**:
```json
{
  "type": "pong",
  "time": 1709798400000
}
```

### 3.4 连接示例

#### JavaScript 示例

```javascript
// 创建 WebSocket 连接
const ws = new WebSocket('ws://localhost:8080/api/v1/market/realtime');

// 连接成功
ws.onopen = function() {
  console.log('WebSocket 连接成功');
  
  // 订阅股票
  ws.send(JSON.stringify({
    type: 'subscribe',
    symbols: ['AAPL', 'TSLA']
  }));
};

// 接收消息
ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  
  switch(data.type) {
    case 'welcome':
      console.log('欢迎消息:', data);
      break;
    case 'ack':
      console.log('订阅确认:', data);
      break;
    case 'quote':
      console.log('实时行情:', data);
      // 更新 UI
      updateQuote(data.symbol, data.data);
      break;
    case 'pong':
      console.log('心跳响应');
      break;
  }
};

// 连接关闭
ws.onclose = function() {
  console.log('WebSocket 连接关闭');
};

// 连接错误
ws.onerror = function(error) {
  console.error('WebSocket 错误:', error);
};

// 取消订阅
function unsubscribe(symbols) {
  ws.send(JSON.stringify({
    type: 'unsubscribe',
    symbols: symbols
  }));
}

// 发送心跳
function sendHeartbeat() {
  ws.send(JSON.stringify({
    type: 'ping'
  }));
}

// 定时发送心跳（每 30 秒）
setInterval(sendHeartbeat, 30000);
```

#### Python 示例

```python
import websocket
import json
import time

def on_message(ws, message):
    data = json.loads(message)
    print(f"收到消息: {data['type']}")
    
    if data['type'] == 'quote':
        print(f"实时行情: {data['symbol']} - ${data['data']['price']}")

def on_open(ws):
    print("WebSocket 连接成功")
    
    # 订阅股票
    ws.send(json.dumps({
        'type': 'subscribe',
        'symbols': ['AAPL', 'TSLA']
    }))

def on_close(ws, close_status_code, close_msg):
    print("WebSocket 连接关闭")

def on_error(ws, error):
    print(f"WebSocket 错误: {error}")

# 创建 WebSocket 连接
ws = websocket.WebSocketApp(
    "ws://localhost:8080/api/v1/market/realtime",
    on_open=on_open,
    on_message=on_message,
    on_error=on_error,
    on_close=on_close
)

# 运行
ws.run_forever()
```

### 3.5 注意事项

1. **心跳机制**: 服务器每 30 秒发送一次 Ping，客户端需响应 Pong
2. **自动重连**: 连接断开后，客户端应实现自动重连机制
3. **订阅限制**: 建议单个连接订阅不超过 50 只股票
4. **消息频率**: 实时行情推送频率取决于数据源更新频率
5. **连接超时**: 60 秒无活动将自动断开连接

### 3.6 错误处理

**连接失败**:
- 检查服务器是否启动
- 检查 WebSocket URL 是否正确
- 检查网络连接

**消息发送失败**:
- 检查消息格式是否正确
- 检查连接是否正常

**频繁断开**:
- 实现心跳机制
- 检查网络稳定性
- 实现自动重连

---

## 4. 数据源说明

### 4.1 Polygon.io

**实时性**: 毫秒级延迟

**覆盖范围**:
- 美股（NYSE, NASDAQ）
- 期权
- 外汇
- 加密货币

**API 限制**:
- Free: 5 requests/min
- Starter ($29/mo): 100 requests/min
- Developer ($99/mo): 1000 requests/min

**WebSocket**: 支持实时行情推送

### 4.2 数据更新频率

| 数据类型 | 更新频率 | 说明 |
|---------|---------|------|
| 实时行情 | 实时 | WebSocket 推送 |
| K线数据 | 1分钟 | 定时同步 |
| 股票信息 | 1小时 | 定时同步 |
| 新闻数据 | 5分钟 | 定时同步 |
| 财报数据 | 1天 | 定时同步 |

---

## 5. 测试工具

### 5.1 WebSocket 测试客户端

**路径**: `/test/websocket-client.html`

**功能**:
- WebSocket 连接测试
- 订阅/取消订阅股票
- 实时查看推送消息
- 心跳测试

**使用方法**:
```bash
# 在浏览器中打开
open test/websocket-client.html
```

### 5.2 Postman 测试

**导入 API 集合**:
1. 打开 Postman
2. 导入 `/docs/api/market-api-postman.json`
3. 设置环境变量 `base_url = http://localhost:8080`
4. 运行测试

---

## 6. 常见问题

### 6.1 REST API

**Q: 如何处理分页？**
A: 使用 `page` 和 `pageSize` 参数，响应中包含 `total` 总数

**Q: 如何处理错误？**
A: 所有错误返回统一格式：`{"code": 错误码, "message": "错误信息"}`

**Q: 是否需要认证？**
A: 当前版本暂未实现认证，后续版本将添加 JWT Token 认证

### 6.2 WebSocket

**Q: 如何保持连接？**
A: 实现心跳机制，每 30 秒发送一次 ping

**Q: 连接断开怎么办？**
A: 实现自动重连机制，建议使用指数退避策略

**Q: 可以订阅多少只股票？**
A: 建议单个连接订阅不超过 50 只股票

**Q: 如何测试 WebSocket？**
A: 使用提供的测试客户端 `/test/websocket-client.html`

---

## 7. 更新日志

### v1.2.0 (2026-03-09)

**新增**:
- ✅ 盘口深度 REST API (`GET /api/v1/market/depth/{symbol}`)
- ✅ WebSocket 深度行情订阅 (`subscribe_depth` / `unsubscribe_depth` / `depth`)
- ✅ WebSocket 逐笔成交推送 (`trade`)
- ✅ QuoteData 扩展字段（bidPrice, askPrice, open, high, low, prevClose, turnover, status, session）

### v1.1.0 (2026-03-07)

**新增**:
- ✅ WebSocket 实时行情推送
- ✅ Kafka 消息消费
- ✅ 心跳保活机制
- ✅ WebSocket 测试客户端

**优化**:
- 改进连接管理
- 优化消息推送性能

### v1.0.0 (2026-03-07)

**初始版本**:
- ✅ 9 个 REST API 接口
- ✅ 7 张数据库表
- ✅ Redis 缓存策略
- ✅ Polygon.io 数据源集成

---

**文档版本**: v1.2.0
**最后更新**: 2026-03-09
