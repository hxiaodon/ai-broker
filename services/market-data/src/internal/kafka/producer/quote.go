// Package producer provides typed Kafka producer interfaces.
// These write to the outbox table — actual Kafka publishing is done by the outbox worker.
package producer

// QuoteTopic is the Kafka topic for quote update events.
const QuoteTopic = "brokerage.market-data.quote.updated"

// QuoteRetryTopic is the retry topic for failed quote events.
const QuoteRetryTopic = "brokerage.market-data.quote.updated.retry"

// QuoteDLQTopic is the dead letter queue for quote events that exceeded retry limit.
const QuoteDLQTopic = "brokerage.market-data.quote.updated.dlq"
