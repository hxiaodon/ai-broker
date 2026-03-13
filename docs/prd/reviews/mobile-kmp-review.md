# 移动端 KMP/CMP 技术评审报告

> ⚠️ **此报告已过期**：项目已于 2026-03-13 正式决策采用 **Flutter** 技术路线，KMP/CMP 方案不再推进。
> - 技术选型依据：[mobile-tech-comparison.md](./mobile-tech-comparison.md)
> - Flutter 落地方案：[../../mobile-flutter-tech-spec.md](../../mobile-flutter-tech-spec.md)
>
> 保留此文件仅用于记录 KMP/CMP 方案的技术风险识别过程。

**技术路线**: Kotlin Multiplatform + Compose Multiplatform (KMP/CMP)（**已废弃**）
**评审日期**: 2026-03-13
**目标平台**: iOS 16+、Android API 26+
**覆盖模块**: 认证(01)、KYC(02)、行情(03)、交易(04)、出入金(05)、设置(08)

---

## 一、生物识别 expect/actual 实现：iOS Secure Enclave 密钥绑定缺失

**严重程度**: P0

**问题描述**

PRD-01（5.2）和 PRD-04（4.2）要求生物识别与硬件密钥对绑定，用于交易签名（挑战-响应机制）：iOS 侧需要 `LAContext` + `SecKeyCreateRandomKey` 将私钥绑定到 Secure Enclave，并指定 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + `kSecAttrTokenIDSecureEnclave`；Android 侧需要 `KeyPairGenerator` 配合 `KeyGenParameterSpec.Builder` + `setUserAuthenticationRequired(true)` + `BiometricPrompt.CryptoObject`。

两平台的密钥生成、签名流程、错误类型均存在根本性差异，无法通过一个简单的 `expect/actual` 函数封装完成。当前 KMP 生态中 **没有** 成熟的跨平台生物识别签名库能满足硬件级密钥的要求。

**建议解决方案**

1. 定义粗粒度的 `expect/actual` 接口，将"密钥生成"、"签名"、"生物识别确认"三个阶段分别建模：
   ```kotlin
   // commonMain
   expect class BiometricKeyManager {
       suspend fun generateKeyPair(keyAlias: String): PublicKeyBytes
       suspend fun signChallenge(keyAlias: String, challenge: ByteArray): SignatureBytes
       fun isKeyInvalidated(keyAlias: String): Boolean
   }
   ```
2. iOS `actual` 实现使用 `Security.framework` + `LocalAuthentication.framework` 通过 Kotlin/Native 的 `@ObjCInterop` 互操作调用；Android `actual` 实现使用 `androidx.biometric:biometric:1.2.x` 配合 `KeyStore`。
3. 将两套实现封装进独立的 Gradle 模块（`:core:biometric`），由专人维护，严禁业务层直接调用平台 API。

---

## 二、Refresh Token 安全存储：HttpOnly Cookie 方案在原生 App 中不可行

**严重程度**: P0

**问题描述**

PRD-01（5.1）规定 Refresh Token 存储于 "HttpOnly + Secure + SameSite=Strict Cookie"，这是 Web 浏览器的方案，**在原生移动 App 的 HTTP 客户端（Ktor `HttpClient`）中 HttpOnly Cookie 无任何安全意义**：Ktor 的 `HttpCookies` 插件在内存或文件中透明存储所有 Cookie，没有与系统 Keychain/Keystore 的集成，Token 完全可被读取。

**建议解决方案**

1. 将 Refresh Token 改为以 **opaque token** 形式由服务端返回 JSON body，客户端显式写入平台安全存储：
   - iOS `actual`：使用 `Security.framework` 的 `SecItemAdd` 写入 Keychain，`kSecAttrService` 区分不同 Token 类型。
   - Android `actual`：使用 `EncryptedSharedPreferences`（`androidx.security:security-crypto:1.1.0-alpha06`），底层由 Android Keystore 保护 AES256-SIV 密钥。
