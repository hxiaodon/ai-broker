// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PortfolioSummary {

 Decimal get totalEquity; Decimal get cashBalance; Decimal get marketValue; Decimal get dayPnl; Decimal get dayPnlPct; Decimal get totalPnl; Decimal get totalPnlPct; Decimal get buyingPower; Decimal get unsettledCash;
/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioSummaryCopyWith<PortfolioSummary> get copyWith => _$PortfolioSummaryCopyWithImpl<PortfolioSummary>(this as PortfolioSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioSummary&&(identical(other.totalEquity, totalEquity) || other.totalEquity == totalEquity)&&(identical(other.cashBalance, cashBalance) || other.cashBalance == cashBalance)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.dayPnl, dayPnl) || other.dayPnl == dayPnl)&&(identical(other.dayPnlPct, dayPnlPct) || other.dayPnlPct == dayPnlPct)&&(identical(other.totalPnl, totalPnl) || other.totalPnl == totalPnl)&&(identical(other.totalPnlPct, totalPnlPct) || other.totalPnlPct == totalPnlPct)&&(identical(other.buyingPower, buyingPower) || other.buyingPower == buyingPower)&&(identical(other.unsettledCash, unsettledCash) || other.unsettledCash == unsettledCash));
}


@override
int get hashCode => Object.hash(runtimeType,totalEquity,cashBalance,marketValue,dayPnl,dayPnlPct,totalPnl,totalPnlPct,buyingPower,unsettledCash);

@override
String toString() {
  return 'PortfolioSummary(totalEquity: $totalEquity, cashBalance: $cashBalance, marketValue: $marketValue, dayPnl: $dayPnl, dayPnlPct: $dayPnlPct, totalPnl: $totalPnl, totalPnlPct: $totalPnlPct, buyingPower: $buyingPower, unsettledCash: $unsettledCash)';
}


}

/// @nodoc
abstract mixin class $PortfolioSummaryCopyWith<$Res>  {
  factory $PortfolioSummaryCopyWith(PortfolioSummary value, $Res Function(PortfolioSummary) _then) = _$PortfolioSummaryCopyWithImpl;
@useResult
$Res call({
 Decimal totalEquity, Decimal cashBalance, Decimal marketValue, Decimal dayPnl, Decimal dayPnlPct, Decimal totalPnl, Decimal totalPnlPct, Decimal buyingPower, Decimal unsettledCash
});




}
/// @nodoc
class _$PortfolioSummaryCopyWithImpl<$Res>
    implements $PortfolioSummaryCopyWith<$Res> {
  _$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final PortfolioSummary _self;
  final $Res Function(PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalEquity = null,Object? cashBalance = null,Object? marketValue = null,Object? dayPnl = null,Object? dayPnlPct = null,Object? totalPnl = null,Object? totalPnlPct = null,Object? buyingPower = null,Object? unsettledCash = null,}) {
  return _then(_self.copyWith(
totalEquity: null == totalEquity ? _self.totalEquity : totalEquity // ignore: cast_nullable_to_non_nullable
as Decimal,cashBalance: null == cashBalance ? _self.cashBalance : cashBalance // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,dayPnl: null == dayPnl ? _self.dayPnl : dayPnl // ignore: cast_nullable_to_non_nullable
as Decimal,dayPnlPct: null == dayPnlPct ? _self.dayPnlPct : dayPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,totalPnl: null == totalPnl ? _self.totalPnl : totalPnl // ignore: cast_nullable_to_non_nullable
as Decimal,totalPnlPct: null == totalPnlPct ? _self.totalPnlPct : totalPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,buyingPower: null == buyingPower ? _self.buyingPower : buyingPower // ignore: cast_nullable_to_non_nullable
as Decimal,unsettledCash: null == unsettledCash ? _self.unsettledCash : unsettledCash // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioSummary].
extension PortfolioSummaryPatterns on PortfolioSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Decimal totalEquity,  Decimal cashBalance,  Decimal marketValue,  Decimal dayPnl,  Decimal dayPnlPct,  Decimal totalPnl,  Decimal totalPnlPct,  Decimal buyingPower,  Decimal unsettledCash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Decimal totalEquity,  Decimal cashBalance,  Decimal marketValue,  Decimal dayPnl,  Decimal dayPnlPct,  Decimal totalPnl,  Decimal totalPnlPct,  Decimal buyingPower,  Decimal unsettledCash)  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Decimal totalEquity,  Decimal cashBalance,  Decimal marketValue,  Decimal dayPnl,  Decimal dayPnlPct,  Decimal totalPnl,  Decimal totalPnlPct,  Decimal buyingPower,  Decimal unsettledCash)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.totalEquity,_that.cashBalance,_that.marketValue,_that.dayPnl,_that.dayPnlPct,_that.totalPnl,_that.totalPnlPct,_that.buyingPower,_that.unsettledCash);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioSummary implements PortfolioSummary {
  const _PortfolioSummary({required this.totalEquity, required this.cashBalance, required this.marketValue, required this.dayPnl, required this.dayPnlPct, required this.totalPnl, required this.totalPnlPct, required this.buyingPower, required this.unsettledCash});
  

@override final  Decimal totalEquity;
@override final  Decimal cashBalance;
@override final  Decimal marketValue;
@override final  Decimal dayPnl;
@override final  Decimal dayPnlPct;
@override final  Decimal totalPnl;
@override final  Decimal totalPnlPct;
@override final  Decimal buyingPower;
@override final  Decimal unsettledCash;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioSummaryCopyWith<_PortfolioSummary> get copyWith => __$PortfolioSummaryCopyWithImpl<_PortfolioSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioSummary&&(identical(other.totalEquity, totalEquity) || other.totalEquity == totalEquity)&&(identical(other.cashBalance, cashBalance) || other.cashBalance == cashBalance)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.dayPnl, dayPnl) || other.dayPnl == dayPnl)&&(identical(other.dayPnlPct, dayPnlPct) || other.dayPnlPct == dayPnlPct)&&(identical(other.totalPnl, totalPnl) || other.totalPnl == totalPnl)&&(identical(other.totalPnlPct, totalPnlPct) || other.totalPnlPct == totalPnlPct)&&(identical(other.buyingPower, buyingPower) || other.buyingPower == buyingPower)&&(identical(other.unsettledCash, unsettledCash) || other.unsettledCash == unsettledCash));
}


