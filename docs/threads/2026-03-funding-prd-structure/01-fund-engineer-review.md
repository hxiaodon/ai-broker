---
seq: 01
author_role: fund-engineer
date: 2026-03-29T10:18+08:00
action: RAISE_ISSUE
---

# Fund Engineer 审查意见：Mobile PRD-05 与资金域 Domain PRD 结构

## 背景

在准备开发出入金（Funding）模块时，我对 Mobile PRD-05 进行了合规和架构审查。发现了三个**结构性缺陷**，不是工程问题，而是**文档架构问题**。

这些缺陷**直接影响跨域协作的效率和合规的可追溯性**。

---

## 发现的问题

### 1️⃣ 资金域 Domain PRD 完全缺失 — **最严重**

**事实**：
- `services/fund-transfer/docs/prd/` 目录为**空**
- 所有业务规则零散分布在三个地方：
  1. Mobile PRD-05（产品层面，混合了 UI 和业务逻辑）
  2. Tech Spec（工程层面，从实现角度出发）
  3. `.claude/rules/fund-transfer-compliance.md`（合规层面，强制规则）

**为什么这是问题**：

首先看规范怎么说的。根据 SPEC-ORGANIZATION § 三条铁律 第 1 条：

> **PRD 按类型归属：Surface PRD 跟界面走，Domain PRD 跟业务走**
> 描述"用户看到什么、怎么交互"的 Surface PRD 放 `mobile/docs/prd/`；
> 描述"业务规则、领域逻辑、合规要求"的 Domain PRD 放对应**后端域的** `docs/prd/`

资金域现在**违反了这条铁律**。Domain PRD 应该在 `services/fund-transfer/docs/prd/` 中存在。

**具体后果**：

- 👤 **Fund-engineer 的困境**：当我要开发"出金审批流程"时，我该去哪读规则？
  - Mobile PRD-05 §6.4 有一份审批矩阵
  - `.claude/rules` 有另一份规则定义
  - Tech Spec 有实现思路
  - 但**没有单一的业务规则源头（SSOT）**

- 🏗️ **跨域方的困难**：Trading 和 Admin 需要了解出金逻辑时，应该读谁？
  - 去 Mobile PRD？不对，那是 Surface，包含 UI 细节
  - 去 Tech Spec？那是实现方案，不是业务规则
  - 去 Rule？那是合规强制项，不是完整业务逻辑
  - **没有直接的、权威的来源**

- 📋 **PM 的困境**：需要确认"出金审批逻辑改一下，增加风险评分阈值"时，该改哪份文档？
  - 改 Mobile PRD？污染了 Surface 层
  - 改 Tech Spec？跳过了业务决策阶段
  - 改 Rule？Rule 是强制执行，应该是业务规则的**结果**，而不是源头

---

### 2️⃣ Mobile PRD-05 混入大量 Domain 内容 — 职责不清

我做了一个扫描。以下**不应该**出现在 Mobile Surface PRD 中：

| 章节 | 内容 | 为什么应该移出 |
|------|------|-------------|
| §6.1 同名账户原则 | "银行账户持有人姓名须与 KYC 认证的法定姓名一致" | 这是**业务规则**，Mobile 工程师无需在意。系统应该在后端自动检查，只告诉前端"success"或"fail"。 |
| §6.2 可提现金额计算 | 完整的计算公式：`可提现 = 总现金 - 待结算 - 冻结 - 保证金` | Mobile 工程师只需知道"在这个位置显示数字"。计算逻辑应该在 Domain PRD（业务规则）中定义。 |
| §6.3 银行卡冷却期 | "0–3 天禁止，3–7 天可能人工审核" 的规则矩阵 | **风险评分和审批判断是后端逻辑**。Mobile 只需知道 API 返回什么状态。 |
| §6.4 出金审批规则 | 三阶梯（auto/manual/escalation）的完整判断矩阵 | 这是**后端的状态机**。Mobile 无需知道"怎么判断"，只需知道"显示什么状态"。 |
| §9 合规要求 | AML/CTR/Structuring/Travel Rule | Mobile **无感知**。这些不应该出现在 Surface PRD，应该在 Domain PRD 中承诺实现。 |
| §10 异常与边界 | "超出日限额""验证失败""银行退回" 的完整处理逻辑 | 一部分是 Surface（用户看到的文案和状态），一部分是 Domain（系统如何判断和处理）。需要拆分。 |

