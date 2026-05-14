---
name: order-lifecycle
description: 订单生命周期、状态转换矩阵、DAY/GTC 有效期规则、幂等性要求、请求安全头规范
type: domain-prd
surface_prd: mobile/docs/prd/04-trading.md (§五 订单状态生命周期、§十一 合规要求)
version: 2
status: DRAFT
created: 2026-03-30T00:00+08:00
last_updated: 2026-04-20T00:00+08:00
revisions:
  - rev: 1
    date: 2026-03-30T00:00+08:00
    author: trading-engineer
    summary: "初始版本：从 Surface PRD 提取订单状态机、有效期规则、审计要求"
  - rev: 2
    date: 2026-04-20T00:00+08:00
    author: trading-engineer
    summary: "安全加固：更新 §3 幂等性（补充 nonce 机制）、§8.1 请求头规范（session-key、nonce、bio-challenge）；详细协议见 security-protocol.md"
  - rev: 3
    date: 2026-05-13T00:00+08:00
    author: trading-engineer
    summary: "P0-7/P0-10：扩展状态机 (QUEUED/AMENDING/AMEND_REJECTED)、新增 DAY_EXT/GTC_EXT/IOC/FOK/AON/OPG/MOO/CLS/MOC TIF；新增 §3 市场状态枚举与排队策略；新增 §8.6 改单 API；GTC 公司行动自动调整规则"
---

# 订单生命周期 (Order Lifecycle) — Domain PRD

> **对应 Surface PRD**：`mobile/docs/prd/04-trading.md` §五（用户可见状态）、§十一（合规）
> **依赖 Spec**：`services/trading-engine/docs/specs/domains/01-order-management.md`

---

## 1. 订单内部状态转换矩阵

订单从创建到终结的完整生命周期由以下状态转换定义（Phase 1 v3 引入了 QUEUED / AMENDING / AMEND_REJECTED 三个新状态以支持市场未开排队和改单）：

```
CREATED (用户提交)
  ↓
VALIDATED (字段校验通过)
  ├─→ QUEUED (市场未开 / 节假日 / 港股午休 / 熔断暂停)
  │     ↓
  │  RISK_APPROVED (开盘前 60s 批量复核通过)
  ↓
RISK_APPROVED (风控检查通过) / RISK_REJECTED (风控拒绝 → 已拒绝)
  ↓
PENDING (发送至交易所)
  ↓
OPEN (交易所接收)
  ├─→ PARTIAL_FILL (部分成交) ──┐
  │                             ↓
  ├─→ FILLED (全部成交)        FILLED
  │
  ├─→ AMENDING (用户改单待确认)
  │     ├─→ OPEN (改单接受, 应用新 price/qty)
  │     ├─→ FILLED/PARTIAL_FILL (改单期间原单成交)
  │     └─→ AMEND_REJECTED (交易所拒绝) → 回 OPEN/PARTIAL_FILL
  │
  ├─→ CANCELLED (用户撤销) / EXCHANGE_REJECTED (交易所拒绝)
  │
  └─→ EXPIRED (DAY 单收盘 / GTC 单满期)
```

### 状态转换表

