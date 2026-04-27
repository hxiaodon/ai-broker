import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/funding/application/deposit_form_notifier.dart';
import 'package:trading_app/features/funding/data/funding_repository_impl.dart';
import 'package:trading_app/features/funding/domain/entities/fund_transfer.dart';
import 'package:trading_app/features/funding/domain/repositories/funding_repository.dart';

class MockFundingRepository extends Mock implements FundingRepository {}

FundTransfer _makePendingTransfer() => FundTransfer(
      transferId: 'txn-001',
      accountId: 'acc-001',
      type: TransferType.deposit,
      status: TransferStatus.pending,
      amount: Decimal.parse('1000.00'),
      currency: 'USD',
      channel: BankChannel.ach,
      bankAccountId: 'ba-001',
      requestId: 'idem-001',
      createdAt: DateTime.utc(2026, 4, 27),
      updatedAt: DateTime.utc(2026, 4, 27),
    );

ProviderContainer _buildContainer(MockFundingRepository mockRepo) =>
    ProviderContainer(
      overrides: [
        fundingRepositoryProvider.overrideWith((_) => mockRepo),
      ],
    );

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 50));

bool _isIdle(DepositFormState s) => s.when(
    idle: () => true,
    confirming: (_, _, _) => false,
    submitting: () => false,
    success: (_) => false,
    error: (_) => false);

bool _isConfirming(DepositFormState s) => s.when(
    idle: () => false,
    confirming: (_, _, _) => true,
    submitting: () => false,
    success: (_) => false,
    error: (_) => false);

bool _isSuccess(DepositFormState s) => s.when(
    idle: () => false,
    confirming: (_, _, _) => false,
    submitting: () => false,
    success: (_) => true,
    error: (_) => false);

bool _isError(DepositFormState s) => s.when(
    idle: () => false,
    confirming: (_, _, _) => false,
    submitting: () => false,
    success: (_) => false,
    error: (_) => true);

void main() {
  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(BankChannel.ach);
    registerFallbackValue(Decimal.zero);
  });

  late MockFundingRepository mockRepo;
  setUp(() => mockRepo = MockFundingRepository());

  group('DepositFormNotifier — initial state', () {
    test('starts in idle', () {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      expect(_isIdle(container.read(depositFormProvider)), isTrue);
    });
  });

  group('DepositFormNotifier — confirm()', () {
    test('idle → confirming with correct fields', () {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      container.read(depositFormProvider.notifier).confirm(
            amount: Decimal.parse('1000.00'),
            bankAccountId: 'ba-001',
            channel: 'ACH',
          );

      final s = container.read(depositFormProvider);
      expect(_isConfirming(s), isTrue);
      s.maybeWhen(
        confirming: (amount, bankAccountId, channel) {
          expect(amount, Decimal.parse('1000.00'));
          expect(bankAccountId, 'ba-001');
          expect(channel, 'ACH');
        },
        orElse: () {},
      );
    });

    test('WIRE channel preserved', () {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      container.read(depositFormProvider.notifier).confirm(
            amount: Decimal.parse('5000.00'),
            bankAccountId: 'ba-002',
            channel: 'WIRE',
          );

      container.read(depositFormProvider).maybeWhen(
            confirming: (_, _, channel) => expect(channel, 'WIRE'),
            orElse: () {},
          );
    });
  });

  group('DepositFormNotifier — backToIdle()', () {
    test('confirming → idle', () {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      final notifier = container.read(depositFormProvider.notifier);

      notifier.confirm(amount: Decimal.parse('500.00'), bankAccountId: 'ba-001', channel: 'ACH');
      expect(_isConfirming(container.read(depositFormProvider)), isTrue);

      notifier.backToIdle();
      expect(_isIdle(container.read(depositFormProvider)), isTrue);
    });
  });

  group('DepositFormNotifier — submit() success', () {
    test('confirming → success with correct transferId', () async {
      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((_) async => _makePendingTransfer());

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      final notifier = container.read(depositFormProvider.notifier);
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.submit();
      await pump();

      final s = container.read(depositFormProvider);
      expect(_isSuccess(s), isTrue);
      s.maybeWhen(
        success: (transferId) => expect(transferId, 'txn-001'),
        orElse: () {},
      );
    });

    test('submit() without confirm is a no-op', () async {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      await container.read(depositFormProvider.notifier).submit();
      await pump();
      verifyNever(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ));
      expect(_isIdle(container.read(depositFormProvider)), isTrue);
    });
  });

  group('DepositFormNotifier — submit() failure', () {
    test('confirming → error on repository failure', () async {
      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenThrow(Exception('Network error'));

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      final notifier = container.read(depositFormProvider.notifier);
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.submit();
      await pump();

      expect(_isError(container.read(depositFormProvider)), isTrue);
    });
  });

  group('DepositFormNotifier — idempotency key semantics', () {
    test('retry reuses the same idempotency key', () async {
      final capturedKeys = <String>[];
      var callCount = 0;

      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((inv) async {
        capturedKeys.add(
            inv.namedArguments[const Symbol('idempotencyKey')] as String);
        callCount++;
        if (callCount == 1) throw Exception('Transient error');
        return _makePendingTransfer();
      });

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      final notifier = container.read(depositFormProvider.notifier);

      // First attempt — fails
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.submit();
      await pump();
      expect(_isError(container.read(depositFormProvider)), isTrue);

      // Retry with same params
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.submit();
      await pump();

      expect(capturedKeys, hasLength(2));
      expect(capturedKeys[0], capturedKeys[1],
          reason: 'Retry must reuse the same idempotency key');
    });

    test('reset() clears key — next submit uses a new key', () async {
      final capturedKeys = <String>[];
      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((inv) async {
        capturedKeys.add(
            inv.namedArguments[const Symbol('idempotencyKey')] as String);
        return _makePendingTransfer();
      });

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      final notifier = container.read(depositFormProvider.notifier);

      notifier.confirm(amount: Decimal.parse('500.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.submit();
      await pump();

      notifier.reset();

      notifier.confirm(amount: Decimal.parse('800.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.submit();
      await pump();

      expect(capturedKeys, hasLength(2));
      expect(capturedKeys[0], isNot(capturedKeys[1]),
          reason: 'After reset(), a fresh idempotency key must be generated');
    });
  });

  group('DepositFormNotifier — reset()', () {
    test('returns to idle from any non-idle state', () {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      final notifier = container.read(depositFormProvider.notifier);

      notifier.confirm(amount: Decimal.parse('100.00'), bankAccountId: 'ba-001', channel: 'ACH');
      expect(_isConfirming(container.read(depositFormProvider)), isTrue);

      notifier.reset();
      expect(_isIdle(container.read(depositFormProvider)), isTrue);
    });
  });
}
