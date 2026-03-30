---
name: settlement
description: T+1 (US) / T+2 (HK) 结算周期、未结算资金冻结、结算流程
type: domain-prd
surface_prd: mobile/docs/prd/06-portfolio.md (§六.2 已结算 vs 未结算、§七 合规)
version: 1
status: DRAFT
created: 2026-03-30T00:00+08:00
last_updated: 2026-03-30T00:00+08:00
revisions:
  - rev: 1
    date: 2026-03-30T00:00+08:00
    author: trading-engineer
    summary: "初始版本：从 Surface PRD 提取 T+1/T+2 结算规则、未结算冻结逻辑"
---

# 结算流程 (Settlement) — Domain PRD

> **对应 Surface PRD**：`mobile/docs/prd/06-portfolio.md` §六.2（已结算 vs 未结算）
> **依赖 Spec**：`services/trading-engine/docs/specs/domains/07-settlement.md`
> **相关规定**：SEC T+1 Settlement Cycle (2024-05)、HKEX T+2 Settlement

---

## 1. 结算制度概览

美国和香港股票市场使用不同的结算周期：

| 市场 | 结算周期 | 何时完成 | 说明 |
|------|---------|---------|------|
| 美股（NYSE/NASDAQ） | T+1 | 成交当日 + 1 个工作日 | SEC 规定，从 2024-05-28 起执行 |
| 港股（HKEX） | T+2 | 成交当日 + 2 个工作日 | HKEX 标准结算周期 |

**T 的定义**：`T = trade_date`（成交日期）

### 1.1 美股 T+1 结算举例

```
Mon 2026-03-30（T）：用户买入 100 股 AAPL @ $150.00
  → 成交，金额 $15,000
  → 未结算数量 = 100 股

Tue 2026-03-31（T+1）：交割完成
  → 资金从经纪商账户转入投资者账户
  → 已结算数量 = 100 股
  → 可以卖出这 100 股

Mon 2026-03-30（T）：用户卖出 50 股 AAPL @ $155.00
  → 成交，收入 $7,750
  → 金额处于未结算状态

Tue 2026-03-31（T+1）：交割完成
  → $7,750 现金结算到账
  → 可以出金或用于购买
```

### 1.2 港股 T+2 结算举例

```
Mon 2026-03-30（T）：用户买入 100 股 0700 @ HK$350.00
  → 成交，金额 HK$35,000
  → 未结算数量 = 100 股

Wed 2026-04-01（T+2）：交割完成
  → 已结算数量 = 100 股
  → 可以卖出
```

---

## 2. 未结算数量与持仓状态

### 2.1 持仓二分法

每只证券的持仓分为**已结算**和**未结算**两个部分：

```
持仓总数 = settled_qty + unsettled_qty
```

| 分类 | 定义 | 对交易的影响 | 对出金的影响 |
|------|------|------------|-----------|
| **已结算股数** (`settled_qty`) | T+1/T+2 后，资金或证券已交割完成 | ✅ 可自由卖出 | ✅ 卖出所得可出金 |
| **未结算股数** (`unsettled_qty`) | 买入的股票或卖出资金尚未交割 | ❌ 不可卖出 | ❌ 金额不可出金 |

### 2.2 前端展示（卖出下单页）

当用户点击"卖出"时，下单页必须展示：

```
持有：150 股
可卖出：100 股（已结算）
未结算：50 股（预计 2026-03-31 结算后可卖）
```

### 2.3 实现约束

- 下单时必须检查：`requested_qty <= settled_qty`，否则拒绝
- 未结算的股票即使已购买，也不能参与卖出、转账等操作
- 持仓表中需要同时记录 `settled_qty` 和 `unsettled_qty`；计算 `quantity = settled_qty + unsettled_qty`

---

## 3. 防止 Free-Riding Violation（自由骑行）

### 3.1 问题定义

```
自由骑行（Free-riding）= 用户卖出未结算的股票所得资金，
                       立即用于购买新股票，
                       然后在原买入订单结算前卖出新股票
```

**例子**：
```
Day 1: 买入 100 股 AAPL（未结算）
Day 1: 卖出 100 股 AAPL（用卖出资金买入 100 股 MSFT）
Day 2: AAPL 成交结算，但 MSFT 在 Day 3 卖出
      → 违反 Free-Riding Rule
```

### 3.2 规则

```
现金账户（Phase 1）：
  用户卖出未结算的股票所得资金，
  不能立即用于购买新股票；
  必须等待原买入订单结算后（T+1 日后）才能使用
```

**实现**：
- 销售所得资金标记为"未结算"，冻结 T+1 天
- 下单时检查：购买力 = settled_cash，不包括未结算的销售资金

### 3.3 违规处理

```
如果检测到 Free-Riding Violation：
  1. FINRA 可冻结账户 90 天（restricted account）
  2. 冻结期内仅允许现金交易（no margin）
  3. 新买入的股票必须在卖出前完全结算
```

---

## 4. 结算处理流程（后端）

### 4.1 Scheduler 定时检查

```
每天 22:00 UTC（交易所关闭 6 小时后）：
  1. 查询所有 `unsettled_qty > 0` 的持仓
  2. 检查成交日期：如果 trade_date + settlement_days <= today，标记为已结算
  3. 更新 settled_qty，清零 unsettled_qty（或转移到 settled）
  4. 发布 Kafka 事件：`settlement.completed`
  5. 发送用户推送通知："您的 AAPL 已结算，现在可以卖出"
```

