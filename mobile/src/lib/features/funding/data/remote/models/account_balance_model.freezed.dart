// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_balance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountBalanceModel {

@JsonKey(name: 'account_id') String get accountId;@JsonKey(name: 'currency') String get currency;@JsonKey(name: 'total_balance') String get totalBalance;@JsonKey(name: 'available_balance') String get availableBalance;@JsonKey(name: 'unsettled_amount') String get unsettledAmount;@JsonKey(name: 'withdrawable_balance') String get withdrawableBalance;@JsonKey(name: 'updated_at') String get updatedAt;
/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountBalanceModelCopyWith<AccountBalanceModel> get copyWith => _$AccountBalanceModelCopyWithImpl<AccountBalanceModel>(this as AccountBalanceModel, _$identity);

  /// Serializes this AccountBalanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountBalanceModel&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.unsettledAmount, unsettledAmount) || other.unsettledAmount == unsettledAmount)&&(identical(other.withdrawableBalance, withdrawableBalance) || other.withdrawableBalance == withdrawableBalance)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,currency,totalBalance,availableBalance,unsettledAmount,withdrawableBalance,updatedAt);

@override
String toString() {
  return 'AccountBalanceModel(accountId: $accountId, currency: $currency, totalBalance: $totalBalance, availableBalance: $availableBalance, unsettledAmount: $unsettledAmount, withdrawableBalance: $withdrawableBalance, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountBalanceModelCopyWith<$Res>  {
  factory $AccountBalanceModelCopyWith(AccountBalanceModel value, $Res Function(AccountBalanceModel) _then) = _$AccountBalanceModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'currency') String currency,@JsonKey(name: 'total_balance') String totalBalance,@JsonKey(name: 'available_balance') String availableBalance,@JsonKey(name: 'unsettled_amount') String unsettledAmount,@JsonKey(name: 'withdrawable_balance') String withdrawableBalance,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class _$AccountBalanceModelCopyWithImpl<$Res>
    implements $AccountBalanceModelCopyWith<$Res> {
  _$AccountBalanceModelCopyWithImpl(this._self, this._then);

  final AccountBalanceModel _self;
  final $Res Function(AccountBalanceModel) _then;

/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? currency = null,Object? totalBalance = null,Object? availableBalance = null,Object? unsettledAmount = null,Object? withdrawableBalance = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as String,availableBalance: null == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as String,unsettledAmount: null == unsettledAmount ? _self.unsettledAmount : unsettledAmount // ignore: cast_nullable_to_non_nullable
as String,withdrawableBalance: null == withdrawableBalance ? _self.withdrawableBalance : withdrawableBalance // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountBalanceModel].
extension AccountBalanceModelPatterns on AccountBalanceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountBalanceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountBalanceModel value)  $default,){
final _that = this;
switch (_that) {
case _AccountBalanceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountBalanceModel value)?  $default,){
final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'total_balance')  String totalBalance, @JsonKey(name: 'available_balance')  String availableBalance, @JsonKey(name: 'unsettled_amount')  String unsettledAmount, @JsonKey(name: 'withdrawable_balance')  String withdrawableBalance, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'total_balance')  String totalBalance, @JsonKey(name: 'available_balance')  String availableBalance, @JsonKey(name: 'unsettled_amount')  String unsettledAmount, @JsonKey(name: 'withdrawable_balance')  String withdrawableBalance, @JsonKey(name: 'updated_at')  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountBalanceModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'currency')  String currency, @JsonKey(name: 'total_balance')  String totalBalance, @JsonKey(name: 'available_balance')  String availableBalance, @JsonKey(name: 'unsettled_amount')  String unsettledAmount, @JsonKey(name: 'withdrawable_balance')  String withdrawableBalance, @JsonKey(name: 'updated_at')  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountBalanceModel() when $default != null:
return $default(_that.accountId,_that.currency,_that.totalBalance,_that.availableBalance,_that.unsettledAmount,_that.withdrawableBalance,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountBalanceModel implements AccountBalanceModel {
  const _AccountBalanceModel({@JsonKey(name: 'account_id') required this.accountId, @JsonKey(name: 'currency') this.currency = 'USD', @JsonKey(name: 'total_balance') required this.totalBalance, @JsonKey(name: 'available_balance') required this.availableBalance, @JsonKey(name: 'unsettled_amount') this.unsettledAmount = '0', @JsonKey(name: 'withdrawable_balance') required this.withdrawableBalance, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _AccountBalanceModel.fromJson(Map<String, dynamic> json) => _$AccountBalanceModelFromJson(json);

@override@JsonKey(name: 'account_id') final  String accountId;
@override@JsonKey(name: 'currency') final  String currency;
@override@JsonKey(name: 'total_balance') final  String totalBalance;
@override@JsonKey(name: 'available_balance') final  String availableBalance;
@override@JsonKey(name: 'unsettled_amount') final  String unsettledAmount;
@override@JsonKey(name: 'withdrawable_balance') final  String withdrawableBalance;
@override@JsonKey(name: 'updated_at') final  String updatedAt;

/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountBalanceModelCopyWith<_AccountBalanceModel> get copyWith => __$AccountBalanceModelCopyWithImpl<_AccountBalanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountBalanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountBalanceModel&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalBalance, totalBalance) || other.totalBalance == totalBalance)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.unsettledAmount, unsettledAmount) || other.unsettledAmount == unsettledAmount)&&(identical(other.withdrawableBalance, withdrawableBalance) || other.withdrawableBalance == withdrawableBalance)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,currency,totalBalance,availableBalance,unsettledAmount,withdrawableBalance,updatedAt);

@override
String toString() {
  return 'AccountBalanceModel(accountId: $accountId, currency: $currency, totalBalance: $totalBalance, availableBalance: $availableBalance, unsettledAmount: $unsettledAmount, withdrawableBalance: $withdrawableBalance, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountBalanceModelCopyWith<$Res> implements $AccountBalanceModelCopyWith<$Res> {
  factory _$AccountBalanceModelCopyWith(_AccountBalanceModel value, $Res Function(_AccountBalanceModel) _then) = __$AccountBalanceModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'currency') String currency,@JsonKey(name: 'total_balance') String totalBalance,@JsonKey(name: 'available_balance') String availableBalance,@JsonKey(name: 'unsettled_amount') String unsettledAmount,@JsonKey(name: 'withdrawable_balance') String withdrawableBalance,@JsonKey(name: 'updated_at') String updatedAt
});




}
/// @nodoc
class __$AccountBalanceModelCopyWithImpl<$Res>
    implements _$AccountBalanceModelCopyWith<$Res> {
  __$AccountBalanceModelCopyWithImpl(this._self, this._then);

  final _AccountBalanceModel _self;
  final $Res Function(_AccountBalanceModel) _then;

/// Create a copy of AccountBalanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? currency = null,Object? totalBalance = null,Object? availableBalance = null,Object? unsettledAmount = null,Object? withdrawableBalance = null,Object? updatedAt = null,}) {
  return _then(_AccountBalanceModel(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalBalance: null == totalBalance ? _self.totalBalance : totalBalance // ignore: cast_nullable_to_non_nullable
as String,availableBalance: null == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as String,unsettledAmount: null == unsettledAmount ? _self.unsettledAmount : unsettledAmount // ignore: cast_nullable_to_non_nullable
as String,withdrawableBalance: null == withdrawableBalance ? _self.withdrawableBalance : withdrawableBalance // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
