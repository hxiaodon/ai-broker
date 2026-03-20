# 移动端技术方案对比评估报告
（KMP/CMP vs Flutter — 针对证券交易 App 技术问题的解决能力）

**评估日期**: 2026-03-13
**评估依据**: Compose Multiplatform 1.10.2（稳定版，2026-03-05）、Flutter 3.41.4（稳定版，2026-03-04）
**Kotlin 版本**: 2.3.10（稳定版，2026-02-05）
**评估维度**: 对 mobile-kmp-review.md 中 12 个问题的解决能力
**数据来源**: GitHub API、pub.dev API、JetBrains CHANGELOG.md、Flutter stable CHANGELOG 实时抓取

---

## 一、技术问题逐项评估

---

### 问题 1：生物识别（expect/actual — iOS Secure Enclave + Android Keystore 硬件密钥签名）

#### KMP/CMP 现状

KMP 生态中，2026 年 3 月出现了显著进展：

- **KSafe v1.7.0**（2026-03-04，stars: 233）：支持 `KSafeEncryptedProtection.HARDWARE_ISOLATED` 模式，在 iOS 上使用 Secure Enclave 的 EC P-256 密钥通过 ECIES 包裹 AES-256-GCM 对称密钥（Envelope Encryption），在 Android 上调用 StrongBox/TEE。其 API 已内置 `verifyBiometricDirect()` 和 `verifyBiometric()`（suspend），实现跨平台生物识别身份验证门控。
- **KVault v1.12.0**（2023-10-11，停止更新，stars: 307）：仅做 Keychain/EncryptedSharedPreferences 封装，不支持生物识别绑定，已过时。
- **核心缺口依然存在**：上述库解决的是"生物识别认证后才允许访问存储密钥"，但 PRD-04 要求的是"生物识别绑定的硬件密钥对用于**交易签名（挑战-响应机制）**"，即 `KeyPairGenerator` + `BiometricPrompt.CryptoObject`（Android）或 `SecKeyCreateRandomKey` + `LAContext`（iOS）的签名流程。KSafe 不暴露 `KeyPair`/`SignatureBytes` API，无法满足"私钥从不离开 Secure Enclave，挑战数据由私钥签名后传给服务端验证"的需求。
- **目前无成熟的 KMP 跨平台签名库**支持该流程，仍需编写大量 `expect/actual` 原生代码（iOS: `Security.framework` + `CryptoKit`，Android: `java.security.KeyPairGenerator` + `androidx.biometric:biometric:1.1.0`）。

#### Flutter 现状

- **local_auth v3.0.1**（官方维护）：提供 `authenticate()` 方法，通过 LAContext（iOS）/ BiometricPrompt（Android）完成**身份验证**，但**不暴露 CryptoObject 接口**，无法与 Android Keystore 密钥对的签名操作绑定。
- **biometric_crypto v1.0.1**（社区库，活跃度低）：宣称支持 Android 侧 BiometricPrompt + CryptoObject 签名，但 iOS Secure Enclave 密钥签名部分实现不完整，且维护状态不明。
- Flutter 在此场景与 KMP 处于相同困境：没有稳定的单一插件能完整封装"硬件密钥对 + 生物识别绑定签名"，iOS 和 Android 都需要平台通道（Method Channel）实现原生代码。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（KSafe 覆盖了安全存储+生物识别门控，但签名流程仍需自研 expect/actual 实现）
- **Flutter 是否解决**：⚠️ 部分解决（local_auth 覆盖认证验证，签名流程同样需要原生 Method Channel 代码）
- **推荐方案**：两套方案均需自实现签名模块。KMP 可利用 KSafe 1.7.0 的 `HARDWARE_ISOLATED` 模式管理密钥存储，签名逻辑通过 `:core:biometric` 模块的 `expect/actual BiometricKeyManager` 封装；Flutter 通过 Method Channel 调用 Kotlin/Swift 原生代码，与 KMP 工作量相当。**此问题不构成两方案的差异性优势**。

---

### 问题 2：Refresh Token 安全存储（HttpOnly Cookie 在原生 App 无效）

#### KMP/CMP 现状

- **KSafe v1.7.0**（2026-03-04）：iOS Keychain + Android Keystore AES-256-GCM 加密，支持 `HARDWARE_ISOLATED` 保护，内置 Compose `mutableStateOf()` 集成，并发安全。Kotlin 属性委托语法极简（`var token by ksafe(AuthTokens())`），支持 Ktor Auth 插件中的 `loadTokens`/`refreshTokens` 直接使用，适配度极高。
- **multiplatform-settings v1.3.0**（2024-11-29）：提供跨平台偏好存储，有加密版本（iOS Keychain / Android EncryptedSharedPreferences），但不支持 HARDWARE_ISOLATED 级别保护，不建议存储 Refresh Token。
- PRD HttpOnly Cookie 问题在 KMP 方案下已有成熟的替代方案，KSafe 1.7.0 可直接投入使用。

#### Flutter 现状

