---
type: architecture-spec
version: v2.0
date: 2026-03-14
supersedes: data-flow v1.0
surface_prd: mobile/docs/prd/03-market.md
status: ACTIVE
---

# 行情数据流架构

## 概述

本文档描述 Market Data Service 的完整数据流：从外部行情源接入、处理与标准化，到 Redis 缓存、WebSocket 双轨推送（注册用户实时 / 访客延迟），以及 Kafka 异步分发和 K 线落盘的全链路架构。

---

## 主数据流图

```
[Polygon.io WebSocket]
        |
        | 实时 tick 流（US 市场）
        v
[Feed Handler - US]
        |
        | Normalizer → RawMessage (内部标准化格式)
        v
[Processing Engine]
        |
        +-- Validator（价格异常检测、量纲校验）
        +-- KlineAggregator（实时聚合当前 K 线槽）
        |
        | 标准化 Quote / Trade
        v
[Redis Pub/Sub Channel: quote-updates:{symbol}]
        |
        +---------------------------------------------+
        |                                             |
        v                                             |
[Redis Quote Cache]                                  |
  quote:US:{symbol}  ← 同步写入                      |
  quote:HK:{symbol}                                  |
  orderbook:US:{symbol}                              |
  market:status:{market}                             |
        |                                             |
        | （异步落盘）                                  |
        v                                             |
[Kafka: market-data.quotes.us]                       |
        |                                             |
        +-- [market-data-store consumer]              |
        |       └→ MySQL klines 表（K 线落盘）         |
        |       └→ MySQL ticks 表（Tick 落盘）         |
        |                                             |
        +-- [trading-engine consumer]                 |
                └→ 实时价格验证（pre-trade risk）      |
                                                      |
[WebSocket Gateway] ←─────────────────────────────────+
        |              订阅 Redis Pub/Sub，接收更新
        |
        +-- [LiveQuoteGroup]（注册用户连接）
        |       └→ 立即推送，delayed=false
        |          端到端延迟 < 500ms P99
        |
        └-- [DelayedQuoteGroup]（访客连接）
                |
                v
        [DelayedQuoteRingBuffer]（进程内滑动窗口）
                └→ 每 5 秒推送 T-15min 快照，delayed=true
```

---

## 访客延迟数据流（双轨推送设计）

### DelayedQuoteRingBuffer 结构

`DelayedQuoteRingBuffer` 是一个进程内的滑动时间窗口，无需持久化：

```
时间槽索引（每分钟一槽，共 20 槽）:
  [0]=T-20min  [1]=T-19min  ...  [14]=T-6min  [15]=T-5min  ...  [19]=T-1min  [20]=T-0

  访客读取位置: 索引 15（T-15min 对应时间槽）
```

运作机制：

1. **写入**：每分钟定时任务从 `Redis quote:US:{symbol}` 全量读取活跃 symbols 的快照，写入 RingBuffer 当前槽（T-0），旧槽自动淘汰
2. **读取**：访客推送协程每 5 秒取 T-15min 槽的快照，批量推送给所有 `DelayedQuoteGroup` 连接
3. **订阅时快照**：访客发送 subscribe 时，立即从 T-15min 槽读取并附在 `subscribe_ack.snapshots` 中返回（`delayed=true`）

### 内存估算

| 场景 | 活跃 symbols | 时间槽数 | 单条字节 | 总内存 |
|------|-------------|---------|---------|--------|
| 典型（热门美股） | 1,000 | 20 | ~200 B | 4 MB |
| 极端（全市场） | 8,000 | 20 | ~200 B | 32 MB |

32 MB 完全可接受，不引入外部持久化依赖。

### 访客 → 注册用户切换（reauth）

```
访客发送 reauth（携带有效 JWT）
        |
        v
WebSocket Gateway 验证 Token
        |
        v
将该连接从 DelayedQuoteGroup 移至 LiveQuoteGroup
        |
        v
立即读取 Redis quote:{market}:{symbol} 实时快照
        |
        v
推送当前实时快照（delayed=false），后续进入 tick 级推送
```

---

## HK 市场数据流

```
[HKEX OMD-C Feed]
        |
        | 二进制协议解码
        v
[Feed Handler - HK]
        |
        | Normalizer → RawMessage
        v
（与 US 数据流汇合，进入同一 Processing Engine）
```

