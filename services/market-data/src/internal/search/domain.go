// Package search implements the stock search subdomain (degenerate DDD form).
// domain.go holds entities and repository interfaces — the domain layer.
package search

import "context"

// Stock represents a searchable stock entity.
type Stock struct {
	Symbol   string
	Name     string // Company name
	NameCN   string // Chinese company name
	Market   string // "US" or "HK"
	Exchange string // "NYSE", "NASDAQ", "HKEX"
	Sector   string
	Industry string
}

// HotSearchItem represents a trending search term.
type HotSearchItem struct {
	Symbol string
	Name   string
	Score  float64 // Redis sorted set score — display ranking only, not financial
}

// StockSearchRepo defines the repository interface for stock search.
type StockSearchRepo interface {
	// Search performs full-text search on stocks by symbol or name.
	Search(ctx context.Context, query string, market string, limit int) ([]*Stock, error)
	// GetBySymbol retrieves a single stock by exact symbol.
	GetBySymbol(ctx context.Context, symbol string) (*Stock, error)
}

// HotSearchRepo defines the repository interface for hot search ranking.
type HotSearchRepo interface {
	// IncrementScore increments the search score for a symbol.
	IncrementScore(ctx context.Context, symbol string) error
	// GetTopN retrieves the top N hot search items.
	GetTopN(ctx context.Context, n int) ([]*HotSearchItem, error)
}
