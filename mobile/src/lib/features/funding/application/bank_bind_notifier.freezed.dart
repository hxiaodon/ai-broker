// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_bind_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BankBindState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankBindState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BankBindState()';
}


}

/// @nodoc
class $BankBindStateCopyWith<$Res>  {
$BankBindStateCopyWith(BankBindState _, $Res Function(BankBindState) __);
}


/// Adds pattern-matching-related methods to [BankBindState].
extension BankBindStatePatterns on BankBindState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Submitting value)?  submitting,TResult Function( _PendingMicroDeposit value)?  pendingMicroDeposit,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Submitting() when submitting != null:
return submitting(_that);case _PendingMicroDeposit() when pendingMicroDeposit != null:
return pendingMicroDeposit(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Submitting value)  submitting,required TResult Function( _PendingMicroDeposit value)  pendingMicroDeposit,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Submitting():
return submitting(_that);case _PendingMicroDeposit():
return pendingMicroDeposit(_that);case _Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Submitting value)?  submitting,TResult? Function( _PendingMicroDeposit value)?  pendingMicroDeposit,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Submitting() when submitting != null:
return submitting(_that);case _PendingMicroDeposit() when pendingMicroDeposit != null:
return pendingMicroDeposit(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  submitting,TResult Function( String bankAccountId,  DateTime cooldownEndsAt)?  pendingMicroDeposit,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Submitting() when submitting != null:
return submitting();case _PendingMicroDeposit() when pendingMicroDeposit != null:
return pendingMicroDeposit(_that.bankAccountId,_that.cooldownEndsAt);case _Error() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  submitting,required TResult Function( String bankAccountId,  DateTime cooldownEndsAt)  pendingMicroDeposit,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Submitting():
return submitting();case _PendingMicroDeposit():
return pendingMicroDeposit(_that.bankAccountId,_that.cooldownEndsAt);case _Error():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  submitting,TResult? Function( String bankAccountId,  DateTime cooldownEndsAt)?  pendingMicroDeposit,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Submitting() when submitting != null:
return submitting();case _PendingMicroDeposit() when pendingMicroDeposit != null:
return pendingMicroDeposit(_that.bankAccountId,_that.cooldownEndsAt);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements BankBindState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BankBindState.idle()';
}


}




/// @nodoc


class _Submitting implements BankBindState {
  const _Submitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Submitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BankBindState.submitting()';
}


}




/// @nodoc


class _PendingMicroDeposit implements BankBindState {
  const _PendingMicroDeposit({required this.bankAccountId, required this.cooldownEndsAt});
  

 final  String bankAccountId;
/// ISO 8601 UTC — displayed as "激活时间" in the UI
 final  DateTime cooldownEndsAt;

/// Create a copy of BankBindState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingMicroDepositCopyWith<_PendingMicroDeposit> get copyWith => __$PendingMicroDepositCopyWithImpl<_PendingMicroDeposit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingMicroDeposit&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.cooldownEndsAt, cooldownEndsAt) || other.cooldownEndsAt == cooldownEndsAt));
}


@override
int get hashCode => Object.hash(runtimeType,bankAccountId,cooldownEndsAt);

@override
String toString() {
  return 'BankBindState.pendingMicroDeposit(bankAccountId: $bankAccountId, cooldownEndsAt: $cooldownEndsAt)';
}


}

/// @nodoc
abstract mixin class _$PendingMicroDepositCopyWith<$Res> implements $BankBindStateCopyWith<$Res> {
  factory _$PendingMicroDepositCopyWith(_PendingMicroDeposit value, $Res Function(_PendingMicroDeposit) _then) = __$PendingMicroDepositCopyWithImpl;
@useResult
$Res call({
 String bankAccountId, DateTime cooldownEndsAt
});




}
/// @nodoc
class __$PendingMicroDepositCopyWithImpl<$Res>
    implements _$PendingMicroDepositCopyWith<$Res> {
  __$PendingMicroDepositCopyWithImpl(this._self, this._then);

  final _PendingMicroDeposit _self;
  final $Res Function(_PendingMicroDeposit) _then;

/// Create a copy of BankBindState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bankAccountId = null,Object? cooldownEndsAt = null,}) {
  return _then(_PendingMicroDeposit(
bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,cooldownEndsAt: null == cooldownEndsAt ? _self.cooldownEndsAt : cooldownEndsAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class _Error implements BankBindState {
  const _Error({required this.message});
  

 final  String message;

/// Create a copy of BankBindState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'BankBindState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $BankBindStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of BankBindState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
