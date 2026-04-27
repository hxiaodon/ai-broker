import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_transfer_model.freezed.dart';
part 'fund_transfer_model.g.dart';

@freezed
abstract class FundTransferModel with _$FundTransferModel {
  const factory FundTransferModel({
    @JsonKey(name: 'transfer_id') required String transferId,
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'amount') required String amount,
    @JsonKey(name: 'currency') @Default('USD') String currency,
    @JsonKey(name: 'channel') required String channel,
    @JsonKey(name: 'bank_account_id') required String bankAccountId,
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'failure_reason') @Default('') String failureReason,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
  }) = _FundTransferModel;

  factory FundTransferModel.fromJson(Map<String, dynamic> json) =>
      _$FundTransferModelFromJson(json);
}
