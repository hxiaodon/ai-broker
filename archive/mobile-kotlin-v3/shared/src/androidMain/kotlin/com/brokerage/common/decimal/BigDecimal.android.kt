package com.brokerage.common.decimal

import java.math.BigDecimal as JavaBigDecimal
import java.math.RoundingMode as JavaRoundingMode

/**
 * Android implementation using java.math.BigDecimal
 */
actual class BigDecimal(private val value: JavaBigDecimal) {
    actual constructor(value: String) : this(JavaBigDecimal(value))
    actual constructor(value: Double) : this(JavaBigDecimal.valueOf(value))
    actual constructor(value: Int) : this(JavaBigDecimal(value))
    actual constructor(value: Long) : this(JavaBigDecimal(value))

    actual fun add(other: BigDecimal): BigDecimal = BigDecimal(value.add(other.value))
    actual fun subtract(other: BigDecimal): BigDecimal = BigDecimal(value.subtract(other.value))
    actual fun multiply(other: BigDecimal): BigDecimal = BigDecimal(value.multiply(other.value))
    actual fun divide(other: BigDecimal, scale: Int, roundingMode: RoundingMode): BigDecimal =
        BigDecimal(value.divide(other.value, scale, roundingMode.toJava()))
    actual operator fun compareTo(other: BigDecimal): Int = value.compareTo(other.value)
    actual operator fun plus(other: BigDecimal): BigDecimal = BigDecimal(value.add(other.value))
    actual operator fun minus(other: BigDecimal): BigDecimal = BigDecimal(value.subtract(other.value))
    actual operator fun times(other: BigDecimal): BigDecimal = BigDecimal(value.multiply(other.value))
    actual operator fun div(other: BigDecimal): BigDecimal = BigDecimal(value.divide(other.value))
    actual fun abs(): BigDecimal = BigDecimal(value.abs())
    actual fun negate(): BigDecimal = BigDecimal(value.negate())
    actual fun setScale(scale: Int, roundingMode: RoundingMode): BigDecimal =
        BigDecimal(value.setScale(scale, roundingMode.toJava()))
    actual fun stripTrailingZeros(): BigDecimal = BigDecimal(value.stripTrailingZeros())
    actual fun scale(): Int = value.scale()
    actual fun toInt(): Int = value.toInt()
    actual fun toDouble(): Double = value.toDouble()
    actual fun toPlainString(): String = value.toPlainString()

    override fun toString(): String = value.toString()
    override fun equals(other: Any?): Boolean = other is BigDecimal && value == other.value
    override fun hashCode(): Int = value.hashCode()

    actual companion object {
        actual val ZERO: BigDecimal = BigDecimal(JavaBigDecimal.ZERO)
        actual val ONE: BigDecimal = BigDecimal(JavaBigDecimal.ONE)
        actual val TEN: BigDecimal = BigDecimal(JavaBigDecimal.TEN)
    }
}

/**
 * Android RoundingMode using java.math.RoundingMode
 */
actual enum class RoundingMode {
    UP,
    DOWN,
    CEILING,
    FLOOR,
    HALF_UP,
    HALF_DOWN,
    HALF_EVEN,
    UNNECESSARY;

    fun toJava(): JavaRoundingMode = when (this) {
        UP -> JavaRoundingMode.UP
        DOWN -> JavaRoundingMode.DOWN
        CEILING -> JavaRoundingMode.CEILING
        FLOOR -> JavaRoundingMode.FLOOR
        HALF_UP -> JavaRoundingMode.HALF_UP
        HALF_DOWN -> JavaRoundingMode.HALF_DOWN
        HALF_EVEN -> JavaRoundingMode.HALF_EVEN
        UNNECESSARY -> JavaRoundingMode.UNNECESSARY
    }
}