Redis Key 命名：`quote:HK:{symbol}`（如 `quote:HK:0700.HK`）

---

## Redis Key 规范

| Key 模式 | 内容 | TTL |
|----------|------|-----|
| `quote:US:{symbol}` | 最新行情快照（JSON/Hash） | 收市后 30 分钟 |
| `quote:HK:{symbol}` | 最新行情快照（JSON/Hash） | 收市后 30 分钟 |
| `orderbook:US:{symbol}` | 深度行情（Sorted Set） | 收市后 30 分钟 |
| `orderbook:HK:{symbol}` | 深度行情（Sorted Set） | 收市后 30 分钟 |
| `market:status:US` | 市场状态（PRE_OPEN/OPEN/CLOSED/HALTED） | 无 TTL，事件驱动更新 |
| `market:status:HK` | 市场状态 | 无 TTL，事件驱动更新 |

---

## Kafka Topic 配置

| Topic | 分区策略 | 消费者组 | 用途 |
|-------|---------|---------|------|
| `market-data.quotes.us` | 按 symbol hash 分区 | `market-data-store`, `trading-engine`, `analytics` | US 实时行情分发 |
| `market-data.quotes.hk` | 按 symbol hash 分区 | `market-data-store`, `trading-engine`, `analytics` | HK 实时行情分发 |
| `market-data.trades.us` | 按 symbol hash 分区 | `market-data-store` | US 逐笔成交落盘 |
| `market-data.trades.hk` | 按 symbol hash 分区 | `market-data-store` | HK 逐笔成交落盘 |
| `market-data.klines.us` | 按 interval+symbol | `admin-panel` | US K 线事件（Admin 图表） |
| `market-data.klines.hk` | 按 interval+symbol | `admin-panel` | HK K 线事件（Admin 图表） |
| `market-data.status` | 单分区 | `all-services` | 开闭市 / HALT 广播 |

### Kafka 消息格式（market-data.quotes.*）

所有价格字段为 string 类型，时间戳为 ISO 8601 字符串：

```json
{
  "symbol": "AAPL",
  "market": "US",
  "price": "182.5200",
  "change": "1.2400",
  "change_pct": "0.68",
  "volume": 45678900,
  "bid": "182.5100",
  "ask": "182.5300",
  "market_status": "REGULAR",
  "timestamp": "2026-03-13T14:30:00.123Z"
}
```

---

## K 线聚合流

```
[Processing Engine - KlineAggregator]
        |
        | 实时写入当前 K 线槽（内存）
        | 支持时间框架：1m / 5m / 15m / 30m / 1h / 4h / 1D / 1W / 1M
        v
[K 线槽关闭（时间边界触发）]
        |
        +-- 推送到 Kafka: market-data.klines.{us|hk}
        |
        +-- 异步写入 MySQL: klines 表（按 open_time 分区）
        |
        v
[REST API: GET /api/v1/kline]
        |
        +-- 近期数据：从 MySQL 分区表读取
        +-- 当前未完成 K 线：从内存 KlineAggregator 读取实时槽
```

---

## Mock vs 生产数据源切换

### 配置文件（config/config.yaml）

```yaml
# 数据源选择：mock | polygon | kafka
data_source: mock

# 开发环境：留空 Kafka brokers，自动启用 MockPusher
kafka:
  brokers: []
  topics:
    quotes_us: market-data.quotes.us
    quotes_hk: market-data.quotes.hk
    trades_us: market-data.trades.us
    trades_hk: market-data.trades.hk
    status: market-data.status
  group_id: market-data-service

# 生产环境：配置 Kafka brokers
# kafka:
#   brokers:
#     - kafka-1.broker.com:9092
#     - kafka-2.broker.com:9092
#     - kafka-3.broker.com:9092

polygon:
  api_key: ""            # 留空时 MockPusher 自动激活
  ws_url: wss://socket.polygon.io/stocks
```

### 启动逻辑（cmd/server/main.go）

```go
switch cfg.DataSource {
case "polygon":
    // 生产：Polygon.io WebSocket Feed Handler
    feedHandler := polygon.NewFeedHandler(cfg.Polygon, processingEngine)
    go feedHandler.Start(ctx)
case "kafka":
    // 生产备选：从 Kafka 消费行情
    consumer := kafka.NewConsumer(cfg.Kafka, processingEngine)
    go consumer.Start(ctx)
default: // "mock"
    // 开发：MockPusher 从 MySQL 读取 + 随机波动
    mockPusher := websocket.NewMockPusher(wsHub, db)
    mockPusher.Start()
}
```

