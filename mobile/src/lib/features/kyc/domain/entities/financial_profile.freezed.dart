// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financial_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FinancialProfile {

 IncomeRange get annualIncomeRange; NetWorthRange get totalNetWorthRange; NetWorthRange get liquidNetWorthRange; List<FundsSource> get fundsSources; EmploymentStatus get employmentStatus; String? get employerName;
/// Create a copy of FinancialProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialProfileCopyWith<FinancialProfile> get copyWith => _$FinancialProfileCopyWithImpl<FinancialProfile>(this as FinancialProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialProfile&&(identical(other.annualIncomeRange, annualIncomeRange) || other.annualIncomeRange == annualIncomeRange)&&(identical(other.totalNetWorthRange, totalNetWorthRange) || other.totalNetWorthRange == totalNetWorthRange)&&(identical(other.liquidNetWorthRange, liquidNetWorthRange) || other.liquidNetWorthRange == liquidNetWorthRange)&&const DeepCollectionEquality().equals(other.fundsSources, fundsSources)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employerName, employerName) || other.employerName == employerName));
}


@override
int get hashCode => Object.hash(runtimeType,annualIncomeRange,totalNetWorthRange,liquidNetWorthRange,const DeepCollectionEquality().hash(fundsSources),employmentStatus,employerName);

@override
String toString() {
  return 'FinancialProfile(annualIncomeRange: $annualIncomeRange, totalNetWorthRange: $totalNetWorthRange, liquidNetWorthRange: $liquidNetWorthRange, fundsSources: $fundsSources, employmentStatus: $employmentStatus, employerName: $employerName)';
}


}

/// @nodoc
abstract mixin class $FinancialProfileCopyWith<$Res>  {
  factory $FinancialProfileCopyWith(FinancialProfile value, $Res Function(FinancialProfile) _then) = _$FinancialProfileCopyWithImpl;
@useResult
$Res call({
 IncomeRange annualIncomeRange, NetWorthRange totalNetWorthRange, NetWorthRange liquidNetWorthRange, List<FundsSource> fundsSources, EmploymentStatus employmentStatus, String? employerName
});




}
/// @nodoc
class _$FinancialProfileCopyWithImpl<$Res>
    implements $FinancialProfileCopyWith<$Res> {
  _$FinancialProfileCopyWithImpl(this._self, this._then);

  final FinancialProfile _self;
  final $Res Function(FinancialProfile) _then;

/// Create a copy of FinancialProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? annualIncomeRange = null,Object? totalNetWorthRange = null,Object? liquidNetWorthRange = null,Object? fundsSources = null,Object? employmentStatus = null,Object? employerName = freezed,}) {
  return _then(_self.copyWith(
annualIncomeRange: null == annualIncomeRange ? _self.annualIncomeRange : annualIncomeRange // ignore: cast_nullable_to_non_nullable
as IncomeRange,totalNetWorthRange: null == totalNetWorthRange ? _self.totalNetWorthRange : totalNetWorthRange // ignore: cast_nullable_to_non_nullable
as NetWorthRange,liquidNetWorthRange: null == liquidNetWorthRange ? _self.liquidNetWorthRange : liquidNetWorthRange // ignore: cast_nullable_to_non_nullable
as NetWorthRange,fundsSources: null == fundsSources ? _self.fundsSources : fundsSources // ignore: cast_nullable_to_non_nullable
as List<FundsSource>,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as EmploymentStatus,employerName: freezed == employerName ? _self.employerName : employerName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialProfile].
extension FinancialProfilePatterns on FinancialProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialProfile value)  $default,){
final _that = this;
switch (_that) {
case _FinancialProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialProfile value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IncomeRange annualIncomeRange,  NetWorthRange totalNetWorthRange,  NetWorthRange liquidNetWorthRange,  List<FundsSource> fundsSources,  EmploymentStatus employmentStatus,  String? employerName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialProfile() when $default != null:
return $default(_that.annualIncomeRange,_that.totalNetWorthRange,_that.liquidNetWorthRange,_that.fundsSources,_that.employmentStatus,_that.employerName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IncomeRange annualIncomeRange,  NetWorthRange totalNetWorthRange,  NetWorthRange liquidNetWorthRange,  List<FundsSource> fundsSources,  EmploymentStatus employmentStatus,  String? employerName)  $default,) {final _that = this;
switch (_that) {
case _FinancialProfile():
return $default(_that.annualIncomeRange,_that.totalNetWorthRange,_that.liquidNetWorthRange,_that.fundsSources,_that.employmentStatus,_that.employerName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IncomeRange annualIncomeRange,  NetWorthRange totalNetWorthRange,  NetWorthRange liquidNetWorthRange,  List<FundsSource> fundsSources,  EmploymentStatus employmentStatus,  String? employerName)?  $default,) {final _that = this;
switch (_that) {
case _FinancialProfile() when $default != null:
return $default(_that.annualIncomeRange,_that.totalNetWorthRange,_that.liquidNetWorthRange,_that.fundsSources,_that.employmentStatus,_that.employerName);case _:
  return null;

}
}

}

/// @nodoc


class _FinancialProfile extends FinancialProfile {
  const _FinancialProfile({required this.annualIncomeRange, required this.totalNetWorthRange, required this.liquidNetWorthRange, required final  List<FundsSource> fundsSources, required this.employmentStatus, this.employerName}): _fundsSources = fundsSources,super._();
  

@override final  IncomeRange annualIncomeRange;
@override final  NetWorthRange totalNetWorthRange;
@override final  NetWorthRange liquidNetWorthRange;
 final  List<FundsSource> _fundsSources;
@override List<FundsSource> get fundsSources {
  if (_fundsSources is EqualUnmodifiableListView) return _fundsSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fundsSources);
}

@override final  EmploymentStatus employmentStatus;
@override final  String? employerName;

/// Create a copy of FinancialProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialProfileCopyWith<_FinancialProfile> get copyWith => __$FinancialProfileCopyWithImpl<_FinancialProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialProfile&&(identical(other.annualIncomeRange, annualIncomeRange) || other.annualIncomeRange == annualIncomeRange)&&(identical(other.totalNetWorthRange, totalNetWorthRange) || other.totalNetWorthRange == totalNetWorthRange)&&(identical(other.liquidNetWorthRange, liquidNetWorthRange) || other.liquidNetWorthRange == liquidNetWorthRange)&&const DeepCollectionEquality().equals(other._fundsSources, _fundsSources)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employerName, employerName) || other.employerName == employerName));
}


