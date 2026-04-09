// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_timer_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// OTP countdown + error count + lockout management (T10).
///
/// Rules from PRD §6.1:
///   - 60s resend cooldown
///   - OTP valid for 5 minutes (300s)
///   - Max 5 errors → 30-minute lockout
///   - 1 hour max 5 sends (enforced server-side; client shows cooldown)

@ProviderFor(OtpTimerNotifier)
final otpTimerProvider = OtpTimerNotifierProvider._();

/// OTP countdown + error count + lockout management (T10).
///
/// Rules from PRD §6.1:
///   - 60s resend cooldown
///   - OTP valid for 5 minutes (300s)
///   - Max 5 errors → 30-minute lockout
///   - 1 hour max 5 sends (enforced server-side; client shows cooldown)
final class OtpTimerNotifierProvider
    extends $NotifierProvider<OtpTimerNotifier, OtpTimerState> {
  /// OTP countdown + error count + lockout management (T10).
  ///
  /// Rules from PRD §6.1:
  ///   - 60s resend cooldown
  ///   - OTP valid for 5 minutes (300s)
  ///   - Max 5 errors → 30-minute lockout
  ///   - 1 hour max 5 sends (enforced server-side; client shows cooldown)
  OtpTimerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'otpTimerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$otpTimerNotifierHash();

  @$internal
  @override
  OtpTimerNotifier create() => OtpTimerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OtpTimerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OtpTimerState>(value),
    );
  }
}

String _$otpTimerNotifierHash() => r'754976dc078748adb45353669b9a26a6d0644ce5';

/// OTP countdown + error count + lockout management (T10).
///
/// Rules from PRD §6.1:
///   - 60s resend cooldown
///   - OTP valid for 5 minutes (300s)
///   - Max 5 errors → 30-minute lockout
///   - 1 hour max 5 sends (enforced server-side; client shows cooldown)

abstract class _$OtpTimerNotifier extends $Notifier<OtpTimerState> {
  OtpTimerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OtpTimerState, OtpTimerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OtpTimerState, OtpTimerState>,
              OtpTimerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
