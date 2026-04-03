# REST API — Profile Endpoints

**Service**: AMS (Account Management Service)  
**Version**: v1.0  
**Last Updated**: 2026-04-01  
**Status**: FINAL  

---

## Overview

The AMS Profile API provides endpoints for retrieving and updating user profile information, including PII fields (name, SSN, HKID, DOB). All PII fields are encrypted at the database layer and decrypted transparently by the API. Sensitive updates (email, phone, document upload) require biometric verification.

### Key Design Principles

1. **PII Encryption**: All encrypted fields (SSN, HKID, DOB) are decrypted on retrieval and returned in plaintext to authenticated clients only.
2. **Blind Indexing**: Searchable PII fields (phone_number, email) use blind index hashes for querying without exposing plaintext in DB.
3. **Audit Trail**: Every profile update is logged immutably with actor, timestamp, IP, and change delta.
4. **Biometric Protection**: Email/phone changes and document uploads require `X-Biometric-Verified` header.

---

## Endpoints Summary

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/v1/profile` | Access Token | Retrieve user profile (decrypted) |
| PUT | `/v1/profile` | Access Token + Biometric | Update profile |
| GET | `/v1/profile/account-status` | Access Token | Retrieve account status (KYC, AML, restrictions) |

---

## 1. Get Profile

**Endpoint**: `GET /v1/profile`

**Purpose**: Retrieve user profile with PII fields decrypted.

### Request

```yaml
headers:
  Authorization:
    type: string
    description: "Bearer <access_token>"
    required: true
  Content-Type: application/json
```

### Response — 200 OK

```yaml
type: object
properties:
  account_id:
    type: string
    example: "acc-123"
  email:
    type: string
    format: email
    description: "Primary email address"
    example: "alice@example.com"
  phone_number:
    type: string
    description: "E.164 format"
    example: "+1206555-0100"
  first_name:
    type: string
    example: "Alice"
  last_name:
    type: string
    example: "Smith"
  date_of_birth:
    type: string
    format: date
    description: "ISO 8601 format (YYYY-MM-DD)"
    example: "1990-05-15"
  nationality:
    type: string
    description: "ISO 3166-1 alpha-2 code"
    example: "US"
  ssn:
    type: string
    description: "US Social Security Number, decrypted"
    example: "123-45-6789"
  ssn_masked:
    type: string
    description: "For UI display (read-only)"
    example: "***-**-6789"
  hkid:
    type: string
    description: "Hong Kong ID, decrypted"
    example: "A123456(7)"
  hkid_masked:
    type: string
    description: "For UI display (read-only)"
    example: "A****(7)"
  address:
    type: object
    properties:
      street_line_1:
        type: string
      street_line_2:
        type: string
      city:
        type: string
      state_province:
        type: string
      postal_code:
        type: string
      country:
        type: string
        description: "ISO 3166-1 alpha-2"
  employment_status:
    type: string
    enum: [EMPLOYED, SELF_EMPLOYED, UNEMPLOYED, RETIRED, STUDENT]
  employment_industry:
    type: string
    nullable: true
  annual_income_range:
    type: string
    enum: [UNDER_50K, 50K_100K, 100K_500K, 500K_1M, OVER_1M]
    nullable: true
  net_worth_range:
    type: string
    enum: [UNDER_100K, 100K_500K, 500K_1M, 1M_5M, OVER_5M]
    nullable: true
  investment_experience:
    type: string
    enum: [BEGINNER, INTERMEDIATE, ADVANCED]
  investment_objective:
    type: string
    enum: [CAPITAL_PRESERVATION, INCOME, GROWTH, AGGRESSIVE_GROWTH]
  risk_tolerance:
    type: string
    enum: [CONSERVATIVE, MODERATE, AGGRESSIVE]
  account_created_at:
    type: string
    format: date-time
  account_kyc_status:
    type: string
    enum: [PENDING, APPROVED, REJECTED]
  account_aml_status:
    type: string
    enum: [CLEAR, REVIEW, FLAGGED]
  profile_completeness_percent:
    type: integer
    description: "Percentage of required fields filled"
    example: 95
