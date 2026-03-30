---
type: domain-prd
surface_prd: mobile/docs/prd/05-funding.md
implements:
  - path: mobile/docs/prd/05-funding.md
    uri: brokerage://mobile/prd/05-funding
compliance_rules:
  - path: ../../.claude/rules/fund-transfer-compliance.md
    uri: brokerage://rules/fund-transfer-compliance
tech_specs:
  - path: ../specs/fund-transfer-system.md
  - path: ../specs/fund-custody-and-matching.md
  - path: ../specs/failure-handling-matrix.md
  - path: ../specs/operations-and-edge-cases.md
mappings:
  - path: ../prd/DOMAIN-SPEC-MAPPING.md
revisions:
  - rev: 2
    date: 2026-03-29T18:00+08:00
    author: fund-engineer
    summary: "v2：新增与 Tech Specs 的交叉引用；补全 AML 筛查范围（SFC/AMLO）；明确出金审批阈值（$50K/$200K）"
  - rev: 1
    date: 2026-03-29T16:30+08:00
    author: fund-engineer
    summary: "初始版本：完整的业务规则、出入金流程、审批矩阵、合规规则映射"
status: ACTIVE
---

# 出入金系统（Fund Transfer System）— Domain PRD

> **版本**：v1.0
> **日期**：2026-03-29
> **对应 Surface PRD**：[Mobile PRD-05：出入金模块](../../../mobile/docs/prd/05-funding.md)
> **关联规则**：[`.claude/rules/fund-transfer-compliance.md`](../../.claude/rules/fund-transfer-compliance.md)

---

## 一、业务概述

### 1.1 核心职责

出入金系统负责用户资金在**银行账户与券商托管账户**之间的双向流转，包括：

| 职能 | 说明 |
|------|------|
| **Deposit（入金）** | 用户从自己的银行账户向券商账户入金（ACH/Wire/FPS） |
| **Withdrawal（出金）** | 用户从券商账户向自己的银行账户出金（ACH/Wire/FPS） |
| **Bank Account Management** | 绑定、验证、管理用户的银行账户（最多 5 张） |
| **Compliance & Screening** | AML/KYC 审查、CTR/SAR 申报、Travel Rule 遵守 |
| **Ledger & Accounting** | 双分录账本、余额计算、对账 |
| **Reconciliation** | 实时/每日/每月的三方对账（内部账本 ↔ 银行回单 ↔ 托管行） |

### 1.2 支持的渠道与时间

| 方式 | 币种 | 手续费 | 预计到账 | 上线 |
|------|------|--------|---------|------|
| **ACH 转账** | USD | 免费 | 3-5 工作日 | Phase 1 ✅ |
| **Wire 电汇** | USD | $25/笔 | 当日（工作日 14:00 ET 前） | Phase 1 ✅ |
| **FPS** | HKD | 免费 | 实时/同日 | Phase 2 |
| **CHATS** | HKD | 免费 | 同日 | Phase 2 |

---

## 二、核心业务规则

### 2.1 同名账户原则（Rule 1）

**定义**：用户**只能**向自己名下的银行账户入金或出金。

**规则**：

```
入金账户持有人姓名 ≡ KYC 认证的法定姓名  ✓
出金账户持有人姓名 ≡ KYC 认证的法定姓名  ✓
```

**执行**：

- ✅ 绑卡时：系统自动填充 KYC 姓名，用户只需验证；系统自动进行**模糊匹配**（忽略大小写、标点、前后空格）
- ✅ 出金时：出金账户下拉仅显示**已验证且姓名匹配**的账户
- ❌ 禁止：向第三方账户入金（如配偶、亲戚的账户）
- ✅ 例外：联名账户（Joint Account）中用户是命名持有人时可允许（需法务逐案确认）

**风险处理**：

