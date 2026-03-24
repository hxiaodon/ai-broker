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

// Client is a Polygon API client with retry and circuit breaker.
type Client struct {
	apiKey         string
	baseURL        string
	http           *http.Client
	maxRetries     int
	circuitBreaker *circuitBreaker
}

type circuitBreaker struct {
	failures    int
	lastFailure time.Time
	state       string // "closed", "open", "half-open"
}

// NewClient creates a new Polygon API client.
func NewClient(apiKey, baseURL string) *Client {
	return &Client{
		apiKey:  apiKey,
		baseURL: baseURL,
		http: &http.Client{
			Timeout: 10 * time.Second,
		},
		maxRetries: 3,
		circuitBreaker: &circuitBreaker{
			state: "closed",
		},
	}
}

// GetQuote fetches the latest quote for a given US symbol with retry and circuit breaker.
func (c *Client) GetQuote(ctx context.Context, symbol string) (*Quote, error) {
	if c.circuitBreaker.isOpen() {
		return nil, fmt.Errorf("circuit breaker open for polygon API")
	}

	var lastErr error
	for attempt := 0; attempt < c.maxRetries; attempt++ {
		if attempt > 0 {
			backoff := time.Duration(1<<uint(attempt-1)) * time.Second
			time.Sleep(backoff)
		}

		// STUB: actual API call would go here
		quote, err := c.doGetQuote(ctx, symbol)
		if err == nil {
			c.circuitBreaker.recordSuccess()
			return quote, nil
		}
		lastErr = err
	}

	c.circuitBreaker.recordFailure()
	return nil, fmt.Errorf("polygon GetQuote failed after %d retries: %w", c.maxRetries, lastErr)
}

func (c *Client) doGetQuote(ctx context.Context, symbol string) (*Quote, error) {
	return nil, fmt.Errorf("polygon GetQuote not implemented for symbol %s", symbol)
}

// StreamQuotes opens a WebSocket connection to Polygon for real-time quotes.
// STUB: domain engineer implements the actual streaming connection.
func (c *Client) StreamQuotes(ctx context.Context, symbols []string) (<-chan Quote, error) {
	return nil, fmt.Errorf("polygon StreamQuotes not implemented")
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
