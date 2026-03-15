// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPreferencesImpl _$$UserPreferencesImplFromJson(
  Map<String, dynamic> json,
) => _$UserPreferencesImpl(
  colorScheme:
      $enumDecodeNullable(_$TradingColorSchemeEnumMap, json['colorScheme']) ??
      TradingColorScheme.greenUp,
  language: json['language'] as String? ?? 'zh',
  biometricEnabled: json['biometricEnabled'] as bool? ?? true,
  orderFillNotifications: json['orderFillNotifications'] as bool? ?? true,
  fundTransferNotifications: json['fundTransferNotifications'] as bool? ?? true,
  priceAlertNotifications: json['priceAlertNotifications'] as bool? ?? true,
  defaultCurrency: json['defaultCurrency'] as String? ?? 'USD',
);

Map<String, dynamic> _$$UserPreferencesImplToJson(
  _$UserPreferencesImpl instance,
) => <String, dynamic>{
  'colorScheme': _$TradingColorSchemeEnumMap[instance.colorScheme]!,
  'language': instance.language,
  'biometricEnabled': instance.biometricEnabled,
  'orderFillNotifications': instance.orderFillNotifications,
  'fundTransferNotifications': instance.fundTransferNotifications,
  'priceAlertNotifications': instance.priceAlertNotifications,
  'defaultCurrency': instance.defaultCurrency,
};

const _$TradingColorSchemeEnumMap = {
  TradingColorScheme.greenUp: 'greenUp',
  TradingColorScheme.redUp: 'redUp',
};
