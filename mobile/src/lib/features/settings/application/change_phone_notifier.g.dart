// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_phone_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State machine for the 3-step change-phone flow.
///
/// Corrected PRD §6.3 sequence:
///   1. startFlow(newPhone) → sends OTP to OLD phone (server derives from JWT)
///   2. submitOldOtp(code)  → verifies old phone, then sends OTP to newPhone
///   3. submitNewOtp(code)  → verifies new phone + finalises update

@ProviderFor(ChangePhoneNotifier)
final changePhoneProvider = ChangePhoneNotifierProvider._();

/// State machine for the 3-step change-phone flow.
///
/// Corrected PRD §6.3 sequence:
///   1. startFlow(newPhone) → sends OTP to OLD phone (server derives from JWT)
///   2. submitOldOtp(code)  → verifies old phone, then sends OTP to newPhone
///   3. submitNewOtp(code)  → verifies new phone + finalises update
final class ChangePhoneNotifierProvider
    extends $NotifierProvider<ChangePhoneNotifier, ChangePhoneState> {
  /// State machine for the 3-step change-phone flow.
  ///
  /// Corrected PRD §6.3 sequence:
  ///   1. startFlow(newPhone) → sends OTP to OLD phone (server derives from JWT)
  ///   2. submitOldOtp(code)  → verifies old phone, then sends OTP to newPhone
  ///   3. submitNewOtp(code)  → verifies new phone + finalises update
  ChangePhoneNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changePhoneProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changePhoneNotifierHash();

  @$internal
  @override
  ChangePhoneNotifier create() => ChangePhoneNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChangePhoneState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChangePhoneState>(value),
    );
  }
}

String _$changePhoneNotifierHash() =>
    r'215f8afd0d4337deff9eac22acd3a43c98c2bcfb';

/// State machine for the 3-step change-phone flow.
///
/// Corrected PRD §6.3 sequence:
///   1. startFlow(newPhone) → sends OTP to OLD phone (server derives from JWT)
///   2. submitOldOtp(code)  → verifies old phone, then sends OTP to newPhone
///   3. submitNewOtp(code)  → verifies new phone + finalises update

abstract class _$ChangePhoneNotifier extends $Notifier<ChangePhoneState> {
  ChangePhoneState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ChangePhoneState, ChangePhoneState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChangePhoneState, ChangePhoneState>,
              ChangePhoneState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
