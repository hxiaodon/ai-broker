---
type: protocol-spec
version: v2.0
date: 2026-03-14
supersedes: websocket-mock v1.0
surface_prd: mobile/docs/prd/03-market.md
status: ACTIVE
---

# WebSocket 行情推送协议规范

## 概述

本文档定义 Market Data Service 的 WebSocket 推送协议，涵盖连接生命周期、认证流程、订阅管理、实时行情推送（注册用户与访客双轨）、心跳机制、错误处理，以及开发环境 Mock 使用指南。

**消息约定**:
- 客户端 → 服务端：使用 `"action"` 字段标识操作类型
- 服务端 → 客户端：使用 `"type"` 字段标识消息类型
- 所有时间戳：ISO 8601 格式（`"2026-03-13T14:30:00.123Z"`）
- 所有价格：string 类型（`"182.5200"`，不使用浮点数）

---

## 连接地址

| 环境 | 地址 |
|------|------|
| 生产 | `wss://api.broker.com/ws/market` |
| 开发 | `ws://localhost:8080/ws/market` |

---

## 连接生命周期

```
Client 连接建立 (WSS)
        |
        v
[1. 认证] ── 5 秒内未发 auth → 服务端关闭 (code 4001)
        |
        v auth_result
[2. 订阅] ── 每次最多 50 个 symbols，超限返回 error
        |
        v subscribe_ack + snapshots
[3. 快照交付] ── 订阅确认时同步下发当前快照
        |
        v
[4. 实时推送]
     ├── 注册用户 → tick 级推送（< 500ms P99）
     └── 访客     → 每 5 秒推送一次，数据为 T-15min 快照，delayed=true
        |
        v（注册用户 token 即将过期时）
[5. Token 续期] ── 服务端提前 2 分钟发 token_expiring，客户端发 reauth
        |
        v
[连接关闭] ── 正常 1000 / 异常 4001-4004
```

---

## Step 1：认证

连接建立后，客户端必须在 **5 秒内**发送 auth 消息，否则服务端主动关闭连接（code 4001）。

### 注册用户认证

```json
{
  "action": "auth",
  "token": "JWT_TOKEN"
}
```

### 访客（无 token）

```json
{
  "action": "auth",
  "token": ""
}
```

### 服务端认证结果

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

### 订阅请求

```json
{
  "action": "subscribe",
  "symbols": ["AAPL", "TSLA", "NVDA"]
}
```

### 订阅确认（含当前快照）

服务端确认订阅，同时在 `snapshots` 中携带每个 symbol 的当前行情快照：

```json
{
  "type": "subscribe_ack",
  "symbols": ["AAPL", "TSLA", "NVDA"],
  "snapshots": {
    "AAPL": {
      "type": "quote",
      "symbol": "AAPL",
      "price": "182.5200",
      "change": "1.2400",
      "change_pct": "0.68",
      "volume": 45678900,
      "bid": "182.5100",
      "ask": "182.5300",
      "open": "181.0000",
      "high": "183.5000",
      "low": "180.0000",
      "prev_close": "181.2800",
      "turnover": "8342156.00",
      "market_status": "REGULAR",
      "timestamp": "2026-03-13T14:30:00.123Z",
      "delayed": false
    },
    "TSLA": {
      "type": "quote",
      "symbol": "TSLA",
      "price": "251.4400",
      "change": "-3.1200",
      "change_pct": "-1.22",
      "volume": 28934100,
      "bid": "251.4000",
      "ask": "251.4800",
      "open": "254.0000",
      "high": "255.3000",
      "low": "250.1000",
      "prev_close": "254.5600",
      "turnover": "7281432.00",
      "market_status": "REGULAR",
      "timestamp": "2026-03-13T14:30:00.098Z",
      "delayed": false
    }
  }
}
```

快照字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `price` | string | 最新成交价，4 位小数 |
| `change` | string | 涨跌额（相对前收盘价） |
| `change_pct` | string | 涨跌幅，保留 2 位小数，不含 `%` |
| `volume` | int | 成交量（股） |
| `bid` / `ask` | string | 买一/卖一价 |
| `open` / `high` / `low` | string | 当日开/高/低价 |
| `prev_close` | string | 前收盘价 |
| `turnover` | string | 成交额（USD/HKD），2 位小数 |
| `market_status` | string | `REGULAR` \| `PRE` \| `POST` \| `CLOSED` \| `HALTED` |
| `timestamp` | string | 行情时间戳（ISO 8601，UTC） |
| `delayed` | bool | `true` 表示延迟数据（T-15min），访客连接时为 `true` |

---

