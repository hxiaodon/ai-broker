package app

import (
	"context"
	"fmt"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// GetQuoteUsecase handles retrieving a quote by symbol.
type GetQuoteUsecase struct {
	cacheRepo domain.QuoteCacheRepo
	quoteRepo domain.QuoteRepo
	stale     *domain.StaleDetector
	logger    *zap.Logger
}

// NewGetQuoteUsecase creates a new GetQuoteUsecase.
func NewGetQuoteUsecase(
	cacheRepo domain.QuoteCacheRepo,
	quoteRepo domain.QuoteRepo,
	stale *domain.StaleDetector,
	logger *zap.Logger,
) *GetQuoteUsecase {
	return &GetQuoteUsecase{
		cacheRepo: cacheRepo,
		quoteRepo: quoteRepo,
		stale:     stale,
		logger:    logger,
	}
}

// Execute retrieves a quote, preferring cache, falling back to DB.
func (uc *GetQuoteUsecase) Execute(ctx context.Context, market domain.Market, symbol string) (*domain.Quote, error) {
	if symbol == "" {
		return nil, fmt.Errorf("get quote: symbol must not be empty")
	}

	// 1. Try cache first.
	q, err := uc.cacheRepo.Get(ctx, market, symbol)
	if err != nil {
		uc.logger.Warn("cache get failed, falling back to DB",
			zap.String("symbol", symbol),
			zap.String("market", string(market)),
			zap.Error(err))
	}
	if q != nil {
		q.ApplyStaleCheck(uc.stale.Evaluate(q))
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

	q.ApplyStaleCheck(uc.stale.Evaluate(q))

	// 3. Populate cache for next request.
	if err := uc.cacheRepo.Set(ctx, q); err != nil {
		uc.logger.Warn("cache set failed after DB read",
			zap.String("symbol", symbol),
			zap.Error(err))
	}

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
