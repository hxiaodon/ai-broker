---
type: review-report
level: L3
status: ACTIVE
date: 2026-03-22
reviewer: opencode
target: services/market-data
scope: phase-1-4-code
reference_workflow: docs/specs/platform/feature-development-workflow.md
reference_spec:
  - docs/specs/market-data-system.md
  - docs/specs/market-api-spec.md
  - docs/specs/data-flow.md
  - docs/specs/market-data-implementation.tracker.md
---

# Market Data Phase 1-4 代码审查

## 1. 审查范围与方法

本次审查仅聚焦 `Phase 1-4` 的代码实现，按 workflow 中 “DB Schema -> Domain -> Infrastructure -> Application” 的顺序检查：

- 设计与跟踪：`docs/specs/market-data-system.md`、`docs/specs/market-api-spec.md`、`docs/specs/data-flow.md`、`docs/specs/market-data-implementation.tracker.md`
- Phase 1：`src/migrations/*.sql`
- Phase 2：`src/internal/*/domain*.go`
- Phase 3：`src/internal/*/repo.go`、`src/internal/quote/infra/**`
- Phase 4：`src/internal/*/usecase.go`、`src/internal/quote/app/*.go`

执行过的验证命令：

```bash
cd src && go test ./internal/quote/... ./internal/kline ./internal/search ./internal/watchlist -short
```

结果：通过。说明现有单元测试可运行，但不代表实现已经满足 spec。

## 2. 总体结论

`Phase 1-4` 当前不应按 tracker 中的 `completed` 视为验收通过。

核心原因：

1. **存在阻塞性实现错误**：Quote/KLine 的 GORM 模型与 migration 列名不一致，真实 MySQL 读写大概率直接失败。
2. **存在核心语义漂移**：`is_stale`、`market_status`、quote 字段模型与 API/spec 的定义不一致。
3. **实现完整度不足**：delayed quote、turnover/turnover_rate、watchlist 幂等/上限、搜索拼音支持等 Phase 1-4 关键能力未落地。
4. **测试覆盖不够**：当前测试更多覆盖 happy path，没拦住 schema mismatch、KLine 时序错误、watchlist 业务规则缺失等问题。

建议至少将 `Phase 1`、`Phase 3`、`Phase 4` 回退到 `in_progress`，修复后重新验收。

## 3. 发现的问题

### P1-01 [Blocking] Quote/KLine 的 GORM 模型与 migration 列名不一致

- `quotes` 表 migration 使用 `open_price`、`high_price`、`low_price`，见 `src/migrations/001_init_market_data.sql:13`、`src/migrations/001_init_market_data.sql:14`、`src/migrations/001_init_market_data.sql:15`
- `QuoteModel` 却使用默认列名 `open`、`high`、`low`，没有显式 `column:` 映射，见 `src/internal/quote/infra/mysql/model.go:18`
- `klines` 表 migration 使用 `interval_type`、`open_price`、`close_price` 等列，见 `src/migrations/001_init_market_data.sql:42`、`src/migrations/001_init_market_data.sql:43`、`src/migrations/001_init_market_data.sql:46`
- `klineModel` 却使用默认列名 `interval`、`open`、`close`，见 `src/internal/kline/repo.go:17`、`src/internal/kline/repo.go:18`、`src/internal/kline/repo.go:21`

影响：

- Phase 3 的 MySQL 仓储在真实 DB 上很可能无法正确读写
- 这个问题没有被现有测试发现，说明当前 repo/integration coverage 不足

建议修复：

- 统一以 migration 为准，为 GORM 字段补全 `gorm:"column:..."` 映射
- 为 `quote` 和 `kline` 仓储补 MySQL integration test，至少覆盖 save/find/basic roundtrip

### P2-01 [Major] `market_status` 枚举仍停留在旧设计，已与现行 spec 脱节

- Domain 仍定义 `OPEN`、`LUNCH_BREAK`、`POST_MARKET`，见 `src/internal/quote/domain/entity.go:48`
- migration 注释也沿用旧枚举，见 `src/migrations/001_init_market_data.sql:33`
- 现行文档要求统一为 `REGULAR | PRE_MARKET | AFTER_HOURS | CLOSED | HALTED`，见 `docs/README-INDEX.md:101`、`docs/specs/market-data-system.md:415`、`docs/specs/market-api-spec.md:204`

影响：

- Phase 2 的领域模型已经和对外 contract 不兼容
- 后续 Phase 5 handler/proto 映射时会出现额外转换甚至错误映射

