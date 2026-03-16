package order

import (
	"context"
	"fmt"

	"github.com/shopspring/decimal"
)

// Status 订单状态
type Status int

const (
	StatusCreated        Status = 1
	StatusValidated      Status = 2
	StatusRiskApproved   Status = 3
	StatusPending        Status = 4
	StatusOpen           Status = 5
	StatusPartialFill    Status = 6
	StatusFilled         Status = 7
	StatusCancelSent     Status = 8
	StatusCancelled      Status = 9
	StatusRejected       Status = 10
	StatusExchangeReject Status = 11
)

// validTransitions 合法的状态转换定义
var validTransitions = map[Status][]Status{
	StatusCreated:        {StatusValidated, StatusRejected},
	StatusValidated:      {StatusRiskApproved, StatusRejected},
	StatusRiskApproved:   {StatusPending},
	StatusPending:        {StatusOpen, StatusExchangeReject, StatusRejected},
	StatusOpen:           {StatusPartialFill, StatusFilled, StatusCancelSent},
	StatusPartialFill:    {StatusPartialFill, StatusFilled, StatusCancelSent},
	StatusCancelSent:     {StatusCancelled, StatusFilled, StatusPartialFill},
	// 终态: 不允许任何转换
	StatusFilled:         {},
	StatusCancelled:      {},
	StatusRejected:       {},
	StatusExchangeReject: {},
}

// StateMachine 订单状态机
type StateMachine struct{}

// Transition 执行状态转换，不合法则返回 error
func (sm *StateMachine) Transition(current, target Status) error {
	allowed, ok := validTransitions[current]
	if !ok {
		return fmt.Errorf("unknown current status: %d", current)
	}
	for _, s := range allowed {
		if s == target {
			return nil
		}
	}
	return fmt.Errorf("invalid transition: %s -> %s", current, target)
}

// IsTerminal 判断是否为终态
func (sm *StateMachine) IsTerminal(status Status) bool {
	transitions, ok := validTransitions[status]
	return ok && len(transitions) == 0
}

func (s Status) String() string {
	names := map[Status]string{
		StatusCreated:        "CREATED",
		StatusValidated:      "VALIDATED",
		StatusRiskApproved:   "RISK_APPROVED",
		StatusPending:        "PENDING",
		StatusOpen:           "OPEN",
		StatusPartialFill:    "PARTIAL_FILL",
		StatusFilled:         "FILLED",
		StatusCancelSent:     "CANCEL_SENT",
		StatusCancelled:      "CANCELLED",
		StatusRejected:       "REJECTED",
		StatusExchangeReject: "EXCHANGE_REJECT",
	}
	if name, ok := names[s]; ok {
		return name
	}
	return fmt.Sprintf("UNKNOWN(%d)", s)
}

// Side 买卖方向
type Side int

const (
	SideBuy  Side = 1
	SideSell Side = 2
)

// Type 订单类型
type Type int

const (
	TypeMarket       Type = 1
	TypeLimit        Type = 2
	TypeStop         Type = 3
	TypeStopLimit    Type = 4
	TypeTrailingStop Type = 5
	TypeMOO          Type = 6
	TypeMOC          Type = 7
)

// TimeInForce 订单有效期
type TimeInForce int

const (
	TIFDay TimeInForce = 1
	TIFGTC TimeInForce = 2
	TIFIOC TimeInForce = 3
	TIFAON TimeInForce = 4
)

// Order 订单实体
type Order struct {
	OrderID         string
	ClientOrderID   string
	ExchangeOrderID string

	UserID    int64
	AccountID int64

	Symbol   string
	Market   string // "US" / "HK"
	Exchange string // "NYSE" / "NASDAQ" / "HKEX"

	Side        Side
	Type        Type
	TimeInForce TimeInForce

	Quantity     int64
	Price        decimal.Decimal // 限价单价格
	StopPrice    decimal.Decimal // 止损价
	TrailAmount  decimal.Decimal // 追踪止损偏移

	Status       Status
	FilledQty    int64
	AvgFillPrice decimal.Decimal
	RemainingQty int64

	Commission decimal.Decimal
	TotalFees  decimal.Decimal

	Source       string // "IOS" / "ANDROID" / "WEB" / "API"
	IPAddress    string
	DeviceID     string
	RejectReason string

	IdempotencyKey string

	CreatedAt   int64 // Unix nanos
	SubmittedAt int64
	CompletedAt int64
}

// Service 订单服务接口
type Service interface {
	// Submit 提交新订单 (校验 → 风控 → 路由 → 发送)
	Submit(ctx context.Context, req *SubmitRequest) (*SubmitResponse, error)

	// Cancel 取消订单
	Cancel(ctx context.Context, orderID string, accountID int64) error

	// Get 查询订单详情
	Get(ctx context.Context, orderID string) (*Order, error)

	// List 查询订单列表
	List(ctx context.Context, req *ListRequest) (*ListResponse, error)

	// HandleExecutionReport 处理交易所回报
	HandleExecutionReport(ctx context.Context, report *ExecutionReport) error
}

// SubmitRequest 下单请求
type SubmitRequest struct {
	AccountID      int64
	Symbol         string
	Market         string
	Side           Side
	Type           Type
	TimeInForce    TimeInForce
	Quantity       int64
	Price          decimal.Decimal
	StopPrice      decimal.Decimal
	TrailAmount    decimal.Decimal
	IdempotencyKey string
	Source         string
	DeviceID       string
	IPAddress      string
}

// SubmitResponse 下单响应
type SubmitResponse struct {
	OrderID      string
	Status       Status
	RejectReason string
}

// ListRequest 查询请求
type ListRequest struct {
	AccountID    int64
	StatusFilter Status
	MarketFilter string
	SymbolFilter string
	FromTime     int64
	ToTime       int64
	PageSize     int
	PageToken    string
}

// ListResponse 查询响应
type ListResponse struct {
	Orders        []*Order
	NextPageToken string
	TotalCount    int
}

// ExecutionReport 交易所成交回报
type ExecutionReport struct {
	OrderID      string
	ClOrdID      string
	ExecID       string
	ExecType     string // "NEW" / "PARTIAL_FILL" / "FILL" / "CANCELLED" / "REJECTED"
	Symbol       string
	Market       string
	Side         Side
	LastQty      int64
	LastPx       decimal.Decimal
	CumQty       int64
	AvgPx        decimal.Decimal
	LeavesQty    int64
	Commission   decimal.Decimal
	Venue        string
	TransactTime int64 // Unix nanos
	Text         string
}

// Validator 订单校验器接口
type Validator interface {
	Validate(ctx context.Context, order *Order) error
}

// Repository 订单持久化接口
type Repository interface {
	Create(ctx context.Context, order *Order) error
	Update(ctx context.Context, order *Order) error
	GetByID(ctx context.Context, orderID string) (*Order, error)
	GetByClientOrderID(ctx context.Context, clientOrderID string) (*Order, error)
	List(ctx context.Context, req *ListRequest) ([]*Order, int, error)
	GetOpenOrdersByAccount(ctx context.Context, accountID int64) ([]*Order, error)
}
