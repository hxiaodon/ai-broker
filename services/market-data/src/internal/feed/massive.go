// Package feed provides real-time market data feed handlers.
package feed

import (
	"context"
	"time"

	massivews "github.com/massive-com/client-go/v3/websocket"
	"github.com/massive-com/client-go/v3/websocket/models"
	"github.com/shopspring/decimal"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/observability"
)

// MassiveClient wraps the Massive SDK WebSocket client.
type MassiveClient struct {
	apiKey  string
	symbols []string
	client  *massivews.Client
	stream  chan *domain.Quote
}

// NewMassiveClient creates a new Massive WebSocket client.
func NewMassiveClient(apiKey string, symbols []string) *MassiveClient {
	return &MassiveClient{
		apiKey:  apiKey,
		symbols: symbols,
		stream:  make(chan *domain.Quote, 100),
	}
}

// Connect establishes WebSocket connection and subscribes to symbols.
func (m *MassiveClient) Connect(ctx context.Context) error {
	client, err := massivews.New(massivews.Config{
		APIKey: m.apiKey,
		Feed:   massivews.Delayed,
		Market: massivews.Stocks,
	})
	if err != nil {
		return err
	}
	m.client = client

	if err := m.client.Connect(); err != nil {
		return err
	}

	if err := m.client.Subscribe(massivews.StocksSecAggs, m.symbols...); err != nil {
		return err
	}

	go m.consumeEvents(ctx)
	return nil
}

// consumeEvents reads from Massive SDK and converts to domain.Quote.
func (m *MassiveClient) consumeEvents(ctx context.Context) {
	defer close(m.stream)
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-m.client.Output():
			if !ok {
				return
			}
			if agg, ok := msg.(models.EquityAgg); ok {
				quote := mapToQuote(&agg)
				select {
				case m.stream <- quote:
				case <-ctx.Done():
					return
				default:
					// Drop quote when buffer is full; increment metric so ops can alert on data loss.
					observability.DroppedQuotes.Inc()
				}
			}
		}
	}
}

// Stream returns the channel of parsed quotes.
func (m *MassiveClient) Stream() <-chan *domain.Quote {
	return m.stream
}

// Close closes the WebSocket connection.
func (m *MassiveClient) Close() error {
	if m.client != nil {
		m.client.Close()
	}
	return nil
}

// mapToQuote converts Massive EquityAgg to domain.Quote.
func mapToQuote(agg *models.EquityAgg) *domain.Quote {
	return &domain.Quote{
		Symbol:        agg.Symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(agg.Close),
		Open:          decimal.NewFromFloat(agg.Open),
		High:          decimal.NewFromFloat(agg.High),
		Low:           decimal.NewFromFloat(agg.Low),
		Volume:        int64(agg.Volume),
		LastUpdatedAt: time.UnixMilli(agg.EndTimestamp).UTC(),
	}
}
