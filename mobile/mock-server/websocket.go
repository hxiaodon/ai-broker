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
		return true
	},
	Subprotocols: []string{"brokerage-market-v1"},
}

type wsFrame struct {
	msgType int
	data    []byte
}

type Client struct {
	conn          *websocket.Conn
	send          chan wsFrame
	subscriptions map[string]bool
	userType      string
	authenticated bool
	mu            sync.RWMutex
}

type WSMessage struct {
	Action  string   `json:"action"`
	Token   string   `json:"token,omitempty"`
	Symbols []string `json:"symbols,omitempty"`
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &Client{
		conn:          conn,
		send:          make(chan wsFrame, 256),
		subscriptions: make(map[string]bool),
	}

	log.Printf("✅ Client connected: %s", conn.RemoteAddr())

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
		case frame, ok := <-c.send:
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			if err := c.conn.WriteMessage(frame.msgType, frame.data); err != nil {
				return
			}

		case <-ticker.C:
			c.sendTickUpdates()
		}
	}
}

func (c *Client) handleMessage(msg WSMessage) {
	switch msg.Action {
	case "auth":
		c.handleAuth(msg.Token)
	case "reauth":
		c.handleReauth(msg.Token)
	case "subscribe":
		if !c.authenticated {
			return
		}
		c.handleSubscribe(msg.Symbols)
	case "unsubscribe":
		if !c.authenticated {
			return
		}
		c.handleUnsubscribe(msg.Symbols)
	case "ping":
		c.sendControl(map[string]interface{}{"type": "pong"})
	default:
		log.Printf("Unknown action: %s", msg.Action)
	}
}

func (c *Client) handleAuth(token string) {
	if currentStrategy.ShouldRejectAuth(token) {
		c.sendControl(map[string]interface{}{
			"type":    "auth_result",
			"success": false,
		})
		time.AfterFunc(100*time.Millisecond, func() {
			c.conn.Close()
		})
		return
	}

	if token == "" || token == "guest" {
		c.userType = "guest"
	} else {
		c.userType = "registered"
	}
	c.authenticated = true

	c.sendControl(map[string]interface{}{
		"type":      "auth_result",
		"success":   true,
		"user_type": c.userType,
	})

	log.Printf("🔐 Auth success: %s (type: %s)", c.conn.RemoteAddr(), c.userType)
}

func (c *Client) handleReauth(token string) {
	if currentStrategy.ShouldRejectAuth(token) {
		c.sendControl(map[string]interface{}{
			"type":    "reauth_result",
			"success": false,
		})
		return
	}

	if token == "" || token == "guest" {
		c.userType = "guest"
	} else {
		c.userType = "registered"
	}

	c.sendControl(map[string]interface{}{
		"type":      "reauth_result",
		"success":   true,
		"user_type": c.userType,
	})

	log.Printf("🔄 Reauth success: %s (type: %s)", c.conn.RemoteAddr(), c.userType)
}

func (c *Client) handleSubscribe(symbols []string) {
	c.mu.Lock()
	for _, s := range symbols {
		c.subscriptions[s] = true
	}
	c.mu.Unlock()

	c.sendControl(map[string]interface{}{
		"type":    "subscribe_ack",
		"symbols": symbols,
	})

	log.Printf("📊 Subscribed: %v", symbols)

	for _, symbol := range symbols {
		quote := generateQuote(symbol, c.userType)
		quoteBuf := encodeQuote(quote, c.userType)
		frame := encodeWsQuoteFrame(frameTypeSnapshot, quoteBuf)
		c.send <- wsFrame{websocket.BinaryMessage, frame}
	}
}

func (c *Client) handleUnsubscribe(symbols []string) {
	c.mu.Lock()
	for _, symbol := range symbols {
		delete(c.subscriptions, symbol)
	}
	c.mu.Unlock()

	log.Printf("🚫 Unsubscribed: %v", symbols)
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

	if currentStrategy.ShouldDisconnect() {
		log.Printf("💥 Strategy triggered disconnect")
		c.conn.Close()
		return
	}

	delay := currentStrategy.GetTickDelay()
	if delay > 0 {
		time.Sleep(delay)
	}

	frameType := frameTypeTick
	if c.userType == "guest" {
		frameType = frameTypeDelayed
	}

	for _, symbol := range symbols {
		quote := generateTickUpdate(symbol, c.userType)
		quoteBuf := encodeQuote(quote, c.userType)
		frame := encodeWsQuoteFrame(frameType, quoteBuf)
		c.send <- wsFrame{websocket.BinaryMessage, frame}
	}
}

func (c *Client) sendControl(data map[string]interface{}) {
	b, _ := json.Marshal(data)
	c.send <- wsFrame{websocket.TextMessage, b}
}
