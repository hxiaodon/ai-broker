package com.brokerage.common.decimal

import com.ionspin.kotlin.bignum.decimal.BigDecimal as IonBigDecimal
import com.ionspin.kotlin.bignum.decimal.RoundingMode as IonRoundingMode

/**
 * iOS implementation using com.ionspin.kotlin.bignum.decimal.BigDecimal
 */
actual class BigDecimal(private val value: IonBigDecimal) {
    actual constructor(value: String) : this(IonBigDecimal.parseString(value))
    actual constructor(value: Double) : this(IonBigDecimal.fromDouble(value))
    actual constructor(value: Int) : this(IonBigDecimal.fromInt(value))
    actual constructor(value: Long) : this(IonBigDecimal.fromLong(value))

    actual fun add(other: BigDecimal): BigDecimal = BigDecimal(value.add(other.value))
    actual fun subtract(other: BigDecimal): BigDecimal = BigDecimal(value.subtract(other.value))
    actual fun multiply(other: BigDecimal): BigDecimal = BigDecimal(value.multiply(other.value))
    actual fun divide(other: BigDecimal, scale: Int, roundingMode: RoundingMode): BigDecimal {
        val decimalMode = com.ionspin.kotlin.bignum.decimal.DecimalMode(
            decimalPrecision = scale.toLong(),
            roundingMode = roundingMode.toIon()
        )
        return BigDecimal(value.divide(other.value, decimalMode))
    }
    actual operator fun compareTo(other: BigDecimal): Int = value.compareTo(other.value)
    actual operator fun plus(other: BigDecimal): BigDecimal = BigDecimal(value.add(other.value))
    actual operator fun minus(other: BigDecimal): BigDecimal = BigDecimal(value.subtract(other.value))
    actual operator fun times(other: BigDecimal): BigDecimal = BigDecimal(value.multiply(other.value))
    actual operator fun div(other: BigDecimal): BigDecimal = BigDecimal(value.divide(other.value))
    actual fun abs(): BigDecimal = BigDecimal(value.abs())
    actual fun negate(): BigDecimal = BigDecimal(value.negate())
    actual fun setScale(scale: Int, roundingMode: RoundingMode): BigDecimal {
        val decimalMode = com.ionspin.kotlin.bignum.decimal.DecimalMode(
            decimalPrecision = scale.toLong(),
            roundingMode = roundingMode.toIon()
        )
        return BigDecimal(value.roundToDigitPositionAfterDecimalPoint(scale.toLong(), decimalMode.roundingMode))
    }
    actual fun stripTrailingZeros(): BigDecimal = BigDecimal(value)
    actual fun scale(): Int = value.scale?.toInt() ?: 0
    actual fun toInt(): Int = value.intValue(exactRequired = false)
    actual fun toDouble(): Double = value.doubleValue(exactRequired = false)
    actual fun toPlainString(): String = value.toPlainString()

    override fun toString(): String = value.toStringExpanded()
    override fun equals(other: Any?): Boolean = other is BigDecimal && value == other.value
    override fun hashCode(): Int = value.hashCode()

    actual companion object {
        actual val ZERO: BigDecimal = BigDecimal(IonBigDecimal.ZERO)
        actual val ONE: BigDecimal = BigDecimal(IonBigDecimal.ONE)
        actual val TEN: BigDecimal = BigDecimal(IonBigDecimal.TEN)
    }
}

/**
 * iOS RoundingMode using com.ionspin.kotlin.bignum RoundingMode
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

    fun toIon(): IonRoundingMode = when (this) {
        UP -> IonRoundingMode.AWAY_FROM_ZERO
        DOWN -> IonRoundingMode.TOWARDS_ZERO
        CEILING -> IonRoundingMode.CEILING
        FLOOR -> IonRoundingMode.FLOOR
        HALF_UP -> IonRoundingMode.ROUND_HALF_AWAY_FROM_ZERO
        HALF_DOWN -> IonRoundingMode.ROUND_HALF_TOWARDS_ZERO
        HALF_EVEN -> IonRoundingMode.ROUND_HALF_TO_EVEN
        UNNECESSARY -> IonRoundingMode.NONE
    }
}
