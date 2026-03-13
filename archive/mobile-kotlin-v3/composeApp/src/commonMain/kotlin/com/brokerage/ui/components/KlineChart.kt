package com.brokerage.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.domain.marketdata.Kline
import com.brokerage.domain.marketdata.KlineInterval
import com.brokerage.ui.theme.BorderLight
import com.brokerage.ui.theme.ChartBlue
import com.brokerage.ui.theme.ChartOrange
import com.brokerage.ui.theme.ChartPurple
import com.brokerage.ui.theme.DangerRed
import com.brokerage.ui.theme.SuccessGreen
import com.brokerage.ui.theme.TextSecondary
import com.brokerage.ui.util.formatDecimal
import kotlin.math.max
import kotlin.math.min

/**
 * 增强版 K线图组件
 * 支持：缩放、拖动、十字线、数据提示、MA线、成交量柱状图、X轴时间标签
 *
 * KMP 兼容：全部使用 Compose DrawScope 和 TextMeasurer，无 android.graphics 依赖
 */
@Composable
fun KlineChart(
    data: List<Kline>,
    modifier: Modifier = Modifier,
    showVolume: Boolean = true,
    showMaLines: Boolean = true,
    interval: KlineInterval = KlineInterval.ONE_DAY
) {
    if (data.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxWidth()
                .height(300.dp)
                .background(Color.White),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "暂无数据",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }
        return
    }

    val textMeasurer = rememberTextMeasurer()

    var scale by remember { mutableStateOf(1f) }
    var offsetX by remember { mutableStateOf(0f) }
    var touchPosition by remember { mutableStateOf<Offset?>(null) }
    var showCrosshair by remember { mutableStateOf(false) }

    // Pre-calculate MA lines over full dataset
    val ma5 = remember(data) { calculateMA(data, 5) }
    val ma10 = remember(data) { calculateMA(data, 10) }
    val ma20 = remember(data) { calculateMA(data, 20) }

    Box(modifier = modifier.fillMaxWidth()) {
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp)
                .background(Color.White)
                .pointerInput(Unit) {
                    detectTransformGestures { _, pan, zoom, _ ->
                        scale = (scale * zoom).coerceIn(0.5f, 3f)
                        offsetX = (offsetX + pan.x).coerceIn(
                            -(size.width * (scale - 1)),
                            0f
                        )
                    }
                }
                .pointerInput(Unit) {
                    detectTapGestures(
                        onPress = { offset ->
                            showCrosshair = true
                            touchPosition = offset
                            tryAwaitRelease()
                            showCrosshair = false
                            touchPosition = null
                        }
                    )
                }
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragStart = { offset ->
                            showCrosshair = true
                            touchPosition = offset
                        },
                        onDrag = { change, _ ->
                            touchPosition = change.position
                        },
                        onDragEnd = {
                            showCrosshair = false
                            touchPosition = null
                        }
                    )
                }
        ) {
            val width = size.width
            val height = size.height

            // Layout constants
            val paddingLeft = 62f
            val paddingRight = 20f
            val paddingTop = 24f
            val xAxisHeight = 20f          // X-axis label area at bottom
            val bottomPadding = xAxisHeight + 4f

            // Vertical split: candle area (top 75%) + gap (5%) + volume (20%) when volume shown
            val totalChartHeight = height - paddingTop - bottomPadding
            val candleAreaHeight: Float
            val volumeAreaTop: Float
            val volumeAreaHeight: Float

            if (showVolume) {
                candleAreaHeight = totalChartHeight * 0.75f
                val gapHeight = totalChartHeight * 0.05f
                volumeAreaHeight = totalChartHeight * 0.20f
                volumeAreaTop = paddingTop + candleAreaHeight + gapHeight
            } else {
                candleAreaHeight = totalChartHeight
                volumeAreaHeight = 0f
                volumeAreaTop = 0f
            }

            val chartWidth = width - paddingLeft - paddingRight

            // Visible data range
            val visibleCount = (data.size / scale).toInt().coerceAtLeast(10)
            val startIndex = ((-offsetX / chartWidth) * data.size).toInt()
                .coerceIn(0, max(0, data.size - visibleCount))
            val endIndex = (startIndex + visibleCount).coerceAtMost(data.size)
            val visibleData = data.subList(startIndex, endIndex)

            if (visibleData.isEmpty()) return@Canvas

            // Price range for visible candles
            val visibleMaxPrice = visibleData.maxOf { maxOf(it.high.toDouble(), it.close.toDouble()) }
            val visibleMinPrice = visibleData.minOf { minOf(it.low.toDouble(), it.close.toDouble()) }
            val visiblePriceRange = visibleMaxPrice - visibleMinPrice

            // Add 5% padding to price range so candles don't touch top/bottom
            val priceRangePadded = if (visiblePriceRange == 0.0) 1.0 else visiblePriceRange * 1.05
            val priceMax = visibleMaxPrice + priceRangePadded * 0.025
            val priceMin = visibleMinPrice - priceRangePadded * 0.025

            fun priceToY(price: Double): Float =
                (paddingTop + ((priceMax - price) / (priceMax - priceMin) * candleAreaHeight)).toFloat()

            // Candle width
            val candleWidth = chartWidth / visibleData.size

            // ── Background grid ──────────────────────────────────────────────
            drawChartGrid(
                chartWidth = chartWidth,
                candleAreaHeight = candleAreaHeight,
                paddingLeft = paddingLeft,
                paddingTop = paddingTop
            )

            // ── Volume bars ──────────────────────────────────────────────────
            if (showVolume) {
                val maxVol = visibleData.maxOf { it.volume }.toFloat().takeIf { it > 0f } ?: 1f
                visibleData.forEachIndexed { index, kline ->
                    val x = paddingLeft + index * candleWidth
                    val volRatio = kline.volume.toFloat() / maxVol
                    val barHeight = volumeAreaHeight * volRatio
                    val barTop = volumeAreaTop + (volumeAreaHeight - barHeight)
                    val color = if (kline.close.toDouble() >= kline.open.toDouble()) {
                        SuccessGreen.copy(alpha = 0.7f)
                    } else {
                        DangerRed.copy(alpha = 0.7f)
                    }
                    val barWidth = (candleWidth * 0.8f).coerceAtLeast(1f)
                    val barLeft = x + (candleWidth - barWidth) / 2f
                    drawRect(
                        color = color,
                        topLeft = Offset(barLeft, barTop),
                        size = Size(barWidth, barHeight)
                    )
                }

                // Separator line between candle area and volume area
                drawLine(
                    color = BorderLight,
                    start = Offset(paddingLeft, volumeAreaTop),
                    end = Offset(paddingLeft + chartWidth, volumeAreaTop),
                    strokeWidth = 1f
                )
            }

            // ── Candlesticks ─────────────────────────────────────────────────
            visibleData.forEachIndexed { index, kline ->
                val x = paddingLeft + index * candleWidth + candleWidth / 2f
                val open = kline.open.toDouble()
                val close = kline.close.toDouble()
                val high = kline.high.toDouble()
                val low = kline.low.toDouble()

                val openY = priceToY(open)
                val closeY = priceToY(close)
                val highY = priceToY(high)
                val lowY = priceToY(low)

                val color = if (close >= open) SuccessGreen else DangerRed

                // Upper and lower wicks
                drawLine(
                    color = color,
                    start = Offset(x, highY),
                    end = Offset(x, lowY),
                    strokeWidth = 1.5f
                )

                // Candle body
                val bodyTop = min(openY, closeY)
                val bodyBottom = max(openY, closeY)
                val bodyHeight = bodyBottom - bodyTop
                val bodyWidth = (candleWidth * 0.65f).coerceAtLeast(2f)

                if (bodyHeight < 1f) {
                    // Doji (cross) candle
                    drawLine(
                        color = color,
                        start = Offset(x - bodyWidth / 2f, bodyTop),
                        end = Offset(x + bodyWidth / 2f, bodyTop),
                        strokeWidth = 1.5f
                    )
                } else {
                    drawRect(
                        color = color,
                        topLeft = Offset(x - bodyWidth / 2f, bodyTop),
                        size = Size(bodyWidth, bodyHeight)
                    )
                }
            }

            // ── MA lines ─────────────────────────────────────────────────────
            if (showMaLines) {
                drawMaLine(
                    maValues = ma5,
                    startIndex = startIndex,
                    visibleData = visibleData,
                    paddingLeft = paddingLeft,
                    candleWidth = candleWidth,
                    color = ChartBlue,
                    priceToY = ::priceToY
                )
                drawMaLine(
                    maValues = ma10,
                    startIndex = startIndex,
                    visibleData = visibleData,
                    paddingLeft = paddingLeft,
                    candleWidth = candleWidth,
                    color = ChartOrange,
                    priceToY = ::priceToY
                )
                drawMaLine(
                    maValues = ma20,
                    startIndex = startIndex,
                    visibleData = visibleData,
                    paddingLeft = paddingLeft,
                    candleWidth = candleWidth,
                    color = ChartPurple,
                    priceToY = ::priceToY
                )
            }

            // ── Y-axis price labels ───────────────────────────────────────────
            drawYAxisLabels(
                textMeasurer = textMeasurer,
                candleAreaHeight = candleAreaHeight,
                paddingLeft = paddingLeft,
                paddingTop = paddingTop,
                priceMax = priceMax,
                priceMin = priceMin
            )

            // ── X-axis time labels ────────────────────────────────────────────
            val xAxisY = height - xAxisHeight + 2f
            drawXAxisLabels(
                textMeasurer = textMeasurer,
                visibleData = visibleData,
                paddingLeft = paddingLeft,
                chartWidth = chartWidth,
                candleWidth = candleWidth,
                xAxisY = xAxisY,
                interval = interval
            )

            // ── Crosshair + tooltip ───────────────────────────────────────────
            if (showCrosshair && touchPosition != null) {
                val pos = touchPosition!!
                val chartBottom = paddingTop + candleAreaHeight

                if (pos.x >= paddingLeft && pos.x <= width - paddingRight &&
                    pos.y >= paddingTop && pos.y <= chartBottom
                ) {
                    // Vertical crosshair line
                    drawLine(
                        color = TextSecondary.copy(alpha = 0.5f),
                        start = Offset(pos.x, paddingTop),
                        end = Offset(pos.x, chartBottom),
                        strokeWidth = 1f
                    )

                    // Horizontal crosshair line
                    drawLine(
                        color = TextSecondary.copy(alpha = 0.5f),
                        start = Offset(paddingLeft, pos.y),
                        end = Offset(width - paddingRight, pos.y),
                        strokeWidth = 1f
                    )

                    // Nearest candle index
                    val index = ((pos.x - paddingLeft) / candleWidth).toInt()
                        .coerceIn(0, visibleData.size - 1)
                    val kline = visibleData[index]

                    // Price at crosshair Y
                    val crosshairPrice = priceMax - (pos.y - paddingTop) / candleAreaHeight * (priceMax - priceMin)

                    // Price label on right Y-axis
                    drawPriceLabel(
                        textMeasurer = textMeasurer,
                        price = crosshairPrice,
                        y = pos.y,
                        x = width - paddingRight,
                        width = width,
                        paddingRight = paddingRight
                    )

                    // OHLC info at top of chart
                    drawOhlcInfo(
                        textMeasurer = textMeasurer,
                        kline = kline,
                        paddingLeft = paddingLeft,
                        paddingTop = paddingTop
                    )
                }
            }
        }

        // Scale indicator overlay
        if (scale != 1f) {
            Text(
                text = "缩放: ${(scale * 100).toInt()}%",
                fontSize = 12.sp,
                color = TextSecondary,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp)
                    .background(Color.White.copy(alpha = 0.8f))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            )
        }
    }
}

