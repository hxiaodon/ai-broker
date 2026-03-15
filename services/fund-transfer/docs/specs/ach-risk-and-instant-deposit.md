# ACH 入金的垫资风险与即时入金策略

`docs/specs/ach-risk-and-instant-deposit.md`

---

## 1. 问题背景

### 1.1 ACH 为什么存在垫资风险

ACH（Automated Clearing House）是美国主流的银行间批量电子转账网络，由 Nacha 运营。其设计目标是低成本的批量清算，而非实时到账。这一根本设计决定了 ACH 天然携带垫资风险。

**核心时序问题：**

```
Day 0 (T+0)  用户发起入金请求
             └── 券商向 ACH 提交 PPD/WEB 批次（Originator → ODFI → ACH Operator → RDFI）

Day 1 (T+1)  ACH 批次处理完成，RDFI（用户的银行）收到借记请求
             └── 资金从技术上"在途"，但 RDFI 尚未确认用户账户状态

Day 1~2      RDFI 处理时间窗口
             └── RDFI 可以在 T+2 营业日结束（EOD）前发回 Return

Day 2 (T+2)  Return 最晚截止时间（对于大多数 Return Code）
             └── R01 (NSF), R02, R03 等需在 T+2 之前返回

Day 5 (T+5)  特殊 Return 截止时间
             └── R05, R07, R10 (未授权借记) 最长可到 60 个日历日
```

**关键矛盾：** ACH 没有类似信用卡的实时授权机制。券商在 T+0 提交借记请求后，要等到 T+2 才能确认资金是否真正到账。这个 48 小时的不确定窗口就是垫资风险的根源。

**未授权 Return 的长尾风险：**

Nacha 规则允许用户以"未授权（Unauthorized）"为由，在 60 个日历日内发起 Return。这意味着券商理论上需要对每一笔 ACH 入金保持最长 60 天的潜在撤销风险敞口。

### 1.2 保守策略对用户体验的影响

**保守策略**：等待 T+2 银行最终确认后再向用户账户记账。

| 影响维度 | 具体表现 |
|---------|---------|
| 时间成本 | 用户入金后需等待 2~3 个营业日才能交易，错过行情窗口 |
| 竞争劣势 | Robinhood、Webull 等竞争对手均提供即时入金额度 |
| 用户信任 | "钱已经从我账户扣了，为什么还不能交易？"是高频客诉 |
| 转化率 | 新用户首次入金体验差，是流失的关键节点 |
| AUM 损耗 | 资金在 pending 状态期间无法产生交易佣金 |

### 1.3 激进策略的风险敞口

**激进策略**：T+0 立即向用户账户记账，允许全额交易。

**风险矩阵：**

```
风险敞口 = Σ(即时入金额度 × Return Rate)

以典型券商数据估算：
- 平均即时入金请求：$2,000
- ACH Return Rate（全市场均值）：0.5% ~ 1.5%
- 其中 NSF (R01) 占比约 60%
- 恶意欺诈 (R07/R10) 占比约 5%~10%

月入金量 10,000 笔 × $2,000 = $20,000,000
预期 Return 损失 = $20,000,000 × 1% = $200,000/月
```

**恶意利用场景（ACH Float Fraud）：**
1. 欺诈用户在账户余额不足时发起大额入金
2. 利用 T+0 即时额度立即买入股票
3. 股票上涨则卖出套现并发起出金
4. 股票下跌则任由账户被 Return 冲回，损失由券商承担
5. 即使股票被强制平仓，市场波动也可能导致净损失

**系统性风险场景：**
- 市场大幅下跌时，NSF Return 集中爆发（用户资金链断裂）
- 大量账户同时出现负余额
- 强制平仓雪上加霜导致进一步亏损

---

## 2. Return Code 分类处理

### 2.1 Return Code 完整分类表

```
Category A: Permanent Failure (永久性失败)
Category B: Temporary Failure (临时性失败)
Category C: Authorization Failure (授权类失败)
Category D: Administrative (管理类)
```

### 2.2 永久性失败

账户不存在、已关闭或无效，重试无意义，需立即限制并清查。

| Return Code | 描述 | 典型原因 |
|-------------|------|---------|
| R02 | Account Closed | 用户账户已注销 |
| R03 | No Account / Unable to Locate | 账号不存在 |
| R04 | Invalid Account Number | 账号格式错误 |
| R13 | Invalid ACH Routing Number | Routing number 无效 |
| R14 | Representative Payee Deceased | 账户持有人已故 |
| R15 | Beneficiary or Account Holder Deceased | 账户持有人已故 |
| R16 | Account Frozen | 账户被司法/监管冻结 |

