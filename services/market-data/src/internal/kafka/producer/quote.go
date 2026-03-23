// Package producer provides typed Kafka producer interfaces.
// These write to the outbox table — actual Kafka publishing is done by the outbox worker.
package producer

// Market-specific quote topics — partitioned by symbol hash.
// Spec: data-flow.md §Kafka Topic 配置 — US and HK quotes use separate topics
// so that downstream consumers (trading-engine, analytics) can subscribe to a single market.
const (
	QuoteTopicUS = "market-data.quotes.us"
	QuoteTopicHK = "market-data.quotes.hk"
)

// Trade topics for tick data persistence.
const (
	TradeTopicUS = "market-data.trades.us"
	TradeTopicHK = "market-data.trades.hk"
)

// KLine event topics for admin panel charts.
const (
	KLineTopicUS = "market-data.klines.us"
	KLineTopicHK = "market-data.klines.hk"
)

// MarketStatusTopic broadcasts open/close/HALT events to all services.
const MarketStatusTopic = "market-data.status"

// DLQTopic is the dead letter queue for events that exceed the retry limit.
const DLQTopic = "market-data.dlq"

// QuoteTopicForMarket returns the correct quote topic for the given market string ("US" or "HK").
func QuoteTopicForMarket(market string) string {
	if market == "HK" {
		return QuoteTopicHK
	}
	return QuoteTopicUS
}
