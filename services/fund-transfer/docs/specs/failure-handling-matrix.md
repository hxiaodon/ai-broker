# 出入金失败处理矩阵

## 文档信息

| 项目 | 内容 |
|------|------|
| 文档路径 | `docs/specs/failure-handling-matrix.md` |
| 适用服务 | Fund Transfer Service |
| 版本 | v1.0 |
| 日期 | 2026-03-15 |
| 监管基准 | SEC 17a-4 / FinCEN BSA / AMLO (HK) |

---

## 一、设计原则

在进入具体矩阵之前，必须理解贯穿所有失败处理的三条铁律：

**原则 1：银行超时时绝对不能假设成功或失败。**
收不到银行回调，唯一合法状态是 `PENDING_BANK_CONFIRM`。系统必须通过 EOD 对账或主动查询来最终确认，任何在超时后自动推进状态的逻辑都是严重缺陷。

**原则 2：双向安全，两个方向都不能错。**
不能因为失败场景设计不当而给用户多入账（资金损失），也不能因补偿事务不完整而错误扣用户余额（用户投诉 + 监管风险）。每一步状态扭转必须是原子的，且通过数据库事务 + 幂等键双重保证。

**原则 3：每次状态修复都必须写 ledger 分录。**
禁止通过直接修改 `account_balances` 来修复异常，所有余额变化必须经由 ledger 条目驱动，否则 3-way reconciliation 将永久失衡。若是修复性操作，entry_type 用 `REVERSAL` 或 `ADJUSTMENT`，并关联原始 `transfer_id`。

---

## 二、失败场景总览

```
出入金失败
├── A. 入金失败
│   ├── A1. 提交时立即失败（银行同步拒绝）
│   ├── A2. 异步失败（银行回调 FAILED）
│   ├── A3. ACH Return（T+2 退款）
│   ├── A4. Wire Reversal（银行主动撤回）
│   └── A5. 提交/回调超时（状态不确定）
│
├── B. 出金失败
│   ├── B1. 提交时立即失败（银行同步拒绝）
│   ├── B2. 异步失败（银行回调 FAILED）
│   ├── B3. 出金后银行发起 Reversal Request
│   ├── B4. 目标账户已关闭/无效
│   └── B5. 提交/回调超时（状态不确定）
│
└── C. 系统内部失败
    ├── C1. AML 阻断
    ├── C2. 入金时余额验证异常
    ├── C3. 人工审批拒绝（出金）
    ├── C4. 幂等冲突
    └── C5. 下游服务不可用（AMS/Trading）
```

---

## 三、入金失败矩阵

### 状态前提说明

入金流程的关键节点是"账户是否已入账"。在银行确认 `COMPLETED` 之前，系统不应向用户账户计入任何余额，因此多数入金失败场景中，用户余额无需回滚，处理相对简单。危险场景是 ACH Return：银行先确认成功，系统已入账，数日后 Return 导致需要逆冲。

### A1. 提交时立即失败（银行同步拒绝）

| 属性 | 详情 |
|------|------|
| 失败时机 | 调用银行 API 时同步返回错误（HTTP 4xx/5xx，或银行业务错误码） |
| 用户余额状态 | 未入账，无需操作 |
| 触发渠道 | ACH、Wire、FPS、SWIFT |

**系统动作序列：**

```
1. Transfer status: INITIATED → FAILED
2. failure_reason 写入银行返回的错误码和描述
3. 无需写 ledger 分录（从未入账）
4. 释放 idempotency_key（允许用户用新 key 重试）
5. 发送失败通知（Push + Email）
6. 若错误类型为 INVALID_ACCOUNT，标记关联 bank_account.verified = false
```

**风控升级触发条件：**
- 同一用户在 24 小时内连续 3 次同步失败 → 触发风控人工审查
- 失败原因为 ACCOUNT_FROZEN 或 BENEFICIARY_BLACKLISTED → 立即升级至合规官

**用户通知内容：**
```
主题：入金申请失败
内容：您发起的 [金额] [币种] 入金申请未能提交至银行。
原因：[银行错误描述（脱敏后的用户友好文案）]
建议：请检查银行账户状态或联系客服。
时机：失败发生后 60 秒内
```

