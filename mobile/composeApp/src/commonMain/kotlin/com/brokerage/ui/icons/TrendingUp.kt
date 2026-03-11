package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val TrendingUp: ImageVector
    get() {
        val current = _trendingUp
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.TrendingUp",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 123.0f, y = 720.0f)
                lineToRelative(dx = -43.0f, dy = -43.0f)
                lineToRelative(dx = 292.0f, dy = -291.0f)
                lineToRelative(dx = 167.0f, dy = 167.0f)
                lineToRelative(dx = 241.0f, dy = -241.0f)
                lineTo(x = 653.0f, y = 312.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineToRelative(dx = 227.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 227.0f)
                lineToRelative(dx = -59.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -123.0f)
                lineTo(x = 538.0f, y = 639.0f)
                lineTo(x = 371.0f, y = 472.0f)
                lineTo(x = 123.0f, y = 720.0f)
                close()
            }
        }.build().also { _trendingUp = it }
    }

@Suppress("ObjectPropertyName")
private var _trendingUp: ImageVector? = null