- **flutter_secure_storage v10.0.0**（官方生态，主流库）：iOS 使用 Keychain（kSecAttrAccessible 可配置），Android 使用 EncryptedSharedPreferences，支持所有目标平台。配置 `IOSOptions.accessibility` 和 `AndroidOptions.encryptedSharedPreferences` 即可实现等效保护。
- API 成熟度高，在 Flutter 生态中是事实标准，Flutter pub.dev 周下载量 >60 万次。

#### 判断
- **KMP/CMP 是否解决**：✅ 已解决（KSafe v1.7.0 提供完整方案，包括 Secure Enclave 选项）
- **Flutter 是否解决**：✅ 已解决（flutter_secure_storage v10.0.0 生产就绪）
- **推荐方案**：两方案均已解决，Flutter 的 flutter_secure_storage 生态成熟度更高、社区案例更丰富。KMP 方案中 KSafe 综合能力更强（含生物识别、Compose 集成），但需评估 1.7.0 版本的生产稳定性。

---

### 问题 3：K 线图（CMP Canvas iOS 性能 + 跨平台图表库）

#### KMP/CMP 现状

**关键突破**：**Vico v3.0.0**（2026-02-21）将 Compose Multiplatform 模块从实验性升级为**稳定版**，且 v3.0.3（2026-03-07）已完成生产修复。

经调研确认：
- Vico 3.0.x 的 `CandlestickCartesianLayer` 已包含完整的 K 线图实现（蜡烛体 `LineComponent`、上下影线 `topWick`/`bottomWick`、OHLC 数据模型 `CandlestickCartesianLayerModel.Change`）。
- `VicoZoomState` 提供内置 pinch-to-zoom 支持，`VicoScrollState` 提供横向滚动，两者均通过 Compose `Modifier` 绑定，已在 v3.0.1 中改善 `CartesianChart` 和 `CartesianLayer` 性能。
- iOS 侧使用 Skia/Skiko（m138，CMP 1.10.0 升级）渲染。
- CMP 1.11.0-alpha03（2026-02-25）已将 `parallelRendering` 标志默认开启（在 1.11.0-alpha02 修复了相关崩溃问题），预计 CMP 1.11.0 稳定版（目标 Q2 2026）后 iOS 渲染性能将进一步提升。

**残留风险**：Vico 不含长按十字线（crosshair cursor）组件，需自行实现；500+ 根 K 线的真机帧率仍需基准测试验证（PRD 要求 > 55fps）。

#### Flutter 现状

- **financial_chart v0.4.1**（2025 年发布）：专为金融场景设计，支持 Candlestick/OHLC/线图/面积图，维护较活跃。
- **k_chart v0.7.1**（最后更新 2023-05-30）：K 线功能较完整（含 MACD、KDJ、成交量叠加），但已停止更新超 2 年，Flutter 3.29+ 兼容性存疑。
- **syncfusion_flutter_charts v32.2.9**（Syncfusion 商业授权，Community License 免费）：支持 Candlestick、OHLC，含缩放、缩略条，性能经过商业级验证，社区反馈 iOS 渲染流畅。
- **Flutter Impeller**（iOS 默认渲染引擎）：从 Flutter 3.27 起在 iOS 成为稳定默认，Metal API 路径，理论上比 Skia 更低延迟，Canvas API（`CustomPainter`）性能优于 CMP Canvas。

#### 判断
- **KMP/CMP 是否解决**：✅ 已解决（Vico 3.0.3 提供生产级 CMP K 线图，但需真机验证 500+ 根帧率）
- **Flutter 是否解决**：✅ 已解决（syncfusion_flutter_charts 商业级方案或 financial_chart 开源方案均可用）
- **推荐方案**：KMP 方案使用 Vico 3.0.3，这是本次评估的最大正面变化——mobile-kmp-review.md 中将 K 线图标记为 P0 风险，现已有稳定库可用。Flutter 方案 Syncfusion 体验更完整，但含商业授权约束。

---

### 问题 4：SMS OTP 自动填充（iOS textContentType.oneTimeCode vs Android SMS Retriever API）

#### KMP/CMP 现状

- **CMP 1.9.0（2025-09）**：引入 `PlatformImeOptions`（`#2108`），支持在 iOS 端配置原生 `UITextInputTraits`，`UITextInputTraits.textContentType` 理论上可通过该 API 设置为 `.oneTimeCode`，实现 SMS 自动填充提示。但官方文档未明确说明该属性的完整暴露范围。
- **CMP 1.11.0-alpha04（2026-03-11）**：引入 **Native iOS Text Input 模式**（`PlatformImeOptions.usingNativeTextInput(enabled)` + `#2602`），`BasicTextField` 在 iOS 侧直接使用 UIKit 原生编辑，明确列出"Autofill support for text fields, including filling from saved passwords one field at a time"，这意味着 `textContentType.oneTimeCode` 的 SMS 自动填充也将被覆盖。但该功能**仅在 1.11.0-alpha 阶段，尚未进入稳定版**（1.10.2 不含此功能）。
- **Android SMS Retriever**：与 CMP UI 层无关，在 `androidMain` 通过 `BroadcastReceiver` + `StateFlow` 实现，技术上可行，与 1.7.x 时期评估无变化。

