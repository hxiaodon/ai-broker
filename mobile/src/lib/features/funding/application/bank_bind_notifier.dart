import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import 'bank_accounts_notifier.dart';

part 'bank_bind_notifier.freezed.dart';
part 'bank_bind_notifier.g.dart';

@freezed
sealed class BankBindState with _$BankBindState {
  const factory BankBindState.idle() = _Idle;
  const factory BankBindState.submitting() = _Submitting;
  /// Binding submitted — awaiting micro-deposits from the bank (1-3 business days).
  const factory BankBindState.pendingMicroDeposit({
    required String bankAccountId,
    /// ISO 8601 UTC — displayed as "激活时间" in the UI
    required DateTime cooldownEndsAt,
  }) = _PendingMicroDeposit;
  const factory BankBindState.error({required String message}) = _Error;
}

@riverpod
class BankBindNotifier extends _$BankBindNotifier {
  String? _pendingIdempotencyKey;

  @override
  BankBindState build() => const BankBindState.idle();

  Future<void> submit({
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String bankName,
  }) async {
    final keepAlive = ref.keepAlive();
    state = const BankBindState.submitting();

    _pendingIdempotencyKey ??= const Uuid().v4();
    final idempotencyKey = _pendingIdempotencyKey!;

    try {
      final account =
          await ref.read(bankAccountsProvider.notifier).addBankAccount(
                accountName: accountName,
                accountNumber: accountNumber,
                routingNumber: routingNumber,
                bankName: bankName,
                idempotencyKey: idempotencyKey,
              );

      _pendingIdempotencyKey = null;

      // cooldownEndsAt from server; fallback to 3 days if missing
      final cooldownEndsAt = account.cooldownEndsAt ??
          DateTime.now().toUtc().add(const Duration(days: 3));

      state = BankBindState.pendingMicroDeposit(
        bankAccountId: account.id,
        cooldownEndsAt: cooldownEndsAt,
      );
    } on Object catch (e) {
      AppLogger.warning('Bank bind failed: $e');
      state = BankBindState.error(message: e.toString());
    } finally {
      keepAlive.close();
    }
  }

  void reset() {
    _pendingIdempotencyKey = null;
    state = const BankBindState.idle();
  }
}
