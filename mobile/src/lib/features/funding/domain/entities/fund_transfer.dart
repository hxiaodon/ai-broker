import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_transfer.freezed.dart';

enum TransferType { deposit, withdrawal }

enum BankChannel { ach, wire }

enum TransferStatus {
  pending,
  complianceCheck,
  balanceCheck,
  settlementCheck,
  approval,
  bankProcessing,
  confirmed,
  ledgerUpdated,
  completed,
  failed,
  rejected,
}

extension TransferStatusDisplay on TransferStatus {
  String get userFacingLabel => switch (this) {
        TransferStatus.pending => '提交中',
        TransferStatus.complianceCheck => '提交中',
        TransferStatus.balanceCheck => '提交中',
        TransferStatus.settlementCheck => '提交中',
        TransferStatus.approval => '审核中',
        TransferStatus.bankProcessing => '处理中',
        TransferStatus.confirmed => '处理中',
        TransferStatus.ledgerUpdated => '处理中',
        TransferStatus.completed => '已到账',
        TransferStatus.failed => '已拒绝',
        TransferStatus.rejected => '已拒绝',
      };

  bool get isTerminal => this == TransferStatus.completed ||
      this == TransferStatus.failed ||
      this == TransferStatus.rejected;
}

@freezed
abstract class FundTransfer with _$FundTransfer {
  const factory FundTransfer({
    required String transferId,
    required String accountId,
    required TransferType type,
    required TransferStatus status,
    required Decimal amount,
    required String currency,
    required BankChannel channel,
    required String bankAccountId,
    /// Idempotency key echoed back by server
    required String requestId,
    @Default('') String failureReason,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) = _FundTransfer;
}
