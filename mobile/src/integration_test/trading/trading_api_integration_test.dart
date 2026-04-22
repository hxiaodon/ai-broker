import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Trading Module — API Integration Tests
///
/// **Purpose**: Verify HTTP API layer and Mock Server integration
/// **Dependencies**: Mock Server running on localhost:8080
/// **Speed**: Fast (~15 seconds)
/// **Run when**: Before commits, in CI/CD pipeline
///
/// Tests directly call Mock Server HTTP endpoints using Dio.
/// No Flutter app is launched — only the HTTP layer is tested.
///
/// Run:
///   cd mobile/mock-server && go run . --strategy=normal
///   cd mobile/src && flutter test integration_test/trading/trading_api_integration_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;

  setUpAll(() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
  });

  // ── Security Protocol ──────────────────────────────────────────────────────

  group('Security Protocol', () {
    testWidgets('TA1: POST /api/v1/auth/session-key returns key_id + hmac_secret',
        (tester) async {
      final resp = await dio.post<Map<String, dynamic>>(
        '/api/v1/auth/session-key',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['key_id'], isNotEmpty);
      expect(resp.data!['hmac_secret'], isNotEmpty);
      expect(resp.data!['expires_at'], isNotEmpty);
      print('✅ TA1: session-key issued: ${resp.data!['key_id']}');
    });

    testWidgets('TA2: GET /api/v1/trading/nonce returns one-time nonce',
        (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/trading/nonce',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['nonce'], isNotEmpty);
      expect(resp.data!['expires_at'], isNotEmpty);
      print('✅ TA2: nonce issued: ${resp.data!['nonce']}');
    });

    testWidgets('TA3: GET /api/v1/trading/bio-challenge returns challenge',
        (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/trading/bio-challenge',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['challenge'], isNotEmpty);
      expect(resp.data!['expires_at'], isNotEmpty);
      print('✅ TA3: bio-challenge issued');
    });

    testWidgets('TA4: Same nonce rejected on second use', (tester) async {
      // Get a nonce
      final nonceResp = await dio.get<Map<String, dynamic>>(
        '/api/v1/trading/nonce',
      );
      final nonce = nonceResp.data!['nonce'] as String;

      // Get session key and bio challenge
      final skResp = await dio.post<Map<String, dynamic>>(
        '/api/v1/auth/session-key',
      );
      final keyId = skResp.data!['key_id'] as String;
      final bioResp = await dio.get<Map<String, dynamic>>(
        '/api/v1/trading/bio-challenge',
      );
      final challenge = bioResp.data!['challenge'] as String;

      final headers = {
        'Authorization': 'Bearer test-token',
        'X-Key-Id': keyId,
        'X-Nonce': nonce,
        'X-Signature': 'stub-sig',
        'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'X-Device-Id': 'dev-test-001',
        'X-Biometric-Token': 'stub-bio-token',
        'X-Bio-Challenge': challenge,
        'X-Bio-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'Idempotency-Key': 'idem-ta4-first',
      };

      // First use — should succeed
      await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'AAPL',
          'market': 'US',
          'side': 'buy',
          'order_type': 'limit',
          'qty': 10,
          'limit_price': '150.00',
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: headers),
      );

      // Second use with same nonce — should fail
      try {
        await dio.post<Map<String, dynamic>>(
          '/api/v1/orders',
          data: {
            'symbol': 'AAPL',
            'market': 'US',
            'side': 'buy',
            'order_type': 'limit',
            'qty': 10,
            'limit_price': '150.00',
            'validity': 'day',
            'extended_hours': false,
          },
          options: Options(headers: {
            ...headers,
            'Idempotency-Key': 'idem-ta4-second',
          }),
        );
        fail('Expected 400 for reused nonce');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
        expect(e.response?.data['error_code'], 'NONCE_ALREADY_USED');
        print('✅ TA4: reused nonce correctly rejected with 400');
      }
    });
  });

  // ── Order Submission ───────────────────────────────────────────────────────

  group('Order Submission', () {
    Future<Map<String, String>> _getSecurityHeaders() async {
      final skResp = await dio.post<Map<String, dynamic>>(
        '/api/v1/auth/session-key',
      );
      final nonceResp = await dio.get<Map<String, dynamic>>(
        '/api/v1/trading/nonce',
      );
      final bioResp = await dio.get<Map<String, dynamic>>(
        '/api/v1/trading/bio-challenge',
      );
      return {
        'Authorization': 'Bearer test-token',
        'X-Key-Id': skResp.data!['key_id'] as String,
        'X-Nonce': nonceResp.data!['nonce'] as String,
        'X-Signature': 'stub-sig',
        'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'X-Device-Id': 'dev-test-001',
        'X-Biometric-Token': 'stub-bio-token',
        'X-Bio-Challenge': bioResp.data!['challenge'] as String,
        'X-Bio-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'Idempotency-Key': 'idem-${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    testWidgets('TA5: Complete order submission with all security headers returns 201',
        (tester) async {
      final headers = await _getSecurityHeaders();

      final resp = await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'AAPL',
          'market': 'US',
          'side': 'buy',
          'order_type': 'limit',
          'qty': 100,
          'limit_price': '150.2500',
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: headers),
      );

      expect(resp.statusCode, 201);
      expect(resp.data!['order_id'], isNotEmpty);
      expect(resp.data!['symbol'], 'AAPL');
      expect(resp.data!['status'], 'PENDING');
      print('✅ TA5: Order submitted: ${resp.data!['order_id']}');
    });

    testWidgets('TA6: Missing X-Nonce header returns 400', (tester) async {
      final headers = await _getSecurityHeaders();
      headers.remove('X-Nonce');

      try {
        await dio.post<Map<String, dynamic>>(
          '/api/v1/orders',
          data: {
            'symbol': 'AAPL',
            'market': 'US',
            'side': 'buy',
            'order_type': 'market',
            'qty': 10,
            'validity': 'day',
            'extended_hours': false,
          },
          options: Options(headers: headers),
        );
        fail('Expected 400');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
        expect(e.response?.data['error_code'], 'MISSING_HEADER');
        print('✅ TA6: Missing X-Nonce → 400 MISSING_HEADER');
      }
    });

    testWidgets('TA7: Order without biometric headers succeeds (biometric optional)', (tester) async {
      final headers = await _getSecurityHeaders();
      // Remove all biometric headers - should still succeed
      headers.remove('X-Biometric-Token');
      headers.remove('X-Bio-Challenge');
      headers.remove('X-Bio-Timestamp');

      final resp = await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'TSLA',
          'market': 'US',
          'side': 'buy',
          'order_type': 'market',
          'qty': 5,
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: headers),
      );
      expect(resp.statusCode, 201);
      expect(resp.data?['order_id'], isNotNull);
      print('✅ TA7: Order without biometric headers → 201 (biometric optional)');
    });

    testWidgets('TA8: Market order (no limit_price) returns 201', (tester) async {
      final headers = await _getSecurityHeaders();

      final resp = await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'TSLA',
          'market': 'US',
          'side': 'sell',
          'order_type': 'market',
          'qty': 50,
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: headers),
      );

      expect(resp.statusCode, 201);
      expect(resp.data!['order_type'], 'market');
      expect(resp.data!['limit_price'], isNull);
      print('✅ TA8: Market order submitted: ${resp.data!['order_id']}');
    });

    testWidgets('TA8b: Market order auto-transitions PENDING → FILLED', (tester) async {
      // Submit a market order and verify Mock Server auto-fills it after ~2s.
      final headers = await _getSecurityHeaders();

      final submit = await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'AAPL',
          'market': 'US',
          'side': 'buy',
          'order_type': 'market',
          'qty': 7,
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: headers),
      );
      expect(submit.statusCode, 201);
      expect(submit.data!['status'], 'PENDING');
      final orderId = submit.data!['order_id'] as String;

      // Poll for up to 5s waiting for auto-fill.
      Map<String, dynamic>? order;
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final resp = await dio.get<Map<String, dynamic>>('/api/v1/orders/$orderId');
        order = resp.data!['order'] as Map<String, dynamic>;
        if (order['status'] == 'FILLED') break;
      }

      expect(order, isNotNull);
      expect(order!['status'], 'FILLED',
          reason: 'Market order should auto-transition to FILLED within 5s');
      expect(order['filled_qty'], 7);
      expect(order['avg_fill_price'], isNotNull);
      print('✅ TA8b: Market order $orderId auto-filled @ ${order['avg_fill_price']}');
    });

    testWidgets('TA8c: Limit order does NOT auto-fill', (tester) async {
      // Limit orders must stay PENDING; only market orders auto-fill.
      final headers = await _getSecurityHeaders();

      final submit = await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'AAPL',
          'market': 'US',
          'side': 'buy',
          'order_type': 'limit',
          'qty': 3,
          'limit_price': '100.00',
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: headers),
      );
      expect(submit.statusCode, 201);
      final orderId = submit.data!['order_id'] as String;

      // Wait beyond the market auto-fill window.
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      final resp = await dio.get<Map<String, dynamic>>('/api/v1/orders/$orderId');
      final order = resp.data!['order'] as Map<String, dynamic>;
      expect(order['status'], 'PENDING',
          reason: 'Limit order should remain PENDING after 2.5s');
      print('✅ TA8c: Limit order $orderId stayed PENDING');
    });
  });

  // ── Cancel Order ───────────────────────────────────────────────────────────

  group('Cancel Order', () {
    testWidgets('TA9: DELETE /api/v1/orders/:id returns 202', (tester) async {
      // First submit an order to cancel
      final skResp = await dio.post<Map<String, dynamic>>('/api/v1/auth/session-key');
      final nonceResp1 = await dio.get<Map<String, dynamic>>('/api/v1/trading/nonce');
      final bioResp = await dio.get<Map<String, dynamic>>('/api/v1/trading/bio-challenge');

      final submitResp = await dio.post<Map<String, dynamic>>(
        '/api/v1/orders',
        data: {
          'symbol': 'AAPL',
          'market': 'US',
          'side': 'buy',
          'order_type': 'limit',
          'qty': 10,
          'limit_price': '150.00',
          'validity': 'day',
          'extended_hours': false,
        },
        options: Options(headers: {
          'Authorization': 'Bearer test-token',
          'X-Key-Id': skResp.data!['key_id'],
          'X-Nonce': nonceResp1.data!['nonce'],
          'X-Signature': 'stub-sig',
          'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'X-Device-Id': 'dev-test-001',
          'X-Biometric-Token': 'stub-bio-token',
          'X-Bio-Challenge': bioResp.data!['challenge'],
          'X-Bio-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'Idempotency-Key': 'idem-cancel-test',
        }),
      );
      final orderId = submitResp.data!['order_id'] as String;

      // Now cancel it with a fresh nonce
      final nonceResp2 = await dio.get<Map<String, dynamic>>('/api/v1/trading/nonce');
      final cancelResp = await dio.delete<void>(
        '/api/v1/orders/$orderId',
        options: Options(headers: {
          'Authorization': 'Bearer test-token',
          'X-Key-Id': skResp.data!['key_id'],
          'X-Nonce': nonceResp2.data!['nonce'],
          'X-Signature': 'stub-sig',
          'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'X-Device-Id': 'dev-test-001',
        }),
      );

      expect(cancelResp.statusCode, 202);
      print('✅ TA9: Order $orderId cancelled → 202');
    });

    testWidgets('TA10: Cancel requires X-Nonce — missing returns 400', (tester) async {
      try {
        await dio.delete<void>(
          '/api/v1/orders/ord-001',
          options: Options(headers: {
            'Authorization': 'Bearer test-token',
            'X-Key-Id': 'sk-test',
            'X-Signature': 'stub-sig',
            'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'X-Device-Id': 'dev-test-001',
            // X-Nonce intentionally omitted
          }),
        );
        fail('Expected 400');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
        print('✅ TA10: Cancel without nonce → 400');
      }
    });
  });

  // ── Query Endpoints ────────────────────────────────────────────────────────

  group('Query Endpoints', () {
    testWidgets('TA11: GET /api/v1/orders returns order list', (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/orders',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['orders'], isA<List>());
      final orders = resp.data!['orders'] as List;
      expect(orders, isNotEmpty);
      print('✅ TA11: GET /orders returned ${orders.length} orders');
    });

    testWidgets('TA12: GET /api/v1/orders/:id returns order + fills', (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/orders/ord-001',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['order'], isA<Map>());
      expect(resp.data!['fills'], isA<List>());
      final order = resp.data!['order'] as Map;
      expect(order['order_id'], 'ord-001');
      print('✅ TA12: GET /orders/ord-001 returned order + ${(resp.data!['fills'] as List).length} fills');
    });

    testWidgets('TA13: GET /api/v1/positions returns positions list', (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/positions',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      final positions = resp.data!['positions'] as List;
      expect(positions, hasLength(2));
      expect((positions.first as Map)['symbol'], 'AAPL');
      print('✅ TA13: GET /positions returned ${positions.length} positions');
    });

    testWidgets('TA14: GET /api/v1/portfolio/summary returns portfolio data',
        (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/portfolio/summary',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['total_equity'], isNotEmpty);
      expect(resp.data!['cash_balance'], isNotEmpty);
      expect(resp.data!['buying_power'], isNotEmpty);
      expect(resp.data!['cumulative_pnl'], isNotEmpty);
      print('✅ TA14: GET /portfolio/summary returned equity: ${resp.data!['total_equity']}');
    });

    testWidgets('TA15: GET /api/v1/orders with status filter', (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/orders',
        queryParameters: {'status': 'PENDING'},
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      final orders = resp.data!['orders'] as List;
      for (final o in orders) {
        expect((o as Map)['status'], 'PENDING');
      }
      print('✅ TA15: Status filter PENDING returned ${orders.length} orders');
    });

    testWidgets('TA16: GET /api/v1/positions/:symbol returns single position',
        (tester) async {
      final resp = await dio.get<Map<String, dynamic>>(
        '/api/v1/positions/AAPL',
        options: Options(headers: {'Authorization': 'Bearer test-token'}),
      );
      expect(resp.statusCode, 200);
      expect(resp.data!['symbol'], 'AAPL');
      expect(resp.data!['market'], 'US');
      print('✅ TA16: GET /positions/AAPL returned qty: ${resp.data!['quantity']}');
    });
  });
}
