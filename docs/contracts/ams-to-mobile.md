---
provider: services/ams
consumer: mobile
protocol: REST + gRPC
status: FINAL
version: 2
created: 2026-03-13
last_updated: 2026-04-01
last_reviewed: 2026-04-01
sync_strategy: provider-owns
---

# AMS → Mobile 接口契约

## 契约范围

移动端用户认证、注册、KYC 流程、个人资料管理、通知。AMS 为 Flutter 移动客户端提供完整的账户生命周期管理能力，包括登录注册、身份验证、KYC 资料提交与状态追踪、个人资料 CRUD、以及站内通知拉取。

## 接口清单（按模块分类）

### 1️⃣ 认证（Authentication）

**实现状态**：✅ **已定义** (Final)
**来源文档**：`services/ams/docs/specs/api/rest/auth.md`
**描述**：OTP 登录、Token 刷新、生物识别认证、设备管理

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| POST | /v1/auth/otp/send | 发送 OTP 验证码（SMS/Email） | <200ms | v2 |
| POST | /v1/auth/otp/verify | 验证 OTP 并签发 JWT access + refresh token | <500ms | v2 |
| POST | /v1/auth/token/refresh | 使用 refresh token 刷新 access token（单次使用） | <300ms | v2 |
| POST | /v1/auth/biometric/register | 注册生物识别（Face ID/Fingerprint），绑定设备 | <200ms | v2 |
| POST | /v1/auth/biometric/verify | 验证生物识别签名（敏感操作） | <300ms | v2 |
| POST | /v1/auth/logout | 注销会话，吊销 token | <200ms | v2 |
| GET | /v1/auth/devices | 列出用户所有已绑定设备 | <200ms | v2 |
| DELETE | /v1/auth/devices/{device_id} | 远程注销设备（踢出会话） | <200ms | v2 |

**核心特性**：
- OTP 流程：60 秒发送间隔，5/小时限制，5 分钟有效期，5 次错误后 30 分钟锁定
- Token 生命周期：access token 15 分钟，refresh token 7 天（单次使用、轮换）
- 设备绑定：最多 3 台设备，超限踢出最早设备（FIFO）
- 生物识别：HMAC-SHA256 签名验证，设备指纹变更检测，重新注册提示
- 设备状态机：ACTIVE / LOCALLY_LOGGED_OUT / REMOTELY_KICKED / SESSION_EXPIRED
- 速率限制：5 req/5min per IP+phone（登录），1/60s per phone（OTP 发送）
- Kafka 事件：`auth.otp_sent`、`auth.otp_verified`、`auth.device_added`、`auth.device_kicked`

**详见**：`api/rest/auth.md` 的：
- § 1-2：OTP 发送与验证流程（新用户自动创建账户）
- § 3：Token 刷新与单次使用强制（防止 token 泄露）
- § 4-5：生物识别注册与验证（设备指纹检测）
- § 6-8：注销、设备列表、设备远程注销（RBAC：需生物识别）
- 速率限制与错误码完整参考表

---

### 2️⃣ KYC 流程（7 步开户）

**实现状态**：✅ **已定义** (Final)
**来源文档**：`services/ams/docs/specs/mobile-ams-kyc-contract.md` §2 OpenAPI 3.0 规范
**描述**：完整的 KYC 七步流程、Sumsub 集成、W-8BEN 税务表单、AML 筛查

| Step | 方法 | 路径 | 用途 |
|------|------|------|------|
| 1 | POST | /v1/kyc/start | 开始 KYC，录入个人信息 |
| 2 | POST | /v1/kyc/documents/upload | 上传身份证件，触发 Sumsub OCR + 活体检测 |
| — | GET | /v1/kyc/sumsub-token | 获取 Sumsub SDK access token |
| 3 | POST | /v1/kyc/financial-profile | 财务信息填报 |
| 4 | POST | /v1/kyc/investment-assessment | 投资适合性问卷 |
| 5 | POST | /v1/kyc/tax-forms | 提交 W-9/W-8BEN/CRS 税务表单 |
| 6 | POST | /v1/kyc/agreements | 风险披露与服务条款确认 |
| 7 | POST | /v1/kyc/submit | 完成提交，账户进入 AML 审核 |
| — | GET | /v1/kyc/status | 轮询 KYC 状态 |

**核心特性**：
- Sumsub 集成（OCR、活体检测、Webhook 异步通知）
- W-8BEN 生命周期管理（3 年有效期，T-90 续期提醒）
- OFAC + HK 制裁名单同步筛查
- 文件上传：S3 预签名 URL + SHA256 校验
- 状态轮询：5 秒间隔，最多 120 次（10 分钟）
- Push 备用通知（FCM）

