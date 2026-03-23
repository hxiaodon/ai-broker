package kafka_test

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	quotekafka "github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/kafka"
)

type mockOutboxRepo struct {
	events []struct {
		topic   string
		payload []byte
	}
}

func (m *mockOutboxRepo) InsertEvent(_ context.Context, topic string, payload []byte) error {
	m.events = append(m.events, struct {
		topic   string
		payload []byte
	}{topic, payload})
	return nil
}

func TestQuoteEventPublisher_Publish_USMarket(t *testing.T) {
	outbox := &mockOutboxRepo{}
	pub := quotekafka.NewQuoteEventPublisher(outbox)

	err := pub.Publish(context.Background(), domain.MarketUS, "AAPL", []byte(`{"symbol":"AAPL"}`))
	require.NoError(t, err)

	require.Len(t, outbox.events, 1)
	assert.Equal(t, "market-data.quotes.us", outbox.events[0].topic)
}

func TestQuoteEventPublisher_Publish_HKMarket(t *testing.T) {
	outbox := &mockOutboxRepo{}
	pub := quotekafka.NewQuoteEventPublisher(outbox)

	err := pub.Publish(context.Background(), domain.MarketHK, "00700", []byte(`{"symbol":"00700"}`))
	require.NoError(t, err)

	require.Len(t, outbox.events, 1)
	assert.Equal(t, "market-data.quotes.hk", outbox.events[0].topic)
}
