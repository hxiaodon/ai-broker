# Market Data Service - 代码审查报告

**审查日期**: 2024-03-24
**审查范围**: market-data 服务完整代码
**审查标准**: DDD 原则、SOLID 原则、系统完备性、可维护性、可扩展性、可读性

---

## 执行摘要

**总体评估**: 架构设计优秀，DDD 和 SOLID 原则落地良好，但存在 **2 个生产阻塞问题 (P0)** 和 **3 个高优先级问题 (P1)** 需要立即修复。

**优势**:
- ✅ 零 SOLID 原则违规
- ✅ 清晰的 DDD 分层，依赖方向正确
- ✅ 领域层测试覆盖率 95%
- ✅ Wire 依赖注入使用得当
- ✅ 正确使用 decimal.Decimal 处理金融计算

**关键缺陷**:
- ❌ 缺失 Dead Letter Queue (DLQ) 路由，Kafka 事件失败后丢失
- ❌ UpdateQuote 用例缺少幂等性检查
- ❌ 缺失 Correlation ID，无法进行分布式追踪
- ❌ Outbox Worker 无背压控制
- ❌ Feed Handler 错误处理不足

---

## 优先级问题清单

### P0: 生产阻塞问题（上线前必须修复）

#### P0-1: Outbox Worker 缺失 DLQ 路由

**文件**: `src/internal/kafka/outbox/worker.go`

**问题描述**: 当 outbox 事件重试达到最大次数后，仅标记为 FAILED 状态，但从未路由到 Dead Letter Queue。这违反了 `docs/specs/market-data-system.md` §8 中定义的 Outbox+DLQ 模式。

**影响**: 失败事件被静默丢失，破坏事件驱动保证。下游服务（Trading Engine）可能错过关键报价更新。

**当前代码** (第 82-89 行):
```go
func (w *Worker) MarkRetry(ctx context.Context, eventID int64, err error) error {
    return w.db.WithContext(ctx).Model(&OutboxEvent{}).
        Where("id = ? AND status = ?", eventID, StatusPending).
        Updates(map[string]interface{}{
            "retry_count": gorm.Expr("retry_count + 1"),
            "status":      gorm.Expr("CASE WHEN retry_count + 1 >= ? THEN ? ELSE ? END", w.maxRetries, StatusFailed, StatusPending),
            "error_msg":   err.Error(),
        }).Error
}
```

**修复方案**:
1. 在 `configs/config.yaml` 添加 DLQ topic 配置
2. 修改 `MarkRetry` 方法，当 `retry_count >= maxRetries` 时发布到 DLQ
3. 添加 DLQ 消费者用于手动重放/调查
4. 添加 Prometheus 指标 `outbox_dlq_events_total{topic}`

**验证方法**: 模拟 Kafka 发布失败，验证事件在 3 次重试后进入 DLQ topic。

---

#### P0-2: UpdateQuote 缺少幂等性检查

**文件**: `src/internal/quote/app/update_quote.go`

**问题描述**: `UpdateQuote` 用例不检查重复的 (symbol, market, timestamp) 组合。如果 feed handler 重试或发送重复 tick，同一报价会被多次处理，创建重复的 outbox 事件。

**影响**: 重复报价更新淹没 Kafka，对下游消费者（Trading Engine、Mobile WebSocket）造成不必要的负载。

**当前代码** (第 59-105 行):
```go
func (uc *UpdateQuote) Execute(ctx context.Context, cmd UpdateQuoteCommand) error {
    // ... 验证 ...

    // 这里没有去重检查！
    quote := &domain.Quote{
        Symbol: cmd.Symbol,
        Market: cmd.Market,
        // ...
    }

    if err := uc.quoteRepo.Save(ctx, quote); err != nil {
        return fmt.Errorf("save quote: %w", err)
    }
    // ...
}
```

**修复方案**:
1. 在 `QuoteRepo` 接口添加 `GetBySymbolMarketTimestamp(ctx, symbol, market, timestamp) (*Quote, error)`
2. 在 `UpdateQuote.Execute` 中，保存前检查报价是否已存在
3. 如果存在且相同，提前返回（幂等成功）
4. 如果存在但不同，记录警告并更新（处理延迟到达的修正）
5. 添加 Redis 缓存键 `quote:dedup:{symbol}:{market}:{timestamp}`，TTL 1 小时用于快速路径

**验证方法**: 通过 feed handler 发送重复报价，验证只创建一个 outbox 事件。

---

### P1: 高优先级（Sprint 1 修复）

#### P1-1: 缺失 Correlation ID 传播

**文件**: `src/internal/server/http.go`, `src/internal/kafka/outbox/worker.go`

**问题描述**: 没有从 HTTP 头提取或为后台任务生成 correlation ID。这破坏了跨服务的分布式追踪。

