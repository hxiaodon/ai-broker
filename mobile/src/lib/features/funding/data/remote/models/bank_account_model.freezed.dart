// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BankAccountModel {

@JsonKey(name: 'bank_account_id') String get id;@JsonKey(name: 'account_name') String get accountName;/// Server returns last-4-digit masked value (e.g. "****1234")
@JsonKey(name: 'account_number') String get accountNumberMasked;@JsonKey(name: 'routing_number') String get routingNumber;@JsonKey(name: 'bank_name') String get bankName;@JsonKey(name: 'currency') String get currency;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'cooldown_ends_at') String? get cooldownEndsAt;@JsonKey(name: 'micro_deposit_status') String get microDepositStatus;@JsonKey(name: 'remaining_verify_attempts') int get remainingVerifyAttempts;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of BankAccountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankAccountModelCopyWith<BankAccountModel> get copyWith => _$BankAccountModelCopyWithImpl<BankAccountModel>(this as BankAccountModel, _$identity);

  /// Serializes this BankAccountModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankAccountModel&&(identical(other.id, id) || other.id == id)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.accountNumberMasked, accountNumberMasked) || other.accountNumberMasked == accountNumberMasked)&&(identical(other.routingNumber, routingNumber) || other.routingNumber == routingNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt)&&(identical(other.microDepositStatus, microDepositStatus) || other.microDepositStatus == microDepositStatus)&&(identical(other.remainingVerifyAttempts, remainingVerifyAttempts) || other.remainingVerifyAttempts == remainingVerifyAttempts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountName,accountNumberMasked,routingNumber,bankName,currency,isVerified,cooldownEndsAt,microDepositStatus,remainingVerifyAttempts,createdAt);

@override
String toString() {
  return 'BankAccountModel(id: $id, accountName: $accountName, accountNumberMasked: $accountNumberMasked, routingNumber: $routingNumber, bankName: $bankName, currency: $currency, isVerified: $isVerified, cooldownEndsAt: $cooldownEndsAt, microDepositStatus: $microDepositStatus, remainingVerifyAttempts: $remainingVerifyAttempts, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BankAccountModelCopyWith<$Res>  {
  factory $BankAccountModelCopyWith(BankAccountModel value, $Res Function(BankAccountModel) _then) = _$BankAccountModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'bank_account_id') String id,@JsonKey(name: 'account_name') String accountName,@JsonKey(name: 'account_number') String accountNumberMasked,@JsonKey(name: 'routing_number') String routingNumber,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'currency') String currency,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'cooldown_ends_at') String? cooldownEndsAt,@JsonKey(name: 'micro_deposit_status') String microDepositStatus,@JsonKey(name: 'remaining_verify_attempts') int remainingVerifyAttempts,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$BankAccountModelCopyWithImpl<$Res>
    implements $BankAccountModelCopyWith<$Res> {
  _$BankAccountModelCopyWithImpl(this._self, this._then);

  final BankAccountModel _self;
  final $Res Function(BankAccountModel) _then;

/// Create a copy of BankAccountModel
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
as String?,microDepositStatus: null == microDepositStatus ? _self.microDepositStatus : microDepositStatus // ignore: cast_nullable_to_non_nullable
as String,remainingVerifyAttempts: null == remainingVerifyAttempts ? _self.remainingVerifyAttempts : remainingVerifyAttempts // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BankAccountModel].
extension BankAccountModelPatterns on BankAccountModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BankAccountModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BankAccountModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BankAccountModel value)  $default,){
final _that = this;
switch (_that) {
case _BankAccountModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BankAccountModel value)?  $default,){
final _that = this;
switch (_that) {
case _BankAccountModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'bank_account_id')  String id, @JsonKey(name: 'account_name')  String accountName, @JsonKey(name: 'account_number')  String accountNumberMasked, @JsonKey(name: 'routing_number')  String routingNumber, @JsonKey(name: 'bank_name')  String bankName, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'cooldown_ends_at')  String? cooldownEndsAt, @JsonKey(name: 'micro_deposit_status')  String microDepositStatus, @JsonKey(name: 'remaining_verify_attempts')  int remainingVerifyAttempts, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BankAccountModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'bank_account_id')  String id, @JsonKey(name: 'account_name')  String accountName, @JsonKey(name: 'account_number')  String accountNumberMasked, @JsonKey(name: 'routing_number')  String routingNumber, @JsonKey(name: 'bank_name')  String bankName, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'cooldown_ends_at')  String? cooldownEndsAt, @JsonKey(name: 'micro_deposit_status')  String microDepositStatus, @JsonKey(name: 'remaining_verify_attempts')  int remainingVerifyAttempts, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _BankAccountModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'bank_account_id')  String id, @JsonKey(name: 'account_name')  String accountName, @JsonKey(name: 'account_number')  String accountNumberMasked, @JsonKey(name: 'routing_number')  String routingNumber, @JsonKey(name: 'bank_name')  String bankName, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'cooldown_ends_at')  String? cooldownEndsAt, @JsonKey(name: 'micro_deposit_status')  String microDepositStatus, @JsonKey(name: 'remaining_verify_attempts')  int remainingVerifyAttempts, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BankAccountModel() when $default != null:
return $default(_that.id,_that.accountName,_that.accountNumberMasked,_that.routingNumber,_that.bankName,_that.currency,_that.isVerified,_that.cooldownEndsAt,_that.microDepositStatus,_that.remainingVerifyAttempts,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BankAccountModel implements BankAccountModel {
  const _BankAccountModel({@JsonKey(name: 'bank_account_id') required this.id, @JsonKey(name: 'account_name') required this.accountName, @JsonKey(name: 'account_number') required this.accountNumberMasked, @JsonKey(name: 'routing_number') this.routingNumber = '', @JsonKey(name: 'bank_name') required this.bankName, @JsonKey(name: 'currency') this.currency = 'USD', @JsonKey(name: 'is_verified') this.isVerified = false, @JsonKey(name: 'cooldown_ends_at') this.cooldownEndsAt, @JsonKey(name: 'micro_deposit_status') this.microDepositStatus = 'pending', @JsonKey(name: 'remaining_verify_attempts') this.remainingVerifyAttempts = 5, @JsonKey(name: 'created_at') required this.createdAt});
  factory _BankAccountModel.fromJson(Map<String, dynamic> json) => _$BankAccountModelFromJson(json);

@override@JsonKey(name: 'bank_account_id') final  String id;
@override@JsonKey(name: 'account_name') final  String accountName;
/// Server returns last-4-digit masked value (e.g. "****1234")
@override@JsonKey(name: 'account_number') final  String accountNumberMasked;
@override@JsonKey(name: 'routing_number') final  String routingNumber;
@override@JsonKey(name: 'bank_name') final  String bankName;
@override@JsonKey(name: 'currency') final  String currency;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'cooldown_ends_at') final  String? cooldownEndsAt;
@override@JsonKey(name: 'micro_deposit_status') final  String microDepositStatus;
@override@JsonKey(name: 'remaining_verify_attempts') final  int remainingVerifyAttempts;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of BankAccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankAccountModelCopyWith<_BankAccountModel> get copyWith => __$BankAccountModelCopyWithImpl<_BankAccountModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BankAccountModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankAccountModel&&(identical(other.id, id) || other.id == id)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.accountNumberMasked, accountNumberMasked) || other.accountNumberMasked == accountNumberMasked)&&(identical(other.routingNumber, routingNumber) || other.routingNumber == routingNumber)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt)&&(identical(other.microDepositStatus, microDepositStatus) || other.microDepositStatus == microDepositStatus)&&(identical(other.remainingVerifyAttempts, remainingVerifyAttempts) || other.remainingVerifyAttempts == remainingVerifyAttempts)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountName,accountNumberMasked,routingNumber,bankName,currency,isVerified,cooldownEndsAt,microDepositStatus,remainingVerifyAttempts,createdAt);

