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

// Client is an HKEX feed client with retry and circuit breaker.
type Client struct {
	endpoint       string
	maxRetries     int
	circuitBreaker *circuitBreaker
}

type circuitBreaker struct {
	failures    int
	lastFailure time.Time
	state       string // "closed", "open", "half-open"
}

// NewClient creates a new HKEX feed client.
func NewClient(endpoint string) *Client {
	return &Client{
		endpoint:   endpoint,
		maxRetries: 3,
		circuitBreaker: &circuitBreaker{
			state: "closed",
		},
	}
}

// GetQuote fetches the latest quote for a given HK symbol with retry and circuit breaker.
func (c *Client) GetQuote(ctx context.Context, symbol string) (*Quote, error) {
	if c.circuitBreaker.isOpen() {
		return nil, fmt.Errorf("circuit breaker open for hkex feed")
	}

	var lastErr error
	for attempt := 0; attempt < c.maxRetries; attempt++ {
		if attempt > 0 {
			backoff := time.Duration(1<<uint(attempt-1)) * time.Second
			time.Sleep(backoff)
		}

		quote, err := c.doGetQuote(ctx, symbol)
		if err == nil {
			c.circuitBreaker.recordSuccess()
			return quote, nil
		}
		lastErr = err
	}

	c.circuitBreaker.recordFailure()
	return nil, fmt.Errorf("hkex GetQuote failed after %d retries: %w", c.maxRetries, lastErr)
}

func (c *Client) doGetQuote(ctx context.Context, symbol string) (*Quote, error) {
	return nil, fmt.Errorf("hkex GetQuote not implemented for symbol %s", symbol)
}

// StreamQuotes opens a connection to the HKEX feed for real-time quotes.
// STUB: domain engineer implements the actual streaming connection.
func (c *Client) StreamQuotes(ctx context.Context, symbols []string) (<-chan Quote, error) {
	return nil, fmt.Errorf("hkex StreamQuotes not implemented")
}

func (cb *circuitBreaker) isOpen() bool {
	if cb.state == "open" {
		if time.Since(cb.lastFailure) > 30*time.Second {
			cb.state = "half-open"
			return false
		}
		return true
	}
	return false
}

func (cb *circuitBreaker) recordSuccess() {
	cb.failures = 0
	cb.state = "closed"
}

func (cb *circuitBreaker) recordFailure() {
	cb.failures++
	cb.lastFailure = time.Now()
	if cb.failures >= 5 {
		cb.state = "open"
	}
}
