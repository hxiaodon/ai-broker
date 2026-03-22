package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/conf"
	"github.com/hxiaodon/ai-broker/services/market-data/pkg/observability"
)

func main() {
	// Initialize logger.
	logger, err := observability.NewLogger()
	if err != nil {
		fmt.Fprintf(os.Stderr, "init logger: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		_ = logger.Sync()
	}()

	// Load configuration.
	cfgPath := "configs/config.yaml"
	if envPath := os.Getenv("CONFIG_PATH"); envPath != "" {
		cfgPath = envPath
	}
	cfg, err := conf.Load(cfgPath)
	if err != nil {
		logger.Fatal("load config", zap.Error(err))
	}

	// Initialize tracer.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	shutdownTracer, err := observability.InitTracer(ctx, "market-data", cfg.Observability.OTLPEndpoint)
	if err != nil {
		logger.Warn("init tracer (non-fatal, continuing without tracing)", zap.Error(err))
	} else {
		defer func() {
			if shutdownErr := shutdownTracer(ctx); shutdownErr != nil {
				logger.Error("shutdown tracer", zap.Error(shutdownErr))
			}
		}()
	}

	// Wire dependencies and start application.
	app, cleanup, err := initApp(cfg, logger)
	if err != nil {
		logger.Fatal("init app", zap.Error(err))
	}
	defer cleanup()

	// Graceful shutdown.
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if startErr := app.Start(); startErr != nil {
			logger.Fatal("start app", zap.Error(startErr))
		}
	}()

	logger.Info("market-data service started",
		zap.String("http", cfg.Server.HTTP.Addr),
		zap.String("grpc", cfg.Server.GRPC.Addr),
		zap.String("ws", cfg.Server.WS.Addr),
	)

	sig := <-sigCh
	logger.Info("received signal, shutting down", zap.String("signal", sig.String()))
	cancel()

	if stopErr := app.Stop(context.Background()); stopErr != nil {
		logger.Error("stop app", zap.Error(stopErr))
	}
}
