import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/funding/application/bank_accounts_notifier.dart';
import 'package:trading_app/features/funding/data/funding_repository_impl.dart';
import 'package:trading_app/features/funding/domain/entities/bank_account.dart';
import 'package:trading_app/features/funding/domain/repositories/funding_repository.dart';

// ─── Mock ─────────────────────────────────────────────────────────────────────

class MockFundingRepository extends Mock implements FundingRepository {}

// ─── Fixtures ─────────────────────────────────────────────────────────────────

BankAccount _makeAccount({
  String id = 'ba-001',
  bool isVerified = true,
  MicroDepositStatus microDepositStatus = MicroDepositStatus.verified,
}) =>
    BankAccount(
      id: id,
      accountName: 'John Smith',
      accountNumberMasked: '****1234',
      routingNumber: '021000021',
      bankName: 'Chase Bank',
      currency: 'USD',
      isVerified: isVerified,
      cooldownEndsAt: null,
      microDepositStatus: microDepositStatus,
      remainingVerifyAttempts: 5,
      createdAt: DateTime.utc(2026, 4, 1),
    );

ProviderContainer _buildContainer(
  MockFundingRepository mockRepo, {
  List<BankAccount> initialAccounts = const [],
}) {
  when(() => mockRepo.getBankAccounts())
      .thenAnswer((_) async => initialAccounts);
  return ProviderContainer(
    overrides: [
      fundingRepositoryProvider.overrideWith((_) => mockRepo),
    ],
  );
}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 50));

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() => AppLogger.init());

  late MockFundingRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(Decimal.zero);
  });

  setUp(() {
    mockRepo = MockFundingRepository();
  });

  group('BankAccountsNotifier — build()', () {
    test('loads accounts from repository on init', () async {
      final accounts = [_makeAccount(id: 'ba-001'), _makeAccount(id: 'ba-002')];
      final container = _buildContainer(mockRepo, initialAccounts: accounts);
      addTearDown(container.dispose);

      // Trigger provider
      final sub = container.listen(bankAccountsProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();

      final state = container.read(bankAccountsProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, hasLength(2));
      expect(state.value!.map((a) => a.id), containsAll(['ba-001', 'ba-002']));
    });

    test('starts in loading state', () {
      when(() => mockRepo.getBankAccounts())
          .thenAnswer((_) async => [_makeAccount()]);
      final container = ProviderContainer(overrides: [
        fundingRepositoryProvider.overrideWith((_) => mockRepo),
      ]);
      addTearDown(container.dispose);

      container.listen(bankAccountsProvider, (_, _) {});
      final state = container.read(bankAccountsProvider);
      expect(state.isLoading, isTrue);
    });
  });

  group('BankAccountsNotifier — addBankAccount()', () {
    test('appends new account to list', () async {
      final container = _buildContainer(mockRepo, initialAccounts: [_makeAccount(id: 'ba-001')]);
      addTearDown(container.dispose);

      final newAccount = _makeAccount(
        id: 'ba-002',
        isVerified: false,
        microDepositStatus: MicroDepositStatus.pending,
      );
      when(() => mockRepo.addBankAccount(
            accountName: any(named: 'accountName'),
            accountNumber: any(named: 'accountNumber'),
            routingNumber: any(named: 'routingNumber'),
            bankName: any(named: 'bankName'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => newAccount);

      final sub = container.listen(bankAccountsProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();

      await container.read(bankAccountsProvider.notifier).addBankAccount(
            accountName: 'John Smith',
            accountNumber: '987654321',
            routingNumber: '021000021',
            bankName: 'Bank of America',
            idempotencyKey: 'idem-bind-001',
          );
      await pump();

      final accounts = container.read(bankAccountsProvider).value!;
      expect(accounts, hasLength(2));
      expect(accounts.map((a) => a.id), contains('ba-002'));
    });

    test('rolls back on repository failure', () async {
      final container = _buildContainer(mockRepo, initialAccounts: [_makeAccount(id: 'ba-001')]);
      addTearDown(container.dispose);

      when(() => mockRepo.addBankAccount(
            accountName: any(named: 'accountName'),
            accountNumber: any(named: 'accountNumber'),
            routingNumber: any(named: 'routingNumber'),
            bankName: any(named: 'bankName'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(Exception('Server error'));

      final sub = container.listen(bankAccountsProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();

      try {
        await container.read(bankAccountsProvider.notifier).addBankAccount(
              accountName: 'John Smith',
              accountNumber: '123456789',
              routingNumber: '021000021',
              bankName: 'Chase',
              idempotencyKey: 'idem-bind-fail',
            );
      } catch (_) {}
      await pump();

      // List should remain unchanged
      expect(container.read(bankAccountsProvider).value, hasLength(1));
    });
  });

  group('BankAccountsNotifier — removeBankAccount()', () {
    test('removes account by id', () async {
      final accounts = [_makeAccount(id: 'ba-001'), _makeAccount(id: 'ba-002')];
      when(() => mockRepo.removeBankAccount('ba-001'))
          .thenAnswer((_) async {});

      final container = _buildContainer(mockRepo, initialAccounts: accounts);
      addTearDown(container.dispose);
      final sub = container.listen(bankAccountsProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();

      await container.read(bankAccountsProvider.notifier).removeBankAccount('ba-001');
      await pump();

      final remaining = container.read(bankAccountsProvider).value!;
      expect(remaining, hasLength(1));
      expect(remaining.first.id, 'ba-002');
    });

    test('rollback on repository failure', () async {
      final accounts = [_makeAccount(id: 'ba-001'), _makeAccount(id: 'ba-002')];
      when(() => mockRepo.removeBankAccount(any()))
          .thenThrow(Exception('Delete failed'));

      final container = _buildContainer(mockRepo, initialAccounts: accounts);
      addTearDown(container.dispose);
      final sub = container.listen(bankAccountsProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();

      try {
        await container.read(bankAccountsProvider.notifier).removeBankAccount('ba-001');
      } catch (_) {}
      await pump();

      // Rollback: both accounts should still be there
      expect(container.read(bankAccountsProvider).value, hasLength(2));
    });
  });

  group('BankAccountsNotifier — verifyMicroDeposit()', () {
    test('updates matching account with server response', () async {
      final pendingAccount = _makeAccount(
        id: 'ba-002',
        isVerified: false,
        microDepositStatus: MicroDepositStatus.pending,
      );
      final verifiedAccount = BankAccount(
        id: 'ba-002',
        accountName: 'John Smith',
        accountNumberMasked: '****1234',
        routingNumber: '021000021',
        bankName: 'Chase Bank',
        currency: 'USD',
        isVerified: true,
        cooldownEndsAt: DateTime.utc(2026, 4, 30),
        microDepositStatus: MicroDepositStatus.verified,
        remainingVerifyAttempts: 5,
        createdAt: DateTime.utc(2026, 4, 1),
      );

      when(() => mockRepo.verifyMicroDeposit(
            bankAccountId: 'ba-002',
            amount1: any(named: 'amount1'),
            amount2: any(named: 'amount2'),
          )).thenAnswer((_) async => verifiedAccount);

      final container = _buildContainer(
        mockRepo,
        initialAccounts: [_makeAccount(id: 'ba-001'), pendingAccount],
      );
      addTearDown(container.dispose);
      final sub = container.listen(bankAccountsProvider, (_, _) {});
      addTearDown(sub.close);
      await pump();

      await container.read(bankAccountsProvider.notifier).verifyMicroDeposit(
            bankAccountId: 'ba-002',
            amount1: Decimal.parse('0.15'),
            amount2: Decimal.parse('0.23'),
          );
      await pump();

      final accounts = container.read(bankAccountsProvider).value!;
      final updated = accounts.firstWhere((a) => a.id == 'ba-002');
      expect(updated.isVerified, isTrue);
      expect(updated.microDepositStatus, MicroDepositStatus.verified);
    });
  });
}
