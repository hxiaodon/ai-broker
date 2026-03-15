// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) {
  return _UserPreferences.fromJson(json);
}

/// @nodoc
mixin _$UserPreferences {
  TradingColorScheme get colorScheme => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError; // 'zh' or 'en'
  bool get biometricEnabled => throw _privateConstructorUsedError;
  bool get orderFillNotifications => throw _privateConstructorUsedError;
  bool get fundTransferNotifications => throw _privateConstructorUsedError;
  bool get priceAlertNotifications => throw _privateConstructorUsedError;
  String get defaultCurrency => throw _privateConstructorUsedError;

  /// Serializes this UserPreferences to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserPreferencesCopyWith<UserPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPreferencesCopyWith<$Res> {
  factory $UserPreferencesCopyWith(
    UserPreferences value,
    $Res Function(UserPreferences) then,
  ) = _$UserPreferencesCopyWithImpl<$Res, UserPreferences>;
  @useResult
  $Res call({
    TradingColorScheme colorScheme,
    String language,
    bool biometricEnabled,
    bool orderFillNotifications,
    bool fundTransferNotifications,
    bool priceAlertNotifications,
    String defaultCurrency,
  });
}

/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res, $Val extends UserPreferences>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? colorScheme = null,
    Object? language = null,
    Object? biometricEnabled = null,
    Object? orderFillNotifications = null,
    Object? fundTransferNotifications = null,
    Object? priceAlertNotifications = null,
    Object? defaultCurrency = null,
  }) {
    return _then(
      _value.copyWith(
            colorScheme:
                null == colorScheme
                    ? _value.colorScheme
                    : colorScheme // ignore: cast_nullable_to_non_nullable
                        as TradingColorScheme,
            language:
                null == language
                    ? _value.language
                    : language // ignore: cast_nullable_to_non_nullable
                        as String,
            biometricEnabled:
                null == biometricEnabled
                    ? _value.biometricEnabled
                    : biometricEnabled // ignore: cast_nullable_to_non_nullable
                        as bool,
            orderFillNotifications:
                null == orderFillNotifications
                    ? _value.orderFillNotifications
                    : orderFillNotifications // ignore: cast_nullable_to_non_nullable
                        as bool,
            fundTransferNotifications:
                null == fundTransferNotifications
                    ? _value.fundTransferNotifications
                    : fundTransferNotifications // ignore: cast_nullable_to_non_nullable
                        as bool,
            priceAlertNotifications:
                null == priceAlertNotifications
                    ? _value.priceAlertNotifications
                    : priceAlertNotifications // ignore: cast_nullable_to_non_nullable
                        as bool,
            defaultCurrency:
                null == defaultCurrency
                    ? _value.defaultCurrency
                    : defaultCurrency // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserPreferencesImplCopyWith<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  factory _$$UserPreferencesImplCopyWith(
    _$UserPreferencesImpl value,
    $Res Function(_$UserPreferencesImpl) then,
  ) = __$$UserPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    TradingColorScheme colorScheme,
    String language,
    bool biometricEnabled,
    bool orderFillNotifications,
    bool fundTransferNotifications,
    bool priceAlertNotifications,
    String defaultCurrency,
  });
}