2. 推荐库：**KVault**（`com.liftric:kvault`）或 **multiplatform-settings**（`com.russhwolf:multiplatform-settings-no-arg`）提供跨平台安全存储抽象，但需注意 KVault 的 iOS 实现依赖 Keychain，Android 依赖 `EncryptedSharedPreferences`，需验证其对 `setUserAuthenticationRequired` 生物识别绑定的支持情况（KVault 默认**不**绑定生物识别，需自行扩展）。
3. **PRD 必须更新**：删除 "HttpOnly Cookie" 说明，改为 "原生客户端使用平台安全存储（iOS Keychain / Android EncryptedSharedPreferences）"。

---

## 三、K 线图（CandleStick Chart）：CMP Canvas 在 iOS 上有性能和 API 风险

**严重程度**: P0

**问题描述**

PRD-03（3.3）要求支持 K 线图、双指缩放、长按十字线、实时 WebSocket 更新。PRD 中的技术栈建议 iOS 使用 `Swift Charts`、Android 使用 `MPAndroidChart`，这两者在 KMP/CMP 路线下**均不可用**。

当前 CMP 的 Canvas API（`androidx.compose.ui.graphics.Canvas` 的 multiplatform 版本，通过 `skia/skiko` 渲染）在 iOS 上存在以下已知问题（截至 Compose Multiplatform 1.7.x / Compose 1.7 for iOS）：
- `drawPath` 和复杂 `ClipPath` 在大数据量（500+ 根 K 线）下 iOS 渲染帧率可能跌至 30fps 以下，JVM 侧 GC 压力与 iOS ARC 内存模型差异导致频繁内存峰值。
- `pointerInput` 多点触控手势在 iOS 上的识别精度（双指 pinch-zoom）与 UIKit `UIPinchGestureRecognizer` 存在差距，竞争状态未完全解决（CMP issue #3514）。
- 目前没有可直接用于生产的跨平台 K 线图库（`MPAndroidChart` 无 KMP 版本，`Vico` 仅 Android）。

**建议解决方案**

1. 短期（Phase 1）：使用 **纯 CMP Canvas 自绘**，K 线数量限制在当前视口内（最多 200 根），启用 `remember { mutableStateOf(...) }` + `derivedStateOf` 避免全量重组。使用 `skiko` 的 `Canvas.drawRect/drawLine` 而非 `Path` 以减少绘制开销。
2. 多点触控：使用 `Modifier.pointerInput` + `awaitEachGesture` + `detectTransformGestures` 实现 pinch-zoom，iOS 实测验证必须作为 P0 验收项。
3. 长期（Phase 2）：评估 **KMP-Charts**（社区库，维护较活跃）或通过 `expect/actual` 在 iOS 侧注入 `UIViewRepresentable` 包裹的原生 `SwiftUI.Chart`，Android 侧注入 `AndroidView` 包裹的 `MPAndroidChart`，通过共享数据模型实现业务层统一。
4. 必须在 Sprint 1 开始前用真实设备（iPhone 13 及以上）跑 500 根日 K 线的性能基准测试，帧率不得低于 55fps。

---

## 四、SMS OTP 自动填充：iOS 与 Android 机制差异大，需两套 actual 实现

**严重程度**: P1

**问题描述**

PRD-01（3.3）要求"iOS SMS 自动填充，Android SMS Listener"。两者机制截然不同：
- **iOS**：通过 `UITextContentType.oneTimeCode` 属性提示系统自动识别短信中的 OTP，无需任何权限，但需要原生 `UITextField`，CMP 的 `TextField` 在 iOS 上底层是 `UIKitTextField`，是否正确传递 `textContentType` 取决于 CMP 版本（1.6.x 后已支持，但需通过 `PlatformTextInputPlugin` 注入，配置较繁琐）。
- **Android**：需要 `com.google.android.gms:play-services-auth:21.x` 的 SMS Retriever API 或 `SmsRetrieverClient`，涉及后台 `BroadcastReceiver` 注册和 `AndroidManifest.xml` 配置，这些完全不在 CMP composable 层，需要 Android-specific 平台代码。

**建议解决方案**

