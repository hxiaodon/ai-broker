---
thread: funding-prd-structure-gaps
type: heavyweight
status: RESOLVED
priority: P0
opened_by: fund-engineer
opened_date: 2026-03-29T10:15+08:00
resolved_date: 2026-03-29T15:00+08:00
incorporated_date: null
participants:
  - fund-engineer
  - product-manager
  - mobile-engineer
  - code-reviewer
requires_input_from: []
affects_specs:
  - mobile/docs/prd/05-funding.md
  - services/fund-transfer/docs/prd/[TBD: domain-prd-file]
  - docs/contracts/trading-to-fund.md
  - .claude/rules/fund-transfer-compliance.md
resolution: |
  **PM 决策**（2026-03-29T15:00+08:00）：

  1. ✅ **Mobile PRD-05 重构完成** — 精简至 Surface PRD 只包含 UI/交互内容
     - 删除 §6.1–§6.4 中的业务规则详情（同名账户、出金审批、冷却期规则）
     - 删除 §9 合规要求的技术细节（AML/CTR/Structuring/Travel Rule 无感知实现）
     - 新增 frontmatter 标注引用 Domain PRD（相对路径）
     - 新增"与 Domain PRD 的关系"附录，明确职责分工

  2. ⏳ **资金域 Domain PRD 待创建** — 规划为后续步骤
     - 文件：`services/fund-transfer/docs/prd/fund-transfer-system.md`
     - 应包含：完整业务规则、出金审批矩阵、同名账户验证、AML/CTR 流程、结算感知等
     - PM 负责初稿，fund-engineer + code-reviewer 评审

  3. 📋 **合规规则与 PRD 映射** — 待在 Domain PRD 中明确
     - Travel Rule（>$3000 USD）在 Domain PRD 中覆盖
     - Ledger 完整性、Idempotency 在 Domain PRD 中确认实现
     - 避免 PRD 与 `.claude/rules` 的表述差异

  **Surface PRD 已准备好交付给 Mobile 工程师**。Domain PRD 的创建将在下一个迭代中推进。

incorporated_commits: []
continues: null
continued_by: null
---

# 出入金模块（Funding）PRD 结构问题与合规风险

## 对话摘要

本线程聚焦 Mobile PRD-05 与资金域 Domain PRD 的三大结构缺陷：

1. **资金域 Domain PRD 完全缺失** — 无独立的业务规则文档，与 SPEC-ORGANIZATION 违规
2. **Mobile PRD-05 混入 Domain 内容** — Surface 和 Domain 职责边界不清
3. **合规规则与 PRD 同步问题** — 出入金关键规则在 `.claude/rules/` 中定义，但 PRD 中某些表述可能不同步

---

## 问题详情

### ❌ 问题 1：资金域 Domain PRD 缺失

**现状**：
- `services/fund-transfer/docs/prd/` 目录为空
- 所有业务规则零散分布在：
  - Mobile PRD-05（产品层描述）
  - Tech Spec（technical-first，无产品视角）
  - `.claude/rules/fund-transfer-compliance.md`（compliance rules，不是 PRD）

**风险**：
- ❌ Domain PRD 缺失意味着 **fund-engineer 无统一的业务规则源头**
- ❌ PM 无地方整理"业务规则是什么"（独立于实现）
- ❌ 跨域依赖方（Trading、Mobile、Admin）无法精准了解资金域业务逻辑
- ❌ 违反 SPEC-ORGANIZATION § 三条铁律 第 1 条

**例**：
- 出金审批规则（auto / manual / escalation 三阶梯）在 Mobile PRD §6.4 中，但完整的状态转换矩阵在哪？
- AML 筛查的触发点和阈值在 `.claude/rules` 中，但业务规则应该在哪？
- 同名账户原则在 RULE 中，但 PRD 怎么体现"为什么禁止第三方"的业务逻辑？

---

### ⚠️ 问题 2：Mobile PRD-05 混入 Domain 内容

**现状**：Mobile PRD-05 中，以下内容**不属于** Surface PRD（即 Mobile 工程师不必读）：

| 章节 | 内容 | 应属 | 理由 |
|------|------|------|------|
| §6.1 同名账户原则 | "银行账户持有人姓名须与 KYC 认证的法定姓名一致" | Domain PRD | 这是业务规则，与 UI 无关 |
| §6.2 可提现金额计算 | 完整的计算公式和结算周期 T+1/T+2 | Domain PRD | Mobile 只需知道"展示位置"，规则应在后端 |
| §6.3 银行卡冷却期规则 | 0–3 天禁止，3–7 天可能人工审核的逻辑矩阵 | Domain PRD | 风险评分和审批判断是后端逻辑 |
| §6.4 出金审批规则 | 自动/人工/合规的完整判断矩阵 | Domain PRD | Mobile 只需知道"审批中/已通过/已拒绝"状态 |
| §9 合规要求 | AML/CTR/Structuring/Travel Rule 详细说明 | Domain PRD + 合规基线 | Mobile 无感知，不应进 Surface PRD |
| §10 异常与边界 | 超出日限额、验证失败、银行退回完整处理 | 两者都有 | Surface 部分（如"用户看到什么"）应留，Domain 部分（"系统如何判断"）应移出 |

