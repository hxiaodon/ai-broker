# PRD-04：交易模块

> **文档状态**: Phase 1 正式版
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据交易引擎工程师评审意见修订：新增市价单价格保护 Collar（3.7节）；补充 DAY 单精确过期时间规则（3.4节）；修正订单状态机（6.1节：增加 RISK_CHECKING→REJECTED 路径、EXCHANGE_REJECTED 状态、PENDING_SUBMIT 标注为客户端态）；新增 GTC 调度器规格（6.3节）；撤单接口改为 POST /cancel（10.4节）；费用字段精度升级为 NUMERIC(18,8)；新增 fee_rates 动态配置表；order_fills 增加 settlement_date；附录 A FIX ExecType 映射表

---

## 一、模块概述

### 1.1 功能范围

| 功能 | Phase 1 | Phase 2 |
|------|---------|---------|
| 市价单（Market Order） | ✅ | - |
| 限价单（Limit Order） | ✅ | - |
| 止损单（Stop Order） | ❌ | ✅ |
| 止损限价单（Stop-Limit） | ❌ | ✅ |
| 追踪止损（Trailing Stop） | ❌ | ✅ |
| DAY / GTC 有效期 | ✅ | - |
| IOC / FOK | ❌ | ✅ |
| 盘前/盘后交易 | ✅（仅限价单） | - |
| 委托修改 | ❌（仅撤单） | ✅ |
| 订单历史与导出 | ✅ | - |

### 1.2 权限前置条件

| 条件 | 说明 |
|------|------|
| KYC 状态 | `APPROVED`（Tier 1 或 Tier 2） |
| 账户类型 | 现金账户（Phase 1 仅此类型） |
| 最低买入金额 | 无（美股支持 1 股起买，Phase 1 不支持碎股） |

---

## 二、交易流程

### 2.1 主流程（买入 / 卖出）

```
进入股票详情页
    ↓
点击 [买入] 或 [卖出] 按钮
    ↓
交易委托页（填写委托参数）
    ↓
动态风险提示展示
    ↓
滑动确认（Slide-to-Confirm）
    ↓
弹出委托确认弹窗（最优执行披露 + Face ID 确认）
    ↓
生物识别验证（Face ID / 指纹）
    ↓
    [通过] → 提交至风控 → 送往交易所 → 委托成功 Toast → 跳转订单列表
    [失败] → 返回委托页，保留输入
```

### 2.2 盘前/盘后交易首次确认

```
用户首次进入盘前/盘后交易时段点击买卖按钮
    ↓
弹出风险确认弹窗（说明流动性风险、宽幅报价、仅限价单）
    ↓
用户勾选"我已了解风险"并确认
    ↓
后续同一 App 安装期间不再提示
```

---

## 三、委托页设计规格

### 3.1 页面头部

| 元素 | 说明 |
|------|------|
| 股票代码 + 名称 | 当前交易标的 |
| 实时价格 | 最新价，WebSocket 实时更新 |
| 涨跌幅 | 颜色随用户颜色设置 |
| 交易时段标识 | 常规 / 盘前 / 盘后 |
| 可用资金 | 现金账户买入方向：可用余额；卖出方向：可卖出股数 |

### 3.2 订单类型（Phase 1）

| 类型 | 显示名称 | 参数 |
|------|---------|------|
| 市价单 | 市价（Market） | 仅数量 |
| 限价单 | 限价（Limit） | 限价 + 数量 |

**市价单说明区**:
- 显示当前最优买/卖报价（Bid / Ask）
- 提示："以当前市场最优价格成交，实际成交价可能与当前显示价格不同"

**限价单价格输入**:
- 步进按钮（±$0.01）
- 数字键盘直接输入
- 参考 NBBO（National Best Bid and Offer）显示当前最优价
- 价格偏离警告：输入价格与当前价格偏离 > 5% 时显示黄色警告
- 最小报价单位：$0.0001（美股）

### 3.3 数量输入

