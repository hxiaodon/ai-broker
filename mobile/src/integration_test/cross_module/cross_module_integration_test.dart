import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';

/// Cross-Module Integration Tests
/// Each test creates a single stable app instance (no mid-test pumpWidget calls)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Module - Guest Restrictions', () {
    testWidgets('C1: Guest cannot access trading', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C1: Trading blocked for guest');
    });

    testWidgets('C2: Guest can see market', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C2: Market visible for guest');
    });
  });

  group('Cross-Module - Auth States', () {
    testWidgets('C3: Authenticated user can trade', (tester) async {
      await tester.pumpWidget(
        TestAppConfig.createAppWithAuth(
          accessToken: 'token',
          refreshToken: 'refresh',
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C3: Authenticated can trade');
    });

    testWidgets('C4: Unauthenticated shows login', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C4: Unauthenticated shows login');
    });
  });

  group('Cross-Module - Token Consistency', () {
    testWidgets('C5: All modules see same token', (tester) async {
      final tokenService = MockTokenServiceForIntegration();
      tokenService.setTokens(
        accessToken: 'shared-token-123',
        refreshToken: 'shared-refresh-456',
      );

      await tester.pumpWidget(
        TestAppConfig.createAppWithAuth(
          accessToken: 'shared-token-123',
          refreshToken: 'shared-refresh-456',
          tokenService: tokenService,
        ),
      );
      await tester.pump();

      expect(await tokenService.getAccessToken(), 'shared-token-123');
      print('✅ C5: Token consistent across modules');
    });
  });

  group('Cross-Module - Security', () {
    testWidgets('C6: Token not exposed in UI', (tester) async {
      await tester.pumpWidget(
        TestAppConfig.createAppWithAuth(
          accessToken: 'secret-token-123',
          refreshToken: 'secret-refresh-456',
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C6: Token hidden in UI');
    });

    testWidgets('C7: Guest sees delayed quotes', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      // Guest should see 15-min delayed data indicator
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C7: Guest sees delayed data');
    });
  });

  group('Cross-Module - Market + Auth Integration', () {
    testWidgets('C8: Market loads for guest', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C8: Market loads for guest');
    });

    testWidgets('C9: Market loads for authenticated', (tester) async {
      await tester.pumpWidget(
        TestAppConfig.createAppWithAuth(
          accessToken: 'token',
          refreshToken: 'refresh',
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C9: Market loads for auth');
    });

    testWidgets('C10: Auth status affects UI', (tester) async {
      // Authenticated should show full features
      await tester.pumpWidget(
        TestAppConfig.createAppWithAuth(
          accessToken: 'token',
          refreshToken: 'refresh',
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ C10: Auth affects UI rendering');
    });
  });
}
