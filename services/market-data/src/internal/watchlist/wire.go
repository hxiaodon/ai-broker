package watchlist

import (
	"github.com/google/wire"
)

// ProviderSet is the Wire provider set for the watchlist subdomain.
var ProviderSet = wire.NewSet(
	// Infra
	NewMySQLWatchlistRepo,
	wire.Bind(new(WatchlistRepo), new(*MySQLWatchlistRepo)),

	// App
	NewGetWatchlistUsecase,
	NewAddToWatchlistUsecase,
	NewRemoveFromWatchlistUsecase,

	// Handler
	NewHandler,
)
