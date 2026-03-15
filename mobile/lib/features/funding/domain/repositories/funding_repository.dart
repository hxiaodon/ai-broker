import '../entities/fund_transfer.dart';

/// Repository interface for fund transfer operations.
///
/// Per compliance: every operation requires an idempotency key (UUID v4).
abstract class FundingRepository {
  /// Initiate a deposit request.
  Future<FundTransfer> initiateDeposit({
    required String bankAccountId,
    required String amount,
    required String currency,
    required String idempotencyKey,
  });

  /// Initiate a withdrawal request.
  /// Only settled funds are withdrawable per Rule 4.
  Future<FundTransfer> initiateWithdrawal({
    required String bankAccountId,
    required String amount,
    required String currency,
    required String idempotencyKey,
  });

  /// Get transfer history.
  Future<List<FundTransfer>> getTransferHistory({int page = 1, int pageSize = 20});

  /// Get fund transfer by ID.
  Future<FundTransfer> getTransfer(String transferId);

  /// Get list of verified bank accounts.
  Future<List<Map<String, dynamic>>> getBankAccounts();

  /// Get available (settled) balance by currency.
  Future<Map<String, String>> getBalance(String currency);
}
