import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/auth/device_info_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/security/hmac_signer.dart';
import '../../../../core/security/nonce_service.dart';
import '../../../../core/security/session_key_service.dart';
import '../../domain/entities/account_balance.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/entities/fund_transfer.dart';
import 'funding_mappers.dart';
import 'models/account_balance_model.dart';
import 'models/bank_account_model.dart';
import 'models/fund_transfer_model.dart';

/// Dio-based implementation of all Fund Transfer REST endpoints.
///
/// Endpoints called:
///   GET  /api/v1/balance
///   POST /api/v1/deposit
///   POST /api/v1/withdrawal
///   GET  /api/v1/fund/history
///   GET  /api/v1/bank-accounts
///   POST /api/v1/bank-accounts
///   DELETE /api/v1/bank-accounts/:id
///   POST /api/v1/bank-accounts/:id/verify-micro-deposit
///
/// All state-changing endpoints require:
///   - HMAC-SHA256 request signature (session key + nonce)
///   - Idempotency-Key header (UUID v4, 72h TTL per compliance rules)
///
/// Withdrawal additionally requires biometric headers (X-Biometric-Token,
/// X-Bio-Challenge, X-Bio-Timestamp).
class FundingRemoteDataSource {
  FundingRemoteDataSource({
    required Dio dio,
    required ConnectivityService connectivity,
    required HmacSigner signer,
    required SessionKeyService sessionKeyService,
    required NonceService nonceService,
    required DeviceInfoService deviceInfoService,
  })  : _dio = dio,
        _connectivity = connectivity,
        _signer = signer,
        _sessionKeyService = sessionKeyService,
        _nonceService = nonceService,
        _deviceInfoService = deviceInfoService;

  final Dio _dio;
  final ConnectivityService _connectivity;
  final HmacSigner _signer;
  final SessionKeyService _sessionKeyService;
  final NonceService _nonceService;
  final DeviceInfoService _deviceInfoService;

  // ─── Balance ──────────────────────────────────────────────────────────────

