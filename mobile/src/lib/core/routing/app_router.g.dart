// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// go_router configuration with 4-tab StatefulShellRoute.
///
/// Authentication redirect logic uses placeholder booleans in Phase 1.
/// Wire to [AuthNotifier] in Phase 2 when the auth feature is implemented.
///
/// Route hierarchy:
///   /auth/login        → LoginScreen (placeholder)
///   /auth/otp          → OtpScreen (placeholder)
///   /kyc               → KycRootScreen (placeholder)
///   / (shell)
///     /market          → MarketListScreen (placeholder)
///     /trading         → TradingScreen (placeholder)
///     /portfolio       → PortfolioScreen (placeholder)
///     /settings        → SettingsScreen (placeholder)

@ProviderFor(appRouter)
const appRouterProvider = AppRouterProvider._();

/// go_router configuration with 4-tab StatefulShellRoute.
///
/// Authentication redirect logic uses placeholder booleans in Phase 1.
/// Wire to [AuthNotifier] in Phase 2 when the auth feature is implemented.
///
/// Route hierarchy:
///   /auth/login        → LoginScreen (placeholder)
///   /auth/otp          → OtpScreen (placeholder)
///   /kyc               → KycRootScreen (placeholder)
///   / (shell)
///     /market          → MarketListScreen (placeholder)
///     /trading         → TradingScreen (placeholder)
///     /portfolio       → PortfolioScreen (placeholder)
///     /settings        → SettingsScreen (placeholder)

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// go_router configuration with 4-tab StatefulShellRoute.
  ///
  /// Authentication redirect logic uses placeholder booleans in Phase 1.
  /// Wire to [AuthNotifier] in Phase 2 when the auth feature is implemented.
  ///
  /// Route hierarchy:
  ///   /auth/login        → LoginScreen (placeholder)
  ///   /auth/otp          → OtpScreen (placeholder)
  ///   /kyc               → KycRootScreen (placeholder)
  ///   / (shell)
  ///     /market          → MarketListScreen (placeholder)
  ///     /trading         → TradingScreen (placeholder)
  ///     /portfolio       → PortfolioScreen (placeholder)
  ///     /settings        → SettingsScreen (placeholder)
  const AppRouterProvider._()
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

String _$appRouterHash() => r'b7aa46accc0276219fb274dd1bc3253268ea850d';
