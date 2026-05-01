import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/logging/app_logger.dart';

part 'kyc_session.freezed.dart';

enum KycStatus {
  notStarted,
  inProgress,
  submitted,
  pendingReview,
  needsMoreInfo,
  approved,
  rejected,
  expired;

  static KycStatus fromApi(String value) => switch (value) {
        'NOT_STARTED' => notStarted,
        'IN_PROGRESS' => inProgress,
        'SUBMITTED' => submitted,
        'PENDING_REVIEW' || 'PENDING' || 'REVIEWING' => pendingReview,
        'NEEDS_MORE_INFO' => needsMoreInfo,
        'APPROVED' => approved,
        'REJECTED' => rejected,
        'EXPIRED' => expired,
        _ => () {
            AppLogger.warning('[KycStatus] Unknown status from API — defaulting to pendingReview');
            return pendingReview;
          }(),
      };

  bool get isTerminal =>
      this == approved || this == rejected || this == expired;

  bool get isPolling =>
      this == submitted || this == pendingReview;
}

@freezed
abstract class KycSession with _$KycSession {
  const factory KycSession({
    required String sessionId,
    required int currentStep,
    required KycStatus status,
    required DateTime expiresAt,
    int? estimatedTimeMinutes,
    String? rejectionReason,
    int? needsMoreInfoStep,
    /// 用户在 Step 1 填写的英文全名（"FirstName LastName"），用于 Step 8 签名比对。
    String? accountHolderName,
  }) = _KycSession;
}
