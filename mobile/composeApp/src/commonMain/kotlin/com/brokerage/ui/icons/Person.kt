package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Person: ImageVector
    get() {
        val current = _person
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Person",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 372.0f, y = 437.0f)
                quadToRelative(dx1 = -42.0f, dy1 = -42.0f, dx2 = -42.0f, dy2 = -108.0f)
                reflectiveQuadToRelative(dx1 = 42.0f, dy1 = -108.0f)
                quadToRelative(dx1 = 42.0f, dy1 = -42.0f, dx2 = 108.0f, dy2 = -42.0f)
                reflectiveQuadToRelative(dx1 = 108.0f, dy1 = 42.0f)
                quadToRelative(dx1 = 42.0f, dy1 = 42.0f, dx2 = 42.0f, dy2 = 108.0f)
                reflectiveQuadToRelative(dx1 = -42.0f, dy1 = 108.0f)
                quadToRelative(dx1 = -42.0f, dy1 = 42.0f, dx2 = -108.0f, dy2 = 42.0f)
                reflectiveQuadToRelative(dx1 = -108.0f, dy1 = -42.0f)
                close()
                moveTo(x = 160.0f, y = 800.0f)
                lineToRelative(dx = 0.0f, dy = -94.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -38.0f, dx2 = 19.0f, dy2 = -65.0f)
                reflectiveQuadToRelative(dx1 = 49.0f, dy1 = -41.0f)
                quadToRelative(dx1 = 67.0f, dy1 = -30.0f, dx2 = 128.5f, dy2 = -45.0f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 540.0f)
                quadToRelative(dx1 = 62.0f, dy1 = 0.0f, dx2 = 123.0f, dy2 = 15.5f)
                reflectiveQuadTo(x1 = 731.0f, y1 = 600.0f)
                quadToRelative(dx1 = 31.0f, dy1 = 14.0f, dx2 = 50.0f, dy2 = 41.0f)
                reflectiveQuadToRelative(dx1 = 19.0f, dy1 = 65.0f)
                lineToRelative(dx = 0.0f, dy = 94.0f)
                lineTo(x = 160.0f, y = 800.0f)
                close()
                moveToRelative(dx = 60.0f, dy = -60.0f)
                lineToRelative(dx = 520.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -34.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -16.0f, dx2 = -9.5f, dy2 = -30.5f)
                reflectiveQuadTo(x1 = 707.0f, y1 = 654.0f)
                quadToRelative(dx1 = -64.0f, dy1 = -31.0f, dx2 = -117.0f, dy2 = -42.5f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 600.0f)
                quadToRelative(dx1 = -57.0f, dy1 = 0.0f, dx2 = -111.0f, dy2 = 11.5f)
                reflectiveQuadTo(x1 = 252.0f, y1 = 654.0f)
                quadToRelative(dx1 = -14.0f, dy1 = 7.0f, dx2 = -23.0f, dy2 = 21.5f)
                reflectiveQuadToRelative(dx1 = -9.0f, dy1 = 30.5f)
                lineToRelative(dx = 0.0f, dy = 34.0f)
                close()
                moveToRelative(dx = 324.5f, dy = -346.5f)
                quadTo(x1 = 570.0f, y1 = 368.0f, x2 = 570.0f, y2 = 329.0f)
                reflectiveQuadToRelative(dx1 = -25.5f, dy1 = -64.5f)
                quadTo(x1 = 519.0f, y1 = 239.0f, x2 = 480.0f, y2 = 239.0f)
                reflectiveQuadToRelative(dx1 = -64.5f, dy1 = 25.5f)
                quadTo(x1 = 390.0f, y1 = 290.0f, x2 = 390.0f, y2 = 329.0f)
                reflectiveQuadToRelative(dx1 = 25.5f, dy1 = 64.5f)
                quadTo(x1 = 441.0f, y1 = 419.0f, x2 = 480.0f, y2 = 419.0f)
                reflectiveQuadToRelative(dx1 = 64.5f, dy1 = -25.5f)
                close()
                moveTo(x = 480.0f, y = 329.0f)
                close()
                moveToRelative(dx = 0.0f, dy = 411.0f)
                close()
            }
        }.build().also { _person = it }
    }

@Suppress("ObjectPropertyName")
private var _person: ImageVector? = null
