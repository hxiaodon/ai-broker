// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingSettlement {

 int get qty; DateTime get settleDate;
/// Create a copy of PendingSettlement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingSettlementCopyWith<PendingSettlement> get copyWith => _$PendingSettlementCopyWithImpl<PendingSettlement>(this as PendingSettlement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingSettlement&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.settleDate, settleDate) || other.settleDate == settleDate));
}


@override
int get hashCode => Object.hash(runtimeType,qty,settleDate);

@override
String toString() {
  return 'PendingSettlement(qty: $qty, settleDate: $settleDate)';
}


}

/// @nodoc
abstract mixin class $PendingSettlementCopyWith<$Res>  {
  factory $PendingSettlementCopyWith(PendingSettlement value, $Res Function(PendingSettlement) _then) = _$PendingSettlementCopyWithImpl;
@useResult
$Res call({
 int qty, DateTime settleDate
});




}
/// @nodoc
class _$PendingSettlementCopyWithImpl<$Res>
    implements $PendingSettlementCopyWith<$Res> {
  _$PendingSettlementCopyWithImpl(this._self, this._then);

  final PendingSettlement _self;
  final $Res Function(PendingSettlement) _then;

/// Create a copy of PendingSettlement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? qty = null,Object? settleDate = null,}) {
  return _then(_self.copyWith(
qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,settleDate: null == settleDate ? _self.settleDate : settleDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingSettlement].
extension PendingSettlementPatterns on PendingSettlement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingSettlement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingSettlement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingSettlement value)  $default,){
final _that = this;
switch (_that) {
case _PendingSettlement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingSettlement value)?  $default,){
final _that = this;
switch (_that) {
case _PendingSettlement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int qty,  DateTime settleDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingSettlement() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int qty,  DateTime settleDate)  $default,) {final _that = this;
switch (_that) {
case _PendingSettlement():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int qty,  DateTime settleDate)?  $default,) {final _that = this;
switch (_that) {
case _PendingSettlement() when $default != null:
return $default(_that.qty,_that.settleDate);case _:
  return null;

}
}

}

/// @nodoc


class _PendingSettlement implements PendingSettlement {
  const _PendingSettlement({required this.qty, required this.settleDate});
  

@override final  int qty;
@override final  DateTime settleDate;

/// Create a copy of PendingSettlement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingSettlementCopyWith<_PendingSettlement> get copyWith => __$PendingSettlementCopyWithImpl<_PendingSettlement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingSettlement&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.settleDate, settleDate) || other.settleDate == settleDate));
}


@override
int get hashCode => Object.hash(runtimeType,qty,settleDate);

@override
String toString() {
  return 'PendingSettlement(qty: $qty, settleDate: $settleDate)';
}


}

/// @nodoc
abstract mixin class _$PendingSettlementCopyWith<$Res> implements $PendingSettlementCopyWith<$Res> {
  factory _$PendingSettlementCopyWith(_PendingSettlement value, $Res Function(_PendingSettlement) _then) = __$PendingSettlementCopyWithImpl;
@override @useResult
$Res call({
 int qty, DateTime settleDate
});




}
/// @nodoc
class __$PendingSettlementCopyWithImpl<$Res>
    implements _$PendingSettlementCopyWith<$Res> {
  __$PendingSettlementCopyWithImpl(this._self, this._then);

  final _PendingSettlement _self;
  final $Res Function(_PendingSettlement) _then;

/// Create a copy of PendingSettlement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? qty = null,Object? settleDate = null,}) {
  return _then(_PendingSettlement(
qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,settleDate: null == settleDate ? _self.settleDate : settleDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$Position {

 String get symbol; String get market; int get qty; int get availableQty; Decimal get avgCost; Decimal get currentPrice; Decimal get marketValue; Decimal get unrealizedPnl; Decimal get unrealizedPnlPct; Decimal get todayPnl; Decimal get todayPnlPct; List<PendingSettlement> get pendingSettlements;
/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PositionCopyWith<Position> get copyWith => _$PositionCopyWithImpl<Position>(this as Position, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Position&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&const DeepCollectionEquality().equals(other.pendingSettlements, pendingSettlements));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,market,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,const DeepCollectionEquality().hash(pendingSettlements));

@override
String toString() {
  return 'Position(symbol: $symbol, market: $market, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, pendingSettlements: $pendingSettlements)';
}


}

/// @nodoc
abstract mixin class $PositionCopyWith<$Res>  {
  factory $PositionCopyWith(Position value, $Res Function(Position) _then) = _$PositionCopyWithImpl;
@useResult
$Res call({
 String symbol, String market, int qty, int availableQty, Decimal avgCost, Decimal currentPrice, Decimal marketValue, Decimal unrealizedPnl, Decimal unrealizedPnlPct, Decimal todayPnl, Decimal todayPnlPct, List<PendingSettlement> pendingSettlements
});




}
/// @nodoc
class _$PositionCopyWithImpl<$Res>
    implements $PositionCopyWith<$Res> {
  _$PositionCopyWithImpl(this._self, this._then);

  final Position _self;
  final $Res Function(Position) _then;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? symbol = null,Object? market = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? pendingSettlements = null,}) {
  return _then(_self.copyWith(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as Decimal,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,pendingSettlements: null == pendingSettlements ? _self.pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlement>,
  ));
}

}


