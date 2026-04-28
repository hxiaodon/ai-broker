// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tax_form.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$W8BenInfo {

 String get fullName; String get countryOfTaxResidence; String? get tin; bool get tinNotAvailable; String? get address; DateTime get signatureDate;
/// Create a copy of W8BenInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$W8BenInfoCopyWith<W8BenInfo> get copyWith => _$W8BenInfoCopyWithImpl<W8BenInfo>(this as W8BenInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is W8BenInfo&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.countryOfTaxResidence, countryOfTaxResidence) || other.countryOfTaxResidence == countryOfTaxResidence)&&(identical(other.tin, tin) || other.tin == tin)&&(identical(other.tinNotAvailable, tinNotAvailable) || other.tinNotAvailable == tinNotAvailable)&&(identical(other.address, address) || other.address == address)&&(identical(other.signatureDate, signatureDate) || other.signatureDate == signatureDate));
}


@override
int get hashCode => Object.hash(runtimeType,fullName,countryOfTaxResidence,tin,tinNotAvailable,address,signatureDate);

@override
String toString() {
  return 'W8BenInfo(fullName: $fullName, countryOfTaxResidence: $countryOfTaxResidence, tin: $tin, tinNotAvailable: $tinNotAvailable, address: $address, signatureDate: $signatureDate)';
}


}

