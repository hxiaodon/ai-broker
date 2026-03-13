package com.brokerage.domain.marketdata

import com.brokerage.common.decimal.BigDecimal
import com.brokerage.common.decimal.BigDecimalSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual

/**
 * 股票基本信息
 */
@Serializable
data class Stock(
    val symbol: String,
    val name: String,
    val nameCN: String,
    val market: Market,
    @Serializable(with = BigDecimalSerializer::class) val price: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val change: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val changePercent: BigDecimal,
    val marketCap: String,
    @Contextual val pe: BigDecimal?,
    @Contextual val pb: BigDecimal?,
    val volume: String,
    val timestamp: Long
)

/**
 * 市场类型
 */
@Serializable
enum class Market {
    US,  // 美股
    HK   // 港股
}

/**
 * 股票分类
 */
enum class StockCategory(val value: String) {
    WATCHLIST("watchlist"),  // 自选股
    US("us"),                // 美股
    HK("hk"),                // 港股
    HOT("hot")               // 热门股
}
