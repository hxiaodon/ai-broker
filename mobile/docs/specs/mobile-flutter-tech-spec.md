# 移动端 Flutter 技术方案文档

**技术路线**: Flutter 3.41.4（稳定版，2026-03-04）
**决策日期**: 2026-03-13
**最后更新**: 2026-04-02（依赖升级轮次，见 flutter-init-report.md §六）
**目标平台**: iOS 16+、Android API 26+
**Dart 版本**: 3.11.1（随 Flutter 3.41.4 附带；环境约束已从 >=3.8.0 升至 >=3.11.0）
**文档状态**: 正式采用

---

## 一、技术路线决策

### 1.1 从 KMP/CMP 切换到 Flutter 的原因

本项目原计划采用 Kotlin Multiplatform + Compose Multiplatform（KMP/CMP）路线。在 2026-03-13 完成的技术评审中，针对项目实际需求列出了 12 个关键技术问题，并对 KMP/CMP 1.10.2 和 Flutter 3.41.4 两套方案分别进行评估，结果如下：

| 方案 | 已解决（✅ 1分） | 部分解决（⚠️ 0.5分） | 总分（满分 12） |
|------|--------------|-------------------|----------------|
| KMP/CMP 1.10.2 | 3 | 9 | **7.5 / 12** |
| Flutter 3.41.4 | 9 | 3 | **10.5 / 12** |

差距来源于以下 5 个 Flutter 显著优势场景：

**场景 1：SMS OTP 自动填充（问题 4）**
KMP/CMP 1.10.2 中，iOS 侧 `textContentType.oneTimeCode` 的稳定支持需等待 CMP 1.11.0 稳定版（预计 Q2 2026），当前版本必须通过 `UIKitView` 包裹原生 `UITextField` 作为 workaround，该 TextField 无法享受 CMP 统一样式系统。Flutter 的 `TextField` 底层在 iOS 上就是 `UITextField`，`autofillHints: [AutofillHints.oneTimeCode]` 原生映射 `UITextContentType.oneTimeCode`，无需任何 workaround，Android 侧通过 `smart_auth v3.2.0` 封装 SMS Retriever API，两平台均已稳定。

**场景 2：APNs/FCM 推送桥接（问题 6）**
KMP/CMP 方案中，iOS APNs DeviceToken 必须在 Swift `AppDelegate` 中通过 `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` 回调手动桥接给 Kotlin 层，需要维护一个薄的 Swift 桥接文件，且 Firebase KMP SDK（GitLive v2.4.0）的 API 覆盖率仅标注为 10%。Flutter 的 `firebase_messaging v16.1.2` 由 FlutterFire 官方维护，iOS APNs Token 关联由 Firebase iOS SDK 内部自动处理，不需要手动实现任何 AppDelegate 回调，周下载量超过 70 万次。

**场景 3：KYC 图片选择与裁剪（问题 9）**
KMP/CMP 方案中，FileKit v0.13.0 提供了跨平台图片选择能力，但图片裁剪（证件四角不遮挡）在 KMP 中无成熟跨平台库，需要自绘 CMP 遮罩或通过 `expect/actual` 调用平台原生裁剪，预估 3-5 天额外工作量。Flutter 方案中 `image_picker v1.2.1`（官方维护）加 `image_cropper v7.x`（调用 iOS `TOCropViewController` 和 Android Ucrop 库）完整覆盖 KYC 证件拍摄与裁剪场景，零样板代码。

**场景 4：PDF 查看（问题 10）**
KMP/CMP 中没有跨平台 PDF 渲染 Composable，需要通过 `expect/actual` 分别在 iOS 侧用 `UIViewControllerRepresentable` 包裹 `PDFViewController`、Android 侧用 `AndroidView` 包裹 `PdfRenderer`，预估 3-4 天工作量。Flutter 的 `pdfx v2.9.2` 统一支持 iOS（PDFKit）、Android（PdfRenderer）、Web（PDF.js），单一 API 开箱即用。

**场景 5：高频行情更新的 GC 性能（问题 11）**
KMP/CMP 在 Kotlin/Native（iOS 侧）使用引用计数加追踪 GC 混合模型，100+ Symbol 并发高频 StateFlow 更新时，大量短生命周期 `Quote` 对象的分配压力可能导致 GC 暂停超过 16ms 引发掉帧，属于 P1 级生产风险。Flutter/Dart 采用分代 GC（Scavenger + Mark-Compact），短生命周期对象由 Scavenger 快速回收，加之 Impeller 渲染引擎运行于独立线程，高频数据更新对渲染帧率的干扰经生产验证稳定。

此外，KMP/CMP 方案还存在 **iOS 原生一致性差距（问题 12）**：CMP 1.10.2 截图防护仍无原生 API（需 `UIScreen.capturedDidChangeNotification` workaround）、LazyColumn 大列表性能需等待 CMP 1.11.0、Native Text Input 仅在 alpha 阶段。Flutter 的 `TextField` 底层是 iOS 原生 `UITextField`，`screen_protector v1.5.1` 封装了完整的截图防护，无上述问题。

综合评估，切换至 Flutter 可消除约 **25-35 人天**的额外 workaround 工作量，并消除 K/Native GC 高频行情更新这一 P1 生产风险。

### 1.2 Flutter 核心优势（针对本项目）

**渲染引擎 Impeller 的金融 UI 适配性**

Flutter 3.27 起 iOS 默认采用 Impeller 渲染引擎，基于 Metal API，渲染流水线与 Dart VM 解耦，K 线图的 `CustomPainter` 高频重绘不阻塞 UI 线程，500 根 K 线加实时 WebSocket 更新场景下性能优于 CMP Skia/Skiko 路径。

**原生控件复用无阻抗**

Flutter 的文本输入控件底层在 iOS 上是 `UITextField`，所有 IME 行为、`textContentType`、autofill 与系统完全一致，不存在 CMP 的 TextField 兼容列表问题，降低安全合规 UI 组件（OTP 输入、密码输入）的开发和验证成本。

**FlutterFire 生态的完整性**

`firebase_messaging`、`firebase_analytics`、`firebase_crashlytics` 均由 Google 官方维护，iOS/Android 双端一致，不需要维护任何 Swift/Kotlin 桥接代码，对于需要 APNs 加 FCM 双平台推送的证券 App（成交通知、出入金通知、安全登录提醒）有决定性价值。

**Dart 的单一代码库效率**

UI 层、业务逻辑层、数据层均使用 Dart，不需要 `expect/actual` 机制，工程师无需在 Kotlin/Swift/Dart 三种语言之间切换，代码审查边界清晰，新成员上手成本低。

**金融 App 生产案例积累**

截至 2025 年，Nubank（4000 万用户）、多家中东及东南亚 Neobank 均在生产环境使用 Flutter，证券 App 特有的行情列表、订单簿可视化场景有成熟参考实现。

---

## 二、技术栈选型

### 2.1 核心框架

| 组件 | 版本 | 说明 |
|------|------|------|
| Flutter SDK | 3.41.4（稳定版，2026-03-04） | 主框架 |
| Dart SDK | 3.7.x（随 Flutter 附带） | 开发语言 |
| 渲染引擎 | Impeller（iOS 默认）/ Skia（Android 默认） | iOS 使用 Metal API，Android 使用 OpenGL ES/Vulkan |
| 最低支持系统 | iOS 16+ / Android API 26+（Android 8.0） | 与 PRD-00 约束一致 |

### 2.2 完整依赖库清单

#### 状态管理

| 库名 | 版本 | 用途 |
|------|------|------|
| flutter_riverpod | ^3.3.1 | 全局状态管理主框架（Riverpod 3.3，含自动重试/暂停恢复） |
| riverpod_annotation | ^4.0.2 | 代码生成注解，配合 riverpod_generator（4.x 大版本升级，2026-04） |
| riverpod_generator | ^4.0.3 | Riverpod Provider 代码生成（dev dependency；需 analyzer ^9.0.0） |
| hooks_riverpod | ^3.3.1 | Flutter Hooks + Riverpod 集成（行情页高频更新场景） |
| flutter_hooks | ^0.21.0 | React-style Hooks，配合 hooks_riverpod |

#### 网络层

| 库名 | 版本 | 用途 |
|------|------|------|
| dio | ^5.7.0 | HTTP 客户端，含拦截器、证书固定、错误处理 |
| web_socket_channel | ^3.0.3 | WebSocket 客户端（行情实时推送、订单状态） |
| crypto | ^3.0.0 | SPKI 公钥 SHA-256 指纹计算，配合 dio 实现证书固定 |
| protobuf | ^3.1.0 | Protocol Buffers 序列化（与后端行情数据传输）；protobuf 6.0 暂不升级（需后端协调） |

#### 安全存储

| 库名 | 版本 | 用途 |
|------|------|------|
| flutter_secure_storage | ^10.0.0 | Keychain（iOS）/ EncryptedSharedPreferences（Android）存储 JWT、Refresh Token |

#### 生物识别

| 库名 | 版本 | 用途 |
|------|------|------|
| local_auth | ^3.0.1 | Face ID / Touch ID（iOS）、BiometricPrompt（Android）身份验证 |

#### 推送通知

| 库名 | 版本 | 用途 |
|------|------|------|
| firebase_messaging | ^16.1.2 | APNs（iOS）+ FCM（Android）统一推送接收 |
| firebase_core | ^3.12.1 | Firebase SDK 初始化基础库 |
| flutter_local_notifications | ^18.0.1 | 前台推送本地展示、自定义通知样式 |

#### 行情图表

| 库名 | 版本 | 用途 |
|------|------|------|
| syncfusion_flutter_charts | ^33.1.46 | K 线图（Candlestick/OHLC）、折线图、面积图，含 pinch-zoom、缩略条；Community License 免费；唯一图表库，无备选 |

#### 图片选择与裁剪

| 库名 | 版本 | 用途 |
|------|------|------|
| image_picker | ^1.2.1 | 相册选取（PHPickerViewController / MediaStore）加相机拍照，KYC 证件上传 |
| image_cropper | ^12.1.1 | 证件图片裁剪（iOS TOCropViewController / Android Ucrop），KYC 四角不遮挡 |

#### PDF 查看

| 库名 | 版本 | 用途 |
|------|------|------|
| pdfx | ^2.9.2 | iOS（PDFKit）/ Android（PdfRenderer）统一 PDF 渲染，W-8BEN 查看 |

#### WebView

| 库名 | 版本 | 用途 |
|------|------|------|
| webview_flutter | ^4.10.0 | 帮助中心、协议页面、营销落地页的 WebView 容器 |

#### 本地数据库与缓存

