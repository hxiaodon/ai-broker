# Security & Compliance Rules

These rules apply to all code in the brokerage trading application. They enforce security best practices and regulatory compliance requirements.

## Authentication & Authorization

### Every endpoint must be protected
- All API endpoints require JWT authentication unless explicitly listed as public
- Public endpoints (limited to): health check, market status, public quote snapshots
- Admin panel endpoints require additional RBAC role verification
- Trading endpoints require both authentication AND active account status check

### Token Management
- Access tokens: 15-minute expiry, JWT with RS256 signing
- Refresh tokens: 7-day expiry, stored in HttpOnly secure cookie
- Token revocation: maintain a blacklist in Redis for revoked tokens
- Session binding: tokens are bound to device ID and IP range

### Biometric Authentication
- Required for: order submission, fund withdrawal, password change, KYC document upload
- iOS: LAContext with `.biometryCurrentSet` policy (invalidate on biometric change)
- Android: BiometricPrompt with `BIOMETRIC_STRONG` authenticator type

## Data Protection

### PII Field Encryption
These fields MUST be encrypted at application level (AES-256-GCM) before database storage:
- SSN / Tax ID
- Hong Kong ID (HKID)
- Passport number
- Bank account numbers
- Date of birth (when stored with other identifying fields)

### PII Masking in UI
- SSN: Show only last 4 digits (`***-**-1234`)
- Bank account: Show only last 4 digits (`****1234`)
- HKID: Show first letter and last digit (`A****(3)`)
- Email: Mask middle of local part (`j***e@example.com`)

### Logging Rules
- NEVER log: passwords, tokens, SSN, HKID, full bank account numbers, encryption keys
- ALWAYS mask PII in logs: use masking utility before logging any user data
- Structured logging (JSON format) with consistent field names
- Include correlation ID in all log entries for request tracing
- Log retention: 90 days in hot storage, 7 years in cold storage (compliance)

## API Security

### Request Signing (Trading Endpoints)
- All trading API requests must include HMAC-SHA256 signature
- Signature covers: HTTP method + path + timestamp + body hash
- Reject requests with timestamp older than 30 seconds (replay protection)
- Nonce-based deduplication for critical operations (order submission)

### Rate Limiting
| Endpoint Category | Rate Limit | Window |
|-------------------|-----------|--------|
| Quote/Market Data | 100 req/s | Per IP |
| Order Submission | 10 req/s | Per user |
| Account Operations | 30 req/s | Per user |
| KYC Upload | 5 req/min | Per user |
| Admin Panel | 60 req/s | Per user |
| Login Attempts | 5 req/5min | Per IP+user |

### CORS
- Allow only specific origins (app domain, admin domain)
- Never use `Access-Control-Allow-Origin: *` in production
- Credentials mode must be `include` for authenticated endpoints

## Mobile Security

### Certificate Pinning
- Pin the leaf certificate or public key for all API endpoints
- Include backup pins for certificate rotation
- Implement pin validation failure reporting (not blocking in first week after rotation)

### Local Storage
- iOS: Keychain Services for credentials, encrypted Core Data for cached data
- Android: Android Keystore for keys, EncryptedSharedPreferences for credentials
- Never store in: UserDefaults (iOS), SharedPreferences (Android), plain files
- Clear cached trading data on logout

### Anti-Tampering
- Jailbreak/root detection: warn user, restrict trading functionality
- Code obfuscation: ProGuard/R8 (Android), bitcode + symbol stripping (iOS)
- SSL proxy detection: detect and block MitM debugging tools in production builds
- Prevent screen capture on sensitive screens (account details, KYC, trading)

## Database Security

### Access Control
- Application uses a dedicated database user with minimum required privileges
- No application code runs as database superuser
- Read replicas use read-only database credentials
- Administrative operations require separate privileged credentials via Vault

### Query Safety
- All queries use parameterized statements (prepared statements / query builders)
- Never concatenate user input into SQL strings
- Use allow-list for dynamic column/table names in sorting/filtering
- Apply `LIMIT` to all user-facing queries (max 1000 rows)

### Data Retention
- Orders: retain indefinitely (SEC Rule 17a-4)
- Audit logs: retain minimum 7 years (WORM storage)
- KYC documents: retain for 6 years after account closure
- Market data: retain tick data for 5 years, aggregated data indefinitely
- Personal data: honor deletion requests while maintaining regulatory minimums
