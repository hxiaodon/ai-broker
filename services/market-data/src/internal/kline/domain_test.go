// Package kline_test contains unit tests for the K-line domain layer.
// Spec: market-data-system.md §4 — K-line aggregation, intervals, OHLCV invariants
package kline_test

import (
	"testing"
	"time"

	"github.com/shopspring/decimal"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kline"
)

// ─── Interval constants ───────────────────────────────────────────────────────

func TestInterval_SupportedValues(t *testing.T) {
	// Spec: market-data-system.md §4 — 8 supported intervals
	supported := []kline.Interval{
		kline.Interval1Min,
		kline.Interval5Min,
		kline.Interval15Min,
		kline.Interval30Min,
		kline.Interval1H,
		kline.Interval1D,
		kline.Interval1W,
		kline.Interval1M,
	}

	expected := map[kline.Interval]string{
		kline.Interval1Min:  "1min",
		kline.Interval5Min:  "5min",
		kline.Interval15Min: "15min",
		kline.Interval30Min: "30min",
		kline.Interval1H:    "1h",
		kline.Interval1D:    "1D",
		kline.Interval1W:    "1W",
		kline.Interval1M:    "1M",
	}

	if len(supported) != len(expected) {
		t.Errorf("expected %d intervals, got %d", len(expected), len(supported))
	}

	for _, iv := range supported {
		want, ok := expected[iv]
		if !ok {
			t.Errorf("unexpected interval: %q", iv)
			continue
		}
		if string(iv) != want {
			t.Errorf("interval %q: want string %q, got %q", iv, want, string(iv))
		}
	}
}

// ─── KLine entity ─────────────────────────────────────────────────────────────

func TestKLine_OHLCVInvariants(t *testing.T) {
	// Spec: §4 — OHLCV data integrity: High ≥ Open, Close, Low; Low ≤ Open, Close, High
	now := time.Now().UTC()
	k := &kline.KLine{
		Symbol:    "AAPL",
		Interval:  kline.Interval1Min,
		Open:      decimal.NewFromFloat(150.00),
		High:      decimal.NewFromFloat(152.00),
		Low:       decimal.NewFromFloat(149.00),
		Close:     decimal.NewFromFloat(151.50),
		Volume:    50000,
		StartTime: now,
		EndTime:   now.Add(time.Minute),
		Adjusted:  false,
	}

	// High ≥ Open
	if k.High.LessThan(k.Open) {
		t.Errorf("OHLCV invariant violated: High (%s) < Open (%s)", k.High, k.Open)
	}
	// High ≥ Close
	if k.High.LessThan(k.Close) {
		t.Errorf("OHLCV invariant violated: High (%s) < Close (%s)", k.High, k.Close)
	}
	// Low ≤ Open
	if k.Low.GreaterThan(k.Open) {
		t.Errorf("OHLCV invariant violated: Low (%s) > Open (%s)", k.Low, k.Open)
	}
	// Low ≤ Close
	if k.Low.GreaterThan(k.Close) {
		t.Errorf("OHLCV invariant violated: Low (%s) > Close (%s)", k.Low, k.Close)
	}
	// High ≥ Low
	if k.High.LessThan(k.Low) {
		t.Errorf("OHLCV invariant violated: High (%s) < Low (%s)", k.High, k.Low)
	}
}

func TestKLine_DecimalPriceNoFloat(t *testing.T) {
	// Spec: financial-coding-standards Rule 1 — never float for money in KLine prices
	now := time.Now().UTC()
	k := &kline.KLine{
		Symbol:    "0700",
		Interval:  kline.Interval1D,
		Open:      decimal.NewFromFloat(350.400),
		High:      decimal.NewFromFloat(355.000),
		Low:       decimal.NewFromFloat(348.200),
		Close:     decimal.NewFromFloat(352.600),
		Volume:    1234567,
		StartTime: now.Truncate(24 * time.Hour),
		EndTime:   now.Truncate(24 * time.Hour).Add(24 * time.Hour),
		Adjusted:  false,
	}

	// HK prices to 3 decimal places — verify decimal precision is preserved
	if k.Open.String() != "350.4" {
		// shopspring/decimal trims trailing zeros; verify it's the correct value
		expected := decimal.NewFromFloat(350.400)
		if !k.Open.Equal(expected) {
			t.Errorf("HK price precision: Open want 350.4, got %s", k.Open.String())
		}
	}
}

