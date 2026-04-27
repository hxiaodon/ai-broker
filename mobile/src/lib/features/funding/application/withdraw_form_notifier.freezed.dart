// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdraw_form_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WithdrawFormState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawFormState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WithdrawFormState()';
}


}

/// @nodoc
class $WithdrawFormStateCopyWith<$Res>  {
$WithdrawFormStateCopyWith(WithdrawFormState _, $Res Function(WithdrawFormState) __);
}


/// Adds pattern-matching-related methods to [WithdrawFormState].
extension WithdrawFormStatePatterns on WithdrawFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Confirming value)?  confirming,TResult Function( _AwaitingBiometric value)?  awaitingBiometric,TResult Function( _Submitting value)?  submitting,TResult Function( _Success value)?  success,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Confirming() when confirming != null:
return confirming(_that);case _AwaitingBiometric() when awaitingBiometric != null:
return awaitingBiometric(_that);case _Submitting() when submitting != null:
return submitting(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Confirming value)  confirming,required TResult Function( _AwaitingBiometric value)  awaitingBiometric,required TResult Function( _Submitting value)  submitting,required TResult Function( _Success value)  success,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Confirming():
return confirming(_that);case _AwaitingBiometric():
return awaitingBiometric(_that);case _Submitting():
return submitting(_that);case _Success():
return success(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Confirming value)?  confirming,TResult? Function( _AwaitingBiometric value)?  awaitingBiometric,TResult? Function( _Submitting value)?  submitting,TResult? Function( _Success value)?  success,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Confirming() when confirming != null:
return confirming(_that);case _AwaitingBiometric() when awaitingBiometric != null:
return awaitingBiometric(_that);case _Submitting() when submitting != null:
return submitting(_that);case _Success() when success != null:
return success(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( Decimal amount,  String bankAccountId,  String channel)?  confirming,TResult Function()?  awaitingBiometric,TResult Function()?  submitting,TResult Function( String transferId)?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Confirming() when confirming != null:
return confirming(_that.amount,_that.bankAccountId,_that.channel);case _AwaitingBiometric() when awaitingBiometric != null:
return awaitingBiometric();case _Submitting() when submitting != null:
return submitting();case _Success() when success != null:
return success(_that.transferId);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( Decimal amount,  String bankAccountId,  String channel)  confirming,required TResult Function()  awaitingBiometric,required TResult Function()  submitting,required TResult Function( String transferId)  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Confirming():
return confirming(_that.amount,_that.bankAccountId,_that.channel);case _AwaitingBiometric():
return awaitingBiometric();case _Submitting():
return submitting();case _Success():
return success(_that.transferId);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( Decimal amount,  String bankAccountId,  String channel)?  confirming,TResult? Function()?  awaitingBiometric,TResult? Function()?  submitting,TResult? Function( String transferId)?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Confirming() when confirming != null:
return confirming(_that.amount,_that.bankAccountId,_that.channel);case _AwaitingBiometric() when awaitingBiometric != null:
return awaitingBiometric();case _Submitting() when submitting != null:
return submitting();case _Success() when success != null:
return success(_that.transferId);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements WithdrawFormState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WithdrawFormState.idle()';
}


}




/// @nodoc


class _Confirming implements WithdrawFormState {
  const _Confirming({required this.amount, required this.bankAccountId, required this.channel});
  

 final  Decimal amount;
 final  String bankAccountId;
 final  String channel;

/// Create a copy of WithdrawFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmingCopyWith<_Confirming> get copyWith => __$ConfirmingCopyWithImpl<_Confirming>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Confirming&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.channel, channel) || other.channel == channel));
}


@override
int get hashCode => Object.hash(runtimeType,amount,bankAccountId,channel);

@override
String toString() {
  return 'WithdrawFormState.confirming(amount: $amount, bankAccountId: $bankAccountId, channel: $channel)';
}


}

/// @nodoc
abstract mixin class _$ConfirmingCopyWith<$Res> implements $WithdrawFormStateCopyWith<$Res> {
  factory _$ConfirmingCopyWith(_Confirming value, $Res Function(_Confirming) _then) = __$ConfirmingCopyWithImpl;
@useResult
$Res call({
 Decimal amount, String bankAccountId, String channel
});




}
/// @nodoc
class __$ConfirmingCopyWithImpl<$Res>
    implements _$ConfirmingCopyWith<$Res> {
  __$ConfirmingCopyWithImpl(this._self, this._then);

  final _Confirming _self;
  final $Res Function(_Confirming) _then;

/// Create a copy of WithdrawFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? bankAccountId = null,Object? channel = null,}) {
  return _then(_Confirming(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AwaitingBiometric implements WithdrawFormState {
  const _AwaitingBiometric();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AwaitingBiometric);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WithdrawFormState.awaitingBiometric()';
}


}




/// @nodoc


class _Submitting implements WithdrawFormState {
  const _Submitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Submitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WithdrawFormState.submitting()';
}


}




/// @nodoc


class _Success implements WithdrawFormState {
  const _Success({required this.transferId});
  

 final  String transferId;

/// Create a copy of WithdrawFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SuccessCopyWith<_Success> get copyWith => __$SuccessCopyWithImpl<_Success>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success&&(identical(other.transferId, transferId) || other.transferId == transferId));
}


@override
int get hashCode => Object.hash(runtimeType,transferId);

@override
String toString() {
  return 'WithdrawFormState.success(transferId: $transferId)';
}


}

/// @nodoc
abstract mixin class _$SuccessCopyWith<$Res> implements $WithdrawFormStateCopyWith<$Res> {
  factory _$SuccessCopyWith(_Success value, $Res Function(_Success) _then) = __$SuccessCopyWithImpl;
@useResult
$Res call({
 String transferId
});




}
/// @nodoc
class __$SuccessCopyWithImpl<$Res>
    implements _$SuccessCopyWith<$Res> {
  __$SuccessCopyWithImpl(this._self, this._then);

  final _Success _self;
  final $Res Function(_Success) _then;

/// Create a copy of WithdrawFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? transferId = null,}) {
  return _then(_Success(
transferId: null == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Error implements WithdrawFormState {
  const _Error({required this.message});
  

 final  String message;

/// Create a copy of WithdrawFormState
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
  return 'WithdrawFormState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $WithdrawFormStateCopyWith<$Res> {
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

/// Create a copy of WithdrawFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
