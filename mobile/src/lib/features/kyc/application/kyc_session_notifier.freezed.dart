// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kyc_session_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$KycSessionState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KycSessionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KycSessionState()';
}


}

/// @nodoc
class $KycSessionStateCopyWith<$Res>  {
$KycSessionStateCopyWith(KycSessionState _, $Res Function(KycSessionState) __);
}


/// Adds pattern-matching-related methods to [KycSessionState].
extension KycSessionStatePatterns on KycSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Loading value)?  loading,TResult Function( _NoSession value)?  noSession,TResult Function( _Active value)?  active,TResult Function( _Expired value)?  expired,TResult Function( _KycError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _NoSession() when noSession != null:
return noSession(_that);case _Active() when active != null:
return active(_that);case _Expired() when expired != null:
return expired(_that);case _KycError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Loading value)  loading,required TResult Function( _NoSession value)  noSession,required TResult Function( _Active value)  active,required TResult Function( _Expired value)  expired,required TResult Function( _KycError value)  error,}){
final _that = this;
switch (_that) {
case _Loading():
return loading(_that);case _NoSession():
return noSession(_that);case _Active():
return active(_that);case _Expired():
return expired(_that);case _KycError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Loading value)?  loading,TResult? Function( _NoSession value)?  noSession,TResult? Function( _Active value)?  active,TResult? Function( _Expired value)?  expired,TResult? Function( _KycError value)?  error,}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _NoSession() when noSession != null:
return noSession(_that);case _Active() when active != null:
return active(_that);case _Expired() when expired != null:
return expired(_that);case _KycError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  noSession,TResult Function( KycSession session)?  active,TResult Function()?  expired,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _NoSession() when noSession != null:
return noSession();case _Active() when active != null:
return active(_that.session);case _Expired() when expired != null:
return expired();case _KycError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  noSession,required TResult Function( KycSession session)  active,required TResult Function()  expired,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Loading():
return loading();case _NoSession():
return noSession();case _Active():
return active(_that.session);case _Expired():
return expired();case _KycError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  noSession,TResult? Function( KycSession session)?  active,TResult? Function()?  expired,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _NoSession() when noSession != null:
return noSession();case _Active() when active != null:
return active(_that.session);case _Expired() when expired != null:
return expired();case _KycError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Loading implements KycSessionState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KycSessionState.loading()';
}


}




/// @nodoc


class _NoSession implements KycSessionState {
  const _NoSession();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NoSession);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KycSessionState.noSession()';
}


}




/// @nodoc


class _Active implements KycSessionState {
  const _Active({required this.session});
  

 final  KycSession session;

/// Create a copy of KycSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveCopyWith<_Active> get copyWith => __$ActiveCopyWithImpl<_Active>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Active&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'KycSessionState.active(session: $session)';
}


}

/// @nodoc
abstract mixin class _$ActiveCopyWith<$Res> implements $KycSessionStateCopyWith<$Res> {
  factory _$ActiveCopyWith(_Active value, $Res Function(_Active) _then) = __$ActiveCopyWithImpl;
@useResult
$Res call({
 KycSession session
});


$KycSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$ActiveCopyWithImpl<$Res>
    implements _$ActiveCopyWith<$Res> {
  __$ActiveCopyWithImpl(this._self, this._then);

  final _Active _self;
  final $Res Function(_Active) _then;

/// Create a copy of KycSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(_Active(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as KycSession,
  ));
}

/// Create a copy of KycSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KycSessionCopyWith<$Res> get session {
  
  return $KycSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class _Expired implements KycSessionState {
  const _Expired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'KycSessionState.expired()';
}


}




/// @nodoc


class _KycError implements KycSessionState {
  const _KycError({required this.message});
  

 final  String message;

/// Create a copy of KycSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KycErrorCopyWith<_KycError> get copyWith => __$KycErrorCopyWithImpl<_KycError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KycError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'KycSessionState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$KycErrorCopyWith<$Res> implements $KycSessionStateCopyWith<$Res> {
  factory _$KycErrorCopyWith(_KycError value, $Res Function(_KycError) _then) = __$KycErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$KycErrorCopyWithImpl<$Res>
    implements _$KycErrorCopyWith<$Res> {
  __$KycErrorCopyWithImpl(this._self, this._then);

  final _KycError _self;
  final $Res Function(_KycError) _then;

/// Create a copy of KycSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_KycError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
