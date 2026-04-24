// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sector_allocation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SectorAllocation {

 String get sector; Decimal get marketValue; Decimal get weight;
/// Create a copy of SectorAllocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectorAllocationCopyWith<SectorAllocation> get copyWith => _$SectorAllocationCopyWithImpl<SectorAllocation>(this as SectorAllocation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectorAllocation&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,sector,marketValue,weight);

@override
String toString() {
  return 'SectorAllocation(sector: $sector, marketValue: $marketValue, weight: $weight)';
}


}

/// @nodoc
abstract mixin class $SectorAllocationCopyWith<$Res>  {
  factory $SectorAllocationCopyWith(SectorAllocation value, $Res Function(SectorAllocation) _then) = _$SectorAllocationCopyWithImpl;
@useResult
$Res call({
 String sector, Decimal marketValue, Decimal weight
});




}
/// @nodoc
class _$SectorAllocationCopyWithImpl<$Res>
    implements $SectorAllocationCopyWith<$Res> {
  _$SectorAllocationCopyWithImpl(this._self, this._then);

  final SectorAllocation _self;
  final $Res Function(SectorAllocation) _then;

/// Create a copy of SectorAllocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sector = null,Object? marketValue = null,Object? weight = null,}) {
  return _then(_self.copyWith(
sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}

}


/// Adds pattern-matching-related methods to [SectorAllocation].
extension SectorAllocationPatterns on SectorAllocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SectorAllocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SectorAllocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SectorAllocation value)  $default,){
final _that = this;
switch (_that) {
case _SectorAllocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SectorAllocation value)?  $default,){
final _that = this;
switch (_that) {
case _SectorAllocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sector,  Decimal marketValue,  Decimal weight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SectorAllocation() when $default != null:
return $default(_that.sector,_that.marketValue,_that.weight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sector,  Decimal marketValue,  Decimal weight)  $default,) {final _that = this;
switch (_that) {
case _SectorAllocation():
return $default(_that.sector,_that.marketValue,_that.weight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sector,  Decimal marketValue,  Decimal weight)?  $default,) {final _that = this;
switch (_that) {
case _SectorAllocation() when $default != null:
return $default(_that.sector,_that.marketValue,_that.weight);case _:
  return null;

}
}

}

/// @nodoc


class _SectorAllocation implements SectorAllocation {
  const _SectorAllocation({required this.sector, required this.marketValue, required this.weight});
  

@override final  String sector;
@override final  Decimal marketValue;
@override final  Decimal weight;

/// Create a copy of SectorAllocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectorAllocationCopyWith<_SectorAllocation> get copyWith => __$SectorAllocationCopyWithImpl<_SectorAllocation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SectorAllocation&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,sector,marketValue,weight);

@override
String toString() {
  return 'SectorAllocation(sector: $sector, marketValue: $marketValue, weight: $weight)';
}


}

/// @nodoc
abstract mixin class _$SectorAllocationCopyWith<$Res> implements $SectorAllocationCopyWith<$Res> {
  factory _$SectorAllocationCopyWith(_SectorAllocation value, $Res Function(_SectorAllocation) _then) = __$SectorAllocationCopyWithImpl;
@override @useResult
$Res call({
 String sector, Decimal marketValue, Decimal weight
});




}
/// @nodoc
class __$SectorAllocationCopyWithImpl<$Res>
    implements _$SectorAllocationCopyWith<$Res> {
  __$SectorAllocationCopyWithImpl(this._self, this._then);

  final _SectorAllocation _self;
  final $Res Function(_SectorAllocation) _then;

/// Create a copy of SectorAllocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sector = null,Object? marketValue = null,Object? weight = null,}) {
  return _then(_SectorAllocation(
sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}


}

// dart format on
