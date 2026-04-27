// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BankAccountModel _$BankAccountModelFromJson(Map<String, dynamic> json) =>
    _BankAccountModel(
      id: json['bank_account_id'] as String,
      accountName: json['account_name'] as String,
      accountNumberMasked: json['account_number'] as String,
      routingNumber: json['routing_number'] as String? ?? '',
      bankName: json['bank_name'] as String,
      currency: json['currency'] as String? ?? 'USD',
      isVerified: json['is_verified'] as bool? ?? false,
      cooldownEndsAt: json['cooldown_ends_at'] as String?,
      microDepositStatus: json['micro_deposit_status'] as String? ?? 'pending',
      remainingVerifyAttempts:
          (json['remaining_verify_attempts'] as num?)?.toInt() ?? 5,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$BankAccountModelToJson(_BankAccountModel instance) =>
    <String, dynamic>{
      'bank_account_id': instance.id,
      'account_name': instance.accountName,
      'account_number': instance.accountNumberMasked,
      'routing_number': instance.routingNumber,
      'bank_name': instance.bankName,
      'currency': instance.currency,
      'is_verified': instance.isVerified,
      'cooldown_ends_at': instance.cooldownEndsAt,
      'micro_deposit_status': instance.microDepositStatus,
      'remaining_verify_attempts': instance.remainingVerifyAttempts,
      'created_at': instance.createdAt,
    };