| 库名 | 版本 | 用途 |
|------|------|------|
| drift | ^2.31.0 | 类型安全 SQLite ORM，持仓历史、订单缓存、行情快照 |
| drift_dev | ^2.28.0 | drift 代码生成（dev dependency；受 riverpod_generator analyzer 9.x 约束，详见§2.4） |
| shared_preferences | ^2.5.5 | 轻量非敏感偏好存储（主题颜色方案、语言设置等） |
| hive_ce | ^2.9.0 | 高速 key-value 存储，行情 tick 缓存（纯 Dart，无原生依赖） |

#### 工具库

| 库名 | 版本 | 用途 |
|------|------|------|
| go_router | ^14.8.1 | 声明式路由，Deep Link 处理，WebView 路由（v14.x onExit 回调签名变更，见§3.4） |
| device_info_plus | ^12.4.0 | iOS identifierForVendor、Android ANDROID_ID 等设备信息 |
| uuid | ^4.5.3 | 生成持久化设备 ID（UUID v4）、Idempotency-Key |
| package_info_plus | ^9.0.1 | App 版本号、Build 号（设备指纹、日志标注） |
| intl | ^0.20.2 | 国际化、日期格式化、货币数字格式化 |
| decimal | ^3.2.1 | Dart 高精度十进制数，金融计算专用，替代 double |
| logger | ^2.7.0 | 结构化日志，生产环境 PII 掩码 |
| connectivity_plus | ^7.1.0 | 网络状态检测，离线模式切换 |
| screen_protector | ^1.5.1 | 敏感页面截图防护（FLAG_SECURE + iOS UITextField 方案） |
| ~~flutter_jailbreak_detection~~ | ~~^1.9.0~~ | **已移除**，包无维护且 AGP 8.0+ 不兼容，见§6.3 |
| permission_handler | ^12.0.1 | 相机、相册、通知权限统一管理 |
| cached_network_image | ^3.4.1 | 股票 Logo、KYC 证件缩略图缓存 |
| timeago | ^3.7.0 | 行情数据时间戳"x 秒前"相对时间显示 |
| rxdart | ^0.28.0 | 复杂流操作（行情去重、节流、合并），配合 Riverpod StreamProvider |

#### SMS OTP

| 库名 | 版本 | 用途 |
|------|------|------|
| smart_auth | ^3.2.0 | Android SMS Retriever API（SMS User Consent）自动读取 OTP |

#### 滑动确认

| 库名 | 版本 | 用途 |
|------|------|------|
| slide_to_confirm | ^1.1.0 | 交易确认滑动手势组件 |

#### 开发与测试工具

| 库名 | 版本 | 用途 |
|------|------|------|
| build_runner | ^2.13.1 | 代码生成统一入口（Riverpod、drift） |
| flutter_test | SDK 内置 | Widget 单元测试 |
| mocktail | ^1.0.4 | Mock 对象，替代 mockito（无需代码生成） |
| integration_test | SDK 内置 | 集成测试 / UI 端到端测试 |
| flutter_lints | ^6.0.0 | 官方 Lint 规则集（v6 适配 Dart 3.11+） |
| very_good_analysis | ^7.0.0 | 严格 Lint 规则（Phase 2 升级至 10.x，待 riverpod_generator 支持 analyzer 10+） |
| leak_tracker | SDK 内置（Flutter 3.18+） | 内存泄漏检测，行情页高频更新场景 CI 检查 |
| custom_lint | ^0.7.0 | 自定义 Lint 规则（Phase 2 引入，与 riverpod_lint 配套） |
| riverpod_lint | ^2.6.0 | Riverpod 专项 Lint（Phase 2 引入） |

### 2.3 选型说明

**状态管理：Riverpod 而非 BLoC 或 Provider**

选择 Riverpod 而非 BLoC 的主要原因：金融 App 中有大量跨 Widget 共享的全局状态（行情价格、账户余额、订单状态），Riverpod 的 Provider 天然支持跨 Widget 树访问且不依赖 `BuildContext`；`AsyncNotifierProvider` 对 `AsyncValue<T>` 的三态（loading/data/error）处理比 BLoC 的 `emit(LoadingState())` 更简洁，减少金融数据加载场景的样板代码。本项目当前使用 **Riverpod 3.3.1 + riverpod_annotation 4.0.2**（2026-04 升级）：

- **自动重试（Auto Retry）**：`@Riverpod(retry: Retry(...))` 对 WebSocket 断线、API 5xx 等临时错误自动重连，无需手写重试循环
- **Pause/Resume（暂停/恢复）**：StreamProvider 在 App 进入后台时自动暂停订阅（无监听者），回到前台时自动恢复，完全取代手写 `WidgetsBindingObserver` 生命周期管理（见§3.3、§4.8）
- **统一 `Ref` API**：原 `WatchlistQuotesRef`、`AppRouterRef` 等 provider 专属 Ref 类型统一替换为 `Ref`，减少代码生成复杂度

Provider 包已进入维护模式，不推荐新项目使用。

### 2.4 已知依赖约束说明

**analyzer 版本天花板（截至 2026-04）**

`riverpod_generator 4.x` 需要 `analyzer ^9.0.0`，导致以下两个工具包无法升级至最新：

| 包 | 上限原因 | 最新可用版本 | 最新稳定版 |
|---|---------|-----------|---------|
| `json_serializable` | `^6.13.0+` 需要 analyzer >=10.0.0 | **^6.12.0** | 6.13.1 |
| `drift_dev` | `^2.32.0+` 需要 analyzer >=10.0.0 | **^2.28.0** (resolves to 2.31.0) | 2.32.1 |

