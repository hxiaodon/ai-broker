package com.brokerage.data.repository

import com.brokerage.common.decimal.BigDecimal
import com.brokerage.data.api.ApiResult
import com.brokerage.data.api.PagedResponse
import com.brokerage.data.websocket.WsState
import com.brokerage.domain.marketdata.DepthData
import com.brokerage.domain.marketdata.Financial
import com.brokerage.domain.marketdata.Kline
import com.brokerage.domain.marketdata.KlineInterval
import com.brokerage.domain.marketdata.Market
import com.brokerage.domain.marketdata.News
import com.brokerage.domain.marketdata.OrderBook
import com.brokerage.domain.marketdata.PriceLevel
import com.brokerage.domain.marketdata.QuoteData
import com.brokerage.domain.marketdata.SearchResult
import com.brokerage.domain.marketdata.Stock
import com.brokerage.domain.marketdata.StockCategory
import com.brokerage.domain.marketdata.StockDetail
import com.brokerage.domain.marketdata.TradeRecord
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.datetime.Clock
import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.roundToLong
import kotlin.random.Random

/**
 * Fake implementation of MarketRepository that returns hardcoded realistic stock data.
 * Used to run the app end-to-end without a real backend.
 */
class FakeMarketRepository : MarketRepository {

    // -------------------------------------------------------------------------
    // Static mock data
    // -------------------------------------------------------------------------

    private data class StockSeed(
        val symbol: String,
        val name: String,
        val nameCN: String,
        val market: Market,
        val price: String,
        val change: String,
        val changePercent: String,
        val marketCap: String,
        val volume: String,
        val pe: String?,
        val pb: String?,
        val open: String,
        val high: String,
        val low: String,
        val high52w: String,
        val low52w: String,
        val eps: String?,
        val dividend: String?,
        val avgVolume: String?
    )

    private val usStocks: List<StockSeed> = listOf(
        StockSeed(
            symbol = "AAPL",
            name = "Apple Inc",
            nameCN = "苹果",
            market = Market.US,
            price = "182.50",
            change = "1.23",
            changePercent = "0.68",
            marketCap = "2.85T",
            volume = "58.2M",
            pe = "28.4",
            pb = "45.2",
            open = "181.30",
            high = "183.15",
            low = "180.85",
            high52w = "199.62",
            low52w = "143.90",
            eps = "6.43",
            dividend = "0.96",
            avgVolume = "62.1M"
        ),
        StockSeed(
            symbol = "TSLA",
            name = "Tesla Inc",
            nameCN = "特斯拉",
            market = Market.US,
            price = "248.42",
            change = "-3.18",
            changePercent = "-1.26",
            marketCap = "791.3B",
            volume = "112.4M",
            pe = "72.1",
            pb = "12.3",
            open = "251.60",
            high = "252.80",
            low = "246.35",
            high52w = "299.29",
            low52w = "138.80",
            eps = "3.45",
            dividend = null,
            avgVolume = "98.7M"
        ),
        StockSeed(
            symbol = "NVDA",
            name = "NVIDIA Corp",
            nameCN = "英伟达",
            market = Market.US,
            price = "875.39",
            change = "12.45",
            changePercent = "1.44",
            marketCap = "2.16T",
            volume = "41.8M",
            pe = "64.8",
            pb = "38.9",
            open = "862.94",
            high = "879.05",
            low = "860.12",
            high52w = "974.00",
            low52w = "403.52",
            eps = "13.51",
            dividend = "0.16",
            avgVolume = "39.2M"
        ),
        StockSeed(
            symbol = "MSFT",
            name = "Microsoft Corp",
            nameCN = "微软",
            market = Market.US,
            price = "415.26",
            change = "2.87",
            changePercent = "0.70",
            marketCap = "3.09T",
            volume = "22.6M",
            pe = "37.2",
            pb = "13.8",
            open = "412.39",
            high = "416.50",
            low = "411.80",
            high52w = "468.35",
            low52w = "309.45",
            eps = "11.16",
            dividend = "3.00",
            avgVolume = "20.8M"
        ),
        StockSeed(
            symbol = "GOOGL",
            name = "Alphabet Inc",
            nameCN = "谷歌",
            market = Market.US,
            price = "175.98",
            change = "-0.45",
            changePercent = "-0.26",
            marketCap = "2.18T",
            volume = "25.3M",
            pe = "27.6",
            pb = "6.9",
            open = "176.43",
            high = "177.20",
            low = "175.10",
            high52w = "193.31",
            low52w = "130.67",
            eps = "6.38",
            dividend = null,
            avgVolume = "23.9M"
        )
    )

