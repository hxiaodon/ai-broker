---
name: security-protocol
description: 交易模块安全协议：动态 session-key、服务端 nonce、生物识别 challenge-response、WebSocket 连接后认证、设备绑定
type: domain-prd
version: 1
status: DRAFT
created: 2026-04-20T00:00+08:00
last_updated: 2026-04-20T00:00+08:00
source: mobile/docs/specs/trading/TRADING-SECURITY-HARDENING.md (Mobile Engineer 威胁分析)
revisions:
  - rev: 1
    date: 2026-04-20T00:00+08:00
    author: trading-engineer
    summary: "初始版本：基于 TRADING-SECURITY-HARDENING.md 评审结论，定义后端安全协议规范"
---

# 交易模块安全协议 — Domain PRD

> **来源**：`mobile/docs/specs/trading/TRADING-SECURITY-HARDENING.md`（Mobile Engineer 威胁分析 + DREAD 评分）  
> **消费方**：`order-lifecycle.md §3`、`trading-to-mobile.md §认证与安全`

---

## 1. 威胁与方案对照

| 漏洞 ID | 严重性 | 方案 | 本文章节 |
|---------|--------|------|---------|
| V-01 HMAC Secret 可逆向提取 | HIGH | S-01 动态 session-key | §2 |
| V-02 Idempotency-Key 客户端可伪造 | HIGH | S-02 服务端 nonce | §3 |
| V-03 biometricToken 硬编码 | CRITICAL | S-03 Challenge-Response | §4 |
| V-04 WebSocket token 暴露在 URL | MEDIUM | S-04 连接后认证 | §5 |
| V-05 撤单 DELETE 无 nonce | MEDIUM | S-02 nonce 覆盖 DELETE | §3 |
| V-06 无设备绑定校验 | MEDIUM | S-05 设备绑定强化 | §6 |

---

## 2. S-01 动态 HMAC Session Key

### 2.1 端点

```
POST /api/v1/auth/session-key
Authorization: Bearer <jwt_access_token>
X-Device-Id: <device_id>
```

**响应 200 OK**：
```json
{
  "key_id": "sk-550e8400",
  "hmac_secret": "<base64_encoded_secret>",
  "expires_at": "2026-04-20T10:00:00Z"
}
```

### 2.2 规格

| 项目 | 规格 |
|------|------|
| Secret 生命周期 | **30 分钟**（独立于 access token，不强绑定） |
| 轮换时机 | 剩余 5 分钟时客户端主动轮换 |
| 宽限期 | 旧 key 在轮换后保留 **5 分钟**（保护 in-flight 请求） |
| 存储 | 客户端：`flutter_secure_storage`；服务端：Redis `session_key:{key_id}` |
| 服务端存储格式 | `{ secret, user_id, device_id, expires_at }` |
| 过期处理 | 服务端返回 401 + `error_code: SESSION_KEY_EXPIRED`，客户端触发轮换 |
| 降级策略 | **禁止降级**到编译时 secret；获取失败时阻断交易，提示用户重新登录 |

### 2.3 灰度过渡

- 过渡期 **4 周**：服务端通过 `X-Key-Id` 区分 session key（新）和编译时 secret（旧）
- 第 3 周：对旧 secret 请求返回 `Deprecation-Warning` header
- 第 4 周末：下线旧 secret，配合 App 最低版本强制更新

---

## 3. S-02 服务端 Nonce

### 3.1 端点

```
GET /api/v1/trading/nonce
Authorization: Bearer <jwt_access_token>

# 批量获取（高频场景）
GET /api/v1/trading/nonce?count=5   # 最多 10 个
```

**响应 200 OK**：
```json
{
  "nonces": [
    { "nonce": "n-550e8400", "expires_at": "2026-04-20T09:31:00Z" }
  ]
}
```

### 3.2 规格

| 项目 | 规格 |
|------|------|
| Nonce 有效期 | **60 秒**（从生成到使用） |
| 使用次数 | 严格一次：`SETNX nonce:{n-xxx} "used" EX 60`（原子操作） |
| 限流 | **50 nonce/min per user**（批量计入总量） |
| 适用端点 | `POST /api/v1/orders`、`DELETE /api/v1/orders/:id` |
| 签名覆盖 | nonce 加入 HMAC payload（见§7） |

### 3.3 与 Idempotency-Key 的关系

两者互补，不互斥：

| 机制 | 防护目标 | 生命周期 |
|------|---------|---------|
| Nonce（服务端签发） | 防重放攻击 | 60s，一次性 |
| Idempotency-Key（客户端生成） | 网络重试安全 | 72h，可重用 |

---

## 4. S-03 生物识别 Challenge-Response

### 4.1 端点

```
GET /api/v1/trading/bio-challenge
Authorization: Bearer <jwt_access_token>
```

**响应 200 OK**：
```json
{
  "challenge": "<base64_32_random_bytes>",
  "expires_at": "2026-04-20T09:30:30Z"
}
```

### 4.2 bio_token 计算（客户端）

