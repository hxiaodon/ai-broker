package main

import (
	"context"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/feed"
	kafkaConsumer "github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/consumer"
	kafkaOutbox "github.com/hxiaodon/ai-broker/services/market-data/internal/kafka/outbox"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/kline"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/server"
)

// App is the application lifecycle container.
type App struct {
	httpSrv         *server.HTTPServer
	grpcSrv         *server.GRPCServer
	wsSrv           *server.WSServer
	wsAddr          server.WSAddr
	feedWorker      *feed.Worker
	outboxWorker    *kafkaOutbox.Worker
	quoteConsumer   *kafkaConsumer.QuoteConsumer
	klineScheduler  *kline.KLineScheduler
	marketScheduler *app.MarketScheduler
	logger          *zap.Logger
	cancel          context.CancelFunc
}

// NewApp creates a new App.
func NewApp(
	httpSrv *server.HTTPServer,
	grpcSrv *server.GRPCServer,
	wsSrv *server.WSServer,
	wsAddr server.WSAddr,
	feedWorker *feed.Worker,
	outboxWorker *kafkaOutbox.Worker,
	quoteConsumer *kafkaConsumer.QuoteConsumer,
	klineScheduler *kline.KLineScheduler,
	marketScheduler *app.MarketScheduler,
	logger *zap.Logger,
) *App {
	return &App{
		httpSrv:         httpSrv,
		grpcSrv:         grpcSrv,
		wsSrv:           wsSrv,
		wsAddr:          wsAddr,
		feedWorker:      feedWorker,
		outboxWorker:    outboxWorker,
		quoteConsumer:   quoteConsumer,
		klineScheduler:  klineScheduler,
		marketScheduler: marketScheduler,
		logger:          logger,
	}
}

// Start starts all servers and background workers.
func (a *App) Start() error {
	ctx, cancel := context.WithCancel(context.Background())
	a.cancel = cancel

	// Start feed worker in background.
	go func() {
		if err := a.feedWorker.Run(ctx); err != nil && ctx.Err() == nil {
			a.logger.Error("feed worker error", zap.Error(err))
		}
	}()

	// Start outbox worker in background.
	go func() {
		if err := a.outboxWorker.Run(ctx); err != nil && ctx.Err() == nil {
			a.logger.Error("outbox worker error", zap.Error(err))
		}
	}()

	// Start Kafka → WebSocket consumer in background.
	go func() {
		if err := a.quoteConsumer.Run(ctx); err != nil && ctx.Err() == nil {
			a.logger.Error("quote consumer error", zap.Error(err))
		}
	}()

	// Start K-line aggregation scheduler in background.
	go func() {
		if err := a.klineScheduler.Run(ctx); err != nil && ctx.Err() == nil {
			a.logger.Error("kline scheduler error", zap.Error(err))
		}
	}()

	// Start market status scheduler in background.
	go func() {
		if err := a.marketScheduler.Run(ctx); err != nil && ctx.Err() == nil {
			a.logger.Error("market scheduler error", zap.Error(err))
		}
	}()

	// Start WebSocket server in background (dedicated HTTP server).
	go func() {
		if err := server.StartWSServer(ctx, string(a.wsAddr), a.wsSrv); err != nil && ctx.Err() == nil {
			a.logger.Error("websocket server error", zap.Error(err))
		}
	}()

	// Start gRPC server in background.
	go func() {
		if err := a.grpcSrv.Start(); err != nil {
			a.logger.Error("grpc server error", zap.Error(err))
		}
	}()

	// Start HTTP server (blocks).
	return a.httpSrv.Start()
}

// Stop gracefully shuts down all servers.
func (a *App) Stop(ctx context.Context) error {
	if a.cancel != nil {
		a.cancel()
	}

	if err := a.httpSrv.Stop(ctx); err != nil {
		a.logger.Error("http server stop", zap.Error(err))
	}
	if err := a.grpcSrv.Stop(ctx); err != nil {
		a.logger.Error("grpc server stop", zap.Error(err))
	}
	return nil
}
