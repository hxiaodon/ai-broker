# AMS 技术栈选型规格

> **版本**: v0.1
> **日期**: 2026-03-17
> **作者**: AMS Engineering
> **状态**: 已确认 — 可开始实施
>
> 本文档记录 Account Management Service 所有 Go 库的最终选型决策，包含决策理由、关键代码模式，以及与其他服务的集成契约。

---

## 目录

1. [技术选型总览](#1-技术选型总览)
2. [JWT 认证库](#2-jwt-认证库)
3. [HTTP 框架 & API 规范](#3-http-框架--api-规范)
4. [数据库访问层](#4-数据库访问层)
5. [Redis 客户端](#5-redis-客户端)
6. [Kafka 事件发布](#6-kafka-事件发布)
7. [后台任务调度](#7-后台任务调度)
8. [gRPC 服务间通信](#8-grpc-服务间通信)
9. [可观测性](#9-可观测性)
10. [PII 加密](#10-pii-加密)
11. [Go Module 依赖清单](#11-go-module-依赖清单)

---

## 1. 技术选型总览

| 领域 | 选型 | 备选方案 | 决策理由 |
|------|------|----------|----------|
| JWT 签发/验证 | `golang-jwt/jwt v5` | go-jose v4 | RS256 最简实现；v5 API 稳定；go-jose 用于 JWKS 端点 |
| HTTP 框架 | `go-chi/chi v5` | gin v1 | stdlib 兼容；中间件无锁定；multipart 流式上传 |
| OpenAPI 规范 | `ogen-go/ogen`（contract-first） | swaggo/swag | 规范即代码；类型安全；消除文档漂移 |
| ORM / SQL | `uptrace/bun` | jmoiron/sqlx | 内置 OTel hook；query builder；乐观锁支持 |
| DB 迁移 | `pressly/goose v3` | golang-migrate | 支持 Go 代码迁移；embedded FS；out-of-order |
| Redis 客户端 | `redis/go-redis v9` | — | 官方客户端；Pipeline；Lua 脚本 |
| Redis 限流 | `go-redis/redis_rate v9` | 自建 Lua | GCRA 算法；防突刺攻击 |
| 分布式锁 | `go-redsync/redsync v4` | bsm/redislock | Redlock 算法；多 Pod 安全 |
| Kafka 客户端 | `twmb/franz-go` | IBM/sarama | 纯 Go（无 CGO）；全 KIP 支持；exactly-once |
| 任务队列 | `hibiken/asynq` | river（需 PG） | Redis 驱动；DLQ；retry；可视化 UI |
| Cron 调度 | `robfig/cron v3` | gocron v2 | 轻量；配合 redsync 分布式去重 |
| gRPC 框架 | `google.golang.org/grpc` | twirp | 行业标准；OTel 官方支持；mTLS |
| gRPC 中间件 | `go-grpc-middleware v2` | 自建 | auth + logging + metrics + recovery 统一链 |
| Metrics | `prometheus/client_golang` | — | 行业标准 |
| 链路追踪 | `opentelemetry-go` | jaeger-client | W3C TraceContext；vendor 中立 |
| 结构化日志 | `uber-go/zap` | zerolog | 高性能；ObjectMarshaler PII 脱敏 |
| 金融精度 | `shopspring/decimal` | — | **强制规则**，不得使用 float64 |

---

## 2. JWT 认证库

### 2.1 选型决策

- **签发 & 验证**: `github.com/golang-jwt/jwt/v5`
- **JWKS 端点** (供下游服务拉取公钥): `github.com/go-jose/go-jose/v4`

### 2.2 v4 → v5 关键破坏性变更

| 变更 | 影响 |
|------|------|
| `StandardClaims` 已移除 | 改用 `RegisteredClaims` |
| `Claims.Valid()` 签名变更 | 自定义校验改用 `ClaimsValidator` 接口的 `Validate() error` |
| `iat` 默认不校验 | 需显式 `jwt.WithIssuedAt()` |
| 解析器选项增加 | `WithLeeway`、`WithAudience`、`WithIssuer` |

### 2.3 RS256 签发模式

```go
// AMS Claims 定义
type AMSClaims struct {
    jwt.RegisteredClaims
    DeviceID  string `json:"device_id"`
    AccountID string `json:"account_id"`
}

// 实现 ClaimsValidator 接口，自定义业务校验
func (c AMSClaims) Validate() error {
    if c.DeviceID == "" {
        return errors.New("device_id claim is required")
    }
    return nil
}

// 签发 Access Token（15 分钟有效期）
func IssueAccessToken(privKey *rsa.PrivateKey, accountID, deviceID string) (string, string, error) {
    jti := uuid.NewString() // JTI 用于 blacklist
    now := time.Now().UTC()
    claims := AMSClaims{
        RegisteredClaims: jwt.RegisteredClaims{
            Subject:   accountID,
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(now.Add(15 * time.Minute)),
            Issuer:    "ams.brokerage.internal",
            ID:        jti,
        },
        DeviceID:  deviceID,
        AccountID: accountID,
    }
    token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
    signed, err := token.SignedString(privKey)
    return signed, jti, err
}

// 验证（任意下游服务）
func ParseAccessToken(pubKey *rsa.PublicKey, tokenStr string) (*AMSClaims, error) {
    var claims AMSClaims
    _, err := jwt.ParseWithClaims(tokenStr, &claims, func(t *jwt.Token) (interface{}, error) {
        if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
        }
        return pubKey, nil
    }, jwt.WithIssuedAt(), jwt.WithLeeway(5*time.Second))
    return &claims, err
}
```

### 2.4 Token Blacklist（Redis SETEX + JTI）

```go
// 撤销 Token（注销、强制下线）
func BlacklistToken(ctx context.Context, rdb *redis.Client, jti string, expiresAt time.Time) error {
    ttl := time.Until(expiresAt)
    if ttl <= 0 {
        return nil // 已过期，无需操作
    }
    return rdb.Set(ctx, "blacklist:"+jti, "1", ttl).Err()
}

// Auth 中间件校验（在签名验证通过后执行）
func IsBlacklisted(ctx context.Context, rdb *redis.Client, jti string) (bool, error) {
    n, err := rdb.Exists(ctx, "blacklist:"+jti).Result()
    return n > 0, err
}
```

### 2.5 Refresh Token Rotation（单次使用）

```go
// Lua 原子脚本：检查 RT 是否匹配 → 旋转
const rotateScript = `
local key = KEYS[1]
local expected = ARGV[1]
local newRT  = ARGV[2]
local ttl    = tonumber(ARGV[3])
local current = redis.call("HGET", key, "refresh_token")
if current ~= expected then
    return 0  -- 不匹配，可能是重放攻击，调用方应撤销该设备所有 token
end
redis.call("HSET", key, "refresh_token", newRT)
redis.call("EXPIRE", key, ttl)
return 1
`

func RotateRefreshToken(ctx context.Context, rdb *redis.Client, deviceID, oldRT, newRT string) (bool, error) {
    result, err := rdb.Eval(ctx, rotateScript,
        []string{"session:" + deviceID},
        oldRT, newRT, int64((7 * 24 * time.Hour).Seconds()),
    ).Int()
    return result == 1, err
}
```

> **安全规则**: RT mismatch（不匹配）= 可能重放攻击 → 立即吊销该 deviceID 的所有 session。

---

## 3. HTTP 框架 & API 规范

### 3.1 选型：go-chi/chi v5 + ogen-go/ogen

**选 chi 而非 gin 的原因**：
- chi 中间件是标准 `func(http.Handler) http.Handler`，无框架锁定
- multipart 流式上传（KYC 文档 → S3）无需绕过框架缓冲
- gin 每请求分配 `gin.Context`，chi 零额外分配

**选 ogen（contract-first）而非 swaggo 的原因**：
- 规范（`openapi.yaml`）是唯一真相源，消除文档漂移
- 生成的服务端接口类型安全，无 `interface{}`
- 下游服务（Trading Engine 等）可从同一规范生成类型安全客户端

### 3.2 中间件链

```go
r := chi.NewRouter()
r.Use(
    otelchi.Middleware("ams", otelchi.WithChiRoutes(r)), // OTel 链路追踪
    middleware.RequestID,            // 注入 X-Request-ID → context
    middleware.RealIP,
    middleware.Recoverer,
    correlationIDMiddleware,         // 读取/生成 X-Correlation-ID
    rateLimitMiddleware(rdb),        // Redis GCRA 限流
    jwtAuthMiddleware(pubKey, rdb),  // JWT 验证 + blacklist 检查
    auditLogMiddleware(logger),      // 所有状态变更请求写审计日志
)
```

**中间件顺序规则**：限流在认证之前（防止 DoS 打穿认证逻辑）。

### 3.3 KYC 文档流式上传（S3）

```go
func uploadKYCDocument(w http.ResponseWriter, r *http.Request) {
    // 限制 10MB，防止内存溢出
    if err := r.ParseMultipartForm(10 << 20); err != nil {
        http.Error(w, "file too large", http.StatusRequestEntityTooLarge)
        return
    }
    file, header, err := r.FormFile("document")
    if err != nil { /* handle */ return }
    defer file.Close()

    // 流式传输到 S3，不落本地磁盘
    uploader := manager.NewUploader(s3Client)
    result, err := uploader.Upload(r.Context(), &s3.PutObjectInput{
        Bucket:      aws.String(kycBucket),
        Key:         aws.String("kyc/" + accountID + "/" + uuid.NewString()),
        Body:        file, // io.Reader，S3 SDK 自动分片
        ContentType: aws.String(header.Header.Get("Content-Type")),
        ServerSideEncryption: types.ServerSideEncryptionAwsKms,
        SSEKMSKeyId: aws.String(kmsKeyARN),
    })
}
```

---

## 4. 数据库访问层

### 4.1 选型：uptrace/bun + pressly/goose

**选 bun 而非 sqlx 的原因**：
- 内置 `AddQueryHook`，统一附加 OTel 追踪 + 审计日志
- 原生 query builder（动态过滤无需字符串拼接）
- sqlx 维护趋于停滞（作者长期不活跃）

**选 goose 而非 golang-migrate 的原因**：
- 支持 Go 代码迁移（加密字段回填等业务逻辑必需）
- `//go:embed` 支持，二进制自包含
- out-of-order 迁移（多分支并行开发友好）

### 4.2 Append-Only 表保护 Hook

```go
// 开发期防护：任何对 account_status_events 的 UPDATE/DELETE 直接 panic
type AppendOnlyHook struct{}

func (h AppendOnlyHook) BeforeQuery(ctx context.Context, ev *bun.QueryEvent) context.Context {
    return ctx
}

func (h AppendOnlyHook) AfterQuery(ctx context.Context, ev *bun.QueryEvent) {
    op := strings.ToUpper(strings.Fields(ev.Query)[0])
    if ev.TableName == "account_status_events" && (op == "UPDATE" || op == "DELETE") {
        panic(fmt.Sprintf("AUDIT VIOLATION: %s on append-only table", op))
    }
}
```

> **数据库层双重保护**：MySQL 用户权限 `REVOKE UPDATE, DELETE ON account_status_events FROM 'ams_app'@'%'`，应用层 hook 作为开发期早期发现机制。

### 4.3 乐观锁（version 字段）

```go
func UpdateAccountStatus(ctx context.Context, db *bun.DB, accountID, newStatus string, expectedVersion int) error {
    res, err := db.NewUpdate().
        TableExpr("accounts").
        Set("account_status = ?", newStatus).
        Set("version = version + 1").
        Set("updated_at = ?", time.Now().UTC()).
        Where("account_id = ? AND version = ?", accountID, expectedVersion).
        Exec(ctx)
    if err != nil {
        return fmt.Errorf("update account status %s: %w", accountID, err)
    }
    n, _ := res.RowsAffected()
    if n == 0 {
        return ErrOptimisticLockConflict // 调用方重新读取后重试
    }
    return nil
}
```

### 4.4 迁移启动（嵌入式）

```go
//go:embed db/migrations/*.sql
var migrations embed.FS

func runMigrations(dsn string) error {
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        return fmt.Errorf("open db: %w", err)
    }
    goose.SetBaseFS(migrations)
    goose.SetDialect("mysql")
    return goose.Up(db, "db/migrations")
}
```

---

## 5. Redis 客户端

### 5.1 限流：GCRA（go-redis/redis_rate v9）

GCRA（Generic Cell Rate Algorithm）相比固定窗口的优势：防突刺攻击（固定窗口允许在边界时刻连续 2 倍速率请求）。

```go
limiter := redis_rate.NewLimiter(rdb)

// 登录端点：5次/5分钟/IP+用户
func LoginRateLimit(ctx context.Context, userID, ip string) error {
    key := fmt.Sprintf("ratelimit:login:%s:%s", userID, ip)
    res, err := limiter.Allow(ctx, key, redis_rate.Limit{
        Rate:   1,
        Burst:  5,
        Period: time.Minute,
    })
    if err != nil {
        return fmt.Errorf("rate limit check: %w", err)
    }
    if res.Allowed == 0 {
        return ErrTooManyRequests
    }
    return nil
}
```

**各端点限速配置**（参考 security-compliance.md）：

| 端点 | 限速 | 窗口 |
|------|------|------|
| 登录 | 5次 | 5分钟/IP+用户 |
| KYC 上传 | 5次 | 1分钟/用户 |
| 账户操作 | 30次 | 1秒/用户 |
| 订单提交（转发） | 10次 | 1秒/用户 |

### 5.2 Session Hash（含过期）

```go
func StoreSession(ctx context.Context, rdb *redis.Client, deviceID string, data map[string]interface{}) error {
    key := "session:" + deviceID
    pipe := rdb.Pipeline()
    pipe.HSet(ctx, key, data)
    pipe.Expire(ctx, key, 7*24*time.Hour) // Refresh Token 有效期一致
    _, err := pipe.Exec(ctx)
    return err
}
```

### 5.3 幂等键 Check-Then-Set（Lua 原子）

```go
const idempotencyScript = `
local key = KEYS[1]
local response = ARGV[1]
local ttl = tonumber(ARGV[2])
local existing = redis.call("GET", key)
if existing then
    return existing  -- 返回缓存响应
end
redis.call("SET", key, response, "EX", ttl)
return nil           -- 首次，继续处理
`

// 返回: (cachedResponse, isDuplicate, error)
func CheckOrSetIdempotency(ctx context.Context, rdb *redis.Client, key, responseJSON string) (string, bool, error) {
    result, err := rdb.Eval(ctx, idempotencyScript,
        []string{"idempotency:" + key},
        responseJSON,
        int64((72 * time.Hour).Seconds()),
    ).Result()
    if err == redis.Nil {
        return "", false, nil // 首次请求
    }
    if err != nil {
        return "", false, fmt.Errorf("idempotency check: %w", err)
    }
    return result.(string), true, nil // 重复请求，返回缓存
}
```

---

## 6. Kafka 事件发布

### 6.1 选型：twmb/franz-go

**选 franz-go 而非 sarama / confluent-kafka-go 的原因**：

| 关键因素 | franz-go | sarama | confluent-kafka-go |
|----------|----------|--------|-------------------|
| CGO 依赖 | ❌ 无 | ❌ 无 | ✅ **需要** |
| Docker 多架构构建 | ✅ 简单 | ✅ 简单 | ⚠️ 复杂 |
| Exactly-once 语义 | ✅ 完整 KIP | ⚠️ 有限 | ✅ 成熟 |
| 维护状态 | ✅ 活跃 | ⚠️ 放缓 | ✅ 活跃 |
| 吞吐量 | 最高 | 中等 | 高 |

confluent-kafka-go 的 CGO 依赖在 CI/CD 中造成实际摩擦：无法 `FROM scratch`，多架构交叉编译困难，构建环境必须携带 C 工具链。

### 6.2 Outbox Pattern（事务性事件发布）

**问题**：AMS 必须原子地写入 MySQL（账户状态变更）和发布 Kafka 事件，但不存在跨两者的分布式事务。

**解决方案**：Outbox 表

```
┌─────────────────────────────────────────────────────────────┐
│ MySQL 事务                                                   │
│  1. UPDATE accounts SET account_status = 'ACTIVE' ...       │
│  2. INSERT INTO outbox (event_type, payload) VALUES (...)   │
│                                                    COMMIT   │
└─────────────────────────────────────────────────────────────┘
                    │
                    │ Relay goroutine 500ms 轮询
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ franz-go Producer                                           │
│  Produce("ams.account-events", payload)                     │
│  On ACK: UPDATE outbox SET published_at = NOW()             │
└─────────────────────────────────────────────────────────────┘
```

```go
// Outbox Relay（AMS Pod 内后台 goroutine）
func RunOutboxRelay(ctx context.Context, db *bun.DB, producer *kgo.Client, logger *zap.Logger) {
    ticker := time.NewTicker(500 * time.Millisecond)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            if err := publishPendingEvents(ctx, db, producer); err != nil {
                logger.Error("outbox relay error", zap.Error(err))
            }
        }
    }
}

func publishPendingEvents(ctx context.Context, db *bun.DB, producer *kgo.Client) error {
    var events []OutboxEvent
    err := db.NewSelect().Model(&events).
        Where("published_at IS NULL").
        OrderExpr("id ASC").
        Limit(100).
        Scan(ctx)
    if err != nil {
        return fmt.Errorf("fetch outbox: %w", err)
    }
    for _, ev := range events {
        record := &kgo.Record{
            Topic: topicForEvent(ev.EventType),
            Key:   []byte(ev.AggregateID), // 保证同一账户的事件有序
            Value: ev.Payload,
        }
        // 注入 OTel 链路上下文
        otel.GetTextMapPropagator().Inject(ctx, &kafkaHeaderCarrier{record: record})

        if err := producer.ProduceSync(ctx, record).FirstErr(); err != nil {
            return fmt.Errorf("produce event %d: %w", ev.ID, err)
        }
        now := time.Now().UTC()
        if _, err := db.NewUpdate().Model(&ev).
            Set("published_at = ?", now).
            Where("id = ?", ev.ID).
            Exec(ctx); err != nil {
            return fmt.Errorf("mark published %d: %w", ev.ID, err)
        }
    }
    return nil
}
```

### 6.3 AMS Topic 设计

| Topic | 触发条件 | 消费方 |
|-------|----------|--------|
| `ams.account.status_changed` | 账户状态机转换 | Trading Engine, Fund Transfer, Admin Panel |
| `ams.kyc.completed` | KYC 审核通过/拒绝 | Mobile（推送通知）, Admin Panel |
| `ams.aml.flagged` | AML 命中或风险评级变更 | Fund Transfer（限制出金）, Admin Panel |
| `ams.tax_form.expiring` | W-8BEN 到期前 90 天 | Mobile（推送通知）, Admin Panel |
| `ams.session.revoked` | 设备 Session 强制撤销 | 所有服务（使其他服务的 token 缓存失效） |

---

## 7. 后台任务调度

### 7.1 两类任务的不同工具

| 任务类型 | 工具 | 原因 |
|----------|------|------|
| W-8BEN 90天提醒（每日 cron） | `robfig/cron v3` + `redsync` 锁 | 轻量 cron；Redis 锁防多 Pod 重复执行 |
| AML 每日全量筛查（10万账户批量） | `hibiken/asynq` 任务队列 | 独立重试；DLQ；AsynqMon 可视化；并行 worker |
| KYC 状态机超时检查 | `hibiken/asynq` 延迟任务 | 延迟投递（如 24h 超时自动拒绝） |

**不选 river 的原因**：river 依赖 PostgreSQL；AMS 主数据库是 MySQL，引入 PG 仅为 job queue 不合适。

### 7.2 W-8BEN 90 天提醒

```go
c := cron.New(cron.WithLocation(time.UTC))
c.AddFunc("0 2 * * *", func() { // 每天 UTC 02:00
    mu := rs.NewMutex("cron:w8ben-reminder", redsync.WithTries(1))
    if err := mu.Lock(); err != nil {
        return // 另一个 Pod 正在运行，跳过
    }
    defer mu.Unlock()

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
    defer cancel()
    sendW8BENReminders(ctx, db, asynqClient)
})
c.Start()

func sendW8BENReminders(ctx context.Context, db *bun.DB, client *asynq.Client) {
    var accounts []struct{ AccountID string }
    db.NewSelect().
        TableExpr("tax_forms").
        ColumnExpr("account_id").
        Where("form_type = 'W8BEN'").
        Where("tax_form_expires_at BETWEEN ? AND ?",
            time.Now().UTC().Add(89*24*time.Hour),
            time.Now().UTC().Add(91*24*time.Hour),
        ).
        Scan(ctx, &accounts)

    for _, a := range accounts {
        payload, _ := json.Marshal(map[string]string{"account_id": a.AccountID})
        task := asynq.NewTask("notification:w8ben-expiring", payload,
            asynq.MaxRetry(3),
            asynq.Timeout(30*time.Second),
        )
        client.EnqueueContext(ctx, task)
    }
}
```

### 7.3 AML 批量筛查 Fan-Out 模式

```go
// Dispatcher：每天 UTC 03:00，将 10 万账户分发为独立任务
c.AddFunc("0 3 * * *", func() {
    mu := rs.NewMutex("cron:aml-dispatcher", redsync.WithTries(1))
    if err := mu.Lock(); err != nil { return }
    defer mu.Unlock()

    var offset int
    for {
        ids, _ := fetchActiveAccountIDs(ctx, db, offset, 1000)
        if len(ids) == 0 { break }
        for _, id := range ids {
            payload, _ := json.Marshal(map[string]string{"account_id": id})
            client.Enqueue(asynq.NewTask("aml:screen-account", payload,
                asynq.MaxRetry(3),
                asynq.Timeout(30*time.Second),
                asynq.Queue("aml"),
            ))
        }
        offset += 1000
    }
})

// Worker（并发处理独立任务，单个失败不阻塞其他）
mux.HandleFunc("aml:screen-account", amlWorker.HandleScreenAccount)
srv := asynq.NewServer(redis.ParseURL(redisURL), asynq.Config{
    Queues: map[string]int{
        "aml":      3, // 3 个并发 worker
        "critical": 6,
        "default":  1,
    },
})
```

---

## 8. gRPC 服务间通信

### 8.1 Interceptor 链（go-grpc-middleware v2）

v2 的关键变化：每个 interceptor 独立子包，避免依赖膨胀；`selector` interceptor 取代旧的 "deciders" API。

```go
srvMetrics := grpcprom.NewServerMetrics()

srv := grpc.NewServer(
    grpc.StatsHandler(otelgrpc.NewServerHandler()), // OTel 链路（统计处理器，非已废弃的拦截器方式）
    grpc.ChainUnaryInterceptor(
        srvMetrics.UnaryServerInterceptor(),                              // Prometheus 指标
        logging.UnaryServerInterceptor(zapGRPCLogger(logger)),            // 结构化日志
        selector.UnaryServerInterceptor(                                  // JWT 认证（排除 health check）
            auth.UnaryServerInterceptor(jwtAuthFunc),
            selector.MatchFunc(excludeHealthCheck),
        ),
        recovery.UnaryServerInterceptor(recovery.WithRecoveryHandler(panicToGRPCError)),
    ),
    grpc.ChainStreamInterceptor(/* 同上 */),
)
```

### 8.2 错误码语义

| 场景 | gRPC Code | HTTP 映射 |
|------|-----------|-----------|
| 无 Authorization header | `Unauthenticated` | 401 |
| Token 过期 / 签名无效 | `Unauthenticated` | 401 |
| JTI 在黑名单中 | `Unauthenticated` | 401 |
| Token 有效但无权限（如访问他人账户） | `PermissionDenied` | 403 |
| 合规官权限不足 | `PermissionDenied` | 403 |
| 账户不存在 | `NotFound` | 404 |
| 乐观锁冲突 | `Aborted` | 409 |
| 重复请求（幂等 key 已存在） | `AlreadyExists` | 409 |

> **规则**：客户端收到 `Unauthenticated` 应重新认证；收到 `PermissionDenied` 不应重认证（换 token 也没用）。

### 8.3 mTLS 证书热轮换

```go
// 使用 advancedtls 包，每次 TLS 握手重新加载证书
// cert-manager（K8s）或 Vault PKI 负责文件轮换
serverOpts := &advancedtls.Options{
    IdentityOptions: advancedtls.IdentityCertificateOptions{
        GetIdentityCertificatesForServer: func(_ *tls.ClientHelloInfo) ([]*tls.Certificate, error) {
            return certCache.Get() // 内部有 60s TTL 缓存，避免每次磁盘读
        },
    },
    RootOptions: advancedtls.RootCertificateOptions{
        GetRootCAs: func(_ *advancedtls.GetRootCAsParams) (*advancedtls.GetRootCAsResults, error) {
            pool, err := certCache.GetRootCAs()
            return &advancedtls.GetRootCAsResults{TrustCerts: pool}, err
        },
    },
    RequireClientCert: true,
}
creds, _ := advancedtls.NewServerCredentials(serverOpts)
```

**零停机原理**：现有连接继续使用旧证书完成握手；新连接在握手时读取新证书文件。

### 8.4 Deadline Propagation 规则

```go
// ✅ 正确：将 context 传递到所有下游调用
func (s *AccountService) ValidateAccount(ctx context.Context, req *pb.ValidateAccountRequest) (*pb.ValidateAccountResponse, error) {
    account, err := s.repo.GetAccount(ctx, req.AccountId) // ctx 携带调用方的 deadline
    if err != nil {
        return nil, status.Errorf(codes.Internal, "get account: %v", err)
    }
    return &pb.ValidateAccountResponse{IsValid: account.IsActive()}, nil
}

// ❌ 错误：创建新 context 丢失 deadline
func (s *AccountService) ValidateAccount(_ context.Context, req *pb.ValidateAccountRequest) (*pb.ValidateAccountResponse, error) {
    ctx := context.Background() // 绝对禁止
    ...
}
```

---

## 9. 可观测性

### 9.1 OTel Trace Context 跨层传播

```
HTTP 请求 (X-Traceparent header)
    → chi otelchi.Middleware 自动提取
        → handler 内 ctx 携带 span
            → gRPC 调用（otelgrpc.NewServerHandler 自动注入/提取）
                → Kafka 发布（手动注入 record headers）
```

```go
// Kafka 生产者：注入 trace context 到 record headers
type kafkaHeaderCarrier struct{ record *kgo.Record }

func (c *kafkaHeaderCarrier) Get(key string) string {
    for _, h := range c.record.Headers {
        if h.Key == key { return string(h.Value) }
    }
    return ""
}
func (c *kafkaHeaderCarrier) Set(key, val string) {
    c.record.Headers = append(c.record.Headers, kgo.RecordHeader{Key: key, Value: []byte(val)})
}
func (c *kafkaHeaderCarrier) Keys() []string {
    keys := make([]string, len(c.record.Headers))
    for i, h := range c.record.Headers { keys[i] = h.Key }
    return keys
}

func PublishWithTrace(ctx context.Context, producer *kgo.Client, topic string, payload []byte) {
    record := &kgo.Record{Topic: topic, Value: payload}
    otel.GetTextMapPropagator().Inject(ctx, &kafkaHeaderCarrier{record: record})
    producer.ProduceSync(ctx, record)
}
```

### 9.2 Zap PII 日志脱敏

```go
// 实现 zapcore.ObjectMarshaler，控制敏感字段的序列化
type MaskedKYCProfile struct {
    AccountID string
    IDType    string
    IDNumber  string
}

func (p MaskedKYCProfile) MarshalLogObject(enc zapcore.ObjectEncoder) error {
    enc.AddString("account_id", p.AccountID)
    enc.AddString("id_type", p.IDType)
    enc.AddString("id_number", maskIDNumber(p.IDType, p.IDNumber))
    return nil
}

func maskIDNumber(idType, id string) string {
    switch idType {
    case "SSN":
        if len(id) < 4 { return "***-**-****" }
        return "***-**-" + id[len(id)-4:]
    case "HKID":
        if len(id) < 2 { return "****" }
        return string(id[0]) + "****" + id[len(id)-3:]
    default:
        return "[REDACTED]"
    }
}

// 使用方式（类型安全，不会意外泄露）
logger.Info("kyc document submitted",
    zap.Object("profile", MaskedKYCProfile{AccountID: acc, IDType: "HKID", IDNumber: raw}),
    zap.String("correlation_id", correlationID),
)
// 输出: {"profile":{"account_id":"acc-123","id_type":"HKID","id_number":"A****7(3)"}}
```

**兜底 PII 检测**（防止遗漏）：

```go
// 正则兜底：捕获意外的明文 SSN
var ssnRegex = regexp.MustCompile(`\b\d{3}-\d{2}-\d{4}\b`)

type piiRedactCore struct{ zapcore.Core }

func (c *piiRedactCore) Write(entry zapcore.Entry, fields []zapcore.Field) error {
    for i, f := range fields {
        if f.Type == zapcore.StringType {
            fields[i].String = ssnRegex.ReplaceAllString(f.String, "***-**-****")
        }
    }
    return c.Core.Write(entry, fields)
}
```

### 9.3 AMS 自定义 Prometheus 指标

```go
var (
    // KYC 审核积压
    KYCQueueDepth = promauto.NewGaugeVec(prometheus.GaugeOpts{
        Name: "ams_kyc_queue_depth",
        Help: "Accounts pending KYC review by status",
    }, []string{"status"}) // MANUAL_REVIEW, AML_SCREENING, PENDING_DOCUMENTS

    // AML 命中率
    AMLScreeningResults = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "ams_aml_screening_results_total",
        Help: "AML screening outcomes",
    }, []string{"result", "list"}) // result=MATCH|CLEAR|REVIEW, list=OFAC_SDN|UN_SANCTIONS

    // Token 撤销
    TokenRevocations = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "ams_token_revocations_total",
        Help: "JWT token revocations",
    }, []string{"reason"}) // LOGOUT, FORCED, SECURITY_EVENT

    // 账户状态转换
    AccountStatusTransitions = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "ams_account_status_transitions_total",
        Help: "Account lifecycle state transitions",
    }, []string{"from", "to", "reason"})

    // W-8BEN 到期预警
    W8BENExpiringCount = promauto.NewGauge(prometheus.GaugeOpts{
        Name: "ams_w8ben_expiring_accounts",
        Help: "Accounts with W-8BEN expiring within 90 days",
    })
)

// 内部 metrics + health 端点（独立端口，不暴露给公网）
internalMux := http.NewServeMux()
internalMux.Handle("/metrics", promhttp.Handler())
internalMux.Handle("/healthz", healthHandler)
go http.ListenAndServe(":9090", internalMux)
```

---

## 10. PII 加密

> 详细方案见 `docs/specs/pii-encryption.md`（待独立文档）。
> 本节为快速参考。

**强制规则**（来自 security-compliance.md）：

| 字段 | 加密方式 | 索引策略 |
|------|----------|----------|
| SSN | AES-256-GCM（envelope encryption via KMS） | HMAC-SHA256 blind index |
| HKID | AES-256-GCM | HMAC-SHA256 blind index |
| 护照号 | AES-256-GCM | HMAC-SHA256 blind index |
| 银行账号 | AES-256-GCM | HMAC-SHA256 blind index |
| 出生日期（+其他标识符时） | AES-256-GCM | 不需要索引 |

**KMS 选型建议**：AWS KMS（当平台部署在 AWS 上时，HSM 标准，$$0.03/1万次 API 调用）。

**Envelope Encryption 原理**：

```
KMS Master Key（CMK）
    └── 加密 DEK（Data Encryption Key，每账户生成一个）
           └── DEK 加密各 PII 字段（AES-256-GCM）
```

MySQL 存储格式（每个加密字段）：`base64(nonce || ciphertext) | key_version`

---

## 11. Go Module 依赖清单

```
# 认证
github.com/golang-jwt/jwt/v5
github.com/go-jose/go-jose/v4       # JWKS 端点（可选）

# HTTP
github.com/go-chi/chi/v5
github.com/ogen-go/ogen              # contract-first OpenAPI 代码生成

# 数据库
github.com/uptrace/bun
github.com/uptrace/bun/driver/mysqldialect
github.com/go-sql-driver/mysql
github.com/pressly/goose/v3

# Redis
github.com/redis/go-redis/v9
github.com/go-redis/redis_rate/v9    # GCRA 限流
github.com/go-redsync/redsync/v4     # 分布式锁

# Kafka
github.com/twmb/franz-go/pkg/kgo

# 后台任务
github.com/hibiken/asynq
github.com/robfig/cron/v3

# gRPC
google.golang.org/grpc
google.golang.org/grpc/security/advancedtls   # mTLS 热轮换
github.com/grpc-ecosystem/go-grpc-middleware/v2

# 可观测性
go.opentelemetry.io/otel
go.opentelemetry.io/otel/exporters/prometheus
go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp
go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc
github.com/riandyrn/otelchi          # chi OTel 中间件
go.uber.org/zap
github.com/prometheus/client_golang/prometheus
github.com/prometheus/client_golang/prometheus/promauto
github.com/prometheus/client_golang/prometheus/promhttp

# 存储
github.com/aws/aws-sdk-go-v2
github.com/aws/aws-sdk-go-v2/service/s3
github.com/aws/aws-sdk-go-v2/service/kms
github.com/aws/aws-sdk-go-v2/feature/s3/manager

# 工具
github.com/google/uuid
github.com/shopspring/decimal       # 强制：金融金额严禁 float64
```

---

*参考来源：AMS Go Library Technical Decision Report（2026-03-17），基于 golang-jwt、ogen、bun、franz-go、asynq、grpc-middleware v2、OpenTelemetry 官方文档及社区最佳实践综合分析。*
