// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_detail_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PositionDetailModel {

@JsonKey(name: 'symbol') String get symbol;@JsonKey(name: 'company_name') String get companyName;@JsonKey(name: 'market') String get market;@JsonKey(name: 'sector') String get sector;@JsonKey(name: 'quantity') int get qty;@JsonKey(name: 'settled_qty') int get availableQty;@JsonKey(name: 'avg_cost') String get avgCost;@JsonKey(name: 'current_price') String get currentPrice;@JsonKey(name: 'market_value') String get marketValue;@JsonKey(name: 'unrealized_pnl') String get unrealizedPnl;@JsonKey(name: 'unrealized_pnl_pct') String get unrealizedPnlPct;@JsonKey(name: 'today_pnl') String get todayPnl;@JsonKey(name: 'today_pnl_pct') String get todayPnlPct;@JsonKey(name: 'realized_pnl') String get realizedPnl;@JsonKey(name: 'cost_basis') String get costBasis;@JsonKey(name: 'wash_sale_status') String get washSaleStatus;@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> get pendingSettlements;@JsonKey(name: 'recent_trades') List<TradeRecordModel> get recentTrades;
/// Create a copy of PositionDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionDetailModelCopyWith<PositionDetailModel> get copyWith => _$PositionDetailModelCopyWithImpl<PositionDetailModel>(this as PositionDetailModel, _$identity);

  /// Serializes this PositionDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionDetailModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.market, market) || other.market == market)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&(identical(other.realizedPnl, realizedPnl) || other.realizedPnl == realizedPnl)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.washSaleStatus, washSaleStatus) || other.washSaleStatus == washSaleStatus)&&const DeepCollectionEquality().equals(other.pendingSettlements, pendingSettlements)&&const DeepCollectionEquality().equals(other.recentTrades, recentTrades));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,companyName,market,sector,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,realizedPnl,costBasis,washSaleStatus,const DeepCollectionEquality().hash(pendingSettlements),const DeepCollectionEquality().hash(recentTrades));

@override
String toString() {
  return 'PositionDetailModel(symbol: $symbol, companyName: $companyName, market: $market, sector: $sector, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, realizedPnl: $realizedPnl, costBasis: $costBasis, washSaleStatus: $washSaleStatus, pendingSettlements: $pendingSettlements, recentTrades: $recentTrades)';
}


}

