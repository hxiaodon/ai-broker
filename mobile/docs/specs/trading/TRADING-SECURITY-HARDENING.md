# Trading 模块安全加固方案 — 防逆向与请求伪造

**日期**: 2026-04-20  
**作者**: Mobile Engineer  
**状态**: ✅ REVIEWED — 后端评审完成，契约 v3 已同步，待客户端实现  
**范围**: 交易模块 REST API + WebSocket 通道的客户端-服务端安全协议  
**方法论**: STRIDE 威胁分析 + DREAD 风险评分

---

## 一、威胁模型概述

**攻击者画像**: 具备逆向工程能力的攻击者，能反编译 APK/IPA，提取编译时常量、API 端点、签名逻辑，并构造伪造请求。

**攻击目标**: 绕过客户端安全控制，直接调用交易 API 执行未授权的下单/撤单操作。

**攻击路径**:
```
逆向 APK → 提取 HMAC Secret → 构造签名 → 伪造下单请求
逆向 APK → 提取 biometricToken 硬编码值 → 绕过生物识别
抓包 → 捕获合法请求 → 30s 内重放（timestamp 窗口内）
抓包 → 捕获 WebSocket token → 建立伪造连接监听订单状态
```

---

## 二、现状评估

### 2.1 已有防护

| # | 机制 | 实现位置 | 防护目标 | 有效性 |
|---|------|---------|---------|--------|
| 1 | JWT Bearer Token | `AuthInterceptor` | 身份认证 | ✅ 有效（15min 过期 + refresh） |
| 2 | HMAC-SHA256 签名 | `HmacSigner` | 请求篡改 | ⚠️ 有条件有效（见 V-01） |
| 3 | X-Timestamp | 签名 payload 组成部分 | 重放攻击 | ⚠️ 依赖服务端 30s 窗口校验 |
| 4 | Idempotency-Key | `submitOrder` UUID v4 | 重复提交 | ⚠️ 客户端生成，可伪造（见 V-02） |
| 5 | 生物识别 | `local_auth` + `X-Biometric-Token` | 设备持有人确认 | ❌ 可绕过（见 V-03） |
| 6 | Certificate Pinning | Dio SPKI pinning（Phase 2） | 中间人攻击 | 🔜 未实现 |

### 2.2 已识别漏洞

| ID | 漏洞 | 严重性 | DREAD 评分 |
|----|------|--------|-----------|
| V-01 | HMAC Secret 编译时硬编码，可逆向提取 | **HIGH** | 21/25 |
| V-02 | 无服务端 Nonce，Idempotency-Key 客户端可伪造 | **HIGH** | 19/25 |
| V-03 | biometricToken 为硬编码字符串 `'biometric_confirmed'` | **CRITICAL** | 23/25 |
| V-04 | WebSocket token 暴露在 URL query 参数中 | **MEDIUM** | 15/25 |
| V-05 | cancelOrder 的 DELETE 请求无 nonce，30s 内可重放 | **MEDIUM** | 16/25 |
| V-06 | 无设备绑定校验（请求可从任意设备发起） | **MEDIUM** | 14/25 |

---

## 三、DREAD 详细评分

### V-01: HMAC Secret 可逆向提取

```
Damage:         5/5  — 攻击者可构造任意合法签名的交易请求
Reproducibility: 4/5  — APK 反编译工具成熟（jadx, Ghidra）
Exploitability:  4/5  — 提取 String.fromEnvironment 常量难度低
Affected Users:  4/5  — 所有用户（共享同一 secret）
Discoverability: 4/5  — 安全研究者常规检查项
Total: 21/25 (HIGH)
```

**根因**: `const hmacSecret = String.fromEnvironment('TRADING_HMAC_SECRET')` 在 `trading_repository_impl.dart:93` — Dart 编译时常量会被内联到 AOT 产物中。

### V-03: biometricToken 硬编码绕过

```
Damage:         5/5  — 完全绕过生物识别，可代替用户下单
Reproducibility: 5/5  — 字符串 'biometric_confirmed' 在二进制中明文可见
Exploitability:  5/5  — 直接在 HTTP header 中传入即可
Affected Users:  4/5  — 所有启用生物识别的用户
Discoverability: 4/5  — 逆向 order_submit_notifier.dart 即可发现
Total: 23/25 (CRITICAL)
```

