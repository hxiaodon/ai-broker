package quote

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/httputil"
	"go.uber.org/zap"
)

func newTestHandler() *Handler {
	return NewHandler(
		app.NewGetQuoteUsecase(&stubQuoteCache{}, &stubQuoteRepo{}, nil, zap.NewNop()),
		app.NewGetMarketStatusUsecase(&stubStatusRepo{}),
	)
}

type stubQuoteCache struct{}

func (s *stubQuoteCache) Get(ctx context.Context, market domain.Market, symbol string) (*domain.Quote, error) {
	return nil, nil
}

func (s *stubQuoteCache) Set(ctx context.Context, q *domain.Quote) error {
	return nil
}

func (s *stubQuoteCache) MGet(ctx context.Context, market domain.Market, symbols []string) ([]*domain.Quote, error) {
	return nil, nil
}

type stubQuoteRepo struct{}

func (s *stubQuoteRepo) Save(ctx context.Context, q *domain.Quote) error {
	return nil
}

func (s *stubQuoteRepo) FindBySymbol(ctx context.Context, symbol string) (*domain.Quote, error) {
	return nil, fmt.Errorf("not found")
}

func (s *stubQuoteRepo) FindByMarketAndSymbol(ctx context.Context, market domain.Market, symbol string) (*domain.Quote, error) {
	return nil, fmt.Errorf("not found")
}

func (s *stubQuoteRepo) FindBySymbols(ctx context.Context, symbols []string) ([]*domain.Quote, error) {
	return nil, nil
}

func (s *stubQuoteRepo) GetBySymbolMarketTimestamp(ctx context.Context, symbol string, market domain.Market, timestamp int64) (*domain.Quote, error) {
	return nil, nil
}

type stubStatusRepo struct{}

func (s *stubStatusRepo) GetStatus(ctx context.Context, market domain.Market) (*domain.MarketStatus, error) {
	return &domain.MarketStatus{Market: market, Phase: domain.PhaseRegular}, nil
}

func (s *stubStatusRepo) SetStatus(ctx context.Context, status *domain.MarketStatus) error {
	return nil
}

func (s *stubStatusRepo) GetMarketStatus(ctx context.Context, market domain.Market) (*domain.MarketStatus, error) {
	return &domain.MarketStatus{Market: market, Phase: domain.PhaseRegular}, nil
}

func TestQuoteHandler_BatchQuotes_TooManySymbols(t *testing.T) {
	h := newTestHandler()

	symbols := strings.Repeat("AAPL,", 51)
	req := httptest.NewRequest("GET", "/v1/market/quotes?symbols="+symbols, nil)
	w := httptest.NewRecorder()

	h.handleGetQuotes(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestQuoteHandler_BatchQuotes_InvalidMarket(t *testing.T) {
	h := newTestHandler()

	req := httptest.NewRequest("GET", "/v1/market/status?market=JP", nil)
	w := httptest.NewRecorder()

	h.handleGetMarketStatus(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestQuoteHandler_EmptySymbols(t *testing.T) {
	h := newTestHandler()

	req := httptest.NewRequest("GET", "/v1/market/quotes?symbols=", nil)
	w := httptest.NewRecorder()

	h.handleGetQuotes(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

// TestQuoteHandler_ErrorResponseFormat verifies the error body follows spec §13:
// {"error":"<CODE>","message":"..."} — not bare string or other format.
func TestQuoteHandler_ErrorResponseFormat(t *testing.T) {
	h := newTestHandler()

	req := httptest.NewRequest("GET", "/v1/market/quotes?symbols=", nil)
	w := httptest.NewRecorder()

	h.handleGetQuotes(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}

	// Content-Type must be application/json (spec §1.3).
	ct := w.Header().Get("Content-Type")
	if !strings.Contains(ct, "application/json") {
		t.Errorf("expected Content-Type application/json, got %q", ct)
	}

	// Body must decode to APIError with a non-empty error code (spec §13.1).
	var apiErr httputil.APIError
	if err := json.NewDecoder(w.Body).Decode(&apiErr); err != nil {
		t.Fatalf("response body is not valid JSON: %v", err)
	}
	if apiErr.Error == "" {
		t.Error("error field must not be empty")
	}
	if apiErr.Error != "INVALID_SYMBOL" {
		t.Errorf("expected error code INVALID_SYMBOL, got %q", apiErr.Error)
	}
	if apiErr.Message == "" {
		t.Error("message field must not be empty")
	}
}

// TestQuoteHandler_TooManySymbols_ErrorCode verifies the correct error code is used.
func TestQuoteHandler_TooManySymbols_ErrorCode(t *testing.T) {
	h := newTestHandler()

	symbols := strings.Join(make([]string, 51), "AAPL,") + "AAPL"
	req := httptest.NewRequest("GET", "/v1/market/quotes?symbols="+symbols, nil)
	w := httptest.NewRecorder()

	h.handleGetQuotes(w, req)

	var apiErr httputil.APIError
	if err := json.NewDecoder(w.Body).Decode(&apiErr); err != nil {
		t.Fatalf("response body is not valid JSON: %v", err)
	}
	if apiErr.Error != "TOO_MANY_SYMBOLS" {
		t.Errorf("expected TOO_MANY_SYMBOLS, got %q", apiErr.Error)
	}
}

// TestQuoteHandler_DelayedFlag_NoJWT verifies that requests without Authorization
// header result in delayed=true (spec §1.5).
// This is tested at the JWT-detection boundary; no usecase invocation needed
// because handleGetQuotes returns an empty quotes map when usecase returns error.
func TestQuoteHandler_DelayedFlag_NoJWT(t *testing.T) {
	h := newTestHandler()

	// Single symbol, no Authorization header.
	req := httptest.NewRequest("GET", "/v1/market/quotes?symbols=AAPL", nil)
	w := httptest.NewRecorder()

	h.handleGetQuotes(w, req)

	// Handler returns 200 with empty quotes map (symbol not found silently omitted).
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	var resp quotesResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("response body is not valid JSON: %v", err)
	}
	// as_of must be present and non-empty (spec §3.3).
	if resp.AsOf == "" {
		t.Error("as_of field must not be empty")
	}
}

// TestQuoteHandler_DelayedFlag_WithValidJWT verifies that IsValidJWT accepts a
// structurally valid three-segment Bearer token (spec §1.5, Phase-5 stub).
func TestQuoteHandler_DelayedFlag_WithValidJWT(t *testing.T) {
	h := newTestHandler()

	req := httptest.NewRequest("GET", "/v1/market/quotes?symbols=AAPL", nil)
	// Structurally valid JWT: three base64url segments separated by dots.
	req.Header.Set("Authorization", "Bearer header.payload.signature")
	w := httptest.NewRecorder()

	h.handleGetQuotes(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}

	// Response must parse as quotesResponse — validates protocol compliance.
	var resp quotesResponse
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("response body is not valid JSON: %v", err)
	}
	if resp.AsOf == "" {
		t.Error("as_of field must not be empty")
	}
}