| 当前状态 | 触发条件 | 目标状态 | 说明 |
|---------|---------|---------|------|
| CREATED | 格式校验通过 | VALIDATED | 订单字段合法性检查 |
| CREATED | 格式校验失败 | REJECTED | 返回错误给用户，不计入审计 |
| VALIDATED | 风控检查通过 + 市场已开 | RISK_APPROVED | 8 道风控检查全通过 |
| VALIDATED | 风控通过但市场未开 | QUEUED | 进入排队队列，等待开盘前 60s 批量复核 |
| VALIDATED | 风控检查失败 | RISK_REJECTED | 风控拒绝（资金不足/限制/合规）；计入审计 |
| QUEUED | 市场开盘前 60s 复核通过 | RISK_APPROVED | 复核内容：buying_power + symbol_status + price band |
| QUEUED | 用户主动撤销 | CANCELLED | 排队单撤销不收手续费 |
| QUEUED | 开盘前复核失败（如标的当日停牌） | REJECTED | 记录拒绝原因 |
| RISK_APPROVED | FIX 发送成功 | PENDING | 订单发送至交易所 |
| RISK_APPROVED | FIX 发送失败 | PENDING_RETRY | 重试机制（可配置重试次数），失败超限后标记异常 |
| PENDING | 交易所 ExecutionReport (ExecType=NEW) | OPEN | 交易所确认接收 |
| PENDING | 交易所 ExecutionReport (ExecType=REJECTED) | EXCHANGE_REJECTED | 交易所拒绝 |
| OPEN | ExecutionReport (ExecType=PARTIAL_FILL) | PARTIAL_FILL | 部分数量成交 |
| OPEN/PARTIAL_FILL | ExecutionReport (ExecType=FILL) | FILLED | 全部成交 |
| OPEN/PARTIAL_FILL | 用户撤单请求 + ExecutionReport (ExecType=CANCELLED) | CANCELLED | 用户成功撤销 |
| OPEN/PARTIAL_FILL | 用户发起改单 | AMENDING | 发送 FIX 35=G OrderCancelReplaceRequest |
| AMENDING | 交易所接受改单 (ExecType=5 Replaced) | OPEN | 应用新 price/qty，关联新 ClOrdID |
| AMENDING | 改单期间发生部分成交（原 ClOrdID） | PARTIAL_FILL | 吸收成交，状态保持 AMENDING 直到 Replaced ACK |
| AMENDING | 改单期间发生全成交 | FILLED | 改单作废 |
| AMENDING | 交易所拒绝改单 (35=9 OrderCancelReject) | AMEND_REJECTED | 记录 reject 原因，原订单保持 |
| AMEND_REJECTED | 改单失败后原订单未成交 | OPEN | 状态回滚 |
| AMEND_REJECTED | 改单失败但原订单已部分成交 | PARTIAL_FILL | 状态回滚 |
| OPEN/PARTIAL_FILL | DAY 单收盘时间到达 | EXPIRED | 当日有效单自动过期 |
| OPEN/PARTIAL_FILL | GTC 单满 90 天 | EXPIRED | GTC 有效期上限过期 |

### 终止状态（不可转移）

- **FILLED**：全部成交，进入持仓和结算流程
- **REJECTED**：风控拒绝 / QUEUED 复核失败 / 校验失败，用户原订单取消
- **RISK_REJECTED**：风控失败，用户原订单取消
- **CANCELLED**：用户撤销，部分成交的部分继续持仓
- **EXCHANGE_REJECTED**：交易所拒绝，不计入成交
- **EXPIRED**：DAY/GTC 到期，自动取消

### 非终态过渡状态

- **QUEUED**：风控已通过，等待市场开盘前批量释放（详 §3 市场状态）
- **AMENDING**：用户改单中，等待交易所应答；可由原单成交事件中转
- **AMEND_REJECTED**：交易所拒绝改单，原订单保持，可继续被撤、被改、或被成交

---

## 2. 订单有效期规则（TIF）

### 2.1 DAY / DAY_EXT（当日有效）

**DAY（默认）**：仅常规交易时段（RTH）有效；收盘自动取消未成交部分。

| 场景 | 系统行为 |
|------|---------|
| RTH 内下单 | 立刻发送，收盘 (16:00 ET / 16:00 HKT) 自动 cancel |
| 盘前 (US 04:00-09:30 ET) 下单 | QUEUED，09:30 ET 开盘前 60s 批量发送 |
| 盘后 (US 16:00-20:00 ET) 下单 | REJECT (`EXTENDED_HOURS_NOT_ENABLED`)；提示用户改用 DAY_EXT 或重新提交 |
| 港股午休 (12:00-13:00 HKT) 下单 | QUEUED 到 13:00 自动释放 |
| 节假日 / 周末下单 | QUEUED 到下一交易日开盘 |

**DAY_EXT（含扩展时段）**：美股专属；要求用户在账户设置中显式启用 `extended_hours_enabled=true`。

| 场景 | 系统行为 |
|------|---------|
| Pre-market 04:00-09:30 ET 下单 | 立刻发送；可在盘前撮合 |
| RTH 09:30-16:00 ET 下单 | 同 DAY |
| After-hours 16:00-20:00 ET 下单 | 立刻发送；可在盘后撮合 |
| 20:00 ET 后下单 | QUEUED 到次日 04:00 ET |

**用户操作前置条件（DAY_EXT）**：
- 账户必须开通"扩展时段交易"权限（一次性开通，含风险确认）
- 标的必须支持 ext-hours（部分 OTC 不支持）

**示例**：用户在 08:00 ET 提交 DAY 单 → 系统自动 QUEUE 到 09:30 释放，用户 app 显示"等待开盘"；同一时刻提交 DAY_EXT 单 → 立刻发送，撮合盘前。

### 2.2 GTC / GTC_EXT（长期有效）

**定义**：订单保持有效直到用户撤销、90 天到期或被公司行动取消。

