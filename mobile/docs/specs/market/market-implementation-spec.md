# Market 模块技术实现规格

**版本**: v1.0  
**日期**: 2026-04-04  
**状态**: DRAFT  
**关联**: [market.tracker.md](../market.tracker.md)

---

## 1. WebSocket 架构

### 1.1 连接管理

```dart
// features/market/data/remote/quote_websocket_client.dart

class QuoteWebSocketClient {
  final String wsUrl;
  final TokenService _tokenService;
  WebSocketChannel? _channel;
  StreamController<WsQuoteFrame> _controller;
  Timer? _heartbeatTimer;
  Set<String> _subscribedSymbols = {};
  
  // 连接生命周期
  Future<void> connect() async {
    _channel = WebSocketChannel.connect(
      Uri.parse(wsUrl),
      protocols: ['brokerage-market-v1'],
    );
    
    // 5秒内必须完成认证
    _authTimer = Timer(Duration(seconds: 5), () {
      if (!_authenticated) {
        _channel?.sink.close(4001, 'Auth timeout');
      }
    });
    
    _listenToMessages();
  }
  
  // 消息级认证（不使用 URL query param）
  Future<void> authenticate() async {
    final token = await _tokenService.getAccessToken();
    final authMsg = jsonEncode({
      'action': 'auth',
      'token': token ?? '', // 空字符串表示访客
    });
    _channel?.sink.add(authMsg);
  }
  
  // 订阅管理（最多50 symbols）
  Future<void> subscribe(List<String> symbols) async {
    if (symbols.length > 50) {
      throw SymbolLimitExceededException('最多订阅50个symbols');
    }
    
    final subMsg = jsonEncode({
      'action': 'subscribe',
      'symbols': symbols,
    });
    _channel?.sink.add(subMsg);
    _subscribedSymbols.addAll(symbols);
  }
  
  // 心跳（30s ping）
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode({'action': 'ping'}));
    });
  }
  
  // Token 续期（无需断开连接）
  Future<void> reauth(String newToken) async {
    final reauthMsg = jsonEncode({
      'action': 'reauth',
      'token': newToken,
    });
    _channel?.sink.add(reauthMsg);
  }
}
```

### 1.2 Protobuf 解析

```dart
// features/market/data/remote/ws_message_parser.dart

import 'package:protobuf/protobuf.dart';
import 'package:your_app/proto/market_data.pb.dart';

class WsMessageParser {
  Stream<Quote> parseMessages(Stream<dynamic> rawStream) {
    return rawStream.asyncMap((message) {
      if (message is String) {
        // JSON 文本帧（控制消息）
        return _handleControlMessage(jsonDecode(message));
      } else if (message is List<int>) {
        // Protobuf 二进制帧（行情数据）
        final frame = WsQuoteFrame.fromBuffer(message);
        return _convertToQuote(frame);
      }
    }).where((q) => q != null).cast<Quote>();
  }
  
  Quote _convertToQuote(WsQuoteFrame frame) {
    final q = frame.quote;
    return Quote(
      symbol: q.symbol,
      price: Decimal.parse(q.price),
      change: Decimal.parse(q.change),
      changePct: Decimal.parse(q.changePct),
      volume: q.volume,
      bid: Decimal.parse(q.bid),
      ask: Decimal.parse(q.ask),
      marketStatus: _parseMarketStatus(q.marketStatus),
      isStale: q.isStale,
      staleSinceMs: q.staleSinceMs,
      delayed: q.delayed,
      timestamp: DateTime.parse(q.timestamp),
    );
  }
}
```

---

## 2. Syncfusion Charts 配置

### 2.1 K线图 Widget

