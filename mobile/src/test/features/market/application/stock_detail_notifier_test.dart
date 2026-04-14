import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/application/quote_websocket_notifier.dart';
import 'package:trading_app/features/market/application/stock_detail_notifier.dart';
import 'package:trading_app/features/market/data/market_data_repository_impl.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/entities/stock_detail.dart';
import 'package:trading_app/features/market/domain/repositories/market_data_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockMarketDataRepository extends Mock implements MarketDataRepository {}

class MockTokenService extends Mock implements TokenService {}

class MockQuoteWebSocketClient extends Mock implements QuoteWebSocketClient {}

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

StockDetail makeDetail(String symbol, {String price = '150.0000'}) =>
    StockDetail(
      symbol: symbol,
      name: '$symbol Inc.',
      nameZh: '',
      market: 'US',
      price: Decimal.parse(price),
      change: Decimal.parse('1.0000'),
      changePct: Decimal.parse('0.0067'),
      open: Decimal.parse('149.5000'),
      high: Decimal.parse('151.0000'),
      low: Decimal.parse('148.5000'),
      prevClose: Decimal.parse('149.0000'),
      volume: 1000000,
      turnover: '150M',
      bid: Decimal.parse('149.9900'),
      ask: Decimal.parse('150.0100'),
      delayed: false,
      marketStatus: MarketStatus.regular,
      session: 'Regular Trading Hours',
      marketCap: '2.8T',
      peRatio: '28.50',
      pbRatio: '42.30',
      dividendYield: '0.52',
      sharesOutstanding: 15000000000,
      avgVolume: 80000000,
      week52High: Decimal.parse('182.9400'),
      week52Low: Decimal.parse('124.1700'),
      turnoverRate: Decimal.parse('0.53'),
      exchange: 'NASDAQ',
      sector: 'Technology',
      asOf: DateTime.utc(2026, 4, 6, 14, 0),
    );

/// Builds a [Quote] with just price/change fields set (other fields zeroed).
/// Used as the payload inside [WsQuoteUpdate].
Quote makeQuotePayload(String symbol, String price) => Quote(
      symbol: symbol,
      name: '',
      nameZh: '',
      market: 'US',
      price: Decimal.parse(price),
      change: Decimal.parse('1.0000'),
      changePct: Decimal.parse('0.0067'),
      volume: 1000000,
      bid: Decimal.parse('149.9900'),
      ask: Decimal.parse('150.0100'),
      turnover: '0',
      prevClose: Decimal.parse('149.0000'),
      open: Decimal.zero,
      high: Decimal.zero,
      low: Decimal.zero,
      marketCap: '',
      delayed: false,
      marketStatus: MarketStatus.regular,
    );

WsQuoteUpdate makeSnapshot(String symbol, {String price = '155.0000'}) =>
    WsQuoteUpdate(
      frameType: WsFrameType.snapshot,
      symbol: symbol,
      quote: makeQuotePayload(symbol, price),
    );

WsQuoteUpdate makeTick(String symbol, {String price = '160.0000'}) =>
    WsQuoteUpdate(
      frameType: WsFrameType.tick,
      symbol: symbol,
      quote: makeQuotePayload(symbol, price),
    );

