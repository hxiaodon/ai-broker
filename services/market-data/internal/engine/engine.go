package engine

import (
	"context"

	"github.com/brokerage/services/market-data/internal/model"
)

// Aggregator K线聚合引擎接口
type Aggregator interface {
	// Start 启动聚合引擎
	Start(ctx context.Context) error

	// ProcessTrade 接收逐笔成交，实时聚合K线
	ProcessTrade(trade *model.Trade)

	// Klines 返回新生成/更新的K线通道
	Klines() <-chan *model.Kline

	// Stop 停止聚合引擎
	Stop() error
}

// Validator 行情数据校验器接口
type Validator interface {
	// ValidateQuote 校验行情快照
	ValidateQuote(quote *model.Quote) ValidationResult

	// ValidateTrade 校验逐笔成交
	ValidateTrade(trade *model.Trade) ValidationResult

	// ValidateDepth 校验深度行情
	ValidateDepth(depth *model.Depth) ValidationResult
}

// ValidationResult 校验结果
type ValidationResult struct {
	Valid  bool              `json:"valid"`
	Issues []ValidationIssue `json:"issues,omitempty"`
}

// ValidationIssue 校验问题
type ValidationIssue struct {
	Level   Severity `json:"level"`
	Message string   `json:"message"`
	Field   string   `json:"field,omitempty"`
}

// Severity 严重程度
type Severity int

const (
	SeverityInfo     Severity = 0
	SeverityWarning  Severity = 1
	SeverityCritical Severity = 2
)

// Processor 行情处理引擎
// 串联 Normalizer → Validator → Aggregator → Cache 的核心流程
type Processor interface {
	// Start 启动处理引擎
	Start(ctx context.Context) error

	// Stop 停止处理引擎
	Stop() error

	// Quotes 返回处理后的行情流（供分发层消费）
	Quotes() <-chan *model.Quote

	// Trades 返回处理后的成交流
	Trades() <-chan *model.Trade

	// Depths 返回处理后的深度行情流
	Depths() <-chan *model.Depth

	// Klines 返回聚合后的K线流
	Klines() <-chan *model.Kline
}