---

### A2. 异步失败（银行回调 FAILED）

| 属性 | 详情 |
|------|------|
| 失败时机 | 银行通过 Webhook 回调通知最终失败 |
| 用户余额状态 | 未入账（系统等待回调才入账），无需操作 |
| 触发渠道 | ACH、FPS、SWIFT |

**系统动作序列：**

```
1. 验证回调签名（HMAC-SHA256）
2. 验证 bank_reference 与内部记录匹配（防重放）
3. Transfer status: PROCESSING → FAILED
4. 无需写 ledger 分录
5. 写 audit_log：event=DEPOSIT_FAILED, actor=BANK_CALLBACK
6. 发送失败通知
```

**回调幂等处理：**

```go
// 银行可能重发回调，必须做幂等处理
func HandleBankCallback(ref string, status BankStatus) error {
    transfer, err := repo.GetByBankReference(ref)
    if err != nil {
        return fmt.Errorf("get transfer by bank ref %s: %w", ref, err)
    }

    // 幂等：若状态已是终态，直接返回 200 告知银行已收到
    if transfer.Status.IsTerminal() {
        log.Info("duplicate callback received, already in terminal state",
            "bank_ref", ref, "current_status", transfer.Status)
        return nil
    }

    // 状态机校验：只允许合法的状态转换
    if err := transfer.FSM.Transition(EventBankFailed); err != nil {
        return fmt.Errorf("invalid state transition for transfer %s: %w",
            transfer.TransferID, err)
    }

    return repo.SaveWithAudit(transfer)
}
```

---

### A3. ACH Return（T+2 退款）— 高危场景

ACH Return 是入金失败中最危险的场景：银行在 T+0 确认了入金，系统已为用户入账，用户可能已用这笔钱买入股票，而在 T+2 前后（最长 60 个自然日，视 Return Code 而定）银行发起 Return，要求归还资金。

**ACH Return Code 分类与处理差异：**

| Return Code | 含义 | 处理策略 | 风控升级 |
|-------------|------|----------|----------|
| R01 | 资金不足 (NSF) | 标准 Return 流程 | 是，记录到用户风险画像 |
| R02 | 账户已关闭 | 标准 Return 流程 + 禁用银行账户 | 是 |
| R07 | 账户持有人主动授权撤销 | 合规介入，可能涉及欺诈 | 立即升级合规官 |
| R08 | 止付 (Stop Payment) | 合规介入 | 立即升级合规官 |
| R10 | 账户持有人未授权 | 最高级别，启动 SAR 评估 | 立即冻结账户 + 合规 |
| R20 | 非交易账户 | 禁用银行账户 | 否 |

**Return 后余额状态机（核心逻辑）：**

```
已入账余额 - Return 金额 = 结果
├── 结果 >= 0：从 available 直接扣回
└── 结果 < 0：账户进入 DEBIT_BALANCE 状态（见第四章补偿事务设计）
```

**系统动作序列（Return 后余额充足）：**

```
BEGIN TRANSACTION

1. Transfer status: COMPLETED → RETURNED
2. 创建 REVERSAL ledger 分录：
   DEBIT   user_available_balance    -[原入金金额]
   CREDIT  platform_bank_account     -[原入金金额]
   entry_type = 'REVERSAL', description = 'ACH Return: [Return Code]'

3. account_balances.available -= return_amount  (version 乐观锁)
4. 写 audit_log：event=ACH_RETURN, return_code=[RXX]
5. 若 bank_account 对应 Return Code 为永久性错误：
   bank_accounts.verified = false

COMMIT

6. 发送 Return 通知（见下方通知模板）
7. 按 Return Code 决定是否触发风控升级
```

**Return 通知内容：**
```
主题：入金被银行退回
内容：您于 [日期] 发起的 [金额] 入金已被您的银行退回（原因：[脱敏后文案]）。
      您的账户余额已相应调整。
      如有疑问，请联系您的开户行或我们的客服。
时机：收到 Return 通知后 30 分钟内
渠道：Push + Email + SMS（因涉及资金）
```

---

### A4. Wire Reversal（银行主动撤回已发入的 Wire）

