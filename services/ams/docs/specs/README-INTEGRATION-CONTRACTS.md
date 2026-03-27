# AMS Integration Contracts — Master Index

> **Date**: 2026-03-31
> **Status**: ✅ All 5 Contracts Complete (155 KB total)
> **Location**: `services/ams/docs/specs/`
> **Next Phase**: Implementation (2 days) → Architecture Review (1 day) → Code Review → Merge (Fri Apr 4)

---

## Quick Navigation

| # | Contract | File | Size | Owner(s) | Timeline |
|---|----------|------|------|----------|----------|
| 1 | Mobile-AMS KYC | `mobile-ams-kyc-contract.md` | 38 KB | h5-engineer + ams-engineer | Mon Mar 31 — Wed Apr 2 |
| 2 | AMS-Fund Transfer AML | `ams-fund-transfer-aml.md` | 25 KB | ams-engineer + fund-engineer | Tue Apr 1 — Fri Apr 4 |
| 3 | PII Encryption Impl. | `pii-encryption-impl.md` | 29 KB | ams-engineer + security-engineer | Mon Mar 31 — Wed Apr 2 |
| 4 | State Machine Relations | `state-machine-relations.md` | 17 KB | ams-engineer + product-manager | Wed Apr 2 — Fri Apr 4 |
| 5 | W-8BEN Lifecycle | `w8ben-lifecycle.md` | 26 KB | ams-engineer + product-manager | Tue Apr 1 — Fri Apr 4 |

---

## Contract Summaries

### Contract 1: mobile-ams-kyc-contract.md

**7-Step KYC Flow** from mobile UI to AMS backend, with Sumsub integration and W-8BEN management.

**Key Sections**:
- OpenAPI 3.0 request/response schemas (all 7 steps)
- Sumsub file upload & OCR integration (Level 2 liveness detection)
- W-8BEN form issuance, validation, T-90/30/7/0 lifecycle
- Status polling & webhook fallback
- Error handling & retry strategies (exponential backoff, 3 retries)
- Dart model generation + Go handler signatures + gRPC protobuf

**Compliance Coverage**:
- SSN/HKID encryption (AES-256-GCM)
- Age verification (>= 18 years)
- OFAC sanctions screening (synchronous at submission)
- PEP flagging (asynchronous, POST-approval)

**Deliverables**:
- OpenAPI YAML (consumable by code-gen)
- Dart freezed models + API service layer
- Go HTTP handlers (with Sumsub webhook verification)
- gRPC protobuf definitions
- Integration test scenarios

---

### Contract 2: ams-fund-transfer-aml.md

**AML Responsibility Boundaries** between AMS and Fund Transfer, with SAR Tipping-off protection and W-8BEN blocking.

**Key Sections**:
- CTR/STR split (who detects, who reports, who files)
- SAR tipping-off prevention (API field filtering, log sanitization, database views)
- Risk score propagation (LOW/MEDIUM/HIGH impact on fund transfer approval)
- gRPC interfaces (ScreenTransaction, GetAccountSnapshotForFundTransfer, ReportSuspiciousActivity)
- Kafka events (AMLRiskScoreChanged, SanctionListHitDetected, TaxFormExpired)
- ComplyAdvantage webhook security (signature verification, idempotency)
- W-8BEN expiry auto-blocking (silent rejection, no error message leaking)

**Compliance Coverage**:
- OFAC/JFIU screening integration
- ComplyAdvantage minute-level updates
- PEP continuous monitoring via webhook
- CTR auto-filing for deposits > $10k
- SAR investigation workflow (30-day review, no tipping-off to user)

**Deliverables**:
- gRPC service definitions (.proto)
- Kafka Avro schemas (7-day retention for audit)
- ComplyAdvantage webhook handler (HMAC signature + idempotency)
- Error handling & fallback strategies
- Monitoring metrics & alerting rules

---

### Contract 3: pii-encryption-impl.md

**Application-Layer Encryption** for 5 PII fields using AWS KMS Envelope Encryption.

**Key Sections**:
- Encrypted field taxonomy (SSN, HKID, passport, bank account, DOB)
- AES-256-GCM AEAD algorithm (with 12-byte nonce, 16-byte auth tag)
- AWS KMS CMK management (2 keys: PII + BlindIndex, auto-rotation every 90 days)
- Envelope encryption architecture (DEK generation, ciphertext storage)
- Blind Index implementation (PBKDF2-SHA256 for low-entropy fields, HMAC-SHA256 for high-entropy)
- Log sanitization (automatic Zap hook to redact SSN/HKID in logs)
- Database schema (VARBINARY(256) for ciphertext, VARBINARY(512) for encrypted DEK)
- Comprehensive unit tests (encryption/decryption roundtrip, authentication tag validation, enumeration attack resistance)

