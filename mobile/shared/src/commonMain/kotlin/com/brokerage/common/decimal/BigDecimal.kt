package com.brokerage.common.decimal

/**
 * Cross-platform BigDecimal wrapper
 * Android: wraps java.math.BigDecimal
 * iOS: wraps com.ionspin.kotlin.bignum.decimal.BigDecimal
 */
expect class BigDecimal {
    constructor(value: String)
    constructor(value: Double)
    constructor(value: Int)
    constructor(value: Long)

    fun add(other: BigDecimal): BigDecimal
    fun subtract(other: BigDecimal): BigDecimal
    fun multiply(other: BigDecimal): BigDecimal
    fun divide(other: BigDecimal, scale: Int, roundingMode: RoundingMode): BigDecimal
    operator fun compareTo(other: BigDecimal): Int
    operator fun plus(other: BigDecimal): BigDecimal
    operator fun minus(other: BigDecimal): BigDecimal
    operator fun times(other: BigDecimal): BigDecimal
    operator fun div(other: BigDecimal): BigDecimal
    fun abs(): BigDecimal
    fun negate(): BigDecimal
    fun setScale(scale: Int, roundingMode: RoundingMode): BigDecimal
    fun stripTrailingZeros(): BigDecimal
    fun scale(): Int
    fun toInt(): Int
    fun toDouble(): Double
    fun toPlainString(): String

    companion object {
        val ZERO: BigDecimal
        val ONE: BigDecimal
        val TEN: BigDecimal
    }
}

/**
 * Cross-platform RoundingMode
 */
expect enum class RoundingMode {
    UP,
    DOWN,
    CEILING,
    FLOOR,
    HALF_UP,
    HALF_DOWN,
    HALF_EVEN,
    UNNECESSARY
}