极少见，通常由发款行或中间行发起（如：合规拦截、错误汇款）。

**系统动作序列：**

```
1. 收到 Wire Reversal 请求（通过银行通知或人工发现）
2. 合规官人工确认 Reversal 合法性
3. 确认后：同 A3 的 Return 处理流程
4. 保存 Reversal 原因和发起方信息（供监管审计）
5. 若 Reversal 原因涉及制裁（Sanctions），立即冻结用户账户
   并向 OFAC/FinCEN 提交 SAR
```

---

### A5. 提交/回调超时（状态不确定）— 最危险场景

**超时分类：**

| 超时类型 | 状态 | 处理策略 |
|----------|------|----------|
| 调用银行 API 超时，无法确认是否提交成功 | `PENDING_BANK_CONFIRM` | 禁止推进，等待对账 |
| 提交成功确认，等待最终 Completed 回调超时 | `PROCESSING` | 按渠道 SLA 定时 poll |
| 已完成回调但 DB 写入失败 | 内部不一致 | 对账发现后修复 |

**超时状态处理流程：**

```
银行 API 调用超时
        │
        ▼
标记 Transfer status = PENDING_BANK_CONFIRM
绝对不写任何余额变动 ledger
        │
        ▼
启动轮询 Job（按渠道 SLA 配置间隔）：
  ACH:   每 2 小时轮询一次，最长等待 T+3
  Wire:  每 30 分钟轮询一次，最长等待 8 小时
  FPS:   每 5 分钟轮询一次，最长等待 2 小时
  SWIFT: 每 4 小时轮询一次，最长等待 T+5
        │
        ├── 查询结果 = SUCCESS → 正常入账流程
        ├── 查询结果 = FAILED  → A2 流程
        └── 超过最大等待时间仍未确认
                    │
                    ▼
            升级为人工处理
            通知运营团队介入
            用户通知：入金处理中，请耐心等待
```

**严禁行为：**

```go
// WRONG: 超时后假设失败并自动关闭
func OnTimeout(transferID string) {
    repo.UpdateStatus(transferID, StatusFailed) // 严禁！
}

// WRONG: 超时后假设成功并入账
func OnTimeout(transferID string) {
    creditUserBalance(transferID) // 严禁！
}

// CORRECT: 超时后只能标记待确认，等待对账
func OnBankAPITimeout(transferID string) error {
    return repo.UpdateStatusWithReason(
        transferID,
        StatusPendingBankConfirm,
        "bank_api_timeout_awaiting_reconciliation",
    )
}
```

---

## 四、出金失败矩阵

### 状态前提说明

出金流程中，资金在提交至银行前已通过 `Hold` 操作冻结（从 `available` 转入 `frozen_withdrawal`）。失败处理的核心是：释放 `frozen_withdrawal` 回 `available`，且这个释放必须通过 ledger 分录，而非直接修改余额字段。

### B1. 提交时立即失败（银行同步拒绝）

| 属性 | 详情 |
|------|------|
| frozen_withdrawal 状态 | 已冻结，需释放 |
| 失败时机 | 调用银行 API 同步返回错误 |

**系统动作序列：**

```
BEGIN TRANSACTION

1. Transfer status: PROCESSING → FAILED
2. 释放 Hold：写 ledger 分录
   DEBIT   user_frozen_balance       -[出金金额]
   CREDIT  user_available_balance    +[出金金额]
   entry_type = 'HOLD_RELEASE', description = 'Withdrawal failed: bank sync reject'

3. account_balances:
   frozen -= amount  (version++)
   available += amount  (version++)

COMMIT

4. 写 audit_log
5. 发送失败通知
```

**重试策略：**

```
同步拒绝原因决定是否允许重试：
├── INVALID_ROUTING_NUMBER     → 禁止重试，提示用户更新银行账户
├── ACCOUNT_CLOSED             → 禁止重试，禁用该银行账户
├── AMOUNT_EXCEEDS_LIMIT       → 允许用户调整金额后重新发起
├── TEMPORARY_BANK_UNAVAILABLE → 系统自动重试（指数退避，最多 3 次）
└── GENERAL_ERROR              → 允许用户重新发起（不自动重试）
```

