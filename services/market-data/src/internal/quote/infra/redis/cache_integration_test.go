// Package redis_test contains integration tests for the quote Redis cache repository.
// Requires: `docker compose up -d` from services/market-data/ before running.
//
// Run with: go test ./internal/quote/infra/redis/... -count=1 -v
// Skip in CI short mode: go test ./... -short
package redis_test

import (
	"context"
	"os"
	"testing"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	quoteredis "github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/redis"
)

func redisAddr() string {
	if v := os.Getenv("TEST_REDIS_ADDR"); v != "" {
		return v
	}
	return "127.0.0.1:6379"
}

func setupRedis(t *testing.T) *goredis.Client {
	t.Helper()
	rdb := goredis.NewClient(&goredis.Options{Addr: redisAddr()})
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	require.NoError(t, rdb.Ping(ctx).Err(), "ping Redis")
	t.Cleanup(func() { _ = rdb.Close() })
	return rdb
}

func newTestQuote(symbol string) *domain.Quote {
	return &domain.Quote{
		Symbol:        symbol,
		Market:        domain.MarketUS,
		Price:         decimal.NewFromFloat(150.25),
		Open:          decimal.NewFromFloat(148.00),
		High:          decimal.NewFromFloat(152.00),
		Low:           decimal.NewFromFloat(147.50),
		PrevClose:     decimal.NewFromFloat(149.00),
		Volume:        1000000,
		Bid:           decimal.NewFromFloat(150.24),
		Ask:           decimal.NewFromFloat(150.26),
		IsStale:       false,
		LastUpdatedAt: time.Now().UTC().Truncate(time.Millisecond),
	}
}

// ─── Set / Get ────────────────────────────────────────────────────────────────

func TestQuoteCacheRepository_SetAndGet(t *testing.T) {
	// Spec: quote cache stores and retrieves all fields; no data loss
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()

	q := newTestQuote("AAPL")
	t.Cleanup(func() { _ = rdb.Del(ctx, "quote:AAPL").Err() })

	require.NoError(t, repo.Set(ctx, q))

	got, err := repo.Get(ctx, domain.MarketUS, "AAPL")
	require.NoError(t, err)
	require.NotNil(t, got)

	assert.Equal(t, q.Symbol, got.Symbol)
	assert.Equal(t, q.Market, got.Market)
	assert.True(t, q.Price.Equal(got.Price), "Price: want %s got %s", q.Price, got.Price)
	assert.True(t, q.PrevClose.Equal(got.PrevClose), "PrevClose: want %s got %s", q.PrevClose, got.PrevClose)
	assert.Equal(t, q.Volume, got.Volume)
	assert.Equal(t, q.IsStale, got.IsStale)
}

func TestQuoteCacheRepository_Get_Miss(t *testing.T) {
	// Cache miss must return (nil, nil) — not an error
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()

	_ = rdb.Del(ctx, "quote:NONEXISTENT")

	got, err := repo.Get(ctx, domain.MarketUS, "NONEXISTENT")
	require.NoError(t, err)
	assert.Nil(t, got, "cache miss should return nil quote")
}

func TestQuoteCacheRepository_Set_OverwritesExisting(t *testing.T) {
	// Set on existing key must overwrite with latest value
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()
	t.Cleanup(func() { _ = rdb.Del(ctx, "quote:MSFT").Err() })

	q1 := newTestQuote("MSFT")
	q1.Price = decimal.NewFromFloat(400.00)
	require.NoError(t, repo.Set(ctx, q1))

	q2 := newTestQuote("MSFT")
	q2.Price = decimal.NewFromFloat(405.50)
	require.NoError(t, repo.Set(ctx, q2))

	got, err := repo.Get(ctx, domain.MarketUS, "MSFT")
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.True(t, decimal.NewFromFloat(405.50).Equal(got.Price), "should return latest price")
}

func TestQuoteCacheRepository_Set_DecimalPrecisionPreserved(t *testing.T) {
	// Spec: financial-coding-standards Rule 1 — decimal precision must survive JSON round-trip
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()
	t.Cleanup(func() { _ = rdb.Del(ctx, "quote:PREC").Err() })

	q := newTestQuote("PREC")
	q.Price = decimal.RequireFromString("123.4567") // 4 decimal places (US stock price precision)
	require.NoError(t, repo.Set(ctx, q))

	got, err := repo.Get(ctx, domain.MarketUS, "PREC")
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.True(t, q.Price.Equal(got.Price),
		"decimal precision must be preserved through cache round-trip: want %s got %s",
		q.Price, got.Price)
}

// ─── MGet ─────────────────────────────────────────────────────────────────────

func TestQuoteCacheRepository_MGet_AllPresent(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()

	symbols := []string{"MGET1", "MGET2", "MGET3"}
	for _, sym := range symbols {
		require.NoError(t, repo.Set(ctx, newTestQuote(sym)))
	}
	t.Cleanup(func() {
		for _, sym := range symbols {
			_ = rdb.Del(ctx, "quote:"+sym).Err()
		}
	})

	results, err := repo.MGet(ctx, domain.MarketUS, symbols)
	require.NoError(t, err)
	assert.Len(t, results, 3)

	gotSymbols := make(map[string]struct{})
	for _, r := range results {
		gotSymbols[r.Symbol] = struct{}{}
	}
	for _, sym := range symbols {
		assert.Contains(t, gotSymbols, sym)
	}
}

func TestQuoteCacheRepository_MGet_PartialHit(t *testing.T) {
	// MGet with some misses: must return only the ones that exist
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()

	require.NoError(t, repo.Set(ctx, newTestQuote("PARTIAL1")))
	_ = rdb.Del(ctx, "quote:MISSING")
	t.Cleanup(func() { _ = rdb.Del(ctx, "quote:PARTIAL1").Err() })

	results, err := repo.MGet(ctx, domain.MarketUS, []string{"PARTIAL1", "MISSING"})
	require.NoError(t, err)
	assert.Len(t, results, 1)
	assert.Equal(t, "PARTIAL1", results[0].Symbol)
}

func TestQuoteCacheRepository_MGet_Empty(t *testing.T) {
	// MGet on empty slice must return (nil, nil) — not a Redis error
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)

	results, err := repo.MGet(context.Background(), domain.MarketUS, []string{})
	require.NoError(t, err)
	assert.Empty(t, results)
}

func TestQuoteCacheRepository_UTCTimestampPreserved(t *testing.T) {
	// Spec: financial-coding-standards Rule 2 — timestamps must remain UTC after cache round-trip
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := quoteredis.NewQuoteCacheRepository(rdb)
	ctx := context.Background()
	t.Cleanup(func() { _ = rdb.Del(ctx, "quote:UTCTEST").Err() })

	q := newTestQuote("UTCTEST")
	require.NoError(t, repo.Set(ctx, q))

	got, err := repo.Get(ctx, domain.MarketUS, "UTCTEST")
	require.NoError(t, err)
	require.NotNil(t, got)

	assert.Equal(t, time.UTC, got.LastUpdatedAt.Location(),
		"LastUpdatedAt must remain UTC after cache round-trip")
}
