// Package kafka provides a typed Kafka publisher for quote events.
package kafka

import (
	"context"
	"fmt"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/mysql"
)

// QuoteEventPublisher writes quote update events to the outbox table.
// Events are published to Kafka by the outbox worker — never directly from here.
type QuoteEventPublisher struct {
	outbox *mysql.OutboxRepository
}

// NewQuoteEventPublisher creates a new QuoteEventPublisher.
func NewQuoteEventPublisher(outbox *mysql.OutboxRepository) *QuoteEventPublisher {
	return &QuoteEventPublisher{outbox: outbox}
}

// Publish writes a quote updated event to the outbox.
// Uses JSON serialization (Phase 4); protobuf will be added in Phase 5.
func (p *QuoteEventPublisher) Publish(ctx context.Context, symbol string, payload []byte) error {
	topic := "brokerage.market-data.quote.updated"
	if err := p.outbox.InsertEvent(ctx, topic, payload); err != nil {
		return fmt.Errorf("publish quote event %s: %w", symbol, err)
	}
	return nil
}
