# 行情系统技术架构设计

> 美港股券商交易 APP — Market Data System Architecture

## 1. 系统概述

行情系统是券商交易平台的核心基础设施，负责从交易所/数据供应商实时获取市场数据，经过标准化处理后分发给交易系统和客户端。系统需要同时支持美股（NYSE/NASDAQ）和港股（HKEX）两个市场。

### 1.1 核心指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 端到端延迟 | < 50ms (p99) | 数据源 → 客户端 |
| 内部处理延迟 | < 5ms (p99) | Feed Handler → WebSocket 推送 |
| 并发连接数 | 100,000+ | WebSocket 长连接 |
| 行情吞吐量 | 500,000 msg/s | 峰值消息处理能力 |
| 可用性 | 99.99% | 盘中时段 |
| 数据准确率 | 100% | 与交易所数据一致 |

### 1.2 支持的数据类型

| 数据类型 | 描述 | 更新频率 |
|----------|------|----------|
| Level 1 (快照) | 最新价、买一/卖一、涨跌幅 | 实时推送 |
| Level 2 (深度) | 5/10/20 档买卖盘口 | 实时推送 |
| 逐笔成交 | 每笔交易明细 (Time & Sales) | 实时推送 |
| K线 (OHLCV) | 1m/5m/15m/30m/1h/1d/1w/1M | 实时聚合 + 历史查询 |
| 盘前盘后 | Pre-market / After-hours | 实时推送 (美股) |
| 指数行情 | 大盘指数、行业指数 | 实时推送 |
| 期权链 | 期权报价、希腊字母 | 实时推送 |

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Market Data System                               │
│                                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │ Data Sources  │    │ Feed Handler │    │   Processing Engine      │  │
│  │              │    │    Layer      │    │                          │  │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ ┌──────────────────────┐│  │
│  │ │ Polygon  │─┼───▶│ │US Feed   │─┼───▶│ │  Normalizer          ││  │
│  │ │ (US Stk) │ │    │ │Handler   │ │    │ │  (统一数据格式)       ││  │
│  │ └──────────┘ │    │ └──────────┘ │    │ └──────────┬───────────┘│  │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │            │            │  │
│  │ │ HKEX OMD │─┼───▶│ │HK Feed   │─┼───▶│ ┌──────────▼───────────┐│  │
│  │ │ (HK Stk) │ │    │ │Handler   │ │    │ │  Aggregator          ││  │
│  │ └──────────┘ │    │ └──────────┘ │    │ │  (K线聚合/指标计算)   ││  │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ └──────────┬───────────┘│  │
│  │ │ IEX/OPRA │─┼───▶│ │Options   │─┼───▶│            │            │  │
│  │ │ (Options)│ │    │ │Handler   │ │    │ ┌──────────▼───────────┐│  │
│  │ └──────────┘ │    │ └──────────┘ │    │ │  Validator           ││  │
│  │ ┌──────────┐ │    │ ┌──────────┐ │    │ │  (数据校验/异常检测) ││  │
│  │ │ Backup   │─┼───▶│ │Backup    │─┼───▶│ └──────────┬───────────┘│  │
│  │ │ Sources  │ │    │ │Handler   │ │    │            │            │  │
│  │ └──────────┘ │    │ └──────────┘ │    └────────────┼────────────┘  │
│  └──────────────┘    └──────────────┘                │                │
│                                                      │                │
│                           ┌──────────────────────────┤                │
│                           │                          │                │
│                           ▼                          ▼                │
│                    ┌──────────────┐         ┌──────────────┐          │
│                    │  Cache Layer │         │  Storage     │          │
│                    │              │         │  Layer       │          │
│                    │ ┌──────────┐ │         │ ┌──────────┐ │          │
│                    │ │ Redis    │ │         │ │TimescaleDB│ │          │
│                    │ │ Cluster  │ │         │ │(历史行情) │ │          │
│                    │ │(实时快照)│ │         │ └──────────┘ │          │
│                    │ └──────────┘ │         │ ┌──────────┐ │          │
│                    │ ┌──────────┐ │         │ │ClickHouse│ │          │
│                    │ │ Local    │ │         │ │(分析查询) │ │          │
│                    │ │ Memory   │ │         │ └──────────┘ │          │
│                    │ │ Cache    │ │         └──────────────┘          │
│                    │ └──────────┘ │                                   │
│                    └──────┬───────┘                                   │
│                           │                                          │
│                           ▼                                          │
│                    ┌──────────────────────────────────────────┐       │
│                    │         Distribution Layer               │       │
│                    │                                          │       │
│                    │ ┌────────────┐  ┌─────────────────────┐ │       │
│                    │ │  Kafka     │  │  WebSocket Gateway  │ │       │
│                    │ │  Cluster   │  │  (客户端推送)        │ │       │
│                    │ │  (内部分发) │  │                     │ │       │
│                    │ └────────────┘  └─────────────────────┘ │       │
│                    │ ┌────────────┐  ┌─────────────────────┐ │       │
│                    │ │  gRPC      │  │  REST API           │ │       │
│                    │ │  (内部服务) │  │  (历史行情查询)      │ │       │
│                    │ └────────────┘  └─────────────────────┘ │       │
│                    └──────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────┘

               ┌─────────────────────────────────────────┐
               │            Clients                       │
               │                                         │
               │  ┌─────────┐ ┌─────────┐ ┌──────────┐  │
               │  │ iOS App │ │Android  │ │ Admin    │  │
               │  │         │ │ App     │ │ Panel    │  │
               │  └─────────┘ └─────────┘ └──────────┘  │
               │  ┌─────────┐ ┌─────────────────────┐   │
               │  │Trading  │ │ Risk Management     │   │
               │  │ Engine  │ │ System              │   │
               │  └─────────┘ └─────────────────────┘   │
               └─────────────────────────────────────────┘
