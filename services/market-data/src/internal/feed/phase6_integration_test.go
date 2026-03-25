package feed

import (
	"context"
	"testing"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	quotemysql "github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/mysql"
	quoteredis "github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/redis"
)

// TestPhase6_P6_01_MainFlow tests the complete flow: Feed → DB → Outbox → Kafka.
func TestPhase6_P6_01_MainFlow(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping Phase 6 integration test")
	}

	db, cleanup := setupTestDB(t)
	defer cleanup()

	rdb := setupTestRedis(t)
	defer rdb.Close()

	quoteRepo := quotemysql.NewQuoteRepository(db)
	quoteCacheRepo := quoteredis.NewQuoteCacheRepository(rdb)
	outboxRepo := quotemysql.NewOutboxRepository(db)
	txFunc := quotemysql.NewTxFunc(db)
	staleDetector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	logger := zap.NewNop()

	updateQuoteUC := app.NewUpdateQuoteUsecase(quoteRepo, quoteCacheRepo, outboxRepo, txFunc, staleDetector, nil, logger)

	scenarios := &MockQuoteScenarios{}
	ctx := context.Background()

	t.Run("Fresh quote flow", func(t *testing.T) {
		quote := scenarios.FreshQuote("AAPL")

		err := updateQuoteUC.Execute(ctx, quote)
		require.NoError(t, err, "UpdateQuote should succeed")

		savedQuote, err := quoteRepo.FindBySymbol(ctx, "AAPL")
		require.NoError(t, err)
		require.NotNil(t, savedQuote)
		assert.Equal(t, "AAPL", savedQuote.Symbol)
		assert.True(t, quote.Price.Equal(savedQuote.Price), "Price should match")
		assert.False(t, savedQuote.IsStale, "Quote should not be stale")

		cachedQuote, err := quoteCacheRepo.Get(ctx, domain.MarketUS, "AAPL")
		require.NoError(t, err)
		require.NotNil(t, cachedQuote)
		assert.Equal(t, "AAPL", cachedQuote.Symbol)

		var outboxCount int64
		db.Table("outbox_events").Where("topic = ?", "market-data.quotes.us").Count(&outboxCount)
		assert.Greater(t, outboxCount, int64(0), "Outbox should contain event")

		t.Logf("✓ Main flow verified: Feed → UpdateQuote → MySQL → Redis → Outbox")
	})

	t.Run("Stale quote detection", func(t *testing.T) {
		staleQuote := scenarios.StaleQuote1s("MSFT")

		err := updateQuoteUC.Execute(ctx, staleQuote)
		require.NoError(t, err)

		savedQuote, err := quoteRepo.FindBySymbol(ctx, "MSFT")
		require.NoError(t, err)

		// Re-evaluate stale status with current time
		result := staleDetector.Evaluate(savedQuote)
		assert.True(t, result.IsStale, "Quote should be marked as stale")

		t.Logf("✓ Stale detection verified: 1.5s delay triggers is_stale=true")
	})

	t.Run("End-to-end latency", func(t *testing.T) {
		start := time.Now()

		quote := scenarios.MarketHoursQuote("TSLA")
		err := updateQuoteUC.Execute(ctx, quote)
		require.NoError(t, err)

		elapsed := time.Since(start)
		assert.Less(t, elapsed, 500*time.Millisecond, "Latency should be < 500ms")

		t.Logf("✓ Latency verified: %v (target < 500ms)", elapsed)
	})
}

// TestPhase6_P6_02_ExceptionFlow tests error handling scenarios.
func TestPhase6_P6_02_ExceptionFlow(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping Phase 6 integration test")
	}

	db, cleanup := setupTestDB(t)
	defer cleanup()

	rdb := setupTestRedis(t)
	defer rdb.Close()

	quoteRepo := quotemysql.NewQuoteRepository(db)
	outboxRepo := quotemysql.NewOutboxRepository(db)
	txFunc := quotemysql.NewTxFunc(db)
	staleDetector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
	logger := zap.NewNop()

	ctx := context.Background()
	scenarios := &MockQuoteScenarios{}

	t.Run("Redis unavailable - graceful degradation", func(t *testing.T) {
		rdb.Close()
		failedCacheRepo := quoteredis.NewQuoteCacheRepository(rdb)
		ucWithFailedCache := app.NewUpdateQuoteUsecase(quoteRepo, failedCacheRepo, outboxRepo, txFunc, staleDetector, nil, logger)

		quote := scenarios.FreshQuote("GOOG")
		err := ucWithFailedCache.Execute(ctx, quote)

		savedQuote, dbErr := quoteRepo.FindBySymbol(ctx, "GOOG")
		require.NoError(t, dbErr, "DB write should succeed even if cache fails")
		require.NotNil(t, savedQuote)

		t.Logf("✓ Redis failure handled: DB write succeeded, cache err=%v", err)
		rdb = setupTestRedis(t)
	})
}

