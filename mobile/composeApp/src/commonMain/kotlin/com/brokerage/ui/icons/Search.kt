package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Search: ImageVector
    get() {
        val current = _search
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Search",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 796.0f, y = 839.0f)
                lineTo(x = 533.0f, y = 576.0f)
                quadToRelative(dx1 = -30.0f, dy1 = 26.0f, dx2 = -70.0f, dy2 = 40.5f)
                reflectiveQuadTo(x1 = 378.0f, y1 = 631.0f)
                quadToRelative(dx1 = -108.0f, dy1 = 0.0f, dx2 = -183.0f, dy2 = -75.0f)
                reflectiveQuadToRelative(dx1 = -75.0f, dy1 = -181.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -106.0f, dx2 = 75.0f, dy2 = -181.0f)
                reflectiveQuadToRelative(dx1 = 182.0f, dy1 = -75.0f)
                quadToRelative(dx1 = 106.0f, dy1 = 0.0f, dx2 = 180.5f, dy2 = 75.0f)
                reflectiveQuadTo(x1 = 632.0f, y1 = 375.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 43.0f, dx2 = -14.0f, dy2 = 83.0f)
                reflectiveQuadToRelative(dx1 = -42.0f, dy1 = 75.0f)
                lineToRelative(dx = 264.0f, dy = 262.0f)
                lineToRelative(dx = -44.0f, dy = 44.0f)
                close()
                moveTo(x = 377.0f, y = 571.0f)
                quadToRelative(dx1 = 81.0f, dy1 = 0.0f, dx2 = 138.0f, dy2 = -57.5f)
                reflectiveQuadTo(x1 = 572.0f, y1 = 375.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -81.0f, dx2 = -57.0f, dy2 = -138.5f)
                reflectiveQuadTo(x1 = 377.0f, y1 = 179.0f)
                quadToRelative(dx1 = -82.0f, dy1 = 0.0f, dx2 = -139.5f, dy2 = 57.5f)
                reflectiveQuadTo(x1 = 180.0f, y1 = 375.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 81.0f, dx2 = 57.5f, dy2 = 138.5f)
                reflectiveQuadTo(x1 = 377.0f, y1 = 571.0f)
                close()
            }
        }.build().also { _search = it }
    }

@Suppress("ObjectPropertyName")
private var _search: ImageVector? = null
