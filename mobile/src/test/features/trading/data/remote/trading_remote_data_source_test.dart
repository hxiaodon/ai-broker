import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/auth/device_info_service.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/core/security/hmac_signer.dart';
import 'package:trading_app/core/security/nonce_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/features/trading/data/remote/trading_remote_data_source.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSessionKeyService extends Mock implements SessionKeyService {}

class MockNonceService extends Mock implements NonceService {}

class MockDeviceInfoService extends Mock implements DeviceInfoService {}

class FakeRequestOptions extends Fake implements RequestOptions {}

// ─── Fixtures ────────────────────────────────────────────────────────────────

Map<String, dynamic> _orderResponseJson({String status = 'PENDING'}) => {
      'order_id': 'ord-001',
      'symbol': 'AAPL',
      'market': 'US',
      'side': 'buy',
      'order_type': 'limit',
      'status': status,
      'qty': 100,
      'filled_qty': 0,
      'limit_price': '150.2500',
      'avg_fill_price': null,
      'validity': 'day',
      'extended_hours': false,
      'fees': {
        'commission': '0.99',
        'exchange_fee': '0.03',
        'sec_fee': '0.01',
        'finra_fee': '0.005',
        'total': '1.035',
      },
      'created_at': '2026-04-15T09:30:00.000Z',
      'updated_at': '2026-04-15T09:30:00.000Z',
    };

Map<String, dynamic> _positionResponseJson() => {
      'symbol': 'AAPL',
      'market': 'US',
      'quantity': 100,
      'settled_qty': 80,
      'avg_cost': '150.2500',
      'current_price': '155.0000',
      'market_value': '15500.0000',
      'unrealized_pnl': '475.0000',
      'unrealized_pnl_pct': '3.16',
      'today_pnl': '200.0000',
      'today_pnl_pct': '1.31',
      'pending_settlements': [],
    };

