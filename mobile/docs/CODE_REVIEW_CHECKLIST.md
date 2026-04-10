# Mobile Code Review 完整检查清单

**版本**: 1.0  
**适用范围**: 所有 Flutter/Dart 代码更改  
**维护者**: Mobile 工程师团队  
**最后更新**: 2026-04-10

> 本清单基于历史审查经验和已识别的关键问题汇总。所有代码变更必须通过相关检查项才能合并。

---

## Part 1: 财务计算与数据精度

### ✅ 货币类型

- [ ] **所有金钱计算使用 `Decimal`** (from `package:decimal`)
  - ❌ 不允许：`double`, `num`, `int` 用于货币运算
  - ✅ 正确：`Decimal.parse('150.25')` 或 `Decimal.fromInt(15025) / Decimal.fromInt(100)`
- [ ] 金额显示时使用正确的精度
  - 美股：4 位小数（价格）/ 整数（数量）
  - 港股：3 位小数（价格）/ 整数（数量）
  - 佣金/费用：2 位小数（半进位）
- [ ] 所有 Decimal 操作指定了舍入模式
  - ✅ 正确：`amount.toDecimal(scaleOnInfinitePrecision: 2)`
  - ❌ 不允许：隐式舍入

### ✅ 时间处理

- [ ] **所有时间戳存储为 UTC**
  - ❌ 不允许：`DateTime.now()` 没有转换
  - ✅ 正确：`DateTime.now().toUtc()` 或 `DateTime.utc(...)`
- [ ] API 响应中的时间戳为 ISO 8601 格式
  - ✅ 示例：`2026-04-10T15:30:00Z`
- [ ] 时区转换仅在显示层进行
  - ✅ 应该在：`lib/core/presentation/formatters.dart`
  - ❌ 不应该在：业务逻辑、网络层、数据模型

---

## Part 2: 网络与错误处理

### ✅ HTTP 客户端设置

- [ ] 使用正确注入的 `DioClient` 实例
  - ✅ 正确：`DioClient.create()` 接收 token 回调
  - ❌ 不正确：直接 `Dio()` 创建或 static 全局实例
- [ ] `AuthInterceptor` 通过依赖注入获得 token 回调
  - ✅ 检查：`auth_interceptor.dart` 中的回调参数
  - ❌ 不允许：直接访问 `TokenService`
- [ ] 所有 HTTP 请求自动带上 `X-Request-ID` (Correlation ID)
  - ✅ 验证：日志中应该有 `[uuid]` 前缀

### ✅ 错误映射与传播

- [ ] **网络错误映射在 Remote Data Source 中进行** (不在 Interceptor)
  - ❌ 删除：`ErrorInterceptor`（已被证明会双重处理）
  - ✅ 位置：`lib/features/{module}/data/{feature}_remote_data_source.dart`
- [ ] `DioException` 映射到 domain exception 时保留上下文
  - ✅ 例如 OTP 错误：包含 `remainingAttempts`, `retryAfter`
  - ❌ 不允许：抛出通用异常，丢失错误细节
- [ ] 所有异常包装时添加上下文信息
  - ✅ 正确：`throw OtpException('OTP validation failed', error: e, remainingAttempts: 2)`
  - ❌ 不正确：`throw e` 或 `return null`
- [ ] 生产代码中不吞咽异常
  - ❌ 不允许：`catch (e) { }` 空处理
  - ✅ 允许：`catch (e) { rethrow; }` 或映射到 domain exception

### ✅ 超时保护

- [ ] HTTP 请求配置了合理的超时时间
  - ✅ 建议：connectTimeout 15s, receiveTimeout 30s, sendTimeout 30s
- [ ] WebSocket 连接有 timeout 保护
  - ✅ 检查：`await _channel!.ready.timeout(Duration(seconds: 10))`
  - ❌ 不允许：无限等待 ready future

---

## Part 3: 身份认证与安全

### ✅ Token 管理

