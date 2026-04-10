import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/routing/app_router.dart';
import 'package:trading_app/core/routing/route_names.dart';
import 'package:trading_app/features/auth/application/auth_notifier.dart';

class MockGoRouterState extends Mock implements GoRouterState {
  MockGoRouterState(this._matchedLocation);
  final String _matchedLocation;

  @override
  String get matchedLocation => _matchedLocation;
}

void main() {
  GoRouterState state(String path) => MockGoRouterState(path);

  group('appRouterRedirect — unauthenticated', () {
    const auth = AuthState.unauthenticated();

    test('splash allowed', () {
      expect(appRouterRedirect(auth, state('/')), isNull);
    });

    test('auth routes allowed', () {
      expect(appRouterRedirect(auth, state('/auth/login')), isNull);
      expect(appRouterRedirect(auth, state('/auth/otp')), isNull);
    });

    test('market redirects to splash', () {
      expect(appRouterRedirect(auth, state('/market')), RouteNames.authSplash);
    });

    test('trading redirects to splash', () {
      expect(appRouterRedirect(auth, state('/trading')), RouteNames.authSplash);
    });

    test('portfolio redirects to splash', () {
      expect(appRouterRedirect(auth, state('/portfolio')), RouteNames.authSplash);
    });
  });

  group('appRouterRedirect — authenticated (ACTIVE)', () {
    const auth = AuthState.authenticated(
      accountId: 'acc-1',
      accountStatus: 'ACTIVE',
      biometricEnabled: false,
    );

    test('market allowed', () {
      expect(appRouterRedirect(auth, state('/market')), isNull);
    });

    test('trading allowed', () {
      expect(appRouterRedirect(auth, state('/trading')), isNull);
    });

    test('auth routes redirect to market', () {
      expect(appRouterRedirect(auth, state('/auth/login')), RouteNames.market);
    });

    test('splash redirects to market', () {
      expect(appRouterRedirect(auth, state('/')), RouteNames.market);
    });
  });

  group('appRouterRedirect — authenticated (PENDING_KYC)', () {
    const auth = AuthState.authenticated(
      accountId: 'acc-1',
      accountStatus: 'PENDING_KYC',
      biometricEnabled: false,
    );

    test('market redirects to KYC', () {
      expect(appRouterRedirect(auth, state('/market')), RouteNames.kycRoot);
    });

    test('KYC route allowed', () {
      expect(appRouterRedirect(auth, state('/kyc')), isNull);
    });

    test('auth routes redirect to market', () {
      expect(appRouterRedirect(auth, state('/auth/login')), RouteNames.market);
    });
  });

  group('appRouterRedirect — guest', () {
    const auth = AuthState.guest();

    test('splash allowed', () {
      expect(appRouterRedirect(auth, state('/')), isNull);
    });

    test('market allowed (guest browsing)', () {
      expect(appRouterRedirect(auth, state('/market')), isNull);
    });

    test('trading/order redirects to login', () {
      expect(
        appRouterRedirect(auth, state('/trading/order')),
        RouteNames.authLogin,
      );
    });

    test('portfolio allowed (shows GuestPlaceholder inline)', () {
      expect(appRouterRedirect(auth, state('/portfolio')), isNull);
    });
  });

  group('appRouterRedirect — authenticating', () {
    const auth = AuthState.authenticating();

    test('always returns null (splash handles loading)', () {
      expect(appRouterRedirect(auth, state('/')), isNull);
      expect(appRouterRedirect(auth, state('/market')), isNull);
    });
  });
}