**Compliance Coverage**:
- GDPR/CCPA encryption at rest
- No plaintext PII in logs
- Key separation (Master key never leaves HSM)
- Audit trail via CloudTrail
- Blind index prevents database-layer enumeration attacks

**Deliverables**:
- Go PIIEncryptor implementation (crypto/cipher + AWS KMS)
- Blind index calculator (PBKDF2 + HMAC)
- Zap logger sanitizer
- Database migration (Goose)
- 100% test coverage (15+ test cases)
- Compliance verification script

---

### Contract 4: state-machine-relations.md

**Three-Way State Mapping** between KYC workflow, Account lifecycle, and AML risk evaluation.

**Key Sections**:
- KYC states: APPLICATION_SUBMITTED → KYC_DOCUMENT_PENDING → KYC_UNDER_REVIEW → KYC_APPROVED or KYC_REJECTED
- Account states: APPLICATION_SUBMITTED → PENDING → ACTIVE → SUSPENDED → CLOSING → CLOSED (or REJECTED)
- AML risk: LOW → MEDIUM → HIGH (dynamic scoring, not a state machine)
- Valid state tuples (9x3 matrix: 27 possible combinations, only 8 valid)
- Transition rules (conditional: KYC=APPROVED ⇒ Account ∈ {ACTIVE, SUSPENDED, CLOSING, CLOSED})
- Invariant constraints (AML=HIGH ⇒ Account ≠ ACTIVE, CLOSED/REJECTED are terminal)
- Role-based visibility (customer sees account_status only; compliance sees all including SAR fields)
- State transition events (immutable audit trail with actor, reason, timestamp)

**Compliance Coverage**:
- Terminal state enforcement (no reversal from CLOSED/REJECTED)
- Time-monotonic state transitions (no time travel)
- Automatic account suspension if AML=HIGH (fail-safe)
- SAR field access control (compliance_officer role only)

**Deliverables**:
- Go StateValidator (validate transitions, check invariants)
- SQL CHECK constraints (database-level enforcement)
- PlantUML state diagrams (for documentation)
- Role-based API field filtering (automatic via struct tags)
- Audit event schema (for immutable logging)

---

### Contract 5: w8ben-lifecycle.md

**W-8BEN Tax Form Complete Lifecycle** from issuance through to expiry and automatic blocking.

**Key Sections**:
- Issuance rules (who needs W-8BEN: non-US tax residents trading US stocks)
- Activation workflow (user uploads → AMS validates name/TIN/signature date → status=ACTIVE, expiry=T+3y)
- Notification timeline:
  - T-90: First reminder (email + push, 1-time only)
  - T-30: Escalated reminder
  - T-7: Final warning
  - T+1: Expiry notice + blocking becomes active
- Cron job implementation (daily 02:00 UTC, distributed lock via Redis)
- Post-expiry behavior:
  - Trading Engine: blocks new BUY orders on US stocks (silent rejection)
  - Fund Transfer: applies 30% FATCA withholding on dividends
  - Ledger: records both dividend and withholding as separate entries
- Kafka event distribution (ams.tax_form_expired → trading-engine, fund-transfer)
- User UI flow (renewal dialog with pre-filled name, input TIN + signature)

**Compliance Coverage**:
- IRS Publication 515 (3-year validity period)
- FATCA withholding (30% automatic if expired)
- SEC 17a-3 audit trail (all status changes immutable)
- Dividend processing ledger (double-entry bookkeeping)
- Cron idempotency (distributed lock prevents duplicate processing)

**Deliverables**:
- Cron job Go code (with Redis lock)
- Dividend processor (withholding calculation)
- Kafka event consumer (for downstream services)
- Flutter UI widget (renewal notice + form input)
- Audit & compliance reporting SQL queries
- Integration test scenarios (T-90, T-0, dividend processing)

---

## Architecture Diagrams

### Contract 1: KYC Data Flow

```
Mobile (Flutter)                AMS Backend                 Sumsub API
    │                               │                            │
    │─── POST /v1/kyc/start ──────►│                            │
    │                               │─ Create session           │
    │◄──────── kycSessionId ────────│                            │
    │                               │                            │
    │─ GET /v1/kyc/sumsub-token ───►│                            │
    │◄──── Sumsub accessToken ──────│◄─ GenerateAccessToken ────│
    │                               │                            │
    │─── POST document + SDK ───────────────────────────────────►│
    │    (Sumsub Mobile SDK)        │                   (OCR + Liveness)
    │                               │                            │
    │                               │◄─ Webhook ─────────────────│
    │                               │   applicantReviewed
    │                               │
    │─ GET /v1/kyc/status ─────────►│
    │◄─ {status: REVIEWING} ────────│
    │
    │ ... (polling continues)
    │
    │─ GET /v1/kyc/status ─────────►│
    │◄─ {status: APPROVED} ─────────│
    │
    │─ FCM Push (backup) ◄───────────│ (account ACTIVE)
```

