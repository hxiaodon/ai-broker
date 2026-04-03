// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Unauthenticated value)?  unauthenticated,TResult Function( _Authenticating value)?  authenticating,TResult Function( _Authenticated value)?  authenticated,TResult Function( _Guest value)?  guest,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case _Authenticating() when authenticating != null:
return authenticating(_that);case _Authenticated() when authenticated != null:
return authenticated(_that);case _Guest() when guest != null:
return guest(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Unauthenticated value)  unauthenticated,required TResult Function( _Authenticating value)  authenticating,required TResult Function( _Authenticated value)  authenticated,required TResult Function( _Guest value)  guest,}){
final _that = this;
switch (_that) {
case _Unauthenticated():
return unauthenticated(_that);case _Authenticating():
return authenticating(_that);case _Authenticated():
return authenticated(_that);case _Guest():
return guest(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Unauthenticated value)?  unauthenticated,TResult? Function( _Authenticating value)?  authenticating,TResult? Function( _Authenticated value)?  authenticated,TResult? Function( _Guest value)?  guest,}){
final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated(_that);case _Authenticating() when authenticating != null:
return authenticating(_that);case _Authenticated() when authenticated != null:
return authenticated(_that);case _Guest() when guest != null:
return guest(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  unauthenticated,TResult Function()?  authenticating,TResult Function( String accountId,  String accountStatus,  bool biometricEnabled)?  authenticated,TResult Function()?  guest,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated();case _Authenticating() when authenticating != null:
return authenticating();case _Authenticated() when authenticated != null:
return authenticated(_that.accountId,_that.accountStatus,_that.biometricEnabled);case _Guest() when guest != null:
return guest();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  unauthenticated,required TResult Function()  authenticating,required TResult Function( String accountId,  String accountStatus,  bool biometricEnabled)  authenticated,required TResult Function()  guest,}) {final _that = this;
switch (_that) {
case _Unauthenticated():
return unauthenticated();case _Authenticating():
return authenticating();case _Authenticated():
return authenticated(_that.accountId,_that.accountStatus,_that.biometricEnabled);case _Guest():
return guest();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  unauthenticated,TResult? Function()?  authenticating,TResult? Function( String accountId,  String accountStatus,  bool biometricEnabled)?  authenticated,TResult? Function()?  guest,}) {final _that = this;
switch (_that) {
case _Unauthenticated() when unauthenticated != null:
return unauthenticated();case _Authenticating() when authenticating != null:
return authenticating();case _Authenticated() when authenticated != null:
return authenticated(_that.accountId,_that.accountStatus,_that.biometricEnabled);case _Guest() when guest != null:
return guest();case _:
  return null;

}
}

}

/// @nodoc


class _Unauthenticated implements AuthState {
  const _Unauthenticated();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unauthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.unauthenticated()';
}


}




/// @nodoc


class _Authenticating implements AuthState {
  const _Authenticating();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Authenticating);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.authenticating()';
}


}




/// @nodoc


class _Authenticated implements AuthState {
  const _Authenticated({required this.accountId, required this.accountStatus, required this.biometricEnabled});
  

 final  String accountId;
 final  String accountStatus;
 final  bool biometricEnabled;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthenticatedCopyWith<_Authenticated> get copyWith => __$AuthenticatedCopyWithImpl<_Authenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Authenticated&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountStatus, accountStatus) || other.accountStatus == accountStatus)&&(identical(other.biometricEnabled, biometricEnabled) || other.biometricEnabled == biometricEnabled));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,accountStatus,biometricEnabled);

@override
String toString() {
  return 'AuthState.authenticated(accountId: $accountId, accountStatus: $accountStatus, biometricEnabled: $biometricEnabled)';
}


}

/// @nodoc
abstract mixin class _$AuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthenticatedCopyWith(_Authenticated value, $Res Function(_Authenticated) _then) = __$AuthenticatedCopyWithImpl;
@useResult
$Res call({
 String accountId, String accountStatus, bool biometricEnabled
});




}
/// @nodoc
class __$AuthenticatedCopyWithImpl<$Res>
    implements _$AuthenticatedCopyWith<$Res> {
  __$AuthenticatedCopyWithImpl(this._self, this._then);

  final _Authenticated _self;
  final $Res Function(_Authenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? accountStatus = null,Object? biometricEnabled = null,}) {
  return _then(_Authenticated(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as String,biometricEnabled: null == biometricEnabled ? _self.biometricEnabled : biometricEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Guest implements AuthState {
  const _Guest();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Guest);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.guest()';
}


}




// dart format on
