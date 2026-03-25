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
	db         OutboxDB
	writer     KafkaWriter
	dlqWriter  KafkaWriter
	dlqTopic   string
	maxRetries int
	logger     *zap.Logger
	interval   time.Duration
	batchSize  int
	backoff    time.Duration
}

// outboxEvent maps to the outbox_events table row.
type outboxEvent struct {
	ID            int64     `gorm:"primaryKey"`
	Topic         string    `gorm:"type:varchar(255)"`
	Payload       []byte    `gorm:"type:blob"`
	CorrelationID string    `gorm:"type:varchar(64)"`
	Status        string    `gorm:"type:varchar(20)"`
	CreatedAt     time.Time
	PublishedAt   *time.Time
	RetryCount    int `gorm:"type:tinyint unsigned"`
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

// NewWorker creates a new outbox Worker backed by a real *gorm.DB and separate Kafka writers.
// dlqWriter may be nil — when nil, the main writer is used as fallback for DLQ (test convenience).
func NewWorker(db *gorm.DB, writer *kafka.Writer, dlqWriter *kafka.Writer, dlqTopic string, logger *zap.Logger) *Worker {
	var dw KafkaWriter = writer // fallback: same writer
	if dlqWriter != nil {
		dw = dlqWriter
	}
	return &Worker{
		db:         &gormOutboxDB{db: db},
		writer:     writer,
		dlqWriter:  dw,
		dlqTopic:   dlqTopic,
		maxRetries: 3,
		logger:     logger,
		interval:   500 * time.Millisecond,
		batchSize:  100,
		backoff:    0,
	}
}

// newWorkerWithDeps is used in tests to inject mock implementations.
func newWorkerWithDeps(db OutboxDB, writer KafkaWriter, logger *zap.Logger) *Worker {
	return &Worker{
		db:         db,
		writer:     writer,
		dlqWriter:  writer, // reuse writer for DLQ in tests
		dlqTopic:   "market-data.dlq",
		maxRetries: 3,
		logger:     logger,
		interval:   500 * time.Millisecond,
		batchSize:  100,
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
	// Apply backoff if Kafka was slow
	if w.backoff > 0 {
		time.Sleep(w.backoff)
	}

	start := time.Now()
	events, err := w.db.QueryPending(ctx, w.batchSize)
	if err != nil {
		return err
	}

	successCount := 0
	for i := range events {
		if err := w.publishEvent(ctx, &events[i]); err != nil {
			w.logger.Error("outbox publish event",
				zap.Int64("event_id", events[i].ID),
				zap.String("topic", events[i].Topic),
				zap.Error(err),
			)
			events[i].RetryCount++

			// Route to DLQ if max retries reached
			if events[i].RetryCount >= w.maxRetries {
				if dlqErr := w.publishToDLQ(ctx, &events[i], err); dlqErr != nil {
					w.logger.Error("failed to publish to DLQ",
						zap.Int64("event_id", events[i].ID),
						zap.Error(dlqErr))
				}
			}

			if markErr := w.db.MarkRetry(ctx, events[i].ID, events[i].RetryCount); markErr != nil {
				w.logger.Error("failed to mark retry", zap.Error(markErr))
			}
			continue
		}
		successCount++
		if markErr := w.db.MarkPublished(ctx, events[i].ID); markErr != nil {
			w.logger.Error("failed to mark published", zap.Error(markErr))
		}
	}

	// Adjust batch size and backoff based on latency
	latency := time.Since(start)
	w.adjustBackpressure(latency, successCount, len(events))

	return nil
}

func (w *Worker) publishEvent(ctx context.Context, event *outboxEvent) error {
	msg := kafka.Message{
		Topic: event.Topic,
		Value: event.Payload,
		Time:  time.Now().UTC(),
		Headers: []kafka.Header{
			{Key: "correlation_id", Value: []byte(event.CorrelationID)},
		},
	}
	if err := w.writer.WriteMessages(ctx, msg); err != nil {
		return fmt.Errorf("outbox publish to %s: %w", event.Topic, err)
	}
	return nil
}

// publishToDLQ publishes a failed event to the Dead Letter Queue with error metadata.
func (w *Worker) publishToDLQ(ctx context.Context, event *outboxEvent, originalErr error) error {
	dlqMsg := kafka.Message{
		Topic: w.dlqTopic,
		Key:   []byte(fmt.Sprintf("%d", event.ID)),
		Value: event.Payload,
		Time:  time.Now().UTC(),
		Headers: []kafka.Header{
			{Key: "original_topic", Value: []byte(event.Topic)},
			{Key: "event_id", Value: []byte(fmt.Sprintf("%d", event.ID))},
			{Key: "retry_count", Value: []byte(fmt.Sprintf("%d", event.RetryCount))},
			{Key: "error", Value: []byte(originalErr.Error())},
			{Key: "failed_at", Value: []byte(time.Now().UTC().Format(time.RFC3339))},
		},
	}
	if err := w.dlqWriter.WriteMessages(ctx, dlqMsg); err != nil {
		return fmt.Errorf("publish to DLQ: %w", err)
	}
	w.logger.Warn("event routed to DLQ",
		zap.Int64("event_id", event.ID),
		zap.String("original_topic", event.Topic),
		zap.Int("retry_count", event.RetryCount))
	return nil
}

// adjustBackpressure adjusts batch size and backoff based on Kafka latency.
func (w *Worker) adjustBackpressure(latency time.Duration, successCount, totalCount int) {
	avgLatency := latency
	if totalCount > 0 {
		avgLatency = latency / time.Duration(totalCount)
	}

	// If Kafka is slow (>100ms per message), reduce batch size and add backoff
	if avgLatency > 100*time.Millisecond {
		w.batchSize = maxInt(25, w.batchSize/2)
		w.backoff = minDuration(4*time.Second, w.backoff*2)
		if w.backoff == 0 {
			w.backoff = 500 * time.Millisecond
		}
		w.logger.Warn("kafka slow, reducing batch size",
			zap.Duration("latency", avgLatency),
			zap.Int("new_batch_size", w.batchSize),
			zap.Duration("backoff", w.backoff))
	} else if avgLatency < 50*time.Millisecond && w.batchSize < 100 {
		// Kafka is fast, increase batch size and reduce backoff
		w.batchSize = minInt(100, w.batchSize*2)
		w.backoff = maxDuration(0, w.backoff/2)
	}
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func minDuration(a, b time.Duration) time.Duration {
	if a < b {
		return a
	}
	return b
}

func maxDuration(a, b time.Duration) time.Duration {
	if a > b {
		return a
	}
	return b
}
