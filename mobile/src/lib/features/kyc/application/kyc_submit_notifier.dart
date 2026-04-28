import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import 'kyc_error_messages.dart';
import 'kyc_session_notifier.dart';

part 'kyc_submit_notifier.freezed.dart';
part 'kyc_submit_notifier.g.dart';

@freezed
sealed class KycSubmitState with _$KycSubmitState {
  const factory KycSubmitState.idle() = _Idle;
  const factory KycSubmitState.submitting() = _Submitting;
  const factory KycSubmitState.submitted() = _Submitted;
  const factory KycSubmitState.error({required String message}) = _Error;
}

@riverpod
class KycSubmitNotifier extends _$KycSubmitNotifier {
  String? _pendingIdempotencyKey;

  @override
  KycSubmitState build() => const KycSubmitState.idle();

  Future<void> submit() async {
    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    state = const KycSubmitState.submitting();
    try {
      final session = await ref.read(kycRepositoryProvider).submitKyc(
            sessionId: sessionId,
            idempotencyKey: idempotencyKey,
          );
      _pendingIdempotencyKey = null;
      await ref.read(kycSessionProvider.notifier).setSession(session);
      ref.read(kycSessionProvider.notifier).startPollingAfterSubmit(sessionId);
      state = const KycSubmitState.submitted();
    } on Object catch (e) {
      AppLogger.warning('KYC final submit failed: $e');
      state = KycSubmitState.error(message: kycUserMessage(e));
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const KycSubmitState.idle();
  }
}
