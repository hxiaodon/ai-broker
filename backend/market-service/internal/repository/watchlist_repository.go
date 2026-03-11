package repository

import (
	"context"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// WatchlistRepository 自选股仓储
type WatchlistRepository struct {
	db *gorm.DB
}

// NewWatchlistRepository 创建自选股仓储
func NewWatchlistRepository(db *gorm.DB) *WatchlistRepository {
	return &WatchlistRepository{db: db}
}

// Create 创建自选股
func (r *WatchlistRepository) Create(ctx context.Context, watchlist *model.Watchlist) error {
	return r.db.WithContext(ctx).Create(watchlist).Error
}

// Delete 删除自选股
func (r *WatchlistRepository) Delete(ctx context.Context, userID uint64, symbol string) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND symbol = ?", userID, symbol).
		Delete(&model.Watchlist{}).Error
}

// FindByUserID 根据用户ID查找自选股列表
func (r *WatchlistRepository) FindByUserID(ctx context.Context, userID uint64) ([]*model.Watchlist, error) {
	var watchlists []*model.Watchlist
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("sort_order ASC, created_at DESC").
		Find(&watchlists).Error
	return watchlists, err
}

// FindByUserIDAndSymbol 根据用户ID和股票代码查找
func (r *WatchlistRepository) FindByUserIDAndSymbol(ctx context.Context, userID uint64, symbol string) (*model.Watchlist, error) {
	var watchlist model.Watchlist
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND symbol = ?", userID, symbol).
		First(&watchlist).Error
	if err != nil {
		return nil, err
	}
	return &watchlist, nil
}

// Exists 检查是否存在
func (r *WatchlistRepository) Exists(ctx context.Context, userID uint64, symbol string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Watchlist{}).
		Where("user_id = ? AND symbol = ?", userID, symbol).
		Count(&count).Error
	return count > 0, err
}

// Count 统计用户自选股数量
func (r *WatchlistRepository) Count(ctx context.Context, userID uint64) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.Watchlist{}).
		Where("user_id = ?", userID).
		Count(&count).Error
	return count, err
}

// UpdateSortOrder 更新排序
func (r *WatchlistRepository) UpdateSortOrder(ctx context.Context, userID uint64, symbol string, sortOrder int) error {
	return r.db.WithContext(ctx).Model(&model.Watchlist{}).
		Where("user_id = ? AND symbol = ?", userID, symbol).
		Update("sort_order", sortOrder).Error
}

// GetSymbols 获取用户的所有自选股代码
func (r *WatchlistRepository) GetSymbols(ctx context.Context, userID uint64) ([]string, error) {
	var symbols []string
	err := r.db.WithContext(ctx).Model(&model.Watchlist{}).
		Where("user_id = ?", userID).
		Pluck("symbol", &symbols).Error
	return symbols, err
}
