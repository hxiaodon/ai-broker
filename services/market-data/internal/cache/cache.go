package cache

import (
	"context"
	"time"

	"github.com/brokerage/services/market-data/internal/model"
)

// QuoteCache 行情缓存接口
type QuoteCache interface {
	// SetQuote 更新行情快照
	SetQuote(ctx context.Context, quote *model.Quote) error

	// GetQuote 获取单个标的行情
	GetQuote(ctx context.Context, symbol string, market model.Market) (*model.Quote, error)

	// GetQuotes 批量获取行情
	GetQuotes(ctx context.Context, symbols []string, market model.Market) ([]*model.Quote, error)

	// SetDepth 更新深度行情
	SetDepth(ctx context.Context, depth *model.Depth) error

	// GetDepth 获取深度行情
	GetDepth(ctx context.Context, symbol string, market model.Market, levels int) (*model.Depth, error)
}

// KlineCache K线缓存接口
type KlineCache interface {
	// AppendKline 追加/更新最新K线
	AppendKline(ctx context.Context, kline *model.Kline) error

	// GetKlines 获取K线数据
	GetKlines(ctx context.Context, symbol string, market model.Market, interval model.KlineInterval, from, to time.Time, limit int) ([]*model.Kline, error)
}

// LocalCache 进程内缓存（热路径，无网络开销）
type LocalCache interface {
	// Get 获取缓存的行情（无锁读取）
	Get(symbol string) (*model.Quote, bool)

	// Update 更新缓存
	Update(quote *model.Quote)

	// Stats 缓存统计
	Stats() CacheStats
}

// CacheStats 缓存统计信息
type CacheStats struct {
	Hits       int64 `json:"hits"`
	Misses     int64 `json:"misses"`
	TotalItems int64 `json:"total_items"`
}
