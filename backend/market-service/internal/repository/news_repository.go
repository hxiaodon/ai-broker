package repository

import (
	"context"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// NewsRepository 新闻仓储
type NewsRepository struct {
	db *gorm.DB
}

// NewNewsRepository 创建新闻仓储
func NewNewsRepository(db *gorm.DB) *NewsRepository {
	return &NewsRepository{db: db}
}

// Create 创建新闻
func (r *NewsRepository) Create(ctx context.Context, news *model.News) error {
	return r.db.WithContext(ctx).Create(news).Error
}

// BatchCreate 批量创建新闻
func (r *NewsRepository) BatchCreate(ctx context.Context, newsList []*model.News) error {
	return r.db.WithContext(ctx).CreateInBatches(newsList, 100).Error
}

// FindByID 根据ID查找新闻
func (r *NewsRepository) FindByID(ctx context.Context, id uint64) (*model.News, error) {
	var news model.News
	err := r.db.WithContext(ctx).First(&news, id).Error
	if err != nil {
		return nil, err
	}
	return &news, nil
}

// FindByNewsID 根据新闻ID查找
func (r *NewsRepository) FindByNewsID(ctx context.Context, newsID string) (*model.News, error) {
	var news model.News
	err := r.db.WithContext(ctx).Where("news_id = ?", newsID).First(&news).Error
	if err != nil {
		return nil, err
	}
	return &news, nil
}

// FindBySymbol 根据股票代码查找新闻
func (r *NewsRepository) FindBySymbol(ctx context.Context, symbol string, offset, limit int) ([]*model.News, error) {
	var newsList []*model.News
	err := r.db.WithContext(ctx).
		Where("symbol = ?", symbol).
		Order("publish_time DESC").
		Offset(offset).
		Limit(limit).
		Find(&newsList).Error
	return newsList, err
}

// List 获取新闻列表
func (r *NewsRepository) List(ctx context.Context, offset, limit int) ([]*model.News, error) {
	var newsList []*model.News
	err := r.db.WithContext(ctx).
		Order("publish_time DESC").
		Offset(offset).
		Limit(limit).
		Find(&newsList).Error
	return newsList, err
}

// Count 统计新闻数量
func (r *NewsRepository) Count(ctx context.Context, symbol string) (int64, error) {
	var count int64
	query := r.db.WithContext(ctx).Model(&model.News{})

	if symbol != "" {
		query = query.Where("symbol = ?", symbol)
	}

	err := query.Count(&count).Error
	return count, err
}

// DeleteOldNews 删除旧新闻
func (r *NewsRepository) DeleteOldNews(ctx context.Context, beforeTimestamp int64) error {
	return r.db.WithContext(ctx).
		Where("publish_time < ?", beforeTimestamp).
		Delete(&model.News{}).Error
}

// Exists 检查新闻是否存在
func (r *NewsRepository) Exists(ctx context.Context, newsID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.News{}).
		Where("news_id = ?", newsID).
		Count(&count).Error
	return count > 0, err
}
