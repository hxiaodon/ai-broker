# Flutter 脚手架问题清单

**扫描日期**：2026-03-28
**项目**：brokerage-trading-app-agents/mobile
**结论**：架构设计优秀，但有 3 个关键问题需要立即处理

---

## 🔴 严重问题 (Critical)

### 1. **零测试覆盖** — 金融应用高风险

**现状**：
- ❌ 无 `test/` 目录（零单元测试）
- ❌ 无 `integration_test/` 目录（零集成测试）
- ❌ 依赖 `flutter_test` 和 `mocktail` 但完全未使用

**未测试的关键模块**：
- Token 刷新逻辑（JWT 401 处理）— **财务系统风险**
- 证书钉钉验证（SPKI SHA-256）— **安全风险**
- PII 日志掩码 — **合规风险**
- 错误异常处理 — **可靠性风险**
- 越狱/Root 检测 — **安全风险**

**影响**：
- 无法发现线上 bug
- 金融应用无法通过审计
- 新增功能无法验证

**修复**：
```bash
# 立即创建测试骨架
mkdir -p test/core/{auth,network,security,logging}
mkdir -p integration_test/{features,auth}

# 编写优先测试（48 小时内）
# test/core/auth/token_service_test.dart
# test/core/network/auth_interceptor_test.dart
# test/core/security/jailbreak_detection_service_test.dart
# test/core/logging/app_logger_test.dart
```

**优先级**：⭐⭐⭐⭐⭐ 最高
**工作量**：40-60 小时（第 1 周）

---

### 2. **Features 层空壳实现** — 功能无法使用

**现状**：
```
features/ 目录结构完美，但 90% 是占位符：
- auth/domain/entities/ ✅ 完成
- auth/domain/repositories/ ✅ 完成
- auth/data/ ❌ 空目录
- auth/presentation/ ❌ 空目录
- 其他 6 个特性类似状态
```

**关键缺失**：
| 特性 | 缺失部分 | 影响 |
|------|----------|------|
| Auth | AuthRepositoryImpl + 登录屏幕 | 无法登录 |
| Market | 报价 provider + 市场详情屏幕 | 无法查看行情 |
| Trading | 订单 provider + 交易屏幕 | 无法下单 |
| KYC | KYC flow + UI 屏幕 | 无法完成认证 |
| Funding | 资金 provider + 出入金屏幕 | 无法充值 |
| Portfolio | 持仓 provider + 投资组合屏幕 | 无法查看头寸 |
| Settings | 设置屏幕 | 无法配置 |

**当前代码问题**：
```dart
// app_router.dart 第 30 行
final _Placeholder() => const _Placeholder();  // ❌ 占位符
```

**修复**：
- 为每个特性实现完整的 `data/` 层（至少 stub 实现）
- 为每个特性实现 `presentation/` 层（providers + screens）
- 移除 `_Placeholder` widget，用真实实现替换

**优先级**：⭐⭐⭐⭐⭐ 最高
**工作量**：120-180 小时（第 2-4 周）

---

### 3. **推送通知服务未初始化** — 关键功能缺失

**现状**：
```dart
// push_notification_service.dart
Future<void> initialize() async {
  // Phase 2: await Firebase.initializeApp();
}
```

**问题**：
- ❌ Firebase 未初始化
- ❌ 无法接收推送通知
- ❌ 订单确认、行情推送、账户告警全部不可用

**需要立即实现**：
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 初始化 Firebase
  await Firebase.initializeApp();

  // ✅ 配置 FCM
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission();

  // ✅ 设置后台消息处理
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
```

**优先级**：⭐⭐⭐⭐⭐ 最高
**工作量**：8-12 小时

---

## 🟡 重要问题 (High)

### 4. **状态管理集成不完整**

**问题**：
- ⚠️ Riverpod providers 存在但未连接（AuthInterceptor 的 `getAccessToken` 是手工 lambda，而非 ref 注入）
- ⚠️ 缺失 `StateNotifier<T>` 子类（无法追踪业务状态变化）
- ⚠️ 所有逻辑都在 Repository 中，Riverpod 无法管理状态流

**现有代码问题**：
```dart
// auth_interceptor.dart
String? Function() getAccessToken = () => null;  // ❌ 硬编码
Future<String?> Function() refreshAccessToken = () async => null;
```

**修复方案**：
```dart
@riverpod
class authNotifier extends _$authNotifier {
  @override
  Future<AuthState> build() => Future.value(const AuthState.initial());

