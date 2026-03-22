package watchlist

import (
	"encoding/json"
	"net/http"
	"strconv"
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
	mux.HandleFunc("GET /api/v1/watchlist", h.handleGetWatchlist)
	mux.HandleFunc("POST /api/v1/watchlist", h.handleAddToWatchlist)
	mux.HandleFunc("DELETE /api/v1/watchlist", h.handleRemoveFromWatchlist)
}

// handleGetWatchlist godoc
//
//	@Summary     Get user watchlist
//	@Description Returns all symbols in the user's watchlist with latest quotes.
//	@Tags        watchlist
//	@Accept      json
//	@Produce     json
//	@Param       user_id  query     int  true  "User ID (temporary; production uses JWT claims)"
//	@Success     200      {array}   WatchlistItem
//	@Failure     400      {object}  map[string]string
//	@Failure     500      {object}  map[string]string
//	@Security    BearerAuth
//	@Router      /watchlist [get]
func (h *Handler) handleGetWatchlist(w http.ResponseWriter, r *http.Request) {
	// FILL: extract userID from JWT claims in production.
	userIDStr := r.URL.Query().Get("user_id")
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid user_id"}`, http.StatusBadRequest)
		return
	}

	items, err := h.getWatchlist.Execute(r.Context(), userID)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(items); err != nil {
		http.Error(w, `{"error":"encode response"}`, http.StatusInternalServerError)
	}
}

type addWatchlistRequest struct {
	UserID int64  `json:"user_id"`
	Symbol string `json:"symbol"`
	Market string `json:"market"`
}

// handleAddToWatchlist godoc
//
//	@Summary     Add symbol to watchlist
//	@Description Adds a stock symbol to the user's watchlist. Duplicate symbols are ignored.
//	@Tags        watchlist
//	@Accept      json
//	@Produce     json
//	@Param       request  body      addWatchlistRequest  true  "Symbol to add"
//	@Success     201      {object}  map[string]string
//	@Failure     400      {object}  map[string]string
//	@Failure     500      {object}  map[string]string
//	@Security    BearerAuth
//	@Router      /watchlist [post]
func (h *Handler) handleAddToWatchlist(w http.ResponseWriter, r *http.Request) {
	var req addWatchlistRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid request body"}`, http.StatusBadRequest)
		return
	}

	if err := h.add.Execute(r.Context(), req.UserID, req.Symbol, req.Market); err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}

// handleRemoveFromWatchlist godoc
//
//	@Summary     Remove symbol from watchlist
//	@Description Removes a stock symbol from the user's watchlist. No-op if symbol is not present.
//	@Tags        watchlist
//	@Accept      json
//	@Produce     json
//	@Param       user_id  query     int     true  "User ID (temporary; production uses JWT claims)"
//	@Param       symbol   query     string  true  "Stock symbol to remove"
//	@Success     200      {object}  map[string]string
//	@Failure     400      {object}  map[string]string
//	@Failure     500      {object}  map[string]string
//	@Security    BearerAuth
//	@Router      /watchlist [delete]
func (h *Handler) handleRemoveFromWatchlist(w http.ResponseWriter, r *http.Request) {
	// FILL: extract userID from JWT claims in production.
	userIDStr := r.URL.Query().Get("user_id")
	userID, err := strconv.ParseInt(userIDStr, 10, 64)
	if err != nil {
		http.Error(w, `{"error":"invalid user_id"}`, http.StatusBadRequest)
		return
	}
	symbol := r.URL.Query().Get("symbol")
	if symbol == "" {
		http.Error(w, `{"error":"symbol required"}`, http.StatusBadRequest)
		return
	}

	if err := h.remove.Execute(r.Context(), userID, symbol); err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}
