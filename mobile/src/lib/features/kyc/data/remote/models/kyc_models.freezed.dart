// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kyc_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KycSessionModel {

@JsonKey(name: 'kyc_session_id') String get kycSessionId;@JsonKey(name: 'current_step') int get currentStep;@JsonKey(name: 'kyc_status') String get kycStatus;@JsonKey(name: 'expires_at') String? get expiresAt;@JsonKey(name: 'estimated_time_minutes') int? get estimatedTimeMinutes;@JsonKey(name: 'reason_if_rejected') String? get reasonIfRejected;@JsonKey(name: 'needs_more_info_step') int? get needsMoreInfoStep;@JsonKey(name: 'account_id') String? get accountId;@JsonKey(name: 'estimated_review_time_hours') int? get estimatedReviewTimeHours;
/// Create a copy of KycSessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KycSessionModelCopyWith<KycSessionModel> get copyWith => _$KycSessionModelCopyWithImpl<KycSessionModel>(this as KycSessionModel, _$identity);

  /// Serializes this KycSessionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KycSessionModel&&(identical(other.kycSessionId, kycSessionId) || other.kycSessionId == kycSessionId)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.estimatedTimeMinutes, estimatedTimeMinutes) || other.estimatedTimeMinutes == estimatedTimeMinutes)&&(identical(other.reasonIfRejected, reasonIfRejected) || other.reasonIfRejected == reasonIfRejected)&&(identical(other.needsMoreInfoStep, needsMoreInfoStep) || other.needsMoreInfoStep == needsMoreInfoStep)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.estimatedReviewTimeHours, estimatedReviewTimeHours) || other.estimatedReviewTimeHours == estimatedReviewTimeHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kycSessionId,currentStep,kycStatus,expiresAt,estimatedTimeMinutes,reasonIfRejected,needsMoreInfoStep,accountId,estimatedReviewTimeHours);

@override
String toString() {
  return 'KycSessionModel(kycSessionId: $kycSessionId, currentStep: $currentStep, kycStatus: $kycStatus, expiresAt: $expiresAt, estimatedTimeMinutes: $estimatedTimeMinutes, reasonIfRejected: $reasonIfRejected, needsMoreInfoStep: $needsMoreInfoStep, accountId: $accountId, estimatedReviewTimeHours: $estimatedReviewTimeHours)';
}


}