```

---

## 3. 分层详细设计

### 3.1 数据源接入层 (Data Source Layer)

#### 美股数据源

| 数据源 | 用途 | 协议 | 数据级别 | 延迟 |
|--------|------|------|----------|------|
| **Polygon.io** | 主数据源 — 实时行情 | WebSocket | L1/L2/Trades | ~10ms |
| **IEX Cloud** | 备用数据源 | WebSocket/REST | L1/Trades | ~50ms |
| **Alpaca** | 备用/开发环境 | WebSocket | L1/L2 | ~30ms |
| **OPRA** | 期权行情 | Binary/UDP | Full Options Chain | ~5ms |

#### 港股数据源

| 数据源 | 用途 | 协议 | 数据级别 | 延迟 |
|--------|------|------|----------|------|
| **HKEX OMD-C** | 主数据源 — 证券行情 | Binary/TCP (OMD Protocol) | L1/L2/Trades | ~1ms |
| **HKEX OMD-D** | 衍生品行情 | Binary/TCP | Derivatives | ~1ms |
| **AAStocks** | 备用/补充数据 | REST/WebSocket | L1 | ~100ms |

#### 数据源选择策略

```go
// 数据源优先级与容灾策略
type FeedPriority struct {
    Market    string // "US" / "HK"
    Primary   DataSource
    Secondary DataSource
    Fallback  DataSource
}

var feedConfig = []FeedPriority{
    {
        Market:    "US",
        Primary:   Polygon,    // 主数据源
        Secondary: IEXCloud,   // 自动切换
        Fallback:  Alpaca,     // 最后兜底
    },
    {
        Market:    "HK",
        Primary:   HKEX_OMD,   // 直连交易所
        Secondary: AAStocks,   // 备用
    },
}
```

### 3.2 Feed Handler 层

每个数据源对应一个独立的 Feed Handler 进程，负责：

1. **连接管理**：建立/维护与数据源的连接，处理断线重连
2. **协议解析**：将供应商私有协议解析为原始行情消息
3. **序列号校验**：检测消息丢失，触发快照恢复
4. **心跳监控**：检测数据源活性，触发故障切换

```go
// Feed Handler 核心接口
type FeedHandler interface {
    // 连接数据源
    Connect(ctx context.Context) error
    // 订阅标的
    Subscribe(symbols []string, dataTypes []DataType) error
    // 取消订阅
    Unsubscribe(symbols []string) error
    // 读取消息流
    Messages() <-chan RawMessage
    // 健康检查
    Health() HealthStatus
    // 关闭连接
    Close() error
}

