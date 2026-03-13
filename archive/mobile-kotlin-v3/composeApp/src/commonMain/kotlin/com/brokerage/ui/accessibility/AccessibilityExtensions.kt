package com.brokerage.ui.accessibility

import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics

/**
 * 无障碍扩展函数
 */

/**
 * 为组件添加内容描述（用于屏幕阅读器）
 */
fun Modifier.accessibilityLabel(label: String): Modifier {
    return this.semantics {
        contentDescription = label
    }
}

/**
 * 为价格添加无障碍描述
 */
fun formatPriceForAccessibility(price: String, symbol: String): String {
    return "$symbol 当前价格 $price 美元"
}

/**
 * 为涨跌幅添加无障碍描述
 */
fun formatChangeForAccessibility(
    change: String,
    changePercent: String,
    isUp: Boolean
): String {
    val direction = if (isUp) "上涨" else "下跌"
    return "$direction $change 美元，涨跌幅 $changePercent 百分点"
}

/**
 * 为按钮添加无障碍描述
 */
fun formatButtonForAccessibility(
    label: String,
    enabled: Boolean = true,
    selected: Boolean = false
): String {
    val state = when {
        !enabled -> "，已禁用"
        selected -> "，已选中"
        else -> ""
    }
    return "$label 按钮$state"
}

/**
 * 为交易操作添加无障碍描述
 */
fun formatTradeActionForAccessibility(
    action: String,
    symbol: String,
    quantity: String,
    price: String
): String {
    return "$action $symbol，数量 $quantity 股，价格 $price 美元"
}

/**
 * 为提醒添加无障碍描述
 */
fun formatAlertForAccessibility(
    symbol: String,
    condition: String,
    targetPrice: String,
    isEnabled: Boolean
): String {
    val status = if (isEnabled) "已启用" else "已禁用"
    return "$symbol 价格提醒，条件：$condition $targetPrice 美元，状态：$status"
}
