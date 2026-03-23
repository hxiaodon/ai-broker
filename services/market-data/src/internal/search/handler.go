package search

import (
	"net/http"
	"strconv"

	"github.com/hxiaodon/ai-broker/services/market-data/pkg/httputil"
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
	mux.HandleFunc("GET /v1/market/search", h.handleSearch)
	mux.HandleFunc("GET /v1/market/search/hot", h.handleHotSearch)
}

// searchResponse is the top-level response for GET /v1/market/search (spec §5.3).
type searchResponse struct {
	Results []searchResultItem `json:"results"`
	Total   int                `json:"total"`
}

type searchResultItem struct {
	Symbol    string `json:"symbol"`
	Name      string `json:"name"`
	NameZh    string `json:"name_zh"`
	Market    string `json:"market"`
	Price     string `json:"price"`
	ChangePct string `json:"change_pct"`
	Delayed   bool   `json:"delayed"`
}

// handleSearch handles GET /v1/market/search (spec §5).
func (h *Handler) handleSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "搜索关键词 q 不能为空", nil)
		return
	}

	market := r.URL.Query().Get("market")
	limit := 10
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}
	if limit > 50 {
		limit = 50
	}

	stocks, err := h.searchStocks.Execute(r.Context(), query, market, limit)
	if err != nil {
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "搜索失败", nil)
		return
	}

	delayed := !httputil.IsValidJWT(r)
	results := make([]searchResultItem, len(stocks))
	for i, s := range stocks {
		results[i] = searchResultItem{
			Symbol:    s.Symbol,
			Name:      s.Name,
			NameZh:    s.NameCN,
			Market:    s.Market,
			Price:     "0.0000", // Stub: quote lookup deferred to Phase 6.
			ChangePct: "0.00",
			Delayed:   delayed,
		}
	}

	httputil.WriteJSON(w, &searchResponse{
		Results: results,
		Total:   len(results),
	})
}

// hotSearchResponse is the top-level response for GET /v1/market/search/hot.
type hotSearchResponse struct {
	Items []hotSearchItem `json:"items"`
}

type hotSearchItem struct {
	Symbol string `json:"symbol"`
	Name   string `json:"name"`
}

// handleHotSearch handles GET /v1/market/search/hot.
func (h *Handler) handleHotSearch(w http.ResponseWriter, r *http.Request) {
	n := 10
	if nStr := r.URL.Query().Get("n"); nStr != "" {
		if parsed, err := strconv.Atoi(nStr); err == nil && parsed > 0 {
			n = parsed
		}
	}

	items, err := h.getHotSearch.Execute(r.Context(), n)
	if err != nil {
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "获取热搜失败", nil)
		return
	}

	results := make([]hotSearchItem, len(items))
	for i, item := range items {
		results[i] = hotSearchItem{
			Symbol: item.Symbol,
			Name:   item.Name,
		}
	}

	httputil.WriteJSON(w, &hotSearchResponse{Items: results})
}
