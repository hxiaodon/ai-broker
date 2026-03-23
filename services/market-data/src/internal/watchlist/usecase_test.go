package watchlist

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

// ─── Mocks ───────────────────────────────────────────────────────────────────

type MockWatchlistRepo struct{ mock.Mock }

func (m *MockWatchlistRepo) FindByUserID(ctx context.Context, userID string) ([]*WatchlistItem, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*WatchlistItem), args.Error(1)
}

func (m *MockWatchlistRepo) CountByUserID(ctx context.Context, userID string) (int, error) {
	args := m.Called(ctx, userID)
	return args.Int(0), args.Error(1)
}

func (m *MockWatchlistRepo) ExistsByUserAndSymbol(ctx context.Context, userID string, symbol string) (bool, error) {
	args := m.Called(ctx, userID, symbol)
	return args.Bool(0), args.Error(1)
}

func (m *MockWatchlistRepo) Add(ctx context.Context, item *WatchlistItem) error {
	args := m.Called(ctx, item)
	return args.Error(0)
}

func (m *MockWatchlistRepo) Remove(ctx context.Context, userID string, symbol string) error {
	args := m.Called(ctx, userID, symbol)
	return args.Error(0)
}

func (m *MockWatchlistRepo) Reorder(ctx context.Context, userID string, symbolOrder []string) error {
	args := m.Called(ctx, userID, symbolOrder)
	return args.Error(0)
}

type MockStockValidator struct{ mock.Mock }

func (m *MockStockValidator) ExistsBySymbol(ctx context.Context, symbol string) (bool, error) {
	args := m.Called(ctx, symbol)
	return args.Bool(0), args.Error(1)
}

// ─── AddToWatchlist tests ────────────────────────────────────────────────────

func TestAddToWatchlist_EmptySymbol(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "", "US")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}

func TestAddToWatchlist_SymbolNotFound(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "INVALID").Return(false, nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "INVALID", "US")
	assert.Error(t, err)
	assert.ErrorIs(t, err, ErrSymbolNotFound)
}

func TestAddToWatchlist_Idempotent(t *testing.T) {
	// Adding an already-watched symbol must return nil, not an error.
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "AAPL").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, "user-uuid-001", "AAPL").Return(true, nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "AAPL", "US")
	assert.NoError(t, err)
	repo.AssertNotCalled(t, "Add")
}

func TestAddToWatchlist_LimitExceeded(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "TSLA").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, "user-uuid-001", "TSLA").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, "user-uuid-001").Return(100, nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "TSLA", "US")
	assert.Error(t, err)
	assert.ErrorIs(t, err, ErrWatchlistFull)
}

func TestAddToWatchlist_Success(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "AAPL").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, "user-uuid-001", "AAPL").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, "user-uuid-001").Return(5, nil)
	repo.On("Add", mock.Anything, mock.AnythingOfType("*watchlist.WatchlistItem")).Return(nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "AAPL", "US")
	assert.NoError(t, err)
	repo.AssertExpectations(t)
}

// ─── GetWatchlist tests ───────────────────────────────────────────────────────

func TestGetWatchlist_ReturnsItemsInSortOrder(t *testing.T) {
	// Spec: watchlist items must be returned ordered by sort_order ASC (set by repo).
	repo := new(MockWatchlistRepo)

	ordered := []*WatchlistItem{
		{UserID: "user-uuid-001", Symbol: "AAPL", Market: "US", SortOrder: 0},
		{UserID: "user-uuid-001", Symbol: "TSLA", Market: "US", SortOrder: 1},
		{UserID: "user-uuid-001", Symbol: "00700", Market: "HK", SortOrder: 2},
	}
	repo.On("FindByUserID", mock.Anything, "user-uuid-001").Return(ordered, nil)

	uc := NewGetWatchlistUsecase(repo)
	items, err := uc.Execute(context.Background(), "user-uuid-001")

	require.NoError(t, err)
	require.Len(t, items, 3)
	assert.Equal(t, "AAPL", items[0].Symbol)
	assert.Equal(t, "TSLA", items[1].Symbol)
	assert.Equal(t, "00700", items[2].Symbol)
}

