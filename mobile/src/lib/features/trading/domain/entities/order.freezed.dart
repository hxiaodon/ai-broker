// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderFees {

 Decimal get commission; Decimal get exchangeFee; Decimal get secFee; Decimal get finraFee; Decimal get total;
/// Create a copy of OrderFees
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderFeesCopyWith<OrderFees> get copyWith => _$OrderFeesCopyWithImpl<OrderFees>(this as OrderFees, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderFees&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.exchangeFee, exchangeFee) || other.exchangeFee == exchangeFee)&&(identical(other.secFee, secFee) || other.secFee == secFee)&&(identical(other.finraFee, finraFee) || other.finraFee == finraFee)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,commission,exchangeFee,secFee,finraFee,total);

@override
String toString() {
  return 'OrderFees(commission: $commission, exchangeFee: $exchangeFee, secFee: $secFee, finraFee: $finraFee, total: $total)';
}


}

/// @nodoc
abstract mixin class $OrderFeesCopyWith<$Res>  {
  factory $OrderFeesCopyWith(OrderFees value, $Res Function(OrderFees) _then) = _$OrderFeesCopyWithImpl;
@useResult
$Res call({
 Decimal commission, Decimal exchangeFee, Decimal secFee, Decimal finraFee, Decimal total
});




}
/// @nodoc
class _$OrderFeesCopyWithImpl<$Res>
    implements $OrderFeesCopyWith<$Res> {
  _$OrderFeesCopyWithImpl(this._self, this._then);

  final OrderFees _self;
  final $Res Function(OrderFees) _then;

/// Create a copy of OrderFees
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commission = null,Object? exchangeFee = null,Object? secFee = null,Object? finraFee = null,Object? total = null,}) {
  return _then(_self.copyWith(
commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as Decimal,exchangeFee: null == exchangeFee ? _self.exchangeFee : exchangeFee // ignore: cast_nullable_to_non_nullable
as Decimal,secFee: null == secFee ? _self.secFee : secFee // ignore: cast_nullable_to_non_nullable
as Decimal,finraFee: null == finraFee ? _self.finraFee : finraFee // ignore: cast_nullable_to_non_nullable
as Decimal,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderFees].
extension OrderFeesPatterns on OrderFees {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderFees value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderFees() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderFees value)  $default,){
final _that = this;
switch (_that) {
case _OrderFees():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderFees value)?  $default,){
final _that = this;
switch (_that) {
case _OrderFees() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Decimal commission,  Decimal exchangeFee,  Decimal secFee,  Decimal finraFee,  Decimal total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderFees() when $default != null:
return $default(_that.commission,_that.exchangeFee,_that.secFee,_that.finraFee,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Decimal commission,  Decimal exchangeFee,  Decimal secFee,  Decimal finraFee,  Decimal total)  $default,) {final _that = this;
switch (_that) {
case _OrderFees():
return $default(_that.commission,_that.exchangeFee,_that.secFee,_that.finraFee,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Decimal commission,  Decimal exchangeFee,  Decimal secFee,  Decimal finraFee,  Decimal total)?  $default,) {final _that = this;
switch (_that) {
case _OrderFees() when $default != null:
return $default(_that.commission,_that.exchangeFee,_that.secFee,_that.finraFee,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _OrderFees implements OrderFees {
  const _OrderFees({required this.commission, required this.exchangeFee, required this.secFee, required this.finraFee, required this.total});
  

@override final  Decimal commission;
@override final  Decimal exchangeFee;
@override final  Decimal secFee;
@override final  Decimal finraFee;
@override final  Decimal total;

/// Create a copy of OrderFees
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderFeesCopyWith<_OrderFees> get copyWith => __$OrderFeesCopyWithImpl<_OrderFees>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderFees&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.exchangeFee, exchangeFee) || other.exchangeFee == exchangeFee)&&(identical(other.secFee, secFee) || other.secFee == secFee)&&(identical(other.finraFee, finraFee) || other.finraFee == finraFee)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,commission,exchangeFee,secFee,finraFee,total);

@override
String toString() {
  return 'OrderFees(commission: $commission, exchangeFee: $exchangeFee, secFee: $secFee, finraFee: $finraFee, total: $total)';
}


}

/// @nodoc
abstract mixin class _$OrderFeesCopyWith<$Res> implements $OrderFeesCopyWith<$Res> {
  factory _$OrderFeesCopyWith(_OrderFees value, $Res Function(_OrderFees) _then) = __$OrderFeesCopyWithImpl;
@override @useResult
$Res call({
 Decimal commission, Decimal exchangeFee, Decimal secFee, Decimal finraFee, Decimal total
});




}
/// @nodoc
class __$OrderFeesCopyWithImpl<$Res>
    implements _$OrderFeesCopyWith<$Res> {
  __$OrderFeesCopyWithImpl(this._self, this._then);

  final _OrderFees _self;
  final $Res Function(_OrderFees) _then;

/// Create a copy of OrderFees
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commission = null,Object? exchangeFee = null,Object? secFee = null,Object? finraFee = null,Object? total = null,}) {
  return _then(_OrderFees(
commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as Decimal,exchangeFee: null == exchangeFee ? _self.exchangeFee : exchangeFee // ignore: cast_nullable_to_non_nullable
as Decimal,secFee: null == secFee ? _self.secFee : secFee // ignore: cast_nullable_to_non_nullable
as Decimal,finraFee: null == finraFee ? _self.finraFee : finraFee // ignore: cast_nullable_to_non_nullable
as Decimal,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}


}

/// @nodoc
mixin _$Order {

 String get orderId; String get symbol; String get market; OrderSide get side; OrderType get orderType; OrderStatus get status; int get qty; int get filledQty; Decimal? get limitPrice; Decimal? get avgFillPrice; OrderValidity get validity; bool get extendedHours; OrderFees get fees; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.side, side) || other.side == side)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.status, status) || other.status == status)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.filledQty, filledQty) || other.filledQty == filledQty)&&(identical(other.limitPrice, limitPrice) || other.limitPrice == limitPrice)&&(identical(other.avgFillPrice, avgFillPrice) || other.avgFillPrice == avgFillPrice)&&(identical(other.validity, validity) || other.validity == validity)&&(identical(other.extendedHours, extendedHours) || other.extendedHours == extendedHours)&&(identical(other.fees, fees) || other.fees == fees)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,orderId,symbol,market,side,orderType,status,qty,filledQty,limitPrice,avgFillPrice,validity,extendedHours,fees,createdAt,updatedAt);

