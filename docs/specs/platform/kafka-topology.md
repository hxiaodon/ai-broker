---
type: platform-standard
level: L3
scope: cross-domain
status: ACTIVE
created: 2026-03-18T00:00+08:00
maintainer: go-scaffold-architect
applies_to:
  - services/ams
  - services/trading-engine
  - services/market-data
  - services/fund-transfer
  - any new Go microservice that produces or consumes Kafka events
---

# Kafka 拓扑规范

> 本文档是平台级 Kafka 工程标准。所有服务的 Kafka Topic 设计、生产者、消费者实现必须遵循本规范。

## 1. Topic 命名规范

```
brokerage.{service}.{entity}.{event-type}
```

| 段 | 规则 | 示例 |
|----|------|------|
| `brokerage` | 固定前缀，平台标识 | `brokerage` |
| `{service}` | 服务名，kebab-case | `trading`、`fund-transfer`、`ams` |
| `{entity}` | 业务实体，单数 | `order`、`account`、`withdrawal` |
| `{event-type}` | 事件类型，过去式动词 | `placed`、`filled`、`approved`、`kyc-approved` |

**示例：**

```
brokerage.trading.order.placed
brokerage.trading.order.filled
brokerage.trading.order.cancelled
brokerage.fund-transfer.withdrawal.approved
brokerage.fund-transfer.deposit.completed
brokerage.ams.account.kyc-approved
brokerage.market-data.quote.updated
```

**禁止：**
- 使用动词现在式（`place`）或名词（`order-event`）
- 使用下划线（`trading_order`）——统一使用 kebab-case
- 随意缩写（`ord`、`acct`）

## 2. DLQ 三级模式（所有消费者必须实现）

每个被消费的 topic 都必须配套 retry 和 DLQ topic：

```
主 topic:   brokerage.{service}.{entity}.{event}
重试 topic: brokerage.{service}.{entity}.{event}.retry
DLQ topic:  brokerage.{service}.{entity}.{event}.dlq
```

**重试策略：指数退避**

| 重试次数 | 等待时间 |
|---------|---------|
| 第 1 次 | 1 秒 |
| 第 2 次 | 4 秒 |
| 第 3 次 | 16 秒 |
| 第 3 次失败后 | 写入 DLQ，触发告警，人工介入 |

**DLQ 处理原则：**
- DLQ 消息必须触发 PagerDuty/告警，不能静默丢失
- DLQ 消息保留至少 7 天（监管要求）
- 人工修复后可重放 DLQ 消息，消费者必须保证幂等

## 3. Outbox Pattern（所有生产者必须实现）

**核心原则：Kafka 消息只能从 outbox worker 发出，不能在业务代码中直接调用 `kafka.Writer.WriteMessages()`。**

### outbox_events 表（每个发布 Kafka 事件的服务都需要此表）

```sql
-- +goose Up
CREATE TABLE outbox_events (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    topic        VARCHAR(255)    NOT NULL,
    payload      BLOB            NOT NULL,         -- 序列化的 proto bytes
    status       ENUM('PENDING','PUBLISHED','FAILED') NOT NULL DEFAULT 'PENDING',
    created_at   TIMESTAMP(6)    NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    published_at TIMESTAMP(6)    NULL,
    retry_count  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    INDEX idx_status_created (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- +goose Down
DROP TABLE outbox_events;
```

### 正确用法：DB 写入 + outbox 插入在同一事务内

outbox 写入的是**完整信封的 JSON bytes**，不是裸 proto bytes——outbox worker 直接把 `payload` 列的内容发到 Kafka，不做任何二次封装。

