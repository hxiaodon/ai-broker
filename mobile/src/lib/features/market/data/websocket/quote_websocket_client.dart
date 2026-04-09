import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/quote.dart';
import '../mappers/market_mappers.dart';
import '../proto/market_data.pb.dart' as proto;
import '../remote/market_response_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public surface types
// ─────────────────────────────────────────────────────────────────────────────

/// A single quote update received from the WebSocket server.
///
/// Covers all three Protobuf frame types:
///   - SNAPSHOT — full quote; pushed right after subscribe_ack per symbol
///   - TICK     — partial patch (only changed fields are non-zero)
///   - DELAYED  — T-15 min full snapshot (guest, every 5 s)
class WsQuoteUpdate {
  const WsQuoteUpdate({
    required this.frameType,
    required this.symbol,
    required this.quote,
  });

  final WsFrameType frameType;
  final String symbol;
  final Quote quote;
}

enum WsFrameType { snapshot, tick, delayed }

/// Authentication mode after a successful auth/reauth handshake.
enum WsUserType { registered, guest }

enum _WsState { disconnected, connecting, authenticating, connected, closed }

/// Factory signature for creating a [WebSocketChannel].
/// Injected at construction time; defaults to [WebSocketChannel.connect].
typedef WsChannelFactory = WebSocketChannel Function(
  Uri uri, {
  Iterable<String>? protocols,
});

// ─────────────────────────────────────────────────────────────────────────────
// QuoteWebSocketClient
// ─────────────────────────────────────────────────────────────────────────────

/// WebSocket client that manages the full lifecycle of a market-data
/// connection per the WebSocket protocol spec v2.1.
///
/// ## Frame protocol
/// - Control messages  : JSON text frames  (`action` / `type` fields)
/// - Quote data        : Protobuf binary frames (`WsQuoteFrame`)
///
/// ## Error surface
/// - [AuthException]            : auth or reauth rejected by server
/// - [BusinessException]        : server `error` frame (e.g. symbol limit)
/// - [NetworkException]         : connection failure or unexpected close
/// - [WsTokenExpiringException] : server `token_expiring` notification
///   → caller should call `reauth(newToken)` before the token expires
class QuoteWebSocketClient {
  QuoteWebSocketClient({
    required String wsUrl,
    this.authTimeoutSeconds = 5,
    this.pingIntervalSeconds = 30,
    @visibleForTesting WsChannelFactory? channelFactory,
  })  : _wsUrl = wsUrl,
        _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final String _wsUrl;
  final int authTimeoutSeconds;
  final int pingIntervalSeconds;
  final WsChannelFactory _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _authTimeoutTimer;
  _WsState _state = _WsState.disconnected;

  final _quoteController = StreamController<WsQuoteUpdate>.broadcast();

  /// Pending auth / reauth completers (FIFO — at most 1 at a time in practice).
  final _pendingAuth = <Completer<WsUserType>>[];

  Set<String> _subscribedSymbols = {};

  /// Frame counter for Protobuf binary frames (used in error logging)
  int _frameCount = 0;

  /// Close reason for tracking disconnect cause
  String? _closeReason;

  /// Last pong received time for timeout detection
  DateTime? _lastPongTime;

  /// Pong timeout timer
  Timer? _pongTimeoutTimer;

  static const _pongTimeout = Duration(seconds: 45); // 1.5x ping interval

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Live stream of quote updates from all subscribed symbols.
  Stream<WsQuoteUpdate> get quoteStream => _quoteController.stream;

  /// Connect to the server and authenticate.
  ///
  /// [token]: valid JWT for registered users, null/empty for guest mode.
  /// Returns [WsUserType.registered] or [WsUserType.guest] on success.
  /// Throws [AuthException] or [NetworkException] on failure.
  Future<WsUserType> connect({String? token}) async {
    if (_state != _WsState.disconnected) {
      throw StateError('QuoteWebSocketClient: already connected');
    }
    _state = _WsState.connecting;

    try {
      _channel = _channelFactory(
        Uri.parse(_wsUrl),
        protocols: const ['brokerage-market-v1'],
      );

      // Add timeout to ready future to prevent infinite hang on weak networks
      await _channel!.ready.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('WebSocket connection timeout after 10s');
        },
      );