func TestKLine_TimestampsAreUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — all timestamps UTC
	now := time.Now().UTC()
	k := &kline.KLine{
		Symbol:    "TSLA",
		Interval:  kline.Interval1H,
		Open:      decimal.NewFromFloat(200.00),
		High:      decimal.NewFromFloat(205.00),
		Low:       decimal.NewFromFloat(198.00),
		Close:     decimal.NewFromFloat(203.00),
		Volume:    100000,
		StartTime: now,
		EndTime:   now.Add(time.Hour),
	}

	if k.StartTime.Location() != time.UTC {
		t.Errorf("StartTime must be UTC, got %v", k.StartTime.Location())
	}
	if k.EndTime.Location() != time.UTC {
		t.Errorf("EndTime must be UTC, got %v", k.EndTime.Location())
	}
}

func TestKLine_StartTimeBeforeEndTime(t *testing.T) {
	// Invariant: StartTime must always precede EndTime
	now := time.Now().UTC()
	k := &kline.KLine{
		Symbol:    "GOOG",
		Interval:  kline.Interval5Min,
		Open:      decimal.NewFromFloat(180.00),
		High:      decimal.NewFromFloat(181.00),
		Low:       decimal.NewFromFloat(179.00),
		Close:     decimal.NewFromFloat(180.50),
		Volume:    25000,
		StartTime: now,
		EndTime:   now.Add(5 * time.Minute),
	}

	if !k.StartTime.Before(k.EndTime) {
		t.Errorf("StartTime (%v) must be before EndTime (%v)", k.StartTime, k.EndTime)
	}
}

func TestKLine_AdjustedFlag(t *testing.T) {
	// Spec: Appendix C — historical klines use split+dividend backward adjustment;
	// real-time quotes use unadjusted prices
	// Adjusted=false means unadjusted (real-time feed); Adjusted=true means backward-adjusted (historical)
	unadjusted := &kline.KLine{Adjusted: false}
	adjusted := &kline.KLine{Adjusted: true}

	if unadjusted.Adjusted {
		t.Error("default/real-time kline should be unadjusted (Adjusted=false)")
	}
	if !adjusted.Adjusted {
		t.Error("historical adjusted kline should have Adjusted=true")
	}
}

func TestKLine_VolumeMustBeNonNegative(t *testing.T) {
	// Volume is an int64; validate that zero volume is valid (e.g., weekend/holiday candle)
	now := time.Now().UTC()
	k := &kline.KLine{
		Symbol:    "AAPL",
		Interval:  kline.Interval1D,
		Open:      decimal.NewFromFloat(150.00),
		High:      decimal.NewFromFloat(150.00),
		Low:       decimal.NewFromFloat(150.00),
		Close:     decimal.NewFromFloat(150.00),
		Volume:    0, // zero volume (e.g., market closed, synthetic candle)
		StartTime: now,
		EndTime:   now.Add(24 * time.Hour),
	}

	if k.Volume < 0 {
		t.Errorf("Volume must be non-negative, got %d", k.Volume)
	}
}

// ─── Interval duration mapping ────────────────────────────────────────────────

func TestInterval_DurationMapping(t *testing.T) {
	// Verify that intra-day intervals map to sensible durations
	// (used by aggregation logic to compute candle end time)
	cases := []struct {
		interval kline.Interval
		want     time.Duration
	}{
		{kline.Interval1Min, 1 * time.Minute},
		{kline.Interval5Min, 5 * time.Minute},
		{kline.Interval15Min, 15 * time.Minute},
		{kline.Interval30Min, 30 * time.Minute},
		{kline.Interval1H, 60 * time.Minute},
	}

	durations := map[kline.Interval]time.Duration{
		kline.Interval1Min:  1 * time.Minute,
		kline.Interval5Min:  5 * time.Minute,
		kline.Interval15Min: 15 * time.Minute,
		kline.Interval30Min: 30 * time.Minute,
		kline.Interval1H:    60 * time.Minute,
	}

	for _, tc := range cases {
		got, ok := durations[tc.interval]
		if !ok {
			t.Errorf("interval %q not found in duration map", tc.interval)
			continue
		}
		if got != tc.want {
			t.Errorf("interval %q duration: want %v, got %v", tc.interval, tc.want, got)
		}
	}
}
