// Package app_test contains unit tests for the quote application use cases.
// Uses mock implementations — no real DB or Redis required.
package app_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// ─── Mocks ────────────────────────────────────────────────────────────────────

type mockQuoteRepo struct {
	saved  []*domain.Quote
	findFn func(symbol string) (*domain.Quote, error)
}

func (m *mockQuoteRepo) Save(_ context.Context, q *domain.Quote) error {
	m.saved = append(m.saved, q)
	return nil
}
func (m *mockQuoteRepo) FindBySymbol(_ context.Context, symbol string) (*domain.Quote, error) {
	if m.findFn != nil {
		return m.findFn(symbol)
	}
	return nil, nil
}
func (m *mockQuoteRepo) FindBySymbols(_ context.Context, _ []string) ([]*domain.Quote, error) {
	return nil, nil
}

type mockCacheRepo struct {
	setErr error
	setCalled int
}

func (m *mockCacheRepo) Set(_ context.Context, _ *domain.Quote) error {
	m.setCalled++
	return m.setErr
}
func (m *mockCacheRepo) Get(_ context.Context, _ string) (*domain.Quote, error) { return nil, nil }
func (m *mockCacheRepo) MGet(_ context.Context, _ []string) ([]*domain.Quote, error) {
	return nil, nil
}

type mockOutboxRepo struct {
	events []struct {
		topic   string
		payload []byte
	}
	insertErr error
}

func (m *mockOutboxRepo) InsertEvent(_ context.Context, topic string, payload []byte) error {
	if m.insertErr != nil {
		return m.insertErr
	}
	m.events = append(m.events, struct {
		topic   string
		payload []byte
	}{topic, payload})
	return nil
}

// noopTxFunc executes fn directly without a real transaction (unit test isolation).
func noopTxFunc(ctx context.Context, fn func(ctx context.Context) error) error {
	return fn(ctx)
}

// errorTxFunc simulates a transaction that always fails.
func errorTxFunc(_ context.Context, _ func(ctx context.Context) error) error {
	return errors.New("tx: simulated DB failure")
}

func newTestQuote() *domain.Quote {
	return &domain.Quote{
		Symbol:    "AAPL",
		Market:    domain.MarketUS,
		Price:     decimal.NewFromFloat(150.25),
		PrevClose: decimal.NewFromFloat(149.00),
		Volume:    1000000,
		Bid:       decimal.NewFromFloat(150.24),
		Ask:       decimal.NewFromFloat(150.26),
	}
}

// ─── UpdateQuoteUsecase ───────────────────────────────────────────────────────

func TestUpdateQuoteUsecase_Execute_HappyPath(t *testing.T) {
	// Spec: market-data-system.md §3 — DB write + outbox insert + cache update
	quoteRepo := &mockQuoteRepo{}
	cacheRepo := &mockCacheRepo{}
	outboxRepo := &mockOutboxRepo{}
	stale := domain.NewStaleDetector(domain.DefaultStaleThreshold())

	uc := app.NewUpdateQuoteUsecase(quoteRepo, cacheRepo, outboxRepo, noopTxFunc, stale, zap.NewNop())
	q := newTestQuote()

	err := uc.Execute(context.Background(), q)
	require.NoError(t, err)

	// DB write occurred
	assert.Len(t, quoteRepo.saved, 1)
	assert.Equal(t, "AAPL", quoteRepo.saved[0].Symbol)

	// Outbox event inserted with correct topic
	assert.Len(t, outboxRepo.events, 1)
	assert.Equal(t, "brokerage.market-data.quote.updated", outboxRepo.events[0].topic)

	// Cache updated
	assert.Equal(t, 1, cacheRepo.setCalled)
}

func TestUpdateQuoteUsecase_Execute_NilQuoteReturnsError(t *testing.T) {
	uc := app.NewUpdateQuoteUsecase(
		&mockQuoteRepo{}, &mockCacheRepo{}, &mockOutboxRepo{},
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)
	err := uc.Execute(context.Background(), nil)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "must not be nil")
}

func TestUpdateQuoteUsecase_Execute_SetsLastUpdatedAtUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — timestamp must be UTC
	// LastUpdatedAt is set by the feed handler (exchange timestamp), not by the usecase.
	// This test verifies that the usecase preserves the feed timestamp.
	quoteRepo := &mockQuoteRepo{}
	uc := app.NewUpdateQuoteUsecase(
		quoteRepo, &mockCacheRepo{}, &mockOutboxRepo{},
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)
	q := newTestQuote()
	feedTimestamp := time.Now().UTC().Add(-500 * time.Millisecond) // Feed timestamp 500ms ago
	q.LastUpdatedAt = feedTimestamp

	require.NoError(t, uc.Execute(context.Background(), q))

	// Usecase must NOT overwrite the feed timestamp
	assert.Equal(t, feedTimestamp, quoteRepo.saved[0].LastUpdatedAt,
		"LastUpdatedAt must preserve feed timestamp, not overwrite with time.Now()")
	assert.Equal(t, time.UTC, quoteRepo.saved[0].LastUpdatedAt.Location(),
		"LastUpdatedAt must be UTC")
}