建议修复：

- 先确定 canonical 枚举集合，再同步修正 domain、migration、repo、tracker 与示例文档

### P2-02 [Major] `is_stale` 语义在代码与文档之间冲突，且 `stale_since_ms` 未实现

- `StaleDetector.Evaluate` 直接按 `TradingRisk` 阈值设置 `q.IsStale`，即超过 1 秒就置 `true`，见 `src/internal/quote/domain/service.go:16`
- `market-data-system.md` 附录 D 也把 `is_stale` 定义为交易风控阈值，见 `docs/specs/market-data-system.md:2555`、`docs/specs/market-data-system.md:2568`
- 但 `market-api-spec.md` 与 `README-INDEX.md` 明确把 `is_stale=true` 定义为超过 5 秒展示阈值，见 `docs/specs/market-api-spec.md:107`、`docs/specs/market-api-spec.md:110`、`docs/README-INDEX.md:100`
- 代码里也没有 `stale_since_ms` 字段与计算逻辑，见 `src/internal/quote/domain/entity.go:18`

影响：

- 当前实现即使通过，也无法确定它到底满足哪一份 spec
- 前端展示、交易风控、gRPC 内部调用会对同一个字段产生不同理解

建议修复：

- 先统一 spec：`is_stale` 究竟是 1 秒还是 5 秒
- 如果保留双阈值，建议显式区分 `is_stale_for_display` / `is_trading_stale`，或至少补全 `stale_since_ms`

### P2-03 [Major] Quote 聚合模型未覆盖 spec 关键字段，且部分字段声明了但未落地

- Domain `Quote` 只有 `Change` / `ChangePct` 字段声明，但 `UpdateQuoteUsecase` 并未计算它们，见 `src/internal/quote/domain/entity.go:32`、`src/internal/quote/app/update_quote.go:60`
- MySQL model 也未持久化 `Change` / `ChangePct`、`turnover`、`market_status`、`delayed` 等字段，见 `src/internal/quote/infra/mysql/model.go:13`
- 现行 spec 的 quote 响应要求至少包含 `change_pct`、`turnover`、`delayed`、`market_status`，见 `docs/specs/market-api-spec.md:192`、`docs/specs/market-api-spec.md:196`、`docs/specs/market-api-spec.md:203`、`docs/specs/market-api-spec.md:204`
- 系统设计中的 quote 消息/表结构也包含 `turnover`、`turnover_rate`、`market_status`、数据时间戳，见 `docs/specs/market-data-system.md:407`、`docs/specs/market-data-system.md:408`、`docs/specs/market-data-system.md:415`、`docs/specs/market-data-system.md:1594`

影响：

- Phase 2-4 的核心 quote 模型无法支撑现行 API spec
- 到 Phase 5 再补字段，会导致 domain/app/repo 一起返工

建议修复：

- 以现行 quote contract 为准，先补齐 aggregate 字段，再决定哪些字段属于缓存态、持久化态、对外投影态

### P3-01 [Major] Quote cache key 与 TTL 策略未按 spec 实现

- Redis 实现使用 `quote:<symbol>` 且固定 TTL 30 秒，见 `src/internal/quote/infra/redis/cache.go:25`、`src/internal/quote/infra/redis/cache.go:29`
- spec 要求按市场分 namespace，并区分 delayed/live，见 `docs/specs/market-data-system.md:1785`、`docs/specs/market-data-system.md:1786`
- `data-flow.md` 也明确实时快照写入 `quote:US:{symbol}` / `quote:HK:{symbol}`，见 `docs/specs/data-flow.md:42`

影响：

- US/HK 同代码会发生 key 冲突
- 访客 delayed quote 链路无法接入
- TTL 策略与盘中/盘后缓存策略不一致

建议修复：

- key 至少升级为 `quote:{market}:{symbol}`
- 按 spec 拆分 delayed/live key 与 TTL 策略

### P3-02 [Major] Watchlist schema/repo 与 spec 不一致

- 当前实现表名为 `watchlist_items`，`user_id` 是 `BIGINT`，见 `src/migrations/001_init_market_data.sql:72`、`src/migrations/001_init_market_data.sql:74`
- repo 模型也延续了该结构，见 `src/internal/watchlist/repo.go:11`
- spec 要求的是 `user_watchlist`，`user_id CHAR(36)` UUID，并通过 `MAX(sort_order)+1` 自动排位，见 `docs/specs/market-data-system.md:1681`、`docs/specs/market-data-system.md:1683`、`docs/specs/market-data-system.md:1694`