1. 在 KMP 的 `androidMain` 中注册 `SmsRetrieverClient`，通过 `BroadcastReceiver` 接收短信并将 OTP 写入共享的 `StateFlow<String?>`，UI 层通过 `collectAsStateWithLifecycle()` 监听并自动填充。
2. 在 KMP 的 `iosMain` 中，通过 `expect/actual` 的 `OtpFieldConfig` 数据类携带 `isOneTimeCode: Boolean`，并在 iOS `actual` 侧通过 `UIKitView` 包裹原生 `UITextField` 并设置 `textContentType = .oneTimeCode`，或等待 CMP 官方稳定支持 `KeyboardOptions(autoFillHints = listOf(AutofillType.SmsOtpCode))` 的 iOS 实现（目前在 CMP 1.7.x 中仍为实验性 API）。
3. Android 的 `hash` 值（SMS Retriever 需要 App 签名哈希追加在短信末尾）必须在 CI/CD 流水线中与后端短信服务配置联动，不可遗漏。

---

## 五、设备 ID 生成：两平台 API 差异及隐私合规风险

**严重程度**: P1

**问题描述**

PRD-01（5.4）要求设备指纹包含 "OS 版本、设备型号、App 版本（不使用 IDFA/GAID）"。在 KMP 中：
- **iOS**：`UIDevice.current.identifierForVendor` 是唯一可靠的持久设备标识符，但 App 卸载重装后会变更，且不同 App 间不一致。`UIDevice.current.model` 只返回 "iPhone"，不含具体型号。
- **Android**：`Settings.Secure.ANDROID_ID` 在 Android 8+ 是应用签名作用域内的唯一标识，Factory Reset 后变更。

两平台均无统一的"永久不变"设备 ID，且上述方案在 KMP `commonMain` 中无法直接调用。

**建议解决方案**

1. 采用**生成一次、永久存储**的策略：首次启动时生成 UUID v4，用平台安全存储（Keychain/EncryptedSharedPreferences）持久化，作为逻辑设备 ID，与 `UIDevice.identifierForVendor` 或 `ANDROID_ID` 作为辅助信息共同构建设备指纹。
2. `expect/actual` 定义 `DeviceInfoProvider`：
   ```kotlin
   // commonMain
   expect fun getDeviceInfo(): DeviceInfo  // 包含 osVersion, model, persistentDeviceId
   ```
3. iOS `actual` 通过 Kotlin/Native 调用 `UIKit.UIDevice` 和 `Foundation.ProcessInfo`；Android `actual` 通过 `android.os.Build`。
4. 此方案需与 PRD 安全规格对齐，确认设备 ID 生命周期（App 卸载后是否需保持一致）对于远程注销功能的影响。

---

## 六、推送通知双平台集成：APNs DeviceToken 与 FCM Token 统一上报

**严重程度**: P1

**问题描述**

PRD-01（八）、PRD-04（成交通知）、PRD-05（资金状态通知）均依赖推送通知。KMP 中 APNs（iOS）和 FCM（Android）的集成方式完全不同：
- **iOS APNs**：需要在 AppDelegate 中实现 `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` 回调获取 DeviceToken（`Data` 类型），这是 UIKit 的回调，在 Compose Multiplatform iOS App 入口（`ComposeUIViewController`）中**没有对应的 KMP 生命周期钩子**。
- **Android FCM**：通过 `FirebaseMessaging.getInstance().token` 协程获取，且 `FirebaseMessagingService` 的 `onNewToken(token: String)` 回调需要在 `AndroidManifest.xml` 中注册 Service。

当前 CMP for iOS 使用 `@UIApplicationDelegateAdaptor` 等 SwiftUI 桥接机制，但 KMP 项目的 iOS 入口通常是纯 Kotlin 的 `MainViewController.kt`，需要额外的 Swift 桥接文件才能处理 AppDelegate 回调。

**建议解决方案**

