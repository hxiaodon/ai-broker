package model

import (
	"time"

	"github.com/shopspring/decimal"
)

// Stock 股票基本信息
type Stock struct {
	ID             uint64          `json:"id" gorm:"primaryKey"`
	Symbol         string          `json:"symbol" gorm:"uniqueIndex;size:20;not null"`
	Name           string          `json:"name" gorm:"size:255;not null"`
	NameCN         string          `json:"nameCN" gorm:"column:name_cn;size:255"`
	Market         string          `json:"market" gorm:"size:10;not null;index"`
	MarketCap      string          `json:"marketCap" gorm:"column:market_cap;size:20"`
	PE             decimal.Decimal `json:"pe" gorm:"type:decimal(10,2)"`
	PB             decimal.Decimal `json:"pb" gorm:"type:decimal(10,2)"`
	DividendYield  decimal.Decimal `json:"dividendYield" gorm:"column:dividend_yield;type:decimal(5,2)"`
	Week52High     decimal.Decimal `json:"week52High" gorm:"column:week_52_high;type:decimal(10,2)"`
	Week52Low      decimal.Decimal `json:"week52Low" gorm:"column:week_52_low;type:decimal(10,2)"`
	AvgVolume      string          `json:"avgVolume" gorm:"column:avg_volume;size:20"`
	CreatedAt      time.Time       `json:"createdAt" gorm:"column:created_at"`
	UpdatedAt      time.Time       `json:"updatedAt" gorm:"column:updated_at"`
}

// TableName 指定表名
func (Stock) TableName() string {
	return "stocks"
}

// Quote 实时行情
type Quote struct {
	ID            uint64          `json:"id" gorm:"primaryKey"`
	Symbol        string          `json:"symbol" gorm:"size:20;not null;index"`
	Price         decimal.Decimal `json:"price" gorm:"type:decimal(20,8);not null"`
	Open          decimal.Decimal `json:"open" gorm:"type:decimal(20,8)"`
	High          decimal.Decimal `json:"high" gorm:"type:decimal(20,8)"`
	Low           decimal.Decimal `json:"low" gorm:"type:decimal(20,8)"`
	Volume        int64           `json:"volume"`
	ChangeAmount  decimal.Decimal `json:"change" gorm:"column:change_amount;type:decimal(20,8)"`
	ChangePercent decimal.Decimal `json:"changePercent" gorm:"column:change_percent;type:decimal(10,4)"`
	Timestamp     int64           `json:"timestamp" gorm:"not null;index"`
	CreatedAt     time.Time       `json:"createdAt" gorm:"column:created_at"`
	UpdatedAt     time.Time       `json:"updatedAt" gorm:"column:updated_at"`
}

// TableName 指定表名
func (Quote) TableName() string {
	return "quotes"
}

// Kline K线数据
type Kline struct {
	ID        uint64          `json:"id" gorm:"primaryKey"`
	Symbol    string          `json:"symbol" gorm:"size:20;not null;uniqueIndex:uk_symbol_interval_timestamp"`
	Interval  string          `json:"interval" gorm:"size:10;not null;uniqueIndex:uk_symbol_interval_timestamp"`
	Open      decimal.Decimal `json:"open" gorm:"type:decimal(20,8);not null"`
	High      decimal.Decimal `json:"high" gorm:"type:decimal(20,8);not null"`
	Low       decimal.Decimal `json:"low" gorm:"type:decimal(20,8);not null"`
	Close     decimal.Decimal `json:"close" gorm:"type:decimal(20,8);not null"`
	Volume    int64           `json:"volume" gorm:"not null"`
	Timestamp int64           `json:"timestamp" gorm:"not null;uniqueIndex:uk_symbol_interval_timestamp;index"`
	CreatedAt time.Time       `json:"createdAt" gorm:"column:created_at"`
}

// TableName 指定表名
func (Kline) TableName() string {
	return "klines"
}

// Watchlist 自选股
type Watchlist struct {
	ID        uint64    `json:"id" gorm:"primaryKey"`
	UserID    uint64    `json:"userId" gorm:"column:user_id;not null;uniqueIndex:uk_user_symbol;index"`
	Symbol    string    `json:"symbol" gorm:"size:20;not null;uniqueIndex:uk_user_symbol"`
	SortOrder int       `json:"sortOrder" gorm:"column:sort_order;default:0"`
	CreatedAt time.Time `json:"createdAt" gorm:"column:created_at"`
}

// TableName 指定表名
func (Watchlist) TableName() string {
	return "watchlists"
}

// News 股票新闻
type News struct {
	ID          uint64    `json:"id" gorm:"primaryKey"`
	NewsID      string    `json:"newsId" gorm:"column:news_id;size:100;not null;uniqueIndex"`
	Symbol      string    `json:"symbol" gorm:"size:20;not null;index"`
	Title       string    `json:"title" gorm:"size:500;not null"`
	Summary     string    `json:"summary" gorm:"type:text"`
	Source      string    `json:"source" gorm:"size:100"`
	URL         string    `json:"url" gorm:"size:500"`
	PublishTime int64     `json:"publishTime" gorm:"column:publish_time;not null;index"`
	CreatedAt   time.Time `json:"createdAt" gorm:"column:created_at"`
}

// TableName 指定表名
func (News) TableName() string {
	return "news"
}

// Financial 财报数据
type Financial struct {
	ID                uint64          `json:"id" gorm:"primaryKey"`
	Symbol            string          `json:"symbol" gorm:"size:20;not null;uniqueIndex:uk_symbol_quarter;index"`
	Quarter           string          `json:"quarter" gorm:"size:20;not null;uniqueIndex:uk_symbol_quarter"`
	ReportDate        time.Time       `json:"reportDate" gorm:"column:report_date;not null;index"`
	Revenue           string          `json:"revenue" gorm:"size:20"`
	NetIncome         string          `json:"netIncome" gorm:"column:net_income;size:20"`
	EPS               decimal.Decimal `json:"eps" gorm:"type:decimal(10,4)"`
	RevenueGrowth     decimal.Decimal `json:"revenueGrowth" gorm:"column:revenue_growth;type:decimal(10,4)"`
	NetIncomeGrowth   decimal.Decimal `json:"netIncomeGrowth" gorm:"column:net_income_growth;type:decimal(10,4)"`
	NextEarningsDate  time.Time       `json:"nextEarningsDate" gorm:"column:next_earnings_date"`
	CreatedAt         time.Time       `json:"createdAt" gorm:"column:created_at"`
	UpdatedAt         time.Time       `json:"updatedAt" gorm:"column:updated_at"`
}

// TableName 指定表名
func (Financial) TableName() string {
	return "financials"
}

// HotSearch 热门搜索
type HotSearch struct {
	ID          uint64    `json:"id" gorm:"primaryKey"`
	Symbol      string    `json:"symbol" gorm:"size:20;not null;uniqueIndex:uk_symbol_date"`
	SearchCount int       `json:"searchCount" gorm:"column:search_count;default:0"`
	Rank        int       `json:"rank" gorm:"default:0;index:idx_date_rank"`
	Date        time.Time `json:"date" gorm:"type:date;not null;uniqueIndex:uk_symbol_date;index:idx_date_rank"`
	CreatedAt   time.Time `json:"createdAt" gorm:"column:created_at"`
	UpdatedAt   time.Time `json:"updatedAt" gorm:"column:updated_at"`
}

// TableName 指定表名
func (HotSearch) TableName() string {
	return "hot_searches"
}