      AppLogger.info('WS connection established to $_wsUrl');
    } catch (e) {
      AppLogger.error('WS connection failed', error: e);
      _cleanup();
      _state = _WsState.disconnected;
      throw NetworkException(message: 'WS 连接失败: $e', cause: e);
    }

    _state = _WsState.authenticating;

    // Register auth completer before starting to listen (to avoid a race where
    // the auth_result arrives before the completer is registered).
    final authCompleter = Completer<WsUserType>();
    _pendingAuth.add(authCompleter);

    // 5-second auth timeout — server closes with code 4001 if no auth received
    _authTimeoutTimer = Timer(Duration(seconds: authTimeoutSeconds), () {
      if (!authCompleter.isCompleted) {
        authCompleter.completeError(
          const AuthException(message: '行情 WS 认证超时，请重新连接'),
        );
      }
    });

    _subscription = _channel!.stream.listen(
      _onFrame,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );

    _sendJson({'action': 'auth', 'token': token ?? ''});

    final userType = await authCompleter.future;
    _authTimeoutTimer?.cancel();
    _authTimeoutTimer = null;

    _state = _WsState.connected;
    _startPingTimer();

    AppLogger.info('WS auth succeeded: userType=$userType');
    return userType;
  }

  /// Subscribe to quote pushes for [symbols] (max 50 per call).
  ///
  /// After subscribe_ack, the server immediately sends one SNAPSHOT frame
  /// per symbol as a Protobuf binary frame.
  Future<void> subscribe(List<String> symbols) async {
    assert(symbols.isNotEmpty && symbols.length <= 50,
        'subscribe: 1–50 symbols required');
    _requireConnected();
    _sendJson({'action': 'subscribe', 'symbols': symbols});
    _subscribedSymbols.addAll(symbols);
    AppLogger.debug('WS subscribe: ${symbols.join(",")}');
  }

  /// Stop receiving pushes for [symbols].
  /// No server acknowledgement is sent for unsubscribe.
  void unsubscribe(List<String> symbols) {
    _requireConnected();
    _sendJson({'action': 'unsubscribe', 'symbols': symbols});
    _subscribedSymbols.removeAll(symbols);
    AppLogger.debug('WS unsubscribe: ${symbols.join(",")}');
  }

  /// Re-authenticate with [newToken] (token renewal or guest → registered).
  ///
  /// The server migrates the connection to the appropriate quote group without
  /// dropping existing subscriptions.
  Future<WsUserType> reauth(String newToken) async {
    _requireConnected();

    final reauthCompleter = Completer<WsUserType>();
    _pendingAuth.add(reauthCompleter);

    _sendJson({'action': 'reauth', 'token': newToken});
    AppLogger.debug('WS reauth sent');

    return reauthCompleter.future;
  }

  /// Gracefully close the connection (WebSocket code 1000).
  Future<void> close() async {
    if (_state == _WsState.closed) return;

    _closeReason = 'user_initiated';
    _state = _WsState.closed;

    _cleanup();
    await _channel?.sink.close(1000);
    AppLogger.info('WS connection closed');
  }

  /// Release all resources including the quote stream.
  Future<void> dispose() async {
    await close();
    await _quoteController.close();
  }

  // ─── Incoming frame dispatch ──────────────────────────────────────────────

  void _onFrame(dynamic raw) {
    if (raw is String) {
      _handleTextFrame(raw);
    } else if (raw is List<int>) {
      _handleBinaryFrame(Uint8List.fromList(raw));
    }
  }

  // ─── JSON text frames (control plane) ─────────────────────────────────────

  void _handleTextFrame(String text) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(text) as Map<String, dynamic>;
    } catch (e, stack) {
      AppLogger.error('WS: malformed text frame', error: e, stackTrace: stack);

      // Add error to stream for critical control messages
      _quoteController.addError(
        BusinessException(
          message: 'Failed to parse WebSocket control message',
          errorCode: 'JSON_DECODE_ERROR',
          cause: e,
        ),
      );
      return;
    }

    switch (msg['type'] as String?) {
      case 'auth_result':
        _onAuthResult(msg, isReauth: false);
      case 'reauth_result':
        _onAuthResult(msg, isReauth: true);
      case 'subscribe_ack':
        final syms = (msg['symbols'] as List?)?.cast<String>() ?? [];
        AppLogger.debug('WS subscribe_ack: ${syms.join(",")}');
      case 'pong':
        _lastPongTime = DateTime.now();
        _pongTimeoutTimer?.cancel();
        AppLogger.debug('WS: pong received');
        break;
      case 'token_expiring':
        final expiresIn = msg['expires_in'] as int? ?? 0;
        AppLogger.warning('WS token_expiring: ${expiresIn}s');
        _quoteController.addError(
          WsTokenExpiringException(expiresInSeconds: expiresIn),
        );
      case 'market_status':
        AppLogger.info(
          'WS market_status: symbol=${msg['symbol']} '
          'status=${msg['market_status']}',
        );
      case 'error':
        final code = msg['code'] as String? ?? 'UNKNOWN';
        final message = msg['message'] as String? ?? '';
        AppLogger.warning('WS server error: code=$code message=$message');
        _quoteController.addError(
          BusinessException(message: message, errorCode: code),
        );
      default:
        AppLogger.warning('WS: unknown message type: ${msg['type']}');
    }
  }

  void _onAuthResult(Map<String, dynamic> msg, {required bool isReauth}) {
    final success = msg['success'] as bool? ?? false;
    final completer =
        _pendingAuth.isNotEmpty ? _pendingAuth.removeAt(0) : null;

    if (!success) {
      final err = AuthException(
        message: isReauth ? 'Token 续期失败，请重新登录' : '行情 WS 认证失败，请重新登录',
      );
      completer?.completeError(err);
      _quoteController.addError(err);
      return;
    }

    final rawType = msg['user_type'] as String?;
    final userType =
        rawType == 'registered' ? WsUserType.registered : WsUserType.guest;
    completer?.complete(userType);

    if (isReauth) {
      AppLogger.info('WS reauth succeeded: userType=$userType');
    }
  }

  // ─── Protobuf binary frames (data plane) ──────────────────────────────────

  void _handleBinaryFrame(Uint8List bytes) {
    try {
      final frame = proto.WsQuoteFrame.fromBuffer(bytes);
      _frameCount++;

      final protoQuote = frame.quote;

      final frameType = switch (frame.frameType) {
        proto.WsQuoteFrame_FrameType.FRAME_TYPE_SNAPSHOT =>
          WsFrameType.snapshot,
        proto.WsQuoteFrame_FrameType.FRAME_TYPE_DELAYED => WsFrameType.delayed,
        _ => WsFrameType.tick,
      };

      final dto = _protoQuoteToDto(protoQuote);
      final quote = dto.toDomain();

      if (protoQuote.isStale) {
        AppLogger.warning(
          'WS: stale quote for ${protoQuote.symbol} '
          '(staleSince=${protoQuote.staleSinceMs}ms)',
        );
      }

      _quoteController.add(WsQuoteUpdate(
        frameType: frameType,
        symbol: protoQuote.symbol,
        quote: quote,
      ));
    } catch (e, stack) {
      AppLogger.error(
        'WS: failed to decode Protobuf binary frame (total frames: $_frameCount)',
        error: e,
        stackTrace: stack,
      );

      // Propagate error to stream so UI can show warning
      _quoteController.addError(
        BusinessException(
          message: 'Failed to parse market data frame',
          errorCode: 'PROTOBUF_DECODE_ERROR',
          cause: e,
        ),
      );
    }
  }

  // ─── Heartbeat ────────────────────────────────────────────────────────────

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      Duration(seconds: pingIntervalSeconds),
      (_) {
        if (_state == _WsState.connected) {
          _sendJson({'action': 'ping'});
          AppLogger.debug('WS: ping sent');

          // Start pong timeout timer
          _pongTimeoutTimer?.cancel();
          _pongTimeoutTimer = Timer(_pongTimeout, () {
            AppLogger.error('WS: pong timeout - connection appears dead');
            _quoteController.addError(
              NetworkException(message: '行情连接超时，正在重连...'),
            );
            _channel?.sink.close(1000, 'pong timeout');
          });
        }
      },
    );
  }

  // ─── Connection lifecycle events ──────────────────────────────────────────

  void _onError(Object error) {
    AppLogger.warning('WS socket error: $error');
    _quoteController.addError(
      NetworkException(message: 'WS 连接错误: $error', cause: error),
    );
    _cleanup();
  }

  void _onDone() {
    final code = _channel?.closeCode;
    final reason = _closeReason ?? 'unknown';

    AppLogger.info('WS connection done: code=$code, reason=$reason, state=$_state');

    if (_state != _WsState.closed) {
      final exception = _mapCloseCode(code);
      AppLogger.warning('WS unexpected disconnect: $exception');
      _quoteController.addError(exception);
      _cleanup();
    } else {
      AppLogger.debug('WS graceful close');
    }

    _closeReason = null;
  }

  AppException _mapCloseCode(int? code) {
    return switch (code) {
      // Standard WebSocket close codes
      1001 => const NetworkException(message: '服务端正在关闭（code 1001），将自动重连'),
      1002 => const NetworkException(message: '协议错误（code 1002）'),
      1003 => const NetworkException(message: '不支持的数据类型（code 1003）'),
      1006 => const NetworkException(message: '连接异常断开（code 1006），将自动重连'),
      1011 => const NetworkException(message: '服务端内部错误（code 1011），将自动重连'),
      1012 => const NetworkException(message: '服务端重启中（code 1012），将自动重连'),
      1013 => const NetworkException(message: '服务端过载（code 1013），请稍后重连'),
      // Application-specific close codes
      4001 => const AuthException(message: '认证超时，连接被服务端关闭（code 4001）'),
      4002 => const AuthException(message: 'Token 无效或已过期（code 4002），请重新登录'),
      4003 => const BusinessException(
          message: 'symbols 数量超过限制（code 4003）',
          errorCode: 'SYMBOL_LIMIT_EXCEEDED',
        ),
      4004 => const NetworkException(message: '服务端主动关闭连接（维护中，code 4004），请稍后重连'),
      _ => NetworkException(
          message: '连接意外断开（code=${code ?? "none"}），将自动重连',
        ),
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _sendJson(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _requireConnected() {
    if (_state != _WsState.connected) {
      throw StateError('QuoteWebSocketClient: not connected (state=$_state)');
    }
  }

  void _cleanup() {
    _closeReason ??= 'error_or_network_failure';
    _pingTimer?.cancel();
    _pongTimeoutTimer?.cancel();
    _authTimeoutTimer?.cancel();
    _subscription?.cancel();
    _pingTimer = null;
    _pongTimeoutTimer = null;
    _authTimeoutTimer = null;
    _subscribedSymbols = {};
    _state = _WsState.disconnected;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Proto → QuoteDto bridge
// ─────────────────────────────────────────────────────────────────────────────

/// Convert a proto [Quote] to a [QuoteDto] so that the shared
/// [QuoteDtoMapper.toDomain()] logic handles Decimal parsing.
///
/// Fields absent from TICK frames arrive as proto3 zero-values (empty string /
/// 0). Callers that patch a cached Quote must handle zero-value fields.
QuoteDto _protoQuoteToDto(proto.Quote q) {
  final marketStatusStr = switch (q.marketStatus) {
    proto.MarketStatus.MARKET_STATUS_REGULAR => 'REGULAR',
    proto.MarketStatus.MARKET_STATUS_PRE_MARKET => 'PRE_MARKET',
    proto.MarketStatus.MARKET_STATUS_AFTER_HOURS => 'AFTER_HOURS',
    proto.MarketStatus.MARKET_STATUS_HALTED => 'HALTED',
    _ => 'CLOSED',
  };

  return QuoteDto(
    symbol: q.symbol,
    // name / nameZh / marketCap are not in WsQuoteFrame.
    // The caller should merge these from the cached REST QuoteDto when patching.
    name: '',
    nameZh: '',
    market: q.market == proto.Market.MARKET_HK ? 'HK' : 'US',
    price: q.price,
    change: q.change,
    changePct: q.changePct,
    volume: q.volume.toInt(),
    bid: q.bid.isEmpty ? null : q.bid,
    ask: q.ask.isEmpty ? null : q.ask,
    turnover: q.turnover,
    prevClose: q.prevClose,
    open: q.open,
    high: q.high,
    low: q.low,
    marketCap: '',
    delayed: q.delayed,
    marketStatus: marketStatusStr,
    isStale: q.isStale,
    staleSinceMs: q.staleSinceMs.toInt(),
  );
}
