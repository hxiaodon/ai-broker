// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// go_router configuration with 4-tab StatefulShellRoute.
///
/// Auth redirect logic:
///   - unauthenticated + non-auth route → splash (/)
///   - guest + restricted route (trading/portfolio/settings) → guest placeholder
///   - authenticated + auth route → market
///   - PENDING_KYC → /kyc
///
/// GoRouter is created as a [Riverpod(keepAlive: true)] provider so it can
/// listen to [authProvider] and refresh on state changes.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// go_router configuration with 4-tab StatefulShellRoute.
///
/// Auth redirect logic:
///   - unauthenticated + non-auth route → splash (/)
///   - guest + restricted route (trading/portfolio/settings) → guest placeholder
///   - authenticated + auth route → market
///   - PENDING_KYC → /kyc
///
/// GoRouter is created as a [Riverpod(keepAlive: true)] provider so it can
/// listen to [authProvider] and refresh on state changes.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// go_router configuration with 4-tab StatefulShellRoute.
  ///
  /// Auth redirect logic:
  ///   - unauthenticated + non-auth route → splash (/)
  ///   - guest + restricted route (trading/portfolio/settings) → guest placeholder
  ///   - authenticated + auth route → market
  ///   - PENDING_KYC → /kyc
  ///
  /// GoRouter is created as a [Riverpod(keepAlive: true)] provider so it can
  /// listen to [authProvider] and refresh on state changes.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'eb0bad223608f82655666839a086e363e199d04b';