影响：

- 当前 Phase 3 schema 已经和系统设计不兼容
- 若 AMS 用户主键是 UUID，后续集成会出现类型不匹配

建议修复：

- 按 spec 统一表名、字段类型和 `sort_order` 生成规则
- 明确 `created_at` / `added_at` 的命名与接口返回语义

### P3-03 [Major] Repository 的 not-found 语义仍然过弱

- Quote repo `FindBySymbol` 未命中返回 `nil, nil`，见 `src/internal/quote/infra/mysql/repo.go:41`
- Search repo `GetBySymbol` 未命中也返回 `nil, nil`，见 `src/internal/search/repo.go:115`
- 但 tracker Phase 3 的准出标准写的是 “FindByXxx 返回 domain error”，见 `docs/specs/market-data-implementation.tracker.md:66`

影响：

- Application/Transport 层只能靠字符串判断 not found
- 后续 Phase 5 错误码映射容易分叉

建议修复：

- 在 domain 或 app 层定义统一的 `ErrNotFound` / typed error
- repo 按统一语义返回

### P4-01 [Major] `UpdateQuoteUsecase` 覆盖了行情原始时间戳，和 spec 的“数据时间戳”语义不一致

- `Execute` 直接把 `q.LastUpdatedAt` 重置为 `time.Now().UTC()`，见 `src/internal/quote/app/update_quote.go:65`
- spec 中 quote 时间戳表示“行情数据时间/交易所时间”，见 `docs/specs/market-data-system.md:393`、`docs/specs/market-data-system.md:1594`
- 附录 D 的“伪新鲜数据”检测也依赖源时间戳，而不是服务写入时间，见 `docs/specs/market-data-system.md:2650`
- 单元测试还把这一行为固化成了预期，见 `src/internal/quote/app/update_quote_test.go:136`

影响：

- 会丢失 feed 原始时间，影响 stale 判断与数据质量检测
- 当上游补发旧数据或网络抖动时，当前实现会把旧行情伪装成“刚更新”

建议修复：

- `LastUpdatedAt` 应由 feed/normalizer 提供
- 如果需要记录服务处理时间，单独增加 ingest/process timestamp，不要覆盖行情数据时间

### P4-02 [Major] KLine 聚合依赖输入顺序，乱序 tick 会生成错误 OHLC

- `AggregateKLineUsecase` 把“第一次遍历到的 tick”当 open，把“最后一次遍历到的 tick”当 close，见 `src/internal/kline/usecase.go:66`、`src/internal/kline/usecase.go:100`
- 这只在输入已经按时间排序时才成立，但代码没有显式排序，也没有用 tick timestamp 比较
- 现有测试只覆盖顺序输入，见 `src/internal/kline/usecase_test.go:115`

影响：

- 一旦批量 tick 乱序，K 线开收盘价就会错误

建议修复：

- 聚合前按 `Timestamp` 排序，或在 bucket 中显式维护 earliest/latest tick
- 增加 out-of-order tick 测试

### P4-03 [Major] Weekly/Monthly KLine 聚合未真正实现

- `intervalDuration` 对 `1W` / `1M` 返回 0，见 `src/internal/kline/usecase.go:146`
- `Execute` 里对 duration=0 的处理只是截到“日”边界，并标注“weekly/monthly handled upstream”，见 `src/internal/kline/usecase.go:74`
- 但 usecase 本身仍然接受 `Interval1W` / `Interval1M`

影响：

- 目前 `1W` / `1M` 不是“未实现”，而是“会返回错误结果”

建议修复：

- 要么在 usecase 里真正按周/月边界聚合
- 要么显式拒绝 `1W` / `1M`，避免 silent wrong result

### P4-04 [Major] Watchlist usecase 只做了空 symbol 校验，业务规则未落实

- `AddToWatchlistUsecase` 仅校验 `symbol != ""`，见 `src/internal/watchlist/usecase.go:39`
- spec 明确要求：
  - 每用户最多 100 只，见 `docs/specs/market-data-system.md:1699`
  - 添加幂等，重复添加直接成功，见 `docs/specs/market-api-spec.md:1096`
  - 重复添加返回原始 `added_at`，见 `docs/specs/market-api-spec.md:1160`
  - 添加前验证 symbol 存在，见 `docs/specs/market-api-spec.md:1161`

影响：

- 当前实现离 Phase 4 的应用层规则完整性还有明显差距

建议修复：

