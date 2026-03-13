package com.brokerage.common.format

import com.brokerage.common.decimal.*

/**
 * Formatting utilities for display
 */

/**
 * Format number with thousand separators
 * Example: 1234567.89 -> "1,234,567.89"
 */
fun BigDecimal.formatWithCommas(scale: Int = 2): String {
    val formatted = this.formatPrice(scale)
    val parts = formatted.split(".")
    val integerPart = parts[0]
    val decimalPart = if (parts.size > 1) ".${parts[1]}" else ""

    val withCommas = integerPart.reversed()
        .chunked(3)
        .joinToString(",")
        .reversed()

    return withCommas + decimalPart
}

/**
 * Format currency with symbol
 * Example: 1234.56 -> "$1,234.56"
 */
fun BigDecimal.formatCurrencyWithSymbol(
    symbol: String = "$",
    scale: Int = 2
): String {
    return "$symbol${this.formatWithCommas(scale)}"
}

/**
 * Format change with sign and color indicator
 * Returns: (formattedValue, isPositive)
 */
fun BigDecimal.formatChange(): Pair<String, Boolean> {
    val isPositive = this.isPositive()
    val sign = when {
        isPositive -> "+"
        this.isNegative() -> ""
        else -> ""
    }
    val formatted = "$sign${this.formatPrice(2)}"
    return Pair(formatted, isPositive)
}

/**
 * Format percentage change with sign
 * Example: 0.0523 -> "+5.23%"
 */
fun BigDecimal.formatPercentageChange(): Pair<String, Boolean> {
    val isPositive = this.isPositive()
    val sign = when {
        isPositive -> "+"
        this.isNegative() -> ""
        else -> ""
    }
    val formatted = "$sign${this.formatPrice(2)}%"
    return Pair(formatted, isPositive)
}

/**
 * Format large numbers with K/M/B suffix
 * Example: 1500000 -> "1.5M"
 */
fun BigDecimal.formatCompact(): String {
    val absValue = this.abs()
    return when {
        absValue >= BigDecimal(1_000_000_000) -> {
            "${(this / BigDecimal(1_000_000_000)).formatPrice(2)}B"
        }
        absValue >= BigDecimal(1_000_000) -> {
            "${(this / BigDecimal(1_000_000)).formatPrice(2)}M"
        }
        absValue >= BigDecimal(1_000) -> {
            "${(this / BigDecimal(1_000)).formatPrice(2)}K"
        }
        else -> this.formatPrice(2)
    }
}

/**
 * Format volume (shares)
 * Example: 1234567 -> "1.23M"
 */
fun Long.formatVolume(): String {
    return BigDecimal(this).formatCompact()
}

/**
 * Format market cap
 * Example: 2500000000000 -> "$2.50T"
 */
fun BigDecimal.formatMarketCap(currencySymbol: String = "$"): String {
    val absValue = this.abs()
    return when {
        absValue >= BigDecimal(1_000_000_000_000) -> {
            "$currencySymbol${(this / BigDecimal(1_000_000_000_000)).formatPrice(2)}T"
        }
        absValue >= BigDecimal(1_000_000_000) -> {
            "$currencySymbol${(this / BigDecimal(1_000_000_000)).formatPrice(2)}B"
        }
        absValue >= BigDecimal(1_000_000) -> {
            "$currencySymbol${(this / BigDecimal(1_000_000)).formatPrice(2)}M"
        }
        else -> "$currencySymbol${this.formatWithCommas(2)}"
    }
}

/**
 * Mask sensitive data
 */
object MaskFormatter {
    /**
     * Mask bank account number (show only last 4 digits)
     * Example: "1234567890" -> "****7890"
     */
    fun maskBankAccount(accountNumber: String): String {
        if (accountNumber.length <= 4) return accountNumber
        return "****${accountNumber.takeLast(4)}"
    }

    /**
     * Mask SSN (show only last 4 digits)
     * Example: "123-45-6789" -> "***-**-6789"
     */
    fun maskSSN(ssn: String): String {
        if (ssn.length <= 4) return ssn
        val lastFour = ssn.takeLast(4)
        return "***-**-$lastFour"
    }

    /**
     * Mask email (show first letter and domain)
     * Example: "john@example.com" -> "j***@example.com"
     */
    fun maskEmail(email: String): String {
        val parts = email.split("@")
        if (parts.size != 2) return email
        val local = parts[0]
        val domain = parts[1]
        if (local.isEmpty()) return email
        return "${local.first()}***@$domain"
    }

    /**
     * Mask phone number (show only last 4 digits)
     * Example: "+1-234-567-8900" -> "***-***-8900"
     */
    fun maskPhone(phone: String): String {
        if (phone.length <= 4) return phone
        return "***-***-${phone.takeLast(4)}"
    }
}

/**
 * Order side formatting
 */
enum class OrderSide {
    BUY, SELL
}

fun OrderSide.displayName(): String = when (this) {
    OrderSide.BUY -> "Buy"
    OrderSide.SELL -> "Sell"
}

fun OrderSide.displayColor(): String = when (this) {
    OrderSide.BUY -> "green"
    OrderSide.SELL -> "red"
}

/**
 * Order status formatting
 */
enum class OrderStatus {
    PENDING,
    SUBMITTED,
    PARTIALLY_FILLED,
    FILLED,
    CANCELLED,
    REJECTED
}

fun OrderStatus.displayName(): String = when (this) {
    OrderStatus.PENDING -> "Pending"
    OrderStatus.SUBMITTED -> "Submitted"
    OrderStatus.PARTIALLY_FILLED -> "Partially Filled"
    OrderStatus.FILLED -> "Filled"
    OrderStatus.CANCELLED -> "Cancelled"
    OrderStatus.REJECTED -> "Rejected"
}
