// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PortfolioSummaryModel {

@JsonKey(name: 'total_equity') String get totalEquity;@JsonKey(name: 'cash_balance') String get cashBalance;@JsonKey(name: 'total_market_value') String get marketValue;@JsonKey(name: 'day_pnl') String get dayPnl;@JsonKey(name: 'day_pnl_pct') String get dayPnlPct;@JsonKey(name: 'cumulative_pnl') String get totalPnl;@JsonKey(name: 'cumulative_pnl_pct') String get totalPnlPct;@JsonKey(name: 'buying_power') String get buyingPower;@JsonKey(name: 'unsettled_cash') String get unsettledCash;
/// Create a copy of PortfolioSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioSummaryModelCopyWith<PortfolioSummaryModel> get copyWith => _$PortfolioSummaryModelCopyWithImpl<PortfolioSummaryModel>(this as PortfolioSummaryModel, _$identity);

  /// Serializes this PortfolioSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioSummaryModel&&(identical(other.totalEquity, totalEquity) || other.totalEquity == totalEquity)&&(identical(other.cashBalance, cashBalance) || other.cashBalance == cashBalance)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.dayPnl, dayPnl) || other.dayPnl == dayPnl)&&(identical(other.dayPnlPct, dayPnlPct) || other.dayPnlPct == dayPnlPct)&&(identical(other.totalPnl, totalPnl) || other.totalPnl == totalPnl)&&(identical(other.totalPnlPct, totalPnlPct) || other.totalPnlPct == totalPnlPct)&&(identical(other.buyingPower, buyingPower) || other.buyingPower == buyingPower)&&(identical(other.unsettledCash, unsettledCash) || other.unsettledCash == unsettledCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEquity,cashBalance,marketValue,dayPnl,dayPnlPct,totalPnl,totalPnlPct,buyingPower,unsettledCash);

@override
String toString() {
  return 'PortfolioSummaryModel(totalEquity: $totalEquity, cashBalance: $cashBalance, marketValue: $marketValue, dayPnl: $dayPnl, dayPnlPct: $dayPnlPct, totalPnl: $totalPnl, totalPnlPct: $totalPnlPct, buyingPower: $buyingPower, unsettledCash: $unsettledCash)';
}


}