@override
String toString() {
  return 'Order(orderId: $orderId, symbol: $symbol, market: $market, side: $side, orderType: $orderType, status: $status, qty: $qty, filledQty: $filledQty, limitPrice: $limitPrice, avgFillPrice: $avgFillPrice, validity: $validity, extendedHours: $extendedHours, fees: $fees, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String orderId, String symbol, String market, OrderSide side, OrderType orderType, OrderStatus status, int qty, int filledQty, Decimal? limitPrice, Decimal? avgFillPrice, OrderValidity validity, bool extendedHours, OrderFees fees, DateTime createdAt, DateTime updatedAt
});


$OrderFeesCopyWith<$Res> get fees;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? symbol = null,Object? market = null,Object? side = null,Object? orderType = null,Object? status = null,Object? qty = null,Object? filledQty = null,Object? limitPrice = freezed,Object? avgFillPrice = freezed,Object? validity = null,Object? extendedHours = null,Object? fees = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as OrderSide,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as OrderType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,filledQty: null == filledQty ? _self.filledQty : filledQty // ignore: cast_nullable_to_non_nullable
as int,limitPrice: freezed == limitPrice ? _self.limitPrice : limitPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,avgFillPrice: freezed == avgFillPrice ? _self.avgFillPrice : avgFillPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,validity: null == validity ? _self.validity : validity // ignore: cast_nullable_to_non_nullable
as OrderValidity,extendedHours: null == extendedHours ? _self.extendedHours : extendedHours // ignore: cast_nullable_to_non_nullable
as bool,fees: null == fees ? _self.fees : fees // ignore: cast_nullable_to_non_nullable
as OrderFees,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderFeesCopyWith<$Res> get fees {
  
  return $OrderFeesCopyWith<$Res>(_self.fees, (value) {
    return _then(_self.copyWith(fees: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String symbol,  String market,  OrderSide side,  OrderType orderType,  OrderStatus status,  int qty,  int filledQty,  Decimal? limitPrice,  Decimal? avgFillPrice,  OrderValidity validity,  bool extendedHours,  OrderFees fees,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.orderId,_that.symbol,_that.market,_that.side,_that.orderType,_that.status,_that.qty,_that.filledQty,_that.limitPrice,_that.avgFillPrice,_that.validity,_that.extendedHours,_that.fees,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String symbol,  String market,  OrderSide side,  OrderType orderType,  OrderStatus status,  int qty,  int filledQty,  Decimal? limitPrice,  Decimal? avgFillPrice,  OrderValidity validity,  bool extendedHours,  OrderFees fees,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.orderId,_that.symbol,_that.market,_that.side,_that.orderType,_that.status,_that.qty,_that.filledQty,_that.limitPrice,_that.avgFillPrice,_that.validity,_that.extendedHours,_that.fees,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String symbol,  String market,  OrderSide side,  OrderType orderType,  OrderStatus status,  int qty,  int filledQty,  Decimal? limitPrice,  Decimal? avgFillPrice,  OrderValidity validity,  bool extendedHours,  OrderFees fees,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.orderId,_that.symbol,_that.market,_that.side,_that.orderType,_that.status,_that.qty,_that.filledQty,_that.limitPrice,_that.avgFillPrice,_that.validity,_that.extendedHours,_that.fees,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Order extends Order {
  const _Order({required this.orderId, required this.symbol, required this.market, required this.side, required this.orderType, required this.status, required this.qty, required this.filledQty, this.limitPrice, this.avgFillPrice, required this.validity, required this.extendedHours, required this.fees, required this.createdAt, required this.updatedAt}): super._();
  

@override final  String orderId;
@override final  String symbol;
@override final  String market;
@override final  OrderSide side;
@override final  OrderType orderType;
@override final  OrderStatus status;
@override final  int qty;
@override final  int filledQty;
@override final  Decimal? limitPrice;
@override final  Decimal? avgFillPrice;
@override final  OrderValidity validity;
@override final  bool extendedHours;
@override final  OrderFees fees;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.side, side) || other.side == side)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.status, status) || other.status == status)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.filledQty, filledQty) || other.filledQty == filledQty)&&(identical(other.limitPrice, limitPrice) || other.limitPrice == limitPrice)&&(identical(other.avgFillPrice, avgFillPrice) || other.avgFillPrice == avgFillPrice)&&(identical(other.validity, validity) || other.validity == validity)&&(identical(other.extendedHours, extendedHours) || other.extendedHours == extendedHours)&&(identical(other.fees, fees) || other.fees == fees)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,orderId,symbol,market,side,orderType,status,qty,filledQty,limitPrice,avgFillPrice,validity,extendedHours,fees,createdAt,updatedAt);

