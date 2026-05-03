// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfile {

 String get accountId; String get fullName; String get phone; String get email; String get idNumber; String get idType; DateTime get dateOfBirth; String get country; String get province; String get city; String get address; EmploymentStatus get employmentStatus; String? get employer; String? get industry; KycTier get kycTier; DateTime get accountOpenedAt; String get accountType;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.idType, idType) || other.idType == idType)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.country, country) || other.country == country)&&(identical(other.province, province) || other.province == province)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employer, employer) || other.employer == employer)&&(identical(other.industry, industry) || other.industry == industry)&&(identical(other.kycTier, kycTier) || other.kycTier == kycTier)&&(identical(other.accountOpenedAt, accountOpenedAt) || other.accountOpenedAt == accountOpenedAt)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,fullName,phone,email,idNumber,idType,dateOfBirth,country,province,city,address,employmentStatus,employer,industry,kycTier,accountOpenedAt,accountType);

@override
String toString() {
  return 'UserProfile(accountId: $accountId, fullName: $fullName, phone: $phone, email: $email, idNumber: $idNumber, idType: $idType, dateOfBirth: $dateOfBirth, country: $country, province: $province, city: $city, address: $address, employmentStatus: $employmentStatus, employer: $employer, industry: $industry, kycTier: $kycTier, accountOpenedAt: $accountOpenedAt, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String accountId, String fullName, String phone, String email, String idNumber, String idType, DateTime dateOfBirth, String country, String province, String city, String address, EmploymentStatus employmentStatus, String? employer, String? industry, KycTier kycTier, DateTime accountOpenedAt, String accountType
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? fullName = null,Object? phone = null,Object? email = null,Object? idNumber = null,Object? idType = null,Object? dateOfBirth = null,Object? country = null,Object? province = null,Object? city = null,Object? address = null,Object? employmentStatus = null,Object? employer = freezed,Object? industry = freezed,Object? kycTier = null,Object? accountOpenedAt = null,Object? accountType = null,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,idNumber: null == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String,idType: null == idType ? _self.idType : idType // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as EmploymentStatus,employer: freezed == employer ? _self.employer : employer // ignore: cast_nullable_to_non_nullable
as String?,industry: freezed == industry ? _self.industry : industry // ignore: cast_nullable_to_non_nullable
as String?,kycTier: null == kycTier ? _self.kycTier : kycTier // ignore: cast_nullable_to_non_nullable
as KycTier,accountOpenedAt: null == accountOpenedAt ? _self.accountOpenedAt : accountOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String fullName,  String phone,  String email,  String idNumber,  String idType,  DateTime dateOfBirth,  String country,  String province,  String city,  String address,  EmploymentStatus employmentStatus,  String? employer,  String? industry,  KycTier kycTier,  DateTime accountOpenedAt,  String accountType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.accountId,_that.fullName,_that.phone,_that.email,_that.idNumber,_that.idType,_that.dateOfBirth,_that.country,_that.province,_that.city,_that.address,_that.employmentStatus,_that.employer,_that.industry,_that.kycTier,_that.accountOpenedAt,_that.accountType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String fullName,  String phone,  String email,  String idNumber,  String idType,  DateTime dateOfBirth,  String country,  String province,  String city,  String address,  EmploymentStatus employmentStatus,  String? employer,  String? industry,  KycTier kycTier,  DateTime accountOpenedAt,  String accountType)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.accountId,_that.fullName,_that.phone,_that.email,_that.idNumber,_that.idType,_that.dateOfBirth,_that.country,_that.province,_that.city,_that.address,_that.employmentStatus,_that.employer,_that.industry,_that.kycTier,_that.accountOpenedAt,_that.accountType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String fullName,  String phone,  String email,  String idNumber,  String idType,  DateTime dateOfBirth,  String country,  String province,  String city,  String address,  EmploymentStatus employmentStatus,  String? employer,  String? industry,  KycTier kycTier,  DateTime accountOpenedAt,  String accountType)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.accountId,_that.fullName,_that.phone,_that.email,_that.idNumber,_that.idType,_that.dateOfBirth,_that.country,_that.province,_that.city,_that.address,_that.employmentStatus,_that.employer,_that.industry,_that.kycTier,_that.accountOpenedAt,_that.accountType);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfile extends UserProfile {
  const _UserProfile({required this.accountId, required this.fullName, required this.phone, required this.email, required this.idNumber, required this.idType, required this.dateOfBirth, required this.country, required this.province, required this.city, required this.address, required this.employmentStatus, this.employer, this.industry, required this.kycTier, required this.accountOpenedAt, required this.accountType}): super._();
  

@override final  String accountId;
@override final  String fullName;
@override final  String phone;
@override final  String email;
@override final  String idNumber;
@override final  String idType;
@override final  DateTime dateOfBirth;
@override final  String country;
@override final  String province;
@override final  String city;
@override final  String address;
@override final  EmploymentStatus employmentStatus;
@override final  String? employer;
@override final  String? industry;
@override final  KycTier kycTier;
@override final  DateTime accountOpenedAt;
@override final  String accountType;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.idType, idType) || other.idType == idType)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.country, country) || other.country == country)&&(identical(other.province, province) || other.province == province)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employer, employer) || other.employer == employer)&&(identical(other.industry, industry) || other.industry == industry)&&(identical(other.kycTier, kycTier) || other.kycTier == kycTier)&&(identical(other.accountOpenedAt, accountOpenedAt) || other.accountOpenedAt == accountOpenedAt)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,fullName,phone,email,idNumber,idType,dateOfBirth,country,province,city,address,employmentStatus,employer,industry,kycTier,accountOpenedAt,accountType);

@override
String toString() {
  return 'UserProfile(accountId: $accountId, fullName: $fullName, phone: $phone, email: $email, idNumber: $idNumber, idType: $idType, dateOfBirth: $dateOfBirth, country: $country, province: $province, city: $city, address: $address, employmentStatus: $employmentStatus, employer: $employer, industry: $industry, kycTier: $kycTier, accountOpenedAt: $accountOpenedAt, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String fullName, String phone, String email, String idNumber, String idType, DateTime dateOfBirth, String country, String province, String city, String address, EmploymentStatus employmentStatus, String? employer, String? industry, KycTier kycTier, DateTime accountOpenedAt, String accountType
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? fullName = null,Object? phone = null,Object? email = null,Object? idNumber = null,Object? idType = null,Object? dateOfBirth = null,Object? country = null,Object? province = null,Object? city = null,Object? address = null,Object? employmentStatus = null,Object? employer = freezed,Object? industry = freezed,Object? kycTier = null,Object? accountOpenedAt = null,Object? accountType = null,}) {
  return _then(_UserProfile(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,idNumber: null == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String,idType: null == idType ? _self.idType : idType // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as DateTime,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as EmploymentStatus,employer: freezed == employer ? _self.employer : employer // ignore: cast_nullable_to_non_nullable
as String?,industry: freezed == industry ? _self.industry : industry // ignore: cast_nullable_to_non_nullable
as String?,kycTier: null == kycTier ? _self.kycTier : kycTier // ignore: cast_nullable_to_non_nullable
as KycTier,accountOpenedAt: null == accountOpenedAt ? _self.accountOpenedAt : accountOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