// 原始消息（未标准化）
type RawMessage struct {
    Source     string    // 数据源标识
    Market    string    // US / HK
    Symbol    string    // 标的代码
    Type      DataType  // Quote / Trade / Depth / Kline
    Sequence  uint64    // 序列号
    Timestamp time.Time // 数据源时间戳
    Payload   []byte    // 原始数据
}
```

#### Feed Handler 进程模型

```
┌───────────────────────────────────────────────────┐
│                Feed Handler Process                │
│                                                   │
│  ┌──────────┐    ┌───────────┐    ┌────────────┐ │
│  │ Connector │───▶│  Decoder  │───▶│  Sequencer │ │
│  │ (TCP/WS)  │    │ (Protocol │    │  (Gap Det- │ │
│  │           │    │  Parser)  │    │   ection)  │ │
│  └──────────┘    └───────────┘    └─────┬──────┘ │
│       ▲                                  │        │
│       │ Reconnect                        ▼        │
│  ┌──────────┐                    ┌────────────┐   │
│  │ Watchdog  │                   │  Output    │   │
│  │ (Health   │                   │  Channel   │──▶ To Processing Engine
│  │  Monitor) │                   │  (Ring Buf)│   │
│  └──────────┘                    └────────────┘   │
└───────────────────────────────────────────────────┘
```

### 3.3 处理引擎层 (Processing Engine)

#### 3.3.1 Normalizer — 数据标准化

将不同数据源的私有格式统一为内部标准格式：

```protobuf
// api/grpc/market_data.proto

syntax = "proto3";
package marketdata;

// 统一行情快照
message Quote {
  string symbol = 1;           // 标的代码 (e.g., "AAPL", "0700.HK")
  string market = 2;           // 市场 ("US", "HK")
  string currency = 3;         // 币种 ("USD", "HKD")

  // 最新成交
  string last_price = 4;       // 最新价 (string 避免精度丢失)
  int64  last_volume = 5;      // 最新成交量
  int64  timestamp = 6;        // 数据时间戳 (Unix nanos)

  // 买卖盘 (Level 1)
  string bid_price = 7;        // 买一价
  int64  bid_size = 8;         // 买一量
  string ask_price = 9;        // 卖一价
  int64  ask_size = 10;        // 卖一量

  // 日内统计
  string open = 11;            // 开盘价
  string high = 12;            // 最高价
  string low = 13;             // 最低价
  string prev_close = 14;      // 昨收价
  int64  volume = 15;          // 成交量
  string turnover = 16;        // 成交额

  // 涨跌
  string change = 17;          // 涨跌额
  string change_pct = 18;      // 涨跌幅 (百分比)

  // 交易状态
  TradingStatus status = 19;   // 交易状态
  MarketSession session = 20;  // 交易时段
}

// 深度行情 (Level 2)
message Depth {
  string symbol = 1;
  string market = 2;
  int64  timestamp = 3;
  repeated PriceLevel bids = 4;  // 买盘 (价格降序)
  repeated PriceLevel asks = 5;  // 卖盘 (价格升序)
}

message PriceLevel {
  string price = 1;
  int64  volume = 2;
  int32  order_count = 3;       // 该价位订单数
}

// 逐笔成交
message Trade {
  string symbol = 1;
  string market = 2;
  string price = 3;
  int64  volume = 4;
  int64  timestamp = 5;
  string trade_id = 6;
  TradeSide side = 7;           // BUY / SELL / UNKNOWN
  repeated TradeCondition conditions = 8;
}

// K线
message Kline {
  string symbol = 1;
  string market = 2;
  string open = 3;
  string high = 4;
  string low = 5;
  string close = 6;
  int64  volume = 7;
  string turnover = 8;
  int64  timestamp = 9;         // K线起始时间
  KlineInterval interval = 10;  // 1m, 5m, 15m, 30m, 1h, 1d, 1w, 1M
}

enum TradingStatus {
  TRADING_STATUS_UNKNOWN = 0;
  PRE_MARKET = 1;
  TRADING = 2;
  LUNCH_BREAK = 3;              // 港股午休
  POST_MARKET = 4;
  CLOSED = 5;
  HALTED = 6;
  SUSPENDED = 7;
}

enum MarketSession {
  SESSION_UNKNOWN = 0;
  REGULAR = 1;
  PRE = 2;
  POST = 3;
  EXTENDED = 4;
}

enum TradeSide {
  SIDE_UNKNOWN = 0;
  BUY = 1;
  SELL = 2;
}

enum KlineInterval {
  INTERVAL_UNKNOWN = 0;
  MIN_1 = 1;
  MIN_5 = 2;
  MIN_15 = 3;
  MIN_30 = 4;
  HOUR_1 = 5;
  DAY_1 = 6;
  WEEK_1 = 7;
  MONTH_1 = 8;
}

