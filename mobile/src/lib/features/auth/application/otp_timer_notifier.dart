import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/logging/app_logger.dart';

part 'otp_timer_notifier.freezed.dart';
part 'otp_timer_notifier.g.dart';

/// OTP timer state (T10)
@freezed
abstract class OtpTimerState with _$OtpTimerState {
  const factory OtpTimerState({
    /// Countdown seconds before resend is allowed (0 = resend available)
    @Default(60) int resendCountdownSeconds,
    /// OTP validity countdown (300 = 5 minutes)
    @Default(300) int expiryCountdownSeconds,
    /// Number of incorrect OTP attempts on current request
    @Default(0) int errorCount,
    /// True when account is locked out (errorCount >= 5)
    @Default(false) bool isLockedOut,
    /// Remaining lockout seconds (PRD: 30 min)
    @Default(0) int lockoutRemainingSeconds,
    /// Timestamp of lockout start (used to compute remaining)
    DateTime? lockoutUntil,
  }) = _OtpTimerState;
}

/// OTP countdown + error count + lockout management (T10).
///
/// Rules from PRD §6.1:
///   - 60s resend cooldown
///   - OTP valid for 5 minutes (300s)
///   - Max 5 errors → 30-minute lockout
///   - 1 hour max 5 sends (enforced server-side; client shows cooldown)
@riverpod
class OtpTimerNotifier extends _$OtpTimerNotifier {
  Timer? _resendTimer;
  Timer? _expiryTimer;
  Timer? _lockoutTimer;

  @override
  OtpTimerState build() {
    ref.onDispose(_cancelAll);
    return const OtpTimerState();
  }

  // ─── OTP Sent ────────────────────────────────────────────────────────────

  /// Call when OTP is successfully sent. Starts resend + expiry countdowns.
  void onOtpSent({int resendAfterSeconds = 60, int expiresInSeconds = 300}) {
    _cancelAll();
    state = OtpTimerState(
      resendCountdownSeconds: resendAfterSeconds,
      expiryCountdownSeconds: expiresInSeconds,
    );
    _startResendTimer();
    _startExpiryTimer();
    AppLogger.debug(
      'OTP timers started (resend: ${resendAfterSeconds}s, expiry: ${expiresInSeconds}s)',
    );
  }

  // ─── Error Handling ──────────────────────────────────────────────────────

  /// Call when OTP verification returns INVALID_OTP_CODE.
  ///
  /// [remainingAttempts] from AMS response. If 0 → trigger lockout.
  void onOtpError({
    required int remainingAttempts,
    DateTime? lockoutUntil,
  }) {
    final newErrorCount = state.errorCount + 1;

    if (remainingAttempts <= 0 || newErrorCount >= 5) {
      _startLockout(lockoutUntil: lockoutUntil);
      return;
    }

    state = state.copyWith(errorCount: newErrorCount);
    AppLogger.debug('OTP error $newErrorCount/5 — remaining: $remainingAttempts');
  }

  // ─── Lockout ─────────────────────────────────────────────────────────────

  void _startLockout({DateTime? lockoutUntil}) {
    _lockoutTimer?.cancel();
    final until = lockoutUntil ??
        DateTime.now().toUtc().add(const Duration(minutes: 30));
    final remaining = until.difference(DateTime.now().toUtc()).inSeconds;

    state = state.copyWith(
      isLockedOut: true,
      lockoutUntil: until,
      lockoutRemainingSeconds: remaining > 0 ? remaining : 0,
    );

    AppLogger.warning('Account locked out until $until');

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final rem = state.lockoutUntil!
          .difference(DateTime.now().toUtc())
          .inSeconds;
      if (rem <= 0) {
        t.cancel();
        state = state.copyWith(
          isLockedOut: false,
          lockoutRemainingSeconds: 0,
          errorCount: 0,
          lockoutUntil: null,
        );
        AppLogger.info('Lockout expired — user can retry');
      } else {
        state = state.copyWith(lockoutRemainingSeconds: rem);
      }
    });
  }

  // ─── Timers ──────────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = state.resendCountdownSeconds - 1;
      if (remaining <= 0) {
        t.cancel();
        state = state.copyWith(resendCountdownSeconds: 0);
      } else {
        state = state.copyWith(resendCountdownSeconds: remaining);
      }
    });
  }

  void _startExpiryTimer() {
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final remaining = state.expiryCountdownSeconds - 1;
      if (remaining <= 0) {
        t.cancel();
        state = state.copyWith(expiryCountdownSeconds: 0);
        AppLogger.debug('OTP expired');
      } else {
        state = state.copyWith(expiryCountdownSeconds: remaining);
      }
    });
  }

  void _cancelAll() {
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    _lockoutTimer?.cancel();
  }

  // ─── Reset ───────────────────────────────────────────────────────────────

  /// Reset all timers when user returns to phone input page.
  void reset() {
    _cancelAll();
    state = const OtpTimerState();
  }
}
