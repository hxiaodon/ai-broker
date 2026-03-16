// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appRouterHash() => r'81060165271527b25b2f2ae3e5449793eb35f2d5';

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
///
/// Copied from [appRouter].
@ProviderFor(appRouter)
final appRouterProvider = AutoDisposeProvider<GoRouter>.internal(
  appRouter,
  name: r'appRouterProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appRouterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppRouterRef = AutoDisposeProviderRef<GoRouter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
