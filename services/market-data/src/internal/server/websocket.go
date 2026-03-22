package server

import (
	"context"
	"fmt"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/pkg/observability"
)

// WSServer provides the WebSocket gateway for real-time quote push.
// Transport layer only — aggregates quote data from the quote subdomain.
// Protocol: control frames use JSON text, quote data uses Protobuf binary.
type WSServer struct {
	upgrader websocket.Upgrader
	logger   *zap.Logger
	clients  map[*websocket.Conn]bool
	mu       sync.RWMutex
}

// NewWSServer creates a new WebSocket server.
func NewWSServer(logger *zap.Logger) *WSServer {
	return &WSServer{
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			CheckOrigin: func(r *http.Request) bool {
				// FILL: domain engineer restricts origins for production.
				return true
			},
		},
		logger:  logger,
		clients: make(map[*websocket.Conn]bool),
	}
}

// HandleWebSocket upgrades HTTP connections to WebSocket.
// FILL: domain engineer implements the full auth flow (message-based, not URL param),
// dual-track push (registered/guest), and Protobuf binary framing.
func (ws *WSServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := ws.upgrader.Upgrade(w, r, nil)
	if err != nil {
		ws.logger.Error("websocket upgrade", zap.Error(err))
		return
	}
	defer func() {
		ws.removeClient(conn)
		if closeErr := conn.Close(); closeErr != nil {
			ws.logger.Debug("websocket close", zap.Error(closeErr))
		}
	}()

	ws.addClient(conn)

	// Read loop — handles control messages (auth, subscribe, unsubscribe).
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				ws.logger.Error("websocket read", zap.Error(err))
			}
			break
		}
		// FILL: parse control messages and handle subscriptions.
	}
}

func (ws *WSServer) addClient(conn *websocket.Conn) {
	ws.mu.Lock()
	defer ws.mu.Unlock()
	ws.clients[conn] = true
	observability.ActiveConns.Inc()
}

func (ws *WSServer) removeClient(conn *websocket.Conn) {
	ws.mu.Lock()
	defer ws.mu.Unlock()
	delete(ws.clients, conn)
	observability.ActiveConns.Dec()
}

// BroadcastQuote sends a quote update to all connected clients.
// FILL: domain engineer implements topic-based subscription filtering.
func (ws *WSServer) BroadcastQuote(data []byte) {
	ws.mu.RLock()
	defer ws.mu.RUnlock()
	for conn := range ws.clients {
		if err := conn.WriteMessage(websocket.BinaryMessage, data); err != nil {
			ws.logger.Debug("websocket broadcast", zap.Error(err))
		}
	}
}

// RegisterRoutes registers the WebSocket endpoint on the HTTP mux.
func (ws *WSServer) RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/ws", ws.HandleWebSocket)
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
		if err := srv.Shutdown(context.Background()); err != nil {
			ws.logger.Error("ws server shutdown", zap.Error(err))
		}
	}()

	ws.logger.Info(fmt.Sprintf("websocket server listening on %s", addr))
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return fmt.Errorf("ws server: %w", err)
	}
	return nil
}
