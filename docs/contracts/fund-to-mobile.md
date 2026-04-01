---
provider: services/fund-transfer
consumer: mobile
protocol: REST
status: DRAFT
version: 1
created: 2026-03-13
last_updated: 2026-03-31
last_reviewed: 2026-03-31
sync_strategy: provider-owns
---

# Fund Transfer → Mobile 接口契约

## 契约范围

移动端出入金操作、银行卡管理、资金余额查询。Fund Transfer 为 Flutter 移动客户端提供完整的资金管理能力。

**业务范围**（Phase 1）：
- ✅ USD 入金（ACH/Wire）
- ✅ USD 出金（ACH/Wire）
- ✅ 银行卡绑定与管理
- ✅ 资金余额与流水查询

详细的业务规则、出金审批矩阵、AML 筛查、同名账户验证、结算周期等见：
- 📖 [Mobile Surface PRD-05](../../../mobile/docs/prd/05-funding.md) — 用户交互与页面设计
- 📖 [Fund Transfer Domain PRD](../../services/fund-transfer/docs/prd/fund-transfer-system.md) — 完整业务规则与合规要求

## 接口列表

| 方法 | 路径 | gRPC 对应 | 用途 |
|------|------|----------|------|
| GET | /api/v1/balance | `GetBalance` | 查询账户余额 |
| POST | /api/v1/deposit | `InitiateDeposit` | 发起入金 |
| POST | /api/v1/withdrawal | `InitiateWithdrawal` | 发起出金 |
| GET | /api/v1/fund/history | `ListDeposits` / `ListWithdrawals` | 出入金记录 |
| GET | /api/v1/bank-accounts | `ListBankAccounts` | 已绑定银行卡列表 |
| POST | /api/v1/bank-accounts | `AddBankAccount` | 绑定新银行卡 |
| DELETE | /api/v1/bank-accounts/:id | `RemoveBankAccount` | 解绑银行卡 |

**Proto 定义**：`services/fund-transfer/docs/specs/api/grpc/fund_transfer.proto`

## 数据模型

所有接口遵循 gRPC proto 消息定义。REST 接口是其 JSON 映射。

### 余额（Balance）

引用 gRPC `Balance` message：

```protobuf
message Balance {
  string account_id = 1;
  Currency currency = 2;
  string total_balance = 3;        // 账户总资产
  string available_balance = 4;    // 可用现金（未冻结）
  string unsettled_amount = 5;     // 待结算资金（T+1/T+2）
  google.protobuf.Timestamp updated_at = 6;
}
```

**Mobile 端显示**（见 [Surface PRD § 5.1](../../../mobile/docs/prd/05-funding.md)）：
- **账户总资产** = total_balance
- **可用现金** = available_balance
- **待结算资金** = unsettled_amount
- **可提现金额** = available_balance - frozen_withdrawal（由 Fund Transfer 计算，通过交易状态推导）

**注**：`frozen_withdrawal` 由出金历史状态推导，不在 Balance 消息中；Mobile 应通过 `ListWithdrawals` 的 PENDING 状态出金金额来计算。

### 资金转账（FundTransfer）

引用 gRPC `FundTransfer` message：

```protobuf
message FundTransfer {
  string transfer_id = 1;
  string account_id = 2;
  TransferType type = 3;           // DEPOSIT or WITHDRAWAL
  TransferStatus status = 4;
  string amount = 5;               // decimal string
  Currency currency = 6;
  BankChannel channel = 7;         // ACH, WIRE, FPS, CHATS, SWIFT
  string bank_account_id = 8;
  string request_id = 9;           // idempotency key
  string failure_reason = 10;
  google.protobuf.Timestamp created_at = 11;
  google.protobuf.Timestamp updated_at = 12;
  google.protobuf.Timestamp completed_at = 13;
}

enum TransferStatus {
  TRANSFER_STATUS_UNSPECIFIED = 0;
  TRANSFER_STATUS_PENDING = 1;
  TRANSFER_STATUS_COMPLIANCE_CHECK = 2;
  TRANSFER_STATUS_BALANCE_CHECK = 3;
  TRANSFER_STATUS_SETTLEMENT_CHECK = 4;
  TRANSFER_STATUS_APPROVAL = 5;
  TRANSFER_STATUS_BANK_PROCESSING = 6;
  TRANSFER_STATUS_CONFIRMED = 7;
  TRANSFER_STATUS_LEDGER_UPDATED = 8;
  TRANSFER_STATUS_COMPLETED = 9;
  TRANSFER_STATUS_FAILED = 10;
  TRANSFER_STATUS_REJECTED = 11;
}
```

