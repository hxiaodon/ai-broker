# CLAUDE.md — US/HK Stock Brokerage Trading App

## Project Overview

A cross-border securities brokerage mobile trading application targeting US and Hong Kong stock markets. The platform enables retail investors to trade US (NYSE/NASDAQ) and HK (HKEX) equities through native iOS (Swift) and Android (Kotlin) apps, backed by a high-performance trading system built entirely on Go with PostgreSQL/Redis. The project must comply with SEC/FINRA (US) and SFC/AMLO (HK) regulatory requirements, including KYC/AML, real-time market data, trade execution, fund deposit/withdrawal (出入金), and risk management.

## Agent Team

**You (the main Claude session reading this CLAUDE.md) are the orchestrator / tech lead.** You analyze tasks, break them down, delegate to specialist agents, and ensure quality. You never need a separate tech-lead agent — this file IS your orchestration guide.

### Routing Table

| Task Type | Agent | When to Use |
|-----------|-------|-------------|
| Product requirements, PRD, user stories, compliance specs | product-manager | Feature planning, regulatory requirement analysis, business logic design, user flow specs |
| UI/UX design, design system, interaction patterns | ui-designer | Screen layouts, component design, financial data visualization, accessibility, design tokens |
| iOS app development (Swift/SwiftUI) | ios-engineer | Swift code, iOS-specific features, real-time quote UI, trading order flow, push notifications |
| Android app development (Kotlin/Compose) | android-engineer | Kotlin code, Android-specific features, market data rendering, order management UI |
| **Trading system (OMS, risk, execution)** | **trading-engine-engineer** | **Order management, smart order routing, FIX protocol, pre-trade risk checks, margin, position/P&L, settlement** |
| Backend infrastructure & business services | backend-engineer | API gateway, account service, KYC/AML, notification, reporting (NOT trading/fund transfer) |
| Fund deposit/withdrawal (出入金), payment channels | fund-transfer-engineer | Deposit/withdrawal flows, bank channel integration, payment reconciliation, AML screening |
| Admin panel frontend (React) | frontend-engineer | React admin dashboard, operations portal, CMS, monitoring dashboards, reporting UI |
| Testing, QA automation, compliance testing | qa-engineer | Test plans, automated testing, regression suites, financial calculation verification, load testing |
| Infrastructure, CI/CD, high availability | devops-engineer | Kubernetes, Docker, CI/CD pipelines, monitoring, disaster recovery, blue-green deployments |
| Security audit, penetration testing, compliance | security-engineer | Threat modeling, encryption, API security, PCI DSS compliance, data protection, vulnerability assessment |
| Data analysis, metrics, reporting | data-analyst | Trading analytics, user behavior analysis, risk metrics, regulatory reporting, A/B testing |
| Code review, PR review | code-reviewer | All code changes before merge |
| **Spec architecture, doc organization, repo structure** | **sdd-expert** | **Spec taxonomy, .claude hierarchy design, legacy doc migration, context isolation audit, multi-product repo planning** |

### Orchestration Protocol

1. **You are the routing authority.** When a complex task arrives, analyze it and delegate to the appropriate specialist(s) via Task tool.
2. **For multi-step tasks, delegate to specialists** — break down the work and assign each piece to the right agent.
3. **Handoff format:** When delegating, provide: (a) clear objective, (b) relevant file paths, (c) acceptance criteria, (d) which agent to hand off to next.
4. **Max 2 agents in parallel** for complex tasks to avoid conflicts.
5. **Code reviewer is the quality gate** — all code changes pass through code-reviewer before completion.
6. **Security engineer reviews all auth/trading/payment flows** — any code touching user credentials, trading orders, fund transfers, or PII must be reviewed by security-engineer.
7. **Product manager validates compliance** — any feature touching regulatory requirements (KYC, AML, trading rules) must be validated by product-manager.

### Workflow Chains

