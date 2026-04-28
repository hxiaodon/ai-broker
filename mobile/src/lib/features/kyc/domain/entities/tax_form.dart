import 'package:freezed_annotation/freezed_annotation.dart';

part 'tax_form.freezed.dart';

enum TaxFormType {
  w9,
  w8ben,
  crs;

  String toApi() => switch (this) {
        w9 => 'W9',
        w8ben => 'W8BEN',
        crs => 'CRS',
      };
}

@freezed
abstract class W8BenInfo with _$W8BenInfo {
  const factory W8BenInfo({
    required String fullName,
    required String countryOfTaxResidence,
    String? tin,
    @Default(false) bool tinNotAvailable,
    String? address,
    required DateTime signatureDate,
  }) = _W8BenInfo;
}

@freezed
abstract class W9Info with _$W9Info {
  /// Security model: SSN is transmitted over TLS 1.3 with certificate pinning.
  /// Server applies AES-256-GCM encryption at rest before database storage.
  /// SSN is masked in all client-side logs (AppLogger SSN redaction pattern).
  const factory W9Info({
    required String fullName,
    required String ssn,
    required String address,
  }) = _W9Info;
}

@freezed
abstract class TaxForm with _$TaxForm {
  const factory TaxForm({
    required TaxFormType type,
    W8BenInfo? w8ben,
    W9Info? w9,
  }) = _TaxForm;
}
