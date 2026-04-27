// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdraw_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WithdrawFormNotifier)
final withdrawFormProvider = WithdrawFormNotifierProvider._();

final class WithdrawFormNotifierProvider
    extends $NotifierProvider<WithdrawFormNotifier, WithdrawFormState> {
  WithdrawFormNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawFormProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawFormNotifierHash();

  @$internal
  @override
  WithdrawFormNotifier create() => WithdrawFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawFormState>(value),
    );
  }
}

String _$withdrawFormNotifierHash() =>
    r'5436d925958c202dd3b99f145c24a8039c17d9f8';

abstract class _$WithdrawFormNotifier extends $Notifier<WithdrawFormState> {
  WithdrawFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<WithdrawFormState, WithdrawFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WithdrawFormState, WithdrawFormState>,
              WithdrawFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
