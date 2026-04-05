// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FinancialsQuarter {

 String get period; String get reportDate; String get revenue; String get netIncome; Decimal get eps; Decimal get epsEstimate; Decimal get revenueGrowth; Decimal get netIncomeGrowth;
/// Create a copy of FinancialsQuarter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialsQuarterCopyWith<FinancialsQuarter> get copyWith => _$FinancialsQuarterCopyWithImpl<FinancialsQuarter>(this as FinancialsQuarter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialsQuarter&&(identical(other.period, period) || other.period == period)&&(identical(other.reportDate, reportDate) || other.reportDate == reportDate)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.eps, eps) || other.eps == eps)&&(identical(other.epsEstimate, epsEstimate) || other.epsEstimate == epsEstimate)&&(identical(other.revenueGrowth, revenueGrowth) || other.revenueGrowth == revenueGrowth)&&(identical(other.netIncomeGrowth, netIncomeGrowth) || other.netIncomeGrowth == netIncomeGrowth));
}


@override
int get hashCode => Object.hash(runtimeType,period,reportDate,revenue,netIncome,eps,epsEstimate,revenueGrowth,netIncomeGrowth);

@override
String toString() {
  return 'FinancialsQuarter(period: $period, reportDate: $reportDate, revenue: $revenue, netIncome: $netIncome, eps: $eps, epsEstimate: $epsEstimate, revenueGrowth: $revenueGrowth, netIncomeGrowth: $netIncomeGrowth)';
}


}

/// @nodoc
abstract mixin class $FinancialsQuarterCopyWith<$Res>  {
  factory $FinancialsQuarterCopyWith(FinancialsQuarter value, $Res Function(FinancialsQuarter) _then) = _$FinancialsQuarterCopyWithImpl;
@useResult
$Res call({
 String period, String reportDate, String revenue, String netIncome, Decimal eps, Decimal epsEstimate, Decimal revenueGrowth, Decimal netIncomeGrowth
});




}
/// @nodoc
class _$FinancialsQuarterCopyWithImpl<$Res>
    implements $FinancialsQuarterCopyWith<$Res> {
  _$FinancialsQuarterCopyWithImpl(this._self, this._then);

  final FinancialsQuarter _self;
  final $Res Function(FinancialsQuarter) _then;

/// Create a copy of FinancialsQuarter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? reportDate = null,Object? revenue = null,Object? netIncome = null,Object? eps = null,Object? epsEstimate = null,Object? revenueGrowth = null,Object? netIncomeGrowth = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,reportDate: null == reportDate ? _self.reportDate : reportDate // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,netIncome: null == netIncome ? _self.netIncome : netIncome // ignore: cast_nullable_to_non_nullable
as String,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as Decimal,epsEstimate: null == epsEstimate ? _self.epsEstimate : epsEstimate // ignore: cast_nullable_to_non_nullable
as Decimal,revenueGrowth: null == revenueGrowth ? _self.revenueGrowth : revenueGrowth // ignore: cast_nullable_to_non_nullable
as Decimal,netIncomeGrowth: null == netIncomeGrowth ? _self.netIncomeGrowth : netIncomeGrowth // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialsQuarter].
extension FinancialsQuarterPatterns on FinancialsQuarter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialsQuarter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialsQuarter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialsQuarter value)  $default,){
final _that = this;
switch (_that) {
case _FinancialsQuarter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialsQuarter value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialsQuarter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period,  String reportDate,  String revenue,  String netIncome,  Decimal eps,  Decimal epsEstimate,  Decimal revenueGrowth,  Decimal netIncomeGrowth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialsQuarter() when $default != null:
return $default(_that.period,_that.reportDate,_that.revenue,_that.netIncome,_that.eps,_that.epsEstimate,_that.revenueGrowth,_that.netIncomeGrowth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period,  String reportDate,  String revenue,  String netIncome,  Decimal eps,  Decimal epsEstimate,  Decimal revenueGrowth,  Decimal netIncomeGrowth)  $default,) {final _that = this;
switch (_that) {
case _FinancialsQuarter():
return $default(_that.period,_that.reportDate,_that.revenue,_that.netIncome,_that.eps,_that.epsEstimate,_that.revenueGrowth,_that.netIncomeGrowth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period,  String reportDate,  String revenue,  String netIncome,  Decimal eps,  Decimal epsEstimate,  Decimal revenueGrowth,  Decimal netIncomeGrowth)?  $default,) {final _that = this;
switch (_that) {
case _FinancialsQuarter() when $default != null:
return $default(_that.period,_that.reportDate,_that.revenue,_that.netIncome,_that.eps,_that.epsEstimate,_that.revenueGrowth,_that.netIncomeGrowth);case _:
  return null;

}
}

}

/// @nodoc


class _FinancialsQuarter implements FinancialsQuarter {
  const _FinancialsQuarter({required this.period, required this.reportDate, required this.revenue, required this.netIncome, required this.eps, required this.epsEstimate, required this.revenueGrowth, required this.netIncomeGrowth});
  

@override final  String period;
@override final  String reportDate;
@override final  String revenue;
@override final  String netIncome;
@override final  Decimal eps;
@override final  Decimal epsEstimate;
@override final  Decimal revenueGrowth;
@override final  Decimal netIncomeGrowth;

/// Create a copy of FinancialsQuarter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialsQuarterCopyWith<_FinancialsQuarter> get copyWith => __$FinancialsQuarterCopyWithImpl<_FinancialsQuarter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialsQuarter&&(identical(other.period, period) || other.period == period)&&(identical(other.reportDate, reportDate) || other.reportDate == reportDate)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.eps, eps) || other.eps == eps)&&(identical(other.epsEstimate, epsEstimate) || other.epsEstimate == epsEstimate)&&(identical(other.revenueGrowth, revenueGrowth) || other.revenueGrowth == revenueGrowth)&&(identical(other.netIncomeGrowth, netIncomeGrowth) || other.netIncomeGrowth == netIncomeGrowth));
}


@override
int get hashCode => Object.hash(runtimeType,period,reportDate,revenue,netIncome,eps,epsEstimate,revenueGrowth,netIncomeGrowth);

@override
String toString() {
  return 'FinancialsQuarter(period: $period, reportDate: $reportDate, revenue: $revenue, netIncome: $netIncome, eps: $eps, epsEstimate: $epsEstimate, revenueGrowth: $revenueGrowth, netIncomeGrowth: $netIncomeGrowth)';
}


}

