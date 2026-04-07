import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/application/quote_websocket_notifier.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockTokenService extends Mock implements TokenService {}

class MockQuoteWebSocketClient extends Mock implements QuoteWebSocketClient {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

WsQuoteUpdate makeUpdate(String symbol) => WsQuoteUpdate(
      frameType: WsFrameType.snapshot,
      symbol: symbol,
      quote: Quote(
        symbol: symbol,
        name: '$symbol Inc.',
        nameZh: '',
        market: 'US',
        price: Decimal.parse('150.0000'),
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
        delayed: false,
        marketStatus: MarketStatus.regular,
        isStale: false,
        staleSinceMs: 0,
      ),
    );

/// Builds a [ProviderContainer] pre-wired with a controllable mock WS client.
///
/// [onConnect] is called when the mock's `connect()` is invoked and should
/// complete the returned future with the desired [WsUserType].
ProviderContainer buildContainer({
  required MockTokenService mockToken,
  required MockQuoteWebSocketClient mockClient,
}) {
  return ProviderContainer(
    overrides: [
      tokenServiceProvider.overrideWithValue(mockToken),
      wsClientFactoryProvider.overrideWithValue((_) => mockClient),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Test suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() => AppLogger.init());

  late MockTokenService mockToken;
  late MockQuoteWebSocketClient mockClient;
  late StreamController<WsQuoteUpdate> quoteCtrl;

  setUp(() {
    mockToken = MockTokenService();
    mockClient = MockQuoteWebSocketClient();
    quoteCtrl = StreamController<WsQuoteUpdate>.broadcast(sync: true);

    when(() => mockClient.quoteStream).thenAnswer((_) => quoteCtrl.stream);
    when(() => mockClient.close()).thenAnswer((_) async {});
    when(() => mockClient.dispose()).thenAnswer((_) async {});
  });

  tearDown(() {
    quoteCtrl.close();
  });

  // ─── Initial connection ───────────────────────────────────────────────────

  group('build() — initial connection', () {
    test('returns WsUserType.registered when token is present', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      final result =
          await container.read(quoteWebSocketProvider.future);
      expect(result, WsUserType.registered);
    });

    test('returns WsUserType.guest when token is null', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.guest);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      final result =
          await container.read(quoteWebSocketProvider.future);
      expect(result, WsUserType.guest);
    });

    test('returns WsUserType.guest when token is empty string', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => '');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.guest);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      final result =
          await container.read(quoteWebSocketProvider.future);
      expect(result, WsUserType.guest);
      // token=null passed to client when empty
      verify(() => mockClient.connect(token: null)).called(1);
    });

    test('state has error when connect() throws NetworkException', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token'))).thenThrow(
        const NetworkException(message: 'connection refused'),
      );

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      // Listen so the provider activates; drain one microtask cycle.
      final sub = container.listen(quoteWebSocketProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      sub.close();

      // Riverpod 3.x keeps failed async notifiers in AsyncLoading(retrying)
      // OR AsyncError — either way, hasError must be true.
      expect(container.read(quoteWebSocketProvider).hasError, isTrue);
    });
  });

  // ─── subscribe / unsubscribe ──────────────────────────────────────────────

  group('subscribe() / unsubscribe()', () {
    late ProviderContainer container;

    setUp(() async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);
      when(() => mockClient.subscribe(any())).thenAnswer((_) async {});
      when(() => mockClient.unsubscribe(any())).thenReturn(null);

      container =
          buildContainer(mockToken: mockToken, mockClient: mockClient);
      await container.read(quoteWebSocketProvider.future);
    });

    tearDown(() => container.dispose());

    test('subscribe() calls client.subscribe', () async {
      final notifier =
          container.read(quoteWebSocketProvider.notifier);
      await notifier.subscribe(['AAPL', 'TSLA']);

      verify(() => mockClient.subscribe(['AAPL', 'TSLA'])).called(1);
    });

    test('subscribe() tracks subscribed symbols', () async {
      final notifier =
          container.read(quoteWebSocketProvider.notifier);
      await notifier.subscribe(['AAPL']);
      await notifier.subscribe(['TSLA']);

      expect(
          notifier.subscribedSymbols, containsAll(['AAPL', 'TSLA']));
    });

    test('subscribe() batches > 50 symbols into multiple calls', () async {
      final symbols = List.generate(55, (i) => 'S$i');
      final notifier =
          container.read(quoteWebSocketProvider.notifier);
      await notifier.subscribe(symbols);

      verify(() => mockClient.subscribe(any())).called(2);
    });

    test('unsubscribe() calls client.unsubscribe and removes from set',
        () async {
      final notifier =
          container.read(quoteWebSocketProvider.notifier);
      await notifier.subscribe(['AAPL', 'TSLA']);
      notifier.unsubscribe(['AAPL']);

      verify(() => mockClient.unsubscribe(['AAPL'])).called(1);
      expect(notifier.subscribedSymbols, isNot(contains('AAPL')));
      expect(notifier.subscribedSymbols, contains('TSLA'));
    });
  });

  // ─── quoteStream ──────────────────────────────────────────────────────────

  group('quoteStream', () {
    test('events from client are forwarded to quoteStream', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      final updates = <WsQuoteUpdate>[];
      final sub = notifier.quoteStream.listen(updates.add);

      quoteCtrl.add(makeUpdate('AAPL'));
      quoteCtrl.add(makeUpdate('TSLA'));

      await Future<void>.delayed(Duration.zero);
      sub.cancel();

      expect(updates.map((u) => u.symbol), ['AAPL', 'TSLA']);
    });
  });

  // ─── quoteUpdateProvider (family) ─────────────────────────────────────────

  group('quoteUpdateProvider(symbol)', () {
    test('emits only updates for the requested symbol', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final aaplUpdates = <WsQuoteUpdate>[];
      final sub = container.listen(
        quoteUpdateProvider('AAPL'),
        (_, next) => next.whenData(aaplUpdates.add),
      );

      quoteCtrl.add(makeUpdate('AAPL'));
      quoteCtrl.add(makeUpdate('TSLA')); // should be filtered out
      quoteCtrl.add(makeUpdate('AAPL'));

      await Future<void>.delayed(Duration.zero);
      sub.close();

      expect(aaplUpdates, hasLength(2));
      expect(aaplUpdates.every((u) => u.symbol == 'AAPL'), isTrue);
    });
  });

  // ─── reauthWithToken ──────────────────────────────────────────────────────

  group('reauthWithToken()', () {
    test('updates state to registered on successful reauth', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.guest);
      when(() => mockClient.reauth(any()))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      await notifier.reauthWithToken('new-jwt');

      expect(
        container.read(quoteWebSocketProvider).value,
        WsUserType.registered,
      );
    });

    test('transitions state to AsyncError on reauth AuthException', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);
      when(() => mockClient.reauth(any())).thenThrow(
        const AuthException(message: 'token invalid'),
      );

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      await notifier.reauthWithToken('bad-jwt');

      expect(container.read(quoteWebSocketProvider), isA<AsyncError<dynamic>>());
    });
  });

  // ─── AuthException from stream ────────────────────────────────────────────

  group('stream AuthException handling', () {
    test('AuthException from stream propagates to provider state', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final states = <AsyncValue<WsUserType>>[];
      final sub = container.listen(quoteWebSocketProvider, (_, s) => states.add(s));

      quoteCtrl.addError(const AuthException(message: 'token revoked'));
      await Future<void>.delayed(Duration.zero);
      sub.close();

      expect(states.last, isA<AsyncError<dynamic>>());
      expect(
        (states.last as AsyncError).error,
        isA<AuthException>(),
      );
    });
  });

  // ─── Reconnect ────────────────────────────────────────────────────────────

  group('reconnect on NetworkException', () {
    test('reconnects and resubscribes previous symbols after disconnect',
        () async {
      final secondQuoteCtrl =
          StreamController<WsQuoteUpdate>.broadcast(sync: true);
      final secondConnectCompleter = Completer<void>();

      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.subscribe(any())).thenAnswer((_) async {});

      var connectCount = 0;
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async {
        connectCount++;
        if (connectCount >= 2) {
          when(() => mockClient.quoteStream)
              .thenAnswer((_) => secondQuoteCtrl.stream);
          if (!secondConnectCompleter.isCompleted) {
            secondConnectCompleter.complete();
          }
        }
        return WsUserType.registered;
      });

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(() {
        container.dispose();
        secondQuoteCtrl.close();
      });

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      await notifier.subscribe(['AAPL', 'TSLA']);

      // Simulate disconnect — triggers reconnect with 1s backoff
      quoteCtrl
          .addError(const NetworkException(message: 'connection dropped'));

      // Wait for second connect (allow up to 5s for the 1s delay)
      await secondConnectCompleter.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero); // flush resubscribe

      // Connected twice: initial + reconnect
      verify(() => mockClient.connect(token: any(named: 'token'))).called(2);
      // Subscribed at least twice: initial subscribe + resubscribe after reconnect
      verify(() => mockClient.subscribe(any()))
          .called(greaterThanOrEqualTo(2));
    });

    test('state becomes AsyncError after stream emits max consecutive errors',
        () async {
      // Have the reconnect itself keep failing so we exhaust retries.
      // Initial connect succeeds; subsequent (reconnect) connects all throw.
      var connectCount = 0;
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async {
        connectCount++;
        if (connectCount == 1) return WsUserType.registered;
        throw const NetworkException(message: 'server down');
      });

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final states = <AsyncValue<WsUserType>>[];
      final sub = container.listen(
        quoteWebSocketProvider,
        (_, s) => states.add(s),
      );

      // Trigger the reconnect loop — each attempt uses 2^n second delay.
      // Flood with 3 errors to push reconnect attempts to limit quickly.
      quoteCtrl.addError(const NetworkException(message: 'drop 1'));
      quoteCtrl.addError(const NetworkException(message: 'drop 2'));
      quoteCtrl.addError(const NetworkException(message: 'drop 3'));

      // Total delay: 1 + 2 + 4 = 7s; allow 10s for safety.
      await Future<void>.delayed(const Duration(seconds: 10));
      sub.close();

      expect(
        states.any((s) => s.hasError),
        isTrue,
        reason: 'should enter error state after max reconnect attempts',
      );
    });
  });

  // ─── pause / resume ───────────────────────────────────────────────────────

  group('pause() / resume()', () {
    test('pause() calls client.close()', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      container.read(quoteWebSocketProvider.notifier).pause();

      verify(() => mockClient.close()).called(1);
    });

    test('resume() reconnects and transitions to data state', () async {
      final secondCtrl =
          StreamController<WsQuoteUpdate>.broadcast(sync: true);

      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');

      var connectCount = 0;
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async {
        connectCount++;
        if (connectCount > 1) {
          when(() => mockClient.quoteStream)
              .thenAnswer((_) => secondCtrl.stream);
        }
        return WsUserType.registered;
      });

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(() {
        container.dispose();
        secondCtrl.close();
      });

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      notifier.pause();
      await notifier.resume();

      expect(
        container.read(quoteWebSocketProvider).value,
        WsUserType.registered,
      );
      // Connected twice: initial + after resume
      verify(() => mockClient.connect(token: any(named: 'token'))).called(2);
    });

    test('pause() is idempotent — second call is a no-op', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      notifier.pause();
      notifier.pause(); // second call

      verify(() => mockClient.close()).called(1); // only once
    });

    test('resume() is a no-op when not paused', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockClient.connect(token: any(named: 'token')))
          .thenAnswer((_) async => WsUserType.registered);

      final container = buildContainer(
          mockToken: mockToken, mockClient: mockClient);
      addTearDown(container.dispose);

      await container.read(quoteWebSocketProvider.future);

      final notifier = container.read(quoteWebSocketProvider.notifier);
      await notifier.resume(); // never paused

      // No extra connect calls
      verify(() => mockClient.connect(token: any(named: 'token'))).called(1);
    });
  });
}
