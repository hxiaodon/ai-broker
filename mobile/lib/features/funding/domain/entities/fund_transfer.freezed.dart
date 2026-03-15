// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FundTransfer _$FundTransferFromJson(Map<String, dynamic> json) {
  return _FundTransfer.fromJson(json);
}

/// @nodoc
mixin _$FundTransfer {
  String get transferId => throw _privateConstructorUsedError;
  FundTransferType get type => throw _privateConstructorUsedError;
  FundTransferStatus get status => throw _privateConstructorUsedError;
  String get amount =>
      throw _privateConstructorUsedError; // Decimal string e.g. "1000.00"
  String get currency => throw _privateConstructorUsedError; // 'USD' or 'HKD'
  String get bankAccountId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError; // UTC
  DateTime? get completedAt => throw _privateConstructorUsedError; // UTC
  String? get idempotencyKey => throw _privateConstructorUsedError; // UUID v4
  String? get failureReason => throw _privateConstructorUsedError;
  String? get referenceNumber => throw _privateConstructorUsedError;

  /// Serializes this FundTransfer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FundTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FundTransferCopyWith<FundTransfer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FundTransferCopyWith<$Res> {
  factory $FundTransferCopyWith(
    FundTransfer value,
    $Res Function(FundTransfer) then,
  ) = _$FundTransferCopyWithImpl<$Res, FundTransfer>;
  @useResult
  $Res call({
    String transferId,
    FundTransferType type,
    FundTransferStatus status,
    String amount,
    String currency,
    String bankAccountId,
    DateTime createdAt,
    DateTime? completedAt,
    String? idempotencyKey,
    String? failureReason,
    String? referenceNumber,
  });
}

