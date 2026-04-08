package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
)

var (
	port     = flag.Int("port", 8080, "Server port")
	strategy = flag.String("strategy", "normal", "Test strategy: normal, delayed, unstable, error, guest")
)

func main() {
	flag.Parse()

	// Validate strategy
	if !isValidStrategy(*strategy) {
		fmt.Fprintf(os.Stderr, "Invalid strategy: %s\n", *strategy)
		fmt.Fprintf(os.Stderr, "Valid strategies: normal, delayed, unstable, error, guest\n")
		os.Exit(1)
	}

	// Initialize strategy
	currentStrategy = getStrategy(*strategy)

	// Routes
	http.HandleFunc("/ws/market-data", handleWebSocket)
	http.HandleFunc("/v1/market/quotes", handleQuotes)
	http.HandleFunc("/v1/market/search", handleSearch)
	http.HandleFunc("/v1/market/movers", handleMovers)
	http.HandleFunc("/v1/market/stocks/", handleStockDetail)
	http.HandleFunc("/v1/market/detail/", handleStockDetail)
	http.HandleFunc("/api/market/search", handleSearch)
	http.HandleFunc("/api/market/movers", handleMovers)
	http.HandleFunc("/api/market/detail/", handleStockDetail)
	http.HandleFunc("/health", handleHealth)

	addr := fmt.Sprintf(":%d", *port)
	log.Printf("🚀 Mock server started on %s (strategy: %s)", addr, *strategy)
	log.Printf("📡 WebSocket endpoint: ws://localhost%s/ws/market-data", addr)
	log.Printf("🔧 Switch strategy: go run . --strategy=<name>")
	log.Fatal(http.ListenAndServe(addr, nil))
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok","strategy":"%s"}`, *strategy)
}

func isValidStrategy(s string) bool {
	valid := []string{"normal", "delayed", "unstable", "error", "guest"}
	for _, v := range valid {
		if s == v {
			return true
		}
	}
	return false
}
