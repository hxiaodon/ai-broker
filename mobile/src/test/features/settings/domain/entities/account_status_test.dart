import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/settings/domain/entities/account_status.dart';

AccountStatus _makeStatus({
  W8BenStatus w8BenStatus = W8BenStatus.valid,
  DateTime? w8BenExpiresAt,
}) =>
    AccountStatus(
      kycStatus: KycStatus.approved,
      amlStatus: AmlStatus.clear,
      w8BenStatus: w8BenStatus,
      w8BenExpiresAt: w8BenExpiresAt,
      withholdingTaxRate: '10%',
      tradingEnabled: true,
      withdrawalEnabled: true,
      depositEnabled: true,
    );

void main() {
  group('AccountStatus.isW8BenExpiringSoon — boundary values (PRD-02 §6.4; PRD-08 §5.2)', () {
    test('exactly 90 days left → expiring soon (boundary: inclusive)', () {
      final exp = DateTime.now().toUtc().add(const Duration(days: 90));
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpiringSoon, isTrue);
    });

    test('91 days left → NOT expiring soon (just outside boundary)', () {
      // Add 91.5 days to avoid inDays truncation causing boundary ambiguity
      final exp = DateTime.now().toUtc().add(const Duration(days: 91, hours: 12));
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpiringSoon, isFalse);
    });

    test('30 days left → expiring soon', () {
      final exp = DateTime.now().toUtc().add(const Duration(days: 30, hours: 12));
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpiringSoon, isTrue);
    });

    test('1 day left → expiring soon', () {
      final exp = DateTime.now().toUtc().add(const Duration(days: 1, hours: 12));
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpiringSoon, isTrue);
    });

    test('0 days left (today expires) → NOT expiring soon (already expired)', () {
      // inDays truncates toward zero — same-day expiry returns 0 which is !> 0
      final exp = DateTime.now().toUtc();
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpiringSoon, isFalse);
    });

    test('null expiresAt → NOT expiring soon', () {
      expect(_makeStatus(w8BenExpiresAt: null).isW8BenExpiringSoon, isFalse);
    });
  });

  group('AccountStatus.isW8BenExpired (PRD-02 §6.4)', () {
    test('past expiry date → expired', () {
      final exp = DateTime.now().toUtc().subtract(const Duration(days: 1));
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpired, isTrue);
    });

    test('future expiry → not expired', () {
      final exp = DateTime.now().toUtc().add(const Duration(days: 30));
      expect(_makeStatus(w8BenExpiresAt: exp).isW8BenExpired, isFalse);
    });

    test('null expiresAt + status=expired → expired', () {
      expect(
        _makeStatus(
          w8BenStatus: W8BenStatus.expired,
          w8BenExpiresAt: null,
        ).isW8BenExpired,
        isTrue,
      );
    });

    test('null expiresAt + status=valid → not expired', () {
      expect(
        _makeStatus(
          w8BenStatus: W8BenStatus.valid,
          w8BenExpiresAt: null,
        ).isW8BenExpired,
        isFalse,
      );
    });
  });
}
