package position

import (
	"context"

	"github.com/shopspring/decimal"

	"github.com/brokerage/services/trading-engine/internal/order"
)

// Position 持仓
type Position struct {
	UserID       int64
	AccountID    int64
	Symbol       string
	Market       string
	Quantity     int64           // 正=多头, 负=空头
	AvgCostBasis decimal.Decimal
	RealizedPnL  decimal.Decimal
	SettledQty   int64
	UnsettledQty int64
	FirstTradeAt int64 // Unix nanos
	LastTradeAt  int64
	Version      int   // 乐观锁
}

// PnLSnapshot 实时盈亏快照
type PnLSnapshot struct {
	Symbol        string
	Market        string
	Quantity      int64
	AvgCostBasis  decimal.Decimal
	MarketPrice   decimal.Decimal
	MarketValue   decimal.Decimal // Quantity × MarketPrice
	CostValue     decimal.Decimal // Quantity × AvgCostBasis
	UnrealizedPnL decimal.Decimal // MarketValue - CostValue
	UnrealizedPct decimal.Decimal // 百分比
	RealizedPnL   decimal.Decimal
	DayPnL        decimal.Decimal // 基于昨收
}

// PortfolioSummary 组合摘要
type PortfolioSummary struct {
	AccountID        int64
	TotalEquity      decimal.Decimal
	TotalMarketValue decimal.Decimal
	CashBalance      decimal.Decimal
	TotalUnrealized  decimal.Decimal
	TotalRealized    decimal.Decimal
	TotalDayPnL      decimal.Decimal
	BuyingPower      decimal.Decimal
	PositionCount    int
	Positions        []*PnLSnapshot
}

// Engine 持仓引擎接口
type Engine interface {
	// ProcessExecution 处理成交，原子更新持仓+余额+台账
	ProcessExecution(ctx context.Context, exec *order.ExecutionReport) error

	// Get 获取单个持仓
	Get(ctx context.Context, accountID int64, symbol, market string) (*Position, error)

	// ListByAccount 获取账户所有持仓
	ListByAccount(ctx context.Context, accountID int64) ([]*Position, error)

	// GetPnLSnapshot 获取持仓实时盈亏
	GetPnLSnapshot(ctx context.Context, pos *Position) (*PnLSnapshot, error)

	// GetPortfolioSummary 获取组合摘要
	GetPortfolioSummary(ctx context.Context, accountID int64) (*PortfolioSummary, error)
}

// Repository 持仓持久化接口
type Repository interface {
	GetForUpdate(ctx context.Context, accountID int64, symbol, market string) (*Position, error)
	Upsert(ctx context.Context, pos *Position) error
	ListByAccount(ctx context.Context, accountID int64) ([]*Position, error)
	ListBySymbol(ctx context.Context, symbol, market string) ([]*Position, error)
}
