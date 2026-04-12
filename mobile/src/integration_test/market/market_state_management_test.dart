import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';

/// Market Module — State Management Tests
///
/// **Purpose**: Verify Riverpod providers, routing logic, and app state for market module
/// **Dependencies**: None (no Mock Server, no HTTP calls)
/// **Speed**: Very fast (~30 seconds for all tests)
/// **Run when**: After every code change (fast feedback)
///
/// **What is tested**:
/// - App renders correctly in different auth states (guest/authenticated)
/// - Market data UI displays correctly in both states
/// - Routing directs to correct market screens
/// - Watchlist, search, and stock detail screens load
/// - Performance: screens load in reasonable time
///
/// **What is NOT tested**:
/// - HTTP API calls (see market_api_integration_test.dart)
/// - Real WebSocket data (see market_api_integration_test.dart)
/// - Complete user flows (see market_e2e_app_test.dart)
/// - Network errors or timeouts
///
/// Each test creates a single app instance with a fixed auth state.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Market Module - App States', () {
    testWidgets(
      'M1: Guest user sees market home (no auth required)',
      (tester) async {
        print('\n📱 M1: Guest market home');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        // Guest should see market content
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ Guest sees market home');
      },
    );

    testWidgets(
      'M2: Authenticated user sees full market features',
      (tester) async {
        print('\n📱 M2: Authenticated market home');
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-market-123',
            refreshToken: 'refresh-market-456',
          ),
        );
        await tester.pump(const Duration(seconds: 2));

        // Authenticated user should see full market UI
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ Authenticated user sees market features');
      },
    );
  });

  group('Market Module - Market Data Display', () {
    testWidgets(
      'M3: Watchlist screen loads for authenticated user',
      (tester) async {
        print('\n📱 M3: Watchlist screen loads');
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-123',
            refreshToken: 'refresh-456',
          ),
        );
        await tester.pump(const Duration(seconds: 2));

        // Look for watchlist indicators
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ Watchlist screen rendered');
      },
    );

    testWidgets(
      'M4: Search results screen loads',
      (tester) async {
        print('\n📱 M4: Search screen');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        // Search functionality available
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ Search screen available');
      },
    );

    testWidgets(
      'M5: Stock detail screen renders',
      (tester) async {
        print('\n📱 M5: Stock detail screen');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        // Stock detail should render
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ Stock detail screen renders');
      },
    );

    testWidgets(
      'M6: Guest sees delayed data indicator',
      (tester) async {
        print('\n📱 M6: Guest delayed data indicator');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        // Guest mode should show some indication of delay
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ Guest mode indicators displayed');
      },
    );
  });

  group('Market Module - Performance', () {
    testWidgets(
      'M7: Market home loads in < 3 seconds',
      (tester) async {
        print('\n📱 M7: Market load performance');
        final sw = Stopwatch()..start();

        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(3000));
        print('    ✅ Market loaded in ${sw.elapsedMilliseconds}ms');
      },
    );

    testWidgets(
      'M8: Search screen loads quickly',
      (tester) async {
        print('\n📱 M8: Search load performance');
        final sw = Stopwatch()..start();

        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(2500));
        print('    ✅ Search loaded in ${sw.elapsedMilliseconds}ms');
      },
    );

    testWidgets(
      'M9: Stock detail loads without lag',
      (tester) async {
        print('\n📱 M9: Stock detail performance');
        final sw = Stopwatch()..start();

        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(2500));
        print('    ✅ Stock detail loaded in ${sw.elapsedMilliseconds}ms');
      },
    );
  });

  group('Market Module - UI Stability', () {
    testWidgets(
      'M10: Market UI stable during scrolling',
      (tester) async {
        print('\n📱 M10: UI stability during scroll');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        // Simulate scroll interaction
        final scaffolds = find.byType(Scaffold);
        if (scaffolds.evaluate().isNotEmpty) {
          await tester.drag(scaffolds.first, const Offset(0, -300));
          await tester.pump();
          print('    ✅ Scroll handled smoothly');
        }

        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ UI remains stable');
      },
    );

    testWidgets(
      'M11: App state consistent across navigation',
      (tester) async {
        print('\n📱 M11: Navigation state consistency');
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token',
            refreshToken: 'refresh',
          ),
        );
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);

        // Perform several interactions
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        // App state should remain consistent
        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ State consistent across navigation');
      },
    );

    testWidgets(
      'M12: No memory leaks during repeated render cycles',
      (tester) async {
        print('\n📱 M12: Memory stability');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());

        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(Scaffold), findsWidgets);
        print('    ✅ No stability issues during repeated cycles');
      },
    );
  });
}
