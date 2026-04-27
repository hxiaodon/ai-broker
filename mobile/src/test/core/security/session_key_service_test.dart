import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockDio mockDio;
  late MockSecureStorageService mockStorage;
  late SessionKeyService service;

  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockSecureStorageService();
    service = SessionKeyService(dio: mockDio, storage: mockStorage);
  });

  Map<String, dynamic> serverResponse({
    String keyId = 'sk-001',
    String secret = 'dynamic-secret',
    String? expiresAt,
  }) =>
      {
        'key_id': keyId,
        'hmac_secret': secret,
        'expires_at': expiresAt ??
            DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 30))
                .toIso8601String(),
      };

  group('getSessionKey — no cache', () {
    test('fetches from server and returns keyId + secret', () async {
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-001', secret: 'sec-abc'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});

      final key = await service.getSessionKey();

      expect(key.keyId, 'sk-001');
      expect(key.secret, 'sec-abc');
      verify(() => mockDio.post<Map<String, dynamic>>('/api/v1/auth/session-key'))
          .called(1);
    });

    test('persists keyId, secret, expiresAt to SecureStorage', () async {
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});

      await service.getSessionKey();

      verify(() => mockStorage.write('trading.session_key_id', any())).called(1);
      verify(() => mockStorage.write('trading.session_key_secret', any())).called(1);
      verify(() => mockStorage.write('trading.session_key_expires_at', any())).called(1);
    });

    test('throws AuthException when server returns DioException', () async {
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any())).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
          ),
          requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
        ),
      );

      expect(
        () => service.getSessionKey(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('getSessionKey — in-memory cache', () {
    test('returns cached key without hitting server or storage', () async {
      // Prime the cache via a first fetch
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-cached', secret: 'sec-cached'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});

      await service.getSessionKey(); // first call — fetches
      final key = await service.getSessionKey(); // second call — from cache

      expect(key.keyId, 'sk-cached');
      // Server called exactly once
      verify(() => mockDio.post<Map<String, dynamic>>(any())).called(1);
    });
  });

  group('getSessionKey — storage cache', () {
    test('loads from SecureStorage when in-memory cache is empty', () async {
      final futureExpiry = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 20))
          .toIso8601String();

      when(() => mockStorage.read('trading.session_key_id'))
          .thenAnswer((_) async => 'sk-stored');
      when(() => mockStorage.read('trading.session_key_secret'))
          .thenAnswer((_) async => 'sec-stored');
      when(() => mockStorage.read('trading.session_key_expires_at'))
          .thenAnswer((_) async => futureExpiry);

      final key = await service.getSessionKey();

      expect(key.keyId, 'sk-stored');
      expect(key.secret, 'sec-stored');
      verifyNever(() => mockDio.post<Map<String, dynamic>>(any()));
    });
  });

  group('getSessionKey — expiry refresh', () {
    test('re-fetches when stored key is within 5 min of expiry', () async {
      // Expires in 3 minutes — within the 5-min refresh window
      final nearExpiry = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 3))
          .toIso8601String();

      when(() => mockStorage.read('trading.session_key_id'))
          .thenAnswer((_) async => 'sk-old');
      when(() => mockStorage.read('trading.session_key_secret'))
          .thenAnswer((_) async => 'sec-old');
      when(() => mockStorage.read('trading.session_key_expires_at'))
          .thenAnswer((_) async => nearExpiry);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-new', secret: 'sec-new'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});

      final key = await service.getSessionKey();

      expect(key.keyId, 'sk-new');
      verify(() => mockDio.post<Map<String, dynamic>>(any())).called(1);
    });

    test('does NOT re-fetch when key has more than 5 min remaining', () async {
      final safeExpiry = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 10))
          .toIso8601String();

      when(() => mockStorage.read('trading.session_key_id'))
          .thenAnswer((_) async => 'sk-valid');
      when(() => mockStorage.read('trading.session_key_secret'))
          .thenAnswer((_) async => 'sec-valid');
      when(() => mockStorage.read('trading.session_key_expires_at'))
          .thenAnswer((_) async => safeExpiry);

      final key = await service.getSessionKey();

      expect(key.keyId, 'sk-valid');
      verifyNever(() => mockDio.post<Map<String, dynamic>>(any()));
    });
  });

  group('rotate', () {
    test('always fetches from server regardless of cache state', () async {
      // Prime cache first
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-v1'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
      await service.getSessionKey();

      // Now rotate — should call server again
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-v2', secret: 'sec-v2'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));

      final rotated = await service.rotate();

      expect(rotated.keyId, 'sk-v2');
      verify(() => mockDio.post<Map<String, dynamic>>(any())).called(2);
    });
  });

  group('clear', () {
    test('deletes all three storage keys and clears in-memory cache', () async {
      when(() => mockStorage.delete(any())).thenAnswer((_) async {});

      await service.clear();

      verify(() => mockStorage.delete('trading.session_key_id')).called(1);
      verify(() => mockStorage.delete('trading.session_key_secret')).called(1);
      verify(() => mockStorage.delete('trading.session_key_expires_at')).called(1);
    });

    test('after clear, next getSessionKey fetches from server', () async {
      // Prime cache
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-before'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));
      when(() => mockStorage.write(any(), any())).thenAnswer((_) async {});
      await service.getSessionKey();

      when(() => mockStorage.delete(any())).thenAnswer((_) async {});
      await service.clear();

      // After clear, storage returns null
      when(() => mockStorage.read(any())).thenAnswer((_) async => null);
      when(() => mockDio.post<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => Response(
                data: serverResponse(keyId: 'sk-after'),
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/v1/auth/session-key'),
              ));

      final key = await service.getSessionKey();
      expect(key.keyId, 'sk-after');
    });
  });
}
