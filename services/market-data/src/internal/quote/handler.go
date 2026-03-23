package quote

import (
	"net/http"
	"strings"
	"time"

	"github.com/shopspring/decimal"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/httputil"
)

// Handler provides HTTP and gRPC endpoints for the quote subdomain.
type Handler struct {
	getQuote  *app.GetQuoteUsecase
	getStatus *app.GetMarketStatusUsecase
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
// Routes align with market-api-spec.md §2:
//
//	GET /v1/market/quotes     — batch quote snapshots (§3)
//	GET /v1/market/status     — market trading status
//
// Stub routes return 501 Not Implemented for endpoints deferred to later phases:
//
//	GET /v1/market/movers
//	GET /v1/market/stocks/{symbol}
//	GET /v1/market/news/{symbol}
//	GET /v1/market/financials/{symbol}
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /v1/market/quotes", h.handleGetQuotes)
	mux.HandleFunc("GET /v1/market/status", h.handleGetMarketStatus)

	// Stub endpoints — not implemented in Phase 5.
	mux.HandleFunc("GET /v1/market/movers", handleNotImplemented)
	mux.HandleFunc("GET /v1/market/stocks/{symbol}", handleNotImplemented)
	mux.HandleFunc("GET /v1/market/news/{symbol}", handleNotImplemented)
	mux.HandleFunc("GET /v1/market/financials/{symbol}", handleNotImplemented)
}

// handleNotImplemented returns 501 for endpoints that are not yet implemented.
func handleNotImplemented(w http.ResponseWriter, _ *http.Request) {
	httputil.WriteError(w, http.StatusNotImplemented, "NOT_IMPLEMENTED", "this endpoint is not yet implemented", nil)
}

// quoteResponse is the JSON representation of a single quote.
// All price fields are strings (spec §1.2 — never float/double).
// is_stale and stale_since_ms are mandatory on every quote response (spec §1.7).
type quoteResponse struct {
	Symbol       string `json:"symbol"`
	Name         string `json:"name"`
	NameZh       string `json:"name_zh"`
	Market       string `json:"market"`
	Price        string `json:"price"`
	Change       string `json:"change"`
	ChangePct    string `json:"change_pct"`
	Volume       int64  `json:"volume"`
	Bid          string `json:"bid"`
	Ask          string `json:"ask"`
	Turnover     string `json:"turnover"`
	PrevClose    string `json:"prev_close"`
	Open         string `json:"open"`
	High         string `json:"high"`
	Low          string `json:"low"`
	MarketCap    string `json:"market_cap"`
	PERatio      string `json:"pe_ratio"`
	Delayed      bool   `json:"delayed"`
	MarketStatus string `json:"market_status"`
	IsStale      bool   `json:"is_stale"`
	StaleSinceMs int64  `json:"stale_since_ms"`
}

// quotesResponse is the top-level response for GET /v1/market/quotes (spec §3.3).
type quotesResponse struct {
	Quotes map[string]*quoteResponse `json:"quotes"`
	AsOf   string                    `json:"as_of"`
}

// marketStatusResponse is the top-level response for GET /v1/market/status.
type marketStatusResponse struct {
	Market    string `json:"market"`
	Status    string `json:"status"`
	UpdatedAt string `json:"updated_at"`
}

// allowedMarkets is the allowlist for the market query parameter (spec §1.2).
var allowedMarkets = map[string]bool{
	"US": true,
	"HK": true,
}

// handleGetQuotes handles GET /v1/market/quotes
//
// Spec: market-api-spec.md §3
// - symbols: comma-separated, max 50 (§3.2)
// - delayed: determined by presence of a structurally valid Bearer JWT (§1.5)
// - is_stale + stale_since_ms: mandatory on every quote (§1.7)
// - Symbols that are not found are silently omitted from the response map (§3.6)
//
// TODO(Phase-6): Replace lightweight JWT check with full RS256 validation using
// the AMS public key. Current stub only checks structural validity (3 JWT segments).
func (h *Handler) handleGetQuotes(w http.ResponseWriter, r *http.Request) {
	symbolsParam := r.URL.Query().Get("symbols")
	if symbolsParam == "" {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "symbols 参数不能为空", nil)
		return
	}

	rawSymbols := strings.Split(symbolsParam, ",")
	if len(rawSymbols) > 50 {
		httputil.WriteError(w, http.StatusBadRequest, "TOO_MANY_SYMBOLS",
			"symbols 参数最多允许 50 个",
			map[string]int{"max": 50, "provided": len(rawSymbols)})
		return
	}

	// Deduplicate and trim whitespace.
	seen := make(map[string]bool, len(rawSymbols))
	symbols := make([]string, 0, len(rawSymbols))
	for _, s := range rawSymbols {
		s = strings.TrimSpace(s)
		if s == "" || seen[s] {
			continue
		}
		seen[s] = true
		symbols = append(symbols, s)
	}

	// Determine delayed flag from JWT presence (spec §1.5).
	// TODO(Phase-6): replace with full JWT validation.
	delayed := !httputil.IsValidJWT(r)

	quotes := make(map[string]*quoteResponse, len(symbols))
	asOf := time.Now().UTC()

	for _, sym := range symbols {
		// Infer market from symbol format: HK stocks are 4–5 digit codes.
		market := inferMarket(sym)

		q, err := h.getQuote.Execute(r.Context(), market, sym)
		if err != nil {
			// Spec §3.6: silently omit symbols that cannot be resolved.
			continue
		}

		quotes[sym] = domainQuoteToResponse(q, delayed)
		if q.LastUpdatedAt.After(time.Time{}) && q.LastUpdatedAt.After(asOf.Add(-time.Second)) {
			// Keep asOf as current server time; exchange timestamps may be older.
			_ = q.LastUpdatedAt
		}
	}

	httputil.WriteJSON(w, &quotesResponse{
		Quotes: quotes,
		AsOf:   asOf.Format(time.RFC3339Nano),
	})
}

