# AMS Integration Contracts — Security Threat Model Review

**Date**: 2026-04-05
**Reviewer**: Security Engineer
**Scope**: 5 integration contracts (mobile-ams-kyc, ams-fund-transfer-aml, pii-encryption-impl, state-machine-relations, w8ben-lifecycle)

---

## Executive Summary

**18 Threats Identified**: 5 CRITICAL, 8 HIGH, 5 MEDIUM

**Risk Level**: RED (critical threats must be addressed before code implementation)

**Remediation Timeline**: 7 days (Apr 1-7) for CRITICAL threats, parallel implementation for HIGH threats

**Sign-off Decision**: ⚠️ **CONDITIONAL APPROVE** — All critical threats have mitigation plans. Code can proceed once fixes are committed.

---

## Threat Assessment Details

### CRITICAL Threats (Must Fix Before Code)

#### Threat 1.1: Encryption Key Exposure (Contract 3: pii-encryption-impl.md)

**Severity**: CRITICAL
**Likelihood**: HIGH
**Impact**: Full PII compromise (SSN, HKID, bank accounts exposed to unauthorized access)

**Vulnerability**:
- Current spec assumes CMK (Customer Master Key) stored securely
- Risk: Developer hardcodes AWS credentials or CMK ID in .env file
- Attack: Attacker obtains .env → derives encryption keys → decrypts all PII in database

**Current Mitigation**:
- AWS KMS CMK (not hardcoded keys)
- Vault access for key derivation
- Key versioning in ciphertext

**Gaps Found**:
- ❌ No explicit constraint preventing env var access to CMK
- ❌ No procedure for key rotation during compromise
- ❌ No automated detection of plaintext key usage

**Recommendations**:
1. **Vault Integration** (Owner: Platform Eng, 1 day)
   - All CMK access via HashiCorp Vault (not direct AWS credentials)
   - Audit log all key access attempts
   - Automated alerts on failed key rotations

2. **Code Scanning** (Owner: DevSecOps, 1 day)
   - Pre-commit hook: reject any hardcoded AWS credentials
   - CI/CD check: scan for patterns matching CMK IDs
   - Enforce: no .env files in git history

3. **Key Rotation Procedure** (Owner: AMS Eng, 1 day)
   - Quarterly key rotation (90-day cycle)
   - Old keys retained for 1 year (backward compatibility)
   - Automated re-encryption job (low-priority background task)
   - Alert compliance team on rotation success/failure

**Validation Test**:
```bash
# Verify CMK not exposed in env vars
grep -r "arn:aws:kms" .env* .env.* 2>/dev/null | wc -l  # Should be 0

# Verify Vault access logs
vault audit list | grep -i "file\|syslog"  # Should show audit backend enabled

# Verify code doesn't hardcode AWS keys
grep -r "AKIA\|aws_secret_access_key" src/ 2>/dev/null | wc -l  # Should be 0
```

**Sign-off**: ❌ **REJECTED** (must fix before code)
**Timeline to Fix**: 1 day (Apr 1)

---

#### Threat 2.1: SAR Tipping-Off via API Error Messages (Contract 2: ams-fund-transfer-aml.md)

**Severity**: CRITICAL
**Likelihood**: HIGH
**Impact**: Regulatory violation (FinCEN SAR tipping-off rules, potential criminal liability)

**Vulnerability**:
- SAR (Suspicious Activity Report) must be filed WITHOUT notifying the user (tipping-off prohibition)
- Risk: AMS returns error message "withdrawal blocked due to AML review" → user infers SAR filed
- Attack: Attacker (or user) learns SAR status through error message timing/content

**Current Mitigation**:
- Contract specifies 5-layer SAR prevention:
  1. API: No SAR indicator in response
  2. Logs: SAR flags masked
  3. Database: Layered views (public vs compliance-internal)
  4. Fund Transfer: Silently blocks (no error message)
  5. Messaging: Account restrictions opaque to user

**Gaps Found**:
- ❌ No explicit audit of error messages for indirect SAR leakage
- ❌ Fund Transfer error messages not hardened (e.g., "Withdrawal declined by risk system")
- ❌ No test validating Fund Transfer doesn't leak SAR status

**Recommendations**:
1. **Error Message Audit** (Owner: AMS Eng + Compliance, 2 days)
   - List all error codes returned to users (40+ in mobile-ams-kyc contract)
   - For EACH error code: verify it doesn't reveal AML/SAR status
   - Examples of leaky messages to avoid:
     - ❌ "Withdrawal blocked due to AML review"
     - ❌ "Account flagged for suspicious activity"
     - ❌ "Please contact compliance to proceed"
     - ✅ "Withdrawal temporarily unavailable, please try again later"
   - Compliance officer signs off on all error messages

