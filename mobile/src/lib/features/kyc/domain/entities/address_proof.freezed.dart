// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_proof.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddressProof {

 String get street; String get city; String get province; String get postalCode; String get country; String get proofDocumentPath; AddressProofDocType get proofDocumentType; String? get documentId;
/// Create a copy of AddressProof
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddressProofCopyWith<AddressProof> get copyWith => _$AddressProofCopyWithImpl<AddressProof>(this as AddressProof, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddressProof&&(identical(other.street, street) || other.street == street)&&(identical(other.city, city) || other.city == city)&&(identical(other.province, province) || other.province == province)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.country, country) || other.country == country)&&(identical(other.proofDocumentPath, proofDocumentPath) || other.proofDocumentPath == proofDocumentPath)&&(identical(other.proofDocumentType, proofDocumentType) || other.proofDocumentType == proofDocumentType)&&(identical(other.documentId, documentId) || other.documentId == documentId));
}


@override
int get hashCode => Object.hash(runtimeType,street,city,province,postalCode,country,proofDocumentPath,proofDocumentType,documentId);

@override
String toString() {
  return 'AddressProof(street: $street, city: $city, province: $province, postalCode: $postalCode, country: $country, proofDocumentPath: $proofDocumentPath, proofDocumentType: $proofDocumentType, documentId: $documentId)';
}


}

/// @nodoc
abstract mixin class $AddressProofCopyWith<$Res>  {
  factory $AddressProofCopyWith(AddressProof value, $Res Function(AddressProof) _then) = _$AddressProofCopyWithImpl;
@useResult
$Res call({
 String street, String city, String province, String postalCode, String country, String proofDocumentPath, AddressProofDocType proofDocumentType, String? documentId
});




}
/// @nodoc
class _$AddressProofCopyWithImpl<$Res>
    implements $AddressProofCopyWith<$Res> {
  _$AddressProofCopyWithImpl(this._self, this._then);

  final AddressProof _self;
  final $Res Function(AddressProof) _then;

/// Create a copy of AddressProof
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? street = null,Object? city = null,Object? province = null,Object? postalCode = null,Object? country = null,Object? proofDocumentPath = null,Object? proofDocumentType = null,Object? documentId = freezed,}) {
  return _then(_self.copyWith(
street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,proofDocumentPath: null == proofDocumentPath ? _self.proofDocumentPath : proofDocumentPath // ignore: cast_nullable_to_non_nullable
as String,proofDocumentType: null == proofDocumentType ? _self.proofDocumentType : proofDocumentType // ignore: cast_nullable_to_non_nullable
as AddressProofDocType,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AddressProof].
extension AddressProofPatterns on AddressProof {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddressProof value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddressProof() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddressProof value)  $default,){
final _that = this;
switch (_that) {
case _AddressProof():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddressProof value)?  $default,){
final _that = this;
switch (_that) {
case _AddressProof() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String street,  String city,  String province,  String postalCode,  String country,  String proofDocumentPath,  AddressProofDocType proofDocumentType,  String? documentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddressProof() when $default != null:
return $default(_that.street,_that.city,_that.province,_that.postalCode,_that.country,_that.proofDocumentPath,_that.proofDocumentType,_that.documentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String street,  String city,  String province,  String postalCode,  String country,  String proofDocumentPath,  AddressProofDocType proofDocumentType,  String? documentId)  $default,) {final _that = this;
switch (_that) {
case _AddressProof():
return $default(_that.street,_that.city,_that.province,_that.postalCode,_that.country,_that.proofDocumentPath,_that.proofDocumentType,_that.documentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String street,  String city,  String province,  String postalCode,  String country,  String proofDocumentPath,  AddressProofDocType proofDocumentType,  String? documentId)?  $default,) {final _that = this;
switch (_that) {
case _AddressProof() when $default != null:
return $default(_that.street,_that.city,_that.province,_that.postalCode,_that.country,_that.proofDocumentPath,_that.proofDocumentType,_that.documentId);case _:
  return null;

}
}

}

/// @nodoc


class _AddressProof implements AddressProof {
  const _AddressProof({required this.street, required this.city, required this.province, required this.postalCode, required this.country, required this.proofDocumentPath, required this.proofDocumentType, this.documentId});
  

@override final  String street;
@override final  String city;
@override final  String province;
@override final  String postalCode;
@override final  String country;
@override final  String proofDocumentPath;
@override final  AddressProofDocType proofDocumentType;
@override final  String? documentId;

/// Create a copy of AddressProof
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddressProofCopyWith<_AddressProof> get copyWith => __$AddressProofCopyWithImpl<_AddressProof>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddressProof&&(identical(other.street, street) || other.street == street)&&(identical(other.city, city) || other.city == city)&&(identical(other.province, province) || other.province == province)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.country, country) || other.country == country)&&(identical(other.proofDocumentPath, proofDocumentPath) || other.proofDocumentPath == proofDocumentPath)&&(identical(other.proofDocumentType, proofDocumentType) || other.proofDocumentType == proofDocumentType)&&(identical(other.documentId, documentId) || other.documentId == documentId));
}


@override
int get hashCode => Object.hash(runtimeType,street,city,province,postalCode,country,proofDocumentPath,proofDocumentType,documentId);

@override
String toString() {
  return 'AddressProof(street: $street, city: $city, province: $province, postalCode: $postalCode, country: $country, proofDocumentPath: $proofDocumentPath, proofDocumentType: $proofDocumentType, documentId: $documentId)';
}


}

/// @nodoc
abstract mixin class _$AddressProofCopyWith<$Res> implements $AddressProofCopyWith<$Res> {
  factory _$AddressProofCopyWith(_AddressProof value, $Res Function(_AddressProof) _then) = __$AddressProofCopyWithImpl;
@override @useResult
$Res call({
 String street, String city, String province, String postalCode, String country, String proofDocumentPath, AddressProofDocType proofDocumentType, String? documentId
});




}
/// @nodoc
class __$AddressProofCopyWithImpl<$Res>
    implements _$AddressProofCopyWith<$Res> {
  __$AddressProofCopyWithImpl(this._self, this._then);

  final _AddressProof _self;
  final $Res Function(_AddressProof) _then;

/// Create a copy of AddressProof
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? street = null,Object? city = null,Object? province = null,Object? postalCode = null,Object? country = null,Object? proofDocumentPath = null,Object? proofDocumentType = null,Object? documentId = freezed,}) {
  return _then(_AddressProof(
street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,province: null == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,proofDocumentPath: null == proofDocumentPath ? _self.proofDocumentPath : proofDocumentPath // ignore: cast_nullable_to_non_nullable
as String,proofDocumentType: null == proofDocumentType ? _self.proofDocumentType : proofDocumentType // ignore: cast_nullable_to_non_nullable
as AddressProofDocType,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
