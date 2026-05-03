// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preferences_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationPreferencesModel {

@JsonKey(name: 'trading_enabled') bool get tradingEnabled;@JsonKey(name: 'funding_enabled') bool get fundingEnabled;@JsonKey(name: 'kyc_enabled') bool get kycEnabled;@JsonKey(name: 'system_announcements_enabled') bool get systemAnnouncementsEnabled;@JsonKey(name: 'push_enabled') bool get pushEnabled;@JsonKey(name: 'sms_enabled') bool get smsEnabled;@JsonKey(name: 'email_enabled') bool get emailEnabled;@JsonKey(name: 'quiet_hours_start') String? get quietHoursStart;@JsonKey(name: 'quiet_hours_end') String? get quietHoursEnd;
/// Create a copy of NotificationPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesModelCopyWith<NotificationPreferencesModel> get copyWith => _$NotificationPreferencesModelCopyWithImpl<NotificationPreferencesModel>(this as NotificationPreferencesModel, _$identity);

  /// Serializes this NotificationPreferencesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferencesModel&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.fundingEnabled, fundingEnabled) || other.fundingEnabled == fundingEnabled)&&(identical(other.kycEnabled, kycEnabled) || other.kycEnabled == kycEnabled)&&(identical(other.systemAnnouncementsEnabled, systemAnnouncementsEnabled) || other.systemAnnouncementsEnabled == systemAnnouncementsEnabled)&&(identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled)&&(identical(other.smsEnabled, smsEnabled) || other.smsEnabled == smsEnabled)&&(identical(other.emailEnabled, emailEnabled) || other.emailEnabled == emailEnabled)&&(identical(other.quietHoursStart, quietHoursStart) || other.quietHoursStart == quietHoursStart)&&(identical(other.quietHoursEnd, quietHoursEnd) || other.quietHoursEnd == quietHoursEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tradingEnabled,fundingEnabled,kycEnabled,systemAnnouncementsEnabled,pushEnabled,smsEnabled,emailEnabled,quietHoursStart,quietHoursEnd);