### Contract 2: AML Responsibility

```
Fund Transfer                    AMS                      ComplyAdvantage
    │                            │                              │
    │ Deposit $15,000 detected   │                              │
    │                            │                              │
    │ gRPC: ScreenTransaction ───►│                              │
    │                            │─ Sync check (400ms) ────────►│
    │                            │◄─ PASS / HIT ────────────────│
    │                            │                              │
    │◄─── Screening result ──────│                              │
    │                            │                              │
    │ (If PASS, proceed)         │◄─ Webhook (new sanction) ────│
    │                            │ (async, continuous monitoring)
    │                            │
    │ Auto-file CTR              │
    │ (amount > $10k) ───────────►Compliance Service
    │                            │
    │                            │ If SAR → Update risk_score
    │                            │ Kafka: aml.risk_score_changed
    │                            │       (hidden_sar_filing_count filtered out)
```

### Contract 3: Encryption Architecture

```
AWS KMS (Master Key)
    │
    ├─ CMK: arn:aws:kms:us-east-1:xxx:key/pii-cmk-prod-v1
    │
    ├─ GenerateDataKey
    │   ├─ Plaintext DEK (32 bytes, in memory)
    │   └─ Encrypted DEK (185 bytes base64, in DB)
    │
    ▼
Application Layer
    ├─ AES-256-GCM cipher
    ├─ Random Nonce (12 bytes per encryption)
    ├─ Auth Tag (16 bytes, automatic in GCM)
    │
    ▼
Database
    ├─ ssn_encrypted: VARBINARY(256)
    ├─ ssn_blind_index: VARCHAR(64) [indexed for queries]
    ├─ ssn_dek_blob: VARBINARY(512) [encrypted DEK]
    │
    └─ (same for HKID, passport, bank_account, DOB)
```

### Contract 4: State Machine Relations

```
KYC: APPLICATION_SUBMITTED → DOCUMENT_PENDING → UNDER_REVIEW → APPROVED ✓
              │                                                    │
              └─ (optional: REJECTED)                             │
                                                                  │
Account: APPLICATION_SUBMITTED → PENDING ◄───────────────────────┘
             │
             ├─ REJECTED (if KYC=REJECTED)
             │
             └─ ACTIVE ──► SUSPENDED (if AML=HIGH)
                             │
                             ▼
                          CLOSED

AML Risk: LOW ◄─────┐
             │      │ (risk resolved)
             ▼      │
          MEDIUM ──►┘
             │
             ▼
           HIGH (auto-suspend account)
             │
             └─ EDD completed ──► MEDIUM
```

### Contract 5: W-8BEN Timeline

```
T-0 (signing)        T+3 years (expiry)
│                    │
▼                    ▼
ACTIVE              T-90 days    T-30 days    T-7 days    T+0 day
  │                   │             │           │          │
  │                   ├─ Notify1    │           │          │
  │                   │             ├─ Notify2  │          │
  │                   │             │           ├─ Notify3 │
  │                   │             │           │          ├─ Expire
  │                   │             │           │          │  (30% withholding)
  │                   │             │           │          ├─ Block BUY
  │                   │             │           │          └─ Notify user
  │                   │             │           │
  └─ User renews ─────┴─────────────┴───────────┘
                 (any time before T+0)
                      │
                      └─ ACTIVE again (new T+3y)
```

---

## Compliance Matrix

### Regulatory Coverage

| Regulation | Contract | Implementation |
|------------|----------|-----------------|
| **SEC Rule 17a-3** (Account Records) | 1, 4, 5 | Audit trail immutable, all state transitions logged |
| **SEC Rule 17a-4** (Record Retention) | 1, 3, 5 | PII encrypted, 7-year retention for tax forms, ledger entries |
| **FINRA Rule 4512** (Know Your Customer) | 1, 4 | 7-step KYC collection, investment assessment, options level |
| **Reg BI** (Best Interest Standard) | 1, 4 | Suitability questionnaire, risk tolerance capture |
| **FATCA (IRC 1471)** | 1, 5 | W-8BEN validation, 30% withholding on dividends |
| **IRS Pub 515** (Tax Withholding) | 5 | W-8BEN 3-year validity, automatic renewal reminders |
| **GDPR / CCPA** (Data Protection) | 3 | Application-layer encryption for all PII, key management |
| **SFC Code of Conduct** (KYC, Suitability) | 1, 4 | KYC tier, PI (professional investor) status, suitability |
| **AMLO Cap. 615** (Anti-Money Laundering) | 2 | Sanctions screening, PEP detection, SAR coordination |
| **FinCEN CTR/SAR** (Currency Transaction Reports) | 2 | CTR auto-filing for > $10k deposits, SAR investigation protocol |
| **FinCEN OFAC SDN** (Sanctions) | 1, 2 | Synchronous OFAC check at account open, daily re-screening |