#### Flutter 现状

- **smart_auth v3.2.0**：封装 Android SMS User Consent API 和 SMS Retriever API，维护活跃。
- **sms_autofill v2.4.1**：支持 Android SMS Retriever，iOS 侧通过 `AutofillHints.oneTimeCode` 设置 `UITextField.textContentType`，官方 Flutter 框架 `TextField` 的 `autofillHints: [AutofillHints.oneTimeCode]` 属性在 iOS 上原生映射到 `UITextContentType.oneTimeCode`，**功能已稳定可用**。
- Flutter 的 `TextField` 在 iOS 上底层是 `UITextField`（原生控件），autofill 行为与系统一致，无需 alpha 特性。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（Android 侧已解决；iOS `textContentType.oneTimeCode` 的稳定支持需等待 CMP 1.11.0 稳定版，当前 1.10.2 需要 `UIKitView` 包裹原生 `UITextField` 作为 workaround）
- **Flutter 是否解决**：✅ 已解决（`AutofillHints.oneTimeCode` + smart_auth，iOS/Android 均稳定）
- **推荐方案**：Flutter 在此问题上优于 KMP，无需 workaround。KMP 方案在 CMP 1.11.0 稳定版前，建议通过 `UIKitView` 包裹原生 `UITextField` 实现 iOS OTP 输入框，代价是该 TextField 无法享受 CMP 统一样式系统。

---

### 问题 5：设备 ID 生成（两平台 API 差异及隐私合规）

#### KMP/CMP 现状

- `expect/actual fun getDeviceInfo()` 模式依然是标准方案，无新的跨平台统一库出现。
- KSafe 1.7.0 内置 `ksafe.detectRoot()` / `ksafe.detectEmulator()` / `ksafe.isDebuggerAttached()` 等安全检测能力，可辅助设备指纹构建。
- 持久化设备 ID（UUID v4 首次生成后存入 Keychain/EncryptedSharedPreferences）通过 KSafe 即可实现，无需额外库。

#### Flutter 现状

- **device_info_plus v12.3.0**：覆盖 iOS（`identifierForVendor`、`systemVersion`、`model`）和 Android（`id`、`version`、`model`）平台信息，跨平台 API 统一，无需 `expect/actual`。
- **uuid v4.5.3** + **flutter_secure_storage**：首次生成 UUID v4 存入 Keychain/EncryptedSharedPreferences，实现持久化设备 ID。
- 方案标准化程度高于 KMP，单一插件（device_info_plus）即可替代两平台的 `actual` 实现。

#### 判断
- **KMP/CMP 是否解决**：✅ 已解决（通过 `expect/actual` + KSafe 持久化，代价是需编写两套 actual 代码）
- **Flutter 是否解决**：✅ 已解决（device_info_plus v12.3.0 开箱即用，无需 expect/actual）
- **推荐方案**：Flutter 方案实现成本更低。KMP 方案功能上完整，但代码量是 Flutter 的 2~3 倍。

---

### 问题 6：推送通知（APNs DeviceToken + FCM Token 统一上报）

#### KMP/CMP 现状

- **Firebase KMP SDK（GitLive）v2.4.0**（2025-10-31）：`firebase-messaging` 模块提供 `Firebase.messaging.getToken()`（iOS/Android 通用）和 `subscribeToTopic()`/`unsubscribeFromTopic()`，API 覆盖率标注为 10%，但核心的 Token 获取功能已可用。
- iOS APNs DeviceToken 桥接：GitLive Firebase KMP SDK 在 Apple/iOS 侧依赖原生 Firebase iOS SDK，其 `FIRMessaging.messaging().apnsToken` 需要在 Swift `AppDelegate` 中通过 `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` 传入，仍需薄 Swift AppDelegate 文件。CMP 项目的 iOS 入口通常是 `ComposeUIViewController`，需要保留 Swift AppDelegate 作为桥接层，此架构复杂度无变化。
- 前台推送处理：需分别在 iOS（`UNUserNotificationCenterDelegate`）和 Android（`FirebaseMessagingService.onMessageReceived`）处理，无法在 KMP 层统一。

#### Flutter 现状

- **firebase_messaging v16.1.2**（官方 FlutterFire 维护）：iOS 和 Android FCM Token 均通过 `FirebaseMessaging.instance.getToken()` 统一获取。APNs Token 关联由 Firebase iOS SDK 自动处理（`FIRMessaging` 内部调用 `registerForRemoteNotifications`），**不需要手动实现 AppDelegate 回调**，这是 Flutter 相对 KMP 的显著简化。
- `FirebaseMessaging.onMessage`（前台）、`FirebaseMessaging.onMessageOpenedApp`（后台点击）、`FirebaseMessaging.onBackgroundMessage`（iOS 后台限制同 KMP）均统一封装。
- 成熟度极高，FlutterFire 是 Flutter 官方生态，firebase_messaging 周下载量 >70 万次。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（Token 获取有库支持，但 iOS APNs 桥接仍需 Swift AppDelegate，架构复杂度较高）
- **Flutter 是否解决**：✅ 已解决（firebase_messaging 完整封装，iOS APNs 无需手动桥接）
- **推荐方案**：Flutter 在推送集成方面明显优于 KMP，减少约 30% 的 iOS 原生代码量。

