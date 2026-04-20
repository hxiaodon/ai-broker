// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingSettlementModel {

@JsonKey(name: 'qty') int get qty;@JsonKey(name: 'settle_date') String get settleDate;
/// Create a copy of PendingSettlementModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingSettlementModelCopyWith<PendingSettlementModel> get copyWith => _$PendingSettlementModelCopyWithImpl<PendingSettlementModel>(this as PendingSettlementModel, _$identity);

  /// Serializes this PendingSettlementModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingSettlementModel&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.settleDate, settleDate) || other.settleDate == settleDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,qty,settleDate);

@override
String toString() {
  return 'PendingSettlementModel(qty: $qty, settleDate: $settleDate)';
}


}

/// @nodoc
abstract mixin class $PendingSettlementModelCopyWith<$Res>  {
  factory $PendingSettlementModelCopyWith(PendingSettlementModel value, $Res Function(PendingSettlementModel) _then) = _$PendingSettlementModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'qty') int qty,@JsonKey(name: 'settle_date') String settleDate
});




}
/// @nodoc
class _$PendingSettlementModelCopyWithImpl<$Res>
    implements $PendingSettlementModelCopyWith<$Res> {
  _$PendingSettlementModelCopyWithImpl(this._self, this._then);

  final PendingSettlementModel _self;
  final $Res Function(PendingSettlementModel) _then;

/// Create a copy of PendingSettlementModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? qty = null,Object? settleDate = null,}) {
  return _then(_self.copyWith(
qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,settleDate: null == settleDate ? _self.settleDate : settleDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingSettlementModel].
extension PendingSettlementModelPatterns on PendingSettlementModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingSettlementModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingSettlementModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingSettlementModel value)  $default,){
final _that = this;
switch (_that) {
case _PendingSettlementModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingSettlementModel value)?  $default,){
final _that = this;
switch (_that) {
case _PendingSettlementModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'qty')  int qty, @JsonKey(name: 'settle_date')  String settleDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingSettlementModel() when $default != null:
return $default(_that.qty,_that.settleDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'qty')  int qty, @JsonKey(name: 'settle_date')  String settleDate)  $default,) {final _that = this;
switch (_that) {
case _PendingSettlementModel():
return $default(_that.qty,_that.settleDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'qty')  int qty, @JsonKey(name: 'settle_date')  String settleDate)?  $default,) {final _that = this;
switch (_that) {
case _PendingSettlementModel() when $default != null:
return $default(_that.qty,_that.settleDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingSettlementModel implements PendingSettlementModel {
  const _PendingSettlementModel({@JsonKey(name: 'qty') required this.qty, @JsonKey(name: 'settle_date') required this.settleDate});
  factory _PendingSettlementModel.fromJson(Map<String, dynamic> json) => _$PendingSettlementModelFromJson(json);

@override@JsonKey(name: 'qty') final  int qty;
@override@JsonKey(name: 'settle_date') final  String settleDate;

/// Create a copy of PendingSettlementModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingSettlementModelCopyWith<_PendingSettlementModel> get copyWith => __$PendingSettlementModelCopyWithImpl<_PendingSettlementModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingSettlementModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingSettlementModel&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.settleDate, settleDate) || other.settleDate == settleDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,qty,settleDate);

@override
String toString() {
  return 'PendingSettlementModel(qty: $qty, settleDate: $settleDate)';
}


}

/// @nodoc
abstract mixin class _$PendingSettlementModelCopyWith<$Res> implements $PendingSettlementModelCopyWith<$Res> {
  factory _$PendingSettlementModelCopyWith(_PendingSettlementModel value, $Res Function(_PendingSettlementModel) _then) = __$PendingSettlementModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'qty') int qty,@JsonKey(name: 'settle_date') String settleDate
});




}
/// @nodoc
class __$PendingSettlementModelCopyWithImpl<$Res>
    implements _$PendingSettlementModelCopyWith<$Res> {
  __$PendingSettlementModelCopyWithImpl(this._self, this._then);

  final _PendingSettlementModel _self;
  final $Res Function(_PendingSettlementModel) _then;

/// Create a copy of PendingSettlementModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? qty = null,Object? settleDate = null,}) {
  return _then(_PendingSettlementModel(
qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,settleDate: null == settleDate ? _self.settleDate : settleDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PositionModel {

@JsonKey(name: 'symbol') String get symbol;@JsonKey(name: 'market') String get market;@JsonKey(name: 'qty') int get qty;@JsonKey(name: 'available_qty') int get availableQty;@JsonKey(name: 'avg_cost') String get avgCost;@JsonKey(name: 'current_price') String get currentPrice;@JsonKey(name: 'market_value') String get marketValue;@JsonKey(name: 'unrealized_pnl') String get unrealizedPnl;@JsonKey(name: 'unrealized_pnl_pct') String get unrealizedPnlPct;@JsonKey(name: 'today_pnl') String get todayPnl;@JsonKey(name: 'today_pnl_pct') String get todayPnlPct;@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> get pendingSettlements;
/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionModelCopyWith<PositionModel> get copyWith => _$PositionModelCopyWithImpl<PositionModel>(this as PositionModel, _$identity);

  /// Serializes this PositionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PositionModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&const DeepCollectionEquality().equals(other.pendingSettlements, pendingSettlements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,market,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,const DeepCollectionEquality().hash(pendingSettlements));

@override
String toString() {
  return 'PositionModel(symbol: $symbol, market: $market, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, pendingSettlements: $pendingSettlements)';
}


}

/// @nodoc
abstract mixin class $PositionModelCopyWith<$Res>  {
  factory $PositionModelCopyWith(PositionModel value, $Res Function(PositionModel) _then) = _$PositionModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'symbol') String symbol,@JsonKey(name: 'market') String market,@JsonKey(name: 'qty') int qty,@JsonKey(name: 'available_qty') int availableQty,@JsonKey(name: 'avg_cost') String avgCost,@JsonKey(name: 'current_price') String currentPrice,@JsonKey(name: 'market_value') String marketValue,@JsonKey(name: 'unrealized_pnl') String unrealizedPnl,@JsonKey(name: 'unrealized_pnl_pct') String unrealizedPnlPct,@JsonKey(name: 'today_pnl') String todayPnl,@JsonKey(name: 'today_pnl_pct') String todayPnlPct,@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> pendingSettlements
});




}
/// @nodoc
class _$PositionModelCopyWithImpl<$Res>
    implements $PositionModelCopyWith<$Res> {
  _$PositionModelCopyWithImpl(this._self, this._then);

  final PositionModel _self;
  final $Res Function(PositionModel) _then;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? market = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? pendingSettlements = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as String,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as String,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as String,pendingSettlements: null == pendingSettlements ? _self.pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlementModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [PositionModel].
extension PositionModelPatterns on PositionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PositionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PositionModel value)  $default,){
final _that = this;
switch (_that) {
case _PositionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PositionModel value)?  $default,){
final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'market')  String market, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'available_qty')  int availableQty, @JsonKey(name: 'avg_cost')  String avgCost, @JsonKey(name: 'current_price')  String currentPrice, @JsonKey(name: 'market_value')  String marketValue, @JsonKey(name: 'unrealized_pnl')  String unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct')  String unrealizedPnlPct, @JsonKey(name: 'today_pnl')  String todayPnl, @JsonKey(name: 'today_pnl_pct')  String todayPnlPct, @JsonKey(name: 'pending_settlements')  List<PendingSettlementModel> pendingSettlements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.symbol,_that.market,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.pendingSettlements);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'market')  String market, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'available_qty')  int availableQty, @JsonKey(name: 'avg_cost')  String avgCost, @JsonKey(name: 'current_price')  String currentPrice, @JsonKey(name: 'market_value')  String marketValue, @JsonKey(name: 'unrealized_pnl')  String unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct')  String unrealizedPnlPct, @JsonKey(name: 'today_pnl')  String todayPnl, @JsonKey(name: 'today_pnl_pct')  String todayPnlPct, @JsonKey(name: 'pending_settlements')  List<PendingSettlementModel> pendingSettlements)  $default,) {final _that = this;
switch (_that) {
case _PositionModel():
return $default(_that.symbol,_that.market,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.pendingSettlements);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'symbol')  String symbol, @JsonKey(name: 'market')  String market, @JsonKey(name: 'qty')  int qty, @JsonKey(name: 'available_qty')  int availableQty, @JsonKey(name: 'avg_cost')  String avgCost, @JsonKey(name: 'current_price')  String currentPrice, @JsonKey(name: 'market_value')  String marketValue, @JsonKey(name: 'unrealized_pnl')  String unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct')  String unrealizedPnlPct, @JsonKey(name: 'today_pnl')  String todayPnl, @JsonKey(name: 'today_pnl_pct')  String todayPnlPct, @JsonKey(name: 'pending_settlements')  List<PendingSettlementModel> pendingSettlements)?  $default,) {final _that = this;
switch (_that) {
case _PositionModel() when $default != null:
return $default(_that.symbol,_that.market,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.pendingSettlements);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PositionModel implements PositionModel {
  const _PositionModel({@JsonKey(name: 'symbol') required this.symbol, @JsonKey(name: 'market') required this.market, @JsonKey(name: 'qty') required this.qty, @JsonKey(name: 'available_qty') required this.availableQty, @JsonKey(name: 'avg_cost') required this.avgCost, @JsonKey(name: 'current_price') required this.currentPrice, @JsonKey(name: 'market_value') required this.marketValue, @JsonKey(name: 'unrealized_pnl') required this.unrealizedPnl, @JsonKey(name: 'unrealized_pnl_pct') required this.unrealizedPnlPct, @JsonKey(name: 'today_pnl') required this.todayPnl, @JsonKey(name: 'today_pnl_pct') required this.todayPnlPct, @JsonKey(name: 'pending_settlements') final  List<PendingSettlementModel> pendingSettlements = const []}): _pendingSettlements = pendingSettlements;
  factory _PositionModel.fromJson(Map<String, dynamic> json) => _$PositionModelFromJson(json);

@override@JsonKey(name: 'symbol') final  String symbol;
@override@JsonKey(name: 'market') final  String market;
@override@JsonKey(name: 'qty') final  int qty;
@override@JsonKey(name: 'available_qty') final  int availableQty;
@override@JsonKey(name: 'avg_cost') final  String avgCost;
@override@JsonKey(name: 'current_price') final  String currentPrice;
@override@JsonKey(name: 'market_value') final  String marketValue;
@override@JsonKey(name: 'unrealized_pnl') final  String unrealizedPnl;
@override@JsonKey(name: 'unrealized_pnl_pct') final  String unrealizedPnlPct;
@override@JsonKey(name: 'today_pnl') final  String todayPnl;
@override@JsonKey(name: 'today_pnl_pct') final  String todayPnlPct;
 final  List<PendingSettlementModel> _pendingSettlements;
@override@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> get pendingSettlements {
  if (_pendingSettlements is EqualUnmodifiableListView) return _pendingSettlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingSettlements);
}


/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionModelCopyWith<_PositionModel> get copyWith => __$PositionModelCopyWithImpl<_PositionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PositionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PositionModel&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&const DeepCollectionEquality().equals(other._pendingSettlements, _pendingSettlements));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,symbol,market,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,const DeepCollectionEquality().hash(_pendingSettlements));

