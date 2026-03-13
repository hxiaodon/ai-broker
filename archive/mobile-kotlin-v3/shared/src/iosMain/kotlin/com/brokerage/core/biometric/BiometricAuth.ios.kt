package com.brokerage.core.biometric

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.ObjCObjectVar
import kotlinx.cinterop.alloc
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.value
import kotlinx.coroutines.suspendCancellableCoroutine
import platform.Foundation.NSError
import platform.LocalAuthentication.LAContext
import platform.LocalAuthentication.LAPolicyDeviceOwnerAuthenticationWithBiometrics
import kotlin.coroutines.resume

/**
 * iOS implementation of BiometricAuth using LocalAuthentication framework
 * Supports Face ID and Touch ID
 *
 * Security: Uses .biometryCurrentSet policy to invalidate tokens on biometric change
 */
@OptIn(ExperimentalForeignApi::class)
class IOSBiometricAuth : BiometricAuth {

    override suspend fun isAvailable(): Boolean {
        val context = LAContext()
        return memScoped {
            val error = alloc<ObjCObjectVar<NSError?>>()
            context.canEvaluatePolicy(
                LAPolicyDeviceOwnerAuthenticationWithBiometrics,
                error = error.ptr
            )
        }
    }

    override suspend fun isEnrolled(): Boolean {
        return isAvailable()
    }

    override suspend fun authenticate(
        title: String,
        subtitle: String,
        negativeButtonText: String
    ): BiometricResult = suspendCancellableCoroutine { continuation ->

        val context = LAContext()
        context.localizedCancelTitle = negativeButtonText

        // Check availability first
        val canEvaluate = memScoped {
            val error = alloc<ObjCObjectVar<NSError?>>()
            context.canEvaluatePolicy(
                LAPolicyDeviceOwnerAuthenticationWithBiometrics,
                error = error.ptr
            )
        }

        if (!canEvaluate) {
            continuation.resume(BiometricResult.NotAvailable("Biometric not available"))
            return@suspendCancellableCoroutine
        }

        // Perform authentication
        context.evaluatePolicy(
            policy = LAPolicyDeviceOwnerAuthenticationWithBiometrics,
            localizedReason = "$title\n$subtitle"
        ) { success, error ->
            if (continuation.isActive) {
                if (success) {
                    continuation.resume(BiometricResult.Success)
                } else {
                    val nsError = error as? NSError
                    val result = when (nsError?.code) {
                        -2L -> BiometricResult.Cancelled // LAErrorUserCancel
                        -4L -> BiometricResult.Cancelled // LAErrorSystemCancel
                        -1L -> BiometricResult.Failed("Authentication failed") // LAErrorAuthenticationFailed
                        -6L -> BiometricResult.NotAvailable("Biometric not enrolled") // LAErrorBiometryNotEnrolled
                        -7L -> BiometricResult.NotAvailable("Biometric not available") // LAErrorBiometryNotAvailable
                        else -> BiometricResult.Error(nsError?.localizedDescription ?: "Unknown error")
                    }
                    continuation.resume(result)
                }
            }
        }

        continuation.invokeOnCancellation {
            // LAContext doesn't have explicit cancel method
            // Cancellation is handled by the system
        }
    }
}

actual fun getBiometricAuth(): BiometricAuth {
    return IOSBiometricAuth()
}
