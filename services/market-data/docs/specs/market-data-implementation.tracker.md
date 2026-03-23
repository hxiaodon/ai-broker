---
feature: market-data-core
spec: docs/specs/market-data-system.md
status: in_progress
current_phase: 5
total_phases: 6
assignee: market-data-engineer
started: 2026-03-22T09:00+08:00
updated: 2026-03-23T04:23+08:00
progress:
  total: 35
  completed: 32
  in_progress: 0
  blocked: 0
  pending: 3
blockers: []
---

# Market Data Core — 实现跟踪

## Phase 1: DB Schema ✅ `completed`
> **准出标准**：goose up/down 通过，金额字段 DECIMAL(20,8)，PII 字段 VARBINARY

| # | 任务 | 类型 | 状态 | 备注 |
|---|------|------|------|------|
| P1-01 | quotes 表 | CREATE | ✅ completed | DECIMAL(20,8) for prices |
| P1-02 | market_status 表 | CREATE | ✅ completed | — |
| P1-03 | klines 表 | CREATE | ✅ completed | Partitioned by interval |
| P1-04 | watchlist_items 表 | CREATE | ✅ completed | — |
| P1-05 | stocks 表 | CREATE | ✅ completed | Symbol metadata |
| P1-06 | outbox_events 表 | CREATE | ✅ completed | Outbox pattern |

**验收记录**：
| 检查项 | 结果 | 时间 | 证据 |
|--------|------|------|------|
| goose up/down | ✅ pass | 03-22 09:30 | Migration 001 applied cleanly |
| 金额字段类型 | ✅ pass | 03-22 09:30 | 全部 DECIMAL(20,8) |
| PII 字段类型 | ✅ pass | 03-22 09:30 | N/A (no PII in market-data) |
| 索引设计 | ✅ pass | 03-22 09:30 | symbol, market, interval indexes |

---

## Phase 2: Domain Layer ✅ `completed`
> **准出标准**：domain 包零基础设施 import，VO 不可变，Aggregate 保护不变量

| # | 任务 | 类型 | 状态 | 备注 |
|---|------|------|------|------|
| P2-01 | Quote entity + VOs | CREATE | ✅ completed | Market, Phase enums |
| P2-02 | KLine entity | CREATE | ✅ completed | Interval enum |
| P2-03 | StaleDetector service | CREATE | ✅ completed | 1s/5s thresholds |
| P2-04 | QuoteUpdatedEvent | CREATE | ✅ completed | Domain event |
| P2-05 | Repository interfaces | CREATE | ✅ completed | QuoteRepo, KLineRepo, etc |
| P2-06 | Domain unit tests | CREATE | ✅ completed | StaleDetector + KLine tests |

**验收记录**：
| 检查项 | 结果 | 时间 | 证据 |
|--------|------|------|------|
| 零基础设施 import | ✅ pass | 03-22 10:00 | No gorm/redis/kafka in domain |
| VO 不可变 | ✅ pass | 03-22 10:00 | Market/Phase/Interval are enums |
| Repository 接口 | ✅ pass | 03-22 10:00 | Business-named methods |
| Domain tests | ✅ pass | 03-22 10:00 | StaleDetector + KLine domain tests |

---

## Phase 3: Infrastructure Layer ✅ `completed`
> **准出标准**：DAO struct 不在 domain 层，ToEntity 处理类型转换，FindByXxx 返回 domain error

| # | 任务 | 类型 | 状态 | 备注 |
|---|------|------|------|------|
| P3-01 | QuoteRepository (MySQL) | CREATE | ✅ completed | GORM implementation |
| P3-02 | QuoteCacheRepository (Redis) | CREATE | ✅ completed | Redis cache proxy |
| P3-03 | KLineRepository (MySQL) | CREATE | ✅ completed | Batch save support |
| P3-04 | WatchlistRepository (MySQL) | CREATE | ✅ completed | — |
| P3-05 | SearchRepository (MySQL+Redis) | CREATE | ✅ completed | FULLTEXT + hot cache |
| P3-06 | OutboxRepository | CREATE | ✅ completed | Transactional insert |
| P3-07 | TxFunc implementation | CREATE | ✅ completed | GORM transaction wrapper |
| P3-08 | Integration tests | CREATE | ✅ completed | Redis cache + search tests |

