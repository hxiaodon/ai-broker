// Package search contains integration tests for the search repository.
// Tests run against the docker-compose MySQL and Redis instances.
// Requires: `docker compose up -d` from services/market-data/ before running.
//
// Run with: go test ./internal/search/... -tags=integration -count=1 -v
package search_test

import (
	"context"
	"os"
	"testing"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/search"
)

// dsn returns the MySQL DSN from env or falls back to docker-compose default.
func mysqlDSN() string {
	if v := os.Getenv("TEST_MYSQL_DSN"); v != "" {
		return v
	}
	return "root:root@tcp(127.0.0.1:3306)/market_data_db?parseTime=true&loc=UTC&time_zone=%27%2B00%3A00%27&charset=utf8mb4"
}

func redisAddr() string {
	if v := os.Getenv("TEST_REDIS_ADDR"); v != "" {
		return v
	}
	return "127.0.0.1:6379"
}

// setupDB opens a GORM connection and cleans the stocks table for test isolation.
func setupDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(mysql.Open(mysqlDSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	require.NoError(t, err, "connect to MySQL")

	// Clean slate — delete all rows from stocks table before each test.
	require.NoError(t, db.Exec("DELETE FROM stocks").Error, "cleanup stocks")
	return db
}

// setupRedis opens a Redis client and clears the hot_search key.
func setupRedis(t *testing.T) *goredis.Client {
	t.Helper()
	rdb := goredis.NewClient(&goredis.Options{Addr: redisAddr()})
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	require.NoError(t, rdb.Ping(ctx).Err(), "ping Redis")
	require.NoError(t, rdb.Del(ctx, "hot_search:ranking").Err(), "cleanup hot_search key")
	t.Cleanup(func() { _ = rdb.Close() })
	return rdb
}

// insertStock is a helper to insert a test stock row directly via GORM.
func insertStock(t *testing.T, db *gorm.DB, symbol, name, nameCN, market, exchange string) {
	t.Helper()
	require.NoError(t, db.Exec(
		"INSERT INTO stocks (symbol, name, name_cn, market, exchange, sector, industry) VALUES (?,?,?,?,?,?,?)",
		symbol, name, nameCN, market, exchange, "Technology", "Software",
	).Error)
}

// ─── MySQLStockSearchRepo ─────────────────────────────────────────────────────

func TestMySQLStockSearchRepo_Search_BySymbolPrefix(t *testing.T) {
	// Spec: market-api-spec.md §GET /search — symbol prefix match via LIKE 'query%'
	// Note: MySQL FULLTEXT minimum word length is 4 chars by default; short queries
	// (< 4 chars) rely on the symbol LIKE fallback, not FULLTEXT.
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	insertStock(t, db, "AAPL", "Apple Inc.", "苹果公司", "US", "NASDAQ")
	insertStock(t, db, "AMAT", "Applied Materials Inc.", "应用材料公司", "US", "NASDAQ")
	insertStock(t, db, "GOOG", "Alphabet Inc.", "谷歌", "US", "NASDAQ")

	repo := search.NewMySQLStockSearchRepo(db)
	ctx := context.Background()

	// "AAPL" prefix-matches AAPL only (exact symbol prefix, 4 chars)
	results, err := repo.Search(ctx, "AAPL", "", 10)
	require.NoError(t, err)
	require.NotEmpty(t, results)

	symbols := make([]string, len(results))
	for i, r := range results {
		symbols[i] = r.Symbol
	}
	assert.Contains(t, symbols, "AAPL")
	assert.NotContains(t, symbols, "GOOG")

	// "AMAT" prefix-matches AMAT (distinct prefix)
	results2, err := repo.Search(ctx, "AMAT", "", 10)
	require.NoError(t, err)
	symbols2 := make([]string, len(results2))
	for i, r := range results2 {
		symbols2[i] = r.Symbol
	}
	assert.Contains(t, symbols2, "AMAT")
}

func TestMySQLStockSearchRepo_Search_ByName(t *testing.T) {
	// Spec: FULLTEXT on name column — "Apple" should find AAPL
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	insertStock(t, db, "AAPL", "Apple Inc.", "苹果公司", "US", "NASDAQ")
	insertStock(t, db, "MSFT", "Microsoft Corporation", "微软", "US", "NASDAQ")

	repo := search.NewMySQLStockSearchRepo(db)

	results, err := repo.Search(context.Background(), "Apple", "", 10)
	require.NoError(t, err)
	require.Len(t, results, 1)
	assert.Equal(t, "AAPL", results[0].Symbol)
}

func TestMySQLStockSearchRepo_Search_WithMarketFilter(t *testing.T) {
	// Spec: market filter restricts results to US or HK exchange
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	insertStock(t, db, "AAPL", "Apple Inc.", "苹果公司", "US", "NASDAQ")
	insertStock(t, db, "0700", "Tencent Holdings", "腾讯控股", "HK", "HKEX")

	repo := search.NewMySQLStockSearchRepo(db)

	usResults, err := repo.Search(context.Background(), "A", "US", 10)
	require.NoError(t, err)
	for _, r := range usResults {
		assert.Equal(t, "US", r.Market, "all results should be US market")
	}

	hkResults, err := repo.Search(context.Background(), "0", "HK", 10)
	require.NoError(t, err)
	for _, r := range hkResults {
		assert.Equal(t, "HK", r.Market, "all results should be HK market")
	}
}

func TestMySQLStockSearchRepo_Search_EmptyQueryReturnsError(t *testing.T) {
	// Spec: empty query must be rejected (not trigger full table scan)
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	repo := search.NewMySQLStockSearchRepo(db)

	_, err := repo.Search(context.Background(), "", "", 10)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "must not be empty")
}

