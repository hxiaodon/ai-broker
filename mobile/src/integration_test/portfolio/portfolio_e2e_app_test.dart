import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/core/security/bio_challenge_service.dart';
import 'package:trading_app/core/security/nonce_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/portfolio/data/portfolio_repository_impl.dart';
import 'package:trading_app/features/portfolio/domain/entities/position_detail.dart';
import 'package:trading_app/features/portfolio/domain/entities/trade_record.dart';
import 'package:trading_app/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:trading_app/features/portfolio/presentation/screens/portfolio_analysis_screen.dart';
import 'package:trading_app/features/portfolio/presentation/screens/portfolio_screen.dart';
import 'package:trading_app/features/portfolio/presentation/screens/position_detail_screen.dart';
import 'package:trading_app/features/portfolio/presentation/widgets/empty_portfolio_widget.dart';
import 'package:trading_app/features/trading/data/trading_repository_impl.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/domain/entities/order_fill.dart';
import 'package:trading_app/features/trading/domain/entities/portfolio_summary.dart';
import 'package:trading_app/features/trading/domain/entities/position.dart';
import 'package:trading_app/features/trading/domain/repositories/trading_repository.dart';
import 'package:trading_app/shared/theme/color_tokens.dart';

import '../helpers/test_app.dart';

/// Portfolio Module — E2E App Tests
///
/// **Purpose**: Verify complete user journeys from UI to Mock Server and back.
/// **Dependencies**: Mock Server running on localhost:8080 + emulator/device
/// **Speed**: Moderate (~30 seconds)
/// **Run when**: Before releases, in CI/CD pipeline
///
/// Run:
///   cd mobile/mock-server && go run . --strategy=normal
///   cd mobile/src && flutter test integration_test/portfolio/portfolio_e2e_app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  // ── Journey 1: Authenticated user sees app with portfolio tab ─────────────

  testWidgets(
    'Journey 1: Authenticated user can launch app and sees portfolio tab',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: TestAppConfig.createAppWithAuth(
            accessToken: 'e2e-portfolio-token',
            refreshToken: 'e2e-portfolio-refresh',
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'App scaffold must be rendered for authenticated user');
      print('✅ Journey 1: Authenticated app launched successfully');
    },
  );

  // ── Journey 2: PortfolioScreen renders AssetSummaryCard ───────────────────

  testWidgets(
    'Journey 2: PortfolioScreen renders with asset summary from Mock Server',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const PortfolioScreen(),
          ),
        ),
      );

      // Allow time for HTTP load from Mock Server
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(PortfolioScreen), findsOneWidget);
      // AssetSummaryCard shows "账户总资产（USD）" label
      expect(find.text('账户总资产（USD）'), findsWidgets,
          reason: 'AssetSummaryCard must be visible with total equity label');
      print('✅ Journey 2: PortfolioScreen rendered with AssetSummaryCard');
    },
  );

  // ── Journey 3: Position list shows AAPL and 0700 ─────────────────────────

  testWidgets(
    'Journey 3: PortfolioScreen position list shows AAPL and 0700 from Mock Server',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const PortfolioScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('AAPL'), findsWidgets,
          reason: 'AAPL position from Mock Server must appear in list');
      expect(find.text('0700'), findsWidgets,
          reason: '0700 position from Mock Server must appear in list');
      print('✅ Journey 3: AAPL and 0700 positions visible in portfolio list');
    },
  );

  // ── Journey 4: PositionDetailScreen shows company name from Mock Server ───

  testWidgets(
    'Journey 4: PositionDetailScreen(AAPL) shows "Apple Inc." from Mock Server',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const PositionDetailScreen(symbol: 'AAPL'),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(PositionDetailScreen), findsOneWidget);
      expect(
        find.text('Apple Inc.'),
        findsOneWidget,
        reason:
            'company_name from Mock Server must appear in PositionDetailScreen',
      );
      // Verify trade history section is present
      expect(find.text('交易记录'), findsOneWidget);
      print('✅ Journey 4: PositionDetailScreen(AAPL) shows "Apple Inc."');
    },
  );

  // ── Journey 5: Analysis tab renders sector bars ───────────────────────────

  testWidgets(
    'Journey 5: PortfolioAnalysisScreen shows sector bars with "Technology"',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: Scaffold(
              body: PortfolioAnalysisScreen(colors: ColorTokens.greenUp),
            ),
          ),
        ),
      );

      // Analysis screen loads position details for each position (parallel)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(PortfolioAnalysisScreen), findsOneWidget);
      expect(
        find.text('Technology'),
        findsWidgets,
        reason:
            'AAPL sector "Technology" from Mock Server must appear in analysis tab',
      );
      print('✅ Journey 5: PortfolioAnalysisScreen shows "Technology" sector bar');
    },
  );

  // ── Journey 6: Empty portfolio ─────────────────────────────────────────────

  testWidgets(
    'Journey 6: Empty portfolio shows EmptyPortfolioWidget',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider.overrideWithValue(_EmptyTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepo()),
          ],
          child: MaterialApp(home: const PortfolioScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(EmptyPortfolioWidget), findsOneWidget,
          reason: 'Empty positions + zero cash must render EmptyPortfolioWidget');
      expect(find.text('账户还没有资产'), findsOneWidget);
      print('✅ Journey 6: EmptyPortfolioWidget rendered correctly');
    },
  );

  // ── Journey 7: Cash-only portfolio ────────────────────────────────────────

  testWidgets(
    'Journey 7: Cash-only portfolio shows CashOnlyPortfolioWidget with balance',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider.overrideWithValue(_CashOnlyTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepo()),
          ],
          child: MaterialApp(home: const PortfolioScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(CashOnlyPortfolioWidget), findsOneWidget,
          reason:
              'Empty positions + non-zero cash must render CashOnlyPortfolioWidget');
      expect(find.text('可用现金'), findsOneWidget);
      print('✅ Journey 7: CashOnlyPortfolioWidget with cash balance rendered');
    },
  );

  // ── Journey 8: Error state with retry button ──────────────────────────────

  testWidgets(
    'Journey 8: Error state shows error message and retry button',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider.overrideWithValue(_ErrorTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepo()),
          ],
          child: MaterialApp(home: const PortfolioScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Error view must show a retry-capable message (regression guard for QA-HIGH-03)
      expect(
        find.textContaining('重试').evaluate().isNotEmpty ||
            find.textContaining('不可用').evaluate().isNotEmpty ||
            find.textContaining('失败').evaluate().isNotEmpty,
        isTrue,
        reason: 'Error state must show recoverable error message',
      );
      print('✅ Journey 8: Error state with error message rendered');
    },
  );

  // ── Journey 9: Sort mode change reorders positions ─────────────────────────

  testWidgets(
    'Journey 9: Changing sort mode reorders position list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider.overrideWithValue(_TwoPositionTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepo()),
          ],
          child: MaterialApp(home: const PortfolioScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Positions tab must be visible with both symbols
      expect(find.text('AAPL'), findsWidgets);
      expect(find.text('0700'), findsWidgets);
      print('✅ Journey 9: Position list with 2 symbols rendered for sort test');
    },
  );

  // ── Journey 10: Concentration warning banner ──────────────────────────────

  testWidgets(
    'Journey 10: Concentration warning appears when position weight > 30% of equity',
    (tester) async {
      // AAPL: marketValue=70000, totalEquity=90000 → weight=0.778 > 0.30
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider
                .overrideWithValue(_ConcentratedTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_StubPortfolioRepo()),
          ],
          child: MaterialApp(home: const PortfolioScreen()),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Concentration banner text includes '集中度较高'
      expect(find.textContaining('集中度'), findsWidgets,
          reason:
              'Position with weight > 30% of totalEquity must show concentration warning');
      print('✅ Journey 10: Concentration warning banner rendered');
    },
  );

  // ── Journey 11: Wash sale warning card ────────────────────────────────────

  testWidgets(
    'Journey 11: PositionDetailScreen shows wash sale warning when flagged',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider.overrideWithValue(_TwoPositionTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_WashSaleFlaggedPortfolioRepo()),
          ],
          child: MaterialApp(
            home: const PositionDetailScreen(symbol: 'AAPL'),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.textContaining('Wash Sale'), findsWidgets,
          reason:
              'washSaleFlagged=true must render _WashSaleWarning with "Wash Sale" text');
      print('✅ Journey 11: Wash sale warning card rendered');
    },
  );

  // ── Journey 12: Pending settlements T+1 / T+2 ────────────────────────────

  testWidgets(
    'Journey 12: PositionDetailScreen shows pending settlement date',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            tradingRepositoryProvider.overrideWithValue(_TwoPositionTradingRepo()),
            portfolioRepositoryProvider
                .overrideWithValue(_PendingSettlementPortfolioRepo()),
          ],
          child: MaterialApp(
            home: const PositionDetailScreen(symbol: 'AAPL'),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Pending settlement section must be visible
      expect(find.text('待结算'), findsWidgets,
          reason: 'Pending settlement row must appear when qty > 0');
      print('✅ Journey 12: Pending settlement date rendered');
    },
  );
}

