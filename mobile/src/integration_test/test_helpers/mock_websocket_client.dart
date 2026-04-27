import 'dart:async';

import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';

/// Mock WebSocket client for testing
///
/// Simulates WebSocket connection lifecycle and quote updates
class MockWebSocketClient extends QuoteWebSocketClient {
  MockWebSocketClient() : super(wsUrl: 'ws://mock:8080/test');

  final _quoteController = StreamController<WsQuoteUpdate>.broadcast();
  final Set<String> subscribedSymbols = {};
  WsUserType? _userType;
  bool _isConnected = false;
  bool _shouldFailConnect = false;

  @override
  Stream<WsQuoteUpdate> get quoteStream => _quoteController.stream;

  @override
  Future<WsUserType> connect({String? token}) async {
    if (_shouldFailConnect) {
      throw Exception('Connection failed');
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
    _isConnected = true;
    _userType = (token == null || token.isEmpty) ? WsUserType.guest : WsUserType.registered;
    return _userType!;
  }

  @override
  Future<void> subscribe(List<String> symbols) async {
    if (!_isConnected) {
      throw StateError('Not connected');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
    subscribedSymbols.addAll(symbols);
  }

  @override
  void unsubscribe(List<String> symbols) {
    subscribedSymbols.removeAll(symbols);
  }

  @override
  Future<WsUserType> reauth(String newToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _userType = WsUserType.registered;
    return _userType!;
  }

  @override
  Future<void> close() async {
    _isConnected = false;
    subscribedSymbols.clear();
  }

  @override
  Future<void> dispose() async {
    await close();
    await _quoteController.close();
  }

  // ─── Test Helpers ─────────────────────────────────────────────────────────

  /// Simulate a successful connection
  void simulateConnected(WsUserType userType) {
    _isConnected = true;
    _userType = userType;
  }

  /// Simulate a quote update from the server
  void simulateQuoteUpdate(WsQuoteUpdate update) {
    if (_isConnected) {
      _quoteController.add(update);
    }
  }

  /// Simulate an error from the server
  void simulateError(Object error) {
    _quoteController.addError(error);
  }

  /// Configure whether connect() should fail
  void setShouldFailConnect(bool shouldFail) {
    _shouldFailConnect = shouldFail;
  }

  /// Reset all state
  void reset() {
    _isConnected = false;
    _userType = null;
    subscribedSymbols.clear();
    _shouldFailConnect = false;
  }

  /// Check if connected
  bool get isConnected => _isConnected;

  /// Get current user type
  WsUserType? get userType => _userType;
}

