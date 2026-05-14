# Test Suite Review Findings — Mobile App

**Review Date**: 2026-05-06  
**Scope**: 85 test files across 7 modules (Auth, KYC, Market, Trading, Funding, Portfolio, Settings)  
**Reviewer**: qa-engineer agent (spec-first, independent review)

---

## Module Coverage Matrix

| Module | Unit Tests (UT) | State Mgmt IT | API IT | E2E IT |
|--------|-----------------|---------------|--------|--------|
| Auth | ✅ (10 files) | ✅ | ✅ | ✅ |
| KYC | ❌ none | ✅ (质量差) | ⚠️ thin | ⚠️ thin |
| Market | ✅ (15 files) | ✅ | ✅ | ✅ |
| Trading | ✅ (6 files) | ✅ | ✅ | ⚠️ thin |
| Funding | ✅ (7 files) | ✅ | ✅ | ⚠️ thin |
| Portfolio | ❌ none | ✅ | ✅ | ⚠️ thin |
| Settings | ❌ none | ✅ | ✅ | ⚠️ thin |

**⚠️ thin** = 测试存在但断言过弱，无法检测回归  
**❌ none** = 该层测试完全缺失

---

## P0 — Critical Gaps（必须修复，可能造成财务损失或合规违规）

### P0-01: SEC Fee / FINRA TAF 计算公式未验证

- **模块**: Trading
- **问题**: `order_test.dart` 只检查费用字段 `isA<Decimal>()`，从不用输入值计算费用并验证结果。SEC fee 公式（`amount × 0.0000278`）和 FINRA TAF 公式（`shares × $0.000166，上限 $8.30`）均未被任何测试验证。
- **违反规则**: PRD-04 §6.5；financial-coding-standards Rule 1（fee 四舍五入到 2 位小数，half-up）
- **建议测试**:
  - `sec_fee_calculation_test.dart`: `secFee(amount: Decimal('10000.00')) == Decimal('0.28')`
  - `finra_fee_calculation_test.dart`: `finraFee(shares: 50000) == Decimal('8.30')`（上限测试）；`finraFee(shares: 100) == Decimal('0.02')`（0.0166 → 0.02 half-up）

---

### P0-02: 加权平均成本公式未被任何测试验证

- **模块**: Portfolio（无 UT）
- **问题**: PRD-06 §6.1 给出了明确公式：`new_avg = (existing_qty × existing_avg + new_qty × fill_price) / new_total_qty`。Portfolio state management 测试使用预设 stub 值（`Decimal.parse('150.25')`），从不执行该公式。spec 自身的计算示例（100 @ $180 + 50 @ $190 = $183.33）未被任何测试覆盖。
- **违反规则**: PRD-06 §6.1；financial-coding-standards Rule 1
- **建议测试**:
  - `weighted_avg_cost_test.dart`: `computeWeightedAvg(existingQty: 100, existingAvg: 180, newQty: 50, fillPrice: 190) == Decimal('183.33')`
  - 边界：从零仓位首次买入；卖至零后重新买入

---

### P0-03: 可提现余额公式未被验证

- **模块**: Funding
- **问题**: PRD-05 §5.1 定义 `withdrawableBalance = availableBalance − frozenWithdrawalAmount`。`account_balance_test.dart` 中的 "withdrawable is less than or equal to available" 只检查预设值之间的不等式，从不用公式推算。未结算金额对可提现余额的影响完全未测。
- **违反规则**: PRD-05 §5.1；fund-transfer-compliance Rule 4（可提现余额 = 总现金 - 未结算金额 - 待处理提款 - 保证金要求）
- **建议测试**:
  - `withdrawable_balance_test.dart`: `availableBalance=10000, pendingWithdrawal=3000` → `withdrawableBalance==7000`；`unsettledAmount=2000` → 进一步减少

---

### P0-04: 未结算股票不可卖的阻断逻辑未被 E2E 验证