**处理动作：**

```go
type PermanentReturnAction struct {
    // 立即冻结用户关联的银行账户绑定
    FreezeBankAccount bool // true

    // 向用户账户发起借记补偿（如已使用即时额度）
    IssueCompensatingDebit bool // true

    // 将银行账户状态标记为 INVALID，需重新绑定验证
    BankAccountStatus string // "INVALID"

    // 冷却期：30天内不允许绑定同一银行账户号码
    RebindCooldownDays int // 30

    // 是否触发 AML 复查（R02/R16 需要）
    TriggerAMLReview bool // depends on code

    // 用户通知级别
    NotificationLevel string // "URGENT"
}
```

**账户影响：**
- 立即暂停该银行账户的所有入出金操作
- 如账户余额因垫资产生负数，限制新建仓（可平仓，不可开仓）
- R16（账户冻结）需上报合规团队，可能涉及 AML 事件

### 2.3 临时性失败

余额不足或技术性失败，可在条件满足后重试，但需谨慎。

| Return Code | 描述 | 最晚 Return 时间 | 可重试 |
|-------------|------|-----------------|--------|
| R01 | Insufficient Funds | T+2 | 是（最多 2 次） |
| R08 | Payment Stopped | T+2 | 否 |
| R09 | Uncollected Funds | T+2 | 是（1 次） |

**处理动作：**

```go
type TemporaryReturnAction struct {
    // R01/R09: 可发起重试，但需判断重试条件
    AllowRetry        bool
    MaxRetryCount     int           // R01: 2次; R09: 1次 (Nacha 规则)
    RetryWaitHours    int           // 等待72小时后重试
    RetryWindowDays   int           // 重试必须在原始 Entry Date + 180天内

    // 即时额度的后续处理
    ReclaimInstantCredit bool // true: 立即收回已给的即时额度

    // 如果重试失败，升级为永久性处理
    EscalateAfterFinalReturn bool // true
}
```

**重试规则（Nacha 合规）：**
- R01 最多重试 **2 次**，且必须附加 `RETRY PYMT` 标识
- 重试不得改变原始金额
- 重试失败后不可再次重试，需通知用户重新发起

**账户影响：**
- 即时额度立即冻结（不可用，但仓位不强制平仓——给用户 24~48 小时自行补充资金）
- 若 72 小时内用户未补充资金且重试仍失败，触发余额修复流程
- R01 连续出现 2 次：将该银行账户加入"高风险"标记，后续入金不享受即时额度

### 2.4 授权类失败

用户声称未授权或撤销授权，是欺诈风险最高的类别。

| Return Code | 描述 | 最晚 Return 时间 | 欺诈风险 |
|-------------|------|-----------------|---------|
| R05 | Unauthorized Debit to Consumer | 60 日历日 | 高 |
| R07 | Authorization Revoked by Customer | 60 日历日 | 中高 |
| R10 | Customer Advises Originator Not Known | 60 日历日 | 极高 |
| R29 | Corporate Customer Advises Not Authorized | 2 营业日 | 高 |

**处理动作：**

```go
type AuthorizationReturnAction struct {
    // 立即冻结账户所有资金操作
    FreezeAllFundOperations bool // true

    // 强制平仓触发条件检查
    TriggerLiquidationCheck bool // true

    // 上报内部欺诈调查
    EscalateToFraudTeam bool // true

    // SAR 考量：R10 几乎必然需要提交 SAR
    ConsiderSARFiling bool // R10: true, R07: case-by-case

    // 保留所有相关记录（无法删除）
    LegalHold bool // true

    // 冷却期：账户所有者 90 天内不可重新绑定任何银行账户
    AccountCooldownDays int // 90

    // 通知合规官员
    NotifyComplianceOfficer bool // true
}
```

**账户影响：**
- 账户进入 `RESTRICTED` 状态，只能平仓不能开仓
- 若因垫资产生负余额，立即启动追偿流程
- R10 视同潜在欺诈，账户进入 `UNDER_REVIEW` 状态，可能要求用户提供额外身份验证
- 合规团队在 5 个工作日内完成人工复查

### 2.5 管理类 Return

不涉及欺诈，通常是系统或流程问题。

| Return Code | 描述 | 处理方式 |
|-------------|------|---------|
| R06 | RDFI Returned Entry per ODFI Request | 系统问题，重新提交 |
| R11 | Check Truncation Entry Return | 技术原因，联系银行 |
| R17 | File Record Edit Criteria | 数据格式错误，修复后重试 |
| R20 | Non-Transaction Account | 账户类型不支持 ACH，提示用户换账户 |

