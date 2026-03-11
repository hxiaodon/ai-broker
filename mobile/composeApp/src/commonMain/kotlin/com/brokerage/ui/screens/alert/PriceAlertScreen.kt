package com.brokerage.ui.screens.alert
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import com.brokerage.domain.alert.AlertCondition
import com.brokerage.domain.alert.PriceAlert
import com.brokerage.ui.theme.*

/**
 * 价格提醒管理页面
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PriceAlertScreen(
    onBackClick: () -> Unit,
    onAddAlertClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // 模拟数据
    var alerts by remember {
        mutableStateOf(
            listOf(
                PriceAlert(
                    id = "1",
                    symbol = "AAPL",
                    stockName = "苹果",
                    targetPrice = com.brokerage.common.decimal.BigDecimal("180.00"),
                    condition = AlertCondition.ABOVE,
                    isEnabled = true
                ),
                PriceAlert(
                    id = "2",
                    symbol = "TSLA",
                    stockName = "特斯拉",
                    targetPrice = com.brokerage.common.decimal.BigDecimal("200.00"),
                    condition = AlertCondition.BELOW,
                    isEnabled = false
                )
            )
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("价格提醒") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = BrokerageIcons.ArrowBack,
                            contentDescription = "返回"
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onAddAlertClick,
                containerColor = PrimaryBlue
            ) {
                Icon(
                    imageVector = BrokerageIcons.Add,
                    contentDescription = "添加提醒",
                    tint = Color.White
                )
            }
        }
    ) { paddingValues ->
        if (alerts.isEmpty()) {
            EmptyAlertView(
                onAddClick = onAddAlertClick,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            )
        } else {
            LazyColumn(
                modifier = modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                contentPadding = PaddingValues(vertical = Spacing.medium)
            ) {
                items(alerts) { alert ->
                    PriceAlertItem(
                        alert = alert,
                        onToggle = { enabled ->
                            alerts = alerts.map {
                                if (it.id == alert.id) it.copy(isEnabled = enabled) else it
                            }
                        },
                        onDelete = {
                            alerts = alerts.filter { it.id != alert.id }
                        }
                    )
                    HorizontalDivider(color = BorderLight)
                }
            }
        }
    }
}

/**
 * 价格提醒列表项
 */
@Composable
private fun PriceAlertItem(
    alert: PriceAlert,
    onToggle: (Boolean) -> Unit,
    onDelete: () -> Unit
) {
    Surface(
        color = Color.White,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                // 股票信息
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = alert.symbol,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                    Text(
                        text = alert.stockName,
                        fontSize = 14.sp,
                        color = TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // 提醒条件
                Row(
                    horizontalArrangement = Arrangement.spacedBy(4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = when (alert.condition) {
                            AlertCondition.ABOVE -> "价格高于"
                            AlertCondition.BELOW -> "价格低于"
                            AlertCondition.CHANGE_UP -> "涨幅超过"
                            AlertCondition.CHANGE_DOWN -> "跌幅超过"
                        },
                        fontSize = 14.sp,
                        color = TextSecondary
                    )
                    Text(
                        text = alert.targetPrice.toPlainString(),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium,
                        color = when (alert.condition) {
                            AlertCondition.ABOVE, AlertCondition.CHANGE_UP -> SuccessGreen
                            AlertCondition.BELOW, AlertCondition.CHANGE_DOWN -> DangerRed
                        }
                    )
                }

                // 触发状态
                if (alert.isTriggered) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "已触发",
                        fontSize = 12.sp,
                        color = WarningOrange
                    )
                }
            }

            // 开关和删除按钮
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Switch(
                    checked = alert.isEnabled,
                    onCheckedChange = onToggle,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = PrimaryBlue
                    )
                )

                IconButton(onClick = onDelete) {
                    Icon(
                        imageVector = BrokerageIcons.Delete,
                        contentDescription = "删除",
                        tint = TextSecondary
                    )
                }
            }
        }
    }
}

/**
 * 空状态视图
 */
@Composable
private fun EmptyAlertView(
    onAddClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
            .padding(Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            BrokerageIcons.Notifications,
            contentDescription = "通知",
            modifier = Modifier.size(64.dp)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "暂无价格提醒",
            fontSize = 18.sp,
            fontWeight = FontWeight.Medium,
            color = TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "设置价格提醒，及时把握交易机会",
            fontSize = 14.sp,
            color = TextSecondary
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(
            onClick = onAddClick,
            colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
        ) {
            Icon(
                imageVector = BrokerageIcons.Add,
                contentDescription = null,
                tint = Color.White
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text("添加提醒", color = Color.White)
        }
    }
}
