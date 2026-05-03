// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TradeSettings {

 DefaultOrderType get defaultOrderType; DefaultOrderValidity get defaultValidity; OrderConfirmationMethod get confirmationMethod; LargeOrderThreshold get largeOrderThreshold; PriceDeviationWarning get priceDeviationWarning;/// Whether extended-hours (pre/after-market) trading is enabled.
/// First enable requires explicit risk disclosure confirmation.
 bool get extendedHoursEnabled;/// Tracks whether user has already accepted extended-hours risk disclosure.
 bool get extendedHoursRiskAccepted;
/// Create a copy of TradeSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeSettingsCopyWith<TradeSettings> get copyWith => _$TradeSettingsCopyWithImpl<TradeSettings>(this as TradeSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeSettings&&(identical(other.defaultOrderType, defaultOrderType) || other.defaultOrderType == defaultOrderType)&&(identical(other.defaultValidity, defaultValidity) || other.defaultValidity == defaultValidity)&&(identical(other.confirmationMethod, confirmationMethod) || other.confirmationMethod == confirmationMethod)&&(identical(other.largeOrderThreshold, largeOrderThreshold) || other.largeOrderThreshold == largeOrderThreshold)&&(identical(other.priceDeviationWarning, priceDeviationWarning) || other.priceDeviationWarning == priceDeviationWarning)&&(identical(other.extendedHoursEnabled, extendedHoursEnabled) || other.extendedHoursEnabled == extendedHoursEnabled)&&(identical(other.extendedHoursRiskAccepted, extendedHoursRiskAccepted) || other.extendedHoursRiskAccepted == extendedHoursRiskAccepted));
}


@override
int get hashCode => Object.hash(runtimeType,defaultOrderType,defaultValidity,confirmationMethod,largeOrderThreshold,priceDeviationWarning,extendedHoursEnabled,extendedHoursRiskAccepted);

@override
String toString() {
  return 'TradeSettings(defaultOrderType: $defaultOrderType, defaultValidity: $defaultValidity, confirmationMethod: $confirmationMethod, largeOrderThreshold: $largeOrderThreshold, priceDeviationWarning: $priceDeviationWarning, extendedHoursEnabled: $extendedHoursEnabled, extendedHoursRiskAccepted: $extendedHoursRiskAccepted)';
}


}

