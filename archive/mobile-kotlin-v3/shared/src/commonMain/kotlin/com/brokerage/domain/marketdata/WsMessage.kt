package com.brokerage.domain.marketdata

import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable

/**
 * WebSocket 消息类型
 */
@Serializable
sealed class WsMessage {
    /**
     * 订阅消息
     */
    @Serializable
    data class Subscribe(
        val action: String = "subscribe",
        val symbols: List<String>
    ) : WsMessage()

    /**
     * 取消订阅消息
     */
    @Serializable
    data class Unsubscribe(
        val action: String = "unsubscribe",
        val symbols: List<String>
    ) : WsMessage()

    /**
     * 心跳消息
     */
    @Serializable
    data class Ping(
        val action: String = "ping",
        val timestamp: Long = Clock.System.now().toEpochMilliseconds()
    ) : WsMessage()

    /**
     * 心跳响应
     */
    @Serializable
    data class Pong(
        val action: String = "pong",
        val timestamp: Long
    ) : WsMessage()

    /**
     * 实时行情推送
     */
    @Serializable
    data class Quote(
        val action: String = "quote",
        val data: QuoteData
    ) : WsMessage()

    /**
     * 错误消息
     */
    @Serializable
    data class Error(
        val action: String = "error",
        val code: Int,
        val message: String
    ) : WsMessage()

    /**
     * 订阅深度行情
     */
    @Serializable
    data class SubscribeDepth(
        val action: String = "subscribe_depth",
        val symbol: String
    ) : WsMessage()

    /**
     * 取消订阅深度行情
     */
    @Serializable
    data class UnsubscribeDepth(
        val action: String = "unsubscribe_depth",
        val symbol: String
    ) : WsMessage()

    /**
     * 深度行情推送
     */
    @Serializable
    data class Depth(
        val action: String = "depth",
        val data: DepthData
    ) : WsMessage()

    /**
     * 成交记录推送
     */
    @Serializable
    data class Trade(
        val action: String = "trade",
        val data: TradeRecord
    ) : WsMessage()
}

/**
 * 实时行情数据
 */
@Serializable
data class QuoteData(
    val symbol: String,
    val price: String,          // 使用 String 避免精度丢失
    val change: String,
    val changePercent: String,
    val volume: String,
    val timestamp: Long,
    val bidPrice: String? = null,
    val askPrice: String? = null,
    val bidSize: Long? = null,
    val askSize: Long? = null,
    val open: String? = null,
    val high: String? = null,
    val low: String? = null,
    val prevClose: String? = null,
    val turnover: String? = null,
    val status: TradingStatus? = null,
    val session: MarketSession? = null
)
