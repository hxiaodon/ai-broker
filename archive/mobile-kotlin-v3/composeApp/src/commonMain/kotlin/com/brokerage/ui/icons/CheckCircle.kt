package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val CheckCircle: ImageVector
    get() {
        val current = _checkCircle
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.CheckCircle",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 421.0f, y = 662.0f)
                lineToRelative(dx = 283.0f, dy = -283.0f)
                lineToRelative(dx = -46.0f, dy = -45.0f)
                lineToRelative(dx = -237.0f, dy = 237.0f)
                lineToRelative(dx = -120.0f, dy = -120.0f)
                lineToRelative(dx = -45.0f, dy = 45.0f)
                lineToRelative(dx = 165.0f, dy = 166.0f)
                close()
                moveToRelative(dx = 59.0f, dy = 218.0f)
                quadToRelative(dx1 = -82.0f, dy1 = 0.0f, dx2 = -155.0f, dy2 = -31.5f)
                reflectiveQuadToRelative(dx1 = -127.5f, dy1 = -86.0f)
                quadTo(x1 = 143.0f, y1 = 708.0f, x2 = 111.5f, y2 = 635.0f)
                reflectiveQuadTo(x1 = 80.0f, y1 = 480.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -83.0f, dx2 = 31.5f, dy2 = -156.0f)
                reflectiveQuadToRelative(dx1 = 86.0f, dy1 = -127.0f)
                quadTo(x1 = 252.0f, y1 = 143.0f, x2 = 325.0f, y2 = 111.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 80.0f)
                quadToRelative(dx1 = 83.0f, dy1 = 0.0f, dx2 = 156.0f, dy2 = 31.5f)
                reflectiveQuadTo(x1 = 763.0f, y1 = 197.0f)
                quadToRelative(dx1 = 54.0f, dy1 = 54.0f, dx2 = 85.5f, dy2 = 127.0f)
                reflectiveQuadTo(x1 = 880.0f, y1 = 480.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 82.0f, dx2 = -31.5f, dy2 = 155.0f)
                reflectiveQuadTo(x1 = 763.0f, y1 = 762.5f)
                quadToRelative(dx1 = -54.0f, dy1 = 54.5f, dx2 = -127.0f, dy2 = 86.0f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 880.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -60.0f)
                quadToRelative(dx1 = 142.0f, dy1 = 0.0f, dx2 = 241.0f, dy2 = -99.5f)
                reflectiveQuadTo(x1 = 820.0f, y1 = 480.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -142.0f, dx2 = -99.0f, dy2 = -241.0f)
                reflectiveQuadToRelative(dx1 = -241.0f, dy1 = -99.0f)
                quadToRelative(dx1 = -141.0f, dy1 = 0.0f, dx2 = -240.5f, dy2 = 99.0f)
                reflectiveQuadTo(x1 = 140.0f, y1 = 480.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 141.0f, dx2 = 99.5f, dy2 = 240.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 820.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -340.0f)
                close()
            }
        }.build().also { _checkCircle = it }
    }

@Suppress("ObjectPropertyName")
private var _checkCircle: ImageVector? = null