## Step 3 / Step 4：实时行情推送

### 注册用户（tick 级，delayed=false）

连接分组为 `LiveQuoteGroup`，订阅符号有更新时立即推送：

```json
{
  "type": "quote",
  "symbol": "AAPL",
  "price": "182.5200",
  "change": "1.2400",
  "change_pct": "0.68",
  "volume": 45678900,
  "bid": "182.5100",
  "ask": "182.5300",
  "market_status": "REGULAR",
  "timestamp": "2026-03-13T14:30:00.123Z",
  "delayed": false
}
```

推送不包含 `open`/`high`/`low`/`prev_close`/`turnover`，客户端以快照为基础持续 patch 最新字段。

### 访客（每 5 秒，T-15min 快照，delayed=true）

连接分组为 `DelayedQuoteGroup`，推送内容为 15 分钟前的行情快照：

```json
{
  "type": "quote",
  "symbol": "AAPL",
  "price": "180.2100",
  "change": "-0.3300",
  "change_pct": "-0.18",
  "volume": 32145600,
  "bid": "180.2000",
  "ask": "180.2200",
  "market_status": "REGULAR",
  "timestamp": "2026-03-13T14:15:00.000Z",
  "delayed": true
}
```

`timestamp` 反映数据实际采集时间（T-15min），客户端须在 UI 显示"延迟 15 分钟"提示。

---

## Step 5：Token 续期与用户类型切换

### 服务端提前告警（提前 2 分钟推送）

```json
{
  "type": "token_expiring",
  "expires_in": 120
}
```

### 客户端发送 reauth

客户端刷新 Token 后，无需断开连接，直接发送：

```json
{
  "action": "reauth",
  "token": "NEW_JWT_TOKEN"
}
```

### 服务端响应

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

**访客升级为注册用户的流程相同**：访客发送带有效 Token 的 `reauth`，服务端将该连接从 `DelayedQuoteGroup` 移至 `LiveQuoteGroup`，并立即推送当前实时快照。

---

## 取消订阅

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

### 客户端发送

```json
{
  "action": "ping"
}
```

### 服务端响应

```json
{
  "type": "pong",
  "timestamp": "2026-03-13T14:30:00Z"
}
```

---

## 交易暂停通知

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

## 错误推送

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

### wscat 测试示例

```bash
npm install -g wscat

# 连接（开发环境）
wscat -c ws://localhost:8080/ws/market

# Step 1: 注册用户认证
> {"action":"auth","token":"YOUR_JWT_TOKEN"}
< {"type":"auth_result","success":true,"user_type":"registered","token_expires_in":850,"client_id":"uuid-xxxx"}

# Step 1: 访客认证
> {"action":"auth","token":""}
< {"type":"auth_result","success":true,"user_type":"guest","token_expires_in":null,"client_id":"uuid-yyyy"}

# Step 2: 订阅
> {"action":"subscribe","symbols":["AAPL","TSLA","NVDA"]}
< {"type":"subscribe_ack","symbols":["AAPL","TSLA","NVDA"],"snapshots":{...}}

# Step 3: 接收实时推送（注册用户）
< {"type":"quote","symbol":"AAPL","price":"182.5200","change":"1.2400","change_pct":"0.68","volume":45678900,"bid":"182.5100","ask":"182.5300","market_status":"REGULAR","timestamp":"2026-03-13T14:30:00.123Z","delayed":false}

# 心跳
> {"action":"ping"}
< {"type":"pong","timestamp":"2026-03-13T14:30:00Z"}

# 取消订阅
> {"action":"unsubscribe","symbols":["AAPL"]}

# 测试 symbol 超限（触发 error）
> {"action":"subscribe","symbols":["A1","A2","A3","A4","A5","A6","A7","A8","A9","A10","A11","A12","A13","A14","A15","A16","A17","A18","A19","A20","A21","A22","A23","A24","A25","A26","A27","A28","A29","A30","A31","A32","A33","A34","A35","A36","A37","A38","A39","A40","A41","A42","A43","A44","A45","A46","A47","A48","A49","A50","A51"]}
< {"type":"error","code":"SYMBOL_LIMIT_EXCEEDED","message":"每次订阅最多50个symbols","max":50}
```

### 注意事项

- **Origin 验证**：开发环境允许 `http://localhost:*`；生产环境仅允许 `https://app.broker.com` 和 `https://www.broker.com`
- **生产环境**：关闭 MockPusher，通过 Kafka 消费真实行情，配置见 `config/config.yaml`
- **价格序列化**：所有价格字段必须为 string 类型，永远不使用 float；见财务编码规范
