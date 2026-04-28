// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FinancialProfileNotifier)
final financialProfileProvider = FinancialProfileNotifierProvider._();

final class FinancialProfileNotifierProvider
    extends $NotifierProvider<FinancialProfileNotifier, FinancialProfileState> {
  FinancialProfileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'financialProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$financialProfileNotifierHash();

  @$internal
  @override
  FinancialProfileNotifier create() => FinancialProfileNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinancialProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinancialProfileState>(value),
    );
  }
}

String _$financialProfileNotifierHash() =>
    r'978db764270ff4826a9c860874ddedf6e034de87';

abstract class _$FinancialProfileNotifier
    extends $Notifier<FinancialProfileState> {
  FinancialProfileState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FinancialProfileState, FinancialProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FinancialProfileState, FinancialProfileState>,
              FinancialProfileState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