@override
String toString() {
  return 'PositionModel(symbol: $symbol, market: $market, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, pendingSettlements: $pendingSettlements)';
}


}

/// @nodoc
abstract mixin class _$PositionModelCopyWith<$Res> implements $PositionModelCopyWith<$Res> {
  factory _$PositionModelCopyWith(_PositionModel value, $Res Function(_PositionModel) _then) = __$PositionModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'symbol') String symbol,@JsonKey(name: 'market') String market,@JsonKey(name: 'qty') int qty,@JsonKey(name: 'available_qty') int availableQty,@JsonKey(name: 'avg_cost') String avgCost,@JsonKey(name: 'current_price') String currentPrice,@JsonKey(name: 'market_value') String marketValue,@JsonKey(name: 'unrealized_pnl') String unrealizedPnl,@JsonKey(name: 'unrealized_pnl_pct') String unrealizedPnlPct,@JsonKey(name: 'today_pnl') String todayPnl,@JsonKey(name: 'today_pnl_pct') String todayPnlPct,@JsonKey(name: 'pending_settlements') List<PendingSettlementModel> pendingSettlements
});




}
/// @nodoc
class __$PositionModelCopyWithImpl<$Res>
    implements _$PositionModelCopyWith<$Res> {
  __$PositionModelCopyWithImpl(this._self, this._then);

  final _PositionModel _self;
  final $Res Function(_PositionModel) _then;

/// Create a copy of PositionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? market = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? pendingSettlements = null,}) {
  return _then(_PositionModel(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as String,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as String,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as String,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as String,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as String,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as String,pendingSettlements: null == pendingSettlements ? _self._pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlementModel>,
  ));
}


}

// dart format on
