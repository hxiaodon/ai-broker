import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/application/otp_timer_notifier.dart';

// ─── Test helpers ─────────────────────────────────────────────────────────────

/// Runs [body] inside fakeAsync so Timer.periodic fires synchronously when
/// [async.elapse()] is called, and clock.now() returns the fake timestamp.
void fa(void Function(FakeAsync async) body) => fakeAsync(body);

/// Creates a ProviderContainer with a listener to keep the provider alive.
ProviderContainer _makeContainer() {
  final container = ProviderContainer();
  container.listen(otpTimerProvider, (_, _) {});
  return container;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late ProviderContainer container;

  setUpAll(() => AppLogger.init());

  setUp(() => container = _makeContainer());
  tearDown(() => container.dispose());

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
    test('onOtpSent starts resend countdown', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 300);

        final state = container.read(otpTimerProvider);
        expect(state.resendCountdownSeconds, 60);
        expect(state.expiryCountdownSeconds, 300);
        expect(state.errorCount, 0);
      });
    });

    test('resend countdown decrements every second', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent(resendAfterSeconds: 3, expiresInSeconds: 300);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).resendCountdownSeconds, 2);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).resendCountdownSeconds, 1);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).resendCountdownSeconds, 0);
      });
    });

    test('expiry countdown decrements every second', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 5);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).expiryCountdownSeconds, 4);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).expiryCountdownSeconds, 3);
      });
    });

    test('resend countdown stops at 0', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent(resendAfterSeconds: 1, expiresInSeconds: 300);

        async.elapse(const Duration(seconds: 2));
        expect(container.read(otpTimerProvider).resendCountdownSeconds, 0);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).resendCountdownSeconds, 0);
      });
    });

    test('expiry countdown stops at 0', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 1);

        async.elapse(const Duration(seconds: 2));
        expect(container.read(otpTimerProvider).expiryCountdownSeconds, 0);

        async.elapse(const Duration(seconds: 1));
        expect(container.read(otpTimerProvider).expiryCountdownSeconds, 0);
      });
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

      notifier.onOtpError(remainingAttempts: 4);
      notifier.onOtpError(remainingAttempts: 3);
      notifier.onOtpError(remainingAttempts: 2);
      notifier.onOtpError(remainingAttempts: 1);

      var state = container.read(otpTimerProvider);
      expect(state.errorCount, 4);
      expect(state.isLockedOut, false);

      notifier.onOtpError(remainingAttempts: 0);

      state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      expect(state.lockoutRemainingSeconds, greaterThan(0));
      expect(state.lockoutUntil, isNotNull);
    });

    test('onOtpError triggers lockout when remainingAttempts is 0', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

      notifier.onOtpError(remainingAttempts: 0);

      final state = container.read(otpTimerProvider);
      expect(state.isLockedOut, true);
      expect(state.lockoutRemainingSeconds, greaterThan(0));
    });

    test('lockout uses server-provided lockoutUntil when available', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent();

        final serverLockoutUntil =
            clock.now().toUtc().add(const Duration(minutes: 30));
        notifier.onOtpError(
            remainingAttempts: 0, lockoutUntil: serverLockoutUntil);

        final state = container.read(otpTimerProvider);
        expect(state.isLockedOut, true);
        expect(state.lockoutUntil, serverLockoutUntil);
      });
    });
  });

  group('OtpTimerNotifier - Lockout', () {
    test('lockout countdown decrements every second', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent();

        final lockoutUntil =
            clock.now().toUtc().add(const Duration(seconds: 5));
        notifier.onOtpError(remainingAttempts: 0, lockoutUntil: lockoutUntil);

        final initialRemaining =
            container.read(otpTimerProvider).lockoutRemainingSeconds;

        async.elapse(const Duration(seconds: 1));
        expect(
          container.read(otpTimerProvider).lockoutRemainingSeconds,
          lessThan(initialRemaining),
        );
      });
    });

    test('lockout auto-unlocks after countdown expires', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent();

        final lockoutUntil =
            clock.now().toUtc().add(const Duration(seconds: 2));
        notifier.onOtpError(remainingAttempts: 0, lockoutUntil: lockoutUntil);

        expect(container.read(otpTimerProvider).isLockedOut, true);

        async.elapse(const Duration(seconds: 3));

        final state = container.read(otpTimerProvider);
        expect(state.isLockedOut, false);
        expect(state.lockoutRemainingSeconds, 0);
        expect(state.errorCount, 0);
        expect(state.lockoutUntil, null);
      });
    });

    test('lockout resets error count after expiry', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent();

        notifier.onOtpError(remainingAttempts: 4);
        notifier.onOtpError(remainingAttempts: 3);
        notifier.onOtpError(remainingAttempts: 2);
        notifier.onOtpError(remainingAttempts: 1);

        final lockoutUntil =
            clock.now().toUtc().add(const Duration(seconds: 2));
        notifier.onOtpError(remainingAttempts: 0, lockoutUntil: lockoutUntil);

        expect(container.read(otpTimerProvider).errorCount, 5);

        async.elapse(const Duration(seconds: 3));

        final state = container.read(otpTimerProvider);
        expect(state.errorCount, 0);
        expect(state.isLockedOut, false);
      });
    });
  });

  group('OtpTimerNotifier - Reset', () {
    test('reset clears all timers and state', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);

        notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 300);
        notifier.onOtpError(remainingAttempts: 4);
        notifier.onOtpError(remainingAttempts: 3);

        async.elapse(const Duration(seconds: 1));

        var state = container.read(otpTimerProvider);
        expect(state.resendCountdownSeconds, lessThan(60));
        expect(state.errorCount, 2);

        notifier.reset();

        state = container.read(otpTimerProvider);
        expect(state.resendCountdownSeconds, 60);
        expect(state.expiryCountdownSeconds, 300);
        expect(state.errorCount, 0);
        expect(state.isLockedOut, false);
        expect(state.lockoutRemainingSeconds, 0);
        expect(state.lockoutUntil, null);
      });
    });

    test('reset stops all running timers', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);

        notifier.onOtpSent(resendAfterSeconds: 10, expiresInSeconds: 300);
        async.elapse(const Duration(seconds: 1));

        notifier.reset();

        final stateAfterReset = container.read(otpTimerProvider);
        expect(stateAfterReset.resendCountdownSeconds, 60);

        // Timer stopped — further elapsed time must not change countdown
        async.elapse(const Duration(seconds: 2));
        expect(
          container.read(otpTimerProvider).resendCountdownSeconds,
          60,
        );
      });
    });
  });

  group('OtpTimerNotifier - Edge Cases', () {
    test('multiple onOtpSent calls cancel previous timers', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);

        notifier.onOtpSent(resendAfterSeconds: 5, expiresInSeconds: 300);
        async.elapse(const Duration(seconds: 1));

        expect(container.read(otpTimerProvider).resendCountdownSeconds, 4);

        notifier.onOtpSent(resendAfterSeconds: 60, expiresInSeconds: 300);

        final state = container.read(otpTimerProvider);
        expect(state.resendCountdownSeconds, 60);
        expect(state.errorCount, 0);
      });
    });

    test('lockout with past lockoutUntil results in 0 remaining seconds', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent();

        final pastLockoutUntil =
            clock.now().toUtc().subtract(const Duration(minutes: 1));
        notifier.onOtpError(
            remainingAttempts: 0, lockoutUntil: pastLockoutUntil);

        final state = container.read(otpTimerProvider);
        expect(state.isLockedOut, true);
        expect(state.lockoutRemainingSeconds, 0);
      });
    });

    test('error count does not exceed 5', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();

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
      expect(container.read(otpTimerProvider).resendCountdownSeconds, 60);
    });

    test('PRD §6.1: OTP valid for 5 minutes (300s)', () {
      final notifier = container.read(otpTimerProvider.notifier);
      notifier.onOtpSent();
      expect(container.read(otpTimerProvider).expiryCountdownSeconds, 300);
    });

    test('PRD §6.1: Max 5 errors trigger 30-minute lockout', () {
      fa((async) {
        final notifier = container.read(otpTimerProvider.notifier);
        notifier.onOtpSent();

        for (int i = 5; i > 0; i--) {
          notifier.onOtpError(remainingAttempts: i - 1);
        }

        final state = container.read(otpTimerProvider);
        expect(state.isLockedOut, true);

        // Lockout should be ~30 minutes (1800 seconds)
        const expectedLockoutSeconds = 30 * 60;
        expect(
          state.lockoutRemainingSeconds,
          inInclusiveRange(expectedLockoutSeconds - 2, expectedLockoutSeconds),
        );
      });
    });
  });
}
