# iOS 技术评审报告 — 证券交易 App PRD

> ⚠️ **此报告已过期**：项目技术路线已更新为 **KMP + Compose Multiplatform**，本报告基于 SwiftUI/原生 iOS 视角编写，相关建议已被 [mobile-kmp-review.md](./mobile-kmp-review.md) 替代。保留此文件仅供参考原始问题识别过程。

**评审角色**: iOS Engineer (Swift/SwiftUI)
**评审日期**: 2026-03-13
**覆盖模块**: 认证(01)、KYC(02)、行情(03)、交易(04)、出入金(05)、设置(08)

---

## 1. HttpOnly Cookie 困境 — Refresh Token 存储

**严重程度**: P0

**问题描述**

PRD 要求 Refresh Token 使用 HttpOnly Cookie 存储。这是 Web 应用的安全最佳实践，但在 Native iOS App 中存在根本性的架构冲突：

- `URLSession` 本身支持 `HTTPCookieStorage`，但 Native App 没有浏览器沙箱，HttpOnly 对 JavaScript 的防护在此场景无意义
- 如果后端 Set-Cookie 响应头返回 HttpOnly Cookie，`URLSession` 会正常存储在 `HTTPCookieStorage.shared` 中，但这是明文存储在沙箱文件系统，**不等同于 Web 的安全语义**
- `WKWebView` 有独立的 Cookie 存储，与 `URLSession` 不共享，无法直接用于 Native API 调用
- Native App 进程可以直接读取 `HTTPCookieStorage`，HttpOnly 标记在此无防护效果

**建议解决方案**

放弃 HttpOnly Cookie 方案，改用 Native-first 实现：Refresh Token 存入 Keychain（`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`，不同步 iCloud，不备份）。Access Token 保存在内存中，不写磁盘。

---

## 2. 生物识别密钥绑定 — Keychain + LAContext

**严重程度**: P0

**问题描述**

PRD 要求"生物识别密钥绑定 `.biometryCurrentSet`"，但这个细节极容易实现错误：

- 许多实现只是"先验证生物识别，再读取 Keychain"——这是**错误模式**，两步之间存在 TOCTOU 风险
- `.biometryCurrentSet` 的正确含义：当设备新增/删除指纹或面容时，此策略会使 Keychain item 失效，**必须通过 `SecAccessControl` 而非 `LAContext` 直接控制**
- PRD 中"挑战-响应签名使用设备私钥"暗示需要 Secure Enclave 密钥对，而非对称密钥

**建议解决方案**

使用 Secure Enclave 生成密钥对（P256），通过 `SecAccessControl` + `.biometryCurrentSet` 绑定生物识别。签名操作本身触发生物识别 UI，而非"先验证再操作"的两步模式。私钥从不离开 Secure Enclave，无法被导出或备份。

---

## 3. Swift Charts K 线图实现

**严重程度**: P1

**问题描述**

Swift Charts（iOS 16+）**原生不支持 Candlestick（蜡烛图/K线图）**。这是 PRD 中最严重的技术可行性误判：

- iOS 16/17/18 Swift Charts 均无内置 Candlestick Mark
- 用 `BarMark` 模拟 K 线理论上可行，但存在严重性能问题：每根 K 线需要至少 2 个 Mark（实体 + 影线），500 根 K 线 = 1000+ SwiftUI 视图节点，在 60fps 手势缩放时会明显掉帧

**建议解决方案**

方案 A（推荐）：用 `Canvas` API 自绘，手动实现缩放、十字线等手势交互，性能最优。
方案 B：Swift Charts 负责成交量柱状图，K 线主图用 Canvas，两者叠加布局。
方案 C：引入 `DGCharts`（MPAndroidChart iOS 移植版），原生支持 Candlestick，通过 UIViewRepresentable 包装。

**需要在进入开发前完成 PoC 验证，特别是渲染性能测试。**

---

## 4. HEIC 格式处理与 OCR 压缩

**严重程度**: P1

**问题描述**

- iOS 11+ 默认相机拍摄格式为 HEIC，单张原图可达 6-10MB，超过 PRD 的 5MB 限制
- 部分后端 OCR 服务对 HEIC 支持不一致，需要明确转换策略
- `PHPickerViewController` 返回的 `NSItemProvider` 异步加载可能超时，需要处理错误分支

**建议解决方案**

上传前强制转换为 JPEG，使用二分法寻找最优压缩质量参数。先降分辨率至 2048px（KYC 文件 OCR 足够），再压缩至 5MB 以内。极端情况下降至 1024px。推荐使用 `PHPickerViewController`（无需相册权限）。

---

## 5. WebSocket 管理与订阅复用

**严重程度**: P1

**问题描述**

PRD 描述"per-user 订阅管理"未明确连接复用策略。常见错误实现：每只股票一个 WebSocket 连接，iOS 系统限制并发 TCP 连接数，且后台时连接全部被挂起。

