// Package watchlist implements the user watchlist subdomain (degenerate DDD form).
// domain.go holds entities and repository interfaces — the domain layer.
package watchlist

import (
	"context"
	"fmt"
	"time"
)

// WatchlistItem is the aggregate root for a user's watchlist entry.
type WatchlistItem struct {
	ID        int64
	UserID    string // UUID (CHAR(36))
	Symbol    string
	Market    string // "US" or "HK"
	SortOrder int
	CreatedAt time.Time // Always UTC
}

// MaxWatchlistSize is the maximum number of symbols a user can have in their watchlist.
const MaxWatchlistSize = 100

// ErrWatchlistFull is returned when a user tries to add beyond the 100-symbol limit.
var ErrWatchlistFull = fmt.Errorf("watchlist: limit of %d symbols reached", MaxWatchlistSize)

// ErrSymbolNotFound is returned when the symbol does not exist in the stocks universe.
var ErrSymbolNotFound = fmt.Errorf("watchlist: symbol not found in stocks universe")

// WatchlistRepo defines the repository interface for watchlist persistence.
type WatchlistRepo interface {
	// FindByUserID retrieves all watchlist items for a user, ordered by sort_order.
	FindByUserID(ctx context.Context, userID string) ([]*WatchlistItem, error)
	// CountByUserID returns the number of watchlist items for a user.
	CountByUserID(ctx context.Context, userID string) (int, error)
	// ExistsByUserAndSymbol returns true if the user already has the symbol in their watchlist.
	ExistsByUserAndSymbol(ctx context.Context, userID string, symbol string) (bool, error)
	// Add adds a symbol to the user's watchlist.
	Add(ctx context.Context, item *WatchlistItem) error
	// Remove removes a symbol from the user's watchlist.
	Remove(ctx context.Context, userID string, symbol string) error
	// Reorder updates the sort order for a user's watchlist items.
	Reorder(ctx context.Context, userID string, symbolOrder []string) error
}

// StockValidator checks whether a symbol exists in the tradeable stocks universe.
// Implemented by the search infra layer; injected into watchlist use cases to avoid
// direct cross-package imports.
type StockValidator interface {
	ExistsBySymbol(ctx context.Context, symbol string) (bool, error)
}