```

### Response — 401 Unauthorized

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [INVALID_ACCESS_TOKEN, TOKEN_EXPIRED]
```

### Implementation Notes

- **PII Decryption**: Query `users` table and decrypt fields: `ssn`, `hkid`, `date_of_birth` using AES-256-GCM key from Vault.
- **Audit Log**: Log retrieval with correlation_id, ip_address, timestamp.
- **Database Query**:
  ```sql
  SELECT account_id, email, phone_number, first_name, last_name,
         AES_DECRYPT(ssn, KEY(ssn_key)) as ssn,
         AES_DECRYPT(hkid, KEY(hkid_key)) as hkid,
         AES_DECRYPT(dob, KEY(dob_key)) as date_of_birth,
         ...
  FROM users WHERE account_id = ? LIMIT 1;
  ```

---

## 2. Update Profile

**Endpoint**: `PUT /v1/profile`

**Purpose**: Update user profile. Sensitive updates (email, phone, SSN, HKID) require biometric verification.

### Request

```yaml
headers:
  Authorization:
    type: string
    description: "Bearer <access_token>"
    required: true
  X-Device-ID:
    type: string
    format: uuid
    required: true
  X-Biometric-Verified:
    type: string
    description: "Required if updating: email, phone_number, ssn, hkid, date_of_birth. HMAC-SHA256(timestamp|device_id|profile_update, biometric_secret)"
    required: false
  Content-Type: application/json

body:
  type: object
  properties:
    first_name:
      type: string
      minLength: 1
      maxLength: 100
      nullable: false
    last_name:
      type: string
      minLength: 1
      maxLength: 100
      nullable: false
    email:
      type: string
      format: email
      description: "Requires biometric verification and re-verification link"
    phone_number:
      type: string
      pattern: "^\\+[1-9]\\d{1,14}$"
      description: "Requires biometric verification and OTP confirmation"
    date_of_birth:
      type: string
      format: date
      description: "Requires biometric verification (immutable after KYC)"
    ssn:
      type: string
      pattern: "^\\d{3}-\\d{2}-\\d{4}$"
      description: "Requires biometric verification (immutable after KYC approval)"
    hkid:
      type: string
      pattern: "^[A-Z]\\d{6}\\([0-9A]\\)$"
      description: "Requires biometric verification (immutable after KYC approval)"
    address:
      type: object
      properties:
        street_line_1:
          type: string
          maxLength: 255
        street_line_2:
          type: string
          maxLength: 255
        city:
          type: string
          maxLength: 100
        state_province:
          type: string
          maxLength: 100
        postal_code:
          type: string
          maxLength: 20
        country:
          type: string
          pattern: "^[A-Z]{2}$"
          description: "ISO 3166-1 alpha-2"
    employment_status:
      type: string
      enum: [EMPLOYED, SELF_EMPLOYED, UNEMPLOYED, RETIRED, STUDENT]
    employment_industry:
      type: string
      nullable: true
    annual_income_range:
      type: string
      enum: [UNDER_50K, 50K_100K, 100K_500K, 500K_1M, OVER_1M]
      nullable: true
    net_worth_range:
      type: string
      enum: [UNDER_100K, 100K_500K, 500K_1M, 1M_5M, OVER_5M]
      nullable: true
    investment_experience:
      type: string
      enum: [BEGINNER, INTERMEDIATE, ADVANCED]
    investment_objective:
      type: string
      enum: [CAPITAL_PRESERVATION, INCOME, GROWTH, AGGRESSIVE_GROWTH]
    risk_tolerance:
      type: string
      enum: [CONSERVATIVE, MODERATE, AGGRESSIVE]
```

### Response — 200 OK

```yaml
type: object
properties:
  account_id:
    type: string
  updated_fields:
    type: array
    items:
      type: string
    description: "List of fields that were updated"
    example: ["first_name", "address.city"]
  profile_completeness_percent:
    type: integer
  pending_verifications:
    type: array
    items:
      type: object
      properties:
        field:
          type: string
          enum: [EMAIL, PHONE_NUMBER]
        verification_token:
          type: string
          description: "Token sent to email/SMS for confirmation"
        verification_method:
          type: string
          enum: [EMAIL_LINK, OTP]
        expires_in_seconds:
          type: integer
          example: 86400
    description: "For email/phone changes, user must confirm via link or OTP"
```