/// Adds pattern-matching-related methods to [Position].
extension PositionPatterns on Position {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Position value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Position value)  $default,){
final _that = this;
switch (_that) {
case _Position():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Position value)?  $default,){
final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String symbol,  String market,  int qty,  int availableQty,  Decimal avgCost,  Decimal currentPrice,  Decimal marketValue,  Decimal unrealizedPnl,  Decimal unrealizedPnlPct,  Decimal todayPnl,  Decimal todayPnlPct,  List<PendingSettlement> pendingSettlements)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Position() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String symbol,  String market,  int qty,  int availableQty,  Decimal avgCost,  Decimal currentPrice,  Decimal marketValue,  Decimal unrealizedPnl,  Decimal unrealizedPnlPct,  Decimal todayPnl,  Decimal todayPnlPct,  List<PendingSettlement> pendingSettlements)  $default,) {final _that = this;
switch (_that) {
case _Position():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String symbol,  String market,  int qty,  int availableQty,  Decimal avgCost,  Decimal currentPrice,  Decimal marketValue,  Decimal unrealizedPnl,  Decimal unrealizedPnlPct,  Decimal todayPnl,  Decimal todayPnlPct,  List<PendingSettlement> pendingSettlements)?  $default,) {final _that = this;
switch (_that) {
case _Position() when $default != null:
return $default(_that.symbol,_that.market,_that.qty,_that.availableQty,_that.avgCost,_that.currentPrice,_that.marketValue,_that.unrealizedPnl,_that.unrealizedPnlPct,_that.todayPnl,_that.todayPnlPct,_that.pendingSettlements);case _:
  return null;

}
}

}

/// @nodoc


class _Position implements Position {
  const _Position({required this.symbol, required this.market, required this.qty, required this.availableQty, required this.avgCost, required this.currentPrice, required this.marketValue, required this.unrealizedPnl, required this.unrealizedPnlPct, required this.todayPnl, required this.todayPnlPct, final  List<PendingSettlement> pendingSettlements = const []}): _pendingSettlements = pendingSettlements;
  

@override final  String symbol;
@override final  String market;
@override final  int qty;
@override final  int availableQty;
@override final  Decimal avgCost;
@override final  Decimal currentPrice;
@override final  Decimal marketValue;
@override final  Decimal unrealizedPnl;
@override final  Decimal unrealizedPnlPct;
@override final  Decimal todayPnl;
@override final  Decimal todayPnlPct;
 final  List<PendingSettlement> _pendingSettlements;
@override@JsonKey() List<PendingSettlement> get pendingSettlements {
  if (_pendingSettlements is EqualUnmodifiableListView) return _pendingSettlements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingSettlements);
}


