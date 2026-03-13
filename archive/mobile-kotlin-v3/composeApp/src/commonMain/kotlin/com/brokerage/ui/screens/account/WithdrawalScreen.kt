package com.brokerage.ui.screens.account
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
import com.brokerage.ui.util.formatDecimal
import kotlinx.coroutines.launch

/**
 * Withdrawal screen with compliance features
 *
 * Compliance (fund-transfer-compliance.md):
 * - Same-name account verification (Rule 1)
 * - AML screening (Rule 2)
 * - Settlement-aware withdrawal (Rule 4)
 * - Approval workflow (Rule 5)
 * - Biometric authentication required
 */
@Composable
fun WithdrawalScreen(
    withdrawableFunds: Double,
    onBackClick: () -> Unit,
    onSubmitWithdrawal: (amount: Double, bankCardId: String) -> Unit,
    modifier: Modifier = Modifier,
    biometricAuth: BiometricAuth? = null
) {
    var amount by remember { mutableStateOf("") }
    var selectedBankCard by remember { mutableStateOf<BankCard?>(null) }
    var showBankCardSelector by remember { mutableStateOf(false) }
    var isSubmitting by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showAmlNotice by remember { mutableStateOf(false) }
    var showSameNameNotice by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    // Mock bank cards - in real app, fetch from backend
    val bankCards = remember {
        listOf(
            BankCard(
                id = "1",
                bankName = "中国银行",
                accountNumber = "****1234",
                accountName = "张三",
                isVerified = true,
                isSameName = true
            ),
            BankCard(
                id = "2",
                bankName = "工商银行",
                accountNumber = "****5678",
                accountName = "张三",
                isVerified = true,
                isSameName = true
            )
        )
    }

    val withdrawalAmount = amount.toDoubleOrNull() ?: 0.0
    val canSubmit = withdrawalAmount > 0 &&
                    withdrawalAmount <= withdrawableFunds &&
                    selectedBankCard != null &&
                    !isSubmitting

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // Top bar
        AppTopBar(
            title = "出金",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            // Withdrawable funds info
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium)
                ) {
                    Text(
                        text = "可出金金额",
                        fontSize = 14.sp,
                        color = TextSecondaryLight
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "$${formatDecimal(withdrawableFunds)}",
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = Primary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "仅已结算资金可出金 (US股票T+1, HK股票T+2)",
                        fontSize = 11.sp,
                        color = TextTertiaryLight
                    )
                }
            }

            // Amount input
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium)
                ) {
                    Text(
                        text = "出金金额",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = TextPrimaryLight
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedTextField(
                        value = amount,
                        onValueChange = {
                            if (it.isEmpty() || it.matches(Regex("^\\d*\\.?\\d{0,2}$"))) {
                                amount = it
                                errorMessage = null
                            }
                        },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("请输入金额") },
                        prefix = { Text("$") },
                        singleLine = true,
                        isError = withdrawalAmount > withdrawableFunds
                    )

                    if (withdrawalAmount > withdrawableFunds) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "金额超过可出金余额",
                            fontSize = 12.sp,
                            color = Error
                        )
                    }

                    // Quick amount buttons
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf(1000.0, 5000.0, 10000.0).forEach { quickAmount ->
                            if (quickAmount <= withdrawableFunds) {
                                OutlinedButton(
                                    onClick = { amount = quickAmount.toInt().toString() },
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text("$${quickAmount.toInt()}")
                                }
                            }
                        }
                        OutlinedButton(
                            onClick = { amount = withdrawableFunds.toInt().toString() },
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("全部")
                        }
                    }
                }
            }

            // Bank card selection
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium)
                ) {
                    Text(
                        text = "收款银行卡",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = TextPrimaryLight
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    if (selectedBankCard != null) {
                        BankCardItem(
                            bankCard = selectedBankCard!!,
                            onClick = { showBankCardSelector = true }
                        )
                    } else {
                        OutlinedButton(
                            onClick = { showBankCardSelector = true },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("选择银行卡")
                        }
                    }
                }
            }

            // Compliance notices
            ComplianceNoticeCard(
                onSameNameClick = { showSameNameNotice = true },
                onAmlClick = { showAmlNotice = true }
            )

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
            }

            // Processing time notice
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = Info.copy(alpha = 0.1f))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = BrokerageIcons.Info,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = Info
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = "到账时间",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Medium,
                            color = Info
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "• 工作日: 1-2个工作日\n• 周末/节假日: 顺延至下一工作日\n• 大额出金(>$50,000)需人工审核",
                        fontSize = 12.sp,
                        color = TextSecondaryLight
                    )
                }
            }
        }

        // Submit button
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            contentAlignment = Alignment.Center
        ) {
            SlideToConfirmButton(
                text = "滑动确认出金",
                onConfirm = {
                    scope.launch {
                        handleWithdrawal(
                            amount = withdrawalAmount,
                            bankCard = selectedBankCard!!,
                            biometricAuth = biometricAuth,
                            onSuccess = {
                                isSubmitting = true
                                onSubmitWithdrawal(withdrawalAmount, selectedBankCard!!.id)
                            },
                            onError = { errorMessage = it }
                        )
                    }
                },
                enabled = canSubmit,
                backgroundColor = Primary
            )
        }
    }

    // Bank card selector dialog
    if (showBankCardSelector) {
        BankCardSelectorDialog(
            bankCards = bankCards,
            onSelect = {
                selectedBankCard = it
                showBankCardSelector = false
            },
            onDismiss = { showBankCardSelector = false }
        )
    }

    // Same-name notice dialog
    if (showSameNameNotice) {
        SameNameNoticeDialog(
            onDismiss = { showSameNameNotice = false }
        )
    }

    // AML notice dialog
    if (showAmlNotice) {
        AmlNoticeDialog(
            onDismiss = { showAmlNotice = false }
        )
    }
}

