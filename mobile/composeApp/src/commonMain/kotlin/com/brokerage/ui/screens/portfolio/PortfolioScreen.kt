package com.brokerage.ui.screens.portfolio

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
import kotlin.math.pow
import kotlin.math.roundToLong

private fun Double.fmt2(): String {
    val factor = 100.0
    val rounded = (this * factor).roundToLong().toDouble() / factor
    val intPart = rounded.toLong()
    val fracPart = ((rounded - intPart) * factor).roundToLong()
    return "$intPart.${fracPart.toString().padStart(2, '0')}"
}

/**
 * Portfolio screen - displays holdings and analysis
 * Based on portfolio.html prototype
 */
@Composable
fun PortfolioScreen(
    onBuyClick: (String) -> Unit,
    onSellClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("持仓", "分析")

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // Asset summary header
        AssetSummaryHeader()

        // Tab row
        AppTabRow(
            selectedTabIndex = selectedTab,
            tabs = tabs,
            onTabSelected = { selectedTab = it }
        )

        HorizontalDivider(color = BorderLight, thickness = 1.dp)

        // Content based on selected tab
        when (selectedTab) {
            0 -> HoldingsTab(
                holdings = getSampleHoldings(),
                onBuyClick = onBuyClick,
                onSellClick = onSellClick,
                modifier = Modifier.weight(1f)
            )
            1 -> AnalysisTab(
                modifier = Modifier.weight(1f)
            )
        }
    }
}

/**
 * Asset summary header with gradient background
 */
@Composable
private fun AssetSummaryHeader() {
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
                text = "总资产",
                fontSize = 12.sp,
                color = Color.White.copy(alpha = 0.9f)
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "$25,340.56",
                fontSize = 32.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "今日盈亏 +$234.50 (+0.93%)",
                    fontSize = 12.sp,
                    color = TradingColors.UpUS
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "▲",
                    fontSize = 10.sp,
                    color = TradingColors.UpUS
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Available and Holdings
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "可用",
                        fontSize = 12.sp,
                        color = Color.White.copy(alpha = 0.75f)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "$10,000",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "持仓",
                        fontSize = 12.sp,
                        color = Color.White.copy(alpha = 0.75f)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "$15,340",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }
            }
        }
    }
}

/**
 * Holdings tab - list of positions
 */
@Composable
private fun HoldingsTab(
    holdings: List<HoldingItem>,
    onBuyClick: (String) -> Unit,
    onSellClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize()
    ) {
        items(holdings) { holding ->
            HoldingListItem(
                holding = holding,
                onBuyClick = { onBuyClick(holding.symbol) },
                onSellClick = { onSellClick(holding.symbol) }
            )
            HorizontalDivider(color = DividerLight, thickness = 1.dp)
        }
    }
}

/**
 * Single holding list item
 */
