import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/auth/local_auth_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/security/fund_withdrawal_bio_service.dart';
import '../../../core/security/session_key_service.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/funding_repository_impl.dart';
import '../domain/entities/fund_transfer.dart';
import 'account_balance_notifier.dart';
import 'fund_transfer_history_notifier.dart';

part 'withdraw_form_notifier.freezed.dart';
part 'withdraw_form_notifier.g.dart';

@freezed
sealed class WithdrawFormState with _$WithdrawFormState {
  const factory WithdrawFormState.idle() = _Idle;
  const factory WithdrawFormState.confirming({
    required Decimal amount,
    required String bankAccountId,
    required String channel,
  }) = _Confirming;
  const factory WithdrawFormState.awaitingBiometric() = _AwaitingBiometric;
  const factory WithdrawFormState.submitting() = _Submitting;
  const factory WithdrawFormState.success({required String transferId}) = _Success;
  const factory WithdrawFormState.error({required String message}) = _Error;
}

@riverpod
class WithdrawFormNotifier extends _$WithdrawFormNotifier {
  String? _pendingIdempotencyKey;

  @override
  WithdrawFormState build() => const WithdrawFormState.idle();

  void confirm({
    required Decimal amount,
    required String bankAccountId,
    required String channel,
  }) {
    state = WithdrawFormState.confirming(
      amount: amount,
      bankAccountId: bankAccountId,
      channel: channel,
    );
  }

  void backToIdle() {
    state = const WithdrawFormState.idle();
  }

  /// Runs the biometric challenge-response then submits the withdrawal.
  Future<void> authenticateAndSubmit() async {
    final confirming = state;
    if (confirming is! _Confirming) return;

    final keepAlive = ref.keepAlive();
    state = const WithdrawFormState.awaitingBiometric();

    String bioToken = '';
    String bioChallenge = '';
    String bioTimestamp = '';

    try {
      // Fetch challenge before prompting — 30s TTL starts now.
      bioChallenge =
          await ref.read(fundWithdrawalBioServiceProvider).fetchChallenge();

      final authenticated = await ref
          .read(localAuthServiceProvider)
          .authenticate(localizedReason: '确认出金 \$${confirming.amount}');
      if (!authenticated) {
        state = const WithdrawFormState.error(message: '生物识别验证失败，请重试');
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
      final actionHash = FundWithdrawalBioService.computeActionHash(
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
      AppLogger.warning('Withdrawal biometric failed: $e');
      state = const WithdrawFormState.error(message: '生物识别不可用，请重试');
      keepAlive.close();
      return;
    }

    state = const WithdrawFormState.submitting();
    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    try {
      final transfer =
          await ref.read(fundingRepositoryProvider).initiateWithdrawal(
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
      state = WithdrawFormState.success(transferId: transfer.transferId);
    } on Object catch (e) {
      AppLogger.warning('Withdrawal submit failed: $e');
      state = WithdrawFormState.error(message: e.toString());
    } finally {
      keepAlive.close();
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const WithdrawFormState.idle();
  }
}

BankChannel _parseChannel(String raw) => switch (raw.toUpperCase()) {
      'WIRE' => BankChannel.wire,
      _ => BankChannel.ach,
    };
