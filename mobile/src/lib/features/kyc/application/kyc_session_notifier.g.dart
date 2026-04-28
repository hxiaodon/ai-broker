// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_session_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KycSessionNotifier)
final kycSessionProvider = KycSessionNotifierProvider._();

final class KycSessionNotifierProvider
    extends $NotifierProvider<KycSessionNotifier, KycSessionState> {
  KycSessionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kycSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kycSessionNotifierHash();

  @$internal
  @override
  KycSessionNotifier create() => KycSessionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KycSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KycSessionState>(value),
    );
  }
}

String _$kycSessionNotifierHash() =>
    r'6abddd24f3e873f961bb181760f812b629a31178';

abstract class _$KycSessionNotifier extends $Notifier<KycSessionState> {
  KycSessionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<KycSessionState, KycSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KycSessionState, KycSessionState>,
              KycSessionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
