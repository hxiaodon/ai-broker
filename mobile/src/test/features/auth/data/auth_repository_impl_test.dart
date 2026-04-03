import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/device_info_service.dart';
import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/auth/data/auth_repository_impl.dart';
import 'package:trading_app/features/auth/data/remote/auth_remote_data_source.dart';
import 'package:trading_app/features/auth/data/remote/auth_request_models.dart';
import 'package:trading_app/features/auth/data/remote/auth_response_models.dart';
import 'package:trading_app/features/auth/domain/repositories/auth_repository.dart';

// Mocks
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockTokenService extends Mock implements TokenService {}
class MockDeviceInfoService extends Mock implements DeviceInfoService {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

// Fake classes for mocktail
class FakeSendOtpRequest extends Fake implements SendOtpRequest {}
class FakeVerifyOtpRequest extends Fake implements VerifyOtpRequest {}
class FakeRefreshTokenRequest extends Fake implements RefreshTokenRequest {}
class FakeRegisterBiometricRequest extends Fake implements RegisterBiometricRequest {}
class FakeVerifyBiometricRequest extends Fake implements VerifyBiometricRequest {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockTokenService mockTokenService;
  late MockDeviceInfoService mockDeviceInfoService;
  late MockSecureStorageService mockSecureStorage;

  setUpAll(() {
    registerFallbackValue(FakeSendOtpRequest());
    registerFallbackValue(FakeVerifyOtpRequest());
    registerFallbackValue(FakeRefreshTokenRequest());
    registerFallbackValue(FakeRegisterBiometricRequest());
    registerFallbackValue(FakeVerifyBiometricRequest());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockTokenService = MockTokenService();
    mockDeviceInfoService = MockDeviceInfoService();
    mockSecureStorage = MockSecureStorageService();

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      tokenService: mockTokenService,
      deviceInfoService: mockDeviceInfoService,
      secureStorage: mockSecureStorage,
    );

    // Default device info mock
    when(() => mockDeviceInfoService.getDeviceInfo()).thenAnswer(
      (_) async => DeviceInfo(
        deviceId: 'test_device_id',
        deviceName: 'Test Device',
        osType: 'iOS',
        osVersion: '17.0',
        appVersion: '1.0.0',
      ),
    );
  });