- 如果绑卡时检测到**姓名不匹配**，系统在验证流程中**阻断**，提示"账户持有人姓名与 KYC 认证不一致"
- 如果出金时用户试图向非自己名下账户出金，系统拒绝，错误码 `WITHDRAWAL_ACCOUNT_MISMATCH`

---

### 2.2 可提现金额计算（Rule 4）

**定义**：在任何时刻，用户的**可提现金额**由以下因素组成：

```
可提现金额 = 总现金余额
           - 待结算资金（未到T+1/T+2）
           - 冻结中的出金申请金额
           - 保证金占用（Phase 1 = 0，后续支持 Margin）
           - Pending Deposits（等待银行确认）
```

**结算周期（与 Trading 系统契约）**：

| 市场 | 资产 | 结算周期 | 实施日期 |
|------|------|---------|---------|
| 美股 | US Stocks | T+1（Settlement Date = Trade Date + 1） | 2024-05-28 起 |
| 港股 | HK Stocks | T+2（Settlement Date = Trade Date + 2） | Phase 2 |

**具体计算逻辑**：

1. **卖出后资金**：
   - 用户卖出 100 股 AAPL，成交价 $150，成交金额 $15,000
   - Trade Date = 2026-03-29（周一）
   - Settlement Date = 2026-03-30（周二）
   - 2026-03-30 00:00 UTC 之前：$15,000 属于**待结算资金**，不可提现
   - 2026-03-30 00:00 UTC 之后：$15,000 变为**已结算现金**，可以提现

2. **现金入金**：
   - 用户通过 ACH 入金 $10,000
   - 银行确认到账后，**立即**可用于交易和出金（不需要等待额外结算）

3. **进行中的出金**：
   - 用户提交出金申请 $5,000，等待审批中
   - 该 $5,000 被**冻结**，不可再次出金或用于交易

**显示规范**（与 Mobile 契约）**：

Mobile 应同时展示：
- ✅ **账户总资产**：现金 + 持仓市值
- ✅ **可用现金**：今天可立即用于交易的金额
- ✅ **待结算资金**：T+1 未到的卖出收益（需注明"明天可提现"）
- ✅ **可提现金额**：可立即出金的金额（= 可用现金 - 冻结出金）

---

### 2.3 银行卡绑定与冷却期（Rule 1 + Rule 5）

**流程**：

```
绑定申请 → 微存款验证（1-3 天） → 验证成功 → 冷却期（3 天） → 可使用
```

**冷却期规则**：

| 绑定天数 | 入金 | 出金 | 说明 |
|---------|------|------|------|
| **0–3 天（冷却期）** | ❌ 禁止 | ❌ 禁止 | 新绑卡，风险等级最高 |
| **3–7 天** | ✅ 允许 | ⚠️ 可能触发人工审核 | 有效期内，但可能要求额外确认 |
| **≥ 7 天** | ✅ 正常 | ✅ 正常 | 充分验证，无额外限制 |

**异常处理**：

- 如果用户在冷却期内试图入金/出金，API 返回错误 `BANK_ACCOUNT_COOLDOWN`，Mobile 显示"请等待 X 天后再试"
- 微存款验证**超时 14 天**未确认：该绑卡作废，需删除后重新绑卡

---

### 2.4 出金审批规则（Rule 5）

**决策树**：

```
用户提交出金申请
  ├─ 【Step 1】基础校验
  │   ├─ 金额 ≤ 0？→ 拒绝（INVALID_AMOUNT）
  │   ├─ 金额 > 可提现金额？→ 拒绝（INSUFFICIENT_BALANCE）
  │   └─ 账户被锁定？→ 拒绝（ACCOUNT_LOCKED）
  │
  ├─ 【Step 2】同名账户校验（Rule 1）
  │   └─ 出金账户 ≠ KYC 名下？→ 拒绝（ACCOUNT_MISMATCH）
  │
  ├─ 【Step 3】AML 筛查（Rule 2）
  │   ├─ 用户/银行在 OFAC SDN 中？→ 拒绝（AML_BLOCKED）
  │   ├─ 返回 REVIEW？→ 进入人工审核
  │   └─ 返回 PASS？→ 继续
  │
  ├─ 【Step 4】审批规则判断（下方矩阵）
  │   ├─ 满足自动审批条件？→ **自动审批**
  │   ├─ 满足人工审核条件？→ **进入人工审核队列**（1 工作日）
  │   └─ 大额出金？→ **合规专员审批**
  │
  └─ 【Step 5】提交至银行处理
      ├─ 银行成功？→ 出金完成，推送通知
      └─ 银行拒绝？→ 退款至账户，通知用户
```

