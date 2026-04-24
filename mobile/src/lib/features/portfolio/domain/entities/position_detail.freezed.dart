// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PositionDetail {

 String get symbol; String get companyName; String get market; String get sector; int get qty; int get availableQty; Decimal get avgCost; Decimal get currentPrice; Decimal get marketValue; Decimal get unrealizedPnl; Decimal get unrealizedPnlPct; Decimal get todayPnl; Decimal get todayPnlPct; Decimal get realizedPnl; Decimal get costBasis; bool get washSaleFlagged; List<PendingSettlement> get pendingSettlements; List<TradeRecord> get recentTrades;
/// Create a copy of PositionDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionDetailCopyWith<PositionDetail> get copyWith => _$PositionDetailCopyWithImpl<PositionDetail>(this as PositionDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionDetail&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.market, market) || other.market == market)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&(identical(other.realizedPnl, realizedPnl) || other.realizedPnl == realizedPnl)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.washSaleFlagged, washSaleFlagged) || other.washSaleFlagged == washSaleFlagged)&&const DeepCollectionEquality().equals(other.pendingSettlements, pendingSettlements)&&const DeepCollectionEquality().equals(other.recentTrades, recentTrades));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,companyName,market,sector,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,realizedPnl,costBasis,washSaleFlagged,const DeepCollectionEquality().hash(pendingSettlements),const DeepCollectionEquality().hash(recentTrades));

@override
String toString() {
  return 'PositionDetail(symbol: $symbol, companyName: $companyName, market: $market, sector: $sector, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, realizedPnl: $realizedPnl, costBasis: $costBasis, washSaleFlagged: $washSaleFlagged, pendingSettlements: $pendingSettlements, recentTrades: $recentTrades)';
}


}

/// @nodoc
abstract mixin class $PositionDetailCopyWith<$Res>  {
  factory $PositionDetailCopyWith(PositionDetail value, $Res Function(PositionDetail) _then) = _$PositionDetailCopyWithImpl;
@useResult
$Res call({
 String symbol, String companyName, String market, String sector, int qty, int availableQty, Decimal avgCost, Decimal currentPrice, Decimal marketValue, Decimal unrealizedPnl, Decimal unrealizedPnlPct, Decimal todayPnl, Decimal todayPnlPct, Decimal realizedPnl, Decimal costBasis, bool washSaleFlagged, List<PendingSettlement> pendingSettlements, List<TradeRecord> recentTrades
});




}
/// @nodoc
class _$PositionDetailCopyWithImpl<$Res>
    implements $PositionDetailCopyWith<$Res> {
  _$PositionDetailCopyWithImpl(this._self, this._then);

  final PositionDetail _self;
  final $Res Function(PositionDetail) _then;

/// Create a copy of PositionDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? companyName = null,Object? market = null,Object? sector = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? realizedPnl = null,Object? costBasis = null,Object? washSaleFlagged = null,Object? pendingSettlements = null,Object? recentTrades = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as Decimal,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,realizedPnl: null == realizedPnl ? _self.realizedPnl : realizedPnl // ignore: cast_nullable_to_non_nullable
as Decimal,costBasis: null == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as Decimal,washSaleFlagged: null == washSaleFlagged ? _self.washSaleFlagged : washSaleFlagged // ignore: cast_nullable_to_non_nullable
as bool,pendingSettlements: null == pendingSettlements ? _self.pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlement>,recentTrades: null == recentTrades ? _self.recentTrades : recentTrades // ignore: cast_nullable_to_non_nullable
as List<TradeRecord>,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionDetail].
extension PositionDetailPatterns on PositionDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionDetail value)  $default,){
final _that = this;
switch (_that) {
case _PositionDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PositionDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String companyName,  String market,  String sector,  int qty,  int availableQty,  Decimal avgCost,  Decimal currentPrice,  Decimal marketValue,  Decimal unrealizedPnl,  Decimal unrealizedPnlPct,  Decimal todayPnl,  Decimal todayPnlPct,  Decimal realizedPnl,  Decimal costBasis,  bool washSaleFlagged,  List<PendingSettlement> pendingSettlements,  List<TradeRecord> recentTrades)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionDetail() when $default != null:
return $default(_that.symbol,_that.companyName,_that.market,_that.sector,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.realizedPnl,_that.costBasis,_that.washSaleFlagged,_that.pendingSettlements,_that.recentTrades);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String companyName,  String market,  String sector,  int qty,  int availableQty,  Decimal avgCost,  Decimal currentPrice,  Decimal marketValue,  Decimal unrealizedPnl,  Decimal unrealizedPnlPct,  Decimal todayPnl,  Decimal todayPnlPct,  Decimal realizedPnl,  Decimal costBasis,  bool washSaleFlagged,  List<PendingSettlement> pendingSettlements,  List<TradeRecord> recentTrades)  $default,) {final _that = this;
switch (_that) {
case _PositionDetail():
return $default(_that.symbol,_that.companyName,_that.market,_that.sector,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.realizedPnl,_that.costBasis,_that.washSaleFlagged,_that.pendingSettlements,_that.recentTrades);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String companyName,  String market,  String sector,  int qty,  int availableQty,  Decimal avgCost,  Decimal currentPrice,  Decimal marketValue,  Decimal unrealizedPnl,  Decimal unrealizedPnlPct,  Decimal todayPnl,  Decimal todayPnlPct,  Decimal realizedPnl,  Decimal costBasis,  bool washSaleFlagged,  List<PendingSettlement> pendingSettlements,  List<TradeRecord> recentTrades)?  $default,) {final _that = this;
switch (_that) {
case _PositionDetail() when $default != null:
return $default(_that.symbol,_that.companyName,_that.market,_that.sector,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.realizedPnl,_that.costBasis,_that.washSaleFlagged,_that.pendingSettlements,_that.recentTrades);case _:
  return null;

}
}

}

