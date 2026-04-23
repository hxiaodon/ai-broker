import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/security/nonce_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() => AppLogger.init());
  late MockDio mockDio;
  late NonceService service;

  setUp(() {
    mockDio = MockDio();
    service = NonceService(dio: mockDio);
  });

  group('NonceService.fetchNonce', () {
    test('returns nonce string on 200 response', () async {
      when(() => mockDio.get<Map<String, dynamic>>(
            '/api/v1/trading/nonce',
          )).thenAnswer((_) async => Response(
            data: {
              'nonce': 'n-abc123def456',
              'expires_at': '2026-04-23T10:00:00Z',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
          ));

      final nonce = await service.fetchNonce();

      expect(nonce, 'n-abc123def456');
    });

    test('nonce is non-empty string', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: {'nonce': 'n-unique-value', 'expires_at': '2026-04-23T10:00:00Z'},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
              ));

      final nonce = await service.fetchNonce();
      expect(nonce, isNotEmpty);
    });

    test('each call hits the endpoint — nonces are never cached', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: {'nonce': 'n-fresh', 'expires_at': '2026-04-23T10:00:00Z'},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
              ));

      await service.fetchNonce();
      await service.fetchNonce();

      // Two calls → two network requests (nonces must never be reused)
      verify(() => mockDio.get<Map<String, dynamic>>(any())).called(2);
    });

    test('DioException is mapped to NetworkException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        ),
      );

      expect(
        () => service.fetchNonce(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('network error message mentions nonce context', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      await expectLater(
        () => service.fetchNonce(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message.toLowerCase(),
            'message mentions nonce',
            contains('nonce'),
          ),
        ),
      );
    });

    test('server 500 wrapped in NetworkException', () async {
      when(() => mockDio.get<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/api/v1/trading/nonce'),
          ),
        ),
      );

      expect(() => service.fetchNonce(), throwsA(isA<NetworkException>()));
    });
  });
}