**详细的审批矩阵**：

#### 自动审批（3 个条件**全部满足**）

| 条件 | 说明 | 备注 |
|------|------|------|
| ✅ 金额 ≤ 日限额 | 金额在 KYC Tier 的日限额范围内 | 见下方 KYC 限额表 |
| ✅ 银行卡验证 > 3 天 | 绑卡时间已超过冷却期 | 降低新卡欺诈风险 |
| ✅ 无 AML 标记 | 用户和银行都未被标记为可疑 | AML 结果 = PASS |
| ✅ 风险评分 = LOW | 系统欺诈检测评分为低 | 实时计算，见 Rule 2 |
| ✅ 有历史出金记录 | 用户曾成功出金过至少 1 次 | 防止首次大额出金欺诈 |

**自动审批 SLA**：< 1 分钟

#### 人工审核（满足**任意一个**条件）

| 条件 | 触发阈值 | 处理 |
|------|---------|------|
| 金额过大 | > $50,000 USD 单笔 | 人工审核（1 工作日） |
| 日累计额度 | > 日限额 80% | 人工审核（1 工作日） |
| 冷却期不足 | 3 天 ≤ 绑卡时间 < 7 天 | 人工审核（建议增强验证） |
| 账户新开 | 注册时间 < 30 天 | 人工审核 |
| 风险评分中等 | MEDIUM or HIGH | 人工审核 |
| AML 需人工审查 | AML 返回 REVIEW | 人工审核 |

**人工审核 SLA**：1 个工作日内完成

#### 合规专员审批（需要升级）

| 条件 | 处理 |
|------|------|
| 大额出金 > $200,000 USD | 合规专员审批 |
| 触发 SAR（Suspicious Activity Report） | 合规专员审批 |
| 多次 AML 筛查失败（30 天内 ≥ 3 次） | 合规专员审批 |
| 用户在内部风险名单上 | 合规专员审批 |

**合规审批 SLA**：1-2 个工作日（可能需要与用户沟通）

---

### 2.5 KYC 等级限额

用户的入出金限额取决于 KYC 认证等级。限额由 AMS 系统维护，Fund Transfer 调用 AMS API 获取。

| KYC 等级 | 单笔限额 | 日限额 | 月限额 | 说明 |
|---------|---------|--------|--------|------|
| **Tier 1** | $5,000 | $10,000 | $50,000 | KYC 提交待审核或初级认证 |
| **Tier 2** | $50,000 | $100,000 | $500,000 | 完整 KYC 认证通过 |
| **Tier 3（Phase 2）** | $500,000 | $1,000,000 | $5,000,000 | 高净值用户（需额外审核） |

**实现**：

- 每次入金/出金前，Fund Transfer 调用 AMS：`GetAccountKYCTier(user_id)`
- 比较用户申请金额与 Tier 限额，如超过则拒绝或触发人工审核

---

### 2.6 AML 筛查与 CTR 申报（Rule 2）

**执行时点**：

- 每笔入金或出金都**必须**进行 AML 筛查，**不管金额大小**
- 筛查在 API 层**同步执行**（不异步），超时 SLA = 3 秒

**筛查范围**：