Map<String, dynamic> _portfolioSummaryResponseJson() => {
      'total_equity': '100000.00',
      'cash_balance': '50000.00',
      'total_market_value': '50000.00',
      'day_pnl': '1200.50',
      'day_pnl_pct': '1.22',
      'cumulative_pnl': '5000.00',
      'cumulative_pnl_pct': '5.26',
      'buying_power': '75000.00',
      'unsettled_cash': '45000.00',
    };

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockDio mockDio;
  late MockConnectivityService mockConnectivity;
  late MockSessionKeyService mockSessionKey;
  late MockNonceService mockNonce;
  late MockDeviceInfoService mockDeviceInfo;
  late TradingRemoteDataSource dataSource;

  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockConnectivity = MockConnectivityService();
    mockSessionKey = MockSessionKeyService();
    mockNonce = MockNonceService();
    mockDeviceInfo = MockDeviceInfoService();

    dataSource = TradingRemoteDataSource(
      dio: mockDio,
      signer: const HmacSigner(),
      connectivity: mockConnectivity,
      sessionKeyService: mockSessionKey,
      nonceService: mockNonce,
      deviceInfoService: mockDeviceInfo,
    );

    when(() => mockConnectivity.isConnected).thenAnswer((_) async => true);
    when(() => mockSessionKey.getSessionKey()).thenAnswer(
      (_) async => (keyId: 'sk-test', secret: 'test-secret'),
    );
    when(() => mockNonce.fetchNonce()).thenAnswer((_) async => 'n-test-nonce');
    when(() => mockDeviceInfo.getDeviceId()).thenAnswer((_) async => 'dev-test');
  });

  // ── Connectivity check ─────────────────────────────────────────────────────
  group('connectivity check', () {
    test('throws NetworkException when offline', () async {
      when(() => mockConnectivity.isConnected).thenAnswer((_) async => false);
      expect(
        () => dataSource.getOrders(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ── submitOrder ────────────────────────────────────────────────────────────
  group('submitOrder', () {
    test('sends POST with all required security headers', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: _orderResponseJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/orders'),
          ));

      final (order, requestId) = await dataSource.submitOrder(
        symbol: 'AAPL',
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.limit,
        qty: 100,
        limitPrice: Decimal.parse('150.2500'),
        validity: OrderValidity.day,
        extendedHours: false,
        idempotencyKey: 'idem-key-123',
        biometricToken: 'bio-token-xyz',
        bioChallenge: 'challenge-abc',
        bioTimestamp: '1713200000000',
      );

      expect(order.orderId, 'ord-001');
      expect(requestId, isNull); // mock Dio doesn't set X-Request-ID

      final captured = verify(() => mockDio.post<Map<String, dynamic>>(
            '/api/v1/orders',
            data: any(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured.single as Options;

      final headers = captured.headers!;
      // Security headers
      expect(headers['X-Key-Id'], 'sk-test');
      expect(headers['X-Nonce'], 'n-test-nonce');
      expect(headers['X-Device-Id'], 'dev-test');
      expect(headers['X-Timestamp'], isNotNull);
      expect(headers['X-Signature'], isNotNull);
      // Bio headers
      expect(headers['X-Biometric-Token'], 'bio-token-xyz');
      expect(headers['X-Bio-Challenge'], 'challenge-abc');
      expect(headers['X-Bio-Timestamp'], '1713200000000');
      // Idempotency
      expect(headers['Idempotency-Key'], 'idem-key-123');
    });

    test('fetches nonce and session key before each request', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: _orderResponseJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/orders'),
          ));

      await dataSource.submitOrder(
        symbol: 'AAPL',
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.limit,
        qty: 100,
        validity: OrderValidity.day,
        extendedHours: false,
        idempotencyKey: 'key',
        biometricToken: '',
        bioChallenge: '',
        bioTimestamp: '',
      );

      verify(() => mockSessionKey.getSessionKey()).called(1);
      verify(() => mockNonce.fetchNonce()).called(1);
      verify(() => mockDeviceInfo.getDeviceId()).called(1);
    });

    test('maps 401 to AuthException', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/api/v1/orders'),
        ),
        requestOptions: RequestOptions(path: '/api/v1/orders'),
      ));

      expect(
        () => dataSource.submitOrder(
          symbol: 'AAPL',
          market: 'US',
          side: OrderSide.buy,
          orderType: OrderType.limit,
          qty: 100,
          validity: OrderValidity.day,
          extendedHours: false,
          idempotencyKey: 'key',
          biometricToken: '',
          bioChallenge: '',
          bioTimestamp: '',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('maps 422 with error_code to BusinessException', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 422,
          data: {
            'error_code': 'INSUFFICIENT_BUYING_POWER',
            'message': 'Not enough funds',
          },
          requestOptions: RequestOptions(path: '/api/v1/orders'),
        ),
        requestOptions: RequestOptions(path: '/api/v1/orders'),
      ));

      expect(
        () => dataSource.submitOrder(
          symbol: 'AAPL',
          market: 'US',
          side: OrderSide.buy,
          orderType: OrderType.limit,
          qty: 100,
          validity: OrderValidity.day,
          extendedHours: false,
          idempotencyKey: 'key',
          biometricToken: '',
          bioChallenge: '',
          bioTimestamp: '',
        ),
        throwsA(
          isA<BusinessException>()
              .having((e) => e.errorCode, 'errorCode', 'INSUFFICIENT_BUYING_POWER'),
        ),
      );
    });

    test('maps timeout to NetworkException', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/api/v1/orders'),
      ));

      expect(
        () => dataSource.submitOrder(
          symbol: 'AAPL',
          market: 'US',
          side: OrderSide.buy,
          orderType: OrderType.limit,
          qty: 100,
          validity: OrderValidity.day,
          extendedHours: false,
          idempotencyKey: 'key',
          biometricToken: '',
          bioChallenge: '',
          bioTimestamp: '',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ── cancelOrder ────────────────────────────────────────────────────────────
  group('cancelOrder', () {
    test('sends DELETE with full 6-segment HMAC headers including nonce', () async {
      when(() => mockDio.delete<void>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 202,
            requestOptions: RequestOptions(path: '/api/v1/orders/ord-001'),
          ));

      await dataSource.cancelOrder('ord-001', idempotencyKey: 'idem-test-001');

      final captured = verify(() => mockDio.delete<void>(
            '/api/v1/orders/ord-001',
            options: captureAny(named: 'options'),
          )).captured.single as Options;

      final headers = captured.headers!;
      expect(headers['X-Key-Id'], 'sk-test');
      expect(headers['X-Nonce'], 'n-test-nonce');
      expect(headers['X-Device-Id'], 'dev-test');
      expect(headers['X-Timestamp'], isNotNull);
      expect(headers['X-Signature'], isNotNull);
      expect(headers['Idempotency-Key'], 'idem-test-001');
    });

    test('fetches fresh nonce for each cancel request', () async {
      when(() => mockDio.delete<void>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 202,
            requestOptions: RequestOptions(path: '/api/v1/orders/ord-001'),
          ));

      await dataSource.cancelOrder('ord-001', idempotencyKey: 'idem-001');
      await dataSource.cancelOrder('ord-002', idempotencyKey: 'idem-002');

      verify(() => mockNonce.fetchNonce()).called(2);
    });
  });

  // ── getOrders ──────────────────────────────────────────────────────────────
  group('getOrders', () {
    test('returns list of orders', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {
              'orders': [
                _orderResponseJson(),
                _orderResponseJson(status: 'FILLED'),
              ],
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/orders'),
          ));

      final orders = await dataSource.getOrders();
      expect(orders, hasLength(2));
      expect(orders[0].status, OrderStatus.pending);
      expect(orders[1].status, OrderStatus.filled);
    });

    test('passes status filter as API string', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          )).thenAnswer((_) async => Response(
            data: {'orders': <Map<String, dynamic>>[]},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/orders'),
          ));

      await dataSource.getOrders(status: OrderStatus.partiallyFilled);

      final captured = verify(() => mockDio.get<Map<String, dynamic>>(
            '/api/v1/orders',
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured.single as Map<String, dynamic>;

      expect(captured['status'], 'PARTIALLY_FILLED');
    });
  });

  // ── getOrderDetail ─────────────────────────────────────────────────────────
  group('getOrderDetail', () {
    test('returns order + fills tuple', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: {
                  'order': _orderResponseJson(status: 'FILLED'),
                  'fills': [
                    {
                      'fill_id': 'fill-001',
                      'order_id': 'ord-001',
                      'qty': 100,
                      'price': '150.3000',
                      'exchange': 'NASDAQ',
                      'filled_at': '2026-04-15T09:31:00.000Z',
                    },
                  ],
                },
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/api/v1/orders/ord-001'),
              ));

      final (order, fills) = await dataSource.getOrderDetail('ord-001');
      expect(order.status, OrderStatus.filled);
      expect(fills, hasLength(1));
      expect(fills.first.fillId, 'fill-001');
    });
  });

  // ── getPositions ───────────────────────────────────────────────────────────
  group('getPositions', () {
    test('returns list of positions', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: {'positions': [_positionResponseJson()]},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/positions'),
              ));

      final positions = await dataSource.getPositions();
      expect(positions, hasLength(1));
      expect(positions.first.symbol, 'AAPL');
    });
  });

  // ── getPortfolioSummary ────────────────────────────────────────────────────
  group('getPortfolioSummary', () {
    test('returns portfolio summary', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: _portfolioSummaryResponseJson(),
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/api/v1/portfolio/summary'),
              ));

      final summary = await dataSource.getPortfolioSummary();
      expect(summary.totalEquity, Decimal.parse('100000.00'));
      expect(summary.buyingPower, Decimal.parse('75000.00'));
    });
  });
}
