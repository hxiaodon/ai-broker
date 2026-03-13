# Android 工程评审报告

**评审范围**: mobile-app-design v1 / v2 / v3-supplement + 9 个 HTML 原型页面
**评审视角**: Android 工程师（Kotlin / Jetpack Compose）
**评审日期**: 2026-03-11
**文档状态**: 初稿，待产品确认后更新工期估算

---

## 目录

1. [技术可行性评估](#1-技术可行性评估)
2. [性能关注点](#2-性能关注点)
3. [平台特性建议](#3-平台特性建议)
4. [安全实现评估](#4-安全实现评估)
5. [第三方库选型](#5-第三方库选型)
6. [KYC 流程实现复杂度](#6-kyc-流程实现复杂度)
7. [出入金模块评估](#7-出入金模块评估)
8. [交互实现评估](#8-交互实现评估)
9. [设备碎片化](#9-设备碎片化)
10. [港股适配问题](#10-港股适配问题)
11. [工期估算建议](#11-工期估算建议)
12. [对产品/UX 的建议](#12-对产品ux-的建议)

---

## 1. 技术可行性评估

### 1.1 Jetpack Compose 实现难易度总览

| 功能模块 | 难度 | 说明 |
|---------|------|------|
| 登录/注册表单 | 低 | 标准 Compose 表单组件，完全可行 |
| K 线图（蜡烛图）| 高 | Compose Canvas 实现手势交互复杂，推荐 AndroidView 包装 |
| 分时图（折线图）| 中 | Canvas 可实现，但实时更新性能需优化 |
| WebSocket 实时推送 | 中 | OkHttp WebSocket + Flow 标准方案 |
| LazyColumn 自选股列表 | 中 | 高频更新时 key 策略至关重要 |
| 滑动确认组件 | 中 | 需自定义 Composable + 精确手势处理 |
| BiometricPrompt 验证 | 低 | Android 官方 API，直接集成 |
| KYC 身份证拍照 | 中 | CameraX 标准用法，OCR 需第三方 SDK |
| 人脸活体识别 | 高 | 强依赖第三方 SDK，技术栈选型是关键风险 |
| 手写签名 Canvas | 低 | Compose Canvas Path 绘制，实现成本低 |
| 深度图（Order Book）| 高 | 实时双向柱状图，自定义 Canvas，高性能要求 |
| 骨架屏 (Shimmer) | 低 | 使用 Shimmer 库或自实现 shimmer 动画 |
| 暗色模式 | 低 | Material 3 原生支持，需规范 Token 配置 |
| 价格涨跌闪烁动画 | 低 | `animateColorAsState` 即可实现 |
| 数字滚动动画 | 中 | 自定义 Composable，或复用开源轮子 |

### 1.2 高风险技术点详解

**K 线图交互（最高风险）**

设计要求支持：双指捏合缩放、单指拖动平移、长按十字线、成交量柱状图叠加、MA 均线叠加。在 Compose Canvas 中同时实现这些手势存在以下挑战：

- Compose 的 `detectTransformGestures` 同时处理缩放和拖动时，在快速操作下会有事件冲突
- 十字线的精确命中检测（touch target mapping to data point）在 Canvas 坐标系下需手动计算
- 大量历史 K 线数据（日线 5 年约 1300 根 K 线）渲染时，每帧全量重绘会导致卡顿

建议方案：使用 `AndroidView` 包装 MPAndroidChart，而非 Compose Canvas 从零实现。MPAndroidChart 对上述场景已有成熟处理，可节省约 3-4 周开发时间，且稳定性更高。

**人脸活体识别（技术风险）**

设计要求：眨眼检测、转头检测、防照片/视频攻击。

- Android 端 ML Kit 的 `FaceDetection` API 可检测人脸关键点，但防活体攻击（liveness detection）不在 ML Kit 标准功能内
- 金融级活体检测必须引入商用 SDK：旷视 FaceID、商汤、阿里云人脸核身、Jumio 等
- 商用 SDK 集成通常有包体积增大（+5-20MB AAR）、混淆规则配置复杂等问题
- 需要在技术选型阶段确定厂商，活体检测 SDK 的接入评估至少需要 1 周

**深度图实时更新**

v3 设计文档中提及了深度图，原型中暂无实现。深度图（Order Book）需要：
- 买卖盘数据实时推送（WebSocket tick 级别更新）
- 双侧柱状图随价格层叠加渲染
- 价格层动态增减，涉及 DiffUtil 级别的增量更新

这是行情模块中实现成本最高的子功能，建议 MVP 以简化列表形式替代，P1 再做可视化深度图。

---

## 2. 性能关注点

### 2.1 WebSocket 实时数据更新

**问题：** 设计方案中自选列表通过 WebSocket 实时推送，当用户自选股达到 50+ 时，每秒多个 tick 更新将频繁触发 Compose 重组。

**风险点：**
- 若直接将整个列表的 `StateFlow<List<StockQuote>>` 作为 Compose 状态，每次任意一只股票价格变化都会触发整个列表重组
- LazyColumn 虽然只渲染可见项，但重组本身仍有 CPU 开销

**推荐方案：**

```kotlin
// 错误方案：整个列表 StateFlow
val watchlist: StateFlow<List<StockQuote>>

// 正确方案：按股票 symbol 分离 StateFlow，结合 key 参数
val quoteMap: StateFlow<Map<String, StockQuote>>

// 在 LazyColumn 中使用 key 确保只有变化项重组
LazyColumn {
    items(symbols, key = { it }) { symbol ->
        val quote by remember {
            quoteMap.map { it[symbol] }
        }.collectAsStateWithLifecycle()
        StockListItem(quote = quote)
    }
}
```

- ViewModel 层对 WebSocket 消息做节流（throttle）：同一 symbol 100ms 内只更新一次
- 使用 `derivedStateOf` 计算涨跌幅，避免在 Composable 内做浮点运算（BigDecimal 运算在主线程更是禁忌）

### 2.2 K 线图渲染性能

K 线图历史数据全量加载（日线 5 年约 1300 根 K 线，加上成交量数据约 2600 个数据点）：

- 首次加载：后台线程解析 + 格式化，完成后切换到主线程更新 Chart
- 实时更新最新 K 线：仅更新最后一根 K 线数据，不重绘历史
- 图表切换（日K/周K/月K）：展示骨架屏，异步加载新数据
- **不能**在 Composable 的 `remember` 块内做大量数据处理，必须在 ViewModel 的协程中完成

### 2.3 LazyColumn 高频更新

行情列表在开盘期间每秒可能收到数十条更新。LazyColumn 高频刷新的核心问题：

- 使用 `key` 参数确保 item 不错位（否则滑动时会出现跳动）
- `StockListItem` 内部使用 `remember(quote.price)` 包装动画，避免全量重组
- 价格变化动画（闪烁高亮）使用 `LaunchedEffect(quote.price)` + `animateColorAsState`，不影响未变化的 item

**内存管理：** 如果行情列表超过 200 条，需对 WebSocket 订阅做范围限制（仅订阅当前可见区域 ± 缓冲区的股票），滚出视窗的股票退订实时推送，改为轮询。

### 2.4 后台 WebSocket 管理

当用户将 App 切换到后台：
- Android 系统在 API 26+ 后对后台 Service 有严格限制
- 若使用普通 Service 维持 WebSocket 连接，在 Doze 模式下连接会被断开
- **推荐方案：** 使用 `ForegroundService` 维持实时行情连接，并显示持仓当前盈亏通知栏。这是 Robinhood、Webull 的通行做法。
- App 回到前台时，检查连接状态，必要时重连并补充断线期间的数据

### 2.5 内存管理

- K 线图历史数据缓存：日线数据约 1.2MB（未压缩），分时图数据约 500KB。限制同时缓存的 symbol 数量（LRU，最多 10 个）
- Bitmap 资源：避免在 LazyColumn item 中加载大图，使用 Coil 的 `AsyncImage` 并指定 size
- 目标内存上限 200MB（v1 文档指标），在中低端 Android 设备（2GB RAM）上需特别注意

---

## 3. 平台特性建议

### 3.1 BiometricPrompt（强烈推荐用于订单确认）

v2 设计已要求生物识别用于下单确认，Android 实现完全可行：

```kotlin
val biometricPrompt = BiometricPrompt(
    activity,
    ContextCompat.getMainExecutor(context),
    object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
            viewModel.submitOrder() // 生物识别成功后提交订单
        }
    }
)

val promptInfo = BiometricPrompt.PromptInfo.Builder()
    .setTitle("确认买入")
    .setSubtitle("AAPL 100股 @ $175.00")
    .setAllowedAuthenticators(
        BiometricManager.Authenticators.BIOMETRIC_STRONG
    ) // 必须用 STRONG，不接受 CLASS_WEAK
    .build()

biometricPrompt.authenticate(promptInfo)
```

注意：
- 必须使用 `BIOMETRIC_STRONG`（指纹/3D 人脸），不接受 `BIOMETRIC_WEAK`（2D 人脸）和设备密码
- 设备生物识别数据变更（新增指纹）后，保存在 Android Keystore 中的密钥会自动失效，需要用户重新登录绑定
- 部分 MIUI/ColorOS 设备的 BiometricPrompt 实现有 bug，需做兼容测试

### 3.2 WorkManager（KYC 文件上传）

KYC 文件上传（证件照片、人脸视频等）涉及大文件传输，网络不稳定可能导致失败。应使用 WorkManager 而非直接在协程中上传：

- 支持断网重试（指数退避策略）
- 约束条件：`NetworkType.CONNECTED`，可选 `requiresCharging()`
- 上传进度通过 WorkInfo 回调更新 UI 进度条
- 支持应用被杀死后重启继续上传（对 KYC 这类关键操作尤为重要）

### 3.3 Foreground Service（实时行情）

行情页面打开时，启动 Foreground Service 维持 WebSocket 连接：

```
Foreground Service 通知栏内容：
[App 图标] 行情推送中 · 持仓盈亏: +$523.00
```

这既满足 Android 后台运行限制，又给用户提供实时持仓提醒价值。

### 3.4 Home Screen Widget

P1 功能建议：自选股 Widget，显示用户前 3 支自选股的实时价格和涨跌幅。使用 Glance API（Compose for Widgets）实现，数据通过 WorkManager 定期刷新（开盘时段 30 秒，休市时段不刷新）。

### 3.5 FCM Push Notifications

订单状态变化（成交、撤单）、价格提醒必须通过 FCM 推送实现，不能依赖后台 WebSocket。通知样式：

- 订单成交：`AAPL 100股买入成交 @ $175.00`，点击跳转订单详情
- 价格提醒：`TSLA 突破 $250.00 触发提醒`，点击跳转股票详情页
- 使用 Android 12+ 的 Notification Trampoline 限制，不能通过 BroadcastReceiver 间接跳转 Activity

### 3.6 Predictive Back Gesture（Android 14+）

KYC 多步骤流程中，用户按返回键应触发"确定要离开吗？已填写内容将保存"的提示。Android 14+ 的 Predictive Back API 可实现返回预览动画，需在多步骤 Composable 中接入 `BackHandler`。

---

## 4. 安全实现评估

### 4.1 Android Keystore

所有加密密钥必须存储在 Android Keystore，不得以任何形式写入磁盘：

```kotlin
// 生成 AES-256-GCM 密钥，用于加密本地敏感数据
val keyGenerator = KeyGenerator.getInstance(
    KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
)
keyGenerator.init(
    KeyGenParameterSpec.Builder(
        "brokerage_secret_key",
        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
    )
    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
    .setUserAuthenticationRequired(true) // 必须生物识别后才能使用密钥
    .setUserAuthenticationValidityDurationSeconds(-1) // 每次使用都要认证
    .build()
)
```

生物识别认证与密钥绑定：`setUserAuthenticationRequired(true)` 确保密钥只能在用户完成生物识别后使用。这是金融级应用的标准做法。

### 4.2 EncryptedSharedPreferences

本地存储 JWT Token、设备 ID、用户偏好设置时，必须使用 `EncryptedSharedPreferences`：

```kotlin
val sharedPreferences = EncryptedSharedPreferences.create(
    context,
    "brokerage_prefs",
    MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build(),
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)
```

注意：`EncryptedSharedPreferences` 性能比普通 SharedPreferences 约慢 3-5 倍，对高频读写的场景（如实时行情缓存）不适用，这类数据使用 Room 数据库。

### 4.3 FLAG_SECURE 防截图

以下屏幕必须设置 `FLAG_SECURE`，防止截图、录屏、近期任务缩略图泄露：

- 出入金页面（含银行卡信息）
- KYC 证件上传、人脸识别页面
- 持仓详情页面（含资产金额）
- 订单确认弹窗

```kotlin
// 在 Compose Activity 中
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
)
```

注意：`FLAG_SECURE` 是页面级别的，若在一个 Activity 中混用敏感和非敏感屏幕（单 Activity 架构），需要在敏感页面导航进入时设置、导航离开时清除。

### 4.4 OkHttp Certificate Pinning

```kotlin
val certificatePinner = CertificatePinner.Builder()
    .add("api.yourbrokerage.com", "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=") // 主证书
    .add("api.yourbrokerage.com", "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=") // 备用证书（轮换用）
    .build()

val okHttpClient = OkHttpClient.Builder()
    .certificatePinner(certificatePinner)
    .build()
```

**证书轮换策略：**
- 至少预设一个备用 Pin（下一期证书的公钥 Hash）
- 通过服务端下发新 Pin 值，并在客户端保留 7 天窗口期（新旧 Pin 同时有效）
- 证书固定失败时上报事件，首周不强制阻断（网络诊断模式），之后强制阻断

### 4.5 Root 检测

金融 App 在 Root 设备上存在密钥泄露风险。建议分层处理：

- **检测到 Root：** 展示警告弹窗，告知用户安全风险，但不强制退出（影响用户留存）
- **交易/出金操作时再次校验：** 如果设备是 Root 状态，在下单和出金时额外提示
- **禁止截图和录屏（FLAG_SECURE）在 Root 设备上可能被绕过：** 需在服务端做额外风控

Root 检测库推荐使用 RootBeer，同时补充以下检测：
- 检测 `su` 命令是否存在
- 检测已知 Root 管理应用包名（Magisk、SuperSU 等）
- 检测 `/system` 分区是否以读写模式挂载

### 4.6 模拟器检测

防止自动化脚本在模拟器上批量注册账号。检测指标：
- Build 属性：`Build.FINGERPRINT` 包含 "generic"，`Build.HARDWARE` 为 "goldfish" / "ranchu"
- 传感器缺失：真机有加速度计、陀螺仪，模拟器通常没有
- 电话相关：没有 SIM 卡，`TelephonyManager.getDeviceId()` 返回固定值

### 4.7 ProGuard/R8 混淆规则

必须为以下类配置 Keep 规则，否则会导致运行时崩溃：

```proguard
# Retrofit 网络模型
-keep class com.yourbrokerage.data.model.** { *; }
-keep interface com.yourbrokerage.data.api.** { *; }

# Protobuf
-keep class com.google.protobuf.** { *; }
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageV3 { *; }

# Room
-keep class * extends androidx.room.RoomDatabase

# Hilt
-keep class dagger.hilt.** { *; }

# 活体检测 SDK（以 FaceID SDK 为例，具体看厂商文档）
-keep class com.megvii.faceid.** { *; }

# 金融数据模型（防止被 R8 优化掉）
-keepclassmembers class **.domain.entity.** { *; }
```

---

## 5. 第三方库选型

### 5.1 图表库选型对比

| 库 | 优势 | 劣势 | 推荐度 |
|----|------|------|--------|
| **MPAndroidChart** | 功能最全、K 线/深度图/均线均支持、社区成熟、金融 App 广泛使用 | API 设计老旧（View-based）、需 AndroidView 包装 | 强烈推荐（MVP 首选）|
| **Vico** | 原生 Compose API、现代设计 | 不支持 K 线图（无蜡烛图）、功能有限 | 不适合（缺 K 线支持）|
| **自定义 Compose Canvas** | 完全定制、无依赖 | 开发周期长（估计 4-6 周）、手势处理复杂 | P1 可考虑替换 MPAndroidChart |
| **TradingView Lightweight Charts** | 专业金融图表、WebView 嵌入 | 性能差（WebView）、交互延迟高 | 不推荐 |

**结论：** MVP 阶段使用 MPAndroidChart，通过 `AndroidView` 包装适配 Compose。后期有预算再考虑基于 Compose Canvas 的完全自定义实现。

### 5.2 WebSocket 方案

推荐 **OkHttp WebSocket**（已是项目 HTTP 客户端依赖），无需额外引入 Scarlet 等库：

```kotlin
val request = Request.Builder().url("wss://api.yourbrokerage.com/ws/quotes").build()
val webSocket = okHttpClient.newWebSocket(request, object : WebSocketListener() {
    override fun onMessage(webSocket: WebSocket, text: String) {
        // 在后台线程调用，需切换到协程上下文处理
    }
    override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        // 实现指数退避重连
    }
})
```

重连策略：断开后 1s → 2s → 4s → 8s → 16s → 最大 60s，重连间隔上限 60 秒。

### 5.3 Protobuf 数据序列化

行情数据使用 Protobuf（相比 JSON 数据量减少约 40-60%，解析速度更快）。添加依赖：

```kotlin
// build.gradle.kts
implementation("com.google.protobuf:protobuf-kotlin-lite:3.25.0")
```

注意配置 ProGuard Keep 规则（见第 4.7 节），否则 R8 会误删 Protobuf 相关类。

### 5.4 Plaid Link Android SDK

用于银行账户即时验证（见出入金模块第 7 节），Plaid 官方提供 Android SDK：

```kotlin
implementation("com.plaid.link:sdk-core:4.x.x")
```

集成方式为启动 Activity（Plaid 提供 `PlaidLinkResultContract`），用户在 Plaid 提供的 WebView 中完成银行账户登录，完成后回调给 App。

限制：
- Plaid Link 目前主要覆盖美国银行，对 HK 银行（HSBC HK、Hang Seng 等）的支持有限
- HK 银行卡验证可能需要回退到"小额打款验证"方案

### 5.5 OCR / 人脸识别 SDK

| 场景 | 推荐方案 | 说明 |
|------|---------|------|
| 证件 OCR | **ML Kit Text Recognition v2** | Google 原生，免费，离线可用 |
| 活体检测 | **商用 SDK（旷视/阿里/Jumio）** | ML Kit 不含 liveness，必须商用方案 |
| 人脸对比 | 与活体检测 SDK 捆绑 | 同一厂商一体化方案 |

OCR 识别中文身份证建议使用 ML Kit 的 `KOREAN` + `CHINESE` 语言模型（中文身份证号、姓名识别效果更好）。

---

## 6. KYC 流程实现复杂度

### 6.1 整体评估

v3 设计的 9 步 KYC 流程是整个 App 中实现复杂度最高的模块，估算工期约 5-7 周（Android 端）。主要复杂度来源：

| 步骤 | 技术实现 | 复杂度 | 工期 |
|------|---------|--------|------|
| 个人信息（Step 1）| 普通 Compose 表单 | 低 | 3天 |
| 证件上传（Step 2）| CameraX + 图片裁剪 + 上传 | 中 | 5天 |
| OCR 识别（Step 2）| ML Kit Text Recognition | 中 | 3天 |
| 人脸活体识别（Step 3）| 商用 SDK 集成 | 高 | 7天 |
| 就业信息（Step 4）| 条件表单 | 低 | 2天 |
| 财务状况（Step 5）| 普通表单 | 低 | 2天 |
| 投资评估（Step 6）| 问卷表单 | 低 | 2天 |
| 税务/W-8BEN（Step 7）| 表单 + 电子签署 | 中 | 3天 |
| 风险披露（Step 8）| 富文本展示 + 强制滚动检测 | 低 | 2天 |
| 协议签署（Step 9）| 手写签名 Canvas | 中 | 3天 |
| 断点续传 | 后台保存/恢复进度 | 中 | 3天 |

### 6.2 CameraX 证件拍照

使用 `CameraX` 的 `ImageCapture` 用例：

- 拍照时展示取景框叠加层（证件对齐引导线）
- 拍照后跳转裁剪页（AndroidX CropImage 或 uCrop 库）
- 图片质量要求：分辨率不低于 1280x720，文件大小压缩到 500KB 以下（避免上传超时）
- 需要处理 Android 相机权限请求流程（`ActivityResultContracts.RequestPermission`）
- 注意：部分低端设备 CameraX 启动时间较长（>1s），需要显示 Loading 状态

### 6.3 手写签名 Canvas

```kotlin
@Composable
fun SignatureCanvas(
    onSignatureChanged: (Path) -> Unit
) {
    val path = remember { Path() }
    var isDrawing by remember { mutableStateOf(false) }

    Canvas(
        modifier = Modifier
            .fillMaxWidth()
            .height(150.dp)
            .border(1.dp, Color.Gray, RoundedCornerShape(8.dp))
            .pointerInput(Unit) {
                detectDragGestures(
                    onDragStart = { offset ->
                        path.moveTo(offset.x, offset.y)
                        isDrawing = true
                    },
                    onDrag = { change, _ ->
                        path.lineTo(change.position.x, change.position.y)
                        onSignatureChanged(path)
                    }
                )
            }
    ) {
        drawPath(path, color = Color.Black, style = Stroke(width = 3f))
    }
}
```

签名完成后需将 Canvas 内容导出为 Bitmap，上传至后端存档。

### 6.4 KYC 断点续传

每步完成后向服务端保存进度（API 调用），本地同时用 Room 缓存进度状态：

```kotlin
// Room Entity
@Entity(tableName = "kyc_progress")
data class KycProgressEntity(
    @PrimaryKey val userId: String,
    val currentStep: Int,        // 当前步骤（1-9）
    val stepDataJson: String,    // 已填写内容的 JSON 快照
    val lastUpdated: Long
)
```

App 冷启动检测到未完成的 KYC 申请时，在 SplashScreen 后展示恢复提示弹窗，而非强制跳转（尊重用户意愿）。

### 6.5 强制滚动检测（风险披露）

风险披露（Step 8）要求用户阅读完整内容后才能勾选确认。需检测 `LazyColumn` 是否滚动到底部：

```kotlin
val listState = rememberLazyListState()
val hasScrolledToBottom by remember {
    derivedStateOf {
        val lastVisibleItem = listState.layoutInfo.visibleItemsInfo.lastOrNull()
        lastVisibleItem?.index == listState.layoutInfo.totalItemsCount - 1
    }
}
// hasScrolledToBottom 为 false 时，禁用"我已阅读"勾选框
```

---

## 7. 出入金模块评估

### 7.1 Plaid Link SDK 集成

Plaid Link 是出入金模块中最大的外部依赖。集成流程：

1. 后端生成 `link_token`（调用 Plaid `/link/token/create` 接口）
2. Android 端用 `link_token` 启动 Plaid Link Activity
3. 用户在 Plaid 页面完成银行账号授权
4. 回调返回 `public_token`，App 传给后端
5. 后端用 `public_token` 换取 `access_token`，完成账户绑定

关键实现注意：
- Plaid Link 在 WebView 内运行，涉及跨域资源加载，需要在 `AndroidManifest.xml` 中配置网络安全策略
- Plaid 的 SDK 包体积约 5-10MB，需评估对最终 APK 大小的影响
- **HK 银行支持问题**：Plaid 目前对港元账户的香港本地银行（汇丰 HK、恒生等）支持非常有限，HK 入金可能需要完全依赖手动的小额打款验证方案

### 7.2 金额输入安全

出入金金额输入框是高安全敏感区域，注意：

- 使用标准 Android KeyboardType（`KeyboardType.Number`），不启用自定义键盘（避免键盘记录风险）
- 禁用输入框的文本自动完成（`autofillHints = emptyArray()`），防止系统填充历史金额
- 大额输入（$10,000+）触发二次确认弹窗，确认弹窗使用 `FLAG_SECURE` 的 Dialog

### 7.3 双币种余额展示

v3 设计要求同时展示 USD 和 HKD 账户余额，Android 实现注意事项：

- 货币金额必须使用 `BigDecimal`，显示时用 `NumberFormat.getCurrencyInstance()` 格式化（指定 `Locale`）
- 港币格式：`HK$5,200.00`，美元格式：`$10,250.00`
- 实时汇率 15 秒刷新（v3 设计要求），使用 `LaunchedEffect` + `delay(15_000L)` 轮询，或 WebSocket 推送汇率更新

### 7.4 出入金记录分页

历史记录页面使用 Paging 3 库实现分页加载，避免一次性加载全量历史记录（合规要求最多保留 7 年记录）：

```kotlin
@HiltViewModel
class FundingHistoryViewModel @Inject constructor(
    private val repository: FundingRepository
) : ViewModel() {
    val pagingData = repository.getFundingHistory()
        .cachedIn(viewModelScope) // 缓存分页数据，避免旋转屏幕时重新请求
}
```

### 7.5 幂等性保障

出入金请求必须携带幂等键（`Idempotency-Key`，UUID v4）。Android 端在提交前生成，存储在 ViewModel 中（非 Room）：

- 成功提交后清除幂等键
- 网络超时后，使用**同一个幂等键**重试（不重新生成）
- 失败（非超时）后，生成新的幂等键，允许用户重新提交

---

## 8. 交互实现评估

### 8.1 滑动确认（Slide to Confirm）

v2 设计引入了滑动确认替代普通按钮。这是 Android 中需要自定义实现的组件（无原生 Composable），实现重点：

```kotlin
@Composable
fun SlideToConfirmButton(
    label: String,
    onConfirmed: () -> Unit,
    enabled: Boolean = true
) {
    var offsetX by remember { mutableFloatStateOf(0f) }
    val maxOffset = // 容器宽度 - 滑块宽度
    val confirmedThreshold = maxOffset * 0.9f // 滑到 90% 触发确认

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(50.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(if (enabled) Color(0xFF3B82F6) else Color.Gray)
            .pointerInput(enabled) {
                if (!enabled) return@pointerInput
                detectHorizontalDragGestures(
                    onDragEnd = {
                        if (offsetX < confirmedThreshold) {
                            // 弹回起始位置（spring 动画）
                            // ...
                        }
                    },
                    onHorizontalDrag = { _, dragAmount ->
                        offsetX = (offsetX + dragAmount).coerceIn(0f, maxOffset)
                        if (offsetX >= confirmedThreshold) {
                            HapticFeedbackType.LongPress // 触觉反馈
                            onConfirmed()
                        }
                    }
                )
            }
    ) {
        // 滑块 + 背景文字
    }
}
```

需要注意：
- 滑块回弹使用 `spring()` 动画（弹性效果），而非 `tween()`（线性）
- 滑动过程中实时更新进度色
- 确认触发后立即禁用（防止重复触发）
- 振动反馈：滑到头时触发 `HapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)`

### 8.2 K 线图手势处理

MPAndroidChart 通过 `AndroidView` 包装后，手势处理已由库内部实现，但需注意 Compose 与 View 系统的手势冲突：

- K 线图外部若是 `VerticalScroll`（如 ScrollableColumn），双指缩放 K 线图时会与外层滚动冲突
- 解决方案：检测到双指操作时，使用 `Modifier.nestedScroll` 消费事件，阻止传递给父容器

### 8.3 骨架屏（Shimmer Loading）

推荐使用 **Valentinilk Compose Shimmer** 库（Compose 原生，无 View 依赖）：

```kotlin
implementation("com.valentinilk.shimmer:compose-shimmer:1.3.0")
```

骨架屏 Composable 与真实内容 Composable 保持相同布局，通过 `isLoading` 状态切换，使用 `AnimatedVisibility` 实现平滑过渡，避免布局跳动（layout shift）。

### 8.4 价格数字滚动动画

资产总览的数字变化动画（如盈亏从 +$523 变为 +$531）：

```kotlin
@Composable
fun AnimatedCounter(
    value: BigDecimal,
    modifier: Modifier = Modifier
) {
    val animatedValue by animateFloatAsState(
        targetValue = value.toFloat(),
        animationSpec = tween(durationMillis = 600, easing = FastOutSlowInEasing)
    )
    Text(
        text = NumberFormat.getCurrencyInstance(Locale.US)
            .format(animatedValue.toBigDecimal()),
        modifier = modifier
    )
}
```

注意：价格动画仅用于资产总览的缓慢数字变化。实时行情数字（每秒更新）不建议使用动画，因为动画会导致显示值滞后于实际值。

### 8.5 价格闪烁高亮

```kotlin
@Composable
fun PriceText(price: BigDecimal, previousPrice: BigDecimal?) {
    val isUp = previousPrice == null || price > previousPrice
    val highlightColor = if (isUp) Color(0xFF52C41A) else Color(0xFFFF4D4F)
    val defaultColor = MaterialTheme.colorScheme.onSurface

    var shouldHighlight by remember { mutableStateOf(false) }
    val textColor by animateColorAsState(
        targetValue = if (shouldHighlight) highlightColor else defaultColor,
        animationSpec = tween(500)
    )

    LaunchedEffect(price) {
        shouldHighlight = true
        delay(500)
        shouldHighlight = false
    }

    Text(text = price.formatAsCurrency(), color = textColor)
}
```

---

## 9. 设备碎片化

### 9.1 最低 API 级别建议

**推荐 minSdk = 26（Android 8.0）**

理由：
- Android 8.0 市场占有率覆盖约 95%+ 的中国大陆主流 Android 设备
- `EncryptedSharedPreferences` 最低支持 API 23，但 BiometricPrompt 强认证（`BIOMETRIC_STRONG`）在 API 28 以下功能有限
- `CameraX` 最低支持 API 21，但稳定的人脸识别功能建议 API 26+
- 低于 API 26 的设备对 Kotlin Coroutines 的后台限制兼容性较差

**实际场景分析：**
- 目标用户是美港股投资者，普遍使用中高端机型，API 26 覆盖已足够
- 如果将来面向更广泛市场，可降至 API 24（Android 7.0），但需额外处理若干兼容性问题

### 9.2 屏幕适配

- 使用 `WindowSizeClass` 区分手机（Compact）和折叠屏/平板（Medium/Expanded）
- K 线图在横屏/折叠屏展开时应充分利用额外空间（自动切换全屏图表模式）
- 字体使用 `sp` 单位（支持系统字体大小设置），`v2` 设计的"大字模式"依赖此特性自动实现（无需额外实现）
- 5.5 寸以下小屏幕（部分 iPhone SE 对标机型）需测试下单页面信息是否显示完整，防止截断

### 9.3 OEM 特殊问题

| OEM/系统 | 问题 | 处理方案 |
|---------|------|---------|
| **MIUI（小米）** | 后台 App 被系统杀死概率高，WebSocket 断连 | Foreground Service + 引导用户打开"自启动"权限 |
| **ColorOS（OPPO/realme）** | 类似 MIUI，省电策略激进 | 同上；检测 OEM 并主动引导白名单设置 |
| **华为（无 GMS）** | FCM Push 不可用 | 集成华为 HMS Push Kit 作为 FCM 替代 |
| **三星 One UI** | 折叠屏适配（Foldable）| 使用 `WindowSizeClass` 处理折叠/展开状态变化 |
| **部分 MIUI BiometricPrompt** | 生物识别弹窗样式被替换，有 bug | 添加 MIUI 设备标识检测，降级提示用户使用密码 |

**华为 HMS 的重要性：** 国内 Android 市场华为（鸿蒙/Android）占有率约 25%。无 GMS 的华为设备无法使用 FCM，必须集成 HMS Push，否则这部分用户无法收到订单成交推送。建议采用抽象层封装 FCM 和 HMS（如 FlexPush 或自实现）。

### 9.4 64 位要求

Google Play 强制要求 APK 包含 64 位 native library。如果集成的人脸识别 SDK 仅提供 32 位 `.so` 文件，将无法上架 Google Play（国内分发无此限制）。在 SDK 选型时必须确认 64 位支持。

---

## 10. 港股适配问题

### 10.1 手（Board Lot）单位处理

港股的交易单位是"手"（Board Lot），不同股票每手股数不同：

| 股票 | 代码 | 每手股数 |
|------|------|---------|
| 腾讯 | 00700 | 100 股 |
| 汇丰控股 | 00005 | 400 股 |
| 中国平安 | 02318 | 500 股 |

下单页数量输入需要：
- 数量步进器以"手"为单位，实际股数 = 手数 × 每手股数
- 显示应为"1手 (100股)"，让用户清楚
- 快捷按钮改为"1手"、"5手"、"10手"、"最大"
- 超出持仓（卖出时）或超出资金（买入时）的校验须基于股数计算
- 数量输入验证：港股数量必须是每手股数的整数倍（除非碎股交易）

```kotlin
fun validateHKQuantity(quantity: Int, lotSize: Int): Boolean {
    return quantity > 0 && quantity % lotSize == 0
}
```

### 10.2 港股代码格式

- 港股代码：4-5 位数字，补零（腾讯是 00700，不是 700）
- 美股代码：1-5 位大写字母（AAPL、BRK.A）
- 搜索 UI 需要支持"700" → 匹配 "00700" 的模糊搜索
- 显示时始终展示完整 5 位带补零格式（00700），避免混淆

### 10.3 港股交易时段

HKEX 交易时段：09:30-12:00 / 13:00-16:00 HKT，有午休时段。

- 下单页需要根据当前 HKT 时间判断是否在交易时段内
- 11:59-13:00 之间（午休）：提示"午间休市，请在 13:00 后重试"
- 竞价时段（08:30-09:20，收盘竞价 16:00-16:10）：是否支持下单需产品确认（v2/v3 未说明）
- 时区转换必须在服务端完成，客户端只根据服务端返回的"市场状态"字段展示，不在客户端做时区计算（避免设备时间被篡改）

### 10.4 双货币显示

- 港股持仓市值以 HKD 显示，但总资产可能需要换算成 USD 显示
- 换算使用实时汇率，来源于服务端（客户端不持有汇率数据）
- 持仓盈亏计算：若用 USD 入金后购入 HKD 计价港股，盈亏需考虑汇率变化对冲，展示逻辑需与产品和后端对齐

### 10.5 港股涨跌停（无限制）

港股没有涨跌停限制，因此：
- 下单页不显示"当日涨跌幅限制"相关提示
- 理论上日内可出现极端价格波动（如 -90%），涨跌色显示需支持大幅数字，避免 UI 截断
- 异常波动警告阈值建议比美股更高（如 ±20% 而非 ±5%）

---

## 11. 工期估算建议

以下为 Android 端 MVP 各模块粗略工期估算，假设 2 名 Android 工程师并行开发。

### 11.1 功能模块工期

| 模块 | 工期（人天）| 风险等级 | 关键路径 |
|------|------------|---------|---------|
| 项目架构搭建（Clean Architecture、DI、Navigation）| 5 | 低 | 所有其他模块的前置 |
| 登录 / 注册 | 5 | 低 | - |
| KYC 流程（9 步，含 OCR）| 25-35 | 高 | 活体检测 SDK 选型 |
| 行情页（自选列表、搜索、实时推送）| 10 | 中 | WebSocket 架构 |
| 股票详情页（含图表）| 12 | 高 | MPAndroidChart 集成 |
| 下单页（含滑动确认、BiometricPrompt）| 10 | 中 | - |
| 订单列表 | 5 | 低 | - |
| 持仓页 | 8 | 中 | 实时盈亏更新 |
| 出入金（含 Plaid SDK）| 15 | 高 | Plaid SDK 集成 |
| 我的 / 设置 | 5 | 低 | - |
| 安全加固（Root 检测、证书固定、混淆）| 5 | 中 | - |
| 华为 HMS 适配 | 5 | 中 | 如果目标市场包含国内 |
| 联调、测试、Bug Fix | 15 | - | - |

**总计：约 120-145 人天（2 人约 10-12 周）**

### 11.2 最高风险模块

1. **KYC 人脸活体识别**：商用 SDK 的采购、集成文档质量、与后端审核系统的接口对接，任何一个环节延误都会拖累整体进度。建议最先启动技术选型（第一周）。

2. **K 线图与实时行情**：MPAndroidChart 集成较为直接，但实时 WebSocket 推送下的 Compose 重组性能调优需要专项时间投入。建议第一个 Sprint 就构建可运行的行情 Demo。

3. **Plaid SDK 与 HK 银行适配**：HK 银行的 Plaid 支持问题可能导致整个 HK 入金流程需要额外设计手动验证方案。

### 11.3 MVP 裁剪建议

如果工期压力大，以下功能可以推到 P1：

- 深度图（Order Book 可视化）：用简单文字列表替代
- 止损限价单、追踪止损等高级订单类型：MVP 仅做市价单和限价单
- 换汇页面：MVP 阶段仅支持 ACH 入金，不做货币兑换
- Widget 和 Wear OS：完全 P1
- 技术指标（MACD/RSI）：完全 P1

---

## 12. 对产品/UX 的建议

### 12.1 必须在开发前明确的问题

以下问题如不明确，会导致返工或设计变更：

**问题 1：港股数量输入单位**

设计文档中的快捷按钮写的是"10股"、"50股"、"100股"，但港股应以"手"为单位。需确认：
- 下单页数量输入以股还是手为单位？
- 港股快捷按钮如何设计（"1手"/"5手"/"10手"？）

**问题 2：华为 HMS 是否必须支持**

是否目标国内 Android 用户？如果是，FCM Push 对华为设备无效，必须集成 HMS。这会增加约 5 人天工作量。

**问题 3：活体检测 SDK 选型**

这是技术风险最高的单点。产品需尽快确定合作厂商（旷视/阿里/Jumio），因为商务合同签署可能需要 2-4 周。技术集成在合同前可以通过 Demo 版 SDK 先行评估。

**问题 4：HK 银行验证方案**

Plaid 对 HK 银行的支持有限，HK 银行账户绑定是否采用小额打款验证？如果是，需要提前设计对应的 UI 流程（v3 文档中只有 USD 账户的详细流程）。

### 12.2 设计层面的建议

**建议 1：PIN 码作为生物识别降级方案**

v3 设计中，生物识别失败 3 次后降级为"密码登录"。从 Android 用户体验角度，建议降级到"6 位数字 PIN 码"而非全密码输入，这更符合移动端操作习惯（参考大多数银行 App 的方案）。

**建议 2：订单确认弹窗与 FLAG_SECURE**

v2 设计的订单确认弹窗包含了完整的订单信息。建议将此弹窗所在的页面设置 `FLAG_SECURE`（即在下单页和确认流程中全程屏蔽截图），而不仅仅是弹窗本身——因为弹窗背后仍可见持仓信息。

**建议 3：K 线图历史数据加载策略**

设计文档未提及历史 K 线图的分页加载策略。建议：
- 首次打开股票详情页：加载最近 3 个月日线数据（约 65 根 K 线）
- 用户向左拖动至数据边界时：自动加载更早的数据（类似 Instagram 无限滚动）
- 不要一次性加载 5 年全量数据（约 1300 根 K 线 + 成交量，数据包约 200-400KB）

**建议 4：出金的余额锁定提示**

v3 出金页面展示了"未结算资金"的扣除，但 UI 上仅有静态文字。建议增加一个"了解详情"弹窗，解释 T+1/T+2 结算规则——这是新用户的常见困惑点，减少客服咨询量。

**建议 5：游客模式的明确流程**

v3 提到游客可以"浏览延迟 15 分钟行情"，但未说明游客进入股票详情页后，买卖按钮的状态是什么（灰化禁用？还是点击后弹出注册引导？）。建议明确：游客点击"买入"时，弹出底部 Sheet 引导注册，而非跳转到完整注册页（降低转化摩擦）。

**建议 6：分时图的数据更新频率**

分时图（当日价格走势）在实盘中是 1 分钟 K 线聚合，还是逐笔 tick 折线图？两种方案的数据量和实现复杂度差异很大。建议产品明确，然后 Android 端才能确定实时更新方案（WebSocket vs 定时轮询）。

**建议 7：多网络状态下的 UI 设计**

当前设计未体现离线状态 UI。建议在以下情况展示明确的离线提示：
- 网络断开：顶部 Banner 显示"无网络连接，行情数据可能已过时"
- WebSocket 断连：行情数据旁显示"行情 03-11 09:35 (数据可能已过时)"，带时间戳
- 交易功能在离线状态下完全禁用（不允许下单），但允许查看历史持仓和订单

---

## 附录：推荐技术架构图

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  Jetpack Compose UI ← ViewModel (MVI: State/Event/Effect)│
│  Navigation Component (Type-safe Routes)                 │
└─────────────────┬───────────────────────────────────────┘
                  │ collectAsStateWithLifecycle
┌─────────────────▼───────────────────────────────────────┐
│                    Domain Layer                          │
│  Use Cases  │  Repository Interfaces  │  Domain Entities │
└─────────────┬────────────────┬────────────────────────┘
              │                │
┌─────────────▼──────┐ ┌───────▼────────────────────────┐
│    Data Layer      │ │       Remote Data               │
│                    │ │  Retrofit + OkHttp (REST)       │
│  Room Database     │ │  OkHttp WebSocket (Quotes)      │
│  EncryptedSharedP. │ │  Plaid Link SDK (Bank)          │
│  DataStore         │ │  FCM / HMS Push                 │
└────────────────────┘ └────────────────────────────────┘

DI: Hilt (全局) | 测试: JUnit5 + MockK + Turbine
```

---

**文档版本**: v1.0
**评审人**: Android Engineer
**下次更新**: 待产品明确 12 个待确认问题后，更新工期估算