1. iOS 侧保留一个最薄的 Swift `AppDelegate`（或 `UIApplicationDelegate` extension），仅用于接收 APNs DeviceToken 并通过 `NotificationBridge`（KMP expect/actual）传递给 Kotlin 层：
   ```swift
   // Swift (iosApp/AppDelegate.swift)
   func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       NotificationBridgeKt.setDeviceToken(deviceToken.hexString)
   }
   ```
2. 共享层定义 `expect class NotificationTokenRepository`，在 `commonMain` 中负责将 Token 上报至后端 `/v1/devices/push-token`。
3. 推送通知的前台展示（App 在前台时收到推送的处理）在 CMP 中需要通过 `UNUserNotificationCenter.delegate`（iOS）和 `FirebaseMessagingService.onMessageReceived`（Android）分别处理，不可在 CMP UI 层统一捕获。
4. 安全通知（新设备登录）要求"不可关闭"，须在 iOS 侧申请 `UNAuthorizationOptions.critical` 权限（需 Apple 授权，通常不批准），退而求其次，应使用 APNs `priority: 10` + `apns-push-type: alert` 保证送达率。

---

## 七、Slide-to-Confirm 手势组件：CMP 手势 API 在 iOS 上的滑动识别冲突

**严重程度**: P1

**问题描述**

PRD-04（交易确认）要求"滑动距离 > 80% 才触发提交，防误触"。在 CMP 中实现 Slide-to-Confirm 手势组件时，iOS 上存在以下风险：
- CMP 的 `Modifier.draggable()` 或 `detectHorizontalDragGestures` 与 iOS 系统的返回手势（从屏幕左边缘右滑）存在**手势竞争**，可能导致用户在尝试完成滑动确认时误触发页面返回。
- iOS 的手势识别系统（`UIGestureRecognizer` 优先级链）与 CMP 的 Compose Hit-Testing 机制不完全一致，边缘手势的识别优先级需要通过 `UIViewController.navigationController?.interactivePopGestureRecognizer` 显式处理，这需要在 iOS `actual` 侧注入原生代码。

**建议解决方案**

1. 交易确认页进入时，在 iOS 侧通过 `expect/actual` 提供 `DisableSystemGestureScope` 组件，iOS `actual` 禁用 `navigationController.interactivePopGestureRecognizer`，页面退出后恢复：
   ```kotlin
   // iosMain actual
   actual fun DisableEdgeSwipeBack(content: @Composable () -> Unit) {
       // 通过 UIKitView/UIViewController 互操作禁用 popGesture
   }
   ```
2. 滑块组件应使用 `Modifier.pointerInput(Unit) { detectDragGesturesAfterLongPress(...) }` 而非 `draggable()`，前者对手势竞争有更好的控制能力。
3. 此组件必须作为独立 UI 测试用例，在 iPhone 真机上验证：从左边缘区域开始的滑动是否被系统手势截获，从非边缘区域的滑动是否正确触发确认逻辑。

---

## 八、WebSocket 后台策略：iOS App 切换后台时连接被系统杀断

**严重程度**: P1

**问题描述**

PRD-03（6.1）依赖 WebSocket 推送实时行情，PRD-04 依赖 WebSocket 推送订单状态更新。在 iOS 上，App 进入后台后：
- **iOS 后台网络策略**：系统在 App 进入后台约 30 秒后会暂停网络活动，长连接 WebSocket 被挂起或关闭。
- **Ktor WebSocket**（`io.ktor:ktor-client-websockets`）在 KMP 的 iOS 引擎（`Darwin` 引擎，基于 `NSURLSession`）下，后台网络执行权限受 `UIBackgroundModes` 控制，默认配置下**无法在后台维持 WebSocket 连接**。
- PRD-03（6.4）要求行情延迟 < 500ms，但行情数据在后台不需要实时维持。真正需要关注的是 **订单状态变更**（成交通知），PRD 中通过 FCM/APNs 推送解决，但 WebSocket 连接重建（App 回到前台）的延迟和数据补全策略 PRD 没有规定。

**建议解决方案**

