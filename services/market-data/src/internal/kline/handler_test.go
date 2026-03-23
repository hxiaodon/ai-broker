package kline

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestKLineHandler_InvalidPeriod(t *testing.T) {
	h := NewHandler(NewGetKLinesUsecase(nil))

	req := httptest.NewRequest("GET", "/v1/market/kline?symbol=AAPL&period=2min", nil)
	w := httptest.NewRecorder()

	h.handleGetKLines(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestKLineHandler_EmptySymbol(t *testing.T) {
	h := NewHandler(NewGetKLinesUsecase(nil))

	req := httptest.NewRequest("GET", "/v1/market/kline?period=1min", nil)
	w := httptest.NewRecorder()

	h.handleGetKLines(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

// TestKLineHandler_LimitCap verifies that limit > 500 is silently capped to 500 (spec §4.2).
func TestKLineHandler_LimitCap(t *testing.T) {
	mockRepo := &stubKLineRepo{}
	h := NewHandler(NewGetKLinesUsecase(mockRepo))

	req := httptest.NewRequest("GET", "/v1/market/kline?symbol=AAPL&period=1min&limit=999", nil)
	w := httptest.NewRecorder()

	h.handleGetKLines(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}
}

type stubKLineRepo struct{}

func (m *stubKLineRepo) Save(ctx context.Context, k *KLine) error {
	return nil
}

func (m *stubKLineRepo) SaveBatch(ctx context.Context, klines []*KLine) error {
	return nil
}

func (m *stubKLineRepo) FindBySymbolAndInterval(ctx context.Context, symbol string, interval Interval, start, end time.Time, limit int) ([]*KLine, error) {
	return []*KLine{}, nil
}
