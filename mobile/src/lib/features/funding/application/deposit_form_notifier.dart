import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../data/funding_repository_impl.dart';
import '../domain/entities/fund_transfer.dart';
import 'account_balance_notifier.dart';
import 'fund_transfer_history_notifier.dart';

part 'deposit_form_notifier.freezed.dart';
part 'deposit_form_notifier.g.dart';

@freezed
sealed class DepositFormState with _$DepositFormState {
  const factory DepositFormState.idle() = _Idle;
  const factory DepositFormState.confirming({
    required Decimal amount,
    required String bankAccountId,
    required String channel,
  }) = _Confirming;
  const factory DepositFormState.submitting() = _Submitting;
  const factory DepositFormState.success({required String transferId}) = _Success;
  const factory DepositFormState.error({required String message}) = _Error;
}

@riverpod
class DepositFormNotifier extends _$DepositFormNotifier {
  // Idempotency key is generated once per submission and reused on retries.
  // Cleared only when submission reaches a terminal state (success/error reset).
  String? _pendingIdempotencyKey;

  @override
  DepositFormState build() => const DepositFormState.idle();

  void confirm({
    required Decimal amount,
    required String bankAccountId,
    required String channel,
  }) {
    state = DepositFormState.confirming(
      amount: amount,
      bankAccountId: bankAccountId,
      channel: channel,
    );
  }

  void backToIdle() {
    state = const DepositFormState.idle();
  }

  Future<void> submit() async {
    final confirming = state;
    if (confirming is! _Confirming) return;

    final keepAlive = ref.keepAlive();
    state = const DepositFormState.submitting();

    // Reuse key on retry; generate new key only for a fresh submission.
    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    try {
      final transfer = await ref.read(fundingRepositoryProvider).initiateDeposit(
            amount: confirming.amount,
            bankAccountId: confirming.bankAccountId,
            channel: _parseChannel(confirming.channel),
            idempotencyKey: idempotencyKey,
          );

      _pendingIdempotencyKey = null; // terminal: reached success
      ref.invalidate(accountBalanceProvider);
      ref.invalidate(fundTransferHistoryProvider);
      state = DepositFormState.success(transferId: transfer.transferId);
    } on Object catch (e) {
      AppLogger.warning('Deposit submit failed: $e');
      state = DepositFormState.error(message: e.toString());
    } finally {
      keepAlive.close();
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const DepositFormState.idle();
  }
}

BankChannel _parseChannel(String raw) => switch (raw.toUpperCase()) {
      'WIRE' => BankChannel.wire,
      _ => BankChannel.ach,
    };