1. **App 生命周期感知的连接管理**：在 `commonMain` 中定义 `AppLifecycleObserver`（`expect/actual`），iOS `actual` 监听 `UIApplication.willResignActiveNotification` / `didBecomeActiveNotification`，Android `actual` 使用 `ProcessLifecycleOwner.get().lifecycle`：
   ```kotlin
   expect class AppLifecycleObserver {
       val state: StateFlow<AppLifecycleState>
   }
   ```
2. **重连策略**：App 回到前台时，WebSocket 立即执行指数退避重连（初始延迟 0ms，最大 30s）。重连成功后，通过 REST 快照接口（`GET /v1/market/quotes`）补全期间丢失的最新价格，避免显示过期数据。
3. **订单状态**：依赖 FCM/APNs 推送 + App 前台后主动 `GET /v1/orders` 轮询，不依赖 WebSocket 保障后台可靠性。
4. 在 iOS 侧明确**不** 申请 `background-fetch` 或 `voip` 背景模式来维持 WebSocket，避免 App Store 审核风险。

---

## 九、KYC 文件选择与上传：跨平台文件选择器实现复杂

**严重程度**: P1

**问题描述**

PRD-02（Step 2）要求用户上传证件图片（JPEG/PNG/HEIC），图片质量 ≥ 720p，支持 HEIC 格式，文件 < 5MB。在 KMP 中：
- **iOS**：需要调用 `PHPickerViewController`（相册）或 `UIImagePickerController`（相机），均为 UIKit/SwiftUI 组件，CMP 中无直接等价物，需要通过 `UIKitView` 或 Interop API 包裹。HEIC 的压缩转换需要调用 `ImageIO.framework`。
- **Android**：需要 `ActivityResultContracts.PickVisualMedia()`（Android 13+）或 `ACTION_PICK`（兼容旧版），以及 `CameraX` 或 `MediaStore` 接口拍照。
- 两平台图片裁剪（证件四角不可遮挡）均需要自定义裁剪 UI 或第三方库，CMP 中没有成熟的跨平台图片裁剪库。

**建议解决方案**

1. 文件选择使用 `expect/actual` 的 `ImagePickerLauncher`，iOS `actual` 通过 `PHPickerViewController` 实现，Android `actual` 通过 `rememberLauncherForActivityResult`。
2. 推荐参考 **Calf**（`com.mohamedrejeb.calf`）或 **KMPFile**（`dev.zwander:kotlin-file-utils`）等社区库，但需评估其对 HEIC 的支持情况（Calf 支持图片选择但 HEIC 转换需额外处理）。
3. 图片裁剪 UI 在 Phase 1 可用 CMP 自绘简单遮罩（矩形裁剪框），复杂裁剪 Phase 2 再引入平台原生裁剪组件。
4. HEIC 在 Android 上需要 `androidx.heifwriter:heifwriter:1.1.0-alpha02`（API 28+）解码，低版本 Android 需要服务端接受 HEIC 后自行转码，客户端上传前不做格式转换。

---

## 十、PDF 查看（W-8BEN 原件）：KMP 中无跨平台 PDF 方案

**严重程度**: P1

**问题描述**

PRD-08（3.2）要求"以内嵌 PDF 查看器展示已签署的 W-8BEN 原件"。在 KMP/CMP 中：
- **iOS**：原生 PDF 渲染使用 `PDFKit.PDFView`（iOS 11+），在 CMP 中需要 `UIKitView` 包裹。
- **Android**：系统没有内置 PDF 渲染 View，需要 `com.github.barteksc:android-pdf-viewer`（基于 PdfiumAndroid，已停维）或 `AndroidPdfViewer`，或使用 `PdfRenderer`（API 21+，需自行实现翻页、缩放 UI）。
- CMP 没有跨平台 PDF 渲染 Composable，两侧均需要 `expect/actual` 注入原生 View。

**建议解决方案**

