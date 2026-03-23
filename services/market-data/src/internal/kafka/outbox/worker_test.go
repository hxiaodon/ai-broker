package outbox_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/segmentio/kafka-go"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/outbox"
)

// ─── Mocks ────────────────────────────────────────────────────────────────────

type mockOutboxDB struct {
	events          []outbox.OutboxEvent
	publishedIDs    []int64
	retriedIDs      []int64
	queryErr        error
	markPublishErr  error
	markRetryErr    error
}

func (m *mockOutboxDB) QueryPending(_ context.Context, limit int) ([]outbox.OutboxEvent, error) {
	if m.queryErr != nil {
		return nil, m.queryErr
	}
	if len(m.events) > limit {
		return m.events[:limit], nil
	}
	return m.events, nil
}

func (m *mockOutboxDB) MarkPublished(_ context.Context, id int64) error {
	if m.markPublishErr != nil {
		return m.markPublishErr
	}
	m.publishedIDs = append(m.publishedIDs, id)
	return nil
}

func (m *mockOutboxDB) MarkRetry(_ context.Context, id int64, _ int) error {
	if m.markRetryErr != nil {
		return m.markRetryErr
	}
	m.retriedIDs = append(m.retriedIDs, id)
	return nil
}

type mockKafkaWriter struct {
	messages []kafka.Message
	writeErr error
}

func (m *mockKafkaWriter) WriteMessages(_ context.Context, msgs ...kafka.Message) error {
	if m.writeErr != nil {
		return m.writeErr
	}
	m.messages = append(m.messages, msgs...)
	return nil
}

// ─── processBatch tests ───────────────────────────────────────────────────────

func TestWorker_ProcessBatch_Success(t *testing.T) {
	db := &mockOutboxDB{
		events: []outbox.OutboxEvent{
			{ID: 1, Topic: "market-data.quotes.us", Payload: []byte(`{"symbol":"AAPL"}`)},
			{ID: 2, Topic: "market-data.quotes.hk", Payload: []byte(`{"symbol":"00700"}`)},
		},
	}
	writer := &mockKafkaWriter{}
	w := outbox.NewWorkerForTest(db, writer, zap.NewNop())

	err := w.ProcessBatchForTest(context.Background())
	require.NoError(t, err)

	assert.Len(t, writer.messages, 2, "both events published to Kafka")
	assert.Equal(t, "market-data.quotes.us", writer.messages[0].Topic)
	assert.Equal(t, "market-data.quotes.hk", writer.messages[1].Topic)

	assert.Equal(t, []int64{1, 2}, db.publishedIDs, "both events marked PUBLISHED")
	assert.Empty(t, db.retriedIDs, "no retries on success")
}

func TestWorker_ProcessBatch_KafkaFailure_IncrementsRetry(t *testing.T) {
	db := &mockOutboxDB{
		events: []outbox.OutboxEvent{
			{ID: 10, Topic: "market-data.quotes.us", Payload: []byte(`{}`), RetryCount: 0},
		},
	}
	writer := &mockKafkaWriter{writeErr: errors.New("kafka: broker unavailable")}
	w := outbox.NewWorkerForTest(db, writer, zap.NewNop())

	err := w.ProcessBatchForTest(context.Background())
	require.NoError(t, err, "processBatch must not fail on Kafka error")

	assert.Empty(t, db.publishedIDs, "event not marked PUBLISHED on Kafka failure")
	assert.Equal(t, []int64{10}, db.retriedIDs, "event marked for retry")
}

func TestWorker_ProcessBatch_ThirdRetry_MarksFailed(t *testing.T) {
	// After 3 retries, MarkRetry receives retryCount=3 and sets status=FAILED.
	db := &mockOutboxDB{
		events: []outbox.OutboxEvent{
			{ID: 20, Topic: "market-data.quotes.us", Payload: []byte(`{}`), RetryCount: 2},
		},
	}
	writer := &mockKafkaWriter{writeErr: errors.New("kafka: timeout")}
	w := outbox.NewWorkerForTest(db, writer, zap.NewNop())

	err := w.ProcessBatchForTest(context.Background())
	require.NoError(t, err)

	assert.Equal(t, []int64{20}, db.retriedIDs, "event retried (will be marked FAILED by MarkRetry)")
}

func TestWorker_ProcessBatch_EmptyBatch_NoOp(t *testing.T) {
	db := &mockOutboxDB{events: []outbox.OutboxEvent{}}
	writer := &mockKafkaWriter{}
	w := outbox.NewWorkerForTest(db, writer, zap.NewNop())

	err := w.ProcessBatchForTest(context.Background())
	require.NoError(t, err)

	assert.Empty(t, writer.messages, "no Kafka writes on empty batch")
	assert.Empty(t, db.publishedIDs)
}

func TestWorker_Run_ContextCancellation_ExitsCleanly(t *testing.T) {
	db := &mockOutboxDB{}
	writer := &mockKafkaWriter{}
	w := outbox.NewWorkerForTest(db, writer, zap.NewNop())

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	err := w.Run(ctx)
	assert.ErrorIs(t, err, context.DeadlineExceeded, "Run must return ctx.Err() on cancellation")
}