**解决时机**：当 `riverpod_generator` 发布支持 `analyzer ^10.0.0+` 的版本时，三个包可以一并升级至最新。追踪 issue：[rrousselGit/riverpod#3xxx](https://github.com/rrousselGit/riverpod)

**protobuf 大版本升级**

`protobuf ^3.1.0` 目前最新稳定版为 6.0.0，但属于 API 重构性大版本升级，需要与后端 Go 服务（market-data, trading-engine）协调同步升级 protoc 生成代码后再升级。



`retrofit ^4.4.1` 和 `retrofit_generator ^9.1.3` 已从本项目移除。原因：Dart 3.11 引入穷举 switch 要求，retrofit_generator 生成的代码在 Dart 3.11 下编译失败，且上游修复进度不可预测。当前方案：在 Data Layer 手写 `RemoteDataSource` 类，直接使用 `dio` 发起请求并处理响应映射：

```dart
// features/auth/data/remote/auth_remote_datasource.dart
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  Future<AuthTokenDto> login(String phone, String otp) async {
    final response = await _dio.post('/v1/auth/login', data: {
      'phone': phone,
      'otp': otp,
    });
    return AuthTokenDto.fromJson(response.data as Map<String, dynamic>);
  }
}
```

备选路线（Phase 2 评估）：若手写 Data Source 维护成本上升，可引入 `chopper`（由 Google 维护，与 Dart 3.x 持续兼容）或 OpenAPI Generator + 自定义模板生成 Data Source 骨架。

**图表：Syncfusion 唯一选型，financial_chart 已移除备选**

Sprint 0 评估完成后，`syncfusion_flutter_charts v32.2.9` 确认为唯一图表库，`financial_chart` 备选方案不再维护在依赖清单中（见§2.2）。

**数据库：drift 而非 sqflite**

`drift v2.23.1` 基于 SQLite，提供类型安全的 Dart DSL 和代码生成，支持 Stream 查询（响应式数据库），适合持仓、订单历史等需要实时 UI 刷新的场景。`sqflite` 仅提供原始 SQL 接口，缺乏类型安全，不推荐在复杂金融数据模型上直接使用。

**路由：go_router 而非 Navigator 2.0 手动实现**

`go_router v14.6.2` 是 Flutter 官方推荐路由方案，支持声明式路由配置、Deep Link（Universal Link / App Link）、嵌套导航（行情 Tab 内的股票详情嵌套路由），对 WebView 页面的路由封装简洁。

**金融计算：decimal 包**

Dart 原生 `double` 有精度问题，不可用于金融计算。`decimal v3.2.1` 提供与 Java `BigDecimal` 语义一致的高精度十进制运算，所有价格、金额、手续费字段均使用 `Decimal` 类型，与 CLAUDE.md 中"禁止浮点数用于金融计算"规则完全对齐。

---

## 三、架构设计

### 3.1 分层架构

采用 Clean Architecture，共四层，依赖方向从外向内单向流动：

```
Presentation Layer（Flutter Widgets + Riverpod Notifiers）
    |
    v  调用
Domain Layer（Use Cases + Entities + Repository Interfaces）
    |
    v  调用
Data Layer（Repository Implementations + Remote/Local Data Sources）
    |
    v  使用
Infrastructure Layer（dio, drift, flutter_secure_storage, firebase_messaging）
```

**Presentation Layer**

- Flutter Widget（StatelessWidget / HookConsumerWidget）
- Riverpod `AsyncNotifier`、`Notifier`、`StreamNotifier`（ViewModel 等价）
- 职责：UI 渲染、用户交互、状态订阅，不包含任何业务规则
- 使用 `ref.watch()` 订阅行情流，`ref.read().add()` 触发下单

**Domain Layer**

- Use Cases（`PlaceOrderUseCase`、`SubmitKycUseCase`、`GetQuoteStreamUseCase` 等）
- Entities（纯 Dart 类，不依赖任何框架）：`Order`、`Quote`、`KycApplication`、`BankAccount`
- Repository Interfaces（抽象类，Data 层实现）：`OrderRepository`、`QuoteRepository`、`AuthRepository`
- 职责：业务规则、前置校验（PDT 规则检查、余额检查）、Use Case 编排
- 不依赖 Flutter、dio、drift 等任何外部框架，便于单元测试

**Data Layer**

- Repository Implementations（实现 Domain 层接口）
- Remote Data Sources（`dio` HTTP 客户端、`web_socket_channel` WebSocket 客户端）
- Local Data Sources（`drift` SQLite、`flutter_secure_storage` Keychain、`shared_preferences`）
- DTO（Data Transfer Objects）与 Domain Entity 之间的 Mapper
- 职责：数据获取、缓存策略、错误转换为 Domain 层定义的异常类型

**Infrastructure / Core Layer**

- 网络基础设施：dio 拦截器（JWT 注入、Token 刷新、请求签名、错误处理）
- 安全基础设施：BiometricKeyManager（Method Channel 封装）、SecureStorageService
- 推送基础设施：FCM/APNs 初始化、Token 上报、前台通知展示
- 日志基础设施：结构化日志加 PII 掩码
- 路由基础设施：go_router 配置、Deep Link 处理

### 3.2 目录结构

```
lib/
├── main.dart                          # App 入口，Firebase 初始化，ProviderScope
├── app.dart                           # MaterialApp.router，go_router 配置注入
│
├── core/                              # 跨功能基础设施，不包含业务逻辑
│   ├── auth/
│   │   ├── biometric_key_manager.dart # Method Channel 封装，生物识别密钥对签名
│   │   └── token_service.dart         # JWT 读写，Token 刷新逻辑
│   ├── network/
│   │   ├── dio_client.dart            # dio 实例工厂，证书固定配置
│   │   ├── auth_interceptor.dart      # Authorization Header 注入，401 自动刷新
│   │   ├── request_signing_interceptor.dart  # HMAC-SHA256 交易请求签名
│   │   ├── error_interceptor.dart     # 统一错误转换为 AppException
│   │   └── connectivity_service.dart  # 网络状态监听，离线模式
│   ├── storage/
│   │   ├── secure_storage_service.dart # flutter_secure_storage 封装
│   │   ├── database.dart              # drift 数据库定义
│   │   └── database.g.dart            # drift 生成代码（不手动编辑）
│   ├── security/
│   │   ├── jailbreak_detection_service.dart
│   │   ├── screen_protection_service.dart
│   │   └── ssl_pinning_config.dart    # 证书指纹配置
│   ├── push/
│   │   ├── push_notification_service.dart  # firebase_messaging 初始化，Token 上报
│   │   └── notification_handler.dart       # 前台/后台通知路由
│   ├── logging/
│   │   ├── app_logger.dart            # 结构化日志，PII 掩码
│   │   └── log_interceptor.dart       # dio 请求日志（脱敏）
│   ├── routing/
│   │   ├── app_router.dart            # go_router 配置，所有路由定义
│   │   ├── route_names.dart           # 路由名称常量
│   │   └── route_guards.dart          # 认证守卫，KYC 状态守卫
│   └── errors/
│       ├── app_exception.dart         # 业务异常类型定义
│       └── failure.dart               # Failure 层级定义
│
├── features/                          # 功能模块，每个模块含 data/domain/presentation
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository_impl.dart
│   │   │   ├── remote/
│   │   │   │   └── auth_api.dart       # 手写 RemoteDataSource API 接口
│   │   │   └── local/
│   │   │       └── auth_local_datasource.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── auth_token.dart
│   │   │   │   └── device_info.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart  # 抽象接口
│   │   │   └── usecases/
│   │   │       ├── login_with_otp_usecase.dart
│   │   │       ├── refresh_token_usecase.dart
│   │   │       └── biometric_auth_usecase.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── otp_screen.dart
│   │       │   └── biometric_setup_screen.dart
│   │       ├── widgets/
│   │       │   ├── otp_input_field.dart   # AutofillHints.oneTimeCode
│   │       │   └── biometric_prompt.dart
│   │       └── providers/
│   │           ├── auth_provider.dart     # @riverpod
│   │           └── auth_provider.g.dart
│   │
│   ├── kyc/
│   │   ├── data/
│   │   │   ├── kyc_repository_impl.dart
│   │   │   └── remote/
│   │   │       └── kyc_api.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── kyc_application.dart
│   │   │   │   └── document_upload.dart
│   │   │   ├── repositories/
│   │   │   │   └── kyc_repository.dart
│   │   │   └── usecases/
│   │   │       ├── submit_kyc_usecase.dart
│   │   │       └── upload_document_usecase.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── kyc_step1_personal_info_screen.dart
│   │       │   ├── kyc_step2_document_screen.dart  # image_picker + image_cropper
│   │       │   ├── kyc_step3_address_screen.dart
│   │       │   ├── kyc_step4_employment_screen.dart
│   │       │   ├── kyc_step5_investment_screen.dart
│   │       │   ├── kyc_step6_disclosure_screen.dart  # 风险披露，原生 ScrollView
│   │       │   └── kyc_step7_agreement_screen.dart   # 协议签署
│   │       ├── widgets/
│   │       │   ├── document_capture_widget.dart
│   │       │   ├── scroll_to_bottom_checker.dart
│   │       │   └── kyc_progress_indicator.dart
│   │       └── providers/
│   │           └── kyc_provider.dart
│   │
│   ├── market/
│   │   ├── data/
│   │   │   ├── quote_repository_impl.dart
│   │   │   ├── remote/
│   │   │   │   ├── market_api.dart
│   │   │   │   └── quote_websocket_client.dart  # web_socket_channel
│   │   │   └── local/
│   │   │       └── quote_cache_datasource.dart  # hive_ce
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── quote.dart               # 价格使用 Decimal
│   │   │   │   ├── candle.dart              # K 线 OHLCV 数据
│   │   │   │   └── stock_detail.dart
│   │   │   ├── repositories/
│   │   │   │   └── quote_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_quote_stream_usecase.dart
│   │   │       ├── get_candles_usecase.dart
│   │   │       └── search_stocks_usecase.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── market_list_screen.dart
│   │       │   ├── stock_detail_screen.dart
│   │       │   ├── watchlist_screen.dart
│   │       │   └── search_screen.dart
│   │       ├── widgets/
│   │       │   ├── candlestick_chart_widget.dart  # syncfusion_flutter_charts
│   │       │   ├── price_ticker_widget.dart
│   │       │   ├── order_book_widget.dart
│   │       │   └── data_freshness_indicator.dart  # 行情时间戳/延迟提示
│   │       └── providers/
│   │           ├── quote_provider.dart
│   │           └── candle_provider.dart
│   │
│   ├── trading/
│   │   ├── data/
│   │   │   ├── order_repository_impl.dart
│   │   │   └── remote/
│   │   │       └── trading_api.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── order.dart               # 金额字段全部使用 Decimal
│   │   │   │   └── buying_power.dart
│   │   │   ├── repositories/
│   │   │   │   └── order_repository.dart
│   │   │   └── usecases/
│   │   │       ├── place_order_usecase.dart  # 含前置风控检查（PDT、余额）
│   │   │       ├── cancel_order_usecase.dart
│   │   │       └── get_orders_usecase.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── order_entry_screen.dart
│   │       │   ├── order_confirmation_screen.dart  # slide_to_confirm + 生物识别
│   │       │   └── order_list_screen.dart
│   │       ├── widgets/
│   │       │   ├── order_type_selector.dart
│   │       │   └── buying_power_indicator.dart
│   │       └── providers/
│   │           └── trading_provider.dart
│   │
│   ├── funding/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── deposit_screen.dart
│   │       │   ├── withdrawal_screen.dart
│   │       │   └── bank_account_management_screen.dart
│   │       └── providers/
│   │
│   ├── portfolio/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── portfolio_overview_screen.dart
│   │       │   └── position_detail_screen.dart
│   │       └── providers/
│   │
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── screens/
│           │   ├── settings_screen.dart
│           │   ├── security_settings_screen.dart
│           │   ├── notification_settings_screen.dart
│           │   ├── color_scheme_settings_screen.dart
│           │   ├── profile_screen.dart
│           │   ├── w8ben_viewer_screen.dart    # pdfx
│           │   └── help_center_screen.dart     # webview_flutter
│           └── providers/
│
└── shared/                            # 跨功能共享组件，不含业务逻辑
    ├── widgets/
    │   ├── buttons/
    │   │   ├── primary_button.dart
    │   │   └── destructive_button.dart
    │   ├── inputs/
    │   │   ├── decimal_input_field.dart   # 专为金融数值输入设计，防止浮点输入
    │   │   ├── secure_input_field.dart
    │   │   └── currency_input_field.dart
    │   ├── loading/
    │   │   ├── skeleton_loader.dart
    │   │   └── shimmer_effect.dart
    │   ├── error/
    │   │   ├── error_view.dart
    │   │   └── empty_state_view.dart
    │   └── price/
    │       ├── price_change_badge.dart    # 涨跌幅标签，颜色由主题决定
    │       └── decimal_price_text.dart   # Decimal 格式化字符串显示
    ├── theme/
    │   ├── app_theme.dart
    │   ├── color_tokens.dart
    │   └── trading_color_scheme.dart     # 红涨绿跌 / 绿涨红跌两套配色
    ├── extensions/
    │   ├── decimal_extensions.dart       # Decimal 格式化扩展
    │   ├── datetime_extensions.dart      # UTC 转用户时区
    │   └── string_extensions.dart        # PII 掩码工具
    └── constants/
        ├── api_constants.dart
        └── app_constants.dart

android/
└── app/
    └── src/main/
        ├── kotlin/com/yourapp/
        │   ├── MainActivity.kt
        │   └── BiometricKeyManagerPlugin.kt  # Method Channel：Android Keystore 签名
        └── AndroidManifest.xml

ios/
└── Runner/
    ├── AppDelegate.swift                  # 仅保留 Firebase 初始化
    ├── BiometricKeyManagerPlugin.swift    # Method Channel：Secure Enclave 密钥签名
    └── Info.plist
```

### 3.3 状态管理方案

**全局单例 Provider（keepAlive: true）**

在 `ProviderScope` 根部注册，跟随 App 生命周期：

```dart
// core/auth/providers/auth_state_provider.dart
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.unauthenticated();

  Future<void> loginWithOtp(String phone, String otp) async { ... }
  Future<void> logout() async { ... }
}

// core/theme/providers/theme_provider.dart
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  TradingColorScheme build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return TradingColorScheme.fromString(
      prefs.getString('color_scheme') ?? 'red_up',
    );
  }

  void setColorScheme(TradingColorScheme scheme) {
    state = scheme;
    ref.read(sharedPreferencesProvider).setString('color_scheme', scheme.name);
  }
}
```

**Watchlist 高频行情：单一 Map Provider 避免 Provider 爆炸**

```dart
// features/market/providers/watchlist_quote_provider.dart
@Riverpod(keepAlive: true)
Stream<Map<String, Quote>> watchlistQuotes(WatchlistQuotesRef ref) {
  final symbols = ref.watch(watchlistSymbolsProvider);
  final wsClient = ref.watch(quoteWebSocketClientProvider);

  return wsClient
    .subscribeToSymbols(symbols)
    .throttleTime(const Duration(milliseconds: 100))  // rxdart，最高 10fps
    .scan<Map<String, Quote>>(
      (acc, tick, _) => {...acc, tick.symbol: tick},
      {},
    );
}
```

在 Watchlist Widget 每行通过 `select` 只监听单只股票变化，避免全量重建：

```dart
final quote = ref.watch(
  watchlistQuotesProvider.select((map) => map.value?[symbol]),
);
```

### Riverpod 3.0 行情流 Provider（替代手动 WidgetsBindingObserver）

Riverpod 3.0 的 StreamProvider 在无监听者时自动暂停（Pause），重新有监听者时自动恢复（Resume），完全取代 §4.8 中基于 `WidgetsBindingObserver` 的手动生命周期管理。以下是完整的行情流实现模式：

**单只股票 StreamProvider（自动 Pause/Resume）**

```dart
// features/market/providers/quote_provider.dart
@riverpod
Stream<Quote> quoteStream(Ref ref, String symbol) {
  final wsClient = ref.watch(quoteWebSocketClientProvider);
  // 当 App 进入后台（无 Widget 监听此 Provider）时，Riverpod 3.0 自动暂停流。
  // 当 App 回到前台（Widget 重新监听）时，自动恢复。
  // 无需 WidgetsBindingObserver。
  return wsClient.subscribeToSymbol(symbol);
}
```

**Watchlist Map Provider（自动重试 + Pause/Resume）**

```dart
// features/market/providers/watchlist_quote_provider.dart
@Riverpod(
  keepAlive: true,
  retry: Retry(
    maxAttempts: 10,
    strategy: ExponentialBackoffStrategy(
      initialDelay: Duration(milliseconds: 100),
      maxDelay: Duration(seconds: 30),
    ),
  ),
)
Stream<Map<String, Quote>> watchlistQuotes(Ref ref) {
  final symbols = ref.watch(watchlistSymbolsProvider);
  final wsClient = ref.watch(quoteWebSocketClientProvider);

  return wsClient
    .subscribeToSymbols(symbols)
    .throttleTime(const Duration(milliseconds: 100)) // rxdart，最高 10fps
    .scan<Map<String, Quote>>(
      (acc, tick, _) => {...acc, tick.symbol: tick},
      {},
    );
}
```

注意：`Ref` 替代了 Riverpod 2.x 的 `WatchlistQuotesRef` 等 Provider 专属 Ref 类型，所有 Provider 函数参数统一使用 `Ref`。

### 3.4 路由方案

**go_router 核心配置**

```dart
// core/routing/app_router.dart
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/market',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      if (!isAuthenticated && !isAuthRoute) return '/auth/login';
      if (isAuthenticated && isAuthRoute) return '/market';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpScreen(phone: state.extra as String),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainTabScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/market', builder: (_, __) => const MarketListScreen()),
            GoRoute(
              path: '/market/stock/:symbol',
              builder: (_, state) => StockDetailScreen(
                symbol: state.pathParameters['symbol']!,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/trading', builder: (_, __) => const OrderEntryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/kyc', builder: (_, __) => const KycStep1Screen()),
      GoRoute(path: '/settings/w8ben', builder: (_, __) => const W8benViewerScreen()),
      GoRoute(
        path: '/settings/help',
        builder: (_, state) => HelpCenterScreen(
          initialUrl: state.extra as String?,
        ),
      ),
      // Deep Link: app://trading/buy?symbol=AAPL
      GoRoute(
        path: '/trading/buy',
        builder: (_, state) => OrderEntryScreen(
          symbol: state.uri.queryParameters['symbol'],
        ),
      ),
    ],
  );
}
```

Deep Link 配置：iOS `Info.plist` 配置 Universal Link 和 Custom Scheme（`app://`），Android `AndroidManifest.xml` 配置 App Link 和 Intent Filter，go_router 通过 `pathParameters` 和 `queryParameters` 自动解析。

> **go_router 14.x Breaking Change：`onExit` 回调签名变更**
>
> go_router 14.x 修改了 `GoRoute.onExit` 的回调签名，第二个参数从无变为 `GoRouterState`，回调类型从 `FutureOr<bool> Function(BuildContext)` 改为 `FutureOr<bool> Function(BuildContext, GoRouterState)`。
>
> ```dart
> // 错误（v13 签名，v14 下编译失败）
> GoRoute(
>   path: '/trading/confirm',
>   onExit: (context) async {
>     return await showCancelDialog(context);
>   },
>   builder: (_, __) => const OrderConfirmationScreen(),
> ),
>
> // 正确（v14 签名）
> GoRoute(
>   path: '/trading/confirm',
>   onExit: (context, state) async {
>     return await showCancelDialog(context);
>   },
>   builder: (_, __) => const OrderConfirmationScreen(),
> ),
> ```
>
> 交易确认页建议优先使用 `PopScope` + `onPopInvokedWithResult` 替代 `onExit`，规避 go_router 版本敏感性（见§4.7 的 `PopScope` 实现）。

---

## 四、原 KMP 评审问题的 Flutter 解决方案

### 4.1 生物识别（Secure Enclave 硬件密钥签名）

**Flutter 方案**

`local_auth v3.0.1` 提供身份验证，但不暴露 `CryptoObject` 接口，无法直接绑定签名操作。与 KMP 方案相同，需要通过 Method Channel 调用原生代码实现完整的硬件密钥签名流程。

Dart 抽象接口（`core/auth/biometric_key_manager.dart`）：

```dart
abstract class BiometricKeyManager {
  Future<String> generateKeyPair(String keyAlias);
  Future<String> signChallenge(String keyAlias, Uint8List challenge);
  Future<bool> isKeyInvalidated(String keyAlias);
  Future<void> deleteKey(String keyAlias);
}

class BiometricKeyManagerImpl implements BiometricKeyManager {
  static const _channel = MethodChannel('com.yourapp/biometric_key');

  @override
  Future<String> generateKeyPair(String keyAlias) async {
    return await _channel.invokeMethod('generateKeyPair', {'keyAlias': keyAlias});
  }

  @override
  Future<String> signChallenge(String keyAlias, Uint8List challenge) async {
    return await _channel.invokeMethod('signChallenge', {
      'keyAlias': keyAlias,
      'challenge': challenge,
    });
  }

  @override
  Future<bool> isKeyInvalidated(String keyAlias) async {
    return await _channel.invokeMethod('isKeyInvalidated', {'keyAlias': keyAlias});
  }

  @override
  Future<void> deleteKey(String keyAlias) async {
    await _channel.invokeMethod('deleteKey', {'keyAlias': keyAlias});
  }
}
```

iOS `BiometricKeyManagerPlugin.swift`：使用 `Security.framework` 的 `SecKeyCreateRandomKey` + `kSecAttrTokenIDSecureEnclave`，私钥指定 `kSecAttrAccessControl` 绑定 `biometryCurrentSet`，签名时触发 Face ID/Touch ID 弹窗，私钥从不离开 Secure Enclave。

Android `BiometricKeyManagerPlugin.kt`：使用 `KeyPairGenerator` + `KeyGenParameterSpec.Builder.setUserAuthenticationRequired(true)` + `BiometricPrompt.CryptoObject(signature)`。

**与 KMP 方案的差异**

KMP 方案使用 `expect/actual BiometricKeyManager` 接口，`iosMain` actual 需通过 Kotlin/Native `@ObjCInterop` 调用 `Security.framework`，语法繁琐。Flutter 方案 iOS 侧用 Swift 直接调用，Android 侧用 Kotlin 直接调用，各自语言更自然。两套方案工作量基本持平，此问题不构成差异性优劣势。

---

### 4.2 Refresh Token 安全存储

**Flutter 方案**

使用 `flutter_secure_storage v10.0.0`，iOS 写入 Keychain（`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`），Android 写入 EncryptedSharedPreferences（Android Keystore 保护 AES256-SIV 密钥）：

```dart
// core/auth/token_service.dart
class TokenService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
    // flutter_secure_storage v10：encryptedSharedPreferences 已废弃，
    // 改用 migrateOnAlgorithmChange 自动迁移加密算法变更后的现有数据。
    aOptions: AndroidOptions(migrateOnAlgorithmChange: true),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: 'access_token', value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
    ]);
  }
}
```

dio `AuthInterceptor` 在 401 响应时自动使用 Refresh Token 无感刷新 Access Token：

```dart
// core/network/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await _refreshDio.post('/v1/auth/refresh',
            data: {'refresh_token': refreshToken});
          final newTokens = AuthToken.fromJson(response.data);
          await _tokenService.saveTokens(
            accessToken: newTokens.accessToken,
            refreshToken: newTokens.refreshToken,
          );
          final retryOptions = err.requestOptions
            ..headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
          handler.resolve(await _dio.fetch(retryOptions));
          return;
        } catch (_) {
          await _tokenService.clearTokens();
          // 触发 AuthNotifier 跳转登录页
        }
      }
    }
    handler.next(err);
  }
}
```

**PRD 对接调整**

PRD-01 第 5.1 节需更新：删除"HttpOnly Secure Cookie"说明，改为"原生客户端以 JSON body 形式接收 Refresh Token，显式写入平台安全存储"。后端 `POST /v1/auth/login` 和 `POST /v1/auth/refresh` 响应体均包含 `refresh_token` 字段，不使用 Set-Cookie 头。

---

### 4.3 K 线图（CandleStick）

**Flutter 方案**

主选：`syncfusion_flutter_charts v32.2.9`

```dart
// features/market/widgets/candlestick_chart_widget.dart
class CandlestickChartWidget extends ConsumerWidget {
  final String symbol;
  final CandleInterval interval;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candleAsync = ref.watch(realtimeCandleProvider(symbol, interval));
    final colorScheme = ref.watch(themeNotifierProvider);

    return candleAsync.when(
      loading: () => const ChartSkeletonLoader(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (candles) => SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        trackballBehavior: TrackballBehavior(
          enable: true,
          activationMode: ActivationMode.longPress,
          tooltipSettings: const InteractiveTooltip(enable: true),
        ),
        series: <CartesianSeries<Candle, DateTime>>[
          CandleSeries<Candle, DateTime>(
            dataSource: candles,
            xValueMapper: (c, _) => c.time,
            lowValueMapper: (c, _) => c.low.toDouble(),   // 仅用于图表坐标渲染
            highValueMapper: (c, _) => c.high.toDouble(),
            openValueMapper: (c, _) => c.open.toDouble(),
            closeValueMapper: (c, _) => c.close.toDouble(),
            bullColor: colorScheme.upColor,
            bearColor: colorScheme.downColor,
          ),
        ],
        primaryXAxis: const DateTimeAxis(),
      ),
    );
  }
}
```

业务层 `Candle` entity 的 OHLCV 字段保持 `Decimal` 类型，仅在传入图表 mapper 时做 `Decimal.toDouble()` 转换（仅用于 Canvas 坐标计算，不影响财务计算精度）。

实时 WebSocket tick 更新最后一根未收盘 K 线，避免全量重绘：

```dart
@riverpod
class RealtimeCandleNotifier extends _$RealtimeCandleNotifier {
  @override
  Future<List<Candle>> build(String symbol, CandleInterval interval) async {
    final candles = await ref.watch(getCandlesUseCaseProvider).execute(symbol, interval);
    ref.listen(quoteStreamProvider(symbol), (_, quote) {
      final data = state.valueOrNull;
      if (data == null || quote == null) return;
      final updatedLast = data.last.updateWithTick(quote);
      state = AsyncData([...data.sublist(0, data.length - 1), updatedLast]);
    });
    return candles;
  }
}
```

**与 KMP 方案的差异**

KMP 方案 Vico 3.0.3（2026-03-07）是最大的正面变化，将 CMP K 线图支持升级为稳定版，但 Vico 不含长按十字线（crosshair）组件，需自行实现；Syncfusion 的 `TrackballBehavior` 提供开箱即用的长按十字线。两方案在 K 线图问题上评估为"平手"，Flutter 在 crosshair 上略省工时。

---

### 4.4 SMS OTP 自动填充

**Flutter 方案**

iOS 通过 `AutofillHints.oneTimeCode` 触发系统 SMS 建议栏（底层是 UITextField.textContentType = .oneTimeCode）：

```dart
// features/auth/widgets/otp_input_field.dart
AutofillGroup(
  child: TextField(
    autofillHints: const [AutofillHints.oneTimeCode],
    keyboardType: TextInputType.number,
    maxLength: 6,
    onChanged: (value) {
      if (value.length == 6) {
        TextInput.finishAutofillContext();
        onCompleted(value);
      }
    },
  ),
)
```

Android 通过 `smart_auth v3.2.0` SMS User Consent API 自动读取 OTP：

```dart
// features/auth/providers/sms_auth_provider.dart
@riverpod
class SmsOtpNotifier extends _$SmsOtpNotifier {
  final _smartAuth = SmartAuth();

  @override
  String? build() => null;

  Future<void> startListening() async {
    if (!Platform.isAndroid) return;
    final result = await _smartAuth.getSmsCode(useUserConsentApi: true);
    if (result.succeed && result.codeFound) state = result.code;
  }

  @override
  void dispose() {
    _smartAuth.removeSmsListener();
    super.dispose();
  }
}
```

**与 KMP 方案的差异**

KMP/CMP 1.10.2 中 iOS `textContentType.oneTimeCode` 稳定支持需等待 CMP 1.11.0（预计 Q2 2026），当前版本需 `UIKitView` 包裹原生 `UITextField` 作为 workaround，预估 2-3 天额外工作量且无法共享 CMP 样式系统。Flutter 方案无需任何 workaround，是 Flutter 相对 KMP 的明确优势。

---

### 4.5 设备 ID 生成

**Flutter 方案**

```dart
// core/auth/device_info_service.dart
class DeviceInfoService {
  static const _deviceIdKey = 'persistent_device_id';

  Future<String> getPersistentDeviceId() async {
    final existing = await _secureStorage.read(key: _deviceIdKey);
    if (existing != null) return existing;
    final newId = const Uuid().v4();
    await _secureStorage.write(key: _deviceIdKey, value: newId);
    return newId;
  }

  Future<DeviceInfo> getDeviceInfo() async {
    final deviceId = await getPersistentDeviceId();
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'ios',
        osVersion: iosInfo.systemVersion,
        model: iosInfo.utsname.machine,
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
      );
    } else {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'android',
        osVersion: androidInfo.version.release,
        model: '${androidInfo.manufacturer} ${androidInfo.model}',
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
      );
    }
  }
}
```

**与 KMP 方案的差异**

KMP 方案需要 `expect/actual fun getDeviceInfo()` 两套 actual 实现，通过 Kotlin/Native `@ObjCInterop` 调用 `UIKit.UIDevice`（iOS）和 `android.os.Build`（Android），代码量是 Flutter 方案的 2-3 倍。Flutter 的 `device_info_plus v12.3.0` 单一库开箱即用，Flutter 优。

---

### 4.6 推送通知（APNs/FCM）

**Flutter 方案**

```dart
// core/push/push_notification_service.dart
class PushNotificationService {
  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // 获取 FCM Token（APNs Token 关联由 Firebase iOS SDK 内部自动处理）
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _uploadToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_uploadToken);

    // 前台消息：通过 flutter_local_notifications 本地展示
    FirebaseMessaging.onMessage.listen(_handleForeground);
    // 后台点击跳转
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    // App 被推送唤起
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) _handleTap(initialMsg);
  }
}
```

iOS `AppDelegate.swift` 仅保留 Firebase 初始化，无需手动实现 `didRegisterForRemoteNotificationsWithDeviceToken`：

```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**与 KMP 方案的差异**

KMP 方案必须在 Swift AppDelegate 中手动实现 `didRegisterForRemoteNotificationsWithDeviceToken` 将 DeviceToken 传给 Kotlin 层，且 Firebase KMP SDK API 覆盖率仅 10%。Flutter 方案减少约 30% iOS 原生代码量，firebase_messaging 覆盖率接近 100%，Flutter 明显优。

---

### 4.7 Slide-to-Confirm 手势组件

**Flutter 方案**

在交易确认页通过 `PopScope` 禁用系统返回手势，使用 `slide_to_confirm v1.1.0`：

```dart
// features/trading/screens/order_confirmation_screen.dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    if (!didPop) _showCancelDialog(context);
  },
  child: Scaffold(
    body: Column(
      children: [
        OrderSummaryCard(draft: draft),
        const Spacer(),
        if (draft.riskWarnings.isNotEmpty)
          RiskWarningBanner(warnings: draft.riskWarnings),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SlideAction(
            text: '滑动确认委托',
            outerColor: Theme.of(context).primaryColor,
            onSubmit: () => _submitWithBiometric(context, ref),
          ),
        ),
      ],
    ),
  ),
)
```

**与 KMP 方案的差异**

KMP 方案需 `expect/actual DisableEdgeSwipeBack` 包装器，Flutter 的 `PopScope` 是标准 Widget，无需平台代码。纯 Flutter Widget（无 PlatformView）不存在与 iOS `UIGestureRecognizer` 的手势竞争问题，Flutter 优。

---

### 4.8 WebSocket 后台策略

**Flutter 方案**

> **Riverpod 3.0 Pause/Resume 已取代本节方案**
>
> 使用 Riverpod 3.0 的 `StreamProvider`（见§3.3）时，App 进入后台后 Provider 自动暂停（无监听者），回到前台自动恢复，**不需要下方的 `WidgetsBindingObserver` 手动生命周期管理**。以下代码保留作为退避参考（例如：在 `QuoteWebSocketClient` 内部维护底层 channel 连接时仍需处理断线重连逻辑）。

使用 `WidgetsBindingObserver` 监听 App 生命周期，进入后台主动断开，回到前台重连并通过 REST 快照补全数据：

```dart
// features/market/data/remote/quote_websocket_client.dart
class QuoteWebSocketClient with WidgetsBindingObserver {
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _reconnectAttempts = 0;
        _connect();
        _fetchRestSnapshot();
      case AppLifecycleState.paused:
        _disconnect();
      default:
        break;
    }
  }

  void _onDone() {
    // 指数退避重连：初始 100ms，最大 30s
    if (_reconnectAttempts < 10) {
      final delay = Duration(
        milliseconds: min(30000, 100 * pow(2, _reconnectAttempts).toInt()),
      );
      Timer(delay, () { _reconnectAttempts++; _connect(); });
    }
  }
}
```

iOS 侧明确不申请 `background-fetch` 或 `voip` 模式维持 WebSocket，避免 App Store 审核风险。

**与 KMP 方案的差异**

两方案本质等价：均受 iOS 系统后台网络约束，均需"前台 WebSocket + 后台 FCM + 回前台重连 + REST 快照补全"模式。差异在于 KMP 需 `expect/actual AppLifecycleObserver` 两套代码，Flutter 的 `WidgetsBindingObserver` 是纯 Dart，实现更简洁。

---

### 4.9 KYC 图片选择与裁剪

**Flutter 方案**

`image_picker v1.2.1` 选取，`image_cropper v11.0.0` 裁剪：

```dart
// features/kyc/widgets/document_capture_widget.dart
Future<void> captureDocument(ImageSource source) async {
  final XFile? image = await ImagePicker().pickImage(
    source: source,
    imageQuality: 90,
    preferredCameraDevice: CameraDevice.rear,
  );
  if (image == null) return;

  final croppedFile = await ImageCropper().cropImage(
    sourcePath: image.path,
    aspectRatioPresets: [CropAspectRatioPreset.ratio4x3],
    uiSettings: [
      AndroidUiSettings(toolbarTitle: '裁剪证件照片'),
      IOSUiSettings(title: '裁剪证件照片'),
    ],
  );
  if (croppedFile == null) return;

  // 验证文件大小 < 5MB
  final fileSize = await File(croppedFile.path).length();
  if (fileSize > 5 * 1024 * 1024) {
    // 提示用户重拍
    return;
  }

  onDocumentCaptured(File(croppedFile.path));
}
```

HEIC 处理：iOS 侧由系统在 `PHPickerViewController` 输出时自动转换；Android API 28+ 通过 `requestFullMetadata: true` 处理，低版本上传后由服务端转码。

**与 KMP 方案的差异**

KMP 方案图片裁剪需自绘 CMP 遮罩（预估 3-5 天），Flutter 的 `image_cropper` 调用 iOS `TOCropViewController` 和 Android Ucrop，均为生产级原生 UI，开发工时约 0.5 天，Flutter 明显优。

---

### 4.10 PDF 查看（W-8BEN）

**Flutter 方案**

使用 `pdfx v2.9.2`，加载 Presigned URL，同时启用截图防护：

```dart
// features/settings/screens/w8ben_viewer_screen.dart
class _W8benViewerState extends State<W8benViewerScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
    _pdfController = PdfController(
      document: PdfDocument.openUrl(widget.presignedUrl),
    );
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('W-8BEN 表格')),
      // 不提供分享按钮，防止含 TIN 的敏感文件外传
      body: PdfView(controller: _pdfController),
    );
  }
}
```

后端需补充接口 `GET /v1/users/w8ben/view-url`，返回 15 分钟有效的 Presigned URL（此问题已在 frontend-webview-supplement.md 问题 3 中提出）。

**与 KMP 方案的差异**

KMP 方案需 `expect/actual PdfViewer` + 两套 actual 实现，预估 3-4 天工作量。Flutter `pdfx` 开箱即用，预估 0.5 天，Flutter 明显优。

---

### 4.11 高频行情更新性能

**Flutter 方案架构**

Flutter/Dart 分代 GC（Scavenger + Mark-Compact）对大量短生命周期 `Quote` tick 对象的处理效率远高于 K/Native GC，Scavenger 在新生代快速回收不产生全局暂停。Impeller 渲染引擎运行在独立线程，Dart VM 高频数据处理不阻塞渲染流水线。

关键优化措施：

**优化 1：单一 Map Stream，避免 Provider 爆炸**

100 只股票使用单一 `Stream<Map<String, Quote>>` 而非 100 个独立 StreamProvider，通过 rxdart `throttleTime` 控制最高更新频率为 10fps（100ms 一次），减少 Widget 树重建次数。

**优化 2：select 最小化重建范围**

```dart
// 每行 Widget 只监听本 Symbol 价格变化
final quote = ref.watch(
  watchlistQuotesProvider.select((snap) => snap.valueOrNull?[symbol]),
);
```

**优化 3：Quote Entity 实现正确的 == 运算符**

```dart
@immutable
class Quote {
  final String symbol;
  final Decimal price;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Quote && symbol == other.symbol && price == other.price;

