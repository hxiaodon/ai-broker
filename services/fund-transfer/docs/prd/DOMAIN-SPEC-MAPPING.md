---
title: Domain PRD vs Tech Specs 关系对标分析
date: 2026-03-29T17:30+08:00
status: ANALYSIS
---

# 资金域 Domain PRD 与 Tech Specs 关系分析

## 一、整体关系架构

```
┌─────────────────────────────────────────────────────────────────┐
│                      Business Requirements                       │
│                   (Mobile PRD-05 Surface)                       │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│           Domain PRD（业务规则源头）★ NEW                       │
│     services/fund-transfer/docs/prd/                            │
│     fund-transfer-system.md (734 行)                            │
│                                                                 │
│ • 业务流程（入出金决策树）                                     │
│ • 业务规则（同名、AML、审批矩阵、结算）                        │
│ • 合规规则完整映射（Rule 1-10）                                │
│ • KYC 限额、出金阶梯、Travel Rule                              │
│ • 成功指标、风险缓解                                           │
│                                                                 │
│ 问: 怎样处理？答案在这里 ✓                                    │
│ 问: 系统为什么这样做？答案在这里 ✓                            │
│ 问: 合规如何承诺？答案在这里 ✓                                │
└──────────────────────┬──────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌────────┐   ┌─────────┐   ┌───────────┐
   │ Tech   │   │ Tech    │   │ Tech      │
   │ Spec 1 │   │ Spec 2  │   │ Spec 3... │
   │        │   │         │   │           │
   │system  │   │custody  │   │ failure   │
   │.md     │   │matching │   │ handling  │
   │        │   │.md      │   │.md        │
   └────────┘   └─────────┘   └───────────┘
        │              │              │
        │ HOW?         │ HOW?         │ HOW?
        │ (实现方案)    │ (入金匹配)   │ (失败补偿)
        ▼              ▼              ▼
   ┌──────────────────────────────────────┐
   │        Implementation Code           │
   │  services/fund-transfer/src/        │
   │  (internal/domain/app/infra)        │
   └──────────────────────────────────────┘
```

---

## 二、文档分层定位

### 第 1 层：Domain PRD（我刚写的）

**所有者**：Product Manager
**维护者**：Fund-Engineer
**主要问题**：
- ❓ **系统应该支持哪些出金审批阶梯？** → 自动/人工/合规三层
- ❓ **出金金额 $50,000 为什么是人工审核阈值？** → KYC Tier 2 日限额 $100K，50K 占 50%，风险等级判断
- ❓ **Travel Rule 什么时候触发？** → $3000 USD 以上

**关键承诺**：
- ✅ "每笔交易都进行 AML 筛查，无例外"
- ✅ "出金自动审批 < 1 分钟，人工审核 1 工作日"
- ✅ "支持同名账户原则、结算感知、双分录"

---

### 第 2 层：Tech Specs（已存在的）

**所有者**：Fund-Engineer
**维护者**：Go Developer
**主要问题**：
- ❓ **出入金状态机怎么设计？** → 见 `fund-transfer-system.md` 状态转移图
- ❓ **AML 筛查怎么调用第三方服务？** → 见各个 spec 的"API 集成"章节
- ❓ **入金匹配的虚拟账户机制是什么？** → 见 `fund-custody-and-matching.md`
- ❓ **失败时怎么补偿？** → 见 `failure-handling-matrix.md`

**关键说明**：
- ✅ 系统架构、数据库设计、状态机
- ✅ 调用链路、错误处理、补偿事务
- ✅ 对账算法、结算推送
- ✅ 边界情况、性能优化

---

## 三、具体的规则对标

### 出金审批规则的映射

#### Domain PRD 中的规则（"应该"）

```
§ 2.4 出金审批规则

自动审批（全部满足）：
- 金额 ≤ 日限额
- 银行卡验证 > 3 天
- 无 AML 标记
- 风险评分 LOW
- 有历史出金记录

→ SLA: < 1 分钟
```

#### Tech Spec 中的实现（"怎么做"）

在 `fund-transfer-system.md` 的 § 4 出金流程中：

```
第 4 步：合规检查（AML、Travel Rule）
第 5 步：审批流程（>$10,000 需人工审批）

决策树伪代码：
if (amount <= daily_limit
    && bank_account.verified_days > 3
    && !user.aml_flags
    && risk_score == LOW
    && user.withdrawal_history_count > 0) {
  return AUTO_APPROVE;
} else {
  return MANUAL_REVIEW;
}
```

