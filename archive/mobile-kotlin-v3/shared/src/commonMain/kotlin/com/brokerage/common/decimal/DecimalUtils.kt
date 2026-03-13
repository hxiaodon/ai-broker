package com.brokerage.common.decimal

/**
 * Financial calculation utilities using BigDecimal for precision.
 * NEVER use Double or Float for money calculations.
 */

/**
 * Create BigDecimal from String safely
 */
fun String.toBigDecimalOrZero(): BigDecimal {
    return try {
        BigDecimal(this)
    } catch (e: NumberFormatException) {
        BigDecimal.ZERO
    }
}

/**
 * Format price with specified decimal places
 * @param scale Number of decimal places (default: 2)
 * @param roundingMode Rounding mode (default: HALF_UP)
 */
fun BigDecimal.formatPrice(
    scale: Int = 2,
    roundingMode: RoundingMode = RoundingMode.HALF_UP
): String {
    return this.setScale(scale, roundingMode).toPlainString()
}

/**
 * Format US stock price (4 decimal places)
 */
fun BigDecimal.formatUSStockPrice(): String {
    return this.formatPrice(scale = 4)
}

/**
 * Format HK stock price (3 decimal places)
 */
fun BigDecimal.formatHKStockPrice(): String {
    return this.formatPrice(scale = 3)
}

/**
 * Format currency amount (2 decimal places)
 */
fun BigDecimal.formatCurrency(): String {
    return this.formatPrice(scale = 2)
}

/**
 * Format percentage (2 decimal places with % sign)
 */
fun BigDecimal.formatPercentage(): String {
    return "${this.formatPrice(scale = 2)}%"
}

/**
 * Calculate percentage change
 * @param oldValue Original value
 * @param newValue New value
 * @return Percentage change as BigDecimal
 */
fun calculatePercentageChange(oldValue: BigDecimal, newValue: BigDecimal): BigDecimal {
    if (oldValue == BigDecimal.ZERO) return BigDecimal.ZERO
    return ((newValue - oldValue) / oldValue) * BigDecimal(100)
}

/**
 * Safe division with default value
 */
fun BigDecimal.safeDivide(
    divisor: BigDecimal,
    scale: Int = 6,
    roundingMode: RoundingMode = RoundingMode.HALF_UP,
    defaultValue: BigDecimal = BigDecimal.ZERO
): BigDecimal {
    return if (divisor == BigDecimal.ZERO) {
        defaultValue
    } else {
        this.divide(divisor, scale, roundingMode)
    }
}

/**
 * Check if value is positive
 */
fun BigDecimal.isPositive(): Boolean = this > BigDecimal.ZERO

/**
 * Check if value is negative
 */
fun BigDecimal.isNegative(): Boolean = this < BigDecimal.ZERO

/**
 * Check if value is zero
 */
fun BigDecimal.isZero(): Boolean = this.compareTo(BigDecimal.ZERO) == 0

/**
 * Absolute value
 */
fun BigDecimal.abs(): BigDecimal = this.abs()

/**
 * Round to specified decimal places
 */
fun BigDecimal.round(
    scale: Int,
    roundingMode: RoundingMode = RoundingMode.HALF_UP
): BigDecimal {
    return this.setScale(scale, roundingMode)
}
