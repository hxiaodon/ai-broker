# Mobile 测试与验收标准

**版本**: 1.0  
**发布日期**: 2026-04-10  
**适用范围**: 所有 Flutter 模块的功能验收  
**维护者**: QA / Mobile Engineering Team

---

## I. 测试层级定义

```
┌─────────────────────────────────────────┐
│  E2E 测试 (可选，生产前)                 │  
│  全流程验证 (用户场景)                   │
└──────────────┬──────────────────────────┘
               ↑
┌──────────────┴──────────────────────────┐
│  集成测试 (Integration Tests)           │
│  - 需要 Mock Server 或真实 API          │
│  - 路径: integration_test/              │
│  - 执行: flutter test integration_test/ │
└──────────────┬──────────────────────────┘
               ↑
┌──────────────┴──────────────────────────┐
│  单元测试 (Unit Tests) ⭐ 必须通过      │
│  - 无 localhost 依赖                    │
│  - 路径: test/                          │
│  - 执行: flutter test                   │
│  - 目标: All tests passed, 0 failures   │
└──────────────────────────────────────────┘
```

**关键**: 仅有 **单元测试** 可提交到 main branch。集成测试用于 CI/CD 验证。

---

## II. 单元测试标准

### A. 覆盖率目标

| 模块 | 目标 | 备注 |
|------|------|------|
| **Core (network, auth, routing)** | ≥ 80% | 关键基础设施 |
| **Repositories** | ≥ 70% | 数据层 |
| **Notifiers** | ≥ 70% | 业务逻辑 |
| **Widgets** | ≥ 50% | UI 层（可选） |

### B. 测试框架与依赖

```yaml
# pubspec.yaml (dev_dependencies)
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^6.0.0            # Mock HTTP responses, services
  riverpod: ^2.5.1           # For ProviderContainer
  fake_async: ^1.3.0         # Control time in tests
```

### C. 测试文件结构

```
test/
├── core/
│   ├── network/
│   │   ├── dio_client_test.dart
│   │   ├── auth_interceptor_test.dart
│   │   └── authenticated_dio_test.dart
│   ├── auth/
│   │   ├── token_service_test.dart
│   │   └── biometric_key_manager_test.dart
│   ├── routing/
│   │   └── app_router_redirect_test.dart
│   ├── logger/
│   │   └── app_logger_test.dart
│   └── providers/
│       └── ... (provider tests)
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository_test.dart
│   │   └── application/
│   │       └── auth_notifier_test.dart
│   ├── market/
│   │   ├── data/
│   │   │   ├── market_data_repository_test.dart
│   │   │   └── quote_websocket_client_test.dart
│   │   └── application/
│   │       ├── search_notifier_test.dart
│   │       └── watchlist_notifier_test.dart
│   └── ...
└── fixtures/
    ├── mock_responses.dart       # API 响应 fixtures
    ├── test_helpers.dart         # 共享测试工具
    └── factories.dart            # 对象工厂
```

### D. 测试代码示例模式

#### 1. Repository 测试 (Network Mocking)

```dart
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDioClient mockDio;
  late AuthRepository repository;

  setUp(() {
    mockDio = MockDioClient();
    repository = AuthRepositoryImpl(dio: mockDio);
  });

  group('AuthRepository.sendOtp', () {
    test('returns correct OTP response on success', () async {
      // Arrange
      final mockResponse = Response(
        statusCode: 200,
        data: {'message_id': 'msg-123', 'expires_in': 300},
        requestOptions: RequestOptions(path: ''),
      );
      when(mockDio.post('/auth/otp', data: any)).thenAnswer(
        (_) async => mockResponse,
      );

      // Act
      final result = await repository.sendOtp('+86 10 1234 5678');

      // Assert
      expect(result, isA<OtpResponse>());
      expect(result.messageId, equals('msg-123'));
      expect(result.expiresIn, equals(300));
    });

    test('throws OtpException on validation error', () async {
      // Arrange
      final mockError = DioException(
        type: DioExceptionType.response,
        error: 'Invalid phone',
        response: Response(
          statusCode: 400,
          data: {'error': 'INVALID_PHONE', 'message': 'Phone format invalid'},
          requestOptions: RequestOptions(path: ''),
        ),
        requestOptions: RequestOptions(path: ''),
      );
      when(mockDio.post('/auth/otp', data: any)).thenThrow(mockError);

      // Act & Assert
      expect(
        () => repository.sendOtp('invalid'),
        throwsA(isA<OtpException>()),
      );
    });
  });
}
```