  @override
  int get hashCode => Object.hash(symbol, price);
}
```

**优化 4：数据新鲜度展示**

```dart
// shared/widgets/price/data_freshness_indicator.dart
final age = DateTime.now().toUtc().difference(quote.timestamp);
final isStale = age > const Duration(seconds: 10);

if (isStale) Icon(Icons.warning_amber, color: Colors.orange);
Text(timeago.format(quote.timestamp, locale: 'zh'));
```

**与 KMP 方案的差异**

KMP/CMP 中 K/Native GC 在高频场景的 P1 生产风险需真机实测验证，属于未知风险。Flutter Dart GC + Impeller 独立线程架构在 Nubank 等大规模金融 App 生产环境中已验证，是架构级优势。

---

### 4.12 iOS 原生一致性

**Flutter 方案**

Flutter 在 iOS 上的核心控件底层使用原生控件或等效实现：

| 功能 | Flutter 实现 | 状态 |
|------|------------|------|
| TextField / 输入框 | 底层 `UITextField`，IME/autofill 与系统一致 | 无问题 |
| ModalBottomSheet | `DraggableScrollableSheet`，行为与 iOS Sheet 一致 | 无问题 |
| 横向翻页 / Pager | `PageView`，底层 `UIScrollView`，fling 动画原生一致 | 无问题 |
| VoiceOver / 无障碍 | `Semantics` Widget 映射 `UIAccessibility`，行为与原生一致 | 无问题 |
| 大列表滚动性能 | `ListView.builder`，底层 `UIScrollView`，无 Canvas 性能瓶颈 | 无问题 |
| 截图防护 | `screen_protector v1.5.1`，Android FLAG_SECURE + iOS UITextField 方案 | 开箱即用 |

截图防护启用规范，以下页面必须启用：

```dart
// 敏感页面 Mixin
mixin ScreenProtectionMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ScreenProtector.preventScreenshotOn();
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }
}