---

### B2. 异步失败（银行回调 FAILED）

| 属性 | 详情 |
|------|------|
| frozen_withdrawal 状态 | 已冻结，需释放 |
| 失败时机 | 提交后数小时内银行回调失败 |

**系统动作序列：**

```
BEGIN TRANSACTION

1. 验证回调签名
2. Transfer status: PROCESSING → FAILED
3. 释放 Hold（同 B1 中的 ledger 分录）
4. 写 audit_log：event=WITHDRAWAL_FAILED, actor=BANK_CALLBACK

COMMIT

5. 发送通知（资金已退回到账户可用余额）
6. 记录 bank_reference 防止重复处理
```

**Hold 释放的幂等保证：**

```go
func ReleaseWithdrawalHold(ctx context.Context, transferID string) error {
    // 检查是否已经释放过（幂等检查）
    existing, err := ledgerRepo.FindByTransferIDAndType(
        transferID, LedgerTypeHoldRelease,
    )
    if err != nil {
        return fmt.Errorf("check existing hold release for %s: %w", transferID, err)
    }
    if existing != nil {
        // 已释放过，直接返回，不重复操作
        log.Info("hold already released, skipping", "transfer_id", transferID)
        return nil
    }

    transfer, err := transferRepo.GetByID(transferID)
    if err != nil {
        return fmt.Errorf("get transfer %s: %w", transferID, err)
    }

    return db.WithTx(ctx, func(tx *sqlx.Tx) error {
        // 写 ledger
        entry := &LedgerEntry{
            EntryID:       uuid.New().String(),
            UserID:        transfer.UserID,
            TransferID:    transferID,
            EntryType:     LedgerTypeHoldRelease,
            DebitAccount:  AccountUserFrozen,
            CreditAccount: AccountUserAvailable,
            Amount:        transfer.Amount,
            Currency:      transfer.Currency,
        }
        if err := ledgerRepo.InsertTx(tx, entry); err != nil {
            return fmt.Errorf("insert hold release ledger: %w", err)
        }

        // 更新余额（乐观锁）
        if err := balanceRepo.ReleaseFrozenTx(tx, transfer.UserID,
            transfer.Amount, transfer.Currency); err != nil {
            return fmt.Errorf("release frozen balance for user %d: %w",
                transfer.UserID, err)
        }

        return nil
    })
}
```

---

### B3. 出金后银行发起 Reversal Request

出金已发出（`COMPLETED`），但银行因合规拦截或错误要求撤回。这是出金侧最复杂的场景。

**场景分类：**

| 触发原因 | 紧急程度 | 处理主体 |
|----------|----------|----------|
| 银行合规拦截（Sanctions） | 紧急 | 合规官 + 系统 |
| 收款行拒绝入账（账户问题） | 高 | 运营 + 系统 |
| 发款行操作错误 | 中 | 运营 + 系统 |
| 用户主动申请撤回 | 常规 | 客服 + 系统 |

**系统动作序列：**

```
收到 Reversal 请求
        │
        ▼
合规官确认 Reversal 合法 & 金额一致
        │
        ▼
Transfer status: COMPLETED → REVERSAL_PENDING
        │
        ▼
等待银行将资金退回平台账户（可能需要 T+1 ~ T+3）
        │
        ▼
确认资金到账后：

BEGIN TRANSACTION

1. Transfer status: REVERSAL_PENDING → REVERSED
2. 写 ledger 分录（出金已从 available 扣除，现在要返还）：
   DEBIT   platform_bank_account     -[金额]     (资金已退回平台)
   CREDIT  user_available_balance    +[金额]     (返还给用户)
   entry_type = 'REVERSAL'

3. account_balances.available += amount

COMMIT

4. 通知用户：出金已被退回，资金已返还至您的平台账户
5. 若 Reversal 原因涉及 Sanctions：冻结用户账户，发起 SAR
```

**注意：在银行资金实际到账前，不得提前返还用户余额。**

---

### B4. 目标账户已关闭/无效

属于 B1/B2 的子场景，但需要额外处理银行账户状态。