// ── MA calculation ────────────────────────────────────────────────────────────

private fun calculateMA(data: List<Kline>, period: Int): List<Double?> {
    return data.mapIndexed { index, _ ->
        if (index < period - 1) null
        else {
            var sum = 0.0
            for (i in 0 until period) {
                sum += data[index - i].close.toDouble()
            }
            sum / period
        }
    }
}

// ── DrawScope extensions ──────────────────────────────────────────────────────

private fun DrawScope.drawChartGrid(
    chartWidth: Float,
    candleAreaHeight: Float,
    paddingLeft: Float,
    paddingTop: Float
) {
    // 5 horizontal grid lines
    for (i in 0..4) {
        val y = paddingTop + candleAreaHeight / 4f * i
        drawLine(
            color = BorderLight,
            start = Offset(paddingLeft, y),
            end = Offset(paddingLeft + chartWidth, y),
            strokeWidth = 1f
        )
    }

    // 5 vertical grid lines
    for (i in 0..4) {
        val x = paddingLeft + chartWidth / 4f * i
        drawLine(
            color = BorderLight.copy(alpha = 0.4f),
            start = Offset(x, paddingTop),
            end = Offset(x, paddingTop + candleAreaHeight),
            strokeWidth = 1f
        )
    }
}

private fun DrawScope.drawMaLine(
    maValues: List<Double?>,
    startIndex: Int,
    visibleData: List<Kline>,
    paddingLeft: Float,
    candleWidth: Float,
    color: Color,
    priceToY: (Double) -> Float
) {
    val path = Path()
    var pathStarted = false

    visibleData.indices.forEach { localIndex ->
        val globalIndex = startIndex + localIndex
        val maVal = if (globalIndex < maValues.size) maValues[globalIndex] else null

        if (maVal != null) {
            val cx = paddingLeft + localIndex * candleWidth + candleWidth / 2f
            val cy = priceToY(maVal)
            if (!pathStarted) {
                path.moveTo(cx, cy)
                pathStarted = true
            } else {
                path.lineTo(cx, cy)
            }
        } else {
            // Reset path segment if MA not yet calculable (insufficient data)
            pathStarted = false
        }
    }

    if (pathStarted) {
        drawPath(
            path = path,
            color = color,
            style = Stroke(width = 2f)
        )
    }
}