func TestMySQLStockSearchRepo_Search_LimitRespected(t *testing.T) {
	// Spec: limit parameter caps result count
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	insertStock(t, db, "AAPL", "Apple Inc.", "苹果公司", "US", "NASDAQ")
	insertStock(t, db, "AMAT", "Applied Materials Inc.", "应用材料公司", "US", "NASDAQ")
	insertStock(t, db, "ABNB", "Airbnb Inc.", "爱彼迎", "US", "NASDAQ")
	insertStock(t, db, "ACMR", "ACM Research Inc.", "盛美半导体", "US", "NASDAQ")

	repo := search.NewMySQLStockSearchRepo(db)

	results, err := repo.Search(context.Background(), "A", "", 2)
	require.NoError(t, err)
	assert.LessOrEqual(t, len(results), 2, "result count must not exceed limit")
}

func TestMySQLStockSearchRepo_GetBySymbol_Found(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	insertStock(t, db, "TSLA", "Tesla Inc.", "特斯拉", "US", "NASDAQ")

	repo := search.NewMySQLStockSearchRepo(db)

	stock, err := repo.GetBySymbol(context.Background(), "TSLA")
	require.NoError(t, err)
	require.NotNil(t, stock)
	assert.Equal(t, "TSLA", stock.Symbol)
	assert.Equal(t, "Tesla Inc.", stock.Name)
	assert.Equal(t, "US", stock.Market)
}

func TestMySQLStockSearchRepo_GetBySymbol_NotFound(t *testing.T) {
	// Not-found must return (nil, nil) — not an error
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	db := setupDB(t)
	repo := search.NewMySQLStockSearchRepo(db)

	stock, err := repo.GetBySymbol(context.Background(), "NONEXISTENT")
	require.NoError(t, err)
	assert.Nil(t, stock)
}

// ─── RedisHotSearchRepo ───────────────────────────────────────────────────────

func TestRedisHotSearchRepo_IncrementAndGetTopN(t *testing.T) {
	// Spec: hot search rankings — ZINCRBY + ZREVRANGEWITHSCORES
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := search.NewRedisHotSearchRepo(rdb)
	ctx := context.Background()

	// Increment AAPL 3 times, TSLA 5 times, GOOG 1 time
	for i := 0; i < 3; i++ {
		require.NoError(t, repo.IncrementScore(ctx, "AAPL"))
	}
	for i := 0; i < 5; i++ {
		require.NoError(t, repo.IncrementScore(ctx, "TSLA"))
	}
	require.NoError(t, repo.IncrementScore(ctx, "GOOG"))

	items, err := repo.GetTopN(ctx, 3)
	require.NoError(t, err)
	require.Len(t, items, 3)

	// Scores should be descending: TSLA(5) > AAPL(3) > GOOG(1)
	assert.Equal(t, "TSLA", items[0].Symbol)
	assert.InDelta(t, 5.0, items[0].Score, 0.001)
	assert.Equal(t, "AAPL", items[1].Symbol)
	assert.InDelta(t, 3.0, items[1].Score, 0.001)
	assert.Equal(t, "GOOG", items[2].Symbol)
	assert.InDelta(t, 1.0, items[2].Score, 0.001)
}

func TestRedisHotSearchRepo_GetTopN_Empty(t *testing.T) {
	// Empty sorted set must return empty slice, not error
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := search.NewRedisHotSearchRepo(rdb)

	items, err := repo.GetTopN(context.Background(), 10)
	require.NoError(t, err)
	assert.Empty(t, items)
}

func TestRedisHotSearchRepo_GetTopN_LimitN(t *testing.T) {
	// GetTopN(2) should return at most 2 items even if more exist
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}
	rdb := setupRedis(t)
	repo := search.NewRedisHotSearchRepo(rdb)
	ctx := context.Background()

	for _, sym := range []string{"AAPL", "TSLA", "GOOG", "MSFT", "NVDA"} {
		require.NoError(t, repo.IncrementScore(ctx, sym))
	}

	items, err := repo.GetTopN(ctx, 2)
	require.NoError(t, err)
	assert.LessOrEqual(t, len(items), 2)
}
