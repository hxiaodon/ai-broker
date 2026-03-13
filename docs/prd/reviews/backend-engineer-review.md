# Backend 技术评审报告

**评审角色**: Backend Engineer (Go 1.22+)
**评审日期**: 2026-03-13
**覆盖模块**: 认证(01)、KYC(02)、行情(03)、设置(08)

---

## 一、Refresh Token 轮换的竞态条件导致双 Token 并发失效（P0）

**严重程度**: P0

**问题描述**

PRD-01 第 4.3 节声明 Refresh Token 采用"单次使用制（刷新后原 Token 失效）"，并在第 5.1 节注明"新旧 Token 5 分钟重叠期（防止并发请求失效）"。这两条规则存在根本性矛盾，且实现中有已知的竞态窗口：

1. 客户端 A（iOS）和客户端 A（Android 新设备，同一账户）同时在 Access Token 过期后发起 `POST /v1/auth/token/refresh`，两个请求几乎同时到达。
2. 如果两个请求都通过了"令牌是否有效"校验（在数据库行锁获取之前），将各自颁发新 Access Token，同时把原 Refresh Token 标记为已消费。
3. 接下来第二个完成的请求实际上消费了一个已被消费的 Refresh Token，此时应当拒绝还是接受？PRD 没有明确回答。

更严重的是：在 Go 服务中，若不使用 `SELECT ... FOR UPDATE` 或 Redis SETNX 来保证原子性操作，上述场景必然发生。PRD 只描述了业务期望，没有给出并发控制方案。

这是阻塞性问题，因为一旦上线，会导致真实用户在多端登录时被随机强制重新登录，引发客诉，且无法通过简单重试修复。

**建议解决方案**

在 Redis 中对 `refresh_token:{token_hash}` 使用 Lua 脚本或 Redis SET NX 实现原子消费，伪代码如下：

```go
// 原子操作：检查-标记-颁发
script := `
local val = redis.call('GET', KEYS[1])
if val == false then return {0, ''} end
if val == 'consumed' then return {-1, ''} end
redis.call('SET', KEYS[1], 'consumed', 'EX', 300)
return {1, val}
`
```

同时 PRD 需明确：当检测到同一 Refresh Token 被二次使用时，视为 Token 重放攻击，应吊销该账户所有 Refresh Token 并推送安全警告。

---

## 二、生物识别 Challenge 缺少服务端绑定，存在 Replay 攻击向量（P0）

**严重程度**: P0

**问题描述**

PRD-01 第 4.5 节生物识别登录接口：

```json
{
  "device_id": "uuid",
  "key_id": "key-uuid",
  "signature": "base64-signed-challenge",
  "challenge": "server-issued-challenge"
}
```

客户端在请求体中自带 `challenge` 字段提交，但 PRD 没有说明服务端如何验证该 Challenge 是否确实由服务端生成并绑定到当前 `device_id`。

攻击路径：
1. 攻击者抓包获取一次合法的 `{challenge, signature}` 对（有效期 30 秒，第 5.2 节）。
2. 若 Challenge 在 Redis 中已消费但未严格绑定 device_id，攻击者可在另一台机器提交同一签名对（改换 device_id）。
3. 更关键的是，PRD 完全缺少 Challenge 的下发接口——客户端从哪里获取 Challenge？PRD 里没有 `GET /v1/auth/biometric/challenge` 接口定义。

缺少 Challenge 下发接口本身就是阻塞性遗漏：开发无法实现，且任何"客户端自己生成 Challenge"的替代方案都等于无 Challenge 保护。

**建议解决方案**

补充 Challenge 下发接口：

```
POST /v1/auth/biometric/challenge
Request: { "device_id": "uuid", "key_id": "uuid" }
Response: { "challenge": "base64(random_32_bytes)", "expires_in": 30 }
```

服务端在 Redis 中存储 `biometric_challenge:{challenge_hash}` -> `device_id`，TTL=30s，且使用后立即删除（单次有效）。签名验证时服务端通过 challenge 查找绑定的 device_id，与请求体中的 device_id 对比，不一致则拒绝。

---

## 三、KYC 进度保存接口缺少幂等性，断网重试会导致步骤数据覆写（P0）

**严重程度**: P0

**问题描述**

PRD-02 第 5.1 节定义了 KYC 进度保存接口 `PUT /v1/kyc/progress`，但：

