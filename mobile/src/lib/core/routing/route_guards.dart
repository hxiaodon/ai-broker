import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../logging/app_logger.dart';

/// Route guards for authentication and KYC status.
///
/// These are integrated into [AppRouter] via the [GoRouter.redirect] callback.
/// Phase 1 provides the skeleton; actual auth state will be wired via Riverpod
/// when [AuthNotifier] is implemented.
class RouteGuards {
  const RouteGuards();

  /// Returns a redirect path if the user should not access [state.matchedLocation],
  /// or null to allow navigation.
  ///
  /// Called by [GoRouter.redirect] on every navigation event.
  String? redirect({
    required BuildContext context,
    required GoRouterState state,
    required bool isAuthenticated,
    required bool hasCompletedKyc,
  }) {
    final path = state.matchedLocation;
    final isAuthRoute = path.startsWith('/auth');
    final isKycRoute = path.startsWith('/kyc');

    // Not authenticated → redirect to login (except auth routes)
    if (!isAuthenticated && !isAuthRoute) {
      AppLogger.debug('RouteGuard: unauthenticated, redirecting to login');
      return '/auth/login';
    }

    // Authenticated but accessing auth routes → redirect to market
    if (isAuthenticated && isAuthRoute) {
      return '/market';
    }

    // Authenticated but KYC not complete → only allow KYC and auth routes
    if (isAuthenticated && !hasCompletedKyc && !isKycRoute && !isAuthRoute) {
      AppLogger.debug('RouteGuard: KYC incomplete, redirecting to kyc');
      return '/kyc';
    }

    return null; // Allow navigation
  }
}
