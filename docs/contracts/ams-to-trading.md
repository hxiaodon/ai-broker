---
provider: services/ams
consumer: services/trading-engine
protocol: gRPC
proto_file: services/ams/api/grpc/ams.proto
status: AGREED
version: 1
created: 2026-03-13
last_updated: 2026-03-30
last_reviewed: 2026-03-30
sync_strategy: provider-owns
---

# AMS → Trading Engine 接口契约

## 契约范围

交易域下单前调用 AMS 验证用户身份和账户状态，确保用户具备交易权限且不受合规限制（PDT 标记、KYC 审核状态、账户类型等）。

---

## gRPC 接口列表

| 方法 | 用途 | SLA (P95) | 版本引入 |
|------|------|----------|---------|
| `VerifySession` | 验证用户 session 有效性（JWT token） | <20ms | v1 |
| `GetAccountStatus` | 获取账户完整状态（含 KYC、账户类型、限制信息） | <30ms | v1 → **v1.1 补充字段** |
| `CheckAccountRestrictions` | 专项检查账户限制（PDT 标记、冻结、合规暂停） | <20ms | v1 |

---

## GetAccountStatus — 接口定义（v1.1）

### Protobuf 规范

```protobuf
syntax = "proto3";
package ams.v1;

enum KYCStatus {
  KYC_STATUS_UNSPECIFIED = 0;
  KYC_STATUS_PENDING     = 1;  // 审核中
  KYC_STATUS_APPROVED    = 2;  // 已通过
  KYC_STATUS_REJECTED    = 3;  // 已拒绝
  KYC_STATUS_SUSPENDED   = 4;  // 已暂停（合规要求）
}

enum KYCTier {
  KYC_TIER_UNSPECIFIED = 0;
  KYC_TIER_1           = 1;  // 基础开户（较低购买力上限）
  KYC_TIER_2           = 2;  // 完整 KYC（完整交易权限）
}

enum AccountType {
  ACCOUNT_TYPE_UNSPECIFIED = 0;
  ACCOUNT_TYPE_CASH        = 1;  // 现金账户（不支持保证金）
  ACCOUNT_TYPE_MARGIN      = 2;  // 保证金账户
}

message GetAccountStatusRequest {
  string account_id = 1;
}

message GetAccountStatusResponse {
  string account_id    = 1;
  string status        = 2;  // "ACTIVE" | "SUSPENDED" | "CLOSED"

  // v1.1 新增字段（2026-03-30 协商）
  KYCStatus   kyc_status   = 3;
  KYCTier     kyc_tier     = 4;
  AccountType account_type = 5;
  bool        is_restricted = 6;  // true = PDT 标记或合规冻结，不允许下单
  string      restriction_reason   = 7;  // 可选，限制原因说明
  int64       restriction_until_ts = 8;  // 可选，限制解除时间（Unix 纳秒，0 = 无限期）
}
```

### 字段说明

| 字段 | 数据来源（AMS DB） | 枚举映射 | 备注 |
|------|-----------------|---------|------|
| `kyc_status` | `accounts.kyc_status` | VERIFIED→APPROVED；新增 SUSPENDED | 已有字段，需枚举调整 |
| `kyc_tier` | `accounts.kyc_tier` | BASIC→TIER_1；STANDARD→TIER_2 | 已有字段，类型转换 VARCHAR→int32 |
| `account_type` | `accounts.trading_type` | MARGIN_REG_T→MARGIN；其余→CASH | 已有字段，简化映射 |
| `is_restricted` | `accounts.is_restricted`（**新增字段**） | 组合判断：PDT 标记 OR 合规冻结 OR 账户状态=SUSPENDED | 唯一新增 DB 字段 |

### AMS 侧实现工作量

| 工作项 | 工时 | 目标完成日期 |
|--------|------|------------|
| DB 迁移：`accounts` 表新增 `is_restricted` 字段 | 2h | 2026-04-01 |
| Protobuf 更新 + 重新生成 | 1h | 2026-04-01 |
| 业务逻辑：is_restricted 判断逻辑 | 3h | 2026-04-01 |
| Kafka 事件：`account.status_changed`（触发 Trading 缓存失效） | 4h | 2026-04-02 |
| 集成测试 + 联调 | 2h | 2026-04-02 |
| **合计** | **12h** | **2026-04-02** |

---

## Trading Engine 侧缓存策略

| 缓存键 | 内容 | TTL | 失效触发 |
|--------|------|-----|---------|
| `account:{id}:status` | GetAccountStatusResponse 完整响应 | **60s** | Kafka `account.status_changed` 事件（立即刷新）或 TTL 到期 |

**选用 60s TTL 的理由**：
- 账户状态变更频率极低（不影响实时性）
- 60s 缓存可将 AMS QPS 压力降低 90%+（假设下单频率 1 次/60s）
- 账户被暂停等高优先级事件通过 Kafka 事件立即失效（不等 TTL）

---

## 数据流向

```
POST /orders 到达 Trading Engine
    │
    ├── 1. Redis 查询账户缓存
    │       命中 → 直接使用缓存（目标 <5ms）
    │       未命中 → gRPC 调用 GetAccountStatus（目标 <30ms）
    │                并写入 Redis（TTL 60s）
    │
    ├── 2. 风控检查（使用缓存数据）
    │       is_restricted = true  → 拒绝，返回 403
    │       kyc_status ≠ APPROVED → 拒绝，返回 403
    │       account_type = CASH   → 跳过保证金检查
    │       account_type = MARGIN → 执行保证金检查
    │
    └── 3. 其余 7 道风控检查...

AMS 账户状态变更时：
    └── 发布 Kafka 事件 account.status_changed
        └── Trading Engine 消费 → 立即删除 Redis 缓存键
```

---

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/grpc/` 或 `api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

---

## Changelog

| 版本 | 日期 | 变更 | 协商方 |
|------|------|------|--------|
| v1.1 | 2026-03-30 | GetAccountStatus 补充 4 个新字段（kyc_status, kyc_tier, account_type, is_restricted）；新增 Protobuf 规范；明确 AMS 缓存策略（Redis TTL 60s + Kafka 事件驱动失效）；AMS 实现计划（12h，2026-04-02 完成） | ams-engineer + trading-engineer |