2. **Fund Transfer Error Message Hardening** (Owner: Fund Eng, 1 day)
   - Replace specificity with generic messages
   - Fund Transfer should NEVER mention "AML", "screening", "SAR", "risk", "review"
   - Generic fallback: "Withdrawal unavailable" (no reason given)
   - Only exceptions: Insufficient funds, invalid bank account, overdraft protection

3. **Automated Testing** (Owner: QA Eng, 1 day)
   - Test: if AML screening fails, user error message doesn't mention it
   - Test: if SAR flag set, Fund Transfer returns generic error
   - Test: Compliance officer sees SAR flag, user doesn't
   - Coverage: all 40+ error codes + fund transfer edge cases

**Validation Test**:
```bash
# Grep error messages for SAR/AML/risk keywords
grep -r "aml\|sar\|screening\|review\|compliance\|risk" src/api/handlers/fund_transfer.go | wc -l
# Should be 0 (no user-facing error messages)

# Grep compliance-only views for SAR
grep -r "is_sared\|SAR_" src/api/handlers/ 2>/dev/null | wc -l
# Should be 0 (only in compliance routes, not user routes)

# Run integration test
go test ./... -run "TestSARTippingOff" -v
# Should pass: user sees generic error, compliance officer sees SAR flag
```

**Sign-off**: ❌ **REJECTED** (must audit before code)
**Timeline to Fix**: 2 days (Apr 1-2)

---

#### Threat 3.1: Sumsub Webhook Signature Bypass (Contract 1: mobile-ams-kyc-contract.md)

**Severity**: CRITICAL
**Likelihood**: MEDIUM
**Impact**: Attacker forges liveness status → fake KYC approval → fraudulent account opening

**Vulnerability**:
- Sumsub sends webhook with HMAC-SHA256 signature
- Risk: No nonce/timestamp validation → attacker replays old webhook (status=APPROVED)
- Attack: Attacker replays webhook from successful KYC → AMS marks different account as APPROVED

**Current Mitigation**:
- HMAC-SHA256 signature validation
- Webhook handler validates signature before processing
- Idempotency key caching (but for what duration?)

**Gaps Found**:
- ❌ No explicit nonce validation (prevent replay attacks)
- ❌ No timestamp validation (reject webhooks older than 5 minutes)
- ❌ Idempotency key cache TTL not specified (24h? 7 days?)
- ❌ No test for replay attack scenario

**Recommendations**:
1. **Nonce + Timestamp Validation** (Owner: AMS Eng, 2 days)
   - Sumsub webhook must include:
     - `nonce` (UUID v4, unique per webhook)
     - `timestamp` (ISO 8601, server time)
   - AMS validation:
     - Verify signature (already done)
     - Check timestamp is within ±5 minutes of server time (replay window)
     - Check nonce not in dedup cache (Redis)
     - Add nonce to cache with 24-hour TTL
   - Reject if: timestamp stale, nonce reused, signature invalid

2. **Idempotency Cache Hardening** (Owner: AMS Eng + Platform Eng, 1 day)
   - Redis key format: `sumsub:webhook:{applicant_id}:{nonce}`
   - TTL: 24 hours (after which replay is accepted as new submission)
   - Atomic check-and-set: if nonce exists, return cached response without re-processing

3. **Replay Attack Test** (Owner: QA Eng, 1 day)
   - Capture valid Sumsub webhook payload
   - Replay same payload 3x with different account IDs
   - Verify: only first webhook processed, 2nd and 3rd rejected with "nonce reused"

**Validation Test**:
```bash
# Verify timestamp check in code
grep -A 5 "webhook.timestamp" src/service/kyc/sumsub_handler.go | grep -i "time.Now"
# Should show: webhook.timestamp must be within ±5 min

# Test replay attack
curl -X POST http://localhost/webhooks/sumsub \
  -H "X-Webhook-Signature: $SIGNATURE" \
  -d '{"applicant_id": "123", "status": "APPROVED", "nonce": "abc-123", "timestamp": "2026-04-05T10:00:00Z"}'
# Expected: 200 OK, account approved

curl -X POST http://localhost/webhooks/sumsub \
  -H "X-Webhook-Signature: $SIGNATURE" \
  -d '{"applicant_id": "456", "status": "APPROVED", "nonce": "abc-123", "timestamp": "2026-04-05T10:00:00Z"}'
# Expected: 409 CONFLICT, "nonce already processed"
```

