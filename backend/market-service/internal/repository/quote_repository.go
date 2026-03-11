package repository

import (
	"context"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// QuoteRepository 行情仓储
type QuoteRepository struct {
	db *gorm.DB
}

// NewQuoteRepository 创建行情仓储
func NewQuoteRepository(db *gorm.DB) *QuoteRepository {
	return &QuoteRepository{db: db}
}

// Create 创建行情
func (r *QuoteRepository) Create(ctx context.Context, quote *model.Quote) error {
	return r.db.WithContext(ctx).Create(quote).Error
}

// Update 更新行情
func (r *QuoteRepository) Update(ctx context.Context, quote *model.Quote) error {
	return r.db.WithContext(ctx).Save(quote).Error
}

// Upsert 插入或更新行情
func (r *QuoteRepository) Upsert(ctx context.Context, quote *model.Quote) error {
	return r.db.WithContext(ctx).
		Where("symbol = ?", quote.Symbol).
		Assign(quote).
		FirstOrCreate(quote).Error
}

// FindBySymbol 根据代码查找最新行情
func (r *QuoteRepository) FindBySymbol(ctx context.Context, symbol string) (*model.Quote, error) {
	var quote model.Quote
	err := r.db.WithContext(ctx).
		Where("symbol = ?", symbol).
		Order("timestamp DESC").
		First(&quote).Error
	if err != nil {
		return nil, err
	}
	return &quote, nil
}

// FindBySymbols 根据代码列表查找最新行情
func (r *QuoteRepository) FindBySymbols(ctx context.Context, symbols []string) ([]*model.Quote, error) {
	var quotes []*model.Quote

	// 使用子查询获取每个股票的最新行情
	err := r.db.WithContext(ctx).Raw(`
		SELECT q1.* FROM quotes q1
		INNER JOIN (
			SELECT symbol, MAX(timestamp) as max_timestamp
			FROM quotes
			WHERE symbol IN ?
			GROUP BY symbol
		) q2 ON q1.symbol = q2.symbol AND q1.timestamp = q2.max_timestamp
	`, symbols).Scan(&quotes).Error

	return quotes, err
}

// List 获取行情列表
func (r *QuoteRepository) List(ctx context.Context, offset, limit int) ([]*model.Quote, error) {
	var quotes []*model.Quote
	err := r.db.WithContext(ctx).
		Order("timestamp DESC").
		Offset(offset).
		Limit(limit).
		Find(&quotes).Error
	return quotes, err
}

// DeleteOldQuotes 删除旧行情数据
func (r *QuoteRepository) DeleteOldQuotes(ctx context.Context, beforeTimestamp int64) error {
	return r.db.WithContext(ctx).
		Where("timestamp < ?", beforeTimestamp).
		Delete(&model.Quote{}).Error
}
