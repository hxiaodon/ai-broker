package repository

import (
	"context"
	"time"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// HotSearchRepository 热门搜索仓储
type HotSearchRepository struct {
	db *gorm.DB
}

// NewHotSearchRepository 创建热门搜索仓储
func NewHotSearchRepository(db *gorm.DB) *HotSearchRepository {
	return &HotSearchRepository{db: db}
}

// Create 创建热门搜索记录
func (r *HotSearchRepository) Create(ctx context.Context, hotSearch *model.HotSearch) error {
	return r.db.WithContext(ctx).Create(hotSearch).Error
}

// Update 更新热门搜索记录
func (r *HotSearchRepository) Update(ctx context.Context, hotSearch *model.HotSearch) error {
	return r.db.WithContext(ctx).Save(hotSearch).Error
}

// IncrementSearchCount 增加搜索次数
func (r *HotSearchRepository) IncrementSearchCount(ctx context.Context, symbol string, date time.Time) error {
	return r.db.WithContext(ctx).Exec(`
		INSERT INTO hot_searches (symbol, search_count, date, created_at, updated_at)
		VALUES (?, 1, ?, NOW(), NOW())
		ON DUPLICATE KEY UPDATE
			search_count = search_count + 1,
			updated_at = NOW()
	`, symbol, date.Format("2006-01-02")).Error
}

// FindByDate 根据日期查找热门搜索
func (r *HotSearchRepository) FindByDate(ctx context.Context, date time.Time, limit int) ([]*model.HotSearch, error) {
	var hotSearches []*model.HotSearch
	err := r.db.WithContext(ctx).
		Where("date = ?", date.Format("2006-01-02")).
		Order("rank ASC, search_count DESC").
		Limit(limit).
		Find(&hotSearches).Error
	return hotSearches, err
}

// FindBySymbolAndDate 根据股票代码和日期查找
func (r *HotSearchRepository) FindBySymbolAndDate(ctx context.Context, symbol string, date time.Time) (*model.HotSearch, error) {
	var hotSearch model.HotSearch
	err := r.db.WithContext(ctx).
		Where("symbol = ? AND date = ?", symbol, date.Format("2006-01-02")).
		First(&hotSearch).Error
	if err != nil {
		return nil, err
	}
	return &hotSearch, nil
}

// GetTopSearches 获取热门搜索排行
func (r *HotSearchRepository) GetTopSearches(ctx context.Context, date time.Time, limit int) ([]*model.HotSearch, error) {
	var hotSearches []*model.HotSearch
	err := r.db.WithContext(ctx).
		Where("date = ?", date.Format("2006-01-02")).
		Order("search_count DESC").
		Limit(limit).
		Find(&hotSearches).Error
	return hotSearches, err
}

// UpdateRanks 更新排名
func (r *HotSearchRepository) UpdateRanks(ctx context.Context, date time.Time) error {
	// 先获取当天的热门搜索，按搜索次数排序
	var hotSearches []*model.HotSearch
	err := r.db.WithContext(ctx).
		Where("date = ?", date.Format("2006-01-02")).
		Order("search_count DESC").
		Find(&hotSearches).Error
	if err != nil {
		return err
	}

	// 更新排名
	for i, hs := range hotSearches {
		hs.Rank = i + 1
		if err := r.db.WithContext(ctx).Model(hs).Update("rank", hs.Rank).Error; err != nil {
			return err
		}
	}

	return nil
}

// DeleteOldRecords 删除旧记录
func (r *HotSearchRepository) DeleteOldRecords(ctx context.Context, beforeDate time.Time) error {
	return r.db.WithContext(ctx).
		Where("date < ?", beforeDate.Format("2006-01-02")).
		Delete(&model.HotSearch{}).Error
}

// Count 统计记录数量
func (r *HotSearchRepository) Count(ctx context.Context, date time.Time) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&model.HotSearch{}).
		Where("date = ?", date.Format("2006-01-02")).
		Count(&count).Error
	return count, err
}