1. 接口没有要求 `Idempotency-Key` 请求头。根据 `.claude/rules/financial-coding-standards.md` Rule 4，所有状态变更 API 必须幂等。
2. `PUT /v1/kyc/progress` 使用 PUT 语义意味着全量替换，但请求体只包含单步数据（`step` + `data`），这与 PUT 语义冲突。客户端重试时，若服务端处理了第一次请求并返回了响应，但客户端因网络超时未收到响应，客户端重试将以相同数据再次 `PUT`，可能触发重复校验逻辑（如 OCR 二次调用）。
3. `resume_token` 在响应中返回了，但在后续接口（5.3 提交申请、5.5 补充材料）中没有使用，其作用和生命周期完全未定义。如果 resume_token 是续传令牌，它应当在每步保存时更新并在提交时验证，否则攻击者可以用旧的 resume_token 跳过某步骤。

**建议解决方案**

将接口改为 `PATCH /v1/kyc/progress` 并添加幂等性控制：

```
PATCH /v1/kyc/progress
Headers: Idempotency-Key: <uuid-v4>
Request: { "step": 1, "data": {...} }
```

服务端在 Redis 中存储 `kyc_progress_idem:{user_id}:{idempotency_key}` -> 响应内容，TTL=72小时。删除未使用的 `resume_token` 或明确定义其用途和验证逻辑。

---

## 四、用户注册时存在 TOCTOU 竞态：同一手机号并发注册可创建重复账户（P0）

**严重程度**: P0

**问题描述**

PRD-01 第 2.1 节注册流程：验证 OTP 成功后，服务端判断"新用户"则"自动创建账号"。`POST /v1/auth/otp/verify` 的响应字段 `is_new_user` 暗示服务端在验证 OTP 时同时完成了用户存在性检测和账户创建。

然而 PRD 中 `users` 表对 `phone` 字段有 `UNIQUE` 约束，但业务逻辑层没有说明如何防止并发注册：

1. 两个请求同时通过 OTP 验证（Redis 中 OTP 被标记已消费，但若验证和消费非原子，则两个请求均通过）。
2. 两个请求均判断 `SELECT id FROM users WHERE phone = ?` 返回空，均尝试 `INSERT INTO users`。
3. 第二个 INSERT 触发 UNIQUE 违反，但此时第一个请求已经返回了 access_token 给用户，第二个请求返回数据库错误，应对客户端返回什么？

在 Go 中若未显式处理 `pq.ErrCode("23505")`（unique violation），服务端可能返回 500，导致用户看到"注册失败"。

**建议解决方案**

使用 PostgreSQL 的 `INSERT ... ON CONFLICT DO NOTHING RETURNING id`，并在应用层区分"新建成功"和"已存在"两种情况：

```go
const q = `
    INSERT INTO users (phone, country_code)
    VALUES ($1, $2)
    ON CONFLICT (phone) DO NOTHING
    RETURNING id, created_at
`
```

若 RETURNING 无结果，则走已存在用户的登录路径。OTP 消费必须通过 Redis Lua 脚本原子完成，确保只有一个请求能消费同一 OTP。

---

## 五、设置更新接口无并发控制，多端同时修改导致静默覆写（P1）

**严重程度**: P1

**问题描述**

PRD-08 第 8.2 节的设置更新接口：

```
PUT /v1/users/settings
Request: 同 GET 响应结构（部分更新）
Response: { "updated": true }
```

存在以下问题：

1. 接口语义为 PUT（全量替换），但注释说"部分更新"，这是矛盾的。全量 PUT 意味着客户端每次只更新一个 Toggle，也必须提交完整 settings 对象，否则会覆盖其他字段为空/默认值。
2. 无乐观锁（没有 `version` 或 `updated_at` 字段用于冲突检测）。用户在手机端改了颜色方案，同时在另一台设备修改了交易确认方式，后提交的请求会静默覆盖先提交的，用户无任何感知。
3. 响应只返回 `{"updated": true}`，缺少完整更新后的 settings 对象，客户端无法确认最终生效值。

**建议解决方案**

改为 PATCH 语义，并引入乐观锁：

```
PATCH /v1/users/settings
Request: { "color_scheme": "GREEN_UP", "version": 5 }
Response: { "version": 6, "color_scheme": "GREEN_UP", ... }
```

在 `user_settings` 表增加 `version INTEGER NOT NULL DEFAULT 0`，更新时检查 `WHERE user_id = $1 AND version = $2`，若不匹配返回 `409 Conflict`，客户端重新 GET 后再提交。

---

## 六、WebSocket 身份验证机制未定义，访客/用户隔离存在漏洞（P1）

**严重程度**: P1

**问题描述**

PRD-03 第 6.1 节描述了 WebSocket 数据流，第 6.3 节说明了访客延迟实现：

> 访客 WebSocket 连接：服务端标记为 `guest=true`，行情推送在服务端延迟 15 分钟后发送

