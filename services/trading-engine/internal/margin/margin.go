package margin

import (
	"context"

	"github.com/shopspring/decimal"
)

// Requirement 保证金要求
type Requirement struct {
	AccountID         int64
	TotalEquity       decimal.Decimal // 总净值
	InitialMargin     decimal.Decimal // 初始保证金要求
	MaintenanceMargin decimal.Decimal // 维持保证金要求
	AvailableMargin   decimal.Decimal // 可用保证金
	MarginUsagePct    decimal.Decimal // 使用率 (%)
	MarginCallAmount  decimal.Decimal // Margin Call 金额 (0=无)
}

// Rate 标的保证金比例
type Rate struct {
	Symbol          string
	Market          string
	InitialRate     decimal.Decimal // 初始保证金比例 (e.g., 0.50 = 50%)
	MaintenanceRate decimal.Decimal // 维持保证金比例 (e.g., 0.25 = 25%)
}

// CallStatus Margin Call 状态
type CallStatus int

const (
	CallStatusNone       CallStatus = 0
	CallStatusWarning    CallStatus = 1 // 接近触发线
	CallStatusTriggered  CallStatus = 2 // 已触发，等待补足
	CallStatusLiquidation CallStatus = 3 // 未补足，需要强平
)

// Engine 保证金引擎接口
type Engine interface {
	// Calculate 计算账户当前保证金要求
	Calculate(ctx context.Context, accountID int64) (*Requirement, error)

	// CalculateAfterOrder 计算下单后的保证金影响
	CalculateAfterOrder(ctx context.Context, accountID int64, orderValue decimal.Decimal, market string) (*Requirement, error)

	// CheckMarginCall 检查是否触发 Margin Call
	CheckMarginCall(ctx context.Context, accountID int64) (CallStatus, decimal.Decimal, error)

	// GetRate 获取标的保证金比例
	GetRate(symbol, market string) *Rate
}

// RateService 保证金比例配置服务
type RateService interface {
	Get(symbol, market string) *Rate
	SetCustomRate(symbol, market string, rate *Rate) error
}
