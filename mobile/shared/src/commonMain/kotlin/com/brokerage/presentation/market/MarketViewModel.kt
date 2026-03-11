package com.brokerage.presentation.market

import com.brokerage.common.decimal.BigDecimal
import com.brokerage.data.api.ApiResult
import com.brokerage.data.repository.MarketRepository
import com.brokerage.data.websocket.WsState
import com.brokerage.domain.marketdata.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

/**
 * 行情页面状态
 */
data class MarketUiState(
    val isLoading: Boolean = false,
    val stocks: List<Stock> = emptyList(),
    val selectedCategory: StockCategory = StockCategory.WATCHLIST,
    val error: String? = null,
    val wsConnected: Boolean = false
)

/**
 * 行情 ViewModel
 */
class MarketViewModel(
    private val repository: MarketRepository
) {
    private val viewModelScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    private val _uiState = MutableStateFlow(MarketUiState())
    val uiState: StateFlow<MarketUiState> = _uiState.asStateFlow()

    // 实时行情更新
    private val stocksMap = mutableMapOf<String, Stock>()

    init {
        observeWebSocketState()
        observeRealtimeQuotes()
        observeWebSocketErrors()
    }

    /**
     * 加载股票列表
     */
    fun loadStocks(category: StockCategory = StockCategory.WATCHLIST) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null, selectedCategory = category) }

            when (val result = repository.getStocks(category, page = 1, pageSize = 100)) {
                is ApiResult.Success -> {
                    val stocks = result.data.items
                    stocksMap.clear()
                    stocks.forEach { stock -> stocksMap[stock.symbol] = stock }

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            stocks = stocks,
                            error = null
                        )
                    }

                    // 如果是自选股，订阅实时行情
                    if (category == StockCategory.WATCHLIST && stocks.isNotEmpty()) {
                        subscribeRealtimeQuotes(stocks.map { it.symbol })
                    }
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
     * 刷新股票列表
     */
    fun refresh() {
        loadStocks(_uiState.value.selectedCategory)
    }

    /**
     * 切换分类
     */
    fun switchCategory(category: StockCategory) {
        if (_uiState.value.selectedCategory != category) {
            // 取消之前的订阅
            val currentSymbols = _uiState.value.stocks.map { it.symbol }
            if (currentSymbols.isNotEmpty()) {
                viewModelScope.launch {
                    repository.unsubscribeQuotes(currentSymbols)
                }
            }

            loadStocks(category)
        }
    }

    /**
     * 添加自选股
     */
    fun addToWatchlist(symbol: String) {
        viewModelScope.launch {
            when (repository.addToWatchlist(symbol)) {
                is ApiResult.Success -> {
                    // 刷新自选股列表
                    if (_uiState.value.selectedCategory == StockCategory.WATCHLIST) {
                        refresh()
                    }
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(error = "添加自选失败") }
                }
            }
        }
    }

    /**
     * 删除自选股
     */
    fun removeFromWatchlist(symbol: String) {
        viewModelScope.launch {
            when (repository.removeFromWatchlist(symbol)) {
                is ApiResult.Success -> {
                    // 从列表中移除
                    val updatedStocks = _uiState.value.stocks.filter { it.symbol != symbol }
                    _uiState.update { it.copy(stocks = updatedStocks) }

                    // 取消订阅
                    repository.unsubscribeQuotes(listOf(symbol))
                }
                is ApiResult.Error -> {
                    _uiState.update { it.copy(error = "删除自选失败") }
                }
            }
        }
    }

    /**
     * 连接 WebSocket（自动获取 token）
     */
    fun connectWebSocket() {
        viewModelScope.launch {
            // Token 从 TokenManager 获取，已在 HttpClient 中配置
            repository.connectWebSocket("")
        }
    }

    /**
     * 订阅实时行情
     */
    private fun subscribeRealtimeQuotes(symbols: List<String>) {
        viewModelScope.launch {
            repository.subscribeQuotes(symbols)
        }
    }

    /**
     * 观察 WebSocket 状态
     */
    private fun observeWebSocketState() {
        viewModelScope.launch {
            repository.wsState.collect { state ->
                _uiState.update { it.copy(wsConnected = state == WsState.CONNECTED) }
            }
        }
    }

    /**
     * 观察实时行情
     */
    private fun observeRealtimeQuotes() {
        viewModelScope.launch {
            repository.realtimeQuotes.collect { quote ->
                // 更新股票价格
                val stock = stocksMap[quote.symbol] ?: return@collect

                val updatedStock = stock.copy(
                    price = BigDecimal(quote.price),
                    change = BigDecimal(quote.change),
                    changePercent = BigDecimal(quote.changePercent),
                    volume = quote.volume,
                    timestamp = quote.timestamp
                )

                stocksMap[quote.symbol] = updatedStock

                // 更新 UI 状态
                _uiState.update {
                    it.copy(stocks = stocksMap.values.toList())
                }
            }
        }
    }

    /**
     * 观察 WebSocket 错误
     */
    private fun observeWebSocketErrors() {
        viewModelScope.launch {
            repository.wsErrors.collect { error ->
                _uiState.update { it.copy(error = error) }
            }
        }
    }

    /**
     * 清除错误
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    /**
     * 清理资源
     */
    fun onCleared() {
        viewModelScope.launch {
            repository.disconnectWebSocket()
        }
    }
}
