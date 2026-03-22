// Package kline implements the K-line aggregation subdomain (degenerate DDD form).
// domain.go holds entities and repository interfaces — the domain layer.
package kline

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// Interval represents a K-line time interval.
type Interval string

const (
	Interval1Min  Interval = "1min"
	Interval5Min  Interval = "5min"
	Interval15Min Interval = "15min"
	Interval30Min Interval = "30min"
	Interval1H    Interval = "1h"
	Interval1D    Interval = "1D"
	Interval1W    Interval = "1W"
	Interval1M    Interval = "1M"
)

// KLine is the aggregate root for candlestick data.
type KLine struct {
	ID        int64
	Symbol    string
	Interval  Interval
	Open      decimal.Decimal // shopspring/decimal — never float64
	High      decimal.Decimal // shopspring/decimal — never float64
	Low       decimal.Decimal // shopspring/decimal — never float64
	Close     decimal.Decimal // shopspring/decimal — never float64
	Volume    int64
	StartTime time.Time // Always UTC — start of the candle period
	EndTime   time.Time // Always UTC — end of the candle period
	Adjusted  bool      // true if prices are adjusted for corporate actions
}

// KLineRepo defines the repository interface for K-line persistence.
type KLineRepo interface {
	// Save persists a K-line record.
	Save(ctx context.Context, k *KLine) error
	// SaveBatch persists multiple K-line records.
	SaveBatch(ctx context.Context, klines []*KLine) error
	// FindBySymbolAndInterval retrieves K-lines for a symbol, interval, and time range.
	FindBySymbolAndInterval(ctx context.Context, symbol string, interval Interval, start, end time.Time, limit int) ([]*KLine, error)
}
