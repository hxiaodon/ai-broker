package model

import (
	"time"

	"github.com/shopspring/decimal"
)

// Market 市场标识
type Market string

const (
	MarketUS Market = "US"
	MarketHK Market = "HK"
)

// DataType 行情数据类型
type DataType int

const (
	DataTypeQuote DataType = iota + 1
	DataTypeTrade
	DataTypeDepth
	DataTypeKline
)

// TradingStatus 交易状态
type TradingStatus int

const (
	StatusUnknown    TradingStatus = 0
	StatusPreMarket  TradingStatus = 1
	StatusTrading    TradingStatus = 2
	StatusLunchBreak TradingStatus = 3
	StatusPostMarket TradingStatus = 4
	StatusClosed     TradingStatus = 5
	StatusHalted     TradingStatus = 6
	StatusSuspended  TradingStatus = 7
)

// KlineInterval K线周期
type KlineInterval int

const (
	Interval1m  KlineInterval = 1
	Interval5m  KlineInterval = 2
	Interval15m KlineInterval = 3
	Interval30m KlineInterval = 4
	Interval1h  KlineInterval = 5
	Interval1d  KlineInterval = 6
	Interval1w  KlineInterval = 7
	Interval1mo KlineInterval = 8
)

// TradeSide 成交方向
type TradeSide int

const (
	SideUnknown TradeSide = 0
	SideBuy     TradeSide = 1
	SideSell    TradeSide = 2
)

// Quote Level 1 行情快照
type Quote struct {
	Symbol   string          `json:"symbol"`
	Market   Market          `json:"market"`
	Currency string          `json:"currency"`

	// 最新成交
	LastPrice  decimal.Decimal `json:"last_price"`
	LastVolume int64           `json:"last_volume"`
	Timestamp  time.Time       `json:"timestamp"`

	// 买卖盘
	BidPrice decimal.Decimal `json:"bid_price"`
	BidSize  int64           `json:"bid_size"`
	AskPrice decimal.Decimal `json:"ask_price"`
	AskSize  int64           `json:"ask_size"`

	// 日内统计
	Open      decimal.Decimal `json:"open"`
	High      decimal.Decimal `json:"high"`
	Low       decimal.Decimal `json:"low"`
	PrevClose decimal.Decimal `json:"prev_close"`
	Volume    int64           `json:"volume"`
	Turnover  decimal.Decimal `json:"turnover"`

	// 涨跌
	Change    decimal.Decimal `json:"change"`
	ChangePct decimal.Decimal `json:"change_pct"`

	// 状态
	Status  TradingStatus `json:"status"`
	Session MarketSession `json:"session"`
}

// MarketSession 交易时段
type MarketSession int

const (
	SessionUnknown  MarketSession = 0
	SessionRegular  MarketSession = 1
	SessionPre      MarketSession = 2
	SessionPost     MarketSession = 3
	SessionExtended MarketSession = 4
)

// Depth Level 2 深度行情
type Depth struct {
	Symbol    string       `json:"symbol"`
	Market    Market       `json:"market"`
	Timestamp time.Time    `json:"timestamp"`
	Bids      []PriceLevel `json:"bids"`
	Asks      []PriceLevel `json:"asks"`
}

// PriceLevel 价格档位
type PriceLevel struct {
	Price      decimal.Decimal `json:"price"`
	Volume     int64           `json:"volume"`
	OrderCount int32           `json:"order_count"`
}

// Trade 逐笔成交
type Trade struct {
	Symbol    string          `json:"symbol"`
	Market    Market          `json:"market"`
	Price     decimal.Decimal `json:"price"`
	Volume    int64           `json:"volume"`
	Timestamp time.Time       `json:"timestamp"`
	TradeID   string          `json:"trade_id"`
	Side      TradeSide       `json:"side"`
}

// Kline K线
type Kline struct {
	Symbol     string          `json:"symbol"`
	Market     Market          `json:"market"`
	Open       decimal.Decimal `json:"open"`
	High       decimal.Decimal `json:"high"`
	Low        decimal.Decimal `json:"low"`
	Close      decimal.Decimal `json:"close"`
	Volume     int64           `json:"volume"`
	Turnover   decimal.Decimal `json:"turnover"`
	Timestamp  time.Time       `json:"timestamp"`
	Interval   KlineInterval   `json:"interval"`
	TradeCount int32           `json:"trade_count"`
}

// RawMessage Feed Handler 产出的原始消息
type RawMessage struct {
	Source    string    // 数据源标识
	Market   Market    // 市场
	Symbol   string    // 标的代码
	Type     DataType  // 数据类型
	Sequence uint64    // 序列号
	RecvTime time.Time // 接收时间
	Payload  []byte    // 原始数据
}

// HealthStatus 健康状态
type HealthStatus struct {
	Connected    bool      `json:"connected"`
	LastMsgTime  time.Time `json:"last_msg_time"`
	MsgCount     int64     `json:"msg_count"`
	ErrorCount   int64     `json:"error_count"`
	Latency      time.Duration `json:"latency"`
}
