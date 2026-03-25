package feed

import (
	"github.com/google/wire"
	"go.uber.org/zap"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/conf"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/kline"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
)

// ProvideMassiveClient provides a Massive WebSocket client.
func ProvideMassiveClient(cfg *conf.Config) *MassiveClient {
	return NewMassiveClient(cfg.Polygon.APIKey, cfg.Polygon.Symbols)
}

// ProvideWorker provides a feed worker with K-line accumulation.
func ProvideWorker(client *MassiveClient, updateQuote *app.UpdateQuoteUsecase, tickAcc *kline.TickAccumulator, logger *zap.Logger) *Worker {
	return NewWorker(client, updateQuote, tickAcc, logger)
}

// ProviderSet is the Wire provider set for feed package.
var ProviderSet = wire.NewSet(
	ProvideMassiveClient,
	ProvideWorker,
)
