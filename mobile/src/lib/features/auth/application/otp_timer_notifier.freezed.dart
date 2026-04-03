// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_timer_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtpTimerState {

/// Countdown seconds before resend is allowed (0 = resend available)
 int get resendCountdownSeconds;/// OTP validity countdown (300 = 5 minutes)
 int get expiryCountdownSeconds;/// Number of incorrect OTP attempts on current request
 int get errorCount;/// True when account is locked out (errorCount >= 5)
 bool get isLockedOut;/// Remaining lockout seconds (PRD: 30 min)
 int get lockoutRemainingSeconds;/// Timestamp of lockout start (used to compute remaining)
 DateTime? get lockoutUntil;
/// Create a copy of OtpTimerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpTimerStateCopyWith<OtpTimerState> get copyWith => _$OtpTimerStateCopyWithImpl<OtpTimerState>(this as OtpTimerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpTimerState&&(identical(other.resendCountdownSeconds, resendCountdownSeconds) || other.resendCountdownSeconds == resendCountdownSeconds)&&(identical(other.expiryCountdownSeconds, expiryCountdownSeconds) || other.expiryCountdownSeconds == expiryCountdownSeconds)&&(identical(other.errorCount, errorCount) || other.errorCount == errorCount)&&(identical(other.isLockedOut, isLockedOut) || other.isLockedOut == isLockedOut)&&(identical(other.lockoutRemainingSeconds, lockoutRemainingSeconds) || other.lockoutRemainingSeconds == lockoutRemainingSeconds)&&(identical(other.lockoutUntil, lockoutUntil) || other.lockoutUntil == lockoutUntil));
}


@override
int get hashCode => Object.hash(runtimeType,resendCountdownSeconds,expiryCountdownSeconds,errorCount,isLockedOut,lockoutRemainingSeconds,lockoutUntil);

@override
String toString() {
  return 'OtpTimerState(resendCountdownSeconds: $resendCountdownSeconds, expiryCountdownSeconds: $expiryCountdownSeconds, errorCount: $errorCount, isLockedOut: $isLockedOut, lockoutRemainingSeconds: $lockoutRemainingSeconds, lockoutUntil: $lockoutUntil)';
}


}

