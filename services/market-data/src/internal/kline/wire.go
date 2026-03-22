package kline

import (
	"github.com/google/wire"
)

// ProviderSet is the Wire provider set for the kline subdomain.
var ProviderSet = wire.NewSet(
	// Infra
	NewMySQLKLineRepo,
	wire.Bind(new(KLineRepo), new(*MySQLKLineRepo)),

	// App
	NewAggregateKLineUsecase,
	NewGetKLinesUsecase,

	// Handler
	NewHandler,
)