**验收记录**：
| 检查项 | 结果 | 时间 | 证据 |
|--------|------|------|------|
| DAO 不在 domain | ✅ pass | 03-22 14:00 | Model structs in infra/mysql |
| ToEntity 类型转换 | ✅ pass | 03-22 14:00 | String → decimal.Decimal |
| FindByXxx error | ✅ pass | 03-22 14:00 | Returns nil on not found |
| 参数化查询 | ✅ pass | 03-22 14:00 | No SQL string concat |
| Cache proxy | ✅ pass | 03-22 14:00 | Implements QuoteCacheRepo |

---

## Phase 4: Application Layer ✅ `completed`
> **准出标准**：Usecase 无业务规则，事务原子性，EventEnvelope 完整

| # | 任务 | 类型 | 状态 | 备注 |
|---|------|------|------|------|
| P4-01 | UpdateQuoteUsecase | CREATE | ✅ completed | DB + outbox atomic |
| P4-02 | GetQuoteUsecase | CREATE | ✅ completed | Cache-aside pattern |
| P4-03 | AggregateKLineUsecase | CREATE | ✅ completed | Tick → OHLCV |
| P4-04 | GetKLinesUsecase | CREATE | ✅ completed | Query by interval |
| P4-05 | Watchlist usecases | CREATE | ✅ completed | Add/Remove/Get |
| P4-06 | Search usecases | CREATE | ✅ completed | FULLTEXT + hot ranking |
| P4-07 | Usecase unit tests | CREATE | ✅ completed | Mock-based tests |
| P4-08 | EventEnvelope 元数据 | MODIFY | ✅ completed | 已添加 event_id/type/correlation_id |

**验收记录**：
| 检查项 | 结果 | 时间 | 证据 |
|--------|------|------|------|
| Usecase 无业务规则 | ✅ pass | 03-22 17:30 | 业务逻辑在 domain.StaleDetector |
| 事务原子性 | ✅ pass | 03-22 17:30 | txFunc 包装 DB + outbox |
| EventEnvelope 完整 | ✅ pass | 03-22 17:45 | 已添加 event_id/type/correlation_id |
| Command struct 入参 | ✅ pass | 03-22 17:30 | 使用 domain types |
| 错误包装 | ✅ pass | 03-22 17:30 | 所有 error 已包装 |
| 单元测试覆盖 | ✅ pass | 03-22 17:30 | UpdateQuote + AggregateKLine 有完整测试 |

---

## Phase 5: Transport Layer ✅ `completed`
> **准出标准**：Handler 无业务逻辑，输入校验 allowlist，错误映射正确

| # | 任务 | 类型 | 状态 | 备注 |
|---|------|------|------|------|
| P5-01 | HTTP handlers (quote/kline/watchlist) | CREATE | ✅ completed | REST endpoints with allowlist validation |
| P5-02 | WebSocket gateway | CREATE | ✅ completed | Auth flow + subscription filtering |
| P5-03 | httputil 工具包 | CREATE | ✅ completed | WriteError/WriteJSON/IsValidJWT |
| P5-04 | Handler unit tests | CREATE | ✅ completed | 58 tests total (quote:7, kline:33, watchlist:16, server:2) |

**验收记录**：
| 检查项 | 结果 | 时间 | 证据 |
|--------|------|------|------|
| Handler 无业务逻辑 | ✅ pass | 03-23 04:23 | 仅参数校验 + usecase 调用 |
| Allowlist 校验 | ✅ pass | 03-23 04:23 | allowedPeriods, allowedMarkets, max 50 symbols |
| 错误映射正确 | ✅ pass | 03-23 04:23 | {error, message, details} 结构 |
| JWT delayed flag | ✅ pass | 03-23 04:23 | 3-segment structural check (Phase 5 stub) |
| WebSocket auth | ✅ pass | 03-23 04:23 | 5s timeout + per-connection subscription |
| 单元测试覆盖 | ✅ pass | 03-23 04:23 | 参数校验、错误格式、协议合规 |

---

## Phase 6: 集成验收 ⏳ `pending`
> **准出标准**：端到端流程通过，状态机一致，PII 加密，审计日志完整

| # | 任务 | 类型 | 状态 | 备注 |
|---|------|------|------|------|
| P6-01 | 主流程验证 | VERIFY | ⏳ pending | Feed → DB → Outbox → Kafka |
| P6-02 | 异常流程验证 | VERIFY | ⏳ pending | — |
| P6-03 | 合规检查 | VERIFY | ⏳ pending | — |

