package com.brokerage.ui.screens.market

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.brokerage.domain.marketdata.Financial
import com.brokerage.domain.marketdata.Kline
import com.brokerage.domain.marketdata.KlineInterval
import com.brokerage.domain.marketdata.News
import com.brokerage.domain.marketdata.OrderBook
import com.brokerage.domain.marketdata.StockDetail
import com.brokerage.presentation.market.StockDetailTab
import com.brokerage.presentation.market.StockDetailViewModel
import com.brokerage.ui.components.AnimatedPrice
import com.brokerage.ui.components.KlineChart
import com.brokerage.ui.components.OrderBookView
import com.brokerage.ui.components.TimeSharingChart
import com.brokerage.ui.components.PriceChangeWithIcon
import com.brokerage.ui.screens.alert.AddPriceAlertDialog
import com.brokerage.ui.theme.BackgroundLight
import com.brokerage.ui.theme.BorderLight
import com.brokerage.ui.theme.DangerRed
import com.brokerage.ui.theme.PrimaryBlue
import com.brokerage.ui.theme.Spacing
import com.brokerage.ui.theme.SuccessGreen
import com.brokerage.ui.theme.TextPrimary
import com.brokerage.ui.theme.TextSecondary
import com.brokerage.ui.theme.WarningOrange
import com.brokerage.ui.util.formatDecimal
import kotlinx.datetime.Clock
import org.koin.compose.koinInject
import org.koin.core.parameter.parametersOf

/**
 * 股票详情页面
 *
 * 布局:
 * 1. TopBar
 * 2. PriceSection
 * 3. KlineSection (包含周期切换、MA/成交量切换、K线图)
 * 4. TabRow — 盘口 | 新闻 | 财报
 * 5. 各 Tab 内容
 * 6. TradeButtonBar
 */
@Composable
fun StockDetailScreen(
    symbol: String,
    onBackClick: () -> Unit,
    onTradeClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: StockDetailViewModel = koinInject { parametersOf(symbol) }
) {
    val uiState by viewModel.uiState.collectAsState()
    var showAlertDialog by remember { mutableStateOf(false) }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.onCleared()
        }
    }

    // 价格提醒对话框
    if (showAlertDialog && uiState.stockDetail != null) {
        AddPriceAlertDialog(
            symbol = symbol,
            stockName = uiState.stockDetail!!.nameCN,
            currentPrice = uiState.stockDetail!!.price,
            onDismiss = { showAlertDialog = false },
            onConfirm = { _, _ ->
                // TODO: 保存价格提醒
                showAlertDialog = false
            }
        )
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(BackgroundLight)
    ) {
        // ── Top bar ──────────────────────────────────────────────────────
        StockDetailTopBar(
            symbol = symbol,
            isInWatchlist = uiState.isInWatchlist,
            onBackClick = onBackClick,
            onWatchlistClick = { viewModel.toggleWatchlist() },
            onAlertClick = { showAlertDialog = true }
        )

        when {
            uiState.isLoading && uiState.stockDetail == null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }

            uiState.error != null && uiState.stockDetail == null -> {
                ErrorView(
                    message = uiState.error!!,
                    onRetry = { viewModel.loadStockDetail() },
                    modifier = Modifier.fillMaxSize()
                )
            }

            else -> {
                uiState.stockDetail?.let { detail ->
                    LazyColumn(
                        modifier = Modifier.weight(1f),
                        contentPadding = PaddingValues(bottom = 80.dp)
                    ) {
                        // ── Price section ────────────────────────────────
                        item {
                            PriceSection(detail = detail)
                        }

                        // ── K-line section (always visible) ──────────────
                        item {
                            KlineSection(
                                klineData = uiState.klineData,
                                selectedInterval = uiState.selectedInterval,
                                showVolume = uiState.showVolume,
                                showMaLines = uiState.showMaLines,
                                onIntervalChange = { viewModel.switchInterval(it) },
                                onToggleMaLines = { viewModel.toggleMaLines() },
                                onToggleVolume = { viewModel.toggleVolume() },
                                prevClose = detail.open.toDouble()
                            )
                        }

                        // ── Tab row: 盘口 | 新闻 | 财报 ──────────────────
                        item {
                            DetailTabRow(
                                selectedTab = uiState.selectedTab,
                                onTabSelected = { viewModel.selectTab(it) }
                            )
                        }

                        // ── Tab content ───────────────────────────────────
                        item {
                            when (uiState.selectedTab) {
                                StockDetailTab.KLINE -> {
                                    // KLINE tab is handled by the KlineSection above;
                                    // show basic info here as a fallback placeholder.
                                    BasicInfoSection(detail = detail)
                                }

                                StockDetailTab.ORDER_BOOK -> {
                                    BasicInfoSection(detail = detail)
                                    OrderBookSection(orderBook = uiState.orderBook)
                                }

                                StockDetailTab.NEWS -> {
                                    NewsSection(
                                        news = uiState.news,
                                        onNewsClick = { /* TODO: navigate to news detail */ }
                                    )
                                }

                                StockDetailTab.FINANCIALS -> {
                                    FinancialsSection(financials = uiState.financials)
                                }
                            }
                        }
                    }

                    // ── Bottom trade bar ─────────────────────────────────
                    TradeButtonBar(
                        onBuyClick = { onTradeClick(symbol) },
                        onSellClick = { onTradeClick(symbol) }
                    )
                }
            }
        }
    }
}