/// @nodoc


class _PositionDetail implements PositionDetail {
  const _PositionDetail({required this.symbol, required this.companyName, required this.market, required this.sector, required this.qty, required this.availableQty, required this.avgCost, required this.currentPrice, required this.marketValue, required this.unrealizedPnl, required this.unrealizedPnlPct, required this.todayPnl, required this.todayPnlPct, required this.realizedPnl, required this.costBasis, this.washSaleFlagged = false, final  List<PendingSettlement> pendingSettlements = const [], final  List<TradeRecord> recentTrades = const []}): _pendingSettlements = pendingSettlements,_recentTrades = recentTrades;
  

@override final  String symbol;
@override final  String companyName;
@override final  String market;
@override final  String sector;
@override final  int qty;
@override final  int availableQty;
@override final  Decimal avgCost;
@override final  Decimal currentPrice;
@override final  Decimal marketValue;
@override final  Decimal unrealizedPnl;
@override final  Decimal unrealizedPnlPct;
@override final  Decimal todayPnl;
@override final  Decimal todayPnlPct;
@override final  Decimal realizedPnl;
@override final  Decimal costBasis;
@override@JsonKey() final  bool washSaleFlagged;
 final  List<PendingSettlement> _pendingSettlements;
@override@JsonKey() List<PendingSettlement> get pendingSettlements {
  if (_pendingSettlements is EqualUnmodifiableListView) return _pendingSettlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingSettlements);
}

 final  List<TradeRecord> _recentTrades;
@override@JsonKey() List<TradeRecord> get recentTrades {
  if (_recentTrades is EqualUnmodifiableListView) return _recentTrades;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentTrades);
}


/// Create a copy of PositionDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionDetailCopyWith<_PositionDetail> get copyWith => __$PositionDetailCopyWithImpl<_PositionDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionDetail&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.market, market) || other.market == market)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&(identical(other.realizedPnl, realizedPnl) || other.realizedPnl == realizedPnl)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.washSaleFlagged, washSaleFlagged) || other.washSaleFlagged == washSaleFlagged)&&const DeepCollectionEquality().equals(other._pendingSettlements, _pendingSettlements)&&const DeepCollectionEquality().equals(other._recentTrades, _recentTrades));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,companyName,market,sector,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,realizedPnl,costBasis,washSaleFlagged,const DeepCollectionEquality().hash(_pendingSettlements),const DeepCollectionEquality().hash(_recentTrades));

@override
String toString() {
  return 'PositionDetail(symbol: $symbol, companyName: $companyName, market: $market, sector: $sector, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, realizedPnl: $realizedPnl, costBasis: $costBasis, washSaleFlagged: $washSaleFlagged, pendingSettlements: $pendingSettlements, recentTrades: $recentTrades)';
}


}

/// @nodoc
abstract mixin class _$PositionDetailCopyWith<$Res> implements $PositionDetailCopyWith<$Res> {
  factory _$PositionDetailCopyWith(_PositionDetail value, $Res Function(_PositionDetail) _then) = __$PositionDetailCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String companyName, String market, String sector, int qty, int availableQty, Decimal avgCost, Decimal currentPrice, Decimal marketValue, Decimal unrealizedPnl, Decimal unrealizedPnlPct, Decimal todayPnl, Decimal todayPnlPct, Decimal realizedPnl, Decimal costBasis, bool washSaleFlagged, List<PendingSettlement> pendingSettlements, List<TradeRecord> recentTrades
});




}
/// @nodoc
class __$PositionDetailCopyWithImpl<$Res>
    implements _$PositionDetailCopyWith<$Res> {
  __$PositionDetailCopyWithImpl(this._self, this._then);

  final _PositionDetail _self;
  final $Res Function(_PositionDetail) _then;

/// Create a copy of PositionDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? companyName = null,Object? market = null,Object? sector = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? realizedPnl = null,Object? costBasis = null,Object? washSaleFlagged = null,Object? pendingSettlements = null,Object? recentTrades = null,}) {
  return _then(_PositionDetail(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as Decimal,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,realizedPnl: null == realizedPnl ? _self.realizedPnl : realizedPnl // ignore: cast_nullable_to_non_nullable
as Decimal,costBasis: null == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as Decimal,washSaleFlagged: null == washSaleFlagged ? _self.washSaleFlagged : washSaleFlagged // ignore: cast_nullable_to_non_nullable
as bool,pendingSettlements: null == pendingSettlements ? _self._pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlement>,recentTrades: null == recentTrades ? _self._recentTrades : recentTrades // ignore: cast_nullable_to_non_nullable
as List<TradeRecord>,
  ));
}


}

// dart format on