**影响**: 无法追踪报价更新从 feed 摄取 → outbox → Kafka → Trading Engine 的完整链路。生产问题调试变得极其困难。

**修复方案**:
1. 在 `http.go` 添加中间件提取/生成 `X-Correlation-ID` 头
2. 通过 `context.WithValue` 将 correlation ID 存储在 `context.Context` 中
3. 在 `outbox_events` 表添加 `correlation_id VARCHAR(64)` 列
4. 修改 outbox worker 在 Kafka 消息头中包含 correlation ID
5. 在所有结构化日志中记录 correlation ID

**验证方法**: 发送带 `X-Correlation-ID: test-123` 的 HTTP 请求，验证它出现在日志、outbox 表和 Kafka 消息头中。

---

#### P1-2: Outbox Worker 无背压控制

**文件**: `src/internal/kafka/outbox/worker.go`

**问题描述**: 固定批次大小 100 个事件（第 142 行），无自适应背压。如果 Kafka 慢，worker 会以全速持续轮询数据库，导致 CPU/内存峰值。

**当前代码** (第 142 行):
```go
events, err := w.repo.FetchPending(ctx, 100)
```

**影响**: 高负载下，服务可能耗尽数据库连接或因无界事件累积导致 OOM。

**修复方案**:
1. 基于 Kafka 发布延迟添加动态批次大小调整
2. 当 Kafka 慢时实现指数退避（P99 延迟 > 100ms）
3. 添加熔断器，Kafka 宕机时暂停轮询
4. 添加 Prometheus 指标: `outbox_batch_size`, `outbox_backoff_seconds`

**验证方法**: 将 Kafka 限速到 10 msg/s，验证 worker 减小批次大小并增加轮询间隔。

---

#### P1-3: Feed Handler 错误处理不足

**文件**: `src/pkg/polygon/client.go`, `src/pkg/hkex/client.go`

**问题描述**: Feed handler 客户端是桩代码，没有重试逻辑、熔断器或回退策略。瞬时网络错误会导致报价更新停止。

**影响**: Feed 提供商宕机期间市场数据中断。无自动恢复。

**修复方案**:
1. 实现指数退避重试（3 次尝试，1s → 2s → 4s）
2. 添加熔断器（连续 5 次失败后打开，30s 后半开）
3. 添加备用 feed 提供商回退（例如美股使用 IEX Cloud）
4. 添加 Prometheus 指标: `feed_errors_total{provider}`, `feed_circuit_breaker_state{provider}`
5. 熔断器打开状态告警

**验证方法**: 模拟 Polygon API 503 错误，验证 3 次重试后熔断器打开。

---

### P2: 中优先级（Sprint 2 修复）

#### P2-1: 缺失 Quote.Validate() 方法
- **文件**: `src/internal/quote/domain/entity.go`
- **问题**: 无领域级验证方法强制不变量（如 price > 0, volume >= 0, bid <= ask）
- **修复**: 添加 `Validate() error` 方法，在 `UpdateQuote.Execute` 保存前调用

#### P2-2: Outbox Worker 吞没错误
- **文件**: `src/internal/kafka/outbox/worker.go` (第 155, 158 行)
- **问题**: 错误赋值给 `_`，无法调试
- **修复**: 用 `logger.Error("mark success failed", zap.Error(err))` 记录错误

#### P2-3: WebSocket Gateway 是桩代码
- **文件**: `src/internal/server/websocket.go`
- **问题**: WebSocket 服务器未实现，移动客户端无法接收实时报价
- **修复**: 按 `docs/specs/websocket-spec.md` 实现（基于消息的认证，双轨推送）

#### P2-4: gRPC Service 是桩代码
- **文件**: `src/internal/server/grpc.go`
- **问题**: gRPC 服务器无服务实现，服务间调用（Trading Engine → Market Data）会失败
- **修复**: 实现 `market_data.proto` 服务方法

---

### P3: 低优先级（技术债）

#### P3-1: JWT 验证未实现
- **文件**: `src/internal/server/http.go`
- **修复**: 按 `.claude/rules/security-compliance.md` 添加 JWT 验证中间件

#### P3-2: 限流未实现
- **文件**: `src/internal/server/http.go`
- **修复**: 添加限流器（报价端点 100 req/s per IP）

#### P3-3: 配置包含占位符密钥
- **文件**: `src/configs/config.yaml`
- **修复**: 替换为 `${MYSQL_PASSWORD}` 并从环境变量加载

---

## SOLID 原则评估

**结果**: ✅ **零违规**

