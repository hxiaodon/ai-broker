package app_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// MockQuoteRepo satisfies domain.QuoteRepo interface.
type MockQuoteRepo struct{ mock.Mock }

func (m *MockQuoteRepo) Save(ctx context.Context, q *domain.Quote) error {
	args := m.Called(ctx, q)
	return args.Error(0)
}

func (m *MockQuoteRepo) FindBySymbol(ctx context.Context, symbol string) (*domain.Quote, error) {
	args := m.Called(ctx, symbol)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Quote), args.Error(1)
}

func (m *MockQuoteRepo) FindBySymbols(ctx context.Context, symbols []string) ([]*domain.Quote, error) {
	args := m.Called(ctx, symbols)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*domain.Quote), args.Error(1)
}

// MockQuoteCacheRepo satisfies domain.QuoteCacheRepo interface.
type MockQuoteCacheRepo struct{ mock.Mock }

func (m *MockQuoteCacheRepo) Set(ctx context.Context, q *domain.Quote) error {
	args := m.Called(ctx, q)
	return args.Error(0)
}

func (m *MockQuoteCacheRepo) Get(ctx context.Context, symbol string) (*domain.Quote, error) {
	args := m.Called(ctx, symbol)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Quote), args.Error(1)
}

func (m *MockQuoteCacheRepo) MGet(ctx context.Context, symbols []string) ([]*domain.Quote, error) {
	args := m.Called(ctx, symbols)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*domain.Quote), args.Error(1)
}

// MockOutboxRepo satisfies app.OutboxRepo interface.
type MockOutboxRepo struct{ mock.Mock }

func (m *MockOutboxRepo) InsertEvent(ctx context.Context, topic string, payload []byte) error {
	args := m.Called(ctx, topic, payload)
	return args.Error(0)
}

func TestGetQuote_CacheHit(t *testing.T) {
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	expectedQuote := &domain.Quote{
		Symbol: "AAPL",
		Market: domain.MarketUS,
	}
	cacheRepo.On("Get", mock.Anything, "AAPL").Return(expectedQuote, nil)

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale)
	q, err := uc.Execute(context.Background(), "AAPL")

	assert.NoError(t, err)
	assert.Equal(t, "AAPL", q.Symbol)
	cacheRepo.AssertExpectations(t)
	quoteRepo.AssertNotCalled(t, "FindBySymbol")
}

func TestGetQuote_EmptySymbol(t *testing.T) {
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale)
	_, err := uc.Execute(context.Background(), "")

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}

func TestUpdateQuote_NilQuote(t *testing.T) {
	quoteRepo := new(MockQuoteRepo)
	cacheRepo := new(MockQuoteCacheRepo)
	outboxRepo := new(MockOutboxRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	uc := app.NewUpdateQuoteUsecase(quoteRepo, cacheRepo, outboxRepo, func(ctx context.Context, fn func(context.Context) error) error { return fn(ctx) }, stale, zap.NewNop())
	err := uc.Execute(context.Background(), nil)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "quote must not be nil")
}