    private val hkStocks: List<StockSeed> = listOf(
        StockSeed(
            symbol = "00700",
            name = "Tencent Holdings",
            nameCN = "腾讯控股",
            market = Market.HK,
            price = "358.60",
            change = "4.20",
            changePercent = "1.18",
            marketCap = "3.42T",
            volume = "18.5M",
            pe = "22.3",
            pb = "3.8",
            open = "354.40",
            high = "360.00",
            low = "353.60",
            high52w = "402.00",
            low52w = "252.40",
            eps = "16.08",
            dividend = "3.40",
            avgVolume = "17.2M"
        ),
        StockSeed(
            symbol = "09988",
            name = "Alibaba Group",
            nameCN = "阿里巴巴",
            market = Market.HK,
            price = "78.45",
            change = "-1.35",
            changePercent = "-1.69",
            marketCap = "1.68T",
            volume = "32.1M",
            pe = "18.4",
            pb = "1.7",
            open = "79.80",
            high = "80.15",
            low = "77.95",
            high52w = "108.70",
            low52w = "66.00",
            eps = "4.26",
            dividend = null,
            avgVolume = "30.4M"
        ),
        StockSeed(
            symbol = "00941",
            name = "China Mobile",
            nameCN = "中国移动",
            market = Market.HK,
            price = "68.30",
            change = "0.80",
            changePercent = "1.19",
            marketCap = "1.37T",
            volume = "14.2M",
            pe = "10.2",
            pb = "1.2",
            open = "67.50",
            high = "68.55",
            low = "67.30",
            high52w = "76.40",
            low52w = "57.10",
            eps = "6.70",
            dividend = "4.71",
            avgVolume = "13.8M"
        )
    )

    private val allStocks: List<StockSeed> = usStocks + hkStocks

    private fun StockSeed.toStock(ts: Long): Stock = Stock(
        symbol = symbol,
        name = name,
        nameCN = nameCN,
        market = market,
        price = BigDecimal(price),
        change = BigDecimal(change),
        changePercent = BigDecimal(changePercent),
        marketCap = marketCap,
        pe = pe?.let { BigDecimal(it) },
        pb = pb?.let { BigDecimal(it) },
        volume = volume,
        timestamp = ts
    )

    private fun StockSeed.toStockDetail(ts: Long): StockDetail = StockDetail(
        symbol = symbol,
        name = name,
        nameCN = nameCN,
        market = market,
        price = BigDecimal(price),
        change = BigDecimal(change),
        changePercent = BigDecimal(changePercent),
        open = BigDecimal(open),
        high = BigDecimal(high),
        low = BigDecimal(low),
        close = BigDecimal(price),
        volume = volume,
        marketCap = marketCap,
        pe = pe?.let { BigDecimal(it) },
        pb = pb?.let { BigDecimal(it) },
        eps = eps?.let { BigDecimal(it) },
        dividend = dividend?.let { BigDecimal(it) },
        high52w = BigDecimal(high52w),
        low52w = BigDecimal(low52w),
        avgVolume = avgVolume,
        timestamp = ts
    )

    // -------------------------------------------------------------------------
    // REST methods
    // -------------------------------------------------------------------------

