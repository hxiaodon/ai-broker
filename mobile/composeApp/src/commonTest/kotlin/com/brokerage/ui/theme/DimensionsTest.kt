package com.brokerage.ui.theme

import androidx.compose.ui.unit.dp
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Unit tests for Dimensions system
 */
class DimensionsTest {

    @Test
    fun `spacing values should be correct`() {
        assertEquals(0.dp, Spacing.none)
        assertEquals(4.dp, Spacing.extraSmall)
        assertEquals(8.dp, Spacing.small)
        assertEquals(16.dp, Spacing.medium)
        assertEquals(24.dp, Spacing.large)
        assertEquals(32.dp, Spacing.extraLarge)
        assertEquals(48.dp, Spacing.huge)
    }

    @Test
    fun `corner radius values should be correct`() {
        assertEquals(0.dp, CornerRadius.none)
        assertEquals(4.dp, CornerRadius.small)
        assertEquals(8.dp, CornerRadius.medium)
        assertEquals(16.dp, CornerRadius.large)
        assertEquals(24.dp, CornerRadius.extraLarge)
        assertEquals(999.dp, CornerRadius.round)
    }

    @Test
    fun `corner radius medium should match HTML prototype (8dp)`() {
        assertEquals(8.dp, CornerRadius.medium)
    }

    @Test
    fun `elevation values should be correct`() {
        assertEquals(0.dp, Elevation.none)
        assertEquals(2.dp, Elevation.small)
        assertEquals(4.dp, Elevation.medium)
        assertEquals(8.dp, Elevation.large)
        assertEquals(16.dp, Elevation.extraLarge)
    }

    @Test
    fun `border width values should be correct`() {
        assertEquals(1.dp, BorderWidth.thin)
        assertEquals(2.dp, BorderWidth.medium)
        assertEquals(4.dp, BorderWidth.thick)
    }

    @Test
    fun `icon size values should be correct`() {
        assertEquals(16.dp, IconSize.small)
        assertEquals(24.dp, IconSize.medium)
        assertEquals(32.dp, IconSize.large)
        assertEquals(48.dp, IconSize.extraLarge)
    }

    @Test
    fun `spacing should follow 8dp grid system`() {
        // All spacing values should be multiples of 4dp (half of 8dp grid)
        assertEquals(0, Spacing.none.value.toInt() % 4)
        assertEquals(0, Spacing.extraSmall.value.toInt() % 4)
        assertEquals(0, Spacing.small.value.toInt() % 4)
        assertEquals(0, Spacing.medium.value.toInt() % 4)
        assertEquals(0, Spacing.large.value.toInt() % 4)
        assertEquals(0, Spacing.extraLarge.value.toInt() % 4)
        assertEquals(0, Spacing.huge.value.toInt() % 4)
    }
}
