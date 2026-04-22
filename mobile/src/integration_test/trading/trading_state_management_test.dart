import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/security/bio_challenge_service.dart';
import 'package:trading_app/core/security/nonce_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/trading/application/order_submit_notifier.dart';
import 'package:trading_app/features/trading/application/orders_notifier.dart';
import 'package:trading_app/features/trading/application/portfolio_summary_provider.dart';
import 'package:trading_app/features/trading/application/positions_provider.dart';
import 'package:trading_app/features/trading/data/trading_repository_impl.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/domain/entities/order_fill.dart';
import 'package:trading_app/features/trading/domain/entities/portfolio_summary.dart';
import 'package:trading_app/features/trading/domain/entities/position.dart';
import 'package:trading_app/features/trading/domain/repositories/trading_repository.dart';

import '../helpers/test_app.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Trading Module — State Management Tests
///
/// **Purpose**: Verify Riverpod providers, state machines, and app state
/// **Dependencies**: None (no Mock Server, no HTTP calls)
/// **Speed**: Very fast (~30 seconds)
/// **Run when**: After every code change
///
/// All network calls are replaced with in-memory stub implementations.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => AppLogger.init());

  group('Trading Module - App States', () {
    testWidgets(
      'T1: Authenticated user can reach trading screen',
      (tester) async {
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-trading-test',
            refreshToken: 'refresh-trading-test',
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(Scaffold), findsWidgets);
        print('✅ T1: Authenticated state renders trading-capable app');
      },
    );
  });

  group('Trading Module - OrderSubmitState Machine', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(_StubTradingRepository()),
          sessionKeyServiceProvider.overrideWithValue(_StubSessionKeyService()),
          nonceServiceProvider.overrideWithValue(_StubNonceService()),
          bioChallengeServiceProvider.overrideWithValue(_StubBioChallengeService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('T2: Initial state is idle', () {
      final state = container.read(orderSubmitProvider);
      expect(state, isA<OrderSubmitState>());
      state.when(
        idle: () => print('✅ T2: OrderSubmitState initial = idle'),
        awaitingBiometric: () => fail('Expected idle'),
        submitting: () => fail('Expected idle'),
        success: (_) => fail('Expected idle'),
        error: (_) => fail('Expected idle'),
      );
    });

    test('T3: submit() transitions idle → submitting → success', () async {
      final notifier = container.read(orderSubmitProvider.notifier);

      await notifier.submit(
        symbol: 'AAPL',
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.limit,
        qty: 100,
        limitPrice: Decimal.parse('150.25'),
        validity: OrderValidity.day,
        extendedHours: false,
        biometricEnabled: false,
      );

      final state = container.read(orderSubmitProvider);
      state.when(
        idle: () => fail('Expected success'),
        awaitingBiometric: () => fail('Expected success'),
        submitting: () => fail('Expected success'),
        success: (orderId) {
          expect(orderId, isNotEmpty);
          print('✅ T3: idle → submitting → success (orderId: $orderId)');
        },
        error: (msg) => fail('Expected success, got error: $msg'),
      );
    });

    test('T4: reset() returns state to idle after success', () async {
      final notifier = container.read(orderSubmitProvider.notifier);
      await notifier.submit(
        symbol: 'AAPL',
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.market,
        qty: 10,
        validity: OrderValidity.day,
        extendedHours: false,
        biometricEnabled: false,
      );

      notifier.reset();
      container.read(orderSubmitProvider).when(
        idle: () => print('✅ T4: reset() returns to idle'),
        awaitingBiometric: () => fail('Expected idle after reset'),
        submitting: () => fail('Expected idle after reset'),
        success: (_) => fail('Expected idle after reset'),
        error: (_) => fail('Expected idle after reset'),
      );
    });

    test('T5: submit() transitions to error when repository throws', () async {
      final errorContainer = ProviderContainer(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(_ErrorTradingRepository()),
          sessionKeyServiceProvider.overrideWithValue(_StubSessionKeyService()),
          nonceServiceProvider.overrideWithValue(_StubNonceService()),
          bioChallengeServiceProvider.overrideWithValue(_StubBioChallengeService()),
        ],
      );
      addTearDown(errorContainer.dispose);

      final notifier = errorContainer.read(orderSubmitProvider.notifier);
      await notifier.submit(
        symbol: 'AAPL',
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.market,
        qty: 10,
        validity: OrderValidity.day,
        extendedHours: false,
        biometricEnabled: false,
      );

      errorContainer.read(orderSubmitProvider).when(
        idle: () => fail('Expected error'),
        awaitingBiometric: () => fail('Expected error'),
        submitting: () => fail('Expected error'),
        success: (_) => fail('Expected error'),
        error: (msg) => print('✅ T5: repository error → OrderSubmitState.error: $msg'),
      );
    });
  });

  group('Trading Module - Provider Loading States', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(_StubTradingRepository()),
          sessionKeyServiceProvider.overrideWithValue(_StubSessionKeyService()),
          nonceServiceProvider.overrideWithValue(_StubNonceService()),
          bioChallengeServiceProvider.overrideWithValue(_StubBioChallengeService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('T6: ordersProvider loads orders list', () async {
      final orders = await container.read(ordersProvider().future);
      expect(orders, isA<List<Order>>());
      expect(orders, hasLength(2));
      expect(orders.first.symbol, 'AAPL');
      print('✅ T6: ordersProvider loaded ${orders.length} orders');
    });

    test('T7: positionsProvider loads positions list', () async {
      final positions = await container.read(positionsProvider.future);
      expect(positions, isA<List<Position>>());
      expect(positions, hasLength(2));
      expect(positions.first.symbol, 'AAPL');
      print('✅ T7: positionsProvider loaded ${positions.length} positions');
    });

    test('T8: portfolioSummaryProvider loads portfolio summary', () async {
      final summary = await container.read(portfolioSummaryProvider.future);
      expect(summary, isA<PortfolioSummary>());
      expect(summary.totalEquity, greaterThan(Decimal.zero));
      print('✅ T8: portfolioSummaryProvider loaded (equity: ${summary.totalEquity})');
    });
  });
}