但 PRD 完全没有定义 WebSocket 的身份验证协议：

1. WebSocket 连接建立时如何传递 JWT？HTTP WebSocket 握手阶段不支持自定义 Header（浏览器限制），标准做法是 URL Query Parameter 传 token 或首条消息认证，但两者都未定义。
2. `guest=true` 的标记是服务端依据什么设置的？没有 token 就默认是 guest，还是需要客户端发送特定消息声明访客身份？
3. 若注册用户的 JWT 在 WebSocket 长连接过程中过期（15分钟），服务端是否降级为访客模式（开始发延迟数据）？还是断开连接？这对用户体验影响重大。
4. WebSocket 的 subscribe 消息没有包含认证信息，攻击者可以建立无认证 WebSocket 连接并无限订阅，造成服务端资源耗尽。

**建议解决方案**

定义 WebSocket 认证协议：

```json
// 连接建立后，客户端必须在 5 秒内发送认证消息，否则服务端关闭连接
{ "action": "auth", "token": "JWT" }
// 服务端响应
{ "type": "auth_result", "success": true, "user_type": "registered" | "guest" }
```

访客连接发送 `{ "action": "auth", "token": "" }` 即可（或省略 token 字段），服务端标记为 guest，所有推送延迟 15 分钟。

Token 过期处理：服务端在 token 剩余有效期前 2 分钟发送 `{ "type": "token_expiring", "expires_in": 120 }`，客户端负责刷新后发送 `{ "action": "reauth", "token": "new-JWT" }`。

---

## 七、KYC 提交接口缺少服务端完整性校验，可绕过关键步骤（P1）

**严重程度**: P1

**问题描述**

PRD-02 第 5.3 节的 KYC 提交接口 `POST /v1/kyc/submit` 请求体为空，服务端依靠什么判断 7 步是否全部完成？PRD 只说"材料完整情况下 1 工作日内完成"，但没有说明服务端的完整性验证逻辑。

具体风险：

1. 用户完成 Step 1-6，跳过 Step 7（协议签署）直接调用 `POST /v1/kyc/submit`，服务端是否拒绝？PRD 未说明。
2. `kyc_applications` 表没有记录各步骤完成状态的字段（无 `completed_steps` 位图或步骤状态字段），服务端无法高效校验完整性。
3. `POST /v1/kyc/submit` 同样没有 `Idempotency-Key`，用户双击提交按钮会创建两个 PENDING_REVIEW 状态的申请，审核队列混乱。

**建议解决方案**

在 `kyc_applications` 表增加步骤完成状态字段：

```sql
completed_steps  SMALLINT NOT NULL DEFAULT 0, -- 位图，第 n 位表示第 n 步完成
```

提交接口服务端验证：`completed_steps == 0b1111111`（7 步全部完成）才允许状态变为 SUBMITTED。

`POST /v1/kyc/submit` 必须要求 `Idempotency-Key`，并在 Redis 中做 72 小时的幂等缓存，重复提交直接返回第一次的响应。

---

## 八、Admin KYC 审核接口完全缺失（P1）

**严重程度**: P1

**问题描述**

PRD-02 第四节详细描述了 Admin Panel 的 KYC 审核工作台 UI，包括审核队列、通过/拒绝/补件操作、多角色权限。但第五节"后端接口规格"中完全没有对应的 Admin API 定义。

以下 Admin API 均缺失：

- `GET /v1/admin/kyc/queue` — 审核队列（带过滤、分页）
- `GET /v1/admin/kyc/{kyc_id}` — 查看单个 KYC 申请详情（含加密字段解密后展示）
- `GET /v1/admin/kyc/{kyc_id}/documents` — 获取证件图片（需生成临时签名 URL）
- `POST /v1/admin/kyc/{kyc_id}/approve` — 审核通过
- `POST /v1/admin/kyc/{kyc_id}/reject` — 拒绝开户
- `POST /v1/admin/kyc/{kyc_id}/request-info` — 要求补件

缺少这些接口，Admin Panel 无法开发，KYC 审核工作台（Phase 1 核心功能）无法上线。这是阻塞前端开发的 P1 问题。

**建议解决方案**

补充完整的 Admin KYC API 规格，重点注意：

1. 证件图片不能直接返回 Base64（数据量太大），应使用对象存储（S3/OSS）生成有时效的预签名 URL（TTL=5分钟），防止图片 URL 泄露。
2. 所有 Admin 操作必须记录至 `kyc_review_log`（PRD 有此表，但 API 层未定义触发时机）。
3. 审核通过后需要触发账户激活事件（发 Kafka 消息），激活 `users` 表的 KYC 状态，这个跨服务触发链路在 PRD 中没有描述。

