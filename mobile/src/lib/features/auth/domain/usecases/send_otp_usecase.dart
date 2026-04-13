import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../repositories/auth_repository.dart';

/// UseCase for sending OTP via SMS.
///
/// Encapsulates business logic:
/// - Phone number validation
/// - Idempotency key generation
/// - OTP request lifecycle management
class SendOtpUseCase {
  SendOtpUseCase(this._repository);

  final AuthRepository _repository;
  static const _uuidGenerator = Uuid();

  /// Send OTP to [phoneNumber].
  ///
  /// Business Logic:
  /// 1. Validate phone number format (+8613812345678, +852XXXXXXXX, etc.)
  /// 2. Generate idempotency key (UUID v4) for network retries
  /// 3. Call repository.sendOtp()
  /// 4. Return OtpSendResult with requestId, expiresIn, retryAfter
  ///
  /// Throws [ValidationException] if phone format is invalid.
  /// Throws [BusinessException] if rate-limited or account is locked.
  /// Throws [NetworkException] on network failure.
  Future<OtpSendResult> call({required String phoneNumber}) async {
    // ─── Input Validation ───────────────────────────────────────────────
    _validatePhoneNumber(phoneNumber);

    // ─── Idempotency Key ────────────────────────────────────────────────
    // Generate UUID v4 for network retry idempotency.
    // Same key + same request = server returns cached response.
    final idempotencyKey = _uuidGenerator.v4();
    AppLogger.debug('SendOtpUseCase: phone=$phoneNumber, idempotency=$idempotencyKey');

    try {
      // ─── Repository Call ────────────────────────────────────────────
      final result = await _repository.sendOtp(
        phoneNumber: phoneNumber,
        idempotencyKey: idempotencyKey,
      );

      AppLogger.info(
        'OTP sent successfully: '
        'phone=$phoneNumber (masked=${result.maskedPhoneNumber}), '
        'expiresIn=${result.expiresInSeconds}s',
      );

      return result;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('SendOtpUseCase failed', error: e, stackTrace: st);
      throw NetworkException(
        message: 'Failed to send OTP: $e',
        cause: e,
      );
    }
  }

  /// Validate phone number format.
  ///
  /// Accepted formats:
  /// - +86 (China): +8613812345678 (11 digits after country code)
  /// - +852 (Hong Kong): +852XXXXXXXX (8 digits after country code)
  /// - +1 (US): +1 followed by 10 digits
  ///
  /// Throws [ValidationException] if format is invalid.
  void _validatePhoneNumber(String phoneNumber) {
    // Regex: + followed by 1-3 digit country code + 8-15 digit number
    final regex = RegExp(r'^\+\d{1,3}\d{8,15}$');
    if (!regex.hasMatch(phoneNumber)) {
      throw ValidationException(
        message: 'Invalid phone number format: $phoneNumber. '
            'Expected format: +countrycode + 8-15 digits (e.g., +8613812345678)',
        field: 'phoneNumber',
      );
    }

    // Additional validation: check for known country codes
    if (phoneNumber.startsWith('+86')) {
      // China: +86 + 11 digits
      if (!RegExp(r'^\+86\d{11}$').hasMatch(phoneNumber)) {
        throw ValidationException(
          message: 'Invalid Chinese phone number: must be +86 + 11 digits',
          field: 'phoneNumber',
        );
      }
    } else if (phoneNumber.startsWith('+852')) {
      // Hong Kong: +852 + 8 digits
      if (!RegExp(r'^\+852\d{8}$').hasMatch(phoneNumber)) {
        throw ValidationException(
          message: 'Invalid HK phone number: must be +852 + 8 digits',
          field: 'phoneNumber',
        );
      }
    } else if (phoneNumber.startsWith('+1')) {
      // US: +1 + 10 digits
      if (!RegExp(r'^\+1\d{10}$').hasMatch(phoneNumber)) {
        throw ValidationException(
          message: 'Invalid US phone number: must be +1 + 10 digits',
          field: 'phoneNumber',
        );
      }
    }
  }
}