### 三种模式对比

| 维度 | mock | polygon | kafka |
|------|------|---------|-------|
| 适用场景 | 本地开发 / APP 联调 | 生产（直连数据源） | 生产（解耦架构） |
| 数据来源 | MySQL 初始数据 + 随机波动 | Polygon.io WebSocket | Kafka 消费者组 |
| 延迟 | 模拟（每秒推送） | < 100ms（实时） | < 100ms（At-least-once） |
| 需要外部依赖 | 仅 MySQL | Polygon API Key | Kafka 集群 |
| 访客延迟模拟 | 简化：当前快照 -15min | DelayedQuoteRingBuffer | DelayedQuoteRingBuffer |

---

## 性能指标

| 指标 | 目标值 |
|------|--------|
| Feed → Redis 延迟 (P99) | < 5ms |
| Redis → WebSocket 延迟 (P99) | < 10ms |
| 端到端（Feed → 客户端）延迟 (P99) | < 500ms |
| 并发 WebSocket 连接数 | 10,000+ |
| 行情吞吐量 | 50,000+ updates/sec |
| Kafka 消费吞吐量 | 10,000+ msg/s |
| K 线查询延迟 (P99) | < 50ms |
| 系统可用性（交易时段） | 99.99% |

---

## 故障切换

### Feed Handler 主备切换

- 每个市场配置主 Feed + 备用 Feed（冷备）
- 主 Feed 断连后，30 秒内自动切换至备用 Feed
- 切换事件写入 `market-data.status` Kafka topic，通知下游服务

### Redis 缓存雪崩防护

- quote key 的 TTL 加随机 jitter（±60s），防止大量 key 同时过期
- 缓存穿透：symbol 不存在时返回空对象并设 10s 短 TTL，不透传到数据库

### Kafka 消费失败处理

- 消费失败重试：指数退避，最多 3 次
- 超过重试次数：发送到 Dead Letter Topic（`market-data.dlq`），并告警
- 延迟超过 5 秒：触发 Prometheus 告警，数据标记 `stale=true` 推给客户端

---

## 历史数据初始化（冷启动）

> 详细规范见 `market-data-system.md` §14

### 启动时序

```
服务首次部署
      │
      ├─① 检查 MySQL klines 表是否为空
      │         是 → 触发全量回填任务（后台异步）
      │         否 → 检查最新 K 线时间，补填缺口
      │
      ├─② 优先回填 TOP 100 热门股票日线（约 30 秒完成）
      │         完成后 → HTTP 服务开放，可响应请求
      │
      ├─③ 后台继续回填全市场 ~8000 只股票（约 4 分钟，付费计划）
      │
      └─④ 订阅 Polygon WebSocket AM.* 事件，盘中实时续接分钟线
```

### Polygon 历史数据速率限制

| 计划 | 速率 | 回填 8000 只日线耗时 |
|------|------|-------------------|
| 免费 | 5 req/min | ~80 分钟 |
| 付费（Starter） | 100 req/min | ~4 分钟 |
| 付费（高级） | unlimited | < 1 分钟 |

### 分钟线按需加载（用户触发）

```
用户访问股票详情页
      │
      ├─ Redis 中有当日分钟线缓存？
      │         是 → 直接返回
      │         否 → 触发按需回填
      │
      └─ 按需回填：
             GET /v2/aggs/ticker/{symbol}/range/1/minute/{today}/{today}
                 ?adjusted=true&limit=500
             写入 MySQL klines（period='1min'）
             写入 Redis kline:US:{symbol}:1min（TTL 300s）
```

### 数据缺口填补规则

| 缺口原因 | 处理方式 |
|---------|---------|
| NYSE 节假日 | 维护交易日历，跳过非交易日，不生成假 K 线 |
| 临时停牌（LULD Halt） | 停牌期间标记 `halted=true`，不 forward-fill |
| 服务中断恢复 | 从 checkpoint 续传，补齐中断期间数据 |
| 新股上市前 | 无数据，从上市日开始 |