@override
String toString() {
  return 'BankAccountModel(id: $id, accountName: $accountName, accountNumberMasked: $accountNumberMasked, routingNumber: $routingNumber, bankName: $bankName, currency: $currency, isVerified: $isVerified, cooldownEndsAt: $cooldownEndsAt, microDepositStatus: $microDepositStatus, remainingVerifyAttempts: $remainingVerifyAttempts, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BankAccountModelCopyWith<$Res> implements $BankAccountModelCopyWith<$Res> {
  factory _$BankAccountModelCopyWith(_BankAccountModel value, $Res Function(_BankAccountModel) _then) = __$BankAccountModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'bank_account_id') String id,@JsonKey(name: 'account_name') String accountName,@JsonKey(name: 'account_number') String accountNumberMasked,@JsonKey(name: 'routing_number') String routingNumber,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'currency') String currency,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'cooldown_ends_at') String? cooldownEndsAt,@JsonKey(name: 'micro_deposit_status') String microDepositStatus,@JsonKey(name: 'remaining_verify_attempts') int remainingVerifyAttempts,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$BankAccountModelCopyWithImpl<$Res>
    implements _$BankAccountModelCopyWith<$Res> {
  __$BankAccountModelCopyWithImpl(this._self, this._then);

  final _BankAccountModel _self;
  final $Res Function(_BankAccountModel) _then;

/// Create a copy of BankAccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountName = null,Object? accountNumberMasked = null,Object? routingNumber = null,Object? bankName = null,Object? currency = null,Object? isVerified = null,Object? cooldownEndsAt = freezed,Object? microDepositStatus = null,Object? remainingVerifyAttempts = null,Object? createdAt = null,}) {
  return _then(_BankAccountModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,accountNumberMasked: null == accountNumberMasked ? _self.accountNumberMasked : accountNumberMasked // ignore: cast_nullable_to_non_nullable
as String,routingNumber: null == routingNumber ? _self.routingNumber : routingNumber // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,cooldownEndsAt: freezed == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as String?,microDepositStatus: null == microDepositStatus ? _self.microDepositStatus : microDepositStatus // ignore: cast_nullable_to_non_nullable
as String,remainingVerifyAttempts: null == remainingVerifyAttempts ? _self.remainingVerifyAttempts : remainingVerifyAttempts // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