    override suspend fun getStocks(
        category: StockCategory,
        page: Int,
        pageSize: Int
    ): ApiResult<PagedResponse<Stock>> {
        val now = currentTimeMillis()
        val source = when (category) {
            StockCategory.US -> usStocks
            StockCategory.HK -> hkStocks
            StockCategory.HOT, StockCategory.WATCHLIST -> allStocks
        }
        val total = source.size
        val fromIndex = ((page - 1) * pageSize).coerceAtLeast(0)
        val toIndex = (fromIndex + pageSize).coerceAtMost(total)
        val items = if (fromIndex >= total) emptyList() else source.subList(fromIndex, toIndex).map { it.toStock(now) }
        return ApiResult.Success(
            PagedResponse(
                total = total,
                page = page,
                pageSize = pageSize,
                items = items
            )
        )
    }

    override suspend fun getStockDetail(symbol: String): ApiResult<StockDetail> {
        val now = currentTimeMillis()
        val seed = allStocks.find { it.symbol.equals(symbol, ignoreCase = true) }
            ?: return ApiResult.Error(com.brokerage.data.api.ApiException.NotFound("Symbol $symbol not found"))
        return ApiResult.Success(seed.toStockDetail(now))
    }

    override suspend fun getKline(
        symbol: String,
        interval: KlineInterval,
        startTime: Long?,
        endTime: Long?,
        limit: Int
    ): ApiResult<List<Kline>> {
        val seed = allStocks.find { it.symbol.equals(symbol, ignoreCase = true) }
        val basePrice = seed?.price?.toDouble() ?: 100.0

        val intervalMs = when (interval) {
            KlineInterval.ONE_MINUTE -> 60_000L
            KlineInterval.FIVE_MINUTES -> 5 * 60_000L
            KlineInterval.FIFTEEN_MINUTES -> 15 * 60_000L
            KlineInterval.THIRTY_MINUTES -> 30 * 60_000L
            KlineInterval.ONE_HOUR -> 60 * 60_000L
            KlineInterval.ONE_DAY -> 24 * 60 * 60_000L
            KlineInterval.ONE_WEEK -> 7 * 24 * 60 * 60_000L
            KlineInterval.ONE_MONTH -> 30L * 24 * 60 * 60_000L
        }

        val actualLimit = limit.coerceIn(1, 500)
        val endTs = endTime ?: currentTimeMillis()

        // Simple seeded pseudo-random walk so candles are deterministic per symbol
        var price = basePrice
        val klines = mutableListOf<Kline>()
        val symbolHash = symbol.hashCode().toLong()

        for (i in (actualLimit - 1) downTo 0) {
            val ts = endTs - i * intervalMs
            // Pseudo-random using linear congruential generator seeded by ts + symbolHash
            val seed1 = ((ts + symbolHash) * 1664525L + 1013904223L) and 0xFFFFFFFFL
            val seed2 = (seed1 * 1664525L + 1013904223L) and 0xFFFFFFFFL
            val seed3 = (seed2 * 1664525L + 1013904223L) and 0xFFFFFFFFL
            val seed4 = (seed3 * 1664525L + 1013904223L) and 0xFFFFFFFFL

            val changeRatio = ((seed1.toDouble() / 0xFFFFFFFFL) - 0.5) * 0.04 // ±2%
            val open = price
            val close = (open * (1.0 + changeRatio)).coerceAtLeast(0.01)
            val bodyHigh = maxOf(open, close)
            val bodyLow = minOf(open, close)
            val wickHigh = bodyHigh * (1.0 + (seed2.toDouble() / 0xFFFFFFFFL) * 0.01)
            val wickLow = bodyLow * (1.0 - (seed3.toDouble() / 0xFFFFFFFFL) * 0.01)
            val vol = (500_000L + (seed4 % 2_000_000L)).coerceAtLeast(100_000L)

            klines.add(
                Kline(
                    timestamp = ts,
                    open = BigDecimal(formatPrice(open)),
                    high = BigDecimal(formatPrice(wickHigh)),
                    low = BigDecimal(formatPrice(wickLow)),
                    close = BigDecimal(formatPrice(close)),
                    volume = vol,
                    turnover = null,
                    tradeCount = null
                )
            )
            price = close
        }
        return ApiResult.Success(klines)
    }