| 规则 | 约束 |
|------|------|
| 有效期上限 | 最多 90 天；到期前 3 天和 1 天 push 通知提醒 |
| 到期处理 | 自动转换为 EXPIRED 状态 + 用户通知 |
| 成交不受限 | GTC 单可随时成交 |
| GTC vs GTC_EXT | GTC 仅在 RTH 撮合；GTC_EXT 在 04:00-20:00 ET 内每日撮合（美股）|
| 撤销后重下 | 重新计算 90 天 |
| 港股 GTC | 仅 RTH 撮合（港股无 ext-hours） |

#### 2.2.1 公司行动自动调整

为避免用户手动维护 GTC 单的价格，系统在以下公司行动后自动调整（用户可在账户设置中关闭）：

| 行动类型 | 调整公式 | 说明 |
|---------|---------|------|
| Forward Split (e.g. 2-for-1) | `new_price = old_price / split_ratio; new_qty = old_qty * split_ratio` | 保持订单经济意义不变 |
| Reverse Split (e.g. 1-for-10) | `new_price = old_price * reverse_ratio; new_qty = old_qty / reverse_ratio` | 数量必须整除，余数舍弃并通知用户 |
| Cash Dividend (除息) | `new_price = old_price - dividend_per_share`（向下取整到 tick size）| 行业惯例；可在账户设置关闭 |
| Stock Dividend (股票股利) | 等价于 forward split | |
| Rights Offering (配股) | 自动取消 GTC 单 | 用户须重新评估并重下 |
| Merger / Spin-off | 自动取消 GTC 单 | 复杂场景，强制人工决策 |

价格调整后写入 `order_events` (`ORDER_PRICE_ADJUSTED`)，并触发 push 通知"您的 GTC 单已根据公司行动自动调整：$X → $Y"。

**监管合规：**
> **GTC 90 天上限的合理性**（PM 确认）：
> 
> - **SEC/美股**：SEC Rule 10b-4 未明确限制 GTC 有效期。大多数美国经纪商（如 Fidelity、Charles Schwab）采用 60-90 天限制，符合行业惯例。
> - **SFC/港股**：SFO 未明确规定 GTC 有效期。HKEX 建议 90-180 天；我们采用 90 天保守估计，满足港股要求。
> - **FINRA/风险管理**：Rule 4210 未涉及订单有效期。90 天是平衡的选择，既保护用户（避免订单遗忘），也降低系统风险。
>
> **法务最终确认状态**：待确认（PM 已确认业务方案，法务评审预计 2026-04-05）
> 如法务有异议，需在 Phase 1 上线前（下周）完成调整和确认。

### 2.3 即时类 TIF（IOC / FOK / AON）

| TIF | 含义 | 美股 | 港股 |
|-----|------|:----:|:----:|
| IOC (Immediate or Cancel) | 立刻成交可成交部分，未成交立即取消 | ✅ | ✅ |
| FOK (Fill or Kill) | 必须立刻全部成交，否则全单取消 | ✅ | ✅ |
| AON (All-or-None) | 必须全部成交，但允许等待 | ✅ | ❌ |

适用场景：算法策略、大单分批、套利。

### 2.4 集合竞价 TIF（OPG/MOO / CLS/MOC）

| TIF | 含义 | 截止提交时间 |
|-----|------|------------|
| OPG / MOO (Market on Open) | 参与开盘集合竞价 | NYSE: 09:28 ET / HKEX: 09:22 HKT |
| CLS / MOC (Market on Close) | 参与收盘集合竞价 | NYSE: 15:50 ET / HKEX: 16:08 HKT |

在截止时间后提交的 OPG/CLS 单：QUEUED 到下一个集合竞价窗口，用户可见提示"已排队至下一开盘/收盘竞价"。

### 2.5 TIF × 市场时段支持矩阵

> **来源**：与 `services/trading-engine/docs/specs/domains/01-order-management.md §3.2.1` 完全一致；任何不一致以 spec 为准。

图例：✅ 接受立刻发送 | 🕓 接受并 QUEUED 到下个有效 session | ❌ 拒单

**美股 (Eastern Time)**

