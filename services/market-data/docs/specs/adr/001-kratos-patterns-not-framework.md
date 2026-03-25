# ADR-001: 采用 Kratos 架构模式而非 Kratos 框架本身

| 字段 | 值 |
|------|-----|
| 状态 | ACCEPTED |
| 日期 | 2026-03-22 |
| 决策者 | market-data-engineer |

## 背景

项目 `CLAUDE.md` 和 `go-scaffold-architect` 规范均标注技术栈为 "Kratos + Wire"。在 `services/market-data/src/` 脚手架生成阶段，需要决定是否引入 `go-kratos/kratos/v2` 框架依赖。

## 决策

**不引入 Kratos 框架库**，仅采用其架构模式（DDD 分层 + Wire DI）。

实际依赖：
- HTTP 传输层：标准库 `net/http`（非 `kratos/transport/http`）
- gRPC 传输层：`google.golang.org/grpc`（非 `kratos/transport/grpc`）
- 配置加载：`gopkg.in/yaml.v3`（非 `kratos/config`）
- DI：`github.com/google/wire`（与 Kratos 共用，保留）

## 原因

### 1. WebSocket 需求
WebSocket gateway 需要直接控制 `http.Server` 和 `http.Hijacker`。Kratos HTTP transport 对底层 mux 有封装侵入，绕一圈反而更复杂。

### 2. Kratos CLI 无法生成领域脚手架
`kratos new` 生成通用模板，与本服务的 subdomain-first DDD（4 个子域：quote/kline/watchlist/search）不对应，领域感知的结构需要 `go-scaffold-architect` 自定义生成。

### 3. 依赖轻量化
避免引入 Kratos 的服务发现、注册中心、middleware 链等暂时不需要的能力，保持 `go.mod` 清晰。

## 后果

**保留能力（不受影响）：**
- DDD 分层结构（domain/app/infra/server）
- Wire 依赖注入
- Outbox + Kafka 分发模式
- 标准 gRPC + Protobuf 接口

**需要自行实现（Kratos 本来开箱即用）：**
- 健康检查集成（已在 `/health` `/ready` 自行实现）
- Prometheus metrics（已通过 `/metrics` 自行实现）
- 请求 middleware 链（如限流、链路追踪）需手动挂载

## 迁移路径（如未来需要统一）

仅需替换传输层，DDD 业务层无需改动：

```
internal/server/http.go  → kratos/transport/http.Server
internal/server/grpc.go  → kratos/transport/grpc.Server
internal/conf/conf.go    → kratos/config
```

subdomain 下的 domain/app/infra 层完全不受影响。


# ADR-002: 后面可能会接入沧海行情数据 https://tsanghi.com/fin/index