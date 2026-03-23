package feed

import (
	"testing"

	"github.com/massive-com/client-go/v3/websocket/models"
	"github.com/shopspring/decimal"
)

// TestMapToQuote tests the mapping from Massive EquityAgg to domain.Quote.
func TestMapToQuote(t *testing.T) {
	agg := &models.EquityAgg{
		Symbol:       "AAPL",
		Open:         150.0,
		High:         152.5,
		Low:          149.5,
		Close:        151.0,
		Volume:       1000000,
		EndTimestamp: 1700000000000, // 2023-11-14 22:13:20 UTC
	}

	quote := mapToQuote(agg)

	if quote.Symbol != "AAPL" {
		t.Errorf("expected symbol AAPL, got %s", quote.Symbol)
	}
	if !quote.Price.Equal(decimal.NewFromFloat(151.0)) {
		t.Errorf("expected price 151.0, got %s", quote.Price)
	}
	if quote.Volume != 1000000 {
		t.Errorf("expected volume 1000000, got %d", quote.Volume)
	}
	if quote.LastUpdatedAt.Unix() != 1700000000 {
		t.Errorf("expected timestamp 1700000000, got %d", quote.LastUpdatedAt.Unix())
	}
}

// TestNewMassiveClient tests client creation.
func TestNewMassiveClient(t *testing.T) {
	apiKey := "test-key"
	symbols := []string{"X:BTCUSD", "X:ETHUSD"}

	client := NewMassiveClient(apiKey, symbols)

	if client.apiKey != apiKey {
		t.Errorf("expected apiKey %s, got %s", apiKey, client.apiKey)
	}
	if len(client.symbols) != 2 {
		t.Errorf("expected 2 symbols, got %d", len(client.symbols))
	}
	if client.stream == nil {
		t.Error("expected stream channel to be initialized")
	}
}
