// Package middleware provides HTTP middleware for the market-data service.
package middleware

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// IdempotencyMiddleware checks the Idempotency-Key header and caches responses
// for 72 hours in Redis to prevent duplicate state-changing operations.
type IdempotencyMiddleware struct {
	rdb *redis.Client
	ttl time.Duration
}

// NewIdempotencyMiddleware creates a new IdempotencyMiddleware with a 72-hour TTL.
func NewIdempotencyMiddleware(rdb *redis.Client) *IdempotencyMiddleware {
	return &IdempotencyMiddleware{
		rdb: rdb,
		ttl: 72 * time.Hour,
	}
}

// Handler wraps an HTTP handler with idempotency checking.
func (m *IdempotencyMiddleware) Handler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Only apply to state-changing methods.
		if r.Method != http.MethodPost && r.Method != http.MethodPut {
			next.ServeHTTP(w, r)
			return
		}

		key := r.Header.Get("Idempotency-Key")
		if key == "" {
			http.Error(w, `{"error":"Idempotency-Key header required"}`, http.StatusBadRequest)
			return
		}

		// Validate UUID format.
		if _, err := uuid.Parse(key); err != nil {
			http.Error(w, `{"error":"Idempotency-Key must be a valid UUID"}`, http.StatusBadRequest)
			return
		}

		ctx := r.Context()
		redisKey := "idempotency:" + key

		// Check if this key was already processed.
		exists, err := m.rdb.Exists(ctx, redisKey).Result()
		if err != nil {
			// Redis error: proceed without idempotency check.
			next.ServeHTTP(w, r)
			return
		}
		if exists > 0 {
			cached, err := m.rdb.Get(ctx, redisKey).Result()
			if err == nil {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusOK)
				_, _ = w.Write([]byte(cached))
				return
			}
		}

		// Store a placeholder to mark this key as in-progress.
		_ = m.rdb.Set(ctx, redisKey, `{"status":"processing"}`, m.ttl).Err()

		next.ServeHTTP(w, r)
	})
}

// contextKey is a private type for context keys to avoid collisions.
type contextKey string

// CorrelationIDKey is the context key for the correlation ID.
const CorrelationIDKey contextKey = "correlation_id"

// CorrelationIDMiddleware injects a correlation ID into the request context.
func CorrelationIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Correlation-ID")
		if id == "" {
			id = uuid.New().String()
		}
		ctx := context.WithValue(r.Context(), CorrelationIDKey, id)
		w.Header().Set("X-Correlation-ID", id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