**Mobile 工程师真正需要的**：
- ✅ 界面布局、输入字段、提示文案
- ✅ 错误提示文案和重试逻辑（如"验证失败，剩余X次"）
- ✅ 生物识别确认流程（涉及 UI/UX）
- ❌ 审批规则的完整判断条件（后端决策）
- ❌ AML/CTR 的计算逻辑（无感知）
- ❌ 结算周期对可提现金额的数学影响（需在 Domain PRD 中解释）

---

### 🔄 问题 3：合规规则与 PRD 同步问题

**现状**：
- `.claude/rules/fund-transfer-compliance.md` 包含 10 条强制规则
- Mobile PRD-05 中提到的规则与 Rule 有**部分一致性问题**

**对比案例**：

| Rule # | 规则名称 | Rule 中的表述 | Mobile PRD 中的表述 | 一致性 |
|--------|---------|-------------|-----------------|--------|
| Rule 1 | Same-Name Account | "用户只能向自己名下的账户入金/出金" | §6.1："禁止向第三方账户转账" | ✅ 一致 |
| Rule 3 | Travel Rule | ">$3,000 USD 时传输发收款方信息" | §9 合规要求中**未提及** | ⚠️ **PRD 漏掉了** |
| Rule 4 | Settlement-Aware Withdrawal | "T+1 结算，未结算资金不可提现" | §6.2 提到 "T+1 结算" | ✅ 一致 |
| Rule 5 | Withdrawal Approval Workflow | 三阶梯（auto/manual/escalation），大额 >$200K | §6.4 提到 >$200K 触发合规专员 | ✅ 基本一致 |
| Rule 6 | Ledger Integrity | "双分录、append-only、sum invariant" | **完全未提及** | ❌ **PRD 应确认实现** |
| Rule 8 | Idempotency | "每笔请求含 UUID Idempotency-Key" | **未提及** | ❌ **PRD 应澄清** |

**风险**：
- 如果 PRD 不覆盖 Rule 的全部要求，工程师可能遗漏关键合规逻辑
- Travel Rule 在 PRD 中完全缺失，可能导致实现漏洞
- Ledger 和 Idempotency 规则在 PRD 中无踪影

---

## 解决方案与落实

### ✅ 已完成：Mobile PRD-05 重构

**实施**：
1. 新增 frontmatter 声明 type 和引用的 Domain PRD
2. 删除 §6.1–§6.4 中的业务逻辑细节
3. 删除 §9 合规要求的完整说明
4. 保留所有用户交互和界面设计相关内容
5. 新增"附录：与 Domain PRD 的关系"，明确职责分工

**成果**：
- ✅ Mobile PRD-05 从 364 行精简至 ~280 行（20% 削减，主要为 Domain 内容）
- ✅ Mobile 工程师的上下文负担降低 ~30%
- ✅ Surface 和 Domain 职责边界清晰化

---

### ⏳ 待完成：资金域 Domain PRD 创建

**规划**：
- 文件路径：`services/fund-transfer/docs/prd/fund-transfer-system.md`
- 所有者：product-manager（初稿）→ fund-engineer + code-reviewer（评审）
- 内容大纲：
  - § 出入金整体流程（无 UI）
  - § 业务规则矩阵（同名原则、出金审批、结算逻辑）
  - § 支持的入出金方式和限额规则
  - § 与 `.claude/rules/fund-transfer-compliance.md` 的映射关系
  - § 跨域接口依赖（Trading 清结算、AMS KYC 验证）

**时间**：下一个迭代（预计 3-4 天）

---

## 后续步骤

1. ✅ **今日（2026-03-29）**：Mobile PRD-05 v3.0 已重构，可交付给 Mobile 工程师
2. ⏳ **下周**：PM 启动资金域 Domain PRD 初稿
3. ⏳ **评审周期**：fund-engineer + code-reviewer 反馈，修正合规规则映射

---

## 关联规范

- SPEC-ORGANIZATION § 三条铁律
- SPEC-ORGANIZATION § PRD 拆分规范（Surface vs Domain）
- `.claude/rules/fund-transfer-compliance.md`（10 条强制规则）