```dart
// features/market/presentation/widgets/kline_chart_widget.dart

class KLineChartWidget extends HookConsumerWidget {
  final String symbol;
  final KLinePeriod period;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final candlesAsync = ref.watch(candleProvider(symbol, period));
    
    return candlesAsync.when(
      data: (candles) => SfCartesianChart(
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        crosshairBehavior: CrosshairBehavior(
          enable: true,
          activationMode: ActivationMode.longPress,
        ),
        primaryXAxis: DateTimeAxis(
          dateFormat: _getDateFormat(period),
        ),
        primaryYAxis: NumericAxis(
          opposedPosition: true,
        ),
        series: <ChartSeries>[
          CandleSeries<Candle, DateTime>(
            dataSource: candles,
            xValueMapper: (Candle c, _) => c.timestamp,
            lowValueMapper: (Candle c, _) => c.low.toDouble(),
            highValueMapper: (Candle c, _) => c.high.toDouble(),
            openValueMapper: (Candle c, _) => c.open.toDouble(),
            closeValueMapper: (Candle c, _) => c.close.toDouble(),
            bearColor: ColorTokens.loss,
            bullColor: ColorTokens.gain,
          ),
          ColumnSeries<Candle, DateTime>(
            dataSource: candles,
            xValueMapper: (Candle c, _) => c.timestamp,
            yValueMapper: (Candle c, _) => c.volume,
            yAxisName: 'volumeAxis',
            opacity: 0.5,
          ),
        ],
        axes: <ChartAxis>[
          NumericAxis(
            name: 'volumeAxis',
            opposedPosition: false,
            maximum: _calculateVolumeMax(candles),
          ),
        ],
      ),
      loading: () => SkeletonLoader(),
      error: (err, stack) => ErrorWidget(err),
    );
  }
}
```

### 2.2 时间轴映射

| PRD 用户视角 | API period | from/to 参数 | 说明 |
|-------------|-----------|-------------|------|
| 分时 | 1min | from=YYYY-MM-DD（当日） | 仅常规交易时段 09:30-16:00 ET，约390条 |
| 5日 | 5min | from=5天前, to=now | 近5个交易日分钟K线 |
| 1月 | 1d | from=1月前, to=now | 近1个月日K线 |
| 3月 | 1d | from=3月前, to=now | 近3个月日K线 |
| 1年 | 1d | from=1年前, to=now | 近1年日K线 |
| 全部 | 1d | from=上市日期, to=now | 全历史日K线 |

---

## 3. Riverpod Provider 设计

### 3.1 QuoteStreamProvider

```dart
// features/market/presentation/providers/quote_stream_provider.dart

@riverpod
class QuoteStream extends _$QuoteStream {
  late QuoteWebSocketClient _wsClient;
  
  @override
  Stream<Map<String, Quote>> build() async* {
    _wsClient = ref.read(quoteWebSocketClientProvider);
    
    await _wsClient.connect();
    await _wsClient.authenticate();
    
    // Pause/Resume（Riverpod 3.0 自动管理）
    ref.onDispose(() {
      _wsClient.close();
    });
    
    // 订阅当前需要的 symbols
    final symbols = ref.watch(activeSymbolsProvider);
    await _wsClient.subscribe(symbols);
    
    // 转换为 Map<symbol, Quote>
    final quoteMap = <String, Quote>{};
    await for (final quote in _wsClient.stream) {
      quoteMap[quote.symbol] = quote;
      yield Map.from(quoteMap);
    }
  }
}
```

### 3.2 WatchlistNotifier

```dart
// features/market/presentation/providers/watchlist_provider.dart

@riverpod
class Watchlist extends _$Watchlist {
  @override
  Future<List<Quote>> build() async {
    final repo = ref.read(watchlistRepositoryProvider);
    final authState = ref.watch(authProvider);
    
    if (authState == AuthState.authenticated) {
      // 注册用户：从服务端获取
      return await repo.getWatchlist();
    } else {
      // 访客：从本地缓存获取
      return await repo.getLocalWatchlist();
    }
  }
  
  Future<void> add(String symbol, Market market) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(watchlistRepositoryProvider);
      await repo.addToWatchlist(symbol, market);
      
      // 重新加载
      return await build();
    });
  }
  
  Future<void> remove(String symbol) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(watchlistRepositoryProvider);
      await repo.removeFromWatchlist(symbol);
      return await build();
    });
  }
}
```

---

## 4. 数据模型

### 4.1 Domain Entities