---

## 九、`user_devices` 表 device_id 唯一性约束会导致换机登录丢失历史（P1）

**严重程度**: P1

**问题描述**

PRD-01 第九节数据模型中：

```sql
CREATE TABLE user_devices (
    device_id  VARCHAR(64) UNIQUE NOT NULL,
    ...
```

`device_id` 有全局唯一约束，而非用户级唯一。这意味着：

1. 若 device_id 是设备硬件标识，同一台手机被 A 用户使用后，B 用户（前任机主）在同一台手机上登录，`INSERT INTO user_devices` 会因为 UNIQUE 违反失败。
2. 实际上 device_id 的唯一性应该是 `(user_id, device_id)` 的组合，而不是全局唯一。
3. 同一用户同一设备重新登录（如卸载重装 App），若 device_id 相同则触发 UNIQUE 违反，正确逻辑应该是更新 `last_login_at` 并复用同一行，但 UNIQUE 约束不能表达这个语义（需要 ON CONFLICT DO UPDATE）。

**建议解决方案**

修改唯一约束为复合唯一，并加入 ON CONFLICT 处理：

```sql
CONSTRAINT uq_user_device UNIQUE (user_id, device_id)
```

对于重新登录场景使用 `INSERT ... ON CONFLICT (user_id, device_id) DO UPDATE SET last_login_at = NOW(), is_active = true`。对于设备转让场景，当 B 用户在 A 用户曾用设备上登录，只检查 `user_id + device_id` 组合即可，互不干扰。

---

## 十、OTP 发送接口的 `purpose` 字段缺少服务端强制校验（P1）

**严重程度**: P1

**问题描述**

PRD-01 第 4.1 节 OTP 发送接口：

```json
{
  "phone": "+8613800138000",
  "purpose": "login" | "register"
}
```

PRD-08 第 8.3 节手机号更改接口 `POST /v1/users/phone/change` 同时需要 old_otp 和 new_otp 验证。问题在于：

1. OTP 在 Redis 中存储的 Key 是 `otp:{phone}:{request_id}`，但没有与 `purpose` 绑定。攻击者可以用 `purpose=login` 向目标手机号发送 OTP，然后在 `/v1/users/phone/change` 接口中使用该 OTP 作为旧号码验证码完成手机号更换（如果服务端只校验 OTP 是否正确，不校验 purpose）。
2. PRD-08 的手机号更换流程也没有对应的 OTP 发送接口（`POST /v1/users/phone/change/send-otp`），依赖的是通用 OTP 接口还是独立接口，没有定义。

**建议解决方案**

将 `purpose` 写入 Redis OTP 值中，验证 OTP 时同时核验 purpose：

```go
// Redis value
type OTPRecord struct {
    HashedOTP string `json:"hashed_otp"`
    Purpose   string `json:"purpose"` // "login" | "register" | "phone_change" | "account_close"
    Phone     string `json:"phone"`
}
```

验证接口必须传入预期 purpose，不一致则返回 `400 Bad Request`。PRD 需补充所有使用 OTP 的接口对应的 purpose 枚举值和独立发送入口。

---

## 十一、K 线历史接口缺少分页和数据量限制，全历史月线可能返回 30 年数据（P1）

**严重程度**: P1

**问题描述**

PRD-03 第 7.2 节 K 线历史数据接口：

```
GET /v1/market/kline?symbol=AAPL&period=1d&from=2026-01-01&to=2026-03-13
```

第 3.3 节描述月线显示"全历史"数据。问题：

1. 月线数据 AAPL 从 1980 年上市至今约有 550+ 条，但日线数据若 `from=1990-01-01&to=2026-03-13` 则有 9000+ 条，均无分页限制。
2. 接口没有 `limit` 参数，没有最大返回数量约束，恶意用户可以对所有股票并发请求全历史数据，对数据源（Polygon.io）造成巨大费用，同时对后端产生 OOM 风险（Go 中把 9000 个 OHLCV 结构体序列化为 JSON 本身不大，但配合 10万并发就成问题）。
3. 接口没有定义当 `from` 和 `to` 超出该股票上市/退市时间范围时的行为，返回空数组还是 400？
4. `period=1m`（分时图当日数据）没有出现在接口定义中，但 PRD 3.3 节说分时图走 WebSocket 实时推送。历史分时图（比如用户看昨天的分时）怎么获取？这是遗漏场景。

**建议解决方案**

增加强制 `limit` 上限（REST 接口默认最多返回 500 条，超出返回 `cursor` 做游标分页）：