1. 通过 `expect/actual` 定义 `PdfViewer(url: String)` Composable，iOS `actual` 用 `UIViewControllerRepresentable` 包裹 `PDFViewController`，Android `actual` 使用 `AndroidView` 包裹 `PdfRenderer` 自绘或集成 `com.tom_roush:pdfbox-android:2.0.27.0`（Apache PDFBox 的 Android 移植，维护较好）。
2. 如果 W-8BEN PDF 体积较小（< 1MB），可降级为 **WebView 加载 PDF URL** 方案（iOS `WKWebView` 支持 PDF 渲染，Android `WebView` 需要 Google Doc Viewer 绕过），实现成本低但体验较差。
3. 不建议使用系统分享打开 PDF（跳出 App 到系统 PDF 查看器），因为涉及含 TIN 的敏感税务文件，需防止截图和分享（应用 `FLAG_SECURE` 等效保护）。

---

## 十一、Kotlin/Native 内存模型与 GC：iOS 上高频 StateFlow 更新的性能风险

**严重程度**: P1

**问题描述**

PRD-03（6.4）要求行情推送 P99 < 500ms，行情列表需要对数十甚至上百个 Symbol 的 `StateFlow` 进行并发更新。在 Kotlin/Native（iOS 侧）上：
- Kotlin/Native 从 1.9.20 起已采用与 JVM 兼容的 **新内存模型**（无需 `@SharedImmutable`、`freeze()` 等），但其 GC 策略与 JVM 不同：Kotlin/Native 使用**引用计数 + 追踪 GC 混合模型**，在大量短生命周期对象（每个 Tick 产生的 `Quote` 数据类）高频创建时，GC 暂停可能导致 UI 卡顿。
- `StateFlow` 在共享层高频发射（< 100ms 间隔）时，iOS 侧 Coroutine 调度器（`Dispatchers.Main` 映射到 `RunLoop.main`）的唤醒开销高于 Android（Android 的 `Looper` 开销更低）。

**建议解决方案**

1. 行情更新使用 **对象池**（`ArrayDeque` + `recycleQuote()`），避免每个 Tick 分配新的 `Quote` 对象。
2. Watchlist 行情订阅使用单一 `StateFlow<Map<String, Quote>>`（整个 Map 的 snapshot），而非每只股票独立 `StateFlow`，减少 iOS 端 Coroutine 调度唤醒次数。在 `LazyColumn` 中通过 `key = { it.symbol }` 限制重组范围。
3. 在 Sprint 1 前必须在 iPhone 15（A16 Bionic）上跑 100 只股票并发更新的 baseline 测试，使用 Xcode Instruments 的 Allocations 和 Time Profiler 工具分析 GC 影响。
4. 若 GC 暂停超过 16ms（导致掉帧），考虑将行情数据处理下沉至 `Dispatchers.Default` 协程，仅将 UI 更新发射到 `Dispatchers.Main`，利用 `conflate()` 算子丢弃来不及渲染的中间帧。

---

## 十二、CMP for iOS 成熟度：当前版本（1.7.x）已知限制清单

**严重程度**: P1

**问题描述**

截至 Compose Multiplatform 1.7.x（对应 Kotlin 2.1.x），iOS 平台仍存在以下影响本项目的已知限制，PRD 中涉及的功能需要逐一确认可行性：

| 功能 | CMP iOS 状态 | PRD 关联 |
|------|------------|---------|
| `TextField` 的 `imeAction` / `keyboardOptions` | 基本稳定，但 `PasswordVisualTransformation` 在 iOS 有光标位置 bug（1.7.0 修复中）| PRD-01 OTP 输入、PRD-05 银行卡号输入 |
| `ModalBottomSheet` | 1.6.x 后稳定，但与 iOS 系统手势（下拉关闭）交互偶有冲突 | PRD-04 委托确认弹窗、PRD-07 订单详情底部抽屉 |
| `Pager`（HorizontalPager）| stable，但 iOS 上 fling 动画与 UIKit ScrollView 惯性不一致 | PRD-03 K 线/新闻/基本面 Tab、PRD-02 7 步 KYC 进度 |
| 无障碍（Accessibility）| iOS 上 VoiceOver 支持不完整，`semantics` modifier 部分属性不生效 | 合规风险：ADA 可访问性要求 |
| `LazyColumn` 性能 | iOS 上在超过 1000 项时滚动性能下降（无 `UITableView` 级别优化）| PRD-03 行情列表、PRD-07 订单历史 |
| 截图防护（FLAG_SECURE 等效）| iOS 无直接 API，需 `UITextField.isSecureTextEntry` 技巧 | PRD 安全规格（敏感页面防截图）|