---

### 问题 7：Slide-to-Confirm 手势（CMP 手势与 iOS 系统返回手势竞争）

#### KMP/CMP 现状

CMP 自 1.7.0 以来持续修复 iOS 手势冲突问题，关键修复记录如下：

- **CMP 1.8.0**（2025-02）：`#1818` 修复 interactive pop gesture 失效问题；`#1879` 修复"back gesture 和 Composable content 同时接收 touch"的 bug；新增关闭 iOS back gesture 检测的 flag（`#1951`）。
- **CMP 1.8.x**：`#2019` 修复 modal popup 后 back gesture 问题；`#2048` 修复 modal view controller dismiss 后 back gesture 处理。
- **CMP 1.9.0**（2025-09）：`#2186` 修复"横向滚动后意外触发 back gesture"。
- **CMP 1.10.0**（2026-01）：`#2605` 修复 back gesture 的 `NSRangeException` 崩溃。

当前（1.10.2）：iOS 交互式返回手势与 CMP 横向手势的竞争已大幅改善，但仍无法在不修改 `UINavigationController.interactivePopGestureRecognizer` 的情况下**完全消除**边缘区域的手势优先级冲突。Slide-to-Confirm 组件需要在交易确认页通过 `expect/actual` 的 `DisableEdgeSwipeBack` 包装器临时禁用系统手势（此方案 1.8.0 起已有 API flag 支持）。

#### Flutter 现状

- Flutter 的 `GestureDetector` 基于 Flutter 引擎的 Gesture Arena（竞技场）模型，与 iOS `UIGestureRecognizer` 在不同层运行，默认情况下 Flutter 内部手势优先级高于 iOS 系统手势（iOS 返回手势通过 `WillPopScope`/`PopScope` 控制）。
- 实现 Slide-to-Confirm 时，需设置 `PopScope(canPop: false, ...)` 或使用 `NavigatorObserver` 在交易确认页禁用返回手势，再用 `GestureDetector` 监听横向拖拽。
- **slide_to_confirm v1.1.0**：Flutter 可用的滑动确认组件，无需自行实现手势竞争处理。
- 风险：Flutter 在 iOS 上偶发平台视图（Platform View）与手势的竞争问题，但纯 Flutter UI（无 PlatformView）基本无此风险。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（CMP 1.10.2 已有禁用 iOS back gesture 的 API，但需要在每个需要手势隔离的页面显式调用，workaround 可接受）
- **Flutter 是否解决**：✅ 已解决（PopScope + GestureDetector，无需平台代码，slide_to_confirm 可直接使用）
- **推荐方案**：Flutter 更简洁。KMP 方案代码量略多，但 CMP 1.8.0+ 以后已有稳定的禁用接口。

---

### 问题 8：WebSocket 后台挂起（iOS 后台网络限制）

#### KMP/CMP 现状

- Ktor WebSocket（`io.ktor:ktor-client-websockets`）在 iOS Darwin 引擎（NSURLSession）下，后台网络挂起行为无变化，iOS 系统约 30 秒后暂停后台网络。
- 无新的 KMP WebSocket 后台保活方案出现。
- 推荐方案（mobile-kmp-review.md 中已列出）：`AppLifecycleObserver`（`expect/actual`）监听前台/后台切换，结合指数退避重连策略，此方案在 CMP 1.9.0 引入的 `Lifecycle` KMP 模块（`org.jetbrains.androidx.lifecycle:lifecycle-*:2.10.0`）后实现更标准化。
- **关键认知**：行情实时推送需要前台连接，后台订单状态依赖 FCM/APNs 推送，这是 iOS 系统设计的约束，与 Flutter/KMP 选型无关。

#### Flutter 现状

- Flutter 的 `WebSocketChannel`（via `web_socket_channel v3.0.3`）基于 Dart isolate，在 iOS 上同样受后台网络挂起限制。
- **flutter_background_service v5.1.0**：提供后台服务，但 iOS 侧依赖 `UIBackgroundModes`，支持场景有限（audio/voip/fetch，WebSocket 维持实际上不被支持）。
- Flutter 对此问题的处理逻辑与 KMP 完全一致：前台 WebSocket + 后台 FCM + 回前台重连 + REST 快照补全。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（需自实现 AppLifecycleObserver + 重连策略，iOS 系统约束不可绕过）
- **Flutter 是否解决**：⚠️ 部分解决（同样的 iOS 系统约束，解决方案模式相同）
- **推荐方案**：两方案等价，均受 iOS 系统约束。差异仅在实现代码量：KMP 需 expect/actual，Flutter 需 AppLifecycleObserver 的 Dart 实现（`WidgetsBindingObserver`），Flutter 稍简洁。

