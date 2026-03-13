# 实时行情数据流架构

## 数据源选择

### 开发/测试环境
**Mock 推送器** (`mock_pusher.go`)
- 从 MySQL 读取初始数据
- 模拟价格波动
- 适合 APP 联调测试

### 生产环境
**Kafka 消费者** (`kafka/consumer.go`)
- 从 Kafka Topic 消费实时行情
- 高吞吐、低延迟
- 支持水平扩展

## 数据流架构

```
[Polygon.io API]
       ↓
[Data Collector Service]  ← 采集服务（独立部署）
       ↓
[Kafka Topic: market.quotes]
       ↓
[Market Service - Kafka Consumer]  ← 当前服务
       ↓
[WebSocket Hub]
       ↓
[APP 客户端]
```

## Kafka 消息格式

### Topic: `market.quotes`

```json
{
  "symbol": "AAPL",
  "price": 175.23,
  "change": 2.15,
  "changePercent": 1.24,
  "volume": 45678900,
  "timestamp": 1709856000000
}
```

## 配置切换

### config.yaml

```yaml
# 开发环境 - 使用 Mock
kafka:
  brokers: []  # 留空，自动启用 Mock 推送器

# 生产环境 - 使用 Kafka
kafka:
  brokers:
    - kafka-1.broker.com:9092
    - kafka-2.broker.com:9092
    - kafka-3.broker.com:9092
  topic: market.quotes
  groupID: market-service-group
```

## 启动逻辑

```go
// main.go 中的逻辑
if len(cfg.Kafka.Brokers) > 0 {
    // 生产环境：启动 Kafka 消费者
    kafkaConsumer := kafka.NewConsumer(...)
    go kafkaConsumer.Start(ctx)
} else {
    // 开发环境：启动 Mock 推送器
    mockPusher := websocket.NewMockPusher(wsHub, db)
    mockPusher.Start()
}
```

## 数据采集服务（需单独实现）

### 职责
1. 调用 Polygon.io API 获取实时行情
2. 数据清洗和格式转换
3. 发送到 Kafka Topic
4. 存储到数据库（异步）

### 部署建议
- 独立服务，与 Market Service 解耦
- 使用定时任务或 WebSocket 订阅 Polygon.io
- 支持多数据源聚合（Polygon、Yahoo Finance 等）

## 性能指标

### Kafka 消费者
- **吞吐量**: 10,000+ msg/s
- **延迟**: < 100ms
- **可靠性**: At-least-once 语义

### WebSocket 推送
- **并发连接**: 10,000+
- **推送延迟**: < 50ms
- **消息丢失率**: < 0.01%
