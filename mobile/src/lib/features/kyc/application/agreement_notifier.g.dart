// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agreement_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgreementNotifier)
final agreementProvider = AgreementNotifierProvider._();

final class AgreementNotifierProvider
    extends $NotifierProvider<AgreementNotifier, AgreementState> {
  AgreementNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agreementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agreementNotifierHash();

  @$internal
  @override
  AgreementNotifier create() => AgreementNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgreementState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgreementState>(value),
    );
  }
}

String _$agreementNotifierHash() => r'10dd2c138c7bca50367dc3a92063eccaeed205d9';

abstract class _$AgreementNotifier extends $Notifier<AgreementState> {
  AgreementState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AgreementState, AgreementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AgreementState, AgreementState>,
              AgreementState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
