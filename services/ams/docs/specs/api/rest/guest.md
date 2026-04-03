# REST API — Guest Mode Endpoint

**Service**: AMS (Account Management Service)  
**Version**: v1.0  
**Last Updated**: 2026-04-01  
**Status**: FINAL  

---

## Overview

The AMS Guest Mode API provides a single endpoint to initiate guest sessions without authentication. Guest sessions allow users to browse delayed market data (15-minute quotes per SEC Regulation NMS) and access limited pages before logging in. This reduces friction for new users while maintaining compliance.

### Key Design Principles

1. **No Authentication Required**: Guest sessions use IP-based tracking (not cookies, to support unauthenticated state).
2. **Delayed Market Data**: All quotes are 15+ minutes delayed and prominently labeled per SEC requirements.
3. **Session Expiry**: 7-day TTL on guest sessions; automatic cleanup on login (upgrade to authenticated).
4. **Page Access Matrix**: 6 pages with varying access levels (3 accessible, 3 restricted).
5. **No PII Storage**: Guest sessions contain no personally identifiable information.

---

## Endpoint Summary

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/v1/guest/session` | None | Initiate guest session |

---

## Create Guest Session

**Endpoint**: `POST /v1/guest/session`

**Purpose**: Initialize a guest session for unauthenticated browsing.

### Request

```yaml
headers:
  X-Device-ID:
    type: string
    format: uuid
    description: "Optional. Device ID for correlation (can be null for web/incognito)"
    required: false
  X-Client-Version:
    type: string
    description: "Mobile app version or web app version (for analytics)"
    example: "1.2.3"
    required: false
  Content-Type: application/json

body:
  type: object
  properties:
    source:
      type: string
      enum: [MOBILE_IOS, MOBILE_ANDROID, WEB_BROWSER]
      description: "Origin of guest session"
    market:
      type: string
      enum: [US, HK, GLOBAL]
      description: "Which market quotes user wants to browse (optional; defaults to GLOBAL)"
      default: GLOBAL
    captcha_token:
      type: string
      description: "reCAPTCHA v3 token (optional but recommended for bot protection)"
      nullable: true
```

### Response — 201 Created

```yaml
type: object
properties:
  guest_session_id:
    type: string
    format: uuid
    description: "Opaque guest session ID; used in subsequent requests via X-Guest-Session-ID header"
    example: "gst_550e8400-e29b-41d4-a716-446655440000"
  expires_at:
    type: string
    format: date-time
    description: "Session expiry (7 days from creation)"
    example: "2026-04-08T14:35:00Z"
  expires_in_seconds:
    type: integer
    example: 604800
  accessible_pages:
    type: array
    items:
      type: string
      enum:
        - QUOTE_HOME
        - STOCK_DETAIL
        - SEARCH
    description: "Pages accessible in guest mode"
  restricted_pages:
    type: array
    items:
      type: string
      enum:
        - ORDERS
        - HOLDINGS
        - PROFILE
    description: "Pages that require login"
  data_characteristics:
    type: object
    properties:
      quotes_delayed_minutes:
        type: integer
        example: 15
      quote_label:
        type: string
        example: "Delayed 15 minutes (not real-time)"
      trading_disabled:
        type: boolean
        example: true
      watchlist_local_only:
        type: boolean
        example: true
        description: "Watchlists stored locally (not synced to server)"
  session_type:
    type: string
    enum: [GUEST]
```

### Response — 429 Too Many Requests

Triggered when:
- Same IP exceeds 100 requests per hour (bot protection)
- Same IP exceeds 10 sessions per minute (session spam)

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [RATE_LIMIT_EXCEEDED, SESSION_SPAM_DETECTED, CAPTCHA_REQUIRED]
  message:
    type: string
    example: "Too many guest sessions created. Please solve CAPTCHA to continue."
  captcha_required:
    type: boolean
  retry_after_seconds:
    type: integer
    example: 60
```

### Response — 400 Bad Request

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [INVALID_REQUEST, CAPTCHA_FAILED, GEOLOCATION_BLOCKED]
  message:
    type: string
  details:
    type: object
    nullable: true
    example:
      reason: "Service not available in your region"
