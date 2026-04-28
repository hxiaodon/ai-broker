// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kyc_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$KycSession {

 String get sessionId; int get currentStep; KycStatus get status; DateTime get expiresAt; int? get estimatedTimeMinutes; String? get rejectionReason; int? get needsMoreInfoStep;/// 用户在 Step 1 填写的英文全名（"FirstName LastName"），用于 Step 8 签名比对。
 String? get accountHolderName;
/// Create a copy of KycSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KycSessionCopyWith<KycSession> get copyWith => _$KycSessionCopyWithImpl<KycSession>(this as KycSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KycSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.estimatedTimeMinutes, estimatedTimeMinutes) || other.estimatedTimeMinutes == estimatedTimeMinutes)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.needsMoreInfoStep, needsMoreInfoStep) || other.needsMoreInfoStep == needsMoreInfoStep)&&(identical(other.accountHolderName, accountHolderName) || other.accountHolderName == accountHolderName));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,currentStep,status,expiresAt,estimatedTimeMinutes,rejectionReason,needsMoreInfoStep,accountHolderName);

@override
String toString() {
  return 'KycSession(sessionId: $sessionId, currentStep: $currentStep, status: $status, expiresAt: $expiresAt, estimatedTimeMinutes: $estimatedTimeMinutes, rejectionReason: $rejectionReason, needsMoreInfoStep: $needsMoreInfoStep, accountHolderName: $accountHolderName)';
}


}

/// @nodoc
abstract mixin class $KycSessionCopyWith<$Res>  {
  factory $KycSessionCopyWith(KycSession value, $Res Function(KycSession) _then) = _$KycSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, int currentStep, KycStatus status, DateTime expiresAt, int? estimatedTimeMinutes, String? rejectionReason, int? needsMoreInfoStep, String? accountHolderName
});




}
/// @nodoc
class _$KycSessionCopyWithImpl<$Res>
    implements $KycSessionCopyWith<$Res> {
  _$KycSessionCopyWithImpl(this._self, this._then);

  final KycSession _self;
  final $Res Function(KycSession) _then;

/// Create a copy of KycSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? currentStep = null,Object? status = null,Object? expiresAt = null,Object? estimatedTimeMinutes = freezed,Object? rejectionReason = freezed,Object? needsMoreInfoStep = freezed,Object? accountHolderName = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as KycStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,estimatedTimeMinutes: freezed == estimatedTimeMinutes ? _self.estimatedTimeMinutes : estimatedTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,needsMoreInfoStep: freezed == needsMoreInfoStep ? _self.needsMoreInfoStep : needsMoreInfoStep // ignore: cast_nullable_to_non_nullable
as int?,accountHolderName: freezed == accountHolderName ? _self.accountHolderName : accountHolderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KycSession].
extension KycSessionPatterns on KycSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KycSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KycSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KycSession value)  $default,){
final _that = this;
switch (_that) {
case _KycSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KycSession value)?  $default,){
final _that = this;
switch (_that) {
case _KycSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  int currentStep,  KycStatus status,  DateTime expiresAt,  int? estimatedTimeMinutes,  String? rejectionReason,  int? needsMoreInfoStep,  String? accountHolderName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KycSession() when $default != null:
return $default(_that.sessionId,_that.currentStep,_that.status,_that.expiresAt,_that.estimatedTimeMinutes,_that.rejectionReason,_that.needsMoreInfoStep,_that.accountHolderName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  int currentStep,  KycStatus status,  DateTime expiresAt,  int? estimatedTimeMinutes,  String? rejectionReason,  int? needsMoreInfoStep,  String? accountHolderName)  $default,) {final _that = this;
switch (_that) {
case _KycSession():
return $default(_that.sessionId,_that.currentStep,_that.status,_that.expiresAt,_that.estimatedTimeMinutes,_that.rejectionReason,_that.needsMoreInfoStep,_that.accountHolderName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  int currentStep,  KycStatus status,  DateTime expiresAt,  int? estimatedTimeMinutes,  String? rejectionReason,  int? needsMoreInfoStep,  String? accountHolderName)?  $default,) {final _that = this;
switch (_that) {
case _KycSession() when $default != null:
return $default(_that.sessionId,_that.currentStep,_that.status,_that.expiresAt,_that.estimatedTimeMinutes,_that.rejectionReason,_that.needsMoreInfoStep,_that.accountHolderName);case _:
  return null;

}
}

}

/// @nodoc


class _KycSession implements KycSession {
  const _KycSession({required this.sessionId, required this.currentStep, required this.status, required this.expiresAt, this.estimatedTimeMinutes, this.rejectionReason, this.needsMoreInfoStep, this.accountHolderName});
  

@override final  String sessionId;
@override final  int currentStep;
@override final  KycStatus status;
@override final  DateTime expiresAt;
@override final  int? estimatedTimeMinutes;
@override final  String? rejectionReason;
@override final  int? needsMoreInfoStep;
/// 用户在 Step 1 填写的英文全名（"FirstName LastName"），用于 Step 8 签名比对。
@override final  String? accountHolderName;

/// Create a copy of KycSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KycSessionCopyWith<_KycSession> get copyWith => __$KycSessionCopyWithImpl<_KycSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KycSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.estimatedTimeMinutes, estimatedTimeMinutes) || other.estimatedTimeMinutes == estimatedTimeMinutes)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.needsMoreInfoStep, needsMoreInfoStep) || other.needsMoreInfoStep == needsMoreInfoStep)&&(identical(other.accountHolderName, accountHolderName) || other.accountHolderName == accountHolderName));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,currentStep,status,expiresAt,estimatedTimeMinutes,rejectionReason,needsMoreInfoStep,accountHolderName);

@override
String toString() {
  return 'KycSession(sessionId: $sessionId, currentStep: $currentStep, status: $status, expiresAt: $expiresAt, estimatedTimeMinutes: $estimatedTimeMinutes, rejectionReason: $rejectionReason, needsMoreInfoStep: $needsMoreInfoStep, accountHolderName: $accountHolderName)';
}


}

/// @nodoc
abstract mixin class _$KycSessionCopyWith<$Res> implements $KycSessionCopyWith<$Res> {
  factory _$KycSessionCopyWith(_KycSession value, $Res Function(_KycSession) _then) = __$KycSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, int currentStep, KycStatus status, DateTime expiresAt, int? estimatedTimeMinutes, String? rejectionReason, int? needsMoreInfoStep, String? accountHolderName
});




}
/// @nodoc
class __$KycSessionCopyWithImpl<$Res>
    implements _$KycSessionCopyWith<$Res> {
  __$KycSessionCopyWithImpl(this._self, this._then);

  final _KycSession _self;
  final $Res Function(_KycSession) _then;

/// Create a copy of KycSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? currentStep = null,Object? status = null,Object? expiresAt = null,Object? estimatedTimeMinutes = freezed,Object? rejectionReason = freezed,Object? needsMoreInfoStep = freezed,Object? accountHolderName = freezed,}) {
  return _then(_KycSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as KycStatus,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,estimatedTimeMinutes: freezed == estimatedTimeMinutes ? _self.estimatedTimeMinutes : estimatedTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,needsMoreInfoStep: freezed == needsMoreInfoStep ? _self.needsMoreInfoStep : needsMoreInfoStep // ignore: cast_nullable_to_non_nullable
as int?,accountHolderName: freezed == accountHolderName ? _self.accountHolderName : accountHolderName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
