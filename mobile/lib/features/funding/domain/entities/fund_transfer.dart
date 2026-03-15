import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_transfer.freezed.dart';
part 'fund_transfer.g.dart';

enum FundTransferType { deposit, withdrawal }
enum FundTransferStatus { pending, processing, completed, failed, cancelled }

/// Fund transfer record (deposit or withdrawal).
///
/// Per fund-transfer-compliance: amounts use [String] to avoid float precision.
/// All timestamps are UTC.
@freezed
class FundTransfer with _$FundTransfer {
  const factory FundTransfer({
    required String transferId,
    required FundTransferType type,
    required FundTransferStatus status,
    required String amount,           // Decimal string e.g. "1000.00"
    required String currency,         // 'USD' or 'HKD'
    required String bankAccountId,
    required DateTime createdAt,      // UTC
    DateTime? completedAt,            // UTC
    String? idempotencyKey,           // UUID v4
    String? failureReason,
    String? referenceNumber,          // Bank reference number
  }) = _FundTransfer;

  factory FundTransfer.fromJson(Map<String, dynamic> json) =>
      _$FundTransferFromJson(json);
}
