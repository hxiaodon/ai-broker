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

| File | Scope |
|------|-------|
| `10-jsbridge-spec.md` | JSBridge contract between Flutter and H5 WebView pages |
| `mobile-flutter-tech-spec.md` | Flutter architecture, folder structure, navigation, DI, security implementation |
| `mobile-market-data-layer.md` | **[ARCHIVED]** KMP/Kotlin era market data layer — superseded; pending rewrite after PRD-03 approval |
| `flutter-init-report.md` | Phase 1 skeleton init report, dependency decisions, build verification |

## Design Index (docs/design/)

| File | Scope |
|------|-------|
| `mobile-app-design.md` | V1 design spec -- screen inventory, navigation, components |
| `mobile-app-design-v2.md` | V2 revisions -- updated flows, refined components |
| `mobile-app-design-v3-supplement.md` | V3 supplement -- KYC, settings, profile flows |
| `design-review-for-pm.md` | PM review notes on design decisions and open questions |

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