ProviderContainer buildContainer({
  required MockMarketDataRepository mockRepo,
  required MockTokenService mockToken,
  required MockQuoteWebSocketClient mockWsClient,
  required StreamController<WsQuoteUpdate> wsStream,
}) {
  return ProviderContainer(
    overrides: [
      marketDataRepositoryProvider.overrideWith((_) => mockRepo),
      tokenServiceProvider.overrideWithValue(mockToken),
      wsClientFactoryProvider.overrideWithValue((_) => mockWsClient),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  late MockMarketDataRepository mockRepo;
  late MockTokenService mockToken;
  late MockQuoteWebSocketClient mockWsClient;
  late StreamController<WsQuoteUpdate> wsStream;

  setUp(() {
    mockRepo = MockMarketDataRepository();
    mockToken = MockTokenService();
    mockWsClient = MockQuoteWebSocketClient();
    wsStream = StreamController<WsQuoteUpdate>.broadcast(sync: true);

    when(() => mockToken.getAccessToken())
        .thenAnswer((_) async => 'valid-jwt');
    when(() => mockWsClient.connect(token: any(named: 'token')))
        .thenAnswer((_) async => WsUserType.registered);
    when(() => mockWsClient.quoteStream)
        .thenAnswer((_) => wsStream.stream);
    when(() => mockWsClient.subscribe(any())).thenAnswer((_) async {});
    when(() => mockWsClient.unsubscribe(any())).thenReturn(null);
    when(() => mockWsClient.close()).thenAnswer((_) async {});
    when(() => mockWsClient.dispose()).thenAnswer((_) async {});
  });

  tearDown(() => wsStream.close());

  // ─── build() ─────────────────────────────────────────────────────────────

  group('build()', () {
    test('fetches StockDetail from repository', () async {
      when(() => mockRepo.getStockDetail('AAPL'))
          .thenAnswer((_) async => makeDetail('AAPL'));

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      final result = await container.read(stockDetailProvider('AAPL').future);

      expect(result.symbol, 'AAPL');
      expect(result.price, Decimal.parse('150.0000'));
      verify(() => mockRepo.getStockDetail('AAPL')).called(1);
    });

    test('subscribes symbol to WS once connected', () async {
      when(() => mockRepo.getStockDetail('AAPL'))
          .thenAnswer((_) async => makeDetail('AAPL'));

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(stockDetailProvider('AAPL').future);
      await container.read(quoteWebSocketProvider.future);
      await Future<void>.delayed(Duration.zero);

      final captured =
          verify(() => mockWsClient.subscribe(captureAny())).captured;
      final allSymbols = captured.expand((b) => b as List<String>).toSet();
      expect(allSymbols, contains('AAPL'));
    });

    test('state becomes error on repository failure', () async {
      when(() => mockRepo.getStockDetail('FAIL'))
          .thenThrow(Exception('network error'));

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      // Keep provider alive; Riverpod 3 retries failed builds
      final sub = container.listen(stockDetailProvider('FAIL'), (_, _) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      // Wait for first build attempt to fail
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // hasError is true for AsyncError AND AsyncLoading(retrying) with prior error
      expect(container.read(stockDetailProvider('FAIL')).hasError, isTrue);
    });
  });

  // ─── Live quote patching ──────────────────────────────────────────────────

  group('live quote patching', () {
    late ProviderContainer container;
    late ProviderSubscription<AsyncValue<StockDetail>> keepAlive;

    setUp(() async {
      when(() => mockRepo.getStockDetail('AAPL'))
          .thenAnswer((_) async => makeDetail('AAPL'));
      container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      // Listen to prevent autoDispose during the test
      keepAlive = container.listen(stockDetailProvider('AAPL'), (_, _) {});
      await container.read(stockDetailProvider('AAPL').future);
      // Wait for WS pipe to be established
      await container.read(quoteWebSocketProvider.future);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      keepAlive.close();
      container.dispose();
    });

    test('SNAPSHOT patches price', () async {
      wsStream.add(makeSnapshot('AAPL', price: '175.0000'));
      await Future<void>.delayed(Duration.zero);

      final detail = container.read(stockDetailProvider('AAPL')).value!;
      expect(detail.price, Decimal.parse('175.0000'));
    });

    test('TICK patches price and preserves prevClose', () async {
      wsStream.add(makeTick('AAPL', price: '160.0000'));
      await Future<void>.delayed(Duration.zero);

      final detail = container.read(stockDetailProvider('AAPL')).value!;
      expect(detail.price, Decimal.parse('160.0000'));
      expect(detail.prevClose, Decimal.parse('149.0000')); // unchanged
    });

    test('SNAPSHOT preserves fundamental fields', () async {
      wsStream.add(makeSnapshot('AAPL', price: '175.0000'));
      await Future<void>.delayed(Duration.zero);

      final detail = container.read(stockDetailProvider('AAPL')).value!;
      expect(detail.marketCap, '2.8T');
      expect(detail.peRatio, '28.50');
      expect(detail.exchange, 'NASDAQ');
      expect(detail.sector, 'Technology');
    });

    test('WS update for different symbol is ignored', () async {
      wsStream.add(makeSnapshot('TSLA', price: '200.0000'));
      await Future<void>.delayed(Duration.zero);

      final detail = container.read(stockDetailProvider('AAPL')).value!;
      expect(detail.price, Decimal.parse('150.0000')); // unchanged
    });

    test('sequential TICK updates accumulate correctly', () async {
      wsStream.add(makeTick('AAPL', price: '160.0000'));
      wsStream.add(makeTick('AAPL', price: '161.0000'));
      await Future<void>.delayed(Duration.zero);

      final detail = container.read(stockDetailProvider('AAPL')).value!;
      expect(detail.price, Decimal.parse('161.0000'));
    });
  });

  // ─── dispose / unsubscribe ────────────────────────────────────────────────

  group('dispose', () {
    test('unsubscribes from WS on dispose', () async {
      when(() => mockRepo.getStockDetail('AAPL'))
          .thenAnswer((_) async => makeDetail('AAPL'));

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );

      // Listen to keep provider alive until we explicitly dispose
      final sub =
          container.listen(stockDetailProvider('AAPL'), (_, _) {});

      await container.read(stockDetailProvider('AAPL').future);
      await container.read(quoteWebSocketProvider.future);
      await Future<void>.delayed(Duration.zero);

      // Close subscription first, then dispose container — triggers onDispose
      sub.close();
      container.dispose();

      verify(() => mockWsClient.unsubscribe(['AAPL'])).called(1);
    });
  });
}