**系统动作序列（在 B1/B2 基础上额外执行）：**

```
1. bank_accounts.verified = false（立即禁用）
2. 通知用户更新绑定的银行账户
3. 若该账户是用户唯一绑定账户：
   - 发送 Email + SMS（多渠道，确保触达）
   - 提示用户绑定新账户才能出金
4. 不允许该账户作为出金目标，直至用户重新验证或绑定新账户
```

---

### B5. 出金提交/回调超时（状态不确定）

出金超时比入金超时更危险，因为资金可能已从平台账户扣出，在途中。

**超时处理规则：**

```
出金 API 调用超时
        │
        ▼
Transfer status = PENDING_BANK_CONFIRM
frozen_withdrawal 保持冻结（不释放，不扣除）
        │
        ▼
启动查询 Job（按渠道 SLA）：

Wire:   每 30 分钟查询，最长等待 8 小时
ACH:    每 2 小时查询，最长等待 T+2
FPS:    每 5 分钟查询，最长等待 2 小时
        │
        ├── 银行确认已提交（PROCESSING）→ 继续等待最终确认
        ├── 银行确认成功（COMPLETED）  → 最终扣款，释放 frozen
        ├── 银行确认失败（FAILED）     → B2 流程，释放 frozen 回 available
        └── 查询超过最大等待时间仍无结果
                    │
                    ▼
            人工介入：运营通过银行后台核实
            用户通知：出金处理延迟，请耐心等待
            绝对不自动释放 frozen（钱可能已经发出去了）
```

**严禁行为：**

```go
// WRONG: 超时后自动释放 frozen，钱可能已经转出
func OnWithdrawalTimeout(transferID string) {
    releaseHold(transferID)     // 严禁！可能导致双倍入账
}

// WRONG: 超时后自动扣款确认，可能银行实际失败
func OnWithdrawalTimeout(transferID string) {
    finalizeDebit(transferID)   // 严禁！银行可能已失败
}
```

---

## 五、系统内部失败矩阵

### C1. AML 阻断

| 属性 | 详情 |
|------|------|
| 触发时机 | 入金/出金提交前的 AML Screening 阶段 |
| 余额影响 | 入金：无影响（未入账）；出金：frozen_withdrawal 需释放 |

**AML 阻断分级处理：**

```
AML Screening 结果
├── PASS     → 继续正常流程
├── REVIEW   → 暂停，等待合规官人工审查（SLA: 4 工作小时）
├── BLOCK    → 立即拒绝 + 冻结账户 + 通知合规官
└── ERROR    → 系统异常，不允许放行，转人工处理
```

**BLOCK 场景系统动作：**

```
1. Transfer status → BLOCKED_AML
2. 出金场景：释放 frozen_withdrawal（写 HOLD_RELEASE ledger）
3. 立即冻结用户账户（account_status = AML_FROZEN）
4. 通知合规官（邮件 + 系统告警）
5. 用户通知：因合规原因，您的操作需要进一步审查（不透露具体 AML 原因）
6. 评估是否需要提交 SAR（可疑活动报告）
7. 禁止用户进行任何出入金操作，直至合规官解除
```

**CTR 自动申报触发：**

```go
const (
    CTRThresholdUSD = decimal.NewFromFloat(10000)
    CTRThresholdHKD = decimal.NewFromFloat(120000)
)

func CheckCTRRequired(amount decimal.Decimal, currency string) bool {
    switch currency {
    case "USD":
        return amount.GreaterThanOrEqual(CTRThresholdUSD)
    case "HKD":
        return amount.GreaterThanOrEqual(CTRThresholdHKD)
    }
    return false
}
```

**Structuring Detection（拆单检测）：**

```
过去 24 小时内，同一用户的入金/出金记录：
条件：sum(amounts) >= CTR_threshold AND 单笔均 < CTR_threshold
      AND count >= 3

触发：
1. 标记所有关联 transfers 为 STRUCTURING_SUSPECTED
2. 阻断当前操作，升级合规官
3. 生成 SAR 草稿
4. 关联的历史成功交易也纳入 SAR 评估范围
```

---

### C2. 入金时余额写入异常（幂等冲突）

