import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/funding_repository_impl.dart';
import '../domain/entities/bank_account.dart';

part 'bank_accounts_notifier.g.dart';

/// Manages the list of the user's linked bank accounts.
///
/// Supports:
/// - build(): fetch list from server on init
/// - addBankAccount(): optimistic local insert after server confirms
/// - removeBankAccount(): optimistic local remove, rollback on error
/// - verifyMicroDeposit(): update matching account with server-returned state
@riverpod
class BankAccountsNotifier extends _$BankAccountsNotifier {
  @override
  Future<List<BankAccount>> build() =>
      ref.watch(fundingRepositoryProvider).getBankAccounts();

  Future<BankAccount> addBankAccount({
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String bankName,
    required String idempotencyKey,
  }) async {
    final prev = state;
    try {
      final newAccount = await ref.read(fundingRepositoryProvider).addBankAccount(
            accountName: accountName,
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            bankName: bankName,
            idempotencyKey: idempotencyKey,
          );
      state = AsyncData([...?prev.value, newAccount]);
      return newAccount;
    } on Object catch (e) {
      AppLogger.warning('addBankAccount failed: $e');
      state = prev;
      rethrow;
    }
  }

  Future<void> removeBankAccount(String bankAccountId) async {
    final prev = state;
    // Optimistic remove
    state = AsyncData(
      prev.value?.where((a) => a.id != bankAccountId).toList() ?? [],
    );
    try {
      await ref.read(fundingRepositoryProvider).removeBankAccount(bankAccountId);
    } on Object catch (e) {
      AppLogger.warning('removeBankAccount failed: $e');
      state = prev;
      rethrow;
    }
  }

  Future<void> verifyMicroDeposit({
    required String bankAccountId,
    required Decimal amount1,
    required Decimal amount2,
  }) async {
    final updated = await ref.read(fundingRepositoryProvider).verifyMicroDeposit(
          bankAccountId: bankAccountId,
          amount1: amount1,
          amount2: amount2,
        );
    // Replace the matching account in the list
    state = AsyncData(
      state.value?.map((a) => a.id == bankAccountId ? updated : a).toList() ?? [updated],
    );
  }
}
