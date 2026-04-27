// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FundTransfer {

 String get transferId; String get accountId; TransferType get type; TransferStatus get status; Decimal get amount; String get currency; BankChannel get channel; String get bankAccountId;/// Idempotency key echoed back by server
 String get requestId; String get failureReason; DateTime get createdAt; DateTime get updatedAt; DateTime? get completedAt;
/// Create a copy of FundTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundTransferCopyWith<FundTransfer> get copyWith => _$FundTransferCopyWithImpl<FundTransfer>(this as FundTransfer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundTransfer&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,transferId,accountId,type,status,amount,currency,channel,bankAccountId,requestId,failureReason,createdAt,updatedAt,completedAt);

@override
String toString() {
  return 'FundTransfer(transferId: $transferId, accountId: $accountId, type: $type, status: $status, amount: $amount, currency: $currency, channel: $channel, bankAccountId: $bankAccountId, requestId: $requestId, failureReason: $failureReason, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $FundTransferCopyWith<$Res>  {
  factory $FundTransferCopyWith(FundTransfer value, $Res Function(FundTransfer) _then) = _$FundTransferCopyWithImpl;
@useResult
$Res call({
 String transferId, String accountId, TransferType type, TransferStatus status, Decimal amount, String currency, BankChannel channel, String bankAccountId, String requestId, String failureReason, DateTime createdAt, DateTime updatedAt, DateTime? completedAt
});




}
/// @nodoc
class _$FundTransferCopyWithImpl<$Res>
    implements $FundTransferCopyWith<$Res> {
  _$FundTransferCopyWithImpl(this._self, this._then);

  final FundTransfer _self;
  final $Res Function(FundTransfer) _then;

/// Create a copy of FundTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transferId = null,Object? accountId = null,Object? type = null,Object? status = null,Object? amount = null,Object? currency = null,Object? channel = null,Object? bankAccountId = null,Object? requestId = null,Object? failureReason = null,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
transferId: null == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransferType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as BankChannel,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,failureReason: null == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FundTransfer].
extension FundTransferPatterns on FundTransfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundTransfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundTransfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundTransfer value)  $default,){
final _that = this;
switch (_that) {
case _FundTransfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundTransfer value)?  $default,){
final _that = this;
switch (_that) {
case _FundTransfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String transferId,  String accountId,  TransferType type,  TransferStatus status,  Decimal amount,  String currency,  BankChannel channel,  String bankAccountId,  String requestId,  String failureReason,  DateTime createdAt,  DateTime updatedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundTransfer() when $default != null:
return $default(_that.transferId,_that.accountId,_that.type,_that.status,_that.amount,_that.currency,_that.channel,_that.bankAccountId,_that.requestId,_that.failureReason,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String transferId,  String accountId,  TransferType type,  TransferStatus status,  Decimal amount,  String currency,  BankChannel channel,  String bankAccountId,  String requestId,  String failureReason,  DateTime createdAt,  DateTime updatedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _FundTransfer():
return $default(_that.transferId,_that.accountId,_that.type,_that.status,_that.amount,_that.currency,_that.channel,_that.bankAccountId,_that.requestId,_that.failureReason,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String transferId,  String accountId,  TransferType type,  TransferStatus status,  Decimal amount,  String currency,  BankChannel channel,  String bankAccountId,  String requestId,  String failureReason,  DateTime createdAt,  DateTime updatedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _FundTransfer() when $default != null:
return $default(_that.transferId,_that.accountId,_that.type,_that.status,_that.amount,_that.currency,_that.channel,_that.bankAccountId,_that.requestId,_that.failureReason,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _FundTransfer implements FundTransfer {
  const _FundTransfer({required this.transferId, required this.accountId, required this.type, required this.status, required this.amount, required this.currency, required this.channel, required this.bankAccountId, required this.requestId, this.failureReason = '', required this.createdAt, required this.updatedAt, this.completedAt});
  

@override final  String transferId;
@override final  String accountId;
@override final  TransferType type;
@override final  TransferStatus status;
@override final  Decimal amount;
@override final  String currency;
@override final  BankChannel channel;
@override final  String bankAccountId;
/// Idempotency key echoed back by server
@override final  String requestId;
@override@JsonKey() final  String failureReason;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? completedAt;

/// Create a copy of FundTransfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundTransferCopyWith<_FundTransfer> get copyWith => __$FundTransferCopyWithImpl<_FundTransfer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundTransfer&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,transferId,accountId,type,status,amount,currency,channel,bankAccountId,requestId,failureReason,createdAt,updatedAt,completedAt);

@override
String toString() {
  return 'FundTransfer(transferId: $transferId, accountId: $accountId, type: $type, status: $status, amount: $amount, currency: $currency, channel: $channel, bankAccountId: $bankAccountId, requestId: $requestId, failureReason: $failureReason, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$FundTransferCopyWith<$Res> implements $FundTransferCopyWith<$Res> {
  factory _$FundTransferCopyWith(_FundTransfer value, $Res Function(_FundTransfer) _then) = __$FundTransferCopyWithImpl;
@override @useResult
$Res call({
 String transferId, String accountId, TransferType type, TransferStatus status, Decimal amount, String currency, BankChannel channel, String bankAccountId, String requestId, String failureReason, DateTime createdAt, DateTime updatedAt, DateTime? completedAt
});




}
/// @nodoc
class __$FundTransferCopyWithImpl<$Res>
    implements _$FundTransferCopyWith<$Res> {
  __$FundTransferCopyWithImpl(this._self, this._then);

  final _FundTransfer _self;
  final $Res Function(_FundTransfer) _then;

/// Create a copy of FundTransfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transferId = null,Object? accountId = null,Object? type = null,Object? status = null,Object? amount = null,Object? currency = null,Object? channel = null,Object? bankAccountId = null,Object? requestId = null,Object? failureReason = null,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,}) {
  return _then(_FundTransfer(
transferId: null == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransferType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as BankChannel,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,failureReason: null == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
