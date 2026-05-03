// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    _UserProfileModel(
      accountId: json['account_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      idNumber: json['id_number'] as String,
      idType: json['id_type'] as String,
      dateOfBirth: json['date_of_birth'] as String,
      country: json['country'] as String,
      province: json['province'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      employmentStatus: json['employment_status'] as String,
      employer: json['employer'] as String?,
      industry: json['industry'] as String?,
      kycTier: (json['kyc_tier'] as num).toInt(),
      accountOpenedAt: json['account_opened_at'] as String,
      accountType: json['account_type'] as String? ?? 'INDIVIDUAL',
    );

Map<String, dynamic> _$UserProfileModelToJson(_UserProfileModel instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'email': instance.email,
      'id_number': instance.idNumber,
      'id_type': instance.idType,
      'date_of_birth': instance.dateOfBirth,
      'country': instance.country,
      'province': instance.province,
      'city': instance.city,
      'address': instance.address,
      'employment_status': instance.employmentStatus,
      'employer': instance.employer,
      'industry': instance.industry,
      'kyc_tier': instance.kycTier,
      'account_opened_at': instance.accountOpenedAt,
      'account_type': instance.accountType,
    };
