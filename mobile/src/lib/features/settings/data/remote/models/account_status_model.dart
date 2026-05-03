import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/account_status.dart';

part 'account_status_model.freezed.dart';
part 'account_status_model.g.dart';

@freezed
abstract class AccountStatusModel with _$AccountStatusModel {
  const factory AccountStatusModel({
    @JsonKey(name: 'kyc_status') required String kycStatus,
    @JsonKey(name: 'aml_status') required String amlStatus,
    @JsonKey(name: 'w8ben_status') required String w8BenStatus,
    @JsonKey(name: 'w8ben_expires_at') String? w8BenExpiresAt,
    @JsonKey(name: 'withholding_tax_rate')
    @Default('30%')
    String withholdingTaxRate,
    @JsonKey(name: 'trading_enabled') @Default(true) bool tradingEnabled,
    @JsonKey(name: 'withdrawal_enabled') @Default(true) bool withdrawalEnabled,
    @JsonKey(name: 'deposit_enabled') @Default(true) bool depositEnabled,
    @JsonKey(name: 'is_locked') @Default(false) bool isLocked,
  }) = _AccountStatusModel;

  factory AccountStatusModel.fromJson(Map<String, dynamic> json) =>
      _$AccountStatusModelFromJson(json);

  const AccountStatusModel._();

  AccountStatus toDomain() => AccountStatus(
        kycStatus: _parseKyc(kycStatus),
        amlStatus: _parseAml(amlStatus),
        w8BenStatus: _parseW8Ben(w8BenStatus),
        w8BenExpiresAt: w8BenExpiresAt != null
            ? DateTime.parse(w8BenExpiresAt!).toUtc()
            : null,
        withholdingTaxRate: withholdingTaxRate,
        tradingEnabled: tradingEnabled,
        withdrawalEnabled: withdrawalEnabled,
        depositEnabled: depositEnabled,
        isLocked: isLocked,
      );

  static KycStatus _parseKyc(String raw) => switch (raw.toUpperCase()) {
        'APPROVED' => KycStatus.approved,
        'REJECTED' => KycStatus.rejected,
        'SUSPENDED' => KycStatus.suspended,
        _ => KycStatus.pending,
      };

  static AmlStatus _parseAml(String raw) => switch (raw.toUpperCase()) {
        'REVIEW' => AmlStatus.review,
        'FLAGGED' => AmlStatus.flagged,
        _ => AmlStatus.clear,
      };

  static W8BenStatus _parseW8Ben(String raw) => switch (raw.toUpperCase()) {
        'VALID' => W8BenStatus.valid,
        'EXPIRING_SOON' => W8BenStatus.expiringSoon,
        'EXPIRED' => W8BenStatus.expired,
        _ => W8BenStatus.notSigned,
      };
}