// ── TopBar ────────────────────────────────────────────────────────────────────

@Composable
private fun StockDetailTopBar(
    symbol: String,
    isInWatchlist: Boolean,
    onBackClick: () -> Unit,
    onWatchlistClick: () -> Unit,
    onAlertClick: (() -> Unit)? = null
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
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            IconButton(onClick = onBackClick) {
                Text(text = "\u2190", fontSize = 24.sp)
            }

            Text(
                text = symbol,
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )

            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                if (onAlertClick != null) {
                    IconButton(onClick = onAlertClick) {
                        Text(text = "\uD83D\uDD14", fontSize = 20.sp)
                    }
                }
                IconButton(onClick = onWatchlistClick) {
                    Text(
                        text = if (isInWatchlist) "\u2605" else "\u2606",
                        fontSize = 24.sp,
                        color = if (isInWatchlist) WarningOrange else TextSecondary
                    )
                }
            }
        }
    }
}

// ── PriceSection ──────────────────────────────────────────────────────────────

@Composable
private fun PriceSection(detail: StockDetail) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White
    ) {
        Column(
            modifier = Modifier.padding(Spacing.medium)
        ) {
            Text(
                text = detail.nameCN,
                fontSize = 14.sp,
                color = TextSecondary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(verticalAlignment = Alignment.Bottom) {
                var previousPrice by remember { mutableStateOf(detail.price) }
                androidx.compose.runtime.LaunchedEffect(detail.price) {
                    previousPrice = detail.price
                }

                AnimatedPrice(
                    price = detail.price,
                    previousPrice = previousPrice,
                    fontSize = 32
                )

                Spacer(modifier = Modifier.width(12.dp))

                PriceChangeWithIcon(
                    change = detail.change,
                    changePercent = detail.changePercent
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                PriceInfoItem("开盘", detail.open.toPlainString())
                PriceInfoItem("最高", detail.high.toPlainString())
                PriceInfoItem("最低", detail.low.toPlainString())
                PriceInfoItem("昨收", detail.close.toPlainString())
            }
        }
    }
}

@Composable
private fun PriceInfoItem(label: String, value: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = label, fontSize = 12.sp, color = TextSecondary)
        Spacer(modifier = Modifier.height(4.dp))
        Text(text = value, fontSize = 14.sp, color = TextPrimary, fontWeight = FontWeight.Medium)
    }
}

// ── KlineSection ──────────────────────────────────────────────────────────────

@Composable
private fun KlineSection(
    klineData: List<Kline>,
    selectedInterval: KlineInterval,
    showVolume: Boolean,
    showMaLines: Boolean,
    onIntervalChange: (KlineInterval) -> Unit,
    onToggleMaLines: () -> Unit,
    onToggleVolume: () -> Unit,
    prevClose: Double? = null
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        color = Color.White
    ) {
        Column(
            modifier = Modifier.padding(Spacing.medium)
        ) {
            // Interval chips
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                val intervals = listOf(
                    KlineInterval.ONE_MINUTE to "分时",
                    KlineInterval.ONE_DAY to "日K",
                    KlineInterval.ONE_WEEK to "周K",
                    KlineInterval.ONE_MONTH to "月K"
                )
                intervals.forEach { (interval, label) ->
                    IntervalChip(
                        label = label,
                        selected = selectedInterval == interval,
                        onClick = { onIntervalChange(interval) }
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Toggle chips: MA线 / 成交量
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = showMaLines,
                    onClick = onToggleMaLines,
                    label = { Text("MA线", fontSize = 11.sp) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = PrimaryBlue.copy(alpha = 0.15f),
                        selectedLabelColor = PrimaryBlue
                    )
                )
                FilterChip(
                    selected = showVolume,
                    onClick = onToggleVolume,
                    label = { Text("成交量", fontSize = 11.sp) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = PrimaryBlue.copy(alpha = 0.15f),
                        selectedLabelColor = PrimaryBlue
                    )
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Chart — timesharing for ONE_MINUTE, candlestick for all others
            if (selectedInterval == KlineInterval.ONE_MINUTE) {
                TimeSharingChart(
                    data = klineData,
                    modifier = Modifier.fillMaxWidth(),
                    prevClose = prevClose
                )
            } else {
                KlineChart(
                    data = klineData,
                    modifier = Modifier.fillMaxWidth(),
                    showVolume = showVolume,
                    showMaLines = showMaLines,
                    interval = selectedInterval
                )
            }
        }
    }
}

@Composable
private fun IntervalChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = if (selected) PrimaryBlue else BackgroundLight,
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = label,
            fontSize = 12.sp,
            color = if (selected) Color.White else TextSecondary,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp)
        )
    }
}