/**
 * Handle withdrawal with security checks
 */
private suspend fun handleWithdrawal(
    amount: Double,
    bankCard: BankCard,
    biometricAuth: BiometricAuth?,
    onSuccess: () -> Unit,
    onError: (String) -> Unit
) {
    // 1. Same-name verification
    if (!bankCard.isSameName) {
        onError("仅支持同名银行卡出金")
        return
    }

    // 2. Bank card verification status
    if (!bankCard.isVerified) {
        onError("银行卡未完成验证，请先完成小额打款验证")
        return
    }

    // 3. Biometric authentication
    if (biometricAuth == null) {
        onError("生物识别不可用")
        return
    }

    val result = biometricAuth.authenticate(
        title = "确认出金",
        subtitle = "出金金额: $${formatDecimal(amount)}"
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
 * Bank card data model
 */
data class BankCard(
    val id: String,
    val bankName: String,
    val accountNumber: String,
    val accountName: String,
    val isVerified: Boolean,
    val isSameName: Boolean
)

/**
 * Bank card item component
 */
@Composable
private fun BankCardItem(
    bankCard: BankCard,
    onClick: () -> Unit
) {
    OutlinedCard(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = bankCard.bankName,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimaryLight
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = bankCard.accountNumber,
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
                if (bankCard.isSameName) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "✓ 同名账户",
                        fontSize = 11.sp,
                        color = Success
                    )
                }
            }
            Text(
                text = "更换 >",
                fontSize = 12.sp,
                color = Primary
            )
        }
    }
}

/**
 * Bank card selector dialog
 */
@Composable
private fun BankCardSelectorDialog(
    bankCards: List<BankCard>,
    onSelect: (BankCard) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("选择银行卡") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                bankCards.forEach { card ->
                    BankCardItem(
                        bankCard = card,
                        onClick = { onSelect(card) }
                    )
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("取消")
            }
        }
    )
}

/**
 * Same-name notice dialog
 */
@Composable
private fun SameNameNoticeDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("同名账户原则") },
        text = {
            Text(
                text = "根据监管要求，您只能出金至与证券账户同名的银行账户。\n\n" +
                      "这是为了防止洗钱和保护您的资金安全。\n\n" +
                      "第三方转账严格禁止。",
                fontSize = 14.sp
            )
        },
        confirmButton = {
            Button(onClick = onDismiss) {
                Text("我知道了")
            }
        }
    )
}

/**
 * AML notice dialog
 */
@Composable
private fun AmlNoticeDialog(onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("AML 反洗钱筛查") },
        text = {
            Text(
                text = "所有出入金交易都会经过反洗钱(AML)筛查，包括：\n\n" +
                      "• OFAC 制裁名单检查\n• 可疑交易监控\n• 大额交易报告(>$10,000)\n• 结构化交易检测\n\n" +
                      "这是法律要求，用于防止金融犯罪。",
                fontSize = 14.sp
            )
        },
        confirmButton = {
            Button(onClick = onDismiss) {
                Text("我知道了")
            }
        }
    )
}

/**
 * Compliance notice card with clickable links
 */
@Composable
private fun ComplianceNoticeCard(
    onSameNameClick: () -> Unit,
    onAmlClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = Warning.copy(alpha = 0.1f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = BrokerageIcons.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = Warning
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "合规提示",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Warning
                )
            }
            Spacer(modifier = Modifier.height(8.dp))

            TextButton(
                onClick = onSameNameClick,
                contentPadding = PaddingValues(0.dp)
            ) {
                Text(
                    text = "• 仅支持同名银行卡出金 >",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }

            TextButton(
                onClick = onAmlClick,
                contentPadding = PaddingValues(0.dp)
            ) {
                Text(
                    text = "• 所有交易将进行AML筛查 >",
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }

            Text(
                text = "• 大额出金(>$50,000)需人工审核",
                fontSize = 12.sp,
                color = TextSecondaryLight
            )
        }
    }
}