**建议解决方案**

单连接 + 多路复用订阅消息，使用 Actor 管理连接生命周期。后台策略：不依赖 Background Task 维持 WebSocket，回到前台后先发 HTTP 快照请求获取最新价格，再恢复 WebSocket 订阅。使用指数退避重连（最长 30 秒间隔）。

---

## 6. Slide-to-Confirm 组件

**严重程度**: P1

**问题描述**

PRD 要求"滑动 > 80% 触发"，但未定义：
- 误触后的回弹动画
- 与页面垂直滚动的手势冲突（`DragGesture` 水平/垂直区分）
- VoiceOver 无障碍替代方案
- 提交中状态（防止重复提交）

**建议解决方案**

- 纵向位移 > 20pt 时忽略水平滑动手势，避免与 ScrollView 冲突
- 未达阈值松手时弹簧动画回弹，触觉反馈区分成功/失败
- VoiceOver：`accessibilityAction` 双击直接触发确认
- 提交中状态：禁用手势，显示加载指示器，防重复提交

---

## 7. SMS OTP 自动填充

**严重程度**: P2

**问题描述**

PRD 提到"Android SMS Listener / iOS SMS 自动填充"并列。iOS 没有"主动监听短信"的机制（无法像 Android SmsRetriever 那样主动读取），iOS 只有 `UITextContentType.oneTimeCode` 触发系统 AutoFill 建议，无需任何权限。

**建议**：PRD 删除"iOS SMS Listener"描述，避免开发者实现不存在的功能。正确实现仅需 `.textContentType(.oneTimeCode)` 一行。

---

## 8. 颜色方案全局切换

**严重程度**: P2

**问题描述**

PRD 要求颜色方案"设置更改后立即生效，无需重启"。iOS 16/17 API 存在差异：
- iOS 16：需要 `ObservableObject` + `@StateObject`
- iOS 17+：可用 `@Observable`

颜色主题切换必须从根视图注入 `preferredColorScheme`，局部视图无法单独触发全局刷新。

**建议解决方案**

根视图 `WindowGroup` 使用 `.preferredColorScheme(theme.colorScheme)` 注入，偏好存储用 `UserDefaults`（非敏感数据）。需要同时支持 iOS 16/17 两套写法，或明确最低版本为 iOS 17。

---

## 9. Deep Link / Universal Links

**严重程度**: P2

**问题描述**

PRD 使用 `app://orders/{order_id}` 格式（Custom URL Scheme），存在安全风险：
- **URL Scheme 劫持**：任何 App 都可以注册相同的 Scheme，恶意 App 可拦截跳转
- 不支持 Web 降级（用户未安装 App 时无法处理）

**建议解决方案**

使用 Universal Links（`https://app.company.com/orders/xxx`），配置 AASA 文件。Custom URL Scheme 作为降级备选保留，两者并存。敏感参数从路径提取而非 query 参数。

---

## 10. 访客延迟行情切换策略

**严重程度**: P1

**问题描述**

PRD 描述"服务端延迟 15 分钟推送"，但访客登录后切换到实时流的细节未定义：
- 是否存在价格跳变闪烁问题？
- 延迟数据和实时数据使用同一 WebSocket 端点还是不同端点？

**建议**：访客升级为登录用户时，先断开延迟连接，发起快照 HTTP 请求填充当前价格，再建立实时 WebSocket 连接，避免 UI 短暂显示旧价格。

---

## 汇总

| # | 模块 | 问题 | 严重程度 |
|---|------|------|----------|
| 1 | 认证 | HttpOnly Cookie 在 Native App 无安全语义，Refresh Token 应存 Keychain | **P0** |
| 2 | 认证 | 生物识别密钥绑定必须用 SecAccessControl + Secure Enclave，不能两步分离 | **P0** |
| 3 | 行情 | Swift Charts 不支持 Candlestick，500根K线性能问题，建议 Canvas 自绘 | **P1** |
| 4 | KYC | HEIC 原图超 5MB，需二分压缩 + 降分辨率策略，上传前强制转 JPEG | **P1** |
| 5 | 行情 | WebSocket 需单连接多路复用，后台重连用快照而非长连接维持 | **P1** |
| 6 | 交易 | Slide-to-Confirm 缺失手势冲突处理、防重复提交、VoiceOver 方案 | **P1** |
| 7 | 认证 | "iOS SMS Listener" 概念错误，iOS 只有 oneTimeCode 自动填充 | **P2** |
| 8 | 设置 | colorScheme 切换需从根视图注入，iOS 16/17 API 差异需处理 | **P2** |
| 9 | 导航 | Custom URL Scheme 存在劫持风险，敏感页面应改用 Universal Links | **P2** |
| 10 | 行情 | 访客延迟行情升级到实时流的切换策略未定义，存在价格闪烁风险 | **P1** |

**P0 问题需在 Sprint 1 技术方案阶段明确，否则会影响认证模块的安全合规性。**
