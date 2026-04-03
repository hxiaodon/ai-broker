# AMS ↔ Admin Panel Backend Contract

**Version**: v1.0  
**Last Updated**: 2026-04-01  
**Status**: FINAL  

**Services**: AMS ← → Admin Panel  
**Protocol**: gRPC + REST (OpenAPI 3.0)  
**Audience**: Admin Panel Backend Engineers, Compliance Ops Team  

---

## Overview

This contract defines the interface between AMS (Account Management Service) and the Admin Panel backend for operational and compliance workflows. Admin Panel is a **React + Node.js** application used by compliance officers, KYC reviewers, and support staff to manage user accounts, review KYC applications, handle AML flags, and enforce account restrictions.

### Design Principles

1. **Role-Based Access Control (RBAC)**: All admin endpoints require role validation (KYC_REVIEWER, AML_ANALYST, COMPLIANCE_OFFICER, ACCOUNT_MANAGER, SUPPORT_AGENT).
2. **Audit Trail**: Every action (approve KYC, flag account, update restriction) logged immutably with actor, timestamp, reason.
3. **Bulk Operations**: Endpoints support batch updates for operational efficiency (e.g., bulk account unlock).
4. **Search & Filter**: Full-text search on user names, emails, and account IDs with date range filtering.
5. **Real-Time Notifications**: Kafka events published for KYC approvals, account locks, etc., consumed by Admin Panel for live dashboard updates.

### Service Dependencies

- **Primary Data Source**: AMS database (users, kyc_applications, aml_screenings, account_restrictions).
- **Event Feed**: Kafka topics (`kyc.*`, `aml.*`, `account.*`, `auth.*`).
- **Authentication**: Bearer token (JWT) issued by Admin Panel's own auth service, validated by AMS via `/admin/verify-token` endpoint.

---

## API Endpoints

### 1. Authentication & Authorization

**Endpoint**: `POST /admin/verify-token` (gRPC: `AdminService.VerifyToken`)

Admin Panel backend calls this to validate its own JWT token with AMS (cross-service token validation).

#### Request (gRPC)

```protobuf
service AdminService {
  rpc VerifyToken(VerifyTokenRequest) returns (VerifyTokenResponse);
}

message VerifyTokenRequest {
  string admin_token = 1;
  string required_role = 2; // KYC_REVIEWER, AML_ANALYST, COMPLIANCE_OFFICER, etc.
}

message VerifyTokenResponse {
  bool valid = 1;
  string admin_id = 2;
  string admin_name = 3;
  repeated string roles = 4;
  int64 expires_at_unix = 5;
  string error_message = 6;
}
```

#### Request (REST)

```yaml
POST /admin/verify-token
headers:
  Authorization: Bearer <admin_token>
  Content-Type: application/json

body:
  required_role: KYC_REVIEWER
```

#### Response

```yaml
200 OK:
  valid: true
  admin_id: "adm-789"
  admin_name: "John Reviewer"
  roles: ["KYC_REVIEWER", "COMPLIANCE_OFFICER"]
  expires_at_unix: 1743750000

401 Unauthorized:
  valid: false
  error_message: "Token expired or invalid"
```

---

### 2. KYC Management

#### 2.1 List KYC Applications (Review Queue)

**Endpoint**: `GET /admin/kyc/applications` (gRPC: `AdminService.ListKycApplications`)

Retrieve paginated list of KYC applications with filtering and sorting.

##### Request

```yaml
query_parameters:
  page: 1
  page_size: 50
  status: [SUBMITTED, IN_REVIEW, APPROVED, REJECTED, PENDING_RESUBMISSION]
  days_pending: 7  # Applications pending for > 7 days
  risk_score_min: 0.5  # Filter by risk score
  risk_score_max: 1.0
  sort_by: DAYS_PENDING  # DAYS_PENDING, RISK_SCORE, CREATED_AT
  date_from: 2026-03-01
  date_to: 2026-04-01
  search_query: "alice@example.com OR acc-123"  # Name, email, account_id

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: KYC_REVIEWER
```

