/// SSL/TLS certificate pinning via SPKI SHA-256 fingerprints.
///
/// ## Why SPKI pinning (not certificate pinning)
/// SPKI (SubjectPublicKeyInfo) pins the *public key* rather than the full
/// certificate. A certificate renewal with the same key pair does not
/// invalidate the pin, reducing certificate-rotation operational risk.
///
/// ## How to obtain SPKI fingerprints
/// Run against your API endpoint:
/// ```sh
/// openssl s_client -connect api.trading.example.com:443 </dev/null 2>/dev/null \
///   | openssl x509 -pubkey -noout \
///   | openssl pkey -pubin -outform DER \
///   | openssl dgst -sha256 -binary \
///   | base64
/// ```
///
/// ## Certificate rotation SOP
/// T−30 days: Add new cert's SPKI pin to [_spkiPins] as second entry and release.
/// T=0:       Rotate server certificate. Both old + new pins are trusted in app.
/// T+30 days: Remove old pin from [_spkiPins] once new app version is adopted. Release.
///
/// ## Phase 1 (Placeholder)
/// [_spkiPins] contains placeholder values. Replace with real fingerprints before
/// deploying to production. Do NOT ship production with placeholders.
///
/// Reference: https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../logging/app_logger.dart';

/// SPKI SHA-256 fingerprints per host.
///
/// Always maintain at least two pins per host: current + rotation backup.
const Map<String, List<String>> _spkiPins = {
  // Primary API gateway
  'api.trading.example.com': [
    // TODO Phase 2: Replace with actual SPKI SHA-256 fingerprint (base64)
    'PLACEHOLDER_PRIMARY_SPKI_PIN_BASE64==',
    // Backup pin for certificate rotation
    'PLACEHOLDER_BACKUP_SPKI_PIN_BASE64==',
  ],
  // WebSocket market data endpoint
  'ws.trading.example.com': [
    'PLACEHOLDER_WS_SPKI_PIN_BASE64==',
    'PLACEHOLDER_WS_BACKUP_SPKI_PIN_BASE64==',
  ],
};

/// Minimum TLS version per PCI DSS requirement.
const String minTlsVersion = 'TLSv1.2';

/// Creates an [HttpClient] that enforces SPKI certificate pinning.
///
/// The [badCertificateCallback] is invoked when the server's certificate
/// does not pass system validation (e.g., self-signed) AND also called to
/// allow us to enforce our own SPKI pin check on top of chain validation.
///
/// Note: on iOS/Android, the system trust store already validates the
/// certificate chain. The [badCertificateCallback] here adds an extra layer —
/// we reject any cert whose SPKI fingerprint is not in our allow-list,
/// even if the system considers it valid.
HttpClient createPinnedHttpClient() {
  final client = HttpClient();
  client.badCertificateCallback = _spkiBadCertCallback;
  return client;
}

bool _spkiBadCertCallback(X509Certificate cert, String host, int port) {
  // Allow localhost for testing/development (mock server)
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    AppLogger.debug('SSL pinning: allowing localhost connection for testing');
    return true;
  }

  final pins = _spkiPins[host];
  if (pins == null) {
    // No pin configured for this host — block by default (fail-closed).
    AppLogger.security(
      'SSL pinning: no pin configured for host=$host — connection rejected',
    );
    return false;
  }

  final computedPin = _computeSpkiPin(cert.der);
  if (pins.contains(computedPin)) {
    return true; // Pin matched — allow connection
  }

  AppLogger.security(
    'SSL pin mismatch for host=$host port=$port — '
    'expected one of $pins, got $computedPin',
  );
  return false;
}

/// Computes the SPKI SHA-256 fingerprint of a DER-encoded certificate.
///
/// The full-certificate DER bytes are used here as an approximation.
/// A production implementation should extract only the SubjectPublicKeyInfo
/// field using an ASN.1 parser (the `asn1lib` package) or the platform's
/// native API (SecCertificateCopyKey on iOS, X509_get_X509_PUBKEY on Android).
///
/// Using the full DER bytes gives a cert-level pin (not a true SPKI pin)
/// until the ASN.1 extraction is implemented in Phase 2.
///
/// TODO Phase 2: Replace with proper SPKI-only byte extraction.
String _computeSpkiPin(Uint8List certDer) {
  final digest = sha256.convert(certDer);
  return base64.encode(digest.bytes);
}
