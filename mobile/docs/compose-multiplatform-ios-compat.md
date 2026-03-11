# Compose Multiplatform iOS/Android 兼容性问题复盘

> 版本：Compose Multiplatform 1.7.1（当前）→ 建议升级至 1.8.x+
> 更新日期：2026-03

---

## 官方现状（2025-2026）

| 里程碑 | 时间 |
|--------|------|
| CMP for iOS **Stable**（生产就绪） | 2025 年 5 月（v1.8.0）|
| 多平台 Navigation 正式支持 iOS | v1.6.10（beta），v2.9.2（stable）|
| Navigation 3（alpha，直接栈操作） | v1.10.0（2026 年 1 月）|
| Compose for Web → Beta | v1.9.0 |

**我们的版本（1.7.1）是 iOS Stable 之前的 pre-stable 版本，应升级。**

---


## 问题一：Emoji 在 iOS 上渲染为 `?`

### 现象
`Text(text = "🔍")` `Text(text = "📈")` 等 emoji，Android 正常显示，iOS 上全部变成 `[?]` 方块。

### 根本原因
Compose Multiplatform 在 iOS 上使用自定义文字渲染引擎（基于 Skia），**不走系统字体 fallback**。iOS 系统字体支持 emoji，但 Skia 渲染器的字体 fallback 链不包含 Apple Color Emoji 字体，导致 emoji 无法解析。

Unicode 基础符号（`←` `→` `▲` `▼` `✕`）同理，也不能保证在 Skia 渲染下正常显示。

### 影响范围（当前项目）
| 文件 | 问题 emoji |
|------|-----------|
| AccountScreen.kt | `💰 💳 📊 👤 🔒 🔔 ⚙️ ❓ 💬 ℹ️` |
| LoginScreen.kt | `📈 👁️ 👁️‍🗨️ 🍎 📱` |
| KycScreen.kt | `📸 ✅ 📷 💡 📄` |
| TradeScreen.kt | `⚠️` |
| FundingScreen.kt | `💳 ℹ️` |
| HelpScreen.kt | `📈 💰 📊 🔒 ❓` |
| MarketScreen.kt | `🔍 🔔`（已修复）|
| Tabs.kt（底部导航）| `📈 📋 💼 👤`（已修复）|

### 解决方案（已验证）
**用 Material Icons 替代 emoji**：

```kotlin
// ❌ 错误 - iOS 上渲染为 ?
Text(text = "🔍", fontSize = 20.sp)

// ✅ 正确 - 两端一致
Icon(
    imageVector = Icons.Default.Search,
    contentDescription = "搜索",
    modifier = Modifier.size(20.dp)
)
```

依赖配置（`build.gradle.kts` commonMain）：
```kotlin
implementation(compose.materialIconsExtended)
```

### 遗留问题
以下文件仍有 emoji 未处理：
- `LoginScreen.kt`（`👁️` 密码可见切换、`🍎 📱` 三方登录）
- `KycScreen.kt`（多处）
- `TradeScreen.kt`、`WithdrawalScreen.kt`（`⚠️`）
- `AccountScreen.kt` 菜单项图标（菜单行已改用 clickable，emoji 已移除）

---

## 问题二：`Surface(onClick=...)` 在 iOS 上点击失效

### 现象
`AccountScreen` 的菜单项（出入金、银行卡管理等）在 iOS 上点击完全无响应，Android 正常。

### 根本原因
`Surface(onClick = ...)` 内部使用 Material 3 的 `indication` 和触摸反馈机制。在 Compose Multiplatform iOS 实现中，`Surface` 的点击事件处理路径与 Android 存在差异，当布局中存在无法渲染的字符（emoji 占位的 `?`）时，命中测试（hit testing）可能发生偏移或被吞掉。

### 解决方案（已验证）
**改用 `.clickable()` modifier**：

