// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchResult {

 String get symbol;/// Company English name.
 String get name;/// Company Chinese name. Empty string if not available.
 String get nameZh;/// Market identifier: "US" or "HK".
 String get market;/// Latest price (4 decimal places for US, 3 for HK).
 Decimal get price;/// Price change percentage (2 decimal places, signed).
 Decimal get changePct;/// True when the quote is delayed by 15 minutes (guest/unauthenticated user).
 bool get delayed;
/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultCopyWith<SearchResult> get copyWith => _$SearchResultCopyWithImpl<SearchResult>(this as SearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResult&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.delayed, delayed) || other.delayed == delayed));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,name,nameZh,market,price,changePct,delayed);

@override
String toString() {
  return 'SearchResult(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, changePct: $changePct, delayed: $delayed)';
}


}

/// @nodoc
abstract mixin class $SearchResultCopyWith<$Res>  {
  factory $SearchResultCopyWith(SearchResult value, $Res Function(SearchResult) _then) = _$SearchResultCopyWithImpl;
@useResult
$Res call({
 String symbol, String name, String nameZh, String market, Decimal price, Decimal changePct, bool delayed
});




}
/// @nodoc
class _$SearchResultCopyWithImpl<$Res>
    implements $SearchResultCopyWith<$Res> {
  _$SearchResultCopyWithImpl(this._self, this._then);

  final SearchResult _self;
  final $Res Function(SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? changePct = null,Object? delayed = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResult].
extension SearchResultPatterns on SearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResult value)  $default,){
final _that = this;
switch (_that) {
case _SearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal changePct,  bool delayed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.changePct,_that.delayed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal changePct,  bool delayed)  $default,) {final _that = this;
switch (_that) {
case _SearchResult():
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.changePct,_that.delayed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal changePct,  bool delayed)?  $default,) {final _that = this;
switch (_that) {
case _SearchResult() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.changePct,_that.delayed);case _:
  return null;

}
}

}

/// @nodoc


class _SearchResult implements SearchResult {
  const _SearchResult({required this.symbol, required this.name, required this.nameZh, required this.market, required this.price, required this.changePct, required this.delayed});
  

@override final  String symbol;
/// Company English name.
@override final  String name;
/// Company Chinese name. Empty string if not available.
@override final  String nameZh;
/// Market identifier: "US" or "HK".
@override final  String market;
/// Latest price (4 decimal places for US, 3 for HK).
@override final  Decimal price;
/// Price change percentage (2 decimal places, signed).
@override final  Decimal changePct;
/// True when the quote is delayed by 15 minutes (guest/unauthenticated user).
@override final  bool delayed;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultCopyWith<_SearchResult> get copyWith => __$SearchResultCopyWithImpl<_SearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResult&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.delayed, delayed) || other.delayed == delayed));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,name,nameZh,market,price,changePct,delayed);

@override
String toString() {
  return 'SearchResult(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, changePct: $changePct, delayed: $delayed)';
}


}

/// @nodoc
abstract mixin class _$SearchResultCopyWith<$Res> implements $SearchResultCopyWith<$Res> {
  factory _$SearchResultCopyWith(_SearchResult value, $Res Function(_SearchResult) _then) = __$SearchResultCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name, String nameZh, String market, Decimal price, Decimal changePct, bool delayed
});




}
/// @nodoc
class __$SearchResultCopyWithImpl<$Res>
    implements _$SearchResultCopyWith<$Res> {
  __$SearchResultCopyWithImpl(this._self, this._then);

  final _SearchResult _self;
  final $Res Function(_SearchResult) _then;

/// Create a copy of SearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? changePct = null,Object? delayed = null,}) {
  return _then(_SearchResult(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
