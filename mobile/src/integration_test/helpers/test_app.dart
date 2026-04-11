import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/routing/app_router.dart';
import 'package:trading_app/features/auth/application/auth_notifier.dart';
import 'package:trading_app/shared/theme/app_theme.dart';
import 'package:trading_app/shared/theme/trading_color_scheme.dart';

/// Test app factory with dependency injection for integration tests
class TestAppConfig {
  /// Create full test app with router and optional auth state override
  static Widget createApp({
    TokenService? tokenService,
    AuthState? initialAuthState,
  }) {
    final overrides = [
      if (tokenService != null) tokenServiceProvider.overrideWithValue(tokenService),
      if (initialAuthState != null) authProvider.overrideWithValue(initialAuthState),
    ];

    return ProviderScope(
      overrides: overrides,
      child: const _TradingAppForTest(),
    );
  }

  /// Create app with pre-authenticated user
  static Widget createAppWithAuth({
    required String accessToken,
    required String refreshToken,
    TokenService? tokenService,
  }) {
    final tokenSvc = tokenService ?? MockTokenServiceForIntegration();
    if (tokenSvc is MockTokenServiceForIntegration) {
      tokenSvc.setTokens(accessToken: accessToken, refreshToken: refreshToken);
    }

    return TestAppConfig.createApp(
      tokenService: tokenSvc,
      initialAuthState: const AuthState.authenticated(
        accountId: 'test-acc-123',
        accountStatus: 'ACTIVE',
        biometricEnabled: false,
      ),
    );
  }

  /// Create app with guest mode enabled
  static Widget createAppAsGuest() {
    return TestAppConfig.createApp(
      initialAuthState: const AuthState.guest(),
    );
  }

  /// Create app with unauthenticated state (shows login screen)
  static Widget createAppUnauthenticated({
    TokenService? tokenService,
  }) {
    return TestAppConfig.createApp(
      tokenService: tokenService,
      initialAuthState: const AuthState.unauthenticated(),
    );
  }
}

/// Root widget matching TradingApp, used for testing
class _TradingAppForTest extends ConsumerWidget {
  const _TradingAppForTest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Trading App (Test)',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.build(
        colorScheme: TradingColorScheme.greenUp,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.build(
        colorScheme: TradingColorScheme.greenUp,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

// Exported mock token service

/// Mock TokenService for testing
class MockTokenServiceForIntegration implements TokenService {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  @override
  String? get cachedAccessToken => _accessToken;

  @override
  Future<void> loadCachedToken() async {}

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<DateTime?> getAccessTokenExpiry() async => _expiresAt;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<bool> isAccessTokenValid() async {
    if (_accessToken == null || _expiresAt == null) return false;
    return DateTime.now().isBefore(_expiresAt!);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = accessTokenExpiresAt;
  }

  // Test helpers
  void setTokens({
    required String accessToken,
    required String refreshToken,
    Duration expiresIn = const Duration(hours: 1),
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _expiresAt = DateTime.now().add(expiresIn);
  }

  void clearCache() {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
  }
}