```go
// ✅ 正确：业务写入和 outbox 插入在同一个 DB 事务，写入完整信封
func (r *orderRepo) SaveWithEvent(ctx context.Context, order *domain.Order, evt proto.Message, meta EventMeta) error {
    return r.db.Transaction(func(tx *gorm.DB) error {
        if err := tx.Create(toModel(order)).Error; err != nil {
            return fmt.Errorf("save order: %w", err)
        }

        // 1. 序列化业务 proto → bytes
        protoBytes, err := proto.Marshal(evt)
        if err != nil {
            return fmt.Errorf("marshal event payload: %w", err)
        }

        // 2. 构造信封
        envelope := &eventsv1.EventEnvelope{
            EventId:       uuid.NewString(),
            EventType:     meta.EventType,     // e.g. "order.placed.v1"
            CorrelationId: meta.CorrelationID, // 从 ctx 取 OTel trace ID
            CausationId:   meta.CausationID,
            Source:        "trading-engine",
            OccurredAt:    timestamppb.Now(),
            Payload:       protoBytes,
        }

        // 3. 序列化信封 → JSON（outbox_events.payload 存 JSON）
        envelopeBytes, err := protojson.Marshal(envelope)
        if err != nil {
            return fmt.Errorf("marshal envelope: %w", err)
        }

        // 4. 写入 outbox（同一事务）
        return tx.Exec(
            "INSERT INTO outbox_events (topic, payload) VALUES (?, ?)",
            meta.Topic, envelopeBytes,
        ).Error
    })
}

// EventMeta 由 Application Service 构造，不由 Domain 层感知
type EventMeta struct {
    Topic         string // "brokerage.trading.order.placed"
    EventType     string // "order.placed.v1"
    CorrelationID string // 从 context 取
    CausationID   string // 可为空
}
```
```

```go
// ❌ 错误：直接在业务逻辑中发布 Kafka——网络失败会导致数据不一致
func (s *orderService) PlaceOrder(ctx context.Context, order *domain.Order) error {
    s.repo.Save(ctx, order)
    s.kafka.WriteMessages(ctx, kafka.Message{...}) // 禁止
    return nil
}
```

### Outbox Worker

```go
// internal/kafka/outbox/worker.go
// 独立 goroutine，轮询 outbox_events 表，发布 PENDING 消息
func (w *Worker) Run(ctx context.Context) error {
    ticker := time.NewTicker(100 * time.Millisecond)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return nil
        case <-ticker.C:
            if err := w.publishPending(ctx); err != nil {
                w.logger.Error("outbox publish failed", zap.Error(err))
            }
        }
    }
}

