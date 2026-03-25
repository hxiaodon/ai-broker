package app_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
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

func (m *MockQuoteRepo) GetBySymbolMarketTimestamp(ctx context.Context, symbol string, market domain.Market, timestamp int64) (*domain.Quote, error) {
	args := m.Called(ctx, symbol, market, timestamp)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Quote), args.Error(1)
}

func (m *MockQuoteRepo) FindPrevClose(ctx context.Context, symbol string, market domain.Market) (decimal.Decimal, error) {
	args := m.Called(ctx, symbol, market)
	return args.Get(0).(decimal.Decimal), args.Error(1)
}

// MockQuoteCacheRepo satisfies domain.QuoteCacheRepo interface.
type MockQuoteCacheRepo struct{ mock.Mock }

func (m *MockQuoteCacheRepo) Set(ctx context.Context, q *domain.Quote) error {
	args := m.Called(ctx, q)
	return args.Error(0)
}

func (m *MockQuoteCacheRepo) Get(ctx context.Context, market domain.Market, symbol string) (*domain.Quote, error) {
	args := m.Called(ctx, market, symbol)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Quote), args.Error(1)
}

func (m *MockQuoteCacheRepo) MGet(ctx context.Context, market domain.Market, symbols []string) ([]*domain.Quote, error) {
	args := m.Called(ctx, market, symbols)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*domain.Quote), args.Error(1)
}

func (m *MockQuoteCacheRepo) IsDedup(ctx context.Context, symbol string, market domain.Market, tsMicro int64) (bool, error) {
	args := m.Called(ctx, symbol, market, tsMicro)
	return args.Bool(0), args.Error(1)
}

// MockOutboxRepo satisfies app.OutboxRepo interface.
type MockOutboxRepo struct{ mock.Mock }

func (m *MockOutboxRepo) InsertEvent(ctx context.Context, topic string, payload []byte) error {
	args := m.Called(ctx, topic, payload)
	return args.Error(0)
}

func TestGetQuote_CacheMiss_DBHit(t *testing.T) {
	// Spec: get_quote.go §Execute — cache miss must fall back to DB and populate cache.
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	dbQuote := &domain.Quote{
		Symbol:        "AAPL",
		Market:        domain.MarketUS,
		LastUpdatedAt: time.Now().UTC(),
	}
	cacheRepo.On("Get", mock.Anything, domain.MarketUS, "AAPL").Return(nil, nil) // cache miss
	quoteRepo.On("FindBySymbol", mock.Anything, "AAPL").Return(dbQuote, nil)
	cacheRepo.On("Set", mock.Anything, dbQuote).Return(nil) // cache backfill

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	q, err := uc.Execute(context.Background(), domain.MarketUS, "AAPL", false)

	require.NoError(t, err)
	assert.Equal(t, "AAPL", q.Symbol)
	quoteRepo.AssertCalled(t, "FindBySymbol", mock.Anything, "AAPL")
	cacheRepo.AssertCalled(t, "Set", mock.Anything, dbQuote)
}

func TestGetQuote_CacheMiss_DBMiss_ReturnsError(t *testing.T) {
	// Unknown symbol: cache miss + DB miss must return an error (not nil, nil).
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	cacheRepo.On("Get", mock.Anything, domain.MarketUS, "UNKNOWN").Return(nil, nil)
	quoteRepo.On("FindBySymbol", mock.Anything, "UNKNOWN").Return(nil, nil)

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	_, err := uc.Execute(context.Background(), domain.MarketUS, "UNKNOWN", false)

	require.Error(t, err)
	assert.Contains(t, err.Error(), "not found")
}

func TestGetQuote_DBError_Propagated(t *testing.T) {
	// A DB error on fallback must be returned to the caller.
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	cacheRepo.On("Get", mock.Anything, domain.MarketUS, "AAPL").Return(nil, nil)
	quoteRepo.On("FindBySymbol", mock.Anything, "AAPL").Return(nil, errors.New("db: connection refused"))

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	_, err := uc.Execute(context.Background(), domain.MarketUS, "AAPL", false)

	require.Error(t, err)
	assert.Contains(t, err.Error(), "connection refused")
}

func TestGetQuote_StaleEvaluatedOnCacheHit(t *testing.T) {
	// Spec: GetQuote must evaluate staleness at read time, not just at write time.
	// A quote sitting in cache > 1s must be returned with IsStale = true.
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	staleQuote := &domain.Quote{
		Symbol:        "AAPL",
		Market:        domain.MarketUS,
		LastUpdatedAt: time.Now().UTC().Add(-5 * time.Second), // 5s old — well past 1s threshold
	}
	cacheRepo.On("Get", mock.Anything, domain.MarketUS, "AAPL").Return(staleQuote, nil)

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	q, err := uc.Execute(context.Background(), domain.MarketUS, "AAPL", false)

	require.NoError(t, err)
	assert.True(t, q.IsStale, "cache hit with old timestamp must be flagged as stale")
	assert.Positive(t, q.StaleSinceMs, "StaleSinceMs must be populated for stale quotes")
}