- [ ] Token 存储在 `flutter_secure_storage` 中
  - ✅ 配置：`iOptions: IOSOptions(accessibility: kSecAttrAccessibleThisDeviceOnly)`
  - ❌ 不允许：SharedPreferences, 明文文件
- [ ] Token 刷新逻辑在 `AuthInterceptor` 中实现
  - ✅ 流程：检测 401 → 触发 token 刷新 → 重试原请求
- [ ] Refresh token 存储在 HttpOnly secure cookie 中（如果使用 API）
  - ✅ 验证：服务端配置 Set-Cookie: HttpOnly, Secure, SameSite=Strict

### ✅ 生物识别认证

- [ ] 生物识别功能仅用于本地设备解锁（Phase 1）
  - ⚠️ 当前：`biometric_key_manager.dart` 返回 stub 签名
  - 📅 Phase 2：集成 iOS Secure Enclave + Android Keystore
- [ ] 生物识别变化时重新认证用户
  - ✅ 检查：`canCheckBiometrics` 状态变化监听
- [ ] 敏感操作（订单提交、提取资金）要求生物识别
  - ✅ 必须：本地 auth 通过后再调用 API

### ✅ 数据加密

- [ ] PII 字段在日志中掩码
  - ✅ 使用 `AppLogger.mask()` 工具函数
  - ❌ 不允许记录：SSN, HKID, Token, Password, Full bank account
- [ ] 敏感缓存数据加密存储
  - ✅ 使用 `encrypt` 包 (AES-256)
  - ❌ 不允许：明文缓存 token, SSN, 账户信息

---

## Part 4: 状态管理（Riverpod）

### ✅ Provider 设计

- [ ] Provider 在 `build()` 中返回稳定的初始状态
  - ❌ 不允许：async 初始化在 `build()` 内
  - ✅ 正确：返回同步初始值，异步加载在单独方法
- [ ] 所有 `@riverpod` providers 有单元测试
  - ✅ 覆盖：成功路径 + 错误路径 + 状态转换
- [ ] 异步操作使用 `AsyncValue<T>` 状态管理
  - ✅ 模式：`.when(loading: ..., error: ..., data: ...)`
  - ❌ 不允许：`?.let()` 链或 null-coalescing 隐藏加载状态

### ✅ 缓存与重试

- [ ] 网络请求配置了合理的重试策略
  - ✅ 建议：连接错误/超时重试 3 次，业务错误不重试
- [ ] 缓存 invalidation 策略清晰
  - ✅ 记录：哪些操作触发哪些 provider 的 invalidate
  - ❌ 不允许：随意 `ref.refresh()` 导致级联刷新

---

## Part 5: 日志与可观测性

### ✅ 日志记录

- [ ] 使用 `AppLogger` (结构化日志)，不用 `print()`
  - ❌ 不允许：`print()`, `debugPrint()` 在生产代码中
  - ✅ 允许：测试代码中的 `print()`（会在 lint 中标记，但可接受）
- [ ] 所有请求/响应日志包含 Correlation ID
  - ✅ 格式：`HTTP Request [uuid-xxx]: GET /api/...`
- [ ] 错误日志包含完整的堆栈信息
  - ✅ 正确：`AppLogger.error('msg', error: e, stackTrace: st)`
  - ❌ 不正确：`AppLogger.error('msg')` 没有异常对象
- [ ] 敏感信息掩码
  - ❌ 不记录：passwords, tokens, SSN, full bank account
  - ✅ 掩码：last 4 digits, first letter only, 等

### ✅ 监控与指标

- [ ] WebSocket 连接状态变化有日志
  - ✅ 记录：connected, disconnected, reconnecting, reconnected
- [ ] 网络错误有分类日志
  - ✅ 区分：connection error, timeout, 400s, 500s
- [ ] 重要业务操作有审计日志
  - ✅ 记录：order submission, fund withdrawal, 等
  - 📋 格式：timestamp, actor_id, action, resource_id, status

