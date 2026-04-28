// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PersonalInfo {

 String get firstName; String get lastName; String? get chineseName; DateTime get dateOfBirth; String get nationality; IdType get idType; EmploymentStatus get employmentStatus; String? get employerName; bool get isPep; bool get isInsiderOfBroker;
/// Create a copy of PersonalInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalInfoCopyWith<PersonalInfo> get copyWith => _$PersonalInfoCopyWithImpl<PersonalInfo>(this as PersonalInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalInfo&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.chineseName, chineseName) || other.chineseName == chineseName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.idType, idType) || other.idType == idType)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employerName, employerName) || other.employerName == employerName)&&(identical(other.isPep, isPep) || other.isPep == isPep)&&(identical(other.isInsiderOfBroker, isInsiderOfBroker) || other.isInsiderOfBroker == isInsiderOfBroker));
}


@override
int get hashCode => Object.hash(runtimeType,firstName,lastName,chineseName,dateOfBirth,nationality,idType,employmentStatus,employerName,isPep,isInsiderOfBroker);

@override
String toString() {
  return 'PersonalInfo(firstName: $firstName, lastName: $lastName, chineseName: $chineseName, dateOfBirth: $dateOfBirth, nationality: $nationality, idType: $idType, employmentStatus: $employmentStatus, employerName: $employerName, isPep: $isPep, isInsiderOfBroker: $isInsiderOfBroker)';
}


}

/// @nodoc
abstract mixin class $PersonalInfoCopyWith<$Res>  {
  factory $PersonalInfoCopyWith(PersonalInfo value, $Res Function(PersonalInfo) _then) = _$PersonalInfoCopyWithImpl;
@useResult
$Res call({
 String firstName, String lastName, String? chineseName, DateTime dateOfBirth, String nationality, IdType idType, EmploymentStatus employmentStatus, String? employerName, bool isPep, bool isInsiderOfBroker
});




}
/// @nodoc
class _$PersonalInfoCopyWithImpl<$Res>
    implements $PersonalInfoCopyWith<$Res> {
  _$PersonalInfoCopyWithImpl(this._self, this._then);

  final PersonalInfo _self;
  final $Res Function(PersonalInfo) _then;

/// Create a copy of PersonalInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstName = null,Object? lastName = null,Object? chineseName = freezed,Object? dateOfBirth = null,Object? nationality = null,Object? idType = null,Object? employmentStatus = null,Object? employerName = freezed,Object? isPep = null,Object? isInsiderOfBroker = null,}) {
  return _then(_self.copyWith(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,chineseName: freezed == chineseName ? _self.chineseName : chineseName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,nationality: null == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String,idType: null == idType ? _self.idType : idType // ignore: cast_nullable_to_non_nullable
as IdType,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as EmploymentStatus,employerName: freezed == employerName ? _self.employerName : employerName // ignore: cast_nullable_to_non_nullable
as String?,isPep: null == isPep ? _self.isPep : isPep // ignore: cast_nullable_to_non_nullable
as bool,isInsiderOfBroker: null == isInsiderOfBroker ? _self.isInsiderOfBroker : isInsiderOfBroker // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalInfo].
extension PersonalInfoPatterns on PersonalInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalInfo value)  $default,){
final _that = this;
switch (_that) {
case _PersonalInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalInfo value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String firstName,  String lastName,  String? chineseName,  DateTime dateOfBirth,  String nationality,  IdType idType,  EmploymentStatus employmentStatus,  String? employerName,  bool isPep,  bool isInsiderOfBroker)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalInfo() when $default != null:
return $default(_that.firstName,_that.lastName,_that.chineseName,_that.dateOfBirth,_that.nationality,_that.idType,_that.employmentStatus,_that.employerName,_that.isPep,_that.isInsiderOfBroker);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String firstName,  String lastName,  String? chineseName,  DateTime dateOfBirth,  String nationality,  IdType idType,  EmploymentStatus employmentStatus,  String? employerName,  bool isPep,  bool isInsiderOfBroker)  $default,) {final _that = this;
switch (_that) {
case _PersonalInfo():
return $default(_that.firstName,_that.lastName,_that.chineseName,_that.dateOfBirth,_that.nationality,_that.idType,_that.employmentStatus,_that.employerName,_that.isPep,_that.isInsiderOfBroker);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String firstName,  String lastName,  String? chineseName,  DateTime dateOfBirth,  String nationality,  IdType idType,  EmploymentStatus employmentStatus,  String? employerName,  bool isPep,  bool isInsiderOfBroker)?  $default,) {final _that = this;
switch (_that) {
case _PersonalInfo() when $default != null:
return $default(_that.firstName,_that.lastName,_that.chineseName,_that.dateOfBirth,_that.nationality,_that.idType,_that.employmentStatus,_that.employerName,_that.isPep,_that.isInsiderOfBroker);case _:
  return null;

}
}

}