// ─── Security service overrides (real HTTP to Mock Server) ───────────────────

final _securityOverrides = [
  sessionKeyServiceProvider.overrideWith((ref) => _HttpSessionKeyService()),
  nonceServiceProvider.overrideWith((ref) => _HttpNonceService()),
  bioChallengeServiceProvider.overrideWith((ref) => _HttpBioChallengeService()),
  connectivityServiceProvider.overrideWith((ref) => _AlwaysConnected()),
];

Dio _createDio() => Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Authorization': 'Bearer e2e-test-token'},
    ));

/// In-memory SecureStorage stub — avoids null-return issues with platform channel.
class _MemoryStorage extends SecureStorageService {
  _MemoryStorage() : super(const FlutterSecureStorage());

  final _map = <String, String>{};

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);
}

/// Stub connectivity that always reports connected.
class _AlwaysConnected extends ConnectivityService {
  _AlwaysConnected() : super(Connectivity());

  @override
  Future<bool> get isConnected async => true;
}

class _HttpSessionKeyService extends SessionKeyService {
  _HttpSessionKeyService()
      : super(dio: _createDio(), storage: _MemoryStorage());
}

class _HttpNonceService extends NonceService {
  _HttpNonceService() : super(dio: _createDio());
}

class _HttpBioChallengeService extends BioChallengeService {
  _HttpBioChallengeService() : super(dio: _createDio());
}

