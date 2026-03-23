// Package outbox implements the outbox event relay worker.
// This is the ONLY component allowed to call kafka.Writer.WriteMessages().
// Business logic and handlers must never publish directly to Kafka.
package outbox

import (
	"context"
	"fmt"
	"time"

	"github.com/segmentio/kafka-go"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

// KafkaWriter abstracts kafka.Writer so the worker can be unit-tested without a real broker.
type KafkaWriter interface {
	WriteMessages(ctx context.Context, msgs ...kafka.Message) error
}

// OutboxDB abstracts the DB operations the worker needs, enabling sqlmock in tests.
type OutboxDB interface {
	// QueryPending returns up to limit PENDING events ordered by created_at ASC.
	QueryPending(ctx context.Context, limit int) ([]outboxEvent, error)
	// MarkPublished sets status=PUBLISHED and published_at=now for the given event ID.
	MarkPublished(ctx context.Context, id int64) error
	// MarkRetry increments retry_count. Sets status=FAILED when retry_count >= 3.
	MarkRetry(ctx context.Context, id int64, retryCount int) error
}

// Worker polls the outbox_events table and publishes pending events to Kafka.
type Worker struct {
	db       OutboxDB
	writer   KafkaWriter
	logger   *zap.Logger
	interval time.Duration
}

// outboxEvent maps to the outbox_events table row.
type outboxEvent struct {
	ID          int64     `gorm:"primaryKey"`
	Topic       string    `gorm:"type:varchar(255)"`
	Payload     []byte    `gorm:"type:blob"`
	Status      string    `gorm:"type:varchar(20)"`
	CreatedAt   time.Time
	PublishedAt *time.Time
	RetryCount  int `gorm:"type:tinyint unsigned"`
}

// OutboxEvent is the exported version for tests.
type OutboxEvent = outboxEvent

func (outboxEvent) TableName() string { return "outbox_events" }

// gormOutboxDB wraps *gorm.DB to implement OutboxDB.
type gormOutboxDB struct {
	db *gorm.DB
}

func (g *gormOutboxDB) QueryPending(ctx context.Context, limit int) ([]outboxEvent, error) {
	var events []outboxEvent
	result := g.db.WithContext(ctx).
		Where("status = ?", "PENDING").
		Order("created_at ASC").
		Limit(limit).
		Find(&events)
	if result.Error != nil {
		return nil, fmt.Errorf("outbox query pending: %w", result.Error)
	}
	return events, nil
}

func (g *gormOutboxDB) MarkPublished(ctx context.Context, id int64) error {
	now := time.Now().UTC()
	return g.db.WithContext(ctx).Model(&outboxEvent{ID: id}).Updates(map[string]interface{}{
		"status":       "PUBLISHED",
		"published_at": now,
	}).Error
}

func (g *gormOutboxDB) MarkRetry(ctx context.Context, id int64, retryCount int) error {
	status := "PENDING"
	if retryCount >= 3 {
		status = "FAILED"
	}
	return g.db.WithContext(ctx).Model(&outboxEvent{ID: id}).Updates(map[string]interface{}{
		"status":      status,
		"retry_count": retryCount,
	}).Error
}

// NewWorker creates a new outbox Worker backed by a real *gorm.DB and *kafka.Writer.
func NewWorker(db *gorm.DB, writer *kafka.Writer, logger *zap.Logger) *Worker {
	return &Worker{
		db:       &gormOutboxDB{db: db},
		writer:   writer,
		logger:   logger,
		interval: 500 * time.Millisecond,
	}
}

// newWorkerWithDeps is used in tests to inject mock implementations.
func newWorkerWithDeps(db OutboxDB, writer KafkaWriter, logger *zap.Logger) *Worker {
	return &Worker{
		db:       db,
		writer:   writer,
		logger:   logger,
		interval: 500 * time.Millisecond,
	}
}

// NewWorkerForTest creates a worker with injected dependencies for unit testing.
func NewWorkerForTest(db OutboxDB, writer KafkaWriter, logger *zap.Logger) *Worker {
	return newWorkerWithDeps(db, writer, logger)
}

// ProcessBatchForTest exposes processBatch for unit testing.
func (w *Worker) ProcessBatchForTest(ctx context.Context) error {
	return w.processBatch(ctx)
}

// Run starts the outbox polling loop. Blocks until context is cancelled.
func (w *Worker) Run(ctx context.Context) error {
	w.logger.Info("outbox worker started")
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			w.logger.Info("outbox worker stopped")
			return ctx.Err()
		case <-ticker.C:
			if err := w.processBatch(ctx); err != nil {
				w.logger.Error("outbox worker process batch", zap.Error(err))
			}
		}
	}
}

func (w *Worker) processBatch(ctx context.Context) error {
	events, err := w.db.QueryPending(ctx, 100)
	if err != nil {
		return err
	}

	for i := range events {
		if err := w.publishEvent(ctx, &events[i]); err != nil {
			w.logger.Error("outbox publish event",
				zap.Int64("event_id", events[i].ID),
				zap.String("topic", events[i].Topic),
				zap.Error(err),
			)
			events[i].RetryCount++
			_ = w.db.MarkRetry(ctx, events[i].ID, events[i].RetryCount)
			continue
		}
		_ = w.db.MarkPublished(ctx, events[i].ID)
	}
	return nil
}

func (w *Worker) publishEvent(ctx context.Context, event *outboxEvent) error {
	msg := kafka.Message{
		Topic: event.Topic,
		Value: event.Payload,
		Time:  time.Now().UTC(),
	}
	if err := w.writer.WriteMessages(ctx, msg); err != nil {
		return fmt.Errorf("outbox publish to %s: %w", event.Topic, err)
	}
	return nil
}
