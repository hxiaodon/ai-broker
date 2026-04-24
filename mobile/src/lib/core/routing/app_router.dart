import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/presentation/screens/biometric_login_screen.dart';
import '../../features/auth/presentation/screens/biometric_setup_screen.dart';
import '../../features/auth/presentation/screens/device_management_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_input_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/market/presentation/screens/market_home_screen.dart';
import '../../features/market/presentation/screens/search_screen.dart';
import '../../features/market/presentation/screens/stock_detail_screen.dart';
import '../../features/trading/domain/entities/order.dart';
import '../../features/trading/presentation/screens/order_confirm_screen.dart';
import '../../features/trading/presentation/screens/order_entry_screen.dart';
import '../../features/trading/presentation/screens/order_list_screen.dart';
import '../../features/portfolio/presentation/screens/portfolio_screen.dart';
import '../../features/portfolio/presentation/screens/position_detail_screen.dart';
import 'route_names.dart';
import 'scaffold_with_nav.dart';

part 'app_router.g.dart';

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
@riverpod
GoRouter appRouter(Ref ref) {
  // Trigger router refresh whenever auth state changes
  final authListenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: RouteNames.authSplash,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      return appRouterRedirect(authState, state);
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.authSplash,
        builder: (_, _) => const SplashScreen(),
      ),

      // ── Auth flow ─────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.authLogin,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.authOtp,
        builder: (_, state) {
          final args = state.extra as OtpScreenArgs;
          return OtpInputScreen(args: args);
        },
      ),
      GoRoute(
        path: RouteNames.authBiometricSetup,
        builder: (_, _) => const BiometricSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.authBiometricLogin,
        builder: (_, _) => const BiometricLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.authDevices,
        builder: (_, _) => const DeviceManagementScreen(),
      ),

      // ── KYC modal flow ────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.kycRoot,
        builder: (_, _) => const _Placeholder('KYC — Personal Info'),
      ),

      // ── Main tab shell ────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainTabScaffold(navigationShell: shell),
        branches: [
          // Market tab — available to both guests and authenticated users
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.market,
                builder: (_, _) => const MarketHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'stock/:symbol',
                    builder: (_, state) => StockDetailScreen(
                      symbol: state.pathParameters['symbol']!,
                    ),
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (_, _) => const SearchScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Trading tab — guests see placeholder
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.trading,
                builder: (_, _) => const OrderListScreen(),
                routes: [
                  GoRoute(
                    path: 'order',
                    builder: (_, state) {
                      final extra =
                          state.extra as Map<String, dynamic>? ?? {};
                      return OrderEntryScreen(
                        symbol: extra['symbol'] as String? ?? '',
                        market: extra['market'] as String? ?? 'US',
                        initialSide: extra['side'] as OrderSide? ??
                            OrderSide.buy,
                        prefillQty: extra['prefillQty'] as int?,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'confirm',
                        builder: (_, state) {
                          final extra =
                              state.extra as Map<String, dynamic>;
                          return OrderConfirmScreen(
                            symbol: extra['symbol'] as String,
                            market: extra['market'] as String,
                            side: extra['side'] as OrderSide,
                            orderType: extra['orderType'] as OrderType,
                            qty: extra['qty'] as int,
                            limitPrice: extra['limitPrice'] as Decimal?,
                            validity: extra['validity'] as OrderValidity,
                            extendedHours:
                                extra['extendedHours'] as bool,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (_, _) => const OrderListScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Portfolio tab — guests see placeholder
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.portfolio,
                builder: (_, _) => const PortfolioScreen(),
                routes: [
                  GoRoute(
                    path: 'position/:symbol',
                    builder: (_, state) => PositionDetailScreen(
                      symbol: state.pathParameters['symbol']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Settings tab — guests see placeholder
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.settings,
                builder: (_, _) => const _Placeholder('Settings'),
                routes: [
                  GoRoute(
                    path: 'security',
                    builder: (_, _) => const _Placeholder('Security Settings'),
                  ),
                  GoRoute(
                    path: 'profile',
                    builder: (_, _) => const _Placeholder('Profile'),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (_, _) => const _Placeholder('Help Center'),
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

/// Redirect logic (pure function, extracted for testability).
///
/// Returns redirect path or null.
@visibleForTesting
String? appRouterRedirect(AuthState authState, GoRouterState state) {
  final path = state.matchedLocation;
  final isAuthPath = path.startsWith('/auth');
  final isSplash = path == '/';
  final isKycPath = path.startsWith('/kyc');

  return authState.when(
    unauthenticated: () {
      // Allow auth routes and splash
      if (isAuthPath || isSplash) return null;
      // Redirect everything else to splash for login
      return RouteNames.authSplash;
    },
    authenticating: () => null, // Let splash handle the loading UI
    authenticated: (accountId, accountStatus, biometricEnabled) {
      // Push KYC-pending users to KYC flow
      if (accountStatus == 'PENDING_KYC' && !isKycPath && !isAuthPath) {
        return RouteNames.kycRoot;
      }
      // Prevent re-entering auth screens once logged in
      if (isAuthPath || isSplash) return RouteNames.market;
      return null;
    },
    guest: () {
      // Guests may use splash and auth routes
      if (isAuthPath || isSplash) return null;
      // Order entry requires authentication — redirect guests to login for deep links
      if (path.startsWith('/trading/order')) return RouteNames.authLogin;
      // Guests may browse market; restricted tabs show GuestPlaceholderScreen inline
      return null;
    },
  );
}

// ---------------------------------------------------------------------------
// Refresh listenable — bridges Riverpod → GoRouter
// ---------------------------------------------------------------------------

/// Notifies [GoRouter] when [AuthNotifier] state changes.
///
/// GoRouter's [refreshListenable] calls [GoRouter.refresh()] when this
/// ChangeNotifier fires.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Internal placeholder widget — retained during scaffolding phase
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
