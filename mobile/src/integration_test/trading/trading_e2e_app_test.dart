import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/security/bio_challenge_service.dart';
import 'package:trading_app/core/security/nonce_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/trading/application/portfolio_summary_provider.dart';
import 'package:trading_app/features/trading/application/positions_provider.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/domain/entities/portfolio_summary.dart';
import 'package:trading_app/features/trading/domain/entities/position.dart';
import 'package:trading_app/features/trading/presentation/screens/order_entry_screen.dart';
import 'package:trading_app/features/trading/presentation/screens/order_list_screen.dart';
import 'package:trading_app/features/trading/presentation/widgets/slide_to_confirm_widget.dart';
import 'package:trading_app/features/trading/data/trading_repository_impl.dart';
import 'package:trading_app/features/trading/data/remote/trading_remote_data_source.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/core/security/hmac_signer.dart';
import 'package:trading_app/core/auth/device_info_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../helpers/test_app.dart';

/// Trading Module — E2E App Tests
///
/// **Purpose**: Verify complete user journeys from UI to API and back
/// **Dependencies**: Mock Server running on localhost:8080 + emulator/device
/// **Speed**: Moderate (~30 seconds)
/// **Run when**: Before releases, in CI/CD pipeline
///
/// Run:
///   cd mobile/mock-server && go run . --strategy=normal
///   cd mobile/src && flutter test integration_test/trading/trading_e2e_app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  // ── Journey 1: Authenticated user sees app ─────────────────────────────────

  testWidgets(
    'Journey 1: Authenticated user sees order list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: TestAppConfig.createAppWithAuth(
            accessToken: 'e2e-token-journey1',
            refreshToken: 'e2e-refresh-journey1',
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      debugPrint('✅ Journey 1: App launched with authenticated state');
    },
  );

  // ── Journey 2: Order entry screen renders ─────────────────────────────────

  testWidgets(
    'Journey 2: Order entry screen renders with symbol and side controls',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const OrderEntryScreen(
              symbol: 'AAPL',
              market: 'US',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(OrderEntryScreen), findsOneWidget);
      expect(find.text('买入'), findsWidgets);
      debugPrint('✅ Journey 2: OrderEntryScreen rendered for AAPL');
    },
  );

  // ── Journey 3: Order form input interactions ───────────────────────────────

  testWidgets(
    'Journey 3: User can enter qty and price on order form',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const OrderEntryScreen(
              symbol: 'AAPL',
              market: 'US',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // qty field
      await tester.enterText(textFields.at(0), '100');
      await tester.pump();

      // price field (for limit order default)
      await tester.enterText(textFields.at(1), '150.25');
      await tester.pump();

      expect(find.text('100'), findsOneWidget);
      expect(find.text('150.25'), findsOneWidget);
      debugPrint('✅ Journey 3: User entered qty=100 and price=150.25');
    },
  );

  // ── Journey 4: Order list screen loads from Mock Server ───────────────────

  testWidgets(
    'Journey 4: OrderListScreen loads orders from Mock Server',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const OrderListScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(OrderListScreen), findsOneWidget);
      // Preset orders from Mock Server: ord-001 AAPL FILLED, ord-002 TSLA PENDING
      expect(find.text('AAPL'), findsWidgets,
          reason: 'Preset order AAPL (ord-001) should be visible');
      expect(find.text('TSLA'), findsWidgets,
          reason: 'Preset order TSLA (ord-002) should be visible');
      debugPrint('✅ Journey 4: OrderListScreen rendered with AAPL + TSLA orders');
    },
  );

  // ── Journey 5: Order list supports rebuild without crash ───────────────────

  testWidgets(
    'Journey 5: Order list can rebuild and stay stable',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const OrderListScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // First build: verify data rendered
      expect(find.byType(OrderListScreen), findsOneWidget);
      expect(find.text('AAPL'), findsWidgets);

      // Force a rebuild
      await tester.pumpWidget(
        ProviderScope(
          overrides: _securityOverrides,
          child: MaterialApp(
            home: const OrderListScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Second build: orders still visible (no loss of data on rebuild)
      expect(find.byType(OrderListScreen), findsOneWidget);
      expect(find.text('AAPL'), findsWidgets,
          reason: 'AAPL order should still be visible after rebuild');
      debugPrint('✅ Journey 5: OrderListScreen rebuilt without data loss');
    },
  );

  // ── Journey 6: Sell qty cap — submit disabled when qty > availableQty ─────
  // P0-04: PRD-04 §6.3 + PRD-06 §6.2 unsettled shares must not be sellable.

  testWidgets(
    'Journey 6: Sell submit disabled when qty exceeds availableQty (P0-04)',
    (tester) async {
      // Render OrderEntryScreen in SELL mode with stubbed providers:
      //   positionsProvider: AAPL qty=100, availableQty=50 (50 shares T+1 unsettled)
      //   portfolioSummaryProvider: stub to avoid HTTP/SSL calls
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._securityOverrides,
            positionsProvider.overrideWith(_StubPositionsNotifier.new),
            portfolioSummaryProvider.overrideWith(_StubPortfolioSummaryNotifier.new),
          ],
          child: MaterialApp(
            home: const OrderEntryScreen(
              symbol: 'AAPL',
              market: 'US',
              initialSide: OrderSide.sell,
            ),
          ),
        ),
      );
      // Pump enough for positions to load and postFrameCallback to fire
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.pump(); // extra frame for addPostFrameCallback setState

      // Enter qty = 100 (> availableQty = 50) AND a valid limit price
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
      await tester.enterText(textFields.at(0), '100'); // qty
      await tester.enterText(textFields.at(1), '160.00'); // limit price
      await tester.pump();
      await tester.pumpAndSettle();

      // SlideToConfirmWidget opacity must be ≈0.4 (disabled) when qty > availableQty
      final slideWidget = find.byType(SlideToConfirmWidget);
      expect(slideWidget, findsOneWidget,
          reason: 'SlideToConfirmWidget must be present on sell order entry screen');
      final opacityWidget = tester.widget<Opacity>(
        find.ancestor(of: slideWidget, matching: find.byType(Opacity)).first,
      );
      expect(opacityWidget.opacity, closeTo(0.4, 0.05),
          reason: 'Submit must be visually disabled (opacity≈0.4) when sell qty(100) > availableQty(50)');
      debugPrint('✅ Journey 6: Sell qty=100 > availableQty=50 → submit disabled (opacity=${opacityWidget.opacity})');

      // Enter qty = 50 (== availableQty) with same valid price → submit should enable
      await tester.enterText(textFields.at(0), '50');
      await tester.pump();
      await tester.pumpAndSettle();

      final opacityEnabled = tester.widget<Opacity>(
        find.ancestor(of: find.byType(SlideToConfirmWidget), matching: find.byType(Opacity)).first,
      );
      expect(opacityEnabled.opacity, closeTo(1.0, 0.05),
          reason: 'Submit must be enabled when sell qty(50) == availableQty(50)');
      debugPrint('✅ Journey 6: Sell qty=50 == availableQty=50 → submit enabled (opacity=${opacityEnabled.opacity})');
    },
  );
}

