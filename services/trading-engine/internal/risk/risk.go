package risk

import (
	"context"
	"fmt"

	"github.com/shopspring/decimal"

	"github.com/brokerage/services/trading-engine/internal/order"
)

// Result 风控结果
type Result struct {
	Approved bool
	Reason   string   // 拒绝原因
	Warnings []string // 警告信息（通过但需提示）
}

// Approve 通过
func Approve() *Result {
	return &Result{Approved: true}
}

// ApproveWithWarning 通过但有警告
func ApproveWithWarning(warning string) *Result {
	return &Result{Approved: true, Warnings: []string{warning}}
}

// Reject 拒绝
func Reject(format string, args ...interface{}) *Result {
	return &Result{Approved: false, Reason: fmt.Sprintf(format, args...)}
}

// Check 单项风控检查接口
type Check interface {
	// Name 检查名称 (用于日志和监控)
	Name() string

	// Execute 执行检查
	Execute(ctx context.Context, ord *order.Order, account *Account) *Result
}

// Account 风控所需的账户信息
type Account struct {
	ID          int64
	UserID      int64
	Type        string          // "CASH" / "MARGIN"
	Status      string          // "ACTIVE" / "FROZEN"
	KYCVerified bool
	Equity      decimal.Decimal // 账户净值

	Permissions AccountPermissions
	TaxWithholdingRate decimal.Decimal
}

// AccountPermissions 交易权限
type AccountPermissions struct {
	USTrading      bool
	HKTrading      bool
	OptionsTrading bool
	MarginTrading  bool
	ShortSelling   bool
}

// Engine 风控引擎
// 按顺序执行所有检查，任一失败则终止
type Engine interface {
	// CheckOrder 对订单执行完整风控检查
	CheckOrder(ctx context.Context, ord *order.Order) (*Result, error)

	// RegisterCheck 注册风控检查项
	RegisterCheck(check Check)
}

// BuyingPower 购买力信息
type BuyingPower struct {
	CashAvailable     decimal.Decimal // 可用现金
	UnsettledProceeds decimal.Decimal // 未结算的卖出收入
	PendingBuyOrders  decimal.Decimal // 未成交买单冻结金额
	MarginAvailable   decimal.Decimal // 可用保证金 (仅保证金账户)
	BuyingPower       decimal.Decimal // 最终购买力
}

// BuyingPowerService 购买力计算服务
type BuyingPowerService interface {
	// Calculate 计算账户购买力
	Calculate(ctx context.Context, accountID int64) (*BuyingPower, error)

	// EstimateOrderCost 预估订单成本 (含手续费)
	EstimateOrderCost(ctx context.Context, ord *order.Order) (decimal.Decimal, error)
}

// PDTService PDT 规则检查服务
type PDTService interface {
	// CountDayTrades 统计过去 N 个工作日的日内交易次数
	CountDayTrades(ctx context.Context, accountID int64, businessDays int) (int, error)

	// WouldCreateDayTrade 判断本次交易是否构成新的日内交易
	WouldCreateDayTrade(ctx context.Context, ord *order.Order) (bool, error)
}
