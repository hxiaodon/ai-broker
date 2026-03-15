import '../entities/kyc_application.dart';

/// Repository interface for KYC operations.
abstract class KycRepository {
  /// Get current user's KYC application state.
  Future<KycApplication?> getApplication();

  /// Submit personal info (step 1).
  Future<void> submitPersonalInfo(Map<String, dynamic> data);

  /// Upload KYC document (step 2). Returns upload URL or document ID.
  Future<String> uploadDocument({
    required String documentType,
    required List<int> imageBytes,
    required String fileName,
  });

  /// Submit the completed KYC application for review.
  Future<KycApplication> submitApplication(String applicationId);

  /// Get KYC status for the current user.
  Future<KycStatus> getKycStatus();
}
