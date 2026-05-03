// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountStatus {

 KycStatus get kycStatus; AmlStatus get amlStatus; W8BenStatus get w8BenStatus;/// Null when not signed or expired
 DateTime? get w8BenExpiresAt;/// Applicable withholding tax rate (10% treaty or 30% default)
 String get withholdingTaxRate; bool get tradingEnabled; bool get withdrawalEnabled; bool get depositEnabled;/// True when account is locked via emergency freeze
 bool get isLocked;
/// Create a copy of AccountStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountStatusCopyWith<AccountStatus> get copyWith => _$AccountStatusCopyWithImpl<AccountStatus>(this as AccountStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountStatus&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.amlStatus, amlStatus) || other.amlStatus == amlStatus)&&(identical(other.w8BenStatus, w8BenStatus) || other.w8BenStatus == w8BenStatus)&&(identical(other.w8BenExpiresAt, w8BenExpiresAt) || other.w8BenExpiresAt == w8BenExpiresAt)&&(identical(other.withholdingTaxRate, withholdingTaxRate) || other.withholdingTaxRate == withholdingTaxRate)&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.withdrawalEnabled, withdrawalEnabled) || other.withdrawalEnabled == withdrawalEnabled)&&(identical(other.depositEnabled, depositEnabled) || other.depositEnabled == depositEnabled)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}


@override
int get hashCode => Object.hash(runtimeType,kycStatus,amlStatus,w8BenStatus,w8BenExpiresAt,withholdingTaxRate,tradingEnabled,withdrawalEnabled,depositEnabled,isLocked);

