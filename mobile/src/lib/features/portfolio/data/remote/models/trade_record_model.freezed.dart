// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trade_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TradeRecordModel {

@JsonKey(name: 'trade_id') String get tradeId;@JsonKey(name: 'side') String get side;@JsonKey(name: 'quantity') int get qty;@JsonKey(name: 'price') String get price;@JsonKey(name: 'amount') String get amount;@JsonKey(name: 'fee') String get fee;@JsonKey(name: 'executed_at') String get executedAt;@JsonKey(name: 'wash_sale') bool get washSale;
/// Create a copy of TradeRecordModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TradeRecordModelCopyWith<TradeRecordModel> get copyWith => _$TradeRecordModelCopyWithImpl<TradeRecordModel>(this as TradeRecordModel, _$identity);

  /// Serializes this TradeRecordModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TradeRecordModel&&(identical(other.tradeId, tradeId) || other.tradeId == tradeId)&&(identical(other.side, side) || other.side == side)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt)&&(identical(other.washSale, washSale) || other.washSale == washSale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tradeId,side,qty,price,amount,fee,executedAt,washSale);

@override
String toString() {
  return 'TradeRecordModel(tradeId: $tradeId, side: $side, qty: $qty, price: $price, amount: $amount, fee: $fee, executedAt: $executedAt, washSale: $washSale)';
}


}

