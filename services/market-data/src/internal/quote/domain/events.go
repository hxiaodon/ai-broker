package domain

import (
	"time"

	"github.com/shopspring/decimal"
)

// QuoteUpdatedEvent is a domain event emitted when a quote is updated.
// Published via the Outbox pattern — never directly to Kafka from domain logic.
type QuoteUpdatedEvent struct {
	Symbol    string          `json:"symbol"`
	Market    Market          `json:"market"`
	Price     decimal.Decimal `json:"price"`     // shopspring/decimal — never float64
	Volume    int64           `json:"volume"`
	Bid       decimal.Decimal `json:"bid"`       // shopspring/decimal — never float64
	Ask       decimal.Decimal `json:"ask"`       // shopspring/decimal — never float64
	IsStale   bool            `json:"is_stale"`
	Timestamp time.Time       `json:"timestamp"` // Always UTC
}

// NewQuoteUpdatedEvent creates a QuoteUpdatedEvent from a Quote.
func NewQuoteUpdatedEvent(q *Quote) *QuoteUpdatedEvent {
	return &QuoteUpdatedEvent{
		Symbol:    q.Symbol,
		Market:    q.Market,
		Price:     q.Price,
		Volume:    q.Volume,
		Bid:       q.Bid,
		Ask:       q.Ask,
		IsStale:   q.IsStale,
		Timestamp: q.LastUpdatedAt.UTC(),
	}
}