**对标结果**：✅ **一致性好** — Domain PRD 定义了规则，Tech Spec 给出了算法框架。

---

### 结算感知提现的映射

#### Domain PRD 中（"业务承诺"）

```
§ 2.2 可提现金额计算

可提现金额 = 总现金余额
           - 待结算资金（未到T+1/T+2）
           - 冻结中的出金申请金额
           - 保证金占用

美股：T+1 结算
港股：T+2 结算（Phase 2）
```

#### Tech Spec 中（"技术实现"）

在 `fund-transfer-system.md` 的 § 5 结算推送中：

```
监听 Trading Engine 的 settlement.completed 事件
在 settlement_date 到达时，自动转移资金从"待结算"→"已结算"
```

**对标结果**：✅ **完整衔接** — Domain PRD 定义了业务规则，Tech Spec 说明了实现方法。

---

### AML 筛查的映射

#### Domain PRD 中（"规则"）

```
§ 2.6 AML 筛查与 CTR 申报

每笔入出金都进行 AML 筛查，无例外
筛查列表：OFAC SDN、Sectoral Sanctions、SFC 指定人员
筛查结果：PASS / REVIEW / BLOCK

CTR 自动申报：
- USD ≥ $10,000
- HKD ≥ HK$120,000
```

#### Tech Specs 中（"实现方案"）

在 `fund-transfer-system.md` 的 § 2.2 系统架构中：

```
Compliance Engine
  - Same-name verification
  - AML screening (OFAC/UN/EU)
  - Travel Rule (>$3000)
  - KYC tier limits
```

在 `operations-and-edge-cases.md` 或其他 spec 中（尚未完全展开）：

```
§ AML 集成
- 调用 AML SaaS 提供商（如 Moov-io、Sanctions Blocks 等）
- 缓存 OFAC 列表（每日更新）
- 筛查 SLA：< 3 秒
```

**对标结果**：⚠️ **部分重叠** — Domain PRD 定义了 AML 的规则和触发条件，Tech Spec 定义了系统架构，但**具体的 API 集成细节和供应商选择可能在其他 spec 中**（如 `references/aml-screening-vendors.md`）。

---

## 四、冲突与重叠分析

### ✅ 完全一致的部分

| 规则 | Domain PRD | Tech Spec | 状态 |
|------|-----------|-----------|------|
| 同名账户原则 | § 2.1 定义规则 | fund-transfer-system.md 提及 | ✅ 一致 |
| 出金审批三阶梯 | § 2.4 完整矩阵 | fund-transfer-system.md 状态机 | ✅ 一致 |
| 结算感知 | § 2.2 公式 | fund-transfer-system.md 流程 | ✅ 一致 |
| 双分录 | § 2.8 详细说明 | fund-transfer-system.md 提及 | ✅ 一致 |
| Travel Rule | § 2.7 触发条件 | fund-transfer-system.md 架构中列出 | ✅ 一致 |

### ⚠️ 部分重叠的部分

**问题区域：出金流程步数**

| 来源 | 说法 | 差异 |
|------|------|------|
| Domain PRD | "出金有 5 层审批（基础校验 → 同名校验 → AML → 审批 → 银行处理）" | 高层、业务导向 |
| Tech Spec（fund-transfer-system.md） | "出金有 8 个步骤（提交 → 余额检查 → 结算检查 → 合规检查 → 审批 → 银行转账 → 确认 → 分录更新）" | 细粒度、实现导向 |

**分析**：
- ❌ **表面冲突**（5 层 vs 8 步）
- ✅ **实际一致**（都包含相同的逻辑节点，只是分组粒度不同）
- 📝 **建议**：在 Domain PRD 中加个脚注："详细的 8 步实现流程见 Tech Spec § 4"

---

### 🟡 当前的空白区（需要补充）

| 话题 | Domain PRD | Tech Spec | 状态 |
|------|-----------|-----------|------|
| **AML 供应商选型** | 定义规则（OFAC/AMLO） | 系统架构中未具体说明 | 📋 缺失 |
| **入金匹配机制** | 不涉及（后端细节） | 见 fund-custody-and-matching.md | ✅ 独立 |
| **失败补偿事务** | 高层说明（§ 4.3） | 见 failure-handling-matrix.md | ✅ 独立 |
| **跨境 FX 换汇** | 仅提及（Phase 2） | 见 fx-conversion-flow.md | ✅ 独立 |
| **节假日处理** | 不涉及 | 见 operations-and-edge-cases.md | ✅ 独立 |