---

## Part 6: 测试覆盖

### ✅ 单元测试

- [ ] 修改的函数/类有相应的单元测试
  - ✅ 覆盖：happy path + error cases
  - 📊 目标：70% 代码覆盖率
- [ ] 所有公开 API (repositories, notifiers) 有集成测试
  - ✅ 包括：正常流程 + 网络故障 + 业务错误

### ✅ 集成测试

- [ ] 端到端流程有集成测试（放在 `integration_test/`）
  - ✅ 例如：Auth flow, Market data streaming
- [ ] Mock Server 提供了测试所需的策略
  - ✅ 如需新策略：更新 `mobile/mock-server/`

### ✅ 测试质量

- [ ] 测试代码清晰，变量名有意义
- [ ] 使用 test fixtures / factories 避免重复代码
- [ ] 异步操作有明确的等待条件（不是固定 sleep）
  - ✅ 正确：`await tester.pumpAndSettle()`
  - ❌ 不正确：`await Future.delayed(Duration(seconds: 1))`

---

## Part 7: 代码质量

### ✅ 代码风格

- [ ] 遵循 Dart 官方规范 (`flutter analyze --no-pub` 通过)
  - ✅ 0 issues 在 lib 代码中
  - ⚠️ 接受：测试代码中的 `print` 警告
- [ ] 命名约定清晰
  - ✅ 类：PascalCase
  - ✅ 函数/变量：camelCase
  - ✅ 常量：lowerCamelCase (no `const` prefix)
- [ ] 无死代码或未使用的导入
  - ✅ 检查：`flutter analyze` 报告

### ✅ 复杂度

- [ ] 函数/方法行数 < 50 行（复杂逻辑分拆）
- [ ] Widget 类嵌套深度 < 5 层
  - 💡 提示：使用 `_buildXxx()` 私有方法分拆 UI
- [ ] 条件嵌套深度 < 3 层
  - 💡 提示：提前返回 (early return) 或提取方法

### ✅ 依赖管理

- [ ] 新依赖在 `pubspec.yaml` 中版本锁定
  - ✅ 使用 `^` 允许兼容升级
  - ❌ 避免：`*` 或无版本约束
- [ ] 大的新依赖有文档说明为什么引入
  - ✅ 例如：`# Added for real-time market data streaming`

---

## Part 8: 功能特性检查

### ✅ 行情模块（Market）

- [ ] 访客模式下显示"延迟 15 分钟"标识
  - ✅ 位置：价格旁边，灰色小字
  - ✅ 范围：列表 + 详情页 + K线图
- [ ] WebSocket 连接断线自动重连
  - ✅ 检查：重连间隔从 1s 开始，指数退避，max 60s
  - ✅ 日志：应该能看到 reconnecting → reconnected
- [ ] 搜索功能返回热股票列表和输入匹配结果
  - ✅ 排序：热股票优先，然后按拼音/英文首字母
- [ ] 自选股支持加载和本地缓存
  - ✅ 缓存：使用 Hive 或 SharedPreferences
  - ✅ 过期：>= 5 分钟时重新加载

### ✅ 认证模块（Auth）

- [ ] 登录流程：输入验证 → 请求 → OTP
  - ✅ 电话号码格式验证
  - ✅ OTP 输入框自动移焦点
- [ ] OTP 重试逻辑
  - ✅ 显示剩余尝试次数
  - ✅ 超过限制后禁用输入
- [ ] 生物识别注册后能登出
  - ✅ 重新启动应该回到登录页

### ✅ 路由与导航

- [ ] 未登录用户无法访问受保护的页面
  - ✅ 尝试深链接到 /market 应该跳转到 /login
- [ ] 登出后路由栈被清空
  - ✅ 不能返回历史页面

---

## Part 9: 性能检查

### ⚡ 列表与滚动

