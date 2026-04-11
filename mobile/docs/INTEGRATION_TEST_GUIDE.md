# Flutter 集成测试分类标准

## 快速参考

| | 状态管理 | API集成 | E2E |
|---|---------|--------|-----|
| 文件 | `*_state_management_test.dart` | `*_api_integration_test.dart` | `*_e2e_app_test.dart` |
| 启动app | ✅ | ❌ | ✅ |
| Mock Server | ❌ | ✅ | ✅ |
| 模拟器 | ✅ | ❌ | ✅ |
| 用户交互 | ❌ | ❌ | ✅ |
| 速度 | 很快 | 快 | 中等 |
| 何时运行 | 开发中 | 提交前 | 发布前 |

**快速命令：**
```bash
# 状态管理测试
flutter test integration_test/auth/auth_state_management_test.dart

# API集成测试（需要Mock Server）
flutter test integration_test/auth/auth_api_integration_test.dart

# E2E测试（需要Mock Server + 模拟器）
flutter test integration_test/auth/auth_e2e_app_test.dart
```

---

## 概述

本文档定义了Flutter移动应用中三种主要的测试类型，以及何时使用每种测试。

---

## 三种测试类型

### 1️⃣ 状态管理测试 (State Management Test)

**文件名约定**: `{module}_state_management_test.dart`  
**位置**: `integration_test/{module}/`  
**示例**: `auth_state_management_test.dart`

#### 职责
- 验证Riverpod providers正确工作
- 测试路由逻辑（authenticated/unauthenticated状态下的导航）
- 验证状态变化触发正确的UI更新
- 测试token storage/retrieval

#### 依赖项
- ✅ Flutter app
- ✅ Riverpod providers  
- ❌ Mock Server
- ❌ HTTP calls
- ❌ Real device/emulator

#### 速度
**很快** (~30秒 for full module)

#### 何时运行
- 开发过程中频繁运行（快速反馈）
- 每次代码提交前
- 在CI/CD的快速反馈阶段

#### 例子：Auth模块
```dart
testWidgets('T1: Unauthenticated app shows login', (tester) async {
  await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
  // Verify login screen is shown
  expect(find.byType(Scaffold), findsWidgets);
});

testWidgets('T2: Authenticated app shows home', (tester) async {
  await tester.pumpWidget(
    TestAppConfig.createAppWithAuth(
      accessToken: 'token',
      refreshToken: 'refresh',
    ),
  );
  // Verify home screen is shown, not login
});
```

---

### 2️⃣ API集成测试 (API Integration Test)

**文件名约定**: `{module}_api_integration_test.dart`  
**位置**: `integration_test/{module}/`  
**示例**: `auth_api_integration_test.dart`

#### 职责
- 测试HTTP API层与Mock Server的交互
- 验证request/response格式正确
- 测试错误处理（错误代码、timeout等）
- 验证API业务逻辑（OTP倒计时、账户锁定等）

#### 依赖项
- ✅ Mock Server (localhost:8080)
- ✅ Dio HTTP client
- ❌ Flutter app UI
- ❌ Real device/emulator
- ❌ Riverpod state management

#### 速度
**快** (~8秒 for full module)

#### 何时运行
- 提交前（快速API验证）
- 在CI/CD管道中
- Mock Server宕机时**不能运行**

#### 例子：Auth模块
```dart
testWidgets('E1: Complete OTP login flow', (tester) async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  
  // Send OTP
  final sendResponse = await dio.post('/v1/auth/otp/send', data: {
    'phone_number': '+8613812345678',
  });
  expect(sendResponse.statusCode, 200);
  
  // Verify OTP
  final verifyResponse = await dio.post('/v1/auth/otp/verify', data: {
    'phone_number': '+8613812345678',
    'otp': '123456',
  });
  expect(verifyResponse.statusCode, 200);
  expect(verifyResponse.data['access_token'], isNotEmpty);
});
```

---

### 3️⃣ 端到端测试 (E2E / End-to-End Test)

**文件名约定**: `{module}_e2e_app_test.dart` 或 `{module}_e2e_test.dart`  
**位置**: `integration_test/{module}/`  
**示例**: `auth_e2e_app_test.dart`

#### 职责
- 模拟真实用户从UI操作到应用响应的完整流程
- 验证UI正确响应用户交互（输入、点击）
- 验证应用正确调用后端API
- 验证应用根据API响应更新UI和状态
- 验证导航流程正确

#### 依赖项
- ✅ Real device/emulator
- ✅ Flutter app (fully launched)
- ✅ Mock Server (localhost:8080)
- ✅ Riverpod state management
- ✅ Routing

#### 速度
**中等** (~15-30秒 per journey)

#### 何时运行
- 发布前完整验证
- 在CI/CD的完整测试阶段
- 关键用户流程验证

