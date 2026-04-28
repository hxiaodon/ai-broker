import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import 'kyc_error_messages.dart';
import 'kyc_session_notifier.dart';

part 'agreement_notifier.freezed.dart';
part 'agreement_notifier.g.dart';

@freezed
sealed class AgreementState with _$AgreementState {
  const factory AgreementState.idle({
    @Default(false) bool riskDisclosureRead,
    @Default(false) bool agreementsRead,
  }) = _Idle;
  const factory AgreementState.submitting() = _Submitting;
  const factory AgreementState.success() = _Success;
  const factory AgreementState.error({required String message}) = _Error;
}

@riverpod
class AgreementNotifier extends _$AgreementNotifier {
  String? _pendingIdempotencyKey;

  @override
  AgreementState build() => const AgreementState.idle();

  void onRiskDisclosureRead() {
    final current = state;
    if (current is! _Idle) return;
    state = current.copyWith(riskDisclosureRead: true);
  }

  void onAgreementsRead() {
    final current = state;
    if (current is! _Idle) return;
    state = current.copyWith(agreementsRead: true);
  }

  Future<void> submit({
    required String signatureInput,
    required String expectedName,
  }) async {
    final current = state;
    if (current is! _Idle) return;

    if (!current.riskDisclosureRead || !current.agreementsRead) {
      state = const AgreementState.error(message: '请阅读全部披露文件及协议');
      return;
    }
    if (signatureInput.trim().toLowerCase() !=
        expectedName.trim().toLowerCase()) {
      state = const AgreementState.error(message: '签名与开户姓名不匹配，请检查');
      return;
    }

    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    state = const AgreementState.submitting();
    try {
      await ref.read(kycRepositoryProvider).acknowledgeAgreements(
            sessionId: sessionId,
            termsAgreed: true,
            riskDisclosureAcknowledged: true,
            agreedAt: DateTime.now().toUtc(),
            idempotencyKey: idempotencyKey,
          );
      _pendingIdempotencyKey = null;
      ref.read(kycSessionProvider.notifier).advanceStep();
      state = const AgreementState.success();
    } on Object catch (e) {
      AppLogger.warning('Agreement submit failed: $e');
      state = AgreementState.error(message: kycUserMessage(e));
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const AgreementState.idle();
  }
}
