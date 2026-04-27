// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_balance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountBalance {

 String get accountId; String get currency;/// Total assets = availableBalance + unsettledAmount + position market value
 Decimal get totalBalance;/// Cash available for trading or withdrawal (unfrozen)
 Decimal get availableBalance;/// Unsettled proceeds from sold securities (US T+1, HK T+2 — not withdrawable)
 Decimal get unsettledAmount;/// available_balance minus frozen pending withdrawals; computed by Fund Transfer service
 Decimal get withdrawableBalance; DateTime get updatedAt;
/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountBalanceCopyWith<AccountBalance> get copyWith => _$AccountBalanceCopyWithImpl<AccountBalance>(this as AccountBalance, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountBalance&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.unsettledAmount, unsettledAmount) || other.unsettledAmount == unsettledAmount)&&(identical(other.withdrawableBalance, withdrawableBalance) || other.withdrawableBalance == withdrawableBalance)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,currency,totalBalance,availableBalance,unsettledAmount,withdrawableBalance,updatedAt);

@override
String toString() {
  return 'AccountBalance(accountId: $accountId, currency: $currency, totalBalance: $totalBalance, availableBalance: $availableBalance, unsettledAmount: $unsettledAmount, withdrawableBalance: $withdrawableBalance, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountBalanceCopyWith<$Res>  {
  factory $AccountBalanceCopyWith(AccountBalance value, $Res Function(AccountBalance) _then) = _$AccountBalanceCopyWithImpl;
@useResult
$Res call({
 String accountId, String currency, Decimal totalBalance, Decimal availableBalance, Decimal unsettledAmount, Decimal withdrawableBalance, DateTime updatedAt
});




}
/// @nodoc
class _$AccountBalanceCopyWithImpl<$Res>
    implements $AccountBalanceCopyWith<$Res> {
  _$AccountBalanceCopyWithImpl(this._self, this._then);

  final AccountBalance _self;
  final $Res Function(AccountBalance) _then;

/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? currency = null,Object? totalBalance = null,Object? availableBalance = null,Object? unsettledAmount = null,Object? withdrawableBalance = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as Decimal,availableBalance: null == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as Decimal,unsettledAmount: null == unsettledAmount ? _self.unsettledAmount : unsettledAmount // ignore: cast_nullable_to_non_nullable
as Decimal,withdrawableBalance: null == withdrawableBalance ? _self.withdrawableBalance : withdrawableBalance // ignore: cast_nullable_to_non_nullable
as Decimal,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountBalance].
extension AccountBalancePatterns on AccountBalance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountBalance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountBalance value)  $default,){
final _that = this;
switch (_that) {
case _AccountBalance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountBalance value)?  $default,){
final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String currency,  Decimal totalBalance,  Decimal availableBalance,  Decimal unsettledAmount,  Decimal withdrawableBalance,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
return $default(_that.accountId,_that.currency,_that.totalBalance,_that.availableBalance,_that.unsettledAmount,_that.withdrawableBalance,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String currency,  Decimal totalBalance,  Decimal availableBalance,  Decimal unsettledAmount,  Decimal withdrawableBalance,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountBalance():
return $default(_that.accountId,_that.currency,_that.totalBalance,_that.availableBalance,_that.unsettledAmount,_that.withdrawableBalance,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String currency,  Decimal totalBalance,  Decimal availableBalance,  Decimal unsettledAmount,  Decimal withdrawableBalance,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountBalance() when $default != null:
return $default(_that.accountId,_that.currency,_that.totalBalance,_that.availableBalance,_that.unsettledAmount,_that.withdrawableBalance,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AccountBalance implements AccountBalance {
  const _AccountBalance({required this.accountId, required this.currency, required this.totalBalance, required this.availableBalance, required this.unsettledAmount, required this.withdrawableBalance, required this.updatedAt});
  

@override final  String accountId;
@override final  String currency;
/// Total assets = availableBalance + unsettledAmount + position market value
@override final  Decimal totalBalance;
/// Cash available for trading or withdrawal (unfrozen)
@override final  Decimal availableBalance;
/// Unsettled proceeds from sold securities (US T+1, HK T+2 — not withdrawable)
@override final  Decimal unsettledAmount;
/// available_balance minus frozen pending withdrawals; computed by Fund Transfer service
@override final  Decimal withdrawableBalance;
@override final  DateTime updatedAt;

/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountBalanceCopyWith<_AccountBalance> get copyWith => __$AccountBalanceCopyWithImpl<_AccountBalance>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountBalance&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.unsettledAmount, unsettledAmount) || other.unsettledAmount == unsettledAmount)&&(identical(other.withdrawableBalance, withdrawableBalance) || other.withdrawableBalance == withdrawableBalance)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,currency,totalBalance,availableBalance,unsettledAmount,withdrawableBalance,updatedAt);

@override
String toString() {
  return 'AccountBalance(accountId: $accountId, currency: $currency, totalBalance: $totalBalance, availableBalance: $availableBalance, unsettledAmount: $unsettledAmount, withdrawableBalance: $withdrawableBalance, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountBalanceCopyWith<$Res> implements $AccountBalanceCopyWith<$Res> {
  factory _$AccountBalanceCopyWith(_AccountBalance value, $Res Function(_AccountBalance) _then) = __$AccountBalanceCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String currency, Decimal totalBalance, Decimal availableBalance, Decimal unsettledAmount, Decimal withdrawableBalance, DateTime updatedAt
});




}
/// @nodoc
class __$AccountBalanceCopyWithImpl<$Res>
    implements _$AccountBalanceCopyWith<$Res> {
  __$AccountBalanceCopyWithImpl(this._self, this._then);

  final _AccountBalance _self;
  final $Res Function(_AccountBalance) _then;

/// Create a copy of AccountBalance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? currency = null,Object? totalBalance = null,Object? availableBalance = null,Object? unsettledAmount = null,Object? withdrawableBalance = null,Object? updatedAt = null,}) {
  return _then(_AccountBalance(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as Decimal,availableBalance: null == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as Decimal,unsettledAmount: null == unsettledAmount ? _self.unsettledAmount : unsettledAmount // ignore: cast_nullable_to_non_nullable
as Decimal,withdrawableBalance: null == withdrawableBalance ? _self.withdrawableBalance : withdrawableBalance // ignore: cast_nullable_to_non_nullable
as Decimal,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
