// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_proof_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AddressProofNotifier)
final addressProofProvider = AddressProofNotifierProvider._();

final class AddressProofNotifierProvider
    extends $NotifierProvider<AddressProofNotifier, AddressProofState> {
  AddressProofNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addressProofProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addressProofNotifierHash();

  @$internal
  @override
  AddressProofNotifier create() => AddressProofNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddressProofState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddressProofState>(value),
    );
  }
}

String _$addressProofNotifierHash() =>
    r'06b558aafe73297eb1b9eeda0f0c82c65bd4fa7b';

abstract class _$AddressProofNotifier extends $Notifier<AddressProofState> {
  AddressProofState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddressProofState, AddressProofState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddressProofState, AddressProofState>,
              AddressProofState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
