package com.brokerage.domain.marketdata

import kotlinx.serialization.Serializable

/**
 * 盘口价格档位
 */
@Serializable
data class PriceLevel(
    val price: String,      // String to avoid precision loss
    val volume: Long,
    val orderCount: Int = 0
)

/**
 * 订单簿 (Order Book)
 */
@Serializable
data class OrderBook(
    val symbol: String,
    val market: Market,
    val bids: List<PriceLevel>,   // 买盘（价格从高到低）
    val asks: List<PriceLevel>,   // 卖盘（价格从低到高）
    val timestamp: Long
)

/**
 * WebSocket 深度数据
 */
@Serializable
data class DepthData(
    val symbol: String,
    val bids: List<PriceLevel>,
    val asks: List<PriceLevel>,
    val timestamp: Long
)