##### Response

```yaml
200 OK:
  applications:
    - application_id: kyc-001
      account_id: acc-123
      user_name: Alice Smith
      email: alice@example.com
      phone_masked: +1206***0100
      status: SUBMITTED
      submitted_at: 2026-03-28T10:00:00Z
      days_pending: 4
      risk_score: 0.65  # 0-1, higher = riskier
      risk_factors: [LARGE_INITIAL_DEPOSIT, FREQUENT_DEPOSITS]
      documents:
        - id: doc-1
          type: IDENTITY_PROOF
          status: VERIFIED
          uploaded_at: 2026-03-28T10:00:00Z
        - id: doc-2
          type: PROOF_OF_ADDRESS
          status: NEEDS_REVIEW
      reviewer_notes: null
      previous_rejections: 0
      jurisdiction: US  # US or HK
  pagination:
    total_count: 523
    total_pages: 11
    has_next_page: true
  unreviewed_count: 187  # High priority
  urgent_count: 23  # Pending > 30 days
```

#### 2.2 Get KYC Application Details

**Endpoint**: `GET /admin/kyc/applications/{application_id}` (gRPC: `AdminService.GetKycApplication`)

Retrieve full details of a KYC application including document images and decision history.

##### Request

```yaml
path_parameters:
  application_id: kyc-001

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: KYC_REVIEWER
```

##### Response

```yaml
200 OK:
  application_id: kyc-001
  account_id: acc-123
  user_profile:
    account_id: acc-123
    first_name: Alice
    last_name: Smith
    email: alice@example.com
    phone_masked: +1206***0100
    date_of_birth: 1990-05-15
    nationality: US
    employment_status: EMPLOYED
    annual_income_range: 100K_500K
    account_created_at: 2026-01-15T12:00:00Z
  application_meta:
    status: SUBMITTED
    submitted_at: 2026-03-28T10:00:00Z
    jurisdiction: US
    risk_score: 0.65
    risk_factors: [LARGE_INITIAL_DEPOSIT, FREQUENT_DEPOSITS]
  documents:
    - document_id: doc-1
      type: IDENTITY_PROOF  # IDENTITY_PROOF, PROOF_OF_ADDRESS, INCOME_VERIFICATION
      description: "Driver's License"
      uploaded_at: 2026-03-28T10:00:00Z
      status: VERIFIED
      image_urls:
        - front: "https://cdn.example.com/kyc/doc-1-front.jpg"  # Signed URL (1 hour expiry)
        - back: "https://cdn.example.com/kyc/doc-1-back.jpg"
      verification_result:
        status: VERIFIED
        verified_by_vendor: ONFIDO
        verified_at: 2026-03-28T11:00:00Z
        issues: []
    - document_id: doc-2
      type: PROOF_OF_ADDRESS
      uploaded_at: 2026-03-28T10:00:00Z
      status: NEEDS_REVIEW
      image_urls:
        - https://cdn.example.com/kyc/doc-2.jpg
      verification_result: null
  previous_decisions:
    - decision_id: dec-1
      status: REJECTED
      decided_at: 2026-02-15T14:00:00Z
      rejected_by: adm-456
      rejection_reason: "Insufficient proof of address"
      reviewer_notes: "Utility bill too old (2 years)"
      appeal_status: APPEALED
  linked_accounts:
    - related_account_id: acc-124
      relationship: SAME_EMAIL
      status: ACTIVE
    - related_account_id: acc-125
      relationship: SAME_ADDRESS
      status: KYC_APPROVED
  aml_status:
    latest_screening_at: 2026-03-28T09:00:00Z
    status: CLEAR
    issues: []
  account_activity:
    first_login_at: 2026-01-15T12:00:00Z
    last_login_at: 2026-03-28T15:00:00Z
    total_logins: 47
    last_trading_activity: 2026-03-27T10:00:00Z
    total_trades: 15
    total_deposits: 3
    total_deposits_amount: 50000
    account_restrictions: []
```

