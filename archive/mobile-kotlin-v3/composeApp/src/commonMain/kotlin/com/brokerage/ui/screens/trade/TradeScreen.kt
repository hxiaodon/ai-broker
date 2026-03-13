package com.brokerage.ui.screens.trade
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.core.biometric.BiometricAuth
import com.brokerage.core.biometric.BiometricResult
import com.brokerage.ui.components.*
import com.brokerage.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.datetime.Clock
import kotlin.math.pow
import kotlin.math.roundToLong

private fun Double.fmt2(): String {
    val factor = 100.0
    val rounded = (this * factor).roundToLong().toDouble() / factor
    val intPart = rounded.toLong()
    val fracPart = ((rounded - intPart) * factor).roundToLong()
    return "$intPart.${fracPart.toString().padStart(2, '0')}"
}

private fun Double.fmt0(): String = this.roundToLong().toString()

/**
 * Trade screen - order placement
 * Based on trade.html prototype and mobile-app-design-v2.md
 *
 * Security features (v2.0):
 * - Slide-to-confirm button (replaces regular button)
 * - Biometric authentication (Face ID/Touch ID/Fingerprint)
 * - 2-second debounce protection
 * - PDT rule enforcement (blocks 4th day trade)
 * - Large order confirmation dialog (>$10,000)
 * - Best execution disclosure
 */