**根因**: `order_submit_notifier.dart:57` — `biometricToken = 'biometric_confirmed'` 是一个占位符，服务端如果仅检查非空就通过，则无任何安全价值。

---

## 四、加固方案

### 方案 S-01: 动态 HMAC Secret（替代编译时常量）

**目标**: 消除 V-01，使逆向提取 secret 无法长期有效。

**协议设计**:

```
┌─────────┐                          ┌─────────┐
│  Client │                          │  Server │
└────┬────┘                          └────┬────┘
     │  POST /v1/auth/session-key         │
     │  Authorization: Bearer <JWT>       │
     │  X-Device-Id: <device_id>          │
     ├───────────────────────────────────►│
     │                                    │ 生成 session_hmac_secret
     │                                    │ 绑定 (user_id, device_id, expires_at)
     │  { "hmac_secret": "...",           │
     │    "expires_at": "...",            │
     │    "key_id": "sk-xxx" }            │
     │◄───────────────────────────────────┤
     │                                    │
     │  存入 SecureStorage                 │
     │  签名时使用 session secret          │
     │  Header 增加 X-Key-Id: sk-xxx      │
     └────────────────────────────────────┘
```

| 项目 | 规格 |
|------|------|
| Secret 生命周期 | 与 access token 同步（15min），refresh 时轮换 |
| 存储 | `flutter_secure_storage`（Keychain / EncryptedSharedPrefs） |
| 降级 | 获取失败时阻止交易，不降级到编译时 secret |
| 服务端 | 维护 `(key_id → secret, user_id, device_id, expires_at)` 映射表 |

**客户端改动**:
- `HmacSigner` 改为接受运行时 secret（非 const）
- 新增 `SessionKeyService`：登录后获取、refresh 时轮换、存 SecureStorage
- `tradingRepositoryProvider` 从 `SessionKeyService` 读取 secret

**服务端改动**:
- 新增 `POST /v1/auth/session-key` 端点
- HMAC 校验时根据 `X-Key-Id` 查找对应 secret
- 过期 key 拒绝请求（401），客户端触发 refresh 流程

---

### 方案 S-02: 服务端 Nonce（替代纯客户端 Idempotency-Key）

**目标**: 消除 V-02 和 V-05，确保每个交易请求不可重放。

**协议设计**:

```
┌─────────┐                          ┌─────────┐
│  Client │                          │  Server │
└────┬────┘                          └────┬────┘
     │  GET /v1/trading/nonce             │
     │  Authorization: Bearer <JWT>       │
     ├───────────────────────────────────►│
     │                                    │ 生成一次性 nonce (UUID + 过期时间)
     │  { "nonce": "n-xxx",               │
     │    "expires_at": "..." }           │ 存入 Redis (TTL 60s)
     │◄───────────────────────────────────┤
     │                                    │
     │  POST /v1/orders                   │
     │  X-Nonce: n-xxx                    │
     │  X-Signature: HMAC(... + nonce)    │
     ├───────────────────────────────────►│
     │                                    │ 校验 nonce 存在且未使用
     │                                    │ 标记 nonce 已消费
     │                                    │ 校验 HMAC（nonce 参与签名）
     │  { "order_id": "..." }             │
     │◄───────────────────────────────────┤
     └────────────────────────────────────┘
```

| 项目 | 规格 |
|------|------|
| Nonce 有效期 | 60 秒（从生成到使用） |
| 使用次数 | 严格一次（Redis SETNX + DEL） |
| 签名覆盖 | nonce 加入 HMAC payload：`method\npath\ntimestamp\nnonce\nbodyHash` |
| 适用端点 | `POST /v1/orders`、`DELETE /v1/orders/:id` |
| Idempotency-Key | 保留，用于网络重试场景（与 nonce 互补） |

**客户端改动**:
- 下单/撤单前先调 `GET /v1/trading/nonce`
- `HmacSigner.sign()` 增加 `nonce` 参数
- 签名 payload 变为 5 段：`METHOD\nPATH\nTIMESTAMP\nNONCE\nBODY_HASH`

**服务端改动**:
- 新增 `GET /v1/trading/nonce` 端点（限流：10 req/s per user）
- 订单提交时校验 nonce 有效性 + 一次性消费
- HMAC 校验逻辑更新（5 段 payload）

---

### 方案 S-03: 平台级生物识别 Attestation（替代硬编码 token）

**目标**: 消除 V-03，使生物识别结果不可伪造。

