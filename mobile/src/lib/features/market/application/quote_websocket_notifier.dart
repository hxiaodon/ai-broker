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
// Connection State Machine
// ─────────────────────────────────────────────────────────────────────────────

enum QuoteWebSocketConnectionState {
  disconnected,
  connecting,
  authenticating,
  connected,
  reconnecting,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending Operations Queue
// ─────────────────────────────────────────────────────────────────────────────

abstract class _PendingOperation {
  const _PendingOperation();
}

class _PendingSubscribe extends _PendingOperation {
  const _PendingSubscribe(this.symbols);
  final List<String> symbols;
}

class _PendingUnsubscribe extends _PendingOperation {
  const _PendingUnsubscribe(this.symbols);
  final List<String> symbols;
}

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

String get _wsUrl {
  final baseWsUrl = EnvironmentConfig.instance.wsBaseUrl;
  return '$baseWsUrl/v1/market/quotes';
}

const _kMaxReconnectAttempts = 3;
const _kSymbolBatchSize = 50;
const _kMaxPendingOperations = 100;
const _kBackoffJitterPercent = 0.2; // ±20% jitter on exponential backoff

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

  /// Connection state stream for UI indicators.
  final _connectionStateController = StreamController<QuoteWebSocketConnectionState>.broadcast();

  /// Symbols to re-subscribe after a reconnect.
  final Set<String> _subscribedSymbols = {};

  /// Queue of pending subscribe/unsubscribe operations during reconnection.
  /// Max size: [_kMaxPendingOperations] to prevent unbounded growth.
  final List<_PendingOperation> _pendingOperations = [];

  int _reconnectAttempts = 0;
  bool _paused = false;
  QuoteWebSocketConnectionState _connectionState = QuoteWebSocketConnectionState.disconnected;

  /// Last error for reconnect logging
  Object? _lastError;

  /// Random number generator for jitter calculation
  final _random = Random();

  @visibleForTesting
  Stream<QuoteWebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Future<WsUserType> build() async {
    ref.onDispose(_dispose);
    return _connectWithToken();
  }

  void _dispose() {
    _pipeSubscription?.cancel();
    _client?.dispose();
    _outputController.close();
    _connectionStateController.close();
    _client = null;
  }

  // ─── Connection State Management ───────────────────────────────────────────

