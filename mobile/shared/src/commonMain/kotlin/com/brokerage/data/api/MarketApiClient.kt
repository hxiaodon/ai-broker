package com.brokerage.data.api

import com.brokerage.data.api.ApiResult
import com.brokerage.domain.marketdata.*
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.http.*

/**
 * 行情 API 客户端
 */
class MarketApiClient(
    private val httpClient: HttpClient,
    private val baseUrl: String
) {
    /**
     * 获取股票列表
     */
    suspend fun getStocks(
        category: StockCategory = StockCategory.WATCHLIST,
        page: Int = 1,
        pageSize: Int = 20
    ): ApiResult<PagedResponse<Stock>> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/stocks") {
            parameter("category", category.value)
            parameter("page", page)
            parameter("pageSize", pageSize)
        }.body<ApiResponse<PagedResponse<Stock>>>().data!!
    }

    /**
     * 获取股票详情
     */
    suspend fun getStockDetail(symbol: String): ApiResult<StockDetail> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/stocks/$symbol")
            .body<ApiResponse<StockDetail>>().data!!
    }

    /**
     * 获取 K 线数据
     */
    suspend fun getKline(
        symbol: String,
        interval: KlineInterval = KlineInterval.ONE_DAY,
        startTime: Long? = null,
        endTime: Long? = null,
        limit: Int = 100
    ): ApiResult<List<Kline>> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/kline/$symbol") {
            parameter("interval", interval.value)
            startTime?.let { parameter("startTime", it) }
            endTime?.let { parameter("endTime", it) }
            parameter("limit", limit)
        }.body<ApiResponse<List<Kline>>>().data!!
    }

    /**
     * 获取订单簿深度
     */
    suspend fun getDepth(
        symbol: String,
        levels: Int = 5
    ): ApiResult<OrderBook> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/depth/$symbol") {
            parameter("levels", levels)
        }.body<ApiResponse<OrderBook>>().data!!
    }

    /**
     * 搜索股票
     */
    suspend fun searchStocks(
        query: String,
        limit: Int = 20
    ): ApiResult<List<SearchResult>> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/search") {
            parameter("q", query)
            parameter("limit", limit)
        }.body<ApiResponse<List<SearchResult>>>().data!!
    }

    /**
     * 获取热门搜索
     */
    suspend fun getHotSearches(limit: Int = 10): ApiResult<List<String>> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/hot-searches") {
            parameter("limit", limit)
        }.body<ApiResponse<List<String>>>().data!!
    }

    /**
     * 获取新闻
     */
    suspend fun getNews(
        symbol: String,
        page: Int = 1,
        pageSize: Int = 20
    ): ApiResult<PagedResponse<News>> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/news/$symbol") {
            parameter("page", page)
            parameter("pageSize", pageSize)
        }.body<ApiResponse<PagedResponse<News>>>().data!!
    }

    /**
     * 获取财报数据
     */
    suspend fun getFinancials(
        symbol: String,
        limit: Int = 8
    ): ApiResult<List<Financial>> = safeApiCall {
        httpClient.get("$baseUrl/api/v1/market/financials/$symbol") {
            parameter("limit", limit)
        }.body<ApiResponse<List<Financial>>>().data!!
    }

    /**
     * 添加自选股
     */
    suspend fun addToWatchlist(symbol: String): ApiResult<Unit> = safeApiCall {
        httpClient.post("$baseUrl/api/v1/market/watchlist") {
            contentType(ContentType.Application.Json)
            setBody(mapOf("symbol" to symbol))
        }.body<ApiResponse<Unit>>()
        Unit
    }

    /**
     * 删除自选股
     */
    suspend fun removeFromWatchlist(symbol: String): ApiResult<Unit> = safeApiCall {
        httpClient.delete("$baseUrl/api/v1/market/watchlist/$symbol")
            .body<ApiResponse<Unit>>()
        Unit
    }

    /**
     * 安全 API 调用封装
     */
    private suspend fun <T> safeApiCall(call: suspend () -> T): ApiResult<T> {
        return try {
            ApiResult.Success(call())
        } catch (e: Exception) {
            ApiResult.Error(mapException(e))
        }
    }

    /**
     * 异常映射
     */
    private fun mapException(e: Exception): ApiException {
        return when (e) {
            is io.ktor.client.network.sockets.ConnectTimeoutException,
            is io.ktor.client.network.sockets.SocketTimeoutException ->
                ApiException.NetworkError("Network timeout")
            is io.ktor.client.plugins.ClientRequestException -> {
                when (e.response.status.value) {
                    400 -> ApiException.BadRequest(e.message)
                    401 -> ApiException.Unauthorized()
                    404 -> ApiException.NotFound(e.message)
                    else -> ApiException.ServerError(e.response.status.value, e.message)
                }
            }
            is io.ktor.client.plugins.ServerResponseException ->
                ApiException.ServerError(e.response.status.value, e.message)
            else -> ApiException.Unknown(e.message ?: "Unknown error")
        }
    }
}
