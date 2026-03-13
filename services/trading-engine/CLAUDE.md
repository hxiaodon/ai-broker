# Trading Engine Service

## Domain Scope

Order management system (OMS), smart order routing, FIX protocol connectivity, pre-trade risk controls, margin calculation, position management, P&L tracking, and settlement for US (NYSE/NASDAQ) and HK (HKEX) equities.

Responsibilities:
- Order lifecycle: PENDING -> SUBMITTED -> PARTIAL_FILL -> FILLED / CANCELLED / REJECTED
- Smart order routing to exchanges via FIX 4.4 protocol
- Pre-trade risk checks (buying power, position limits, regulatory rules)
- Margin calculation and maintenance margin monitoring
- Real-time position tracking and unrealized P&L
- Settlement processing (T+1 US / T+2 HK)
- Pattern Day Trader (PDT) detection and enforcement

## Tech Stack

- **Language**: Go 1.22+
- **Database**: MySQL 8.0+ (orders, positions, settlement records)
- **Cache**: Redis 7+ (order dedup, buying power cache, real-time positions)
- **Message Queue**: Kafka (order events, fill notifications, settlement events)
- **Protocol**: FIX 4.4 (exchange connectivity)
- **RPC**: gRPC (inter-service), REST (client-facing via gateway)

## Doc Index

| Path | Content |
|------|---------|
| `docs/prd/` | Domain PRDs -- order lifecycle, risk rules, settlement (TBD) |
| `docs/specs/trading-system.md` | System architecture and tech design |
| `docs/threads/` | Collaboration threads for trading decisions |
| `proto/trading.proto` | gRPC service definitions |
| `migrations/` | MySQL schema migrations |
| `internal/` | Implementation: order, risk, routing, fix, margin, position, settlement |

## Dependencies

### Upstream
- **AMS** -- auth token validation, account status check before order submission
- **Market Data** -- real-time quotes for price validation and risk checks

### Downstream
- **Fund Transfer** -- settlement triggers fund movements; buying power affects withdrawals
- **Mobile** -- order status updates, position/P&L display
- **Admin Panel** -- order monitoring, risk alerts

### Contracts
- `docs/contracts/ams-to-trading.md` -- account status, auth verification
- `docs/contracts/trading-to-fund.md` -- settlement instructions, buying power queries

## Domain Agent

**Agent**: `.claude/agents/trading-engineer.md`
Specialist in OMS design, FIX protocol, exchange connectivity, risk management, and settlement systems.

## Key Compliance Rules

1. **shopspring/decimal for ALL money** -- never use float64 for prices, quantities, or P&L
2. **Reg NMS best execution** -- smart order router must demonstrate best price execution
3. **PDT tracking** -- flag accounts with 4+ day trades in 5 business days; enforce $25K minimum equity
4. **Reg SHO** -- short selling restrictions; locate requirement before short orders
5. **Settlement cycles** -- T+1 for US equities (since May 2024), T+2 for HK equities
6. **Idempotency** -- every order submission requires UUID idempotency key; reject duplicates
7. **Audit trail** -- every order state transition logged immutably (SEC Rule 17a-4, 7-year retention)
8. **Pre-trade risk** -- validate buying power, position limits, and symbol eligibility before routing