| 元素 | 规格 |
|------|------|
| 数量输入框 | 正整数，最小 1 股 |
| 快速选择按钮 | 25股 / 50股 / 100股 / 最大 |
| "最大"计算逻辑（买入） | floor(可用资金 / 委托价格)，市价单用 ask 价估算 |
| "最大"计算逻辑（卖出） | 当前持有已结算股数（不含未结算） |
| 卖出时显示持仓摘要 | 持有股数 / 平均成本 / 市值 / 浮动盈亏 / 可卖（已结算）/ 未结算股数及预计结算日 |

### 3.4 有效期（Time-in-Force）

| TIF | 说明 | Phase 1 |
|-----|------|---------|
| DAY | 当日有效，收盘自动过期 | ✅ |
| GTC | 最多有效 90 天（到期通知用户） | ✅ |
| IOC | 立即成交否则撤销 | ❌ Phase 2 |
| FOK | 完全成交否则全部撤销 | ❌ Phase 2 |

**默认 TIF**：DAY（可在交易设置中修改默认值）

**DAY 单过期精确规则**：

| 交易时段 | 过期时间（ET） | 说明 |
|---------|--------------|------|
| 常规交易（Regular） | 16:00:00 | NYSE/NASDAQ 正常收盘 |
| 包含盘后（extended_hours=true） | 20:00:00 | 盘后交易截止 |
| 早收盘日（Early Close） | 13:00:00 | NYSE 发布的特殊交易日（如感恩节次日） |
| 交易暂停（Trading Halt）期间 | 暂停期间不过期，复牌后继续计算至当日截止时间 | |

- 过期逻辑由 GTC 调度器统一处理（见 6.3 节）
- 过期时，系统向交易所发出撤单指令，收到 ExecType=4（Cancelled）回报后更新状态为 EXPIRED
- 若交易所已成交但过期指令到达，以成交为准（ExecType=2 优先）

### 3.5 费用预估明细

| 费用项 | 买入显示 | 卖出显示 | 说明 |
|--------|---------|---------|------|
| 佣金 | $0.00 | $0.00 | 免佣 |
| 交易所费用 | ≈$0.30 | ≈$0.30 | Exchange Fee |
| SEC 费用 | — | ≈$X.XX | 仅卖出，0.0000278 × 成交金额 |
| FINRA TAF | — | ≈$0.XX | 仅卖出，$0.000166/股，最高$8.30 |
| 合计费用 | 显示 | 显示 | — |
| 委托金额 | 数量 × 价格（估算） | 数量 × 价格（估算） | — |
| 预计总金额 | 委托金额 + 费用 | 委托金额 − 费用 + 税 | — |

**P&L 预览（卖出专属）**:
```
预计盈亏：+$XXX.XX (+X.XX%)
= (预计卖出价 − 平均成本) × 数量 − 费用
```

### 3.6 动态风险提示

| 触发条件 | 提示内容 |
|---------|---------|
| 单只持仓占比 > 20% | "该股票持仓集中度较高，请注意分散投资风险" |
| 下单金额 > $10,000 | 弹出二次确认："大额委托确认，您正在下达超过 $10,000 的委托" |
| 限价与市价偏离 > 5% | "您的委托价格与当前市价偏离超过 5%，请确认" |
| 盘前/盘后下单 | "盘前/盘后交易流动性较低，可能无法成交或以不理想价格成交" |
| PDT 触发警告（Day Trade 第 4 次） | 见 PDT 章节 |

### 3.7 市价单价格保护（Price Protection Collar）

市价单在提交至交易所前，系统自动添加价格保护区间，防止在流动性差或行情剧烈波动时以极端价格成交。

| 交易时段 | Collar 范围 | 说明 |
|---------|------------|------|
| 常规交易（Regular Hours） | ±5% | 以提交时 NBBO 中间价为基准 |
| 盘前/盘后（Extended Hours） | ±3% | 流动性更差，保护范围更窄 |

**执行逻辑**：
```
买入市价单：实际上限价 = NBBO Ask × (1 + collar_pct)
卖出市价单：实际下限价 = NBBO Bid × (1 - collar_pct)

若价格触碰 Collar 边界，订单转为 LIMIT 单（以 Collar 价格提交）
若此价格仍无法成交，订单进入等待，直到收盘或用户主动撤单
```

**前端展示**：
- 委托确认弹窗中注明："市价单设有价格保护区间（±5%），超出范围将以保护价格委托"
- 实际成交后，成交详情页展示"保护价格"字段（若触碰 Collar）