- 增加 `CountByUserID` / `GetByUserAndSymbol` / `GetBySymbol` 等依赖接口
- 在 app 层实现上限、幂等、原始时间返回与 symbol existence check

### P4-05 [Major] Search 实现与 spec 仍有明显差距

- repo 仅支持 `name` / `name_cn` FULLTEXT + ticker prefix，见 `src/internal/search/repo.go:35`
- spec 要求支持中文名拼音首字母，如 `pg -> 苹果`，见 `docs/specs/market-api-spec.md:549`、`docs/specs/market-api-spec.md:550`
- `README-INDEX.md` 也把 `pinyin_initials` 列为 Phase 1 待办，见 `docs/README-INDEX.md:120`
- usecase 的默认/最大 limit 为 `20/100`，但 API spec 是 `10/50`，见 `src/internal/search/usecase.go:27`、`docs/specs/market-api-spec.md:477`

影响：

- Search Phase 1 的中文检索能力并未达到文档承诺
- 参数行为也和 API spec 不一致

建议修复：

- 补 `pinyin_initials` schema/index/查询逻辑
- 统一 app/transport 层的默认值和上限

### P4-06 [Major] 当前 quote 写路径与 data-flow 的 Redis-first 设计不一致，delayed quote 主链路仍缺失

- `UpdateQuoteUsecase` 当前是 “MySQL + outbox 事务写入，缓存后置 best-effort”，见 `src/internal/quote/app/update_quote.go:78`
- `data-flow.md` 的主链路是先写 Redis quote cache，再经 Kafka/异步链路处理，见 `docs/specs/data-flow.md:41`、`docs/specs/data-flow.md:47`
- `market-data-system.md` 也明确 delayed quote 依赖 `DelayedQuoteRingBuffer` 和定时快照写入，但 `src/` 中尚未看到对应实现，见 `docs/specs/data-flow.md:68`、`docs/specs/data-flow.md:89`

影响：

- 当前代码无法支撑 delayed quote 能力
- 高频行情直接打 MySQL，也偏离了设计里对吞吐与缓存优先级的假设

建议修复：

- 先澄清 canonical 数据流是否已经变更
- 若没有变更，应把 Redis-first / delayed snapshot/ring-buffer 作为 Phase 1-4 未完成项补回 tracker

## 4. 测试评估

### 已验证

- `cd src && go test ./internal/quote/... ./internal/kline ./internal/search ./internal/watchlist -short` 通过

### 覆盖不足

- `src/internal/search/usecase_test.go:17` 基本还是占位测试，没验证 hot ranking、limit clamp、错误传播
- `src/internal/watchlist/usecase_test.go:36` 只覆盖空 symbol 和简单成功路径，未覆盖幂等、上限、symbol existence、顺序稳定性
- `src/internal/quote/app/get_quote_test.go:71` 只覆盖 cache hit/空 symbol，未覆盖 cache miss -> DB fallback、not found、cache 回填、stale 逻辑
- `src/internal/kline/usecase_test.go:115` 没覆盖 out-of-order tick、`1W/1M`、跨市场交易日边界
- `src/internal/quote/infra/mysql` 与 `src/internal/kline` 缺少能连真实 schema 的 MySQL integration test，这正是 P1-01 漏检的直接原因

## 5. 与 tracker 的偏差

- tracker 当前把 `Phase 1-4` 都标成 `completed`，见 `docs/specs/market-data-implementation.tracker.md:21`、`docs/specs/market-data-implementation.tracker.md:65`、`docs/specs/market-data-implementation.tracker.md:90`
- 但从代码事实看，至少以下准出标准尚未满足：
  - Phase 3：`FindByXxx 返回 domain error`
  - Phase 3：真实 schema/repo 对齐
  - Phase 4：应用层规则完整
  - Phase 4：Event/Quote 模型与现行 spec 对齐

建议：

- 先修复阻塞项，再重做每个 Phase 的 self-verify 与 codex verify
- tracker 的验收记录应保留 fail -> fix -> pass 轨迹，而不是直接写 pass

## 6. 优先级建议

建议按下面顺序修：

1. **先修 schema/model 对齐**：Quote/KLine GORM 列映射、watchlist schema、枚举统一
2. **再修核心语义**：`market_status`、`is_stale`、timestamp、quote 字段模型
3. **补应用层规则**：watchlist 幂等/上限、search pinyin、KLine 周月聚合
4. **最后补测试**：repo integration test、KLine 乱序测试、watchlist/search/get_quote 场景测试