/// @nodoc
abstract mixin class $TradeSettingsCopyWith<$Res>  {
  factory $TradeSettingsCopyWith(TradeSettings value, $Res Function(TradeSettings) _then) = _$TradeSettingsCopyWithImpl;
@useResult
$Res call({
 DefaultOrderType defaultOrderType, DefaultOrderValidity defaultValidity, OrderConfirmationMethod confirmationMethod, LargeOrderThreshold largeOrderThreshold, PriceDeviationWarning priceDeviationWarning, bool extendedHoursEnabled, bool extendedHoursRiskAccepted
});




}
/// @nodoc
class _$TradeSettingsCopyWithImpl<$Res>
    implements $TradeSettingsCopyWith<$Res> {
  _$TradeSettingsCopyWithImpl(this._self, this._then);

  final TradeSettings _self;
  final $Res Function(TradeSettings) _then;

/// Create a copy of TradeSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? defaultOrderType = null,Object? defaultValidity = null,Object? confirmationMethod = null,Object? largeOrderThreshold = null,Object? priceDeviationWarning = null,Object? extendedHoursEnabled = null,Object? extendedHoursRiskAccepted = null,}) {
  return _then(_self.copyWith(
defaultOrderType: null == defaultOrderType ? _self.defaultOrderType : defaultOrderType // ignore: cast_nullable_to_non_nullable
as DefaultOrderType,defaultValidity: null == defaultValidity ? _self.defaultValidity : defaultValidity // ignore: cast_nullable_to_non_nullable
as DefaultOrderValidity,confirmationMethod: null == confirmationMethod ? _self.confirmationMethod : confirmationMethod // ignore: cast_nullable_to_non_nullable
as OrderConfirmationMethod,largeOrderThreshold: null == largeOrderThreshold ? _self.largeOrderThreshold : largeOrderThreshold // ignore: cast_nullable_to_non_nullable
as LargeOrderThreshold,priceDeviationWarning: null == priceDeviationWarning ? _self.priceDeviationWarning : priceDeviationWarning // ignore: cast_nullable_to_non_nullable
as PriceDeviationWarning,extendedHoursEnabled: null == extendedHoursEnabled ? _self.extendedHoursEnabled : extendedHoursEnabled // ignore: cast_nullable_to_non_nullable
as bool,extendedHoursRiskAccepted: null == extendedHoursRiskAccepted ? _self.extendedHoursRiskAccepted : extendedHoursRiskAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeSettings].
extension TradeSettingsPatterns on TradeSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TradeSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TradeSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TradeSettings value)  $default,){
final _that = this;
switch (_that) {
case _TradeSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TradeSettings value)?  $default,){
final _that = this;
switch (_that) {
case _TradeSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DefaultOrderType defaultOrderType,  DefaultOrderValidity defaultValidity,  OrderConfirmationMethod confirmationMethod,  LargeOrderThreshold largeOrderThreshold,  PriceDeviationWarning priceDeviationWarning,  bool extendedHoursEnabled,  bool extendedHoursRiskAccepted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TradeSettings() when $default != null:
return $default(_that.defaultOrderType,_that.defaultValidity,_that.confirmationMethod,_that.largeOrderThreshold,_that.priceDeviationWarning,_that.extendedHoursEnabled,_that.extendedHoursRiskAccepted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DefaultOrderType defaultOrderType,  DefaultOrderValidity defaultValidity,  OrderConfirmationMethod confirmationMethod,  LargeOrderThreshold largeOrderThreshold,  PriceDeviationWarning priceDeviationWarning,  bool extendedHoursEnabled,  bool extendedHoursRiskAccepted)  $default,) {final _that = this;
switch (_that) {
case _TradeSettings():
return $default(_that.defaultOrderType,_that.defaultValidity,_that.confirmationMethod,_that.largeOrderThreshold,_that.priceDeviationWarning,_that.extendedHoursEnabled,_that.extendedHoursRiskAccepted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DefaultOrderType defaultOrderType,  DefaultOrderValidity defaultValidity,  OrderConfirmationMethod confirmationMethod,  LargeOrderThreshold largeOrderThreshold,  PriceDeviationWarning priceDeviationWarning,  bool extendedHoursEnabled,  bool extendedHoursRiskAccepted)?  $default,) {final _that = this;
switch (_that) {
case _TradeSettings() when $default != null:
return $default(_that.defaultOrderType,_that.defaultValidity,_that.confirmationMethod,_that.largeOrderThreshold,_that.priceDeviationWarning,_that.extendedHoursEnabled,_that.extendedHoursRiskAccepted);case _:
  return null;

}
}

}

/// @nodoc


class _TradeSettings implements TradeSettings {
  const _TradeSettings({this.defaultOrderType = DefaultOrderType.limit, this.defaultValidity = DefaultOrderValidity.day, this.confirmationMethod = OrderConfirmationMethod.slideAndBiometric, this.largeOrderThreshold = LargeOrderThreshold.usd10000, this.priceDeviationWarning = PriceDeviationWarning.pct5, this.extendedHoursEnabled = false, this.extendedHoursRiskAccepted = false});
  

@override@JsonKey() final  DefaultOrderType defaultOrderType;
@override@JsonKey() final  DefaultOrderValidity defaultValidity;
@override@JsonKey() final  OrderConfirmationMethod confirmationMethod;
@override@JsonKey() final  LargeOrderThreshold largeOrderThreshold;
@override@JsonKey() final  PriceDeviationWarning priceDeviationWarning;
/// Whether extended-hours (pre/after-market) trading is enabled.
/// First enable requires explicit risk disclosure confirmation.
@override@JsonKey() final  bool extendedHoursEnabled;
/// Tracks whether user has already accepted extended-hours risk disclosure.
@override@JsonKey() final  bool extendedHoursRiskAccepted;

/// Create a copy of TradeSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TradeSettingsCopyWith<_TradeSettings> get copyWith => __$TradeSettingsCopyWithImpl<_TradeSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TradeSettings&&(identical(other.defaultOrderType, defaultOrderType) || other.defaultOrderType == defaultOrderType)&&(identical(other.defaultValidity, defaultValidity) || other.defaultValidity == defaultValidity)&&(identical(other.confirmationMethod, confirmationMethod) || other.confirmationMethod == confirmationMethod)&&(identical(other.largeOrderThreshold, largeOrderThreshold) || other.largeOrderThreshold == largeOrderThreshold)&&(identical(other.priceDeviationWarning, priceDeviationWarning) || other.priceDeviationWarning == priceDeviationWarning)&&(identical(other.extendedHoursEnabled, extendedHoursEnabled) || other.extendedHoursEnabled == extendedHoursEnabled)&&(identical(other.extendedHoursRiskAccepted, extendedHoursRiskAccepted) || other.extendedHoursRiskAccepted == extendedHoursRiskAccepted));
}


@override
int get hashCode => Object.hash(runtimeType,defaultOrderType,defaultValidity,confirmationMethod,largeOrderThreshold,priceDeviationWarning,extendedHoursEnabled,extendedHoursRiskAccepted);

@override
String toString() {
  return 'TradeSettings(defaultOrderType: $defaultOrderType, defaultValidity: $defaultValidity, confirmationMethod: $confirmationMethod, largeOrderThreshold: $largeOrderThreshold, priceDeviationWarning: $priceDeviationWarning, extendedHoursEnabled: $extendedHoursEnabled, extendedHoursRiskAccepted: $extendedHoursRiskAccepted)';
}


}

