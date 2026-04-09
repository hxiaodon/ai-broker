# Mobile 可观测性改进计划

## 背景

基于访问链路和故障定位审查，发现 20 个影响生产环境问题排查的缺陷。本文档提供完整的修复计划。

## 问题分类

- **HIGH 严重度**: 5 个 - 影响故障定位的关键问题
- **MEDIUM 中等**: 10 个 - 影响调试效率的问题  
- **LOW 较低**: 5 个 - 改进日志质量的问题

---

## Phase 1: 关键基础设施（HIGH 优先级）

### 1.1 添加请求关联 ID (Correlation ID)

**文件**: `lib/core/network/dio_client.dart`

**问题**: 所有 HTTP 请求缺少唯一标识，无法关联客户端和服务端日志

**修复方案**:
```dart
import 'package:uuid/uuid.dart';

class DioClient {
  static const _uuid = Uuid();
  
  static Dio create({required String baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    // Add request ID interceptor FIRST
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final requestId = _uuid.v4();
        options.headers['X-Request-ID'] = requestId;
        AppLogger.debug('HTTP Request [$requestId]: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final requestId = response.requestOptions.headers['X-Request-ID'];
        AppLogger.debug('HTTP Response [$requestId]: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (error, handler) {
        final requestId = error.requestOptions.headers['X-Request-ID'];
        AppLogger.warning('HTTP Error [$requestId]: ${error.type}');
        return handler.next(error);
      },
    ));

    // Then add other interceptors...
    return dio;
  }
}
```

**依赖**: 需要在 `pubspec.yaml` 添加 `uuid: ^4.0.0`

**验证**: 检查日志中所有请求都有 `[uuid]` 前缀

---

### 1.2 WebSocket 连接 ready 添加超时

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**问题**: `await _channel!.ready` 无超时，弱网下可能无限挂起

**修复方案**:
```dart
// Line 129-136
try {
  _channel = _channelFactory(
    Uri.parse(_wsUrl),
    protocols: const ['brokerage-market-v1'],
  );
  
  // Add timeout to ready future
  await _channel!.ready.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      throw TimeoutException('WebSocket connection timeout after 10s');
    },
  );
  
  AppLogger.info('WS connection established to $_wsUrl');
} catch (e) {
  AppLogger.error('WS connection failed', error: e);
  _cleanup();
  rethrow;
}
```

**验证**: 在飞行模式下连接 WS，应在 10 秒后超时而非无限挂起

---

### 1.3 Protobuf 帧解析失败传播到 stream

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**问题**: Protobuf 解析失败只记录 warning，不通知 UI

**修复方案**:
```dart
// Line 291-314
void _handleBinaryFrame(Uint8List bytes) {
  try {
    final frame = proto.WsQuoteFrame.fromBuffer(bytes);
    _frameCount++;
    
    // ... existing logic
    
  } catch (e, stack) {
    AppLogger.error(
      'WS: failed to decode Protobuf binary frame (total frames: $_frameCount)',
      error: e,
      stackTrace: stack,
    );
    
    // Propagate error to stream so UI can show warning
    _quoteController.addError(
      DataException(
        message: 'Failed to parse market data frame',
        cause: e,
      ),
    );
  }
}

// Add frame counter as class field
int _frameCount = 0;
```

**验证**: 模拟发送错误的 Protobuf 数据，UI 应显示错误提示

---

### 1.4 改进 WebSocket 断连原因跟踪

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**问题**: `_onDone()` 无法区分主动关闭 vs 网络异常

**修复方案**:
```dart
// Add field to track close reason
String? _closeReason;

// Line 376-384
void _onDone() {
  final code = _channel?.closeCode;
  final reason = _closeReason ?? 'unknown';
  
  AppLogger.info('WS connection done: code=$code, reason=$reason, state=$_state');

  if (_state != _WsState.closed) {
    final exception = _mapCloseCode(code);
    AppLogger.warning('WS unexpected disconnect: $exception');
    _quoteController.addError(exception);
    _cleanup();
  } else {
    AppLogger.debug('WS graceful close');
  }
  
  _closeReason = null;
}

// Update close() method to set reason
Future<void> close() async {
  if (_state == _WsState.closed) return;
  
  _closeReason = 'user_initiated';
  _state = _WsState.closed;
  
  // ... existing close logic
}

// Update _cleanup() to set reason if not already set
void _cleanup() {
  _closeReason ??= 'error_or_network_failure';
  // ... existing cleanup logic
}
```