```
筛查对象：
├─ 用户法定姓名
├─ 用户国籍/住所国
├─ 银行名称
├─ 银行国家
└─ SWIFT Code（国际转账时）

筛查列表（美国）：
├─ OFAC SDN（Specially Designated Nationals）
├─ OFAC Sectoral Sanctions（特定国家/行业）
└─ OFAC Non-SDN Consolidated List

筛查列表（港澳）：
├─ SFC 指定人员/实体列表
├─ AMLO Part 4A 指定名单
└─ 联合财智组（JFIU）可疑交易名单
```

**筛查结果**：

| 结果 | 含义 | 处理 |
|------|------|------|
| **PASS** | 无风险，直接通过 | 继续处理 |
| **REVIEW** | 需人工审查（模糊匹配、相似名字等） | 进入人工审核队列（待合规人员确认） |
| **BLOCK** | 确认在黑名单上 | 拒绝交易，即刻通知用户和合规部门 |

**CTR 自动申报（Rule 2）**：

当入金或出金**金额超过 CTR 阈值**时，系统自动生成并提交 CTR：

| 地区 | 阈值 | 管理部门 | 提交时间 |
|------|------|---------|---------|
| **美国** | ≥ $10,000 USD | FinCEN | 交易后 15 个自然日内 |
| **香港** | ≥ HK$120,000 | JFIU | 交易后 10 个工作日内 |

**CTR 内容**：涉及用户身份、银行信息、交易金额、交易类型、交易日期等。

**分拆交易检测（Rule 2）**：

系统自动检测"结构化交易"（Structuring），即用户意图通过多次小额交易来规避 CTR 阈值：

- **检测规则**：同一用户在 7 日内进行 3 笔或更多交易，单笔金额 < CTR 阈值，但**累计金额 > CTR 阈值 + 20%**
- **处理**：
  - 标记账户 ⚠️，记录在案
  - 提交增强型 CTR（包含结构化迹象说明）
  - 如果频繁发生，可能触发 **SAR（Suspicious Activity Report）**，进行专项审查

---

### 2.7 Travel Rule 合规（Rule 3）

**定义**：对于**跨境或金额较大**的转账，金融机构必须传输发款人和收款人信息给对方。

**触发条件**：

```
Transfer Amount > $3,000 USD  或  Transfer Amount > HK$8,000 HKD
```

**必传信息**：

**发款人信息**：
- 姓名（与身份证件一致）
- 账号（最后 4 位）
- 住所地址

**收款人信息**：
- 姓名（银行账户持有人）
- 账号（最后 4 位）
- 住所地址（如可获得）

**实现**：

1. 用户提交出金申请 > $3,000 USD
2. 系统自动收集上述信息
3. 通过 SWIFT/FedNow 等渠道将信息附加到汇款指令中
4. 接收行验证收款人信息，如不符可拒绝接收或返还

**记录保留**（Rule 9）：
- Travel Rule 相关记录保留最少 **5 年**
- 包含：发款人信息、收款人信息、传输日期、传输方式

---

### 2.8 Ledger 完整性（Rule 6）

**原则**：每笔资金移动都必须遵循**双分录（Double-Entry Bookkeeping）**原则。

**基本规则**：

```
每笔交易 → 对账分录（Debit Entry）+ 贷账分录（Credit Entry）

例：用户入金 $1000
┌─────────────────────────────────────────┐
│ Debit Entry:  用户账户 +$1000           │
│ Credit Entry: 银行待清队列 -$1000      │
│ 日期：2026-03-29 14:30 UTC              │
│ Transaction ID：txn_001                 │
└─────────────────────────────────────────┘
```

**账本属性**：

| 属性 | 说明 | 实现 |
|------|------|------|
| **Append-Only** | 分录**永不修改或删除** | INSERT-only 表结构，无 UPDATE 操作 |
| **Immutable** | 历史记录完全追溯 | 所有分录带时间戳、user_id、tx_id |
| **Sum Invariant** | 所有用户余额之和 = 平台托管账户余额 | 每日对账程序验证此不等式 |

**纠错机制**：