#### 2. Riverpod Notifier 测试

```dart
import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchNotifier', () {
    late ProviderContainer container;
    late MockMarketRepository mockRepo;

    setUp(() {
      mockRepo = MockMarketRepository();
      container = ProviderContainer(
        overrides: [
          marketRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    test('initial state returns empty list', () {
      // Act
      final notifier = container.read(searchNotifierProvider);

      // Assert
      expect(notifier, isEmpty);
    });

    test('loads hot stocks after build', () async {
      // Arrange
      when(mockRepo.getHotStocks()).thenAnswer(
        (_) async => [
          Stock(symbol: 'AAPL', name: 'Apple Inc.'),
          Stock(symbol: 'MSFT', name: 'Microsoft Corp.'),
        ],
      );

      // Act
      await container.read(searchNotifierProvider.notifier).loadHotStocks();

      // Assert
      final state = container.read(searchNotifierProvider);
      expect(state, hasLength(2));
      expect(state.first.symbol, equals('AAPL'));
    });

    test('handles errors gracefully', () async {
      // Arrange
      when(mockRepo.getHotStocks()).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      // Act & Assert
      expect(
        () => container.read(searchNotifierProvider.notifier).loadHotStocks(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
```

#### 3. Widget 测试 (State Verification)

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginTextField', () {
    testWidgets('validates phone format', (WidgetTester tester) async {
      // Build the widget with form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginTextField(),
          ),
        ),
      );

      // Enter invalid phone
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify error message
      expect(find.text('Invalid phone format'), findsOneWidget);
    });

    testWidgets('shows clear button when text entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginTextField(),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });
}
```

### E. Mock Server 与 Fixtures

#### 启动 Mock Server

```bash
cd mobile/mock-server

# 选择策略启动
./start.sh guest                # 延迟 15 分钟数据（游客模式）
./start.sh loggedIn             # 实时数据（登录用户）
./start.sh slowNetwork          # 弱网模拟 (200ms 延迟)
./start.sh offline              # 离线模式 (所有请求返回错误)
./start.sh errorRate            # 5% 随机错误率

# 验证启动成功
curl http://localhost:8080/health
# 预期: { "status": "ok" }
```

#### API 端点清单

```
# Market Data
GET  /api/v1/stocks/{symbol}          - 获取股票详情
GET  /api/v1/stocks/search?q={query}  - 搜索股票
GET  /api/v1/watchlist                - 获取自选股
POST /api/v1/watchlist                - 添加自选股
DELETE /api/v1/watchlist/{symbol}     - 删除自选股

# WebSocket
WS   ws://localhost:8080/ws/market-data  - 实时行情流
```

#### 响应 Fixtures

```dart
// test/fixtures/mock_responses.dart

final mockStockResponse = {
  'symbol': 'AAPL',
  'name': 'Apple Inc.',
  'price': 150.25,
  'change': 2.15,
  'changePercent': 1.45,
  'timestamp': '2026-04-10T15:30:00Z',
};