// 需要启用的页面：
// OrderConfirmationScreen（交易确认）
// W8benViewerScreen（W-8BEN 文件）
// WithdrawalScreen（出金）
// SecuritySettingsScreen（安全设置）
// KycDocumentScreen（证件上传）
```

**与 KMP 方案的差异**

CMP 1.10.2 已将"P0 风险"降至"P1 已知限制"，但仍需维护版本兼容列表，每次 CMP 升级后重新验证。Flutter 的 iOS 原生一致性源于架构设计，不依赖特定版本的修复，无需维护兼容列表，在需要满足 ADA 可访问性要求的金融 App 场景下价值显著。

---

## 五、WebView/H5 方案

### 5.1 使用场景

根据 PRD 各模块梳理，App 内 WebView/H5 使用场景如下：

| 场景 | PRD 来源 | WebView 类型 | 是否需要登录态 |
|------|---------|------------|------------|
| 帮助中心 FAQ | PRD-08 第 7.1 节 | 公开 H5 | 否（Phase 1 无个性化内容） |
| 风险披露文件（5 份） | PRD-02 Step 6 | 内部 H5（带滚动检测） | 是 |
| 协议条款（5 份） | PRD-02 Step 7 | 内部 H5 | 是 |
| W-8BEN 查看 | PRD-08 第 3.2 节 | 使用原生 pdfx，不用 WebView | 是 |
| 用户协议/隐私政策 | PRD-01 第 3.1 节 | 公开 H5 | 否 |
| 营销落地页 | 行业标准（PRD 未明确） | 公开 H5 | 否 |

注意：W-8BEN 已确认使用 pdfx 原生渲染（见第 4.10 节），不通过 WebView 加载，避免 Token 泄露和 Google Docs Viewer 的 PII 风险。

### 5.2 WebView 实现方案

使用 `webview_flutter v4.10.0` 封装通用 WebView 容器：

```dart
// features/settings/screens/help_center_screen.dart
class AppWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final bool requiresAuth;           // 是否需要注入 Token
  final bool enableScrollTracking;   // 是否需要滚动到底检测（风险披露场景）
  final VoidCallback? onScrolledToBottom;

  const AppWebViewScreen({ ... });
}