如果发现分录有误（如重复计账），**不是修改原分录**，而是生成**反向分录**：

```
原分录（错误）：
Debit:  User A +$1000
Credit: Bank Queue -$1000

反向分录（纠错）：
Debit:  Bank Queue +$1000
Credit: User A -$1000

最终效果：User A 回到原始余额
```

**对账验证**（Rule 6）：

系统每日自动进行三方对账：

```
内部账本（Ledger 表）
    ↓ match ↓
银行回单（Bank Statement）
    ↓ match ↓
托管行报告（Custodian Balance Report）
```

- ✅ 完全匹配 → 放行
- ⚠️ 差异 < $0.01 → 记录待查
- ❌ 差异 ≥ $0.01 → 自动告警，暂停相关账户的出金操作
- ❌ 差异 > $100 → 立即上报合规部门，可能冻结账户

---

## 三、入金流程（Deposit Flow）

### 3.1 入金决策树

```
用户发起入金申请
  │
  ├─ 【Step 1】基础校验
  │   ├─ 金额有效性？
  │   ├─ 金额 ≤ Tier 日限额？
  │   └─ 选中的银行卡已验证且非冷却期？
  │
  ├─ 【Step 2】AML 筛查（同步）
  │   ├─ 用户在黑名单？→ 拒绝
  │   ├─ 银行在黑名单？→ 拒绝
  │   └─ 需人工审查？→ 进入人工队列（继续处理，但标记为待审）
  │
  ├─ 【Step 3】入金额度检查
  │   └─ 单笔金额 ≤ 日限额 ≤ 月限额？→ 继续
  │
  ├─ 【Step 4】微存款验证
  │   └─ 银行卡已验证？→ 继续；否则拒绝
  │
  ├─ 【Step 5】生成入金指令
  │   ├─ 向银行发送 ACH/Wire 指令
  │   ├─ 记录 Bank Reference ID（幂等性标识）
  │   └─ 状态 = PENDING_BANK_CONFIRMATION
  │
  ├─ 【Step 6】等待银行回调
  │   ├─ 银行确认成功？→ 余额立即增加，推送通知
  │   ├─ 银行拒绝？→ 记录拒绝原因，通知用户
  │   └─ 银行超时（5 天）？→ 标记为 TIMEOUT，定期查询状态
  │
  └─ 【Step 7】AML 人工审查（如 Step 2 返回 REVIEW）
      ├─ 合规人员审查 → 确认无风险 → 继续 Step 5
      └─ 合规人员审查 → 确认可疑 → 拒绝，通知用户
```

### 3.2 入金方式与 SLA

| 方式 | 描述 | 费用 | 到账时间 | 使用场景 |
|------|------|------|---------|---------|
| **ACH** | 美国清算所电子转账 | 免费 | 3-5 工作日 | 日常入金，金额不急 |
| **Wire** | 银行电汇（SWIFT） | $25/笔 | 工作日当日（14:00 ET 前） | 大额或紧急入金 |

### 3.3 入金后的资金状态

用户成功入金后，资金流转如下：

```
银行确认 → 托管行账户收到 → Fund Service 记账 → 用户可见
  ↓            ↓                   ↓              ↓
 T            T                  T              T
 (银行处理)  (托管行，1-3 天)   (记账，实时)   (余额+1，立即可用)
```

**关键承诺**：
- ✅ 入金成功率 ≥ 97%（银行确认率）
- ✅ 成功入金后**立即可用**（可交易、可再次出金）
- ✅ 入金过程中，所有失败都会通知用户，可重试

---

## 四、出金流程（Withdrawal Flow）

### 4.1 出金决策树（详细）

见前面 §2.4 出金审批规则 的完整决策树。

### 4.2 出金方式与 SLA

| 方式 | 费用 | 到账时间 | 使用场景 |
|------|------|---------|---------|
| **ACH** | 免费 | 3-5 工作日 | 日常出金 |
| **Wire** | $25/笔 | 工作日当日（14:00 ET 前） | 紧急出金或大额 |

