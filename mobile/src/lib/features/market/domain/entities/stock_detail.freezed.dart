// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StockDetail {

// ── Quote fields ──────────────────────────────────────────────────────────
 String get symbol; String get name; String get nameZh;/// Market identifier: "US" or "HK".
 String get market; Decimal get price; Decimal get change; Decimal get changePct; Decimal get open; Decimal get high; Decimal get low; Decimal get prevClose; int get volume;/// Daily turnover with unit suffix, e.g. "8.24B". Kept as String.
 String get turnover; Decimal? get bid; Decimal? get ask; bool get delayed; MarketStatus get marketStatus;/// Human-readable session description, e.g. "Regular Trading Hours".
 String get session; bool get isStale; int get staleSinceMs;// ── Fundamental fields ────────────────────────────────────────────────────
/// Market capitalisation with unit suffix, e.g. "2.80T". Kept as String.
 String get marketCap;/// P/E ratio (TTM), e.g. "28.50". String to accommodate "N/A" values.
 String get peRatio;/// Price-to-book ratio, e.g. "42.30".
 String get pbRatio;/// Dividend yield percentage, e.g. "0.52". "0.00" when no dividend.
 String get dividendYield;/// Total shares outstanding.
 int get sharesOutstanding;/// 30-day average daily volume.
 int get avgVolume;/// 52-week high price.
 Decimal get week52High;/// 52-week low price.
 Decimal get week52Low;/// Daily turnover rate: volume / shares_outstanding × 100 (2 decimal places).
/// Pre-computed by the server (market-api-spec §7.6, blocker Q2 resolved 2026-04-04).
 Decimal get turnoverRate;/// Primary listing exchange, e.g. "NASDAQ", "HKEX".
 String get exchange;/// Industry sector in English, e.g. "Technology".
 String get sector;/// Timestamp of the data snapshot (UTC).
 DateTime get asOf;
/// Create a copy of StockDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockDetailCopyWith<StockDetail> get copyWith => _$StockDetailCopyWithImpl<StockDetail>(this as StockDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockDetail&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.session, session) || other.session == session)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.pbRatio, pbRatio) || other.pbRatio == pbRatio)&&(identical(other.dividendYield, dividendYield) || other.dividendYield == dividendYield)&&(identical(other.sharesOutstanding, sharesOutstanding) || other.sharesOutstanding == sharesOutstanding)&&(identical(other.avgVolume, avgVolume) || other.avgVolume == avgVolume)&&(identical(other.week52High, week52High) || other.week52High == week52High)&&(identical(other.week52Low, week52Low) || other.week52Low == week52Low)&&(identical(other.turnoverRate, turnoverRate) || other.turnoverRate == turnoverRate)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}


@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,open,high,low,prevClose,volume,turnover,bid,ask,delayed,marketStatus,session,isStale,staleSinceMs,marketCap,peRatio,pbRatio,dividendYield,sharesOutstanding,avgVolume,week52High,week52Low,turnoverRate,exchange,sector,asOf]);

