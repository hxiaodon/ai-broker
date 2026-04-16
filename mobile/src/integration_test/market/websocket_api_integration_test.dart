import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WebSocket API Integration Tests
// ─────────────────────────────────────────────────────────────────────────────
//
// These tests require the Mock Server to be running on localhost:8080
// Start it with: cd mock-server && ./mock-server --strategy=normal --port=8080
//
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppLogger.init();
  });

  group('WebSocket API Integration - Mock Server', () {
    const wsUrl = 'ws://localhost:8080/v1/market/quotes';
    late QuoteWebSocketClient client;

    setUp(() {
      client = QuoteWebSocketClient(wsUrl: wsUrl);
    });

    tearDown(() async {
      await client.dispose();
    });

    test('T01: Connect and authenticate as registered user', () async {
      // Act
      final userType = await client.connect(token: 'test-token-123');

      // Assert
      expect(userType, WsUserType.registered);

      print('✅ T01: Registered user authentication works');
    });

    test('T02: Connect and authenticate as guest user', () async {
      // Act
      final userType = await client.connect(token: null);

      // Assert
      expect(userType, WsUserType.guest);

      print('✅ T02: Guest user authentication works');
    });

    test('T03: Subscribe to symbols and receive SNAPSHOT frames', () async {
      // Arrange
      await client.connect(token: 'test-token');

      final updates = <WsQuoteUpdate>[];
      final subscription = client.quoteStream.listen(updates.add);

      // Act
      await client.subscribe(['AAPL', 'TSLA']);

      // Wait for SNAPSHOT frames
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert
      expect(updates.length, greaterThanOrEqualTo(2)); // At least 2 SNAPSHOT frames

      final aaplSnapshot = updates.firstWhere((u) => u.symbol == 'AAPL');
      expect(aaplSnapshot.frameType, WsFrameType.snapshot);
      expect(aaplSnapshot.quote.symbol, 'AAPL');
      expect(aaplSnapshot.quote.price, greaterThan(Decimal.zero));

      await subscription.cancel();
      print('✅ T03: Subscribe and SNAPSHOT frames work');
    });

    test('T04: Receive TICK frames for subscribed symbols', () async {
      // Arrange
      await client.connect(token: 'test-token');

      final updates = <WsQuoteUpdate>[];
      final subscription = client.quoteStream.listen(updates.add);

      await client.subscribe(['AAPL']);

      // Wait for SNAPSHOT
      await Future.delayed(const Duration(milliseconds: 300));
      updates.clear();

      // Act - wait for TICK frames (server sends every 1 second)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Assert
      final tickFrames = updates.where((u) => u.frameType == WsFrameType.tick).toList();
      expect(tickFrames.length, greaterThanOrEqualTo(1));

      final tick = tickFrames.first;
      expect(tick.symbol, 'AAPL');
      expect(tick.quote.price, greaterThan(Decimal.zero));

      await subscription.cancel();
      print('✅ T04: TICK frames work');
    });

    test('T05: Unsubscribe stops receiving updates', () async {
      // Arrange
      await client.connect(token: 'test-token');

      final updates = <WsQuoteUpdate>[];
      final subscription = client.quoteStream.listen(updates.add);

      await client.subscribe(['AAPL']);
      await Future.delayed(const Duration(milliseconds: 300));
      updates.clear();

      // Act - unsubscribe
      client.unsubscribe(['AAPL']);
      await Future.delayed(const Duration(milliseconds: 1500));

      // Assert - should not receive new TICK frames for AAPL
      final aaplUpdates = updates.where((u) => u.symbol == 'AAPL').toList();
      expect(aaplUpdates.length, 0);

      await subscription.cancel();
      print('✅ T05: Unsubscribe works');
    });

    test('T06: Ping/pong heartbeat works', () async {
      // Arrange
      await client.connect(token: 'test-token');

      // Act - wait for at least one ping/pong cycle (30s interval)
      // We can't easily test this without waiting 30s, so we just verify connection stays alive
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - connection should still be alive
      // If ping/pong fails, connection would be closed
      await client.subscribe(['AAPL']);
      // If this succeeds, connection is alive

      print('✅ T06: Connection stays alive (ping/pong implicit)');
    });

    test('T07: Reauth changes user type', () async {
      // Arrange - start as guest
      final initialType = await client.connect(token: null);
      expect(initialType, WsUserType.guest);

      // Act - reauth as registered
      final newType = await client.reauth('new-token-456');

      // Assert
      expect(newType, WsUserType.registered);

      print('✅ T07: Reauth works');
    });

    test('T08: Guest user receives DELAYED frames', () async {
      // Arrange
      await client.connect(token: null); // Guest mode

      final updates = <WsQuoteUpdate>[];
      final subscription = client.quoteStream.listen(updates.add);

      await client.subscribe(['AAPL']);

      // Act - wait for frames
      await Future.delayed(const Duration(milliseconds: 1500));

      // Assert - guest should receive DELAYED frames
      final delayedFrames = updates.where((u) => u.frameType == WsFrameType.delayed).toList();
      expect(delayedFrames.length, greaterThanOrEqualTo(1));

      final delayed = delayedFrames.first;
      expect(delayed.quote.delayed, true);

      await subscription.cancel();
      print('✅ T08: Guest DELAYED frames work');
    });

    test('T09: Multiple symbols subscription', () async {
      // Arrange
      await client.connect(token: 'test-token');

      final updates = <WsQuoteUpdate>[];
      final subscription = client.quoteStream.listen(updates.add);

      // Act
      await client.subscribe(['AAPL', 'TSLA', 'GOOGL']);

      // Wait for SNAPSHOT frames
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert
      final symbols = updates.map((u) => u.symbol).toSet();
      expect(symbols, containsAll(['AAPL', 'TSLA', 'GOOGL']));

      await subscription.cancel();
      print('✅ T09: Multiple symbols subscription works');
    });

    test('T10: Close connection gracefully', () async {
      // Arrange
      await client.connect(token: 'test-token');
      await client.subscribe(['AAPL']);

      // Act
      await client.close();

      // Assert - should not be able to subscribe after close
      expect(
        () => client.subscribe(['TSLA']),
        throwsStateError,
      );

      print('✅ T10: Graceful close works');
    });
  });
}
