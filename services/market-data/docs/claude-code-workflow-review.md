---
type: review-report
level: L3
status: ACTIVE
date: 2026-03-22
reviewer: opencode
target: services/market-data
reference_workflow: docs/specs/platform/feature-development-workflow.md
---

# Market Data Claude Code 工作流审查

## 1. 审查范围与方法

本次审查按 `docs/specs/platform/feature-development-workflow.md` 的顺序执行，覆盖：

- 服务内文档：`docs/README-INDEX.md`、`docs/specs/*.md`
- 实施跟踪：`docs/specs/market-data-implementation.tracker.md`
- 跨域契约：`../../docs/contracts/market-data-to-mobile.md`、`../../docs/contracts/market-data-to-trading.md`、`../../docs/contracts/market-data-to-admin.md`
- 契约代码：`../../api/market_data/v1/market_data.proto`、`../../api/events/v1/market_events.proto`
- 实现代码：`src/**`
- Step 1 评审证据：`../../mobile/docs/threads/2026-03-prd-03-market-data-review/_index.md`

执行过的非变更验证：

- `cd src && go test ./internal/quote/domain ./internal/quote/app ./internal/kline ./internal/watchlist`：通过
- `cd src && go test ./...`：失败；失败点集中在 Redis/MySQL integration tests 依赖本地 `127.0.0.1:6379` / `127.0.0.1:3306`
- `find docs -maxdepth 2 -type f \( -name 'active-features.yaml' -o -name 'patches.yaml' \)`：无结果
- `find ../../docs/openapi -maxdepth 2 -type f`：无结果

## 2. 总体结论

### 已完成或基本符合的部分

- **Step 1 / PRD Tech Review**：存在已关闭的 heavyweight thread，`../../mobile/docs/threads/2026-03-prd-03-market-data-review/_index.md:1` 可作为 Step 1 证据。
- **Step 1.5 / canonical proto 落位**：根目录已存在 `../../api/market_data/v1/market_data.proto:1` 和 `../../api/events/v1/market_events.proto:1`。
- **部分单元测试**：领域层和部分应用层测试可运行。

### 主要问题

- Step 1.5 产物未达到 workflow 要求，contract/status/openapi/source-of-truth 仍不完整。
- Step 2 没有形成 workflow 定义的 Tech Spec，现有文档仍是历史架构文档 + scaffold 占位。
- Tracker、管理文件、phase 验收记录与代码事实存在多处冲突。
- Transport Layer 和集成验收并未完成，但 tracker 已给出大量 completed/pass 结论。

## 3. 逐步审查结果

## Step 1 - PRD Tech Review

### 结论

- **通过**：Step 1 有 thread 证据，且 `_index.md` 显示已于 2026-03-20 关闭，见 `../../mobile/docs/threads/2026-03-prd-03-market-data-review/_index.md:1`。
- **未单列问题**：本轮未发现 Step 1 自身阻塞项，但其结论在后续 Step 1.5/Step 2 没有完全闭环。

## Step 1.5 - Contract Definition

### MD-REV-001 [Blocking] Contract 状态和必备字段不符合 workflow

- 发现：
  - 三份 contract 都使用 `status: ACTIVE`，未体现 workflow 要求的 `APPROVED` 状态。
  - SLA 仍为 `TBD`，changelog 仍为“暂无变更记录”，不满足“接口清单 + SLA + 变更历史”的最小要求。
- 证据：
  - `../../docs/contracts/market-data-to-mobile.md:7`
  - `../../docs/contracts/market-data-to-mobile.md:25`
  - `../../docs/contracts/market-data-to-mobile.md:65`
  - `../../docs/contracts/market-data-to-trading.md:7`
  - `../../docs/contracts/market-data-to-trading.md:23`
  - `../../docs/contracts/market-data-to-trading.md:42`
  - `../../docs/contracts/market-data-to-admin.md:6`
  - `../../docs/contracts/market-data-to-admin.md:22`
  - `../../docs/contracts/market-data-to-admin.md:51`
