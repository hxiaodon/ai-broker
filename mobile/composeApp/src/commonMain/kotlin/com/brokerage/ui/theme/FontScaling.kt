package com.brokerage.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density

/**
 * 字体缩放级别
 */
enum class FontScale(val scale: Float) {
    SMALL(0.85f),
    NORMAL(1.0f),
    LARGE(1.15f),
    EXTRA_LARGE(1.3f)
}

/**
 * 本地字体缩放配置
 */
val LocalFontScale = staticCompositionLocalOf { FontScale.NORMAL }

/**
 * 应用字体缩放的包装器
 */
@Composable
fun ScalableTheme(
    fontScale: FontScale = FontScale.NORMAL,
    content: @Composable () -> Unit
) {
    val density = LocalDensity.current
    val scaledDensity = Density(
        density = density.density,
        fontScale = density.fontScale * fontScale.scale
    )

    CompositionLocalProvider(
        LocalDensity provides scaledDensity,
        LocalFontScale provides fontScale
    ) {
        content()
    }
}

/**
 * 获取当前字体缩放级别
 */
@Composable
fun currentFontScale(): FontScale {
    return LocalFontScale.current
}

/**
 * 根据字体缩放调整尺寸
 */
fun Float.scaledBy(fontScale: FontScale): Float {
    return this * fontScale.scale
}

/**
 * 根据字体缩放调整整数尺寸
 */
fun Int.scaledBy(fontScale: FontScale): Int {
    return (this * fontScale.scale).toInt()
}