---

## 五、关系总结表

```
┌──────────────────────┬──────────────────────┬────────────────┐
│     文档             │      主要职责         │    与 PRD 关系  │
├──────────────────────┼──────────────────────┼────────────────┤
│ fund-transfer-       │ 高层系统架构、      │ ✅ 直接实现    │
│ system.md            │ 入出金状态机、      │    Domain PRD  │
│ (Tech Spec)          │ 流程概览            │                │
├──────────────────────┼──────────────────────┼────────────────┤
│ fund-custody-and-    │ 入金匹配、虚拟账户、│ ✅ 业务细节    │
│ matching.md          │ 悬挂资金机制        │    独立 Spec   │
│ (Tech Spec)          │                      │                │
├──────────────────────┼──────────────────────┼────────────────┤
│ failure-handling-    │ 完整的失败场景矩阵、│ ✅ 补偿逻辑    │
│ matrix.md            │ 补偿事务、状态修复  │    详细 Spec   │
│ (Tech Spec)          │                      │                │
├──────────────────────┼──────────────────────┼────────────────┤
│ operations-and-      │ 节假日、限额、边界  │ ✅ 运维细节    │
│ edge-cases.md        │ 场景、日常操作      │    独立 Spec   │
│ (Tech Spec)          │                      │                │
├──────────────────────┼──────────────────────┼────────────────┤
│ ach-risk-and-        │ ACH 垫资风险、即时  │ ✅ Phase 1/3   │
│ instant-deposit.md   │ 入金分层策略        │    专项 Spec   │
│ (Tech Spec)          │                      │                │
├──────────────────────┼──────────────────────┼────────────────┤
│ fx-conversion-       │ 换汇流程、锁价、    │ ✅ Phase 2     │
│ flow.md              │ 汇率管理、失败补偿  │    专项 Spec   │
│ (Tech Spec)          │                      │                │
└──────────────────────┴──────────────────────┴────────────────┘
```

---

## 六、潜在的冲突点及修复

### 冲突 1：出金流程的粒度描述

**现象**：
- Domain PRD：5 层审批
- Tech Spec：8 步流程

**根因**：
- Domain PRD 按业务决策分组（"业务上什么时候发生什么"）
- Tech Spec 按系统实现分步（"技术上怎么实现"）

**修复建议**：

在 Domain PRD § 2.4 后面加脚注：

```markdown
> **技术实现细节**：出金的 5 层审批在技术实现中展开为 8 个步骤：
> 1. 用户提交请求 → 2. 余额检查 → 3. 结算检查 → 4. AML 筛查（=审批第 3 层）
> → 5. 系统审批决策（=审批第 4 层）→ 6. 提交银行 → 7. 等待银行确认
> → 8. 更新分录和余额。详见 [Tech Spec § 4](../specs/fund-transfer-system.md)。
```

---

### 冲突 2：审批阈值的具体定义

**现象**：
- Domain PRD：金额 > $50,000 USD 触发人工审核
- Tech Spec（fund-transfer-system.md）：金额 > $10,000 需人工审批（这是过时的）

**根因**：
- Domain PRD 是新版本，完整的审批矩阵
- Tech Spec 中某处可能还有旧版本的阈值说明

**修复建议**：

1. 检查 `fund-transfer-system.md` 中关于出金阈值的所有说法
2. 将其对齐为 Domain PRD 中的 $50,000 USD 和 $200,000 USD
3. 在 Tech Spec 中加 TODO 注释：
   ```
   // TODO: 这里需要与 Domain PRD § 2.4 保持一致
   // 当前阈值：自动审批无上限（满足 5 个条件）、人工审核 >$50K、合规专员 >$200K
   ```

---

### 冲突 3：AML 筛查详细规则

**现象**：
- Domain PRD：明确列出 OFAC、Sectoral Sanctions、SFC、AMLO 四个筛查列表
- Tech Spec（fund-transfer-system.md）：只提及 "AML screening (OFAC/UN/EU)"，没有提 SFC/AMLO