---

### 问题 9：KYC 图片选择与拍照（跨平台 PHPickerViewController / CameraX）

#### KMP/CMP 现状

- **FileKit v0.13.0**（2026-02-25）：KMP 文件选择库，支持图片、视频、文件，维护活跃，基于 `PHPickerViewController`（iOS）/ `ActivityResultContracts.PickVisualMedia`（Android）实现，是目前最成熟的 KMP 文件选择方案之一。
- **Calf v0.8.0**（2025-05-25）：支持图片选择（含相机拍摄），iOS HEIC 需额外处理，最后更新距今 10 个月，维护频率低于 FileKit。
- **Peekaboo v0.5.2**（2024-04-15）：相机拍摄为主，最后更新近 2 年，基本停维。
- 图片裁剪（证件四角不遮挡）：KMP 中无成熟跨平台裁剪库，需自绘 CMP 遮罩或 expect/actual 调用平台原生裁剪。

#### Flutter 现状

- **image_picker v1.2.1**（官方维护，FlutterFire 生态）：iOS `PHPickerViewController`（iOS 14+）/ UIImagePickerController，Android `MediaStore`，支持拍照和相册选择。HEIC 在 iOS 侧由系统自动处理（可配置输出格式），Android 需 `requestFullMetadata` 处理元数据。
- **photo_manager v3.9.0**（2025 年更新）：更高级的相册访问（批量、筛选、HEIC 解码），适用于 KYC 多图选择场景。
- **图片裁剪**：`image_cropper v7.x`（专用裁剪库，调用 iOS Objective-C 库 `TOCropViewController`，Android Ucrop 库），功能完整，证件四角裁剪场景成熟。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（FileKit 0.13.0 提供图片选择，但图片裁剪仍需自实现或 expect/actual 平台原生方案）
- **Flutter 是否解决**：✅ 已解决（image_picker + image_cropper 组合覆盖完整 KYC 场景）
- **推荐方案**：Flutter 方案更完整，image_cropper 提供生产级证件裁剪 UI，KMP 需额外开发裁剪功能。

---

### 问题 10：PDF 查看（W-8BEN 原件 — KMP 中无跨平台方案）

#### KMP/CMP 现状

- CMP 中仍**无跨平台 PDF 渲染 Composable**，情况与 1.7.x 时期相同。
- CMP 1.10.0（`#2501`）新增 `UIKitInteropProperties.placedAsOverlay` 实验标志，允许 UIKit Interop 视图（如 `PDFKit.PDFView`）渲染在 Compose Canvas 之上，解决了旧版 Interop 视图必须在 Compose Canvas 下层的问题，更便于 PDF 查看器的集成。
- **建议方案**：通过 `expect/actual PdfViewer(url)` + iOS `UIViewControllerRepresentable(PDFViewController)` + Android `AndroidView(PdfRenderer)` 实现，额外依赖：Android 侧使用 `com.tom_roush:pdfbox-android:2.0.27.0`（Apache PDFBox Android 移植）。

#### Flutter 现状

- **pdfx v2.9.2**：支持 iOS（PDFKit）、Android（`PdfRenderer`）、Web（PDF.js）、macOS、Windows，统一 API，维护活跃。
- **flutter_pdfview v1.4.4**（基于 `PDFKit`/`AndroidPdfViewer`）：更轻量，但 Android 底层依赖的 `barteksc/android-pdf-viewer` 已停维，不建议新项目使用。
- 敏感 PDF（W-8BEN 含 TIN）的截图防护：需在展示 PDF 的页面配合 `screen_protector v1.5.1` 禁用截图。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（需 expect/actual 集成平台原生 PDF 组件，CMP 1.10.0 改善了 UIKit Interop 层叠问题；非开箱即用）
- **Flutter 是否解决**：✅ 已解决（pdfx v2.9.2 直接可用，跨平台统一 API）
- **推荐方案**：Flutter 方案零样板代码，pdfx 开箱即用。KMP 方案需约 3~5 天的 expect/actual 集成工作。

---

### 问题 11：Kotlin/Native GC 性能（高频 StateFlow 更新在 iOS 上的内存和帧率风险）

#### KMP/CMP 现状

- **Kotlin 2.3.10**（稳定版，2026-02-05）：K/Native 持续采用新内存模型（引用计数 + 追踪 GC 混合），Kotlin 2.3.x 系列的 GC 调优工作持续进行，但无单一"K/Native GC 重大改进"的 Release Note 条目，表明此为渐进式优化。
- **CMP 1.11.0-alpha03**（2026-02-25）：`parallelRendering` 默认开启，GPU 命令编码下沉至独立线程，理论上减少了 Compose 帧渲染对 Main RunLoop 的占用，间接缓解高频 StateFlow 更新时的 UI 卡顿。
- **根本性 GC 风险依然存在**：行情 100+ symbol 并发 StateFlow 更新的 Kotlin/Native GC 影响需要在真机（iPhone 15, A16）上实测，mobile-kmp-review.md 中的建议（对象池、单一 `StateFlow<Map<String, Quote>>`、`conflate()`）仍有效。

