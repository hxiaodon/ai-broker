---
type: tracker
module: kyc
phase: 1
started: 2026-04-28
status: complete
---

# KYC 模块 Phase 1 实现跟踪

> **PRD**: [docs/prd/02-kyc.md](../prd/02-kyc.md)
> **合约**: [docs/contracts/ams-to-mobile.md](../../../docs/contracts/ams-to-mobile.md) § KYC
> **KYC 合约规格**: [services/ams/docs/specs/mobile-ams-kyc-contract.md](../../../services/ams/docs/specs/mobile-ams-kyc-contract.md)
> **HiFi 原型**: [prototypes/02-kyc/hifi/](../../prototypes/02-kyc/hifi/)
> **H5 架构决策**: [docs/specs/shared/h5-vs-native-decision.md](shared/h5-vs-native-decision.md)

---

## 架构决策

> **步骤拆分**：Steps 1-6 Flutter Native；Step 7（风险披露）H5 WebView；Step 8（协议文本展示）H5 WebView，签名动作 Native 完成。
>
> **Sumsub SDK**：Phase 1 引入 `sumsub_sdk_flutter`，Step 2 证件上传走 Sumsub SDK 原生流程（OCR + 活体检测），同时保留 image_picker fallback 用于测试。
>
> **断点续传**：`kycSessionId` 持久化至 `flutter_secure_storage`，App 启动时检查并恢复到对应 Step。
>
> **PII 加密**：SSN / HKID / TIN 在本地 AES-256-GCM 加密后再发送 API（与 funding 模块 EncryptionService 复用）。
>
> **幂等性**：每步 form 提交携带 `Idempotency-Key: UUID v4`（`_pendingKey ??= Uuid().v4()` 模式）。
>
> **状态轮询**：`KycStatusNotifier` 使用 `Timer.periodic(5s)`，最多 120 次（10 分钟），超时后停止并提示用户等待推送通知。
>
> **W-8BEN 续签入口**：位于 Settings 模块（Phase 2 对应 settings.tracker.md），本模块仅在 KYC 流程中完成初次签署。
>
> **生物识别**：文件上传（Step 2/3）提交前需 biometric challenge（HMAC-SHA256，`actionHash = SHA256(KYC_UPLOAD|SESSION_ID|DOC_TYPE|ACCOUNT_ID)`）。

---

## 任务列表

### Domain 层

- [ ] **T01** — `KycStatus` enum + `KycSession` entity
  - KycStatus: NOT_STARTED / IN_PROGRESS / SUBMITTED / PENDING_REVIEW / NEEDS_MORE_INFO / APPROVED / REJECTED / EXPIRED
  - KycSession: sessionId, currentStep, status, expiresAt, estimatedTimeMinutes
  - `domain/entities/kyc_session.dart`

- [ ] **T02** — `PersonalInfo` entity（Step 1）
  - firstName, lastName, chineseName, dateOfBirth, nationality, idType, employmentStatus
  - employer (nullable), isPep, isInsiderOfBroker
  - `domain/entities/personal_info.dart`

- [ ] **T03** — `DocumentUpload` entity + `DocumentType` enum（Step 2）
  - DocumentType: CHINA_RESIDENT_ID / HKID / PASSPORT / MAINLAND_PERMIT
  - DocumentUpload: documentId, type, status, sumsubApplicantId, frontImagePath, backImagePath (nullable)
  - `domain/entities/document_upload.dart`

- [ ] **T04** — `AddressProof` entity（Step 3）
  - street, city, province, postalCode, country, proofDocumentPath, proofDocumentType
  - `domain/entities/address_proof.dart`

- [ ] **T05** — `FinancialProfile` entity（Step 4）
  - annualIncomeRange, liquidNetWorthRange, fundsSources (List), employmentStatus, employerName (nullable)
  - `domain/entities/financial_profile.dart`

- [ ] **T06** — `InvestmentAssessment` entity（Step 5）
  - investmentObjective, riskTolerance, timeHorizon
  - stockExperienceYears, optionsExperienceYears, marginExperienceYears, liquidityNeed
  - `domain/entities/investment_assessment.dart`

- [ ] **T07** — `TaxForm` entity + `W8BenInfo` + `W9Info`（Step 6）
  - TaxFormType: W9 / W8BEN / CRS
  - W8BenInfo: fullName, countryOfTaxResidence, tin, tinNotAvailable, signatureDate
  - W9Info: fullName, ssn, address
  - TaxForm: type, w8ben (nullable), w9 (nullable)
  - `domain/entities/tax_form.dart`