/// @nodoc
abstract mixin class _$TradeSettingsCopyWith<$Res> implements $TradeSettingsCopyWith<$Res> {
  factory _$TradeSettingsCopyWith(_TradeSettings value, $Res Function(_TradeSettings) _then) = __$TradeSettingsCopyWithImpl;
@override @useResult
$Res call({
 DefaultOrderType defaultOrderType, DefaultOrderValidity defaultValidity, OrderConfirmationMethod confirmationMethod, LargeOrderThreshold largeOrderThreshold, PriceDeviationWarning priceDeviationWarning, bool extendedHoursEnabled, bool extendedHoursRiskAccepted
});




}
/// @nodoc
class __$TradeSettingsCopyWithImpl<$Res>
    implements _$TradeSettingsCopyWith<$Res> {
  __$TradeSettingsCopyWithImpl(this._self, this._then);

  final _TradeSettings _self;
  final $Res Function(_TradeSettings) _then;

/// Create a copy of TradeSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? defaultOrderType = null,Object? defaultValidity = null,Object? confirmationMethod = null,Object? largeOrderThreshold = null,Object? priceDeviationWarning = null,Object? extendedHoursEnabled = null,Object? extendedHoursRiskAccepted = null,}) {
  return _then(_TradeSettings(
defaultOrderType: null == defaultOrderType ? _self.defaultOrderType : defaultOrderType // ignore: cast_nullable_to_non_nullable
as DefaultOrderType,defaultValidity: null == defaultValidity ? _self.defaultValidity : defaultValidity // ignore: cast_nullable_to_non_nullable
as DefaultOrderValidity,confirmationMethod: null == confirmationMethod ? _self.confirmationMethod : confirmationMethod // ignore: cast_nullable_to_non_nullable
as OrderConfirmationMethod,largeOrderThreshold: null == largeOrderThreshold ? _self.largeOrderThreshold : largeOrderThreshold // ignore: cast_nullable_to_non_nullable
as LargeOrderThreshold,priceDeviationWarning: null == priceDeviationWarning ? _self.priceDeviationWarning : priceDeviationWarning // ignore: cast_nullable_to_non_nullable
as PriceDeviationWarning,extendedHoursEnabled: null == extendedHoursEnabled ? _self.extendedHoursEnabled : extendedHoursEnabled // ignore: cast_nullable_to_non_nullable
as bool,extendedHoursRiskAccepted: null == extendedHoursRiskAccepted ? _self.extendedHoursRiskAccepted : extendedHoursRiskAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
