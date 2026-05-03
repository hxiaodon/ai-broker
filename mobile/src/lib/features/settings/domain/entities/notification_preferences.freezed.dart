// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationPreferences {

 bool get tradingEnabled; bool get fundingEnabled; bool get kycEnabled; bool get systemAnnouncementsEnabled;/// Always true — cannot be changed by user
 bool get securityAlertsEnabled; bool get pushEnabled; bool get smsEnabled; bool get emailEnabled;/// "HH:mm" format, null = no quiet hours
 String? get quietHoursStart; String? get quietHoursEnd;
/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<NotificationPreferences> get copyWith => _$NotificationPreferencesCopyWithImpl<NotificationPreferences>(this as NotificationPreferences, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferences&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.fundingEnabled, fundingEnabled) || other.fundingEnabled == fundingEnabled)&&(identical(other.kycEnabled, kycEnabled) || other.kycEnabled == kycEnabled)&&(identical(other.systemAnnouncementsEnabled, systemAnnouncementsEnabled) || other.systemAnnouncementsEnabled == systemAnnouncementsEnabled)&&(identical(other.securityAlertsEnabled, securityAlertsEnabled) || other.securityAlertsEnabled == securityAlertsEnabled)&&(identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled)&&(identical(other.smsEnabled, smsEnabled) || other.smsEnabled == smsEnabled)&&(identical(other.emailEnabled, emailEnabled) || other.emailEnabled == emailEnabled)&&(identical(other.quietHoursStart, quietHoursStart) || other.quietHoursStart == quietHoursStart)&&(identical(other.quietHoursEnd, quietHoursEnd) || other.quietHoursEnd == quietHoursEnd));
}


@override
int get hashCode => Object.hash(runtimeType,tradingEnabled,fundingEnabled,kycEnabled,systemAnnouncementsEnabled,securityAlertsEnabled,pushEnabled,smsEnabled,emailEnabled,quietHoursStart,quietHoursEnd);

@override
String toString() {
  return 'NotificationPreferences(tradingEnabled: $tradingEnabled, fundingEnabled: $fundingEnabled, kycEnabled: $kycEnabled, systemAnnouncementsEnabled: $systemAnnouncementsEnabled, securityAlertsEnabled: $securityAlertsEnabled, pushEnabled: $pushEnabled, smsEnabled: $smsEnabled, emailEnabled: $emailEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd)';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesCopyWith<$Res>  {
  factory $NotificationPreferencesCopyWith(NotificationPreferences value, $Res Function(NotificationPreferences) _then) = _$NotificationPreferencesCopyWithImpl;
@useResult
$Res call({
 bool tradingEnabled, bool fundingEnabled, bool kycEnabled, bool systemAnnouncementsEnabled, bool securityAlertsEnabled, bool pushEnabled, bool smsEnabled, bool emailEnabled, String? quietHoursStart, String? quietHoursEnd
});




}
/// @nodoc
class _$NotificationPreferencesCopyWithImpl<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final NotificationPreferences _self;
  final $Res Function(NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tradingEnabled = null,Object? fundingEnabled = null,Object? kycEnabled = null,Object? systemAnnouncementsEnabled = null,Object? securityAlertsEnabled = null,Object? pushEnabled = null,Object? smsEnabled = null,Object? emailEnabled = null,Object? quietHoursStart = freezed,Object? quietHoursEnd = freezed,}) {
  return _then(_self.copyWith(
tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,fundingEnabled: null == fundingEnabled ? _self.fundingEnabled : fundingEnabled // ignore: cast_nullable_to_non_nullable
as bool,kycEnabled: null == kycEnabled ? _self.kycEnabled : kycEnabled // ignore: cast_nullable_to_non_nullable
as bool,systemAnnouncementsEnabled: null == systemAnnouncementsEnabled ? _self.systemAnnouncementsEnabled : systemAnnouncementsEnabled // ignore: cast_nullable_to_non_nullable
as bool,securityAlertsEnabled: null == securityAlertsEnabled ? _self.securityAlertsEnabled : securityAlertsEnabled // ignore: cast_nullable_to_non_nullable
as bool,pushEnabled: null == pushEnabled ? _self.pushEnabled : pushEnabled // ignore: cast_nullable_to_non_nullable
as bool,smsEnabled: null == smsEnabled ? _self.smsEnabled : smsEnabled // ignore: cast_nullable_to_non_nullable
as bool,emailEnabled: null == emailEnabled ? _self.emailEnabled : emailEnabled // ignore: cast_nullable_to_non_nullable
as bool,quietHoursStart: freezed == quietHoursStart ? _self.quietHoursStart : quietHoursStart // ignore: cast_nullable_to_non_nullable
as String?,quietHoursEnd: freezed == quietHoursEnd ? _self.quietHoursEnd : quietHoursEnd // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferences].
extension NotificationPreferencesPatterns on NotificationPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferences value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool tradingEnabled,  bool fundingEnabled,  bool kycEnabled,  bool systemAnnouncementsEnabled,  bool securityAlertsEnabled,  bool pushEnabled,  bool smsEnabled,  bool emailEnabled,  String? quietHoursStart,  String? quietHoursEnd)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.tradingEnabled,_that.fundingEnabled,_that.kycEnabled,_that.systemAnnouncementsEnabled,_that.securityAlertsEnabled,_that.pushEnabled,_that.smsEnabled,_that.emailEnabled,_that.quietHoursStart,_that.quietHoursEnd);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool tradingEnabled,  bool fundingEnabled,  bool kycEnabled,  bool systemAnnouncementsEnabled,  bool securityAlertsEnabled,  bool pushEnabled,  bool smsEnabled,  bool emailEnabled,  String? quietHoursStart,  String? quietHoursEnd)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences():
return $default(_that.tradingEnabled,_that.fundingEnabled,_that.kycEnabled,_that.systemAnnouncementsEnabled,_that.securityAlertsEnabled,_that.pushEnabled,_that.smsEnabled,_that.emailEnabled,_that.quietHoursStart,_that.quietHoursEnd);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool tradingEnabled,  bool fundingEnabled,  bool kycEnabled,  bool systemAnnouncementsEnabled,  bool securityAlertsEnabled,  bool pushEnabled,  bool smsEnabled,  bool emailEnabled,  String? quietHoursStart,  String? quietHoursEnd)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.tradingEnabled,_that.fundingEnabled,_that.kycEnabled,_that.systemAnnouncementsEnabled,_that.securityAlertsEnabled,_that.pushEnabled,_that.smsEnabled,_that.emailEnabled,_that.quietHoursStart,_that.quietHoursEnd);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationPreferences extends NotificationPreferences {
  const _NotificationPreferences({required this.tradingEnabled, required this.fundingEnabled, required this.kycEnabled, required this.systemAnnouncementsEnabled, this.securityAlertsEnabled = true, required this.pushEnabled, required this.smsEnabled, required this.emailEnabled, this.quietHoursStart, this.quietHoursEnd}): super._();
  

@override final  bool tradingEnabled;
@override final  bool fundingEnabled;
@override final  bool kycEnabled;
@override final  bool systemAnnouncementsEnabled;
/// Always true — cannot be changed by user
@override@JsonKey() final  bool securityAlertsEnabled;
@override final  bool pushEnabled;
@override final  bool smsEnabled;
@override final  bool emailEnabled;
/// "HH:mm" format, null = no quiet hours
@override final  String? quietHoursStart;
@override final  String? quietHoursEnd;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesCopyWith<_NotificationPreferences> get copyWith => __$NotificationPreferencesCopyWithImpl<_NotificationPreferences>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferences&&(identical(other.tradingEnabled, tradingEnabled) || other.tradingEnabled == tradingEnabled)&&(identical(other.fundingEnabled, fundingEnabled) || other.fundingEnabled == fundingEnabled)&&(identical(other.kycEnabled, kycEnabled) || other.kycEnabled == kycEnabled)&&(identical(other.systemAnnouncementsEnabled, systemAnnouncementsEnabled) || other.systemAnnouncementsEnabled == systemAnnouncementsEnabled)&&(identical(other.securityAlertsEnabled, securityAlertsEnabled) || other.securityAlertsEnabled == securityAlertsEnabled)&&(identical(other.pushEnabled, pushEnabled) || other.pushEnabled == pushEnabled)&&(identical(other.smsEnabled, smsEnabled) || other.smsEnabled == smsEnabled)&&(identical(other.emailEnabled, emailEnabled) || other.emailEnabled == emailEnabled)&&(identical(other.quietHoursStart, quietHoursStart) || other.quietHoursStart == quietHoursStart)&&(identical(other.quietHoursEnd, quietHoursEnd) || other.quietHoursEnd == quietHoursEnd));
}


