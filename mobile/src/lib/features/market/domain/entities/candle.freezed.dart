// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'candle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Candle {

/// Candle open time (UTC). Represents the start of the period.
 DateTime get t;/// Opening price.
 Decimal get o;/// Highest price in the period.
 Decimal get h;/// Lowest price in the period.
 Decimal get l;/// Closing price.
 Decimal get c;/// Trade volume (shares).
 int get v;/// Number of trades in the period.
 int get n;
/// Create a copy of Candle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandleCopyWith<Candle> get copyWith => _$CandleCopyWithImpl<Candle>(this as Candle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Candle&&(identical(other.t, t) || other.t == t)&&(identical(other.o, o) || other.o == o)&&(identical(other.h, h) || other.h == h)&&(identical(other.l, l) || other.l == l)&&(identical(other.c, c) || other.c == c)&&(identical(other.v, v) || other.v == v)&&(identical(other.n, n) || other.n == n));
}


@override
int get hashCode => Object.hash(runtimeType,t,o,h,l,c,v,n);

@override
String toString() {
  return 'Candle(t: $t, o: $o, h: $h, l: $l, c: $c, v: $v, n: $n)';
}


}

/// @nodoc
abstract mixin class $CandleCopyWith<$Res>  {
  factory $CandleCopyWith(Candle value, $Res Function(Candle) _then) = _$CandleCopyWithImpl;
@useResult
$Res call({
 DateTime t, Decimal o, Decimal h, Decimal l, Decimal c, int v, int n
});




}
/// @nodoc
class _$CandleCopyWithImpl<$Res>
    implements $CandleCopyWith<$Res> {
  _$CandleCopyWithImpl(this._self, this._then);

  final Candle _self;
  final $Res Function(Candle) _then;

/// Create a copy of Candle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = null,Object? o = null,Object? h = null,Object? l = null,Object? c = null,Object? v = null,Object? n = null,}) {
  return _then(_self.copyWith(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as DateTime,o: null == o ? _self.o : o // ignore: cast_nullable_to_non_nullable
as Decimal,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as Decimal,l: null == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as Decimal,c: null == c ? _self.c : c // ignore: cast_nullable_to_non_nullable
as Decimal,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Candle].
extension CandlePatterns on Candle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Candle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Candle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Candle value)  $default,){
final _that = this;
switch (_that) {
case _Candle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Candle value)?  $default,){
final _that = this;
switch (_that) {
case _Candle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime t,  Decimal o,  Decimal h,  Decimal l,  Decimal c,  int v,  int n)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Candle() when $default != null:
return $default(_that.t,_that.o,_that.h,_that.l,_that.c,_that.v,_that.n);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime t,  Decimal o,  Decimal h,  Decimal l,  Decimal c,  int v,  int n)  $default,) {final _that = this;
switch (_that) {
case _Candle():
return $default(_that.t,_that.o,_that.h,_that.l,_that.c,_that.v,_that.n);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime t,  Decimal o,  Decimal h,  Decimal l,  Decimal c,  int v,  int n)?  $default,) {final _that = this;
switch (_that) {
case _Candle() when $default != null:
return $default(_that.t,_that.o,_that.h,_that.l,_that.c,_that.v,_that.n);case _:
  return null;

}
}

}

/// @nodoc


class _Candle implements Candle {
  const _Candle({required this.t, required this.o, required this.h, required this.l, required this.c, required this.v, required this.n});
  

/// Candle open time (UTC). Represents the start of the period.
@override final  DateTime t;
/// Opening price.
@override final  Decimal o;
/// Highest price in the period.
@override final  Decimal h;
/// Lowest price in the period.
@override final  Decimal l;
/// Closing price.
@override final  Decimal c;
/// Trade volume (shares).
@override final  int v;
/// Number of trades in the period.
@override final  int n;

/// Create a copy of Candle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandleCopyWith<_Candle> get copyWith => __$CandleCopyWithImpl<_Candle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Candle&&(identical(other.t, t) || other.t == t)&&(identical(other.o, o) || other.o == o)&&(identical(other.h, h) || other.h == h)&&(identical(other.l, l) || other.l == l)&&(identical(other.c, c) || other.c == c)&&(identical(other.v, v) || other.v == v)&&(identical(other.n, n) || other.n == n));
}


@override
int get hashCode => Object.hash(runtimeType,t,o,h,l,c,v,n);

@override
String toString() {
  return 'Candle(t: $t, o: $o, h: $h, l: $l, c: $c, v: $v, n: $n)';
}


}

/// @nodoc
abstract mixin class _$CandleCopyWith<$Res> implements $CandleCopyWith<$Res> {
  factory _$CandleCopyWith(_Candle value, $Res Function(_Candle) _then) = __$CandleCopyWithImpl;
@override @useResult
$Res call({
 DateTime t, Decimal o, Decimal h, Decimal l, Decimal c, int v, int n
});




}
/// @nodoc
class __$CandleCopyWithImpl<$Res>
    implements _$CandleCopyWith<$Res> {
  __$CandleCopyWithImpl(this._self, this._then);

  final _Candle _self;
  final $Res Function(_Candle) _then;

/// Create a copy of Candle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = null,Object? o = null,Object? h = null,Object? l = null,Object? c = null,Object? v = null,Object? n = null,}) {
  return _then(_Candle(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as DateTime,o: null == o ? _self.o : o // ignore: cast_nullable_to_non_nullable
as Decimal,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as Decimal,l: null == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as Decimal,c: null == c ? _self.c : c // ignore: cast_nullable_to_non_nullable
as Decimal,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