**详见**：`mobile-ams-kyc-contract.md` 的：
- §1 七步流程概览
- §2 OpenAPI 3.0 完整规范（包括 request/response schema）
- §3 数据模型与验证
- §4 文件上传协议
- §5 Sumsub 集成细节
- §6 W-8BEN 生命周期
- §7 状态轮询与 Webhook
- §8 错误处理与重试
- §9 Dart 模型生成（freezed）
- §10 Go 处理函数签名
- §11 gRPC Protobuf 定义

---

### 3️⃣ 个人资料（User Profile）

**实现状态**：✅ **已定义** (Final)
**来源文档**：`services/ams/docs/specs/api/rest/profile.md`
**描述**：获取、更新个人资料，包括基本信息、财务信息、KYC 与 AML 状态

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| GET | /v1/profile | 获取个人资料（PII 解密返回） | <200ms | v2 |
| PUT | /v1/profile | 更新个人资料（敏感字段需生物识别验证） | <300ms | v2 |
| GET | /v1/profile/account-status | 获取账户合规状态（KYC、AML、限制、W-8BEN） | <200ms | v2 |

**核心特性**：
- 资料字段：姓名、出生日期、国籍、就业状态、财务信息、投资适合性评级
- PII 加密：SSN、HKID、DOB 在应用层 AES-256-GCM 加密存储（盲索引支持查询）
- PII 脱敏：返回明文给已认证客户端，UI 展示时二次脱敏（SSN `***-**-1234`，HKID `A****(3)`）
- 敏感字段更新（email、phone、SSN、HKID）需生物识别验证 + 二次确认
- 账户状态：KYC 状态（PENDING/APPROVED/REJECTED/SUSPENDED）、AML 筛查状态（CLEAR/REVIEW/FLAGGED）、活跃限制（交易禁用、提现禁用等）
- W-8BEN 税务表单：3 年有效期，T-90 自动续期提醒

**详见**：`api/rest/profile.md` 的：
- § 1：Get Profile（PII 解密逻辑）
- § 2：Update Profile（敏感字段验证、邮箱/手机二次确认流程）
- § 3：Get Account Status（KYC/AML 状态、活跃限制、W-8BEN 状态）
- PII 字段分类与脱敏规则表

---

### 4️⃣ 通知（Notifications）

**实现状态**：✅ **已定义** (Final)
**来源文档**：`services/ams/docs/specs/api/rest/notifications.md`
**描述**：获取站内通知列表、管理已读状态、配置通知偏好

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| GET | /v1/notifications | 分页获取通知列表（支持已读/未读/事件类型筛选） | <300ms | v2 |
| PATCH | /v1/notifications/{notification_id}/read | 标记单个通知为已读 | <200ms | v2 |
| PATCH | /v1/notifications/read | 批量标记通知为已读（最多 100 条） | <300ms | v2 |
| GET | /v1/notifications/preferences | 获取用户通知偏好设置 | <200ms | v2 |
| PUT | /v1/notifications/preferences | 更新通知偏好（渠道、事件类型、勿扰时间） | <200ms | v2 |

**核心特性**：
- 事件类型：设备登录、设备被踢、异常登录、账户锁定、KYC 状态、W-8BEN 过期、Session 过期、提现/存款完成（8 类）
- 多渠道投递：FCM（推送）、SMS（短信）、Email（邮件），每个用户可独立配置
- 优先级：HIGH（安全相关）、NORMAL（账户通知）、LOW（信息性）
- 已读状态：应用内追踪，Redis 计数器快速查询未读数
- 勿扰时间：用户可设置静音时间段（推送仍投递但不弹出）
- 安全事件强制：设备被踢、账户锁定通知无法关闭（compliance required）
- Kafka 事件：消费 `auth.device_kicked`、`kyc.status_changed`、`account.restricted` 等事件

**详见**：`api/rest/notifications.md` 的：
- § 1：List Notifications（分页、过滤、排序）
- § 2-3：Mark Read（单个及批量）
- § 4-5：Get/Update Preferences（渠道偏好、事件类型订阅、勿扰时间）
- 推送 Kafka 事件映射表

---

### 5️⃣ 访客模式（Guest Mode）

**实现状态**：✅ **已定义** (Final)
**来源文档**：`services/ams/docs/specs/api/rest/guest.md`
**描述**：无认证用户浏览延迟行情、搜索、浏览库存后升级为认证用户

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| POST | /v1/guest/session | 创建访客会话（IP 追踪，7 天过期） | <200ms | v2 |

