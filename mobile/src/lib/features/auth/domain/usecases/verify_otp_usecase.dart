import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../repositories/auth_repository.dart';

/// UseCase for verifying OTP code.
///
/// Business logic:
/// - OTP code format validation (6 digits)
/// - Request ID and phone number validation
/// - Idempotency handling for network retries
/// - Token persistence on successful verification
class VerifyOtpUseCase {
  VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;
  static const _uuidGenerator = Uuid();

  /// Verify OTP code for a phone number.
  ///
  /// Business Logic:
  /// 1. Validate OTP format (exactly 6 digits)
  /// 2. Validate request ID is not empty
  /// 3. Generate idempotency key
  /// 4. Call repository.verifyOtp()
  /// 5. Return OtpVerifyResult (token for existing users, null for new users)
  ///
  /// Throws [ValidationException] if inputs are invalid.
  /// Throws [AuthException] if OTP is wrong, expired, or locked out.
  /// Throws [BusinessException] if rate-limited or account issues.
  /// Throws [NetworkException] on network failure.
  Future<OtpVerifyResult> call({
    required String requestId,
    required String phoneNumber,
    required String otpCode,
  }) async {
    // ─── Input Validation ───────────────────────────────────────────────
    _validateInputs(requestId, phoneNumber, otpCode);

    // ─── Idempotency Key ────────────────────────────────────────────────
    final idempotencyKey = _uuidGenerator.v4();
    AppLogger.debug(
      'VerifyOtpUseCase: requestId=$requestId, '
      'phone=$phoneNumber, idempotency=$idempotencyKey',
    );

    try {
      // ─── Repository Call ────────────────────────────────────────────
      final result = await _repository.verifyOtp(
        requestId: requestId,
        phoneNumber: phoneNumber,
        otpCode: otpCode,
        idempotencyKey: idempotencyKey,
      );

      // ─── Log Result ──────────────────────────────────────────────────
      switch (result.status) {
        case OtpVerifyStatus.existingUser:
          AppLogger.info(
            'OTP verified successfully for existing user: accountId=${result.token?.accountId}',
          );
        case OtpVerifyStatus.newUser:
          AppLogger.info(
            'OTP verified successfully for new user: requires profile setup',
          );
      }

      return result;
    } on AuthException catch (e) {
      AppLogger.warning('OTP verification failed: ${e.message}');
      rethrow;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('VerifyOtpUseCase failed', error: e, stackTrace: st);
      throw NetworkException(
        message: 'Failed to verify OTP: $e',
        cause: e,
      );
    }
  }

  /// Validate all input parameters.
  ///
  /// Throws [ValidationException] for any invalid input.
  void _validateInputs(String requestId, String phoneNumber, String otpCode) {
    // Check request ID
    if (requestId.isEmpty) {
      throw ValidationException(
        message: 'Request ID cannot be empty',
        field: 'requestId',
      );
    }

    // Check phone number
    if (phoneNumber.isEmpty) {
      throw ValidationException(
        message: 'Phone number cannot be empty',
        field: 'phoneNumber',
      );
    }

    // Check OTP format: exactly 6 digits
    if (!RegExp(r'^\d{6}$').hasMatch(otpCode)) {
      throw ValidationException(
        message: 'Invalid OTP format: must be exactly 6 digits (got ${otpCode.length} chars)',
        field: 'otpCode',
      );
    }
  }
}
