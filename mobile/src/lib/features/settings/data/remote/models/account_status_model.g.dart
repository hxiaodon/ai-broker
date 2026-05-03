// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountStatusModel _$AccountStatusModelFromJson(Map<String, dynamic> json) =>
    _AccountStatusModel(
      kycStatus: json['kyc_status'] as String,
      amlStatus: json['aml_status'] as String,
      w8BenStatus: json['w8ben_status'] as String,
      w8BenExpiresAt: json['w8ben_expires_at'] as String?,
      withholdingTaxRate: json['withholding_tax_rate'] as String? ?? '30%',
      tradingEnabled: json['trading_enabled'] as bool? ?? true,
      withdrawalEnabled: json['withdrawal_enabled'] as bool? ?? true,
      depositEnabled: json['deposit_enabled'] as bool? ?? true,
      isLocked: json['is_locked'] as bool? ?? false,
    );

Map<String, dynamic> _$AccountStatusModelToJson(_AccountStatusModel instance) =>
    <String, dynamic>{
      'kyc_status': instance.kycStatus,
      'aml_status': instance.amlStatus,
      'w8ben_status': instance.w8BenStatus,
      'w8ben_expires_at': instance.w8BenExpiresAt,
      'withholding_tax_rate': instance.withholdingTaxRate,
      'trading_enabled': instance.tradingEnabled,
      'withdrawal_enabled': instance.withdrawalEnabled,
      'deposit_enabled': instance.depositEnabled,
      'is_locked': instance.isLocked,
    };
