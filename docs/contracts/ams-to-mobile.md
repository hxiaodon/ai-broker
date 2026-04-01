---
provider: services/ams
consumer: mobile
protocol: REST + gRPC
status: REVIEWED
version: 1
created: 2026-03-13
last_updated: 2026-03-31
last_reviewed: 2026-03-31
sync_strategy: provider-owns
---

# AMS → Mobile 接口契约

## 契约范围

移动端用户认证、注册、KYC 流程、个人资料管理、通知。AMS 为 Flutter 移动客户端提供完整的账户生命周期管理能力，包括登录注册、身份验证、KYC 资料提交与状态追踪、个人资料 CRUD、以及站内通知拉取。

## 接口清单（按模块分类）

### 1️⃣ 认证（Authentication）

**实现状态**：❌ 待实现
**来源文档**：TBD in `services/ams/docs/specs/api/rest/auth.md`
**描述**：登录、注册、Token 刷新、生物识别认证

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| POST | /api/v1/auth/login | 手机号+密码登录，返回 JWT access + refresh token | TBD | v1 |
| POST | /api/v1/auth/register | 新用户注册（邮箱、密码） | TBD | v1 |
| POST | /api/v1/auth/refresh | 使用 refresh token 刷新 access token | TBD | v1 |
| POST | /api/v1/auth/biometric | 生物识别认证（指纹/面容），绑定设备 ID | TBD | v1 |

**规范参考**：
- Token 生命周期：access token 15 分钟，refresh token 7 天（JWT RS256）
- 设备绑定：Token 绑定 device_id + IP 范围
- MFA：TOTP + SMS/Email 备用
- 速率限制：5 req/5min per IP+user

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

**实现状态**：❌ 待实现
**来源文档**：TBD in `services/ams/docs/specs/api/rest/profile.md`
**描述**：获取、更新个人资料，包括基本信息、偏好设置、PII 脱敏

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| GET | /api/v1/profile | 获取个人资料（脱敏返回） | TBD | v1 |
| PUT | /api/v1/profile | 更新个人资料（关键字段需重新验证） | TBD | v1 |

**规范参考**：
- 资料字段：姓名、出生日期、国籍、税务居住地、就业、财务信息
- PII 加密：SSN、HKID、护照号在应用层 AES-256-GCM 加密
- PII 脱敏：SSN `***-**-1234`，HKID `A****(3)`，Email `j***e@example.com`
- 关键字段变更（姓名、税号）需重新验证

---

### 4️⃣ 通知（Notifications）

**实现状态**：❌ 待实现
**来源文档**：TBD in `services/ams/docs/specs/api/rest/notifications.md`
**描述**：获取站内通知列表，支持分页、已读/未读筛选、多渠道投递

| 方法 | 路径 | 用途 | SLA | 引入版本 |
|------|------|------|-----|---------|
| GET | /api/v1/notifications | 通知列表（分页，已读/未读筛选） | TBD | v1 |

**规范参考**：
- 多渠道：Push (FCM)、邮件、短信、应用内
- 事件类型：KYC 状态变更、W-8BEN 续期、账户警告、合规冻结
- 用户偏好设置：按渠道和事件类型配置
- 通知持久化：应用内已读/未读状态

---

## 数据流向

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
| v1 | 2026-03-31 | 首次审核：按模块分类，引用已定义的 KYC 合约，标记待实现模块指向 TBD 文档。完善安全规范（认证、PII 脱敏、速率限制）。 | REVIEWED |
| v0 | 2026-03-13 | 初始创建（占位符） | DRAFT |
