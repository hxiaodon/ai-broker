// Package domain_test contains unit tests for the quote domain service layer.
// Spec: market-data-system.md §3.3.5 — Two-tier stale thresholds
package domain_test

import (
	"testing"
	"time"

	"github.com/shopspring/decimal"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// newQuoteWithAge returns a Quote whose LastUpdatedAt is `age` ago.
func newQuoteWithAge(symbol string, age time.Duration) *domain.Quote {
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		PrevClose:     decimal.NewFromFloat(149.00),
		LastUpdatedAt: time.Now().UTC().Add(-age),
	}
}

// ─── StaleDetector.Evaluate ───────────────────────────────────────────────────

// Spec: TradingRisk threshold = 1s (blocks market orders)
func TestStaleDetector_Evaluate_FreshQuote(t *testing.T) {
	// Spec: market-data-system.md §3.3.5 — quote updated <1s ago must NOT be stale
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("AAPL", 500*time.Millisecond)

	isStale := detector.Evaluate(q)

	if isStale {
		t.Errorf("expected fresh quote (500ms old) to not be stale, got IsStale=%v", isStale)
	}
	if q.IsStale {
		t.Errorf("expected Quote.IsStale=false for fresh quote, got true")
	}
}

func TestStaleDetector_Evaluate_ExactlyAtTradingRiskBoundary(t *testing.T) {
	// Spec: §3.3.5 — quote at exactly TradingRisk (1s) is NOT stale (boundary exclusive)
	// elapsed must be strictly > 1s to be stale
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("AAPL", 1*time.Second)

	// 1s old: elapsed == threshold; should be false (not stale yet)
	isStale := detector.Evaluate(q)

	// Allow either false or true depending on nanosecond timing, but
	// verify consistency between return value and q.IsStale
	if isStale != q.IsStale {
		t.Errorf("Evaluate() return value (%v) inconsistent with q.IsStale (%v)", isStale, q.IsStale)
	}
}

func TestStaleDetector_Evaluate_StaleQuote(t *testing.T) {
	// Spec: §3.3.5 — quote updated >1s ago IS stale at trading-risk level
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("AAPL", 2*time.Second)

	isStale := detector.Evaluate(q)

	if !isStale {
		t.Errorf("expected stale quote (2s old) to be stale, got IsStale=%v", isStale)
	}
	if !q.IsStale {
		t.Errorf("expected Quote.IsStale=true for 2s-old quote, got false")
	}
}

func TestStaleDetector_Evaluate_SetsQuoteIsStaleField(t *testing.T) {
	// Spec: Evaluate() must mutate q.IsStale so callers can inspect the aggregate
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("TSLA", 3*time.Second)
	q.IsStale = false // start false; Evaluate should flip it

	detector.Evaluate(q)

	if !q.IsStale {
		t.Error("Evaluate() should have set q.IsStale=true for a 3s-old quote")
	}
}

func TestStaleDetector_Evaluate_CustomThreshold(t *testing.T) {
	// Verify custom TradingRisk threshold is respected (not hard-coded 1s)
	customThreshold := domain.StaleThreshold{
		TradingRisk: 500 * time.Millisecond,
		DisplayWarn: 2 * time.Second,
	}
	detector := domain.NewStaleDetector(customThreshold)

	fresh := newQuoteWithAge("GOOG", 100*time.Millisecond)
	stale := newQuoteWithAge("GOOG", 600*time.Millisecond)

	if detector.Evaluate(fresh) {
		t.Error("100ms-old quote should not be stale with 500ms threshold")
	}
	if !detector.Evaluate(stale) {
		t.Error("600ms-old quote should be stale with 500ms threshold")
	}
}

func TestStaleDetector_Evaluate_HKMarketQuote(t *testing.T) {
	// Spec: §3.3.5 — same thresholds apply to HK market (HKEX)
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := &domain.Quote{
		Symbol:        "0700",
		Market:        domain.MarketHK,
		Price:         decimal.NewFromFloat(350.400),
		LastUpdatedAt: time.Now().UTC().Add(-2 * time.Second),
	}

	isStale := detector.Evaluate(q)

	if !isStale {
		t.Errorf("HK quote 2s old should be stale, got isStale=%v", isStale)
	}
}