**验证**: 检查日志，主动关闭显示 `user_initiated`，网络断开显示 `error_or_network_failure`

---

### 1.5 DioClient 超时配置日志

**文件**: `lib/core/network/dio_client.dart`

**问题**: 超时值硬编码，触发时缺少诊断信息

**修复方案**:
```dart
static Dio create({required String baseUrl}) {
  const connectTimeout = Duration(seconds: 15);
  const receiveTimeout = Duration(seconds: 30);
  const sendTimeout = Duration(seconds: 30);
  
  AppLogger.info(
    'DioClient: baseUrl=$baseUrl, '
    'connectTimeout=${connectTimeout.inSeconds}s, '
    'receiveTimeout=${receiveTimeout.inSeconds}s, '
    'sendTimeout=${sendTimeout.inSeconds}s'
  );
  
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: connectTimeout,
    receiveTimeout: receiveTimeout,
    sendTimeout: sendTimeout,
  ));
  
  // ... rest of setup
}
```

**验证**: 启动 app 时日志中应显示超时配置

---

## Phase 2: 错误传播和用户反馈（MEDIUM 优先级）

### 2.1 添加网络连通性预检

**文件**: `lib/features/market/data/remote/market_remote_data_source.dart`

**问题**: 离线时请求要等 30s 超时才失败

**修复方案**:
```dart
import '../../../core/network/connectivity_service.dart';

class MarketRemoteDataSource {
  MarketRemoteDataSource(this._dio, this._connectivity);
  
  final Dio _dio;
  final ConnectivityService _connectivity;
  
  Future<T> _withConnectivityCheck<T>(
    String operation,
    Future<T> Function() call,
  ) async {
    // Check connectivity first
    final isConnected = await _connectivity.isConnected;
    if (!isConnected) {
      AppLogger.warning('$operation: no network connectivity');
      throw NetworkException(message: '网络未连接，请检查网络设置');
    }
    
    return call();
  }
  
  // Update all methods to use wrapper
  Future<QuotesResponseDto> getQuotes(List<String> symbols) async {
    return _withConnectivityCheck(
      'getQuotes',
      () => _withRateLimitRetry('getQuotes', () async {
        // ... existing logic
      }),
    );
  }
}
```

**依赖**: 需要在 provider 中注入 `ConnectivityService`

**验证**: 飞行模式下请求应立即失败并显示"网络未连接"

---

### 2.2 WS Token 过期重认证失败传播到 UI

**文件**: `lib/features/market/application/quote_websocket_notifier.dart`

**问题**: reauth 失败只记录 warning，UI 不知道

**修复方案**:
```dart
// Line 146-158
Future<void> _handleTokenExpiring(WsTokenExpiringException ex) async {
  AppLogger.debug('QuoteWS: token expiring in ${ex.expiresInSeconds}s — reauthenticating');
  try {
    final token = await ref.read(tokenServiceProvider).getAccessToken();
    if (token != null && token.isNotEmpty && _client != null) {
      final userType = await _client!.reauth(token);
      state = AsyncData(userType);
      AppLogger.info('QuoteWS: reauth successful');
    } else {
      throw AuthException(message: 'No valid token available for reauth');
    }
  } on Object catch (e, stack) {
    AppLogger.error('QuoteWS: reauth on token_expiring failed', error: e, stackTrace: stack);
    
    // Set error state so UI can show warning
    state = AsyncError(
      AuthException(message: '行情认证失败，请重新登录'),
      stack,
    );
    
    // Close connection to trigger reconnect
    await _client?.close();
  }
}
```

**验证**: 模拟 token 过期，UI 应显示认证失败提示

---

### 2.3 添加 Ping/Pong 超时检测

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**问题**: 不验证 pong 响应，无法检测僵尸连接

**修复方案**:
```dart
// Add fields
DateTime? _lastPongTime;
Timer? _pongTimeoutTimer;
static const _pongTimeout = Duration(seconds: 45); // 1.5x ping interval

// Line 318-327 - Update ping logic
void _startPingTimer() {
  _pingTimer?.cancel();
  _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    if (_state == _WsState.authenticated) {
      _send({'type': 'ping'});
      AppLogger.debug('WS: ping sent');
      
      // Start pong timeout timer
      _pongTimeoutTimer?.cancel();
      _pongTimeoutTimer = Timer(_pongTimeout, () {
        AppLogger.error('WS: pong timeout - connection appears dead');
        _quoteController.addError(
          NetworkException(message: '行情连接超时，正在重连...'),
        );
        _channel?.sink.close(1000, 'pong timeout');
      });
    }
  });
}

// Line 239-241 - Update pong handler
case 'pong':
  _lastPongTime = DateTime.now();
  _pongTimeoutTimer?.cancel();
  AppLogger.debug('WS: pong received');
  break;

// Update _cleanup to cancel timer
void _cleanup() {
  _pongTimeoutTimer?.cancel();
  // ... existing cleanup
}
```

