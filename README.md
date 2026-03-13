# Brokerage Trading App — AI Agent Team

A cross-border securities brokerage trading application for US and Hong Kong stock markets, **built almost entirely by a team of 15 AI agents** powered by Claude Code.

This project demonstrates how a single developer can orchestrate a full AI agent team to design, architect, implement, and review a production-grade financial trading system — from product requirements to working code.

## What This Project Is

A mobile trading platform that enables retail investors to trade US (NYSE/NASDAQ) and HK (HKEX) equities, featuring:

- Real-time market data with WebSocket streaming
- Order management with smart order routing
- Pre-trade risk controls and margin calculation
- Fund deposit/withdrawal with AML/KYC compliance
- Cross-platform mobile app (Flutter, iOS + Android)
- H5 WebView pages for compliance forms and marketing
- Internal admin panel for operations and compliance review

## The AI Agent Team

The project is driven by **15 specialized Claude Code agents** — 8 global cross-cutting agents and 7 domain-scoped agents:

### Global Agents (`.claude/agents/`)

| Agent | Role |
|-------|------|
| **product-manager** | PRDs, user stories, regulatory compliance specs |
| **ui-designer** | Screen layouts, design system, interaction patterns |
| **qa-engineer** | Test plans, automated testing, compliance verification |
| **devops-engineer** | CI/CD, Kubernetes, monitoring |
| **security-engineer** | Threat modeling, encryption, audit |
| **code-reviewer** | Mandatory quality gate for all code changes |
| **data-analyst** | Trading analytics, regulatory reporting |
| **sdd-expert** | Spec taxonomy, repo structure, doc organization |

### Domain Agents (scoped to their service directory)

| Agent | Location | Role |
|-------|----------|------|
| **mobile-engineer** | `mobile/.claude/agents/` | Flutter/Dart, real-time UI, biometrics |
| **h5-engineer** | `mobile/.claude/agents/` | React/TS WebView pages, JSBridge |
| **ams-engineer** | `services/ams/.claude/agents/` | Go auth, KYC/AML, account lifecycle |
| **trading-engineer** | `services/trading-engine/.claude/agents/` | Go OMS, risk, settlement, FIX protocol |
| **market-data-engineer** | `services/market-data/.claude/agents/` | Go quotes, WebSocket, feed handlers |
| **fund-engineer** | `services/fund-transfer/.claude/agents/` | Go deposit/withdrawal, AML, ledger |
| **admin-panel-engineer** | `services/admin-panel/.claude/agents/` | React admin dashboard |

The main Claude session acts as **tech lead / orchestrator** — analyzing tasks, delegating to specialists, and ensuring quality.

## Tech Stack

- **Mobile**: Flutter 3.41.4 / Dart 3.7.x (shared UI for iOS & Android)
- **H5 WebView**: React 18+ / TypeScript 5.x / Vite / Tailwind CSS
- **Backend**: Go 1.22+ (AMS, trading engine, market data, fund transfer)
- **Admin Panel**: React 19+ / TypeScript 5.x / Ant Design Pro 6.x
- **Database**: MySQL 8.0+ / Redis 7+
- **Messaging**: Kafka
- **Protocol**: gRPC + REST, WebSocket (market data), FIX 4.4 (exchange connectivity)

## Project Structure

