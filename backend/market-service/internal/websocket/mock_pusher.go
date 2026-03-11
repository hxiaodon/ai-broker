package websocket

import (
	"log"
	"math/rand"
	"time"

	"github.com/shopspring/decimal"
	"gorm.io/gorm"
)

// MockPusher Mock 数据推送器
type MockPusher struct {
	hub *Hub
	db  *gorm.DB
}

// NewMockPusher 创建 Mock 推送器
func NewMockPusher(hub *Hub, db *gorm.DB) *MockPusher {
	return &MockPusher{
		hub: hub,
		db:  db,
	}
}

// Start 启动 Mock 数据推送
func (m *MockPusher) Start() {
	go m.pushQuotes()
}

// pushQuotes 推送实时行情（每秒更新）
func (m *MockPusher) pushQuotes() {
	ticker := time.NewTicker(1 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		var quotes []struct {
			Symbol        string
			Price         decimal.Decimal
			Change        decimal.Decimal
			ChangePercent decimal.Decimal
			Volume        int64
		}

		// 从数据库读取最新行情
		err := m.db.Table("quotes").
			Select("symbol, price, `change`, change_percent, volume").
			Order("updated_at DESC").
			Limit(10).
			Find(&quotes).Error

		if err != nil {
			log.Printf("Failed to fetch quotes: %v", err)
			continue
		}

		// 模拟价格波动并推送
		for _, q := range quotes {
			// 随机波动 ±0.5%
			fluctuation := decimal.NewFromFloat((rand.Float64() - 0.5) / 100)
			newPrice := q.Price.Mul(decimal.NewFromInt(1).Add(fluctuation))
			newChange := newPrice.Sub(q.Price)
			newChangePercent := newChange.Div(q.Price).Mul(decimal.NewFromInt(100))

			quoteData := &QuoteData{
				Symbol:        q.Symbol,
				Price:         newPrice,
				Change:        newChange,
				ChangePercent: newChangePercent,
				Volume:        q.Volume + rand.Int63n(1000),
				Timestamp:     time.Now().UnixMilli(),
			}

			m.hub.BroadcastQuote(quoteData)
		}
	}
}
