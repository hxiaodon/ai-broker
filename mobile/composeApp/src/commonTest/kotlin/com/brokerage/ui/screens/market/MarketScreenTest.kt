package com.brokerage.ui.screens.market

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.test.assertFalse

/**
 * Unit tests for MarketScreen data models
 */
class MarketScreenTest {

    @Test
    fun `StockItem should hold correct data`() {
        val stock = StockItem(
            symbol = "AAPL",
            name = "Apple Inc.",
            price = 175.23,
            change = 2.34,
            changePercent = 1.35,
            isUp = true,
            marketCap = "2.8T",
            pe = 28.5,
            volume = "45.2M"
        )

        assertEquals("AAPL", stock.symbol)
        assertEquals("Apple Inc.", stock.name)
        assertEquals(175.23, stock.price)
        assertEquals(2.34, stock.change)
        assertEquals(1.35, stock.changePercent)
        assertTrue(stock.isUp)
        assertEquals("2.8T", stock.marketCap)
        assertEquals(28.5, stock.pe)
        assertEquals("45.2M", stock.volume)
    }

    @Test
    fun `StockItem with negative change should be marked as down`() {
        val stock = StockItem(
            symbol = "TSLA",
            name = "Tesla Inc.",
            price = 245.67,
            change = -3.21,
            changePercent = -1.29,
            isUp = false,
            marketCap = "780B",
            pe = 65.3,
            volume = "52.1M"
        )

        assertFalse(stock.isUp)
        assertTrue(stock.change < 0)
        assertTrue(stock.changePercent < 0)
    }

    @Test
    fun `getSampleStocks should return 6 stocks`() {
        val stocks = getSampleStocks()
        assertEquals(6, stocks.size)
    }

    @Test
    fun `getSampleStocks should contain AAPL`() {
        val stocks = getSampleStocks()
        val aapl = stocks.find { it.symbol == "AAPL" }

        assertEquals("AAPL", aapl?.symbol)
        assertEquals("Apple Inc.", aapl?.name)
        assertTrue(aapl?.isUp ?: false)
    }

    @Test
    fun `getSampleStocks should contain TSLA`() {
        val stocks = getSampleStocks()
        val tsla = stocks.find { it.symbol == "TSLA" }

        assertEquals("TSLA", tsla?.symbol)
        assertEquals("Tesla Inc.", tsla?.name)
        assertFalse(tsla?.isUp ?: true)
    }

    @Test
    fun `getSampleStocks should have mix of up and down stocks`() {
        val stocks = getSampleStocks()
        val upStocks = stocks.filter { it.isUp }
        val downStocks = stocks.filter { !it.isUp }

        assertTrue(upStocks.size > 0, "Should have at least one up stock")
        assertTrue(downStocks.size > 0, "Should have at least one down stock")
    }

    @Test
    fun `all sample stocks should have valid market cap`() {
        val stocks = getSampleStocks()
        stocks.forEach { stock ->
            assertTrue(stock.marketCap.length > 0, "${stock.symbol} should have market cap")
        }
    }

    @Test
    fun `all sample stocks should have valid PE ratio`() {
        val stocks = getSampleStocks()
        stocks.forEach { stock ->
            assertTrue(stock.pe > 0, "${stock.symbol} should have positive PE ratio")
        }
    }

    @Test
    fun `all sample stocks should have valid volume`() {
        val stocks = getSampleStocks()
        stocks.forEach { stock ->
            assertTrue(stock.volume.length > 0, "${stock.symbol} should have volume")
        }
    }

    @Test
    fun `stock symbols should be unique`() {
        val stocks = getSampleStocks()
        val symbols = stocks.map { it.symbol }
        val uniqueSymbols = symbols.toSet()

        assertEquals(symbols.size, uniqueSymbols.size, "All stock symbols should be unique")
    }

    @Test
    fun `stock prices should be positive`() {
        val stocks = getSampleStocks()
        stocks.forEach { stock ->
            assertTrue(stock.price > 0, "${stock.symbol} price should be positive")
        }
    }

    @Test
    fun `change and changePercent should have same sign`() {
        val stocks = getSampleStocks()
        stocks.forEach { stock ->
            val changeSign = stock.change >= 0
            val percentSign = stock.changePercent >= 0
            assertEquals(changeSign, percentSign,
                "${stock.symbol} change and changePercent should have same sign")
        }
    }

    @Test
    fun `isUp flag should match change sign`() {
        val stocks = getSampleStocks()
        stocks.forEach { stock ->
            val expectedIsUp = stock.change > 0
            assertEquals(expectedIsUp, stock.isUp,
                "${stock.symbol} isUp flag should match change sign")
        }
    }
}
