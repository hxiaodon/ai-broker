// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kyc_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

KycApplication _$KycApplicationFromJson(Map<String, dynamic> json) {
  return _KycApplication.fromJson(json);
}

/// @nodoc
mixin _$KycApplication {
  String get applicationId => throw _privateConstructorUsedError;
  KycStatus get status => throw _privateConstructorUsedError;
  KycJurisdiction get jurisdiction => throw _privateConstructorUsedError;
  int get completedSteps => throw _privateConstructorUsedError; // 0-7
  DateTime get createdAt => throw _privateConstructorUsedError; // UTC
  DateTime? get submittedAt => throw _privateConstructorUsedError; // UTC
  DateTime? get reviewedAt => throw _privateConstructorUsedError; // UTC
  String? get rejectionReason => throw _privateConstructorUsedError;

  /// Serializes this KycApplication to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KycApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KycApplicationCopyWith<KycApplication> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KycApplicationCopyWith<$Res> {
  factory $KycApplicationCopyWith(
    KycApplication value,
    $Res Function(KycApplication) then,
  ) = _$KycApplicationCopyWithImpl<$Res, KycApplication>;
  @useResult
  $Res call({
    String applicationId,
    KycStatus status,
    KycJurisdiction jurisdiction,
    int completedSteps,
    DateTime createdAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
  });
}

/// @nodoc
class _$KycApplicationCopyWithImpl<$Res, $Val extends KycApplication>
    implements $KycApplicationCopyWith<$Res> {
  _$KycApplicationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KycApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applicationId = null,
    Object? status = null,
    Object? jurisdiction = null,
    Object? completedSteps = null,
    Object? createdAt = null,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? rejectionReason = freezed,
  }) {
    return _then(
      _value.copyWith(
            applicationId:
                null == applicationId
                    ? _value.applicationId
                    : applicationId // ignore: cast_nullable_to_non_nullable
                        as String,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as KycStatus,
            jurisdiction:
                null == jurisdiction
                    ? _value.jurisdiction
                    : jurisdiction // ignore: cast_nullable_to_non_nullable
                        as KycJurisdiction,
            completedSteps:
                null == completedSteps
                    ? _value.completedSteps
                    : completedSteps // ignore: cast_nullable_to_non_nullable
                        as int,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            submittedAt:
                freezed == submittedAt
                    ? _value.submittedAt
                    : submittedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            reviewedAt:
                freezed == reviewedAt
                    ? _value.reviewedAt
                    : reviewedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            rejectionReason:
                freezed == rejectionReason
                    ? _value.rejectionReason
                    : rejectionReason // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KycApplicationImplCopyWith<$Res>
    implements $KycApplicationCopyWith<$Res> {
  factory _$$KycApplicationImplCopyWith(
    _$KycApplicationImpl value,
    $Res Function(_$KycApplicationImpl) then,
  ) = __$$KycApplicationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String applicationId,
    KycStatus status,
    KycJurisdiction jurisdiction,
    int completedSteps,
    DateTime createdAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
  });
}

/// @nodoc
class __$$KycApplicationImplCopyWithImpl<$Res>
    extends _$KycApplicationCopyWithImpl<$Res, _$KycApplicationImpl>
    implements _$$KycApplicationImplCopyWith<$Res> {
  __$$KycApplicationImplCopyWithImpl(
    _$KycApplicationImpl _value,
    $Res Function(_$KycApplicationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KycApplication
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? applicationId = null,
    Object? status = null,
    Object? jurisdiction = null,
    Object? completedSteps = null,
    Object? createdAt = null,
    Object? submittedAt = freezed,
    Object? reviewedAt = freezed,
    Object? rejectionReason = freezed,
  }) {
    return _then(
      _$KycApplicationImpl(
        applicationId:
            null == applicationId
                ? _value.applicationId
                : applicationId // ignore: cast_nullable_to_non_nullable
                    as String,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as KycStatus,
        jurisdiction:
            null == jurisdiction
                ? _value.jurisdiction
                : jurisdiction // ignore: cast_nullable_to_non_nullable
                    as KycJurisdiction,
        completedSteps:
            null == completedSteps
                ? _value.completedSteps
                : completedSteps // ignore: cast_nullable_to_non_nullable
                    as int,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        submittedAt:
            freezed == submittedAt
                ? _value.submittedAt
                : submittedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        reviewedAt:
            freezed == reviewedAt
                ? _value.reviewedAt
                : reviewedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        rejectionReason:
            freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$KycApplicationImpl implements _KycApplication {
  const _$KycApplicationImpl({
    required this.applicationId,
    required this.status,
    required this.jurisdiction,
    required this.completedSteps,
    required this.createdAt,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  factory _$KycApplicationImpl.fromJson(Map<String, dynamic> json) =>
      _$$KycApplicationImplFromJson(json);

  @override
  final String applicationId;
  @override
  final KycStatus status;
  @override
  final KycJurisdiction jurisdiction;
  @override
  final int completedSteps;
  // 0-7
  @override
  final DateTime createdAt;
  // UTC
  @override
  final DateTime? submittedAt;
  // UTC
  @override
  final DateTime? reviewedAt;
  // UTC
  @override
  final String? rejectionReason;

  @override
  String toString() {
    return 'KycApplication(applicationId: $applicationId, status: $status, jurisdiction: $jurisdiction, completedSteps: $completedSteps, createdAt: $createdAt, submittedAt: $submittedAt, reviewedAt: $reviewedAt, rejectionReason: $rejectionReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KycApplicationImpl &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.jurisdiction, jurisdiction) ||
                other.jurisdiction == jurisdiction) &&
            (identical(other.completedSteps, completedSteps) ||
                other.completedSteps == completedSteps) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.submittedAt, submittedAt) ||
                other.submittedAt == submittedAt) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    applicationId,
    status,
    jurisdiction,
    completedSteps,
    createdAt,
    submittedAt,
    reviewedAt,
    rejectionReason,
  );

  /// Create a copy of KycApplication
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KycApplicationImplCopyWith<_$KycApplicationImpl> get copyWith =>
      __$$KycApplicationImplCopyWithImpl<_$KycApplicationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$KycApplicationImplToJson(this);
  }
}

abstract class _KycApplication implements KycApplication {
  const factory _KycApplication({
    required final String applicationId,
    required final KycStatus status,
    required final KycJurisdiction jurisdiction,
    required final int completedSteps,
    required final DateTime createdAt,
    final DateTime? submittedAt,
    final DateTime? reviewedAt,
    final String? rejectionReason,
  }) = _$KycApplicationImpl;

  factory _KycApplication.fromJson(Map<String, dynamic> json) =
      _$KycApplicationImpl.fromJson;

  @override
  String get applicationId;
  @override
  KycStatus get status;
  @override
  KycJurisdiction get jurisdiction;
  @override
  int get completedSteps; // 0-7
  @override
  DateTime get createdAt; // UTC
  @override
  DateTime? get submittedAt; // UTC
  @override
  DateTime? get reviewedAt; // UTC
  @override
  String? get rejectionReason;

  /// Create a copy of KycApplication
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KycApplicationImplCopyWith<_$KycApplicationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
