// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Quote {

 String get symbol;/// Company English name.
 String get name;/// Company Chinese name. Empty string if not available.
 String get nameZh;/// Market identifier: "US" or "HK".
 String get market;/// Latest trade price (4 decimal places for US, 3 for HK).
 Decimal get price;/// Price change vs previous regular-session close (market-api-spec §1.8).
 Decimal get change;/// Percentage change vs previous regular-session close (2 decimal places).
 Decimal get changePct;/// Cumulative daily trade volume (shares).
 int get volume;/// Best bid price (Level 1). Null when market is closed.
 Decimal? get bid;/// Best ask price (Level 1). Null when market is closed.
 Decimal? get ask;/// Daily turnover with unit suffix, e.g. "8.24B". Kept as String (带单位).
 String get turnover;/// Previous regular-session closing price.
 Decimal get prevClose;/// Daily opening price.
 Decimal get open;/// Daily high price.
 Decimal get high;/// Daily low price.
 Decimal get low;/// Market capitalisation with unit suffix, e.g. "2.80T". Kept as String.
 String get marketCap;/// P/E ratio (TTM). Null for stocks with no earnings (SPACs, loss-making).
 String? get peRatio;/// True when the quote is delayed 15 minutes (guest / unauthenticated).
 bool get delayed;/// Current market trading status.
 MarketStatus get marketStatus;/// True when this data point has not been refreshed within 1 second
/// (market-api-spec §1.7). Used by the trading engine to reject market orders.
 bool get isStale;/// Duration in milliseconds that the quote has been stale.
/// 0 when [isStale] is false.
 int get staleSinceMs;
/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteCopyWith<Quote> get copyWith => _$QuoteCopyWithImpl<Quote>(this as Quote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quote&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs));
}


@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,volume,bid,ask,turnover,prevClose,open,high,low,marketCap,peRatio,delayed,marketStatus,isStale,staleSinceMs]);

@override
String toString() {
  return 'Quote(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, volume: $volume, bid: $bid, ask: $ask, turnover: $turnover, prevClose: $prevClose, open: $open, high: $high, low: $low, marketCap: $marketCap, peRatio: $peRatio, delayed: $delayed, marketStatus: $marketStatus, isStale: $isStale, staleSinceMs: $staleSinceMs)';
}


}

/// @nodoc
abstract mixin class $QuoteCopyWith<$Res>  {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) _then) = _$QuoteCopyWithImpl;
@useResult
$Res call({
 String symbol, String name, String nameZh, String market, Decimal price, Decimal change, Decimal changePct, int volume, Decimal? bid, Decimal? ask, String turnover, Decimal prevClose, Decimal open, Decimal high, Decimal low, String marketCap, String? peRatio, bool delayed, MarketStatus marketStatus, bool isStale, int staleSinceMs
});




}
/// @nodoc
class _$QuoteCopyWithImpl<$Res>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._self, this._then);

  final Quote _self;
  final $Res Function(Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? bid = freezed,Object? ask = freezed,Object? turnover = null,Object? prevClose = null,Object? open = null,Object? high = null,Object? low = null,Object? marketCap = null,Object? peRatio = freezed,Object? delayed = null,Object? marketStatus = null,Object? isStale = null,Object? staleSinceMs = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as Decimal?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as Decimal?,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as Decimal,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as Decimal,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as Decimal,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as Decimal,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: freezed == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as MarketStatus,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Quote].
extension QuotePatterns on Quote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quote value)  $default,){
final _that = this;
switch (_that) {
case _Quote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quote value)?  $default,){
final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal change,  Decimal changePct,  int volume,  Decimal? bid,  Decimal? ask,  String turnover,  Decimal prevClose,  Decimal open,  Decimal high,  Decimal low,  String marketCap,  String? peRatio,  bool delayed,  MarketStatus marketStatus,  bool isStale,  int staleSinceMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal change,  Decimal changePct,  int volume,  Decimal? bid,  Decimal? ask,  String turnover,  Decimal prevClose,  Decimal open,  Decimal high,  Decimal low,  String marketCap,  String? peRatio,  bool delayed,  MarketStatus marketStatus,  bool isStale,  int staleSinceMs)  $default,) {final _that = this;
switch (_that) {
case _Quote():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal change,  Decimal changePct,  int volume,  Decimal? bid,  Decimal? ask,  String turnover,  Decimal prevClose,  Decimal open,  Decimal high,  Decimal low,  String marketCap,  String? peRatio,  bool delayed,  MarketStatus marketStatus,  bool isStale,  int staleSinceMs)?  $default,) {final _that = this;
switch (_that) {
case _Quote() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.volume,_that.bid,_that.ask,_that.turnover,_that.prevClose,_that.open,_that.high,_that.low,_that.marketCap,_that.peRatio,_that.delayed,_that.marketStatus,_that.isStale,_that.staleSinceMs);case _:
  return null;

}
}

}