#### 2.3 Approve KYC Application

**Endpoint**: `POST /admin/kyc/applications/{application_id}/approve` (gRPC: `AdminService.ApproveKycApplication`)

Approve a KYC application and activate account for trading.

##### Request

```yaml
path_parameters:
  application_id: kyc-001

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: KYC_REVIEWER

body:
  reviewer_notes: "All documents verified. Account ready for trading."
  approved_kyc_level: STANDARD  # STANDARD, ENHANCED (for large traders)
```

##### Response

```yaml
201 Created:
  application_id: kyc-001
  account_id: acc-123
  status: APPROVED
  approved_at: 2026-04-01T14:35:00Z
  approved_by: adm-789
  kyc_level: STANDARD
  next_annual_review_due: 2027-04-01
  account_status_updated: ACTIVE
```

#### 2.4 Reject KYC Application

**Endpoint**: `POST /admin/kyc/applications/{application_id}/reject` (gRPC: `AdminService.RejectKycApplication`)

Reject a KYC application with reason and allow resubmission.

##### Request

```yaml
path_parameters:
  application_id: kyc-001

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: KYC_REVIEWER

body:
  rejection_reason: INSUFFICIENT_PROOF_OF_ADDRESS
  reviewer_notes: "Utility bill must be dated within 3 months. Please resubmit with current utility bill."
  allow_resubmission: true
  days_before_resubmission: 7
```

##### Response

```yaml
201 Created:
  application_id: kyc-001
  account_id: acc-123
  status: REJECTED
  rejected_at: 2026-04-01T14:35:00Z
  rejected_by: adm-789
  rejection_reason: INSUFFICIENT_PROOF_OF_ADDRESS
  allow_resubmission: true
  resubmission_available_at: 2026-04-08T14:35:00Z
  account_status: PENDING_KYC  # No change; account remains pending
```

---

### 3. AML Management

#### 3.1 List AML Screening Results

**Endpoint**: `GET /admin/aml/screenings` (gRPC: `AdminService.ListAmlScreenings`)

Retrieve AML screening results with filtering by status and risk level.

##### Request

```yaml
query_parameters:
  page: 1
  page_size: 50
  status: [CLEAR, REVIEW, FLAGGED, ESCALATED]
  risk_score_min: 0.7
  sort_by: RISK_SCORE  # RISK_SCORE, SCREENED_AT, UPDATED_AT
  date_from: 2026-03-01
  date_to: 2026-04-01
  search_query: "alice@example.com"

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: AML_ANALYST
```

##### Response

```yaml
200 OK:
  screenings:
    - screening_id: aml-001
      account_id: acc-123
      user_name: Alice Smith
      email: alice@example.com
      status: REVIEW  # CLEAR, REVIEW, FLAGGED, ESCALATED
      risk_score: 0.72
      screened_at: 2026-03-28T10:00:00Z
      screening_type: INITIAL  # INITIAL, RECURRING, TRANSACTION_MONITORING
      issues:
        - type: OFAC_POTENTIAL_MATCH
          name_matched: Alice M. Smith
          confidence: 0.85
          action_taken: MANUAL_REVIEW
          notes: "Name similarity; likely false positive"
        - type: VELOCITY_ANOMALY
          description: "$50k deposit followed by rapid withdrawal in 24 hours"
          action_taken: PENDING_REVIEW
      analyst_notes: null
      status_last_updated_at: 2026-03-28T10:00:00Z
  pagination:
    total_count: 87
    flagged_count: 12
    requires_escalation: 3
```

#### 3.2 Get AML Screening Details

**Endpoint**: `GET /admin/aml/screenings/{screening_id}` (gRPC: `AdminService.GetAmlScreening`)

Retrieve full AML screening details with remediation workflow.

##### Request

```yaml
path_parameters:
  screening_id: aml-001

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: AML_ANALYST
```

##### Response

