// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_response_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SendOtpResponse {

@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'phone_number') String get phoneNumber;@JsonKey(name: 'delivery_method') String get deliveryMethod;@JsonKey(name: 'expires_in_seconds') int get expiresInSeconds;@JsonKey(name: 'retry_after_seconds') int get retryAfterSeconds;
/// Create a copy of SendOtpResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SendOtpResponseCopyWith<SendOtpResponse> get copyWith => _$SendOtpResponseCopyWithImpl<SendOtpResponse>(this as SendOtpResponse, _$identity);

  /// Serializes this SendOtpResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SendOtpResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.deliveryMethod, deliveryMethod) || other.deliveryMethod == deliveryMethod)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,phoneNumber,deliveryMethod,expiresInSeconds,retryAfterSeconds);

@override
String toString() {
  return 'SendOtpResponse(requestId: $requestId, phoneNumber: $phoneNumber, deliveryMethod: $deliveryMethod, expiresInSeconds: $expiresInSeconds, retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class $SendOtpResponseCopyWith<$Res>  {
  factory $SendOtpResponseCopyWith(SendOtpResponse value, $Res Function(SendOtpResponse) _then) = _$SendOtpResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'delivery_method') String deliveryMethod,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'retry_after_seconds') int retryAfterSeconds
});




}
/// @nodoc
class _$SendOtpResponseCopyWithImpl<$Res>
    implements $SendOtpResponseCopyWith<$Res> {
  _$SendOtpResponseCopyWithImpl(this._self, this._then);

  final SendOtpResponse _self;
  final $Res Function(SendOtpResponse) _then;

/// Create a copy of SendOtpResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? phoneNumber = null,Object? deliveryMethod = null,Object? expiresInSeconds = null,Object? retryAfterSeconds = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,deliveryMethod: null == deliveryMethod ? _self.deliveryMethod : deliveryMethod // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,retryAfterSeconds: null == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SendOtpResponse].
extension SendOtpResponsePatterns on SendOtpResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SendOtpResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SendOtpResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SendOtpResponse value)  $default,){
final _that = this;
switch (_that) {
case _SendOtpResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SendOtpResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SendOtpResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'delivery_method')  String deliveryMethod, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'retry_after_seconds')  int retryAfterSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SendOtpResponse() when $default != null:
return $default(_that.requestId,_that.phoneNumber,_that.deliveryMethod,_that.expiresInSeconds,_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'delivery_method')  String deliveryMethod, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'retry_after_seconds')  int retryAfterSeconds)  $default,) {final _that = this;
switch (_that) {
case _SendOtpResponse():
return $default(_that.requestId,_that.phoneNumber,_that.deliveryMethod,_that.expiresInSeconds,_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'delivery_method')  String deliveryMethod, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'retry_after_seconds')  int retryAfterSeconds)?  $default,) {final _that = this;
switch (_that) {
case _SendOtpResponse() when $default != null:
return $default(_that.requestId,_that.phoneNumber,_that.deliveryMethod,_that.expiresInSeconds,_that.retryAfterSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SendOtpResponse implements SendOtpResponse {
  const _SendOtpResponse({@JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'phone_number') required this.phoneNumber, @JsonKey(name: 'delivery_method') required this.deliveryMethod, @JsonKey(name: 'expires_in_seconds') required this.expiresInSeconds, @JsonKey(name: 'retry_after_seconds') required this.retryAfterSeconds});
  factory _SendOtpResponse.fromJson(Map<String, dynamic> json) => _$SendOtpResponseFromJson(json);

@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'phone_number') final  String phoneNumber;
@override@JsonKey(name: 'delivery_method') final  String deliveryMethod;
@override@JsonKey(name: 'expires_in_seconds') final  int expiresInSeconds;
@override@JsonKey(name: 'retry_after_seconds') final  int retryAfterSeconds;

/// Create a copy of SendOtpResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendOtpResponseCopyWith<_SendOtpResponse> get copyWith => __$SendOtpResponseCopyWithImpl<_SendOtpResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SendOtpResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendOtpResponse&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.deliveryMethod, deliveryMethod) || other.deliveryMethod == deliveryMethod)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,phoneNumber,deliveryMethod,expiresInSeconds,retryAfterSeconds);

@override
String toString() {
  return 'SendOtpResponse(requestId: $requestId, phoneNumber: $phoneNumber, deliveryMethod: $deliveryMethod, expiresInSeconds: $expiresInSeconds, retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class _$SendOtpResponseCopyWith<$Res> implements $SendOtpResponseCopyWith<$Res> {
  factory _$SendOtpResponseCopyWith(_SendOtpResponse value, $Res Function(_SendOtpResponse) _then) = __$SendOtpResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'delivery_method') String deliveryMethod,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'retry_after_seconds') int retryAfterSeconds
});




}
/// @nodoc
class __$SendOtpResponseCopyWithImpl<$Res>
    implements _$SendOtpResponseCopyWith<$Res> {
  __$SendOtpResponseCopyWithImpl(this._self, this._then);

  final _SendOtpResponse _self;
  final $Res Function(_SendOtpResponse) _then;

/// Create a copy of SendOtpResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? phoneNumber = null,Object? deliveryMethod = null,Object? expiresInSeconds = null,Object? retryAfterSeconds = null,}) {
  return _then(_SendOtpResponse(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,deliveryMethod: null == deliveryMethod ? _self.deliveryMethod : deliveryMethod // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,retryAfterSeconds: null == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VerifyOtpExistingUserResponse {

 String get status;@JsonKey(name: 'access_token') String get accessToken;@JsonKey(name: 'refresh_token') String get refreshToken;@JsonKey(name: 'expires_in_seconds') int get expiresInSeconds;@JsonKey(name: 'account_id') String get accountId;@JsonKey(name: 'account_status') String get accountStatus;@JsonKey(name: 'request_id') String? get requestId;@JsonKey(name: 'device_info') DeviceInfoDto? get deviceInfo;
/// Create a copy of VerifyOtpExistingUserResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpExistingUserResponseCopyWith<VerifyOtpExistingUserResponse> get copyWith => _$VerifyOtpExistingUserResponseCopyWithImpl<VerifyOtpExistingUserResponse>(this as VerifyOtpExistingUserResponse, _$identity);

  /// Serializes this VerifyOtpExistingUserResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpExistingUserResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountStatus, accountStatus) || other.accountStatus == accountStatus)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,accessToken,refreshToken,expiresInSeconds,accountId,accountStatus,requestId,deviceInfo);

@override
String toString() {
  return 'VerifyOtpExistingUserResponse(status: $status, accessToken: $accessToken, refreshToken: $refreshToken, expiresInSeconds: $expiresInSeconds, accountId: $accountId, accountStatus: $accountStatus, requestId: $requestId, deviceInfo: $deviceInfo)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpExistingUserResponseCopyWith<$Res>  {
  factory $VerifyOtpExistingUserResponseCopyWith(VerifyOtpExistingUserResponse value, $Res Function(VerifyOtpExistingUserResponse) _then) = _$VerifyOtpExistingUserResponseCopyWithImpl;
@useResult
$Res call({
 String status,@JsonKey(name: 'access_token') String accessToken,@JsonKey(name: 'refresh_token') String refreshToken,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'account_status') String accountStatus,@JsonKey(name: 'request_id') String? requestId,@JsonKey(name: 'device_info') DeviceInfoDto? deviceInfo
});


$DeviceInfoDtoCopyWith<$Res>? get deviceInfo;

}
/// @nodoc
class _$VerifyOtpExistingUserResponseCopyWithImpl<$Res>
    implements $VerifyOtpExistingUserResponseCopyWith<$Res> {
  _$VerifyOtpExistingUserResponseCopyWithImpl(this._self, this._then);

  final VerifyOtpExistingUserResponse _self;
  final $Res Function(VerifyOtpExistingUserResponse) _then;

/// Create a copy of VerifyOtpExistingUserResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? accessToken = null,Object? refreshToken = null,Object? expiresInSeconds = null,Object? accountId = null,Object? accountStatus = null,Object? requestId = freezed,Object? deviceInfo = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as DeviceInfoDto?,
  ));
}
/// Create a copy of VerifyOtpExistingUserResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoDtoCopyWith<$Res>? get deviceInfo {
    if (_self.deviceInfo == null) {
    return null;
  }

  return $DeviceInfoDtoCopyWith<$Res>(_self.deviceInfo!, (value) {
    return _then(_self.copyWith(deviceInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [VerifyOtpExistingUserResponse].
extension VerifyOtpExistingUserResponsePatterns on VerifyOtpExistingUserResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyOtpExistingUserResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyOtpExistingUserResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyOtpExistingUserResponse value)  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpExistingUserResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyOtpExistingUserResponse value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpExistingUserResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status, @JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'refresh_token')  String refreshToken, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'account_status')  String accountStatus, @JsonKey(name: 'request_id')  String? requestId, @JsonKey(name: 'device_info')  DeviceInfoDto? deviceInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyOtpExistingUserResponse() when $default != null:
return $default(_that.status,_that.accessToken,_that.refreshToken,_that.expiresInSeconds,_that.accountId,_that.accountStatus,_that.requestId,_that.deviceInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status, @JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'refresh_token')  String refreshToken, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'account_status')  String accountStatus, @JsonKey(name: 'request_id')  String? requestId, @JsonKey(name: 'device_info')  DeviceInfoDto? deviceInfo)  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpExistingUserResponse():
return $default(_that.status,_that.accessToken,_that.refreshToken,_that.expiresInSeconds,_that.accountId,_that.accountStatus,_that.requestId,_that.deviceInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status, @JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'refresh_token')  String refreshToken, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'account_status')  String accountStatus, @JsonKey(name: 'request_id')  String? requestId, @JsonKey(name: 'device_info')  DeviceInfoDto? deviceInfo)?  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpExistingUserResponse() when $default != null:
return $default(_that.status,_that.accessToken,_that.refreshToken,_that.expiresInSeconds,_that.accountId,_that.accountStatus,_that.requestId,_that.deviceInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyOtpExistingUserResponse implements VerifyOtpExistingUserResponse {
  const _VerifyOtpExistingUserResponse({required this.status, @JsonKey(name: 'access_token') required this.accessToken, @JsonKey(name: 'refresh_token') required this.refreshToken, @JsonKey(name: 'expires_in_seconds') required this.expiresInSeconds, @JsonKey(name: 'account_id') required this.accountId, @JsonKey(name: 'account_status') required this.accountStatus, @JsonKey(name: 'request_id') this.requestId, @JsonKey(name: 'device_info') this.deviceInfo});
  factory _VerifyOtpExistingUserResponse.fromJson(Map<String, dynamic> json) => _$VerifyOtpExistingUserResponseFromJson(json);

@override final  String status;
@override@JsonKey(name: 'access_token') final  String accessToken;
@override@JsonKey(name: 'refresh_token') final  String refreshToken;
@override@JsonKey(name: 'expires_in_seconds') final  int expiresInSeconds;
@override@JsonKey(name: 'account_id') final  String accountId;
@override@JsonKey(name: 'account_status') final  String accountStatus;
@override@JsonKey(name: 'request_id') final  String? requestId;
@override@JsonKey(name: 'device_info') final  DeviceInfoDto? deviceInfo;

/// Create a copy of VerifyOtpExistingUserResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyOtpExistingUserResponseCopyWith<_VerifyOtpExistingUserResponse> get copyWith => __$VerifyOtpExistingUserResponseCopyWithImpl<_VerifyOtpExistingUserResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyOtpExistingUserResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyOtpExistingUserResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountStatus, accountStatus) || other.accountStatus == accountStatus)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.deviceInfo, deviceInfo) || other.deviceInfo == deviceInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,accessToken,refreshToken,expiresInSeconds,accountId,accountStatus,requestId,deviceInfo);

@override
String toString() {
  return 'VerifyOtpExistingUserResponse(status: $status, accessToken: $accessToken, refreshToken: $refreshToken, expiresInSeconds: $expiresInSeconds, accountId: $accountId, accountStatus: $accountStatus, requestId: $requestId, deviceInfo: $deviceInfo)';
}


}

/// @nodoc
abstract mixin class _$VerifyOtpExistingUserResponseCopyWith<$Res> implements $VerifyOtpExistingUserResponseCopyWith<$Res> {
  factory _$VerifyOtpExistingUserResponseCopyWith(_VerifyOtpExistingUserResponse value, $Res Function(_VerifyOtpExistingUserResponse) _then) = __$VerifyOtpExistingUserResponseCopyWithImpl;
@override @useResult
$Res call({
 String status,@JsonKey(name: 'access_token') String accessToken,@JsonKey(name: 'refresh_token') String refreshToken,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'account_status') String accountStatus,@JsonKey(name: 'request_id') String? requestId,@JsonKey(name: 'device_info') DeviceInfoDto? deviceInfo
});


@override $DeviceInfoDtoCopyWith<$Res>? get deviceInfo;

}
/// @nodoc
class __$VerifyOtpExistingUserResponseCopyWithImpl<$Res>
    implements _$VerifyOtpExistingUserResponseCopyWith<$Res> {
  __$VerifyOtpExistingUserResponseCopyWithImpl(this._self, this._then);

  final _VerifyOtpExistingUserResponse _self;
  final $Res Function(_VerifyOtpExistingUserResponse) _then;

/// Create a copy of VerifyOtpExistingUserResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? accessToken = null,Object? refreshToken = null,Object? expiresInSeconds = null,Object? accountId = null,Object? accountStatus = null,Object? requestId = freezed,Object? deviceInfo = freezed,}) {
  return _then(_VerifyOtpExistingUserResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,accountStatus: null == accountStatus ? _self.accountStatus : accountStatus // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as DeviceInfoDto?,
  ));
}

/// Create a copy of VerifyOtpExistingUserResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeviceInfoDtoCopyWith<$Res>? get deviceInfo {
    if (_self.deviceInfo == null) {
    return null;
  }

  return $DeviceInfoDtoCopyWith<$Res>(_self.deviceInfo!, (value) {
    return _then(_self.copyWith(deviceInfo: value));
  });
}
}


/// @nodoc
mixin _$VerifyOtpNewUserResponse {

 String get status;@JsonKey(name: 'request_id') String get requestId;@JsonKey(name: 'phone_number') String get phoneNumber;@JsonKey(name: 'next_step') String get nextStep;@JsonKey(name: 'expires_in_seconds') int get expiresInSeconds;
/// Create a copy of VerifyOtpNewUserResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpNewUserResponseCopyWith<VerifyOtpNewUserResponse> get copyWith => _$VerifyOtpNewUserResponseCopyWithImpl<VerifyOtpNewUserResponse>(this as VerifyOtpNewUserResponse, _$identity);

  /// Serializes this VerifyOtpNewUserResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpNewUserResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.nextStep, nextStep) || other.nextStep == nextStep)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,requestId,phoneNumber,nextStep,expiresInSeconds);

@override
String toString() {
  return 'VerifyOtpNewUserResponse(status: $status, requestId: $requestId, phoneNumber: $phoneNumber, nextStep: $nextStep, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpNewUserResponseCopyWith<$Res>  {
  factory $VerifyOtpNewUserResponseCopyWith(VerifyOtpNewUserResponse value, $Res Function(VerifyOtpNewUserResponse) _then) = _$VerifyOtpNewUserResponseCopyWithImpl;
@useResult
$Res call({
 String status,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'next_step') String nextStep,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds
});




}
/// @nodoc
class _$VerifyOtpNewUserResponseCopyWithImpl<$Res>
    implements $VerifyOtpNewUserResponseCopyWith<$Res> {
  _$VerifyOtpNewUserResponseCopyWithImpl(this._self, this._then);

  final VerifyOtpNewUserResponse _self;
  final $Res Function(VerifyOtpNewUserResponse) _then;

/// Create a copy of VerifyOtpNewUserResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? requestId = null,Object? phoneNumber = null,Object? nextStep = null,Object? expiresInSeconds = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,nextStep: null == nextStep ? _self.nextStep : nextStep // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyOtpNewUserResponse].
extension VerifyOtpNewUserResponsePatterns on VerifyOtpNewUserResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyOtpNewUserResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyOtpNewUserResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyOtpNewUserResponse value)  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpNewUserResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyOtpNewUserResponse value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpNewUserResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'next_step')  String nextStep, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyOtpNewUserResponse() when $default != null:
return $default(_that.status,_that.requestId,_that.phoneNumber,_that.nextStep,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'next_step')  String nextStep, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpNewUserResponse():
return $default(_that.status,_that.requestId,_that.phoneNumber,_that.nextStep,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status, @JsonKey(name: 'request_id')  String requestId, @JsonKey(name: 'phone_number')  String phoneNumber, @JsonKey(name: 'next_step')  String nextStep, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpNewUserResponse() when $default != null:
return $default(_that.status,_that.requestId,_that.phoneNumber,_that.nextStep,_that.expiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyOtpNewUserResponse implements VerifyOtpNewUserResponse {
  const _VerifyOtpNewUserResponse({required this.status, @JsonKey(name: 'request_id') required this.requestId, @JsonKey(name: 'phone_number') required this.phoneNumber, @JsonKey(name: 'next_step') required this.nextStep, @JsonKey(name: 'expires_in_seconds') required this.expiresInSeconds});
  factory _VerifyOtpNewUserResponse.fromJson(Map<String, dynamic> json) => _$VerifyOtpNewUserResponseFromJson(json);

@override final  String status;
@override@JsonKey(name: 'request_id') final  String requestId;
@override@JsonKey(name: 'phone_number') final  String phoneNumber;
@override@JsonKey(name: 'next_step') final  String nextStep;
@override@JsonKey(name: 'expires_in_seconds') final  int expiresInSeconds;

/// Create a copy of VerifyOtpNewUserResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyOtpNewUserResponseCopyWith<_VerifyOtpNewUserResponse> get copyWith => __$VerifyOtpNewUserResponseCopyWithImpl<_VerifyOtpNewUserResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyOtpNewUserResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyOtpNewUserResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.nextStep, nextStep) || other.nextStep == nextStep)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,requestId,phoneNumber,nextStep,expiresInSeconds);

@override
String toString() {
  return 'VerifyOtpNewUserResponse(status: $status, requestId: $requestId, phoneNumber: $phoneNumber, nextStep: $nextStep, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$VerifyOtpNewUserResponseCopyWith<$Res> implements $VerifyOtpNewUserResponseCopyWith<$Res> {
  factory _$VerifyOtpNewUserResponseCopyWith(_VerifyOtpNewUserResponse value, $Res Function(_VerifyOtpNewUserResponse) _then) = __$VerifyOtpNewUserResponseCopyWithImpl;
@override @useResult
$Res call({
 String status,@JsonKey(name: 'request_id') String requestId,@JsonKey(name: 'phone_number') String phoneNumber,@JsonKey(name: 'next_step') String nextStep,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds
});




}
/// @nodoc
class __$VerifyOtpNewUserResponseCopyWithImpl<$Res>
    implements _$VerifyOtpNewUserResponseCopyWith<$Res> {
  __$VerifyOtpNewUserResponseCopyWithImpl(this._self, this._then);

  final _VerifyOtpNewUserResponse _self;
  final $Res Function(_VerifyOtpNewUserResponse) _then;

/// Create a copy of VerifyOtpNewUserResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? requestId = null,Object? phoneNumber = null,Object? nextStep = null,Object? expiresInSeconds = null,}) {
  return _then(_VerifyOtpNewUserResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,nextStep: null == nextStep ? _self.nextStep : nextStep // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VerifyOtpErrorResponse {

@JsonKey(name: 'error_code') String get errorCode; String get message;@JsonKey(name: 'remaining_attempts') int? get remainingAttempts;@JsonKey(name: 'lockout_until') String? get lockoutUntil;
/// Create a copy of VerifyOtpErrorResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyOtpErrorResponseCopyWith<VerifyOtpErrorResponse> get copyWith => _$VerifyOtpErrorResponseCopyWithImpl<VerifyOtpErrorResponse>(this as VerifyOtpErrorResponse, _$identity);

  /// Serializes this VerifyOtpErrorResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyOtpErrorResponse&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.message, message) || other.message == message)&&(identical(other.remainingAttempts, remainingAttempts) || other.remainingAttempts == remainingAttempts)&&(identical(other.lockoutUntil, lockoutUntil) || other.lockoutUntil == lockoutUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,errorCode,message,remainingAttempts,lockoutUntil);

@override
String toString() {
  return 'VerifyOtpErrorResponse(errorCode: $errorCode, message: $message, remainingAttempts: $remainingAttempts, lockoutUntil: $lockoutUntil)';
}


}

/// @nodoc
abstract mixin class $VerifyOtpErrorResponseCopyWith<$Res>  {
  factory $VerifyOtpErrorResponseCopyWith(VerifyOtpErrorResponse value, $Res Function(VerifyOtpErrorResponse) _then) = _$VerifyOtpErrorResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'error_code') String errorCode, String message,@JsonKey(name: 'remaining_attempts') int? remainingAttempts,@JsonKey(name: 'lockout_until') String? lockoutUntil
});




}
/// @nodoc
class _$VerifyOtpErrorResponseCopyWithImpl<$Res>
    implements $VerifyOtpErrorResponseCopyWith<$Res> {
  _$VerifyOtpErrorResponseCopyWithImpl(this._self, this._then);

  final VerifyOtpErrorResponse _self;
  final $Res Function(VerifyOtpErrorResponse) _then;

/// Create a copy of VerifyOtpErrorResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? errorCode = null,Object? message = null,Object? remainingAttempts = freezed,Object? lockoutUntil = freezed,}) {
  return _then(_self.copyWith(
errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,remainingAttempts: freezed == remainingAttempts ? _self.remainingAttempts : remainingAttempts // ignore: cast_nullable_to_non_nullable
as int?,lockoutUntil: freezed == lockoutUntil ? _self.lockoutUntil : lockoutUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyOtpErrorResponse].
extension VerifyOtpErrorResponsePatterns on VerifyOtpErrorResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyOtpErrorResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyOtpErrorResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyOtpErrorResponse value)  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpErrorResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyOtpErrorResponse value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyOtpErrorResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'error_code')  String errorCode,  String message, @JsonKey(name: 'remaining_attempts')  int? remainingAttempts, @JsonKey(name: 'lockout_until')  String? lockoutUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyOtpErrorResponse() when $default != null:
return $default(_that.errorCode,_that.message,_that.remainingAttempts,_that.lockoutUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'error_code')  String errorCode,  String message, @JsonKey(name: 'remaining_attempts')  int? remainingAttempts, @JsonKey(name: 'lockout_until')  String? lockoutUntil)  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpErrorResponse():
return $default(_that.errorCode,_that.message,_that.remainingAttempts,_that.lockoutUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'error_code')  String errorCode,  String message, @JsonKey(name: 'remaining_attempts')  int? remainingAttempts, @JsonKey(name: 'lockout_until')  String? lockoutUntil)?  $default,) {final _that = this;
switch (_that) {
case _VerifyOtpErrorResponse() when $default != null:
return $default(_that.errorCode,_that.message,_that.remainingAttempts,_that.lockoutUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyOtpErrorResponse implements VerifyOtpErrorResponse {
  const _VerifyOtpErrorResponse({@JsonKey(name: 'error_code') required this.errorCode, required this.message, @JsonKey(name: 'remaining_attempts') this.remainingAttempts, @JsonKey(name: 'lockout_until') this.lockoutUntil});
  factory _VerifyOtpErrorResponse.fromJson(Map<String, dynamic> json) => _$VerifyOtpErrorResponseFromJson(json);

@override@JsonKey(name: 'error_code') final  String errorCode;
@override final  String message;
@override@JsonKey(name: 'remaining_attempts') final  int? remainingAttempts;
@override@JsonKey(name: 'lockout_until') final  String? lockoutUntil;

/// Create a copy of VerifyOtpErrorResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyOtpErrorResponseCopyWith<_VerifyOtpErrorResponse> get copyWith => __$VerifyOtpErrorResponseCopyWithImpl<_VerifyOtpErrorResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyOtpErrorResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyOtpErrorResponse&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.message, message) || other.message == message)&&(identical(other.remainingAttempts, remainingAttempts) || other.remainingAttempts == remainingAttempts)&&(identical(other.lockoutUntil, lockoutUntil) || other.lockoutUntil == lockoutUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,errorCode,message,remainingAttempts,lockoutUntil);

@override
String toString() {
  return 'VerifyOtpErrorResponse(errorCode: $errorCode, message: $message, remainingAttempts: $remainingAttempts, lockoutUntil: $lockoutUntil)';
}


}

/// @nodoc
abstract mixin class _$VerifyOtpErrorResponseCopyWith<$Res> implements $VerifyOtpErrorResponseCopyWith<$Res> {
  factory _$VerifyOtpErrorResponseCopyWith(_VerifyOtpErrorResponse value, $Res Function(_VerifyOtpErrorResponse) _then) = __$VerifyOtpErrorResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'error_code') String errorCode, String message,@JsonKey(name: 'remaining_attempts') int? remainingAttempts,@JsonKey(name: 'lockout_until') String? lockoutUntil
});




}
/// @nodoc
class __$VerifyOtpErrorResponseCopyWithImpl<$Res>
    implements _$VerifyOtpErrorResponseCopyWith<$Res> {
  __$VerifyOtpErrorResponseCopyWithImpl(this._self, this._then);

  final _VerifyOtpErrorResponse _self;
  final $Res Function(_VerifyOtpErrorResponse) _then;

/// Create a copy of VerifyOtpErrorResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? errorCode = null,Object? message = null,Object? remainingAttempts = freezed,Object? lockoutUntil = freezed,}) {
  return _then(_VerifyOtpErrorResponse(
errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,remainingAttempts: freezed == remainingAttempts ? _self.remainingAttempts : remainingAttempts // ignore: cast_nullable_to_non_nullable
as int?,lockoutUntil: freezed == lockoutUntil ? _self.lockoutUntil : lockoutUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RefreshTokenResponse {

@JsonKey(name: 'access_token') String get accessToken;@JsonKey(name: 'refresh_token') String get refreshToken;@JsonKey(name: 'expires_in_seconds') int get expiresInSeconds;@JsonKey(name: 'device_status') String get deviceStatus;
/// Create a copy of RefreshTokenResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshTokenResponseCopyWith<RefreshTokenResponse> get copyWith => _$RefreshTokenResponseCopyWithImpl<RefreshTokenResponse>(this as RefreshTokenResponse, _$identity);

  /// Serializes this RefreshTokenResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshTokenResponse&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.deviceStatus, deviceStatus) || other.deviceStatus == deviceStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresInSeconds,deviceStatus);

@override
String toString() {
  return 'RefreshTokenResponse(accessToken: $accessToken, refreshToken: $refreshToken, expiresInSeconds: $expiresInSeconds, deviceStatus: $deviceStatus)';
}


}

/// @nodoc
abstract mixin class $RefreshTokenResponseCopyWith<$Res>  {
  factory $RefreshTokenResponseCopyWith(RefreshTokenResponse value, $Res Function(RefreshTokenResponse) _then) = _$RefreshTokenResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'access_token') String accessToken,@JsonKey(name: 'refresh_token') String refreshToken,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'device_status') String deviceStatus
});




}
/// @nodoc
class _$RefreshTokenResponseCopyWithImpl<$Res>
    implements $RefreshTokenResponseCopyWith<$Res> {
  _$RefreshTokenResponseCopyWithImpl(this._self, this._then);

  final RefreshTokenResponse _self;
  final $Res Function(RefreshTokenResponse) _then;

/// Create a copy of RefreshTokenResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresInSeconds = null,Object? deviceStatus = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,deviceStatus: null == deviceStatus ? _self.deviceStatus : deviceStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RefreshTokenResponse].
extension RefreshTokenResponsePatterns on RefreshTokenResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefreshTokenResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefreshTokenResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefreshTokenResponse value)  $default,){
final _that = this;
switch (_that) {
case _RefreshTokenResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefreshTokenResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RefreshTokenResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'refresh_token')  String refreshToken, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'device_status')  String deviceStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefreshTokenResponse() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresInSeconds,_that.deviceStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'refresh_token')  String refreshToken, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'device_status')  String deviceStatus)  $default,) {final _that = this;
switch (_that) {
case _RefreshTokenResponse():
return $default(_that.accessToken,_that.refreshToken,_that.expiresInSeconds,_that.deviceStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'refresh_token')  String refreshToken, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'device_status')  String deviceStatus)?  $default,) {final _that = this;
switch (_that) {
case _RefreshTokenResponse() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresInSeconds,_that.deviceStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RefreshTokenResponse implements RefreshTokenResponse {
  const _RefreshTokenResponse({@JsonKey(name: 'access_token') required this.accessToken, @JsonKey(name: 'refresh_token') required this.refreshToken, @JsonKey(name: 'expires_in_seconds') required this.expiresInSeconds, @JsonKey(name: 'device_status') required this.deviceStatus});
  factory _RefreshTokenResponse.fromJson(Map<String, dynamic> json) => _$RefreshTokenResponseFromJson(json);

@override@JsonKey(name: 'access_token') final  String accessToken;
@override@JsonKey(name: 'refresh_token') final  String refreshToken;
@override@JsonKey(name: 'expires_in_seconds') final  int expiresInSeconds;
@override@JsonKey(name: 'device_status') final  String deviceStatus;

/// Create a copy of RefreshTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshTokenResponseCopyWith<_RefreshTokenResponse> get copyWith => __$RefreshTokenResponseCopyWithImpl<_RefreshTokenResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RefreshTokenResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshTokenResponse&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.deviceStatus, deviceStatus) || other.deviceStatus == deviceStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresInSeconds,deviceStatus);

@override
String toString() {
  return 'RefreshTokenResponse(accessToken: $accessToken, refreshToken: $refreshToken, expiresInSeconds: $expiresInSeconds, deviceStatus: $deviceStatus)';
}


}

/// @nodoc
abstract mixin class _$RefreshTokenResponseCopyWith<$Res> implements $RefreshTokenResponseCopyWith<$Res> {
  factory _$RefreshTokenResponseCopyWith(_RefreshTokenResponse value, $Res Function(_RefreshTokenResponse) _then) = __$RefreshTokenResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'access_token') String accessToken,@JsonKey(name: 'refresh_token') String refreshToken,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'device_status') String deviceStatus
});




}
/// @nodoc
class __$RefreshTokenResponseCopyWithImpl<$Res>
    implements _$RefreshTokenResponseCopyWith<$Res> {
  __$RefreshTokenResponseCopyWithImpl(this._self, this._then);

  final _RefreshTokenResponse _self;
  final $Res Function(_RefreshTokenResponse) _then;

/// Create a copy of RefreshTokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresInSeconds = null,Object? deviceStatus = null,}) {
  return _then(_RefreshTokenResponse(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,deviceStatus: null == deviceStatus ? _self.deviceStatus : deviceStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RegisterBiometricResponse {

@JsonKey(name: 'device_id') String get deviceId;@JsonKey(name: 'biometric_type') String get biometricType;@JsonKey(name: 'registered_at') String get registeredAt; String get status;
/// Create a copy of RegisterBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterBiometricResponseCopyWith<RegisterBiometricResponse> get copyWith => _$RegisterBiometricResponseCopyWithImpl<RegisterBiometricResponse>(this as RegisterBiometricResponse, _$identity);

  /// Serializes this RegisterBiometricResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterBiometricResponse&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,biometricType,registeredAt,status);

@override
String toString() {
  return 'RegisterBiometricResponse(deviceId: $deviceId, biometricType: $biometricType, registeredAt: $registeredAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $RegisterBiometricResponseCopyWith<$Res>  {
  factory $RegisterBiometricResponseCopyWith(RegisterBiometricResponse value, $Res Function(RegisterBiometricResponse) _then) = _$RegisterBiometricResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'biometric_type') String biometricType,@JsonKey(name: 'registered_at') String registeredAt, String status
});




}
/// @nodoc
class _$RegisterBiometricResponseCopyWithImpl<$Res>
    implements $RegisterBiometricResponseCopyWith<$Res> {
  _$RegisterBiometricResponseCopyWithImpl(this._self, this._then);

  final RegisterBiometricResponse _self;
  final $Res Function(RegisterBiometricResponse) _then;

/// Create a copy of RegisterBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? biometricType = null,Object? registeredAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,biometricType: null == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterBiometricResponse].
extension RegisterBiometricResponsePatterns on RegisterBiometricResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterBiometricResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterBiometricResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterBiometricResponse value)  $default,){
final _that = this;
switch (_that) {
case _RegisterBiometricResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterBiometricResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterBiometricResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'biometric_type')  String biometricType, @JsonKey(name: 'registered_at')  String registeredAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterBiometricResponse() when $default != null:
return $default(_that.deviceId,_that.biometricType,_that.registeredAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'biometric_type')  String biometricType, @JsonKey(name: 'registered_at')  String registeredAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _RegisterBiometricResponse():
return $default(_that.deviceId,_that.biometricType,_that.registeredAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'biometric_type')  String biometricType, @JsonKey(name: 'registered_at')  String registeredAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _RegisterBiometricResponse() when $default != null:
return $default(_that.deviceId,_that.biometricType,_that.registeredAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisterBiometricResponse implements RegisterBiometricResponse {
  const _RegisterBiometricResponse({@JsonKey(name: 'device_id') required this.deviceId, @JsonKey(name: 'biometric_type') required this.biometricType, @JsonKey(name: 'registered_at') required this.registeredAt, required this.status});
  factory _RegisterBiometricResponse.fromJson(Map<String, dynamic> json) => _$RegisterBiometricResponseFromJson(json);

@override@JsonKey(name: 'device_id') final  String deviceId;
@override@JsonKey(name: 'biometric_type') final  String biometricType;
@override@JsonKey(name: 'registered_at') final  String registeredAt;
@override final  String status;

/// Create a copy of RegisterBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterBiometricResponseCopyWith<_RegisterBiometricResponse> get copyWith => __$RegisterBiometricResponseCopyWithImpl<_RegisterBiometricResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisterBiometricResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterBiometricResponse&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,biometricType,registeredAt,status);

@override
String toString() {
  return 'RegisterBiometricResponse(deviceId: $deviceId, biometricType: $biometricType, registeredAt: $registeredAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$RegisterBiometricResponseCopyWith<$Res> implements $RegisterBiometricResponseCopyWith<$Res> {
  factory _$RegisterBiometricResponseCopyWith(_RegisterBiometricResponse value, $Res Function(_RegisterBiometricResponse) _then) = __$RegisterBiometricResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'biometric_type') String biometricType,@JsonKey(name: 'registered_at') String registeredAt, String status
});




}
/// @nodoc
class __$RegisterBiometricResponseCopyWithImpl<$Res>
    implements _$RegisterBiometricResponseCopyWith<$Res> {
  __$RegisterBiometricResponseCopyWithImpl(this._self, this._then);

  final _RegisterBiometricResponse _self;
  final $Res Function(_RegisterBiometricResponse) _then;

/// Create a copy of RegisterBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? biometricType = null,Object? registeredAt = null,Object? status = null,}) {
  return _then(_RegisterBiometricResponse(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,biometricType: null == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String,registeredAt: null == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VerifyBiometricResponse {

 String get operation; bool get verified;@JsonKey(name: 'verification_token') String get verificationToken;
/// Create a copy of VerifyBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyBiometricResponseCopyWith<VerifyBiometricResponse> get copyWith => _$VerifyBiometricResponseCopyWithImpl<VerifyBiometricResponse>(this as VerifyBiometricResponse, _$identity);

  /// Serializes this VerifyBiometricResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyBiometricResponse&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.verificationToken, verificationToken) || other.verificationToken == verificationToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operation,verified,verificationToken);

@override
String toString() {
  return 'VerifyBiometricResponse(operation: $operation, verified: $verified, verificationToken: $verificationToken)';
}


}

/// @nodoc
abstract mixin class $VerifyBiometricResponseCopyWith<$Res>  {
  factory $VerifyBiometricResponseCopyWith(VerifyBiometricResponse value, $Res Function(VerifyBiometricResponse) _then) = _$VerifyBiometricResponseCopyWithImpl;
@useResult
$Res call({
 String operation, bool verified,@JsonKey(name: 'verification_token') String verificationToken
});




}
/// @nodoc
class _$VerifyBiometricResponseCopyWithImpl<$Res>
    implements $VerifyBiometricResponseCopyWith<$Res> {
  _$VerifyBiometricResponseCopyWithImpl(this._self, this._then);

  final VerifyBiometricResponse _self;
  final $Res Function(VerifyBiometricResponse) _then;

/// Create a copy of VerifyBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operation = null,Object? verified = null,Object? verificationToken = null,}) {
  return _then(_self.copyWith(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,verificationToken: null == verificationToken ? _self.verificationToken : verificationToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyBiometricResponse].
extension VerifyBiometricResponsePatterns on VerifyBiometricResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyBiometricResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyBiometricResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyBiometricResponse value)  $default,){
final _that = this;
switch (_that) {
case _VerifyBiometricResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyBiometricResponse value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyBiometricResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String operation,  bool verified, @JsonKey(name: 'verification_token')  String verificationToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyBiometricResponse() when $default != null:
return $default(_that.operation,_that.verified,_that.verificationToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String operation,  bool verified, @JsonKey(name: 'verification_token')  String verificationToken)  $default,) {final _that = this;
switch (_that) {
case _VerifyBiometricResponse():
return $default(_that.operation,_that.verified,_that.verificationToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String operation,  bool verified, @JsonKey(name: 'verification_token')  String verificationToken)?  $default,) {final _that = this;
switch (_that) {
case _VerifyBiometricResponse() when $default != null:
return $default(_that.operation,_that.verified,_that.verificationToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerifyBiometricResponse implements VerifyBiometricResponse {
  const _VerifyBiometricResponse({required this.operation, required this.verified, @JsonKey(name: 'verification_token') required this.verificationToken});
  factory _VerifyBiometricResponse.fromJson(Map<String, dynamic> json) => _$VerifyBiometricResponseFromJson(json);

@override final  String operation;
@override final  bool verified;
@override@JsonKey(name: 'verification_token') final  String verificationToken;

/// Create a copy of VerifyBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyBiometricResponseCopyWith<_VerifyBiometricResponse> get copyWith => __$VerifyBiometricResponseCopyWithImpl<_VerifyBiometricResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerifyBiometricResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyBiometricResponse&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.verificationToken, verificationToken) || other.verificationToken == verificationToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operation,verified,verificationToken);

@override
String toString() {
  return 'VerifyBiometricResponse(operation: $operation, verified: $verified, verificationToken: $verificationToken)';
}


}

/// @nodoc
abstract mixin class _$VerifyBiometricResponseCopyWith<$Res> implements $VerifyBiometricResponseCopyWith<$Res> {
  factory _$VerifyBiometricResponseCopyWith(_VerifyBiometricResponse value, $Res Function(_VerifyBiometricResponse) _then) = __$VerifyBiometricResponseCopyWithImpl;
@override @useResult
$Res call({
 String operation, bool verified,@JsonKey(name: 'verification_token') String verificationToken
});




}
/// @nodoc
class __$VerifyBiometricResponseCopyWithImpl<$Res>
    implements _$VerifyBiometricResponseCopyWith<$Res> {
  __$VerifyBiometricResponseCopyWithImpl(this._self, this._then);

  final _VerifyBiometricResponse _self;
  final $Res Function(_VerifyBiometricResponse) _then;

/// Create a copy of VerifyBiometricResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? verified = null,Object? verificationToken = null,}) {
  return _then(_VerifyBiometricResponse(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,verificationToken: null == verificationToken ? _self.verificationToken : verificationToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DeviceInfoDto {

@JsonKey(name: 'device_id') String get deviceId;@JsonKey(name: 'device_name') String get deviceName;@JsonKey(name: 'os_type') String get osType;@JsonKey(name: 'login_time') String get loginTime; String get status;@JsonKey(name: 'last_activity_time') String? get lastActivityTime;@JsonKey(name: 'location_country') String? get locationCountry;@JsonKey(name: 'location_city') String? get locationCity;@JsonKey(name: 'is_current_device') bool? get isCurrentDevice;@JsonKey(name: 'biometric_registered') bool? get biometricRegistered;@JsonKey(name: 'biometric_type') String? get biometricType;
/// Create a copy of DeviceInfoDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoDtoCopyWith<DeviceInfoDto> get copyWith => _$DeviceInfoDtoCopyWithImpl<DeviceInfoDto>(this as DeviceInfoDto, _$identity);

  /// Serializes this DeviceInfoDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfoDto&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.osType, osType) || other.osType == osType)&&(identical(other.loginTime, loginTime) || other.loginTime == loginTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastActivityTime, lastActivityTime) || other.lastActivityTime == lastActivityTime)&&(identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry)&&(identical(other.locationCity, locationCity) || other.locationCity == locationCity)&&(identical(other.isCurrentDevice, isCurrentDevice) || other.isCurrentDevice == isCurrentDevice)&&(identical(other.biometricRegistered, biometricRegistered) || other.biometricRegistered == biometricRegistered)&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,osType,loginTime,status,lastActivityTime,locationCountry,locationCity,isCurrentDevice,biometricRegistered,biometricType);

@override
String toString() {
  return 'DeviceInfoDto(deviceId: $deviceId, deviceName: $deviceName, osType: $osType, loginTime: $loginTime, status: $status, lastActivityTime: $lastActivityTime, locationCountry: $locationCountry, locationCity: $locationCity, isCurrentDevice: $isCurrentDevice, biometricRegistered: $biometricRegistered, biometricType: $biometricType)';
}


}

/// @nodoc
abstract mixin class $DeviceInfoDtoCopyWith<$Res>  {
  factory $DeviceInfoDtoCopyWith(DeviceInfoDto value, $Res Function(DeviceInfoDto) _then) = _$DeviceInfoDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'device_name') String deviceName,@JsonKey(name: 'os_type') String osType,@JsonKey(name: 'login_time') String loginTime, String status,@JsonKey(name: 'last_activity_time') String? lastActivityTime,@JsonKey(name: 'location_country') String? locationCountry,@JsonKey(name: 'location_city') String? locationCity,@JsonKey(name: 'is_current_device') bool? isCurrentDevice,@JsonKey(name: 'biometric_registered') bool? biometricRegistered,@JsonKey(name: 'biometric_type') String? biometricType
});




}
/// @nodoc
class _$DeviceInfoDtoCopyWithImpl<$Res>
    implements $DeviceInfoDtoCopyWith<$Res> {
  _$DeviceInfoDtoCopyWithImpl(this._self, this._then);

  final DeviceInfoDto _self;
  final $Res Function(DeviceInfoDto) _then;

/// Create a copy of DeviceInfoDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceName = null,Object? osType = null,Object? loginTime = null,Object? status = null,Object? lastActivityTime = freezed,Object? locationCountry = freezed,Object? locationCity = freezed,Object? isCurrentDevice = freezed,Object? biometricRegistered = freezed,Object? biometricType = freezed,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,osType: null == osType ? _self.osType : osType // ignore: cast_nullable_to_non_nullable
as String,loginTime: null == loginTime ? _self.loginTime : loginTime // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastActivityTime: freezed == lastActivityTime ? _self.lastActivityTime : lastActivityTime // ignore: cast_nullable_to_non_nullable
as String?,locationCountry: freezed == locationCountry ? _self.locationCountry : locationCountry // ignore: cast_nullable_to_non_nullable
as String?,locationCity: freezed == locationCity ? _self.locationCity : locationCity // ignore: cast_nullable_to_non_nullable
as String?,isCurrentDevice: freezed == isCurrentDevice ? _self.isCurrentDevice : isCurrentDevice // ignore: cast_nullable_to_non_nullable
as bool?,biometricRegistered: freezed == biometricRegistered ? _self.biometricRegistered : biometricRegistered // ignore: cast_nullable_to_non_nullable
as bool?,biometricType: freezed == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceInfoDto].
extension DeviceInfoDtoPatterns on DeviceInfoDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfoDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfoDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfoDto value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfoDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfoDto value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfoDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'device_name')  String deviceName, @JsonKey(name: 'os_type')  String osType, @JsonKey(name: 'login_time')  String loginTime,  String status, @JsonKey(name: 'last_activity_time')  String? lastActivityTime, @JsonKey(name: 'location_country')  String? locationCountry, @JsonKey(name: 'location_city')  String? locationCity, @JsonKey(name: 'is_current_device')  bool? isCurrentDevice, @JsonKey(name: 'biometric_registered')  bool? biometricRegistered, @JsonKey(name: 'biometric_type')  String? biometricType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfoDto() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.osType,_that.loginTime,_that.status,_that.lastActivityTime,_that.locationCountry,_that.locationCity,_that.isCurrentDevice,_that.biometricRegistered,_that.biometricType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'device_name')  String deviceName, @JsonKey(name: 'os_type')  String osType, @JsonKey(name: 'login_time')  String loginTime,  String status, @JsonKey(name: 'last_activity_time')  String? lastActivityTime, @JsonKey(name: 'location_country')  String? locationCountry, @JsonKey(name: 'location_city')  String? locationCity, @JsonKey(name: 'is_current_device')  bool? isCurrentDevice, @JsonKey(name: 'biometric_registered')  bool? biometricRegistered, @JsonKey(name: 'biometric_type')  String? biometricType)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfoDto():
return $default(_that.deviceId,_that.deviceName,_that.osType,_that.loginTime,_that.status,_that.lastActivityTime,_that.locationCountry,_that.locationCity,_that.isCurrentDevice,_that.biometricRegistered,_that.biometricType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'device_name')  String deviceName, @JsonKey(name: 'os_type')  String osType, @JsonKey(name: 'login_time')  String loginTime,  String status, @JsonKey(name: 'last_activity_time')  String? lastActivityTime, @JsonKey(name: 'location_country')  String? locationCountry, @JsonKey(name: 'location_city')  String? locationCity, @JsonKey(name: 'is_current_device')  bool? isCurrentDevice, @JsonKey(name: 'biometric_registered')  bool? biometricRegistered, @JsonKey(name: 'biometric_type')  String? biometricType)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfoDto() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.osType,_that.loginTime,_that.status,_that.lastActivityTime,_that.locationCountry,_that.locationCity,_that.isCurrentDevice,_that.biometricRegistered,_that.biometricType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceInfoDto implements DeviceInfoDto {
  const _DeviceInfoDto({@JsonKey(name: 'device_id') required this.deviceId, @JsonKey(name: 'device_name') required this.deviceName, @JsonKey(name: 'os_type') required this.osType, @JsonKey(name: 'login_time') required this.loginTime, required this.status, @JsonKey(name: 'last_activity_time') this.lastActivityTime, @JsonKey(name: 'location_country') this.locationCountry, @JsonKey(name: 'location_city') this.locationCity, @JsonKey(name: 'is_current_device') this.isCurrentDevice, @JsonKey(name: 'biometric_registered') this.biometricRegistered, @JsonKey(name: 'biometric_type') this.biometricType});
  factory _DeviceInfoDto.fromJson(Map<String, dynamic> json) => _$DeviceInfoDtoFromJson(json);

@override@JsonKey(name: 'device_id') final  String deviceId;
@override@JsonKey(name: 'device_name') final  String deviceName;
@override@JsonKey(name: 'os_type') final  String osType;
@override@JsonKey(name: 'login_time') final  String loginTime;
@override final  String status;
@override@JsonKey(name: 'last_activity_time') final  String? lastActivityTime;
@override@JsonKey(name: 'location_country') final  String? locationCountry;
@override@JsonKey(name: 'location_city') final  String? locationCity;
@override@JsonKey(name: 'is_current_device') final  bool? isCurrentDevice;
@override@JsonKey(name: 'biometric_registered') final  bool? biometricRegistered;
@override@JsonKey(name: 'biometric_type') final  String? biometricType;

/// Create a copy of DeviceInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoDtoCopyWith<_DeviceInfoDto> get copyWith => __$DeviceInfoDtoCopyWithImpl<_DeviceInfoDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceInfoDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfoDto&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.osType, osType) || other.osType == osType)&&(identical(other.loginTime, loginTime) || other.loginTime == loginTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastActivityTime, lastActivityTime) || other.lastActivityTime == lastActivityTime)&&(identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry)&&(identical(other.locationCity, locationCity) || other.locationCity == locationCity)&&(identical(other.isCurrentDevice, isCurrentDevice) || other.isCurrentDevice == isCurrentDevice)&&(identical(other.biometricRegistered, biometricRegistered) || other.biometricRegistered == biometricRegistered)&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,osType,loginTime,status,lastActivityTime,locationCountry,locationCity,isCurrentDevice,biometricRegistered,biometricType);

@override
String toString() {
  return 'DeviceInfoDto(deviceId: $deviceId, deviceName: $deviceName, osType: $osType, loginTime: $loginTime, status: $status, lastActivityTime: $lastActivityTime, locationCountry: $locationCountry, locationCity: $locationCity, isCurrentDevice: $isCurrentDevice, biometricRegistered: $biometricRegistered, biometricType: $biometricType)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoDtoCopyWith<$Res> implements $DeviceInfoDtoCopyWith<$Res> {
  factory _$DeviceInfoDtoCopyWith(_DeviceInfoDto value, $Res Function(_DeviceInfoDto) _then) = __$DeviceInfoDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'device_name') String deviceName,@JsonKey(name: 'os_type') String osType,@JsonKey(name: 'login_time') String loginTime, String status,@JsonKey(name: 'last_activity_time') String? lastActivityTime,@JsonKey(name: 'location_country') String? locationCountry,@JsonKey(name: 'location_city') String? locationCity,@JsonKey(name: 'is_current_device') bool? isCurrentDevice,@JsonKey(name: 'biometric_registered') bool? biometricRegistered,@JsonKey(name: 'biometric_type') String? biometricType
});




}
/// @nodoc
class __$DeviceInfoDtoCopyWithImpl<$Res>
    implements _$DeviceInfoDtoCopyWith<$Res> {
  __$DeviceInfoDtoCopyWithImpl(this._self, this._then);

  final _DeviceInfoDto _self;
  final $Res Function(_DeviceInfoDto) _then;

/// Create a copy of DeviceInfoDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceName = null,Object? osType = null,Object? loginTime = null,Object? status = null,Object? lastActivityTime = freezed,Object? locationCountry = freezed,Object? locationCity = freezed,Object? isCurrentDevice = freezed,Object? biometricRegistered = freezed,Object? biometricType = freezed,}) {
  return _then(_DeviceInfoDto(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,osType: null == osType ? _self.osType : osType // ignore: cast_nullable_to_non_nullable
as String,loginTime: null == loginTime ? _self.loginTime : loginTime // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastActivityTime: freezed == lastActivityTime ? _self.lastActivityTime : lastActivityTime // ignore: cast_nullable_to_non_nullable
as String?,locationCountry: freezed == locationCountry ? _self.locationCountry : locationCountry // ignore: cast_nullable_to_non_nullable
as String?,locationCity: freezed == locationCity ? _self.locationCity : locationCity // ignore: cast_nullable_to_non_nullable
as String?,isCurrentDevice: freezed == isCurrentDevice ? _self.isCurrentDevice : isCurrentDevice // ignore: cast_nullable_to_non_nullable
as bool?,biometricRegistered: freezed == biometricRegistered ? _self.biometricRegistered : biometricRegistered // ignore: cast_nullable_to_non_nullable
as bool?,biometricType: freezed == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DevicesListResponse {

 List<DeviceInfoDto> get devices;
/// Create a copy of DevicesListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DevicesListResponseCopyWith<DevicesListResponse> get copyWith => _$DevicesListResponseCopyWithImpl<DevicesListResponse>(this as DevicesListResponse, _$identity);

  /// Serializes this DevicesListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicesListResponse&&const DeepCollectionEquality().equals(other.devices, devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(devices));

@override
String toString() {
  return 'DevicesListResponse(devices: $devices)';
}


}

/// @nodoc
abstract mixin class $DevicesListResponseCopyWith<$Res>  {
  factory $DevicesListResponseCopyWith(DevicesListResponse value, $Res Function(DevicesListResponse) _then) = _$DevicesListResponseCopyWithImpl;
@useResult
$Res call({
 List<DeviceInfoDto> devices
});




}
/// @nodoc
class _$DevicesListResponseCopyWithImpl<$Res>
    implements $DevicesListResponseCopyWith<$Res> {
  _$DevicesListResponseCopyWithImpl(this._self, this._then);

  final DevicesListResponse _self;
  final $Res Function(DevicesListResponse) _then;

/// Create a copy of DevicesListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? devices = null,}) {
  return _then(_self.copyWith(
devices: null == devices ? _self.devices : devices // ignore: cast_nullable_to_non_nullable
as List<DeviceInfoDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [DevicesListResponse].
extension DevicesListResponsePatterns on DevicesListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DevicesListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DevicesListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DevicesListResponse value)  $default,){
final _that = this;
switch (_that) {
case _DevicesListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DevicesListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DevicesListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DeviceInfoDto> devices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DevicesListResponse() when $default != null:
return $default(_that.devices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DeviceInfoDto> devices)  $default,) {final _that = this;
switch (_that) {
case _DevicesListResponse():
return $default(_that.devices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DeviceInfoDto> devices)?  $default,) {final _that = this;
switch (_that) {
case _DevicesListResponse() when $default != null:
return $default(_that.devices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DevicesListResponse implements DevicesListResponse {
  const _DevicesListResponse({required final  List<DeviceInfoDto> devices}): _devices = devices;
  factory _DevicesListResponse.fromJson(Map<String, dynamic> json) => _$DevicesListResponseFromJson(json);

 final  List<DeviceInfoDto> _devices;
@override List<DeviceInfoDto> get devices {
  if (_devices is EqualUnmodifiableListView) return _devices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_devices);
}


/// Create a copy of DevicesListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DevicesListResponseCopyWith<_DevicesListResponse> get copyWith => __$DevicesListResponseCopyWithImpl<_DevicesListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DevicesListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DevicesListResponse&&const DeepCollectionEquality().equals(other._devices, _devices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_devices));

@override
String toString() {
  return 'DevicesListResponse(devices: $devices)';
}


}

/// @nodoc
abstract mixin class _$DevicesListResponseCopyWith<$Res> implements $DevicesListResponseCopyWith<$Res> {
  factory _$DevicesListResponseCopyWith(_DevicesListResponse value, $Res Function(_DevicesListResponse) _then) = __$DevicesListResponseCopyWithImpl;
@override @useResult
$Res call({
 List<DeviceInfoDto> devices
});




}
/// @nodoc
class __$DevicesListResponseCopyWithImpl<$Res>
    implements _$DevicesListResponseCopyWith<$Res> {
  __$DevicesListResponseCopyWithImpl(this._self, this._then);

  final _DevicesListResponse _self;
  final $Res Function(_DevicesListResponse) _then;

/// Create a copy of DevicesListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? devices = null,}) {
  return _then(_DevicesListResponse(
devices: null == devices ? _self._devices : devices // ignore: cast_nullable_to_non_nullable
as List<DeviceInfoDto>,
  ));
}


}


/// @nodoc
mixin _$RevokeDeviceResponse {

@JsonKey(name: 'device_id') String get deviceId; String get status;@JsonKey(name: 'kicked_at') String get kickedAt;@JsonKey(name: 'notification_status') String? get notificationStatus;
/// Create a copy of RevokeDeviceResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevokeDeviceResponseCopyWith<RevokeDeviceResponse> get copyWith => _$RevokeDeviceResponseCopyWithImpl<RevokeDeviceResponse>(this as RevokeDeviceResponse, _$identity);

  /// Serializes this RevokeDeviceResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevokeDeviceResponse&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.status, status) || other.status == status)&&(identical(other.kickedAt, kickedAt) || other.kickedAt == kickedAt)&&(identical(other.notificationStatus, notificationStatus) || other.notificationStatus == notificationStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,status,kickedAt,notificationStatus);

@override
String toString() {
  return 'RevokeDeviceResponse(deviceId: $deviceId, status: $status, kickedAt: $kickedAt, notificationStatus: $notificationStatus)';
}


}

/// @nodoc
abstract mixin class $RevokeDeviceResponseCopyWith<$Res>  {
  factory $RevokeDeviceResponseCopyWith(RevokeDeviceResponse value, $Res Function(RevokeDeviceResponse) _then) = _$RevokeDeviceResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId, String status,@JsonKey(name: 'kicked_at') String kickedAt,@JsonKey(name: 'notification_status') String? notificationStatus
});




}
/// @nodoc
class _$RevokeDeviceResponseCopyWithImpl<$Res>
    implements $RevokeDeviceResponseCopyWith<$Res> {
  _$RevokeDeviceResponseCopyWithImpl(this._self, this._then);

  final RevokeDeviceResponse _self;
  final $Res Function(RevokeDeviceResponse) _then;

/// Create a copy of RevokeDeviceResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? status = null,Object? kickedAt = null,Object? notificationStatus = freezed,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,kickedAt: null == kickedAt ? _self.kickedAt : kickedAt // ignore: cast_nullable_to_non_nullable
as String,notificationStatus: freezed == notificationStatus ? _self.notificationStatus : notificationStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RevokeDeviceResponse].
extension RevokeDeviceResponsePatterns on RevokeDeviceResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevokeDeviceResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevokeDeviceResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevokeDeviceResponse value)  $default,){
final _that = this;
switch (_that) {
case _RevokeDeviceResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevokeDeviceResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RevokeDeviceResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId,  String status, @JsonKey(name: 'kicked_at')  String kickedAt, @JsonKey(name: 'notification_status')  String? notificationStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevokeDeviceResponse() when $default != null:
return $default(_that.deviceId,_that.status,_that.kickedAt,_that.notificationStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId,  String status, @JsonKey(name: 'kicked_at')  String kickedAt, @JsonKey(name: 'notification_status')  String? notificationStatus)  $default,) {final _that = this;
switch (_that) {
case _RevokeDeviceResponse():
return $default(_that.deviceId,_that.status,_that.kickedAt,_that.notificationStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device_id')  String deviceId,  String status, @JsonKey(name: 'kicked_at')  String kickedAt, @JsonKey(name: 'notification_status')  String? notificationStatus)?  $default,) {final _that = this;
switch (_that) {
case _RevokeDeviceResponse() when $default != null:
return $default(_that.deviceId,_that.status,_that.kickedAt,_that.notificationStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevokeDeviceResponse implements RevokeDeviceResponse {
  const _RevokeDeviceResponse({@JsonKey(name: 'device_id') required this.deviceId, required this.status, @JsonKey(name: 'kicked_at') required this.kickedAt, @JsonKey(name: 'notification_status') this.notificationStatus});
  factory _RevokeDeviceResponse.fromJson(Map<String, dynamic> json) => _$RevokeDeviceResponseFromJson(json);

@override@JsonKey(name: 'device_id') final  String deviceId;
@override final  String status;
@override@JsonKey(name: 'kicked_at') final  String kickedAt;
@override@JsonKey(name: 'notification_status') final  String? notificationStatus;

/// Create a copy of RevokeDeviceResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevokeDeviceResponseCopyWith<_RevokeDeviceResponse> get copyWith => __$RevokeDeviceResponseCopyWithImpl<_RevokeDeviceResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevokeDeviceResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevokeDeviceResponse&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.status, status) || other.status == status)&&(identical(other.kickedAt, kickedAt) || other.kickedAt == kickedAt)&&(identical(other.notificationStatus, notificationStatus) || other.notificationStatus == notificationStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,status,kickedAt,notificationStatus);

@override
String toString() {
  return 'RevokeDeviceResponse(deviceId: $deviceId, status: $status, kickedAt: $kickedAt, notificationStatus: $notificationStatus)';
}


}

/// @nodoc
abstract mixin class _$RevokeDeviceResponseCopyWith<$Res> implements $RevokeDeviceResponseCopyWith<$Res> {
  factory _$RevokeDeviceResponseCopyWith(_RevokeDeviceResponse value, $Res Function(_RevokeDeviceResponse) _then) = __$RevokeDeviceResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId, String status,@JsonKey(name: 'kicked_at') String kickedAt,@JsonKey(name: 'notification_status') String? notificationStatus
});




}
/// @nodoc
class __$RevokeDeviceResponseCopyWithImpl<$Res>
    implements _$RevokeDeviceResponseCopyWith<$Res> {
  __$RevokeDeviceResponseCopyWithImpl(this._self, this._then);

  final _RevokeDeviceResponse _self;
  final $Res Function(_RevokeDeviceResponse) _then;

/// Create a copy of RevokeDeviceResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? status = null,Object? kickedAt = null,Object? notificationStatus = freezed,}) {
  return _then(_RevokeDeviceResponse(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,kickedAt: null == kickedAt ? _self.kickedAt : kickedAt // ignore: cast_nullable_to_non_nullable
as String,notificationStatus: freezed == notificationStatus ? _self.notificationStatus : notificationStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AmsErrorResponse {

@JsonKey(name: 'error_code') String get errorCode; String get message;@JsonKey(name: 'retry_after_seconds') int? get retryAfterSeconds;@JsonKey(name: 'remaining_attempts') int? get remainingAttempts;@JsonKey(name: 'lockout_until') String? get lockoutUntil; Map<String, dynamic>? get details;
/// Create a copy of AmsErrorResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmsErrorResponseCopyWith<AmsErrorResponse> get copyWith => _$AmsErrorResponseCopyWithImpl<AmsErrorResponse>(this as AmsErrorResponse, _$identity);

  /// Serializes this AmsErrorResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AmsErrorResponse&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.message, message) || other.message == message)&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds)&&(identical(other.remainingAttempts, remainingAttempts) || other.remainingAttempts == remainingAttempts)&&(identical(other.lockoutUntil, lockoutUntil) || other.lockoutUntil == lockoutUntil)&&const DeepCollectionEquality().equals(other.details, details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,errorCode,message,retryAfterSeconds,remainingAttempts,lockoutUntil,const DeepCollectionEquality().hash(details));

@override
String toString() {
  return 'AmsErrorResponse(errorCode: $errorCode, message: $message, retryAfterSeconds: $retryAfterSeconds, remainingAttempts: $remainingAttempts, lockoutUntil: $lockoutUntil, details: $details)';
}


}

/// @nodoc
abstract mixin class $AmsErrorResponseCopyWith<$Res>  {
  factory $AmsErrorResponseCopyWith(AmsErrorResponse value, $Res Function(AmsErrorResponse) _then) = _$AmsErrorResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'error_code') String errorCode, String message,@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,@JsonKey(name: 'remaining_attempts') int? remainingAttempts,@JsonKey(name: 'lockout_until') String? lockoutUntil, Map<String, dynamic>? details
});




}
/// @nodoc
class _$AmsErrorResponseCopyWithImpl<$Res>
    implements $AmsErrorResponseCopyWith<$Res> {
  _$AmsErrorResponseCopyWithImpl(this._self, this._then);

  final AmsErrorResponse _self;
  final $Res Function(AmsErrorResponse) _then;

/// Create a copy of AmsErrorResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? errorCode = null,Object? message = null,Object? retryAfterSeconds = freezed,Object? remainingAttempts = freezed,Object? lockoutUntil = freezed,Object? details = freezed,}) {
  return _then(_self.copyWith(
errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,remainingAttempts: freezed == remainingAttempts ? _self.remainingAttempts : remainingAttempts // ignore: cast_nullable_to_non_nullable
as int?,lockoutUntil: freezed == lockoutUntil ? _self.lockoutUntil : lockoutUntil // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AmsErrorResponse].
extension AmsErrorResponsePatterns on AmsErrorResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AmsErrorResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AmsErrorResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AmsErrorResponse value)  $default,){
final _that = this;
switch (_that) {
case _AmsErrorResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AmsErrorResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AmsErrorResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'error_code')  String errorCode,  String message, @JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds, @JsonKey(name: 'remaining_attempts')  int? remainingAttempts, @JsonKey(name: 'lockout_until')  String? lockoutUntil,  Map<String, dynamic>? details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AmsErrorResponse() when $default != null:
return $default(_that.errorCode,_that.message,_that.retryAfterSeconds,_that.remainingAttempts,_that.lockoutUntil,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'error_code')  String errorCode,  String message, @JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds, @JsonKey(name: 'remaining_attempts')  int? remainingAttempts, @JsonKey(name: 'lockout_until')  String? lockoutUntil,  Map<String, dynamic>? details)  $default,) {final _that = this;
switch (_that) {
case _AmsErrorResponse():
return $default(_that.errorCode,_that.message,_that.retryAfterSeconds,_that.remainingAttempts,_that.lockoutUntil,_that.details);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'error_code')  String errorCode,  String message, @JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds, @JsonKey(name: 'remaining_attempts')  int? remainingAttempts, @JsonKey(name: 'lockout_until')  String? lockoutUntil,  Map<String, dynamic>? details)?  $default,) {final _that = this;
switch (_that) {
case _AmsErrorResponse() when $default != null:
return $default(_that.errorCode,_that.message,_that.retryAfterSeconds,_that.remainingAttempts,_that.lockoutUntil,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AmsErrorResponse implements AmsErrorResponse {
  const _AmsErrorResponse({@JsonKey(name: 'error_code') required this.errorCode, required this.message, @JsonKey(name: 'retry_after_seconds') this.retryAfterSeconds, @JsonKey(name: 'remaining_attempts') this.remainingAttempts, @JsonKey(name: 'lockout_until') this.lockoutUntil, final  Map<String, dynamic>? details}): _details = details;
  factory _AmsErrorResponse.fromJson(Map<String, dynamic> json) => _$AmsErrorResponseFromJson(json);

@override@JsonKey(name: 'error_code') final  String errorCode;
@override final  String message;
@override@JsonKey(name: 'retry_after_seconds') final  int? retryAfterSeconds;
@override@JsonKey(name: 'remaining_attempts') final  int? remainingAttempts;
@override@JsonKey(name: 'lockout_until') final  String? lockoutUntil;
 final  Map<String, dynamic>? _details;
@override Map<String, dynamic>? get details {
  final value = _details;
  if (value == null) return null;
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AmsErrorResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AmsErrorResponseCopyWith<_AmsErrorResponse> get copyWith => __$AmsErrorResponseCopyWithImpl<_AmsErrorResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AmsErrorResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AmsErrorResponse&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.message, message) || other.message == message)&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds)&&(identical(other.remainingAttempts, remainingAttempts) || other.remainingAttempts == remainingAttempts)&&(identical(other.lockoutUntil, lockoutUntil) || other.lockoutUntil == lockoutUntil)&&const DeepCollectionEquality().equals(other._details, _details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,errorCode,message,retryAfterSeconds,remainingAttempts,lockoutUntil,const DeepCollectionEquality().hash(_details));

@override
String toString() {
  return 'AmsErrorResponse(errorCode: $errorCode, message: $message, retryAfterSeconds: $retryAfterSeconds, remainingAttempts: $remainingAttempts, lockoutUntil: $lockoutUntil, details: $details)';
}


}

/// @nodoc
abstract mixin class _$AmsErrorResponseCopyWith<$Res> implements $AmsErrorResponseCopyWith<$Res> {
  factory _$AmsErrorResponseCopyWith(_AmsErrorResponse value, $Res Function(_AmsErrorResponse) _then) = __$AmsErrorResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'error_code') String errorCode, String message,@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,@JsonKey(name: 'remaining_attempts') int? remainingAttempts,@JsonKey(name: 'lockout_until') String? lockoutUntil, Map<String, dynamic>? details
});




}
/// @nodoc
class __$AmsErrorResponseCopyWithImpl<$Res>
    implements _$AmsErrorResponseCopyWith<$Res> {
  __$AmsErrorResponseCopyWithImpl(this._self, this._then);

  final _AmsErrorResponse _self;
  final $Res Function(_AmsErrorResponse) _then;

/// Create a copy of AmsErrorResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? errorCode = null,Object? message = null,Object? retryAfterSeconds = freezed,Object? remainingAttempts = freezed,Object? lockoutUntil = freezed,Object? details = freezed,}) {
  return _then(_AmsErrorResponse(
errorCode: null == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,remainingAttempts: freezed == remainingAttempts ? _self.remainingAttempts : remainingAttempts // ignore: cast_nullable_to_non_nullable
as int?,lockoutUntil: freezed == lockoutUntil ? _self.lockoutUntil : lockoutUntil // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
