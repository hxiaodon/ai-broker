// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TradeRecord {

 String get tradeId; TradeSide get side; int get qty; Decimal get price; Decimal get amount; Decimal get fee; DateTime get executedAt; bool get washSale;
/// Create a copy of TradeRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeRecordCopyWith<TradeRecord> get copyWith => _$TradeRecordCopyWithImpl<TradeRecord>(this as TradeRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeRecord&&(identical(other.tradeId, tradeId) || other.tradeId == tradeId)&&(identical(other.side, side) || other.side == side)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt)&&(identical(other.washSale, washSale) || other.washSale == washSale));
}


@override
int get hashCode => Object.hash(runtimeType,tradeId,side,qty,price,amount,fee,executedAt,washSale);

@override
String toString() {
  return 'TradeRecord(tradeId: $tradeId, side: $side, qty: $qty, price: $price, amount: $amount, fee: $fee, executedAt: $executedAt, washSale: $washSale)';
}


}

/// @nodoc
abstract mixin class $TradeRecordCopyWith<$Res>  {
  factory $TradeRecordCopyWith(TradeRecord value, $Res Function(TradeRecord) _then) = _$TradeRecordCopyWithImpl;
@useResult
$Res call({
 String tradeId, TradeSide side, int qty, Decimal price, Decimal amount, Decimal fee, DateTime executedAt, bool washSale
});




}
/// @nodoc
class _$TradeRecordCopyWithImpl<$Res>
    implements $TradeRecordCopyWith<$Res> {
  _$TradeRecordCopyWithImpl(this._self, this._then);

  final TradeRecord _self;
  final $Res Function(TradeRecord) _then;

/// Create a copy of TradeRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tradeId = null,Object? side = null,Object? qty = null,Object? price = null,Object? amount = null,Object? fee = null,Object? executedAt = null,Object? washSale = null,}) {
  return _then(_self.copyWith(
tradeId: null == tradeId ? _self.tradeId : tradeId // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as TradeSide,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as Decimal,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as DateTime,washSale: null == washSale ? _self.washSale : washSale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeRecord].
extension TradeRecordPatterns on TradeRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TradeRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TradeRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TradeRecord value)  $default,){
final _that = this;
switch (_that) {
case _TradeRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TradeRecord value)?  $default,){
final _that = this;
switch (_that) {
case _TradeRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tradeId,  TradeSide side,  int qty,  Decimal price,  Decimal amount,  Decimal fee,  DateTime executedAt,  bool washSale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TradeRecord() when $default != null:
return $default(_that.tradeId,_that.side,_that.qty,_that.price,_that.amount,_that.fee,_that.executedAt,_that.washSale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tradeId,  TradeSide side,  int qty,  Decimal price,  Decimal amount,  Decimal fee,  DateTime executedAt,  bool washSale)  $default,) {final _that = this;
switch (_that) {
case _TradeRecord():
return $default(_that.tradeId,_that.side,_that.qty,_that.price,_that.amount,_that.fee,_that.executedAt,_that.washSale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tradeId,  TradeSide side,  int qty,  Decimal price,  Decimal amount,  Decimal fee,  DateTime executedAt,  bool washSale)?  $default,) {final _that = this;
switch (_that) {
case _TradeRecord() when $default != null:
return $default(_that.tradeId,_that.side,_that.qty,_that.price,_that.amount,_that.fee,_that.executedAt,_that.washSale);case _:
  return null;

}
}

}

/// @nodoc


class _TradeRecord implements TradeRecord {
  const _TradeRecord({required this.tradeId, required this.side, required this.qty, required this.price, required this.amount, required this.fee, required this.executedAt, this.washSale = false});
  

@override final  String tradeId;
@override final  TradeSide side;
@override final  int qty;
@override final  Decimal price;
@override final  Decimal amount;
@override final  Decimal fee;
@override final  DateTime executedAt;
@override@JsonKey() final  bool washSale;

/// Create a copy of TradeRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TradeRecordCopyWith<_TradeRecord> get copyWith => __$TradeRecordCopyWithImpl<_TradeRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TradeRecord&&(identical(other.tradeId, tradeId) || other.tradeId == tradeId)&&(identical(other.side, side) || other.side == side)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt)&&(identical(other.washSale, washSale) || other.washSale == washSale));
}


@override
int get hashCode => Object.hash(runtimeType,tradeId,side,qty,price,amount,fee,executedAt,washSale);

@override
String toString() {
  return 'TradeRecord(tradeId: $tradeId, side: $side, qty: $qty, price: $price, amount: $amount, fee: $fee, executedAt: $executedAt, washSale: $washSale)';
}


}

/// @nodoc
abstract mixin class _$TradeRecordCopyWith<$Res> implements $TradeRecordCopyWith<$Res> {
  factory _$TradeRecordCopyWith(_TradeRecord value, $Res Function(_TradeRecord) _then) = __$TradeRecordCopyWithImpl;
@override @useResult
$Res call({
 String tradeId, TradeSide side, int qty, Decimal price, Decimal amount, Decimal fee, DateTime executedAt, bool washSale
});




}
/// @nodoc
class __$TradeRecordCopyWithImpl<$Res>
    implements _$TradeRecordCopyWith<$Res> {
  __$TradeRecordCopyWithImpl(this._self, this._then);

  final _TradeRecord _self;
  final $Res Function(_TradeRecord) _then;

/// Create a copy of TradeRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tradeId = null,Object? side = null,Object? qty = null,Object? price = null,Object? amount = null,Object? fee = null,Object? executedAt = null,Object? washSale = null,}) {
  return _then(_TradeRecord(
tradeId: null == tradeId ? _self.tradeId : tradeId // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as TradeSide,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as Decimal,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as DateTime,washSale: null == washSale ? _self.washSale : washSale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