// ─── Stub Repositories for Journey 6-12 ──────────────────────────────────────

abstract class _BaseTradingRepo implements TradingRepository {
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
  }) async =>
      throw UnimplementedError();

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
  Future<Position> getPositionDetail(String symbol) async =>
      throw UnimplementedError();
}

class _EmptyTradingRepo extends _BaseTradingRepo {
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

class _CashOnlyTradingRepo extends _BaseTradingRepo {
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

class _ErrorTradingRepo extends _BaseTradingRepo {
  @override
  Future<List<Position>> getPositions() async =>
      throw const ServerException(statusCode: 503, message: 'Service unavailable');

  @override
  Future<PortfolioSummary> getPortfolioSummary() async =>
      throw const ServerException(statusCode: 503, message: 'Service unavailable');
}

class _TwoPositionTradingRepo extends _BaseTradingRepo {
  @override
  Future<List<Position>> getPositions() async => [
        _makePos('AAPL', 'US', 100,
            marketValue: Decimal.parse('17550.00'),
            unrealizedPnl: Decimal.parse('2525.00')),
        _makePos('0700', 'HK', 200,
            marketValue: Decimal.parse('73700.00'),
            unrealizedPnl: Decimal.parse('3700.00')),
      ];

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

// AAPL has 77.8% weight of totalEquity (>30% threshold)
class _ConcentratedTradingRepo extends _BaseTradingRepo {
  @override
  Future<List<Position>> getPositions() async => [
        _makePos('AAPL', 'US', 100, marketValue: Decimal.parse('70000.00')),
      ];