```yaml
200 OK:
  screening_id: aml-001
  account_id: acc-123
  status: REVIEW
  risk_score: 0.72
  screened_at: 2026-03-28T10:00:00Z
  screening_issues:
    - issue_id: iss-1
      type: OFAC_POTENTIAL_MATCH
      description: "Name matches OFAC SDN list entry: Alice M. Smith"
      confidence: 0.85
      action_required: MANUAL_REVIEW
      evidence:
        matched_record: "Alice Michelle Smith, DOB: 1945-05-15"
        jurisdiction: OFAC
        list_type: SDN
      analyst_resolution: null
      resolved_at: null
      resolution_notes: null
    - issue_id: iss-2
      type: VELOCITY_ANOMALY
      description: "Deposit of $50k followed by withdrawal of $49.5k within 24 hours (potential structuring)"
      confidence: 0.68
      action_required: PENDING_REVIEW
      evidence:
        transactions:
          - txn_id: txn-123
            type: DEPOSIT
            amount: 50000
            timestamp: 2026-03-27T10:00:00Z
          - txn_id: txn-124
            type: WITHDRAWAL
            amount: 49500
            timestamp: 2026-03-28T08:00:00Z
      analyst_resolution: null
  remediation_options:
    - action: CLEAR
      description: "Mark as reviewed; false positive (no action needed)"
      requires_approval: true
    - action: ESCALATE_TO_COMPLIANCE
      description: "Escalate to Compliance Officer for formal SAR (Suspicious Activity Report)"
      requires_approval: true
    - action: RESTRICT_ACCOUNT
      description: "Restrict account pending further investigation"
      restrict_types: [DEPOSIT, WITHDRAWAL, TRADING]
      duration_days: 30
  previous_screenings:
    - screening_id: aml-001
      screened_at: 2026-02-15T10:00:00Z
      status: CLEAR
```

#### 3.3 Resolve AML Issue

**Endpoint**: `POST /admin/aml/screenings/{screening_id}/resolve-issue` (gRPC: `AdminService.ResolveAmlIssue`)

Resolve an individual AML issue (clear or escalate).

##### Request

```yaml
path_parameters:
  screening_id: aml-001

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: AML_ANALYST

body:
  issue_id: iss-1
  resolution: CLEAR  # CLEAR, ESCALATE_TO_COMPLIANCE, ESCALATE_TO_OFAC, RESTRICT_ACCOUNT
  analyst_notes: "Confirmed: Alice Michelle Smith (DOB 1995-05-15) is not a match to OFAC entry (DOB 1945). Likely same-name false positive."
  restrict_options:
    restrict_types: [WITHDRAWAL]  # Only if resolution = RESTRICT_ACCOUNT
    duration_days: 7
```

##### Response

```yaml
200 OK:
  issue_id: iss-1
  resolution: CLEAR
  resolved_at: 2026-04-01T14:35:00Z
  resolved_by: adm-456
  analyst_notes: "Confirmed false positive..."
  screening_status_updated_to: CLEAR  # If all issues resolved
```

---

### 4. Account Management

#### 4.1 Search Accounts

**Endpoint**: `GET /admin/accounts/search` (gRPC: `AdminService.SearchAccounts`)

Full-text search on accounts with advanced filtering.

##### Request

```yaml
query_parameters:
  q: "alice smith OR alice@example.com OR +1206555-0100 OR acc-123"  # Name, email, phone, account_id
  status: [ACTIVE, PENDING_KYC, SUSPENDED, CLOSED]
  kyc_status: [PENDING, APPROVED, REJECTED]
  aml_status: [CLEAR, REVIEW, FLAGGED]
  restriction_type: TRADING_DISABLED  # Any restriction type
  account_age_days_min: 0
  account_age_days_max: 365
  deposit_amount_min: 1000
  deposit_amount_max: 100000
  jurisdiction: [US, HK]
  sort_by: ACCOUNT_AGE  # ACCOUNT_AGE, LAST_LOGIN, TRADING_VOLUME, DEPOSIT_AMOUNT
  page: 1
  page_size: 50

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: SUPPORT_AGENT
```

