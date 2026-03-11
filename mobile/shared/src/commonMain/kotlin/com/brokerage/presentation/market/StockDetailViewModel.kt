package com.brokerage.presentation.market

import com.brokerage.data.api.ApiResult
import com.brokerage.data.repository.MarketRepository
import com.brokerage.domain.marketdata.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * 股票详情页面 Tab
 */
enum class StockDetailTab {
    KLINE,
    ORDER_BOOK,
    NEWS,
    FINANCIALS
}

/**
 * 股票详情页面状态
 */
data class StockDetailUiState(
    val isLoading: Boolean = false,
    val stockDetail: StockDetail? = null,
    val klineData: List<Kline> = emptyList(),
    val selectedInterval: KlineInterval = KlineInterval.ONE_DAY,
    val news: List<News> = emptyList(),
    val financials: List<Financial> = emptyList(),
    val error: String? = null,
    val isInWatchlist: Boolean = false,
    val selectedTab: StockDetailTab = StockDetailTab.ORDER_BOOK,
    val orderBook: OrderBook? = null,
    val showMaLines: Boolean = true,
    val showVolume: Boolean = true
)

/**
 * 股票详情 ViewModel
 */
class StockDetailViewModel(
    private val repository: MarketRepository,
    private val symbol: String
) {
    private val viewModelScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val _uiState = MutableStateFlow(StockDetailUiState())
    val uiState: StateFlow<StockDetailUiState> = _uiState.asStateFlow()

    private var depthJob: Job? = null

    init {
        loadStockDetail()
        loadKlineData()
        observeRealtimeQuotes()
        // Default tab is ORDER_BOOK, so subscribe to depth on init
        selectTab(StockDetailTab.ORDER_BOOK)
    }

    /**
     * 加载股票详情
     */
    fun loadStockDetail() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            when (val result = repository.getStockDetail(symbol)) {
                is ApiResult.Success -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            stockDetail = result.data,
                            error = null
                        )
                    }

                    // 订阅实时行情
                    repository.subscribeQuotes(listOf(symbol))
                }
                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = result.exception.message
                        )
                    }
                }
            }
        }
    }

    /**
     * 加载 K 线数据
     */
    fun loadKlineData(interval: KlineInterval = KlineInterval.ONE_DAY) {
        viewModelScope.launch {
            _uiState.update { it.copy(selectedInterval = interval) }

            when (val result = repository.getKline(symbol, interval, null, null, 100)) {
                is ApiResult.Success -> {
                    _uiState.update {
                        it.copy(klineData = result.data)
                    }
                }
                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(error = result.exception.message)
                    }
                }
            }
        }
    }

    /**
     * 加载新闻
     */
    fun loadNews() {
        viewModelScope.launch {
            when (val result = repository.getNews(symbol, page = 1, pageSize = 20)) {
                is ApiResult.Success -> {
                    _uiState.update {
                        it.copy(news = result.data.items)
                    }
                }
                is ApiResult.Error -> {
                    // 新闻加载失败不影响主流程
                }
            }
        }
    }

    /**
     * 加载财报
     */
    fun loadFinancials() {
        viewModelScope.launch {
            when (val result = repository.getFinancials(symbol, limit = 8)) {
                is ApiResult.Success -> {
                    _uiState.update {
                        it.copy(financials = result.data)
                    }
                }
                is ApiResult.Error -> {
                    // 财报加载失败不影响主流程
                }
            }
        }
    }

    /**
     * 切换页面 Tab，按需懒加载数据
     */
    fun selectTab(tab: StockDetailTab) {
        val previousTab = _uiState.value.selectedTab
        _uiState.update { it.copy(selectedTab = tab) }

        // 离开 ORDER_BOOK 时取消深度订阅
        if (previousTab == StockDetailTab.ORDER_BOOK && tab != StockDetailTab.ORDER_BOOK) {
            unsubscribeDepthUpdates()
        }

        when (tab) {
            StockDetailTab.ORDER_BOOK -> {
                subscribeDepthUpdates()
                viewModelScope.launch {
                    when (val result = repository.getDepth(symbol)) {
                        is ApiResult.Success -> {
                            _uiState.update { it.copy(orderBook = result.data) }
                        }
                        is ApiResult.Error -> {
                            // 深度加载失败不影响主流程
                        }
                    }
                }
            }
            StockDetailTab.NEWS -> {
                if (_uiState.value.news.isEmpty()) {
                    loadNews()
                }
            }
            StockDetailTab.FINANCIALS -> {
                if (_uiState.value.financials.isEmpty()) {
                    loadFinancials()
                }
            }
            StockDetailTab.KLINE -> {
                // K 线数据已在 init 中加载，无需重复请求
            }
        }
    }

    /**
     * 切换 K 线周期
     */
    fun switchInterval(interval: KlineInterval) {
        if (_uiState.value.selectedInterval != interval) {
            loadKlineData(interval)
        }
    }

    /**
     * 添加/删除自选
     */
    fun toggleWatchlist() {
        viewModelScope.launch {
            val isInWatchlist = _uiState.value.isInWatchlist

            val result = if (isInWatchlist) {
                repository.removeFromWatchlist(symbol)
            } else {
                repository.addToWatchlist(symbol)
            }

            when (result) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(isInWatchlist = !isInWatchlist) }
                }
                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(error = if (isInWatchlist) "删除自选失败" else "添加自选失败")
                    }
                }
            }
        }
    }

    /**
     * 切换均线显示
     */
    fun toggleMaLines() {
        _uiState.update { it.copy(showMaLines = !it.showMaLines) }
    }

    /**
     * 切换成交量显示
     */
    fun toggleVolume() {
        _uiState.update { it.copy(showVolume = !it.showVolume) }
    }

    /**
     * 订阅深度行情更新
     */
    private fun subscribeDepthUpdates() {
        depthJob?.cancel()
        depthJob = viewModelScope.launch {
            repository.subscribeDepth(symbol)
            repository.realtimeDepth
                .filter { it.symbol == symbol }
                .collect { depthData ->
                    val currentBook = _uiState.value.orderBook
                    val market = currentBook?.market ?: return@collect
                    _uiState.update {
                        it.copy(
                            orderBook = OrderBook(
                                symbol = depthData.symbol,
                                market = market,
                                bids = depthData.bids,
                                asks = depthData.asks,
                                timestamp = depthData.timestamp
                            )
                        )
                    }
                }
        }
    }

    /**
     * 取消订阅深度行情
     */
    private fun unsubscribeDepthUpdates() {
        depthJob?.cancel()
        depthJob = null
        viewModelScope.launch {
            repository.unsubscribeDepth(symbol)
        }
    }

    /**
     * 观察实时行情
     */
    private fun observeRealtimeQuotes() {
        viewModelScope.launch {
            repository.realtimeQuotes
                .filter { it.symbol == symbol }
                .collect { quote ->
                    val currentDetail = _uiState.value.stockDetail ?: return@collect

                    val updatedDetail = currentDetail.copy(
                        price = com.brokerage.common.decimal.BigDecimal(quote.price),
                        change = com.brokerage.common.decimal.BigDecimal(quote.change),
                        changePercent = com.brokerage.common.decimal.BigDecimal(quote.changePercent),
                        volume = quote.volume,
                        timestamp = quote.timestamp
                    )

                    _uiState.update { it.copy(stockDetail = updatedDetail) }
                }
        }
    }

    /**
     * 清理资源
     */
    fun onCleared() {
        viewModelScope.launch {
            repository.unsubscribeQuotes(listOf(symbol))
            repository.unsubscribeDepth(symbol)
        }
        depthJob?.cancel()
        depthJob = null
    }
}
