# AMS GetAccountStatus 新字段 — 快速参考卡

## 核心评估结果

### 字段存在性速查表

| 字段 | 存在？ | 当前位置 | 改动 | 工作量 |
|------|------|---------|------|--------|
| **kyc_status** | ✅ 是 | accounts.kyc_status | 枚举值调整（VERIFIED→APPROVED，新增 SUSPENDED） | **< 1h** |
| **kyc_tier** | ✅ 是 | accounts.kyc_tier | 类型转换（VARCHAR→INT32），BASIC→1, STANDARD→2 | **1-2h** |
| **account_type** | ✅ 是 | accounts.trading_type | 值映射（MARGIN_REG_T/MARGIN_PORTFOLIO→MARGIN） | **< 1h** |
| **is_restricted** | ⚠️ 部分 | 分散存储 | 新增 DB 字段 + 组合判断逻辑 | **3-5h** |

---

## 关键数字

| 指标 | 数值 | 说明 |
|------|------|------|
| **总工作量** | 19-24h | AMS (12-16h) + Trading Engine (7-8h) |
| **完成周期** | 2.5 天 | 含开发、测试、灰度 |
| **性能影响** | 可忽略 | +50 字节/响应，< 1ms 额外延迟 |
| **缓存命中率** | 90%+ | Redis TTL 60s 合理 |
| **MySQL QPS 压力** | 🟢 低 | 新字段同行查询，无额外成本 |
| **上线风险** | 🟢 低 | 灰度部署 + Kafka 事件驱动缓存失效 |

---

## Protobuf 快速示例

```protobuf
enum KYCStatus {
  PENDING = 1;
  APPROVED = 2;
  REJECTED = 3;
  SUSPENDED = 4;
}

enum KYCTier {
  TIER_1 = 1;
  TIER_2 = 2;
}

enum AccountType {
  CASH = 1;
  MARGIN = 2;
}

message GetAccountStatusResponse {
  string account_id = 1;
  KYCStatus kyc_status = 4;
  KYCTier kyc_tier = 5;
  AccountType account_type = 6;
  bool is_restricted = 7;
  string restriction_reason = 8;  // 可选
  int64 restriction_until_timestamp = 9;  // 可选
}
```

---

## is_restricted 推导规则

```
is_restricted = true 当：
  1. account_status ∈ {SUSPENDED, UNDER_REVIEW, CLOSING}
  2. 或 pdt_flagged=1 且 account_equity < $25,000
  3. 或 margin_call_active=1
  4. 或 存在未解除的 AML 冻结
```

---

## 缓存策略

```
Redis Key: account:{account_id}:status
TTL: 60 秒（平衡实时性与 QPS 压力）

失效驱动：
  - 订阅 Kafka topic: ams.account.status_changed
  - 事件到达时立即刷新缓存
  - Redis TTL 60s 兜底
```

---

## 实现优先顺序

1. **Task 1**: Product Manager 确认 KYC 等级→风控系数映射表
2. **Task 2-5**: AMS Engineer 实现（DB 迁移 + Protobuf + 业务逻辑 + Kafka）
3. **Task 6-7**: Trading Engineer 实现（缓存层 + 联调测试）
4. **Task 8**: DevOps 灰度部署（10% → 50% → 100%）

---

## 一句话结论

**完全可行。3 个字段已存在仅需映射，1 个新字段低成本，2.5 天完成，性能无压力。建议本周三（2026-04-02）前上线。**

### 可行性等级：🟢 HIGH（绿灯）

---

## 相关文档

- 详细评估：[AMS_GETACCOUNTSTATUS_FEASIBILITY.md](./AMS_GETACCOUNTSTATUS_FEASIBILITY.md)
- 原始需求：[AMS_CONTRACT_SUPPLEMENT.md](./AMS_CONTRACT_SUPPLEMENT.md)
- AMS 金融模型：`services/ams/docs/specs/account-financial-model.md`
- Trading 风控规则：`services/trading-engine/docs/prd/risk-rules.md`

