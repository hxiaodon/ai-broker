package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Close: ImageVector
    get() {
        val current = _close
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Close",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 249.0f, y = 753.0f)
                lineToRelative(dx = -42.0f, dy = -42.0f)
                lineToRelative(dx = 231.0f, dy = -231.0f)
                lineToRelative(dx = -231.0f, dy = -231.0f)
                lineToRelative(dx = 42.0f, dy = -42.0f)
                lineToRelative(dx = 231.0f, dy = 231.0f)
                lineToRelative(dx = 231.0f, dy = -231.0f)
                lineToRelative(dx = 42.0f, dy = 42.0f)
                lineToRelative(dx = -231.0f, dy = 231.0f)
                lineToRelative(dx = 231.0f, dy = 231.0f)
                lineToRelative(dx = -42.0f, dy = 42.0f)
                lineToRelative(dx = -231.0f, dy = -231.0f)
                lineToRelative(dx = -231.0f, dy = 231.0f)
                close()
            }
        }.build().also { _close = it }
    }

@Suppress("ObjectPropertyName")
private var _close: ImageVector? = null