/// @nodoc
abstract mixin class $PortfolioSummaryModelCopyWith<$Res>  {
  factory $PortfolioSummaryModelCopyWith(PortfolioSummaryModel value, $Res Function(PortfolioSummaryModel) _then) = _$PortfolioSummaryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_equity') String totalEquity,@JsonKey(name: 'cash_balance') String cashBalance,@JsonKey(name: 'total_market_value') String marketValue,@JsonKey(name: 'day_pnl') String dayPnl,@JsonKey(name: 'day_pnl_pct') String dayPnlPct,@JsonKey(name: 'cumulative_pnl') String totalPnl,@JsonKey(name: 'cumulative_pnl_pct') String totalPnlPct,@JsonKey(name: 'buying_power') String buyingPower,@JsonKey(name: 'unsettled_cash') String unsettledCash
});




}
/// @nodoc
class _$PortfolioSummaryModelCopyWithImpl<$Res>
    implements $PortfolioSummaryModelCopyWith<$Res> {
  _$PortfolioSummaryModelCopyWithImpl(this._self, this._then);

  final PortfolioSummaryModel _self;
  final $Res Function(PortfolioSummaryModel) _then;

/// Create a copy of PortfolioSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalEquity = null,Object? cashBalance = null,Object? marketValue = null,Object? dayPnl = null,Object? dayPnlPct = null,Object? totalPnl = null,Object? totalPnlPct = null,Object? buyingPower = null,Object? unsettledCash = null,}) {
  return _then(_self.copyWith(
totalEquity: null == totalEquity ? _self.totalEquity : totalEquity // ignore: cast_nullable_to_non_nullable
as String,cashBalance: null == cashBalance ? _self.cashBalance : cashBalance // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,dayPnl: null == dayPnl ? _self.dayPnl : dayPnl // ignore: cast_nullable_to_non_nullable
as String,dayPnlPct: null == dayPnlPct ? _self.dayPnlPct : dayPnlPct // ignore: cast_nullable_to_non_nullable
as String,totalPnl: null == totalPnl ? _self.totalPnl : totalPnl // ignore: cast_nullable_to_non_nullable
as String,totalPnlPct: null == totalPnlPct ? _self.totalPnlPct : totalPnlPct // ignore: cast_nullable_to_non_nullable
as String,buyingPower: null == buyingPower ? _self.buyingPower : buyingPower // ignore: cast_nullable_to_non_nullable
as String,unsettledCash: null == unsettledCash ? _self.unsettledCash : unsettledCash // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioSummaryModel].
extension PortfolioSummaryModelPatterns on PortfolioSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_equity')  String totalEquity, @JsonKey(name: 'cash_balance')  String cashBalance, @JsonKey(name: 'total_market_value')  String marketValue, @JsonKey(name: 'day_pnl')  String dayPnl, @JsonKey(name: 'day_pnl_pct')  String dayPnlPct, @JsonKey(name: 'cumulative_pnl')  String totalPnl, @JsonKey(name: 'cumulative_pnl_pct')  String totalPnlPct, @JsonKey(name: 'buying_power')  String buyingPower, @JsonKey(name: 'unsettled_cash')  String unsettledCash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioSummaryModel() when $default != null:
return $default(_that.totalEquity,_that.cashBalance,_that.marketValue,_that.dayPnl,_that.dayPnlPct,_that.totalPnl,_that.totalPnlPct,_that.buyingPower,_that.unsettledCash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_equity')  String totalEquity, @JsonKey(name: 'cash_balance')  String cashBalance, @JsonKey(name: 'total_market_value')  String marketValue, @JsonKey(name: 'day_pnl')  String dayPnl, @JsonKey(name: 'day_pnl_pct')  String dayPnlPct, @JsonKey(name: 'cumulative_pnl')  String totalPnl, @JsonKey(name: 'cumulative_pnl_pct')  String totalPnlPct, @JsonKey(name: 'buying_power')  String buyingPower, @JsonKey(name: 'unsettled_cash')  String unsettledCash)  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummaryModel():
return $default(_that.totalEquity,_that.cashBalance,_that.marketValue,_that.dayPnl,_that.dayPnlPct,_that.totalPnl,_that.totalPnlPct,_that.buyingPower,_that.unsettledCash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_equity')  String totalEquity, @JsonKey(name: 'cash_balance')  String cashBalance, @JsonKey(name: 'total_market_value')  String marketValue, @JsonKey(name: 'day_pnl')  String dayPnl, @JsonKey(name: 'day_pnl_pct')  String dayPnlPct, @JsonKey(name: 'cumulative_pnl')  String totalPnl, @JsonKey(name: 'cumulative_pnl_pct')  String totalPnlPct, @JsonKey(name: 'buying_power')  String buyingPower, @JsonKey(name: 'unsettled_cash')  String unsettledCash)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummaryModel() when $default != null:
return $default(_that.totalEquity,_that.cashBalance,_that.marketValue,_that.dayPnl,_that.dayPnlPct,_that.totalPnl,_that.totalPnlPct,_that.buyingPower,_that.unsettledCash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PortfolioSummaryModel implements PortfolioSummaryModel {
  const _PortfolioSummaryModel({@JsonKey(name: 'total_equity') required this.totalEquity, @JsonKey(name: 'cash_balance') required this.cashBalance, @JsonKey(name: 'total_market_value') required this.marketValue, @JsonKey(name: 'day_pnl') required this.dayPnl, @JsonKey(name: 'day_pnl_pct') required this.dayPnlPct, @JsonKey(name: 'cumulative_pnl') required this.totalPnl, @JsonKey(name: 'cumulative_pnl_pct') required this.totalPnlPct, @JsonKey(name: 'buying_power') required this.buyingPower, @JsonKey(name: 'unsettled_cash') required this.unsettledCash});
  factory _PortfolioSummaryModel.fromJson(Map<String, dynamic> json) => _$PortfolioSummaryModelFromJson(json);

@override@JsonKey(name: 'total_equity') final  String totalEquity;
@override@JsonKey(name: 'cash_balance') final  String cashBalance;
@override@JsonKey(name: 'total_market_value') final  String marketValue;
@override@JsonKey(name: 'day_pnl') final  String dayPnl;
@override@JsonKey(name: 'day_pnl_pct') final  String dayPnlPct;
@override@JsonKey(name: 'cumulative_pnl') final  String totalPnl;
@override@JsonKey(name: 'cumulative_pnl_pct') final  String totalPnlPct;
@override@JsonKey(name: 'buying_power') final  String buyingPower;
@override@JsonKey(name: 'unsettled_cash') final  String unsettledCash;

/// Create a copy of PortfolioSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioSummaryModelCopyWith<_PortfolioSummaryModel> get copyWith => __$PortfolioSummaryModelCopyWithImpl<_PortfolioSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PortfolioSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioSummaryModel&&(identical(other.totalEquity, totalEquity) || other.totalEquity == totalEquity)&&(identical(other.cashBalance, cashBalance) || other.cashBalance == cashBalance)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.dayPnl, dayPnl) || other.dayPnl == dayPnl)&&(identical(other.dayPnlPct, dayPnlPct) || other.dayPnlPct == dayPnlPct)&&(identical(other.totalPnl, totalPnl) || other.totalPnl == totalPnl)&&(identical(other.totalPnlPct, totalPnlPct) || other.totalPnlPct == totalPnlPct)&&(identical(other.buyingPower, buyingPower) || other.buyingPower == buyingPower)&&(identical(other.unsettledCash, unsettledCash) || other.unsettledCash == unsettledCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEquity,cashBalance,marketValue,dayPnl,dayPnlPct,totalPnl,totalPnlPct,buyingPower,unsettledCash);

@override
String toString() {
  return 'PortfolioSummaryModel(totalEquity: $totalEquity, cashBalance: $cashBalance, marketValue: $marketValue, dayPnl: $dayPnl, dayPnlPct: $dayPnlPct, totalPnl: $totalPnl, totalPnlPct: $totalPnlPct, buyingPower: $buyingPower, unsettledCash: $unsettledCash)';
}


}

/// @nodoc
abstract mixin class _$PortfolioSummaryModelCopyWith<$Res> implements $PortfolioSummaryModelCopyWith<$Res> {
  factory _$PortfolioSummaryModelCopyWith(_PortfolioSummaryModel value, $Res Function(_PortfolioSummaryModel) _then) = __$PortfolioSummaryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_equity') String totalEquity,@JsonKey(name: 'cash_balance') String cashBalance,@JsonKey(name: 'total_market_value') String marketValue,@JsonKey(name: 'day_pnl') String dayPnl,@JsonKey(name: 'day_pnl_pct') String dayPnlPct,@JsonKey(name: 'cumulative_pnl') String totalPnl,@JsonKey(name: 'cumulative_pnl_pct') String totalPnlPct,@JsonKey(name: 'buying_power') String buyingPower,@JsonKey(name: 'unsettled_cash') String unsettledCash
});




}
/// @nodoc
class __$PortfolioSummaryModelCopyWithImpl<$Res>
    implements _$PortfolioSummaryModelCopyWith<$Res> {
  __$PortfolioSummaryModelCopyWithImpl(this._self, this._then);

  final _PortfolioSummaryModel _self;
  final $Res Function(_PortfolioSummaryModel) _then;

/// Create a copy of PortfolioSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalEquity = null,Object? cashBalance = null,Object? marketValue = null,Object? dayPnl = null,Object? dayPnlPct = null,Object? totalPnl = null,Object? totalPnlPct = null,Object? buyingPower = null,Object? unsettledCash = null,}) {
  return _then(_PortfolioSummaryModel(
totalEquity: null == totalEquity ? _self.totalEquity : totalEquity // ignore: cast_nullable_to_non_nullable
as String,cashBalance: null == cashBalance ? _self.cashBalance : cashBalance // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,dayPnl: null == dayPnl ? _self.dayPnl : dayPnl // ignore: cast_nullable_to_non_nullable
as String,dayPnlPct: null == dayPnlPct ? _self.dayPnlPct : dayPnlPct // ignore: cast_nullable_to_non_nullable
as String,totalPnl: null == totalPnl ? _self.totalPnl : totalPnl // ignore: cast_nullable_to_non_nullable
as String,totalPnlPct: null == totalPnlPct ? _self.totalPnlPct : totalPnlPct // ignore: cast_nullable_to_non_nullable
as String,buyingPower: null == buyingPower ? _self.buyingPower : buyingPower // ignore: cast_nullable_to_non_nullable
as String,unsettledCash: null == unsettledCash ? _self.unsettledCash : unsettledCash // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