```
GET /v1/market/kline?symbol=AAPL&period=1d&from=2026-01-01&limit=500&cursor=xxx
```

分时历史数据补充接口：`GET /v1/market/kline?symbol=AAPL&period=1min&date=2026-03-12`（仅支持单日查询，最多返回 390 条）。

---

## 十二、Watchlist 并发添加/删除缺少幂等处理，可能导致重复自选（P1）

**严重程度**: P1

**问题描述**

PRD-03 第 7.5 节：

```
POST /v1/watchlist
Body: { "symbol": "AAPL" }
```

该接口没有定义 `Idempotency-Key`，没有声明重复添加时的行为（返回 200 还是 409）。

1. 用户快速双击"收藏"按钮，两个 POST 请求同时到达，若服务端使用 `INSERT INTO watchlist (user_id, symbol, added_at) VALUES (...)` 且没有 `UNIQUE (user_id, symbol)` 约束，会插入重复行，用户自选列表出现同一股票两次。
2. PRD 自选股数据模型完全缺失（没有 `watchlist` 表定义），无法确认是否有唯一约束。
3. 第 5.1 节说"最大数量 200 只（Phase 1 暂不设上限）"，这是矛盾的说法：写了 200 只但又说"暂不设上限"。如果不设上限，用户可以添加任意数量，WebSocket 批量订阅会让服务端订阅数爆炸。

**建议解决方案**

补充 `watchlist` 数据模型：

```sql
CREATE TABLE user_watchlist (
    user_id    UUID NOT NULL REFERENCES users(id),
    symbol     VARCHAR(10) NOT NULL,
    added_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sort_order INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, symbol)
);
CREATE INDEX idx_watchlist_user_id ON user_watchlist(user_id);
```

`POST /v1/watchlist` 使用 `INSERT ... ON CONFLICT DO NOTHING` 实现幂等。明确上限为 200 条，超出返回 `422 Unprocessable Entity` 并告知当前数量。

---

## 十三、W-8BEN 到期未更新时的扣税状态变更缺少触发机制（P1）

**严重程度**: P1

**问题描述**

PRD-02 第 5 步税务申报描述：

> 到期未更新：股息自动按 30% 扣税（后台标记，Admin 工作台提醒）

但 PRD 没有定义触发这个状态变更的机制：

1. 谁负责在 W-8BEN 过期时（`valid_until <= NOW()`）将用户的股息税率从 10% 切换到 30%？没有定义定时任务（Cron Job）或事件驱动机制。
2. PRD-08 第 3.2 节说"到期前 90 天系统推送提醒"，这个推送是定时扫描触发还是在 W-8BEN 保存时就 schedule 好了？
3. `w8ben_forms` 表没有 `status` 字段（ACTIVE/EXPIRED/SUPERSEDED），到期时如何高效查询哪些用户的 W-8BEN 已过期？
4. 一个用户可能有多个 W-8BEN 记录（更新后），哪一条是当前有效的？表中没有 `is_current` 字段，也没有唯一约束限制每个 user_id 只有一条当前有效记录。

**建议解决方案**

在 `w8ben_forms` 增加字段：

```sql
status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE / EXPIRED / SUPERSEDED
is_current      BOOLEAN NOT NULL DEFAULT true,
CONSTRAINT uq_user_w8ben_current UNIQUE (user_id, is_current) WHERE is_current = true
```

定义后台定时任务（每日 00:00 UTC 运行）：

```
SELECT user_id FROM w8ben_forms WHERE is_current = true AND valid_until < NOW()
```

对超期用户标记 `status = EXPIRED`，发送 Kafka 事件触发通知服务推送，并通知交易引擎对该用户股息按 30% 扣税。

---

## 十四、手机号更改后 Token 失效机制存在时间窗口（P1）

**严重程度**: P1

**问题描述**

PRD-08 第 4.3 节手机号更改流程，完成后执行：

> 更新成功 → 推送通知至新旧号码 → 所有设备强制重新登录

但 PRD-01 第 5.1 节说明 Token 失效通过 Redis 黑名单实现，TTL = Token 剩余有效期。

问题：

1. "所有设备强制重新登录"需要使所有该用户的 Refresh Token 失效，但 Refresh Token 是 HttpOnly Cookie，服务端无法主动推送"请求"，只能在下次 `POST /v1/auth/token/refresh` 时拒绝。这意味着在用户下次刷新前（最长 7 天），旧设备仍然可以用已有的 Access Token（最长 15 分钟有效）访问系统。
2. 黑名单方案要枚举所有该用户的 Access Token 并加入黑名单，但 Access Token 是 JWT，服务端默认不存储其列表，无法枚举。
3. 手机号是登录凭证，更换后原手机号如果被他人注册，若没有正确失效旧 Refresh Token，可能存在账户混淆风险。

