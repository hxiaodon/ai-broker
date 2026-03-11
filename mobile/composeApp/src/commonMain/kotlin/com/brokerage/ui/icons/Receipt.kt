package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Receipt: ImageVector
    get() {
        val current = _receipt
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Receipt",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 120.0f, y = 879.0f)
                lineToRelative(dx = 0.0f, dy = -798.0f)
                lineToRelative(dx = 60.0f, dy = 60.0f)
                lineToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 60.0f, dy = 60.0f)
                lineToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 60.0f, dy = 60.0f)
                lineToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 60.0f, dy = 60.0f)
                lineToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 60.0f, dy = 60.0f)
                lineToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 60.0f, dy = 60.0f)
                lineToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 0.0f, dy = 798.0f)
                lineToRelative(dx = -60.0f, dy = -60.0f)
                lineToRelative(dx = -60.0f, dy = 60.0f)
                lineToRelative(dx = -60.0f, dy = -60.0f)
                lineToRelative(dx = -60.0f, dy = 60.0f)
                lineToRelative(dx = -60.0f, dy = -60.0f)
                lineToRelative(dx = -60.0f, dy = 60.0f)
                lineToRelative(dx = -60.0f, dy = -59.85f)
                lineTo(x = 360.0f, y = 879.0f)
                lineToRelative(dx = -60.0f, dy = -59.85f)
                lineTo(x = 240.0f, y = 879.0f)
                lineToRelative(dx = -60.0f, dy = -59.85f)
                lineTo(x = 120.0f, y = 879.0f)
                close()
                moveToRelative(dx = 117.0f, dy = -215.0f)
                lineToRelative(dx = 490.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineTo(x = 237.0f, y = 604.0f)
                lineToRelative(dx = 0.0f, dy = 60.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -154.0f)
                lineToRelative(dx = 490.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineTo(x = 237.0f, y = 450.0f)
                lineToRelative(dx = 0.0f, dy = 60.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -155.0f)
                lineToRelative(dx = 490.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineTo(x = 237.0f, y = 295.0f)
                lineToRelative(dx = 0.0f, dy = 60.0f)
                close()
                moveToRelative(dx = -57.0f, dy = 423.0f)
                lineToRelative(dx = 600.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -596.0f)
                lineTo(x = 180.0f, y = 182.0f)
                lineToRelative(dx = 0.0f, dy = 596.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -596.0f)
                lineToRelative(dx = 0.0f, dy = 596.0f)
                lineToRelative(dx = 0.0f, dy = -596.0f)
                close()
            }
        }.build().also { _receipt = it }
    }

@Suppress("ObjectPropertyName")
private var _receipt: ImageVector? = null
