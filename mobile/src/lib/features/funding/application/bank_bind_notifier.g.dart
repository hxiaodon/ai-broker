// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_bind_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BankBindNotifier)
final bankBindProvider = BankBindNotifierProvider._();

final class BankBindNotifierProvider
    extends $NotifierProvider<BankBindNotifier, BankBindState> {
  BankBindNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bankBindProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bankBindNotifierHash();

  @$internal
  @override
  BankBindNotifier create() => BankBindNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BankBindState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BankBindState>(value),
    );
  }
}

String _$bankBindNotifierHash() => r'f1b8c41498f66f33e7adfb7b0beb54c9cdab205e';

abstract class _$BankBindNotifier extends $Notifier<BankBindState> {
  BankBindState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BankBindState, BankBindState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BankBindState, BankBindState>,
              BankBindState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
