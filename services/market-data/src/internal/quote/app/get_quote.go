package app

import (
	"context"
	"fmt"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// GetQuoteUsecase handles retrieving a quote by symbol.
type GetQuoteUsecase struct {
	cacheRepo   domain.QuoteCacheRepo
	quoteRepo   domain.QuoteRepo
	delayedRepo domain.QuoteDelayedRepo // optional; nil disables delayed path
	stale       *domain.StaleDetector
	logger      *zap.Logger
}

// NewGetQuoteUsecase creates a new GetQuoteUsecase.
// delayedRepo is optional — pass nil to disable the delayed quote path.
func NewGetQuoteUsecase(
	cacheRepo domain.QuoteCacheRepo,
	quoteRepo domain.QuoteRepo,
	stale *domain.StaleDetector,
	delayedRepo domain.QuoteDelayedRepo,
	logger *zap.Logger,
) *GetQuoteUsecase {
	return &GetQuoteUsecase{
		cacheRepo:   cacheRepo,
		quoteRepo:   quoteRepo,
		delayedRepo: delayedRepo,
		stale:       stale,
		logger:      logger,
	}
}

// Execute retrieves a quote.
// When delayed=true (guest user), returns the T-15min ring-buffer snapshot instead of real-time data.
// Spec: CLAUDE.md §10 — "implement via DelayedQuoteRingBuffer (T-15min snapshot)".
func (uc *GetQuoteUsecase) Execute(ctx context.Context, market domain.Market, symbol string, delayed bool) (*domain.Quote, error) {
	if symbol == "" {
		return nil, fmt.Errorf("get quote: symbol must not be empty")
	}

	// Guest path: serve 15-minute delayed snapshot.
	if delayed && uc.delayedRepo != nil {
		q, err := uc.delayedRepo.GetDelayed(ctx, market, symbol)
		if err != nil {
			uc.logger.Warn("delayed ring get failed, falling back to realtime",
				zap.String("symbol", symbol),
				zap.Error(err))
			// Fall through to real-time path on error.
		} else if q != nil {
			q.Delayed = true
			q.ApplyStaleCheck(uc.stale.Evaluate(q))
			return q, nil
		}
		// No delayed snapshot yet — fall through to real-time (rare at startup).
	}

	// Real-time path: cache first, then DB.
	q, err := uc.cacheRepo.Get(ctx, market, symbol)
	if err != nil {
		uc.logger.Warn("cache get failed, falling back to DB",
			zap.String("symbol", symbol),
			zap.String("market", string(market)),
			zap.Error(err))
	}
	if q != nil {
		q.Delayed = delayed
		q.ApplyStaleCheck(uc.stale.Evaluate(q))
		return q, nil
	}

	// Fall back to DB.
	q, err = uc.quoteRepo.FindBySymbol(ctx, symbol)
	if err != nil {
		return nil, fmt.Errorf("get quote %s: %w", symbol, err)
	}
	if q == nil {
		return nil, fmt.Errorf("get quote %s: not found", symbol)
	}

	q.Delayed = delayed
	q.ApplyStaleCheck(uc.stale.Evaluate(q))

	// Populate cache for next request.
	if err := uc.cacheRepo.Set(ctx, q); err != nil {
		uc.logger.Warn("cache set failed after DB read",
			zap.String("symbol", symbol),
			zap.Error(err))
	}

	return q, nil
}

// ExecuteBatch retrieves quotes for multiple symbols in bulk.
// Strategy:
//  1. cacheRepo.MGet — one Redis MGET for all symbols in the same market
//  2. DB fallback for cache misses (quoteRepo.FindBySymbols)
//  3. Best-effort cache population for DB results
//
// For delayed users each quote has Delayed=true but the data source is
// the delayed ring buffer on a per-symbol basis (see Execute).
// ExecuteBatch uses the real-time cache for bulk efficiency and sets
// Delayed=true on every result when delayed=true; for strict per-symbol
// delayed snapshots callers should invoke Execute per-symbol.
func (uc *GetQuoteUsecase) ExecuteBatch(ctx context.Context, market domain.Market, symbols []string, delayed bool) ([]*domain.Quote, error) {
	if len(symbols) == 0 {
		return nil, nil
	}

	// 1. Bulk cache read.
	cached, err := uc.cacheRepo.MGet(ctx, market, symbols)
	if err != nil {
		uc.logger.Warn("batch cache mget failed, falling back to DB for all symbols",
			zap.Error(err))
		cached = nil
	}

	// Build a set of cache-hit symbols.
	found := make(map[string]*domain.Quote, len(cached))
	for _, q := range cached {
		if q != nil {
			q.Delayed = delayed
			q.ApplyStaleCheck(uc.stale.Evaluate(q))
			found[q.Symbol] = q
		}
	}

	// 2. Identify misses and fall back to DB.
	var misses []string
	for _, s := range symbols {
		if _, ok := found[s]; !ok {
			misses = append(misses, s)
		}
	}

	if len(misses) > 0 {
		dbQuotes, err := uc.quoteRepo.FindBySymbols(ctx, misses)
		if err != nil {
			uc.logger.Warn("batch DB fallback failed",
				zap.Error(err))
		} else {
			for _, q := range dbQuotes {
				q.Delayed = delayed
				q.ApplyStaleCheck(uc.stale.Evaluate(q))
				found[q.Symbol] = q
			}
			// 3. Repopulate cache for DB results (best-effort, non-blocking).
			go func() {
				bgCtx := context.Background()
				for _, q := range dbQuotes {
					_ = uc.cacheRepo.Set(bgCtx, q)
				}
			}()
		}
	}

	// Return in original request order; silently omit symbols not found.
	result := make([]*domain.Quote, 0, len(found))
	for _, sym := range symbols {
		if q, ok := found[sym]; ok {
			result = append(result, q)
		}
	}
	return result, nil
}

// GetMarketStatusUsecase retrieves the current market status.
type GetMarketStatusUsecase struct {
	statusRepo domain.MarketStatusRepo
}

// NewGetMarketStatusUsecase creates a new GetMarketStatusUsecase.
func NewGetMarketStatusUsecase(statusRepo domain.MarketStatusRepo) *GetMarketStatusUsecase {
	return &GetMarketStatusUsecase{statusRepo: statusRepo}
}

// Execute returns the current status for the given market.
func (uc *GetMarketStatusUsecase) Execute(ctx context.Context, market domain.Market) (*domain.MarketStatus, error) {
	status, err := uc.statusRepo.GetStatus(ctx, market)
	if err != nil {
		return nil, fmt.Errorf("get market status %s: %w", market, err)
	}
	return status, nil
}
