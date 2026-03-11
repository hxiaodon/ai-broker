package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val ArrowForward: ImageVector
    get() {
        val current = _arrowForward
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.ArrowForward",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 686.0f, y = 510.0f)
                lineTo(x = 160.0f, y = 510.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineToRelative(dx = 526.0f, dy = 0.0f)
                lineTo(x = 438.0f, y = 202.0f)
                lineToRelative(dx = 42.0f, dy = -42.0f)
                lineToRelative(dx = 320.0f, dy = 320.0f)
                lineToRelative(dx = -320.0f, dy = 320.0f)
                lineToRelative(dx = -42.0f, dy = -42.0f)
                lineToRelative(dx = 248.0f, dy = -248.0f)
                close()
            }
        }.build().also { _arrowForward = it }
    }

@Suppress("ObjectPropertyName")
private var _arrowForward: ImageVector? = null