@override
String toString() {
  return 'StockDetail(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, open: $open, high: $high, low: $low, prevClose: $prevClose, volume: $volume, turnover: $turnover, bid: $bid, ask: $ask, delayed: $delayed, marketStatus: $marketStatus, session: $session, isStale: $isStale, staleSinceMs: $staleSinceMs, marketCap: $marketCap, peRatio: $peRatio, pbRatio: $pbRatio, dividendYield: $dividendYield, sharesOutstanding: $sharesOutstanding, avgVolume: $avgVolume, week52High: $week52High, week52Low: $week52Low, turnoverRate: $turnoverRate, exchange: $exchange, sector: $sector, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class $StockDetailCopyWith<$Res>  {
  factory $StockDetailCopyWith(StockDetail value, $Res Function(StockDetail) _then) = _$StockDetailCopyWithImpl;
@useResult
$Res call({
 String symbol, String name, String nameZh, String market, Decimal price, Decimal change, Decimal changePct, Decimal open, Decimal high, Decimal low, Decimal prevClose, int volume, String turnover, Decimal? bid, Decimal? ask, bool delayed, MarketStatus marketStatus, String session, bool isStale, int staleSinceMs, String marketCap, String peRatio, String pbRatio, String dividendYield, int sharesOutstanding, int avgVolume, Decimal week52High, Decimal week52Low, Decimal turnoverRate, String exchange, String sector, DateTime asOf
});




}
/// @nodoc
class _$StockDetailCopyWithImpl<$Res>
    implements $StockDetailCopyWith<$Res> {
  _$StockDetailCopyWithImpl(this._self, this._then);

  final StockDetail _self;
  final $Res Function(StockDetail) _then;

/// Create a copy of StockDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? open = null,Object? high = null,Object? low = null,Object? prevClose = null,Object? volume = null,Object? turnover = null,Object? bid = freezed,Object? ask = freezed,Object? delayed = null,Object? marketStatus = null,Object? session = null,Object? isStale = null,Object? staleSinceMs = null,Object? marketCap = null,Object? peRatio = null,Object? pbRatio = null,Object? dividendYield = null,Object? sharesOutstanding = null,Object? avgVolume = null,Object? week52High = null,Object? week52Low = null,Object? turnoverRate = null,Object? exchange = null,Object? sector = null,Object? asOf = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as Decimal,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as Decimal,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as Decimal,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as Decimal,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as Decimal?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as Decimal?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as MarketStatus,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as String,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: null == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String,pbRatio: null == pbRatio ? _self.pbRatio : pbRatio // ignore: cast_nullable_to_non_nullable
as String,dividendYield: null == dividendYield ? _self.dividendYield : dividendYield // ignore: cast_nullable_to_non_nullable
as String,sharesOutstanding: null == sharesOutstanding ? _self.sharesOutstanding : sharesOutstanding // ignore: cast_nullable_to_non_nullable
as int,avgVolume: null == avgVolume ? _self.avgVolume : avgVolume // ignore: cast_nullable_to_non_nullable
as int,week52High: null == week52High ? _self.week52High : week52High // ignore: cast_nullable_to_non_nullable
as Decimal,week52Low: null == week52Low ? _self.week52Low : week52Low // ignore: cast_nullable_to_non_nullable
as Decimal,turnoverRate: null == turnoverRate ? _self.turnoverRate : turnoverRate // ignore: cast_nullable_to_non_nullable
as Decimal,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StockDetail].
extension StockDetailPatterns on StockDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockDetail value)  $default,){
final _that = this;
switch (_that) {
case _StockDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockDetail value)?  $default,){
final _that = this;
switch (_that) {
case _StockDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal change,  Decimal changePct,  Decimal open,  Decimal high,  Decimal low,  Decimal prevClose,  int volume,  String turnover,  Decimal? bid,  Decimal? ask,  bool delayed,  MarketStatus marketStatus,  String session,  bool isStale,  int staleSinceMs,  String marketCap,  String peRatio,  String pbRatio,  String dividendYield,  int sharesOutstanding,  int avgVolume,  Decimal week52High,  Decimal week52Low,  Decimal turnoverRate,  String exchange,  String sector,  DateTime asOf)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockDetail() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal change,  Decimal changePct,  Decimal open,  Decimal high,  Decimal low,  Decimal prevClose,  int volume,  String turnover,  Decimal? bid,  Decimal? ask,  bool delayed,  MarketStatus marketStatus,  String session,  bool isStale,  int staleSinceMs,  String marketCap,  String peRatio,  String pbRatio,  String dividendYield,  int sharesOutstanding,  int avgVolume,  Decimal week52High,  Decimal week52Low,  Decimal turnoverRate,  String exchange,  String sector,  DateTime asOf)  $default,) {final _that = this;
switch (_that) {
case _StockDetail():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String name,  String nameZh,  String market,  Decimal price,  Decimal change,  Decimal changePct,  Decimal open,  Decimal high,  Decimal low,  Decimal prevClose,  int volume,  String turnover,  Decimal? bid,  Decimal? ask,  bool delayed,  MarketStatus marketStatus,  String session,  bool isStale,  int staleSinceMs,  String marketCap,  String peRatio,  String pbRatio,  String dividendYield,  int sharesOutstanding,  int avgVolume,  Decimal week52High,  Decimal week52Low,  Decimal turnoverRate,  String exchange,  String sector,  DateTime asOf)?  $default,) {final _that = this;
switch (_that) {
case _StockDetail() when $default != null:
return $default(_that.symbol,_that.name,_that.nameZh,_that.market,_that.price,_that.change,_that.changePct,_that.open,_that.high,_that.low,_that.prevClose,_that.volume,_that.turnover,_that.bid,_that.ask,_that.delayed,_that.marketStatus,_that.session,_that.isStale,_that.staleSinceMs,_that.marketCap,_that.peRatio,_that.pbRatio,_that.dividendYield,_that.sharesOutstanding,_that.avgVolume,_that.week52High,_that.week52Low,_that.turnoverRate,_that.exchange,_that.sector,_that.asOf);case _:
  return null;

}
}

}

