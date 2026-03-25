package kline

import (
	"context"
	"time"
)

// KLineScheduler fires K-line aggregation at each interval boundary.
// It runs FlushAll on the TickAccumulator for all supported intra-day intervals.
//
// Supported intervals and their flush cadence:
//   Interval1Min  — every minute
//   Interval5Min  — every 5 minutes
//   Interval15Min — every 15 minutes
//   Interval30Min — every 30 minutes
//   Interval1H    — every hour
//   Interval1D    — every day (midnight UTC)
type KLineScheduler struct {
	acc    *TickAccumulator
}

// NewKLineScheduler creates a new KLineScheduler.
func NewKLineScheduler(acc *TickAccumulator) *KLineScheduler {
	return &KLineScheduler{acc: acc}
}

// Run blocks until ctx is cancelled, triggering aggregation at each interval boundary.
func (s *KLineScheduler) Run(ctx context.Context) error {
	// Wait for the next minute boundary before starting tickers so they align
	// to clock minutes (e.g., fire at :00, :01, :05 …) rather than drifting.
	now := time.Now().UTC()
	nextMinute := now.Truncate(time.Minute).Add(time.Minute)
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-time.After(time.Until(nextMinute)):
	}

	// 1-minute ticker drives all other intervals via modulo checks.
	ticker := time.NewTicker(time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case t := <-ticker.C:
			t = t.UTC()
			minute := t.Minute()
			hour := t.Hour()

			// Always flush 1-min candles.
			s.acc.FlushAll(ctx, Interval1Min)

			if minute%5 == 0 {
				s.acc.FlushAll(ctx, Interval5Min)
			}
			if minute%15 == 0 {
				s.acc.FlushAll(ctx, Interval15Min)
			}
			if minute%30 == 0 {
				s.acc.FlushAll(ctx, Interval30Min)
			}
			if minute == 0 {
				s.acc.FlushAll(ctx, Interval1H)
			}
			// Daily candle: flush at midnight UTC.
			if hour == 0 && minute == 0 {
				s.acc.FlushAll(ctx, Interval1D)
			}
		}
	}
}