enum TradeCondition {
  CONDITION_UNKNOWN = 0;
  REGULAR_SALE = 1;
  ODD_LOT = 2;
  CROSS_TRADE = 3;
  DARK_POOL = 4;
}
```

#### 3.3.2 Aggregator — K线聚合引擎

实时将逐笔成交聚合为多周期 K 线：

```go
// K线聚合器
type KlineAggregator struct {
    mu       sync.RWMutex
    klines   map[string]map[KlineInterval]*KlineBuilder  // symbol -> interval -> builder
    timers   map[KlineInterval]*time.Ticker               // 每个周期的定时器
    output   chan *Kline                                   // 输出通道
}

// K线构建器（单个标的单个周期）
type KlineBuilder struct {
    Symbol    string
    Interval  KlineInterval
    Open      decimal.Decimal
    High      decimal.Decimal
    Low       decimal.Decimal
    Close     decimal.Decimal
    Volume    int64
    Turnover  decimal.Decimal
    StartTime time.Time
    TradeCount int32
}

func (b *KlineBuilder) Update(trade *Trade) {
    price := decimal.RequireFromString(trade.Price)
    if b.TradeCount == 0 {
        b.Open = price
        b.High = price
        b.Low = price
    }
    if price.GreaterThan(b.High) {
        b.High = price
    }
    if price.LessThan(b.Low) {
        b.Low = price
    }
    b.Close = price
    b.Volume += trade.Volume
    b.Turnover = b.Turnover.Add(price.Mul(decimal.NewFromInt(trade.Volume)))
    b.TradeCount++
}
```

#### 3.3.3 Validator — 数据校验

```go
// 行情数据校验规则
type QuoteValidator struct {
    prevQuotes sync.Map  // symbol -> *Quote (上一次报价)
}

func (v *QuoteValidator) Validate(q *Quote) ValidationResult {
    var issues []ValidationIssue

    price := decimal.RequireFromString(q.LastPrice)

    // 1. 价格合理性检查
    if price.LessThanOrEqual(decimal.Zero) {
        issues = append(issues, ValidationIssue{
            Level:   Critical,
            Message: "price <= 0",
        })
    }

    // 2. 涨跌幅异常检测 (与上一笔比较)
    if prev, ok := v.prevQuotes.Load(q.Symbol); ok {
        prevPrice := decimal.RequireFromString(prev.(*Quote).LastPrice)
        changePct := price.Sub(prevPrice).Div(prevPrice).Abs()
        if changePct.GreaterThan(decimal.NewFromFloat(0.2)) { // >20% 波动
            issues = append(issues, ValidationIssue{
                Level:   Warning,
                Message: fmt.Sprintf("abnormal price change: %.2f%%", changePct.InexactFloat64()*100),
            })
        }
    }

    // 3. 时间戳合理性
    now := time.Now()
    dataTime := time.Unix(0, q.Timestamp)
    if now.Sub(dataTime) > 5*time.Minute {
        issues = append(issues, ValidationIssue{
            Level:   Warning,
            Message: "stale data: timestamp > 5 minutes old",
        })
    }

    // 4. 买卖价合理性 (bid <= last <= ask)
    bid := decimal.RequireFromString(q.BidPrice)
    ask := decimal.RequireFromString(q.AskPrice)
    if bid.GreaterThan(ask) {
        issues = append(issues, ValidationIssue{
            Level:   Critical,
            Message: "crossed market: bid > ask",
        })
    }

    v.prevQuotes.Store(q.Symbol, q)

    if len(issues) == 0 {
        return ValidationResult{Valid: true}
    }
    return ValidationResult{Valid: false, Issues: issues}
}
```

### 3.4 缓存层 (Cache Layer)

#### Redis 缓存设计

```
┌─────────────────────────────────────────────────────────┐
│                    Redis Cluster                         │
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Quote Cache (Hash)                                  ││
│  │ Key: quote:{market}:{symbol}                        ││
│  │ Fields: last_price, bid, ask, volume, change, ...   ││
│  │ TTL: None (overwritten on each update)              ││
│  │ Example: quote:US:AAPL → {last_price: "178.50"...} ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Depth Cache (Sorted Set)                            ││
│  │ Key: depth:{market}:{symbol}:{side}                 ││
│  │ Score: price, Member: volume|order_count             ││
│  │ Example: depth:US:AAPL:bid → [(178.49, "100|5")]   ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Kline Cache (Sorted Set)                            ││
│  │ Key: kline:{market}:{symbol}:{interval}             ││
│  │ Score: timestamp, Member: JSON(OHLCV)               ││
│  │ Max: 保留最近 500 根 K 线                             ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Market Status (String)                              ││
│  │ Key: market_status:{market}                         ││
│  │ Value: TRADING / PRE_MARKET / CLOSED / ...          ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Pub/Sub Channels                                    ││
│  │ Channel: md:{market}:{symbol}                       ││
│  │ Used for: Real-time quote push to WS gateway        ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

