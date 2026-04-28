// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_info_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PersonalInfoNotifier)
final personalInfoProvider = PersonalInfoNotifierProvider._();

final class PersonalInfoNotifierProvider
    extends $NotifierProvider<PersonalInfoNotifier, PersonalInfoState> {
  PersonalInfoNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'personalInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$personalInfoNotifierHash();

  @$internal
  @override
  PersonalInfoNotifier create() => PersonalInfoNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonalInfoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonalInfoState>(value),
    );
  }
}

String _$personalInfoNotifierHash() =>
    r'c32171dcb17650d58eb84b60c70accba08883565';

abstract class _$PersonalInfoNotifier extends $Notifier<PersonalInfoState> {
  PersonalInfoState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PersonalInfoState, PersonalInfoState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PersonalInfoState, PersonalInfoState>,
              PersonalInfoState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
