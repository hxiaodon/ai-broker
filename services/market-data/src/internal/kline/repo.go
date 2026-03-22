package kline

import (
	"context"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
	"gorm.io/gorm"
)

// klineModel is the GORM DB struct for the klines table.
// Private to the infra layer.
type klineModel struct {
	ID        int64           `gorm:"primaryKey;autoIncrement"`
	Symbol    string          `gorm:"type:varchar(20);not null;index:idx_symbol_interval_start"`
	Interval  string          `gorm:"column:interval_type;type:varchar(10);not null;index:idx_symbol_interval_start"`
	Open      decimal.Decimal `gorm:"column:open_price;type:decimal(20,8);not null"` // shopspring/decimal — never float64
	High      decimal.Decimal `gorm:"column:high_price;type:decimal(20,8);not null"` // shopspring/decimal — never float64
	Low       decimal.Decimal `gorm:"column:low_price;type:decimal(20,8);not null"` // shopspring/decimal — never float64
	Close     decimal.Decimal `gorm:"column:close_price;type:decimal(20,8);not null"` // shopspring/decimal — never float64
	Volume    int64           `gorm:"not null;default:0"`
	StartTime time.Time       `gorm:"not null;index:idx_symbol_interval_start"`
	EndTime   time.Time       `gorm:"not null"`
	Adjusted  bool            `gorm:"not null;default:false"`
	CreatedAt time.Time       `gorm:"autoCreateTime"`
}

func (klineModel) TableName() string { return "klines" }

// MySQLKLineRepo implements KLineRepo using GORM.
type MySQLKLineRepo struct {
	db *gorm.DB
}

// NewMySQLKLineRepo creates a new MySQLKLineRepo.
func NewMySQLKLineRepo(db *gorm.DB) *MySQLKLineRepo {
	return &MySQLKLineRepo{db: db}
}

// Save persists a K-line record.
func (r *MySQLKLineRepo) Save(ctx context.Context, k *KLine) error {
	m := toKlineModel(k)
	result := r.db.WithContext(ctx).Create(&m)
	if result.Error != nil {
		return fmt.Errorf("kline repo save: %w", result.Error)
	}
	return nil
}

// SaveBatch persists multiple K-line records.
func (r *MySQLKLineRepo) SaveBatch(ctx context.Context, klines []*KLine) error {
	if len(klines) == 0 {
		return nil
	}
	models := make([]klineModel, 0, len(klines))
	for _, k := range klines {
		models = append(models, *toKlineModel(k))
	}
	result := r.db.WithContext(ctx).Create(&models)
	if result.Error != nil {
		return fmt.Errorf("kline repo save batch: %w", result.Error)
	}
	return nil
}

// FindBySymbolAndInterval retrieves K-lines for a symbol, interval, and time range.
func (r *MySQLKLineRepo) FindBySymbolAndInterval(ctx context.Context, symbol string, interval Interval, start, end time.Time, limit int) ([]*KLine, error) {
	var models []klineModel
	result := r.db.WithContext(ctx).
		Where("symbol = ? AND interval_type = ? AND start_time >= ? AND start_time <= ?", symbol, string(interval), start.UTC(), end.UTC()).
		Order("start_time ASC").
		Limit(limit).
		Find(&models)
	if result.Error != nil {
		return nil, fmt.Errorf("kline repo find: %w", result.Error)
	}
	klines := make([]*KLine, 0, len(models))
	for i := range models {
		klines = append(klines, toKlineDomain(&models[i]))
	}
	return klines, nil
}

func toKlineModel(k *KLine) *klineModel {
	return &klineModel{
		Symbol:    k.Symbol,
		Interval:  string(k.Interval),
		Open:      k.Open,
		High:      k.High,
		Low:       k.Low,
		Close:     k.Close,
		Volume:    k.Volume,
		StartTime: k.StartTime.UTC(),
		EndTime:   k.EndTime.UTC(),
		Adjusted:  k.Adjusted,
	}
}

func toKlineDomain(m *klineModel) *KLine {
	return &KLine{
		ID:        m.ID,
		Symbol:    m.Symbol,
		Interval:  Interval(m.Interval),
		Open:      m.Open,
		High:      m.High,
		Low:       m.Low,
		Close:     m.Close,
		Volume:    m.Volume,
		StartTime: m.StartTime.UTC(),
		EndTime:   m.EndTime.UTC(),
		Adjusted:  m.Adjusted,
	}
}
