import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_balance_model.freezed.dart';
part 'account_balance_model.g.dart';

@freezed
abstract class AccountBalanceModel with _$AccountBalanceModel {
  const factory AccountBalanceModel({
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'currency') @Default('USD') String currency,
    @JsonKey(name: 'total_balance') required String totalBalance,
    @JsonKey(name: 'available_balance') required String availableBalance,
    @JsonKey(name: 'unsettled_amount') @Default('0') String unsettledAmount,
    @JsonKey(name: 'withdrawable_balance') required String withdrawableBalance,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _AccountBalanceModel;

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$AccountBalanceModelFromJson(json);
}
