import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/network/authenticated_dio.dart';
import '../domain/entities/address_proof.dart';
import '../domain/entities/document_upload.dart';
import '../domain/entities/financial_profile.dart';
import '../domain/entities/investment_assessment.dart';
import '../domain/entities/kyc_session.dart';
import '../domain/entities/personal_info.dart';
import '../domain/entities/tax_form.dart';
import '../domain/repositories/kyc_repository.dart';
import 'remote/kyc_remote_data_source.dart';
import 'remote/models/kyc_models.dart';

part 'kyc_repository_impl.g.dart';

@Riverpod(keepAlive: true)
KycRemoteDataSource kycRemoteDataSource(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final baseUrl = EnvironmentConfig.instance.amsBaseUrl;
  final dio = createAuthenticatedDio(baseUrl: baseUrl, tokenService: tokenSvc);
  return KycRemoteDataSource(dio);
}

@Riverpod(keepAlive: true)
KycRepository kycRepository(Ref ref) {
  return KycRepositoryImpl(ref.read(kycRemoteDataSourceProvider));
}

class KycRepositoryImpl implements KycRepository {
  KycRepositoryImpl(this._dataSource);

  final KycRemoteDataSource _dataSource;

  @override
  Future<KycSession> startKyc(PersonalInfo info) async {
    final dob = info.dateOfBirth.toUtc();
    final model = await _dataSource.startKyc({
      'first_name': info.firstName,
      'last_name': info.lastName,
      'date_of_birth':
          '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}',
      'nationality': info.nationality,
      'jurisdiction': 'US',
      if (info.chineseName != null) 'chinese_name': info.chineseName,
      'employment_status': info.employmentStatus.toApi(),
      if (info.employerName != null) 'employer_name': info.employerName,
      'is_pep': info.isPep,
      'is_insider_of_broker': info.isInsiderOfBroker,
    });
    return _fromModel(model);
  }

  @override
  Future<KycSession?> resumeSession() => Future.value(null);

  @override
  Future<({String accessToken, String applicantId, int ttl})> getSumsubToken(
      String sessionId) async {
    final m = await _dataSource.getSumsubToken(sessionId);
    return (accessToken: m.accessToken, applicantId: m.applicantId, ttl: m.ttl);
  }

  @override
  Future<DocumentUpload> confirmDocumentUpload({
    required String sessionId,
    required DocumentType documentType,
    required String s3Key,
    required String fileHash,
    required int fileSize,
  }) async {
    final m = await _dataSource.confirmDocumentUpload(
      sessionId: sessionId,
      documentId: s3Key,   // server-assigned doc ID returned by getUploadUrl
      s3Key: s3Key,
      fileHash: fileHash,
      fileSize: fileSize,
    );
    return DocumentUpload(
      documentId: m.documentId,
      type: documentType,
      status: DocumentUploadStatus.fromApi(m.status),
      sumsubApplicantId: m.sumsubApplicantId,
    );
  }

  @override
  Future<({String uploadUrl, String documentId, int expirySeconds})>
      getUploadUrl({
    required String sessionId,
    required String documentType,
  }) async {
    final m = await _dataSource.getUploadUrl(
      sessionId: sessionId,
      documentType: documentType,
    );
    return (uploadUrl: m.uploadUrl, documentId: m.documentId, expirySeconds: m.expiry);
  }