### Response — 400 Bad Request

```yaml
type: object
properties:
  error_code:
    type: string
    enum:
      - INVALID_REQUEST
      - FIELD_IMMUTABLE
      - BIOMETRIC_VERIFICATION_REQUIRED
      - EMAIL_ALREADY_REGISTERED
      - PHONE_ALREADY_REGISTERED
  message:
    type: string
  details:
    type: object
    description: "Field-level validation errors"
    example:
      email: "Email is already registered"
      ssn: "Cannot update SSN after KYC approval"
```

### Response — 401 Unauthorized

```yaml
type: object
properties:
  error_code:
    type: string
    enum:
      - INVALID_ACCESS_TOKEN
      - INVALID_BIOMETRIC_SIGNATURE
  message:
    type: string
```

### Implementation Notes

- **Immutable Fields After KYC**: Once KYC status is APPROVED, SSN and HKID cannot be changed. Return 400 with `FIELD_IMMUTABLE`.
- **Biometric Verification Check**:
  ```
  sensitive_fields = {email, phone_number, ssn, hkid, date_of_birth}
  if any(field in request.body for field in sensitive_fields):
      if X-Biometric-Verified header missing or invalid:
          return 401 INVALID_BIOMETRIC_SIGNATURE
  ```
- **Email/Phone Verification**:
  1. On email update, generate 32-byte random token.
  2. Send verification link: `https://app.example.com/verify-email?token=...`.
  3. Insert into `email_verifications` table with `token_hash`, `new_email`, `expires_at = now() + 24h`.
  4. Return pending verification in response.
  5. Only update user.email when verification endpoint called with valid token.
- **Blind Index Update**: If phone_number changes, recompute blind index hash and update `users.phone_number_blind_index`.
- **Audit Trail**: Log update in `audit_log` table with:
  ```json
  {
    "event_type": "PROFILE_UPDATED",
    "account_id": "...",
    "timestamp": "...",
    "ip_address": "...",
    "changed_fields": ["first_name", "address.city"],
    "device_id": "...",
    "correlation_id": "..."
  }
  ```
- **Kafka Event**: Publish `account.profile_updated` with `account_id`, `changed_fields`.

---

## 3. Get Account Status

**Endpoint**: `GET /v1/profile/account-status`

**Purpose**: Retrieve account compliance status (KYC, AML, restrictions, W-8BEN, etc.).

### Request

```yaml
headers:
  Authorization:
    type: string
    description: "Bearer <access_token>"
    required: true
  Content-Type: application/json
```

### Response — 200 OK

