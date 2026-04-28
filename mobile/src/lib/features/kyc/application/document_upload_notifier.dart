import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/local_auth_service.dart';
import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/entities/document_upload.dart';
import 'kyc_session_notifier.dart';

part 'document_upload_notifier.freezed.dart';
part 'document_upload_notifier.g.dart';

@freezed
sealed class DocumentUploadState with _$DocumentUploadState {
  const factory DocumentUploadState.idle() = _Idle;
  const factory DocumentUploadState.sumsubLaunched() = _SumsubLaunched;
  const factory DocumentUploadState.uploading({required int progressPct}) =
      _Uploading;
  const factory DocumentUploadState.success(
      {required DocumentUpload document}) = _Success;
  const factory DocumentUploadState.error({required String message}) = _Error;
}

@riverpod
class DocumentUploadNotifier extends _$DocumentUploadNotifier {
  @override
  DocumentUploadState build() => const DocumentUploadState.idle();

  Future<({String accessToken, String applicantId})> initSumsubFlow(
      DocumentType documentType) async {
    final sessionId = ref.read(kycSessionProvider).maybeWhen(
          active: (session) => session.sessionId,
          orElse: () => null,
        );
    if (sessionId == null) throw StateError('No active KYC session');

    final authenticated =
        await ref.read(localAuthServiceProvider).authenticate(
              localizedReason: '请验证身份以上传证件',
            );
    if (!authenticated) {
      state = const DocumentUploadState.error(message: '生物识别验证失败');
      throw Exception('biometric_failed');
    }

    final token =
        await ref.read(kycRepositoryProvider).getSumsubToken(sessionId);
    state = const DocumentUploadState.sumsubLaunched();
    return (accessToken: token.accessToken, applicantId: token.applicantId);
  }

  /// Called after the Sumsub SDK reports a successful verification.
  ///
  /// The Sumsub backend notifies AMS via Webhook (applicantReviewed) —
  /// the client does NOT call confirmDocumentUpload for Sumsub-managed uploads.
  /// We only advance the step and record the local success state.
  Future<void> onSumsubSuccess({
    required String applicantId,
    required DocumentType documentType,
  }) async {
    state = const DocumentUploadState.uploading(progressPct: 90);
    // Synthetic document record for local UI state (server state comes via Webhook).
    final doc = DocumentUpload(
      documentId: 'sumsub-$applicantId',
      type: documentType,
      status: DocumentUploadStatus.pendingVerification,
      sumsubApplicantId: applicantId,
    );
    ref.read(kycSessionProvider.notifier).advanceStep();
    state = DocumentUploadState.success(document: doc);
  }

  void reset() => state = const DocumentUploadState.idle();
}
