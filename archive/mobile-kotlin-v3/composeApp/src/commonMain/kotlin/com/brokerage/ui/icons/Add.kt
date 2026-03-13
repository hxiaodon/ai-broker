package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Add: ImageVector
    get() {
        val current = _add
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Add",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 450.0f, y = 510.0f)
                lineTo(x = 200.0f, y = 510.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineToRelative(dx = 250.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -250.0f)
                lineToRelative(dx = 60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 250.0f)
                lineToRelative(dx = 250.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 60.0f)
                lineTo(x = 510.0f, y = 510.0f)
                lineToRelative(dx = 0.0f, dy = 250.0f)
                lineToRelative(dx = -60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -250.0f)
                close()
            }
        }.build().also { _add = it }
    }

@Suppress("ObjectPropertyName")
private var _add: ImageVector? = null