- **单一职责**: 每个用例只有一个变更原因
- **开闭原则**: 领域实体对修改封闭，通过接口对扩展开放
- **里氏替换**: 所有仓储实现可替换
- **接口隔离**: 接口最小化（如 `QuoteRepo` 只有 2 个方法）
- **依赖倒置**: 所有层依赖抽象（接口），而非具体实现

---

## DDD 实现评估

**结果**: ✅ **优秀**

- **子域优先架构**: 4 个子域（quote, kline, watchlist, search）边界清晰
- **依赖方向**: `handler → app → domain ← infra`（正确）
- **领域层纯净**: `domain/` 包无基础设施依赖
- **聚合设计**: `Quote` 是合适的聚合根，`StaleDetector` 是领域服务
- **仓储模式**: 清晰抽象，MySQL/Redis 实现
- **领域事件**: `QuoteUpdatedEvent` 建模正确
- **测试覆盖**: 领域层 95%（优秀）

**小缺陷**: `Quote` 实体缺少 `Validate()` 方法（P2-1）

---

## 可维护性评估

**优势**:
- 清晰的包结构，命名一致
- 复杂逻辑有全面的内联注释（如 stale 检测）
- 正确的错误包装（`fmt.Errorf("...: %w", err)`）
- 结构化日志（Zap JSON 格式）

**缺陷**:
- Outbox worker 吞没错误（P2-2）
- 缺失 correlation ID 分布式追踪（P1-1）
- Feed handler 无熔断器（P1-3）

---

## 可扩展性评估

**当前瓶颈**:
1. **单一 outbox worker**: 无法水平扩展（无 leader 选举）
2. **Redis 单点**: 无 Redis Cluster 或 Sentinel 高可用
3. **MySQL 写瓶颈**: 所有报价更新通过单一主库

**改进建议**（MVP 后）:
- 添加 outbox worker leader 选举（etcd 或 Consul）
- 部署 Redis Cluster（3 主 + 3 从）
- 按市场（US/HK）或股票代码前缀分片 MySQL

---

## 可读性评估

**优势**:
- 一致的 Go 命名约定（导出用 PascalCase，私有用 camelCase）
- 清晰的关注点分离（transport → app → domain → infra）
- 最小圈复杂度（大多数函数 < 10 行）

**小问题**:
- `update_quote.go` 部分函数较长（105 行）— 考虑提取验证逻辑
- 魔法数字（如批次大小 100）— 应使用常量

---

## 关键修改文件

### P0 修复

1. `src/internal/kafka/outbox/worker.go` - 添加 DLQ 路由
2. `src/internal/quote/app/update_quote.go` - 添加幂等性检查
3. `src/internal/quote/domain/repo.go` - 添加 `GetBySymbolMarketTimestamp` 接口
4. `src/internal/quote/infra/mysql/repo.go` - 实现 `GetBySymbolMarketTimestamp`
5. `src/configs/config.yaml` - 添加 DLQ topic 配置
6. `src/migrations/002_add_dlq_and_correlation.sql` (新建) - 添加 `correlation_id` 列和去重索引

### P1 修复

7. `src/internal/server/http.go` - 添加 correlation ID 中间件
8. `src/pkg/polygon/client.go` - 实现重试 + 熔断器
9. `src/pkg/hkex/client.go` - 实现重试 + 熔断器

---

## 实施顺序

1. **Sprint 0（生产前）**:
   - P0-1: DLQ 路由（2 天）
   - P0-2: 幂等性检查（1 天）
   - P1-1: Correlation ID（1 天）

2. **Sprint 1（生产加固）**:
   - P1-2: 背压控制（2 天）
   - P1-3: Feed handler 重试 + 熔断器（3 天）
   - P2-1: Quote.Validate()（0.5 天）
   - P2-2: 修复错误吞没（0.5 天）

3. **Sprint 2（功能完善）**:
   - P2-3: WebSocket gateway（5 天）
   - P2-4: gRPC service（3 天）

4. **Sprint 3（安全 & 优化）**:
   - P3-1: JWT 验证（1 天）
   - P3-2: 限流（1 天）
   - P3-3: 配置密钥（0.5 天）

---

## 结论

Market-data 服务有**坚实的基础**，DDD 和 SOLID 原则落地优秀。但 **2 个生产阻塞问题（P0）** 和 **3 个高优先级问题（P1）** 必须在上线前解决：

- **P0-1**: 缺失 DLQ 路由（数据丢失风险）
- **P0-2**: 无幂等性检查（重复事件）
- **P1-1**: 缺失 correlation ID（无法调试）
- **P1-2**: 无背压控制（OOM 风险）
- **P1-3**: Feed 错误处理不足（中断风险）

**预估工作量**: P0+P1 修复需要 **10 天**。

修复后，服务将为 Phase 1 上线（美股市场，仅注册用户）做好生产准备。