```kotlin
// ❌ iOS 上可能失效
Surface(
    onClick = item.onClick,
    color = Color.White
) { ... }

// ✅ 两端均可靠
Row(
    modifier = Modifier
        .fillMaxWidth()
        .clickable(onClick = item.onClick)
        .background(Color.White)
        .padding(vertical = 14.dp)
) { ... }
```

### 影响范围（当前项目）
| 文件 | 位置 |
|------|------|
| AccountScreen.kt | `MenuItemRow`（已修复）|
| OrdersScreen.kt | 订单列表行（L122）|
| StockDetailScreen.kt | 新闻列表行（L416, L597）|
| LoginScreen.kt | 登录方式 Tab（L345）|

---

## 问题三：iOS 启动崩溃 —— PlistSanityCheck

### 现象
App 安装后立即崩溃，crash 栈：
```
kfun:androidx.compose.ui.uikit.PlistSanityCheck.performIfNeeded$lambda$0#internal
```

### 根本原因
Compose Multiplatform 在启动时会检查 `Info.plist` 中是否存在 `UIApplicationSceneManifest`（含有效的 `UIWindowSceneSessionRoleApplication` 配置）。使用 SwiftUI `@main App` 生命周期时，Xcode 自动生成的 `Info.plist` 可能缺少此字段。

### 解决方案（已验证）
两种方式二选一：

**方式 A（推荐）：关闭强制检查**
```kotlin
// iosMain/MainViewController.kt
fun MainViewController(): UIViewController {
    return ComposeUIViewController(
        configure = {
            enforceStrictPlistSanityCheck = false  // 关闭检查
        }
    ) {
        App()
    }
}
```

**方式 B：在 Info.plist 加完整的 Scene 配置**
```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

---

## 问题四：iOS 无底部导航栏

### 现象
`commonMain/App.kt` 是占位 stub，iOS 启动后只显示 splash 页面，无法进入任何功能页面。

### 根本原因
`MainScreen`（含底部导航 + `AppNavGraph`）依赖 `androidx.navigation:navigation-compose`，该库被声明在 `androidMain`，iOS 端无法使用。`App()` 在 `commonMain` 只是一个 stub。

### 解决方案（已验证）
在 `iosMain` 创建 `App.kt`（`actual` 实现），手写轻量 back-stack 路由：

```kotlin
// iosMain/kotlin/com/brokerage/ui/App.kt
@Composable
actual fun App() {
    BrokerageTheme {
        val backStack = remember { mutableStateListOf<IosRoute>(IosRoute.Market) }
        val current = backStack.last()
        fun push(r: IosRoute) { backStack.add(r) }
        fun pop() { if (backStack.size > 1) backStack.removeAt(backStack.lastIndex) }

        Scaffold(bottomBar = {
            if (current in tabRoots) BottomNavBar(...)
        }) { padding ->
            Box(Modifier.padding(padding)) {
                when (current) {
                    is IosRoute.Market -> MarketScreen(...)
                    is IosRoute.StockDetail -> StockDetailScreen(...)
                    // ...
                }
            }
        }
    }
}
```

`commonMain/App.kt` 改为 `expect`：
```kotlin
@Composable
expect fun App()
```

`androidMain/App.kt` 提供 `actual`（调用原有 `MainScreen()`）：
```kotlin
@Composable
actual fun App() = MainScreen()
```

### 长期方案
迁移到 `org.jetbrains.androidx.navigation:navigation-compose`（Compose Multiplatform 官方多平台导航，从 2.8.0-alpha 开始支持 iOS），可共用一套 `NavGraph`，无需维护两套路由。

---

## 问题五：底部导航栏与系统手势条重叠（Android）

### 现象
Android 底部导航栏与系统 Home 手势条重叠，无法正常点击。

### 解决方案（已验证）
在 `BottomNavBar` 的 `Surface` 上加 `navigationBarsPadding()`：
```kotlin
Surface(
    modifier = Modifier
        .fillMaxWidth()
        .navigationBarsPadding()  // ← 关键
) { ... }
```

---

## 问题六：`Divider()` 废弃警告

### 现象
项目中 `Divider()` 调用（12+ 处）在 Material 3 最新版已废弃。

### 影响文件
`LoginScreen`、`SettingsScreen`（12+处）、`PortfolioScreen`、`MarketScreen`、`OrdersScreen`、`PriceAlertScreen`

### 解决方案
```kotlin
// ❌ 废弃
Divider()

