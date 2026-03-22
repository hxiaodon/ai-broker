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

// Worker polls the outbox_events table and publishes pending events to Kafka.
type Worker struct {
	db       *gorm.DB
	writer   *kafka.Writer
	logger   *zap.Logger
	interval time.Duration
}

// NewWorker creates a new outbox Worker.
func NewWorker(db *gorm.DB, writer *kafka.Writer, logger *zap.Logger) *Worker {
	return &Worker{
		db:       db,
		writer:   writer,
		logger:   logger,
		interval: 500 * time.Millisecond,
	}
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

func (outboxEvent) TableName() string { return "outbox_events" }

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
	var events []outboxEvent
	result := w.db.WithContext(ctx).
		Where("status = ?", "PENDING").
		Order("created_at ASC").
		Limit(100).
		Find(&events)
	if result.Error != nil {
		return fmt.Errorf("outbox query pending: %w", result.Error)
	}

	for i := range events {
		if err := w.publishEvent(ctx, &events[i]); err != nil {
			w.logger.Error("outbox publish event",
				zap.Int64("event_id", events[i].ID),
				zap.String("topic", events[i].Topic),
				zap.Error(err),
			)
			// Mark as FAILED after 3 retries.
			events[i].RetryCount++
			status := "PENDING"
			if events[i].RetryCount >= 3 {
				status = "FAILED"
			}
			w.db.WithContext(ctx).Model(&events[i]).Updates(map[string]interface{}{
				"status":      status,
				"retry_count": events[i].RetryCount,
			})
			continue
		}

		now := time.Now().UTC()
		w.db.WithContext(ctx).Model(&events[i]).Updates(map[string]interface{}{
			"status":       "PUBLISHED",
			"published_at": now,
		})
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
