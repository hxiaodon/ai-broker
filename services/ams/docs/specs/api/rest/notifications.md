# REST API — Notifications Endpoints

**Service**: AMS (Account Management Service)  
**Version**: v1.0  
**Last Updated**: 2026-04-01  
**Status**: FINAL  

---

## Overview

The AMS Notifications API provides endpoints for retrieving notification history, marking notifications as read, and managing notification delivery preferences. Notifications are event-driven (Kafka → Notification Service → FCM/SMS/Email) and queryable via REST for UI display.

### Key Design Principles

1. **Event-Driven Delivery**: Notifications are asynchronously delivered via Kafka (see `push-notification.md` for event mapping).
2. **Preference-Based Filtering**: Users can opt-in/out per channel (FCM, SMS, Email) and per event type.
3. **Read/Unread State**: In-app notifications tracked separately from delivery channels.
4. **Audit Trail**: All notification delivery and user actions (read, dismiss) logged immutably.

---

## Endpoints Summary

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/v1/notifications` | Access Token | List notifications (paginated) |
| PATCH | `/v1/notifications/{notification_id}/read` | Access Token | Mark single notification as read |
| PATCH | `/v1/notifications/read` | Access Token | Mark multiple as read (bulk) |
| GET | `/v1/notifications/preferences` | Access Token | Retrieve user notification preferences |
| PUT | `/v1/notifications/preferences` | Access Token | Update notification preferences |

---

## 1. List Notifications

**Endpoint**: `GET /v1/notifications`

**Purpose**: Retrieve paginated list of user's notifications with filtering options.

### Request

```yaml
query_parameters:
  page:
    type: integer
    default: 1
    minimum: 1
    description: "Page number (1-indexed)"
  page_size:
    type: integer
    default: 20
    minimum: 1
    maximum: 100
    description: "Notifications per page"
  status:
    type: string
    enum: [UNREAD, READ, ALL]
    default: ALL
    description: "Filter by read status"
  event_type:
    type: string
    enum:
      - DEVICE_ADDED
      - DEVICE_KICKED
      - UNAUTHORIZED_LOGIN
      - ACCOUNT_LOCKED
      - KYC_STATUS_CHANGE
      - W8BEN_EXPIRING_SOON
      - SESSION_EXPIRED
      - WITHDRAWAL_COMPLETED
      - DEPOSIT_COMPLETED
    nullable: true
    description: "Filter by event type"
  date_from:
    type: string
    format: date
    nullable: true
    description: "ISO 8601 date; only notifications from this date onwards"
  date_to:
    type: string
    format: date
    nullable: true
    description: "ISO 8601 date; only notifications up to this date"
  sort:
    type: string
    enum: [NEWEST, OLDEST]
    default: NEWEST
    description: "Sort order by created_at"

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
  notifications:
    type: array
    items:
      type: object
      properties:
        notification_id:
          type: string
          format: uuid
        event_type:
          type: string
          enum: [DEVICE_ADDED, DEVICE_KICKED, UNAUTHORIZED_LOGIN, ...]
        title:
          type: string
          example: "New device login from iPhone 15 Pro"
        message:
          type: string
          example: "Your account was logged in from a new device in Seattle, US on April 1, 2026 at 09:30 AM PT."
        details:
          type: object
          description: "Event-specific details; structure varies by event_type"
          properties:
            device_name:
              type: string
              nullable: true
            device_id:
              type: string
              nullable: true
            location:
              type: string
              nullable: true
            timestamp:
              type: string
              format: date-time
              nullable: true
        priority:
          type: string
          enum: [HIGH, NORMAL, LOW]
          description: "Notification priority (for UI sorting/highlighting)"
        is_read:
          type: boolean
        created_at:
          type: string
          format: date-time
        read_at:
          type: string
          format: date-time
          nullable: true
        action_required:
          type: boolean
          description: "True if user action is needed (e.g., approve device)"
        action_url:
          type: string
          format: uri
          nullable: true
          description: "Deep link to relevant screen (e.g., device management)"
          example: "/settings/devices"
  pagination:
    type: object
    properties:
      page:
        type: integer
      page_size:
        type: integer
      total_count:
        type: integer
      total_pages:
        type: integer
      has_next_page:
        type: boolean
  unread_count:
    type: integer
    description: "Total unread notifications"
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

- **Query**: SELECT from `push_notifications` WHERE account_id = extracted_from_token WITH pagination and filters.
- **Unread Count**: Fast query via Redis counter key: `notifications:unread:{account_id}` (incremented on creation, decremented on mark-read).
- **Details Field**: Structure varies by event_type:
  ```
  DEVICE_ADDED/KICKED:
    { device_name, device_id, location, timestamp }
  
  UNAUTHORIZED_LOGIN:
    { location, ip_address, timestamp, device_name }
  
  KYC_STATUS_CHANGE:
    { status, reason, next_steps }
  
  WITHDRAWAL_COMPLETED:
    { amount, currency, bank_account_last_4, timestamp }
  ```
