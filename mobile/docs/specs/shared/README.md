# Shared Architecture Specifications

This directory contains cross-module specifications that apply to multiple product modules (auth, market, trading, kyc, portfolio, funding, settings).

## Structure

```
shared/
├── README.md                          ← This file
├── mobile-flutter-tech-spec.md         ← Flutter architecture, DI, navigation, security
├── 10-jsbridge-spec.md                 ← Flutter ↔ H5 WebView communication contract
├── h5-vs-native-decision.md            ← Architecture decision: which pages use H5 vs Native
├── flutter-init-report.md              ← Phase 1 skeleton initialization report
└── mobile-market-data-layer.md         ← [ARCHIVED] Market data architecture (superseded)
```

## Key Documents by Role

### For Mobile Engineers
1. **Start here**: `mobile-flutter-tech-spec.md`
   - Flutter 3.41.4 + Riverpod 3.0 architecture
   - DI (Wire), navigation (GoRouter), state management patterns
   - Security implementation (biometrics, encrypted storage, certificate pinning)
   - Testing strategy (mocktail, Phase 1/Phase 2 separation)

2. **For H5 WebView pages**: `10-jsbridge-spec.md`
   - JSBridge communication protocol
   - Which pages are H5 vs Native (see `h5-vs-native-decision.md`)
   - Message format, error handling, security

3. **For architecture decisions**: `h5-vs-native-decision.md`
   - Why certain pages are React/H5 vs Flutter Native
   - List of 5 H5 pages: KYC, Compliance, Profile, Settings, Help Center
   - JSBridge sufficiency analysis

### For H5 Engineers
1. **Primary**: `10-jsbridge-spec.md` — Complete JSBridge API contract
2. **Context**: `h5-vs-native-decision.md` — Which pages are H5
3. **Architecture**: `mobile-flutter-tech-spec.md` § Security for understanding security requirements

### For Product Managers / Designers
1. **Overview**: `h5-vs-native-decision.md` — Which pages are H5 vs Native (and why)
2. **Context**: `mobile-flutter-tech-spec.md` § Navigation and State Management

### For Security / Compliance
1. **Security requirements**: `mobile-flutter-tech-spec.md` § Security Implementation
   - Biometric authentication
   - Token storage (flutter_secure_storage)
   - PII encryption and masking
   - Certificate pinning
   - Jailbreak/root detection

## File Descriptions

### mobile-flutter-tech-spec.md
**Purpose**: Foundation document for Flutter development across all modules

**Sections**:
- Tech stack (Flutter 3.41.4, Riverpod 3.0, Dio, Web Socket, Syncfusion Charts)
- Project layout (src/lib, src/ios, src/android, src/test)
- Architecture patterns:
  - DI via Wire (Application/Domain/Infrastructure layers)
  - Navigation via GoRouter with route guards
  - State via Riverpod (providers, watchers, selectors)
  - Freezed data classes with JSON serialization
- Testing strategy (Phase 1 instantiation, Phase 2 integration)
- Security (biometrics, encrypted storage, PII masking, certificate pinning)
- Financial standards (Decimal for money, UTC timestamps, audit logging)
- Code patterns and examples

**Used by**: All domain engineers (mobile-engineer, h5-engineer)
**Reference format**: See `mobile/CLAUDE.md` → "Shared Architecture Specs" section

---

### 10-jsbridge-spec.md
**Purpose**: API contract for React/H5 WebView ↔ Flutter communication

**Sections**:
- Overview (which pages use H5, why)
- Message format (JSON, request/response pattern)
- Supported methods (navigation, biometric auth, file upload, etc.)
- Error handling (error codes, timeout handling)
- Security (origin validation, message signing, HTTPS only)
- Examples for each method

**Used by**: H5 engineers, mobile engineers integrating WebView
**Reference format**: See `mobile/CLAUDE.md` → "Shared Architecture Specs" section

---

### h5-vs-native-decision.md
**Purpose**: Architecture decision document for which pages are H5 WebView vs Flutter Native

**Sections**:
- Decision (95% Flutter Native, 5% H5 WebView)
- Pages as H5:
  1. KYC Form (complex form handling, regulatory compliance)
  2. Compliance Agreement (signature capture, document generation)
  3. Profile / Account Settings (static content, rarely updated)
  4. Help Center / FAQ (static content, external links)
  5. [TBD] One additional page (based on future requirements)
