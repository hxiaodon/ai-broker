package watchlist

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// ─── Mocks ───────────────────────────────────────────────────────────────────

type MockWatchlistRepo struct{ mock.Mock }

func (m *MockWatchlistRepo) FindByUserID(ctx context.Context, userID int64) ([]*WatchlistItem, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*WatchlistItem), args.Error(1)
}

func (m *MockWatchlistRepo) CountByUserID(ctx context.Context, userID int64) (int, error) {
	args := m.Called(ctx, userID)
	return args.Int(0), args.Error(1)
}

func (m *MockWatchlistRepo) ExistsByUserAndSymbol(ctx context.Context, userID int64, symbol string) (bool, error) {
	args := m.Called(ctx, userID, symbol)
	return args.Bool(0), args.Error(1)
}

func (m *MockWatchlistRepo) Add(ctx context.Context, item *WatchlistItem) error {
	args := m.Called(ctx, item)
	return args.Error(0)
}

func (m *MockWatchlistRepo) Remove(ctx context.Context, userID int64, symbol string) error {
	args := m.Called(ctx, userID, symbol)
	return args.Error(0)
}

func (m *MockWatchlistRepo) Reorder(ctx context.Context, userID int64, symbolOrder []string) error {
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
	err := uc.Execute(context.Background(), 1, "", "US")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}

func TestAddToWatchlist_SymbolNotFound(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "INVALID").Return(false, nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), 1, "INVALID", "US")
	assert.Error(t, err)
	assert.ErrorIs(t, err, ErrSymbolNotFound)
}

func TestAddToWatchlist_Idempotent(t *testing.T) {
	// Adding an already-watched symbol must return nil, not an error.
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "AAPL").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, int64(1), "AAPL").Return(true, nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), 1, "AAPL", "US")
	assert.NoError(t, err)
	repo.AssertNotCalled(t, "Add")
}

func TestAddToWatchlist_LimitExceeded(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "TSLA").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, int64(1), "TSLA").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, int64(1)).Return(100, nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), 1, "TSLA", "US")
	assert.Error(t, err)
	assert.ErrorIs(t, err, ErrWatchlistFull)
}

func TestAddToWatchlist_Success(t *testing.T) {
	repo := new(MockWatchlistRepo)
	validator := new(MockStockValidator)
	validator.On("ExistsBySymbol", mock.Anything, "AAPL").Return(true, nil)
	repo.On("ExistsByUserAndSymbol", mock.Anything, int64(1), "AAPL").Return(false, nil)
	repo.On("CountByUserID", mock.Anything, int64(1)).Return(5, nil)
	repo.On("Add", mock.Anything, mock.AnythingOfType("*watchlist.WatchlistItem")).Return(nil)

	uc := NewAddToWatchlistUsecase(repo, validator)
	err := uc.Execute(context.Background(), 1, "AAPL", "US")
	assert.NoError(t, err)
	repo.AssertExpectations(t)
}

// ─── RemoveFromWatchlist tests ───────────────────────────────────────────────

func TestRemoveFromWatchlist_EmptySymbol(t *testing.T) {
	repo := new(MockWatchlistRepo)
	uc := NewRemoveFromWatchlistUsecase(repo)
	err := uc.Execute(context.Background(), 1, "")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}
