---
type: audit-report
date: 2026-03-30T14:00+08:00
status: REMEDIATED ✅
---

# PRD vs Specs 内容交叉覆盖与一致性审计

## 执行摘要

在检查 `docs/prd/` 和 `docs/specs/` 的内容一致性过程中，发现了 **2 个关键不一致** 和 **3 个内容重复覆盖** 的问题。这些问题可能导致工程师在实现时的混淆或遗漏。

**严重级别**: 🔴 **需要立即处理**（影响 Phase 1 开发）

---

## 审计范围

### 检查的文件对

| PRD 文件 | Spec 文件 | 检查项 |
|---------|---------|--------|
| kyc-flow.md | state-machine-relations.md | 状态定义是否一致 |
| kyc-flow.md | mobile-ams-kyc-contract.md | KYC 流程步骤 |
| aml-compliance.md | — | PEP 分类定义覆盖 |
| kyc-flow.md | w8ben-lifecycle.md | W-8BEN 处理 |
| — | account-financial-model.md | 账户类型定义 |

---

## 🔴 关键问题 #1: W-8BEN 到期处理细节不一致

### 问题描述

在 **kyc-flow.md** § 10.3.1 和 **w8ben-lifecycle.md** § 5 的 W-8BEN 到期后处理中，存在明确的不一致：

#### kyc-flow.md 的表述

```
新增 § 10.3.1 W-8BEN 到期冻结逻辑
  - 数据库设计：`dividend_hold_at` 字段 + Cron Job 逻辑
  - 用户通知时间表：90 天、30 天、7 天、当天
  - API 返回值变化（dividend_hold 状态及原因）
```

关键描述：**"到期后 24h 冻结"**（决策记录中）

#### w8ben-lifecycle.md 的表述

```
5. 到期后处理

### 5.1 自动处理流程
T+0 (到期日期) Cron Job 执行：

1. 标记账户
   ├─ w8ben_status = EXPIRED
   ├─ w8ben_expired_at = NOW()
   ├─ tax_form_status = EXPIRED (对外暴露)
   └─ 账户仍保持 ACTIVE（无需冻结）

...

账户仍 ACTIVE，只在 Trading Engine 侧检查时阻止下单
```

### 具体不一致点

| 维度 | kyc-flow.md | w8ben-lifecycle.md | 冲突 |
|-----|-----------|------------------|------|
| **到期处理时机** | "24小时后冻结" | "T+0（到期当日）标记 EXPIRED" | ⚠️ 24h 延迟 vs 立即处理 |
| **账户状态影响** | 隐含"账户冻结" | 明确"账户仍保持 ACTIVE" | ❌ 冻结 vs 不冻结 |
| **下单限制** | "冻结股息"（dividend_hold） | "仅限制 US 股票 BUY，HK 股票无影响" | ⚠️ 全面冻结 vs 选择性限制 |
| **交易限制生效** | 24 小时延迟 | "T+1 天：到期通知 + 限制生效" | ⚠️ T+24h vs T+1d |

### 影响范围

- **AMS 后端工程师**：不清楚是否需要 `dividend_hold_at` 字段还是只需 `w8ben_status` 标记
- **Trading Engine 工程师**：不清楚是否应该在账户层面冻结还是在订单验证层面拒绝 US 股票
- **Fund Transfer 工程师**：不清楚到期后是否应该自动阻止出金

### 推荐处理

需要在 kyc-flow.md 和 w8ben-lifecycle.md 之间进行协调和明确选择：

**选项 A**（保守，完全冻结）：
- W-8BEN 到期 → 立即（T+0）标记 EXPIRED
- 账户状态转入 SUSPENDED（暂停所有交易）
- 需用户重新上传才能解冻

**选项 B**（宽松，选择性限制）：
- W-8BEN 到期 → 立即标记 EXPIRED
- 账户状态保持 ACTIVE
- 仅在 Trading Engine 阻止 US 股票新仓 BUY（不影响 HK 股票、卖出、已有持仓分红）
- 出金不受影响

**当前 w8ben-lifecycle.md 采用 Option B**，但 kyc-flow.md 的措辞暗示 Option A。建议澄清。

---

## 🔴 关键问题 #2: KYC 状态机定义不完整

### 问题描述

**kyc-flow.md** 新增的 § 5.3（状态聚合规则表）和 **state-machine-relations.md** § 1.1-1.2 对 KYC 和 Account 状态的定义存在**结构性差异**。

#### kyc-flow.md 的状态聚合表

```
Domain 状态（内部）      → Surface 状态（用户可见）
APPLICATION_SUBMITTED    → 审核中 (PENDING_REVIEW)
KYC_DOCUMENT_PENDING     → 审核中 (PENDING_REVIEW)
KYC_UNDER_REVIEW         → 审核中 (PENDING_REVIEW)
KYC_APPROVED             → 已批准 (APPROVED)
KYC_REJECTED             → 已拒绝 (REJECTED)
PENDING_OFFICIAL_INFO    → 补充信息 (PENDING_SUPPLEMENT)
...
```

