// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_transfer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FundTransferModel _$FundTransferModelFromJson(Map<String, dynamic> json) =>
    _FundTransferModel(
      transferId: json['transfer_id'] as String,
      accountId: json['account_id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      amount: json['amount'] as String,
      currency: json['currency'] as String? ?? 'USD',
      channel: json['channel'] as String,
      bankAccountId: json['bank_account_id'] as String,
      requestId: json['request_id'] as String,
      failureReason: json['failure_reason'] as String? ?? '',
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      completedAt: json['completed_at'] as String?,
    );

Map<String, dynamic> _$FundTransferModelToJson(_FundTransferModel instance) =>
    <String, dynamic>{
      'transfer_id': instance.transferId,
      'account_id': instance.accountId,
      'type': instance.type,
      'status': instance.status,
      'amount': instance.amount,
      'currency': instance.currency,
      'channel': instance.channel,
      'bank_account_id': instance.bankAccountId,
      'request_id': instance.requestId,
      'failure_reason': instance.failureReason,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'completed_at': instance.completedAt,
    };
