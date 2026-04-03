# AMS Kafka 事件规范

> **版本**: v0.1
> **日期**: 2026-03-30
> **作者**: AMS Engineering
> **状态**: Draft — 待技术评审
>
> 本文档定义 AMS 发布的所有 Kafka 事件，供下游服务（Trading Engine、Fund Transfer、Admin Panel）消费。

---

## 目录

1. [总体原则](#1-总体原则)
2. [事件：account.status_changed](#2-事件-accountstatus_changed)
3. [事件：认证相关事件](#3-事件认证相关事件)
4. [Kafka 主题配置](#4-kafka-主题配置)
5. [消费方职责](#5-消费方职责)
6. [Schema 演进规则](#6-schema-演进规则)

---

## 1. 总体原则

- **Outbox 模式**：所有事件通过数据库 Outbox 表发布，保证"最少一次投递"（at-least-once delivery）。
- **幂等消费**：消费方须通过 `event_id`（UUID v4）做幂等去重，忽略重复事件。
- **不含 PII**：Kafka payload 不允许出现加密前的 PII 字段（SSN、HKID、银行账号等）。
- **UTC 时间**：所有时间戳使用 ISO 8601 UTC 格式（`2026-03-30T09:00:00.000Z`）。
- **向后兼容**：新字段只追加，不删除、不重命名已有字段；版本变更时递增 `schema_version`。

---

## 2. 事件：account.status_changed

### 2.1 事件概要

| 属性 | 值 |
|------|----|
| **事件名** | `account.status_changed` |
| **Kafka Topic** | `ams.account.status-changed` |
| **Partition Key** | `account_id`（保证同一账户事件有序） |
| **触发方** | AMS |
| **主要消费方** | Trading Engine（立即失效 Redis 账户缓存），Admin Panel（合规监控） |
| **引入版本** | v1.1（2026-03-30，见 docs/contracts/ams-to-trading.md v1.1） |

### 2.2 触发条件

下列任一变更发生时，AMS **必须**发布此事件：

| 变更字段 | 示例场景 |
|----------|----------|
| `account_status` | ACTIVE → SUSPENDED（合规冻结）、SUSPENDED → ACTIVE（解冻） |
| `is_restricted` | 0 → 1（PDT 标记触发）、1 → 0（限制解除） |
| `restriction_reason` | 限制原因更新 |
| `restriction_until_at` | 限制解除时间变更 |
| `kyc_status` | PENDING → APPROVED / REJECTED / SUSPENDED |
| `kyc_tier` | TIER_1 → TIER_2（KYC 完整通过后升级） |

> **重要**：`is_restricted` 字段由 AMS 业务逻辑在以下条件下置 `true`：
> - `pdt_flagged = 1`（PDT 标记，由 Trading Engine 通过内部 API 通知 AMS 更新）
> - 合规官员触发冻结操作
> - `account_status` 变更为 `SUSPENDED`
>
> AMS 在上述任一条件发生时同步更新 `is_restricted`，并发布此 Kafka 事件。

### 2.3 Payload Schema（JSON）

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "AccountStatusChangedEvent",
  "type": "object",
  "required": [
    "event_id",
    "event_type",
    "schema_version",
    "account_id",
    "changed_fields",
    "previous",
    "current",
    "changed_at",
    "correlation_id"
  ],
  "properties": {
    "event_id": {
      "type": "string",
      "format": "uuid",
      "description": "UUID v4，用于消费方幂等去重"
    },
    "event_type": {
      "type": "string",
      "const": "account.status_changed"
    },
    "schema_version": {
      "type": "integer",
      "description": "Payload schema 版本号，当前为 1"
    },
    "account_id": {
      "type": "string",
      "format": "uuid",
      "description": "账户 UUID（accounts.account_id）"
    },
    "changed_fields": {
      "type": "array",
      "items": { "type": "string" },
      "description": "本次事件中实际发生变更的字段名列表，如 [\"is_restricted\", \"restriction_reason\"]",
      "minItems": 1
    },
    "previous": {
      "$ref": "#/$defs/AccountStatusSnapshot",
      "description": "变更前的字段快照（仅包含 changed_fields 中列出的字段）"
    },
    "current": {
      "$ref": "#/$defs/AccountStatusSnapshot",
      "description": "变更后的字段快照（仅包含 changed_fields 中列出的字段）"
    },
    "changed_at": {
      "type": "string",
      "format": "date-time",
      "description": "变更发生时间，ISO 8601 UTC，如 2026-03-30T09:00:00.123Z"
    },
    "correlation_id": {
      "type": "string",
      "description": "触发本次变更的业务请求的关联 ID（用于链路追踪）"
    },
    "actor_id": {
      "type": ["string", "null"],
      "description": "触发变更的操作人 ID；null 表示系统自动触发"
    },
    "actor_type": {
      "type": "string",
      "enum": ["SYSTEM", "COMPLIANCE_OFFICER", "ADMIN"],
      "description": "操作人类型"
    }
  },
  "$defs": {
    "AccountStatusSnapshot": {
      "type": "object",
      "description": "账户状态字段的部分快照，只包含 changed_fields 中的字段",
      "properties": {
        "account_status": {
          "type": "string",
          "enum": ["APPLICATION_SUBMITTED", "KYC_IN_PROGRESS", "KYC_ADDITIONAL_INFO",
                   "ACTIVE", "SUSPENDED", "UNDER_REVIEW", "CLOSING", "CLOSED", "REJECTED"],
          "description": "账户生命周期状态"
        },
        "kyc_status": {
          "type": "string",
          "enum": ["PENDING", "APPROVED", "REJECTED", "SUSPENDED"],
          "description": "KYC 核验状态"
        },
        "kyc_tier": {
          "type": "string",
          "enum": ["TIER_1", "TIER_2"],
          "description": "KYC 层级"
        },
        "is_restricted": {
          "type": "boolean",
          "description": "账户是否受限（PDT/合规冻结/SUSPENDED）"
        },
        "restriction_reason": {
          "type": ["string", "null"],
          "description": "限制原因，is_restricted=false 时为 null"
        },
        "restriction_until_at": {
          "type": ["string", "null"],
          "format": "date-time",
          "description": "限制解除时间（ISO 8601 UTC），null = 无限期"
        }
      },
      "additionalProperties": false
    }
  }
}
```

### 2.4 事件示例

**场景 1：PDT 标记触发账户限制**

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440001",
  "event_type": "account.status_changed",
  "schema_version": 1,
  "account_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "changed_fields": ["is_restricted", "restriction_reason"],
  "previous": {
    "is_restricted": false,
    "restriction_reason": null
  },
  "current": {
    "is_restricted": true,
    "restriction_reason": "PDT: 5 交易日内第 4 次日内交易，账户净值 < $25,000"
  },
  "changed_at": "2026-03-30T14:30:00.123Z",
  "correlation_id": "req-abc123def456",
  "actor_id": null,
  "actor_type": "SYSTEM"
}
```

**场景 2：合规冻结账户**

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440002",
  "event_type": "account.status_changed",
  "schema_version": 1,
  "account_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "changed_fields": ["account_status", "is_restricted", "restriction_reason", "restriction_until_at"],
  "previous": {
    "account_status": "ACTIVE",
    "is_restricted": false,
    "restriction_reason": null,
    "restriction_until_at": null
  },
  "current": {
    "account_status": "SUSPENDED",
    "is_restricted": true,
    "restriction_reason": "AML_REVIEW: 制裁名单疑似匹配，待人工核查",
    "restriction_until_at": null
  },
  "changed_at": "2026-03-30T16:00:00.000Z",
  "correlation_id": "req-aml-review-9999",
  "actor_id": "compliance-officer-007",
  "actor_type": "COMPLIANCE_OFFICER"
}
```

**场景 3：KYC 审核通过**

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440003",
  "event_type": "account.status_changed",
  "schema_version": 1,
  "account_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "changed_fields": ["kyc_status", "kyc_tier"],
  "previous": {
    "kyc_status": "PENDING",
    "kyc_tier": "TIER_1"
  },
  "current": {
    "kyc_status": "APPROVED",
    "kyc_tier": "TIER_2"
  },
  "changed_at": "2026-03-30T10:15:00.000Z",
  "correlation_id": "req-kyc-review-1234",
  "actor_id": "kyc-reviewer-003",
  "actor_type": "COMPLIANCE_OFFICER"
}
```

---

## 3. 事件：认证相关事件

### 3.1 事件列表

本节定义 AMS 认证系统（device-management.md、auth-architecture.md、session-refresh-strategy.md）发布的事件。

| 事件类型 | Topic | Partition Key | 优先级 | 消费方 |
|---------|-------|-------------|-------|-------|
| `auth.otp_sent` | `ams.auth.otp-sent` | account_id | LOW | Analytics |
| `auth.otp_verified` | `ams.auth.otp-verified` | account_id | NORMAL | AuditLog |
| `auth.login_failed` | `ams.auth.login-failed` | account_id | NORMAL | AuditLog, Notification |
| `auth.device_added` | `ams.auth.device-added` | account_id | NORMAL | Notification |
| `auth.device_kicked` | `ams.auth.device-kicked` | account_id | **HIGH** | Notification, AuditLog |
| `auth.device_revoked` | `ams.auth.device-revoked` | account_id | NORMAL | Notification, AuditLog |
| `auth.session_expired` | `ams.auth.session-expired` | account_id | LOW | AuditLog |
| `auth.account_locked` | `ams.auth.account-locked` | account_id | **HIGH** | Notification, AuditLog |

### 3.2 事件详定义

#### auth.otp_sent（OTP 发送）

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.otp_sent",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:30:00.000Z",
  "phone_number_hash": "HMAC-SHA256(phone_number, secret)",
  "account_id": "account-uuid-or-null",  // 新用户时为 null
  "send_method": "SMS",  // SMS, EMAIL, VOICE
  "region_code": "+86",  // E.164 区号
  "correlation_id": "req-abc"
}
```

**消费方**：Analytics —— 追踪 OTP 发送成功率、区域分布等

---

#### auth.otp_verified（OTP 验证成功）

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.otp_verified",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:31:00.000Z",
  "account_id": "account-uuid",
  "is_new_user": true,  // 新注册 vs 已有用户
  "device_id": "device-uuid",
  "phone_number_hash": "HMAC-SHA256(phone_number, secret)",
  "attempts_count": 1,  // 本次 OTP 请求需要的尝试次数
  "correlation_id": "req-abc"
}
```

**消费方**：AuditLog —— 审计用户登录记录（7 年保留）

---

#### auth.login_failed（登录失败，多次失败时锁定）

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.login_failed",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:32:00.000Z",
  "phone_number_hash": "HMAC-SHA256(phone_number, secret)",
  "account_id": "account-uuid-or-null",
  "failure_reason": "INVALID_OTP",  // INVALID_OTP, OTP_EXPIRED, INVALID_REFRESH_TOKEN 等
  "attempt_count": 3,  // 当前累计尝试次数（本次错误的计数值）
  "ip_address": "192.168.1.100",
  "device_fingerprint": "device-uuid",
  "locked": false,  // 当 attempt_count >= 5 时，locked = true
  "locked_until": "2026-04-01T10:47:00.000Z",  // attempt_count >= 5 时出现
  "correlation_id": "req-abc"
}
```

**消费方**：
- AuditLog —— 审计日志
- Notification Service —— 当 locked = true 时，发送 HIGH 优先级推送告警

---

#### auth.device_added（新设备登录）

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.device_added",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:35:00.000Z",
  "account_id": "account-uuid",
  "device_id": "device-uuid",
  "device_name": "iPhone 15 Pro",
  "os_type": "ios",
  "os_version": "17.3",
  "app_version": "1.0.0",
  "location_country": "CN",
  "location_city": "Beijing",
  "ip_address": "192.168.1.100",
  "correlation_id": "req-abc"
}
```

**消费方**：Notification Service —— 发送推送通知："您的账号已在 [设备名] 登录"

---

#### auth.device_kicked（设备被超限踢出）【HIGH 优先级】

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.device_kicked",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:37:00.000Z",
  "account_id": "account-uuid",
  "kicked_device_id": "device-uuid",
  "kicked_device_name": "iPad Air",
  "reason": "AUTO_LIMIT",  // AUTO_LIMIT, MANUAL_REVOCATION, SECURITY_POLICY
  "initiator": "system",  // system 或触发者的 device_id
  "correlation_id": "req-abc"
}
```

**消费方**：
- Notification Service (Priority: HIGH) —— 立即推送 + SMS："您的账号已在新设备登录，如非本人操作请立即联系客服"
- AuditLog —— 审计日志

**SLA**：5 秒内首次投递尝试

---

#### auth.device_revoked（设备被手动注销）

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.device_revoked",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:40:00.000Z",
  "account_id": "account-uuid",
  "revoked_device_id": "device-uuid",
  "revoked_device_name": "MacBook Pro",
  "initiator_device_id": "device-xxx",  // 执行远程注销的设备
  "reason": "MANUAL_REVOCATION",
  "correlation_id": "req-abc"
}
```

**消费方**：
- Notification Service —— 推送通知给被注销设备："您已在该设备上注销登录"
- AuditLog —— 审计日志

---

#### auth.session_expired（会话过期）

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.session_expired",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:45:00.000Z",
  "account_id": "account-uuid",
  "device_id": "device-uuid",
  "reason": "REFRESH_TOKEN_EXPIRED",  // REFRESH_TOKEN_EXPIRED, DEVICE_REMOVED, MANUAL_LOGOUT
  "correlation_id": "req-abc"
}
```

**消费方**：AuditLog —— 会话生命周期审计

---

#### auth.account_locked（账户锁定）【HIGH 优先级】

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "auth.account_locked",
  "schema_version": 1,
  "timestamp": "2026-04-01T10:32:00.000Z",
  "account_id": "account-uuid",
  "phone_number_hash": "HMAC-SHA256(phone_number, secret)",
  "reason": "OTP_ERROR_LIMIT",  // OTP_ERROR_LIMIT, COMPLIANCE, SECURITY_POLICY
  "locked_until": "2026-04-01T10:47:00.000Z",  // 30 分钟后自动解锁
  "unlock_reason": "AUTO_UNLOCK_AFTER_TIMEOUT",  // 预置解锁原因
  "correlation_id": "req-abc"
}
```

