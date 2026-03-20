# AMS -- Account Management Service

## Domain Scope

Authentication, user registration, KYC/AML pipeline, notification service, and full account lifecycle management for the brokerage platform. This is the root identity service -- every other service depends on AMS for auth tokens and account verification.

Responsibilities:
- JWT RS256 token issuance (15-min access / 7-day refresh)
- User registration with dual-jurisdiction KYC (US SSN + HK HKID)
- KYC document collection, verification, and status state machine
- AML screening (OFAC SDN + HK designated persons list)
- Account status management (PENDING / ACTIVE / SUSPENDED / CLOSED)
- Notification dispatch (push, SMS, email) for account and compliance events
- Session management and device binding

## Tech Stack

- **Language**: Go 1.22+
- **Database**: MySQL 8.0+ (accounts, KYC records, notifications)
- **Cache**: Redis 7+ (sessions, token blacklist, rate limiting)
- **RPC**: gRPC (inter-service), REST (client-facing via gateway)
- **API**: `api/grpc/` (gRPC), `api/rest/` (OpenAPI)

## Doc Index

| Path | Content |
|------|---------|
| `docs/prd/` | Domain PRDs -- KYC rules, account lifecycle (TBD) |
| `docs/specs/` | Tech specs -- auth flow, KYC pipeline design |
| `docs/specs/*.tracker.md` | 实现跟踪文件（动态进度 + 验收记录） |
| `docs/active-features.yaml` | 域级功能实现进度仪表盘 |
| `docs/patches.yaml` | Patch 注册表（活跃补丁 + 技术债） |
| `docs/specs/api/grpc/` | gRPC proto definitions |
| `docs/specs/api/rest/` | REST OpenAPI specs (TBD) |
| `docs/threads/` | Collaboration threads for AMS decisions |
| `src/internal/` | Implementation (TBD) |

## Dependencies

### Upstream
None -- AMS is the root service for identity and auth.

### Downstream (consumers of AMS)
- **Trading Engine** -- validates account status + auth before order submission
- **Fund Transfer** -- verifies KYC tier for withdrawal limits
- **Market Data** -- authenticates WebSocket connections
- **Mobile** -- login, registration, KYC screens
- **Admin Panel** -- KYC review queue, user management

### Contracts
- `docs/contracts/ams-to-trading.md` -- account status, auth token validation
- `docs/contracts/ams-to-fund.md` -- KYC tier, account verification

## Domain Agent

**Agent**: `.claude/agents/ams-engineer.md`
Specialist in Go backend, auth systems, KYC/AML compliance, and notification infrastructure.

## Key Compliance Rules

1. **PII encryption at rest** -- SSN, HKID, passport number, DOB encrypted with AES-256-GCM before DB storage
2. **PII masking in logs** -- never log full SSN/HKID; use masking utility for all user data
3. **Dual-jurisdiction KYC** -- US accounts require SSN + W-8BEN; HK accounts require HKID + proof of address
4. **FINRA Rule 4511** -- all account records retained for 7 years minimum
5. **SFC KYC Guidelines** -- identity verification, beneficial ownership, investor suitability
6. **Token security** -- RS256 signing, device-bound sessions, token blacklist on revocation
7. **Audit trail** -- every account state change produces an immutable audit record
