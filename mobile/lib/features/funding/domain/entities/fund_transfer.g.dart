// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FundTransferImpl _$$FundTransferImplFromJson(Map<String, dynamic> json) =>
    _$FundTransferImpl(
      transferId: json['transferId'] as String,
      type: $enumDecode(_$FundTransferTypeEnumMap, json['type']),
      status: $enumDecode(_$FundTransferStatusEnumMap, json['status']),
      amount: json['amount'] as String,
      currency: json['currency'] as String,
      bankAccountId: json['bankAccountId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] == null
              ? null
              : DateTime.parse(json['completedAt'] as String),
      idempotencyKey: json['idempotencyKey'] as String?,
      failureReason: json['failureReason'] as String?,
      referenceNumber: json['referenceNumber'] as String?,
    );

Map<String, dynamic> _$$FundTransferImplToJson(_$FundTransferImpl instance) =>
    <String, dynamic>{
      'transferId': instance.transferId,
      'type': _$FundTransferTypeEnumMap[instance.type]!,
      'status': _$FundTransferStatusEnumMap[instance.status]!,
      'amount': instance.amount,
      'currency': instance.currency,
      'bankAccountId': instance.bankAccountId,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'idempotencyKey': instance.idempotencyKey,
      'failureReason': instance.failureReason,
      'referenceNumber': instance.referenceNumber,
    };

const _$FundTransferTypeEnumMap = {
  FundTransferType.deposit: 'deposit',
  FundTransferType.withdrawal: 'withdrawal',
};

const _$FundTransferStatusEnumMap = {
  FundTransferStatus.pending: 'pending',
  FundTransferStatus.processing: 'processing',
  FundTransferStatus.completed: 'completed',
  FundTransferStatus.failed: 'failed',
  FundTransferStatus.cancelled: 'cancelled',
};
