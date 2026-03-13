package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val ChevronRight: ImageVector
    get() {
        val current = _chevronRight
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.ChevronRight",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 530.0f, y = 479.0f)
                lineTo(x = 332.0f, y = 281.0f)
                lineToRelative(dx = 43.0f, dy = -43.0f)
                lineToRelative(dx = 241.0f, dy = 241.0f)
                lineToRelative(dx = -241.0f, dy = 241.0f)
                lineToRelative(dx = -43.0f, dy = -43.0f)
                lineToRelative(dx = 198.0f, dy = -198.0f)
                close()
            }
        }.build().also { _chevronRight = it }
    }

@Suppress("ObjectPropertyName")
private var _chevronRight: ImageVector? = null
