---
type: domain-rules
level: L4
service: market-data
status: ACTIVE
version: 1.0
last_updated: 2026-03-22
---

# Business Rules -- Market Data

## 1. Stale Detection Rules

### 1.1 Two-Tier Threshold

| Threshold | Use Case | Action |
|-----------|----------|--------|
| **1 second** | Trading risk control | Set `is_stale = true`, block market orders in Trading Engine |
| **5 seconds** | Display warning | Show "Delayed" badge in mobile UI |

### 1.2 Detection Logic

```
if (now_utc - quote.last_updated_at) > 1s:
    quote.is_stale = true
    // Trading Engine must reject market orders for this symbol

if (now_utc - quote.last_updated_at) > 5s:
    // Mobile displays "Delayed" warning badge
```

### 1.3 Invariants

- `is_stale` flag MUST be computed on every quote read (not stored)
- Stale quotes MUST still be returned (never return 404)
- Trading Engine MUST check `is_stale` before accepting market orders

## 2. Price Adjustment Rules (Corporate Actions)

### 2.1 Real-Time Quotes (Unadjusted)

- Real-time quotes use **unadjusted prices** (raw exchange prices)
- `change` and `change_pct` calculated against **previous Regular Session close** (16:00 ET)
- Pre-market/after-hours changes reference the same 16:00 ET close

### 2.2 Historical K-Line (Backward Adjusted)

Historical K-line data uses **backward adjustment** for splits and dividends:

**Split Adjustment:**
```
adjusted_price = raw_price / split_ratio
adjusted_volume = raw_volume * split_ratio

Example: 2-for-1 split on 2024-06-10
- Before split: $100/share, 1000 volume
- After adjustment: $50/share, 2000 volume
```

**Dividend Adjustment:**
```
adjustment_factor = 1 - (dividend / close_price_before_ex_date)
adjusted_price = raw_price * adjustment_factor

Example: $2 dividend, close before ex-date = $100
- adjustment_factor = 1 - (2/100) = 0.98
- Historical prices multiplied by 0.98
```

### 2.3 Invariants

- Real-time quotes NEVER adjusted (always raw exchange prices)
- Historical K-line ALWAYS adjusted (for chart continuity)
- Adjustment metadata stored in `corporate_actions` table

## 3. Market Status State Machine

### 3.1 US Market (NYSE/NASDAQ)

```
CLOSED → PRE_MARKET (04:00-09:30 ET) → REGULAR (09:30-16:00 ET) → AFTER_HOURS (16:00-20:00 ET) → CLOSED
         ↓                                    ↓
       HALTED ←──────────────────────────── HALTED
```

### 3.2 HK Market (HKEX)

```
CLOSED → PRE_MARKET (09:00-09:30 HKT) → REGULAR (09:30-12:00, 13:00-16:00 HKT) → CLOSED
                                              ↓
                                           HALTED
```

### 3.3 State Transitions

- `CLOSED` → `PRE_MARKET`: Automatic at market open time
- `PRE_MARKET` → `REGULAR`: Automatic at regular session start
- `REGULAR` → `AFTER_HOURS`: Automatic at regular session close (US only)
- `REGULAR` → `HALTED`: Manual trigger or circuit breaker
- `HALTED` → `REGULAR`: Manual resume after halt cleared

### 3.4 Invariants

- Market status checked before order submission
- Limit orders allowed in PRE_MARKET and AFTER_HOURS
- Market orders blocked outside REGULAR session

## 4. Watchlist Rules

### 4.1 Capacity Limit

- Maximum 100 symbols per user
- Attempt to add 101st symbol returns error: `WATCHLIST_LIMIT_EXCEEDED`

### 4.2 Idempotency

- Adding duplicate symbol returns `200 OK` (idempotent, no error)
- Response includes `already_exists: true` flag

### 4.3 Deletion

- Deleting non-existent symbol returns `404 NOT_FOUND`
- Soft delete: mark `deleted_at`, retain for audit (30 days)

## 5. Delayed Quote Rules (Guest Users)

### 5.1 Delay Requirement

- Guest users (unauthenticated or `user_type=guest`) receive **15-minute delayed quotes**
- Registered users receive real-time quotes

### 5.2 Implementation

- Use `DelayedQuoteRingBuffer` with 20 slots (1-minute snapshots)
- Guest connections read from `RingBuffer[T-15min]`
- Push frequency: every 5 seconds (not tick-level)

### 5.3 Labeling

- All delayed quotes MUST include `"delayed": true` in response
- Mobile UI MUST display "Delayed 15 min" label

## 6. Data Licensing Requirements

### 6.1 Redistribution Restrictions

- **Standard Polygon API**: Prohibits redistribution to end users
- **Production requirement**: Must use Polygon Poly.feed+ or direct NYSE/Nasdaq Vendor Agreement
- **Compliance**: P0 blocker before production launch

### 6.2 Index Data

- S&P 500, DJIA, Nasdaq Composite require separate licensing
- **Phase 1 workaround**: Use ETF proxies (SPY, DIA, QQQ)
- **Labeling requirement**: Display as "SPY (tracking S&P 500)", NOT "S&P 500"

## 7. Change Calculation Rules

### 7.1 Basis Definition

- `change` = current_price - previous_regular_close
- `change_pct` = (change / previous_regular_close) × 100
- **Basis**: Previous Regular Session close at 16:00 ET (US) or 16:00 HKT (HK)

### 7.2 Extended Hours

- Pre-market and after-hours changes reference the SAME 16:00 ET close
- Do NOT use after-hours close as next day's basis

## 8. Symbol Validation

### 8.1 US Stocks

- Format: 1-5 uppercase letters, optional dot suffix
- Regex: `^[A-Z]{1,5}(\.[A-Z])?$`
- Examples: `AAPL`, `TSLA`, `BRK.A`

### 8.2 HK Stocks

- Format: 4-5 digit code with leading zeros
- Regex: `^[0-9]{4,5}$`
- Examples: `00700`, `09988`, `00001`
