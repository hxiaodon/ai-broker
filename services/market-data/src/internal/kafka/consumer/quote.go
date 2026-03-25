// Package consumer provides Kafka consumers for the market-data service.
package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/segmentio/kafka-go"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/producer"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/observability"
)

// QuoteBroadcaster abstracts the WebSocket server's broadcast method so the consumer
// does not import the server package (avoids circular dependency).
type QuoteBroadcaster interface {
	BroadcastQuote(symbol string, data []byte)
}

// QuoteConsumer subscribes to the market-data quote topics and broadcasts
// each event to subscribed WebSocket clients.
//
// Data flow: Kafka (market-data.quotes.us / .hk) → QuoteConsumer → WSServer.BroadcastQuote
// Spec: websocket-spec.md — binary push frames carry quote payloads to subscribed clients.
type QuoteConsumer struct {
	readers     []*kafka.Reader
	broadcaster QuoteBroadcaster
	logger      *zap.Logger
}

// NewQuoteConsumer creates a consumer for US and HK quote topics.
func NewQuoteConsumer(brokers []string, groupID string, broadcaster QuoteBroadcaster, logger *zap.Logger) *QuoteConsumer {
	topics := []string{
		producer.QuoteTopicUS,
		producer.QuoteTopicHK,
	}

	readers := make([]*kafka.Reader, 0, len(topics))
	for _, topic := range topics {
		readers = append(readers, kafka.NewReader(kafka.ReaderConfig{
			Brokers:        brokers,
			GroupID:        groupID,
			Topic:          topic,
			MinBytes:       1,
			MaxBytes:       1 << 20, // 1 MiB
			MaxWait:        50 * time.Millisecond,
			CommitInterval: 200 * time.Millisecond,
		}))
	}

	return &QuoteConsumer{
		readers:     readers,
		broadcaster: broadcaster,
		logger:      logger,
	}
}

// Run starts one goroutine per Kafka reader and blocks until ctx is cancelled.
// All reader goroutines are stopped and closed on exit.
func (c *QuoteConsumer) Run(ctx context.Context) error {
	c.logger.Info("quote consumer started", zap.Int("readers", len(c.readers)))
	defer c.closeAll()

	errCh := make(chan error, len(c.readers))
	for _, r := range c.readers {
		r := r
		go func() {
			errCh <- c.consumeReader(ctx, r)
		}()
	}

	// Wait for context cancellation; log any reader errors.
	for i := 0; i < len(c.readers); i++ {
		if err := <-errCh; err != nil && ctx.Err() == nil {
			c.logger.Error("quote consumer reader error", zap.Error(err))
		}
	}

	c.logger.Info("quote consumer stopped")
	return ctx.Err()
}

func (c *QuoteConsumer) consumeReader(ctx context.Context, r *kafka.Reader) error {
	for {
		msg, err := r.FetchMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil // normal shutdown
			}
			return fmt.Errorf("quote consumer fetch: %w", err)
		}

		c.handleMessage(msg)

		if err := r.CommitMessages(ctx, msg); err != nil {
			c.logger.Warn("quote consumer commit failed",
				zap.String("topic", msg.Topic),
				zap.Int64("offset", msg.Offset),
				zap.Error(err))
		}
	}
}

// handleMessage deserialises the QuoteUpdatedEvent and broadcasts to WS clients.
func (c *QuoteConsumer) handleMessage(msg kafka.Message) {
	var event domain.QuoteUpdatedEvent
	if err := json.Unmarshal(msg.Value, &event); err != nil {
		c.logger.Error("quote consumer unmarshal failed",
			zap.String("topic", msg.Topic),
			zap.Error(err))
		observability.KafkaConsumed.WithLabelValues(msg.Topic, "error").Inc()
		return
	}

	// Re-serialise the event as the WebSocket push payload.
	// TODO(Phase-6): switch to Protobuf binary frame for lower overhead.
	payload, err := json.Marshal(&event)
	if err != nil {
		c.logger.Error("quote consumer marshal push payload failed", zap.Error(err))
		observability.KafkaConsumed.WithLabelValues(msg.Topic, "error").Inc()
		return
	}

	c.broadcaster.BroadcastQuote(event.Symbol, payload)
	observability.KafkaConsumed.WithLabelValues(msg.Topic, "ok").Inc()
}

func (c *QuoteConsumer) closeAll() {
	for _, r := range c.readers {
		_ = r.Close()
	}
}
