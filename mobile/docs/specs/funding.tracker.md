---
type: tracker
module: funding
phase: 1
started: 2026-04-27
status: complete
---

# Funding 模块 Phase 1 实现跟踪

> **PRD**: [docs/prd/05-funding.md](../prd/05-funding.md)
> **合约**: [docs/contracts/fund-to-mobile.md](../../../docs/contracts/fund-to-mobile.md)
> **HiFi 原型**: [prototypes/05-funding/hifi/](../../prototypes/05-funding/hifi/)

---

## 架构决策

> **入口：从 Portfolio 页面进入**（用户确认）：Funding 不作为底部 Tab，通过 Portfolio AppBar 的"出入金"按钮 `context.push(RouteNames.funding)` 进入。路由为顶层 GoRoute，支持 deep link。
>
> **绑卡验证：微存款验证**（用户确认）：按 PRD v3.0 § 4.1 标准，US ACH 银行账户绑定使用微存款验证（1-3 工作日）。MicroDepositVerifyScreen 从 FundingScreen 银行卡列表进入（点击 pending 状态卡）。
>
> **生物识别：FundWithdrawalBioService**：出金独立 bio challenge 端点（`/api/v1/funding/bio-challenge`），与 Trading 模块的 BioChallengeService 完全独立，actionHash 格式为 `SHA256(WITHDRAWAL|AMOUNT|BANK_ACCOUNT_ID|ACCOUNT_ID)`。
>
> **幂等性**：Deposit / Withdraw / BankBind 均使用 `Idempotency-Key: UUID v4`（`_pendingIdempotencyKey ??= Uuid().v4()` 模式，沿用 trading 模块），72h TTL。
>
> **金额精度**：所有金额使用 `Decimal`（`package:decimal`），通过 `DecimalInputField`（已有 shared widget）输入，JSON 传输为字符串，禁止 double。

---

## 任务列表

### Domain 层

- [x] **T01** — `BankAccount` entity
  - id, accountName, accountNumberMasked, routingNumber, bankName, currency, isVerified
  - cooldownEndsAt (nullable), MicroDepositStatus (enum), remainingVerifyAttempts
  - computed: `isInCooldown`, `isUsable`
  - `domain/entities/bank_account.dart`

- [x] **T02** — `AccountBalance` entity
  - accountId, currency, totalBalance, availableBalance, unsettledAmount, withdrawableBalance
  - `domain/entities/account_balance.dart`

- [x] **T03** — `FundTransfer` entity + enums
  - TransferType (deposit/withdrawal), BankChannel (ach/wire)
  - TransferStatus (11 states) + `userFacingLabel` extension + `isTerminal`
  - `domain/entities/fund_transfer.dart`

- [x] **T04** — `FundingRepository` interface
  - 8 methods: getBalance / initiateDeposit / initiateWithdrawal / getTransferHistory
  - getBankAccounts / addBankAccount / removeBankAccount / verifyMicroDeposit
  - `domain/repositories/funding_repository.dart`

### Data 层

- [x] **T05** — `BankAccountModel` + `AccountBalanceModel`（freezed + json_serializable）
  - `data/remote/models/bank_account_model.dart`
  - `data/remote/models/account_balance_model.dart`

- [x] **T06** — `FundTransferModel`（freezed + json_serializable）
  - `data/remote/models/fund_transfer_model.dart`

- [x] **T07** — `FundingMappers`
  - 类型安全的 toDomain() 方法（含 Decimal 安全解析、UTC DateTime 解析）
  - TransferStatus / TransferType / BankChannel / MicroDepositStatus 枚举映射
  - `data/remote/funding_mappers.dart`

- [x] **T08** — `FundingRemoteDataSource`
  - 8 个 REST 端点 + HMAC 签名 + Idempotency-Key + 出金 biometric headers
  - `data/remote/funding_remote_data_source.dart`

- [x] **T09** — `FundingRepositoryImpl`（Riverpod Provider，keepAlive: true）
  - 使用 `EnvironmentConfig.instance.fundingBaseUrl`（新增字段）
  - `data/funding_repository_impl.dart`

### Application 层

- [x] **T10** — `AccountBalanceNotifier`（FutureProvider, autoDispose）
  - `application/account_balance_notifier.dart`

- [x] **T11** — `BankAccountsNotifier`（AsyncNotifier）
  - addBankAccount() → Future<BankAccount>（供 BankBindNotifier 使用）
  - removeBankAccount(): 乐观删除 + rollback on error
  - verifyMicroDeposit(): 替换列表中对应条目
  - `application/bank_accounts_notifier.dart`

- [x] **T12** — `FundTransferHistoryNotifier`
  - 首页 10 条：`fundTransferHistoryProvider`
  - 分页：`fundTransferHistoryPageProvider(page)`
  - `application/fund_transfer_history_notifier.dart`

- [x] **T13** — `DepositFormNotifier`（Notifier）
  - State machine: idle → confirming → submitting → success / error
  - Idempotency key 生成与复用
  - `application/deposit_form_notifier.dart`

- [x] **T14** — `WithdrawFormNotifier`（Notifier）
  - State machine: idle → confirming → awaitingBiometric → submitting → success / error
  - 生物识别 challenge-response 完整流程
  - `application/withdraw_form_notifier.dart`

- [x] **T15** — `BankBindNotifier`（Notifier）
  - State machine: idle → submitting → pendingMicroDeposit / error
  - `application/bank_bind_notifier.dart`

### Security 层

