package kline

import (
	"context"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
)

// Tick represents a single trade tick used as aggregation input.
// Spec: market-data-system.md §4 — tick→candle OHLCV aggregation
type Tick struct {
	Symbol    string
	Price     decimal.Decimal // shopspring/decimal — never float64
	Volume    int64
	Timestamp time.Time // Always UTC
}

// AggregateKLineUsecase aggregates tick data into K-line candles.
type AggregateKLineUsecase struct {
	repo KLineRepo
}

// NewAggregateKLineUsecase creates a new AggregateKLineUsecase.
func NewAggregateKLineUsecase(repo KLineRepo) *AggregateKLineUsecase {
	return &AggregateKLineUsecase{repo: repo}
}

// Execute aggregates a batch of ticks for one symbol+interval into K-line candles
// and persists them.
// Spec: market-data-system.md §4 — OHLCV candle construction rules:
//   - Open  = price of first tick in the candle period
//   - High  = max price across all ticks
//   - Low   = min price across all ticks
//   - Close = price of last tick in the candle period
//   - Volume = sum of all tick volumes
//   - StartTime = truncated to interval boundary (UTC)
//   - EndTime   = StartTime + interval duration
//
// Spec: financial-coding-standards Rule 1 — shopspring/decimal for all price arithmetic.
// Spec: financial-coding-standards Rule 2 — all timestamps UTC.
func (uc *AggregateKLineUsecase) Execute(ctx context.Context, ticks []Tick, interval Interval) error {
	if len(ticks) == 0 {
		return nil
	}

	// Group ticks into candle buckets by interval boundary.
	dur, err := intervalDuration(interval)
	if err != nil {
		return fmt.Errorf("aggregate kline: %w", err)
	}

	type bucket struct {
		open      decimal.Decimal
		high      decimal.Decimal
		low       decimal.Decimal
		close     decimal.Decimal
		volume    int64
		startTime time.Time
		hasData   bool
	}

	buckets := make(map[time.Time]*bucket)

	for _, t := range ticks {
		// Spec: Rule 2 — always UTC
		ts := t.Timestamp.UTC()
		// Truncate to interval boundary
		var start time.Time
		if dur > 0 {
			start = ts.Truncate(dur)
		} else {
			// Daily/Weekly/Monthly: truncate to day boundary; weekly/monthly handled upstream
			start = time.Date(ts.Year(), ts.Month(), ts.Day(), 0, 0, 0, 0, time.UTC)
		}

		b, ok := buckets[start]
		if !ok {
			b = &bucket{
				open:      t.Price,
				high:      t.Price,
				low:       t.Price,
				close:     t.Price,
				volume:    t.Volume,
				startTime: start,
				hasData:   true,
			}
			buckets[start] = b
			continue
		}

		// Spec: Rule 1 — use decimal.Cmp, never float comparison
		if t.Price.GreaterThan(b.high) {
			b.high = t.Price
		}
		if t.Price.LessThan(b.low) {
			b.low = t.Price
		}
		b.close = t.Price
		b.volume += t.Volume
	}

	// Build KLine slice and persist in batch.
	symbol := ticks[0].Symbol
	klines := make([]*KLine, 0, len(buckets))
	for start, b := range buckets {
		if !b.hasData {
			continue
		}
		endTime := candleEndTime(start, interval, dur)
		klines = append(klines, &KLine{
			Symbol:    symbol,
			Interval:  interval,
			Open:      b.open,
			High:      b.high,
			Low:       b.low,
			Close:     b.close,
			Volume:    b.volume,
			StartTime: start,
			EndTime:   endTime,
			Adjusted:  false, // real-time ticks are always unadjusted
		})
	}

	if err := uc.repo.SaveBatch(ctx, klines); err != nil {
		return fmt.Errorf("aggregate kline save batch: %w", err)
	}
	return nil
}

// intervalDuration returns the time.Duration for intra-day intervals.
// Returns 0 for daily/weekly/monthly (handled separately).
func intervalDuration(iv Interval) (time.Duration, error) {
	switch iv {
	case Interval1Min:
		return 1 * time.Minute, nil
	case Interval5Min:
		return 5 * time.Minute, nil
	case Interval15Min:
		return 15 * time.Minute, nil
	case Interval30Min:
		return 30 * time.Minute, nil
	case Interval1H:
		return 60 * time.Minute, nil
	case Interval1D, Interval1W, Interval1M:
		return 0, nil // handled by date-level truncation
	default:
		return 0, fmt.Errorf("unsupported interval: %q", iv)
	}
}

// candleEndTime returns the exclusive end time for a candle starting at start.
func candleEndTime(start time.Time, iv Interval, dur time.Duration) time.Time {
	if dur > 0 {
		return start.Add(dur)
	}
	switch iv {
	case Interval1D:
		return start.AddDate(0, 0, 1)
	case Interval1W:
		return start.AddDate(0, 0, 7)
	case Interval1M:
		return start.AddDate(0, 1, 0)
	default:
		return start.AddDate(0, 0, 1)
	}
}

// GetKLinesUsecase retrieves K-line data for display.
type GetKLinesUsecase struct {
	repo KLineRepo
}

// NewGetKLinesUsecase creates a new GetKLinesUsecase.
func NewGetKLinesUsecase(repo KLineRepo) *GetKLinesUsecase {
	return &GetKLinesUsecase{repo: repo}
}

// Execute retrieves K-lines for a symbol, interval, and time range.
func (uc *GetKLinesUsecase) Execute(ctx context.Context, symbol string, interval Interval, start, end time.Time, limit int) ([]*KLine, error) {
	if symbol == "" {
		return nil, fmt.Errorf("get klines: symbol must not be empty")
	}
	if limit <= 0 {
		limit = 200
	}
	if limit > 1000 {
		limit = 1000
	}

	klines, err := uc.repo.FindBySymbolAndInterval(ctx, symbol, interval, start.UTC(), end.UTC(), limit)
	if err != nil {
		return nil, fmt.Errorf("get klines %s %s: %w", symbol, interval, err)
	}
	return klines, nil
}