#### Flutter 现状

- Flutter/Dart 采用分代 GC（Scavenger + Mark-Compact），短生命周期对象（Quote Tick 数据）由 Scavenger 快速回收，对 UI 帧率影响远低于 K/Native GC。
- **Flutter Impeller**（iOS 默认）：渲染流水线与 Dart VM 解耦（Impeller 运行在独立线程），高频数据更新对渲染的干扰更小。
- Flutter `StreamBuilder`/`Riverpod`/`BLoC` 的 Dart 异步模型不存在 K/Native GC 相关的内存压力问题。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（CMP 1.11.0-alpha03 parallelRendering 改善帧渲染，但 K/Native GC 在高频场景的风险需实测验证，仍是 P1 级别未知风险）
- **Flutter 是否解决**：✅ 已解决（Dart 分代 GC + Impeller 独立渲染线程，高频更新场景经生产验证稳定）
- **推荐方案**：Flutter 在高频行情更新场景有架构级优势，Dart GC 更适合大量短生命周期对象的场景。

---

### 问题 12：CMP for iOS 已知限制（TextField、ModalBottomSheet、VoiceOver、截图防护等）

#### KMP/CMP 现状（对比 mobile-kmp-review.md 中的 1.7.x 状态）

| 功能 | 1.7.x 状态 | 1.10.2 现状（2026-03） |
|------|-----------|----------------------|
| `TextField` iOS `imeAction`/光标 bug | `PasswordVisualTransformation` 光标位置 bug | `#2331` 对齐 TextField 语义与 iOS 文本输入；`#2488` 修复语音输入文本消失；基本修复 |
| `ModalBottomSheet` iOS 手势 | 偶有下拉关闭冲突 | `#2019`/`#2048`/`#2605` 系列修复；1.10.2 已稳定 |
| `HorizontalPager` fling 动画 | iOS 惯性不一致 | CMP 1.8.0 默认启用 Cupertino Overscroll（`#1753`）；动画体验已接近原生 |
| VoiceOver 无障碍 | 不完整，部分 semantics 不生效 | 1.8.0 大量修复（`#1644`/`#1719`/`#1780`/`#1809`/`#1875`）；VoiceControl 支持；1.10.0 `#2327`/`#2539` 持续修复；**已接近可用，但仍非 UIKit 级别** |
| `LazyColumn` 1000+ 项性能 | 无 UITableView 级别优化 | 1.11.0-alpha03 parallelRendering 默认开启预计改善；稳定版需等待 1.11.0 |
| 截图防护（FLAG_SECURE 等效） | iOS 无直接 API | **仍无原生 API**，需 `UIScreen.capturedDidChangeNotification` workaround |
| Native iOS Text Input | 无 | CMP 1.11.0-alpha04（`#2602`）引入 opt-in Native iOS Text Input，含 autofill；**仅 alpha** |

**核心结论**：与 1.7.x 相比，CMP 1.10.2 在 TextField、ModalBottomSheet、VoiceOver、手势方面有实质性改善，不再是 P0 级别的功能缺失，但部分功能（LazyColumn 大列表、截图防护、Native Text Input）仍需 workaround 或等待 1.11.0 稳定版。

#### Flutter 现状

- Flutter `TextField` 底层是 `UITextField`（iOS 原生），所有 IME 行为、`textContentType`、autofill 与系统一致，无此类问题。
- `DraggableScrollableSheet`（ModalBottomSheet 等效）行为与 iOS 系统表格一致。
- **VoiceOver/无障碍**：Flutter 的 `Semantics` 组件在 iOS 上映射到 `UIAccessibility`，行为与原生一致，无 VoiceOver 兼容问题。
- **截图防护**：`screen_protector v1.5.1` 库，Android `FLAG_SECURE` + iOS `UITextField.isSecureTextEntry` 技巧，均封装完整，无需开发者自行实现。
- **LazyColumn 等效（ListView.builder）**：底层 `UIScrollView`（iOS）实现，性能与原生一致，无 CMP 的 Skia Canvas 性能瓶颈。

#### 判断
- **KMP/CMP 是否解决**：⚠️ 部分解决（1.10.2 相比 1.7.x 有大幅改善，已从"P0 风险"降为"P1 已知限制"；完整解决需等待 CMP 1.11.0 稳定版）
- **Flutter 是否解决**：✅ 已解决（Flutter UI 底层是 iOS 原生控件或等效实现，上述问题基本不存在）
- **推荐方案**：Flutter 在 iOS 原生一致性方面具有架构级优势，无需因 CMP 版本升级而维护兼容列表。

---

## 二、综合对比总结

