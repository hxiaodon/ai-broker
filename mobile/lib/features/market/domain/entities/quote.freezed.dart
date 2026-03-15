// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Quote _$QuoteFromJson(Map<String, dynamic> json) {
  return _Quote.fromJson(json);
}

/// @nodoc
mixin _$Quote {
  String get symbol => throw _privateConstructorUsedError;
  String get lastPrice =>
      throw _privateConstructorUsedError; // Decimal string e.g. "150.2500"
  String get change => throw _privateConstructorUsedError; // Absolute change
  String get changePercent =>
      throw _privateConstructorUsedError; // e.g. "0.0352" = +3.52%
  String get open => throw _privateConstructorUsedError;
  String get high => throw _privateConstructorUsedError;
  String get low => throw _privateConstructorUsedError;
  String get prevClose => throw _privateConstructorUsedError;
  int get volume => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError; // UTC
  String get market => throw _privateConstructorUsedError;

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuoteCopyWith<Quote> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuoteCopyWith<$Res> {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) then) =
      _$QuoteCopyWithImpl<$Res, Quote>;
  @useResult
  $Res call({
    String symbol,
    String lastPrice,
    String change,
    String changePercent,
    String open,
    String high,
    String low,
    String prevClose,
    int volume,
    DateTime timestamp,
    String market,
  });
}

/// @nodoc
class _$QuoteCopyWithImpl<$Res, $Val extends Quote>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? lastPrice = null,
    Object? change = null,
    Object? changePercent = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? prevClose = null,
    Object? volume = null,
    Object? timestamp = null,
    Object? market = null,
  }) {
    return _then(
      _value.copyWith(
            symbol:
                null == symbol
                    ? _value.symbol
                    : symbol // ignore: cast_nullable_to_non_nullable
                        as String,
            lastPrice:
                null == lastPrice
                    ? _value.lastPrice
                    : lastPrice // ignore: cast_nullable_to_non_nullable
                        as String,
            change:
                null == change
                    ? _value.change
                    : change // ignore: cast_nullable_to_non_nullable
                        as String,
            changePercent:
                null == changePercent
                    ? _value.changePercent
                    : changePercent // ignore: cast_nullable_to_non_nullable
                        as String,
            open:
                null == open
                    ? _value.open
                    : open // ignore: cast_nullable_to_non_nullable
                        as String,
            high:
                null == high
                    ? _value.high
                    : high // ignore: cast_nullable_to_non_nullable
                        as String,
            low:
                null == low
                    ? _value.low
                    : low // ignore: cast_nullable_to_non_nullable
                        as String,
            prevClose:
                null == prevClose
                    ? _value.prevClose
                    : prevClose // ignore: cast_nullable_to_non_nullable
                        as String,
            volume:
                null == volume
                    ? _value.volume
                    : volume // ignore: cast_nullable_to_non_nullable
                        as int,
            timestamp:
                null == timestamp
                    ? _value.timestamp
                    : timestamp // ignore: cast_nullable_to_non_nullable
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
abstract class _$$QuoteImplCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$$QuoteImplCopyWith(
    _$QuoteImpl value,
    $Res Function(_$QuoteImpl) then,
  ) = __$$QuoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String symbol,
    String lastPrice,
    String change,
    String changePercent,
    String open,
    String high,
    String low,
    String prevClose,
    int volume,
    DateTime timestamp,
    String market,
  });
}

/// @nodoc
class __$$QuoteImplCopyWithImpl<$Res>
    extends _$QuoteCopyWithImpl<$Res, _$QuoteImpl>
    implements _$$QuoteImplCopyWith<$Res> {
  __$$QuoteImplCopyWithImpl(
    _$QuoteImpl _value,
    $Res Function(_$QuoteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? lastPrice = null,
    Object? change = null,
    Object? changePercent = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? prevClose = null,
    Object? volume = null,
    Object? timestamp = null,
    Object? market = null,
  }) {
    return _then(
      _$QuoteImpl(
        symbol:
            null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                    as String,
        lastPrice:
            null == lastPrice
                ? _value.lastPrice
                : lastPrice // ignore: cast_nullable_to_non_nullable
                    as String,
        change:
            null == change
                ? _value.change
                : change // ignore: cast_nullable_to_non_nullable
                    as String,
        changePercent:
            null == changePercent
                ? _value.changePercent
                : changePercent // ignore: cast_nullable_to_non_nullable
                    as String,
        open:
            null == open
                ? _value.open
                : open // ignore: cast_nullable_to_non_nullable
                    as String,
        high:
            null == high
                ? _value.high
                : high // ignore: cast_nullable_to_non_nullable
                    as String,
        low:
            null == low
                ? _value.low
                : low // ignore: cast_nullable_to_non_nullable
                    as String,
        prevClose:
            null == prevClose
                ? _value.prevClose
                : prevClose // ignore: cast_nullable_to_non_nullable
                    as String,
        volume:
            null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                    as int,
        timestamp:
            null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
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
class _$QuoteImpl implements _Quote {
  const _$QuoteImpl({
    required this.symbol,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.prevClose,
    required this.volume,
    required this.timestamp,
    this.market = 'US',
  });

  factory _$QuoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuoteImplFromJson(json);

  @override
  final String symbol;
  @override
  final String lastPrice;
  // Decimal string e.g. "150.2500"
  @override
  final String change;
  // Absolute change
  @override
  final String changePercent;
  // e.g. "0.0352" = +3.52%
  @override
  final String open;
  @override
  final String high;
  @override
  final String low;
  @override
  final String prevClose;
  @override
  final int volume;
  @override
  final DateTime timestamp;
  // UTC
  @override
  @JsonKey()
  final String market;

  @override
  String toString() {
    return 'Quote(symbol: $symbol, lastPrice: $lastPrice, change: $change, changePercent: $changePercent, open: $open, high: $high, low: $low, prevClose: $prevClose, volume: $volume, timestamp: $timestamp, market: $market)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuoteImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.lastPrice, lastPrice) ||
                other.lastPrice == lastPrice) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.changePercent, changePercent) ||
                other.changePercent == changePercent) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.prevClose, prevClose) ||
                other.prevClose == prevClose) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.market, market) || other.market == market));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    symbol,
    lastPrice,
    change,
    changePercent,
    open,
    high,
    low,
    prevClose,
    volume,
    timestamp,
    market,
  );

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuoteImplCopyWith<_$QuoteImpl> get copyWith =>
      __$$QuoteImplCopyWithImpl<_$QuoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuoteImplToJson(this);
  }
}

abstract class _Quote implements Quote {
  const factory _Quote({
    required final String symbol,
    required final String lastPrice,
    required final String change,
    required final String changePercent,
    required final String open,
    required final String high,
    required final String low,
    required final String prevClose,
    required final int volume,
    required final DateTime timestamp,
    final String market,
  }) = _$QuoteImpl;

  factory _Quote.fromJson(Map<String, dynamic> json) = _$QuoteImpl.fromJson;

  @override
  String get symbol;
  @override
  String get lastPrice; // Decimal string e.g. "150.2500"
  @override
  String get change; // Absolute change
  @override
  String get changePercent; // e.g. "0.0352" = +3.52%
  @override
  String get open;
  @override
  String get high;
  @override
  String get low;
  @override
  String get prevClose;
  @override
  int get volume;
  @override
  DateTime get timestamp; // UTC
  @override
  String get market;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuoteImplCopyWith<_$QuoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
