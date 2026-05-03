// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountStatusModel {

@JsonKey(name: 'kyc_status') String get kycStatus;@JsonKey(name: 'aml_status') String get amlStatus;@JsonKey(name: 'w8ben_status') String get w8BenStatus;@JsonKey(name: 'w8ben_expires_at') String? get w8BenExpiresAt;@JsonKey(name: 'withholding_tax_rate') String get withholdingTaxRate;@JsonKey(name: 'trading_enabled') bool get tradingEnabled;@JsonKey(name: 'withdrawal_enabled') bool get withdrawalEnabled;@JsonKey(name: 'deposit_enabled') bool get depositEnabled;@JsonKey(name: 'is_locked') bool get isLocked;
/// Create a copy of AccountStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountStatusModelCopyWith<AccountStatusModel> get copyWith => _$AccountStatusModelCopyWithImpl<AccountStatusModel>(this as AccountStatusModel, _$identity);

  /// Serializes this AccountStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountStatusModel&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.amlStatus, amlStatus) || other.amlStatus == amlStatus)&&(identical(other.w8BenStatus, w8BenStatus) || other.w8BenStatus == w8BenStatus)&&(identical(other.w8BenExpiresAt, w8BenExpiresAt) || other.w8BenExpiresAt == w8BenExpiresAt)&&(identical(other.withholdingTaxRate, withholdingTaxRate) || other.withholdingTaxRate == withholdingTaxRate)&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.withdrawalEnabled, withdrawalEnabled) || other.withdrawalEnabled == withdrawalEnabled)&&(identical(other.depositEnabled, depositEnabled) || other.depositEnabled == depositEnabled)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kycStatus,amlStatus,w8BenStatus,w8BenExpiresAt,withholdingTaxRate,tradingEnabled,withdrawalEnabled,depositEnabled,isLocked);

