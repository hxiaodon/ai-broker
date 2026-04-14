# 全局错误处理系统设计

**Status**: 待实施  
**优先级**: P2（质量提升）  
**工作量估算**: 1周  

---

## 问题陈述

### 当前状态
- ❌ 错误处理分散在各个 `.when()` 中
- ❌ 未捕获的异常可能导致应用崩溃（黑屏）
- ❌ 生产环境错误无法追踪
- ❌ 用户无法报告问题
- ❌ 没有错误聚合和模式识别

### 业界最佳实践（对标 Immich）
- Sentry 集成（实时错误上报）
- 全局错误边界
- 用户反馈系统
- 错误去重（同一错误只报告一次）
- 离线模式下的本地日志存储

---

## 架构设计

### 1. 错误分类体系

```dart
// 按严重程度分类
enum ErrorSeverity {
  info,     // 信息性，无需上报
  warning,  // 警告，发送诊断信息
  error,    // 错误，需要上报，应用可继续
  critical, // 严重，应用可能需要重启
}

// 按业务类型分类
enum ErrorCategory {
  network,      // 网络错误（DNS、连接超时）
  auth,         // 认证错误（token 过期、登录失败）
  validation,   // 验证错误（输入不合法）
  business,     // 业务逻辑错误（余额不足、限额超出）
  database,     // 本地数据库错误
  platform,     // 平台错误（摄像头不可用、权限拒绝）
  unknown,      // 未知错误
}

// 扩展 AppException
abstract class AppException implements Exception {
  final String message;
  final String? errorCode;
  final Object? cause;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final ErrorCategory category;

  AppException({
    required this.message,
    this.errorCode,
    this.cause,
    this.stackTrace,
    required this.severity,
    required this.category,
  });

  // 用户可见的错误消息（中文、非技术细节）
  String get userFriendlyMessage;

  // Sentry fingerprint（用于去重）
  List<String> get sentryFingerprint => [category.name, errorCode ?? 'unknown'];
}
```

### 2. 全局错误处理器

```dart
class GlobalErrorHandler {
  static final _instance = GlobalErrorHandler._();

  factory GlobalErrorHandler() => _instance;

  GlobalErrorHandler._();

  static Future<void> init({
    required String sentryDsn,
    required String environment,
  }) async {
    // 1. 初始化 Sentry
    await Sentry.init(
      sentryDsn,
      dsn: sentryDsn,
      environment: environment,
      tracesSampleRate: environment == 'production' ? 0.1 : 1.0,
      beforeSend: _beforeSendToSentry,
      integrations: [
        HttpClientIntegration(),
        LoggingIntegration(),
        NativeIntegration(),
      ],
    );

    // 2. 捕获 Flutter 框架错误
    FlutterError.onError = _handleFlutterError;

    // 3. 捕获异步错误
    PlatformDispatcher.instance.onError = _handlePlatformError;

    // 4. 初始化本地日志存储
    await _initLocalLogging();
  }

  static void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? userMessage,
  }) {
    // 确定严重程度
    final severity = _getSeverity(error);

    if (severity == ErrorSeverity.info) {
      // 仅本地记录
      _logLocally(error, stackTrace, severity);
      return;
    }

    // 记录到本地
    _logLocally(error, stackTrace, severity);

    // 上报到 Sentry
    if (severity.index >= ErrorSeverity.error.index) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'user_message': userMessage,
          'device_id': _getDeviceId(),
          'user_id': _getCurrentUserId(),
        }),
      );
    }
  }

  static SentryEvent? _beforeSendToSentry(SentryEvent event, Hint hint) {
    // 1. 过滤敏感信息
    event.request?.headers?.remove('Authorization');
    
    // 2. 添加设备信息
    event.contexts['app'] = AppContext(
      version: _getAppVersion(),
      build: _getAppBuild(),
    );

    // 3. 去重检查（避免重复上报同一错误）
    if (_isDuplicate(event)) {
      return null; // 丢弃重复错误
    }

    return event;
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    reportError(
      details.exception,
      stackTrace: details.stack,
      userMessage: '应用发生错误，我们已记录此问题',
    );

    // 继续默认处理（显示红色错误框等）
    // FlutterError.presentError(details);
  }

  static bool Function(Object error, StackTrace stack) _handlePlatformError =
      (error, stack) {
    reportError(error, stackTrace: stack);
    return true; // 已处理
  };

  static ErrorSeverity _getSeverity(Object error) {
    if (error is NetworkException) {
      // 网络错误通常是 warning
      return ErrorSeverity.warning;
    } else if (error is AuthException) {
      // 认证错误是 error
      return ErrorSeverity.error;
    } else if (error is BusinessException) {
      // 业务错误是 warning（用户输入错误）
      return ErrorSeverity.warning;
    } else {
      // 未知错误是 critical
      return ErrorSeverity.critical;
    }
  }

  static Future<void> _initLocalLogging() async {
    // 使用 path_provider 获取应用文档目录
    final docDir = await getApplicationDocumentsDirectory();
    final logDir = Directory('${docDir.path}/logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    // 配置日志输出
    final logFile = File('${logDir.path}/error_${_getTodayDate()}.log');
    _logFile = logFile;
  }

  static void _logLocally(
    Object error,
    StackTrace? stack,
    ErrorSeverity severity,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = [
      '[$timestamp] [$severity] $error',
      if (stack != null) stack.toString(),
      '',
    ].join('\n');

    _logFile?.writeAsStringSync(
      logEntry,
      mode: FileMode.append,
    );

    // 同时输出到控制台
    debugPrint(logEntry);
  }

  static bool _isDuplicate(SentryEvent event) {
    // 检查最近 1 小时内是否有相同的错误
    // 使用 sentryFingerprint 进行比较
    // 实现可以用简单的内存缓存或数据库查询
    return false; // TODO: 实现重复检测
  }

  static String _getDeviceId() {
    // 使用 device_info_plus 获取设备 ID
    return 'device_${uuid.v4()}';
  }

  static String? _getCurrentUserId() {
    // 从 auth provider 获取当前用户 ID
    return null; // TODO: 集成 Riverpod
  }

  static String _getAppVersion() {
    // 使用 package_info_plus 获取应用版本
    return '1.0.0'; // TODO: 动态获取
  }

  static String _getAppBuild() {
    // 获取应用 build 号
    return '1'; // TODO: 动态获取
  }

  static String _getTodayDate() {
    return DateTime.now().toIso8601String().split('T').first;
  }

  static File? _logFile;
}
```

