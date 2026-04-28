import 'package:freezed_annotation/freezed_annotation.dart';
import 'kyc_enums.dart';

part 'personal_info.freezed.dart';

enum IdType {
  chinaResidentId,
  hkid,
  passport,
  mainlandPermit;

  String toApi() => switch (this) {
        chinaResidentId => 'CHINA_RESIDENT_ID',
        hkid => 'HKID',
        passport => 'INTL_PASSPORT',
        mainlandPermit => 'MAINLAND_PERMIT',
      };
}

@freezed
abstract class PersonalInfo with _$PersonalInfo {
  const factory PersonalInfo({
    required String firstName,
    required String lastName,
    String? chineseName,
    required DateTime dateOfBirth,
    required String nationality,
    required IdType idType,
    required EmploymentStatus employmentStatus,
    String? employerName,
    @Default(false) bool isPep,
    @Default(false) bool isInsiderOfBroker,
  }) = _PersonalInfo;

  const PersonalInfo._();

  String get fullName => '$firstName $lastName';

  bool get isAdult {
    final now = DateTime.now().toUtc();
    final dob = dateOfBirth.toUtc();
    var age = now.year - dob.year;
    // Subtract 1 if the birthday hasn't occurred yet this year.
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  bool get requiresManualReview => isPep || isInsiderOfBroker;
}
