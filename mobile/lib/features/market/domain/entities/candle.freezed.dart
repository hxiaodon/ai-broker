// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'candle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Candle _$CandleFromJson(Map<String, dynamic> json) {
  return _Candle.fromJson(json);
}

/// @nodoc
mixin _$Candle {
  DateTime get timestamp =>
      throw _privateConstructorUsedError; // UTC, bar open time
  String get open => throw _privateConstructorUsedError;
  String get high => throw _privateConstructorUsedError;
  String get low => throw _privateConstructorUsedError;
  String get close => throw _privateConstructorUsedError;
  int get volume => throw _privateConstructorUsedError;
  String get interval => throw _privateConstructorUsedError;

  /// Serializes this Candle to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Candle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CandleCopyWith<Candle> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CandleCopyWith<$Res> {
  factory $CandleCopyWith(Candle value, $Res Function(Candle) then) =
      _$CandleCopyWithImpl<$Res, Candle>;
  @useResult
  $Res call({
    DateTime timestamp,
    String open,
    String high,
    String low,
    String close,
    int volume,
    String interval,
  });
}

/// @nodoc
class _$CandleCopyWithImpl<$Res, $Val extends Candle>
    implements $CandleCopyWith<$Res> {
  _$CandleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Candle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? volume = null,
    Object? interval = null,
  }) {
    return _then(
      _value.copyWith(
            timestamp:
                null == timestamp
                    ? _value.timestamp
                    : timestamp // ignore: cast_nullable_to_non_nullable
                        as DateTime,
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
            close:
                null == close
                    ? _value.close
                    : close // ignore: cast_nullable_to_non_nullable
                        as String,
            volume:
                null == volume
                    ? _value.volume
                    : volume // ignore: cast_nullable_to_non_nullable
                        as int,
            interval:
                null == interval
                    ? _value.interval
                    : interval // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CandleImplCopyWith<$Res> implements $CandleCopyWith<$Res> {
  factory _$$CandleImplCopyWith(
    _$CandleImpl value,
    $Res Function(_$CandleImpl) then,
  ) = __$$CandleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    DateTime timestamp,
    String open,
    String high,
    String low,
    String close,
    int volume,
    String interval,
  });
}

/// @nodoc
class __$$CandleImplCopyWithImpl<$Res>
    extends _$CandleCopyWithImpl<$Res, _$CandleImpl>
    implements _$$CandleImplCopyWith<$Res> {
  __$$CandleImplCopyWithImpl(
    _$CandleImpl _value,
    $Res Function(_$CandleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Candle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? open = null,
    Object? high = null,
    Object? low = null,
    Object? close = null,
    Object? volume = null,
    Object? interval = null,
  }) {
    return _then(
      _$CandleImpl(
        timestamp:
            null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                    as DateTime,
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
        close:
            null == close
                ? _value.close
                : close // ignore: cast_nullable_to_non_nullable
                    as String,
        volume:
            null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                    as int,
        interval:
            null == interval
                ? _value.interval
                : interval // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CandleImpl implements _Candle {
  const _$CandleImpl({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.interval = '1D',
  });

  factory _$CandleImpl.fromJson(Map<String, dynamic> json) =>
      _$$CandleImplFromJson(json);

  @override
  final DateTime timestamp;
  // UTC, bar open time
  @override
  final String open;
  @override
  final String high;
  @override
  final String low;
  @override
  final String close;
  @override
  final int volume;
  @override
  @JsonKey()
  final String interval;

  @override
  String toString() {
    return 'Candle(timestamp: $timestamp, open: $open, high: $high, low: $low, close: $close, volume: $volume, interval: $interval)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CandleImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.interval, interval) ||
                other.interval == interval));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    timestamp,
    open,
    high,
    low,
    close,
    volume,
    interval,
  );

  /// Create a copy of Candle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CandleImplCopyWith<_$CandleImpl> get copyWith =>
      __$$CandleImplCopyWithImpl<_$CandleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CandleImplToJson(this);
  }
}

abstract class _Candle implements Candle {
  const factory _Candle({
    required final DateTime timestamp,
    required final String open,
    required final String high,
    required final String low,
    required final String close,
    required final int volume,
    final String interval,
  }) = _$CandleImpl;

  factory _Candle.fromJson(Map<String, dynamic> json) = _$CandleImpl.fromJson;

  @override
  DateTime get timestamp; // UTC, bar open time
  @override
  String get open;
  @override
  String get high;
  @override
  String get low;
  @override
  String get close;
  @override
  int get volume;
  @override
  String get interval;

  /// Create a copy of Candle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CandleImplCopyWith<_$CandleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
