import 'package:freezed_annotation/freezed_annotation.dart';

part 'kyc_models.freezed.dart';
part 'kyc_models.g.dart';

@freezed
abstract class KycSessionModel with _$KycSessionModel {
  const factory KycSessionModel({
    @JsonKey(name: 'kyc_session_id') required String kycSessionId,
    @JsonKey(name: 'current_step') @Default(1) int currentStep,
    @JsonKey(name: 'kyc_status') @Default('IN_PROGRESS') String kycStatus,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'estimated_time_minutes') int? estimatedTimeMinutes,
    @JsonKey(name: 'reason_if_rejected') String? reasonIfRejected,
    @JsonKey(name: 'needs_more_info_step') int? needsMoreInfoStep,
    @JsonKey(name: 'account_id') String? accountId,
    @JsonKey(name: 'estimated_review_time_hours') int? estimatedReviewTimeHours,
  }) = _KycSessionModel;

  factory KycSessionModel.fromJson(Map<String, dynamic> json) =>
      _$KycSessionModelFromJson(json);
}

@freezed
abstract class SumsubTokenModel with _$SumsubTokenModel {
  const factory SumsubTokenModel({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'applicant_id') required String applicantId,
    @Default(600) int ttl,
  }) = _SumsubTokenModel;

  factory SumsubTokenModel.fromJson(Map<String, dynamic> json) =>
      _$SumsubTokenModelFromJson(json);
}

@freezed
abstract class UploadUrlModel with _$UploadUrlModel {
  const factory UploadUrlModel({
    @JsonKey(name: 'upload_url') required String uploadUrl,
    @JsonKey(name: 'document_id') required String documentId,
    @Default(3600) int expiry,
    @JsonKey(name: 'checksum_algorithm')
    @Default('SHA256')
    String checksumAlgorithm,
  }) = _UploadUrlModel;

  factory UploadUrlModel.fromJson(Map<String, dynamic> json) =>
      _$UploadUrlModelFromJson(json);
}

@freezed
abstract class DocumentUploadModel with _$DocumentUploadModel {
  const factory DocumentUploadModel({
    @JsonKey(name: 'document_id') required String documentId,
    @Default('UPLOADING') String status,
    @JsonKey(name: 'sumsub_applicant_id') String? sumsubApplicantId,
  }) = _DocumentUploadModel;

  factory DocumentUploadModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentUploadModelFromJson(json);
}