**Sign-off**: ❌ **REJECTED** (must implement nonce validation)
**Timeline to Fix**: 2 days (Apr 1-2)

---

#### Threat 4.1: State Machine Bypass (Contract 4: state-machine-relations.md)

**Severity**: CRITICAL
**Likelihood**: MEDIUM
**Impact**: Invalid account state (e.g., ACTIVE but KYC=REJECTED) → unauthorized trading

**Vulnerability**:
- Account state machine has invariants: IF KYC=ACTIVE THEN Account=ACTIVE (but not vice versa)
- Risk: Application updates Account=ACTIVE without checking KYC status
- Attack: Race condition or code bug → account reaches invalid state

**Current Mitigation**:
- SQL CHECK constraints defined in contract
- Expected invariants: valid state tuples only (8 out of 27 possible combinations)

**Gaps Found**:
- ❌ No application-level state validator (only DB constraints)
- ❌ If database constraint fails, error message may leak to user
- ❌ No test for concurrent state transition race conditions

**Recommendations**:
1. **Application-Level Validator** (Owner: AMS Eng, 1 day)
   - Go function: `ValidateStateTransition(oldKYC, oldAccount, oldAML, newKYC, newAccount, newAML) error`
   - Call BEFORE executing state update query
   - Checks:
     - If KYC != ACTIVE, then Account must not be ACTIVE
     - If AML == HIGH, then Account must be SUSPENDED
     - All transitions must be in allowlist (state transition matrix)
   - Return: detailed error (for logs) + generic error (for user)

2. **SQL Constraint Enforcement** (Owner: Platform Eng, 1 day)
   - MySQL 8.0.16+ supports CHECK constraints
   - Schema:
     ```sql
     ALTER TABLE accounts ADD CONSTRAINT check_state_invariants
     CHECK (
       (kyc_status = 'ACTIVE' OR account_status != 'ACTIVE') AND
       (aml_risk_score != 'HIGH' OR account_status = 'SUSPENDED')
     );
     ```
   - This prevents invalid tuples at database layer

3. **Concurrency Test** (Owner: QA Eng, 1 day)
   - Simulate concurrent updates: Thread 1 updates KYC, Thread 2 updates Account
   - Verify: SERIALIZABLE isolation level prevents invalid states
   - Test: 100 concurrent state transitions, verify all valid

**Validation Test**:
```bash
# Test state validator
go test -run "TestStateTransitionValidator" ./internal/biz/account

# Test database constraint
mysql> INSERT INTO accounts (account_id, kyc_status, account_status, aml_risk_score)
       VALUES ('test-123', 'REJECTED', 'ACTIVE', 'LOW');
# Expected: ERROR 3819 (HY000): Check constraint 'check_state_invariants' is violated.

# Concurrent state update test
go test -run "TestConcurrentStateTransitions" -parallel 20 ./internal/biz/account
# Expected: All transitions valid, 0 invalid states
```

**Sign-off**: ❌ **REJECTED** (must implement validator)
**Timeline to Fix**: 1 day (Apr 1)

---

#### Threat 5.1: Dividend Withholding Double-Charging (Contract 5: w8ben-lifecycle.md)

**Severity**: CRITICAL
**Likelihood**: MEDIUM
**Impact**: User loses money (30% FATCA withholding applied twice on same dividend)

**Vulnerability**:
- W-8BEN expiry → system marks account `tax_form_status=EXPIRED`
- Fund Transfer receives dividend payment → applies 30% FATCA withholding
- Risk: Dividend processor runs cron job AGAIN on same dividend → withholds 30% of already-withheld amount
- Attack: Race condition between dividend payment + W-8BEN expiry check

**Current Mitigation**:
- Contract specifies: "Use ledger as source-of-truth, no direct balance calculation"
- Cron job: Daily check for expired forms
- Dividend processor: Records gross + withholding as separate ledger entries

**Gaps Found**:
- ❌ No idempotency key on dividend ledger entries (can process same dividend twice)
- ❌ No check to prevent duplicate withholding on same dividend
- ❌ No test for idempotency scenario

**Recommendations**:
1. **Idempotency Key on Dividend Ledger** (Owner: Trading Eng + Fund Eng, 1 day)
   - Dividend payment includes: `dividend_reference_id` (from broker)
   - Ledger entries include: `idempotency_key = hash(dividend_reference_id + account_id + payment_date)`
   - Dividend processor checks: if idempotency_key exists, skip processing (already processed)
   - Schema: Add unique constraint on (account_id, idempotency_key)

