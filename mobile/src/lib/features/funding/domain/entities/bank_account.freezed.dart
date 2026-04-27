// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BankAccount {

 String get id; String get accountName;/// Server-masked to last 4 digits (e.g. "****1234")
 String get accountNumberMasked; String get routingNumber; String get bankName; String get currency; bool get isVerified;/// Null when not in cooldown; set after micro-deposit verification passes
 DateTime? get cooldownEndsAt; MicroDepositStatus get microDepositStatus;/// Remaining verification attempts (max 5 per PRD § 4.1)
 int get remainingVerifyAttempts; DateTime get createdAt;
/// Create a copy of BankAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankAccountCopyWith<BankAccount> get copyWith => _$BankAccountCopyWithImpl<BankAccount>(this as BankAccount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.accountNumberMasked, accountNumberMasked) || other.accountNumberMasked == accountNumberMasked)&&(identical(other.routingNumber, routingNumber) || other.routingNumber == routingNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt)&&(identical(other.microDepositStatus, microDepositStatus) || other.microDepositStatus == microDepositStatus)&&(identical(other.remainingVerifyAttempts, remainingVerifyAttempts) || other.remainingVerifyAttempts == remainingVerifyAttempts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountName,accountNumberMasked,routingNumber,bankName,currency,isVerified,cooldownEndsAt,microDepositStatus,remainingVerifyAttempts,createdAt);