- 影响：
  - Step 1.5 不能算完成，Step 2 前置条件不成立。
  - consumer 无法基于 contract 判断接口是否已 review/可并行开发。
- 建议修复：
  - 将三份 contract 补齐 SLA、版本变更记录和 review 结论。
  - 统一改为 workflow 认可的 approved 状态语义。

### MD-REV-002 [Blocking] OpenAPI 产物缺失，Step 1.5 未闭环

- 发现：
  - contracts 都指向 `docs/openapi/market_data/`，但仓库中没有任何 openapi 产物。
- 证据：
  - `../../docs/contracts/market-data-to-mobile.md:5`
  - `../../docs/contracts/market-data-to-admin.md:5`
  - `find ../../docs/openapi -maxdepth 2 -type f` 返回空结果（2026-03-22）
- 影响：
  - Mobile/Web contract 无法按 workflow 使用 OpenAPI 作为并行开发输入。
- 建议修复：
  - 生成并校验 `docs/openapi/market_data.*`，或从 contract 中移除未兑现的产物声明。

### MD-REV-003 [Major] Proto source-of-truth 混乱，design draft 未清理

- 发现：
  - 根目录已经有 canonical proto，但服务内仍保留一份 `docs/specs/api/grpc/market_data.proto`，文件头明确写着“设计草稿”“正式 canonical 文件将在 Step 1.5 创建”。
- 证据：
  - `../../api/market_data/v1/market_data.proto:1`
  - `docs/specs/api/grpc/market_data.proto:1`
  - `docs/specs/api/grpc/market_data.proto:3`
  - `docs/specs/api/grpc/market_data.proto:10`
- 影响：
  - reader 很难判断应以哪份 proto 为准。
  - 文档和实现容易继续引用过期草稿。
- 建议修复：
  - 明确根目录 `api/` 为唯一 canonical source。
  - 将服务内草稿删除、归档，或只保留对 canonical proto 的引用。

### MD-REV-004 [Major] Mobile/Admin contracts 仍是占位版，且与现行 spec 不一致

- 发现：
  - mobile contract 仍使用旧 REST 路径，如 `/api/v1/quotes/:symbol`、`/api/v1/stocks/search`，与现行 API spec 的 `/v1/market/*` 不一致。
  - mobile contract 仍允许 WebSocket “query param 或首条消息传 token”，而 `websocket-spec` 已要求连接后 5 秒内通过消息 `auth`。
  - admin contract 仍是“初始占位”，未填充具体 schema。
- 证据：
  - `../../docs/contracts/market-data-to-mobile.md:27`
  - `../../docs/contracts/market-data-to-mobile.md:30`
  - `../../docs/contracts/market-data-to-mobile.md:53`
  - `docs/specs/market-api-spec.md:26`
  - `docs/specs/market-api-spec.md:139`
  - `docs/specs/websocket-spec.md:79`
  - `../../docs/contracts/market-data-to-admin.md:29`
- 影响：
  - contract 无法作为 consumer 的真实对接依据。
  - Step 1.5 虽有文件，但内容仍停留在 draft 占位阶段。
- 建议修复：
  - 以 `market-api-spec.md` 和 `websocket-spec.md` 为准重写 mobile/admin contracts。
  - 删除“待实现阶段填充”的描述，填入实际 endpoint、schema、认证方式和 SLA。

## Step 2 - Tech Spec

### MD-REV-005 [Blocking] 当前不存在符合 workflow 模板的 Tech Spec

- 发现：
  - 主文档 `docs/specs/market-data-system.md` frontmatter 是 `type: domain-spec`，没有 workflow 要求的 `level`、`implements`、`contracts`、`depends_on`、`code_paths`。
  - 文档结构是历史架构说明，不是 workflow Step 2 要求的 Tech Spec 模板。
