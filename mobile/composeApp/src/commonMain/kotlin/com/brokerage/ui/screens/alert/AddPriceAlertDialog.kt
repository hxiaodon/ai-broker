package com.brokerage.ui.screens.alert

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.brokerage.common.decimal.BigDecimal
import com.brokerage.domain.alert.AlertCondition
import com.brokerage.ui.accessibility.accessibilityLabel
import com.brokerage.ui.theme.*

/**
 * 添加价格提醒对话框
 */
@Composable
fun AddPriceAlertDialog(
    symbol: String,
    stockName: String,
    currentPrice: BigDecimal,
    onDismiss: () -> Unit,
    onConfirm: (BigDecimal, AlertCondition) -> Unit
) {
    var targetPrice by remember { mutableStateOf("") }
    var selectedCondition by remember { mutableStateOf(AlertCondition.ABOVE) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            shape = MaterialTheme.shapes.large,
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp)
            ) {
                // 标题
                Text(
                    text = "设置价格提醒",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )

                Spacer(modifier = Modifier.height(16.dp))

                // 股票信息
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = symbol,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                    Text(
                        text = stockName,
                        fontSize = 14.sp,
                        color = TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // 当前价格
                Text(
                    text = "当前价格: ${currentPrice.toPlainString()}",
                    fontSize = 14.sp,
                    color = TextSecondary
                )

                Spacer(modifier = Modifier.height(16.dp))

                // 提醒条件选择
                Text(
                    text = "提醒条件",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimary
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    AlertConditionChip(
                        label = "高于",
                        selected = selectedCondition == AlertCondition.ABOVE,
                        onClick = { selectedCondition = AlertCondition.ABOVE },
                        modifier = Modifier.weight(1f)
                    )
                    AlertConditionChip(
                        label = "低于",
                        selected = selectedCondition == AlertCondition.BELOW,
                        onClick = { selectedCondition = AlertCondition.BELOW },
                        modifier = Modifier.weight(1f)
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // 目标价格输入
                OutlinedTextField(
                    value = targetPrice,
                    onValueChange = {
                        targetPrice = it
                        errorMessage = null
                    },
                    label = { Text("目标价格") },
                    placeholder = { Text("请输入目标价格") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    isError = errorMessage != null
                )

                if (errorMessage != null) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = errorMessage!!,
                        fontSize = 12.sp,
                        color = DangerRed
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // 按钮
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text("取消")
                    }

                    Button(
                        onClick = {
                            val price = targetPrice.toDoubleOrNull()
                            when {
                                price == null -> {
                                    errorMessage = "请输入有效的价格"
                                }
                                price <= 0 -> {
                                    errorMessage = "价格必须大于0"
                                }
                                selectedCondition == AlertCondition.ABOVE && price <= currentPrice.toDouble() -> {
                                    errorMessage = "目标价格应高于当前价格"
                                }
                                selectedCondition == AlertCondition.BELOW && price >= currentPrice.toDouble() -> {
                                    errorMessage = "目标价格应低于当前价格"
                                }
                                else -> {
                                    onConfirm(BigDecimal(targetPrice), selectedCondition)
                                }
                            }
                        },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryBlue)
                    ) {
                        Text("确定")
                    }
                }
            }
        }
    }
}

@Composable
private fun AlertConditionChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val accessibilityLabel = if (selected) {
        "$label，已选中"
    } else {
        "$label，未选中"
    }

    Surface(
        onClick = onClick,
        modifier = modifier.accessibilityLabel(accessibilityLabel),
        color = if (selected) PrimaryBlue else MaterialTheme.colorScheme.surface,
        shape = MaterialTheme.shapes.medium,
        border = if (!selected) ButtonDefaults.outlinedButtonBorder else null
    ) {
        Text(
            text = label,
            fontSize = 14.sp,
            fontWeight = if (selected) FontWeight.Medium else FontWeight.Normal,
            color = if (selected) MaterialTheme.colorScheme.onPrimary else TextPrimary,
            modifier = Modifier.padding(vertical = 12.dp),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )
    }
}
