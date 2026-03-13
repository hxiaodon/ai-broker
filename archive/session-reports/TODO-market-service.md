# Market Service 待修复问题清单

**项目**: 美港股券商交易 APP - Market Service
**创建日期**: 2026-03-07
**状态**: 进行中

---

## P1 优先级 (近期完成)

### 1. 实现 Repository 层
**优先级**: P1 - 高
**状态**: 待开始
**预计工时**: 4-6 小时

**问题描述**:
- `internal/repository/repository.go` 文件不存在
- Service 层依赖的所有 Repository 接口未实现
- 影响代码编译和运行

**需要实现的 Repository**:
- [x] StockRepository
- [x] QuoteRepository
- [x] KlineRepository
- [x] WatchlistRepository
- [x] NewsRepository
- [x] FinancialRepository
- [x] HotSearchRepository

**实现内容**:
```go
// 每个 Repository 需要实现的方法
- Create()
- Update()
- Delete()
- FindByID()
- FindBySymbol()
- List()
- Count()
```

**文件位置**:
- `backend/market-service/internal/repository/stock_repository.go`
- `backend/market-service/internal/repository/quote_repository.go`
- `backend/market-service/internal/repository/kline_repository.go`
- `backend/market-service/internal/repository/watchlist_repository.go`
- `backend/market-service/internal/repository/news_repository.go`
- `backend/market-service/internal/repository/financial_repository.go`
- `backend/market-service/internal/repository/hot_search_repository.go`

---

### 2. 统一数据库架构
**优先级**: P1 - 高
**状态**: 待开始
**预计工时**: 8-12 小时

**问题描述**:
- 当前 `backend/market-service` 使用 MySQL + GORM
- `services/market-data/migrations` 使用 TimescaleDB
- 两套数据库方案并存，架构混乱

**决策建议**:
统一使用 **TimescaleDB**，原因：
- 专为时序数据优化
- 支持高效的时间范围查询
- 自动分区和数据压缩
- 更适合行情数据场景

**迁移步骤**:
1. [ ] 评估现有 MySQL schema
2. [ ] 设计 TimescaleDB schema
3. [ ] 创建迁移脚本
4. [ ] 更新 GORM 配置
5. [ ] 修改连接字符串
6. [ ] 测试数据迁移
7. [ ] 更新部署文档

**影响范围**:
- `pkg/database/database.go`
- `config/config.yaml`
- 所有 Repository 实现
- Docker Compose 配置

---

### 3. 实现 K线聚合逻辑
**优先级**: P1 - 中
**状态**: 待开始
**预计工时**: 6-8 小时

**问题描述**:
- 架构文档详细描述了 K线聚合引擎
- 实际代码只有简单的数据库查询
- 缺少实时聚合能力

**需要实现的功能**:
1. [ ] 实时 K线聚合引擎
   - 从 Kafka 消费逐笔成交数据
   - 按时间窗口聚合 OHLCV
   - 支持多种时间周期（1m, 5m, 15m, 30m, 1h, 1d）

2. [ ] K线缓存策略
   - Redis 缓存最新 K线
   - 定期持久化到数据库

3. [ ] K线补全逻辑
   - 处理缺失的 K线数据
   - 从 Polygon API 回填历史数据

**实现位置**:
- `internal/aggregator/kline_aggregator.go`
- `internal/service/kline_service.go`

**技术方案**:
```go
// 使用滑动窗口算法
type KlineAggregator struct {
    windows map[string]*TimeWindow // symbol -> window
    redis   *redis.Client
    db      *gorm.DB
}

func (a *KlineAggregator) ProcessTrade(trade *Trade) {
    // 1. 更新各个时间窗口
    // 2. 检查窗口是否完成
    // 3. 持久化完成的 K线
    // 4. 推送到 WebSocket
}
```

---

### 4. 添加错误处理
**优先级**: P1 - 中
**状态**: 待开始
**预计工时**: 3-4 小时

**问题描述**:
- WebSocket 消息处理缺少错误响应
- 客户端无法知道订阅失败原因
- 缺少统一的错误码定义

**需要实现**:
1. [ ] 定义错误码体系
```go
const (
    ErrCodeInvalidSymbol    = 1001
    ErrCodeSubscribeFailed  = 1002
    ErrCodeUnauthorized     = 1003
    ErrCodeRateLimitExceeded = 1004
)
```

2. [ ] WebSocket 错误消息类型
```json
{
  "type": "error",
  "code": 1001,
  "message": "Invalid symbol: INVALID",
  "time": 1709798400000
}
```

3. [ ] 添加错误处理到 WebSocket handler
   - 订阅失败
   - 消息格式错误
   - 权限不足
   - 连接限制

**文件修改**:
- `internal/websocket/hub.go`
- `internal/websocket/handler.go`
- `internal/websocket/errors.go` (新建)

---

## P2 优先级 (后续优化)

### 5. 实现缓存逻辑
**优先级**: P2 - 中
**状态**: 待开始
**预计工时**: 4-6 小时

**问题描述**:
- `pkg/cache/cache.go` 只有基础的 Redis 连接
- 缺少具体的缓存策略实现
- 没有缓存预热和失效机制

