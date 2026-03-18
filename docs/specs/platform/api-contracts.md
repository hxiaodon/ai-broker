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
  - any new Go microservice with external interfaces
---

# API 契约规范

> 本文档是平台级 API 契约工程标准。所有服务间接口定义、消息体 schema、HTTP DTO 的管理方式必须遵循本规范。

## 1. 核心原则

**Proto-first**：所有跨服务接口和 Kafka 消息体以 `.proto` 文件为唯一来源。不做手写共享 Go DTO 包。

**Consumer generates its own types**：消费方从 proto 或 OpenAPI 生成自己的客户端类型。不从生产方的 Go 包 import 类型。

**Breaking change is gated in CI**：`buf breaking` 在 merge 前阻断任何不向后兼容的 proto 变更。

## 2. 顶层 `api/` 目录结构

所有服务接口和事件定义统一放在 repo 根目录的 `api/`——跨服务契约的唯一来源：

```
api/                                    # repo root — 唯一 proto 来源
├── buf.yaml                            # buf lint + breaking change 检测配置
├── buf.gen.yaml                        # 代码生成配置
├── common/v1/
│   ├── money.proto                     # Money、Currency（string decimal，禁止 float）
│   └── pagination.proto                # PageRequest、PageResponse
├── ams/v1/
│   ├── ams.proto                       # AMS RPC 定义 + HTTP annotations
│   └── errors.proto                    # AMS 错误码
├── trading/v1/
│   ├── trading.proto
│   └── errors.proto
├── market_data/v1/
│   ├── market_data.proto
│   └── errors.proto
├── fund_transfer/v1/
│   ├── fund_transfer.proto
│   └── errors.proto
└── events/v1/
    ├── order_events.proto              # Trading 发布的事件
    ├── account_events.proto            # AMS 发布的事件
    ├── transfer_events.proto           # Fund Transfer 发布的事件
    ├── market_events.proto             # Market Data 发布的事件
    └── envelope.proto                  # EventEnvelope 包装器
```

### buf.yaml

```yaml
version: v1
lint:
  use:
    - DEFAULT
  except:
    - PACKAGE_VERSION_SUFFIX   # 允许不带版本后缀的包名（内部服务）
breaking:
  use:
    - WIRE_JSON                # 阻断所有 wire 和 JSON 不兼容的变更
```

### buf.gen.yaml

生成产物**直接输出到各服务的 `internal/gen/` 目录**，各服务 `go.mod` 保持完全独立，无需 `replace` 指令。`module=` opt 告诉 protoc-gen-go 以各服务自己的 module root 计算 Go import path。

```yaml
# api/buf.gen.yaml
version: v1
plugins:
  # ── trading-engine ──────────────────────────────────────────────
  - plugin: go
    out: ../services/trading-engine/src
    opt:
      - paths=source_relative
      - module=brokerage/trading-engine   # 与该服务 go.mod module 名一致
  - plugin: go-grpc
    out: ../services/trading-engine/src
    opt:
      - paths=source_relative
      - module=brokerage/trading-engine
  - plugin: go-http                        # Kratos HTTP binding
    out: ../services/trading-engine/src
    opt:
      - paths=source_relative
      - module=brokerage/trading-engine
  - plugin: go-errors                      # Kratos 错误码
    out: ../services/trading-engine/src
    opt:
      - paths=source_relative
      - module=brokerage/trading-engine

  # ── ams ─────────────────────────────────────────────────────────
  - plugin: go
    out: ../services/ams/src
    opt:
      - paths=source_relative
      - module=brokerage/ams
  - plugin: go-grpc
    out: ../services/ams/src
    opt:
      - paths=source_relative
      - module=brokerage/ams
  - plugin: go-http
    out: ../services/ams/src
    opt:
      - paths=source_relative
      - module=brokerage/ams
  - plugin: go-errors
    out: ../services/ams/src
    opt:
      - paths=source_relative
      - module=brokerage/ams

  # ── market-data ─────────────────────────────────────────────────
  - plugin: go
    out: ../services/market-data/src
    opt:
      - paths=source_relative
      - module=brokerage/market-data
  - plugin: go-grpc
    out: ../services/market-data/src
    opt:
      - paths=source_relative
      - module=brokerage/market-data
  - plugin: go-http
    out: ../services/market-data/src
    opt:
      - paths=source_relative
      - module=brokerage/market-data
  - plugin: go-errors
    out: ../services/market-data/src
    opt:
      - paths=source_relative
      - module=brokerage/market-data

  # ── fund-transfer ────────────────────────────────────────────────
  - plugin: go
    out: ../services/fund-transfer/src
    opt:
      - paths=source_relative
      - module=brokerage/fund-transfer
  - plugin: go-grpc
    out: ../services/fund-transfer/src
    opt:
      - paths=source_relative
      - module=brokerage/fund-transfer
  - plugin: go-http
    out: ../services/fund-transfer/src
    opt:
      - paths=source_relative
      - module=brokerage/fund-transfer
  - plugin: go-errors
    out: ../services/fund-transfer/src
    opt:
      - paths=source_relative
      - module=brokerage/fund-transfer

  # ── OpenAPI（Mobile / Admin Panel 消费）─────────────────────────
  - plugin: openapiv2
    out: ../docs/openapi
    opt:
      - logtostderr=true
      - allow_merge=true           # 所有服务合并为单一 openapi.json
```

