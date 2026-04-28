// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KycSessionModel _$KycSessionModelFromJson(Map<String, dynamic> json) =>
    _KycSessionModel(
      kycSessionId: json['kyc_session_id'] as String,
      currentStep: (json['current_step'] as num?)?.toInt() ?? 1,
      kycStatus: json['kyc_status'] as String? ?? 'IN_PROGRESS',
      expiresAt: json['expires_at'] as String?,
      estimatedTimeMinutes: (json['estimated_time_minutes'] as num?)?.toInt(),
      reasonIfRejected: json['reason_if_rejected'] as String?,
      needsMoreInfoStep: (json['needs_more_info_step'] as num?)?.toInt(),
      accountId: json['account_id'] as String?,
      estimatedReviewTimeHours: (json['estimated_review_time_hours'] as num?)
          ?.toInt(),
    );

Map<String, dynamic> _$KycSessionModelToJson(_KycSessionModel instance) =>
    <String, dynamic>{
      'kyc_session_id': instance.kycSessionId,
      'current_step': instance.currentStep,
      'kyc_status': instance.kycStatus,
      'expires_at': instance.expiresAt,
      'estimated_time_minutes': instance.estimatedTimeMinutes,
      'reason_if_rejected': instance.reasonIfRejected,
      'needs_more_info_step': instance.needsMoreInfoStep,
      'account_id': instance.accountId,
      'estimated_review_time_hours': instance.estimatedReviewTimeHours,
    };

_SumsubTokenModel _$SumsubTokenModelFromJson(Map<String, dynamic> json) =>
    _SumsubTokenModel(
      accessToken: json['access_token'] as String,
      applicantId: json['applicant_id'] as String,
      ttl: (json['ttl'] as num?)?.toInt() ?? 600,
    );

Map<String, dynamic> _$SumsubTokenModelToJson(_SumsubTokenModel instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'applicant_id': instance.applicantId,
      'ttl': instance.ttl,
    };

_UploadUrlModel _$UploadUrlModelFromJson(Map<String, dynamic> json) =>
    _UploadUrlModel(
      uploadUrl: json['upload_url'] as String,
      documentId: json['document_id'] as String,
      expiry: (json['expiry'] as num?)?.toInt() ?? 3600,
      checksumAlgorithm: json['checksum_algorithm'] as String? ?? 'SHA256',
    );

Map<String, dynamic> _$UploadUrlModelToJson(_UploadUrlModel instance) =>
    <String, dynamic>{
      'upload_url': instance.uploadUrl,
      'document_id': instance.documentId,
      'expiry': instance.expiry,
      'checksum_algorithm': instance.checksumAlgorithm,
    };

_DocumentUploadModel _$DocumentUploadModelFromJson(Map<String, dynamic> json) =>
    _DocumentUploadModel(
      documentId: json['document_id'] as String,
      status: json['status'] as String? ?? 'UPLOADING',
      sumsubApplicantId: json['sumsub_applicant_id'] as String?,
    );

Map<String, dynamic> _$DocumentUploadModelToJson(
  _DocumentUploadModel instance,
) => <String, dynamic>{
  'document_id': instance.documentId,
  'status': instance.status,
  'sumsub_applicant_id': instance.sumsubApplicantId,
};
