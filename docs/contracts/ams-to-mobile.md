---
provider: services/ams
consumer: mobile
protocol: REST
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# AMS → Mobile 接口契约

## 契约范围

移动端用户认证、注册、KYC 流程、个人资料管理、通知。AMS 为 Flutter 移动客户端提供完整的账户生命周期管理能力，包括登录注册、身份验证、KYC 资料提交与状态追踪、个人资料 CRUD、以及站内通知拉取。

## 接口列表

| 方法 | 路径 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|------|-----|---------|
| POST | /api/v1/auth/login | 手机号+密码登录，返回 JWT access + refresh token | REST | TBD | v1 |
| POST | /api/v1/auth/register | 新用户注册（手机号、邮箱、密码） | REST | TBD | v1 |
| POST | /api/v1/auth/refresh | 刷新 JWT token（使用 refresh token） | REST | TBD | v1 |
| POST | /api/v1/auth/biometric | 生物识别认证（指纹/面容），绑定设备 ID | REST | TBD | v1 |
| GET | /api/v1/kyc/status | KYC 状态查询（NOT_STARTED / IN_PROGRESS / APPROVED / REJECTED） | REST | TBD | v1 |
| POST | /api/v1/kyc/submit | KYC 资料提交（身份证件、地址证明、税务信息） | REST | TBD | v1 |
| GET | /api/v1/profile | 获取个人资料 | REST | TBD | v1 |
| PUT | /api/v1/profile | 更新个人资料 | REST | TBD | v1 |
| GET | /api/v1/notifications | 通知列表（分页，支持已读/未读筛选） | REST | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体请求/响应 schema。

## 数据流向

AMS 向 Mobile 提供 JWT 认证令牌（access token + refresh token）、KYC 审核状态、用户个人资料、以及站内通知列表。Mobile 端提交用户注册信息、KYC 身份证件与地址证明文档、以及个人资料更新请求。

## 认证与安全

- 除 `/auth/login`、`/auth/register` 外，**所有端点均需 JWT Bearer token**
- 敏感操作（KYC 提交、资料修改）需**生物识别二次认证**
- KYC 文档上传限速：**5 req/min per user**
- Token 有效期：access token 15 分钟，refresh token 7 天
- PII 字段（SSN、HKID、出生日期）在响应中按规则脱敏

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`services/ams/api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
