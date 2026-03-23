package domain

import "context"

// QuoteRepo defines the repository interface for quote persistence.
// Implementations live in infra/mysql and infra/redis — domain layer has zero external dependencies.
type QuoteRepo interface {
	// Save persists a quote to the database.
	Save(ctx context.Context, q *Quote) error
	// FindBySymbol retrieves the latest quote for a symbol.
	FindBySymbol(ctx context.Context, symbol string) (*Quote, error)
	// FindBySymbols retrieves quotes for multiple symbols.
	FindBySymbols(ctx context.Context, symbols []string) ([]*Quote, error)
}

// QuoteCacheRepo defines the cache interface for real-time quote access.
type QuoteCacheRepo interface {
	// Set stores a quote in the cache.
	Set(ctx context.Context, q *Quote) error
	// Get retrieves a quote from the cache by market and symbol.
	Get(ctx context.Context, market Market, symbol string) (*Quote, error)
	// MGet retrieves quotes for multiple symbols from the cache (all from same market).
	MGet(ctx context.Context, market Market, symbols []string) ([]*Quote, error)
}

// MarketStatusRepo defines the repository interface for market status.
type MarketStatusRepo interface {
	// GetStatus returns the current market status for an exchange.
	GetStatus(ctx context.Context, market Market) (*MarketStatus, error)
	// SetStatus updates the market status for an exchange.
	SetStatus(ctx context.Context, status *MarketStatus) error
}