/// @nodoc
abstract mixin class $TradeRecordModelCopyWith<$Res>  {
  factory $TradeRecordModelCopyWith(TradeRecordModel value, $Res Function(TradeRecordModel) _then) = _$TradeRecordModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'trade_id') String tradeId,@JsonKey(name: 'side') String side,@JsonKey(name: 'quantity') int qty,@JsonKey(name: 'price') String price,@JsonKey(name: 'amount') String amount,@JsonKey(name: 'fee') String fee,@JsonKey(name: 'executed_at') String executedAt,@JsonKey(name: 'wash_sale') bool washSale
});




}
/// @nodoc
class _$TradeRecordModelCopyWithImpl<$Res>
    implements $TradeRecordModelCopyWith<$Res> {
  _$TradeRecordModelCopyWithImpl(this._self, this._then);

  final TradeRecordModel _self;
  final $Res Function(TradeRecordModel) _then;

/// Create a copy of TradeRecordModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tradeId = null,Object? side = null,Object? qty = null,Object? price = null,Object? amount = null,Object? fee = null,Object? executedAt = null,Object? washSale = null,}) {
  return _then(_self.copyWith(
tradeId: null == tradeId ? _self.tradeId : tradeId // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as String,washSale: null == washSale ? _self.washSale : washSale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TradeRecordModel].
extension TradeRecordModelPatterns on TradeRecordModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TradeRecordModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TradeRecordModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TradeRecordModel value)  $default,){
final _that = this;
switch (_that) {
case _TradeRecordModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TradeRecordModel value)?  $default,){
final _that = this;
switch (_that) {
case _TradeRecordModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'trade_id')  String tradeId, @JsonKey(name: 'side')  String side, @JsonKey(name: 'quantity')  int qty, @JsonKey(name: 'price')  String price, @JsonKey(name: 'amount')  String amount, @JsonKey(name: 'fee')  String fee, @JsonKey(name: 'executed_at')  String executedAt, @JsonKey(name: 'wash_sale')  bool washSale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TradeRecordModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'trade_id')  String tradeId, @JsonKey(name: 'side')  String side, @JsonKey(name: 'quantity')  int qty, @JsonKey(name: 'price')  String price, @JsonKey(name: 'amount')  String amount, @JsonKey(name: 'fee')  String fee, @JsonKey(name: 'executed_at')  String executedAt, @JsonKey(name: 'wash_sale')  bool washSale)  $default,) {final _that = this;
switch (_that) {
case _TradeRecordModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'trade_id')  String tradeId, @JsonKey(name: 'side')  String side, @JsonKey(name: 'quantity')  int qty, @JsonKey(name: 'price')  String price, @JsonKey(name: 'amount')  String amount, @JsonKey(name: 'fee')  String fee, @JsonKey(name: 'executed_at')  String executedAt, @JsonKey(name: 'wash_sale')  bool washSale)?  $default,) {final _that = this;
switch (_that) {
case _TradeRecordModel() when $default != null:
return $default(_that.tradeId,_that.side,_that.qty,_that.price,_that.amount,_that.fee,_that.executedAt,_that.washSale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TradeRecordModel implements TradeRecordModel {
  const _TradeRecordModel({@JsonKey(name: 'trade_id') required this.tradeId, @JsonKey(name: 'side') required this.side, @JsonKey(name: 'quantity') required this.qty, @JsonKey(name: 'price') required this.price, @JsonKey(name: 'amount') required this.amount, @JsonKey(name: 'fee') required this.fee, @JsonKey(name: 'executed_at') required this.executedAt, @JsonKey(name: 'wash_sale') this.washSale = false});
  factory _TradeRecordModel.fromJson(Map<String, dynamic> json) => _$TradeRecordModelFromJson(json);

@override@JsonKey(name: 'trade_id') final  String tradeId;
@override@JsonKey(name: 'side') final  String side;
@override@JsonKey(name: 'quantity') final  int qty;
@override@JsonKey(name: 'price') final  String price;
@override@JsonKey(name: 'amount') final  String amount;
@override@JsonKey(name: 'fee') final  String fee;
@override@JsonKey(name: 'executed_at') final  String executedAt;
@override@JsonKey(name: 'wash_sale') final  bool washSale;

/// Create a copy of TradeRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TradeRecordModelCopyWith<_TradeRecordModel> get copyWith => __$TradeRecordModelCopyWithImpl<_TradeRecordModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TradeRecordModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TradeRecordModel&&(identical(other.tradeId, tradeId) || other.tradeId == tradeId)&&(identical(other.side, side) || other.side == side)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.price, price) || other.price == price)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.executedAt, executedAt) || other.executedAt == executedAt)&&(identical(other.washSale, washSale) || other.washSale == washSale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tradeId,side,qty,price,amount,fee,executedAt,washSale);

@override
String toString() {
  return 'TradeRecordModel(tradeId: $tradeId, side: $side, qty: $qty, price: $price, amount: $amount, fee: $fee, executedAt: $executedAt, washSale: $washSale)';
}


}

/// @nodoc
abstract mixin class _$TradeRecordModelCopyWith<$Res> implements $TradeRecordModelCopyWith<$Res> {
  factory _$TradeRecordModelCopyWith(_TradeRecordModel value, $Res Function(_TradeRecordModel) _then) = __$TradeRecordModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'trade_id') String tradeId,@JsonKey(name: 'side') String side,@JsonKey(name: 'quantity') int qty,@JsonKey(name: 'price') String price,@JsonKey(name: 'amount') String amount,@JsonKey(name: 'fee') String fee,@JsonKey(name: 'executed_at') String executedAt,@JsonKey(name: 'wash_sale') bool washSale
});




}
/// @nodoc
class __$TradeRecordModelCopyWithImpl<$Res>
    implements _$TradeRecordModelCopyWith<$Res> {
  __$TradeRecordModelCopyWithImpl(this._self, this._then);

  final _TradeRecordModel _self;
  final $Res Function(_TradeRecordModel) _then;

/// Create a copy of TradeRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tradeId = null,Object? side = null,Object? qty = null,Object? price = null,Object? amount = null,Object? fee = null,Object? executedAt = null,Object? washSale = null,}) {
  return _then(_TradeRecordModel(
tradeId: null == tradeId ? _self.tradeId : tradeId // ignore: cast_nullable_to_non_nullable
as String,side: null == side ? _self.side : side // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,fee: null == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as String,executedAt: null == executedAt ? _self.executedAt : executedAt // ignore: cast_nullable_to_non_nullable
as String,washSale: null == washSale ? _self.washSale : washSale // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
