package server

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/observability"
)

// WSServer provides the WebSocket gateway for real-time quote push.
// Spec: websocket-spec.md v2.1
type WSServer struct {
	upgrader  websocket.Upgrader
	logger    *zap.Logger
	clients   map[*wsClient]bool
	mu        sync.RWMutex
	cacheRepo domain.QuoteCacheRepo // used to send initial snapshot on subscribe
}

type wsClient struct {
	conn          *websocket.Conn
	authenticated bool
	userType      string // "registered" or "guest"
	subscriptions map[string]bool
	mu            sync.RWMutex // protects authenticated, userType, subscriptions
	writeMu       sync.Mutex   // serialises all conn.WriteMessage calls (gorilla requirement)
}

// NewWSServer creates a new WebSocket server.
// cacheRepo is used to push initial snapshots on subscribe; may be nil (disables snapshot push).
func NewWSServer(logger *zap.Logger, cacheRepo domain.QuoteCacheRepo) *WSServer {
	return &WSServer{
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				// TODO(Phase-6): restrict origins for production.
				return true
			},
		},
		logger:    logger,
		clients:   make(map[*wsClient]bool),
		cacheRepo: cacheRepo,
	}
}

// controlMessage represents JSON text frame messages (spec §2).
type controlMessage struct {
	Action string   `json:"action,omitempty"` // client → server
	Type   string   `json:"type,omitempty"`   // server → client
	Token  string   `json:"token,omitempty"`
	Symbols []string `json:"symbols,omitempty"`
}

// HandleWebSocket upgrades HTTP connections to WebSocket.
// Spec: websocket-spec.md — message-based auth, subscribe/unsubscribe, ping/pong.
func (ws *WSServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := ws.upgrader.Upgrade(w, r, nil)
	if err != nil {
		ws.logger.Error("websocket upgrade", zap.Error(err))
		return
	}

	client := &wsClient{
		conn:          conn,
		authenticated: false,
		subscriptions: make(map[string]bool),
	}

	ws.addClient(client)
	defer func() {
		ws.removeClient(client)
		_ = conn.Close()
	}()

	// Set 5-second auth deadline (spec: must auth within 5s).
	authDeadline := time.NewTimer(5 * time.Second)
	defer authDeadline.Stop()

	// readLoop signals auth result then continues processing messages until disconnect.
	authChan := make(chan bool, 1)
	done := make(chan struct{})
	go func() {
		defer close(done)
		ws.readLoop(client, authChan)
	}()

	select {
	case <-authDeadline.C:
		if !client.authenticated {
			ws.logger.Warn("client failed to authenticate within 5s")
			_ = conn.WriteControl(websocket.CloseMessage,
				websocket.FormatCloseMessage(4001, "auth timeout"), time.Now().Add(time.Second))
			// Wait for readLoop to exit before returning (ensures clean defer).
			<-done
			return
		}
	case authed := <-authChan:
		if !authed {
			_ = conn.WriteControl(websocket.CloseMessage,
				websocket.FormatCloseMessage(4002, "auth failed"), time.Now().Add(time.Second))
			<-done
			return
		}
	}

	// Keep connection alive until readLoop exits (client disconnects or read error).
	<-done
}

func (ws *WSServer) readLoop(client *wsClient, authChan chan bool) {
	for {
		_, message, err := client.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				ws.logger.Error("websocket read", zap.Error(err))
			}
			return
		}

		var msg controlMessage
		if err := json.Unmarshal(message, &msg); err != nil {
			ws.sendError(client, "INVALID_MESSAGE", "消息格式错误")
			continue
		}

		ws.handleControlMessage(client, &msg, authChan)
	}
}

func (ws *WSServer) handleControlMessage(client *wsClient, msg *controlMessage, authChan chan bool) {
	switch msg.Action {
	case "auth":
		ws.handleAuth(client, msg, authChan)
	case "subscribe":
		ws.handleSubscribe(client, msg)
	case "unsubscribe":
		ws.handleUnsubscribe(client, msg)
	case "ping":
		ws.handlePing(client)
	case "reauth":
		ws.handleReauth(client, msg)
	default:
		ws.sendError(client, "UNKNOWN_ACTION", "未知的 action: "+msg.Action)
	}
}

func (ws *WSServer) handleAuth(client *wsClient, msg *controlMessage, authChan chan bool) {
	userType := "guest"
	success := true
	expiresIn := 0

	if msg.Token != "" {
		// WARNING: stub — accepts any non-empty token as registered user.
		// TODO(Phase-6): validate RS256 JWT signature using AMS public key — MUST NOT deploy to production with stub.
		userType = "registered"
		expiresIn = 900
	}

	client.mu.Lock()
	client.authenticated = success
	client.userType = userType
	client.mu.Unlock()

	resp := map[string]interface{}{
		"type":             "auth_result",
		"success":          success,
		"user_type":        userType,
		"token_expires_in": expiresIn,
		"client_id":        fmt.Sprintf("client-%d", time.Now().UnixNano()),
	}
	if userType == "guest" {
		resp["token_expires_in"] = nil
	}

	ws.sendJSON(client, resp)
	authChan <- success
}