| TIF | Pre 04:00-09:30 | Opening 09:30 | RTH 09:30-15:50 | Closing 15:50-16:00 | After 16:00-20:00 | Closed 20:00-04:00 |
|-----|:-:|:-:|:-:|:-:|:-:|:-:|
| DAY | 🕓→RTH | ✅ | ✅ | ✅ | ❌ | 🕓→次日 RTH |
| DAY_EXT | ✅ | ✅ | ✅ | ✅ | ✅ | 🕓→次日 04:00 |
| GTC | 🕓→RTH | ✅ | ✅ | ✅ | 🕓→次日 RTH | 🕓→次日 RTH |
| GTC_EXT | ✅ | ✅ | ✅ | ✅ | ✅ | 🕓→次日 04:00 |
| IOC | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |
| FOK | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| AON | 🕓→RTH | ✅ | ✅ | ✅ | ❌ | 🕓→次日 RTH |
| OPG/MOO | ✅（截止 09:28）| ❌ | ❌ | ❌ | 🕓→次日 OPG | 🕓→次日 OPG |
| CLS/MOC | 🕓→Closing | 🕓→Closing | 🕓→Closing（截止 15:50）| ❌ | 🕓→次日 CLS | 🕓→次日 CLS |

**港股 (Hong Kong Time)**

| TIF | Pre-open 09:00-09:30 | AM 09:30-12:00 | Lunch 12:00-13:00 | PM 13:00-16:00 | Closing 16:00-16:10 | Closed |
|-----|:-:|:-:|:-:|:-:|:-:|:-:|
| DAY | ✅ | ✅ | 🕓→13:00 | ✅ | ✅ | 🕓→次日 |
| GTC | ✅ | ✅ | 🕓→13:00 | ✅ | ✅ | 🕓→次日 |
| IOC | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| FOK | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| OPG | ✅（截止 09:22）| ❌ | ❌ | ❌ | ❌ | 🕓→次日 |
| CLS | 🕓 | 🕓 | 🕓 | 🕓（截止 16:08）| ❌ | 🕓→次日 |

---

## 3. 市场状态与订单接收策略

### 3.1 市场状态枚举（用户可见）

| 内部状态 | 用户可见文案 | 下单按钮 | 提示 |
|---------|------------|---------|------|
| OPEN | 交易中 | 可点 | — |
| PRE_OPEN_AUCTION (US/HK) | 集合竞价中 | 可点 | "正在集合竞价，仅 OPG/MOO 单参与" |
| PRE_MARKET (US) | 盘前交易 | 可点（需开通扩展时段） | "盘前交易，仅 DAY_EXT/GTC_EXT 单立刻发送；其他单将在 RTH 开盘后发送" |
| LUNCH (HK) | 港股午休 | 可点 | "港股午休中（12:00-13:00），订单将在 13:00 自动发送" |
| AFTER_HOURS (US) | 盘后交易 | 可点（需开通扩展时段） | "盘后交易，仅 DAY_EXT/GTC_EXT 单可下" |
| CLOSING_AUCTION | 收盘竞价中 | 可点 | "收盘集合竞价进行中" |
| CLOSED | 已收盘 | 可点（限部分 TIF） | "市场已收盘，可下单（次日开盘前批量发送）" |
| HOLIDAY | 节假日 | 可点（限 DAY/GTC） | "市场休市（节日：{name}），订单将在下一交易日 {date} 开盘前发送" |
| EARLY_CLOSE | 半日市 | 可点 | "今日提前收盘 {time}（{reason}）" |
| EMERGENCY_HALT | 紧急停市 | 置灰 | "市场临时停市，原因：{reason}" |
| MWCB_PAUSE | 熔断中 | 可点 | "美股熔断 Level {N}，预计 {time} 恢复，您的订单已排队" |

### 3.2 排队（QUEUED）单的用户体验

- **下单成功响应**：app 显示订单状态 = "等待开盘"，附带预计释放时间
- **Push 通知**：
  - 入队时："您的订单已接收，将在 {date 09:30 ET} 开盘后发送"
  - 释放成功时："您的订单已发往交易所"
  - 释放失败时（如复核拒绝）："您的订单未能发送，原因：{reason}"
- **撤销**：用户可在 QUEUED 期间随时撤销，不收手续费，状态直接置为 CANCELLED
- **改单**：QUEUED 单不允许改单（提示"请先撤销后重新下单"）

### 3.3 GTC 到期提醒规则

- 到期前 3 天：push 通知"您的 GTC 单将在 3 天后过期，可登录查看或重下"
- 到期前 1 天：push 通知 + app 内消息
- 到期当日：自动 EXPIRED + push "您的 GTC 单已自动取消，可重新下单"
- 公司行动调整：当日通知"您的 GTC 单已根据 {行动类型} 自动调整：价格 {old} → {new}"

---

## 4. 幂等性与重复检测

> **安全协议详见**：`docs/prd/security-protocol.md`（session-key、nonce、bio-challenge 完整协议）

### 4.1 请求安全头（POST /api/v1/orders 和 DELETE /api/v1/orders/:id）

