---
type: protocol-spec
version: v2.1
date: 2026-03-22
supersedes: v2.0 (2026-03-14)
surface_prd: mobile/docs/prd/03-market.md
status: ACTIVE
---

# WebSocket 行情推送协议规范

## 概述

本文档定义 Market Data Service 的 WebSocket 推送协议，涵盖连接生命周期、认证流程、订阅管理、实时行情推送（注册用户与访客双轨）、心跳机制、错误处理，以及开发环境 Mock 使用指南。

---

## 消息帧类型约定（v2.1 更新）

WebSocket 采用**混合帧**协议，将控制平面（低频）与数据平面（高频）分离：

| 帧类型 | 方向 | 编码 | 用途 |
|--------|------|------|------|
| **文本帧（Text Frame）** | 双向 | JSON | 所有控制消息：auth、subscribe、unsubscribe、reauth、ping/pong、error、市场状态通知 |
| **二进制帧（Binary Frame）** | 服务端 → 客户端 | **Protobuf** (`WsQuoteFrame`) | 所有行情数据：初始快照、Tick 更新、访客延迟快照 |

**设计依据**：行情推送是高频路径（注册用户 tick 级），采用 Protobuf binary 相比 JSON 减少约 3-4x payload，降低移动端解析 CPU 开销和弱网延迟。控制消息低频且需要可读性，保持 JSON。

**Protobuf 消息定义**：`docs/specs/api/grpc/market_data.proto` 中的 `WsQuoteFrame`。

**WebSocket Subprotocol**：握手时客户端须声明 `Sec-WebSocket-Protocol: brokerage-market-v1`。

**其他约定**：
- 文本帧：客户端用 `"action"` 字段标识操作，服务端用 `"type"` 字段标识消息类型
- 所有时间戳（JSON）：ISO 8601 格式（`"2026-03-13T14:30:00.123Z"`）
- 所有价格（JSON + Protobuf）：string 类型，禁止 float/double

---

## 连接地址

| 环境 | 地址 |
|------|------|
| 生产 | `wss://api.broker.com/ws/market` |
| 开发 | `ws://localhost:8080/ws/market` |

---

## 连接生命周期

```
Client 连接建立 (WSS, Subprotocol: brokerage-market-v1)
        |
        v
[1. 认证] ── 5 秒内未发 auth → 服务端关闭 (code 4001)
        |
        v auth_result (JSON 文本帧)
[2. 订阅] ── 每次最多 50 个 symbols，超限返回 error
        |
        v subscribe_ack (JSON 文本帧)
[3. 快照交付] ── 每个 symbol 单独一条 WsQuoteFrame(SNAPSHOT) 二进制帧
        |
        v
[4. 实时推送]
     ├── 注册用户 → WsQuoteFrame(TICK) 二进制帧，tick 级推送（< 500ms P99）
     └── 访客     → WsQuoteFrame(DELAYED) 二进制帧，每 5 秒推送 T-15min 快照
        |
        v（注册用户 token 即将过期时）
[5. Token 续期] ── 服务端发 token_expiring (JSON)，客户端发 reauth (JSON)
        |
        v
[连接关闭] ── 正常 1000 / 异常 4001-4004
```

---

## Step 1：认证

连接建立后，客户端必须在 **5 秒内**发送 auth 消息，否则服务端主动关闭连接（code 4001）。

### 注册用户认证（JSON 文本帧）

```json
{
  "action": "auth",
  "token": "JWT_TOKEN"
}
```

### 访客（无 token，JSON 文本帧）

```json
{
  "action": "auth",
  "token": ""
}
```

### 服务端认证结果（JSON 文本帧）

```json
{
  "type": "auth_result",
  "success": true,
  "user_type": "registered",
  "token_expires_in": 850,
  "client_id": "uuid-xxxx"
}
```

认证失败时：

```json
{
  "type": "auth_result",
  "success": false,
  "user_type": null,
  "token_expires_in": null,
  "client_id": "uuid-xxxx"
}
```

