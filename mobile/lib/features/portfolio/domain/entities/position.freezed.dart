// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Position _$PositionFromJson(Map<String, dynamic> json) {
  return _Position.fromJson(json);
}

/// @nodoc
mixin _$Position {
  String get symbol => throw _privateConstructorUsedError;
  String get quantity => throw _privateConstructorUsedError; // Shares held
  String get avgCostPrice =>
      throw _privateConstructorUsedError; // Average cost basis
  String get marketValue =>
      throw _privateConstructorUsedError; // Current market value
  String get unrealizedPnl =>
      throw _privateConstructorUsedError; // Unrealized P&L
  String get unrealizedPnlPercent => throw _privateConstructorUsedError;
  String get totalCost => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError; // UTC
  String get market => throw _privateConstructorUsedError;

  /// Serializes this Position to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PositionCopyWith<Position> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PositionCopyWith<$Res> {
  factory $PositionCopyWith(Position value, $Res Function(Position) then) =
      _$PositionCopyWithImpl<$Res, Position>;
  @useResult
  $Res call({
    String symbol,
    String quantity,
    String avgCostPrice,
    String marketValue,
    String unrealizedPnl,
    String unrealizedPnlPercent,
    String totalCost,
    DateTime updatedAt,
    String market,
  });
}

