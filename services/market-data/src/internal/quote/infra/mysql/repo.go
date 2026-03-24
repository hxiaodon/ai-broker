// Package mysql implements the quote repository using MySQL/GORM.
package mysql

import (
	"context"
	"crypto/rand"
	"fmt"
	"strings"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/correlation"
	"gorm.io/gorm"
)

// QuoteRepository implements domain.QuoteRepo using GORM.
type QuoteRepository struct {
	db *gorm.DB
}

// NewQuoteRepository creates a new QuoteRepository.
func NewQuoteRepository(db *gorm.DB) *QuoteRepository {
	return &QuoteRepository{db: db}
}

// Save persists a quote to MySQL.
// Uses the transactional *gorm.DB from context if present (set by NewTxFunc).
func (r *QuoteRepository) Save(ctx context.Context, q *domain.Quote) error {
	db := dbFromCtx(ctx, r.db)
	m := toModel(q)
	result := db.Save(&m)
	if result.Error != nil {
		return fmt.Errorf("quote repo save %s: %w", q.Symbol, result.Error)
	}
	return nil
}

// FindBySymbol retrieves the latest quote for a symbol.
func (r *QuoteRepository) FindBySymbol(ctx context.Context, symbol string) (*domain.Quote, error) {
	var m QuoteModel
	result := r.db.WithContext(ctx).Where("symbol = ?", symbol).First(&m)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("quote repo find %s: %w", symbol, result.Error)
	}
	return toDomain(&m), nil
}

// FindBySymbols retrieves quotes for multiple symbols.
func (r *QuoteRepository) FindBySymbols(ctx context.Context, symbols []string) ([]*domain.Quote, error) {
	var models []QuoteModel
	result := r.db.WithContext(ctx).Where("symbol IN ?", symbols).Find(&models)
	if result.Error != nil {
		return nil, fmt.Errorf("quote repo find symbols: %w", result.Error)
	}
	quotes := make([]*domain.Quote, 0, len(models))
	for i := range models {
		quotes = append(quotes, toDomain(&models[i]))
	}
	return quotes, nil
}

// GetBySymbolMarketTimestamp checks if a quote already exists for deduplication.
func (r *QuoteRepository) GetBySymbolMarketTimestamp(ctx context.Context, symbol string, market domain.Market, timestamp int64) (*domain.Quote, error) {
	var m QuoteModel
	result := r.db.WithContext(ctx).Where("symbol = ? AND market = ? AND last_updated_at = ?", symbol, string(market), timestamp).First(&m)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("quote repo get by timestamp: %w", result.Error)
	}
	return toDomain(&m), nil
}

// MarketStatusRepository implements domain.MarketStatusRepo using GORM.
type MarketStatusRepository struct {
	db *gorm.DB
}

// NewMarketStatusRepository creates a new MarketStatusRepository.
func NewMarketStatusRepository(db *gorm.DB) *MarketStatusRepository {
	return &MarketStatusRepository{db: db}
}

// GetStatus returns the current market status for an exchange.
func (r *MarketStatusRepository) GetStatus(ctx context.Context, market domain.Market) (*domain.MarketStatus, error) {
	var m MarketStatusModel
	result := r.db.WithContext(ctx).Where("market = ?", string(market)).First(&m)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			return nil, nil
		}
		return nil, fmt.Errorf("market status repo get %s: %w", market, result.Error)
	}
	return &domain.MarketStatus{
		Market:    domain.Market(m.Market),
		Phase:     domain.TradingPhase(m.Phase),
		UpdatedAt: m.UpdatedAt.UTC(),
	}, nil
}

// SetStatus updates the market status for an exchange.
func (r *MarketStatusRepository) SetStatus(ctx context.Context, status *domain.MarketStatus) error {
	m := MarketStatusModel{
		Market:    string(status.Market),
		Phase:     string(status.Phase),
		UpdatedAt: status.UpdatedAt.UTC(),
	}
	result := r.db.WithContext(ctx).Save(&m)
	if result.Error != nil {
		return fmt.Errorf("market status repo set %s: %w", status.Market, result.Error)
	}
	return nil
}

// OutboxRepository implements app.OutboxRepo for outbox event insertion.
type OutboxRepository struct {
	db *gorm.DB
}

// NewOutboxRepository creates a new OutboxRepository.
func NewOutboxRepository(db *gorm.DB) *OutboxRepository {
	return &OutboxRepository{db: db}
}

// InsertEvent inserts an outbox event with full EventEnvelope metadata.
// Uses the transactional *gorm.DB from context when present — this ensures
// the outbox write is atomic with the quote save (Spec: Outbox pattern).
func (r *OutboxRepository) InsertEvent(ctx context.Context, topic string, payload []byte) error {
	db := dbFromCtx(ctx, r.db)

	// Generate event_id (UUID v4) for idempotency
	eventID := generateUUID()

	// Extract correlation_id from context (OTel trace ID), fallback to event_id
	correlationID := extractCorrelationID(ctx, eventID)

	// event_type derived from topic (e.g., "brokerage.market-data.quote.updated" → "QuoteUpdated.v1")
	eventType := deriveEventType(topic)

	result := db.Exec(
		"INSERT INTO outbox_events (event_id, event_type, correlation_id, topic, payload, status, created_at) VALUES (?, ?, ?, ?, ?, 'PENDING', NOW(6))",
		eventID, eventType, correlationID, topic, payload,
	)
	if result.Error != nil {
		return fmt.Errorf("outbox insert event: %w", result.Error)
	}
	return nil
}

// NewTxFunc returns an app.TxFunc backed by gorm.DB.Transaction.
// The returned function executes fn within a single DB transaction; if fn returns
// an error the transaction is rolled back, otherwise it is committed.
func NewTxFunc(db *gorm.DB) app.TxFunc {
	return func(ctx context.Context, fn func(ctx context.Context) error) error {
		return db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
			// Store tx in context so repos can detect and use it.
			txCtx := context.WithValue(ctx, txKey{}, tx)
			return fn(txCtx)
		})
	}
}

// txKey is the context key for the transactional *gorm.DB.
type txKey struct{}

// dbFromCtx returns the transactional *gorm.DB from context if present,
// otherwise falls back to the provided default db with ctx applied.
func dbFromCtx(ctx context.Context, fallback *gorm.DB) *gorm.DB {
	if tx, ok := ctx.Value(txKey{}).(*gorm.DB); ok && tx != nil {
		return tx
	}
	return fallback.WithContext(ctx)
}

// generateUUID generates a UUID v4 for event_id.
func generateUUID() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	b[6] = (b[6] & 0x0f) | 0x40 // Version 4
	b[8] = (b[8] & 0x3f) | 0x80 // Variant RFC4122
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:])
}

// extractCorrelationID extracts correlation_id from context.
func extractCorrelationID(ctx context.Context, fallback string) string {
	if id := correlation.FromContext(ctx); id != "" {
		return id
	}
	return fallback
}

// deriveEventType derives event_type from topic.
func deriveEventType(topic string) string {
	parts := strings.Split(topic, ".")
	if len(parts) > 0 {
		return strings.Title(parts[len(parts)-1]) + ".v1"
	}
	return "Unknown.v1"
}
