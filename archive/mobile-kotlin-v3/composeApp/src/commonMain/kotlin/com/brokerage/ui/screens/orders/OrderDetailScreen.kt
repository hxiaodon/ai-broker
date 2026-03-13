package com.brokerage.ui.screens.orders
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.theme.*
import com.brokerage.ui.util.formatDecimal

/**
 * 订单详情页面
 */
@Composable
fun OrderDetailScreen(
    orderId: String,
    onBackClick: () -> Unit,
    onCancelOrder: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Mock 数据
    val order = remember {
        OrderDetail(
            orderId = orderId,
            symbol = "AAPL",
            name = "Apple Inc.",
            type = "限价单",
            side = "买入",
            status = "部分成交",
            price = 175.50,
            quantity = 100,
            filledQuantity = 60,
            avgPrice = 175.45,
            totalAmount = 17550.0,
            filledAmount = 10527.0,
            commission = 5.26,
            createTime = "2024-03-07 09:30:00",
            updateTime = "2024-03-07 09:35:12",
            validUntil = "2024-03-07 16:00:00"
        )
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // 顶部导航栏
        OrderDetailTopBar(
            orderId = orderId,
            onBackClick = onBackClick
        )

        // 内容区域
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium)
        ) {
            // 状态卡片
            StatusCard(order = order)

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 订单信息
            OrderInfoSection(order = order)

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 成交信息
            FilledInfoSection(order = order)

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 费用信息
            FeeInfoSection(order = order)

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 时间信息
            TimeInfoSection(order = order)
        }

        // 底部操作按钮
        if (order.status == "待成交" || order.status == "部分成交") {
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = Color.White,
                shadowElevation = 8.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium),
                    horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
                ) {
                    OutlinedButton(
                        onClick = { /* TODO: 修改订单 */ },
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("修改订单")
                    }

                    Button(
                        onClick = onCancelOrder,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = DangerRed
                        )
                    ) {
                        Text("撤销订单")
                    }
                }
            }
        }
    }
}

@Composable
private fun OrderDetailTopBar(
    orderId: String,
    onBackClick: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 1.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
                .padding(horizontal = Spacing.small),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = BrokerageIcons.ArrowBack,
                    contentDescription = "返回",
                    modifier = Modifier.size(24.dp)
                )
            }

            Text(
                text = "订单详情",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary,
                modifier = Modifier.weight(1f)
            )

            Text(
                text = "#$orderId",
                fontSize = 12.sp,
                color = TextSecondary
            )
        }
    }
}

@Composable
private fun StatusCard(order: OrderDetail) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(
            modifier = Modifier.padding(Spacing.medium),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // 状态图标
            Text(
                text = when (order.status) {
                    "待成交" -> "⏳"
                    "部分成交" -> "⏳"
                    "已成交" -> "✅"
                    "已撤销" -> "❌"
                    else -> "❓"
                },
                fontSize = 48.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            // 状态文本
            Text(
                text = order.status,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = when (order.status) {
                    "待成交" -> WarningOrange
                    "部分成交" -> InfoBlue
                    "已成交" -> SuccessGreen
                    "已撤销" -> TextSecondary
                    else -> TextPrimary
                }
            )

            Spacer(modifier = Modifier.height(4.dp))

            // 股票信息
            Text(
                text = "${order.side} ${order.symbol} ${order.name}",
                fontSize = 14.sp,
                color = TextSecondary
            )
        }
    }
}

@Composable
private fun OrderInfoSection(order: OrderDetail) {
    InfoCard(title = "订单信息") {
        InfoRow(label = "订单类型", value = order.type)
        InfoRow(label = "买卖方向", value = order.side, valueColor = if (order.side == "买入") SuccessGreen else DangerRed)
        InfoRow(label = "委托价格", value = "$${order.price}")
        InfoRow(label = "委托数量", value = "${order.quantity} 股")
        InfoRow(label = "委托金额", value = "$${formatDecimal(order.totalAmount)}")
    }
}

@Composable
private fun FilledInfoSection(order: OrderDetail) {
    InfoCard(title = "成交信息") {
        InfoRow(
            label = "成交数量",
            value = "${order.filledQuantity} / ${order.quantity} 股",
            valueColor = if (order.filledQuantity > 0) SuccessGreen else TextPrimary
        )
        if (order.filledQuantity > 0) {
            InfoRow(label = "成交均价", value = "$${order.avgPrice}")
            InfoRow(label = "成交金额", value = "$${formatDecimal(order.filledAmount)}")
        }
    }
}

@Composable
private fun FeeInfoSection(order: OrderDetail) {
    InfoCard(title = "费用信息") {
        InfoRow(label = "佣金", value = "$${formatDecimal(order.commission)}")
        InfoRow(label = "平台费", value = "$0.00")
        InfoRow(label = "总费用", value = "$${formatDecimal(order.commission)}", valueColor = DangerRed)
    }
}

@Composable
private fun TimeInfoSection(order: OrderDetail) {
    InfoCard(title = "时间信息") {
        InfoRow(label = "创建时间", value = order.createTime)
        InfoRow(label = "更新时间", value = order.updateTime)
        if (order.status == "待成交" || order.status == "部分成交") {
            InfoRow(label = "有效期至", value = order.validUntil, valueColor = WarningOrange)
        }
    }
}

@Composable
private fun InfoCard(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shape = MaterialTheme.shapes.medium
    ) {
        Column(modifier = Modifier.padding(Spacing.medium)) {
            Text(
                text = title,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            content()
        }
    }
}

@Composable
private fun InfoRow(
    label: String,
    value: String,
    valueColor: Color = TextPrimary
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 6.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            fontSize = 14.sp,
            color = TextSecondary
        )

        Text(
            text = value,
            fontSize = 14.sp,
            color = valueColor,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * 订单详情数据模型
 */
data class OrderDetail(
    val orderId: String,
    val symbol: String,
    val name: String,
    val type: String,
    val side: String,
    val status: String,
    val price: Double,
    val quantity: Int,
    val filledQuantity: Int,
    val avgPrice: Double,
    val totalAmount: Double,
    val filledAmount: Double,
    val commission: Double,
    val createTime: String,
    val updateTime: String,
    val validUntil: String
)
