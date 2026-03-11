package com.brokerage.ui.screens.account
import com.brokerage.ui.icons.BrokerageIcons

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.ui.components.*
import com.brokerage.ui.theme.*
import com.brokerage.ui.util.formatDecimal

/**
 * Funding screen - deposit and withdrawal
 * Based on funding.html prototype
 *
 * Compliance features (fund-transfer-compliance.md):
 * - Same-name account verification (Rule 1)
 * - AML screening indicator (Rule 2)
 * - Settlement-aware withdrawals (Rule 4)
 * - T+1/T+2 settlement date display
 * - Withdrawable balance calculation
 */
@Composable
fun FundingScreen(
    onBackClick: () -> Unit,
    onDepositClick: () -> Unit,
    onWithdrawClick: () -> Unit,
    onAddBankCardClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    // Mock data - in real app, fetch from backend
    val totalCash = 10000.0
    val settledFunds = 8500.0
    val unsettledFunds = 1500.0
    val pendingWithdrawals = 0.0
    val marginRequirement = 0.0

    // Withdrawable balance = Settled funds - Pending withdrawals - Margin requirement
    val withdrawableFunds = settledFunds - pendingWithdrawals - marginRequirement

    // Settlement dates for unsettled funds
    val unsettledTransactions = listOf(
        UnsettledTransaction(amount = 1000.0, settlementDate = "2026-03-09", type = "US股票卖出 (T+1)"),
        UnsettledTransaction(amount = 500.0, settlementDate = "2026-03-10", type = "HK股票卖出 (T+2)")
    )
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // Top bar
        AppTopBar(
            title = "出入金",
            onBackClick = onBackClick
        )

        LazyColumn(
            modifier = Modifier.weight(1f),
            contentPadding = PaddingValues(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            // Enhanced balance card with settlement info
            item {
                EnhancedBalanceCard(
                    totalCash = totalCash,
                    settledFunds = settledFunds,
                    unsettledFunds = unsettledFunds,
                    withdrawableFunds = withdrawableFunds,
                    unsettledTransactions = unsettledTransactions
                )
            }

            // Compliance notice
            item {
                ComplianceNoticeCard()
            }

            // Action buttons
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    ActionButton(
                        text = "入金",
                        icon = BrokerageIcons.Add,
                        onClick = onDepositClick,
                        backgroundColor = Success,
                        modifier = Modifier.weight(1f)
                    )
                    ActionButton(
                        text = "出金",
                        icon = BrokerageIcons.Remove,
                        onClick = onWithdrawClick,
                        backgroundColor = Primary,
                        modifier = Modifier.weight(1f)
                    )
                }
            }

            // Bank cards section
            item {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "银行卡",
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = TextPrimaryLight
                        )
                        TextButton(onClick = onAddBankCardClick) {
                            Text(
                                text = "+ 添加",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Medium,
                                color = Primary
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    BankCardItem(
                        bankName = "中国银行",
                        cardNumber = "****1234",
                        onClick = { /* TODO */ }
                    )
                }
            }

            // Recent transactions
            item {
                Text(
                    text = "最近记录",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimaryLight
                )
            }

            items(getSampleTransactions()) { transaction ->
                TransactionItem(transaction = transaction)
            }
        }
    }
}

/**
 * Balance card with gradient background
 */
@Composable
private fun BalanceCard(
    availableFunds: Double,
    settledFunds: Double,
    unsettledFunds: Double
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.Transparent
        )
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Primary,
                            PrimaryDark
                        )
                    )
                )
                .padding(24.dp)
        ) {
            Column {
                Text(
                    text = "可用资金",
                    fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.9f)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "$${formatDecimal(availableFunds)}",
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "已结算 $${formatDecimal(settledFunds)} | 未结算 $${formatDecimal(unsettledFunds)}",
                    fontSize = 12.sp,
                    color = Color.White.copy(alpha = 0.75f)
                )
            }
        }
    }
}

/**
 * Action button (Deposit/Withdraw)
 */
@Composable
private fun ActionButton(
    text: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    backgroundColor: Color,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier.height(80.dp),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = ButtonDefaults.buttonColors(
            containerColor = backgroundColor
        )
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = text,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = text,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

/**
 * Bank card item
 */
@Composable
private fun BankCardItem(
    bankName: String,
    cardNumber: String,
    onClick: () -> Unit
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        ),
        border = ButtonDefaults.outlinedButtonBorder
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Bank icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .background(
                        color = Error.copy(alpha = 0.1f),
                        shape = RoundedCornerShape(CornerRadius.medium)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = BrokerageIcons.CreditCard,
                    contentDescription = null,
                    tint = Error,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = bankName,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimaryLight
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = cardNumber,
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }

            Icon(
                imageVector = BrokerageIcons.ChevronRight,
                contentDescription = null,
                tint = TextSecondaryLight
            )
        }
    }
}

/**
 * Transaction item
 */
@Composable
private fun TransactionItem(
    transaction: TransactionRecord
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        ),
        border = ButtonDefaults.outlinedButtonBorder
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
                    text = transaction.type,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium,
                    color = TextPrimaryLight
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = transaction.time,
                    fontSize = 12.sp,
                    color = TextSecondaryLight
                )
            }

            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "${if (transaction.isDeposit) "+" else "-"}$${formatDecimal(transaction.amount)}",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (transaction.isDeposit) Success else TextPrimaryLight
                )
                Spacer(modifier = Modifier.height(4.dp))
                TransactionStatusBadge(status = transaction.status)
            }
        }
    }
}

