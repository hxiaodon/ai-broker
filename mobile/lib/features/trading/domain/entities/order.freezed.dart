// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  String get orderId => throw _privateConstructorUsedError;
  String get symbol => throw _privateConstructorUsedError;
  OrderSide get side => throw _privateConstructorUsedError;
  OrderType get type => throw _privateConstructorUsedError;
  OrderStatus get status => throw _privateConstructorUsedError;
  String get quantity =>
      throw _privateConstructorUsedError; // e.g. "100" (whole shares)
  String? get limitPrice =>
      throw _privateConstructorUsedError; // Required for limit/stopLimit orders
  String? get stopPrice =>
      throw _privateConstructorUsedError; // Required for stopLimit orders
  String? get filledQuantity => throw _privateConstructorUsedError;
  String? get avgFillPrice => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError; // UTC
  DateTime? get filledAt => throw _privateConstructorUsedError; // UTC
  OrderMarket get market => throw _privateConstructorUsedError;
  String? get idempotencyKey => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call({
    String orderId,
    String symbol,
    OrderSide side,
    OrderType type,
    OrderStatus status,
    String quantity,
    String? limitPrice,
    String? stopPrice,
    String? filledQuantity,
    String? avgFillPrice,
    DateTime createdAt,
    DateTime? filledAt,
    OrderMarket market,
    String? idempotencyKey,
  });
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? symbol = null,
    Object? side = null,
    Object? type = null,
    Object? status = null,
    Object? quantity = null,
    Object? limitPrice = freezed,
    Object? stopPrice = freezed,
    Object? filledQuantity = freezed,
    Object? avgFillPrice = freezed,
    Object? createdAt = null,
    Object? filledAt = freezed,
    Object? market = null,
    Object? idempotencyKey = freezed,
  }) {
    return _then(
      _value.copyWith(
            orderId:
                null == orderId
                    ? _value.orderId
                    : orderId // ignore: cast_nullable_to_non_nullable
                        as String,
            symbol:
                null == symbol
                    ? _value.symbol
                    : symbol // ignore: cast_nullable_to_non_nullable
                        as String,
            side:
                null == side
                    ? _value.side
                    : side // ignore: cast_nullable_to_non_nullable
                        as OrderSide,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as OrderType,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as OrderStatus,
            quantity:
                null == quantity
                    ? _value.quantity
                    : quantity // ignore: cast_nullable_to_non_nullable
                        as String,
            limitPrice:
                freezed == limitPrice
                    ? _value.limitPrice
                    : limitPrice // ignore: cast_nullable_to_non_nullable
                        as String?,
            stopPrice:
                freezed == stopPrice
                    ? _value.stopPrice
                    : stopPrice // ignore: cast_nullable_to_non_nullable
                        as String?,
            filledQuantity:
                freezed == filledQuantity
                    ? _value.filledQuantity
                    : filledQuantity // ignore: cast_nullable_to_non_nullable
                        as String?,
            avgFillPrice:
                freezed == avgFillPrice
                    ? _value.avgFillPrice
                    : avgFillPrice // ignore: cast_nullable_to_non_nullable
                        as String?,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            filledAt:
                freezed == filledAt
                    ? _value.filledAt
                    : filledAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            market:
                null == market
                    ? _value.market
                    : market // ignore: cast_nullable_to_non_nullable
                        as OrderMarket,
            idempotencyKey:
                freezed == idempotencyKey
                    ? _value.idempotencyKey
                    : idempotencyKey // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
    _$OrderImpl value,
    $Res Function(_$OrderImpl) then,
  ) = __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String orderId,
    String symbol,
    OrderSide side,
    OrderType type,
    OrderStatus status,
    String quantity,
    String? limitPrice,
    String? stopPrice,
    String? filledQuantity,
    String? avgFillPrice,
    DateTime createdAt,
    DateTime? filledAt,
    OrderMarket market,
    String? idempotencyKey,
  });
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
    _$OrderImpl _value,
    $Res Function(_$OrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? symbol = null,
    Object? side = null,
    Object? type = null,
    Object? status = null,
    Object? quantity = null,
    Object? limitPrice = freezed,
    Object? stopPrice = freezed,
    Object? filledQuantity = freezed,
    Object? avgFillPrice = freezed,
    Object? createdAt = null,
    Object? filledAt = freezed,
    Object? market = null,
    Object? idempotencyKey = freezed,
  }) {
    return _then(
      _$OrderImpl(
        orderId:
            null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                    as String,
        symbol:
            null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                    as String,
        side:
            null == side
                ? _value.side
                : side // ignore: cast_nullable_to_non_nullable
                    as OrderSide,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as OrderType,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as OrderStatus,
        quantity:
            null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                    as String,
        limitPrice:
            freezed == limitPrice
                ? _value.limitPrice
                : limitPrice // ignore: cast_nullable_to_non_nullable
                    as String?,
        stopPrice:
            freezed == stopPrice
                ? _value.stopPrice
                : stopPrice // ignore: cast_nullable_to_non_nullable
                    as String?,
        filledQuantity:
            freezed == filledQuantity
                ? _value.filledQuantity
                : filledQuantity // ignore: cast_nullable_to_non_nullable
                    as String?,
        avgFillPrice:
            freezed == avgFillPrice
                ? _value.avgFillPrice
                : avgFillPrice // ignore: cast_nullable_to_non_nullable
                    as String?,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        filledAt:
            freezed == filledAt
                ? _value.filledAt
                : filledAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        market:
            null == market
                ? _value.market
                : market // ignore: cast_nullable_to_non_nullable
                    as OrderMarket,
        idempotencyKey:
            freezed == idempotencyKey
                ? _value.idempotencyKey
                : idempotencyKey // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderImpl implements _Order {
  const _$OrderImpl({
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.type,
    required this.status,
    required this.quantity,
    this.limitPrice,
    this.stopPrice,
    this.filledQuantity,
    this.avgFillPrice,
    required this.createdAt,
    this.filledAt,
    this.market = OrderMarket.us,
    this.idempotencyKey,
  });

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  @override
  final String orderId;
  @override
  final String symbol;
  @override
  final OrderSide side;
  @override
  final OrderType type;
  @override
  final OrderStatus status;
  @override
  final String quantity;
  // e.g. "100" (whole shares)
  @override
  final String? limitPrice;
  // Required for limit/stopLimit orders
  @override
  final String? stopPrice;
  // Required for stopLimit orders
  @override
  final String? filledQuantity;
  @override
  final String? avgFillPrice;
  @override
  final DateTime createdAt;
  // UTC
  @override
  final DateTime? filledAt;
  // UTC
  @override
  @JsonKey()
  final OrderMarket market;
  @override
  final String? idempotencyKey;

  @override
  String toString() {
    return 'Order(orderId: $orderId, symbol: $symbol, side: $side, type: $type, status: $status, quantity: $quantity, limitPrice: $limitPrice, stopPrice: $stopPrice, filledQuantity: $filledQuantity, avgFillPrice: $avgFillPrice, createdAt: $createdAt, filledAt: $filledAt, market: $market, idempotencyKey: $idempotencyKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.side, side) || other.side == side) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.limitPrice, limitPrice) ||
                other.limitPrice == limitPrice) &&
            (identical(other.stopPrice, stopPrice) ||
                other.stopPrice == stopPrice) &&
            (identical(other.filledQuantity, filledQuantity) ||
                other.filledQuantity == filledQuantity) &&
            (identical(other.avgFillPrice, avgFillPrice) ||
                other.avgFillPrice == avgFillPrice) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.filledAt, filledAt) ||
                other.filledAt == filledAt) &&
            (identical(other.market, market) || other.market == market) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    orderId,
    symbol,
    side,
    type,
    status,
    quantity,
    limitPrice,
    stopPrice,
    filledQuantity,
    avgFillPrice,
    createdAt,
    filledAt,
    market,
    idempotencyKey,
  );

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(this);
  }
}

abstract class _Order implements Order {
  const factory _Order({
    required final String orderId,
    required final String symbol,
    required final OrderSide side,
    required final OrderType type,
    required final OrderStatus status,
    required final String quantity,
    final String? limitPrice,
    final String? stopPrice,
    final String? filledQuantity,
    final String? avgFillPrice,
    required final DateTime createdAt,
    final DateTime? filledAt,
    final OrderMarket market,
    final String? idempotencyKey,
  }) = _$OrderImpl;

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  @override
  String get orderId;
  @override
  String get symbol;
  @override
  OrderSide get side;
  @override
  OrderType get type;
  @override
  OrderStatus get status;
  @override
  String get quantity; // e.g. "100" (whole shares)
  @override
  String? get limitPrice; // Required for limit/stopLimit orders
  @override
  String? get stopPrice; // Required for stopLimit orders
  @override
  String? get filledQuantity;
  @override
  String? get avgFillPrice;
  @override
  DateTime get createdAt; // UTC
  @override
  DateTime? get filledAt; // UTC
  @override
  OrderMarket get market;
  @override
  String? get idempotencyKey;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
