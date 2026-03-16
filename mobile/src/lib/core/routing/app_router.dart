import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'route_names.dart';
import 'scaffold_with_nav.dart';

part 'app_router.g.dart';

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
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: RouteNames.market,
    debugLogDiagnostics: true,
    // Phase 1: no redirect — always navigate directly to tab shell.
    // Phase 2: wire AuthNotifier here for auth/KYC guards.
    redirect: null,
    routes: [
      // Auth routes
      GoRoute(
        path: RouteNames.authLogin,
        builder: (_, __) => const _Placeholder('Login'),
      ),
      GoRoute(
        path: RouteNames.authOtp,
        builder: (_, __) => const _Placeholder('OTP Verification'),
      ),
      GoRoute(
        path: RouteNames.authBiometricSetup,
        builder: (_, __) => const _Placeholder('Biometric Setup'),
      ),

      // KYC routes (modal flow)
      GoRoute(
        path: RouteNames.kycRoot,
        builder: (_, __) => const _Placeholder('KYC — Personal Info'),
      ),

      // Main tab shell
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainTabScaffold(navigationShell: shell),
        branches: [
          // Market tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.market,
                builder: (_, __) => const _Placeholder('Market'),
                routes: [
                  GoRoute(
                    path: 'stock/:symbol',
                    builder: (_, state) => _Placeholder(
                      'Stock Detail — ${state.pathParameters['symbol']}',
                    ),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (_, __) => const _Placeholder('Search'),
                  ),
                ],
              ),
            ],
          ),

          // Trading tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.trading,
                builder: (_, __) => const _Placeholder('Trading'),
                routes: [
                  GoRoute(
                    path: 'order',
                    builder: (_, __) => const _Placeholder('Order Entry'),
                  ),
                ],
              ),
            ],
          ),

          // Portfolio tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.portfolio,
                builder: (_, __) => const _Placeholder('Portfolio'),
              ),
            ],
          ),

          // Settings tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                builder: (_, __) => const _Placeholder('Settings'),
                routes: [
                  GoRoute(
                    path: 'security',
                    builder: (_, __) => const _Placeholder('Security Settings'),
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const _Placeholder('Profile'),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (_, __) => const _Placeholder('Help Center'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => _ErrorPage(state.error),
  );
}

// ---------------------------------------------------------------------------
// Internal placeholder widget (used only during scaffolding phase)
// ---------------------------------------------------------------------------

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage(this.error);
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Page not found\n${error?.toString() ?? ''}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
