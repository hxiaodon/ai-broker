package search

import (
	"context"
	"fmt"
)

// SearchStocksUsecase handles stock search queries.
type SearchStocksUsecase struct {
	stockRepo StockSearchRepo
	hotRepo   HotSearchRepo
}

// NewSearchStocksUsecase creates a new SearchStocksUsecase.
func NewSearchStocksUsecase(stockRepo StockSearchRepo, hotRepo HotSearchRepo) *SearchStocksUsecase {
	return &SearchStocksUsecase{
		stockRepo: stockRepo,
		hotRepo:   hotRepo,
	}
}

// Execute searches stocks and increments the hot search score for the query.
func (uc *SearchStocksUsecase) Execute(ctx context.Context, query string, market string, limit int) ([]*Stock, error) {
	if query == "" {
		return nil, fmt.Errorf("search stocks: query must not be empty")
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	stocks, err := uc.stockRepo.Search(ctx, query, market, limit)
	if err != nil {
		return nil, fmt.Errorf("search stocks %q: %w", query, err)
	}

	// Increment hot search ranking (best-effort, do not fail the search).
	if len(stocks) > 0 {
		_ = uc.hotRepo.IncrementScore(ctx, stocks[0].Symbol)
	}

	return stocks, nil
}

// GetHotSearchUsecase retrieves trending search items.
type GetHotSearchUsecase struct {
	hotRepo HotSearchRepo
}

// NewGetHotSearchUsecase creates a new GetHotSearchUsecase.
func NewGetHotSearchUsecase(hotRepo HotSearchRepo) *GetHotSearchUsecase {
	return &GetHotSearchUsecase{hotRepo: hotRepo}
}

// Execute retrieves the top N hot search items.
func (uc *GetHotSearchUsecase) Execute(ctx context.Context, n int) ([]*HotSearchItem, error) {
	if n <= 0 {
		n = 10
	}
	if n > 50 {
		n = 50
	}
	items, err := uc.hotRepo.GetTopN(ctx, n)
	if err != nil {
		return nil, fmt.Errorf("get hot search: %w", err)
	}
	return items, nil
}
