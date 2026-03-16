package websocket

import (
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

// AllowedOrigins 允许的来源列表
var AllowedOrigins = []string{
	"https://app.broker.com",
	"https://www.broker.com",
	"http://localhost:3000",
	"http://localhost:8080",
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		if origin == "" {
			return false
		}

		for _, allowed := range AllowedOrigins {
			if origin == allowed || strings.HasPrefix(origin, allowed) {
				return true
			}
		}

		log.Printf("Rejected WebSocket connection from origin: %s", origin)
		return false
	},
}

// Handler WebSocket 处理器
type Handler struct {
	Hub *Hub
}

// NewHandler 创建 WebSocket 处理器
func NewHandler(hub *Hub) *Handler {
	return &Handler{
		Hub: hub,
	}
}

// ServeWS 处理 WebSocket 连接
func (h *Handler) ServeWS(c *gin.Context) {
	// 升级 HTTP 连接为 WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		return
	}

	// 创建客户端
	client := &Client{
		ID:      uuid.New().String(),
		Conn:    conn,
		Hub:     h.Hub,
		Send:    make(chan []byte, 256),
		Symbols: make(map[string]bool),
	}

	// 注册客户端
	h.Hub.Register <- client

	// 启动读写协程
	go client.WritePump()
	go client.ReadPump()

	// 发送欢迎消息
	h.sendWelcome(client)
}

// sendWelcome 发送欢迎消息
func (h *Handler) sendWelcome(client *Client) {
	welcome := map[string]interface{}{
		"type":    "welcome",
		"message": "Connected to Market Service WebSocket",
		"clientId": client.ID,
		"time":    client.Hub.encodeMessage(&Message{
			Type: "welcome",
			Data: map[string]interface{}{
				"message":  "Connected to Market Service WebSocket",
				"clientId": client.ID,
			},
		}),
	}

	data := h.Hub.encodeMessage(&Message{
		Type: "welcome",
		Data: welcome,
	})

	if data != nil {
		select {
		case client.Send <- data:
		default:
		}
	}
}
