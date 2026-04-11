# Mobile Domain

## Domain Scope

This domain owns the consumer-facing mobile application (iOS + Android) built with Flutter, the embedded H5 WebView pages (React/TypeScript) for compliance forms and marketing content, and the interactive HTML prototypes used for design validation.

Everything the end user sees and touches lives here. Backend business logic lives in the upstream service domains.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.41.4 / Dart 3.7.x |
| State Management | Riverpod 3.0 (`^3.0.0`，含自动重试 / Pause/Resume / 统一 `Ref` API) |
| HTTP Client | Dio (interceptors, SPKI certificate pinning, retry) |
| WebSocket | `web_socket_channel` (real-time market data) |
| Charts | Syncfusion Flutter Charts（唯一图表库） |
| Data Classes | `freezed` + `json_serializable` |
| Secure Storage | `flutter_secure_storage ^10.0.0` (`migrateOnAlgorithmChange`，`unlocked_this_device`) |
| Biometrics | `local_auth` |
| H5 Pages | React 18 / TypeScript 5.x / Vite / Tailwind CSS |

Financial calculations must use `Decimal` from `package:decimal` -- never `double`.

## Source Layout

Flutter project root is `src/`. All `flutter`/`dart` commands must be run from `mobile/src/`.

```
src/
├── lib/          -- Dart application code
├── ios/          -- iOS native project
├── android/      -- Android native project
├── pubspec.yaml  -- Dependency manifest
└── build/        -- Build artifacts (gitignored)
```

## PRD Index (docs/prd/)

| File | Scope |
|------|-------|
| `00-overview.md` | Product overview, user personas, market scope |
| `01-auth.md` | Login, registration, session management |
| `02-kyc.md` | KYC/AML onboarding flow (US + HK) |
| `03-market.md` | Market data, quotes, watchlists, stock detail |
| `04-trading.md` | Order entry, order status, trade confirmation |
| `05-funding.md` | Deposit/withdrawal UI, bank account binding |
| `06-portfolio.md` | Holdings, P&L, position detail |
| `07-cross-module.md` | Notifications, search, deep links, error handling |
| `08-settings-profile.md` | Account settings, profile management, preferences |

## Spec Index (docs/specs/)

### Shared Architecture Specs (Cross-Module)

| File | Scope |
|------|-------|
| `shared/mobile-flutter-tech-spec.md` | Flutter 3.41.4 architecture, folder structure, navigation, DI, security implementation |
| `shared/10-jsbridge-spec.md` | JSBridge contract between Flutter and H5 WebView pages |
| `shared/h5-vs-native-decision.md` | **Architecture decision**: which pages are H5 WebView vs Flutter Native, KYC breakdown, JSBridge sufficiency |
| `shared/flutter-init-report.md` | Phase 1 skeleton init report, dependency decisions, build verification |
| `shared/mobile-market-data-layer.md` | **[ARCHIVED]** KMP/Kotlin era market data layer — superseded; pending rewrite after PRD-03 approval |

### Module-Specific Specs

| File | Scope |
|------|-------|
| `auth/` | Auth module specs: implementation, tests, code review, security analysis (T04, T05, T06, T17) |
| `market/` | **[PENDING]** Market module specs (created JIT with PRD-03 approval) |
| `trading/` | **[PENDING]** Trading module specs |
| `kyc/` | **[PENDING]** KYC/AML module specs |
| `portfolio/` | **[PENDING]** Portfolio module specs |
| `funding/` | **[PENDING]** Funding (deposit/withdrawal) module specs |
| `settings/` | **[PENDING]** Settings/Profile module specs |

### Progress Tracking

| File | Scope |
|------|-------|
| `*.tracker.md` | 实现跟踪文件（动态进度 + 验收记录） — Tracker files at root level, linked by active-features.yaml |
| `../active-features.yaml` | 域级功能实现进度仪表盘（`docs/active-features.yaml`） |
| `../patches.yaml` | Patch 注册表（`docs/patches.yaml`） |

## Design Index (docs/design/)