### 4.2 持仓表结构

```sql
CREATE TABLE positions (
  id BIGINT PRIMARY KEY,
  account_id BIGINT,
  symbol VARCHAR(10),
  market ENUM('US', 'HK'),

  settled_qty INT,              -- 已结算数量
  unsettled_qty INT,            -- 未结算数量
  unsettled_trade_date DATE,    -- 最新未结算交易日期

  settled_cost_basis DECIMAL(19, 4),  -- 已结算成本基础（总）
  avg_cost DECIMAL(10, 4),            -- 平均成本价

  created_at TIMESTAMP,
  updated_at TIMESTAMP,

  UNIQUE KEY (account_id, symbol, market)
);
```

### 4.3 成交记录表

```sql
CREATE TABLE executions (
  id BIGINT PRIMARY KEY,
  order_id BIGINT,
  account_id BIGINT,
  symbol VARCHAR(10),
  market ENUM('US', 'HK'),

  side ENUM('BUY', 'SELL'),
  executed_qty INT,
  executed_price DECIMAL(10, 4),
  executed_at TIMESTAMP,

  trade_date DATE,              -- 成交日期（T）
  settlement_date DATE,         -- 结算预期日期（T+1 or T+2）
  is_settled BOOLEAN DEFAULT FALSE,

  settled_at TIMESTAMP,         -- 实际结算时刻

  created_at TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id)
);
```

---

## 5. 交易时段与结算日期

### 5.1 美股

**正常交易日**：周一至周五（NYT）

```
Mon: 成交 → Tue 结算
Tue: 成交 → Wed 结算
Wed: 成交 → Thu 结算
Thu: 成交 → Fri 结算
Fri: 成交 → Mon 结算（跨越周末）
```

**公共假日**：
```
如果结算日（T+1）是假日，顺延至下一个交易日

示例：
Memorial Day (US 假期，通常 5 月最后一个周一)
Fri 2026-05-22: 成交 → Mon 2026-05-25 是假日 → Tue 2026-05-26 结算
```

**支持的假日列表**：需要维护交易所公布的年度假日表

### 5.2 港股

```
Mon: 成交 → Wed 结算
Tue: 成交 → Thu 结算
Wed: 成交 → Fri 结算
Thu: 成交 → Mon 结算（跨越周末）
Fri: 成交 → Tue 结算（跨越周末）
```

**港股假日**（按 HKEX 公布）：
```
如果结算日（T+2）是假日，顺延至下一个交易日
```

---

## 6. 特殊场景处理

### 6.1 股权分配（Dividend）

```
如果在未结算期间发生分红：
  → 分红所得资金同样标记为未结算
  → 结算日期 = max(原持仓结算日, 分红结算日)
```

### 6.2 股票拆分（Stock Split）

```
如果在未结算期间发生拆分：
  → 未结算数量同步调整
  → 均价同步调整
  → 结算日期不变
```

### 6.3 公司行动（Corporate Action）

**Phase 1 人工处理方案：**

仅支持常见的现金分红、股票分红和拆分事件。处理流程如下：

1. **Compliance 监控** — 监控交易所公司行动公告
2. **事件识别** — 识别影响用户持仓的事件（如 AAPL 3:1 拆分）
3. **PM 审核** — PM 评估和确认调整方案
4. **后台触发** — 通过 Admin Panel 手动触发调整：
   - 更新 positions 表的 qty 和 avg_cost
   - 记录 position_adjustments 审计日志（含调整原因、执行人、时间）
5. **用户通知** — 推送通知："AAPL 发生 3:1 拆分，您的持仓已自动调整"
6. **Compliance 确认** — 确保调整正确无误

**Phase 1 支持的公司行动清单：**
- ✅ 现金分红（Cash Dividend）
- ✅ 股票分红（Stock Dividend）
- ✅ 股票拆分（Stock Split）
- ❌ 反向拆分（Reverse Split）— Phase 2
- ❌ 配股（Rights Offering）— Phase 2
- ❌ 并购（Merger）— Phase 2

**Phase 2 自动化方案：**

详见 position-pnl.md §3.3 中的 Phase 2 自动化规划。

---

## 7. 出金与结算的关系

### 7.1 可提取余额计算

```
withdrawable_cash = settled_cash - margin_requirement - pending_withdrawals
```

**约束**：
- 仅已结算的现金可以出金
- 未结算的销售资金冻结，不可出金
- 如果账户在融资状态，需扣除保证金要求

### 7.2 出金前结算检查

```
当用户发起出金请求时：
  1. 检查 withdrawable_cash >= withdrawal_amount
  2. 如果不足，返回错误："可用余额不足，尚有 $X 未结算"
  3. 如果充足，发起出金流程（见 fund-transfer 服务）
```

---

## 8. 与其他 Domain PRD 的关系

- **order-lifecycle.md**：成交（FILLED 状态）后触发结算流程
- **position-pnl.md**：已结算数量影响可卖数量；未结算影响 P&L 展示
- **risk-rules.md**：未结算资金冻结影响购买力计算
- **mobile/docs/prd/06-portfolio.md**：前端展示"已结算"vs"未结算"分类
- **fund-transfer 服务**：出金时需查询已结算余额