    override suspend fun searchStocks(query: String, limit: Int): ApiResult<List<SearchResult>> {
        val q = query.trim().lowercase()
        val results = allStocks
            .filter { it.symbol.lowercase().contains(q) || it.name.lowercase().contains(q) || it.nameCN.contains(q) }
            .take(limit)
            .map { SearchResult(symbol = it.symbol, name = it.name, nameCN = it.nameCN, market = it.market) }
        return ApiResult.Success(results)
    }

    override suspend fun getHotSearches(limit: Int): ApiResult<List<String>> {
        val hot = listOf("AAPL", "TSLA", "NVDA", "MSFT", "00700", "09988")
        return ApiResult.Success(hot.take(limit))
    }

    override suspend fun getNews(
        symbol: String,
        page: Int,
        pageSize: Int
    ): ApiResult<PagedResponse<News>> {
        val now = currentTimeMillis()
        val oneHour = 3_600_000L
        val newsItems = buildNewsFor(symbol, now, oneHour)
        val total = newsItems.size
        val fromIndex = ((page - 1) * pageSize).coerceAtLeast(0)
        val toIndex = (fromIndex + pageSize).coerceAtMost(total)
        val items = if (fromIndex >= total) emptyList() else newsItems.subList(fromIndex, toIndex)
        return ApiResult.Success(
            PagedResponse(
                total = total,
                page = page,
                pageSize = pageSize,
                items = items
            )
        )
    }

    override suspend fun getFinancials(symbol: String, limit: Int): ApiResult<List<Financial>> {
        val financials = buildFinancialsFor(symbol, limit)
        return ApiResult.Success(financials)
    }

    override suspend fun addToWatchlist(symbol: String): ApiResult<Unit> {
        return ApiResult.Success(Unit)
    }

    override suspend fun removeFromWatchlist(symbol: String): ApiResult<Unit> {
        return ApiResult.Success(Unit)
    }

    override suspend fun getDepth(symbol: String, levels: Int): ApiResult<OrderBook> {
        val now = currentTimeMillis()
        val seed = allStocks.find { it.symbol.equals(symbol, ignoreCase = true) }
        val midPrice = seed?.price?.toDouble() ?: 100.0
        val market = seed?.market ?: Market.US
        val scale = if (market == Market.HK) 3 else 4
        val tick = if (market == Market.HK) 0.02 else 0.01

        val bids = (1..levels).map { i ->
            val p = midPrice - i * tick
            PriceLevel(
                price = formatPriceScale(p, scale),
                volume = (10_000L - i * 800L).coerceAtLeast(500L),
                orderCount = (20 - i * 2).coerceAtLeast(1)
            )
        }
        val asks = (1..levels).map { i ->
            val p = midPrice + i * tick
            PriceLevel(
                price = formatPriceScale(p, scale),
                volume = (8_000L + i * 600L).coerceAtLeast(500L),
                orderCount = (15 + i).coerceAtLeast(1)
            )
        }
        return ApiResult.Success(
            OrderBook(
                symbol = symbol,
                market = market,
                bids = bids,
                asks = asks,
                timestamp = now
            )
        )
    }

    // -------------------------------------------------------------------------
    // WebSocket mock — ticker pushes price updates every 2 seconds
    // -------------------------------------------------------------------------

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    // Live prices that drift over time (symbol -> current price as Double)
    private val livePrices: MutableMap<String, Double> = allStocks.associate { it.symbol to it.price.toDouble() }.toMutableMap()

    // Base prices for change% calculation
    private val basePrices: Map<String, Double> = allStocks.associate { it.symbol to it.price.toDouble() }

    private val subscribedSymbols = mutableSetOf<String>()
    private val symbolsMutex = Mutex()

    private val subscribedDepthSymbols = mutableSetOf<String>()
    private val depthMutex = Mutex()

    private val _wsState = MutableStateFlow(WsState.CONNECTED)
    private val _quotes = MutableSharedFlow<QuoteData>(replay = 0, extraBufferCapacity = 64)
    private val _depth = MutableSharedFlow<DepthData>(replay = 0, extraBufferCapacity = 32)
    private val _wsErrors = MutableSharedFlow<String>(replay = 0, extraBufferCapacity = 8)

