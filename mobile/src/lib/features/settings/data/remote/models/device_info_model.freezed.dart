// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_info_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceInfoModel {

@JsonKey(name: 'device_id') String get deviceId;@JsonKey(name: 'device_name') String get deviceName; String get platform; String get status;@JsonKey(name: 'last_active_at') String get lastActiveAt;@JsonKey(name: 'is_current_device') bool get isCurrentDevice;
/// Create a copy of DeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceInfoModelCopyWith<DeviceInfoModel> get copyWith => _$DeviceInfoModelCopyWithImpl<DeviceInfoModel>(this as DeviceInfoModel, _$identity);

  /// Serializes this DeviceInfoModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceInfoModel&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.isCurrentDevice, isCurrentDevice) || other.isCurrentDevice == isCurrentDevice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,platform,status,lastActiveAt,isCurrentDevice);

@override
String toString() {
  return 'DeviceInfoModel(deviceId: $deviceId, deviceName: $deviceName, platform: $platform, status: $status, lastActiveAt: $lastActiveAt, isCurrentDevice: $isCurrentDevice)';
}


}

/// @nodoc
abstract mixin class $DeviceInfoModelCopyWith<$Res>  {
  factory $DeviceInfoModelCopyWith(DeviceInfoModel value, $Res Function(DeviceInfoModel) _then) = _$DeviceInfoModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'device_name') String deviceName, String platform, String status,@JsonKey(name: 'last_active_at') String lastActiveAt,@JsonKey(name: 'is_current_device') bool isCurrentDevice
});




}
/// @nodoc
class _$DeviceInfoModelCopyWithImpl<$Res>
    implements $DeviceInfoModelCopyWith<$Res> {
  _$DeviceInfoModelCopyWithImpl(this._self, this._then);

  final DeviceInfoModel _self;
  final $Res Function(DeviceInfoModel) _then;

/// Create a copy of DeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceName = null,Object? platform = null,Object? status = null,Object? lastActiveAt = null,Object? isCurrentDevice = null,}) {
  return _then(_self.copyWith(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as String,isCurrentDevice: null == isCurrentDevice ? _self.isCurrentDevice : isCurrentDevice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceInfoModel].
extension DeviceInfoModelPatterns on DeviceInfoModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceInfoModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceInfoModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceInfoModel value)  $default,){
final _that = this;
switch (_that) {
case _DeviceInfoModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceInfoModel value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceInfoModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'device_name')  String deviceName,  String platform,  String status, @JsonKey(name: 'last_active_at')  String lastActiveAt, @JsonKey(name: 'is_current_device')  bool isCurrentDevice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceInfoModel() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.platform,_that.status,_that.lastActiveAt,_that.isCurrentDevice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'device_name')  String deviceName,  String platform,  String status, @JsonKey(name: 'last_active_at')  String lastActiveAt, @JsonKey(name: 'is_current_device')  bool isCurrentDevice)  $default,) {final _that = this;
switch (_that) {
case _DeviceInfoModel():
return $default(_that.deviceId,_that.deviceName,_that.platform,_that.status,_that.lastActiveAt,_that.isCurrentDevice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'device_id')  String deviceId, @JsonKey(name: 'device_name')  String deviceName,  String platform,  String status, @JsonKey(name: 'last_active_at')  String lastActiveAt, @JsonKey(name: 'is_current_device')  bool isCurrentDevice)?  $default,) {final _that = this;
switch (_that) {
case _DeviceInfoModel() when $default != null:
return $default(_that.deviceId,_that.deviceName,_that.platform,_that.status,_that.lastActiveAt,_that.isCurrentDevice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceInfoModel extends DeviceInfoModel {
  const _DeviceInfoModel({@JsonKey(name: 'device_id') required this.deviceId, @JsonKey(name: 'device_name') required this.deviceName, required this.platform, required this.status, @JsonKey(name: 'last_active_at') required this.lastActiveAt, @JsonKey(name: 'is_current_device') this.isCurrentDevice = false}): super._();
  factory _DeviceInfoModel.fromJson(Map<String, dynamic> json) => _$DeviceInfoModelFromJson(json);

@override@JsonKey(name: 'device_id') final  String deviceId;
@override@JsonKey(name: 'device_name') final  String deviceName;
@override final  String platform;
@override final  String status;
@override@JsonKey(name: 'last_active_at') final  String lastActiveAt;
@override@JsonKey(name: 'is_current_device') final  bool isCurrentDevice;

/// Create a copy of DeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceInfoModelCopyWith<_DeviceInfoModel> get copyWith => __$DeviceInfoModelCopyWithImpl<_DeviceInfoModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceInfoModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceInfoModel&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastActiveAt, lastActiveAt) || other.lastActiveAt == lastActiveAt)&&(identical(other.isCurrentDevice, isCurrentDevice) || other.isCurrentDevice == isCurrentDevice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceId,deviceName,platform,status,lastActiveAt,isCurrentDevice);

@override
String toString() {
  return 'DeviceInfoModel(deviceId: $deviceId, deviceName: $deviceName, platform: $platform, status: $status, lastActiveAt: $lastActiveAt, isCurrentDevice: $isCurrentDevice)';
}


}

/// @nodoc
abstract mixin class _$DeviceInfoModelCopyWith<$Res> implements $DeviceInfoModelCopyWith<$Res> {
  factory _$DeviceInfoModelCopyWith(_DeviceInfoModel value, $Res Function(_DeviceInfoModel) _then) = __$DeviceInfoModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'device_id') String deviceId,@JsonKey(name: 'device_name') String deviceName, String platform, String status,@JsonKey(name: 'last_active_at') String lastActiveAt,@JsonKey(name: 'is_current_device') bool isCurrentDevice
});




}
/// @nodoc
class __$DeviceInfoModelCopyWithImpl<$Res>
    implements _$DeviceInfoModelCopyWith<$Res> {
  __$DeviceInfoModelCopyWithImpl(this._self, this._then);

  final _DeviceInfoModel _self;
  final $Res Function(_DeviceInfoModel) _then;

/// Create a copy of DeviceInfoModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceName = null,Object? platform = null,Object? status = null,Object? lastActiveAt = null,Object? isCurrentDevice = null,}) {
  return _then(_DeviceInfoModel(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastActiveAt: null == lastActiveAt ? _self.lastActiveAt : lastActiveAt // ignore: cast_nullable_to_non_nullable
as String,isCurrentDevice: null == isCurrentDevice ? _self.isCurrentDevice : isCurrentDevice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
