import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../../../../core/security/ssl_pinning_config.dart';
import 'models/kyc_models.dart';

class KycRemoteDataSource {
  KycRemoteDataSource(this._dio);

  final Dio _dio;

  Future<KycSessionModel> startKyc(Map<String, dynamic> body) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/v1/kyc/start',
      data: body,
    );
    return KycSessionModel.fromJson(resp.data!);
  }

  Future<SumsubTokenModel> getSumsubToken(String sessionId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/v1/kyc/sumsub-token',
      queryParameters: {'kyc_session_id': sessionId},
    );
    return SumsubTokenModel.fromJson(resp.data!);
  }

  Future<UploadUrlModel> getUploadUrl({
    required String sessionId,
    required String documentType,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/v1/kyc/upload-url',
      queryParameters: {
        'kyc_session_id': sessionId,
        'document_type': documentType,
      },
    );
    return UploadUrlModel.fromJson(resp.data!);
  }

  /// Uploads [fileBytes] to the S3 presigned [uploadUrl].
  ///
  /// Returns the SHA-256 hex hash and file size as a record so the caller can
  /// pass them directly to [confirmDocumentUpload] — eliminates the mutable
  /// instance-field race condition that existed when using `_lastUploadHash`.
  ///
  /// Uses a certificate-pinned HttpClient (same pinning config as the API Dio)
  /// to protect KYC identity documents and address proofs from MitM interception.
  Future<({String fileHash, int fileSize})> uploadToS3({
    required String uploadUrl,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final hashBytes = sha256.convert(fileBytes);
    final fileHash = 'sha256:${hashBytes.toString()}';
    final checksumB64 = base64.encode(hashBytes.bytes);

    // Use a pinned HttpClient for S3 uploads (certificate pinning via ssl_pinning_config).
    final s3Dio = Dio()
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: createPinnedHttpClient,
      );

    await s3Dio.put<void>(
      uploadUrl,
      data: Stream.fromIterable([fileBytes]),
      options: Options(
        headers: {
          'Content-Type': mimeType,
          'x-amz-checksum-sha256': checksumB64,
          'Content-Length': fileBytes.length,
        },
      ),
    );

    return (fileHash: fileHash, fileSize: fileBytes.length);
  }

  Future<DocumentUploadModel> confirmDocumentUpload({
    required String sessionId,
    required String documentId,
    required String s3Key,
    required String fileHash,
    required int fileSize,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/v1/kyc/documents/confirm-upload',
      data: {
        'kyc_session_id': sessionId,
        'document_id': documentId,
        's3_key': s3Key,
        'file_hash': fileHash,
        'file_size': fileSize,
      },
    );
    return DocumentUploadModel.fromJson(resp.data!);
  }

  Future<void> submitFinancialProfile({
    required String sessionId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await _dio.post<void>(
      '/v1/kyc/financial-profile',
      queryParameters: {'kyc_session_id': sessionId},
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  Future<void> submitAddressProof({
    required String sessionId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await _dio.post<void>(
      '/v1/kyc/address-proof',
      queryParameters: {'kyc_session_id': sessionId},
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  Future<void> submitInvestmentAssessment({
    required String sessionId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await _dio.post<void>(
      '/v1/kyc/investment-assessment',
      queryParameters: {'kyc_session_id': sessionId},
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  Future<void> submitTaxForms({
    required String sessionId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await _dio.post<void>(
      '/v1/kyc/tax-forms',
      queryParameters: {'kyc_session_id': sessionId},
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  Future<void> acknowledgeAgreements({
    required String sessionId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    await _dio.post<void>(
      '/v1/kyc/agreements',
      queryParameters: {'kyc_session_id': sessionId},
      data: body,
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
  }

  Future<KycSessionModel> submitKyc({
    required String sessionId,
    required String idempotencyKey,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/v1/kyc/submit',
      queryParameters: {'kyc_session_id': sessionId},
      data: {'review_checklist': {}},
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return KycSessionModel.fromJson(resp.data!);
  }

  Future<KycSessionModel> getKycStatus(String sessionId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/v1/kyc/status',
      queryParameters: {'kyc_session_id': sessionId},
    );
    return KycSessionModel.fromJson(resp.data!);
  }
}
