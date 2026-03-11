package com.brokerage.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Color system for brokerage trading app
 * Based on Tailwind CSS colors from HTML prototypes
 * Supports both light and dark themes
 */

// Primary colors (Tailwind Blue)
val Primary = Color(0xFF3B82F6)        // blue-500
val PrimaryVariant = Color(0xFF2563EB) // blue-600
val PrimaryLight = Color(0xFF60A5FA)   // blue-400
val PrimaryDark = Color(0xFF1D4ED8)    // blue-700

// Background colors
val BackgroundLight = Color(0xFFFAFAFA)  // gray-50
val BackgroundDark = Color(0xFF121212)
val SurfaceLight = Color(0xFFFFFFFF)     // white
val SurfaceDark = Color(0xFF1E1E1E)

// Text colors (Tailwind Gray)
val TextPrimaryLight = Color(0xFF1F2937)   // gray-800
val TextPrimaryDark = Color(0xFFFFFFFF)
val TextSecondaryLight = Color(0xFF6B7280) // gray-500
val TextSecondaryDark = Color(0xFF9CA3AF)  // gray-400
val TextTertiaryLight = Color(0xFF9CA3AF)  // gray-400
val TextTertiaryDark = Color(0xFF6B7280)   // gray-500

// Trading colors (US style: Green up, Red down)
object TradingColors {
    // US style: Green up, Red down (from HTML prototype)
    val UpUS = Color(0xFF10B981)      // green-500 (Tailwind)
    val DownUS = Color(0xFFEF4444)    // red-500 (Tailwind)

    // Asia style: Red up, Green down
    val UpAsia = Color(0xFFEF4444)    // red-500
    val DownAsia = Color(0xFF10B981)  // green-500

    // Neutral
    val Neutral = Color(0xFF6B7280)   // gray-500
}

// Functional colors (Tailwind)
val Success = Color(0xFF10B981)  // green-500
val Warning = Color(0xFFF59E0B)  // amber-500
val Error = Color(0xFFEF4444)    // red-500
val Info = Color(0xFF3B82F6)     // blue-500

// Semantic color aliases (used in UI components)
val PrimaryBlue = Primary
val SuccessGreen = Success
val DangerRed = Error
val WarningOrange = Warning
val InfoBlue = Info

// Text color aliases (for easier usage)
val TextPrimary = TextPrimaryLight
val TextSecondary = TextSecondaryLight
val TextTertiary = TextTertiaryLight

// Chart colors
val ChartRed = Color(0xFFEF4444)     // red-500
val ChartGreen = Color(0xFF10B981)   // green-500
val ChartBlue = Color(0xFF3B82F6)    // blue-500
val ChartOrange = Color(0xFFF97316)  // orange-500
val ChartPurple = Color(0xFFA855F7)  // purple-500
val ChartYellow = Color(0xFFF59E0B)  // amber-500

// Border and divider (Tailwind Gray)
val BorderLight = Color(0xFFE5E7EB)    // gray-200
val BorderDark = Color(0xFF374151)     // gray-700
val DividerLight = Color(0xFFF3F4F6)   // gray-100
val DividerDark = Color(0xFF4B5563)    // gray-600

// Hover and pressed states
val HoverLight = Color(0xFFF3F4F6)     // gray-100
val HoverDark = Color(0xFF374151)      // gray-700
val PressedLight = Color(0xFFE5E7EB)   // gray-200
val PressedDark = Color(0xFF4B5563)    // gray-600

/**
 * Market color preference
 */
enum class MarketColorStyle {
    US,    // Green up, Red down
    ASIA   // Red up, Green down
}

/**
 * Get up/down colors based on market preference
 */
fun getUpColor(style: MarketColorStyle): Color {
    return when (style) {
        MarketColorStyle.US -> TradingColors.UpUS
        MarketColorStyle.ASIA -> TradingColors.UpAsia
    }
}

fun getDownColor(style: MarketColorStyle): Color {
    return when (style) {
        MarketColorStyle.US -> TradingColors.DownUS
        MarketColorStyle.ASIA -> TradingColors.DownAsia
    }
}