func TestGetQuote_HKMarket_UsesMarketDimension(t *testing.T) {
	// Spec: P3-01 fix — HK and US quotes use market-scoped cache keys.
	// Fetching HK:AAPL must call cache with MarketHK, not MarketUS.
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	hkQuote := &domain.Quote{
		Symbol:        "00700",
		Market:        domain.MarketHK,
		LastUpdatedAt: time.Now().UTC(),
	}
	cacheRepo.On("Get", mock.Anything, domain.MarketHK, "00700").Return(hkQuote, nil)

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	q, err := uc.Execute(context.Background(), domain.MarketHK, "00700", false)

	require.NoError(t, err)
	assert.Equal(t, domain.MarketHK, q.Market)
	cacheRepo.AssertCalled(t, "Get", mock.Anything, domain.MarketHK, "00700")
	quoteRepo.AssertNotCalled(t, "FindBySymbol")
}

func TestGetQuote_KafkaTopicIsMarketSpecific(t *testing.T) {
	// Spec: P4-06 — UpdateQuote must publish to market-specific Kafka topic.
	outboxRepo := &MockOutboxRepo{}
	quoteRepo := new(MockQuoteRepo)
	cacheRepo := new(MockQuoteCacheRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	quoteRepo.On("FindPrevClose", mock.Anything, mock.Anything, mock.Anything).Return(decimal.Zero, nil)
	cacheRepo.On("IsDedup", mock.Anything, mock.Anything, mock.Anything, mock.Anything).Return(false, nil)
	quoteRepo.On("Save", mock.Anything, mock.Anything).Return(nil)
	cacheRepo.On("Set", mock.Anything, mock.Anything).Return(nil)
	outboxRepo.On("InsertEvent", mock.Anything, mock.Anything, mock.Anything).Return(nil)

	uc := app.NewUpdateQuoteUsecase(
		quoteRepo, cacheRepo, outboxRepo,
		func(ctx context.Context, fn func(context.Context) error) error { return fn(ctx) },
		stale, nil, zap.NewNop(),
	)

	// US quote → should go to market-data.quotes.us
	usQuote := &domain.Quote{
		Symbol:        "AAPL",
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		LastUpdatedAt: time.Now().UTC(),
	}
	require.NoError(t, uc.Execute(context.Background(), usQuote))

	outboxRepo.AssertCalled(t, "InsertEvent", mock.Anything, "market-data.quotes.us", mock.Anything)
}

func TestUpdateQuote_HKGoesToHKTopic(t *testing.T) {
	// HK quote must publish to market-data.quotes.hk.
	outboxRepo := &MockOutboxRepo{}
	quoteRepo := new(MockQuoteRepo)
	cacheRepo := new(MockQuoteCacheRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	quoteRepo.On("FindPrevClose", mock.Anything, mock.Anything, mock.Anything).Return(decimal.Zero, nil)
	cacheRepo.On("IsDedup", mock.Anything, mock.Anything, mock.Anything, mock.Anything).Return(false, nil)
	quoteRepo.On("Save", mock.Anything, mock.Anything).Return(nil)
	cacheRepo.On("Set", mock.Anything, mock.Anything).Return(nil)
	outboxRepo.On("InsertEvent", mock.Anything, mock.Anything, mock.Anything).Return(nil)

	uc := app.NewUpdateQuoteUsecase(
		quoteRepo, cacheRepo, outboxRepo,
		func(ctx context.Context, fn func(context.Context) error) error { return fn(ctx) },
		stale, nil, zap.NewNop(),
	)

	hkQuote := &domain.Quote{
		Symbol:        "00700",
		Market:        domain.MarketHK,
		Price:         decimal.NewFromFloat(320.50),
		LastUpdatedAt: time.Now().UTC(),
	}
	require.NoError(t, uc.Execute(context.Background(), hkQuote))

	outboxRepo.AssertCalled(t, "InsertEvent", mock.Anything, "market-data.quotes.hk", mock.Anything)
}

func TestGetQuote_CacheHit(t *testing.T) {
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	expectedQuote := &domain.Quote{
		Symbol: "AAPL",
		Market: domain.MarketUS,
	}
	cacheRepo.On("Get", mock.Anything, domain.MarketUS, "AAPL").Return(expectedQuote, nil)

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	q, err := uc.Execute(context.Background(), domain.MarketUS, "AAPL", false)

	assert.NoError(t, err)
	assert.Equal(t, "AAPL", q.Symbol)
	cacheRepo.AssertExpectations(t)
	quoteRepo.AssertNotCalled(t, "FindBySymbol")
}

func TestGetQuote_EmptySymbol(t *testing.T) {
	cacheRepo := new(MockQuoteCacheRepo)
	quoteRepo := new(MockQuoteRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	uc := app.NewGetQuoteUsecase(cacheRepo, quoteRepo, stale, nil, zap.NewNop())
	_, err := uc.Execute(context.Background(), domain.MarketUS, "", false)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "symbol must not be empty")
}

func TestUpdateQuote_NilQuote(t *testing.T) {
	quoteRepo := new(MockQuoteRepo)
	cacheRepo := new(MockQuoteCacheRepo)
	outboxRepo := new(MockOutboxRepo)
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	uc := app.NewUpdateQuoteUsecase(quoteRepo, cacheRepo, outboxRepo, func(ctx context.Context, fn func(context.Context) error) error { return fn(ctx) }, stale, nil, zap.NewNop())
	err := uc.Execute(context.Background(), nil)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "quote must not be nil")
}