---

## 3. 即时入金分层策略

### 3.1 设计原则

即时入金本质上是券商向用户提供的短期信用额度（类似 margin，但无利息）。分层策略的核心是：**用已知信息量化每个用户的违约概率，将额度与风险匹配**。

```
即时入金额度 = f(账户年龄, 历史 Return 记录, 验证方式, KYC 等级, 行为模式)
```

### 3.2 用户分层定义

```
Tier 0: 新用户 (New User)
  条件: 账户开立 < 30 天 OR 首次入金
  风险特征: 信息最少，Return 概率最高，欺诈风险最高

Tier 1: 普通已验证用户 (Standard Verified)
  条件: 账户开立 ≥ 30 天，完成 KYC Standard，银行账户通过微存款验证
  风险特征: 基础验证完成，历史短，需保守对待

Tier 2: 信用良好老用户 (Established Good Standing)
  条件: 账户开立 ≥ 180 天，完成 ≥ 5 次成功入金，历史 0 次 Return，
        银行账户绑定 ≥ 90 天
  风险特征: 行为历史充分，违约概率低

Tier 3: VIP 用户
  条件: Enhanced KYC + 关系经理维护，或资产 AUM ≥ $100,000
  风险特征: 经过深度 KYC，长期客户，信用最好
```

### 3.3 分层即时入金策略详表

```
┌─────────────────┬──────────────┬─────────────────┬───────────────┬────────────────────┐
│ Tier             │ Instant Limit│ Wait Requirement│ Risk Window   │ Conditions         │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 0 (New)     │ $0           │ T+2 confirmed   │ N/A           │ 无即时额度         │
│                  │              │ (保守策略)       │               │                    │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 0 (New)     │ $500         │ T+0 即时        │ 60 日历日     │ Plaid Instant 验证 │
│ + Plaid Instant  │              │                 │               │ 通过后解锁         │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 1 (Standard)│ $1,000       │ T+0 即时        │ T+2 标准窗口  │ 微存款验证通过     │
│                  │              │                 │               │ KYC Standard 完成  │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 1           │ $2,500       │ T+0 即时        │ T+2 标准窗口  │ Plaid Instant 验证 │
│ + Plaid Instant  │              │                 │               │                    │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 2           │ $5,000       │ T+0 即时        │ T+2 标准窗口  │ 自动解锁（满足     │
│ (Established)    │              │ (超额部分 T+2)  │               │ Tier 2 条件）      │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 2           │ $10,000      │ T+0 即时        │ T+2 标准窗口  │ Plaid Instant 验证 │
│ + Plaid Instant  │              │ (超额部分 T+1)  │               │                    │
├─────────────────┼──────────────┼─────────────────┼───────────────┼────────────────────┤
│ Tier 3 (VIP)     │ Custom       │ T+0 即时        │ T+2 标准窗口  │ 关系经理审批       │
│                  │ (≤ $50,000)  │ (全额)          │               │ 或资产门槛自动解锁 │
└─────────────────┴──────────────┴─────────────────┴───────────────┴────────────────────┘
```

**超额部分处理：** 入金金额超出即时额度的部分，进入标准等待流程，T+2 确认后再记账。

### 3.4 即时额度动态调整规则

```go
// 即时额度会因以下事件动态调整（向下）
type InstantLimitAdjustmentEvent struct {
    Event             string
    Action            string
    CooldownPeriod    string
}

var adjustmentRules = []InstantLimitAdjustmentEvent{
    {
        Event:          "First R01 (NSF) Return",
        Action:         "Reduce instant limit by 50%",
        CooldownPeriod: "90 days",
    },
    {
        Event:          "Second R01 Return within 12 months",
        Action:         "Revoke instant limit entirely",
        CooldownPeriod: "180 days",
    },
    {
        Event:          "Any R07/R10 Return",
        Action:         "Revoke instant limit, freeze bank account",
        CooldownPeriod: "365 days",
    },
    {
        Event:          "Fraud investigation triggered",
        Action:         "Revoke instant limit immediately",
        CooldownPeriod: "Until investigation closed",
    },
}
```

---

## 4. 银行账户即时验证

### 4.1 验证通道对比

