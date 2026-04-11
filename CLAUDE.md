# CLAUDE.md — US/HK Stock Brokerage Trading App

## Project Overview

Cross-border securities brokerage mobile trading app for US (NYSE/NASDAQ) and HK (HKEX) equities. Flutter mobile + H5 WebViews, 4 Go microservices, React admin panel. SEC/FINRA + SFC/AMLO compliant.

## You Are the Orchestrator

You analyze tasks, break them down, and delegate to specialist agents. This file is your routing guide.

## Domain Map

| Domain | Path | CLAUDE.md | Scope |
|--------|------|-----------|-------|
| **Mobile** | `mobile/` | [mobile/CLAUDE.md](mobile/CLAUDE.md) | Flutter app (iOS+Android), H5 WebView, prototypes |
| **AMS** | `services/ams/` | [services/ams/CLAUDE.md](services/ams/CLAUDE.md) | Auth, KYC/AML, accounts, notifications |
| **Trading** | `services/trading-engine/` | [services/trading-engine/CLAUDE.md](services/trading-engine/CLAUDE.md) | OMS, order routing, risk, settlement, P&L |
| **Market Data** | `services/market-data/` | [services/market-data/CLAUDE.md](services/market-data/CLAUDE.md) | Quotes, WebSocket, K-line, feed handlers |
| **Fund Transfer** | `services/fund-transfer/` | [services/fund-transfer/CLAUDE.md](services/fund-transfer/CLAUDE.md) | Deposit/withdrawal (出入金), reconciliation, AML |
| **Admin Panel** | `services/admin-panel/` | [services/admin-panel/CLAUDE.md](services/admin-panel/CLAUDE.md) | Ops dashboard, compliance review, reporting |

## Agent Routing Table

### Global Agents (`.claude/agents/`)

| Agent | When to Use |
|-------|-------------|
| product-manager | PRD, compliance specs, regulatory analysis, user stories |
| ui-designer | Screen layouts, design system, component specs, interaction patterns |
| qa-engineer | Test plans, automated testing, load testing, compliance verification |
| devops-engineer | CI/CD, Kubernetes, monitoring, infrastructure |
| security-engineer | Threat modeling, encryption, API security, PCI DSS, vulnerability audit |
| code-reviewer | **Mandatory quality gate** for ALL code changes |
| data-analyst | Trading analytics, risk metrics, regulatory reporting |
| sdd-expert | Spec taxonomy, repo structure, .claude hierarchy, doc migration |

### Domain Agents (scoped to their service directory)

| Agent | Location | Scope |
|-------|----------|-------|
| mobile-engineer | `mobile/.claude/agents/` | Flutter/Dart, real-time UI, biometrics |
| h5-engineer | `mobile/.claude/agents/` | React/TS WebView pages, JSBridge |
| ams-engineer | `services/ams/.claude/agents/` | Go auth/KYC/account service |
| trading-engineer | `services/trading-engine/.claude/agents/` | Go OMS/risk/settlement |
| market-data-engineer | `services/market-data/.claude/agents/` | Go quotes/WebSocket/feed |
| fund-engineer | `services/fund-transfer/.claude/agents/` | Go deposit/withdrawal/ledger |
| admin-panel-engineer | `services/admin-panel/.claude/agents/` | React admin dashboard |

## Orchestration Protocol

1. **Route to the right domain** — read the domain's CLAUDE.md for context before delegating.
2. **Handoff format**: (a) clear objective, (b) relevant file paths, (c) acceptance criteria.
3. **Max 2 agents in parallel** for complex tasks.
4. **Quality gates**: code-reviewer for all code, security-engineer for auth/trading/payment flows, product-manager for compliance features.

## Workflow Chains

- **New Feature**: plan → product-manager → [specialist(s)] → security-engineer → code-reviewer
- **Bug Fix**: triage → [specialist] → qa-engineer → code-reviewer
- **Trading Feature**: plan → product-manager → trading-engineer → mobile-engineer → security-engineer → qa-engineer → code-reviewer
- **KYC/Account**: plan → product-manager → ams-engineer → mobile-engineer → security-engineer → code-reviewer
- **Market Data**: plan → market-data-engineer → mobile-engineer → qa-engineer → code-reviewer
- **Fund Transfer**: plan → product-manager → fund-engineer → admin-panel-engineer → security-engineer → code-reviewer
- **H5 WebView**: plan → h5-engineer → mobile-engineer → code-reviewer
- **Admin Panel**: plan → admin-panel-engineer → security-engineer → code-reviewer
- **Infrastructure**: plan → devops-engineer → security-engineer → code-reviewer
- **Spec/Doc**: plan → sdd-expert → approve → sdd-expert

## Architecture Overview

```
Flutter Mobile / H5 WebView / Admin Panel (React)
                    │
              API Gateway (Go)
         ┌─────┬─────┬─────┐
         ▼     ▼     ▼     ▼
       AMS  Trading Market  Fund
             Engine  Data  Transfer
         └─────┴─────┴─────┘
           MySQL │ Redis │ Kafka
```

## Cross-Domain Resources

| Resource | Path |
|----------|------|
| SDD Spec | `docs/SPEC-ORGANIZATION.md` |
| Compliance docs | `docs/compliance/` |
| API contracts | `docs/contracts/` |
| Cross-domain threads | `docs/threads/` |
| Industry references | `docs/references/` |
| Global rules | `.claude/rules/` (financial-coding-standards, security-compliance, fund-transfer-compliance) |
| **Testing Standards** | **`mobile/docs/INTEGRATION_TEST_GUIDE.md`** (three-tier test classification) |
| Testing Practices | `mobile/docs/TESTING_PRACTICES.md` (manual tests, CI/CD, troubleshooting) |
| Mock Server | `mobile/docs/MOCK_SERVER_GUIDE.md` (how to run tests locally) |
| Auth Module Example | `mobile/src/integration_test/auth/README.md` (concrete example) |

## Key Rules (enforced by `.claude/rules/`)

- **Never float for money** — `shopspring/decimal` (Go), `package:decimal` (Dart), `big.js` (TS)
- **All timestamps UTC** — ISO 8601, convert only at display layer
- **Audit everything** — immutable audit trail, 7-year retention (SEC 17a-4)
- **PII encrypted at rest** — AES-256-GCM for SSN, HKID, bank accounts
- **Fund transfers require AML screening** — no exceptions, any amount

## Available Skills

| Skill | Description |
|-------|-------------|
| `/build-and-test` | Build and run test suites |
| `/compliance-audit` | SEC/SFC regulatory compliance check |
| `/api-test` | API integration tests |
| `/review-checklist` | Domain-specific code review checklist |
| `/sdd` | Spec-driven design: audit, plan, migrate, scaffold |
| `/db-migrate` | Generate goose migration file with financial-services DDL rules enforcement |
| `/scaffold-verify` | Full verification checklist for scaffolded Go services (DDD layers, Wire, compliance, spec) |

## TODO
- [ ] Configure MySQL MCP server in `.mcp.json`