class _AppWebViewScreenState extends State<AppWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 禁止本地文件访问
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            // 注入 JSBridge 和 Auth Context
            if (widget.requiresAuth) await _injectAuthContext();
            if (widget.enableScrollTracking) await _injectScrollTracker();
          },
          onWebResourceError: (error) => setState(() => _hasError = true),
          onNavigationRequest: (request) {
            // 域名白名单：只允许加载 *.yourapp.com 域名
            if (_isAllowedDomain(request.url)) {
              return NavigationDecision.navigate;
            }
            // 外部链接通过系统浏览器打开
            launchUrl(Uri.parse(request.url));
            return NavigationDecision.prevent;
          },
        ),
      )
      // 注册 JSBridge 消息处理器
      ..addJavaScriptChannel(
        'NativeBridge',
        onMessageReceived: _handleJsBridgeMessage,
      );

    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 处理 WebView 内多级页面的返回逻辑
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Stack(
          children: [
            if (!_hasError) WebViewWidget(controller: _controller),
            if (_isLoading) const LinearProgressIndicator(),
            if (_hasError) _buildErrorView(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 48),
          const Text('页面加载失败'),
          ElevatedButton(
            onPressed: () {
              setState(() => _hasError = false);
              _controller.reload();
            },
            child: const Text('重试'),
          ),
          // 合规关键页面提供离线 fallback
          if (widget.enableScrollTracking)
            TextButton(
              onPressed: _showOfflineFallback,
              child: const Text('查看本地缓存版本'),
            ),
        ],
      ),
    );
  }

  bool _isAllowedDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.endsWith('.yourapp.com') || uri.scheme == 'app';
    } catch (_) {
      return false;
    }
  }
}
```

### 5.3 JSBridge 设计

解决 frontend-webview-supplement.md 中 P0 问题（JSBridge 规范缺失）：

**H5 调用 Native 的接口（H5 → Native）**

H5 通过 `window.NativeBridge.postMessage(JSON.stringify({action, params}))` 调用 Native 能力：

```dart
// Flutter 端 JSBridge 消息处理
void _handleJsBridgeMessage(JavaScriptMessage message) {
  final payload = jsonDecode(message.message) as Map<String, dynamic>;
  final action = payload['action'] as String;
  final params = payload['params'] as Map<String, dynamic>? ?? {};

  switch (action) {
    case 'openEmailClient':
      final to = params['to'] as String;
      final subject = params['subject'] as String? ?? '';
      launchUrl(Uri(scheme: 'mailto', path: to, query: 'subject=$subject'));

    case 'closeWebView':
      final result = params['result'];
      Navigator.of(context).pop(result);

    case 'getAuthToken':
      // H5 请求最新 Token（用于 H5 内部发起 API 请求）
      _provideToken();

    case 'openNativeLogin':
      context.go('/auth/login');

    case 'navigateTo':
      // 从 H5 触发 Native 路由跳转
      final route = params['route'] as String;
      context.go(route);

    case 'shareFile':
      final url = params['url'] as String;
      final filename = params['filename'] as String;
      _shareFile(url, filename);

    case 'scrolledToBottom':
      // 风险披露文件滚动到底回调
      widget.onScrolledToBottom?.call();
  }
}
```

**Native 注入 H5 的接口（Native → H5）**

```dart
// 注入 Auth Context（页面加载完成后调用）
Future<void> _injectAuthContext() async {
  final token = await ref.read(tokenServiceProvider).getAccessToken();
  final colorScheme = ref.read(themeNotifierProvider).name;
  final locale = Localizations.localeOf(context).languageCode;

  await _controller.runJavaScript('''
    if (window.onNativeContext) {
      window.onNativeContext({
        token: "${token ?? ''}",
        colorScheme: "$colorScheme",
        locale: "$locale"
      });
    }
  ''');
}

// 主题变更时实时通知 WebView
Future<void> notifyThemeChange(String colorScheme) async {
  await _controller.runJavaScript('''
    if (window.onThemeChange) window.onThemeChange("$colorScheme");
  ''');
}

// 注入滚动到底检测 JS（风险披露文件场景）
Future<void> _injectScrollTracker() async {
  await _controller.runJavaScript('''
    window.addEventListener('scroll', function() {
      var scrolled = window.scrollY + window.innerHeight;
      var total = document.documentElement.scrollHeight;
      if (scrolled >= total - 20) {
        window.NativeBridge.postMessage(JSON.stringify({
          action: "scrolledToBottom",
          params: {}
        }));
      }
    });
  ''');
}
```

H5 端规范（前端约定）：

```javascript
// H5 端调用 Native 的统一方法（iOS/Android 通用）
function callNative(action, params = {}) {
  window.NativeBridge.postMessage(JSON.stringify({ action, params }));
}

// H5 端接收 Native 注入的 Context
window.onNativeContext = function({ token, colorScheme, locale }) {
  // 设置 API 请求 Header
  apiClient.setDefaultHeader('Authorization', `Bearer ${token}`);
  // 应用颜色方案
  document.documentElement.setAttribute('data-color-scheme', colorScheme);
};

