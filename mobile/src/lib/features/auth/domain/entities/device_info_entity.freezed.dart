// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_info_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceInfoEntity {

 String get deviceId; String get deviceName; String get osType; String get status; DateTime get loginTime; DateTime get lastActivityTime; bool get isCurrentDevice; bool get biometricRegistered; String? get locationCountry; String? get locationCity; String? get biometricType;
/// Create a copy of DeviceInfoEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoEntityCopyWith<DeviceInfoEntity> get copyWith => _$DeviceInfoEntityCopyWithImpl<DeviceInfoEntity>(this as DeviceInfoEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfoEntity&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.osType, osType) || other.osType == osType)&&(identical(other.status, status) || other.status == status)&&(identical(other.loginTime, loginTime) || other.loginTime == loginTime)&&(identical(other.lastActivityTime, lastActivityTime) || other.lastActivityTime == lastActivityTime)&&(identical(other.isCurrentDevice, isCurrentDevice) || other.isCurrentDevice == isCurrentDevice)&&(identical(other.biometricRegistered, biometricRegistered) || other.biometricRegistered == biometricRegistered)&&(identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry)&&(identical(other.locationCity, locationCity) || other.locationCity == locationCity)&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,osType,status,loginTime,lastActivityTime,isCurrentDevice,biometricRegistered,locationCountry,locationCity,biometricType);

@override
String toString() {
  return 'DeviceInfoEntity(deviceId: $deviceId, deviceName: $deviceName, osType: $osType, status: $status, loginTime: $loginTime, lastActivityTime: $lastActivityTime, isCurrentDevice: $isCurrentDevice, biometricRegistered: $biometricRegistered, locationCountry: $locationCountry, locationCity: $locationCity, biometricType: $biometricType)';
}


}

/// @nodoc
abstract mixin class $DeviceInfoEntityCopyWith<$Res>  {
  factory $DeviceInfoEntityCopyWith(DeviceInfoEntity value, $Res Function(DeviceInfoEntity) _then) = _$DeviceInfoEntityCopyWithImpl;
@useResult
$Res call({
 String deviceId, String deviceName, String osType, String status, DateTime loginTime, DateTime lastActivityTime, bool isCurrentDevice, bool biometricRegistered, String? locationCountry, String? locationCity, String? biometricType
});




}
/// @nodoc
class _$DeviceInfoEntityCopyWithImpl<$Res>
    implements $DeviceInfoEntityCopyWith<$Res> {
  _$DeviceInfoEntityCopyWithImpl(this._self, this._then);

  final DeviceInfoEntity _self;
  final $Res Function(DeviceInfoEntity) _then;

/// Create a copy of DeviceInfoEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceName = null,Object? osType = null,Object? status = null,Object? loginTime = null,Object? lastActivityTime = null,Object? isCurrentDevice = null,Object? biometricRegistered = null,Object? locationCountry = freezed,Object? locationCity = freezed,Object? biometricType = freezed,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,osType: null == osType ? _self.osType : osType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,loginTime: null == loginTime ? _self.loginTime : loginTime // ignore: cast_nullable_to_non_nullable
as DateTime,lastActivityTime: null == lastActivityTime ? _self.lastActivityTime : lastActivityTime // ignore: cast_nullable_to_non_nullable
as DateTime,isCurrentDevice: null == isCurrentDevice ? _self.isCurrentDevice : isCurrentDevice // ignore: cast_nullable_to_non_nullable
as bool,biometricRegistered: null == biometricRegistered ? _self.biometricRegistered : biometricRegistered // ignore: cast_nullable_to_non_nullable
as bool,locationCountry: freezed == locationCountry ? _self.locationCountry : locationCountry // ignore: cast_nullable_to_non_nullable
as String?,locationCity: freezed == locationCity ? _self.locationCity : locationCity // ignore: cast_nullable_to_non_nullable
as String?,biometricType: freezed == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceInfoEntity].
extension DeviceInfoEntityPatterns on DeviceInfoEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfoEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfoEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfoEntity value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfoEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfoEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfoEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  String deviceName,  String osType,  String status,  DateTime loginTime,  DateTime lastActivityTime,  bool isCurrentDevice,  bool biometricRegistered,  String? locationCountry,  String? locationCity,  String? biometricType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfoEntity() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.osType,_that.status,_that.loginTime,_that.lastActivityTime,_that.isCurrentDevice,_that.biometricRegistered,_that.locationCountry,_that.locationCity,_that.biometricType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  String deviceName,  String osType,  String status,  DateTime loginTime,  DateTime lastActivityTime,  bool isCurrentDevice,  bool biometricRegistered,  String? locationCountry,  String? locationCity,  String? biometricType)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfoEntity():
return $default(_that.deviceId,_that.deviceName,_that.osType,_that.status,_that.loginTime,_that.lastActivityTime,_that.isCurrentDevice,_that.biometricRegistered,_that.locationCountry,_that.locationCity,_that.biometricType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  String deviceName,  String osType,  String status,  DateTime loginTime,  DateTime lastActivityTime,  bool isCurrentDevice,  bool biometricRegistered,  String? locationCountry,  String? locationCity,  String? biometricType)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfoEntity() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.osType,_that.status,_that.loginTime,_that.lastActivityTime,_that.isCurrentDevice,_that.biometricRegistered,_that.locationCountry,_that.locationCity,_that.biometricType);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceInfoEntity implements DeviceInfoEntity {
  const _DeviceInfoEntity({required this.deviceId, required this.deviceName, required this.osType, required this.status, required this.loginTime, required this.lastActivityTime, required this.isCurrentDevice, required this.biometricRegistered, this.locationCountry, this.locationCity, this.biometricType});
  

@override final  String deviceId;
@override final  String deviceName;
@override final  String osType;
@override final  String status;
@override final  DateTime loginTime;
@override final  DateTime lastActivityTime;
@override final  bool isCurrentDevice;
@override final  bool biometricRegistered;
@override final  String? locationCountry;
@override final  String? locationCity;
@override final  String? biometricType;

/// Create a copy of DeviceInfoEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoEntityCopyWith<_DeviceInfoEntity> get copyWith => __$DeviceInfoEntityCopyWithImpl<_DeviceInfoEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfoEntity&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.osType, osType) || other.osType == osType)&&(identical(other.status, status) || other.status == status)&&(identical(other.loginTime, loginTime) || other.loginTime == loginTime)&&(identical(other.lastActivityTime, lastActivityTime) || other.lastActivityTime == lastActivityTime)&&(identical(other.isCurrentDevice, isCurrentDevice) || other.isCurrentDevice == isCurrentDevice)&&(identical(other.biometricRegistered, biometricRegistered) || other.biometricRegistered == biometricRegistered)&&(identical(other.locationCountry, locationCountry) || other.locationCountry == locationCountry)&&(identical(other.locationCity, locationCity) || other.locationCity == locationCity)&&(identical(other.biometricType, biometricType) || other.biometricType == biometricType));
}


