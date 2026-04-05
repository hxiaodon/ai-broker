// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'market_response_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuoteDto {

 String get symbol; String get name;@JsonKey(name: 'name_zh') String get nameZh; String get market; String get price; String get change;@JsonKey(name: 'change_pct') String get changePct; int get volume; String? get bid; String? get ask; String get turnover;@JsonKey(name: 'prev_close') String get prevClose; String get open; String get high; String get low;@JsonKey(name: 'market_cap') String get marketCap;@JsonKey(name: 'pe_ratio') String? get peRatio; bool get delayed;@JsonKey(name: 'market_status') String get marketStatus;// §1.7 — present in all quote responses; defaulted for spec-example omissions
@JsonKey(name: 'is_stale') bool get isStale;@JsonKey(name: 'stale_since_ms') int get staleSinceMs;
/// Create a copy of QuoteDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteDtoCopyWith<QuoteDto> get copyWith => _$QuoteDtoCopyWithImpl<QuoteDto>(this as QuoteDto, _$identity);

  /// Serializes this QuoteDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,volume,bid,ask,turnover,prevClose,open,high,low,marketCap,peRatio,delayed,marketStatus,isStale,staleSinceMs]);

@override
String toString() {
  return 'QuoteDto(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, volume: $volume, bid: $bid, ask: $ask, turnover: $turnover, prevClose: $prevClose, open: $open, high: $high, low: $low, marketCap: $marketCap, peRatio: $peRatio, delayed: $delayed, marketStatus: $marketStatus, isStale: $isStale, staleSinceMs: $staleSinceMs)';
}


}

