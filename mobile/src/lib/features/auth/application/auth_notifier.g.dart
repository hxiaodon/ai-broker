// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Core authentication state machine.
///
/// States: unauthenticated ↔ authenticating ↔ authenticated / guest
/// On cold start, [build] schedules async session restore from [TokenService].

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// Core authentication state machine.
///
/// States: unauthenticated ↔ authenticating ↔ authenticated / guest
/// On cold start, [build] schedules async session restore from [TokenService].
final class AuthNotifierProvider
    extends $NotifierProvider<AuthNotifier, AuthState> {
  /// Core authentication state machine.
  ///
  /// States: unauthenticated ↔ authenticating ↔ authenticated / guest
  /// On cold start, [build] schedules async session restore from [TokenService].
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthState>(value),
    );
  }
}

String _$authNotifierHash() => r'd84716689be77b9f01031d05e8a7c4598ed1c617';

/// Core authentication state machine.
///
/// States: unauthenticated ↔ authenticating ↔ authenticated / guest
/// On cold start, [build] schedules async session restore from [TokenService].

abstract class _$AuthNotifier extends $Notifier<AuthState> {
  AuthState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthState, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthState, AuthState>,
              AuthState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