**验证**: 模拟服务端不响应 pong，45 秒后应触发重连

---

### 2.4 改进 WS 重连日志

**文件**: `lib/features/market/application/quote_websocket_notifier.dart`

**问题**: 重连日志缺少断连原因

**修复方案**:
```dart
// Add field to track last error
Object? _lastError;

// Line 160-190
Future<void> _handleNetworkError(NetworkException ex) async {
  _lastError = ex;
  
  if (_reconnectAttempts >= _kMaxReconnectAttempts) {
    AppLogger.error(
      'QuoteWS: max reconnect attempts reached after ${ex.runtimeType}',
    );
    state = AsyncError(ex, StackTrace.current);
    return;
  }

  final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
  _reconnectAttempts++;
  
  AppLogger.debug(
    'QuoteWS: reconnecting in ${delay.inSeconds}s '
    '(attempt $_reconnectAttempts/$_kMaxReconnectAttempts) '
    'reason: ${ex.message}',
  );

  await Future<void>.delayed(delay);
  await _connect();
}
```

**验证**: 检查重连日志包含断连原因

---

### 2.5 JSON 文本帧解析失败传播错误

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**问题**: JSON 解析失败静默忽略

**修复方案**:
```dart
// Line 222-229
void _handleTextFrame(String text) {
  Map<String, dynamic> msg;
  try {
    msg = jsonDecode(text) as Map<String, dynamic>;
  } catch (e, stack) {
    AppLogger.error('WS: malformed text frame', error: e, stackTrace: stack);
    
    // Add error to stream for critical control messages
    _quoteController.addError(
      DataException(
        message: 'Failed to parse WebSocket control message',
        cause: e,
      ),
    );
    return;
  }
  
  // ... rest of logic
}
```

**验证**: 发送错误 JSON，应在日志中看到 error 级别日志

---

### 2.6 改进限流重试日志

**文件**: `lib/features/market/data/remote/market_remote_data_source.dart`

**问题**: 重试成功无日志，失败丢失重试上下文

**修复方案**:
```dart
// Line 229-252
if (retryAfter != null && retryAfter <= _maxRetryAfterSeconds) {
  AppLogger.warning(
    'Market API 429 [$operation] — retrying after ${retryAfter}s',
  );
  await Future<void>.delayed(Duration(seconds: retryAfter));
  
  try {
    final result = await call();
    AppLogger.info('Market API 429 [$operation] — retry succeeded');
    return result;
  } on DioException catch (e2) {
    AppLogger.error(
      'Market API 429 [$operation] — retry failed: ${e2.type}',
      error: e2,
    );
    throw _mapDioException(e2, '$operation (retry)');
  }
}
```

**验证**: 触发 429，检查日志包含重试结果

---

### 2.7 错误日志添加请求参数

**文件**: `lib/features/market/data/remote/market_remote_data_source.dart`

**问题**: 错误日志缺少 symbol 等参数

**修复方案**:
```dart
// Update _mapDioException signature
AppException _mapDioException(
  DioException err,
  String operation, {
  Map<String, dynamic>? context,
}) {
  final statusCode = err.response?.statusCode;
  final errorCode = _extractErrorCode(err.response?.data);
  
  final contextStr = context != null ? ' context=$context' : '';
  AppLogger.warning(
    'Market API error [$operation]: status=$statusCode, code=$errorCode$contextStr',
  );
  
  // ... rest of mapping
}

// Update all call sites to include context
Future<StockDetailDto> getStockDetail(String symbol) async {
  return _withRateLimitRetry('getStockDetail', () async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/v1/market/stocks/$symbol');
      return StockDetailDto.fromJson(resp.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'getStockDetail', context: {'symbol': symbol});
    }
  });
}
```

**验证**: 触发错误，日志应包含 `context={symbol: AAPL}`

---

### 2.8 自选股导入失败反馈

**文件**: `lib/features/market/application/watchlist_notifier.dart`