### 4.3 出金被银行退回的处理

**场景**：出金申请已被平台受理并提交至银行，但银行随后将资金退回（如收款账户已关闭、账户信息错误等）。

**完整处理流程**：

```
出金资金汇出至银行
  ↓
  ├─ 银行成功入账 → 出金完成，推送通知
  └─ 银行拒绝处理，退回资金（3-5 个工作日）
      ├─ 资金返还至证券账户
      ├─ 账户余额**立即恢复**
      ├─ 系统推送退款通知
      ├─ App 展示退回原因（银行提供）
      └─ 根据退回原因引导用户
          ├─ 账户信息错误 → 引导检查和修正
          ├─ 账户已关闭 → 引导删除失效卡，重新绑定
          └─ 其他银行原因 → 建议联系客服或收款银行
```

**关键承诺**：
- ✅ 退款到账后**立即可用**
- ✅ 用户可立即重新出金或交易
- ✅ 完整的退款原因说明

---

## 五、合规规则完整映射

本节对标 `.claude/rules/fund-transfer-compliance.md` 中的 10 条强制规则，逐条说明在 Domain PRD 中的对应内容和实现承诺。

### Rule 1：同名账户原则（Same-Name Account Principle）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 2.1 同名账户原则 |
| **业务承诺** | 绑卡和出金时强制执行同名校验；禁止第三方转账 |
| **实现主体** | Bank Account Binding（绑卡）+ Withdrawal Engine（出金） |
| **验证模式** | 模糊匹配（fuzzy matching），允许大小写、标点、空格差异 |
| **用户感知** | 绑卡时界面自动填充 KYC 姓名，不可修改 |

### Rule 2：AML 筛查强制（AML Screening is Mandatory）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 2.6 AML 筛查与 CTR 申报 |
| **业务承诺** | 每笔交易都进行 AML 筛查，无例外；筛查范围覆盖 OFAC/AMLO |
| **筛查清单** | OFAC SDN、Sectoral Sanctions、SFC 指定人员、AMLO Part 4A |
| **实现主体** | Compliance Engine（AML 筛查子系统） |
| **SLA** | 筛查响应 < 3 秒；OFAC 列表每日更新 |
| **用户感知** | 无（后台自动）；如被阻止会收到拒绝通知 |

### Rule 3：Travel Rule 合规（Travel Rule Compliance）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 2.7 Travel Rule 合规 |
| **业务承诺** | 转账金额 > $3000 USD / HK$8000 时，传输发收款方信息 |
| **信息范围** | 发款人和收款人的姓名、账号（末 4 位）、住所地址 |
| **实现主体** | Withdrawal Engine（出金时自动收集和传输） |
| **记录保留** | 最少 5 年 |
| **用户感知** | 无（后台自动）；信息通过 SWIFT/FedNow 加密传输 |

### Rule 4：结算感知提现（Settlement-Aware Withdrawals）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 2.2 可提现金额计算 |
| **业务承诺** | 未结算资金不可提现；T+1（美股）/ T+2（港股）后自动可用 |
| **计算公式** | 可提现 = 总现金 - 待结算 - 冻结出金 - 保证金 |
| **实现主体** | Ledger Engine（结算日期追踪）+ Balance Service（实时计算） |
| **用户感知** | 界面展示"待结算"和"可提现"两个数字；解释 T+1/T+2 规则 |

### Rule 5：出金审批工作流（Withdrawal Approval Workflow）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 2.4 出金审批规则 |
| **业务承诺** | 三阶梯审批（自动 / 人工 / 合规专员）；SLA 保证 |
| **自动审批 SLA** | < 1 分钟 |
| **人工审核 SLA** | 1 个工作日内 |
| **合规审批 SLA** | 1-2 个工作日 |
| **实现主体** | Withdrawal Engine（决策树）+ Manual Review Queue（人工队列） |

