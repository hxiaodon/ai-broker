package fix

import (
	"context"

	"github.com/brokerage/services/trading-engine/internal/order"
)

// SessionStatus FIX 会话状态
type SessionStatus int

const (
	SessionDisconnected SessionStatus = 0
	SessionConnecting   SessionStatus = 1
	SessionLoggedOn     SessionStatus = 2
	SessionLoggedOut    SessionStatus = 3
)

// Engine FIX 协议引擎接口
type Engine interface {
	// SendNewOrder 发送新订单 (MsgType=D)
	SendNewOrder(ctx context.Context, ord *order.Order) error

	// SendCancelOrder 发送取消请求 (MsgType=F)
	SendCancelOrder(ctx context.Context, orderID, origClOrdID string) error

	// SendAmendOrder 发送改单请求 (MsgType=G)
	SendAmendOrder(ctx context.Context, ord *order.Order, origClOrdID string) error

	// OnExecutionReport 注册成交回报处理器
	OnExecutionReport(handler func(*order.ExecutionReport))

	// SessionStatus 获取指定交易所的会话状态
	SessionStatus(venue string) SessionStatus

	// Close 关闭所有 FIX 会话
	Close() error
}

// SessionConfig FIX 会话配置
type SessionConfig struct {
	Venue          string // "NYSE" / "NASDAQ" / "HKEX"
	SenderCompID   string
	TargetCompID   string
	Host           string
	Port           int
	HeartbeatInt   int    // 心跳间隔 (秒)
	FIXVersion     string // "FIX.4.2" / "FIX.4.4"
	UseTLS         bool
	LogPath        string // FIX 消息日志路径
	StorePath      string // 序列号持久化路径
}