// ─── Stub implementations ─────────────────────────────────────────────────────

class _StubSessionKeyService extends SessionKeyService {
  _StubSessionKeyService() : super(dio: MockDio(), storage: MockSecureStorageService());

  @override
  Future<SessionKey> getSessionKey() async =>
      (keyId: 'sk-stub-001', secret: 'stub-secret-for-testing');

  @override
  Future<SessionKey> rotate() => getSessionKey();

  @override
  Future<void> clear() async {}
}

class _StubNonceService extends NonceService {
  _StubNonceService() : super(dio: MockDio());

  @override
  Future<String> fetchNonce() async =>
      'n-stub-nonce-${DateTime.now().millisecondsSinceEpoch}';
}

class _StubBioChallengeService extends BioChallengeService {
  _StubBioChallengeService() : super(dio: MockDio());

  @override
  Future<String> fetchChallenge() async => 'stub-challenge-abc123';
}

class _StubTradingRepository implements TradingRepository {
  @override
  Future<Order> submitOrder({
    required String symbol,
    required String market,
    required OrderSide side,
    required OrderType orderType,
    required int qty,
    Decimal? limitPrice,
    required OrderValidity validity,
    required bool extendedHours,
    required String idempotencyKey,
    required String biometricToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) async {
    return Order(
      orderId: 'ord-stub-${DateTime.now().millisecondsSinceEpoch}',
      symbol: symbol,
      market: market,
      side: side,
      orderType: orderType,
      status: OrderStatus.pending,
      qty: qty,
      filledQty: 0,
      limitPrice: limitPrice,
      avgFillPrice: null,
      validity: validity,
      extendedHours: extendedHours,
      fees: OrderFees(
        commission: Decimal.zero,
        exchangeFee: Decimal.zero,
        secFee: Decimal.zero,
        finraFee: Decimal.zero,
        total: Decimal.zero,
      ),
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> cancelOrder(String orderId) async {}

  @override
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? market,
  }) async {
    return [
      _makeOrder('ord-001', 'AAPL', OrderStatus.filled),
      _makeOrder('ord-002', 'TSLA', OrderStatus.pending),
    ];
  }

  @override
  Future<(Order, List<OrderFill>)> getOrderDetail(String orderId) async {
    return (_makeOrder(orderId, 'AAPL', OrderStatus.filled), <OrderFill>[]);
  }

  @override
  Future<List<Position>> getPositions() async {
    return [
      _makePosition('AAPL', 'US', 100),
      _makePosition('0700', 'HK', 200),
    ];
  }

  @override
  Future<Position> getPositionDetail(String symbol) async {
    return _makePosition(symbol, 'US', 100);
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary() async {
    return PortfolioSummary(
      totalEquity: Decimal.parse('96282.20'),
      cashBalance: Decimal.parse('5032.20'),
      marketValue: Decimal.parse('91250.00'),
      dayPnl: Decimal.parse('1070.00'),
      dayPnlPct: Decimal.parse('1.12'),
      totalPnl: Decimal.parse('7425.50'),
      totalPnlPct: Decimal.parse('8.35'),
      buyingPower: Decimal.parse('10064.40'),
      settledCash: Decimal.parse('0.00'),
    );
  }

  Order _makeOrder(String id, String symbol, OrderStatus status) => Order(
        orderId: id,
        symbol: symbol,
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.limit,
        status: status,
        qty: 100,
        filledQty: status == OrderStatus.filled ? 100 : 0,
        limitPrice: Decimal.parse('150.25'),
        avgFillPrice:
            status == OrderStatus.filled ? Decimal.parse('150.25') : null,
        validity: OrderValidity.day,
        extendedHours: false,
        fees: OrderFees(
          commission: Decimal.zero,
          exchangeFee: Decimal.zero,
          secFee: Decimal.zero,
          finraFee: Decimal.zero,
          total: Decimal.zero,
        ),
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

  Position _makePosition(String symbol, String market, int qty) => Position(
        symbol: symbol,
        market: market,
        qty: qty,
        availableQty: qty,
        avgCost: Decimal.parse('150.25'),
        currentPrice: Decimal.parse('175.50'),
        marketValue: Decimal.parse('17550.00'),
        unrealizedPnl: Decimal.parse('2525.00'),
        unrealizedPnlPct: Decimal.parse('16.81'),
        todayPnl: Decimal.parse('230.00'),
        todayPnlPct: Decimal.parse('1.33'),
      );
}

class _ErrorTradingRepository extends _StubTradingRepository {
  @override
  Future<Order> submitOrder({
    required String symbol,
    required String market,
    required OrderSide side,
    required OrderType orderType,
    required int qty,
    Decimal? limitPrice,
    required OrderValidity validity,
    required bool extendedHours,
    required String idempotencyKey,
    required String biometricToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) async {
    throw Exception('Simulated network error');
  }
}