##### Response

```yaml
200 OK:
  accounts:
    - account_id: acc-123
      user_name: Alice Smith
      email: alice@example.com
      phone_masked: +1206***0100
      status: ACTIVE
      kyc_status: APPROVED
      aml_status: CLEAR
      account_created_at: 2026-01-15T12:00:00Z
      last_login_at: 2026-03-28T15:00:00Z
      total_deposits: 50000
      total_withdrawals: 10000
      active_restrictions: []
      is_high_risk: false
  pagination:
    total_count: 1
```

#### 4.2 Get Account Details

**Endpoint**: `GET /admin/accounts/{account_id}` (gRPC: `AdminService.GetAccount`)

Retrieve comprehensive account details for support/compliance review.

##### Request

```yaml
path_parameters:
  account_id: acc-123

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: ACCOUNT_MANAGER
```

##### Response

```yaml
200 OK:
  account_id: acc-123
  personal_info:
    first_name: Alice
    last_name: Smith
    email: alice@example.com
    phone_masked: +1206***0100
    nationality: US
    ssn_masked: ***-**-6789
  account_status:
    status: ACTIVE
    created_at: 2026-01-15T12:00:00Z
    kyc_status: APPROVED
    kyc_approved_at: 2026-02-01T14:00:00Z
    kyc_next_review_due: 2027-02-01
    aml_status: CLEAR
    w8ben_status: VERIFIED
    w8ben_expires_at: 2029-02-01
  restrictions:
    - restriction_id: res-1
      type: TRADING_DISABLED
      reason: COMPLIANCE_HOLD
      effective_from: 2026-03-27T10:00:00Z
      effective_until: 2026-04-10T10:00:00Z
      notes: "Pending AML review completion"
      imposed_by: adm-456
  login_history:
    last_login_at: 2026-03-28T15:00:00Z
    last_login_ip: "203.0.113.42"
    last_login_country: US
    login_count_last_30_days: 12
    unique_devices: 2
  trading_activity:
    last_trade_at: 2026-03-27T10:00:00Z
    trades_last_30_days: 8
    avg_order_value: 5000
    portfolio_value_approx: 45000
  deposits_withdrawals:
    deposits_total: 50000
    deposits_count: 3
    latest_deposit: 2026-03-15T12:00:00Z
    withdrawals_total: 10000
    withdrawals_count: 1
    pending_withdrawals: 2000
  linked_accounts:
    - account_id: acc-124
      relationship: SAME_EMAIL
      status: KYC_APPROVED
  notifications_sent:
    - type: KYC_APPROVED
      sent_at: 2026-02-01T14:00:00Z
    - type: TRADING_DISABLED
      sent_at: 2026-03-27T10:00:00Z
```

#### 4.3 Update Account Restrictions

**Endpoint**: `POST /admin/accounts/{account_id}/restrictions` (gRPC: `AdminService.UpdateAccountRestriction`)

Add, modify, or remove account restrictions (trading, withdrawal, deposit disabled).

##### Request

```yaml
path_parameters:
  account_id: acc-123

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: COMPLIANCE_OFFICER

body:
  restriction_type: TRADING_DISABLED  # TRADING_DISABLED, WITHDRAWAL_DISABLED, DEPOSIT_DISABLED, ALL_DISABLED
  action: ADD  # ADD, REMOVE, EXTEND
  reason: COMPLIANCE_HOLD  # AML_FLAG, KYC_INCOMPLETE, COMPLIANCE_HOLD, ACCOUNT_SUSPENDED
  duration_days: 30  # null for indefinite
  notes: "Pending completion of enhanced AML review. Customer has been notified."
  notify_customer: true  # Send notification to user
```

##### Response

```yaml
201 Created:
  account_id: acc-123
  restriction_id: res-2
  type: TRADING_DISABLED
  reason: COMPLIANCE_HOLD
  effective_from: 2026-04-01T14:35:00Z
  effective_until: 2026-05-01T14:35:00Z
  imposed_by: adm-789
  notes: "..."
  customer_notification_sent: true
```