**注**：Collar 功能为服务端逻辑，客户端仅做展示，不参与计算。

---

## 四、委托确认弹窗

### 4.1 内容布局

```
[委托摘要]
方向：买入 AAPL
类型：限价单
委托价：$182.52
数量：100 股
有效期：当日有效
委托金额：$18,252.00

[费用明细]
交易所费用：$0.30
合计：$18,252.30

[最优执行披露]
"您的订单将以最优价格路由至 NYSE、NASDAQ 等交易所，
 我们不接受 PFOF，执行质量报告每季度公示。"

[确认按钮] 🔐 Face ID 确认
```

### 4.2 确认方式

| 场景 | 确认方式 |
|------|---------|
| 默认 | 滑动解锁 + 生物识别 |
| 生物识别不可用 | 仅滑动解锁 |
| 用户在交易设置关闭生物识别确认 | 仅滑动解锁 |
| 限价单（用户设置 "限价免生物识别"） | 仅滑动 |

---

## 五、PDT（Pattern Day Trader）规则

### 5.1 规则定义

| 规则 | 说明 |
|------|------|
| PDT 定义 | 5 个交易日内在保证金账户完成 4 次或以上 Day Trade |
| Phase 1 | 现金账户不受 PDT 限制（Phase 1 仅现金账户） |
| Phase 2 | 融资账户需追踪 Day Trade 计数，余额 < $25K 时触发限制 |
| 前端 | PDT 教育页面（设置 → 交易 → PDT 规则说明），无切换开关 |

**重要决策**（参考 pm-decision-response.md CRITICAL-1）:
- PDT 是 FINRA 强制要求，**不提供绕过选项**
- 交易引擎层硬性拦截（Phase 2 融资账户时）
- Phase 1 现金账户不受约束，但应向用户展示 PDT 教育内容

---

## 六、订单状态机

### 6.1 状态定义

```
PENDING_SUBMIT     [仅客户端态，不持久化到服务端]
                   (前端已发送，等待服务端 HTTP 响应)
    ↓ HTTP 200
RISK_CHECKING      (服务端收单，风控预检中)
    ↓ [通过]            ↓ [拒绝]
SUBMITTED          REJECTED（风控拒绝，终态）
    ↓
PENDING_FILL       (已送至交易所，挂单中，等待成交)
    ↓ [部分成交]         ↓ [全部成交]        ↓ [撤单]
PARTIAL_FILL       FILLED（终态）            CANCELLED（终态）
    ↓ [全部成交]         ↓ [撤单]
    FILLED（终态）       CANCELLED_PARTIAL（终态，部分成交后撤单）
                         EXPIRED（终态，超时过期：GTC 90天 / DAY 收盘）
                         EXCHANGE_REJECTED（终态，交易所拒绝，详见附录A FIX ExecType）
```

**状态说明**：

| 状态 | 是否持久化 | 描述 |
|------|---------|------|
| PENDING_SUBMIT | ❌ 仅客户端 | Flutter 本地 UI 状态，HTTP 响应后即替换 |
| RISK_CHECKING | ✅ | 服务端风控处理中，通常 < 100ms |
| SUBMITTED | ✅ | 已通过风控，发送至经纪商/交易所 |
| PENDING_FILL | ✅ | 交易所已确认接受，等待成交 |
| PARTIAL_FILL | ✅ | 部分数量已成交 |
| FILLED | ✅ 终态 | 全部成交 |
| CANCELLED | ✅ 终态 | 用户主动撤单，交易所确认 |
| CANCELLED_PARTIAL | ✅ 终态 | 部分成交后用户撤单 |
| EXPIRED | ✅ 终态 | DAY 单收盘过期 / GTC 达 90 天 |
| REJECTED | ✅ 终态 | 风控拒绝（含资金不足、PDT 等） |
| EXCHANGE_REJECTED | ✅ 终态 | 交易所拒绝（FIX ExecType=8，见附录 A） |

### 6.2 状态对应 UI

