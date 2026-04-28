import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/local_auth_service.dart';
import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../data/remote/kyc_remote_data_source.dart';
import '../domain/entities/address_proof.dart';
import 'kyc_error_messages.dart';
import 'kyc_session_notifier.dart';

part 'address_proof_notifier.freezed.dart';
part 'address_proof_notifier.g.dart';

@freezed
sealed class AddressProofState with _$AddressProofState {
  const factory AddressProofState.idle() = _Idle;
  const factory AddressProofState.uploading({required int progressPct}) =
      _Uploading;
  const factory AddressProofState.success() = _Success;
  const factory AddressProofState.error({required String message}) = _Error;
}

@riverpod
class AddressProofNotifier extends _$AddressProofNotifier {
  // Idempotency key persists for one submission attempt; reused on retry.
  String? _pendingIdempotencyKey;

  @override
  AddressProofState build() => const AddressProofState.idle();

  Future<void> submit({
    required AddressProof proof,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    final authenticated =
        await ref.read(localAuthServiceProvider).authenticate(
              localizedReason: '请验证身份以上传地址证明',
            );
    if (!authenticated) {
      state = const AddressProofState.error(message: '生物识别验证失败');
      return;
    }

    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    state = const AddressProofState.uploading(progressPct: 10);
    try {
      final repo = ref.read(kycRepositoryProvider);
      final upload = await repo.getUploadUrl(
        sessionId: sessionId,
        documentType: proof.proofDocumentType.toApi(),
      );

      state = const AddressProofState.uploading(progressPct: 40);
      final dataSource = ref.read(kycRemoteDataSourceProvider);
      final (:fileHash, :fileSize) = await dataSource.uploadToS3(
        uploadUrl: upload.uploadUrl,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

      state = const AddressProofState.uploading(progressPct: 80);
      final updatedProof = proof.copyWith(documentId: upload.documentId);
      await repo.submitAddressProof(
        sessionId: sessionId,
        proof: updatedProof,
        idempotencyKey: idempotencyKey,
      );

      _pendingIdempotencyKey = null;
      ref.read(kycSessionProvider.notifier).advanceStep();
      state = const AddressProofState.success();
    } on Object catch (e) {
      AppLogger.warning('AddressProof submit failed: $e');
      state = AddressProofState.error(message: kycUserMessage(e));
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const AddressProofState.idle();
  }
}
