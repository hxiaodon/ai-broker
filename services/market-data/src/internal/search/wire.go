package search

import (
	"github.com/google/wire"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/watchlist"
)

// ProviderSet is the Wire provider set for the search subdomain.
var ProviderSet = wire.NewSet(
	// Infra
	NewMySQLStockSearchRepo,
	NewRedisHotSearchRepo,
	wire.Bind(new(StockSearchRepo), new(*MySQLStockSearchRepo)),
	wire.Bind(new(HotSearchRepo), new(*RedisHotSearchRepo)),
	wire.Bind(new(watchlist.StockValidator), new(*MySQLStockSearchRepo)),

	// App
	NewSearchStocksUsecase,
	NewGetHotSearchUsecase,

	// Handler
	NewHandler,
)
