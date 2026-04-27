package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/websocket"
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
	// Auth endpoints
	http.HandleFunc("/v1/auth/otp/send", handleOtpSend)
	http.HandleFunc("/v1/auth/otp/verify", handleOtpVerify)
	http.HandleFunc("/v1/auth/token/refresh", handleTokenRefresh)
	http.HandleFunc("/v1/auth/biometric/register", handleBiometricRegister)
	http.HandleFunc("/v1/auth/biometric/verify", handleBiometricVerify)
	http.HandleFunc("/v1/auth/logout", handleLogout)
	http.HandleFunc("/v1/auth/devices", handleGetDevices)
	http.HandleFunc("/v1/auth/devices/", handleDeleteDevice)

	// Trading endpoints
	http.HandleFunc("/api/v1/auth/session-key", handleSessionKey)
	http.HandleFunc("/api/v1/trading/nonce", handleTradingNonce)
	http.HandleFunc("/api/v1/trading/bio-challenge", handleBioChallenge)
	http.HandleFunc("/api/v1/orders", handleOrders)
	http.HandleFunc("/api/v1/orders/", handleOrderByID)
	http.HandleFunc("/api/v1/positions", handlePositions)
	http.HandleFunc("/api/v1/positions/", handlePositionBySymbol)
	http.HandleFunc("/api/v1/portfolio/summary", handlePortfolioSummary)
	http.HandleFunc("/ws/trading", handleTradingWS)

	// Watchlist endpoints (registered users)
	http.HandleFunc("/v1/watchlist", handleWatchlist)
	http.HandleFunc("/v1/watchlist/", handleDeleteWatchlist)

	// Market endpoints
	// Merge REST and WebSocket on same path
	http.HandleFunc("/v1/market/quotes", func(w http.ResponseWriter, r *http.Request) {
		if websocket.IsWebSocketUpgrade(r) {
			handleWebSocket(w, r)
		} else {
			handleQuotes(w, r)
		}
	})
	http.HandleFunc("/v1/market/kline", handleKline)
	http.HandleFunc("/v1/market/kline/", handleKline)
	http.HandleFunc("/v1/market/search", handleSearch)
	http.HandleFunc("/v1/market/movers", handleMovers)
	http.HandleFunc("/v1/market/stocks/", handleStockDetail)
	http.HandleFunc("/v1/market/detail/", handleStockDetail)
	http.HandleFunc("/api/market/search", handleSearch)
	http.HandleFunc("/api/market/movers", handleMovers)
	http.HandleFunc("/api/market/detail/", handleStockDetail)
	http.HandleFunc("/health", handleHealth)

	// Funding endpoints
	http.HandleFunc("/api/v1/balance", handleFundingBalance)
	http.HandleFunc("/api/v1/deposit", handleFundingDeposit)
	http.HandleFunc("/api/v1/withdrawal", handleFundingWithdrawal)
	http.HandleFunc("/api/v1/fund/history", handleFundingHistory)
	http.HandleFunc("/api/v1/bank-accounts", handleFundingBankAccounts)
	http.HandleFunc("/api/v1/bank-accounts/", handleFundingBankAccountByID)
	http.HandleFunc("/api/v1/funding/bio-challenge", handleFundingBioChallenge)

	addr := fmt.Sprintf(":%d", *port)
	log.Printf("🚀 Mock server started on %s (strategy: %s)", addr, *strategy)
	log.Printf("📡 WebSocket endpoint: ws://localhost%s/v1/market/quotes", addr)
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