```
POST /api/v1/orders
Headers:
  Authorization:      Bearer <jwt_access_token>
  Idempotency-Key:    <uuid_v4>                    # 网络重试幂等
  X-Key-Id:           <session_key_id>             # 动态 HMAC session key 标识
  X-Timestamp:        <unix_ms>                    # 服务端校验 ±30s 窗口
  X-Nonce:            <server_issued_nonce>        # 服务端签发，一次性，60s TTL
  X-Device-Id:        <device_id>                  # 已绑定设备 ID
  X-Signature:        <hmac_sha256>                # 见下方 payload 格式
  X-Biometric-Token:  <bio_token>                  # 仅 POST /orders 必填
  X-Bio-Challenge:    <challenge>                  # 仅 POST /orders 必填
  X-Bio-Timestamp:    <unix_ms>                    # 仅 POST /orders 必填
```

**HMAC-SHA256 签名 payload（6 段，\n 分隔）**：
```
METHOD\nPATH\nTIMESTAMP\nNONCE\nDEVICE_ID\nBODY_HASH
```
- `BODY_HASH` = `SHA256(raw_request_body_bytes)`；空 body 用 `SHA256("")` 固定值
- `session_secret` 通过 `POST /api/v1/auth/session-key` 获取，存于 SecureStorage

### 4.2 Idempotency-Key 机制

所有订单提交请求都必须包含 `Idempotency-Key` 头，用于网络重试场景的重复检测（与 nonce 互补：nonce 防重放，Idempotency-Key 保证重试安全）。

```
POST /api/v1/orders
Headers:
  Idempotency-Key: "550e8400-e29b-41d4-a716-446655440000" (UUID v4)
Body:
  {
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 100,
    ...
  }
```

### 4.3 重复检测规则

| 场景 | 处理方式 | 缓存时长 |
|------|---------|---------|
| 首次请求 | 创建订单，记录 Idempotency-Key | 72 小时 |
| 重复请求（同 Key，同参数） | 返回缓存的第一次请求结果（订单 ID + 状态） | 72 小时 |
| 重复请求（同 Key，不同参数） | 拒绝请求，返回 409 Conflict + 错误信息 | — |
| 超过缓存时长 | 生成新订单（用户需重新生成新 Key 并下单） | — |

**实现细节**：
- 幂等性缓存存储在 Redis，格式：`idempotency:{key} → {order_id, status, created_at}`
- 网络超时场景：客户端可以用**相同的 Key** 重新请求，系统会返回原订单状态（不会创建重单）
- 缓存 Key 包含用户 ID，确保跨用户的相同 Key 不会冲突

### 4.4 银行渠道幂等性

对于通过经纪商发送的 FIX 订单，使用 FIX `ClOrdID` 作为交易所层的幂等 ID：
- `ClOrdID` = `{account_id}_{order_id}_{timestamp}`
- 交易所记录 `ClOrdID`，相同 `ClOrdID` 的重复请求自动去重

---

## 5. 用户可见状态与内部状态映射

Surface PRD 中用户界面展示的状态名称与后端内部状态的映射关系如下：

| 用户可见状态 | 内部状态（枚举） | 颜色 | 何时出现 |
|-------------|------------------|------|---------|
| 审核中 | RISK_APPROVED（processing） | 蓝色（加载动画） | 风控通过，但尚未 FIX 发送或未获交易所确认 |
| 等待开盘 | QUEUED | 蓝色（时钟图标） | 风控通过但市场未开 / 节假日 / 港股午休 / 熔断中 |
| 待成交 | OPEN | 蓝色 | 交易所确认接收，但未成交 |
| 部分成交 | PARTIAL_FILL | 橙色 | 部分成交，还有待成交部分 |
| 已成交 | FILLED | 绿色 | 全部成交 |
| 改单处理中 | AMENDING | 蓝色（加载动画） | 用户改单已发出，等待交易所应答 |
| 改单失败 | AMEND_REJECTED → OPEN/PARTIAL | 黄色（短暂提示）| 交易所拒绝改单；原订单状态保留，用户可重试或撤单 |
| 已撤销 | CANCELLED | 灰色 | 用户撤单成功（含 QUEUED 阶段主动撤销）|
| 部分成交后撤销 | CANCELLED（with `filled_qty > 0`） | 橙色 | 部分成交后用户撤单 |
| 已过期 | EXPIRED | 灰色 | DAY 或 GTC 单到期 |
| 已拒绝 | REJECTED / RISK_REJECTED | 红色 | 风控拒绝、QUEUED 复核失败或格式校验失败 |
| 交易所拒绝 | EXCHANGE_REJECTED | 红色 | 交易所拒绝订单 |

