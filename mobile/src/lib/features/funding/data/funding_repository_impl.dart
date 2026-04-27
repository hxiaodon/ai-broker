import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/security/hmac_signer.dart';
import '../../../core/security/nonce_service.dart';
import '../../../core/security/session_key_service.dart';
import '../domain/entities/account_balance.dart';
import '../domain/entities/bank_account.dart';
import '../domain/entities/fund_transfer.dart';
import '../domain/repositories/funding_repository.dart';
import 'remote/funding_remote_data_source.dart';

part 'funding_repository_impl.g.dart';

class FundingRepositoryImpl implements FundingRepository {
  FundingRepositoryImpl({required FundingRemoteDataSource remote})
      : _remote = remote;

  final FundingRemoteDataSource _remote;

  @override
  Future<AccountBalance> getBalance() => _remote.getBalance();

  @override
  Future<FundTransfer> initiateDeposit({
    required Decimal amount,
    required String bankAccountId,
    required BankChannel channel,
    required String idempotencyKey,
  }) =>
      _remote.initiateDeposit(
        amount: amount,
        bankAccountId: bankAccountId,
        channel: channel.name.toUpperCase(),
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<FundTransfer> initiateWithdrawal({
    required Decimal amount,
    required String bankAccountId,
    required BankChannel channel,
    required String idempotencyKey,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) =>
      _remote.initiateWithdrawal(
        amount: amount,
        bankAccountId: bankAccountId,
        channel: channel.name.toUpperCase(),
        idempotencyKey: idempotencyKey,
        bioToken: bioToken,
        bioChallenge: bioChallenge,
        bioTimestamp: bioTimestamp,
      );

  @override
  Future<List<FundTransfer>> getTransferHistory({
    int page = 1,
    int pageSize = 20,
  }) =>
      _remote.getTransferHistory(page: page, pageSize: pageSize);

  @override
  Future<List<BankAccount>> getBankAccounts() => _remote.getBankAccounts();

  @override
  Future<BankAccount> addBankAccount({
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String bankName,
    required String idempotencyKey,
  }) =>
      _remote.addBankAccount(
        accountName: accountName,
        accountNumber: accountNumber,
        routingNumber: routingNumber,
        bankName: bankName,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<void> removeBankAccount(String bankAccountId) =>
      _remote.removeBankAccount(bankAccountId);

  @override
  Future<BankAccount> verifyMicroDeposit({
    required String bankAccountId,
    required Decimal amount1,
    required Decimal amount2,
  }) =>
      _remote.verifyMicroDeposit(
        bankAccountId: bankAccountId,
        amount1: amount1,
        amount2: amount2,
      );
}

@Riverpod(keepAlive: true)
FundingRepository fundingRepository(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final baseUrl = EnvironmentConfig.instance.fundingBaseUrl;
  final dio = createAuthenticatedDio(baseUrl: baseUrl, tokenService: tokenSvc);
  return FundingRepositoryImpl(
    remote: FundingRemoteDataSource(
      dio: dio,
      connectivity: ref.watch(connectivityServiceProvider),
      signer: const HmacSigner(),
      sessionKeyService: ref.read(sessionKeyServiceProvider),
      nonceService: ref.read(nonceServiceProvider),
      deviceInfoService: ref.read(deviceInfoServiceProvider),
    ),
  );
}
