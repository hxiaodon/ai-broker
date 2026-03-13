package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Delete: ImageVector
    get() {
        val current = _delete
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Delete",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 261.0f, y = 840.0f)
                quadToRelative(dx1 = -24.75f, dy1 = 0.0f, dx2 = -42.37f, dy2 = -17.63f)
                quadTo(x1 = 201.0f, y1 = 804.75f, x2 = 201.0f, y2 = 780.0f)
                lineToRelative(dx = 0.0f, dy = -570.0f)
                lineToRelative(dx = -41.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineToRelative(dx = 188.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -30.0f)
                lineToRelative(dx = 264.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 30.0f)
                lineToRelative(dx = 188.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 60.0f)
                lineToRelative(dx = -41.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 570.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 24.0f, dx2 = -18.0f, dy2 = 42.0f)
                reflectiveQuadToRelative(dx1 = -42.0f, dy1 = 18.0f)
                lineTo(x = 261.0f, y = 840.0f)
                close()
                moveToRelative(dx = 438.0f, dy = -630.0f)
                lineTo(x = 261.0f, y = 210.0f)
                lineToRelative(dx = 0.0f, dy = 570.0f)
                lineToRelative(dx = 438.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -570.0f)
                close()
                moveTo(x = 367.0f, y = 694.0f)
                lineToRelative(dx = 60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -399.0f)
                lineToRelative(dx = -60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 399.0f)
                close()
                moveToRelative(dx = 166.0f, dy = 0.0f)
                lineToRelative(dx = 60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -399.0f)
                lineToRelative(dx = -60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 399.0f)
                close()
                moveTo(x = 261.0f, y = 210.0f)
                lineToRelative(dx = 0.0f, dy = 570.0f)
                lineToRelative(dx = 0.0f, dy = -570.0f)
                close()
            }
        }.build().also { _delete = it }
    }

@Suppress("ObjectPropertyName")
private var _delete: ImageVector? = null