**根因**：
- Domain PRD 是金融领域完整的、后补充的规则定义
- Tech Spec 的架构图是早期版本，可能不够完整

**修复建议**：

更新 Tech Spec 的系统架构图：

```
从：
│  │  - AML screening (OFAC/UN/EU)

改为：
│  │  - AML screening
│  │    • OFAC (US)
│  │    • SFC/AMLO (HK)
│  │    • Sanctions Screening
```

---

## 七、推荐的关系维护策略

### 原则

1. **Domain PRD 是业务源头**
   - 定义"什么规则"、"为什么"、"SLA 承诺"
   - 是 Product Manager 和合规方的对话文档
   - 相对稳定，变化少

2. **Tech Spec 是实现详细设计**
   - 定义"怎么实现"、"状态机"、"调用链路"
   - 是 Fund-Engineer 和 Go Developer 的对话文档
   - 会因为技术优化而变化

3. **定期同步检查**
   - 每次 Domain PRD 变更时，检查是否需要更新 Tech Spec
   - 每次 Tech Spec 有重大改架时，检查是否违反了 Domain PRD 的承诺

### 文档交叉引用

**在 Domain PRD 中**：

```markdown
## 技术实现参考

详细的系统架构、失败处理、边界情况处理见以下技术文档：

- [系统架构设计](../specs/fund-transfer-system.md) — 状态机、流程细节
- [入金匹配与托管](../specs/fund-custody-and-matching.md) — 虚拟账户、悬挂资金
- [失败处理矩阵](../specs/failure-handling-matrix.md) — 补偿事务、状态修复
- [运营场景](../specs/operations-and-edge-cases.md) — 节假日、限额、边界情况
```

**在 Tech Spec 中**：

```markdown
## 业务规则源头

本文档的所有出入金规则、审批阈值、合规要求均实现自：

- [出入金系统 Domain PRD](../prd/fund-transfer-system.md)
- [合规规则](../../../.claude/rules/fund-transfer-compliance.md)

如发现本 Spec 与 Domain PRD 的冲突，以 Domain PRD 为准。
```

---

## 八、当前状态评分

| 维度 | 评分 | 说明 |
|------|------|------|
| **逻辑一致性** | 8/10 | 大体方向一致，少数细节需对齐（如阈值） |
| **覆盖完整性** | 7/10 | Domain PRD 完整，Tech Spec 仍有部分空白（AML 供应商、FX 换汇） |
| **交叉引用** | 5/10 | 两份文档目前互相没有明确的交叉引用 |
| **版本同步** | 6/10 | Tech Spec 中某些说法是旧版本（如 $10K 阈值） |

---

## 九、后续行动清单

### 立即（本周）

- [ ] **检查 Tech Spec 中的出金阈值** — 确保 $50K/$200K 与 Domain PRD 一致
- [ ] **补充交叉引用** — 在两份文档中加入对方的链接
- [ ] **标记需要核对的地方** — 用 TODO / FIXME 标记潜在冲突

### 短期（下周）

- [ ] **更新 Tech Spec 的 AML 筛查说明** — 包含 OFAC/SFC/AMLO
- [ ] **补全 AML 供应商选型 Spec** — 从 Domain PRD 的规则 → 到供应商选择
- [ ] **创建 Spec-Code 映射表** — 哪个 Domain PRD 规则对应哪个代码文件

### 中期（Phase 1 交付前）

- [ ] **Code Review 时验证** — Reviewer 检查代码是否违反了 Domain PRD 承诺
- [ ] **集成测试** — 测试场景应该基于 Domain PRD 的规则和 Tech Spec 的边界情况

---

## 总结

**现状**：Domain PRD 和 Tech Specs 大体上是**相容的**，但缺少显式的**交叉引用和细节对齐**。

**风险**：如果开发时只看 Tech Spec，可能会遗漏 Domain PRD 中定义的某些规则（如 Travel Rule、Idempotency）。

**建议**：
1. ✅ 保持当前状态（两份文档逻辑分离）
2. 📝 **加强交叉引用** — 让工程师知道两份文档的关系
3. 🔍 **定期同步检查** — 每次 PRD 或 Spec 变更时对齐
4. 📋 **创建对应表** — Domain PRD 规则 ↔ Tech Spec 章节 ↔ 代码文件

这样可以保证**业务承诺**（Domain PRD）和**技术实现**（Tech Spec）始终对齐。