// handleGetMarketStatus handles GET /v1/market/status
func (h *Handler) handleGetMarketStatus(w http.ResponseWriter, r *http.Request) {
	marketParam := r.URL.Query().Get("market")
	if marketParam == "" {
		marketParam = "US"
	}
	if !allowedMarkets[marketParam] {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL",
			"market 参数不合法，合法值为：US, HK",
			map[string]string{"provided": marketParam})
		return
	}

	market := domain.Market(marketParam)
	status, err := h.getStatus.Execute(r.Context(), market)
	if err != nil {
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "获取市场状态失败", nil)
		return
	}

	httputil.WriteJSON(w, &marketStatusResponse{
		Market:    string(status.Market),
		Status:    string(status.Phase),
		UpdatedAt: status.UpdatedAt.UTC().Format(time.RFC3339Nano),
	})
}

// domainQuoteToResponse converts a domain.Quote to a quoteResponse.
// Price fields are formatted as decimal strings per spec §1.2:
//   - US stocks: 4 decimal places
//   - HK stocks: 3 decimal places
//
// Spec: financial-coding-standards Rule 1 — never serialize financial values as float.
func domainQuoteToResponse(q *domain.Quote, delayed bool) *quoteResponse {
	dp := 4
	if q.Market == domain.MarketHK {
		dp = 3
	}
	fmtPrice := func(d decimal.Decimal) string {
		return d.StringFixed(int32(dp))
	}
	fmtPct := func(d decimal.Decimal) string {
		return d.StringFixed(2)
	}

	return &quoteResponse{
		Symbol:       q.Symbol,
		Name:         q.Name,
		NameZh:       q.NameZh,
		Market:       string(q.Market),
		Price:        fmtPrice(q.Price),
		Change:       fmtPrice(q.Change),
		ChangePct:    fmtPct(q.ChangePct),
		Volume:       q.Volume,
		Bid:          fmtPrice(q.Bid),
		Ask:          fmtPrice(q.Ask),
		Turnover:     formatLargeDecimal(q.Turnover),
		PrevClose:    fmtPrice(q.PrevClose),
		Open:         fmtPrice(q.Open),
		High:         fmtPrice(q.High),
		Low:          fmtPrice(q.Low),
		MarketCap:    formatLargeDecimal(q.MarketCap),
		PERatio:      fmtPct(q.PERatio),
		Delayed:      delayed,
		MarketStatus: string(q.MarketStatus),
		IsStale:      q.IsStale,
		StaleSinceMs: q.StaleSinceMs,
	}
}

// inferMarket detects whether a symbol is a HK stock (all digits, 4–5 chars).
// US symbols are 1–5 uppercase letters; HK codes are zero-padded 4–5 digit numbers.
func inferMarket(symbol string) domain.Market {
	allDigits := true
	for _, c := range symbol {
		if c < '0' || c > '9' {
			allDigits = false
			break
		}
	}
	if allDigits && len(symbol) >= 4 {
		return domain.MarketHK
	}
	return domain.MarketUS
}

// formatLargeDecimal formats large decimal values with T/B/M suffix as strings.
// Used for turnover and market_cap fields (spec §1.2 — "带单位后缀").
// Values are passed through as decimal strings when no suffix applies.
func formatLargeDecimal(d decimal.Decimal) string {
	trillion := decimal.NewFromFloat(1e12)
	billion := decimal.NewFromFloat(1e9)
	million := decimal.NewFromFloat(1e6)

	switch {
	case d.GreaterThanOrEqual(trillion):
		return d.Div(trillion).StringFixed(2) + "T"
	case d.GreaterThanOrEqual(billion):
		return d.Div(billion).StringFixed(2) + "B"
	case d.GreaterThanOrEqual(million):
		return d.Div(million).StringFixed(2) + "M"
	default:
		return d.StringFixed(2)
	}
}
