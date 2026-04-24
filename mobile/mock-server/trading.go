package main

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// ─── In-memory state ─────────────────────────────────────────────────────────

var (
	sessionKeys   = make(map[string]*SessionKeyEntry) // key_id -> entry
	sessionMu     sync.RWMutex
	usedNonces    = make(map[string]time.Time) // nonce -> consumed_at
	nonceMu       sync.RWMutex
	usedChallenges = make(map[string]time.Time) // challenge -> consumed_at
	challengeMu   sync.RWMutex
	tradingOrders = initOrders()
	ordersMu      sync.RWMutex
)

type SessionKeyEntry struct {
	KeyID     string
	Secret    string
	ExpiresAt time.Time
}

type SubmitOrderRequest struct {
	Symbol        string  `json:"symbol"`
	Market        string  `json:"market"`
	Side          string  `json:"side"`
	OrderType     string  `json:"order_type"`
	Qty           int     `json:"qty"`
	LimitPrice    *string `json:"limit_price,omitempty"`
	Validity      string  `json:"validity"`
	ExtendedHours bool    `json:"extended_hours"`
}

// ─── Preset data ─────────────────────────────────────────────────────────────

func initOrders() []map[string]interface{} {
	now := time.Now().UTC()
	return []map[string]interface{}{
		{
			"order_id":      "ord-001",
			"symbol":        "AAPL",
			"market":        "US",
			"side":          "buy",
			"order_type":    "limit",
			"status":        "FILLED",
			"display_status": "已成交",
			"qty":           100,
			"filled_qty":    100,
			"limit_price":   "150.2500",
			"avg_fill_price": "150.2500",
			"validity":      "day",
			"extended_hours": false,
			"fees": map[string]interface{}{
				"commission":  "0.99",
				"exchange_fee": "0.03",
				"sec_fee":     "0.01",
				"finra_fee":   "0.005",
				"total":       "1.035",
			},
			"created_at": now.Add(-2 * time.Hour).Format(time.RFC3339Nano),
			"updated_at": now.Add(-90 * time.Minute).Format(time.RFC3339Nano),
		},
		{
			"order_id":      "ord-002",
			"symbol":        "TSLA",
			"market":        "US",
			"side":          "buy",
			"order_type":    "limit",
			"status":        "PENDING",
			"display_status": "待成交",
			"qty":           50,
			"filled_qty":    0,
			"limit_price":   "240.0000",
			"avg_fill_price": nil,
			"validity":      "day",
			"extended_hours": false,
			"fees": map[string]interface{}{
				"commission":  "0.99",
				"exchange_fee": "0.02",
				"sec_fee":     "0.01",
				"finra_fee":   "0.003",
				"total":       "1.023",
			},
			"created_at": now.Add(-30 * time.Minute).Format(time.RFC3339Nano),
			"updated_at": now.Add(-30 * time.Minute).Format(time.RFC3339Nano),
		},
	}
}

var mockPositions = []map[string]interface{}{
	{
		"symbol":              "AAPL",
		"company_name":        "Apple Inc.",
		"market":              "US",
		"sector":              "Technology",
		"quantity":            100,
		"settled_qty":         100,
		"unsettled_qty":       0,
		"settlement_date":     nil,
		"avg_cost":            "150.2500",
		"cost_basis":          "15025.00",
		"current_price":       "175.5000",
		"market_value":        "17550.00",
		"unrealized_pnl":      "2525.00",
		"unrealized_pnl_pct":  "16.81",
		"today_pnl":           "230.00",
		"today_pnl_pct":       "1.33",
		"realized_pnl":        "250.00",
		"wash_sale_status":    "clean",
		"pending_settlements": []interface{}{},
		"recent_trades": []map[string]interface{}{
			{
				"trade_id":    "trd-aapl-001",
				"side":        "BUY",
				"quantity":    100,
				"price":       "150.2500",
				"amount":      "15025.00",
				"fee":         "1.00",
				"executed_at": time.Now().UTC().Add(-7 * 24 * time.Hour).Format(time.RFC3339Nano),
				"wash_sale":   false,
			},
		},
		"updated_at": time.Now().UTC().Format(time.RFC3339Nano),
	},
	{
		"symbol":              "0700",
		"company_name":        "Tencent Holdings",
		"market":              "HK",
		"sector":              "Communication Services",
		"quantity":            200,
		"settled_qty":         200,
		"unsettled_qty":       0,
		"settlement_date":     nil,
		"avg_cost":            "350.000",
		"cost_basis":          "70000.00",
		"current_price":       "368.500",
		"market_value":        "73700.00",
		"unrealized_pnl":      "3700.00",
		"unrealized_pnl_pct":  "5.29",
		"today_pnl":           "840.00",
		"today_pnl_pct":       "1.15",
		"realized_pnl":        "0.00",
		"wash_sale_status":    "clean",
		"pending_settlements": []interface{}{},
		"recent_trades": []map[string]interface{}{
			{
				"trade_id":    "trd-0700-001",
				"side":        "BUY",
				"quantity":    200,
				"price":       "350.000",
				"amount":      "70000.00",
				"fee":         "2.00",
				"executed_at": time.Now().UTC().Add(-14 * 24 * time.Hour).Format(time.RFC3339Nano),
				"wash_sale":   false,
			},
		},
		"updated_at": time.Now().UTC().Format(time.RFC3339Nano),
	},
}

