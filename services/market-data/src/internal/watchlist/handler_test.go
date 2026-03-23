package watchlist

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

type mockRepo struct{}

func (m *mockRepo) FindByUserID(ctx context.Context, userID string) ([]*WatchlistItem, error) {
	return nil, nil
}
func (m *mockRepo) Add(ctx context.Context, item *WatchlistItem) error { return nil }
func (m *mockRepo) Remove(ctx context.Context, userID, symbol string) error { return nil }
func (m *mockRepo) CountByUserID(ctx context.Context, userID string) (int, error) { return 0, nil }
func (m *mockRepo) ExistsByUserAndSymbol(ctx context.Context, userID, symbol string) (bool, error) {
	return false, nil
}
func (m *mockRepo) Reorder(ctx context.Context, userID string, symbolOrder []string) error {
	return nil
}

type mockValidator struct {
	exists bool
}

func (m *mockValidator) ExistsBySymbol(ctx context.Context, symbol string) (bool, error) {
	return m.exists, nil
}

type mockAddRepo struct {
	mockRepo
	countResult int
}

func (m *mockAddRepo) CountByUserID(ctx context.Context, userID string) (int, error) {
	return m.countResult, nil
}

func TestWatchlistHandler_AddSymbol_WatchlistFull(t *testing.T) {
	repo := &mockAddRepo{countResult: MaxWatchlistSize}
	addUsecase := NewAddToWatchlistUsecase(repo, &mockValidator{exists: true})
	h := NewHandler(NewGetWatchlistUsecase(&mockRepo{}), addUsecase, NewRemoveFromWatchlistUsecase(&mockRepo{}))

	body := bytes.NewBufferString(`{"symbol":"AAPL"}`)
	req := httptest.NewRequest("POST", "/v1/watchlist", body)
	req.Header.Set("X-User-ID", "test-user-123")
	w := httptest.NewRecorder()

	h.handleAddToWatchlist(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", w.Code)
	}
}

func TestWatchlistHandler_AddSymbol_SymbolNotFound(t *testing.T) {
	addUsecase := NewAddToWatchlistUsecase(&mockRepo{}, &mockValidator{exists: false})
	h := NewHandler(NewGetWatchlistUsecase(&mockRepo{}), addUsecase, NewRemoveFromWatchlistUsecase(&mockRepo{}))

	body := bytes.NewBufferString(`{"symbol":"INVALID"}`)
	req := httptest.NewRequest("POST", "/v1/watchlist", body)
	req.Header.Set("X-User-ID", "test-user-123")
	w := httptest.NewRecorder()

	h.handleAddToWatchlist(w, req)

	if w.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", w.Code)
	}
}
