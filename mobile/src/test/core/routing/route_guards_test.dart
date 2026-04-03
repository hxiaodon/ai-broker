import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/routing/route_guards.dart';
import 'package:trading_app/core/routing/route_names.dart';

// Mock GoRouterState since its constructor is complex and varies by go_router version
class MockGoRouterState extends Mock implements GoRouterState {
  final String _matchedLocation;
  final Uri _uri;
  final Map<String, String> _pathParameters;

  MockGoRouterState({
    required String matchedLocation,
    Map<String, String> pathParameters = const {},
  })
      : _matchedLocation = matchedLocation,
        _pathParameters = pathParameters,
        _uri = Uri.parse('http://localhost$matchedLocation');

  @override
  String get matchedLocation => _matchedLocation;

  @override
  Uri get uri => _uri;

  @override
  Map<String, String> get pathParameters => _pathParameters;
}

class _DummyBuildContext extends BuildContext {
  @override
  bool get mounted => true;

  @override
  Widget get widget => const SizedBox();

  RenderObject? get renderObject => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RouteGuards routeGuards;

  setUpAll(() {
    // Initialize AppLogger before any tests run to enable structured logging
    // throughout all test suites. Required for logging-dependent assertions.
    AppLogger.init(verbose: true);
  });

  setUp(() {
    routeGuards = const RouteGuards();
  });

  GoRouterState createMockState(String matchedLocation) {
    final state = MockGoRouterState(matchedLocation: matchedLocation);
    return state;
  }

  BuildContext createMockContext() {
    // Use a dummy context — RouteGuards only uses context for logging
    return _DummyBuildContext();
  }

  group('RouteGuards - Unauthenticated User', () {
    testWidgets('unauthenticated user accessing market redirects to login', (tester) async {
      final state = createMockState(RouteNames.market);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });

    testWidgets('unauthenticated user accessing orders redirects to login', (tester) async {
      final state = createMockState('/orders');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });

    testWidgets('unauthenticated user accessing portfolio redirects to login', (tester) async {
      final state = createMockState('/portfolio');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });

    testWidgets('unauthenticated user accessing auth routes allowed', (tester) async {
      final state = createMockState(RouteNames.authLogin);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, isNull); // Allow navigation
    });

    testWidgets('unauthenticated user accessing OTP screen allowed', (tester) async {
      final state = createMockState('/auth/otp');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, isNull); // Allow navigation
    });
  });

  group('RouteGuards - Authenticated User', () {
    testWidgets('authenticated user accessing market allowed', (tester) async {
      final state = createMockState(RouteNames.market);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, isNull); // Allow navigation
    });

    testWidgets('authenticated user accessing orders allowed', (tester) async {
      final state = createMockState('/orders');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, isNull); // Allow navigation
    });

    testWidgets('authenticated user accessing portfolio allowed', (tester) async {
      final state = createMockState('/portfolio');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, isNull); // Allow navigation
    });

    testWidgets('authenticated user accessing login redirects to market', (tester) async {
      final state = createMockState(RouteNames.authLogin);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, RouteNames.market);
    });

    testWidgets('authenticated user accessing biometric login redirects to market', (tester) async {
      final state = createMockState('/auth/biometric-login');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, RouteNames.market);
    });

    testWidgets('authenticated user accessing any /auth/* redirects to market', (tester) async {
      final state = createMockState('/auth/otp');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, RouteNames.market);
    });
  });

  group('RouteGuards - KYC Incomplete', () {
    testWidgets('authenticated without KYC accessing market redirects to KYC', (tester) async {
      final state = createMockState(RouteNames.market);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, '/kyc');
    });

    testWidgets('authenticated without KYC accessing orders redirects to KYC', (tester) async {
      final state = createMockState('/orders');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, '/kyc');
    });

    testWidgets('authenticated without KYC accessing portfolio redirects to KYC', (tester) async {
      final state = createMockState('/portfolio');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, '/kyc');
    });

    testWidgets('authenticated without KYC accessing KYC route allowed', (tester) async {
      final state = createMockState('/kyc');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, isNull); // Allow navigation
    });

    testWidgets('authenticated without KYC accessing /kyc/verify allowed', (tester) async {
      final state = createMockState('/kyc/verify');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, isNull); // Allow navigation
    });

    testWidgets('authenticated without KYC accessing auth routes redirected to market', (tester) async {
      final state = createMockState('/auth/device-management');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.market); // Authenticated accessing auth routes → market
    });
  });

  group('RouteGuards - Edge Cases', () {
    testWidgets('guest user accessing market allowed (guest mode not in scope)', (tester) async {
      // Note: Guest mode is separate concern; routing treats guest as unauthenticated
      final state = createMockState(RouteNames.market);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });

    testWidgets('root path without auth redirects to login', (tester) async {
      final state = createMockState('/');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });

    testWidgets('unknown route with auth allowed (no guard blocks it)', (tester) async {
      final state = createMockState('/unknown/route');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, isNull); // Allow navigation (GoRouter will handle 404)
    });

    testWidgets('unknown route without auth redirects to login', (tester) async {
      final state = createMockState('/unknown/route');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });
  });

  group('RouteGuards - PRD Compliance (T17)', () {
    testWidgets('unauthenticated → /auth/login', (tester) async {
      final state = createMockState(RouteNames.market);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: false,
        hasCompletedKyc: false,
      );

      expect(result, RouteNames.authLogin);
    });

    testWidgets('KYC APPROVED allowed to trading/portfolio', (tester) async {
      final state = createMockState('/orders');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, isNull);
    });

    testWidgets('KYC NOT APPROVED → /kyc', (tester) async {
      final state = createMockState('/orders');
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: false,
      );

      expect(result, '/kyc');
    });

    testWidgets('authenticated accessing auth routes → market', (tester) async {
      final state = createMockState(RouteNames.authLogin);
      final result = routeGuards.redirect(
        context: createMockContext(),
        state: state,
        isAuthenticated: true,
        hasCompletedKyc: true,
      );

      expect(result, RouteNames.market);
    });
  });
}