@Composable
private fun HoldingListItem(
    holding: HoldingItem,
    onBuyClick: () -> Unit,
    onSellClick: () -> Unit
) {
    Surface(
        color = Color.White,
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        ) {
            // Header: Symbol, Quantity, Price
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = holding.symbol,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = TextPrimaryLight
                        )
                        Text(
                            text = if (holding.isUp) "▲" else "▼",
                            fontSize = 10.sp,
                            color = if (holding.isUp) TradingColors.UpUS else TradingColors.DownUS
                        )
                        Text(
                            text = "${holding.quantity}股",
                            fontSize = 12.sp,
                            color = TextSecondaryLight
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "成本 $${holding.costBasis.fmt2()} (均价)",
                        fontSize = 12.sp,
                        color = TextSecondaryLight
                    )
                }

                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "$${holding.currentPrice.fmt2()}",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimaryLight
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "${if (holding.profitLoss > 0) "+" else ""}$${holding.profitLoss.fmt2()} (${if (holding.profitLossPercent > 0) "+" else ""}${holding.profitLossPercent.fmt2()}%)",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (holding.isUp) TradingColors.UpUS else TradingColors.DownUS
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onBuyClick,
                    modifier = Modifier
                        .weight(1f)
                        .height(40.dp),
                    shape = RoundedCornerShape(CornerRadius.medium),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = TradingColors.UpUS.copy(alpha = 0.1f),
                        contentColor = TradingColors.UpUS
                    ),
                    elevation = ButtonDefaults.buttonElevation(
                        defaultElevation = 0.dp
                    )
                ) {
                    Text(
                        text = "买入",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
                Button(
                    onClick = onSellClick,
                    modifier = Modifier
                        .weight(1f)
                        .height(40.dp),
                    shape = RoundedCornerShape(CornerRadius.medium),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = TradingColors.DownUS.copy(alpha = 0.1f),
                        contentColor = TradingColors.DownUS
                    ),
                    elevation = ButtonDefaults.buttonElevation(
                        defaultElevation = 0.dp
                    )
                ) {
                    Text(
                        text = "卖出",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

/**
 * Analysis tab - sector distribution and P&L ranking
 */
@Composable
private fun AnalysisTab(
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize()
    ) {
        item {
            // Sector distribution
            Surface(
                color = Color.White,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium)
                ) {
                    Text(
                        text = "行业分布",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimaryLight
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    // Tech sector
                    SectorDistributionItem(
                        name = "科技",
                        percentage = 60,
                        color = Primary
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    // Auto sector
                    SectorDistributionItem(
                        name = "汽车",
                        percentage = 40,
                        color = ChartOrange
                    )
                }
            }

            HorizontalDivider(color = DividerLight, thickness = 8.dp)

            // P&L ranking
            Surface(
                color = Color.White,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(Spacing.medium)
                ) {
                    Text(
                        text = "盈亏排行",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = TextPrimaryLight
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    ProfitLossRankingItem(
                        symbol = "AAPL",
                        profitLoss = 523.00,
                        profitLossPercent = 3.08,
                        isUp = true
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    ProfitLossRankingItem(
                        symbol = "TSLA",
                        profitLoss = -216.50,
                        profitLossPercent = -1.73,
                        isUp = false
                    )
                }
            }

            HorizontalDivider(color = DividerLight, thickness = 8.dp)

            // Concentration risk warning
            WarningCard(
                title = "持仓集中度风险",
                message = "AAPL 持仓占比 60%，建议分散投资降低风险",
                modifier = Modifier.padding(Spacing.medium)
            )
        }
    }
}

/**
 * Sector distribution item with progress bar
 */
@Composable
private fun SectorDistributionItem(
    name: String,
    percentage: Int,
    color: Color
) {
    Column {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = name,
                fontSize = 12.sp,
                color = TextSecondaryLight
            )
            Text(
                text = "$percentage%",
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = TextPrimaryLight
            )
        }
        Spacer(modifier = Modifier.height(4.dp))
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .background(
                    color = BorderLight,
                    shape = RoundedCornerShape(4.dp)
                )
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(percentage / 100f)
                    .fillMaxHeight()
                    .background(
                        color = color,
                        shape = RoundedCornerShape(4.dp)
                    )
            )
        }
    }
}

/**
 * Profit/Loss ranking item
 */
@Composable
private fun ProfitLossRankingItem(
    symbol: String,
    profitLoss: Double,
    profitLossPercent: Double,
    isUp: Boolean
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = symbol,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = TextPrimaryLight
        )
        Text(
            text = "${if (profitLoss > 0) "+" else ""}$${profitLoss.fmt2()} (${if (profitLossPercent > 0) "+" else ""}${profitLossPercent.fmt2()}%)",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = if (isUp) TradingColors.UpUS else TradingColors.DownUS
        )
    }
}

/**
 * Holding data model
 */
data class HoldingItem(
    val symbol: String,
    val quantity: Int,
    val costBasis: Double,
    val currentPrice: Double,
    val profitLoss: Double,
    val profitLossPercent: Double,
    val isUp: Boolean
)

/**
 * Sample holdings data
 */
internal fun getSampleHoldings(): List<HoldingItem> {
    return listOf(
        HoldingItem(
            symbol = "AAPL",
            quantity = 100,
            costBasis = 170.00,
            currentPrice = 175.23,
            profitLoss = 523.00,
            profitLossPercent = 3.08,
            isUp = true
        ),
        HoldingItem(
            symbol = "TSLA",
            quantity = 50,
            costBasis = 250.00,
            currentPrice = 245.67,
            profitLoss = -216.50,
            profitLossPercent = -1.73,
            isUp = false
        )
    )
}
