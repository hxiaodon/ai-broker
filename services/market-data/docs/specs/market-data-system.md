---
type: domain-spec
version: v2.0
date: 2026-03-14
supersedes: v1.0 (2026-03-07)
surface_prd: mobile/docs/prd/03-market.md
status: ACTIVE
---

# 行情系统技术架构设计

> 美港股券商交易 App — Market Data System Architecture v2.0
> Phase 1 聚焦美股（NYSE/NASDAQ），港股（HKEX）为 Phase 2

---

## 目录

1. [系统概述](#1-系统概述)
2. [整体架构](#2-整体架构)
3. [分层详细设计](#3-分层详细设计)
4. [访客双轨推送架构](#4-访客双轨推送架构)
5. [WebSocket 协议完整规范](#5-websocket-协议完整规范)
6. [REST API 接口规范](#6-rest-api-接口规范)
7. [MySQL 数据模型](#7-mysql-数据模型)
8. [Redis 缓存设计](#8-redis-缓存设计)
9. [Kafka Topic 设计](#9-kafka-topic-设计)
10. [关键设计决策](#10-关键设计决策)
11. [监控告警](#11-监控告警)
12. [交易时段与市场日历](#12-交易时段与市场日历)
13. [Phase 1 部署方案](#13-phase-1-部署方案)

---

## 1. 系统概述

行情系统是券商交易平台的核心基础设施，负责从交易所/数据供应商实时获取市场数据，经标准化处理后分发给交易引擎和客户端。Phase 1 专注美股，同时预留港股扩展接口。

### 1.1 核心性能指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 端到端延迟（注册用户） | < 500ms (P99) | 数据源 → 客户端 WebSocket 推送 |
| 内部处理延迟 | < 50ms (P99) | Feed Handler → Redis 写入 |
| 并发 WebSocket 连接 | 100,000+ | 含注册用户 + 访客连接 |
| 行情吞吐量 | 50,000 msg/s | 峰值消息处理能力（Phase 1 美股） |
| 搜索响应时间 | < 300ms (P99) | 含拼音/中英文搜索 |
| K 线查询响应时间 | < 200ms (P99) | Redis 命中；MySQL 回退 < 500ms |
| K 线数据加载 | 首次 < 2s | 含网络传输 |
| 系统可用性 | 99.99% | 美股盘中时段（ET 09:30-16:00） |
| 数据准确率 | 100% | 与 Polygon.io 数据一致 |
| 主备数据源切换 | < 3s | 自动故障切换 |

### 1.2 支持的数据类型（Phase 1）

| 数据类型 | 描述 | 更新频率 |
|----------|------|----------|
| Level 1 快照 | 最新价、买一/卖一、涨跌幅、成交量 | 实时 Tick 推送 |
| Level 2 深度 | 5/10/20 档买卖盘口 | 实时推送（P1 后期） |
| 逐笔成交 | 每笔交易明细 | 实时推送 |
| K 线 (OHLCV) | 1min/5min/15min/30min/60min/1d/1w/1mo | 实时聚合 + 历史查询 |
| 盘前/盘后行情 | Pre-Market / After-Hours | 实时推送，附时段标签 |
| 市场状态 | REGULAR / PRE_MARKET / AFTER_HOURS / CLOSED / HALTED | 状态变更推送 |
| 股票基本面 | 市值、P/E、P/B、EPS、52 周高/低 | 每日更新 |
| 新闻资讯 | Polygon.io 新闻 API | 每 5 分钟刷新 |
| 财务数据 | 近 4 季度营收/净利润/EPS | 财报发布后更新 |

### 1.3 Phase 1 范围边界

- **数据源**: 仅 Polygon.io（主）+ IEX Cloud（备）
- **市场**: 仅美股 NYSE/NASDAQ
- **服务形态**: 单体模块化（Feed + Engine + Cache + WS + API 合并为一个 Go 进程，按包划分）
- **存储**: MySQL 8.0（K 线、逐笔）；Phase 2 评估迁移至 TimescaleDB
- **用户类型**: 注册用户（实时行情）+ 访客（延迟 15 分钟行情）

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Market Data Service (Phase 1)                          │
│                                                                                  │
│  ┌──────────────────┐    ┌───────────────────┐    ┌──────────────────────────┐  │
│  │  Data Source      │    │  Feed Handler     │    │  Processing Engine        │  │
│  │  Layer            │    │  Layer            │    │                           │  │
│  │  ┌────────────┐  │    │  ┌─────────────┐  │    │  ┌─────────────────────┐ │  │
│  │  │ Polygon.io │──┼───▶│  │ US Feed     │──┼───▶│  │  Normalizer          │ │  │
│  │  │ (主数据源) │  │    │  │ Handler     │  │    │  │  (统一 Protobuf 格式) │ │  │
│  │  └────────────┘  │    │  └─────────────┘  │    │  └──────────┬──────────┘ │  │
│  │  ┌────────────┐  │    │  ┌─────────────┐  │    │             │            │  │
│  │  │ IEX Cloud  │──┼───▶│  │ Backup Feed │──┼─── │  ┌──────────▼──────────┐ │  │
│  │  │ (备用数据源) │ │    │  │ Handler     │  │    │  │  KlineAggregator     │ │  │
│  │  └────────────┘  │    │  └─────────────┘  │    │  │  (实时 OHLCV 聚合)   │ │  │
│  │  ┌────────────┐  │    │  ┌─────────────┐  │    │  └──────────┬──────────┘ │  │
│  │  │ HKEX OMD   │──┼───▶│  │ HK Feed     │  │    │             │            │  │
│  │  │ (Phase 2)  │  │    │  │ Handler     │  │    │  ┌──────────▼──────────┐ │  │
│  │  └────────────┘  │    │  └─────────────┘  │    │  │  QuoteValidator      │ │  │
│  └──────────────────┘    └───────────────────┘    │  │  (价格/时间戳校验)   │ │  │
│                                                    │  └──────────┬──────────┘ │  │
│                                                    └─────────────┼────────────┘  │
│                                                                  │               │
│              ┌───────────────────────────────────────────────────┤               │
│              │                          │                        │               │
│              ▼                          ▼                        ▼               │
│  ┌───────────────────┐    ┌─────────────────────┐    ┌──────────────────────┐   │
│  │  Redis Cache       │    │  DelayedQuote        │    │  Storage Layer        │   │
│  │  Layer             │    │  RingBuffer          │    │                       │   │
│  │  (实时行情快照)    │    │  (访客延迟行情)      │    │  MySQL 8.0            │   │
│  │  quote:{mkt}:{sym} │    │  T-15min 历史快照    │    │  klines / ticks       │   │
│  └────────┬──────────┘    └─────────────────────┘    │  stocks / watchlist    │   │
│           │                                           │  news / financials     │   │
│           ▼                                           └──────────────────────┘   │
│  ┌───────────────────────────────────────────────────────────────────────────┐   │
│  │                         Distribution Layer                                  │   │
│  │                                                                             │   │
│  │  ┌────────────────┐   ┌─────────────────────────────────────────────────┐  │   │
│  │  │  Kafka Cluster │   │  WebSocket Gateway                               │  │   │
│  │  │  (内部分发)    │   │  - JWT 认证（5s 超时）                           │  │   │
│  │  │  market-data.  │   │  - 注册用户: 实时 Tick 推送                      │  │   │
│  │  │  quotes.us     │   │  - 访客: 每 5s 从 RingBuffer 推送 T-15min 数据   │  │   │
│  │  │  trades.us     │   │  - reauth 无缝切换实时/延迟流                    │  │   │
│  │  │  klines        │   │  - 单连接最多订阅 50 symbols                     │  │   │
│  │  │  market.status │   └─────────────────────────────────────────────────┘  │   │
│  │  └────────────────┘                                                         │   │
│  │  ┌────────────────┐   ┌─────────────────────┐                              │   │
│  │  │  gRPC          │   │  REST API            │                              │   │
│  │  │  (内部服务调用) │   │  /v1/market/...      │                              │   │
│  │  └────────────────┘   └─────────────────────┘                              │   │
│  └───────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                          │
              ┌───────────────────────────┼───────────────────────┐
              ▼                           ▼                        ▼
   ┌──────────────────┐       ┌──────────────────┐    ┌──────────────────────┐
   │  iOS / Android    │       │  Trading Engine   │    │  Admin Panel          │
   │  Flutter App      │       │  (价格校验/风控)   │    │  (市场监控)           │
   └──────────────────┘       └──────────────────┘    └──────────────────────┘
```

---

## 3. 分层详细设计

### 3.1 数据源接入层

#### 美股数据源（Phase 1）

| 数据源 | 角色 | 协议 | 数据级别 | 延迟 |
|--------|------|------|----------|------|
| **Polygon.io** | 主数据源 | WebSocket (wss://) | L1 Quotes / Trades / Aggregates | ~10ms |
| **IEX Cloud** | 备用数据源 | SSE / WebSocket | L1 Quotes / Trades | ~50ms |

#### 港股数据源（Phase 2 预留）

| 数据源 | 角色 | 协议 | 数据级别 | 延迟 |
|--------|------|------|----------|------|
| **HKEX OMD-C** | 主数据源 | Binary/TCP (OMD 协议) | L1/L2/Trades | ~1ms |
| **AAStocks** | 备用数据源 | REST/WebSocket | L1 | ~100ms |

#### 数据源优先级管理

```go
// internal/feedhandler/config.go

type FeedSource string

const (
    FeedPolygon  FeedSource = "polygon"
    FeedIEX      FeedSource = "iex"
    FeedHKEXOMD  FeedSource = "hkex_omd"
)

type FeedConfig struct {
    Market    string       // "US" / "HK"
    Primary   FeedSource   // 主数据源
    Secondary FeedSource   // 备用数据源，自动切换
    // 主备切换条件:
    //   1. 心跳超时 > 3s
    //   2. 连续 30s 无消息（盘中时段）
    //   3. 序列号缺口 > 100 且 10s 内未恢复
    SwitchThresholdSec int
}

var USFeedConfig = FeedConfig{
    Market:             "US",
    Primary:            FeedPolygon,
    Secondary:          FeedIEX,
    SwitchThresholdSec: 3,
}
```

### 3.2 Feed Handler 层

每个数据源对应一个独立的 Feed Handler goroutine 组，负责连接管理、协议解析、序列号校验、心跳监控。

```go
// internal/feedhandler/handler.go

// FeedHandler 核心接口
type FeedHandler interface {
    // 连接数据源
    Connect(ctx context.Context) error
    // 订阅标的（Phase 1 US 全市场订阅，无需指定 symbol 列表）
    Subscribe(symbols []string, types []DataType) error
    // 取消订阅
    Unsubscribe(symbols []string) error
    // 消息输出通道（非阻塞 Ring Buffer）
    Messages() <-chan RawMessage
    // 健康检查
    Health() HealthStatus
    // 关闭
    Close() error
}

// 原始消息（标准化前）
type RawMessage struct {
    Source    FeedSource // 数据源标识
    Market    string     // "US" / "HK"
    Symbol    string     // 标的代码
    Type      DataType   // Quote / Trade / Depth / Kline
    Sequence  uint64     // 序列号，用于缺口检测
    Timestamp time.Time  // 数据源时间戳（UTC）
    Payload   []byte     // 原始 JSON 或 Binary 数据
}

// 健康状态
type HealthStatus struct {
    Connected      bool
    LastMessageAt  time.Time
    MessagesPerSec float64
    GapsDetected   int64  // 序列号缺口次数
}
```

#### Feed Handler 进程模型

```
┌──────────────────────────────────────────────────────────────┐
│                    Feed Handler（单数据源）                    │
│                                                               │
│  ┌───────────┐     ┌────────────┐     ┌────────────────────┐  │
│  │ Connector  │────▶│  Decoder   │────▶│  Sequencer         │  │
│  │ (WSS/TCP)  │     │ (JSON/     │     │  (序列号校验       │  │
│  │            │     │  Binary)   │     │   缺口检测         │  │
│  └───────────┘     └────────────┘     │   快照请求触发)    │  │
│        ▲                              └────────┬───────────┘  │
│        │ 自动重连（指数退避）                   │              │
│  ┌───────────┐                        ┌────────▼───────────┐  │
│  │  Watchdog  │                       │   Output Ring      │  │
│  │  (心跳/   │                        │   Buffer           │──────▶ Processing Engine
│  │   活性监控) │                       │   (lock-free,      │  │
│  └───────────┘                        │    8192 slots)     │  │
│                                       └────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

**连接管理细节**:
- 初始连接失败：指数退避重试，最大间隔 30s
- 盘中断连：立即重连，3s 内未恢复则切换备用数据源
- 序列号缺口：发送 Snapshot Request 补齐，10s 内未恢复则触发全量快照
- 心跳：每 10s 发送 Ping，30s 无响应判定断连

### 3.3 处理引擎层

#### 3.3.1 Normalizer — 数据标准化

将不同数据源的私有格式统一为内部 Protobuf 标准格式。所有价格字段使用字符串（避免浮点精度丢失），所有时间戳使用 ISO 8601 UTC 字符串（JSON 层）或 Unix nanoseconds（内部 Protobuf）。

```protobuf
// api/grpc/market_data.proto
syntax = "proto3";
package marketdata;
option go_package = "github.com/broker/market-data/api/grpc";

// 统一行情快照（Level 1）
message Quote {
    string symbol      = 1;   // 标的代码，如 "AAPL"、"0700.HK"
    string market      = 2;   // 市场，"US" / "HK"
    string currency    = 3;   // 币种，"USD" / "HKD"

    // 最新成交
    string last_price  = 4;   // 最新价（字符串，4 位小数）
    int64  last_volume = 5;   // 最新成交量
    int64  timestamp   = 6;   // 数据时间戳（Unix nanoseconds，UTC）

    // 买卖盘 Level 1
    string bid_price   = 7;   // 买一价
    int64  bid_size    = 8;   // 买一量
    string ask_price   = 9;   // 卖一价
    int64  ask_size    = 10;  // 卖一量

    // 日内统计
    string open        = 11;  // 今日开盘价
    string high        = 12;  // 今日最高价
    string low         = 13;  // 今日最低价
    string prev_close  = 14;  // 昨日收盘价
    int64  volume      = 15;  // 当日累计成交量
    string turnover    = 16;  // 当日成交额
    string turnover_rate = 17; // 换手率 = volume / shares_outstanding，2 位小数

    // 涨跌
    string change      = 18;  // 涨跌额（last_price - prev_close）
    string change_pct  = 19;  // 涨跌幅（百分比，如 "0.68"）

    // 交易状态
    MarketStatus market_status = 20;  // REGULAR / PRE_MARKET / AFTER_HOURS / CLOSED / HALTED
}

// 深度行情 Level 2
message Depth {
    string symbol  = 1;
    string market  = 2;
    int64  timestamp = 3;          // Unix nanoseconds
    repeated PriceLevel bids = 4;  // 买盘，价格降序
    repeated PriceLevel asks = 5;  // 卖盘，价格升序
}

message PriceLevel {
    string price       = 1;  // 价格
    int64  volume      = 2;  // 量
    int32  order_count = 3;  // 该价位订单数
}

// 逐笔成交
message Trade {
    string    symbol     = 1;
    string    market     = 2;
    string    price      = 3;   // 成交价（字符串）
    int64     volume     = 4;   // 成交量
    int64     timestamp  = 5;   // Unix nanoseconds
    string    trade_id   = 6;   // 交易所成交编号
    TradeSide side       = 7;   // BUY / SELL / UNKNOWN
    repeated TradeCondition conditions = 8;
}

// K 线
message Kline {
    string        symbol    = 1;
    string        market    = 2;
    string        open      = 3;
    string        high      = 4;
    string        low       = 5;
    string        close     = 6;
    int64         volume    = 7;
    string        turnover  = 8;
    int64         timestamp = 9;  // K 线起始时间（Unix nanoseconds，UTC）
    KlineInterval interval  = 10;
    bool          is_final  = 11; // true = 已收盘 K 线；false = 实时更新中
}

enum MarketStatus {
    MARKET_STATUS_UNKNOWN = 0;
    REGULAR     = 1;  // 常规时段 09:30-16:00 ET
    PRE_MARKET  = 2;  // 盘前 04:00-09:30 ET
    AFTER_HOURS = 3;  // 盘后 16:00-20:00 ET
    CLOSED      = 4;  // 休市
    HALTED      = 5;  // 交易暂停
}

enum TradeSide {
    SIDE_UNKNOWN = 0;
    BUY          = 1;
    SELL         = 2;
}

enum KlineInterval {
    INTERVAL_UNKNOWN = 0;
    MIN_1   = 1;   // "1min"
    MIN_5   = 2;   // "5min"
    MIN_15  = 3;   // "15min"
    MIN_30  = 4;   // "30min"
    HOUR_1  = 5;   // "60min"
    DAY_1   = 6;   // "1d"
    WEEK_1  = 7;   // "1w"
    MONTH_1 = 8;   // "1mo"
}

enum TradeCondition {
    CONDITION_UNKNOWN = 0;
    REGULAR_SALE      = 1;
    ODD_LOT           = 2;
    CROSS_TRADE       = 3;
    DARK_POOL         = 4;
}
```

#### 3.3.2 KlineAggregator — K 线聚合引擎

实时将逐笔成交聚合为多周期 K 线，写入 Redis 实时 K 线缓存，并在周期结束时持久化到 MySQL。

```go
// internal/engine/kline_aggregator.go

// KlineAggregator 管理所有标的所有周期的实时 K 线构建
type KlineAggregator struct {
    mu      sync.RWMutex
    // symbol -> interval -> KlineBuilder
    builders map[string]map[KlineInterval]*KlineBuilder
    output   chan *Kline  // 已完成 K 线输出通道（写入 MySQL + Kafka）
    redis    *cache.RedisClient
}

// KlineBuilder 单标的单周期的实时 K 线状态
type KlineBuilder struct {
    Symbol     string
    Market     string
    Interval   KlineInterval
    Open       decimal.Decimal
    High       decimal.Decimal
    Low        decimal.Decimal
    Close      decimal.Decimal
    Volume     int64
    Turnover   decimal.Decimal
    StartTime  time.Time   // UTC
    TradeCount int32
    IsDirty    bool        // 是否有新的 trade 更新，用于控制推送频率
}

// Update 处理一笔 Trade，更新当前 K 线
func (b *KlineBuilder) Update(trade *Trade) {
    price := decimal.RequireFromString(trade.Price)
    qty := decimal.NewFromInt(trade.Volume)

    if b.TradeCount == 0 {
        b.Open  = price
        b.High  = price
        b.Low   = price
    } else {
        if price.GreaterThan(b.High) {
            b.High = price
        }
        if price.LessThan(b.Low) {
            b.Low = price
        }
    }
    b.Close    = price
    b.Volume  += trade.Volume
    b.Turnover = b.Turnover.Add(price.Mul(qty))
    b.TradeCount++
    b.IsDirty  = true
}

// Flush 周期结束时封闭当前 K 线，返回完成的 Kline
func (b *KlineBuilder) Flush(nextStart time.Time) *Kline {
    k := &Kline{
        Symbol:    b.Symbol,
        Market:    b.Market,
        Interval:  b.Interval,
        Open:      b.Open.String(),
        High:      b.High.String(),
        Low:       b.Low.String(),
        Close:     b.Close.String(),
        Volume:    b.Volume,
        Turnover:  b.Turnover.StringFixed(2),
        Timestamp: b.StartTime.UnixNano(),
        IsFinal:   true,
    }
    // 重置 Builder 为新周期
    b.Open      = b.Close
    b.High      = b.Close
    b.Low       = b.Close
    b.Volume    = 0
    b.Turnover  = decimal.Zero
    b.TradeCount = 0
    b.StartTime = nextStart
    b.IsDirty   = false
    return k
}
```

**K 线周期边界**（ET 时区基准，仅常规时段聚合分钟线）:

| 周期 | 聚合边界 | 日线历史深度 | 分钟线深度 |
|------|----------|------------|------------|
| 1min | 每分钟整点 | — | 当日全量（约 390 根） |
| 5min | 5 分钟整点 | — | 当日全量 |
| 15min | 15 分钟整点 | — | 当日全量 |
| 30min | 30 分钟整点 | — | 当日全量 |
| 60min | 整点 | — | 当日全量 |
| 1d | 交易日 | 近 2 年 | — |
| 1w | 自然周（周一开盘） | 近 5 年 | — |
| 1mo | 自然月 | 全历史 | — |

注：分钟级 K 线仅聚合常规时段（09:30-16:00 ET），盘前/盘后数据不纳入分钟线。

#### 3.3.3 QuoteValidator — 数据校验

```go
// internal/engine/validator.go

type QuoteValidator struct {
    prevQuotes sync.Map // symbol -> *Quote（上一次有效报价）
}

type ValidationResult struct {
    Valid  bool
    Issues []ValidationIssue
}

type ValidationLevel string

const (
    Critical ValidationLevel = "CRITICAL" // 丢弃该报价
    Warning  ValidationLevel = "WARNING"  // 标记并继续
)

type ValidationIssue struct {
    Level   ValidationLevel
    Message string
}

func (v *QuoteValidator) Validate(q *Quote) ValidationResult {
    var issues []ValidationIssue
    price := decimal.RequireFromString(q.LastPrice)

    // 规则 1: 价格必须为正
    if price.LessThanOrEqual(decimal.Zero) {
        issues = append(issues, ValidationIssue{Critical, "price <= 0"})
    }

    // 规则 2: 买卖价合理性（bid <= ask）
    bid := decimal.RequireFromString(q.BidPrice)
    ask := decimal.RequireFromString(q.AskPrice)
    if bid.GreaterThan(ask) {
        issues = append(issues, ValidationIssue{Warning, "crossed market: bid > ask"})
    }

    // 规则 3: 与上一笔价格比较，>20% 波动触发告警
    if prev, ok := v.prevQuotes.Load(q.Symbol); ok {
        prevPrice := decimal.RequireFromString(prev.(*Quote).LastPrice)
        if !prevPrice.IsZero() {
            changePct := price.Sub(prevPrice).Div(prevPrice).Abs()
            if changePct.GreaterThan(decimal.NewFromFloat(0.20)) {
                issues = append(issues, ValidationIssue{
                    Warning,
                    fmt.Sprintf("abnormal price spike: %.2f%% change", changePct.InexactFloat64()*100),
                })
            }
        }
    }

    // 规则 4: 时间戳新鲜度（> 5 分钟视为过期）
    dataTime := time.Unix(0, q.Timestamp)
    if time.Since(dataTime) > 5*time.Minute {
        issues = append(issues, ValidationIssue{Warning, "stale data: timestamp > 5min old"})
    }

    // 规则 5: 美股标的代码格式（1-5 位大写字母）
    if q.Market == "US" {
        if !regexp.MustCompile(`^[A-Z]{1,5}$`).MatchString(q.Symbol) {
            issues = append(issues, ValidationIssue{Critical, "invalid US symbol format"})
        }
    }

    // 更新缓存（仅 Critical 以下的消息）
    hasCritical := false
    for _, issue := range issues {
        if issue.Level == Critical {
            hasCritical = true
        }
    }
    if !hasCritical {
        v.prevQuotes.Store(q.Symbol, q)
    }

    return ValidationResult{
        Valid:  !hasCritical,
        Issues: issues,
    }
}
```

### 3.4 本地内存缓存（Hot Path）

进程内 `sync.Map` 维护最新行情快照，用于 Trading Engine gRPC 查价（超低延迟路径）和 WebSocket 推送去重。

```go
// internal/cache/local.go

type LocalQuoteCache struct {
    quotes atomic.Pointer[map[string]*Quote] // COW（Copy-On-Write）更新
}

func (c *LocalQuoteCache) Get(symbol string) (*Quote, bool) {
    m := c.quotes.Load()
    if m == nil {
        return nil, false
    }
    q, ok := (*m)[symbol]
    return q, ok
}

// Update 由处理引擎在验证通过后调用（每次 trade/quote 更新）
func (c *LocalQuoteCache) Update(q *Quote) {
    for {
        old := c.quotes.Load()
        var newMap map[string]*Quote
        if old == nil {
            newMap = make(map[string]*Quote)
        } else {
            newMap = make(map[string]*Quote, len(*old)+1)
            for k, v := range *old {
                newMap[k] = v
            }
        }
        newMap[q.Symbol] = q
        if c.quotes.CompareAndSwap(old, &newMap) {
            break
        }
    }
}
```

---

## 4. 访客双轨推送架构

本章是 v2.0 新增核心设计，解决访客延迟 15 分钟行情的实现问题。

### 4.1 设计原则

**不能** 在消息队列中 hold 住消息 15 分钟推送（会造成 15 分钟量级的内存积压），而是维护一个全局内存 Ring Buffer，定期将实时行情快照写入，访客推送时从 T-15min 时刻读取对应快照。

### 4.2 DelayedQuoteRingBuffer

```go
// internal/delayed/ring_buffer.go

const (
    RingBufferCapacity = 20  // 保留最近 20 分钟的快照
    SnapshotIntervalSec = 60 // 每 60 秒写入一次快照
    GuestDelayMinutes  = 15  // 访客延迟 15 分钟
    GuestPushIntervalSec = 5 // 访客推送频率（每 5 秒一次）
)

// MinuteSnapshot 某一分钟时刻所有标的的行情快照
type MinuteSnapshot struct {
    Timestamp time.Time            // 快照时刻（UTC，精确到分钟）
    Quotes    map[string]*Quote    // symbol -> Quote
}

// DelayedQuoteRingBuffer 全局单例，线程安全
type DelayedQuoteRingBuffer struct {
    mu       sync.RWMutex
    slots    [RingBufferCapacity]*MinuteSnapshot
    head     int    // 最新槽位索引
    size     int    // 当前有效槽位数
}

var globalRingBuffer = &DelayedQuoteRingBuffer{}

// WriteSnapshot 由后台 goroutine 每分钟调用一次，从 LocalQuoteCache 读取全量快照写入
func (rb *DelayedQuoteRingBuffer) WriteSnapshot(snapshot *MinuteSnapshot) {
    rb.mu.Lock()
    defer rb.mu.Unlock()
    rb.head = (rb.head + 1) % RingBufferCapacity
    rb.slots[rb.head] = snapshot
    if rb.size < RingBufferCapacity {
        rb.size++
    }
}

// GetDelayedQuote 读取指定 symbol 在 T-15min 时刻的行情快照
// 返回 nil 表示历史快照尚未积累 15 分钟（服务刚启动时）
func (rb *DelayedQuoteRingBuffer) GetDelayedQuote(symbol string) (*Quote, time.Time) {
    rb.mu.RLock()
    defer rb.mu.RUnlock()

    if rb.size < GuestDelayMinutes {
        return nil, time.Time{} // 快照不足 15 分钟
    }

    // 向前查找 15 个槽位（每槽 1 分钟）
    targetIdx := (rb.head - GuestDelayMinutes + RingBufferCapacity) % RingBufferCapacity
    slot := rb.slots[targetIdx]
    if slot == nil {
        return nil, time.Time{}
    }

    q, ok := slot.Quotes[symbol]
    if !ok {
        return nil, time.Time{}
    }
    return q, slot.Timestamp
}
```

### 4.3 双轨推送流程

```
注册用户连接（auth 成功，user_type=registered）：
    ├── 订阅后，立即从 LocalQuoteCache 读取最新快照发送（Snapshot 投递）
    ├── 后续每次 Trade/Quote 事件触发实时推送（Tick 级，无节流）
    └── 推送消息附 "delayed": false

访客连接（auth 成功，user_type=guest，或 token 为空）：
    ├── 订阅后，从 RingBuffer[T-15min] 读取快照发送（若历史不足 15min，跳过或提示）
    ├── 后台每 5 秒定时：从 RingBuffer[T-15min] 读最新快照 → 推送给该访客连接
    └── 推送消息附 "delayed": true

reauth 事件（访客登录后发送 reauth 消息）：
    ├── 验证新 JWT 有效，切换 connection.userType = registered
    ├── 立即从 LocalQuoteCache 读取实时快照推送（弥补延迟差）
    ├── 停止访客定时推送任务，改为 Tick 级实时推送
    └── 客户端收到后执行 500ms 价格渐变动画（避免突然跳价）
```

### 4.4 内存估算

Phase 1 美股全市场约 8,000 只标的：
- 单个 Quote 结构体约 400 bytes
- 单个分钟快照 = 8,000 * 400 bytes = ~3.2 MB
- Ring Buffer 20 个槽位 = 20 * 3.2 MB = **~64 MB**（可接受，进程内驻留）

### 4.5 后台快照写入 Goroutine

```go
// internal/delayed/snapshot_writer.go

func StartSnapshotWriter(ctx context.Context, localCache *cache.LocalQuoteCache, rb *DelayedQuoteRingBuffer) {
    ticker := time.NewTicker(SnapshotIntervalSec * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case t := <-ticker.C:
            // 从 LocalQuoteCache 读取所有标的当前行情
            snapshot := &MinuteSnapshot{
                Timestamp: t.UTC().Truncate(time.Minute),
                Quotes:    make(map[string]*Quote),
            }
            localCache.Range(func(symbol string, q *Quote) {
                // 深拷贝，避免引用竞争
                qCopy := *q
                snapshot.Quotes[symbol] = &qCopy
            })
            rb.WriteSnapshot(snapshot)
        }
    }
}
```

---

## 5. WebSocket 协议完整规范

### 5.1 连接地址

```
生产环境: wss://api.broker.com/ws/market
开发环境: ws://localhost:8080/ws/market
```

### 5.2 消息格式约定

- **客户端 → 服务端**: 使用 `"action"` 字段标识消息类型
- **服务端 → 客户端**: 使用 `"type"` 字段标识消息类型
- **价格字段**: 全部为字符串（`"182.5200"`），客户端使用 Decimal 解析，禁止 float
- **时间戳字段**: ISO 8601 UTC 格式（`"2026-03-13T14:30:00.123Z"`）
- **传输格式**: JSON（生产环境可协商升级为 Protobuf Binary，通过 HTTP Header 协商）

### 5.3 连接生命周期

```
Client                              Server
  │                                   │
  │── WSS 握手 ────────────────────▶  │
  │◀── HTTP 101 Switching Protocols ──│
  │                                   │
  │  [5 秒超时窗口，服务端等待 auth]   │
  │                                   │
  │── { action: "auth", token: JWT }─▶│  Step 1: 认证
  │◀── { type: "auth_result", ... } ──│  Step 2: 认证结果
  │                                   │
  │── { action: "subscribe", ... } ──▶│  Step 3: 订阅
  │◀── { type: "subscribe_ack", ... } │  Step 4: 订阅确认 + 快照
  │                                   │
  │◀── { type: "quote", ... } ────────│  Step 5: 实时/延迟推送（持续）
  │                                   │
  │◀── { type: "token_expiring", ...} │  Step 6: Token 即将过期（提前 2 分钟）
  │── { action: "reauth", token: JWT}▶│  Step 7: 刷新 Token
  │                                   │
  │── { action: "unsubscribe", ... }─▶│  Step 8: 取消订阅（可选）
  │                                   │
  │── { action: "ping" } ────────────▶│  心跳（客户端每 30s 发送）
  │◀── { type: "pong", ... } ─────────│
  │                                   │
  │── 关闭连接 ───────────────────────│
```

**超时规则**:
- 连接建立后 5 秒内未收到 `auth` 消息：服务端发送 `{"type":"error","code":"AUTH_TIMEOUT"}` 后关闭连接
- 60 秒无任何消息（含 ping）：服务端主动关闭连接

### 5.4 完整消息定义

#### Step 1 — 客户端认证

```json
// 注册用户（携带有效 JWT）
{
  "action": "auth",
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}

// 访客（token 为空字符串或省略 token 字段）
{
  "action": "auth",
  "token": ""
}
```

#### Step 2 — 服务端认证结果

```json
// 认证成功（注册用户）
{
  "type": "auth_result",
  "success": true,
  "user_type": "registered",
  "token_expires_in": 850
}

// 认证成功（访客）
{
  "type": "auth_result",
  "success": true,
  "user_type": "guest",
  "token_expires_in": null
}

// 认证失败（Token 无效或过期）
{
  "type": "auth_result",
  "success": false,
  "error": "INVALID_TOKEN",
  "message": "Token signature verification failed"
}
```

#### Step 3 — 客户端订阅

```json
{
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA", "NVDA", "MSFT"]
}
```

**约束**:
- `symbols` 数组最多 50 个元素，超出返回 `SYMBOLS_LIMIT_EXCEEDED` 错误
- 必须在 `auth_result.success = true` 之后才能发送订阅，否则返回 `NOT_AUTHENTICATED` 错误
- 多次调用 `subscribe` 会**追加**到当前订阅集合（不替换）

#### Step 4 — 服务端订阅确认 + 快照

```json
{
  "type": "subscribe_ack",
  "symbols": ["AAPL", "TSLA", "NVDA", "MSFT"],
  "snapshot": {
    "AAPL": {
      "symbol": "AAPL",
      "price": "182.5200",
      "change": "1.2400",
      "change_pct": "0.68",
      "volume": 45678900,
      "bid": "182.5100",
      "ask": "182.5300",
      "open": "181.0000",
      "high": "183.5000",
      "low": "180.0000",
      "prev_close": "181.2800",
      "turnover": "8327145600",
      "turnover_rate": "0.31",
      "market_status": "REGULAR",
      "timestamp": "2026-03-13T14:30:00.123Z",
      "delayed": false
    }
  },
  "timestamp": "2026-03-13T14:30:00.200Z"
}
```

#### Step 5 — 行情推送（持续）

```json
// 注册用户实时推送（Tick 级，每次有更新即推送）
{
  "type": "quote",
  "symbol": "AAPL",
  "price": "182.6100",
  "change": "1.3300",
  "change_pct": "0.74",
  "volume": 45701234,
  "bid": "182.6000",
  "ask": "182.6200",
  "market_status": "REGULAR",
  "timestamp": "2026-03-13T14:30:01.045Z",
  "delayed": false
}

// 访客延迟推送（每 5 秒一次，从 T-15min RingBuffer 读取）
{
  "type": "quote",
  "symbol": "AAPL",
  "price": "181.3500",
  "change": "0.0700",
  "change_pct": "0.04",
  "volume": 41230000,
  "bid": "181.3400",
  "ask": "181.3600",
  "market_status": "REGULAR",
  "timestamp": "2026-03-13T14:15:00.000Z",
  "delayed": true
}
```

#### Step 6 — Token 即将过期提醒（服务端主动推送）

```json
{
  "type": "token_expiring",
  "expires_in": 120
}
```

#### Step 7 — 客户端重新认证（无缝切换流）

```json
// 客户端刷新 Token 后，或访客登录后，发送 reauth
{
  "action": "reauth",
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...（新 JWT）"
}

// 服务端响应 reauth 结果
{
  "type": "reauth_result",
  "success": true,
  "user_type": "registered",
  "token_expires_in": 900
}
```

reauth 成功后，服务端立即切换该连接的推送模式（访客 → 注册用户），不断开 WebSocket 连接，不丢失已有订阅列表。

#### Step 8 — 取消订阅

```json
{
  "action": "unsubscribe",
  "symbols": ["TSLA"]
}

// 服务端确认
{
  "type": "unsubscribe_ack",
  "symbols": ["TSLA"],
  "remaining": ["AAPL", "NVDA", "MSFT"],
  "timestamp": "2026-03-13T14:31:00.000Z"
}
```

#### 心跳

```json
// 客户端 → 服务端（每 30 秒发送一次）
{ "action": "ping" }

// 服务端 → 客户端
{
  "type": "pong",
  "timestamp": "2026-03-13T14:31:00.000Z"
}
```

#### 服务端错误消息

```json
{
  "type": "error",
  "code": "SYMBOLS_LIMIT_EXCEEDED",
  "message": "Maximum 50 symbols per connection, provided: 53",
  "timestamp": "2026-03-13T14:31:00.000Z"
}
```

| 错误码 | 触发场景 |
|--------|---------|
| `AUTH_TIMEOUT` | 连接建立 5s 内未发送 auth |
| `INVALID_TOKEN` | JWT 签名验证失败或已过期 |
| `NOT_AUTHENTICATED` | 订阅前未完成认证 |
| `SYMBOLS_LIMIT_EXCEEDED` | 单次 subscribe 超过 50 个 |
| `SYMBOL_NOT_FOUND` | 订阅了不存在的标的代码 |
| `RATE_LIMITED` | 消息发送频率超限 |
| `INTERNAL_ERROR` | 服务端内部错误 |

### 5.5 WebSocket Gateway 内部架构

```go
// internal/websocket/hub.go

// ConnState 单连接状态
type ConnState struct {
    ID          string              // 连接 UUID
    Conn        *websocket.Conn
    UserType    UserType            // registered / guest
    UserID      string              // 注册用户 ID（访客为空）
    Symbols     map[string]struct{} // 已订阅标的集合（上限 50）
    TokenExp    time.Time           // JWT 过期时间
    AuthAt      time.Time           // 认证时间
    CreatedAt   time.Time

    send        chan []byte         // 发送缓冲通道（大小 256）
    guestTicker *time.Ticker       // 访客 5s 推送定时器（仅访客连接）
}

// Hub 管理所有 WebSocket 连接
type Hub struct {
    // symbol -> 订阅该 symbol 的所有连接
    subscriptions map[string]map[string]*ConnState // symbol -> connID -> conn

    // 连接注册/注销
    register   chan *ConnState
    unregister chan *ConnState

    // 实时行情广播（由处理引擎写入）
    broadcast  chan *Quote

    mu         sync.RWMutex
}
```

**连接级流控**:
- 发送缓冲通道大小 256 条消息
- 若客户端消费过慢导致 `send` 通道满，触发背压降级：跳过中间 tick，仅保留最新 1 帧推送
- 单个 WebSocket 连接的写操作串行化，避免并发写 panic

---

## 6. REST API 接口规范

所有接口统一前缀 `/v1/market`（公开市场数据）或 `/v1/watchlist`（需认证）。

**公共响应结构**:
```json
{
  "data": { ... },
  "error": null,
  "as_of": "2026-03-13T14:30:00.000Z"
}
```

错误时：
```json
{
  "data": null,
  "error": {
    "code": "TOO_MANY_SYMBOLS",
    "message": "Maximum 50 symbols allowed, provided: 53",
    "max": 50,
    "provided": 53
  }
}
```

### 6.1 股票快照（批量）

```
GET /v1/market/quotes?symbols=AAPL,TSLA,NVDA

Authorization: Bearer <JWT>（可选；未提供时返回延迟行情）

约束：symbols 最多 50 个，超出返回 HTTP 400
```

**响应示例**:
```json
{
  "data": {
    "quotes": {
      "AAPL": {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "name_zh": "苹果公司",
        "price": "182.5200",
        "change": "1.2400",
        "change_pct": "0.68",
        "volume": 45678900,
        "turnover": "8327145600",
        "turnover_rate": "0.31",
        "open": "181.0000",
        "high": "183.5000",
        "low": "180.0000",
        "prev_close": "181.2800",
        "bid": "182.5100",
        "ask": "182.5300",
        "market_cap": 2800000000000,
        "pe_ratio": "28.50",
        "market_status": "REGULAR",
        "delayed": false
      },
      "TSLA": { "..." : "..." }
    },
    "as_of": "2026-03-13T14:30:00.000Z"
  }
}
```

**字段说明**:
- `price`、`change`、`change_pct`、`open`、`high`、`low`、`prev_close`、`bid`、`ask`、`pe_ratio`：字符串类型，客户端按 Decimal 解析
- `volume`、`market_cap`：整型
- `turnover_rate`：换手率，计算公式 `volume / shares_outstanding`，保留 2 位小数
- `delayed: true` 时 `price` 为 T-15min 历史快照价
- `market_status` 枚举：`REGULAR | PRE_MARKET | AFTER_HOURS | CLOSED | HALTED`

### 6.2 K 线历史数据

```
// 日/周/月 K 线（时间范围查询）
GET /v1/market/kline?symbol=AAPL&period=1d&from=2026-01-01&to=2026-03-13&limit=500&cursor=

// 分钟级历史 K 线（指定日期，不支持 cursor 分页）
GET /v1/market/kline?symbol=AAPL&period=1min&date=2026-03-12
```

**period 枚举**: `1min | 5min | 15min | 30min | 60min | 1d | 1w | 1mo`

**分页规则**:
- `limit` 最大 500，默认 100
- `cursor` 为 Base64 编码的时间戳游标（不透明），`null` 表示已到末尾
- 分钟级（含 `date` 参数）不支持 cursor，返回当日全量（约 390 根）

**响应示例**:
```json
{
  "data": {
    "symbol": "AAPL",
    "period": "1d",
    "candles": [
      {
        "t": "2026-03-13T00:00:00Z",
        "o": "181.0000",
        "h": "183.5000",
        "l": "180.0000",
        "c": "182.5200",
        "v": 45678900,
        "turnover": "8327145600"
      },
      {
        "t": "2026-03-12T00:00:00Z",
        "o": "179.5000",
        "h": "181.8000",
        "l": "178.9000",
        "c": "181.2800",
        "v": 42100000,
        "turnover": "7633080000"
      }
    ],
    "next_cursor": "eyJ0IjoiMjAyNi0wMS0wMSJ9",
    "total": 52
  }
}
```

**错误**:
- `404`：数据源无该标的分钟历史（或日期超出保留范围）
- `400 INVALID_PERIOD`：period 不在枚举范围内

### 6.3 搜索

```
GET /v1/market/search?q=apple&market=US&limit=20

Authorization: Bearer <JWT>（可选）
limit 默认 10，最大 50
```

搜索支持：股票代码（精确/前缀）、英文公司名（前缀/包含）、中文公司名、拼音首字母前缀匹配。

**响应示例**:
```json
{
  "data": {
    "results": [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "name_zh": "苹果公司",
        "price": "182.5200",
        "change_pct": "0.68",
        "market": "US",
        "delayed": false
      }
    ],
    "total": 3
  }
}
```

### 6.4 热门/涨跌幅榜

```
GET /v1/market/movers?type=gainers|losers|hot&market=US&limit=20

limit 最大 50
```

**约束**: `gainers` 和 `losers` 仅包含当日成交量 > 100 万股的标的；常规交易时段（ET 09:30-16:00）实时更新，其余时段展示上一个交易日收盘时数据。

**响应示例**:
```json
{
  "data": {
    "type": "gainers",
    "market": "US",
    "items": [
      {
        "symbol": "NVDA",
        "name": "NVIDIA Corp.",
        "name_zh": "英伟达",
        "price": "875.0000",
        "change": "43.5000",
        "change_pct": "5.23",
        "volume": 89234567
      }
    ],
    "as_of": "2026-03-13T14:30:00.000Z"
  }
}
```

### 6.5 股票详情

```
GET /v1/market/stocks/{symbol}

Authorization: Bearer <JWT>（可选，影响 delayed 字段）
```

**响应示例**:
```json
{
  "data": {
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "name_zh": "苹果公司",
    "market": "US",
    "exchange": "NASDAQ",
    "sector": "Technology",
    "industry": "Consumer Electronics",
    "price": "182.5200",
    "change": "1.2400",
    "change_pct": "0.68",
    "open": "181.0000",
    "high": "183.5000",
    "low": "180.0000",
    "prev_close": "181.2800",
    "volume": 45678900,
    "turnover": "8327145600",
    "turnover_rate": "0.31",
    "bid": "182.5100",
    "ask": "182.5300",
    "market_cap": 2800000000000,
    "shares_outstanding": 14960000000,
    "pe_ratio": "28.50",
    "pb_ratio": "45.20",
    "eps": "6.43",
    "dividend_yield": "0.52",
    "week_52_high": "199.6200",
    "week_52_low": "124.1700",
    "avg_volume_10d": 58234567,
    "market_status": "REGULAR",
    "delayed": false,
    "updated_at": "2026-03-13T14:30:00.123Z"
  }
}
```

### 6.6 股票新闻

```
GET /v1/market/news/{symbol}?page=1&page_size=20

page_size 最大 50，默认 20
```

**响应示例**:
```json
{
  "data": {
    "symbol": "AAPL",
    "total": 45,
    "page": 1,
    "page_size": 20,
    "news": [
      {
        "id": "news_001",
        "title": "Apple Announces Record Quarter",
        "summary": "Apple reported record revenue of $119.6B...",
        "source": "Reuters",
        "image_url": "https://cdn.example.com/news/001.jpg",
        "url": "https://reuters.com/apple-q1",
        "lang": "en",
        "published_at": "2026-03-13T10:00:00Z"
      }
    ]
  }
}
```

### 6.7 财务数据

```
GET /v1/market/financials/{symbol}
```

**响应示例**:
```json
{
  "data": {
    "symbol": "AAPL",
    "next_earnings_date": "2026-04-28",
    "next_earnings_quarter": "Q2 2026",
    "latest": {
      "quarter": "Q1 2026",
      "report_date": "2026-01-28",
      "revenue": "119600000000",
      "net_income": "33900000000",
      "eps": "2.18",
      "revenue_growth": "12.50",
      "net_income_growth": "15.30"
    },
    "historical_quarters": [
      {
        "quarter": "Q4 2025",
        "report_date": "2025-10-30",
        "revenue": "94900000000",
        "net_income": "22900000000",
        "eps": "1.46",
        "revenue_growth": "6.00",
        "net_income_growth": "11.00"
      }
    ]
  }
}
```

注：金额类字段（revenue、net_income）使用字符串表示整数原始值（美元），客户端自行格式化为 "119.6B" 等显示形式。

### 6.8 Watchlist 管理

所有 Watchlist 接口要求 JWT 认证（访客返回 401）。

```
GET /v1/watchlist
Authorization: Bearer <JWT>
```

**响应示例**:
```json
{
  "data": {
    "symbols": ["AAPL", "TSLA", "NVDA"],
    "quotes": {
      "AAPL": { "price": "182.5200", "change_pct": "0.68", "..." : "..." }
    }
  }
}
```

```
POST /v1/watchlist
Authorization: Bearer <JWT>
Content-Type: application/json

{ "symbol": "AAPL" }
```

**幂等语义**: 标的已在自选列表则返回 200（非 409）。

**错误**:
- `404 SYMBOL_NOT_FOUND`：标的代码不存在
- `400 WATCHLIST_FULL`：已达 100 只上限

**响应示例**:
```json
{
  "data": {
    "symbol": "AAPL",
    "added_at": "2026-03-13T14:30:00.000Z"
  }
}
```

```
DELETE /v1/watchlist/{symbol}
Authorization: Bearer <JWT>
```

**幂等语义**: 标的不在列表时返回 200。

**响应示例**:
```json
{
  "data": {
    "symbol": "AAPL",
    "removed": true
  }
}
```

---

## 7. MySQL 数据模型

数据库名: `market_service`，字符集: `utf8mb4`，排序规则: `utf8mb4_unicode_ci`，`time_zone = '+00:00'`（所有 TIMESTAMP 存储 UTC）。

### 7.1 stocks — 股票基础信息

```sql
CREATE TABLE stocks (
    id                  BIGINT UNSIGNED AUTO_INCREMENT,
    symbol              VARCHAR(20)     NOT NULL,           -- 股票代码，美股 1-5 位大写字母
    market              VARCHAR(8)      NOT NULL,           -- 'US' / 'HK'
    exchange            VARCHAR(20)     NOT NULL DEFAULT '', -- 'NYSE' / 'NASDAQ' / 'HKEX'
    name                VARCHAR(255)    NOT NULL,           -- 英文公司名
    name_zh             VARCHAR(255)    NOT NULL DEFAULT '', -- 中文公司名
    pinyin_initials     VARCHAR(20)     NOT NULL DEFAULT '', -- 拼音首字母（如 "pg" 对应苹果）
    sector              VARCHAR(100)    NOT NULL DEFAULT '', -- 行业板块
    industry            VARCHAR(100)    NOT NULL DEFAULT '', -- 细分行业
    shares_outstanding  BIGINT UNSIGNED NOT NULL DEFAULT 0, -- 流通股本（股），用于换手率计算
    market_cap          BIGINT UNSIGNED NOT NULL DEFAULT 0, -- 市值（USD cents）
    pe_ratio            DECIMAL(12, 4)  NULL,               -- 市盈率 TTM
    pb_ratio            DECIMAL(12, 4)  NULL,               -- 市净率
    eps                 DECIMAL(12, 4)  NULL,               -- 近 4 季度摊薄 EPS
    dividend_yield      DECIMAL(8, 4)   NULL,               -- 股息收益率（%）
    week_52_high        DECIMAL(20, 4)  NOT NULL DEFAULT 0, -- 52 周最高价
    week_52_low         DECIMAL(20, 4)  NOT NULL DEFAULT 0, -- 52 周最低价
    avg_volume_10d      BIGINT UNSIGNED NOT NULL DEFAULT 0, -- 近 10 日均量
    is_active           TINYINT(1)      NOT NULL DEFAULT 1, -- 0=退市/停牌
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_symbol_market (symbol, market),
    INDEX idx_market_active (market, is_active),
    INDEX idx_pinyin (pinyin_initials),               -- 支持拼音首字母搜索
    FULLTEXT INDEX ft_name (name, name_zh)            -- 全文搜索（英文/中文名）
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**拼音首字母说明**:
- 股票入库时一次性计算写入 `pinyin_initials`
- 算法：对中文名每个汉字取声母（如 "苹果" → "pg"）
- 搜索时使用 `LIKE 'pg%'` 前缀匹配

### 7.2 quotes — 实时行情快照

```sql
-- 仅存储最新行情快照（非历史），每个标的只有一行（REPLACE INTO 更新）
CREATE TABLE quotes (
    id              BIGINT UNSIGNED AUTO_INCREMENT,
    symbol          VARCHAR(20)     NOT NULL,
    market          VARCHAR(8)      NOT NULL,
    last_price      DECIMAL(20, 4)  NOT NULL,
    bid_price       DECIMAL(20, 4)  NULL,
    ask_price       DECIMAL(20, 4)  NULL,
    open_price      DECIMAL(20, 4)  NULL,
    high_price      DECIMAL(20, 4)  NULL,
    low_price       DECIMAL(20, 4)  NULL,
    prev_close      DECIMAL(20, 4)  NULL,
    volume          BIGINT UNSIGNED NOT NULL DEFAULT 0,
    turnover        DECIMAL(24, 2)  NOT NULL DEFAULT 0,  -- 成交额
    change_amount   DECIMAL(20, 4)  NULL,                -- 涨跌额
    change_pct      DECIMAL(10, 4)  NULL,                -- 涨跌幅（百分比，如 0.6800）
    market_status   VARCHAR(16)     NOT NULL DEFAULT 'CLOSED',
    data_timestamp  TIMESTAMP(3)    NOT NULL,            -- 行情数据时间（UTC，毫秒精度）
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_symbol_market (symbol, market),
    INDEX idx_market_status (market, market_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

注：`quotes` 表作为 Redis 缓存的持久化备份，Redis 未命中时回退读取此表。实际高频写入走 Redis，MySQL 每分钟批量 UPSERT 一次。

### 7.3 klines — K 线历史数据

```sql
CREATE TABLE klines (
    id          BIGINT UNSIGNED AUTO_INCREMENT,
    symbol      VARCHAR(20)     NOT NULL,
    market      VARCHAR(8)      NOT NULL,
    period      VARCHAR(8)      NOT NULL,       -- '1min'/'5min'/'15min'/'30min'/'60min'/'1d'/'1w'/'1mo'
    open_time   TIMESTAMP       NOT NULL,       -- K 线起始时间（UTC）
    open        DECIMAL(20, 4)  NOT NULL,
    high        DECIMAL(20, 4)  NOT NULL,
    low         DECIMAL(20, 4)  NOT NULL,
    close       DECIMAL(20, 4)  NOT NULL,
    volume      BIGINT UNSIGNED NOT NULL DEFAULT 0,
    turnover    DECIMAL(24, 2)  NOT NULL DEFAULT 0,  -- 成交额
    trade_count INT UNSIGNED    NOT NULL DEFAULT 0,  -- 成交笔数
    PRIMARY KEY (id, open_time),
    UNIQUE KEY uk_kline (symbol, market, period, open_time),
    INDEX idx_kline_lookup (symbol, market, period, open_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  PARTITION BY RANGE (UNIX_TIMESTAMP(open_time)) (
    PARTITION p2026_01 VALUES LESS THAN (UNIX_TIMESTAMP('2026-02-01 00:00:00')),
    PARTITION p2026_02 VALUES LESS THAN (UNIX_TIMESTAMP('2026-03-01 00:00:00')),
    PARTITION p2026_03 VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION p2026_04 VALUES LESS THAN (UNIX_TIMESTAMP('2026-05-01 00:00:00')),
    PARTITION p2026_05 VALUES LESS THAN (UNIX_TIMESTAMP('2026-06-01 00:00:00')),
    PARTITION p2026_06 VALUES LESS THAN (UNIX_TIMESTAMP('2026-07-01 00:00:00')),
    PARTITION p2026_07 VALUES LESS THAN (UNIX_TIMESTAMP('2026-08-01 00:00:00')),
    PARTITION p2026_08 VALUES LESS THAN (UNIX_TIMESTAMP('2026-09-01 00:00:00')),
    PARTITION p2026_09 VALUES LESS THAN (UNIX_TIMESTAMP('2026-10-01 00:00:00')),
    PARTITION p2026_10 VALUES LESS THAN (UNIX_TIMESTAMP('2026-11-01 00:00:00')),
    PARTITION p2026_11 VALUES LESS THAN (UNIX_TIMESTAMP('2026-12-01 00:00:00')),
    PARTITION p2026_12 VALUES LESS THAN (UNIX_TIMESTAMP('2027-01-01 00:00:00')),
    PARTITION p_future  VALUES LESS THAN MAXVALUE
  );
```

**分区维护**: 每年底通过脚本新增下一年度的月分区，并将超出保留期（日线 2 年、分钟线 30 天）的旧分区 DROP（注意 DROP PARTITION 前需备份）。

**数据保留策略**:
- 分钟线（1min/5min/15min/30min/60min）: 保留最近 30 个交易日
- 日线（1d）: 保留近 2 年
- 周线（1w）: 保留近 5 年
- 月线（1mo）: 保留全历史

### 7.4 ticks — 逐笔成交

```sql
CREATE TABLE ticks (
    id          BIGINT UNSIGNED AUTO_INCREMENT,
    symbol      VARCHAR(20)     NOT NULL,
    market      VARCHAR(8)      NOT NULL,
    trade_id    VARCHAR(64)     NOT NULL DEFAULT '',
    price       DECIMAL(20, 4)  NOT NULL,
    volume      BIGINT UNSIGNED NOT NULL,
    side        VARCHAR(4)      NULL,       -- 'BUY' / 'SELL' / NULL（未知方向）
    trade_time  TIMESTAMP(3)    NOT NULL,   -- 成交时间（UTC，毫秒精度）
    PRIMARY KEY (id, trade_time),
    UNIQUE KEY uk_trade_id (trade_id, market),
    INDEX idx_ticks_lookup (symbol, market, trade_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  PARTITION BY RANGE (UNIX_TIMESTAMP(trade_time)) (
    PARTITION p2026_01 VALUES LESS THAN (UNIX_TIMESTAMP('2026-02-01 00:00:00')),
    PARTITION p2026_02 VALUES LESS THAN (UNIX_TIMESTAMP('2026-03-01 00:00:00')),
    PARTITION p2026_03 VALUES LESS THAN (UNIX_TIMESTAMP('2026-04-01 00:00:00')),
    PARTITION p2026_04 VALUES LESS THAN (UNIX_TIMESTAMP('2026-05-01 00:00:00')),
    PARTITION p2026_05 VALUES LESS THAN (UNIX_TIMESTAMP('2026-06-01 00:00:00')),
    PARTITION p_future  VALUES LESS THAN MAXVALUE
  );
```

**数据保留**: 在线保留 5 个交易日逐笔，超出部分归档到 S3（Parquet 格式），满足 SEC 5 年保留合规要求。

### 7.5 user_watchlist — 用户自选股

```sql
CREATE TABLE user_watchlist (
    id          BIGINT UNSIGNED AUTO_INCREMENT,
    user_id     CHAR(36)        NOT NULL,   -- UUID v4，对应 AMS 服务的 users.id
    symbol      VARCHAR(20)     NOT NULL,
    market      VARCHAR(8)      NOT NULL DEFAULT 'US',
    sort_order  INT UNSIGNED    NOT NULL DEFAULT 0,
    added_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_symbol (user_id, symbol),
    INDEX idx_user_order (user_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 幂等添加（应用层 INSERT 前先 COUNT 判断上限 100）
-- INSERT INTO user_watchlist (user_id, symbol, sort_order)
-- VALUES (?, ?, (SELECT COALESCE(MAX(sort_order), 0) + 1 FROM user_watchlist WHERE user_id = ?))
-- ON DUPLICATE KEY UPDATE id = id;  -- 已存在则静默忽略
```

**Watchlist 上限**: 每用户最多 100 只，应用层在 INSERT 前执行 `SELECT COUNT(*) WHERE user_id = ?` 检查，超出返回 `WATCHLIST_FULL`。

### 7.6 hot_searches — 热门搜索

```sql
CREATE TABLE hot_searches (
    id           BIGINT UNSIGNED AUTO_INCREMENT,
    symbol       VARCHAR(20)  NOT NULL,
    market       VARCHAR(8)   NOT NULL DEFAULT 'US',
    search_count INT UNSIGNED NOT NULL DEFAULT 0,
    `rank`       INT UNSIGNED NOT NULL DEFAULT 0,
    date         DATE         NOT NULL,          -- UTC 日期
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_symbol_date (symbol, market, date),
    INDEX idx_date_rank (date, `rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

热门搜索排名由 Admin Panel 或离线任务每日更新，`search_count` 通过 Redis HyperLogLog 统计后批量写入。

### 7.7 news — 新闻资讯

```sql
CREATE TABLE news (
    id           BIGINT UNSIGNED AUTO_INCREMENT,
    news_id      VARCHAR(128)    NOT NULL,          -- Polygon.io 返回的原始 news ID
    symbol       VARCHAR(20)     NOT NULL,
    market       VARCHAR(8)      NOT NULL DEFAULT 'US',
    title        VARCHAR(512)    NOT NULL,
    summary      TEXT            NULL,
    source       VARCHAR(128)    NOT NULL DEFAULT '',
    image_url    VARCHAR(512)    NOT NULL DEFAULT '',  -- 封面图 URL
    url          VARCHAR(512)    NOT NULL,
    lang         VARCHAR(8)      NOT NULL DEFAULT 'en', -- 语言，'en' / 'zh'
    published_at TIMESTAMP       NOT NULL,
    created_at   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_news_id (news_id),
    INDEX idx_symbol_time (symbol, published_at DESC),
    INDEX idx_published (published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 7.8 financials — 财务数据

```sql
CREATE TABLE financials (
    id                  BIGINT UNSIGNED AUTO_INCREMENT,
    symbol              VARCHAR(20)     NOT NULL,
    market              VARCHAR(8)      NOT NULL DEFAULT 'US',
    quarter             VARCHAR(16)     NOT NULL,   -- 如 'Q1 2026'
    report_date         DATE            NOT NULL,
    revenue             BIGINT          NULL,        -- 营收（美元分，整数）
    net_income          BIGINT          NULL,        -- 净利润（美元分，整数）
    eps                 DECIMAL(12, 4)  NULL,        -- EPS
    revenue_growth      DECIMAL(10, 4)  NULL,        -- 营收同比增长率（%）
    net_income_growth   DECIMAL(10, 4)  NULL,        -- 净利润同比增长率（%）
    next_earnings_date  DATE            NULL,        -- 下一次财报日期（预计）
    historical_quarters JSON            NULL,        -- 历史 4 季度数据（JSON Array）
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_symbol_quarter (symbol, market, quarter),
    INDEX idx_symbol (symbol, market),
    INDEX idx_report_date (report_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

`historical_quarters` JSON 示例:
```json
[
  {"quarter": "Q4 2025", "revenue": 94900000000, "net_income": 22900000000, "eps": "1.46"},
  {"quarter": "Q3 2025", "revenue": 85800000000, "net_income": 21400000000, "eps": "1.40"}
]
```

---

## 8. Redis 缓存设计

### 8.1 Key 体系

| Key 模式 | 数据结构 | TTL | 说明 |
|----------|----------|-----|------|
| `quote:US:{symbol}` | Hash | 60s（盘中）/ 1800s（收盘后 30min） | 实时行情快照，全字段 |
| `quote:US:{symbol}:delayed` | Hash | 1200s（20min 容量） | 访客延迟行情，从 RingBuffer 导出的最新延迟快照 |
| `depth:US:{symbol}:bid` | Sorted Set | 60s | 买盘，Score=价格，Member=量\|笔数 |
| `depth:US:{symbol}:ask` | Sorted Set | 60s | 卖盘，Score=价格，Member=量\|笔数 |
| `kline:US:{symbol}:{period}` | Sorted Set | 300s | K 线缓存，Score=open_time Unix sec，Member=JSON candle |
| `market:status:US` | String | 60s | 美股市场状态枚举 |
| `movers:US:gainers` | String（JSON） | 60s（盘中）/ 300s（盘外） | 涨幅榜 JSON |
| `movers:US:losers` | String（JSON） | 60s（盘中）/ 300s（盘外） | 跌幅榜 JSON |
| `movers:US:hot` | String（JSON） | 300s | 热门榜 JSON |
| `search:rank:US` | Sorted Set | 3600s | 热门搜索，Score=搜索次数 |
| `ws:token:blacklist:{jti}` | String | Token 剩余有效期 | JWT 撤销黑名单 |

### 8.2 行情 Hash 字段示例

```
HGETALL quote:US:AAPL
→
  last_price    "182.5200"
  bid_price     "182.5100"
  ask_price     "182.5300"
  open          "181.0000"
  high          "183.5000"
  low           "180.0000"
  prev_close    "181.2800"
  volume        "45678900"
  turnover      "8327145600"
  turnover_rate "0.31"
  change        "1.2400"
  change_pct    "0.68"
  market_status "REGULAR"
  ts            "2026-03-13T14:30:00.123Z"
```

### 8.3 K 线缓存说明

K 线 Sorted Set 保留最近 500 根，超出时 `ZREMRANGEBYRANK` 删除最旧条目。每次 KlineAggregator 完成一根 K 线时：
1. `ZADD kline:US:AAPL:1d <unix_sec> <json_candle>` 写入 Redis
2. 当 K 线为实时更新中（is_final=false）时，更新同一 Score 的 Member（覆盖当前未完成 K 线）
3. 当 is_final=true 时，同时异步写入 MySQL klines 表

### 8.4 Redis Pub/Sub — WebSocket 内部广播

WebSocket Gateway 与处理引擎之间通过 Redis Pub/Sub 解耦（单机部署时可退化为 Go channel）：

```
Channel: md:US:{symbol}        → 发布 Quote 更新（JSON 序列化）
Channel: md:status:US          → 发布市场状态变更
```

WebSocket Gateway 节点在启动时订阅所有客户端已订阅标的对应的 Pub/Sub Channel，收到消息后分发给本节点上的连接。多节点部署时，每个节点独立订阅，消息复制广播。

---

## 9. Kafka Topic 设计

Phase 1 Kafka 主要用于向内部服务（Trading Engine、Admin Panel、通知服务）分发实时行情事件。

### 9.1 Topic 清单

| Topic | 分区数 | 保留时间 | 序列化 | 用途 |
|-------|--------|----------|--------|------|
| `market-data.quotes.us` | 32 | 7 天 | Protobuf | 美股 Level 1 行情更新 |
| `market-data.quotes.hk` | 16 | 7 天 | Protobuf | 港股 Level 1（Phase 2） |
| `market-data.depth.us` | 16 | 1 天 | Protobuf | 美股盘口深度 |
| `market-data.trades.us` | 32 | 7 天 | Protobuf | 美股逐笔成交 |
| `market-data.klines` | 8 | 7 天 | Protobuf | 已完成 K 线（所有周期） |
| `market-data.market.status` | 1 | 30 天 | JSON | 市场状态变更事件 |

### 9.2 分区策略

```go
// 按 symbol hash 分区，保证同一标的消息有序
func partitionKey(symbol string) []byte {
    return []byte(symbol)
}
```

### 9.3 Consumer Group

| Consumer Group | 消费 Topic | 用途 |
|----------------|-----------|------|
| `trading-engine` | `market-data.quotes.us` | 实时报价用于订单价格校验 |
| `risk-service` | `market-data.quotes.us`, `market-data.trades.us` | 实时风险计算 |
| `kline-store` | `market-data.klines` | K 线持久化写入 MySQL |
| `notification-service` | `market-data.quotes.us` | 价格提醒触发判断 |
| `admin-panel` | `market-data.market.status` | 市场状态监控面板 |

### 9.4 市场状态事件格式

```json
{
  "event": "market_status_changed",
  "market": "US",
  "status": "REGULAR",
  "previous_status": "PRE_MARKET",
  "effective_at": "2026-03-13T13:30:00.000Z",
  "session_date": "2026-03-13"
}
```

---

## 10. 关键设计决策

### 10.1 性能优化

| 优化手段 | 应用位置 | 预期收益 |
|----------|----------|---------|
| Lock-free Ring Buffer（8192 槽） | Feed Handler 输出 | 消除写入热锁，提升吞吐 |
| COW（Copy-On-Write）读取 | LocalQuoteCache | 读操作零竞争 |
| sync.Pool 复用消息对象 | 处理引擎 | 降低 GC 压力 |
| Protocol Buffers 序列化 | Kafka 消息 / gRPC | 比 JSON 快 5-10x，体积小 60% |
| WebSocket 写串行化 per conn | WebSocket 推送 | 避免并发写 panic，简化逻辑 |
| 增量推送（仅推变化字段） | WebSocket 行情推送 | 减少 70%+ 带宽 |
| permessage-deflate 压缩 | WebSocket 帧 | 压缩比 60-80% |
| Redis Pipeline 批量写 | 行情快照写入 Redis | 减少 RTT，提升写吞吐 |
| MySQL UPSERT 批量操作 | klines 持久化写入 | 每分钟批量而非逐条写入 |
| Redis Sorted Set for K 线 | K 线缓存 | 范围查询 O(log N)，P99 < 5ms |

### 10.2 高可用设计

**数据源层**:
- Polygon.io（主） + IEX Cloud（备），心跳超时 3s 自动切换
- 切换时从 Redis 快照恢复 Last Known Price，避免空白期
- 切换成功后 Prometheus 触发告警，人工确认主链路恢复后手动切回

**处理引擎层**:
- Phase 1 单实例（模块化单体），通过进程监控（systemd/K8s liveness probe）自动重启
- 重启恢复策略：从 Redis 读取最新快照恢复 LocalQuoteCache，延迟 DelayedQuoteRingBuffer 重建（需 15 分钟积累）

**WebSocket 层**:
- 水平扩展，多实例无状态（订阅状态存储于内存，客户端断连后重新 auth + subscribe）
- 客户端实现指数退避重连（初始 1s，最大 30s，抖动 ±50%）

**Redis 层**:
- Redis Sentinel 主从配置（1 主 2 从 + 3 哨兵）
- 主从切换 < 10s；切换期间 WebSocket Gateway 使用 LocalQuoteCache 兜底

**MySQL 层**:
- MySQL 主从复制（1 主 1 从）
- 写入走主库，K 线历史查询走从库
- 主库宕机：从库提升，K 线写入短暂中断（< 1 分钟），K 线查询切主库

### 10.3 容灾场景处理

| 场景 | 策略 | RTO |
|------|------|-----|
| Polygon.io 断连 | 立即切换 IEX Cloud | < 3s |
| Feed Handler 进程崩溃 | K8s/systemd 自动重启 + Redis 快照恢复 | < 5s |
| Redis 主节点故障 | Sentinel 自动切换从库为主 | < 10s |
| MySQL 主库故障 | 从库提升，K 线写入中断 | < 60s |
| WebSocket 节点宕机 | 客户端断连后自动重连其他节点 | < 3s（客户端重连） |
| 全量行情中断（数据源全部不可用） | 展示最后已知价格，附 `stale: true` 标记 | 立即 |
| DelayedQuoteRingBuffer 冷启动 | 访客订阅后显示"数据准备中"，15 分钟后正常提供延迟行情 | 15min 填充期 |

### 10.4 数据精度保证

- 所有价格使用 `shopspring/decimal.Decimal`（Go），禁止 `float64`
- JSON 序列化/反序列化时使用字符串传递价格（`"182.5200"`）
- MySQL DECIMAL(20,4) 存储，避免浮点误差
- 换手率计算：`volume / shares_outstanding`，使用整数除法后保留 2 位小数
- 涨跌幅计算：`(last - prev_close) / prev_close * 100`，保留 2 位小数

### 10.5 Phase 2 存储演进规划（参考）

Phase 1 使用 MySQL 8.0 按月分区存储 K 线和逐笔数据。随数据量增长，Phase 2 评估迁移：
- **K 线**: 迁移至 TimescaleDB（hypertable + 连续聚合，自动压缩）
- **逐笔**: 超过 90 天的数据归档至 S3（Parquet），通过 Athena 查询
- 迁移不影响 API 接口层（Repository 模式抽象存储后端）

---

## 11. 监控告警

### 11.1 Prometheus 指标体系

```yaml
# Feed Handler
feed_handler_messages_total{source, market, type}          # 消息计数（Counter）
feed_handler_message_lag_seconds{source, quantile}         # 处理延迟分布（Histogram）
feed_handler_gaps_total{source}                            # 序列号缺口次数（Counter）
feed_handler_reconnects_total{source, reason}              # 重连次数（Counter）
feed_handler_connected{source}                             # 连接状态 0/1（Gauge）
feed_handler_last_message_age_seconds{source}              # 距上次消息时间（Gauge）

# 处理引擎
processing_throughput_messages_per_second{type}            # 处理吞吐量（Gauge）
processing_validation_failures_total{level, reason}        # 校验失败次数（Counter）
processing_kline_aggregation_lag_seconds{interval}         # K 线聚合延迟（Histogram）

# WebSocket Gateway
ws_connections_active{user_type}                           # 活跃连接数（Gauge）
ws_subscriptions_active                                    # 活跃订阅数（Gauge）
ws_messages_sent_total{user_type}                         # 推送消息量（Counter）
ws_push_latency_seconds{user_type, quantile}              # 推送延迟（Histogram）
ws_auth_failures_total{reason}                             # 认证失败次数（Counter）
ws_slow_consumer_drops_total                               # 慢消费者丢弃帧数（Counter）

# Redis
redis_quote_update_latency_seconds{quantile}              # 行情写入 Redis 延迟（Histogram）
redis_cache_hit_ratio{key_type}                           # 缓存命中率（Gauge）

# DelayedQuote Ring Buffer
delayed_buffer_fill_ratio                                  # RingBuffer 填充率 0-1（Gauge）
delayed_buffer_write_total                                 # 快照写入次数（Counter）

# REST API
http_request_duration_seconds{method, path, status}       # HTTP 延迟（Histogram）
http_requests_total{method, path, status}                  # HTTP 请求量（Counter）

# Kafka
kafka_producer_send_total{topic}                           # 消息发送量（Counter）
kafka_producer_errors_total{topic}                         # 发送失败量（Counter）
```

### 11.2 告警规则

| 告警名称 | 条件 | 级别 | 处理策略 |
|----------|------|------|---------|
| FeedHandlerDisconnected | `feed_handler_connected == 0` 持续 10s | Critical | 立即切换备用数据源 + PagerDuty |
| NoRecentMessages | `feed_handler_last_message_age_seconds > 30`（盘中） | Critical | 检查数据源连接，触发重连 |
| HighProcessingLatency | `processing_kline_aggregation_lag_seconds{p99} > 1` | Warning | 检查处理引擎负载 |
| WebSocketPushLatencyHigh | `ws_push_latency_seconds{p99, registered} > 0.5` | Critical | 检查 Redis Pub/Sub 延迟 |
| GuestDelayBufferInsufficient | `delayed_buffer_fill_ratio < 0.5`（服务运行 > 20min） | Warning | 可能丢失快照写入，检查写入 goroutine |
| RedisCacheHitLow | `redis_cache_hit_ratio{key_type="quote"} < 0.9` | Warning | 检查 Redis 容量和 TTL 配置 |
| DataGapDetected | `rate(feed_handler_gaps_total[5m]) > 0`（盘中） | Warning | 可能数据缺失，触发快照恢复 |
| SlowConsumerDrops | `rate(ws_slow_consumer_drops_total[1m]) > 100` | Warning | 客户端网络差或服务端负载高 |
| MySQLWriteLatencyHigh | klines 批量写入 P99 > 1s | Warning | 检查 MySQL 主库负载 |

---

## 12. 交易时段与市场日历

### 12.1 美股交易时段（Phase 1）

```go
// internal/calendar/calendar.go

const USTimezone = "America/New_York" // ET（Eastern Time）

// MarketSession 交易时段枚举（与 Protobuf MarketStatus 对应）
type MarketSession string

const (
    SessionPreMarket  MarketSession = "PRE_MARKET"  // 04:00-09:30 ET
    SessionRegular    MarketSession = "REGULAR"      // 09:30-16:00 ET
    SessionAfterHours MarketSession = "AFTER_HOURS"  // 16:00-20:00 ET
    SessionClosed     MarketSession = "CLOSED"        // 其余时间
    SessionHalted     MarketSession = "HALTED"        // 交易暂停（个股或全市场）
)

// USMarketSessions 美股各时段时间区间
var USMarketSessions = []SessionDef{
    {Name: SessionPreMarket,  StartHHMM: "04:00", EndHHMM: "09:30"},
    {Name: SessionRegular,    StartHHMM: "09:30", EndHHMM: "16:00"},
    {Name: SessionAfterHours, StartHHMM: "16:00", EndHHMM: "20:00"},
}

// GetCurrentSession 根据当前 ET 时间判断所处时段
func GetCurrentSession(now time.Time) MarketSession {
    et, _ := time.LoadLocation(USTimezone)
    etNow := now.In(et)

    // 节假日判断（从 MarketCalendar 数据源读取）
    if IsUSMarketHoliday(etNow) {
        return SessionClosed
    }

    // 周末
    wd := etNow.Weekday()
    if wd == time.Saturday || wd == time.Sunday {
        return SessionClosed
    }

    hhmm := etNow.Hour()*100 + etNow.Minute()
    switch {
    case hhmm >= 400 && hhmm < 930:
        return SessionPreMarket
    case hhmm >= 930 && hhmm < 1600:
        return SessionRegular
    case hhmm >= 1600 && hhmm < 2000:
        return SessionAfterHours
    default:
        return SessionClosed
    }
}
```

### 12.2 港股交易时段（Phase 2 预留）

```go
var HKMarketSessions = []SessionDef{
    {Name: "PRE_OPENING",     StartHHMM: "09:00", EndHHMM: "09:30", TZ: "Asia/Hong_Kong"},
    {Name: "MORNING",         StartHHMM: "09:30", EndHHMM: "12:00", TZ: "Asia/Hong_Kong"},
    {Name: "LUNCH_BREAK",     StartHHMM: "12:00", EndHHMM: "13:00", TZ: "Asia/Hong_Kong"},
    {Name: "AFTERNOON",       StartHHMM: "13:00", EndHHMM: "16:00", TZ: "Asia/Hong_Kong"},
    {Name: "CLOSING_AUCTION", StartHHMM: "16:00", EndHHMM: "16:10", TZ: "Asia/Hong_Kong"},
}
```

### 12.3 美股市场日历维护

- 节假日列表从 NYSE 官网 / Polygon.io API 获取，每年初批量写入 MySQL `market_holidays` 表
- 临时停市（如飓风、国家哀悼日）通过 Admin Panel 手动维护
- Feed Handler 收到 Polygon.io 发送的市场状态变更事件（`AM` - After Market Open / `PM` - Post Market Open / `X` - Closed）时，同步更新 Redis `market:status:US` 并发布 Kafka `market-data.market.status` 事件

### 12.4 K 线聚合的时段边界处理

- **分钟线**: 仅在常规时段（ET 09:30-16:00）聚合，盘前/盘后不产生分钟线
- **日线 open_time**: 取当日常规时段开盘时刻（ET 09:30 转 UTC = 13:30 / 14:30，夏令时不同）
- **周线 open_time**: 取当周第一个交易日开盘时刻
- **月线 open_time**: 取当月第一个交易日开盘时刻

---

## 13. Phase 1 部署方案

### 13.1 服务部署拓扑

Phase 1 采用**模块化单体**方式，所有模块（Feed Handler、Processing Engine、WebSocket Gateway、REST API）在同一个 Go 进程内运行，通过内部 Go channel 和共享内存通信，降低运维复杂度。

```
┌─────────────────── Kubernetes Cluster ───────────────────────────┐
│  Namespace: market-data                                           │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  Deployment: market-data-server                            │   │
│  │  replicas: 2（主备，active-standby）                       │   │
│  │  resources: 4 CPU / 8 GB RAM（含 DelayedQuoteRingBuffer）  │   │
│  │                                                            │   │
│  │  Container: market-data                                    │   │
│  │    - Feed Handler（Polygon.io 主连接 + IEX 备用）          │   │
│  │    - Processing Engine（Normalizer / Aggregator / Validator）  │
│  │    - LocalQuoteCache + DelayedQuoteRingBuffer              │   │
│  │    - WebSocket Gateway（:8080/ws/market）                  │   │
│  │    - REST API Server（:8080/v1/market + /v1/watchlist）    │   │
│  │    - Kafka Producer                                        │   │
│  │    - MySQL Writer（K 线/逐笔批量写入）                     │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  StatefulSets                                              │   │
│  │  redis-sentinel: 1 主 2 从 3 哨兵                         │   │
│  │  kafka: 3 Brokers（kraft 模式，无 Zookeeper）              │   │
│  │  mysql: 1 主 1 从（主从复制）                              │   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  Ingress（Nginx）                                          │   │
│  │  wss://api.broker.com/ws/market   → market-data-server:8080   │
│  │  https://api.broker.com/v1/market → market-data-server:8080   │
│  └───────────────────────────────────────────────────────────┘   │
│                                                                   │
│  HPA: CPU > 60% → 自动扩容到最多 4 实例（WebSocket 有状态，     │
│       扩容时客户端会断连重连，需注意扩容时机选在盘后）            │
└───────────────────────────────────────────────────────────────────┘
```

### 13.2 主备切换策略

Phase 1 的双实例采用 Active-Standby 模式，通过 Redis 分布式锁（`SETNX market-data:leader <instance_id> PX 10000`）实现 Leader Election：
- Active 实例持有 Leader Lock，负责 Feed Handler 连接和行情处理
- Standby 实例监控 Lock，Lock 过期后抢占，接管 Feed Handler 连接
- 两个实例均提供 REST API 和 WebSocket 服务（WebSocket 连接在 Standby 切换为 Active 后开始推送行情）

### 13.3 配置管理

核心配置项（通过 K8s ConfigMap + Secret 管理）：

```yaml
# config/config.yaml（非敏感配置）
feed:
  us:
    primary: polygon
    secondary: iex
    switch_threshold_sec: 3
    heartbeat_interval_sec: 10

websocket:
  auth_timeout_sec: 5
  ping_interval_sec: 30
  max_symbols_per_conn: 50
  guest_push_interval_sec: 5
  send_buffer_size: 256

delayed_quote:
  ring_buffer_capacity: 20      # 分钟数
  snapshot_interval_sec: 60
  guest_delay_minutes: 15

cache:
  quote_ttl_active_sec: 60     # 盘中
  quote_ttl_closed_sec: 1800   # 收盘后 30 分钟

kline:
  redis_max_candles: 500        # 每个 symbol/period 缓存最近 500 根 K 线
  mysql_batch_size: 100         # 批量写入 K 线条数

# 敏感配置从 K8s Secret 注入环境变量
# POLYGON_API_KEY
# IEX_API_KEY
# REDIS_URL
# MYSQL_DSN
# JWT_RS256_PUBLIC_KEY
```

### 13.4 健康检查与优雅停机

```
GET /health/live    → Liveness Probe（进程存活）
GET /health/ready   → Readiness Probe（连接已建立、Redis 可达）

优雅停机流程（SIGTERM）：
  1. 停止接受新 WebSocket 连接
  2. 停止 Feed Handler 订阅
  3. 等待 in-flight 消息处理完成（最长 10s）
  4. 批量 Flush 未写入的 K 线到 MySQL
  5. 关闭现有 WebSocket 连接（发送 Close Frame）
  6. 进程退出
```

### 13.5 Phase 2 微服务拆分规划

当 Phase 1 达到瓶颈时，按以下方向拆分：

| 服务 | 职责 | 扩展方式 |
|------|------|---------|
| `feed-handler` | 数据源接入 | 按市场独立部署 |
| `processing-engine` | 标准化/聚合/校验 | 主备 |
| `ws-gateway` | WebSocket 分发 | 水平扩展（无状态） |
| `market-api` | REST API | 水平扩展 |
| `kline-store` | K 线持久化 | 单实例（批量写） |

拆分后各服务间通过 Kafka 事件 + gRPC 通信，Repository 层无需改动（MySQL/Redis 连接信息调整）。

---

## 附录 A — 标的代码规范

| 市场 | 格式 | 示例 | 验证规则 |
|------|------|------|---------|
| 美股 NYSE/NASDAQ | 1-5 位大写字母 | `AAPL`, `TSLA`, `BRK.A` | `^[A-Z]{1,5}(\.[A-Z])?$` |
| 港股 HKEX | 4-5 位数字 + ".HK" | `0700.HK`, `9988.HK` | `^\d{4,5}\.HK$` |
| 美股期权 | OCC 格式 | `AAPL260320C00182500` | OCC 格式验证 |

内部统一标识符示例：`US:AAPL`、`HK:0700.HK`。

---

## 附录 B — 错误码体系

| HTTP 状态码 | 错误码 | 说明 |
|------------|--------|------|
| 400 | `TOO_MANY_SYMBOLS` | symbols 超过 50 个 |
| 400 | `INVALID_PERIOD` | K 线周期不在枚举范围 |
| 400 | `INVALID_SYMBOL` | 标的代码格式错误 |
| 400 | `WATCHLIST_FULL` | 自选股超过 100 只 |
| 401 | `UNAUTHORIZED` | 未提供或无效 JWT |
| 401 | `TOKEN_EXPIRED` | JWT 已过期 |
| 404 | `SYMBOL_NOT_FOUND` | 标的不存在 |
| 404 | `DATA_NOT_AVAILABLE` | 所请求历史数据不存在 |
| 429 | `RATE_LIMITED` | 请求频率超限（100 req/s per IP） |
| 500 | `INTERNAL_ERROR` | 服务内部错误 |
| 503 | `DATA_SOURCE_UNAVAILABLE` | 上游数据源不可用 |

---

*文档版本 v2.0 | 日期 2026-03-14 | 替代 v1.0（2026-03-07）*
*关联 PRD: mobile/docs/prd/03-market.md v1.1（2026-03-13）*