func (ws *WSServer) handleSubscribe(client *wsClient, msg *controlMessage) {
	if !client.authenticated {
		ws.sendError(client, "AUTH_REQUIRED", "请先完成认证后再订阅")
		return
	}
	if len(msg.Symbols) > 50 {
		ws.sendError(client, "SYMBOL_LIMIT_EXCEEDED", "每次订阅最多50个symbols")
		return
	}

	client.mu.Lock()
	for _, sym := range msg.Symbols {
		client.subscriptions[sym] = true
	}
	client.mu.Unlock()

	ws.sendJSON(client, map[string]interface{}{
		"type":    "subscribe_ack",
		"symbols": msg.Symbols,
	})

	// Push initial snapshot for each subscribed symbol so the client gets
	// the current price immediately without waiting for the next feed update.
	// Spec: websocket-spec.md — server MUST send SNAPSHOT frames after subscribe_ack.
	if ws.cacheRepo != nil && len(msg.Symbols) > 0 {
		go ws.pushInitialSnapshots(client, msg.Symbols)
	}
}

func (ws *WSServer) handleUnsubscribe(client *wsClient, msg *controlMessage) {
	client.mu.Lock()
	for _, sym := range msg.Symbols {
		delete(client.subscriptions, sym)
	}
	client.mu.Unlock()
}

func (ws *WSServer) handlePing(client *wsClient) {
	ws.sendJSON(client, map[string]interface{}{
		"type":      "pong",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

func (ws *WSServer) handleReauth(client *wsClient, msg *controlMessage) {
	// TODO(Phase-6): validate new token and switch user type.
	ws.sendJSON(client, map[string]interface{}{
		"type":             "reauth_result",
		"success":          true,
		"user_type":        "registered",
		"token_expires_in": 900,
	})
}

func (ws *WSServer) sendJSON(client *wsClient, v interface{}) {
	data, _ := json.Marshal(v)
	client.writeMu.Lock()
	_ = client.conn.WriteMessage(websocket.TextMessage, data)
	client.writeMu.Unlock()
}

func (ws *WSServer) sendError(client *wsClient, code, message string) {
	ws.sendJSON(client, map[string]interface{}{
		"type":    "error",
		"code":    code,
		"message": message,
	})
}

func (ws *WSServer) addClient(client *wsClient) {
	ws.mu.Lock()
	defer ws.mu.Unlock()
	ws.clients[client] = true
	observability.ActiveConns.Inc()
}

func (ws *WSServer) removeClient(client *wsClient) {
	ws.mu.Lock()
	defer ws.mu.Unlock()
	delete(ws.clients, client)
	observability.ActiveConns.Dec()
}

// BroadcastQuote sends a quote update to subscribed clients.
// Each client's writeMu serialises concurrent writes from this goroutine and sendJSON.
func (ws *WSServer) BroadcastQuote(symbol string, data []byte) {
	ws.mu.RLock()
	defer ws.mu.RUnlock()
	for client := range ws.clients {
		client.mu.RLock()
		subscribed := client.subscriptions[symbol]
		client.mu.RUnlock()
		if subscribed {
			client.writeMu.Lock()
			_ = client.conn.WriteMessage(websocket.BinaryMessage, data)
			client.writeMu.Unlock()
		}
	}
}

// RegisterRoutes registers the WebSocket endpoint on the HTTP mux.
func (ws *WSServer) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/ws/market", ws.HandleWebSocket)
}

// StartWSServer starts a dedicated HTTP server for WebSocket connections.
func StartWSServer(ctx context.Context, addr string, ws *WSServer) error {
	mux := http.NewServeMux()
	ws.RegisterRoutes(mux)

	srv := &http.Server{
		Addr:    addr,
		Handler: mux,
	}

	go func() {
		<-ctx.Done()
		_ = srv.Shutdown(context.Background())
	}()

	ws.logger.Info(fmt.Sprintf("websocket server listening on %s", addr))
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return fmt.Errorf("ws server: %w", err)
	}
	return nil
}

// WSAddr is the typed address for the WebSocket server (avoids collision with HTTPAddr).
type WSAddr string

// pushInitialSnapshots fetches cached quotes for the given symbols and sends
// each as a SNAPSHOT binary frame to the client.
// Runs in a goroutine to avoid blocking the readLoop.
func (ws *WSServer) pushInitialSnapshots(client *wsClient, symbols []string) {
	// Group symbols by market (infer from symbol format).
	usSymbols := make([]string, 0)
	hkSymbols := make([]string, 0)
	for _, s := range symbols {
		if isHKSymbol(s) {
			hkSymbols = append(hkSymbols, s)
		} else {
			usSymbols = append(usSymbols, s)
		}
	}

	ctx := context.Background()
	for _, batch := range []struct {
		market  domain.Market
		symbols []string
	}{
		{domain.MarketUS, usSymbols},
		{domain.MarketHK, hkSymbols},
	} {
		if len(batch.symbols) == 0 {
			continue
		}
		quotes, err := ws.cacheRepo.MGet(ctx, batch.market, batch.symbols)
		if err != nil {
			ws.logger.Warn("snapshot fetch failed", zap.Error(err))
			continue
		}
		for _, q := range quotes {
			payload, err := json.Marshal(q)
			if err != nil {
				continue
			}
			client.writeMu.Lock()
			_ = client.conn.WriteMessage(websocket.BinaryMessage, payload)
			client.writeMu.Unlock()
		}
	}
}

// isHKSymbol returns true when the symbol looks like a HK stock code (4–5 digits).
func isHKSymbol(symbol string) bool {
	if len(symbol) < 4 {
		return false
	}
	for _, c := range symbol {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}