- 证据：
  - `docs/specs/market-data-system.md:1`
  - `docs/specs/market-data-system.md:2`
  - `docs/specs/market-data-system.md:6`
  - `docs/specs/market-data-system.md:18`
- 影响：
  - Step 2 不成立，后续 Phase 验收无法对照统一 spec。
  - 代码与文档之间缺少可追溯的 section-to-code 关系。
- 建议修复：
  - 新建或重构为 workflow 定义的 L3 Tech Spec。
  - 把当前 `market-data-system.md` 中有价值的架构内容迁入 Tech Spec 对应章节。

### MD-REV-006 [Blocking] `service-overview.md` 和 `business-rules.md` 仍是 scaffold，占位未落地

- 发现：
  - `service-overview.md` 仅有 frontmatter 和 `FILL` 注释。
  - `business-rules.md` 仅有 `FILL` 注释，没有不变量、状态转换、计算规则落文。
- 证据：
  - `docs/specs/service-overview.md:11`
  - `docs/specs/service-overview.md:23`
  - `docs/specs/business-rules.md:5`
  - `docs/specs/business-rules.md:10`
- 影响：
  - 业务规则、状态机、流程图没有被正式化。
  - 后续 Domain/Application/Transport 验收缺少依据。
- 建议修复：
  - 完整填充两个 scaffold，至少补齐 workflow 要求的领域模型、状态机、核心流程、异常流程和安全合规章节。

### MD-REV-007 [Major] Step 2 所需的 patch 检查、Phase 拆解、幂等性章节缺失

- 发现：
  - 当前文档体系中没有 workflow 要求的“活跃 Patch 检查”和“§8 Phase 任务拆解”。
  - 也看不到与 workflow 模板一致的幂等性章节。
- 证据：
  - `docs/specs/market-data-system.md:18` 到 `docs/specs/market-data-system.md:36` 的目录不包含上述章节
  - `docs/specs/service-overview.md:21` 到 `docs/specs/service-overview.md:27` 仍为空白
- 影响：
  - 无法做正式 Gap Analysis。
  - 实施阶段只能靠工程师主观判断，不符合 workflow 的“Spec 是合同”要求。
- 建议修复：
  - 在正式 Tech Spec 中补齐 patch 检查、幂等性和 §8 Phase 拆解。

## Tracker 与管理文件

### MD-REV-008 [Blocking] 缺少 `active-features.yaml` 和 `patches.yaml`

- 发现：
  - workflow 要求在 `docs/` 下维护域级仪表盘和 patch registry，但当前两个文件都不存在。
- 证据：
  - `find docs -maxdepth 2 -type f \( -name 'active-features.yaml' -o -name 'patches.yaml' \)` 返回空结果（2026-03-22）
- 影响：
  - 无法按 workflow 汇总 feature 进度、阻塞与补丁负债。
  - Step 2 的“活跃 Patch 检查”也无从执行。
- 建议修复：
  - 新建 `docs/active-features.yaml` 和 `docs/patches.yaml`，并回填当前 feature 信息。

### MD-REV-009 [Blocking] Tracker frontmatter 与正文状态互相矛盾

- 发现：
  - frontmatter 写 `current_phase: 5`、`status: in_progress`，但 `progress.completed: 24` 且 `pending/in_progress/blockers` 全为 0。
  - 正文中 Phase 5 和 Phase 6 仍全部 `pending`。
  - 正文总任务数实际为 35 项，但 frontmatter 只记录 `total: 24`。
- 证据：
  - `docs/specs/market-data-implementation.tracker.md:4`
  - `docs/specs/market-data-implementation.tracker.md:5`
  - `docs/specs/market-data-implementation.tracker.md:11`
  - `docs/specs/market-data-implementation.tracker.md:15`
  - `docs/specs/market-data-implementation.tracker.md:116`
  - `docs/specs/market-data-implementation.tracker.md:128`
- 影响：
  - tracker 失去“动态日志”作用，不能作为 orchestrator 或 reviewer 的可信输入。
