import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_status.freezed.dart';

enum KycStatus { pending, approved, rejected, suspended }

enum AmlStatus { clear, review, flagged }

enum W8BenStatus { notSigned, valid, expiringSoon, expired }

/// Account compliance status from GET /v1/profile/account-status.
@freezed
abstract class AccountStatus with _$AccountStatus {
  const factory AccountStatus({
    required KycStatus kycStatus,
    required AmlStatus amlStatus,
    required W8BenStatus w8BenStatus,
    /// Null when not signed or expired
    DateTime? w8BenExpiresAt,
    /// Applicable withholding tax rate (10% treaty or 30% default)
    required String withholdingTaxRate,
    required bool tradingEnabled,
    required bool withdrawalEnabled,
    required bool depositEnabled,
    /// True when account is locked via emergency freeze
    @Default(false) bool isLocked,
  }) = _AccountStatus;

  const AccountStatus._();

  bool get isW8BenExpiringSoon {
    final exp = w8BenExpiresAt;
    if (exp == null) return false;
    final daysLeft = exp.difference(DateTime.now().toUtc()).inDays;
    return daysLeft <= 90 && daysLeft > 0;
  }

  bool get isW8BenExpired {
    final exp = w8BenExpiresAt;
    if (exp == null) return w8BenStatus == W8BenStatus.expired;
    return DateTime.now().toUtc().isAfter(exp);
  }
}
