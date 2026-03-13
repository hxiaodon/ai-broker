package com.brokerage.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
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
import com.brokerage.ui.theme.BorderLight
import com.brokerage.ui.theme.DangerRed
import com.brokerage.ui.theme.SuccessGreen
import com.brokerage.ui.theme.TextSecondary
import com.brokerage.ui.util.formatDecimal
import kotlin.math.max
import kotlin.math.min

/**
 * 分时图组件
 * - 折线连接各分钟收盘价
 * - 渐变填充（涨=红填充, 跌=绿填充）
 * - 均线（MA of visible prices）
 * - 触摸十字光标 + 价格标注
 */
@Composable
fun TimeSharingChart(
    data: List<Kline>,
    modifier: Modifier = Modifier,
    prevClose: Double? = null
) {
    if (data.isEmpty()) return

    val textMeasurer = rememberTextMeasurer()
    var crosshairX by remember { mutableStateOf<Float?>(null) }
    var isDragging by remember { mutableStateOf(false) }

    val chartHeight = 200.dp
    val volumeHeight = 50.dp
    val totalHeight = chartHeight + volumeHeight

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(totalHeight)
            .background(Color.White)
    ) {
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(totalHeight)
                .pointerInput(data) {
                    detectTapGestures { offset ->
                        crosshairX = offset.x
                    }
                }
                .pointerInput(data) {
                    detectDragGestures(
                        onDragStart = { offset ->
                            isDragging = true
                            crosshairX = offset.x
                        },
                        onDrag = { change, _ ->
                            crosshairX = change.position.x
                        },
                        onDragEnd = { isDragging = false },
                        onDragCancel = { isDragging = false }
                    )
                }
        ) {
            val chartHeightPx = size.height * 0.80f
            val volumeHeightPx = size.height * 0.20f
            val volumeTop = chartHeightPx
            val paddingLeft = 8.dp.toPx()
            val paddingRight = 8.dp.toPx()
            val chartWidth = size.width - paddingLeft - paddingRight

            val prices = data.map { it.close.toDouble() }
            val volumes = data.map { it.volume }

            val priceMin = prices.minOrNull() ?: 0.0
            val priceMax = prices.maxOrNull() ?: 1.0
            val priceRange = (priceMax - priceMin).let { if (it < 0.001) 1.0 else it }

            // Baseline: use prevClose if provided, otherwise first candle close
            val baseline = prevClose ?: prices.first()
            val isUp = (prices.lastOrNull() ?: baseline) >= baseline

            val lineColor = if (isUp) DangerRed else SuccessGreen
            val fillColorTop = if (isUp) DangerRed.copy(alpha = 0.25f) else SuccessGreen.copy(alpha = 0.25f)
            val fillColorBottom = Color.Transparent

            val n = data.size

            fun priceToY(price: Double): Float {
                return chartHeightPx - ((price - priceMin) / priceRange * chartHeightPx * 0.85f + chartHeightPx * 0.075f)
            }

            fun indexToX(i: Int): Float {
                return paddingLeft + i.toFloat() / (n - 1).coerceAtLeast(1) * chartWidth
            }

            // ── Draw grid lines (3 horizontal) ────────────────────────────────
            val gridPaint = BorderLight.copy(alpha = 0.6f)
            for (row in listOf(0f, 0.25f, 0.5f, 0.75f, 1f)) {
                val y = row * chartHeightPx
                drawLine(
                    color = gridPaint,
                    start = Offset(paddingLeft, y),
                    end = Offset(paddingLeft + chartWidth, y),
                    strokeWidth = 0.5f
                )
            }

            // ── Build line path ───────────────────────────────────────────────
            val linePath = Path()
            val fillPath = Path()

            for (i in 0 until n) {
                val x = indexToX(i)
                val y = priceToY(prices[i])
                if (i == 0) {
                    linePath.moveTo(x, y)
                    fillPath.moveTo(x, chartHeightPx)
                    fillPath.lineTo(x, y)
                } else {
                    linePath.lineTo(x, y)
                    fillPath.lineTo(x, y)
                }
            }
            // Close the fill path at the bottom
            fillPath.lineTo(indexToX(n - 1), chartHeightPx)
            fillPath.close()

            // ── Draw fill area (gradient) ─────────────────────────────────────
            drawPath(
                path = fillPath,
                brush = Brush.verticalGradient(
                    colors = listOf(fillColorTop, fillColorBottom),
                    startY = 0f,
                    endY = chartHeightPx
                )
            )

            // ── Draw price line ───────────────────────────────────────────────
            drawPath(
                path = linePath,
                color = lineColor,
                style = Stroke(width = 1.5f)
            )

            // ── Draw MA line ──────────────────────────────────────────────────
            val maPeriod = min(20, n)
            if (n >= maPeriod) {
                drawMaLine(prices, n, maPeriod, ::indexToX, ::priceToY)
            }

            // ── Draw Y-axis price labels (left) ───────────────────────────────
            drawTimeSharingYLabels(priceMin, priceMax, chartHeightPx, paddingLeft, textMeasurer)

            // ── Draw volume bars ──────────────────────────────────────────────
            val maxVol = volumes.maxOrNull()?.toDouble() ?: 1.0
            val barWidth = (chartWidth / n.toFloat()).coerceAtLeast(2f)
            for (i in 0 until n) {
                val volRatio = if (maxVol > 0) volumes[i].toDouble() / maxVol else 0.0
                val barH = (volRatio * volumeHeightPx * 0.85f).toFloat()
                val x = indexToX(i)
                val barColor = if (i == 0 || prices[i] >= prices[i - 1]) DangerRed.copy(alpha = 0.7f)
                               else SuccessGreen.copy(alpha = 0.7f)
                drawRect(
                    color = barColor,
                    topLeft = Offset(x - barWidth / 2f + 0.5f, volumeTop + volumeHeightPx - barH),
                    size = Size((barWidth - 1f).coerceAtLeast(1f), barH)
                )
            }

            // ── Draw crosshair ────────────────────────────────────────────────
            val cx = crosshairX
            if (cx != null) {
                val clampedX = cx.coerceIn(paddingLeft, paddingLeft + chartWidth)
                val idx = ((clampedX - paddingLeft) / chartWidth * (n - 1)).toInt().coerceIn(0, n - 1)
                val snapX = indexToX(idx)
                val snapY = priceToY(prices[idx])
                val snapPrice = prices[idx]

                // Vertical line
                drawLine(
                    color = TextSecondary.copy(alpha = 0.6f),
                    start = Offset(snapX, 0f),
                    end = Offset(snapX, size.height),
                    strokeWidth = 0.8f
                )
                // Horizontal line (chart area only)
                drawLine(
                    color = TextSecondary.copy(alpha = 0.6f),
                    start = Offset(paddingLeft, snapY),
                    end = Offset(paddingLeft + chartWidth, snapY),
                    strokeWidth = 0.8f
                )
                // Price label on right
                drawCrosshairPriceLabel(snapX, snapY, snapPrice, size.width, textMeasurer)
            }
        }
    }
}

