package kline

import (
	"net/http"
	"strconv"
	"time"

	"github.com/hxiaodon/ai-broker/services/market-data/pkg/httputil"
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
	mux.HandleFunc("GET /v1/market/kline", h.handleGetKLines)
}

// klineResponse is the top-level response for GET /v1/market/kline (spec §4.3).
type klineResponse struct {
	Symbol     string          `json:"symbol"`
	Period     string          `json:"period"`
	Candles    []candleItem    `json:"candles"`
	NextCursor *string         `json:"next_cursor"`
	Total      int             `json:"total"`
}

type candleItem struct {
	T string `json:"t"` // ISO 8601 timestamp
	O string `json:"o"` // open (4dp string)
	H string `json:"h"` // high
	L string `json:"l"` // low
	C string `json:"c"` // close
	V int64  `json:"v"` // volume
	N int    `json:"n"` // trade count (stub: always 0 in Phase 5)
}

var allowedPeriods = map[string]bool{
	"1min": true, "5min": true, "15min": true, "30min": true,
	"60min": true, "1d": true, "1w": true, "1mo": true,
}

// handleGetKLines handles GET /v1/market/kline (spec §4).
func (h *Handler) handleGetKLines(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")
	if symbol == "" {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_SYMBOL", "symbol 参数不能为空", nil)
		return
	}

	period := r.URL.Query().Get("period")
	if period == "" {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_PERIOD", "period 参数不能为空", nil)
		return
	}
	if !allowedPeriods[period] {
		httputil.WriteError(w, http.StatusBadRequest, "INVALID_PERIOD",
			"period 参数不合法，合法值为：1min, 5min, 15min, 30min, 60min, 1d, 1w, 1mo",
			map[string]string{"provided": period})
		return
	}

	// Map spec period names to internal Interval constants.
	interval := mapPeriodToInterval(period)

	limit := 100
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}
	if limit > 500 {
		limit = 500
	}

	// Parse time range.
	end := time.Now().UTC()
	start := end.AddDate(0, 0, -30)
	if s := r.URL.Query().Get("from"); s != "" {
		if t, err := time.Parse(time.RFC3339, s); err == nil {
			start = t.UTC()
		}
	}
	if e := r.URL.Query().Get("to"); e != "" {
		if t, err := time.Parse(time.RFC3339, e); err == nil {
			end = t.UTC()
		}
	}

	klines, err := h.getKLines.Execute(r.Context(), symbol, interval, start, end, limit)
	if err != nil {
		httputil.WriteError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "查询 K 线失败", nil)
		return
	}

	candles := make([]candleItem, len(klines))
	for i, k := range klines {
		candles[i] = candleItem{
			T: k.StartTime.UTC().Format(time.RFC3339Nano),
			O: k.Open.StringFixed(4),
			H: k.High.StringFixed(4),
			L: k.Low.StringFixed(4),
			C: k.Close.StringFixed(4),
			V: k.Volume,
			N: 0, // Trade count not implemented in Phase 5.
		}
	}

	httputil.WriteJSON(w, &klineResponse{
		Symbol:     symbol,
		Period:     period,
		Candles:    candles,
		NextCursor: nil, // Cursor pagination not implemented in Phase 5.
		Total:      len(candles),
	})
}

func mapPeriodToInterval(period string) Interval {
	switch period {
	case "1min":
		return Interval1Min
	case "5min":
		return Interval5Min
	case "15min":
		return Interval15Min
	case "30min":
		return Interval30Min
	case "60min":
		return Interval1H
	case "1d":
		return Interval1D
	case "1w":
		return Interval1W
	case "1mo":
		return Interval1M
	default:
		return Interval1D
	}
}
