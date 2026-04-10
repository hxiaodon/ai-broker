/// Abstract interface for biometric key management.
///
/// Concrete implementations use platform Method Channels:
///   - iOS: Secure Enclave (SecKey) via BiometricKeyManagerPlugin.swift
///   - Android: Android Keystore (KeyPairGenerator) via BiometricKeyManagerPlugin.kt
///
/// Phase 2 will provide the Method Channel implementations.
/// For Phase 1 the stub always returns null / false.
abstract class BiometricKeyManager {
  const BiometricKeyManager();

  /// Generate a key pair protected by biometric authentication.
  /// Returns the public key bytes, or null if biometric is unavailable.
  Future<List<int>?> generateKeyPair({required String keyAlias});

  /// Sign [challenge] bytes with the biometric-protected private key.
  /// Triggers biometric prompt; returns signature bytes or null on failure.
  Future<List<int>?> sign({
    required String keyAlias,
    required List<int> challenge,
  });

  /// Delete the key pair associated with [keyAlias].
  Future<void> deleteKeyPair({required String keyAlias});

  /// Returns true if a key pair exists for [keyAlias].
  Future<bool> hasKeyPair({required String keyAlias});
}

/// Stub implementation used until Method Channel plugins are integrated.
///
/// Phase 1: always returns null/false. NOT production-ready.
/// Phase 2: implement via iOS Secure Enclave (SecKey) and Android Keystore.
class StubBiometricKeyManager extends BiometricKeyManager {
  const StubBiometricKeyManager();

  @override
  Future<List<int>?> generateKeyPair({required String keyAlias}) async => null;

  @override
  Future<List<int>?> sign({
    required String keyAlias,
    required List<int> challenge,
  }) async => null;

  @override
  Future<void> deleteKeyPair({required String keyAlias}) async {}

  @override
  Future<bool> hasKeyPair({required String keyAlias}) async => false;
}