/// @nodoc
abstract mixin class $QuoteDtoCopyWith<$Res>  {
  factory $QuoteDtoCopyWith(QuoteDto value, $Res Function(QuoteDto) _then) = _$QuoteDtoCopyWithImpl;
@useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String market, String price, String change,@JsonKey(name: 'change_pct') String changePct, int volume, String? bid, String? ask, String turnover,@JsonKey(name: 'prev_close') String prevClose, String open, String high, String low,@JsonKey(name: 'market_cap') String marketCap,@JsonKey(name: 'pe_ratio') String? peRatio, bool delayed,@JsonKey(name: 'market_status') String marketStatus,@JsonKey(name: 'is_stale') bool isStale,@JsonKey(name: 'stale_since_ms') int staleSinceMs
});




}
/// @nodoc
class _$QuoteDtoCopyWithImpl<$Res>
    implements $QuoteDtoCopyWith<$Res> {
  _$QuoteDtoCopyWithImpl(this._self, this._then);

  final QuoteDto _self;
  final $Res Function(QuoteDto) _then;

/// Create a copy of QuoteDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? bid = freezed,Object? ask = freezed,Object? turnover = null,Object? prevClose = null,Object? open = null,Object? high = null,Object? low = null,Object? marketCap = null,Object? peRatio = freezed,Object? delayed = null,Object? marketStatus = null,Object? isStale = null,Object? staleSinceMs = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as String?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as String?,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as String,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as String,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as String,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: freezed == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as String,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteDto].
extension QuoteDtoPatterns on QuoteDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteDto value)  $default,){
final _that = this;
switch (_that) {
case _QuoteDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteDto value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  int volume,  String? bid,  String? ask,  String turnover, @JsonKey(name: 'prev_close')  String prevClose,  String open,  String high,  String low, @JsonKey(name: 'market_cap')  String marketCap, @JsonKey(name: 'pe_ratio')  String? peRatio,  bool delayed, @JsonKey(name: 'market_status')  String marketStatus, @JsonKey(name: 'is_stale')  bool isStale, @JsonKey(name: 'stale_since_ms')  int staleSinceMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteDto() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.volume,_that.bid,_that.ask,_that.turnover,_that.prevClose,_that.open,_that.high,_that.low,_that.marketCap,_that.peRatio,_that.delayed,_that.marketStatus,_that.isStale,_that.staleSinceMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  int volume,  String? bid,  String? ask,  String turnover, @JsonKey(name: 'prev_close')  String prevClose,  String open,  String high,  String low, @JsonKey(name: 'market_cap')  String marketCap, @JsonKey(name: 'pe_ratio')  String? peRatio,  bool delayed, @JsonKey(name: 'market_status')  String marketStatus, @JsonKey(name: 'is_stale')  bool isStale, @JsonKey(name: 'stale_since_ms')  int staleSinceMs)  $default,) {final _that = this;
switch (_that) {
case _QuoteDto():
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.volume,_that.bid,_that.ask,_that.turnover,_that.prevClose,_that.open,_that.high,_that.low,_that.marketCap,_that.peRatio,_that.delayed,_that.marketStatus,_that.isStale,_that.staleSinceMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  int volume,  String? bid,  String? ask,  String turnover, @JsonKey(name: 'prev_close')  String prevClose,  String open,  String high,  String low, @JsonKey(name: 'market_cap')  String marketCap, @JsonKey(name: 'pe_ratio')  String? peRatio,  bool delayed, @JsonKey(name: 'market_status')  String marketStatus, @JsonKey(name: 'is_stale')  bool isStale, @JsonKey(name: 'stale_since_ms')  int staleSinceMs)?  $default,) {final _that = this;
switch (_that) {
case _QuoteDto() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.volume,_that.bid,_that.ask,_that.turnover,_that.prevClose,_that.open,_that.high,_that.low,_that.marketCap,_that.peRatio,_that.delayed,_that.marketStatus,_that.isStale,_that.staleSinceMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuoteDto implements QuoteDto {
  const _QuoteDto({required this.symbol, required this.name, @JsonKey(name: 'name_zh') required this.nameZh, required this.market, required this.price, required this.change, @JsonKey(name: 'change_pct') required this.changePct, required this.volume, this.bid, this.ask, required this.turnover, @JsonKey(name: 'prev_close') required this.prevClose, required this.open, required this.high, required this.low, @JsonKey(name: 'market_cap') required this.marketCap, @JsonKey(name: 'pe_ratio') this.peRatio, required this.delayed, @JsonKey(name: 'market_status') required this.marketStatus, @JsonKey(name: 'is_stale') this.isStale = false, @JsonKey(name: 'stale_since_ms') this.staleSinceMs = 0});
  factory _QuoteDto.fromJson(Map<String, dynamic> json) => _$QuoteDtoFromJson(json);

@override final  String symbol;
@override final  String name;
@override@JsonKey(name: 'name_zh') final  String nameZh;
@override final  String market;
@override final  String price;
@override final  String change;
@override@JsonKey(name: 'change_pct') final  String changePct;
@override final  int volume;
@override final  String? bid;
@override final  String? ask;
@override final  String turnover;
@override@JsonKey(name: 'prev_close') final  String prevClose;
@override final  String open;
@override final  String high;
@override final  String low;
@override@JsonKey(name: 'market_cap') final  String marketCap;
@override@JsonKey(name: 'pe_ratio') final  String? peRatio;
@override final  bool delayed;
@override@JsonKey(name: 'market_status') final  String marketStatus;
// §1.7 — present in all quote responses; defaulted for spec-example omissions
@override@JsonKey(name: 'is_stale') final  bool isStale;
@override@JsonKey(name: 'stale_since_ms') final  int staleSinceMs;

/// Create a copy of QuoteDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteDtoCopyWith<_QuoteDto> get copyWith => __$QuoteDtoCopyWithImpl<_QuoteDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,volume,bid,ask,turnover,prevClose,open,high,low,marketCap,peRatio,delayed,marketStatus,isStale,staleSinceMs]);

@override
String toString() {
  return 'QuoteDto(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, volume: $volume, bid: $bid, ask: $ask, turnover: $turnover, prevClose: $prevClose, open: $open, high: $high, low: $low, marketCap: $marketCap, peRatio: $peRatio, delayed: $delayed, marketStatus: $marketStatus, isStale: $isStale, staleSinceMs: $staleSinceMs)';
}


}

/// @nodoc
abstract mixin class _$QuoteDtoCopyWith<$Res> implements $QuoteDtoCopyWith<$Res> {
  factory _$QuoteDtoCopyWith(_QuoteDto value, $Res Function(_QuoteDto) _then) = __$QuoteDtoCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String market, String price, String change,@JsonKey(name: 'change_pct') String changePct, int volume, String? bid, String? ask, String turnover,@JsonKey(name: 'prev_close') String prevClose, String open, String high, String low,@JsonKey(name: 'market_cap') String marketCap,@JsonKey(name: 'pe_ratio') String? peRatio, bool delayed,@JsonKey(name: 'market_status') String marketStatus,@JsonKey(name: 'is_stale') bool isStale,@JsonKey(name: 'stale_since_ms') int staleSinceMs
});




}
/// @nodoc
class __$QuoteDtoCopyWithImpl<$Res>
    implements _$QuoteDtoCopyWith<$Res> {
  __$QuoteDtoCopyWithImpl(this._self, this._then);

  final _QuoteDto _self;
  final $Res Function(_QuoteDto) _then;

/// Create a copy of QuoteDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? bid = freezed,Object? ask = freezed,Object? turnover = null,Object? prevClose = null,Object? open = null,Object? high = null,Object? low = null,Object? marketCap = null,Object? peRatio = freezed,Object? delayed = null,Object? marketStatus = null,Object? isStale = null,Object? staleSinceMs = null,}) {
  return _then(_QuoteDto(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as String?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as String?,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as String,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as String,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as String,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: freezed == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as String,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QuotesResponseDto {

 Map<String, QuoteDto> get quotes;@JsonKey(name: 'as_of') String get asOf;
/// Create a copy of QuotesResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuotesResponseDtoCopyWith<QuotesResponseDto> get copyWith => _$QuotesResponseDtoCopyWithImpl<QuotesResponseDto>(this as QuotesResponseDto, _$identity);

  /// Serializes this QuotesResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuotesResponseDto&&const DeepCollectionEquality().equals(other.quotes, quotes)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(quotes),asOf);

@override
String toString() {
  return 'QuotesResponseDto(quotes: $quotes, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class $QuotesResponseDtoCopyWith<$Res>  {
  factory $QuotesResponseDtoCopyWith(QuotesResponseDto value, $Res Function(QuotesResponseDto) _then) = _$QuotesResponseDtoCopyWithImpl;
@useResult
$Res call({
 Map<String, QuoteDto> quotes,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class _$QuotesResponseDtoCopyWithImpl<$Res>
    implements $QuotesResponseDtoCopyWith<$Res> {
  _$QuotesResponseDtoCopyWithImpl(this._self, this._then);

  final QuotesResponseDto _self;
  final $Res Function(QuotesResponseDto) _then;

/// Create a copy of QuotesResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quotes = null,Object? asOf = null,}) {
  return _then(_self.copyWith(
quotes: null == quotes ? _self.quotes : quotes // ignore: cast_nullable_to_non_nullable
as Map<String, QuoteDto>,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuotesResponseDto].
extension QuotesResponseDtoPatterns on QuotesResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuotesResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuotesResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuotesResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _QuotesResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuotesResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _QuotesResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of')  String asOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuotesResponseDto() when $default != null:
return $default(_that.quotes,_that.asOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of')  String asOf)  $default,) {final _that = this;
switch (_that) {
case _QuotesResponseDto():
return $default(_that.quotes,_that.asOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of')  String asOf)?  $default,) {final _that = this;
switch (_that) {
case _QuotesResponseDto() when $default != null:
return $default(_that.quotes,_that.asOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuotesResponseDto implements QuotesResponseDto {
  const _QuotesResponseDto({required final  Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of') required this.asOf}): _quotes = quotes;
  factory _QuotesResponseDto.fromJson(Map<String, dynamic> json) => _$QuotesResponseDtoFromJson(json);

 final  Map<String, QuoteDto> _quotes;
@override Map<String, QuoteDto> get quotes {
  if (_quotes is EqualUnmodifiableMapView) return _quotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_quotes);
}

@override@JsonKey(name: 'as_of') final  String asOf;

/// Create a copy of QuotesResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuotesResponseDtoCopyWith<_QuotesResponseDto> get copyWith => __$QuotesResponseDtoCopyWithImpl<_QuotesResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuotesResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuotesResponseDto&&const DeepCollectionEquality().equals(other._quotes, _quotes)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_quotes),asOf);

@override
String toString() {
  return 'QuotesResponseDto(quotes: $quotes, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class _$QuotesResponseDtoCopyWith<$Res> implements $QuotesResponseDtoCopyWith<$Res> {
  factory _$QuotesResponseDtoCopyWith(_QuotesResponseDto value, $Res Function(_QuotesResponseDto) _then) = __$QuotesResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 Map<String, QuoteDto> quotes,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class __$QuotesResponseDtoCopyWithImpl<$Res>
    implements _$QuotesResponseDtoCopyWith<$Res> {
  __$QuotesResponseDtoCopyWithImpl(this._self, this._then);

  final _QuotesResponseDto _self;
  final $Res Function(_QuotesResponseDto) _then;

/// Create a copy of QuotesResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quotes = null,Object? asOf = null,}) {
  return _then(_QuotesResponseDto(
quotes: null == quotes ? _self._quotes : quotes // ignore: cast_nullable_to_non_nullable
as Map<String, QuoteDto>,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CandleDto {

/// Candle open time — ISO 8601 UTC string (e.g. "2026-03-13T14:30:00.000Z").
 String get t; String get o; String get h; String get l; String get c; int get v; int get n;
/// Create a copy of CandleDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CandleDtoCopyWith<CandleDto> get copyWith => _$CandleDtoCopyWithImpl<CandleDto>(this as CandleDto, _$identity);

  /// Serializes this CandleDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CandleDto&&(identical(other.t, t) || other.t == t)&&(identical(other.o, o) || other.o == o)&&(identical(other.h, h) || other.h == h)&&(identical(other.l, l) || other.l == l)&&(identical(other.c, c) || other.c == c)&&(identical(other.v, v) || other.v == v)&&(identical(other.n, n) || other.n == n));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,o,h,l,c,v,n);

@override
String toString() {
  return 'CandleDto(t: $t, o: $o, h: $h, l: $l, c: $c, v: $v, n: $n)';
}


}

/// @nodoc
abstract mixin class $CandleDtoCopyWith<$Res>  {
  factory $CandleDtoCopyWith(CandleDto value, $Res Function(CandleDto) _then) = _$CandleDtoCopyWithImpl;
@useResult
$Res call({
 String t, String o, String h, String l, String c, int v, int n
});




}
/// @nodoc
class _$CandleDtoCopyWithImpl<$Res>
    implements $CandleDtoCopyWith<$Res> {
  _$CandleDtoCopyWithImpl(this._self, this._then);

  final CandleDto _self;
  final $Res Function(CandleDto) _then;

/// Create a copy of CandleDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = null,Object? o = null,Object? h = null,Object? l = null,Object? c = null,Object? v = null,Object? n = null,}) {
  return _then(_self.copyWith(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String,o: null == o ? _self.o : o // ignore: cast_nullable_to_non_nullable
as String,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as String,l: null == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as String,c: null == c ? _self.c : c // ignore: cast_nullable_to_non_nullable
as String,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CandleDto].
extension CandleDtoPatterns on CandleDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CandleDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CandleDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CandleDto value)  $default,){
final _that = this;
switch (_that) {
case _CandleDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CandleDto value)?  $default,){
final _that = this;
switch (_that) {
case _CandleDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String t,  String o,  String h,  String l,  String c,  int v,  int n)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CandleDto() when $default != null:
return $default(_that.t,_that.o,_that.h,_that.l,_that.c,_that.v,_that.n);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String t,  String o,  String h,  String l,  String c,  int v,  int n)  $default,) {final _that = this;
switch (_that) {
case _CandleDto():
return $default(_that.t,_that.o,_that.h,_that.l,_that.c,_that.v,_that.n);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String t,  String o,  String h,  String l,  String c,  int v,  int n)?  $default,) {final _that = this;
switch (_that) {
case _CandleDto() when $default != null:
return $default(_that.t,_that.o,_that.h,_that.l,_that.c,_that.v,_that.n);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CandleDto implements CandleDto {
  const _CandleDto({required this.t, required this.o, required this.h, required this.l, required this.c, required this.v, required this.n});
  factory _CandleDto.fromJson(Map<String, dynamic> json) => _$CandleDtoFromJson(json);

/// Candle open time — ISO 8601 UTC string (e.g. "2026-03-13T14:30:00.000Z").
@override final  String t;
@override final  String o;
@override final  String h;
@override final  String l;
@override final  String c;
@override final  int v;
@override final  int n;

/// Create a copy of CandleDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CandleDtoCopyWith<_CandleDto> get copyWith => __$CandleDtoCopyWithImpl<_CandleDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CandleDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CandleDto&&(identical(other.t, t) || other.t == t)&&(identical(other.o, o) || other.o == o)&&(identical(other.h, h) || other.h == h)&&(identical(other.l, l) || other.l == l)&&(identical(other.c, c) || other.c == c)&&(identical(other.v, v) || other.v == v)&&(identical(other.n, n) || other.n == n));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,t,o,h,l,c,v,n);

@override
String toString() {
  return 'CandleDto(t: $t, o: $o, h: $h, l: $l, c: $c, v: $v, n: $n)';
}


}

/// @nodoc
abstract mixin class _$CandleDtoCopyWith<$Res> implements $CandleDtoCopyWith<$Res> {
  factory _$CandleDtoCopyWith(_CandleDto value, $Res Function(_CandleDto) _then) = __$CandleDtoCopyWithImpl;
@override @useResult
$Res call({
 String t, String o, String h, String l, String c, int v, int n
});




}
/// @nodoc
class __$CandleDtoCopyWithImpl<$Res>
    implements _$CandleDtoCopyWith<$Res> {
  __$CandleDtoCopyWithImpl(this._self, this._then);

  final _CandleDto _self;
  final $Res Function(_CandleDto) _then;

/// Create a copy of CandleDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = null,Object? o = null,Object? h = null,Object? l = null,Object? c = null,Object? v = null,Object? n = null,}) {
  return _then(_CandleDto(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as String,o: null == o ? _self.o : o // ignore: cast_nullable_to_non_nullable
as String,h: null == h ? _self.h : h // ignore: cast_nullable_to_non_nullable
as String,l: null == l ? _self.l : l // ignore: cast_nullable_to_non_nullable
as String,c: null == c ? _self.c : c // ignore: cast_nullable_to_non_nullable
as String,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as int,n: null == n ? _self.n : n // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$KlineResponseDto {

 String get symbol; String get period; List<CandleDto> get candles;@JsonKey(name: 'next_cursor') String? get nextCursor; int get total;
/// Create a copy of KlineResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KlineResponseDtoCopyWith<KlineResponseDto> get copyWith => _$KlineResponseDtoCopyWithImpl<KlineResponseDto>(this as KlineResponseDto, _$identity);

  /// Serializes this KlineResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KlineResponseDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.candles, candles)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,period,const DeepCollectionEquality().hash(candles),nextCursor,total);

@override
String toString() {
  return 'KlineResponseDto(symbol: $symbol, period: $period, candles: $candles, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class $KlineResponseDtoCopyWith<$Res>  {
  factory $KlineResponseDtoCopyWith(KlineResponseDto value, $Res Function(KlineResponseDto) _then) = _$KlineResponseDtoCopyWithImpl;
@useResult
$Res call({
 String symbol, String period, List<CandleDto> candles,@JsonKey(name: 'next_cursor') String? nextCursor, int total
});




}
/// @nodoc
class _$KlineResponseDtoCopyWithImpl<$Res>
    implements $KlineResponseDtoCopyWith<$Res> {
  _$KlineResponseDtoCopyWithImpl(this._self, this._then);

  final KlineResponseDto _self;
  final $Res Function(KlineResponseDto) _then;

/// Create a copy of KlineResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? period = null,Object? candles = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,candles: null == candles ? _self.candles : candles // ignore: cast_nullable_to_non_nullable
as List<CandleDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [KlineResponseDto].
extension KlineResponseDtoPatterns on KlineResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KlineResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KlineResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KlineResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _KlineResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KlineResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _KlineResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String period,  List<CandleDto> candles, @JsonKey(name: 'next_cursor')  String? nextCursor,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KlineResponseDto() when $default != null:
return $default(_that.symbol,_that.period,_that.candles,_that.nextCursor,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String period,  List<CandleDto> candles, @JsonKey(name: 'next_cursor')  String? nextCursor,  int total)  $default,) {final _that = this;
switch (_that) {
case _KlineResponseDto():
return $default(_that.symbol,_that.period,_that.candles,_that.nextCursor,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String period,  List<CandleDto> candles, @JsonKey(name: 'next_cursor')  String? nextCursor,  int total)?  $default,) {final _that = this;
switch (_that) {
case _KlineResponseDto() when $default != null:
return $default(_that.symbol,_that.period,_that.candles,_that.nextCursor,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KlineResponseDto implements KlineResponseDto {
  const _KlineResponseDto({required this.symbol, required this.period, required final  List<CandleDto> candles, @JsonKey(name: 'next_cursor') this.nextCursor, required this.total}): _candles = candles;
  factory _KlineResponseDto.fromJson(Map<String, dynamic> json) => _$KlineResponseDtoFromJson(json);

@override final  String symbol;
@override final  String period;
 final  List<CandleDto> _candles;
@override List<CandleDto> get candles {
  if (_candles is EqualUnmodifiableListView) return _candles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candles);
}

@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override final  int total;

/// Create a copy of KlineResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KlineResponseDtoCopyWith<_KlineResponseDto> get copyWith => __$KlineResponseDtoCopyWithImpl<_KlineResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KlineResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KlineResponseDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other._candles, _candles)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,period,const DeepCollectionEquality().hash(_candles),nextCursor,total);

@override
String toString() {
  return 'KlineResponseDto(symbol: $symbol, period: $period, candles: $candles, nextCursor: $nextCursor, total: $total)';
}


}

/// @nodoc
abstract mixin class _$KlineResponseDtoCopyWith<$Res> implements $KlineResponseDtoCopyWith<$Res> {
  factory _$KlineResponseDtoCopyWith(_KlineResponseDto value, $Res Function(_KlineResponseDto) _then) = __$KlineResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String period, List<CandleDto> candles,@JsonKey(name: 'next_cursor') String? nextCursor, int total
});




}
/// @nodoc
class __$KlineResponseDtoCopyWithImpl<$Res>
    implements _$KlineResponseDtoCopyWith<$Res> {
  __$KlineResponseDtoCopyWithImpl(this._self, this._then);

  final _KlineResponseDto _self;
  final $Res Function(_KlineResponseDto) _then;

/// Create a copy of KlineResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? period = null,Object? candles = null,Object? nextCursor = freezed,Object? total = null,}) {
  return _then(_KlineResponseDto(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,candles: null == candles ? _self._candles : candles // ignore: cast_nullable_to_non_nullable
as List<CandleDto>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SearchResultDto {

 String get symbol; String get name;@JsonKey(name: 'name_zh') String get nameZh; String get market; String get price;@JsonKey(name: 'change_pct') String get changePct; bool get delayed;
/// Create a copy of SearchResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultDtoCopyWith<SearchResultDto> get copyWith => _$SearchResultDtoCopyWithImpl<SearchResultDto>(this as SearchResultDto, _$identity);

  /// Serializes this SearchResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.delayed, delayed) || other.delayed == delayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,nameZh,market,price,changePct,delayed);

@override
String toString() {
  return 'SearchResultDto(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, changePct: $changePct, delayed: $delayed)';
}


}

/// @nodoc
abstract mixin class $SearchResultDtoCopyWith<$Res>  {
  factory $SearchResultDtoCopyWith(SearchResultDto value, $Res Function(SearchResultDto) _then) = _$SearchResultDtoCopyWithImpl;
@useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String market, String price,@JsonKey(name: 'change_pct') String changePct, bool delayed
});




}
/// @nodoc
class _$SearchResultDtoCopyWithImpl<$Res>
    implements $SearchResultDtoCopyWith<$Res> {
  _$SearchResultDtoCopyWithImpl(this._self, this._then);

  final SearchResultDto _self;
  final $Res Function(SearchResultDto) _then;

/// Create a copy of SearchResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? changePct = null,Object? delayed = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResultDto].
extension SearchResultDtoPatterns on SearchResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultDto value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price, @JsonKey(name: 'change_pct')  String changePct,  bool delayed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultDto() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.changePct,_that.delayed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price, @JsonKey(name: 'change_pct')  String changePct,  bool delayed)  $default,) {final _that = this;
switch (_that) {
case _SearchResultDto():
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.changePct,_that.delayed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price, @JsonKey(name: 'change_pct')  String changePct,  bool delayed)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultDto() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.changePct,_that.delayed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResultDto implements SearchResultDto {
  const _SearchResultDto({required this.symbol, required this.name, @JsonKey(name: 'name_zh') required this.nameZh, required this.market, required this.price, @JsonKey(name: 'change_pct') required this.changePct, required this.delayed});
  factory _SearchResultDto.fromJson(Map<String, dynamic> json) => _$SearchResultDtoFromJson(json);

@override final  String symbol;
@override final  String name;
@override@JsonKey(name: 'name_zh') final  String nameZh;
@override final  String market;
@override final  String price;
@override@JsonKey(name: 'change_pct') final  String changePct;
@override final  bool delayed;

/// Create a copy of SearchResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultDtoCopyWith<_SearchResultDto> get copyWith => __$SearchResultDtoCopyWithImpl<_SearchResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.delayed, delayed) || other.delayed == delayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,name,nameZh,market,price,changePct,delayed);

@override
String toString() {
  return 'SearchResultDto(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, changePct: $changePct, delayed: $delayed)';
}


}

/// @nodoc
abstract mixin class _$SearchResultDtoCopyWith<$Res> implements $SearchResultDtoCopyWith<$Res> {
  factory _$SearchResultDtoCopyWith(_SearchResultDto value, $Res Function(_SearchResultDto) _then) = __$SearchResultDtoCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String market, String price,@JsonKey(name: 'change_pct') String changePct, bool delayed
});




}
/// @nodoc
class __$SearchResultDtoCopyWithImpl<$Res>
    implements _$SearchResultDtoCopyWith<$Res> {
  __$SearchResultDtoCopyWithImpl(this._self, this._then);

  final _SearchResultDto _self;
  final $Res Function(_SearchResultDto) _then;

/// Create a copy of SearchResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? changePct = null,Object? delayed = null,}) {
  return _then(_SearchResultDto(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SearchResponseDto {

 List<SearchResultDto> get results; int get total;
/// Create a copy of SearchResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResponseDtoCopyWith<SearchResponseDto> get copyWith => _$SearchResponseDtoCopyWithImpl<SearchResponseDto>(this as SearchResponseDto, _$identity);

  /// Serializes this SearchResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResponseDto&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(results),total);

@override
String toString() {
  return 'SearchResponseDto(results: $results, total: $total)';
}


}

/// @nodoc
abstract mixin class $SearchResponseDtoCopyWith<$Res>  {
  factory $SearchResponseDtoCopyWith(SearchResponseDto value, $Res Function(SearchResponseDto) _then) = _$SearchResponseDtoCopyWithImpl;
@useResult
$Res call({
 List<SearchResultDto> results, int total
});




}
/// @nodoc
class _$SearchResponseDtoCopyWithImpl<$Res>
    implements $SearchResponseDtoCopyWith<$Res> {
  _$SearchResponseDtoCopyWithImpl(this._self, this._then);

  final SearchResponseDto _self;
  final $Res Function(SearchResponseDto) _then;

/// Create a copy of SearchResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? results = null,Object? total = null,}) {
  return _then(_self.copyWith(
results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SearchResultDto>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResponseDto].
extension SearchResponseDtoPatterns on SearchResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _SearchResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchResultDto> results,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResponseDto() when $default != null:
return $default(_that.results,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchResultDto> results,  int total)  $default,) {final _that = this;
switch (_that) {
case _SearchResponseDto():
return $default(_that.results,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchResultDto> results,  int total)?  $default,) {final _that = this;
switch (_that) {
case _SearchResponseDto() when $default != null:
return $default(_that.results,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResponseDto implements SearchResponseDto {
  const _SearchResponseDto({required final  List<SearchResultDto> results, required this.total}): _results = results;
  factory _SearchResponseDto.fromJson(Map<String, dynamic> json) => _$SearchResponseDtoFromJson(json);

 final  List<SearchResultDto> _results;
@override List<SearchResultDto> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  int total;

/// Create a copy of SearchResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResponseDtoCopyWith<_SearchResponseDto> get copyWith => __$SearchResponseDtoCopyWithImpl<_SearchResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResponseDto&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_results),total);

@override
String toString() {
  return 'SearchResponseDto(results: $results, total: $total)';
}


}

/// @nodoc
abstract mixin class _$SearchResponseDtoCopyWith<$Res> implements $SearchResponseDtoCopyWith<$Res> {
  factory _$SearchResponseDtoCopyWith(_SearchResponseDto value, $Res Function(_SearchResponseDto) _then) = __$SearchResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 List<SearchResultDto> results, int total
});




}
/// @nodoc
class __$SearchResponseDtoCopyWithImpl<$Res>
    implements _$SearchResponseDtoCopyWith<$Res> {
  __$SearchResponseDtoCopyWithImpl(this._self, this._then);

  final _SearchResponseDto _self;
  final $Res Function(_SearchResponseDto) _then;

/// Create a copy of SearchResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? results = null,Object? total = null,}) {
  return _then(_SearchResponseDto(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SearchResultDto>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$MoverItemDto {

 int get rank; String get symbol; String get name;@JsonKey(name: 'name_zh') String get nameZh; String get price; String get change;@JsonKey(name: 'change_pct') String get changePct; int get volume; String get turnover;@JsonKey(name: 'market_status') String get marketStatus;
/// Create a copy of MoverItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoverItemDtoCopyWith<MoverItemDto> get copyWith => _$MoverItemDtoCopyWithImpl<MoverItemDto>(this as MoverItemDto, _$identity);

  /// Serializes this MoverItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoverItemDto&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,symbol,name,nameZh,price,change,changePct,volume,turnover,marketStatus);

@override
String toString() {
  return 'MoverItemDto(rank: $rank, symbol: $symbol, name: $name, nameZh: $nameZh, price: $price, change: $change, changePct: $changePct, volume: $volume, turnover: $turnover, marketStatus: $marketStatus)';
}


}

/// @nodoc
abstract mixin class $MoverItemDtoCopyWith<$Res>  {
  factory $MoverItemDtoCopyWith(MoverItemDto value, $Res Function(MoverItemDto) _then) = _$MoverItemDtoCopyWithImpl;
@useResult
$Res call({
 int rank, String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String price, String change,@JsonKey(name: 'change_pct') String changePct, int volume, String turnover,@JsonKey(name: 'market_status') String marketStatus
});




}
/// @nodoc
class _$MoverItemDtoCopyWithImpl<$Res>
    implements $MoverItemDtoCopyWith<$Res> {
  _$MoverItemDtoCopyWithImpl(this._self, this._then);

  final MoverItemDto _self;
  final $Res Function(MoverItemDto) _then;

/// Create a copy of MoverItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rank = null,Object? symbol = null,Object? name = null,Object? nameZh = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? turnover = null,Object? marketStatus = null,}) {
  return _then(_self.copyWith(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MoverItemDto].
extension MoverItemDtoPatterns on MoverItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoverItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoverItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoverItemDto value)  $default,){
final _that = this;
switch (_that) {
case _MoverItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoverItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _MoverItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int rank,  String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  int volume,  String turnover, @JsonKey(name: 'market_status')  String marketStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoverItemDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int rank,  String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  int volume,  String turnover, @JsonKey(name: 'market_status')  String marketStatus)  $default,) {final _that = this;
switch (_that) {
case _MoverItemDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int rank,  String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  int volume,  String turnover, @JsonKey(name: 'market_status')  String marketStatus)?  $default,) {final _that = this;
switch (_that) {
case _MoverItemDto() when $default != null:
return $default(_that.rank,_that.symbol,_that.name,_that.nameZh,_that.price,_that.change,_that.changePct,_that.volume,_that.turnover,_that.marketStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoverItemDto implements MoverItemDto {
  const _MoverItemDto({required this.rank, required this.symbol, required this.name, @JsonKey(name: 'name_zh') required this.nameZh, required this.price, required this.change, @JsonKey(name: 'change_pct') required this.changePct, required this.volume, required this.turnover, @JsonKey(name: 'market_status') required this.marketStatus});
  factory _MoverItemDto.fromJson(Map<String, dynamic> json) => _$MoverItemDtoFromJson(json);

@override final  int rank;
@override final  String symbol;
@override final  String name;
@override@JsonKey(name: 'name_zh') final  String nameZh;
@override final  String price;
@override final  String change;
@override@JsonKey(name: 'change_pct') final  String changePct;
@override final  int volume;
@override final  String turnover;
@override@JsonKey(name: 'market_status') final  String marketStatus;

/// Create a copy of MoverItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoverItemDtoCopyWith<_MoverItemDto> get copyWith => __$MoverItemDtoCopyWithImpl<_MoverItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoverItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoverItemDto&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rank,symbol,name,nameZh,price,change,changePct,volume,turnover,marketStatus);

@override
String toString() {
  return 'MoverItemDto(rank: $rank, symbol: $symbol, name: $name, nameZh: $nameZh, price: $price, change: $change, changePct: $changePct, volume: $volume, turnover: $turnover, marketStatus: $marketStatus)';
}


}

/// @nodoc
abstract mixin class _$MoverItemDtoCopyWith<$Res> implements $MoverItemDtoCopyWith<$Res> {
  factory _$MoverItemDtoCopyWith(_MoverItemDto value, $Res Function(_MoverItemDto) _then) = __$MoverItemDtoCopyWithImpl;
@override @useResult
$Res call({
 int rank, String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String price, String change,@JsonKey(name: 'change_pct') String changePct, int volume, String turnover,@JsonKey(name: 'market_status') String marketStatus
});




}
/// @nodoc
class __$MoverItemDtoCopyWithImpl<$Res>
    implements _$MoverItemDtoCopyWith<$Res> {
  __$MoverItemDtoCopyWithImpl(this._self, this._then);

  final _MoverItemDto _self;
  final $Res Function(_MoverItemDto) _then;

/// Create a copy of MoverItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rank = null,Object? symbol = null,Object? name = null,Object? nameZh = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? turnover = null,Object? marketStatus = null,}) {
  return _then(_MoverItemDto(
rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MoversResponseDto {

 String get type; String get market; List<MoverItemDto> get items;@JsonKey(name: 'as_of') String get asOf;
/// Create a copy of MoversResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoversResponseDtoCopyWith<MoversResponseDto> get copyWith => _$MoversResponseDtoCopyWithImpl<MoversResponseDto>(this as MoversResponseDto, _$identity);

  /// Serializes this MoversResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoversResponseDto&&(identical(other.type, type) || other.type == type)&&(identical(other.market, market) || other.market == market)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,market,const DeepCollectionEquality().hash(items),asOf);

@override
String toString() {
  return 'MoversResponseDto(type: $type, market: $market, items: $items, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class $MoversResponseDtoCopyWith<$Res>  {
  factory $MoversResponseDtoCopyWith(MoversResponseDto value, $Res Function(MoversResponseDto) _then) = _$MoversResponseDtoCopyWithImpl;
@useResult
$Res call({
 String type, String market, List<MoverItemDto> items,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class _$MoversResponseDtoCopyWithImpl<$Res>
    implements $MoversResponseDtoCopyWith<$Res> {
  _$MoversResponseDtoCopyWithImpl(this._self, this._then);

  final MoversResponseDto _self;
  final $Res Function(MoversResponseDto) _then;

/// Create a copy of MoversResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? market = null,Object? items = null,Object? asOf = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MoverItemDto>,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MoversResponseDto].
extension MoversResponseDtoPatterns on MoversResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoversResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoversResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoversResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _MoversResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoversResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _MoversResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String market,  List<MoverItemDto> items, @JsonKey(name: 'as_of')  String asOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoversResponseDto() when $default != null:
return $default(_that.type,_that.market,_that.items,_that.asOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String market,  List<MoverItemDto> items, @JsonKey(name: 'as_of')  String asOf)  $default,) {final _that = this;
switch (_that) {
case _MoversResponseDto():
return $default(_that.type,_that.market,_that.items,_that.asOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String market,  List<MoverItemDto> items, @JsonKey(name: 'as_of')  String asOf)?  $default,) {final _that = this;
switch (_that) {
case _MoversResponseDto() when $default != null:
return $default(_that.type,_that.market,_that.items,_that.asOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoversResponseDto implements MoversResponseDto {
  const _MoversResponseDto({required this.type, required this.market, required final  List<MoverItemDto> items, @JsonKey(name: 'as_of') required this.asOf}): _items = items;
  factory _MoversResponseDto.fromJson(Map<String, dynamic> json) => _$MoversResponseDtoFromJson(json);

@override final  String type;
@override final  String market;
 final  List<MoverItemDto> _items;
@override List<MoverItemDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'as_of') final  String asOf;

/// Create a copy of MoversResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoversResponseDtoCopyWith<_MoversResponseDto> get copyWith => __$MoversResponseDtoCopyWithImpl<_MoversResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoversResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoversResponseDto&&(identical(other.type, type) || other.type == type)&&(identical(other.market, market) || other.market == market)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,market,const DeepCollectionEquality().hash(_items),asOf);

@override
String toString() {
  return 'MoversResponseDto(type: $type, market: $market, items: $items, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class _$MoversResponseDtoCopyWith<$Res> implements $MoversResponseDtoCopyWith<$Res> {
  factory _$MoversResponseDtoCopyWith(_MoversResponseDto value, $Res Function(_MoversResponseDto) _then) = __$MoversResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String type, String market, List<MoverItemDto> items,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class __$MoversResponseDtoCopyWithImpl<$Res>
    implements _$MoversResponseDtoCopyWith<$Res> {
  __$MoversResponseDtoCopyWithImpl(this._self, this._then);

  final _MoversResponseDto _self;
  final $Res Function(_MoversResponseDto) _then;

/// Create a copy of MoversResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? market = null,Object? items = null,Object? asOf = null,}) {
  return _then(_MoversResponseDto(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MoverItemDto>,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StockDetailDto {

 String get symbol; String get name;@JsonKey(name: 'name_zh') String get nameZh; String get market; String get price; String get change;@JsonKey(name: 'change_pct') String get changePct; String get open; String get high; String get low;@JsonKey(name: 'prev_close') String get prevClose; int get volume; String get turnover; String? get bid; String? get ask; bool get delayed;@JsonKey(name: 'market_status') String get marketStatus; String get session;@JsonKey(name: 'is_stale') bool get isStale;@JsonKey(name: 'stale_since_ms') int get staleSinceMs;// Fundamental fields
@JsonKey(name: 'market_cap') String get marketCap;@JsonKey(name: 'pe_ratio') String get peRatio;@JsonKey(name: 'pb_ratio') String get pbRatio;@JsonKey(name: 'dividend_yield') String get dividendYield;@JsonKey(name: 'shares_outstanding') int get sharesOutstanding;@JsonKey(name: 'avg_volume') int get avgVolume;@JsonKey(name: 'week52_high') String get week52High;@JsonKey(name: 'week52_low') String get week52Low;@JsonKey(name: 'turnover_rate') String get turnoverRate; String get exchange; String get sector;@JsonKey(name: 'as_of') String get asOf;
/// Create a copy of StockDetailDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockDetailDtoCopyWith<StockDetailDto> get copyWith => _$StockDetailDtoCopyWithImpl<StockDetailDto>(this as StockDetailDto, _$identity);

  /// Serializes this StockDetailDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockDetailDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.session, session) || other.session == session)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.pbRatio, pbRatio) || other.pbRatio == pbRatio)&&(identical(other.dividendYield, dividendYield) || other.dividendYield == dividendYield)&&(identical(other.sharesOutstanding, sharesOutstanding) || other.sharesOutstanding == sharesOutstanding)&&(identical(other.avgVolume, avgVolume) || other.avgVolume == avgVolume)&&(identical(other.week52High, week52High) || other.week52High == week52High)&&(identical(other.week52Low, week52Low) || other.week52Low == week52Low)&&(identical(other.turnoverRate, turnoverRate) || other.turnoverRate == turnoverRate)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,open,high,low,prevClose,volume,turnover,bid,ask,delayed,marketStatus,session,isStale,staleSinceMs,marketCap,peRatio,pbRatio,dividendYield,sharesOutstanding,avgVolume,week52High,week52Low,turnoverRate,exchange,sector,asOf]);

@override
String toString() {
  return 'StockDetailDto(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, open: $open, high: $high, low: $low, prevClose: $prevClose, volume: $volume, turnover: $turnover, bid: $bid, ask: $ask, delayed: $delayed, marketStatus: $marketStatus, session: $session, isStale: $isStale, staleSinceMs: $staleSinceMs, marketCap: $marketCap, peRatio: $peRatio, pbRatio: $pbRatio, dividendYield: $dividendYield, sharesOutstanding: $sharesOutstanding, avgVolume: $avgVolume, week52High: $week52High, week52Low: $week52Low, turnoverRate: $turnoverRate, exchange: $exchange, sector: $sector, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class $StockDetailDtoCopyWith<$Res>  {
  factory $StockDetailDtoCopyWith(StockDetailDto value, $Res Function(StockDetailDto) _then) = _$StockDetailDtoCopyWithImpl;
@useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String market, String price, String change,@JsonKey(name: 'change_pct') String changePct, String open, String high, String low,@JsonKey(name: 'prev_close') String prevClose, int volume, String turnover, String? bid, String? ask, bool delayed,@JsonKey(name: 'market_status') String marketStatus, String session,@JsonKey(name: 'is_stale') bool isStale,@JsonKey(name: 'stale_since_ms') int staleSinceMs,@JsonKey(name: 'market_cap') String marketCap,@JsonKey(name: 'pe_ratio') String peRatio,@JsonKey(name: 'pb_ratio') String pbRatio,@JsonKey(name: 'dividend_yield') String dividendYield,@JsonKey(name: 'shares_outstanding') int sharesOutstanding,@JsonKey(name: 'avg_volume') int avgVolume,@JsonKey(name: 'week52_high') String week52High,@JsonKey(name: 'week52_low') String week52Low,@JsonKey(name: 'turnover_rate') String turnoverRate, String exchange, String sector,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class _$StockDetailDtoCopyWithImpl<$Res>
    implements $StockDetailDtoCopyWith<$Res> {
  _$StockDetailDtoCopyWithImpl(this._self, this._then);

  final StockDetailDto _self;
  final $Res Function(StockDetailDto) _then;

/// Create a copy of StockDetailDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? open = null,Object? high = null,Object? low = null,Object? prevClose = null,Object? volume = null,Object? turnover = null,Object? bid = freezed,Object? ask = freezed,Object? delayed = null,Object? marketStatus = null,Object? session = null,Object? isStale = null,Object? staleSinceMs = null,Object? marketCap = null,Object? peRatio = null,Object? pbRatio = null,Object? dividendYield = null,Object? sharesOutstanding = null,Object? avgVolume = null,Object? week52High = null,Object? week52Low = null,Object? turnoverRate = null,Object? exchange = null,Object? sector = null,Object? asOf = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as String,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as String,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as String,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as String?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as String?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as String,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as String,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: null == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String,pbRatio: null == pbRatio ? _self.pbRatio : pbRatio // ignore: cast_nullable_to_non_nullable
as String,dividendYield: null == dividendYield ? _self.dividendYield : dividendYield // ignore: cast_nullable_to_non_nullable
as String,sharesOutstanding: null == sharesOutstanding ? _self.sharesOutstanding : sharesOutstanding // ignore: cast_nullable_to_non_nullable
as int,avgVolume: null == avgVolume ? _self.avgVolume : avgVolume // ignore: cast_nullable_to_non_nullable
as int,week52High: null == week52High ? _self.week52High : week52High // ignore: cast_nullable_to_non_nullable
as String,week52Low: null == week52Low ? _self.week52Low : week52Low // ignore: cast_nullable_to_non_nullable
as String,turnoverRate: null == turnoverRate ? _self.turnoverRate : turnoverRate // ignore: cast_nullable_to_non_nullable
as String,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StockDetailDto].
extension StockDetailDtoPatterns on StockDetailDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockDetailDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockDetailDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockDetailDto value)  $default,){
final _that = this;
switch (_that) {
case _StockDetailDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockDetailDto value)?  $default,){
final _that = this;
switch (_that) {
case _StockDetailDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  String open,  String high,  String low, @JsonKey(name: 'prev_close')  String prevClose,  int volume,  String turnover,  String? bid,  String? ask,  bool delayed, @JsonKey(name: 'market_status')  String marketStatus,  String session, @JsonKey(name: 'is_stale')  bool isStale, @JsonKey(name: 'stale_since_ms')  int staleSinceMs, @JsonKey(name: 'market_cap')  String marketCap, @JsonKey(name: 'pe_ratio')  String peRatio, @JsonKey(name: 'pb_ratio')  String pbRatio, @JsonKey(name: 'dividend_yield')  String dividendYield, @JsonKey(name: 'shares_outstanding')  int sharesOutstanding, @JsonKey(name: 'avg_volume')  int avgVolume, @JsonKey(name: 'week52_high')  String week52High, @JsonKey(name: 'week52_low')  String week52Low, @JsonKey(name: 'turnover_rate')  String turnoverRate,  String exchange,  String sector, @JsonKey(name: 'as_of')  String asOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockDetailDto() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.open,_that.high,_that.low,_that.prevClose,_that.volume,_that.turnover,_that.bid,_that.ask,_that.delayed,_that.marketStatus,_that.session,_that.isStale,_that.staleSinceMs,_that.marketCap,_that.peRatio,_that.pbRatio,_that.dividendYield,_that.sharesOutstanding,_that.avgVolume,_that.week52High,_that.week52Low,_that.turnoverRate,_that.exchange,_that.sector,_that.asOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  String open,  String high,  String low, @JsonKey(name: 'prev_close')  String prevClose,  int volume,  String turnover,  String? bid,  String? ask,  bool delayed, @JsonKey(name: 'market_status')  String marketStatus,  String session, @JsonKey(name: 'is_stale')  bool isStale, @JsonKey(name: 'stale_since_ms')  int staleSinceMs, @JsonKey(name: 'market_cap')  String marketCap, @JsonKey(name: 'pe_ratio')  String peRatio, @JsonKey(name: 'pb_ratio')  String pbRatio, @JsonKey(name: 'dividend_yield')  String dividendYield, @JsonKey(name: 'shares_outstanding')  int sharesOutstanding, @JsonKey(name: 'avg_volume')  int avgVolume, @JsonKey(name: 'week52_high')  String week52High, @JsonKey(name: 'week52_low')  String week52Low, @JsonKey(name: 'turnover_rate')  String turnoverRate,  String exchange,  String sector, @JsonKey(name: 'as_of')  String asOf)  $default,) {final _that = this;
switch (_that) {
case _StockDetailDto():
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.open,_that.high,_that.low,_that.prevClose,_that.volume,_that.turnover,_that.bid,_that.ask,_that.delayed,_that.marketStatus,_that.session,_that.isStale,_that.staleSinceMs,_that.marketCap,_that.peRatio,_that.pbRatio,_that.dividendYield,_that.sharesOutstanding,_that.avgVolume,_that.week52High,_that.week52Low,_that.turnoverRate,_that.exchange,_that.sector,_that.asOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name, @JsonKey(name: 'name_zh')  String nameZh,  String market,  String price,  String change, @JsonKey(name: 'change_pct')  String changePct,  String open,  String high,  String low, @JsonKey(name: 'prev_close')  String prevClose,  int volume,  String turnover,  String? bid,  String? ask,  bool delayed, @JsonKey(name: 'market_status')  String marketStatus,  String session, @JsonKey(name: 'is_stale')  bool isStale, @JsonKey(name: 'stale_since_ms')  int staleSinceMs, @JsonKey(name: 'market_cap')  String marketCap, @JsonKey(name: 'pe_ratio')  String peRatio, @JsonKey(name: 'pb_ratio')  String pbRatio, @JsonKey(name: 'dividend_yield')  String dividendYield, @JsonKey(name: 'shares_outstanding')  int sharesOutstanding, @JsonKey(name: 'avg_volume')  int avgVolume, @JsonKey(name: 'week52_high')  String week52High, @JsonKey(name: 'week52_low')  String week52Low, @JsonKey(name: 'turnover_rate')  String turnoverRate,  String exchange,  String sector, @JsonKey(name: 'as_of')  String asOf)?  $default,) {final _that = this;
switch (_that) {
case _StockDetailDto() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.open,_that.high,_that.low,_that.prevClose,_that.volume,_that.turnover,_that.bid,_that.ask,_that.delayed,_that.marketStatus,_that.session,_that.isStale,_that.staleSinceMs,_that.marketCap,_that.peRatio,_that.pbRatio,_that.dividendYield,_that.sharesOutstanding,_that.avgVolume,_that.week52High,_that.week52Low,_that.turnoverRate,_that.exchange,_that.sector,_that.asOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockDetailDto implements StockDetailDto {
  const _StockDetailDto({required this.symbol, required this.name, @JsonKey(name: 'name_zh') required this.nameZh, required this.market, required this.price, required this.change, @JsonKey(name: 'change_pct') required this.changePct, required this.open, required this.high, required this.low, @JsonKey(name: 'prev_close') required this.prevClose, required this.volume, required this.turnover, this.bid, this.ask, required this.delayed, @JsonKey(name: 'market_status') required this.marketStatus, required this.session, @JsonKey(name: 'is_stale') this.isStale = false, @JsonKey(name: 'stale_since_ms') this.staleSinceMs = 0, @JsonKey(name: 'market_cap') required this.marketCap, @JsonKey(name: 'pe_ratio') required this.peRatio, @JsonKey(name: 'pb_ratio') required this.pbRatio, @JsonKey(name: 'dividend_yield') required this.dividendYield, @JsonKey(name: 'shares_outstanding') required this.sharesOutstanding, @JsonKey(name: 'avg_volume') required this.avgVolume, @JsonKey(name: 'week52_high') required this.week52High, @JsonKey(name: 'week52_low') required this.week52Low, @JsonKey(name: 'turnover_rate') required this.turnoverRate, required this.exchange, required this.sector, @JsonKey(name: 'as_of') required this.asOf});
  factory _StockDetailDto.fromJson(Map<String, dynamic> json) => _$StockDetailDtoFromJson(json);

@override final  String symbol;
@override final  String name;
@override@JsonKey(name: 'name_zh') final  String nameZh;
@override final  String market;
@override final  String price;
@override final  String change;
@override@JsonKey(name: 'change_pct') final  String changePct;
@override final  String open;
@override final  String high;
@override final  String low;
@override@JsonKey(name: 'prev_close') final  String prevClose;
@override final  int volume;
@override final  String turnover;
@override final  String? bid;
@override final  String? ask;
@override final  bool delayed;
@override@JsonKey(name: 'market_status') final  String marketStatus;
@override final  String session;
@override@JsonKey(name: 'is_stale') final  bool isStale;
@override@JsonKey(name: 'stale_since_ms') final  int staleSinceMs;
// Fundamental fields
@override@JsonKey(name: 'market_cap') final  String marketCap;
@override@JsonKey(name: 'pe_ratio') final  String peRatio;
@override@JsonKey(name: 'pb_ratio') final  String pbRatio;
@override@JsonKey(name: 'dividend_yield') final  String dividendYield;
@override@JsonKey(name: 'shares_outstanding') final  int sharesOutstanding;
@override@JsonKey(name: 'avg_volume') final  int avgVolume;
@override@JsonKey(name: 'week52_high') final  String week52High;
@override@JsonKey(name: 'week52_low') final  String week52Low;
@override@JsonKey(name: 'turnover_rate') final  String turnoverRate;
@override final  String exchange;
@override final  String sector;
@override@JsonKey(name: 'as_of') final  String asOf;

/// Create a copy of StockDetailDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockDetailDtoCopyWith<_StockDetailDto> get copyWith => __$StockDetailDtoCopyWithImpl<_StockDetailDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockDetailDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockDetailDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.session, session) || other.session == session)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.pbRatio, pbRatio) || other.pbRatio == pbRatio)&&(identical(other.dividendYield, dividendYield) || other.dividendYield == dividendYield)&&(identical(other.sharesOutstanding, sharesOutstanding) || other.sharesOutstanding == sharesOutstanding)&&(identical(other.avgVolume, avgVolume) || other.avgVolume == avgVolume)&&(identical(other.week52High, week52High) || other.week52High == week52High)&&(identical(other.week52Low, week52Low) || other.week52Low == week52Low)&&(identical(other.turnoverRate, turnoverRate) || other.turnoverRate == turnoverRate)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,open,high,low,prevClose,volume,turnover,bid,ask,delayed,marketStatus,session,isStale,staleSinceMs,marketCap,peRatio,pbRatio,dividendYield,sharesOutstanding,avgVolume,week52High,week52Low,turnoverRate,exchange,sector,asOf]);

@override
String toString() {
  return 'StockDetailDto(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, open: $open, high: $high, low: $low, prevClose: $prevClose, volume: $volume, turnover: $turnover, bid: $bid, ask: $ask, delayed: $delayed, marketStatus: $marketStatus, session: $session, isStale: $isStale, staleSinceMs: $staleSinceMs, marketCap: $marketCap, peRatio: $peRatio, pbRatio: $pbRatio, dividendYield: $dividendYield, sharesOutstanding: $sharesOutstanding, avgVolume: $avgVolume, week52High: $week52High, week52Low: $week52Low, turnoverRate: $turnoverRate, exchange: $exchange, sector: $sector, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class _$StockDetailDtoCopyWith<$Res> implements $StockDetailDtoCopyWith<$Res> {
  factory _$StockDetailDtoCopyWith(_StockDetailDto value, $Res Function(_StockDetailDto) _then) = __$StockDetailDtoCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name,@JsonKey(name: 'name_zh') String nameZh, String market, String price, String change,@JsonKey(name: 'change_pct') String changePct, String open, String high, String low,@JsonKey(name: 'prev_close') String prevClose, int volume, String turnover, String? bid, String? ask, bool delayed,@JsonKey(name: 'market_status') String marketStatus, String session,@JsonKey(name: 'is_stale') bool isStale,@JsonKey(name: 'stale_since_ms') int staleSinceMs,@JsonKey(name: 'market_cap') String marketCap,@JsonKey(name: 'pe_ratio') String peRatio,@JsonKey(name: 'pb_ratio') String pbRatio,@JsonKey(name: 'dividend_yield') String dividendYield,@JsonKey(name: 'shares_outstanding') int sharesOutstanding,@JsonKey(name: 'avg_volume') int avgVolume,@JsonKey(name: 'week52_high') String week52High,@JsonKey(name: 'week52_low') String week52Low,@JsonKey(name: 'turnover_rate') String turnoverRate, String exchange, String sector,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class __$StockDetailDtoCopyWithImpl<$Res>
    implements _$StockDetailDtoCopyWith<$Res> {
  __$StockDetailDtoCopyWithImpl(this._self, this._then);

  final _StockDetailDto _self;
  final $Res Function(_StockDetailDto) _then;

/// Create a copy of StockDetailDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? open = null,Object? high = null,Object? low = null,Object? prevClose = null,Object? volume = null,Object? turnover = null,Object? bid = freezed,Object? ask = freezed,Object? delayed = null,Object? marketStatus = null,Object? session = null,Object? isStale = null,Object? staleSinceMs = null,Object? marketCap = null,Object? peRatio = null,Object? pbRatio = null,Object? dividendYield = null,Object? sharesOutstanding = null,Object? avgVolume = null,Object? week52High = null,Object? week52Low = null,Object? turnoverRate = null,Object? exchange = null,Object? sector = null,Object? asOf = null,}) {
  return _then(_StockDetailDto(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as String,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as String,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as String,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as String,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as String,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as String?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as String?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as String,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as String,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: null == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String,pbRatio: null == pbRatio ? _self.pbRatio : pbRatio // ignore: cast_nullable_to_non_nullable
as String,dividendYield: null == dividendYield ? _self.dividendYield : dividendYield // ignore: cast_nullable_to_non_nullable
as String,sharesOutstanding: null == sharesOutstanding ? _self.sharesOutstanding : sharesOutstanding // ignore: cast_nullable_to_non_nullable
as int,avgVolume: null == avgVolume ? _self.avgVolume : avgVolume // ignore: cast_nullable_to_non_nullable
as int,week52High: null == week52High ? _self.week52High : week52High // ignore: cast_nullable_to_non_nullable
as String,week52Low: null == week52Low ? _self.week52Low : week52Low // ignore: cast_nullable_to_non_nullable
as String,turnoverRate: null == turnoverRate ? _self.turnoverRate : turnoverRate // ignore: cast_nullable_to_non_nullable
as String,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NewsArticleDto {

 String get id; String get title; String get summary; String get source;@JsonKey(name: 'published_at') String get publishedAt; String get url;
/// Create a copy of NewsArticleDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsArticleDtoCopyWith<NewsArticleDto> get copyWith => _$NewsArticleDtoCopyWithImpl<NewsArticleDto>(this as NewsArticleDto, _$identity);

  /// Serializes this NewsArticleDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsArticleDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.source, source) || other.source == source)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,summary,source,publishedAt,url);

@override
String toString() {
  return 'NewsArticleDto(id: $id, title: $title, summary: $summary, source: $source, publishedAt: $publishedAt, url: $url)';
}


}

/// @nodoc
abstract mixin class $NewsArticleDtoCopyWith<$Res>  {
  factory $NewsArticleDtoCopyWith(NewsArticleDto value, $Res Function(NewsArticleDto) _then) = _$NewsArticleDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String summary, String source,@JsonKey(name: 'published_at') String publishedAt, String url
});




}
/// @nodoc
class _$NewsArticleDtoCopyWithImpl<$Res>
    implements $NewsArticleDtoCopyWith<$Res> {
  _$NewsArticleDtoCopyWithImpl(this._self, this._then);

  final NewsArticleDto _self;
  final $Res Function(NewsArticleDto) _then;

/// Create a copy of NewsArticleDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? source = null,Object? publishedAt = null,Object? url = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsArticleDto].
extension NewsArticleDtoPatterns on NewsArticleDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsArticleDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsArticleDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsArticleDto value)  $default,){
final _that = this;
switch (_that) {
case _NewsArticleDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsArticleDto value)?  $default,){
final _that = this;
switch (_that) {
case _NewsArticleDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String summary,  String source, @JsonKey(name: 'published_at')  String publishedAt,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsArticleDto() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.source,_that.publishedAt,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String summary,  String source, @JsonKey(name: 'published_at')  String publishedAt,  String url)  $default,) {final _that = this;
switch (_that) {
case _NewsArticleDto():
return $default(_that.id,_that.title,_that.summary,_that.source,_that.publishedAt,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String summary,  String source, @JsonKey(name: 'published_at')  String publishedAt,  String url)?  $default,) {final _that = this;
switch (_that) {
case _NewsArticleDto() when $default != null:
return $default(_that.id,_that.title,_that.summary,_that.source,_that.publishedAt,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsArticleDto implements NewsArticleDto {
  const _NewsArticleDto({required this.id, required this.title, required this.summary, required this.source, @JsonKey(name: 'published_at') required this.publishedAt, required this.url});
  factory _NewsArticleDto.fromJson(Map<String, dynamic> json) => _$NewsArticleDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String summary;
@override final  String source;
@override@JsonKey(name: 'published_at') final  String publishedAt;
@override final  String url;

/// Create a copy of NewsArticleDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsArticleDtoCopyWith<_NewsArticleDto> get copyWith => __$NewsArticleDtoCopyWithImpl<_NewsArticleDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsArticleDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsArticleDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.source, source) || other.source == source)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,summary,source,publishedAt,url);

@override
String toString() {
  return 'NewsArticleDto(id: $id, title: $title, summary: $summary, source: $source, publishedAt: $publishedAt, url: $url)';
}


}

/// @nodoc
abstract mixin class _$NewsArticleDtoCopyWith<$Res> implements $NewsArticleDtoCopyWith<$Res> {
  factory _$NewsArticleDtoCopyWith(_NewsArticleDto value, $Res Function(_NewsArticleDto) _then) = __$NewsArticleDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String summary, String source,@JsonKey(name: 'published_at') String publishedAt, String url
});




}
/// @nodoc
class __$NewsArticleDtoCopyWithImpl<$Res>
    implements _$NewsArticleDtoCopyWith<$Res> {
  __$NewsArticleDtoCopyWithImpl(this._self, this._then);

  final _NewsArticleDto _self;
  final $Res Function(_NewsArticleDto) _then;

/// Create a copy of NewsArticleDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? summary = null,Object? source = null,Object? publishedAt = null,Object? url = null,}) {
  return _then(_NewsArticleDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NewsResponseDto {

 String get symbol; List<NewsArticleDto> get news; int get page;@JsonKey(name: 'page_size') int get pageSize; int get total;
/// Create a copy of NewsResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsResponseDtoCopyWith<NewsResponseDto> get copyWith => _$NewsResponseDtoCopyWithImpl<NewsResponseDto>(this as NewsResponseDto, _$identity);

  /// Serializes this NewsResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsResponseDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&const DeepCollectionEquality().equals(other.news, news)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,const DeepCollectionEquality().hash(news),page,pageSize,total);

@override
String toString() {
  return 'NewsResponseDto(symbol: $symbol, news: $news, page: $page, pageSize: $pageSize, total: $total)';
}


}

/// @nodoc
abstract mixin class $NewsResponseDtoCopyWith<$Res>  {
  factory $NewsResponseDtoCopyWith(NewsResponseDto value, $Res Function(NewsResponseDto) _then) = _$NewsResponseDtoCopyWithImpl;
@useResult
$Res call({
 String symbol, List<NewsArticleDto> news, int page,@JsonKey(name: 'page_size') int pageSize, int total
});




}
/// @nodoc
class _$NewsResponseDtoCopyWithImpl<$Res>
    implements $NewsResponseDtoCopyWith<$Res> {
  _$NewsResponseDtoCopyWithImpl(this._self, this._then);

  final NewsResponseDto _self;
  final $Res Function(NewsResponseDto) _then;

/// Create a copy of NewsResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? news = null,Object? page = null,Object? pageSize = null,Object? total = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,news: null == news ? _self.news : news // ignore: cast_nullable_to_non_nullable
as List<NewsArticleDto>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsResponseDto].
extension NewsResponseDtoPatterns on NewsResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _NewsResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _NewsResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  List<NewsArticleDto> news,  int page, @JsonKey(name: 'page_size')  int pageSize,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsResponseDto() when $default != null:
return $default(_that.symbol,_that.news,_that.page,_that.pageSize,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  List<NewsArticleDto> news,  int page, @JsonKey(name: 'page_size')  int pageSize,  int total)  $default,) {final _that = this;
switch (_that) {
case _NewsResponseDto():
return $default(_that.symbol,_that.news,_that.page,_that.pageSize,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  List<NewsArticleDto> news,  int page, @JsonKey(name: 'page_size')  int pageSize,  int total)?  $default,) {final _that = this;
switch (_that) {
case _NewsResponseDto() when $default != null:
return $default(_that.symbol,_that.news,_that.page,_that.pageSize,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewsResponseDto implements NewsResponseDto {
  const _NewsResponseDto({required this.symbol, required final  List<NewsArticleDto> news, required this.page, @JsonKey(name: 'page_size') required this.pageSize, required this.total}): _news = news;
  factory _NewsResponseDto.fromJson(Map<String, dynamic> json) => _$NewsResponseDtoFromJson(json);

@override final  String symbol;
 final  List<NewsArticleDto> _news;
@override List<NewsArticleDto> get news {
  if (_news is EqualUnmodifiableListView) return _news;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_news);
}

@override final  int page;
@override@JsonKey(name: 'page_size') final  int pageSize;
@override final  int total;

/// Create a copy of NewsResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsResponseDtoCopyWith<_NewsResponseDto> get copyWith => __$NewsResponseDtoCopyWithImpl<_NewsResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewsResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsResponseDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&const DeepCollectionEquality().equals(other._news, _news)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,const DeepCollectionEquality().hash(_news),page,pageSize,total);

@override
String toString() {
  return 'NewsResponseDto(symbol: $symbol, news: $news, page: $page, pageSize: $pageSize, total: $total)';
}


}

/// @nodoc
abstract mixin class _$NewsResponseDtoCopyWith<$Res> implements $NewsResponseDtoCopyWith<$Res> {
  factory _$NewsResponseDtoCopyWith(_NewsResponseDto value, $Res Function(_NewsResponseDto) _then) = __$NewsResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String symbol, List<NewsArticleDto> news, int page,@JsonKey(name: 'page_size') int pageSize, int total
});




}
/// @nodoc
class __$NewsResponseDtoCopyWithImpl<$Res>
    implements _$NewsResponseDtoCopyWith<$Res> {
  __$NewsResponseDtoCopyWithImpl(this._self, this._then);

  final _NewsResponseDto _self;
  final $Res Function(_NewsResponseDto) _then;

/// Create a copy of NewsResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? news = null,Object? page = null,Object? pageSize = null,Object? total = null,}) {
  return _then(_NewsResponseDto(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,news: null == news ? _self._news : news // ignore: cast_nullable_to_non_nullable
as List<NewsArticleDto>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FinancialsQuarterDto {

 String get period;@JsonKey(name: 'report_date') String get reportDate; String get revenue;@JsonKey(name: 'net_income') String get netIncome; String get eps;@JsonKey(name: 'eps_estimate') String get epsEstimate;@JsonKey(name: 'revenue_growth') String get revenueGrowth;@JsonKey(name: 'net_income_growth') String get netIncomeGrowth;
/// Create a copy of FinancialsQuarterDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialsQuarterDtoCopyWith<FinancialsQuarterDto> get copyWith => _$FinancialsQuarterDtoCopyWithImpl<FinancialsQuarterDto>(this as FinancialsQuarterDto, _$identity);

  /// Serializes this FinancialsQuarterDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialsQuarterDto&&(identical(other.period, period) || other.period == period)&&(identical(other.reportDate, reportDate) || other.reportDate == reportDate)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.eps, eps) || other.eps == eps)&&(identical(other.epsEstimate, epsEstimate) || other.epsEstimate == epsEstimate)&&(identical(other.revenueGrowth, revenueGrowth) || other.revenueGrowth == revenueGrowth)&&(identical(other.netIncomeGrowth, netIncomeGrowth) || other.netIncomeGrowth == netIncomeGrowth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,reportDate,revenue,netIncome,eps,epsEstimate,revenueGrowth,netIncomeGrowth);

@override
String toString() {
  return 'FinancialsQuarterDto(period: $period, reportDate: $reportDate, revenue: $revenue, netIncome: $netIncome, eps: $eps, epsEstimate: $epsEstimate, revenueGrowth: $revenueGrowth, netIncomeGrowth: $netIncomeGrowth)';
}


}

/// @nodoc
abstract mixin class $FinancialsQuarterDtoCopyWith<$Res>  {
  factory $FinancialsQuarterDtoCopyWith(FinancialsQuarterDto value, $Res Function(FinancialsQuarterDto) _then) = _$FinancialsQuarterDtoCopyWithImpl;
@useResult
$Res call({
 String period,@JsonKey(name: 'report_date') String reportDate, String revenue,@JsonKey(name: 'net_income') String netIncome, String eps,@JsonKey(name: 'eps_estimate') String epsEstimate,@JsonKey(name: 'revenue_growth') String revenueGrowth,@JsonKey(name: 'net_income_growth') String netIncomeGrowth
});




}
/// @nodoc
class _$FinancialsQuarterDtoCopyWithImpl<$Res>
    implements $FinancialsQuarterDtoCopyWith<$Res> {
  _$FinancialsQuarterDtoCopyWithImpl(this._self, this._then);

  final FinancialsQuarterDto _self;
  final $Res Function(FinancialsQuarterDto) _then;

/// Create a copy of FinancialsQuarterDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? reportDate = null,Object? revenue = null,Object? netIncome = null,Object? eps = null,Object? epsEstimate = null,Object? revenueGrowth = null,Object? netIncomeGrowth = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,reportDate: null == reportDate ? _self.reportDate : reportDate // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,netIncome: null == netIncome ? _self.netIncome : netIncome // ignore: cast_nullable_to_non_nullable
as String,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as String,epsEstimate: null == epsEstimate ? _self.epsEstimate : epsEstimate // ignore: cast_nullable_to_non_nullable
as String,revenueGrowth: null == revenueGrowth ? _self.revenueGrowth : revenueGrowth // ignore: cast_nullable_to_non_nullable
as String,netIncomeGrowth: null == netIncomeGrowth ? _self.netIncomeGrowth : netIncomeGrowth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialsQuarterDto].
extension FinancialsQuarterDtoPatterns on FinancialsQuarterDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialsQuarterDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialsQuarterDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialsQuarterDto value)  $default,){
final _that = this;
switch (_that) {
case _FinancialsQuarterDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialsQuarterDto value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialsQuarterDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period, @JsonKey(name: 'report_date')  String reportDate,  String revenue, @JsonKey(name: 'net_income')  String netIncome,  String eps, @JsonKey(name: 'eps_estimate')  String epsEstimate, @JsonKey(name: 'revenue_growth')  String revenueGrowth, @JsonKey(name: 'net_income_growth')  String netIncomeGrowth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialsQuarterDto() when $default != null:
return $default(_that.period,_that.reportDate,_that.revenue,_that.netIncome,_that.eps,_that.epsEstimate,_that.revenueGrowth,_that.netIncomeGrowth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period, @JsonKey(name: 'report_date')  String reportDate,  String revenue, @JsonKey(name: 'net_income')  String netIncome,  String eps, @JsonKey(name: 'eps_estimate')  String epsEstimate, @JsonKey(name: 'revenue_growth')  String revenueGrowth, @JsonKey(name: 'net_income_growth')  String netIncomeGrowth)  $default,) {final _that = this;
switch (_that) {
case _FinancialsQuarterDto():
return $default(_that.period,_that.reportDate,_that.revenue,_that.netIncome,_that.eps,_that.epsEstimate,_that.revenueGrowth,_that.netIncomeGrowth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period, @JsonKey(name: 'report_date')  String reportDate,  String revenue, @JsonKey(name: 'net_income')  String netIncome,  String eps, @JsonKey(name: 'eps_estimate')  String epsEstimate, @JsonKey(name: 'revenue_growth')  String revenueGrowth, @JsonKey(name: 'net_income_growth')  String netIncomeGrowth)?  $default,) {final _that = this;
switch (_that) {
case _FinancialsQuarterDto() when $default != null:
return $default(_that.period,_that.reportDate,_that.revenue,_that.netIncome,_that.eps,_that.epsEstimate,_that.revenueGrowth,_that.netIncomeGrowth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinancialsQuarterDto implements FinancialsQuarterDto {
  const _FinancialsQuarterDto({required this.period, @JsonKey(name: 'report_date') required this.reportDate, required this.revenue, @JsonKey(name: 'net_income') required this.netIncome, required this.eps, @JsonKey(name: 'eps_estimate') required this.epsEstimate, @JsonKey(name: 'revenue_growth') required this.revenueGrowth, @JsonKey(name: 'net_income_growth') required this.netIncomeGrowth});
  factory _FinancialsQuarterDto.fromJson(Map<String, dynamic> json) => _$FinancialsQuarterDtoFromJson(json);

@override final  String period;
@override@JsonKey(name: 'report_date') final  String reportDate;
@override final  String revenue;
@override@JsonKey(name: 'net_income') final  String netIncome;
@override final  String eps;
@override@JsonKey(name: 'eps_estimate') final  String epsEstimate;
@override@JsonKey(name: 'revenue_growth') final  String revenueGrowth;
@override@JsonKey(name: 'net_income_growth') final  String netIncomeGrowth;

/// Create a copy of FinancialsQuarterDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialsQuarterDtoCopyWith<_FinancialsQuarterDto> get copyWith => __$FinancialsQuarterDtoCopyWithImpl<_FinancialsQuarterDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinancialsQuarterDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialsQuarterDto&&(identical(other.period, period) || other.period == period)&&(identical(other.reportDate, reportDate) || other.reportDate == reportDate)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.eps, eps) || other.eps == eps)&&(identical(other.epsEstimate, epsEstimate) || other.epsEstimate == epsEstimate)&&(identical(other.revenueGrowth, revenueGrowth) || other.revenueGrowth == revenueGrowth)&&(identical(other.netIncomeGrowth, netIncomeGrowth) || other.netIncomeGrowth == netIncomeGrowth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,reportDate,revenue,netIncome,eps,epsEstimate,revenueGrowth,netIncomeGrowth);

@override
String toString() {
  return 'FinancialsQuarterDto(period: $period, reportDate: $reportDate, revenue: $revenue, netIncome: $netIncome, eps: $eps, epsEstimate: $epsEstimate, revenueGrowth: $revenueGrowth, netIncomeGrowth: $netIncomeGrowth)';
}


}

/// @nodoc
abstract mixin class _$FinancialsQuarterDtoCopyWith<$Res> implements $FinancialsQuarterDtoCopyWith<$Res> {
  factory _$FinancialsQuarterDtoCopyWith(_FinancialsQuarterDto value, $Res Function(_FinancialsQuarterDto) _then) = __$FinancialsQuarterDtoCopyWithImpl;
@override @useResult
$Res call({
 String period,@JsonKey(name: 'report_date') String reportDate, String revenue,@JsonKey(name: 'net_income') String netIncome, String eps,@JsonKey(name: 'eps_estimate') String epsEstimate,@JsonKey(name: 'revenue_growth') String revenueGrowth,@JsonKey(name: 'net_income_growth') String netIncomeGrowth
});




}
/// @nodoc
class __$FinancialsQuarterDtoCopyWithImpl<$Res>
    implements _$FinancialsQuarterDtoCopyWith<$Res> {
  __$FinancialsQuarterDtoCopyWithImpl(this._self, this._then);

  final _FinancialsQuarterDto _self;
  final $Res Function(_FinancialsQuarterDto) _then;

/// Create a copy of FinancialsQuarterDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? reportDate = null,Object? revenue = null,Object? netIncome = null,Object? eps = null,Object? epsEstimate = null,Object? revenueGrowth = null,Object? netIncomeGrowth = null,}) {
  return _then(_FinancialsQuarterDto(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,reportDate: null == reportDate ? _self.reportDate : reportDate // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,netIncome: null == netIncome ? _self.netIncome : netIncome // ignore: cast_nullable_to_non_nullable
as String,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as String,epsEstimate: null == epsEstimate ? _self.epsEstimate : epsEstimate // ignore: cast_nullable_to_non_nullable
as String,revenueGrowth: null == revenueGrowth ? _self.revenueGrowth : revenueGrowth // ignore: cast_nullable_to_non_nullable
as String,netIncomeGrowth: null == netIncomeGrowth ? _self.netIncomeGrowth : netIncomeGrowth // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FinancialsResponseDto {

 String get symbol;@JsonKey(name: 'next_earnings_date') String get nextEarningsDate;@JsonKey(name: 'next_earnings_quarter') String get nextEarningsQuarter; List<FinancialsQuarterDto> get quarters;
/// Create a copy of FinancialsResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialsResponseDtoCopyWith<FinancialsResponseDto> get copyWith => _$FinancialsResponseDtoCopyWithImpl<FinancialsResponseDto>(this as FinancialsResponseDto, _$identity);

  /// Serializes this FinancialsResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialsResponseDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.nextEarningsDate, nextEarningsDate) || other.nextEarningsDate == nextEarningsDate)&&(identical(other.nextEarningsQuarter, nextEarningsQuarter) || other.nextEarningsQuarter == nextEarningsQuarter)&&const DeepCollectionEquality().equals(other.quarters, quarters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,nextEarningsDate,nextEarningsQuarter,const DeepCollectionEquality().hash(quarters));

@override
String toString() {
  return 'FinancialsResponseDto(symbol: $symbol, nextEarningsDate: $nextEarningsDate, nextEarningsQuarter: $nextEarningsQuarter, quarters: $quarters)';
}


}

/// @nodoc
abstract mixin class $FinancialsResponseDtoCopyWith<$Res>  {
  factory $FinancialsResponseDtoCopyWith(FinancialsResponseDto value, $Res Function(FinancialsResponseDto) _then) = _$FinancialsResponseDtoCopyWithImpl;
@useResult
$Res call({
 String symbol,@JsonKey(name: 'next_earnings_date') String nextEarningsDate,@JsonKey(name: 'next_earnings_quarter') String nextEarningsQuarter, List<FinancialsQuarterDto> quarters
});




}
/// @nodoc
class _$FinancialsResponseDtoCopyWithImpl<$Res>
    implements $FinancialsResponseDtoCopyWith<$Res> {
  _$FinancialsResponseDtoCopyWithImpl(this._self, this._then);

  final FinancialsResponseDto _self;
  final $Res Function(FinancialsResponseDto) _then;

/// Create a copy of FinancialsResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? nextEarningsDate = null,Object? nextEarningsQuarter = null,Object? quarters = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,nextEarningsDate: null == nextEarningsDate ? _self.nextEarningsDate : nextEarningsDate // ignore: cast_nullable_to_non_nullable
as String,nextEarningsQuarter: null == nextEarningsQuarter ? _self.nextEarningsQuarter : nextEarningsQuarter // ignore: cast_nullable_to_non_nullable
as String,quarters: null == quarters ? _self.quarters : quarters // ignore: cast_nullable_to_non_nullable
as List<FinancialsQuarterDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialsResponseDto].
extension FinancialsResponseDtoPatterns on FinancialsResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialsResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialsResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialsResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _FinancialsResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialsResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialsResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol, @JsonKey(name: 'next_earnings_date')  String nextEarningsDate, @JsonKey(name: 'next_earnings_quarter')  String nextEarningsQuarter,  List<FinancialsQuarterDto> quarters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialsResponseDto() when $default != null:
return $default(_that.symbol,_that.nextEarningsDate,_that.nextEarningsQuarter,_that.quarters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol, @JsonKey(name: 'next_earnings_date')  String nextEarningsDate, @JsonKey(name: 'next_earnings_quarter')  String nextEarningsQuarter,  List<FinancialsQuarterDto> quarters)  $default,) {final _that = this;
switch (_that) {
case _FinancialsResponseDto():
return $default(_that.symbol,_that.nextEarningsDate,_that.nextEarningsQuarter,_that.quarters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol, @JsonKey(name: 'next_earnings_date')  String nextEarningsDate, @JsonKey(name: 'next_earnings_quarter')  String nextEarningsQuarter,  List<FinancialsQuarterDto> quarters)?  $default,) {final _that = this;
switch (_that) {
case _FinancialsResponseDto() when $default != null:
return $default(_that.symbol,_that.nextEarningsDate,_that.nextEarningsQuarter,_that.quarters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinancialsResponseDto implements FinancialsResponseDto {
  const _FinancialsResponseDto({required this.symbol, @JsonKey(name: 'next_earnings_date') required this.nextEarningsDate, @JsonKey(name: 'next_earnings_quarter') required this.nextEarningsQuarter, required final  List<FinancialsQuarterDto> quarters}): _quarters = quarters;
  factory _FinancialsResponseDto.fromJson(Map<String, dynamic> json) => _$FinancialsResponseDtoFromJson(json);

@override final  String symbol;
@override@JsonKey(name: 'next_earnings_date') final  String nextEarningsDate;
@override@JsonKey(name: 'next_earnings_quarter') final  String nextEarningsQuarter;
 final  List<FinancialsQuarterDto> _quarters;
@override List<FinancialsQuarterDto> get quarters {
  if (_quarters is EqualUnmodifiableListView) return _quarters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quarters);
}


/// Create a copy of FinancialsResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialsResponseDtoCopyWith<_FinancialsResponseDto> get copyWith => __$FinancialsResponseDtoCopyWithImpl<_FinancialsResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinancialsResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialsResponseDto&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.nextEarningsDate, nextEarningsDate) || other.nextEarningsDate == nextEarningsDate)&&(identical(other.nextEarningsQuarter, nextEarningsQuarter) || other.nextEarningsQuarter == nextEarningsQuarter)&&const DeepCollectionEquality().equals(other._quarters, _quarters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,nextEarningsDate,nextEarningsQuarter,const DeepCollectionEquality().hash(_quarters));

@override
String toString() {
  return 'FinancialsResponseDto(symbol: $symbol, nextEarningsDate: $nextEarningsDate, nextEarningsQuarter: $nextEarningsQuarter, quarters: $quarters)';
}


}

/// @nodoc
abstract mixin class _$FinancialsResponseDtoCopyWith<$Res> implements $FinancialsResponseDtoCopyWith<$Res> {
  factory _$FinancialsResponseDtoCopyWith(_FinancialsResponseDto value, $Res Function(_FinancialsResponseDto) _then) = __$FinancialsResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String symbol,@JsonKey(name: 'next_earnings_date') String nextEarningsDate,@JsonKey(name: 'next_earnings_quarter') String nextEarningsQuarter, List<FinancialsQuarterDto> quarters
});




}
/// @nodoc
class __$FinancialsResponseDtoCopyWithImpl<$Res>
    implements _$FinancialsResponseDtoCopyWith<$Res> {
  __$FinancialsResponseDtoCopyWithImpl(this._self, this._then);

  final _FinancialsResponseDto _self;
  final $Res Function(_FinancialsResponseDto) _then;

/// Create a copy of FinancialsResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? nextEarningsDate = null,Object? nextEarningsQuarter = null,Object? quarters = null,}) {
  return _then(_FinancialsResponseDto(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,nextEarningsDate: null == nextEarningsDate ? _self.nextEarningsDate : nextEarningsDate // ignore: cast_nullable_to_non_nullable
as String,nextEarningsQuarter: null == nextEarningsQuarter ? _self.nextEarningsQuarter : nextEarningsQuarter // ignore: cast_nullable_to_non_nullable
as String,quarters: null == quarters ? _self._quarters : quarters // ignore: cast_nullable_to_non_nullable
as List<FinancialsQuarterDto>,
  ));
}


}


/// @nodoc
mixin _$WatchlistResponseDto {

 List<String> get symbols; Map<String, QuoteDto> get quotes;@JsonKey(name: 'as_of') String get asOf;
/// Create a copy of WatchlistResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchlistResponseDtoCopyWith<WatchlistResponseDto> get copyWith => _$WatchlistResponseDtoCopyWithImpl<WatchlistResponseDto>(this as WatchlistResponseDto, _$identity);

  /// Serializes this WatchlistResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchlistResponseDto&&const DeepCollectionEquality().equals(other.symbols, symbols)&&const DeepCollectionEquality().equals(other.quotes, quotes)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(symbols),const DeepCollectionEquality().hash(quotes),asOf);

@override
String toString() {
  return 'WatchlistResponseDto(symbols: $symbols, quotes: $quotes, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class $WatchlistResponseDtoCopyWith<$Res>  {
  factory $WatchlistResponseDtoCopyWith(WatchlistResponseDto value, $Res Function(WatchlistResponseDto) _then) = _$WatchlistResponseDtoCopyWithImpl;
@useResult
$Res call({
 List<String> symbols, Map<String, QuoteDto> quotes,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class _$WatchlistResponseDtoCopyWithImpl<$Res>
    implements $WatchlistResponseDtoCopyWith<$Res> {
  _$WatchlistResponseDtoCopyWithImpl(this._self, this._then);

  final WatchlistResponseDto _self;
  final $Res Function(WatchlistResponseDto) _then;

/// Create a copy of WatchlistResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbols = null,Object? quotes = null,Object? asOf = null,}) {
  return _then(_self.copyWith(
symbols: null == symbols ? _self.symbols : symbols // ignore: cast_nullable_to_non_nullable
as List<String>,quotes: null == quotes ? _self.quotes : quotes // ignore: cast_nullable_to_non_nullable
as Map<String, QuoteDto>,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchlistResponseDto].
extension WatchlistResponseDtoPatterns on WatchlistResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchlistResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchlistResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchlistResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _WatchlistResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchlistResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _WatchlistResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> symbols,  Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of')  String asOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchlistResponseDto() when $default != null:
return $default(_that.symbols,_that.quotes,_that.asOf);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> symbols,  Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of')  String asOf)  $default,) {final _that = this;
switch (_that) {
case _WatchlistResponseDto():
return $default(_that.symbols,_that.quotes,_that.asOf);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> symbols,  Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of')  String asOf)?  $default,) {final _that = this;
switch (_that) {
case _WatchlistResponseDto() when $default != null:
return $default(_that.symbols,_that.quotes,_that.asOf);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WatchlistResponseDto implements WatchlistResponseDto {
  const _WatchlistResponseDto({required final  List<String> symbols, required final  Map<String, QuoteDto> quotes, @JsonKey(name: 'as_of') required this.asOf}): _symbols = symbols,_quotes = quotes;
  factory _WatchlistResponseDto.fromJson(Map<String, dynamic> json) => _$WatchlistResponseDtoFromJson(json);

 final  List<String> _symbols;
@override List<String> get symbols {
  if (_symbols is EqualUnmodifiableListView) return _symbols;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_symbols);
}

 final  Map<String, QuoteDto> _quotes;
@override Map<String, QuoteDto> get quotes {
  if (_quotes is EqualUnmodifiableMapView) return _quotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_quotes);
}

@override@JsonKey(name: 'as_of') final  String asOf;

/// Create a copy of WatchlistResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchlistResponseDtoCopyWith<_WatchlistResponseDto> get copyWith => __$WatchlistResponseDtoCopyWithImpl<_WatchlistResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WatchlistResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchlistResponseDto&&const DeepCollectionEquality().equals(other._symbols, _symbols)&&const DeepCollectionEquality().equals(other._quotes, _quotes)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_symbols),const DeepCollectionEquality().hash(_quotes),asOf);

@override
String toString() {
  return 'WatchlistResponseDto(symbols: $symbols, quotes: $quotes, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class _$WatchlistResponseDtoCopyWith<$Res> implements $WatchlistResponseDtoCopyWith<$Res> {
  factory _$WatchlistResponseDtoCopyWith(_WatchlistResponseDto value, $Res Function(_WatchlistResponseDto) _then) = __$WatchlistResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> symbols, Map<String, QuoteDto> quotes,@JsonKey(name: 'as_of') String asOf
});




}
/// @nodoc
class __$WatchlistResponseDtoCopyWithImpl<$Res>
    implements _$WatchlistResponseDtoCopyWith<$Res> {
  __$WatchlistResponseDtoCopyWithImpl(this._self, this._then);

  final _WatchlistResponseDto _self;
  final $Res Function(_WatchlistResponseDto) _then;

/// Create a copy of WatchlistResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbols = null,Object? quotes = null,Object? asOf = null,}) {
  return _then(_WatchlistResponseDto(
symbols: null == symbols ? _self._symbols : symbols // ignore: cast_nullable_to_non_nullable
as List<String>,quotes: null == quotes ? _self._quotes : quotes // ignore: cast_nullable_to_non_nullable
as Map<String, QuoteDto>,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
