package com.brokerage.ui.theme

import androidx.compose.ui.graphics.Color
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Unit tests for Color system
 */
class ColorTest {

    @Test
    fun `primary colors should match Tailwind CSS blue-500`() {
        assertEquals(Color(0xFF3B82F6), Primary)
    }

    @Test
    fun `primary light should match Tailwind CSS blue-400`() {
        assertEquals(Color(0xFF60A5FA), PrimaryLight)
    }

    @Test
    fun `primary dark should match Tailwind CSS blue-700`() {
        assertEquals(Color(0xFF1D4ED8), PrimaryDark)
    }

    @Test
    fun `trading up color should be green for US market`() {
        assertEquals(Color(0xFF10B981), TradingColors.UpUS)
    }

    @Test
    fun `trading down color should be red for US market`() {
        assertEquals(Color(0xFFEF4444), TradingColors.DownUS)
    }

    @Test
    fun `trading up color should be red for Asia market`() {
        assertEquals(Color(0xFFEF4444), TradingColors.UpAsia)
    }

    @Test
    fun `trading down color should be green for Asia market`() {
        assertEquals(Color(0xFF10B981), TradingColors.DownAsia)
    }

    @Test
    fun `getUpColor should return correct color for US market`() {
        val upColor = getUpColor(MarketColorStyle.US)
        assertEquals(TradingColors.UpUS, upColor)
        assertEquals(Color(0xFF10B981), upColor)
    }

    @Test
    fun `getUpColor should return correct color for Asia market`() {
        val upColor = getUpColor(MarketColorStyle.ASIA)
        assertEquals(TradingColors.UpAsia, upColor)
        assertEquals(Color(0xFFEF4444), upColor)
    }

    @Test
    fun `getDownColor should return correct color for US market`() {
        val downColor = getDownColor(MarketColorStyle.US)
        assertEquals(TradingColors.DownUS, downColor)
        assertEquals(Color(0xFFEF4444), downColor)
    }

    @Test
    fun `getDownColor should return correct color for Asia market`() {
        val downColor = getDownColor(MarketColorStyle.ASIA)
        assertEquals(TradingColors.DownAsia, downColor)
        assertEquals(Color(0xFF10B981), downColor)
    }

    @Test
    fun `background light should match Tailwind CSS gray-50`() {
        assertEquals(Color(0xFFFAFAFA), BackgroundLight)
    }

    @Test
    fun `text primary light should match Tailwind CSS gray-800`() {
        assertEquals(Color(0xFF1F2937), TextPrimaryLight)
    }

    @Test
    fun `text secondary light should match Tailwind CSS gray-500`() {
        assertEquals(Color(0xFF6B7280), TextSecondaryLight)
    }

    @Test
    fun `success color should match Tailwind CSS green-500`() {
        assertEquals(Color(0xFF10B981), Success)
    }

    @Test
    fun `error color should match Tailwind CSS red-500`() {
        assertEquals(Color(0xFFEF4444), Error)
    }

    @Test
    fun `warning color should match Tailwind CSS amber-500`() {
        assertEquals(Color(0xFFF59E0B), Warning)
    }

    @Test
    fun `border light should match Tailwind CSS gray-200`() {
        assertEquals(Color(0xFFE5E7EB), BorderLight)
    }

    @Test
    fun `US and Asia up colors should be opposite`() {
        assertTrue(TradingColors.UpUS != TradingColors.UpAsia)
        assertEquals(TradingColors.UpUS, TradingColors.DownAsia)
        assertEquals(TradingColors.DownUS, TradingColors.UpAsia)
    }
}