**建议解决方案**

在 `users` 表增加 `token_version INTEGER NOT NULL DEFAULT 0`，JWT payload 中携带 `token_version`。每次手机号更改时 `UPDATE users SET token_version = token_version + 1`。服务端验证 JWT 时额外检查 `token_version` 是否匹配（需查 Redis 缓存该值，避免每次查 DB）。所有旧版本 Token 在下次请求时被拒绝，无需维护黑名单列表。

---

## 十五、行情快照接口的 `symbols` Query 参数缺少长度限制（P1）

**严重程度**: P1

**问题描述**

PRD-03 第 7.1 节：

```
GET /v1/market/quotes?symbols=AAPL,TSLA,NVDA
```

没有定义 `symbols` 参数的最大数量限制。

1. 攻击者或行为不当的客户端可以在一次请求中传入 1000 个 symbol，服务端需要向 Polygon.io 发起批量查询，每个 symbol 对应一次网络请求（若 Polygon 不支持真正的批量接口，则是 N 次请求）—— 典型的 N+1 查询放大攻击。
2. 即使 Polygon 支持批量接口，1000 个 symbol 的 URL Query String 长度超过 8KB，某些 Load Balancer 会以 414 拒绝。
3. Watchlist 最大 200 只股票时，行情列表页需要一次获取 200 个 symbol 的报价。PRD 没有说明是使用这个 REST 接口还是 WebSocket 推送作为初始值，若用 REST 轮询 200 个 symbol 则对 Polygon.io 的 API 调用量极高（按调用次数计费）。

**建议解决方案**

明确限制：`symbols` 最多 50 个，超出返回 `400 Bad Request: too many symbols, max 50`。

在 Go handler 中：

```go
symbols := strings.Split(r.URL.Query().Get("symbols"), ",")
if len(symbols) > 50 {
    http.Error(w, "too many symbols", http.StatusBadRequest)
    return
}
```

行情列表页改为：WebSocket 连接建立后通过 subscribe 消息批量订阅，REST 接口仅用于首屏快照（<20 个 symbol）。

---

## 十六、注销账户接口缺少幂等性和前置条件的原子校验（P2）

**严重程度**: P2

**问题描述**

PRD-08 第 8.4 节注销账户接口 `POST /v1/users/close-account`：

1. 没有 `Idempotency-Key`。用户提交注销后网络超时重试，可能触发两次注销流程。
2. 前置条件（无持仓、无余额、无待处理申请、无未成交委托）需要跨服务查询（持仓在交易引擎，余额在资金服务），这些条件的原子性检查如何保证？在检查完"无未成交委托"到实际执行注销之间，可能有新委托被提交（时间窗口）。
3. PRD 说"7 年内数据依法保留，您将无法使用相同手机号重新注册"——但 `users` 表的 `phone` 字段有 UNIQUE 约束，如果注销后不释放手机号但又不允许该手机号重注册，需要在手机号上加状态标记，现有数据模型不支持。

**建议解决方案**

注销流程使用两阶段提交模式：先调用各子服务验证前置条件（trading service、fund service），全部通过后通过 Saga 协调注销事务。在 `users` 表增加 `closed_at TIMESTAMP WITH TIME ZONE` 和 `phone_released BOOLEAN DEFAULT false`，注销后手机号不物理删除但标记 UNIQUE 约束无效化（将 phone 字段更新为 `{original_phone}__closed_{user_id}` 这类不可能被输入的值，释放原手机号 UNIQUE 槽位但保留审计记录）。

---

## 十七、KYC 状态机缺少对 `IN_PROGRESS` 的超时处理（P2）

**严重程度**: P2

**问题描述**

PRD-02 第 3.1 节 KYC 状态机：

```
NOT_STARTED → IN_PROGRESS（用户开始填写）→ SUBMITTED → PENDING_REVIEW → ...
```

当用户进入 KYC 流程后离开（App 挂起或卸载），状态停留在 `IN_PROGRESS`，此时：

1. 没有定义超时时间。用户 30 天不操作，状态一直是 `IN_PROGRESS`，影响业务统计（看起来有大量"进行中"的 KYC 申请）。
2. `kyc_applications` 表没有 `started_at` 字段（`created_at` 可以作为起点，但语义不准确），无法精确追踪"用户首次填写时间"以计算完成率漏斗。
3. 断点续传依赖 `resume_token`（见问题三），但 PRD 没有定义 `resume_token` 是否有过期时间。如果用户 90 天后回来继续，旧的 `resume_token` 是否还有效？

