package domain

import "time"

// StaleDetector is a domain service that evaluates whether a quote is stale.
// Pure logic, no I/O dependencies.
type StaleDetector struct {
	threshold StaleThreshold
}

// NewStaleDetector creates a StaleDetector with the given thresholds.
func NewStaleDetector(threshold StaleThreshold) *StaleDetector {
	return &StaleDetector{threshold: threshold}
}

// StaleResult holds the outcome of a stale evaluation.
// Callers apply it to a Quote via Quote.ApplyStaleCheck().
type StaleResult struct {
	IsStale      bool
	StaleSinceMs int64 // 0 when not stale; >=5000 triggers UI display warning
}

// Evaluate computes stale status for a quote based on its exchange timestamp.
// Returns a StaleResult; does NOT mutate the quote — call q.ApplyStaleCheck() to apply.
// Spec: market-data-system.md §3.3.5 — two-tier thresholds (1s trading-risk, 5s display-warn).
func (d *StaleDetector) Evaluate(q *Quote) StaleResult {
	now := time.Now().UTC()
	elapsed := now.Sub(q.LastUpdatedAt.UTC())
	isStale := elapsed > d.threshold.TradingRisk
	staleSinceMs := int64(0)
	if isStale {
		staleSinceMs = elapsed.Milliseconds()
	}
	return StaleResult{IsStale: isStale, StaleSinceMs: staleSinceMs}
}

// IsDisplayStale checks if the quote exceeds the display warning threshold (5s).
func (d *StaleDetector) IsDisplayStale(q *Quote) bool {
	now := time.Now().UTC()
	elapsed := now.Sub(q.LastUpdatedAt.UTC())
	return elapsed > d.threshold.DisplayWarn
}