@override
int get hashCode => Object.hash(runtimeType,tradingEnabled,fundingEnabled,kycEnabled,systemAnnouncementsEnabled,securityAlertsEnabled,pushEnabled,smsEnabled,emailEnabled,quietHoursStart,quietHoursEnd);

@override
String toString() {
  return 'NotificationPreferences(tradingEnabled: $tradingEnabled, fundingEnabled: $fundingEnabled, kycEnabled: $kycEnabled, systemAnnouncementsEnabled: $systemAnnouncementsEnabled, securityAlertsEnabled: $securityAlertsEnabled, pushEnabled: $pushEnabled, smsEnabled: $smsEnabled, emailEnabled: $emailEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesCopyWith<$Res> implements $NotificationPreferencesCopyWith<$Res> {
  factory _$NotificationPreferencesCopyWith(_NotificationPreferences value, $Res Function(_NotificationPreferences) _then) = __$NotificationPreferencesCopyWithImpl;
@override @useResult
$Res call({
 bool tradingEnabled, bool fundingEnabled, bool kycEnabled, bool systemAnnouncementsEnabled, bool securityAlertsEnabled, bool pushEnabled, bool smsEnabled, bool emailEnabled, String? quietHoursStart, String? quietHoursEnd
});




}
/// @nodoc
class __$NotificationPreferencesCopyWithImpl<$Res>
    implements _$NotificationPreferencesCopyWith<$Res> {
  __$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final _NotificationPreferences _self;
  final $Res Function(_NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tradingEnabled = null,Object? fundingEnabled = null,Object? kycEnabled = null,Object? systemAnnouncementsEnabled = null,Object? securityAlertsEnabled = null,Object? pushEnabled = null,Object? smsEnabled = null,Object? emailEnabled = null,Object? quietHoursStart = freezed,Object? quietHoursEnd = freezed,}) {
  return _then(_NotificationPreferences(
tradingEnabled: null == tradingEnabled ? _self.tradingEnabled : tradingEnabled // ignore: cast_nullable_to_non_nullable
as bool,fundingEnabled: null == fundingEnabled ? _self.fundingEnabled : fundingEnabled // ignore: cast_nullable_to_non_nullable
as bool,kycEnabled: null == kycEnabled ? _self.kycEnabled : kycEnabled // ignore: cast_nullable_to_non_nullable
as bool,systemAnnouncementsEnabled: null == systemAnnouncementsEnabled ? _self.systemAnnouncementsEnabled : systemAnnouncementsEnabled // ignore: cast_nullable_to_non_nullable
as bool,securityAlertsEnabled: null == securityAlertsEnabled ? _self.securityAlertsEnabled : securityAlertsEnabled // ignore: cast_nullable_to_non_nullable
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
