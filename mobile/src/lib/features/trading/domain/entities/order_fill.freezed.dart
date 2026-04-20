// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_fill.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderFill {

 String get fillId; String get orderId; int get qty; Decimal get price; String get exchange; DateTime get filledAt;
/// Create a copy of OrderFill
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderFillCopyWith<OrderFill> get copyWith => _$OrderFillCopyWithImpl<OrderFill>(this as OrderFill, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderFill&&(identical(other.fillId, fillId) || other.fillId == fillId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.filledAt, filledAt) || other.filledAt == filledAt));
}


@override
int get hashCode => Object.hash(runtimeType,fillId,orderId,qty,price,exchange,filledAt);

@override
String toString() {
  return 'OrderFill(fillId: $fillId, orderId: $orderId, qty: $qty, price: $price, exchange: $exchange, filledAt: $filledAt)';
}


}

/// @nodoc
abstract mixin class $OrderFillCopyWith<$Res>  {
  factory $OrderFillCopyWith(OrderFill value, $Res Function(OrderFill) _then) = _$OrderFillCopyWithImpl;
@useResult
$Res call({
 String fillId, String orderId, int qty, Decimal price, String exchange, DateTime filledAt
});




}
/// @nodoc
class _$OrderFillCopyWithImpl<$Res>
    implements $OrderFillCopyWith<$Res> {
  _$OrderFillCopyWithImpl(this._self, this._then);

  final OrderFill _self;
  final $Res Function(OrderFill) _then;

/// Create a copy of OrderFill
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fillId = null,Object? orderId = null,Object? qty = null,Object? price = null,Object? exchange = null,Object? filledAt = null,}) {
  return _then(_self.copyWith(
fillId: null == fillId ? _self.fillId : fillId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,filledAt: null == filledAt ? _self.filledAt : filledAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderFill].
extension OrderFillPatterns on OrderFill {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderFill value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderFill() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderFill value)  $default,){
final _that = this;
switch (_that) {
case _OrderFill():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderFill value)?  $default,){
final _that = this;
switch (_that) {
case _OrderFill() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fillId,  String orderId,  int qty,  Decimal price,  String exchange,  DateTime filledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderFill() when $default != null:
return $default(_that.fillId,_that.orderId,_that.qty,_that.price,_that.exchange,_that.filledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fillId,  String orderId,  int qty,  Decimal price,  String exchange,  DateTime filledAt)  $default,) {final _that = this;
switch (_that) {
case _OrderFill():
return $default(_that.fillId,_that.orderId,_that.qty,_that.price,_that.exchange,_that.filledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fillId,  String orderId,  int qty,  Decimal price,  String exchange,  DateTime filledAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderFill() when $default != null:
return $default(_that.fillId,_that.orderId,_that.qty,_that.price,_that.exchange,_that.filledAt);case _:
  return null;

}
}

}

/// @nodoc


class _OrderFill implements OrderFill {
  const _OrderFill({required this.fillId, required this.orderId, required this.qty, required this.price, required this.exchange, required this.filledAt});
  

@override final  String fillId;
@override final  String orderId;
@override final  int qty;
@override final  Decimal price;
@override final  String exchange;
@override final  DateTime filledAt;

/// Create a copy of OrderFill
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderFillCopyWith<_OrderFill> get copyWith => __$OrderFillCopyWithImpl<_OrderFill>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderFill&&(identical(other.fillId, fillId) || other.fillId == fillId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.filledAt, filledAt) || other.filledAt == filledAt));
}


@override
int get hashCode => Object.hash(runtimeType,fillId,orderId,qty,price,exchange,filledAt);

@override
String toString() {
  return 'OrderFill(fillId: $fillId, orderId: $orderId, qty: $qty, price: $price, exchange: $exchange, filledAt: $filledAt)';
}


}

/// @nodoc
abstract mixin class _$OrderFillCopyWith<$Res> implements $OrderFillCopyWith<$Res> {
  factory _$OrderFillCopyWith(_OrderFill value, $Res Function(_OrderFill) _then) = __$OrderFillCopyWithImpl;
@override @useResult
$Res call({
 String fillId, String orderId, int qty, Decimal price, String exchange, DateTime filledAt
});




}
/// @nodoc
class __$OrderFillCopyWithImpl<$Res>
    implements _$OrderFillCopyWith<$Res> {
  __$OrderFillCopyWithImpl(this._self, this._then);

  final _OrderFill _self;
  final $Res Function(_OrderFill) _then;

/// Create a copy of OrderFill
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fillId = null,Object? orderId = null,Object? qty = null,Object? price = null,Object? exchange = null,Object? filledAt = null,}) {
  return _then(_OrderFill(
fillId: null == fillId ? _self.fillId : fillId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,filledAt: null == filledAt ? _self.filledAt : filledAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