**生成产物的目录约定：**

`paths=source_relative` + `module=brokerage/{service}` 的组合效果：

```
# proto 文件位置               →  生成产物位置（在各服务 src/ 内）
api/trading/v1/trading.proto  →  services/trading-engine/src/internal/gen/trading/v1/trading.pb.go
api/events/v1/envelope.proto  →  services/trading-engine/src/internal/gen/events/v1/envelope.pb.go
```

各服务代码 import 路径：

```go
import (
    tradingv1 "brokerage/trading-engine/internal/gen/trading/v1"
    eventsv1  "brokerage/trading-engine/internal/gen/events/v1"
)
```

**`.gitignore` 规则（各服务 src/ 下）：**

```gitignore
# proto 生成产物——由 buf generate 重新生成，不提交
internal/gen/
```

**派生链路：** proto（source of truth）→ `buf generate`（单次执行）→ 各服务 `internal/gen/` + `docs/openapi/` → Mobile/Web 代码生成

`internal/gen/` 和 `docs/openapi/` 下的所有文件均为**只读派生产物**，不可手写修改。如需变更接口，改对应 `.proto` 文件，重新运行 `buf generate`。

## 3. Proto 编写规范

### 金额字段：必须用 string，禁止 float

```protobuf
// ✅ 正确
message Order {
  string quantity = 3;   // string decimal — never float
  string price    = 4;   // string decimal — never float
}

// ❌ 错误
message Order {
  double quantity = 3;   // 禁止：float 会有精度损失
  float  price    = 4;   // 禁止
}
```

### 时间戳：必须用 google.protobuf.Timestamp（UTC）

```protobuf
import "google/protobuf/timestamp.proto";

message Order {
  google.protobuf.Timestamp created_at = 8;  // UTC
  google.protobuf.Timestamp filled_at  = 9;  // UTC，nullable 用 optional
}
```

### HTTP annotations（Kratos HTTP binding）

```protobuf
import "google/api/annotations.proto";

service TradingService {
  rpc PlaceOrder(PlaceOrderRequest) returns (PlaceOrderResponse) {
    option (google.api.http) = {
      post: "/api/v1/orders"
      body: "*"
    };
  }
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse) {
    option (google.api.http) = {
      get: "/api/v1/orders/{order_id}"
    };
  }
}
```

### 错误码 proto（每个服务一个）

```protobuf
// api/{service}/v1/errors.proto
syntax = "proto3";
package brokerage.{service}.v1;

import "errors/errors.proto";

enum {Service}ErrorReason {
  option (errors.default_code) = 500;

  // 4xx — 客户端/业务规则错误
  {SERVICE}_INVALID_ARGUMENT    = 0  [(errors.code) = 400];
  {SERVICE}_NOT_FOUND           = 1  [(errors.code) = 404];
  {SERVICE}_ALREADY_EXISTS      = 2  [(errors.code) = 409];
  {SERVICE}_PRECONDITION_FAILED = 3  [(errors.code) = 412];

  // 5xx — 服务端错误
  {SERVICE}_INTERNAL            = 10 [(errors.code) = 500];
  {SERVICE}_UNAVAILABLE         = 11 [(errors.code) = 503];

  // 业务规则错误（FILL：按域扩展）
  // ORDER_INSUFFICIENT_BUYING_POWER = 20 [(errors.code) = 422];
}
```