/// @nodoc
class __$$UserPreferencesImplCopyWithImpl<$Res>
    extends _$UserPreferencesCopyWithImpl<$Res, _$UserPreferencesImpl>
    implements _$$UserPreferencesImplCopyWith<$Res> {
  __$$UserPreferencesImplCopyWithImpl(
    _$UserPreferencesImpl _value,
    $Res Function(_$UserPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? colorScheme = null,
    Object? language = null,
    Object? biometricEnabled = null,
    Object? orderFillNotifications = null,
    Object? fundTransferNotifications = null,
    Object? priceAlertNotifications = null,
    Object? defaultCurrency = null,
  }) {
    return _then(
      _$UserPreferencesImpl(
        colorScheme:
            null == colorScheme
                ? _value.colorScheme
                : colorScheme // ignore: cast_nullable_to_non_nullable
                    as TradingColorScheme,
        language:
            null == language
                ? _value.language
                : language // ignore: cast_nullable_to_non_nullable
                    as String,
        biometricEnabled:
            null == biometricEnabled
                ? _value.biometricEnabled
                : biometricEnabled // ignore: cast_nullable_to_non_nullable
                    as bool,
        orderFillNotifications:
            null == orderFillNotifications
                ? _value.orderFillNotifications
                : orderFillNotifications // ignore: cast_nullable_to_non_nullable
                    as bool,
        fundTransferNotifications:
            null == fundTransferNotifications
                ? _value.fundTransferNotifications
                : fundTransferNotifications // ignore: cast_nullable_to_non_nullable
                    as bool,
        priceAlertNotifications:
            null == priceAlertNotifications
                ? _value.priceAlertNotifications
                : priceAlertNotifications // ignore: cast_nullable_to_non_nullable
                    as bool,
        defaultCurrency:
            null == defaultCurrency
                ? _value.defaultCurrency
                : defaultCurrency // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPreferencesImpl implements _UserPreferences {
  const _$UserPreferencesImpl({
    this.colorScheme = TradingColorScheme.greenUp,
    this.language = 'zh',
    this.biometricEnabled = true,
    this.orderFillNotifications = true,
    this.fundTransferNotifications = true,
    this.priceAlertNotifications = true,
    this.defaultCurrency = 'USD',
  });

  factory _$UserPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPreferencesImplFromJson(json);

  @override
  @JsonKey()
  final TradingColorScheme colorScheme;
  @override
  @JsonKey()
  final String language;
  // 'zh' or 'en'
  @override
  @JsonKey()
  final bool biometricEnabled;
  @override
  @JsonKey()
  final bool orderFillNotifications;
  @override
  @JsonKey()
  final bool fundTransferNotifications;
  @override
  @JsonKey()
  final bool priceAlertNotifications;
  @override
  @JsonKey()
  final String defaultCurrency;

  @override
  String toString() {
    return 'UserPreferences(colorScheme: $colorScheme, language: $language, biometricEnabled: $biometricEnabled, orderFillNotifications: $orderFillNotifications, fundTransferNotifications: $fundTransferNotifications, priceAlertNotifications: $priceAlertNotifications, defaultCurrency: $defaultCurrency)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPreferencesImpl &&
            (identical(other.colorScheme, colorScheme) ||
                other.colorScheme == colorScheme) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.biometricEnabled, biometricEnabled) ||
                other.biometricEnabled == biometricEnabled) &&
            (identical(other.orderFillNotifications, orderFillNotifications) ||
                other.orderFillNotifications == orderFillNotifications) &&
            (identical(
                  other.fundTransferNotifications,
                  fundTransferNotifications,
                ) ||
                other.fundTransferNotifications == fundTransferNotifications) &&
            (identical(
                  other.priceAlertNotifications,
                  priceAlertNotifications,
                ) ||
                other.priceAlertNotifications == priceAlertNotifications) &&
            (identical(other.defaultCurrency, defaultCurrency) ||
                other.defaultCurrency == defaultCurrency));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    colorScheme,
    language,
    biometricEnabled,
    orderFillNotifications,
    fundTransferNotifications,
    priceAlertNotifications,
    defaultCurrency,
  );

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      __$$UserPreferencesImplCopyWithImpl<_$UserPreferencesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPreferencesImplToJson(this);
  }
}

abstract class _UserPreferences implements UserPreferences {
  const factory _UserPreferences({
    final TradingColorScheme colorScheme,
    final String language,
    final bool biometricEnabled,
    final bool orderFillNotifications,
    final bool fundTransferNotifications,
    final bool priceAlertNotifications,
    final String defaultCurrency,
  }) = _$UserPreferencesImpl;

  factory _UserPreferences.fromJson(Map<String, dynamic> json) =
      _$UserPreferencesImpl.fromJson;

  @override
  TradingColorScheme get colorScheme;
  @override
  String get language; // 'zh' or 'en'
  @override
  bool get biometricEnabled;
  @override
  bool get orderFillNotifications;
  @override
  bool get fundTransferNotifications;
  @override
  bool get priceAlertNotifications;
  @override
  String get defaultCurrency;

  /// Create a copy of UserPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