---

## Implementation Dependencies

### Critical Path

```
Day 1 (Mon Mar 31):
  ├─ Contract 1 & 3 implementation (parallel)
  │   ├─ Go: mobile-ams-kyc handlers + PIIEncryptor
  │   ├─ Dart: KYC UI + model generation
  │   └─ SQL: users_pii table migration
  │
  └─ Contract 5 partial (W-8BEN schema)

Day 2 (Tue Apr 1):
  ├─ Contract 2 implementation (gRPC interfaces)
  │   ├─ amsClient.ScreenTransaction
  │   ├─ Kafka consumer for tax_form_expired
  │   └─ ComplyAdvantage webhook handler
  │
  ├─ Contract 5 continued (Cron job)
  │   ├─ w8ben_expiry_check daily job
  │   └─ Notification scheduling
  │
  └─ Contract 4 (StateValidator)

Days 2-4 (Tue-Thu):
  ├─ Integration testing
  ├─ Code review (security-engineer)
  └─ Compliance checklist validation

Day 5 (Fri Apr 4):
  ├─ Final PR review
  ├─ Architecture Review sign-off
  └─ Merge to main
```

### Cross-Contract Dependencies

```
mobile-ams-kyc-contract.md (1)
    └─ requires ─► pii-encryption-impl.md (3)
    └─ requires ─► state-machine-relations.md (4)

ams-fund-transfer-aml.md (2)
    └─ requires ─► state-machine-relations.md (4)
    └─ requires ─► w8ben-lifecycle.md (5)

pii-encryption-impl.md (3)
    └─ [independent, but used by Contracts 1 & 2]

state-machine-relations.md (4)
    └─ [foundational, required by 1 & 2]

w8ben-lifecycle.md (5)
    └─ requires ─► ams-fund-transfer-aml.md (2)
```

---

## Code Review Checklist

### For Each Contract

- [ ] **Compliance**: All regulatory citations in place (SEC/SFC/FINRA/FinCEN)
- [ ] **Security**: PII handled safely (encryption, masking, access control)
- [ ] **API Contracts**: OpenAPI/gRPC definitions valid and consumable
- [ ] **Error Handling**: All error paths specified (timeout, validation, retry)
- [ ] **Testing**: Unit + integration tests specified or provided
- [ ] **Monitoring**: Prometheus metrics + alerting rules defined
- [ ] **Backward Compatibility**: Schema migrations non-destructive

### Specific to Each

**Contract 1**: Sumsub webhook signature validation, file size limits, OCR timeout handling
**Contract 2**: SAR field filtering in all API responses, ComplyAdvantage Webhook security
**Contract 3**: DEK generation idempotency, key rotation SOP, CloudTrail audit
**Contract 4**: Terminal state enforcement (SQL + Go), role-based field filtering
**Contract 5**: Cron job distributed lock (Redis), W-8BEN tax calculation in ledger

---

## Success Metrics

| Metric | Target | Validation Method |
|--------|--------|-------------------|
| **All 5 contracts delivered** | ✅ 155 KB docs | Line count check |
| **OpenAPI specs valid** | ✅ swagger-cli lint | Automated validation |
| **gRPC protos compilable** | ✅ protoc errors = 0 | Build test |
| **PII encryption coverage** | ✅ 100% (5 fields) | Code review |
| **State machine constraints** | ✅ SQL + Go tests | Unit tests pass |
| **Compliance alignment** | ✅ All rules cited | Audit trail |
| **Architecture review ready** | ✅ By Fri Apr 4 EOD | Merge gate |

---

## File Locations (Absolute Paths)

```
/Users/huoxd/metabot-workspace/brokerage-trading-app-agents/services/ams/docs/specs/
├── mobile-ams-kyc-contract.md           (38 KB)
├── ams-fund-transfer-aml.md             (25 KB)
├── pii-encryption-impl.md               (29 KB)
├── state-machine-relations.md           (17 KB)
└── w8ben-lifecycle.md                   (26 KB)

Total: 155 KB, ~4,500 lines of specification
```

---

## Next Steps

1. **Code Generation** (1 day): OpenAPI → Go/Dart, protobuf → Go
2. **Implementation** (3 days): Handlers, services, database migrations
3. **Unit Testing** (1 day): 85%+ coverage per contract
4. **Integration Testing** (1 day): Cross-service workflows
5. **Architecture Review** (security-engineer, code-reviewer): Fri Apr 4
6. **Code Review & Merge**: Fri Apr 4 EOD → Main branch

---

**Status**: ✅ All contracts complete and ready for implementation

**Next Meeting**: Tue Apr 1 10:00 AM (implementation sync)