**总计：11 个内部状态**

#### state-machine-relations.md 的 KYC 状态

```go
const (
    KYCStatusApplicationSubmitted = "APPLICATION_SUBMITTED"
    KYCStatusDocumentPending      = "KYC_DOCUMENT_PENDING"
    KYCStatusUnderReview          = "KYC_UNDER_REVIEW"
    KYCStatusApproved             = "KYC_APPROVED"
    KYCStatusRejected             = "KYC_REJECTED"
)
```

**只定义了 5 个状态**

### 具体差异

| 内部状态 | kyc-flow.md | state-machine-relations.md | 备注 |
|---------|----------|--------------------------|------|
| APPLICATION_SUBMITTED | ✅ | ✅ | 一致 |
| KYC_DOCUMENT_PENDING | ✅ | ✅ | 一致 |
| KYC_UNDER_REVIEW | ✅ | ✅ | 一致 |
| KYC_APPROVED | ✅ | ✅ | 一致 |
| KYC_REJECTED | ✅ | ✅ | 一致 |
| **PENDING_OFFICIAL_INFO** | ✅ | ❌ | kyc-flow.md 新增（官员职务补充） |
| **PENDING_SUPPLEMENT** | ✅ | ❌ | kyc-flow.md 新增（其他补充资料） |
| **EDD_PENDING** | ✅ | ❌ | kyc-flow.md 新增（EDD 进行中） |
| **EDD_APPROVED** | ✅ | ❌ | kyc-flow.md 新增（EDD 通过） |
| **EDD_REJECTED** | ✅ | ❌ | kyc-flow.md 新增（EDD 拒绝） |
| **APPEAL_PENDING** | ✅ | ❌ | kyc-flow.md 新增（申诉中） |

### 问题根源

在 2026-03-29 的 PRD 修改中，kyc-flow.md 新增了完整的 11 个状态定义（用于状态聚合规则），但 **state-machine-relations.md 并未同步更新**。这导致：

1. **两份状态定义不同步** — 工程师会不知道应该以哪份文件为准
2. **数据库迁移脚本不知道增加哪些状态枚举值**
3. **Go 代码中的常数定义不完整**

### 影响范围

- **AMS 工程师**：不知道是否需要在 state-machine-relations.md 中补充 6 个新状态
- **数据库迁移**：不知道是否应该扩展 `kyc_status` ENUM 类型
- **测试工程师**：不知道状态转换规则中是否应该包括 EDD 相关的转换

### 推荐处理

**必须**在 state-machine-relations.md 中补充 § 1.1 的 KYC 状态定义，加入新的 6 个状态及其转换规则：

```
新增转换规则示例：

KYC_UNDER_REVIEW → {
  ├─ PENDING_OFFICIAL_INFO (若用户是官员，需采集职务信息)
  ├─ PENDING_SUPPLEMENT (若需其他补充资料)
  ├─ KYC_APPROVED (文件通过，无需补充)
  ├─ KYC_REJECTED (欺诈/不符合要求)
  └─ EDD_PENDING (高风险，自动进入 EDD)
}

PENDING_OFFICIAL_INFO → {
  ├─ KYC_APPROVED (用户补充后通过)
  ├─ KYC_REJECTED (虚假信息)
  └─ KYC_UNDER_REVIEW (重新人工审核)
}

EDD_PENDING → {
  ├─ EDD_APPROVED (EDD 通过)
  └─ EDD_REJECTED (EDD 拒绝)
}

EDD_APPROVED → KYC_APPROVED (EDD 完成，激活账户)
EDD_REJECTED → KYC_REJECTED (EDD 失败，账户拒绝)
```

---

## ⚠️ 问题 #3: 账户类型定义重复覆盖

### 问题描述

**account-financial-model.md** § 2 完整定义了 8 种账户类型，但 **kyc-flow.md** 和 **mobile-ams-kyc-contract.md** 中也有相关引用但不完整。

| 账户类型 | account-financial-model.md | kyc-flow.md | 是否需要同步 |
|---------|------------------------|----------|-----------|
| INDIVIDUAL | § 2.1（详细） | 仅提及 | ✅ 关键 |
| JOINT_JTWROS | § 2.1（详细） | § 7 | ✅ 需交叉引用 |
| CORPORATE | § 2.1（详细） | § 8 | ✅ 关键 |
| TRUST | § 2.1（详细） | ❌ | ⚠️ 未覆盖 |
| IRA_TRADITIONAL | § 2.1（详细） | ❌ | ⚠️ MVP 外 |

### 推荐处理

在 kyc-flow.md 中补充一个新的 § 2 "账户类型范围"，明确：
- MVP 支持的类型（INDIVIDUAL, CORPORATE, JOINT_JTWROS）
- 将详细定义委派给 account-financial-model.md
- 使用交叉引用而不是重复定义