@override
String toString() {
  return 'NotificationPreferencesModel(tradingEnabled: $tradingEnabled, fundingEnabled: $fundingEnabled, kycEnabled: $kycEnabled, systemAnnouncementsEnabled: $systemAnnouncementsEnabled, pushEnabled: $pushEnabled, smsEnabled: $smsEnabled, emailEnabled: $emailEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd)';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesModelCopyWith<$Res>  {
  factory $NotificationPreferencesModelCopyWith(NotificationPreferencesModel value, $Res Function(NotificationPreferencesModel) _then) = _$NotificationPreferencesModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'trading_enabled') bool tradingEnabled,@JsonKey(name: 'funding_enabled') bool fundingEnabled,@JsonKey(name: 'kyc_enabled') bool kycEnabled,@JsonKey(name: 'system_announcements_enabled') bool systemAnnouncementsEnabled,@JsonKey(name: 'push_enabled') bool pushEnabled,@JsonKey(name: 'sms_enabled') bool smsEnabled,@JsonKey(name: 'email_enabled') bool emailEnabled,@JsonKey(name: 'quiet_hours_start') String? quietHoursStart,@JsonKey(name: 'quiet_hours_end') String? quietHoursEnd
});




}
/// @nodoc
class _$NotificationPreferencesModelCopyWithImpl<$Res>
    implements $NotificationPreferencesModelCopyWith<$Res> {
  _$NotificationPreferencesModelCopyWithImpl(this._self, this._then);

  final NotificationPreferencesModel _self;
  final $Res Function(NotificationPreferencesModel) _then;

/// Create a copy of NotificationPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tradingEnabled = null,Object? fundingEnabled = null,Object? kycEnabled = null,Object? systemAnnouncementsEnabled = null,Object? pushEnabled = null,Object? smsEnabled = null,Object? emailEnabled = null,Object? quietHoursStart = freezed,Object? quietHoursEnd = freezed,}) {
  return _then(_self.copyWith(
tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,fundingEnabled: null == fundingEnabled ? _self.fundingEnabled : fundingEnabled // ignore: cast_nullable_to_non_nullable
as bool,kycEnabled: null == kycEnabled ? _self.kycEnabled : kycEnabled // ignore: cast_nullable_to_non_nullable
as bool,systemAnnouncementsEnabled: null == systemAnnouncementsEnabled ? _self.systemAnnouncementsEnabled : systemAnnouncementsEnabled // ignore: cast_nullable_to_non_nullable
as bool,pushEnabled: null == pushEnabled ? _self.pushEnabled : pushEnabled // ignore: cast_nullable_to_non_nullable
as bool,smsEnabled: null == smsEnabled ? _self.smsEnabled : smsEnabled // ignore: cast_nullable_to_non_nullable
as bool,emailEnabled: null == emailEnabled ? _self.emailEnabled : emailEnabled // ignore: cast_nullable_to_non_nullable
as bool,quietHoursStart: freezed == quietHoursStart ? _self.quietHoursStart : quietHoursStart // ignore: cast_nullable_to_non_nullable
as String?,quietHoursEnd: freezed == quietHoursEnd ? _self.quietHoursEnd : quietHoursEnd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferencesModel].
extension NotificationPreferencesModelPatterns on NotificationPreferencesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferencesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferencesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferencesModel value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferencesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferencesModel value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferencesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'trading_enabled')  bool tradingEnabled, @JsonKey(name: 'funding_enabled')  bool fundingEnabled, @JsonKey(name: 'kyc_enabled')  bool kycEnabled, @JsonKey(name: 'system_announcements_enabled')  bool systemAnnouncementsEnabled, @JsonKey(name: 'push_enabled')  bool pushEnabled, @JsonKey(name: 'sms_enabled')  bool smsEnabled, @JsonKey(name: 'email_enabled')  bool emailEnabled, @JsonKey(name: 'quiet_hours_start')  String? quietHoursStart, @JsonKey(name: 'quiet_hours_end')  String? quietHoursEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferencesModel() when $default != null:
return $default(_that.tradingEnabled,_that.fundingEnabled,_that.kycEnabled,_that.systemAnnouncementsEnabled,_that.pushEnabled,_that.smsEnabled,_that.emailEnabled,_that.quietHoursStart,_that.quietHoursEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'trading_enabled')  bool tradingEnabled, @JsonKey(name: 'funding_enabled')  bool fundingEnabled, @JsonKey(name: 'kyc_enabled')  bool kycEnabled, @JsonKey(name: 'system_announcements_enabled')  bool systemAnnouncementsEnabled, @JsonKey(name: 'push_enabled')  bool pushEnabled, @JsonKey(name: 'sms_enabled')  bool smsEnabled, @JsonKey(name: 'email_enabled')  bool emailEnabled, @JsonKey(name: 'quiet_hours_start')  String? quietHoursStart, @JsonKey(name: 'quiet_hours_end')  String? quietHoursEnd)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferencesModel():
return $default(_that.tradingEnabled,_that.fundingEnabled,_that.kycEnabled,_that.systemAnnouncementsEnabled,_that.pushEnabled,_that.smsEnabled,_that.emailEnabled,_that.quietHoursStart,_that.quietHoursEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'trading_enabled')  bool tradingEnabled, @JsonKey(name: 'funding_enabled')  bool fundingEnabled, @JsonKey(name: 'kyc_enabled')  bool kycEnabled, @JsonKey(name: 'system_announcements_enabled')  bool systemAnnouncementsEnabled, @JsonKey(name: 'push_enabled')  bool pushEnabled, @JsonKey(name: 'sms_enabled')  bool smsEnabled, @JsonKey(name: 'email_enabled')  bool emailEnabled, @JsonKey(name: 'quiet_hours_start')  String? quietHoursStart, @JsonKey(name: 'quiet_hours_end')  String? quietHoursEnd)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferencesModel() when $default != null:
return $default(_that.tradingEnabled,_that.fundingEnabled,_that.kycEnabled,_that.systemAnnouncementsEnabled,_that.pushEnabled,_that.smsEnabled,_that.emailEnabled,_that.quietHoursStart,_that.quietHoursEnd);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationPreferencesModel extends NotificationPreferencesModel {
  const _NotificationPreferencesModel({@JsonKey(name: 'trading_enabled') this.tradingEnabled = true, @JsonKey(name: 'funding_enabled') this.fundingEnabled = true, @JsonKey(name: 'kyc_enabled') this.kycEnabled = true, @JsonKey(name: 'system_announcements_enabled') this.systemAnnouncementsEnabled = true, @JsonKey(name: 'push_enabled') this.pushEnabled = true, @JsonKey(name: 'sms_enabled') this.smsEnabled = false, @JsonKey(name: 'email_enabled') this.emailEnabled = true, @JsonKey(name: 'quiet_hours_start') this.quietHoursStart, @JsonKey(name: 'quiet_hours_end') this.quietHoursEnd}): super._();
  factory _NotificationPreferencesModel.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesModelFromJson(json);

@override@JsonKey(name: 'trading_enabled') final  bool tradingEnabled;
@override@JsonKey(name: 'funding_enabled') final  bool fundingEnabled;
@override@JsonKey(name: 'kyc_enabled') final  bool kycEnabled;
@override@JsonKey(name: 'system_announcements_enabled') final  bool systemAnnouncementsEnabled;
@override@JsonKey(name: 'push_enabled') final  bool pushEnabled;
@override@JsonKey(name: 'sms_enabled') final  bool smsEnabled;
@override@JsonKey(name: 'email_enabled') final  bool emailEnabled;
@override@JsonKey(name: 'quiet_hours_start') final  String? quietHoursStart;
@override@JsonKey(name: 'quiet_hours_end') final  String? quietHoursEnd;

/// Create a copy of NotificationPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesModelCopyWith<_NotificationPreferencesModel> get copyWith => __$NotificationPreferencesModelCopyWithImpl<_NotificationPreferencesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationPreferencesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferencesModel&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.fundingEnabled, fundingEnabled) || other.fundingEnabled == fundingEnabled)&&(identical(other.kycEnabled, kycEnabled) || other.kycEnabled == kycEnabled)&&(identical(other.systemAnnouncementsEnabled, systemAnnouncementsEnabled) || other.systemAnnouncementsEnabled == systemAnnouncementsEnabled)&&(identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled)&&(identical(other.smsEnabled, smsEnabled) || other.smsEnabled == smsEnabled)&&(identical(other.emailEnabled, emailEnabled) || other.emailEnabled == emailEnabled)&&(identical(other.quietHoursStart, quietHoursStart) || other.quietHoursStart == quietHoursStart)&&(identical(other.quietHoursEnd, quietHoursEnd) || other.quietHoursEnd == quietHoursEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tradingEnabled,fundingEnabled,kycEnabled,systemAnnouncementsEnabled,pushEnabled,smsEnabled,emailEnabled,quietHoursStart,quietHoursEnd);

@override
String toString() {
  return 'NotificationPreferencesModel(tradingEnabled: $tradingEnabled, fundingEnabled: $fundingEnabled, kycEnabled: $kycEnabled, systemAnnouncementsEnabled: $systemAnnouncementsEnabled, pushEnabled: $pushEnabled, smsEnabled: $smsEnabled, emailEnabled: $emailEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesModelCopyWith<$Res> implements $NotificationPreferencesModelCopyWith<$Res> {
  factory _$NotificationPreferencesModelCopyWith(_NotificationPreferencesModel value, $Res Function(_NotificationPreferencesModel) _then) = __$NotificationPreferencesModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'trading_enabled') bool tradingEnabled,@JsonKey(name: 'funding_enabled') bool fundingEnabled,@JsonKey(name: 'kyc_enabled') bool kycEnabled,@JsonKey(name: 'system_announcements_enabled') bool systemAnnouncementsEnabled,@JsonKey(name: 'push_enabled') bool pushEnabled,@JsonKey(name: 'sms_enabled') bool smsEnabled,@JsonKey(name: 'email_enabled') bool emailEnabled,@JsonKey(name: 'quiet_hours_start') String? quietHoursStart,@JsonKey(name: 'quiet_hours_end') String? quietHoursEnd
});




}
/// @nodoc
class __$NotificationPreferencesModelCopyWithImpl<$Res>
    implements _$NotificationPreferencesModelCopyWith<$Res> {
  __$NotificationPreferencesModelCopyWithImpl(this._self, this._then);

  final _NotificationPreferencesModel _self;
  final $Res Function(_NotificationPreferencesModel) _then;

/// Create a copy of NotificationPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tradingEnabled = null,Object? fundingEnabled = null,Object? kycEnabled = null,Object? systemAnnouncementsEnabled = null,Object? pushEnabled = null,Object? smsEnabled = null,Object? emailEnabled = null,Object? quietHoursStart = freezed,Object? quietHoursEnd = freezed,}) {
  return _then(_NotificationPreferencesModel(
tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,fundingEnabled: null == fundingEnabled ? _self.fundingEnabled : fundingEnabled // ignore: cast_nullable_to_non_nullable
as bool,kycEnabled: null == kycEnabled ? _self.kycEnabled : kycEnabled // ignore: cast_nullable_to_non_nullable
as bool,systemAnnouncementsEnabled: null == systemAnnouncementsEnabled ? _self.systemAnnouncementsEnabled : systemAnnouncementsEnabled // ignore: cast_nullable_to_non_nullable
as bool,pushEnabled: null == pushEnabled ? _self.pushEnabled : pushEnabled // ignore: cast_nullable_to_non_nullable
as bool,smsEnabled: null == smsEnabled ? _self.smsEnabled : smsEnabled // ignore: cast_nullable_to_non_nullable
as bool,emailEnabled: null == emailEnabled ? _self.emailEnabled : emailEnabled // ignore: cast_nullable_to_non_nullable
as bool,quietHoursStart: freezed == quietHoursStart ? _self.quietHoursStart : quietHoursStart // ignore: cast_nullable_to_non_nullable
as String?,quietHoursEnd: freezed == quietHoursEnd ? _self.quietHoursEnd : quietHoursEnd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
