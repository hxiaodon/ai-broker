// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mover_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MoverItem {

/// 1-based ranking position.
 int get rank; String get symbol; String get name;/// Company Chinese name. Empty string if not available.
 String get nameZh; Decimal get price; Decimal get change;/// Percentage change (2 decimal places, signed).
 Decimal get changePct;/// Daily volume (shares).
 int get volume;/// Daily turnover with unit suffix, e.g. "33.31B". Kept as String.
 String get turnover; MarketStatus get marketStatus;
/// Create a copy of MoverItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoverItemCopyWith<MoverItem> get copyWith => _$MoverItemCopyWithImpl<MoverItem>(this as MoverItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoverItem&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus));
}


@override
int get hashCode => Object.hash(runtimeType,rank,symbol,name,nameZh,price,change,changePct,volume,turnover,marketStatus);

@override
String toString() {
  return 'MoverItem(rank: $rank, symbol: $symbol, name: $name, nameZh: $nameZh, price: $price, change: $change, changePct: $changePct, volume: $volume, turnover: $turnover, marketStatus: $marketStatus)';
}


}

/// @nodoc
abstract mixin class $MoverItemCopyWith<$Res>  {
  factory $MoverItemCopyWith(MoverItem value, $Res Function(MoverItem) _then) = _$MoverItemCopyWithImpl;
@useResult
$Res call({
 int rank, String symbol, String name, String nameZh, Decimal price, Decimal change, Decimal changePct, int volume, String turnover, MarketStatus marketStatus
});




}
/// @nodoc
class _$MoverItemCopyWithImpl<$Res>
    implements $MoverItemCopyWith<$Res> {
  _$MoverItemCopyWithImpl(this._self, this._then);

  final MoverItem _self;
  final $Res Function(MoverItem) _then;

/// Create a copy of MoverItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? symbol = null,Object? name = null,Object? nameZh = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? turnover = null,Object? marketStatus = null,}) {
  return _then(_self.copyWith(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as MarketStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [MoverItem].
extension MoverItemPatterns on MoverItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoverItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoverItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoverItem value)  $default,){
final _that = this;
switch (_that) {
case _MoverItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoverItem value)?  $default,){
final _that = this;
switch (_that) {
case _MoverItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String symbol,  String name,  String nameZh,  Decimal price,  Decimal change,  Decimal changePct,  int volume,  String turnover,  MarketStatus marketStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoverItem() when $default != null:
return $default(_that.rank,_that.symbol,_that.name,_that.nameZh,_that.price,_that.change,_that.changePct,_that.volume,_that.turnover,_that.marketStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String symbol,  String name,  String nameZh,  Decimal price,  Decimal change,  Decimal changePct,  int volume,  String turnover,  MarketStatus marketStatus)  $default,) {final _that = this;
switch (_that) {
case _MoverItem():
return $default(_that.rank,_that.symbol,_that.name,_that.nameZh,_that.price,_that.change,_that.changePct,_that.volume,_that.turnover,_that.marketStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String symbol,  String name,  String nameZh,  Decimal price,  Decimal change,  Decimal changePct,  int volume,  String turnover,  MarketStatus marketStatus)?  $default,) {final _that = this;
switch (_that) {
case _MoverItem() when $default != null:
return $default(_that.rank,_that.symbol,_that.name,_that.nameZh,_that.price,_that.change,_that.changePct,_that.volume,_that.turnover,_that.marketStatus);case _:
  return null;

}
}

}

/// @nodoc


class _MoverItem implements MoverItem {
  const _MoverItem({required this.rank, required this.symbol, required this.name, required this.nameZh, required this.price, required this.change, required this.changePct, required this.volume, required this.turnover, required this.marketStatus});
  

/// 1-based ranking position.
@override final  int rank;
@override final  String symbol;
@override final  String name;
/// Company Chinese name. Empty string if not available.
@override final  String nameZh;
@override final  Decimal price;
@override final  Decimal change;
/// Percentage change (2 decimal places, signed).
@override final  Decimal changePct;
/// Daily volume (shares).
@override final  int volume;
/// Daily turnover with unit suffix, e.g. "33.31B". Kept as String.
@override final  String turnover;
@override final  MarketStatus marketStatus;

/// Create a copy of MoverItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoverItemCopyWith<_MoverItem> get copyWith => __$MoverItemCopyWithImpl<_MoverItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoverItem&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus));
}


@override
int get hashCode => Object.hash(runtimeType,rank,symbol,name,nameZh,price,change,changePct,volume,turnover,marketStatus);

@override
String toString() {
  return 'MoverItem(rank: $rank, symbol: $symbol, name: $name, nameZh: $nameZh, price: $price, change: $change, changePct: $changePct, volume: $volume, turnover: $turnover, marketStatus: $marketStatus)';
}


}

/// @nodoc
abstract mixin class _$MoverItemCopyWith<$Res> implements $MoverItemCopyWith<$Res> {
  factory _$MoverItemCopyWith(_MoverItem value, $Res Function(_MoverItem) _then) = __$MoverItemCopyWithImpl;
@override @useResult
$Res call({
 int rank, String symbol, String name, String nameZh, Decimal price, Decimal change, Decimal changePct, int volume, String turnover, MarketStatus marketStatus
});




}
/// @nodoc
class __$MoverItemCopyWithImpl<$Res>
    implements _$MoverItemCopyWith<$Res> {
  __$MoverItemCopyWithImpl(this._self, this._then);

  final _MoverItem _self;
  final $Res Function(_MoverItem) _then;

/// Create a copy of MoverItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? symbol = null,Object? name = null,Object? nameZh = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? turnover = null,Object? marketStatus = null,}) {
  return _then(_MoverItem(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as MarketStatus,
  ));
}


}

// dart format on
