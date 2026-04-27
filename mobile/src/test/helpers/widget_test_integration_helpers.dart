// Widget Test Integration Helpers
//
// Provides simplified test app builders that handle all Riverpod setup
// and allow focusing on the widget behavior being tested.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/features/auth/application/auth_notifier.dart';
import 'package:trading_app/features/market/application/quote_websocket_notifier.dart';
import 'package:trading_app/features/market/data/watchlist_repository_impl.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/repositories/watchlist_repository.dart';

// Mocks
class _MockWatchlistRepository extends Mock implements WatchlistRepository {}

class _MockTokenService extends Mock implements TokenService {}

class _MockQuoteWebSocketClient extends Mock implements QuoteWebSocketClient {}

// Simplified test app builder with sensible defaults
class WidgetTestIntegrationHelper {
  /// Build authenticated test app with minimal boilerplate
  static Widget buildAuthenticatedApp({
    required Widget child,
    Future<List<Quote>> Function()? watchlistItems,
    String accountId = 'test-acc-123',
    String accountStatus = 'ACTIVE',
  }) {
    final mockRepo = _MockWatchlistRepository();
    final mockToken = _MockTokenService();
    final mockWsClient = _MockQuoteWebSocketClient();

    // Setup default mocks
    when(() => mockToken.getAccessToken())
        .thenAnswer((_) async => 'test-token');
    when(() => mockRepo.getWatchlist()).thenAnswer(
      (_) => watchlistItems?.call() ?? Future.value([]),
    );
    when(() => mockWsClient.connect(token: any(named: 'token')))
        .thenAnswer((_) async => WsUserType.registered);
    when(() => mockWsClient.quoteStream).thenAnswer((_) => Stream.empty());
    when(() => mockWsClient.subscribe(any())).thenAnswer((_) async {});
    when(() => mockWsClient.unsubscribe(any())).thenReturn(null);
    when(() => mockWsClient.close()).thenAnswer((_) async {});
    when(() => mockWsClient.dispose()).thenAnswer((_) async {});

    return ProviderScope(
      overrides: [
        authProvider.overrideWithValue(
          AuthState.authenticated(
            accountId: accountId,
            accountStatus: accountStatus,
            biometricEnabled: false,
          ),
        ),
        watchlistRepositoryProvider.overrideWithValue(mockRepo),
        tokenServiceProvider.overrideWithValue(mockToken),
        wsClientFactoryProvider.overrideWithValue((_) => mockWsClient),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Build guest test app with minimal boilerplate
  static Widget buildGuestApp({
    required Widget child,
    Future<List<Quote>> Function()? watchlistItems,
  }) {
    final mockRepo = _MockWatchlistRepository();
    final mockToken = _MockTokenService();
    final mockWsClient = _MockQuoteWebSocketClient();

    // Setup default mocks
    when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
    when(() => mockRepo.getWatchlist()).thenAnswer(
      (_) => watchlistItems?.call() ?? Future.value([]),
    );
    when(() => mockWsClient.connect(token: any(named: 'token')))
        .thenAnswer((_) async => WsUserType.guest);
    when(() => mockWsClient.quoteStream).thenAnswer((_) => Stream.empty());
    when(() => mockWsClient.subscribe(any())).thenAnswer((_) async {});
    when(() => mockWsClient.unsubscribe(any())).thenReturn(null);
    when(() => mockWsClient.close()).thenAnswer((_) async {});
    when(() => mockWsClient.dispose()).thenAnswer((_) async {});

    return ProviderScope(
      overrides: [
        authProvider.overrideWithValue(const AuthState.guest()),
        watchlistRepositoryProvider.overrideWithValue(mockRepo),
        tokenServiceProvider.overrideWithValue(mockToken),
        wsClientFactoryProvider.overrideWithValue((_) => mockWsClient),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Build unauthenticated test app
  static Widget buildUnauthenticatedApp({
    required Widget child,
  }) {
    final mockToken = _MockTokenService();

    when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);

    return ProviderScope(
      overrides: [
        authProvider.overrideWithValue(const AuthState.unauthenticated()),
        tokenServiceProvider.overrideWithValue(mockToken),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