**场景：** 银行回调触发余额入账，但 DB 写入失败，银行再次重发回调。

```
首次回调 → DB 写入失败（网络抖动）
        │
        ▼
银行重发回调（或系统重试）
        │
        ▼
幂等检查：bank_reference 已存在？
├── 是：返回 200（已处理），不重复入账
└── 否：正常入账流程
```

**幂等键设计：**

```go
// 入金回调幂等检查：以 bank_reference 作为天然幂等键
func ProcessDepositCallback(bankRef string, amount decimal.Decimal) error {
    // 尝试插入 bank_reference（UNIQUE 约束）
    _, err := db.Exec(`
        INSERT INTO deposit_callback_log (bank_reference, processed_at)
        VALUES (?, NOW())
        ON DUPLICATE KEY UPDATE bank_reference = bank_reference
    `, bankRef)

    if isMySQLDuplicateError(err) {
        // 幂等：已处理过
        return nil
    }
    if err != nil {
        return fmt.Errorf("insert callback log for bank_ref %s: %w", bankRef, err)
    }

    // 首次处理：执行入账
    return creditUserBalance(bankRef, amount)
}
```

---

### C3. 人工审批拒绝（出金）

| 属性 | 详情 |
|------|------|
| 触发条件 | 出金金额大、账户新、风控标记等触发人工审批 |
| frozen_withdrawal 状态 | 已冻结，等待审批期间保持冻结 |

**审批拒绝系统动作：**

```
BEGIN TRANSACTION

1. Transfer status: PENDING_APPROVAL → REJECTED
2. 记录拒绝原因和审批人 ID
3. 释放 Hold：写 HOLD_RELEASE ledger 分录
4. account_balances: frozen -= amount, available += amount

COMMIT

5. 用户通知：出金申请未获批准（说明原因，若合规允许披露）
6. 写 audit_log：event=WITHDRAWAL_REJECTED, approved_by=[operator_id]
```

**审批超时自动升级：**

```
PENDING_APPROVAL 状态 SLA：
├── 普通人工审批：4 工作小时
├── 合规官审批：8 工作小时
└── 超过 SLA 未处理：
    自动升级至上级审批队列
    发送运营告警
    用户通知：申请处理中，预计延迟
```

---

### C4. 幂等冲突（重复提交）

```
收到重复请求（相同 Idempotency-Key）
        │
        ▼
从 Redis/DB 查询原始请求的处理结果
├── 原始请求处理成功 → 返回原始成功响应，不重复执行
├── 原始请求处理失败 → 返回原始失败响应，不重复执行
├── 原始请求处理中   → 返回 202 Accepted，告知客户端等待
└── Idempotency-Key 已过期（> 72h）→ 拒绝，要求使用新 Key
```

---

### C5. 下游服务不可用（AMS/Trading）

```
AMS 不可用（无法查询 KYC 状态）：
→ 拒绝所有出入金请求（KYC 状态必须实时验证）
→ 返回 503 并告知用户系统维护中
→ 不使用缓存的 KYC 结果（过期 KYC 状态可能导致合规风险）

Trading Engine 不可用（无法查询 unsettled balance）：
→ 出金请求：拒绝（无法确认可提现余额）
→ 入金请求：可正常处理（不依赖 Trading 状态）
→ 返回 503 并告知用户系统维护中
```

---

## 六、补偿事务设计

### 6.1 ACH Return 后用户已买股票（负余额场景）

这是全系统最复杂的补偿场景，需要多步协调。

**场景还原：**
```
T+0：用户入金 $10,000 → ACH 初步确认 → 系统入账
T+0：用户用 $9,000 买入 AAPL → 资金冻结至 frozen（T+1 结算）
T+1：AAPL 结算 → $9,000 转入 position_value，available ≈ $1,000
T+2：ACH Return（R01: NSF）→ 需归还 $10,000 给银行
     但用户 available = $1,000，position_value = $9,000
     → 缺口 $9,000 → DEBIT_BALANCE 场景
```

**处理流程：**