#### 本地内存缓存 (Hot Path)

```go
// 进程内缓存，用于最热路径（如交易引擎的价格查询）
type LocalQuoteCache struct {
    quotes sync.Map  // symbol -> *Quote (lock-free read)
    stats  atomic.Int64
}

func (c *LocalQuoteCache) Get(symbol string) (*Quote, bool) {
    c.stats.Add(1)
    v, ok := c.quotes.Load(symbol)
    if !ok {
        return nil, false
    }
    return v.(*Quote), true
}

func (c *LocalQuoteCache) Update(q *Quote) {
    c.quotes.Store(q.Symbol, q)
}
```

### 3.5 分发层 (Distribution Layer)

#### 3.5.1 内部分发 — Kafka

```
Topic 设计:

market-data.quotes.us          # 美股 L1 行情
market-data.quotes.hk          # 港股 L1 行情
market-data.depth.us           # 美股深度行情
market-data.depth.hk           # 港股深度行情
market-data.trades.us          # 美股逐笔成交
market-data.trades.hk          # 港股逐笔成交
market-data.klines.{interval}  # K线 (按周期分 topic)

Partition 策略: 按 symbol hash 分区，保证同一标的的消息有序
Retention: 7 天 (用于回放和故障恢复)
Serialization: Protocol Buffers
```

#### 3.5.2 客户端分发 — WebSocket Gateway

```
┌─────────────────────────────────────────────────────────────┐
│                WebSocket Gateway Cluster                     │
│                                                             │
│  ┌───────────┐   ┌────────────────┐   ┌──────────────────┐ │
│  │  Load     │   │  WS Server     │   │  Subscription    │ │
│  │  Balancer │──▶│  (Go, epoll)   │──▶│  Manager         │ │
│  │  (Nginx)  │   │                │   │                  │ │
│  └───────────┘   └────────┬───────┘   └────────┬─────────┘ │
│                           │                     │           │
│                           ▼                     ▼           │
│                  ┌────────────────┐   ┌──────────────────┐  │
│                  │  Message       │   │  Client State    │  │
│                  │  Broadcaster   │   │  Store (Redis)   │  │
│                  │  (Fan-out)     │   │                  │  │
│                  └────────────────┘   └──────────────────┘  │
│                                                             │
│  Features:                                                  │
│  - 连接级别的订阅管理 (按 symbol + dataType)                 │
│  - 消息合并 (相同 symbol 的高频更新合并为一帧)                │
│  - 增量推送 (仅推送变化的字段, 减少带宽)                      │
│  - 背压控制 (慢消费者降级为低频推送)                          │
│  - 压缩 (permessage-deflate)                                │
│  - 断线重连 + 快照恢复                                       │
└─────────────────────────────────────────────────────────────┘
```

#### WebSocket 协议设计

```json
// === 客户端 → 服务端 ===

// 订阅
{
  "action": "subscribe",
  "req_id": "uuid-1234",
  "data": {
    "quotes": ["AAPL", "GOOGL", "0700.HK"],
    "depth": ["AAPL"],
    "trades": ["TSLA"],
    "klines": [{"symbol": "AAPL", "interval": "1m"}]
  }
}

// 取消订阅
{
  "action": "unsubscribe",
  "req_id": "uuid-1235",
  "data": {
    "quotes": ["GOOGL"]
  }
}

// === 服务端 → 客户端 ===

// 行情推送 (增量模式，仅推送变化字段)
{
  "type": "quote",
  "symbol": "AAPL",
  "data": {
    "last": "178.50",
    "bid": "178.49",
    "ask": "178.51",
    "vol": 52341200,
    "chg": "+1.25",
    "chg_pct": "+0.71%",
    "ts": 1709712000000
  }
}

// 深度行情推送
{
  "type": "depth",
  "symbol": "AAPL",
  "data": {
    "bids": [["178.49", 300, 5], ["178.48", 500, 8]],
    "asks": [["178.51", 200, 3], ["178.52", 400, 6]],
    "ts": 1709712000000
  }
}

// 逐笔成交推送
{
  "type": "trade",
  "symbol": "TSLA",
  "data": {
    "price": "195.20",
    "vol": 100,
    "side": "B",
    "ts": 1709712000050
  }
}

// 心跳
{
  "type": "ping",
  "ts": 1709712000000
}
```