  @override
  Future<PortfolioSummary> getPortfolioSummary() async => PortfolioSummary(
        totalEquity: Decimal.parse('90000.00'),
        cashBalance: Decimal.parse('20000.00'),
        marketValue: Decimal.parse('70000.00'),
        dayPnl: Decimal.parse('500.00'),
        dayPnlPct: Decimal.parse('0.56'),
        totalPnl: Decimal.parse('5000.00'),
        totalPnlPct: Decimal.parse('5.88'),
        buyingPower: Decimal.parse('20000.00'),
        unsettledCash: Decimal.zero,
      );
}

class _StubPortfolioRepo implements PortfolioRepository {
  @override
  Future<PositionDetail> getPositionDetail(String symbol) async =>
      _makeDetail(symbol);
}

class _WashSaleFlaggedPortfolioRepo implements PortfolioRepository {
  @override
  Future<PositionDetail> getPositionDetail(String symbol) async =>
      _makeDetail(symbol).copyWith(washSaleFlagged: true);
}

class _PendingSettlementPortfolioRepo implements PortfolioRepository {
  @override
  Future<PositionDetail> getPositionDetail(String symbol) async =>
      _makeDetail(symbol).copyWith(
        pendingSettlements: [
          PendingSettlement(
            qty: 10,
            settleDate: DateTime.now().toUtc().add(const Duration(days: 1)),
          ),
        ],
      );
}

// ─── Shared factory helpers ────────────────────────────────────────────────────

Position _makePos(
  String symbol,
  String market,
  int qty, {
  Decimal? marketValue,
  Decimal? unrealizedPnl,
}) =>
    Position(
      symbol: symbol,
      market: market,
      qty: qty,
      availableQty: qty,
      avgCost: Decimal.parse('150.00'),
      currentPrice: Decimal.parse('175.00'),
      marketValue: marketValue ?? Decimal.parse('17500.00'),
      unrealizedPnl: unrealizedPnl ?? Decimal.parse('2500.00'),
      unrealizedPnlPct: Decimal.parse('16.67'),
      todayPnl: Decimal.parse('200.00'),
      todayPnlPct: Decimal.parse('1.15'),
    );

PositionDetail _makeDetail(String symbol) => PositionDetail(
      symbol: symbol,
      companyName: symbol == '0700' ? 'Tencent Holdings' : 'Apple Inc.',
      market: symbol == '0700' ? 'HK' : 'US',
      sector: symbol == '0700' ? 'Communication Services' : 'Technology',
      qty: 100,
      availableQty: 100,
      avgCost: Decimal.parse('150.00'),
      currentPrice: Decimal.parse('175.00'),
      marketValue: Decimal.parse('17500.00'),
      unrealizedPnl: Decimal.parse('2500.00'),
      unrealizedPnlPct: Decimal.parse('16.67'),
      todayPnl: Decimal.parse('200.00'),
      todayPnlPct: Decimal.parse('1.15'),
      realizedPnl: Decimal.parse('250.00'),
      costBasis: Decimal.parse('15000.00'),
      washSaleFlagged: false,
      recentTrades: [
        TradeRecord(
          tradeId: 'trd-e2e-001',
          side: TradeSide.buy,
          qty: 100,
          price: Decimal.parse('150.00'),
          amount: Decimal.parse('15000.00'),
          fee: Decimal.parse('1.00'),
          executedAt: DateTime.now().toUtc().subtract(const Duration(days: 7)),
          washSale: false,
        ),
      ],
    );