**需要实现**:
1. [ ] 实时行情缓存
   - TTL: 5 秒
   - Key: `quote:{symbol}`
   - 自动更新机制

2. [ ] 股票信息缓存
   - TTL: 1 小时
   - Key: `stock:{symbol}`
   - 懒加载 + 预热

3. [ ] K线数据缓存
   - TTL: 5 分钟
   - Key: `kline:{symbol}:{interval}:{timestamp}`
   - 分页缓存

4. [ ] 热门搜索缓存
   - TTL: 10 分钟
   - Key: `hot_searches`
   - 定时刷新

**实现位置**:
- `pkg/cache/quote_cache.go`
- `pkg/cache/stock_cache.go`
- `pkg/cache/kline_cache.go`

---

### 6. 添加监控和日志
**优先级**: P2 - 中
**状态**: 待开始
**预计工时**: 6-8 小时

**问题描述**:
- 缺少 Prometheus metrics
- 日志级别配置未使用
- 没有结构化日志

**需要实现**:
1. [ ] Prometheus Metrics
   - HTTP 请求延迟
   - WebSocket 连接数
   - Kafka 消费延迟
   - 缓存命中率
   - 数据库查询时间

2. [ ] 结构化日志
   - 使用 zap 或 logrus
   - 统一日志格式
   - 日志级别控制
   - 日志轮转

3. [ ] 监控面板
   - Grafana Dashboard
   - 告警规则配置

**依赖库**:
- `github.com/prometheus/client_golang`
- `go.uber.org/zap`

**实现位置**:
- `pkg/metrics/metrics.go`
- `pkg/logger/logger.go`
- `deployments/grafana/dashboards/`

---

### 7. 编写单元测试
**优先级**: P2 - 中
**状态**: 待开始
**预计工时**: 8-12 小时

**问题描述**:
- 未发现单元测试文件
- 代码覆盖率为 0%
- 缺少集成测试

**测试目标**:
- 单元测试覆盖率 > 70%
- 集成测试覆盖核心流程
- E2E 测试覆盖关键场景

**需要测试的模块**:
1. [ ] Repository 层
   - CRUD 操作
   - 查询条件
   - 事务处理

2. [ ] Service 层
   - 业务逻辑
   - 错误处理
   - 缓存逻辑

3. [ ] API 层
   - 请求验证
   - 响应格式
   - 错误码

4. [ ] WebSocket
   - 连接管理
   - 消息订阅
   - 心跳机制

5. [ ] Polygon 客户端
   - API 调用
   - 错误重试
   - 数据解析

**测试工具**:
- `testing` (标准库)
- `github.com/stretchr/testify`
- `github.com/golang/mock`

**文件结构**:
```
internal/
  repository/
    stock_repository_test.go
  service/
    market_service_test.go
  api/
    market_handler_test.go
pkg/
  polygon/
    client_test.go
```

---

### 8. 优化配置管理
**优先级**: P2 - 低
**状态**: 待开始
**预计工时**: 3-4 小时

**问题描述**:
- 敏感信息（API Key、密码）硬编码在配置文件
- 缺少环境变量支持
- 没有配置验证

**需要实现**:
1. [ ] 环境变量支持
```go
// 优先级: 环境变量 > 配置文件 > 默认值
cfg.Database.Password = getEnvOrDefault("DB_PASSWORD", cfg.Database.Password)
cfg.JWT.Secret = getEnvOrDefault("JWT_SECRET", cfg.JWT.Secret)
cfg.Polygon.APIKey = getEnvOrDefault("POLYGON_API_KEY", cfg.Polygon.APIKey)
```

2. [ ] 配置验证
```go
func (c *Config) Validate() error {
    if c.JWT.Secret == "your-secret-key-change-in-production" {
        return errors.New("JWT secret must be changed in production")
    }
    // ... 更多验证
}
```

3. [ ] 密钥管理集成
   - AWS Secrets Manager
   - HashiCorp Vault
   - Kubernetes Secrets

**文件修改**:
- `internal/config/config.go`
- `cmd/server/main.go`

---

## 完成标准

### P1 完成标准
- [ ] 所有 Repository 实现并通过测试
- [ ] 数据库统一为 TimescaleDB
- [ ] K线实时聚合功能可用
- [ ] WebSocket 错误处理完善

### P2 完成标准
- [ ] 缓存命中率 > 80%
- [ ] 监控面板可用
- [ ] 测试覆盖率 > 70%
- [ ] 配置管理支持环境变量

---

## 风险和依赖

### 技术风险
1. TimescaleDB 迁移可能影响现有数据
2. K线聚合性能需要压测验证
3. 缓存策略需要根据实际流量调整

### 外部依赖
1. Polygon.io API 稳定性
2. Redis 集群可用性
3. Kafka 消息队列性能

---

## 参考资料

- [Polygon.io API 文档](https://polygon.io/docs)
- [TimescaleDB 最佳实践](https://docs.timescale.com/timescaledb/latest/best-practices/)
- [GORM 文档](https://gorm.io/docs/)
- [Prometheus 监控指南](https://prometheus.io/docs/practices/naming/)

---

**最后更新**: 2026-03-07
**负责人**: 待分配
**审核人**: 待分配
