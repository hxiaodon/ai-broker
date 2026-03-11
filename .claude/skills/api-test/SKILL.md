---
name: api-test
description: "Execute API integration tests against trading and account endpoints. Validates order lifecycle, account operations, market data, and compliance endpoints."
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
context: fork
---

You are the API test skill for a US/HK stock brokerage trading application. You execute integration tests against the backend APIs and report results.

## Pre-Flight Checks

Before running tests, verify the environment:

```bash
# Check if services are running
!`curl -s http://localhost:8080/health 2>/dev/null || echo "API Gateway not running"`
!`curl -s http://localhost:8081/actuator/health 2>/dev/null || echo "Account Service not running"`
```

## Test Suites

### 1. Account API Tests
Test account management endpoints:
- `POST /api/v1/accounts` — Create account (validate required fields)
- `GET /api/v1/accounts/:id` — Get account details (verify auth, ownership check)
- `PUT /api/v1/accounts/:id/kyc` — Submit KYC (validate document types, status transitions)
- `GET /api/v1/accounts/:id/positions` — Get positions (verify P&L calculation)
- `GET /api/v1/accounts/:id/balances` — Get balances (verify buying power calculation)

### 2. Trading API Tests
Test order lifecycle:
- `POST /api/v1/orders` — Submit order (all types: market, limit, stop, stop-limit)
- `GET /api/v1/orders/:id` — Get order status
- `DELETE /api/v1/orders/:id` — Cancel order (verify state machine)
- `PUT /api/v1/orders/:id` — Modify order (verify allowed modifications)
- `GET /api/v1/orders?status=open` — List open orders with filtering

### 3. Market Data API Tests
Test market data endpoints:
- `GET /api/v1/quotes/:symbol` — Get quote (verify data freshness)
- `WS /api/v1/stream/quotes` — WebSocket quote subscription
- `GET /api/v1/charts/:symbol?interval=1d` — Historical OHLCV data
- `GET /api/v1/market/status` — Market hours status (US, HK)

### 4. Security Tests
Test authentication and authorization:
- Verify all protected endpoints return 401 without token
- Verify expired tokens are rejected
- Verify users cannot access other users' data (403)
- Verify rate limiting headers and enforcement
- Verify request signing validation for trading endpoints

### 5. Compliance Endpoint Tests
Test compliance-specific endpoints:
- `GET /api/v1/audit/trail?account=X` — Audit trail query
- `GET /api/v1/compliance/pdt-status/:account` — PDT status check
- `GET /api/v1/compliance/wash-sales/:account` — Wash sale detection
- `GET /api/v1/reports/1099/:account/:year` — Tax report generation

## Execution

Look for existing test files and run them:

```bash
# Check for API test files
!`find . -name "*api*test*" -o -name "*integration*test*" -o -name "*.http" -o -name "*.rest" | head -20`

# Run Go integration tests
!`go test ./tests/integration/... -v -tags=integration 2>/dev/null || echo "No Go integration tests found"`

# Run Postman/Newman tests
!`npx newman run tests/api/*.json --reporters cli 2>/dev/null || echo "No Newman tests found"`
```

## Output Format

```markdown
## API Test Report
**Date**: [current date]
**Environment**: [local/staging/uat]
**Base URL**: [url]

### Results by Suite
| Suite | Total | Passed | Failed | Skipped | Duration |
|-------|-------|--------|--------|---------|----------|
| Account API | N | N | N | N | Xs |
| Trading API | N | N | N | N | Xs |
| Market Data | N | N | N | N | Xs |
| Security | N | N | N | N | Xs |
| Compliance | N | N | N | N | Xs |

### Failed Tests
| Test | Endpoint | Expected | Actual | Error |
|------|----------|----------|--------|-------|

### Summary
- Total: N tests
- Passed: N (X%)
- Failed: N
- API Coverage: X endpoints tested / Y total
```