```yaml
type: object
properties:
  account_id:
    type: string
  account_status:
    type: string
    enum: [ACTIVE, PENDING_KYC, SUSPENDED, CLOSED]
  kyc_status:
    type: string
    enum: [PENDING, APPROVED, REJECTED, SUSPENDED]
  kyc_last_reviewed_at:
    type: string
    format: date-time
    nullable: true
  kyc_next_review_due:
    type: string
    format: date-time
    nullable: true
    description: "Annual KYC refresh required 365 days after approval"
  aml_status:
    type: string
    enum: [CLEAR, REVIEW, FLAGGED, SUSPENDED]
    description: "Latest AML screening result"
  aml_last_screened_at:
    type: string
    format: date-time
  aml_risk_score:
    type: number
    format: float
    nullable: true
    description: "0.0 (low risk) to 1.0 (high risk). Null if CLEAR."
  aml_issues:
    type: array
    items:
      type: object
      properties:
        type:
          type: string
          enum: [OFAC_MATCH, HK_DESIGNATED_PERSON, PEP_CLASSIFIED, STRUCTURING_DETECTED, ROUND_TRIPPING, VELOCITY_ANOMALY]
        description:
          type: string
        action_required:
          type: boolean
    description: "AML issues requiring user action (if any)"
  w8ben_status:
    type: string
    enum: [NOT_REQUIRED, PENDING, VERIFIED, EXPIRED]
    description: "W-8BEN tax form status (for non-US persons trading US stocks)"
  w8ben_expires_at:
    type: string
    format: date-time
    nullable: true
    description: "W-8BEN forms expire 3 years from signature date"
  w8ben_days_until_expiry:
    type: integer
    nullable: true
    description: "Days remaining; null if not applicable or valid"
  restrictions:
    type: array
    items:
      type: object
      properties:
        type:
          type: string
          enum: [TRADING_DISABLED, WITHDRAWAL_DISABLED, DEPOSIT_DISABLED, ALL_DISABLED]
        reason:
          type: string
          enum: [AML_FLAG, KYC_INCOMPLETE, COMPLIANCE_HOLD, ACCOUNT_SUSPENDED, MANUAL_REVIEW]
        effective_from:
          type: string
          format: date-time
        effective_until:
          type: string
          format: date-time
          nullable: true
        resolution_action:
          type: string
          nullable: true
          example: "Complete W-8BEN form"
    description: "Active trading/withdrawal restrictions"
  communication_preferences:
    type: object
    properties:
      marketing_email_enabled:
        type: boolean
      marketing_sms_enabled:
        type: boolean
      compliance_notifications_enabled:
        type: boolean
        description: "Cannot be disabled; required for compliance"
  last_login_at:
    type: string
    format: date-time
  last_ip_address:
    type: string
    description: "Last login IP (for security awareness)"
  account_age_days:
    type: integer
    description: "Days since account creation"
```

### Response — 401 Unauthorized

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [INVALID_ACCESS_TOKEN]
```

### Implementation Notes

- **Query Join**: Retrieve from `users`, `kyc_applications`, `aml_screenings`, `account_restrictions` tables.
- **W-8BEN Logic**:
  ```
  if user.nationality != 'US' AND trading_us_stocks:
      kyc.w8ben_status = fetch from w8ben_forms table
      if exists:
          w8ben_expires_at = signature_date + 3 years
          days_until_expiry = max(0, (expires_at - now()).days)
  ```
- **Restrictions Calculation**:
  ```
  SELECT * FROM account_restrictions 
  WHERE account_id = ? 
  AND effective_from <= now() 
  AND (effective_until IS NULL OR effective_until > now())
  ```
- **AML Issues**: Query latest `aml_screening_issues` for account; display user-facing descriptions.
- **No Sensitive Info**: Never return AML screening rationale (internal use only) or detailed PEP classification (Yes/No only).

---

## Security & Compliance

### PII Field Classification

| Field | Encryption | Blind Index | Masking |
|-------|-----------|------------|---------|
| SSN | AES-256-GCM | Yes | ***-**-6789 |
| HKID | AES-256-GCM | Yes | A****(7) |
| DOB | AES-256-GCM | No | Hidden from other users |
| Email | Not encrypted | Yes (blind index for query) | j***e@example.com in logs |
| Phone | Not encrypted | Yes (blind index for query) | +1206***0100 in logs |

### Rate Limiting

| Endpoint | Limit | Window | Scope |
|----------|-------|--------|-------|
| GET /profile | 10 | 1min | per account_id |
| PUT /profile | 5 | 1min | per account_id |
| GET /profile/account-status | 10 | 1min | per account_id |

### Audit & Logging

- Every GET /profile retrieval logged with correlation_id (searchable by audit).
- Every PUT /profile update logged with delta (before/after hash, not plaintext).
- Logs retained for 7 years in cold storage (SEC Rule 17a-4).
- No unencrypted PII in logs; use masking utility.

### Related Specifications

- **PII Encryption**: See `pii-encryption.md` for encryption key management and field classification.
- **KYC Status**: See `kyc-flow.md` for KYC application lifecycle and review workflow.
- **AML Screening**: See `aml-compliance.md` for AML risk scoring and restriction triggers.
- **Auth Architecture**: See `auth-architecture.md` § 1 for Account model and required fields.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-01 | Initial OpenAPI 3.0 specification for 3 profile endpoints |