### 3.6 存储层 (Storage Layer)

#### TimescaleDB — 历史 K 线 & 逐笔数据

```sql
-- 创建 TimescaleDB 扩展
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- K线表 (hypertable)
CREATE TABLE klines (
    time        TIMESTAMPTZ NOT NULL,
    symbol      TEXT        NOT NULL,
    market      TEXT        NOT NULL,  -- 'US' / 'HK'
    interval    TEXT        NOT NULL,  -- '1m', '5m', '1h', '1d', etc.
    open        NUMERIC(20, 8) NOT NULL,
    high        NUMERIC(20, 8) NOT NULL,
    low         NUMERIC(20, 8) NOT NULL,
    close       NUMERIC(20, 8) NOT NULL,
    volume      BIGINT      NOT NULL,
    turnover    NUMERIC(30, 8) NOT NULL DEFAULT 0,
    trade_count INT         NOT NULL DEFAULT 0
);

SELECT create_hypertable('klines', 'time');

-- 复合索引: symbol + interval + time
CREATE INDEX idx_klines_symbol_interval ON klines (symbol, interval, time DESC);

-- 逐笔成交表 (hypertable)
CREATE TABLE trades (
    time        TIMESTAMPTZ NOT NULL,
    symbol      TEXT        NOT NULL,
    market      TEXT        NOT NULL,
    price       NUMERIC(20, 8) NOT NULL,
    volume      BIGINT      NOT NULL,
    trade_id    TEXT,
    side        TEXT,  -- 'B' / 'S' / 'U'
    conditions  TEXT[] DEFAULT '{}'
);

SELECT create_hypertable('trades', 'time', chunk_time_interval => INTERVAL '1 day');

CREATE INDEX idx_trades_symbol ON trades (symbol, time DESC);

-- 连续聚合 (自动生成更大周期的 K 线)
CREATE MATERIALIZED VIEW klines_5m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS time,
    symbol,
    market,
    first(open, time) AS open,
    max(high) AS high,
    min(low) AS low,
    last(close, time) AS close,
    sum(volume) AS volume,
    sum(turnover) AS turnover
FROM klines
WHERE interval = '1m'
GROUP BY time_bucket('5 minutes', time), symbol, market;

-- 数据保留策略
SELECT add_retention_policy('trades', INTERVAL '90 days');     -- 逐笔保留90天
SELECT add_retention_policy('klines', INTERVAL '10 years');    -- K线保留10年

-- 压缩策略 (降低存储成本)
ALTER TABLE klines SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol, market, interval'
);
SELECT add_compression_policy('klines', INTERVAL '7 days');
```

#### REST API — 历史行情查询

```go
// 历史 K 线查询接口
// GET /api/v1/market-data/klines?symbol=AAPL&market=US&interval=1d&from=2024-01-01&to=2024-12-31

type KlineQueryRequest struct {
    Symbol   string        `query:"symbol" validate:"required"`
    Market   string        `query:"market" validate:"required,oneof=US HK"`
    Interval KlineInterval `query:"interval" validate:"required"`
    From     time.Time     `query:"from" validate:"required"`
    To       time.Time     `query:"to" validate:"required"`
    Limit    int           `query:"limit" validate:"max=1000"`
}

type KlineQueryResponse struct {
    Symbol string   `json:"symbol"`
    Market string   `json:"market"`
    Klines []*Kline `json:"klines"`
    HasMore bool    `json:"has_more"`
}
```

---

## 4. 关键设计决策

### 4.1 性能优化

| 优化手段 | 应用位置 | 说明 |
|----------|----------|------|
| **Ring Buffer** | Feed Handler 输出 | 无锁环形缓冲区，避免 GC 压力 |
| **sync.Map** | LocalQuoteCache | 读多写少场景的无锁并发 Map |
| **Protocol Buffers** | 内部通信 | 比 JSON 序列化快 5-10x，体积减少 60% |
| **epoll/kqueue** | WebSocket Server | 单进程支撑 100K+ 连接 |
| **Message Batching** | WebSocket 推送 | 高频更新合并为一帧发送，降低系统调用 |
| **Incremental Update** | 客户端推送 | 仅推送变化字段，减少 70%+ 带宽 |
| **permessage-deflate** | WebSocket 压缩 | 压缩比约 60-80% |
| **Object Pool** | 消息对象 | sync.Pool 复用消息对象，降低 GC |

