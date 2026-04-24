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
import 'package:trading_app/features/portfolio/application/pnl_ranking_provider.dart';
import 'package:trading_app/features/portfolio/application/position_detail_provider.dart';
import 'package:trading_app/features/portfolio/application/sector_allocation_provider.dart';
import 'package:trading_app/features/portfolio/data/portfolio_repository_impl.dart';
import 'package:trading_app/features/portfolio/domain/entities/position_detail.dart';
import 'package:trading_app/features/portfolio/domain/entities/sector_allocation.dart';
import 'package:trading_app/features/portfolio/domain/entities/trade_record.dart';
import 'package:trading_app/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:trading_app/features/trading/application/portfolio_summary_provider.dart';
import 'package:trading_app/features/trading/application/positions_provider.dart';
import 'package:trading_app/features/trading/application/trading_ws_notifier.dart';
import 'package:trading_app/features/trading/data/trading_repository_impl.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/domain/entities/order_fill.dart';
import 'package:trading_app/features/trading/domain/entities/portfolio_summary.dart';
import 'package:trading_app/features/trading/domain/entities/position.dart';
import 'package:trading_app/features/trading/domain/repositories/trading_repository.dart';

import '../helpers/test_app.dart';

class MockDio extends Mock implements Dio {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Portfolio Module — State Management Tests
///
/// **Purpose**: Verify Riverpod providers, derived state, and WS updates
/// **Dependencies**: None (no Mock Server, no HTTP calls)
/// **Speed**: Very fast (~30 seconds)
/// **Run when**: After every code change
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => AppLogger.init());

  // ── App States ─────────────────────────────────────────────────────────────

  group('Portfolio Module - App States', () {
    testWidgets(
      'TP1: Authenticated user can access portfolio tab',
      (tester) async {
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-portfolio-test',
            refreshToken: 'refresh-portfolio-test',
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(Scaffold), findsWidgets);
        print('✅ TP1: Authenticated state renders portfolio-capable app');
      },
    );
  });

  // ── Provider Loading States ────────────────────────────────────────────────

  group('Portfolio Module - Provider Loading States', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(_StubTradingRepository()),
          portfolioRepositoryProvider
              .overrideWithValue(_StubPortfolioRepository()),
          sessionKeyServiceProvider.overrideWithValue(_StubSessionKeyService()),
          nonceServiceProvider.overrideWithValue(_StubNonceService()),
          bioChallengeServiceProvider
              .overrideWithValue(_StubBioChallengeService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('TP2: positionsProvider loads 2 positions (AAPL + 0700)', () async {
      final positions = await container.read(positionsProvider.future);
      expect(positions, isA<List<Position>>());
      expect(positions, hasLength(2));
      expect(positions.first.symbol, 'AAPL');
      expect(positions.first.qty, 100);
      expect(positions.last.symbol, '0700');
      expect(positions.last.qty, 200);
      print('✅ TP2: positionsProvider loaded ${positions.length} positions');
    });

    test(
      'TP3: portfolioSummaryProvider returns totalEquity = 96282.20',
      () async {
        final summary = await container.read(portfolioSummaryProvider.future);
        expect(summary, isA<PortfolioSummary>());
        expect(summary.totalEquity, Decimal.parse('96282.20'));
        expect(summary.cashBalance, greaterThan(Decimal.zero));
        print(
          '✅ TP3: portfolioSummaryProvider totalEquity = ${summary.totalEquity}',
        );
      },
    );

    test(
      'TP4: positionDetailProvider(AAPL) returns correct entity fields',
      () async {
        final detail =
            await container.read(positionDetailProvider('AAPL').future);
        expect(detail, isA<PositionDetail>());
        expect(detail.symbol, 'AAPL');
        expect(detail.companyName, 'Apple Inc.');
        expect(detail.sector, 'Technology');
        expect(detail.washSaleFlagged, isFalse);
        expect(detail.recentTrades, hasLength(1));
        expect(detail.recentTrades.first.side, TradeSide.buy);
        expect(detail.unrealizedPnl, greaterThan(Decimal.zero));
        print(
          '✅ TP4: positionDetailProvider(AAPL) returned PositionDetail '
          'companyName="${detail.companyName}" sector="${detail.sector}"',
        );
      },
    );

    test(
      'TP5: positionDetailProvider overlays WS currentPrice from positionsProvider',
      () async {
        // Bootstrap positions so positionsProvider has data
        await container.read(positionsProvider.future);

        // Inject WS update with a new currentPrice for AAPL
        final newPrice = Decimal.parse('200.00');
        container.read(tradingWsProvider.notifier).injectPositionUpdate(
              TradingWsPositionUpdate(
                position: _makePosition('AAPL', 'US', 100,
                    currentPrice: newPrice),
              ),
            );

        // Allow stream listener to process the update
        await Future<void>.microtask(() {});

        final detail =
            await container.read(positionDetailProvider('AAPL').future);
        expect(detail.currentPrice, newPrice,
            reason:
                'positionDetailProvider must overlay WS currentPrice on top of REST data');
        print(
          '✅ TP5: positionDetailProvider overlaid WS currentPrice = $newPrice',
        );
      },
    );
  });

  // ── Derived Providers ─────────────────────────────────────────────────────

  group('Portfolio Module - Derived Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(_StubTradingRepository()),
          portfolioRepositoryProvider
              .overrideWithValue(_StubPortfolioRepository()),
          sessionKeyServiceProvider.overrideWithValue(_StubSessionKeyService()),
          nonceServiceProvider.overrideWithValue(_StubNonceService()),
          bioChallengeServiceProvider
              .overrideWithValue(_StubBioChallengeService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
      'TP6: pnlRankingProvider sorts positions by unrealizedPnl descending',
      () async {
        final ranked = await container.read(pnlRankingProvider.future);
        expect(ranked, isA<List<Position>>());
        expect(ranked, hasLength(2));
        // AAPL unrealizedPnl=2525, 0700=3700 → 0700 first
        expect(ranked.first.unrealizedPnl,
            greaterThanOrEqualTo(ranked.last.unrealizedPnl),
            reason: 'Positions must be sorted by unrealizedPnl descending');
        print(
          '✅ TP6: pnlRanking[0]=${ranked.first.symbol} '
          'pnl=${ranked.first.unrealizedPnl}',
        );
      },
    );

    test(
      'TP7: sectorAllocationProvider aggregates sectors, weights sum to 1.0',
      () async {
        final allocations =
            await container.read(sectorAllocationProvider.future);
        expect(allocations, isA<List<SectorAllocation>>());
        expect(allocations, hasLength(2),
            reason: 'AAPL (Technology) and 0700 (Communication Services)');

        final totalWeight = allocations.fold<Decimal>(
          Decimal.zero,
          (acc, s) => acc + s.weight,
        );
        // Allow small rounding tolerance
        expect(totalWeight.toDouble(), closeTo(1.0, 0.001),
            reason: 'All sector weights must sum to 1.0');

        final tech =
            allocations.where((a) => a.sector == 'Technology').firstOrNull;
        expect(tech, isNotNull, reason: 'Technology sector must be present');
        // AAPL marketValue=17550 / total(17550+73700) = 0.192
        expect(tech!.weight.toDouble(), closeTo(0.192, 0.01));
        print(
          '✅ TP7: sectorAllocation weights sum = $totalWeight '
          '(Technology = ${tech.weight})',
        );
      },
    );

    test(
      'TP8: sectorAllocationProvider with single-position stub → weight == 1.0',
      () async {
        final singleContainer = ProviderContainer(
          overrides: [
            tradingRepositoryProvider.overrideWithValue(
              _SinglePositionTradingRepository(),
            ),
            portfolioRepositoryProvider.overrideWithValue(
              _SinglePositionPortfolioRepository(),
            ),
            sessionKeyServiceProvider
                .overrideWithValue(_StubSessionKeyService()),
            nonceServiceProvider.overrideWithValue(_StubNonceService()),
            bioChallengeServiceProvider
                .overrideWithValue(_StubBioChallengeService()),
          ],
        );
        addTearDown(singleContainer.dispose);

        final allocations =
            await singleContainer.read(sectorAllocationProvider.future);
        expect(allocations, hasLength(1));
        expect(allocations.first.weight.toDouble(), closeTo(1.0, 0.001),
            reason: 'Single sector must have weight = 1.0');
        print(
          '✅ TP8: Single-sector weight = ${allocations.first.weight}',
        );
      },
    );
  });

  // ── WS Position Updates ───────────────────────────────────────────────────

  group('Portfolio Module - WS Position Updates', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(_StubTradingRepository()),
          portfolioRepositoryProvider
              .overrideWithValue(_StubPortfolioRepository()),
          sessionKeyServiceProvider.overrideWithValue(_StubSessionKeyService()),
          nonceServiceProvider.overrideWithValue(_StubNonceService()),
          bioChallengeServiceProvider
              .overrideWithValue(_StubBioChallengeService()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
      'TP9: injectPositionUpdate for known symbol patches AAPL in-place',
      () async {
        await container.read(positionsProvider.future);
        final initialAapl =
            container.read(positionsProvider).value!.first;
        expect(initialAapl.currentPrice, Decimal.parse('175.50'));

        final updatedPrice = Decimal.parse('190.00');
        container.read(tradingWsProvider.notifier).injectPositionUpdate(
              TradingWsPositionUpdate(
                position: _makePosition('AAPL', 'US', 100,
                    currentPrice: updatedPrice),
              ),
            );

        await Future<void>.microtask(() {});

        final updated = container.read(positionsProvider).value;
        expect(updated, isNotNull);
        final patchedAapl =
            updated!.where((p) => p.symbol == 'AAPL').firstOrNull;
        expect(patchedAapl, isNotNull);
        expect(patchedAapl!.currentPrice, updatedPrice,
            reason: 'WS update must patch AAPL currentPrice in-place');
        print(
          '✅ TP9: WS patch AAPL currentPrice ${initialAapl.currentPrice} → $updatedPrice',
        );
      },
    );

    test(
      'TP10: injectPositionUpdate for unknown symbol (NVDA) appends to list',
      () async {
        await container.read(positionsProvider.future);
        final initialCount =
            container.read(positionsProvider).value!.length;

        container.read(tradingWsProvider.notifier).injectPositionUpdate(
              TradingWsPositionUpdate(
                position: _makePosition('NVDA', 'US', 10),
              ),
            );

        await Future<void>.microtask(() {});

        final updated = container.read(positionsProvider).value;
        expect(updated, isNotNull);
        expect(updated!.length, initialCount + 1,
            reason:
                'Unknown symbol WS update must append a new position entry');
        expect(updated.any((p) => p.symbol == 'NVDA'), isTrue);
        print(
          '✅ TP10: NVDA appended, positions count $initialCount → ${updated.length}',
        );
      },
    );
  });

  // ── Empty Portfolio States ─────────────────────────────────────────────────

  group('Portfolio Module - Empty Portfolio States', () {
    test(
      'TP11: No positions + no cash → providers return empty / zero state',
      () async {
        final container = ProviderContainer(
          overrides: [
            tradingRepositoryProvider
                .overrideWithValue(_EmptyTradingRepository()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepository()),
            sessionKeyServiceProvider
                .overrideWithValue(_StubSessionKeyService()),
            nonceServiceProvider.overrideWithValue(_StubNonceService()),
            bioChallengeServiceProvider
                .overrideWithValue(_StubBioChallengeService()),
          ],
        );
        addTearDown(container.dispose);

        final positions = await container.read(positionsProvider.future);
        final summary =
            await container.read(portfolioSummaryProvider.future);

        expect(positions, isEmpty,
            reason: 'No positions state must yield empty list');
        expect(summary.cashBalance, Decimal.zero,
            reason: 'No-cash state must yield zero cashBalance');
        print('✅ TP11: Empty portfolio state verified');
      },
    );

    test(
      'TP12: No positions + has cash → positions empty, summary has non-zero cash',
      () async {
        final container = ProviderContainer(
          overrides: [
            tradingRepositoryProvider
                .overrideWithValue(_CashOnlyTradingRepository()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepository()),
            sessionKeyServiceProvider
                .overrideWithValue(_StubSessionKeyService()),
            nonceServiceProvider.overrideWithValue(_StubNonceService()),
            bioChallengeServiceProvider
                .overrideWithValue(_StubBioChallengeService()),
          ],
        );
        addTearDown(container.dispose);

        final positions = await container.read(positionsProvider.future);
        final summary =
            await container.read(portfolioSummaryProvider.future);

        expect(positions, isEmpty);
        expect(summary.cashBalance, greaterThan(Decimal.zero),
            reason:
                'Cash-only state must have non-zero cashBalance for UI branch');
        print(
          '✅ TP12: Cash-only state: positions empty, cash = ${summary.cashBalance}',
        );
      },
    );
  });
}