**Mobile 工程师真正需要的是什么**：
- ✅ 页面布局、输入字段、验证提示（"Routing Number 必须 9 位数字"）
- ✅ 错误文案和重试机制（"验证失败，还有 3 次机会"）
- ✅ 生物识别流程（涉及 UI/UX）
- ✅ 页面状态转换（"提交中" → "已通过" / "已拒绝"）

**不需要的是什么**：
- ❌ 完整的 AML 筛查流程
- ❌ 出金审批的判断条件（"金额 > $50K 则人工审核"）
- ❌ 结算周期如何计算可提现金额
- ❌ CTR/Travel Rule 的具体实现承诺

目前 PRD-05 有 364 行，其中至少 30% 是 Domain 内容。如果分离出来，Mobile 工程师的上下文会**显著简化**。

---

### 3️⃣ 合规规则与 PRD 的同步风险

我对 `.claude/rules/fund-transfer-compliance.md`（10 条强制规则）和 Mobile PRD-05 做了逐条对比：

| Rule # | 规则 | PRD 中的状态 | 风险 |
|--------|------|-----------|------|
| Rule 1 | Same-Name Account | ✅ §6.1 有提及 | 无 |
| Rule 2 | AML Screening 强制 | ✅ §9 有提及 | 无 |
| Rule 3 | **Travel Rule** | ❌ **完全未提及** | 高：实现时可能遗漏 |
| Rule 4 | Settlement-Aware Withdrawal | ✅ §6.2 有提及 | 无 |
| Rule 5 | Withdrawal Approval Workflow | ✅ §6.4 有提及 | 无 |
| Rule 6 | Ledger Integrity（双分录） | ❌ **未提及** | 中：工程师需确认实现 |
| Rule 7 | Bank Account Encryption | ⚠️ 间接提及（"显示末 4 位"） | 低：UI 层已考虑 |
| Rule 8 | **Idempotency（UUID Key）** | ❌ **未提及** | 中：API 设计可能缺失 |
| Rule 9 | Record Retention（7 年） | ⚠️ 间接提及 | 低：工程承诺 |
| Rule 10 | Error Handling（不沉默失败） | ✅ §10 有部分说明 | 无 |

**最严重的遗漏**：
1. **Travel Rule（>$3000 USD）**：PRD 中完全无踪影。这是 FinCEN 强制要求，发收款方信息必须跨机构传输。如果 PRD 不强调，工程师可能遗漏。
2. **Idempotency（幂等性）**：提交入金/出金申请时，每笔必须含 UUID key，系统 72 小时内缓存重复请求。如果 PRD 不强调，API 设计时可能漏掉。
3. **Ledger Integrity**：双分录、append-only、sum invariant——这是财务账本的最基础原则，PRD 应该明确承诺实现。

---

## 根本原因分析

资金域在规范化过程中出现了三个错误：

1. **跳过了 Domain PRD 步骤**
   - 正常流程：需求 → Surface PRD（mobile）+ Domain PRD（fund-transfer） → Tech Spec → 实现
   - 实际流程：需求 → Surface PRD（mobile）+ Tech Spec（跳过 Domain PRD）→ 实现

2. **"合规规则"和"业务规则"混淆**
   - `.claude/rules` 是 AI 强制执行的编码标准，是**结果规则**
   - Domain PRD 应该是**业务决策规则**
   - 两者有关系但不同义，目前缺少中间层的 Domain PRD 来连接

3. **跨域接口契约缺失**
   - Trading → Fund、Admin → Fund 的接口契约是什么？
   - 如果 Fund Domain PRD 不存在，契约就无处生根

---

## 解决方案

### ⭐ 推荐方案：创建完整的资金域 Domain PRD

**操作步骤**：

#### Step 1：创建 `services/fund-transfer/docs/prd/fund-transfer-system.md`

内容应包括：