**Mobile 端用户看到的状态**（见 [Surface PRD § 4.2 § 4.3](../../../mobile/docs/prd/05-funding.md)）：
- "提交中" → PENDING, COMPLIANCE_CHECK, BALANCE_CHECK, SETTLEMENT_CHECK
- "审核中" → APPROVAL（人工审核或合规审批）
- "处理中" → BANK_PROCESSING
- "已到账" → COMPLETED
- "已拒绝" → REJECTED, FAILED
- "已退款" → COMPLETED（with failure_reason = "BANK_REVERSAL"）

### 银行账户（BankAccount）

引用 gRPC `BankAccount` message：

```protobuf
message BankAccount {
  string bank_account_id = 1;
  string account_id = 2;
  string account_name = 3;
  string account_number = 4;       // AES-256-GCM encrypted
  string routing_number = 5;
  string swift_code = 6;
  string bank_name = 7;
  Currency currency = 8;
  bool is_verified = 9;
  google.protobuf.Timestamp created_at = 10;
}
```

**Mobile 端处理**（见 [Security-Compliance Rules § PII 脱敏](../../.claude/rules/security-compliance.md)）：
- `account_number` 在 REST 响应中**脱敏显示为末 4 位**：`****1234`
- 应用层（Flutter）在 UI 中强制脱敏，不依赖服务端

**冷却期**（见 [Domain PRD § 2.3](../../services/fund-transfer/docs/prd/fund-transfer-system.md)）：
- 银行卡绑定后进入 3 天冷却期，期间不可用于出入金
- 冷却期状态由 Fund Transfer 计算：`created_at + 3 天 > 当前时间`
- Mobile 应显示"✓ 已验证，可在 X 天后使用"

## 认证与安全

所有规则引用自 [Security-Compliance Rules](../../.claude/rules/security-compliance.md) 和 [Financial Coding Standards](../../.claude/rules/financial-coding-standards.md)：

### 身份认证

- **所有端点均需 JWT Bearer token**（15 分钟过期）
- 出金操作（POST /withdrawal）**必须通过生物识别认证**（见 [Security-Compliance § Biometric Authentication](../../.claude/rules/security-compliance.md)）
- 绑定新银行卡（POST /bank-accounts）**必须通过身份重验证**（生物识别或 2FA）（见 [Domain PRD § 2.1](../../services/fund-transfer/docs/prd/fund-transfer-system.md)）

### 幂等性

所有状态变更请求（POST /deposit, POST /withdrawal, POST /bank-accounts）**必须携带 `Idempotency-Key` header**：
- 格式：UUID v4
- 缓存时间：**72 小时**（见 [Fund Transfer Compliance Rules § Rule 8](../../.claude/rules/fund-transfer-compliance.md)）
- 重复提交：返回首次响应（缓存命中）

### 数据保护

- 银行卡号：**AES-256-GCM 加密**存储，REST 响应中脱敏为末 4 位（见 [Security-Compliance § PII Masking](../../.claude/rules/security-compliance.md)）
- 所有余额、转账记录均需 JWT 认证
- 证书固定（Certificate Pinning）由 Mobile 端实现（见 [Security-Compliance § Certificate Pinning](../../.claude/rules/security-compliance.md)）

## 业务规则引用

### 余额与提现（Balance & Withdrawal）

见 [Domain PRD § 2.2 可提现金额计算](../../services/fund-transfer/docs/prd/fund-transfer-system.md)：

```
可提现金额 = 总现金 - 待结算资金 - 冻结出金 - 保证金
```

结算周期（见 [Domain PRD § 2.2](../../services/fund-transfer/docs/prd/fund-transfer-system.md)）：
- **US 股票**：T+1（自 2024 年 5 月起）
- **HK 股票**：T+2（Phase 2）

### 银行卡绑定与冷却期