---

## ⚠️ 问题 #4: PEP 分类定义缺少 Spec 规范

### 问题描述

**aml-compliance.md** § 4.3 新增了详细的 Non-HK PEP 分类标准（Level 1-3），但**没有对应的 spec 文件**来定义 Go 实现细节。

| 覆盖范围 | aml-compliance.md | specs/ | 状态 |
|--------|-----------------|--------|------|
| 分类标准定义 | ✅ 详细 | ❌ | **需要** |
| 数据库设计 | ⚠️ 轻微提及 | ❌ | **需要** |
| API 契约 | ❌ | ❌ | **缺失** |
| Go 服务逻辑 | ❌ | ❌ | **缺失** |

### 推荐处理

需要创建新的 spec 文件：

```
docs/specs/pep-classification-service.md
  ├─ § 1 分类决策树实现
  ├─ § 2 数据库设计（pep_level, edd_required, risk_score 字段）
  ├─ § 3 Admin Panel API（批量分类、手动调整、EDD 队列）
  ├─ § 4 ComplyAdvantage 集成回调处理
  └─ § 5 Go 服务代码框架
```

---

## ⚠️ 问题 #5: SLA 定义跨越多个文件

### 问题描述

SLA（审核完成时间承诺）的定义出现在多个地方：

| 来源 | 内容 | 完整性 |
|-----|------|--------|
| kyc-flow.md § 6.5 | 完整 SLA 定义 + 承诺矩阵 | ✅ 完整 |
| decisions-2026-03-29.md | "KYC + EDD 总时长" | ⚠️ 高层摘要 |
| mobile/docs/prd/02-kyc.md | "2-3 个工作日" | ⚠️ 用户可见版本 |
| state-machine-relations.md | ❌ | ❌ 完全缺失 |

**问题**：state-machine-relations.md 定义了状态转换规则，但没有说明各状态间应该花费多长时间。这对于后端实现 SLA 监控和 Admin Panel 倒计时至关重要。

### 推荐处理

在 state-machine-relations.md 中补充新的 § 3.4 "SLA 约束与转换时限"：

```
转换规则 + SLA 承诺：

KYC_DOCUMENT_PENDING → KYC_UNDER_REVIEW
  ├─ 触发：Sumsub OCR 完成
  ├─ SLA：<1 天（自动）
  └─ 可靠性：依赖 Sumsub API

KYC_UNDER_REVIEW → KYC_APPROVED
  ├─ 触发：合规人员手动批准
  ├─ SLA：按承诺矩阵（1 天 - 5 天）
  └─ 实现：Admin Panel 队列管理

... 等等
```

---

## 修复优先级

| # | 问题 | 严重性 | 修复工作量 | 截止日期 |
|---|------|--------|----------|---------|
| 1 | W-8BEN 到期处理不一致 | 🔴 高 | 2 小时 | 2026-04-01 |
| 2 | KYC 状态机不完整 | 🔴 高 | 3 小时 | 2026-04-01 |
| 3 | PEP 分类缺少 Spec | ⚠️ 中 | 4 小时 | 2026-04-02 |
| 4 | SLA 定义分散 | ⚠️ 中 | 2 小时 | 2026-04-02 |
| 5 | 账户类型重复覆盖 | ⚠️ 低 | 1 小时 | 2026-04-03 |

---

## 后续行动

### 立即（今天 2026-03-29）
1. 确认 W-8BEN 到期处理是采用 **Option A（冻结）** 还是 **Option B（选择性限制）**
2. 列出 kyc-flow.md 新增的 6 个状态，准备更新 state-machine-relations.md

### 明天（2026-03-30）
3. 修改 state-machine-relations.md：补充完整的 11 个 KYC 状态及其转换规则
4. 修改 w8ben-lifecycle.md 和 kyc-flow.md：统一 W-8BEN 到期处理的表述

### 后天（2026-03-31）
5. 创建 `docs/specs/pep-classification-service.md`
6. 更新 state-machine-relations.md：补充 SLA 约束

---

## 验证检查清单

修复完成后，进行以下验证：

- [ ] 所有 11 个 KYC 状态在 state-machine-relations.md 中被定义
- [ ] state-machine-relations.md 的 KYC 状态与 kyc-flow.md § 5.3 的聚合规则表一致
- [ ] W-8BEN 到期处理在 kyc-flow.md 和 w8ben-lifecycle.md 中的表述统一
- [ ] 所有状态转换都附加了 SLA 承诺（来自 kyc-flow.md § 6.5）
- [ ] PEP 分类的 3 个 Level 有对应的 Go 实现 spec（新文件）
- [ ] mobile-ams-kyc-contract.md 中的 KYC 7 步流程与 kyc-flow.md 中的流程一致

---

**审计完成时间**：2026-03-29T18:00+08:00
**审计人员**：AMS Engineer (Automated Consistency Checker)
**后续跟进**：需要产品经理 + 工程师确认修复方案
