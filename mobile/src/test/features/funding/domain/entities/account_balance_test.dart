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
}