/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PositionCopyWith<_Position> get copyWith => __$PositionCopyWithImpl<_Position>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Position&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.market, market) || other.market == market)&&(identical(other.qty, qty) || other.qty == qty)&&(identical(other.availableQty, availableQty) || other.availableQty == availableQty)&&(identical(other.avgCost, avgCost) || other.avgCost == avgCost)&&(identical(other.currentPrice, currentPrice) || other.currentPrice == currentPrice)&&(identical(other.marketValue, marketValue) || other.marketValue == marketValue)&&(identical(other.unrealizedPnl, unrealizedPnl) || other.unrealizedPnl == unrealizedPnl)&&(identical(other.unrealizedPnlPct, unrealizedPnlPct) || other.unrealizedPnlPct == unrealizedPnlPct)&&(identical(other.todayPnl, todayPnl) || other.todayPnl == todayPnl)&&(identical(other.todayPnlPct, todayPnlPct) || other.todayPnlPct == todayPnlPct)&&const DeepCollectionEquality().equals(other._pendingSettlements, _pendingSettlements));
}


@override
int get hashCode => Object.hash(runtimeType,symbol,market,qty,availableQty,avgCost,currentPrice,marketValue,unrealizedPnl,unrealizedPnlPct,todayPnl,todayPnlPct,const DeepCollectionEquality().hash(_pendingSettlements));

@override
String toString() {
  return 'Position(symbol: $symbol, market: $market, qty: $qty, availableQty: $availableQty, avgCost: $avgCost, currentPrice: $currentPrice, marketValue: $marketValue, unrealizedPnl: $unrealizedPnl, unrealizedPnlPct: $unrealizedPnlPct, todayPnl: $todayPnl, todayPnlPct: $todayPnlPct, pendingSettlements: $pendingSettlements)';
}


}

/// @nodoc
abstract mixin class _$PositionCopyWith<$Res> implements $PositionCopyWith<$Res> {
  factory _$PositionCopyWith(_Position value, $Res Function(_Position) _then) = __$PositionCopyWithImpl;
@override @useResult
$Res call({
 String symbol, String market, int qty, int availableQty, Decimal avgCost, Decimal currentPrice, Decimal marketValue, Decimal unrealizedPnl, Decimal unrealizedPnlPct, Decimal todayPnl, Decimal todayPnlPct, List<PendingSettlement> pendingSettlements
});




}
/// @nodoc
class __$PositionCopyWithImpl<$Res>
    implements _$PositionCopyWith<$Res> {
  __$PositionCopyWithImpl(this._self, this._then);

  final _Position _self;
  final $Res Function(_Position) _then;

/// Create a copy of Position
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? symbol = null,Object? market = null,Object? qty = null,Object? availableQty = null,Object? avgCost = null,Object? currentPrice = null,Object? marketValue = null,Object? unrealizedPnl = null,Object? unrealizedPnlPct = null,Object? todayPnl = null,Object? todayPnlPct = null,Object? pendingSettlements = null,}) {
  return _then(_Position(
symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,market: null == market ? _self.market : market // ignore: cast_nullable_to_non_nullable
as String,qty: null == qty ? _self.qty : qty // ignore: cast_nullable_to_non_nullable
as int,availableQty: null == availableQty ? _self.availableQty : availableQty // ignore: cast_nullable_to_non_nullable
as int,avgCost: null == avgCost ? _self.avgCost : avgCost // ignore: cast_nullable_to_non_nullable
as Decimal,currentPrice: null == currentPrice ? _self.currentPrice : currentPrice // ignore: cast_nullable_to_non_nullable
as Decimal,marketValue: null == marketValue ? _self.marketValue : marketValue // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnl: null == unrealizedPnl ? _self.unrealizedPnl : unrealizedPnl // ignore: cast_nullable_to_non_nullable
as Decimal,unrealizedPnlPct: null == unrealizedPnlPct ? _self.unrealizedPnlPct : unrealizedPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnl: null == todayPnl ? _self.todayPnl : todayPnl // ignore: cast_nullable_to_non_nullable
as Decimal,todayPnlPct: null == todayPnlPct ? _self.todayPnlPct : todayPnlPct // ignore: cast_nullable_to_non_nullable
as Decimal,pendingSettlements: null == pendingSettlements ? _self._pendingSettlements : pendingSettlements // ignore: cast_nullable_to_non_nullable
as List<PendingSettlement>,
  ));
}


}

// dart format on