func (w *Worker) publishPending(ctx context.Context) error {
    // 1. SELECT id, topic, payload FROM outbox_events WHERE status='PENDING' LIMIT 100
    // 2. 直接将 payload（完整信封 JSON）作为 kafka.Message.Value 发出，不做任何二次封装
    // 3. UPDATE outbox_events SET status='PUBLISHED', published_at=NOW() WHERE id IN (...)
    // 4. 失败时 UPDATE status='FAILED', retry_count=retry_count+1
}
```

## 4. Consumer Group 命名

```
{consuming-service}-{entity}-consumer
```

**示例：**

```
notification-email-consumer
risk-order-consumer
settlement-trade-consumer
admin-panel-withdrawal-consumer
```

**规则：**
- 同一消费逻辑在所有实例间共享一个 consumer group（水平扩展）
- 不同业务逻辑分属不同 consumer group（独立消费进度）
- consumer group 名称与 topic 名称保持语义一致

## 5. 消息体规范

### 必须使用 Protobuf，禁止 JSON Go Struct 共享包

Kafka 消息体定义在顶层 `api/events/v1/*.proto`：

```protobuf
// api/events/v1/order_events.proto
syntax = "proto3";
package brokerage.events.v1;

import "google/protobuf/timestamp.proto";

message OrderPlacedEvent {
  string   order_id   = 1;
  string   account_id = 2;
  string   symbol     = 3;
  string   quantity   = 4;  // string decimal — 禁止 float
  string   price      = 5;  // string decimal — 禁止 float
  string   side       = 6;  // BUY | SELL
  google.protobuf.Timestamp placed_at = 7;
}
```

**为什么禁止 Go struct 共享包：**
Go struct 删除字段不会有任何编译报错，消费方的对应字段会静默变成零值。Protobuf 字段编号保护 + `buf breaking` CI 检测能在变更入库前阻断 breaking change。

### EventEnvelope（基础设施层包装，非业务逻辑）

每条 Kafka 消息都用 EventEnvelope 包装，提供路由、可观测性和 schema 版本元数据。

**序列化格式：外层信封用 JSON，内层 Payload 用 proto bytes（base64 编码嵌入 JSON）。**

选择 JSON 信封的原因：`EventType`、`CorrelationID` 等元数据字段需要在不反序列化 payload 的情况下被 DLQ 监控、日志系统、审计 consumer 读取；proto 二进制信封在调试和运维场景下不可读。Payload 仍用 proto 保证业务数据的序列化效率和 schema 安全。

#### Proto 定义

```protobuf
// api/events/v1/envelope.proto
syntax = "proto3";
package brokerage.events.v1;

import "google/protobuf/timestamp.proto";

// EventEnvelope 是所有 Kafka 消息的外层包装
// 序列化：使用 protojson.Marshal 输出 JSON（Payload 字段自动 base64）
message EventEnvelope {
  string event_id        = 1;  // UUID v4，消息唯一标识，用于消费方幂等去重
  string event_type      = 2;  // "order.placed.v1"，消费方按此字段路由
  string correlation_id  = 3;  // OTel trace ID，贯穿整个调用链
  string causation_id    = 4;  // 触发本事件的上一个 event_id，实现事件因果链
  string source          = 5;  // 发布方服务名，如 "trading-engine"
  google.protobuf.Timestamp occurred_at = 6;  // UTC，事件发生时间
  bytes  payload         = 7;  // proto.Marshal 后的业务事件 bytes
}
```

#### Go 类型（由 proto 生成，勿手写）

```go
// 生成路径：api/events/v1/envelope.pb.go（protoc-gen-go 生成）
// 信封序列化：统一使用 protojson，不用 encoding/json
// protojson 保证 bytes 字段正确 base64，Timestamp 输出 RFC3339

import (
    "google.golang.org/protobuf/encoding/protojson"
    eventsv1 "brokerage/api/events/v1"
)

// 序列化信封 → Kafka Message.Value
func marshalEnvelope(env *eventsv1.EventEnvelope) ([]byte, error) {
    return protojson.Marshal(env)
}

// 反序列化 Kafka Message.Value → 信封
func unmarshalEnvelope(data []byte) (*eventsv1.EventEnvelope, error) {
    var env eventsv1.EventEnvelope
    if err := protojson.Unmarshal(data, &env); err != nil {
        return nil, fmt.Errorf("unmarshal envelope: %w", err)
    }
    return &env, nil
}
```

**字段说明：**
- `event_id`：消费方用此字段做幂等去重（Redis SET NX 或 DB unique index）
- `event_type`：包含版本后缀（如 `.v1`）允许 schema 并行演进，消费方路由的唯一依据
- `correlation_id`：与 OTel trace ID 保持一致，便于跨服务链路追踪
- `causation_id`：实现事件因果链，用于审计和问题排查；若无上游事件则为空字符串
- `occurred_at`：事件**发生**时间（非写入 Kafka 的时间），由 Application Service 在创建信封时设置

### Consumer 路由规范

消费方收到消息后，先解析信封取得 `event_type`，再路由到对应 handler。路由表在 consumer 初始化时注册，**不使用 switch-case**——新增事件类型只需注册新 handler，不修改路由逻辑。

```go
// kafka/consumer/router.go
package consumer

import (
    "context"
    "fmt"
    "google.golang.org/protobuf/proto"
    "google.golang.org/protobuf/encoding/protojson"
    eventsv1 "brokerage/api/events/v1"
    "go.uber.org/zap"
)

// PayloadHandler 处理已解包的 proto payload bytes
type PayloadHandler func(ctx context.Context, payload []byte) error

// Router 按 event_type 路由到对应 handler
type Router struct {
    handlers map[string]PayloadHandler
    logger   *zap.Logger
}

func NewRouter(logger *zap.Logger) *Router {
    return &Router{
        handlers: make(map[string]PayloadHandler),
        logger:   logger,
    }
}

// Register 注册 event_type → handler 映射
func (r *Router) Register(eventType string, handler PayloadHandler) {
    r.handlers[eventType] = handler
}

// Handle 是 Kafka consumer 的入口，被 DLQ 三级模式的 main consumer 调用
func (r *Router) Handle(ctx context.Context, msg []byte) error {
    env, err := unmarshalEnvelope(msg)
    if err != nil {
        // 信封解析失败：消息格式损坏，直接进 DLQ，不重试
        return fmt.Errorf("envelope corrupted, routing to dlq: %w", err)
    }

    handler, ok := r.handlers[env.EventType]
    if !ok {
        // 未知 event_type：向前兼容，跳过不报错
        // 场景：消费方尚未部署新版本，但生产方已发布新事件类型
        r.logger.Warn("unknown event type, skipping",
            zap.String("event_type", env.EventType),
            zap.String("event_id", env.EventId),
            zap.String("source", env.Source),
        )
        return nil
    }

    if err := handler(ctx, env.Payload); err != nil {
        return fmt.Errorf("handle %s event_id=%s: %w", env.EventType, env.EventId, err)
    }
    return nil
}
```

```go
// kafka/consumer/order_consumer.go — 具体 consumer 的组装示例
package consumer

import eventsv1 "brokerage/api/events/v1"

func NewOrderEventConsumer(
    settlementUC SettlementUsecase,
    notifyUC     NotifyUsecase,
    logger       *zap.Logger,
) *Router {
    r := NewRouter(logger)

    // 注册：每个 event_type 对应一个 handler 函数
    r.Register("order.placed.v1",    handleOrderPlaced(settlementUC))
    r.Register("order.filled.v1",    handleOrderFilled(settlementUC, notifyUC))
    r.Register("order.cancelled.v1", handleOrderCancelled(notifyUC))

    return r
}

func handleOrderFilled(settlementUC SettlementUsecase, notifyUC NotifyUsecase) PayloadHandler {
    return func(ctx context.Context, payload []byte) error {
        // 1. 反序列化具体业务 proto（payload 是 proto.Marshal bytes）
        var evt eventsv1.OrderFilledEvent
        if err := proto.Unmarshal(payload, &evt); err != nil {
            return fmt.Errorf("unmarshal OrderFilledEvent: %w", err)
        }
        // 2. 调用 Application Service（不在 consumer 层写业务逻辑）
        if err := settlementUC.TriggerSettlement(ctx, &evt); err != nil {
            return err // 返回 error 触发 DLQ 三级重试
        }
        return notifyUC.NotifyOrderFilled(ctx, &evt)
    }
}
```

**路由规则总结：**

| 情况 | 处理方式 | 原因 |
|------|---------|------|
| 信封 JSON 解析失败 | 返回 error → 进 DLQ | 消息损坏，重试无意义 |
| `event_type` 未注册 | 跳过（返回 nil） | 向前兼容，消费方版本落后于生产方 |
| payload proto 解析失败 | 返回 error → 触发重试 | 可能是瞬时问题，允许重试 |
| handler 业务逻辑失败 | 返回 error → 触发重试 | 按 DLQ 三级模式处理 |

## 6. Schema 演进规则

使用 `buf breaking` 在 CI 中检测 breaking change：

```yaml
# api/buf.yaml
breaking:
  use: [WIRE_JSON]
```

**允许的演进：**
- 新增 field（使用新的 field number）
- 新增 enum value
- 修改 field 名称（field number 不变，不影响序列化）

**禁止的演进（buf breaking 会阻断）：**
- 删除 field（会导致消费方静默零值）
- 修改 field number
- 修改 field 类型
- 修改 enum value 的数字

**废弃 field 的正确做法：**
```protobuf
message OrderPlacedEvent {
  string order_id = 1;
  // deprecated: use unit_price instead. Will be removed in v2.
  string price = 4 [deprecated = true];
  string unit_price = 8;  // 新字段使用新编号
}
```

## 7. 目录结构

### 布局 A（单子域服务）

Kafka 基础设施放在 `data/` 层内——单子域服务的所有基础设施（DB、Redis、Kafka）都归 `data/` 管理。

```
internal/
├── biz/                        # Domain 层
├── data/                       # Infrastructure 层（拥有所有基础设施）
│   ├── {entity}_repo.go        # MySQL/Redis 实现
│   ├── model/                  # GORM DB structs
│   ├── kafka/
│   │   ├── outbox/
│   │   │   └── worker.go       # Outbox worker（轮询 outbox_events 表）
│   │   ├── producer/
│   │   │   └── {entity}.go     # 按实体分文件的类型安全发布接口
│   │   └── consumer/
│   │       └── {topic}.go      # 每个消费 topic 独立 handler 文件
│   └── data.go                 # DB/Redis init + wire.NewSet(...)
├── service/                    # Application 层
└── server/                     # Transport 层
```

### 布局 B（多子域服务）

Kafka 基础设施**提升到 `internal/` 根级**，与各子域并列。

原因：多子域服务中 outbox worker 是服务级的单一 goroutine，不属于任何一个子域——如果每个子域各有一个 worker，多个 worker 并发 SELECT + UPDATE 同一批 `outbox_events` 记录会产生竞争条件。producer/consumer 同理，作为服务级基础设施统一管理。

```
internal/
├── order/                      # 子域 A（自包含的 DDD 单元）
│   ├── domain/
│   ├── app/
│   ├── infra/
│   │   └── mysql/repo.go       # order 子域的 DB 访问（私有）
│   ├── handler.go
│   └── wire.go
├── risk/                       # 子域 B
│   ├── domain/
│   ├── app/
│   ├── infra/
│   ├── handler.go
│   └── wire.go
├── settlement/                 # 子域 C
│   └── ...
├── kafka/                      # 服务级 Kafka 基础设施（与子域并列，不属于任何子域）
│   ├── outbox/
│   │   └── worker.go           # 单一 outbox worker，轮询整个服务的 outbox_events 表
│   ├── producer/
│   │   └── {entity}.go         # 各子域通过此处发布事件（不直接调用 kafka.Writer）
│   └── consumer/
│       └── {topic}.go          # 每个消费 topic 独立 handler 文件
├── data/
│   └── model/                  # 仅放跨子域共享的 DB struct
└── server/                     # 全局 Transport（聚合各子域 handler）
    ├── http.go
    ├── grpc.go
    └── server.go
```

**子域内的 `infra/` vs 服务级 `kafka/` 的职责边界：**

| 位置 | 存放内容 |
|------|---------|
| `{subdomain}/infra/mysql/` | 该子域专属的 DB 查询、GORM model（私有，不跨域共享）|
| `{subdomain}/infra/kafka/publisher.go` | 实现该子域 `domain.EventPublisher` 接口的适配器（调用服务级 `kafka/producer/`）|
| 服务级 `kafka/producer/` | 实际写 Kafka 的类型安全接口（被各子域的 infra adapter 调用）|
| 服务级 `kafka/outbox/worker.go` | 轮询 `outbox_events` 表，统一发布，唯一调用 `kafka.Writer.WriteMessages()` 的地方 |

## 8. 监控指标（所有服务标准）

```go
// pkg/observability/metrics.go（脚手架预置）
KafkaPublished = prometheus.NewCounterVec(prometheus.CounterOpts{
    Name: "kafka_messages_published_total",
    Help: "Total Kafka messages published, by topic and status",
}, []string{"topic", "status"})  // status: success | error

KafkaConsumed = prometheus.NewCounterVec(prometheus.CounterOpts{
    Name: "kafka_messages_consumed_total",
    Help: "Total Kafka messages consumed, by topic and status",
}, []string{"topic", "status"})  // status: success | retry | dlq
```

告警规则（DevOps 配置）：
- `kafka_messages_consumed_total{status="dlq"} > 0` → P1 告警
- `kafka_messages_consumed_total{status="retry"} / total > 5%` → P2 告警
- outbox_events 表中 `PENDING` 记录堆积超过 1000 → P2 告警

## 9. 参考资料

| 资源 | 说明 |
|------|------|
| `docs/specs/platform/go-service-architecture.md` | Go 服务架构总规范 |
| `docs/specs/platform/api-contracts.md` | API 契约规范（proto layout、buf） |
| [Confluent Event Envelope Pattern](https://developer.confluent.io/patterns/event/event-envelope/) | EventEnvelope 设计来源 |
| [buf.build breaking rules](https://buf.build/docs/breaking/rules) | Schema 演进规则参考 |
| `.claude/agents/go-scaffold-architect.md` | 脚手架 agent（执行层） |
