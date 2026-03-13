package com.brokerage.core.biometric

/**
 * Biometric authentication interface
 * Platform-specific implementations for iOS (Face ID/Touch ID) and Android (BiometricPrompt)
 *
 * Required for:
 * - Order submission
 * - Fund withdrawal
 * - Password change
 * - KYC document upload
 */
interface BiometricAuth {
    /**
     * Check if biometric authentication is available on this device
     */
    suspend fun isAvailable(): Boolean

    /**
     * Check if biometric authentication is enrolled (user has set up biometrics)
     */
    suspend fun isEnrolled(): Boolean

    /**
     * Authenticate user with biometrics
     *
     * @param title Dialog title
     * @param subtitle Dialog subtitle/description
     * @param negativeButtonText Text for cancel/fallback button
     * @return BiometricResult indicating success or failure
     */
    suspend fun authenticate(
        title: String,
        subtitle: String,
        negativeButtonText: String = "取消"
    ): BiometricResult
}

/**
 * Result of biometric authentication attempt
 */
sealed class BiometricResult {
    /**
     * Authentication succeeded
     */
    object Success : BiometricResult()

    /**
     * User cancelled the authentication
     */
    object Cancelled : BiometricResult()

    /**
     * Authentication failed (wrong biometric)
     */
    data class Failed(val reason: String) : BiometricResult()

    /**
     * Biometric not available or not enrolled
     */
    data class NotAvailable(val reason: String) : BiometricResult()

    /**
     * System error occurred
     */
    data class Error(val message: String) : BiometricResult()
}

/**
 * Get platform-specific biometric authenticator
 */
expect fun getBiometricAuth(): BiometricAuth