/// @nodoc


class _PersonalInfo extends PersonalInfo {
  const _PersonalInfo({required this.firstName, required this.lastName, this.chineseName, required this.dateOfBirth, required this.nationality, required this.idType, required this.employmentStatus, this.employerName, this.isPep = false, this.isInsiderOfBroker = false}): super._();
  

@override final  String firstName;
@override final  String lastName;
@override final  String? chineseName;
@override final  DateTime dateOfBirth;
@override final  String nationality;
@override final  IdType idType;
@override final  EmploymentStatus employmentStatus;
@override final  String? employerName;
@override@JsonKey() final  bool isPep;
@override@JsonKey() final  bool isInsiderOfBroker;

/// Create a copy of PersonalInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalInfoCopyWith<_PersonalInfo> get copyWith => __$PersonalInfoCopyWithImpl<_PersonalInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalInfo&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.chineseName, chineseName) || other.chineseName == chineseName)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.idType, idType) || other.idType == idType)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employerName, employerName) || other.employerName == employerName)&&(identical(other.isPep, isPep) || other.isPep == isPep)&&(identical(other.isInsiderOfBroker, isInsiderOfBroker) || other.isInsiderOfBroker == isInsiderOfBroker));
}


@override
int get hashCode => Object.hash(runtimeType,firstName,lastName,chineseName,dateOfBirth,nationality,idType,employmentStatus,employerName,isPep,isInsiderOfBroker);

@override
String toString() {
  return 'PersonalInfo(firstName: $firstName, lastName: $lastName, chineseName: $chineseName, dateOfBirth: $dateOfBirth, nationality: $nationality, idType: $idType, employmentStatus: $employmentStatus, employerName: $employerName, isPep: $isPep, isInsiderOfBroker: $isInsiderOfBroker)';
}


}

/// @nodoc
abstract mixin class _$PersonalInfoCopyWith<$Res> implements $PersonalInfoCopyWith<$Res> {
  factory _$PersonalInfoCopyWith(_PersonalInfo value, $Res Function(_PersonalInfo) _then) = __$PersonalInfoCopyWithImpl;
@override @useResult
$Res call({
 String firstName, String lastName, String? chineseName, DateTime dateOfBirth, String nationality, IdType idType, EmploymentStatus employmentStatus, String? employerName, bool isPep, bool isInsiderOfBroker
});




}
/// @nodoc
class __$PersonalInfoCopyWithImpl<$Res>
    implements _$PersonalInfoCopyWith<$Res> {
  __$PersonalInfoCopyWithImpl(this._self, this._then);

  final _PersonalInfo _self;
  final $Res Function(_PersonalInfo) _then;

/// Create a copy of PersonalInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstName = null,Object? lastName = null,Object? chineseName = freezed,Object? dateOfBirth = null,Object? nationality = null,Object? idType = null,Object? employmentStatus = null,Object? employerName = freezed,Object? isPep = null,Object? isInsiderOfBroker = null,}) {
  return _then(_PersonalInfo(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,chineseName: freezed == chineseName ? _self.chineseName : chineseName // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,nationality: null == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String,idType: null == idType ? _self.idType : idType // ignore: cast_nullable_to_non_nullable
as IdType,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as EmploymentStatus,employerName: freezed == employerName ? _self.employerName : employerName // ignore: cast_nullable_to_non_nullable
as String?,isPep: null == isPep ? _self.isPep : isPep // ignore: cast_nullable_to_non_nullable
as bool,isInsiderOfBroker: null == isInsiderOfBroker ? _self.isInsiderOfBroker : isInsiderOfBroker // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