**建议解决方案**

在 `kyc_applications` 增加 `started_at` 和 `expires_at` 字段。`IN_PROGRESS` 状态设置 60 天超时：超时后状态变为 `EXPIRED`，下次打开 KYC 流程时系统决定是 RESUME（60 天内）还是 RESTART（60 天后重新开始）。定时任务每日扫描 `WHERE status = 'IN_PROGRESS' AND started_at < NOW() - INTERVAL '60 days'` 并更新状态。

---

## 十八、行情数据 `market_cap` 字段使用整数，溢出风险（P2）

**严重程度**: P2

**问题描述**

PRD-03 第 7.1 节响应示例：

```json
"market_cap": 2800000000000
```

苹果公司市值 2.8 万亿美元，数值为 `2800000000000`。

1. PRD 没有定义此字段的数据类型。若前端或后端使用 JavaScript `number`（IEEE 754 双精度浮点），最大安全整数为 `2^53 - 1 = 9007199254740991`（约 9 千万亿），2.8 万亿在安全范围内，但未来万亿级别的公司市值（如 Google、Microsoft 已超过 3 万亿）仍在安全范围内。
2. 然而若后端 Go 服务使用 `int32`（最大约 21 亿），`2800000000000` 直接溢出。PRD 没有明确要求使用 `int64` 或 `decimal`。
3. 按照 `.claude/rules/financial-coding-standards.md` Rule 1，所有金融数值不能使用浮点数，但 `market_cap` 可以接受字符串表示（`"2800000000000"`）以保持 JSON 安全性。

**建议解决方案**

明确所有金融/市值字段的数据类型规范：

- 后端 Go：`market_cap int64` 或 `shopspring/decimal.Decimal`（若需要精度）
- 数据库：`NUMERIC(20, 0)` 或 `BIGINT`
- JSON 传输：使用字符串格式 `"market_cap": "2800000000000"` 避免 JavaScript 数字精度问题
- 在接口规格中明确：所有货币和市值字段均以字符串形式传输

---

## 十九、`auth_audit_log` 缺少关键索引，合规查询性能不足（P2）

**严重程度**: P2

**问题描述**

PRD-01 第九节审计日志表定义：