var mockPortfolio = map[string]interface{}{
	"total_equity":              "96282.20",
	"total_market_value":        "91250.00",
	"cash_balance":              "5032.20",
	"unsettled_cash":            "0.00",
	"day_pnl":                   "1070.00",
	"day_pnl_pct":               "1.12",
	"cumulative_unrealized_pnl": "6225.00",
	"cumulative_realized_pnl":   "1200.50",
	"cumulative_pnl":            "7425.50",
	"cumulative_pnl_pct":        "8.35",
	"buying_power":              "10064.40",
	"margin_requirement":        "0.00",
}

// ─── S-01: Session Key ────────────────────────────────────────────────────────

func handleSessionKey(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if currentStrategy.Name() == "error" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "INVALID_TOKEN",
			"message":    "认证失败，请重新登录",
		})
		return
	}

	keyID := "sk-" + generateHex(8)
	secret := generateHex(32)
	expiresAt := time.Now().UTC().Add(30 * time.Minute)

	sessionMu.Lock()
	sessionKeys[keyID] = &SessionKeyEntry{
		KeyID:     keyID,
		Secret:    secret,
		ExpiresAt: expiresAt,
	}
	sessionMu.Unlock()

	fmt.Printf("🔑 Session key issued: %s (expires %s)\n", keyID, expiresAt.Format(time.RFC3339))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"key_id":     keyID,
		"hmac_secret": secret,
		"expires_at": expiresAt.Format(time.RFC3339),
	})
}

// ─── S-02: Nonce ──────────────────────────────────────────────────────────────

func handleTradingNonce(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	nonce := "n-" + generateHex(16)
	expiresAt := time.Now().UTC().Add(60 * time.Second)

	fmt.Printf("🎲 Nonce issued: %s\n", nonce)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"nonce":      nonce,
		"expires_at": expiresAt.Format(time.RFC3339),
	})
}

// consumeNonce marks a nonce as used. Returns false if already consumed.
func consumeNonce(nonce string) bool {
	nonceMu.Lock()
	defer nonceMu.Unlock()
	if _, used := usedNonces[nonce]; used {
		return false
	}
	usedNonces[nonce] = time.Now()
	return true
}

// ─── S-03: Bio Challenge ──────────────────────────────────────────────────────

func handleBioChallenge(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	challenge := generateHex(32)
	expiresAt := time.Now().UTC().Add(30 * time.Second)

	fmt.Printf("🧬 Bio challenge issued: %s...\n", challenge[:16])

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"challenge":  challenge,
		"expires_at": expiresAt.Format(time.RFC3339),
	})
}

// ─── Orders ───────────────────────────────────────────────────────────────────

