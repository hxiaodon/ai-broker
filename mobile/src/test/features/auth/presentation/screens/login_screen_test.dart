import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/data/auth_repository_impl.dart';
import 'package:trading_app/features/auth/presentation/screens/login_screen.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepositoryImpl {}

void main() {
  late MockAuthRepository mockRepository;

  setUpAll(() => AppLogger.init());

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget', () {
    testWidgets('renders phone input field and send button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('获取验证码'), findsOneWidget);
    });

    testWidgets('send button is disabled when phone is empty', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final sendButton = find.widgetWithText(ElevatedButton, '获取验证码');
      expect(sendButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(sendButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('send button is disabled for invalid China phone (< 11 digits)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter 10 digits (invalid for +86)
      await tester.enterText(find.byType(TextField), '1381234567');
      await tester.pump();

      final sendButton = find.widgetWithText(ElevatedButton, '获取验证码');
      final button = tester.widget<ElevatedButton>(sendButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('send button is enabled for valid China phone (11 digits)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter 11 digits (valid for +86)
      await tester.enterText(find.byType(TextField), '13812345678');
      await tester.pump();

      final sendButton = find.widgetWithText(ElevatedButton, '获取验证码');
      final button = tester.widget<ElevatedButton>(sendButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('send button is disabled for invalid HK phone (< 8 digits)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Switch to Hong Kong
      final countryPicker = find.byKey(const Key('country_code_button'));
      expect(countryPicker, findsOneWidget);
      await tester.tap(countryPicker);
      await tester.pumpAndSettle();

      // Select Hong Kong
      await tester.tap(find.text('+852'));
      await tester.pumpAndSettle();

      // Enter 7 digits (invalid for +852)
      await tester.enterText(find.byType(TextField), '1234567');
      await tester.pump();

      final sendButton = find.widgetWithText(ElevatedButton, '获取验证码');
      final button = tester.widget<ElevatedButton>(sendButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('send button is enabled for valid HK phone (8 digits)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Switch to Hong Kong
      final countryPicker = find.byKey(const Key('country_code_button'));
      await tester.tap(countryPicker);
      await tester.pumpAndSettle();

      await tester.tap(find.text('+852'));
      await tester.pumpAndSettle();

      // Enter 8 digits (valid for +852)
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.pump();

      final sendButton = find.widgetWithText(ElevatedButton, '获取验证码');
      final button = tester.widget<ElevatedButton>(sendButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('phone input accepts only digits', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Try to enter letters and special characters
      await tester.enterText(find.byType(TextField), 'abc123!@#456');
      await tester.pump();

      // Should only keep digits
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, contains('123456'));
    });

    testWidgets('displays guest mode entry button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('先逛逛'), findsOneWidget);
    });

    testWidgets('shows error message on send failure', (tester) async {
      when(() => mockRepository.sendOtp(
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());

      // Enter valid phone
      await tester.enterText(find.byType(TextField), '13812345678');
      await tester.pump();

      // Tap send button
      await tester.tap(find.widgetWithText(ElevatedButton, '获取验证码'));
      await tester.pump();

      // Wait for async operation
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('失败'), findsOneWidget);
    });
  });

  group('LoginScreen Phone Format Validation', () {
    testWidgets('China +86: accepts exactly 11 digits', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Test 10 digits - invalid
      await tester.enterText(find.byType(TextField), '1381234567');
      await tester.pump();
      var button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '获取验证码'),
      );
      expect(button.onPressed, isNull);

      // Test 11 digits - valid
      await tester.enterText(find.byType(TextField), '13812345678');
      await tester.pump();
      button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '获取验证码'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Hong Kong +852: accepts exactly 8 digits', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Switch to Hong Kong
      await tester.tap(find.byKey(const Key('country_code_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+852'));
      await tester.pumpAndSettle();

      // Test 7 digits - invalid
      await tester.enterText(find.byType(TextField), '1234567');
      await tester.pump();
      var button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '获取验证码'),
      );
      expect(button.onPressed, isNull);

      // Test 8 digits - valid
      await tester.enterText(find.byType(TextField), '12345678');
      await tester.pump();
      button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '获取验证码'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('LoginScreen PRD Compliance', () {
    testWidgets('PRD §6.1: supports +86 China (11 digits)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.enterText(find.byType(TextField), '13812345678');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '获取验证码'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('PRD §6.1: supports +852 Hong Kong (8 digits)', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.byKey(const Key('country_code_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+852'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12345678');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '获取验证码'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('PRD §4.3: provides guest mode entry', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('先逛逛'), findsOneWidget);
    });
  });
}