// ─── Stub positions notifier — AAPL 100 qty / 50 availableQty ────────────────

class _StubPositionsNotifier extends PositionsNotifier {
  @override
  Future<List<Position>> build() async => [
        Position(
          symbol: 'AAPL',
          market: 'US',
          qty: 100,
          availableQty: 50, // 50 shares unsettled (T+1 pending) — not sellable
          avgCost: Decimal.parse('150.00'),
          currentPrice: Decimal.parse('160.00'),
          marketValue: Decimal.parse('16000.00'),
          unrealizedPnl: Decimal.parse('1000.00'),
          unrealizedPnlPct: Decimal.parse('6.67'),
          todayPnl: Decimal.parse('500.00'),
          todayPnlPct: Decimal.parse('3.23'),
        ),
      ];
}

// ─── Stub portfolio summary notifier — avoids HTTP/SSL calls in E2E ──────────

class _StubPortfolioSummaryNotifier extends PortfolioSummaryNotifier {
  @override
  Future<PortfolioSummary> build() async => PortfolioSummary(
        totalEquity: Decimal.parse('16000.00'),
        cashBalance: Decimal.parse('0.00'),
        marketValue: Decimal.parse('16000.00'),
        dayPnl: Decimal.parse('500.00'),
        dayPnlPct: Decimal.parse('3.23'),
        totalPnl: Decimal.parse('1000.00'),
        totalPnlPct: Decimal.parse('6.67'),
        buyingPower: Decimal.parse('0.00'),
        unsettledCash: Decimal.parse('0.00'),
      );
}

// ─── Security service overrides (real HTTP to Mock Server) ───────────────────
final _securityOverrides = [
  sessionKeyServiceProvider.overrideWith((ref) => _HttpSessionKeyService()),
  nonceServiceProvider.overrideWith((ref) => _HttpNonceService()),
  bioChallengeServiceProvider.overrideWith((ref) => _HttpBioChallengeService()),
  // Override tradingRepositoryProvider to use non-pinned Dio → avoids the
  // PLACEHOLDER SSL pin assertion that fires when DioClient.create() is called
  // in the normal provider setup. Journey 4/5 need real HTTP to mock server.
  tradingRepositoryProvider.overrideWith((ref) => TradingRepositoryImpl(
        remote: TradingRemoteDataSource(
          dio: _createDio(),
          signer: const HmacSigner(),
          connectivity: ConnectivityService(Connectivity()),
          sessionKeyService: ref.read(sessionKeyServiceProvider),
          nonceService: ref.read(nonceServiceProvider),
          deviceInfoService: DeviceInfoService(
            DeviceInfoPlugin(),
            const FlutterSecureStorage(),
          ),
        ),
      )),
];

Dio _createDio() => Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Authorization': 'Bearer e2e-test-token'},
    ));

/// In-memory SecureStorage stub — avoids mocktail null return issues.
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

class _HttpSessionKeyService extends SessionKeyService {
  _HttpSessionKeyService() : super(dio: _createDio(), storage: _MemoryStorage());
}

class _HttpNonceService extends NonceService {
  _HttpNonceService() : super(dio: _createDio());
}

class _HttpBioChallengeService extends BioChallengeService {
  _HttpBioChallengeService() : super(dio: _createDio());
}