```
┌──────────────────────┬─────────────────────────────┬──────────────────────────────┐
│ 维度                  │ Plaid Instant Verification  │ Micro-deposit Verification   │
├──────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ 验证时间              │ 即时（秒级，用户授权登录）   │ 1~3 个营业日（等待小额到账） │
│ 用户体验              │ 优（OAuth 登录银行 App）     │ 差（需用户主动查账确认）     │
│ 成功率                │ ~90%（部分小银行不支持）     │ ~99%（几乎所有银行账户）     │
│ 同名验证强度          │ 强（可获取账户持有人姓名）   │ 弱（仅验证账户可达性）       │
│ 成本                  │ Plaid API 费用（约 $1~2/次）│ ACH 手续费（< $0.1/笔）      │
│ 即时额度影响          │ 解锁更高即时入金额度         │ 基础验证，标准额度           │
│ 欺诈防护              │ 强（银行登录验证）           │ 弱（他人账户可能被滥用）     │
│ 监管合规              │ 符合 Nacha WEB Debit 规则    │ 符合标准 KYC 要求            │
└──────────────────────┴─────────────────────────────┴──────────────────────────────┘
```

### 4.2 Plaid Instant Verification 完整流程

```
用户触发绑定银行账户
         │
         ▼
┌─────────────────────┐
│ 1. 初始化 Plaid Link │  后端调用 /link/token/create
│    Token             │  产品类型: ["auth", "identity"]
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 2. 用户在 Plaid SDK  │  用户选择银行 → OAuth 跳转到银行 App
│    中完成授权        │  授权后携带 public_token 回调
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 3. 交换 Access Token │  /item/public_token/exchange
│                      │  获取 access_token（存储加密）
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 4. 获取账户信息      │  /auth/get → 获取 account number + routing number
│    + 持有人身份      │  /identity/get → 获取账户持有人姓名
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 5. 同名验证          │  比对 Plaid 返回姓名 vs KYC 验证姓名
│                      │  模糊匹配（容忍中间名缩写、顺序差异）
│                      │  不匹配 → 拒绝绑定，记录 AML 事件
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 6. 更新银行账户状态  │  verified = true
│                      │  verification_method = "PLAID_INSTANT"
│                      │  instant_limit_tier = "ELEVATED"
│                      │  cooldown_until = NOW() (无冷却期，即时生效)
└─────────────────────┘
```

**关键合规点：**
- Plaid 返回的 account/routing number 必须加密存储（AES-256-GCM）
- access_token 视同银行凭证，独立加密列存储
- Plaid OAuth 必须在券商自己的 OAuth 重定向域内完成（不可跨域转发）

### 4.3 微存款验证（Micro-deposit）标准流程

```
用户输入银行账户号码 + Routing Number
         │
         ▼
┌─────────────────────┐
│ 1. 格式预验证        │  Routing number 校验（ABA checksum）
│                      │  账号格式验证（4~17位数字）
│                      │  Routing number 黑名单检查
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 2. 发送微存款        │  通过 ACH CREDIT 发送 2 笔随机金额
│                      │  金额范围: $0.01 ~ $0.99（各自独立随机）
│                      │  SEC CODE: PPD, 描述: "VERIFY DEPOSIT"
│                      │  同时发起 1 笔 DEBIT 扣回总金额（部分机构）
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 3. 等待用户确认      │  用户在 1~3 营业日后查看银行流水
│                      │  在 App 内输入 2 笔存款金额
│                      │  最多 3 次尝试机会，超过则需重新绑定
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 4. 验证金额          │  误差容忍: 0（必须精确匹配）
│                      │  验证有效期: 10 个营业日
│                      │  超时未验证: 自动作废，需重新绑定
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ 5. 更新状态          │  verified = true
│                      │  verification_method = "MICRO_DEPOSIT"
│                      │  cooldown_until = NOW() + 3 days（标准冷却期）
└─────────────────────┘
```

### 4.4 验证方式对即时入金额度的影响

```go
// 银行账户验证方式与即时额度加成
type VerificationBonus struct {
    Method           string
    BaseMultiplier   float64  // 相对于 Tier 基础额度的倍数
    CooldownOverride string   // 是否覆盖冷却期
}

var verificationBonuses = map[string]VerificationBonus{
    "MICRO_DEPOSIT": {
        Method:           "MICRO_DEPOSIT",
        BaseMultiplier:   1.0,  // 基础额度，无加成
        CooldownOverride: "standard (3 days)",
    },
    "PLAID_INSTANT": {
        Method:           "PLAID_INSTANT",
        BaseMultiplier:   2.5,  // 额度上限提升 2.5x
        CooldownOverride: "none (immediate)",  // 无冷却期
    },
    "PLAID_INSTANT_WITH_IDENTITY": {
        Method:           "PLAID_INSTANT_WITH_IDENTITY",
        BaseMultiplier:   3.0,  // 额度上限提升 3x
        CooldownOverride: "none (immediate)",
    },
}
```

