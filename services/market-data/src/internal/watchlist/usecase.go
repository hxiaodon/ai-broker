package watchlist

import (
	"context"
	"fmt"
	"time"
)

// GetWatchlistUsecase retrieves a user's watchlist.
type GetWatchlistUsecase struct {
	repo WatchlistRepo
}

// NewGetWatchlistUsecase creates a new GetWatchlistUsecase.
func NewGetWatchlistUsecase(repo WatchlistRepo) *GetWatchlistUsecase {
	return &GetWatchlistUsecase{repo: repo}
}

// Execute retrieves all watchlist items for the given user.
func (uc *GetWatchlistUsecase) Execute(ctx context.Context, userID string) ([]*WatchlistItem, error) {
	items, err := uc.repo.FindByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get watchlist user %s: %w", userID, err)
	}
	return items, nil
}

// AddToWatchlistUsecase adds a symbol to a user's watchlist.
type AddToWatchlistUsecase struct {
	repo      WatchlistRepo
	validator StockValidator
}

// NewAddToWatchlistUsecase creates a new AddToWatchlistUsecase.
func NewAddToWatchlistUsecase(repo WatchlistRepo, validator StockValidator) *AddToWatchlistUsecase {
	return &AddToWatchlistUsecase{repo: repo, validator: validator}
}

// Execute adds a symbol to the user's watchlist.
// Business rules:
//  1. Watchlist limit: maximum 100 symbols per user.
//  2. Idempotency: if the symbol is already in the watchlist, return nil (no error).
//  3. Symbol existence: the symbol must exist in the tradeable stocks universe.
func (uc *AddToWatchlistUsecase) Execute(ctx context.Context, userID string, symbol, market string) error {
	if symbol == "" {
		return fmt.Errorf("add to watchlist: symbol must not be empty")
	}

	// Rule 3: symbol must exist in stocks universe.
	exists, err := uc.validator.ExistsBySymbol(ctx, symbol)
	if err != nil {
		return fmt.Errorf("add to watchlist user %s symbol %s: validate symbol: %w", userID, symbol, err)
	}
	if !exists {
		return fmt.Errorf("add to watchlist user %s symbol %s: %w", userID, symbol, ErrSymbolNotFound)
	}

	// Rule 2: idempotency — already in watchlist is a no-op.
	alreadyExists, err := uc.repo.ExistsByUserAndSymbol(ctx, userID, symbol)
	if err != nil {
		return fmt.Errorf("add to watchlist user %s symbol %s: check exists: %w", userID, symbol, err)
	}
	if alreadyExists {
		return nil
	}

	// Rule 1: enforce 100-symbol cap.
	count, err := uc.repo.CountByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("add to watchlist user %s: count: %w", userID, err)
	}
	if count >= MaxWatchlistSize {
		return fmt.Errorf("add to watchlist user %s: %w", userID, ErrWatchlistFull)
	}

	item := &WatchlistItem{
		UserID:    userID,
		Symbol:    symbol,
		Market:    market,
		CreatedAt: time.Now().UTC(),
	}
	if err := uc.repo.Add(ctx, item); err != nil {
		return fmt.Errorf("add to watchlist user %s symbol %s: %w", userID, symbol, err)
	}
	return nil
}

// RemoveFromWatchlistUsecase removes a symbol from a user's watchlist.
type RemoveFromWatchlistUsecase struct {
	repo WatchlistRepo
}

// NewRemoveFromWatchlistUsecase creates a new RemoveFromWatchlistUsecase.
func NewRemoveFromWatchlistUsecase(repo WatchlistRepo) *RemoveFromWatchlistUsecase {
	return &RemoveFromWatchlistUsecase{repo: repo}
}

// Execute removes a symbol from the user's watchlist.
func (uc *RemoveFromWatchlistUsecase) Execute(ctx context.Context, userID string, symbol string) error {
	if symbol == "" {
		return fmt.Errorf("remove from watchlist: symbol must not be empty")
	}
	if err := uc.repo.Remove(ctx, userID, symbol); err != nil {
		return fmt.Errorf("remove from watchlist user %s symbol %s: %w", userID, symbol, err)
	}
	return nil
}
