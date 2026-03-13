package com.brokerage.domain.marketdata

import com.brokerage.common.decimal.BigDecimal
import com.brokerage.common.decimal.BigDecimalSerializer
import kotlinx.serialization.Serializable

/**
 * K线数据
 */
@Serializable
data class Kline(
    val timestamp: Long,
    @Serializable(with = BigDecimalSerializer::class) val open: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val high: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val low: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val close: BigDecimal,
    val volume: Long,
    val turnover: String? = null,
    val tradeCount: Int? = null
)

/**
 * K线周期
 */
enum class KlineInterval(val value: String) {
    ONE_MINUTE("1m"),
    FIVE_MINUTES("5m"),
    FIFTEEN_MINUTES("15m"),
    THIRTY_MINUTES("30m"),
    ONE_HOUR("1h"),
    ONE_DAY("1d"),
    ONE_WEEK("1w"),
    ONE_MONTH("1M")
}
