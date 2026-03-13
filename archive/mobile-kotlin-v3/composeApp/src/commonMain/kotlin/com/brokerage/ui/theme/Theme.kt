package com.brokerage.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * 浅色主题颜色方案
 */
private val LightColorScheme = lightColorScheme(
    primary = Primary,
    onPrimary = Color.White,
    primaryContainer = PrimaryLight,
    onPrimaryContainer = PrimaryDark,

    secondary = Color(0xFF3B82F6),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFDCEEFF),
    onSecondaryContainer = Color(0xFF1E3A8A),

    tertiary = Color(0xFF9333EA),
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFF3E8FF),
    onTertiaryContainer = Color(0xFF5B21B6),

    error = Error,
    onError = Color.White,
    errorContainer = Color(0xFFFEE2E2),
    onErrorContainer = Color(0xFF7F1D1D),

    background = BackgroundLight,
    onBackground = TextPrimaryLight,

    surface = SurfaceLight,
    onSurface = TextPrimaryLight,
    surfaceVariant = Color(0xFFF3F4F6),
    onSurfaceVariant = TextSecondaryLight,

    outline = BorderLight,
    outlineVariant = DividerLight
)

/**
 * 深色主题颜色方案
 */
private val DarkColorScheme = darkColorScheme(
    primary = PrimaryLight,
    onPrimary = Color.Black,
    primaryContainer = PrimaryDark,
    onPrimaryContainer = Color.White,

    secondary = Color(0xFF60A5FA),
    onSecondary = Color.Black,
    secondaryContainer = Color(0xFF1E3A8A),
    onSecondaryContainer = Color.White,

    tertiary = Color(0xFFA78BFA),
    onTertiary = Color.Black,
    tertiaryContainer = Color(0xFF5B21B6),
    onTertiaryContainer = Color.White,

    error = Color(0xFFEF4444),
    onError = Color.White,
    errorContainer = Color(0xFF7F1D1D),
    onErrorContainer = Color(0xFFFEE2E2),

    background = BackgroundDark,
    onBackground = TextPrimaryDark,

    surface = SurfaceDark,
    onSurface = TextPrimaryDark,
    surfaceVariant = Color(0xFF2D2D2D),
    onSurfaceVariant = TextSecondaryDark,

    outline = BorderDark,
    outlineVariant = Color(0xFF4B5563)
)

/**
 * 自定义扩展颜色（Material 3 不支持的颜色）
 */
data class ExtendedColors(
    val success: Color,
    val onSuccess: Color,
    val warning: Color,
    val onWarning: Color,
    val info: Color,
    val onInfo: Color,
    val upColor: Color,
    val downColor: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val divider: Color,
    val hover: Color,
    val pressed: Color
)

private val LightExtendedColors = ExtendedColors(
    success = Success,
    onSuccess = Color.White,
    warning = Warning,
    onWarning = Color.White,
    info = Info,
    onInfo = Color.White,
    upColor = TradingColors.UpUS,
    downColor = TradingColors.DownUS,
    textSecondary = TextSecondaryLight,
    textTertiary = TextTertiaryLight,
    divider = DividerLight,
    hover = HoverLight,
    pressed = PressedLight
)

private val DarkExtendedColors = ExtendedColors(
    success = Color(0xFF10B981),
    onSuccess = Color.Black,
    warning = Color(0xFFFBBF24),
    onWarning = Color.Black,
    info = Color(0xFF60A5FA),
    onInfo = Color.Black,
    upColor = TradingColors.UpUS,
    downColor = TradingColors.DownUS,
    textSecondary = TextSecondaryDark,
    textTertiary = TextTertiaryDark,
    divider = DividerDark,
    hover = HoverDark,
    pressed = PressedDark
)

val LocalExtendedColors = staticCompositionLocalOf { LightExtendedColors }

/**
 * 应用主题
 */
@Composable
fun BrokerageTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val extendedColors = if (darkTheme) DarkExtendedColors else LightExtendedColors

    CompositionLocalProvider(LocalExtendedColors provides extendedColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = AppTypography,
            content = content
        )
    }
}

/**
 * 访问扩展颜色
 */
object AppTheme {
    val extendedColors: ExtendedColors
        @Composable
        get() = LocalExtendedColors.current
}
