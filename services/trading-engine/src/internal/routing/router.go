package routing

import (
	"context"

	"github.com/shopspring/decimal"

	"github.com/brokerage/services/trading-engine/internal/order"
)

// Decision 路由决策
type Decision struct {
	Venue         string          // 目标交易所 ("NYSE" / "NASDAQ" / "HKEX" / ...)
	Price         decimal.Decimal // 调整后价格 (tick size 对齐)
	Quantity      int64           // 路由数量 (可能拆单)
	EstimatedCost decimal.Decimal // 预计总成本
	Reason        string          // 路由原因 (审计用)
}

// Router 智能订单路由接口
type Router interface {
	// Route 确定最佳执行场所
	Route(ctx context.Context, ord *order.Order) (*Decision, error)
}

// VenueQuote 交易所报价
type VenueQuote struct {
	Venue     string
	BidPrice  decimal.Decimal
	BidSize   int64
	AskPrice  decimal.Decimal
	AskSize   int64
	Depth     int64 // 总深度
}

// VenueConfig 交易所配置
type VenueConfig struct {
	Name       string
	Enabled    bool
	FeePerShare decimal.Decimal
	RebatePerShare decimal.Decimal // 做市商返佣
	AvgLatencyMs   int
}