**错误码命名：** `{DOMAIN}_{ENTITY}_{REASON}`，SCREAMING_SNAKE_CASE

**错误码是 append-only**：永不修改或删除已有编号，废弃时加 `[deprecated = true]` 注释。

## 4. 消费方接入规范

### 禁止共享 Go DTO 包

不得创建 `shared/types`、`common/dto` 等跨服务共享的 Go HTTP 类型包。

**原因：** 共享 DTO 包是分布式单体的典型特征——修改一个字段强制所有依赖服务协调部署，破坏服务独立演进能力。

### 三类消费方，一个 proto 来源

```
proto (source of truth)
    │
    ├── buf generate (go / go-grpc / go-http / go-errors)
    │       └── 服务端 + Server-to-Server gRPC 客户端（Go）
    │
    └── buf generate (openapiv2)
            └── docs/openapi/*.json  ←── 只读派生产物
                    │
                    ├── Flutter (openapi-generator-cli → Dart)
                    └── React Admin (openapi-typescript / orval → TypeScript)
```

| 消费方 | 协议 | 代码生成方式 | 来源文件 |
|--------|------|-------------|---------|
| Go 微服务（服务间） | gRPC | `buf generate` → `.pb.go` | `api/{service}/v1/*.proto` |
| Flutter Mobile / H5 | REST over HTTP | `openapi-generator-cli --generator-name dart` | `docs/openapi/{service}.json` |
| React Admin Panel | REST over HTTP | `openapi-typescript` 或 `orval` | `docs/openapi/{service}.json` |

### 方式 A：Server-to-Server（gRPC，Go）

生成产物在各服务的 `internal/gen/` 下，服务代码直接 import 本模块内的生成类型：

```go
// services/trading-engine/src/internal/order/app/place_order.go
import (
    amsv1 "brokerage/trading-engine/internal/gen/ams/v1"    // AMS 生成类型
    eventsv1 "brokerage/trading-engine/internal/gen/events/v1"
)
```

**代码组织：**

```
services/trading-engine/src/
└── internal/
    ├── gen/                        # buf generate 输出（gitignore，不提交）
    │   ├── trading/v1/             # 本服务的 proto 生成类型
    │   ├── ams/v1/                 # 上游服务的 proto 生成类型（供 gRPC client 使用）
    │   └── events/v1/              # Kafka 事件 proto 生成类型
    └── order/
        ├── infra/grpc/
        │   └── ams_client.go       # AMS gRPC client 封装（使用 gen/ams/v1 类型）
        └── deps.go                 # order 子域对 AMS 能力的接口定义（供 Wire 注入）
```

```go
// internal/order/deps.go — 接口定义在调用方，不在 gen/ 生成代码里
package order

type AccountVerifier interface {
    VerifyAccount(ctx context.Context, accountID string) (*AccountStatus, error)
}
```

### 方式 B：Flutter Mobile / H5（REST，Dart）

OpenAPI 由 proto 派生（`protoc-gen-openapiv2`），Flutter 工程从 `docs/openapi/` 生成 Dart client：

```bash
# 在 CI 中执行；mobile 工程师不手写 HTTP client
openapi-generator-cli generate \
  -i docs/openapi/{service}.json \
  -g dart-dio \
  -o mobile/lib/generated/api/{service}
```

- 生成的 Dart client 放在 `mobile/lib/generated/api/`，**不手写、不提交到 git**（gitignore）
- 接口变更流程：改 proto → CI 重新生成 `docs/openapi/` → Mobile CI 重新生成 Dart client → Flutter 工程师适配

### 方式 C：React Admin Panel（REST，TypeScript）

```bash
# 在 CI 或 dev setup 中执行
npx openapi-typescript docs/openapi/{service}.json \
  --output services/admin-panel/src/generated/api/{service}.ts
```

或使用 `orval`（支持 React Query / SWR hooks 自动生成）：

```bash
orval --config services/admin-panel/orval.config.ts
```

- 生成的 TypeScript 类型放在 `services/admin-panel/src/generated/api/`，**不手写**
- `services/admin-panel/orval.config.ts` 指向 `docs/openapi/` 下各服务的 JSON 文件