// H5 端接收主题变更通知
window.onThemeChange = function(colorScheme) {
  document.documentElement.setAttribute('data-color-scheme', colorScheme);
};
```

### 5.4 H5 鉴权方案

解决 frontend-webview-supplement.md P0 问题（H5 鉴权方案缺失）：

**方案选择**：Native 在 WebView 加载完成后通过 `evaluateJavaScript` 注入短时效 Token，而非 URL 参数传递（防止 Token 出现在服务器访问日志）或 Cookie 同步（Refresh 链路复杂）。

```dart
Future<void> _injectAuthContext() async {
  // 获取当前 Access Token（最多 15 分钟有效）
  final token = await ref.read(tokenServiceProvider).getAccessToken();

  // 注入到 H5，H5 用此 Token 发起 API 请求
  await _controller.runJavaScript('''
    if (window.onNativeContext) {
      window.onNativeContext({ token: "${token ?? ''}" });
    }
  ''');
}
```

Token 刷新：`AuthInterceptor` 在后台自动刷新 Access Token 时，通过 `AppWebViewScreen` 的公开方法重新注入新 Token：

```dart
// Token 刷新后，通知所有活跃的 WebView 实例更新 Token
// 通过 Riverpod GlobalKey 或 EventBus 通知
```

**Token 安全注意事项**：

- 通过 `evaluateJavaScript` 注入 Token 时，Token 不经过 URL，不会出现在网络请求日志中
- WebView 域名白名单确保 Token 只注入到受信任域名的页面
- H5 页面收到 Token 后应存储在内存变量中，不写入 localStorage 或 Cookie

**访客态（未登录）WebView 规则**：

帮助中心、用户协议、隐私政策等公开页面：`requiresAuth: false`，不注入 Token，H5 设计为无需登录即可访问。访客在 H5 内点击"立即开户"等 CTA 时，通过 `callNative('openNativeLogin')` 触发 Native 登录流程，H5 内不实现任何登录逻辑。

---

## 六、安全合规要求落地

### 6.1 数据安全

**flutter_secure_storage 使用规范**

```dart
// core/storage/secure_storage_service.dart
// 规则：以下字段必须通过 SecureStorageService 存储，禁止使用 shared_preferences

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      // 设备锁定时不可访问（防止越狱后从内存转储读取）
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
    // flutter_secure_storage v10：encryptedSharedPreferences 已废弃，
    // 改用 migrateOnAlgorithmChange 自动迁移加密算法变更后的现有数据。
    aOptions: AndroidOptions(
      migrateOnAlgorithmChange: true,
    ),
  );

  // 必须使用安全存储的字段：
  // - access_token（JWT）
  // - refresh_token
  // - persistent_device_id（设备 ID）
  // - biometric_key_registered（生物识别密钥注册标记）

  // 禁止存储在安全存储中的字段（不必要，降低性能）：
  // - 用户偏好（颜色方案、语言等）-> 使用 shared_preferences
  // - 非敏感缓存数据 -> 使用 drift 或 hive_ce
}
```

**加密存储策略**

PII 字段（SSN、HKID、银行卡号、出生日期）不在客户端本地存储，仅在 API 请求时传输（加密传输）。如需本地缓存（如 KYC 草稿），使用 drift 配合 `sqlcipher`（如有需求可引入 `drift_sqflite` 加密版本）。

日志中禁止记录的字段：

```dart
// lib/core/logging/app_logger.dart
class AppLogger {
  static const _piiPatterns = [
    r'\b\d{3}-\d{2}-\d{4}\b',  // SSN
    r'\b[A-Z]\d{6}\(\d\)\b',    // HKID
    r'\b\d{16}\b',               // 银行卡号
  ];

  static String _maskPii(String message) {
    var masked = message;
    for (final pattern in _piiPatterns) {
      masked = masked.replaceAll(RegExp(pattern), '[REDACTED]');
    }
    return masked;
  }

  static void info(String message, {Map<String, dynamic>? extra}) {
    final safeMessage = _maskPii(message);
    // 使用 logger 包输出结构化日志
  }
}
```

### 6.2 截图防护

使用 `screen_protector v1.5.1`，以下页面必须启用：

| 页面 | 原因 |
|------|------|
| OrderConfirmationScreen | 含股票代码、价格、账户余额 |
| W8benViewerScreen | 含 TIN、签名等 PII |
| WithdrawalScreen | 含银行卡号、金额 |
| SecuritySettingsScreen | 含生物识别设置、设备列表 |
| KycDocumentScreen | 含证件图片 |
| ProfileScreen（展示账户详情时） | 含完整姓名、账户号码 |

实现方式见第 4.12 节中的 `ScreenProtectionMixin`。

### 6.3 越狱/Root 检测

> **`flutter_jailbreak_detection` 已移除**
>
> 该包已停止维护，且与 AGP 8.0+（当前项目使用的 Android Gradle Plugin 版本）存在不兼容问题（Gradle 构建报错）。已从 `pubspec.yaml` 移除。

**Phase 1 当前实现：文件路径启发式检测**

```dart
// core/security/jailbreak_detection_service.dart
class JailbreakDetectionService {
  Future<SecurityCheckResult> check() async {
    if (Platform.isIOS) return await _checkIos();
    if (Platform.isAndroid) return await _checkAndroid();
    return SecurityCheckResult.clean;
  }

  Future<SecurityCheckResult> _checkIos() async {
    const jailbreakPaths = [
      '/Applications/Cydia.app',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
    ];
    for (final path in jailbreakPaths) {
      if (await File(path).exists()) return SecurityCheckResult.jailbroken;
    }
    return SecurityCheckResult.clean;
  }

  Future<SecurityCheckResult> _checkAndroid() async {
    const rootPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
    ];
    for (final path in rootPaths) {
      if (await File(path).exists()) return SecurityCheckResult.rooted;
    }
    return SecurityCheckResult.clean;
  }
}
```

注：文件路径启发式检测容易被高级越狱绕过，作为 Phase 1 基础防线。

**Phase 2 改进路线图（Android）：Play Integrity API**

通过 Google Play Integrity API 获取服务器端签名的设备完整性判定令牌：
1. 客户端调用 `IntegrityManager.requestIntegrityToken(nonce)` 获取令牌
2. 将令牌传给 AMS 后端，后端调用 Google Integrity API 解密并验证 `deviceIntegrity.deviceRecognitionVerdict`
3. 若 verdict 不包含 `MEETS_DEVICE_INTEGRITY`，AMS 返回受限会话标记
4. 客户端根据标记限制交易功能

**Phase 2 改进路线图（iOS）：App Attest**

通过 Apple App Attest 框架验证设备合法性：
1. 首次启动时生成 Attestation Key，通过 AMS 后端向 Apple App Attest Service 验证
2. 后端存储公钥，后续请求携带 Assertion（签名的请求哈希）
3. 后端用存储的公钥验证每次 Assertion，确保请求来自合法未改装的 App

**检测结果处理策略**

```dart
// App 启动时检测，在 main.dart 中执行
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final securityCheck = await JailbreakDetectionService().check();

  runApp(
    ProviderScope(
      overrides: [
        securityCheckResultProvider.overrideWithValue(securityCheck),
      ],
      child: const App(),
    ),
  );
}
```

| 检测结果 | 处置动作 |
|--------|--------|
| `jailbroken` / `rooted` | 显示不可关闭的警告对话框；禁止下单和出入金；允许查看行情（只读） |
| `developerModeEnabled` | 仅 Release 构建下显示警告；Debug/Profile 构建忽略 |
| `clean` | 正常运行 |

### 6.4 证书固定（Certificate Pinning）

采用 **SPKI SHA-256 公钥指纹固定**方案，优于直接固定证书 DER 指纹：SPKI 指纹绑定的是密钥对本身，证书续签（同一密钥对签发新证书）不影响指纹，降低证书轮换时的发版压力。

```dart
// core/security/ssl_pinning_config.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class SslPinningConfig {
  /// SPKI SHA-256 指纹（Base64 编码），始终维护两条：当前生效 + 下次轮换备用。
  static const _spkiPins = {
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // 当前证书 SPKI 指纹
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // 轮换备用 SPKI 指纹
  };

  /// 从 DER 编码的证书中提取 SPKI 字节并计算 SHA-256 指纹。
  /// 生产环境应使用 ASN.1 解析库或平台 API（SecCertificateCopyKey / X509_get_X509_PUBKEY）
  /// 提取精确的 SubjectPublicKeyInfo 字节，而非对整个 DER 做哈希。
  static String _computeSpkiPin(Uint8List certDer) {
    // TODO: 替换为正式的 ASN.1 SPKI 提取实现
    final digest = sha256.convert(certDer);
    return 'sha256/${base64.encode(digest.bytes)}';
  }

  static HttpClient createPinnedHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      final pin = _computeSpkiPin(cert.der);
      if (_spkiPins.contains(pin)) return true; // 指纹匹配，允许连接

      // 指纹不匹配：记录安全事件，拒绝连接
      AppLogger.security(
        'SSL pin mismatch for $host — expected one of $_spkiPins, got $pin',
      );
      return false;
    };
    return client;
  }
}

