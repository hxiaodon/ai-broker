package com.brokerage.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.domain.marketdata.OrderBook
import com.brokerage.domain.marketdata.PriceLevel
import com.brokerage.ui.theme.BackgroundLight
import com.brokerage.ui.theme.BorderLight
import com.brokerage.ui.theme.DangerRed
import com.brokerage.ui.theme.SuccessGreen
import com.brokerage.ui.theme.TextPrimary
import com.brokerage.ui.theme.TextSecondary
import com.brokerage.ui.util.formatDecimal

/**
 * 盘口组件 — 5档买卖盘口
 *
 * 布局：卖盘（上方，红色）→ 价差行 → 买盘（下方，绿色）
 * 每档显示：价格 | 成交量 | 委托数
 * 成交量进度条从内向外扩展，直观表达相对力度
 */
@Composable
fun OrderBookView(
    orderBook: OrderBook?,
    modifier: Modifier = Modifier
) {
    if (orderBook == null) {
        Box(
            modifier = modifier
                .fillMaxWidth()
                .height(240.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "盘口数据加载中...",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }
        return
    }

    // Take top 5 levels for each side; asks displayed top-down (lowest ask at bottom = closest to spread)
    val displayBids = orderBook.bids.take(5)
    val displayAsks = orderBook.asks.take(5).reversed() // show best ask closest to spread

    if (displayBids.isEmpty() && displayAsks.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxWidth()
                .height(240.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "暂无盘口数据",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }
        return
    }

    // Max volume for scaling bars (across both sides so bars are comparable)
    val allVolumes = (displayBids + displayAsks).map { it.volume }
    val maxVolume = remember(allVolumes) { allVolumes.maxOrNull()?.toFloat() ?: 1f }

    // Spread calculation
    val bestBid = orderBook.bids.firstOrNull()
    val bestAsk = orderBook.asks.firstOrNull()
    val spreadText = if (bestBid != null && bestAsk != null) {
        try {
            val bid = bestBid.price.toDouble()
            val ask = bestAsk.price.toDouble()
            val spread = ask - bid
            val midpoint = (ask + bid) / 2.0
            val spreadPct = if (midpoint != 0.0) spread / midpoint * 100.0 else 0.0
            "价差: ${formatDecimal(spread, 4)}  (${formatDecimal(spreadPct, 3)}%)"
        } catch (_: NumberFormatException) {
            "价差: --"
        }
    } else {
        "价差: --"
    }

    Column(modifier = modifier.fillMaxWidth()) {
        // ── Column headers ────────────────────────────────────────────────
        OrderBookHeader()

        HorizontalDivider(color = BorderLight, thickness = 0.5.dp)

        Spacer(modifier = Modifier.height(4.dp))

        // ── Ask levels (卖盘) — shown top-down, worst ask first ───────────
        if (displayAsks.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "暂无卖盘", fontSize = 12.sp, color = TextSecondary)
            }
        } else {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "卖盘",
                    fontSize = 11.sp,
                    color = DangerRed,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                )
                displayAsks.forEach { level ->
                    OrderBookLevelRow(
                        level = level,
                        isBid = false,
                        maxVolume = maxVolume
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(6.dp))

        // ── Spread row ────────────────────────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(BackgroundLight)
                .padding(vertical = 6.dp, horizontal = 8.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = spreadText,
                fontSize = 11.sp,
                color = TextSecondary,
                textAlign = TextAlign.Center
            )
        }

        Spacer(modifier = Modifier.height(6.dp))

        // ── Bid levels (买盘) — shown top-down, best bid first ────────────
        if (displayBids.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "暂无买盘", fontSize = 12.sp, color = TextSecondary)
            }
        } else {
            Column(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = "买盘",
                    fontSize = 11.sp,
                    color = SuccessGreen,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                )
                displayBids.forEach { level ->
                    OrderBookLevelRow(
                        level = level,
                        isBid = true,
                        maxVolume = maxVolume
                    )
                }
            }
        }
    }
}

// ── Internal composables ──────────────────────────────────────────────────────

@Composable
private fun OrderBookHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        // Price column (left-aligned)
        Text(
            text = "价格",
            fontSize = 11.sp,
            color = TextSecondary,
            modifier = Modifier.weight(1.5f)
        )
        // Volume column (centre)
        Text(
            text = "数量",
            fontSize = 11.sp,
            color = TextSecondary,
            textAlign = TextAlign.Center,
            modifier = Modifier.weight(1.5f)
        )
        // Order count (right-aligned)
        Text(
            text = "委托数",
            fontSize = 11.sp,
            color = TextSecondary,
            textAlign = TextAlign.End,
            modifier = Modifier.weight(1f)
        )
    }
}

/**
 * A single order book level row with a coloured volume-bar background.
 */
@Composable
private fun OrderBookLevelRow(
    level: PriceLevel,
    isBid: Boolean,
    maxVolume: Float
) {
    val barColor = if (isBid) {
        SuccessGreen.copy(alpha = 0.15f)
    } else {
        DangerRed.copy(alpha = 0.15f)
    }
    val priceColor = if (isBid) SuccessGreen else DangerRed
    val volumeRatio = (level.volume.toFloat() / maxVolume).coerceIn(0f, 1f)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(26.dp)
    ) {
        // Volume bar — fills from the price side inward
        // Bids: bar grows from left; Asks: bar grows from right
        if (isBid) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(volumeRatio)
                    .height(26.dp)
                    .align(Alignment.CenterStart)
                    .background(barColor)
            )
        } else {
            Box(
                modifier = Modifier
                    .fillMaxWidth(volumeRatio)
                    .height(26.dp)
                    .align(Alignment.CenterEnd)
                    .background(barColor)
            )
        }

        // Text content on top of bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.Center)
                .padding(horizontal = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Price
            Text(
                text = level.price,
                fontSize = 12.sp,
                color = priceColor,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.weight(1.5f)
            )

            // Volume
            Text(
                text = formatVolume(level.volume),
                fontSize = 12.sp,
                color = TextPrimary,
                textAlign = TextAlign.Center,
                modifier = Modifier.weight(1.5f)
            )

            // Order count
            Text(
                text = if (level.orderCount > 0) level.orderCount.toString() else "--",
                fontSize = 12.sp,
                color = TextSecondary,
                textAlign = TextAlign.End,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

// ── Formatting helpers ────────────────────────────────────────────────────────

private fun formatVolume(volume: Long): String {
    return when {
        volume >= 100_000_000L -> "${formatDecimal(volume / 100_000_000.0)}亿"
        volume >= 10_000L -> "${formatDecimal(volume / 10_000.0)}万"
        else -> volume.toString()
    }
}