见 [Domain PRD § 2.3 银行卡绑定与冷却期](../../services/fund-transfer/docs/prd/fund-transfer-system.md)：

| 绑定天数 | 入金 | 出金 | 说明 |
|---------|------|------|------|
| **0–3 天（冷却期）** | ❌ | ❌ | 新绑卡风险等级最高 |
| **≥ 3 天** | ✅ | ✅ | 正常使用 |

超时未验证（14 天）：该绑卡作废，用户需删除后重新绑定。

**微存款验证**（见 [Surface PRD § 4.1](../../../mobile/docs/prd/05-funding.md)）：
- 等待 1-3 个工作日
- 用户输入 2 笔小额存款金额
- 验证失败 ≥ 5 次：该卡作废

### 出金审批规则

见 [Domain PRD § 2.4 出金审批规则](../../services/fund-transfer/docs/prd/fund-transfer-system.md)：

**自动审批**（< 1 分钟）：满足以下 5 个条件
- 金额 ≤ 日限额（由 AMS 决定）
- 银行卡验证 > 3 天
- 无 AML 标记
- 风险评分 = LOW
- 有历史出金记录

**人工审核**（1 工作日）：满足任一条件
- 金额 > $50,000 USD（单笔）
- 日累计额度 > 日限额 80%
- 冷却期不足（3-7 天）
- 账户新开（< 30 天）
- 风险评分 MEDIUM 或 HIGH
- AML 需人工审查

**合规专员审批**（1-2 工作日）
- 金额 > $200,000 USD
- 触发 SAR（可疑活动报告）

### KYC 限额

见 [Domain PRD § 2.5 KYC 等级限额](../../services/fund-transfer/docs/prd/fund-transfer-system.md)：

| KYC 等级 | 单笔限额 | 日限额 | 月限额 |
|---------|---------|--------|--------|
| **Tier 1** | $5,000 | $10,000 | $50,000 |
| **Tier 2** | $50,000 | $100,000 | $500,000 |

**获取方式**：Fund Transfer 在每次入出金前调用 AMS API `GetAccountKYCTier(user_id)` 获取实时限额。

### AML 筛查

见 [Domain PRD § 2.6 AML 筛查与 CTR 申报](../../services/fund-transfer/docs/prd/fund-transfer-system.md)：

- **每笔入出金都进行 AML 筛查，无例外**
- 筛查列表：OFAC SDN、Sectoral Sanctions、SFC 指定人员、AMLO Part 4A
- 筛查结果：PASS / REVIEW / BLOCK
- **CTR 自动申报**：USD ≥ $10,000，HKD ≥ HK$120,000

### 同名账户原则

见 [Domain PRD § 2.1 同名账户原则](../../services/fund-transfer/docs/prd/fund-transfer-system.md) + [Fund Transfer Compliance Rules § Rule 1](../../.claude/rules/fund-transfer-compliance.md)：

- 用户**只能**向自己名下的银行账户入出金
- 绑卡时系统自动填充 KYC 姓名，用户验证（不可修改）
- 系统自动进行**模糊匹配**（忽略大小写、标点、空格）
- 不匹配时返回错误码 `ACCOUNT_MISMATCH`

### 入金后资金状态

见 [Domain PRD § 3.3 入金后的资金状态](../../services/fund-transfer/docs/prd/fund-transfer-system.md)：

- 入金成功率 ≥ 97%
- 成功入金后**立即可用**（可交易、可再次出金）
- 用户在 Mobile 资金中心看到"待结算"或"已到账"状态

### 出金被银行退回

见 [Domain PRD § 4.3 出金被银行退回的处理](../../services/fund-transfer/docs/prd/fund-transfer-system.md) + [Surface PRD § 8.2 银行退回处理流程](../../../mobile/docs/prd/05-funding.md)：

- 银行拒绝：资金**立即恢复**至账户
- 用户收到**推送通知** + 退回原因
- 退款到账后**立即可用**

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：
   - `services/fund-transfer/docs/specs/api/grpc/fund_transfer.proto`（if gRPC 变更）
   - `services/fund-transfer/api/rest/`（REST 实现）
   - 本契约文件（version +1）
4. Thread 标记 RESOLVED

## Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| v1 | 2026-03-31 | 初始版本：引用 gRPC proto、Domain/Surface PRD、合规规则 |
