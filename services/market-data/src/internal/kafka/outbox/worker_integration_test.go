// Package outbox_test contains integration tests for the outbox worker.
// Requires: `docker compose up -d` from services/market-data/ before running.
//
// Run with: go test ./internal/kafka/outbox/... -count=1 -v
// Skip in CI short mode: go test ./... -short
package outbox_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/segmentio/kafka-go"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/outbox"
)

func mysqlDSN() string {
	if v := os.Getenv("TEST_MYSQL_DSN"); v != "" {
		return v
	}
	return "root:root@tcp(127.0.0.1:3306)/market_data_db?parseTime=true&loc=UTC&time_zone=%27%2B00%3A00%27&charset=utf8mb4"
}

func kafkaAddr() string {
	if v := os.Getenv("TEST_KAFKA_ADDR"); v != "" {
		return v
	}
	return "127.0.0.1:9092"
}

func setupDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(mysql.Open(mysqlDSN()), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	require.NoError(t, err, "connect to MySQL")
	t.Cleanup(func() {
		sqlDB, _ := db.DB()
		_ = sqlDB.Close()
	})
	return db
}

func setupKafkaWriter(t *testing.T) *kafka.Writer {
	t.Helper()
	w := &kafka.Writer{
		Addr:     kafka.TCP(kafkaAddr()),
		Balancer: &kafka.Hash{},
	}
	t.Cleanup(func() { _ = w.Close() })
	return w
}

func TestWorkerIntegration_OutboxToKafka_EndToEnd(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}

	db := setupDB(t)
	writer := setupKafkaWriter(t)
	ctx := context.Background()

	// Create topic if not exists (Kafka auto-create may be disabled)
	testTopic := "market-data.quotes.us"
	conn, err := kafka.DialLeader(ctx, "tcp", kafkaAddr(), testTopic, 0)
	if err != nil {
		// Topic doesn't exist, create it
		controller, err := kafka.Dial("tcp", kafkaAddr())
		require.NoError(t, err, "connect to Kafka controller")
		defer controller.Close()

		err = controller.CreateTopics(kafka.TopicConfig{
			Topic:             testTopic,
			NumPartitions:     1,
			ReplicationFactor: 1,
		})
		if err != nil {
			t.Logf("create topic warning (may already exist): %v", err)
		}
	} else {
		conn.Close()
	}

	// Insert a PENDING event into outbox_events
	testPayload := []byte(`{"symbol":"AAPL","price":"150.25"}`)
	result := db.Exec(
		"INSERT INTO outbox_events (event_id, event_type, correlation_id, topic, payload, status, created_at) VALUES (?, ?, ?, ?, ?, 'PENDING', NOW(6))",
		"test-event-001", "QuoteUpdated.v1", "test-corr-001", testTopic, testPayload,
	)
	require.NoError(t, result.Error, "insert test outbox event")

	// Run worker for one batch
	logger := zap.NewExample()
	w := outbox.NewWorker(db, writer, "market-data.dlq", logger)
	err = w.ProcessBatchForTest(ctx)
	require.NoError(t, err, "processBatch must succeed")

	// Verify event marked PUBLISHED
	var status string
	db.Raw("SELECT status FROM outbox_events WHERE event_id = ?", "test-event-001").Scan(&status)
	assert.Equal(t, "PUBLISHED", status, "event must be marked PUBLISHED after Kafka write")

	// Cleanup
	db.Exec("DELETE FROM outbox_events WHERE event_id = ?", "test-event-001")
}

func TestWorkerIntegration_Run_ContextCancellation(t *testing.T) {
	if testing.Short() {
		t.Skip("integration test skipped in short mode")
	}

	db := setupDB(t)
	writer := setupKafkaWriter(t)
	w := outbox.NewWorker(db, writer, "market-data.dlq", zap.NewNop())

	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()

	err := w.Run(ctx)
	assert.ErrorIs(t, err, context.DeadlineExceeded, "Run must exit cleanly on ctx cancellation")
}