- 建议修复：
  - 重新统计总任务数和 phase 状态。
  - 以正文任务状态为准修正 frontmatter。

### MD-REV-010 [Major] Tracker 的验收结论与代码事实冲突

- 发现：
  - Phase 1 明确写“金额字段 DECIMAL(20,8)”并判定 pass，但 workflow 与文档索引都要求 `DECIMAL(20,4)`。
  - Phase 3 “FindByXxx error” 写 pass，证据却是 “Returns nil on not found”；这与 workflow 的“必须返回 domain not found error”正相反。
- 证据：
  - `docs/specs/market-data-implementation.tracker.md:22`
  - `docs/specs/market-data-implementation.tracker.md:37`
  - `docs/README-INDEX.md:97`
  - `docs/specs/market-data-implementation.tracker.md:66`
  - `docs/specs/market-data-implementation.tracker.md:84`
- 影响：
  - tracker 记录的 pass 不能信任。
  - 后续 phase 决策建立在错误验收之上。
- 建议修复：
  - 按 workflow checklist 重做 Phase 1/3 验收，并保留 fail -> fix -> pass 记录链。

## Phase 1 - DB Schema

### MD-REV-011 [Blocking] Migration 违反平台金额字段规则，且与文档约定不一致

- 发现：
  - migration 明确声明价格字段使用 `DECIMAL(20,8)`。
  - `docs/README-INDEX.md` 的统一约定写的是 `DECIMAL(20,4)`。
- 证据：
  - `src/migrations/001_init_market_data.sql:3`
  - `src/migrations/001_init_market_data.sql:12`
  - `src/migrations/001_init_market_data.sql:43`
  - `docs/README-INDEX.md:97`
- 影响：
  - 违反平台 workflow 的 DB 规则。
  - 文档、tracker、DDL 三方口径不一致。
- 建议修复：
  - 明确 market-data 是否获准使用 8 位小数；若没有豁免，按 workflow 改回 `DECIMAL(20,4)` 并补充变更说明。

### MD-REV-012 [Major] 表结构命名和状态字段与现行 spec 漂移

- 发现：
  - migration 使用 `watchlist_items`，但系统设计文档给出的是 `user_watchlist`。
  - `market_status.phase` 注释使用 `OPEN`、`POST_MARKET`、`LUNCH_BREAK`，与当前 API/proto 的 `REGULAR`、`AFTER_HOURS`、`HALTED` 不一致。
- 证据：
  - `src/migrations/001_init_market_data.sql:30`
  - `src/migrations/001_init_market_data.sql:33`
  - `src/migrations/001_init_market_data.sql:72`
  - `docs/specs/market-data-system.md:1681`
  - `docs/specs/market-api-spec.md:74`
  - `../../api/market_data/v1/market_data.proto:31`
- 影响：
  - 领域模型、持久化、对外契约对同一个概念使用了不同枚举和表设计。
- 建议修复：
  - 统一市场状态枚举词汇。
  - 在 Tech Spec 中明确 table naming 和 schema source-of-truth。

## Phase 2 - Domain Layer

### MD-REV-013 [Major] Domain 模型与 contract/API 字段集不一致

- 发现：
  - `domain.Quote` 缺少对外 contract 已要求的 `turnover`、`delayed`、`stale_since_ms`、`market_status` 等字段。
  - `domain.MarketStatus` 仅有 `Phase`，而 gRPC contract 需要 `status`、`session_open`、`session_close`、`as_of`。
- 证据：
  - `src/internal/quote/domain/entity.go:18`
  - `src/internal/quote/domain/entity.go:38`
  - `../../api/market_data/v1/market_data.proto:47`
  - `../../api/market_data/v1/market_data.proto:101`
- 影响：
  - Transport 层即使实现，也无法直接从当前 domain 模型完整映射到 contract。
- 建议修复：
  - 先在正式 Tech Spec 中收敛领域对象与 DTO 的边界。
  - 明确哪些字段属于 domain，哪些属于 transport DTO。