/// @nodoc
class _$PositionCopyWithImpl<$Res, $Val extends Position>
    implements $PositionCopyWith<$Res> {
  _$PositionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? quantity = null,
    Object? avgCostPrice = null,
    Object? marketValue = null,
    Object? unrealizedPnl = null,
    Object? unrealizedPnlPercent = null,
    Object? totalCost = null,
    Object? updatedAt = null,
    Object? market = null,
  }) {
    return _then(
      _value.copyWith(
            symbol:
                null == symbol
                    ? _value.symbol
                    : symbol // ignore: cast_nullable_to_non_nullable
                        as String,
            quantity:
                null == quantity
                    ? _value.quantity
                    : quantity // ignore: cast_nullable_to_non_nullable
                        as String,
            avgCostPrice:
                null == avgCostPrice
                    ? _value.avgCostPrice
                    : avgCostPrice // ignore: cast_nullable_to_non_nullable
                        as String,
            marketValue:
                null == marketValue
                    ? _value.marketValue
                    : marketValue // ignore: cast_nullable_to_non_nullable
                        as String,
            unrealizedPnl:
                null == unrealizedPnl
                    ? _value.unrealizedPnl
                    : unrealizedPnl // ignore: cast_nullable_to_non_nullable
                        as String,
            unrealizedPnlPercent:
                null == unrealizedPnlPercent
                    ? _value.unrealizedPnlPercent
                    : unrealizedPnlPercent // ignore: cast_nullable_to_non_nullable
                        as String,
            totalCost:
                null == totalCost
                    ? _value.totalCost
                    : totalCost // ignore: cast_nullable_to_non_nullable
                        as String,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            market:
                null == market
                    ? _value.market
                    : market // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PositionImplCopyWith<$Res>
    implements $PositionCopyWith<$Res> {
  factory _$$PositionImplCopyWith(
    _$PositionImpl value,
    $Res Function(_$PositionImpl) then,
  ) = __$$PositionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String symbol,
    String quantity,
    String avgCostPrice,
    String marketValue,
    String unrealizedPnl,
    String unrealizedPnlPercent,
    String totalCost,
    DateTime updatedAt,
    String market,
  });
}

/// @nodoc
class __$$PositionImplCopyWithImpl<$Res>
    extends _$PositionCopyWithImpl<$Res, _$PositionImpl>
    implements _$$PositionImplCopyWith<$Res> {
  __$$PositionImplCopyWithImpl(
    _$PositionImpl _value,
    $Res Function(_$PositionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? quantity = null,
    Object? avgCostPrice = null,
    Object? marketValue = null,
    Object? unrealizedPnl = null,
    Object? unrealizedPnlPercent = null,
    Object? totalCost = null,
    Object? updatedAt = null,
    Object? market = null,
  }) {
    return _then(
      _$PositionImpl(
        symbol:
            null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                    as String,
        quantity:
            null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                    as String,
        avgCostPrice:
            null == avgCostPrice
                ? _value.avgCostPrice
                : avgCostPrice // ignore: cast_nullable_to_non_nullable
                    as String,
        marketValue:
            null == marketValue
                ? _value.marketValue
                : marketValue // ignore: cast_nullable_to_non_nullable
                    as String,
        unrealizedPnl:
            null == unrealizedPnl
                ? _value.unrealizedPnl
                : unrealizedPnl // ignore: cast_nullable_to_non_nullable
                    as String,
        unrealizedPnlPercent:
            null == unrealizedPnlPercent
                ? _value.unrealizedPnlPercent
                : unrealizedPnlPercent // ignore: cast_nullable_to_non_nullable
                    as String,
        totalCost:
            null == totalCost
                ? _value.totalCost
                : totalCost // ignore: cast_nullable_to_non_nullable
                    as String,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        market:
            null == market
                ? _value.market
                : market // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PositionImpl implements _Position {
  const _$PositionImpl({
    required this.symbol,
    required this.quantity,
    required this.avgCostPrice,
    required this.marketValue,
    required this.unrealizedPnl,
    required this.unrealizedPnlPercent,
    required this.totalCost,
    required this.updatedAt,
    this.market = 'US',
  });

  factory _$PositionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PositionImplFromJson(json);

  @override
  final String symbol;
  @override
  final String quantity;
  // Shares held
  @override
  final String avgCostPrice;
  // Average cost basis
  @override
  final String marketValue;
  // Current market value
  @override
  final String unrealizedPnl;
  // Unrealized P&L
  @override
  final String unrealizedPnlPercent;
  @override
  final String totalCost;
  @override
  final DateTime updatedAt;
  // UTC
  @override
  @JsonKey()
  final String market;

  @override
  String toString() {
    return 'Position(symbol: $symbol, quantity: $quantity, avgCostPrice: $avgCostPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPercent: $unrealizedPnlPercent, totalCost: $totalCost, updatedAt: $updatedAt, market: $market)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PositionImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.avgCostPrice, avgCostPrice) ||
                other.avgCostPrice == avgCostPrice) &&
            (identical(other.marketValue, marketValue) ||
                other.marketValue == marketValue) &&
            (identical(other.unrealizedPnl, unrealizedPnl) ||
                other.unrealizedPnl == unrealizedPnl) &&
            (identical(other.unrealizedPnlPercent, unrealizedPnlPercent) ||
                other.unrealizedPnlPercent == unrealizedPnlPercent) &&
            (identical(other.totalCost, totalCost) ||
                other.totalCost == totalCost) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.market, market) || other.market == market));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    symbol,
    quantity,
    avgCostPrice,
    marketValue,
    unrealizedPnl,
    unrealizedPnlPercent,
    totalCost,
    updatedAt,
    market,
  );

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PositionImplCopyWith<_$PositionImpl> get copyWith =>
      __$$PositionImplCopyWithImpl<_$PositionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PositionImplToJson(this);
  }
}

abstract class _Position implements Position {
  const factory _Position({
    required final String symbol,
    required final String quantity,
    required final String avgCostPrice,
    required final String marketValue,
    required final String unrealizedPnl,
    required final String unrealizedPnlPercent,
    required final String totalCost,
    required final DateTime updatedAt,
    final String market,
  }) = _$PositionImpl;

  factory _Position.fromJson(Map<String, dynamic> json) =
      _$PositionImpl.fromJson;

  @override
  String get symbol;
  @override
  String get quantity; // Shares held
  @override
  String get avgCostPrice; // Average cost basis
  @override
  String get marketValue; // Current market value
  @override
  String get unrealizedPnl; // Unrealized P&L
  @override
  String get unrealizedPnlPercent;
  @override
  String get totalCost;
  @override
  DateTime get updatedAt; // UTC
  @override
  String get market;

  /// Create a copy of Position
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PositionImplCopyWith<_$PositionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
