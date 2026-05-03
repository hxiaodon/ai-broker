// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfileModel {

@JsonKey(name: 'account_id') String get accountId;@JsonKey(name: 'full_name') String get fullName; String get phone; String get email;@JsonKey(name: 'id_number') String get idNumber;@JsonKey(name: 'id_type') String get idType;@JsonKey(name: 'date_of_birth') String get dateOfBirth; String get country; String get province; String get city; String get address;@JsonKey(name: 'employment_status') String get employmentStatus; String? get employer; String? get industry;@JsonKey(name: 'kyc_tier') int get kycTier;@JsonKey(name: 'account_opened_at') String get accountOpenedAt;@JsonKey(name: 'account_type') String get accountType;
/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileModelCopyWith<UserProfileModel> get copyWith => _$UserProfileModelCopyWithImpl<UserProfileModel>(this as UserProfileModel, _$identity);

  /// Serializes this UserProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfileModel&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.idType, idType) || other.idType == idType)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.country, country) || other.country == country)&&(identical(other.province, province) || other.province == province)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employer, employer) || other.employer == employer)&&(identical(other.industry, industry) || other.industry == industry)&&(identical(other.kycTier, kycTier) || other.kycTier == kycTier)&&(identical(other.accountOpenedAt, accountOpenedAt) || other.accountOpenedAt == accountOpenedAt)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,fullName,phone,email,idNumber,idType,dateOfBirth,country,province,city,address,employmentStatus,employer,industry,kycTier,accountOpenedAt,accountType);

@override
String toString() {
  return 'UserProfileModel(accountId: $accountId, fullName: $fullName, phone: $phone, email: $email, idNumber: $idNumber, idType: $idType, dateOfBirth: $dateOfBirth, country: $country, province: $province, city: $city, address: $address, employmentStatus: $employmentStatus, employer: $employer, industry: $industry, kycTier: $kycTier, accountOpenedAt: $accountOpenedAt, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class $UserProfileModelCopyWith<$Res>  {
  factory $UserProfileModelCopyWith(UserProfileModel value, $Res Function(UserProfileModel) _then) = _$UserProfileModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'full_name') String fullName, String phone, String email,@JsonKey(name: 'id_number') String idNumber,@JsonKey(name: 'id_type') String idType,@JsonKey(name: 'date_of_birth') String dateOfBirth, String country, String province, String city, String address,@JsonKey(name: 'employment_status') String employmentStatus, String? employer, String? industry,@JsonKey(name: 'kyc_tier') int kycTier,@JsonKey(name: 'account_opened_at') String accountOpenedAt,@JsonKey(name: 'account_type') String accountType
});




}
/// @nodoc
class _$UserProfileModelCopyWithImpl<$Res>
    implements $UserProfileModelCopyWith<$Res> {
  _$UserProfileModelCopyWithImpl(this._self, this._then);

  final UserProfileModel _self;
  final $Res Function(UserProfileModel) _then;

/// Create a copy of UserProfileModel
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
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as String,employer: freezed == employer ? _self.employer : employer // ignore: cast_nullable_to_non_nullable
as String?,industry: freezed == industry ? _self.industry : industry // ignore: cast_nullable_to_non_nullable
as String?,kycTier: null == kycTier ? _self.kycTier : kycTier // ignore: cast_nullable_to_non_nullable
as int,accountOpenedAt: null == accountOpenedAt ? _self.accountOpenedAt : accountOpenedAt // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfileModel].
extension UserProfileModelPatterns on UserProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _UserProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'full_name')  String fullName,  String phone,  String email, @JsonKey(name: 'id_number')  String idNumber, @JsonKey(name: 'id_type')  String idType, @JsonKey(name: 'date_of_birth')  String dateOfBirth,  String country,  String province,  String city,  String address, @JsonKey(name: 'employment_status')  String employmentStatus,  String? employer,  String? industry, @JsonKey(name: 'kyc_tier')  int kycTier, @JsonKey(name: 'account_opened_at')  String accountOpenedAt, @JsonKey(name: 'account_type')  String accountType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'full_name')  String fullName,  String phone,  String email, @JsonKey(name: 'id_number')  String idNumber, @JsonKey(name: 'id_type')  String idType, @JsonKey(name: 'date_of_birth')  String dateOfBirth,  String country,  String province,  String city,  String address, @JsonKey(name: 'employment_status')  String employmentStatus,  String? employer,  String? industry, @JsonKey(name: 'kyc_tier')  int kycTier, @JsonKey(name: 'account_opened_at')  String accountOpenedAt, @JsonKey(name: 'account_type')  String accountType)  $default,) {final _that = this;
switch (_that) {
case _UserProfileModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'full_name')  String fullName,  String phone,  String email, @JsonKey(name: 'id_number')  String idNumber, @JsonKey(name: 'id_type')  String idType, @JsonKey(name: 'date_of_birth')  String dateOfBirth,  String country,  String province,  String city,  String address, @JsonKey(name: 'employment_status')  String employmentStatus,  String? employer,  String? industry, @JsonKey(name: 'kyc_tier')  int kycTier, @JsonKey(name: 'account_opened_at')  String accountOpenedAt, @JsonKey(name: 'account_type')  String accountType)?  $default,) {final _that = this;
switch (_that) {
case _UserProfileModel() when $default != null:
return $default(_that.accountId,_that.fullName,_that.phone,_that.email,_that.idNumber,_that.idType,_that.dateOfBirth,_that.country,_that.province,_that.city,_that.address,_that.employmentStatus,_that.employer,_that.industry,_that.kycTier,_that.accountOpenedAt,_that.accountType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfileModel extends UserProfileModel {
  const _UserProfileModel({@JsonKey(name: 'account_id') required this.accountId, @JsonKey(name: 'full_name') required this.fullName, required this.phone, required this.email, @JsonKey(name: 'id_number') required this.idNumber, @JsonKey(name: 'id_type') required this.idType, @JsonKey(name: 'date_of_birth') required this.dateOfBirth, required this.country, this.province = '', this.city = '', this.address = '', @JsonKey(name: 'employment_status') required this.employmentStatus, this.employer, this.industry, @JsonKey(name: 'kyc_tier') required this.kycTier, @JsonKey(name: 'account_opened_at') required this.accountOpenedAt, @JsonKey(name: 'account_type') this.accountType = 'INDIVIDUAL'}): super._();
  factory _UserProfileModel.fromJson(Map<String, dynamic> json) => _$UserProfileModelFromJson(json);

@override@JsonKey(name: 'account_id') final  String accountId;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  String phone;
@override final  String email;
@override@JsonKey(name: 'id_number') final  String idNumber;
@override@JsonKey(name: 'id_type') final  String idType;
@override@JsonKey(name: 'date_of_birth') final  String dateOfBirth;
@override final  String country;
@override@JsonKey() final  String province;
@override@JsonKey() final  String city;
@override@JsonKey() final  String address;
@override@JsonKey(name: 'employment_status') final  String employmentStatus;
@override final  String? employer;
@override final  String? industry;
@override@JsonKey(name: 'kyc_tier') final  int kycTier;
@override@JsonKey(name: 'account_opened_at') final  String accountOpenedAt;
@override@JsonKey(name: 'account_type') final  String accountType;

/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileModelCopyWith<_UserProfileModel> get copyWith => __$UserProfileModelCopyWithImpl<_UserProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfileModel&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.idNumber, idNumber) || other.idNumber == idNumber)&&(identical(other.idType, idType) || other.idType == idType)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.country, country) || other.country == country)&&(identical(other.province, province) || other.province == province)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address)&&(identical(other.employmentStatus, employmentStatus) || other.employmentStatus == employmentStatus)&&(identical(other.employer, employer) || other.employer == employer)&&(identical(other.industry, industry) || other.industry == industry)&&(identical(other.kycTier, kycTier) || other.kycTier == kycTier)&&(identical(other.accountOpenedAt, accountOpenedAt) || other.accountOpenedAt == accountOpenedAt)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,fullName,phone,email,idNumber,idType,dateOfBirth,country,province,city,address,employmentStatus,employer,industry,kycTier,accountOpenedAt,accountType);

