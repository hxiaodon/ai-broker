import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_upload.freezed.dart';

enum DocumentType {
  chinaResidentId,
  hkid,
  passport,
  mainlandPermit;

  String toApi() => switch (this) {
        chinaResidentId => 'CHINA_RESIDENT_ID',
        hkid => 'HKID',
        passport => 'INTL_PASSPORT',
        mainlandPermit => 'MAINLAND_PERMIT',
      };

  bool get requiresBackImage =>
      this == chinaResidentId || this == mainlandPermit;
}

enum DocumentUploadStatus {
  idle,
  uploading,
  pendingVerification,
  verified,
  failed;

  static DocumentUploadStatus fromApi(String v) => switch (v) {
        'UPLOADING' => uploading,
        'PENDING_VERIFICATION' => pendingVerification,
        'VERIFIED' => verified,
        'FAILED' => failed,
        _ => idle,
      };
}

@freezed
abstract class DocumentUpload with _$DocumentUpload {
  const factory DocumentUpload({
    required String documentId,
    required DocumentType type,
    required DocumentUploadStatus status,
    String? sumsubApplicantId,
    String? frontImagePath,
    String? backImagePath,
  }) = _DocumentUpload;
}