  void _setConnectionState(QuoteWebSocketConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      AppLogger.debug('QuoteWS: connection state → $newState');
    }
  }

  // ─── Connection ───────────────────────────────────────────────────────────

  Future<WsUserType> _connectWithToken() async {
    _setConnectionState(QuoteWebSocketConnectionState.connecting);

    final token = await ref.read(tokenServiceProvider).getAccessToken();
    final factory = ref.read(wsClientFactoryProvider);
    final client = factory(_wsUrl);

    _setConnectionState(QuoteWebSocketConnectionState.authenticating);

    final userType = await client.connect(
      token: (token == null || token.isEmpty) ? null : token,
    );

    _client = client;
    _reconnectAttempts = 0;
    _pendingOperations.clear();
    _pipeClientEvents(client);

    _setConnectionState(QuoteWebSocketConnectionState.connected);
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
      _setConnectionState(QuoteWebSocketConnectionState.error);
      state = AsyncError(
        const NetworkException(message: '行情连接失败，请检查网络后重试'),
        StackTrace.current,
      );
      return;
    }

    _setConnectionState(QuoteWebSocketConnectionState.reconnecting);

    // Calculate exponential backoff with jitter to prevent thundering herd
    final baseDelay = pow(2, _reconnectAttempts).toInt();
    final jitterMs = (baseDelay * 1000 * _kBackoffJitterPercent).toInt();
    final randomJitter = _random.nextInt(2 * jitterMs) - jitterMs;
    final finalDelayMs = (baseDelay * 1000) + randomJitter;
    final delay = Duration(milliseconds: finalDelayMs.clamp(100, 32000).toInt());

    _reconnectAttempts++;

    final reason = _lastError is NetworkException
        ? (_lastError as NetworkException).message
        : _lastError?.toString() ?? 'unknown';

    AppLogger.debug(
      'QuoteWS: reconnecting in ${delay.inSeconds}s (${delay.inMilliseconds}ms, '
      'with ±${(jitterMs / 1000).toStringAsFixed(1)}s jitter) '
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
    final pendingOps = List<_PendingOperation>.from(_pendingOperations);
    _subscribedSymbols.clear();
    _pendingOperations.clear();

    _pipeSubscription?.cancel();
    await _client?.dispose();

    _setConnectionState(QuoteWebSocketConnectionState.connecting);

    final token = await ref.read(tokenServiceProvider).getAccessToken();
    final factory = ref.read(wsClientFactoryProvider);
    final newClient = factory(_wsUrl);

    _setConnectionState(QuoteWebSocketConnectionState.authenticating);

    final userType = await newClient.connect(
      token: (token == null || token.isEmpty) ? null : token,
    );

    _client = newClient;
    _reconnectAttempts = 0;
    _pipeClientEvents(newClient);

    // Replay previously subscribed symbols first
    if (prevSymbols.isNotEmpty) {
      await _subscribeInternal(prevSymbols.toList());
    }

    // Then replay buffered pending operations (subscribe/unsubscribe that occurred during disconnect)
    await _replayPendingOperations(pendingOps);

    _setConnectionState(QuoteWebSocketConnectionState.connected);
    state = AsyncData(userType);
    AppLogger.info(
      'QuoteWS: reconnected successfully as $userType '
      '(replayed ${prevSymbols.length} symbols + ${pendingOps.length} buffered ops)',
    );
  }

  /// Replay pending operations (subscribe/unsubscribe) that were buffered during reconnection.
  Future<void> _replayPendingOperations(List<_PendingOperation> pendingOps) async {
    if (pendingOps.isEmpty || _client == null) return;

    for (final op in pendingOps) {
      try {
        if (op is _PendingSubscribe) {
          await _subscribeInternal(op.symbols);
        } else if (op is _PendingUnsubscribe) {
          unsubscribe(op.symbols);
        }
      } catch (e) {
        AppLogger.warning('QuoteWS: failed to replay operation $op: $e');
      }
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Persistent stream of [WsQuoteUpdate] for all subscribed symbols.
  ///
  /// Survives individual WS reconnects — consumers never need to re-listen.
  Stream<WsQuoteUpdate> get quoteStream => _outputController.stream;

  /// Subscribe to real-time (or delayed) quotes for [symbols].
  ///
  /// Automatically batches into groups of [_kSymbolBatchSize] (50) per the
  /// server limit. If currently reconnecting, buffers the request for replay.
  Future<void> subscribe(List<String> symbols) async {
    if (symbols.isEmpty) return;

    // If reconnecting, buffer the request for replay after connection restored
    if (_connectionState == QuoteWebSocketConnectionState.reconnecting) {
      _bufferOperation(_PendingSubscribe(symbols));
      return;
    }

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
  /// If currently reconnecting, buffers the request for replay after connection restored.
  void unsubscribe(List<String> symbols) {
    if (symbols.isEmpty) return;

    // If reconnecting, buffer the request for replay after connection restored
    if (_connectionState == QuoteWebSocketConnectionState.reconnecting) {
      _bufferOperation(_PendingUnsubscribe(symbols));
      return;
    }

    _client?.unsubscribe(symbols);
    _subscribedSymbols.removeAll(symbols);
    AppLogger.debug('QuoteWS: unsubscribed from ${symbols.length} symbols');
  }

  /// Buffer an operation for replay during reconnection.
  /// Operations are queued if buffer is not full; oldest operations are dropped if needed.
  void _bufferOperation(_PendingOperation op) {
    if (_pendingOperations.length >= _kMaxPendingOperations) {
      _pendingOperations.removeAt(0); // Drop oldest operation
      AppLogger.warning('QuoteWS: pending operation buffer full, dropping oldest op');
    }
    _pendingOperations.add(op);
    AppLogger.debug('QuoteWS: buffered operation ${op.runtimeType}');
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