func TestGetWatchlist_EmptyWatchlist(t *testing.T) {
	// User with no watchlist items should return empty slice, not error.
	repo := new(MockWatchlistRepo)
	repo.On("FindByUserID", mock.Anything, "user-uuid-002").Return([]*WatchlistItem{}, nil)

	uc := NewGetWatchlistUsecase(repo)
	items, err := uc.Execute(context.Background(), "user-uuid-002")

	require.NoError(t, err)
	assert.Empty(t, items)
}

func TestGetWatchlist_RepoError_Propagated(t *testing.T) {
	repo := new(MockWatchlistRepo)
	repo.On("FindByUserID", mock.Anything, "user-uuid-001").Return(nil, errors.New("db: deadlock"))

	uc := NewGetWatchlistUsecase(repo)
	_, err := uc.Execute(context.Background(), "user-uuid-001")

	require.Error(t, err)
	assert.Contains(t, err.Error(), "deadlock")
}

func TestAddToWatchlist_MarketFieldPreserved(t *testing.T) {
	// The Market field (US/HK) must be persisted exactly as provided.
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "00700").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, "user-uuid-001", "00700").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, "user-uuid-001").Return(0, nil)
	repo.On("Add", mock.Anything, mock.AnythingOfType("*watchlist.WatchlistItem")).Return(nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "00700", "HK")
	require.NoError(t, err)

	// Verify the item was added with the correct market.
	call := repo.Calls[len(repo.Calls)-1]
	item := call.Arguments[1].(*WatchlistItem)
	assert.Equal(t, "HK", item.Market, "Market must be preserved as HK")
	assert.Equal(t, "00700", item.Symbol)
}

func TestAddToWatchlist_TimestampIsUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — CreatedAt must be UTC.
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "AAPL").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, "user-uuid-001", "AAPL").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, "user-uuid-001").Return(0, nil)
	repo.On("Add", mock.Anything, mock.AnythingOfType("*watchlist.WatchlistItem")).Return(nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "AAPL", "US")
	require.NoError(t, err)

	call := repo.Calls[len(repo.Calls)-1]
	item := call.Arguments[1].(*WatchlistItem)
	assert.Equal(t, time.UTC, item.CreatedAt.Location(), "CreatedAt must be UTC")
}

func TestAddToWatchlist_AtExactLimit_Fails(t *testing.T) {
	// Adding the 101st item must fail with ErrWatchlistFull even if the check is at boundary.
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "GOOG").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, "user-uuid-001", "GOOG").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, "user-uuid-001").Return(100, nil) // already at limit

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), "user-uuid-001", "GOOG", "US")

	require.Error(t, err)
	assert.ErrorIs(t, err, ErrWatchlistFull)
	repo.AssertNotCalled(t, "Add")
}

func TestRemoveFromWatchlist_Success(t *testing.T) {
	repo := new(MockWatchlistRepo)
	repo.On("Remove", mock.Anything, "user-uuid-001", "AAPL").Return(nil)

	uc := NewRemoveFromWatchlistUsecase(repo)
	err := uc.Execute(context.Background(), "user-uuid-001", "AAPL")

	require.NoError(t, err)
	repo.AssertExpectations(t)
}

func TestRemoveFromWatchlist_RepoError_Propagated(t *testing.T) {
	repo := new(MockWatchlistRepo)
	repo.On("Remove", mock.Anything, "user-uuid-001", "AAPL").Return(errors.New("db: deadlock"))

	uc := NewRemoveFromWatchlistUsecase(repo)
	err := uc.Execute(context.Background(), "user-uuid-001", "AAPL")

	require.Error(t, err)
	assert.Contains(t, err.Error(), "deadlock")
}

func TestRemoveFromWatchlist_EmptySymbol(t *testing.T) {
	repo := new(MockWatchlistRepo)
	uc := NewRemoveFromWatchlistUsecase(repo)
	err := uc.Execute(context.Background(), "user-uuid-001", "")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}
