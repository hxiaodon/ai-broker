import '../entities/auth_token.dart';
import '../entities/device_info_entity.dart';

/// Abstract repository interface for authentication operations.
///
/// Implementations live in the data layer and are injected via Riverpod.
/// All methods may throw [AppException] subtypes on failure.
abstract class AuthRepository {
  /// Send OTP to [phoneNumber] via SMS.
  ///
  /// Returns [requestId] for use in [verifyOtp].
  /// Throws [BusinessException] with errorCode from AMS on rate limit / account locked.
  Future<OtpSendResult> sendOtp({
    required String phoneNumber,
    required String idempotencyKey,
  });

  /// Verify [otpCode] against the OTP request identified by [requestId].
  ///
  /// Returns [AuthToken] on success for existing users.
  /// Returns null accessToken + [OtpVerifyStatus.newUser] for new users
  /// who must complete profile setup.
  Future<OtpVerifyResult> verifyOtp({
    required String requestId,
    required String otpCode,
    required String phoneNumber,
    required String idempotencyKey,
  });

  /// Silently refresh the access token using the stored refresh token.
  ///
  /// Returns a new [AuthToken] with rotated refresh token.
  /// Throws [AuthException] if refresh token is expired/invalid/already-used.
  Future<AuthToken> refreshToken({required String refreshToken});

  /// Register biometric credential on the current device.
  ///
  /// [biometricType]: FACE_ID | FINGERPRINT | TOUCH_ID
  /// [deviceFingerprint]: hash of device biometric enrollment (for change detection)
  Future<void> registerBiometric({
    required String biometricType,
    required String deviceFingerprint,
    String? deviceName,
  });

  /// Verify biometric signature for a sensitive [operation].
  ///
  /// Returns a short-lived verification token on success.
  Future<String> verifyBiometric({
    required String operation,
    required String biometricSignature,
    required String deviceFingerprint,
  });

  /// Revoke the current session and clear server-side tokens.
  Future<void> logout();

  /// Fetch all devices registered to the authenticated user.
  Future<List<DeviceInfoEntity>> getDevices();

  /// Remotely revoke [targetDeviceId] after biometric confirmation.
  Future<void> revokeDevice({
    required String targetDeviceId,
    required String biometricSignature,
  });

  /// Check whether biometric has been registered on this device.
  Future<bool> isBiometricRegistered();
}

/// Result from OTP send endpoint.
class OtpSendResult {
  const OtpSendResult({
    required this.requestId,
    required this.maskedPhoneNumber,
    required this.expiresInSeconds,
    required this.retryAfterSeconds,
  });

  final String requestId;
  final String maskedPhoneNumber;
  final int expiresInSeconds;
  final int retryAfterSeconds;
}

/// Status of OTP verification.
enum OtpVerifyStatus {
  existingUser,
  newUser,
}

/// Result from OTP verify endpoint.
class OtpVerifyResult {
  const OtpVerifyResult({
    required this.status,
    this.token,
    this.accountStatus,
    int? remainingAttempts,
    DateTime? lockoutUntil,
  }) : _remainingAttempts = remainingAttempts,
       _lockoutUntil = lockoutUntil;

  final OtpVerifyStatus status;
  final AuthToken? token;
  final String? accountStatus;
  final int? _remainingAttempts;
  final DateTime? _lockoutUntil;

  int? get remainingAttempts => _remainingAttempts;
  DateTime? get lockoutUntil => _lockoutUntil;
}
