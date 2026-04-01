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
3. [Kafka 主题配置](#3-kafka-主题配置)
4. [消费方职责](#4-消费方职责)
5. [Schema 演进规则](#5-schema-演进规则)

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

## 3. Kafka 主题配置

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

## 5. Schema 演进规则

1. **向后兼容**：只追加新字段，已有字段不重命名、不删除、不改类型。
2. **版本号**：追加新必填字段时递增 `schema_version`（从 1 → 2）。
3. **消费方容错**：消费方须忽略未知字段（`additionalProperties` 实际处理时不报错）。
4. **变更通知**：任何 breaking change 须提前 2 周通知所有消费方，并在 `docs/contracts/` 更新对应契约文件。
