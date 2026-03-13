# Android 技术评审报告

> ⚠️ **此报告已过期**：项目技术路线已更新为 **KMP + Compose Multiplatform**，本报告基于原生 Android（Kotlin/Jetpack Compose）视角编写，相关建议已被 [mobile-kmp-review.md](./mobile-kmp-review.md) 替代。保留此文件仅供参考原始问题识别过程。

**评审角色**: Android Engineer (Kotlin/Jetpack Compose)
**评审日期**: 2026-03-13
**覆盖模块**: 认证(01)、KYC(02)、行情(03)、交易(04)、出入金(05)、设置(08)

---

## 一、HttpOnly Cookie 与 Refresh Token 存储

**严重程度**: P0

**问题描述**

PRD 要求使用 HttpOnly Secure Cookie 存储 Refresh Token。该设计源于 Web 安全最佳实践，但在 Native Android App 中存在根本性的实现矛盾：

- OkHttp 的 `CookieJar` 接口中 HttpOnly 在浏览器中的意义是 JavaScript 不可读取，在 Native App 中该保护完全不存在
- 如果将 Cookie 持久化到磁盘（如 `PersistentCookieStore`），等同于明文（或弱加密）存储在 App 私有目录，Root 设备可读取
- WebView 的 `CookieManager` 与 OkHttp `CookieJar` 是两个独立的 Cookie 存储，如果 API 同时服务于 WebView 和 Native，会产生 Token 不同步问题

**建议解决方案**

Refresh Token 在 Native App 中应存储在 `EncryptedSharedPreferences`（底层已使用 Android Keystore）。Access Token 保存在内存中（ViewModel scope），不写磁盘。需与后端确认是否可将认证形式改为 Bearer Token（Authorization 头），彻底避免 Native App 的 Cookie 管理复杂度。

---

## 二、SMS OTP 自动读取

**严重程度**: P1

**问题描述**

PRD 描述为"Android SMS Listener"，通常指 `READ_SMS` 权限方案，该方案：
- `READ_SMS` 是高敏感权限，**Google Play 自 2019 年起对证券类 App 几乎不可能通过审核**（除非是默认短信 App）
- 可读取用户所有短信内容，隐私风险极高

**正确方案对比**

| 方案 | 无需 READ_SMS | 用户感知 | 适用场景 |
|------|------------|---------|---------|
| SMS Retriever API | 是 | 无感知（自动填充） | 后端可定制短信格式 |
| SMS User Consent API | 是 | 有弹窗（用户确认） | 无法修改短信格式时 |
| `READ_SMS` + BroadcastReceiver | 否（高危权限） | 无感知 | **禁止使用** |

**建议方案**: SMS Retriever API（`com.google.android.gms:play-services-auth`）。注意：后端短信内容末尾必须包含 11 位 App Hash。

---

## 三、BiometricPrompt 降级处理

**严重程度**: P1

**问题描述**

PRD 要求 `BIOMETRIC_STRONG`，但以下情况未覆盖：
1. 设备没有任何生物识别硬件（低端机）
2. 设备仅支持 `BIOMETRIC_WEAK`（Class 2，如部分前置摄像头 2D 人脸）
3. 用户没有录入任何生物特征
4. **关键**: 将密钥绑定到生物识别（`setUserAuthenticationRequired(true)`）后，用户新增/移除指纹会导致密钥永久失效，App 必须处理 `KeyPermanentlyInvalidatedException`

**建议解决方案**

使用 `BiometricManager.canAuthenticate(BIOMETRIC_STRONG)` 检查能力。对于 `KeyPermanentlyInvalidatedException`：清除旧密钥，要求用户重新登录并绑定新密钥。

降级策略建议：
- 交易确认：强生物识别 → 设备 PIN/Pattern（`DEVICE_CREDENTIAL`）→ 不允许（必须先注册生物识别）
- 登录解锁：强生物识别 → 弱生物识别 → 设备 PIN → 密码登录

---

## 四、HEIC 图片格式

**严重程度**: P1

**问题描述**

Android 对 HEIC 的支持情况：

| 能力 | API 版本 | 说明 |
|------|---------|------|
| HEIC 解码（读取） | API 28+ (Android 9) | `ImageDecoder` 支持，但硬件依赖 |
| HEIC 编码（写入） | API 30+ (Android 11) | `HeifEncoder` |
| API 26-27 | 完全不支持 | 无任何原生 HEIC 支持 |

PRD 最低要求 API 26，因此在 Android 8.0-8.1 上完全无法处理 HEIC 文件。Android 设备自身摄像头默认格式是 JPEG，HEIC 问题主要出现在用户从 iPhone 传输照片后上传。

**建议解决方案**

API 28+ 使用 `ImageDecoder` 自动转码；API 26-27 检测到 HEIC 时拒绝并提示"请选择 JPG/PNG 格式图片"。不建议引入第三方 HEIC 解码库（如 ffmpeg-kit），体积过大（30MB+）。

---

## 五、MPAndroidChart K 线图集成

**严重程度**: P1

**问题描述**

1. **Compose 集成**: MPAndroidChart 是纯 View-based 库，在 Compose 中必须通过 `AndroidView` 包装，存在性能和交互传递问题
2. **手势冲突**: Compose 触摸事件与 View 触摸系统共存时双指缩放手势容易冲突
3. **维护状态**: MPAndroidChart 最后一次重大更新是 2021 年，对 Compose 没有官方支持
4. **K 线支持**: MPAndroidChart 支持 `CandleStickChart` API，但 `AndroidView` 包装的手势体验较差

**建议替代方案评估**