**注意**：`CREATED` 和 `VALIDATED` 状态用户不可见；只有 `PENDING/QUEUED` 以后的状态才会通过 WebSocket 推送给客户端。`AMEND_REJECTED` 是短暂中间态（< 1 秒），app 显示为黄色提示后立即回到原状态（OPEN 或 PARTIAL_FILL）。

---

## 6. 订单事件与审计追踪（SEC Rule 17a-4）

所有订单状态转换都必须生成**不可变的事件记录**，用于审计和 CAT 上报。

### 6.1 事件结构

```json
{
  "event_id": "evt-550e8400-e29b",
  "order_id": "ord-1234",
  "event_type": "ORDER_CREATED",
  "timestamp": "2026-03-30T09:30:00.123456Z",
  "actor_id": "user-5678",
  "actor_type": "CUSTOMER",
  "previous_state": null,
  "new_state": "CREATED",
  "details": {
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 100,
    "order_type": "LIMIT",
    "price": "150.00",
    "time_in_force": "DAY",
    "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
  },
  "ip_address": "192.168.1.1",
  "device_id": "device-abc123",
  "correlation_id": "req-xyz789"
}
```

### 6.2 必须记录的事件

| 事件类型 | 何时触发 | 强制性 |
|---------|---------|--------|
| ORDER_CREATED | 订单创建 | ✅ |
| ORDER_VALIDATED | 校验通过 | ✅ |
| ORDER_RISK_APPROVED | 风控通过 | ✅ |
| ORDER_RISK_REJECTED | 风控拒绝 | ✅ |
| ORDER_SENT_TO_EXCHANGE | FIX 发送 | ✅ |
| ORDER_ACCEPTED_BY_EXCHANGE | 交易所 NEW | ✅ |
| ORDER_PARTIALLY_FILLED | ExecutionReport PARTIAL_FILL | ✅ |
| ORDER_FILLED | ExecutionReport FILL | ✅ |
| ORDER_CANCELLED | 用户撤销 + EXCHANGE CANCELLED | ✅ |
| ORDER_EXPIRED | DAY/GTC 到期 | ✅ |
| ORDER_REJECTED | 交易所拒绝 | ✅ |

### 6.3 存储要求（WORM 合规）

- **表结构**：`order_events` append-only 表，禁止 UPDATE 或 DELETE
- **保留期**：最少 7 年（前 2 年热存储，后 5 年冷存储）
- **可追溯性**：系统需支持按 `order_id` 重建完整订单历史（Event Replay）
- **CAT 上报**：`timestamp` 需精确到纳秒；其他字段见 tech spec

---

## 7. 交易所回报处理（FIX ExecutionReport）

交易所通过 FIX 4.4 `ExecutionReport` 消息通知订单状态变化。系统需要：

1. **解析 ExecutionReport**：提取 `ExecType`、`OrdStatus`、`ExecQty`、`Price` 等关键字段
2. **去重处理**：按 FIX `ExecID` 去重，防止处理重复的交易所消息
3. **状态转换**：根据 ExecType 更新订单内部状态（见 §1 转换矩阵）
4. **持仓更新**：成交后触发 Position Engine 更新（见 05-position-pnl.md）
5. **事件发布**：发布 Kafka `order.executed` 事件供下游消费

---

## 8. 依赖与风险

| 项目 | 说明 |
|------|------|
| **FIX 协议实现** | 依赖 QuickFIX/Go 库；需完成对接 UAT 测试 |
| **GTC 90 天法律确认** | 待法务确认 GTC 上限是否符合 SEC/SFC 监管要求 |
| **用户状态映射** | 前端需要根据内部状态映射展示用户可见状态；建议在 API response 中同时返回内部状态和用户状态 |
| **Event Replay** | 审计和问题排查时需支持按 order_id 重建完整历史 |

---

## 9. REST API 响应定义

所有订单 API 端点的返回格式在本章定义。**所有金额字段使用 string decimal；所有时间戳使用 ISO 8601 UTC。**

### 9.1 POST /api/v1/orders — 201 Created

**请求**（必须包含完整安全头，见§3.1；安全协议详见 security-protocol.md）：
```json
{
  "symbol": "AAPL",
  "side": "BUY",
  "quantity": 100,
  "order_type": "LIMIT",
  "limit_price": "150.00",           // 限价单必填（string decimal）
  "time_in_force": "DAY",            // DAY | GTC
  "allow_premarket": false,          // 可选，默认 false
  "allow_postmarket": false          // 可选，默认 false
}
```

