import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/jwt_decoder.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/logging/app_logger.dart';
import '../data/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/entities/auth_token.dart';

part 'auth_notifier.freezed.dart';
part 'auth_notifier.g.dart';

// ─────────────────────────────────────────────
// Auth State
// ─────────────────────────────────────────────

/// The four states from PRD §五 state machine.
@freezed
sealed class AuthState with _$AuthState {
  /// No session — show splash / login
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// In-flight — OTP sending / verifying / biometric check
  const factory AuthState.authenticating() = _Authenticating;

  /// Fully authenticated with valid tokens
  const factory AuthState.authenticated({
    required String accountId,
    required String accountStatus,
    required bool biometricEnabled,
  }) = _Authenticated;

  /// Browsing without account — delayed quotes, no order/portfolio
  const factory AuthState.guest() = _Guest;
}

// ─────────────────────────────────────────────
// Auth Notifier (T09)
// ─────────────────────────────────────────────

/// Core authentication state machine.
///
/// States: unauthenticated ↔ authenticating ↔ authenticated / guest
/// On cold start, [build] schedules async session restore from [TokenService].
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Schedule async session restore after first synchronous build.
    Future.microtask(_restoreSession);
    return const AuthState.unauthenticated();
  }

  // ─── Cold Start Session Restore ─────────────────────────────────────────

  Future<void> _restoreSession() async {
    final tokenService = ref.read(tokenServiceProvider);
    try {
      final accessToken = await tokenService.getAccessToken();
      final refreshToken = await tokenService.getRefreshToken();

      if (accessToken == null || refreshToken == null) return;

      final isValid = await tokenService.isAccessTokenValid();
      if (isValid) {
        final accountId = JwtDecoder.extractAccountId(accessToken) ?? 'unknown';
        final biometricEnabled = await _isBiometricRegistered();
        state = AuthState.authenticated(
          accountId: accountId,
          accountStatus: 'ACTIVE',
          biometricEnabled: biometricEnabled,
        );
        AppLogger.info('Session restored from storage');
        return;
      }

      // Access token expired — try silent refresh
      await _silentRefresh(refreshToken);
    } on Object catch (e, st) {
      AppLogger.warning('Session restore failed', error: e, stackTrace: st);
    }
  }

  // ─── Silent Token Refresh ─────────────────────────────────────────────────

  Future<void> _silentRefresh(String refreshToken) async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final token = await repo.refreshToken(refreshToken: refreshToken);
      final biometricEnabled = await _isBiometricRegistered();
      state = AuthState.authenticated(
        accountId: token.accountId,
        accountStatus: token.accountStatus,
        biometricEnabled: biometricEnabled,
      );
      AppLogger.info('Silent token refresh succeeded');
    } on Object catch (e, st) {
      AppLogger.warning(
        'Silent refresh failed — clearing session',
        error: e,
        stackTrace: st,
      );
      await ref.read(tokenServiceProvider).clearTokens();
      state = const AuthState.unauthenticated();
    }
  }

  // ─── Post-OTP Login ──────────────────────────────────────────────────────

  /// Called by [OtpInputScreen] after successful OTP verify for an existing user.
  Future<void> loginWithToken({required AuthToken token}) async {
    final biometricEnabled = await _isBiometricRegistered();
    state = AuthState.authenticated(
      accountId: token.accountId,
      accountStatus: token.accountStatus,
      biometricEnabled: biometricEnabled,
    );
    AppLogger.info('Login complete for account: ${token.accountId}');
  }

  // ─── Biometric Login ─────────────────────────────────────────────────────

  /// Attempt biometric login via silent token refresh.
  ///
  /// Returns true on success. Caller counts failures (max 3 from PRD §6.2).
  Future<bool> loginWithBiometric() async {
    state = const AuthState.authenticating();
    final tokenService = ref.read(tokenServiceProvider);
    final refreshToken = await tokenService.getRefreshToken();

    if (refreshToken == null) {
      state = const AuthState.unauthenticated();
      return false;
    }

    try {
      await _silentRefresh(refreshToken);
      return state is _Authenticated;
    } on Object catch (e, st) {
      AppLogger.warning('Biometric login failed', error: e, stackTrace: st);
      state = const AuthState.unauthenticated();
      return false;
    }
  }

  // ─── Guest Mode ──────────────────────────────────────────────────────────

  void enterGuestMode() {
    state = const AuthState.guest();
    AppLogger.info('Entered guest mode');
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.logout();
    } on Object catch (e, st) {
      AppLogger.warning(
        'Server logout failed — clearing local state anyway',
        error: e,
        stackTrace: st,
      );
    }
    state = const AuthState.unauthenticated();
  }

  // ─── Remote Kick / Session Expired ──────────────────────────────────────

  Future<void> handleRemoteKick() async {
    await ref.read(tokenServiceProvider).clearTokens();
    state = const AuthState.unauthenticated();
    AppLogger.security('Session invalidated by remote kick / device revocation');
  }

  // ─── Proactive Refresh ──────────────────────────────────────────────────

  /// Called from app lifecycle checks. Silently refreshes if token < 15 min.
  Future<void> checkAndRefreshIfNeeded() async {
    if (state is! _Authenticated) return;
    final tokenService = ref.read(tokenServiceProvider);
    final isValid = await tokenService.isAccessTokenValid();
    if (!isValid) {
      final rt = await tokenService.getRefreshToken();
      if (rt != null) await _silentRefresh(rt);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<bool> _isBiometricRegistered() async {
    final repo = ref.read(authRepositoryProvider);
    return repo.isBiometricRegistered();
  }
}