@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,osType,status,loginTime,lastActivityTime,isCurrentDevice,biometricRegistered,locationCountry,locationCity,biometricType);

@override
String toString() {
  return 'DeviceInfoEntity(deviceId: $deviceId, deviceName: $deviceName, osType: $osType, status: $status, loginTime: $loginTime, lastActivityTime: $lastActivityTime, isCurrentDevice: $isCurrentDevice, biometricRegistered: $biometricRegistered, locationCountry: $locationCountry, locationCity: $locationCity, biometricType: $biometricType)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoEntityCopyWith<$Res> implements $DeviceInfoEntityCopyWith<$Res> {
  factory _$DeviceInfoEntityCopyWith(_DeviceInfoEntity value, $Res Function(_DeviceInfoEntity) _then) = __$DeviceInfoEntityCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, String deviceName, String osType, String status, DateTime loginTime, DateTime lastActivityTime, bool isCurrentDevice, bool biometricRegistered, String? locationCountry, String? locationCity, String? biometricType
});




}
/// @nodoc
class __$DeviceInfoEntityCopyWithImpl<$Res>
    implements _$DeviceInfoEntityCopyWith<$Res> {
  __$DeviceInfoEntityCopyWithImpl(this._self, this._then);

  final _DeviceInfoEntity _self;
  final $Res Function(_DeviceInfoEntity) _then;

/// Create a copy of DeviceInfoEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceName = null,Object? osType = null,Object? status = null,Object? loginTime = null,Object? lastActivityTime = null,Object? isCurrentDevice = null,Object? biometricRegistered = null,Object? locationCountry = freezed,Object? locationCity = freezed,Object? biometricType = freezed,}) {
  return _then(_DeviceInfoEntity(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,osType: null == osType ? _self.osType : osType // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,loginTime: null == loginTime ? _self.loginTime : loginTime // ignore: cast_nullable_to_non_nullable
as DateTime,lastActivityTime: null == lastActivityTime ? _self.lastActivityTime : lastActivityTime // ignore: cast_nullable_to_non_nullable
as DateTime,isCurrentDevice: null == isCurrentDevice ? _self.isCurrentDevice : isCurrentDevice // ignore: cast_nullable_to_non_nullable
as bool,biometricRegistered: null == biometricRegistered ? _self.biometricRegistered : biometricRegistered // ignore: cast_nullable_to_non_nullable
as bool,locationCountry: freezed == locationCountry ? _self.locationCountry : locationCountry // ignore: cast_nullable_to_non_nullable
as String?,locationCity: freezed == locationCity ? _self.locationCity : locationCity // ignore: cast_nullable_to_non_nullable
as String?,biometricType: freezed == biometricType ? _self.biometricType : biometricType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
