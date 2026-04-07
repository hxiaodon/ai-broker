import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/application/otp_timer_notifier.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<OtpTimerState> sub;

  setUpAll(() => AppLogger.init());

  setUp(() {
    container = ProviderContainer();
    // Keep provider alive across awaits — without a listener, the provider is
    // auto-disposed when the event loop yields, resetting all timer state.
    sub = container.listen(otpTimerProvider, (_, _) {});
  });

  tearDown(() {
    sub.close();
    container.dispose();
  });

  group('OtpTimerNotifier - Initial State', () {
    test('initial state has default values', () {
      final state = container.read(otpTimerProvider);

      expect(state.resendCountdownSeconds, 60);
      expect(state.expiryCountdownSeconds, 300);
      expect(state.errorCount, 0);
      expect(state.isLockedOut, false);
      expect(state.lockoutRemainingSeconds, 0);
      expect(state.lockoutUntil, null);
    });
  });

  group('OtpTimerNotifier - OTP Sent', () {
    test('onOtpSent starts resend countdown', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 300);

      final state = container.read(otpTimerProvider);
      expect(state.resendCountdownSeconds, 60);
      expect(state.expiryCountdownSeconds, 300);
      expect(state.errorCount, 0);
    });

    test('resend countdown decrements every second', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent(resendAfterSeconds: 3, expiresInSeconds: 300);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(container.read(otpTimerProvider).resendCountdownSeconds, 2);

      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(container.read(otpTimerProvider).resendCountdownSeconds, 1);

      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(container.read(otpTimerProvider).resendCountdownSeconds, 0);
    });

    test('expiry countdown decrements every second', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 5);

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(container.read(otpTimerProvider).expiryCountdownSeconds, 4);

      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(container.read(otpTimerProvider).expiryCountdownSeconds, 3);
    });

    test('resend countdown stops at 0', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent(resendAfterSeconds: 1, expiresInSeconds: 300);

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(container.read(otpTimerProvider).resendCountdownSeconds, 0);

      // Wait more and verify it stays at 0
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(container.read(otpTimerProvider).resendCountdownSeconds, 0);
    });

    test('expiry countdown stops at 0', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 1);

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(container.read(otpTimerProvider).expiryCountdownSeconds, 0);

      // Wait more and verify it stays at 0
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(container.read(otpTimerProvider).expiryCountdownSeconds, 0);
    });
  });

  group('OtpTimerNotifier - Error Handling', () {
    test('onOtpError increments error count', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      notifier.onOtpError(remainingAttempts: 4);
      expect(container.read(otpTimerProvider).errorCount, 1);

      notifier.onOtpError(remainingAttempts: 3);
      expect(container.read(otpTimerProvider).errorCount, 2);

      notifier.onOtpError(remainingAttempts: 2);
      expect(container.read(otpTimerProvider).errorCount, 3);
    });

    test('onOtpError triggers lockout after 5 errors', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // First 4 errors
      notifier.onOtpError(remainingAttempts: 4);
      notifier.onOtpError(remainingAttempts: 3);
      notifier.onOtpError(remainingAttempts: 2);
      notifier.onOtpError(remainingAttempts: 1);

      var state = container.read(otpTimerProvider);
      expect(state.errorCount, 4);
      expect(state.isLockedOut, false);

      // 5th error triggers lockout
      notifier.onOtpError(remainingAttempts: 0);

      state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      expect(state.lockoutRemainingSeconds, greaterThan(0));
      expect(state.lockoutUntil, isNotNull);
    });

    test('onOtpError triggers lockout when remainingAttempts is 0', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // Server says no attempts remaining
      notifier.onOtpError(remainingAttempts: 0);

      final state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      expect(state.lockoutRemainingSeconds, greaterThan(0));
    });

    test('lockout uses server-provided lockoutUntil when available', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      final serverLockoutUntil = DateTime.now().toUtc().add(const Duration(minutes: 30));
      notifier.onOtpError(remainingAttempts: 0, lockoutUntil: serverLockoutUntil);

      final state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      expect(state.lockoutUntil, serverLockoutUntil);
    });
  });

  group('OtpTimerNotifier - Lockout', () {
    test('lockout countdown decrements every second', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // Trigger lockout with short duration for testing
      final lockoutUntil = DateTime.now().toUtc().add(const Duration(seconds: 3));
      notifier.onOtpError(remainingAttempts: 0, lockoutUntil: lockoutUntil);

      var state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      final initialRemaining = state.lockoutRemainingSeconds;

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      state = container.read(otpTimerProvider);
      expect(state.lockoutRemainingSeconds, lessThan(initialRemaining));
    });

    test('lockout auto-unlocks after 30 minutes', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // Trigger lockout with very short duration for testing
      final lockoutUntil = DateTime.now().toUtc().add(const Duration(seconds: 2));
      notifier.onOtpError(remainingAttempts: 0, lockoutUntil: lockoutUntil);

      var state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);

      // Wait for lockout to expire
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      state = container.read(otpTimerProvider);
      expect(state.isLockedOut, false);
      expect(state.lockoutRemainingSeconds, 0);
      expect(state.errorCount, 0);
      expect(state.lockoutUntil, null);
    });

    test('lockout resets error count after expiry', () async {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // Build up error count
      notifier.onOtpError(remainingAttempts: 4);
      notifier.onOtpError(remainingAttempts: 3);
      notifier.onOtpError(remainingAttempts: 2);
      notifier.onOtpError(remainingAttempts: 1);

      // Trigger lockout
      final lockoutUntil = DateTime.now().toUtc().add(const Duration(seconds: 1));
      notifier.onOtpError(remainingAttempts: 0, lockoutUntil: lockoutUntil);

      expect(container.read(otpTimerProvider).errorCount, 5);

      // Wait for lockout to expire
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      final state = container.read(otpTimerProvider);
      expect(state.errorCount, 0);
      expect(state.isLockedOut, false);
    });
  });

  group('OtpTimerNotifier - Reset', () {
    test('reset clears all timers and state', () async {
      final notifier = container.read(otpTimerProvider.notifier);

      // Setup some state
      notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 300);
      notifier.onOtpError(remainingAttempts: 4);
      notifier.onOtpError(remainingAttempts: 3);

      await Future<void>.delayed(const Duration(milliseconds: 1100));

      var state = container.read(otpTimerProvider);
      expect(state.resendCountdownSeconds, lessThan(60));
      expect(state.errorCount, 2);

      // Reset
      notifier.reset();

      state = container.read(otpTimerProvider);
      expect(state.resendCountdownSeconds, 60);
      expect(state.expiryCountdownSeconds, 300);
      expect(state.errorCount, 0);
      expect(state.isLockedOut, false);
      expect(state.lockoutRemainingSeconds, 0);
      expect(state.lockoutUntil, null);
    });

    test('reset stops all running timers', () async {
      final notifier = container.read(otpTimerProvider.notifier);

      notifier.onOtpSent(resendAfterSeconds: 10, expiresInSeconds: 300);
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      // Reset
      notifier.reset();

      final stateAfterReset = container.read(otpTimerProvider);
      expect(stateAfterReset.resendCountdownSeconds, 60);

      // Wait and verify countdown doesn't continue
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final stateAfterWait = container.read(otpTimerProvider);
      expect(stateAfterWait.resendCountdownSeconds, 60); // Should not have changed
    });
  });

  group('OtpTimerNotifier - Edge Cases', () {
    test('multiple onOtpSent calls cancel previous timers', () async {
      final notifier = container.read(otpTimerProvider.notifier);

      // First OTP send
      notifier.onOtpSent(resendAfterSeconds: 5, expiresInSeconds: 300);
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      var state = container.read(otpTimerProvider);
      expect(state.resendCountdownSeconds, 4);

      // Second OTP send (e.g., user requested resend)
      notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 300);

      state = container.read(otpTimerProvider);
      expect(state.resendCountdownSeconds, 60); // Reset to new countdown
      expect(state.errorCount, 0); // Error count reset
    });

    test('lockout with past lockoutUntil results in 0 remaining seconds', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // Lockout time in the past
      final pastLockoutUntil = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      notifier.onOtpError(remainingAttempts: 0, lockoutUntil: pastLockoutUntil);

      final state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      expect(state.lockoutRemainingSeconds, 0);
    });

    test('error count does not exceed 5', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // Try to add 6 errors
      for (int i = 5; i > 0; i--) {
        notifier.onOtpError(remainingAttempts: i - 1);
      }

      final state = container.read(otpTimerProvider);
      expect(state.errorCount, lessThanOrEqualTo(5));
      expect(state.isLockedOut, true);
    });
  });

  group('OtpTimerNotifier - PRD Compliance', () {
    test('PRD §6.1: 60s resend cooldown', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      final state = container.read(otpTimerProvider);
      expect(state.resendCountdownSeconds, 60);
    });

    test('PRD §6.1: OTP valid for 5 minutes (300s)', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      final state = container.read(otpTimerProvider);
      expect(state.expiryCountdownSeconds, 300);
    });

    test('PRD §6.1: Max 5 errors trigger 30-minute lockout', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      // 5 errors
      for (int i = 5; i > 0; i--) {
        notifier.onOtpError(remainingAttempts: i - 1);
      }

      final state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);

      // Verify lockout is approximately 30 minutes (allow 1 second tolerance)
      final expectedLockoutSeconds = 30 * 60;
      expect(
        state.lockoutRemainingSeconds,
        inInclusiveRange(expectedLockoutSeconds - 2, expectedLockoutSeconds),
      );
    });
  });
}
