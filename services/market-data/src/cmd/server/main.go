package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/brokerage/market-service/internal/api"
	"github.com/brokerage/market-service/internal/config"
	"github.com/brokerage/market-service/internal/middleware"
	"github.com/brokerage/market-service/internal/repository"
	"github.com/brokerage/market-service/internal/service"
	"github.com/brokerage/market-service/internal/websocket"
	"github.com/brokerage/market-service/pkg/cache"
	"github.com/brokerage/market-service/pkg/database"
	"github.com/brokerage/market-service/pkg/kafka"
	"github.com/brokerage/market-service/pkg/polygon"
	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg, err := config.Load("config/config.yaml")
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// 初始化数据库
	if err := database.Init(&cfg.Database); err != nil {
		log.Fatalf("Failed to init database: %v", err)
	}
	defer database.Close()

	// 初始化 Redis
	if err := cache.Init(&cfg.Redis); err != nil {
		log.Fatalf("Failed to init redis: %v", err)
	}
	defer cache.Close()

	// 初始化 Polygon 客户端
	polygonClient := polygon.NewClient(&cfg.Polygon)

	// 初始化 Repository
	db := database.GetDB()
	stockRepo := repository.NewStockRepository(db)
	quoteRepo := repository.NewQuoteRepository(db)
	klineRepo := repository.NewKlineRepository(db)
	watchlistRepo := repository.NewWatchlistRepository(db)
	newsRepo := repository.NewNewsRepository(db)
	financialRepo := repository.NewFinancialRepository(db)
	hotSearchRepo := repository.NewHotSearchRepository(db)

	// 初始化 Service
	marketService := service.NewMarketService(
		stockRepo,
		quoteRepo,
		klineRepo,
		watchlistRepo,
		newsRepo,
		financialRepo,
		hotSearchRepo,
		polygonClient,
	)

	// 初始化 Handler
	marketHandler := api.NewMarketHandler(marketService)

	// 初始化 WebSocket Hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// 初始化 WebSocket Handler
	wsHandler := websocket.NewHandler(wsHub)

	// 根据配置选择数据源
	var kafkaConsumer *kafka.Consumer
	if len(cfg.Kafka.Brokers) > 0 {
		// 生产环境：使用 Kafka 消费实时行情
		kafkaConsumer = kafka.NewConsumer(
			cfg.Kafka.Brokers,
			cfg.Kafka.Topic,
			cfg.Kafka.GroupID,
			wsHub,
		)
		ctx := context.Background()
		go func() {
			if err := kafkaConsumer.Start(ctx); err != nil {
				log.Printf("Kafka consumer error: %v", err)
			}
		}()
		log.Println("Kafka consumer started (production mode)")
	} else {
		// 开发环境：使用 Mock 推送器
		mockPusher := websocket.NewMockPusher(wsHub, db)
		mockPusher.Start()
		log.Println("Mock data pusher started (development mode)")
	}

	// 设置 Gin 模式
	gin.SetMode(cfg.Server.Mode)

	// 创建路由
	router := gin.Default()

	// 全局中间件
	router.Use(middleware.CORSMiddleware(
		cfg.CORS.AllowedOrigins,
		cfg.CORS.AllowedMethods,
		cfg.CORS.AllowedHeaders,
	))

	// 健康检查
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok",
			"time":   time.Now().Unix(),
		})
	})

	// API 路由
	v1 := router.Group("/api/v1")
	{
		market := v1.Group("/market")
		// 应用认证中间件
		market.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		{
			// 股票列表
			market.GET("/stocks", marketHandler.GetStockList)
			// 股票详情
			market.GET("/stocks/:symbol", marketHandler.GetStockDetail)
			// K线数据
			market.GET("/kline/:symbol", marketHandler.GetKlineData)
			// 搜索股票
			market.GET("/search", marketHandler.SearchStocks)
			// 热门搜索
			market.GET("/hot-searches", marketHandler.GetHotSearches)
			// 股票新闻
			market.GET("/news/:symbol", marketHandler.GetStockNews)
			// 财报数据
			market.GET("/financials/:symbol", marketHandler.GetFinancials)
			// 自选股管理
			market.POST("/watchlist", marketHandler.AddToWatchlist)
			market.DELETE("/watchlist/:symbol", marketHandler.RemoveFromWatchlist)
			// WebSocket 实时行情
			market.GET("/realtime", wsHandler.ServeWS)
		}
	}

	// 创建 HTTP 服务器
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	srv := &http.Server{
		Addr:    addr,
		Handler: router,
	}

	// 启动服务器
	go func() {
		log.Printf("Starting server on %s", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// 优雅关闭
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// 关闭 Kafka 消费者
	if kafkaConsumer != nil {
		if err := kafkaConsumer.Close(); err != nil {
			log.Printf("Failed to close Kafka consumer: %v", err)
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
