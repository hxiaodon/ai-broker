// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderFeesModel {

@JsonKey(name: 'commission') String get commission;@JsonKey(name: 'exchange_fee') String get exchangeFee;@JsonKey(name: 'sec_fee') String get secFee;@JsonKey(name: 'finra_fee') String get finraFee;@JsonKey(name: 'total') String get total;
/// Create a copy of OrderFeesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderFeesModelCopyWith<OrderFeesModel> get copyWith => _$OrderFeesModelCopyWithImpl<OrderFeesModel>(this as OrderFeesModel, _$identity);

  /// Serializes this OrderFeesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderFeesModel&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.exchangeFee, exchangeFee) || other.exchangeFee == exchangeFee)&&(identical(other.secFee, secFee) || other.secFee == secFee)&&(identical(other.finraFee, finraFee) || other.finraFee == finraFee)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commission,exchangeFee,secFee,finraFee,total);

@override
String toString() {
  return 'OrderFeesModel(commission: $commission, exchangeFee: $exchangeFee, secFee: $secFee, finraFee: $finraFee, total: $total)';
}


}

/// @nodoc
abstract mixin class $OrderFeesModelCopyWith<$Res>  {
  factory $OrderFeesModelCopyWith(OrderFeesModel value, $Res Function(OrderFeesModel) _then) = _$OrderFeesModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'commission') String commission,@JsonKey(name: 'exchange_fee') String exchangeFee,@JsonKey(name: 'sec_fee') String secFee,@JsonKey(name: 'finra_fee') String finraFee,@JsonKey(name: 'total') String total
});




}
/// @nodoc
class _$OrderFeesModelCopyWithImpl<$Res>
    implements $OrderFeesModelCopyWith<$Res> {
  _$OrderFeesModelCopyWithImpl(this._self, this._then);

  final OrderFeesModel _self;
  final $Res Function(OrderFeesModel) _then;

/// Create a copy of OrderFeesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? commission = null,Object? exchangeFee = null,Object? secFee = null,Object? finraFee = null,Object? total = null,}) {
  return _then(_self.copyWith(
commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as String,exchangeFee: null == exchangeFee ? _self.exchangeFee : exchangeFee // ignore: cast_nullable_to_non_nullable
as String,secFee: null == secFee ? _self.secFee : secFee // ignore: cast_nullable_to_non_nullable
as String,finraFee: null == finraFee ? _self.finraFee : finraFee // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderFeesModel].
extension OrderFeesModelPatterns on OrderFeesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderFeesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderFeesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderFeesModel value)  $default,){
final _that = this;
switch (_that) {
case _OrderFeesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderFeesModel value)?  $default,){
final _that = this;
switch (_that) {
case _OrderFeesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'commission')  String commission, @JsonKey(name: 'exchange_fee')  String exchangeFee, @JsonKey(name: 'sec_fee')  String secFee, @JsonKey(name: 'finra_fee')  String finraFee, @JsonKey(name: 'total')  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderFeesModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'commission')  String commission, @JsonKey(name: 'exchange_fee')  String exchangeFee, @JsonKey(name: 'sec_fee')  String secFee, @JsonKey(name: 'finra_fee')  String finraFee, @JsonKey(name: 'total')  String total)  $default,) {final _that = this;
switch (_that) {
case _OrderFeesModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'commission')  String commission, @JsonKey(name: 'exchange_fee')  String exchangeFee, @JsonKey(name: 'sec_fee')  String secFee, @JsonKey(name: 'finra_fee')  String finraFee, @JsonKey(name: 'total')  String total)?  $default,) {final _that = this;
switch (_that) {
case _OrderFeesModel() when $default != null:
return $default(_that.commission,_that.exchangeFee,_that.secFee,_that.finraFee,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderFeesModel implements OrderFeesModel {
  const _OrderFeesModel({@JsonKey(name: 'commission') required this.commission, @JsonKey(name: 'exchange_fee') required this.exchangeFee, @JsonKey(name: 'sec_fee') required this.secFee, @JsonKey(name: 'finra_fee') required this.finraFee, @JsonKey(name: 'total') required this.total});
  factory _OrderFeesModel.fromJson(Map<String, dynamic> json) => _$OrderFeesModelFromJson(json);

@override@JsonKey(name: 'commission') final  String commission;
@override@JsonKey(name: 'exchange_fee') final  String exchangeFee;
@override@JsonKey(name: 'sec_fee') final  String secFee;
@override@JsonKey(name: 'finra_fee') final  String finraFee;
@override@JsonKey(name: 'total') final  String total;

/// Create a copy of OrderFeesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderFeesModelCopyWith<_OrderFeesModel> get copyWith => __$OrderFeesModelCopyWithImpl<_OrderFeesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderFeesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderFeesModel&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.exchangeFee, exchangeFee) || other.exchangeFee == exchangeFee)&&(identical(other.secFee, secFee) || other.secFee == secFee)&&(identical(other.finraFee, finraFee) || other.finraFee == finraFee)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,commission,exchangeFee,secFee,finraFee,total);

@override
String toString() {
  return 'OrderFeesModel(commission: $commission, exchangeFee: $exchangeFee, secFee: $secFee, finraFee: $finraFee, total: $total)';
}


}

/// @nodoc
abstract mixin class _$OrderFeesModelCopyWith<$Res> implements $OrderFeesModelCopyWith<$Res> {
  factory _$OrderFeesModelCopyWith(_OrderFeesModel value, $Res Function(_OrderFeesModel) _then) = __$OrderFeesModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'commission') String commission,@JsonKey(name: 'exchange_fee') String exchangeFee,@JsonKey(name: 'sec_fee') String secFee,@JsonKey(name: 'finra_fee') String finraFee,@JsonKey(name: 'total') String total
});




}
/// @nodoc
class __$OrderFeesModelCopyWithImpl<$Res>
    implements _$OrderFeesModelCopyWith<$Res> {
  __$OrderFeesModelCopyWithImpl(this._self, this._then);

  final _OrderFeesModel _self;
  final $Res Function(_OrderFeesModel) _then;

/// Create a copy of OrderFeesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? commission = null,Object? exchangeFee = null,Object? secFee = null,Object? finraFee = null,Object? total = null,}) {
  return _then(_OrderFeesModel(
commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as String,exchangeFee: null == exchangeFee ? _self.exchangeFee : exchangeFee // ignore: cast_nullable_to_non_nullable
as String,secFee: null == secFee ? _self.secFee : secFee // ignore: cast_nullable_to_non_nullable
as String,finraFee: null == finraFee ? _self.finraFee : finraFee // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrderModel {

@JsonKey(name: 'order_id') String get orderId;@JsonKey(name: 'symbol') String get symbol;@JsonKey(name: 'market') String get market;@JsonKey(name: 'side') String get side;@JsonKey(name: 'order_type') String get orderType;@JsonKey(name: 'status') String get status;@JsonKey(name: 'qty') int get qty;@JsonKey(name: 'filled_qty') int get filledQty;@JsonKey(name: 'limit_price') String? get limitPrice;@JsonKey(name: 'avg_fill_price') String? get avgFillPrice;@JsonKey(name: 'validity') String get validity;@JsonKey(name: 'extended_hours') bool get extendedHours;@JsonKey(name: 'fees') OrderFeesModel get fees;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderModelCopyWith<OrderModel> get copyWith => _$OrderModelCopyWithImpl<OrderModel>(this as OrderModel, _$identity);

  /// Serializes this OrderModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderModel&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.side, side) || other.side == side)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.status, status) || other.status == status)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.filledQty, filledQty) || other.filledQty == filledQty)&&(identical(other.limitPrice, limitPrice) || other.limitPrice == limitPrice)&&(identical(other.avgFillPrice, avgFillPrice) || other.avgFillPrice == avgFillPrice)&&(identical(other.validity, validity) || other.validity == validity)&&(identical(other.extendedHours, extendedHours) || other.extendedHours == extendedHours)&&(identical(other.fees, fees) || other.fees == fees)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,symbol,market,side,orderType,status,qty,filledQty,limitPrice,avgFillPrice,validity,extendedHours,fees,createdAt,updatedAt);

@override
String toString() {
  return 'OrderModel(orderId: $orderId, symbol: $symbol, market: $market, side: $side, orderType: $orderType, status: $status, qty: $qty, filledQty: $filledQty, limitPrice: $limitPrice, avgFillPrice: $avgFillPrice, validity: $validity, extendedHours: $extendedHours, fees: $fees, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $OrderModelCopyWith<$Res>  {
  factory $OrderModelCopyWith(OrderModel value, $Res Function(OrderModel) _then) = _$OrderModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'order_id') String orderId,@JsonKey(name: 'symbol') String symbol,@JsonKey(name: 'market') String market,@JsonKey(name: 'side') String side,@JsonKey(name: 'order_type') String orderType,@JsonKey(name: 'status') String status,@JsonKey(name: 'qty') int qty,@JsonKey(name: 'filled_qty') int filledQty,@JsonKey(name: 'limit_price') String? limitPrice,@JsonKey(name: 'avg_fill_price') String? avgFillPrice,@JsonKey(name: 'validity') String validity,@JsonKey(name: 'extended_hours') bool extendedHours,@JsonKey(name: 'fees') OrderFeesModel fees,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});


$OrderFeesModelCopyWith<$Res> get fees;

}
/// @nodoc
class _$OrderModelCopyWithImpl<$Res>
    implements $OrderModelCopyWith<$Res> {
  _$OrderModelCopyWithImpl(this._self, this._then);

  final OrderModel _self;
  final $Res Function(OrderModel) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? symbol = null,Object? market = null,Object? side = null,Object? orderType = null,Object? status = null,Object? qty = null,Object? filledQty = null,Object? limitPrice = freezed,Object? avgFillPrice = freezed,Object? validity = null,Object? extendedHours = null,Object? fees = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,filledQty: null == filledQty ? _self.filledQty : filledQty // ignore: cast_nullable_to_non_nullable
as int,limitPrice: freezed == limitPrice ? _self.limitPrice : limitPrice // ignore: cast_nullable_to_non_nullable
as String?,avgFillPrice: freezed == avgFillPrice ? _self.avgFillPrice : avgFillPrice // ignore: cast_nullable_to_non_nullable
as String?,validity: null == validity ? _self.validity : validity // ignore: cast_nullable_to_non_nullable
as String,extendedHours: null == extendedHours ? _self.extendedHours : extendedHours // ignore: cast_nullable_to_non_nullable
as bool,fees: null == fees ? _self.fees : fees // ignore: cast_nullable_to_non_nullable
as OrderFeesModel,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderFeesModelCopyWith<$Res> get fees {
  
  return $OrderFeesModelCopyWith<$Res>(_self.fees, (value) {
    return _then(_self.copyWith(fees: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderModel].
extension OrderModelPatterns on OrderModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderModel value)  $default,){
final _that = this;
switch (_that) {
case _OrderModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderModel value)?  $default,){
final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  String orderId, @JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'market')  String market, @JsonKey(name: 'side')  String side, @JsonKey(name: 'order_type')  String orderType, @JsonKey(name: 'status')  String status, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'filled_qty')  int filledQty, @JsonKey(name: 'limit_price')  String? limitPrice, @JsonKey(name: 'avg_fill_price')  String? avgFillPrice, @JsonKey(name: 'validity')  String validity, @JsonKey(name: 'extended_hours')  bool extendedHours, @JsonKey(name: 'fees')  OrderFeesModel fees, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  String orderId, @JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'market')  String market, @JsonKey(name: 'side')  String side, @JsonKey(name: 'order_type')  String orderType, @JsonKey(name: 'status')  String status, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'filled_qty')  int filledQty, @JsonKey(name: 'limit_price')  String? limitPrice, @JsonKey(name: 'avg_fill_price')  String? avgFillPrice, @JsonKey(name: 'validity')  String validity, @JsonKey(name: 'extended_hours')  bool extendedHours, @JsonKey(name: 'fees')  OrderFeesModel fees, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _OrderModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'order_id')  String orderId, @JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'market')  String market, @JsonKey(name: 'side')  String side, @JsonKey(name: 'order_type')  String orderType, @JsonKey(name: 'status')  String status, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'filled_qty')  int filledQty, @JsonKey(name: 'limit_price')  String? limitPrice, @JsonKey(name: 'avg_fill_price')  String? avgFillPrice, @JsonKey(name: 'validity')  String validity, @JsonKey(name: 'extended_hours')  bool extendedHours, @JsonKey(name: 'fees')  OrderFeesModel fees, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderModel() when $default != null:
return $default(_that.orderId,_that.symbol,_that.market,_that.side,_that.orderType,_that.status,_that.qty,_that.filledQty,_that.limitPrice,_that.avgFillPrice,_that.validity,_that.extendedHours,_that.fees,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderModel implements OrderModel {
  const _OrderModel({@JsonKey(name: 'order_id') required this.orderId, @JsonKey(name: 'symbol') required this.symbol, @JsonKey(name: 'market') required this.market, @JsonKey(name: 'side') required this.side, @JsonKey(name: 'order_type') required this.orderType, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'qty') required this.qty, @JsonKey(name: 'filled_qty') required this.filledQty, @JsonKey(name: 'limit_price') this.limitPrice, @JsonKey(name: 'avg_fill_price') this.avgFillPrice, @JsonKey(name: 'validity') required this.validity, @JsonKey(name: 'extended_hours') required this.extendedHours, @JsonKey(name: 'fees') required this.fees, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);

@override@JsonKey(name: 'order_id') final  String orderId;
@override@JsonKey(name: 'symbol') final  String symbol;
@override@JsonKey(name: 'market') final  String market;
@override@JsonKey(name: 'side') final  String side;
@override@JsonKey(name: 'order_type') final  String orderType;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'qty') final  int qty;
@override@JsonKey(name: 'filled_qty') final  int filledQty;
@override@JsonKey(name: 'limit_price') final  String? limitPrice;
@override@JsonKey(name: 'avg_fill_price') final  String? avgFillPrice;
@override@JsonKey(name: 'validity') final  String validity;
@override@JsonKey(name: 'extended_hours') final  bool extendedHours;
@override@JsonKey(name: 'fees') final  OrderFeesModel fees;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderModelCopyWith<_OrderModel> get copyWith => __$OrderModelCopyWithImpl<_OrderModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderModel&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.side, side) || other.side == side)&&(identical(other.orderType, orderType) || other.orderType == orderType)&&(identical(other.status, status) || other.status == status)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.filledQty, filledQty) || other.filledQty == filledQty)&&(identical(other.limitPrice, limitPrice) || other.limitPrice == limitPrice)&&(identical(other.avgFillPrice, avgFillPrice) || other.avgFillPrice == avgFillPrice)&&(identical(other.validity, validity) || other.validity == validity)&&(identical(other.extendedHours, extendedHours) || other.extendedHours == extendedHours)&&(identical(other.fees, fees) || other.fees == fees)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,symbol,market,side,orderType,status,qty,filledQty,limitPrice,avgFillPrice,validity,extendedHours,fees,createdAt,updatedAt);

