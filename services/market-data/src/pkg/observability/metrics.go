// Package observability provides Prometheus metrics for the market-data service.
package observability

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	// RequestDuration measures HTTP/gRPC request latency by method and status.
	RequestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "market_data",
		Name:      "request_duration_seconds",
		Help:      "Request duration in seconds by method and status.",
		Buckets:   prometheus.DefBuckets,
	}, []string{"method", "status"})

	// KafkaPublished counts Kafka messages published by topic.
	KafkaPublished = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: "market_data",
		Name:      "kafka_published_total",
		Help:      "Total Kafka messages published by topic.",
	}, []string{"topic"})

	// KafkaConsumed counts Kafka messages consumed by topic and status.
	KafkaConsumed = promauto.NewCounterVec(prometheus.CounterOpts{
		Namespace: "market_data",
		Name:      "kafka_consumed_total",
		Help:      "Total Kafka messages consumed by topic and status.",
	}, []string{"topic", "status"})

	// DBQueryDuration measures database query latency by query name.
	DBQueryDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Namespace: "market_data",
		Name:      "db_query_duration_seconds",
		Help:      "Database query duration in seconds by query name.",
		Buckets:   prometheus.DefBuckets,
	}, []string{"query"})

	// ActiveConns tracks active WebSocket connections.
	ActiveConns = promauto.NewGauge(prometheus.GaugeOpts{
		Namespace: "market_data",
		Name:      "active_connections",
		Help:      "Number of active WebSocket connections.",
	})
)
