package com.brokerage.ui.icons

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

val CreditCard: ImageVector
    get() {
        val current = _creditCard
        if (current != null) return current

        return ImageVector.Builder(
            name = "com.brokerage.ui.theme.BrokerageTheme.CreditCard",
            defaultWidth = 48.0.dp,
            defaultHeight = 48.0.dp,
            viewportWidth = 960.0f,
            viewportHeight = 960.0f,
        ).apply {
            path(
                fill = SolidColor(Color(0xFF000000)),
            ) {
                moveTo(x = 880.0f, y = 220.0f)
                lineToRelative(dx = 0.0f, dy = 520.0f)
                quadToRelative(dx1 = 0.0f, dy1 = 24.0f, dx2 = -18.0f, dy2 = 42.0f)
                reflectiveQuadToRelative(dx1 = -42.0f, dy1 = 18.0f)
                lineTo(x = 140.0f, y = 800.0f)
                quadToRelative(dx1 = -24.0f, dy1 = 0.0f, dx2 = -42.0f, dy2 = -18.0f)
                reflectiveQuadToRelative(dx1 = -18.0f, dy1 = -42.0f)
                lineToRelative(dx = 0.0f, dy = -520.0f)
                quadToRelative(dx1 = 0.0f, dy1 = -24.0f, dx2 = 18.0f, dy2 = -42.0f)
                reflectiveQuadToRelative(dx1 = 42.0f, dy1 = -18.0f)
                lineToRelative(dx = 680.0f, dy = 0.0f)
                quadToRelative(dx1 = 24.0f, dy1 = 0.0f, dx2 = 42.0f, dy2 = 18.0f)
                reflectiveQuadToRelative(dx1 = 18.0f, dy1 = 42.0f)
                close()
                moveTo(x = 140.0f, y = 329.0f)
                lineToRelative(dx = 680.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -109.0f)
                lineTo(x = 140.0f, y = 220.0f)
                lineToRelative(dx = 0.0f, dy = 109.0f)
                close()
                moveToRelative(dx = 0.0f, dy = 129.0f)
                lineToRelative(dx = 0.0f, dy = 282.0f)
                lineToRelative(dx = 680.0f, dy = 0.0f)
                lineToRelative(dx = 0.0f, dy = -282.0f)
                lineTo(x = 140.0f, y = 458.0f)
                close()
                moveToRelative(dx = 0.0f, dy = 282.0f)
                lineToRelative(dx = 0.0f, dy = -520.0f)
                lineToRelative(dx = 0.0f, dy = 520.0f)
                close()
            }
        }.build().also { _creditCard = it }
    }

@Suppress("ObjectPropertyName")
private var _creditCard: ImageVector? = null
