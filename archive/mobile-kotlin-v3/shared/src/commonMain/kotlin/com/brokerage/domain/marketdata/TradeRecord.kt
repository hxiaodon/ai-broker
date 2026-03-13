package com.brokerage.domain.marketdata

import kotlinx.serialization.Serializable

/**
 * 成交方向
 */
@Serializable
enum class TradeSide {
    UNKNOWN,
    BUY,
    SELL
}

/**
 * 成交记录
 */
@Serializable
data class TradeRecord(
    val symbol: String,
    val price: String,      // String to avoid precision loss
    val volume: Long,
    val timestamp: Long,
    val tradeId: String? = null,
    val side: TradeSide = TradeSide.UNKNOWN
)
