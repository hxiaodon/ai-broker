package com.brokerage.core.crypto

/**
 * Biometric authentication result
 */
sealed class BiometricResult {
    object Success : BiometricResult()
    data class Error(val message: String) : BiometricResult()
    object Cancelled : BiometricResult()
    object NotAvailable : BiometricResult()
}

/**
 * Biometric authentication interface
 * Platform-specific implementation required
 */
expect class BiometricAuth {
    /**
     * Authenticate user with biometric (Face ID / Touch ID / Fingerprint)
     * @param reason Reason for authentication (displayed to user)
     * @return BiometricResult
     */
    suspend fun authenticate(reason: String): BiometricResult

    /**
     * Check if biometric authentication is available
     */
    fun isAvailable(): Boolean
}

/**
 * Secure storage interface
 * Platform-specific implementation required (Keychain for iOS, Keystore for Android)
 */
expect class SecureStorage {
    /**
     * Save sensitive data securely
     * @param key Storage key
     * @param value Data to store
     */
    fun save(key: String, value: String)

    /**
     * Retrieve sensitive data
     * @param key Storage key
     * @return Stored value or null if not found
     */
    fun get(key: String): String?

    /**
     * Delete sensitive data
     * @param key Storage key
     */
    fun delete(key: String)

    /**
     * Check if key exists
     * @param key Storage key
     */
    fun contains(key: String): Boolean

    /**
     * Clear all stored data
     */
    fun clear()
}

/**
 * Certificate pinning interface
 * Platform-specific implementation required
 */
expect class CertificatePinner {
    /**
     * Pin certificates for a hostname
     * @param hostname Domain name (e.g., "api.brokerage.com")
     * @param pins List of SHA-256 public key hashes (base64 encoded)
     */
    fun pin(hostname: String, pins: List<String>)

    /**
     * Verify certificate for hostname
     * @param hostname Domain name
     * @return true if certificate is valid
     */
    fun verify(hostname: String): Boolean
}

/**
 * Encryption utilities
 */
expect object EncryptionUtils {
    /**
     * Encrypt data using AES-256-GCM
     * Platform-specific implementation
     */
    fun encrypt(data: String, key: ByteArray): ByteArray

    /**
     * Decrypt data using AES-256-GCM
     * Platform-specific implementation
     */
    fun decrypt(encryptedData: ByteArray, key: ByteArray): String

    /**
     * Generate random encryption key
     */
    fun generateKey(): ByteArray

    /**
     * Hash data using SHA-256
     */
    fun sha256(data: String): String
}

/**
 * Secure storage keys (constants)
 */
object SecureStorageKeys {
    const val ACCESS_TOKEN = "access_token"
    const val REFRESH_TOKEN = "refresh_token"
    const val USER_ID = "user_id"
    const val BIOMETRIC_ENABLED = "biometric_enabled"
    const val PIN_CODE = "pin_code"
    const val DEVICE_ID = "device_id"
}