// ✅ 正确
HorizontalDivider()
```

---

## 系统性改进建议

### 0. 升级 Compose Multiplatform 版本（优先级：高）

当前 1.7.1 是 pre-stable，存在已知 iOS 问题。升级到 1.8.x+ 获得：
- iOS 正式 Stable API 保证
- 滚动性能提升（120Hz ProMotion 支持）
- 无障碍访问（VoiceOver）修复
- 更完整的字体 fallback

```toml
# libs.versions.toml
compose = "1.8.0"  # 从 1.7.1 升级
```

### 1. 迁移到官方多平台导航（优先级：高）

**现状**：Android 用 `androidx.navigation:navigation-compose:2.8.0`，iOS 用自写 back-stack — 两套完全不同的路由系统，维护成本高，且 iOS 缺少原生返回手势动画。

**官方方案**：`org.jetbrains.androidx.navigation:navigation-compose`，API 与 `androidx.navigation` 完全兼容，同时支持 iOS 和 Android：

```toml
# libs.versions.toml — 替换 Android-only 版本
navigation-compose = { module = "org.jetbrains.androidx.navigation:navigation-compose", version = "2.9.2" }
```

```kotlin
// build.gradle.kts — 从 androidMain 移到 commonMain
commonMain.dependencies {
    implementation(libs.navigation.compose)  // 两端共用
}
```

然后把 `AppNavGraph.kt` 从 `androidMain` 移到 `commonMain`，删除 `iosMain/App.kt` 中的手写路由。

**收益**：
- iOS 原生右滑返回手势（自动）
- Android 预测性返回手势（自动）
- 类型安全路由（`@Serializable` data class）
- 深链接支持

### 2. 建立图标规范（优先级：高）

禁止在 UI 代码中直接使用 emoji 字符串，统一用 Material Icons：

```kotlin
// build.gradle.kts — commonMain 已加入
implementation(compose.materialIconsExtended)
```

> ⚠️ **废弃警告**：`compose.materialIconsExtended`（即 `material-icons-extended`）已在
> CMP 1.7.3 冻结，不再更新。新项目应使用 `material-icons-core` 覆盖的图标，
> 其余自定义图标迁移到 Valkyrie 生成的 ImageVector 或 XML vector drawable。
> 详见下方"图标跨平台解决方案"专章。

```kotlin
// ❌ 禁止 — iOS Skia 渲染器不走系统字体 fallback
Text(text = "🔍", fontSize = 20.sp)

// ✅ 正确
Icon(imageVector = Icons.Default.Search, contentDescription = "搜索")
```

可选：建立集中映射表减少 import 散乱：
```kotlin
object AppIcons {
    val Search = Icons.Default.Search
    val Notification = Icons.Default.Notifications
    val Back = Icons.Default.ArrowBack
    val ChevronRight = Icons.Default.ChevronRight
    val Close = Icons.Default.Close
}
```

### 3. 统一列表项交互模式（优先级：中）

**iOS 已知 Bug（官方文档确认）**：`Modifier.clickable` 在 iOS 上会让被点击元素获得焦点，触发 `bringIntoView` 滚动机制，导致页面意外滚动。

解决方案：
```kotlin
// 纯容器行（卡片、列表项）→ 用 Surface(onClick) 作为事件屏障
Surface(onClick = item.onClick, color = Color.White) { ... }