private fun DrawScope.drawYAxisLabels(
    textMeasurer: TextMeasurer,
    candleAreaHeight: Float,
    paddingLeft: Float,
    paddingTop: Float,
    priceMax: Double,
    priceMin: Double
) {
    val labelStyle = TextStyle(fontSize = 9.sp, color = TextSecondary)

    for (i in 0..4) {
        val y = paddingTop + candleAreaHeight / 4f * i
        val price = priceMax - (priceMax - priceMin) / 4.0 * i
        val priceText = formatPrice(price)

        val measured = textMeasurer.measure(priceText, labelStyle)
        val textX = paddingLeft - measured.size.width.toFloat() - 6f
        val textY = y - measured.size.height / 2f

        drawText(
            textLayoutResult = measured,
            topLeft = Offset(textX.coerceAtLeast(0f), textY)
        )
    }
}

private fun DrawScope.drawXAxisLabels(
    textMeasurer: TextMeasurer,
    visibleData: List<Kline>,
    paddingLeft: Float,
    chartWidth: Float,
    candleWidth: Float,
    xAxisY: Float,
    interval: KlineInterval
) {
    if (visibleData.isEmpty()) return

    val labelStyle = TextStyle(fontSize = 9.sp, color = TextSecondary)
    val labelCount = 4
    val step = (visibleData.size - 1).coerceAtLeast(1) / labelCount.coerceAtMost(visibleData.size - 1).coerceAtLeast(1)

    val indices = buildList {
        var i = 0
        while (i < visibleData.size) {
            add(i)
            if (size >= labelCount) break
            i += step.coerceAtLeast(1)
        }
        if (visibleData.size - 1 !in this) {
            add(visibleData.size - 1)
        }
    }.distinct().sorted()

    indices.forEach { index ->
        val timestamp = visibleData[index].timestamp
        val label = formatTimestamp(timestamp, interval)
        val cx = paddingLeft + index * candleWidth + candleWidth / 2f

        val measured = textMeasurer.measure(label, labelStyle)
        val textX = (cx - measured.size.width / 2f).coerceIn(
            paddingLeft,
            paddingLeft + chartWidth - measured.size.width
        )
        drawText(
            textLayoutResult = measured,
            topLeft = Offset(textX, xAxisY)
        )
    }
}

