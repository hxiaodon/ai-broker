/// SSL/TLS certificate pinning via SPKI SHA-256 fingerprints.
///
/// ## Why SecurityContext(withTrustedRoots: false)
/// Setting [withTrustedRoots] to false removes the system CA store, so Dart's
/// TLS stack cannot validate any server certificate on its own. Every
/// connection — including those with valid CA-signed certificates — triggers
/// [badCertificateCallback]. This is the only reliable way to intercept
/// connections from a MitM proxy whose CA has been user-installed; the proxy's
/// cert passes system chain validation but fails our SPKI allow-list check.
///
/// ## Pin computation (Phase 1: certificate-level hash)
/// Currently hashes the full DER-encoded certificate (cert pinning).
/// Phase 2: extract SubjectPublicKeyInfo bytes via ASN.1 parsing so that
/// a certificate renewal with the same keypair does not require a pin update.
///
/// ## How to obtain certificate fingerprints
/// Run against your API endpoint:
/// ```sh
/// openssl s_client -connect api.trading.example.com:443 </dev/null 2>/dev/null \
///   | openssl x509 -outform DER \
///   | openssl dgst -sha256 -binary \
///   | base64
/// ```
///
/// ## Certificate rotation SOP
/// T−30 days: Add new cert's pin to [_spkiPins] as second entry and release.
/// T=0:       Rotate server certificate. Both old + new pins are trusted.
/// T+30 days: Remove old pin once new app version is adopted.
///
/// ## TLS version enforcement
/// Dart's [SecurityContext] does not expose a minProtocol setter directly.
/// TLS 1.2+ is enforced at the OS level:
///   iOS: App Transport Security (ATS) — TLS 1.2 minimum by default.
///   Android: Network Security Config + ConscryptProvider enforce TLS 1.2+
///     from API 29 (Android 10+) and via Google Play Services on older devices.
///
/// ## Phase 1 (Placeholder)
/// [_spkiPins] contains placeholder values. Replace with real fingerprints
/// before deploying to production. DO NOT ship production with placeholders.
///
/// Reference: https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../logging/app_logger.dart';

/// Certificate SHA-256 fingerprints per host.
///
/// Always maintain at least two pins per host: current + rotation backup.
///
/// WARNING: Phase 1 placeholder values. DO NOT ship to production.
/// Replace with real certificate fingerprints before release.
const Map<String, List<String>> _spkiPins = {
  // Primary API gateway
  'api.trading.example.com': [
    // TODO Phase 2: Replace with actual certificate SHA-256 fingerprint (base64)
    'PLACEHOLDER_PRIMARY_CERT_PIN_BASE64==',
    // Backup pin for certificate rotation
    'PLACEHOLDER_BACKUP_CERT_PIN_BASE64==',
  ],
  // WebSocket market data endpoint
  'ws.trading.example.com': [
    'PLACEHOLDER_WS_CERT_PIN_BASE64==',
    'PLACEHOLDER_WS_BACKUP_CERT_PIN_BASE64==',
  ],
};

/// Creates an [HttpClient] that enforces certificate pinning for all connections.
///
/// Uses [SecurityContext] with no trusted roots ([withTrustedRoots] = false),
/// which forces [HttpClient.badCertificateCallback] to fire on every TLS
/// handshake — including handshakes where the server presents a valid
/// CA-signed certificate. This defeats MitM proxies that rely on a
/// user-installed root CA to produce apparently-valid certificates.
HttpClient createPinnedHttpClient() {
  // withTrustedRoots: false → no system CAs are trusted → all certificates
  // are "bad" from Dart's perspective → badCertificateCallback fires for
  // every connection, not just self-signed or expired certs.
  final context = SecurityContext(withTrustedRoots: false);
  final client = HttpClient(context: context);
  client.badCertificateCallback = _certPinCallback;
  return client;
}

bool _certPinCallback(X509Certificate cert, String host, int port) {
  // Always allow localhost — mock server used in development and testing.
  if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
    AppLogger.debug('SSL pinning: bypassing for localhost');
    return true;
  }

  final pins = _spkiPins[host];
  if (pins == null) {
    // Fail-closed: no pin configured for this host — reject the connection.
    AppLogger.security(
      'SSL pinning: no pin configured for host=$host — connection rejected',
    );
    return false;
  }

  final computedPin = _computeCertPin(cert.der);
  if (pins.contains(computedPin)) {
    return true;
  }

  AppLogger.security(
    'SSL pin mismatch for host=$host port=$port — '
    'expected one of $pins, got $computedPin',
  );
  return false;
}

/// Computes SHA-256 of the full DER-encoded certificate.
///
/// This is certificate-level pinning (not true SPKI pinning).
/// Phase 2: replace with SPKI extraction via ASN.1 parser so that
/// certificate renewal with the same keypair does not invalidate the pin.
String _computeCertPin(Uint8List certDer) {
  final digest = sha256.convert(certDer);
  return base64.encode(digest.bytes);
}
