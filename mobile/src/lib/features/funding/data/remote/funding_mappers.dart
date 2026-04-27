import 'package:decimal/decimal.dart';

import '../../domain/entities/account_balance.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/fund_transfer.dart';
import 'models/account_balance_model.dart';
import 'models/bank_account_model.dart';
import 'models/fund_transfer_model.dart';

// ─── Safe parse helpers ───────────────────────────────────────────────────────

Decimal _parseDecimal(String? raw, String field) {
  if (raw == null || raw.isEmpty) {
    throw FormatException('Missing required field: $field');
  }
  return Decimal.tryParse(raw) ??
      (throw FormatException('Invalid decimal for $field: "$raw"'));
}

DateTime _parseUtcDateTime(String? raw, String field) {
  if (raw == null || raw.isEmpty) {
    throw FormatException('Missing required field: $field');
  }
  try {
    return DateTime.parse(raw).toUtc();
  } catch (_) {
    throw FormatException('Invalid datetime for $field: "$raw"');
  }
}

TransferType _parseTransferType(String raw) => switch (raw.toUpperCase()) {
      'DEPOSIT' => TransferType.deposit,
      'WITHDRAWAL' => TransferType.withdrawal,
      _ => throw FormatException('Unknown transfer type: "$raw"'),
    };

TransferStatus _parseTransferStatus(String raw) =>
    switch (raw.toUpperCase()) {
      'TRANSFER_STATUS_PENDING' || 'PENDING' => TransferStatus.pending,
      'TRANSFER_STATUS_COMPLIANCE_CHECK' ||
      'COMPLIANCE_CHECK' =>
        TransferStatus.complianceCheck,
      'TRANSFER_STATUS_BALANCE_CHECK' ||
      'BALANCE_CHECK' =>
        TransferStatus.balanceCheck,
      'TRANSFER_STATUS_SETTLEMENT_CHECK' ||
      'SETTLEMENT_CHECK' =>
        TransferStatus.settlementCheck,
      'TRANSFER_STATUS_APPROVAL' || 'APPROVAL' => TransferStatus.approval,
      'TRANSFER_STATUS_BANK_PROCESSING' ||
      'BANK_PROCESSING' =>
        TransferStatus.bankProcessing,
      'TRANSFER_STATUS_CONFIRMED' || 'CONFIRMED' => TransferStatus.confirmed,
      'TRANSFER_STATUS_LEDGER_UPDATED' ||
      'LEDGER_UPDATED' =>
        TransferStatus.ledgerUpdated,
      'TRANSFER_STATUS_COMPLETED' || 'COMPLETED' => TransferStatus.completed,
      'TRANSFER_STATUS_FAILED' || 'FAILED' => TransferStatus.failed,
      'TRANSFER_STATUS_REJECTED' || 'REJECTED' => TransferStatus.rejected,
      _ => TransferStatus.pending,
    };

BankChannel _parseBankChannel(String raw) => switch (raw.toUpperCase()) {
      'ACH' => BankChannel.ach,
      'WIRE' => BankChannel.wire,
      _ => BankChannel.ach,
    };

MicroDepositStatus _parseMicroDepositStatus(String raw) =>
    switch (raw.toLowerCase()) {
      'verified' => MicroDepositStatus.verified,
      'verifying' => MicroDepositStatus.verifying,
      'failed' => MicroDepositStatus.failed,
      _ => MicroDepositStatus.pending,
    };

// ─── Mappers ──────────────────────────────────────────────────────────────────

extension AccountBalanceModelMapper on AccountBalanceModel {
  AccountBalance toDomain() => AccountBalance(
        accountId: accountId,
        currency: currency,
        totalBalance: _parseDecimal(totalBalance, 'total_balance'),
        availableBalance: _parseDecimal(availableBalance, 'available_balance'),
        unsettledAmount: _parseDecimal(unsettledAmount, 'unsettled_amount'),
        withdrawableBalance:
            _parseDecimal(withdrawableBalance, 'withdrawable_balance'),
        updatedAt: _parseUtcDateTime(updatedAt, 'updated_at'),
      );
}

extension BankAccountModelMapper on BankAccountModel {
  BankAccount toDomain() => BankAccount(
        id: id,
        accountName: accountName,
        accountNumberMasked: accountNumberMasked,
        routingNumber: routingNumber,
        bankName: bankName,
        currency: currency,
        isVerified: isVerified,
        cooldownEndsAt: cooldownEndsAt != null
            ? _parseUtcDateTime(cooldownEndsAt, 'cooldown_ends_at')
            : null,
        microDepositStatus: _parseMicroDepositStatus(microDepositStatus),
        remainingVerifyAttempts: remainingVerifyAttempts,
        createdAt: _parseUtcDateTime(createdAt, 'created_at'),
      );
}

extension FundTransferModelMapper on FundTransferModel {
  FundTransfer toDomain() => FundTransfer(
        transferId: transferId,
        accountId: accountId,
        type: _parseTransferType(type),
        status: _parseTransferStatus(status),
        amount: _parseDecimal(amount, 'amount'),
        currency: currency,
        channel: _parseBankChannel(channel),
        bankAccountId: bankAccountId,
        requestId: requestId,
        failureReason: failureReason,
        createdAt: _parseUtcDateTime(createdAt, 'created_at'),
        updatedAt: _parseUtcDateTime(updatedAt, 'updated_at'),
        completedAt: completedAt != null
            ? _parseUtcDateTime(completedAt, 'completed_at')
            : null,
      );
}
