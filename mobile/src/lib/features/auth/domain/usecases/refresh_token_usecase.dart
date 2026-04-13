import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

/// UseCase for silently refreshing access tokens.
///
/// Business logic:
/// - Refresh token validation (not empty, valid format)
/// - Token rotation handling
/// - Proactive refresh before expiry (5-minute buffer)
/// - Cascade refresh if new token also expires soon
class RefreshTokenUseCase {
  RefreshTokenUseCase(this._repository);

  final AuthRepository _repository;

  /// Silently refresh the access token using a refresh token.
  ///
  /// Business Logic:
  /// 1. Validate refresh token is not empty
  /// 2. Call repository.refreshToken()
  /// 3. Check if new token expires within 5 minutes
  /// 4. If so, recursively refresh again (cascade refresh)
  /// 5. Return the final refreshed token
  ///
  /// Throws [ValidationException] if refresh token is invalid.
  /// Throws [AuthException] if refresh token is expired or already used.
  /// Throws [NetworkException] on network failure.
  Future<AuthToken> call({required String refreshToken}) async {
    // ─── Input Validation ───────────────────────────────────────────────
    _validateRefreshToken(refreshToken);

    AppLogger.debug('RefreshTokenUseCase: refreshing access token');

    try {
      // ─── Repository Call ────────────────────────────────────────────
      final newToken = await _repository.refreshToken(
        refreshToken: refreshToken,
      );

      AppLogger.info('Access token refreshed successfully');

      // ─── Check for Cascade Refresh ──────────────────────────────────
      // If the new token expires within 5 minutes, refresh again immediately.
      // This prevents short-lived tokens from expiring between checks.
      final timeUntilExpiry = newToken.accessTokenExpiresAt.difference(DateTime.now().toUtc());

      if (timeUntilExpiry.inMinutes < 5) {
        AppLogger.warning(
          'New token expires within 5 minutes (${timeUntilExpiry.inSeconds}s), '
          'refreshing again...',
        );

        // Recursive refresh with new refresh token
        return call(refreshToken: newToken.refreshToken);
      }

      return newToken;
    } on AuthException catch (e) {
      AppLogger.warning('Token refresh failed: ${e.message}');
      rethrow;
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('RefreshTokenUseCase failed', error: e, stackTrace: st);
      throw NetworkException(
        message: 'Failed to refresh token: $e',
        cause: e,
      );
    }
  }

  /// Validate refresh token format.
  ///
  /// Throws [ValidationException] if token is invalid.
  void _validateRefreshToken(String token) {
    if (token.isEmpty) {
      throw ValidationException(
        message: 'Refresh token cannot be empty',
        field: 'refreshToken',
      );
    }

    // Validate JWT format: header.payload.signature (3 parts separated by dots)
    final parts = token.split('.');
    if (parts.length != 3) {
      throw ValidationException(
        message: 'Invalid refresh token format: expected JWT with 3 parts, got ${parts.length}',
        field: 'refreshToken',
      );
    }

    // Check that each part is non-empty
    if (parts.any((p) => p.isEmpty)) {
      throw ValidationException(
        message: 'Invalid refresh token: empty parts',
        field: 'refreshToken',
      );
    }
  }
}
