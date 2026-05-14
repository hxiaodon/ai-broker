# Market Data 模块审计报告 (2026-05-08)

**日期**: 2026-05-08
**执行角色**: code-reviewer (delegated)
**触发方式**: 全栈设计与实现审计 — 在 2026-03-25 Wave 1-7 修复之后挖未识别问题
**基线**: `go build` 通过、`go vet` 无警告、`go test -short` 全绿（注意：short 模式用 mock，P0-1/P0-2 在真实 MySQL 下必然报错）

---

## 摘要

| 严重度 | 数量 | 说明 |
|--------|------|------|
| P0 阻断 | 4 | 数据正确性 / 合规 / DB 不一致 |
| P1 严重 | 6 | 功能缺陷 / 可观测性 / 关机数据丢失 / 越权 |
| P2 设计味道 | 5 | 跨域边界 / deprecated API / 调度边界错误 |
| P3 优化 | 3 | 错误码 / readiness probe / 微优化 |

---

## P0（必须立刻修）

### 1. `FindPrevClose` 列名/缺列错配
**文件**: `internal/quote/infra/mysql/repo.go:81-105`

裸 SQL 查 `klines.close / interval / market`，但 DDL 实际是 `close_price / interval_type`，且 `klines` 表**根本没有 `market` 列**。

**影响**: 所有行情 `change` / `change_pct` 永远为 0，W2 修复对线上无效。
**附带**: QuoteRepo 跨域查 kline 表（见 P2-11）。

**建议**:
1. 在 `klines` 表增加 `market` 列（migration v2）或在 KLine 域模型加入 Market 字段。
2. 修改查询: `Select("close_price")`, `Where("... AND interval_type = ? ...")`, `Pluck("close_price", &closePrice)`。

---

### 2. `outbox_events` DDL ↔ INSERT 字段不一致，Outbox 链路死掉
**文件**: `migrations/001_init_market_data.sql:84-93` vs `internal/quote/infra/mysql/repo.go:174` & `internal/kafka/outbox/worker.go:45-54`

migration 的 `outbox_events` 表只有 `(id, topic, payload, status, created_at, published_at, retry_count)`，**没有 `event_id`、`event_type`、`correlation_id` 列**。但 `InsertEvent` SQL 包含这三列：
```go
"INSERT INTO outbox_events (event_id, event_type, correlation_id, topic, payload, status, created_at) ..."
```

**影响**: Feed→Outbox→Kafka→WS push 在真 DB 上完全跑不通；W4-A 修复无法验收。
**建议**: migration v2 补齐：
```sql
event_id       VARCHAR(36)   NOT NULL COMMENT 'UUID v4',
event_type     VARCHAR(100)  NOT NULL,
correlation_id VARCHAR(64)   NULL,
```
同时确认 `status ENUM` 是否需加入 `RETRY` 值（worker 中设置了 PENDING 重试）。

---

### 3. WS 对 Guest 推实时数据，违反数据 license
**文件**: `internal/server/websocket.go:273-285`, `internal/kafka/consumer/quote.go:128`

`BroadcastQuote(symbol, data)` 将同一份 Kafka 消息（实时行情）推给所有订阅该 symbol 的客户端，**不区分 `userType == "guest"` 还是 `"registered"`**。

违反 CLAUDE.md §10：Guest delayed quotes — must label every price with "Delayed 15 min"; implement via DelayedQuoteRingBuffer。

**影响**: 合规/法律风险，Polygon 标准 key 不可分发实时数据，可能触发合同终止。
**建议**: `BroadcastQuote` 拆双轨：注册推实时；guest 走 `delayedRingBuffer.GetDelayed` 取 T-15min 快照 + `"delayed":true` 标记。

---

### 4. Feed 热路径用 `decimal.NewFromFloat`，浮点精度污染
**文件**: `internal/feed/massive.go:101-104`

```go
Price: decimal.NewFromFloat(agg.Close),
Open:  decimal.NewFromFloat(agg.Open),
High:  decimal.NewFromFloat(agg.High),
Low:   decimal.NewFromFloat(agg.Low),
```

Polygon SDK 给的是 `float64`，`decimal.NewFromFloat(150.05)` 实际存 `150.04999...`。违反 `.claude/rules/financial-coding-standards.md` Rule 1（CRITICAL）。

