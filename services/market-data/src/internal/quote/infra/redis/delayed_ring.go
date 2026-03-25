// Package redis implements the delayed quote ring buffer using Redis Sorted Sets.
package redis

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

const (
	// delayedTTLWindow is how long we retain snapshots in the sorted set.
	// 30 minutes covers the required 15-minute delay window with ample margin.
	delayedTTLWindow = 30 * time.Minute

	// delayedQuoteDelay is the minimum age a snapshot must have before being served to guest users.
	// Spec: CLAUDE.md §10 — "Delayed 15 min"
	delayedQuoteDelay = 15 * time.Minute
)

// DelayedRingBuffer implements domain.QuoteDelayedRepo using a Redis Sorted Set per symbol.
// Key schema: "delayed:{market}:{symbol}"
// Score:      Unix milliseconds of the quote's exchange timestamp (LastUpdatedAt)
// Member:     JSON-serialised domain.Quote
//
// On every Push the buffer trims entries older than delayedTTLWindow so memory is bounded.
type DelayedRingBuffer struct {
	rdb *redis.Client
}

// NewDelayedRingBuffer creates a new DelayedRingBuffer.
func NewDelayedRingBuffer(rdb *redis.Client) *DelayedRingBuffer {
	return &DelayedRingBuffer{rdb: rdb}
}

func delayedKey(market, symbol string) string {
	return fmt.Sprintf("delayed:%s:%s", market, symbol)
}

// Push appends the current quote snapshot to the ring buffer.
// Old entries (> 30min) are pruned atomically via ZREMRANGEBYSCORE.
func (r *DelayedRingBuffer) Push(ctx context.Context, q *domain.Quote) error {
	data, err := json.Marshal(q)
	if err != nil {
		return fmt.Errorf("delayed push %s: marshal: %w", q.Symbol, err)
	}

	key := delayedKey(string(q.Market), q.Symbol)
	scoreMsec := float64(q.LastUpdatedAt.UnixMilli())

	pipe := r.rdb.Pipeline()
	pipe.ZAdd(ctx, key, redis.Z{Score: scoreMsec, Member: string(data)})

	// Trim entries older than delayedTTLWindow.
	cutoffMsec := float64(time.Now().Add(-delayedTTLWindow).UnixMilli())
	pipe.ZRemRangeByScore(ctx, key, "-inf", fmt.Sprintf("%f", cutoffMsec))

	// Expire the whole key so it is cleaned up if the symbol stops trading.
	pipe.Expire(ctx, key, delayedTTLWindow+5*time.Minute)

	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("delayed push %s: redis pipeline: %w", q.Symbol, err)
	}
	return nil
}

// GetDelayed returns the most recent snapshot that is at least delayedQuoteDelay old.
// Returns nil (no error) when no suitable snapshot exists.
func (r *DelayedRingBuffer) GetDelayed(ctx context.Context, market domain.Market, symbol string) (*domain.Quote, error) {
	key := delayedKey(string(market), symbol)

	// Find the highest-scored entry whose score ≤ (now - 15min).
	maxScore := fmt.Sprintf("%d", time.Now().Add(-delayedQuoteDelay).UnixMilli())

	results, err := r.rdb.ZRevRangeByScoreWithScores(ctx, key, &redis.ZRangeBy{
		Min:    "-inf",
		Max:    maxScore,
		Offset: 0,
		Count:  1,
	}).Result()
	if err != nil {
		return nil, fmt.Errorf("delayed get %s: %w", symbol, err)
	}
	if len(results) == 0 {
		// No delayed snapshot available yet (symbol just started, or buffer empty).
		return nil, nil
	}

	var q domain.Quote
	if err := json.Unmarshal([]byte(results[0].Member.(string)), &q); err != nil {
		return nil, fmt.Errorf("delayed get %s: unmarshal: %w", symbol, err)
	}
	return &q, nil
}
