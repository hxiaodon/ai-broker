package quote

import (
	"github.com/google/wire"

	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/app"
	"github.com/hxiaodon/ai-broker/services/market-data/internal/quote/domain"
	infraMySQL "github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/mysql"
	infraRedis "github.com/hxiaodon/ai-broker/services/market-data/internal/quote/infra/redis"
)

// ProviderSet is the Wire provider set for the quote subdomain.
var ProviderSet = wire.NewSet(
	// Domain
	ProvideStaleDetector,

	// Infra
	infraMySQL.NewQuoteRepository,
	infraMySQL.NewMarketStatusRepository,
	infraMySQL.NewOutboxRepository,
	infraMySQL.NewTxFunc,
	infraRedis.NewQuoteCacheRepository,
	// NOTE: infraKafka.NewQuoteEventPublisher removed — unused dead code.
	// UpdateQuoteUsecase calls OutboxRepo.InsertEvent directly with producer.QuoteTopicForMarket().

	// Bind infra implementations to domain interfaces
	wire.Bind(new(domain.QuoteRepo), new(*infraMySQL.QuoteRepository)),
	wire.Bind(new(domain.QuoteCacheRepo), new(*infraRedis.QuoteCacheRepository)),
	wire.Bind(new(domain.MarketStatusRepo), new(*infraMySQL.MarketStatusRepository)),
	wire.Bind(new(app.OutboxRepo), new(*infraMySQL.OutboxRepository)),

	// App
	app.NewUpdateQuoteUsecase,
	app.NewGetQuoteUsecase,
	app.NewGetMarketStatusUsecase,

	// Handler
	NewHandler,
)

// ProvideStaleDetector creates a StaleDetector with default thresholds.
func ProvideStaleDetector() *domain.StaleDetector {
	return domain.NewStaleDetector(domain.DefaultStaleThreshold())
}