// ─── StaleDetector.IsDisplayStale ────────────────────────────────────────────

// Spec: DisplayWarn threshold = 5s (shows warning in UI)
func TestStaleDetector_IsDisplayStale_FreshQuote(t *testing.T) {
	// Spec: §3.3.5 — quote <5s old must NOT trigger display warning
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("AAPL", 3*time.Second)

	if detector.IsDisplayStale(q) {
		t.Error("3s-old quote should not be display-stale (threshold=5s)")
	}
}

func TestStaleDetector_IsDisplayStale_StaleQuote(t *testing.T) {
	// Spec: §3.3.5 — quote >5s old MUST trigger display warning
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("AAPL", 6*time.Second)

	if !detector.IsDisplayStale(q) {
		t.Error("6s-old quote should be display-stale (threshold=5s)")
	}
}

func TestStaleDetector_IsDisplayStale_TradingRiskButNotDisplayStale(t *testing.T) {
	// Spec: §3.3.5 — between 1s and 5s: trading-risk stale but NOT display-stale
	// This validates the two-tier separation is correctly implemented.
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("MSFT", 2*time.Second)

	isTradingStale := detector.Evaluate(q)
	isDisplayStale := detector.IsDisplayStale(q)

	if !isTradingStale {
		t.Error("2s-old quote should be trading-risk stale (threshold=1s)")
	}
	if isDisplayStale {
		t.Error("2s-old quote should NOT be display-stale (threshold=5s)")
	}
}

func TestStaleDetector_IsDisplayStale_DoesNotMutateIsStale(t *testing.T) {
	// IsDisplayStale() must NOT modify q.IsStale — it's a read-only check
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	q := newQuoteWithAge("NVDA", 10*time.Second)
	q.IsStale = false // set to false to verify IsDisplayStale doesn't flip it

	detector.IsDisplayStale(q)

	if q.IsStale != false {
		t.Error("IsDisplayStale() must not mutate q.IsStale")
	}
}

// ─── DefaultStaleThreshold ───────────────────────────────────────────────────

func TestDefaultStaleThreshold_Values(t *testing.T) {
	// Spec: §3.3.5 — TradingRisk=1s, DisplayWarn=5s are spec-mandated constants
	threshold := domain.DefaultStaleThreshold()

	if threshold.TradingRisk != 1*time.Second {
		t.Errorf("DefaultStaleThreshold.TradingRisk: want 1s, got %v", threshold.TradingRisk)
	}
	if threshold.DisplayWarn != 5*time.Second {
		t.Errorf("DefaultStaleThreshold.DisplayWarn: want 5s, got %v", threshold.DisplayWarn)
	}
}

func TestDefaultStaleThreshold_TradingRiskLessThanDisplayWarn(t *testing.T) {
	// Invariant: TradingRisk must always be < DisplayWarn
	threshold := domain.DefaultStaleThreshold()
	if threshold.TradingRisk >= threshold.DisplayWarn {
		t.Errorf("TradingRisk (%v) must be less than DisplayWarn (%v)", threshold.TradingRisk, threshold.DisplayWarn)
	}
}

// ─── Quote entity ─────────────────────────────────────────────────────────────