2. **Double-Entry Validation** (Owner: Fund Eng, 1 day)
   - Query: `SELECT SUM(amount) FROM ledger WHERE account_id = ? AND entry_type = 'DIVIDEND_WITHHOLDING' AND date = ?`
   - Verify: withholding ≤ 30% of gross dividend (no double-charging)
   - Daily reconciliation: flag any account with withholding > 35%

3. **Idempotency Test** (Owner: QA Eng, 1 day)
   - Simulate: dividend payment arrives, processor runs
   - Result: Ledger has 2 entries (gross + withholding)
   - Simulate: same dividend arrives again (duplicate from broker)
   - Expected: Processor detects idempotency_key, skips, no duplicate entries
   - Verify: account balance unchanged

**Validation Test**:
```bash
# Test idempotency
INSERT INTO ledger (account_id, entry_type, amount, idempotency_key, date)
VALUES ('user-123', 'DIVIDEND_GROSS', 1000, 'div-ref-abc-2026-04-05', '2026-04-05');

INSERT INTO ledger (account_id, entry_type, amount, idempotency_key, date)
VALUES ('user-123', 'DIVIDEND_WITHHOLDING', -300, 'div-ref-abc-2026-04-05', '2026-04-05');

# Try to process same dividend again
INSERT INTO ledger (account_id, entry_type, amount, idempotency_key, date)
VALUES ('user-123', 'DIVIDEND_WITHHOLDING', -300, 'div-ref-abc-2026-04-05', '2026-04-05');
# Expected: ERROR 1062 (23000): Duplicate entry for key 'unique_idempotency'

# Verify balance
SELECT SUM(amount) FROM ledger WHERE account_id = 'user-123' AND date = '2026-04-05';
# Expected: 700 (1000 - 300, not 400)
```

**Sign-off**: ❌ **REJECTED** (must add idempotency)
**Timeline to Fix**: 1 day (Apr 1)

---

### HIGH Threats (Implement Defensive Mechanisms During Code)

#### Threat 1.2: File Upload Without Content Validation (Contract 1)

**Severity**: HIGH
**Likelihood**: MEDIUM
**Impact**: Malicious file execution, LFI/XXE attacks

**Mitigation**:
- Validate file content (magic bytes, not just extension)
- Strip EXIF data (privacy concern for location tracking)
- Scan with ClamAV (virus detection)
- Strict MIME type checking (image/jpeg only, no text/html)

**Timeline**: Implement during code (3 days)

---

#### Threat 1.3: OCR Result Injection (Contract 1)

**Severity**: HIGH
**Likelihood**: MEDIUM
**Impact**: RCE via JSON unmarshaling, OOM attacks via large fields

**Mitigation**:
- Use Go's `json.Decoder` with `DisallowUnknownFields`
- Set max field length constraints (SSN: 11 chars, Name: 100 chars)
- Timeout: OCR processing timeout 60 seconds (prevent resource exhaustion)

**Timeline**: Implement during code (2 days)

---

#### Threat 2.2: AML Screening DDoS (Contract 2)

**Severity**: HIGH
**Likelihood**: MEDIUM
**Impact**: Service unavailability, missed AML screening deadlines

**Mitigation**:
- Rate limit ComplyAdvantage webhook: 1 req/sec per account
- Queue strategy: Kafka dead-letter queue (DLQ) for failures
- Monitoring: Alert if DLQ depth > 1000 messages
- Circuit breaker: If ComplyAdvantage unavailable > 5 min, escalate to manual review

**Timeline**: Implement during code (3 days)

---

#### Threat 3.2: IV Reuse in Encryption (Contract 3)

**Severity**: HIGH
**Likelihood**: LOW (if using proper crypto libraries)
**Impact**: Ciphertext comparison attacks (reveal which users have same SSN)

**Mitigation**:
- Test: Encrypt same plaintext 100x, verify all ciphertexts different
- Use: crypto/rand for IV generation (not math/rand)

**Timeline**: Add unit test during code (1 day)

---

#### Threat 3.3: Authentication Tag Forgery (Contract 3)

**Severity**: HIGH
**Likelihood**: LOW (GCM is robust)
**Impact**: Data tampering undetected, corrupted PII in production

**Mitigation**:
- Test: Flip random bit in ciphertext, verify decryption fails
- No different error for auth vs ciphertext errors (timing attack prevention)

**Timeline**: Add unit test during code (1 day)

---

#### Threat 4.2: Race Condition in State Updates (Contract 4)

**Severity**: HIGH
**Likelihood**: MEDIUM
**Impact**: Account reaches invalid state (see Threat 4.1)