// 内联文字链接（"忘记密码"、"注册"等）→ 加 focusProperties
Text(
    "忘记密码",
    modifier = Modifier
        .clickable { onForgotPassword() }
        .focusProperties { canFocus = false }  // ← 防止 iOS 滚动跳动
)
```

> **注意**：我们之前在 AccountScreen 把 `Surface(onClick)` 改为 `.clickable` 是为了解决另一个问题（emoji 导致命中测试偏移）。升级到 1.8.x 并修复 emoji 后，`Surface(onClick)` 应当恢复——它在事件传播上更正确。

### 4. CJK 字体测试（优先级：中）

Skia 渲染器需要字体文件中包含对应字形。港股标的如"腾讯控股"、"阿里巴巴"等中文名称需验证：

- 在真机（非模拟器）上测试 CJK 渲染
- 若系统 fallback 不足，考虑打包一个 CJK 子集字体（NotoSansCJK-Subset，约 2-3 MB）

### 5. BiometricAuth 平台隔离（优先级：低，已有 expect/actual）

当前实现架构正确，但有两处 `commonMain` 文件直接 import 了平台类：
- `TradeScreen.kt` — `import com.brokerage.core.biometric.BiometricAuth`
- `WithdrawalScreen.kt` — 同上

这两个 import 本身没问题（`BiometricAuth` 是 `commonMain` 的 interface），但需确认没有直接 import `androidMain`/`iosMain` 的实现类。

可优化点：区分 Face ID 和 Touch ID 的 UI 文案：
```kotlin
// iosMain
val biometryType = LAContext().biometryType  // .faceID / .touchID
val prompt = if (biometryType == LABiometryTypeFaceID) "使用 Face ID" else "使用 Touch ID"
```

### 6. `Divider()` → `HorizontalDivider()`（优先级：低）

项目中 12+ 处废弃调用，批量替换：
```kotlin
// ❌ 废弃（Material 3）
Divider()