final mockWatchlistResponse = {
  'stocks': [
    { 'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 150.25 },
    { 'symbol': 'MSFT', 'name': 'Microsoft', 'price': 380.50 },
  ],
};

final mockOtpResponse = {
  'message_id': 'msg-123',
  'expires_in': 300,
};
```

---

## III. 集成测试标准

### A. 集成测试范围

集成测试用于验证跨层交互，需要 Mock Server 或真实 API：

| 场景 | 文件 | 验证内容 |
|------|------|---------|
| Auth Flow | `integration_test/auth_flow_test.dart` | 登录 → OTP → Token 存储 |
| Market Data | `integration_test/market_data_test.dart` | WebSocket 连接 → 数据推送 → 缓存 |
| Watchlist | `integration_test/watchlist_loading_test.dart` | 加载 → 缓存 → 删除 |
| Guest Mode | `integration_test/guest_mode_test.dart` | 访客模式 → 延迟标识 |

### B. 集成测试执行

```bash
cd mobile/src

# 启动 Mock Server（另一个终端）
cd ../mock-server && ./start.sh loggedIn

# 运行集成测试
flutter test integration_test/

# 或指定测试文件
flutter test integration_test/auth_flow_test.dart

# 预期输出
# All tests passed! (5 passed, 0 failed)
```

### C. 集成测试代码示例

```dart
// integration_test/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:brokerage_app/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow Integration', () {
    testWidgets('complete login with OTP', (WidgetTester tester) async {
      // Launch app pointing to mock server
      await tester.binding.window.physicalSizeTestValue = Size(540, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      app.main(); // Your app main()
      await tester.pumpAndSettle();

      // Step 1: Enter phone number
      await tester.enterText(
        find.byType(TextField).at(0),
        '+86 10 1234 5678',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Step 2: Receive OTP (mock server returns it)
      expect(find.byType(OtpInputField), findsOneWidget);
      
      // Enter OTP
      await tester.enterText(find.byType(OtpInputField), '123456');
      await tester.pumpAndSettle();

      // Step 3: Verify token was stored
      // (Check via accessing shared preferences or secure storage)
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

---

## IV. 功能验收检查清单（按模块）

### Market 模块完整清单

#### 自动化验证 ✅
```bash
cd mobile/src

# 1. 静态分析
flutter analyze --no-pub
# 预期: 0 issues in lib/features/market

# 2. 单元测试
flutter test test/features/market/ --reporter=expanded
# 预期: 191 tests passed, 0 failed

# 3. Lint 检查
flutter analyze lib/features/market/
# 预期: 0 issues (or only acceptable warnings)
```

#### 功能验收（手工测试）

| # | 功能 | 步骤 | 预期结果 | 状态 |
|---|------|------|---------|------|
| 1 | 访客模式延迟标识 | 1. 启动 app 不登录<br>2. 进入行情页<br>3. 点击任意股票 | 所有价格显示"延迟 15 分钟" | [ ] |
| 2 | WebSocket 连接 | 1. 启动 app<br>2. 查看日志 | 日志显示 `WS connected` | [ ] |
| 3 | WebSocket 断线重连 | 1. 启动 mock server<br>2. 终止 WebSocket 连接<br>3. 观察重连行为 | 5 秒内自动重连 | [ ] |
| 4 | 搜索热股票 | 1. 进入搜索页<br>2. 清空搜索框 | 显示热股票列表 (AAPL, MSFT, ...) | [ ] |
| 5 | 搜索结果 | 1. 输入 "apple"<br>2. 等待结果 | 返回 AAPL 和其他匹配股票 | [ ] |
| 6 | 自选股加载 | 1. 进入自选股 tab<br>2. 观察加载 | 首次加载 API，后续从缓存 | [ ] |
| 7 | 添加自选股 | 1. 在股票详情页<br>2. 点击"加自选"按钮 | 自选股列表中出现该股票 | [ ] |
| 8 | 删除自选股 | 1. 在自选股页<br>2. 长按股票<br>3. 选择删除 | 股票从列表移除 | [ ] |
| 9 | K线图展示 | 1. 进入股票详情<br>2. 向下滚动 | K线图显示，支持放大缩小 | [ ] |
| 10 | 离线模式 | 1. 启动 mock server offline<br>2. 尝试刷新 | 显示网络错误提示 | [ ] |

**验收标准**: 所有 10 项通过

#### 性能验收

| 指标 | 目标 | 验证方法 |
|------|------|---------|
| App 启动时间 | < 3s | 使用 Android Studio / Xcode profiler |
| 行情列表滚动帧率 | ≥ 60 fps | Devtools → Performance |
| WebSocket 消息延迟 | < 500ms | 查看日志时间戳差异 |
| 内存占用 | < 100 MB | Devtools → Memory |

---

### Auth 模块完整清单

#### 自动化验证 ✅
```bash
cd mobile/src

# Unit tests
flutter test test/features/auth/ --reporter=expanded
# 预期: All tests passed
```

#### 功能验收（手工测试）

| # | 功能 | 预期结果 | 状态 |
|---|------|---------|------|
| 1 | 电话号码输入验证 | 显示格式错误提示 | [ ] |
| 2 | OTP 输入框自动移焦点 | 输入 6 位数字后自动进下一步 | [ ] |
| 3 | OTP 重试限制 | 超过 3 次后显示"请稍后重试" | [ ] |
| 4 | 生物识别注册（Phase 1） | 注册后下次启动可用生物识别登录 | [ ] |
| 5 | Token 持久化 | 重启 app 保持登录状态 | [ ] |
| 6 | Token 刷新 | 401 错误后自动刷新 token | [ ] |
| 7 | 登出 | 清空 token，返回登录页 | [ ] |

---

## V. 测试执行命令速查

### 本地开发

```bash
cd mobile/src

# 运行所有单元测试
flutter test

# 运行特定模块测试
flutter test test/features/market/

# 运行特定文件测试
flutter test test/features/market/data/market_repository_test.dart

# 生成覆盖率报告
flutter test --coverage
open coverage/lcov-report/index.html  # macOS

# 观看模式（改动时自动重新运行）
flutter test --watch
```

### 集成测试

```bash
# 启动 Mock Server（另一个终端）
cd mobile/mock-server && ./start.sh loggedIn

# 运行集成测试
cd mobile/src && flutter test integration_test/

# 运行特定集成测试
flutter test integration_test/auth_flow_test.dart
```

### CI/CD 验证

```bash
# 完整的 CI 流程
cd mobile/src
flutter analyze --no-pub              # 0 issues
flutter test                           # All passed
flutter build apk --split-per-abi     # Build successful
flutter build ios --no-codesign       # Build successful
```

---

## VI. 常见测试问题排查

### Q: 测试通过但 app 运行出错

**原因**: Mock 不完整或环境差异  
**排查**:
1. 检查 Mock 响应是否符合 API 契约
2. 运行集成测试验证真实交互：`flutter test integration_test/`
3. 检查是否有 localhost 依赖（单元测试不应依赖）

### Q: WebSocket 测试超时

**原因**: Mock Server 未启动或地址不对  
**排查**:
```bash
# 验证 Mock Server 运行
curl http://localhost:8080/health

# 检查 app 配置的 WebSocket 地址
grep -r "ws://" lib/
# 应该是 ws://localhost:8080/ws/market-data

# 重启 Mock Server
cd mobile/mock-server && ./start.sh loggedIn
```

### Q: 集成测试在 CI 环境失败，本地通过

**原因**: 环境或时序问题  
**排查**:
```bash
# 添加详细日志
flutter test integration_test/ -v

# 增加等待时间
await tester.pumpAndSettle(timeout: Duration(seconds: 5));

# 检查 Mock Server 是否在 CI 启动
# (在 CI 配置中添加 Mock Server 启动命令)
```

---

## VII. 验收流程

### 新功能完成 → 验收 → 合并

```
1. Developer 完成代码
   ├─ flutter analyze --no-pub     ✅ 0 issues
   ├─ flutter test                 ✅ All passed
   └─ 提交 PR

2. Code Reviewer 审查
   ├─ 检查 CODE_REVIEW_CHECKLIST.md 中的所有项目
   ├─ 要求补充测试（如覆盖率不足）
   └─ Approve / Request Changes

3. QA 功能验收（可选，对关键功能）
   ├─ 按本文档的功能清单验收
   ├─ 报告 bug（如有）
   └─ Sign-off

4. Merge to main
   └─ 删除 feature branch
```

---

**版本**: 1.0  
**最后更新**: 2026-04-10  
**维护者**: QA / Mobile Engineering Team  
**下次审查**: 2026-05-10
