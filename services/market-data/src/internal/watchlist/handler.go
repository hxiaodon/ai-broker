package watchlist

import (
	"encoding/json"
	"errors"
	"net/http"
	"time"

	"github.com/hxiaodon/ai-broker/services/market-data/pkg/httputil"
)

// Handler provides HTTP endpoints for the watchlist subdomain.
type Handler struct {
	getWatchlist *GetWatchlistUsecase
	add          *AddToWatchlistUsecase
	remove       *RemoveFromWatchlistUsecase
}

// NewHandler creates a new watchlist Handler.
func NewHandler(
	getWatchlist *GetWatchlistUsecase,
	add *AddToWatchlistUsecase,
	remove *RemoveFromWatchlistUsecase,
) *Handler {
	return &Handler{
		getWatchlist: getWatchlist,
		add:          add,
		remove:       remove,
	}
}

// RegisterRoutes registers HTTP routes on the provided mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /v1/watchlist", h.handleGetWatchlist)
	mux.HandleFunc("POST /v1/watchlist", h.handleAddToWatchlist)
	mux.HandleFunc("DELETE /v1/watchlist/{symbol}", h.handleRemoveFromWatchlist)
}

// handleGetWatchlist handles GET /v1/watchlist (spec §10).
func (h *Handler) handleGetWatchlist(w http.ResponseWriter, r *http.Request) {
	// TODO(Phase-6): Extract userID from validated JWT claims.
	userID := httputil.ExtractUserID(r)
	if userID == "" {
		httputil.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED", "需要有效的 Authorization Bearer JWT", nil)
		return
	}

	items, err := h.getWatchlist.Execute(r.Context(), userID)
	if err != nil {
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "获取自选股失败", nil)
		return
	}

	symbols := make([]string, len(items))
	for i, item := range items {
		symbols[i] = item.Symbol
	}

	// Spec §10.3: response includes symbols array + quotes map + as_of.
	// Phase 5: quotes map is stubbed as empty; full implementation in Phase 6.
	httputil.WriteJSON(w, map[string]interface{}{
		"symbols": symbols,
		"quotes":  map[string]interface{}{},
		"as_of":   time.Now().UTC().Format(time.RFC3339Nano),
	})
}

type addWatchlistRequest struct {
	Symbol string `json:"symbol"`
}

// handleAddToWatchlist handles POST /v1/watchlist (spec §11).
func (h *Handler) handleAddToWatchlist(w http.ResponseWriter, r *http.Request) {
	userID := httputil.ExtractUserID(r)
	if userID == "" {
		httputil.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED", "需要有效的 Authorization Bearer JWT", nil)
		return
	}

	var req addWatchlistRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "请求体格式错误", nil)
		return
	}
	if req.Symbol == "" {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "symbol 不能为空", nil)
		return
	}

	// Infer market from symbol format (same logic as quote handler).
	market := "US"
	if isHKSymbol(req.Symbol) {
		market = "HK"
	}

	err := h.add.Execute(r.Context(), userID, req.Symbol, market)
	if err != nil {
		if errors.Is(err, ErrSymbolNotFound) {
			httputil.WriteError(w, http.StatusNotFound, "SYMBOL_NOT_FOUND",
				"股票代码 "+req.Symbol+" 不存在", nil)
			return
		}
		if errors.Is(err, ErrWatchlistFull) {
			httputil.WriteError(w, http.StatusBadRequest, "WATCHLIST_FULL",
				"自选股数量已达上限",
				map[string]int{"max": MaxWatchlistSize, "current": MaxWatchlistSize})
			return
		}
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "添加自选股失败", nil)
		return
	}

	// Spec §11.3: HTTP 200 with {symbol, added_at}.
	httputil.WriteJSON(w, map[string]interface{}{
		"symbol":   req.Symbol,
		"added_at": time.Now().UTC().Format(time.RFC3339Nano),
	})
}

// handleRemoveFromWatchlist handles DELETE /v1/watchlist/{symbol} (spec §12).
func (h *Handler) handleRemoveFromWatchlist(w http.ResponseWriter, r *http.Request) {
	userID := httputil.ExtractUserID(r)
	if userID == "" {
		httputil.WriteError(w, http.StatusUnauthorized, "UNAUTHORIZED", "需要有效的 Authorization Bearer JWT", nil)
		return
	}

	symbol := r.PathValue("symbol")
	if symbol == "" {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "symbol 不能为空", nil)
		return
	}

	err := h.remove.Execute(r.Context(), userID, symbol)
	if err != nil {
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "删除自选股失败", nil)
		return
	}

	// Spec §12.3: {symbol, removed: true/false}.
	// Phase 5: always return removed: true (idempotency check deferred).
	httputil.WriteJSON(w, map[string]interface{}{
		"symbol":  symbol,
		"removed": true,
	})
}

func isHKSymbol(symbol string) bool {
	if len(symbol) < 4 {
		return false
	}
	for _, c := range symbol {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}
