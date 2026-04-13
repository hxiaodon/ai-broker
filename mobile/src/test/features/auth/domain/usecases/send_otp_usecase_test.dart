import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:trading_app/features/auth/domain/usecases/send_otp_usecase.dart';

/// Unit tests for [SendOtpUseCase].
///
/// Tests business logic in isolation from network and UI layers.
/// Does not require Flutter or Riverpod context.
void main() {
  group('SendOtpUseCase', () {
    late _MockAuthRepository mockRepository;
    late SendOtpUseCase sendOtpUseCase;

    setUp(() {
      AppLogger.init(verbose: false);
      mockRepository = _MockAuthRepository();
      sendOtpUseCase = SendOtpUseCase(mockRepository);
    });

    // ─────────────────────────────────────────────────────────────────────
    // Happy Path Tests
    // ─────────────────────────────────────────────────────────────────────

    test('should send OTP for valid China phone number', () async {
      // Arrange
      const phoneNumber = '+8613812345678';
      final mockResult = OtpSendResult(
        requestId: 'req-123',
        maskedPhoneNumber: '+86****5678',
        expiresInSeconds: 300,
        retryAfterSeconds: 60,
      );

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenAnswer((_) async => mockResult);

      // Act
      final result = await sendOtpUseCase(phoneNumber: phoneNumber);

      // Assert
      expect(result.requestId, 'req-123');
      expect(result.expiresInSeconds, 300);
      verify(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).called(1);
    });

    test('should send OTP for valid Hong Kong phone number', () async {
      // Arrange
      const phoneNumber = '+85298765432';
      final mockResult = OtpSendResult(
        requestId: 'req-456',
        maskedPhoneNumber: '+852****5432',
        expiresInSeconds: 300,
        retryAfterSeconds: 60,
      );

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenAnswer((_) async => mockResult);

      // Act
      final result = await sendOtpUseCase(phoneNumber: phoneNumber);

      // Assert
      expect(result.requestId, 'req-456');
      verify(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).called(1);
    });

    test('should send OTP for valid US phone number', () async {
      // Arrange
      const phoneNumber = '+12125551234';
      final mockResult = OtpSendResult(
        requestId: 'req-789',
        maskedPhoneNumber: '+1****1234',
        expiresInSeconds: 300,
        retryAfterSeconds: 60,
      );

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenAnswer((_) async => mockResult);

      // Act
      final result = await sendOtpUseCase(phoneNumber: phoneNumber);

      // Assert
      expect(result.requestId, 'req-789');
      verify(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).called(1);
    });

    // ─────────────────────────────────────────────────────────────────────
    // Input Validation Tests
    // ─────────────────────────────────────────────────────────────────────

    test('should throw ValidationException for invalid phone format', () async {
      // Arrange
      const invalidPhone = '13812345678'; // missing + country code

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: invalidPhone),
        throwsA(isA<ValidationException>()),
      );

      // Verify repository was NOT called
      verifyNever(() => mockRepository.sendOtp(
        phoneNumber: any(named: 'phoneNumber'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ));
    });

    test('should throw ValidationException for short phone number', () async {
      // Arrange
      const shortPhone = '+861234567'; // too few digits

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: shortPhone),
        throwsA(isA<ValidationException>()),
      );

      verifyNever(() => mockRepository.sendOtp(
        phoneNumber: any(named: 'phoneNumber'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ));
    });

    test('should throw ValidationException for China phone with wrong digit count', () async {
      // Arrange
      const invalidChinaPhone = '+861234567890'; // 12 digits instead of 11

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: invalidChinaPhone),
        throwsA(isA<ValidationException>()),
      );

      verifyNever(() => mockRepository.sendOtp(
        phoneNumber: any(named: 'phoneNumber'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ));
    });

    test('should throw ValidationException for HK phone with wrong digit count', () async {
      // Arrange
      const invalidHkPhone = '+852123456789'; // 9 digits instead of 8

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: invalidHkPhone),
        throwsA(isA<ValidationException>()),
      );

      verifyNever(() => mockRepository.sendOtp(
        phoneNumber: any(named: 'phoneNumber'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ));
    });

    test('should throw ValidationException for US phone with wrong digit count', () async {
      // Arrange
      const invalidUsPhone = '+1212555'; // 7 digits instead of 10

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: invalidUsPhone),
        throwsA(isA<ValidationException>()),
      );

      verifyNever(() => mockRepository.sendOtp(
        phoneNumber: any(named: 'phoneNumber'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ));
    });

    // ─────────────────────────────────────────────────────────────────────
    // Repository Error Handling Tests
    // ─────────────────────────────────────────────────────────────────────

    test('should propagate BusinessException from repository (rate limited)', () async {
      // Arrange
      const phoneNumber = '+8613812345678';
      const businessError = BusinessException(
        message: 'Rate limit exceeded: max 3 OTP attempts per hour',
        errorCode: 'RATE_LIMIT_EXCEEDED',
      );

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenThrow(businessError);

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: phoneNumber),
        throwsA(isA<BusinessException>()),
      );
    });

    test('should propagate NetworkException from repository (no connectivity)', () async {
      // Arrange
      const phoneNumber = '+8613812345678';
      const networkError = NetworkException(
        message: 'Network timeout: failed to reach OTP service',
        statusCode: 503,
      );

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenThrow(networkError);

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: phoneNumber),
        throwsA(isA<NetworkException>()),
      );
    });

    test('should wrap unexpected errors in NetworkException', () async {
      // Arrange
      const phoneNumber = '+8613812345678';

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenThrow(Exception('Unexpected database error'));

      // Act & Assert
      expect(
        sendOtpUseCase(phoneNumber: phoneNumber),
        throwsA(isA<NetworkException>()),
      );
    });

    // ─────────────────────────────────────────────────────────────────────
    // Idempotency Tests
    // ─────────────────────────────────────────────────────────────────────

    test('should generate different idempotency keys on each call', () async {
      // Arrange
      const phoneNumber = '+8613812345678';
      final mockResult = OtpSendResult(
        requestId: 'req-123',
        maskedPhoneNumber: '+86****5678',
        expiresInSeconds: 300,
        retryAfterSeconds: 60,
      );

      final capturedKeys = <String>[];

      when(() => mockRepository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: any(named: 'idempotencyKey'),
      )).thenAnswer((invocation) {
        capturedKeys.add(
          invocation.namedArguments[Symbol('idempotencyKey')] as String,
        );
        return Future.value(mockResult);
      });

      // Act - call multiple times
      await sendOtpUseCase(phoneNumber: phoneNumber);
      await sendOtpUseCase(phoneNumber: phoneNumber);
      await sendOtpUseCase(phoneNumber: phoneNumber);

      // Assert - all keys should be unique (UUID v4)
      expect(capturedKeys.length, 3);
      expect(capturedKeys.toSet().length, 3); // All unique
      expect(capturedKeys.every((k) => RegExp(r'^[a-f0-9-]+$').hasMatch(k)), true);
    });
  });
}

class _MockAuthRepository extends Mock implements AuthRepository {}
