package com.brokerage.domain.alert

import com.brokerage.common.decimal.BigDecimal
import kotlinx.datetime.Clock

/**
 * 价格提醒
 */
data class PriceAlert(
    val id: String,
    val symbol: String,
    val stockName: String,
    val targetPrice: BigDecimal,
    val condition: AlertCondition,
    val isEnabled: Boolean = true,
    val isTriggered: Boolean = false,
    val createdAt: Long = Clock.System.now().toEpochMilliseconds(),
    val triggeredAt: Long? = null,
    val note: String? = null
)

/**
 * 提醒条件
 */
enum class AlertCondition {
    ABOVE,      // 价格高于
    BELOW,      // 价格低于
    CHANGE_UP,  // 涨幅超过
    CHANGE_DOWN // 跌幅超过
}

/**
 * 提醒类型
 */
enum class AlertType {
    PRICE,      // 价格提醒
    PERCENT     // 百分比提醒
}