**影响**: 错误价格写入 MySQL/Redis，downstream Change/ChangePct/K线 OHLCV 全部受污染。
**建议**: 改 `decimal.NewFromString(strconv.FormatFloat(agg.Close, 'f', -1, 64))`，或要求 SDK 提供字符串格式字段。

---

## P1（功能/可观测性/安全）

### 5. Prometheus 指标只注册不 emit
**文件**: `pkg/observability/metrics.go:11,34`

5 个标准指标中：
- ✅ `KafkaConsumed` (consumer/quote.go:115)
- ✅ `ActiveConns` (websocket.go:261)
- ✅ `DroppedQuotes` (feed/massive.go:77)
- ❌ `RequestDuration` 全仓 0 调用
- ❌ `DBQueryDuration` 全仓 0 调用
- ❌ `KafkaPublished` 全仓 0 调用

**影响**: SLO / 告警直接哑火。
**建议**: HTTP middleware 中 `defer` 包装 emit `RequestDuration`；MySQL repo 关键查询前后 emit `DBQueryDuration`；outbox `publishEvent` 成功后 emit `KafkaPublished`。

---

### 6. `app.Stop()` 不等后台 goroutine 退出
**文件**: `cmd/server/app.go:117-129`

`Stop()` 仅 `cancel()` + `httpSrv.Stop()` + `grpcSrv.Stop()`，**不等待** feedWorker / outboxWorker / quoteConsumer / klineScheduler / marketScheduler 这五个 goroutine 真正退出。

**影响**: 滚动发布时 outbox 事务可能截断、accumulator 中未 flush tick 丢失。
**建议**: 后台 goroutine 改 `sync.WaitGroup` 管理，`Stop()` 调 `wg.Wait()` 后再返回。

---

### 7. outbox struct 缺 `EventID/EventType` 字段
**文件**: `internal/kafka/outbox/worker.go:45-54`

`outboxEvent` struct 只有 `(ID, Topic, Payload, CorrelationID, Status, CreatedAt, PublishedAt, RetryCount)`，没有 `EventID`、`EventType`。即便 P0-2 修了 DDL，QueryPending 出来的 `correlation_id` 也永远空，Kafka header 追踪断链。

**建议**: struct 同步补 `EventID string`、`EventType string`，与 DDL 对齐。

---

### 8. Rate limiter IP bucket map 无 TTL 清理
**文件**: `internal/server/http.go:104-107`

```go
var (
    rateMu  sync.Mutex
    buckets = make(map[string]*ipBucket)
)
```

`lastSeen` 字段已存在但**从不用于清理**。爬虫/扫描器可耗尽内存。
**建议**: 启动后台 goroutine 每 5min 扫描清理 `lastSeen > 10min`，或改 Redis TTL。

---

### 9. Watchlist 用户身份用 `X-User-ID` 明文 header
**文件**: `pkg/httputil/response.go:49-51`, `internal/watchlist/handler.go:42`

```go
func ExtractUserID(r *http.Request) string {
    return r.Header.Get("X-User-ID")
}
```

任何客户端伪造 header 即可读写他人自选股，且**无 SECURITY 警告注释**。
**建议**: 加显式 `// SECURITY: INSECURE STUB — Phase-6 must extract from validated JWT`，集成测试加 TODO 拦截进入生产。

---

### 10. `cache.go` MGet 默默吞 unmarshal 错误
**文件**: `internal/quote/infra/redis/cache.go:99`

```go
_ = fmt.Errorf("quote cache mget: unmarshal failed symbol=%s: %w", symbols[i], err)
```

创建了 error 对象后立刻丢弃，**不 log 不告警**。Redis 数据损坏静默跳过。
**建议**: 改 `ws.logger.Warn(...)` 或 `observability` counter 计数。

---

## P2（设计味道）

### 11. QuoteRepo 越界查 kline 表
**文件**: `internal/quote/infra/mysql/repo.go:81-105`（与 P0-1 关联）

`QuoteRepository.FindPrevClose` 直接裸 SQL 查 `klines` 表（属 kline subdomain），跨越 DDD 边界。
**建议**: kline subdomain 暴露 `KLineRepo.FindLastDailyClose` 接口，QuoteRepo 反向调用。

---

### 12. `strings.Title` 已 deprecated
**文件**: `internal/quote/infra/mysql/repo.go:229`

```go
return strings.Title(parts[len(parts)-1]) + ".v1"
```
Go 1.18+ 已标记 deprecated。
**建议**: 改 `golang.org/x/text/cases`。

---