**设计依据：** Plaid 提供的 `/identity/get` 接口可返回账户持有人全名，从而实现更严格的同名验证，欺诈风险更低，因此给予更高额度加成。

---

## 5. Return 发生后的补偿流程

### 5.1 总体补偿流程

```
RDFI 发回 Return Entry
         │
         ▼
┌─────────────────────────┐
│ 1. ODFI / 银行通知到达  │  通过 ACH operator 返回 Return Entry
│                         │  包含: Return Code, Addenda Information
│                         │  我方系统通过银行 API / SFTP 对账文件接收
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ 2. 幂等性去重            │  以 Bank Reference (Trace Number) 为 key
│                         │  防止重复处理同一 Return
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ 3. Return Code 分类路由  │  见第 2 节分类
│                         │  Permanent / Temporary / Authorization
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ 4. 即时额度核查          │  查询该笔 ACH 是否已给予即时额度
│                         │  查询即时额度已使用金额（used_instant_amount）
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ 5. 补偿事务执行          │  见 5.3 节
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ 6. 银行账户状态更新      │  根据 Return Code 更新状态
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ 7. 用户通知              │  Push + Email，附带说明和后续步骤
└─────────────────────────┘
```

### 5.2 用户已用垫资买入股票的场景

这是最复杂的场景，需要分情况处理：

```
Return 发生时，用户使用即时额度的资金状态：

场景 A: 即时额度未使用（或仍为 Cash）
  └── 直接从 available_balance 借记补偿，无仓位影响

场景 B: 即时额度已部分/全部买入股票，持仓中（Position Open）
  ├── B1: 当前持仓市值 ≥ Return 金额 → 可以通过冻结持仓处理
  └── B2: 当前持仓市值 < Return 金额（亏损） → 账户余额为负

场景 C: 即时额度买入的股票已卖出，现金在账户
  └── 直接从 available_balance 借记，同场景 A

场景 D: 即时额度买入的股票已卖出，现金已被提现（出金）
  └── 最严重：账户净资产为负，且资金已离开平台
```

### 5.3 补偿事务设计

```go
// 补偿事务必须满足 ACID，使用数据库事务 + 乐观锁
// 对应台账的双式记账

// Step 1: 在 fund_transfers 表将原 DEPOSIT 标记为 RETURNED
UPDATE fund_transfers
SET status = 'RETURNED',
    return_code = ?,
    return_reason = ?,
    returned_at = NOW()
WHERE transfer_id = ? AND status = 'COMPLETED'

// Step 2: 写入补偿台账分录（Reversing Entry）
INSERT INTO ledger_entries (
    entry_id,
    user_id,
    transfer_id,
    entry_type,
    debit_account,   -- 'user_available_balance'
    credit_account,  -- 'platform_bank_account'
    amount,          -- 原始入金金额（负方向）
    currency,
    balance_after,
    description,
    created_at
) VALUES (?, ?, ?, 'ACH_RETURN', ...)

// Step 3: 更新 account_balances（乐观锁）
UPDATE account_balances
SET available = available - ?,       -- 减去 Return 金额
    version = version + 1
WHERE user_id = ? AND version = ?    -- 乐观锁检查
  AND available - ? >= 0             -- 乐观路径：有足够余额

// 如果 Step 3 中 available < 0，走负余额处理路径（见 5.4）
```

**Saga 补偿事务的失败处理：**

```
补偿事务执行失败时（如数据库超时）：
1. 写入 compensation_failures 表记录失败原因
2. 触发告警（PagerDuty 级别告警）
3. 人工介入，不允许自动重试超过 3 次
4. 每次重试间隔：1min → 5min → 15min（指数退避）
```

### 5.4 账户余额变为负数的场景

```go
// 负余额处理状态机
type NegativeBalanceState string

const (
    // T+0: Return 发生，即时冻结买入能力
    NegativeBalance_Detected    NegativeBalanceState = "DETECTED"

    // T+0 ~ T+1: 宽限期，允许用户自行补充资金或平仓
    NegativeBalance_GracePeriod NegativeBalanceState = "GRACE_PERIOD"

    // T+1 ~ T+2: 系统准备强制平仓
    NegativeBalance_PendingLiquidation NegativeBalanceState = "PENDING_LIQUIDATION"

    // T+2+: 强制平仓执行中
    NegativeBalance_Liquidating NegativeBalanceState = "LIQUIDATING"

    // 平仓后仍为负（市场亏损）
    NegativeBalance_Delinquent  NegativeBalanceState = "DELINQUENT"
)
```

