# Fund Transfer Service

## Domain Scope

Deposit and withdrawal (出入金) flows, bank channel integration, reconciliation, AML screening, and double-entry ledger for the brokerage platform. Handles real money movement between user bank accounts and the brokerage custodial account.

Responsibilities:
- Deposit flows: ACH (US), Wire Transfer, FPS (HK)
- Withdrawal flows with tiered approval workflow (auto / manual / compliance escalation)
- Bank account binding with same-name verification and cool-down period
- AML screening on every transfer (OFAC + AMLO)
- CTR auto-filing for transactions > $10,000 USD / HK$120,000
- Double-entry ledger with append-only integrity
- Daily 3-way reconciliation (internal ledger vs bank statement vs custodian)
- Settlement-aware withdrawal calculation (exclude unsettled proceeds)

## Tech Stack

- **Language**: Go 1.22+
- **Database**: MySQL 8.0+ (ledger, transfer records, bank accounts, AML results)
- **Cache**: Redis 7+ (idempotency key cache, withdrawal limits)
- **Message Queue**: Kafka (transfer events, settlement notifications from Trading)
- **RPC**: gRPC (inter-service), REST (client-facing via gateway)

## Doc Index

| Path | Content |
|------|---------|
| `docs/prd/` | Domain PRDs -- deposit/withdrawal rules, AML (TBD) |
| `docs/specs/fund-transfer-system.md` | System architecture and tech design |
| `docs/threads/` | Collaboration threads |
| `api/grpc/` | gRPC proto definitions |
| `api/rest/` | REST OpenAPI specs (TBD) |
| `migrations/` | MySQL schema migrations |
| `internal/` | Implementation: transfer, bank, compliance, ledger, reconciliation |

## Dependencies

### Upstream
- **AMS** -- KYC tier verification, account status, same-name validation
- **Trading Engine** -- settlement events trigger fund credit; buying power queries

### Downstream
- **Mobile** -- deposit/withdrawal screens, balance display
- **Admin Panel** -- fund approval queue, reconciliation reports, SAR management

### Contracts
- `docs/contracts/ams-to-fund.md` -- KYC tier, account verification
- `docs/contracts/trading-to-fund.md` -- settlement instructions, buying power

## Domain Agent

**Agent**: `.claude/agents/fund-engineer.md`
Specialist in payment systems, bank channel integration, AML/compliance, and financial ledger design.

## Key Compliance Rules

1. **Same-name account principle** -- deposits/withdrawals only to/from accounts matching KYC name
2. **Mandatory AML screening** -- every transfer screened against OFAC SDN + HK designated persons
3. **CTR filing** -- auto-report transactions > $10,000 USD / HK$120,000
4. **Structuring detection** -- flag split transactions that appear to avoid CTR threshold
5. **Settlement-aware withdrawals** -- only settled cash is withdrawable (T+1 US / T+2 HK)
6. **Double-entry bookkeeping** -- every fund movement has matching debit + credit entries
7. **Ledger integrity** -- append-only; corrections via reversing entries; sum invariant enforced
8. **Idempotency** -- every transfer request requires UUID idempotency key (72-hour cache)
9. **Bank account encryption** -- account numbers encrypted at rest with AES-256-GCM
10. **Record retention** -- transfer records 7 years, AML results 7 years, ledger entries indefinite