// ─── Stub implementations ─────────────────────────────────────────────────────

class _StubSessionKeyService extends SessionKeyService {
  _StubSessionKeyService()
      : super(dio: MockDio(), storage: MockSecureStorageService());

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
      'n-stub-${DateTime.now().millisecondsSinceEpoch}';
}

class _StubBioChallengeService extends BioChallengeService {
  _StubBioChallengeService() : super(dio: MockDio());

  @override
  Future<String> fetchChallenge() async => 'stub-challenge-abc123';
}

// ─── Trading repository stubs ─────────────────────────────────────────────────

class _StubTradingRepository implements TradingRepository {
  @override
  Future<(Order, String?)> submitOrder({
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
    throw UnimplementedError();
  }

  @override
  Future<void> cancelOrder(String orderId,
          {required String idempotencyKey}) async =>
      throw UnimplementedError();

  @override
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? market,
  }) async =>
      [];

  @override
  Future<(Order, List<OrderFill>)> getOrderDetail(String orderId) async =>
      throw UnimplementedError();

  @override
  Future<List<Position>> getPositions() async => [
        _makePosition('AAPL', 'US', 100),
        _makePosition('0700', 'HK', 200,
            currentPrice: Decimal.parse('368.50'),
            marketValue: Decimal.parse('73700.00'),
            unrealizedPnl: Decimal.parse('3700.00'),
            unrealizedPnlPct: Decimal.parse('5.29'),
            todayPnl: Decimal.parse('840.00'),
            todayPnlPct: Decimal.parse('1.15')),
      ];

  @override
  Future<Position> getPositionDetail(String symbol) async =>
      _makePosition(symbol, 'US', 100);

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => PortfolioSummary(
        totalEquity: Decimal.parse('96282.20'),
        cashBalance: Decimal.parse('5032.20'),
        marketValue: Decimal.parse('91250.00'),
        dayPnl: Decimal.parse('1070.00'),
        dayPnlPct: Decimal.parse('1.12'),
        totalPnl: Decimal.parse('7425.50'),
        totalPnlPct: Decimal.parse('8.35'),
        buyingPower: Decimal.parse('10064.40'),
        unsettledCash: Decimal.parse('0.00'),
      );
}

