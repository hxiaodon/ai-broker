# 后端工程师设计评审报告

> 评审范围：mobile-app-design v1 / v2 / v3-supplement 三份设计文档 + UX 设计师问题清单
> 评审视角：Backend Engineer（Go, PostgreSQL, Redis, Kafka）
> 日期：2026-03-11
> 评审人：Backend Engineer

---

## 目录

1. [API 设计评估](#1-api-设计评估)
2. [服务拆分建议](#2-服务拆分建议)
3. [KYC/AML 后端实现](#3-kycaml-后端实现)
4. [用户认证与会话管理](#4-用户认证与会话管理)
5. [行情数据架构](#5-行情数据架构)
6. [消息推送架构](#6-消息推送架构)
7. [数据库设计关注点](#7-数据库设计关注点)
8. [合规与审计](#8-合规与审计)
9. [游客模式后端实现](#9-游客模式后端实现)
10. [港股适配](#10-港股适配)
11. [性能指标分析](#11-性能指标分析)
12. [设计文档缺失项与待确认问题](#12-设计文档缺失项与待确认问题)
13. [工期估算建议](#13-工期估算建议)

---

## 1. API 设计评估

### 1.1 REST vs gRPC 选型

| 场景 | 协议 | 理由 |
|------|------|------|
| 移动端 / 游客行情 | REST (HTTP/1.1) | 简单，CDN 友好，15 分钟延迟行情无需低延迟 |
| 登录 / KYC / 出入金 | REST (HTTP/2) | 移动端标准调用，请求较低频 |
| 实时行情推送 | WebSocket | 双向持久连接，行情增量推送 |
| 内部服务间通信 | gRPC + protobuf | 低延迟、强类型、支持流式传输 |
| 订单状态推送 | WebSocket | 与行情共用连接，降低连接数 |

移动端全部走 REST Gateway（基于 grpc-gateway），内部服务间走 gRPC。这样移动端无需接入 gRPC，同时保留内部高性能通信能力。

### 1.2 API 版本策略

采用 URL 路径版本化，格式：`/api/v1/`、`/api/v2/`

```
https://api.example.com/api/v1/accounts
https://api.example.com/api/v1/kyc/status
https://api.example.com/api/v1/market/quotes/{symbol}
https://api.example.com/api/v1/orders
https://api.example.com/api/v1/funds/deposit
```

版本废弃策略：旧版本至少维护 12 个月，提前 6 个月通知下线。

### 1.3 核心 API 清单（基于设计文档梳理）

**认证服务**

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/auth/send-otp | 发送手机/邮箱验证码 |
| POST | /api/v1/auth/login/phone | 手机号 + OTP 登录 |
| POST | /api/v1/auth/login/email | 邮箱 + 密码登录 |
| POST | /api/v1/auth/refresh | Refresh token 换取新 Access Token |
| POST | /api/v1/auth/logout | 登出（废弃当前 token） |
| POST | /api/v1/auth/biometric/register | 注册生物识别 Token |
| POST | /api/v1/auth/biometric/verify | 生物识别验证 |
| POST | /api/v1/auth/password/reset | 重置密码 |

**KYC 服务**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/kyc/status | 获取 KYC 状态及断点进度 |
| PUT | /api/v1/kyc/steps/{step} | 提交某一步 KYC 数据（幂等） |
| POST | /api/v1/kyc/documents/upload | 上传证件照（返回 presigned URL） |
| POST | /api/v1/kyc/face/start | 启动人脸识别会话 |
| GET | /api/v1/kyc/face/status/{session_id} | 查询人脸识别结果 |
| POST | /api/v1/kyc/submit | 最终提交开户申请 |
| GET | /api/v1/kyc/review-status | 审核进度查询 |

**账户服务**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/accounts/me | 获取账户信息 |
| GET | /api/v1/accounts/balance | 查询余额（USD + HKD） |
| GET | /api/v1/accounts/positions | 查询持仓列表 |
| GET | /api/v1/accounts/positions/{symbol} | 查询单个持仓详情 |

**出入金服务**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/funds/bank-accounts | 银行卡列表 |
| POST | /api/v1/funds/bank-accounts | 添加银行卡 |
| DELETE | /api/v1/funds/bank-accounts/{id} | 软删除银行卡 |
| POST | /api/v1/funds/bank-accounts/{id}/verify | 小额打款验证 |
| POST | /api/v1/funds/deposit | 发起入金 |
| POST | /api/v1/funds/withdraw | 发起出金 |
| GET | /api/v1/funds/transactions | 出入金记录（分页） |
| GET | /api/v1/funds/transactions/{id} | 单笔交易详情 |
| POST | /api/v1/funds/exchange | 换汇 |
| GET | /api/v1/funds/limits | 查询额度（日/月限额使用情况） |

**行情服务（REST，供游客和初始加载）**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/market/quotes/{symbol} | 单股行情（实时/延迟按认证状态） |
| GET | /api/v1/market/quotes | 批量行情（最多 50 只） |
| GET | /api/v1/market/klines/{symbol} | K 线历史数据 |
| GET | /api/v1/market/search | 股票搜索 |
| GET | /api/v1/market/status | 市场状态（开盘/收盘/盘前盘后） |
| GET | /api/v1/market/watchlist | 自选股列表 |
| POST | /api/v1/market/watchlist | 添加自选 |
| DELETE | /api/v1/market/watchlist/{symbol} | 删除自选 |

**通知服务**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/notifications | 通知列表 |
| PUT | /api/v1/notifications/{id}/read | 标为已读 |
| POST | /api/v1/notifications/device-token | 注册推送 Token |
| GET | /api/v1/notifications/preferences | 通知偏好 |
| PUT | /api/v1/notifications/preferences | 更新通知偏好 |

### 1.4 限流策略（对应 security-compliance.md）

| 端点类别 | 限流规则 | 实现 |
|---------|---------|------|
| 行情/市场数据 | 100 req/s per IP | Redis token bucket |
| 下单接口 | 10 req/s per user | Redis token bucket |
| 账户操作 | 30 req/s per user | Redis token bucket |
| KYC 上传 | 5 req/min per user | Redis sliding window |
| 登录尝试 | 5 次/5min per IP+user | Redis counter + 锁定 |
| OTP 发送 | 1 次/60s per phone | Redis TTL key |
| WebSocket 连接 | 3 个连接/user | 服务端连接管理 |

所有限流状态存储在 Redis，用 token bucket 算法实现。超限返回 `429 Too Many Requests`，响应头包含 `Retry-After` 和 `X-RateLimit-Remaining`。

### 1.5 幂等性要求

所有状态变更 API 强制携带 `Idempotency-Key` 头（UUID v4），包括：
- 发起入金 / 出金
- 提交订单
- KYC 步骤提交
- 银行卡添加

幂等键 72 小时内有效，存储在 Redis，格式：`idempotency:{service}:{key}` → 序列化后的响应体。

---

## 2. 服务拆分建议

### 2.1 服务边界划分

```
┌─────────────────────────────────────────────────────────────────┐
│                         API Gateway                              │
│                    (gRPC-gateway + JWT验证)                      │
│              限流 · 路由 · 认证 · API版本管理                     │
└──────────┬───────────┬───────────┬───────────┬──────────────────┘
           │           │           │           │
   ┌───────▼───┐ ┌────▼─────┐ ┌──▼────┐ ┌───▼──────────┐
   │ Auth      │ │ Account  │ │  KYC  │ │  Notification │
   │ Service   │ │ Service  │ │ Service│ │  Service      │
   └───────────┘ └──────────┘ └───────┘ └──────────────┘
           │           │           │
   ┌───────▼───────────▼───────────▼──────────────────────┐
   │                     Kafka Event Bus                    │
   │   account.events / kyc.events / notification.events   │
   └───────────────────────────────────────────────────────┘
           │           │
   ┌───────▼───┐ ┌────▼──────────────┐
   │  Market   │ │   Reporting       │
   │  Data GW  │ │   Service         │
   └───────────┘ └───────────────────┘
```

**重要说明**：按照 CLAUDE.md 的服务边界划分，后端工程师（本报告）负责以下服务：
- API Gateway
- Auth Service（认证/会话）
- Account Service（账户管理）
- KYC/AML Service
- Notification Service
- Reporting Service

以下服务**不在本范围**，由专属工程师负责：
- Trading Engine / OMS（`trading-engine-engineer`）
- Fund Transfer Service（`fund-transfer-engineer`）

### 2.2 各服务职责

**API Gateway**
- JWT 验证与权限检查
- 请求路由至下游 gRPC 服务
- 限流、熔断（sony/gobreaker）
- 请求日志、分布式追踪（Jaeger）
- 游客模式识别（无 token → 延迟行情）
- API 版本路由

**Auth Service**
- OTP 生成与验证（Redis 存储，5 分钟 TTL）
- JWT 签发（RS256，Access Token 15 分钟）
- Refresh Token 管理（7 天，HttpOnly Cookie）
- 设备绑定与多设备管理
- 生物识别 Token 注册（关联设备 ID）
- 密码管理（bcrypt，cost=12）
- Token 黑名单（Redis Set）

**Account Service**
- 账户生命周期（创建/冻结/注销）
- 余额查询（USD + HKD 双币种）
- 持仓汇总（从 Trading Engine 读取）
- 自选股管理
- 账户偏好设置（涨跌色、语言、通知）
- KYC Tier 状态维护

**KYC/AML Service**
- 9 步 KYC 状态机
- OCR 结果接收与存储（集成 Onfido/Jumio）
- 人脸识别会话管理
- 制裁名单筛查（OFAC / HK 指定人士）
- 文件存储（加密上传至 S3）
- 断点续传进度持久化
- 审核状态管理与通知触发

**Notification Service**
- APNs (iOS) + FCM (Android) 推送
- Email（SendGrid/SES）
- SMS（Twilio）
- In-App 通知（WebSocket 推送 + DB 持久化）
- 通知偏好管理
- 通知模板管理

**Reporting Service**
- 账户月度/季度对账单生成（PDF）
- 成交历史 CSV 导出
- 税务报告（1099-B、W-8BEN）
- 监管合规报告（FINRA OATS、SFC）

### 2.3 服务间通信方式

```
同步调用（gRPC）:
  API Gateway → Auth Service（Token验证）
  API Gateway → Account Service（余额/持仓）
  API Gateway → KYC Service（状态查询）

异步事件（Kafka）:
  KYC Service → account.kyc.events → Account Service（KYC通过，激活账户）
  KYC Service → notification.events → Notification Service（发送审核结果通知）
  Fund Transfer Service → account.balance.events → Account Service（更新余额）
  Trading Engine → notification.events → Notification Service（订单成交通知）
```

---

## 3. KYC/AML 后端实现

### 3.1 KYC 状态机设计

设计文档定义了 9 步 KYC 流程，后端需要实现对应的状态机：

```
状态机定义:
  DRAFT                     → 用户开始注册，未提交任何步骤
  STEP_1_PERSONAL_INFO      → 个人基本信息已提交
  STEP_2_DOCUMENT_UPLOADED  → 证件照已上传
  STEP_3_FACE_VERIFIED      → 人脸识别完成（或转人工）
  STEP_4_EMPLOYMENT         → 就业信息已填写
  STEP_5_FINANCIAL          → 财务状况已填写
  STEP_6_INVESTMENT         → 投资经验评估完成
  STEP_7_TAX_DECLARATION    → 税务声明（W-8BEN/W-9）已签署
  STEP_8_RISK_DISCLOSURE    → 风险披露已确认
  STEP_9_AGREEMENT_SIGNED   → 协议签署完成，待提交
  SUBMITTED                 → 已提交，等待审核
  UNDER_REVIEW              → 人工审核中
  APPROVED                  → 审核通过，账户激活
  REJECTED                  → 审核拒绝
  ADDITIONAL_INFO_REQUIRED  → 需要补充材料
  EXPIRED                   → 申请超期（90天未完成）
```

关键实现要求：
- 状态只能单向前进（不允许回退到已完成步骤），`ADDITIONAL_INFO_REQUIRED` 例外
- 每次状态变更写入 `kyc_state_transitions` 审计表（append-only）
- 状态变更通过 Kafka 事件通知下游服务

### 3.2 断点续传实现

v3 文档明确要求"每完成一步自动保存进度到服务端"：

```sql
-- KYC 进度持久化表
CREATE TABLE kyc_applications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    status              VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    current_step        SMALLINT NOT NULL DEFAULT 0,
    completed_steps     SMALLINT[] NOT NULL DEFAULT '{}',

    -- 各步骤数据（JSON，按步骤分开存）
    step1_personal_info JSONB,           -- 加密存储 PII
    step2_document_info JSONB,           -- 存储 document_id，不存原始数据
    step3_face_session  JSONB,           -- 存储 session_id 和结果
    step4_employment    JSONB,
    step5_financial     JSONB,
    step6_investment    JSONB,
    step7_tax           JSONB,           -- W-8BEN 签署记录
    step8_risk_ack      BOOLEAN DEFAULT FALSE,
    step9_agreements    JSONB,           -- 各协议签署时间戳

    -- 元数据
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at        TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ,     -- 90天过期
    review_notes        TEXT,
    reviewer_id         UUID,

    CONSTRAINT kyc_user_unique UNIQUE (user_id)
);
```

API 层面：`GET /api/v1/kyc/status` 返回当前进度（`current_step`、`completed_steps`、各步骤预填数据），App 根据进度条跳转到对应步骤，已填数据自动回填表单。

### 3.3 OCR 与人脸识别集成

**OCR 集成（Onfido / Jumio）**：
- App 上传图片 → 后端生成 S3 presigned URL → App 直传 S3（避免图片流经后端）
- 后端接收 S3 事件 → 触发异步 OCR 任务 → 调用 Onfido API
- OCR 结果回调（Webhook）→ 更新 KYC 状态
- 图片原文件加密存储（S3 SSE-KMS），访问受 IAM 控制

**人脸识别流程**：
1. 后端调用 Onfido 创建 Check 会话，返回 `session_token` 给 App
2. App 使用 Onfido SDK 完成活体检测（直接与 Onfido 交互，后端不经手视频流）
3. Onfido 异步回调后端 Webhook，更新人脸识别状态
4. 失败 3 次 → 状态标记为 `FACE_MANUAL_REVIEW_REQUIRED`，发送通知安排人工视频审核

**注意**：v3 提到"人工视频审核"需要客服预约系统，这是一个独立模块，需要在工期中额外计划。

### 3.4 AML 制裁筛查

对接 Comply Advantage 或类似 SaaS：

```
筛查触发点:
  1. KYC 提交时（姓名 + 出生日期）
  2. 银行卡绑定时（银行名 + 账户持有人姓名）
  3. 每日定期对存量用户重新筛查（批处理任务）
  4. 制裁名单更新时触发全量重新筛查

筛查结果:
  CLEAR   → 无命中，自动通过
  REVIEW  → 疑似命中，人工审核
  BLOCK   → 确认命中，立即冻结账户，通知合规团队
```

制裁名单需在本地维护缓存（Redis + PostgreSQL），每日从 OFAC / HK 官方来源更新，避免每次筛查都调用第三方 API（降低延迟和成本）。筛查记录保留 7 年（满足 BSA + AMLO 要求）。

### 3.5 文件存储安全

- 所有 KYC 文档存储在 AWS S3，使用 SSE-KMS 加密
- 访问通过预签名 URL（15 分钟有效期），URL 不存储在数据库
- 数据库只存储 S3 object key，不存储文件内容
- 文件保留期：账户注销后 6 年（KYC requirements）
- 文件名混淆（UUID，不暴露用户 ID）

---

## 4. 用户认证与会话管理

### 4.1 JWT 方案

严格按照 security-compliance.md 规范执行：

| 属性 | Access Token | Refresh Token |
|------|-------------|---------------|
| 签名算法 | RS256（RSA 2048-bit） | 随机 256-bit 字节 |
| 有效期 | 15 分钟 | 7 天 |
| 传输方式 | Authorization: Bearer 头 | HttpOnly Secure Cookie |
| 存储（客户端） | 内存（不持久化） | Cookie |
| 存储（服务端） | 无状态，黑名单用 Redis | PostgreSQL（关联设备） |
| 吊销 | Redis 黑名单（剩余有效期 TTL） | DB 标记失效 |

Access Token Payload 设计：

```json
{
  "sub": "user-uuid",
  "iss": "brokerage-auth-service",
  "aud": "brokerage-api",
  "iat": 1741651200,
  "exp": 1741652100,
  "jti": "token-uuid",
  "device_id": "device-uuid",
  "kyc_tier": "STANDARD",
  "account_status": "ACTIVE",
  "session_id": "session-uuid"
}
```

`kyc_tier` 和 `account_status` 内嵌 Token，避免每次请求都查数据库验权限。Token 续期时刷新这两个字段。

### 4.2 Refresh Token 轮换

每次使用 Refresh Token 换取新 Access Token 时，同步生成新的 Refresh Token（轮换策略），旧 Token 立即失效。检测到旧 Token 被重复使用时（可能是 Token 泄露），立即吊销该设备的所有 Session，触发安全告警。

### 4.3 设备绑定

```sql
CREATE TABLE user_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    device_id       VARCHAR(255) NOT NULL,
    device_name     VARCHAR(255),        -- "iPhone 15 Pro"
    device_os       VARCHAR(50),         -- "iOS 17.3"
    device_fingerprint TEXT,             -- 设备指纹
    refresh_token_hash VARCHAR(64) NOT NULL,  -- SHA-256 of refresh token
    ip_address      INET,
    user_agent      TEXT,
    last_active_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked         BOOLEAN NOT NULL DEFAULT FALSE,
    revoke_reason   VARCHAR(100)
);

-- 同一用户最多 5 个活跃 Session（设备管理）
CREATE INDEX idx_user_sessions_user_active ON user_sessions(user_id)
    WHERE revoked = FALSE;
```

### 4.4 生物识别 Token 流程

v3 文档设计了"生物识别快速登录"，后端实现方案：

1. 首次密码登录成功后，App 生成设备端密钥对（存储在 Keychain/KeyStore）
2. App 调用 `/api/v1/auth/biometric/register`，提交设备公钥
3. 后端存储公钥，关联 `user_id + device_id`
4. 后续生物识别登录：后端下发随机 Challenge → App 用私钥签名 → 后端用公钥验签 → 签发正常 JWT
5. 系统生物识别数据变更（新增指纹）时，App 检测到 `LAContext.biometryCurrentSet` 变化，主动调用注销接口，需重新密码登录

这是标准的 FIDO2/WebAuthn 模式简化版，不依赖设备端存储 Token，Token 泄露不导致伪登录。

### 4.5 多设备管理

- 提供 `GET /api/v1/auth/devices` 查看所有登录设备列表
- 支持 `DELETE /api/v1/auth/devices/{session_id}` 远程登出指定设备
- "登出所有其他设备"功能（KYC 要求场景、安全告警场景）
- 密码重置后强制登出所有设备（v3 文档已有说明）

### 4.6 OTP 安全

| 属性 | 设计 |
|------|------|
| 长度 | 6 位数字 |
| 有效期 | 5 分钟 |
| 最大尝试次数 | 5 次 |
| 发送频率限制 | 60 秒冷却，24 小时内最多 10 次 |
| 存储 | Redis，key: `otp:{phone/email}:{purpose}`，TTL 5 分钟 |
| 验证后处理 | 立即删除（防重放） |
| 防枚举 | 验证失败响应时间固定（constant time compare） |

---

## 5. 行情数据架构

### 5.1 整体架构

```
外部数据源（Refinitiv / Polygon.io / HKEX）
        │
        ▼
  Market Data Ingestion Service（Go）
        │
        ├── 实时行情 → Kafka（market.quotes.us / market.quotes.hk）
        │
        └── Redis 缓存（最新快照，TTL 5s）
              │
              ▼
        WebSocket Gateway（Go）
              │
        ├── 认证用户 → 实时行情推送
        └── 游客 → 从延迟队列拉取（15分钟延迟）

        REST Market Data API（Go）
              │
        ├── 认证用户 → Redis 最新快照
        └── 游客 → 延迟缓存（Redis，key 加 delayed 后缀）
```

### 5.2 WebSocket 网关设计

```
连接管理:
  - 每个 WebSocket 连接携带 JWT（握手阶段验证）
  - 每个 user 最多 3 个并发连接（跨设备）
  - 连接超时：Ping/Pong 心跳，30 秒无响应断开
  - 连接数上限：每个网关节点 50,000 连接（Kubernetes HPA 扩缩容）

订阅模型（设计文档要求）:
  - 客户端发送 SUBSCRIBE 消息，指定 symbols 列表
  - 服务端维护 symbol → [conn_ids] 的映射（Redis Pub/Sub）
  - 行情推送采用增量模式（只推变化字段）
  - 价格变化闪烁效果依赖前端，后端不关心

消息格式（JSON over WebSocket）:
{
  "type": "quote",
  "symbol": "AAPL",
  "price": "175.23",
  "change": "2.34",
  "change_pct": "1.35",
  "volume": 45200000,
  "bid": "175.22",
  "ask": "175.24",
  "timestamp": "2026-03-11T14:30:00.123Z"
}
```

### 5.3 游客延迟行情实现

游客访问延迟 15 分钟行情，后端实现方案：

```
方案：双轨缓存
  Redis Key: market:quote:realtime:{symbol}     ← 认证用户
  Redis Key: market:quote:delayed:{symbol}      ← 游客，TTL 设定

实现逻辑:
  Market Data Ingestion 写入实时缓存的同时，
  将数据放入 Delayed Queue（按时间排序的 Redis Sorted Set）
  Delay Worker 每分钟执行，将 15 分钟前的数据写入 delayed 缓存

API Gateway 路由逻辑:
  - 请求携带有效 JWT → 读 realtime 缓存
  - 无 JWT / 游客 Token → 读 delayed 缓存
  - API 响应头包含 X-Data-Delay: 900 供前端展示提示
```

注意：游客行情数据需要在 UI 层明确标注"延迟 15 分钟"，后端在响应中提供 `data_delayed: true` 字段。

### 5.4 K 线历史数据

K 线数据量大，存储和查询需要专项设计：

```
存储：TimescaleDB（PostgreSQL 扩展）
  分时数据（1m K 线）→ 保留 30 天热数据
  日 K 线 → 永久保留（监管要求 5 年）
  周 K / 月 K → 聚合计算，按需缓存

查询优化:
  - 热数据（近 30 天）→ TimescaleDB，启用 compression
  - 冷数据 → S3 Parquet 文件，按 symbol/year/month 分区
  - 缓存层：Redis 缓存最近 5 个交易日的日 K，TTL 到当日收盘

API 设计:
  GET /api/v1/market/klines/{symbol}?period=1d&from=2026-01-01&to=2026-03-11&limit=200
```

### 5.5 价格提醒（v2 新增功能）

v2 设计文档新增了价格提醒功能，后端需要：

```sql
CREATE TABLE price_alerts (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL,
    symbol      VARCHAR(20) NOT NULL,
    direction   VARCHAR(10) NOT NULL,  -- 'ABOVE' or 'BELOW'
    target_price NUMERIC(20, 6) NOT NULL,  -- 使用 NUMERIC，不用 float
    currency    VARCHAR(3) NOT NULL,
    triggered   BOOLEAN DEFAULT FALSE,
    triggered_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Alert 触发逻辑：Market Data Ingestion 收到行情更新时，从 Redis 查询该 symbol 的所有活跃提醒，判断是否触发，触发后发送 Kafka 事件到 Notification Service。提醒触发后自动失效（设计文档未明确，建议确认）。

---

## 6. 消息推送架构

### 6.1 推送通道矩阵

| 事件类型 | Push | In-App | Email | SMS | 优先级 |
|---------|------|--------|-------|-----|--------|
| KYC 审核通过 | ✅ | ✅ | ✅ | ✅ | HIGH |
| KYC 审核拒绝 | ✅ | ✅ | ✅ | ✅ | HIGH |
| KYC 需补材料 | ✅ | ✅ | ✅ | - | HIGH |
| 入金到账 | ✅ | ✅ | ✅ | - | HIGH |
| 出金到账 | ✅ | ✅ | ✅ | - | HIGH |
| 出金被拒 | ✅ | ✅ | ✅ | ✅ | HIGH |
| 订单成交（全部）| ✅ | ✅ | - | - | MEDIUM |
| 订单部分成交 | ✅ | ✅ | - | - | MEDIUM |
| 订单撤单成功 | ✅ | ✅ | - | - | LOW |
| 价格提醒触发 | ✅ | ✅ | - | - | MEDIUM |
| 保证金追缴 | ✅ | ✅ | ✅ | ✅ | CRITICAL |
| 账户异常登录 | ✅ | ✅ | ✅ | ✅ | CRITICAL |
| W-8BEN 即将到期 | - | ✅ | ✅ | - | MEDIUM |

注：保证金追缴（Margin Call）由 Trading Engine 触发，本服务只负责发送。

### 6.2 Notification Service 架构

```
Kafka Consumer（notification.events）
        │
        ▼
  Notification Dispatcher（Go）
        │
        ├── APNS（iOS Push）← golang-apns2
        ├── FCM（Android Push）← firebase-admin-go
        ├── SendGrid（Email）← sendgrid-go
        ├── Twilio（SMS）
        └── WebSocket Push（In-App）← 通过 WS Gateway 广播
```

**关键设计**：
- 推送失败自动重试（指数退避，最多 3 次）
- 重试仍失败的降级发送 Email 或 SMS
- In-App 通知持久化到 PostgreSQL（`notifications` 表），用户离线时 WebSocket 推送失败不丢通知
- 设备 Token 失效（APNs feedback 服务、FCM unregister）自动删除，避免无效推送
- 通知去重（Kafka 消息 exactly-once + Redis 幂等检查）

### 6.3 In-App 通知

WebSocket Gateway 在行情推送连接上复用通知推送（同一长连接），消息类型字段区分行情和通知：

```json
{
  "type": "notification",
  "id": "notif-uuid",
  "category": "KYC_APPROVED",
  "title": "开户申请已通过",
  "body": "您的账户已开通，立即入金开始交易",
  "timestamp": "2026-03-11T15:00:00Z",
  "read": false,
  "action_url": "app://funds/deposit"
}
```

### 6.4 通知偏好

v3 未详细展开通知偏好设置页，但从设计意图推断需要支持：
- 每类通知独立开关（Push / Email / SMS）
- 勿扰时间段设置（仅限 CRITICAL 级别可穿透）
- 频率限制（如日摘要 vs 实时通知）

---

## 7. 数据库设计关注点

### 7.1 核心表清单

**users（用户主表）**

```sql
CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email               VARCHAR(255) UNIQUE,
    phone               VARCHAR(20) UNIQUE,
    phone_country_code  VARCHAR(5),
    password_hash       VARCHAR(255),          -- bcrypt
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDING_KYC',
    -- PENDING_KYC / ACTIVE / FROZEN / SUSPENDED / CLOSED
    kyc_tier            VARCHAR(20) NOT NULL DEFAULT 'NONE',
    -- NONE / BASIC / STANDARD / ENHANCED / VIP

    -- PII 字段应用层加密（AES-256-GCM）后存储
    full_name_encrypted BYTEA,
    date_of_birth_encrypted BYTEA,
    nationality_encrypted BYTEA,

    -- 非 PII 字段
    preferred_language  VARCHAR(10) DEFAULT 'zh-CN',
    color_scheme        VARCHAR(20) DEFAULT 'RED_UP',   -- 涨跌色偏好

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at       TIMESTAMPTZ,

    -- 软删除不适用（合规原因，只标记 CLOSED 状态）
);
```

**accounts（证券账户，与 users 1:N）**

```sql
CREATE TABLE accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    account_number  VARCHAR(20) UNIQUE NOT NULL,  -- 格式: AXXX-XXXXX
    account_type    VARCHAR(20) NOT NULL,          -- CASH / MARGIN / IRA
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',

    -- 余额（使用 NUMERIC，禁止 FLOAT）
    cash_usd        NUMERIC(20, 4) NOT NULL DEFAULT 0,
    cash_hkd        NUMERIC(20, 4) NOT NULL DEFAULT 0,
    frozen_usd      NUMERIC(20, 4) NOT NULL DEFAULT 0,
    frozen_hkd      NUMERIC(20, 4) NOT NULL DEFAULT 0,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT cash_non_negative CHECK (cash_usd >= 0 AND cash_hkd >= 0),
    CONSTRAINT frozen_non_negative CHECK (frozen_usd >= 0 AND frozen_hkd >= 0)
);
```

**watchlist（自选股）**

```sql
CREATE TABLE watchlist (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    symbol      VARCHAR(20) NOT NULL,
    market      VARCHAR(10) NOT NULL,   -- US / HK
    sort_order  INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT watchlist_user_symbol_unique UNIQUE (user_id, symbol)
);
```

**notifications（In-App 通知持久化）**

```sql
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    category    VARCHAR(50) NOT NULL,
    title       VARCHAR(255) NOT NULL,
    body        TEXT NOT NULL,
    action_url  VARCHAR(500),
    read        BOOLEAN NOT NULL DEFAULT FALSE,
    read_at     TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- 按月分区
CREATE TABLE notifications_2026_03 PARTITION OF notifications
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
```

### 7.2 PII 字段加密策略

应用层加密（AES-256-GCM），密钥存储在 AWS KMS，严格按照 security-compliance.md 执行：

| 字段 | 表 | 加密方式 | 脱敏展示 |
|------|-----|---------|---------|
| 姓名 | users | AES-256-GCM | 首字母 + *** |
| 出生日期 | users | AES-256-GCM | 不展示 |
| 身份证号 | kyc_applications | AES-256-GCM | 前3后4 |
| 护照号 | kyc_applications | AES-256-GCM | 不展示 |
| SSN / TIN | kyc_applications | AES-256-GCM | ***-**-XXXX |
| HKID | kyc_applications | AES-256-GCM | A****(3) |
| 银行账号 | bank_accounts | AES-256-GCM | ****1234 |

**不允许使用 PostgreSQL 内置加密（pgcrypto）作为唯一加密层**，必须在应用层加密后再写入数据库，防止数据库凭证泄露时 PII 裸露。

### 7.3 分区策略

| 表 | 分区字段 | 分区策略 | 理由 |
|----|---------|---------|------|
| notifications | created_at | 按月 RANGE | 通知量大，方便清理旧数据 |
| audit_logs | created_at | 按月 RANGE | 审计日志量极大 |
| kyc_state_transitions | created_at | 按季度 RANGE | 合规查询按时间范围 |
| price_alerts | - | 不分区 | 数据量小 |

订单表、持仓表、出入金流水表由 Trading Engine 和 Fund Transfer Service 管理，不在本范围。

### 7.4 索引设计要点

```sql
-- 高频查询索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_watchlist_user_id ON watchlist(user_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, created_at DESC)
    WHERE read = FALSE;
CREATE INDEX idx_price_alerts_symbol ON price_alerts(symbol)
    WHERE triggered = FALSE;

-- KYC 查询
CREATE INDEX idx_kyc_applications_user_id ON kyc_applications(user_id);
CREATE INDEX idx_kyc_applications_status ON kyc_applications(status)
    WHERE status IN ('SUBMITTED', 'UNDER_REVIEW', 'ADDITIONAL_INFO_REQUIRED');

-- 会话查询
CREATE INDEX idx_user_sessions_user_active ON user_sessions(user_id, expires_at)
    WHERE revoked = FALSE;
```

### 7.5 Read Replica 策略

```
写入: 主节点（账户余额更新、KYC 状态变更）
读取:
  - 行情相关读取 → Redis 缓存（不走 DB）
  - 持仓/订单查询 → Read Replica（由 Trading Engine 管理的数据）
  - 通知列表 → Read Replica
  - KYC 状态查询 → Primary（需强一致性）
  - 余额查询 → Primary（金融数据，不允许读取旧数据）
```

---

## 8. 合规与审计

### 8.1 审计日志设计

所有账户状态变更必须写入审计日志，设计为 append-only：

```sql
CREATE TABLE audit_logs (
    id              UUID NOT NULL DEFAULT gen_random_uuid(),
    event_type      VARCHAR(100) NOT NULL,
    actor_id        UUID,                    -- 用户 ID 或系统 ID
    actor_type      VARCHAR(20) NOT NULL,    -- CUSTOMER / ADMIN / SYSTEM
    resource_type   VARCHAR(50) NOT NULL,    -- USER / ACCOUNT / KYC / ORDER / FUND_TRANSFER
    resource_id     VARCHAR(100) NOT NULL,
    details         JSONB NOT NULL,
    ip_address      INET,
    device_id       VARCHAR(255),
    correlation_id  UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- 禁止 UPDATE 和 DELETE（通过 PostgreSQL Row Security Policy 强制）
CREATE POLICY audit_logs_no_update ON audit_logs FOR UPDATE USING (FALSE);
CREATE POLICY audit_logs_no_delete ON audit_logs FOR DELETE USING (FALSE);
```

Event Type 规范（部分示例）：

| event_type | 触发时机 |
|-----------|---------|
| USER_REGISTERED | 用户注册完成 |
| USER_LOGIN_SUCCESS | 登录成功 |
| USER_LOGIN_FAILED | 登录失败 |
| KYC_STEP_COMPLETED | KYC 每步完成 |
| KYC_SUBMITTED | KYC 提交审核 |
| KYC_APPROVED | KYC 审核通过 |
| KYC_REJECTED | KYC 审核拒绝 |
| ACCOUNT_STATUS_CHANGED | 账户状态变更 |
| BANK_ACCOUNT_ADDED | 银行卡添加 |
| BANK_ACCOUNT_DELETED | 银行卡软删除 |
| DEPOSIT_INITIATED | 入金发起 |
| WITHDRAWAL_INITIATED | 出金发起 |
| AML_SCREENING_RESULT | AML 筛查结果 |

**注意**：日志中严禁写入明文 PII，如姓名、证件号等需脱敏后写入。

### 8.2 记录保留策略

严格按照 fund-transfer-compliance.md Rule 9 执行：

| 数据类型 | 保留期 | 存储层 | 法规依据 |
|---------|-------|--------|---------|
| 审计日志 | 7 年 | PostgreSQL（热）→ S3 Glacier（冷） | SEC 17a-4, SFO |
| KYC 文件 | 账户注销后 6 年 | S3（Object Lock） | KYC requirements |
| AML 筛查记录 | 7 年 | PostgreSQL → S3 | BSA, AMLO |
| 通知记录 | 90 天热存储 + 7 年冷存储 | PostgreSQL → S3 | 合规审计 |
| 用户协议签署记录 | 7 年 | PostgreSQL + S3 | 电子签名法 |

**WORM 合规**：
- S3 使用 Object Lock（Compliance Mode），防止任何人删除（包括 root 账户）
- 保留期到期后自动转入 Glacier Deep Archive
- 每年执行 WORM 存储完整性审计

### 8.3 CTR/SAR 自动申报

这部分逻辑由 Fund Transfer Service 负责，但 Notification Service 需要在申报完成后通知合规团队：

- CTR（Currency Transaction Report）：>$10,000 USD 或 >HK$120,000 的单笔出入金，自动向 FinCEN 提交
- SAR（Suspicious Activity Report）：AML 筛查返回 BLOCK 或合规人员手动标记可疑交易
- 申报记录保留 5 年（FinCEN 要求）

### 8.4 合规报告生成

Reporting Service 需要定期生成：

| 报告 | 周期 | 接收方 | 格式 |
|------|------|-------|------|
| 账户月度对账单 | 每月1日 | 客户（Email + App） | PDF |
| FINRA OATS 报告 | 每日收盘后 | FINRA | 规定格式 |
| SFC 交易报告 | T+1 日 | SFC | 规定格式 |
| 税务报告（1099-B） | 每年 1 月 | 美国用户 | PDF |
| W-8BEN 更新提醒 | 到期前 90/30 天 | 非美用户 | Email + Push |

---

## 9. 游客模式后端实现

### 9.1 游客权限矩阵

| API 端点 | 游客 | 认证用户（KYC 未完成）| 认证用户（KYC 完成）|
|---------|------|---------------------|-------------------|
| 行情快照（REST） | ✅ 延迟 15 分钟 | ✅ 实时 | ✅ 实时 |
| 行情 WebSocket | ✅ 延迟 15 分钟 | ✅ 实时 | ✅ 实时 |
| K 线历史数据 | ✅ 延迟 15 分钟 | ✅ 实时 | ✅ 实时 |
| 股票搜索 | ✅ | ✅ | ✅ |
| 自选股 | ❌ | ✅ | ✅ |
| 持仓 / 账户余额 | ❌ | ❌（无持仓）| ✅ |
| 下单 | ❌ | ❌ | ✅ |
| 出入金 | ❌ | ❌ | ✅ |

### 9.2 游客模式实现

游客不需要创建账户，API Gateway 通过以下逻辑判断：
- 无 Authorization 头 → 游客模式，路由到延迟行情 → 受限端点返回 401
- 有 Authorization 头但 Token 无效 → 返回 401
- 有有效 Token 但 `kyc_tier: NONE` → 已注册用户，实时行情，但无法交易/出入金

行情 API 响应示例（游客）：

```json
{
  "symbol": "AAPL",
  "price": "175.23",
  "timestamp": "2026-03-11T14:00:00Z",
  "data_delayed": true,
  "delay_minutes": 15
}
```

### 9.3 转化漏斗追踪

游客行为追踪（合规范围内，匿名化）：
- 游客浏览的 symbol 列表（用于热门榜计算，不关联身份）
- 游客触发注册引导的行为（点击"买入"按钮）
- 转化率统计（游客 → 注册 → KYC 完成 → 首次入金）

数据不存储任何 PII，仅存储 session_hash + 行为类型 + 时间戳。

---

## 10. 港股适配

### 10.1 港股交易规则差异

| 维度 | 美股 | 港股 |
|------|------|------|
| 代码格式 | 1-5 字母（AAPL） | 4-5 位数字（00700.HK） |
| 货币 | USD | HKD |
| 交易单位 | 1 股（或碎股） | 手（Board Lot，每只股票不同）|
| 结算周期 | T+1 | T+2 |
| 涨跌停 | 无 | 无（但有熔断机制）|
| 价差（Spread）| 固定报价精度 | 按价格区间分档（Spread Table）|
| 交易时段 | 09:30-16:00 ET，+盘前盘后 | 09:30-12:00, 13:00-16:00 HKT，+竞价 |
| 印花税 | 无 | 卖出 0.1%（香港印花税）|
| 平台费 | SEC Fee + FINRA TAF | 交易所费 + 证监会征费 |

### 10.2 Board Lot 数据服务

每只港股的 Board Lot Size 不同（腾讯 00700 为 100 股/手，汇丰 0005 为 400 股/手），且偶尔随企业行动变化。需要独立的 Board Lot 数据服务：

```sql
CREATE TABLE hk_board_lots (
    symbol          VARCHAR(20) PRIMARY KEY,  -- 00700.HK
    board_lot_size  INT NOT NULL,             -- 手的股数
    last_changed_at TIMESTAMPTZ NOT NULL,
    source          VARCHAR(50) NOT NULL      -- HKEX
);

-- 企业行动（股票分拆/合并等导致 lot size 变化）
CREATE TABLE hk_board_lot_history (
    id              UUID PRIMARY KEY,
    symbol          VARCHAR(20) NOT NULL,
    old_lot_size    INT NOT NULL,
    new_lot_size    INT NOT NULL,
    effective_date  DATE NOT NULL,
    reason          VARCHAR(255),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Board Lot 数据需要每天从 HKEX 官方数据源更新，并缓存在 Redis（TTL 24h）。交易下单时，验证数量必须是 Board Lot 的整数倍（除非支持碎股，MVP 阶段不支持）。

**注意**：v3 文档的下单页面示例使用美股模式（按股），港股下单数量单位应改为"手"，设计文档需要补充这一差异。

### 10.3 双币种账户

设计文档（v3 出入金页面）已展示 USD + HKD 双币种账户，后端实现要点：

```
账户余额维护:
  accounts 表中维护 cash_usd 和 cash_hkd 两个独立字段
  持仓市值计算时，港股持仓用 HKD，美股持仓用 USD
  资产总览页需要汇总成同一货币展示（USD 或 HKD，用户可选）

换汇操作:
  换汇属于原子操作：同时减少 cash_usd 和增加 cash_hkd（或反向）
  使用 PostgreSQL 事务保证原子性
  汇率来源：Bloomberg/Reuters 实时汇率，每 15 秒刷新（与 v3 换汇页设计一致）
  换汇手续费：0.3%（v3 文档已标注），以 Decimal 精确计算
```

### 10.4 港股费用计算

卖出港股时的费用组成：

| 费用项目 | 计算方式 | 收款方 |
|---------|---------|-------|
| 交易所费 | 成交额 × 0.00565% | HKEX |
| 证监会征费 | 成交额 × 0.0027% | SFC |
| 财务汇报局征费 | 成交额 × 0.00015% | FRC |
| 香港印花税 | 成交额 × 0.1%（卖方） | 香港政府 |
| 股票结算费 | 成交额 × 0.002%（最低 HK$2，最高 HK$100）| HKSCC |

全部使用 `shopspring/decimal` 计算，精确到 HKD 最小单位（分）。

### 10.5 不同结算周期对出金的影响

美股 T+1，港股 T+2，后端需要精确追踪每笔成交的结算日期：

```
可出金余额计算:
  可出金 = 总现金
         - SUM(未结算成交买入金额，按货币分类)
         - 待处理出金金额
         - 保证金冻结金额（仅保证金账户）

注意: 港股持仓卖出所得款项 T+2 才进入可出金余额
     美股持仓卖出所得款项 T+1 才进入可出金余额
```

v3 出金页面已经展示了"未结算资金"字段，后端需要准确计算并通过 API 返回。

### 10.6 港股竞价时段

HKEX 的竞价时段（08:30-09:20 集合竞价，16:01-16:10 收盘竞价）需要后端：
- 维护市场状态枚举（PRE_AUCTION / CONTINUOUS / POST_AUCTION / CLOSED）
- 按时段控制可提交的订单类型（竞价时段只能提交竞价限价单，MVP 阶段需确认是否支持）
- 市场状态通过 WebSocket 推送给客户端

---

## 11. 性能指标分析

### 11.1 设计文档性能目标

| 指标 | 目标 | 评估 |
|------|------|------|
| 冷启动时间 | < 2 秒 | 后端可达，需优化启动加载策略 |
| 页面切换 | < 300ms | 后端 API 需 p99 < 100ms（读）才能支撑 |
| 行情刷新 | < 500ms | WebSocket 推送天然满足，轮询方案需注意 |
| 下单响应 | < 1 秒 | 后端部分：< 200ms；交易所确认不在控制范围内 |
| 内存占用 | < 200MB | 客户端侧指标，后端不涉及 |

### 11.2 后端性能优化策略

**冷启动 < 2s 的后端保障**：
- 行情首屏数据（自选股行情快照）在 App 启动时一次性返回（批量 API），避免多次串行请求
- 返回数据预先缓存在 Redis（TTL 5s），不走 PostgreSQL
- CDN 加速静态资源（公告、Logo 等）
- Kubernetes Readiness Probe 确保 Pod 完全就绪后才接流量

**API 响应时间 p99 目标**：

| 接口类型 | p99 目标 | 实现策略 |
|---------|---------|---------|
| 行情快照（Redis） | < 20ms | Redis Get，几乎无 DB 压力 |
| 自选股列表 | < 50ms | Redis + DB 合并，预热缓存 |
| 持仓列表 | < 80ms | Read Replica，索引优化 |
| 下单（后端部分） | < 100ms | 内存预检，异步写 Kafka |
| KYC 状态查询 | < 50ms | Primary DB，加缓存 |
| 余额查询 | < 30ms | 内存级别更新（后期考虑），当前 Primary DB |

**WebSocket 推送延迟**：
- 市场数据 Ingestion → Kafka → WebSocket Gateway 推送：目标 < 100ms
- Kafka partition 按 symbol 哈希（保证同一 symbol 顺序消费）
- WebSocket Gateway 水平扩展（Kubernetes HPA），不同节点间通过 Redis Pub/Sub 广播

**数据库连接池**：
- 使用 `jackc/pgx` 连接池，每个服务配置最大连接数
- Account Service: maxConns=50（写少读多，余额查询高频）
- KYC Service: maxConns=20（低频）
- Notification Service: maxConns=30
- pgBouncer 连接池代理（Kubernetes DaemonSet 或 Sidecar）

### 11.3 下单响应 < 1s 的可达性分析

下单端到端路径：
```
客户端 → API Gateway（JWT验证: ~5ms）
       → Trading Engine（前置风控: ~10ms）
       → 订单写 Kafka（ack: ~5ms）
       → 返回"订单已提交"（< 30ms）

订单执行路径（异步）:
  Kafka → Order Router → 交易所 FIX → 回报 → WebSocket 推送客户端
  这部分时延由 Trading Engine 负责，不在本服务范围
```

后端承诺的 < 200ms 写响应是可达的。但设计文档中"下单响应 < 1 秒"如果指的是"订单成交"，则超出后端控制范围，需要与 PM 明确指标含义。

---

## 12. 设计文档缺失项与待确认问题

### 12.1 对 PM 的强制性确认（阻塞开发）

以下问题不解答，后端无法开始架构设计：

**A. 账户类型**
- MVP 是否同时支持现金账户和保证金账户？保证金账户涉及融资杠杆、维持保证金计算，实现复杂度差异巨大，完全影响账户模型设计。
- 建议：MVP 仅支持现金账户，保证金账户 P1 迭代。

**B. KYC MVP 范围**
- 9 步 KYC 中，哪些步骤必须完成才能开户？
- 人脸识别首发是否支持"转人工视频审核"？人工审核需要独立的排班系统，不在当前技术范围内。
- 这个问题直接影响 KYC Service 状态机设计和工期估算。

**C. 港股下单单位**
- 港股下单数量输入是"手"还是"股"？
- 是否 MVP 支持港股碎股交易？
- 这影响下单页面的前后端逻辑（需同步确认 v3 下单设计中的港股适配部分）。

**D. 即时入金垫资方案**
- v3 文档提到"平台垫资，资金立即可用"，这是资产负债表外的金融行为，需要 CFO / Legal 确认是否可行，以及额度如何设定。
- 首次 $1,000 / 老用户 $5,000 是否经过合规审查？
- 这影响 Fund Transfer Service 的实现（不在本范围，但需提醒）。

**E. W-8BEN 存储与电子签名**
- W-8BEN 电子签署需要满足哪个国家的电子签名法律要求？
- 手写签名是否有法律效力，还是需要第三方电子签名服务（DocuSign / HelloSign）？

**F. 订单修改（改单）**
- v3 文档有"改单"功能，但改单在业务上是"撤销原订单 + 创建新订单"，还是"修改原订单属性"？这影响 Trading Engine 设计，需要 Trading Engine 工程师确认实现方案。

### 12.2 设计文档遗漏的后端需求

以下内容在设计文档中未提及，但后端实现时必须处理：

**账户状态与 API 权限矩阵**

设计文档仅描述了"游客 vs 认证用户"的权限差异，缺少以下场景：
- KYC 审核中（UNDER_REVIEW）→ 可以浏览行情，不能交易
- 账户被冻结（FROZEN）→ 可以查看持仓，不能下单，不能出金（但能看余额）
- 账户被暂停（SUSPENDED）→ 完全只读
- 这些状态的 API 行为需要明确定义，否则后端逻辑无法实现。

**错误码规范**

API 的错误响应格式、错误码体系未定义。建议后端统一规范：
```json
{
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "可用余额不足",
    "details": {
      "available": "8750.00",
      "required": "10000.00"
    }
  }
}
```

**Rate Limit 超限的用户体验**

设计文档未描述限流后的 App 提示。需要设计降级体验（如显示"请求过于频繁，请稍后重试"）。

**搜索功能的数据边界**

v2 文档提到"支持股票代码、公司名、拼音首字母搜索"，但：
- 搜索库包含多少支股票？全美股（约 8,000 只）+ 全港股（约 2,600 只）？
- 还是仅热门股票？
- 是否需要全文搜索引擎（Elasticsearch）？或者 PostgreSQL 的 pg_trgm 扩展足够？

**价格提醒触发条件**

v2 新增了价格提醒功能，但：
- 价格提醒是否支持百分比变化（如"涨幅超过 5% 时提醒"）？还是仅支持绝对价格？
- 提醒触发后是否自动删除，还是持续有效（用户每次价格经过都提醒）？
- 每人最多可设置多少个提醒？

**分时图数据**

K 线图设计文档提到支持"分时"（Intraday）图，分时图需要：
- 1 分钟级别的 K 线数据，当日 390 个数据点（美股）
- 今日开盘到现在的实时数据
- 均价线（VWAP）计算需要后端提供成交量加权数据，还是前端自己计算？

### 12.3 与 UX 设计师问题清单的交叉响应

UX 设计师的 `design-review-for-pm.md` 提出了 6 大问题，从后端视角补充：

**问题二（登录策略）**：
- "设置密码"步骤如果保留，密码需要 bcrypt 存储，KYC 流程提交时写入
- 如果只做手机号 OTP 登录，密码字段可以允许为 NULL，邮箱登录 P1 迭代
- 但**无密码账户的账户安全性较低**，建议所有用户都必须设置密码，OTP 只用于验证身份

**问题四（港股相关设计缺失）**：
- 货币单位：后端返回原始货币（港股返回 HKD），前端负责展示格式化
- 搜索 API 需要支持港股 4-5 位数字代码格式，数据库字段已留 `market` 字段区分
- 竞价时段订单类型限制需要 Market Data 服务提供市场状态信号

**问题六（游客模式功能边界）**：
- 所有 Tab 展示但点击受限的方案对后端影响更小（不需要 Tab 级别的权限 API）
- 建议：4 个 Tab 均展示，点击行情 Tab 直接可用（延迟行情），点击其他 Tab 弹出登录引导

---

## 13. 工期估算建议

### 13.1 服务工期估算（粗略）

| 服务 / 模块 | 工期（人周）| 风险等级 | 说明 |
|------------|----------|---------|------|
| API Gateway | 3 | 低 | 成熟方案，主要是配置和集成 |
| Auth Service（OTP + JWT + 设备管理）| 4 | 低 | 逻辑清晰，有成熟 SDK |
| Auth Service（生物识别 Token 流程）| 2 | 中 | 需要与移动端联调 |
| Account Service（账户 + 余额 + 自选）| 3 | 低 | 逻辑简单 |
| KYC Service（状态机 + 断点续传）| 5 | 中 | 状态机复杂，边界情况多 |
| KYC Service（Onfido/Jumio 集成）| 4 | 高 | 第三方 SDK 文档质量不稳定 |
| KYC Service（AML 制裁筛查）| 3 | 中 | 依赖第三方数据服务合同 |
| KYC Service（人工视频审核流程）| 5 | 高 | 需要排班系统，MVP 建议去掉 |
| Notification Service（Push + Email + SMS）| 4 | 低 | 成熟 SDK，主要是集成测试 |
| Notification Service（In-App + WS）| 3 | 中 | 需要与 WS Gateway 协调 |
| Market Data Gateway（REST + WS）| 4 | 中 | WebSocket 扩展性设计要仔细 |
| 游客延迟行情实现 | 1 | 低 | 缓存 TTL 策略，不复杂 |
| 港股 Board Lot 数据服务 | 2 | 中 | 依赖 HKEX 数据源稳定性 |
| 双币种账户 + 换汇 | 3 | 中 | 金融计算需要反复测试 |
| 数据库 Schema + 迁移 | 2 | 低 | 需要精心设计，一次到位 |
| Reporting Service（账单 + CSV 导出）| 3 | 低 | PDF 生成有成熟库 |
| 监管报告（FINRA OATS + SFC）| 5 | 高 | 监管格式严格，需要合规确认 |
| 审计日志系统 | 2 | 低 | 设计清晰，实现简单 |
| **合计（不含人工视频审核）** | **62 人周** | - | 约 2 名后端工程师 8 个月 |

### 13.2 高风险模块（建议优先评估）

**最高风险：KYC 第三方集成（Onfido/Jumio）**
- 第三方 API 文档质量差异大，沙箱环境与生产环境行为可能不一致
- 合同谈判和接入审批可能需要 4-8 周
- **建议**：尽早启动供应商评估和合同流程，不要等开发阶段才开始

**高风险：监管报告格式**
- FINRA OATS 和 SFC 报告格式每年都有更新
- 需要与合规团队密切合作，确认最新格式
- **建议**：Reporting Service 的监管报告模块放在 P1，MVP 先做账单和 CSV 导出

**高风险：AML 制裁名单更新机制**
- 制裁名单需要 24/7 实时更新，对基础设施要求高
- 建议采购 Comply Advantage 或 Refinitiv World-Check 这类已有数据的 SaaS，而非自建
- **建议**：提前确认供应商合同，数据接入验证需要 4-6 周

### 13.3 MVP 范围建议（后端视角）

建议 MVP 阶段以下模块**推迟至 P1**：
1. 人工视频审核排班系统（KYC 失败 3 次后的降级方案可暂时用"联系客服"替代）
2. 监管合规报告（FINRA OATS / SFC）
3. W-8BEN 自动到期提醒
4. 盘前盘后交易支持（Market Data 服务需要额外数据源）
5. 碎股交易（港股 / 美股）
6. 价格提醒高级功能（百分比变化提醒）

### 13.4 依赖项关键路径

```
外部依赖（需提前启动，不能等到开发阶段）:
  Week 1-2: 启动 Onfido/Jumio 供应商评估
  Week 1-2: 启动 AML 数据服务商评估（Comply Advantage 等）
  Week 2-4: 申请 HKEX 实时数据授权
  Week 2-4: 申请美股行情数据授权（Refinitiv / Polygon.io）
  Week 4-8: 完成与 Onfido 的合同签署和集成账号开通

内部依赖:
  Week 1: PM 确认 KYC MVP 步骤范围 → 解锁 KYC Service 开发
  Week 1: PM 确认账户类型（现金/保证金）→ 解锁 Account Service 设计
  Week 2: Trading Engine 工程师确认改单接口设计
  Week 2: Fund Transfer 工程师确认余额更新事件协议（Kafka schema）
  Week 3: 合规团队确认 W-8BEN 电子签名合法性
```

---

## 总结

从后端工程视角看，v3 设计文档已经非常详细，覆盖了关键的 KYC 流程、出入金流程和交易流程。以下是几个最关键的关注点：

1. **金融计算一律使用 `shopspring/decimal`**，代码 review 时零容忍 float64 的使用。
2. **KYC 第三方集成是最高风险项**，建议提前 2-3 个月启动供应商评估。
3. **港股适配设计文档严重缺失**，Board Lot 模式、HKD 双币种账户、T+2 结算都需要 v3 文档补充港股专项设计。
4. **账户状态机与 API 权限矩阵**需要 PM 明确定义，否则 API Gateway 的鉴权逻辑无法实现。
5. **游客延迟行情**实现相对简单，不是技术难点，但需要 PM 明确标注方案（v3 文档已有 `data_delayed: true` 的概念，需要前端同步实现"延迟 15 分钟"的 UI 标注）。

建议召开一次 Backend + PM + Trading Engine + Fund Transfer 的联合设计评审，对齐 Kafka 事件 Schema、服务间 gRPC 接口协议，以及合规红线的技术实现方案。

---

**文档版本**: v1.0
**评审日期**: 2026-03-11
**评审人**: Backend Engineer
**下一步**: 待 PM 确认 §12.1 中的强制性问题后，启动详细技术方案设计（HLD）
