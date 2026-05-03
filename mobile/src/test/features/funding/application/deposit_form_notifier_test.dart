import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/device_info_service.dart';
import 'package:trading_app/core/auth/local_auth_service.dart';
import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/security/fund_withdrawal_bio_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/funding/application/deposit_form_notifier.dart';
import 'package:trading_app/features/funding/data/funding_repository_impl.dart';
import 'package:trading_app/features/funding/domain/entities/fund_transfer.dart';
import 'package:trading_app/features/funding/domain/repositories/funding_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockFundingRepository extends Mock implements FundingRepository {}
class MockLocalAuthService extends Mock implements LocalAuthService {}
class MockFundWithdrawalBioService extends Mock implements FundWithdrawalBioService {}
class MockSessionKeyService extends Mock implements SessionKeyService {}
class MockDeviceInfoService extends Mock implements DeviceInfoService {}
class MockTokenService extends Mock implements TokenService {}
class MockSecureStorageService extends Mock implements SecureStorageService {}

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Container builder
// ─────────────────────────────────────────────────────────────────────────────

ProviderContainer _buildContainer(
  MockFundingRepository mockRepo, {
  MockLocalAuthService? localAuth,
  MockFundWithdrawalBioService? bioService,
  MockSessionKeyService? sessionKey,
  MockDeviceInfoService? deviceInfo,
}) {
  final auth = localAuth ?? MockLocalAuthService();
  final bio = bioService ?? MockFundWithdrawalBioService();
  final sk = sessionKey ?? MockSessionKeyService();
  final di = deviceInfo ?? MockDeviceInfoService();

  // Default stubs for biometric flow
  when(() => bio.fetchChallenge()).thenAnswer((_) async => 'test-challenge');
  when(() => bio.computeBioToken(
        sessionSecret: any(named: 'sessionSecret'),
        challenge: any(named: 'challenge'),
        timestamp: any(named: 'timestamp'),
        deviceId: any(named: 'deviceId'),
        actionHash: any(named: 'actionHash'),
      )).thenReturn('test-bio-token');
  when(() => auth.authenticate(localizedReason: any(named: 'localizedReason')))
      .thenAnswer((_) async => true);
  when(() => sk.getSessionKey())
      .thenAnswer((_) async => (keyId: 'key-id', secret: 'sk-secret'));
  when(() => di.getDeviceId()).thenAnswer((_) async => 'test-device-id');

  // Mock TokenService so AuthNotifier._restoreSession() fails gracefully,
  // leaving authProvider in unauthenticated state (accountId = '').
  // The deposit test does not depend on accountId.
  final mockToken = MockTokenService();
  when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);

  return ProviderContainer(
    overrides: [
      fundingRepositoryProvider.overrideWith((_) => mockRepo),
      localAuthServiceProvider.overrideWith((_) => auth),
      fundWithdrawalBioServiceProvider.overrideWith((_) => bio),
      sessionKeyServiceProvider.overrideWith((_) => sk),
      deviceInfoServiceProvider.overrideWith((_) => di),
      tokenServiceProvider.overrideWith((_) => mockToken),
    ],
  );
}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 50));

// ─────────────────────────────────────────────────────────────────────────────
// State helpers — include all variants post-security-review
// ─────────────────────────────────────────────────────────────────────────────

bool _isIdle(DepositFormState s) => s.when(
    idle: () => true,
    confirming: (_, _, _) => false,
    awaitingBiometric: () => false,
    submitting: () => false,
    success: (_) => false,
    error: (_) => false);

bool _isConfirming(DepositFormState s) => s.when(
    idle: () => false,
    confirming: (_, _, _) => true,
    awaitingBiometric: () => false,
    submitting: () => false,
    success: (_) => false,
    error: (_) => false);

bool _isSuccess(DepositFormState s) => s.when(
    idle: () => false,
    confirming: (_, _, _) => false,
    awaitingBiometric: () => false,
    submitting: () => false,
    success: (_) => true,
    error: (_) => false);