- [ ] 大列表使用 `ListView.builder` (不是 `Column` 包含列表)
- [ ] Item widget 使用 `const` 构造函数避免重建
- [ ] Image 加载使用缓存 (`cached_network_image` or similar)

### ⚡ 网络性能

- [ ] 不重复发送相同请求
  - ✅ 使用 Riverpod 缓存或防抖
- [ ] 大数据响应使用流式加载或分页
  - ✅ 股票列表：一次加载 20-50 条

### ⚡ 包大小

- [ ] 新资源（图片、字体）已优化
  - ✅ 图片：压缩、使用 WebP 格式
  - ✅ 字体：仅包含必要的语言/符号

---

## Part 10: 提交前检查清单

### 🔧 本地验证

```bash
# 1. 静态分析
cd mobile/src
flutter analyze --no-pub
# 预期：0 issues in lib code

# 2. 格式化
dart format lib/ test/ integration_test/
# 预期：未改变（或已格式化）

# 3. 单元测试
flutter test
# 预期：All tests passed

# 4. 构建验证
flutter build apk --split-per-abi --release  # Android
flutter build ios --release --no-codesign   # iOS
# 预期：Build successful
```

### 📝 提交信息格式

```
feat(market): add websocket reconnection with exponential backoff

- Add TimeoutException for connection ready timeout
- Implement exponential backoff: 1s → 60s
- Log connection state changes with correlation ID
- Add integration test for reconnection scenario

Fixes #123
```

**格式规则**
- 类型：`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`
- 作用域：module name (auth, market, fund, etc)
- 描述：imperative mood, 小写
- Body：为什么和如何，不是什么

### ✅ Push 前确认

- [ ] 所有本地检查通过（见上）
- [ ] Commit message 清晰准确
- [ ] 没有 secrets / credentials 提交
- [ ] 变更文件符合预期（检查 `git diff --stat`）
- [ ] 如有 `mobile/temp/` 文件变更，确认是否需要归档

---

## Appendix A: 常见 Issue 修复

### Issue: Token 刷新后原请求仍然失败

**根因**: AuthInterceptor 回调为 null  
**检查点**:
```dart
// ❌ 不对
final authInterceptor = AuthInterceptor(null, null);

// ✅ 正确
final authInterceptor = AuthInterceptor(
  onRefreshToken: () => tokenService.refreshToken(),
  onGetToken: () => tokenService.getToken(),
);
```

### Issue: WebSocket 连接后收不到消息

**根因**: 消息处理在错误的地方，或订阅逻辑有问题  
**检查点**:
```dart
// 检查 listen() 是否在 ready 后调用
_channel = _channelFactory(...);
await _channel!.ready.timeout(...);
_channel!.stream.listen((message) { ... }); // 在这里
```

### Issue: 搜索结果为空但列表应该有数据

**根因**: `SearchNotifier.build()` 中的 async 初始化导致状态未准备好  
**检查点**:
```dart
// ❌ 不对
@riverpod
Future<List<Stock>> searchResults(SearchResultsRef ref) async {
  await _loadHotStocks(); // 在 build 中不要做这个
  return [];
}

// ✅ 正确
@riverpod
class SearchResults extends _$SearchResults {
  @override
  List<Stock> build() {
    _loadHotStocks(); // 触发异步，不等待
    return []; // 返回初始状态
  }
  
  Future<void> _loadHotStocks() async { ... }
}
```

### Issue: 单元测试在 main branch 通过，但在本地失败

**根因**: localhost 依赖或 flutter_test binding 问题  
**检查点**:
```bash
# 确保测试不依赖 localhost
grep -r "localhost" test/
# 预期：无结果（localhost 测试应该在 integration_test/）

# 检查 pubspec.yaml 中的 flutter_test 导入
grep -r "flutter_test" test/features/
# 预期：仅在 test_helpers.dart 等共享代码中
```

---

**Version**: 1.0  
**Last Updated**: 2026-04-10  
**Maintainer**: Mobile Engineering Team  
**Next Review**: 2026-05-10