// ── Tab row ───────────────────────────────────────────────────────────────────

private val detailTabs = listOf(
    StockDetailTab.ORDER_BOOK to "盘口",
    StockDetailTab.NEWS to "新闻",
    StockDetailTab.FINANCIALS to "财报"
)

@Composable
private fun DetailTabRow(
    selectedTab: StockDetailTab,
    onTabSelected: (StockDetailTab) -> Unit
) {
    val tabIndex = detailTabs.indexOfFirst { it.first == selectedTab }.coerceAtLeast(0)

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        color = Color.White
    ) {
        TabRow(
            selectedTabIndex = tabIndex,
            containerColor = Color.White,
            contentColor = PrimaryBlue
        ) {
            detailTabs.forEachIndexed { index, (tab, label) ->
                Tab(
                    selected = tabIndex == index,
                    onClick = { onTabSelected(tab) },
                    text = {
                        Text(
                            text = label,
                            fontSize = 14.sp,
                            fontWeight = if (tabIndex == index) FontWeight.SemiBold else FontWeight.Normal
                        )
                    }
                )
            }
        }
    }
}

// ── OrderBookSection ──────────────────────────────────────────────────────────

@Composable
private fun OrderBookSection(orderBook: OrderBook?) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        color = Color.White
    ) {
        OrderBookView(
            orderBook = orderBook,
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium)
        )
    }
}

// ── BasicInfoSection ──────────────────────────────────────────────────────────

@Composable
private fun BasicInfoSection(detail: StockDetail) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        color = Color.White
    ) {
        Column(
            modifier = Modifier.padding(Spacing.medium)
        ) {
            Text(
                text = "基本信息",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(12.dp))

            InfoRow("市值", detail.marketCap)
            InfoRow("成交量", detail.volume)
            detail.pe?.let { InfoRow("市盈率", it.toPlainString()) }
            detail.pb?.let { InfoRow("市净率", it.toPlainString()) }
            detail.eps?.let { InfoRow("每股收益", it.toPlainString()) }
            detail.dividend?.let { InfoRow("股息", it.toPlainString()) }
            detail.high52w?.let { InfoRow("52周最高", it.toPlainString()) }
            detail.low52w?.let { InfoRow("52周最低", it.toPlainString()) }
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, fontSize = 14.sp, color = TextSecondary)
        Text(text = value, fontSize = 14.sp, color = TextPrimary)
    }
}

// ── NewsSection ───────────────────────────────────────────────────────────────

@Composable
private fun NewsSection(
    news: List<News>,
    onNewsClick: (String) -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        color = Color.White
    ) {
        Column(
            modifier = Modifier.padding(Spacing.medium)
        ) {
            Text(
                text = "相关新闻",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(12.dp))

            if (news.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "暂无新闻", fontSize = 14.sp, color = TextSecondary)
                }
            } else {
                news.take(10).forEachIndexed { index, newsItem ->
                    NewsItemRow(
                        news = newsItem,
                        onClick = { onNewsClick(newsItem.id) }
                    )
                    if (index < news.size - 1) {
                        HorizontalDivider(
                            color = BorderLight,
                            thickness = 0.5.dp,
                            modifier = Modifier.padding(vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun NewsItemRow(
    news: News,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        color = Color.White
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
        ) {
            Text(
                text = news.title,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = TextPrimary,
                maxLines = 2
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(text = news.source, fontSize = 12.sp, color = TextSecondary)
                Text(
                    text = formatRelativeTime(news.publishedAt),
                    fontSize = 12.sp,
                    color = TextSecondary
                )
            }
        }
    }
}

// ── FinancialsSection ─────────────────────────────────────────────────────────

@Composable
private fun FinancialsSection(financials: List<Financial>) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp),
        color = Color.White
    ) {
        Column(
            modifier = Modifier.padding(Spacing.medium)
        ) {
            Text(
                text = "财务报告",
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary
            )

            Spacer(modifier = Modifier.height(12.dp))

            if (financials.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(80.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "暂无财报数据", fontSize = 14.sp, color = TextSecondary)
                }
            } else {
                // Table header
                FinancialsHeader()
                HorizontalDivider(color = BorderLight, thickness = 0.5.dp)

                // Table rows
                financials.forEach { financial ->
                    FinancialRow(financial = financial)
                    HorizontalDivider(color = BorderLight, thickness = 0.5.dp)
                }
            }
        }
    }
}