### Rule 6：账本完整性（Ledger Integrity）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 2.8 Ledger 完整性 |
| **业务承诺** | 双分录、append-only、sum invariant；日对账验证 |
| **实现主体** | Ledger Engine（不可变账本）+ Reconciliation Engine（对账） |
| **数据库设计** | ledger_entries 表 INSERT-only，无 UPDATE；带完整索引用于日对账 |
| **对账 SLA** | 每日 00:00 UTC 前完成前一日的三方对账；差异 ≥ $0.01 立即告警 |

### Rule 7：银行账户安全（Bank Account Security）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | Mobile PRD-05 § 5.3（显示）+ Tech Spec（加密实现） |
| **业务承诺** | 账号加密（AES-256-GCM），UI 仅显示末 4 位 |
| **实现主体** | Bank Account Repository（加密存储）+ Mobile Client（脱敏显示） |
| **账户限额** | 每用户最多 5 张绑卡 |
| **账户变更** | 修改绑卡需生物识别或 2FA 二次确认 |

### Rule 8：幂等性（Idempotency for Fund Operations）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 4.1 入金流程 / § 4.2 出金流程（隐含） |
| **业务承诺** | 每笔请求含 UUID Idempotency-Key；系统 72 小时缓存 |
| **实现主体** | API Gateway（请求签名验证）+ Request Cache（Redis，72 小时 TTL） |
| **重复处理** | 重复请求返回首次响应（缓存命中）|
| **用户体验** | 网络超时时，用户可安全重试（携带相同 Idempotency-Key） |

### Rule 9：记录保留（Record Retention）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | 隐含于整个流程（无 UI，后台合规） |
| **保留期限** | 入出金记录 7 年；AML 结果 7 年；CTR/SAR 5 年 |
| **存储位置** | MySQL 主库 + S3 冷存储（WORM 模式） |
| **实现主体** | Data Retention Service（自动归档）+ Audit Logging |
| **查询支持** | 合规部门可查询任意历史交易记录（7 年内） |

### Rule 10：错误处理（Error Handling for Fund Operations）

| 维度 | 说明 |
|------|------|
| **PRD 位置** | § 4.3 出金被银行退回的处理 + Mobile PRD-05 § 10 异常边界 |
| **业务承诺** | 不沉默失败；每个失败都通知用户；补偿交易机制 |
| **Bank Reversal** | 银行退回 → 余额立即恢复 → 推送通知 → 引导用户处理 |
| **Insufficient Balance on Reversal** | 退款时余额不足 → 标记账户风险 → 限制交易 → 通知合规 |
| **Bank Timeout** | 不假设成功/失败，标记 PENDING → 定期查询 → 以银行回单为准 |
| **Duplicate Callbacks** | 检测银行重复回调（Bank Reference ID 去重）→ 忽略 |

---

## 六、KYC/AMS 依赖契约

Fund Transfer 依赖 AMS 系统提供的两个关键接口：

```
RPC: AMS.GetAccountKYCTier(user_id) → {tier, daily_limit, monthly_limit}
RPC: AMS.VerifySameName(user_id, bank_account_holder_name) → {match: boolean}
```

**承诺**：

- ✅ Fund Transfer 在每次入出金前调用上述接口进行验证
- ✅ 如果 KYC Tier 不存在，出金拒绝（错误码 `KYC_VERIFICATION_FAILED`）
- ✅ 如果同名校验失败，出金拒绝（错误码 `ACCOUNT_MISMATCH`）

---

## 七、与 Trading 系统的清结算契约

Fund Transfer 依赖 Trading Engine 推送**结算事件**：

```
Topic: settlement.completed
Payload: {
  user_id: string
  symbol: string
  quantity: number
  trade_amount: decimal(19,4)
  settlement_date: date
  currency: string  // "USD" | "HKD"
}
```

**承诺**：

- ✅ 实时监听 settlement.completed 事件
- ✅ 在 settlement_date 到达时，自动将资金从"待结算"转为"已结算"
- ✅ 更新用户的可提现金额

