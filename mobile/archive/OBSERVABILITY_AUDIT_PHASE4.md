# Auth & Market 模块可观测性审计

## Auth 模块分析

### 1. AuthRemoteDataSource (auth_remote_data_source.dart)
**问题**:
- ❌ sendOtp() / verifyOtp() 缺少请求参数日志（phone, code）
- ❌ 成功的 OTP 操作无日志记录（只有错误时记录）
- ❌ refreshToken() 成功无日志
- ❌ biometric 操作缺少成功日志
- ❌ _mapDioException() 缺少 idempotency key 上下文

**建议修复**:
- 在 sendOtp/verifyOtp 成功时记录 info 日志（不含敏感信息）
- 在 refreshToken 成功时记录 info 日志
- 在 biometric 操作成功时记录 debug 日志
- 在错误映射中添加 idempotency key 信息

### 2. AuthNotifier (auth_notifier.dart)
**问题**:
- ❌ _silentRefresh() 缺少成功日志
- ❌ sendOtp() 缺少请求上下文（phone, region）
- ❌ verifyOtp() 失败无重试上下文
- ❌ _isBiometricRegistered() 无任何日志
- ❌ registerBiometric() 无成功日志
- ✅ Session restore 有日志

**建议修复**:
- 在 _silentRefresh 成功时记录 info 日志
- 在 sendOtp 时记录请求上下文（region）
- 在 verifyOtp 失败时记录 error 含尝试次数
- 在 _isBiometricRegistered 完成时记录结果
- 在 registerBiometric 成功时记录 info

### 3. OtpTimerNotifier (otp_timer_notifier.dart)
**问题**:
- ✅ onOtpError 有日志
- ✅ _startLockout 有日志
- ❌ onOtpExpired() 无日志
- ❌ onOtpResent() 无日志
- ❌ 倒计时状态变化无日志

**建议修复**:
- 在 onOtpExpired 时记录 warning
- 在 onOtpResent 时记录 debug
- 在倒计时完成时记录状态变化

---

## Market 模块分析

### 1. MarketRemoteDataSource
**问题**:
- ✅ 连通性检查已添加
- ✅ 限流重试已有日志
- ❌ getKline/searchStocks 缺少请求参数日志
- ❌ getNews/getFinancials 成功无日志
- ❌ watchlist 操作成功无日志
- ❌ _mapDioException 缺少操作耗时信息

**建议修复**:
- 在 getKline 记录 period/from/to 参数
- 在 searchStocks 记录查询 q
- 在 getNews/getFinancials 成功时记录 debug
- 在 addToWatchlist/removeFromWatchlist 成功时记录 info
- 记录 API 响应时间

### 2. QuoteWebSocketClient
**问题**:
- ✅ 连接超时已添加
- ✅ Protobuf 错误已传播
- ✅ JSON 错误已传播
- ✅ Ping/Pong 超时已检测
- ✅ Close 原因已追踪
- ❌ 认证成功无日志
- ❌ 订阅成功无日志
- ❌ 帧处理速率无日志（可能的性能问题）

**建议修复**:
- 在 _onAuthResult 成功时记录 info
- 在 _onSubscribeAck 时记录订阅的符号
- 定期记录帧处理率（e.g., 每 1000 帧）

### 3. QuoteWebSocketNotifier
**问题**:
- ✅ Token 刷新错误已传播
- ✅ 重连日志已改进
- ❌ subscribe/unsubscribe 成功无日志
- ❌ _reconnectAttempts 达到限制后无明确日志
- ❌ 连接就绪后无完整日志

**建议修复**:
- 在 subscribe 成功时记录 debug (含符号列表)
- 在 unsubscribe 时记录 debug
- 在达到最大重连次数时记录 error
- 在连接就绪时记录 info

### 4. SearchNotifier
**问题**:
- ✅ hotStocksError 已添加
- ❌ query 开始/完成无日志
- ❌ debounce 超时无日志
- ❌ 搜索结果计数无日志

**建议修复**:
- 在 search 开始时记录 debug (q=$query)
- 在搜索完成时记录结果计数
- 记录搜索耗时

### 5. WatchlistNotifier
**问题**:
- ✅ importGuestItems 失败已反馈
- ❌ 初始化加载无日志
- ❌ addToWatchlist/removeFromWatchlist 成功无日志
- ❌ 同步状态变化无日志

**建议修复**:
- 在初始化完成时记录 info (符号数量)
- 在 add/remove 成功时记录 debug
- 记录同步成功/失败

### 6. StockDetailNotifier
**问题**:
- ✅ 加载错误已记录
- ❌ 初始加载耗时无记录
- ❌ 实时更新补丁计数无记录
- ❌ 一级市场数据变化（delayed→regular）无日志

**建议修复**:
- 记录初始加载耗时
- 定期记录累积补丁数
- 记录市场状态变化

---

## 优先级建议

### 高 (建议立即修复)
1. API 成功操作无日志（auth/market 核心路径）
2. 订阅/取消订阅无日志（WS 生命周期不完整）
3. 请求参数丢失（错误诊断不完整）

### 中 (下个迭代)
1. 性能指标无记录（帧率、耗时）
2. 状态转移无日志
3. 操作计数无记录

### 低 (改进，非必须)
1. Debounce 超时日志
2. 累积统计日志

---

## 快速修复列表

```
Auth Module (8 items):
1. sendOtp success logging
2. verifyOtp success logging  
3. refreshToken success logging
4. registerBiometric success logging
5. _isBiometricRegistered logging
6. onOtpExpired logging
7. onOtpResent logging
8. Error mapping with idempotency context

Market Module (12 items):
9. getKline parameter logging
10. searchStocks query logging
11. getNews/getFinancials success logging
12. watchlist add/remove success logging
13. API response time tracking
14. WS auth success logging
15. WS subscribe success logging
16. WS frame throughput metrics
17. subscribe/unsubscribe logging
18. max reconnect attempts logging
19. search result count logging
20. watchlist sync status logging
21. stock detail load time logging
22. realtime update patch count logging
```

总计: 22 个建议改进项
