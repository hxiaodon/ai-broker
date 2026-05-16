# Fund Transfer Compliance Rules (出入金合规规则)

These rules apply to all deposit, withdrawal, and fund transfer operations. They are non-negotiable and enforced by both code and manual review.

## Rule 1: Same-Name Account Principle (同名账户原则)

- Users can ONLY deposit from and withdraw to bank accounts **under the same legal name** as their brokerage account
- Third-party transfers are **strictly prohibited** (no deposits from another person's bank account)
- Bank account name must match KYC-verified name (fuzzy match allowed for minor formatting differences)
- Exception: Joint accounts where the user is a named holder

## Rule 2: AML Screening is Mandatory

Every fund movement event — deposit, withdrawal, **FX conversion**, internal account transfer, refund — must pass AML screening before execution. **No exceptions** based on "previously screened at deposit" or "small amount". Sanctions lists are dynamic (OFAC publishes updates multiple times per week) so the screening result is valid only for the event in question.

### OFAC / Sanctions Screening (US)
- Check against: OFAC SDN List, Sectoral Sanctions Identifications List, Foreign Sanctions Evaders List, Non-SDN Palestinian Legislative Council List, Non-SDN Menu-Based Sanctions List
- **50% Rule (OFAC Sanctions Compliance Guidance §III.A)**: An entity owned 50% or more (directly or indirectly, aggregated) by one or more SDN-listed persons is itself blocked, even if not on any list. Implementation requires Ultimate Beneficial Owner (UBO) lookup at least two ownership levels deep; the chosen AML SaaS vendor (e.g., Refinitiv World-Check, ComplyAdvantage, LexisNexis Bridger) must support UBO traversal — see `docs/references/aml-screening-vendors.md`
- Screen on: user legal name + DOB, counterparty entity name, bank name, bank country, SWIFT/BIC, beneficiary name (for outgoing wires)
- Block transfers to/from sanctioned countries (Cuba, Iran, North Korea, Syria, Crimea/Donetsk/Luhansk regions)
- Refresh sanctions list daily (T-1 cutoff 06:00 UTC); name-screening uses fuzzy match with phonetic + transliteration

### SFC / AMLO Screening (HK)
- Check against HK designated persons/entities list (published by HK SAR Government Gazette)
- Comply with AMLO Cap. 615 Part 4A (AML/CFT requirements)
- Report suspicious transactions to JFIU (Joint Financial Intelligence Unit) via STR e-form
- HK sanctions list refresh: daily (UN Security Council updates propagate via HK Government Gazette)

### Transaction Monitoring

**CTR (Currency Transaction Report)**
- Auto-file for any single deposit or withdrawal **> $10,000 USD** (US, FinCEN Form 112) or **> HK$120,000** (HK, JFIU large transaction report). The threshold is **strictly greater than** — exactly $10,000 does NOT trigger CTR (FinCEN: "in excess of $10,000")
- Per-currency calculation; USD and HKD do not aggregate
- Filing deadline: within 15 calendar days of the transaction (FinCEN); WORM-stored for 5 years

**Structuring Detection (Dual-Window)**
Structuring is a separate federal offense (31 U.S.C. § 5324) regardless of whether CTR threshold is reached. Detection runs **two windows simultaneously** — either trip generates a SAR candidate:

| Window | Conditions (all must hold) |
|--------|---------------------------|
| **24-hour sliding** | ≥ 3 transactions, same user + same direction + same currency, each `< $10,000 USD` (or HK$120,000), cumulative `≥ $8,000 USD` (HK$96,000) — conservative low-bound to catch near-threshold splits |
| **7-day rolling** (FinCEN standard) | ≥ 3 transactions, same user + same direction + same currency, each `< $10,000 USD`, cumulative `≥ $10,000 USD` (or HK$120,000) |

Aggregation rules: cross-channel (ACH + Wire + FX-funded transfer all count); cross-account on same SSN/HKID aggregates; cross-day defined by **UTC** day boundary for limits, **ET** day boundary for CTR-relevant aggregations (FinCEN convention).

**Velocity / Pattern Checks**
- Alert on unusual frequency (e.g., > 5 deposits in 24h from same source)
- Round-tripping: rapid deposit → withdraw within 24h with zero trading activity
- New-account high-velocity: > $50K cumulative within first 7 days post-KYC

### SAR Filing and Tipping-Off Prohibition

When suspicious activity is detected (structuring signal, BLOCK / REVIEW from OFAC, round-trip pattern, customer-reported fraud):

- **Filing deadline**: 30 calendar days from initial detection (FinCEN Form 111); extendable by 30 days if additional review needed, never beyond 60 days (31 CFR 1023.320(b)(3))
- **HK counterpart**: STR to JFIU "as soon as reasonably practicable" (AMLO §25A); no fixed deadline but courts have ruled 7–14 days is the upper bound

**Tipping-Off (31 U.S.C. § 5318(g)(2) / AMLO §25A(5)) — strictly prohibited**

Once a SAR/STR is filed OR is under internal review pending filing decision, the firm and **every employee** must NOT disclose to the customer, counterparty, or any unauthorized third party:
- That a SAR/STR has been filed
- That the customer is under AML investigation
- Any information that would reasonably allow the customer to infer the above

### SAR + CTR Coexistence Decision Matrix

A single transaction can simultaneously trigger CTR (large amount) and SAR (suspicious pattern). CTR filing is mandatory and not tipping-off; SAR is confidential. The two flows must be kept independent:

| Trigger State | CTR action | SAR action | Customer-facing comms |
|---------------|------------|------------|----------------------|
| CTR only (no suspicion) | File CTR within 15 days | None | None required; do not mention CTR |
| SAR only (below CTR threshold) | None | File SAR within 30 days | No comms about AML; if transaction is BLOCKED, generic "compliance review" message only |
| **CTR + SAR (both triggered)** | File CTR within 15 days | File SAR within 30 days | Generic compliance-review message; **NEVER reference CTR, SAR, or AML in customer notification or bank statement** |
| Customer asks "why was I flagged?" | Confirm only that compliance review is in progress; no specifics | — | Use approved tipping-off-safe script (see `operations-and-edge-cases.md` §4.X) |

**Implementation**: customer notification templates must be reviewed by compliance counsel before deployment; AML status fields in customer-facing API responses (`compliance_review_required: bool`) must NOT distinguish CTR vs SAR vs BLOCK reasons. Internal logs may distinguish but are restricted to compliance role RBAC.

## Rule 3: Travel Rule Compliance

For transfers involving the thresholds below, the firm must transmit originator and beneficiary information to the counterparty institution:

**US (FinCEN, 31 CFR 1010.410)**
- Transfers > **$3,000 USD**: must include originator name, account number, address; beneficiary name, account number

**HK (HKMA SPM SA-2 §6.18–6.26, AMLO Schedule 2 §13–14) — Two-Tier**

| Threshold | Required Information |
|-----------|---------------------|
| > **HK$8,000** | Originator name + account number; beneficiary name + account number |
| > **HK$120,000** | Above + originator address; beneficiary address (if obtainable); purpose of transfer; relationship between originator and beneficiary |

The two thresholds are cumulative — transfers > HK$120,000 must satisfy both tiers. Intermediary institutions must also forward this information without modification.

**Implementation**
- Information must be transmitted through the payment message (SWIFT MT103 field 50/59, ACH addenda records, FPS extended fields)
- Records retained for minimum **5 years** (Rule 9)

## Rule 4: Settlement-Aware Withdrawals

- **Unsettled funds are NOT withdrawable** — only settled cash can be withdrawn
- US Stocks: T+1 settlement (since May 2024)
- HK Stocks: T+2 settlement
- System must track settlement dates per transaction
- Withdrawable balance = Total cash - Unsettled proceeds - Pending withdrawals - Margin requirement
- Display "settled" vs "unsettled" balances clearly in user accounts

## Rule 5: Withdrawal Approval Workflow

### Auto-Approve Criteria (all must be true)
- Amount ≤ daily limit for user's KYC tier
- Bank account verified for > 3 days (past cool-down)
- No active AML flags on the account
- User has completed at least one successful withdrawal before
- Risk score: LOW

### Manual Review Required (any one triggers)
- Amount > $50,000 USD or HK$400,000 in single transaction
- Cumulative daily withdrawals > 80% of KYC tier limit
- Bank account bound within last 7 days (extended cool-down)
- User account age < 30 days
- Risk score: MEDIUM or HIGH
- AML screening returned "REVIEW" status

### Escalation to Compliance Officer
- Amount > $200,000 USD or HK$1,500,000
- SAR (Suspicious Activity Report) triggered
- Multiple failed AML screenings in past 30 days
- User on internal watchlist

## Rule 6: Ledger Integrity

- **Double-entry bookkeeping**: Every fund movement must have matching debit and credit entries
- **Append-only**: Ledger entries are NEVER updated or deleted; corrections are made via reversing entries
- **Sum invariant**: Sum of all user balances must equal platform custodial balance at all times
- **Daily reconciliation**: Automated 3-way match (internal ledger ↔ bank statement ↔ custodian balance)
- **Discrepancy threshold**: Auto-alert if mismatch > $0.01; halt operations if mismatch > $100

## Rule 7: Bank Account Security

- Bank account numbers must be **encrypted at rest** (AES-256-GCM) at application level
- Display only last 4 digits in UI: `****1234`
- Deleting a bank account = soft delete (mark inactive, retain for audit)
- Maximum 5 bank accounts per user
- Bank account changes require identity re-verification (biometric or 2FA)

## Rule 8: Idempotency for Fund Operations

- Every deposit/withdrawal request must include an `Idempotency-Key` (UUID v4)
- System must detect and reject duplicate submissions
- Idempotency key cache retention: minimum 72 hours
- On network timeout: client must retry with **same** idempotency key
- Bank channel submissions must also use idempotent reference numbers

## Rule 9: Record Retention and WORM Storage

### Retention Schedule

| Record Type | Retention Period | Regulation |
|-------------|-----------------|------------|
| Fund transfer records | 7 years | SEC 17a-4, SFO |
| AML screening results | 7 years | BSA, AMLO |
| CTR/SAR filings | 5 years | FinCEN, JFIU |
| Bank account records | 6 years after closure | KYC requirements |
| Reconciliation reports | 7 years | Audit requirements |
| Ledger entries | Indefinite | Business continuity |
| 15c3-3 reserve computations | 6 years | SEC Rule 17a-4(b)(10) |
| Customer communications re: fund ops | 3 years accessible + 2 years offline | SEC 17a-4(b)(4) |

### SEC Rule 17a-4(f) — WORM Storage Requirements (US)

All electronic records in the table above must be preserved in **WORM (Write-Once Read-Many)** format. Implementation:

**Storage**: AWS S3 with **Object Lock enabled in COMPLIANCE mode** (not Governance mode, which allows deletion by root). Retention periods must be set at object creation; cannot be shortened. Do NOT use Glacier alone without Object Lock — Glacier is not WORM.

**Coverage** — every record type below must be written to a WORM-enabled S3 prefix before the primary path confirms success:
- `fund_transfers` rows → snapshot exported to S3 on status → COMPLETED / RETURNED / REVERSED / BLOCKED_AML
- `ledger_entries` rows → append-only; all entries replicated to WORM within 24 hours
- `aml_screening_log` rows → written to WORM at time of creation
- `ctr_reports` and `sar_reports` → written to WORM immediately on status = FILED
- `reserve_computations` and SRBA transaction records → written to WORM weekly after CFO sign-off
- `reconciliation_reports` → written to WORM on generation

**Indexing** (17a-4(f)(3)): Each WORM archive must be indexed by: record_type, user_id or account_id (where applicable), date, and correlation_id. An index file in JSON-LD or CSV must be written alongside each batch.

### Designated Third Party (D3P) — SEC 17a-4(f)(3)(i)

SEC requires that a **Designated Third Party (D3P)** have independent access to all WORM records within 24 hours of any SEC or FINRA request. Requirements:

1. **Choose a D3P** before going live with electronic records. Options: Iron Mountain Digital Vault, Smarsh, Broadridge Data Repository, or a bank custodian with SEC-qualified WORM service. The D3P must sign a formal agreement acknowledging their role.
2. **Notify SEC Regional Office** (District Office serving the broker's principal place of business) at least **90 days before** first use of the electronic recordkeeping system (17a-4(f)(2)(i)). Submit written notification with: D3P name + address, storage vendor + system description, senior officer attestation.
3. **Annual Attestation**: A designated senior officer must attest annually that the WORM system is operating correctly (17a-4(f)(2)(ii)).
4. **Audit access**: D3P must be able to retrieve any record within 24 hours of an SEC request. Grant D3P read-only IAM access to the WORM S3 bucket.

### HK Equivalent — SFC / SFO Records

Hong Kong SFO Section 130 + SFC Code of Conduct §4: licensed corporations must retain records in a form accessible to SFC. Implementation mirrors the S3 WORM approach but:
- D3P equivalent: appoint a recognized custodian (HKSCC, or a major bank with proper HKMA authorization)
- Notify SFC Licensing before first use of electronic recordkeeping
- Records localization: HK client records may need to be stored within HK or an approved jurisdiction (data residency law awareness)

## Rule 10: Error Handling for Fund Operations

- **Never silently fail** — every failure must generate an alert and user notification
- **Compensating transactions**: If a deposit is reversed by the bank, immediately debit user balance and notify
- **Insufficient balance on reversal**: Flag account, restrict trading, notify compliance
- **Bank timeout**: Do NOT assume success or failure; mark as PENDING and reconcile via bank statement
- **Duplicate bank callbacks**: Detect and ignore via bank reference number deduplication