**核心特性**：
- 页面权限矩阵：6 个页面，3 个开放（行情首页、股票详情、搜索），3 个限制（订单、持仓、个人资料）
- 行情延迟：15+ 分钟延迟，满足 SEC Regulation NMS（合规标签强制显示 "Delayed 15 minutes"）
- 会话生命周期：7 天 TTL，无 PII 存储，支持本地 watchlist（非服务端同步）
- 登录触发：点击买/卖、加入 watchlist 时弹出登录 sheet → OTP 流程 → 自动升级为认证用户
- 本地数据：Watchlist 存储在客户端（localStorage/indexedDB），升级时可同步到服务端
- Kafka 事件：`guest.session_created`、`guest.upgraded_to_user`

**详见**：`api/rest/guest.md` 的：
- § Create Guest Session 流程与响应格式
- § Guest Session Lifecycle（状态转换、页面访问矩阵、升级流程）
- § SEC Compliance 标签规则与显示位置
- Watchlist 同步端点

```
移动端 (Flutter)
  ├─ 登录/注册 ───► Auth 模块（待实现）
  ├─ KYC 开户流程 ───► KYC 模块（已实现）
  ├─ 个人资料 CRUD ───► Profile 模块（待实现）
  └─ 通知拉取 ───► Notifications 模块（待实现）
       │
       ▼
AMS 后端 (Go)
  ├─ JWT RS256 发行 + Token 黑名单（Redis）
  ├─ KYC 状态机 + Sumsub 集成
  ├─ AML 筛查（OFAC/HK）
  ├─ PII 加密存储（AES-256-GCM）
  └─ Notification 分发（FCM/Email/SMS）
       │
       ▼
外部服务
  ├─ Sumsub (OCR、活体检测)
  ├─ AWS S3 (文件存储)
  ├─ Firebase Cloud Messaging (推送)
  ├─ SendGrid/AWS SES (邮件)
  ├─ Twilio/Aliyun SMS (短信)
  └─ OFAC/HK 制裁清单 (定期同步)
```

## 认证与安全

**Authentication**：
- 除 `/auth/login`、`/auth/register`、health check 外，**所有端点均需 JWT Bearer token**
- Token 格式：`Authorization: Bearer <jwt_access_token>`
- 设备绑定：Token 绑定 device_id + IP 范围，新设备需额外验证

**Biometric Authentication**：
- **强制要求于以下操作**：
  - 下单提交（trading endpoint）
  - 资金提现
  - 密码变更
  - KYC 文档上传
- Flutter 实现：`local_auth` package with `biometricOnly: true`

**Rate Limiting**：
```
Login Attempts:    5 req / 5 min per IP+user
KYC Upload:        5 req / min per user
Profile Update:    10 req / min per user
Notifications:     20 req / min per user
```

**PII 脱敏规则**：
- SSN：`***-**-1234`（仅显示后 4 位）
- HKID：`A****(3)`（首字母 + 末位数字）
- Email：`j***e@example.com`（脱敏中间）
- Bank Account：`****1234`（仅显示后 4 位）

**Data Protection**：
- 敏感字段（SSN、HKID、护照、银行账号、出生日期）在数据库存储前应用层加密（AES-256-GCM）
- 密钥管理：AWS KMS 或 HashiCorp Vault
- 日志规则：NEVER log 密码、token、SSN、HKID、银行账号；ALWAYS mask PII before logging

---

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：
   - `services/ams/docs/specs/api/rest/<module>.md`（或 `mobile-ams-kyc-contract.md`）
   - 本契约文件 (`version` +1, `last_updated` 更新)
4. Thread 标记 RESOLVED

---

## Changelog

| 版本 | 日期 | 变更 | 状态 |
|------|------|------|------|
| v2 | 2026-04-01 | 完成全部 4 个移动端模块 REST API 规范（auth、profile、notifications、guest）。标记认证、个人资料、通知、访客模式状态为 **Final**；引用新建的规范文档（auth.md, profile.md, notifications.md, guest.md）。补充核心特性、Kafka 事件、详细参考链接。 | FINAL |
| v1 | 2026-03-31 | 首次审核：按模块分类，引用已定义的 KYC 合约，标记待实现模块指向 TBD 文档。完善安全规范（认证、PII 脱敏、速率限制）。 | REVIEWED |
| v0 | 2026-03-13 | 初始创建（占位符） | DRAFT |