**方案 A（推荐）: Challenge-Response 模式**

```
┌─────────┐                          ┌─────────┐
│  Client │                          │  Server │
└────┬────┘                          └────┬────┘
     │  GET /v1/trading/bio-challenge     │
     │  Authorization: Bearer <JWT>       │
     ├───────────────────────────────────►│
     │                                    │ 生成 challenge (随机 32 字节)
     │  { "challenge": "base64...",       │ 存入 Redis (TTL 30s)
     │    "expires_at": "..." }           │
     │◄───────────────────────────────────┤
     │                                    │
     │  触发 local_auth.authenticate()    │
     │  认证成功后:                        │
     │    bio_token = HMAC-SHA256(        │
     │      session_secret,               │
     │      challenge + timestamp +       │
     │      device_id + action_hash       │
     │    )                               │
     │                                    │
     │  POST /v1/orders                   │
     │  X-Biometric-Token: <bio_token>    │
     │  X-Bio-Challenge: <challenge>      │
     │  X-Bio-Timestamp: <ts>            │
     ├───────────────────────────────────►│
     │                                    │ 校验 challenge 有效且未使用
     │                                    │ 用同一 session_secret 重算 bio_token
     │                                    │ 比对一致 → 生物识别确认
     └────────────────────────────────────┘
```

| 项目 | 规格 |
|------|------|
| Challenge 有效期 | 30 秒 |
| action_hash | SHA256(order_payload) — 绑定具体操作，防止 challenge 被挪用 |
| 降级 | 生物识别不可用时，降级为 PIN + SMS OTP 双因子 |

**方案 B（轻量替代）: 时间窗口签名**

如果后端不想维护 challenge 状态，可用时间窗口方案：
- 客户端生物识别成功后，用 session_secret 签名 `(timestamp + device_id + action_hash)`
- 服务端校验签名 + timestamp 在 15s 窗口内
- 弱于方案 A（无 challenge 绑定），但远优于硬编码字符串

**推荐**: 方案 A（交易场景安全要求高，值得多一次 RTT）

---

### 方案 S-04: WebSocket Token 迁移至连接后认证

**目标**: 消除 V-04，避免 token 泄露到日志和代理。

**当前**:
```
wss://api.example.com/ws/trading?token=eyJhbG...
```

**改为**:
```
wss://api.example.com/ws/trading          ← URL 无敏感信息

连接建立后，客户端发送首条消息:
{
  "type": "auth",
  "token": "eyJhbG...",
  "device_id": "dev-xxx",
  "timestamp": 1713200000000,
  "signature": "hmac..."
}

服务端校验后回复:
{ "type": "auth.ok", "expires_in": 840 }

校验失败:
{ "type": "auth.error", "code": "INVALID_TOKEN" }
→ 服务端主动关闭连接
```

| 项目 | 规格 |
|------|------|
| 认证超时 | 连接后 5 秒内必须发送 auth 消息，否则断开 |
| Token 续期 | 服务端推送 `token_expiring` 事件，客户端发送 `reauth` 消息 |
| 签名 | HMAC(session_secret, "WS_AUTH\n" + timestamp + "\n" + device_id) |

**客户端改动**:
- `TradingWsNotifier._connect()` 移除 URL 中的 token 参数
- 连接成功后发送 auth 消息
- 监听 `auth.ok` / `auth.error` 响应

**服务端改动**:
- WebSocket 端点不再从 query 参数读取 token
- 实现连接后认证协议
- 5 秒超时未认证则断开

---

### 方案 S-05: 设备绑定强化

**目标**: 消除 V-06，确保请求只能从已绑定设备发起。

**机制**:
- 所有交易请求必须携带 `X-Device-Id` header
- 服务端校验 device_id 是否属于该用户的已绑定设备列表
- device_id 参与 HMAC 签名（防篡改）
- 新设备首次交易需要额外验证（SMS OTP）

**签名 payload 最终形态**:
```
HMAC-SHA256(session_secret,
  METHOD + "\n" +
  PATH + "\n" +
  TIMESTAMP + "\n" +
  NONCE + "\n" +
  DEVICE_ID + "\n" +
  BODY_HASH
)
```

**客户端改动**:
- `HmacSigner` 增加 `deviceId` 参数
- 从 `DeviceInfoService` 获取持久化 device_id