/// @nodoc
abstract mixin class $OtpTimerStateCopyWith<$Res>  {
  factory $OtpTimerStateCopyWith(OtpTimerState value, $Res Function(OtpTimerState) _then) = _$OtpTimerStateCopyWithImpl;
@useResult
$Res call({
 int resendCountdownSeconds, int expiryCountdownSeconds, int errorCount, bool isLockedOut, int lockoutRemainingSeconds, DateTime? lockoutUntil
});




}
/// @nodoc
class _$OtpTimerStateCopyWithImpl<$Res>
    implements $OtpTimerStateCopyWith<$Res> {
  _$OtpTimerStateCopyWithImpl(this._self, this._then);

  final OtpTimerState _self;
  final $Res Function(OtpTimerState) _then;

/// Create a copy of OtpTimerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resendCountdownSeconds = null,Object? expiryCountdownSeconds = null,Object? errorCount = null,Object? isLockedOut = null,Object? lockoutRemainingSeconds = null,Object? lockoutUntil = freezed,}) {
  return _then(_self.copyWith(
resendCountdownSeconds: null == resendCountdownSeconds ? _self.resendCountdownSeconds : resendCountdownSeconds // ignore: cast_nullable_to_non_nullable
as int,expiryCountdownSeconds: null == expiryCountdownSeconds ? _self.expiryCountdownSeconds : expiryCountdownSeconds // ignore: cast_nullable_to_non_nullable
as int,errorCount: null == errorCount ? _self.errorCount : errorCount // ignore: cast_nullable_to_non_nullable
as int,isLockedOut: null == isLockedOut ? _self.isLockedOut : isLockedOut // ignore: cast_nullable_to_non_nullable
as bool,lockoutRemainingSeconds: null == lockoutRemainingSeconds ? _self.lockoutRemainingSeconds : lockoutRemainingSeconds // ignore: cast_nullable_to_non_nullable
as int,lockoutUntil: freezed == lockoutUntil ? _self.lockoutUntil : lockoutUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpTimerState].
extension OtpTimerStatePatterns on OtpTimerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpTimerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpTimerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpTimerState value)  $default,){
final _that = this;
switch (_that) {
case _OtpTimerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpTimerState value)?  $default,){
final _that = this;
switch (_that) {
case _OtpTimerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int resendCountdownSeconds,  int expiryCountdownSeconds,  int errorCount,  bool isLockedOut,  int lockoutRemainingSeconds,  DateTime? lockoutUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpTimerState() when $default != null:
return $default(_that.resendCountdownSeconds,_that.expiryCountdownSeconds,_that.errorCount,_that.isLockedOut,_that.lockoutRemainingSeconds,_that.lockoutUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int resendCountdownSeconds,  int expiryCountdownSeconds,  int errorCount,  bool isLockedOut,  int lockoutRemainingSeconds,  DateTime? lockoutUntil)  $default,) {final _that = this;
switch (_that) {
case _OtpTimerState():
return $default(_that.resendCountdownSeconds,_that.expiryCountdownSeconds,_that.errorCount,_that.isLockedOut,_that.lockoutRemainingSeconds,_that.lockoutUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int resendCountdownSeconds,  int expiryCountdownSeconds,  int errorCount,  bool isLockedOut,  int lockoutRemainingSeconds,  DateTime? lockoutUntil)?  $default,) {final _that = this;
switch (_that) {
case _OtpTimerState() when $default != null:
return $default(_that.resendCountdownSeconds,_that.expiryCountdownSeconds,_that.errorCount,_that.isLockedOut,_that.lockoutRemainingSeconds,_that.lockoutUntil);case _:
  return null;

}
}

}

/// @nodoc


class _OtpTimerState implements OtpTimerState {
  const _OtpTimerState({this.resendCountdownSeconds = 60, this.expiryCountdownSeconds = 300, this.errorCount = 0, this.isLockedOut = false, this.lockoutRemainingSeconds = 0, this.lockoutUntil});
  

/// Countdown seconds before resend is allowed (0 = resend available)
@override@JsonKey() final  int resendCountdownSeconds;
/// OTP validity countdown (300 = 5 minutes)
@override@JsonKey() final  int expiryCountdownSeconds;
/// Number of incorrect OTP attempts on current request
@override@JsonKey() final  int errorCount;
/// True when account is locked out (errorCount >= 5)
@override@JsonKey() final  bool isLockedOut;
/// Remaining lockout seconds (PRD: 30 min)
@override@JsonKey() final  int lockoutRemainingSeconds;
/// Timestamp of lockout start (used to compute remaining)
@override final  DateTime? lockoutUntil;

/// Create a copy of OtpTimerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpTimerStateCopyWith<_OtpTimerState> get copyWith => __$OtpTimerStateCopyWithImpl<_OtpTimerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpTimerState&&(identical(other.resendCountdownSeconds, resendCountdownSeconds) || other.resendCountdownSeconds == resendCountdownSeconds)&&(identical(other.expiryCountdownSeconds, expiryCountdownSeconds) || other.expiryCountdownSeconds == expiryCountdownSeconds)&&(identical(other.errorCount, errorCount) || other.errorCount == errorCount)&&(identical(other.isLockedOut, isLockedOut) || other.isLockedOut == isLockedOut)&&(identical(other.lockoutRemainingSeconds, lockoutRemainingSeconds) || other.lockoutRemainingSeconds == lockoutRemainingSeconds)&&(identical(other.lockoutUntil, lockoutUntil) || other.lockoutUntil == lockoutUntil));
}


@override
int get hashCode => Object.hash(runtimeType,resendCountdownSeconds,expiryCountdownSeconds,errorCount,isLockedOut,lockoutRemainingSeconds,lockoutUntil);

@override
String toString() {
  return 'OtpTimerState(resendCountdownSeconds: $resendCountdownSeconds, expiryCountdownSeconds: $expiryCountdownSeconds, errorCount: $errorCount, isLockedOut: $isLockedOut, lockoutRemainingSeconds: $lockoutRemainingSeconds, lockoutUntil: $lockoutUntil)';
}


}

/// @nodoc
abstract mixin class _$OtpTimerStateCopyWith<$Res> implements $OtpTimerStateCopyWith<$Res> {
  factory _$OtpTimerStateCopyWith(_OtpTimerState value, $Res Function(_OtpTimerState) _then) = __$OtpTimerStateCopyWithImpl;
@override @useResult
$Res call({
 int resendCountdownSeconds, int expiryCountdownSeconds, int errorCount, bool isLockedOut, int lockoutRemainingSeconds, DateTime? lockoutUntil
});




}
/// @nodoc
class __$OtpTimerStateCopyWithImpl<$Res>
    implements _$OtpTimerStateCopyWith<$Res> {
  __$OtpTimerStateCopyWithImpl(this._self, this._then);

  final _OtpTimerState _self;
  final $Res Function(_OtpTimerState) _then;

/// Create a copy of OtpTimerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resendCountdownSeconds = null,Object? expiryCountdownSeconds = null,Object? errorCount = null,Object? isLockedOut = null,Object? lockoutRemainingSeconds = null,Object? lockoutUntil = freezed,}) {
  return _then(_OtpTimerState(
resendCountdownSeconds: null == resendCountdownSeconds ? _self.resendCountdownSeconds : resendCountdownSeconds // ignore: cast_nullable_to_non_nullable
as int,expiryCountdownSeconds: null == expiryCountdownSeconds ? _self.expiryCountdownSeconds : expiryCountdownSeconds // ignore: cast_nullable_to_non_nullable
as int,errorCount: null == errorCount ? _self.errorCount : errorCount // ignore: cast_nullable_to_non_nullable
as int,isLockedOut: null == isLockedOut ? _self.isLockedOut : isLockedOut // ignore: cast_nullable_to_non_nullable
as bool,lockoutRemainingSeconds: null == lockoutRemainingSeconds ? _self.lockoutRemainingSeconds : lockoutRemainingSeconds // ignore: cast_nullable_to_non_nullable
as int,lockoutUntil: freezed == lockoutUntil ? _self.lockoutUntil : lockoutUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