| 库 | Compose 原生 | 维护活跃度 | K线支持 |
|----|------------|----------|--------|
| `Vico` (patrykandpatrick/vico) | 是 | 活跃 | 需自定义 |
| 自定义 Canvas | 是 | N/A | 完全可控 |
| MPAndroidChart | 否（需 AndroidView） | 低 | 有 |

金融级 K 线图建议使用**自定义 Canvas 实现**，一次性工作量约 2-3 周，但长期维护成本最低，交互体验最佳。

---

## 六、Slide-to-Confirm 组件

**严重程度**: P2

**问题描述**

自定义 Slide-to-Confirm 组件需精确处理手势拖动、边界检测、动画反弹。关键问题：
1. 用户轻扫未达到 80% 时需要弹回动画
2. 需要防止快速滑动（velocity-based）绕过视觉确认
3. 滑动完成后需立即禁用组件，防止重复提交

**建议实现方案**

使用 `Animatable` 管理位置状态（支持动画化弹回）。在 `onDragStopped` 中同时检查**位置比例**（80%）和**速度**（>1000dp/s 也触发），避免快速甩动触发。`isConfirmed` 状态设为 `true` 后立即锁定所有手势输入。

---

## 七、WebSocket 后台策略

**严重程度**: P1

**问题描述**

Android 8.0（API 26）引入严格的后台执行限制：
- App 进入后台后约 1 分钟内，系统会限制后台服务
- 不能使用 `startService()` 长期维持后台 WebSocket 连接（耗电投诉）
- 对于证券 App，行情数据在后台保活 WebSocket 是不必要的

**推荐后台策略**

前后台切换策略：App 进入前台时建立连接，进入后台时主动断开，保留最后价格缓存（Room）。使用 `ProcessLifecycleOwner` 监听 `ON_START` / `ON_STOP` 事件。

后台价格提醒使用 FCM 推送（服务端推送），而不是客户端保持 WebSocket。**需要在 PRD 中明确：后台不提供实时行情，后台价格提醒通过 FCM 实现。**

---

## 八、Compose 颜色主题热切换

**严重程度**: P2

**问题描述**

Compose 中 `MaterialTheme` 通过 `CompositionLocal` 传递，顶层切换 `colorScheme` 即可触发全局重组。但存在陷阱：
1. 混合 View 场景（如 MPAndroidChart 的 `AndroidView`）需要额外处理 View 的主题切换
2. 颜色切换默认瞬时，需要手动添加 `animateColorAsState` 过渡
3. 状态持久化需要 DataStore（不是 SharedPreferences）

"全局即时生效"技术上完全可行，风险点在于混合 View 场景。使用 `DataStore` 持久化偏好，偏好变化通过 `StateFlow` 传递至 `MaterialTheme`。

---

## 九、设备 ID 生成（不使用 GAID）

**严重程度**: P1

**问题描述**

`Settings.Secure.ANDROID_ID` 局限性：恢复出厂设置后改变、多用户场景不同、API 26+ 起每个应用签名独立。

**推荐方案：组合指纹 + UUID 持久化**

首次运行时生成 UUID 并持久化到 `EncryptedSharedPreferences`。组合 `ANDROID_ID + Build.MANUFACTURER + Build.MODEL + Build.HARDWARE` 的 SHA-256 哈希作为辅助指纹。不使用 `TelephonyManager.getDeviceId()`（API 29 已废弃，需要高危权限）。

---

## 十、其他不可行/高风险 PRD 设计

### 10.1 W-8BEN 内嵌 PDF 查看器

Android 没有系统内置 PDF 渲染 API（iOS 有 PDFKit）。建议使用系统 `PdfRenderer`（API 21+）自建简单查看器，工作量约 3-4 天。不建议使用 `AndroidPdfViewer`（已停止维护）或 WebView 加载 PDF（需要网络）。

### 10.2 访客延迟行情的切换策略

PRD 未定义登录前/后的 WebSocket 端点、鉴权方式和数据切换时机。访客 WebSocket 需要匿名访问鉴权，登录后平滑切换到实时行情需重连 + 数据续传设计。

---

## 总结

| # | 模块 | 问题 | 严重程度 |
|---|------|------|---------|
| 1 | 认证 | HttpOnly Cookie 在 Native App 无意义，应用 EncryptedSharedPreferences | **P0** |
| 2 | 认证 | SMS Listener 方案被 Play Store 禁止，应改用 SMS Retriever API | **P1** |
| 3 | 认证 | BiometricPrompt 降级处理和 KeyPermanentlyInvalidatedException 未覆盖 | **P1** |
| 4 | KYC | API 26-27 不支持 HEIC，需要明确错误处理策略 | **P1** |
| 5 | 行情 | MPAndroidChart 维护停滞，Compose 集成有性能风险，建议评估替代方案 | **P1** |
| 6 | 交易 | Slide-to-Confirm 需同时检查位置和速度，防止快速甩动绕过 | **P2** |
| 7 | 行情 | WebSocket 后台保活在 API 26+ 受限，应改为前后台切换策略 + FCM | **P1** |
| 8 | 设置 | 主题热切换技术可行，但混合 View 场景需额外处理 | **P2** |
| 9 | 认证 | ANDROID_ID 不稳定，推荐组合指纹 + EncryptedSharedPreferences 持久化 UUID | **P1** |
| 10 | KYC/行情 | PDF 查看器无原生方案、访客行情切换逻辑需澄清 | **P2** |

**P0 问题（1 项）**: 需在开发前与产品和后端对齐 Refresh Token 存储方案，阻塞认证模块开发。

**P1 问题（6 项）**: 需在 Sprint 1 技术方案评审中逐一确认，避免后期返工。