**建议解决方案**

1. 为上述每个功能点建立独立的 Spike 任务，在 Sprint 0 中用真机验证，记录版本和 workaround。
2. `ModalBottomSheet` 的 iOS 手势冲突：在底部弹窗内部禁用下拉 dismiss（设置 `sheetState.confirmValueChange { it != SheetValue.Hidden }`），由明确的关闭按钮控制，避免误操作。
3. 截图防护：iOS `actual` 实现在 `UIWindow` 级别注册 `UIScreen.capturedDidChangeNotification`，截图时用空白 View 覆盖；Android `actual` 在 `Activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)` 实现。
4. 建立 CMP 版本升级的锁定机制：在 `libs.versions.toml` 中锁定 `compose-multiplatform = "1.7.3"`（或已验证的稳定版），禁止自动升级到 minor 以上版本，避免引入 iOS 回归。

---

## 十三、全局颜色主题动态切换：CompositionLocal 在 KMP 全局状态同步

**严重程度**: P2

**问题描述**

PRD-08（5.1）要求涨跌颜色方案切换后"全局 App 状态更新，所有行情页同步变更，无需重启"。在 CMP 中，颜色方案通常通过 `CompositionLocalProvider` + 自定义 `LocalColorScheme` 提供。问题在于：
- 如果行情页、订单页、详情页分布在不同的 Navigation 目标（屏幕）中，切换 `CompositionLocal` 值需要触发所有屏幕的重组。
- KMP 的 ViewModel 共享层（`commonMain` 中使用 `kotlinx-coroutines` 和 `StateFlow`）与 CMP 的 `CompositionLocal` 机制不直接兼容——`CompositionLocal` 必须在 Compose 树根部定义，而业务 ViewModel 通常在 Compose 树外部。

**建议解决方案**

1. 在 App 根 Composable（`App()` 函数）中用 `collectAsStateWithLifecycle()` 订阅 `SettingsViewModel.colorScheme: StateFlow<ColorScheme>`，将其传入 `CompositionLocalProvider(LocalAppColorScheme provides colorScheme)`，这样设置变更自动触发整个树的重组。
2. 颜色方案持久化用 `multiplatform-settings`（`com.russhwolf:multiplatform-settings`）存储到 `NSUserDefaults`（iOS）/ `SharedPreferences`（Android），首次启动时读取，避免启动闪烁（先显示默认颜色再切换）。
3. 此方案设计简单，不需要 `expect/actual`，但需注意 `collectAsStateWithLifecycle` 在 iOS 上对应 `collectAsStateWithLifecycle`（`androidx.lifecycle:lifecycle-runtime-compose`）的 KMP 版本（`org.jetbrains.androidx.lifecycle:lifecycle-runtime-compose`），需确认依赖版本兼容性。

---

## 十四、未来 Flutter 迁移路径评估：KMP/CMP 决策中的迁移障碍

**严重程度**: P2

**问题描述**

项目未来计划迁移至 Flutter，当前 KMP/CMP 选型中存在以下对迁移不友好的决策点：