    override val wsState: StateFlow<WsState> = _wsState
    override val realtimeQuotes: Flow<QuoteData> = _quotes.asSharedFlow()
    override val realtimeDepth: Flow<DepthData> = _depth.asSharedFlow()
    override val realtimeTrades: Flow<TradeRecord> = MutableSharedFlow()
    override val wsErrors: Flow<String> = _wsErrors.asSharedFlow()

    init {
        startTicker()
    }

    private fun startTicker() {
        scope.launch {
            var tickCount = 0
            while (true) {
                delay(2_000L)
                tickCount++
                val symbols = symbolsMutex.withLock { subscribedSymbols.toList() }
                if (symbols.isEmpty()) continue

                val now = Clock.System.now().toEpochMilliseconds()
                for (symbol in symbols) {
                    val base = basePrices[symbol] ?: continue
                    val current = livePrices[symbol] ?: base

                    // Random walk: ±0.3% per tick, mean-reverting toward base
                    val noise = (Random.nextDouble() - 0.5) * 0.006
                    val revert = (base - current) / base * 0.02
                    val next = (current * (1.0 + noise + revert)).coerceAtLeast(base * 0.5)
                    livePrices[symbol] = next

                    val change = next - base
                    val changePct = change / base * 100.0
                    val mockVolume = (50_000_000L + abs(now % 20_000_000L))

                    _quotes.emit(
                        QuoteData(
                            symbol = symbol,
                            price = formatDouble(next, 2),
                            change = formatDouble(change, 2),
                            changePercent = formatDouble(changePct, 2),
                            volume = "${mockVolume / 1_000_000}M",
                            timestamp = now,
                        )
                    )
                }

                // Emit depth data every 3 ticks (~6 seconds)
                if (tickCount % 3 == 0) {
                    val depthSymbols = depthMutex.withLock { subscribedDepthSymbols.toList() }
                    for (symbol in depthSymbols) {
                        val now2 = Clock.System.now().toEpochMilliseconds()
                        _depth.emit(buildDepthData(symbol, now2))
                    }
                }
            }
        }
    }

    private fun buildDepthData(symbol: String, now: Long): DepthData {
        val seed = allStocks.find { it.symbol.equals(symbol, ignoreCase = true) }
        val midPrice = livePrices[symbol] ?: seed?.price?.toDouble() ?: 100.0
        val market = seed?.market ?: Market.US
        val scale = if (market == Market.HK) 3 else 4
        val tick = if (market == Market.HK) 0.02 else 0.01
        val levels = 5

        val bids = (1..levels).map { i ->
            val p = midPrice - i * tick
            val volVariation = (Random.nextDouble() * 0.2 - 0.1)  // ±10%
            val baseVol = (10_000L - i * 800L).coerceAtLeast(500L)
            PriceLevel(
                price = formatPriceScale(p, scale),
                volume = (baseVol * (1.0 + volVariation)).toLong().coerceAtLeast(100L),
                orderCount = (20 - i * 2).coerceAtLeast(1)
            )
        }
        val asks = (1..levels).map { i ->
            val p = midPrice + i * tick
            val volVariation = (Random.nextDouble() * 0.2 - 0.1)
            val baseVol = (8_000L + i * 600L).coerceAtLeast(500L)
            PriceLevel(
                price = formatPriceScale(p, scale),
                volume = (baseVol * (1.0 + volVariation)).toLong().coerceAtLeast(100L),
                orderCount = (15 + i).coerceAtLeast(1)
            )
        }
        return DepthData(symbol = symbol, bids = bids, asks = asks, timestamp = now)
    }

    override suspend fun connectWebSocket(token: String) {
        _wsState.value = WsState.CONNECTED
    }

    override suspend fun disconnectWebSocket() {
        _wsState.value = WsState.DISCONNECTED
        symbolsMutex.withLock { subscribedSymbols.clear() }
        depthMutex.withLock { subscribedDepthSymbols.clear() }
    }