```dart
// features/market/domain/entities/quote.dart

class Quote {
  final String symbol;
  final Decimal price;
  final Decimal change;
  final Decimal changePct;
  final int volume;
  final Decimal bid;
  final Decimal ask;
  final MarketStatus marketStatus;
  final bool isStale;
  final int staleSinceMs;
  final bool delayed;
  final DateTime timestamp;
  
  // Stale Quote 前端显示逻辑
  bool get shouldShowStaleWarning => isStale && staleSinceMs >= 5000;
}

enum MarketStatus {
  regular,
  preMarket,
  afterHours,
  closed,
  halted,
}
```

### 4.2 DTOs

```dart
// features/market/data/dtos/quote_dto.dart

@freezed
class QuoteDto with _$QuoteDto {
  const factory QuoteDto({
    required String symbol,
    required String price,
    required String change,
    @JsonKey(name: 'change_pct') required String changePct,
    required int volume,
    required String bid,
    required String ask,
    @JsonKey(name: 'market_status') required String marketStatus,
    @JsonKey(name: 'is_stale') required bool isStale,
    @JsonKey(name: 'stale_since_ms') required int staleSinceMs,
    required bool delayed,
    required String timestamp,
  }) = _QuoteDto;
  
  factory QuoteDto.fromJson(Map<String, dynamic> json) =>
      _$QuoteDtoFromJson(json);
}

// Mapper
extension QuoteDtoX on QuoteDto {
  Quote toEntity() => Quote(
    symbol: symbol,
    price: Decimal.parse(price),
    change: Decimal.parse(change),
    changePct: Decimal.parse(changePct),
    volume: volume,
    bid: Decimal.parse(bid),
    ask: Decimal.parse(ask),
    marketStatus: _parseMarketStatus(marketStatus),
    isStale: isStale,
    staleSinceMs: staleSinceMs,
    delayed: delayed,
    timestamp: DateTime.parse(timestamp),
  );
}
```

---

## 5. 访客模式实现

### 5.1 延迟横幅

```dart
// features/market/presentation/widgets/delayed_quote_banner.dart

class DelayedQuoteBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState == AuthState.guest) {
      return Container(
        padding: EdgeInsets.all(SpaceTokens.space3),
        color: ColorTokens.warning.withOpacity(0.1),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: ColorTokens.warning),
            SizedBox(width: SpaceTokens.space2),
            Expanded(
              child: Text(
                '当前为延迟行情（15分钟），登录后查看实时数据',
                style: TextStyle(color: ColorTokens.textPrimary),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/auth/login'),
              child: Text('登录'),
            ),
          ],
        ),
      );
    }
    
    return SizedBox.shrink();
  }
}
```

### 5.2 自选股登录引导

```dart
// features/market/presentation/widgets/login_guidance_sheet.dart

void showLoginGuidanceSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: EdgeInsets.all(SpaceTokens.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('登录后使用自选股功能', style: TextStyle(fontSize: 18)),
          SizedBox(height: SpaceTokens.space3),
          Text('自选股数据将在多设备间同步'),
          SizedBox(height: SpaceTokens.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('继续浏览'),
                ),
              ),
              SizedBox(width: SpaceTokens.space2),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/auth/login');
                  },
                  child: Text('立即登录'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

---

## 6. Stale Quote 处理

### 6.1 警告横幅

```dart
// features/market/presentation/widgets/stale_quote_warning_banner.dart

class StaleQuoteWarningBanner extends StatelessWidget {
  final Quote quote;
  
