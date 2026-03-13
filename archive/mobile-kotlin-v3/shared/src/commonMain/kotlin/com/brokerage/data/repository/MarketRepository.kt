package com.brokerage.data.repository

import com.brokerage.data.api.ApiResult
import com.brokerage.data.api.MarketApiClient
import com.brokerage.data.api.PagedResponse
import com.brokerage.data.websocket.MarketWebSocketClient
import com.brokerage.data.websocket.WsState
import com.brokerage.domain.marketdata.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/**
 * 行情数据仓库
 */
interface MarketRepository {
    // REST API
    suspend fun getStocks(category: StockCategory, page: Int, pageSize: Int): ApiResult<PagedResponse<Stock>>
    suspend fun getStockDetail(symbol: String): ApiResult<StockDetail>
    suspend fun getKline(symbol: String, interval: KlineInterval, startTime: Long?, endTime: Long?, limit: Int): ApiResult<List<Kline>>
    suspend fun searchStocks(query: String, limit: Int): ApiResult<List<SearchResult>>
    suspend fun getHotSearches(limit: Int): ApiResult<List<String>>
    suspend fun getNews(symbol: String, page: Int, pageSize: Int): ApiResult<PagedResponse<News>>
    suspend fun getFinancials(symbol: String, limit: Int): ApiResult<List<Financial>>
    suspend fun addToWatchlist(symbol: String): ApiResult<Unit>
    suspend fun removeFromWatchlist(symbol: String): ApiResult<Unit>
    suspend fun getDepth(symbol: String, levels: Int = 5): ApiResult<OrderBook>

    // WebSocket
    suspend fun connectWebSocket(token: String)
    suspend fun disconnectWebSocket()
    suspend fun subscribeQuotes(symbols: List<String>)
    suspend fun unsubscribeQuotes(symbols: List<String>)
    suspend fun subscribeDepth(symbol: String)
    suspend fun unsubscribeDepth(symbol: String)
    val wsState: StateFlow<WsState>
    val realtimeQuotes: Flow<QuoteData>
    val realtimeDepth: Flow<DepthData>
    val realtimeTrades: Flow<TradeRecord>
    val wsErrors: Flow<String>
}

/**
 * 行情数据仓库实现
 */
class MarketRepositoryImpl(
    private val apiClient: MarketApiClient,
    private val wsClient: MarketWebSocketClient
) : MarketRepository {

    override suspend fun getStocks(
        category: StockCategory,
        page: Int,
        pageSize: Int
    ): ApiResult<PagedResponse<Stock>> {
        return apiClient.getStocks(category, page, pageSize)
    }

    override suspend fun getStockDetail(symbol: String): ApiResult<StockDetail> {
        return apiClient.getStockDetail(symbol)
    }

    override suspend fun getKline(
        symbol: String,
        interval: KlineInterval,
        startTime: Long?,
        endTime: Long?,
        limit: Int
    ): ApiResult<List<Kline>> {
        return apiClient.getKline(symbol, interval, startTime, endTime, limit)
    }

    override suspend fun searchStocks(query: String, limit: Int): ApiResult<List<SearchResult>> {
        return apiClient.searchStocks(query, limit)
    }

    override suspend fun getHotSearches(limit: Int): ApiResult<List<String>> {
        return apiClient.getHotSearches(limit)
    }

    override suspend fun getNews(
        symbol: String,
        page: Int,
        pageSize: Int
    ): ApiResult<PagedResponse<News>> {
        return apiClient.getNews(symbol, page, pageSize)
    }

    override suspend fun getFinancials(symbol: String, limit: Int): ApiResult<List<Financial>> {
        return apiClient.getFinancials(symbol, limit)
    }

    override suspend fun addToWatchlist(symbol: String): ApiResult<Unit> {
        return apiClient.addToWatchlist(symbol)
    }

    override suspend fun removeFromWatchlist(symbol: String): ApiResult<Unit> {
        return apiClient.removeFromWatchlist(symbol)
    }

    override suspend fun getDepth(symbol: String, levels: Int): ApiResult<OrderBook> {
        return apiClient.getDepth(symbol, levels)
    }

    override suspend fun connectWebSocket(token: String) {
        wsClient.connect(token)
    }

    override suspend fun disconnectWebSocket() {
        wsClient.disconnect()
    }

    override suspend fun subscribeQuotes(symbols: List<String>) {
        wsClient.subscribe(symbols)
    }

    override suspend fun unsubscribeQuotes(symbols: List<String>) {
        wsClient.unsubscribe(symbols)
    }

    override suspend fun subscribeDepth(symbol: String) {
        wsClient.subscribeDepth(symbol)
    }

    override suspend fun unsubscribeDepth(symbol: String) {
        wsClient.unsubscribeDepth(symbol)
    }

    override val wsState: StateFlow<WsState> = wsClient.state

    override val realtimeQuotes: Flow<QuoteData> = wsClient.quotes

    override val realtimeDepth: Flow<DepthData> = wsClient.depth

    override val realtimeTrades: Flow<TradeRecord> = wsClient.trades

    override val wsErrors: Flow<String> = wsClient.errors
}
