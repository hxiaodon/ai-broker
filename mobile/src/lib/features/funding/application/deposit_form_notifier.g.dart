// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deposit_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DepositFormNotifier)
final depositFormProvider = DepositFormNotifierProvider._();

final class DepositFormNotifierProvider
    extends $NotifierProvider<DepositFormNotifier, DepositFormState> {
  DepositFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'depositFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$depositFormNotifierHash();

  @$internal
  @override
  DepositFormNotifier create() => DepositFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DepositFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DepositFormState>(value),
    );
  }
}

String _$depositFormNotifierHash() =>
    r'38b29c5af123e0825f9153eafa81cb10959fd85e';

abstract class _$DepositFormNotifier extends $Notifier<DepositFormState> {
  DepositFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DepositFormState, DepositFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DepositFormState, DepositFormState>,
              DepositFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