/// @nodoc
class _$FundTransferCopyWithImpl<$Res, $Val extends FundTransfer>
    implements $FundTransferCopyWith<$Res> {
  _$FundTransferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FundTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transferId = null,
    Object? type = null,
    Object? status = null,
    Object? amount = null,
    Object? currency = null,
    Object? bankAccountId = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? idempotencyKey = freezed,
    Object? failureReason = freezed,
    Object? referenceNumber = freezed,
  }) {
    return _then(
      _value.copyWith(
            transferId:
                null == transferId
                    ? _value.transferId
                    : transferId // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as FundTransferType,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as FundTransferStatus,
            amount:
                null == amount
                    ? _value.amount
                    : amount // ignore: cast_nullable_to_non_nullable
                        as String,
            currency:
                null == currency
                    ? _value.currency
                    : currency // ignore: cast_nullable_to_non_nullable
                        as String,
            bankAccountId:
                null == bankAccountId
                    ? _value.bankAccountId
                    : bankAccountId // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            completedAt:
                freezed == completedAt
                    ? _value.completedAt
                    : completedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            idempotencyKey:
                freezed == idempotencyKey
                    ? _value.idempotencyKey
                    : idempotencyKey // ignore: cast_nullable_to_non_nullable
                        as String?,
            failureReason:
                freezed == failureReason
                    ? _value.failureReason
                    : failureReason // ignore: cast_nullable_to_non_nullable
                        as String?,
            referenceNumber:
                freezed == referenceNumber
                    ? _value.referenceNumber
                    : referenceNumber // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FundTransferImplCopyWith<$Res>
    implements $FundTransferCopyWith<$Res> {
  factory _$$FundTransferImplCopyWith(
    _$FundTransferImpl value,
    $Res Function(_$FundTransferImpl) then,
  ) = __$$FundTransferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String transferId,
    FundTransferType type,
    FundTransferStatus status,
    String amount,
    String currency,
    String bankAccountId,
    DateTime createdAt,
    DateTime? completedAt,
    String? idempotencyKey,
    String? failureReason,
    String? referenceNumber,
  });
}

/// @nodoc
class __$$FundTransferImplCopyWithImpl<$Res>
    extends _$FundTransferCopyWithImpl<$Res, _$FundTransferImpl>
    implements _$$FundTransferImplCopyWith<$Res> {
  __$$FundTransferImplCopyWithImpl(
    _$FundTransferImpl _value,
    $Res Function(_$FundTransferImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FundTransfer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transferId = null,
    Object? type = null,
    Object? status = null,
    Object? amount = null,
    Object? currency = null,
    Object? bankAccountId = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? idempotencyKey = freezed,
    Object? failureReason = freezed,
    Object? referenceNumber = freezed,
  }) {
    return _then(
      _$FundTransferImpl(
        transferId:
            null == transferId
                ? _value.transferId
                : transferId // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as FundTransferType,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as FundTransferStatus,
        amount:
            null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                    as String,
        currency:
            null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                    as String,
        bankAccountId:
            null == bankAccountId
                ? _value.bankAccountId
                : bankAccountId // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        completedAt:
            freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        idempotencyKey:
            freezed == idempotencyKey
                ? _value.idempotencyKey
                : idempotencyKey // ignore: cast_nullable_to_non_nullable
                    as String?,
        failureReason:
            freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                    as String?,
        referenceNumber:
            freezed == referenceNumber
                ? _value.referenceNumber
                : referenceNumber // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FundTransferImpl implements _FundTransfer {
  const _$FundTransferImpl({
    required this.transferId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.bankAccountId,
    required this.createdAt,
    this.completedAt,
    this.idempotencyKey,
    this.failureReason,
    this.referenceNumber,
  });

  factory _$FundTransferImpl.fromJson(Map<String, dynamic> json) =>
      _$$FundTransferImplFromJson(json);

  @override
  final String transferId;
  @override
  final FundTransferType type;
  @override
  final FundTransferStatus status;
  @override
  final String amount;
  // Decimal string e.g. "1000.00"
  @override
  final String currency;
  // 'USD' or 'HKD'
  @override
  final String bankAccountId;
  @override
  final DateTime createdAt;
  // UTC
  @override
  final DateTime? completedAt;
  // UTC
  @override
  final String? idempotencyKey;
  // UUID v4
  @override
  final String? failureReason;
  @override
  final String? referenceNumber;

  @override
  String toString() {
    return 'FundTransfer(transferId: $transferId, type: $type, status: $status, amount: $amount, currency: $currency, bankAccountId: $bankAccountId, createdAt: $createdAt, completedAt: $completedAt, idempotencyKey: $idempotencyKey, failureReason: $failureReason, referenceNumber: $referenceNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FundTransferImpl &&
            (identical(other.transferId, transferId) ||
                other.transferId == transferId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.bankAccountId, bankAccountId) ||
                other.bankAccountId == bankAccountId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.idempotencyKey, idempotencyKey) ||
                other.idempotencyKey == idempotencyKey) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            (identical(other.referenceNumber, referenceNumber) ||
                other.referenceNumber == referenceNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    transferId,
    type,
    status,
    amount,
    currency,
    bankAccountId,
    createdAt,
    completedAt,
    idempotencyKey,
    failureReason,
    referenceNumber,
  );

  /// Create a copy of FundTransfer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FundTransferImplCopyWith<_$FundTransferImpl> get copyWith =>
      __$$FundTransferImplCopyWithImpl<_$FundTransferImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FundTransferImplToJson(this);
  }
}

abstract class _FundTransfer implements FundTransfer {
  const factory _FundTransfer({
    required final String transferId,
    required final FundTransferType type,
    required final FundTransferStatus status,
    required final String amount,
    required final String currency,
    required final String bankAccountId,
    required final DateTime createdAt,
    final DateTime? completedAt,
    final String? idempotencyKey,
    final String? failureReason,
    final String? referenceNumber,
  }) = _$FundTransferImpl;

  factory _FundTransfer.fromJson(Map<String, dynamic> json) =
      _$FundTransferImpl.fromJson;

  @override
  String get transferId;
  @override
  FundTransferType get type;
  @override
  FundTransferStatus get status;
  @override
  String get amount; // Decimal string e.g. "1000.00"
  @override
  String get currency; // 'USD' or 'HKD'
  @override
  String get bankAccountId;
  @override
  DateTime get createdAt; // UTC
  @override
  DateTime? get completedAt; // UTC
  @override
  String? get idempotencyKey; // UUID v4
  @override
  String? get failureReason;
  @override
  String? get referenceNumber;

  /// Create a copy of FundTransfer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FundTransferImplCopyWith<_$FundTransferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