@override
int get hashCode => Object.hash(runtimeType,totalEquity,cashBalance,marketValue,dayPnl,dayPnlPct,totalPnl,totalPnlPct,buyingPower,unsettledCash);

@override
String toString() {
  return 'PortfolioSummary(totalEquity: $totalEquity, cashBalance: $cashBalance, marketValue: $marketValue, dayPnl: $dayPnl, dayPnlPct: $dayPnlPct, totalPnl: $totalPnl, totalPnlPct: $totalPnlPct, buyingPower: $buyingPower, unsettledCash: $unsettledCash)';
}


}

/// @nodoc
abstract mixin class _$PortfolioSummaryCopyWith<$Res> implements $PortfolioSummaryCopyWith<$Res> {
  factory _$PortfolioSummaryCopyWith(_PortfolioSummary value, $Res Function(_PortfolioSummary) _then) = __$PortfolioSummaryCopyWithImpl;
@override @useResult
$Res call({
 Decimal totalEquity, Decimal cashBalance, Decimal marketValue, Decimal dayPnl, Decimal dayPnlPct, Decimal totalPnl, Decimal totalPnlPct, Decimal buyingPower, Decimal unsettledCash
});




}
/// @nodoc
class __$PortfolioSummaryCopyWithImpl<$Res>
    implements _$PortfolioSummaryCopyWith<$Res> {
  __$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final _PortfolioSummary _self;
  final $Res Function(_PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalEquity = null,Object? cashBalance = null,Object? marketValue = null,Object? dayPnl = null,Object? dayPnlPct = null,Object? totalPnl = null,Object? totalPnlPct = null,Object? buyingPower = null,Object? unsettledCash = null,}) {
  return _then(_PortfolioSummary(
totalEquity: null == totalEquity ? _self.totalEquity : totalEquity // ignore: cast_nullable_to_non_nullable
as Decimal,cashBalance: null == cashBalance ? _self.cashBalance : cashBalance // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,dayPnl: null == dayPnl ? _self.dayPnl : dayPnl // ignore: cast_nullable_to_non_nullable
as Decimal,dayPnlPct: null == dayPnlPct ? _self.dayPnlPct : dayPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,totalPnl: null == totalPnl ? _self.totalPnl : totalPnl // ignore: cast_nullable_to_non_nullable
as Decimal,totalPnlPct: null == totalPnlPct ? _self.totalPnlPct : totalPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,buyingPower: null == buyingPower ? _self.buyingPower : buyingPower // ignore: cast_nullable_to_non_nullable
as Decimal,unsettledCash: null == unsettledCash ? _self.unsettledCash : unsettledCash // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}


}

// dart format on