func TestUpdateQuoteUsecase_Execute_OutboxPayloadIsValidJSON(t *testing.T) {
	// Outbox event payload must deserialize to a QuoteUpdatedEvent with correct fields
	outboxRepo := &mockOutboxRepo{}
	uc := app.NewUpdateQuoteUsecase(
		&mockQuoteRepo{}, &mockCacheRepo{}, outboxRepo,
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)
	q := newTestQuote()
	require.NoError(t, uc.Execute(context.Background(), q))

	require.Len(t, outboxRepo.events, 1)
	var event domain.QuoteUpdatedEvent
	err := json.Unmarshal(outboxRepo.events[0].payload, &event)
	require.NoError(t, err, "outbox payload must be valid JSON")
	assert.Equal(t, "AAPL", event.Symbol)
	assert.Equal(t, domain.MarketUS, event.Market)
	assert.True(t, decimal.NewFromFloat(150.25).Equal(event.Price),
		"price in event: want 150.25 got %s", event.Price)
}

func TestUpdateQuoteUsecase_Execute_OutboxEventTimestampUTC(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — event timestamp must be UTC
	outboxRepo := &mockOutboxRepo{}
	uc := app.NewUpdateQuoteUsecase(
		&mockQuoteRepo{}, &mockCacheRepo{}, outboxRepo,
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)
	require.NoError(t, uc.Execute(context.Background(), newTestQuote()))

	var event domain.QuoteUpdatedEvent
	require.NoError(t, json.Unmarshal(outboxRepo.events[0].payload, &event))
	assert.Equal(t, time.UTC, event.Timestamp.Location(),
		"QuoteUpdatedEvent.Timestamp must be UTC")
}

func TestUpdateQuoteUsecase_Execute_TxFailure_NoOutboxEvent(t *testing.T) {
	// Spec: Outbox pattern — if the transaction fails, no event must be persisted
	outboxRepo := &mockOutboxRepo{}
	cacheRepo := &mockCacheRepo{}
	uc := app.NewUpdateQuoteUsecase(
		&mockQuoteRepo{}, cacheRepo, outboxRepo,
		errorTxFunc, // tx always fails
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)

	err := uc.Execute(context.Background(), newTestQuote())
	require.Error(t, err)
	assert.Contains(t, err.Error(), "tx")

	// No outbox event must have been inserted
	assert.Empty(t, outboxRepo.events, "no outbox event on tx failure")
	// Cache must not have been updated (tx failed before cache step)
	assert.Equal(t, 0, cacheRepo.setCalled, "cache not updated on tx failure")
}

func TestUpdateQuoteUsecase_Execute_OutboxInsertFailure_RollsBack(t *testing.T) {
	// If outbox insert fails, the use case must return an error
	outboxRepo := &mockOutboxRepo{insertErr: errors.New("db: deadlock")}
	uc := app.NewUpdateQuoteUsecase(
		&mockQuoteRepo{}, &mockCacheRepo{}, outboxRepo,
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)

	err := uc.Execute(context.Background(), newTestQuote())
	require.Error(t, err)
	assert.Contains(t, err.Error(), "tx")
}

func TestUpdateQuoteUsecase_Execute_CacheFailureIsNonFatal(t *testing.T) {
	// Spec: cache update is best-effort — a cache error must NOT fail the use case
	cacheRepo := &mockCacheRepo{setErr: errors.New("redis: connection refused")}
	uc := app.NewUpdateQuoteUsecase(
		&mockQuoteRepo{}, cacheRepo, &mockOutboxRepo{},
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)

	err := uc.Execute(context.Background(), newTestQuote())
	// Must succeed despite cache error
	require.NoError(t, err, "cache failure must not fail the use case")
}

func TestUpdateQuoteUsecase_Execute_EvaluatesStale(t *testing.T) {
	// Spec: market-data-system.md §3.3.5 — stale detection runs on every update
	// Feed handler sets LastUpdatedAt to exchange timestamp; usecase preserves it.
	// A quote with LastUpdatedAt = now is fresh (< 1s old), so IsStale must be false.
	quoteRepo := &mockQuoteRepo{}
	uc := app.NewUpdateQuoteUsecase(
		quoteRepo, &mockCacheRepo{}, &mockOutboxRepo{},
		noopTxFunc,
		domain.NewStaleDetector(domain.DefaultStaleThreshold()),
		zap.NewNop(),
	)
	q := newTestQuote()
	q.LastUpdatedAt = time.Now().UTC() // Simulate feed handler setting exchange timestamp

	require.NoError(t, uc.Execute(context.Background(), q))
	assert.False(t, quoteRepo.saved[0].IsStale, "freshly updated quote must not be stale")
}