// core/network/dio_client.dart
Dio createDioClient() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
      SslPinningConfig.createPinnedHttpClient;

  dio.interceptors.addAll([
    AuthInterceptor(_tokenService),
    RequestSigningInterceptor(),
    ErrorInterceptor(),
  ]);

  return dio;
}
```

**证书轮换标准操作程序（SOP）**

| 时间节点 | 操作 | 说明 |
|--------|------|------|
| T−30 天 | 将新证书的 SPKI 指纹加入 `_spkiPins` 作为第二条 | 发 App 更新版本，旧证书指纹仍保留 |
| T=0 | 服务端部署新证书 | 新旧两个指纹均在 App 白名单中，新老版本均可连接 |
| T+30 天 | 充分等待新版 App 覆盖率后，移除旧证书指纹 | 发 App 更新版本，清除旧指纹 |

注：Sprint 0 验证项第 12 条（Charles Proxy MitM 测试）需验证指纹固定生效。

---

## 七、Sprint 0 验证清单

必须在功能开发启动前完成的 PoC 验证：

| # | 验证项 | 验证目标 | 验收标准 | 预估工时 |
|---|-------|---------|---------|---------|
| 1 | K 线图性能（Syncfusion） | iPhone 15 上渲染 500 根日 K 线 + pinch-zoom + 实时 tick 更新 | 帧率 ≥ 55fps（Xcode Instruments Time Profiler 实测），无明显卡顿 | 2 天 |
| 2 | K 线图备选方案（financial_chart） | 同上，验证 financial_chart v0.4.1 | 帧率 ≥ 55fps，确认 crosshair 实现难度 | 1 天 |
| 3 | 生物识别密钥签名 | iOS Secure Enclave 密钥生成 + Face ID 触发签名，Android Keystore + BiometricPrompt.CryptoObject 签名 | 两端 Method Channel 返回正确的 Base64 签名，服务端验证通过 | 3 天 |
| 4 | Watchlist 高频行情（100 只股票） | 模拟 100 只股票 100ms 间隔并发 WebSocket 更新，iPhone 14 实测 | 帧率 ≥ 55fps，Dart DevTools Memory 面板无内存持续增长，GC 频率正常 | 2 天 |
| 5 | flutter_secure_storage Keychain 行为 | iOS App 卸载重装后 Keychain 数据保留/清除行为，iCloud Keychain 同步策略 | 确认 `unlocked_this_device` 配置下数据在 App 重装后被清除，符合安全预期 | 0.5 天 |
| 6 | WebView JSBridge 通信 | H5 调用 `callNative('closeWebView', {result: {agreed: true}})`，Flutter 端收到并关闭 WebView | 双端（iOS/Android）均能正确收发消息，无时序问题 | 1 天 |
| 7 | SMS OTP 自动填充 | iOS 真机接收含验证码的短信后键盘建议栏显示验证码；Android SMS User Consent 弹窗正常 | 两端均能触发系统 OTP 自动填充，无需手动输入 | 1 天 |
| 8 | 截图防护验证 | 在 OrderConfirmationScreen 触发系统截图（电源+音量/Home+电源），录屏场景 | iOS 截图显示空白，录屏被阻止；Android FLAG_SECURE 生效 | 0.5 天 |
| 9 | WebSocket 后台重连 | App 进入后台 30 秒，回到前台后 WebSocket 重连并 REST 快照补全 | 回前台 3 秒内行情数据恢复显示最新价，无空白或 NaN | 1 天 |
| 10 | pdfx PDF 渲染（W-8BEN） | 加载 Presigned URL 的 PDF，iOS/Android 双端渲染 | 文字清晰可读，支持滚动，截图防护已启用 | 0.5 天 |
| 11 | Syncfusion 许可证确认 | 确认 Community License 适用条件（年营收 < $1M），若超过则确认商业授权流程 | 获得法务/业务确认，明确后续授权路径 | 0.5 天 |
| 12 | 证书固定验证 | 使用 Charles Proxy 模拟 MitM 攻击，App 应拒绝连接 | App 在 Charles 代理下无法发起 API 请求，显示网络错误而非数据 | 0.5 天 |

**Sprint 0 总工时估算：约 13 天**

Sprint 0 验证的 Go/No-Go 判断：
- 若第 1/2 项 K 线图帧率均低于 55fps，需立即评估 CustomPainter 自绘方案
- 若第 3 项生物识别签名 Method Channel 实现超过 5 天工时，需重新评估时间表
- 若第 4 项高频行情帧率低于 55fps，需引入 `rxdart debounce` 降低更新频率

---

## 八、与后端 PRD 规格的对接说明

### 8.1 Refresh Token 存储方案变更（影响 PRD-01）

**变更内容**：PRD-01 第 5.1 节原规格"Refresh Token 存储于 HttpOnly + Secure + SameSite=Strict Cookie"在原生 App 中无安全意义，需更改。

**变更后规格**：

```
登录接口：POST /v1/auth/login
响应体（变更前）：
{
  "access_token": "eyJ...",
  "expires_in": 900
}
Set-Cookie: refresh_token=...; HttpOnly; Secure; SameSite=Strict; Path=/v1/auth/refresh

响应体（变更后）：
{
  "access_token": "eyJ...",
  "expires_in": 900,
  "refresh_token": "opaque-token-string",  // 新增字段
  "refresh_expires_in": 604800
}
// 不再使用 Set-Cookie 头

刷新接口：POST /v1/auth/refresh
请求体（变更前）：Cookie 自动携带 refresh_token
请求体（变更后）：
{
  "refresh_token": "opaque-token-string"
}
```

**后端影响**：后端刷新 Token 接口从读取 Cookie 改为读取 JSON body，需更新中间件逻辑。Web 端（Admin Panel）仍可使用 HttpOnly Cookie 方案，需区分 Web 和原生 App 的 Token 存储路径。

**安全等级不降低**：原生 App 的 flutter_secure_storage 使用 iOS Keychain 和 Android EncryptedSharedPreferences，均为系统级硬件保护，安全性不低于 HttpOnly Cookie。

### 8.2 W-8BEN PDF 访问接口缺失（影响 PRD-08）

frontend-webview-supplement.md 问题 3 指出 PRD-08 的 API 规格中缺少 W-8BEN 文件访问接口，Flutter 方案使用 `pdfx` 加载 Presigned URL，需要补充该接口：

```
新增接口：GET /v1/users/w8ben/view-url
认证：Bearer JWT（必须）
响应：
{
  "url": "https://storage.yourapp.com/kyc/w8ben/user-123.pdf?X-Signature=...",
  "expires_at": "2026-03-13T10:45:00Z"  // 15 分钟有效期
}
```

### 8.3 KYC Step 6 服务端验证补充（影响 PRD-02）

frontend-webview-supplement.md 问题 4 指出风险披露文件的"滚动到底"检测纯依赖前端，可被绕过。Flutter 方案中风险披露文件使用原生 `ScrollController` 监听滚动，但服务端也应补充验证字段：

```
修改接口：POST /v1/kyc/submit
请求体新增字段：
{
  "read_documents": [
    "RISK_DISCLOSURE_1",
    "RISK_DISCLOSURE_2",
    "RISK_DISCLOSURE_3",
    "RISK_DISCLOSURE_4",
    "RISK_DISCLOSURE_5"
  ]
}
```

服务端验证 `read_documents` 包含所有必读文件，否则返回 400，消除前端绕过风险，满足 FINRA Rule 2010 合规要求。

### 8.4 内容配置接口（解决 H5 URL 硬编码问题）

frontend-webview-supplement.md 问题 5 和 9 指出 WebView URL 硬编码和内容版本管理问题。Flutter 方案通过启动时拉取配置避免硬编码：

```
新增接口：GET /v1/app/content-config
认证：可无需认证（公开接口，允许启动时调用）
响应：
{
  "help_center_url": "https://help.yourapp.com/faq",
  "terms_url": "https://h5.yourapp.com/terms",
  "privacy_url": "https://h5.yourapp.com/privacy",
  "agreement_versions": {
    "CLIENT_AGREEMENT": "v2.1",
    "RISK_DISCLOSURE_1": "v1.3",
    ...
  }
}
```

Flutter 端在 App 启动时（`main.dart`）拉取并缓存此配置，所有 WebView 使用配置中的 URL，不硬编码。

### 8.5 设备 Token 上报接口规范

APNs/FCM Token 上报需标注平台：

```
接口：POST /v1/devices/push-token
请求体：
{
  "device_id": "uuid-v4",        // 持久化设备 ID
  "platform": "ios" | "android",
  "push_token": "fcm-or-apns-token",
  "app_version": "1.0.0+1"
}
```

Flutter 端在 `PushNotificationService.initialize()` 中调用，Token 刷新时重新调用。

---

## 九、包管理问题追踪与 Phase 2 路线图

### 9.1 已移除包的问题追踪

| 包名 | 原版本 | 移除原因 | 替代方案 |
|------|------|---------|---------|
| `retrofit` | ^4.4.1 | Dart 3.11 穷举 switch 要求导致生成代码编译失败，上游修复进度不可预测 | 手写 `RemoteDataSource`（见§2.3）；Phase 2 可评估 `chopper` 或 OpenAPI Generator |
| `retrofit_generator` | ^9.1.3 | 同上，`retrofit` 生成器 | 同上 |
| `flutter_jailbreak_detection` | ^1.9.0 | 包无维护（最后更新 2023 年），AGP 8.0+ 不兼容导致 Android 构建失败 | Phase 1：文件路径启发式检测（见§6.3）；Phase 2：Play Integrity API（Android）+ App Attest（iOS） |
| `financial_chart` | ^0.4.1 | Sprint 0 评估完成，选定 Syncfusion 作为唯一图表库 | `syncfusion_flutter_charts ^32.2.9`（已采用） |

### 9.2 待升级包

| 包名 | 当前版本（pubspec.yaml） | 目标版本 | 升级原因 | 优先级 |
|------|------------------|---------|---------|------|
| `flutter_riverpod` / `riverpod_annotation` / `riverpod_generator` / `hooks_riverpod` | ^2.6.1 | ^3.0.0 | Riverpod 3.0 自动重试、Pause/Resume、统一 Ref API（见§2.3、§3.3、§4.8） | P1（Phase 2 初期） |
| `very_good_analysis` | ^7.0.0 | ^10.1.0 | Dart 3.11 兼容；7.0.0 在 Dart 3.11 下部分规则报错 | P1（Phase 2 初期） |
| `image_cropper` | ^11.0.0 | 已对齐 | pubspec.yaml 实际版本已是 ^11.0.0，tech spec §4.9 文本中旧版本号 ^7.1.5 已修正 | 已完成 |
| `custom_lint` | 未引入 | ^0.7.0 | Phase 2 引入自定义 Lint 规则，配合 riverpod_lint | P2 |
| `riverpod_lint` | 未引入 | ^2.6.0 | Riverpod 专项 Lint 检查，Phase 2 引入 | P2 |

### 9.3 `analysis_options.yaml` Phase 2 严格化计划

当前 `analysis_options.yaml` 使用 `flutter_lints ^5.0.0` 作为基础，Phase 1 刻意放宽部分严格规则以确保初始化骨架 0 error。Phase 2 分三批次逐步启用更严格规则：

**批次 1（Phase 2 Sprint 1）：代码组织规则**

```yaml
# analysis_options.yaml — 批次 1 追加
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - avoid_dynamic_calls
    - always_use_package_imports
```

**批次 2（Phase 2 Sprint 2）：类型安全规则**

```yaml
# analysis_options.yaml — 批次 2 追加
analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
linter:
  rules:
    - avoid_annotating_with_dynamic
    - prefer_void_to_null
    - use_super_parameters
    - no_wildcard_variable_uses      # Dart 3.x pattern variable 安全
```

**批次 3（Phase 2 Sprint 3）：完整 very_good_analysis**

升级至 `very_good_analysis ^10.1.0` 后，以 `very_good_analysis` 替换 `flutter_lints` 作为 include 基础，同步启用所有 VGV 推荐规则。升级步骤：

1. 在 `pubspec.yaml` 中将 `very_good_analysis: ^7.0.0` 升级为 `^10.1.0`，运行 `flutter pub get`
2. 在 `analysis_options.yaml` 中替换 `include: package:flutter_lints/flutter.yaml` 为 `include: package:very_good_analysis/flutter.yaml`
3. 运行 `flutter analyze`，批量修复新增报错（主要为命名规范、文档注释要求）
4. 针对金融代码特殊场景（如 Syncfusion Chart 需要 `toDouble()` 转换）添加局部 `// ignore:` 注释并说明理由