@Composable
fun TradeScreen(
    symbol: String,
    isBuy: Boolean,
    onBackClick: () -> Unit,
    onSubmitOrder: () -> Unit,
    modifier: Modifier = Modifier,
    biometricAuth: BiometricAuth? = null
) {
    var orderType by remember { mutableStateOf(OrderType.MARKET) }
    var price by remember { mutableStateOf("175.00") }
    var quantity by remember { mutableStateOf("100") }

    // Security state
    var isSubmitting by remember { mutableStateOf(false) }
    var lastSubmitTime by remember { mutableStateOf(0L) }
    var showLargeOrderDialog by remember { mutableStateOf(false) }
    var showPdtBlockDialog by remember { mutableStateOf(false) }
    var showBestExecutionDialog by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    val scope = rememberCoroutineScope()

    // Mock data - in real app, fetch from backend
    val currentPrice = 175.23
    val availableFunds = 10000.0
    val commission = 5.0
    val dayTradesThisWeek = 3 // Mock: user has made 3 day trades this week
    val accountEquity = 15340.0 // Mock: total account value
    val isPdtAccount = accountEquity < 25000.0 // PDT rule applies if < $25k

    val estimatedCost = (price.toDoubleOrNull() ?: currentPrice) * (quantity.toIntOrNull() ?: 0)
    val totalCost = estimatedCost + commission
    val positionRatio = (totalCost / (availableFunds + accountEquity)) * 100

    // PDT check: block 4th day trade if account < $25k
    val isPdtBlocked = isPdtAccount && dayTradesThisWeek >= 3
    val isLargeOrder = totalCost > 10000.0

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        // Top bar
        AppTopBar(
            title = "${if (isBuy) "买入" else "卖出"} $symbol",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium)
        ) {
            // Current price and available funds
            PriceInfoCard(
                currentPrice = currentPrice,
                availableFunds = availableFunds
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Order type tabs
            OrderTypeTabs(
                selectedType = orderType,
                onTypeSelected = { orderType = it }
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Price input (for limit orders)
            if (orderType == OrderType.LIMIT || orderType == OrderType.STOP) {
                NumberTextField(
                    value = price,
                    onValueChange = { price = it },
                    label = if (orderType == OrderType.LIMIT) "限价" else "止损价",
                    placeholder = "0.00",
                    suffix = "$"
                )
                Spacer(modifier = Modifier.height(Spacing.medium))
            }

            // Quantity input
            NumberTextField(
                value = quantity,
                onValueChange = { quantity = it },
                label = "数量",
                placeholder = "0",
                suffix = "股"
            )

            Spacer(modifier = Modifier.height(Spacing.small))

            // Quick quantity buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                QuickQuantityButton(
                    text = "10",
                    onClick = { quantity = "10" },
                    modifier = Modifier.weight(1f)
                )
                QuickQuantityButton(
                    text = "50",
                    onClick = { quantity = "50" },
                    modifier = Modifier.weight(1f)
                )
                QuickQuantityButton(
                    text = "100",
                    onClick = { quantity = "100" },
                    modifier = Modifier.weight(1f)
                )
                QuickQuantityButton(
                    text = "全部",
                    onClick = {
                        val maxQty = (availableFunds / currentPrice).toInt()
                        quantity = maxQty.toString()
                    },
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Cost summary
            CostSummaryCard(
                estimatedCost = estimatedCost,
                commission = commission,
                totalCost = totalCost,
                positionRatio = positionRatio
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Risk warning
            if (totalCost > availableFunds || positionRatio > 20) {
                RiskWarningCard(
                    insufficientFunds = totalCost > availableFunds,
                    highRatio = positionRatio > 20,
                    isLimitOrder = orderType == OrderType.LIMIT
                )
                Spacer(modifier = Modifier.height(Spacing.medium))
            }

            // PDT warning (if approaching limit)
            if (isPdtAccount && dayTradesThisWeek >= 2 && !isPdtBlocked) {
                PdtWarningCard(dayTradesRemaining = 3 - dayTradesThisWeek)
                Spacer(modifier = Modifier.height(Spacing.medium))
            }

            // Error message
            errorMessage?.let { error ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(containerColor = Error.copy(alpha = 0.1f))
                ) {
                    Text(
                        text = error,
                        fontSize = 14.sp,
                        color = Error,
                        modifier = Modifier.padding(Spacing.medium)
                    )
                }
                Spacer(modifier = Modifier.height(Spacing.medium))
            }
        }

        // Slide-to-confirm button (v2.0 security feature)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            contentAlignment = Alignment.Center
        ) {
            val canSubmit = totalCost <= availableFunds && !isSubmitting && !isPdtBlocked

            SlideToConfirmButton(
                text = if (isBuy) "滑动确认买入 →" else "滑动确认卖出 →",
                onConfirm = {
                    scope.launch {
                        handleOrderSubmission(
                            isBuy = isBuy,
                            isLargeOrder = isLargeOrder,
                            biometricAuth = biometricAuth,
                            onShowLargeOrderDialog = { showLargeOrderDialog = true },
                            onShowBestExecutionDialog = { showBestExecutionDialog = true },
                            onError = { errorMessage = it },
                            onSuccess = {
                                isSubmitting = true
                                lastSubmitTime = Clock.System.now().toEpochMilliseconds()
                                onSubmitOrder()
                            },
                            isSubmitting = isSubmitting,
                            lastSubmitTime = lastSubmitTime
                        )
                    }
                },
                enabled = canSubmit,
                backgroundColor = if (isBuy) SuccessGreen else DangerRed
            )
        }
    }

    // Large order confirmation dialog
    if (showLargeOrderDialog) {
        LargeOrderConfirmDialog(
            amount = totalCost,
            onConfirm = {
                showLargeOrderDialog = false
                showBestExecutionDialog = true
            },
            onDismiss = {
                showLargeOrderDialog = false
                isSubmitting = false
            }
        )
    }

    // Best execution disclosure dialog
    if (showBestExecutionDialog) {
        BestExecutionDialog(
            onConfirm = {
                showBestExecutionDialog = false
                // Proceed to biometric auth
                scope.launch {
                    performBiometricAuth(
                        biometricAuth = biometricAuth,
                        isBuy = isBuy,
                        onSuccess = {
                            isSubmitting = true
                            lastSubmitTime = Clock.System.now().toEpochMilliseconds()
                            onSubmitOrder()
                        },
                        onError = { errorMessage = it }
                    )
                }
            },
            onDismiss = {
                showBestExecutionDialog = false
                isSubmitting = false
            }
        )
    }

    // PDT block dialog
    if (showPdtBlockDialog) {
        PdtBlockDialog(
            onDismiss = { showPdtBlockDialog = false }
        )
    }
}

/**
 * Handle order submission with security checks
 */
