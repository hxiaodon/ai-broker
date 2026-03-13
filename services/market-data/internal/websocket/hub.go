package websocket

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	pb "github.com/brokerage/market-service/proto"
	"github.com/gorilla/websocket"
	"github.com/shopspring/decimal"
	"google.golang.org/protobuf/proto"
)

// Client WebSocket 客户端
type Client struct {
	ID          string
	Conn        *websocket.Conn
	Hub         *Hub
	Send        chan []byte
	Symbols     map[string]bool // 订阅的股票代码
	SymbolsLock sync.RWMutex
}

// Hub WebSocket 连接管理中心
type Hub struct {
	Clients    map[*Client]bool
	Broadcast  chan *Message
	Register   chan *Client
	Unregister chan *Client
	Lock       sync.RWMutex
}

// Message WebSocket 消息
type Message struct {
	Type    string      `json:"type"`    // quote/kline/news/heartbeat
	Symbol  string      `json:"symbol"`  // 股票代码
	Data    interface{} `json:"data"`    // 消息数据
	Time    int64       `json:"time"`    // 时间戳
}

// QuoteData 实时行情数据
type QuoteData struct {
	Symbol        string          `json:"symbol"`
	Price         decimal.Decimal `json:"price"`
	Change        decimal.Decimal `json:"change"`
	ChangePercent decimal.Decimal `json:"changePercent"`
	Volume        int64           `json:"volume"`
	Timestamp     int64           `json:"timestamp"`
}

// NewHub 创建 Hub
func NewHub() *Hub {
	return &Hub{
		Clients:    make(map[*Client]bool),
		Broadcast:  make(chan *Message, 256),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
	}
}

// Run 运行 Hub
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.Lock.Lock()
			h.Clients[client] = true
			h.Lock.Unlock()
			log.Printf("Client registered: %s, total clients: %d", client.ID, len(h.Clients))

		case client := <-h.Unregister:
			h.Lock.Lock()
			if _, ok := h.Clients[client]; ok {
				delete(h.Clients, client)
				close(client.Send)
				log.Printf("Client unregistered: %s, total clients: %d", client.ID, len(h.Clients))
			}
			h.Lock.Unlock()

		case message := <-h.Broadcast:
			h.Lock.RLock()
			for client := range h.Clients {
				// 检查客户端是否订阅了该股票
				if message.Symbol != "" {
					client.SymbolsLock.RLock()
					subscribed := client.Symbols[message.Symbol]
					client.SymbolsLock.RUnlock()

					if !subscribed {
						continue
					}
				}

				select {
				case client.Send <- h.encodeMessage(message):
				default:
					// 发送失败，关闭客户端
					close(client.Send)
					delete(h.Clients, client)
				}
			}
			h.Lock.RUnlock()
		}
	}
}

// encodeMessage 编码消息为 Protobuf
func (h *Hub) encodeMessage(msg *Message) []byte {
	// 转换为 Protobuf Quote
	quoteData, ok := msg.Data.(*QuoteData)
	if !ok {
		log.Printf("Invalid message data type")
		return nil
	}

	pbQuote := &pb.Quote{
		Symbol:        quoteData.Symbol,
		Price:         quoteData.Price.String(),
		Change:        quoteData.Change.String(),
		ChangePercent: quoteData.ChangePercent.String(),
		Volume:        quoteData.Volume,
		Timestamp:     quoteData.Timestamp,
	}

	data, err := proto.Marshal(pbQuote)
	if err != nil {
		log.Printf("Failed to marshal protobuf: %v", err)
		return nil
	}

	return data
}

// ReadPump 读取客户端消息
func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
			}
			break
		}

		// 处理客户端消息
		c.handleMessage(message)
	}
}

// WritePump 向客户端发送消息
func (c *Client) WritePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				// Hub 关闭了通道
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// 批量发送队列中的消息
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			// 发送心跳
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// handleMessage 处理客户端消息
func (c *Client) handleMessage(message []byte) {
	// 尝试解析为 Protobuf SubscribeRequest
	var subReq pb.SubscribeRequest
	if err := proto.Unmarshal(message, &subReq); err == nil && len(subReq.Symbols) > 0 {
		// Protobuf 订阅请求
		c.SymbolsLock.Lock()
		for _, symbol := range subReq.Symbols {
			c.Symbols[symbol] = true
			log.Printf("Client %s subscribed to %s", c.ID, symbol)
		}
		c.SymbolsLock.Unlock()
		c.sendProtoAck("subscribe", subReq.Symbols)
		return
	}

	// 兼容 JSON 格式
	var msg map[string]interface{}
	if err := json.Unmarshal(message, &msg); err != nil {
		log.Printf("Failed to unmarshal message: %v", err)
		return
	}

	msgType, ok := msg["type"].(string)
	if !ok {
		return
	}

	switch msgType {
	case "subscribe":
		if symbols, ok := msg["symbols"].([]interface{}); ok {
			c.SymbolsLock.Lock()
			for _, s := range symbols {
				if symbol, ok := s.(string); ok {
					c.Symbols[symbol] = true
					log.Printf("Client %s subscribed to %s", c.ID, symbol)
				}
			}
			c.SymbolsLock.Unlock()
			c.sendAck("subscribe", symbols)
		}

	case "unsubscribe":
		if symbols, ok := msg["symbols"].([]interface{}); ok {
			c.SymbolsLock.Lock()
			for _, s := range symbols {
				if symbol, ok := s.(string); ok {
					delete(c.Symbols, symbol)
					log.Printf("Client %s unsubscribed from %s", c.ID, symbol)
				}
			}
			c.SymbolsLock.Unlock()
			c.sendAck("unsubscribe", symbols)
		}

	case "ping":
		c.sendPong()
	}
}

// sendAck 发送确认消息
func (c *Client) sendAck(action string, symbols interface{}) {
	ack := map[string]interface{}{
		"type":    "ack",
		"action":  action,
		"symbols": symbols,
		"time":    time.Now().UnixMilli(),
	}

	data, err := json.Marshal(ack)
	if err != nil {
		return
	}

	select {
	case c.Send <- data:
	default:
	}
}

// sendPong 发送 pong 消息
func (c *Client) sendPong() {
	pong := map[string]interface{}{
		"type": "pong",
		"time": time.Now().UnixMilli(),
	}

	data, err := json.Marshal(pong)
	if err != nil {
		return
	}

	select {
	case c.Send <- data:
	default:
	}
}

// sendProtoAck 发送 Protobuf 确认消息
func (c *Client) sendProtoAck(action string, symbols []string) {
	ack := &pb.SubscribeResponse{
		Action:  action,
		Symbols: symbols,
		Time:    time.Now().UnixMilli(),
	}

	data, err := proto.Marshal(ack)
	if err != nil {
		return
	}

	select {
	case c.Send <- data:
	default:
	}
}

// BroadcastQuote 广播实时行情
func (h *Hub) BroadcastQuote(quote *QuoteData) {
	msg := &Message{
		Type:   "quote",
		Symbol: quote.Symbol,
		Data:   quote,
		Time:   time.Now().UnixMilli(),
	}

	select {
	case h.Broadcast <- msg:
	default:
		log.Printf("Broadcast channel full, dropping message for %s", quote.Symbol)
	}
}
