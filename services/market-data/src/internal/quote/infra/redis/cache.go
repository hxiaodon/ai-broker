// Package redis implements the quote cache using Redis.
package redis

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// QuoteCacheRepository implements domain.QuoteCacheRepo using Redis.
type QuoteCacheRepository struct {
	rdb *redis.Client
	ttl time.Duration
}

// NewQuoteCacheRepository creates a new QuoteCacheRepository.
func NewQuoteCacheRepository(rdb *redis.Client) *QuoteCacheRepository {
	return &QuoteCacheRepository{
		rdb: rdb,
		ttl: 30 * time.Second, // Quotes expire after 30s without update
	}
}

func quoteKey(market, symbol string) string {
	return fmt.Sprintf("quote:%s:%s", market, symbol)
}

// Set stores a quote in Redis.
func (r *QuoteCacheRepository) Set(ctx context.Context, q *domain.Quote) error {
	data, err := json.Marshal(q)
	if err != nil {
		return fmt.Errorf("quote cache set %s: marshal: %w", q.Symbol, err)
	}
	if err := r.rdb.Set(ctx, quoteKey(string(q.Market), q.Symbol), data, r.ttl).Err(); err != nil {
		return fmt.Errorf("quote cache set %s: redis: %w", q.Symbol, err)
	}
	return nil
}

// Get retrieves a quote from Redis by market and symbol.
func (r *QuoteCacheRepository) Get(ctx context.Context, market domain.Market, symbol string) (*domain.Quote, error) {
	data, err := r.rdb.Get(ctx, quoteKey(string(market), symbol)).Bytes()
	if err != nil {
		if err == redis.Nil {
			return nil, nil
		}
		return nil, fmt.Errorf("quote cache get %s: %w", symbol, err)
	}
	var q domain.Quote
	if err := json.Unmarshal(data, &q); err != nil {
		return nil, fmt.Errorf("quote cache get %s: unmarshal: %w", symbol, err)
	}
	return &q, nil
}

// IsDedup returns true if a quote with this (market, symbol, tsMicro) has already been processed.
// Uses Redis SET NX so the check-and-set is atomic; TTL = 5 minutes (well beyond any feed retry window).
// Returns (false, nil) when no connection issues occur and the key is new.
func (r *QuoteCacheRepository) IsDedup(ctx context.Context, symbol string, market domain.Market, tsMicro int64) (bool, error) {
	key := fmt.Sprintf("dedup:%s:%s:%d", string(market), symbol, tsMicro)
	set, err := r.rdb.SetNX(ctx, key, 1, 5*time.Minute).Result()
	if err != nil {
		return false, fmt.Errorf("quote dedup check %s: %w", symbol, err)
	}
	// SetNX returns true when the key was NEW (not a duplicate).
	// We invert: isDuplicate = !set.
	return !set, nil
}
func (r *QuoteCacheRepository) MGet(ctx context.Context, market domain.Market, symbols []string) ([]*domain.Quote, error) {
	if len(symbols) == 0 {
		return nil, nil
	}
	keys := make([]string, len(symbols))
	for i, s := range symbols {
		keys[i] = quoteKey(string(market), s)
	}

	vals, err := r.rdb.MGet(ctx, keys...).Result()
	if err != nil {
		return nil, fmt.Errorf("quote cache mget: %w", err)
	}

	quotes := make([]*domain.Quote, 0, len(vals))
	for i, v := range vals {
		if v == nil {
			continue
		}
		str, ok := v.(string)
		if !ok {
			continue
		}
		var q domain.Quote
		if err := json.Unmarshal([]byte(str), &q); err != nil {
			_ = fmt.Errorf("quote cache mget: unmarshal failed symbol=%s: %w", symbols[i], err)
			continue
		}
		quotes = append(quotes, &q)
	}
	return quotes, nil
}