```
Step 1: 账户标记
─────────────────
account_status = DEBIT_BALANCE
debit_balance_amount = $9,000（缺口金额）
debit_balance_reason = 'ACH_RETURN_R01'
debit_balance_deadline = NOW() + 5 个工作日

Step 2: 立即限制
─────────────────
- 限制出金（禁止）
- 限制新买入（禁止）
- 允许卖出（鼓励用户主动补足）

Step 3: Ledger 处理
────────────────────
将 available 全额回收（仅能回收 $1,000）：
DEBIT  user_available_balance  -$1,000
CREDIT platform_bank_account   +$1,000

剩余缺口 $9,000 记入负债科目：
DEBIT  user_debit_balance      +$9,000    (负债，需追回)
CREDIT platform_loss_provision +$9,000    (平台计提损失)
entry_type = 'DEBIT_BALANCE_PROVISION'

Step 4: 用户通知
─────────────────
主题：紧急：您的账户出现资金缺口
内容：您此前的入金被银行退回，导致账户出现 $9,000 资金缺口。
      请在 [deadline] 前通过以下方式补足：
      1. 重新入金
      2. 卖出持仓
      若未在期限内补足，我们将采取必要措施。
渠道：Push + Email + SMS（所有渠道）

Step 5: 超时处理（5 个工作日内未补足）
────────────────────────────────────────
├── 触发强制平仓评估（不是立即平仓，需合规确认）
├── 升级至合规官和风控团队
├── 若合规确认强制平仓：
│   - 由系统提交市价卖单（优先卖流动性最好的持仓）
│   - 平仓所得扣除缺口金额
│   - 剩余归还用户
│   - 若平仓所得不足以覆盖缺口：走法务催收流程
└── 记录全程 audit trail（用于后续法律程序）
```

**强制平仓触发条件（严格限制，避免误触发）：**

| 条件 | 说明 |
|------|------|
| 账户处于 DEBIT_BALANCE | 必要条件 |
| 超过宽限期（5 个工作日） | 必要条件 |
| 合规官人工确认 | 必要条件（不允许系统自动平仓） |
| 平仓前再次通知用户 | 必要条件（24 小时预警） |

---

### 6.2 出金失败后 frozen_withdrawal 释放的幂等保证

**核心挑战：** 失败通知可能多次到达（银行重发回调、系统重试），必须确保 frozen_withdrawal 只释放一次。

**幂等保证机制：**

```go
// 幂等性通过 ledger 分录的唯一性约束保证
// ledger_entries.entry_id = transfer_id + ':HOLD_RELEASE' （业务唯一键）

func EnsureHoldReleased(ctx context.Context, transferID string) error {
    idempotencyKey := transferID + ":HOLD_RELEASE"

    return db.WithTx(ctx, func(tx *sqlx.Tx) error {
        // 尝试插入唯一的 HOLD_RELEASE 分录
        entry := buildHoldReleaseEntry(transferID, idempotencyKey)

        err := ledgerRepo.InsertWithUniqueKeyTx(tx, entry)
        if isMySQLDuplicateError(err) {
            // 已经释放过，幂等成功，直接返回
            return nil
        }
        if err != nil {
            return fmt.Errorf("insert hold release for transfer %s: %w",
                transferID, err)
        }

        // 首次释放：更新余额
        return balanceRepo.ReleaseFrozenTx(tx,
            entry.UserID, entry.Amount, entry.Currency)
    })
}
```

**DB 层约束（防止双重释放的最后防线）：**

```sql
-- ledger_entries 增加业务唯一键
ALTER TABLE ledger_entries
    ADD COLUMN business_key VARCHAR(128) NULL,
    ADD UNIQUE INDEX idx_ledger_business_key (business_key);

-- HOLD_RELEASE 的 business_key 格式：
-- '{transfer_id}:HOLD_RELEASE'
```

---

## 七、状态修复 SLA

### 7.1 各异常状态的最大容忍时间

