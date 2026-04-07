package main

import (
	"encoding/json"
	"net/http"
	"strings"
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
	symbol := strings.TrimPrefix(r.URL.Path, "/api/market/detail/")

	quote := generateQuote(symbol, "registered")

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(quote)
}
