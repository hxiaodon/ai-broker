package ws

import (
	"context"

	"github.com/brokerage/services/market-data/internal/model"
)

// SubscriptionType 订阅类型
type SubscriptionType int

const (
	SubTypeQuote SubscriptionType = iota + 1
	SubTypeDepth
	SubTypeTrade
	SubTypeKline
)

// Subscription 订阅请求
type Subscription struct {
	Symbols  []string           `json:"symbols"`
	Type     SubscriptionType   `json:"type"`
	Interval model.KlineInterval `json:"interval,omitempty"` // 仅K线订阅时使用
}

// Gateway WebSocket 网关接口
type Gateway interface {
	// Start 启动 WebSocket 服务
	Start(ctx context.Context, addr string) error

	// Stop 停止服务
	Stop() error

	// BroadcastQuote 广播行情给订阅者
	BroadcastQuote(quote *model.Quote)

	// BroadcastDepth 广播深度行情
	BroadcastDepth(depth *model.Depth)

	// BroadcastTrade 广播逐笔成交
	BroadcastTrade(trade *model.Trade)

	// BroadcastKline 广播K线
	BroadcastKline(kline *model.Kline)

	// Stats 返回网关统计信息
	Stats() GatewayStats
}

// GatewayStats 网关统计
type GatewayStats struct {
	ActiveConnections  int64 `json:"active_connections"`
	TotalSubscriptions int64 `json:"total_subscriptions"`
	MessagesSent       int64 `json:"messages_sent"`
	MessagesPerSecond  int64 `json:"messages_per_second"`
	SlowConsumers      int64 `json:"slow_consumers"`
}

// ClientMessage 客户端发送的消息
type ClientMessage struct {
	Action string      `json:"action"` // subscribe, unsubscribe, ping
	ReqID  string      `json:"req_id"`
	Data   interface{} `json:"data"`
}

// ServerMessage 服务端推送的消息
type ServerMessage struct {
	Type   string      `json:"type"` // quote, depth, trade, kline, pong, error
	Symbol string      `json:"symbol,omitempty"`
	Data   interface{} `json:"data"`
}
