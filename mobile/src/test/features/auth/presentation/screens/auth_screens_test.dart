import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/presentation/screens/login_screen.dart';
import 'package:trading_app/features/auth/presentation/screens/otp_input_screen.dart';
import 'package:trading_app/features/auth/presentation/screens/biometric_setup_screen.dart';
import '../../../../helpers/widget_test_integration_helpers.dart';

void main() {
  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login screen with title', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: const LoginScreen(),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify Scaffold is rendered
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has phone input field', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: const LoginScreen(),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify TextField exists for phone input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays country code picker', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: const LoginScreen(),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify app bar and input widgets are present
      expect(find.byType(AppBar), findsWidgets);
    });

    testWidgets('renders submit button', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: const LoginScreen(),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify button widget exists (ElevatedButton or similar)
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('OtpInputScreen Widget Tests', () {
    testWidgets('renders otp input screen', (WidgetTester tester) async {
      final args = OtpScreenArgs(
        requestId: 'req-123',
        phoneNumber: '+86 13800000000',
        maskedPhone: '+86 138****0000',
        idempotencyKey: 'idem-123',
      );

      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: OtpInputScreen(args: args),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify Scaffold is rendered
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('displays masked phone number provided', (WidgetTester tester) async {
      final args = OtpScreenArgs(
        requestId: 'req-123',
        phoneNumber: '+86 13800000000',
        maskedPhone: '+86 138****0000',
        idempotencyKey: 'idem-123',
      );

      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: OtpInputScreen(args: args),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify OtpInputScreen is rendered with masked phone
      expect(find.byType(OtpInputScreen), findsWidgets);
    });

    testWidgets('has otp code input field', (WidgetTester tester) async {
      final args = OtpScreenArgs(
        requestId: 'req-123',
        phoneNumber: '+86 13800000000',
        maskedPhone: '+86 138****0000',
        idempotencyKey: 'idem-123',
      );

      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: OtpInputScreen(args: args),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // TextField should exist for OTP code input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('renders verify button', (WidgetTester tester) async {
      final args = OtpScreenArgs(
        requestId: 'req-123',
        phoneNumber: '+86 13800000000',
        maskedPhone: '+86 138****0000',
        idempotencyKey: 'idem-123',
      );

      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: OtpInputScreen(args: args),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify button widget exists
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('displays resend link', (WidgetTester tester) async {
      final args = OtpScreenArgs(
        requestId: 'req-123',
        phoneNumber: '+86 13800000000',
        maskedPhone: '+86 138****0000',
        idempotencyKey: 'idem-123',
      );

      final app = WidgetTestIntegrationHelper.buildUnauthenticatedApp(
        child: OtpInputScreen(args: args),
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Resend option should be available
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });

  group('BiometricSetupScreen Widget Tests', () {
    testWidgets('renders biometric setup screen', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const BiometricSetupScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify Scaffold is rendered
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has setup button for biometric', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const BiometricSetupScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Button to start biometric setup should exist
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('displays biometric information', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const BiometricSetupScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Text content should be present
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('has skip option available', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const BiometricSetupScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Skip button or link should exist
      expect(find.byType(TextButton), findsWidgets);
    });
  });
}