func handleOrders(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodPost:
		handleSubmitOrder(w, r)
	case http.MethodGet:
		handleGetOrders(w, r)
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleSubmitOrder(w http.ResponseWriter, r *http.Request) {
	// Validate required security headers (bio headers only required when X-Biometric-Token is present)
	required := []string{"X-Key-Id", "X-Nonce", "X-Signature", "Idempotency-Key"}
	for _, h := range required {
		if r.Header.Get(h) == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code": "MISSING_HEADER",
				"message":    fmt.Sprintf("缺少必要请求头: %s", h),
			})
			return
		}
	}
	// Bio headers required only when biometric flow is used
	if r.Header.Get("X-Biometric-Token") != "" {
		bioRequired := []string{"X-Bio-Challenge", "X-Bio-Timestamp"}
		for _, h := range bioRequired {
			if r.Header.Get(h) == "" {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusBadRequest)
				json.NewEncoder(w).Encode(map[string]interface{}{
					"error_code": "MISSING_HEADER",
					"message":    fmt.Sprintf("缺少必要请求头: %s", h),
				})
				return
			}
		}
	}

	// Nonce one-time check
	nonce := r.Header.Get("X-Nonce")
	if !consumeNonce(nonce) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "NONCE_ALREADY_USED",
			"message":    "Nonce 已被使用，请重新获取",
		})
		return
	}

	if currentStrategy.Name() == "error" {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusServiceUnavailable)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error_code": "EXCHANGE_UNAVAILABLE",
			"message":    "交易所连接中断，请稍后重试",
		})
		return
	}

	var body SubmitOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	now := time.Now().UTC()
	orderID := "ord-" + generateHex(6)
	order := map[string]interface{}{
		"order_id":       orderID,
		"symbol":         body.Symbol,
		"market":         body.Market,
		"side":           body.Side,
		"order_type":     body.OrderType,
		"status":         "PENDING",
		"display_status": "待成交",
		"qty":            body.Qty,
		"filled_qty":     0,
		"limit_price":    body.LimitPrice,
		"avg_fill_price": nil,
		"validity":       body.Validity,
		"extended_hours": body.ExtendedHours,
		"fees": map[string]interface{}{
			"commission":   "0.99",
			"exchange_fee": "0.02",
			"sec_fee":      "0.01",
			"finra_fee":    "0.003",
			"total":        "1.023",
		},
		"created_at": now.Format(time.RFC3339Nano),
		"updated_at": now.Format(time.RFC3339Nano),
	}

	ordersMu.Lock()
	tradingOrders = append(tradingOrders, order)
	ordersMu.Unlock()

	fmt.Printf("📋 Order submitted: %s %s %d %s\n", orderID, body.Side, body.Qty, body.Symbol)

	// Market orders: auto-transition PENDING → FILLED after short delay.
	// Limit orders stay PENDING until externally cancelled or (in a future
	// iteration) matched against limit price.
	if strings.EqualFold(body.OrderType, "market") {
		go autoFillMarketOrder(orderID, body.Symbol, body.Qty)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(order)
}

// autoFillMarketOrder simulates exchange execution for market orders.
// Runs in its own goroutine; uses the symbol's current quote (falls back
// to "100.00") as the average fill price.
func autoFillMarketOrder(orderID, symbol string, qty int) {
	time.Sleep(2 * time.Second)

	fillPrice := "100.00"
	if base, ok := baseQuotes[symbol]; ok {
		if p, ok := base["price"].(string); ok && p != "" {
			fillPrice = p
		}
	}

	now := time.Now().UTC().Format(time.RFC3339Nano)

	ordersMu.Lock()
	for i, o := range tradingOrders {
		if o["order_id"] != orderID {
			continue
		}
		// Skip if already transitioned (e.g., cancelled before fill).
		if o["status"] != "PENDING" {
			ordersMu.Unlock()
			return
		}
		tradingOrders[i]["status"] = "FILLED"
		tradingOrders[i]["display_status"] = "已成交"
		tradingOrders[i]["filled_qty"] = qty
		tradingOrders[i]["avg_fill_price"] = fillPrice
		tradingOrders[i]["updated_at"] = now
		break
	}
	ordersMu.Unlock()

	fmt.Printf("✅ Market order auto-filled: %s @ %s\n", orderID, fillPrice)
}

func handleGetOrders(w http.ResponseWriter, r *http.Request) {
	statusFilter := r.URL.Query().Get("status")
	marketFilter := r.URL.Query().Get("market")

	ordersMu.RLock()
	result := make([]map[string]interface{}, 0)
	for _, o := range tradingOrders {
		if statusFilter != "" && o["status"] != statusFilter {
			continue
		}
		if marketFilter != "" && o["market"] != marketFilter {
			continue
		}
		result = append(result, o)
	}
	ordersMu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"orders": result})
}

