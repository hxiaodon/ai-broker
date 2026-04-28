import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/kyc_repository_impl.dart';
import '../domain/entities/financial_profile.dart';
import 'kyc_error_messages.dart';
import 'kyc_session_notifier.dart';

part 'financial_profile_notifier.freezed.dart';
part 'financial_profile_notifier.g.dart';

@freezed
sealed class FinancialProfileState with _$FinancialProfileState {
  const factory FinancialProfileState.idle() = _Idle;
  const factory FinancialProfileState.submitting() = _Submitting;
  const factory FinancialProfileState.success() = _Success;
  const factory FinancialProfileState.error({required String message}) = _Error;
}

@riverpod
class FinancialProfileNotifier extends _$FinancialProfileNotifier {
  String? _pendingIdempotencyKey;

  @override
  FinancialProfileState build() => const FinancialProfileState.idle();

  Future<void> submit(FinancialProfile profile) async {
    if (!profile.isLiquidNetWorthValid) {
      state = const FinancialProfileState.error(message: '流动净资产不可超过总净资产');
      return;
    }
    if (profile.fundsSources.isEmpty) {
      state = const FinancialProfileState.error(message: '请至少选择一项资金来源');
      return;
    }

    final sessionId = ref.read(kycSessionProvider).maybeWhen(
      active: (session) => session.sessionId,
      orElse: () => null,
    );
    if (sessionId == null) return;

    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    state = const FinancialProfileState.submitting();
    try {
      await ref.read(kycRepositoryProvider).submitFinancialProfile(
            sessionId: sessionId,
            profile: profile,
            idempotencyKey: idempotencyKey,
          );
      _pendingIdempotencyKey = null;
      ref.read(kycSessionProvider.notifier).advanceStep();
      state = const FinancialProfileState.success();
    } on Object catch (e) {
      AppLogger.warning('FinancialProfile submit failed: $e');
      state = FinancialProfileState.error(message: kycUserMessage(e));
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const FinancialProfileState.idle();
  }
}
