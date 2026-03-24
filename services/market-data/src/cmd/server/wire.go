//go:build wireinject
// +build wireinject

package main

import (
	"github.com/google/wire"
	goredis "github.com/redis/go-redis/v9"
	"github.com/segmentio/kafka-go"
	"go.uber.org/zap"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/conf"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/feed"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/kline"
	kafkaOutbox "github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/outbox"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/search"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/server"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/watchlist"
)

func initApp(cfg *conf.Config, logger *zap.Logger) (*App, func(), error) {
	panic(wire.Build(
		// Infrastructure providers
		ProvideDB,
		ProvideRedis,
		ProvideKafkaWriter,
		ProvideDLQTopic,

		// Subdomain provider sets
		quote.ProviderSet,
		kline.ProviderSet,
		watchlist.ProviderSet,
		search.ProviderSet,

		// Feed handler
		feed.ProviderSet,

		// Kafka outbox
		kafkaOutbox.NewWorker,

		// Transport layer
		server.ProviderSet,
		ProvideHTTPAddr,
		ProvideGRPCAddr,

		// App lifecycle
		NewApp,
	))
}

// ProvideDB creates a GORM DB connection.
func ProvideDB(cfg *conf.Config) (*gorm.DB, func(), error) {
	db, err := gorm.Open(mysql.Open(cfg.Data.MySQL.DSN), &gorm.Config{})
	if err != nil {
		return nil, nil, err
	}
	sqlDB, err := db.DB()
	if err != nil {
		return nil, nil, err
	}
	cleanup := func() {
		_ = sqlDB.Close()
	}
	return db, cleanup, nil
}

// ProvideRedis creates a Redis client.
func ProvideRedis(cfg *conf.Config) (*goredis.Client, func(), error) {
	rdb := goredis.NewClient(&goredis.Options{
		Addr:     cfg.Data.Redis.Addr,
		Password: cfg.Data.Redis.Password,
		DB:       cfg.Data.Redis.DB,
	})
	cleanup := func() {
		_ = rdb.Close()
	}
	return rdb, cleanup, nil
}

// ProvideKafkaWriter creates a Kafka writer for the outbox worker.
func ProvideKafkaWriter(cfg *conf.Config) *kafka.Writer {
	return &kafka.Writer{
		Addr:     kafka.TCP(cfg.Kafka.Brokers...),
		Balancer: &kafka.LeastBytes{},
	}
}

// ProvideDLQTopic extracts DLQ topic from config.
func ProvideDLQTopic(cfg *conf.Config) string {
	if cfg.Kafka.DLQTopic == "" {
		return "market-data.dlq"
	}
	return cfg.Kafka.DLQTopic
}

// ProvideHTTPAddr extracts the HTTP address from config.
func ProvideHTTPAddr(cfg *conf.Config) server.HTTPAddr {
	return server.HTTPAddr(cfg.Server.HTTP.Addr)
}

// ProvideGRPCAddr extracts the gRPC address from config.
func ProvideGRPCAddr(cfg *conf.Config) server.GRPCAddr {
	return server.GRPCAddr(cfg.Server.GRPC.Addr)
}
