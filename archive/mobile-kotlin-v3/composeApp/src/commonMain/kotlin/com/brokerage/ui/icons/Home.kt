package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Home: ImageVector
    get() {
        val current = _home
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Home",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 220.0f, y = 780.0f)
                lineToRelative(dx = 150.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -250.0f)
                lineToRelative(dx = 220.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 250.0f)
                lineToRelative(dx = 150.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -390.0f)
                lineTo(x = 480.0f, y = 195.0f)
                lineTo(x = 220.0f, y = 390.0f)
                lineToRelative(dx = 0.0f, dy = 390.0f)
                close()
                moveToRelative(dx = -60.0f, dy = 60.0f)
                lineToRelative(dx = 0.0f, dy = -480.0f)
                lineToRelative(dx = 320.0f, dy = -240.0f)
                lineToRelative(dx = 320.0f, dy = 240.0f)
                lineToRelative(dx = 0.0f, dy = 480.0f)
                lineTo(x = 530.0f, y = 840.0f)
                lineToRelative(dx = 0.0f, dy = -250.0f)
                lineTo(x = 430.0f, y = 590.0f)
                lineToRelative(dx = 0.0f, dy = 250.0f)
                lineTo(x = 160.0f, y = 840.0f)
                close()
                moveToRelative(dx = 320.0f, dy = -353.0f)
                close()
            }
        }.build().also { _home = it }
    }

@Suppress("ObjectPropertyName")
private var _home: ImageVector? = null