/// @nodoc
abstract mixin class $W8BenInfoCopyWith<$Res>  {
  factory $W8BenInfoCopyWith(W8BenInfo value, $Res Function(W8BenInfo) _then) = _$W8BenInfoCopyWithImpl;
@useResult
$Res call({
 String fullName, String countryOfTaxResidence, String? tin, bool tinNotAvailable, String? address, DateTime signatureDate
});




}
/// @nodoc
class _$W8BenInfoCopyWithImpl<$Res>
    implements $W8BenInfoCopyWith<$Res> {
  _$W8BenInfoCopyWithImpl(this._self, this._then);

  final W8BenInfo _self;
  final $Res Function(W8BenInfo) _then;

/// Create a copy of W8BenInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? countryOfTaxResidence = null,Object? tin = freezed,Object? tinNotAvailable = null,Object? address = freezed,Object? signatureDate = null,}) {
  return _then(_self.copyWith(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,countryOfTaxResidence: null == countryOfTaxResidence ? _self.countryOfTaxResidence : countryOfTaxResidence // ignore: cast_nullable_to_non_nullable
as String,tin: freezed == tin ? _self.tin : tin // ignore: cast_nullable_to_non_nullable
as String?,tinNotAvailable: null == tinNotAvailable ? _self.tinNotAvailable : tinNotAvailable // ignore: cast_nullable_to_non_nullable
as bool,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,signatureDate: null == signatureDate ? _self.signatureDate : signatureDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [W8BenInfo].
extension W8BenInfoPatterns on W8BenInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _W8BenInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _W8BenInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _W8BenInfo value)  $default,){
final _that = this;
switch (_that) {
case _W8BenInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _W8BenInfo value)?  $default,){
final _that = this;
switch (_that) {
case _W8BenInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String countryOfTaxResidence,  String? tin,  bool tinNotAvailable,  String? address,  DateTime signatureDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _W8BenInfo() when $default != null:
return $default(_that.fullName,_that.countryOfTaxResidence,_that.tin,_that.tinNotAvailable,_that.address,_that.signatureDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String countryOfTaxResidence,  String? tin,  bool tinNotAvailable,  String? address,  DateTime signatureDate)  $default,) {final _that = this;
switch (_that) {
case _W8BenInfo():
return $default(_that.fullName,_that.countryOfTaxResidence,_that.tin,_that.tinNotAvailable,_that.address,_that.signatureDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String countryOfTaxResidence,  String? tin,  bool tinNotAvailable,  String? address,  DateTime signatureDate)?  $default,) {final _that = this;
switch (_that) {
case _W8BenInfo() when $default != null:
return $default(_that.fullName,_that.countryOfTaxResidence,_that.tin,_that.tinNotAvailable,_that.address,_that.signatureDate);case _:
  return null;

}
}

}

/// @nodoc


class _W8BenInfo implements W8BenInfo {
  const _W8BenInfo({required this.fullName, required this.countryOfTaxResidence, this.tin, this.tinNotAvailable = false, this.address, required this.signatureDate});
  

@override final  String fullName;
@override final  String countryOfTaxResidence;
@override final  String? tin;
@override@JsonKey() final  bool tinNotAvailable;
@override final  String? address;
@override final  DateTime signatureDate;

/// Create a copy of W8BenInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$W8BenInfoCopyWith<_W8BenInfo> get copyWith => __$W8BenInfoCopyWithImpl<_W8BenInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _W8BenInfo&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.countryOfTaxResidence, countryOfTaxResidence) || other.countryOfTaxResidence == countryOfTaxResidence)&&(identical(other.tin, tin) || other.tin == tin)&&(identical(other.tinNotAvailable, tinNotAvailable) || other.tinNotAvailable == tinNotAvailable)&&(identical(other.address, address) || other.address == address)&&(identical(other.signatureDate, signatureDate) || other.signatureDate == signatureDate));
}


@override
int get hashCode => Object.hash(runtimeType,fullName,countryOfTaxResidence,tin,tinNotAvailable,address,signatureDate);

@override
String toString() {
  return 'W8BenInfo(fullName: $fullName, countryOfTaxResidence: $countryOfTaxResidence, tin: $tin, tinNotAvailable: $tinNotAvailable, address: $address, signatureDate: $signatureDate)';
}


}

/// @nodoc
abstract mixin class _$W8BenInfoCopyWith<$Res> implements $W8BenInfoCopyWith<$Res> {
  factory _$W8BenInfoCopyWith(_W8BenInfo value, $Res Function(_W8BenInfo) _then) = __$W8BenInfoCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String countryOfTaxResidence, String? tin, bool tinNotAvailable, String? address, DateTime signatureDate
});




}
/// @nodoc
class __$W8BenInfoCopyWithImpl<$Res>
    implements _$W8BenInfoCopyWith<$Res> {
  __$W8BenInfoCopyWithImpl(this._self, this._then);

  final _W8BenInfo _self;
  final $Res Function(_W8BenInfo) _then;

/// Create a copy of W8BenInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? countryOfTaxResidence = null,Object? tin = freezed,Object? tinNotAvailable = null,Object? address = freezed,Object? signatureDate = null,}) {
  return _then(_W8BenInfo(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,countryOfTaxResidence: null == countryOfTaxResidence ? _self.countryOfTaxResidence : countryOfTaxResidence // ignore: cast_nullable_to_non_nullable
as String,tin: freezed == tin ? _self.tin : tin // ignore: cast_nullable_to_non_nullable
as String?,tinNotAvailable: null == tinNotAvailable ? _self.tinNotAvailable : tinNotAvailable // ignore: cast_nullable_to_non_nullable
as bool,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,signatureDate: null == signatureDate ? _self.signatureDate : signatureDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$W9Info {

 String get fullName; String get ssn; String get address;
/// Create a copy of W9Info
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$W9InfoCopyWith<W9Info> get copyWith => _$W9InfoCopyWithImpl<W9Info>(this as W9Info, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is W9Info&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.ssn, ssn) || other.ssn == ssn)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,fullName,ssn,address);

@override
String toString() {
  return 'W9Info(fullName: $fullName, ssn: $ssn, address: $address)';
}


}

/// @nodoc
abstract mixin class $W9InfoCopyWith<$Res>  {
  factory $W9InfoCopyWith(W9Info value, $Res Function(W9Info) _then) = _$W9InfoCopyWithImpl;
@useResult
$Res call({
 String fullName, String ssn, String address
});




}
/// @nodoc
class _$W9InfoCopyWithImpl<$Res>
    implements $W9InfoCopyWith<$Res> {
  _$W9InfoCopyWithImpl(this._self, this._then);

  final W9Info _self;
  final $Res Function(W9Info) _then;

/// Create a copy of W9Info
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? ssn = null,Object? address = null,}) {
  return _then(_self.copyWith(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,ssn: null == ssn ? _self.ssn : ssn // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [W9Info].
extension W9InfoPatterns on W9Info {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _W9Info value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _W9Info() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _W9Info value)  $default,){
final _that = this;
switch (_that) {
case _W9Info():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _W9Info value)?  $default,){
final _that = this;
switch (_that) {
case _W9Info() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String ssn,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _W9Info() when $default != null:
return $default(_that.fullName,_that.ssn,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String ssn,  String address)  $default,) {final _that = this;
switch (_that) {
case _W9Info():
return $default(_that.fullName,_that.ssn,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String ssn,  String address)?  $default,) {final _that = this;
switch (_that) {
case _W9Info() when $default != null:
return $default(_that.fullName,_that.ssn,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _W9Info implements W9Info {
  const _W9Info({required this.fullName, required this.ssn, required this.address});
  

@override final  String fullName;
@override final  String ssn;
@override final  String address;

/// Create a copy of W9Info
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$W9InfoCopyWith<_W9Info> get copyWith => __$W9InfoCopyWithImpl<_W9Info>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _W9Info&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.ssn, ssn) || other.ssn == ssn)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,fullName,ssn,address);

@override
String toString() {
  return 'W9Info(fullName: $fullName, ssn: $ssn, address: $address)';
}


}

/// @nodoc
abstract mixin class _$W9InfoCopyWith<$Res> implements $W9InfoCopyWith<$Res> {
  factory _$W9InfoCopyWith(_W9Info value, $Res Function(_W9Info) _then) = __$W9InfoCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String ssn, String address
});




}
/// @nodoc
class __$W9InfoCopyWithImpl<$Res>
    implements _$W9InfoCopyWith<$Res> {
  __$W9InfoCopyWithImpl(this._self, this._then);

  final _W9Info _self;
  final $Res Function(_W9Info) _then;

/// Create a copy of W9Info
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? ssn = null,Object? address = null,}) {
  return _then(_W9Info(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,ssn: null == ssn ? _self.ssn : ssn // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TaxForm {

 TaxFormType get type; W8BenInfo? get w8ben; W9Info? get w9;
/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaxFormCopyWith<TaxForm> get copyWith => _$TaxFormCopyWithImpl<TaxForm>(this as TaxForm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaxForm&&(identical(other.type, type) || other.type == type)&&(identical(other.w8ben, w8ben) || other.w8ben == w8ben)&&(identical(other.w9, w9) || other.w9 == w9));
}


@override
int get hashCode => Object.hash(runtimeType,type,w8ben,w9);

@override
String toString() {
  return 'TaxForm(type: $type, w8ben: $w8ben, w9: $w9)';
}


}

/// @nodoc
abstract mixin class $TaxFormCopyWith<$Res>  {
  factory $TaxFormCopyWith(TaxForm value, $Res Function(TaxForm) _then) = _$TaxFormCopyWithImpl;
@useResult
$Res call({
 TaxFormType type, W8BenInfo? w8ben, W9Info? w9
});


$W8BenInfoCopyWith<$Res>? get w8ben;$W9InfoCopyWith<$Res>? get w9;

}
/// @nodoc
class _$TaxFormCopyWithImpl<$Res>
    implements $TaxFormCopyWith<$Res> {
  _$TaxFormCopyWithImpl(this._self, this._then);

  final TaxForm _self;
  final $Res Function(TaxForm) _then;

/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? w8ben = freezed,Object? w9 = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TaxFormType,w8ben: freezed == w8ben ? _self.w8ben : w8ben // ignore: cast_nullable_to_non_nullable
as W8BenInfo?,w9: freezed == w9 ? _self.w9 : w9 // ignore: cast_nullable_to_non_nullable
as W9Info?,
  ));
}
/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$W8BenInfoCopyWith<$Res>? get w8ben {
    if (_self.w8ben == null) {
    return null;
  }

  return $W8BenInfoCopyWith<$Res>(_self.w8ben!, (value) {
    return _then(_self.copyWith(w8ben: value));
  });
}/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$W9InfoCopyWith<$Res>? get w9 {
    if (_self.w9 == null) {
    return null;
  }

  return $W9InfoCopyWith<$Res>(_self.w9!, (value) {
    return _then(_self.copyWith(w9: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaxForm].
extension TaxFormPatterns on TaxForm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaxForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaxForm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaxForm value)  $default,){
final _that = this;
switch (_that) {
case _TaxForm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaxForm value)?  $default,){
final _that = this;
switch (_that) {
case _TaxForm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TaxFormType type,  W8BenInfo? w8ben,  W9Info? w9)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaxForm() when $default != null:
return $default(_that.type,_that.w8ben,_that.w9);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TaxFormType type,  W8BenInfo? w8ben,  W9Info? w9)  $default,) {final _that = this;
switch (_that) {
case _TaxForm():
return $default(_that.type,_that.w8ben,_that.w9);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TaxFormType type,  W8BenInfo? w8ben,  W9Info? w9)?  $default,) {final _that = this;
switch (_that) {
case _TaxForm() when $default != null:
return $default(_that.type,_that.w8ben,_that.w9);case _:
  return null;

}
}

}

