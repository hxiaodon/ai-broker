import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/domain/entities/auth_token.dart';
import 'package:trading_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:trading_app/features/auth/domain/usecases/verify_otp_usecase.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late VerifyOtpUseCase verifyOtpUseCase;
  late _MockAuthRepository mockRepository;

  setUp(() {
    AppLogger.init(verbose: false);
    mockRepository = _MockAuthRepository();
    verifyOtpUseCase = VerifyOtpUseCase(mockRepository);
  });

  group('VerifyOtpUseCase', () {
    // ─── Happy Path Tests ───────────────────────────────────────────
    group('Happy Path', () {
      test('should verify OTP and return token for existing user', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '123456';

        final mockToken = AuthToken(
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          accountId: 'account-123',
          accountStatus: 'ACTIVE',
        );

        when(() => mockRepository.verifyOtp(
          requestId: any(named: 'requestId'),
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => OtpVerifyResult(
          status: OtpVerifyStatus.existingUser,
          token: mockToken,
        ));

        // Act
        final result = await verifyOtpUseCase(
          requestId: requestId,
          phoneNumber: phoneNumber,
          otpCode: otpCode,
        );

        // Assert
        expect(result.status, OtpVerifyStatus.existingUser);
        expect(result.token, mockToken);
      });

      test('should verify OTP and return null token for new user', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '123456';

        when(() => mockRepository.verifyOtp(
          requestId: any(named: 'requestId'),
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => OtpVerifyResult(
          status: OtpVerifyStatus.newUser,
          token: null,
        ));

        // Act
        final result = await verifyOtpUseCase(
          requestId: requestId,
          phoneNumber: phoneNumber,
          otpCode: otpCode,
        );

        // Assert
        expect(result.status, OtpVerifyStatus.newUser);
        expect(result.token, null);
      });
    });

    // ─── Validation Tests ───────────────────────────────────────────
    group('Input Validation', () {
      test('should throw ValidationException for empty request ID', () async {
        // Arrange
        const requestId = '';
        const phoneNumber = '+8613812345678';
        const otpCode = '123456';

        // Act & Assert
        expect(
          () => verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'requestId',
          )),
        );
      });

      test('should throw ValidationException for empty phone number', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '';
        const otpCode = '123456';

        // Act & Assert
        expect(
          () => verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'phoneNumber',
          )),
        );
      });

      test('should throw ValidationException for invalid OTP format (non-numeric)', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = 'abc123'; // Not all digits

        // Act & Assert
        expect(
          () => verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'otpCode',
          )),
        );
      });

      test('should throw ValidationException for OTP with wrong length (5 digits)', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '12345'; // Only 5 digits

        // Act & Assert
        expect(
          () => verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'otpCode',
          )),
        );
      });

      test('should throw ValidationException for OTP with wrong length (7 digits)', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '1234567'; // 7 digits

        // Act & Assert
        expect(
          () => verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<ValidationException>().having(
            (e) => e.field,
            'field',
            'otpCode',
          )),
        );
      });
    });

    // ─── Error Handling Tests ───────────────────────────────────────
    group('Error Handling', () {
      test('should propagate AuthException (wrong OTP)', () {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '999999';

        when(() => mockRepository.verifyOtp(
          requestId: any(named: 'requestId'),
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(AuthException(message: 'Invalid OTP'));

        // Act & Assert
        expect(
          verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should propagate BusinessException (rate limit)', () {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '123456';

        when(() => mockRepository.verifyOtp(
          requestId: any(named: 'requestId'),
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(BusinessException(message: 'Too many attempts'));

        // Act & Assert
        expect(
          verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<BusinessException>()),
        );
      });

      test('should wrap unexpected Exception in NetworkException', () {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '123456';

        when(() => mockRepository.verifyOtp(
          requestId: any(named: 'requestId'),
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          verifyOtpUseCase(
            requestId: requestId,
            phoneNumber: phoneNumber,
            otpCode: otpCode,
          ),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    // ─── Idempotency Tests ──────────────────────────────────────────
    group('Idempotency', () {
      test('should generate unique idempotency keys on each call', () async {
        // Arrange
        const requestId = 'req-12345';
        const phoneNumber = '+8613812345678';
        const otpCode = '123456';

        final capturedKeys = <String>[];

        when(() => mockRepository.verifyOtp(
          requestId: any(named: 'requestId'),
          phoneNumber: any(named: 'phoneNumber'),
          otpCode: any(named: 'otpCode'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((invocation) {
          final key = invocation.namedArguments[#idempotencyKey] as String;
          capturedKeys.add(key);
          return Future.value(OtpVerifyResult(
            status: OtpVerifyStatus.newUser,
            token: null,
          ));
        });

        // Act
        await verifyOtpUseCase(
          requestId: requestId,
          phoneNumber: phoneNumber,
          otpCode: otpCode,
        );
        await verifyOtpUseCase(
          requestId: requestId,
          phoneNumber: phoneNumber,
          otpCode: otpCode,
        );
        await verifyOtpUseCase(
          requestId: requestId,
          phoneNumber: phoneNumber,
          otpCode: otpCode,
        );

        // Assert
        expect(capturedKeys.length, 3);
        expect(capturedKeys[0], isNotEmpty);
        expect(capturedKeys[1], isNotEmpty);
        expect(capturedKeys[2], isNotEmpty);
        expect(capturedKeys[0] != capturedKeys[1], true);
        expect(capturedKeys[1] != capturedKeys[2], true);
        expect(capturedKeys[0] != capturedKeys[2], true);
      });
    });
  });
}