  @override
  Widget build(BuildContext context) {
    if (!quote.shouldShowStaleWarning) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(SpaceTokens.space3),
      color: ColorTokens.warning.withOpacity(0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: ColorTokens.warning),
          SizedBox(width: SpaceTokens.space2),
          Expanded(
            child: Text(
              '行情数据可能存在延迟，请谨慎交易',
              style: TextStyle(color: ColorTokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 7. 性能优化

### 7.1 WebSocket 高频更新节流

```dart
// features/market/presentation/providers/quote_stream_provider.dart

@riverpod
Stream<Map<String, Quote>> throttledQuoteStream(ThrottledQuoteStreamRef ref) {
  final rawStream = ref.watch(quoteStreamProvider.stream);
  
  // RxDart throttle：100ms 内最多触发一次 rebuild
  return rawStream.throttleTime(Duration(milliseconds: 100));
}
```

### 7.2 列表滚动优化

```dart
// features/market/presentation/screens/market_home_screen.dart

class WatchlistTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: quotes.length,
      itemBuilder: (context, index) {
        return _WatchlistItem(
          key: ValueKey(quotes[index].symbol),
          quote: quotes[index],
        );
      },
    );
  }
}

class _WatchlistItem extends StatefulWidget with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 避免滚动时重建
}
```

---

## 8. 错误处理

### 8.1 WebSocket 错误码

| 关闭码 | 含义 | 客户端处理 |
|-------|------|----------|
| 1000 | 正常关闭 | 不重连 |
| 4001 | 认证超时（5s内未发auth） | 重新连接 |
| 4002 | 认证失败 | 提示用户重新登录 |
| 4003 | Token 过期 | 刷新 Token 后重连 |
| 4004 | 订阅超限（>50 symbols） | 减少订阅数量 |

### 8.2 REST API 错误

```dart
// features/market/data/remote/market_data_remote_datasource.dart

class MarketDataRemoteDataSource {
  Future<List<QuoteDto>> getQuotes(List<String> symbols) async {
    try {
      final response = await _dio.get('/v1/market/quotes', queryParameters: {
        'symbols': symbols.join(','),
      });
      return (response.data['quotes'] as Map).values
          .map((json) => QuoteDto.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryAfter = e.response?.headers['Retry-After']?.first;
        throw RateLimitException(retryAfter: int.tryParse(retryAfter ?? '60'));
      } else if (e.response?.statusCode == 400) {
        throw InvalidRequestException(e.response?.data['message']);
      }
      throw NetworkException(e.message);
    }
  }
}
```

---

## 9. 测试策略

### 9.1 单元测试

```dart
// test/features/market/data/remote/quote_websocket_client_test.dart

void main() {
  group('QuoteWebSocketClient', () {
    test('should authenticate within 5 seconds', () async {
      final client = QuoteWebSocketClient(mockChannel, mockTokenService);
      await client.connect();
      
      verify(() => mockChannel.sink.add(any(that: contains('auth')))).called(1);
    });
    
    test('should parse Protobuf binary frames', () async {
      final frame = WsQuoteFrame()
        ..frameType = FrameType.FRAME_TYPE_TICK
        ..quote = (Quote()
          ..symbol = 'AAPL'
          ..price = '182.52');
      
      final parsed = client.parseFrame(frame.writeToBuffer());
      expect(parsed.symbol, 'AAPL');
      expect(parsed.price, Decimal.parse('182.52'));
    });
  });
}
```

### 9.2 集成测试

```dart
// integration_test/market_flow_test.dart

void main() {
  testWidgets('Market flow: search -> detail -> add to watchlist', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // 1. 进入搜索页
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    
    // 2. 搜索 AAPL
    await tester.enterText(find.byType(TextField), 'AAPL');
    await tester.pump(Duration(milliseconds: 300)); // debounce
    await tester.pumpAndSettle();
    
    // 3. 点击搜索结果
    await tester.tap(find.text('AAPL'));
    await tester.pumpAndSettle();
    
    // 4. 验证股票详情页
    expect(find.text('Apple Inc.'), findsOneWidget);
    
    // 5. 点击收藏按钮
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();
    
    // 6. 验证已加入自选
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
```

---

## 10. 安全考虑

### 10.1 证书固定（Certificate Pinning）

```dart
// core/network/dio_client.dart

Dio createDioClient() {
  final dio = Dio();
  
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        // SPKI 公钥指纹验证
        final certHash = sha256.convert(cert.publicKey).toString();
        return SslPinningConfig.allowedHashes.contains(certHash);
      };
      return client;
    },
  );
  
  return dio;
}
```

### 10.2 PII 日志掩码

```dart
// core/logging/app_logger.dart

class AppLogger {
  void logQuoteUpdate(Quote quote) {
    logger.info('Quote update', {
      'symbol': quote.symbol,
      'price': quote.price.toString(),
      // 不记录用户 ID、设备 ID 等 PII
    });
  }
}
```
