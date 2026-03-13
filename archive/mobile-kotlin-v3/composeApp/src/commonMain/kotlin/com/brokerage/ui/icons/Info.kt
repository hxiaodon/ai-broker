package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val Info: ImageVector
    get() {
        val current = _info
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.Info",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 453.0f, y = 680.0f)
                lineToRelative(dx = 60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -240.0f)
                lineToRelative(dx = -60.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = 240.0f)
                close()
                moveToRelative(dx = 50.5f, dy = -323.2f)
                quadToRelative(dx1 = 9.5f, dy1 = -9.2f, dx2 = 9.5f, dy2 = -22.8f)
                quadToRelative(dx1 = 0.0f, dy1 = -14.45f, dx2 = -9.48f, dy2 = -24.22f)
                quadToRelative(dx1 = -9.48f, dy1 = -9.78f, dx2 = -23.5f, dy2 = -9.78f)
                reflectiveQuadToRelative(dx1 = -23.52f, dy1 = 9.78f)
                quadTo(x1 = 447.0f, y1 = 319.55f, x2 = 447.0f, y2 = 334.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 13.6f, dx2 = 9.48f, dy2 = 22.8f)
                quadToRelative(dx1 = 9.48f, dy1 = 9.2f, dx2 = 23.5f, dy2 = 9.2f)
                reflectiveQuadToRelative(dx1 = 23.52f, dy1 = -9.2f)
                close()
                moveTo(x = 480.27f, y = 880.0f)
                quadToRelative(dx1 = -82.74f, dy1 = 0.0f, dx2 = -155.5f, dy2 = -31.5f)
                quadTo(x1 = 252.0f, y1 = 817.0f, x2 = 197.5f, y2 = 762.5f)
                reflectiveQuadToRelative(dx1 = -86.0f, dy1 = -127.34f)
                quadTo(x1 = 80.0f, y1 = 562.32f, x2 = 80.0f, y2 = 479.5f)
                reflectiveQuadToRelative(dx1 = 31.5f, dy1 = -155.66f)
                quadTo(x1 = 143.0f, y1 = 251.0f, x2 = 197.5f, y2 = 197.0f)
                reflectiveQuadToRelative(dx1 = 127.34f, dy1 = -85.5f)
                quadTo(x1 = 397.68f, y1 = 80.0f, x2 = 480.5f, y2 = 80.0f)
                reflectiveQuadToRelative(dx1 = 155.66f, dy1 = 31.5f)
                quadTo(x1 = 709.0f, y1 = 143.0f, x2 = 763.0f, y2 = 197.0f)
                reflectiveQuadToRelative(dx1 = 85.5f, dy1 = 127.0f)
                quadTo(x1 = 880.0f, y1 = 397.0f, x2 = 880.0f, y2 = 479.73f)
                quadToRelative(dx1 = 0.0f, dy1 = 82.74f, dx2 = -31.5f, dy2 = 155.5f)
                quadTo(x1 = 817.0f, y1 = 708.0f, x2 = 763.0f, y2 = 762.32f)
                quadToRelative(dx1 = -54.0f, dy1 = 54.31f, dx2 = -127.0f, dy2 = 86.0f)
                quadTo(x1 = 563.0f, y1 = 880.0f, x2 = 480.27f, y2 = 880.0f)
                close()
                moveToRelative(dx = 0.23f, dy = -60.0f)
                quadTo(x1 = 622.0f, y1 = 820.0f, x2 = 721.0f, y2 = 720.5f)
                reflectiveQuadToRelative(dx1 = 99.0f, dy1 = -241.0f)
                quadTo(x1 = 820.0f, y1 = 338.0f, x2 = 721.19f, y2 = 239.0f)
                reflectiveQuadTo(x1 = 480.0f, y1 = 140.0f)
                quadToRelative(dx1 = -141.0f, dy1 = 0.0f, dx2 = -240.5f, dy2 = 98.81f)
                reflectiveQuadTo(x1 = 140.0f, y1 = 480.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 141.0f, dx2 = 99.5f, dy2 = 240.5f)
                reflectiveQuadToRelative(dx1 = 241.0f, dy1 = 99.5f)
                close()
                moveToRelative(dx = -0.5f, dy = -340.0f)
                close()
            }
        }.build().also { _info = it }
    }

@Suppress("ObjectPropertyName")
private var _info: ImageVector? = null