| 决策/依赖 | 迁移障碍等级 | 说明 |
|---------|------------|------|
| Room 数据库（`androidx.room:room-runtime`）| 高 | Room 是 Android/KMP 特有，Flutter 侧对应 `sqflite` 或 `drift`（同一作者的 Flutter 版本），迁移时数据层需完全重写 |
| Ktor HTTP Client（`io.ktor:ktor-client-core`）| 低 | Flutter 侧有对应的 `dio`/`http`，Ktor 的接口定义可作为迁移参考，业务逻辑可复用 |
| CMP 自定义 Canvas K 线图 | 中 | Flutter 的 `CustomPainter` API 与 CMP `Canvas` API 概念相似，可按绘图逻辑移植，但手势处理需重写 |
| `expect/actual` 平台特有实现（Biometric、Keychain 等）| 中 | Flutter 有成熟的 `local_auth`、`flutter_secure_storage` 插件直接替代，迁移相对明确 |
| Kotlin 协程 + StateFlow（业务逻辑层）| 高 | Flutter/Dart 使用 `Stream`/`BLoC`/`Riverpod` 等完全不同的异步模型，业务逻辑层需重写 |
| `DataStore`（`androidx.datastore`）| 中 | Flutter 对应 `shared_preferences`，接口概念类似，迁移量小 |
| 整体架构（MVI + ViewModel）| 中 | Flutter 常用 BLoC/Cubit，MVI 状态机概念可复用，但框架代码需重写 |

**建议解决方案**

1. **现在最重要的架构决策**：严格保持 **Domain 层纯 Kotlin（无框架依赖）**，Use Case 和 Entity 不依赖任何 KMP 特有库（Ktor、Room、Coroutines 只在 Data 层和 Presentation 层），这样迁移时 Domain 逻辑可最大程度复用（作为文档参考）。
2. Room 考虑使用 **SQLDelight**（`app.cash.sqldelight`）替代，SQLDelight 有官方的 Flutter（Dart）代码生成支持（`sqldelight-flutter`），数据库 Schema 可在迁移时复用。
3. 业务逻辑层中的 `Flow` / `StateFlow` 使用接口而非具体类型暴露给 UI 层，便于未来替换为 Dart `Stream`。
4. 避免在 `commonMain` 引入任何 CMP UI 组件的直接依赖（UI 组件只在 `:feature:xxx` 模块中），保持业务层与 UI 层的模块边界清晰。

---

## 总结

| # | 模块 | 问题 | 严重程度 |
|---|------|------|---------|
| 1 | 认证(01) + 交易(04) | 生物识别 expect/actual：iOS Secure Enclave 密钥绑定需两套完整实现 | P0 |
| 2 | 认证(01) | Refresh Token 安全存储：HttpOnly Cookie 方案在原生 KMP App 中无效 | P0 |
| 3 | 行情(03) | K 线图 CMP Canvas 在 iOS 上帧率与多点触控手势风险 | P0 |
| 4 | 认证(01) | SMS OTP 自动填充：iOS `textContentType` 与 Android SMS Retriever 需两套 actual | P1 |
| 5 | 认证(01) | 设备 ID 生成：两平台 API 差异及隐私合规，需 expect/actual + 安全持久化 | P1 |
| 6 | 认证(01) + 交易(04) + 出入金(05) | APNs DeviceToken 与 FCM Token 统一上报：iOS AppDelegate 与 KMP 入口桥接 | P1 |
| 7 | 交易(04) | Slide-to-Confirm 手势：iOS 系统返回手势与 CMP 手势竞争 | P1 |
| 8 | 行情(03) + 交易(04) | WebSocket 后台被系统挂起：iOS 后台网络策略与重连/数据补全策略缺失 | P1 |
| 9 | KYC(02) | 证件图片选择/拍照：跨平台 PHPickerViewController / CameraX 需 expect/actual | P1 |
| 10 | 设置(08) | W-8BEN PDF 查看：KMP 中无跨平台 PDF 渲染方案，需平台注入 | P1 |
| 11 | 行情(03) | Kotlin/Native GC + 高频 StateFlow：iOS 上百 Symbol 并发更新的内存和帧率风险 | P1 |
| 12 | 全模块 | CMP for iOS 1.7.x 已知限制：TextField、ModalBottomSheet、截图防护等需 Sprint 0 Spike | P1 |
| 13 | 设置(08) | 颜色主题全局切换：CompositionLocal + KMP ViewModel 集成方案 | P2 |
| 14 | 全模块 | Flutter 迁移路径：Room/Coroutines 依赖是主要障碍，建议 SQLDelight + 纯 Domain 层设计 | P2 |