    override suspend fun subscribeQuotes(symbols: List<String>) {
        symbolsMutex.withLock { subscribedSymbols.addAll(symbols) }
    }

    override suspend fun unsubscribeQuotes(symbols: List<String>) {
        symbolsMutex.withLock { subscribedSymbols.removeAll(symbols.toSet()) }
    }

    override suspend fun subscribeDepth(symbol: String) {
        depthMutex.withLock { subscribedDepthSymbols.add(symbol) }
        // Emit initial snapshot in a new coroutine to let the collector attach first
        scope.launch {
            delay(100L)
            val now = Clock.System.now().toEpochMilliseconds()
            _depth.emit(buildDepthData(symbol, now))
        }
    }

    override suspend fun unsubscribeDepth(symbol: String) {
        depthMutex.withLock { subscribedDepthSymbols.remove(symbol) }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private fun currentTimeMillis(): Long = Clock.System.now().toEpochMilliseconds()

    private fun formatPrice(value: Double): String = formatDouble(value, 4)

    private fun formatPriceScale(value: Double, scale: Int): String = formatDouble(value, scale)

    private fun formatDouble(value: Double, decimals: Int): String {
        val sign = if (value < 0) "-" else ""
        val abs = kotlin.math.abs(value)
        val factor = 10.0.pow(decimals)
        val rounded = (abs * factor).roundToLong().toDouble() / factor
        val intPart = rounded.toLong()
        val fracPart = ((rounded - intPart) * factor).roundToLong()
        val fracStr = fracPart.toString().padStart(decimals, '0')
        return "$sign$intPart.$fracStr"
    }

    private fun buildNewsFor(symbol: String, now: Long, oneHour: Long): List<News> {
        val base = when (symbol.uppercase()) {
            "AAPL" -> listOf(
                News("n1", "Apple Reports Record Q1 Revenue", "Apple Inc. posted record quarterly revenue driven by strong iPhone sales and services growth.", "Reuters", "https://reuters.com/aapl-q1", now - oneHour, null),
                News("n2", "Apple Vision Pro Sales Exceed Expectations", "Analysts raise price targets after Vision Pro pre-orders surpass forecasts.", "Bloomberg", "https://bloomberg.com/aapl-vp", now - 2 * oneHour, null),
                News("n3", "Apple Expands Manufacturing in India", "Apple accelerates supply chain diversification with new India facilities.", "WSJ", "https://wsj.com/aapl-india", now - 5 * oneHour, null)
            )
            "TSLA" -> listOf(
                News("n1", "Tesla Deliveries Miss Q3 Estimates", "Tesla delivered fewer vehicles than analysts expected amid production challenges.", "CNBC", "https://cnbc.com/tsla-q3", now - oneHour, null),
                News("n2", "Tesla Full Self-Driving Beta Update", "Tesla releases updated FSD software improving highway performance.", "TechCrunch", "https://techcrunch.com/tsla-fsd", now - 3 * oneHour, null),
                News("n3", "Tesla Opens New Gigafactory in Mexico", "New facility expected to significantly boost production capacity.", "Reuters", "https://reuters.com/tsla-giga", now - 6 * oneHour, null)
            )
            "NVDA" -> listOf(
                News("n1", "NVIDIA Data Center Revenue Soars on AI Demand", "NVIDIA posts triple-digit data center revenue growth fueled by AI chip demand.", "Bloomberg", "https://bloomberg.com/nvda-dc", now - oneHour, null),
                News("n2", "NVIDIA H100 Chips Remain in Short Supply", "Enterprise customers face long wait times for NVIDIA's flagship AI accelerator.", "Reuters", "https://reuters.com/nvda-h100", now - 4 * oneHour, null),
                News("n3", "NVIDIA Partners with Leading Cloud Providers", "Major cloud platforms expand NVIDIA GPU capacity to meet customer demand.", "WSJ", "https://wsj.com/nvda-cloud", now - 8 * oneHour, null)
            )
            "00700" -> listOf(
                News("n1", "Tencent Gaming Revenue Rebounds in Q2", "Tencent's gaming division returns to growth led by domestic and international titles.", "SCMP", "https://scmp.com/00700-q2", now - oneHour, null),
                News("n2", "Tencent Expands AI Investment", "Tencent announces significant capital allocation toward AI infrastructure.", "Bloomberg", "https://bloomberg.com/00700-ai", now - 3 * oneHour, null),
                News("n3", "WeChat Pay Users Reach 900 Million", "Tencent's payment platform continues strong growth in active users.", "Reuters", "https://reuters.com/wechat-pay", now - 6 * oneHour, null)
            )
            "09988" -> listOf(
                News("n1", "Alibaba Cloud Revenue Grows 21%", "Alibaba's cloud division posts strong growth driven by AI and enterprise demand.", "SCMP", "https://scmp.com/09988-cloud", now - oneHour, null),
                News("n2", "Alibaba Raises Annual Revenue Forecast", "Strong e-commerce performance leads management to upgrade full-year guidance.", "Reuters", "https://reuters.com/09988-forecast", now - 4 * oneHour, null),
                News("n3", "Alibaba Restructuring Unlocks Value", "Strategic reorganization of business units aims to improve capital allocation.", "Bloomberg", "https://bloomberg.com/09988-reorg", now - 7 * oneHour, null)
            )
            else -> listOf(
                News("n1", "Market Update: $symbol in Focus", "Investors watch $symbol closely as macro conditions drive sector rotation.", "MarketWatch", "https://marketwatch.com/$symbol", now - oneHour, null),
                News("n2", "Analyst Upgrades $symbol to Buy", "Wall Street firm raises rating citing improved earnings visibility.", "Barron's", "https://barrons.com/$symbol-upgrade", now - 3 * oneHour, null),
                News("n3", "$symbol Announces Share Buyback Program", "Board authorizes repurchase of up to 5% of outstanding shares.", "PRNewswire", "https://prnewswire.com/$symbol-buyback", now - 6 * oneHour, null)
            )
        }
        return base
    }

    private fun buildFinancialsFor(symbol: String, limit: Int): List<Financial> {
        val now = currentTimeMillis()
        val oneDay = 86_400_000L

        // Base quarterly figures per symbol (revenue in billions USD, net income in billions)
        val (revBase, niBase, epsBase) = when (symbol.uppercase()) {
            "AAPL" -> Triple("119.58", "29.96", "1.89")
            "TSLA" -> Triple("25.18", "1.85", "0.53")
            "NVDA" -> Triple("22.10", "12.29", "4.93")
            "MSFT" -> Triple("62.02", "21.87", "2.94")
            "GOOGL" -> Triple("86.31", "23.66", "1.89")
            "00700" -> Triple("161.07", "36.24", "3.84")  // billions HKD
            "09988" -> Triple("260.35", "28.52", "14.22") // billions HKD
            "00941" -> Triple("256.00", "26.00", "10.30") // billions HKD
            else -> Triple("10.00", "2.00", "1.00")
        }

        val actualLimit = limit.coerceIn(1, 12)
        val quarters = listOf(
            Pair(2024, 4), Pair(2024, 3), Pair(2024, 2), Pair(2024, 1),
            Pair(2023, 4), Pair(2023, 3), Pair(2023, 2), Pair(2023, 1),
            Pair(2022, 4), Pair(2022, 3), Pair(2022, 2), Pair(2022, 1)
        )

        return quarters.take(actualLimit).mapIndexed { index, (year, quarter) ->
            // Slight variation per quarter using index
            val variation = 1.0 + (index % 4 - 1.5) * 0.05
            val rev = (revBase.toDouble() * variation)
            val ni = (niBase.toDouble() * variation)
            val eps = (epsBase.toDouble() * variation)
            val reportTs = now - index * 90 * oneDay

            Financial(
                symbol = symbol,
                fiscalYear = year,
                fiscalQuarter = quarter,
                revenue = BigDecimal(formatDouble(rev, 2)),
                netIncome = BigDecimal(formatDouble(ni, 2)),
                eps = BigDecimal(formatDouble(eps, 2)),
                reportDate = reportTs
            )
        }
    }
}
