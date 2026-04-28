// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_assessment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestmentAssessment {

 InvestmentObjective get investmentObjective; RiskTolerance get riskTolerance; TimeHorizon get timeHorizon; int get stockExperienceYears; int get optionsExperienceYears; int get marginExperienceYears; LiquidityNeed get liquidityNeed;
/// Create a copy of InvestmentAssessment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentAssessmentCopyWith<InvestmentAssessment> get copyWith => _$InvestmentAssessmentCopyWithImpl<InvestmentAssessment>(this as InvestmentAssessment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentAssessment&&(identical(other.investmentObjective, investmentObjective) || other.investmentObjective == investmentObjective)&&(identical(other.riskTolerance, riskTolerance) || other.riskTolerance == riskTolerance)&&(identical(other.timeHorizon, timeHorizon) || other.timeHorizon == timeHorizon)&&(identical(other.stockExperienceYears, stockExperienceYears) || other.stockExperienceYears == stockExperienceYears)&&(identical(other.optionsExperienceYears, optionsExperienceYears) || other.optionsExperienceYears == optionsExperienceYears)&&(identical(other.marginExperienceYears, marginExperienceYears) || other.marginExperienceYears == marginExperienceYears)&&(identical(other.liquidityNeed, liquidityNeed) || other.liquidityNeed == liquidityNeed));
}


@override
int get hashCode => Object.hash(runtimeType,investmentObjective,riskTolerance,timeHorizon,stockExperienceYears,optionsExperienceYears,marginExperienceYears,liquidityNeed);

@override
String toString() {
  return 'InvestmentAssessment(investmentObjective: $investmentObjective, riskTolerance: $riskTolerance, timeHorizon: $timeHorizon, stockExperienceYears: $stockExperienceYears, optionsExperienceYears: $optionsExperienceYears, marginExperienceYears: $marginExperienceYears, liquidityNeed: $liquidityNeed)';
}


}

/// @nodoc
abstract mixin class $InvestmentAssessmentCopyWith<$Res>  {
  factory $InvestmentAssessmentCopyWith(InvestmentAssessment value, $Res Function(InvestmentAssessment) _then) = _$InvestmentAssessmentCopyWithImpl;
@useResult
$Res call({
 InvestmentObjective investmentObjective, RiskTolerance riskTolerance, TimeHorizon timeHorizon, int stockExperienceYears, int optionsExperienceYears, int marginExperienceYears, LiquidityNeed liquidityNeed
});




}
/// @nodoc
class _$InvestmentAssessmentCopyWithImpl<$Res>
    implements $InvestmentAssessmentCopyWith<$Res> {
  _$InvestmentAssessmentCopyWithImpl(this._self, this._then);

  final InvestmentAssessment _self;
  final $Res Function(InvestmentAssessment) _then;

/// Create a copy of InvestmentAssessment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investmentObjective = null,Object? riskTolerance = null,Object? timeHorizon = null,Object? stockExperienceYears = null,Object? optionsExperienceYears = null,Object? marginExperienceYears = null,Object? liquidityNeed = null,}) {
  return _then(_self.copyWith(
investmentObjective: null == investmentObjective ? _self.investmentObjective : investmentObjective // ignore: cast_nullable_to_non_nullable
as InvestmentObjective,riskTolerance: null == riskTolerance ? _self.riskTolerance : riskTolerance // ignore: cast_nullable_to_non_nullable
as RiskTolerance,timeHorizon: null == timeHorizon ? _self.timeHorizon : timeHorizon // ignore: cast_nullable_to_non_nullable
as TimeHorizon,stockExperienceYears: null == stockExperienceYears ? _self.stockExperienceYears : stockExperienceYears // ignore: cast_nullable_to_non_nullable
as int,optionsExperienceYears: null == optionsExperienceYears ? _self.optionsExperienceYears : optionsExperienceYears // ignore: cast_nullable_to_non_nullable
as int,marginExperienceYears: null == marginExperienceYears ? _self.marginExperienceYears : marginExperienceYears // ignore: cast_nullable_to_non_nullable
as int,liquidityNeed: null == liquidityNeed ? _self.liquidityNeed : liquidityNeed // ignore: cast_nullable_to_non_nullable
as LiquidityNeed,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestmentAssessment].
extension InvestmentAssessmentPatterns on InvestmentAssessment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestmentAssessment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestmentAssessment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestmentAssessment value)  $default,){
final _that = this;
switch (_that) {
case _InvestmentAssessment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestmentAssessment value)?  $default,){
final _that = this;
switch (_that) {
case _InvestmentAssessment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InvestmentObjective investmentObjective,  RiskTolerance riskTolerance,  TimeHorizon timeHorizon,  int stockExperienceYears,  int optionsExperienceYears,  int marginExperienceYears,  LiquidityNeed liquidityNeed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestmentAssessment() when $default != null:
return $default(_that.investmentObjective,_that.riskTolerance,_that.timeHorizon,_that.stockExperienceYears,_that.optionsExperienceYears,_that.marginExperienceYears,_that.liquidityNeed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InvestmentObjective investmentObjective,  RiskTolerance riskTolerance,  TimeHorizon timeHorizon,  int stockExperienceYears,  int optionsExperienceYears,  int marginExperienceYears,  LiquidityNeed liquidityNeed)  $default,) {final _that = this;
switch (_that) {
case _InvestmentAssessment():
return $default(_that.investmentObjective,_that.riskTolerance,_that.timeHorizon,_that.stockExperienceYears,_that.optionsExperienceYears,_that.marginExperienceYears,_that.liquidityNeed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InvestmentObjective investmentObjective,  RiskTolerance riskTolerance,  TimeHorizon timeHorizon,  int stockExperienceYears,  int optionsExperienceYears,  int marginExperienceYears,  LiquidityNeed liquidityNeed)?  $default,) {final _that = this;
switch (_that) {
case _InvestmentAssessment() when $default != null:
return $default(_that.investmentObjective,_that.riskTolerance,_that.timeHorizon,_that.stockExperienceYears,_that.optionsExperienceYears,_that.marginExperienceYears,_that.liquidityNeed);case _:
  return null;

}
}

}

/// @nodoc


class _InvestmentAssessment implements InvestmentAssessment {
  const _InvestmentAssessment({required this.investmentObjective, required this.riskTolerance, required this.timeHorizon, required this.stockExperienceYears, this.optionsExperienceYears = 0, this.marginExperienceYears = 0, required this.liquidityNeed});
  

@override final  InvestmentObjective investmentObjective;
@override final  RiskTolerance riskTolerance;
@override final  TimeHorizon timeHorizon;
@override final  int stockExperienceYears;
@override@JsonKey() final  int optionsExperienceYears;
@override@JsonKey() final  int marginExperienceYears;
@override final  LiquidityNeed liquidityNeed;

/// Create a copy of InvestmentAssessment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestmentAssessmentCopyWith<_InvestmentAssessment> get copyWith => __$InvestmentAssessmentCopyWithImpl<_InvestmentAssessment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestmentAssessment&&(identical(other.investmentObjective, investmentObjective) || other.investmentObjective == investmentObjective)&&(identical(other.riskTolerance, riskTolerance) || other.riskTolerance == riskTolerance)&&(identical(other.timeHorizon, timeHorizon) || other.timeHorizon == timeHorizon)&&(identical(other.stockExperienceYears, stockExperienceYears) || other.stockExperienceYears == stockExperienceYears)&&(identical(other.optionsExperienceYears, optionsExperienceYears) || other.optionsExperienceYears == optionsExperienceYears)&&(identical(other.marginExperienceYears, marginExperienceYears) || other.marginExperienceYears == marginExperienceYears)&&(identical(other.liquidityNeed, liquidityNeed) || other.liquidityNeed == liquidityNeed));
}


@override
int get hashCode => Object.hash(runtimeType,investmentObjective,riskTolerance,timeHorizon,stockExperienceYears,optionsExperienceYears,marginExperienceYears,liquidityNeed);

@override
String toString() {
  return 'InvestmentAssessment(investmentObjective: $investmentObjective, riskTolerance: $riskTolerance, timeHorizon: $timeHorizon, stockExperienceYears: $stockExperienceYears, optionsExperienceYears: $optionsExperienceYears, marginExperienceYears: $marginExperienceYears, liquidityNeed: $liquidityNeed)';
}


}