@override
String toString() {
  return 'UserProfileModel(accountId: $accountId, fullName: $fullName, phone: $phone, email: $email, idNumber: $idNumber, idType: $idType, dateOfBirth: $dateOfBirth, country: $country, province: $province, city: $city, address: $address, employmentStatus: $employmentStatus, employer: $employer, industry: $industry, kycTier: $kycTier, accountOpenedAt: $accountOpenedAt, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class _$UserProfileModelCopyWith<$Res> implements $UserProfileModelCopyWith<$Res> {
  factory _$UserProfileModelCopyWith(_UserProfileModel value, $Res Function(_UserProfileModel) _then) = __$UserProfileModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'full_name') String fullName, String phone, String email,@JsonKey(name: 'id_number') String idNumber,@JsonKey(name: 'id_type') String idType,@JsonKey(name: 'date_of_birth') String dateOfBirth, String country, String province, String city, String address,@JsonKey(name: 'employment_status') String employmentStatus, String? employer, String? industry,@JsonKey(name: 'kyc_tier') int kycTier,@JsonKey(name: 'account_opened_at') String accountOpenedAt,@JsonKey(name: 'account_type') String accountType
});




}
/// @nodoc
class __$UserProfileModelCopyWithImpl<$Res>
    implements _$UserProfileModelCopyWith<$Res> {
  __$UserProfileModelCopyWithImpl(this._self, this._then);

  final _UserProfileModel _self;
  final $Res Function(_UserProfileModel) _then;

/// Create a copy of UserProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? fullName = null,Object? phone = null,Object? email = null,Object? idNumber = null,Object? idType = null,Object? dateOfBirth = null,Object? country = null,Object? province = null,Object? city = null,Object? address = null,Object? employmentStatus = null,Object? employer = freezed,Object? industry = freezed,Object? kycTier = null,Object? accountOpenedAt = null,Object? accountType = null,}) {
  return _then(_UserProfileModel(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,idNumber: null == idNumber ? _self.idNumber : idNumber // ignore: cast_nullable_to_non_nullable
as String,idType: null == idType ? _self.idType : idType // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,employmentStatus: null == employmentStatus ? _self.employmentStatus : employmentStatus // ignore: cast_nullable_to_non_nullable
as String,employer: freezed == employer ? _self.employer : employer // ignore: cast_nullable_to_non_nullable
as String?,industry: freezed == industry ? _self.industry : industry // ignore: cast_nullable_to_non_nullable
as String?,kycTier: null == kycTier ? _self.kycTier : kycTier // ignore: cast_nullable_to_non_nullable
as int,accountOpenedAt: null == accountOpenedAt ? _self.accountOpenedAt : accountOpenedAt // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