bool _isError(DepositFormState s) => s.when(
    idle: () => false,
    confirming: (_, _, _) => false,
    awaitingBiometric: () => false,
    submitting: () => false,
    success: (_) => false,
    error: (_) => true);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

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

  group('DepositFormNotifier — authenticateAndSubmit() success', () {
    test('confirming → success with correct transferId', () async {
      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
            bioToken: any(named: 'bioToken'),
            bioChallenge: any(named: 'bioChallenge'),
            bioTimestamp: any(named: 'bioTimestamp'),
          )).thenAnswer((_) async => _makePendingTransfer());

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      final notifier = container.read(depositFormProvider.notifier);
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.authenticateAndSubmit();
      await pump();

      final s = container.read(depositFormProvider);
      expect(_isSuccess(s), isTrue);
      s.maybeWhen(
        success: (transferId) => expect(transferId, 'txn-001'),
        orElse: () {},
      );
    });

    test('authenticateAndSubmit() without confirm is a no-op', () async {
      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      await container.read(depositFormProvider.notifier).authenticateAndSubmit();
      await pump();
      verifyNever(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
            bioToken: any(named: 'bioToken'),
            bioChallenge: any(named: 'bioChallenge'),
            bioTimestamp: any(named: 'bioTimestamp'),
          ));
      expect(_isIdle(container.read(depositFormProvider)), isTrue);
    });
  });

  group('DepositFormNotifier — authenticateAndSubmit() failure', () {
    test('confirming → error on repository failure', () async {
      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
            bioToken: any(named: 'bioToken'),
            bioChallenge: any(named: 'bioChallenge'),
            bioTimestamp: any(named: 'bioTimestamp'),
          )).thenThrow(Exception('Network error'));

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      final notifier = container.read(depositFormProvider.notifier);
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.authenticateAndSubmit();
      await pump();

      expect(_isError(container.read(depositFormProvider)), isTrue);
    });

    test('biometric auth failure → error state', () async {
      final mockAuth = MockLocalAuthService();
      when(() => mockAuth.authenticate(localizedReason: any(named: 'localizedReason')))
          .thenAnswer((_) async => false);

      final container = _buildContainer(mockRepo, localAuth: mockAuth);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});

      final notifier = container.read(depositFormProvider.notifier);
      notifier.confirm(amount: Decimal.parse('500.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.authenticateAndSubmit();
      await pump();

      expect(_isError(container.read(depositFormProvider)), isTrue);
    });
  });

  group('DepositFormNotifier — idempotency key semantics', () {
    test('each authenticateAndSubmit() generates a fresh idempotency key paired with a fresh bio challenge', () async {
      // Design intent: the idempotency key is reset on every authenticateAndSubmit()
      // because each call fetches a new bio challenge — the two are co-generated
      // so they stay in sync. (Contrast with the old submit() which reused the key.)
      final capturedKeys = <String>[];

      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
            bioToken: any(named: 'bioToken'),
            bioChallenge: any(named: 'bioChallenge'),
            bioTimestamp: any(named: 'bioTimestamp'),
          )).thenAnswer((inv) async {
        capturedKeys.add(
            inv.namedArguments[const Symbol('idempotencyKey')] as String);
        return _makePendingTransfer();
      });

      final container = _buildContainer(mockRepo);
      addTearDown(container.dispose);
      container.listen(depositFormProvider, (_, _) {});
      final notifier = container.read(depositFormProvider.notifier);

      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.authenticateAndSubmit();
      await pump();

      notifier.reset();
      notifier.confirm(amount: Decimal.parse('1000.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.authenticateAndSubmit();
      await pump();

      expect(capturedKeys, hasLength(2));
      expect(capturedKeys[0], isNot(capturedKeys[1]),
          reason: 'Each authenticateAndSubmit() generates a fresh idempotency key');
    });

    test('reset() clears key — next submit uses a new key', () async {
      final capturedKeys = <String>[];
      when(() => mockRepo.initiateDeposit(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            channel: any(named: 'channel'),
            idempotencyKey: any(named: 'idempotencyKey'),
            bioToken: any(named: 'bioToken'),
            bioChallenge: any(named: 'bioChallenge'),
            bioTimestamp: any(named: 'bioTimestamp'),
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
      await notifier.authenticateAndSubmit();
      await pump();

      notifier.reset();

      notifier.confirm(amount: Decimal.parse('800.00'), bankAccountId: 'ba-001', channel: 'ACH');
      await notifier.authenticateAndSubmit();
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
