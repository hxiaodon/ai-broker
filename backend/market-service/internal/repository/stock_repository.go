package repository

import (
	"context"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// StockRepository 股票仓储
type StockRepository struct {
	db *gorm.DB
}

// NewStockRepository 创建股票仓储
func NewStockRepository(db *gorm.DB) *StockRepository {
	return &StockRepository{db: db}
}

// Create 创建股票
func (r *StockRepository) Create(ctx context.Context, stock *model.Stock) error {
	return r.db.WithContext(ctx).Create(stock).Error
}

// Update 更新股票
func (r *StockRepository) Update(ctx context.Context, stock *model.Stock) error {
	return r.db.WithContext(ctx).Save(stock).Error
}

// Delete 删除股票
func (r *StockRepository) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&model.Stock{}, id).Error
}

// FindByID 根据ID查找股票
func (r *StockRepository) FindByID(ctx context.Context, id uint64) (*model.Stock, error) {
	var stock model.Stock
	err := r.db.WithContext(ctx).First(&stock, id).Error
	if err != nil {
		return nil, err
	}
	return &stock, nil
}

// FindBySymbol 根据代码查找股票
func (r *StockRepository) FindBySymbol(ctx context.Context, symbol string) (*model.Stock, error) {
	var stock model.Stock
	err := r.db.WithContext(ctx).Where("symbol = ?", symbol).First(&stock).Error
	if err != nil {
		return nil, err
	}
	return &stock, nil
}

// FindBySymbols 根据代码列表查找股票
func (r *StockRepository) FindBySymbols(ctx context.Context, symbols []string) ([]*model.Stock, error) {
	var stocks []*model.Stock
	err := r.db.WithContext(ctx).Where("symbol IN ?", symbols).Find(&stocks).Error
	return stocks, err
}

// List 获取股票列表
func (r *StockRepository) List(ctx context.Context, market string, offset, limit int) ([]*model.Stock, error) {
	var stocks []*model.Stock
	query := r.db.WithContext(ctx)

	if market != "" {
		query = query.Where("market = ?", market)
	}

	err := query.Offset(offset).Limit(limit).Find(&stocks).Error
	return stocks, err
}

// Count 统计股票数量
func (r *StockRepository) Count(ctx context.Context, market string) (int64, error) {
	var count int64
	query := r.db.WithContext(ctx).Model(&model.Stock{})

	if market != "" {
		query = query.Where("market = ?", market)
	}

	err := query.Count(&count).Error
	return count, err
}

// Search 搜索股票
func (r *StockRepository) Search(ctx context.Context, keyword string, limit int) ([]*model.Stock, error) {
	var stocks []*model.Stock
	err := r.db.WithContext(ctx).
		Where("symbol LIKE ? OR name LIKE ? OR name_cn LIKE ?",
			"%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%").
		Limit(limit).
		Find(&stocks).Error
	return stocks, err
}
