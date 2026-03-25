package domain

import (
	"context"

	"github.com/shopspring/decimal"
)

// QuoteRepo defines the repository interface for quote persistence.
// Implementations live in infra/mysql and infra/redis — domain layer has zero external dependencies.
type QuoteRepo interface {
	// Save persists a quote to the database.
	Save(ctx context.Context, q *Quote) error
	// FindBySymbol retrieves the latest quote for a symbol.
	FindBySymbol(ctx context.Context, symbol string) (*Quote, error)
	// FindBySymbols retrieves quotes for multiple symbols.
	FindBySymbols(ctx context.Context, symbols []string) ([]*Quote, error)
	// GetBySymbolMarketTimestamp checks if a quote already exists for deduplication.
	GetBySymbolMarketTimestamp(ctx context.Context, symbol string, market Market, timestamp int64) (*Quote, error)
	// FindPrevClose returns the most recent closing price recorded before today's midnight UTC
	// for the given symbol+market. Used to compute Change and ChangePct when the feed does not
	// provide them. Returns decimal.Zero when no historical record exists.
	FindPrevClose(ctx context.Context, symbol string, market Market) (decimal.Decimal, error)
}

// QuoteCacheRepo defines the cache interface for real-time quote access.
type QuoteCacheRepo interface {
	// Set stores a quote in the cache.
	Set(ctx context.Context, q *Quote) error
	// Get retrieves a quote from the cache by market and symbol.
	Get(ctx context.Context, market Market, symbol string) (*Quote, error)
	// MGet retrieves quotes for multiple symbols from the cache (all from same market).
	MGet(ctx context.Context, market Market, symbols []string) ([]*Quote, error)
	// IsDedup returns true if a quote with this (market, symbol, tsMicro) has already been processed.
	// Implemented via Redis SET NX so the check and mark are atomic.
	IsDedup(ctx context.Context, symbol string, market Market, tsMicro int64) (bool, error)
}

// QuoteDelayedRepo stores and retrieves T-15min delayed quote snapshots for guest users.
// Spec: CLAUDE.md §10 — guest delayed quotes must use a ring buffer snapshot, not real-time data.
type QuoteDelayedRepo interface {
	// Push appends the current quote to the delayed ring buffer for the given symbol.
	Push(ctx context.Context, q *Quote) error
	// GetDelayed returns the most recent snapshot that is at least 15 minutes old.
	// Returns nil when no suitable snapshot exists (e.g., symbol just started trading).
	GetDelayed(ctx context.Context, market Market, symbol string) (*Quote, error)
}

// MarketStatusRepo defines the repository interface for market status.
type MarketStatusRepo interface {
	// GetStatus returns the current market status for an exchange.
	GetStatus(ctx context.Context, market Market) (*MarketStatus, error)
	// SetStatus updates the market status for an exchange.
	SetStatus(ctx context.Context, status *MarketStatus) error
}