字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `success` | bool | 认证是否成功 |
| `user_type` | string\|null | `"registered"` 或 `"guest"`；失败时为 null |
| `token_expires_in` | int\|null | 距 Token 过期的秒数；访客或失败时为 null |
| `client_id` | string | 本次连接 ID，用于服务端日志追踪与客户端调试 |

认证失败后服务端关闭连接（code 4002）。

---

## Step 2：订阅

认证成功后，客户端发送订阅请求。单次最多 **50 个** symbols。

### 订阅请求（JSON 文本帧）

```json
{
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA", "NVDA"]
}
```

### 订阅确认（JSON 文本帧）

服务端确认订阅接受的 symbols，**不含**行情快照（快照通过后续二进制帧单独下发）：

```json
{
  "type": "subscribe_ack",
  "symbols": ["AAPL", "TSLA", "NVDA"]
}
```

> **注**：服务端在发送 `subscribe_ack` 后，立即为每个 symbol 推送一条 `WsQuoteFrame(SNAPSHOT)` 二进制帧（见 Step 3）。

---

## Step 3：初始快照交付（Binary Frame）

`subscribe_ack` 之后，服务端为每个已订阅 symbol 各发送一条 **Protobuf 二进制帧**（`WsQuoteFrame`，`frame_type = SNAPSHOT`），携带完整行情快照。

**Protobuf 结构**（`WsQuoteFrame`）：

```
frame_type = FRAME_TYPE_SNAPSHOT
quote {
  symbol         = "AAPL"
  market         = MARKET_US
  price          = "182.5200"
  change         = "1.2400"
  change_pct     = "0.68"
  volume         = 45678900
  bid            = "182.5100"
  ask            = "182.5300"
  open           = "181.0000"
  high           = "183.5000"
  low            = "180.0000"
  prev_close     = "181.2800"
  turnover       = "8.34B"
  market_status  = MARKET_STATUS_REGULAR
  is_stale       = false
  stale_since_ms = 0
  delayed        = false
  timestamp      = "2026-03-13T14:30:00.123Z"
}
```

SNAPSHOT 包含 `Quote` 的**全部字段**，客户端以此建立本地状态，后续 TICK 帧只 patch 变动字段。

访客连接：`delayed = true`，`timestamp` 为 T-15min 时间，`frame_type = FRAME_TYPE_DELAYED`。

---

## Step 4：实时行情推送（Binary Frame）

### 注册用户：Tick 更新（`frame_type = FRAME_TYPE_TICK`）

每当订阅 symbol 有行情变动时立即推送，只含**变动字段**，未变动字段为 proto3 零值（空字符串 / 0）：

```
frame_type = FRAME_TYPE_TICK
quote {
  symbol        = "AAPL"
  price         = "182.6700"
  change        = "1.3900"
  change_pct    = "0.77"
  volume        = 45901200
  bid           = "182.6600"
  ask           = "182.6800"
  market_status = MARKET_STATUS_REGULAR
  is_stale      = false
  stale_since_ms = 0
  delayed       = false
  timestamp     = "2026-03-13T14:30:01.045Z"
}
```

> 不含 `open`/`high`/`low`/`prev_close`/`turnover`；客户端以 SNAPSHOT 为基础持续 patch。

### 访客：延迟快照（`frame_type = FRAME_TYPE_DELAYED`）

每 **5 秒**推送一次，内容为 T-15min 完整快照（`delayed = true`，包含全部字段）：

```
frame_type = FRAME_TYPE_DELAYED
quote {
  symbol        = "AAPL"
  price         = "180.2100"
  change        = "-0.3300"
  change_pct    = "-0.18"
  volume        = 32145600
  bid           = "180.2000"
  ask           = "180.2200"
  open          = "181.0000"
  high          = "183.5000"
  low           = "179.8000"
  prev_close    = "180.5400"
  turnover      = "5.79B"
  market_status = MARKET_STATUS_REGULAR
  is_stale      = false
  stale_since_ms = 0
  delayed       = true
  timestamp     = "2026-03-13T14:15:00.000Z"
}
```

`timestamp` 反映数据实际采集时间（T-15min），客户端须在 UI 显示"延迟 15 分钟"提示。

---

## Step 5：Token 续期与用户类型切换

### 服务端提前告警（JSON 文本帧，提前 2 分钟推送）

