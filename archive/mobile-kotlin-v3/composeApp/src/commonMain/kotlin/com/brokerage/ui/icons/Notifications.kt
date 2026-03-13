package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Notifications: ImageVector
    get() {
        val current = _notifications
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Notifications",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 160.0f, y = 760.0f)
                lineToRelative(dx = 0.0f, dy = -60.0f)
                lineToRelative(dx = 80.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -304.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -84.0f, dx2 = 49.5f, dy2 = -150.5f)
                reflectiveQuadTo(x1 = 420.0f, y1 = 162.0f)
                lineToRelative(dx = 0.0f, dy = -22.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -25.0f, dx2 = 17.5f, dy2 = -42.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 80.0f)
                quadToRelative(dx1 = 25.0f, dy1 = 0.0f, dx2 = 42.5f, dy2 = 17.5f)
                reflectiveQuadTo(x1 = 540.0f, y1 = 140.0f)
                lineToRelative(dx = 0.0f, dy = 22.0f)
                quadToRelative(dx1 = 81.0f, dy1 = 17.0f, dx2 = 130.5f, dy2 = 83.5f)
                reflectiveQuadTo(x1 = 720.0f, y1 = 396.0f)
                lineToRelative(dx = 0.0f, dy = 304.0f)
                lineToRelative(dx = 80.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 60.0f)
                lineTo(x = 160.0f, y = 760.0f)
                close()
                moveToRelative(dx = 320.0f, dy = -302.0f)
                close()
                moveToRelative(dx = 0.0f, dy = 422.0f)
                quadToRelative(dx1 = -33.0f, dy1 = 0.0f, dx2 = -56.5f, dy2 = -23.5f)
                reflectiveQuadTo(x1 = 400.0f, y1 = 800.0f)
                lineToRelative(dx = 160.0f, dy = 0.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 33.0f, dx2 = -23.5f, dy2 = 56.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 880.0f)
                close()
                moveTo(x = 300.0f, y = 700.0f)
                lineToRelative(dx = 360.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -304.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -75.0f, dx2 = -52.5f, dy2 = -127.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 216.0f)
                quadToRelative(dx1 = -75.0f, dy1 = 0.0f, dx2 = -127.5f, dy2 = 52.5f)
                reflectiveQuadTo(x1 = 300.0f, y1 = 396.0f)
                lineToRelative(dx = 0.0f, dy = 304.0f)
                close()
            }
        }.build().also { _notifications = it }
    }

@Suppress("ObjectPropertyName")
private var _notifications: ImageVector? = null
