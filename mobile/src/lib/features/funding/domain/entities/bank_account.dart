import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_account.freezed.dart';

enum MicroDepositStatus { pending, verifying, verified, failed }

@freezed
abstract class BankAccount with _$BankAccount {
  const factory BankAccount({
    required String id,
    required String accountName,
    /// Server-masked to last 4 digits (e.g. "****1234")
    required String accountNumberMasked,
    required String routingNumber,
    required String bankName,
    required String currency,
    required bool isVerified,
    /// Null when not in cooldown; set after micro-deposit verification passes
    DateTime? cooldownEndsAt,
    required MicroDepositStatus microDepositStatus,
    /// Remaining verification attempts (max 5 per PRD § 4.1)
    @Default(5) int remainingVerifyAttempts,
    required DateTime createdAt,
  }) = _BankAccount;

  const BankAccount._();

  bool get isInCooldown {
    final end = cooldownEndsAt;
    return end != null && DateTime.now().toUtc().isBefore(end);
  }

  bool get isUsable => isVerified && !isInCooldown;
}
