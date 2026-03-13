# Market Data Service

## Domain Scope

Real-time and historical market data for US (NYSE/NASDAQ) and HK (HKEX) equities. Feed ingestion, quote caching, WebSocket push, K-line aggregation, and tick data storage.

This is the **most mature service** in the repo with working code across all layers.

Responsibilities:
- Feed handlers for external providers (Polygon API for US, HKEX feed for HK)
- Quote cache with sub-second update latency (Redis)
- WebSocket gateway for real-time quote push to mobile clients
- K-line aggregation (1min, 5min, 15min, 30min, 1h, 1D, 1W, 1M)
- Tick data ingestion and partitioned storage
- REST API for snapshots, search, watchlists, financials, news
- Kafka distribution of normalized market events to internal consumers

## Tech Stack

- **Language**: Go 1.22+
- **Database**: MySQL 8.0+ (K-line, stock metadata, watchlists, financials)
- **Cache**: Redis 7+ (real-time quote cache, hot search rankings)
- **Message Queue**: Kafka (market event distribution)
- **Protocol**: WebSocket (client push), Protobuf (wire format), gRPC (inter-service)
- **External**: Polygon API client (`pkg/polygon/`)

## Doc Index

| Path | Content |
|------|---------|
| `docs/README-INDEX.md` | Document index with scenario-based loading guide |
| `docs/specs/market-data-system.md` | System architecture and tech design |
| `docs/specs/market-api-spec.md` | REST API endpoint specifications |
| `docs/specs/data-flow.md` | Kafka vs Mock data source switching |
| `docs/specs/websocket-mock.md` | WebSocket protocol and mock data spec |
| `docs/prd/` | Domain PRDs (TBD) |
| `docs/threads/` | Collaboration threads |
| `proto/market_data.proto` | Protobuf message definitions |
| `scripts/init_db.sql` | MySQL schema and seed data |
| `config/config.yaml` | Service configuration |

## Code Layout

```
cmd/server/main.go         -- Entry point
internal/api/              -- HTTP handlers
internal/service/          -- Business logic
internal/repository/       -- MySQL data access (quote, kline, stock, watchlist, news, financial, hot_search)
internal/websocket/        -- WebSocket hub, handler, mock pusher
internal/config/           -- Config loading
pkg/cache/                 -- Redis wrapper
pkg/database/              -- MySQL connection
pkg/kafka/                 -- Kafka consumer
pkg/polygon/               -- Polygon API client
```

## Dependencies

### Upstream
- **External**: Polygon API (US market data), HKEX feed (HK market data)

### Downstream
- **Trading Engine** -- real-time quotes for price validation and pre-trade risk
- **Mobile** -- quote display, charts, watchlists via REST + WebSocket
- **Admin Panel** -- market monitoring dashboard

## Domain Agent

**Agent**: `.claude/agents/market-data-engineer.md`
Specialist in feed handlers, WebSocket infrastructure, time-series data, and high-throughput quote systems.

## Key Compliance Rules

1. **Sub-second quote delivery** -- feed-to-client latency target < 500ms
2. **Market hours awareness** -- NYSE 9:30-16:00 ET, NASDAQ extended hours, HKEX 9:30-16:00 HKT
3. **Tick data retention** -- 5 years minimum (SEC/SFC audit requirements)
4. **No financial calculation with float** -- use shopspring/decimal for any price arithmetic
5. **Rate limiting** -- 100 req/s per IP for quote endpoints (public)
6. **Data accuracy** -- cross-validate quotes against multiple sources; flag stale data > 5s