@override
String toString() {
  return 'BankAccount(id: $id, accountName: $accountName, accountNumberMasked: $accountNumberMasked, routingNumber: $routingNumber, bankName: $bankName, currency: $currency, isVerified: $isVerified, cooldownEndsAt: $cooldownEndsAt, microDepositStatus: $microDepositStatus, remainingVerifyAttempts: $remainingVerifyAttempts, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BankAccountCopyWith<$Res>  {
  factory $BankAccountCopyWith(BankAccount value, $Res Function(BankAccount) _then) = _$BankAccountCopyWithImpl;
@useResult
$Res call({
 String id, String accountName, String accountNumberMasked, String routingNumber, String bankName, String currency, bool isVerified, DateTime? cooldownEndsAt, MicroDepositStatus microDepositStatus, int remainingVerifyAttempts, DateTime createdAt
});




}
/// @nodoc
class _$BankAccountCopyWithImpl<$Res>
    implements $BankAccountCopyWith<$Res> {
  _$BankAccountCopyWithImpl(this._self, this._then);

  final BankAccount _self;
  final $Res Function(BankAccount) _then;

/// Create a copy of BankAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountName = null,Object? accountNumberMasked = null,Object? routingNumber = null,Object? bankName = null,Object? currency = null,Object? isVerified = null,Object? cooldownEndsAt = freezed,Object? microDepositStatus = null,Object? remainingVerifyAttempts = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,accountNumberMasked: null == accountNumberMasked ? _self.accountNumberMasked : accountNumberMasked // ignore: cast_nullable_to_non_nullable
as String,routingNumber: null == routingNumber ? _self.routingNumber : routingNumber // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,microDepositStatus: null == microDepositStatus ? _self.microDepositStatus : microDepositStatus // ignore: cast_nullable_to_non_nullable
as MicroDepositStatus,remainingVerifyAttempts: null == remainingVerifyAttempts ? _self.remainingVerifyAttempts : remainingVerifyAttempts // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BankAccount].
extension BankAccountPatterns on BankAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankAccount value)  $default,){
final _that = this;
switch (_that) {
case _BankAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankAccount value)?  $default,){
final _that = this;
switch (_that) {
case _BankAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountName,  String accountNumberMasked,  String routingNumber,  String bankName,  String currency,  bool isVerified,  DateTime? cooldownEndsAt,  MicroDepositStatus microDepositStatus,  int remainingVerifyAttempts,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankAccount() when $default != null:
return $default(_that.id,_that.accountName,_that.accountNumberMasked,_that.routingNumber,_that.bankName,_that.currency,_that.isVerified,_that.cooldownEndsAt,_that.microDepositStatus,_that.remainingVerifyAttempts,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountName,  String accountNumberMasked,  String routingNumber,  String bankName,  String currency,  bool isVerified,  DateTime? cooldownEndsAt,  MicroDepositStatus microDepositStatus,  int remainingVerifyAttempts,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BankAccount():
return $default(_that.id,_that.accountName,_that.accountNumberMasked,_that.routingNumber,_that.bankName,_that.currency,_that.isVerified,_that.cooldownEndsAt,_that.microDepositStatus,_that.remainingVerifyAttempts,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountName,  String accountNumberMasked,  String routingNumber,  String bankName,  String currency,  bool isVerified,  DateTime? cooldownEndsAt,  MicroDepositStatus microDepositStatus,  int remainingVerifyAttempts,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BankAccount() when $default != null:
return $default(_that.id,_that.accountName,_that.accountNumberMasked,_that.routingNumber,_that.bankName,_that.currency,_that.isVerified,_that.cooldownEndsAt,_that.microDepositStatus,_that.remainingVerifyAttempts,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _BankAccount extends BankAccount {
  const _BankAccount({required this.id, required this.accountName, required this.accountNumberMasked, required this.routingNumber, required this.bankName, required this.currency, required this.isVerified, this.cooldownEndsAt, required this.microDepositStatus, this.remainingVerifyAttempts = 5, required this.createdAt}): super._();
  

@override final  String id;
@override final  String accountName;
/// Server-masked to last 4 digits (e.g. "****1234")
@override final  String accountNumberMasked;
@override final  String routingNumber;
@override final  String bankName;
@override final  String currency;
@override final  bool isVerified;
/// Null when not in cooldown; set after micro-deposit verification passes
@override final  DateTime? cooldownEndsAt;
@override final  MicroDepositStatus microDepositStatus;
/// Remaining verification attempts (max 5 per PRD § 4.1)
@override@JsonKey() final  int remainingVerifyAttempts;
@override final  DateTime createdAt;

/// Create a copy of BankAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankAccountCopyWith<_BankAccount> get copyWith => __$BankAccountCopyWithImpl<_BankAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.accountNumberMasked, accountNumberMasked) || other.accountNumberMasked == accountNumberMasked)&&(identical(other.routingNumber, routingNumber) || other.routingNumber == routingNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt)&&(identical(other.microDepositStatus, microDepositStatus) || other.microDepositStatus == microDepositStatus)&&(identical(other.remainingVerifyAttempts, remainingVerifyAttempts) || other.remainingVerifyAttempts == remainingVerifyAttempts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountName,accountNumberMasked,routingNumber,bankName,currency,isVerified,cooldownEndsAt,microDepositStatus,remainingVerifyAttempts,createdAt);

@override
String toString() {
  return 'BankAccount(id: $id, accountName: $accountName, accountNumberMasked: $accountNumberMasked, routingNumber: $routingNumber, bankName: $bankName, currency: $currency, isVerified: $isVerified, cooldownEndsAt: $cooldownEndsAt, microDepositStatus: $microDepositStatus, remainingVerifyAttempts: $remainingVerifyAttempts, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BankAccountCopyWith<$Res> implements $BankAccountCopyWith<$Res> {
  factory _$BankAccountCopyWith(_BankAccount value, $Res Function(_BankAccount) _then) = __$BankAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountName, String accountNumberMasked, String routingNumber, String bankName, String currency, bool isVerified, DateTime? cooldownEndsAt, MicroDepositStatus microDepositStatus, int remainingVerifyAttempts, DateTime createdAt
});




}
/// @nodoc
class __$BankAccountCopyWithImpl<$Res>
    implements _$BankAccountCopyWith<$Res> {
  __$BankAccountCopyWithImpl(this._self, this._then);

  final _BankAccount _self;
  final $Res Function(_BankAccount) _then;

/// Create a copy of BankAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountName = null,Object? accountNumberMasked = null,Object? routingNumber = null,Object? bankName = null,Object? currency = null,Object? isVerified = null,Object? cooldownEndsAt = freezed,Object? microDepositStatus = null,Object? remainingVerifyAttempts = null,Object? createdAt = null,}) {
  return _then(_BankAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,accountNumberMasked: null == accountNumberMasked ? _self.accountNumberMasked : accountNumberMasked // ignore: cast_nullable_to_non_nullable
as String,routingNumber: null == routingNumber ? _self.routingNumber : routingNumber // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,microDepositStatus: null == microDepositStatus ? _self.microDepositStatus : microDepositStatus // ignore: cast_nullable_to_non_nullable
as MicroDepositStatus,remainingVerifyAttempts: null == remainingVerifyAttempts ? _self.remainingVerifyAttempts : remainingVerifyAttempts // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
