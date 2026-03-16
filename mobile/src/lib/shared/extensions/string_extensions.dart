/// Extension methods on [String] for PII masking and display formatting.
///
/// Per security-compliance rules: PII must be masked in all UI displays
/// and log output. These utilities handle the masking at the display layer.
library;

extension StringPiiExtensions on String {
  /// Mask SSN: show only last 4 digits.
  /// Input: '123-45-6789' → '***-**-6789'
  String maskSsn() {
    if (length != 11) return '***-**-****';
    final last4 = substring(7);
    return '***-**-$last4';
  }

  /// Mask HKID: show first letter and last check digit.
  /// Input: 'A123456(3)' → 'A****(3)'
  String maskHkid() {
    final match = RegExp(r'^([A-Z]{1,2})\d+\(([0-9A])\)$').firstMatch(this);
    if (match == null) return '****';
    return '${match.group(1)}*****(${match.group(2)})';
  }

  /// Mask bank account: show only last 4 digits.
  /// Input: '1234567890' → '****7890'
  String maskBankAccount() {
    if (length <= 4) return '****';
    return '****${substring(length - 4)}';
  }

  /// Mask email: show first char, asterisks, last char of local part.
  /// Input: 'john.doe@example.com' → 'j***e@example.com'
  String maskEmail() {
    final atIndex = indexOf('@');
    if (atIndex <= 2) return this;
    final local = substring(0, atIndex);
    final domain = substring(atIndex);
    if (local.length <= 2) return '${local[0]}*$domain';
    return '${local[0]}${'*' * (local.length - 2)}${local[local.length - 1]}$domain';
  }

  /// Mask phone number: show only last 4 digits with country code.
  /// Input: '+12345678901' → '+1 ***-***-8901'
  String maskPhone() {
    final digits = replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '***-***-****';
    final last4 = digits.substring(digits.length - 4);
    return '***-***-$last4';
  }

  /// Truncate with ellipsis for display.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }

  /// Returns true if this string is a valid US stock symbol (1-5 uppercase letters).
  bool get isValidUsSymbol =>
      RegExp(r'^[A-Z]{1,5}$').hasMatch(this);

  /// Returns true if this string is a valid HK stock code (4-5 digit number).
  bool get isValidHkCode =>
      RegExp(r'^\d{4,5}$').hasMatch(this);

  /// Converts empty string to null.
  String? get nullIfEmpty => isEmpty ? null : this;
}