  group('AuthRepositoryImpl - sendOtp', () {
    test('sendOtp success returns OtpSendResult', () async {
      final response = SendOtpResponse(
        requestId: 'req_123',
        phoneNumber: '138****8888',
        expiresInSeconds: 300,
        retryAfterSeconds: 60,
      );

      when(() => mockRemoteDataSource.sendOtp(
            request: any(named: 'request'),
            idempotencyKey: any(named: 'idempotencyKey'),
            deviceId: any(named: 'deviceId'),
          )).thenAnswer((_) async => response);

      final result = await repository.sendOtp(
        phoneNumber: '+8613812345678',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.requestId, 'req_123');
      expect(result.maskedPhoneNumber, '138****8888');
      expect(result.expiresInSeconds, 300);
      expect(result.retryAfterSeconds, 60);

      verify(() => mockRemoteDataSource.sendOtp(
            request: any(named: 'request'),
            idempotencyKey: 'idem_key_123',
            deviceId: 'test_device_id',
          )).called(1);
    });

    test('sendOtp throws on network error', () async {
      when(() => mockRemoteDataSource.sendOtp(
            request: any(named: 'request'),
            idempotencyKey: any(named: 'idempotencyKey'),
            deviceId: any(named: 'deviceId'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/v1/auth/otp/send'),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(
        () => repository.sendOtp(
          phoneNumber: '+8613812345678',
          idempotencyKey: 'idem_key_123',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRepositoryImpl - verifyOtp', () {
    test('verifyOtp success for existing user saves tokens', () async {
      final responseJson = {
        'status': 'OTP_VERIFIED_EXISTING_USER',
        'access_token': 'access_token_123',
        'refresh_token': 'refresh_token_123',
        'expires_in_seconds': 900,
        'account_id': 'acc_123',
        'account_status': 'ACTIVE',
      };

      when(() => mockRemoteDataSource.verifyOtp(
            request: any(named: 'request'),
            idempotencyKey: any(named: 'idempotencyKey'),
            deviceId: any(named: 'deviceId'),
          )).thenAnswer((_) async => responseJson);

      when(() => mockTokenService.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
          )).thenAnswer((_) async {});

      final result = await repository.verifyOtp(
        requestId: 'req_123',
        otpCode: '123456',
        phoneNumber: '+8613812345678',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.status, OtpVerifyStatus.existingUser);
      expect(result.token, isNotNull);
      expect(result.token!.accessToken, 'access_token_123');
      expect(result.token!.refreshToken, 'refresh_token_123');
      expect(result.token!.accountId, 'acc_123');
      expect(result.token!.accountStatus, 'ACTIVE');

      verify(() => mockTokenService.saveTokens(
            accessToken: 'access_token_123',
            refreshToken: 'refresh_token_123',
            accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
          )).called(1);
    });

    test('verifyOtp success for new user returns newUser status', () async {
      final responseJson = {
        'status': 'OTP_VERIFIED_NEW_USER',
      };

      when(() => mockRemoteDataSource.verifyOtp(
            request: any(named: 'request'),
            idempotencyKey: any(named: 'idempotencyKey'),
            deviceId: any(named: 'deviceId'),
          )).thenAnswer((_) async => responseJson);

      final result = await repository.verifyOtp(
        requestId: 'req_123',
        otpCode: '123456',
        phoneNumber: '+8613812345678',
        idempotencyKey: 'idem_key_123',
      );

      expect(result.status, OtpVerifyStatus.newUser);
      expect(result.token, isNull);

      verifyNever(() => mockTokenService.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
          ));
    });

    test('verifyOtp throws on invalid OTP', () async {
      when(() => mockRemoteDataSource.verifyOtp(
            request: any(named: 'request'),
            idempotencyKey: any(named: 'idempotencyKey'),
            deviceId: any(named: 'deviceId'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/v1/auth/otp/verify'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/otp/verify'),
          statusCode: 400,
          data: {'error_code': 'INVALID_OTP_CODE'},
        ),
      ));

      expect(
        () => repository.verifyOtp(
          requestId: 'req_123',
          otpCode: '000000',
          phoneNumber: '+8613812345678',
          idempotencyKey: 'idem_key_123',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRepositoryImpl - refreshToken', () {
    test('refreshToken success saves new tokens', () async {
      final response = RefreshTokenResponse(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        expiresInSeconds: 900,
      );

      when(() => mockRemoteDataSource.refreshToken(
            request: any(named: 'request'),
            deviceId: any(named: 'deviceId'),
          )).thenAnswer((_) async => response);

      when(() => mockTokenService.getAccessToken())
          .thenAnswer((_) async => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2NvdW50X2lkIjoiYWNjXzEyMyJ9.test');

      when(() => mockTokenService.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
            accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
          )).thenAnswer((_) async {});

      final result = await repository.refreshToken(
        refreshToken: 'old_refresh_token',
      );

      expect(result.accessToken, 'new_access_token');
      expect(result.refreshToken, 'new_refresh_token');
      expect(result.accountId, 'acc_123');

      verify(() => mockTokenService.saveTokens(
            accessToken: 'new_access_token',
            refreshToken: 'new_refresh_token',
            accessTokenExpiresAt: any(named: 'accessTokenExpiresAt'),
          )).called(1);
    });

    test('refreshToken throws on expired refresh token', () async {
      when(() => mockRemoteDataSource.refreshToken(
            request: any(named: 'request'),
            deviceId: any(named: 'deviceId'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/v1/auth/token/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/v1/auth/token/refresh'),
          statusCode: 401,
          data: {'error_code': 'REFRESH_TOKEN_EXPIRED'},
        ),
      ));

      expect(
        () => repository.refreshToken(refreshToken: 'expired_token'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRepositoryImpl - registerBiometric', () {
    test('registerBiometric success marks biometric as registered', () async {
      when(() => mockRemoteDataSource.registerBiometric(
            request: any(named: 'request'),
            deviceId: any(named: 'deviceId'),
          )).thenAnswer((_) async {});

      when(() => mockSecureStorage.write(any(), any()))
          .thenAnswer((_) async {});

      await repository.registerBiometric(
        biometricType: 'FACE_ID',
        deviceFingerprint: 'fingerprint_123',
        deviceName: 'iPhone 15',
      );

      verify(() => mockRemoteDataSource.registerBiometric(
            request: any(named: 'request'),
            deviceId: 'test_device_id',
          )).called(1);

      verify(() => mockSecureStorage.write('auth.biometric_registered', 'true'))
          .called(1);
    });
  });

  group('AuthRepositoryImpl - verifyBiometric', () {
    test('verifyBiometric success returns verification token', () async {
      final response = VerifyBiometricResponse(
        verificationToken: 'verify_token_123',
        expiresInSeconds: 300,
      );

      when(() => mockRemoteDataSource.verifyBiometric(
            request: any(named: 'request'),
            biometricSignature: any(named: 'biometricSignature'),
            deviceId: any(named: 'deviceId'),
          )).thenAnswer((_) async => response);

      final result = await repository.verifyBiometric(
        operation: 'DEVICE_REVOKE',
        biometricSignature: 'signature_123',
        deviceFingerprint: 'fingerprint_123',
      );

      expect(result, 'verify_token_123');
    });
  });

  group('AuthRepositoryImpl - logout', () {
    test('logout clears tokens and biometric registration', () async {
      when(() => mockRemoteDataSource.logout(deviceId: any(named: 'deviceId')))
          .thenAnswer((_) async {});

      when(() => mockTokenService.clearTokens()).thenAnswer((_) async {});

      when(() => mockSecureStorage.delete(any())).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemoteDataSource.logout(deviceId: 'test_device_id'))
          .called(1);
      verify(() => mockTokenService.clearTokens()).called(1);
      verify(() => mockSecureStorage.delete('auth.biometric_registered'))
          .called(1);
    });

    test('logout clears local state even if server call fails', () async {
      when(() => mockRemoteDataSource.logout(deviceId: any(named: 'deviceId')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/v1/auth/logout'),
        type: DioExceptionType.connectionTimeout,
      ));

      when(() => mockTokenService.clearTokens()).thenAnswer((_) async {});

      when(() => mockSecureStorage.delete(any())).thenAnswer((_) async {});

      // Should not throw
      await repository.logout();

      verify(() => mockTokenService.clearTokens()).called(1);
      verify(() => mockSecureStorage.delete('auth.biometric_registered'))
          .called(1);
    });
  });

  group('AuthRepositoryImpl - getDevices', () {
    test('getDevices returns list of devices', () async {
      final response = GetDevicesResponse(
        devices: [
          DeviceInfoDto(
            deviceId: 'device_1',
            deviceName: 'iPhone 15',
            osType: 'iOS',
            status: 'ACTIVE',
            loginTime: '2024-01-15T10:00:00Z',
            lastActivityTime: '2024-01-15T12:00:00Z',
            isCurrentDevice: true,
            biometricRegistered: true,
            biometricType: 'FACE_ID',
          ),
          DeviceInfoDto(
            deviceId: 'device_2',
            deviceName: 'iPad Pro',
            osType: 'iOS',
            status: 'ACTIVE',
            loginTime: '2024-01-14T10:00:00Z',
            lastActivityTime: '2024-01-14T15:00:00Z',
            isCurrentDevice: false,
            biometricRegistered: false,
          ),
        ],
      );

      when(() => mockRemoteDataSource.getDevices(deviceId: any(named: 'deviceId')))
          .thenAnswer((_) async => response);

      final result = await repository.getDevices();

      expect(result.length, 2);
      expect(result[0].deviceId, 'device_1');
      expect(result[0].deviceName, 'iPhone 15');
      expect(result[0].isCurrentDevice, true);
      expect(result[0].biometricRegistered, true);
      expect(result[1].deviceId, 'device_2');
      expect(result[1].isCurrentDevice, false);
    });
  });

  group('AuthRepositoryImpl - revokeDevice', () {
    test('revokeDevice calls remote data source', () async {
      when(() => mockRemoteDataSource.revokeDevice(
            targetDeviceId: any(named: 'targetDeviceId'),
            currentDeviceId: any(named: 'currentDeviceId'),
            biometricSignature: any(named: 'biometricSignature'),
          )).thenAnswer((_) async {});

      await repository.revokeDevice(
        targetDeviceId: 'device_to_revoke',
        biometricSignature: 'signature_123',
      );

      verify(() => mockRemoteDataSource.revokeDevice(
            targetDeviceId: 'device_to_revoke',
            currentDeviceId: 'test_device_id',
            biometricSignature: 'signature_123',
          )).called(1);
    });
  });

  group('AuthRepositoryImpl - isBiometricRegistered', () {
    test('isBiometricRegistered returns true when registered', () async {
      when(() => mockSecureStorage.read('auth.biometric_registered'))
          .thenAnswer((_) async => 'true');

      final result = await repository.isBiometricRegistered();

      expect(result, true);
    });

    test('isBiometricRegistered returns false when not registered', () async {
      when(() => mockSecureStorage.read('auth.biometric_registered'))
          .thenAnswer((_) async => null);

      final result = await repository.isBiometricRegistered();

      expect(result, false);
    });

    test('isBiometricRegistered returns false for non-true value', () async {
      when(() => mockSecureStorage.read('auth.biometric_registered'))
          .thenAnswer((_) async => 'false');

      final result = await repository.isBiometricRegistered();

      expect(result, false);
    });
  });
}
