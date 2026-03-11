package com.brokerage.ui.util

import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.roundToLong

/**
 * KMP-compatible decimal formatting helper.
 *
 * Replaces JVM-only String.format("%.2f", value) and "%.2f".format(value)
 * with pure Kotlin arithmetic that compiles on all KMP targets (iOS, Android, JS).
 *
 * Note: The input is Double for display-only purposes (mock/UI data). For any
 * financial calculation use Decimal; this helper is for rendering pre-computed
 * display values only.
 */
fun formatDecimal(value: Double, decimals: Int = 2): String {
    val factor = 10.0.pow(decimals)
    val rounded = (abs(value) * factor).roundToLong()
    val intPart = rounded / factor.toLong()
    val fracPart = rounded % factor.toLong()
    val sign = if (value < 0) "-" else ""
    val fracStr = fracPart.toString().padStart(decimals, '0')
    return "${sign}${intPart}.${fracStr}"
}