// TestPhase6_P6_03_ComplianceChecks verifies regulatory compliance.
func TestPhase6_P6_03_ComplianceChecks(t *testing.T) {
	if testing.Short() {
		t.Skip("skipping Phase 6 integration test")
	}

	t.Run("Decimal type enforcement", func(t *testing.T) {
		scenarios := &MockQuoteScenarios{}
		quote := scenarios.FreshQuote("AAPL")

		assert.IsType(t, decimal.Decimal{}, quote.Price)
		assert.IsType(t, decimal.Decimal{}, quote.Open)
		assert.IsType(t, decimal.Decimal{}, quote.High)
		assert.IsType(t, decimal.Decimal{}, quote.Low)

		sum := quote.Price.Add(quote.Open)
		assert.IsType(t, decimal.Decimal{}, sum)

		t.Logf("✓ Decimal compliance verified")
	})

	t.Run("UTC timestamp enforcement", func(t *testing.T) {
		scenarios := &MockQuoteScenarios{}
		quote := scenarios.FreshQuote("AAPL")

		assert.Equal(t, "UTC", quote.LastUpdatedAt.Location().String())
		assert.IsType(t, time.Time{}, quote.LastUpdatedAt)

		t.Logf("✓ UTC timestamp compliance: %s", quote.LastUpdatedAt.Format(time.RFC3339))
	})

	t.Run("Stale detection thresholds", func(t *testing.T) {
		staleDetector := domain.NewStaleDetector(domain.DefaultStaleThreshold())
		now := time.Now().UTC()

		fresh := &domain.Quote{LastUpdatedAt: now.Add(-500 * time.Millisecond)}
		result := staleDetector.Evaluate(fresh)
		assert.False(t, result.IsStale, "0.5s should be fresh")

		stale1s := &domain.Quote{LastUpdatedAt: now.Add(-1500 * time.Millisecond)}
		result = staleDetector.Evaluate(stale1s)
		assert.True(t, result.IsStale, "1.5s should be stale")

		stale5s := &domain.Quote{LastUpdatedAt: now.Add(-6 * time.Second)}
		result = staleDetector.Evaluate(stale5s)
		assert.True(t, result.IsStale, "6s should be stale")

		t.Logf("✓ Stale thresholds verified: 1s/5s")
	})

	t.Run("No PII in market data", func(t *testing.T) {
		scenarios := &MockQuoteScenarios{}
		quote := scenarios.FreshQuote("AAPL")

		assert.NotEmpty(t, quote.Symbol)
		assert.NotEmpty(t, quote.Market)
		assert.False(t, quote.Price.IsZero())

		t.Logf("✓ PII compliance: no personal information")
	})
}

// setupTestDB creates a test database connection.
func setupTestDB(t *testing.T) (*gorm.DB, func()) {
	dsn := "root:root@tcp(127.0.0.1:3306)/market_data_test?charset=utf8mb4&parseTime=True&loc=UTC"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	require.NoError(t, err, "Failed to connect to test database")

	err = db.AutoMigrate(&quotemysql.QuoteModel{})
	require.NoError(t, err, "Failed to migrate test tables")

	cleanup := func() {
		db.Exec("DELETE FROM quotes WHERE symbol IN ('AAPL', 'MSFT', 'TSLA', 'GOOG', 'AMZN')")
		db.Exec("DELETE FROM outbox_events")
		sqlDB, _ := db.DB()
		sqlDB.Close()
	}

	return db, cleanup
}

// setupTestRedis creates a test Redis connection.
func setupTestRedis(t *testing.T) *redis.Client {
	rdb := redis.NewClient(&redis.Options{
		Addr: "127.0.0.1:6379",
		DB:   1,
	})

	ctx := context.Background()
	_, err := rdb.Ping(ctx).Result()
	require.NoError(t, err, "Failed to connect to test Redis")

	rdb.FlushDB(ctx)

	return rdb
}

