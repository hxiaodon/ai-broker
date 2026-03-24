// Package server provides the transport layer for the market-data service.
package server

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	httpSwagger "github.com/swaggo/http-swagger"

	// Import generated swagger docs so the init() func registers them.
	_ "github.com/hxiaodon/ai-broker/services/market-data/docs/swagger"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kline"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/search"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/watchlist"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/correlation"
)

// CorrelationIDFromContext extracts correlation ID from context.
func CorrelationIDFromContext(ctx context.Context) string {
	return correlation.FromContext(ctx)
}

// HTTPServer wraps net/http.Server with route registration.
type HTTPServer struct {
	srv *http.Server
	mux *http.ServeMux
}

// NewHTTPServer creates a new HTTPServer with all subdomain handlers registered.
func NewHTTPServer(
	addr HTTPAddr,
	quoteHandler *quote.Handler,
	klineHandler *kline.Handler,
	watchlistHandler *watchlist.Handler,
	searchHandler *search.Handler,
) *HTTPServer {
	mux := http.NewServeMux()

	// Public endpoints — no auth required (security-compliance.md).
	mux.HandleFunc("GET /health", handleHealth)
	mux.HandleFunc("GET /ready", handleReady)
	mux.Handle("GET /metrics", promhttp.Handler())
	mux.Handle("/swagger/", httpSwagger.WrapHandler)

	// Register subdomain routes (protected by middleware chain below).
	quoteHandler.RegisterRoutes(mux)
	klineHandler.RegisterRoutes(mux)
	watchlistHandler.RegisterRoutes(mux)
	searchHandler.RegisterRoutes(mux)

	// Middleware chain (outermost executes first):
	//   correlationID → rateLimiter → jwtAuth → mux
	handler := correlationIDMiddleware(rateLimitMiddleware(jwtMiddleware(mux)))

	return &HTTPServer{
		srv: &http.Server{
			Addr:    string(addr),
			Handler: handler,
		},
		mux: mux,
	}
}

// ── Correlation ID ────────────────────────────────────────────────────────────

// correlationIDMiddleware extracts or generates X-Correlation-ID header.
func correlationIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		correlationID := r.Header.Get("X-Correlation-ID")
		if correlationID == "" {
			correlationID = generateCorrelationID()
		}
		ctx := correlation.WithID(r.Context(), correlationID)
		w.Header().Set("X-Correlation-ID", correlationID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func generateCorrelationID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:])
}

// ── Rate Limiter ─────────────────────────────────────────────────────────────

// ipBucket tracks token-bucket state per IP.
type ipBucket struct {
	tokens   float64
	lastSeen time.Time
}

var (
	rateMu  sync.Mutex
	buckets = make(map[string]*ipBucket)
)

const (
	rateLimit = 100.0 // tokens per second per IP
	burstSize = 100.0 // max burst
)

// rateLimitMiddleware implements a token-bucket rate limiter (100 req/s per IP).
// Public endpoints (/health, /ready, /metrics, /swagger/) are exempted.
func rateLimitMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Exempt public endpoints.
		if isPublicPath(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}

		ip := clientIP(r)
		now := time.Now()

		rateMu.Lock()
		b, ok := buckets[ip]
		if !ok {
			b = &ipBucket{tokens: burstSize, lastSeen: now}
			buckets[ip] = b
		}
		// Replenish tokens based on elapsed time.
		elapsed := now.Sub(b.lastSeen).Seconds()
		b.tokens = min(burstSize, b.tokens+elapsed*rateLimit)
		b.lastSeen = now

		allowed := b.tokens >= 1.0
		if allowed {
			b.tokens--
		}
		rateMu.Unlock()

		if !allowed {
			w.Header().Set("Content-Type", "application/json")
			w.Header().Set("Retry-After", "1")
			w.WriteHeader(http.StatusTooManyRequests)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"error":   "RATE_LIMIT_EXCEEDED",
				"message": "Too many requests. Limit: 100 req/s per IP.",
			})
			return
		}
		next.ServeHTTP(w, r)
	})
}

func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		return strings.SplitN(xff, ",", 2)[0]
	}
	// Strip port from RemoteAddr.
	addr := r.RemoteAddr
	if i := strings.LastIndex(addr, ":"); i != -1 {
		return addr[:i]
	}
	return addr
}

// ── JWT Auth ──────────────────────────────────────────────────────────────────

// jwtMiddleware validates Bearer tokens for protected endpoints.
// Public endpoints are passed through without validation.
// Phase-1 stub: validates structural JWT format (3 segments).
// Phase-5: replace with full RS256 signature + claims validation.
func jwtMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Exempt public endpoints.
		if isPublicPath(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}

		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			// No token — allow through as guest (quote handler marks delayed=true).
			next.ServeHTTP(w, r)
			return
		}

		// Validate "Bearer <token>" format.
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
			writeAuthError(w, "INVALID_TOKEN", "Authorization header must be: Bearer <token>")
			return
		}

		token := parts[1]
		// Phase-1: structural check — JWT must have 3 dot-separated segments.
		// Phase-5: TODO verify RS256 signature, exp, iss, aud claims.
		if !isStructurallyValidJWT(token) {
			writeAuthError(w, "INVALID_TOKEN", "Malformed JWT token")
			return
		}

		next.ServeHTTP(w, r)
	})
}

// isStructurallyValidJWT checks that the token has exactly 3 base64url segments.
func isStructurallyValidJWT(token string) bool {
	parts := strings.Split(token, ".")
	return len(parts) == 3 && parts[0] != "" && parts[1] != "" && parts[2] != ""
}

func writeAuthError(w http.ResponseWriter, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"error":   code,
		"message": message,
	})
}

// isPublicPath returns true for endpoints that require no authentication.
func isPublicPath(path string) bool {
	switch {
	case path == "/health", path == "/ready", path == "/metrics":
		return true
	case strings.HasPrefix(path, "/swagger/"):
		return true
	}
	return false
}

func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

// ── Lifecycle ─────────────────────────────────────────────────────────────────

// Start starts the HTTP server.
func (s *HTTPServer) Start() error {
	return s.srv.ListenAndServe()
}

// Stop gracefully shuts down the HTTP server.
func (s *HTTPServer) Stop(ctx context.Context) error {
	return s.srv.Shutdown(ctx)
}

func handleHealth(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	resp := map[string]string{
		"status": "ok",
		"time":   time.Now().UTC().Format(time.RFC3339),
	}
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		http.Error(w, `{"status":"error"}`, http.StatusInternalServerError)
	}
}

func handleReady(w http.ResponseWriter, _ *http.Request) {
	// FILL: domain engineer adds DB and Redis connectivity checks.
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	resp := map[string]string{
		"status": "ok",
		"time":   time.Now().UTC().Format(time.RFC3339),
	}
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		http.Error(w, `{"status":"error"}`, http.StatusInternalServerError)
	}
}
