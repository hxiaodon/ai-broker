package com.brokerage.ui.screens.market
import com.brokerage.ui.icons.BrokerageIcons

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
import com.brokerage.domain.marketdata.Stock
import com.brokerage.domain.marketdata.StockCategory
import com.brokerage.presentation.market.MarketViewModel
import com.brokerage.ui.accessibility.accessibilityLabel
import com.brokerage.ui.components.*
import com.brokerage.ui.theme.*
import org.koin.compose.koinInject

/**
 * Market screen - displays stock list with tabs
 * Integrated with real API data
 */
@Composable
fun MarketScreen(
    onStockClick: (String) -> Unit,
    onSearchClick: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: MarketViewModel = koinInject()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(0) }
    val tabs = listOf("自选", "美股", "港股", "热门")
    val categories = listOf(
        StockCategory.WATCHLIST,
        StockCategory.US,
        StockCategory.HK,
        StockCategory.HOT
    )

    // 初始加载
    LaunchedEffect(Unit) {
        viewModel.loadStocks(StockCategory.WATCHLIST)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // Top bar with search and notification
        MarketTopBar(
            onSearchClick = onSearchClick,
            onNotificationClick = { /* TODO */ },
            wsConnected = uiState.wsConnected
        )

        // Tab row
        AppTabRow(
            selectedTabIndex = selectedTab,
            tabs = tabs,
            onTabSelected = { index ->
                selectedTab = index
                viewModel.switchCategory(categories[index])
            }
        )

        HorizontalDivider(color = BorderLight, thickness = 1.dp)

        // Content
        Box(modifier = Modifier.weight(1f)) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.error != null -> {
                    ErrorView(
                        message = uiState.error!!,
                        onRetry = { viewModel.refresh() },
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                uiState.stocks.isEmpty() -> {
                    EmptyView(
                        message = "暂无数据",
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                else -> {
                    StockList(
                        stocks = uiState.stocks,
                        onStockClick = onStockClick
                    )
                }
            }
        }
    }
}

/**
 * Top bar with title and action buttons
 */
@Composable
private fun MarketTopBar(
    onSearchClick: () -> Unit,
    onNotificationClick: () -> Unit,
    wsConnected: Boolean = false
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
                .padding(horizontal = Spacing.medium),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "行情",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimaryLight
                )
                if (wsConnected) {
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(SuccessGreen, shape = androidx.compose.foundation.shape.CircleShape)
                    )
                }
            }

            Row(
                horizontalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                IconButton(onClick = onSearchClick) {
                    Icon(BrokerageIcons.Search, contentDescription = "搜索", modifier = Modifier.size(20.dp))
                }
                IconButton(onClick = onNotificationClick) {
                    Icon(BrokerageIcons.Notifications, contentDescription = "通知", modifier = Modifier.size(20.dp))
                }
            }
        }
    }
}

/**
 * Stock list component
 */
@Composable
private fun StockList(
    stocks: List<Stock>,
    onStockClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(vertical = Spacing.small)
    ) {
        items(stocks, key = { it.symbol }) { stock ->
            StockListItem(
                stock = stock,
                onClick = { onStockClick(stock.symbol) }
            )
            HorizontalDivider(color = BorderLight, thickness = 1.dp)
        }
    }
}

/**
 * Stock list item
 */
@Composable
private fun StockListItem(
    stock: Stock,
    onClick: () -> Unit
) {
    val isUp = stock.change.toDouble() >= 0
    val accessibilityLabel = "${stock.symbol} ${stock.nameCN}，" +
            "当前价格 ${stock.price.toPlainString()} 美元，" +
            "${if (isUp) "上涨" else "下跌"} ${stock.changePercent.toPlainString()} 百分点"

    Surface(
        onClick = onClick,
        color = Color.White,
        modifier = Modifier
            .fillMaxWidth()
            .accessibilityLabel(accessibilityLabel)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.medium),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left: Symbol and name
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = stock.symbol,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = stock.nameCN,
                    fontSize = 12.sp,
                    color = TextSecondary
                )
            }

            // Middle: Market cap and PE
            Column(
                horizontalAlignment = Alignment.End,
                modifier = Modifier.padding(horizontal = Spacing.medium)
            ) {
                Text(
                    text = stock.marketCap,
                    fontSize = 12.sp,
                    color = TextSecondary
                )
                stock.pe?.let { pe ->
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "PE ${pe.toPlainString()}",
                        fontSize = 12.sp,
                        color = TextSecondary
                    )
                }
            }

            // Right: Price and change
            Column(horizontalAlignment = Alignment.End) {
                // 价格（带闪烁动画）
                var previousPrice by remember { mutableStateOf(stock.price) }
                LaunchedEffect(stock.price) {
                    previousPrice = stock.price
                }

                AnimatedPrice(
                    price = stock.price,
                    previousPrice = previousPrice,
                    fontSize = 16
                )

                Spacer(modifier = Modifier.height(4.dp))

                // 涨跌幅（带图标）
                Row(
                    horizontalArrangement = Arrangement.spacedBy(2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    PriceChangeIcon(change = stock.change, size = 10)

                    val isUp = stock.change.toDouble() >= 0
                    Text(
                        text = "${if (isUp) "+" else ""}${stock.changePercent.toPlainString()}%",
                        fontSize = 12.sp,
                        color = if (isUp) SuccessGreen else DangerRed,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

/**
 * Error view
 */
@Composable
private fun ErrorView(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.padding(Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = message,
            fontSize = 14.sp,
            color = TextSecondary
        )
        Spacer(modifier = Modifier.height(Spacing.medium))
        Button(onClick = onRetry) {
            Text("重试")
        }
    }
}

/**
 * Empty view
 */
@Composable
private fun EmptyView(
    message: String,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier.padding(Spacing.large),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = message,
            fontSize = 14.sp,
            color = TextSecondary
        )
    }
}