- **模块**: Trading、Portfolio
- **问题**: PRD-04 §6.3 和 PRD-06 §6.2 要求 `availableQty`（已结算）作为最大可卖数量强制上限。state management 测试 TP14 注释说"UI 层 clamps"，但实际断言是 `availableQty > qty`——这只记录了一个已知数据问题，并未验证保护机制是否触发。无 E2E 测试验证输入超出 `availableQty` 时提交按钮被禁用。
- **违反规则**: PRD-06 §6.2；PRD-04 §6.3（卖出最大值计算：当前已结算持仓，未结算部分不可卖）
- **建议测试**:
  - Unit: `max_sell_quantity_test.dart`：`availableQty=50, qty=100` 时表单 qty 被钳制为 50
  - E2E: 用户尝试提交 100 股卖单，已结算仓位只有 50 股，提交按钮保持禁用

---

### P0-05: AML 审核/拒绝状态流转无测试

- **模块**: Funding
- **问题**: PRD-05 §4.2 说明 AML 筛查对用户"完全透明"。`funding_api_integration_test.dart` FB2 只检查成功存款返回 `status == 'PENDING'`。AML 筛查返回 `REVIEW` 或 `REJECTED` 时的状态流转（`提交中 → 审核中` vs `提交中 → 已拒绝`）完全没有测试。
- **违反规则**: PRD-05 §4.2；fund-transfer-compliance Rule 2（AML 筛查对任意金额强制要求）
- **建议测试**:
  - API IT: mock server 返回 AML `REVIEW` → 验证响应状态映射为 `审核中`
  - API IT: mock server 返回 AML `REJECTED` → 验证 `已拒绝` 状态及非空拒绝原因

---

### P0-06: 同名账户原则无测试

- **模块**: Funding
- **问题**: fund-transfer-compliance Rule 1 是最核心的 AML 控制。`funding_api_integration_test.dart` FB9 提交了 `'account_name': 'John Smith'` 但未测试姓名与 KYC 不符的拒绝场景。
- **违反规则**: fund-transfer-compliance Rule 1；PRD-05 §4.1
- **建议测试**:
  - `same_name_account_test.dart` (API IT): POST `/api/v1/bank-accounts` with `account_name = 'Different Person'` → expect 422 with `error_code = 'NAME_MISMATCH'`

---

### P0-07: 出金生物认证完整流程无测试

- **模块**: Funding
- **问题**: PRD-05 §4.3 要求出金确认必须经过生物识别；PRD-08 §6.1 说明"不可关闭"。FB6 只检查缺少生物识别 header 返回 400，但完整的 `fetchChallenge → authenticate → computeBioToken → submit` 流程从未被端到端测试。`fund_withdrawal_bio_service_test.dart` 未验证 token 与 challenge 绑定（challenge 变化时 token 必须改变）。
- **违反规则**: security-compliance 生物认证章节；PRD-05 §4.3；PRD-08 §6.1
- **建议测试**:
  - Unit: `computeBioToken` 输出在 challenge 变化时必须改变（验证 challenge 绑定性）

---

### P0-08: OTP 5 次失败锁账 30 分钟无测试

- **模块**: Auth
- **问题**: PRD-01 §6.1 规定同一 OTP 请求最多错误 5 次，超限锁定账号 30 分钟。auth API IT 和 E2E 测试均未包含连续 5 次错误 OTP 后第 6 次返回锁定错误的场景。
- **违反规则**: PRD-01 §6.1（七. 安全与合规）；NIST SP 800-63B
- **建议测试**:
  - API IT: 提交错误 OTP 5 次 → 第 6 次返回 429/423，`error_code = 'ACCOUNT_LOCKED'`，响应含锁定时长

---

### P0-09: Guest 延迟行情标识断言完全无效（合规硬要求）

- **模块**: Market、Cross-module
- **问题**: PRD-03 §6.1 将延迟行情标识定义为 SEC Regulation NMS 合规硬要求，PRD-01 §11 要求"所有行情数据旁必须显示'延迟 15 分钟'标识"。`cross_module_integration_test.dart` C7 测试注释写明 "Guest should see 15-min delayed data indicator"，但实际断言是 `expect(find.byType(Scaffold), findsWidgets)`——即使 app 显示实时行情且完全没有延迟标识，测试也会通过。这是一个给出虚假合规信心的断言。
- **违反规则**: PRD-03 §七（SEC Regulation NMS）；PRD-01 §11
- **建议测试**:
  - E2E: Guest 模式进入行情主页 → `find.textContaining('延迟')` 或 `find.textContaining('Delayed 15')` 必须 findsWidgets

---

### P0-10: 小额存款验证 5 次耗尽后终止状态无测试