**消费方**：
- Notification Service (Priority: HIGH) —— 立即推送 + SMS："多次登录失败，账号已暂时锁定，请 30 分钟后重试"
- AuditLog —— 安全事件审计

**SLA**：5 秒内首次投递尝试

---

### 3.3 事件通用字段

所有认证事件都包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `event_id` | string(UUID) | 唯一事件 ID，用于消费方幂等去重 |
| `event_type` | string | 事件类型（如 `auth.otp_sent`） |
| `schema_version` | int | Payload schema 版本，当前为 1 |
| `timestamp` | string(ISO8601-UTC) | 事件发生时间 |
| `correlation_id` | string | 链路追踪 ID（来自 HTTP 请求的 X-Correlation-ID）|

**约束**：
- 所有时间戳使用 UTC 并为 ISO 8601 格式
- 所有 ID（account_id、device_id、event_id）为 UUID v4
- 个人信息（手机号、邮箱）使用哈希：`HMAC-SHA256(value, HMAC_KEY)`

---



| 主题 | Partitions | Replication Factor | Retention | 压缩 |
|------|-----------|-------------------|-----------|------|
| `ams.account.status-changed` | 12 | 3 | 7 天（合规保留） | snappy |

**Partition 策略**：以 `account_id` 为 partition key，保证同一账户的事件全局有序，Trading Engine 消费时可按顺序处理 Redis 缓存失效。

