// Package domain defines the core domain entities and value objects for the quote subdomain.
package domain

import (
	"fmt"
	"time"

	"github.com/shopspring/decimal"
)

// Market represents a supported exchange.
type Market string

const (
	MarketUS Market = "US" // NYSE/NASDAQ
	MarketHK Market = "HK" // HKEX
)

// Quote is the aggregate root for real-time quote data.
type Quote struct {
	Symbol        string
	Name          string          // Company name (English)
	NameZh        string          // Company name (Chinese)
	Market        Market
	Price         decimal.Decimal // shopspring/decimal — never float64
	Open          decimal.Decimal // shopspring/decimal — never float64
	High          decimal.Decimal // shopspring/decimal — never float64
	Low           decimal.Decimal // shopspring/decimal — never float64
	PrevClose     decimal.Decimal // shopspring/decimal — never float64 — previous Regular Session close
	Volume        int64
	Turnover      decimal.Decimal // shopspring/decimal — daily turnover amount
	Bid           decimal.Decimal // shopspring/decimal — never float64
	BidSize       int64
	Ask           decimal.Decimal // shopspring/decimal — never float64
	AskSize       int64
	Change        decimal.Decimal // shopspring/decimal — never float64 — Price - PrevClose (unadjusted)
	ChangePct     decimal.Decimal // shopspring/decimal — never float64 — Change / PrevClose * 100
	MarketCap     decimal.Decimal // shopspring/decimal — market capitalization
	PERatio       decimal.Decimal // shopspring/decimal — P/E ratio (TTM)
	MarketStatus  TradingPhase    // Current market trading phase
	Delayed       bool            // true = 15-min delayed quote, false = real-time
	IsStale       bool            // true if quote exceeds 1s trading-risk threshold (market-data-system.md Appendix D)
	StaleSinceMs  int64           // ms since exchange timestamp; 0 when IsStale=false; >=5000 triggers UI warning
	LastUpdatedAt time.Time       // Exchange timestamp (data time from feed) — Always UTC; set by feed handler, not usecase
}

// MarketStatus is the aggregate root for exchange trading status.
type MarketStatus struct {
	Market    Market
	Phase     TradingPhase
	UpdatedAt time.Time // Always UTC
}

// TradingPhase represents the current trading session phase.
type TradingPhase string

const (
	PhasePreMarket  TradingPhase = "PRE_MARKET"
	PhaseRegular    TradingPhase = "REGULAR"      // Regular trading hours (replaces OPEN)
	PhaseLunchBreak TradingPhase = "LUNCH_BREAK"  // HK only
	PhaseAfterHours TradingPhase = "AFTER_HOURS"  // After-hours trading (replaces POST_MARKET)
	PhaseClosed     TradingPhase = "CLOSED"
)

// StaleThreshold defines stale detection thresholds.
type StaleThreshold struct {
	TradingRisk time.Duration // 1s — blocks market orders when exceeded
	DisplayWarn time.Duration // 5s — shows warning in UI
}

// DefaultStaleThreshold returns the default two-tier stale threshold.
func DefaultStaleThreshold() StaleThreshold {
	return StaleThreshold{
		TradingRisk: 1 * time.Second,
		DisplayWarn: 5 * time.Second,
	}
}

// ApplyChange computes and sets Change, ChangePct, and PrevClose from the given prevClose price.
// Spec: market-data-system.md Appendix C — change basis = previous Regular Session close (unadjusted).
// Change    = Price - PrevClose
// ChangePct = Change / PrevClose * 100  (rounded to 4 dp; 0 when PrevClose is zero)
func (q *Quote) ApplyChange(prevClose decimal.Decimal) {
	if prevClose.IsZero() {
		return
	}
	q.PrevClose = prevClose
	q.Change = q.Price.Sub(prevClose)
	q.ChangePct = q.Change.Div(prevClose).Mul(decimal.NewFromInt(100)).Round(4)
}

// ApplyStaleCheck applies the result of StaleDetector.Evaluate() to the Quote.
// Separating computation (StaleDetector) from mutation (Quote) keeps the domain
// service free of side effects and the aggregate in control of its own state.
func (q *Quote) ApplyStaleCheck(r StaleResult) {
	q.IsStale = r.IsStale
	q.StaleSinceMs = r.StaleSinceMs
}

// Validate enforces domain invariants on a Quote.
// Called by the application layer before persisting.
func (q *Quote) Validate() error {
	if q.Symbol == "" {
		return fmt.Errorf("quote: symbol must not be empty")
	}
	if q.Market != MarketUS && q.Market != MarketHK {
		return fmt.Errorf("quote: unsupported market %q", q.Market)
	}
	if q.Price.LessThanOrEqual(decimal.Zero) {
		return fmt.Errorf("quote: price must be > 0, got %s", q.Price)
	}
	if q.Volume < 0 {
		return fmt.Errorf("quote: volume must be >= 0, got %d", q.Volume)
	}
	// Bid/Ask spread check (only when both are set)
	if !q.Bid.IsZero() && !q.Ask.IsZero() && q.Bid.GreaterThan(q.Ask) {
		return fmt.Errorf("quote: bid %s must be <= ask %s", q.Bid, q.Ask)
	}
	if q.LastUpdatedAt.IsZero() {
		return fmt.Errorf("quote: last_updated_at must not be zero")
	}
	return nil
}