#### 例子：Auth模块
```dart
testWidgets('Journey 1: User OTP login flow', (tester) async {
  // 1. App launches → shows login screen
  await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
  await tester.pump(const Duration(seconds: 2));
  
  // 2. User enters phone number
  final phoneInputs = find.byType(TextField);
  if (phoneInputs.evaluate().isNotEmpty) {
    await tester.tap(phoneInputs.first);
    await tester.pump();
    await tester.enterText(phoneInputs.first, '13812345678');
    await tester.pump();
  }
  
  // 3. User sends OTP
  final sendButtons = find.byType(ElevatedButton);
  if (sendButtons.evaluate().isNotEmpty) {
    await tester.tap(sendButtons.first);
    await tester.pump(const Duration(seconds: 3));
  }
  
  // 4. App calls Mock Server, navigates to OTP screen
  // 5. User enters OTP code
  // 6. User verifies OTP
  // 7. App navigates to home screen
  
  expect(find.byType(Scaffold), findsWidgets);
});
```

---

## 对比表

| 方面 | 状态管理测试 | API集成测试 | E2E测试 |
|------|-----------|----------|--------|
| **文件名** | `{module}_state_management_test.dart` | `{module}_api_integration_test.dart` | `{module}_e2e_app_test.dart` |
| **依赖 Mock Server** | ❌ No | ✅ Yes | ✅ Yes |
| **启动 Flutter app** | ✅ Yes | ❌ No | ✅ Yes |
| **模拟用户交互** | ❌ No | ❌ No | ✅ Yes |
| **验证UI更新** | ✅ Yes | ❌ No | ✅ Yes |
| **验证HTTP API** | ❌ No | ✅ Yes | ✅ Yes (indirect) |
| **验证路由** | ✅ Yes | ❌ No | ✅ Yes |
| **需要真机/模拟器** | ✅ Yes | ❌ No | ✅ Yes |
| **速度** | 很快 | 快 | 中等 |
| **何时运行** | 开发中频繁 | 提交前 | 发布前 |
| **总测试时间** | ~30s | ~8s | ~15-30s per journey |

---

## 为不同模块设置测试

### 示例：Market模块

```
integration_test/market/
├── market_state_management_test.dart      # 状态管理（无需Mock Server）
├── market_api_integration_test.dart       # API层（需要Mock Server）
├── market_e2e_app_test.dart              # 完整用户流程（需要模拟器+Mock Server）
├── helpers/
│   └── test_app.dart
└── README.md
```

### 示例：Trading模块

```
integration_test/trading/
├── trading_state_management_test.dart
├── trading_api_integration_test.dart
├── trading_e2e_app_test.dart
├── helpers/
│   └── test_app.dart
└── README.md
```

---

## 在CI/CD中的应用

### 快速反馈阶段（Pull Request）
- ✅ 运行所有状态管理测试 (`*_state_management_test.dart`)
- ✅ 运行所有API集成测试 (`*_api_integration_test.dart`)
- ❌ 不运行E2E测试（太慢）

**预期时间**: 1-2分钟

### 完整测试阶段（发布前）
- ✅ 运行所有状态管理测试
- ✅ 运行所有API集成测试
- ✅ 运行所有E2E测试

**预期时间**: 5-10分钟

---

## 开发工作流程

### 开发新feature
```bash
# 1. 编写测试
# 2. 运行状态管理测试（快速反馈）
flutter test integration_test/market/market_state_management_test.dart

# 3. 实现feature
# 4. 运行API集成测试
flutter test integration_test/market/market_api_integration_test.dart

# 5. 测试完整流程
# 6. 运行E2E测试
flutter test integration_test/market/market_e2e_app_test.dart

# 7. 提交PR（CI/CD会运行前两个）
```

### 提交前检查
```bash
# 快速反馈
flutter test integration_test/auth/

# 或仅运行API测试
flutter test integration_test/auth/auth_api_integration_test.dart
```

### 发布前检查
```bash
# 完整测试所有模块
flutter test integration_test/
```

---

## 常见陷阱

### ❌ 不要在状态管理测试中测试HTTP
```dart
// 错误做法
testWidgets('T1: Send OTP', (tester) async {
  await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
  
  // 这会尝试调用真实Mock Server，不属于状态管理测试
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'));
  final response = await dio.post('/v1/auth/otp/send', ...);
});
```

### ❌ 不要在API测试中启动完整的app
```dart
// 错误做法
testWidgets('E1: OTP send', (tester) async {
  // 这会启动完整app，浪费时间，属于E2E测试的职责
  await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
  
  // 然后再测试HTTP...
  final dio = Dio(...);
  await dio.post('/v1/auth/otp/send', ...);
});
```

### ❌ 不要在一个test中多次pumpWidget
```dart
// 错误做法
testWidgets('E2E flow', (tester) async {
  // First state
  await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
  
  // Try to change state
  await tester.pumpWidget(TestAppConfig.createAppWithAuth(...));
  // ❌ This will cause Riverpod provider override conflicts
});
```

✅ 正确做法：**每个test是一个独立的应用实例**

---

## 文件模板

### 新模块应包含的文件

```
integration_test/{module}/
├── {module}_state_management_test.dart    # 必要：验证状态管理
├── {module}_api_integration_test.dart     # 必要：验证API
├── {module}_e2e_app_test.dart            # 必要：验证完整流程
├── helpers/
│   └── test_app.dart                      # 可共享
└── README.md                              # 文档
```

每个模块都应该有这三种测试类型。
