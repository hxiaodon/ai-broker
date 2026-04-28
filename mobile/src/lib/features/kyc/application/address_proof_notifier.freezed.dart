// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_proof_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddressProofState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddressProofState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AddressProofState()';
}


}

/// @nodoc
class $AddressProofStateCopyWith<$Res>  {
$AddressProofStateCopyWith(AddressProofState _, $Res Function(AddressProofState) __);
}


/// Adds pattern-matching-related methods to [AddressProofState].
extension AddressProofStatePatterns on AddressProofState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Idle value)?  idle,TResult Function( _Uploading value)?  uploading,TResult Function( _Success value)?  success,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Uploading() when uploading != null:
return uploading(_that);case _Success() when success != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Idle value)  idle,required TResult Function( _Uploading value)  uploading,required TResult Function( _Success value)  success,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Idle():
return idle(_that);case _Uploading():
return uploading(_that);case _Success():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Idle value)?  idle,TResult? Function( _Uploading value)?  uploading,TResult? Function( _Success value)?  success,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle(_that);case _Uploading() when uploading != null:
return uploading(_that);case _Success() when success != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( int progressPct)?  uploading,TResult Function()?  success,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Uploading() when uploading != null:
return uploading(_that.progressPct);case _Success() when success != null:
return success();case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( int progressPct)  uploading,required TResult Function()  success,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Idle():
return idle();case _Uploading():
return uploading(_that.progressPct);case _Success():
return success();case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( int progressPct)?  uploading,TResult? Function()?  success,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Idle() when idle != null:
return idle();case _Uploading() when uploading != null:
return uploading(_that.progressPct);case _Success() when success != null:
return success();case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Idle implements AddressProofState {
  const _Idle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Idle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AddressProofState.idle()';
}


}




/// @nodoc


class _Uploading implements AddressProofState {
  const _Uploading({required this.progressPct});
  

 final  int progressPct;

/// Create a copy of AddressProofState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadingCopyWith<_Uploading> get copyWith => __$UploadingCopyWithImpl<_Uploading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Uploading&&(identical(other.progressPct, progressPct) || other.progressPct == progressPct));
}


@override
int get hashCode => Object.hash(runtimeType,progressPct);

@override
String toString() {
  return 'AddressProofState.uploading(progressPct: $progressPct)';
}


}

/// @nodoc
abstract mixin class _$UploadingCopyWith<$Res> implements $AddressProofStateCopyWith<$Res> {
  factory _$UploadingCopyWith(_Uploading value, $Res Function(_Uploading) _then) = __$UploadingCopyWithImpl;
@useResult
$Res call({
 int progressPct
});




}
/// @nodoc
class __$UploadingCopyWithImpl<$Res>
    implements _$UploadingCopyWith<$Res> {
  __$UploadingCopyWithImpl(this._self, this._then);

  final _Uploading _self;
  final $Res Function(_Uploading) _then;

/// Create a copy of AddressProofState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progressPct = null,}) {
  return _then(_Uploading(
progressPct: null == progressPct ? _self.progressPct : progressPct // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Success implements AddressProofState {
  const _Success();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Success);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AddressProofState.success()';
}


}




/// @nodoc


class _Error implements AddressProofState {
  const _Error({required this.message});
  

 final  String message;

/// Create a copy of AddressProofState
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
  return 'AddressProofState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $AddressProofStateCopyWith<$Res> {
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

/// Create a copy of AddressProofState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