private fun DrawScope.drawPriceLabel(
    textMeasurer: TextMeasurer,
    price: Double,
    y: Float,
    x: Float,
    width: Float,
    paddingRight: Float
) {
    val priceText = formatPrice(price)
    val labelStyle = TextStyle(fontSize = 10.sp, color = Color.White)
    val measured = textMeasurer.measure(priceText, labelStyle)

    val bgWidth = measured.size.width.toFloat() + 12f
    val bgHeight = measured.size.height.toFloat() + 6f
    val bgLeft = width - paddingRight - bgWidth + 4f
    val bgTop = y - bgHeight / 2f

    // Dark background pill
    drawRoundRect(
        color = Color(0xFF333333),
        topLeft = Offset(bgLeft, bgTop),
        size = Size(bgWidth, bgHeight),
        cornerRadius = CornerRadius(4f, 4f)
    )

    drawText(
        textLayoutResult = measured,
        topLeft = Offset(bgLeft + 6f, bgTop + 3f)
    )
}

private fun DrawScope.drawOhlcInfo(
    textMeasurer: TextMeasurer,
    kline: Kline,
    paddingLeft: Float,
    paddingTop: Float
) {
    val open = kline.open.toDouble()
    val close = kline.close.toDouble()
    val high = kline.high.toDouble()
    val low = kline.low.toDouble()
    val change = close - open
    val changePercent = if (open != 0.0) change / open * 100.0 else 0.0

    val infoText = "O:${formatPrice(open)}  H:${formatPrice(high)}  L:${formatPrice(low)}  C:${formatPrice(close)}  " +
            "${if (changePercent >= 0) "+" else ""}${formatDecimal(changePercent)}%"

    val textColor = if (close >= open) SuccessGreen else DangerRed
    val labelStyle = TextStyle(fontSize = 10.sp, color = textColor)

    val measured = textMeasurer.measure(infoText, labelStyle)
    drawText(
        textLayoutResult = measured,
        topLeft = Offset(paddingLeft + 4f, paddingTop + 4f)
    )
}

