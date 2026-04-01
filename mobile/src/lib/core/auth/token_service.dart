import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/secure_storage_service.dart';
import '../logging/app_logger.dart';

part 'token_service.g.dart';

/// Storage keys for JWT tokens in secure storage.
class _Keys {
  static const accessToken = 'auth.access_token';
  static const refreshToken = 'auth.refresh_token';
  static const accessTokenExpiresAt = 'auth.access_token_expires_at';
}

/// Manages JWT access and refresh token lifecycle.
///
/// Tokens are persisted in [SecureStorageService] (Keychain / EncryptedSharedPrefs).
/// Access tokens expire after 15 minutes per security policy.
class TokenService {
  const TokenService(this._storage);

  final SecureStorageService _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
  }) async {
    await Future.wait([
      _storage.write(_Keys.accessToken, accessToken),
      _storage.write(_Keys.refreshToken, refreshToken),
      _storage.write(
        _Keys.accessTokenExpiresAt,
        accessTokenExpiresAt.toUtc().toIso8601String(),
      ),
    ]);
    AppLogger.debug('Tokens saved (expires: ${accessTokenExpiresAt.toUtc()})');
  }

  Future<String?> getAccessToken() => _storage.read(_Keys.accessToken);

  Future<String?> getRefreshToken() => _storage.read(_Keys.refreshToken);

  Future<DateTime?> getAccessTokenExpiry() async {
    final raw = await _storage.read(_Keys.accessTokenExpiresAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<bool> isAccessTokenValid() async {
    final expiry = await getAccessTokenExpiry();
    if (expiry == null) return false;
    // Add 30-second buffer to account for clock skew
    return DateTime.now().toUtc().isBefore(
          expiry.subtract(const Duration(seconds: 30)),
        );
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(_Keys.accessToken),
      _storage.delete(_Keys.refreshToken),
      _storage.delete(_Keys.accessTokenExpiresAt),
    ]);
    AppLogger.info('Tokens cleared');
  }
}

@Riverpod(keepAlive: true)
TokenService tokenService(Ref ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return TokenService(storage);
}