- Rationale (maintenance, UX consistency, offline capability, security)
- JSBridge sufficiency analysis (what H5 pages can do via bridge)
- Tradeoffs (code reuse vs complexity, deployment timing)

**Used by**: Product managers, architects, designers, mobile engineers
**Reference format**: Linked from auth module docs as architectural precedent

---

### flutter-init-report.md
**Purpose**: Phase 1 skeleton initialization report

**Content**:
- Initial project setup (Flutter 3.41.4, Dart 3.7)
- Dependency decisions (Riverpod 3.0, Dio, Freezed, etc.)
- Build verification (compilation, analysis, test setup)
- Project structure validation

**Status**: Reference for Phase 1 baseline
**Used by**: Architecture review, future module setup

---

### mobile-market-data-layer.md
**Purpose**: [ARCHIVED] Market data architecture (KMP/Kotlin era)

**Status**: ⚠️ **ARCHIVED** — Superseded by Flutter architecture
**Used by**: Historical reference only; pending rewrite for Flutter after PRD-03 approval

---

## Cross-Module Pattern

When creating specs for new modules (market, trading, kyc, portfolio, funding, settings):

1. **Keep shared specs in this directory** (tech-spec, jsbridge, h5-vs-native)
2. **Create module-specific directory** `../market/`, `../trading/`, etc.
3. **Follow the pattern established in `../auth/`**:
   ```
   {module}/
   ├── README.md
   ├── {module}-*.md (implementation specs)
   ├── code-review/ (code review artifacts)
   └── security/ (security analysis, if applicable)
   ```
4. **Create tracker at root** `../{module}.tracker.md` (not in module subdir)
   - Linked by `mobile/docs/active-features.yaml`
   - Mirrors structure of `../auth.tracker.md`

## Tech Stack Reference

| Layer | Library | Version | Role |
|-------|---------|---------|------|
| Framework | Flutter | 3.41.4 | Mobile app |
| Language | Dart | 3.7.x | Flutter development |
| State Management | Riverpod | 3.0 | Provider + watchers + selectors |
| HTTP | Dio | latest | REST API + interceptors + retry |
| WebSocket | web_socket_channel | latest | Real-time market data |
| Data Classes | Freezed | latest | Immutable models + JSON |
| Secure Storage | flutter_secure_storage | 10.0.0 | Tokens, biometric keys |
| Biometrics | local_auth | latest | Face ID, fingerprint |
| Charts | Syncfusion | latest | K-line, price charts |
| DI | Wire | latest | Application factory, DDD layers |
| Navigation | GoRouter | latest | Routing with guards + redirects |
| Testing | mocktail | latest | Mocking + spy + verify |

## Architecture Layers (per DDD)

All modules follow these layers:

```
Domain/
  ├── entities/          ← Core business objects
  ├── value_objects/     ← Value types (enum, constants)
  └── repositories/      ← Interfaces (abstract)

Application/
  ├── state/             ← Riverpod providers
  ├── use_cases/         ← Business logic orchestration
  └── exceptions/        ← Domain-specific exceptions

Infrastructure/
  ├── repositories_impl/ ← Repository implementations
  ├── data_sources/      ← Remote (API) / Local (cache)
  └── mappers/           ← Entity ↔ DTO conversion

Presentation/
  ├── screens/           ← Full-screen widgets
  ├── widgets/           ← Reusable UI components
  └── notifiers/         ← Screen-specific state (Riverpod)
```

## Security Requirements (All Modules)

- ✅ Biometric authentication for sensitive operations
- ✅ Token storage via flutter_secure_storage (Keychain/EncryptedSharedPrefs)
- ✅ PII encryption at application level (AES-256-GCM)
- ✅ PII masking in logs (SSN, HKID, bank account, email)
- ✅ Certificate pinning via Dio (eliminate network MitM)
- ✅ Jailbreak/root detection (`flutter_jailbreak_detection`)
- ✅ Error handling with context (no secret leakage)
- ✅ Session management (15-min access, 7-day refresh)

## Financial Requirements (All Modules)

- ✅ Use `Decimal` from `package:decimal` for all money calculations (never `double`)
- ✅ All timestamps in UTC (ISO 8601 format)
- ✅ Audit logging for all state-changing operations
- ✅ No floating-point rounding errors

---

**Last Updated**: 2026-04-03  
**Scope**: Applies to all 7 planned modules (auth, market, trading, kyc, portfolio, funding, settings)  
**Status**: Active (flutter-init-report.md and mobile-market-data-layer.md archived)