**宽限期政策（Grace Period）：**

```
负余额金额 ≤ $500（小额负余额）:
  宽限期: 3 个营业日
  期间: 限制开仓，允许平仓，不中断出金（以避免资金更进一步流失）
  到期处理: 若未恢复，强制从最流动仓位开始平仓

$500 < 负余额 ≤ $5,000（中额）:
  宽限期: 1 个营业日
  期间: 完全限制开仓和出金，仅允许平仓
  到期处理: 自动强制平仓触发

负余额 > $5,000（大额）:
  宽限期: 0（立即处理）
  立即冻结账户，触发强制平仓
  上报合规团队
```

### 5.5 强制平仓触发条件

```go
// 强制平仓仅在以下条件同时满足时触发（不因小额 Return 轻易清算）
type LiquidationTrigger struct {
    Conditions []string
}

var liquidationTrigger = LiquidationTrigger{
    Conditions: []string{
        "account.net_balance < 0",                   // 账户净余额为负
        "grace_period_expired == true",              // 宽限期已过
        "user_has_not_deposited_to_cover == true",  // 用户未自行补充资金
        "positions_exist == true",                   // 存在可平仓位
    },
}

// 平仓顺序（由流动性高到低）
var liquidationOrder = []string{
    "1. US ETFs (highest liquidity)",
    "2. US Large Cap Stocks (S&P 500 components)",
    "3. US Mid/Small Cap Stocks",
    "4. HK Stocks",
    "5. Unsettled sell proceeds (cannot liquidate, wait settlement)",
}

// 平仓数量计算
// liquidation_amount = abs(negative_balance) + buffer (5%)
// buffer 用于覆盖平仓过程中的市场滑点和佣金
```

**关键合规约束：**
- 强制平仓前必须通过 Push + Email + SMS 三渠道通知用户，留存通知记录
- 通知内容需包含：负余额金额、宽限期截止时间、预计平仓标的和金额
- 强制平仓产生的损益需在审计日志中明确标注来源为 `ACH_RETURN_LIQUIDATION`
- 平仓后若仍有负余额，标记账户为 `DELINQUENT`，启动债务追偿流程（超出本文范围）

### 5.6 用户通知标准

```
通知触发节点               通知渠道           通知内容要素
─────────────────────────────────────────────────────────────────────
Return 发生 T+0            Push + Email      Return Code 含义、涉及金额、
（即时通知）                                  对账户余额的影响
                                              后续步骤说明（补充资金 or 重新入金）

宽限期届满前 24 小时        Push + Email+SMS  剩余宽限时间、
（催告通知）                                  负余额金额、
                                              预计平仓标的（如适用）

宽限期届满，启动平仓         Push + Email+SMS  确认已开始强制平仓、
（平仓通知）                                  平仓标的和数量、预计完成时间

平仓完成                    Push + Email      最终结算后账户状态
                                              余额是否恢复正数
                                              如仍为负数，后续追偿说明
```

---

## 6. 系统设计要点

### 6.1 追踪 ACH 入金的"风险窗口期"

每一笔 ACH 入金都必须携带明确的风险窗口元数据：

```sql
-- 在 fund_transfers 表扩展 ACH 专属字段
ALTER TABLE fund_transfers ADD COLUMN ach_metadata JSON;

-- ach_metadata 结构示例:
{
  "sec_code": "WEB",                      -- Standard Entry Class Code
  "effective_entry_date": "2026-03-16",   -- ACH 批次生效日期
  "standard_return_deadline": "2026-03-18T23:59:59Z",  -- T+2 标准 Return 截止
  "extended_return_deadline": "2026-05-15T23:59:59Z",  -- T+60 授权类 Return 截止
  "instant_amount_granted": "1000.00",    -- 已给予的即时入金额度
  "instant_amount_used": "750.00",        -- 已使用的即时额度
  "risk_window_expires_at": "2026-05-15T23:59:59Z",    -- 风险窗口期结束时间
  "risk_window_status": "OPEN",           -- OPEN / CLOSED / RETURNED
  "nacha_trace_number": "021000021234567", -- 追踪号，用于对账
  "odfi_routing": "021000021"             -- ODFI 路由号
}
```

**风险窗口期状态机：**

```
OPEN ──── 标准 Return 截止（T+2）───► MONITORING
  │                                      │
  │                                      │ 授权类 Return 截止（T+60）
  │                                      ▼
  │                                   CLOSED（风险解除）
  │
  └─── Return 发生 ──────────────────► RETURNED（已补偿）
```

### 6.2 风险窗口期内的资金使用限制

