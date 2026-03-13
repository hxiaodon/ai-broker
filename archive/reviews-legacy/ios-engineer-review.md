# iOS 工程评审报告

**评审对象**：mobile-app-design v1 / v2 / v3-supplement 设计文档 + 9 个 HTML 原型页面
**评审视角**：iOS 工程师（Swift/SwiftUI）
**评审日期**：2026-03-11
**评审人**：iOS Engineer Agent

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
9. [港股适配问题](#9-港股适配问题)
10. [工期估算建议](#10-工期估算建议)
11. [对产品/UX 的建议](#11-对产品ux-的建议)

---

## 1. 技术可行性评估

### 1.1 直接可行的设计元素

以下设计在 SwiftUI/UIKit 中均为标准实现，技术风险低：

| 功能 | 实现方式 | 难度 |
|------|---------|------|
| Tab Bar 导航（4 个 Tab） | `TabView` + `TabItem` | 低 |
| 行情列表 + 骨架屏 | `LazyVStack` + `redacted(.placeholder)` | 低 |
| 价格颜色翻转（红涨绿跌/绿涨红跌） | `@AppStorage` 偏好 + `Color` extension | 低 |
| 暗色模式 | `@Environment(\.colorScheme)` + Asset Catalog | 低 |
| 下单页订单类型切换 | `Picker` style `.segmented` 或自定义 Tab | 低 |
| 订单状态时间轴 | `LazyVStack` + 自定义 TimelineView | 低-中 |
| 出入金记录列表 | `List` + `Section` 按日期分组 | 低 |
| 进度条（KYC 步骤） | `ProgressView(value:total:)` | 低 |
| 大字模式 | `DynamicType` + `.scaledFont()` 全局适配 | 低-中 |

### 1.2 技术挑战较高的设计元素

| 功能 | 挑战来源 | 风险等级 |
|------|---------|---------|
| K 线图（蜡烛图）+ 分时图 | Swift Charts 原生不支持蜡烛图类型，需要自定义 | 高 |
| 滑动确认手势（Slide to Confirm） | 需纯 SwiftUI 手势状态机，防止快速滑过 | 中 |
| 实时 WebSocket + 列表差量更新 | 高频更新场景下的主线程渲染压力 | 高 |
| KYC 人脸识别 + 活体检测 | 依赖第三方 SDK，集成复杂，合规要求苛刻 | 高 |
| K 线图十字线 + 双指缩放 + 拖动 | 多手势并发冲突，SwiftUI 手势优先级管理 | 高 |
| 电子签名手写板 | SwiftUI 无内建 canvas，需 UIKit 桥接 | 中 |
| 换汇页面 15 秒汇率倒计时 + 竞态条件 | 用户输入中途汇率刷新导致数字跳变 | 中 |
| 港股 Tick Size 动态步进器 | 不同价格区间对应不同最小变动单位，需动态计算 | 中 |

### 1.3 设计文档与 iOS 平台存在差异之处

1. **"记住登录状态" 勾选框**（v3 邮箱登录页）：iOS 上常规做法是通过 Keychain 持久化 Refresh Token，不需要用户手动勾选。建议去掉该选项，改为系统层面的自动持久化，仅在"退出登录"时清除。

2. **日期选择器格式**：v3 设计 `1990-01-15` 格式的日期输入框，iOS 原生 `DatePicker` 会根据系统区域自动调整格式，不宜限定为固定格式展示。建议用 `DatePicker` 的 `.compact` 样式。

3. **底部导航按钮的安全区域**：原型中"滑动确认"按钮固定在页面底部，在 iPhone 有 Home Indicator 的机型（iPhone X 及以后）需预留 `safeAreaInsets.bottom`，否则会被 Home Indicator 遮挡。

4. **手机号国家码选择器**：设计中有 `+86▼` 的下拉组件，iOS 原生没有对应的 Picker 样式，需自定义实现或使用 `Menu` 包裹的 `Picker`。

---

## 2. 性能关注点

### 2.1 WebSocket 实时数据更新

**风险**：自选列表可能同时订阅数十只股票的实时报价，每只股票每秒推送 1 次，高峰期会产生大量 UI 更新。

**具体问题**：
- 若每条推送都触发 `@Published` 变化导致整个列表重渲染，在低端设备上会出现掉帧（目标 60fps）
- WebSocket 回调默认在后台线程，需要正确切换到 `@MainActor` 更新 UI，否则会有 Swift Strict Concurrency 编译警告甚至运行时崩溃

**推荐方案**：
```swift
// 使用 actor 隔离数据层，批量更新 UI
actor QuoteStore {
    private var quotes: [String: Quote] = [:]

    func update(_ quote: Quote) {
        quotes[quote.symbol] = quote
    }
}

// ViewModel 使用节流（throttle）控制刷新频率
// Combine: publisher.throttle(for: .milliseconds(200), scheduler: RunLoop.main, latest: true)
```

- 对自选列表使用 `throttle(200ms)` 节流，避免每秒更新触发过多重渲染
- 使用 `@Observable`（iOS 17+）替代 `ObservableObject`，粒度更细的依赖追踪可大幅减少不必要的 View 刷新
- 若需兼容 iOS 16，退回 `ObservableObject` 时需手动用 `id()` 标记稳定的 List item

### 2.2 K 线图渲染性能

**风险**：日 K 数据通常有 1-5 年历史（250-1250 根蜡烛），月 K 理论上更长。一次性渲染全量数据会造成卡顿，且内存占用高。

**具体问题**：
- 自定义蜡烛图如用 `Path` 逐根绘制，1000 根蜡烛在 `drawRect` 中的耗时不可忽略
- 双指缩放 + 拖动时需要实时重计算可视范围内的蜡烛数量

**推荐方案**：
- 仅渲染可视区域内的蜡烛（viewport clipping）
- 使用 Metal（`MTKView`）或 Core Graphics 离屏渲染，避免 GPU 和 CPU 争抢
- 图表数据用 `ContiguousArray<OHLCV>` 而非 `[OHLCV]`，减少内存访问开销
- 预先计算均线数组，不在渲染时实时计算

### 2.3 持仓列表实时盈亏更新

**风险**：持仓列表中每个 cell 都包含实时浮亏，WebSocket 价格更新时需要重算所有持仓的盈亏。

**具体问题**：
- 若持仓量大（20+ 只股票），且每秒均有价格推送，计算开销会叠加
- 使用 `Decimal` 计算（合规要求）比 `Double` 慢约 10-20 倍，需特别关注

**推荐方案**：
- 在后台线程（非 MainActor）完成所有 `Decimal` 计算，算完后切换 MainActor 更新
- 对持仓列表同样施加 `throttle`，300ms 刷新一次即可满足用户体验需求

### 2.4 内存管理

**风险**：K 线历史数据 + WebSocket 消息缓存 + 多图表同时存在时，内存压力可能超出 200MB 目标。

**重点关注**：
- 离开股票详情页后必须释放图表数据缓存，用 `weak` 引用或显式 `cancel()` 取消 WebSocket 订阅
- 搜索页建议对搜索结果图表缩略图使用懒加载 + 内存缓存（`NSCache`），避免 10+ 个缩略图同时渲染
- KYC 流程中相机捕获的图像必须及时压缩并释放原始 `UIImage`，证件照原图一般为 5-15MB

---

## 3. 平台特性建议

### 3.1 Face ID / Touch ID 深度集成

设计已规划生物识别用于下单确认和出入金确认，这是正确的。需要注意以下 iOS 平台细节：

- **策略选择**：使用 `LAContext` 的 `.biometryCurrentSet` 策略（而非 `.biometryAny`）。当用户在系统中新增了指纹或面容数据时，已存储在 Keychain 中的凭证会自动失效，强制用户重新密码登录并重新授权。这符合 security-compliance.md 的要求。
- **降级逻辑**：生物识别失败 3 次后必须降级到密码输入（v3 已有此设计），iOS 系统本身也会在多次失败后禁用生物识别。
- **改单/撤单是否需要生物识别**：v3 设计改单页面的确认按钮写了 `Face ID`，但撤单弹窗没有。**建议统一**：改单需要生物识别（改价格金额），撤单不需要（纯取消操作，无资金风险）。

### 3.2 Push Notifications

- KYC 审核结果通知、订单成交通知、出金到账通知均需要 Push，建议使用 APNs + `UserNotifications` framework
- 交易通知属于高时效性通知（time-sensitive），应在 `UNNotificationContent` 中设置 `interruptionLevel = .timeSensitive`（iOS 15+），避免被系统通知摘要延迟推送
- 价格提醒通知（v2 新增功能）：建议使用服务端推送，而非客户端轮询，因为 App 在后台可能被系统挂起

### 3.3 Live Activities（建议新增）

v3 的订单状态时间轴（"订单创建 → 风控通过 → 交易所确认 → 部分成交"）非常适合用 **Live Activities**（iOS 16.2+）实现：

- 用户提交订单后，锁屏和灵动岛可实时显示订单执行状态
- 部分成交时，灵动岛可显示"AAPL 已成交 50/100 股"
- 完全成交后自动消失，并推送 notification

这是对标 Futu、Tiger 的差异化体验，建议列为 P1 迭代。

### 3.4 Widgets（建议新增）

- 自选股小组件（Home Screen Widget）：显示 2-5 只自选股的实时价格
- 资产总览小组件：显示总资产 + 今日盈亏
- 使用 `WidgetKit` + `TimelineProvider`，配合 App Group 共享数据

同样建议列为 P1，但 WidgetKit 实现时需注意：Widget 更新频率受 iOS 系统限制，不适合显示 tick 级实时数据，1-5 分钟延迟是可接受的。

### 3.5 Haptic Feedback（震动反馈）

设计文档中提到"成功时震动反馈"，但未细化规格。推荐以下标准：

| 事件 | 震动类型 | 实现 |
|------|---------|------|
| 下单成功 | `.success` | `UINotificationFeedbackGenerator` |
| 下单失败 | `.error` | `UINotificationFeedbackGenerator` |
| 滑动确认完成 | `.heavy` | `UIImpactFeedbackGenerator` |
| 按钮点击 | `.light` | `UIImpactFeedbackGenerator` |
| 价格提醒触发 | `.warning` | `UINotificationFeedbackGenerator` |

### 3.6 Spotlight 搜索集成

将自选股索引到 Spotlight（`CSSearchableIndex`），用户可在系统搜索中直接搜索股票代码跳转 App，是一个低成本高价值的平台特性。

---

## 4. 安全实现评估

### 4.1 Keychain 存储策略

设计文档提到 Keychain 存储，但未明确具体字段。以下为推荐的 Keychain 存储规范：

| 存储内容 | Keychain 保护级别 | 说明 |
|---------|-----------------|------|
| Access Token | `.whenUnlockedThisDeviceOnly` | 短期 token，仅本设备 |
| Refresh Token | `.whenUnlockedThisDeviceOnly` | 长期 token，不可备份到 iCloud |
| 生物识别授权密钥 | `.whenPasscodeSetThisDeviceOnly` | 强制要求设备有锁屏密码 |
| 用户账号 ID | `.afterFirstUnlockThisDeviceOnly` | 允许后台访问（Widget 需要） |

**严禁存放在 UserDefaults 的内容**：任何 token、账号密码、账户余额、银行卡信息。

### 4.2 证书固定（Certificate Pinning）

security-compliance.md 要求证书固定，iOS 实现需注意：

- 使用 `URLSession` 的 `didReceive challenge` delegate 实现公钥固定（Public Key Pinning），而非证书指纹固定，以避免证书续期时 App 失效
- 必须内置至少 **2 个备用公钥**（backup pins），用于证书轮换过渡期
- 固定失败时上报事件（不阻断，仅在首周上报），监测是否有异常的 MitM 攻击
- **注意**：Plaid SDK 有自己的证书固定策略，与 App 的全局 `URLSession` delegate 不能冲突，需单独为 Plaid 使用的 `URLSession` 配置

### 4.3 越狱检测

需要实现多维度检测，单一检测方法容易被绕过：

```swift
// 检测策略组合（不依赖单一方法）：
// 1. 检测 cydia:// URL scheme
// 2. 检测 /Applications/Cydia.app 等路径是否存在
// 3. 尝试写入 /private/jailbreak_test.txt（沙盒外路径）
// 4. 检测 dyld 中是否有可疑动态库注入（MobileSubstrate）
// 5. 检测 fork() 系统调用是否可用（非越狱设备不可用）
```

越狱设备上的行为：**警告但不强制退出**（与 security-compliance.md 一致），记录风险事件到服务端，禁用交易功能，但允许查看行情。

### 4.4 截屏防护

v3 设计文档要求敏感页面防止截屏，iOS 实现方案：

```swift
// 方案1：覆盖层遮盖（适用于 SwiftUI）
// 在 .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification))
// 检测到截屏/录屏时，在 Window 最上层盖上遮罩

// 方案2：SecureField 变体
// 仅适用于文本内容

// 方案3：UITextField.isSecureTextEntry = true 的 UIView 桥接技巧
// 利用系统安全文本框的截屏防护特性覆盖敏感 View
```

**需要截屏防护的页面**：KYC 证件拍照确认页、出入金页面（含账户余额）、账户详情页（含证件号/银行卡号）。

**注意**：Screen Recording 检测用 `UIScreen.main.isCaptured`，需要在 App 进入这些页面时检测并提示。

### 4.5 网络传输安全

- 在 `Info.plist` 中保持 ATS 全局开启（`NSAllowsArbitraryLoads = false`），不做任何豁免
- WebSocket 连接必须使用 `wss://`（TLS），`URLSessionWebSocketTask` 默认支持
- 所有 API 请求的 HMAC-SHA256 签名（trading endpoints）在 iOS 端用 `CryptoKit.HMAC<SHA256>` 实现，无需第三方库

---

## 5. 第三方库选型

### 5.1 图表库：danielgindi/Charts

**评估结论：不推荐用于 MVP，建议替换为自定义 Swift Charts 实现或评估 LightweightCharts**

| 维度 | 评估 |
|------|------|
| K 线图支持 | 支持 CandleStick chart，但样式定制复杂 |
| Swift/SwiftUI 集成 | 基于 UIKit，需要 `UIViewRepresentable` 桥接，与 SwiftUI 状态管理摩擦大 |
| 维护状态 | 活跃维护，但版本迭代较慢，Swift 6 strict concurrency 适配尚未完成 |
| 性能 | 中等，大数据量（1000+ 蜡烛）时需注意 |
| 手势定制 | 支持但需大量 override，与 SwiftUI 手势冲突需要额外处理 |

**推荐替代方案**：
- **自定义 Swift Charts + CALayer 覆盖**：Swift Charts（Apple 官方，iOS 16+）处理分时图/折线图，蜡烛图用 `Canvas` 或 `CALayer` 自绘，能与 SwiftUI 无缝集成
- **TradingView Lightweight Charts（Web 内嵌）**：用 `WKWebView` 内嵌 TradingView 的 Lightweight Charts，图表体验专业，但有一定性能开销和通信延迟
- **LightweightCharts（Swift 原生版）**：TradingView 有官方 iOS SDK（`https://github.com/tradingview/lightweight-charts-ios`），基于 `WKWebView` 封装，接口简洁，金融图表支持完善，**推荐评估**

### 5.2 WebSocket：Starscream

**评估结论：可接受，但需要评估是否必要**

| 维度 | 评估 |
|------|------|
| 功能完整性 | 支持 RFC 6455 全规范，支持 TLS/SSL，支持自定义 HTTP 头 |
| 维护状态 | 活跃维护（Vapor 生态） |
| Swift Concurrency | 尚未原生支持 async/await，需要自行封装 |
| 替代方案 | `URLSessionWebSocketTask`（iOS 13+，Apple 官方） |

**具体建议**：
- 若 iOS 最低部署版本 >= 13，优先使用 `URLSessionWebSocketTask`，无需引入额外依赖
- `URLSessionWebSocketTask` 支持自动 ping/pong，支持证书固定（通过 `URLSession` delegate），与 `async/await` 天然集成
- 仅在需要兼容 iOS 12 以下，或需要 Starscream 特有功能（如自定义协议扩展）时才引入 Starscream

### 5.3 OCR：证件识别 SDK

**评估结论：必须使用第三方专业 SDK，iOS 原生 Vision 框架能力不足**

iOS 原生 `Vision` 框架（`VNRecognizeTextRequest`）可以识别通用文字，但不具备：
- 身份证/护照版面结构化识别（字段分离）
- 各国证件格式的预训练模型
- OCR 失败降级和质量评分

**推荐第三方 SDK**：

| SDK | 适用场景 | 合规资质 |
|-----|---------|---------|
| 阿里云实人认证 | 中国大陆用户为主，支持中国身份证/护照 | 公安部接入，合规 |
| 腾讯云慧眼 | 类似阿里，支持港澳台证件 | 合规 |
| Jumio | 国际化，支持 200+ 国家证件，SEC/SFC 认可 | GDPR/金融合规 |
| Onfido | 欧美合规，API-first，集成友好 | FCA/SEC 认可 |

**针对本产品（美港股，目标用户含中国大陆、香港、美国）**：
- 建议采用 **Jumio 或 Onfido** 作为国际化方案，同时支持中国身份证、香港 HKID、美国驾照/护照
- 如果用户群体以中国大陆为主，可使用 **阿里云实人认证 SDK**，成本更低

**iOS 集成注意事项**：
- 第三方 KYC SDK 体积通常较大（10-50MB），会显著影响 App 包体积（设计目标 < 50MB）
- 部分 SDK 使用 CocoaPods，需要转换为 SPM 或手动集成 XCFramework
- SDK 的相机权限使用需要在 `Info.plist` 单独声明用途字符串（NSCameraUsageDescription）

### 5.4 人脸识别/活体检测 SDK

**评估结论：与 OCR SDK 往往捆绑，选型需统一**

如选 Jumio/Onfido，其 SDK 已内置活体检测（liveness detection）。如选国内方案：
- **阿里云/腾讯云实人认证**均包含活体检测（眨眼、点头、摇头等动作）
- 独立选用：Face++ SDK（旷视），支持活体检测 + 人脸比对

**苹果平台特殊限制**：Apple App Store 审核政策要求，任何人脸数据处理必须在 Privacy Policy 中明确披露，且不能将人脸数据用于广告目的。

### 5.5 Plaid SDK

**评估结论：可行，但需关注以下问题**

| 维度 | 评估 |
|------|------|
| 功能 | 银行账户即时连接验证、余额查询、ACH 授权 |
| iOS SDK | 官方提供 `PlaidLink` iOS SDK（支持 SPM） |
| 覆盖范围 | 主要覆盖美国银行，港币 HKD 账户不支持 |
| 合规 | 持有美国 FinCEN 注册，符合 AML 要求 |

**关键问题**：
- **HKD 账户无法使用 Plaid**：香港银行系统不在 Plaid 支持范围内。HKD 银行卡验证只能走小额打款验证（micro-deposit）。这需要告知产品，在 UI 上对 USD 和 HKD 账户使用不同的验证流程。
- **Plaid 引导流程（Link Flow）**：Plaid 有自己的 OAuth 回调流程，需要在 `AppDelegate` 或 `SceneDelegate` 中处理 Universal Links 回调，与 App 内的页面跳转逻辑需要仔细协调。
- **包体积影响**：PlaidLink iOS SDK 约 10MB。

### 5.6 网络层：Alamofire

**评估结论：可以使用，但有更轻量的替代方案**

设计文档选用 Alamofire，但项目的 `CLAUDE.md` 技术栈中只写了 `URLSession with async/await`。

**建议**：
- 若团队熟悉 Alamofire，可以保留，但需升级到 5.x 版本以支持 `async/await`
- 更推荐**不引入 Alamofire**，直接使用 `URLSession` + `async/await` + 简单的 Request Builder 封装，减少依赖，也更容易配置证书固定
- 交易类 API 的 HMAC 签名逻辑用 `CryptoKit`（Apple 官方），无需额外库

---

## 6. KYC 流程实现复杂度

### 6.1 整体评估

v3 设计的 9 步 KYC 流程是整个项目**实现复杂度最高的模块**，也是**风险最高的模块**。以下逐步分析：

| 步骤 | 技术复杂度 | 主要挑战 |
|------|-----------|---------|
| Step 1: 个人信息 | 低 | 表单验证、证件号格式校验 |
| Step 2: 证件上传 + OCR | 高 | 相机权限、图像质量检测、OCR SDK 集成、失败降级 |
| Step 3: 人脸识别 + 活体检测 | 高 | 第三方 SDK 集成、相机取景框定制、失败重试逻辑 |
| Step 4: 就业信息 | 低 | 条件显示字段，动态表单 |
| Step 5: 财务状况 | 低 | 纯单选/多选 |
| Step 6: 投资评估 | 低 | 纯单选 |
| Step 7: 税务 / W-8BEN | 中 | 税务协定条款自动填充、电子签名 |
| Step 8: 风险披露 | 中 | 长文档展开、强制阅读检测（滚动到底部才可继续） |
| Step 9: 协议签署 + 手写签名 | 中-高 | 手写签名画板（需 UIKit 桥接）、签名图像上传 |

### 6.2 断点续传实现

v3 设计要求"每步自动保存进度，退出后可续传"，iOS 实现方案：

```
服务端保存：每步完成时 HTTPS POST 到 /kyc/progress，服务端持久化
本地缓存：用 Core Data / SwiftData 缓存当前步骤编号和已填表单数据（不含证件图像）
启动时：检查服务端 KYC 状态，若为 IN_PROGRESS 则提示续传
```

**注意**：证件图像（敏感数据）不应本地持久化，仅在内存中保持至上传成功。

### 6.3 相机集成

- 证件拍照用 `AVCaptureSession` 自定义相机（非系统相机），以便添加证件边缘检测引导框、实时质量评估（模糊检测、光线不足检测）
- 人脸识别取景框（椭圆 overlay）需要 `AVCaptureVideoPreviewLayer` + `CAShapeLayer` 蒙版实现
- **重要**：`AVCaptureSession` 必须在后台线程启动，切勿在 MainThread 调用 `startRunning()`，否则会阻塞 UI

### 6.4 强制阅读检测

风险披露页（Step 8）要求用户"阅读完整"才可继续。SwiftUI 实现方案：

```swift
// 用 ScrollViewReader 检测用户是否滚动到底部
ScrollView {
    VStack { /* 长文本内容 */ }
    Color.clear
        .frame(height: 1)
        .id("bottom")
        .onAppear { hasReadToBottom = true }
}
// 仅当 hasReadToBottom == true 时才激活"下一步"按钮
```

### 6.5 手写签名

UIKit 中用 `UIBezierPath` + `CAShapeLayer` 实现，SwiftUI 需通过 `UIViewRepresentable` 桥接：

```swift
struct SignatureView: UIViewRepresentable {
    @Binding var signatureImage: UIImage?
    // 使用 UITouch 事件收集坐标，绘制 bezier path
    // 完成后导出为 UIImage（黑底白线或白底黑线）
}
```

- 签名图像在上传前需压缩到合理大小（建议 PNG，< 500KB）
- 法律有效性需确认：电子签名 + 时间戳 + 设备指纹 + IP 地址联合记录

---

## 7. 出入金模块评估

### 7.1 Plaid 集成流程

```
用户点击"使用 Plaid 验证"
  → 调用 PlaidLink.create(token:onSuccess:onExit:)
  → 展示 Plaid 提供的 Link UI（Modal）
  → 用户在 Plaid UI 中选择银行并授权
  → onSuccess 回调返回 publicToken
  → App 将 publicToken 发送到自有后端
  → 后端用 publicToken 换取 accessToken（服务端操作）
  → 后端完成银行账户绑定
```

iOS 端的主要工作是调起 Plaid Link SDK 并处理回调，逻辑相对简单。复杂度主要在后端。

### 7.2 安全性注意事项

- **银行账号输入**：输入时使用 `UITextField.isSecureTextEntry = false`（明文，方便用户确认），但"确认账号"字段应使用 `isSecureTextEntry = true` 防止旁窥
- **确认账号字段**：禁止粘贴操作（`shouldChangeCharactersIn` delegate），防止用户直接粘贴未手动输入验证
- 银行卡信息本地**只缓存 `bankAccountId`（后端脱敏 ID）和尾号 4 位**，完整账号不在客户端存储

### 7.3 出金流程的生物识别时机

v3 设计在"确认入金弹窗"中集成了 Face ID，这是正确的。出金页面未见明确说明，建议**出金确认也必须经过生物识别**，且出金金额越大应有更明显的风险确认文案。

### 7.4 换汇页面的竞态条件

换汇页设计了"15 秒后汇率刷新"，在倒计时结束刷新时，若用户正在输入金额，会产生数字跳变问题：

**建议**：汇率刷新仅更新参考汇率显示，不主动重算用户已输入的金额；仅在用户修改输入金额时才用当前最新汇率计算结果。确认按钮点击时，获取一次最新汇率并重算，若与用户看到的汇率偏差 > 0.5%，弹窗提示"汇率已更新，请确认新金额"。

### 7.5 双币种账户展示

出入金首页展示 USD 和 HKD 双账户余额，需注意：

- `Decimal` 类型精确存储，显示时使用 `NumberFormatter` 配置 `currencyCode` 和 `locale` 分别格式化
- HKD 与 USD 的最小显示单位不同（HKD 通常显示整数或 2 位小数），避免"HK$5,200.00" 和 "HK$5,200" 混用

---

## 8. 交互实现评估

### 8.1 滑动确认手势（Slide to Confirm）

这是设计中最核心的自定义手势组件，需要仔细实现：

**实现要点**：

```swift
struct SlideToConfirmButton: View {
    var onConfirm: () -> Void
    @State private var offset: CGFloat = 0
    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景轨道
                RoundedRectangle(cornerRadius: 8)
                    .fill(buyColor.opacity(0.3))

                // 滑块
                Circle()
                    .fill(Color.white)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = max(0, min(value.translation.width,
                                                   geometry.size.width - 50))
                            }
                            .onEnded { value in
                                if offset > geometry.size.width * 0.85 {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    onConfirm()
                                } else {
                                    withAnimation(.spring()) { offset = 0 }
                                }
                            }
                    )

                // 文字（随滑动淡出）
                Text("滑动确认买入 →")
                    .opacity(1 - offset / (geometry.size.width * 0.5))
            }
        }
    }
}
```

**安全性**：需要设定最小滑动距离（85% 以上）才触发确认，防止误触。滑块松手未到达阈值时自动弹回。

**防抖**：确认触发后立即禁用手势（`.disabled(isSubmitting)`），防止 v2 要求的"2 秒内禁止重复提交"场景。

### 8.2 K 线图手势体系

K 线图需要支持三种手势，它们在 SwiftUI 中存在冲突需要处理：

| 手势 | 功能 | 冲突情况 |
|------|------|---------|
| 单指拖动 | 水平滚动历史数据 | 与 ScrollView 父级冲突 |
| 双指捏合 | 缩放时间维度（蜡烛数量） | 优先级高于拖动 |
| 长按 | 显示十字线 + 数据面板 | 与拖动手势冲突 |

**解决方案**：
- 图表区域使用独立的 `UIView`（通过 `UIViewRepresentable`），在 UIKit 层用 `UIPanGestureRecognizer` + `UIPinchGestureRecognizer` 处理，通过 `requiresFailureOf` 设定优先级
- 长按手势用 `UILongPressGestureRecognizer`，识别后切换到十字线模式，此时拖动手势变为移动十字线

### 8.3 价格闪烁高亮动画

v2 设计要求"价格变化时 0.5s 闪烁高亮"。SwiftUI 实现：

```swift
struct PriceLabel: View {
    let price: Decimal
    let previousPrice: Decimal?
    @State private var isFlashing = false

    var body: some View {
        Text(price, format: .currency(code: "USD"))
            .foregroundColor(isFlashing ? flashColor : .primary)
            .animation(.easeOut(duration: 0.5), value: isFlashing)
            .onChange(of: price) { _, newPrice in
                guard let prev = previousPrice, newPrice != prev else { return }
                isFlashing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFlashing = false
                }
            }
    }

    var flashColor: Color {
        guard let prev = previousPrice else { return .primary }
        return price > prev ? .green : .red
    }
}
```

**性能注意**：自选列表中每个 cell 都有一个价格 label 在监听变化，若同时有 20+ 个动画在运行，需要测试低端设备的帧率。

### 8.4 骨架屏

v2 要求用骨架屏替代 Loading Spinner，SwiftUI 原生支持：

```swift
// 使用 redacted + shimmer 效果
List(viewModel.isLoading ? Stock.placeholders : viewModel.stocks) { stock in
    StockRow(stock: stock)
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
}
```

SwiftUI `.redacted(.placeholder)` 会将 Text/Image 替换为灰色块，配合自定义 shimmer 动画（`LinearGradient` 平移）即可实现标准骨架屏效果。

### 8.5 数字滚动动画（资产变化）

v1 设计提到"数字滚动动画（资产变化）"，iOS 实现：

- iOS 17+ 可用 `ContentTransition.numericText()` 实现数字过渡动画（官方支持）
- iOS 16 以下需要自定义，用 `withAnimation` + 数字分段逐位渲染

---

## 9. 港股适配问题

港股的特殊规则在设计文档中（尤其 v3 的 3.10 节）已有初步设计，但作为 iOS 工程师，以下问题需要在代码层面明确处理：

### 9.1 手数（Board Lot）处理

港股买卖以"手"为单位，每只股票的每手股数不同（如腾讯 100 股/手，中国移动 200 股/手，汇丰 400 股/手）。

**iOS 端需要实现**：
- 数量输入框的 `step` 值不是固定的，需根据当前股票的 `lotSize` 动态设置
- 快捷按钮显示"1手/2手/5手"而非固定股数
- 输入非整数手数时实时提示"港股需以手为单位，最近的整数手为 X 手"
- 最大可买量计算：`floor(availableBalance / (price * lotSize)) * lotSize`

### 9.2 Tick Size（最小变动价位）

港股的 Tick Size 随价格区间动态变化，数量超过 10 个价格区间的规则，必须用完整的规则表驱动：

```swift
struct HKTickSizeTable {
    static func tickSize(for price: Decimal) -> Decimal {
        switch price {
        case ..<Decimal(0.25): return Decimal(string: "0.001")!
        case Decimal(0.25)..<Decimal(0.5): return Decimal(string: "0.005")!
        case Decimal(0.5)..<Decimal(10): return Decimal(string: "0.01")!
        case Decimal(10)..<Decimal(20): return Decimal(string: "0.02")!
        case Decimal(20)..<Decimal(100): return Decimal(string: "0.05")!
        case Decimal(100)..<Decimal(200): return Decimal(string: "0.1")!
        case Decimal(200)..<Decimal(500): return Decimal(string: "0.2")!
        case Decimal(500)..<Decimal(1000): return Decimal(string: "0.5")!
        case Decimal(1000)..<Decimal(2000): return Decimal(string: "1")!
        case Decimal(2000)..<Decimal(5000): return Decimal(string: "2")!
        default: return Decimal(string: "5")!
        }
    }
}
```

价格步进器的 `+/-` 按钮必须使用 `tickSize` 而非固定 `0.01`。

### 9.3 港股交易时段的多状态处理

港股有以下特殊时段，UI 状态机比美股复杂：

| 时段 | HKT | 下单限制 |
|------|-----|---------|
| 开市前竞价 | 09:00-09:30 | 仅可提交竞价限价盘 |
| 早市 | 09:30-12:00 | 正常交易 |
| 午休 | 12:00-13:00 | 禁止下单 |
| 午市 | 13:00-16:00 | 正常交易 |
| 收市竞价 | 16:00-16:10 | 仅可提交竞价限价盘（价格 ±5% 内） |

iOS 需要一个实时时区感知的"市场状态计算器"，结合服务端推送的市场状态（避免时区处理错误）：

```swift
// 永远以 HKT（Asia/Hong_Kong）时区计算港股时段
let hktCalendar = Calendar(identifier: .gregorian)
// ... 配置 timeZone = TimeZone(identifier: "Asia/Hong_Kong")
```

### 9.4 港股代码格式与搜索

- 港股代码为 4-5 位数字，前缀补零显示（如 `0700.HK` 而非 `700.HK`）
- 搜索时需同时支持：`700`、`0700`、`腾讯`、`tencent` 四种输入方式
- 行情列表混合展示美股（字母）和港股（数字），排序和显示需要区分市场

### 9.5 港股费用结构

v3 的 3.10 节已列出港股费用（印花税 0.13%、交易征费等），iOS 端需要：
- 费用计算公式用 `Decimal` 精确计算，不能用 `Double`
- 印花税取整规则：向上取整至最近整数港元（`ceil`）
- 买入和卖出的费用结构不同（印花税双边征收，SEC Fee 仅美股卖出）

---

## 10. 工期估算建议

### 10.1 MVP 功能工期估算

以下按单名 iOS 工程师工作量估算（人周，不含联调和测试时间）：

| 模块 | 工期估算 | 风险等级 | 说明 |
|------|---------|---------|------|
| **基础框架** | 2周 | 低 | 项目结构、依赖配置、设计系统、导航框架 |
| **登录/注册** | 2周 | 低 | 手机号+OTP、邮箱密码、Face ID、Keychain |
| **KYC 流程** | 6周 | 高 | 含 OCR SDK 集成、活体检测、手写签名、断点续传 |
| **行情模块** | 3周 | 中 | 列表、WebSocket 实时更新、搜索 |
| **K 线图** | 4周 | 高 | 自定义图表渲染、手势、均线、分时图 |
| **交易下单** | 3周 | 中 | 多订单类型、滑动确认、生物识别、风控提示 |
| **持仓/资产** | 2周 | 低 | 实时盈亏、成本计算 |
| **订单管理** | 2周 | 低 | 列表、状态追踪、改单/撤单 |
| **出入金模块** | 4周 | 高 | Plaid 集成、双币种、银行卡管理、合规提示 |
| **港股适配** | 2周 | 中 | Tick Size、Board Lot、多时段处理 |
| **安全加固** | 2周 | 中 | 证书固定、越狱检测、截屏防护 |
| **测试 + 调试** | 3周 | — | 单元测试、UI 测试、性能优化 |
| **合计** | **35周** | — | 约 9 个月（单人）|

### 10.2 建议的并行开发策略

若配置 2 名 iOS 工程师并行开发，可压缩至约 5-6 个月：

| 工程师 A | 工程师 B |
|---------|---------|
| 基础框架 + 登录 | KYC 流程（并行启动） |
| 行情模块 + 搜索 | K 线图组件 |
| 交易下单 + 港股适配 | 出入金模块 + Plaid |
| 持仓/订单 | 安全加固 |
| 联合测试 + 性能优化 | 联合测试 + Bug 修复 |

### 10.3 最高风险模块

以下 3 个模块风险最高，建议最优先启动并预留 buffer：

1. **KYC + 人脸识别**：第三方 SDK 选型决策会影响 2 周以上的工期，且 SDK 接入后的合规测试（用真实证件测试 OCR 准确率）耗时不可预估。**建议在项目开始第一周就评估 SDK 并采购**。

2. **K 线图**：自定义金融图表是业界公认的难点，4 周估算包含了一定 buffer，但若要支持 MACD/RSI 等技术指标（P1 功能），工期会再增加 2 周。

3. **出入金 + Plaid**：Plaid 的 Link Flow 涉及 OAuth 回调、Universal Links 配置，与 App 导航系统的集成需要仔细设计，且 Plaid 本身的 sandbox 测试环境与生产环境有差异，UAT 测试周期较长。

---

## 11. 对产品/UX 的建议

### 11.1 iOS 最低版本须明确

设计文档未指定 iOS 最低版本，但这对技术选型影响巨大：

- **iOS 17+**：可以使用 `@Observable`、`ContentTransition.numericText()`、完整的 TipKit 功能引导
- **iOS 16**：可以使用 Swift Charts（官方图表）、Lock Screen Widgets
- **iOS 15**：Live Activities 不可用，部分 SwiftUI 3 特性不可用

**建议**：考虑到金融 App 用户更新系统较积极，以及功能覆盖全面性，**建议最低支持 iOS 16**，这样既能用 Swift Charts 做折线图，又能支持 Lock Screen Widgets，同时规避 iOS 15 的诸多 SwiftUI 限制。

### 11.2 KYC 流程 MVP 范围须定稿

UX 设计师的审查报告已提出此问题，iOS 工程师角度完全同意：**9 步全量 KYC 绝对不是 MVP 范围**。

**iOS 工程师建议的 MVP KYC 范围**：

| 步骤 | MVP 必须 | 原因 |
|------|---------|------|
| Step 1: 个人信息 | 必须 | 无法省略 |
| Step 2: 证件上传 | 必须（人工审核替代 OCR） | OCR SDK 集成耗时，可先人工审核 |
| Step 3: 人脸识别 | 可简化 | 活体检测先用视频上传，人工审核替代 |
| Step 4: 就业信息 | 必须 | 合规要求 |
| Step 5: 财务状况 | 必须 | 合规要求 |
| Step 6: 投资评估 | 必须 | 合规要求 |
| Step 7: W-8BEN | 必须 | 美股税务必须 |
| Step 8: 风险披露 | 必须 | 监管要求 |
| Step 9: 协议签署 | 必须（可去掉手写签名，改复选框） | 手写签名实现复杂 |

这样 MVP 的 KYC 工期可从 6 周压缩至约 4 周。

### 11.3 Tab 结构最终确认

UX 设计师已指出 v1/v2 Tab 结构不一致的问题。iOS 工程师角度补充：

- **出入金入口位置**：从 iOS 用户体验角度，出入金是高转化率页面，建议在"持仓"页的资产总览区域保留一个"入金"快捷入口（即便出入金主入口在"我的"Tab 下），富途就是这样做的，效果好。
- **Tab 数量**：4 个 Tab 是 iOS App 的常规配置，不建议增加到 5 个（"发现/资讯"Tab），否则会触发 `UITabBar` 的"更多"折叠，用户体验较差。

### 11.4 游客模式需明确技术边界

v3 设计游客可以浏览延迟 15 分钟行情，这意味着：
- **不能要求用户登录后才能展示 App 内容**，需要在无 token 的情况下请求公共行情 API
- 延迟 15 分钟的行情数据不需要 WebSocket，HTTP 轮询即可
- 游客访问行情数据时需要在 UI 上明确标注"延迟 15 分钟"，否则违反 SEC 合规要求（不能将延迟数据展示为实时数据）

**建议产品明确**：游客模式下，股票详情页的 K 线图是否显示？若显示，需要调用不同的 API 端点获取延迟数据。

### 11.5 订单修改功能的 iOS 实现建议

UX 设计师指出"原型有修改按钮但文档未说明流程"。v3 已补充了改单页面（3.6 节），iOS 工程师建议：

- MVP 阶段**仅支持撤单，不支持改单**。改单的底层逻辑是"撤单 + 重新下单"（这是大多数券商的实现），但需要处理"撤单成功但新单提交失败"的异常情况，这涉及复杂的补偿事务，增加了交易模块的风险。
- 若产品坚持 MVP 支持改单，则改单 API 和 UI 必须清晰告知用户"改单等同于重新排队"（v3 已有此说明），且改单操作需要生物识别验证。

### 11.6 下单手续费显示问题

v3 买入页面显示"佣金 $0.00（免佣）"但同时显示"交易所费 ~$0.30"，这对用户会产生困惑——"不是说免费吗，为什么还有费用？"

**建议**：将"交易所费"标注为"监管费用（非本平台收取）"并提供 `ⓘ` tooltip 解释，同时在免佣说明中注明"平台免佣，但交易所和监管机构的强制性费用将照实收取"。

### 11.7 数字精度和格式化一致性

设计原型（HTML）中的费用计算使用的是 JavaScript `number` 类型，存在浮点精度问题（如 `175.23 * 100 = 17522.999...`）。虽然原型层面可以接受，但需要在与产品确认时明确：**iOS 端所有涉及金额的计算使用 `Decimal` 类型，与后端保持一致，产品审核时看到原型的数字结果仅供参考，实际以 `Decimal` 精确计算为准**。

### 11.8 色盲友好实现优先级

v2 已增加 ▲▼ 图标辅助色盲用户，这是正确的方向。iOS 端额外建议：
- 在 `Assets.xcassets` 中为涨色和跌色分别定义 Color Set，支持 High Contrast 模式（系统辅助功能开启时自动切换到高对比度版本）
- 避免单纯依靠颜色传递信息（符合 WCAG 1.4.1），设计文档已在改进这一点，工程侧要确保执行到位

---

## 总结

| 维度 | 评估结论 |
|------|---------|
| 整体可行性 | 可行。设计方案成熟，技术栈选型合理，无根本性障碍 |
| 最高风险模块 | KYC 流程（人脸识别 SDK）、K 线图、Plaid 集成 |
| 优先决策事项 | KYC SDK 选型、iOS 最低版本、MVP KYC 范围、Tab 结构定稿 |
| 技术债风险 | Charts 库选型若用 danielgindi/Charts，后续迁移成本高，建议早决策 |
| 安全合规 | 规范设计合理，需重点确保 Keychain 使用、证书固定、越狱检测三项落地 |
| 工期 | 单人 ~9 个月，双人并行约 5-6 个月（不含后端联调时间） |

**最紧急的行动项**：

1. 确认 iOS 最低支持版本（影响所有技术选型）
2. KYC SDK 招标评估（Jumio vs 阿里云 vs 腾讯云），采购周期可能 2-4 周
3. 确认 MVP 范围（KYC 9 步是否全部必须）
4. 图表库最终决策（自研 vs LightweightCharts vs danielgindi/Charts）
5. 确认港股上线时间（若港股是 P1 后续迭代，可不在 MVP 中处理 Board Lot 逻辑）

---

**文档版本**：v1.0
**评审人**：iOS Engineer Agent
**评审日期**：2026-03-11
