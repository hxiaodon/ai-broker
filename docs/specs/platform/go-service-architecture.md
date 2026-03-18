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
  - any new Go microservice
---

# Go 微服务架构规范

> 本文档是平台级工程标准。所有新建 Go 微服务必须遵循本规范。
> 现有服务迁移时参考本规范，但不强制立即对齐——迁移为独立任务。

## 1. 架构框架

所有新服务使用 **Kratos + Wire**：

- [go-kratos/kratos v2](https://github.com/go-kratos/kratos) — 框架（Transport、Middleware、生命周期）
- [google/wire](https://github.com/google/wire) — 编译期依赖注入

**为什么是 DDD 而不是 MVC？**

MVC 的依赖方向是 `Controller → Service → Model(DB)`——领域依赖数据库。
DDD 倒置这个方向：`biz/`（领域层）定义 Repository *接口*；`data/`（基础设施层）*实现*接口。
数据库依赖领域，而不是领域依赖数据库。这是依赖倒置原则（DIP），是让子域可以独立测试和独立拆分的架构基础。

## 2. DDD 层映射（Kratos）

| Kratos 包 | DDD 层 | 职责 |
|-----------|--------|------|
| `biz/` | **Domain** | 实体、值对象、聚合根、Repository 接口、领域服务——零外部依赖 |
| `data/` | **Infrastructure** | 实现 `biz/` 定义的接口；持有 DB struct、Redis 操作、Kafka producer |
| `service/` | **Application** | 编排用例；DTO ↔ 领域对象转换；通过接口调用 `biz/` |
| `server/` | **Transport** | HTTP + gRPC server 注册；注册 `service/` handler；挂载 middleware |

**依赖方向**（由 Go import graph 强制，违反会编译报错）：

```
server → service → biz ← data
```

`data/` import `biz/` 来实现其接口。`biz/` 不 import 同服务的任何其他包。

## 3. 目录结构选择

根据子域数量选择布局：

### 布局 A：Single-Domain DDD（1 个子域）

使用 Kratos 原生结构，四个 DDD 层直接对应 `biz/`、`data/`、`service/`、`server/`。

```
services/{name}/src/
└── internal/
    ├── conf/       # config proto → Go struct
    ├── biz/        # Domain 层
    ├── data/       # Infrastructure 层
    ├── service/    # Application 层
    └── server/     # Transport 层
```

### 布局 B：Subdomain-First DDD（2+ 个子域）

`internal/` 顶层按**子域**组织，DDD 层在每个子域内部展开。子域是独立可提取的单元。

```
services/{name}/src/
└── internal/
    ├── {subdomain-a}/
    │   ├── domain/     # Domain 层
    │   ├── app/        # Application 层
    │   ├── infra/      # Infrastructure 层
    │   ├── handler.go  # Transport 接入点
    │   └── wire.go     # var ProviderSet = wire.NewSet(...)
    ├── {subdomain-b}/
    │   └── ...
    ├── data/model/     # 仅放跨子域共享的 DB struct
    ├── kafka/          # 服务级 Kafka 基础设施
    └── server/         # 全局 Transport（聚合所有子域 handler）
```

**每个子域内的依赖方向**：

```
handler → app → domain ← infra
```

### 布局 B 的退化形式（简单子域）

当子域只有 1 个聚合根且每层代码 < 300 行时，可以将各层折叠为单文件——仍然是 DDD，只是减少目录层级：

```
{subdomain}/
├── domain.go    # 实体 + repo 接口（Domain 层）
├── usecase.go   # 用例编排（Application 层）
├── repo.go      # MySQL/Redis 实现（Infrastructure 层）
└── handler.go   # HTTP/gRPC handler（Transport 层）
```

当任意文件超过 ~300 行，或出现第二个聚合根时，提升为子包形式。

### domain/ 子包展开（复杂子域）

当子域有 2+ 个聚合根时，`domain/` 按聚合根再分包：

```
{subdomain}/domain/
├── {aggregate-a}/
│   ├── aggregate.go   # 聚合根 + 方法
│   ├── vo/            # 值对象（不可变，按值比较）
│   └── repo.go        # 该聚合的 repo 接口
├── {aggregate-b}/
│   └── ...
├── service/           # 跨聚合的领域服务
└── event/             # 跨聚合边界的领域事件
```

## 4. Wire 组织方式

每个子域暴露自己的 `ProviderSet`，组合根（`cmd/server/wire.go`）只做汇聚：

```go
// internal/{subdomain}/wire.go
var ProviderSet = wire.NewSet(
    mysql.NewRepo,
    kafka.NewPublisher,
    NewCreateOrderUsecase,
    NewHandler,
)

// cmd/server/wire.go  (build tag: //go:build wireinject)
func initApp(cfg *conf.Bootstrap, logger log.Logger) (*kratos.App, func(), error) {
    wire.Build(
        server.ProviderSet,
        order.ProviderSet,
        risk.ProviderSet,
        settlement.ProviderSet,
        data.ProviderSet,
        newApp,
    )
    return nil, nil, nil
}
```

拆分子域到新 repo 时：搬走子域目录，将其 `ProviderSet` 移入新 repo 的 `cmd/server/wire.go`，完成。

## 5. 跨子域通信（进程内）

> **核心规则：接口属于调用方。**

调用方子域在自己的包内定义所需接口（`deps.go`）。被调方提供实现，通过 Go 结构化类型隐式满足接口，被调方对接口的存在一无所知。

这是 Google Go Style Guide、ThreeDotsLabs (wild-workouts) 和 DDD 社区的共识做法，是唯一保证子域边界可提取的方案。

```go
// internal/order/deps.go — 调用方定义自己需要什么
package order

type RiskEngine interface {
    CheckOrder(ctx context.Context, ord *Order) (*RiskResult, error)
}

type Router interface {
    Route(ctx context.Context, ord *Order) error
}
```

```go
// cmd/server/wire.go — 组合根绑定具体类型 → 接口
wire.Bind(new(order.RiskEngine), new(*risk.EngineImpl)),
wire.Bind(new(order.Router),     new(*routing.SORImpl)),
```

### 允许 vs 禁止

| 模式 | 规则 |
|------|------|
| `risk/` import `order.Order` 结构体（纯数据类型） | ✅ 允许 |
| `order/` 定义 `RiskEngine` 接口，`risk/` 实现它 | ✅ 正确模式 |
| `order/app` 直接 import `risk/app.Service` 并调用方法 | ❌ 禁止——导入了兄弟行为 |
| 同 DB 事务内的子域协作使用进程内事件总线 | ❌ 避免——引入不确定性，用接口调用代替 |

### 何时用 Kafka 事件而非接口调用

只有当副作用必须发生在**主事务之外**或**跨服务边界**时才用 Kafka 事件：

- 填单确认后写入审计 topic → Kafka 事件
- 通知移动端订单状态变更 → Kafka 事件
- 下单前同步检查买入力 → 接口调用

> **Vladimir Khorikov（DDD）**：「如果所有协作方使用同一个数据库，用显式调用让流程清晰。领域事件是应用间通信，不是应用内通信。」

## 6. 跨子域数据类型共享

| 场景 | 做法 |
|------|------|
| 只有一个子域使用的 DB struct | 放在该子域的 `infra/mysql/model.go`，不提升 |
| 两个及以上子域使用的 DB struct | 提升到 `internal/data/model/shared.go` |
| HTTP 请求/响应 DTO | 不做共享包——各消费方从 proto 或 OpenAPI 生成自己的类型 |
| Kafka 消息体 | 定义在 `api/events/v1/*.proto`，不做 Go struct 共享包 |
| 纯数据类型（实体 struct、枚举） | 可以跨子域 import，但不能 import 行为（方法调用） |

## 7. 拆分 Repo 的准备

布局 B（Subdomain-First DDD）的设计目标之一是让子域拆分为独立 repo 时代价最低：

```bash
# 拆分 settlement 子域到新 repo：
mv internal/settlement/ ../settlement-service/internal/settlement/
# 新 repo 补充 cmd/server/ 和 server/ 即可，业务代码零修改
```

布局 A（Single-Domain DDD）拆分时需要将 `biz/`、`data/`、`service/` 各取一块，成本更高。因此：
- 预期未来拆分 → 优先使用布局 B
- 确定不拆分的简单服务 → 布局 A 足够

## 8. 参考资料

| 资源 | 说明 |
|------|------|
| [go-kratos/kratos-layout](https://github.com/go-kratos/kratos-layout) | 官方 layout 模板 |
| [ThreeDotsLabs/wild-workouts](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example) | Go DDD 最佳实践参考实现 |
| [google/wire guide](https://github.com/google/wire/blob/main/docs/guide.md) | Wire 使用指南 |
| [Google Go Style: Interfaces](https://google.github.io/styleguide/go/decisions#interfaces) | 接口定义在消费方 |
| `docs/specs/platform/kafka-topology.md` | Kafka 拓扑规范 |
| `docs/specs/platform/api-contracts.md` | API 契约规范 |
| `docs/specs/platform/ddd-patterns.md` | DDD 战术模式、SOLID Go 落地、设计模式选型指南 |
| `docs/specs/platform/feature-development-workflow.md` | PRD → Tech Spec → 分 Phase 实现 → Codex 验收的完整开发流程 |
| `.claude/agents/go-scaffold-architect.md` | 脚手架 agent（执行层） |
