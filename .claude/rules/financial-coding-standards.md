# Financial Coding Standards

All code in this project handles real money and is subject to regulatory audit. These rules are non-negotiable.

## Rule 1: Never Use Floating-Point for Money

This is the single most critical rule. Violating it is a CRITICAL bug.

| Language | Correct Type | Wrong Type |
|----------|-------------|------------|
| Go | `shopspring/decimal.Decimal` | `float64`, `float32` |
| Swift | `Foundation.Decimal` | `Double`, `Float` |
| Kotlin | `java.math.BigDecimal` | `Double`, `Float` |
| TypeScript | `big.js` or `decimal.js` | `number` (for calculations) |
| SQL | `NUMERIC(precision, scale)` | `REAL`, `DOUBLE PRECISION` (for money) |

### Rounding Rules
- Always specify rounding mode explicitly in decimal operations
- US stocks: prices to 4 decimal places, quantities to whole numbers (or fractional if supported)
- HK stocks: prices to 3 decimal places, quantities in board lots
- Commission/fees: round to 2 decimal places (half-up)
- Currency conversion: 6 decimal places for FX rate, 2 for final amount
- Fund transfer amounts: round to 2 decimal places

## Rule 2: Timestamps and Time Zones

- **Store**: All timestamps in UTC as `TIMESTAMP WITH TIME ZONE` in PostgreSQL
- **Transmit**: ISO 8601 format (`2024-01-15T09:30:00Z`)
- **Convert**: Only at the display layer (mobile app / admin panel)
- **Market hours**: Respect exchange-specific time zones (ET for NYSE/NASDAQ, HKT for HKEX)
- **Go**: Use `time.Time` with UTC location; never use `time.Now()` without `.UTC()`
- **Never**: Use unix timestamps for user-facing data (audit, reporting)

## Rule 3: Error Handling

### Go
```go
// CORRECT: Wrap errors with context
if err != nil {
    return fmt.Errorf("submit order %s: %w", orderID, err)
}

// WRONG: Naked return
if err != nil {
    return err
}

// WRONG: Swallowed error
result, _ := doSomething()
```

## Rule 4: Idempotency

All state-changing API endpoints must be idempotent:
- Accept an `Idempotency-Key` header (UUID v4)
- Store the key + response for 24 hours
- Return the cached response for duplicate requests
- This prevents double-orders from network retries

## Rule 5: Audit Logging

Every state-changing operation must produce an immutable audit record:

```json
{
  "event_type": "ORDER_SUBMITTED",
  "timestamp": "2024-01-15T09:30:00.123Z",
  "actor_id": "user-123",
  "actor_type": "CUSTOMER",
  "resource_type": "ORDER",
  "resource_id": "ord-456",
  "details": { "symbol": "AAPL", "side": "BUY", "qty": 100, "price": "150.25" },
  "ip_address": "192.168.1.1",
  "device_id": "dev-789",
  "correlation_id": "req-abc"
}
```

- Audit records are WRITE-ONLY. Never update or delete.
- Store in append-only table or immutable storage (S3 Object Lock).
- Retention: minimum 7 years (SEC Rule 17a-4).

## Rule 6: No Secrets in Code

- Never hardcode API keys, passwords, tokens, or connection strings
- Use environment variables or Vault/Secrets Manager
- `.env` files must be in `.gitignore`
- Even test credentials should use obviously-fake values (`test-api-key-not-real`)

## Rule 7: Input Validation

- Validate all user input at the API boundary
- Use allowlists over blocklists for order types, symbols, etc.
- Validate symbol format: US stocks (1-5 uppercase letters), HK stocks (4-5 digit codes)
- Validate order quantities: positive integers (or positive decimals for fractional shares)
- Validate prices: positive decimals with appropriate precision
- Reject requests with fields that exceed maximum length
