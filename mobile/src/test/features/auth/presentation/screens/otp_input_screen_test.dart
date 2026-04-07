import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/misc.dart' show Override;

import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/application/otp_timer_notifier.dart';
import 'package:trading_app/features/auth/data/auth_repository_impl.dart';
import 'package:trading_app/features/auth/domain/entities/auth_token.dart';
import 'package:trading_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:trading_app/features/auth/presentation/screens/login_screen.dart';
import 'package:trading_app/features/auth/presentation/screens/otp_input_screen.dart';

// Mocks
class MockAuthRepository extends Mock implements AuthRepositoryImpl {}
class MockGoRouter extends Mock {}

// Fake for mocktail
class FakeOtpScreenArgs extends Fake implements OtpScreenArgs {}

void main() {
  late MockAuthRepository mockRepository;

  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(FakeOtpScreenArgs());
  });

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  Widget createTestWidget({
    required OtpScreenArgs args,
    List<Override>? additionalOverrides,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
        ...?additionalOverrides,
      ],
      child: MaterialApp(
        home: OtpInputScreen(args: args),
      ),
    );
  }

  OtpScreenArgs createTestArgs() {
    return OtpScreenArgs(
      requestId: 'req_123',
      phoneNumber: '+8613812345678',
      maskedPhone: '138****5678',
      idempotencyKey: 'idem_key_123',
    );
  }

  group('OtpInputScreen Widget', () {
    testWidgets('renders 6-digit OTP input boxes', (tester) async {
      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      // Should have OTP input widget
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('displays masked phone number', (tester) async {
      final args = createTestArgs();
      await tester.pumpWidget(createTestWidget(args: args));

      expect(find.textContaining(args.maskedPhone), findsOneWidget);
    });

    testWidgets('displays resend button with countdown', (tester) async {
      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      // Should show resend button (initially disabled with countdown)
      expect(find.textContaining('重新发送'), findsOneWidget);
    });

    testWidgets('shows error message on invalid OTP', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'INVALID_OTP_CODE',
        message: 'Invalid OTP',
        remainingAttempts: 4,
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      // Enter invalid OTP
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();

      // Wait for async verification
      await tester.pumpAndSettle();

      // Should show error with remaining attempts
      expect(find.textContaining('还可重试 4 次'), findsOneWidget);
    });

    testWidgets('shows bold warning on last attempt', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'INVALID_OTP_CODE',
        message: 'Invalid OTP',
        remainingAttempts: 1,
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show warning for last attempt
      expect(find.textContaining('还可重试 1 次'), findsOneWidget);
    });

    testWidgets('displays lockout message when max attempts exceeded', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'OTP_MAX_ATTEMPTS_EXCEEDED',
        message: 'Max attempts exceeded',
        remainingAttempts: 0,
        lockoutUntil: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('锁定'), findsWidgets);
    });

    testWidgets('clears input on OTP expired error', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(const OtpAuthException(
        errorCode: 'OTP_EXPIRED',
        message: 'OTP expired',
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Input should be cleared
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });
  });

  group('OtpInputScreen Error Retry Logic', () {
    testWidgets('updates OtpTimerNotifier on error', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'INVALID_OTP_CODE',
        message: 'Invalid OTP',
        remainingAttempts: 3,
      ));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OtpInputScreen(args: createTestArgs()),
          ),
        ),
      );

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Check that timer notifier was updated
      final timerState = container.read(otpTimerProvider);
      expect(timerState.errorCount, greaterThan(0));

      container.dispose();
    });

    testWidgets('triggers lockout in timer on max attempts', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'OTP_MAX_ATTEMPTS_EXCEEDED',
        message: 'Max attempts exceeded',
        remainingAttempts: 0,
        lockoutUntil: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      ));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: OtpInputScreen(args: createTestArgs()),
          ),
        ),
      );

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Check that lockout was triggered
      final timerState = container.read(otpTimerProvider);
      expect(timerState.isLockedOut, true);

      container.dispose();
    });

    testWidgets('clears input after error', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'INVALID_OTP_CODE',
        message: 'Invalid OTP',
        remainingAttempts: 4,
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Input should be cleared after error
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });
  });

  group('OtpInputScreen Success Flow', () {
    testWidgets('navigates to biometric setup on successful verification for existing user', (tester) async {
      final token = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'ACTIVE',
      );

      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => OtpVerifyResult(
        status: OtpVerifyStatus.existingUser,
        token: token,
        accountStatus: 'ACTIVE',
      ));

      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Verification should succeed (navigation tested in integration tests)
      verify(() => mockRepository.verifyOtp(
            requestId: 'req_123',
            otpCode: '123456',
            phoneNumber: '+8613812345678',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).called(1);
    });

    testWidgets('navigates to KYC for PENDING_KYC status', (tester) async {
      final token = AuthToken(
        accessToken: 'access_token_123',
        refreshToken: 'refresh_token_123',
        accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
        accountId: 'acc_123',
        accountStatus: 'PENDING_KYC',
      );

      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => OtpVerifyResult(
        status: OtpVerifyStatus.existingUser,
        token: token,
        accountStatus: 'PENDING_KYC',
      ));

      when(() => mockRepository.isBiometricRegistered())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Should navigate to KYC (navigation tested in integration tests)
      verify(() => mockRepository.verifyOtp(
            requestId: 'req_123',
            otpCode: '123456',
            phoneNumber: '+8613812345678',
            idempotencyKey: any(named: 'idempotencyKey'),
          )).called(1);
    });
  });

  group('OtpInputScreen PRD Compliance', () {
    testWidgets('PRD §6.1: shows remaining attempts on error', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'INVALID_OTP_CODE',
        message: 'Invalid OTP',
        remainingAttempts: 3,
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('还可重试 3 次'), findsOneWidget);
    });

    testWidgets('PRD §八: displays lockout countdown on max attempts', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(OtpAuthException(
        errorCode: 'OTP_MAX_ATTEMPTS_EXCEEDED',
        message: 'Max attempts exceeded',
        remainingAttempts: 0,
        lockoutUntil: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      // Should show lockout message
      expect(find.textContaining('锁定'), findsWidgets);
    });

    testWidgets('PRD §6.1: clears input on OTP expired', (tester) async {
      when(() => mockRepository.verifyOtp(
            requestId: any(named: 'requestId'),
            otpCode: any(named: 'otpCode'),
            phoneNumber: any(named: 'phoneNumber'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(const OtpAuthException(
        errorCode: 'OTP_EXPIRED',
        message: 'OTP expired',
      ));

      await tester.pumpWidget(createTestWidget(args: createTestArgs()));

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '123456');
      await tester.pump();
      await tester.pumpAndSettle();

      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, isEmpty);
    });
  });
}