private suspend fun handleOrderSubmission(
    isBuy: Boolean,
    isLargeOrder: Boolean,
    biometricAuth: BiometricAuth?,
    onShowLargeOrderDialog: () -> Unit,
    onShowBestExecutionDialog: () -> Unit,
    onError: (String) -> Unit,
    onSuccess: () -> Unit,
    isSubmitting: Boolean,
    lastSubmitTime: Long
) {
    // 1. Debounce check (2-second protection)
    val currentTime = Clock.System.now().toEpochMilliseconds()
    if (currentTime - lastSubmitTime < 2000) {
        onError("请勿频繁提交订单")
        return
    }

    if (isSubmitting) {
        onError("订单提交中，请稍候")
        return
    }

    // 2. Large order check (>$10,000)
    if (isLargeOrder) {
        onShowLargeOrderDialog()
        return
    }

    // 3. Best execution disclosure
    onShowBestExecutionDialog()
}

/**
 * Perform biometric authentication
 */
private suspend fun performBiometricAuth(
    biometricAuth: BiometricAuth?,
    isBuy: Boolean,
    onSuccess: () -> Unit,
    onError: (String) -> Unit
) {
    if (biometricAuth == null) {
        onError("生物识别不可用")
        return
    }

    val result = biometricAuth.authenticate(
        title = if (isBuy) "确认买入" else "确认卖出",
        subtitle = "请验证您的身份以提交订单"
    )

    when (result) {
        is BiometricResult.Success -> onSuccess()
        is BiometricResult.Cancelled -> onError("已取消身份验证")
        is BiometricResult.Failed -> onError("身份验证失败: ${result.reason}")
        is BiometricResult.NotAvailable -> onError("生物识别不可用: ${result.reason}")
        is BiometricResult.Error -> onError("验证错误: ${result.message}")
    }
}

/**
 * Price info card
 */
@Composable
private fun PriceInfoCard(
    currentPrice: Double,
    availableFunds: Double
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = Primary.copy(alpha = 0.1f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "当前价格",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Text(
                    text = "$${currentPrice.fmt2()}",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "可用资金",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Text(
                    text = "$${availableFunds.fmt2()}",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimaryLight
                )
            }
        }
    }
}

/**
 * Order type tabs
 */
@Composable
private fun OrderTypeTabs(
    selectedType: OrderType,
    onTypeSelected: (OrderType) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(BackgroundLight, RoundedCornerShape(CornerRadius.medium))
            .padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        OrderType.values().forEach { type ->
            val isSelected = selectedType == type
            Button(
                onClick = { onTypeSelected(type) },
                modifier = Modifier.weight(1f).height(40.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isSelected) Color.White else Color.Transparent,
                    contentColor = if (isSelected) TextPrimaryLight else TextSecondaryLight
                ),
                elevation = ButtonDefaults.buttonElevation(
                    defaultElevation = if (isSelected) 2.dp else 0.dp
                ),
                shape = RoundedCornerShape(CornerRadius.small)
            ) {
                Text(
                    text = type.displayName,
                    fontSize = 14.sp,
                    fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
                )
            }
        }
    }
}

/**
 * Quick quantity button
 */
@Composable
private fun QuickQuantityButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier.height(40.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = BackgroundLight,
            contentColor = TextPrimaryLight
        ),
        elevation = ButtonDefaults.buttonElevation(defaultElevation = 0.dp),
        shape = RoundedCornerShape(CornerRadius.medium)
    ) {
        Text(
            text = text,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

/**
 * Cost summary card
 */
@Composable
private fun CostSummaryCard(
    estimatedCost: Double,
    commission: Double,
    totalCost: Double,
    positionRatio: Double
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = BackgroundLight
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "预估成本",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Text(
                    text = "$${estimatedCost.fmt2()}",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimaryLight
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "手续费",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Text(
                    text = "$${commission.fmt2()}",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimaryLight
                )
            }
            HorizontalDivider(
                modifier = Modifier.padding(vertical = 8.dp),
                color = BorderLight
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "合计",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimaryLight
                )
                Text(
                    text = "$${totalCost.fmt2()}",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimaryLight
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "买入后持仓占比",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Text(
                    text = "${positionRatio.fmt0()}%",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (positionRatio > 20) Warning else TextPrimaryLight
                )
            }
        }
    }
}