**服务端改动**:
- 交易端点校验 device_id 属于用户绑定设备
- HMAC 校验包含 device_id

---

## 五、实施优先级与排期建议

| 优先级 | 方案 | 消除漏洞 | 客户端工作量 | 服务端工作量 | 建议排期 |
|--------|------|---------|------------|------------|---------|
| **P0** | S-03 生物识别 Attestation | V-03 (CRITICAL) | 1d | 1d | 本 Sprint |
| **P0** | S-01 动态 HMAC Secret | V-01 (HIGH) | 1d | 1.5d | 本 Sprint |
| **P1** | S-02 服务端 Nonce | V-02, V-05 (HIGH) | 0.5d | 1d | 下 Sprint |
| **P1** | S-04 WS Token 迁移 | V-04 (MEDIUM) | 0.5d | 0.5d | 下 Sprint |
| **P2** | S-05 设备绑定强化 | V-06 (MEDIUM) | 0.5d | 1d | Sprint+2 |

---

## 六、HMAC 签名 Payload 演进对比

| 版本 | Payload 结构 | 安全等级 |
|------|-------------|---------|
| **当前** | `METHOD\nPATH\nTIMESTAMP\nBODY_HASH` | ⚠️ 可逆向 secret 后伪造 |
| **S-01 后** | 同上，但 secret 为动态 session key | ✅ secret 不可逆向提取 |
| **S-02 后** | `METHOD\nPATH\nTIMESTAMP\nNONCE\nBODY_HASH` | ✅ 不可重放 |
| **S-05 后** | `METHOD\nPATH\nTIMESTAMP\nNONCE\nDEVICE_ID\nBODY_HASH` | ✅ 设备绑定 |

---

## 七、向后兼容与灰度策略

1. **双 secret 过渡期**: 服务端同时接受编译时 secret 和 session secret（通过 `X-Key-Id` 区分），灰度 2 周后下线旧 secret
2. **Nonce 可选期**: 首周 nonce 校验为 warn-only（记录但不拒绝），第二周切为 enforce
3. **WS 协议版本**: 通过 URL path 区分 `/ws/trading/v1`（旧）和 `/ws/trading/v2`（新），旧版本 4 周后下线
4. **客户端强制更新**: S-01 和 S-03 上线后，低于最低版本的客户端强制更新

---

## 八、关于 CSRF

**结论: 不适用。**

CSRF（Cross-Site Request Forgery）是浏览器环境的攻击向量，依赖 cookie 自动附带机制。本项目的交易 API：
- 认证通过 `Authorization: Bearer <JWT>` header（非 cookie）
- 移动端原生 HTTP 客户端不存在跨站请求场景
- H5 WebView 页面不涉及交易操作（仅 KYC、合规披露）

因此无需引入 CSRF Token。真正的威胁是**请求伪造/重放**（本文档 S-01 ~ S-05 已覆盖）。

---

## 九、评审 Checklist

请后端 + Security Engineer 评审以下决策点：

- [ ] S-01: session-key 的生命周期是否与 access token 绑定？还是独立管理？
- [ ] S-02: nonce 端点的限流策略（10 req/s）是否足够？高频交易场景是否需要批量 nonce？
- [ ] S-03: 选择方案 A（Challenge-Response）还是方案 B（时间窗口签名）？
- [ ] S-04: WS 认证超时 5 秒是否合理？弱网环境是否需要延长？
- [ ] S-05: 设备绑定是否需要支持"临时设备授权"（如用户换手机过渡期）？
- [ ] 灰度策略: 双 secret 过渡期 2 周是否足够覆盖所有客户端更新？
- [ ] 降级策略: session-key 获取失败时，是否允许降级到编译时 secret（牺牲安全换可用性）？

---

## 十、参考

| 文档 | 用途 |
|------|------|
| `.claude/rules/security-compliance.md` §Request Signing | 当前签名规范 |
| `.claude/rules/security-compliance.md` §Biometric Authentication | 生物识别要求 |
| `.claude/rules/financial-coding-standards.md` §Rule 4 | 幂等性要求 |
| `docs/specs/auth/security/AUTH-STRIDE-THREAT-MODEL.md` | Auth 模块 STRIDE 参考 |
| OWASP Mobile Top 10 — M3 (Insecure Communication) | WS token 泄露 |
| OWASP Mobile Top 10 — M9 (Reverse Engineering) | HMAC secret 提取 |