/// @nodoc
abstract mixin class _$FinancialsQuarterCopyWith<$Res> implements $FinancialsQuarterCopyWith<$Res> {
  factory _$FinancialsQuarterCopyWith(_FinancialsQuarter value, $Res Function(_FinancialsQuarter) _then) = __$FinancialsQuarterCopyWithImpl;
@override @useResult
$Res call({
 String period, String reportDate, String revenue, String netIncome, Decimal eps, Decimal epsEstimate, Decimal revenueGrowth, Decimal netIncomeGrowth
});




}
/// @nodoc
class __$FinancialsQuarterCopyWithImpl<$Res>
    implements _$FinancialsQuarterCopyWith<$Res> {
  __$FinancialsQuarterCopyWithImpl(this._self, this._then);

  final _FinancialsQuarter _self;
  final $Res Function(_FinancialsQuarter) _then;

/// Create a copy of FinancialsQuarter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? reportDate = null,Object? revenue = null,Object? netIncome = null,Object? eps = null,Object? epsEstimate = null,Object? revenueGrowth = null,Object? netIncomeGrowth = null,}) {
  return _then(_FinancialsQuarter(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,reportDate: null == reportDate ? _self.reportDate : reportDate // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,netIncome: null == netIncome ? _self.netIncome : netIncome // ignore: cast_nullable_to_non_nullable
as String,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as Decimal,epsEstimate: null == epsEstimate ? _self.epsEstimate : epsEstimate // ignore: cast_nullable_to_non_nullable
as Decimal,revenueGrowth: null == revenueGrowth ? _self.revenueGrowth : revenueGrowth // ignore: cast_nullable_to_non_nullable
as Decimal,netIncomeGrowth: null == netIncomeGrowth ? _self.netIncomeGrowth : netIncomeGrowth // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}


}

/// @nodoc
mixin _$Financials {

 String get symbol; String get nextEarningsDate; String get nextEarningsQuarter; List<FinancialsQuarter> get quarters;
/// Create a copy of Financials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialsCopyWith<Financials> get copyWith => _$FinancialsCopyWithImpl<Financials>(this as Financials, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Financials&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.nextEarningsDate, nextEarningsDate) || other.nextEarningsDate == nextEarningsDate)&&(identical(other.nextEarningsQuarter, nextEarningsQuarter) || other.nextEarningsQuarter == nextEarningsQuarter)&&const DeepCollectionEquality().equals(other.quarters, quarters));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,nextEarningsDate,nextEarningsQuarter,const DeepCollectionEquality().hash(quarters));

@override
String toString() {
  return 'Financials(symbol: $symbol, nextEarningsDate: $nextEarningsDate, nextEarningsQuarter: $nextEarningsQuarter, quarters: $quarters)';
}


}

/// @nodoc
abstract mixin class $FinancialsCopyWith<$Res>  {
  factory $FinancialsCopyWith(Financials value, $Res Function(Financials) _then) = _$FinancialsCopyWithImpl;
@useResult
$Res call({
 String symbol, String nextEarningsDate, String nextEarningsQuarter, List<FinancialsQuarter> quarters
});




}
/// @nodoc
class _$FinancialsCopyWithImpl<$Res>
    implements $FinancialsCopyWith<$Res> {
  _$FinancialsCopyWithImpl(this._self, this._then);

  final Financials _self;
  final $Res Function(Financials) _then;

/// Create a copy of Financials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? nextEarningsDate = null,Object? nextEarningsQuarter = null,Object? quarters = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,nextEarningsDate: null == nextEarningsDate ? _self.nextEarningsDate : nextEarningsDate // ignore: cast_nullable_to_non_nullable
as String,nextEarningsQuarter: null == nextEarningsQuarter ? _self.nextEarningsQuarter : nextEarningsQuarter // ignore: cast_nullable_to_non_nullable
as String,quarters: null == quarters ? _self.quarters : quarters // ignore: cast_nullable_to_non_nullable
as List<FinancialsQuarter>,
  ));
}

}