- [ ] **T08** — `KycRepository` interface
  - startKyc / uploadDocument / confirmUpload / getSumsubToken
  - submitFinancialProfile / submitInvestmentAssessment / submitTaxForms / acknowledgeAgreements
  - submitKyc / getKycStatus / resumeSession
  - getUploadUrl (S3 presigned)
  - `domain/repositories/kyc_repository.dart`

### Data 层

- [ ] **T09** — Remote models（freezed + json_serializable）
  - KycSessionModel, PersonalInfoModel, DocumentUploadModel, FinancialProfileModel
  - InvestmentAssessmentModel, TaxFormModel, KycStatusModel, UploadUrlModel, SumsubTokenModel
  - `data/remote/models/`

- [ ] **T10** — `KycRemoteDataSource`（Dio + multipart）
  - 全部 API 方法实现 + S3 direct upload（SHA256 checksum）
  - `data/remote/kyc_remote_data_source.dart`

- [ ] **T11** — `KycRepositoryImpl` + `@riverpod` provider
  - domain entity ↔ remote model 映射
  - `data/kyc_repository_impl.dart`

### Application 层

- [ ] **T12** — `KycSessionNotifier`（核心状态管理）
  - 持久化 sessionId 到 SecureStorage
  - App 启动时 resumeSession
  - 对外暴露 currentStep / status / session
  - 状态轮询（Timer.periodic 5s，max 120 次）
  - `application/kyc_session_notifier.dart`

- [ ] **T13** — `PersonalInfoNotifier`（Step 1 表单）
  - 字段验证（年龄≥18, 英文姓名格式, PEP 标记）
  - submit → POST /v1/kyc/start → 更新 session
  - `application/personal_info_notifier.dart`

- [ ] **T14** — `DocumentUploadNotifier`（Step 2）
  - Sumsub SDK 集成（获取 token → 启动 SDK 流程）
  - image_picker fallback → S3 presigned upload → confirm
  - biometric challenge 前置
  - `application/document_upload_notifier.dart`

- [ ] **T15** — `AddressProofNotifier`（Step 3）
  - 文件选择（image_picker / file_picker for PDF）
  - S3 presigned upload → confirm
  - biometric challenge 前置
  - `application/address_proof_notifier.dart`

- [ ] **T16** — `FinancialProfileNotifier`（Step 4）
  - 流动净资产不得超过总净资产的实时校验（前端）
  - submit → POST /v1/kyc/financial-profile
  - `application/financial_profile_notifier.dart`

- [ ] **T17** — `InvestmentAssessmentNotifier`（Step 5）
  - submit → POST /v1/kyc/investment-assessment
  - `application/investment_assessment_notifier.dart`

- [ ] **T18** — `TaxFormNotifier`（Step 6）
  - W-8BEN / W-9 分支判断（依据 Step 1 国籍）
  - PII 加密（SSN/TIN 调用 EncryptionService 加密后传输）
  - HMAC 签名 submit → POST /v1/kyc/tax-forms
  - `application/tax_form_notifier.dart`

- [ ] **T19** — `AgreementNotifier`（Step 7+8 确认）
  - 接收 H5 WebView JSBridge 回调（risk_disclosure_read, agreements_signed）
  - submit → POST /v1/kyc/agreements
  - `application/agreement_notifier.dart`

- [ ] **T20** — `KycSubmitNotifier`（最终提交）
  - POST /v1/kyc/submit（幂等键）
  - 触发 KycSessionNotifier 切换到 PENDING_REVIEW + 开始轮询
  - `application/kyc_submit_notifier.dart`

### Presentation 层

- [ ] **T21** — `KycEntryScreen`（开户引导页）
  - 展示开户好处 + 预计 15 分钟
  - 判断：NOT_STARTED → 开始；IN_PROGRESS → 继续；APPROVED → 已开户页；EXPIRED → 过期提示
  - `presentation/screens/kyc_entry_screen.dart`

- [ ] **T22** — `KycStepRouter`（步骤容器 + 进度条）
  - 顶部线性进度指示（8 步）
  - 根据 `currentStep` 渲染对应 screen
  - 返回键确认弹窗（"进度会保存，确认离开？"）
  - `presentation/screens/kyc_step_router.dart`

- [ ] **T23** — `KycStep1PersonalScreen`（个人信息）
  - 英文姓/名、中文名（选填）、出生日期（日期选择器）
  - 国籍下拉、证件类型、就业状况、职业/雇主
  - PEP / 内部人员 checkbox + 说明弹窗
  - `presentation/screens/kyc_step1_personal_screen.dart`

