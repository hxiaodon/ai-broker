package server

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

func TestWebSocket_AuthTimeout(t *testing.T) {
	ws := NewWSServer(zap.NewNop(), nil)

	server := httptest.NewServer(http.HandlerFunc(ws.HandleWebSocket))
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws/market"
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("dial failed: %v", err)
	}
	defer conn.Close()

	conn.SetReadDeadline(time.Now().Add(6 * time.Second))
	_, _, err = conn.ReadMessage()

	if err == nil {
		t.Error("expected connection to close due to auth timeout")
	}
}

func TestWebSocket_SubscribeFiltering(t *testing.T) {
	ws := NewWSServer(zap.NewNop(), nil)

	server := httptest.NewServer(http.HandlerFunc(ws.HandleWebSocket))
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws/market"
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("dial failed: %v", err)
	}
	defer conn.Close()

	authMsg := `{"action":"auth","token":"fake-token"}`
	if err := conn.WriteMessage(websocket.TextMessage, []byte(authMsg)); err != nil {
		t.Fatalf("auth failed: %v", err)
	}

	time.Sleep(100 * time.Millisecond)

	subMsg := `{"action":"subscribe","symbols":["AAPL"]}`
	if err := conn.WriteMessage(websocket.TextMessage, []byte(subMsg)); err != nil {
		t.Fatalf("subscribe failed: %v", err)
	}

	time.Sleep(100 * time.Millisecond)

	ws.BroadcastQuote("AAPL", []byte("test-data"))

	conn.SetReadDeadline(time.Now().Add(1 * time.Second))
	_, msg, err := conn.ReadMessage()
	if err != nil {
		t.Errorf("expected to receive broadcast: %v", err)
	}
	if len(msg) == 0 {
		t.Error("expected non-empty message")
	}
}