class _EmptyTradingRepository extends _StubTradingRepository {
  @override
  Future<List<Position>> getPositions() async => [];

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => PortfolioSummary(
        totalEquity: Decimal.zero,
        cashBalance: Decimal.zero,
        marketValue: Decimal.zero,
        dayPnl: Decimal.zero,
        dayPnlPct: Decimal.zero,
        totalPnl: Decimal.zero,
        totalPnlPct: Decimal.zero,
        buyingPower: Decimal.zero,
        unsettledCash: Decimal.zero,
      );
}

class _CashOnlyTradingRepository extends _StubTradingRepository {
  @override
  Future<List<Position>> getPositions() async => [];

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => PortfolioSummary(
        totalEquity: Decimal.parse('5000.00'),
        cashBalance: Decimal.parse('5000.00'),
        marketValue: Decimal.zero,
        dayPnl: Decimal.zero,
        dayPnlPct: Decimal.zero,
        totalPnl: Decimal.zero,
        totalPnlPct: Decimal.zero,
        buyingPower: Decimal.parse('5000.00'),
        unsettledCash: Decimal.zero,
      );
}

class _SinglePositionTradingRepository extends _StubTradingRepository {
  @override
  Future<List<Position>> getPositions() async =>
      [_makePosition('AAPL', 'US', 100)];
}