- **New Feature**: you (plan & delegate) → product-manager (PRD) → [specialist(s)] → security-engineer (if auth/trading) → code-reviewer
- **Bug Fix**: you (triage) → [specialist] → qa-engineer (verify) → code-reviewer
- **Refactor**: you (plan) → code-reviewer (review plan) → [specialist] → code-reviewer
- **Compliance Feature**: you (plan) → product-manager (compliance spec) → [specialist(s)] → security-engineer → qa-engineer (compliance test) → code-reviewer
- **Infrastructure Change**: you (plan) → devops-engineer → security-engineer (review) → code-reviewer
- **New Trading Feature**: you (plan) → product-manager (PRD + compliance) → trading-engine-engineer (交易逻辑) → [ios-engineer + android-engineer] (parallel) → security-engineer → qa-engineer → code-reviewer
- **Fund Transfer Feature**: you (plan) → product-manager (compliance spec) → fund-transfer-engineer (出入金逻辑) → security-engineer (AML review) → qa-engineer → code-reviewer
- **Spec/Doc Restructure**: you (plan) → sdd-expert (audit + plan) → you (approve) → sdd-expert (execute migration)

## Tech Stack

### Mobile
- **iOS**: Swift 5.9+, SwiftUI, Combine, Swift Concurrency (async/await)
- **Android**: Kotlin 2.0+, Jetpack Compose, Coroutines, Flow
- **Shared**: Protocol Buffers for data serialization, WebSocket for real-time data

### Backend
- **Trading Engine**: Go 1.22+ (high-performance, low-latency order matching)
- **Business Services**: Go 1.22+ (account management, KYC, fund transfer, reporting)
- **Fund Transfer Service**: Go 1.22+ (deposit/withdrawal, bank channel integration, reconciliation)
- **API Gateway**: Go (gRPC + REST gateway)
- **Message Queue**: Kafka (order events, market data distribution, fund transfer events)

### Frontend (Admin)
- **Framework**: React 19+ with TypeScript 5.x
- **State**: Zustand / TanStack Query
- **UI**: Ant Design Pro (enterprise admin components)

### Data
- **Primary DB**: PostgreSQL 16+ (accounts, orders, positions, compliance records)
- **Cache/Session**: Redis 7+ (real-time quotes, session management, rate limiting)
- **Time-Series**: TimescaleDB (market data history, tick data)
- **Search**: Elasticsearch (audit logs, compliance search)

### Infrastructure
- **Container**: Docker + Kubernetes (EKS/GKE)
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana + AlertManager
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **APM**: Jaeger (distributed tracing)

## Coding Standards