/// @nodoc


class _TaxForm implements TaxForm {
  const _TaxForm({required this.type, this.w8ben, this.w9});
  

@override final  TaxFormType type;
@override final  W8BenInfo? w8ben;
@override final  W9Info? w9;

/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaxFormCopyWith<_TaxForm> get copyWith => __$TaxFormCopyWithImpl<_TaxForm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaxForm&&(identical(other.type, type) || other.type == type)&&(identical(other.w8ben, w8ben) || other.w8ben == w8ben)&&(identical(other.w9, w9) || other.w9 == w9));
}


@override
int get hashCode => Object.hash(runtimeType,type,w8ben,w9);

@override
String toString() {
  return 'TaxForm(type: $type, w8ben: $w8ben, w9: $w9)';
}


}

/// @nodoc
abstract mixin class _$TaxFormCopyWith<$Res> implements $TaxFormCopyWith<$Res> {
  factory _$TaxFormCopyWith(_TaxForm value, $Res Function(_TaxForm) _then) = __$TaxFormCopyWithImpl;
@override @useResult
$Res call({
 TaxFormType type, W8BenInfo? w8ben, W9Info? w9
});


@override $W8BenInfoCopyWith<$Res>? get w8ben;@override $W9InfoCopyWith<$Res>? get w9;

}
/// @nodoc
class __$TaxFormCopyWithImpl<$Res>
    implements _$TaxFormCopyWith<$Res> {
  __$TaxFormCopyWithImpl(this._self, this._then);

  final _TaxForm _self;
  final $Res Function(_TaxForm) _then;

/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? w8ben = freezed,Object? w9 = freezed,}) {
  return _then(_TaxForm(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TaxFormType,w8ben: freezed == w8ben ? _self.w8ben : w8ben // ignore: cast_nullable_to_non_nullable
as W8BenInfo?,w9: freezed == w9 ? _self.w9 : w9 // ignore: cast_nullable_to_non_nullable
as W9Info?,
  ));
}

/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$W8BenInfoCopyWith<$Res>? get w8ben {
    if (_self.w8ben == null) {
    return null;
  }

  return $W8BenInfoCopyWith<$Res>(_self.w8ben!, (value) {
    return _then(_self.copyWith(w8ben: value));
  });
}/// Create a copy of TaxForm
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$W9InfoCopyWith<$Res>? get w9 {
    if (_self.w9 == null) {
    return null;
  }

  return $W9InfoCopyWith<$Res>(_self.w9!, (value) {
    return _then(_self.copyWith(w9: value));
  });
}
}

// dart format on