/// @nodoc
abstract mixin class $PositionDetailModelCopyWith<$Res>  {
  factory $PositionDetailModelCopyWith(PositionDetailModel value, $Res Function(PositionDetailModel) _then) = _$PositionDetailModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'symbol') String symbol,@JsonKey(name: 'company_name') String companyName,@JsonKey(name: 'market') String market,@JsonKey(name: 'sector') String sector,@JsonKey(name: 'quantity') int qty,@JsonKey(name: 'settled_qty') int availableQty,@JsonKey(name: 'avg_cost') String avgCost,@JsonKey(name: 'current_price') String currentPrice,@JsonKey(name: 'market_value') String marketValue,@JsonKey(name: 'unrealized_pnl') String unrealizedPnl,@JsonKey(name: 'unrealized_pnl_pct') String unrealizedPnlPct,@JsonKey(name: 'today_pnl') String todayPnl,@JsonKey(name: 'today_pnl_pct') String todayPnlPct,@JsonKey(name: 'realized_pnl') String realizedPnl,@JsonKey(name: 'cost_basis') String costBasis,@JsonKey(name: 'wash_sale_status') String washSaleStatus,@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> pendingSettlements,@JsonKey(name: 'recent_trades') List<TradeRecordModel> recentTrades
});




}
/// @nodoc
class _$PositionDetailModelCopyWithImpl<$Res>
    implements $PositionDetailModelCopyWith<$Res> {
  _$PositionDetailModelCopyWithImpl(this._self, this._then);

  final PositionDetailModel _self;
  final $Res Function(PositionDetailModel) _then;

/// Create a copy of PositionDetailModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? companyName = null,Object? market = null,Object? sector = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? realizedPnl = null,Object? costBasis = null,Object? washSaleStatus = null,Object? pendingSettlements = null,Object? recentTrades = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as String,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as String,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as String,realizedPnl: null == realizedPnl ? _self.realizedPnl : realizedPnl // ignore: cast_nullable_to_non_nullable
as String,costBasis: null == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as String,washSaleStatus: null == washSaleStatus ? _self.washSaleStatus : washSaleStatus // ignore: cast_nullable_to_non_nullable
as String,pendingSettlements: null == pendingSettlements ? _self.pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlementModel>,recentTrades: null == recentTrades ? _self.recentTrades : recentTrades // ignore: cast_nullable_to_non_nullable
as List<TradeRecordModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionDetailModel].
extension PositionDetailModelPatterns on PositionDetailModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionDetailModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionDetailModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionDetailModel value)  $default,){
final _that = this;
switch (_that) {
case _PositionDetailModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionDetailModel value)?  $default,){
final _that = this;
switch (_that) {
case _PositionDetailModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'company_name')  String companyName, @JsonKey(name: 'market')  String market, @JsonKey(name: 'sector')  String sector, @JsonKey(name: 'quantity')  int qty, @JsonKey(name: 'settled_qty')  int availableQty, @JsonKey(name: 'avg_cost')  String avgCost, @JsonKey(name: 'current_price')  String currentPrice, @JsonKey(name: 'market_value')  String marketValue, @JsonKey(name: 'unrealized_pnl')  String unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct')  String unrealizedPnlPct, @JsonKey(name: 'today_pnl')  String todayPnl, @JsonKey(name: 'today_pnl_pct')  String todayPnlPct, @JsonKey(name: 'realized_pnl')  String realizedPnl, @JsonKey(name: 'cost_basis')  String costBasis, @JsonKey(name: 'wash_sale_status')  String washSaleStatus, @JsonKey(name: 'pending_settlements')  List<PendingSettlementModel> pendingSettlements, @JsonKey(name: 'recent_trades')  List<TradeRecordModel> recentTrades)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionDetailModel() when $default != null:
return $default(_that.symbol,_that.companyName,_that.market,_that.sector,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.realizedPnl,_that.costBasis,_that.washSaleStatus,_that.pendingSettlements,_that.recentTrades);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'company_name')  String companyName, @JsonKey(name: 'market')  String market, @JsonKey(name: 'sector')  String sector, @JsonKey(name: 'quantity')  int qty, @JsonKey(name: 'settled_qty')  int availableQty, @JsonKey(name: 'avg_cost')  String avgCost, @JsonKey(name: 'current_price')  String currentPrice, @JsonKey(name: 'market_value')  String marketValue, @JsonKey(name: 'unrealized_pnl')  String unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct')  String unrealizedPnlPct, @JsonKey(name: 'today_pnl')  String todayPnl, @JsonKey(name: 'today_pnl_pct')  String todayPnlPct, @JsonKey(name: 'realized_pnl')  String realizedPnl, @JsonKey(name: 'cost_basis')  String costBasis, @JsonKey(name: 'wash_sale_status')  String washSaleStatus, @JsonKey(name: 'pending_settlements')  List<PendingSettlementModel> pendingSettlements, @JsonKey(name: 'recent_trades')  List<TradeRecordModel> recentTrades)  $default,) {final _that = this;
switch (_that) {
case _PositionDetailModel():
return $default(_that.symbol,_that.companyName,_that.market,_that.sector,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.realizedPnl,_that.costBasis,_that.washSaleStatus,_that.pendingSettlements,_that.recentTrades);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'company_name')  String companyName, @JsonKey(name: 'market')  String market, @JsonKey(name: 'sector')  String sector, @JsonKey(name: 'quantity')  int qty, @JsonKey(name: 'settled_qty')  int availableQty, @JsonKey(name: 'avg_cost')  String avgCost, @JsonKey(name: 'current_price')  String currentPrice, @JsonKey(name: 'market_value')  String marketValue, @JsonKey(name: 'unrealized_pnl')  String unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct')  String unrealizedPnlPct, @JsonKey(name: 'today_pnl')  String todayPnl, @JsonKey(name: 'today_pnl_pct')  String todayPnlPct, @JsonKey(name: 'realized_pnl')  String realizedPnl, @JsonKey(name: 'cost_basis')  String costBasis, @JsonKey(name: 'wash_sale_status')  String washSaleStatus, @JsonKey(name: 'pending_settlements')  List<PendingSettlementModel> pendingSettlements, @JsonKey(name: 'recent_trades')  List<TradeRecordModel> recentTrades)?  $default,) {final _that = this;
switch (_that) {
case _PositionDetailModel() when $default != null:
return $default(_that.symbol,_that.companyName,_that.market,_that.sector,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.realizedPnl,_that.costBasis,_that.washSaleStatus,_that.pendingSettlements,_that.recentTrades);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PositionDetailModel implements PositionDetailModel {
  const _PositionDetailModel({@JsonKey(name: 'symbol') required this.symbol, @JsonKey(name: 'company_name') required this.companyName, @JsonKey(name: 'market') required this.market, @JsonKey(name: 'sector') this.sector = 'Other', @JsonKey(name: 'quantity') required this.qty, @JsonKey(name: 'settled_qty') required this.availableQty, @JsonKey(name: 'avg_cost') required this.avgCost, @JsonKey(name: 'current_price') required this.currentPrice, @JsonKey(name: 'market_value') required this.marketValue, @JsonKey(name: 'unrealized_pnl') required this.unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct') required this.unrealizedPnlPct, @JsonKey(name: 'today_pnl') required this.todayPnl, @JsonKey(name: 'today_pnl_pct') required this.todayPnlPct, @JsonKey(name: 'realized_pnl') this.realizedPnl = '0', @JsonKey(name: 'cost_basis') required this.costBasis, @JsonKey(name: 'wash_sale_status') this.washSaleStatus = 'clean', @JsonKey(name: 'pending_settlements') final  List<PendingSettlementModel> pendingSettlements = const [], @JsonKey(name: 'recent_trades') final  List<TradeRecordModel> recentTrades = const []}): _pendingSettlements = pendingSettlements,_recentTrades = recentTrades;
  factory _PositionDetailModel.fromJson(Map<String, dynamic> json) => _$PositionDetailModelFromJson(json);

@override@JsonKey(name: 'symbol') final  String symbol;
@override@JsonKey(name: 'company_name') final  String companyName;
@override@JsonKey(name: 'market') final  String market;
@override@JsonKey(name: 'sector') final  String sector;
@override@JsonKey(name: 'quantity') final  int qty;
@override@JsonKey(name: 'settled_qty') final  int availableQty;
@override@JsonKey(name: 'avg_cost') final  String avgCost;
@override@JsonKey(name: 'current_price') final  String currentPrice;
@override@JsonKey(name: 'market_value') final  String marketValue;
@override@JsonKey(name: 'unrealized_pnl') final  String unrealizedPnl;
@override@JsonKey(name: 'unrealized_pnl_pct') final  String unrealizedPnlPct;
@override@JsonKey(name: 'today_pnl') final  String todayPnl;
@override@JsonKey(name: 'today_pnl_pct') final  String todayPnlPct;
@override@JsonKey(name: 'realized_pnl') final  String realizedPnl;
@override@JsonKey(name: 'cost_basis') final  String costBasis;
@override@JsonKey(name: 'wash_sale_status') final  String washSaleStatus;
 final  List<PendingSettlementModel> _pendingSettlements;
@override@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> get pendingSettlements {
  if (_pendingSettlements is EqualUnmodifiableListView) return _pendingSettlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingSettlements);
}

 final  List<TradeRecordModel> _recentTrades;
@override@JsonKey(name: 'recent_trades') List<TradeRecordModel> get recentTrades {
  if (_recentTrades is EqualUnmodifiableListView) return _recentTrades;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentTrades);
}


/// Create a copy of PositionDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionDetailModelCopyWith<_PositionDetailModel> get copyWith => __$PositionDetailModelCopyWithImpl<_PositionDetailModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PositionDetailModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionDetailModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.market, market) || other.market == market)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&(identical(other.realizedPnl, realizedPnl) || other.realizedPnl == realizedPnl)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.washSaleStatus, washSaleStatus) || other.washSaleStatus == washSaleStatus)&&const DeepCollectionEquality().equals(other._pendingSettlements, _pendingSettlements)&&const DeepCollectionEquality().equals(other._recentTrades, _recentTrades));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,companyName,market,sector,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,realizedPnl,costBasis,washSaleStatus,const DeepCollectionEquality().hash(_pendingSettlements),const DeepCollectionEquality().hash(_recentTrades));

@override
String toString() {
  return 'PositionDetailModel(symbol: $symbol, companyName: $companyName, market: $market, sector: $sector, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, realizedPnl: $realizedPnl, costBasis: $costBasis, washSaleStatus: $washSaleStatus, pendingSettlements: $pendingSettlements, recentTrades: $recentTrades)';
}


}

/// @nodoc
abstract mixin class _$PositionDetailModelCopyWith<$Res> implements $PositionDetailModelCopyWith<$Res> {
  factory _$PositionDetailModelCopyWith(_PositionDetailModel value, $Res Function(_PositionDetailModel) _then) = __$PositionDetailModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'symbol') String symbol,@JsonKey(name: 'company_name') String companyName,@JsonKey(name: 'market') String market,@JsonKey(name: 'sector') String sector,@JsonKey(name: 'quantity') int qty,@JsonKey(name: 'settled_qty') int availableQty,@JsonKey(name: 'avg_cost') String avgCost,@JsonKey(name: 'current_price') String currentPrice,@JsonKey(name: 'market_value') String marketValue,@JsonKey(name: 'unrealized_pnl') String unrealizedPnl,@JsonKey(name: 'unrealized_pnl_pct') String unrealizedPnlPct,@JsonKey(name: 'today_pnl') String todayPnl,@JsonKey(name: 'today_pnl_pct') String todayPnlPct,@JsonKey(name: 'realized_pnl') String realizedPnl,@JsonKey(name: 'cost_basis') String costBasis,@JsonKey(name: 'wash_sale_status') String washSaleStatus,@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> pendingSettlements,@JsonKey(name: 'recent_trades') List<TradeRecordModel> recentTrades
});




}
/// @nodoc
class __$PositionDetailModelCopyWithImpl<$Res>
    implements _$PositionDetailModelCopyWith<$Res> {
  __$PositionDetailModelCopyWithImpl(this._self, this._then);

  final _PositionDetailModel _self;
  final $Res Function(_PositionDetailModel) _then;

/// Create a copy of PositionDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? companyName = null,Object? market = null,Object? sector = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? realizedPnl = null,Object? costBasis = null,Object? washSaleStatus = null,Object? pendingSettlements = null,Object? recentTrades = null,}) {
  return _then(_PositionDetailModel(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,sector: null == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as String,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as String,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as String,realizedPnl: null == realizedPnl ? _self.realizedPnl : realizedPnl // ignore: cast_nullable_to_non_nullable
as String,costBasis: null == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as String,washSaleStatus: null == washSaleStatus ? _self.washSaleStatus : washSaleStatus // ignore: cast_nullable_to_non_nullable
as String,pendingSettlements: null == pendingSettlements ? _self._pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlementModel>,recentTrades: null == recentTrades ? _self._recentTrades : recentTrades // ignore: cast_nullable_to_non_nullable
as List<TradeRecordModel>,
  ));
}


}

// dart format on
