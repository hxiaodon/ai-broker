---
name: review-checklist
description: "Generate a domain-specific code review checklist tailored to the type of change being reviewed. Helps reviewers catch brokerage-specific issues."
user-invocable: true
allowed-tools: Read, Grep, Glob
context: fork
---

You are the review checklist generator for a US/HK stock brokerage trading application. You analyze the current changes and generate a tailored review checklist.

## Step 1: Detect Changes

Analyze what has changed:

```bash
!`git diff --name-only HEAD~1 2>/dev/null || git diff --name-only --staged 2>/dev/null || echo "No git changes detected"`
```

```bash
!`git diff --stat HEAD~1 2>/dev/null || git diff --stat --staged 2>/dev/null || echo ""`
```

## Step 2: Classify the Change

Based on files changed, determine which domains are affected:
- **Trading Engine** (Go files in trading/, order/, matching/)
- **Account Services** (Java files in account/, kyc/, compliance/)
- **iOS App** (Swift files)
- **Android App** (Kotlin files)
- **Admin Panel** (TypeScript/React files)
- **Infrastructure** (Dockerfile, K8s manifests, Terraform, CI configs)
- **Database** (SQL migrations, schema changes)

## Step 3: Generate Domain-Specific Checklist

### Always Include (All Changes)
- [ ] No floating-point types used for financial calculations
- [ ] No secrets/credentials in code or config files
- [ ] All user inputs validated and sanitized
- [ ] Error handling is complete (no swallowed errors)
- [ ] Audit logging for state-changing operations
- [ ] Tests added/updated for changed code
- [ ] No PII in log statements

### If Trading Engine Changes
- [ ] Order state machine transitions are correct and complete
- [ ] Pre-trade risk checks cannot be bypassed
- [ ] Idempotency keys used for order submission
- [ ] Fill quantity never exceeds order quantity
- [ ] Partial fill handling is correct (remaining qty, avg price)
- [ ] Market hours validation is correct for both US and HK
- [ ] FIX protocol messages are well-formed
- [ ] Decimal precision matches exchange requirements

### If Account/KYC Changes
- [ ] KYC status transitions follow allowed state machine
- [ ] PII fields are encrypted before database storage
- [ ] Sanctions screening is invoked for new accounts
- [ ] Account type restrictions are enforced (individual vs institutional)
- [ ] Fund transfer limits are validated
- [ ] Cooling period enforced for new bank account linkage

### If Mobile App Changes (iOS/Android)
- [ ] Biometric auth used for sensitive operations (trades, withdrawals)
- [ ] Keychain/Keystore used for credential storage (not UserDefaults/SharedPrefs)
- [ ] Certificate pinning configured for API calls
- [ ] Offline state handled gracefully (trading disabled, stale data indicated)
- [ ] Decimal type used for financial display values
- [ ] Accessibility labels on all interactive elements

### If Admin Panel Changes
- [ ] RBAC permissions checked at component and route level
- [ ] Financial numbers displayed with correct formatting and precision
- [ ] Pagination used for all list views (no unbounded queries)
- [ ] Form validation matches backend validation rules
- [ ] Export functionality sanitizes data (no PII in CSV unless authorized)

### If Database/Migration Changes
- [ ] Migration is reversible (has down migration)
- [ ] No destructive changes to production data (DROP, DELETE, TRUNCATE)
- [ ] Indexes added for new query patterns
- [ ] Partitioning strategy maintained for orders/audit tables
- [ ] Schema change is backward compatible with running services

### If Infrastructure Changes
- [ ] No credentials in Terraform/Helm values (use Vault/Secrets Manager)
- [ ] Resource limits set for all containers
- [ ] Health check endpoints configured
- [ ] Monitoring alerts updated for new services
- [ ] Network policies restrict unnecessary access
- [ ] SSL/TLS configured for all public endpoints

## Output Format

```markdown
## Code Review Checklist
**Change**: [brief description from git log]
**Domains**: [list of affected domains]
**Risk Level**: LOW / MEDIUM / HIGH / CRITICAL

### Checklist
[Domain-specific checklist items as checkboxes]

### Key Areas to Focus
1. [Most important thing to verify based on the specific changes]
2. [Second most important]
3. [Third most important]

### Suggested Reviewers
- [Agent name] for [reason]
```
