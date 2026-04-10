# Watchlist Loading Fix Summary

## 问题描述
访客模式下自选股页面显示"出现错误，加载自选股失败"。

## 根本原因分析
通过单元测试和日志分析，发现了以下问题：

### 1. Mock Server API 响应缺少必需字段
- **缺少 `as_of` 字段**: `QuotesResponseDto` 要求此字段，但 mock server 未返回
- **缺少 `name_zh` 字段**: `QuoteDto` 要求此字段为 `required String`
- **缺少 `market_status` 字段**: `QuoteDto` 要求此字段为 `required String`
- **`volume` 字段类型错误**: 应为 `int` 但返回的是 `string`

### 2. iOS App Transport Security (ATS) 阻止 HTTP 连接
- iOS 默认阻止非 HTTPS 连接
- `Info.plist` 缺少 `NSAppTransportSecurity` 配置

### 3. SSL Pinning 阻止 localhost 连接
- `ssl_pinning_config.dart` 对未配置的主机采用 fail-closed 策略
- localhost 不在 `_spkiPins` 配置中

## 已完成的修复

### 1. Mock Server 修复 (`mobile/mock-server/`)

#### `rest.go`
```go
// 添加 as_of 字段到 quotes 响应
json.NewEncoder(w).Encode(map[string]interface{}{
    "quotes": quotes,
    "as_of":  time.Now().UTC().Format(time.RFC3339),
})
```

#### `data.go`
```go
// 为所有股票添加必需字段
var baseQuotes = map[string]map[string]interface{}{
    "AAPL": {
        // ... 其他字段
        "name_zh":       "苹果公司",
        "market_status": "OPEN",
        "volume":        52341234,  // int 而不是 string
    },
    // ... 其他股票
}
```

### 2. iOS ATS 配置 (`ios/Runner/Info.plist`)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 3. SSL Pinning 配置 (`lib/core/security/ssl_pinning_config.dart`)
```dart
bool _spkiBadCertCallback(X509Certificate cert, String host, int port) {
  // Allow localhost for testing/development
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    AppLogger.debug('SSL pinning: allowing localhost connection for testing');
    return true;
  }
  // ... 其他逻辑
}
```

## 验证结果

### ✅ 单元测试通过
```bash
flutter test test/features/market/data/watchlist_repository_test.dart
```
输出：
```
✅ API call successful
Quotes count: 4
as_of: 2026-04-08T01:26:15Z
Symbols: 0700, 9988, AAPL, TSLA
00:00 +1: All tests passed!
```

### ⚠️ 集成测试仍然失败
虽然单元测试通过，但集成测试中自选股仍然加载失败。

## 剩余问题

日志显示：
1. ✅ App 启动成功
2. ✅ 进入访客模式成功
3. ✅ DioClient 创建成功
4. ✅ 调用 `getWatchlist (guest)`
5. ❌ **之后没有任何日志**，说明代码在 `_guestWatchlist()` 内部抛出异常

可能的原因：
- Hive 初始化问题
- 异常被 Riverpod 捕获但未记录
- 需要添加更详细的错误日志来定位具体失败点

## 建议的下一步

1. **添加详细的错误日志**到 `WatchlistRepositoryImpl._guestWatchlist()`
2. **添加 try-catch** 包裹关键代码段并记录异常
3. **检查 Hive 初始化**是否在 `_local.getItems()` 调用前完成
4. **使用 Flutter DevTools** 连接到运行中的 app 查看实时异常

## 文件清单

### 修改的文件
- `mobile/mock-server/rest.go`
- `mobile/mock-server/data.go`
- `mobile/src/ios/Runner/Info.plist`
- `mobile/src/lib/core/security/ssl_pinning_config.dart`

### 新增的文件
- `mobile/src/integration_test/watchlist_loading_test.dart`
- `mobile/src/test/features/market/data/watchlist_repository_test.dart`

## Git Commit 建议

```bash
git add mobile/mock-server/rest.go mobile/mock-server/data.go
git commit -m "fix(mock-server): add missing fields to quotes API response

- Add as_of field to QuotesResponseDto
- Add name_zh and market_status to QuoteDto
- Fix volume field type from string to int

Fixes API contract compliance with Flutter client"

git add mobile/src/ios/Runner/Info.plist
git commit -m "fix(ios): allow HTTP connections to localhost for testing

Add NSAppTransportSecurity configuration to allow localhost HTTP
connections for mock server testing"

git add mobile/src/lib/core/security/ssl_pinning_config.dart
git commit -m "fix(security): allow localhost in SSL pinning for development

Add exception for localhost/127.0.0.1/::1 to enable testing with
local mock server"

git add mobile/src/integration_test/watchlist_loading_test.dart mobile/src/test/features/market/data/watchlist_repository_test.dart
git commit -m "test(market): add watchlist loading tests

- Add unit test for quotes API connectivity
- Add integration test for guest mode watchlist loading"
```
