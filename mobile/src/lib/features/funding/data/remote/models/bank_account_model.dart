import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_account_model.freezed.dart';
part 'bank_account_model.g.dart';

@freezed
abstract class BankAccountModel with _$BankAccountModel {
  const factory BankAccountModel({
    @JsonKey(name: 'bank_account_id') required String id,
    @JsonKey(name: 'account_name') required String accountName,
    /// Server returns last-4-digit masked value (e.g. "****1234")
    @JsonKey(name: 'account_number') required String accountNumberMasked,
    @JsonKey(name: 'routing_number') @Default('') String routingNumber,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'currency') @Default('USD') String currency,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'cooldown_ends_at') String? cooldownEndsAt,
    @JsonKey(name: 'micro_deposit_status') @Default('pending') String microDepositStatus,
    @JsonKey(name: 'remaining_verify_attempts') @Default(5) int remainingVerifyAttempts,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _BankAccountModel;

  factory BankAccountModel.fromJson(Map<String, dynamic> json) =>
      _$BankAccountModelFromJson(json);
}
