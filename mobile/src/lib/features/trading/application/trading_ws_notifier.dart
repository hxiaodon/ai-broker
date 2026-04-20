import 'dart:async';
import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/entities/order.dart';
import '../domain/entities/portfolio_summary.dart';
import '../domain/entities/position.dart';

part 'trading_ws_notifier.g.dart';

// ─── WS message types ────────────────────────────────────────────────────────

class TradingWsOrderUpdate {
  const TradingWsOrderUpdate({required this.orderId, required this.status});
  final String orderId;
  final OrderStatus status;
}

class TradingWsPositionUpdate {
  const TradingWsPositionUpdate({required this.position});
  final Position position;
}

class TradingWsPortfolioUpdate {
  const TradingWsPortfolioUpdate({required this.summary});
  final PortfolioSummary summary;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class TradingWsNotifier extends _$TradingWsNotifier {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  final _orderController =
      StreamController<TradingWsOrderUpdate>.broadcast();
  final _positionController =
      StreamController<TradingWsPositionUpdate>.broadcast();
  final _portfolioController =
      StreamController<TradingWsPortfolioUpdate>.broadcast();

  Stream<TradingWsOrderUpdate> get orderUpdates => _orderController.stream;
  Stream<TradingWsPositionUpdate> get positionUpdates =>
      _positionController.stream;
  Stream<TradingWsPortfolioUpdate> get portfolioUpdates =>
      _portfolioController.stream;

  @override
  Future<void> build() async {
    ref.onDispose(_dispose);
    await _connect();
  }

  Future<void> _connect() async {
    final token = await ref.read(tokenServiceProvider).getAccessToken();
    if (token == null || token.isEmpty) return;

    final wsUrl =
        '${EnvironmentConfig.instance.wsBaseUrl}/ws/trading?token=$token';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _reconnectAttempts = 0;
      AppLogger.debug('TradingWS: connected');
    } on Object catch (e, st) {
      AppLogger.warning('TradingWS: connect failed: $e');
      state = AsyncError(e, st);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final msg = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      switch (type) {
        case 'order.updated':
          _orderController.add(TradingWsOrderUpdate(
            orderId: msg['order_id'] as String,
            status: _parseStatus(msg['status'] as String),
          ));
        case 'position.updated':
          // Position update is handled by invalidating the positions provider
          _positionController.add(TradingWsPositionUpdate(
            position: _parsePosition(msg['position'] as Map<String, dynamic>),
          ));
        case 'portfolio.summary':
          _portfolioController.add(TradingWsPortfolioUpdate(
            summary: _parsePortfolio(msg['data'] as Map<String, dynamic>),
          ));
      }
    } on Object catch (e) {
      AppLogger.warning('TradingWS: failed to parse message: $e');
    }
  }

  void _onError(Object error) {
    AppLogger.warning('TradingWS: error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    if (!_disposed) {
      AppLogger.debug('TradingWS: connection closed, reconnecting');
      _scheduleReconnect();
    }
  }

  Future<void> _scheduleReconnect() async {
    if (_disposed || _reconnectAttempts >= 5) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: 1 << _reconnectAttempts.clamp(0, 5));
    AppLogger.debug(
        'TradingWS: reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    await Future<void>.delayed(delay);
    if (!_disposed) await _connect();
  }

  void _dispose() {
    _disposed = true;
    _sub?.cancel();
    _channel?.sink.close();
    _orderController.close();
    _positionController.close();
    _portfolioController.close();
  }

  // ─── Parsers (minimal — full mapping done in data layer) ──────────────────

  OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'RISK_CHECKING':
        return OrderStatus.riskChecking;
      case 'PENDING':
        return OrderStatus.pending;
      case 'PARTIALLY_FILLED':
        return OrderStatus.partiallyFilled;
      case 'FILLED':
        return OrderStatus.filled;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PARTIALLY_FILLED_CANCELLED':
        return OrderStatus.partiallyFilledCancelled;
      case 'EXPIRED':
        return OrderStatus.expired;
      case 'EXCHANGE_REJECTED':
        return OrderStatus.exchangeRejected;
      default:
        return OrderStatus.rejected;
    }
  }

  Position _parsePosition(Map<String, dynamic> m) {
    // Minimal parse for WS update — full parse in data layer
    return Position(
      symbol: m['symbol'] as String,
      market: m['market'] as String,
      qty: m['qty'] as int,
      availableQty: m['available_qty'] as int,
      avgCost: _d(m['avg_cost']),
      currentPrice: _d(m['current_price']),
      marketValue: _d(m['market_value']),
      unrealizedPnl: _d(m['unrealized_pnl']),
      unrealizedPnlPct: _d(m['unrealized_pnl_pct']),
      todayPnl: _d(m['today_pnl']),
      todayPnlPct: _d(m['today_pnl_pct']),
    );
  }

  PortfolioSummary _parsePortfolio(Map<String, dynamic> m) {
    return PortfolioSummary(
      totalEquity: _d(m['total_equity']),
      cashBalance: _d(m['cash_balance']),
      marketValue: _d(m['market_value']),
      dayPnl: _d(m['day_pnl']),
      dayPnlPct: _d(m['day_pnl_pct']),
      totalPnl: _d(m['total_pnl']),
      totalPnlPct: _d(m['total_pnl_pct']),
      buyingPower: _d(m['buying_power']),
      settledCash: _d(m['settled_cash']),
    );
  }

  static Decimal _d(dynamic v) {
    final s = v is String ? v : v.toString();
    return Decimal.parse(s);
  }
}