## 5. 服务间调用模式

### 同步调用（gRPC）

服务间同步调用使用 gRPC，通过 Kratos 的 `gRPC client` 封装：

```go
// internal/ams/client.go — trading-engine 内部的 AMS gRPC 客户端
package ams

import (
    "google.golang.org/grpc"
    amsv1 "github.com/brokerage/trading-engine/api/ams/v1"
)

func NewAMSClient(conn *grpc.ClientConn) amsv1.AMSServiceClient {
    return amsv1.NewAMSServiceClient(conn)
}
```

```go
// internal/order/deps.go — order 子域对 AMS 能力的接口定义
package order

// AccountVerifier 是 order/ 需要 AMS 提供的能力
// 接口定义在调用方，不在 AMS 包内
type AccountVerifier interface {
    VerifyAccount(ctx context.Context, accountID string) (*AccountStatus, error)
}
```

### 异步调用（Kafka Events）

跨服务异步通信通过 Kafka，消息体定义在 `api/events/v1/*.proto`。
详见 `docs/specs/platform/kafka-topology.md`。

## 6. Contracts 文档（docs/contracts/）

每对有接口依赖的服务在 `docs/contracts/` 下维护一份契约文档，记录接口版本和变更历史：

```
docs/contracts/
├── ams-to-trading.md           # AMS 提供给 Trading Engine 的接口
├── trading-to-fund.md          # Trading Engine 触发的资金操作接口
├── market-data-to-trading.md   # Market Data 提供给 Trading Engine 的报价接口
└── ...
```

**契约文档格式：**

```yaml
---
provider: services/ams
consumer: services/trading-engine
protocol: gRPC
proto_file: api/ams/v1/ams.proto
version: 2
last_updated: 2026-03-18T00:00+08:00
---
```

当 proto 发生 breaking change 时，需同步更新对应契约文档的 `version` 和 changelog。

## 7. Schema 演进与 CI 门控

### buf breaking 检测（必须配置在 CI）

```yaml
# .github/workflows/proto-check.yml
- name: buf breaking
  run: |
    cd api
    buf breaking --against '.git#branch=main'
```

### 允许的演进

| 操作 | 是否允许 |
|------|---------|
| 新增 field（新 field number） | ✅ |
| 新增 RPC method | ✅ |
| 新增 enum value | ✅ |
| 修改 field 名（number 不变） | ✅ |
| 删除 field | ❌ buf breaking 阻断 |
| 修改 field number | ❌ buf breaking 阻断 |
| 修改 field 类型 | ❌ buf breaking 阻断 |
| 删除 RPC method | ❌ buf breaking 阻断 |

### 废弃而非删除

```protobuf
message PlaceOrderRequest {
  string symbol = 1;
  // deprecated: use limit_price. Removal planned for v2.
  string price = 3 [deprecated = true];
  string limit_price = 7;  // 新字段使用新编号
}
```

## 8. 代码生成工作流

### 统一生成脚本（repo root）

```bash
# scripts/gen-proto.sh
#!/bin/bash
set -e
cd "$(git rev-parse --show-toplevel)/api"
buf generate
echo "✓ proto generation complete"
```

**一条命令，所有服务的桩文件同时刷新：**

```bash
# 在 repo root 执行
./scripts/gen-proto.sh
```

输出结果：
- `services/*/src/internal/gen/` — 各服务的 Go 生成类型（gitignore）
- `docs/openapi/` — OpenAPI JSON（gitignore，Mobile/Web 消费入口）

### 各服务 Makefile（可选，便于单服务开发）

```makefile
# services/{name}/Makefile
.PHONY: proto proto-check

proto:
	cd ../../ && ./scripts/gen-proto.sh

proto-check:
	cd ../../api && buf breaking --against '.git#branch=main'
	cd ../../api && buf lint
```

### CI 流水线

```yaml
# .github/workflows/proto-check.yml
- name: buf lint
  run: cd api && buf lint

- name: buf breaking
  run: cd api && buf breaking --against '.git#branch=main'

- name: buf generate（验证生成产物与提交一致）
  run: |
    ./scripts/gen-proto.sh
    git diff --exit-code services/*/src/internal/gen/ docs/openapi/
    # 如有 diff 说明 proto 改了但没重新生成，CI 报错
```