@override
String toString() {
  return 'Order(orderId: $orderId, symbol: $symbol, market: $market, side: $side, orderType: $orderType, status: $status, qty: $qty, filledQty: $filledQty, limitPrice: $limitPrice, avgFillPrice: $avgFillPrice, validity: $validity, extendedHours: $extendedHours, fees: $fees, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String symbol, String market, OrderSide side, OrderType orderType, OrderStatus status, int qty, int filledQty, Decimal? limitPrice, Decimal? avgFillPrice, OrderValidity validity, bool extendedHours, OrderFees fees, DateTime createdAt, DateTime updatedAt
});


@override $OrderFeesCopyWith<$Res> get fees;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? symbol = null,Object? market = null,Object? side = null,Object? orderType = null,Object? status = null,Object? qty = null,Object? filledQty = null,Object? limitPrice = freezed,Object? avgFillPrice = freezed,Object? validity = null,Object? extendedHours = null,Object? fees = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Order(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as OrderSide,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as OrderType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,filledQty: null == filledQty ? _self.filledQty : filledQty // ignore: cast_nullable_to_non_nullable
as int,limitPrice: freezed == limitPrice ? _self.limitPrice : limitPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,avgFillPrice: freezed == avgFillPrice ? _self.avgFillPrice : avgFillPrice // ignore: cast_nullable_to_non_nullable
as Decimal?,validity: null == validity ? _self.validity : validity // ignore: cast_nullable_to_non_nullable
as OrderValidity,extendedHours: null == extendedHours ? _self.extendedHours : extendedHours // ignore: cast_nullable_to_non_nullable
as bool,fees: null == fees ? _self.fees : fees // ignore: cast_nullable_to_non_nullable
as OrderFees,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderFeesCopyWith<$Res> get fees {
  
  return $OrderFeesCopyWith<$Res>(_self.fees, (value) {
    return _then(_self.copyWith(fees: value));
  });
}
}

// dart format on
