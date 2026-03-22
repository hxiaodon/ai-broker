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

// Evaluate checks the quote against stale thresholds and updates IsStale + StaleSinceMs.
// IsStale is true when the exchange timestamp exceeds the 1s trading-risk threshold.
// StaleSinceMs holds the full staleness duration; UI shows warning banner when >= 5000.
// Returns true if the quote is stale at the trading-risk level.
func (d *StaleDetector) Evaluate(q *Quote) bool {
	now := time.Now().UTC()
	elapsed := now.Sub(q.LastUpdatedAt.UTC())
	q.IsStale = elapsed > d.threshold.TradingRisk
	if q.IsStale {
		q.StaleSinceMs = elapsed.Milliseconds()
	} else {
		q.StaleSinceMs = 0
	}
	return q.IsStale
}

// IsDisplayStale checks if the quote exceeds the display warning threshold (5s).
func (d *StaleDetector) IsDisplayStale(q *Quote) bool {
	now := time.Now().UTC()
	elapsed := now.Sub(q.LastUpdatedAt.UTC())
	return elapsed > d.threshold.DisplayWarn
}
