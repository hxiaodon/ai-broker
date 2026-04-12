package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"strings"
	"time"
)

func handleSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")

	results := []map[string]interface{}{}
	for symbol, quote := range baseQuotes {
		if strings.Contains(strings.ToLower(symbol), strings.ToLower(query)) ||
			strings.Contains(strings.ToLower(quote["name"].(string)), strings.ToLower(query)) {
			results = append(results, map[string]interface{}{
				"symbol": symbol,
				"name":   quote["name"],
				"market": quote["market"],
			})
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"results": results,
	})
}

func handleMovers(w http.ResponseWriter, r *http.Request) {
	movers := map[string]interface{}{
		"gainers": []map[string]interface{}{
			{"symbol": "AAPL", "name": "Apple Inc.", "change_pct": "1.33"},
			{"symbol": "0700", "name": "腾讯控股", "change_pct": "1.15"},
		},
		"losers": []map[string]interface{}{
			{"symbol": "TSLA", "name": "Tesla, Inc.", "change_pct": "-2.10"},
			{"symbol": "9988", "name": "阿里巴巴-SW", "change_pct": "-1.51"},
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(movers)
}

func handleStockDetail(w http.ResponseWriter, r *http.Request) {
	// Support both /api/market/detail/{symbol} and /v1/market/stocks/{symbol}
	symbol := strings.TrimPrefix(r.URL.Path, "/api/market/detail/")
	symbol = strings.TrimPrefix(symbol, "/v1/market/stocks/")
	symbol = strings.TrimPrefix(symbol, "/v1/market/detail/")

	quote := generateQuote(symbol, currentStrategy.Name())

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(quote)
}

func handleQuotes(w http.ResponseWriter, r *http.Request) {
	symbolsParam := r.URL.Query().Get("symbols")
	if symbolsParam == "" {
		http.Error(w, "Missing symbols parameter", http.StatusBadRequest)
		return
	}

	symbols := strings.Split(symbolsParam, ",")
	quotes := make(map[string]interface{})

	for _, symbol := range symbols {
		symbol = strings.TrimSpace(symbol)
		if symbol != "" {
			quotes[symbol] = generateQuote(symbol, currentStrategy.Name())
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"quotes": quotes,
		"as_of":  time.Now().UTC().Format(time.RFC3339),
	})
}

func handleKline(w http.ResponseWriter, r *http.Request) {
	// Support two formats:
	// 1. /v1/market/kline?symbol=AAPL&period=1d&limit=50
	// 2. /v1/market/kline/AAPL?period=1d&limit=50

	// First, check if symbol is in query params
	symbol := r.URL.Query().Get("symbol")

	// If not in query, extract from path
	if symbol == "" {
		symbol = strings.TrimPrefix(r.URL.Path, "/v1/market/kline/")
		symbol = strings.TrimSuffix(symbol, "/")
	}

	if symbol == "" {
		http.Error(w, "Missing symbol", http.StatusBadRequest)
		return
	}

	period := r.URL.Query().Get("period")
	if period == "" {
		period = "1d"
	}

	limitStr := r.URL.Query().Get("limit")
	limit := 50
	if limitStr != "" {
		if n := parseLimit(limitStr); n > 0 {
			limit = n
		}
	}

	// Get base quote for price reference
	basePrice := 100.0
	if quote, exists := baseQuotes[symbol]; exists {
		if price, ok := quote["price"].(string); ok {
			parsePrice(price, &basePrice)
		}
	}

	candles := generateCandles(basePrice, period, limit)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"symbol":      symbol,
		"period":      period,
		"candles":     candles,
		"total":       len(candles),
		"next_cursor": "",
	})
}

func parseLimit(s string) int {
	var n int
	fmt.Sscanf(s, "%d", &n)
	return n
}

func parsePrice(s string, dest *float64) {
	fmt.Sscanf(s, "%f", dest)
}

func generateCandles(basePrice float64, period string, count int) []map[string]interface{} {
	candles := []map[string]interface{}{}

	now := time.Now().UTC()
	currentPrice := basePrice

	// Determine candle duration based on period
	var duration time.Duration
	switch period {
	case "1min":
		duration = time.Minute
	case "5min":
		duration = 5 * time.Minute
	case "15min":
		duration = 15 * time.Minute
	case "30min":
		duration = 30 * time.Minute
	case "60min", "1h":
		duration = time.Hour
	case "1d":
		duration = 24 * time.Hour
	case "1w":
		duration = 7 * 24 * time.Hour
	case "1mo":
		duration = 30 * 24 * time.Hour
	default:
		duration = 24 * time.Hour
	}

	// Generate candles backward from now
	for i := 0; i < count; i++ {
		t := now.Add(-duration * time.Duration(count-i-1))

		// Generate OHLCV with small random walk
		open := currentPrice
		close := open + (rand.Float64()-0.5)*4 // ±2
		high := open
		low := open
		if close > high {
			high = close
		}
		if close < low {
			low = close
		}
		high += rand.Float64() * 2
		low -= rand.Float64() * 2

		volume := 1000000 + rand.Intn(9000000)

		candles = append(candles, map[string]interface{}{
			"t": t.Format(time.RFC3339),
			"o": formatDecimal(open),
			"h": formatDecimal(high),
			"l": formatDecimal(low),
			"c": formatDecimal(close),
			"v": volume,
			"n": rand.Intn(1000) + 100,
		})

		currentPrice = close
	}

	return candles
}

func formatDecimal(f float64) string {
	return fmt.Sprintf("%.2f", f)
}