// ── Formatting helpers ────────────────────────────────────────────────────────

private fun formatPrice(price: Double): String {
    return if (price >= 1000.0) formatDecimal(price, 2)
    else if (price >= 10.0) formatDecimal(price, 2)
    else formatDecimal(price, 3)
}

/**
 * Format a Unix-epoch-millisecond timestamp for the X-axis.
 * Intraday intervals show HH:mm; daily and above show MM/dd.
 *
 * Uses simple epoch arithmetic to avoid platform-specific date APIs.
 */
private fun formatTimestamp(timestampMs: Long, interval: KlineInterval): String {
    val isIntraday = when (interval) {
        KlineInterval.ONE_MINUTE,
        KlineInterval.FIVE_MINUTES,
        KlineInterval.FIFTEEN_MINUTES,
        KlineInterval.THIRTY_MINUTES,
        KlineInterval.ONE_HOUR -> true
        else -> false
    }

    // Seconds since Unix epoch
    val epochSec = timestampMs / 1000L

    // Days since 1970-01-01
    val daysSinceEpoch = epochSec / 86400L
    val secondsInDay = epochSec % 86400L
    val hours = secondsInDay / 3600L
    val minutes = (secondsInDay % 3600L) / 60L

    // Gregorian calendar calculation (Zeller-like)
    var z = daysSinceEpoch + 719468L
    val era = (if (z >= 0) z else z - 146096L) / 146097L
    val doe = z - era * 146097L
    val yoe = (doe - doe / 1460L + doe / 36524L - doe / 146096L) / 365L
    val y = yoe + era * 400L
    val doy = doe - (365L * yoe + yoe / 4L - yoe / 100L)
    val mp = (5L * doy + 2L) / 153L
    val d = doy - (153L * mp + 2L) / 5L + 1L
    val m = if (mp < 10L) mp + 3L else mp - 9L

    return if (isIntraday) {
        "${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}"
    } else {
        "${m.toString().padStart(2, '0')}/${d.toString().padStart(2, '0')}"
    }
}