  Future<void> login(String phone) async {
    state = const AsyncValue.loading();
    try {
      // ...
      state = AsyncValue.data(AuthState.loggedIn(token));
    } catch (e) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 在 AuthInterceptor 中使用
ref.watch(authNotifierProvider).whenData((state) => state.accessToken)
```

**优先级**：⭐⭐⭐⭐ 高
**工作量**：16-24 小时

---

### 5. **SSL 证书钉扎实现不完整**

**问题**：
```dart
// ssl_pinning_config.dart 第 99-105 行
// Using the full DER bytes gives a cert-level pin (not a true SPKI pin)
// until the ASN.1 extraction is implemented in Phase 2.  ❌ TODO
```

**现状**：
- 使用完整证书而非 SPKI（SubjectPublicKeyInfo）
- 不符合 OWASP 最佳实践
- 证书更新时必须修改应用代码

**应该改为 SPKI**：
```dart
import 'package:asn1lib/asn1lib.dart' as asn1;

Future<String> extractSPKI(List<int> derBytes) async {
  final asn = asn1.ASN1Parser(derBytes).nextObject() as asn1.ASN1Sequence;
  final tbsCert = asn.elements[0];
  final publicKey = (tbsCert as asn1.ASN1Sequence).elements[6];
  final publicKeyBits = (publicKey as asn1.ASN1Sequence).elements[1] as asn1.ASN1BitString;
  final spkiHash = sha256.convert(publicKeyBits.bytes).toString();
  return 'sha256/$spkiHash';
}
```

**优先级**：⭐⭐⭐⭐ 高
**工作量**：8-12 小时

---

### 6. **缺失多环境配置（Build Flavor）**

**问题**：
- ❌ 无 dev/staging/prod 环境区分
- ❌ 无法管理多环境 API 端点
- ❌ 无 Firebase 项目切换机制

**需要实现**：
```yaml
# android/app/build.gradle.kts
flavorDimensions("env")

productFlavors {
  create("dev") {
    dimension = "env"
    applicationIdSuffix = ".dev"
    manifestPlaceholders["apiBaseUrl"] = "https://api-dev.example.com"
    manifestPlaceholders["firebaseJsonUrl"] = "..." // dev Firebase
  }

  create("staging") {
    dimension = "env"
    applicationIdSuffix = ".staging"
    manifestPlaceholders["apiBaseUrl"] = "https://api-staging.example.com"
  }

  create("prod") {
    dimension = "env"
    manifestPlaceholders["apiBaseUrl"] = "https://api.example.com"
  }
}
```

**iOS 类似配置**（xcconfig 文件）

**优先级**：⭐⭐⭐⭐ 高
**工作量**：12-16 小时

---

### 7. **网络层缺少重试和熔断机制**

**问题**：
```dart
// dio_client.dart
// ❌ 无自动重试（除了 401 刷新）
// ❌ 无熔断器（连续失败仍然尝试）
// ❌ 并发 401 处理有竞争条件
```

**需要实现**：
```dart
// 1. 重试机制（指数退避）
dio.interceptors.add(
  RetryInterceptor(
    dio: dio,
    logPrint: logger.d,
    retries: 3,
    retryDelays: const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
    ],
  ),
);

// 2. 修复并发 401
// 使用 Completer 同步刷新结果
final _refreshCompleter = Completer<String?>();

// 3. 熔断器
// 某个端点连续失败 5 次后，30 秒内直接返回缓存或错误
```

**优先级**：⭐⭐⭐ 中
**工作量**：16-20 小时

---

## 🟢 中等问题 (Medium)

### 8. **越狱/Root 检测太弱**

**问题**：
- ⚠️ 仅检查文件路径（易被绕过）
- Phase 2 计划中有 Play Integrity API (Android) 和 App Attest (iOS)，但未实现

**现有实现**：
```dart
// jailbreak_detection_service.dart 第 25-40 行
static const _suspiciousFiles = [
  '/Applications/Cydia.app',
  '/Library/MobileSubstrate',
  '/bin/bash',
  // ...
];
```

**需要升级到**：
```dart
// Android: Play Integrity API
import 'package:google_play_integrity/google_play_integrity.dart';

// iOS: App Attest
import 'package:app_attest/app_attest.dart';
```

**优先级**：⭐⭐⭐ 中
**工作量**：16-20 小时（Phase 2）

---

### 9. **数据库完全未配置**

**问题**：
```dart
// database.dart
const database = null;  // ❌ 空实现
```

**需要**：
- 定义 Drift 表结构（orders, positions, watchlist 等）
- 实现数据库迁移（goose）
- 配置 SQLite 加密

**优先级**：⭐⭐⭐ 中
**工作量**：24-32 小时（第 3-4 周）

---

### 10. **文档严重不足**

**现状**：
- Doc comment 覆盖率仅 8%
- Features 层约 2% 覆盖
- Widgets/Providers 完全无文档

**需要**：
- 为所有 public API 添加 doc comment
- 生成 Dartdoc 文档
- 编写使用指南

**优先级**：⭐⭐⭐ 中
**工作量**：20-30 小时（第 2-3 周）

---

## 📋 依赖版本问题

### 11. **过时依赖和缺失依赖**

**过时库**（>6 个月未更新）：
| 库 | 版本 | 问题 | 优先级 |
|-----|------|------|--------|
| pdfx | 2.9.2 | 超期未更新 | P2 |
| screen_protector | 1.5.1 | 小库，维护未知 | P2 |
| smart_auth | 3.2.0 | SMS OTP，关键安全功能 | P1 |

**缺失库**（应该添加）：
```yaml
dev_dependencies:
  test: ^1.25.0              # ❌ 缺失单元测试框架
  sentry_flutter: ^8.0.0     # ❌ 缺失错误追踪
  patrol: ^3.0.0             # ❌ 缺失 E2E 测试

dependencies:
  firebase_messaging: ^14.8.0 # ❌ 缺失推送（已在代码中使用但未声明）
  flutter_local_notifications: ^17.0.0  # ❌ 缺失本地通知
```

**优先级**：⭐⭐⭐ 中
**工作量**：4-8 小时

---

## ✅ 正确之处（值得保留）

这个脚手架做对的事：

1. **Clean Architecture** ✅ — 完美的分层设计
2. **Security 实现** ✅ — PII 掩码、Secure Storage、屏幕保护都做了
3. **Error Handling** ✅ — 完整的异常层级和拦截器链
4. **Code Quality** ✅ — 零警告、严格类型检查、无 dead code
5. **Riverpod DI** ✅ — 依赖注入框架配置正确

---

## 🚀 修复优先级与时间表

### Week 1（立即）— Critical Path
```
Day 1-2: 创建测试框架 + Firebase 初始化
  ├─ test/ 目录结构
  ├─ Firebase init
  ├─ FCM setup
  └─ 推送通知处理

Day 3-4: Auth 特性实现
  ├─ AuthRepositoryImpl
  ├─ AuthNotifier
  ├─ Login 屏幕骨架
  └─ 关键路径集成测试

Day 5: 关键测试编写
  ├─ TokenService tests
  ├─ AuthInterceptor tests
  └─ AppLogger tests

工作量：40-48 小时
```

### Week 2-3（高优先级）
```
- 完成 6 个特性的 data 层 (stub)
- 完成 6 个特性的 presentation 层
- SSL SPKI 修复
- Build Flavor 配置
- 状态管理集成完成

工作量：80-120 小时
```

### Week 4+（中优先级）
```
- 网络层重试/熔断
- 数据库配置
- 文档补充
- Play Integrity / App Attest
- E2E 测试

工作量：60-80 小时
```

---

## 成功指标

**Go/No-Go 决策点**：

```
✅ Green Light 前置条件（必须满足）：
  - [ ] test/ 目录已创建，>5 个关键路径测试通过
  - [ ] Firebase 初始化成功，推送通知可工作
  - [ ] Auth 特性完整（登录/注销/刷新令牌）
  - [ ] 6 个特性至少有骨架屏幕（可导航）
  - [ ] 无构建错误、零 analyze 警告

🟡 Beta Launch 条件（90 天内）：
  - [ ] 测试覆盖率 >60%
  - [ ] 所有 6 个特性功能完整
  - [ ] Build Flavor 配置完成
  - [ ] SSL SPKI 正确实现
  - [ ] 生物识别集成完成

🟢 Production Ready（180 天内）：
  - [ ] 测试覆盖率 >85%
  - [ ] 文档完整（Dartdoc + API 指南）
  - [ ] Play Integrity / App Attest 集成
  - [ ] 数据库加密配置
  - [ ] 网络重试/熔断完成
```

---

## 建议下一步

1. **立即开始** — test/ 目录创建 + Firebase 初始化（今天）
2. **本周完成** — Auth 特性完整实现 + 关键测试（周五）
3. **下周开始** — 其他特性 data/presentation 实现 + Security 加固

这个脚手架有 **坚实的架构基础**，但必须立即补充 **测试、功能实现和安全加固** 才能进入 Beta。
