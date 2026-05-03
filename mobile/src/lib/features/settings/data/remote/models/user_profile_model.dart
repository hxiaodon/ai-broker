import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../core/logging/app_logger.dart';
import '../../../domain/entities/user_profile.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
abstract class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'full_name') required String fullName,
    required String phone,
    required String email,
    @JsonKey(name: 'id_number') required String idNumber,
    @JsonKey(name: 'id_type') required String idType,
    @JsonKey(name: 'date_of_birth') required String dateOfBirth,
    required String country,
    @Default('') String province,
    @Default('') String city,
    @Default('') String address,
    @JsonKey(name: 'employment_status') required String employmentStatus,
    String? employer,
    String? industry,
    @JsonKey(name: 'kyc_tier') required int kycTier,
    @JsonKey(name: 'account_opened_at') required String accountOpenedAt,
    @JsonKey(name: 'account_type') @Default('INDIVIDUAL') String accountType,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  const UserProfileModel._();

  UserProfile toDomain() => UserProfile(
        accountId: accountId,
        fullName: fullName,
        phone: phone,
        email: email,
        idNumber: idNumber,
        idType: idType,
        dateOfBirth: DateTime.parse(dateOfBirth).toUtc(),
        country: country,
        province: province,
        city: city,
        address: address,
        employmentStatus: _parseEmploymentStatus(employmentStatus),
        employer: employer,
        industry: industry,
        kycTier: kycTier >= 2 ? KycTier.tier2 : KycTier.tier1,
        accountOpenedAt: DateTime.parse(accountOpenedAt).toUtc(),
        accountType: accountType,
      );

  static EmploymentStatus _parseEmploymentStatus(String raw) =>
      switch (raw.toUpperCase()) {
        'SELF_EMPLOYED' => EmploymentStatus.selfEmployed,
        'UNEMPLOYED' => EmploymentStatus.unemployed,
        'RETIRED' => EmploymentStatus.retired,
        'STUDENT' => EmploymentStatus.student,
        'EMPLOYED' => EmploymentStatus.employed,
        final v => _unknownEmploymentStatus(v),
      };

  static EmploymentStatus _unknownEmploymentStatus(String v) {
    AppLogger.warning('Unknown employment_status: $v — defaulting to employed');
    return EmploymentStatus.employed;
  }
}
