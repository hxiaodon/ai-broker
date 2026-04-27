// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_balance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountBalanceModel _$AccountBalanceModelFromJson(Map<String, dynamic> json) =>
    _AccountBalanceModel(
      accountId: json['account_id'] as String,
      currency: json['currency'] as String? ?? 'USD',
      totalBalance: json['total_balance'] as String,
      availableBalance: json['available_balance'] as String,
      unsettledAmount: json['unsettled_amount'] as String? ?? '0',
      withdrawableBalance: json['withdrawable_balance'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$AccountBalanceModelToJson(
  _AccountBalanceModel instance,
) => <String, dynamic>{
  'account_id': instance.accountId,
  'currency': instance.currency,
  'total_balance': instance.totalBalance,
  'available_balance': instance.availableBalance,
  'unsettled_amount': instance.unsettledAmount,
  'withdrawable_balance': instance.withdrawableBalance,
  'updated_at': instance.updatedAt,
};
