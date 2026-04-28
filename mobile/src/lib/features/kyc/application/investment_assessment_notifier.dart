import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/entities/investment_assessment.dart';
import 'kyc_error_messages.dart';
import 'kyc_session_notifier.dart';

part 'investment_assessment_notifier.freezed.dart';
part 'investment_assessment_notifier.g.dart';

@freezed
sealed class InvestmentAssessmentState with _$InvestmentAssessmentState {
  const factory InvestmentAssessmentState.idle() = _Idle;
  const factory InvestmentAssessmentState.submitting() = _Submitting;
  const factory InvestmentAssessmentState.success() = _Success;
  const factory InvestmentAssessmentState.error({required String message}) = _Error;
}

@riverpod
class InvestmentAssessmentNotifier extends _$InvestmentAssessmentNotifier {
  String? _pendingIdempotencyKey;

  @override
  InvestmentAssessmentState build() => const InvestmentAssessmentState.idle();

  Future<void> submit(InvestmentAssessment assessment) async {
    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    state = const InvestmentAssessmentState.submitting();
    try {
      await ref.read(kycRepositoryProvider).submitInvestmentAssessment(
            sessionId: sessionId,
            assessment: assessment,
            idempotencyKey: idempotencyKey,
          );
      _pendingIdempotencyKey = null;
      ref.read(kycSessionProvider.notifier).advanceStep();
      state = const InvestmentAssessmentState.success();
    } on Object catch (e) {
      AppLogger.warning('InvestmentAssessment submit failed: $e');
      state = InvestmentAssessmentState.error(message: kycUserMessage(e));
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const InvestmentAssessmentState.idle();
  }
}