#### 4.4 Unlock Account (Bulk)

**Endpoint**: `POST /admin/accounts/bulk-unlock` (gRPC: `AdminService.BulkUnlockAccounts`)

Bulk unlock multiple accounts (remove all restrictions).

##### Request

```yaml
headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: COMPLIANCE_OFFICER

body:
  account_ids: ["acc-123", "acc-124", "acc-125"]
  reason: COMPLIANCE_HOLD_RESOLVED
  notes: "AML review completed for all 3 accounts. Restrictions removed."
  notify_customers: true
```

##### Response

```yaml
200 OK:
  unlocked_count: 3
  failed_count: 0
  results:
    - account_id: acc-123
      success: true
      restrictions_removed: ["TRADING_DISABLED"]
    - account_id: acc-124
      success: true
      restrictions_removed: ["WITHDRAWAL_DISABLED", "DEPOSIT_DISABLED"]
    - account_id: acc-125
      success: true
      restrictions_removed: []  # No active restrictions
```

---

### 5. Device Management

#### 5.1 List User Devices

**Endpoint**: `GET /admin/accounts/{account_id}/devices` (gRPC: `AdminService.ListDevices`)

Retrieve all registered devices for an account.

##### Request

```yaml
path_parameters:
  account_id: acc-123

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: ACCOUNT_MANAGER
```

##### Response

```yaml
200 OK:
  account_id: acc-123
  devices:
    - device_id: dev-1
      device_name: "Alice's iPhone 15 Pro"
      os_type: iOS
      status: ACTIVE
      login_time: 2026-03-15T10:00:00Z
      last_activity_time: 2026-03-28T15:00:00Z
      location_country: US
      location_city: Seattle
      ip_address_masked: "203.0.***.*"
      biometric_registered: true
      biometric_type: FACE_ID
    - device_id: dev-2
      device_name: "Alice's MacBook Pro"
      os_type: WEB
      status: LOCALLY_LOGGED_OUT
      login_time: 2026-02-01T10:00:00Z
      last_activity_time: 2026-02-15T08:00:00Z
      location_country: US
      location_city: Seattle
```

#### 5.2 Kick Device (Remote Revocation)

**Endpoint**: `POST /admin/accounts/{account_id}/devices/{device_id}/kick` (gRPC: `AdminService.KickDevice`)

Remotely revoke a device (force logout).

##### Request

```yaml
path_parameters:
  account_id: acc-123
  device_id: dev-2

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: ACCOUNT_MANAGER

body:
  reason: COMPROMISE_SUSPECTED  # COMPROMISE_SUSPECTED, LOST_DEVICE, ACCOUNT_SECURITY_HOLD, COMPLIANCE_REVIEW
  notes: "User reported unusual activity. Kicking all devices pending investigation."
  notify_customer: true
```

##### Response

```yaml
201 Created:
  account_id: acc-123
  device_id: dev-2
  status: REMOTELY_KICKED
  kicked_at: 2026-04-01T14:35:00Z
  kicked_by: adm-789
  reason: COMPROMISE_SUSPECTED
  customer_notification_sent: true
  notification_id: notif-123
```

---

### 6. Notification Template Management

#### 6.1 List Notification Templates

**Endpoint**: `GET /admin/notifications/templates` (gRPC: `AdminService.ListNotificationTemplates`)

Retrieve all notification message templates (for push, SMS, email).

##### Request

```yaml
query_parameters:
  event_type: DEVICE_KICKED  # Filter by event type
  channel: [FCM, SMS, EMAIL]  # Filter by delivery channel
  status: [ACTIVE, DRAFT, ARCHIVED]

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: COMPLIANCE_OFFICER
```

##### Response