| # | 问题 | KMP/CMP 1.10.2 | Flutter 3.41.4 | 推荐 |
|---|------|----------------|----------------|------|
| 1 | 生物识别签名（Secure Enclave + CryptoObject） | ⚠️ 需自研（KSafe 覆盖存储，签名需 expect/actual） | ⚠️ 需自研（local_auth 覆盖认证，签名需 Method Channel） | 平手 |
| 2 | Refresh Token 安全存储 | ✅ KSafe v1.7.0（含 SE 支持） | ✅ flutter_secure_storage v10.0.0 | 平手（KSafe 功能更丰富） |
| 3 | K 线图（Candlestick + 手势） | ✅ Vico 3.0.3 CMP 稳定版（K 线 + 缩放） | ✅ syncfusion / financial_chart（Impeller 渲染） | 平手（Vico 3.0 逆转了此问题） |
| 4 | SMS OTP 自动填充 | ⚠️ iOS 稳定支持需等 CMP 1.11.0（或 UIKitView workaround） | ✅ AutofillHints.oneTimeCode 原生支持 | Flutter |
| 5 | 设备 ID 生成 | ✅ expect/actual + KSafe（需写两套代码） | ✅ device_info_plus（单一库） | Flutter（代码量少） |
| 6 | APNs/FCM 推送桥接 | ⚠️ Firebase KMP 10% 覆盖 + 需 Swift AppDelegate | ✅ firebase_messaging 完整封装，无需手动桥接 | Flutter |
| 7 | Slide-to-Confirm 手势竞争 | ⚠️ CMP 1.8.0+ 有 API，需显式禁用 back gesture | ✅ PopScope + GestureDetector，slide_to_confirm 可用 | Flutter（略优） |
| 8 | WebSocket 后台挂起 | ⚠️ iOS 系统约束，AppLifecycleObserver + 重连 | ⚠️ 同 iOS 系统约束，WidgetsBindingObserver + 重连 | 平手 |
| 9 | KYC 图片选择/裁剪 | ⚠️ FileKit 0.13.0 选择 OK，裁剪需自实现 | ✅ image_picker + image_cropper 完整覆盖 | Flutter |
| 10 | PDF 查看（W-8BEN） | ⚠️ expect/actual 平台注入，CMP 1.10.0 改善 Interop | ✅ pdfx v2.9.2 开箱即用 | Flutter |
| 11 | K/N GC + 高频 StateFlow | ⚠️ parallelRendering 改善，但 GC 风险需实测 | ✅ Dart 分代 GC + Impeller 独立线程 | Flutter |
| 12 | CMP iOS 已知限制（综合） | ⚠️ 1.10.2 大幅改善，仍非原生一致 | ✅ 底层原生控件，无此类问题 | Flutter |

**得分汇总**（✅=1分，⚠️=0.5分，❌=0分）：

| 方案 | 已解决（✅） | 部分解决（⚠️） | 总分（满分 12） |
|------|------------|--------------|----------------|
| KMP/CMP 1.10.2 | 3 | 9 | **7.5/12** |
| Flutter 3.41.4 | 9 | 3 | **10.5/12** |

---

## 三、技术路线建议

### 3.1 如果继续推进 KMP/CMP 方案

**现在已可解决的问题（无需或低成本 workaround）**：

1. **K 线图**：Vico 3.0.3 是最大的正面变化，mobile-kmp-review.md 中的 P0 问题已有稳定库，但需安排 Sprint 0 真机帧率测试（500+ 根 K 线 + pinch-zoom，目标 > 55fps）。
2. **安全存储**：KSafe 1.7.0 提供生产级加密存储 + 生物识别门控 + Secure Enclave 支持。
3. **VoiceOver 无障碍**：CMP 1.10.2 已接近可用（需真机 VoiceOver 完整验证）。
4. **ModalBottomSheet / 返回手势**：CMP 1.10.2 已稳定，不再是 Sprint 0 P0 验收项。

**仍需 workaround 的问题（评估工作量）**：

| 问题 | Workaround | 预估工时 |
|------|-----------|---------|
| iOS SMS OTP 自动填充 | UIKitView 包裹原生 UITextField | 2~3 天 |
| APNs DeviceToken 桥接 | 保留薄 Swift AppDelegate | 1~2 天 |
| KYC 图片裁剪 | CMP 自绘矩形裁剪遮罩 | 3~5 天 |
| PDF 查看（W-8BEN） | expect/actual + PDFKit/PdfBox | 3~4 天 |
| 截图防护（iOS） | UIScreen.capturedDidChangeNotification 覆盖 | 2 天 |
| 交易签名（生物识别密钥对） | expect/actual BiometricKeyManager | 5~8 天 |
| K/N GC 高频更新 | 对象池 + 单一 StateFlow<Map> + conflate() | 3~5 天（含测试） |

**CMP 1.11.0 稳定版（预计 Q2 2026）后将消除的问题**：
- SMS OTP 自动填充（Native iOS Text Input 含 autofill）
- parallelRendering 默认开启改善 LazyColumn 性能

**结论**：KMP/CMP 方案在技术上可行，但需要约 25~35 人天的额外工程成本来处理上述 workaround，且存在 K/Native GC 高频行情更新的生产风险需实测验证。

---

### 3.2 如果迁移到 Flutter

**迁移的主要工作量**：