@override
String toString() {
  return 'AccountStatus(kycStatus: $kycStatus, amlStatus: $amlStatus, w8BenStatus: $w8BenStatus, w8BenExpiresAt: $w8BenExpiresAt, withholdingTaxRate: $withholdingTaxRate, tradingEnabled: $tradingEnabled, withdrawalEnabled: $withdrawalEnabled, depositEnabled: $depositEnabled, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class $AccountStatusCopyWith<$Res>  {
  factory $AccountStatusCopyWith(AccountStatus value, $Res Function(AccountStatus) _then) = _$AccountStatusCopyWithImpl;
@useResult
$Res call({
 KycStatus kycStatus, AmlStatus amlStatus, W8BenStatus w8BenStatus, DateTime? w8BenExpiresAt, String withholdingTaxRate, bool tradingEnabled, bool withdrawalEnabled, bool depositEnabled, bool isLocked
});




}
/// @nodoc
class _$AccountStatusCopyWithImpl<$Res>
    implements $AccountStatusCopyWith<$Res> {
  _$AccountStatusCopyWithImpl(this._self, this._then);

  final AccountStatus _self;
  final $Res Function(AccountStatus) _then;

/// Create a copy of AccountStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kycStatus = null,Object? amlStatus = null,Object? w8BenStatus = null,Object? w8BenExpiresAt = freezed,Object? withholdingTaxRate = null,Object? tradingEnabled = null,Object? withdrawalEnabled = null,Object? depositEnabled = null,Object? isLocked = null,}) {
  return _then(_self.copyWith(
kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as KycStatus,amlStatus: null == amlStatus ? _self.amlStatus : amlStatus // ignore: cast_nullable_to_non_nullable
as AmlStatus,w8BenStatus: null == w8BenStatus ? _self.w8BenStatus : w8BenStatus // ignore: cast_nullable_to_non_nullable
as W8BenStatus,w8BenExpiresAt: freezed == w8BenExpiresAt ? _self.w8BenExpiresAt : w8BenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,withholdingTaxRate: null == withholdingTaxRate ? _self.withholdingTaxRate : withholdingTaxRate // ignore: cast_nullable_to_non_nullable
as String,tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,withdrawalEnabled: null == withdrawalEnabled ? _self.withdrawalEnabled : withdrawalEnabled // ignore: cast_nullable_to_non_nullable
as bool,depositEnabled: null == depositEnabled ? _self.depositEnabled : depositEnabled // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountStatus].
extension AccountStatusPatterns on AccountStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountStatus value)  $default,){
final _that = this;
switch (_that) {
case _AccountStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AccountStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( KycStatus kycStatus,  AmlStatus amlStatus,  W8BenStatus w8BenStatus,  DateTime? w8BenExpiresAt,  String withholdingTaxRate,  bool tradingEnabled,  bool withdrawalEnabled,  bool depositEnabled,  bool isLocked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountStatus() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( KycStatus kycStatus,  AmlStatus amlStatus,  W8BenStatus w8BenStatus,  DateTime? w8BenExpiresAt,  String withholdingTaxRate,  bool tradingEnabled,  bool withdrawalEnabled,  bool depositEnabled,  bool isLocked)  $default,) {final _that = this;
switch (_that) {
case _AccountStatus():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( KycStatus kycStatus,  AmlStatus amlStatus,  W8BenStatus w8BenStatus,  DateTime? w8BenExpiresAt,  String withholdingTaxRate,  bool tradingEnabled,  bool withdrawalEnabled,  bool depositEnabled,  bool isLocked)?  $default,) {final _that = this;
switch (_that) {
case _AccountStatus() when $default != null:
return $default(_that.kycStatus,_that.amlStatus,_that.w8BenStatus,_that.w8BenExpiresAt,_that.withholdingTaxRate,_that.tradingEnabled,_that.withdrawalEnabled,_that.depositEnabled,_that.isLocked);case _:
  return null;

}
}

}

/// @nodoc


class _AccountStatus extends AccountStatus {
  const _AccountStatus({required this.kycStatus, required this.amlStatus, required this.w8BenStatus, this.w8BenExpiresAt, required this.withholdingTaxRate, required this.tradingEnabled, required this.withdrawalEnabled, required this.depositEnabled, this.isLocked = false}): super._();
  

@override final  KycStatus kycStatus;
@override final  AmlStatus amlStatus;
@override final  W8BenStatus w8BenStatus;
/// Null when not signed or expired
@override final  DateTime? w8BenExpiresAt;
/// Applicable withholding tax rate (10% treaty or 30% default)
@override final  String withholdingTaxRate;
@override final  bool tradingEnabled;
@override final  bool withdrawalEnabled;
@override final  bool depositEnabled;
/// True when account is locked via emergency freeze
@override@JsonKey() final  bool isLocked;

/// Create a copy of AccountStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountStatusCopyWith<_AccountStatus> get copyWith => __$AccountStatusCopyWithImpl<_AccountStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountStatus&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.amlStatus, amlStatus) || other.amlStatus == amlStatus)&&(identical(other.w8BenStatus, w8BenStatus) || other.w8BenStatus == w8BenStatus)&&(identical(other.w8BenExpiresAt, w8BenExpiresAt) || other.w8BenExpiresAt == w8BenExpiresAt)&&(identical(other.withholdingTaxRate, withholdingTaxRate) || other.withholdingTaxRate == withholdingTaxRate)&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.withdrawalEnabled, withdrawalEnabled) || other.withdrawalEnabled == withdrawalEnabled)&&(identical(other.depositEnabled, depositEnabled) || other.depositEnabled == depositEnabled)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked));
}


@override
int get hashCode => Object.hash(runtimeType,kycStatus,amlStatus,w8BenStatus,w8BenExpiresAt,withholdingTaxRate,tradingEnabled,withdrawalEnabled,depositEnabled,isLocked);

@override
String toString() {
  return 'AccountStatus(kycStatus: $kycStatus, amlStatus: $amlStatus, w8BenStatus: $w8BenStatus, w8BenExpiresAt: $w8BenExpiresAt, withholdingTaxRate: $withholdingTaxRate, tradingEnabled: $tradingEnabled, withdrawalEnabled: $withdrawalEnabled, depositEnabled: $depositEnabled, isLocked: $isLocked)';
}


}

/// @nodoc
abstract mixin class _$AccountStatusCopyWith<$Res> implements $AccountStatusCopyWith<$Res> {
  factory _$AccountStatusCopyWith(_AccountStatus value, $Res Function(_AccountStatus) _then) = __$AccountStatusCopyWithImpl;
@override @useResult
$Res call({
 KycStatus kycStatus, AmlStatus amlStatus, W8BenStatus w8BenStatus, DateTime? w8BenExpiresAt, String withholdingTaxRate, bool tradingEnabled, bool withdrawalEnabled, bool depositEnabled, bool isLocked
});




}
/// @nodoc
class __$AccountStatusCopyWithImpl<$Res>
    implements _$AccountStatusCopyWith<$Res> {
  __$AccountStatusCopyWithImpl(this._self, this._then);

  final _AccountStatus _self;
  final $Res Function(_AccountStatus) _then;

/// Create a copy of AccountStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kycStatus = null,Object? amlStatus = null,Object? w8BenStatus = null,Object? w8BenExpiresAt = freezed,Object? withholdingTaxRate = null,Object? tradingEnabled = null,Object? withdrawalEnabled = null,Object? depositEnabled = null,Object? isLocked = null,}) {
  return _then(_AccountStatus(
kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as KycStatus,amlStatus: null == amlStatus ? _self.amlStatus : amlStatus // ignore: cast_nullable_to_non_nullable
as AmlStatus,w8BenStatus: null == w8BenStatus ? _self.w8BenStatus : w8BenStatus // ignore: cast_nullable_to_non_nullable
as W8BenStatus,w8BenExpiresAt: freezed == w8BenExpiresAt ? _self.w8BenExpiresAt : w8BenExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,withholdingTaxRate: null == withholdingTaxRate ? _self.withholdingTaxRate : withholdingTaxRate // ignore: cast_nullable_to_non_nullable
as String,tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,withdrawalEnabled: null == withdrawalEnabled ? _self.withdrawalEnabled : withdrawalEnabled // ignore: cast_nullable_to_non_nullable
as bool,depositEnabled: null == depositEnabled ? _self.depositEnabled : depositEnabled // ignore: cast_nullable_to_non_nullable
as bool,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