```markdown
# 出入金系统（Fund Transfer System）— Domain PRD

## 一、业务流程（不涉及 UI）

- 入金流程：用户发起 → AML 筛查 → 银行处理 → 账户入账
- 出金流程：用户发起 → 生物确认 → 审批判断 → 银行处理 → 回调处理
- 银行卡绑定：验证申请 → 微存款 → 验证确认 → 冷却期

## 二、业务规则矩阵

### 2.1 同名账户原则
- 禁止向第三方账户入金/出金
- 账户名模糊匹配
- 联名账户特殊处理

### 2.2 可提现金额计算
```
可提现 = 总现金 - 待结算资金(T+1/T+2) - 冻结中的出金 - 保证金
```
- 美股：T+1 结算
- 港股：T+2 结算（Phase 2）

### 2.3 银行卡冷却期
[矩阵]

### 2.4 出金审批规则
- 自动审批：金额 ≤ 日限额，卡绑定 > 3 天，无 AML 标记，风险评分低
- 人工审核：金额 > $50K 或其他条件
- 合规专员：金额 > $200K 或 SAR 触发

## 三、合规承诺

[对标 10 条 Rule，逐条确认实现方式]
```

#### Step 2：重构 Mobile PRD-05

修改 frontmatter：

```yaml
---
type: surface-prd
domain_prd:
  - path: services/fund-transfer/docs/prd/fund-transfer-system.md
    uri: brokerage://fund-transfer/prd/fund-transfer-system
---
```

删除以下章节的**业务逻辑**部分（保留 UI 部分）：
- §6 业务规则 → 改为链接到 Domain PRD，保留"UI 如何展示"的部分
- §9 合规要求 → 改为链接到 Domain PRD

#### Step 3：补全合规规则-PRD 映射

在 Domain PRD 中，为每条 Rule 添加"实现承诺"一节：

```markdown
## 三、合规承诺映射

| Rule # | 规则 | 实现承诺 | 实现代码路径 |
|--------|------|--------|----------|
| Rule 1 | Same-Name Account | § 2.1 同名原则：系统验证账户名匹配，Mobile 无决策权 | services/fund-transfer/internal/bank/verify.go |
| Rule 3 | Travel Rule | § 4 跨机构信息传输：>$3000 时，自动收集发收款方信息并上传对方银行 | services/fund-transfer/internal/compliance/travel-rule.go |
| Rule 6 | Ledger Integrity | § 5 账本完整性：每笔资金移动产生对账分录，append-only + sum invariant | services/fund-transfer/internal/ledger/ |
| Rule 8 | Idempotency | § 6 幂等性：每笔请求含 Idempotency-Key，72 小时缓存 | services/fund-transfer/internal/idempotency/ |
```

---

## 三个方案对比

| 维度 | 方案 A：完整 Domain PRD | 方案 B：合并保持 | 方案 C：轻量补丁 |
|------|------|----------|----------|
| **符合规范** | ✅ 完全符合 | ❌ 违规 | ⚠️ 标注而已 |
| **跨域清晰性** | ✅ 高 | ❌ 低 | ⚠️ 低 |
| **合规可追溯** | ✅ 高 | ⚠️ 中 | ⚠️ 低 |
| **工作量** | ~3-4h | 0 | ~1h |
| **长期收益** | ✅ 高 | ❌ 无 | ⚠️ 低 |

**推荐方案 A**。理由：
1. 出入金是**最高风险业务**（涉及真金和合规）
2. **Domain PRD 不是可选的**，是必需的
3. 工作量合理，优先级 P0
4. SPEC-ORGANIZATION 已明确规范，应该遵循

---

## 需要回复方

- [ ] **product-manager**：
  - 确认是否同意拆分 Mobile PRD-05？Domain PRD 初稿预计何时完成？
  - 确认 Travel Rule、Idempotency、Ledger 三条规则是否需在 Domain PRD 中明确覆盖？

- [ ] **code-reviewer**：
  - Domain PRD 初稿完成后，参与评审确保与 `.claude/rules` 无矛盾
  - 审查合规规则映射表，确认工程实现的承诺清晰

---

## 关联文档

- SPEC-ORGANIZATION § 三条铁律 + § PRD 拆分规范
- `.claude/rules/fund-transfer-compliance.md`（10 条强制规则）
- Mobile PRD-05 v2.1（当前混合状态）