// ─── Portfolio repository stubs ───────────────────────────────────────────────

class _StubPortfolioRepository implements PortfolioRepository {
  @override
  Future<PositionDetail> getPositionDetail(String symbol) async {
    if (symbol == '0700') return _makeDetail('0700', 'Tencent Holdings', 200);
    return _makeDetail('AAPL', 'Apple Inc.', 100);
  }
}

class _SinglePositionPortfolioRepository implements PortfolioRepository {
  @override
  Future<PositionDetail> getPositionDetail(String symbol) async =>
      _makeDetail('AAPL', 'Apple Inc.', 100);
}

// ─── Shared factory helpers ────────────────────────────────────────────────────

Position _makePosition(
  String symbol,
  String market,
  int qty, {
  Decimal? currentPrice,
  Decimal? marketValue,
  Decimal? unrealizedPnl,
  Decimal? unrealizedPnlPct,
  Decimal? todayPnl,
  Decimal? todayPnlPct,
}) =>
    Position(
      symbol: symbol,
      market: market,
      qty: qty,
      availableQty: qty,
      avgCost: Decimal.parse('150.25'),
      currentPrice: currentPrice ?? Decimal.parse('175.50'),
      marketValue: marketValue ?? Decimal.parse('17550.00'),
      unrealizedPnl: unrealizedPnl ?? Decimal.parse('2525.00'),
      unrealizedPnlPct: unrealizedPnlPct ?? Decimal.parse('16.81'),
      todayPnl: todayPnl ?? Decimal.parse('230.00'),
      todayPnlPct: todayPnlPct ?? Decimal.parse('1.33'),
    );

