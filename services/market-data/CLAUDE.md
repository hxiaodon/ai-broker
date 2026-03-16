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
| `docs/README-INDEX.md` | **Start here** — scenario-based loading guide, key conventions, todo list |
| `docs/specs/market-data-system.md` | System architecture v2.1: §0 compliance prerequisites, feed handler, processing engine, corporate actions (Appendix C), stale handling (Appendix D), MySQL DDL, Redis/Kafka design, historical backfill (§14) |
| `docs/specs/market-api-spec.md` | REST API v2.1: all 10 endpoints, `is_stale` field, change/change_pct basis definition, adjusted price notes |
| `docs/specs/websocket-mock.md` | WebSocket protocol v2.1: full auth flow (message-based, not URL param), dual-track push (registered/guest), `is_stale` field |
| `docs/specs/data-flow.md` | Data flow v2.1: feed→engine→Redis→WS dual-track, Kafka topics, cold-start backfill procedure |
| `docs/references/market-data-industry-research.md` | Industry research: licensing (Polygon Poly.feed+, CTA/UTP), price adjustment formulas, NBBO/SIP, stale thresholds, open-source references |
| `docs/threads/` | Collaboration threads |
| `docs/specs/api/grpc/market_data.proto` | Protobuf message definitions |
| `src/scripts/init_db.sql` | MySQL schema and seed data (needs update to v2.1 DDL) |
| `src/config/config.yaml` | Service configuration |

## Code Layout

```
src/
├── cmd/server/main.go         -- Entry point
├── internal/api/              -- HTTP handlers
├── internal/service/          -- Business logic
├── internal/repository/       -- MySQL data access (quote, kline, stock, watchlist, news, financial, hot_search)
├── internal/websocket/        -- WebSocket hub, handler, mock pusher
├── internal/config/           -- Config loading
├── pkg/cache/                 -- Redis wrapper
├── pkg/database/              -- MySQL connection
├── pkg/kafka/                 -- Kafka consumer
├── pkg/polygon/               -- Polygon API client
└── api/grpc/market_data.pb.go -- Generated protobuf code
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

1. **Sub-second quote delivery** -- feed-to-client latency target < 500ms (P99, registered users)
2. **Market hours awareness** -- NYSE 9:30-16:00 ET, NASDAQ extended hours, HKEX 9:30-16:00 HKT
3. **Tick data retention** -- 5 years minimum (SEC/SFC audit requirements)
4. **No financial calculation with float** -- use shopspring/decimal for any price arithmetic
5. **Rate limiting** -- 100 req/s per IP for quote endpoints (public)
6. **Stale data — two-tier threshold** -- 1s for trading risk control (`is_stale` flag blocks market orders); 5s for display warning; see `docs/specs/market-data-system.md` Appendix D
7. **Price adjustment (corporate actions)** -- historical klines use split+dividend backward adjustment; real-time quotes and change/change_pct use unadjusted prices; change basis = previous Regular Session close (16:00 ET); see Appendix C
8. **Market data licensing (P0 blocker)** -- standard Polygon API key prohibits redistribution to end users; must use Polygon Poly.feed+ or direct NYSE/Nasdaq Vendor Agreement before production launch; see §0 of market-data-system.md and docs/references/market-data-industry-research.md §1
9. **Index data** -- S&P 500/DJIA/Nasdaq indices require separate licensing; Phase 1 uses ETF proxies (SPY/QQQ/DIA); display must label as "ETF tracking XXX", not the index itself
10. **Guest delayed quotes** -- must label every price with "Delayed 15 min"; implement via DelayedQuoteRingBuffer (T-15min snapshot), not by holding live messages in memory