/**
 * Risk warning card
 */
@Composable
private fun RiskWarningCard(
    insufficientFunds: Boolean,
    highRatio: Boolean,
    isLimitOrder: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = Warning.copy(alpha = 0.1f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            Icon(
                imageVector = BrokerageIcons.Warning,
                contentDescription = null,
                tint = Warning,
                modifier = Modifier.size(20.dp).padding(end = 8.dp)
            )
            Column {
                Text(
                    text = "风险提示",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Warning
                )
                Spacer(modifier = Modifier.height(4.dp))
                Column(
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    if (insufficientFunds) {
                        Text(
                            text = "• 可用资金不足",
                            fontSize = 11.sp,
                            color = TextSecondaryLight
                        )
                    }
                    if (highRatio) {
                        Text(
                            text = "• 持仓占比过高（建议不超过 20%）",
                            fontSize = 11.sp,
                            color = TextSecondaryLight
                        )
                    }
                    if (isLimitOrder) {
                        Text(
                            text = "• 限价单可能无法成交",
                            fontSize = 11.sp,
                            color = TextSecondaryLight
                        )
                    }
                    Text(
                        text = "• 市场波动风险",
                        fontSize = 11.sp,
                        color = TextSecondaryLight
                    )
                }
            }
        }
    }
}

/**
 * Order type enum
 */
enum class OrderType(val displayName: String) {
    MARKET("市价单"),
    LIMIT("限价单"),
    STOP("止损单")
}

/**
 * PDT warning card
 */
@Composable
private fun PdtWarningCard(dayTradesRemaining: Int) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = Warning.copy(alpha = 0.1f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                imageVector = BrokerageIcons.Warning,
                contentDescription = null,
                tint = Warning,
                modifier = Modifier.size(20.dp).padding(end = 8.dp)
            )
            Column {
                Text(
                    text = "PDT 规则提醒",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Warning
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "您的账户资金少于 $25,000，本周还可进行 $dayTradesRemaining 次日内交易。超过限制将被标记为 Pattern Day Trader，需维持 $25,000 最低资金。",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }
        }
    }
}

/**
 * Large order confirmation dialog
 */
@Composable
private fun LargeOrderConfirmDialog(
    amount: Double,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "大额订单确认",
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                Text(
                    text = "您即将提交一笔大额订单：",
                    fontSize = 14.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "$${amount.fmt2()}",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "请确认订单信息无误后继续。",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }
        },
        confirmButton = {
            Button(onClick = onConfirm) {
                Text("确认")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

/**
 * Best execution disclosure dialog
 */
@Composable
private fun BestExecutionDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "最佳执行披露",
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            Column {
                Text(
                    text = "根据 SEC Reg NMS 规定，我们承诺为您的订单寻求最佳执行价格。",
                    fontSize = 14.sp
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "• 订单将被路由至提供最佳价格的交易所\n• 市价单可能存在滑点\n• 限价单以您指定的价格或更优价格执行",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "点击确认表示您已阅读并理解上述内容。",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }
        },
        confirmButton = {
            Button(onClick = onConfirm) {
                Text("我已理解")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

/**
 * PDT block dialog
 */
@Composable
private fun PdtBlockDialog(
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "无法提交订单",
                fontWeight = FontWeight.Bold,
                color = Error
            )
        },
        text = {
            Column {
                Text(
                    text = "您已达到本周日内交易次数上限（3次）。",
                    fontSize = 14.sp
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "根据 FINRA Pattern Day Trader (PDT) 规则，账户资金少于 $25,000 的投资者每周最多只能进行 3 次日内交易。",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "解决方案：\n• 等待下周重置\n• 将账户资金充值至 $25,000 以上\n• 持仓过夜（非日内交易）",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }
        },
        confirmButton = {
            Button(onClick = onDismiss) {
                Text("我知道了")
            }
        }
    )
}