/// @nodoc


class _StockDetail extends StockDetail {
  const _StockDetail({required this.symbol, required this.name, required this.nameZh, required this.market, required this.price, required this.change, required this.changePct, required this.open, required this.high, required this.low, required this.prevClose, required this.volume, required this.turnover, this.bid, this.ask, required this.delayed, required this.marketStatus, required this.session, this.isStale = false, this.staleSinceMs = 0, required this.marketCap, required this.peRatio, required this.pbRatio, required this.dividendYield, required this.sharesOutstanding, required this.avgVolume, required this.week52High, required this.week52Low, required this.turnoverRate, required this.exchange, required this.sector, required this.asOf}): super._();
  

// ── Quote fields ──────────────────────────────────────────────────────────
@override final  String symbol;
@override final  String name;
@override final  String nameZh;
/// Market identifier: "US" or "HK".
@override final  String market;
@override final  Decimal price;
@override final  Decimal change;
@override final  Decimal changePct;
@override final  Decimal open;
@override final  Decimal high;
@override final  Decimal low;
@override final  Decimal prevClose;
@override final  int volume;
/// Daily turnover with unit suffix, e.g. "8.24B". Kept as String.
@override final  String turnover;
@override final  Decimal? bid;
@override final  Decimal? ask;
@override final  bool delayed;
@override final  MarketStatus marketStatus;
/// Human-readable session description, e.g. "Regular Trading Hours".
@override final  String session;
@override@JsonKey() final  bool isStale;
@override@JsonKey() final  int staleSinceMs;
// ── Fundamental fields ────────────────────────────────────────────────────
/// Market capitalisation with unit suffix, e.g. "2.80T". Kept as String.
@override final  String marketCap;
/// P/E ratio (TTM), e.g. "28.50". String to accommodate "N/A" values.
@override final  String peRatio;
/// Price-to-book ratio, e.g. "42.30".
@override final  String pbRatio;
/// Dividend yield percentage, e.g. "0.52". "0.00" when no dividend.
@override final  String dividendYield;
/// Total shares outstanding.
@override final  int sharesOutstanding;
/// 30-day average daily volume.
@override final  int avgVolume;
/// 52-week high price.
@override final  Decimal week52High;
/// 52-week low price.
@override final  Decimal week52Low;
/// Daily turnover rate: volume / shares_outstanding × 100 (2 decimal places).
/// Pre-computed by the server (market-api-spec §7.6, blocker Q2 resolved 2026-04-04).
@override final  Decimal turnoverRate;
/// Primary listing exchange, e.g. "NASDAQ", "HKEX".
@override final  String exchange;
/// Industry sector in English, e.g. "Technology".
@override final  String sector;
/// Timestamp of the data snapshot (UTC).
@override final  DateTime asOf;

/// Create a copy of StockDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockDetailCopyWith<_StockDetail> get copyWith => __$StockDetailCopyWithImpl<_StockDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockDetail&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameZh, nameZh) || other.nameZh == nameZh)&&(identical(other.market, market) || other.market == market)&&(identical(other.price, price) || other.price == price)&&(identical(other.change, change) || other.change == change)&&(identical(other.changePct, changePct) || other.changePct == changePct)&&(identical(other.open, open) || other.open == open)&&(identical(other.high, high) || other.high == high)&&(identical(other.low, low) || other.low == low)&&(identical(other.prevClose, prevClose) || other.prevClose == prevClose)&&(identical(other.volume, volume) || other.volume == volume)&&(identical(other.turnover, turnover) || other.turnover == turnover)&&(identical(other.bid, bid) || other.bid == bid)&&(identical(other.ask, ask) || other.ask == ask)&&(identical(other.delayed, delayed) || other.delayed == delayed)&&(identical(other.marketStatus, marketStatus) || other.marketStatus == marketStatus)&&(identical(other.session, session) || other.session == session)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.staleSinceMs, staleSinceMs) || other.staleSinceMs == staleSinceMs)&&(identical(other.marketCap, marketCap) || other.marketCap == marketCap)&&(identical(other.peRatio, peRatio) || other.peRatio == peRatio)&&(identical(other.pbRatio, pbRatio) || other.pbRatio == pbRatio)&&(identical(other.dividendYield, dividendYield) || other.dividendYield == dividendYield)&&(identical(other.sharesOutstanding, sharesOutstanding) || other.sharesOutstanding == sharesOutstanding)&&(identical(other.avgVolume, avgVolume) || other.avgVolume == avgVolume)&&(identical(other.week52High, week52High) || other.week52High == week52High)&&(identical(other.week52Low, week52Low) || other.week52Low == week52Low)&&(identical(other.turnoverRate, turnoverRate) || other.turnoverRate == turnoverRate)&&(identical(other.exchange, exchange) || other.exchange == exchange)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.asOf, asOf) || other.asOf == asOf));
}