  @override
  Future<void> submitAddressProof({
    required String sessionId,
    required AddressProof proof,
    required String idempotencyKey,
  }) async {
    await _dataSource.submitAddressProof(
      sessionId: sessionId,
      body: {
        'address_street': proof.street,
        'address_city': proof.city,
        'address_province': proof.province,
        'address_postal_code': proof.postalCode,
        'address_country': proof.country,
        'proof_document_type': proof.proofDocumentType.toApi(),
        if (proof.documentId != null) 'proof_document_id': proof.documentId,
      },
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<void> submitFinancialProfile({
    required String sessionId,
    required FinancialProfile profile,
    required String idempotencyKey,
  }) async {
    await _dataSource.submitFinancialProfile(
      sessionId: sessionId,
      body: {
        'annual_income_range': profile.annualIncomeRange.toApi(),
        'liquid_net_worth_range': profile.liquidNetWorthRange.toApi(),
        'total_net_worth_range': profile.totalNetWorthRange.toApi(),
        'funds_source': profile.fundsSources.map((s) => s.toApi()).toList(),
        'employment_status': profile.employmentStatus.toApi(),
        if (profile.employerName != null) 'employer_name': profile.employerName,
      },
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<void> submitInvestmentAssessment({
    required String sessionId,
    required InvestmentAssessment assessment,
    required String idempotencyKey,
  }) async {
    await _dataSource.submitInvestmentAssessment(
      sessionId: sessionId,
      body: {
        'investment_objective': assessment.investmentObjective.toApi(),
        'risk_tolerance': assessment.riskTolerance.toApi(),
        'time_horizon': assessment.timeHorizon.toApi(),
        'stock_experience_years': assessment.stockExperienceYears,
        'options_experience_years': assessment.optionsExperienceYears,
        'margin_experience_years': assessment.marginExperienceYears,
        'liquidity_need': assessment.liquidityNeed.toApi(),
      },
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<void> submitTaxForm({
    required String sessionId,
    required TaxForm form,
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> body = switch (form.type) {
      TaxFormType.w8ben => () {
          final w = form.w8ben!;
          final sd = w.signatureDate.toUtc();
          return <String, dynamic>{
            'form_type': 'W8BEN',
            'full_name': w.fullName,
            'country_of_tax_residence': w.countryOfTaxResidence,
            if (w.tin != null) 'tin': w.tin,
            'tin_not_available': w.tinNotAvailable,
            if (w.address != null) 'address': w.address,
            'signature_date':
                '${sd.year.toString().padLeft(4, '0')}-'
                '${sd.month.toString().padLeft(2, '0')}-'
                '${sd.day.toString().padLeft(2, '0')}',
          };
        }(),
      TaxFormType.w9 => () {
          final w = form.w9!;
          return <String, dynamic>{
            'form_type': 'W9',
            'full_name': w.fullName,
            'ssn': w.ssn,
            'address': w.address,
          };
        }(),
      TaxFormType.crs => {'form_type': 'CRS'},
    };
    await _dataSource.submitTaxForms(
      sessionId: sessionId,
      body: body,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<void> acknowledgeAgreements({
    required String sessionId,
    required bool termsAgreed,
    required bool riskDisclosureAcknowledged,
    required DateTime agreedAt,
    required String idempotencyKey,
  }) async {
    await _dataSource.acknowledgeAgreements(
      sessionId: sessionId,
      body: {
        'terms_of_service_agreed': termsAgreed,
        'risk_disclosure_acknowledged': riskDisclosureAcknowledged,
        'agreed_at': agreedAt.toUtc().toIso8601String(),
      },
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<KycSession> submitKyc({
    required String sessionId,
    required String idempotencyKey,
  }) async {
    final m = await _dataSource.submitKyc(
      sessionId: sessionId,
      idempotencyKey: idempotencyKey,
    );
    return _fromModel(m);
  }

  @override
  Future<KycSession> getKycStatus(String sessionId) async {
    final m = await _dataSource.getKycStatus(sessionId);
    return _fromModel(m);
  }

  KycSession _fromModel(KycSessionModel m) => KycSession(
        sessionId: m.kycSessionId,
        currentStep: m.currentStep,
        status: KycStatus.fromApi(m.kycStatus),
        expiresAt: m.expiresAt != null
            ? DateTime.parse(m.expiresAt!).toUtc()
            : DateTime.now().toUtc().add(const Duration(days: 60)),
        estimatedTimeMinutes: m.estimatedTimeMinutes,
        rejectionReason: m.reasonIfRejected,
        needsMoreInfoStep: m.needsMoreInfoStep,
      );
}