@override
String toString() {
  return 'OrderModel(orderId: $orderId, symbol: $symbol, market: $market, side: $side, orderType: $orderType, status: $status, qty: $qty, filledQty: $filledQty, limitPrice: $limitPrice, avgFillPrice: $avgFillPrice, validity: $validity, extendedHours: $extendedHours, fees: $fees, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OrderModelCopyWith<$Res> implements $OrderModelCopyWith<$Res> {
  factory _$OrderModelCopyWith(_OrderModel value, $Res Function(_OrderModel) _then) = __$OrderModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'order_id') String orderId,@JsonKey(name: 'symbol') String symbol,@JsonKey(name: 'market') String market,@JsonKey(name: 'side') String side,@JsonKey(name: 'order_type') String orderType,@JsonKey(name: 'status') String status,@JsonKey(name: 'qty') int qty,@JsonKey(name: 'filled_qty') int filledQty,@JsonKey(name: 'limit_price') String? limitPrice,@JsonKey(name: 'avg_fill_price') String? avgFillPrice,@JsonKey(name: 'validity') String validity,@JsonKey(name: 'extended_hours') bool extendedHours,@JsonKey(name: 'fees') OrderFeesModel fees,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt
});


@override $OrderFeesModelCopyWith<$Res> get fees;

}
/// @nodoc
class __$OrderModelCopyWithImpl<$Res>
    implements _$OrderModelCopyWith<$Res> {
  __$OrderModelCopyWithImpl(this._self, this._then);

  final _OrderModel _self;
  final $Res Function(_OrderModel) _then;

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? symbol = null,Object? market = null,Object? side = null,Object? orderType = null,Object? status = null,Object? qty = null,Object? filledQty = null,Object? limitPrice = freezed,Object? avgFillPrice = freezed,Object? validity = null,Object? extendedHours = null,Object? fees = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_OrderModel(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,orderType: null == orderType ? _self.orderType : orderType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,filledQty: null == filledQty ? _self.filledQty : filledQty // ignore: cast_nullable_to_non_nullable
as int,limitPrice: freezed == limitPrice ? _self.limitPrice : limitPrice // ignore: cast_nullable_to_non_nullable
as String?,avgFillPrice: freezed == avgFillPrice ? _self.avgFillPrice : avgFillPrice // ignore: cast_nullable_to_non_nullable
as String?,validity: null == validity ? _self.validity : validity // ignore: cast_nullable_to_non_nullable
as String,extendedHours: null == extendedHours ? _self.extendedHours : extendedHours // ignore: cast_nullable_to_non_nullable
as bool,fees: null == fees ? _self.fees : fees // ignore: cast_nullable_to_non_nullable
as OrderFeesModel,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of OrderModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderFeesModelCopyWith<$Res> get fees {
  
  return $OrderFeesModelCopyWith<$Res>(_self.fees, (value) {
    return _then(_self.copyWith(fees: value));
  });
}
}


/// @nodoc
mixin _$OrderFillModel {

@JsonKey(name: 'fill_id') String get fillId;@JsonKey(name: 'order_id') String get orderId;@JsonKey(name: 'qty') int get qty;@JsonKey(name: 'price') String get price;@JsonKey(name: 'exchange') String get exchange;@JsonKey(name: 'filled_at') String get filledAt;
/// Create a copy of OrderFillModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderFillModelCopyWith<OrderFillModel> get copyWith => _$OrderFillModelCopyWithImpl<OrderFillModel>(this as OrderFillModel, _$identity);

  /// Serializes this OrderFillModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderFillModel&&(identical(other.fillId, fillId) || other.fillId == fillId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.filledAt, filledAt) || other.filledAt == filledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fillId,orderId,qty,price,exchange,filledAt);

@override
String toString() {
  return 'OrderFillModel(fillId: $fillId, orderId: $orderId, qty: $qty, price: $price, exchange: $exchange, filledAt: $filledAt)';
}


}

/// @nodoc
abstract mixin class $OrderFillModelCopyWith<$Res>  {
  factory $OrderFillModelCopyWith(OrderFillModel value, $Res Function(OrderFillModel) _then) = _$OrderFillModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'fill_id') String fillId,@JsonKey(name: 'order_id') String orderId,@JsonKey(name: 'qty') int qty,@JsonKey(name: 'price') String price,@JsonKey(name: 'exchange') String exchange,@JsonKey(name: 'filled_at') String filledAt
});




}
/// @nodoc
class _$OrderFillModelCopyWithImpl<$Res>
    implements $OrderFillModelCopyWith<$Res> {
  _$OrderFillModelCopyWithImpl(this._self, this._then);

  final OrderFillModel _self;
  final $Res Function(OrderFillModel) _then;

/// Create a copy of OrderFillModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fillId = null,Object? orderId = null,Object? qty = null,Object? price = null,Object? exchange = null,Object? filledAt = null,}) {
  return _then(_self.copyWith(
fillId: null == fillId ? _self.fillId : fillId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,filledAt: null == filledAt ? _self.filledAt : filledAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderFillModel].
extension OrderFillModelPatterns on OrderFillModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderFillModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderFillModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderFillModel value)  $default,){
final _that = this;
switch (_that) {
case _OrderFillModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderFillModel value)?  $default,){
final _that = this;
switch (_that) {
case _OrderFillModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'fill_id')  String fillId, @JsonKey(name: 'order_id')  String orderId, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'price')  String price, @JsonKey(name: 'exchange')  String exchange, @JsonKey(name: 'filled_at')  String filledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderFillModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'fill_id')  String fillId, @JsonKey(name: 'order_id')  String orderId, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'price')  String price, @JsonKey(name: 'exchange')  String exchange, @JsonKey(name: 'filled_at')  String filledAt)  $default,) {final _that = this;
switch (_that) {
case _OrderFillModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'fill_id')  String fillId, @JsonKey(name: 'order_id')  String orderId, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'price')  String price, @JsonKey(name: 'exchange')  String exchange, @JsonKey(name: 'filled_at')  String filledAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderFillModel() when $default != null:
return $default(_that.fillId,_that.orderId,_that.qty,_that.price,_that.exchange,_that.filledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderFillModel implements OrderFillModel {
  const _OrderFillModel({@JsonKey(name: 'fill_id') required this.fillId, @JsonKey(name: 'order_id') required this.orderId, @JsonKey(name: 'qty') required this.qty, @JsonKey(name: 'price') required this.price, @JsonKey(name: 'exchange') required this.exchange, @JsonKey(name: 'filled_at') required this.filledAt});
  factory _OrderFillModel.fromJson(Map<String, dynamic> json) => _$OrderFillModelFromJson(json);

@override@JsonKey(name: 'fill_id') final  String fillId;
@override@JsonKey(name: 'order_id') final  String orderId;
@override@JsonKey(name: 'qty') final  int qty;
@override@JsonKey(name: 'price') final  String price;
@override@JsonKey(name: 'exchange') final  String exchange;
@override@JsonKey(name: 'filled_at') final  String filledAt;

/// Create a copy of OrderFillModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderFillModelCopyWith<_OrderFillModel> get copyWith => __$OrderFillModelCopyWithImpl<_OrderFillModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderFillModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderFillModel&&(identical(other.fillId, fillId) || other.fillId == fillId)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.filledAt, filledAt) || other.filledAt == filledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fillId,orderId,qty,price,exchange,filledAt);

@override
String toString() {
  return 'OrderFillModel(fillId: $fillId, orderId: $orderId, qty: $qty, price: $price, exchange: $exchange, filledAt: $filledAt)';
}


}

/// @nodoc
abstract mixin class _$OrderFillModelCopyWith<$Res> implements $OrderFillModelCopyWith<$Res> {
  factory _$OrderFillModelCopyWith(_OrderFillModel value, $Res Function(_OrderFillModel) _then) = __$OrderFillModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'fill_id') String fillId,@JsonKey(name: 'order_id') String orderId,@JsonKey(name: 'qty') int qty,@JsonKey(name: 'price') String price,@JsonKey(name: 'exchange') String exchange,@JsonKey(name: 'filled_at') String filledAt
});




}
/// @nodoc
class __$OrderFillModelCopyWithImpl<$Res>
    implements _$OrderFillModelCopyWith<$Res> {
  __$OrderFillModelCopyWithImpl(this._self, this._then);

  final _OrderFillModel _self;
  final $Res Function(_OrderFillModel) _then;

/// Create a copy of OrderFillModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fillId = null,Object? orderId = null,Object? qty = null,Object? price = null,Object? exchange = null,Object? filledAt = null,}) {
  return _then(_OrderFillModel(
fillId: null == fillId ? _self.fillId : fillId // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,filledAt: null == filledAt ? _self.filledAt : filledAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrderDetailModel {

@JsonKey(name: 'order') OrderModel get order;@JsonKey(name: 'fills') List<OrderFillModel> get fills;
/// Create a copy of OrderDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDetailModelCopyWith<OrderDetailModel> get copyWith => _$OrderDetailModelCopyWithImpl<OrderDetailModel>(this as OrderDetailModel, _$identity);

  /// Serializes this OrderDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDetailModel&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.fills, fills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,order,const DeepCollectionEquality().hash(fills));

@override
String toString() {
  return 'OrderDetailModel(order: $order, fills: $fills)';
}


}

/// @nodoc
abstract mixin class $OrderDetailModelCopyWith<$Res>  {
  factory $OrderDetailModelCopyWith(OrderDetailModel value, $Res Function(OrderDetailModel) _then) = _$OrderDetailModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'order') OrderModel order,@JsonKey(name: 'fills') List<OrderFillModel> fills
});