```

### Implementation Notes

- **Session Creation**:
  1. Validate request (CAPTCHA if required).
  2. Generate 32-byte random session ID.
  3. Insert into `guest_sessions` table:
     ```sql
     INSERT INTO guest_sessions (
       guest_session_id, ip_address, user_agent, country_code, city,
       created_at, expires_at, status, page_views, trading_disabled
     ) VALUES (?, ?, ?, ?, ?, now(), now() + INTERVAL 7 DAY, 'ACTIVE', 0, true);
     ```
  4. Cache session in Redis with 7-day TTL: `guest_session:{session_id}`.

- **GeoIP Lookup**: Resolve IP address to country/city for:
  - Blocking guests from restricted regions (if applicable).
  - Analytics and fraud detection.
  - Display in "access from X location" context.

- **CAPTCHA Validation**: If `captcha_token` provided:
  1. Call Google reCAPTCHA API.
  2. If score < 0.5, return 400 with `CAPTCHA_FAILED`.
  3. If score >= 0.5, proceed.

- **Kafka Event**: Publish `guest.session_created` with:
  ```json
  {
    "guest_session_id": "gst_...",
    "ip_address": "...",
    "country_code": "US",
    "created_at": "2026-04-01T14:35:00Z",
    "source": "MOBILE_IOS"
  }
  ```

- **Rate Limiting**:
  - Per IP: 100 requests/hour (all endpoints).
  - Per IP: 10 session creations/minute.
  - Redis counters: `rate_limit:create_guest_session:{ip}`.

---

## Guest Session Lifecycle

### Page Access Matrix

| Page | Guest Mode | Authenticated | Delayed Data | Notes |
|------|-----------|---------------|--------------|-------|
| **Quote Home** | ✅ Yes | ✅ Yes | 15 min delay | Shows market overview, top gainers/losers, trending stocks |
| **Stock Detail** | ✅ Yes | ✅ Yes | 15 min delay | Stock charts, company info, fundamentals (non-real-time) |
| **Search** | ✅ Yes | ✅ Yes | 15 min delay | Symbol/company search, quick quote lookup |
| **Orders** | ❌ Restricted | ✅ Yes | N/A | Requires login; shows "Login to place orders" sheet |
| **Holdings** | ❌ Restricted | ✅ Yes | N/A | Requires login; shows "Login to view portfolio" sheet |
| **Profile** | ❌ Restricted | ✅ Yes | N/A | Requires login; shows "Login to manage account" sheet |

### Session States

```
ACTIVE
  ├─→ [User browses 7 days] → EXPIRED
  ├─→ [User logs in] → UPGRADED_TO_USER (account_id set, status UPGRADED)
  └─→ [Server cleanup after 7 days] → CLEANED_UP
