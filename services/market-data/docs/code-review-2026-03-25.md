# Market Data Service — 2/8 链路修复记录

**日期**: 2026-03-25
**执行角色**: market-data-engineer
**触发方式**: 2/8 法则 Review — 20% 核心流程闭环 vs 80% 业务场景覆盖

---

## 背景

对整条行情链路（Feed → UpdateQuote → Cache/Outbox → Kafka → WS → Client）进行了完整的 2/8 Review，识别出：
- **4 个 P0 流程断链**：导致行情数据不完整、WS 推送不工作、K 线无数据
- **8 个 P2/P3 缺陷**：并发安全、性能、数据语义等问题

HK feed 接入问题搁置，其余全部修复。

---

## 修复清单

### Wave 1 — 快速修复

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W1-A | WebSocket 并发写 data race：`wsClient` 缺 `writeMu`，`BroadcastQuote`/`sendJSON` 未加写锁；`HandleWebSocket` 用 `<-make(chan struct{})` 永久阻塞 | `internal/server/websocket.go` | ✅ |
| W1-B | Outbox DLQ writer 与 main writer 复用同一实例，Kafka 故障时 DLQ 也无法写入 | `internal/kafka/outbox/worker.go`、`cmd/server/wire_gen.go` | ✅ |
| W1-C | Feed buffer 满时静默丢弃 quote，无可观测指标 | `pkg/observability/metrics.go`、`internal/feed/massive.go` | ✅ |
| W1-D | Hot search `IncrementScore` 传的是第一个结果的 symbol，应传查询词 query | `internal/search/usecase.go` | ✅ |
| W1-E | JWT 验证是纯结构检查（3 段），无安全警告注释 | `pkg/httputil/response.go`、`internal/server/websocket.go` | ✅ |

### Wave 2 — Change/ChangePct 计算链路

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W2 | `mapToQuote` 不设置 `Change`/`ChangePct`/`PrevClose`，REST API 返回 `"change":"0"` | `domain/entity.go`（新增 `ApplyChange`）、`domain/repo.go`（新增 `FindPrevClose`）、`infra/mysql/repo.go`（查 1D kline 表前日收盘）、`app/update_quote.go` | ✅ |

### Wave 3 — Delayed Quote Ring Buffer

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W3 | Guest 用户的 `delayed=true` 只是 flag，数据本身是实时的，违反 Spec §10 | `infra/redis/delayed_ring.go`（新建，Redis Sorted Set T-15min 快照）、`domain/repo.go`（新增 `QuoteDelayedRepo` 接口）、`app/update_quote.go`（Push）、`app/get_quote.go`（GetDelayed 路径）、`handler.go`（传 delayed flag） | ✅ |

### Wave 4 — Kafka Consumer → WebSocket Push 闭环

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W4-A | `BroadcastQuote` 存在但零调用方，WS 推送完全不工作 | `internal/kafka/consumer/quote.go`（新建，订阅 `market-data.quotes.us/hk`） | ✅ |
| W4-B | `WSServer` 被创建但未启动，未注入 App | `cmd/server/app.go`、`cmd/server/wire_gen.go` | ✅ |
| W4-C | Subscribe 后无初始快照，客户端要等下一次 feed tick 才能看到数据 | `internal/server/websocket.go`（`pushInitialSnapshots` via `cacheRepo.MGet`） | ✅ |

### Wave 5 — K-line 触发机制

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W5 | `AggregateKLineUsecase` 存在但无触发点，K 线表永远没有数据 | `internal/kline/accumulator.go`（新建）、`internal/kline/scheduler.go`（新建，分钟边界触发多周期聚合）、`internal/feed/worker.go`（接入 TickAccumulator）、`cmd/server/app.go`/`wire_gen.go` | ✅ |

### Wave 6 — MarketStatus 调度器

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W6 | `SetStatus` 方法从未被调用，市场状态永远是初始值，不随交易时段变化 | `internal/quote/app/market_scheduler.go`（新建，ET/HKT 时区 + 含 LunchBreak + 周末判断）、`cmd/server/app.go`/`wire_gen.go` | ✅ |

### Wave 7 — 性能优化

| 编号 | 问题 | 改动文件 | 状态 |
|------|------|----------|------|
| W7-A | `handleGetQuotes` 对 50 个 symbol 串行发 50 次 Redis GET | `app/get_quote.go`（新增 `ExecuteBatch` via `MGet`）、`handler.go` | ✅ |
| W7-B | Dedup 每次 tick 打 MySQL 查询，高频场景性能瓶颈 | `domain/repo.go`（新增 `IsDedup` 到 `QuoteCacheRepo`）、`infra/redis/cache.go`（Redis SET NX）、`app/update_quote.go` | ✅ |

---

## 新增文件

| 文件 | 说明 |
|------|------|
| `internal/kafka/consumer/quote.go` | Kafka consumer，订阅 US/HK quote 主题，调 `WSServer.BroadcastQuote` |
| `internal/kline/accumulator.go` | TickAccumulator，per-symbol 内存 buffer |
| `internal/kline/scheduler.go` | KLineScheduler，分钟对齐触发多周期 flush |
| `internal/quote/app/market_scheduler.go` | MarketScheduler，基于交易所日历自动维护 US/HK 市场状态 |
| `internal/quote/infra/redis/delayed_ring.go` | DelayedRingBuffer，Redis Sorted Set 实现 T-15min 快照 |

---

## 接口变更（破坏性）

| 接口/函数 | 变更 |
|-----------|------|
| `domain.QuoteRepo` | 新增 `FindPrevClose(ctx, symbol, market) (decimal.Decimal, error)` |
| `domain.QuoteCacheRepo` | 新增 `IsDedup(ctx, symbol, market, tsMicro) (bool, error)` |
| `domain.QuoteDelayedRepo` | 新增接口 `{ Push / GetDelayed }` |
| `app.NewGetQuoteUsecase` | 新增参数 `delayedRepo domain.QuoteDelayedRepo`（第 4 位，可传 nil） |
| `app.GetQuoteUsecase.Execute` | 新增参数 `delayed bool`（第 4 位） |
| `app.NewUpdateQuoteUsecase` | 新增参数 `delayedRepo domain.QuoteDelayedRepo`（第 6 位，可传 nil） |
| `server.NewWSServer` | 新增参数 `cacheRepo domain.QuoteCacheRepo`（第 2 位，可传 nil） |
| `outbox.NewWorker` | 新增参数 `dlqWriter *kafka.Writer`（第 3 位，可传 nil） |
| `feed.NewWorker` / `ProvideWorker` | 新增参数 `tickAcc *kline.TickAccumulator`（第 3 位，可传 nil） |

---

## 验证结果

```
go build ./...     → 编译通过，无错误
go test ./... -short → 12 个包全绿，零失败
```

---

## 遗留问题（待后续处理）

| 问题 | 说明 |
|------|------|
| HK feed 接入 | `feed/massive.go` 硬编码 `MarketUS`，HKEX client 存在但未接入，本次搁置 |
| JWT RS256 验证 | 需集成 AMS 公钥，目前仍为结构检查 stub（已加生产警告注释） |
| WS 推送 Protobuf | 当前 consumer 推送 JSON，TODO 改为 Protobuf binary frame |
| Outbox at-least-once | `MarkPublished` 失败时存在重复推 Kafka 的风险，需消费侧幂等键 |
| 1W / 1M K-line | KLineScheduler 目前不触发周/月聚合（需日历边界检测），`Interval1D` 每日 00:00 UTC 触发 |