func handleOrderByID(w http.ResponseWriter, r *http.Request) {
	// Path: /api/v1/orders/{id}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/v1/orders/"), "/")
	orderID := parts[0]

	switch r.Method {
	case http.MethodGet:
		ordersMu.RLock()
		var found map[string]interface{}
		for _, o := range tradingOrders {
			if o["order_id"] == orderID {
				found = o
				break
			}
		}
		ordersMu.RUnlock()

		if found == nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code": "ORDER_NOT_FOUND",
				"message":    "订单不存在",
			})
			return
		}

		fills := []map[string]interface{}{}
		if found["status"] == "FILLED" {
			fillPrice := found["avg_fill_price"]
			if fillPrice == nil {
				fillPrice = found["limit_price"]
			}
			fills = append(fills, map[string]interface{}{
				"fill_id":   "fill-" + generateHex(4),
				"order_id":  orderID,
				"qty":       found["qty"],
				"price":     fillPrice,
				"exchange":  "NASDAQ",
				"filled_at": found["updated_at"],
			})
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"order": found,
			"fills": fills,
		})

	case http.MethodDelete:
		// Validate nonce for cancel
		nonce := r.Header.Get("X-Nonce")
		if nonce == "" {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code": "MISSING_HEADER",
				"message":    "缺少必要请求头: X-Nonce",
			})
			return
		}
		if !consumeNonce(nonce) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code": "NONCE_ALREADY_USED",
				"message":    "Nonce 已被使用，请重新获取",
			})
			return
		}

		ordersMu.Lock()
		found := false
		for i, o := range tradingOrders {
			if o["order_id"] == orderID {
				if o["status"] != "PENDING" && o["status"] != "OPEN" {
					ordersMu.Unlock()
					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusUnprocessableEntity)
					json.NewEncoder(w).Encode(map[string]interface{}{
						"error_code": "ORDER_NOT_CANCELLABLE",
						"message":    "订单状态不可撤销",
					})
					return
				}
				tradingOrders[i]["status"] = "CANCELLED"
				tradingOrders[i]["display_status"] = "已撤销"
				tradingOrders[i]["updated_at"] = time.Now().UTC().Format(time.RFC3339Nano)
				found = true
				break
			}
		}
		ordersMu.Unlock()

		if !found {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusNotFound)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error_code": "ORDER_NOT_FOUND",
				"message":    "订单不存在",
			})
			return
		}

		fmt.Printf("🗑️  Order cancelled: %s\n", orderID)
		w.WriteHeader(http.StatusAccepted)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// ─── Positions ────────────────────────────────────────────────────────────────

func handlePositions(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"positions": mockPositions})
}

func handlePositionBySymbol(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	symbol := strings.TrimPrefix(r.URL.Path, "/api/v1/positions/")
	for _, p := range mockPositions {
		if p["symbol"] == symbol {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(p)
			return
		}
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNotFound)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"error_code": "POSITION_NOT_FOUND",
		"message":    "持仓不存在",
	})
}

// ─── Portfolio ────────────────────────────────────────────────────────────────

func handlePortfolioSummary(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	result := make(map[string]interface{})
	for k, v := range mockPortfolio {
		result[k] = v
	}
	result["updated_at"] = time.Now().UTC().Format(time.RFC3339Nano)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

// ─── Trading WebSocket ────────────────────────────────────────────────────────

var tradingUpgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func handleTradingWS(w http.ResponseWriter, r *http.Request) {
	conn, err := tradingUpgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Printf("TradingWS upgrade error: %v\n", err)
		return
	}
	defer conn.Close()

	fmt.Printf("📡 TradingWS: client connected %s\n", conn.RemoteAddr())

	// Wait for auth message within 10s
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))
	_, msgBytes, err := conn.ReadMessage()
	if err != nil {
		fmt.Printf("TradingWS: auth timeout or error: %v\n", err)
		conn.WriteJSON(map[string]interface{}{"type": "auth.error", "code": "AUTH_TIMEOUT"})
		return
	}
	conn.SetReadDeadline(time.Time{}) // clear deadline

	var authMsg map[string]interface{}
	if err := json.Unmarshal(msgBytes, &authMsg); err != nil || authMsg["type"] != "auth" {
		conn.WriteJSON(map[string]interface{}{"type": "auth.error", "code": "INVALID_MESSAGE"})
		return
	}

	token, _ := authMsg["token"].(string)
	if token == "" {
		conn.WriteJSON(map[string]interface{}{"type": "auth.error", "code": "MISSING_TOKEN"})
		return
	}

	if currentStrategy.Name() == "error" {
		conn.WriteJSON(map[string]interface{}{"type": "auth.error", "code": "INVALID_TOKEN"})
		return
	}

	conn.WriteJSON(map[string]interface{}{"type": "auth.ok", "expires_in": 840})
	fmt.Printf("✅ TradingWS: authenticated (token prefix: %s...)\n", token[:min(8, len(token))])

	// Push periodic updates
	ticker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()

	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()

	for {
		select {
		case <-done:
			fmt.Printf("📡 TradingWS: client disconnected\n")
			return
		case <-ticker.C:
			now := time.Now().UTC()
			// Push portfolio summary
			portfolio := make(map[string]interface{})
			for k, v := range mockPortfolio {
				portfolio[k] = v
			}
			portfolio["updated_at"] = now.Format(time.RFC3339Nano)
			conn.WriteJSON(map[string]interface{}{
				"channel": "portfolio.summary",
				"data":    portfolio,
			})
		}
	}
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

func generateHex(n int) string {
	b := make([]byte, n)
	rand.Read(b)
	return fmt.Sprintf("%x", b)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