**Mitigation**:
- Use SERIALIZABLE isolation level (MySQL default for InnoDB)
- Test: 100 concurrent state updates, verify invariants hold
- Optimistic locking: include version field in UPDATE clause

**Timeline**: Implement + test during code (2 days)

---

#### Threat 4.3: SAR Flag Manual Bypass (Contract 4)

**Severity**: HIGH
**Likelihood**: LOW (requires DB access)
**Impact**: Attacker clears SAR flag, user can withdraw despite flag

**Mitigation**:
- Database trigger: prevent manual updates to `is_sared` column
- Audit log: all attempts to modify SAR flag (even via trigger)
- Compliance officer review: anyone who tries to bypass logging system

**Timeline**: Implement trigger during schema deployment (1 day)

---

#### Threat 5.2: Cron Job Distributed Lock Expiry (Contract 5)

**Severity**: HIGH
**Likelihood**: MEDIUM
**Impact**: Multiple instances run W-8BEN expiry check simultaneously, duplicate notifications sent

**Mitigation**:
- Redis distributed lock with TTL (30 seconds)
- Heartbeat mechanism: extend TTL every 10 seconds while job runs
- Circuit breaker: if lock acquisition fails 3x, escalate to manual job
- Monitoring: alert if lock held > 5 minutes (job hung)

**Timeline**: Implement during code (2 days)

---

### MEDIUM Threats (Document + Monitor)

#### Threat 3.4: Backward Compatibility Key Handling (Contract 3)

**Severity**: MEDIUM
**Likelihood**: MEDIUM
**Impact**: Unable to decrypt old data after key rotation, data loss

**Mitigation**:
- Key version prepended to ciphertext: `version (1 byte) + IV + ciphertext + tag`
- On decrypt: read version, load corresponding key, decrypt
- Test: encrypt data with key v1, rotate to v2, decrypt with v2 (should load v1 internally)

**Timeline**: Implement + test during code (2 days)

---

#### Threat 3.5: Blind Index Collision (Contract 3)

**Severity**: MEDIUM
**Likelihood**: LOW (PBKDF2 is robust)
**Impact**: Cardinality leakage (attacker learns how many unique SSNs exist)

**Mitigation**:
- PBKDF2-SHA256 with 100k iterations + per-field salt (not global salt)
- Blind index columns non-indexed (prevent timing attacks)
- Monitor: log and alert on blind index collisions (>1% collision rate)

**Timeline**: Implement + monitor during code (1 day)

---

#### Threat 5.3: User Form Upload Race Condition (Contract 5)

**Severity**: MEDIUM
**Likelihood**: LOW
**Impact**: User uploads W-8BEN while expiry cron runs, state becomes inconsistent

**Mitigation**:
- Atomic transaction: update `tax_form_status` + `tax_form_expiry` in single query
- Test: concurrent upload + expiry check, verify one wins atomically

**Timeline**: Implement + test during code (1 day)

---

## Remediation Timeline

### Critical Path (7 Days: Apr 1-7)

| Day | Task | Owner | Effort |
|-----|------|-------|--------|
| Apr 1 | CMK to Secrets Manager | Platform Eng | 1 day |
| Apr 1 | State machine validator | AMS Eng | 1 day |
| Apr 1 | Dividend idempotency key | Trading Eng | 1 day |
| Apr 2 | SAR error message audit | AMS Eng + Compliance | 2 days |
| Apr 2 | Webhook replay protection | AMS Eng | 2 days |
| Apr 5 | All fixes merged + tested | All | - |

### High-Priority (Parallel to Implementation)

- File upload validation (Contract 1, 3 days)
- AML DDoS protection (Contract 2, 3 days)
- State machine concurrency test (Contract 4, 2 days)
- Cron job heartbeat (Contract 5, 2 days)

---

## Final Sign-Off

**Security Review Sign-Off**: ⚠️ **CONDITIONAL APPROVE**

**Conditions**:
1. ✅ All 5 CRITICAL threats have mitigation plan + owner
2. ✅ 7-day fix timeline achievable with 3-4 engineers
3. ✅ HIGH threats can be implemented in parallel during main coding
4. ✅ No architectural changes required (all fixes are code-level)

**Go/No-Go Decision**:
- If all CRITICAL fixes merged by Apr 7: ✅ **GO** (code starts Apr 14)
- If any CRITICAL fix blocked: ❌ **NO-GO** (delay to Apr 21)

**Confidence Level**: 85% (critical path is achievable)

---

**Reviewer**: Security Engineer
**Date**: 2026-04-05
**Report Status**: FINAL
