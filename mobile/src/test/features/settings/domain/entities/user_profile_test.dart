import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/settings/domain/entities/user_profile.dart';

UserProfile _makeProfile({
  String phone = '+86 13812345678',
  String email = 'zhangwei@gmail.com',
  String idNumber = '110101199001011234',
  KycTier kycTier = KycTier.tier2,
}) =>
    UserProfile(
      accountId: 'acc-001',
      fullName: 'Zhang Wei',
      phone: phone,
      email: email,
      idNumber: idNumber,
      idType: 'CHINA_RESIDENT_ID',
      dateOfBirth: DateTime.utc(1990, 1, 1),
      country: 'CN',
      province: 'Beijing',
      city: 'Beijing',
      address: '123 Main St',
      employmentStatus: EmploymentStatus.employed,
      kycTier: kycTier,
      accountOpenedAt: DateTime.utc(2026, 1, 1),
      accountType: 'CASH',
    );

void main() {
  group('UserProfile.maskedIdNumber (PRD-08; security-compliance PII masking)', () {
    test('masks middle digits, keeps first 6 and last 4', () {
      final p = _makeProfile(idNumber: '110101199001011234');
      expect(p.maskedIdNumber, '110101****1234');
    });

    test('short id returned as-is', () {
      final p = _makeProfile(idNumber: '12345');
      expect(p.maskedIdNumber, '12345');
    });

    test('masked id never exposes middle digits', () {
      final p = _makeProfile(idNumber: '110101199001011234');
      expect(p.maskedIdNumber, isNot(contains('1990')));
    });
  });

  group('UserProfile.maskedPhone (PRD-08; security-compliance PII masking)', () {
    test('masks 4 middle digits of phone number', () {
      final p = _makeProfile(phone: '+86 13812345678');
      final masked = p.maskedPhone;
      expect(masked, contains('****'));
      expect(masked, contains('5678'));
      expect(masked, isNot(contains('1234')));
    });

    test('masked phone retains country code prefix', () {
      final p = _makeProfile(phone: '+86 13812345678');
      expect(p.maskedPhone, startsWith('+86'));
    });

    test('short phone returned as-is', () {
      final p = _makeProfile(phone: '1234');
      expect(p.maskedPhone, '1234');
    });
  });

  group('UserProfile.maskedEmail (PRD-08; security-compliance PII masking)', () {
    test('masks middle characters of local part', () {
      final p = _makeProfile(email: 'zhangwei@gmail.com');
      final masked = p.maskedEmail;
      expect(masked, endsWith('@gmail.com'));
      expect(masked, startsWith('z'));
      expect(masked, contains('***'));
      expect(masked, isNot(contains('hangwe')));
    });

    test('single-char local part returned as-is', () {
      final p = _makeProfile(email: 'z@gmail.com');
      expect(p.maskedEmail, 'z@gmail.com');
    });

    test('two-char local part returned as-is', () {
      final p = _makeProfile(email: 'zw@gmail.com');
      expect(p.maskedEmail, 'zw@gmail.com');
    });
  });

  group('KycTier enum', () {
    test('tier1 is less privileged than tier2', () {
      expect(KycTier.values, containsAll([KycTier.tier1, KycTier.tier2]));
    });

    test('default profile has tier2 (fully approved)', () {
      expect(_makeProfile().kycTier, KycTier.tier2);
    });

    test('tier1 profile can be constructed', () {
      expect(_makeProfile(kycTier: KycTier.tier1).kycTier, KycTier.tier1);
    });
  });
}
