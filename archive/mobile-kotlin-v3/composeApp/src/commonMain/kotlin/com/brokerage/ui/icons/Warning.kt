package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Warning: ImageVector
    get() {
        val current = _warning
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Warning",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 40.0f, y = 840.0f)
                lineToRelative(dx = 440.0f, dy = -760.0f)
                lineToRelative(dx = 440.0f, dy = 760.0f)
                lineTo(x = 40.0f, y = 840.0f)
                close()
                moveToRelative(dx = 104.0f, dy = -60.0f)
                lineToRelative(dx = 672.0f, dy = 0.0f)
                lineTo(x = 480.0f, y = 200.0f)
                lineTo(x = 144.0f, y = 780.0f)
                close()
                moveToRelative(dx = 361.5f, dy = -65.68f)
                quadToRelative(dx1 = 8.5f, dy1 = -8.67f, dx2 = 8.5f, dy2 = -21.5f)
                quadToRelative(dx1 = 0.0f, dy1 = -12.82f, dx2 = -8.68f, dy2 = -21.32f)
                quadToRelative(dx1 = -8.67f, dy1 = -8.5f, dx2 = -21.5f, dy2 = -8.5f)
                quadToRelative(dx1 = -12.82f, dy1 = 0.0f, dx2 = -21.32f, dy2 = 8.68f)
                quadToRelative(dx1 = -8.5f, dy1 = 8.67f, dx2 = -8.5f, dy2 = 21.5f)
                quadToRelative(dx1 = 0.0f, dy1 = 12.82f, dx2 = 8.68f, dy2 = 21.32f)
                quadToRelative(dx1 = 8.67f, dy1 = 8.5f, dx2 = 21.5f, dy2 = 8.5f)
                quadToRelative(dx1 = 12.82f, dy1 = 0.0f, dx2 = 21.32f, dy2 = -8.68f)
                close()
                moveTo(x = 454.0f, y = 612.0f)
                lineToRelative(dx = 60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -224.0f)
                lineToRelative(dx = -60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 224.0f)
                close()
                moveToRelative(dx = 26.0f, dy = -122.0f)
                close()
            }
        }.build().also { _warning = it }
    }

@Suppress("ObjectPropertyName")
private var _warning: ImageVector? = null
