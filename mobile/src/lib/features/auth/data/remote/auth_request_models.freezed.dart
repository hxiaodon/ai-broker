// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_request_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SendOtpRequest {

@JsonKey(name: 'phone_number') String get phoneNumber;@JsonKey(name: 'delivery_method') String get deliveryMethod;@JsonKey(name: 'captcha_token') String? get captchaToken;
/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendOtpRequestCopyWith<SendOtpRequest> get copyWith => _$SendOtpRequestCopyWithImpl<SendOtpRequest>(this as SendOtpRequest, _$identity);

  /// Serializes this SendOtpRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendOtpRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.deliveryMethod, deliveryMethod) || other.deliveryMethod == deliveryMethod)&&(identical(other.captchaToken, captchaToken) || other.captchaToken == captchaToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber,deliveryMethod,captchaToken);

@override
String toString() {
  return 'SendOtpRequest(phoneNumber: $phoneNumber, deliveryMethod: $deliveryMethod, captchaToken: $captchaToken)';
}


}

/// @nodoc
abstract mixin class $SendOtpRequestCopyWith<$Res>  {
  factory $SendOtpRequestCopyWith(SendOtpRequest value, $Res Function(SendOtpRequest) _then) = _$SendOtpRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'delivery_method') String deliveryMethod,@JsonKey(name: 'captcha_token') String? captchaToken
});




}
/// @nodoc
class _$SendOtpRequestCopyWithImpl<$Res>
    implements $SendOtpRequestCopyWith<$Res> {
  _$SendOtpRequestCopyWithImpl(this._self, this._then);

  final SendOtpRequest _self;
  final $Res Function(SendOtpRequest) _then;

/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phoneNumber = null,Object? deliveryMethod = null,Object? captchaToken = freezed,}) {
  return _then(_self.copyWith(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,deliveryMethod: null == deliveryMethod ? _self.deliveryMethod : deliveryMethod // ignore: cast_nullable_to_non_nullable
as String,captchaToken: freezed == captchaToken ? _self.captchaToken : captchaToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SendOtpRequest].
extension SendOtpRequestPatterns on SendOtpRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SendOtpRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SendOtpRequest value)  $default,){
final _that = this;
switch (_that) {
case _SendOtpRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SendOtpRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'delivery_method')  String deliveryMethod, @JsonKey(name: 'captcha_token')  String? captchaToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
return $default(_that.phoneNumber,_that.deliveryMethod,_that.captchaToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'delivery_method')  String deliveryMethod, @JsonKey(name: 'captcha_token')  String? captchaToken)  $default,) {final _that = this;
switch (_that) {
case _SendOtpRequest():
return $default(_that.phoneNumber,_that.deliveryMethod,_that.captchaToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'delivery_method')  String deliveryMethod, @JsonKey(name: 'captcha_token')  String? captchaToken)?  $default,) {final _that = this;
switch (_that) {
case _SendOtpRequest() when $default != null:
return $default(_that.phoneNumber,_that.deliveryMethod,_that.captchaToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SendOtpRequest implements SendOtpRequest {
  const _SendOtpRequest({@JsonKey(name: 'phone_number') required this.phoneNumber, @JsonKey(name: 'delivery_method') this.deliveryMethod = 'SMS', @JsonKey(name: 'captcha_token') this.captchaToken});
  factory _SendOtpRequest.fromJson(Map<String, dynamic> json) => _$SendOtpRequestFromJson(json);

@override@JsonKey(name: 'phone_number') final  String phoneNumber;
@override@JsonKey(name: 'delivery_method') final  String deliveryMethod;
@override@JsonKey(name: 'captcha_token') final  String? captchaToken;

/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendOtpRequestCopyWith<_SendOtpRequest> get copyWith => __$SendOtpRequestCopyWithImpl<_SendOtpRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SendOtpRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendOtpRequest&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.deliveryMethod, deliveryMethod) || other.deliveryMethod == deliveryMethod)&&(identical(other.captchaToken, captchaToken) || other.captchaToken == captchaToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phoneNumber,deliveryMethod,captchaToken);

@override
String toString() {
  return 'SendOtpRequest(phoneNumber: $phoneNumber, deliveryMethod: $deliveryMethod, captchaToken: $captchaToken)';
}


}

/// @nodoc
abstract mixin class _$SendOtpRequestCopyWith<$Res> implements $SendOtpRequestCopyWith<$Res> {
  factory _$SendOtpRequestCopyWith(_SendOtpRequest value, $Res Function(_SendOtpRequest) _then) = __$SendOtpRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'delivery_method') String deliveryMethod,@JsonKey(name: 'captcha_token') String? captchaToken
});




}
/// @nodoc
class __$SendOtpRequestCopyWithImpl<$Res>
    implements _$SendOtpRequestCopyWith<$Res> {
  __$SendOtpRequestCopyWithImpl(this._self, this._then);

  final _SendOtpRequest _self;
  final $Res Function(_SendOtpRequest) _then;

/// Create a copy of SendOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phoneNumber = null,Object? deliveryMethod = null,Object? captchaToken = freezed,}) {
  return _then(_SendOtpRequest(
phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,deliveryMethod: null == deliveryMethod ? _self.deliveryMethod : deliveryMethod // ignore: cast_nullable_to_non_nullable
as String,captchaToken: freezed == captchaToken ? _self.captchaToken : captchaToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VerifyOtpRequest {

@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'otp_code') String get otpCode;@JsonKey(name: 'phone_number') String get phoneNumber;
/// Create a copy of VerifyOtpRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpRequestCopyWith<VerifyOtpRequest> get copyWith => _$VerifyOtpRequestCopyWithImpl<VerifyOtpRequest>(this as VerifyOtpRequest, _$identity);

  /// Serializes this VerifyOtpRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.otpCode, otpCode) || other.otpCode == otpCode)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,otpCode,phoneNumber);

@override
String toString() {
  return 'VerifyOtpRequest(requestId: $requestId, otpCode: $otpCode, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpRequestCopyWith<$Res>  {
  factory $VerifyOtpRequestCopyWith(VerifyOtpRequest value, $Res Function(VerifyOtpRequest) _then) = _$VerifyOtpRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'otp_code') String otpCode,@JsonKey(name: 'phone_number') String phoneNumber
});




}
/// @nodoc
class _$VerifyOtpRequestCopyWithImpl<$Res>
    implements $VerifyOtpRequestCopyWith<$Res> {
  _$VerifyOtpRequestCopyWithImpl(this._self, this._then);

  final VerifyOtpRequest _self;
  final $Res Function(VerifyOtpRequest) _then;

/// Create a copy of VerifyOtpRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? otpCode = null,Object? phoneNumber = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,otpCode: null == otpCode ? _self.otpCode : otpCode // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyOtpRequest].
extension VerifyOtpRequestPatterns on VerifyOtpRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyOtpRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyOtpRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyOtpRequest value)  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyOtpRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'otp_code')  String otpCode, @JsonKey(name: 'phone_number')  String phoneNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyOtpRequest() when $default != null:
return $default(_that.requestId,_that.otpCode,_that.phoneNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'otp_code')  String otpCode, @JsonKey(name: 'phone_number')  String phoneNumber)  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpRequest():
return $default(_that.requestId,_that.otpCode,_that.phoneNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'otp_code')  String otpCode, @JsonKey(name: 'phone_number')  String phoneNumber)?  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpRequest() when $default != null:
return $default(_that.requestId,_that.otpCode,_that.phoneNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyOtpRequest implements VerifyOtpRequest {
  const _VerifyOtpRequest({@JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'otp_code') required this.otpCode, @JsonKey(name: 'phone_number') required this.phoneNumber});
  factory _VerifyOtpRequest.fromJson(Map<String, dynamic> json) => _$VerifyOtpRequestFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'otp_code') final  String otpCode;