> **注意**：CI 里 `git diff --exit-code` 检查的前提是 `internal/gen/` 和 `docs/openapi/` **提交到 git**（CI 验证场景）。本地开发这两个目录 gitignore，按需运行 `./scripts/gen-proto.sh` 重新生成。两种策略都可行，团队选择其一并在此处更新说明。

## 9. common/v1 共享类型与治理规则

`api/common/v1/` 存放跨服务共享的**值类型**（不含业务逻辑）：

```protobuf
// api/common/v1/money.proto
message Money {
  string amount   = 1;  // string decimal，如 "123.45"
  string currency = 2;  // ISO 4217，如 "USD"、"HKD"
}

// api/common/v1/pagination.proto
message PageRequest {
  int32 page = 1;
  int32 size = 2;  // max 100
}
message PageResponse {
  int32 page  = 1;
  int32 size  = 2;
  int64 total = 3;
}
```

### 准入规则：什么可以进 common/v1

**必须同时满足以下全部条件才能加入 common/v1：**

| 条件 | 说明 |
|------|------|
| 跨 **3 个及以上**服务使用 | 1–2 个服务重复，在各自 proto 里冗余即可，不抽取 |
| 纯值类型 | 无状态、无行为、无业务规则；仅描述"是什么"，不描述"怎么做" |
| 无服务归属 | 不属于任何单个业务域（否则放该域的 proto） |
| 语义稳定 | 预期基本不变更；频繁变更的类型放各自服务，避免牵连所有消费方 |

### 禁止放入 common/v1 的内容

| 类型 | 原因 | 正确位置 |
|------|------|---------|
| 业务实体（`Order`、`Account`、`Position`） | 归属明确，属于对应服务域 | `api/{service}/v1/` |
| 状态枚举（`OrderStatus`、`KYCStatus`） | 状态机演进由各服务自主控制；放 common 会强耦合 | `api/{service}/v1/` |
| 跨域计算结果（`RiskLevel`、`SettlementResult`） | 含业务语义，随业务规则变化 | 产出域的 proto |
| 错误码 | 每个服务的错误域独立，见 §3 | `api/{service}/v1/errors.proto` |
| 服务配置或请求上下文（`AuthContext`、`TenantInfo`） | 属于横切关注点，通过 gRPC metadata 或 middleware 传递，不进消息体 | 中间件层 |

### 变更治理

- **新增字段**：field number append-only，`buf breaking` CI 自动门控
- **新增 message**：需在 PR 描述中说明"被哪些服务使用"，reviewer 验证是否满足准入规则
- **删除/重命名**：`common/v1` 的删除影响所有消费方——必须走废弃流程（`[deprecated = true]` + 至少一个迭代周期的过渡期）
- **Owner**：`common/v1` 变更需 **sdd-expert** + 至少一个受影响服务的 engineer review，不得单方面修改

## 10. 参考资料

| 资源 | 说明 |
|------|------|
| `docs/specs/platform/go-service-architecture.md` | Go 服务架构总规范 |
| `docs/specs/platform/kafka-topology.md` | Kafka 拓扑规范 |
| `docs/contracts/` | 服务间接口契约文档 |
| `docs/openapi/` | 由 `buf generate` 派生的 OpenAPI JSON（只读，Mobile/Web 消费入口） |
| [buf.build](https://buf.build) | Proto 工具链（lint、breaking 检测、代码生成） |
| [Kratos proto guide](https://go-kratos.dev/docs/guide/api-protobuf/) | Kratos HTTP/gRPC binding 与错误码生成 |
| [protoc-gen-openapiv2](https://github.com/grpc-ecosystem/grpc-gateway/tree/main/protoc-gen-openapiv2) | proto → OpenAPI 生成插件 |
| [openapi-generator-cli](https://openapi-generator.tech/) | OpenAPI → Dart client 生成（Flutter 消费方） |
| [openapi-typescript](https://openapi-ts.dev/) | OpenAPI → TypeScript 类型生成（Admin Panel 消费方） |
| [orval](https://orval.dev/) | OpenAPI → TypeScript + React Query hooks 生成（Admin Panel 可选） |
| `.claude/agents/go-scaffold-architect.md` | 脚手架 agent（执行层） |