- [ ] **T24** — `KycStep2DocumentScreen`（证件上传）
  - 证件类型选择（身份证/护照/HKID/港澳通行证）
  - Sumsub SDK 启动按钮（主流程）
  - OCR 识别结果回填 Step 1 字段预览 + 用户确认
  - 上传进度、失败重试提示
  - `presentation/screens/kyc_step2_document_screen.dart`

- [ ] **T25** — `KycStep3AddressScreen`（地址证明）
  - 地址表单（英文街道、城市、省份、邮编）
  - 文件上传（PDF/JPG，≤10MB）+ 预览缩略图
  - 不接受截图提示
  - `presentation/screens/kyc_step3_address_screen.dart`

- [ ] **T26** — `KycStep4FinanceScreen`（财务状况）
  - 5 个字段（年收入、总净资产、流动净资产、资金来源多选、就业状态）
  - 流动净资产 > 总净资产时红色提示 + 禁用"下一步"
  - `presentation/screens/kyc_step4_finance_screen.dart`

- [ ] **T27** — `KycStep5InvestmentScreen`（投资评估）
  - 5 个字段的单选/多选表单
  - `presentation/screens/kyc_step5_investment_screen.dart`

- [ ] **T28** — `KycStep6TaxScreen`（税务申报）
  - "您是否是美国税务居民？" 分支
  - W-9：SSN 输入（masked）+ 地址
  - W-8BEN：税务居住国、TIN、协定优惠说明、3年有效期提示
  - 签署日期自动填充（today UTC）
  - `presentation/screens/kyc_step6_tax_screen.dart`

- [ ] **T29** — `KycStep7DisclosureScreen`（风险披露 H5 WebView）
  - `webview_flutter` + JSBridge setAuthContext
  - 监听 `closeWebView({ risk_disclosure_read: true })` 回调
  - 回调后推进 currentStep
  - `presentation/screens/kyc_step7_disclosure_screen.dart`

- [ ] **T30** — `KycStep8AgreementScreen`（协议签署）
  - H5 WebView 展示协议文本（`setAuthContext` 注入）
  - Native 签名区：文本框输入英文全名
  - 姓名比对（与 Step 1 英文姓名比较，case-insensitive, trimmed）
  - 全选 checkbox + "提交申请"按钮
  - `presentation/screens/kyc_step8_agreement_screen.dart`

- [ ] **T31** — `KycReviewStatusScreen`（审核状态页）
  - 5 节点进度时间轴（已提交 / 身份核验 / 人工审核 / 合规审批 / 账户激活）
  - PENDING_REVIEW：动画加载 + 预计时间
  - NEEDS_MORE_INFO：具体原因 + 跳转对应补件步骤
  - APPROVED：UID + "立即入金"按钮
  - REJECTED：拒绝原因 + 客服按钮
  - `presentation/screens/kyc_review_status_screen.dart`

- [ ] **T32** — 补件流程（NEEDS_MORE_INFO re-entry）
  - 从 T31 状态页点击"去补件"→ 跳回对应 Step
  - 补件完成后重新 submit → 重回 PENDING_REVIEW
  - 最多 3 次补件机会提示

### 路由注册

- [ ] **T33** — GoRouter 路由注册
  - `/kyc` → KycEntryScreen
  - `/kyc/steps` → KycStepRouter
  - `/kyc/status` → KycReviewStatusScreen
  - 在 `core/router/app_router.dart` 补充路由

### 测试套件

- [ ] **T34** — State Management Tests
  - KycSessionNotifier 恢复逻辑、step 推进、status 轮询（fakeAsync）
  - TaxFormNotifier W-8BEN/W-9 分支
  - FinancialProfileNotifier 净资产校验
  - `integration_test/kyc/kyc_state_management_test.dart`

- [ ] **T35** — API Integration Tests（Mock Server）
  - POST /v1/kyc/start 成功/400 (underage)
  - POST /v1/kyc/documents/upload 202
  - GET /v1/kyc/sumsub-token
  - POST /v1/kyc/submit 202
  - GET /v1/kyc/status 各状态
  - `integration_test/kyc/kyc_api_integration_test.dart`

- [ ] **T36** — E2E Tests（Emulator + Mock Server）
  - Happy path: Step 1 → 8 → 提交 → APPROVED
  - NEEDS_MORE_INFO 补件流程
  - EXPIRED 草稿过期重开
  - `integration_test/kyc/kyc_e2e_app_test.dart`
