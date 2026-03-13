package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val PhotoCamera: ImageVector
    get() {
        val current = _photoCamera
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.PhotoCamera",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 479.5f, y = 693.0f)
                quadToRelative(dx1 = 72.5f, dy1 = 0.0f, dx2 = 121.5f, dy2 = -49.0f)
                reflectiveQuadToRelative(dx1 = 49.0f, dy1 = -121.5f)
                quadToRelative(dx1 = 0.0f, dy1 = -72.5f, dx2 = -49.0f, dy2 = -121.0f)
                reflectiveQuadTo(x1 = 479.5f, y1 = 353.0f)
                quadToRelative(dx1 = -72.5f, dy1 = 0.0f, dx2 = -121.0f, dy2 = 48.5f)
                reflectiveQuadToRelative(dx1 = -48.5f, dy1 = 121.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 72.5f, dx2 = 48.5f, dy2 = 121.5f)
                reflectiveQuadToRelative(dx1 = 121.0f, dy1 = 49.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -60.0f)
                quadToRelative(dx1 = -47.5f, dy1 = 0.0f, dx2 = -78.5f, dy2 = -31.5f)
                reflectiveQuadToRelative(dx1 = -31.0f, dy1 = -79.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -47.5f, dx2 = 31.0f, dy2 = -78.5f)
                reflectiveQuadToRelative(dx1 = 78.5f, dy1 = -31.0f)
                quadToRelative(dx1 = 47.5f, dy1 = 0.0f, dx2 = 79.0f, dy2 = 31.0f)
                reflectiveQuadToRelative(dx1 = 31.5f, dy1 = 78.5f)
                quadToRelative(dx1 = 0.0f, dy1 = 47.5f, dx2 = -31.5f, dy2 = 79.0f)
                reflectiveQuadToRelative(dx1 = -79.0f, dy1 = 31.5f)
                close()
                moveTo(x = 140.0f, y = 840.0f)
                quadToRelative(dx1 = -24.0f, dy1 = 0.0f, dx2 = -42.0f, dy2 = -18.0f)
                reflectiveQuadToRelative(dx1 = -18.0f, dy1 = -42.0f)
                lineToRelative(dx = 0.0f, dy = -513.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -23.0f, dx2 = 18.0f, dy2 = -41.5f)
                reflectiveQuadToRelative(dx1 = 42.0f, dy1 = -18.5f)
                lineToRelative(dx = 147.0f, dy = 0.0f)
                lineToRelative(dx = 73.0f, dy = -87.0f)
                lineToRelative(dx = 240.0f, dy = 0.0f)
                lineToRelative(dx = 73.0f, dy = 87.0f)
                lineToRelative(dx = 147.0f, dy = 0.0f)
                quadToRelative(dx1 = 23.0f, dy1 = 0.0f, dx2 = 41.5f, dy2 = 18.5f)
                reflectiveQuadTo(x1 = 880.0f, y1 = 267.0f)
                lineToRelative(dx = 0.0f, dy = 513.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 24.0f, dx2 = -18.5f, dy2 = 42.0f)
                reflectiveQuadTo(x1 = 820.0f, y1 = 840.0f)
                lineTo(x = 140.0f, y = 840.0f)
                close()
                moveToRelative(dx = 0.0f, dy = -60.0f)
                lineToRelative(dx = 680.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -513.0f)
                lineTo(x = 645.0f, y = 267.0f)
                lineToRelative(dx = -73.0f, dy = -87.0f)
                lineTo(x = 388.0f, y = 180.0f)
                lineToRelative(dx = -73.0f, dy = 87.0f)
                lineTo(x = 140.0f, y = 267.0f)
                lineToRelative(dx = 0.0f, dy = 513.0f)
                close()
                moveToRelative(dx = 340.0f, dy = -257.0f)
                close()
            }
        }.build().also { _photoCamera = it }
    }

@Suppress("ObjectPropertyName")
private var _photoCamera: ImageVector? = null
