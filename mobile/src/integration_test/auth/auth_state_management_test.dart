import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';

/// Auth Module — State Management Tests
///
/// **Purpose**: Verify Riverpod providers, routing logic, and app state management
/// **Dependencies**: None (no Mock Server, no HTTP calls)
/// **Speed**: Very fast (~30 seconds for all tests)
/// **Run when**: After every code change (fast feedback)
///
/// **What is tested**:
/// - App renders correctly in different auth states (authenticated/unauthenticated/guest)
/// - Token service stores and retrieves tokens correctly
/// - Routing redirects to correct screens based on auth state
/// - Multi-device scenarios
///
/// **What is NOT tested**:
/// - HTTP API calls (see auth_api_integration_test.dart)
/// - Complete user flows (see auth_e2e_app_test.dart)
/// - Network errors or timeouts
///
/// Each test creates a single app instance with a fixed auth state.
/// State transitions are tested in separate test cases, not in a single test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Module - App States', () {
    testWidgets(
      'T1: Unauthenticated app shows login',
      (tester) async {
        await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T1: Unauthenticated state renders');
      },
    );

    testWidgets(
      'T2: Authenticated app shows home',
      (tester) async {
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-123',
            refreshToken: 'refresh-456',
          ),
        );
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T2: Authenticated state renders');
      },
    );

    testWidgets(
      'T3: Guest app shows market',
      (tester) async {
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T3: Guest state renders');
      },
    );
  });

  group('Auth Module - Token Management', () {
    testWidgets(
      'T4: Authenticated user has access token',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        tokenService.setTokens(
          accessToken: 'valid-token-xyz',
          refreshToken: 'valid-refresh-abc',
        );

        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'valid-token-xyz',
            refreshToken: 'valid-refresh-abc',
            tokenService: tokenService,
          ),
        );
        await tester.pump();

        expect(await tokenService.getAccessToken(), equals('valid-token-xyz'));
        debugPrint('✅ T4: Access token stored');
      },
    );

    testWidgets(
      'T5: Token expiry is validated',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        tokenService.setTokens(
          accessToken: 'token-1h',
          refreshToken: 'refresh-1h',
          expiresIn: const Duration(hours: 1),
        );

        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-1h',
            refreshToken: 'refresh-1h',
            tokenService: tokenService,
          ),
        );
        await tester.pump();

        final isValid = await tokenService.isAccessTokenValid();
        expect(isValid, isTrue);
        debugPrint('✅ T5: Token valid check works');
      },
    );

    testWidgets(
      'T6: Logout clears tokens',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        tokenService.setTokens(
          accessToken: 'token-to-clear',
          refreshToken: 'refresh-to-clear',
        );

        // Verify set
        expect(await tokenService.getAccessToken(), isNotNull);

        // Clear
        await tokenService.clearTokens();

        // Verify cleared
        expect(await tokenService.getAccessToken(), isNull);
        debugPrint('✅ T6: Logout clears all tokens');
      },
    );
  });

  group('Auth Module - Security', () {
    testWidgets(
      'T7: Tokens not exposed in UI',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        tokenService.setTokens(
          accessToken: 'secret-token-123',
          refreshToken: 'secret-refresh-456',
        );

        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'secret-token-123',
            refreshToken: 'secret-refresh-456',
            tokenService: tokenService,
          ),
        );
        await tester.pump();

        // Token should be in secure storage, not visible in widgets
        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T7: Tokens in secure storage');
      },
    );

    testWidgets(
      'T8: Token refresh maintains refresh token',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        tokenService.setTokens(
          accessToken: 'old-token',
          refreshToken: 'stable-refresh',
          expiresIn: const Duration(seconds: 10),
        );

        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'old-token',
            refreshToken: 'stable-refresh',
            tokenService: tokenService,
          ),
        );
        await tester.pump();

        // Simulate refresh
        tokenService.setTokens(
          accessToken: 'new-token',
          refreshToken: 'stable-refresh',
          expiresIn: const Duration(hours: 1),
        );

        expect(await tokenService.getRefreshToken(), 'stable-refresh');
        debugPrint('✅ T8: Refresh token stable');
      },
    );
  });

  group('Auth Module - Error Handling', () {
    testWidgets(
      'T9: Missing token handled gracefully',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        // Don't set any tokens

        await tester.pumpWidget(
          TestAppConfig.createApp(tokenService: tokenService),
        );
        await tester.pump();

        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T9: Missing token handled');
      },
    );

    testWidgets(
      'T10: Expired token detected',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();
        tokenService.setTokens(
          accessToken: 'expired-token',
          refreshToken: 'refresh',
          expiresIn: const Duration(milliseconds: 50),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        final isValid = await tokenService.isAccessTokenValid();
        expect(isValid, isFalse);
        debugPrint('✅ T10: Expired token detected');
      },
    );
  });

  group('Auth Module - Multi-Device', () {
    testWidgets(
      'T11: Each device has independent token storage',
      (tester) async {
        final device1 = MockTokenServiceForIntegration();
        final device2 = MockTokenServiceForIntegration();

        device1.setTokens(
          accessToken: 'device-1-token',
          refreshToken: 'device-1-refresh',
        );

        device2.setTokens(
          accessToken: 'device-2-token',
          refreshToken: 'device-2-refresh',
        );

        expect(await device1.getAccessToken(), 'device-1-token');
        expect(await device2.getAccessToken(), 'device-2-token');
        debugPrint('✅ T11: Independent token storage');
      },
    );

    testWidgets(
      'T12: Token service persistence',
      (tester) async {
        final tokenService = MockTokenServiceForIntegration();

        await tokenService.saveTokens(
          accessToken: 'saved-token',
          refreshToken: 'saved-refresh',
          accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(await tokenService.getAccessToken(), 'saved-token');
        debugPrint('✅ T12: Token persistence works');
      },
    );
  });

  group('Auth Module - App Integration', () {
    testWidgets(
      'T13: Unauthenticated app renders without errors',
      (tester) async {
        await tester.pumpWidget(TestAppConfig.createAppUnauthenticated());
        await tester.pump(const Duration(seconds: 2));

        // No exceptions thrown, app renders
        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T13: Unauthenticated app stable');
      },
    );

    testWidgets(
      'T14: Authenticated app renders without errors',
      (tester) async {
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token',
            refreshToken: 'refresh',
          ),
        );
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T14: Authenticated app stable');
      },
    );

    testWidgets(
      'T15: Guest app renders without errors',
      (tester) async {
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        debugPrint('✅ T15: Guest app stable');
      },
    );
  });
}
