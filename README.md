# Brokerage Trading App — AI Agent Team

A cross-border securities brokerage trading application for US and Hong Kong stock markets, **built almost entirely by a team of 13 AI agents** powered by Claude Code.

This project demonstrates how a single developer can orchestrate a full AI agent team to design, architect, implement, and review a production-grade financial trading system — from product requirements to working code.

## What This Project Is

A mobile trading platform that enables retail investors to trade US (NYSE/NASDAQ) and HK (HKEX) equities, featuring:

- Real-time market data with WebSocket streaming
- Order management with smart order routing
- Pre-trade risk controls and margin calculation
- Fund deposit/withdrawal with AML/KYC compliance
- Cross-platform mobile app (iOS + Android)

## The AI Agent Team

The entire project is driven by **13 specialized Claude Code agents**, each with domain expertise defined in `.claude/agents/`:

| Agent | Role |
|-------|------|
| **product-manager** | PRDs, user stories, regulatory compliance specs |
| **ui-designer** | Screen layouts, design system, interaction patterns |
| **ios-engineer** | Swift/SwiftUI development |
| **android-engineer** | Kotlin/Jetpack Compose development |
| **trading-engine-engineer** | OMS, order routing, FIX protocol, risk controls |
| **backend-engineer** | API gateway, account service, KYC/AML |
| **fund-transfer-engineer** | Deposit/withdrawal, bank integration, reconciliation |
| **frontend-engineer** | React admin dashboard |
| **qa-engineer** | Test plans, automated testing, compliance verification |
| **devops-engineer** | CI/CD, Kubernetes, monitoring |
| **security-engineer** | Threat modeling, encryption, audit |
| **data-analyst** | Trading analytics, regulatory reporting |
| **code-reviewer** | Mandatory quality gate for all code changes |

The main Claude session acts as **tech lead / orchestrator** — analyzing tasks, delegating to specialists, and ensuring quality.

## Tech Stack

- **Mobile**: Kotlin Multiplatform (KMP) + Compose Multiplatform (shared UI for iOS & Android)
- **Backend**: Go 1.22+ (trading engine, market data, fund transfer)
- **Database**: PostgreSQL + Redis + TimescaleDB
- **Messaging**: Kafka
- **Protocol**: gRPC + REST, FIX 4.4 (exchange connectivity)

## Project Structure

```
.
├── .claude/
│   ├── agents/          # 13 AI agent definitions
│   ├── rules/           # Financial coding standards, compliance rules
│   └── skills/          # Custom slash commands (/build-and-test, /compliance-audit, etc.)
├── backend/
│   └── market-service/  # Market data service (Go)
├── services/
│   ├── trading-engine/  # Order management, risk, settlement (Go)
│   ├── market-data/     # Real-time quotes, WebSocket broadcasting (Go)
│   └── fund-transfer/   # Deposit/withdrawal, AML screening (Go)
├── mobile/              # KMP mobile app (iOS + Android)
│   ├── composeApp/      # Shared Compose Multiplatform UI
│   ├── shared/          # Shared business logic (KMM)
│   ├── androidApp/      # Android entry point
│   └── iosApp/          # iOS entry point
├── prototypes/          # Interactive HTML prototypes
├── docs/
│   ├── design/          # Mobile app design specs (v1, v2, v3)
│   ├── architecture/    # System architecture docs
│   ├── api/             # API specifications
│   └── review/          # Cross-team review records
└── CLAUDE.md            # Orchestration guide for the AI agent team
```

## How It Works

1. A human gives a high-level task (e.g., "design the trading order flow")
2. The orchestrator (main Claude session) breaks it down and delegates to specialists
3. Agents work autonomously — writing specs, designing UIs, implementing code, reviewing each other's work
4. The human reviews outputs and provides direction

Workflow chains are pre-defined for common patterns:

- **New Feature**: orchestrator → product-manager → specialists → security-engineer → code-reviewer
- **Trading Feature**: orchestrator → product-manager → trading-engine-engineer → [ios + android] (parallel) → security-engineer → qa-engineer → code-reviewer
- **Bug Fix**: orchestrator → specialist → qa-engineer → code-reviewer

## Compliance

The system is designed to comply with:

- **US**: SEC/FINRA rules (Reg NMS, PDT, Rule 17a-4)
- **Hong Kong**: SFC/AMLO requirements (KYC, Travel Rule)
- **Cross-border**: FATCA, dual-jurisdiction KYC, data residency

Compliance rules are enforced at the agent level via `.claude/rules/`.

## Status

> **This is an actively evolving project.** The directory structure, system architecture, tech choices, and agent configurations will continue to change as development progresses. What you see today may look very different next month — that's by design.

Current state:

- [x] Product design specs (v1-v3)
- [x] Interactive HTML prototypes (9 pages)
- [x] System architecture docs (trading, market data, fund transfer)
- [x] Market data service (Go, with WebSocket)
- [x] Trading engine structure (OMS, risk, settlement, FIX)
- [x] Fund transfer service structure (ledger, AML, reconciliation)
- [x] Mobile app scaffolding (KMP + Compose Multiplatform)
- [ ] Full backend API integration
- [ ] Admin panel
- [ ] End-to-end testing
- [ ] Production deployment

## License

MIT