- **Action URL**: Construct based on event_type:
  - DEVICE_KICKED → `/settings/devices`
  - KYC_STATUS_CHANGE → `/kyc/status`
  - WITHDRAWAL_COMPLETED → `/portfolio/history`
- **Sorting**: Default NEWEST (created_at DESC).

---

## 2. Mark Notification as Read (Single)

**Endpoint**: `PATCH /v1/notifications/{notification_id}/read`

**Purpose**: Mark a single notification as read.

### Request

```yaml
path_parameters:
  notification_id:
    type: string
    format: uuid
    required: true

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
  notification_id:
    type: string
    format: uuid
  is_read:
    type: boolean
    example: true
  read_at:
    type: string
    format: date-time
```

### Response — 404 Not Found

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [NOTIFICATION_NOT_FOUND]
```

### Response — 401 Unauthorized

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [INVALID_ACCESS_TOKEN, NOTIFICATION_NOT_OWNED_BY_USER]
  message:
    type: string
    example: "Notification does not belong to your account"
```

### Implementation Notes

- **Authorization Check**: Verify notification.account_id matches token.account_id.
- **Database Update**: SET `is_read = true`, `read_at = now()` WHERE notification_id = ? AND account_id = ?.
- **Redis Counter**: Decrement `notifications:unread:{account_id}` if is_read was false.
- **Audit Log**: Log read action with notification_id, account_id, timestamp.

---

## 3. Mark Multiple Notifications as Read (Bulk)

**Endpoint**: `PATCH /v1/notifications/read`

**Purpose**: Bulk mark multiple notifications as read.

### Request

```yaml
headers:
  Authorization:
    type: string
    description: "Bearer <access_token>"
    required: true
  Content-Type: application/json

body:
  type: object
  required:
    - notification_ids
  properties:
    notification_ids:
      type: array
      items:
        type: string
        format: uuid
      minItems: 1
      maxItems: 100
      description: "List of notification IDs to mark as read"
```

### Response — 200 OK

```yaml
type: object
properties:
  marked_as_read:
    type: integer
    description: "Number of notifications successfully marked as read"
  errors:
    type: array
    items:
      type: object
      properties:
        notification_id:
          type: string
          format: uuid
        error_code:
          type: string
          enum: [NOT_FOUND, NOT_OWNED_BY_USER]
    description: "Any errors encountered during bulk update"
```

### Response — 400 Bad Request

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [INVALID_REQUEST, TOO_MANY_IDS]
  message:
    type: string
    example: "Maximum 100 notification IDs allowed"
```

### Implementation Notes

- **Validation**: Limit to 100 IDs per request.
- **Database Update**: Use CASE statement for efficient update:
  ```sql
  UPDATE push_notifications 
  SET is_read = true, read_at = now() 
  WHERE notification_id IN (?, ?, ...) 
  AND account_id = ? 
  AND is_read = false;
  ```
- **Redis Update**: Decrement `notifications:unread:{account_id}` by count of updated rows.
- **Partial Success**: If some notifications not found or not owned, return 200 with error details.

---

## 4. Get Notification Preferences

**Endpoint**: `GET /v1/notifications/preferences`

**Purpose**: Retrieve user's notification delivery preferences per channel and event type.

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
  channels:
    type: object
    description: "Opt-in/out per delivery channel"
    properties:
      fcm:
        type: object
        properties:
          enabled:
            type: boolean
            description: "Push notifications via Firebase Cloud Messaging"
          updated_at:
            type: string
            format: date-time
      sms:
        type: object
        properties:
          enabled:
            type: boolean
            description: "SMS text notifications"
          updated_at:
            type: string
            format: date-time
      email:
        type: object
        properties:
          enabled:
            type: boolean
          updated_at:
            type: string
            format: date-time
  event_types:
    type: object
    description: "Opt-in/out per event type (defaults to true if not set)"
    properties:
      device_added:
        type: boolean
      device_kicked:
        type: boolean
      unauthorized_login:
        type: boolean
        description: "Cannot be disabled; required for security"
      account_locked:
        type: boolean
        description: "Cannot be disabled; required for security"
      kyc_status_change:
        type: boolean
      w8ben_expiring_soon:
        type: boolean
      session_expired:
        type: boolean
      withdrawal_completed:
        type: boolean
      deposit_completed:
        type: boolean
  do_not_disturb:
    type: object
    description: "Quiet hours; notifications still delivered but not shown as FCM pop-up"
    properties:
      enabled:
        type: boolean
      quiet_start_time:
        type: string
        format: "HH:mm"
        example: "22:00"
      quiet_end_time:
        type: string
        format: "HH:mm"
        example: "08:00"
      timezone:
        type: string
        example: "America/Los_Angeles"
  marketing_emails:
    type: boolean
    description: "Separate opt-in for marketing/promotional emails"
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

- **Query**: SELECT from `notification_preferences` table WHERE account_id = ?.
- **Defaults**: If row doesn't exist, return defaults: all channels enabled, all event types enabled, DND disabled.
- **Insert-on-First-Update**: If user hasn't customized preferences, first update creates the row.

---

## 5. Update Notification Preferences

**Endpoint**: `PUT /v1/notifications/preferences`

**Purpose**: Update user's notification delivery preferences.

### Request

```yaml
headers:
  Authorization:
    type: string
    description: "Bearer <access_token>"
    required: true
  Content-Type: application/json

