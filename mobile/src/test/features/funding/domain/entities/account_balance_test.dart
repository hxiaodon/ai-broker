import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/funding/domain/entities/account_balance.dart';

AccountBalance _makeBalance({
  String totalBalance = '12450.00',
  String availableBalance = '12450.00',
  String unsettledAmount = '0.00',
  String withdrawableBalance = '11450.00',
}) =>
    AccountBalance(
      accountId: 'acc-001',
      currency: 'USD',
      totalBalance: Decimal.parse(totalBalance),
      availableBalance: Decimal.parse(availableBalance),
      unsettledAmount: Decimal.parse(unsettledAmount),
      withdrawableBalance: Decimal.parse(withdrawableBalance),
      updatedAt: DateTime.utc(2026, 4, 27, 10, 0),
    );

void main() {
  group('AccountBalance fields', () {
    test('all amount fields are Decimal, not double', () {
      final balance = _makeBalance();
      expect(balance.totalBalance, isA<Decimal>());
      expect(balance.availableBalance, isA<Decimal>());
      expect(balance.unsettledAmount, isA<Decimal>());
      expect(balance.withdrawableBalance, isA<Decimal>());
    });

    test('amounts parse correctly', () {
      final balance = _makeBalance(
        totalBalance: '15000.50',
        availableBalance: '13000.25',
        unsettledAmount: '2000.25',
        withdrawableBalance: '12500.00',
      );
      expect(balance.totalBalance, Decimal.parse('15000.50'));
      expect(balance.availableBalance, Decimal.parse('13000.25'));
      expect(balance.unsettledAmount, Decimal.parse('2000.25'));
      expect(balance.withdrawableBalance, Decimal.parse('12500.00'));
    });

    test('updatedAt is UTC', () {
      expect(_makeBalance().updatedAt.isUtc, isTrue);
    });

    test('zero unsettled amount', () {
      final balance = _makeBalance(unsettledAmount: '0.00');
      expect(balance.unsettledAmount, Decimal.zero);
    });

    test('withdrawable is less than or equal to available', () {
      final balance = _makeBalance(
        availableBalance: '12450.00',
        withdrawableBalance: '11450.00',
      );
      expect(balance.withdrawableBalance <= balance.availableBalance, isTrue);
    });
  });

  group('AccountBalance.isWithdrawable (PRD-05 §5.1; fund-transfer-compliance Rule 4)', () {
    test('valid amount within withdrawable limit', () {
      final balance = _makeBalance(
        availableBalance: '10000.00',
        withdrawableBalance: '7000.00',
      );
      expect(balance.isWithdrawable(Decimal.parse('7000.00')), isTrue);
      expect(balance.isWithdrawable(Decimal.parse('3000.00')), isTrue);
    });

    test('amount equal to withdrawableBalance is allowed (exact limit)', () {
      final balance = _makeBalance(
        availableBalance: '10000.00',
        withdrawableBalance: '7000.00',
      );
      expect(balance.isWithdrawable(Decimal.parse('7000.00')), isTrue);
    });

    test('amount exceeding withdrawableBalance is rejected', () {
      final balance = _makeBalance(
        availableBalance: '10000.00',
        withdrawableBalance: '7000.00',
      );
      expect(balance.isWithdrawable(Decimal.parse('7000.01')), isFalse);
      expect(balance.isWithdrawable(Decimal.parse('10000.00')), isFalse);
    });

    test('zero amount is rejected', () {
      final balance = _makeBalance(withdrawableBalance: '5000.00');
      expect(balance.isWithdrawable(Decimal.zero), isFalse);
    });

    test('negative amount is rejected', () {
      final balance = _makeBalance(withdrawableBalance: '5000.00');
      expect(balance.isWithdrawable(Decimal.parse('-1.00')), isFalse);
    });

    test('any amount rejected when withdrawableBalance is zero', () {
      final balance = _makeBalance(
        availableBalance: '5000.00',
        withdrawableBalance: '0.00',
      );
      expect(balance.isWithdrawable(Decimal.parse('0.01')), isFalse);
    });

    test('unsettled proceeds reduce withdrawable — amount valid against withdrawable not available', () {
      // availableBalance=10000, unsettledAmount=3000 → withdrawableBalance=7000
      final balance = _makeBalance(
        availableBalance: '10000.00',
        unsettledAmount: '3000.00',
        withdrawableBalance: '7000.00',
      );
      expect(balance.isWithdrawable(Decimal.parse('8000.00')), isFalse);
      expect(balance.isWithdrawable(Decimal.parse('7000.00')), isTrue);
    });
  });

  group('AccountBalance.isValidWithdrawalAmount (static — used by withdraw screen)', () {
    test('respects withdrawableBalance when provided', () {
      expect(
        AccountBalance.isValidWithdrawalAmount(
          Decimal.parse('5000.00'),
          withdrawableBalance: Decimal.parse('7000.00'),
        ),
        isTrue,
      );
      expect(
        AccountBalance.isValidWithdrawalAmount(
          Decimal.parse('8000.00'),
          withdrawableBalance: Decimal.parse('7000.00'),
        ),
        isFalse,
      );
    });

    test('allows positive amount when withdrawableBalance is null (balance not yet loaded)', () {
      expect(
        AccountBalance.isValidWithdrawalAmount(Decimal.parse('100.00')),
        isTrue,
      );
    });

    test('rejects zero and negative amounts regardless of withdrawableBalance', () {
      expect(
        AccountBalance.isValidWithdrawalAmount(Decimal.zero),
        isFalse,
      );
      expect(
        AccountBalance.isValidWithdrawalAmount(Decimal.parse('-50.00')),
        isFalse,
      );
    });
  });
}