// ✅ 正确
HorizontalDivider()
```

---

## 图标跨平台解决方案（生产级）

### 1. 为什么 emoji 在 iOS 失效

Compose Multiplatform 在 iOS 上使用基于 Skia 的自定义文字渲染引擎，**不走系统字体 fallback**。Apple Color Emoji 字体和系统符号字体不在 Skia 的字体查找链中，导致 emoji 和部分 Unicode 符号渲染为 `[?]` 方块（详见问题一）。解决根本问题需替换为 Compose-native 的图标方案。

### 2. 五种跨平台图标方案对比

| 方案 | 实现方式 | 包体影响 | 两端一致性 | 适用场景 |
|------|---------|---------|-----------|---------|
| `material-icons-core` | `Icons.Default.*` ImageVector | 小（按需） | ✅ 完全一致 | 通用 UI 图标（**推荐**） |
| `material-icons-extended`（⚠️ 废弃）| 同上 | 大（300+ 图标全量） | ✅ 一致 | **不推荐新项目** |
| Valkyrie SVG→ImageVector | Kotlin 代码生成 | 中（按图标） | ✅ 完全一致 | 自定义品牌/业务图标（**推荐**） |
| XML vector drawable（composeResources）| `painterResource(Res.drawable.xxx)` | 小（资源文件） | ✅ 一致 | 设计团队产出 SVG 时 |
| Icon Font TTF | `FontFamily` + Unicode | 小 | ⚠️ 需注意着色 | iconfont.cn 存量图标迁移 |
| Compottie（KMP Lottie）| Lottie JSON 动画 | 中 | ✅ 一致 | 加载动效、交互动效（待稳定） |

### 3. `material-icons-extended` 废弃详情

- CMP 1.7.3 起停止更新，锁定在 Material Design 2 图标集
- 官方建议迁移到 Material Symbols（新一代图标库，通过 Valkyrie 或 XML drawable 引入）
- `material-icons-core`（约 150 个常用图标）不受影响，仍是稳定依赖
- 影响评估：若只使用 `Icons.Default.*` 下的常用图标，直接改依赖为 `compose.material3` 内置即可；如使用了 Extended 独有图标，需逐一替换

### 4. Valkyrie 使用流程

**Valkyrie** 是 JetBrains 官方工具，将 SVG / XML vector drawable 转换为 Compose `ImageVector` Kotlin 代码。

**IDEA/Android Studio 插件方式**（推荐单图标场景）：
```
File → New → ImageVector
选择 SVG 或 XML 文件 → 自动生成 Kotlin 文件
```

**Gradle 插件方式**（推荐批量转换）：
```kotlin
// build.gradle.kts
plugins {
    id("io.github.composegears.valkyrie") version "0.x.x"
}
valkyrie {
    inputDir = file("src/main/svg")
    outputDir = file("commonMain/kotlin/com/brokerage/ui/icons")
    packageName = "com.brokerage.ui.icons"
}
```

生成产物统一放入：
```
commonMain/kotlin/com/brokerage/ui/icons/
├── AppIcons.kt        # 图标入口对象
├── ic_logo.kt
├── ic_candle_chart.kt
└── ic_hk_flag.kt
```

### 5. XML vector drawable 方式

适合设计师直接交付 SVG 文件的团队：

1. 用 Android Studio **Vector Asset Studio** 将 SVG 转为 XML
2. 放入 `composeApp/src/commonMain/composeResources/drawable/*.xml`（CMP 1.6+ 支持跨平台 composeResources）
3. 在代码中调用：

```kotlin
// commonMain
import com.brokerage.generated.resources.Res
import com.brokerage.generated.resources.ic_search

Icon(
    painter = painterResource(Res.drawable.ic_search),
    contentDescription = "搜索"
)
```

优点：设计师可直接参与交付流程，无需工程师介入转换。

### 6. 本项目推荐策略（三层架构）

```kotlin
// 层 1：通用 UI 图标 → material-icons-core（已有，稳定）
Icon(Icons.Default.Search, contentDescription = "搜索")
Icon(Icons.Default.Notifications, contentDescription = "通知")

// 层 2：品牌/业务图标 → Valkyrie 生成 ImageVector（推荐引入）
// 放在 commonMain/kotlin/com/brokerage/ui/icons/AppIcons.kt
object AppIcons {
    val Logo = /* Valkyrie 生成的 ImageVector */
    val CandleChart = /* 自定义 K 线图标 */
    val HkFlag = /* 港股标识 */
    val UsFlag = /* 美股标识 */
}

// 层 3：动效图标 → Compottie（等 1.0 正式版后引入）
// implementation("io.github.alexzhirkevich:compottie:1.x.x")
```

### 7. 短期行动项（本项目）

1. **修复剩余 emoji**：将 `LoginScreen`、`KycScreen`、`TradeScreen`、`FundingScreen` 中剩余 emoji 替换为 `Icons.Default.*`
2. **移除 extended 依赖**：去除 `implementation(compose.materialIconsExtended)` 或标记 `// TODO: 迁移 Material Symbols`，改依赖 `material-icons-core`（`compose.material3` 内置）
3. **建立品牌图标库**：创建 `AppIcons.kt`，通过 Valkyrie 引入 logo、业务图标，统一管理自定义图标

---

## 修复状态总结

