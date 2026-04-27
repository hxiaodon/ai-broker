import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/funding/domain/entities/bank_account.dart';

BankAccount _makeAccount({
  bool isVerified = true,
  DateTime? cooldownEndsAt,
  MicroDepositStatus microDepositStatus = MicroDepositStatus.verified,
  int remainingVerifyAttempts = 5,
}) =>
    BankAccount(
      id: 'ba-001',
      accountName: 'John Smith',
      accountNumberMasked: '****1234',
      routingNumber: '021000021',
      bankName: 'Chase Bank',
      currency: 'USD',
      isVerified: isVerified,
      cooldownEndsAt: cooldownEndsAt,
      microDepositStatus: microDepositStatus,
      remainingVerifyAttempts: remainingVerifyAttempts,
      createdAt: DateTime.utc(2026, 4, 1),
    );

void main() {
  group('BankAccount.isInCooldown', () {
    test('false when cooldownEndsAt is null', () {
      expect(_makeAccount(cooldownEndsAt: null).isInCooldown, isFalse);
    });

    test('true when cooldownEndsAt is in the future', () {
      final future = DateTime.now().toUtc().add(const Duration(hours: 48));
      expect(_makeAccount(cooldownEndsAt: future).isInCooldown, isTrue);
    });

    test('false when cooldownEndsAt is in the past', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      expect(_makeAccount(cooldownEndsAt: past).isInCooldown, isFalse);
    });
  });

  group('BankAccount.isUsable', () {
    test('true when verified and no cooldown', () {
      expect(
        _makeAccount(isVerified: true, cooldownEndsAt: null).isUsable,
        isTrue,
      );
    });

    test('false when not verified (pending micro-deposit)', () {
      expect(
        _makeAccount(
          isVerified: false,
          microDepositStatus: MicroDepositStatus.pending,
        ).isUsable,
        isFalse,
      );
    });

    test('false when verified but still in cooldown', () {
      final future = DateTime.now().toUtc().add(const Duration(days: 2));
      expect(
        _makeAccount(isVerified: true, cooldownEndsAt: future).isUsable,
        isFalse,
      );
    });

    test('true when verified and cooldown has expired', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      expect(
        _makeAccount(isVerified: true, cooldownEndsAt: past).isUsable,
        isTrue,
      );
    });
  });

  group('MicroDepositStatus enum', () {
    test('has 4 values: pending, verifying, verified, failed', () {
      expect(MicroDepositStatus.values, hasLength(4));
      expect(MicroDepositStatus.values,
          containsAll([
            MicroDepositStatus.pending,
            MicroDepositStatus.verifying,
            MicroDepositStatus.verified,
            MicroDepositStatus.failed,
          ]));
    });
  });

  group('BankAccount fields', () {
    test('accountNumberMasked preserves last-4-digit format', () {
      final account = _makeAccount();
      expect(account.accountNumberMasked, '****1234');
      expect(account.accountNumberMasked, startsWith('****'));
    });

    test('remainingVerifyAttempts defaults to 5', () {
      expect(_makeAccount().remainingVerifyAttempts, 5);
    });

    test('createdAt is UTC', () {
      expect(_makeAccount().createdAt.isUtc, isTrue);
    });
  });
}
