// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tax_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TaxFormNotifier)
final taxFormProvider = TaxFormNotifierProvider._();

final class TaxFormNotifierProvider
    extends $NotifierProvider<TaxFormNotifier, TaxFormState> {
  TaxFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taxFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taxFormNotifierHash();

  @$internal
  @override
  TaxFormNotifier create() => TaxFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaxFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaxFormState>(value),
    );
  }
}

String _$taxFormNotifierHash() => r'85d8a9db14448767db499ed271014fec65fa8446';

abstract class _$TaxFormNotifier extends $Notifier<TaxFormState> {
  TaxFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TaxFormState, TaxFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TaxFormState, TaxFormState>,
              TaxFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