@override
String toString() {
  return 'AccountStatusModel(kycStatus: $kycStatus, amlStatus: $amlStatus, w8BenStatus: $w8BenStatus, w8BenExpiresAt: $w8BenExpiresAt, withholdingTaxRate: $withholdingTaxRate, tradingEnabled: $tradingEnabled, withdrawalEnabled: $withdrawalEnabled, depositEnabled: $depositEnabled, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class $AccountStatusModelCopyWith<$Res>  {
  factory $AccountStatusModelCopyWith(AccountStatusModel value, $Res Function(AccountStatusModel) _then) = _$AccountStatusModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'kyc_status') String kycStatus,@JsonKey(name: 'aml_status') String amlStatus,@JsonKey(name: 'w8ben_status') String w8BenStatus,@JsonKey(name: 'w8ben_expires_at') String? w8BenExpiresAt,@JsonKey(name: 'withholding_tax_rate') String withholdingTaxRate,@JsonKey(name: 'trading_enabled') bool tradingEnabled,@JsonKey(name: 'withdrawal_enabled') bool withdrawalEnabled,@JsonKey(name: 'deposit_enabled') bool depositEnabled,@JsonKey(name: 'is_locked') bool isLocked
});




}
/// @nodoc
class _$AccountStatusModelCopyWithImpl<$Res>
    implements $AccountStatusModelCopyWith<$Res> {
  _$AccountStatusModelCopyWithImpl(this._self, this._then);

  final AccountStatusModel _self;
  final $Res Function(AccountStatusModel) _then;

/// Create a copy of AccountStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kycStatus = null,Object? amlStatus = null,Object? w8BenStatus = null,Object? w8BenExpiresAt = freezed,Object? withholdingTaxRate = null,Object? tradingEnabled = null,Object? withdrawalEnabled = null,Object? depositEnabled = null,Object? isLocked = null,}) {
  return _then(_self.copyWith(
kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,amlStatus: null == amlStatus ? _self.amlStatus : amlStatus // ignore: cast_nullable_to_non_nullable
as String,w8BenStatus: null == w8BenStatus ? _self.w8BenStatus : w8BenStatus // ignore: cast_nullable_to_non_nullable
as String,w8BenExpiresAt: freezed == w8BenExpiresAt ? _self.w8BenExpiresAt : w8BenExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,withholdingTaxRate: null == withholdingTaxRate ? _self.withholdingTaxRate : withholdingTaxRate // ignore: cast_nullable_to_non_nullable
as String,tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,withdrawalEnabled: null == withdrawalEnabled ? _self.withdrawalEnabled : withdrawalEnabled // ignore: cast_nullable_to_non_nullable
as bool,depositEnabled: null == depositEnabled ? _self.depositEnabled : depositEnabled // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountStatusModel].
extension AccountStatusModelPatterns on AccountStatusModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountStatusModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _AccountStatusModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _AccountStatusModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'aml_status')  String amlStatus, @JsonKey(name: 'w8ben_status')  String w8BenStatus, @JsonKey(name: 'w8ben_expires_at')  String? w8BenExpiresAt, @JsonKey(name: 'withholding_tax_rate')  String withholdingTaxRate, @JsonKey(name: 'trading_enabled')  bool tradingEnabled, @JsonKey(name: 'withdrawal_enabled')  bool withdrawalEnabled, @JsonKey(name: 'deposit_enabled')  bool depositEnabled, @JsonKey(name: 'is_locked')  bool isLocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountStatusModel() when $default != null:
return $default(_that.kycStatus,_that.amlStatus,_that.w8BenStatus,_that.w8BenExpiresAt,_that.withholdingTaxRate,_that.tradingEnabled,_that.withdrawalEnabled,_that.depositEnabled,_that.isLocked);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'aml_status')  String amlStatus, @JsonKey(name: 'w8ben_status')  String w8BenStatus, @JsonKey(name: 'w8ben_expires_at')  String? w8BenExpiresAt, @JsonKey(name: 'withholding_tax_rate')  String withholdingTaxRate, @JsonKey(name: 'trading_enabled')  bool tradingEnabled, @JsonKey(name: 'withdrawal_enabled')  bool withdrawalEnabled, @JsonKey(name: 'deposit_enabled')  bool depositEnabled, @JsonKey(name: 'is_locked')  bool isLocked)  $default,) {final _that = this;
switch (_that) {
case _AccountStatusModel():
return $default(_that.kycStatus,_that.amlStatus,_that.w8BenStatus,_that.w8BenExpiresAt,_that.withholdingTaxRate,_that.tradingEnabled,_that.withdrawalEnabled,_that.depositEnabled,_that.isLocked);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'aml_status')  String amlStatus, @JsonKey(name: 'w8ben_status')  String w8BenStatus, @JsonKey(name: 'w8ben_expires_at')  String? w8BenExpiresAt, @JsonKey(name: 'withholding_tax_rate')  String withholdingTaxRate, @JsonKey(name: 'trading_enabled')  bool tradingEnabled, @JsonKey(name: 'withdrawal_enabled')  bool withdrawalEnabled, @JsonKey(name: 'deposit_enabled')  bool depositEnabled, @JsonKey(name: 'is_locked')  bool isLocked)?  $default,) {final _that = this;
switch (_that) {
case _AccountStatusModel() when $default != null:
return $default(_that.kycStatus,_that.amlStatus,_that.w8BenStatus,_that.w8BenExpiresAt,_that.withholdingTaxRate,_that.tradingEnabled,_that.withdrawalEnabled,_that.depositEnabled,_that.isLocked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountStatusModel extends AccountStatusModel {
  const _AccountStatusModel({@JsonKey(name: 'kyc_status') required this.kycStatus, @JsonKey(name: 'aml_status') required this.amlStatus, @JsonKey(name: 'w8ben_status') required this.w8BenStatus, @JsonKey(name: 'w8ben_expires_at') this.w8BenExpiresAt, @JsonKey(name: 'withholding_tax_rate') this.withholdingTaxRate = '30%', @JsonKey(name: 'trading_enabled') this.tradingEnabled = true, @JsonKey(name: 'withdrawal_enabled') this.withdrawalEnabled = true, @JsonKey(name: 'deposit_enabled') this.depositEnabled = true, @JsonKey(name: 'is_locked') this.isLocked = false}): super._();
  factory _AccountStatusModel.fromJson(Map<String, dynamic> json) => _$AccountStatusModelFromJson(json);

@override@JsonKey(name: 'kyc_status') final  String kycStatus;
@override@JsonKey(name: 'aml_status') final  String amlStatus;
@override@JsonKey(name: 'w8ben_status') final  String w8BenStatus;
@override@JsonKey(name: 'w8ben_expires_at') final  String? w8BenExpiresAt;
@override@JsonKey(name: 'withholding_tax_rate') final  String withholdingTaxRate;
@override@JsonKey(name: 'trading_enabled') final  bool tradingEnabled;
@override@JsonKey(name: 'withdrawal_enabled') final  bool withdrawalEnabled;
@override@JsonKey(name: 'deposit_enabled') final  bool depositEnabled;
@override@JsonKey(name: 'is_locked') final  bool isLocked;

/// Create a copy of AccountStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountStatusModelCopyWith<_AccountStatusModel> get copyWith => __$AccountStatusModelCopyWithImpl<_AccountStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountStatusModel&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.amlStatus, amlStatus) || other.amlStatus == amlStatus)&&(identical(other.w8BenStatus, w8BenStatus) || other.w8BenStatus == w8BenStatus)&&(identical(other.w8BenExpiresAt, w8BenExpiresAt) || other.w8BenExpiresAt == w8BenExpiresAt)&&(identical(other.withholdingTaxRate, withholdingTaxRate) || other.withholdingTaxRate == withholdingTaxRate)&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.withdrawalEnabled, withdrawalEnabled) || other.withdrawalEnabled == withdrawalEnabled)&&(identical(other.depositEnabled, depositEnabled) || other.depositEnabled == depositEnabled)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kycStatus,amlStatus,w8BenStatus,w8BenExpiresAt,withholdingTaxRate,tradingEnabled,withdrawalEnabled,depositEnabled,isLocked);

@override
String toString() {
  return 'AccountStatusModel(kycStatus: $kycStatus, amlStatus: $amlStatus, w8BenStatus: $w8BenStatus, w8BenExpiresAt: $w8BenExpiresAt, withholdingTaxRate: $withholdingTaxRate, tradingEnabled: $tradingEnabled, withdrawalEnabled: $withdrawalEnabled, depositEnabled: $depositEnabled, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class _$AccountStatusModelCopyWith<$Res> implements $AccountStatusModelCopyWith<$Res> {
  factory _$AccountStatusModelCopyWith(_AccountStatusModel value, $Res Function(_AccountStatusModel) _then) = __$AccountStatusModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'kyc_status') String kycStatus,@JsonKey(name: 'aml_status') String amlStatus,@JsonKey(name: 'w8ben_status') String w8BenStatus,@JsonKey(name: 'w8ben_expires_at') String? w8BenExpiresAt,@JsonKey(name: 'withholding_tax_rate') String withholdingTaxRate,@JsonKey(name: 'trading_enabled') bool tradingEnabled,@JsonKey(name: 'withdrawal_enabled') bool withdrawalEnabled,@JsonKey(name: 'deposit_enabled') bool depositEnabled,@JsonKey(name: 'is_locked') bool isLocked
});




}
/// @nodoc
class __$AccountStatusModelCopyWithImpl<$Res>
    implements _$AccountStatusModelCopyWith<$Res> {
  __$AccountStatusModelCopyWithImpl(this._self, this._then);

  final _AccountStatusModel _self;
  final $Res Function(_AccountStatusModel) _then;

/// Create a copy of AccountStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kycStatus = null,Object? amlStatus = null,Object? w8BenStatus = null,Object? w8BenExpiresAt = freezed,Object? withholdingTaxRate = null,Object? tradingEnabled = null,Object? withdrawalEnabled = null,Object? depositEnabled = null,Object? isLocked = null,}) {
  return _then(_AccountStatusModel(
kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,amlStatus: null == amlStatus ? _self.amlStatus : amlStatus // ignore: cast_nullable_to_non_nullable
as String,w8BenStatus: null == w8BenStatus ? _self.w8BenStatus : w8BenStatus // ignore: cast_nullable_to_non_nullable
as String,w8BenExpiresAt: freezed == w8BenExpiresAt ? _self.w8BenExpiresAt : w8BenExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,withholdingTaxRate: null == withholdingTaxRate ? _self.withholdingTaxRate : withholdingTaxRate // ignore: cast_nullable_to_non_nullable
as String,tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,withdrawalEnabled: null == withdrawalEnabled ? _self.withdrawalEnabled : withdrawalEnabled // ignore: cast_nullable_to_non_nullable
as bool,depositEnabled: null == depositEnabled ? _self.depositEnabled : depositEnabled // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
