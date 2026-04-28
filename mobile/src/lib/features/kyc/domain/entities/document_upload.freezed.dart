// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_upload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocumentUpload {

 String get documentId; DocumentType get type; DocumentUploadStatus get status; String? get sumsubApplicantId; String? get frontImagePath; String? get backImagePath;
/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentUploadCopyWith<DocumentUpload> get copyWith => _$DocumentUploadCopyWithImpl<DocumentUpload>(this as DocumentUpload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentUpload&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.sumsubApplicantId, sumsubApplicantId) || other.sumsubApplicantId == sumsubApplicantId)&&(identical(other.frontImagePath, frontImagePath) || other.frontImagePath == frontImagePath)&&(identical(other.backImagePath, backImagePath) || other.backImagePath == backImagePath));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,type,status,sumsubApplicantId,frontImagePath,backImagePath);

@override
String toString() {
  return 'DocumentUpload(documentId: $documentId, type: $type, status: $status, sumsubApplicantId: $sumsubApplicantId, frontImagePath: $frontImagePath, backImagePath: $backImagePath)';
}


}

/// @nodoc
abstract mixin class $DocumentUploadCopyWith<$Res>  {
  factory $DocumentUploadCopyWith(DocumentUpload value, $Res Function(DocumentUpload) _then) = _$DocumentUploadCopyWithImpl;
@useResult
$Res call({
 String documentId, DocumentType type, DocumentUploadStatus status, String? sumsubApplicantId, String? frontImagePath, String? backImagePath
});




}
/// @nodoc
class _$DocumentUploadCopyWithImpl<$Res>
    implements $DocumentUploadCopyWith<$Res> {
  _$DocumentUploadCopyWithImpl(this._self, this._then);

  final DocumentUpload _self;
  final $Res Function(DocumentUpload) _then;

/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? type = null,Object? status = null,Object? sumsubApplicantId = freezed,Object? frontImagePath = freezed,Object? backImagePath = freezed,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentUploadStatus,sumsubApplicantId: freezed == sumsubApplicantId ? _self.sumsubApplicantId : sumsubApplicantId // ignore: cast_nullable_to_non_nullable
as String?,frontImagePath: freezed == frontImagePath ? _self.frontImagePath : frontImagePath // ignore: cast_nullable_to_non_nullable
as String?,backImagePath: freezed == backImagePath ? _self.backImagePath : backImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentUpload].
extension DocumentUploadPatterns on DocumentUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentUpload value)  $default,){
final _that = this;
switch (_that) {
case _DocumentUpload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentUpload value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  DocumentType type,  DocumentUploadStatus status,  String? sumsubApplicantId,  String? frontImagePath,  String? backImagePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
return $default(_that.documentId,_that.type,_that.status,_that.sumsubApplicantId,_that.frontImagePath,_that.backImagePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  DocumentType type,  DocumentUploadStatus status,  String? sumsubApplicantId,  String? frontImagePath,  String? backImagePath)  $default,) {final _that = this;
switch (_that) {
case _DocumentUpload():
return $default(_that.documentId,_that.type,_that.status,_that.sumsubApplicantId,_that.frontImagePath,_that.backImagePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  DocumentType type,  DocumentUploadStatus status,  String? sumsubApplicantId,  String? frontImagePath,  String? backImagePath)?  $default,) {final _that = this;
switch (_that) {
case _DocumentUpload() when $default != null:
return $default(_that.documentId,_that.type,_that.status,_that.sumsubApplicantId,_that.frontImagePath,_that.backImagePath);case _:
  return null;

}
}

}

/// @nodoc


class _DocumentUpload implements DocumentUpload {
  const _DocumentUpload({required this.documentId, required this.type, required this.status, this.sumsubApplicantId, this.frontImagePath, this.backImagePath});
  

@override final  String documentId;
@override final  DocumentType type;
@override final  DocumentUploadStatus status;
@override final  String? sumsubApplicantId;
@override final  String? frontImagePath;
@override final  String? backImagePath;

/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentUploadCopyWith<_DocumentUpload> get copyWith => __$DocumentUploadCopyWithImpl<_DocumentUpload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentUpload&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.sumsubApplicantId, sumsubApplicantId) || other.sumsubApplicantId == sumsubApplicantId)&&(identical(other.frontImagePath, frontImagePath) || other.frontImagePath == frontImagePath)&&(identical(other.backImagePath, backImagePath) || other.backImagePath == backImagePath));
}


@override
int get hashCode => Object.hash(runtimeType,documentId,type,status,sumsubApplicantId,frontImagePath,backImagePath);

@override
String toString() {
  return 'DocumentUpload(documentId: $documentId, type: $type, status: $status, sumsubApplicantId: $sumsubApplicantId, frontImagePath: $frontImagePath, backImagePath: $backImagePath)';
}


}

/// @nodoc
abstract mixin class _$DocumentUploadCopyWith<$Res> implements $DocumentUploadCopyWith<$Res> {
  factory _$DocumentUploadCopyWith(_DocumentUpload value, $Res Function(_DocumentUpload) _then) = __$DocumentUploadCopyWithImpl;
@override @useResult
$Res call({
 String documentId, DocumentType type, DocumentUploadStatus status, String? sumsubApplicantId, String? frontImagePath, String? backImagePath
});




}
/// @nodoc
class __$DocumentUploadCopyWithImpl<$Res>
    implements _$DocumentUploadCopyWith<$Res> {
  __$DocumentUploadCopyWithImpl(this._self, this._then);

  final _DocumentUpload _self;
  final $Res Function(_DocumentUpload) _then;

/// Create a copy of DocumentUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? type = null,Object? status = null,Object? sumsubApplicantId = freezed,Object? frontImagePath = freezed,Object? backImagePath = freezed,}) {
  return _then(_DocumentUpload(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as DocumentType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentUploadStatus,sumsubApplicantId: freezed == sumsubApplicantId ? _self.sumsubApplicantId : sumsubApplicantId // ignore: cast_nullable_to_non_nullable
as String?,frontImagePath: freezed == frontImagePath ? _self.frontImagePath : frontImagePath // ignore: cast_nullable_to_non_nullable
as String?,backImagePath: freezed == backImagePath ? _self.backImagePath : backImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