```json
{
  "type": "token_expiring",
  "expires_in": 120
}
```

### 客户端发送 reauth（JSON 文本帧）

客户端刷新 Token 后，无需断开连接，直接发送：

```json
{
  "action": "reauth",
  "token": "NEW_JWT_TOKEN"
}
```

### 服务端响应（JSON 文本帧）

```json
{
  "type": "reauth_result",
  "success": true,
  "user_type": "registered",
  "token_expires_in": 900
}
```

reauth 失败时：

```json
{
  "type": "reauth_result",
  "success": false,
  "user_type": null,
  "token_expires_in": null
}
```

**访客升级为注册用户的流程相同**：访客发送带有效 Token 的 `reauth`，服务端将该连接从 `DelayedQuoteGroup` 移至 `LiveQuoteGroup`，并立即推送当前实时快照（二进制帧，`frame_type = SNAPSHOT`）。

---

## 取消订阅（JSON 文本帧）

```json
{
  "action": "unsubscribe",
  "symbols": ["AAPL"]
}
```

服务端不返回确认消息，直接停止对该 symbol 的推送。

---

## 心跳

客户端每 **30 秒**发送一次 ping；服务端 **60 秒**无任何活动（含行情推送）则关闭连接（code 1000）。

### 客户端发送（JSON 文本帧）

```json
{
  "action": "ping"
}
```

### 服务端响应（JSON 文本帧）

```json
{
  "type": "pong",
  "timestamp": "2026-03-13T14:30:00Z"
}
```

---

## 交易暂停通知（JSON 文本帧）

当某 symbol 进入 HALTED 状态时，服务端主动向所有订阅该 symbol 的连接推送：

```json
{
  "type": "market_status",
  "symbol": "AAPL",
  "market_status": "HALTED",
  "halt_reason": "NEWS_PENDING",
  "timestamp": "2026-03-13T14:30:00Z"
}
```

`halt_reason` 可选值：`NEWS_PENDING` | `REGULATORY` | `VOLATILITY` | `OTHER`

市场恢复交易时推送同类消息，`market_status` 改回 `REGULAR`，`halt_reason` 字段省略。

---

## 错误推送（JSON 文本帧）

服务端检测到客户端操作违规时，以 `error` 消息告知（不主动断开连接，除非已达关闭条件）：

### symbols 超出限制

```json
{
  "type": "error",
  "code": "SYMBOL_LIMIT_EXCEEDED",
  "message": "每次订阅最多50个symbols",
  "max": 50
}
```

### 未认证即订阅

```json
{
  "type": "error",
  "code": "AUTH_REQUIRED",
  "message": "请先完成认证后再订阅"
}
```

### 无效 symbol 格式

```json
{
  "type": "error",
  "code": "INVALID_SYMBOL",
  "message": "symbol格式不合法",
  "symbols": ["INVALID@SYM"]
}
```

### 未知 action

```json
{
  "type": "error",
  "code": "UNKNOWN_ACTION",
  "message": "不支持的action类型",
  "action": "foo"
}
```

---

## 连接关闭码

| Code | 含义 |
|------|------|
| 1000 | 正常关闭（心跳超时或客户端主动断开） |
| 4001 | 认证超时（连接建立后 5 秒内未发 auth） |
| 4002 | Token 无效或已过期（auth/reauth 失败） |
| 4003 | symbols 数量超过限制（单次 > 50） |
| 4004 | 服务端主动关闭（维护 / 滚动重启） |

---

## 性能约定

| 指标 | 注册用户 | 访客 |
|------|----------|------|
| 推送频率 | tick 级（每次行情变动立即推送） | 每 5 秒推送一次 |
| 数据新鲜度 | 实时（delayed=false） | T-15min 快照（delayed=true） |
| 端到端延迟 (P99) | < 500ms | N/A（定时推送） |
| 行情帧编码 | Protobuf binary（~80-120 bytes/帧） | Protobuf binary（~120-180 bytes/帧） |
| 最大并发连接 | 10,000+ | 10,000+ |
| 心跳间隔 | 客户端 30s | 客户端 30s |
| 服务端空闲超时 | 60s 无活动关闭 | 60s 无活动关闭 |
| 断线重连退避 | 指数退避，初始 1s，最大 30s | 同左 |