### 13. 日线 K 线在 UTC 00:00 flush，US/HK 边界都错
**文件**: `internal/kline/scheduler.go:67-70`

US 收盘 16:00 ET = 21:00 UTC（夏令时）—— 晚 3 小时；HK 收盘 16:00 HKT = 08:00 UTC —— 要等到次日午夜。
**影响**: 当日日线延迟落库，`FindPrevClose` 收盘后数小时仍返回前天数据。
**建议**: 跟随 MarketScheduler 相变，US 21:30 UTC / HK 08:30 UTC 触发。

---

### 14. `handleReauth` 半实现
**文件**: `internal/server/websocket.go:232-239`

```go
func (ws *WSServer) handleReauth(client *wsClient, msg *controlMessage) {
    // TODO(Phase-6): validate new token and switch user type.
    ws.sendJSON(client, map[string]interface{}{
        "success": true, "user_type": "registered", "token_expires_in": 900,
    })
}
```

无条件返回 `"registered"` 但**不写入 `client.userType`** —— 既不安全（误导性成功响应），又不正确（实际未改变状态）。
**建议**: stub 阶段返回 `501 Not Implemented` 或不更新 `user_type`，加 SECURITY 注释。

---

### 15. WS server Shutdown 无超时保护
**文件**: `cmd/server/app.go`

WS HTTP server `Shutdown(context.Background())` 用空 context，无超时保护。
**建议**: 改 `context.WithTimeout(5s)`。

---

## P3（优化）

### 16. `formatLargeDecimal` 重复创建常量
**文件**: `internal/quote/handler.go:275-277`

每次 HTTP 响应都重新创建三个 `decimal.NewFromFloat(1e12)` 等。低频路径影响小，但风格不佳。
**建议**: 包级 `var` init 时创建一次。

---

### 17. `handleGetMarketStatus` 错误码错配
**文件**: `internal/quote/handler.go:192`

```go
httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "market 参数不合法...")
```
错误针对 `market` 参数，错误码却是 `INVALID_SYMBOL`。
**建议**: 改 `INVALID_MARKET`。

---

### 18. `/ready` endpoint 不检查 DB/Redis 连通性
**文件**: `internal/server/http.go:267-278`

注释 `// FILL: domain engineer adds DB and Redis connectivity checks` 多轮迭代未实现，readiness probe 永远 200，k8s 会路由到 DB 失联的 Pod。

---

## 已知遗留（不重复展开，已在 code-review-2026-03-25.md 记录）

- HK feed 接入（`feed/massive.go` 硬编码 MarketUS）
- JWT RS256 接 AMS 公钥
- WS 推送 Protobuf binary frame
- Outbox at-least-once 消费侧幂等键
- 1W / 1M K-line 聚合（需日历边界检测）

---

## 建议修复顺序

| 阶段 | 内容 | 理由 |
|------|------|------|
| **Wave 1** | P0-1 + P0-2 | DB 启起来就崩级别，需 migration v2 + repo/struct 同步修正 |
| **Wave 2** | P0-3 + P0-4 | 合规 + 数据精度，不修不能上 prod |
| **Wave 3** | P1-6 + P1-5（运维线） | Stop()/WaitGroup + Prometheus emit |
| **Wave 4** | P1-8 + P1-9 + P1-10（安全/稳定线） | rate limiter 清理 + watchlist 警告 + cache 错误告警 |
| **Wave 5** | P2 / P3 | 设计清理与微优化 |

---

## 验证日志（附录）

```
go build ./...     → 编译通过，无错误
go vet ./...       → 无警告
go test ./... -short -count=1 → 12 个包全绿（短模式不连真实 DB/Redis，P0-1/P0-2 无法暴露）

关键 grep 结果:
- decimal.NewFromFloat 生产调用: internal/feed/massive.go:101-104          (P0-4)
- RequestDuration emit                                                       (P1-5: 0 调用)
- DBQueryDuration emit                                                       (P1-5: 0 调用)
- KafkaPublished emit                                                        (P1-5: 0 调用)
- time.Now() 无 .UTC(): infra/redis/delayed_ring.go:59,77                    (语义正确但未遵守规范)
- strings.Title deprecated: infra/mysql/repo.go:229                          (P2-12)
- _ = fmt.Errorf 丢弃 error: infra/redis/cache.go:99                         (P1-10)
- X-User-ID header 无认证: pkg/httputil/response.go:49-51                    (P1-9)
```