/// @nodoc
abstract mixin class $KycSessionModelCopyWith<$Res>  {
  factory $KycSessionModelCopyWith(KycSessionModel value, $Res Function(KycSessionModel) _then) = _$KycSessionModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'kyc_session_id') String kycSessionId,@JsonKey(name: 'current_step') int currentStep,@JsonKey(name: 'kyc_status') String kycStatus,@JsonKey(name: 'expires_at') String? expiresAt,@JsonKey(name: 'estimated_time_minutes') int? estimatedTimeMinutes,@JsonKey(name: 'reason_if_rejected') String? reasonIfRejected,@JsonKey(name: 'needs_more_info_step') int? needsMoreInfoStep,@JsonKey(name: 'account_id') String? accountId,@JsonKey(name: 'estimated_review_time_hours') int? estimatedReviewTimeHours
});




}
/// @nodoc
class _$KycSessionModelCopyWithImpl<$Res>
    implements $KycSessionModelCopyWith<$Res> {
  _$KycSessionModelCopyWithImpl(this._self, this._then);

  final KycSessionModel _self;
  final $Res Function(KycSessionModel) _then;

/// Create a copy of KycSessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kycSessionId = null,Object? currentStep = null,Object? kycStatus = null,Object? expiresAt = freezed,Object? estimatedTimeMinutes = freezed,Object? reasonIfRejected = freezed,Object? needsMoreInfoStep = freezed,Object? accountId = freezed,Object? estimatedReviewTimeHours = freezed,}) {
  return _then(_self.copyWith(
kycSessionId: null == kycSessionId ? _self.kycSessionId : kycSessionId // ignore: cast_nullable_to_non_nullable
as String,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,estimatedTimeMinutes: freezed == estimatedTimeMinutes ? _self.estimatedTimeMinutes : estimatedTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,reasonIfRejected: freezed == reasonIfRejected ? _self.reasonIfRejected : reasonIfRejected // ignore: cast_nullable_to_non_nullable
as String?,needsMoreInfoStep: freezed == needsMoreInfoStep ? _self.needsMoreInfoStep : needsMoreInfoStep // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,estimatedReviewTimeHours: freezed == estimatedReviewTimeHours ? _self.estimatedReviewTimeHours : estimatedReviewTimeHours // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [KycSessionModel].
extension KycSessionModelPatterns on KycSessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KycSessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KycSessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KycSessionModel value)  $default,){
final _that = this;
switch (_that) {
case _KycSessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KycSessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _KycSessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'kyc_session_id')  String kycSessionId, @JsonKey(name: 'current_step')  int currentStep, @JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'estimated_time_minutes')  int? estimatedTimeMinutes, @JsonKey(name: 'reason_if_rejected')  String? reasonIfRejected, @JsonKey(name: 'needs_more_info_step')  int? needsMoreInfoStep, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'estimated_review_time_hours')  int? estimatedReviewTimeHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KycSessionModel() when $default != null:
return $default(_that.kycSessionId,_that.currentStep,_that.kycStatus,_that.expiresAt,_that.estimatedTimeMinutes,_that.reasonIfRejected,_that.needsMoreInfoStep,_that.accountId,_that.estimatedReviewTimeHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'kyc_session_id')  String kycSessionId, @JsonKey(name: 'current_step')  int currentStep, @JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'estimated_time_minutes')  int? estimatedTimeMinutes, @JsonKey(name: 'reason_if_rejected')  String? reasonIfRejected, @JsonKey(name: 'needs_more_info_step')  int? needsMoreInfoStep, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'estimated_review_time_hours')  int? estimatedReviewTimeHours)  $default,) {final _that = this;
switch (_that) {
case _KycSessionModel():
return $default(_that.kycSessionId,_that.currentStep,_that.kycStatus,_that.expiresAt,_that.estimatedTimeMinutes,_that.reasonIfRejected,_that.needsMoreInfoStep,_that.accountId,_that.estimatedReviewTimeHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'kyc_session_id')  String kycSessionId, @JsonKey(name: 'current_step')  int currentStep, @JsonKey(name: 'kyc_status')  String kycStatus, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'estimated_time_minutes')  int? estimatedTimeMinutes, @JsonKey(name: 'reason_if_rejected')  String? reasonIfRejected, @JsonKey(name: 'needs_more_info_step')  int? needsMoreInfoStep, @JsonKey(name: 'account_id')  String? accountId, @JsonKey(name: 'estimated_review_time_hours')  int? estimatedReviewTimeHours)?  $default,) {final _that = this;
switch (_that) {
case _KycSessionModel() when $default != null:
return $default(_that.kycSessionId,_that.currentStep,_that.kycStatus,_that.expiresAt,_that.estimatedTimeMinutes,_that.reasonIfRejected,_that.needsMoreInfoStep,_that.accountId,_that.estimatedReviewTimeHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KycSessionModel implements KycSessionModel {
  const _KycSessionModel({@JsonKey(name: 'kyc_session_id') required this.kycSessionId, @JsonKey(name: 'current_step') this.currentStep = 1, @JsonKey(name: 'kyc_status') this.kycStatus = 'IN_PROGRESS', @JsonKey(name: 'expires_at') this.expiresAt, @JsonKey(name: 'estimated_time_minutes') this.estimatedTimeMinutes, @JsonKey(name: 'reason_if_rejected') this.reasonIfRejected, @JsonKey(name: 'needs_more_info_step') this.needsMoreInfoStep, @JsonKey(name: 'account_id') this.accountId, @JsonKey(name: 'estimated_review_time_hours') this.estimatedReviewTimeHours});
  factory _KycSessionModel.fromJson(Map<String, dynamic> json) => _$KycSessionModelFromJson(json);

@override@JsonKey(name: 'kyc_session_id') final  String kycSessionId;
@override@JsonKey(name: 'current_step') final  int currentStep;
@override@JsonKey(name: 'kyc_status') final  String kycStatus;
@override@JsonKey(name: 'expires_at') final  String? expiresAt;
@override@JsonKey(name: 'estimated_time_minutes') final  int? estimatedTimeMinutes;
@override@JsonKey(name: 'reason_if_rejected') final  String? reasonIfRejected;
@override@JsonKey(name: 'needs_more_info_step') final  int? needsMoreInfoStep;
@override@JsonKey(name: 'account_id') final  String? accountId;
@override@JsonKey(name: 'estimated_review_time_hours') final  int? estimatedReviewTimeHours;

/// Create a copy of KycSessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KycSessionModelCopyWith<_KycSessionModel> get copyWith => __$KycSessionModelCopyWithImpl<_KycSessionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KycSessionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KycSessionModel&&(identical(other.kycSessionId, kycSessionId) || other.kycSessionId == kycSessionId)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.estimatedTimeMinutes, estimatedTimeMinutes) || other.estimatedTimeMinutes == estimatedTimeMinutes)&&(identical(other.reasonIfRejected, reasonIfRejected) || other.reasonIfRejected == reasonIfRejected)&&(identical(other.needsMoreInfoStep, needsMoreInfoStep) || other.needsMoreInfoStep == needsMoreInfoStep)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.estimatedReviewTimeHours, estimatedReviewTimeHours) || other.estimatedReviewTimeHours == estimatedReviewTimeHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kycSessionId,currentStep,kycStatus,expiresAt,estimatedTimeMinutes,reasonIfRejected,needsMoreInfoStep,accountId,estimatedReviewTimeHours);

@override
String toString() {
  return 'KycSessionModel(kycSessionId: $kycSessionId, currentStep: $currentStep, kycStatus: $kycStatus, expiresAt: $expiresAt, estimatedTimeMinutes: $estimatedTimeMinutes, reasonIfRejected: $reasonIfRejected, needsMoreInfoStep: $needsMoreInfoStep, accountId: $accountId, estimatedReviewTimeHours: $estimatedReviewTimeHours)';
}


}

/// @nodoc
abstract mixin class _$KycSessionModelCopyWith<$Res> implements $KycSessionModelCopyWith<$Res> {
  factory _$KycSessionModelCopyWith(_KycSessionModel value, $Res Function(_KycSessionModel) _then) = __$KycSessionModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'kyc_session_id') String kycSessionId,@JsonKey(name: 'current_step') int currentStep,@JsonKey(name: 'kyc_status') String kycStatus,@JsonKey(name: 'expires_at') String? expiresAt,@JsonKey(name: 'estimated_time_minutes') int? estimatedTimeMinutes,@JsonKey(name: 'reason_if_rejected') String? reasonIfRejected,@JsonKey(name: 'needs_more_info_step') int? needsMoreInfoStep,@JsonKey(name: 'account_id') String? accountId,@JsonKey(name: 'estimated_review_time_hours') int? estimatedReviewTimeHours
});




}
/// @nodoc
class __$KycSessionModelCopyWithImpl<$Res>
    implements _$KycSessionModelCopyWith<$Res> {
  __$KycSessionModelCopyWithImpl(this._self, this._then);

  final _KycSessionModel _self;
  final $Res Function(_KycSessionModel) _then;

/// Create a copy of KycSessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kycSessionId = null,Object? currentStep = null,Object? kycStatus = null,Object? expiresAt = freezed,Object? estimatedTimeMinutes = freezed,Object? reasonIfRejected = freezed,Object? needsMoreInfoStep = freezed,Object? accountId = freezed,Object? estimatedReviewTimeHours = freezed,}) {
  return _then(_KycSessionModel(
kycSessionId: null == kycSessionId ? _self.kycSessionId : kycSessionId // ignore: cast_nullable_to_non_nullable
as String,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,kycStatus: null == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,estimatedTimeMinutes: freezed == estimatedTimeMinutes ? _self.estimatedTimeMinutes : estimatedTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,reasonIfRejected: freezed == reasonIfRejected ? _self.reasonIfRejected : reasonIfRejected // ignore: cast_nullable_to_non_nullable
as String?,needsMoreInfoStep: freezed == needsMoreInfoStep ? _self.needsMoreInfoStep : needsMoreInfoStep // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,estimatedReviewTimeHours: freezed == estimatedReviewTimeHours ? _self.estimatedReviewTimeHours : estimatedReviewTimeHours // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SumsubTokenModel {

@JsonKey(name: 'access_token') String get accessToken;@JsonKey(name: 'applicant_id') String get applicantId; int get ttl;
/// Create a copy of SumsubTokenModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SumsubTokenModelCopyWith<SumsubTokenModel> get copyWith => _$SumsubTokenModelCopyWithImpl<SumsubTokenModel>(this as SumsubTokenModel, _$identity);

  /// Serializes this SumsubTokenModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SumsubTokenModel&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.ttl, ttl) || other.ttl == ttl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,applicantId,ttl);

@override
String toString() {
  return 'SumsubTokenModel(accessToken: $accessToken, applicantId: $applicantId, ttl: $ttl)';
}


}

/// @nodoc
abstract mixin class $SumsubTokenModelCopyWith<$Res>  {
  factory $SumsubTokenModelCopyWith(SumsubTokenModel value, $Res Function(SumsubTokenModel) _then) = _$SumsubTokenModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'access_token') String accessToken,@JsonKey(name: 'applicant_id') String applicantId, int ttl
});




}
/// @nodoc
class _$SumsubTokenModelCopyWithImpl<$Res>
    implements $SumsubTokenModelCopyWith<$Res> {
  _$SumsubTokenModelCopyWithImpl(this._self, this._then);

  final SumsubTokenModel _self;
  final $Res Function(SumsubTokenModel) _then;

/// Create a copy of SumsubTokenModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? applicantId = null,Object? ttl = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SumsubTokenModel].
extension SumsubTokenModelPatterns on SumsubTokenModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SumsubTokenModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SumsubTokenModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SumsubTokenModel value)  $default,){
final _that = this;
switch (_that) {
case _SumsubTokenModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SumsubTokenModel value)?  $default,){
final _that = this;
switch (_that) {
case _SumsubTokenModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'applicant_id')  String applicantId,  int ttl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SumsubTokenModel() when $default != null:
return $default(_that.accessToken,_that.applicantId,_that.ttl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'applicant_id')  String applicantId,  int ttl)  $default,) {final _that = this;
switch (_that) {
case _SumsubTokenModel():
return $default(_that.accessToken,_that.applicantId,_that.ttl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'access_token')  String accessToken, @JsonKey(name: 'applicant_id')  String applicantId,  int ttl)?  $default,) {final _that = this;
switch (_that) {
case _SumsubTokenModel() when $default != null:
return $default(_that.accessToken,_that.applicantId,_that.ttl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SumsubTokenModel implements SumsubTokenModel {
  const _SumsubTokenModel({@JsonKey(name: 'access_token') required this.accessToken, @JsonKey(name: 'applicant_id') required this.applicantId, this.ttl = 600});
  factory _SumsubTokenModel.fromJson(Map<String, dynamic> json) => _$SumsubTokenModelFromJson(json);

@override@JsonKey(name: 'access_token') final  String accessToken;
@override@JsonKey(name: 'applicant_id') final  String applicantId;
@override@JsonKey() final  int ttl;

/// Create a copy of SumsubTokenModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SumsubTokenModelCopyWith<_SumsubTokenModel> get copyWith => __$SumsubTokenModelCopyWithImpl<_SumsubTokenModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SumsubTokenModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SumsubTokenModel&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.applicantId, applicantId) || other.applicantId == applicantId)&&(identical(other.ttl, ttl) || other.ttl == ttl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,applicantId,ttl);

@override
String toString() {
  return 'SumsubTokenModel(accessToken: $accessToken, applicantId: $applicantId, ttl: $ttl)';
}


}

/// @nodoc
abstract mixin class _$SumsubTokenModelCopyWith<$Res> implements $SumsubTokenModelCopyWith<$Res> {
  factory _$SumsubTokenModelCopyWith(_SumsubTokenModel value, $Res Function(_SumsubTokenModel) _then) = __$SumsubTokenModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'access_token') String accessToken,@JsonKey(name: 'applicant_id') String applicantId, int ttl
});




}
/// @nodoc
class __$SumsubTokenModelCopyWithImpl<$Res>
    implements _$SumsubTokenModelCopyWith<$Res> {
  __$SumsubTokenModelCopyWithImpl(this._self, this._then);

  final _SumsubTokenModel _self;
  final $Res Function(_SumsubTokenModel) _then;

/// Create a copy of SumsubTokenModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? applicantId = null,Object? ttl = null,}) {
  return _then(_SumsubTokenModel(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,applicantId: null == applicantId ? _self.applicantId : applicantId // ignore: cast_nullable_to_non_nullable
as String,ttl: null == ttl ? _self.ttl : ttl // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UploadUrlModel {

@JsonKey(name: 'upload_url') String get uploadUrl;@JsonKey(name: 'document_id') String get documentId; int get expiry;@JsonKey(name: 'checksum_algorithm') String get checksumAlgorithm;
/// Create a copy of UploadUrlModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadUrlModelCopyWith<UploadUrlModel> get copyWith => _$UploadUrlModelCopyWithImpl<UploadUrlModel>(this as UploadUrlModel, _$identity);

  /// Serializes this UploadUrlModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadUrlModel&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.checksumAlgorithm, checksumAlgorithm) || other.checksumAlgorithm == checksumAlgorithm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uploadUrl,documentId,expiry,checksumAlgorithm);

@override
String toString() {
  return 'UploadUrlModel(uploadUrl: $uploadUrl, documentId: $documentId, expiry: $expiry, checksumAlgorithm: $checksumAlgorithm)';
}


}

/// @nodoc
abstract mixin class $UploadUrlModelCopyWith<$Res>  {
  factory $UploadUrlModelCopyWith(UploadUrlModel value, $Res Function(UploadUrlModel) _then) = _$UploadUrlModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'upload_url') String uploadUrl,@JsonKey(name: 'document_id') String documentId, int expiry,@JsonKey(name: 'checksum_algorithm') String checksumAlgorithm
});




}
/// @nodoc
class _$UploadUrlModelCopyWithImpl<$Res>
    implements $UploadUrlModelCopyWith<$Res> {
  _$UploadUrlModelCopyWithImpl(this._self, this._then);

  final UploadUrlModel _self;
  final $Res Function(UploadUrlModel) _then;

/// Create a copy of UploadUrlModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uploadUrl = null,Object? documentId = null,Object? expiry = null,Object? checksumAlgorithm = null,}) {
  return _then(_self.copyWith(
uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as int,checksumAlgorithm: null == checksumAlgorithm ? _self.checksumAlgorithm : checksumAlgorithm // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadUrlModel].
extension UploadUrlModelPatterns on UploadUrlModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadUrlModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadUrlModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadUrlModel value)  $default,){
final _that = this;
switch (_that) {
case _UploadUrlModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadUrlModel value)?  $default,){
final _that = this;
switch (_that) {
case _UploadUrlModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'document_id')  String documentId,  int expiry, @JsonKey(name: 'checksum_algorithm')  String checksumAlgorithm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadUrlModel() when $default != null:
return $default(_that.uploadUrl,_that.documentId,_that.expiry,_that.checksumAlgorithm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'document_id')  String documentId,  int expiry, @JsonKey(name: 'checksum_algorithm')  String checksumAlgorithm)  $default,) {final _that = this;
switch (_that) {
case _UploadUrlModel():
return $default(_that.uploadUrl,_that.documentId,_that.expiry,_that.checksumAlgorithm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'upload_url')  String uploadUrl, @JsonKey(name: 'document_id')  String documentId,  int expiry, @JsonKey(name: 'checksum_algorithm')  String checksumAlgorithm)?  $default,) {final _that = this;
switch (_that) {
case _UploadUrlModel() when $default != null:
return $default(_that.uploadUrl,_that.documentId,_that.expiry,_that.checksumAlgorithm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadUrlModel implements UploadUrlModel {
  const _UploadUrlModel({@JsonKey(name: 'upload_url') required this.uploadUrl, @JsonKey(name: 'document_id') required this.documentId, this.expiry = 3600, @JsonKey(name: 'checksum_algorithm') this.checksumAlgorithm = 'SHA256'});
  factory _UploadUrlModel.fromJson(Map<String, dynamic> json) => _$UploadUrlModelFromJson(json);

@override@JsonKey(name: 'upload_url') final  String uploadUrl;
@override@JsonKey(name: 'document_id') final  String documentId;
@override@JsonKey() final  int expiry;
@override@JsonKey(name: 'checksum_algorithm') final  String checksumAlgorithm;

/// Create a copy of UploadUrlModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadUrlModelCopyWith<_UploadUrlModel> get copyWith => __$UploadUrlModelCopyWithImpl<_UploadUrlModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadUrlModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadUrlModel&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.expiry, expiry) || other.expiry == expiry)&&(identical(other.checksumAlgorithm, checksumAlgorithm) || other.checksumAlgorithm == checksumAlgorithm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uploadUrl,documentId,expiry,checksumAlgorithm);

@override
String toString() {
  return 'UploadUrlModel(uploadUrl: $uploadUrl, documentId: $documentId, expiry: $expiry, checksumAlgorithm: $checksumAlgorithm)';
}


}

/// @nodoc
abstract mixin class _$UploadUrlModelCopyWith<$Res> implements $UploadUrlModelCopyWith<$Res> {
  factory _$UploadUrlModelCopyWith(_UploadUrlModel value, $Res Function(_UploadUrlModel) _then) = __$UploadUrlModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'upload_url') String uploadUrl,@JsonKey(name: 'document_id') String documentId, int expiry,@JsonKey(name: 'checksum_algorithm') String checksumAlgorithm
});




}
/// @nodoc
class __$UploadUrlModelCopyWithImpl<$Res>
    implements _$UploadUrlModelCopyWith<$Res> {
  __$UploadUrlModelCopyWithImpl(this._self, this._then);

  final _UploadUrlModel _self;
  final $Res Function(_UploadUrlModel) _then;

/// Create a copy of UploadUrlModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uploadUrl = null,Object? documentId = null,Object? expiry = null,Object? checksumAlgorithm = null,}) {
  return _then(_UploadUrlModel(
uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,expiry: null == expiry ? _self.expiry : expiry // ignore: cast_nullable_to_non_nullable
as int,checksumAlgorithm: null == checksumAlgorithm ? _self.checksumAlgorithm : checksumAlgorithm // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocumentUploadModel {

@JsonKey(name: 'document_id') String get documentId; String get status;@JsonKey(name: 'sumsub_applicant_id') String? get sumsubApplicantId;
/// Create a copy of DocumentUploadModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentUploadModelCopyWith<DocumentUploadModel> get copyWith => _$DocumentUploadModelCopyWithImpl<DocumentUploadModel>(this as DocumentUploadModel, _$identity);

  /// Serializes this DocumentUploadModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentUploadModel&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.sumsubApplicantId, sumsubApplicantId) || other.sumsubApplicantId == sumsubApplicantId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,status,sumsubApplicantId);

@override
String toString() {
  return 'DocumentUploadModel(documentId: $documentId, status: $status, sumsubApplicantId: $sumsubApplicantId)';
}


}

/// @nodoc
abstract mixin class $DocumentUploadModelCopyWith<$Res>  {
  factory $DocumentUploadModelCopyWith(DocumentUploadModel value, $Res Function(DocumentUploadModel) _then) = _$DocumentUploadModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'document_id') String documentId, String status,@JsonKey(name: 'sumsub_applicant_id') String? sumsubApplicantId
});




}
/// @nodoc
class _$DocumentUploadModelCopyWithImpl<$Res>
    implements $DocumentUploadModelCopyWith<$Res> {
  _$DocumentUploadModelCopyWithImpl(this._self, this._then);

  final DocumentUploadModel _self;
  final $Res Function(DocumentUploadModel) _then;

/// Create a copy of DocumentUploadModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? status = null,Object? sumsubApplicantId = freezed,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sumsubApplicantId: freezed == sumsubApplicantId ? _self.sumsubApplicantId : sumsubApplicantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentUploadModel].
extension DocumentUploadModelPatterns on DocumentUploadModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentUploadModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentUploadModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentUploadModel value)  $default,){
final _that = this;
switch (_that) {
case _DocumentUploadModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentUploadModel value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentUploadModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'document_id')  String documentId,  String status, @JsonKey(name: 'sumsub_applicant_id')  String? sumsubApplicantId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentUploadModel() when $default != null:
return $default(_that.documentId,_that.status,_that.sumsubApplicantId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'document_id')  String documentId,  String status, @JsonKey(name: 'sumsub_applicant_id')  String? sumsubApplicantId)  $default,) {final _that = this;
switch (_that) {
case _DocumentUploadModel():
return $default(_that.documentId,_that.status,_that.sumsubApplicantId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'document_id')  String documentId,  String status, @JsonKey(name: 'sumsub_applicant_id')  String? sumsubApplicantId)?  $default,) {final _that = this;
switch (_that) {
case _DocumentUploadModel() when $default != null:
return $default(_that.documentId,_that.status,_that.sumsubApplicantId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentUploadModel implements DocumentUploadModel {
  const _DocumentUploadModel({@JsonKey(name: 'document_id') required this.documentId, this.status = 'UPLOADING', @JsonKey(name: 'sumsub_applicant_id') this.sumsubApplicantId});
  factory _DocumentUploadModel.fromJson(Map<String, dynamic> json) => _$DocumentUploadModelFromJson(json);

@override@JsonKey(name: 'document_id') final  String documentId;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'sumsub_applicant_id') final  String? sumsubApplicantId;

/// Create a copy of DocumentUploadModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentUploadModelCopyWith<_DocumentUploadModel> get copyWith => __$DocumentUploadModelCopyWithImpl<_DocumentUploadModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentUploadModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentUploadModel&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.sumsubApplicantId, sumsubApplicantId) || other.sumsubApplicantId == sumsubApplicantId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,status,sumsubApplicantId);

@override
String toString() {
  return 'DocumentUploadModel(documentId: $documentId, status: $status, sumsubApplicantId: $sumsubApplicantId)';
}


}

/// @nodoc
abstract mixin class _$DocumentUploadModelCopyWith<$Res> implements $DocumentUploadModelCopyWith<$Res> {
  factory _$DocumentUploadModelCopyWith(_DocumentUploadModel value, $Res Function(_DocumentUploadModel) _then) = __$DocumentUploadModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'document_id') String documentId, String status,@JsonKey(name: 'sumsub_applicant_id') String? sumsubApplicantId
});




}
/// @nodoc
class __$DocumentUploadModelCopyWithImpl<$Res>
    implements _$DocumentUploadModelCopyWith<$Res> {
  __$DocumentUploadModelCopyWithImpl(this._self, this._then);

  final _DocumentUploadModel _self;
  final $Res Function(_DocumentUploadModel) _then;

/// Create a copy of DocumentUploadModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? status = null,Object? sumsubApplicantId = freezed,}) {
  return _then(_DocumentUploadModel(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,sumsubApplicantId: freezed == sumsubApplicantId ? _self.sumsubApplicantId : sumsubApplicantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