/// @nodoc


class _Quote extends Quote {
  const _Quote({required this.symbol, required this.name, required this.nameZh, required this.market, required this.price, required this.change, required this.changePct, required this.volume, this.bid, this.ask, required this.turnover, required this.prevClose, required this.open, required this.high, required this.low, required this.marketCap, this.peRatio, required this.delayed, required this.marketStatus, this.isStale = false, this.staleSinceMs = 0}): super._();
  

@override final  String symbol;
/// Company English name.
@override final  String name;
/// Company Chinese name. Empty string if not available.
@override final  String nameZh;
/// Market identifier: "US" or "HK".
@override final  String market;
/// Latest trade price (4 decimal places for US, 3 for HK).
@override final  Decimal price;
/// Price change vs previous regular-session close (market-api-spec §1.8).
@override final  Decimal change;
/// Percentage change vs previous regular-session close (2 decimal places).
@override final  Decimal changePct;
/// Cumulative daily trade volume (shares).
@override final  int volume;
/// Best bid price (Level 1). Null when market is closed.
@override final  Decimal? bid;
/// Best ask price (Level 1). Null when market is closed.
@override final  Decimal? ask;
/// Daily turnover with unit suffix, e.g. "8.24B". Kept as String (带单位).
@override final  String turnover;
/// Previous regular-session closing price.
@override final  Decimal prevClose;
/// Daily opening price.
@override final  Decimal open;
/// Daily high price.
@override final  Decimal high;
/// Daily low price.
@override final  Decimal low;
/// Market capitalisation with unit suffix, e.g. "2.80T". Kept as String.
@override final  String marketCap;
/// P/E ratio (TTM). Null for stocks with no earnings (SPACs, loss-making).
@override final  String? peRatio;
/// True when the quote is delayed 15 minutes (guest / unauthenticated).
@override final  bool delayed;
/// Current market trading status.
@override final  MarketStatus marketStatus;
/// True when this data point has not been refreshed within 1 second
/// (market-api-spec §1.7). Used by the trading engine to reject market orders.
@override@JsonKey() final  bool isStale;
/// Duration in milliseconds that the quote has been stale.
/// 0 when [isStale] is false.
@override@JsonKey() final  int staleSinceMs;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteCopyWith<_Quote> get copyWith => __$QuoteCopyWithImpl<_Quote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quote&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs));
}


@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,volume,bid,ask,turnover,prevClose,open,high,low,marketCap,peRatio,delayed,marketStatus,isStale,staleSinceMs]);

@override
String toString() {
  return 'Quote(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, volume: $volume, bid: $bid, ask: $ask, turnover: $turnover, prevClose: $prevClose, open: $open, high: $high, low: $low, marketCap: $marketCap, peRatio: $peRatio, delayed: $delayed, marketStatus: $marketStatus, isStale: $isStale, staleSinceMs: $staleSinceMs)';
}


}

/// @nodoc
abstract mixin class _$QuoteCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$QuoteCopyWith(_Quote value, $Res Function(_Quote) _then) = __$QuoteCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name, String nameZh, String market, Decimal price, Decimal change, Decimal changePct, int volume, Decimal? bid, Decimal? ask, String turnover, Decimal prevClose, Decimal open, Decimal high, Decimal low, String marketCap, String? peRatio, bool delayed, MarketStatus marketStatus, bool isStale, int staleSinceMs
});




}
/// @nodoc
class __$QuoteCopyWithImpl<$Res>
    implements _$QuoteCopyWith<$Res> {
  __$QuoteCopyWithImpl(this._self, this._then);

  final _Quote _self;
  final $Res Function(_Quote) _then;

/// Create a copy of Quote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? volume = null,Object? bid = freezed,Object? ask = freezed,Object? turnover = null,Object? prevClose = null,Object? open = null,Object? high = null,Object? low = null,Object? marketCap = null,Object? peRatio = freezed,Object? delayed = null,Object? marketStatus = null,Object? isStale = null,Object? staleSinceMs = null,}) {
  return _then(_Quote(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as Decimal?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as Decimal?,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as Decimal,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as Decimal,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as Decimal,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as Decimal,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: freezed == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as MarketStatus,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