| 状态 | 徽标颜色 | 文字 |
|------|---------|------|
| RISK_CHECKING | 蓝色（动画） | 风控中 |
| PENDING_FILL | 蓝色 | 待成交 |
| PARTIAL_FILL | 黄色 | 部分成交 |
| FILLED | 绿色 | 已成交 |
| CANCELLED | 灰色 | 已撤销 |
| CANCELLED_PARTIAL | 橙色 | 部分成交后撤销 |
| EXPIRED | 灰色 | 已过期 |
| REJECTED | 红色 | 已拒绝 |
| EXCHANGE_REJECTED | 红色 | 交易所拒绝 |

### 6.3 GTC 调度器 / DAY 单过期调度器

**服务**: `order-expiry-scheduler`（独立 Go goroutine，每分钟扫描）

```
调度逻辑（伪代码）：

每分钟执行：
  1. 查询当日 DAY 单过期时间（NYSE/NASDAQ 收盘时间，含早收盘日）
  2. SELECT * FROM orders
       WHERE status IN ('PENDING_FILL', 'PARTIAL_FILL')
         AND time_in_force = 'DAY'
         AND expires_at <= NOW()
         AND expires_at > NOW() - INTERVAL '5 minutes'  // 避免重复处理
     FOR UPDATE SKIP LOCKED;
  3. 对每个订单：发送 FIX OrderCancelRequest → 等待 ExecType=4 回报 → 更新 EXPIRED
  4. GTC 90 天到期：同逻辑，提前 3 天/1 天发送推送通知（见 PRD-07 通知模块）

并发保护：
  - FOR UPDATE SKIP LOCKED 防止多实例重复处理
  - 发送 FIX 请求前设置 processing_at 时间戳（乐观锁）
  - 若 ExecType 回报未在 30s 内收到，进入 PENDING_CANCEL 中间态（Phase 2）

推送通知（GTC 即将到期）：
  - 到期前 3 天：推送"您的 GTC 委托将在 3 天后过期"
  - 到期前 1 天：推送"您的 GTC 委托将在明天过期"
  - 已过期：推送"您的 GTC 委托已过期"
```

---

## 七、订单管理页

### 7.1 订单列表

**Tab 分类**:
- 全部 / 待成交 / 已成交 / 已撤销 / 已过期

**列表卡片字段**:
- 股票代码 + 方向（买/卖）+ 订单类型
- 委托价格 / 委托数量
- 已成交数量 / 未成交数量
- 订单号（短号，12 位）
- 委托时间
- 撤单按钮（仅 PENDING_FILL / PARTIAL_FILL 状态）

### 7.2 订单详情（底部抽屉）

```
[状态标题区]
方向 + 代码 + 状态 Badge

[订单信息]
委托类型 / 委托价 / 委托数量 / 已成交 / 均价 / 剩余 / 有效期

[成交明细]（有成交时）
成交时间 / 成交数量 / 成交价 / 成交金额 / 成交所 / 执行 ID

[费用明细]
逐笔费用 + 合计

[状态时间轴]
节点1：委托创建 2026-03-13 09:30:00.123
节点2：风控通过 2026-03-13 09:30:00.456
节点3：已送往交易所 2026-03-13 09:30:00.789
节点4：确认接受 2026-03-13 09:30:01.012
节点5：已成交 / 已撤销 / 已过期

[操作区域]
[撤单] 按钮（状态允许时显示）
```

### 7.3 撤单流程

```
点击 [撤单] → 弹出确认弹窗
    ↓
弹窗内容：
  - 原委托摘要（代码、方向、委托价、委托数量）
  - 已成交数量（部分成交情况）
  - 待撤销数量
  - "注意：撤单不保证成功，若订单已成交撤单请求将被拒绝"
    ↓
[确认撤单] / [取消]
    ↓
服务端处理：
  [撤单成功] → Toast 提示"撤单请求已提交" → 订单状态更新
  [撤单失败-已成交] → Toast "该委托已成交，无法撤单" → 刷新订单
  [撤单失败-网络] → Toast "撤单请求失败，请重试"
```

### 7.4 交易历史（成交记录）

- 时间过滤：今天 / 本周 / 本月 / 自定义
- 市场过滤：全部 / 美股
- 按日期分组，每组显示当日交易摘要
- 每条成交记录：代码、方向、数量 × 价格 = 金额、费用、时间、交易所
- 导出：CSV（Phase 1），PDF（Phase 2）

