/// Widget Test Helpers
///
/// Utilities for testing Riverpod-based Flutter widgets with proper
/// provider overrides and mock setup.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/features/auth/application/auth_notifier.dart';
import 'package:trading_app/features/market/application/watchlist_notifier.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/domain/repositories/watchlist_repository.dart';

/// Test app builder for widget tests with Riverpod provider overrides
class TestWidgetBuilder {
  /// Build a test app with authenticated user and mocked services
  static Widget buildAuthenticatedApp({
    required Widget child,
    required WatchlistRepository watchlistRepository,
    required TokenService tokenService,
    required QuoteWebSocketClient wsClient,
    String accountId = 'test-acc-123',
    String accountStatus = 'ACTIVE',
  }) {
    return ProviderScope(
      overrides: [
        // Auth state
        authProvider.overrideWithValue(
          AuthState.authenticated(
            accountId: accountId,
            accountStatus: accountStatus,
          ),
        ),
        // Market repositories and services
        watchlistRepositoryProvider.overrideWithValue(watchlistRepository),
        tokenServiceProvider.overrideWithValue(tokenService),
        wsClientFactoryProvider.overrideWithValue((_) => wsClient),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Build a test app with guest user
  static Widget buildGuestApp({
    required Widget child,
    required WatchlistRepository watchlistRepository,
    required TokenService tokenService,
    required QuoteWebSocketClient wsClient,
  }) {
    return ProviderScope(
      overrides: [
        // Guest state
        authProvider.overrideWithValue(const AuthState.guest()),
        // Market repositories and services
        watchlistRepositoryProvider.overrideWithValue(watchlistRepository),
        tokenServiceProvider.overrideWithValue(tokenService),
        wsClientFactoryProvider.overrideWithValue((_) => wsClient),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Build a test app with unauthenticated state
  static Widget buildUnauthenticatedApp({
    required Widget child,
    required TokenService tokenService,
  }) {
    return ProviderScope(
      overrides: [
        // Unauthenticated state
        authProvider.overrideWithValue(const AuthState.unauthenticated()),
        tokenServiceProvider.overrideWithValue(tokenService),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Common mock implementations for widget tests
class MockTokenServiceForWidget extends Mock implements TokenService {
  late String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _accessToken != null ? 'refresh-token' : null;
}
