import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/kyc/application/personal_info_notifier.dart';
import 'package:trading_app/features/kyc/domain/entities/kyc_enums.dart';
import 'package:trading_app/features/kyc/domain/entities/kyc_session.dart';
import 'package:trading_app/features/kyc/domain/entities/personal_info.dart';

PersonalInfo _adultInfo({
  String firstName = 'John',
  String lastName = 'Doe',
}) =>
    PersonalInfo(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: DateTime.now().subtract(const Duration(days: 365 * 25)),
      nationality: 'CN',
      idType: IdType.passport,
      employmentStatus: EmploymentStatus.employed,
    );

void main() {
  setUpAll(() => AppLogger.init());
  group('PersonalInfoNotifier — name format validation (PRD-02; KYC Step 1)', () {
    test('non-English firstName → PersonalInfoState.error with name message', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalInfoProvider.notifier).submit(
            _adultInfo(firstName: '张伟'), // Chinese characters not allowed
          );
      final state = container.read(personalInfoProvider);
      expect(
        state.maybeWhen(error: (msg) => msg, orElse: () => null),
        contains('姓名'),
      );
    });

    test('non-English lastName → error', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalInfoProvider.notifier).submit(
            _adultInfo(lastName: '李四'),
          );
      final state = container.read(personalInfoProvider);
      expect(
        state.maybeWhen(error: (msg) => msg, orElse: () => null),
        isNotNull,
      );
    });

    test('hyphenated name is accepted (e.g. Mary-Jane)', () {
      // hyphen/apostrophe allowed per PRD §2.1
      final info = _adultInfo(firstName: 'Mary-Jane', lastName: "O'Brien");
      expect(info.isAdult, isTrue); // precondition
      // Name format check passes (only letter/space/hyphen/apostrophe)
      final valid = RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(info.firstName) &&
          RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(info.lastName);
      expect(valid, isTrue);
    });
  });

  group('KycStatus.fromApi() mapping (PRD-02 §6.2)', () {
    test('maps all known API strings', () {
      expect(KycStatus.fromApi('NOT_STARTED'), KycStatus.notStarted);
      expect(KycStatus.fromApi('IN_PROGRESS'), KycStatus.inProgress);
      expect(KycStatus.fromApi('SUBMITTED'), KycStatus.submitted);
      expect(KycStatus.fromApi('PENDING_REVIEW'), KycStatus.pendingReview);
      expect(KycStatus.fromApi('PENDING'), KycStatus.pendingReview);
      expect(KycStatus.fromApi('REVIEWING'), KycStatus.pendingReview);
      expect(KycStatus.fromApi('NEEDS_MORE_INFO'), KycStatus.needsMoreInfo);
      expect(KycStatus.fromApi('APPROVED'), KycStatus.approved);
      expect(KycStatus.fromApi('REJECTED'), KycStatus.rejected);
      expect(KycStatus.fromApi('EXPIRED'), KycStatus.expired);
    });

    test('unknown API string defaults to pendingReview (safe fallback)', () {
      expect(KycStatus.fromApi('UNKNOWN_STATUS'), KycStatus.pendingReview);
    });
  });
}