| 异常状态 | 最大容忍时间 | 到期后自动动作 | 通知对象 |
|----------|------------|----------------|----------|
| `PENDING_BANK_CONFIRM`（入金） | 按渠道 SLA + 4h | 升级运营人工处理 | 运营、合规 |
| `PENDING_BANK_CONFIRM`（出金） | 按渠道 SLA + 4h | 升级运营人工处理 | 运营、合规 |
| `PENDING_APPROVAL`（普通审批） | 4 工作小时 | 升级至高级审批队列 | 运营主管 |
| `PENDING_APPROVAL`（合规审批） | 8 工作小时 | 升级至合规主管 | 合规主管 |
| `BLOCKED_AML`（等待合规处理） | 24 工作小时 | 升级至合规主管 | 合规主管 + 法务 |
| `DEBIT_BALANCE`（欠款补充） | 5 个工作日 | 触发强制平仓评估 | 合规官、风控、法务 |
| `REVERSAL_PENDING`（等待银行退款） | T+5 个工作日 | 升级至合规，启动追款 | 合规、运营 |
| 对账差异 > $0.01 | 4 工作小时 | 自动告警 | 运营、合规 |
| 对账差异 > $100 | 立即 | 暂停相关出入金操作 | CTO、合规主管 |

### 7.2 渠道 SLA 配置

```go
var ChannelSLA = map[Channel]ChannelSLAConfig{
    ChannelACH: {
        SubmitTimeout:    30 * time.Second,
        ProcessingWindow: 48 * time.Hour, // T+2
        PollInterval:     2 * time.Hour,
        MaxWaitBeforeEscalate: 72 * time.Hour,
    },
    ChannelWire: {
        SubmitTimeout:    30 * time.Second,
        ProcessingWindow: 8 * time.Hour,
        PollInterval:     30 * time.Minute,
        MaxWaitBeforeEscalate: 12 * time.Hour,
    },
    ChannelFPS: {
        SubmitTimeout:    10 * time.Second,
        ProcessingWindow: 2 * time.Hour,
        PollInterval:     5 * time.Minute,
        MaxWaitBeforeEscalate: 4 * time.Hour,
    },
    ChannelSWIFT: {
        SubmitTimeout:    60 * time.Second,
        ProcessingWindow: 5 * 24 * time.Hour, // T+5
        PollInterval:     4 * time.Hour,
        MaxWaitBeforeEscalate: 7 * 24 * time.Hour,
    },
}
```

### 7.3 自动升级流程

```
异常状态超过 SLA
        │
        ▼
Level 1: 系统自动告警（运营 Oncall）
  → Slack/Feishu: "@oncall 出入金异常超 SLA"
  → 包含：transfer_id, user_id（脱敏）, 当前状态, 等待时长
        │
        ▼ （未处理 +2h）
Level 2: 升级运营主管
  → Email + 即时通讯
        │
        ▼ （未处理 +4h）
Level 3: 升级合规主管 + CTO
  → 电话告警（PagerDuty）
        │
        ▼ （未处理 +8h）
Level 4: 触发应急响应流程
  → 评估是否暂停相关渠道的出入金
  → 启动监管报告评估
```

---

## 八、关键设计决策总结

| 设计决策 | 原因 |
|----------|------|
| 银行超时时状态设为 `PENDING_BANK_CONFIRM`，不自动推进 | 资金状态不确定时，任何自动推进都有资金损失或重复计账风险 |
| 所有余额变化必须通过 ledger 分录驱动 | 保证 3-way reconciliation 永远平衡；直接修改余额字段会破坏审计链 |
| Hold 释放必须幂等（通过 ledger 唯一键保证） | 银行回调可能重发，幂等是防止双重释放的最后防线 |
| ACH Return 后不立即强制平仓，给用户宽限期 | 监管合规（不得随意处置客户资产）；给用户补充资金的机会 |
| Wire Reversal 确认银行资金到账前不返还用户余额 | 资金可能在途，过早返还导致平台垫资风险 |
| AML BLOCK 时出金场景必须释放 frozen | 账户被冻结不等于资金被没收，用户资金安全必须保障 |
| 下游服务不可用时出金拒绝、入金允许 | 出金依赖 unsettled balance 精确计算；宁可拒绝，不可错放 |
| 强制平仓必须有合规官人工确认 | 监管要求；避免系统 bug 导致客户资产损失 |

---

*本文档依据 SEC 17a-4 / FinCEN BSA / AMLO (HK) 等监管要求起草，如有监管规则更新，需同步修订。*