package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for testing
	},
}

type Client struct {
	conn          *websocket.Conn
	send          chan []byte
	subscriptions map[string]bool
	userType      string // "registered" or "guest"
	mu            sync.RWMutex
}

type WSMessage struct {
	Action  string   `json:"action"`
	Token   string   `json:"token,omitempty"`
	Symbols []string `json:"symbols,omitempty"`
}

type WSResponse struct {
	Type     string      `json:"type"`
	UserType string      `json:"user_type,omitempty"`
	Message  string      `json:"message,omitempty"`
	Data     interface{} `json:"data,omitempty"`
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &Client{
		conn:          conn,
		send:          make(chan []byte, 256),
		subscriptions: make(map[string]bool),
	}

	log.Printf("✅ Client connected: %s", conn.RemoteAddr())

	// Start goroutines
	go client.writePump()
	go client.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.conn.Close()
		log.Printf("❌ Client disconnected: %s", c.conn.RemoteAddr())
	}()

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket read error: %v", err)
			}
			break
		}

		var msg WSMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("JSON unmarshal error: %v", err)
			continue
		}

		c.handleMessage(msg)
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(1 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := c.conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			// Send tick updates for subscribed symbols
			c.sendTickUpdates()
		}
	}
}

func (c *Client) handleMessage(msg WSMessage) {
	switch msg.Action {
	case "auth":
		c.handleAuth(msg.Token)
	case "subscribe":
		c.handleSubscribe(msg.Symbols)
	case "unsubscribe":
		c.handleUnsubscribe(msg.Symbols)
	default:
		log.Printf("Unknown action: %s", msg.Action)
	}
}

func (c *Client) handleAuth(token string) {
	// Apply strategy
	if shouldRejectAuth := currentStrategy.ShouldRejectAuth(token); shouldRejectAuth {
		c.sendError(4002, "Token 无效或已过期（code 4002）")
		time.AfterFunc(100*time.Millisecond, func() {
			c.conn.Close()
		})
		return
	}

	// Determine user type
	if token == "" || token == "guest" {
		c.userType = "guest"
	} else {
		c.userType = "registered"
	}

	resp := WSResponse{
		Type:     "auth_success",
		UserType: c.userType,
		Message:  "认证成功",
	}

	data, _ := json.Marshal(resp)
	c.send <- data

	log.Printf("🔐 Auth success: %s (type: %s)", c.conn.RemoteAddr(), c.userType)
}

func (c *Client) handleSubscribe(symbols []string) {
	c.mu.Lock()
	for _, symbol := range symbols {
		c.subscriptions[symbol] = true
	}
	c.mu.Unlock()

	log.Printf("📊 Subscribed: %v", symbols)

	// Send initial snapshot
	c.sendSnapshot(symbols)
}

func (c *Client) handleUnsubscribe(symbols []string) {
	c.mu.Lock()
	for _, symbol := range symbols {
		delete(c.subscriptions, symbol)
	}
	c.mu.Unlock()

	log.Printf("🚫 Unsubscribed: %v", symbols)
}

func (c *Client) sendSnapshot(symbols []string) {
	for _, symbol := range symbols {
		quote := generateQuote(symbol, c.userType)
		frame := map[string]interface{}{
			"type":   "snapshot",
			"symbol": symbol,
			"data":   quote,
		}
		data, _ := json.Marshal(frame)
		c.send <- data
	}
}

func (c *Client) sendTickUpdates() {
	c.mu.RLock()
	symbols := make([]string, 0, len(c.subscriptions))
	for symbol := range c.subscriptions {
		symbols = append(symbols, symbol)
	}
	c.mu.RUnlock()

	if len(symbols) == 0 {
		return
	}

	// Apply strategy
	if shouldDisconnect := currentStrategy.ShouldDisconnect(); shouldDisconnect {
		log.Printf("💥 Strategy triggered disconnect")
		c.conn.Close()
		return
	}

	delay := currentStrategy.GetTickDelay()
	if delay > 0 {
		time.Sleep(delay)
	}

	for _, symbol := range symbols {
		quote := generateTickUpdate(symbol, c.userType)
		frame := map[string]interface{}{
			"type":   "tick",
			"symbol": symbol,
			"data":   quote,
		}
		data, _ := json.Marshal(frame)
		c.send <- data
	}
}

func (c *Client) sendError(code int, message string) {
	resp := map[string]interface{}{
		"type":    "error",
		"code":    code,
		"message": message,
	}
	data, _ := json.Marshal(resp)
	c.send <- data
}