```go
// 资金可用性计算逻辑（核心函数）
type BalanceInfo struct {
    TotalCash             decimal.Decimal  // 账户总现金
    InstantCreditPending  decimal.Decimal  // 风险窗口期内的即时额度（ACH 未确认）
    SettledCash           decimal.Decimal  // 已结算现金（银行确认 + T+1/T+2 交割完成）
    UnsettledProceeds     decimal.Decimal  // 未结算卖出收益
    FrozenBalance         decimal.Decimal  // 冻结余额（出金中 / 交易中）
    MarginRequirement     decimal.Decimal  // 保证金要求（如有）
}

func CalcWithdrawableBalance(b BalanceInfo) decimal.Decimal {
    // 可提现余额：不包含即时额度部分（必须等风险窗口关闭）
    // 不包含未结算收益（必须等 T+1/T+2 结算完成）
    return b.SettledCash.
        Sub(b.InstantCreditPending).  // 减去未确认的即时入金
        Sub(b.FrozenBalance).
        Sub(b.MarginRequirement)
}

func CalcBuyingPower(b BalanceInfo) decimal.Decimal {
    // 买入能力：可以使用即时额度，但不含未结算收益（非 margin 账户）
    return b.TotalCash.
        Sub(b.FrozenBalance).
        Sub(b.MarginRequirement)
}

// 注意: CalcBuyingPower > CalcWithdrawableBalance
// 用户可以用即时额度买股票，但不能提现
```

**UI 层展示建议：**

```
账户余额页面应分拆显示:

总资产估值:        $12,500.00
  ├── 现金余额:    $3,000.00
  │     ├── 可提现:  $1,500.00  ← settled cash only
  │     └── 处理中:  $1,500.00  ← ACH pending (risk window open)
  │           └── 预计可提现: 2026-03-18（T+2 确认后）
  ├── 股票持仓:    $9,200.00
  └── 未结算收益:  $300.00（预计 2026-03-17 结算）
```

### 6.3 Return 补偿事务的详细设计

```go
// Saga 补偿事务：每一步必须幂等
// 使用 return_compensation_id 作为幂等键

type ReturnCompensationSaga struct {
    CompensationID string          // UUID，全局唯一
    TransferID     string          // 原始 ACH 入金 ID
    ReturnCode     string          // ACH Return Code
    ReturnAmount   decimal.Decimal // 实际 Return 金额（通常等于原始金额）
    Steps          []SagaStep
}

// Saga 步骤（必须按序执行，每步幂等）
var sagaSteps = []SagaStep{
    {
        Name:        "LockTransfer",
        Description: "Mark original transfer as RETURN_IN_PROGRESS (optimistic lock)",
        Compensate:  "Unlock to COMPLETED if saga fails before debit",
    },
    {
        Name:        "CheckInstantCreditUsage",
        Description: "Query how much of instant credit was used",
        Compensate:  "N/A (read-only)",
    },
    {
        Name:        "DebitAvailableBalance",
        Description: "Debit user balance with optimistic lock (version check)",
        Compensate:  "Credit back if downstream steps fail",
    },
    {
        Name:        "WriteLedgerEntry",
        Description: "Append ACH_RETURN reversing entry (append-only, idempotent by entry_id)",
        Compensate:  "Write COMPENSATION_REVERSAL entry if needed",
    },
    {
        Name:        "UpdateTransferStatus",
        Description: "Mark transfer as RETURNED with return metadata",
        Compensate:  "N/A (terminal state)",
    },
    {
        Name:        "UpdateBankAccountStatus",
        Description: "Update bank account risk flags based on return code",
        Compensate:  "N/A (async, non-critical path)",
    },
    {
        Name:        "TriggerNegativeBalanceCheck",
        Description: "If balance went negative, initiate grace period workflow",
        Compensate:  "N/A (async workflow)",
    },
    {
        Name:        "SendUserNotification",
        Description: "Send Push + Email notification to user",
        Compensate:  "N/A (idempotent notification service)",
    },
    {
        Name:        "PublishReturnEvent",
        Description: "Publish ACH_RETURN event to Kafka for downstream consumers",
        Compensate:  "N/A (event sourcing, consumers handle idempotency)",
    },
}
```

**事务隔离与并发控制：**

```sql
-- 扣款时使用 SELECT FOR UPDATE + 版本号双重保护
BEGIN;

SELECT available, version
FROM account_balances
WHERE user_id = ? FOR UPDATE;  -- 行级锁防并发

-- 应用层检查 available >= return_amount
-- 如果 available < return_amount，进入负余额处理流程

UPDATE account_balances
SET available = available - ?,
    version = version + 1
WHERE user_id = ?
  AND version = ?;            -- 乐观锁二次确认

INSERT INTO ledger_entries (...);  -- 同一事务内写台账

COMMIT;
```

