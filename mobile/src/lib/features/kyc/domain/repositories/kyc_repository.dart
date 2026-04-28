import '../entities/kyc_session.dart';
import '../entities/personal_info.dart';
import '../entities/document_upload.dart';
import '../entities/address_proof.dart';
import '../entities/financial_profile.dart';
import '../entities/investment_assessment.dart';
import '../entities/tax_form.dart';

abstract class KycRepository {
  /// Step 1 — 开始 KYC，提交个人信息
  Future<KycSession> startKyc(PersonalInfo info);

  /// 从 SecureStorage 恢复已有 session（断点续传）
  Future<KycSession?> resumeSession();

  /// 获取 Sumsub SDK access token（Step 2 证件上传前调用）
  Future<({String accessToken, String applicantId, int ttl})> getSumsubToken(
      String sessionId);

  /// Step 2 — 证件上传确认（Sumsub SDK 完成后调用）
  Future<DocumentUpload> confirmDocumentUpload({
    required String sessionId,
    required DocumentType documentType,
    required String s3Key,
    required String fileHash,
    required int fileSize,
  });

  /// Step 3 — 地址证明：获取 S3 预签名上传 URL
  Future<({String uploadUrl, String documentId, int expirySeconds})>
      getUploadUrl({
    required String sessionId,
    required String documentType,
  });

  /// Step 3 — 地址证明：确认上传并提交地址信息
  /// [idempotencyKey] 由调用方（notifier）生成，每次提交尝试创建一次，重试时复用。
  Future<void> submitAddressProof({
    required String sessionId,
    required AddressProof proof,
    required String idempotencyKey,
  });

  /// Step 4 — 提交财务状况
  Future<void> submitFinancialProfile({
    required String sessionId,
    required FinancialProfile profile,
    required String idempotencyKey,
  });

  /// Step 5 — 提交投资评估问卷
  Future<void> submitInvestmentAssessment({
    required String sessionId,
    required InvestmentAssessment assessment,
    required String idempotencyKey,
  });

  /// Step 6 — 提交税务表单（W-8BEN / W-9 / CRS）
  Future<void> submitTaxForm({
    required String sessionId,
    required TaxForm form,
    required String idempotencyKey,
  });

  /// Step 7+8 — 确认风险披露与协议
  Future<void> acknowledgeAgreements({
    required String sessionId,
    required bool termsAgreed,
    required bool riskDisclosureAcknowledged,
    required DateTime agreedAt,
    required String idempotencyKey,
  });

  /// 最终提交 KYC
  Future<KycSession> submitKyc({
    required String sessionId,
    required String idempotencyKey,
  });

  /// 轮询 KYC 状态（GET /v1/kyc/status）
  Future<KycSession> getKycStatus(String sessionId);
}