**问题**: 导入失败静默跳过

**修复方案**:
```dart
// Line 243-258 - Return failed symbols
Future<List<String>> importGuestItems(
  List<WatchlistItem> guestItems,
) async {
  AppLogger.info(
      'WatchlistNotifier: importing ${guestItems.length} guest items');
  
  final repo = ref.read(watchlistRepositoryProvider);
  final failed = <String>[];
  
  for (final item in guestItems) {
    try {
      await repo.addToWatchlist(symbol: item.symbol, market: item.market);
    } on Object catch (e) {
      AppLogger.warning(
          'WatchlistNotifier: failed to import ${item.symbol}: $e');
      failed.add(item.symbol);
    }
  }
  
  ref.invalidateSelf();
  
  if (failed.isNotEmpty) {
    AppLogger.warning('WatchlistNotifier: ${failed.length} items failed to import: $failed');
  }
  
  return failed;
}
```

**UI 层修改**: 调用方需要检查返回值并显示失败提示

**验证**: 模拟部分导入失败，UI 应显示失败的股票列表

---

### 2.9 热门搜索加载失败 UI 反馈

**文件**: `lib/features/market/application/search_notifier.dart`

**问题**: 加载失败时热门区域为空，无法区分"无数据"和"失败"

**修复方案**:
```dart
// Add field to track hot stocks error
Object? _hotStocksError;

// Line 143-165
Future<void> _loadHotStocks() async {
  try {
    final repo = ref.read(marketDataRepositoryProvider);
    final items = await repo.getHotStocks();
    _hotStocks = items;
    _hotStocksError = null;
    AppLogger.debug('SearchNotifier: loaded ${items.length} hot stocks');
  } on Object catch (e, stack) {
    _hotStocksError = e;
    AppLogger.error('SearchNotifier: failed to load hot stocks', error: e, stackTrace: stack);
    // Keep existing hot stocks if any, but mark as stale
  }
}

// Add getter for UI to check error state
Object? get hotStocksError => _hotStocksError;
```

**UI 层修改**: 检查 `hotStocksError` 并显示错误提示

**验证**: 断网后搜索，热门区域应显示"加载失败"而非空白

---

## Phase 3: 日志质量改进（LOW 优先级）

### 3.1 Log Interceptor 添加请求 ID

**文件**: `lib/core/logging/log_interceptor.dart`

**修复**: 从 headers 中读取 `X-Request-ID` 并包含在日志中

### 3.2 启动时记录 Base URL

**文件**: `lib/core/network/dio_client.dart`

**修复**: 将 base URL 日志级别从 debug 改为 info

### 3.3 完善 WS Close Code 映射

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**修复**: 添加更多标准 WebSocket close code 的映射

### 3.4 Token 刷新成功日志

**文件**: `lib/core/network/auth_interceptor.dart`

**修复**: 将成功日志从 debug 改为 info

### 3.5 Stale Quote 检测日志

**文件**: `lib/features/market/data/websocket/quote_websocket_client.dart`

**修复**: 当检测到 `isStale=true` 时记录 warning

---

## 实施顺序

建议分 3 个会话完成：

### Session 1: 关键基础设施（预计 1-2 小时）
- Task #21: Correlation ID
- Task #9: WS connection timeout
- Task #14: Protobuf error propagation
- Task #18: WS disconnect reason tracking
- Task #22: Timeout logging

### Session 2: 错误传播（预计 1-2 小时）
- Task #20: Connectivity check
- Task #19: WS token refresh error propagation
- Task #23: Ping/pong timeout
- Task #11: Reconnect logging
- Task #10: JSON parsing error propagation

### Session 3: 日志和反馈（预计 1 小时）
- Task #16: Retry logging
- Task #12: Request context in errors
- Task #13: Watchlist import feedback
- Task #17: Hot stocks error feedback
- Tasks #15, LOW priority items

---

## 验证清单

每个修复完成后需要验证：

- [ ] 单元测试通过
- [ ] 集成测试通过
- [ ] 日志输出符合预期
- [ ] 错误场景下 UI 有正确反馈
- [ ] 性能无明显下降

---

## 依赖变更

需要在 `pubspec.yaml` 添加：

```yaml
dependencies:
  uuid: ^4.0.0  # For correlation ID generation
```

---

**创建时间**: 2026-04-09  
**预计完成时间**: 3 个工作会话  
**优先级**: P0（生产环境故障定位能力）