```yaml
200 OK:
  templates:
    - template_id: tmpl-1
      event_type: DEVICE_KICKED
      channel: FCM
      subject: "Device was removed"
      body: "Your {{device_name}} was remotely logged out due to security review. If this wasn't you, contact support."
      variables: [device_name, kicked_at, support_url]
      status: ACTIVE
      created_at: 2026-01-01T10:00:00Z
      last_updated_at: 2026-03-01T10:00:00Z
      updated_by: adm-456
```

#### 6.2 Update Notification Template

**Endpoint**: `PUT /admin/notifications/templates/{template_id}` (gRPC: `AdminService.UpdateNotificationTemplate`)

Edit notification template text and variables.

##### Request

```yaml
path_parameters:
  template_id: tmpl-1

headers:
  Authorization: Bearer <admin_token>
  X-Required-Role: COMPLIANCE_OFFICER

body:
  subject: "Device logged out"
  body: "Your {{device_name}} has been logged out as part of a security review. Contact {{support_url}} if you have questions."
  status: ACTIVE
  audit_notes: "Updated subject line for clarity"
```

##### Response

```yaml
200 OK:
  template_id: tmpl-1
  event_type: DEVICE_KICKED
  channel: FCM
  updated_at: 2026-04-01T14:35:00Z
  updated_by: adm-789
  audit_notes: "..."
```

---

## Audit & Compliance

### Audit Trail

Every action (KYC approval, account restriction, device kick) is logged immutably:

```json
{
  "audit_id": "aud-123",
  "event_type": "KYC_APPROVED",
  "actor_id": "adm-789",
  "actor_role": "KYC_REVIEWER",
  "resource_type": "KYC_APPLICATION",
  "resource_id": "kyc-001",
  "timestamp": "2026-04-01T14:35:00Z",
  "changes": {
    "status": "SUBMITTED → APPROVED",
    "kyc_level": null,
    "reviewer_notes": "..."
  },
  "ip_address": "203.0.113.5",
  "user_agent": "Mozilla/5.0..."
}
```

**Retention**: 7 years (SEC Rule 17a-4).

### Rate Limiting

| Endpoint | Limit | Window | Scope |
|----------|-------|--------|-------|
| GET /admin/kyc/applications | 50 | 1min | per admin_id |
| POST /admin/kyc/applications/{id}/approve | 10 | 1min | per admin_id |
| POST /admin/accounts/bulk-unlock | 5 | 1min | per admin_id |

### Role-Based Permissions

| Role | Permissions |
|------|-------------|
| KYC_REVIEWER | Approve/reject KYC, view applications |
| AML_ANALYST | Review AML screenings, resolve issues, escalate |
| COMPLIANCE_OFFICER | All above + impose restrictions, unlock accounts, escalate SAR |
| ACCOUNT_MANAGER | View accounts, manage devices, basic restrictions |
| SUPPORT_AGENT | Search accounts, view basic info, create tickets |

---

## Data Masking Rules

For Admin Panel display, PII is masked:

| Field | Display |
|-------|---------|
| SSN | ***-**-6789 |
| HKID | A****(7) |
| Email | j***e@example.com |
| Phone | +1206***0100 |
| IP Address | 203.0.***.* |

---

## Integration with Event Streams

AMS publishes Kafka events consumed by Admin Panel for live dashboard updates:

| Kafka Topic | Event | Admin Panel Action |
|-------------|----|--|
| kyc.application_approved | Application approved | Update KYC review queue, refresh dashboard |
| aml.screening_completed | AML screening done | Update AML queue, flag urgent issues |
| account.restriction_added | Restriction imposed | Update account status, notify team |
| auth.device_kicked | Device revoked | Update device list, log action |

---

## Related Specifications

- **KYC Flow**: See `kyc-flow.md` for application states and vendor integration.
- **AML Compliance**: See `aml-compliance.md` for screening workflow and escalation rules.
- **Auth Architecture**: See `auth-architecture.md` § 4 for device management details.
- **Notifications**: See `push-notification.md` for notification delivery and template variables.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-01 | Initial contract for admin panel backend integration |

