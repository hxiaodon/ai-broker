// Package app implements use cases for the quote subdomain.
package app

import (
	"context"
	"encoding/json"
	"fmt"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/producer"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
)

// UpdateQuoteUsecase handles updating a quote from feed data.
type UpdateQuoteUsecase struct {
	quoteRepo   domain.QuoteRepo
	cacheRepo   domain.QuoteCacheRepo
	outboxRepo  OutboxRepo
	txFunc      TxFunc
	stale       *domain.StaleDetector
	delayedRepo domain.QuoteDelayedRepo // optional; nil disables delayed ring-buffer push
	logger      *zap.Logger
}

// OutboxRepo defines the interface for writing outbox events.
// Implementations live in infra — this interface belongs to the app layer (caller).
type OutboxRepo interface {
	// InsertEvent inserts an outbox event within the current transaction context.
	InsertEvent(ctx context.Context, topic string, payload []byte) error
}

// TxFunc is a function that executes fn within a DB transaction.
// The infra layer provides a concrete implementation backed by gorm.DB.Transaction.
// Using a function type keeps the app layer free of GORM imports.
type TxFunc func(ctx context.Context, fn func(ctx context.Context) error) error

// NewUpdateQuoteUsecase creates a new UpdateQuoteUsecase.
// delayedRepo is optional — pass nil to disable the delayed ring-buffer push.
func NewUpdateQuoteUsecase(
	quoteRepo domain.QuoteRepo,
	cacheRepo domain.QuoteCacheRepo,
	outboxRepo OutboxRepo,
	txFunc TxFunc,
	stale *domain.StaleDetector,
	delayedRepo domain.QuoteDelayedRepo,
	logger *zap.Logger,
) *UpdateQuoteUsecase {
	return &UpdateQuoteUsecase{
		quoteRepo:   quoteRepo,
		cacheRepo:   cacheRepo,
		outboxRepo:  outboxRepo,
		txFunc:      txFunc,
		stale:       stale,
		delayedRepo: delayedRepo,
		logger:      logger,
	}
}

// Execute updates a quote and publishes a domain event via outbox.
// Spec: market-data-system.md §3 — feed-to-cache-to-outbox pipeline.
// Transaction boundary: DB write + outbox insert are atomic; cache update is best-effort.
func (uc *UpdateQuoteUsecase) Execute(ctx context.Context, q *domain.Quote) error {
	if q == nil {
		return fmt.Errorf("update quote: quote must not be nil")
	}

	// Enforce domain invariants before persisting.
	if err := q.Validate(); err != nil {
		return fmt.Errorf("update quote: %w", err)
	}

	// Idempotency check: prevent duplicate processing of same (symbol, market, timestamp).
	// Redis SET NX is used instead of a MySQL query to avoid a DB round-trip on every tick.
	// If feed handler retries or sends duplicate ticks, return early without creating duplicate outbox events.
	isDup, err := uc.cacheRepo.IsDedup(ctx, q.Symbol, q.Market, q.LastUpdatedAt.UnixMicro())
	if err != nil {
		// Dedup check failure is non-fatal: fall through and risk a duplicate outbox entry,
		// which is safer than dropping a real quote update.
		uc.logger.Warn("dedup check failed (non-fatal), proceeding",
			zap.String("symbol", q.Symbol),
			zap.Error(err))
	} else if isDup {
		uc.logger.Debug("duplicate quote ignored",
			zap.String("symbol", q.Symbol),
			zap.String("market", string(q.Market)),
			zap.Time("timestamp", q.LastUpdatedAt))
		return nil
	}

	// Compute Change / ChangePct from PrevClose when the feed does not provide them.
	// Spec: market-data-system.md Appendix C — change basis = previous Regular Session close (unadjusted).
	if q.PrevClose.IsZero() {
		prevClose, err := uc.quoteRepo.FindPrevClose(ctx, q.Symbol, q.Market)
		if err != nil {
			// Non-fatal: log and continue with zero Change (better than failing the whole update).
			uc.logger.Warn("find prev close failed (non-fatal)",
				zap.String("symbol", q.Symbol),
				zap.Error(err))
		} else {
			q.ApplyChange(prevClose)
		}
	} else {
		// Feed supplied PrevClose; ensure Change/ChangePct are (re)computed consistently.
		q.ApplyChange(q.PrevClose)
	}

	// LastUpdatedAt must be set by the feed handler (exchange timestamp).
	// The usecase must NOT overwrite it with time.Now() — doing so would break
	// stale detection by making stale quotes appear fresh (market-data-system.md Appendix D.3).
	// Spec: market-data-system.md §3.3.5 — evaluate stale thresholds on every update
	q.ApplyStaleCheck(uc.stale.Evaluate(q))

	// Serialize domain event payload (JSON; proto wire format added in Phase 5).
	// Spec: market-data-system.md §5 — QuoteUpdatedEvent is the canonical outbox payload.
	event := domain.NewQuoteUpdatedEvent(q)
	payload, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("update quote %s: marshal event: %w", q.Symbol, err)
	}

	// 1. Atomic: DB write + outbox insert in one transaction.
	// Spec: Outbox pattern — event and entity are written together so no event is lost.
	// Spec: data-flow.md — use market-specific topic (market-data.quotes.us or .hk)
	topic := producer.QuoteTopicForMarket(string(q.Market))
	if err := uc.txFunc(ctx, func(txCtx context.Context) error {
		if err := uc.quoteRepo.Save(txCtx, q); err != nil {
			return fmt.Errorf("save quote: %w", err)
		}
		if err := uc.outboxRepo.InsertEvent(txCtx, topic, payload); err != nil {
			return fmt.Errorf("insert outbox event: %w", err)
		}
		return nil
	}); err != nil {
		return fmt.Errorf("update quote %s: tx: %w", q.Symbol, err)
	}

	// 2. Cache update is best-effort after the transaction commits.
	// A cache miss is tolerable — the next read will fall through to DB.
	if err := uc.cacheRepo.Set(ctx, q); err != nil {
		// Non-fatal: log and continue. The outbox event is already durable.
		uc.logger.Warn("cache set failed (non-fatal)",
			zap.String("symbol", q.Symbol),
			zap.String("market", string(q.Market)),
			zap.Error(err))
	}

	// 3. Push to delayed ring buffer for guest users (best-effort).
	if uc.delayedRepo != nil {
		if err := uc.delayedRepo.Push(ctx, q); err != nil {
			uc.logger.Warn("delayed push failed (non-fatal)",
				zap.String("symbol", q.Symbol),
				zap.Error(err))
		}
	}

	return nil
}