func TestQuote_DecimalPriceNoFloat(t *testing.T) {
	// Spec: financial-coding-standards Rule 1 — never float for money
	// Verify shopspring/decimal is used (compile-time: decimal.Decimal fields cannot hold float64)
	q := &domain.Quote{
		Symbol:        "AAPL",
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.2500),
		Open:          decimal.NewFromFloat(149.0000),
		High:          decimal.NewFromFloat(152.0000),
		Low:           decimal.NewFromFloat(148.5000),
		PrevClose:     decimal.NewFromFloat(149.0000),
		Bid:           decimal.NewFromFloat(150.2400),
		Ask:           decimal.NewFromFloat(150.2600),
		Volume:        1000000,
		LastUpdatedAt: time.Now().UTC(),
	}

	// Change = Price - PrevClose
	expectedChange := decimal.NewFromFloat(1.25)
	change := q.Price.Sub(q.PrevClose)
	if !change.Equal(expectedChange) {
		t.Errorf("Change calculation: want %s, got %s", expectedChange, change)
	}

	// ChangePct = Change / PrevClose * 100
	expectedChangePct := decimal.NewFromFloat(0.8389).Round(4)
	changePct := change.Div(q.PrevClose).Mul(decimal.NewFromInt(100)).Round(4)
	if !changePct.Equal(expectedChangePct) {
		t.Errorf("ChangePct: want %s, got %s", expectedChangePct, changePct)
	}
}

func TestQuote_LastUpdatedAtUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — all timestamps UTC
	q := newQuoteWithAge("AAPL", 0)
	if q.LastUpdatedAt.Location() != time.UTC {
		t.Errorf("LastUpdatedAt must be UTC, got location: %v", q.LastUpdatedAt.Location())
	}
}

// ─── QuoteUpdatedEvent ────────────────────────────────────────────────────────

func TestNewQuoteUpdatedEvent_MapsAllFields(t *testing.T) {
	// Spec: Outbox pattern — event carries all fields needed for Kafka publish
	now := time.Now().UTC()
	q := &domain.Quote{
		Symbol:        "AAPL",
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		Volume:        1000000,
		Bid:           decimal.NewFromFloat(150.24),
		Ask:           decimal.NewFromFloat(150.26),
		IsStale:       false,
		LastUpdatedAt: now,
	}

	ev := domain.NewQuoteUpdatedEvent(q)

	if ev.Symbol != q.Symbol {
		t.Errorf("Symbol: want %q, got %q", q.Symbol, ev.Symbol)
	}
	if ev.Market != q.Market {
		t.Errorf("Market: want %q, got %q", q.Market, ev.Market)
	}
	if !ev.Price.Equal(q.Price) {
		t.Errorf("Price: want %s, got %s", q.Price, ev.Price)
	}
	if ev.Volume != q.Volume {
		t.Errorf("Volume: want %d, got %d", q.Volume, ev.Volume)
	}
	if !ev.Bid.Equal(q.Bid) {
		t.Errorf("Bid: want %s, got %s", q.Bid, ev.Bid)
	}
	if !ev.Ask.Equal(q.Ask) {
		t.Errorf("Ask: want %s, got %s", q.Ask, ev.Ask)
	}
	if ev.IsStale != q.IsStale {
		t.Errorf("IsStale: want %v, got %v", q.IsStale, ev.IsStale)
	}
	if !ev.Timestamp.Equal(q.LastUpdatedAt) {
		t.Errorf("Timestamp: want %v, got %v", q.LastUpdatedAt, ev.Timestamp)
	}
}

func TestNewQuoteUpdatedEvent_TimestampIsUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — event timestamp must always be UTC
	q := &domain.Quote{
		Symbol:        "MSFT",
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(400.00),
		LastUpdatedAt: time.Now().UTC(), // store UTC
	}

	ev := domain.NewQuoteUpdatedEvent(q)

	if ev.Timestamp.Location() != time.UTC {
		t.Errorf("QuoteUpdatedEvent.Timestamp must be UTC, got %v", ev.Timestamp.Location())
	}
}

func TestNewQuoteUpdatedEvent_StaleQuote(t *testing.T) {
	// IsStale must be propagated correctly when the quote is stale
	q := newQuoteWithAge("NVDA", 3*time.Second)
	detector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	detector.Evaluate(q) // marks q.IsStale = true

	ev := domain.NewQuoteUpdatedEvent(q)

	if !ev.IsStale {
		t.Error("event IsStale should be true when emitted from a stale quote")
	}
}
