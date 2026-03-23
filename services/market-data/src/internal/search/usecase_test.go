package search

import (
	"context"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ─── Mocks ────────────────────────────────────────────────────────────────────

type mockStockSearchRepo struct {
	results []*Stock
	err     error
}

func (m *mockStockSearchRepo) Search(_ context.Context, _ string, _ string, _ int) ([]*Stock, error) {
	return m.results, m.err
}

func (m *mockStockSearchRepo) GetBySymbol(_ context.Context, symbol string) (*Stock, error) {
	for _, s := range m.results {
		if s.Symbol == symbol {
			return s, nil
		}
	}
	return nil, nil
}

type mockHotSearchRepo struct {
	incrementCalled int
	incrementErr    error
	topN            []*HotSearchItem
	topNErr         error
}

func (m *mockHotSearchRepo) IncrementScore(_ context.Context, _ string) error {
	m.incrementCalled++
	return m.incrementErr
}

func (m *mockHotSearchRepo) GetTopN(_ context.Context, n int) ([]*HotSearchItem, error) {
	if m.topNErr != nil {
		return nil, m.topNErr
	}
	if len(m.topN) > n {
		return m.topN[:n], nil
	}
	return m.topN, nil
}

// ─── SearchStocksUsecase ─────────────────────────────────────────────────────

func TestSearchStocks_EmptyQuery(t *testing.T) {
	uc := NewSearchStocksUsecase(nil, nil)
	_, err := uc.Execute(context.Background(), "", "", 20)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "query must not be empty")
}

func TestSearchStocks_LimitClamping(t *testing.T) {
	// limit ≤ 0 defaults to 20; limit > 100 is clamped to 100.
	repo := &mockStockSearchRepo{results: []*Stock{{Symbol: "AAPL", Name: "Apple Inc.", Market: "US"}}}
	hot := &mockHotSearchRepo{}

	uc := NewSearchStocksUsecase(repo, hot)

	// 0 → 20 (no error, just verifying it doesn't panic)
	_, err := uc.Execute(context.Background(), "AAPL", "", 0)
	require.NoError(t, err)

	// 9999 → 100 (no error, verifying clamp)
	_, err = uc.Execute(context.Background(), "AAPL", "", 9999)
	require.NoError(t, err)
}

func TestSearchStocks_IncrementsHotScore_OnResults(t *testing.T) {
	// Spec: SearchStocksUsecase must increment the hot search score for the top result.
	repo := &mockStockSearchRepo{
		results: []*Stock{
			{Symbol: "AAPL", Name: "Apple Inc.", Market: "US"},
			{Symbol: "MSFT", Name: "Microsoft", Market: "US"},
		},
	}
	hot := &mockHotSearchRepo{}

	uc := NewSearchStocksUsecase(repo, hot)
	results, err := uc.Execute(context.Background(), "apple", "", 20)

	require.NoError(t, err)
	assert.Len(t, results, 2)
	assert.Equal(t, 1, hot.incrementCalled, "IncrementScore must be called once for the top result")
}

func TestSearchStocks_NoHotIncrement_WhenNoResults(t *testing.T) {
	// If the search returns no results, hot score must NOT be incremented.
	repo := &mockStockSearchRepo{results: []*Stock{}} // empty
	hot := &mockHotSearchRepo{}

	uc := NewSearchStocksUsecase(repo, hot)
	_, err := uc.Execute(context.Background(), "xyz_unknown", "", 20)

	require.NoError(t, err)
	assert.Equal(t, 0, hot.incrementCalled, "IncrementScore must not be called when no results found")
}

func TestSearchStocks_BestEffort_HotScoreFailureDoesNotFailSearch(t *testing.T) {
	// Spec: hot search ranking is best-effort — a Redis failure must not fail the search.
	repo := &mockStockSearchRepo{
		results: []*Stock{{Symbol: "AAPL", Name: "Apple Inc.", Market: "US"}},
	}
	hot := &mockHotSearchRepo{incrementErr: errors.New("redis: connection refused")}

	uc := NewSearchStocksUsecase(repo, hot)
	results, err := uc.Execute(context.Background(), "AAPL", "", 20)

	require.NoError(t, err, "hot score failure must not propagate to caller")
	assert.Len(t, results, 1)
}

func TestSearchStocks_DBError_Propagated(t *testing.T) {
	// A DB error in the search repo must be returned to the caller.
	repo := &mockStockSearchRepo{err: errors.New("db: deadlock")}
	hot := &mockHotSearchRepo{}

	uc := NewSearchStocksUsecase(repo, hot)
	_, err := uc.Execute(context.Background(), "AAPL", "", 20)

	require.Error(t, err)
	assert.Contains(t, err.Error(), "deadlock")
}

// ─── GetHotSearchUsecase ──────────────────────────────────────────────────────

func TestGetHotSearch_DefaultN(t *testing.T) {
	// n ≤ 0 must default to 10.
	hot := &mockHotSearchRepo{topN: make([]*HotSearchItem, 15)}
	uc := NewGetHotSearchUsecase(hot)

	results, err := uc.Execute(context.Background(), 0)
	require.NoError(t, err)
	assert.Len(t, results, 10, "n=0 must default to 10")
}

func TestGetHotSearch_LimitClamping(t *testing.T) {
	// n > 50 is clamped to 50.
	hot := &mockHotSearchRepo{topN: make([]*HotSearchItem, 60)}
	uc := NewGetHotSearchUsecase(hot)

	results, err := uc.Execute(context.Background(), 200)
	require.NoError(t, err)
	assert.Len(t, results, 50, "n > 50 must be clamped to 50")
}

func TestGetHotSearch_ReturnsItems(t *testing.T) {
	hot := &mockHotSearchRepo{
		topN: []*HotSearchItem{
			{Symbol: "AAPL", Score: 100},
			{Symbol: "TSLA", Score: 90},
		},
	}
	uc := NewGetHotSearchUsecase(hot)

	results, err := uc.Execute(context.Background(), 10)
	require.NoError(t, err)
	assert.Len(t, results, 2)
	assert.Equal(t, "AAPL", results[0].Symbol)
}

func TestGetHotSearch_RepoError_Propagated(t *testing.T) {
	hot := &mockHotSearchRepo{topNErr: errors.New("redis: timeout")}
	uc := NewGetHotSearchUsecase(hot)

	_, err := uc.Execute(context.Background(), 10)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "timeout")
}
