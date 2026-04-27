import 'package:decimal/decimal.dart';

import '../entities/account_balance.dart';
import '../entities/bank_account.dart';
import '../entities/fund_transfer.dart';

abstract interface class FundingRepository {
  Future<AccountBalance> getBalance();

  Future<FundTransfer> initiateDeposit({
    required Decimal amount,
    required String bankAccountId,
    required BankChannel channel,
    required String idempotencyKey,
  });

  Future<FundTransfer> initiateWithdrawal({
    required Decimal amount,
    required String bankAccountId,
    required BankChannel channel,
    required String idempotencyKey,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  });

  Future<List<FundTransfer>> getTransferHistory({
    int page = 1,
    int pageSize = 20,
  });

  Future<List<BankAccount>> getBankAccounts();

  Future<BankAccount> addBankAccount({
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String bankName,
    required String idempotencyKey,
  });

  Future<void> removeBankAccount(String bankAccountId);

  Future<BankAccount> verifyMicroDeposit({
    required String bankAccountId,
    required Decimal amount1,
    required Decimal amount2,
  });
}