$OrderModelCopyWith<$Res> get order;

}
/// @nodoc
class _$OrderDetailModelCopyWithImpl<$Res>
    implements $OrderDetailModelCopyWith<$Res> {
  _$OrderDetailModelCopyWithImpl(this._self, this._then);

  final OrderDetailModel _self;
  final $Res Function(OrderDetailModel) _then;

/// Create a copy of OrderDetailModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? order = null,Object? fills = null,}) {
  return _then(_self.copyWith(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as OrderModel,fills: null == fills ? _self.fills : fills // ignore: cast_nullable_to_non_nullable
as List<OrderFillModel>,
  ));
}
/// Create a copy of OrderDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderModelCopyWith<$Res> get order {
  
  return $OrderModelCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderDetailModel].
extension OrderDetailModelPatterns on OrderDetailModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDetailModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDetailModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDetailModel value)  $default,){
final _that = this;
switch (_that) {
case _OrderDetailModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDetailModel value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDetailModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'order')  OrderModel order, @JsonKey(name: 'fills')  List<OrderFillModel> fills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDetailModel() when $default != null:
return $default(_that.order,_that.fills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'order')  OrderModel order, @JsonKey(name: 'fills')  List<OrderFillModel> fills)  $default,) {final _that = this;
switch (_that) {
case _OrderDetailModel():
return $default(_that.order,_that.fills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'order')  OrderModel order, @JsonKey(name: 'fills')  List<OrderFillModel> fills)?  $default,) {final _that = this;
switch (_that) {
case _OrderDetailModel() when $default != null:
return $default(_that.order,_that.fills);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderDetailModel implements OrderDetailModel {
  const _OrderDetailModel({@JsonKey(name: 'order') required this.order, @JsonKey(name: 'fills') required final  List<OrderFillModel> fills}): _fills = fills;
  factory _OrderDetailModel.fromJson(Map<String, dynamic> json) => _$OrderDetailModelFromJson(json);

@override@JsonKey(name: 'order') final  OrderModel order;
 final  List<OrderFillModel> _fills;
@override@JsonKey(name: 'fills') List<OrderFillModel> get fills {
  if (_fills is EqualUnmodifiableListView) return _fills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fills);
}


/// Create a copy of OrderDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDetailModelCopyWith<_OrderDetailModel> get copyWith => __$OrderDetailModelCopyWithImpl<_OrderDetailModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderDetailModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDetailModel&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._fills, _fills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,order,const DeepCollectionEquality().hash(_fills));

@override
String toString() {
  return 'OrderDetailModel(order: $order, fills: $fills)';
}


}

/// @nodoc
abstract mixin class _$OrderDetailModelCopyWith<$Res> implements $OrderDetailModelCopyWith<$Res> {
  factory _$OrderDetailModelCopyWith(_OrderDetailModel value, $Res Function(_OrderDetailModel) _then) = __$OrderDetailModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'order') OrderModel order,@JsonKey(name: 'fills') List<OrderFillModel> fills
});


@override $OrderModelCopyWith<$Res> get order;

}
/// @nodoc
class __$OrderDetailModelCopyWithImpl<$Res>
    implements _$OrderDetailModelCopyWith<$Res> {
  __$OrderDetailModelCopyWithImpl(this._self, this._then);

  final _OrderDetailModel _self;
  final $Res Function(_OrderDetailModel) _then;

/// Create a copy of OrderDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? order = null,Object? fills = null,}) {
  return _then(_OrderDetailModel(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as OrderModel,fills: null == fills ? _self._fills : fills // ignore: cast_nullable_to_non_nullable
as List<OrderFillModel>,
  ));
}

/// Create a copy of OrderDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderModelCopyWith<$Res> get order {
  
  return $OrderModelCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

// dart format on