```sql
CREATE TABLE auth_audit_log (
    id          UUID PRIMARY KEY,
    user_id     UUID REFERENCES users(id),
    event_type  VARCHAR(50) NOT NULL,
    device_id   VARCHAR(64),
    ip_address  INET,
    success     BOOLEAN,
    details     JSONB,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

表中只有 `id` 的 PRIMARY KEY 索引，完全没有其他索引，而合规场景的典型查询包括：

1. `SELECT * FROM auth_audit_log WHERE user_id = ? ORDER BY created_at DESC LIMIT 100` — 查某用户登录历史，全表扫描。
2. `SELECT * FROM auth_audit_log WHERE ip_address = ? AND created_at > ?` — 排查 IP 异常，全表扫描。
3. `SELECT * FROM auth_audit_log WHERE event_type = 'OTP_FAILED' AND created_at > ?` — 统计一段时间内的失败次数。

随着数据量增长（用户登录 7 年保留），表会有数亿行，没有索引的查询响应时间无法接受。

另外，`user_id` 可以为 NULL（`REFERENCES users(id)` 没有 NOT NULL 约束），对于 `event_type = 'OTP_SENT'` 的记录（此时账户可能不存在），user_id 为空是合理的，但应显式声明允许 NULL。

**建议解决方案**

补充必要索引：

```sql
CREATE INDEX idx_auth_audit_user_time  ON auth_audit_log (user_id, created_at DESC) WHERE user_id IS NOT NULL;
CREATE INDEX idx_auth_audit_event_time ON auth_audit_log (event_type, created_at DESC);
CREATE INDEX idx_auth_audit_ip         ON auth_audit_log USING GIST (ip_address inet_ops);
CREATE INDEX idx_auth_audit_device     ON auth_audit_log (device_id, created_at DESC) WHERE device_id IS NOT NULL;
```

使用分区表（按月分区）提升大数据量下的查询和归档效率。

---

## 二十、KYC 个人信息表中 `risk_level` 字段放置位置不合理（P2）

**严重程度**: P2

**问题描述**

PRD-02 第六节 `kyc_personal_info` 表中包含 `risk_level SMALLINT` 字段，但该字段是由 Step 4（投资评估，Risk Assessment）的数据计算得出，而非个人信息的一部分。

1. `risk_level` 放在 `kyc_personal_info` 里是错误的归属：个人信息（姓名/身份证/就业）是 Step 1 的数据，风险等级是 Step 4 的输出。
2. 表中没有单独的 `kyc_risk_assessment` 表来存储 Step 4 的原始数据（投资经验年限、投资频率、产品知识、投资目标、风险承受能力），只有计算结果 `risk_level`，失去了原始评估数据的可审计性。
3. 若后期需要重新评估风险等级（例如 Phase 2 的 EDD），无法回溯原始答题数据。
4. Step 3（财务状况）的数据（年收入、净资产、资金来源）也没有对应的表定义，这部分数据同样被遗漏了。

**建议解决方案**

补充独立的评估数据表：

```sql
CREATE TABLE kyc_financial_profile (
    kyc_id              UUID PRIMARY KEY REFERENCES kyc_applications(id),
    annual_income_range VARCHAR(30),
    net_worth_range     VARCHAR(30),
    liquid_assets_range VARCHAR(30),
    fund_sources        VARCHAR(200)[],  -- ARRAY of source codes
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE kyc_risk_assessment (
    kyc_id              UUID PRIMARY KEY REFERENCES kyc_applications(id),
    investment_exp_years VARCHAR(20),
    investment_frequency VARCHAR(20),
    product_knowledge   VARCHAR(20)[],
    investment_objective VARCHAR(30),
    risk_tolerance      VARCHAR(20),
    computed_risk_level SMALLINT NOT NULL,  -- 1-5
    computed_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 总结

| # | 模块 | 问题 | 严重程度 |
|---|------|------|---------|
| 01 | 认证(01) | Refresh Token 轮换竞态条件导致双 Token 并发失效 | P0 |
| 02 | 认证(01) | 生物识别 Challenge 缺少服务端绑定，存在 Replay 攻击向量 + Challenge 下发接口缺失 | P0 |
| 03 | KYC(02) | KYC 进度保存接口缺少幂等性，断网重试会导致数据覆写 | P0 |
| 04 | 认证(01) | 用户注册时同一手机号并发请求存在 TOCTOU 竞态 | P0 |
| 05 | 设置(08) | 设置更新接口无并发控制，多端同时修改导致静默覆写 | P1 |
| 06 | 行情(03) | WebSocket 身份验证机制未定义，访客/用户隔离存在漏洞 | P1 |
| 07 | KYC(02) | KYC 提交接口缺少服务端完整性校验，可绕过关键步骤 | P1 |
| 08 | KYC(02) | Admin KYC 审核接口完全缺失，阻塞 Admin Panel 开发 | P1 |
| 09 | 认证(01) | user_devices 表 device_id 全局唯一约束逻辑错误 | P1 |
| 10 | 认证(01) | OTP purpose 字段缺少服务端强制校验，可跨场景复用 OTP | P1 |
| 11 | 行情(03) | K 线历史接口缺少分页和数据量限制，全历史查询风险 | P1 |
| 12 | 行情(03) | Watchlist 并发添加缺少幂等处理，数据模型缺失 | P1 |
| 13 | KYC(02) | W-8BEN 到期状态变更缺少触发机制和当前有效记录约束 | P1 |
| 14 | 设置(08) | 手机号更改后 Token 全量失效机制存在时间窗口 | P1 |
| 15 | 行情(03) | 行情快照接口 symbols 参数缺少长度限制，N+1 放大攻击 | P1 |
| 16 | 设置(08) | 注销账户接口缺少幂等性和前置条件原子校验 | P2 |
| 17 | KYC(02) | KYC 状态机缺少 IN_PROGRESS 超时处理 | P2 |
| 18 | 行情(03) | market_cap 字段数据类型未定义，整数溢出风险 | P2 |
| 19 | 认证(01) | auth_audit_log 缺少关键索引，合规查询性能不足 | P2 |
| 20 | KYC(02) | risk_level 字段归属错误，财务状况和投资评估原始数据缺失 | P2 |

**P0 汇总（4 个，需立即修复后方可开始开发）**:
- 问题 01、02、03、04 均涉及并发安全或安全漏洞，必须在技术设计阶段解决，否则上线后无法通过安全审计。

**P1 汇总（11 个，需在 Sprint 1 评审前确认）**:
- 问题 08（Admin KYC 接口缺失）是 Sprint 1 开发阻塞项，建议最优先补充。
- 问题 06（WebSocket 认证）、07（KYC 完整性校验）影响核心业务流程，需同步澄清。

**P2 汇总（5 个，不阻塞开发，但建议在 Phase 1 上线前完成）**:
- 问题 18（market_cap 数据类型）应在定义接口 Mock 时一并明确，避免前后端联调时产生歧义。
