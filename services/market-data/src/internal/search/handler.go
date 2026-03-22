package search

import (
	"encoding/json"
	"net/http"
	"strconv"
)

// Handler provides HTTP endpoints for the search subdomain.
type Handler struct {
	searchStocks *SearchStocksUsecase
	getHotSearch *GetHotSearchUsecase
}

// NewHandler creates a new search Handler.
func NewHandler(searchStocks *SearchStocksUsecase, getHotSearch *GetHotSearchUsecase) *Handler {
	return &Handler{
		searchStocks: searchStocks,
		getHotSearch: getHotSearch,
	}
}

// RegisterRoutes registers HTTP routes on the provided mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/search", h.handleSearch)
	mux.HandleFunc("GET /api/v1/search/hot", h.handleHotSearch)
}

// handleSearch godoc
//
//	@Summary     Search stocks
//	@Description Full-text search across stock symbols and company names. Supports US (NYSE/NASDAQ) and HK (HKEX) markets.
//	@Tags        search
//	@Accept      json
//	@Produce     json
//	@Param       q       query     string  true   "Search query (symbol prefix or company name keyword)"
//	@Param       market  query     string  false  "Filter by market" Enums(US, HK)
//	@Param       limit   query     int     false  "Maximum number of results" default(20)
//	@Success     200     {array}   Stock
//	@Failure     400     {object}  map[string]string
//	@Failure     500     {object}  map[string]string
//	@Router      /search [get]
func (h *Handler) handleSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		http.Error(w, `{"error":"q query parameter required"}`, http.StatusBadRequest)
		return
	}
	market := r.URL.Query().Get("market")

	limitStr := r.URL.Query().Get("limit")
	limit := 20
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	stocks, err := h.searchStocks.Execute(r.Context(), query, market, limit)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(stocks); err != nil {
		http.Error(w, `{"error":"encode response"}`, http.StatusInternalServerError)
	}
}

// handleHotSearch godoc
//
//	@Summary     Get hot search rankings
//	@Description Returns the top-N most searched symbols in the last 24 hours, ranked by search frequency.
//	@Tags        search
//	@Accept      json
//	@Produce     json
//	@Param       n   query     int  false  "Number of top symbols to return" default(10)
//	@Success     200 {array}   HotSearchItem
//	@Failure     500 {object}  map[string]string
//	@Router      /search/hot [get]
func (h *Handler) handleHotSearch(w http.ResponseWriter, r *http.Request) {
	nStr := r.URL.Query().Get("n")
	n := 10
	if nStr != "" {
		if parsed, err := strconv.Atoi(nStr); err == nil {
			n = parsed
		}
	}

	items, err := h.getHotSearch.Execute(r.Context(), n)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(items); err != nil {
		http.Error(w, `{"error":"encode response"}`, http.StatusInternalServerError)
	}
}
