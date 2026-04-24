import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/core/security/bio_challenge_service.dart';
import 'package:trading_app/core/security/nonce_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/portfolio/presentation/screens/portfolio_analysis_screen.dart';
import 'package:trading_app/features/portfolio/presentation/screens/portfolio_screen.dart';
import 'package:trading_app/features/portfolio/presentation/screens/position_detail_screen.dart';
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
