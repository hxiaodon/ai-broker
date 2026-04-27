import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/funding/application/bank_accounts_notifier.dart';
import 'package:trading_app/features/funding/application/bank_bind_notifier.dart';
import 'package:trading_app/features/funding/data/funding_repository_impl.dart';
import 'package:trading_app/features/funding/domain/entities/bank_account.dart';
import 'package:trading_app/features/funding/domain/repositories/funding_repository.dart';

// ─── Mock ─────────────────────────────────────────────────────────────────────

class MockFundingRepository extends Mock implements FundingRepository {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

BankAccount _makePendingAccount({String id = 'ba-new'}) => BankAccount(
      id: id,
      accountName: 'John Smith',
      accountNumberMasked: '****5678',
      routingNumber: '021000021',
      bankName: 'Chase Bank',
      currency: 'USD',
      isVerified: false,
      cooldownEndsAt: DateTime.utc(2026, 4, 30),
      microDepositStatus: MicroDepositStatus.pending,
      remainingVerifyAttempts: 5,
      createdAt: DateTime.utc(2026, 4, 27),
    );

ProviderContainer _buildContainer(MockFundingRepository mockRepo) {
  when(() => mockRepo.getBankAccounts()).thenAnswer((_) async => []);
  return ProviderContainer(
    overrides: [
      fundingRepositoryProvider.overrideWith((_) => mockRepo),
    ],
  );
}

Future<void> pump([int ms = 50]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

bool _isIdle(BankBindState s) =>
    s.when(idle: () => true, submitting: () => false,
        pendingMicroDeposit: (_, _) => false, error: (_) => false);

bool _isPendingMicroDeposit(BankBindState s) =>
    s.when(idle: () => false, submitting: () => false,
        pendingMicroDeposit: (_, _) => true, error: (_) => false);

bool _isError(BankBindState s) =>
    s.when(idle: () => false, submitting: () => false,
        pendingMicroDeposit: (_, _) => false, error: (_) => true);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(Decimal.zero);
  });

  late MockFundingRepository mockRepo;

  setUp(() {
    mockRepo = MockFundingRepository();
  });

  group('BankBindNotifier — initial state', () {
    test('starts in idle', () {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      // Use listen to keep provider alive
      container.listen(bankBindProvider, (_, _) {});
      expect(_isIdle(container.read(bankBindProvider)), isTrue);
    });
  });

  group('BankBindNotifier — submit() success', () {
    test('idle → pendingMicroDeposit on success', () async {
      final newAccount = _makePendingAccount();
      when(() => mockRepo.addBankAccount(
            accountName: any(named: 'accountName'),
            accountNumber: any(named: 'accountNumber'),
            routingNumber: any(named: 'routingNumber'),
            bankName: any(named: 'bankName'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => newAccount);

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);

      // Keep both providers alive
      container.listen(bankAccountsProvider, (_, _) {});
      container.listen(bankBindProvider, (_, _) {});
      await pump();

      await container.read(bankBindProvider.notifier).submit(
            accountName: 'John Smith',
            accountNumber: '987654321',
            routingNumber: '021000021',
            bankName: 'Chase Bank',
          );
      await pump();

      final s = container.read(bankBindProvider);
      expect(_isPendingMicroDeposit(s), isTrue);
      s.maybeWhen(
        pendingMicroDeposit: (bankAccountId, cooldownEndsAt) {
          expect(bankAccountId, 'ba-new');
          expect(cooldownEndsAt.isUtc, isTrue);
        },
        orElse: () => fail('Expected pendingMicroDeposit state'),
      );
    });

    test('cooldownEndsAt falls back to ~3 days if server returns null', () async {
      final accountNoCooldown = BankAccount(
        id: 'ba-ncd',
        accountName: 'John Smith',
        accountNumberMasked: '****9999',
        routingNumber: '021000021',
        bankName: 'Chase',
        currency: 'USD',
        isVerified: false,
        cooldownEndsAt: null,
        microDepositStatus: MicroDepositStatus.pending,
        remainingVerifyAttempts: 5,
        createdAt: DateTime.utc(2026, 4, 27),
      );
      when(() => mockRepo.addBankAccount(
            accountName: any(named: 'accountName'),
            accountNumber: any(named: 'accountNumber'),
            routingNumber: any(named: 'routingNumber'),
            bankName: any(named: 'bankName'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => accountNoCooldown);

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(bankAccountsProvider, (_, _) {});
      container.listen(bankBindProvider, (_, _) {});
      await pump();

      final before = DateTime.now().toUtc();
      await container.read(bankBindProvider.notifier).submit(
            accountName: 'John Smith',
            accountNumber: '999999999',
            routingNumber: '021000021',
            bankName: 'Chase',
          );
      await pump();

      container.read(bankBindProvider).maybeWhen(
        pendingMicroDeposit: (_, cooldownEndsAt) {
          final minExpected = before.add(const Duration(days: 2, hours: 23));
          final maxExpected =
              before.add(const Duration(days: 3, hours: 1));
          expect(cooldownEndsAt.isAfter(minExpected), isTrue,
              reason: 'cooldown should be ~3 days from now');
          expect(cooldownEndsAt.isBefore(maxExpected), isTrue);
        },
        orElse: () => fail('Expected pendingMicroDeposit'),
      );
    });
  });

  group('BankBindNotifier — submit() failure', () {
    test('idle → error on repository failure', () async {
      when(() => mockRepo.addBankAccount(
            accountName: any(named: 'accountName'),
            accountNumber: any(named: 'accountNumber'),
            routingNumber: any(named: 'routingNumber'),
            bankName: any(named: 'bankName'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(Exception('Network error'));

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(bankAccountsProvider, (_, _) {});
      container.listen(bankBindProvider, (_, _) {});
      await pump();

      await container.read(bankBindProvider.notifier).submit(
            accountName: 'John Smith',
            accountNumber: '123456789',
            routingNumber: '021000021',
            bankName: 'Chase',
          );
      await pump();

      expect(_isError(container.read(bankBindProvider)), isTrue);
    });
  });

  group('BankBindNotifier — reset()', () {
    test('returns to idle from error', () async {
      when(() => mockRepo.addBankAccount(
            accountName: any(named: 'accountName'),
            accountNumber: any(named: 'accountNumber'),
            routingNumber: any(named: 'routingNumber'),
            bankName: any(named: 'bankName'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(Exception('Fail'));

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(bankAccountsProvider, (_, _) {});
      container.listen(bankBindProvider, (_, _) {});
      await pump();

      await container.read(bankBindProvider.notifier).submit(
            accountName: 'John Smith',
            accountNumber: '000000000',
            routingNumber: '111111111',
            bankName: 'Bank',
          );
      await pump();
      expect(_isError(container.read(bankBindProvider)), isTrue);

      container.read(bankBindProvider.notifier).reset();
      expect(_isIdle(container.read(bankBindProvider)), isTrue);
    });
  });
}