  Future<AccountBalance> getBalance() async {
    await _checkConnectivity();
    const path = '/api/v1/balance';
    final sigHeaders = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: sigHeaders),
      );
      return AccountBalanceModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getBalance');
    }
  }

  // ─── Deposit ──────────────────────────────────────────────────────────────

  Future<FundTransfer> initiateDeposit({
    required Decimal amount,
    required String bankAccountId,
    required String channel,
    required String idempotencyKey,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) async {
    await _checkConnectivity();
    const path = '/api/v1/deposit';
    final body = {
      'amount': amount.toString(),
      'bank_account_id': bankAccountId,
      'channel': channel,
    };
    final bodyJson = jsonEncode(body);
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: bodyJson,
      idempotencyKey: idempotencyKey,
    );
    headers['X-Biometric-Token'] = bioToken;
    headers['X-Bio-Challenge'] = bioChallenge;
    headers['X-Bio-Timestamp'] = bioTimestamp;
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        path,
        data: bodyJson,
        options: Options(headers: headers),
      );
      AppLogger.info('initiateDeposit success: ${resp.data?['transfer_id']}');
      return FundTransferModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'initiateDeposit');
    }
  }

  // ─── Withdrawal ───────────────────────────────────────────────────────────

  Future<FundTransfer> initiateWithdrawal({
    required Decimal amount,
    required String bankAccountId,
    required String channel,
    required String idempotencyKey,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) async {
    await _checkConnectivity();
    const path = '/api/v1/withdrawal';
    final body = {
      'amount': amount.toString(),
      'bank_account_id': bankAccountId,
      'channel': channel,
    };
    final bodyJson = jsonEncode(body);
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: bodyJson,
      idempotencyKey: idempotencyKey,
    );
    headers['X-Biometric-Token'] = bioToken;
    headers['X-Bio-Challenge'] = bioChallenge;
    headers['X-Bio-Timestamp'] = bioTimestamp;

    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        path,
        data: bodyJson,
        options: Options(headers: headers),
      );
      AppLogger.info('initiateWithdrawal success: ${resp.data?['transfer_id']}');
      return FundTransferModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'initiateWithdrawal');
    }
  }

  // ─── Transfer History ─────────────────────────────────────────────────────

  Future<List<FundTransfer>> getTransferHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    await _checkConnectivity();
    const path = '/api/v1/fund/history';
    final sigHeaders = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'page_size': pageSize},
        options: Options(headers: sigHeaders),
      );
      final items = resp.data!['transfers'] as List<dynamic>? ?? [];
      return items
          .map((e) => FundTransferModel.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getTransferHistory');
    }
  }

  // ─── Bank Accounts ────────────────────────────────────────────────────────

  Future<List<BankAccount>> getBankAccounts() async {
    await _checkConnectivity();
    const path = '/api/v1/bank-accounts';
    final sigHeaders = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: sigHeaders),
      );
      final items = resp.data!['bank_accounts'] as List<dynamic>? ?? [];
      return items
          .map((e) => BankAccountModel.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getBankAccounts');
    }
  }

  Future<BankAccount> addBankAccount({
    required String accountName,
    required String accountNumber,
    required String routingNumber,
    required String bankName,
    required String idempotencyKey,
  }) async {
    await _checkConnectivity();
    const path = '/api/v1/bank-accounts';
    final body = {
      'account_name': accountName,
      'account_number': accountNumber,
      'routing_number': routingNumber,
      'bank_name': bankName,
    };
    final bodyJson = jsonEncode(body);
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: bodyJson,
      idempotencyKey: idempotencyKey,
    );
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        path,
        data: bodyJson,
        options: Options(headers: headers),
      );
      return BankAccountModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'addBankAccount');
    }
  }

  Future<void> removeBankAccount(String bankAccountId) async {
    await _checkConnectivity();
    final path = '/api/v1/bank-accounts/$bankAccountId';
    final headers = await _buildMutatingHeaders(
      method: 'DELETE',
      path: path,
      bodyJson: '',
      idempotencyKey: 'delete-$bankAccountId',
    );
    try {
      await _dio.delete<void>(path, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'removeBankAccount');
    }
  }

  Future<BankAccount> verifyMicroDeposit({
    required String bankAccountId,
    required Decimal amount1,
    required Decimal amount2,
  }) async {
    await _checkConnectivity();
    final path = '/api/v1/bank-accounts/$bankAccountId/verify-micro-deposit';
    final body = {
      'amount_1': amount1.toString(),
      'amount_2': amount2.toString(),
    };
    final bodyJson = jsonEncode(body);
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: bodyJson,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        path,
        data: bodyJson,
        options: Options(headers: headers),
      );
      return BankAccountModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'verifyMicroDeposit');
    }
  }

  // ─── Header builders ──────────────────────────────────────────────────────

  Future<Map<String, String>> _buildGetHeaders(String path) async {
    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();
    return _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: 'GET',
      path: path,
      nonce: nonce,
      deviceId: deviceId,
    );
  }

  Future<Map<String, String>> _buildMutatingHeaders({
    required String method,
    required String path,
    required String bodyJson,
    required String idempotencyKey,
  }) async {
    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();
    final sigHeaders = _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: method,
      path: path,
      nonce: nonce,
      deviceId: deviceId,
      body: bodyJson,
    );
    return {
      'Content-Type': 'application/json',
      ...sigHeaders,
      'Idempotency-Key': idempotencyKey,
    };
  }

  // ─── Error mapping ────────────────────────────────────────────────────────

  Future<void> _checkConnectivity() async {
    if (!await _connectivity.isConnected) {
      throw const NetworkException(message: 'No internet connection');
    }
  }

  AppException _mapDioError(DioException e, String op) {
    AppLogger.warning('$op failed: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: '$op timed out', cause: e);
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(message: 'Unauthorized', cause: e);
    }
    final body = e.response?.data;
    final msg = body is Map ? body['message'] as String? : null;
    final errorCode = body is Map ? body['error_code'] as String? : null;
    if (statusCode != null && statusCode >= 500) {
      return ServerException(statusCode: statusCode, message: msg ?? 'Server error');
    }
    if (statusCode == 409) {
      return BusinessException(
        errorCode: errorCode ?? 'IDEMPOTENT_REPLAY',
        message: msg ?? 'Duplicate request',
      );
    }
    if (statusCode == 422) {
      return ValidationException(message: msg ?? 'Validation failed');
    }
    if (statusCode != null && statusCode >= 400) {
      return BusinessException(
        errorCode: errorCode ?? 'CLIENT_ERROR',
        message: msg ?? 'Request failed',
      );
    }
    return NetworkException(message: '$op failed: ${e.message}', cause: e);
  }
}