PositionDetail _makeDetail(
  String symbol,
  String companyName,
  int qty,
) {
  final isHK = symbol == '0700';
  return PositionDetail(
    symbol: symbol,
    companyName: companyName,
    market: isHK ? 'HK' : 'US',
    sector: isHK ? 'Communication Services' : 'Technology',
    qty: qty,
    availableQty: qty,
    avgCost: isHK ? Decimal.parse('350.00') : Decimal.parse('150.25'),
    currentPrice: isHK ? Decimal.parse('368.50') : Decimal.parse('175.50'),
    marketValue: isHK ? Decimal.parse('73700.00') : Decimal.parse('17550.00'),
    unrealizedPnl: isHK ? Decimal.parse('3700.00') : Decimal.parse('2525.00'),
    unrealizedPnlPct:
        isHK ? Decimal.parse('5.29') : Decimal.parse('16.81'),
    todayPnl: isHK ? Decimal.parse('840.00') : Decimal.parse('230.00'),
    todayPnlPct: isHK ? Decimal.parse('1.15') : Decimal.parse('1.33'),
    realizedPnl:
        isHK ? Decimal.zero : Decimal.parse('250.00'),
    costBasis: isHK ? Decimal.parse('70000.00') : Decimal.parse('15025.00'),
    washSaleFlagged: false,
    recentTrades: [
      TradeRecord(
        tradeId: 'trd-${symbol.toLowerCase()}-001',
        side: TradeSide.buy,
        qty: qty,
        price: isHK ? Decimal.parse('350.00') : Decimal.parse('150.25'),
        amount: isHK ? Decimal.parse('70000.00') : Decimal.parse('15025.00'),
        fee: Decimal.parse('1.00'),
        executedAt: DateTime.now().toUtc().subtract(const Duration(days: 7)),
        washSale: false,
      ),
    ],
  );
}
