// Package feed provides real-time market data feed handlers.
package feed

import (
	"context"
	"time"

	"github.com/shopspring/decimal"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// MockMassiveClient simulates Massive WebSocket client for testing.
type MockMassiveClient struct {
	symbols []string
	stream  chan *domain.Quote
	closed  bool
}

// NewMockMassiveClient creates a mock client for testing.
func NewMockMassiveClient(symbols []string) *MockMassiveClient {
	return &MockMassiveClient{
		symbols: symbols,
		stream:  make(chan *domain.Quote, 100),
	}
}

// Connect simulates connection (no-op for mock).
func (m *MockMassiveClient) Connect(ctx context.Context) error {
	return nil
}

// Stream returns the channel of mock quotes.
func (m *MockMassiveClient) Stream() <-chan *domain.Quote {
	return m.stream
}

// Close closes the mock client.
func (m *MockMassiveClient) Close() error {
	if !m.closed {
		close(m.stream)
		m.closed = true
	}
	return nil
}

// SendQuote injects a mock quote into the stream (for testing).
func (m *MockMassiveClient) SendQuote(quote *domain.Quote) {
	if !m.closed {
		m.stream <- quote
	}
}

// MockQuoteScenarios provides pre-built test scenarios.
type MockQuoteScenarios struct{}

// FreshQuote returns a quote with current timestamp (< 1s stale).
func (s *MockQuoteScenarios) FreshQuote(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		Open:          decimal.NewFromFloat(149.50),
		High:          decimal.NewFromFloat(151.00),
		Low:           decimal.NewFromFloat(149.00),
		Volume:        1000000,
		LastUpdatedAt: now.Add(-500 * time.Millisecond), // 0.5s ago
	}
}

// StaleQuote1s returns a quote that's 1.5s old (triggers 1s stale threshold).
func (s *MockQuoteScenarios) StaleQuote1s(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		Open:          decimal.NewFromFloat(149.50),
		High:          decimal.NewFromFloat(151.00),
		Low:           decimal.NewFromFloat(149.00),
		Volume:        1000000,
		LastUpdatedAt: now.Add(-1500 * time.Millisecond), // 1.5s ago
	}
}

// StaleQuote5s returns a quote that's 6s old (triggers 5s stale threshold).
func (s *MockQuoteScenarios) StaleQuote5s(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		Open:          decimal.NewFromFloat(149.50),
		High:          decimal.NewFromFloat(151.00),
		Low:           decimal.NewFromFloat(149.00),
		Volume:        1000000,
		LastUpdatedAt: now.Add(-6 * time.Second), // 6s ago
	}
}

// PreMarketQuote returns a delayed quote (15min delay).
func (s *MockQuoteScenarios) PreMarketQuote(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(148.75),
		Open:          decimal.NewFromFloat(148.50),
		High:          decimal.NewFromFloat(149.00),
		Low:           decimal.NewFromFloat(148.25),
		Volume:        50000,
		LastUpdatedAt: now.Add(-15 * time.Minute), // 15min delayed
	}
}

// MarketHoursQuote returns a typical market hours quote.
func (s *MockQuoteScenarios) MarketHoursQuote(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.50),
		Open:          decimal.NewFromFloat(149.75),
		High:          decimal.NewFromFloat(151.25),
		Low:           decimal.NewFromFloat(149.50),
		Volume:        2500000,
		LastUpdatedAt: now.Add(-200 * time.Millisecond), // 0.2s ago
	}
}

// AfterHoursQuote returns a post-market quote.
func (s *MockQuoteScenarios) AfterHoursQuote(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.75),
		Open:          decimal.NewFromFloat(150.50),
		High:          decimal.NewFromFloat(151.00),
		Low:           decimal.NewFromFloat(150.25),
		Volume:        100000,
		LastUpdatedAt: now.Add(-1 * time.Second), // 1s ago
	}
}

// HKQuote returns a Hong Kong market quote.
func (s *MockQuoteScenarios) HKQuote(symbol string) *domain.Quote {
	now := time.Now().UTC()
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketHK,
		Price:         decimal.NewFromFloat(388.60),
		Open:          decimal.NewFromFloat(387.00),
		High:          decimal.NewFromFloat(390.00),
		Low:           decimal.NewFromFloat(386.50),
		Volume:        5000000,
		LastUpdatedAt: now.Add(-300 * time.Millisecond), // 0.3s ago
	}
}
