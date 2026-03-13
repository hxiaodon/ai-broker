package com.brokerage.domain.marketdata

import kotlinx.serialization.Serializable

/**
 * 交易状态
 */
@Serializable
enum class TradingStatus {
    UNKNOWN,
    PRE_MARKET,       // 盘前
    TRADING,          // 交易中
    LUNCH_BREAK,      // 午间休市（港股）
    POST_MARKET,      // 盘后
    CLOSED,           // 已收盘
    HALTED,           // 停牌
    SUSPENDED         // 暂停交易
}

/**
 * 市场时段
 */
@Serializable
enum class MarketSession {
    UNKNOWN,
    PRE_MARKET,       // 盘前交易
    REGULAR,          // 常规交易
    POST_MARKET,      // 盘后交易
    EXTENDED          // 延长交易
}
