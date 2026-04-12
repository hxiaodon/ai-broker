import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../data/websocket/quote_websocket_client.dart';

part 'quote_websocket_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

String get _wsUrl {
  final baseWsUrl = EnvironmentConfig.instance.wsBaseUrl;
  return '$baseWsUrl/v1/market/quotes';
}

const _kMaxReconnectAttempts = 3;
const _kSymbolBatchSize = 50;

// ─────────────────────────────────────────────────────────────────────────────
// Factory provider (injectable for tests)
// ─────────────────────────────────────────────────────────────────────────────

/// Factory for creating [QuoteWebSocketClient] instances.
///
/// Override this provider in tests to inject a mock client.
typedef WsClientFactory = QuoteWebSocketClient Function(String wsUrl);

@Riverpod(keepAlive: true)
WsClientFactory wsClientFactory(Ref ref) {
  return (wsUrl) => QuoteWebSocketClient(wsUrl: wsUrl);
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteWebSocketNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the lifecycle of a [QuoteWebSocketClient] connection and exposes a
/// persistent broadcast stream of [WsQuoteUpdate] events to the UI layer.
///
/// ## Connection lifecycle
/// - `build()` connects immediately using the current access token (or guest).
/// - On connection loss ([NetworkException]), an exponential-backoff reconnect
///   loop runs up to [_kMaxReconnectAttempts] times, then transitions to
///   [AsyncError].
/// - `pause()` / `resume()` allow the caller (e.g. app lifecycle handler) to
///   gracefully disconnect while backgrounded and reconnect on foreground.
///
/// ## Dual-track quotes
/// - Registered users → real-time TICK/SNAPSHOT frames.
/// - Guest users → T-15 min DELAYED snapshots every 5 s.
///   Both share the same [quoteStream]; callers inspect [WsQuoteUpdate.frameType].
///
/// ## Subscribing to symbols
/// ```dart
/// final notifier = ref.read(quoteWebSocketNotifierProvider.notifier);
/// await notifier.subscribe(['AAPL', 'TSLA']);
/// ```
///
/// ## Listening to per-symbol updates
/// Use [quoteUpdateProvider] which filters by symbol:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((u) => /* handle WsQuoteUpdate */);
/// });
/// ```
@Riverpod(keepAlive: true)
class QuoteWebSocketNotifier extends _$QuoteWebSocketNotifier {
  QuoteWebSocketClient? _client;

  /// Persistent broadcast stream that outlives individual WS connections.
  ///
  /// Events are piped from each new [QuoteWebSocketClient] instance.
  final _outputController = StreamController<WsQuoteUpdate>.broadcast();
  StreamSubscription<WsQuoteUpdate>? _pipeSubscription;

  /// Symbols to re-subscribe after a reconnect.
  final Set<String> _subscribedSymbols = {};

  int _reconnectAttempts = 0;
  bool _paused = false;

  /// Last error for reconnect logging
  Object? _lastError;

  @override
  Future<WsUserType> build() async {
    ref.onDispose(_dispose);
    return _connectWithToken();
  }

  void _dispose() {
    _pipeSubscription?.cancel();
    _client?.dispose();
    _outputController.close();
    _client = null;
  }

  // ─── Connection ───────────────────────────────────────────────────────────

  Future<WsUserType> _connectWithToken() async {
    final token = await ref.read(tokenServiceProvider).getAccessToken();
    final factory = ref.read(wsClientFactoryProvider);
    final client = factory(_wsUrl);

    final userType = await client.connect(
      token: (token == null || token.isEmpty) ? null : token,
    );

    _client = client;
    _reconnectAttempts = 0;
    _pipeClientEvents(client);

    AppLogger.debug('QuoteWS: connected as $userType');
    return userType;
  }

  void _pipeClientEvents(QuoteWebSocketClient client) {
    _pipeSubscription?.cancel();
    _pipeSubscription = client.quoteStream.listen(
      _outputController.add,
      onError: _onClientError,
      cancelOnError: false,
    );
  }

  // ─── Error & reconnect ────────────────────────────────────────────────────

  void _onClientError(Object error) {
    _lastError = error;

    if (error is WsTokenExpiringException) {
      _handleTokenExpiring(error);
    } else if (error is NetworkException) {
      _outputController.addError(error);
      _scheduleReconnect();
    } else if (error is AuthException) {
      _outputController.addError(error);
      state = AsyncError(error, StackTrace.current);
    } else {
      _outputController.addError(error);
    }
  }

  Future<void> _handleTokenExpiring(WsTokenExpiringException ex) async {
    AppLogger.debug(
        'QuoteWS: token expiring in ${ex.expiresInSeconds}s — reauthenticating');
    try {
      final token = await ref.read(tokenServiceProvider).getAccessToken();
      if (token != null && token.isNotEmpty && _client != null) {
        final userType = await _client!.reauth(token);
        state = AsyncData(userType);
        AppLogger.info('QuoteWS: reauth successful');
      } else {
        throw AuthException(message: 'No valid token available for reauth');
      }
    } on Object catch (e, stack) {
      AppLogger.error('QuoteWS: reauth on token_expiring failed', error: e, stackTrace: stack);

      // Set error state so UI can show warning
      state = AsyncError(
        AuthException(message: '行情认证失败，请重新登录'),
        stack,
      );

      // Close connection to trigger reconnect
      await _client?.close();
    }
  }

  Future<void> _scheduleReconnect() async {
    if (_paused) return;

    if (_reconnectAttempts >= _kMaxReconnectAttempts) {
      final errorType = _lastError?.runtimeType ?? 'Unknown';
      AppLogger.error(
        'QuoteWS: max reconnect attempts reached after $errorType',
      );
      state = AsyncError(
        const NetworkException(message: '行情连接失败，请检查网络后重试'),
        StackTrace.current,
      );
      return;
    }

    final delay = Duration(seconds: pow(2, _reconnectAttempts).toInt());
    _reconnectAttempts++;

    final reason = _lastError is NetworkException
        ? (_lastError as NetworkException).message
        : _lastError?.toString() ?? 'unknown';

    AppLogger.debug(
      'QuoteWS: reconnecting in ${delay.inSeconds}s '
      '(attempt $_reconnectAttempts/$_kMaxReconnectAttempts) '
      'reason: $reason',
    );

    await Future<void>.delayed(delay);
    if (_paused) return;

    try {
      await _reconnectInternal();
    } on Object catch (e) {
      AppLogger.warning(
          'QuoteWS: reconnect attempt $_reconnectAttempts failed: $e');
      _scheduleReconnect();
    }
  }

  Future<void> _reconnectInternal() async {
    final prevSymbols = Set<String>.from(_subscribedSymbols);
    _subscribedSymbols.clear();

    _pipeSubscription?.cancel();
    await _client?.dispose();

    final token = await ref.read(tokenServiceProvider).getAccessToken();
    final factory = ref.read(wsClientFactoryProvider);
    final newClient = factory(_wsUrl);

    final userType = await newClient.connect(
      token: (token == null || token.isEmpty) ? null : token,
    );

    _client = newClient;
    _reconnectAttempts = 0;
    _pipeClientEvents(newClient);

    if (prevSymbols.isNotEmpty) {
      await _subscribeInternal(prevSymbols.toList());
    }

    state = AsyncData(userType);
    AppLogger.info('QuoteWS: reconnected successfully as $userType');
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Persistent stream of [WsQuoteUpdate] for all subscribed symbols.
  ///
  /// Survives individual WS reconnects — consumers never need to re-listen.
  Stream<WsQuoteUpdate> get quoteStream => _outputController.stream;

  /// Subscribe to real-time (or delayed) quotes for [symbols].
  ///
  /// Automatically batches into groups of [_kSymbolBatchSize] (50) per the
  /// server limit.
  Future<void> subscribe(List<String> symbols) async {
    if (symbols.isEmpty) return;
    await _subscribeInternal(symbols);
  }

  Future<void> _subscribeInternal(List<String> symbols) async {
    if (_client == null) return;
    for (var i = 0; i < symbols.length; i += _kSymbolBatchSize) {
      final batch = symbols.sublist(i, min(i + _kSymbolBatchSize, symbols.length));
      await _client!.subscribe(batch);
      _subscribedSymbols.addAll(batch);
    }
    AppLogger.debug('QuoteWS: subscribed to ${symbols.length} symbols: ${symbols.join(", ")}');
  }

  /// Unsubscribe from [symbols].
  void unsubscribe(List<String> symbols) {
    if (symbols.isEmpty) return;
    _client?.unsubscribe(symbols);
    _subscribedSymbols.removeAll(symbols);
    AppLogger.debug('QuoteWS: unsubscribed from ${symbols.length} symbols');
  }

  /// Re-authenticate with a refreshed [newToken].
  ///
  /// Typically called after the app's auth module renews the JWT, or after
  /// a guest user logs in (guest → registered upgrade).
  Future<void> reauthWithToken(String newToken) async {
    if (_client == null) return;
    try {
      final userType = await _client!.reauth(newToken);
      state = AsyncData(userType);
    } on AuthException catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  /// Disconnect the WebSocket to save battery when the app is backgrounded.
  ///
  /// Existing subscriptions are remembered for [resume()].
  void pause() {
    if (_paused) return;
    _paused = true;
    AppLogger.debug('QuoteWS: paused (app backgrounded)');
    _pipeSubscription?.cancel();
    _client?.close();
  }

  /// Reconnect and re-subscribe after the app returns to the foreground.
  Future<void> resume() async {
    if (!_paused) return;
    _paused = false;
    AppLogger.debug('QuoteWS: resuming (app foregrounded)');
    _reconnectAttempts = 0;
    state = const AsyncLoading();
    try {
      await _reconnectInternal();
    } on Object catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ─── Test helpers ─────────────────────────────────────────────────────────

  /// The set of currently subscribed symbols.
  @visibleForTesting
  Set<String> get subscribedSymbols => Set.unmodifiable(_subscribedSymbols);
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-symbol stream provider
// ─────────────────────────────────────────────────────────────────────────────

/// A [StreamProvider.family] that filters the global [QuoteWebSocketNotifier]
/// stream to updates for a single [symbol].
///
/// The stream emits even if the notifier is in [AsyncLoading] state (no events
/// are lost — WS must be subscribed first via [QuoteWebSocketNotifier.subscribe]).
///
/// Example:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((update) => handleTick(update));
/// });
/// ```
@riverpod
Stream<WsQuoteUpdate> quoteUpdate(Ref ref, String symbol) {
  final notifier = ref.watch(quoteWebSocketProvider.notifier);
  return notifier.quoteStream.where((WsQuoteUpdate u) => u.symbol == symbol);
}
