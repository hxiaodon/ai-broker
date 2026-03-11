package feed

import (
	"context"

	"github.com/brokerage/services/market-data/internal/model"
)

// Handler 数据源 Feed Handler 接口
// 每个数据源（Polygon、HKEX OMD、IEX 等）实现该接口
type Handler interface {
	// Name 返回数据源名称
	Name() string

	// Market 返回数据源所属市场
	Market() model.Market

	// Connect 连接数据源
	Connect(ctx context.Context) error

	// Subscribe 订阅标的行情
	Subscribe(symbols []string, dataTypes []model.DataType) error

	// Unsubscribe 取消订阅
	Unsubscribe(symbols []string) error

	// Messages 返回消息通道（标准化前的原始消息）
	Messages() <-chan model.RawMessage

	// Health 返回连接健康状态
	Health() model.HealthStatus

	// Close 关闭连接并释放资源
	Close() error
}

// Normalizer 数据标准化接口
// 将不同数据源的私有格式转换为内部统一格式
type Normalizer interface {
	// NormalizeQuote 将原始消息标准化为 Quote
	NormalizeQuote(raw model.RawMessage) (*model.Quote, error)

	// NormalizeTrade 将原始消息标准化为 Trade
	NormalizeTrade(raw model.RawMessage) (*model.Trade, error)

	// NormalizeDepth 将原始消息标准化为 Depth
	NormalizeDepth(raw model.RawMessage) (*model.Depth, error)
}

// Manager 数据源管理器
// 管理多个 Feed Handler 的生命周期和故障切换
type Manager interface {
	// Start 启动所有数据源
	Start(ctx context.Context) error

	// Stop 停止所有数据源
	Stop() error

	// GetHandler 获取指定市场的活跃 Feed Handler
	GetHandler(market model.Market) Handler

	// SwitchSource 手动切换数据源（故障时自动触发）
	SwitchSource(market model.Market, source string) error

	// Quotes 返回标准化后的行情通道
	Quotes() <-chan *model.Quote

	// Trades 返回标准化后的成交通道
	Trades() <-chan *model.Trade

	// Depths 返回标准化后的深度行情通道
	Depths() <-chan *model.Depth
}