**响应 201 Created**：
```json
{
  "order_id": "ord-550e8400-e29b",       // 生成的订单 ID（UUID）
  "status": "PENDING",                    // 初始内部状态（见§1 转换矩阵）
  "symbol": "AAPL",
  "side": "BUY",
  "order_type": "LIMIT",
  "quantity": 100,
  "limit_price": "150.00",                // string decimal，仅限价单有
  "time_in_force": "DAY",
  "created_at": "2026-03-31T09:30:00.123Z",    // ISO 8601 UTC
  "expires_at": "2026-03-31T20:00:00Z",       // DAY 单收盘时间；GTC 单为 90 天后
  "allow_premarket": false,
  "allow_postmarket": false,
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"  // 原请求的幂等键（回显）
}
```

**失败响应**：见 error-responses.md

---

### 9.2 GET /api/v1/orders — 200 OK

列表查询，支持分页和过滤。

**请求查询参数**：
```
GET /api/v1/orders?status=FILLED&date_from=2026-03-25&date_to=2026-03-31&page=1&page_size=20
```

**响应 200 OK**：
```json
{
  "orders": [
    {
      "order_id": "ord-550e8400-e29b",
      "status": "FILLED",                    // 当前内部状态
      "display_status": "已成交",             // 用户可见状态（见§4 映射表）
      "symbol": "AAPL",
      "side": "BUY",
      "order_type": "LIMIT",
      "quantity": 100,
      "limit_price": "150.00",
      "time_in_force": "DAY",

      // 成交信息
      "filled_qty": 100,                     // 已成交数量
      "avg_fill_price": "150.1525",          // 加权平均成交价（string decimal）
      "remaining_qty": 0,                    // 待成交数量

      // 时间戳
      "created_at": "2026-03-31T09:30:00.123Z",
      "expires_at": "2026-03-31T20:00:00Z",
      "filled_at": "2026-03-31T09:35:45.456Z"   // 全部成交时间（仅 FILLED 状态有）
    }
  ],

  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_count": 47,
    "total_pages": 3
  }
}
```

---

### 9.3 GET /api/v1/orders/:id — 200 OK

订单详情，包含完整成交记录和费用明细。

**响应 200 OK**：
```json
{
  "order_id": "ord-550e8400-e29b",
  "status": "PARTIAL_FILL",
  "display_status": "部分成交",
  "symbol": "AAPL",
  "market": "US",                    // US | HK
  "side": "BUY",
  "order_type": "LIMIT",
  "quantity": 100,
  "limit_price": "150.00",
  "time_in_force": "DAY",
  "allow_premarket": false,
  "allow_postmarket": false,

  // 成交统计
  "filled_qty": 50,
  "avg_fill_price": "150.1200",
  "remaining_qty": 50,

  // 时间戳
  "created_at": "2026-03-31T09:30:00.123Z",
  "expires_at": "2026-03-31T20:00:00Z",
  "updated_at": "2026-03-31T09:45:00.789Z",

  // 成交明细（按成交时间排序）
  "fills": [
    {
      "fill_id": "fill-001",
      "fill_qty": 30,
      "fill_price": "150.1000",      // string decimal
      "fill_time": "2026-03-31T09:35:00.000Z",
      "venue": "NASDAQ",              // 成交交易所
      "execution_id": "exec-12345"    // 交易所的执行 ID（用于对账）
    },
    {
      "fill_id": "fill-002",
      "fill_qty": 20,
      "fill_price": "150.1400",
      "fill_time": "2026-03-31T09:40:00.000Z",
      "venue": "NYSE",
      "execution_id": "exec-12346"
    }
  ],

  // 费用明细
  "fees": {
    "commission": "0.00",            // string decimal
    "exchange_fee": "0.30",
    "sec_fee": "0.00",               // 美股卖出才有
    "finra_fee": "0.00",             // 美股卖出才有
    "total_fees": "0.30"
  },

  // 订单风险属性
  "risk_checks": {
    "account_status": "APPROVED",    // 账户状态检查结果
    "buying_power_check": "PASSED",  // 购买力检查（买入订单才有）
    "position_check": "PASSED",      // 持仓检查（卖出订单才有）
    "pdt_check": "NOT_APPLICABLE",   // PDT 检查
    "concentration_check": "WARNING" // 集中度检查：PASSED | WARNING
  }
}
```

---

### 9.4 DELETE /api/v1/orders/:id — 202 Accepted

撤单请求（异步处理）。

**响应 202 Accepted**：
```json
{
  "order_id": "ord-550e8400-e29b",
  "message": "撤单请求已提交，结果将通过 WebSocket order.updated 频道推送"
}
```