### MD-REV-014 [Major] 市场状态枚举仍停留在旧词汇

- 发现：
  - domain 使用 `OPEN`、`POST_MARKET`、`LUNCH_BREAK`，与当前 API spec / proto 的 `REGULAR`、`AFTER_HOURS`、`HALTED` 不一致。
- 证据：
  - `src/internal/quote/domain/entity.go:45`
  - `src/internal/quote/domain/entity.go:50`
  - `src/internal/quote/domain/entity.go:52`
  - `docs/specs/market-api-spec.md:74`
  - `../../api/market_data/v1/market_data.proto:33`
- 影响：
  - 同一状态在 domain 和 contract 之间无法稳定映射。
- 建议修复：
  - 统一枚举词汇；如果内部仍需不同命名，要在 Tech Spec 中定义明确映射。

## Phase 3 - Infrastructure Layer

### MD-REV-015 [Major] Repository not-found 语义不符合 workflow

- 发现：
  - `QuoteRepository.FindBySymbol` 和 `MarketStatusRepository.GetStatus` 都在 not found 时返回 `nil, nil`。
  - tracker 也把这类行为写成 pass。
- 证据：
  - `src/internal/quote/infra/mysql/repo.go:36`
  - `src/internal/quote/infra/mysql/repo.go:41`
  - `src/internal/quote/infra/mysql/repo.go:73`
  - `src/internal/quote/infra/mysql/repo.go:78`
  - `docs/specs/market-data-implementation.tracker.md:84`
- 影响：
  - 不符合 workflow 对 Phase 3 的验收要求。
  - 上层 usecase 只能自行拼接 not found 文本错误，错误码映射会继续漂移。
- 建议修复：
  - 在 domain 定义 not-found 错误，并让 repo 统一返回该错误。

## Phase 4 - Application Layer

### MD-REV-016 [Major] Outbox metadata 只完成了“存字段”，未完成 workflow 要求的语义

- 发现：
  - `correlation_id` 目前直接回退为 `event_id`，并未从 context/trace 中提取。
  - `event_type` 从 topic 最后一段推导，`brokerage.market-data.quote.updated` 会得到 `Updated.v1`，与 migration 注释示例 `QuoteUpdated.v1` 不一致。
- 证据：
  - `src/internal/quote/infra/mysql/repo.go:123`
  - `src/internal/quote/infra/mysql/repo.go:126`
  - `src/internal/quote/infra/mysql/repo.go:173`
  - `src/internal/quote/infra/mysql/repo.go:179`
  - `src/migrations/002_add_outbox_metadata.sql:7`
  - `src/internal/kafka/producer/quote.go:6`
- 影响：
  - tracker 中“EventEnvelope 完整”属于高估。
  - 后续消费者和审计系统无法稳定依赖 event metadata。
- 建议修复：
  - 从 ctx 中提取 trace/correlation id。
  - 显式定义 event_type 常量，不要从 topic 名猜测。

### MD-REV-017 [Minor] 非致命 cache 错误被吞掉，未形成可观测证据

- 发现：
  - `UpdateQuoteUsecase` 在 cache 写入失败时只是构造错误对象后丢弃，没有日志输出。
- 证据：
  - `src/internal/quote/app/update_quote.go:92`
  - `src/internal/quote/app/update_quote.go:97`
- 影响：
  - 运行中 cache 退化不可观测。
- 建议修复：
  - 使用 logger 记录 warn/error，并附 symbol、operation 等上下文。

### MD-REV-018 [Major] Watchlist 业务规则未在应用层落实

- 发现：
  - 当前 `AddToWatchlistUsecase` 只校验空 symbol，没有执行“每用户最多 100 只”“重复添加幂等返回 200”等规则。
- 证据：
  - `docs/README-INDEX.md:104`
  - `docs/specs/market-data-system.md:1492`
  - `docs/specs/market-data-system.md:1496`
  - `docs/specs/market-data-system.md:1699`
  - `src/internal/watchlist/usecase.go:38`
  - `src/internal/watchlist/usecase.go:41`