- [x] **T16** — `FundWithdrawalBioService`
  - endpoint: `/api/v1/funding/bio-challenge`
  - computeActionHash: `SHA256(WITHDRAWAL|AMOUNT|BANK_ACCOUNT_ID|ACCOUNT_ID)`
  - `core/security/fund_withdrawal_bio_service.dart`

### Presentation 层

- [x] **T17** — `FundingScreen`（主页，资金中心）
  - BalanceCard + HkdPlaceholderCard + 入金/出金按钮 + 银行卡列表 + 近期流水
  - RefreshIndicator + ScreenProtectionMixin
  - `presentation/screens/funding_screen.dart`

- [x] **T18** — `BalanceCard` widget
  - 4 字段：总资产 / 可用现金 / 待结算 / 可提现金额
  - loading skeleton + error retry
  - `presentation/widgets/balance_card.dart`

- [x] **T19** — `HkdPlaceholderCard` widget（Opacity 0.4，不可交互）
  - `presentation/widgets/hkd_placeholder_card.dart`

- [x] **T20** — `BankAccountCard` widget（Dismissible 滑动删除）
  - 状态 badge：已验证 / 等待微存款 / 冷却期 X 天 / 验证失败
  - 点击 pending 卡 → 跳转 MicroDepositVerifyScreen
  - `presentation/widgets/bank_account_card.dart`

- [x] **T21** — `TransferHistoryTile` widget
  - 入金绿↑ / 出金红↓ + 状态 chip + 本地化时间
  - `presentation/widgets/transfer_history_tile.dart`

- [x] **T22** — `DepositScreen`（3 步：金额 → 确认 → 完成）
  - DecimalInputField + 快捷金额 + 银行卡选择器 + 费用摘要
  - `presentation/screens/deposit_screen.dart`

- [x] **T23** — `WithdrawScreen`（3 步：金额 → 生物识别 → 完成）
  - 可提现金额实时显示 + 金额校验 + Face ID/Touch ID 确认
  - ScreenProtectionMixin（敏感屏幕）
  - `presentation/screens/withdraw_screen.dart`

- [x] **T24** — `BankAccountBindScreen`（US ACH 绑卡流程）
  - KYC 姓名自动填充（只读）+ Routing Number + Account Number（obscure）+ 银行名称
  - 提交后显示等待微存款状态 + 预计激活时间
  - `presentation/screens/bank_account_bind_screen.dart`

- [x] **T25** — `MicroDepositVerifyScreen`
  - 输入 2 笔金额 + 剩余次数提示 + 验证失败（≥5次）→ 强制删除重绑
  - `presentation/screens/micro_deposit_verify_screen.dart`

### Router 更新

- [x] **T26** — Router + Portfolio 入口
  - `core/routing/app_router.dart`: 顶层 GoRoute（funding + 4 子路由）
  - `core/routing/route_names.dart`: 新增 `fundingMicroDeposit`
  - `features/portfolio/presentation/screens/portfolio_screen.dart`: AppBar actions "出入金"按钮
  - `core/config/environment_config.dart`: 新增 `fundingBaseUrl`

### Mock Server

- [x] **T27** — `mock-server/funding.go`
  - 9 个端点：balance / deposit / withdrawal / fund/history / bank-accounts /
    bank-accounts/:id (DELETE) / bank-accounts/:id/verify-micro-deposit / funding/bio-challenge
  - Idempotency-Key 缓存（72h）
  - 微存款：接受 $0.15 + $0.23 ± $0.01
  - `mock-server/main.go`: 注册所有 funding 路由

### 集成测试

- [x] **T28** — `funding_state_management_test.dart`（6 个 state/routing 测试）
- [x] **T29** — `funding_api_integration_test.dart`（12 个 API 测试，含幂等性 + bio headers）
- [x] **T30** — `funding_e2e_app_test.dart`（4 个 E2E 测试）

---

## 验收标准

- [x] `flutter analyze lib/features/funding/` — 0 errors
- [x] `go build ./...`（mock-server）— 编译通过
- [x] 所有 freezed/riverpod `.g.dart` 文件已生成（19 个文件）
- [x] `flutter test test/features/funding/ test/core/security/fund_withdrawal_bio_service_test.dart` — **124 tests passed** ✅
- [x] Mock Server 启动后 API tests pass — **12/12 passed** (FB1–FB12) ✅
- [x] State management tests pass on iPhone 17 Pro simulator — **6/6 passed** ✅
- [x] E2E tests pass on iPhone 17 Pro simulator + mock server — **4/4 passed** ✅
- [x] **集成测试总计 22/22 passed** (iPhone 17 Pro, iOS 26.4.1) ✅

---

## 安全约束（已验证）

| 约束 | 实现位置 |
|-----|---------|
| 金额使用 Decimal，非 double | `funding_mappers.dart` + `DecimalInputField` |
| Idempotency-Key UUID v4，terminal 后 reset | `deposit_form_notifier.dart`, `withdraw_form_notifier.dart`, `bank_bind_notifier.dart` |
| 账户号后端脱敏（后 4 位），前端不展示完整号 | `BankAccountModel` + `BankAccountCard` |
| 出金必须生物识别 | `WithdrawFormNotifier.authenticateAndSubmit()` |
| 出金后立即 invalidate balanceProvider | `WithdrawFormNotifier` success state |
| 待验证卡（micro-deposit pending）不可用 | `BankAccount.isUsable` + 选择器过滤 |
| 微存款验证 ≥5 次，卡作废 | `MicroDepositVerifyScreen._FailedState` |
| 所有时间戳 UTC | `_parseUtcDateTime()` in `funding_mappers.dart` |