- **模块**: Funding
- **问题**: PRD-05 §4.1 规定已用验证次数 ≥ 5 次时验证失败，需删除后重新绑卡。FB11 只覆盖单次金额错误（422）。`BankAccount.remainingVerifyAttempts` 字段默认值为 5 的测试存在，但 `remainingVerifyAttempts == 0` 时不可再提交的终止状态从未测试。
- **违反规则**: PRD-05 §4.1；fund-transfer-compliance Rule 8
- **建议测试**:
  - Unit: `bank_account_test.dart`：`remainingVerifyAttempts == 0` 时 `isUsable` 返回 false，`canAttemptVerification` 返回 false

---

## QI — 质量问题（测试存在但验证方式有误）

### QI-01: KYC state management 测试验证 Dart 运算符而非 notifier 逻辑

- **文件**: `kyc_state_management_test.dart`，测试 K3–K12
- **问题**: 大量测试在测试体内部自行计算"期望值"并与自身比较。K5 例：`liquidOrdinal = 3, totalOrdinal = 2`，断言 `liquidOrdinal > totalOrdinal`——这与 `FinancialProfileNotifier` 的实际行为无关，永远为真。K8 将 `taxFormType` 定义为测试体内部的 lambda。
- **应该测试什么**: 实际调用 `PersonalInfoNotifier.validate(dob: ...)`、`FinancialProfileNotifier.validateLiquidNetWorth(...)` 等方法，期望值从 spec 规则推导，而非在测试内部计算。

---

### QI-02: Portfolio TP3 用 stub 值作为期望值（循环验证）

- **文件**: `portfolio_state_management_test.dart`，测试 TP3
- **问题**: `expect(summary.totalEquity, Decimal.parse('96282.20'))` 中的期望值 `96282.20` 直接抄自同文件的 `_StubTradingRepository.getPortfolioSummary()` 返回值。这是同义反复：stub 返回什么，测试就断言什么，无法检测任何逻辑错误。
- **应该测试什么**: 验证 `totalEquity = cashBalance + marketValue` 的组装逻辑，而非 stub 的原始返回值。

---

### QI-03: Trading E2E 5 个 journey 全部只断言 `find.byType(Scaffold)`

- **文件**: `trading_e2e_app_test.dart`
- **问题**: Journey 1 断言 `find.byType(Scaffold)`；Journey 2 断言 `find.text('买入')`；Journey 5 断言 `find.text('AAPL')`。没有一个 journey 真正完成了"填写订单 → 确认 → 验证 mock server 收到请求 → 订单出现在列表"的完整流程。
- **应该测试什么**: 最低限度：渲染 `OrderEntryScreen`，填写 qty/price，点击提交，验证 mock server 收到调用，`OrderListScreen` 显示新订单。

---

### QI-04: Cross-module C7 断言无效（SEC 合规测试）

- **文件**: `cross_module_integration_test.dart`，测试 C7
- **问题**: 见 P0-09。测试注释描述的是有意义的行为，但断言 `find.byType(Scaffold)` 对任何页面状态都会通过，给审阅者虚假的合规信心。

---

### QI-05: `auth_flow_test.dart` 包含永远通过的占位测试

- **文件**: `integration_test/auth_flow_test.dart`
- **问题**: "Error handling: network failure on OTP send" 和 "Complete login flow" 两个测试均包含内联注释 "Note: In a real test with mocked repository, we would..."，测试体无条件通过。这些是从未完成的占位 stub，但会被计入覆盖率统计。

---

### QI-06: Funding FB10 使用 magic number 微存款金额

- **文件**: `funding_api_integration_test.dart`，测试 FB10
- **问题**: `{'amount_1': '0.15', 'amount_2': '0.23'}` 与 mock server 预设值绑定，不来自任何 spec。未验证金额必须在 $0.01–$0.99 USD 范围内；边界值（$0.01、$0.99、$1.00 超出范围）均未测试。

---

## CI — 分类问题（测试放错了位置）

### CI-01: `integration_test/auth_flow_test.dart` — 遗留根目录文件

- **问题**: 位于 `integration_test/` 根目录，不在 `auth/` 子目录。不使用 `TestAppConfig`，绕过三层分类标准。与 `auth/auth_e2e_app_test.dart` 部分重复，且含不完整 stub 测试（见 QI-05）。
- **处置**: 完成断言后迁移至 `auth/auth_e2e_app_test.dart`，或直接删除。