---

## 八、与 Admin Panel 的依赖

Admin Panel 需要查看和管理以下内容：

| 功能 | 说明 |
|------|------|
| **出金审批队列** | 显示待人工审核的出金申请；合规人员可批准/拒绝 |
| **AML 异常列表** | 显示 AML 返回 REVIEW 或 BLOCK 的用户/交易 |
| **对账报告** | 每日/每月的三方对账结果；显示差异项 |
| **交易日志** | 完整的入出金历史；可按用户/日期/金额筛选 |
| **SAR 申报** | 可疑交易申报管理；记录申报时间和结果 |

**API Contract**：见 `docs/contracts/admin-to-fund.md`（待创建）

---

## 九、Phase 规划

### Phase 1（当前 / Q1 2026）

✅ **已完成**：
- USD 入金（ACH/Wire）
- USD 出金（ACH/Wire）
- 银行卡绑定与微存款验证
- 出金审批（三阶梯）
- AML 筛查（OFAC）
- 基础对账（日对账）
- Ledger（双分录）

⏳ **进行中**：
- 实时对账系统
- Admin Panel 集成

### Phase 2（Q2-Q3 2026）

📋 **规划中**：
- HKD 入出金（FPS/CHATS）
- 跨境转账（HK → US）
- FX 换汇（CNY → USD）
- Plaid 快捷银行验证
- Margin 保证金支持

### Phase 3（Q4 2026 及以后）

🔮 **未来**：
- 即时入金（平台垫资）
- Auto FX Hedging
- 多币种余额管理

---

## 十、成功指标

| 指标 | 目标 | 衡量方式 |
|------|------|---------|
| **首次入金完成率** | 开户后 7 天内完成 ≥ 60% | 用户路径分析 |
| **入金成功率** | 银行确认 ≥ 97% | 银行回执统计 |
| **绑卡完成率** | 开始绑卡 → 验证成功 ≥ 75% | 漏斗分析 |
| **出金 SLA 达标** | 自动审批出金 1 工作日内完成 ≥ 99% | 出金时效统计 |
| **出金申诉率** | 用户因出金问题联系客服 ≤ 2% | 客服工单分类 |
| **AML 误杀率** | PASS/BLOCK 的准确度 ≥ 99% | 对账报告 |

---

## 十一、主要风险与缓解

| 风险 | 级别 | 缓解方案 |
|------|------|---------|
| 银行 API 超时/故障 | 高 | 实现重试机制、回路断路器、降级方案（标记为 PENDING，定期查询） |
| 同名校验的模糊度 | 中 | 使用业界标准模糊匹配库（如 Levenshtein 距离）；异常情况需人工审查 |
| AML 列表更新延迟 | 中 | 日更新 OFAC 列表；更新前的 6 小时内有交易需再次筛查 |
| 对账差异无法解释 | 高 | 实时增强对账（时间粒度从日改为小时）；自动化查询银行回单 |
| 恶意分拆交易 | 中 | 实时检测结构化交易；多次触发 → SAR 申报 → 冻结账户 |

---

## 十二、后续技术设计

本 Domain PRD 定义了业务规则和承诺。实现细节（数据库设计、算法、API 签名等）在技术 Spec 中定义：

- `services/fund-transfer/docs/specs/fund-transfer-system.md` — 系统架构设计
- `services/fund-transfer/docs/specs/fund-custody-and-matching.md` — 托管架构与入金匹配
- `services/fund-transfer/docs/specs/ach-risk-and-instant-deposit.md` — ACH 垫资风险与即时入金
- `services/fund-transfer/docs/specs/failure-handling-matrix.md` — 完整失败处理矩阵
- `services/fund-transfer/docs/specs/operations-and-edge-cases.md` — 边界场景与日常运维

---

**本文档最后审视日期**：2026-03-29
**维护者**：Fund Transfer 工程团队
