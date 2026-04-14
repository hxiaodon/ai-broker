import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/application/quote_websocket_notifier.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/application/watchlist_notifier.dart';
import 'package:trading_app/features/market/data/local/watchlist_local_datasource.dart';
import 'package:trading_app/features/market/data/watchlist_repository_impl.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/repositories/watchlist_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

class MockTokenService extends Mock implements TokenService {}

class MockQuoteWebSocketClient extends Mock implements QuoteWebSocketClient {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Quote makeQuote(String symbol, {String price = '150.0000', bool delayed = false}) =>
    Quote(
      symbol: symbol,
      name: '$symbol Inc.',
      nameZh: '',
      market: 'US',
      price: Decimal.parse(price),
      change: Decimal.parse('1.0000'),
      changePct: Decimal.parse('0.0067'),
      volume: 1000000,
      bid: Decimal.parse('149.9900'),
      ask: Decimal.parse('150.0100'),
      turnover: '150M',
      prevClose: Decimal.parse('149.0000'),
      open: Decimal.parse('149.5000'),
      high: Decimal.parse('151.0000'),
      low: Decimal.parse('148.5000'),
      marketCap: '2.8T',
      delayed: delayed,
      marketStatus: MarketStatus.regular,
    );

WsQuoteUpdate makeSnapshot(String symbol, {String price = '155.0000'}) =>
    WsQuoteUpdate(
      frameType: WsFrameType.snapshot,
      symbol: symbol,
      quote: makeQuote(symbol, price: price),
    );

WsQuoteUpdate makeTick(String symbol, {String price = '160.0000'}) =>
    WsQuoteUpdate(
      frameType: WsFrameType.tick,
      symbol: symbol,
      quote: makeQuote(symbol, price: price),
    );

/// Builds a [ProviderContainer] with mocked WS client and watchlist repository.
ProviderContainer buildContainer({
  required MockWatchlistRepository mockRepo,
  required MockTokenService mockToken,
  required MockQuoteWebSocketClient mockWsClient,
  required StreamController<WsQuoteUpdate> wsStream,
}) {
  return ProviderContainer(
    overrides: [
      // WatchlistRepository
      watchlistRepositoryProvider.overrideWith((_) => mockRepo),
      // WS infrastructure
      tokenServiceProvider.overrideWithValue(mockToken),
      wsClientFactoryProvider.overrideWithValue((_) => mockWsClient),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Test suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  late MockWatchlistRepository mockRepo;
  late MockTokenService mockToken;
  late MockQuoteWebSocketClient mockWsClient;
  late StreamController<WsQuoteUpdate> wsStream;

  setUp(() {
    mockRepo = MockWatchlistRepository();
    mockToken = MockTokenService();
    mockWsClient = MockQuoteWebSocketClient();
    wsStream = StreamController<WsQuoteUpdate>.broadcast(sync: true);

    // Default WS stubs
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
    test('returns watchlist from repository', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      final result = await container.read(watchlistProvider.future);

      expect(result.map((q) => q.symbol), ['AAPL', 'TSLA']);
    });

    test('subscribes loaded symbols to WS once connected', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);
      // Wait for WS ready → subscribe
      await Future<void>.delayed(Duration.zero);

      // At least one subscribe call with AAPL and TSLA
      final captured =
          verify(() => mockWsClient.subscribe(captureAny())).captured;
      final allSymbols =
          captured.expand((b) => b as List<String>).toSet();
      expect(allSymbols, containsAll(['AAPL', 'TSLA']));
    });

    test('empty watchlist does not call subscribe', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer((_) async => []);

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockWsClient.subscribe(any()));
    });
  });

  // ─── Live quote patching ──────────────────────────────────────────────────

  group('live quote patching', () {
    late ProviderContainer container;

    setUp(() async {
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );
      container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      await container.read(watchlistProvider.future);
      // Wait for WS pipe to be fully established (async connect + pipeClientEvents)
      await container.read(quoteWebSocketProvider.future);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() => container.dispose());

    test('SNAPSHOT update patches the quote price', () async {
      wsStream.add(makeSnapshot('AAPL', price: '175.0000'));
      await Future<void>.delayed(Duration.zero);

      final quotes = container.read(watchlistProvider).value!;
      final aapl = quotes.firstWhere((q) => q.symbol == 'AAPL');
      expect(aapl.price, Decimal.parse('175.0000'));
    });

    test('TICK update patches only the price field', () async {
      // Initial price: 150
      wsStream.add(makeTick('AAPL', price: '160.0000'));
      await Future<void>.delayed(Duration.zero);

      final quotes = container.read(watchlistProvider).value!;
      final aapl = quotes.firstWhere((q) => q.symbol == 'AAPL');
      expect(aapl.price, Decimal.parse('160.0000'));
      // Static fields preserved (prevClose unchanged)
      expect(aapl.prevClose, Decimal.parse('149.0000'));
    });

    test('updates do NOT affect other symbols', () async {
      wsStream.add(makeSnapshot('AAPL', price: '200.0000'));
      await Future<void>.delayed(Duration.zero);

      final quotes = container.read(watchlistProvider).value!;
      final tsla = quotes.firstWhere((q) => q.symbol == 'TSLA');
      expect(tsla.price, Decimal.parse('150.0000')); // unchanged
    });

    test('WS update for symbol not in watchlist is silently ignored', () async {
      final before = container.read(watchlistProvider).value!;

      wsStream.add(makeSnapshot('MSFT', price: '300.0000'));
      await Future<void>.delayed(Duration.zero);

      final after = container.read(watchlistProvider).value!;
      // State unchanged
      expect(after.map((q) => q.price).toList(),
          before.map((q) => q.price).toList());
    });
  });

  // ─── add() ───────────────────────────────────────────────────────────────

  group('add()', () {
    test('calls repository.addToWatchlist and refreshes state', () async {
      when(() => mockRepo.getWatchlist())
          .thenAnswer((_) async => [makeQuote('AAPL')]);
      when(() => mockRepo.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          )).thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);

      // Change repo to return extended list after add
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );

      await container.read(watchlistProvider.notifier)
          .add(symbol: 'TSLA', market: 'US');

      final result = await container.read(watchlistProvider.future);
      expect(result.map((q) => q.symbol), ['AAPL', 'TSLA']);
      verify(() => mockRepo.addToWatchlist(symbol: 'TSLA', market: 'US'))
          .called(1);
    });

    test('throws ValidationException when 100-symbol limit is reached',
        () async {
      final bigList = List.generate(100, (i) => makeQuote('S$i'));
      when(() => mockRepo.getWatchlist())
          .thenAnswer((_) async => bigList);

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);

      expect(
        () => container
            .read(watchlistProvider.notifier)
            .add(symbol: 'NEW', market: 'US'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('99 items: add succeeds (no limit violation)', () async {
      final nearFullList = List.generate(99, (i) => makeQuote('S$i'));
      when(() => mockRepo.getWatchlist())
          .thenAnswer((_) async => nearFullList);
      when(() => mockRepo.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          )).thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);
      when(() => mockRepo.getWatchlist())
          .thenAnswer((_) async => [
                ...nearFullList,
                makeQuote('NEW'),
              ]);

      await expectLater(
        container
            .read(watchlistProvider.notifier)
            .add(symbol: 'NEW', market: 'US'),
        completes,
      );
    });
  });

  // ─── remove() ────────────────────────────────────────────────────────────

  group('remove()', () {
    test('calls repository.removeFromWatchlist and unsubscribes from WS',
        () async {
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );
      when(() => mockRepo.removeFromWatchlist(any()))
          .thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);
      when(() => mockRepo.getWatchlist())
          .thenAnswer((_) async => [makeQuote('TSLA')]);

      await container
          .read(watchlistProvider.notifier)
          .remove('AAPL');

      verify(() => mockRepo.removeFromWatchlist('AAPL')).called(1);
      verify(() => mockWsClient.unsubscribe(['AAPL'])).called(1);
      final result = await container.read(watchlistProvider.future);
      expect(result.map((q) => q.symbol), ['TSLA']);
    });
  });

  // ─── reorder() ───────────────────────────────────────────────────────────

  group('reorder()', () {
    test('persists new order and updates state immediately', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async =>
            [makeQuote('AAPL'), makeQuote('TSLA'), makeQuote('MSFT')],
      );
      when(() => mockRepo.reorderWatchlist(any()))
          .thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);

      await container
          .read(watchlistProvider.notifier)
          .reorder(['TSLA', 'MSFT', 'AAPL']);

      verify(() => mockRepo.reorderWatchlist(['TSLA', 'MSFT', 'AAPL']))
          .called(1);
      // Optimistic state update
      final current = container.read(watchlistProvider).value!;
      expect(current.map((q) => q.symbol), ['TSLA', 'MSFT', 'AAPL']);
    });

    test('unknown symbols in new order are silently dropped', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );
      when(() => mockRepo.reorderWatchlist(any()))
          .thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);

      await container
          .read(watchlistProvider.notifier)
          .reorder(['TSLA', 'UNKNOWN', 'AAPL']);

      final current = container.read(watchlistProvider).value!;
      expect(current.map((q) => q.symbol), ['TSLA', 'AAPL']);
    });
  });

  // ─── importGuestItems() ───────────────────────────────────────────────────

  group('importGuestItems()', () {
    test('calls addToWatchlist for each guest item and refreshes', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer((_) async => []);
      when(() => mockRepo.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          )).thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);
      when(() => mockRepo.getWatchlist()).thenAnswer(
        (_) async => [makeQuote('AAPL'), makeQuote('TSLA')],
      );

      await container.read(watchlistProvider.notifier).importGuestItems([
        const WatchlistItem(symbol: 'AAPL', market: 'US'),
        const WatchlistItem(symbol: 'TSLA', market: 'US'),
      ]);

      verify(() => mockRepo.addToWatchlist(symbol: 'AAPL', market: 'US'))
          .called(1);
      verify(() => mockRepo.addToWatchlist(symbol: 'TSLA', market: 'US'))
          .called(1);
      final result = await container.read(watchlistProvider.future);
      expect(result.length, 2);
    });

    test('failed individual item import is silently skipped', () async {
      when(() => mockRepo.getWatchlist()).thenAnswer((_) async => []);
      // First item fails
      when(() => mockRepo.addToWatchlist(symbol: 'AAPL', market: 'US'))
          .thenThrow(const NetworkException(message: 'server error'));
      when(() => mockRepo.addToWatchlist(symbol: 'TSLA', market: 'US'))
          .thenAnswer((_) async {});

      final container = buildContainer(
        mockRepo: mockRepo,
        mockToken: mockToken,
        mockWsClient: mockWsClient,
        wsStream: wsStream,
      );
      addTearDown(container.dispose);

      await container.read(watchlistProvider.future);
      when(() => mockRepo.getWatchlist())
          .thenAnswer((_) async => [makeQuote('TSLA')]);

      // Should complete without throwing
      await expectLater(
        container.read(watchlistProvider.notifier).importGuestItems([
          const WatchlistItem(symbol: 'AAPL', market: 'US'),
          const WatchlistItem(symbol: 'TSLA', market: 'US'),
        ]),
        completes,
      );

      // TSLA should still be added
      verify(() => mockRepo.addToWatchlist(symbol: 'TSLA', market: 'US'))
          .called(1);
    });
  });
}