---

## Mock 开发指南

### 连接地址（开发）

```
ws://localhost:8080/ws/market
```

### 数据源

- Mock 数据从 MySQL `stocks` 表读取初始行情
- 每秒在当前价格基础上随机 ±0.5% 波动
- 成交量每次随机增加 0–1000 股

### 访客延迟模拟（开发环境简化）

生产环境通过 `DelayedQuoteRingBuffer` 实现精确 T-15min 快照；开发环境简化为：将当前 Redis 快照直接标记 `delayed=true`，并在 `timestamp` 减去 15 分钟。

### Mock 股票列表

| Symbol | 名称 |
|--------|------|
| AAPL | 苹果 |
| TSLA | 特斯拉 |
| GOOGL | 谷歌 |
| MSFT | 微软 |
| AMZN | 亚马逊 |
| 0700.HK | 腾讯 |
| 9988.HK | 阿里巴巴 |
| 0941.HK | 中国移动 |
| 1810.HK | 小米 |
| 2318.HK | 中国平安 |

### 启动服务

```bash
cd services/market-data
mysql -u root -p < scripts/init_db.sql
go run cmd/server/main.go
```

### 测试示例

**控制消息（JSON 文本帧）** — 使用 wscat：

```bash
npm install -g wscat

# 连接（需声明 subprotocol）
wscat -c ws://localhost:8080/ws/market --subprotocol brokerage-market-v1

# Step 1: 注册用户认证
> {"action":"auth","token":"YOUR_JWT_TOKEN"}
< {"type":"auth_result","success":true,"user_type":"registered","token_expires_in":850,"client_id":"uuid-xxxx"}

# Step 1: 访客认证
> {"action":"auth","token":""}
< {"type":"auth_result","success":true,"user_type":"guest","token_expires_in":null,"client_id":"uuid-yyyy"}

# Step 2: 订阅
> {"action":"subscribe","symbols":["AAPL","TSLA","NVDA"]}
< {"type":"subscribe_ack","symbols":["AAPL","TSLA","NVDA"]}
# 随后收到 3 条 WsQuoteFrame(SNAPSHOT) 二进制帧（wscat 显示为 Binary message received）

# 心跳
> {"action":"ping"}
< {"type":"pong","timestamp":"2026-03-13T14:30:00Z"}

# 取消订阅
> {"action":"unsubscribe","symbols":["AAPL"]}
```

**行情二进制帧** — wscat 无法解码 protobuf，建议用集成测试或 Flutter 客户端验证。
开发阶段可在服务端增加一个调试端点 `GET /debug/ws-quote?symbol=AAPL` 以 JSON 格式返回当前快照，便于排查。

### 注意事项

- **Origin 验证**：开发环境允许 `http://localhost:*`；生产环境仅允许 `https://app.broker.com` 和 `https://www.broker.com`
- **生产环境**：关闭 MockPusher，通过 Kafka 消费真实行情，配置见 `config/config.yaml`
- **价格序列化**：所有价格字段必须为 string 类型，永远不使用 float；见财务编码规范
- **Flutter 客户端**：使用 `protobuf` 包（`package:protobuf`）解码二进制帧，控制帧正常 `jsonDecode`

---

## 更新日志

| 版本 | 日期 | 变更摘要 |
|------|------|---------|
| v2.1 | 2026-03-22 | 采用混合帧协议：控制消息保持 JSON 文本帧，行情推送（snapshot/tick/delayed）改为 Protobuf 二进制帧（`WsQuoteFrame`）；`subscribe_ack` 移除内嵌 snapshots，改为独立二进制帧下发；新增 subprotocol 声明 `brokerage-market-v1` |
| v2.0 | 2026-03-14 | 与 PRD-03 v1.1 完全对齐：消息认证改为消息体 action 字段（非 URL 参数）；双轨推送（注册用户 tick 级 / 访客 5s 延迟）；is_stale 字段；token 续期流程 |
| v1.0 | 2026-03-07 | 初始版本 |
