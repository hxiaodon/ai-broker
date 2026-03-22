package search

import (
	"github.com/google/wire"
)

// ProviderSet is the Wire provider set for the search subdomain.
var ProviderSet = wire.NewSet(
	// Infra
	NewMySQLStockSearchRepo,
	NewRedisHotSearchRepo,
	wire.Bind(new(StockSearchRepo), new(*MySQLStockSearchRepo)),
	wire.Bind(new(HotSearchRepo), new(*RedisHotSearchRepo)),

	// App
	NewSearchStocksUsecase,
	NewGetHotSearchUsecase,

	// Handler
	NewHandler,
)