/// Adds pattern-matching-related methods to [Financials].
extension FinancialsPatterns on Financials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Financials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Financials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Financials value)  $default,){
final _that = this;
switch (_that) {
case _Financials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Financials value)?  $default,){
final _that = this;
switch (_that) {
case _Financials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String nextEarningsDate,  String nextEarningsQuarter,  List<FinancialsQuarter> quarters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Financials() when $default != null:
return $default(_that.symbol,_that.nextEarningsDate,_that.nextEarningsQuarter,_that.quarters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String nextEarningsDate,  String nextEarningsQuarter,  List<FinancialsQuarter> quarters)  $default,) {final _that = this;
switch (_that) {
case _Financials():
return $default(_that.symbol,_that.nextEarningsDate,_that.nextEarningsQuarter,_that.quarters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String nextEarningsDate,  String nextEarningsQuarter,  List<FinancialsQuarter> quarters)?  $default,) {final _that = this;
switch (_that) {
case _Financials() when $default != null:
return $default(_that.symbol,_that.nextEarningsDate,_that.nextEarningsQuarter,_that.quarters);case _:
  return null;

}
}

}

/// @nodoc


class _Financials implements Financials {
  const _Financials({required this.symbol, required this.nextEarningsDate, required this.nextEarningsQuarter, required final  List<FinancialsQuarter> quarters}): _quarters = quarters;
  

@override final  String symbol;
@override final  String nextEarningsDate;
@override final  String nextEarningsQuarter;
 final  List<FinancialsQuarter> _quarters;
@override List<FinancialsQuarter> get quarters {
  if (_quarters is EqualUnmodifiableListView) return _quarters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quarters);
}


/// Create a copy of Financials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialsCopyWith<_Financials> get copyWith => __$FinancialsCopyWithImpl<_Financials>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Financials&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.nextEarningsDate, nextEarningsDate) || other.nextEarningsDate == nextEarningsDate)&&(identical(other.nextEarningsQuarter, nextEarningsQuarter) || other.nextEarningsQuarter == nextEarningsQuarter)&&const DeepCollectionEquality().equals(other._quarters, _quarters));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,nextEarningsDate,nextEarningsQuarter,const DeepCollectionEquality().hash(_quarters));

@override
String toString() {
  return 'Financials(symbol: $symbol, nextEarningsDate: $nextEarningsDate, nextEarningsQuarter: $nextEarningsQuarter, quarters: $quarters)';
}


}

/// @nodoc
abstract mixin class _$FinancialsCopyWith<$Res> implements $FinancialsCopyWith<$Res> {
  factory _$FinancialsCopyWith(_Financials value, $Res Function(_Financials) _then) = __$FinancialsCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String nextEarningsDate, String nextEarningsQuarter, List<FinancialsQuarter> quarters
});




}
/// @nodoc
class __$FinancialsCopyWithImpl<$Res>
    implements _$FinancialsCopyWith<$Res> {
  __$FinancialsCopyWithImpl(this._self, this._then);

  final _Financials _self;
  final $Res Function(_Financials) _then;

/// Create a copy of Financials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? nextEarningsDate = null,Object? nextEarningsQuarter = null,Object? quarters = null,}) {
  return _then(_Financials(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,nextEarningsDate: null == nextEarningsDate ? _self.nextEarningsDate : nextEarningsDate // ignore: cast_nullable_to_non_nullable
as String,nextEarningsQuarter: null == nextEarningsQuarter ? _self.nextEarningsQuarter : nextEarningsQuarter // ignore: cast_nullable_to_non_nullable
as String,quarters: null == quarters ? _self._quarters : quarters // ignore: cast_nullable_to_non_nullable
as List<FinancialsQuarter>,
  ));
}


}

// dart format on
