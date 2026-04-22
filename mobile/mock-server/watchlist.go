package main

import (
	"encoding/json"
	"net/http"
	"strings"
)

func handleWatchlist(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		handleGetWatchlist(w, r)
	case http.MethodPost:
		handleAddWatchlist(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleGetWatchlist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(buildWatchlistResponse(cloneRegisteredWatchlist()))
}

func handleAddWatchlist(w http.ResponseWriter, r *http.Request) {
	var body struct {
		Symbol string `json:"symbol"`
		Market string `json:"market"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	if body.Symbol == "" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error":   "INVALID_SYMBOL",
			"message": "symbol 不能为空",
		})
		return
	}
	ensureInRegisteredWatchlist(body.Symbol)
	w.WriteHeader(http.StatusNoContent)
}

func handleDeleteWatchlist(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	symbol := strings.TrimPrefix(r.URL.Path, "/v1/watchlist/")
	if symbol == "" {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
	removeFromRegisteredWatchlist(symbol)
	w.WriteHeader(http.StatusNoContent)
}
