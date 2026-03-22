package kline

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"
)

// Handler provides HTTP endpoints for the kline subdomain.
type Handler struct {
	getKLines *GetKLinesUsecase
}

// NewHandler creates a new kline Handler.
func NewHandler(getKLines *GetKLinesUsecase) *Handler {
	return &Handler{getKLines: getKLines}
}

// RegisterRoutes registers HTTP routes on the provided mux.
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/kline", h.handleGetKLines)
}

// handleGetKLines godoc
//
//	@Summary     Get K-line (candlestick) data
//	@Description Returns OHLCV candlestick bars for a symbol and interval. Historical prices use split+dividend backward adjustment.
//	@Tags        kline
//	@Accept      json
//	@Produce     json
//	@Param       symbol    query     string  true   "Stock symbol (e.g. AAPL, 00700)"
//	@Param       interval  query     string  false  "Bar interval" Enums(1min,5min,15min,30min,1h,1D,1W,1M) default(1D)
//	@Param       limit     query     int     false  "Maximum number of bars to return" default(200)
//	@Param       start     query     string  false  "Start time in RFC 3339 format (e.g. 2024-01-01T00:00:00Z)"
//	@Param       end       query     string  false  "End time in RFC 3339 format (e.g. 2024-12-31T23:59:59Z)"
//	@Success     200       {array}   KLine
//	@Failure     400       {object}  map[string]string
//	@Failure     500       {object}  map[string]string
//	@Security    BearerAuth
//	@Router      /kline [get]
func (h *Handler) handleGetKLines(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")
	if symbol == "" {
		http.Error(w, `{"error":"symbol query parameter required"}`, http.StatusBadRequest)
		return
	}

	intervalStr := r.URL.Query().Get("interval")
	if intervalStr == "" {
		intervalStr = "1D"
	}
	interval := Interval(intervalStr)

	limitStr := r.URL.Query().Get("limit")
	limit := 200
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	// Default time range: last 30 days.
	end := time.Now().UTC()
	start := end.AddDate(0, 0, -30)

	if s := r.URL.Query().Get("start"); s != "" {
		if t, err := time.Parse(time.RFC3339, s); err == nil {
			start = t.UTC()
		}
	}
	if e := r.URL.Query().Get("end"); e != "" {
		if t, err := time.Parse(time.RFC3339, e); err == nil {
			end = t.UTC()
		}
	}

	klines, err := h.getKLines.Execute(r.Context(), symbol, interval, start, end, limit)
	if err != nil {
		http.Error(w, `{"error":"`+err.Error()+`"}`, http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(klines); err != nil {
		http.Error(w, `{"error":"encode response"}`, http.StatusInternalServerError)
	}
}