```
.
├── CLAUDE.md                          # Orchestration guide (routing table)
├── .claude/
│   ├── agents/                        # 8 global cross-cutting agents
│   ├── rules/                         # Financial coding standards, compliance rules
│   └── skills/                        # Custom slash commands
│
├── mobile/                            # ═══ Mobile Domain (Flutter) ═══
│   ├── CLAUDE.md                      # Domain context
│   ├── .claude/agents/                # mobile-engineer, h5-engineer
│   ├── docs/
│   │   ├── prd/                       # Surface PRDs (9 modules)
│   │   ├── design/                    # UI/UX design specs (v1–v3)
│   │   ├── specs/                     # Technical specs (JSBridge, Flutter arch)
│   │   └── threads/                   # Review threads and decisions
│   └── prototypes/                    # Interactive HTML prototypes (13 pages)
│
├── services/
│   ├── ams/                           # ═══ Account Management Service ═══
│   │   ├── CLAUDE.md
│   │   ├── .claude/agents/            # ams-engineer
│   │   └── docs/
│   │
│   ├── trading-engine/                # ═══ Trading Engine ═══
│   │   ├── CLAUDE.md
│   │   ├── .claude/agents/            # trading-engineer
│   │   ├── docs/specs/                # Trading system architecture
│   │   ├── api/grpc/                  # gRPC proto definitions
│   │   ├── internal/                  # OMS, risk, settlement, FIX, margin
│   │   └── migrations/
│   │
│   ├── market-data/                   # ═══ Market Data Service ═══ (most mature)
│   │   ├── CLAUDE.md
│   │   ├── .claude/agents/            # market-data-engineer
│   │   ├── docs/specs/                # Architecture, API spec, data flow
│   │   ├── api/grpc/                  # gRPC proto definitions
│   │   ├── cmd/server/                # Entry point
│   │   ├── internal/                  # API, service, repository, WebSocket
│   │   ├── pkg/                       # Database, cache, Kafka, Polygon client
│   │   └── go.mod                     # ✓ Buildable Go module
│   │
│   ├── fund-transfer/                 # ═══ Fund Transfer (出入金) ═══
│   │   ├── CLAUDE.md
│   │   ├── .claude/agents/            # fund-engineer
│   │   ├── docs/specs/                # Fund transfer architecture
│   │   ├── api/grpc/                  # gRPC proto definitions
│   │   ├── internal/                  # Bank, compliance, ledger, reconciliation
│   │   └── migrations/
│   │
│   └── admin-panel/                   # ═══ Admin Panel ═══
│       ├── CLAUDE.md
│       ├── .claude/agents/            # admin-panel-engineer
│       └── docs/prd/                  # Admin panel PRD
│
├── docs/                              # Cross-domain resources
│   ├── SPEC-ORGANIZATION.md           # SDD spec for repo structure
│   ├── references/                    # Industry research
│   ├── compliance/                    # Cross-jurisdiction compliance
│   ├── contracts/                     # Domain-to-domain API contracts
│   └── threads/                       # Cross-domain discussion threads
│
└── archive/                           # Frozen historical artifacts
    ├── mobile-kotlin-v3/              # Obsolete KMP mobile code
    ├── reviews-legacy/                # Stale platform-specific reviews
    ├── session-reports/               # Agent session delivery reports
    └── skills-metabot/                # Archived MetaBot skills
```

## How It Works

1. A human gives a high-level task (e.g., "design the trading order flow")
2. The orchestrator (main Claude session) reads the relevant domain CLAUDE.md for context
3. It breaks the task down and delegates to domain-scoped specialist agents
4. Agents work autonomously — writing specs, designing UIs, implementing code, reviewing each other's work
5. The human reviews outputs and provides direction

Workflow chains are pre-defined for common patterns:

- **New Feature**: orchestrator → product-manager → specialists → security-engineer → code-reviewer
- **Trading Feature**: orchestrator → product-manager → trading-engineer → mobile-engineer → security-engineer → qa-engineer → code-reviewer
- **Fund Transfer**: orchestrator → product-manager → fund-engineer → admin-panel-engineer → security-engineer → code-reviewer
- **Bug Fix**: orchestrator → specialist → qa-engineer → code-reviewer

## Compliance

The system is designed to comply with:

- **US**: SEC/FINRA rules (Reg NMS, PDT, Rule 17a-4)
- **Hong Kong**: SFC/AMLO requirements (KYC, Travel Rule)
- **Cross-border**: FATCA, dual-jurisdiction KYC, data residency

Compliance rules are enforced at the agent level via `.claude/rules/`.

## Status

> **This is an actively evolving project.** The directory structure, system architecture, tech choices, and agent configurations will continue to change as development progresses.

Current state:

- [x] Product design specs (v1–v3) with interactive prototypes
- [x] 15 AI agents organized by domain (SDD-spec structure)
- [x] System architecture docs (trading, market data, fund transfer)
- [x] Market data service (Go, with WebSocket, MySQL, Redis) — buildable
- [x] Trading engine structure (OMS, risk, settlement, FIX)
- [x] Fund transfer service structure (ledger, AML, reconciliation)
- [x] Domain-isolated repo structure with per-service CLAUDE.md
- [ ] Flutter mobile app implementation
- [ ] H5 WebView pages
- [ ] Full backend API integration
- [ ] Admin panel
- [ ] End-to-end testing
- [ ] Production deployment

## License

MIT