---

## 4. 消费方职责

### Trading Engine

| 操作 | 细节 |
|------|------|
| **消费触发** | 订阅 `ams.account.status-changed`，Consumer Group: `trading-engine-account-cache` |
| **缓存失效** | 收到事件后立即删除 Redis Key `account:{account_id}:status`（不等 TTL 到期） |
| **幂等处理** | 通过 `event_id` 去重，已处理的 event_id 记录在 Redis Set，TTL 72h |
| **失败处理** | 消费失败重试 3 次，超出写入 DLQ（Dead Letter Queue）`ams.account.status-changed.dlq` |
| **延迟 SLA** | 从 AMS 发布到 Trading Engine 缓存失效 < 500ms（P95） |

### Admin Panel

订阅同一主题，Consumer Group: `admin-panel-account-audit`，用于实时更新合规监控仪表盘和触发告警通知。

---

### Admin Panel

订阅 `ams.account.status-changed`，Consumer Group: `admin-panel-account-audit`，用于实时更新合规监控仪表盘和触发告警通知。

---

## 6. Schema 演进规则

1. **向后兼容**：只追加新字段，已有字段不重命名、不删除、不改类型。
2. **版本号**：追加新必填字段时递增 `schema_version`（从 1 → 2）。
3. **消费方容错**：消费方须忽略未知字段（`additionalProperties` 实际处理时不报错）。
4. **变更通知**：任何 breaking change 须提前 2 周通知所有消费方，并在 `docs/contracts/` 更新对应契约文件。

---

## Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| v0.2 | 2026-04-01 | 新增认证相关事件（8 个）：OTP、设备管理、账户锁定、会话管理 |
| v0.1 | 2026-03-30 | 初版：account.status_changed 事件定义 |

---

## 参考资料

- `device-management.md` — 设备事件来源
- `auth-architecture.md` — 认证系统与 OTP 规则
- `session-refresh-strategy.md` — 会话生命周期事件
- `push-notification.md` — 通知消费方处理
- `../../.claude/rules/financial-coding-standards.md` — 审计日志保留规则