| 问题 | 状态 | 备注 |
|------|------|------|
| 底部导航 emoji 图标 | ✅ 已修复 | 换 Material Icons |
| MarketScreen 顶部 emoji 按钮 | ✅ 已修复 | 换 Material Icons |
| Inputs.kt 搜索/清除/密码可见 emoji | ✅ 已修复 | 换 Material Icons |
| LoginScreen emoji（📈 👁️ 🍎 📱）| ✅ 已修复 | 换 Material Icons |
| RegisterScreen emoji（← 👁️）| ✅ 已修复 | 换 Material Icons |
| KycScreen emoji（📸 ✅ 📷 💡 👤 📄 ←）| ✅ 已修复 | 换 Material Icons |
| TradeScreen emoji（⚠️ × 2）| ✅ 已修复 | 换 Material Icons |
| FundingScreen emoji（➕ ➖ 💳 ℹ️ →）| ✅ 已修复 | 换 Material Icons |
| WithdrawalScreen emoji（💡 ⚠️）| ✅ 已修复 | 换 Material Icons |
| AccountScreen emoji（👤 →）| ✅ 已修复 | 换 Material Icons |
| HelpScreen emoji（→ × 3）| ✅ 已修复 | 换 Material Icons |
| Cards.kt emoji（⚠️ ✅ ❌）| ✅ 已修复 | 换 Material Icons |
| SlideToConfirmButton emoji（→）| ✅ 已修复 | 换 Material Icons |
| PhoneVerificationLoginScreen emoji（📈）| ✅ 已修复 | 换 Material Icons |
| OrderDetailScreen emoji（←）| ✅ 已修复 | 换 Material Icons |
| SettingsScreen emoji（←）+ Divider × 11 | ✅ 已修复 | 换 Material Icons；HorizontalDivider |
| `Divider()` 废弃调用（29 处）| ✅ 已修复 | 全局批量替换 HorizontalDivider() |
| PlistSanityCheck 崩溃 | ✅ 已修复 | `enforceStrictPlistSanityCheck = false` |
| iOS 无底部导航 | ✅ 已修复 | iosMain App.kt 手写路由（临时方案）|
| AccountScreen 点击失效 | ✅ 已修复 | Surface → clickable（临时方案）|
| Android 底部遮挡手势条 | ✅ 已修复 | `navigationBarsPadding()` |
| CMP 版本升级 1.7.1 → 1.8.0 | ✅ 已升级 | libs.versions.toml 更新 |
| 多平台导航库配置 | ✅ 已配置 | navigation-compose-multiplatform 2.9.2 入 toml（待迁移实施）|
| 迁移官方多平台导航（代码层面）| ⚠️ 待迁移 | 替换手写 iOS 路由，统一两端 AppNavGraph |
| OrdersScreen `Surface(onClick)` | 📋 待验证 | emoji 修复后升级 1.8.x 重测（预计正常）|
| StockDetailScreen 新闻行点击 | 📋 待验证 | emoji 修复后升级 1.8.x 重测（预计正常）|
| CJK 字体真机验证 | 📋 待测试 | 港股中文名称 |
| BiometricAuth Face ID/Touch ID 区分 | 📋 规划中 | UX 优化 |

---

## 参考资料

- [Compose Multiplatform 1.8.0 — iOS Stable 公告](https://blog.jetbrains.com/kotlin/2025/05/compose-multiplatform-1-8-0-released-compose-multiplatform-for-ios-is-stable-and-production-ready/)
- [官方：Compose Multiplatform Navigation](https://kotlinlang.org/docs/multiplatform/compose-navigation.html)
- [官方：iOS 触摸事件处理](https://kotlinlang.org/docs/multiplatform/compose-ios-touch.html)
- [官方：与 SwiftUI 集成](https://kotlinlang.org/docs/multiplatform/compose-swiftui-integration.html)
- [官方：平台 UI 行为差异](https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-platform-specifics.html)
- [ProAndroidDev：KMP 生物认证实践](https://proandroiddev.com/biometric-authorization-in-compose-multiplatform-app-a00e0fa64640)
- [Compose Multiplatform 1.10.0 — Navigation 3](https://blog.jetbrains.com/kotlin/2026/01/compose-multiplatform-1-10-0/)
- [Valkyrie — SVG/XML to ImageVector 官方 IDEA 插件](https://plugins.jetbrains.com/plugin/24786-valkyrie)
- [svg-to-compose — Google 开源 SVG 转 Compose 工具](https://github.com/DevSrSouza/svg-to-compose)
- [Compottie — KMP Lottie 动画库](https://github.com/alexzhirkevich/compottie)
- [Material Symbols — 新一代 Google 图标库](https://fonts.google.com/icons)