body:
  type: object
  properties:
    channels:
      type: object
      properties:
        fcm:
          type: boolean
        sms:
          type: boolean
        email:
          type: boolean
    event_types:
      type: object
      properties:
        device_added:
          type: boolean
        device_kicked:
          type: boolean
        unauthorized_login:
          type: boolean
          description: "Cannot be disabled"
        account_locked:
          type: boolean
          description: "Cannot be disabled"
        kyc_status_change:
          type: boolean
        w8ben_expiring_soon:
          type: boolean
        session_expired:
          type: boolean
        withdrawal_completed:
          type: boolean
        deposit_completed:
          type: boolean
    do_not_disturb:
      type: object
      properties:
        enabled:
          type: boolean
        quiet_start_time:
          type: string
          format: "HH:mm"
          example: "22:00"
        quiet_end_time:
          type: string
          format: "HH:mm"
          example: "08:00"
        timezone:
          type: string
          example: "America/Los_Angeles"
    marketing_emails:
      type: boolean
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
    example: ["channels.fcm", "event_types.device_added", "do_not_disturb.enabled"]
  channels:
    type: object
    properties:
      fcm:
        type: boolean
      sms:
        type: boolean
      email:
        type: boolean
  event_types:
    type: object
```

### Response — 400 Bad Request

```yaml
type: object
properties:
  error_code:
    type: string
    enum: [INVALID_REQUEST, CANNOT_DISABLE_REQUIRED_EVENTS]
  message:
    type: string
    example: "Cannot disable 'unauthorized_login' and 'account_locked' notifications; they are required for security"
  details:
    type: object
    example:
      restricted_fields: ["event_types.unauthorized_login", "event_types.account_locked"]
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

- **Validation**: Ensure `unauthorized_login` and `account_locked` remain enabled (enforce at API level).
- **DND Validation**: Verify `quiet_start_time` < `quiet_end_time` or allow wrapping (e.g., 22:00 to 08:00 next day).
- **Database Operation**: UPSERT into `notification_preferences`:
  ```sql
  INSERT INTO notification_preferences (...) 
  VALUES (...) 
  ON DUPLICATE KEY UPDATE 
  channel_fcm = ?, channel_sms = ?, ... 
  WHERE account_id = ?
  ```
- **Audit Log**: Log preference changes with delta (old vs. new values).
- **Kafka Event**: Publish `notification.preferences_updated` with account_id, changed_fields.

---

## Security & Compliance

### PII in Notifications

- Never expose full SSN, HKID, or bank account numbers in notification message or details.
- Device location (city, country) is safe to expose (for login alerts).
- IP address masked in user-facing messages.

### Rate Limiting

| Endpoint | Limit | Window | Scope |
|----------|-------|--------|-------|
| GET /notifications | 10 | 1min | per account_id |
| PATCH /notifications/{id}/read | 10 | 1min | per account_id |
| PATCH /notifications/read | 5 | 1min | per account_id |
| GET /notifications/preferences | 10 | 1min | per account_id |
| PUT /notifications/preferences | 5 | 1min | per account_id |

### Audit & Logging

- Log all preference updates with before/after delta.
- Log all read actions with account_id, notification_id, timestamp.
- Logs retained for 90 days in hot storage, 7 years in cold storage.

### Related Specifications

- **Push Notifications**: See `push-notification.md` for event types, delivery SLA, and multi-channel failover.
- **Kafka Events**: See `kafka-events.md` for notification event schema and partition key strategy.
- **Auth Architecture**: See `auth-architecture.md` § 9.2 for security event notification types.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v1.0 | 2026-04-01 | Initial OpenAPI 3.0 specification for 5 notification endpoints |