/// @nodoc
abstract mixin class _$InvestmentAssessmentCopyWith<$Res> implements $InvestmentAssessmentCopyWith<$Res> {
  factory _$InvestmentAssessmentCopyWith(_InvestmentAssessment value, $Res Function(_InvestmentAssessment) _then) = __$InvestmentAssessmentCopyWithImpl;
@override @useResult
$Res call({
 InvestmentObjective investmentObjective, RiskTolerance riskTolerance, TimeHorizon timeHorizon, int stockExperienceYears, int optionsExperienceYears, int marginExperienceYears, LiquidityNeed liquidityNeed
});




}
/// @nodoc
class __$InvestmentAssessmentCopyWithImpl<$Res>
    implements _$InvestmentAssessmentCopyWith<$Res> {
  __$InvestmentAssessmentCopyWithImpl(this._self, this._then);

  final _InvestmentAssessment _self;
  final $Res Function(_InvestmentAssessment) _then;

/// Create a copy of InvestmentAssessment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investmentObjective = null,Object? riskTolerance = null,Object? timeHorizon = null,Object? stockExperienceYears = null,Object? optionsExperienceYears = null,Object? marginExperienceYears = null,Object? liquidityNeed = null,}) {
  return _then(_InvestmentAssessment(
investmentObjective: null == investmentObjective ? _self.investmentObjective : investmentObjective // ignore: cast_nullable_to_non_nullable
as InvestmentObjective,riskTolerance: null == riskTolerance ? _self.riskTolerance : riskTolerance // ignore: cast_nullable_to_non_nullable
as RiskTolerance,timeHorizon: null == timeHorizon ? _self.timeHorizon : timeHorizon // ignore: cast_nullable_to_non_nullable
as TimeHorizon,stockExperienceYears: null == stockExperienceYears ? _self.stockExperienceYears : stockExperienceYears // ignore: cast_nullable_to_non_nullable
as int,optionsExperienceYears: null == optionsExperienceYears ? _self.optionsExperienceYears : optionsExperienceYears // ignore: cast_nullable_to_non_nullable
as int,marginExperienceYears: null == marginExperienceYears ? _self.marginExperienceYears : marginExperienceYears // ignore: cast_nullable_to_non_nullable
as int,liquidityNeed: null == liquidityNeed ? _self.liquidityNeed : liquidityNeed // ignore: cast_nullable_to_non_nullable
as LiquidityNeed,
  ));
}


}

// dart format on
