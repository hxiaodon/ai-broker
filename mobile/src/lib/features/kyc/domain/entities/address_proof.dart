import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_proof.freezed.dart';

enum AddressProofDocType {
  bankStatement,
  utilityBill,
  governmentLetter;

  String toApi() => switch (this) {
        bankStatement => 'BANK_STATEMENT',
        utilityBill => 'UTILITY_BILL',
        governmentLetter => 'GOVERNMENT_LETTER',
      };
}

@freezed
abstract class AddressProof with _$AddressProof {
  const factory AddressProof({
    required String street,
    required String city,
    required String province,
    required String postalCode,
    required String country,
    required String proofDocumentPath,
    required AddressProofDocType proofDocumentType,
    String? documentId,
  }) = _AddressProof;
}
