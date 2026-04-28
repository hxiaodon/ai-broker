import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/auth/local_auth_service.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/security/fund_withdrawal_bio_service.dart';
import '../../../core/security/session_key_service.dart';
import '../../auth/application/auth_notifier.dart';
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
  const factory DepositFormState.awaitingBiometric() = _AwaitingBiometric;
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

  Future<void> authenticateAndSubmit() async {
    final confirming = state;
    if (confirming is! _Confirming) return;

    final keepAlive = ref.keepAlive();
    state = const DepositFormState.awaitingBiometric();

    // Clear key so idempotency key and bio-token are always from the same challenge.
    _pendingIdempotencyKey = null;

    String bioToken = '';
    String bioChallenge = '';
    String bioTimestamp = '';

    try {
      bioChallenge =
          await ref.read(fundWithdrawalBioServiceProvider).fetchChallenge();

      final authenticated = await ref
          .read(localAuthServiceProvider)
          .authenticate(localizedReason: '确认入金 \$${confirming.amount}');
      if (!authenticated) {
        state = const DepositFormState.error(message: '生物识别验证失败，请重试');
        keepAlive.close();
        return;
      }

      bioTimestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
      final sessionKey =
          await ref.read(sessionKeyServiceProvider).getSessionKey();
      final deviceId = await ref.read(deviceInfoServiceProvider).getDeviceId();
      final accountId = ref.read(authProvider).maybeWhen(
            authenticated: (id, _, _) => id,
            orElse: () => '',
          );
      final actionHash = FundWithdrawalBioService.computeDepositActionHash(
        amount: confirming.amount.toString(),
        bankAccountId: confirming.bankAccountId,
        accountId: accountId,
      );
      bioToken = ref.read(fundWithdrawalBioServiceProvider).computeBioToken(
            sessionSecret: sessionKey.secret,
            challenge: bioChallenge,
            timestamp: bioTimestamp,
            deviceId: deviceId,
            actionHash: actionHash,
          );
    } on Object catch (e) {
      AppLogger.warning('Deposit biometric failed: $e');
      state = const DepositFormState.error(message: '生物识别不可用，请重试');
      keepAlive.close();
      return;
    }

    state = const DepositFormState.submitting();
    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    try {
      final transfer = await ref.read(fundingRepositoryProvider).initiateDeposit(
            amount: confirming.amount,
            bankAccountId: confirming.bankAccountId,
            channel: _parseChannel(confirming.channel),
            idempotencyKey: idempotencyKey,
            bioToken: bioToken,
            bioChallenge: bioChallenge,
            bioTimestamp: bioTimestamp,
          );

      _pendingIdempotencyKey = null;
      ref.invalidate(accountBalanceProvider);
      ref.invalidate(fundTransferHistoryProvider);
      state = DepositFormState.success(transferId: transfer.transferId);
    } on Object catch (e) {
      AppLogger.warning('Deposit submit failed: $e');
      final msg = e is BusinessException ? e.message : '入金失败，请稍后重试';
      state = DepositFormState.error(message: msg);
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
