package producer_test

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/producer"
)

func TestQuoteTopicForMarket_US(t *testing.T) {
	assert.Equal(t, "market-data.quotes.us", producer.QuoteTopicForMarket("US"))
}

func TestQuoteTopicForMarket_HK(t *testing.T) {
	assert.Equal(t, "market-data.quotes.hk", producer.QuoteTopicForMarket("HK"))
}

func TestQuoteTopicForMarket_Unknown_DefaultsToUS(t *testing.T) {
	// Unknown market falls back to US topic (fail-safe; never drop an event).
	assert.Equal(t, "market-data.quotes.us", producer.QuoteTopicForMarket(""))
	assert.Equal(t, "market-data.quotes.us", producer.QuoteTopicForMarket("CN"))
}

func TestTopicConstants_AreDistinct(t *testing.T) {
	// Sanity check: all topic constants must be unique strings.
	topics := []string{
		producer.QuoteTopicUS,
		producer.QuoteTopicHK,
		producer.TradeTopicUS,
		producer.TradeTopicHK,
		producer.KLineTopicUS,
		producer.KLineTopicHK,
		producer.MarketStatusTopic,
		producer.DLQTopic,
	}
	seen := make(map[string]struct{}, len(topics))
	for _, topic := range topics {
		_, dup := seen[topic]
		assert.False(t, dup, "duplicate topic constant: %s", topic)
		seen[topic] = struct{}{}
	}
}
