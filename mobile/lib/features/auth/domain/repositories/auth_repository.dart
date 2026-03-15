import '../../domain/entities/auth_token.dart';

/// Repository interface for authentication operations.
///
/// Implementations live in [features/auth/data/auth_repository_impl.dart].
/// Domain layer only depends on this abstraction.
abstract class AuthRepository {
  /// Send OTP to [phoneNumber]. Returns request ID for verification.
  Future<String> sendOtp(String phoneNumber);

  /// Verify [otp] for [requestId]. Returns [AuthToken] on success.
  Future<AuthToken> verifyOtp({
    required String requestId,
    required String otp,
    required String deviceId,
  });

  /// Refresh the access token using the stored refresh token.
  Future<AuthToken> refreshToken(String refreshToken);

  /// Log out and invalidate all sessions on the server.
  Future<void> logout();
}