- 影响：
  - Phase 4 的核心业务规则尚未实现。
- 建议修复：
  - 为 watchlist 增加 count/idempotency 逻辑与领域错误定义。

## Phase 5 - Transport Layer

### MD-REV-019 [Blocking] HTTP Transport 与 API spec 大范围漂移

- 发现：
  - 路径仍是 `/api/v1/*`，而现行 API spec 统一为 `/v1/*` / `/v1/market/*`。
  - quote handler 只实现了单标的 `/api/v1/quote`，而 API spec 的主入口是批量 `/v1/market/quotes`。
  - search handler 是 `/api/v1/search`，而 API spec 是 `/v1/market/search`。
  - kline handler 是 `/api/v1/kline`，而 API spec 是 `/v1/market/kline`。
- 证据：
  - `docs/specs/market-api-spec.md:26`
  - `docs/specs/market-api-spec.md:139`
  - `src/internal/quote/handler.go:29`
  - `src/internal/kline/handler.go:21`
  - `src/internal/search/handler.go:24`
  - `src/internal/watchlist/handler.go:30`
- 影响：
  - 当前 HTTP 实现不能被视为 Phase 5 已对齐 contract/spec。
- 建议修复：
  - 以 API spec 为准重建 routing 和 DTO。
  - 先补齐 batch quotes、market search、market stocks 等主入口。

### MD-REV-020 [Blocking] HTTP handler 仍直接暴露 domain 对象，且错误映射不符合要求

- 发现：
  - quote handler 直接返回 `domain.Quote`，但该结构不包含 contract/API 所需字段集。
  - not found 被包装成普通 error，handler 统一走 500，没有按 404/401/400 等 spec 进行映射。
  - watchlist 仍通过 query/body 传 `user_id`，没有 JWT claim 提取；代码里也明确写着 `FILL`。
- 证据：
  - `src/internal/quote/handler.go:42`
  - `src/internal/quote/handler.go:55`
  - `src/internal/quote/app/get_quote.go:48`
  - `src/internal/watchlist/handler.go:43`
  - `src/internal/watchlist/handler.go:50`
  - `src/internal/watchlist/handler.go:71`
  - `docs/specs/market-api-spec.md:45`
  - `docs/specs/market-api-spec.md:80`
- 影响：
  - handler 未达到 workflow 对“输入校验 -> usecase -> DTO/错误码映射”的要求。
- 建议修复：
  - 为 transport 层定义独立 request/response DTO。
  - 为 domain/application error 建立 HTTP/gRPC 映射表。
  - 用 JWT claims 替换临时 `user_id` 参数。

### MD-REV-021 [Blocking] gRPC Transport 仍是 health-only stub

- 发现：
  - gRPC server 只注册了 health service，文件注释仍写着“FILL: register proto-generated service implementations”。
- 证据：
  - `src/internal/server/grpc.go:19`
  - `src/internal/server/grpc.go:27`
  - `src/internal/server/grpc.go:31`
- 影响：
  - trading contract 虽有 proto，但服务端并未真正暴露 `MarketDataService`。
- 建议修复：
  - 先实现并注册 `GetQuote` / `GetMarketStatus`。

### MD-REV-022 [Blocking] WebSocket Gateway 仍是 stub，且路由与协议都未对齐

- 发现：
  - WebSocket route 仍是 `/ws`，而协议文档写的是 `/ws/market`。
  - auth/subscribe/reauth/subprotocol/origin 限制都未实现，代码中保留多个 `FILL`。
  - 当前 broadcast 还是全量 fan-out，没有 symbol 级订阅过滤。
- 证据：
  - `docs/specs/websocket-spec.md:44`
  - `docs/specs/websocket-spec.md:79`
  - `src/internal/server/websocket.go:31`
  - `src/internal/server/websocket.go:42`
  - `src/internal/server/websocket.go:68`
  - `src/internal/server/websocket.go:87`
  - `src/internal/server/websocket.go:99`