### Go
- Follow [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- Use `context.Context` for all service methods; propagate deadlines and cancellation
- Error handling: wrap errors with `fmt.Errorf("operation: %w", err)` for traceability
- Financial calculations: use `shopspring/decimal` — never use float64 for money
- Naming: `camelCase` for unexported, `PascalCase` for exported; packages are lowercase single words
- Use Go standard library and well-maintained third-party libs (sqlx, pgx, go-redis, sarama)

### Swift
- Follow Swift API Design Guidelines
- Use SwiftUI for new views, UIKit only when SwiftUI is insufficient
- Prefer value types (structs) over reference types (classes) where possible
- Use `Decimal` type for all financial calculations
- Naming: `camelCase` for variables/functions, `PascalCase` for types

### Kotlin
- Follow Kotlin Coding Conventions
- Use Jetpack Compose for new UI, XML layouts only for legacy screens
- Prefer `data class` for models, `sealed class/interface` for domain states
- Use `java.math.BigDecimal` for financial calculations
- Coroutines for all async work; never block the main thread

### React/TypeScript
- Strict TypeScript (`strict: true` in tsconfig)
- Functional components with hooks only; no class components
- Use `big.js` or `decimal.js` for financial calculations on the frontend
- API types auto-generated from backend OpenAPI specs

### General Rules
- **Never use floating-point for money.** All financial calculations must use decimal types.
- **All API endpoints require authentication** except public market data endpoints.
- **Audit logging is mandatory** for all state-changing operations on accounts, orders, and funds.
- **All dates/times in UTC** with ISO 8601 format; convert to user timezone only at display layer.
- **Sensitive data encryption** at rest and in transit. PII fields encrypted at application level.
- **Immutable audit trails** — never delete or modify audit/compliance records.
- **Fund transfers require dual verification** — all deposit/withdrawal operations must pass both AML screening and business rule validation before execution.

## Regulatory Compliance Reference

### US (SEC/FINRA)
- **FINRA Rule 4511**: Books and records retention
- **SEC Rule 17a-4**: Electronic storage of records (WORM compliance)
- **Reg NMS**: Best execution obligation for order routing
- **Reg SHO**: Short selling regulations
- **Pattern Day Trader (PDT)**: $25,000 minimum equity requirement tracking
- **Wash Sale Rule**: Track and flag wash sale transactions

### Hong Kong (SFC)
- **Securities and Futures Ordinance (SFO)**: Type 1 (dealing) + Type 7 (automated trading) licenses
- **AMLO**: Anti-money laundering and counter-terrorist financing obligations
- **SFC KYC Guidelines**: Identity verification, beneficial ownership, investor knowledge assessment
- **Travel Rule**: Originator/beneficiary information for fund transfers
- **ASPIRe Roadmap (2025)**: Evolving regulatory framework — design for flexibility

### Cross-Border
- **KYC/AML**: Dual-jurisdiction identity verification (US SSN + HK HKID)
- **Tax Reporting**: IRS W-8BEN for non-US investors, FATCA compliance
- **Data Residency**: User data storage must comply with both jurisdictions
- **Trading Hours**: Handle NYSE (9:30-16:00 ET), NASDAQ extended hours, HKEX (9:30-16:00 HKT)

## Shared Knowledge (MetaMemory)

All agents share context through MetaMemory. Use the `mm` CLI to read and write shared documents.

### Quick Reference
```bash
mm search <query>                    # Find existing knowledge
mm get <doc-id>                      # Read a document
mm list [--folder <id>]              # Browse documents
mm create -t "Title" -c "Content"    # Save new knowledge
mm update <doc-id> -c "New content"  # Update existing doc
```

### When to Use
- **Before starting work**: Search MetaMemory for existing context, decisions, and lessons
- **After completing work**: Save important decisions, architecture notes, and findings
- **When discovering patterns**: Document reusable patterns for other agents to reference
- Use `--by "agent-name"` when creating/updating to track which agent contributed

## Workflow Discipline (All Agents)

### Planning
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Write detailed specs upfront to reduce ambiguity

### Autonomous Execution
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user

### Verification
- Never mark a task complete without proving it works
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### Self-Improvement
- After ANY correction from the user: record the pattern as a lesson
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for relevant context
- Save important lessons and discoveries to MetaMemory (`mm create`) so all agents benefit

### Core Principles
- **Simplicity First**: Make every change as simple as possible. Minimal code impact.
- **Root Cause Focus**: Find root causes. No temporary fixes.
- **Minimal Footprint**: Only touch what's necessary. Avoid introducing bugs.
- **Demand Elegance**: For non-trivial changes, pause and ask "is there a more elegant way?" Skip for simple fixes.
- **Subagent Strategy**: Use subagents liberally. One task per subagent for focused execution.

## Available Skills

| Skill | Description |
|-------|-------------|
| `/build-and-test` | Build the project (all modules or specific) and run test suites |
| `/compliance-audit` | Run a compliance audit against SEC/SFC regulatory checklist |
| `/api-test` | Execute API integration tests against trading and account endpoints |
| `/review-checklist` | Generate a domain-specific code review checklist for brokerage code |
| `/sdd` | Specification-Driven Design: audit spec completeness, plan repo structure, migrate docs, scaffold .claude hierarchy |

## TODO
- [ ] Configure PostgreSQL MCP server: add your connection string to `.mcp.json` → `mcpServers.postgres.args[2]`