```

### Transition: Guest → Authenticated

When user completes OTP verification in authenticated flow:

1. OTP verify endpoint (from `auth.md`) checks if `request_id` came from guest context.
2. If yes, update `guest_sessions` row:
   ```sql
   UPDATE guest_sessions 
   SET status = 'UPGRADED', account_id = ?, upgraded_at = now() 
   WHERE guest_session_id = ?;
   ```
3. Return account and tokens in OTP verify response (same as non-guest flow).
4. Mobile app transitions from guest state to authenticated state.
5. Publish `guest.upgraded_to_user` Kafka event (for analytics).

### Watchlist Handling

- Guest watchlists stored in `localStorage` (mobile app) or `indexedDB` (web).
- **Not synced** to server during guest session.
- On upgrade to authenticated user:
  - Client calls new endpoint: `POST /v1/watchlist/sync-from-guest` with local watchlist symbols.
  - Server creates `watchlist_items` entries for the new account.
  - Client clears local guest watchlist.

---

## Login Sheet Trigger

When user clicks **Buy/Sell** or **Add to Watchlist** on guest session:

1. Mobile app shows **Login Sheet** with:
   - Header: "Create Free Account"
   - Text: "Sign in to start trading and manage your portfolio"
   - CTA: "Continue with Phone Number"
   - Secondary: "Already have an account? Sign in"

2. User taps CTA → navigates to `/v1/auth/otp/send` (from `auth.md` § 1).

3. Server detects guest context and:
   - If OTP send is first-time user: display "Complete Profile" screen.
   - If OTP send is returning user: issue tokens directly after OTP verify.

---

## SEC Compliance: Delayed Data Labeling

All guest session quote displays must include **persistent labeling**:

```
┌─────────────────────────────────────┐
│  AAPL  150.25  ↑ 2.15 (1.45%)      │
├─────────────────────────────────────┤
│  Delayed 15 minutes (Not real-time) │  ← Prominent label
└─────────────────────────────────────┘
```

### Labeling Rules

- **Placement**: Below price/change (or integrated into header for compact layouts).
- **Visibility**: 11pt font minimum (readable on all devices).
- **Color**: Neutral gray (#666 or equivalent), not mixed with positive/negative price color.
- **Always visible**: Never collapsed, hidden in scroll, or dismissible by user.
- **Persistence**: On every screen that displays quotes (home, stock detail, search results).

### References

- SEC Regulation NMS, Rule 10b-35, § (d): "Disparity of 15 minutes with respect to the most recent transaction"
- SHO Regulation, § 242.200: Enhanced labeling for delayed quotes.

---

## Database Schema

### guest_sessions Table

```sql
CREATE TABLE guest_sessions (
  guest_session_id CHAR(36) PRIMARY KEY,
  account_id VARCHAR(50) NULL,
  ip_address VARCHAR(45) NOT NULL,
  user_agent TEXT,
  country_code CHAR(2),
  city VARCHAR(100),
  source ENUM('MOBILE_IOS', 'MOBILE_ANDROID', 'WEB_BROWSER'),
  status ENUM('ACTIVE', 'UPGRADED', 'EXPIRED', 'CLEANED_UP') DEFAULT 'ACTIVE',
  page_views INT DEFAULT 0,
  trading_disabled BOOLEAN DEFAULT true,
  local_watchlist JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  upgraded_at TIMESTAMP NULL,
  expires_at TIMESTAMP NOT NULL,
  cleaned_up_at TIMESTAMP NULL,
  
  KEY idx_ip_address (ip_address),
  KEY idx_created_at (created_at),
  KEY idx_expires_at (expires_at),
  KEY idx_status (status),
  FOREIGN KEY (account_id) REFERENCES users(account_id) ON DELETE SET NULL
);
```

### Indexes

- `idx_ip_address`: For rate limiting per IP.
- `idx_expires_at`: For daily cleanup job (DELETE WHERE expires_at < now()).
- `idx_status`: For querying active vs. upgraded sessions.

---

## Cleanup Job

Daily scheduled job (recommended 02:00 UTC):

```sql
DELETE FROM guest_sessions 
WHERE expires_at < now() 
AND status IN ('ACTIVE', 'EXPIRED');

UPDATE guest_sessions 
SET status = 'CLEANED_UP', cleaned_up_at = now() 
WHERE expires_at < now() - INTERVAL 30 DAY;
```

---

## Security & Compliance

### Rate Limiting

| Action | Limit | Window | Scope |
|--------|-------|--------|-------|
| POST /guest/session | 10 | 1min | per IP |
| POST /guest/session | 100 | 1hour | per IP |

### Fraud Detection

- Flag IPs creating > 50 sessions per day → require CAPTCHA.
- Block IPs from sanctioned countries (OFAC).
- Monitor session-to-login conversion rates (if < 0.1%, possible fraud/crawling).

### No PII Storage

- Never store email, phone, name, or any user-identifiable info in `guest_sessions`.
- IP address and User-Agent for analytics only; not linked to marketing.
- Comply with GDPR Article 4(1) (no personal data = no GDPR scope for guest sessions).

### Analytics & Privacy

- Guest session metrics (page views, conversion to login, market interest) are collected for:
  - A/B testing (placement of login prompts).
  - Product analytics (market interest by region).
  - Fraud detection (suspicious patterns).
- All metrics anonymized by default; linked to account only after upgrade.
- Retention: 90 days for raw sessions, 2 years for aggregated metrics.

---

## Related Specifications

- **Guest Mode (System Design)**: See `guest-mode.md` for detailed business logic, page permissions, and SEC compliance rules.
- **Authentication**: See `auth.md` for OTP send/verify endpoints and login flow.
- **Market Data API**: See `services/market-data/.../rest/quotes.md` for quote delay logic (must check session type and apply 15-min delay).

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-01 | Initial OpenAPI 3.0 specification for guest session endpoint |

