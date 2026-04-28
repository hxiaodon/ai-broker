// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_submit_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(KycSubmitNotifier)
final kycSubmitProvider = KycSubmitNotifierProvider._();

final class KycSubmitNotifierProvider
    extends $NotifierProvider<KycSubmitNotifier, KycSubmitState> {
  KycSubmitNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kycSubmitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kycSubmitNotifierHash();

  @$internal
  @override
  KycSubmitNotifier create() => KycSubmitNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KycSubmitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KycSubmitState>(value),
    );
  }
}

String _$kycSubmitNotifierHash() => r'1547838c5a1909b54d565593fae87377af665d70';

abstract class _$KycSubmitNotifier extends $Notifier<KycSubmitState> {
  KycSubmitState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<KycSubmitState, KycSubmitState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<KycSubmitState, KycSubmitState>,
              KycSubmitState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