@override@JsonKey(name: 'phone_number') final  String phoneNumber;

/// Create a copy of VerifyOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyOtpRequestCopyWith<_VerifyOtpRequest> get copyWith => __$VerifyOtpRequestCopyWithImpl<_VerifyOtpRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyOtpRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyOtpRequest&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.otpCode, otpCode) || other.otpCode == otpCode)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,otpCode,phoneNumber);

@override
String toString() {
  return 'VerifyOtpRequest(requestId: $requestId, otpCode: $otpCode, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$VerifyOtpRequestCopyWith<$Res> implements $VerifyOtpRequestCopyWith<$Res> {
  factory _$VerifyOtpRequestCopyWith(_VerifyOtpRequest value, $Res Function(_VerifyOtpRequest) _then) = __$VerifyOtpRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'otp_code') String otpCode,@JsonKey(name: 'phone_number') String phoneNumber
});




}
/// @nodoc
class __$VerifyOtpRequestCopyWithImpl<$Res>
    implements _$VerifyOtpRequestCopyWith<$Res> {
  __$VerifyOtpRequestCopyWithImpl(this._self, this._then);

  final _VerifyOtpRequest _self;
  final $Res Function(_VerifyOtpRequest) _then;

/// Create a copy of VerifyOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? otpCode = null,Object? phoneNumber = null,}) {
  return _then(_VerifyOtpRequest(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,otpCode: null == otpCode ? _self.otpCode : otpCode // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RefreshTokenRequest {

@JsonKey(name: 'refresh_token') String get refreshToken;
/// Create a copy of RefreshTokenRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshTokenRequestCopyWith<RefreshTokenRequest> get copyWith => _$RefreshTokenRequestCopyWithImpl<RefreshTokenRequest>(this as RefreshTokenRequest, _$identity);

  /// Serializes this RefreshTokenRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshTokenRequest&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,refreshToken);

@override
String toString() {
  return 'RefreshTokenRequest(refreshToken: $refreshToken)';
}


}

/// @nodoc
abstract mixin class $RefreshTokenRequestCopyWith<$Res>  {
  factory $RefreshTokenRequestCopyWith(RefreshTokenRequest value, $Res Function(RefreshTokenRequest) _then) = _$RefreshTokenRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'refresh_token') String refreshToken
});




}
/// @nodoc
class _$RefreshTokenRequestCopyWithImpl<$Res>
    implements $RefreshTokenRequestCopyWith<$Res> {
  _$RefreshTokenRequestCopyWithImpl(this._self, this._then);

  final RefreshTokenRequest _self;
  final $Res Function(RefreshTokenRequest) _then;

/// Create a copy of RefreshTokenRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? refreshToken = null,}) {
  return _then(_self.copyWith(
refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RefreshTokenRequest].
extension RefreshTokenRequestPatterns on RefreshTokenRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefreshTokenRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefreshTokenRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefreshTokenRequest value)  $default,){
final _that = this;
switch (_that) {
case _RefreshTokenRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefreshTokenRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RefreshTokenRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'refresh_token')  String refreshToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefreshTokenRequest() when $default != null:
return $default(_that.refreshToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'refresh_token')  String refreshToken)  $default,) {final _that = this;
switch (_that) {
case _RefreshTokenRequest():
return $default(_that.refreshToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'refresh_token')  String refreshToken)?  $default,) {final _that = this;
switch (_that) {
case _RefreshTokenRequest() when $default != null:
return $default(_that.refreshToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RefreshTokenRequest implements RefreshTokenRequest {
  const _RefreshTokenRequest({@JsonKey(name: 'refresh_token') required this.refreshToken});
  factory _RefreshTokenRequest.fromJson(Map<String, dynamic> json) => _$RefreshTokenRequestFromJson(json);

@override@JsonKey(name: 'refresh_token') final  String refreshToken;

/// Create a copy of RefreshTokenRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshTokenRequestCopyWith<_RefreshTokenRequest> get copyWith => __$RefreshTokenRequestCopyWithImpl<_RefreshTokenRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RefreshTokenRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshTokenRequest&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,refreshToken);

@override
String toString() {
  return 'RefreshTokenRequest(refreshToken: $refreshToken)';
}


}

/// @nodoc
abstract mixin class _$RefreshTokenRequestCopyWith<$Res> implements $RefreshTokenRequestCopyWith<$Res> {
  factory _$RefreshTokenRequestCopyWith(_RefreshTokenRequest value, $Res Function(_RefreshTokenRequest) _then) = __$RefreshTokenRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'refresh_token') String refreshToken
});




}
/// @nodoc
class __$RefreshTokenRequestCopyWithImpl<$Res>
    implements _$RefreshTokenRequestCopyWith<$Res> {
  __$RefreshTokenRequestCopyWithImpl(this._self, this._then);

  final _RefreshTokenRequest _self;
  final $Res Function(_RefreshTokenRequest) _then;

/// Create a copy of RefreshTokenRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? refreshToken = null,}) {
  return _then(_RefreshTokenRequest(
refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RegisterBiometricRequest {

@JsonKey(name: 'biometric_type') String get biometricType;@JsonKey(name: 'device_fingerprint') String get deviceFingerprint;@JsonKey(name: 'device_name') String? get deviceName;
/// Create a copy of RegisterBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterBiometricRequestCopyWith<RegisterBiometricRequest> get copyWith => _$RegisterBiometricRequestCopyWithImpl<RegisterBiometricRequest>(this as RegisterBiometricRequest, _$identity);

  /// Serializes this RegisterBiometricRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterBiometricRequest&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType)&&(identical(other.deviceFingerprint, deviceFingerprint) || other.deviceFingerprint == deviceFingerprint)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,biometricType,deviceFingerprint,deviceName);

@override
String toString() {
  return 'RegisterBiometricRequest(biometricType: $biometricType, deviceFingerprint: $deviceFingerprint, deviceName: $deviceName)';
}


}

/// @nodoc
abstract mixin class $RegisterBiometricRequestCopyWith<$Res>  {
  factory $RegisterBiometricRequestCopyWith(RegisterBiometricRequest value, $Res Function(RegisterBiometricRequest) _then) = _$RegisterBiometricRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'biometric_type') String biometricType,@JsonKey(name: 'device_fingerprint') String deviceFingerprint,@JsonKey(name: 'device_name') String? deviceName
});




}
/// @nodoc
class _$RegisterBiometricRequestCopyWithImpl<$Res>
    implements $RegisterBiometricRequestCopyWith<$Res> {
  _$RegisterBiometricRequestCopyWithImpl(this._self, this._then);

  final RegisterBiometricRequest _self;
  final $Res Function(RegisterBiometricRequest) _then;

/// Create a copy of RegisterBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? biometricType = null,Object? deviceFingerprint = null,Object? deviceName = freezed,}) {
  return _then(_self.copyWith(
biometricType: null == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String,deviceFingerprint: null == deviceFingerprint ? _self.deviceFingerprint : deviceFingerprint // ignore: cast_nullable_to_non_nullable
as String,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterBiometricRequest].
extension RegisterBiometricRequestPatterns on RegisterBiometricRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterBiometricRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterBiometricRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterBiometricRequest value)  $default,){
final _that = this;
switch (_that) {
case _RegisterBiometricRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterBiometricRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterBiometricRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'biometric_type')  String biometricType, @JsonKey(name: 'device_fingerprint')  String deviceFingerprint, @JsonKey(name: 'device_name')  String? deviceName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterBiometricRequest() when $default != null:
return $default(_that.biometricType,_that.deviceFingerprint,_that.deviceName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'biometric_type')  String biometricType, @JsonKey(name: 'device_fingerprint')  String deviceFingerprint, @JsonKey(name: 'device_name')  String? deviceName)  $default,) {final _that = this;
switch (_that) {
case _RegisterBiometricRequest():
return $default(_that.biometricType,_that.deviceFingerprint,_that.deviceName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'biometric_type')  String biometricType, @JsonKey(name: 'device_fingerprint')  String deviceFingerprint, @JsonKey(name: 'device_name')  String? deviceName)?  $default,) {final _that = this;
switch (_that) {
case _RegisterBiometricRequest() when $default != null:
return $default(_that.biometricType,_that.deviceFingerprint,_that.deviceName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisterBiometricRequest implements RegisterBiometricRequest {
  const _RegisterBiometricRequest({@JsonKey(name: 'biometric_type') required this.biometricType, @JsonKey(name: 'device_fingerprint') required this.deviceFingerprint, @JsonKey(name: 'device_name') this.deviceName});
  factory _RegisterBiometricRequest.fromJson(Map<String, dynamic> json) => _$RegisterBiometricRequestFromJson(json);

@override@JsonKey(name: 'biometric_type') final  String biometricType;
@override@JsonKey(name: 'device_fingerprint') final  String deviceFingerprint;
@override@JsonKey(name: 'device_name') final  String? deviceName;

/// Create a copy of RegisterBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterBiometricRequestCopyWith<_RegisterBiometricRequest> get copyWith => __$RegisterBiometricRequestCopyWithImpl<_RegisterBiometricRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisterBiometricRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterBiometricRequest&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType)&&(identical(other.deviceFingerprint, deviceFingerprint) || other.deviceFingerprint == deviceFingerprint)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,biometricType,deviceFingerprint,deviceName);

@override
String toString() {
  return 'RegisterBiometricRequest(biometricType: $biometricType, deviceFingerprint: $deviceFingerprint, deviceName: $deviceName)';
}


}

/// @nodoc
abstract mixin class _$RegisterBiometricRequestCopyWith<$Res> implements $RegisterBiometricRequestCopyWith<$Res> {
  factory _$RegisterBiometricRequestCopyWith(_RegisterBiometricRequest value, $Res Function(_RegisterBiometricRequest) _then) = __$RegisterBiometricRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'biometric_type') String biometricType,@JsonKey(name: 'device_fingerprint') String deviceFingerprint,@JsonKey(name: 'device_name') String? deviceName
});




}
/// @nodoc
class __$RegisterBiometricRequestCopyWithImpl<$Res>
    implements _$RegisterBiometricRequestCopyWith<$Res> {
  __$RegisterBiometricRequestCopyWithImpl(this._self, this._then);

  final _RegisterBiometricRequest _self;
  final $Res Function(_RegisterBiometricRequest) _then;

/// Create a copy of RegisterBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? biometricType = null,Object? deviceFingerprint = null,Object? deviceName = freezed,}) {
  return _then(_RegisterBiometricRequest(
biometricType: null == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String,deviceFingerprint: null == deviceFingerprint ? _self.deviceFingerprint : deviceFingerprint // ignore: cast_nullable_to_non_nullable
as String,deviceName: freezed == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VerifyBiometricRequest {

 String get operation;@JsonKey(name: 'device_fingerprint') String? get deviceFingerprint;
/// Create a copy of VerifyBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyBiometricRequestCopyWith<VerifyBiometricRequest> get copyWith => _$VerifyBiometricRequestCopyWithImpl<VerifyBiometricRequest>(this as VerifyBiometricRequest, _$identity);

  /// Serializes this VerifyBiometricRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyBiometricRequest&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.deviceFingerprint, deviceFingerprint) || other.deviceFingerprint == deviceFingerprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operation,deviceFingerprint);

@override
String toString() {
  return 'VerifyBiometricRequest(operation: $operation, deviceFingerprint: $deviceFingerprint)';
}


}

/// @nodoc
abstract mixin class $VerifyBiometricRequestCopyWith<$Res>  {
  factory $VerifyBiometricRequestCopyWith(VerifyBiometricRequest value, $Res Function(VerifyBiometricRequest) _then) = _$VerifyBiometricRequestCopyWithImpl;
@useResult
$Res call({
 String operation,@JsonKey(name: 'device_fingerprint') String? deviceFingerprint
});




}
/// @nodoc
class _$VerifyBiometricRequestCopyWithImpl<$Res>
    implements $VerifyBiometricRequestCopyWith<$Res> {
  _$VerifyBiometricRequestCopyWithImpl(this._self, this._then);

  final VerifyBiometricRequest _self;
  final $Res Function(VerifyBiometricRequest) _then;

/// Create a copy of VerifyBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operation = null,Object? deviceFingerprint = freezed,}) {
  return _then(_self.copyWith(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,deviceFingerprint: freezed == deviceFingerprint ? _self.deviceFingerprint : deviceFingerprint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyBiometricRequest].
extension VerifyBiometricRequestPatterns on VerifyBiometricRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyBiometricRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyBiometricRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyBiometricRequest value)  $default,){
final _that = this;
switch (_that) {
case _VerifyBiometricRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyBiometricRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyBiometricRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String operation, @JsonKey(name: 'device_fingerprint')  String? deviceFingerprint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyBiometricRequest() when $default != null:
return $default(_that.operation,_that.deviceFingerprint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String operation, @JsonKey(name: 'device_fingerprint')  String? deviceFingerprint)  $default,) {final _that = this;
switch (_that) {
case _VerifyBiometricRequest():
return $default(_that.operation,_that.deviceFingerprint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String operation, @JsonKey(name: 'device_fingerprint')  String? deviceFingerprint)?  $default,) {final _that = this;
switch (_that) {
case _VerifyBiometricRequest() when $default != null:
return $default(_that.operation,_that.deviceFingerprint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyBiometricRequest implements VerifyBiometricRequest {
  const _VerifyBiometricRequest({required this.operation, @JsonKey(name: 'device_fingerprint') this.deviceFingerprint});
  factory _VerifyBiometricRequest.fromJson(Map<String, dynamic> json) => _$VerifyBiometricRequestFromJson(json);

@override final  String operation;
@override@JsonKey(name: 'device_fingerprint') final  String? deviceFingerprint;

/// Create a copy of VerifyBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyBiometricRequestCopyWith<_VerifyBiometricRequest> get copyWith => __$VerifyBiometricRequestCopyWithImpl<_VerifyBiometricRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyBiometricRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyBiometricRequest&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.deviceFingerprint, deviceFingerprint) || other.deviceFingerprint == deviceFingerprint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operation,deviceFingerprint);

@override
String toString() {
  return 'VerifyBiometricRequest(operation: $operation, deviceFingerprint: $deviceFingerprint)';
}


}

/// @nodoc
abstract mixin class _$VerifyBiometricRequestCopyWith<$Res> implements $VerifyBiometricRequestCopyWith<$Res> {
  factory _$VerifyBiometricRequestCopyWith(_VerifyBiometricRequest value, $Res Function(_VerifyBiometricRequest) _then) = __$VerifyBiometricRequestCopyWithImpl;
@override @useResult
$Res call({
 String operation,@JsonKey(name: 'device_fingerprint') String? deviceFingerprint
});




}
/// @nodoc
class __$VerifyBiometricRequestCopyWithImpl<$Res>
    implements _$VerifyBiometricRequestCopyWith<$Res> {
  __$VerifyBiometricRequestCopyWithImpl(this._self, this._then);

  final _VerifyBiometricRequest _self;
  final $Res Function(_VerifyBiometricRequest) _then;

/// Create a copy of VerifyBiometricRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? deviceFingerprint = freezed,}) {
  return _then(_VerifyBiometricRequest(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,deviceFingerprint: freezed == deviceFingerprint ? _self.deviceFingerprint : deviceFingerprint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$LogoutRequest {

 String get reason;
/// Create a copy of LogoutRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoutRequestCopyWith<LogoutRequest> get copyWith => _$LogoutRequestCopyWithImpl<LogoutRequest>(this as LogoutRequest, _$identity);

  /// Serializes this LogoutRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'LogoutRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $LogoutRequestCopyWith<$Res>  {
  factory $LogoutRequestCopyWith(LogoutRequest value, $Res Function(LogoutRequest) _then) = _$LogoutRequestCopyWithImpl;
@useResult
$Res call({
 String reason
});




}
/// @nodoc
class _$LogoutRequestCopyWithImpl<$Res>
    implements $LogoutRequestCopyWith<$Res> {
  _$LogoutRequestCopyWithImpl(this._self, this._then);

  final LogoutRequest _self;
  final $Res Function(LogoutRequest) _then;

/// Create a copy of LogoutRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reason = null,}) {
  return _then(_self.copyWith(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LogoutRequest].
extension LogoutRequestPatterns on LogoutRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogoutRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogoutRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogoutRequest value)  $default,){
final _that = this;
switch (_that) {
case _LogoutRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogoutRequest value)?  $default,){
final _that = this;
switch (_that) {
case _LogoutRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogoutRequest() when $default != null:
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reason)  $default,) {final _that = this;
switch (_that) {
case _LogoutRequest():
return $default(_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reason)?  $default,) {final _that = this;
switch (_that) {
case _LogoutRequest() when $default != null:
return $default(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LogoutRequest implements LogoutRequest {
  const _LogoutRequest({this.reason = 'USER_INITIATED'});
  factory _LogoutRequest.fromJson(Map<String, dynamic> json) => _$LogoutRequestFromJson(json);

@override@JsonKey() final  String reason;

/// Create a copy of LogoutRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogoutRequestCopyWith<_LogoutRequest> get copyWith => __$LogoutRequestCopyWithImpl<_LogoutRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LogoutRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogoutRequest&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'LogoutRequest(reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$LogoutRequestCopyWith<$Res> implements $LogoutRequestCopyWith<$Res> {
  factory _$LogoutRequestCopyWith(_LogoutRequest value, $Res Function(_LogoutRequest) _then) = __$LogoutRequestCopyWithImpl;
@override @useResult
$Res call({
 String reason
});




}
/// @nodoc
class __$LogoutRequestCopyWithImpl<$Res>
    implements _$LogoutRequestCopyWith<$Res> {
  __$LogoutRequestCopyWithImpl(this._self, this._then);

  final _LogoutRequest _self;
  final $Res Function(_LogoutRequest) _then;

/// Create a copy of LogoutRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(_LogoutRequest(
reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
