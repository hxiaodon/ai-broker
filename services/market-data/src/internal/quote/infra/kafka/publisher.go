// Package kafka provides a typed Kafka publisher for quote events.
//
// DEPRECATED: QuoteEventPublisher is currently unused dead code.
// UpdateQuoteUsecase calls OutboxRepo.InsertEvent() directly with producer.QuoteTopicForMarket().
// This file is kept for reference and may be removed in a future cleanup.
package kafka

import (
	"context"
	"fmt"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/producer"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// QuoteEventPublisher writes quote update events to the outbox table.
// Events are published to Kafka by the outbox worker — never directly from here.
type QuoteEventPublisher struct {
	outbox app.OutboxRepo
}

// NewQuoteEventPublisher creates a new QuoteEventPublisher.
func NewQuoteEventPublisher(outbox app.OutboxRepo) *QuoteEventPublisher {
	return &QuoteEventPublisher{outbox: outbox}
}

// Publish writes a quote updated event to the outbox with market-specific topic.
// Uses JSON serialization (Phase 4); protobuf will be added in Phase 5.
func (p *QuoteEventPublisher) Publish(ctx context.Context, market domain.Market, symbol string, payload []byte) error {
	topic := producer.QuoteTopicForMarket(string(market))
	if err := p.outbox.InsertEvent(ctx, topic, payload); err != nil {
		return fmt.Errorf("publish quote event %s: %w", symbol, err)
	}
	return nil
}