// ── Private helpers ────────────────────────────────────────────────────────────

private fun DrawScope.drawMaLine(
    prices: List<Double>,
    n: Int,
    period: Int,
    indexToX: (Int) -> Float,
    priceToY: (Double) -> Float
) {
    val maPath = Path()
    var started = false
    for (i in (period - 1) until n) {
        val ma = prices.subList(i - period + 1, i + 1).average()
        val x = indexToX(i)
        val y = priceToY(ma)
        if (!started) {
            maPath.moveTo(x, y)
            started = true
        } else {
            maPath.lineTo(x, y)
        }
    }
    drawPath(
        path = maPath,
        color = Color(0xFFFF9800),  // orange MA line
        style = Stroke(width = 1.0f)
    )
}

private fun DrawScope.drawTimeSharingYLabels(
    priceMin: Double,
    priceMax: Double,
    chartHeightPx: Float,
    paddingLeft: Float,
    textMeasurer: TextMeasurer
) {
    val labels = listOf(
        priceMax to 0f,
        ((priceMax + priceMin) / 2) to chartHeightPx / 2f,
        priceMin to chartHeightPx
    )
    val style = TextStyle(fontSize = 9.sp, color = TextSecondary)
    for ((price, y) in labels) {
        val text = formatDecimal(price, 2)
        val result = textMeasurer.measure(text, style)
        val drawY = (y - result.size.height / 2f).coerceIn(0f, chartHeightPx - result.size.height.toFloat())
        drawText(
            textMeasurer = textMeasurer,
            text = text,
            style = style,
            topLeft = Offset(paddingLeft, drawY)
        )
    }
}

private fun DrawScope.drawCrosshairPriceLabel(
    x: Float,
    y: Float,
    price: Double,
    canvasWidth: Float,
    textMeasurer: TextMeasurer
) {
    val text = formatDecimal(price, 2)
    val style = TextStyle(fontSize = 10.sp, color = Color.White)
    val measured = textMeasurer.measure(text, style)
    val labelW = measured.size.width.toFloat() + 8f
    val labelH = measured.size.height.toFloat() + 4f
    val labelX = if (x + labelW + 4f < canvasWidth) x + 4f else x - labelW - 4f
    val labelY = (y - labelH / 2f).coerceIn(0f, size.height - labelH)

    drawRoundRect(
        color = Color(0xFF444444),
        topLeft = Offset(labelX, labelY),
        size = Size(labelW, labelH),
        cornerRadius = CornerRadius(3f)
    )
    drawText(
        textMeasurer = textMeasurer,
        text = text,
        style = style,
        topLeft = Offset(labelX + 4f, labelY + 2f)
    )
}
