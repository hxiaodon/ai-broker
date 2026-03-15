// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KycApplicationImpl _$$KycApplicationImplFromJson(Map<String, dynamic> json) =>
    _$KycApplicationImpl(
      applicationId: json['applicationId'] as String,
      status: $enumDecode(_$KycStatusEnumMap, json['status']),
      jurisdiction: $enumDecode(_$KycJurisdictionEnumMap, json['jurisdiction']),
      completedSteps: (json['completedSteps'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      submittedAt:
          json['submittedAt'] == null
              ? null
              : DateTime.parse(json['submittedAt'] as String),
      reviewedAt:
          json['reviewedAt'] == null
              ? null
              : DateTime.parse(json['reviewedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$$KycApplicationImplToJson(
  _$KycApplicationImpl instance,
) => <String, dynamic>{
  'applicationId': instance.applicationId,
  'status': _$KycStatusEnumMap[instance.status]!,
  'jurisdiction': _$KycJurisdictionEnumMap[instance.jurisdiction]!,
  'completedSteps': instance.completedSteps,
  'createdAt': instance.createdAt.toIso8601String(),
  'submittedAt': instance.submittedAt?.toIso8601String(),
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
  'rejectionReason': instance.rejectionReason,
};

const _$KycStatusEnumMap = {
  KycStatus.notStarted: 'notStarted',
  KycStatus.inProgress: 'inProgress',
  KycStatus.submitted: 'submitted',
  KycStatus.approved: 'approved',
  KycStatus.rejected: 'rejected',
};

const _$KycJurisdictionEnumMap = {
  KycJurisdiction.us: 'us',
  KycJurisdiction.hk: 'hk',
  KycJurisdiction.both: 'both',
};
