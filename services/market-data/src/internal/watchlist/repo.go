package watchlist

import (
	"context"
	"fmt"
	"time"

	"gorm.io/gorm"
)

// watchlistModel is the GORM DB struct for the watchlist_items table.
type watchlistModel struct {
	ID        int64     `gorm:"primaryKey;autoIncrement"`
	UserID    int64     `gorm:"not null;index:idx_user_symbol,unique"`
	Symbol    string    `gorm:"type:varchar(20);not null;index:idx_user_symbol,unique"`
	Market    string    `gorm:"type:varchar(5);not null"`
	SortOrder int       `gorm:"not null;default:0"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
}

func (watchlistModel) TableName() string { return "watchlist_items" }

// MySQLWatchlistRepo implements WatchlistRepo using GORM.
type MySQLWatchlistRepo struct {
	db *gorm.DB
}

// NewMySQLWatchlistRepo creates a new MySQLWatchlistRepo.
func NewMySQLWatchlistRepo(db *gorm.DB) *MySQLWatchlistRepo {
	return &MySQLWatchlistRepo{db: db}
}

// FindByUserID retrieves all watchlist items for a user.
func (r *MySQLWatchlistRepo) FindByUserID(ctx context.Context, userID int64) ([]*WatchlistItem, error) {
	var models []watchlistModel
	result := r.db.WithContext(ctx).Where("user_id = ?", userID).Order("sort_order ASC").Find(&models)
	if result.Error != nil {
		return nil, fmt.Errorf("watchlist repo find user %d: %w", userID, result.Error)
	}
	items := make([]*WatchlistItem, 0, len(models))
	for _, m := range models {
		items = append(items, &WatchlistItem{
			ID:        m.ID,
			UserID:    m.UserID,
			Symbol:    m.Symbol,
			Market:    m.Market,
			SortOrder: m.SortOrder,
			CreatedAt: m.CreatedAt.UTC(),
		})
	}
	return items, nil
}

// CountByUserID returns the number of watchlist items for a user.
func (r *MySQLWatchlistRepo) CountByUserID(ctx context.Context, userID int64) (int, error) {
	var count int64
	result := r.db.WithContext(ctx).Model(&watchlistModel{}).Where("user_id = ?", userID).Count(&count)
	if result.Error != nil {
		return 0, fmt.Errorf("watchlist repo count user %d: %w", userID, result.Error)
	}
	return int(count), nil
}

// ExistsByUserAndSymbol returns true if the user already has the symbol in their watchlist.
func (r *MySQLWatchlistRepo) ExistsByUserAndSymbol(ctx context.Context, userID int64, symbol string) (bool, error) {
	var count int64
	result := r.db.WithContext(ctx).Model(&watchlistModel{}).
		Where("user_id = ? AND symbol = ?", userID, symbol).Count(&count)
	if result.Error != nil {
		return false, fmt.Errorf("watchlist repo exists user %d symbol %s: %w", userID, symbol, result.Error)
	}
	return count > 0, nil
}

// Add adds a symbol to the user's watchlist.
func (r *MySQLWatchlistRepo) Add(ctx context.Context, item *WatchlistItem) error {
	m := watchlistModel{
		UserID:    item.UserID,
		Symbol:    item.Symbol,
		Market:    item.Market,
		SortOrder: item.SortOrder,
		CreatedAt: item.CreatedAt.UTC(),
	}
	result := r.db.WithContext(ctx).Create(&m)
	if result.Error != nil {
		return fmt.Errorf("watchlist repo add: %w", result.Error)
	}
	item.ID = m.ID
	return nil
}

// Remove removes a symbol from the user's watchlist.
func (r *MySQLWatchlistRepo) Remove(ctx context.Context, userID int64, symbol string) error {
	result := r.db.WithContext(ctx).Where("user_id = ? AND symbol = ?", userID, symbol).Delete(&watchlistModel{})
	if result.Error != nil {
		return fmt.Errorf("watchlist repo remove: %w", result.Error)
	}
	return nil
}

// Reorder updates the sort order for a user's watchlist items.
func (r *MySQLWatchlistRepo) Reorder(ctx context.Context, userID int64, symbolOrder []string) error {
	for i, symbol := range symbolOrder {
		result := r.db.WithContext(ctx).
			Model(&watchlistModel{}).
			Where("user_id = ? AND symbol = ?", userID, symbol).
			Update("sort_order", i)
		if result.Error != nil {
			return fmt.Errorf("watchlist repo reorder: %w", result.Error)
		}
	}
	return nil
}
