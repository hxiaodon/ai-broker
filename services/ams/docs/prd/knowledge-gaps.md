# AMS 工程师知识体系梳理 — 业务 & 技术盲点分析

> **版本**: v0.2
> **日期**: 2026-03-17
> **作者**: AMS Engineering
> **状态**: 调研完成 — 各盲点已落地为独立文档，待 PM / 合规团队对齐开放决策点

本文梳理 AMS 工程师在上手编码前需要补充的业务知识与技术知识，以及需与产品、合规团队讨论的关键决策点。

---

## 目录

1. [业务知识盲点](#一业务知识盲点)
2. [技术知识盲点（Go 生态）](#二技术知识盲点go-生态为主)
3. [优先补课顺序](#三优先补课顺序)
4. [待讨论的关键决策点](#四待讨论的关键决策点)

---

## 一、业务知识盲点

### 1. KYC / 身份验证流程

| 盲点 | 为什么重要 |
|------|-----------|
| **三方 KYC 供应商选型**（Jumio / Onfido / iDenfy / Sumsub） | 影响 OCR 精度、活体检测方案、SDK 集成方式、SLA |
| **HK 非面对面开户 — 指定银行名单** | AMLO 要求 ≥HK$10K 验证转账，需确认哪些香港银行可接受 |
| **中国大陆用户开户路径** | 护照 or 大陆身份证？SFC 对大陆居民的 KYC 要求？ |
| **联名账户（Joint Account）KYC 状态机** | 两位申请人 KYC 是否需要同时通过？是否支持分步完成？ |
| **公司账户（Corporate）— UBO 穿透规则** | ≥25% 股东逐层穿透，每位 UBO 单独 KYC；审核 SLA 如何设定？ |
| **专业投资者（PI）认定流程** | HK HK$800 万组合或 HK$4000 万资产，在线自助 vs 人工审核？年度续期如何通知？ |

### 2. AML / 制裁合规

| 盲点 | 为什么重要 |
|------|-----------|
| **制裁名单供应商选型**（Dow Jones / Refinitiv / LexisNexis / 自建） | 影响命中率、误报率、API 延迟、合规认可度 |
| **PEP 判定标准 — 中国大陆官员** | 2023 AMLO 修订将大陆官员纳入"非香港 PEP"→ 强制 EDD，需了解实操边界 |
| **AML 风险评分算法** | 哪些因子？权重？第三方评分服务 vs 内部规则引擎？触发 EDD 阈值？ |
| **SAR/STR 不得"泄露"（Tipping-off）规则** | 一旦提交 SAR，不能告知客户，API 设计必须隐藏此状态 |
| **CTR 责任归属** | 存款触发 CTR — AMS 负责标记、Fund Transfer 负责提交？还是 Fund Transfer 全责？ |
| **结构性交易（Structuring）检测逻辑** | 同一天多笔小额？阈值如何设定？是 AMS 还是 Fund Transfer 负责检测？ |

### 3. 税务合规

| 盲点 | 为什么重要 |
|------|-----------|
| **W-8BEN 续签工作流** | 90 天前通知 → 到期冻结股息 → 30% 预扣税；谁触发 Job？用户在哪里重新签？ |
| **FATCA Chapter 4 实体状态分类** | W-8BEN-E 中 FATCA status（NFFE / PFIC / Certified deemed-compliant 等）业务含义 |
| **CRS 多税务居民地申报** | 用户可能同时持有美国、香港、中国大陆税务居民身份，多行 TIN 存储与校验 |

### 4. 账户类型 & 交易权限

| 盲点 | 为什么重要 |
|------|-----------|
| **PDT 规则当前状态**（2026 年） | FINRA 2026-01 提案还未获 SEC 批准；$25,000 门槛依然生效，代码不能提前假设新规 |
| **Reg BI"合理理由"（Reasonable Basis）判断** | 执行型（Execution-only）平台 Reg BI 豁免边界是什么？ |
| **保证金账户审批标准** | 哪些收入/资产指标可自动审批？哪些需要人工？HK 要求 SFC Type 8 牌照细节 |
| **期权分级（Level 0-4）自动审批条件** | 每级的投资经验/资产最低门槛，目前文档只说"Level 3+ 人工审核" |
| **IRA 账户（Traditional / Roth）特殊规则** | Phase 2 项，但了解其税务优势与取款规则有助于 PRD 评审 |

### 5. 运营流程

| 盲点 | 为什么重要 |
|------|-----------|
| **合规官工作流**（KYC 审核队列） | 审核 SLA？驳回标准？多级审核权限（初审/终审）？ |
| **账户注销后的数据访问权** | 6 年数据保留，但哪些角色可以访问 CLOSED 账户？API 层如何限制？ |
| **用户反投诉 / 申诉流程** | KYC 被拒后客户可申请复核，AMS 需要哪些状态来支撑？ |

---

## 二、技术知识盲点（Go 生态为主）

### 1. 认证 & 授权

#### JWT RS256 实现

- **三方库**: [`golang-jwt/jwt/v5`](https://github.com/golang-jwt/jwt) — 最稳定，v4→v5 破坏性变更已稳定
- **知识点**:
  - RS256 私钥签发 + 公钥验证（跨服务分发公钥）
  - Token Blacklist 用 Redis SETEX（TTL = refresh token 剩余有效期）
  - Device binding：`device_id` claim + Redis session hash 存 device fingerprint
  - Token Rotation：Refresh Token 单次使用（rotation）策略，防止 refresh token 泄露后无限续期

#### OAuth2 / OIDC（可选，用于 Admin Panel 的 SSO）

- **三方库**: [`go-jose/go-jose`](https://github.com/go-jose/go-jose) — 成熟的 JOSE 实现
- **知识点**: PKCE flow、introspection endpoint、RBAC claims

#### RBAC 权限模型（Admin Panel）

- **三方库**: [`casbin/casbin`](https://github.com/casbin/casbin) — Go 最主流的 RBAC/ABAC 库
- **知识点**: RBAC0/RBAC3 模型选择；policy 存储（MySQL adapter）；每次请求的 Enforce 性能优化

### 2. 人脸识别 / 活体检测（Liveness Detection）

AMS 负责 KYC 文档收集，活体检测通常委托给三方 KYC SDK。

| 方案 | 集成方式 | 优劣 |
|------|----------|------|
| **Jumio Netverify** | REST API | 证件 OCR + 活体检测一体，合规认可高，价格贵 |
| **Onfido** | REST API | 文档 + 面部比对，ISO 30107-3 Liveness 认证 |
| **iDenfy** | REST API | 性价比较高，支持 HKID |
| **Sumsub** | REST API | 快速集成，支持中文护照/大陆居民身份证 |
| **自建（OpenCV + FaceLiveness）** | Go FFI | 成本低但合规认可难，强烈不建议 |

**Go 端职责**:
- 生成临时 Token（SDK token）返回给 Mobile，Mobile 调 SDK 完成活体
- 接收 Webhook 回调：`event_type=CHECK_COMPLETED`，更新 KYC 状态
- 需要熟悉 Webhook 签名验证（HMAC-SHA256）

**知识点**:
- ISO/IEC 30107-3 PAD（Presentation Attack Detection）等级（Jumio/Onfido 都支持 Level 1/2）
- 活体检测误报率（FAR/FRR）业务影响
- 主动式活体（翻转头部）vs 被动式活体（AI 判断静态视频）

### 3. 密码学 & PII 加密

- **三方库**: Go 标准库 `crypto/aes` + `crypto/cipher`（GCM mode）已足够
  - 或 [`google/tink`](https://github.com/google/tink) — 封装了 AES-256-GCM + key rotation 原语，更安全防误用
- **知识点**:
  - AES-256-GCM：12-byte nonce（随机生成，每次加密不同），16-byte tag
  - **Envelope encryption**：用 KMS Master Key 加密 DEK（Data Encryption Key），DEK 加密数据；支持无停机 key rotation
  - KMS 选型：AWS KMS / GCP Cloud KMS / HashiCorp Vault Transit Secrets Engine
  - 数据库存储：`VARBINARY` 或 `TEXT` with base64（encrypted blob + nonce + key_version）
  - **索引问题**：加密字段无法直接 B-Tree 索引，需要存 HMAC（SHA-256(plaintext)）用于精确匹配查询

### 4. 数据库 & 持久化

- **三方库**: [`jmoiron/sqlx`](https://github.com/jmoiron/sqlx) + [`go-sql-driver/mysql`](https://github.com/go-sql-driver/mysql)
  - 或 [`uptrace/bun`](https://github.com/uptrace/bun) — 更现代，内置 ORM + query builder，有 MySQL 支持
- **知识点**:
  - Append-only 表强制：MySQL 层 `REVOKE UPDATE, DELETE ON account_status_events FROM 'app_user'@'%'`
  - 乐观锁（optimistic locking）：`version` 字段 + `UPDATE ... WHERE version = ?`；Go 层检测 `rows affected = 0`
  - 审计字段自动填充：`created_at` / `updated_at` 的 hook
  - 大表分区策略：`account_status_events` 按年分区（`PARTITION BY RANGE YEAR(created_at)`）
  - 读写分离：Primary 写，Replica 读（`sqlx.DB` 多实例 + 业务层路由）

### 5. gRPC & 服务间通信

- **三方库**: [`google.golang.org/grpc`](https://pkg.go.dev/google.golang.org/grpc) + [`grpc-ecosystem/go-grpc-middleware`](https://github.com/grpc-ecosystem/go-grpc-middleware)
- **知识点**:
  - Proto3 + `google.protobuf.Timestamp`（UTC 时间标准化）
  - Unary interceptor 链：auth 验证 + logging + metrics + recovery
  - mTLS（服务间双向 TLS），证书轮换不中断服务
  - 错误传播：`google.golang.org/grpc/status` + `google.golang.org/grpc/codes`（`Code_UNAUTHENTICATED`、`Code_PERMISSION_DENIED` 语义区分）
  - gRPC health check protocol（`grpc.health.v1`）
  - Deadline propagation（Context deadline 跨服务传递）

### 6. Redis（Session / Blacklist / Rate Limiting）

- **三方库**: [`redis/go-redis/v9`](https://github.com/redis/go-redis)
- **知识点**:
  - Token blacklist：`SET blacklist:{jti} 1 EX {seconds}` — TTL = access token 剩余有效期
  - Rate limiting：`INCR rate:{userID}:{window}` + `EXPIRE`；或用 Redis Cell 模块（GCRA 算法）
  - Session hash：`HSET session:{deviceID} user_id ... ip ...`
  - Lua script 原子操作（防止 TOCTOU race condition）
  - Redis Cluster vs Redis Sentinel — HA 策略选型

### 7. 任务调度（W-8BEN 到期提醒、批量 AML 筛查）

- **三方库**:
  - [`robfig/cron/v3`](https://github.com/robfig/cron) — 单节点 Cron
  - [`go-co-op/gocron`](https://github.com/go-co-op/gocron) — 更现代，支持分布式锁
  - [`riverqueue/river`](https://github.com/riverqueue/river) — background job queue（若考虑换 PostgreSQL）
  - 或 Kafka Consumer 驱动定时任务
- **知识点**:
  - 分布式锁（Redis SETNX or `go-redis/v9` Lock）防止多 Pod 重复执行
  - Dead letter queue：任务失败后的重试策略 + 告警
  - W-8BEN 90 天提醒：每日批量扫描 `WHERE tax_form_expires_at < NOW() + INTERVAL 90 DAY`

### 8. Kafka（事件发布）

- **三方库**: [`IBM/sarama`](https://github.com/IBM/sarama) 或 [`confluentinc/confluent-kafka-go`](https://github.com/confluentinc/confluent-kafka-go)（CGO 依赖，部署复杂）
- **知识点**:
  - **Outbox Pattern**：DB 事务内写 `outbox` 表，异步 Relay → Kafka（保证事件不丢失）
  - At-least-once vs Exactly-once 语义（幂等 Producer + Transactional API）
  - Topic 设计：`ams.account.status_changed`、`ams.kyc.completed`、`ams.aml.flagged`
  - Consumer Group + Offset 管理
  - Schema Registry（Avro/Protobuf）保证跨服务消息格式兼容

### 9. 通知服务（Push / SMS / Email）

- **三方库 / 服务**:
  - Push：APNs（iOS）+ FCM（Android）→ `sideshow/apns2` + `appleboy/go-fcm`
  - SMS：Twilio / AWS SNS / 阿里云短信
  - Email：AWS SES / SendGrid → [`sendgrid/sendgrid-go`](https://github.com/sendgrid/sendgrid-go)
- **知识点**:
  - 通知幂等：`Idempotency-Key` 防重复发送
  - 通知模板国际化（中/英文，用户语言偏好）
  - Delivery status callback / bounce handling
  - 通知优先级：合规通知（KYC 拒绝、账户冻结）需要多渠道冗余发送

### 10. 可观测性

- **三方库**:
  - Metrics：[`prometheus/client_golang`](https://github.com/prometheus/client_golang)
  - Tracing：[`open-telemetry/opentelemetry-go`](https://github.com/open-telemetry/opentelemetry-go) — 分布式链路追踪
  - Logging：[`uber-go/zap`](https://github.com/uber-go/zap) — 结构化日志，高性能
- **知识点**:
  - Correlation ID 在日志/trace 中全链路传播（HTTP header `X-Correlation-ID` → gRPC metadata → Kafka header）
  - PII 日志脱敏（zap `Field` 自定义 marshaller 隐藏 SSN/HKID）
  - Custom metrics：KYC 审核积压量、AML 命中率、Token 撤销频率、W-8BEN 到期预警数

### 11. API 层（REST Gateway）

- **三方库**: [`go-chi/chi/v5`](https://github.com/go-chi/chi) 或 [`gin-gonic/gin`](https://github.com/gin-gonic/gin)
- **知识点**:
  - Middleware 链：Rate Limit → Auth → Correlation ID → Request Logging → Audit
  - Request validation：[`go-playground/validator`](https://github.com/go-playground/validator)
  - OpenAPI spec 生成：[`swaggo/swag`](https://github.com/swaggo/swag)（code-first）或 contract-first（`openapi.yaml` + `ogen-go/ogen` 生成代码）
  - CORS 中间件：限制允许的 Origin 列表
  - 文件上传（KYC 文档）：multipart/form-data → Stream to S3，避免内存溢出

### 12. KYC 文档存储（S3）

- **三方库**: [`aws/aws-sdk-go-v2`](https://github.com/aws/aws-sdk-go-v2) — S3 SSE-KMS server-side encryption
- **知识点**:
  - Pre-signed URL（客户端直传 S3，AMS 只验证回调）
  - S3 Object Lock（WORM）for KYC documents — 防止误删除
  - Virus scan on upload（Lambda + ClamAV 或 AWS Macie）

---

## 三、优先补课顺序

### 第一优先级（开始写代码前必须搞清楚）

1. KYC 供应商选型 → 影响 onboarding flow 架构
2. AML / 制裁名单供应商选型 → 影响风险评分设计
3. PII 加密 key 管理方案（Vault vs AWS KMS）
4. JWT RS256 + Token Blacklist + Device Binding → 核心认证模块
5. gRPC proto 设计 + 跨服务错误码规范

### 第二优先级（MVP 前需要）

6. Kafka Outbox Pattern → 事件可靠发布
7. W-8BEN 定时任务框架选型（单节点 cron or 分布式 job queue）
8. RBAC 权限模型（Casbin or 自建）→ Admin Panel 访问控制
9. 结构化日志 + PII 脱敏工具函数
10. Rate limiting（Redis GCRA）

### 第三优先级（Phase 2 / 可延迟）

11. OAuth2 / OIDC（Admin SSO）
12. 活体检测 ISO 30107-3 细节（供应商已处理）
13. IRA 账户规则
14. PI 年度续期自动化

---

## 四、待讨论的关键决策点

以下是需要与 PM / 合规团队对齐的开放性问题，**在写任何代码前必须确认**：

| # | 问题 | 选项 / 考量 |
|---|------|------------|
| 1 | **KYC 供应商** | Jumio / Onfido / Sumsub / 其他？主要考量：大陆身份证支持、价格、合规认可 |
| 2 | **制裁名单供应商** | 购买数据还是订阅 API？误报率可接受水平？ |
| 3 | **Key Management** | AWS KMS、GCP KMS、HashiCorp Vault 哪个？ |
| 4 | **API 框架** | Gin vs Chi？Contract-first（ogen）还是 code-first（swag）？ |
| 5 | **Background Jobs** | `robfig/cron` + Redis 分布式锁 足够，还是引入专门的 job queue（River/Asynq）？ |
| 6 | **Joint Account MVP** | Phase 1 包含还是延迟？（影响 KYC 状态机复杂度） |
| 7 | **PDT 规则 2026** | FINRA 提案未获批，代码中如何处理"可能变更"的规则？硬编码还是配置化？ |
| 8 | **DB 访问层** | `sqlx`（轻量 SQL）还是 `bun`（ORM）？ |
| 9 | **事件总线** | `IBM/sarama` 还是 `confluent-kafka-go`？（后者有 CGO 依赖） |
| 10 | **AML 风险评分** | 第三方评分服务 vs 内部规则引擎？触发 EDD 的阈值由谁定？ |

---

## 附：调研落地状态

| 盲点 | 文档 | 状态 |
|------|------|------|
| KYC 供应商选型 | `docs/prd/kyc-flow.md` | ✅ 已完成（**选定 Sumsub**，备选 Jumio） |
| AML 供应商选型 | `docs/prd/aml-compliance.md` | ✅ 已完成（**选定 ComplyAdvantage**，EDD 用 World-Check） |
| KMS & PII 加密方案 | `docs/specs/pii-encryption.md` | ✅ 已完成（**AWS KMS + Tink**，PBKDF2 Blind Index） |
| Go 技术栈选型 | `docs/specs/tech-stack.md` | ✅ 已完成（chi/ogen/bun/franz-go/asynq 等） |
| JWT & 认证架构 | `docs/specs/auth-architecture.md` | ✅ 已完成（RS256/Device Binding/RBAC） |
| KYC 流程 & 状态机 | `docs/prd/kyc-flow.md` | ✅ 已完成（各用户群体路径 / W-8BEN 续签） |
| AML 风险评分 & SAR | `docs/prd/aml-compliance.md` | ✅ 已完成（Tipping-off 防护 / CTR 边界） |

## 下一步：待 PM / 合规团队确认的开放决策点

参见各文档末尾的"开放决策点"章节：
- `docs/prd/kyc-flow.md` §13：7 个待决问题（联名账户 MVP、大陆居民银行验证、供应商最终选型等）
- `docs/prd/aml-compliance.md` §12：7 个待决问题（HK JFIU 名单覆盖、风险评分权重、STR 申报架构等）
- `docs/specs/auth-architecture.md`：Admin Panel SSO 方案待定

---

*参考：`services/ams/docs/specs/account-financial-model.md` — AMS 金融业务模型规格（963 行，v0.2-draft）*