---

## 八、交易设置

| 设置项 | 选项 | 默认 |
|--------|------|------|
| 默认订单类型 | 市价单 / 限价单 | 限价单 |
| 默认有效期 | DAY / GTC | DAY |
| 确认方式 | 滑动+生物识别 / 仅滑动 / 限价单免确认 | 滑动+生物识别 |
| 大额委托阈值 | $5,000 / $10,000 / $20,000 | $10,000 |
| 盘前/盘后交易 | 开启 / 关闭 | 关闭（首次需确认风险） |
| 价格偏离警告阈值 | 3% / 5% / 10% | 5% |

---

## 九、错误处理

| 错误类型 | 错误码 | 用户提示 | 操作 |
|---------|--------|---------|------|
| 资金不足 | ERR_INSUFFICIENT_FUNDS | "可用资金不足，当前可用 $X.XX" | 显示充值入口 |
| 持仓不足（卖出） | ERR_INSUFFICIENT_POSITION | "持仓不足，当前可卖出 X 股（已结算）" | 无 |
| 市场休市 | ERR_MARKET_CLOSED | "当前市场已休市，可预设次日限价委托" | 提示开市时间 |
| 交易暂停（股票） | ERR_TRADING_HALTED | "该股票交易暂时中止，请稍后再试" | 设置恢复提醒 |
| PDT 拦截（Phase 2） | ERR_PDT_RESTRICTED | "您已触发 PDT 规则，账户权益需维持在 $25,000 以上" | 跳转 PDT 教育页 |
| 风控拦截 | ERR_RISK_REJECTED | "委托被风控拒绝，请联系客服" | 客服入口 |
| 网络超时 | ERR_NETWORK_TIMEOUT | "网络连接超时，请检查您的网络后在订单列表确认委托状态" | 跳转订单列表 |
| 交易所拒绝 | ERR_EXCHANGE_REJECTED | "委托被交易所拒绝：{原因}" | 无 |

---

## 十、后端接口规格

### 10.1 提交委托

```
POST /v1/orders
Headers:
  Authorization: Bearer {token}
  Idempotency-Key: {uuid}
Request:
  {
    "symbol": "AAPL",
    "market": "US",
    "side": "BUY" | "SELL",
    "order_type": "MARKET" | "LIMIT",
    "quantity": 100,
    "limit_price": "182.52",          // 限价单必填
    "time_in_force": "DAY" | "GTC",
    "extended_hours": false,           // 是否允许盘前盘后
    "device_id": "device-uuid",
    "biometric_signature": "..."       // 生物识别签名（可选）
  }
Response:
  {
    "order_id": "ord-xxxxxxxx",
    "client_order_id": "uuid",         // 等同 Idempotency-Key
    "status": "SUBMITTED",
    "created_at": "2026-03-13T09:30:00.000Z"
  }
```

**幂等性规则**：相同 `Idempotency-Key` 的请求，72 小时内返回第一次响应。

### 10.2 查询订单列表

```
GET /v1/orders?status=PENDING_FILL&page=1&page_size=20
Response:
  {
    "orders": [...],
    "total": 150,
    "page": 1
  }
```

### 10.3 查询订单详情

```
GET /v1/orders/{order_id}
Response: 订单完整详情（含成交明细、状态时间轴）
```

### 10.4 撤单

```
POST /v1/orders/{order_id}/cancel
Headers:
  Authorization: Bearer {token}
  Idempotency-Key: {uuid}
Body: {}   // 无需请求体，预留用于 Phase 2 部分撤单

Response 200:
  {
    "order_id": "ord-xxxxxxxx",
    "cancel_status": "CANCEL_REQUESTED" | "CANCELLED" | "FAILED_ALREADY_FILLED"
  }

注：使用 POST /cancel 而非 DELETE，原因：
  1. 撤单是业务操作（带 Idempotency-Key），非幂等的 HTTP DELETE 语义
  2. 可在 Body 中携带参数（如 Phase 2 的部分撤单数量）
  3. API Gateway 和防火墙对 DELETE with body 支持不一致
```

