package settlement

import (
	"context"
	"time"

	"github.com/shopspring/decimal"
)

// Engine 结算引擎接口
type Engine interface {
	// ProcessDaily 每日结算批处理
	ProcessDaily(ctx context.Context, settlementDate time.Time) error

	// GetUnsettledExecutions 获取待结算成交
	GetUnsettledExecutions(ctx context.Context, settlementDate time.Time) ([]*UnsettledExecution, error)

	// ProcessCorporateAction 处理公司行动
	ProcessCorporateAction(ctx context.Context, action *CorporateAction) error
}

// UnsettledExecution 待结算成交
type UnsettledExecution struct {
	ExecutionID    string
	OrderID        string
	AccountID      int64
	Symbol         string
	Market         string
	Side           string
	Quantity       int64
	Price          decimal.Decimal
	NetAmount      decimal.Decimal
	SettlementDate time.Time
}

// CorporateAction 公司行动
type CorporateAction struct {
	Type           ActionType
	Symbol         string
	Market         string
	RecordDate     time.Time
	ExDate         time.Time
	PayDate        time.Time

	// 分红
	DividendPerShare decimal.Decimal
	DividendCurrency string

	// 拆股
	SplitRatio int // e.g., 4 表示 4:1 拆股
}

// ActionType 公司行动类型
type ActionType int

const (
	ActionDividend    ActionType = 1
	ActionStockSplit  ActionType = 2
	ActionReverseSplit ActionType = 3
	ActionMerger      ActionType = 4
	ActionSpinoff     ActionType = 5
	ActionRightsIssue ActionType = 6
)
