package app

import (
	"context"
	"fmt"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// GetQuoteUsecase handles retrieving a quote by symbol.
type GetQuoteUsecase struct {
	cacheRepo domain.QuoteCacheRepo
	quoteRepo domain.QuoteRepo
	stale     *domain.StaleDetector
}

// NewGetQuoteUsecase creates a new GetQuoteUsecase.
func NewGetQuoteUsecase(
	cacheRepo domain.QuoteCacheRepo,
	quoteRepo domain.QuoteRepo,
	stale *domain.StaleDetector,
) *GetQuoteUsecase {
	return &GetQuoteUsecase{
		cacheRepo: cacheRepo,
		quoteRepo: quoteRepo,
		stale:     stale,
	}
}

// Execute retrieves a quote, preferring cache, falling back to DB.
func (uc *GetQuoteUsecase) Execute(ctx context.Context, symbol string) (*domain.Quote, error) {
	if symbol == "" {
		return nil, fmt.Errorf("get quote: symbol must not be empty")
	}

	// 1. Try cache first.
	q, err := uc.cacheRepo.Get(ctx, symbol)
	if err == nil && q != nil {
		uc.stale.Evaluate(q)
		return q, nil
	}

	// 2. Fall back to DB.
	q, err = uc.quoteRepo.FindBySymbol(ctx, symbol)
	if err != nil {
		return nil, fmt.Errorf("get quote %s: %w", symbol, err)
	}
	if q == nil {
		return nil, fmt.Errorf("get quote %s: not found", symbol)
	}

	uc.stale.Evaluate(q)

	// 3. Populate cache for next request.
	_ = uc.cacheRepo.Set(ctx, q)

	return q, nil
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