@Composable
private fun FinancialsHeader() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "季度",
            fontSize = 12.sp,
            color = TextSecondary,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1.2f)
        )
        Text(
            text = "营收",
            fontSize = 12.sp,
            color = TextSecondary,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1.5f)
        )
        Text(
            text = "净利润",
            fontSize = 12.sp,
            color = TextSecondary,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1.5f)
        )
        Text(
            text = "EPS",
            fontSize = 12.sp,
            color = TextSecondary,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun FinancialRow(financial: Financial) {
    val quarterLabel = "${financial.fiscalYear}Q${financial.fiscalQuarter}"
    val revenueText = formatFinancialValue(financial.revenue.toDouble())
    val netIncomeText = formatFinancialValue(financial.netIncome.toDouble())
    val netIncomeColor = if (financial.netIncome.toDouble() >= 0.0) SuccessGreen else DangerRed
    val epsText = "$${formatDecimal(financial.eps.toDouble())}"
    val epsColor = if (financial.eps.toDouble() >= 0.0) SuccessGreen else DangerRed

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 10.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = quarterLabel,
            fontSize = 13.sp,
            color = TextPrimary,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.weight(1.2f)
        )
        Text(
            text = revenueText,
            fontSize = 13.sp,
            color = TextPrimary,
            modifier = Modifier.weight(1.5f)
        )
        Text(
            text = netIncomeText,
            fontSize = 13.sp,
            color = netIncomeColor,
            modifier = Modifier.weight(1.5f)
        )
        Text(
            text = epsText,
            fontSize = 13.sp,
            color = epsColor,
            modifier = Modifier.weight(1f)
        )
    }
}

// ── TradeButtonBar ────────────────────────────────────────────────────────────

@Composable
private fun TradeButtonBar(
    onBuyClick: () -> Unit,
    onSellClick: () -> Unit
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color.White,
        shadowElevation = 8.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.medium),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Button(
                onClick = onBuyClick,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(containerColor = SuccessGreen)
            ) {
                Text("买入", fontSize = 16.sp)
            }

            Button(
                onClick = onSellClick,
                modifier = Modifier.weight(1f),
                colors = ButtonDefaults.buttonColors(containerColor = DangerRed)
            ) {
                Text("卖出", fontSize = 16.sp)
            }
        }
    }
}

// ── ErrorView ─────────────────────────────────────────────────────────────────

@Composable
private fun ErrorView(
    message: String,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(text = message, fontSize = 14.sp, color = TextSecondary)
            Spacer(modifier = Modifier.height(16.dp))
            Button(onClick = onRetry) {
                Text("重试")
            }
        }
    }
}

// ── Formatting helpers ────────────────────────────────────────────────────────

/**
 * Format a financial value (revenue / net income) as a human-readable string.
 * Uses simple arithmetic — no platform-specific APIs.
 */
private fun formatFinancialValue(value: Double): String {
    val abs = if (value < 0) -value else value
    val prefix = if (value < 0) "-" else ""
    return when {
        abs >= 1_000_000_000_000.0 -> "${prefix}${formatDecimal(abs / 1_000_000_000_000.0)}T"
        abs >= 1_000_000_000.0 -> "${prefix}${formatDecimal(abs / 1_000_000_000.0)}B"
        abs >= 1_000_000.0 -> "${prefix}${formatDecimal(abs / 1_000_000.0)}M"
        abs >= 1_000.0 -> "${prefix}${formatDecimal(abs / 1_000.0)}K"
        else -> "${prefix}${formatDecimal(abs)}"
    }
}

/**
 * Format a Unix-epoch-millisecond timestamp as a relative time string.
 * Uses simple epoch arithmetic — no platform-specific date APIs.
 */
private fun formatRelativeTime(timestampMs: Long): String {
    val nowMs = Clock.System.now().toEpochMilliseconds()
    val diffMs = nowMs - timestampMs
    return when {
        diffMs < 60_000L -> "刚刚"
        diffMs < 3_600_000L -> "${diffMs / 60_000L}分钟前"
        diffMs < 86_400_000L -> "${diffMs / 3_600_000L}小时前"
        diffMs < 2_592_000_000L -> "${diffMs / 86_400_000L}天前"
        else -> "${diffMs / 2_592_000_000L}个月前"
    }
}