```
action_hash = SHA256(
  order_side + "|" + symbol + "|" + quantity + "|" + price + "|" + account_id
)

bio_token = HMAC-SHA256(
  session_secret,
  challenge + "|" + bio_timestamp + "|" + device_id + "|" + action_hash
)
```

> `action_hash` 字段拼接顺序固定，使用 `|` 分隔，防止序列化歧义。

### 4.3 服务端校验

1. 校验 challenge 存在于 Redis 且未使用（TTL 30s）
2. 标记 challenge 已消费（原子操作）
3. 用同一 `session_secret` 重算 `bio_token`，比对一致
4. 校验 `bio_timestamp` 在 15s 窗口内（防 bio_token 被挪用）

### 4.4 规格

| 项目 | 规格 |
|------|------|
| Challenge 有效期 | **30 秒** |
| 使用次数 | 严格一次 |
| action_hash 绑定 | 防止 challenge 被挪用到不同操作 |
| 降级 | 生物识别不可用 → PIN + SMS OTP 双因子（SMS 为最后降级，存在 SIM swap 风险） |

---

## 5. S-04 WebSocket 连接后认证

### 5.1 协议

连接 URL 不携带任何认证信息：
```
wss://api.example.com/ws/trading
```

连接建立后，客户端在 **10 秒内**发送首条 auth 消息：
```json
{
  "type": "auth",
  "token": "<jwt_access_token>",
  "device_id": "<device_id>",
  "timestamp": 1713200000000,
  "signature": "<hmac_sha256>"
}
```

签名 payload：
```
HMAC-SHA256(session_secret, "WS_AUTH\n" + timestamp + "\n" + device_id)
```

**服务端响应**：
```json
// 成功
{ "type": "auth.ok", "expires_in": 840 }

// 失败
{ "type": "auth.error", "code": "INVALID_TOKEN" }
```

### 5.2 规格

| 项目 | 规格 |
|------|------|
| 认证超时 | **10 秒**（弱网环境考量，超时后断开） |
| Token 续期 | 服务端在过期前 **2 分钟**推送 `token_expiring` 事件 |
| Reauth 期间消息 | Buffer **30 秒**，reauth 成功后补发；超时丢弃 |
| 旧协议下线 | `/ws/trading/v1`（旧）保留 **4 周**后下线，新协议走 `/ws/trading/v2` |

---

## 6. S-05 设备绑定强化

### 6.1 校验规则

- 所有交易请求必须携带 `X-Device-Id` header
- 服务端校验 `device_id` 属于该用户的已绑定设备列表
- `device_id` 参与 HMAC 签名（见§7）

### 6.2 临时设备授权

| 项目 | 规格 |
|------|------|
| 触发场景 | 用户换手机过渡期 |
| 授权有效期 | **72 小时** |
| 验证要求 | SMS OTP + 邮件双重确认 |
| 交易限额 | 临时设备单笔限额为正常的 **50%** |
| 到期处理 | 自动降级为"待绑定"状态，需完整设备绑定流程 |

---

## 7. HMAC 签名 Payload 最终规范

```
X-Signature = HMAC-SHA256(
  session_secret,
  METHOD + "\n" +
  PATH   + "\n" +
  TIMESTAMP + "\n" +
  NONCE  + "\n" +
  DEVICE_ID + "\n" +
  BODY_HASH
)
```

- `BODY_HASH` = `SHA256(raw_request_body_bytes)`
- 空 body（如 DELETE）：`BODY_HASH = SHA256("")` = `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- 所有字段均为 UTF-8 字符串，`\n` 为 LF（0x0A）

### 版本演进对照

| 版本 | Payload 结构 | 安全等级 |
|------|-------------|---------|
| v1（当前） | `METHOD\nPATH\nTIMESTAMP\nBODY_HASH` | ⚠️ secret 可逆向 |
| v2（S-01 后） | 同上，secret 改为动态 session key | ✅ secret 不可逆向 |
| v3（S-02 后） | `METHOD\nPATH\nTIMESTAMP\nNONCE\nBODY_HASH` | ✅ 不可重放 |
| **v4（S-05 后，目标）** | `METHOD\nPATH\nTIMESTAMP\nNONCE\nDEVICE_ID\nBODY_HASH` | ✅ 设备绑定 |

---

## 8. 实施优先级

| 优先级 | 方案 | 消除漏洞 | 后端工作量 | 目标 Sprint |
|--------|------|---------|----------|------------|
| **P0** | S-03 生物识别 Challenge-Response | V-03 CRITICAL | 1d | 当前 Sprint |
| **P0** | S-01 动态 session-key | V-01 HIGH | 1.5d | 当前 Sprint |
| **P1** | S-02 服务端 Nonce | V-02, V-05 HIGH | 1d | 下 Sprint |
| **P1** | S-04 WS 连接后认证 | V-04 MEDIUM | 0.5d | 下 Sprint |
| **P2** | S-05 设备绑定强化 | V-06 MEDIUM | 1d | Sprint+2 |
