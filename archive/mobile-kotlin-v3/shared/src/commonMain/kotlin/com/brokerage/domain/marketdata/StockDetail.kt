package com.brokerage.domain.marketdata

import com.brokerage.common.decimal.BigDecimal
import com.brokerage.common.decimal.BigDecimalSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.Contextual

/**
 * 股票详情
 */
@Serializable
data class StockDetail(
    val symbol: String,
    val name: String,
    val nameCN: String,
    val market: Market,
    @Serializable(with = BigDecimalSerializer::class) val price: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val change: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val changePercent: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val open: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val high: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val low: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val close: BigDecimal,
    val volume: String,
    val marketCap: String,
    @Serializable(with = BigDecimalSerializer::class) @Contextual val pe: BigDecimal?,
    @Serializable(with = BigDecimalSerializer::class) @Contextual val pb: BigDecimal?,
    @Serializable(with = BigDecimalSerializer::class) @Contextual val eps: BigDecimal?,
    @Serializable(with = BigDecimalSerializer::class) @Contextual val dividend: BigDecimal?,
    @Contextual val high52w: BigDecimal?,
    @Contextual val low52w: BigDecimal?,
    val avgVolume: String?,
    val timestamp: Long
)

/**
 * 搜索结果
 */
@Serializable
data class SearchResult(
    val symbol: String,
    val name: String,
    val nameCN: String,
    val market: Market
)

/**
 * 新闻
 */
@Serializable
data class News(
    val id: String,
    val title: String,
    val summary: String,
    val source: String,
    val url: String,
    val publishedAt: Long,
    val imageUrl: String?
)

/**
 * 财报数据
 */
@Serializable
data class Financial(
    val symbol: String,
    val fiscalYear: Int,
    val fiscalQuarter: Int,
    @Serializable(with = BigDecimalSerializer::class) val revenue: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val netIncome: BigDecimal,
    @Serializable(with = BigDecimalSerializer::class) val eps: BigDecimal,
    val reportDate: Long
)