### 10.5 预估费用

```
POST /v1/orders/estimate
Request: 同提交委托（不实际提交）
Response:
  {
    "estimated_commission": "0.00",
    "estimated_exchange_fee": "0.30",
    "estimated_sec_fee": "0.00",       // 买入为 0
    "estimated_finra_taf": "0.00",     // 买入为 0
    "total_estimated_fee": "0.30",
    "estimated_total_amount": "18252.30"
  }
```

---

## 十一、数据模型

```sql
-- 订单主表
CREATE TABLE orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    client_order_id     UUID UNIQUE NOT NULL,      -- 幂等键（等同 Idempotency-Key）
    symbol              VARCHAR(10) NOT NULL,
    market              VARCHAR(5) NOT NULL DEFAULT 'US',
    side                VARCHAR(4) NOT NULL,        -- 'BUY', 'SELL'
    order_type          VARCHAR(20) NOT NULL,       -- 'MARKET', 'LIMIT'
    quantity            NUMERIC(18,6) NOT NULL,
    limit_price         NUMERIC(18,4),
    time_in_force       VARCHAR(5) NOT NULL,        -- 'DAY', 'GTC'
    extended_hours      BOOLEAN DEFAULT false,
    status              VARCHAR(30) NOT NULL DEFAULT 'RISK_CHECKING',
                        -- 注：PENDING_SUBMIT 为客户端态，不写入 DB
    filled_quantity     NUMERIC(18,6) DEFAULT 0,
    avg_fill_price      NUMERIC(18,4),
    commission          NUMERIC(18,8) DEFAULT 0,   -- 精度升级至 8 位（SEC/FINRA 费率需要）
    exchange_fee        NUMERIC(18,8) DEFAULT 0,
    sec_fee             NUMERIC(18,8) DEFAULT 0,   -- 费率：0.0000278 × 成交金额
    finra_taf           NUMERIC(18,8) DEFAULT 0,   -- 费率：$0.000166/股，max $8.30
    collar_price        NUMERIC(18,4),              -- 市价单触碰 Collar 时的保护价格
    broker_order_id     VARCHAR(100),               -- 经纪商/交易所分配的 ID
    fix_exec_type       VARCHAR(5),                 -- 最后一次 FIX ExecType 值，用于调试
    reject_reason       TEXT,
    expires_at          TIMESTAMPTZ,               -- DAY: 收盘时间, GTC: created_at+90d
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_status ON orders (user_id, status);
CREATE INDEX idx_orders_expiry ON orders (expires_at)
    WHERE status IN ('PENDING_FILL', 'PARTIAL_FILL');  -- 过期调度器专用

-- 成交明细表
CREATE TABLE order_fills (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID NOT NULL REFERENCES orders(id),
    fill_quantity   NUMERIC(18,6) NOT NULL,
    fill_price      NUMERIC(18,4) NOT NULL,
    fill_amount     NUMERIC(18,4) NOT NULL,         -- fill_quantity × fill_price
    commission      NUMERIC(18,8) NOT NULL DEFAULT 0,
    sec_fee         NUMERIC(18,8) NOT NULL DEFAULT 0,
    finra_taf       NUMERIC(18,8) NOT NULL DEFAULT 0,
    exchange        VARCHAR(20),                    -- 成交所（NYSE/NASDAQ/ARCA等）
    execution_id    VARCHAR(100) UNIQUE,            -- FIX ExecID，幂等键
    settlement_date DATE NOT NULL,                  -- T+1（US），用于可提现余额计算
    filled_at       TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fills_order ON order_fills (order_id);
CREATE INDEX idx_fills_settlement ON order_fills (settlement_date)
    WHERE settlement_date > CURRENT_DATE;           -- 查询待结算数据

-- 订单状态变更历史（只追加，不更新不删除）
CREATE TABLE order_status_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID NOT NULL REFERENCES orders(id),
    old_status  VARCHAR(30),
    new_status  VARCHAR(30) NOT NULL,
    reason      TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 费率动态配置表（避免硬编码费率）
CREATE TABLE fee_rates (
    id          SERIAL PRIMARY KEY,
    fee_type    VARCHAR(30) NOT NULL,   -- 'SEC_FEE', 'FINRA_TAF', 'EXCHANGE_FEE'
    market      VARCHAR(5) NOT NULL DEFAULT 'US',
    rate        NUMERIC(18,10) NOT NULL, -- 费率本身（如 SEC: 0.0000278）
    max_amount  NUMERIC(18,4),          -- 单笔上限（如 FINRA TAF: 8.30）
    min_amount  NUMERIC(18,4),          -- 单笔下限（如 0.01）
    effective_from  DATE NOT NULL,
    effective_to    DATE,               -- NULL 表示当前有效
    CONSTRAINT uq_fee_rate_active UNIQUE (fee_type, market, effective_from)
);

-- 初始数据（费率以实际监管公告为准，需定期更新）
INSERT INTO fee_rates (fee_type, market, rate, max_amount, effective_from) VALUES
  ('SEC_FEE',    'US', 0.0000278, NULL, '2024-01-01'),
  ('FINRA_TAF',  'US', 0.000166,  8.30, '2024-01-01'),
  ('EXCHANGE_FEE','US', 0.003,    NULL, '2024-01-01');
-- 注：Exchange Fee 以实际执行交易所 Schedule 为准，此处为估算默认值
```