| File | Scope |
|------|-------|
| `mobile-app-design.md` | V1 design spec -- screen inventory, navigation, components |
| `mobile-app-design-v2.md` | V2 revisions -- updated flows, refined components |
| `mobile-app-design-v3-supplement.md` | V3 supplement -- KYC, settings, profile flows |
| `design-review-for-pm.md` | PM review notes on design decisions and open questions |

## Testing Standards

Integration testing follows the **three-tier classification** defined in [docs/INTEGRATION_TEST_GUIDE.md](./docs/INTEGRATION_TEST_GUIDE.md):

| Type | File Name | Purpose | Dependencies | Speed |
|------|-----------|---------|--------------|-------|
| **State Management** | `*_state_management_test.dart` | Riverpod providers, routing, state | None | Very fast (~30s) |
| **API Integration** | `*_api_integration_test.dart` | HTTP layer with Mock Server | Mock Server | Fast (~8s) |
| **E2E** | `*_e2e_app_test.dart` | Complete user flows UI→API→UI | Emulator + Mock Server | Moderate (~15s) |

**Every module must implement all three test types.** See [integration_test/auth/README.md](./src/integration_test/auth/README.md) for a working example.

**Key Documents:**
- [INTEGRATION_TEST_GUIDE.md](./docs/INTEGRATION_TEST_GUIDE.md) — Test classification standard (mobile-engineer MUST read)
- [MOCK_SERVER_GUIDE.md](./docs/MOCK_SERVER_GUIDE.md) — How to run tests locally
- [TESTING_PRACTICES.md](./docs/TESTING_PRACTICES.md) — Manual test checklist, CI/CD integration, troubleshooting
- [integration_test/auth/README.md](./src/integration_test/auth/README.md) — Concrete example for Auth module

**Running Tests:**
```bash
# State management (no Mock Server needed)
flutter test integration_test/auth/auth_state_management_test.dart

# API integration (requires Mock Server on localhost:8080)
flutter test integration_test/auth/auth_api_integration_test.dart

# E2E (requires Mock Server + emulator)
flutter test integration_test/auth/auth_e2e_app_test.dart

# All tests
flutter test integration_test/
```

## Upstream Dependencies

| Service | What This Domain Consumes |
|---------|--------------------------|
| AMS | Auth tokens, KYC status, user profile, notifications |
| Trading Engine | Order submission, order status, position data, P&L |
| Market Data | Real-time quotes (WebSocket), K-line data, tick history |
| Fund Service | Deposit/withdrawal status, bank account list, balance info |

Cross-domain contracts live in `docs/contracts/` at repo root.

## Downstream Consumers

End users on iOS and Android devices. No other service depends on this domain.

## Domain Agents

| Agent | File | Scope |
|-------|------|-------|
| Mobile Engineer | `.claude/agents/mobile-engineer.md` | Flutter app — widgets, navigation, state, platform integration. **Spec-reference only: reads PRD / tech-spec / contracts / hifi prototype before implementing.** |
| H5 Engineer | `.claude/agents/h5-engineer.md` | React/TS WebView pages — JSBridge, compliance forms, marketing |
| UI Designer (UXUE) | `.claude/agents/ui-designer.md` (global) | High-fidelity HTML prototypes → `prototypes/{module}/hifi/`; upstream of mobile-engineer |

## Design Handoff Flow

```
PM (PRD + lofi prototype)
    ↓
UXUE / ui-designer  →  prototypes/{module}/hifi/  +  tokens.css
    ↓
mobile-engineer  →  Flutter implementation
```

- Mobile engineer **must read hifi HTML before writing any Widget code**
- Color/spacing values come from `tokens.css` variable names → `ColorTokens` in Dart
- All states defined in the prototype's dev state switcher must be implemented

## Prototypes (prototypes/)

Interactive HTML prototypes implementing the v3-final design spec. Used for design review and PM sign-off before Flutter implementation.

Pages: `index.html` (hub), `login.html`, `kyc.html`, `market.html`, `stock-detail.html`, `search.html`, `trade.html`, `orders.html`, `portfolio.html`, `funding.html`, `profile.html`, `settings.html`.

See `prototypes/CHANGELOG.md` for revision history.
