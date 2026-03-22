package search

import (
	"context"
	"fmt"

	goredis "github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

// stockModel is the GORM DB struct for the stocks table.
type stockModel struct {
	ID       int64  `gorm:"primaryKey;autoIncrement"`
	Symbol   string `gorm:"type:varchar(20);uniqueIndex;not null"`
	Name     string `gorm:"type:varchar(255);not null"`
	NameCN   string `gorm:"type:varchar(255)"`
	Market   string `gorm:"type:varchar(5);not null;index"`
	Exchange string `gorm:"type:varchar(20);not null"`
	Sector   string `gorm:"type:varchar(100)"`
	Industry string `gorm:"type:varchar(100)"`
}

func (stockModel) TableName() string { return "stocks" }

// MySQLStockSearchRepo implements StockSearchRepo using GORM full-text search.
type MySQLStockSearchRepo struct {
	db *gorm.DB
}

// NewMySQLStockSearchRepo creates a new MySQLStockSearchRepo.
func NewMySQLStockSearchRepo(db *gorm.DB) *MySQLStockSearchRepo {
	return &MySQLStockSearchRepo{db: db}
}

// Search performs a FULLTEXT search on stocks using the idx_stocks_search index.
// Spec: market-api-spec.md §GET /search — MATCH(name, name_cn) AGAINST IN BOOLEAN MODE
// Symbol prefix match is ORed in so exact ticker lookups always surface first.
func (r *MySQLStockSearchRepo) Search(ctx context.Context, query string, market string, limit int) ([]*Stock, error) {
	if query == "" {
		return nil, fmt.Errorf("stock search: query must not be empty")
	}

	// Sanitise and append * for prefix matching in BOOLEAN MODE.
	fulltextTerm := sanitizeFulltextQuery(query)

	rawSQL := `
SELECT id, symbol, name, name_cn, market, exchange, sector, industry,
       MATCH(name, name_cn) AGAINST(? IN BOOLEAN MODE) AS relevance
FROM stocks
WHERE (symbol LIKE ? OR MATCH(name, name_cn) AGAINST(? IN BOOLEAN MODE))`

	args := []interface{}{fulltextTerm, query + "%", fulltextTerm}

	if market != "" {
		rawSQL += " AND market = ?"
		args = append(args, market)
	}
	rawSQL += " ORDER BY (symbol LIKE ?) DESC, relevance DESC LIMIT ?"
	args = append(args, query+"%", limit)

	rows, err := r.db.WithContext(ctx).Raw(rawSQL, args...).Rows()
	if err != nil {
		return nil, fmt.Errorf("stock search repo fulltext: %w", err)
	}
	defer rows.Close()

	stocks := make([]*Stock, 0, limit)
	seen := make(map[string]struct{})
	for rows.Next() {
		var m stockModel
		var relevance float64
		if err := rows.Scan(&m.ID, &m.Symbol, &m.Name, &m.NameCN, &m.Market, &m.Exchange, &m.Sector, &m.Industry, &relevance); err != nil {
			return nil, fmt.Errorf("stock search repo scan: %w", err)
		}
		if _, dup := seen[m.Symbol]; dup {
			continue
		}
		seen[m.Symbol] = struct{}{}
		stocks = append(stocks, &Stock{
			Symbol:   m.Symbol,
			Name:     m.Name,
			NameCN:   m.NameCN,
			Market:   m.Market,
			Exchange: m.Exchange,
			Sector:   m.Sector,
			Industry: m.Industry,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("stock search repo rows: %w", err)
	}
	return stocks, nil
}

// sanitizeFulltextQuery strips MySQL BOOLEAN MODE operator characters to prevent
// query structure injection, then appends * for prefix matching.
func sanitizeFulltextQuery(q string) string {
	result := make([]rune, 0, len(q)+1)
	for _, ch := range q {
		switch ch {
		case '+', '-', '<', '>', '(', ')', '~', '"', '@', '\\', '*':
			// strip BOOLEAN MODE operators (including * — we append our own below)
		default:
			result = append(result, ch)
		}
	}
	return string(result) + "*"
}

// GetBySymbol retrieves a single stock by exact symbol.
func (r *MySQLStockSearchRepo) GetBySymbol(ctx context.Context, symbol string) (*Stock, error) {
	var m stockModel
	result := r.db.WithContext(ctx).Where("symbol = ?", symbol).First(&m)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("stock search repo get %s: %w", symbol, result.Error)
	}
	return &Stock{
		Symbol:   m.Symbol,
		Name:     m.Name,
		NameCN:   m.NameCN,
		Market:   m.Market,
		Exchange: m.Exchange,
		Sector:   m.Sector,
		Industry: m.Industry,
	}, nil
}

// ExistsBySymbol returns true if the symbol exists in the stocks universe.
// Implements watchlist.StockValidator.
func (r *MySQLStockSearchRepo) ExistsBySymbol(ctx context.Context, symbol string) (bool, error) {
	var count int64
	result := r.db.WithContext(ctx).Model(&stockModel{}).Where("symbol = ?", symbol).Count(&count)
	if result.Error != nil {
		return false, fmt.Errorf("stock search repo exists %s: %w", symbol, result.Error)
	}
	return count > 0, nil
}

const hotSearchKey = "hot_search:ranking"

// RedisHotSearchRepo implements HotSearchRepo using Redis sorted sets.
type RedisHotSearchRepo struct {
	rdb *goredis.Client
}

// NewRedisHotSearchRepo creates a new RedisHotSearchRepo.
func NewRedisHotSearchRepo(rdb *goredis.Client) *RedisHotSearchRepo {
	return &RedisHotSearchRepo{rdb: rdb}
}

// IncrementScore increments the search score for a symbol.
func (r *RedisHotSearchRepo) IncrementScore(ctx context.Context, symbol string) error {
	if err := r.rdb.ZIncrBy(ctx, hotSearchKey, 1, symbol).Err(); err != nil {
		return fmt.Errorf("hot search increment %s: %w", symbol, err)
	}
	return nil
}

// GetTopN retrieves the top N hot search items.
func (r *RedisHotSearchRepo) GetTopN(ctx context.Context, n int) ([]*HotSearchItem, error) {
	results, err := r.rdb.ZRevRangeWithScores(ctx, hotSearchKey, 0, int64(n-1)).Result()
	if err != nil {
		return nil, fmt.Errorf("hot search get top %d: %w", n, err)
	}
	items := make([]*HotSearchItem, 0, len(results))
	for _, z := range results {
		items = append(items, &HotSearchItem{
			Symbol: z.Member.(string),
			Score:  z.Score,
		})
	}
	return items, nil
}