### 4.2 高可用设计

```
┌─────────────────────────────────────────────┐
│              高可用架构                       │
│                                             │
│  数据源层:                                   │
│  ┌─────────┐   ┌──────────┐                 │
│  │Primary  │   │Secondary │   自动故障切换    │
│  │Polygon  │◀─▶│IEX Cloud │   (< 3s)        │
│  └─────────┘   └──────────┘                 │
│                                             │
│  处理层:                                     │
│  ┌─────────┐   ┌──────────┐                 │
│  │Active   │   │Standby   │   主备热切换     │
│  │Engine   │◀─▶│Engine    │   (< 1s)        │
│  └─────────┘   └──────────┘                 │
│                                             │
│  分发层:                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐                 │
│  │WS-1  │ │WS-2  │ │WS-N  │  水平扩展       │
│  └──────┘ └──────┘ └──────┘  无状态节点      │
│                                             │
│  缓存层:                                     │
│  ┌────────────────────────┐                 │
│  │ Redis Cluster (6节点)  │  主从 + 哨兵     │
│  └────────────────────────┘                 │
│                                             │
│  存储层:                                     │
│  ┌────────────────────────┐                 │
│  │ TimescaleDB (主从复制)  │  流式复制       │
│  └────────────────────────┘                 │
└─────────────────────────────────────────────┘
```

### 4.3 容灾与恢复

| 场景 | 策略 | RTO |
|------|------|-----|
| 主数据源断连 | 自动切换备用数据源 | < 3s |
| Feed Handler 崩溃 | 进程自动重启 + 快照恢复 | < 5s |
| WebSocket 节点宕机 | 客户端自动重连其他节点 | < 3s |
| Redis 节点故障 | Sentinel 自动主从切换 | < 10s |
| Kafka Broker 故障 | ISR 机制自动切换 | < 5s |
| 全市场行情中断 | 显示最后已知价格 + 状态标记 | 立即 |

### 4.4 监控告警

```yaml
# Prometheus 核心监控指标

# Feed Handler
- feed_handler_messages_total{source, market, type}      # 消息总量
- feed_handler_latency_seconds{source, quantile}         # 处理延迟
- feed_handler_gaps_total{source}                        # 序列号缺失
- feed_handler_reconnects_total{source}                  # 重连次数
- feed_handler_status{source}                            # 连接状态

# Processing Engine
- processing_engine_throughput{type}                     # 处理吞吐量
- processing_engine_validation_failures_total{level}     # 校验失败
- processing_engine_kline_aggregation_lag_seconds         # K线聚合延迟

# WebSocket Gateway
- ws_gateway_connections_active                          # 活跃连接数
- ws_gateway_subscriptions_total{type}                   # 订阅总数
- ws_gateway_messages_sent_total                         # 推送消息量
- ws_gateway_message_latency_seconds{quantile}           # 推送延迟
- ws_gateway_slow_consumers_total                        # 慢消费者数量

# Cache
- quote_cache_hit_ratio                                  # 缓存命中率
- quote_cache_update_latency_seconds                     # 缓存更新延迟

# 告警规则
alerts:
  - name: FeedHandlerDown
    condition: feed_handler_status == 0
    severity: critical
    message: "数据源 {source} 连接中断"

  - name: HighLatency
    condition: processing_engine_latency_seconds{p99} > 0.05
    severity: warning
    message: "行情处理延迟超过 50ms"

  - name: DataGap
    condition: rate(feed_handler_gaps_total[5m]) > 0
    severity: critical
    message: "检测到行情数据缺失"
```

---

## 5. 服务划分

| 服务 | 语言 | 职责 | 实例数 |
|------|------|------|--------|
| `market-data-feed` | Go | Feed Handler, 数据源接入 | 每数据源 2 (主备) |
| `market-data-engine` | Go | 标准化, 聚合, 校验 | 2 (主备) |
| `market-data-cache` | Go | Redis 缓存管理, 内部推送 | 2 |
| `market-data-ws` | Go | WebSocket Gateway | 4+ (水平扩展) |
| `market-data-api` | Go | REST API (历史行情) | 3+ |
| `market-data-store` | Go | TimescaleDB 写入 | 2 |