@override
int get hashCode => Object.hashAll([runtimeType,symbol,name,nameZh,market,price,change,changePct,open,high,low,prevClose,volume,turnover,bid,ask,delayed,marketStatus,session,isStale,staleSinceMs,marketCap,peRatio,pbRatio,dividendYield,sharesOutstanding,avgVolume,week52High,week52Low,turnoverRate,exchange,sector,asOf]);

@override
String toString() {
  return 'StockDetail(symbol: $symbol, name: $name, nameZh: $nameZh, market: $market, price: $price, change: $change, changePct: $changePct, open: $open, high: $high, low: $low, prevClose: $prevClose, volume: $volume, turnover: $turnover, bid: $bid, ask: $ask, delayed: $delayed, marketStatus: $marketStatus, session: $session, isStale: $isStale, staleSinceMs: $staleSinceMs, marketCap: $marketCap, peRatio: $peRatio, pbRatio: $pbRatio, dividendYield: $dividendYield, sharesOutstanding: $sharesOutstanding, avgVolume: $avgVolume, week52High: $week52High, week52Low: $week52Low, turnoverRate: $turnoverRate, exchange: $exchange, sector: $sector, asOf: $asOf)';
}


}

/// @nodoc
abstract mixin class _$StockDetailCopyWith<$Res> implements $StockDetailCopyWith<$Res> {
  factory _$StockDetailCopyWith(_StockDetail value, $Res Function(_StockDetail) _then) = __$StockDetailCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String name, String nameZh, String market, Decimal price, Decimal change, Decimal changePct, Decimal open, Decimal high, Decimal low, Decimal prevClose, int volume, String turnover, Decimal? bid, Decimal? ask, bool delayed, MarketStatus marketStatus, String session, bool isStale, int staleSinceMs, String marketCap, String peRatio, String pbRatio, String dividendYield, int sharesOutstanding, int avgVolume, Decimal week52High, Decimal week52Low, Decimal turnoverRate, String exchange, String sector, DateTime asOf
});




}
/// @nodoc
class __$StockDetailCopyWithImpl<$Res>
    implements _$StockDetailCopyWith<$Res> {
  __$StockDetailCopyWithImpl(this._self, this._then);

  final _StockDetail _self;
  final $Res Function(_StockDetail) _then;

/// Create a copy of StockDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? name = null,Object? nameZh = null,Object? market = null,Object? price = null,Object? change = null,Object? changePct = null,Object? open = null,Object? high = null,Object? low = null,Object? prevClose = null,Object? volume = null,Object? turnover = null,Object? bid = freezed,Object? ask = freezed,Object? delayed = null,Object? marketStatus = null,Object? session = null,Object? isStale = null,Object? staleSinceMs = null,Object? marketCap = null,Object? peRatio = null,Object? pbRatio = null,Object? dividendYield = null,Object? sharesOutstanding = null,Object? avgVolume = null,Object? week52High = null,Object? week52Low = null,Object? turnoverRate = null,Object? exchange = null,Object? sector = null,Object? asOf = null,}) {
  return _then(_StockDetail(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameZh: null == nameZh ? _self.nameZh : nameZh // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as Decimal,changePct: null == changePct ? _self.changePct : changePct // ignore: cast_nullable_to_non_nullable
as Decimal,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as Decimal,high: null == high ? _self.high : high // ignore: cast_nullable_to_non_nullable
as Decimal,low: null == low ? _self.low : low // ignore: cast_nullable_to_non_nullable
as Decimal,prevClose: null == prevClose ? _self.prevClose : prevClose // ignore: cast_nullable_to_non_nullable
as Decimal,volume: null == volume ? _self.volume : volume // ignore: cast_nullable_to_non_nullable
as int,turnover: null == turnover ? _self.turnover : turnover // ignore: cast_nullable_to_non_nullable
as String,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as Decimal?,ask: freezed == ask ? _self.ask : ask // ignore: cast_nullable_to_non_nullable
as Decimal?,delayed: null == delayed ? _self.delayed : delayed // ignore: cast_nullable_to_non_nullable
as bool,marketStatus: null == marketStatus ? _self.marketStatus : marketStatus // ignore: cast_nullable_to_non_nullable
as MarketStatus,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as String,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,staleSinceMs: null == staleSinceMs ? _self.staleSinceMs : staleSinceMs // ignore: cast_nullable_to_non_nullable
as int,marketCap: null == marketCap ? _self.marketCap : marketCap // ignore: cast_nullable_to_non_nullable
as String,peRatio: null == peRatio ? _self.peRatio : peRatio // ignore: cast_nullable_to_non_nullable
as String,pbRatio: null == pbRatio ? _self.pbRatio : pbRatio // ignore: cast_nullable_to_non_nullable
as String,dividendYield: null == dividendYield ? _self.dividendYield : dividendYield // ignore: cast_nullable_to_non_nullable
as String,sharesOutstanding: null == sharesOutstanding ? _self.sharesOutstanding : sharesOutstanding // ignore: cast_nullable_to_non_nullable
as int,avgVolume: null == avgVolume ? _self.avgVolume : avgVolume // ignore: cast_nullable_to_non_nullable
as int,week52High: null == week52High ? _self.week52High : week52High // ignore: cast_nullable_to_non_nullable
as Decimal,week52Low: null == week52Low ? _self.week52Low : week52Low // ignore: cast_nullable_to_non_nullable
as Decimal,turnoverRate: null == turnoverRate ? _self.turnoverRate : turnoverRate // ignore: cast_nullable_to_non_nullable
as Decimal,exchange: null == exchange ? _self.exchange : exchange // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,asOf: null == asOf ? _self.asOf : asOf // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
