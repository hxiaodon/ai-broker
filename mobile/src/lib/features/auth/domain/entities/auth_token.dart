import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_token.freezed.dart';

/// JWT access + refresh token pair issued by AMS on successful OTP verification.
///
/// access_token: RS256 JWT, 15 minute expiry.
/// refresh_token: opaque token, 7 day expiry, single-use rotated.
@freezed
abstract class AuthToken with _$AuthToken {
  const factory AuthToken({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
    required String accountId,
    required String accountStatus,
  }) = _AuthToken;

  const AuthToken._();

  bool get isExpired => DateTime.now().toUtc().isAfter(accessTokenExpiresAt);

  bool get isNearExpiry {
    final now = DateTime.now().toUtc();
    final buffer = accessTokenExpiresAt.subtract(const Duration(minutes: 15));
    return now.isAfter(buffer);
  }
}
