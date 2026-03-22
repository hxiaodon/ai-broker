// Package hkex provides a client for the HKEX market data feed.
// This is a stub — domain engineers will implement the full feed handler.
package hkex

import (
	"context"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
)

// Quote represents a quote snapshot from HKEX.
type Quote struct {
	Symbol    string          // e.g., "00700" (Tencent)
	Price     decimal.Decimal // shopspring/decimal — never float64
	Bid       decimal.Decimal // shopspring/decimal — never float64
	Ask       decimal.Decimal // shopspring/decimal — never float64
	Volume    int64
	Timestamp time.Time // Always UTC
}

// Client is an HKEX feed client.
type Client struct {
	endpoint string
}

// NewClient creates a new HKEX feed client.
func NewClient(endpoint string) *Client {
	return &Client{
		endpoint: endpoint,
	}
}

// GetQuote fetches the latest quote for a given HK symbol.
// STUB: domain engineer implements the actual HKEX API call.
func (c *Client) GetQuote(ctx context.Context, symbol string) (*Quote, error) {
	return nil, fmt.Errorf("hkex GetQuote not implemented for symbol %s", symbol)
}

// StreamQuotes opens a connection to the HKEX feed for real-time quotes.
// STUB: domain engineer implements the actual streaming connection.
func (c *Client) StreamQuotes(ctx context.Context, symbols []string) (<-chan Quote, error) {
	return nil, fmt.Errorf("hkex StreamQuotes not implemented")
}