---

## 6. 美港股市场特殊处理

### 6.1 交易时段管理

```go
type MarketCalendar struct {
    Market string
    Sessions []Session
}

var USMarket = MarketCalendar{
    Market: "US",
    Sessions: []Session{
        {Name: "Pre-Market",  Start: "04:00", End: "09:30", TZ: "America/New_York"},
        {Name: "Regular",     Start: "09:30", End: "16:00", TZ: "America/New_York"},
        {Name: "Post-Market", Start: "16:00", End: "20:00", TZ: "America/New_York"},
    },
}

var HKMarket = MarketCalendar{
    Market: "HK",
    Sessions: []Session{
        {Name: "Pre-Opening",    Start: "09:00", End: "09:30", TZ: "Asia/Hong_Kong"},
        {Name: "Morning",        Start: "09:30", End: "12:00", TZ: "Asia/Hong_Kong"},
        {Name: "Lunch Break",    Start: "12:00", End: "13:00", TZ: "Asia/Hong_Kong"},
        {Name: "Afternoon",      Start: "13:00", End: "16:00", TZ: "Asia/Hong_Kong"},
        {Name: "Closing Auction",Start: "16:00", End: "16:10", TZ: "Asia/Hong_Kong"},
    },
}
```

### 6.2 标的代码映射

```go
// 统一标的标识符
type SymbolMapping struct {
    Internal string  // 内部代码: "AAPL", "0700.HK"
    Exchange string  // 交易所代码
    ISIN     string  // 国际证券识别码
    SEDOL    string  // 港股常用
    Display  string  // 显示名称
}

// 美股: 直接使用 ticker (AAPL, TSLA, GOOGL)
// 港股: {code}.HK (0700.HK, 9988.HK)
// 美股期权: {underlying}{expiry}{type}{strike} (AAPL240315C00180000)
```

### 6.3 碎股处理 (港股)

```go
// 港股每手股数不同，需要特殊处理
type LotSize struct {
    Symbol  string
    Market  string
    LotSize int  // 每手股数 (港股: 100, 500, 1000, 2000 等不等)
}

// 美股无碎股限制，但 ODD LOT (< 100股) 交易有特殊规则
```

---

## 7. 部署架构

```
┌─────────────────── Kubernetes Cluster ───────────────────┐
│                                                          │
│  Namespace: market-data                                  │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Deployments                                         │ │
│  │                                                     │ │
│  │ market-data-feed-us    (2 replicas, anti-affinity)  │ │
│  │ market-data-feed-hk    (2 replicas, anti-affinity)  │ │
│  │ market-data-engine     (2 replicas, active-standby) │ │
│  │ market-data-cache      (2 replicas)                 │ │
│  │ market-data-ws         (4+ replicas, HPA)           │ │
│  │ market-data-api        (3+ replicas, HPA)           │ │
│  │ market-data-store      (2 replicas)                 │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ StatefulSets                                        │ │
│  │                                                     │ │
│  │ redis-cluster          (6 nodes: 3 master + 3 slave)│ │
│  │ kafka-cluster          (3 brokers)                  │ │
│  │ timescaledb            (1 primary + 1 replica)      │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Ingress                                             │ │
│  │                                                     │ │
│  │ wss://api.broker.com/ws/market-data  → market-data-ws│ │
│  │ https://api.broker.com/api/v1/market → market-data-api│
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ HPA (Horizontal Pod Autoscaler)                     │ │
│  │                                                     │ │
│  │ market-data-ws:  CPU > 60% → scale up (max 20)     │ │
│  │ market-data-api: CPU > 70% → scale up (max 10)     │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 8. 成本估算

| 组件 | 月成本 (估) | 说明 |
|------|-------------|------|
| Polygon.io (美股实时) | $2,000-5,000 | Business plan, 全市场实时行情 |
| HKEX OMD (港股) | HK$10,000-30,000 | 取决于牌照类型和数据级别 |
| Kubernetes 集群 | $3,000-5,000 | 约 20-30 节点 (含数据库) |
| Redis Cluster | $500-1,000 | 6 节点 (含在 K8s 成本中) |
| TimescaleDB | $500-1,000 | Cloud 或 self-hosted |
| Kafka | $500-1,000 | 含在 K8s 成本中 |
| CDN/带宽 | $1,000-3,000 | WebSocket 流量 |
| **合计** | **$8,000-15,000/月** | 初期规模 |
