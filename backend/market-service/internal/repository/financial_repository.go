package repository

import (
	"context"

	"github.com/brokerage/market-service/internal/model"
	"gorm.io/gorm"
)

// FinancialRepository 财报仓储
type FinancialRepository struct {
	db *gorm.DB
}

// NewFinancialRepository 创建财报仓储
func NewFinancialRepository(db *gorm.DB) *FinancialRepository {
	return &FinancialRepository{db: db}
}

// Create 创建财报
func (r *FinancialRepository) Create(ctx context.Context, financial *model.Financial) error {
	return r.db.WithContext(ctx).Create(financial).Error
}

// Update 更新财报
func (r *FinancialRepository) Update(ctx context.Context, financial *model.Financial) error {
	return r.db.WithContext(ctx).Save(financial).Error
}

// Upsert 插入或更新财报
func (r *FinancialRepository) Upsert(ctx context.Context, financial *model.Financial) error {
	return r.db.WithContext(ctx).
		Where("symbol = ? AND quarter = ?", financial.Symbol, financial.Quarter).
		Assign(financial).
		FirstOrCreate(financial).Error
}

// FindByID 根据ID查找财报
func (r *FinancialRepository) FindByID(ctx context.Context, id uint64) (*model.Financial, error) {
	var financial model.Financial
	err := r.db.WithContext(ctx).First(&financial, id).Error
	if err != nil {
		return nil, err
	}
	return &financial, nil
}

// FindBySymbol 根据股票代码查找财报
func (r *FinancialRepository) FindBySymbol(ctx context.Context, symbol string, limit int) ([]*model.Financial, error) {
	var financials []*model.Financial
	err := r.db.WithContext(ctx).
		Where("symbol = ?", symbol).
		Order("report_date DESC").
		Limit(limit).
		Find(&financials).Error
	return financials, err
}

// FindBySymbolAndQuarter 根据股票代码和季度查找财报
func (r *FinancialRepository) FindBySymbolAndQuarter(ctx context.Context, symbol, quarter string) (*model.Financial, error) {
	var financial model.Financial
	err := r.db.WithContext(ctx).
		Where("symbol = ? AND quarter = ?", symbol, quarter).
		First(&financial).Error
	if err != nil {
		return nil, err
	}
	return &financial, nil
}

// FindLatest 查找最新财报
func (r *FinancialRepository) FindLatest(ctx context.Context, symbol string) (*model.Financial, error) {
	var financial model.Financial
	err := r.db.WithContext(ctx).
		Where("symbol = ?", symbol).
		Order("report_date DESC").
		First(&financial).Error
	if err != nil {
		return nil, err
	}
	return &financial, nil
}

// List 获取财报列表
func (r *FinancialRepository) List(ctx context.Context, offset, limit int) ([]*model.Financial, error) {
	var financials []*model.Financial
	err := r.db.WithContext(ctx).
		Order("report_date DESC").
		Offset(offset).
		Limit(limit).
		Find(&financials).Error
	return financials, err
}

// Count 统计财报数量
func (r *FinancialRepository) Count(ctx context.Context, symbol string) (int64, error) {
	var count int64
	query := r.db.WithContext(ctx).Model(&model.Financial{})

	if symbol != "" {
		query = query.Where("symbol = ?", symbol)
	}

	err := query.Count(&count).Error
	return count, err
}

// BatchCreate 批量创建财报
func (r *FinancialRepository) BatchCreate(ctx context.Context, financials []*model.Financial) error {
	return r.db.WithContext(ctx).CreateInBatches(financials, 100).Error
}