/**
 * Transaction status badge
 */
@Composable
private fun TransactionStatusBadge(status: TransactionStatus) {
    val (text, backgroundColor, textColor) = when (status) {
        TransactionStatus.SUCCESS -> Triple("成功", Success.copy(alpha = 0.1f), Success)
        TransactionStatus.PENDING -> Triple("处理中", Warning.copy(alpha = 0.1f), Warning)
        TransactionStatus.FAILED -> Triple("失败", Error.copy(alpha = 0.1f), Error)
    }

    Surface(
        shape = RoundedCornerShape(4.dp),
        color = backgroundColor
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
 * Transaction record data model
 */
data class TransactionRecord(
    val id: String,
    val type: String,
    val amount: Double,
    val isDeposit: Boolean,
    val status: TransactionStatus,
    val time: String
)

enum class TransactionStatus {
    SUCCESS,
    PENDING,
    FAILED
}

/**
 * Unsettled transaction data model
 */
data class UnsettledTransaction(
    val amount: Double,
    val settlementDate: String,
    val type: String
)

/**
 * Enhanced balance card with settlement information
 */
@Composable
private fun EnhancedBalanceCard(
    totalCash: Double,
    settledFunds: Double,
    unsettledFunds: Double,
    withdrawableFunds: Double,
    unsettledTransactions: List<UnsettledTransaction>
) {
    var showDetails by remember { mutableStateOf(false) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.large),
        colors = CardDefaults.cardColors(
            containerColor = Color.White
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(Primary.copy(alpha = 0.1f), Primary.copy(alpha = 0.05f))
                    )
                )
                .padding(Spacing.large)
        ) {
            // Total cash
            Text(
                text = "总资金",
                fontSize = 14.sp,
                color = TextSecondaryLight
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "$${formatDecimal(totalCash)}",
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = TextPrimaryLight
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Settled vs Unsettled breakdown
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Column {
                    Text(
                        text = "已结算",
                        fontSize = 12.sp,
                        color = TextSecondaryLight
                    )
                    Text(
                        text = "$${formatDecimal(settledFunds)}",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Success
                    )
                }

                Column(horizontalAlignment = Alignment.End) {
                    Text(
                        text = "未结算",
                        fontSize = 12.sp,
                        color = TextSecondaryLight
                    )
                    Text(
                        text = "$${formatDecimal(unsettledFunds)}",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Warning
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Withdrawable funds (critical for compliance)
            HorizontalDivider(color = BorderLight)
            Spacer(modifier = Modifier.height(Spacing.medium))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "可出金金额",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = TextPrimaryLight
                    )
                    Text(
                        text = "仅已结算资金可出金",
                        fontSize = 11.sp,
                        color = TextSecondaryLight
                    )
                }
                Text(
                    text = "$${formatDecimal(withdrawableFunds)}",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Primary
                )
            }

            // Show unsettled details
            if (unsettledFunds > 0) {
                Spacer(modifier = Modifier.height(Spacing.small))
                TextButton(
                    onClick = { showDetails = !showDetails },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = if (showDetails) "收起详情 ▲" else "查看未结算详情 ▼",
                        fontSize = 12.sp,
                        color = Primary
                    )
                }

                if (showDetails) {
                    Spacer(modifier = Modifier.height(Spacing.small))
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color.White.copy(alpha = 0.5f), RoundedCornerShape(CornerRadius.small))
                            .padding(Spacing.small),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        unsettledTransactions.forEach { transaction ->
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = transaction.type,
                                        fontSize = 11.sp,
                                        color = TextSecondaryLight
                                    )
                                    Text(
                                        text = "结算日: ${transaction.settlementDate}",
                                        fontSize = 10.sp,
                                        color = TextTertiaryLight
                                    )
                                }
                                Text(
                                    text = "$${formatDecimal(transaction.amount)}",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = Warning
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/**
 * Compliance notice card
 */
@Composable
private fun ComplianceNoticeCard() {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(CornerRadius.medium),
        colors = CardDefaults.cardColors(
            containerColor = InfoBlue.copy(alpha = 0.1f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            verticalAlignment = Alignment.Top
        ) {
            Icon(
                imageVector = BrokerageIcons.Info,
                contentDescription = null,
                tint = InfoBlue,
                modifier = Modifier.size(20.dp).padding(end = 8.dp)
            )
            Column {
                Text(
                    text = "出入金合规提示",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = InfoBlue
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "• 同名账户原则：仅支持本人同名银行账户出入金\n• AML筛查：所有交易将进行反洗钱审查\n• 结算规则：US股票T+1，HK股票T+2结算\n• 大额交易：单笔>$10,000需人工审核",
                    fontSize = 11.sp,
                    color = TextSecondaryLight,
                    lineHeight = 16.sp
                )
            }
        }
    }
}

/**
 * Sample transaction data
 */
internal fun getSampleTransactions(): List<TransactionRecord> {
    return listOf(
        TransactionRecord(
            id = "1",
            type = "入金",
            amount = 5000.0,
            isDeposit = true,
            status = TransactionStatus.SUCCESS,
            time = "2026-03-07 10:30"
        ),
        TransactionRecord(
            id = "2",
            type = "出金",
            amount = 2000.0,
            isDeposit = false,
            status = TransactionStatus.SUCCESS,
            time = "2026-03-06 15:20"
        ),
        TransactionRecord(
            id = "3",
            type = "入金",
            amount = 10000.0,
            isDeposit = true,
            status = TransactionStatus.PENDING,
            time = "2026-03-05 09:15"
        )
    )
}
