package quote

import (
	"encoding/json"
	"net/http"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// Handler provides HTTP and gRPC endpoints for the quote subdomain.
type Handler struct {
	getQuote       *app.GetQuoteUsecase
	getStatus      *app.GetMarketStatusUsecase
}

// NewHandler creates a new quote Handler.
func NewHandler(
	getQuote *app.GetQuoteUsecase,
	getStatus *app.GetMarketStatusUsecase,
) *Handler {
	return &Handler{
		getQuote:  getQuote,
		getStatus: getStatus,
	}
}

// RegisterRoutes registers HTTP routes on the provided mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/quote", h.handleGetQuote)
	mux.HandleFunc("GET /api/v1/market/status", h.handleGetMarketStatus)
}

// handleGetQuote godoc
//
//	@Summary     Get real-time quote
//	@Description Returns the latest quote snapshot for a given symbol. For guest users the price is delayed 15 minutes and labeled accordingly.
//	@Tags        quote
//	@Accept      json
//	@Produce     json
//	@Param       symbol   query     string true  "Stock symbol (e.g. AAPL, 00700)"
//	@Success     200      {object}  domain.Quote
//	@Failure     400      {object}  map[string]string
//	@Failure     404      {object}  map[string]string
//	@Failure     500      {object}  map[string]string
//	@Security    BearerAuth
//	@Router      /quote [get]
func (h *Handler) handleGetQuote(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")
	if symbol == "" {
		http.Error(w, `{"error":"symbol query parameter required"}`, http.StatusBadRequest)
		return
	}

	q, err := h.getQuote.Execute(r.Context(), symbol)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(q); err != nil {
		http.Error(w, `{"error":"encode response"}`, http.StatusInternalServerError)
	}
}

// handleGetMarketStatus godoc
//
//	@Summary     Get market trading status
//	@Description Returns the current trading phase and session times for a given market (US or HK).
//	@Tags        quote
//	@Accept      json
//	@Produce     json
//	@Param       market   query     string false  "Market identifier (US or HK)" Enums(US, HK) default(US)
//	@Success     200      {object}  domain.MarketStatus
//	@Failure     500      {object}  map[string]string
//	@Router      /market/status [get]
func (h *Handler) handleGetMarketStatus(w http.ResponseWriter, r *http.Request) {
	marketParam := r.URL.Query().Get("market")
	if marketParam == "" {
		marketParam = "US"
	}

	market := domain.Market(marketParam)
	status, err := h.getStatus.Execute(r.Context(), market)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(status); err != nil {
		http.Error(w, `{"error":"encode response"}`, http.StatusInternalServerError)
	}
}