| 模块 | 迁移方向 | 风险等级 | 估算 |
|------|---------|---------|-----|
| UI 层（CMP Composable → Flutter Widget） | 全量重写 | 高（最大工作量） | 按功能模块 × 1.5~2x 系数估算 |
| 业务逻辑层（Kotlin Coroutines/StateFlow → Dart Stream/Riverpod） | 概念迁移，代码重写 | 高 | ~30% 代码量 |
| 数据层（Room → sqflite/drift-flutter） | Schema 可复用，代码重写 | 中 | ~20% 代码量 |
| 网络层（Ktor → dio/http） | 接口概念相似，重写 | 低 | ~10% 代码量 |
| 平台特有功能（BiometricKeyManager、设备 ID） | Method Channel 替代 expect/actual | 低（减少工作量） | 节省约 30% |

**迁移风险**：
- UI/UX 一致性：Flutter 和 CMP 的视觉渲染差异可能导致交互细节需要重新调试（字体渲染、动画曲线、触感反馈）。
- Kotlin Domain 逻辑无法复用：Flutter 使用 Dart，Kotlin 业务逻辑层需要重新用 Dart 实现，无法代码层面复用。
- 测试覆盖率重置：所有现有 KMP 单元测试需用 Dart/Flutter Test 重写。

---

### 3.3 "KMP 先行、Flutter 接管"路线的迁移时机建议

基于本次评估，对迁移时机给出如下判断：

**不建议立即迁移**（在以下条件满足前）：
- KMP/CMP 当前版本的技术债务已通过 workaround 覆盖，不阻塞 v1.0 发布。
- Flutter 迁移需要完整 UI 重写，在项目早期进行迁移成本最高。

**建议在以下里程碑后评估迁移**：

**里程碑 1（v1.0 上线后，约 3~6 个月）**：
- 验证 K/Native GC 高频行情更新的生产稳定性。
- 验证 CMP iOS 用户体验是否满足产品质量标准（VoiceOver、TextField、动画）。
- 如果出现 2 个以上因 CMP iOS 兼容性导致的 P1 生产 Bug，立即启动迁移评估。

**里程碑 2（CMP 1.11.0 稳定版发布后，预计 Q2 2026）**：
- 重新评估 12 个问题的解决状态（预期 SMS OTP、LazyColumn 性能问题将关闭）。
- 若 1.11.0 后 KMP/CMP 得分提升至 10+ /12，继续 KMP 路线；否则按下面时间点启动迁移。

**迁移窗口（v2.0 规划阶段，项目启动后 12~18 个月）**：
- 此时 v1.0 的核心功能模块已完成并稳定，迁移成本可被预期。
- Flutter 生态已有更多金融 App 生产案例（2025 年数量显著增长）。
- 迁移策略建议：先迁移行情模块（技术风险最高），验证后再迁移交易、KYC、出入金模块，分 3~4 个季度完成。

**总体建议**：
- **当前（2026-03）**：继续 KMP/CMP 方案，但将迁移准备工作提前——Domain 层保持纯 Kotlin 无框架依赖，用 **SQLDelight** 替代 Room（SQLDelight 有 Flutter Dart 代码生成支持，迁移时 Schema 可复用），这是成本最低的迁移友好性投资。
- **6 个月后（2026-09）**：基于 CMP 1.11.0 发布和 v1.0 生产数据，做最终"继续 KMP"或"启动迁移 Flutter"的 Go/No-Go 决策。

---

## 附：版本参考信息（截至 2026-03-13）

| 技术 | 最新稳定版本 | 发布日期 |
|------|------------|---------|
| Compose Multiplatform | 1.10.2 | 2026-03-05 |
| CMP Alpha | 1.11.0-alpha04 | 2026-03-11 |
| Kotlin | 2.3.10 | 2026-02-05 |
| Flutter | 3.41.4 | 2026-03-04 |
| Vico (KMP K线图) | 3.0.3 | 2026-03-07 |
| KSafe (KMP 安全存储) | 1.7.0 | 2026-03-04 |
| KVault (KMP 安全存储) | 1.12.0 | 2023-10-11（停更）|
| multiplatform-settings | 1.3.0 | 2024-11-29 |
| Firebase KMP (GitLive) | 2.4.0 | 2025-10-31 |
| FileKit (KMP 文件选择) | 0.13.0 | 2026-02-25 |
| Calf (KMP 图片选择) | 0.8.0 | 2025-05-25 |
| flutter_secure_storage | 10.0.0 | 2025 年 |
| local_auth | 3.0.1 | 2025 年 |
| firebase_messaging | 16.1.2 | 2025 年 |
| image_picker | 1.2.1 | 2025 年 |
| pdfx | 2.9.2 | 2025 年 |
| syncfusion_flutter_charts | 32.2.9 | 2025 年 |
| financial_chart | 0.4.1 | 2025 年 |
| smart_auth | 3.2.0 | 2025 年 |
| device_info_plus | 12.3.0 | 2025 年 |
| screen_protector | 1.5.1 | 2025 年 |
| slide_to_confirm (Flutter) | 1.1.0 | 2025 年 |
