package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Visibility: ImageVector
    get() {
        val current = _visibility
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Visibility",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 600.5f, y = 580.5f)
                quadTo(x1 = 650.0f, y1 = 531.0f, x2 = 650.0f, y2 = 460.0f)
                reflectiveQuadToRelative(dx1 = -49.5f, dy1 = -120.5f)
                quadTo(x1 = 551.0f, y1 = 290.0f, x2 = 480.0f, y2 = 290.0f)
                reflectiveQuadToRelative(dx1 = -120.5f, dy1 = 49.5f)
                quadTo(x1 = 310.0f, y1 = 389.0f, x2 = 310.0f, y2 = 460.0f)
                reflectiveQuadToRelative(dx1 = 49.5f, dy1 = 120.5f)
                quadTo(x1 = 409.0f, y1 = 630.0f, x2 = 480.0f, y2 = 630.0f)
                reflectiveQuadToRelative(dx1 = 120.5f, dy1 = -49.5f)
                close()
                moveToRelative(dx = -200.0f, dy = -41.0f)
                quadTo(x1 = 368.0f, y1 = 507.0f, x2 = 368.0f, y2 = 460.0f)
                reflectiveQuadToRelative(dx1 = 32.5f, dy1 = -79.5f)
                quadTo(x1 = 433.0f, y1 = 348.0f, x2 = 480.0f, y2 = 348.0f)
                reflectiveQuadToRelative(dx1 = 79.5f, dy1 = 32.5f)
                quadTo(x1 = 592.0f, y1 = 413.0f, x2 = 592.0f, y2 = 460.0f)
                reflectiveQuadToRelative(dx1 = -32.5f, dy1 = 79.5f)
                quadTo(x1 = 527.0f, y1 = 572.0f, x2 = 480.0f, y2 = 572.0f)
                reflectiveQuadToRelative(dx1 = -79.5f, dy1 = -32.5f)
                close()
                moveTo(x = 216.0f, y = 677.0f)
                quadTo(x1 = 98.0f, y1 = 594.0f, x2 = 40.0f, y2 = 460.0f)
                quadToRelative(dx1 = 58.0f, dy1 = -134.0f, dx2 = 176.0f, dy2 = -217.0f)
                reflectiveQuadToRelative(dx1 = 264.0f, dy1 = -83.0f)
                quadToRelative(dx1 = 146.0f, dy1 = 0.0f, dx2 = 264.0f, dy2 = 83.0f)
                reflectiveQuadToRelative(dx1 = 176.0f, dy1 = 217.0f)
                quadToRelative(dx1 = -58.0f, dy1 = 134.0f, dx2 = -176.0f, dy2 = 217.0f)
                reflectiveQuadToRelative(dx1 = -264.0f, dy1 = 83.0f)
                quadToRelative(dx1 = -146.0f, dy1 = 0.0f, dx2 = -264.0f, dy2 = -83.0f)
                close()
                moveToRelative(dx = 264.0f, dy = -217.0f)
                close()
                moveToRelative(dx = 222.5f, dy = 174.5f)
                quadTo(x1 = 804.0f, y1 = 569.0f, x2 = 857.0f, y2 = 460.0f)
                quadToRelative(dx1 = -53.0f, dy1 = -109.0f, dx2 = -154.5f, dy2 = -174.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 220.0f)
                quadToRelative(dx1 = -121.0f, dy1 = 0.0f, dx2 = -222.5f, dy2 = 65.5f)
                reflectiveQuadTo(x1 = 102.0f, y1 = 460.0f)
                quadToRelative(dx1 = 54.0f, dy1 = 109.0f, dx2 = 155.5f, dy2 = 174.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 700.0f)
                quadToRelative(dx1 = 121.0f, dy1 = 0.0f, dx2 = 222.5f, dy2 = -65.5f)
                close()
            }
        }.build().also { _visibility = it }
    }

@Suppress("ObjectPropertyName")
private var _visibility: ImageVector? = null