---

### CI-02: `integration_test/guest_mode_test.dart` — 遗留根目录文件

- **问题**: 同 CI-01，根目录放置，应属于 `market/` 或 cross-module 目录。
- **处置**: 审计后迁移或删除。

---

### CI-03: `integration_test/watchlist_loading_test.dart` — 遗留根目录文件

- **问题**: Market watchlist 测试放在根目录，应在 `integration_test/market/`。
- **处置**: 迁移至 `market/market_e2e_app_test.dart` 或确认已有重复覆盖后删除。

---

### CI-04: `integration_test/features/market/data/watchlist_repository_test.dart` — 目录结构错误

- **问题**: 路径 `integration_test/features/market/data/` 镜像了 `lib/features/` 的源码结构，这是 `test/`（单元测试）的组织模式，不是集成测试的模式。按 INTEGRATION_TEST_GUIDE.md，集成测试应在 `integration_test/{module}/`。
- **处置**: 移动至 `integration_test/market/`，并使用正确的三层文件名。

---

### CI-05: `test/features/market/data/quote_cache_repository_api_integration_test.dart` — API IT 放在 UT 目录

- **问题**: 文件名以 `_api_integration_test.dart` 结尾，但位于 `test/` 目录。CI 的 `flutter test integration_test/` 命令不会运行此文件。
- **处置**: 移动至 `integration_test/market/`，或确认仅使用 mock 后重命名为 `_test.dart`。

---

## P1 — 非关键缺口

| # | 模块 | 缺失内容 | 来源 |
|---|------|---------|------|
| P1-01 | KYC | 无任何 UT（8 个步骤各有域验证逻辑：年龄、OCR 置信度、地址日期、签名匹配、PEP 路由） | PRD-02 |
| P1-02 | Portfolio | 无任何 UT（加权平均成本、板块权重公式、wash-sale 标志） | PRD-06 |
| P1-03 | Settings | 无任何 UT（PII 脱敏逻辑、W-8BEN 到期计算、KYC 等级标签推导） | PRD-08 |
| P1-04 | Auth | OTP 60 秒限速无 API IT 验证 | PRD-01 §6.1 |
| P1-05 | Trading | GTC 订单 90 天过期及提前 3/1 天通知无测试 | PRD-04 §6.4 |
| P1-06 | Auth/Settings | 第 4 台设备登录触发踢出最早设备逻辑无 E2E 测试 | PRD-01 §6.3 |
| P1-07 | Settings/KYC | W-8BEN 剩余 30 天边界值和恰好 90 天边界值无测试 | PRD-02 §6.4；PRD-08 §5.2 |
| P1-08 | KYC | 60 天后 `IN_PROGRESS → EXPIRED` 状态及恢复流程无 E2E 测试 | PRD-02 §6.2 |
| P1-09 | Trading/Settings | 买卖按钮颜色不随颜色方案偏好变化（固定红绿）无 Widget 测试 | PRD-04 §6.7 |
| P1-10 | Market | Watchlist 100 条上限达到后 `WATCHLIST_FULL` 错误无测试 | PRD-03 §6.3 |
| P1-11 | Market | 搜索 300ms 防抖行为无测试（300ms 内不触发请求） | PRD-03 §5.3 |
| P1-12 | Portfolio | 单只股票超 30% 仓位集中度警告触发逻辑无测试 | PRD-06 §5.2 |
| P1-13 | KYC | `kyc_api_integration_test.dart` K-API-05~09 用 `anyOf(200, 204)`，无响应体内容断言 | — |

---

## P2 — 低优先级缺口

| # | 描述 |
|---|------|
| P2-01 | WebSocket 并发连接下重连性能无负载测试 |
| P2-02 | 交易接口限速（10 req/s）超出后 429 无测试 |
| P2-03 | 交易历史 CSV 导出（税务用途）无测试（PRD-04 §8.4） |

---

## 修复优先级建议

```
立即处理（本周）：P0-09（虚假合规断言）、P0-01/02/03（金融计算公式零验证）
下一迭代（P0 其余）：P0-04 ~ P0-08、P0-10
分类清理（独立 PR）：CI-01 ~ CI-05
质量修复：QI-01（KYC 测试重写）、QI-03（Trading E2E 补全）
P1 按模块逐步补充
```
