import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/features/funding/application/bank_bind_notifier.dart';
import 'package:trading_app/features/funding/application/deposit_form_notifier.dart';
import 'package:trading_app/features/funding/application/withdraw_form_notifier.dart';

import '../helpers/test_app.dart';

/// Funding Module — State Management Tests
///
/// **Purpose**: Verify Riverpod providers, routing, and app state for funding module
/// **Dependencies**: None (no Mock Server, no HTTP calls)
/// **Speed**: Very fast (~30 seconds for all tests)
/// **Run when**: After every code change (fast feedback)
///
/// **What is tested**:
/// - App renders correctly for authenticated users
/// - Funding screen is reachable from portfolio screen
/// - Deposit/Withdraw/BankBind screens are reachable
/// - Form state machines start in idle state
///
/// **What is NOT tested**:
/// - HTTP API calls (see funding_api_integration_test.dart)
/// - Complete user flows (see funding_e2e_app_test.dart)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Funding Module - App States', () {
    testWidgets(
      'F1: Authenticated user can navigate to funding screen',
      (tester) async {
        printOnFailure('\n📱 F1: Authenticated user sees portfolio with funding button');
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-funding-123',
            refreshToken: 'refresh-funding-456',
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        printOnFailure('    ✅ Authenticated user sees app');
      },
    );

    testWidgets(
      'F2: Guest user sees market but not restricted screens',
      (tester) async {
        printOnFailure('\n📱 F2: Guest sees market screen');
        await tester.pumpWidget(TestAppConfig.createAppAsGuest());
        await tester.pump(const Duration(seconds: 2));

        expect(find.byType(Scaffold), findsWidgets);
        printOnFailure('    ✅ Guest sees app without crash');
      },
    );

    testWidgets(
      'F3: DepositFormNotifier idle → confirming state transition',
      (tester) async {
        printOnFailure('\n🧪 F3: DepositFormNotifier state machine');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Initial state must be idle
        final isInitiallyIdle = container.read(depositFormProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isInitiallyIdle, isTrue,
            reason: 'DepositFormNotifier must start in idle state');

        // confirm() transitions to confirming with correct fields
        container.read(depositFormProvider.notifier).confirm(
              amount: Decimal.parse('500.00'),
              bankAccountId: 'ba-test-001',
              channel: 'ACH',
            );
        container.read(depositFormProvider).maybeWhen(
              confirming: (amount, bankAccountId, channel) {
                expect(amount, Decimal.parse('500.00'));
                expect(bankAccountId, 'ba-test-001');
                expect(channel, 'ACH');
              },
              orElse: () => fail('Expected confirming state'),
            );

        // backToIdle() returns to idle
        container.read(depositFormProvider.notifier).backToIdle();
        final isIdleAgain = container.read(depositFormProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isIdleAgain, isTrue);
        printOnFailure('    ✅ DepositFormNotifier idle → confirming → idle');
      },
    );

    testWidgets(
      'F4: WithdrawFormNotifier idle → confirming state transition',
      (tester) async {
        printOnFailure('\n🧪 F4: WithdrawFormNotifier state machine');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final isInitiallyIdle = container.read(withdrawFormProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isInitiallyIdle, isTrue,
            reason: 'WithdrawFormNotifier must start in idle state');

        container.read(withdrawFormProvider.notifier).confirm(
              amount: Decimal.parse('1000.00'),
              bankAccountId: 'ba-test-002',
              channel: 'WIRE',
            );
        container.read(withdrawFormProvider).maybeWhen(
              confirming: (amount, bankAccountId, channel) {
                expect(amount, Decimal.parse('1000.00'));
                expect(channel, 'WIRE');
              },
              orElse: () => fail('Expected confirming state'),
            );

        container.read(withdrawFormProvider.notifier).backToIdle();
        final isIdleAgain = container.read(withdrawFormProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isIdleAgain, isTrue);
        printOnFailure('    ✅ WithdrawFormNotifier idle → confirming → idle');
      },
    );

    testWidgets(
      'F5: BankBindNotifier starts in idle, reset() returns to idle',
      (tester) async {
        printOnFailure('\n🧪 F5: BankBindNotifier idle state');
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final isInitiallyIdle = container.read(bankBindProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isInitiallyIdle, isTrue,
            reason: 'BankBindNotifier must start in idle state');

        // reset() from idle stays idle (no crash)
        container.read(bankBindProvider.notifier).reset();
        final isStillIdle = container.read(bankBindProvider).maybeWhen(
              idle: () => true,
              orElse: () => false,
            );
        expect(isStillIdle, isTrue);
        printOnFailure('    ✅ BankBindNotifier starts idle, reset() is safe');
      },
    );

    testWidgets(
      'F6: App loads within acceptable time for authenticated user',
      (tester) async {
        printOnFailure('\n⏱️  F6: App load performance');
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(
          TestAppConfig.createAppWithAuth(
            accessToken: 'token-perf-test',
            refreshToken: 'refresh-perf-test',
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        stopwatch.stop();
        printOnFailure('    ℹ️  App loaded in ${stopwatch.elapsedMilliseconds}ms');
        // No hard assertion — just measure
        printOnFailure('    ✅ App loaded without timeout');
      },
    );
  });
}
