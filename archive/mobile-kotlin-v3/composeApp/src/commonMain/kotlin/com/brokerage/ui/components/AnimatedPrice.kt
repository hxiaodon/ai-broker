package com.brokerage.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.common.decimal.BigDecimal
import com.brokerage.ui.theme.*
import kotlinx.coroutines.delay

/**
 * 价格闪烁动画组件
 * 当价格变化时显示闪烁效果
 */
@Composable
fun AnimatedPrice(
    price: BigDecimal,
    previousPrice: BigDecimal?,
    modifier: Modifier = Modifier,
    fontSize: Int = 32,
    fontWeight: FontWeight = FontWeight.Bold
) {
    var shouldAnimate by remember { mutableStateOf(false) }
    val priceChange = remember(price, previousPrice) {
        if (previousPrice != null && price != previousPrice) {
            when {
                price > previousPrice -> PriceChange.UP
                price < previousPrice -> PriceChange.DOWN
                else -> PriceChange.NONE
            }
        } else {
            PriceChange.NONE
        }
    }

    // 触发动画
    LaunchedEffect(price) {
        if (previousPrice != null && price != previousPrice) {
            shouldAnimate = true
            delay(500)
            shouldAnimate = false
        }
    }

    // 闪烁动画
    val alpha by animateFloatAsState(
        targetValue = if (shouldAnimate) 1f else 0f,
        animationSpec = tween(durationMillis = 500, easing = FastOutSlowInEasing),
        label = "price_flash"
    )

    Box(modifier = modifier) {
        // 背景闪烁层
        if (shouldAnimate) {
            Box(
                modifier = Modifier
                    .matchParentSize()
                    .graphicsLayer { this.alpha = alpha }
                    .background(
                        when (priceChange) {
                            PriceChange.UP -> SuccessGreen.copy(alpha = 0.2f)
                            PriceChange.DOWN -> DangerRed.copy(alpha = 0.2f)
                            PriceChange.NONE -> Color.Transparent
                        }
                    )
            )
        }

        // 价格文本
        Text(
            text = price.toPlainString(),
            fontSize = fontSize.sp,
            fontWeight = fontWeight,
            color = when (priceChange) {
                PriceChange.UP -> SuccessGreen
                PriceChange.DOWN -> DangerRed
                PriceChange.NONE -> TextPrimary
            },
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

/**
 * 涨跌图标组件
 */
@Composable
fun PriceChangeIcon(
    change: BigDecimal,
    modifier: Modifier = Modifier,
    size: Int = 16
) {
    val isUp = change >= BigDecimal.ZERO
    val icon = if (isUp) "▲" else "▼"
    val color = if (isUp) SuccessGreen else DangerRed

    Text(
        text = icon,
        fontSize = size.sp,
        color = color,
        modifier = modifier
    )
}

/**
 * 涨跌幅度显示（带图标）
 */
@Composable
fun PriceChangeWithIcon(
    change: BigDecimal,
    changePercent: BigDecimal,
    modifier: Modifier = Modifier
) {
    val isUp = change >= BigDecimal.ZERO

    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        PriceChangeIcon(change = change, size = 12)

        Text(
            text = "${if (isUp) "+" else ""}${change.toPlainString()}",
            fontSize = 16.sp,
            color = if (isUp) SuccessGreen else DangerRed,
            fontWeight = FontWeight.Medium
        )

        Text(
            text = "(${if (isUp) "+" else ""}${changePercent.toPlainString()}%)",
            fontSize = 14.sp,
            color = if (isUp) SuccessGreen else DangerRed
        )
    }
}

/**
 * 价格变化方向
 */
enum class PriceChange {
    UP, DOWN, NONE
}