### 6.4 对账与监控

```go
// ACH Return Rate 实时监控指标
type ACHReturnMetrics struct {
    // 按时间窗口统计 Return Rate
    ReturnRate1h    float64  // 最近 1 小时 Return Rate（预警阈值: 2%）
    ReturnRate24h   float64  // 最近 24 小时 Return Rate（预警阈值: 1.5%）
    ReturnRate7d    float64  // 最近 7 天 Return Rate（预警阈值: 1%）

    // 按 Return Code 分类统计
    NSFReturnCount     int     // R01 发生次数
    FraudReturnCount   int     // R07 + R10 发生次数（高度关注）
    TotalReturnAmount  decimal.Decimal

    // 负余额账户监控
    NegativeBalanceAccounts int  // 当前负余额账户数量（告警阈值: 10）
    TotalNegativeExposure   decimal.Decimal  // 总负余额敞口（告警阈值: $10,000）
}
```

**告警矩阵：**

```
告警级别   触发条件                                 响应动作
────────────────────────────────────────────────────────────────────
P1 (紧急)  单小时 Return Rate > 5%                 立即暂停所有即时入金，人工复查
           负余额总敞口 > $50,000                   通知 CFO + 合规官员
           R10 (Unauthorized) Return > 3笔/小时    触发欺诈调查流程

P2 (严重)  24 小时 Return Rate > 2%               降低所有用户即时入金额度 50%
           单一银行账户 Return >= 2 次             标记银行账户，暂停即时额度
           负余额账户数 > 10                       触发批量宽限期审查

P3 (警告)  7 天 Return Rate > 1%                  Review 即时额度策略
           新用户 Return Rate 异常升高             检查注册欺诈

P4 (信息)  单笔 Return（R01）                     标准流程执行，无需人工介入
```

---

## 附录：关键数据结构扩展

### A. 即时入金记录表

```sql
-- 独立追踪每笔 ACH 的即时额度状态
CREATE TABLE ach_instant_credit_records (
    id                     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    record_id              CHAR(36) UNIQUE NOT NULL,
    transfer_id            CHAR(36) NOT NULL,           -- 关联 fund_transfers
    user_id                BIGINT UNSIGNED NOT NULL,
    instant_amount_granted DECIMAL(20, 2) NOT NULL,     -- 授予的即时额度
    instant_amount_used    DECIMAL(20, 2) NOT NULL DEFAULT 0, -- 已使用的即时额度
    risk_window_status     VARCHAR(16) NOT NULL DEFAULT 'OPEN',
    risk_window_opened_at  TIMESTAMP NOT NULL,
    standard_return_deadline TIMESTAMP NOT NULL,         -- T+2
    extended_return_deadline TIMESTAMP NOT NULL,         -- T+60（授权类）
    risk_window_closed_at  TIMESTAMP NULL,
    return_code            VARCHAR(8) NULL,
    return_received_at     TIMESTAMP NULL,
    compensation_id        CHAR(36) NULL,               -- 补偿 Saga ID
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ach_instant_user (user_id),
    INDEX idx_ach_instant_window (risk_window_status, standard_return_deadline),
    FOREIGN KEY (transfer_id) REFERENCES fund_transfers(transfer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### B. 负余额追踪表

```sql
CREATE TABLE negative_balance_cases (
    id                     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    case_id                CHAR(36) UNIQUE NOT NULL,
    user_id                BIGINT UNSIGNED NOT NULL,
    triggered_by           CHAR(36) NOT NULL,            -- transfer_id (Return)
    negative_amount        DECIMAL(20, 2) NOT NULL,      -- 负余额绝对值
    state                  VARCHAR(32) NOT NULL,         -- 状态机
    grace_period_expires_at TIMESTAMP NOT NULL,
    liquidation_triggered_at TIMESTAMP NULL,
    recovered_at           TIMESTAMP NULL,               -- 余额恢复正数时间
    resolution             VARCHAR(32) NULL,             -- 'USER_DEPOSITED' / 'LIQUIDATED' / 'WRITTEN_OFF'
    created_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_neg_balance_user (user_id),
    INDEX idx_neg_balance_state (state, grace_period_expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

*文档版本：v1.0 | 日期：2026-03-15 | 作者：Fund Transfer Engineering*
*适用范围：US 市场 ACH 入金（PPD/WEB） | 不适用于 Wire、FPS、SWIFT*