# AMS 认证授权架构规格

> **版本**: v0.1
> **日期**: 2026-03-17
> **作者**: AMS Engineering
> **状态**: Draft — 待安全评审
>
> 本文档定义 AMS 的认证（Authentication）与授权（Authorization）完整技术方案。涵盖 JWT RS256 实现、设备绑定、Token 生命周期、RBAC 权限模型、gRPC 服务间认证，以及与移动端/Admin Panel 的集成契约。

---

## 目录

1. [架构概述](#1-架构概述)
2. [JWT Token 体系](#2-jwt-token-体系)
3. [Token 生命周期管理](#3-token-生命周期管理)
4. [设备绑定（Device Binding）](#4-设备绑定device-binding)
5. [RBAC 权限模型](#5-rbac-权限模型)
6. [gRPC 服务间认证（mTLS）](#6-grpc-服务间认证mtls)
7. [公钥分发（JWKS）](#7-公钥分发jwks)
8. [认证中间件设计](#8-认证中间件设计)
9. [安全事件处理](#9-安全事件处理)
10. [与各端集成契约](#10-与各端集成契约)
11. [密钥管理与轮换](#11-密钥管理与轮换)

---

## 1. 架构概述

```
┌─────────────────────────────────────────────────────────────────┐
│  移动端 / Admin Panel / H5 WebView                              │
└───────────────┬─────────────────────────────────────────────────┘
                │ HTTPS + Access Token (JWT RS256)
                ▼
┌─────────────────────────────────────────────────────────────────┐
│  API Gateway                                                    │
│  - 验证 JWT 签名（公钥）                                         │
│  - 检查 Redis Token Blacklist                                   │
│  - 提取 account_id, device_id → 下游 header                    │
└───────────────┬─────────────────────────────────────────────────┘
                │ gRPC + mTLS（内部服务凭证）
                ▼
┌──────┐  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐
│ AMS  │  │Trading Engine│  │ Market Data │  │  Fund Transfer   │
│(签发)│  │(验证/只读)   │  │ (验证/只读) │  │  (验证/只读)     │
└──────┘  └──────────────┘  └─────────────┘  └──────────────────┘
```

**核心原则**：
- **AMS 是唯一签发方**：只有 AMS 签发 JWT；其他服务只验证、不签发
- **RS256 非对称签名**：私钥留在 AMS；公钥通过 JWKS 端点分发给下游服务
- **设备绑定**：每个 Token 绑定到颁发时的 device_id，防止 Token 跨设备使用
- **短生命期 + 刷新**：Access Token 15 分钟；Refresh Token 7 天单次使用

---

## 2. JWT Token 体系

### 2.1 Access Token Claims

```json
{
  "iss": "ams.brokerage.internal",
  "sub": "acc-a1b2c3d4",
  "aud": ["trading-engine", "market-data", "fund-transfer"],
  "iat": 1710672000,
  "exp": 1710672900,
  "nbf": 1710672000,
  "jti": "550e8400-e29b-41d4-a716-446655440000",
  "account_id": "acc-a1b2c3d4",
  "device_id": "dev-xyz-789",
  "account_status": "ACTIVE",
  "kyc_tier": "FULL",
  "roles": ["customer"],
  "jurisdiction": "BOTH"
}
```

| Claim | 类型 | 说明 |
|-------|------|------|
| `jti` | UUID v4 | Token 唯一 ID，用于黑名单索引 |
| `device_id` | string | 签发时绑定的设备 ID |
| `account_status` | enum | `ACTIVE` / `RESTRICTED` / `SUSPENDED` |
| `kyc_tier` | enum | `NONE` / `BASIC` / `FULL` — 影响下游权限 |
| `roles` | []string | `customer` / `compliance_officer` / `admin` |
| `jurisdiction` | enum | `US` / `HK` / `BOTH` — 影响可交易市场 |

> **安全规则**：`account_status` 嵌入 Token 仅用于快速路由决策（无需回查 DB），但交易/出金等关键操作必须实时查询 AMS，不信任 Token 中的状态。

### 2.2 Refresh Token

Refresh Token **不是 JWT**，而是一个不透明的 UUID v4，存储于 Redis：

```
Key:   session:{device_id}
Type:  Hash
Fields:
  refresh_token: <UUID v4>
  account_id:    acc-xxx
  issued_at:     <Unix timestamp>
  ip_bound:      192.168.x.x  (CIDR /24 软绑定)
TTL:   7 days
```

**不使用 JWT 作为 Refresh Token 的原因**：
- Refresh Token 需要服务端状态（单次使用、可撤销）；JWT 是无状态的
- 存储在 Redis Hash 中，可精确控制生命周期和撤销

### 2.3 Admin Panel Token（更严格要求）

Admin Panel 使用独立的 Token 策略：

| 参数 | 普通用户 | Admin Panel |
|------|----------|-------------|
| Access Token 有效期 | 15 分钟 | **5 分钟** |
| Refresh Token 有效期 | 7 天 | **8 小时**（工作日内） |
| 多因素认证 | 生物识别 | **TOTP（RFC 6238）** |
| IP 锁定 | 软绑定（/24） | **硬绑定（精确 IP 或 VPN CIDR）** |
| 会话闲置超时 | 无 | **30 分钟**（前端强制） |

---

## 3. Token 生命周期管理

### 3.1 状态图

```
[登录成功]
    │
    ▼
[Active]──────────────────────────────────────┐
    │                                          │
    │ 15分钟后 Access Token 过期               │
    ▼                                          │
[使用 Refresh Token 续期]                      │ 用户主动注销 /
    │                    │                     │ 安全事件
    │ 成功               │ RT 不匹配           │
    ▼                    ▼                     │
[新 Access Token]   [可疑！撤销所有该设备 token] │
    │                                          │
    │ 7天后 Refresh Token 过期                 │
    ▼                                          ▼
[需要重新登录]                           [Revoked]
                                               │
                                               │ JTI 写入 Redis blacklist
                                               │ TTL = 剩余有效期
                                               ▼
                                         [黑名单生效]
```

### 3.2 登录流程

```
Client                    AMS                      Redis
  │                         │                         │
  │──POST /v1/auth/login──►│                         │
  │   {phone, password,     │                         │
  │    device_id, device_fp}│                         │
  │                         │─ HMAC password check   │
  │                         │─ AML risk check ────────┤
  │                         │                         │
  │                         │─ HSET session:{dev_id} ►│
  │                         │   {refresh_token: UUID} │
  │                         │   EXPIRE 7d             │
  │                         │                         │
  │◄── 200 OK ──────────────│                         │
  │   {access_token: JWT,   │                         │
  │    refresh_token: UUID, │                         │
  │    expires_in: 900}     │                         │
```

### 3.3 Refresh Token 轮换

```go
// POST /v1/auth/refresh
// Header: X-Device-ID: {device_id}
// Body: { "refresh_token": "{old_uuid}" }

func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
    deviceID := r.Header.Get("X-Device-ID")
    oldRT := req.RefreshToken

    // 原子操作：验证 + 轮换（Lua 脚本）
    newRT := uuid.NewString()
    ok, err := h.sessionStore.RotateRefreshToken(r.Context(), deviceID, oldRT, newRT)
    if !ok {
        // RT 不匹配 = 可能重放攻击，撤销该设备所有 token
        h.sessionStore.RevokeDevice(r.Context(), deviceID)
        http.Error(w, "invalid refresh token", http.StatusUnauthorized)
        return
    }

    // 签发新 Access Token（旧 AT 自动因过期失效，无需加黑名单）
    newAT, jti, _ := h.tokenSvc.IssueAccessToken(accountID, deviceID)
    // 响应...
}
```

### 3.4 注销流程

```go
// POST /v1/auth/logout
// 注销需将当前 AT 的 JTI 加入黑名单，并删除 RT

func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
    claims := claimsFromContext(r.Context())

    // 1. 将 Access Token JTI 加入黑名单（TTL = 剩余有效期）
    h.tokenStore.BlacklistToken(r.Context(), claims.ID, claims.ExpiresAt.Time)

    // 2. 删除 Refresh Token session
    h.sessionStore.DeleteSession(r.Context(), claims.DeviceID)

    // 3. 发布事件（其他服务可能缓存了 token，通知他们）
    h.eventBus.Publish(r.Context(), "ams.session.revoked", SessionRevokedEvent{
        AccountID: claims.AccountID,
        DeviceID:  claims.DeviceID,
        Reason:    "USER_LOGOUT",
    })

    w.WriteHeader(http.StatusNoContent)
}
```

---

## 4. 设备绑定（Device Binding）

### 4.1 设备指纹收集

移动端在登录时提交设备指纹，AMS 存储并绑定：

```json
{
  "device_id": "dev-xyz-789",
  "device_fingerprint": {
    "platform": "iOS",
    "os_version": "17.3",
    "app_version": "1.2.0",
    "model": "iPhone 15 Pro"
  }
}
```

`device_id` 由客户端生成（`flutter_secure_storage` 持久化，不随 App 卸载重置），首次登录在 AMS 注册。

### 4.2 设备验证中间件

```go
func jwtAuthMiddleware(pubKey *rsa.PublicKey, rdb *redis.Client) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // 1. 提取 Bearer token
            tokenStr := extractBearerToken(r)
            if tokenStr == "" {
                respondUnauthorized(w, "missing token")
                return
            }

            // 2. 验证签名 + 过期
            claims, err := parseAccessToken(pubKey, tokenStr)
            if err != nil {
                respondUnauthorized(w, "invalid token")
                return
            }

            // 3. 检查黑名单（Redis EXISTS）
            if blacklisted, _ := isBlacklisted(r.Context(), rdb, claims.ID); blacklisted {
                respondUnauthorized(w, "token revoked")
                return
            }

            // 4. 设备绑定验证
            deviceID := r.Header.Get("X-Device-ID")
            if deviceID != "" && deviceID != claims.DeviceID {
                // 设备不匹配：可能是 Token 被盗用，拒绝并记录
                auditLog.Warn("device mismatch", zap.String("token_device", claims.DeviceID),
                    zap.String("request_device", deviceID), zap.String("account_id", claims.AccountID))
                respondUnauthorized(w, "device mismatch")
                return
            }

            // 5. 注入 claims 到 context
            ctx := context.WithValue(r.Context(), ctxKeyClaims, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

---

## 5. RBAC 权限模型

### 5.1 角色定义

| 角色 | 说明 | 主要权限 |
|------|------|----------|
| `customer` | 普通注册用户 | 访问自己的账户、下单、出入金 |
| `compliance_officer` | 合规审核员 | 查看 KYC 队列、审批/拒绝 KYC、查看 AML 记录 |
| `compliance_manager` | 合规经理 | 同上 + 大额出金审批 + SAR 提交授权 |
| `operations` | 运营人员 | 查看用户信息（脱敏）、查看订单、不可修改 |
| `admin` | 系统管理员 | 账户状态强制修改、系统配置、不可查看 SAR |
| `auditor` | 审计员 | 只读访问所有审计日志，无法执行任何操作 |

### 5.2 权限矩阵

| 操作 | customer | compliance_officer | compliance_manager | operations | admin | auditor |
|------|----------|-------------------|-------------------|------------|-------|---------|
| 查看自己账户 | ✅ | — | — | ✅（脱敏） | ✅ | ✅（只读） |
| 查看他人账户 | ❌ | ✅（KYC 相关） | ✅ | ✅（脱敏） | ✅ | ✅（只读） |
| KYC 审批 | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| SAR 相关字段 | ❌（Tipping-off） | ❌（只能提交） | ✅（提交+查看） | ❌ | ❌ | ✅ |
| 账户状态强制修改 | ❌ | ❌ | ❌（冻结可以） | ❌ | ✅ | ❌ |
| 大额出金审批 | ❌ | ✅（审核） | ✅（终审） | ❌ | ❌ | ❌ |
| 审计日志查看 | ❌（自己的） | ❌ | ❌ | ❌ | ❌ | ✅ |

### 5.3 RBAC 实现方案

**使用 `casbin/casbin v2` 还是自建？**

对于当前规模，**不引入 Casbin**，改用轻量级自定义 RBAC：

- Casbin 增加了 policy 文件维护负担和 `Enforce()` 每请求调用开销
- AMS 的权限模型相对简单，不需要 ABAC（属性基访问控制）
- 自建 RBAC 在 Go 中实现简单且可测试

```go
type Permission string

const (
    PermViewOwnAccount    Permission = "account:view:own"
    PermViewAnyAccount    Permission = "account:view:any"
    PermReviewKYC         Permission = "kyc:review"
    PermApproveWithdrawal Permission = "withdrawal:approve"
    PermViewSAR           Permission = "sar:view"
    PermForceAccountStatus Permission = "account:status:force"
    PermViewAuditLog      Permission = "auditlog:view"
)

var rolePermissions = map[string][]Permission{
    "customer": {PermViewOwnAccount},
    "compliance_officer": {
        PermViewAnyAccount, PermReviewKYC, PermApproveWithdrawal,
    },
    "compliance_manager": {
        PermViewAnyAccount, PermReviewKYC, PermApproveWithdrawal, PermViewSAR,
    },
    "operations": {PermViewAnyAccount},
    "admin":    {PermViewAnyAccount, PermForceAccountStatus},
    "auditor":  {PermViewAnyAccount, PermViewAuditLog, PermViewSAR},
}

func RequirePermission(perm Permission) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            claims := claimsFromContext(r.Context())
            if !hasPermission(claims.Roles, perm) {
                respondForbidden(w, "insufficient permissions")
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

// 路由示例
r.Route("/v1/compliance", func(r chi.Router) {
    r.Use(RequirePermission(PermReviewKYC))
    r.Get("/kyc-queue", listKYCQueue)
    r.Post("/kyc/{kycID}/approve", approveKYC)
})
```

> **SAR Tipping-off 防护**：所有包含 `sar_filing_count`、`sar_status` 等字段的 API 响应，在序列化层（`json.Marshal`）自动过滤，除非当前 claims 包含 `PermViewSAR`。这在 struct tag 层实现：`json:"sar_filing_count,omitempty" perm:"sar:view"`，由自定义 JSON marshaller 处理。

---

## 6. gRPC 服务间认证（mTLS）

### 6.1 内部认证机制

服务间调用使用 **mTLS（Mutual TLS）**，不传递客户用户的 JWT：

```
Trading Engine ──mTLS──► AMS
  CN=trading-engine.internal         CN=ams.internal
  (trading-engine 的客户端证书)       (AMS 的服务端证书)
```

**调用方式**：Trading Engine 调用 AMS `ValidateAccount` 时，传入 `account_id` 参数；AMS 验证 mTLS 后返回账户状态，不需要用户 JWT。

### 6.2 服务标识（SAN 规范）

| 服务 | TLS Common Name | SAN DNS |
|------|----------------|---------|
| AMS | ams.internal | ams.svc.cluster.local |
| Trading Engine | trading.internal | trading.svc.cluster.local |
| Market Data | marketdata.internal | marketdata.svc.cluster.local |
| Fund Transfer | fundtransfer.internal | fundtransfer.svc.cluster.local |

### 6.3 证书生命周期

- **签发机构**：HashiCorp Vault PKI 或 cert-manager（Kubernetes）
- **有效期**：30 天（短期证书，自动轮换）
- **轮换方式**：cert-manager 在到期前 10 天自动申请新证书并更新 K8s Secret
- **热轮换**：`advancedtls.GetIdentityCertificatesForServer` 每次握手重新读取（60s 内存缓存）

---

## 7. 公钥分发（JWKS）

下游服务通过 JWKS 端点获取 AMS 的公钥，无需硬编码：

```
GET /.well-known/jwks.json
```

响应示例：
```json
{
  "keys": [
    {
      "kty": "RSA",
      "use": "sig",
      "alg": "RS256",
      "kid": "ams-2026-03",
      "n": "...(base64url encoded modulus)...",
      "e": "AQAB"
    }
  ]
}
```

**Key Rotation 流程**：
1. 生成新 RSA 密钥对
2. 将新公钥**追加**到 JWKS（不删除旧的）
3. 等待 Access Token 最大有效期（15 分钟）
4. 开始用新私钥签发 Token（`kid` 更新）
5. 等待所有旧 Token 过期（15 分钟）
6. 从 JWKS 中删除旧公钥

下游服务解析 JWT 时通过 `kid` header 定位正确的公钥，支持平滑轮换。

---

## 8. 认证中间件设计

### 8.1 完整中间件链（HTTP）

```
Request
  │
  ▼ [1] RateLimit          检查 Redis GCRA 限速（按 endpoint + IP/userID）
  │
  ▼ [2] RequestID          生成/传播 X-Request-ID → context
  │
  ▼ [3] CorrelationID      读取 X-Correlation-ID（无则生成），注入所有下游 header
  │
  ▼ [4] JWTAuth            验证签名 + 过期 + 黑名单 + 设备绑定
  │
  ▼ [5] AccountStatus      可选：关键操作实时查询 AMS 确认账户状态（非 Token 内缓存）
  │
  ▼ [6] RequirePermission  RBAC 权限检查（按路由配置）
  │
  ▼ [7] AuditLog           写审计事件（异步，不阻塞主路径）
  │
  ▼ Handler
```

### 8.2 公开端点白名单（无需认证）

```go
publicPaths := map[string]struct{}{
    "/v1/auth/login":          {},
    "/v1/auth/refresh":        {},
    "/v1/auth/forgot-password":{},
    "/.well-known/jwks.json":  {},
    "/healthz":                {},
    "/readyz":                 {},
}
```

> **规则**：行情快照端点（`/v1/market/quotes/snapshot`）属于 Market Data 服务，不在 AMS 管辖范围。AMS 仅管理账户相关端点。

---

## 9. 安全事件处理

### 9.1 强制撤销（账户冻结场景）

当合规系统触发账户冻结时，需要立即使所有活跃 Token 失效：

```go
func (s *AuthService) RevokeAllTokensForAccount(ctx context.Context, accountID, reason string) error {
    // 1. 获取该账户所有活跃设备
    devices, err := s.deviceRepo.ListActiveDevices(ctx, accountID)
    if err != nil {
        return fmt.Errorf("list devices: %w", err)
    }

    // 2. 删除所有设备的 Refresh Token
    for _, device := range devices {
        s.sessionStore.DeleteSession(ctx, device.DeviceID)
    }

    // 3. 将账户标记为 "revoke all tokens before this timestamp"
    // 在 account 表存储 tokens_revoked_before 字段
    // Auth middleware 检查 iat < tokens_revoked_before 则拒绝
    s.accountRepo.SetTokensRevokedBefore(ctx, accountID, time.Now().UTC())

    // 4. 发布事件通知其他服务
    s.eventBus.Publish(ctx, "ams.session.revoked", SessionRevokedEvent{
        AccountID: accountID,
        Reason:    reason,
        RevokedAt: time.Now().UTC(),
    })
    return nil
}
```

> **注意**：无法立即使所有活跃的 Access Token 失效（因为是无状态的），但通过 `tokens_revoked_before` 时间戳可以在下一次请求时拒绝。对于高风险账户，Auth Gateway 应实时查询此字段（接受 15 分钟窗口内的请求还是立即拒绝，取决于合规要求）。

### 9.2 异常检测事件

| 事件 | 触发条件 | 处理方式 |
|------|----------|----------|
| Refresh Token 不匹配 | 旧 RT 已被使用（可能重放攻击） | 撤销该设备所有 session；发送安全通知 |
| 设备 ID 不匹配 | Token 中 device_id ≠ 请求头 device_id | 拒绝；写安全审计日志 |
| 同账户多地登录 | 同一账户在短时间内从不同 IP 登录 | 发送登录通知；不自动锁定（用户选择） |
| 登录失败超限 | 5次/5分钟 | 临时锁定该 IP+账户组合；不透露原因 |
| 生物识别重新注册检测 | Flutter 侧检测到 biometric enrollment 变更 | 强制重新认证；发送安全通知 |

---

## 10. 与各端集成契约

### 10.1 Mobile（Flutter）集成

**登录请求**：
```http
POST /v1/auth/login
Content-Type: application/json
X-Device-ID: {device_id}
X-App-Version: 1.2.0

{
  "phone_number": "+852xxxxxxxx",
  "password": "...",
  "device_fingerprint": { "platform": "iOS", "model": "iPhone 15 Pro" }
}
```

**响应**：
```json
{
  "access_token": "eyJ...",
  "refresh_token": "550e8400-e29b-41d4-a716-446655440000",
  "expires_in": 900,
  "token_type": "Bearer",
  "account_id": "acc-xxx"
}
```

**存储规则**（Flutter）：
- `access_token`：内存变量（不持久化，App 重启后用 RT 刷新）
- `refresh_token`：`flutter_secure_storage`（Keychain/EncryptedSharedPreferences）

**生物识别保护**：出金、下单等敏感操作在调用 API 前，Flutter 层先完成生物识别验证，然后在请求头中加 `X-Biometric-Verified: true`（由 HMAC 签名保护，防止伪造）。

### 10.2 Admin Panel（React）集成

- **登录方式**：TOTP（`/v1/admin/auth/login` 专用端点）
- **Cookie**：Refresh Token 存储在 HttpOnly Secure Cookie（`SameSite=Strict`）
- **CSRF 防护**：`X-CSRF-Token` header（由服务端 double-submit cookie 方案验证）
- **会话超时**：前端在 5 分钟无操作后发送 `/v1/admin/auth/logout`

### 10.3 下游 Go 服务集成（Trading Engine / Fund Transfer）

下游服务验证 Access Token 时：
1. 从 `/.well-known/jwks.json` 缓存公钥（TTL 60 分钟）
2. 本地验证签名 + 过期（不需要网络调用 AMS）
3. 对高敏感操作（下单、出金）额外调用 AMS gRPC `ValidateAccount` 实时确认账户状态

```protobuf
// AMS gRPC 接口（下游服务调用）
service AccountService {
  rpc ValidateAccount(ValidateAccountRequest) returns (ValidateAccountResponse);
  rpc GetKYCTier(GetKYCTierRequest) returns (GetKYCTierResponse);
}

message ValidateAccountRequest {
  string account_id = 1;
  string required_status = 2; // "ACTIVE"
}

message ValidateAccountResponse {
  bool is_valid = 1;
  string account_status = 2;
  string rejection_reason = 3;
}
```

---

## 11. 密钥管理与轮换

### 11.1 RSA 私钥存储

| 环境 | 存储方式 |
|------|---------|
| 生产 | AWS KMS 存储私钥（API 签名，私钥不离开 HSM）或 Vault Transit |
| 开发/测试 | 本地 PEM 文件，通过环境变量 `JWT_PRIVATE_KEY_PEM` 注入 |

> **强制规则**：私钥绝不存储在代码仓库、Docker 镜像或 Kubernetes ConfigMap 中。

### 11.2 密钥轮换 SOP（Standard Operating Procedure）

```
Step 1: 生成新 RSA-2048 密钥对
  aws kms create-key --key-usage SIGN_VERIFY --key-spec RSA_2048

Step 2: 将新公钥追加到 JWKS（kid = ams-YYYY-MM）
  → 下游服务收到 JWKS 时自动缓存新公钥

Step 3: 等待 15 分钟（所有旧 Token 的最大剩余有效期）

Step 4: AMS 切换到新私钥签发 Token（更新 KMS Key ID 配置）

Step 5: 再等待 15 分钟（旧 kid 签发的 Token 全部过期）

Step 6: 从 JWKS 删除旧公钥

总耗时：~30 分钟，零停机，用户无感知
```

### 11.3 轮换监控

- Prometheus 指标 `ams_jwt_key_age_days`：当前私钥年龄
- 告警规则：私钥年龄 > 80 天时触发告警（建议 90 天轮换一次）

---

*参考：`docs/specs/tech-stack.md`（库选型）、`docs/specs/account-financial-model.md`（账户模型）、`.claude/rules/security-compliance.md`（安全规则）*
