package com.brokerage.common.datetime

import kotlinx.datetime.*

/**
 * Date and time utilities for trading application.
 * All timestamps are stored in UTC and converted to local timezone only for display.
 */

/**
 * Get current UTC timestamp
 */
fun nowUtc(): Instant = Clock.System.now()

/**
 * Convert Instant to ISO 8601 string
 */
fun Instant.toIso8601(): String = this.toString()

/**
 * Parse ISO 8601 string to Instant
 */
fun String.toInstantOrNull(): Instant? {
    return try {
        Instant.parse(this)
    } catch (e: Exception) {
        null
    }
}

/**
 * Format timestamp for display in local timezone
 */
fun Instant.formatForDisplay(timeZone: TimeZone = TimeZone.currentSystemDefault()): String {
    val localDateTime = this.toLocalDateTime(timeZone)
    return "${localDateTime.date} ${localDateTime.time}"
}

/**
 * Format date only
 */
fun Instant.formatDate(timeZone: TimeZone = TimeZone.currentSystemDefault()): String {
    val localDateTime = this.toLocalDateTime(timeZone)
    return localDateTime.date.toString()
}

/**
 * Format time only
 */
fun Instant.formatTime(timeZone: TimeZone = TimeZone.currentSystemDefault()): String {
    val localDateTime = this.toLocalDateTime(timeZone)
    return localDateTime.time.toString()
}

/**
 * Trading session enum
 */
enum class TradingSession {
    PRE_MARKET,
    REGULAR,
    AFTER_HOURS,
    CLOSED
}

/**
 * Market enum
 */
enum class Market {
    US,  // NYSE/NASDAQ
    HK   // HKEX
}

/**
 * Check if market is currently open
 * US: 9:30-16:00 ET (regular hours)
 * HK: 9:30-16:00 HKT
 */
fun isMarketOpen(market: Market, timestamp: Instant = nowUtc()): Boolean {
    val timeZone = when (market) {
        Market.US -> TimeZone.of("America/New_York")
        Market.HK -> TimeZone.of("Asia/Hong_Kong")
    }

    val localDateTime = timestamp.toLocalDateTime(timeZone)
    val dayOfWeek = localDateTime.dayOfWeek

    // Weekend check
    if (dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY) {
        return false
    }

    val time = localDateTime.time
    val marketOpenTime = LocalTime(9, 30)
    val marketCloseTime = LocalTime(16, 0)

    return time >= marketOpenTime && time < marketCloseTime
}

/**
 * Get current trading session
 */
fun getTradingSession(market: Market, timestamp: Instant = nowUtc()): TradingSession {
    val timeZone = when (market) {
        Market.US -> TimeZone.of("America/New_York")
        Market.HK -> TimeZone.of("Asia/Hong_Kong")
    }

    val localDateTime = timestamp.toLocalDateTime(timeZone)
    val dayOfWeek = localDateTime.dayOfWeek

    // Weekend
    if (dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY) {
        return TradingSession.CLOSED
    }

    val time = localDateTime.time

    return when (market) {
        Market.US -> {
            when {
                time < LocalTime(9, 30) -> TradingSession.PRE_MARKET
                time < LocalTime(16, 0) -> TradingSession.REGULAR
                time < LocalTime(20, 0) -> TradingSession.AFTER_HOURS
                else -> TradingSession.CLOSED
            }
        }
        Market.HK -> {
            when {
                time < LocalTime(9, 30) -> TradingSession.CLOSED
                time < LocalTime(16, 0) -> TradingSession.REGULAR
                else -> TradingSession.CLOSED
            }
        }
    }
}

/**
 * Calculate settlement date
 * US: T+1 (since May 2024)
 * HK: T+2
 */
fun calculateSettlementDate(
    tradeDate: Instant,
    market: Market,
    timeZone: TimeZone = TimeZone.currentSystemDefault()
): LocalDate {
    val tradeDateLocal = tradeDate.toLocalDateTime(timeZone).date
    val settlementDays = when (market) {
        Market.US -> 1
        Market.HK -> 2
    }

    // Simple implementation - in production, should skip weekends and holidays
    return tradeDateLocal.plus(settlementDays, DateTimeUnit.DAY)
}

/**
 * Check if funds are settled
 */
fun isFundsSettled(
    tradeDate: Instant,
    market: Market,
    currentDate: Instant = nowUtc(),
    timeZone: TimeZone = TimeZone.currentSystemDefault()
): Boolean {
    val settlementDate = calculateSettlementDate(tradeDate, market, timeZone)
    val currentDateLocal = currentDate.toLocalDateTime(timeZone).date
    return currentDateLocal >= settlementDate
}