**说明**：
- 返回 202 表示请求已被系统接收，但撤单操作仍在处理中
- 移动端应通过 WebSocket `order.updated` 频道监听撤单结果
- 如果 10 秒内未收到 WebSocket 推送，移动端应主动 GET /orders/:id 查询最新状态

**失败响应**：见 error-responses.md（如订单已成交、已过期等）

---

### 9.5 WebSocket order.updated 消息

推送时机：订单任何状态变化时立即推送。

**消息格式**：
```json
{
  "channel": "order.updated",
  "data": {
    "order_id": "ord-550e8400-e29b",
    "status": "FILLED",                    // 新的内部状态
    "display_status": "已成交",             // 新的用户可见状态（见§4）
    "symbol": "AAPL",
    "side": "BUY",
    "filled_qty": 100,
    "avg_fill_price": "150.1525",          // 最新平均成交价
    "remaining_qty": 0,
    "updated_at": "2026-03-31T09:35:45.123Z",

    // 撤单特有字段（仅当 status=CANCELLED 时）
    "cancel_status": "SUCCESS",            // SUCCESS | FAILED
    "cancel_reason": "USER_REQUESTED",     // 撤销原因

    // 拒绝特有字段（status=REJECTED 或 RISK_REJECTED）
    "reject_reason": "INSUFFICIENT_BALANCE",  // 拒绝原因代码
    "reject_message": "可用资金不足"            // 拒绝原因说明
  }
}
```

### 9.6 POST /api/v1/orders/:id/amend — 202 Accepted（改单）

异步处理。客户端请求改单后，服务端立即返回 202，订单状态变为 `AMENDING`；交易所应答后通过 WebSocket 推送最终状态。

**Request**

```http
POST /api/v1/orders/ord-abc/amend
Headers:
  Authorization:      Bearer <jwt>
  Idempotency-Key:    <uuid_v4>
  X-Signature:        <hmac_sha256>
  X-Biometric-Token:  <bio_token>             # 必填（金额变更需重新生物认证）
  X-Bio-Challenge:    <challenge>
  X-Bio-Timestamp:    <unix_ms>
Body:
{
  "new_price":      "151.50",    // 可选（不修改时省略）
  "new_quantity":   80,           // 可选
  "new_stop_price": null,         // 可选
  "new_trail_amount": null,
  "new_time_in_force": null
}
```

**Response 202 Accepted**

```json
{
  "order_id":       "ord-abc",
  "new_cl_ord_id":  "CLI-1747246800000-002",
  "orig_cl_ord_id": "CLI-1747246800000-001",
  "status":         "AMENDING",
  "accepted_at":    "2026-05-14T14:30:00.123Z"
}
```

**错误响应**

| HTTP | 错误码 | 说明 |
|------|--------|------|
| 400 | AMEND_INVALID_FIELD | 修改了不可改字段（side, symbol, order_type）|
| 400 | AMEND_QTY_BELOW_FILLED | new_quantity < filled_qty |
| 400 | AMEND_PRICE_VIOLATION | 不符合 tick size / 超出 LULD band |
| 409 | AMEND_ORDER_NOT_AMENDABLE | 订单当前状态不允许改单（终态、QUEUED、AMENDING 等）|
| 409 | AMEND_IN_PROGRESS | 同一订单已有改单在途 |
| 403 | INSUFFICIENT_BUYING_POWER | 差额冻结失败 |
| 401 | INVALID_BIO_TOKEN | 生物认证失效 |

**WebSocket 后续推送**

```json
{
  "event": "order.amended",       // 或 "order.amend_rejected"
  "order_id": "ord-abc",
  "data": {
    "new_cl_ord_id":  "CLI-1747246800000-002",
    "orig_cl_ord_id": "CLI-1747246800000-001",
    "status":         "OPEN",
    "price":          "151.50",
    "quantity":       80,
    "amended_at":     "2026-05-14T14:30:01.456Z"
  }
}
```

`order.amend_rejected` 的 payload 额外包含 `reject_reason` 字段。

---

## 10. 与其他 Domain PRD 的关系

- **risk-rules.md**：定义 RISK_APPROVED → RISK_REJECTED 的风控检查规则
- **settlement.md**：FILLED 订单的后续结算流程（T+1/T+2）
- **position-pnl.md**：FILLED 订单对持仓和 P&L 的影响
- **type-definitions.md**：decimal、timestamp 的序列化规则
- **error-responses.md**：错误响应的标准格式
- **交易契约 (trading-to-mobile.md)**：API 应返回用户可见状态（display_status），而非内部状态（status）