### 3. 用户反馈流程

```dart
class UserFeedbackDialog extends StatefulWidget {
  final Object error;
  final String? defaultMessage;

  const UserFeedbackDialog({
    required this.error,
    this.defaultMessage,
  });

  @override
  State<UserFeedbackDialog> createState() => _UserFeedbackDialogState();
}

class _UserFeedbackDialogState extends State<UserFeedbackDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultMessage ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('帮助我们改进'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('遇到问题了？告诉我们发生了什么。'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '请描述您遇到的问题...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => _submitFeedback(),
          child: const Text('提交'),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    // 构建用户反馈
    final feedback = SentryUserFeedback(
      eventId: Sentry.lastEventId,
      name: '用户',
      email: 'user@example.com', // 可选，从登录信息获取
      comments: _controller.text,
    );

    // 上报反馈
    await Sentry.captureUserFeedback(feedback);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('感谢您的反馈')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 4. 集成到 main.dart

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化全局错误处理
  await GlobalErrorHandler.init(
    sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
    environment: const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development'),
  );

  // 初始化其他模块...

  runApp(
    SentryWidget(
      child: ProviderScope(
        observers: [RiverpodObserver()],
        child: const MyApp(),
      ),
    ),
  );
}
```

### 5. 错误边界组件

```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object, StackTrace)? onError;

  const ErrorBoundary({
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错误')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('应用发生错误'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('重新加载'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showFeedback,
                child: const Text('报告问题'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  void _reset() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  void _showFeedback() {
    showDialog(
      context: context,
      builder: (_) => UserFeedbackDialog(error: _error!),
    );
  }
}
```

---

## 集成检查清单

### 依赖包
- [ ] `sentry_flutter: ^7.0.0`
- [ ] `sentry: ^7.0.0`
- [ ] `package_info_plus`
- [ ] `device_info_plus`
- [ ] `path_provider`
- [ ] `uuid`

### 初始化
- [ ] Sentry DSN 配置（从环境变量或 Firebase Remote Config）
- [ ] 错误处理器注册
- [ ] 本地日志存储初始化
- [ ] Flutter 错误捕获
- [ ] Platform 错误捕获

### 测试
- [ ] 手动测试错误捕获（触发各类异常）
- [ ] Sentry Dashboard 验证上报
- [ ] 去重功能测试
- [ ] 用户反馈流程测试
- [ ] 离线日志存储验证

### 文档
- [ ] Sentry 账户和项目设置
- [ ] 错误分类指南
- [ ] 开发者如何使用 GlobalErrorHandler
- [ ] 生产环境监控清单

---

## Sentry 配置示例

### 开发环境
```yaml
# 所有错误都上报（100% sample rate）
environment: development
traces_sample_rate: 1.0
max_breadcrumbs: 100
```

### 生产环境
```yaml
# 采样 10%（减少成本和噪音）
environment: production
traces_sample_rate: 0.1
max_breadcrumbs: 50
# 启用 replay（用户会话录制）
session_sample_rate: 0.1
```

---

## 监控面板设置

### Sentry Dashboard
1. **错误聚合** — 按 errorCode 分组
2. **趋势** — 24h 错误数量变化
3. **优先级** — 按严重程度排序
4. **用户影响** — 有多少用户受到影响
5. **告警规则**:
   - 相同错误 > 10 次 / 小时 → Slack 通知
   - 严重级别错误 → 立即通知

---

## 预期收益

| 收益 | 描述 |
|------|------|
| **可见性** | 生产环境中所有错误都有记录和追踪 |
| **快速响应** | 关键问题在 Sentry Dashboard 中立即显示 |
| **根因分析** | breadcrumbs 和 context 帮助快速定位问题 |
| **用户反馈** | 用户可以直接关联反馈和错误 |
| **数据驱动** | 优先修复影响最多用户的问题 |

---

## 参考资源

- Sentry Flutter 文档: https://docs.sentry.io/platforms/flutter/
- Sentry Release Tracking: https://docs.sentry.io/product/releases/
- Best Practices: https://docs.sentry.io/product/best-practices/

---

**所有者**: Mobile Engineer / DevOps  
**完成日期**: TBD  
**验收标准**: Sentry 集成完成，所有错误均可在 Dashboard 中查看，用户反馈流程可用
