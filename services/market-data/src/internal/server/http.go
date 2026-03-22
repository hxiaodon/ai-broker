// Package server provides the transport layer for the market-data service.
package server

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
	httpSwagger "github.com/swaggo/http-swagger"

	// Import generated swagger docs so the init() func registers them.
	_ "github.com/hxiaodon/ai-broker/services/market-data/docs/swagger"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kline"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/search"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/watchlist"
)

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

	// Health, readiness, metrics, and API docs endpoints.
	mux.HandleFunc("GET /health", handleHealth)
	mux.HandleFunc("GET /ready", handleReady)
	mux.Handle("GET /metrics", promhttp.Handler())
	mux.Handle("/swagger/", httpSwagger.WrapHandler)

	// Register subdomain routes.
	quoteHandler.RegisterRoutes(mux)
	klineHandler.RegisterRoutes(mux)
	watchlistHandler.RegisterRoutes(mux)
	searchHandler.RegisterRoutes(mux)

	return &HTTPServer{
		srv: &http.Server{
			Addr:    string(addr),
			Handler: mux,
		},
		mux: mux,
	}
}

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
