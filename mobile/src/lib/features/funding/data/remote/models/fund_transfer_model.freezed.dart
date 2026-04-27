// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_transfer_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundTransferModel {

@JsonKey(name: 'transfer_id') String get transferId;@JsonKey(name: 'account_id') String get accountId;@JsonKey(name: 'type') String get type;@JsonKey(name: 'status') String get status;@JsonKey(name: 'amount') String get amount;@JsonKey(name: 'currency') String get currency;@JsonKey(name: 'channel') String get channel;@JsonKey(name: 'bank_account_id') String get bankAccountId;@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'failure_reason') String get failureReason;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'updated_at') String get updatedAt;@JsonKey(name: 'completed_at') String? get completedAt;
/// Create a copy of FundTransferModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundTransferModelCopyWith<FundTransferModel> get copyWith => _$FundTransferModelCopyWithImpl<FundTransferModel>(this as FundTransferModel, _$identity);

  /// Serializes this FundTransferModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundTransferModel&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,transferId,accountId,type,status,amount,currency,channel,bankAccountId,requestId,failureReason,createdAt,updatedAt,completedAt);

@override
String toString() {
  return 'FundTransferModel(transferId: $transferId, accountId: $accountId, type: $type, status: $status, amount: $amount, currency: $currency, channel: $channel, bankAccountId: $bankAccountId, requestId: $requestId, failureReason: $failureReason, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $FundTransferModelCopyWith<$Res>  {
  factory $FundTransferModelCopyWith(FundTransferModel value, $Res Function(FundTransferModel) _then) = _$FundTransferModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'transfer_id') String transferId,@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'type') String type,@JsonKey(name: 'status') String status,@JsonKey(name: 'amount') String amount,@JsonKey(name: 'currency') String currency,@JsonKey(name: 'channel') String channel,@JsonKey(name: 'bank_account_id') String bankAccountId,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'failure_reason') String failureReason,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class _$FundTransferModelCopyWithImpl<$Res>
    implements $FundTransferModelCopyWith<$Res> {
  _$FundTransferModelCopyWithImpl(this._self, this._then);

  final FundTransferModel _self;
  final $Res Function(FundTransferModel) _then;

/// Create a copy of FundTransferModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transferId = null,Object? accountId = null,Object? type = null,Object? status = null,Object? amount = null,Object? currency = null,Object? channel = null,Object? bankAccountId = null,Object? requestId = null,Object? failureReason = null,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
transferId: null == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,failureReason: null == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FundTransferModel].
extension FundTransferModelPatterns on FundTransferModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundTransferModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundTransferModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundTransferModel value)  $default,){
final _that = this;
switch (_that) {
case _FundTransferModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundTransferModel value)?  $default,){
final _that = this;
switch (_that) {
case _FundTransferModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'transfer_id')  String transferId, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'type')  String type, @JsonKey(name: 'status')  String status, @JsonKey(name: 'amount')  String amount, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'channel')  String channel, @JsonKey(name: 'bank_account_id')  String bankAccountId, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'failure_reason')  String failureReason, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundTransferModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'transfer_id')  String transferId, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'type')  String type, @JsonKey(name: 'status')  String status, @JsonKey(name: 'amount')  String amount, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'channel')  String channel, @JsonKey(name: 'bank_account_id')  String bankAccountId, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'failure_reason')  String failureReason, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'completed_at')  String? completedAt)  $default,) {final _that = this;
switch (_that) {
case _FundTransferModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'transfer_id')  String transferId, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'type')  String type, @JsonKey(name: 'status')  String status, @JsonKey(name: 'amount')  String amount, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'channel')  String channel, @JsonKey(name: 'bank_account_id')  String bankAccountId, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'failure_reason')  String failureReason, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'updated_at')  String updatedAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _FundTransferModel() when $default != null:
return $default(_that.transferId,_that.accountId,_that.type,_that.status,_that.amount,_that.currency,_that.channel,_that.bankAccountId,_that.requestId,_that.failureReason,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundTransferModel implements FundTransferModel {
  const _FundTransferModel({@JsonKey(name: 'transfer_id') required this.transferId, @JsonKey(name: 'account_id') required this.accountId, @JsonKey(name: 'type') required this.type, @JsonKey(name: 'status') required this.status, @JsonKey(name: 'amount') required this.amount, @JsonKey(name: 'currency') this.currency = 'USD', @JsonKey(name: 'channel') required this.channel, @JsonKey(name: 'bank_account_id') required this.bankAccountId, @JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'failure_reason') this.failureReason = '', @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'completed_at') this.completedAt});
  factory _FundTransferModel.fromJson(Map<String, dynamic> json) => _$FundTransferModelFromJson(json);

@override@JsonKey(name: 'transfer_id') final  String transferId;
@override@JsonKey(name: 'account_id') final  String accountId;
@override@JsonKey(name: 'type') final  String type;
@override@JsonKey(name: 'status') final  String status;
@override@JsonKey(name: 'amount') final  String amount;
@override@JsonKey(name: 'currency') final  String currency;
@override@JsonKey(name: 'channel') final  String channel;
@override@JsonKey(name: 'bank_account_id') final  String bankAccountId;
@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'failure_reason') final  String failureReason;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'updated_at') final  String updatedAt;
@override@JsonKey(name: 'completed_at') final  String? completedAt;

/// Create a copy of FundTransferModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundTransferModelCopyWith<_FundTransferModel> get copyWith => __$FundTransferModelCopyWithImpl<_FundTransferModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundTransferModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundTransferModel&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,transferId,accountId,type,status,amount,currency,channel,bankAccountId,requestId,failureReason,createdAt,updatedAt,completedAt);

@override
String toString() {
  return 'FundTransferModel(transferId: $transferId, accountId: $accountId, type: $type, status: $status, amount: $amount, currency: $currency, channel: $channel, bankAccountId: $bankAccountId, requestId: $requestId, failureReason: $failureReason, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$FundTransferModelCopyWith<$Res> implements $FundTransferModelCopyWith<$Res> {
  factory _$FundTransferModelCopyWith(_FundTransferModel value, $Res Function(_FundTransferModel) _then) = __$FundTransferModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'transfer_id') String transferId,@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'type') String type,@JsonKey(name: 'status') String status,@JsonKey(name: 'amount') String amount,@JsonKey(name: 'currency') String currency,@JsonKey(name: 'channel') String channel,@JsonKey(name: 'bank_account_id') String bankAccountId,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'failure_reason') String failureReason,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'updated_at') String updatedAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class __$FundTransferModelCopyWithImpl<$Res>
    implements _$FundTransferModelCopyWith<$Res> {
  __$FundTransferModelCopyWithImpl(this._self, this._then);

  final _FundTransferModel _self;
  final $Res Function(_FundTransferModel) _then;

/// Create a copy of FundTransferModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transferId = null,Object? accountId = null,Object? type = null,Object? status = null,Object? amount = null,Object? currency = null,Object? channel = null,Object? bankAccountId = null,Object? requestId = null,Object? failureReason = null,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,}) {
  return _then(_FundTransferModel(
transferId: null == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,failureReason: null == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
