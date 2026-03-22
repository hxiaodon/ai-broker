// Package polygon provides a client for the Polygon.io market data API.
// This is a stub — domain engineers will implement the full feed handler.
package polygon

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/shopspring/decimal"
)

// Quote represents a quote snapshot from Polygon API.
type Quote struct {
	Symbol    string          // shopspring/decimal — never float64
	Price     decimal.Decimal // shopspring/decimal — never float64
	Bid       decimal.Decimal // shopspring/decimal — never float64
	Ask       decimal.Decimal // shopspring/decimal — never float64
	Volume    int64
	Timestamp time.Time // Always UTC
}

// Client is a Polygon API client.
type Client struct {
	apiKey  string
	baseURL string
	http    *http.Client
}

// NewClient creates a new Polygon API client.
func NewClient(apiKey, baseURL string) *Client {
	return &Client{
		apiKey:  apiKey,
		baseURL: baseURL,
		http: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// GetQuote fetches the latest quote for a given US symbol.
// STUB: domain engineer implements the actual Polygon API call.
func (c *Client) GetQuote(ctx context.Context, symbol string) (*Quote, error) {
	return nil, fmt.Errorf("polygon GetQuote not implemented for symbol %s", symbol)
}

// StreamQuotes opens a WebSocket connection to Polygon for real-time quotes.
// STUB: domain engineer implements the actual streaming connection.
func (c *Client) StreamQuotes(ctx context.Context, symbols []string) (<-chan Quote, error) {
	return nil, fmt.Errorf("polygon StreamQuotes not implemented")
}
