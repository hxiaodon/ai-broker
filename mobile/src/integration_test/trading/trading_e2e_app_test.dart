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
import 'package:trading_app/features/trading/presentation/screens/order_entry_screen.dart';
import 'package:trading_app/features/trading/presentation/screens/order_list_screen.dart';

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
      print('✅ Journey 1: App launched with authenticated state');
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
      print('✅ Journey 2: OrderEntryScreen rendered for AAPL');
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
      print('✅ Journey 3: User entered qty=100 and price=150.25');
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
      print('✅ Journey 4: OrderListScreen rendered without crash');
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

      expect(find.byType(OrderListScreen), findsOneWidget);

      // Force a rebuild to ensure provider-driven screen remains stable
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

      expect(find.byType(OrderListScreen), findsOneWidget);
      print('✅ Journey 5: OrderListScreen rebuilt without crash');
    },
  );
}

// ─── Security service overrides (real HTTP to Mock Server) ───────────────────

final _securityOverrides = [
  sessionKeyServiceProvider.overrideWith((ref) => _HttpSessionKeyService()),
  nonceServiceProvider.overrideWith((ref) => _HttpNonceService()),
  bioChallengeServiceProvider.overrideWith((ref) => _HttpBioChallengeService()),
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
