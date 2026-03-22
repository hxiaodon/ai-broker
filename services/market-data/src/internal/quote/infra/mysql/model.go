package mysql

import (
	"time"

	"github.com/shopspring/decimal"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// QuoteModel is the GORM DB struct for the quotes table.
// Private to the data/infra layer — never exposed to domain or app layers.
type QuoteModel struct {
	ID            int64           `gorm:"primaryKey;autoIncrement"`
	Symbol        string          `gorm:"uniqueIndex;type:varchar(20);not null"`
	Name          string          `gorm:"type:varchar(255);not null"`
	NameZh        string          `gorm:"column:name_zh;type:varchar(255)"`
	Market        string          `gorm:"type:varchar(5);not null"`
	Price         decimal.Decimal `gorm:"type:decimal(20,8);not null"`
	Open          decimal.Decimal `gorm:"column:open_price;type:decimal(20,8);not null"`
	High          decimal.Decimal `gorm:"column:high_price;type:decimal(20,8);not null"`
	Low           decimal.Decimal `gorm:"column:low_price;type:decimal(20,8);not null"`
	PrevClose     decimal.Decimal `gorm:"column:prev_close;type:decimal(20,8);not null"`
	Volume        int64           `gorm:"not null;default:0"`
	Turnover      decimal.Decimal `gorm:"type:decimal(20,8);not null;default:0"`
	Bid           decimal.Decimal `gorm:"type:decimal(20,8);not null"`
	BidSize       int64           `gorm:"not null;default:0"`
	Ask           decimal.Decimal `gorm:"type:decimal(20,8);not null"`
	AskSize       int64           `gorm:"not null;default:0"`
	MarketCap     decimal.Decimal `gorm:"column:market_cap;type:decimal(20,8);not null;default:0"`
	PERatio       decimal.Decimal `gorm:"column:pe_ratio;type:decimal(10,2);not null;default:0"`
	MarketStatus  string          `gorm:"column:market_status;type:varchar(20);not null"`
	Delayed       bool            `gorm:"not null;default:false"`
	LastUpdatedAt time.Time       `gorm:"not null"`
	CreatedAt     time.Time       `gorm:"autoCreateTime"`
	UpdatedAt     time.Time       `gorm:"autoUpdateTime"`
}

// TableName returns the table name for QuoteModel.
func (QuoteModel) TableName() string {
	return "quotes"
}

// MarketStatusModel is the GORM DB struct for the market_status table.
type MarketStatusModel struct {
	ID        int64     `gorm:"primaryKey;autoIncrement"`
	Market    string    `gorm:"uniqueIndex;type:varchar(5);not null"`
	Phase     string    `gorm:"type:varchar(20);not null"`
	UpdatedAt time.Time `gorm:"not null"`
}

// TableName returns the table name for MarketStatusModel.
func (MarketStatusModel) TableName() string {
	return "market_status"
}

// toModel converts a domain Quote to a QuoteModel.
func toModel(q *domain.Quote) *QuoteModel {
	return &QuoteModel{
		Symbol:        q.Symbol,
		Name:          q.Name,
		NameZh:        q.NameZh,
		Market:        string(q.Market),
		Price:         q.Price,
		Open:          q.Open,
		High:          q.High,
		Low:           q.Low,
		PrevClose:     q.PrevClose,
		Volume:        q.Volume,
		Turnover:      q.Turnover,
		Bid:           q.Bid,
		BidSize:       q.BidSize,
		Ask:           q.Ask,
		AskSize:       q.AskSize,
		MarketCap:     q.MarketCap,
		PERatio:       q.PERatio,
		MarketStatus:  string(q.MarketStatus),
		Delayed:       q.Delayed,
		LastUpdatedAt: q.LastUpdatedAt.UTC(),
	}
}

// toDomain converts a QuoteModel to a domain Quote.
func toDomain(m *QuoteModel) *domain.Quote {
	return &domain.Quote{
		Symbol:        m.Symbol,
		Name:          m.Name,
		NameZh:        m.NameZh,
		Market:        domain.Market(m.Market),
		Price:         m.Price,
		Open:          m.Open,
		High:          m.High,
		Low:           m.Low,
		PrevClose:     m.PrevClose,
		Volume:        m.Volume,
		Turnover:      m.Turnover,
		Bid:           m.Bid,
		BidSize:       m.BidSize,
		Ask:           m.Ask,
		AskSize:       m.AskSize,
		MarketCap:     m.MarketCap,
		PERatio:       m.PERatio,
		MarketStatus:  domain.TradingPhase(m.MarketStatus),
		Delayed:       m.Delayed,
		LastUpdatedAt: m.LastUpdatedAt.UTC(),
	}
}
