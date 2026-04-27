import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_balance.freezed.dart';

@freezed
abstract class AccountBalance with _$AccountBalance {
  const factory AccountBalance({
    required String accountId,
    required String currency,
    /// Total assets = availableBalance + unsettledAmount + position market value
    required Decimal totalBalance,
    /// Cash available for trading or withdrawal (unfrozen)
    required Decimal availableBalance,
    /// Unsettled proceeds from sold securities (US T+1, HK T+2 — not withdrawable)
    required Decimal unsettledAmount,
    /// available_balance minus frozen pending withdrawals; computed by Fund Transfer service
    required Decimal withdrawableBalance,
    required DateTime updatedAt,
  }) = _AccountBalance;
}
