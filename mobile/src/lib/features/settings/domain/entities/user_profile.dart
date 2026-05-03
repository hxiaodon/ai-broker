import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

/// KYC tier level for the user's account.
enum KycTier {
  /// Submitted / under review; limited deposit quota
  tier1,

  /// Fully approved; all features unlocked
  tier2,
}

/// Employment status as declared during KYC.
enum EmploymentStatus { employed, selfEmployed, unemployed, retired, student }

/// User profile data returned by GET /v1/profile.
///
/// PII fields are returned decrypted by the server for authenticated clients.
/// UI layer applies secondary masking via the helper getters below.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String accountId,
    required String fullName,
    required String phone,
    required String email,
    required String idNumber,
    required String idType,
    required DateTime dateOfBirth,
    required String country,
    required String province,
    required String city,
    required String address,
    required EmploymentStatus employmentStatus,
    String? employer,
    String? industry,
    required KycTier kycTier,
    required DateTime accountOpenedAt,
    required String accountType,
  }) = _UserProfile;

  const UserProfile._();

  // ─── PII masking helpers ─────────────────────────────────────────────────

  /// e.g. "110101****0001" — middle digits hidden
  String get maskedIdNumber {
    if (idNumber.length <= 8) return idNumber;
    final prefix = idNumber.substring(0, 6);
    final suffix = idNumber.substring(idNumber.length - 4);
    return '$prefix****$suffix';
  }

  /// e.g. "+86 138****8888"
  String get maskedPhone {
    if (phone.length < 8) return phone;
    final parts = phone.split(' ');
    if (parts.length >= 2) {
      final number = parts.last;
      if (number.length <= 4) return phone;
      final prefix = number.substring(0, number.length - 8);
      final suffix = number.substring(number.length - 4);
      final cc = parts.sublist(0, parts.length - 1).join(' ');
      return '$cc ${prefix.isEmpty ? '' : prefix}****$suffix';
    }
    final prefix = phone.substring(0, phone.length - 8);
    final suffix = phone.substring(phone.length - 4);
    return '${prefix.isEmpty ? '' : prefix}****$suffix';
  }

  /// e.g. "zh***@gmail.com"
  String get maskedEmail {
    final atIdx = email.indexOf('@');
    if (atIdx <= 1) return email;
    final local = email.substring(0, atIdx);
    final domain = email.substring(atIdx);
    if (local.length <= 2) return email;
    return '${local[0]}***${local[local.length - 1]}$domain';
  }
}
