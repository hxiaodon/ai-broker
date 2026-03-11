# Fund Transfer Compliance Rules (出入金合规规则)

These rules apply to all deposit, withdrawal, and fund transfer operations. They are non-negotiable and enforced by both code and manual review.

## Rule 1: Same-Name Account Principle (同名账户原则)

- Users can ONLY deposit from and withdraw to bank accounts **under the same legal name** as their brokerage account
- Third-party transfers are **strictly prohibited** (no deposits from another person's bank account)
- Bank account name must match KYC-verified name (fuzzy match allowed for minor formatting differences)
- Exception: Joint accounts where the user is a named holder

## Rule 2: AML Screening is Mandatory

Every fund transfer, regardless of amount, must pass AML screening before execution:

### OFAC / Sanctions Screening (US)
- Check against OFAC SDN List, Sectoral Sanctions, Non-SDN Lists
- Screen on: user name, bank name, bank country, SWIFT code
- Block transfers to/from sanctioned countries or entities
- Refresh sanctions list daily

### SFC / AMLO Screening (HK)
- Check against HK designated persons/entities list
- Comply with AMLO Part 4A (AML/CFT requirements)
- Report suspicious transactions to JFIU (Joint Financial Intelligence Unit)

### Transaction Monitoring
- **CTR (Currency Transaction Report)**: Auto-file for deposits/withdrawals > $10,000 USD (US) or HK$120,000 (HK)
- **Structuring Detection**: Flag multiple transactions that appear to be split to avoid CTR threshold (e.g., 3x $3,500 in one day)
- **Velocity Checks**: Alert on unusual frequency of deposits/withdrawals
- **Pattern Analysis**: Detect round-tripping (rapid deposit → withdraw without trading)

## Rule 3: Travel Rule Compliance

For transfers > $3,000 USD (US) or HK$8,000 (HK):
- Must include originator information: name, account number, address
- Must include beneficiary information: name, account number
- Information must be transmitted to counterparty institution
- Records retained for minimum 5 years

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

## Rule 9: Record Retention

| Record Type | Retention Period | Regulation |
|-------------|-----------------|------------|
| Fund transfer records | 7 years | SEC 17a-4, SFO |
| AML screening results | 7 years | BSA, AMLO |
| CTR/SAR filings | 5 years | FinCEN, JFIU |
| Bank account records | 6 years after closure | KYC requirements |
| Reconciliation reports | 7 years | Audit requirements |
| Ledger entries | Indefinite | Business continuity |

## Rule 10: Error Handling for Fund Operations

- **Never silently fail** — every failure must generate an alert and user notification
- **Compensating transactions**: If a deposit is reversed by the bank, immediately debit user balance and notify
- **Insufficient balance on reversal**: Flag account, restrict trading, notify compliance
- **Bank timeout**: Do NOT assume success or failure; mark as PENDING and reconcile via bank statement
- **Duplicate bank callbacks**: Detect and ignore via bank reference number deduplication