@override
int get hashCode => Object.hash(runtimeType,annualIncomeRange,totalNetWorthRange,liquidNetWorthRange,const DeepCollectionEquality().hash(_fundsSources),employmentStatus,employerName);

@override
String toString() {
  return 'FinancialProfile(annualIncomeRange: $annualIncomeRange, totalNetWorthRange: $totalNetWorthRange, liquidNetWorthRange: $liquidNetWorthRange, fundsSources: $fundsSources, employmentStatus: $employmentStatus, employerName: $employerName)';
}


}

/// @nodoc
abstract mixin class _$FinancialProfileCopyWith<$Res> implements $FinancialProfileCopyWith<$Res> {
  factory _$FinancialProfileCopyWith(_FinancialProfile value, $Res Function(_FinancialProfile) _then) = __$FinancialProfileCopyWithImpl;
@override @useResult
$Res call({
 IncomeRange annualIncomeRange, NetWorthRange totalNetWorthRange, NetWorthRange liquidNetWorthRange, List<FundsSource> fundsSources, EmploymentStatus employmentStatus, String? employerName
});




}
/// @nodoc
class __$FinancialProfileCopyWithImpl<$Res>
    implements _$FinancialProfileCopyWith<$Res> {
  __$FinancialProfileCopyWithImpl(this._self, this._then);

  final _FinancialProfile _self;
  final $Res Function(_FinancialProfile) _then;

/// Create a copy of FinancialProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? annualIncomeRange = null,Object? totalNetWorthRange = null,Object? liquidNetWorthRange = null,Object? fundsSources = null,Object? employmentStatus = null,Object? employerName = freezed,}) {
  return _then(_FinancialProfile(
annualIncomeRange: null == annualIncomeRange ? _self.annualIncomeRange : annualIncomeRange // ignore: cast_nullable_to_non_nullable
as IncomeRange,totalNetWorthRange: null == totalNetWorthRange ? _self.totalNetWorthRange : totalNetWorthRange // ignore: cast_nullable_to_non_nullable
as NetWorthRange,liquidNetWorthRange: null == liquidNetWorthRange ? _self.liquidNetWorthRange : liquidNetWorthRange // ignore: cast_nullable_to_non_nullable
as NetWorthRange,fundsSources: null == fundsSources ? _self._fundsSources : fundsSources // ignore: cast_nullable_to_non_nullable
as List<FundsSource>,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as EmploymentStatus,employerName: freezed == employerName ? _self.employerName : employerName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