- 影响：
  - Phase 5 中最关键的双轨推送能力尚未进入可验收状态。
- 建议修复：
  - 先对齐连接地址、subprotocol、消息认证和订阅模型，再补 delayed/registered 双轨逻辑。

### MD-REV-023 [Major] `/ready` 仍是占位实现

- 发现：
  - readiness endpoint 没有检查 DB/Redis/Kafka，仅返回固定 `ok`。
- 证据：
  - `src/internal/server/http.go:81`
  - `src/internal/server/http.go:82`
- 影响：
  - 运维上会误报可用，集成验收也无法据此判断依赖是否就绪。
- 建议修复：
  - 将 DB 和 Redis 连通性纳入 ready 检查，必要时增加 Kafka/outbox worker 状态。

## Phase 6 - Integration Verification

### MD-REV-024 [Major] 集成验收尚未完成，但 tracker 没有体现真实前置条件与证据

- 发现：
  - 默认 `go test ./...` 不能通过；integration tests 依赖 docker-compose 中的 MySQL/Redis。
  - search integration tests 的文件头写“Run with `-tags=integration`”，但文件本身没有 build tag，默认全量测试仍会执行。
  - tracker 却将 Phase 3 的 integration tests 记为 completed，且没有记录运行前置条件或失败历史。
- 证据：
  - `src/internal/quote/infra/redis/cache_integration_test.go:2`
  - `src/internal/quote/infra/redis/cache_integration_test.go:5`
  - `src/internal/search/repo_integration_test.go:3`
  - `src/internal/search/repo_integration_test.go:5`
  - `cd src && go test ./...` 在 2026-03-22 失败，失败包为 `internal/quote/infra/redis` 与 `internal/search`
- 影响：
  - “Phase 3/6 已具备集成证据”的结论目前不成立。
- 建议修复：
  - 给 integration tests 加明确的 build tag 或 CI profile。
  - 在 tracker 中补充真实验证命令、前置依赖和失败 -> 修复 -> 通过记录。

## 4. 其他文档一致性问题

### MD-REV-025 [Minor] 文档版本和索引内容自相矛盾

- 发现：
  - `README-INDEX.md` 上半段宣称 `market-api-spec.md` 和 `data-flow.md` 是 `v2.1`，但对应文件 frontmatter 仍是 `v2.0`。
  - `README-INDEX.md` 从第 137 行开始还重复了一套旧版内容。
- 证据：
  - `docs/README-INDEX.md:17`
  - `docs/README-INDEX.md:20`
  - `docs/README-INDEX.md:137`
  - `docs/specs/market-api-spec.md:3`
  - `docs/specs/data-flow.md:3`
- 影响：
  - 新加入的工程师会被文档索引误导。
- 建议修复：
  - 清理重复内容，统一版本号和发布日期。

## 5. 修复优先级建议

1. **先修流程阻塞项**
   - MD-REV-001 / 002 / 005 / 006 / 008 / 009 / 019 / 021 / 022
2. **再修 spec-code 漂移**
   - MD-REV-003 / 004 / 011 / 012 / 013 / 014 / 015 / 016 / 018 / 020
3. **最后修验收与文档一致性**
   - MD-REV-017 / 023 / 024 / 025

## 6. 审查结论

当前 `services/market-data` 已经有一批文档、proto 和代码雏形，但**还不能算按 workflow 完成了一轮“Contract First -> Spec Second -> Code Third -> Test Against Spec”的闭环**。最大问题不是“完全没有做”，而是：

- Step 1.5 产物看起来存在，但未达到可对接状态；
- Step 2 缺少真正的 Tech Spec；
- tracker 记录和代码事实存在明显偏差；
- Transport 和集成验收仍处于半成品/占位状态。

建议先修文档与 tracker 的 source-of-truth，再继续推进代码收敛，否则后续 review 和验收会持续失真。
