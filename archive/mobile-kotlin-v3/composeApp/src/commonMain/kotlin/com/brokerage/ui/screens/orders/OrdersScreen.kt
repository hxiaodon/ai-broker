package com.brokerage.ui.screens.orders

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.components.*
import com.brokerage.ui.theme.*

/**
 * Orders screen - displays order list with status tabs
 * Based on orders.html prototype
 */
@Composable
fun OrdersScreen(
    onOrderClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("全部", "待成交", "已成交", "已撤销")

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // Top bar
        OrdersTopBar()

        // Tab row
        AppTabRow(
            selectedTabIndex = selectedTab,
            tabs = tabs,
            onTabSelected = { selectedTab = it }
        )

        HorizontalDivider(color = BorderLight, thickness = 1.dp)

        // Order list
        OrderList(
            orders = getFilteredOrders(selectedTab),
            onOrderClick = onOrderClick,
            onEditClick = { /* TODO */ },
            onCancelClick = { /* TODO */ },
            modifier = Modifier.weight(1f)
        )
    }
}

/**
 * Top bar
 */
@Composable
private fun OrdersTopBar() {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .padding(horizontal = Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "订单",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimaryLight
            )
        }
    }
}

/**
 * Order list component
 */
@Composable
private fun OrderList(
    orders: List<OrderItem>,
    onOrderClick: (String) -> Unit,
    onEditClick: (String) -> Unit,
    onCancelClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize()
    ) {
        items(orders) { order ->
            OrderListItem(
                order = order,
                onClick = { onOrderClick(order.id) },
                onEditClick = { onEditClick(order.id) },
                onCancelClick = { onCancelClick(order.id) }
            )
            HorizontalDivider(color = DividerLight, thickness = 1.dp)
        }
    }
}

/**
 * Single order list item
 */
@Composable
private fun OrderListItem(
    order: OrderItem,
    onClick: () -> Unit,
    onEditClick: () -> Unit,
    onCancelClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = Color.White,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            // Header: Symbol/Action and Status
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column {
                    Text(
                        text = "${order.symbol} ${if (order.isBuy) "买入" else "卖出"} ${order.quantity}股",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimaryLight
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = order.priceType,
                        fontSize = 12.sp,
                        color = TextSecondaryLight
                    )
                }

                OrderStatusBadge(status = order.status)
            }

            // Fill info (if applicable)
            if (order.fillInfo != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = order.fillInfo,
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Footer: Time and Actions
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = order.time,
                    fontSize = 11.sp,
                    color = TextTertiaryLight
                )

                // Action buttons (only for pending/partial orders)
                if (order.status == OrderStatus.PENDING || order.status == OrderStatus.PARTIAL) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        TextButton(
                            onClick = { onEditClick() },
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.textButtonColors(
                                contentColor = Primary
                            )
                        ) {
                            Text(
                                text = "修改",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        TextButton(
                            onClick = { onCancelClick() },
                            modifier = Modifier.height(32.dp),
                            colors = ButtonDefaults.textButtonColors(
                                contentColor = Error
                            )
                        ) {
                            Text(
                                text = "撤单",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Order status badge
 */
@Composable
private fun OrderStatusBadge(status: OrderStatus) {
    val (bgColor, textColor, text) = when (status) {
        OrderStatus.PENDING -> Triple(
            Primary.copy(alpha = 0.1f),
            Primary,
            "待成交"
        )
        OrderStatus.PARTIAL -> Triple(
            Warning.copy(alpha = 0.1f),
            Warning,
            "部分成交"
        )
        OrderStatus.FILLED -> Triple(
            Success.copy(alpha = 0.1f),
            Success,
            "已成交"
        )
        OrderStatus.CANCELLED -> Triple(
            TextSecondaryLight.copy(alpha = 0.1f),
            TextSecondaryLight,
            "已撤销"
        )
    }

    Surface(
        shape = MaterialTheme.shapes.small,
        color = bgColor,
        modifier = Modifier.padding(0.dp)
    ) {
        Text(
            text = text,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = textColor,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

/**
 * Order status enum
 */
enum class OrderStatus {
    PENDING,    // 待成交
    PARTIAL,    // 部分成交
    FILLED,     // 已成交
    CANCELLED   // 已撤销
}

/**
 * Order data model
 */
data class OrderItem(
    val id: String,
    val symbol: String,
    val isBuy: Boolean,
    val quantity: Int,
    val priceType: String,      // "限价 $175.00" or "市价单"
    val status: OrderStatus,
    val fillInfo: String?,      // "已成交 50/100 股 @ $175.10"
    val time: String
)

/**
 * Get filtered orders by tab
 */
private fun getFilteredOrders(tabIndex: Int): List<OrderItem> {
    val allOrders = getSampleOrders()
    return when (tabIndex) {
        0 -> allOrders // 全部
        1 -> allOrders.filter { it.status == OrderStatus.PENDING || it.status == OrderStatus.PARTIAL } // 待成交
        2 -> allOrders.filter { it.status == OrderStatus.FILLED } // 已成交
        3 -> allOrders.filter { it.status == OrderStatus.CANCELLED } // 已撤销
        else -> allOrders
    }
}

/**
 * Sample order data (from HTML prototype)
 */
internal fun getSampleOrders(): List<OrderItem> {
    return listOf(
        OrderItem(
            id = "1",
            symbol = "AAPL",
            isBuy = true,
            quantity = 100,
            priceType = "限价 $175.00",
            status = OrderStatus.PARTIAL,
            fillInfo = "已成交 50/100 股 @ $175.10",
            time = "2026-03-07 09:35"
        ),
        OrderItem(
            id = "2",
            symbol = "TSLA",
            isBuy = false,
            quantity = 50,
            priceType = "市价单",
            status = OrderStatus.FILLED,
            fillInfo = "成交价 $245.50 | 手续费 $5.00",
            time = "2026-03-07 09:30"
        ),
        OrderItem(
            id = "3",
            symbol = "MSFT",
            isBuy = true,
            quantity = 30,
            priceType = "限价 $380.00",
            status = OrderStatus.PENDING,
            fillInfo = null,
            time = "2026-03-07 09:20"
        ),
        OrderItem(
            id = "4",
            symbol = "GOOGL",
            isBuy = true,
            quantity = 20,
            priceType = "限价 $145.00",
            status = OrderStatus.CANCELLED,
            fillInfo = null,
            time = "2026-03-07 09:10"
        )
    )
}
