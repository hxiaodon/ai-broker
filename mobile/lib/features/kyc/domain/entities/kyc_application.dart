import 'package:freezed_annotation/freezed_annotation.dart';

part 'kyc_application.freezed.dart';
part 'kyc_application.g.dart';

enum KycStatus { notStarted, inProgress, submitted, approved, rejected }
enum KycJurisdiction { us, hk, both }

/// KYC application state.
///
/// Tracks multi-step KYC form progress (7 steps per PRD-02).
@freezed
class KycApplication with _$KycApplication {
  const factory KycApplication({
    required String applicationId,
    required KycStatus status,
    required KycJurisdiction jurisdiction,
    required int completedSteps,   // 0-7
    required DateTime createdAt,   // UTC
    DateTime? submittedAt,         // UTC
    DateTime? reviewedAt,          // UTC
    String? rejectionReason,
  }) = _KycApplication;

  factory KycApplication.fromJson(Map<String, dynamic> json) =>
      _$KycApplicationFromJson(json);
}