---

## 十二、验收标准

| 场景 | 标准 |
|------|------|
| 委托提交延迟 | P99 < 1 秒（下单到订单状态 SUBMITTED） |
| 幂等性 | 重复提交同一 Idempotency-Key 不产生双单 |
| 滑动确认 | 滑动距离 > 80% 才触发提交，防误触 |
| 生物识别确认 | Face ID 验证失败 3 次后降级至滑动确认 |
| 大额委托 | > $10K 必须弹出二次确认，不可关闭 |
| 撤单结果 | 撤单后 3 秒内刷新订单状态 |
| 网络断开 | 断网后不自动重试委托，提示用户确认 |
| 市价单 Collar | 常规时段 ±5%、盘前盘后 ±3%，触碰时自动转限价 |
| DAY 单过期 | 16:00 ET（早收盘日 13:00）精准触发，误差 < 60s |
| GTC 到期通知 | 到期前 3 天和 1 天均有推送通知 |
| 状态机完整性 | EXCHANGE_REJECTED 正确显示为红色"交易所拒绝" |

---

## 附录 A：FIX ExecType 映射表

本附录定义 FIX 4.2/4.4 协议的 ExecType（tag 150）值与系统内部订单状态的映射关系。

| FIX ExecType | 值 | 系统内部状态变更 | 说明 |
|-------------|---|--------------|------|
| New | 0 | SUBMITTED → PENDING_FILL | 交易所确认接受订单 |
| Partial Fill | 1 | → PARTIAL_FILL | 部分成交，触发 order_fills 记录 |
| Fill | 2 | → FILLED | 全部成交，终态 |
| Done For Day | 3 | → EXPIRED | DAY 单当日结束，未成交部分作废 |
| Cancelled | 4 | → CANCELLED 或 EXPIRED | 撤单成功；调度器触发的过期也收此回报 |
| Replace | 5 | 暂不支持（Phase 2 委托修改） | 收到则记录告警，不改状态 |
| Pending Cancel | 6 | 记录 fix_exec_type，不改状态 | 交易所处理撤单中 |
| Stopped | 7 | → PENDING_FILL（保持） | 特殊执行情况，等待后续回报 |
| Rejected | 8 | → EXCHANGE_REJECTED | 交易所拒绝，reject_reason 记录 Text(58) |
| Suspended | 9 | → PENDING_FILL（保持） | 订单暂停，等待恢复 |
| Pending New | A | → RISK_CHECKING（保持） | 交易所确认收到，待处理 |
| Expired | C | → EXPIRED | GTC 到达交易所设定的到期日 |

**注意**：
- ExecType=C（Expired）与 ExecType=4（Cancelled）均映射至 EXPIRED 状态，区别在于触发方（交易所 vs 系统调度）
- 所有 ExecType 值均记录到 `orders.fix_exec_type` 和 `order_status_log` 中供调试
- 未知 ExecType 值：记录告警日志，不改变订单状态，人工介入
