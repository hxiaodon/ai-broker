package repository

import (
	"context"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// KlineRepository K线仓储
type KlineRepository struct {
	db *gorm.DB
}

// NewKlineRepository 创建K线仓储
func NewKlineRepository(db *gorm.DB) *KlineRepository {
	return &KlineRepository{db: db}
}

// Create 创建K线
func (r *KlineRepository) Create(ctx context.Context, kline *model.Kline) error {
	return r.db.WithContext(ctx).Create(kline).Error
}

// Upsert 插入或更新K线
func (r *KlineRepository) Upsert(ctx context.Context, kline *model.Kline) error {
	return r.db.WithContext(ctx).
		Where("symbol = ? AND interval = ? AND timestamp = ?", kline.Symbol, kline.Interval, kline.Timestamp).
		Assign(kline).
		FirstOrCreate(kline).Error
}

// BatchCreate 批量创建K线
func (r *KlineRepository) BatchCreate(ctx context.Context, klines []*model.Kline) error {
	return r.db.WithContext(ctx).CreateInBatches(klines, 100).Error
}

// FindBySymbolAndInterval 根据股票代码和时间间隔查找K线
func (r *KlineRepository) FindBySymbolAndInterval(ctx context.Context, symbol, interval string, startTime, endTime int64, limit int) ([]*model.Kline, error) {
	var klines []*model.Kline
	query := r.db.WithContext(ctx).
		Where("symbol = ? AND interval = ?", symbol, interval)

	if startTime > 0 {
		query = query.Where("timestamp >= ?", startTime)
	}
	if endTime > 0 {
		query = query.Where("timestamp <= ?", endTime)
	}

	err := query.Order("timestamp DESC").Limit(limit).Find(&klines).Error
	return klines, err
}

// FindLatest 查找最新的K线
func (r *KlineRepository) FindLatest(ctx context.Context, symbol, interval string) (*model.Kline, error) {
	var kline model.Kline
	err := r.db.WithContext(ctx).
		Where("symbol = ? AND interval = ?", symbol, interval).
		Order("timestamp DESC").
		First(&kline).Error
	if err != nil {
		return nil, err
	}
	return &kline, nil
}

// DeleteOldKlines 删除旧K线数据
func (r *KlineRepository) DeleteOldKlines(ctx context.Context, beforeTimestamp int64) error {
	return r.db.WithContext(ctx).
		Where("timestamp < ?", beforeTimestamp).
		Delete(&model.Kline{}).Error
}

// Count 统计K线数量
func (r *KlineRepository) Count(ctx context.Context, symbol, interval string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Kline{}).
		Where("symbol = ? AND interval = ?", symbol, interval).
		Count(&count).Error
	return count, err
}
