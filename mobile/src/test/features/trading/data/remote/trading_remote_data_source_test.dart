import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/core/security/hmac_signer.dart';
import 'package:trading_app/features/trading/data/remote/trading_remote_data_source.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockDio extends Mock implements Dio {}

class MockConnectivityService extends Mock implements ConnectivityService {}

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
      'qty': 100,
      'available_qty': 80,
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
      'market_value': '50000.00',
      'day_pnl': '1200.50',
      'day_pnl_pct': '1.22',
      'total_pnl': '5000.00',
      'total_pnl_pct': '5.26',
      'buying_power': '75000.00',
      'settled_cash': '45000.00',
    };

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockDio mockDio;
  late MockConnectivityService mockConnectivity;
  late TradingRemoteDataSource dataSource;

  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockConnectivity = MockConnectivityService();
    dataSource = TradingRemoteDataSource(
      dio: mockDio,
      signer: const HmacSigner('test-secret'),
      connectivity: mockConnectivity,
    );
    when(() => mockConnectivity.isConnected).thenAnswer((_) async => true);
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
    test('sends POST with HMAC headers and idempotency key', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: _orderResponseJson(),
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/orders'),
          ));

      final order = await dataSource.submitOrder(
        symbol: 'AAPL',
        market: 'US',
        side: OrderSide.buy,
        orderType: OrderType.limit,
        qty: 100,
        limitPrice: Decimal.parse('150.2500'),
        validity: OrderValidity.day,
        extendedHours: false,
        idempotencyKey: 'test-key-123',
        biometricToken: 'bio-token',
      );

      expect(order.orderId, 'ord-001');
      expect(order.symbol, 'AAPL');

      final captured = verify(() => mockDio.post<Map<String, dynamic>>(
            '/api/v1/orders',
            data: any(named: 'data'),
            options: captureAny(named: 'options'),
          )).captured.single as Options;

      expect(captured.headers!['Idempotency-Key'], 'test-key-123');
      expect(captured.headers!['X-Biometric-Token'], 'bio-token');
      expect(captured.headers!['X-Timestamp'], isNotNull);
      expect(captured.headers!['X-Signature'], isNotNull);
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
          biometricToken: 'bio',
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
          data: {'error_code': 'INSUFFICIENT_BUYING_POWER', 'message': 'Not enough funds'},
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
          biometricToken: 'bio',
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
          biometricToken: 'bio',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ── cancelOrder ────────────────────────────────────────────────────────────
  group('cancelOrder', () {
    test('sends DELETE with HMAC headers', () async {
      when(() => mockDio.delete<void>(
            any(),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            statusCode: 202,
            requestOptions: RequestOptions(path: '/api/v1/orders/ord-001'),
          ));

      await dataSource.cancelOrder('ord-001');

      final captured = verify(() => mockDio.delete<void>(
            '/api/v1/orders/ord-001',
            options: captureAny(named: 'options'),
          )).captured.single as Options;

      expect(captured.headers!['X-Timestamp'], isNotNull);
      expect(captured.headers!['X-Signature'], isNotNull);
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
              'orders': [_orderResponseJson(), _orderResponseJson(status: 'FILLED')],
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
                data: {
                  'positions': [_positionResponseJson()],
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/positions'),
              ));

      final positions = await dataSource.getPositions();
      expect(positions, hasLength(1));
      expect(positions.first.symbol, 'AAPL');
    });
  });

  // ── getPositionDetail ──────────────────────────────────────────────────────
  group('getPositionDetail', () {
    test('returns single position', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: _positionResponseJson(),
                statusCode: 200,
                requestOptions:
                    RequestOptions(path: '/api/v1/positions/AAPL'),
              ));

      final pos = await dataSource.getPositionDetail('AAPL');
      expect(pos.symbol, 'AAPL');
      expect(pos.qty, 100);
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
