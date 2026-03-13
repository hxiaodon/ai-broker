# PRD-06：持仓与组合模块

> **文档状态**: Phase 1 正式版
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据交易引擎工程师评审意见修订：positions 表增加 version 乐观锁字段；realized_pnl 增加 wash_sale_flag；数据类型 TIMESTAMP WITH TIME ZONE 统一为 TIMESTAMPTZ 缩写

---

## 一、模块概述

### 1.1 功能范围

| 功能 | Phase 1 | Phase 2 |
|------|---------|---------|
| 总资产概览 | ✅ | - |
| 持仓列表（美股） | ✅ | - |
| 持仓列表（港股） | ❌ | ✅ |
| 浮动盈亏（未实现 P&L） | ✅ | - |
| 已实现盈亏 | ✅（交易历史页） | - |
| 资产分析（板块分布/盈亏排名）| ✅ 基础版 | 增强版 |
| 双货币显示 | USD 为主（Phase 2 追加 HKD） | ✅ |
| 持仓告警（集中度预警） | ✅ | - |
| 股票组合报告 | ❌ | ✅ |

---

## 二、持仓页结构

### 2.1 资产总览卡片（顶部英雄区）

```
总资产：$XX,XXX.XX USD
今日盈亏：+$XXX.XX (+X.XX%) ←绿色或红色

可用现金：$X,XXX.XX
持仓市值：$XX,XXX.XX
未结算资金：$XXX.XX  [?]
冻结资金：$0.00

[入金快捷按钮] [出金快捷按钮]
```

**字段说明**:

| 字段 | 定义 |
|------|------|
| 总资产 | 可用现金 + 持仓市值 + 未结算资金 |
| 今日盈亏 | (所有持仓今日涨跌) + 今日已实现盈亏 |
| 可用现金 | 可提现 + 可用于买入（同一数值） |
| 持仓市值 | 所有持仓按最新价计算的市场价值 |
| 未结算资金 | T+1 日结算前的卖出所得 |
| 冻结资金 | 已提交委托占用的资金（委托未成交期间）|

**未结算资金 `[?]` 展开说明**:
```
美股实行 T+1 结算制度，您卖出股票所得的资金
将在下一个工作日完成结算后才可提现。
```

### 2.2 Tab 切换

| Tab | 内容 |
|-----|------|
| 持仓 | 当前持仓列表 |
| 分析 | 资产分析（板块分布 + P&L 排名） |

---

## 三、持仓列表

### 3.1 持仓卡片字段

| 字段 | 说明 | 格式 |
|------|------|------|
| 股票代码 | AAPL | 大写 |
| 公司简称 | 苹果公司 | 中文 |
| 持有股数 | 100 股 | 整数 |
| 平均成本 | $182.00 | 4 位小数 |
| 当前价格 | $185.00 | 实时，4 位小数 |
| 持仓市值 | $18,500.00 | 2 位小数 |
| 浮动盈亏（$） | +$300.00 | 颜色区分 |
| 浮动盈亏（%） | +1.65% | 颜色区分 |
| 方向箭头 | ↑ / ↓ | 随涨跌方向 |
| 快捷操作 | [买入] [卖出] | 绿/红 |

### 3.2 平均成本计算方法

使用**加权平均成本（VWAP-style）**:

```
新平均成本 = (原持仓 × 原均价 + 新买入数量 × 成交价) / 新总持仓数量
```

示例：
```
已持 100 股 @ $180.00
再买 50 股 @ $190.00
新均价 = (100 × 180 + 50 × 190) / 150 = $183.33
```

### 3.3 已结算 vs 未结算股数

卖出时需区分：
- **可卖出（已结算）**：可立即委托卖出
- **未结算股数 + 预计结算日**：买入后 T+1 前不可卖出（美股）

在卖出委托页显示：
```
持有：150 股
可卖出：100 股（已结算）
未结算：50 股（预计 2026-03-14 结算）
```

### 3.4 持仓为空状态

```
[空状态图示]
您还没有持仓
资金已入账？立即开始投资

[热门股票推荐]  AAPL · TSLA · NVDA ···

[立即入金] 按钮 → 跳转入金页
[去看行情] 按钮 → 跳转行情页
```

---

## 四、资产分析 Tab

### 4.1 板块分布

**可视化形式**：横向进度条（Phase 1）/ 饼图（Phase 2）

| 字段 | 说明 |
|------|------|
| 板块名称 | Technology / Consumer Discretionary / Healthcare... |
| 持仓市值 | 该板块所有持仓的市值总和 |
| 占比 % | 该板块市值 / 总持仓市值 |

**板块数据来源**：从行情数据服务获取每只股票的 GICS Sector 分类

### 4.2 P&L 排名

按浮动盈亏绝对值从大到小排列：

| 排名 | 股票 | 持仓市值 | 浮动盈亏 $ | 浮动盈亏 % |
|------|------|---------|----------|----------|
| 1 | NVDA | $5,000 | +$1,200 | +31.6% |
| 2 | AAPL | $8,000 | +$300 | +3.9% |
| 3 | TSLA | $3,000 | -$450 | -13.0% |

### 4.3 集中度预警

**规则**：单只股票持仓市值 > 总持仓市值的 30%

**触发展示**:
```
⚠️ 集中度提示
[NVDA] 持仓占总资产的 45%，集中度较高。
建议适当分散投资，降低单一持股风险。
```

---

## 五、实时数据更新

### 5.1 数据刷新机制

| 数据类型 | 刷新方式 | 频率 |
|---------|---------|------|
| 持仓股价 | WebSocket 订阅 | 实时 |
| 持仓市值 | 依据实时股价计算 | 实时 |
| 今日盈亏 | 依据实时股价计算 | 实时 |
| 总资产 | 持仓市值 + 现金 | 实时 |
| 平均成本 | 成交后更新 | 成交驱动 |
| 未结算资金 | 结算完成后更新 | 每日 |

### 5.2 休市状态

- 市场休市期间，持仓价格显示最后收盘价
- 显示"数据截至 YYYY-MM-DD 收盘"
- 不显示实时更新指示器

---

## 六、持仓页快速入口

### 6.1 入金快捷按钮

位置：资产总览卡片右侧
行为：跳转出入金页 → 默认展示入金 Tab

### 6.2 从持仓买/卖

持仓卡片上直接显示 [买入] [卖出] 按钮：
- 点击 [买入] → 进入该股票交易页（买入方向）
- 点击 [卖出] → 进入该股票交易页（卖出方向），预填"卖出"

---

## 七、后端接口规格

### 7.1 查询持仓

```
GET /v1/portfolio/positions
Response:
  {
    "positions": [
      {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "name_zh": "苹果公司",
        "quantity": 100,
        "settled_quantity": 100,
        "unsettled_quantity": 0,
        "unsettled_settle_date": null,
        "avg_cost": "182.00",
        "current_price": "185.00",
        "market_value": "18500.00",
        "unrealized_pnl": "300.00",
        "unrealized_pnl_pct": "1.65",
        "sector": "Technology"
      }
    ],
    "as_of": "2026-03-13T14:30:00Z"
  }
```

### 7.2 查询资产概览

```
GET /v1/portfolio/summary
Response:
  {
    "total_assets": "25000.00",
    "total_assets_currency": "USD",
    "available_cash": "6500.00",
    "portfolio_value": "18500.00",
    "unsettled_funds": "0.00",
    "frozen_funds": "0.00",
    "today_pnl": "300.00",
    "today_pnl_pct": "1.20",
    "as_of": "2026-03-13T14:30:00Z"
  }
```

### 7.3 查询资产分析

```
GET /v1/portfolio/analysis
Response:
  {
    "sector_distribution": [
      {"sector": "Technology", "value": "12000.00", "pct": "64.86"},
      {"sector": "Consumer Discretionary", "value": "6500.00", "pct": "35.14"}
    ],
    "pnl_ranking": [
      {
        "symbol": "NVDA",
        "market_value": "5000.00",
        "unrealized_pnl": "1200.00",
        "unrealized_pnl_pct": "31.58"
      }
    ],
    "concentration_alerts": [
      {
        "symbol": "NVDA",
        "pct_of_portfolio": "45.00",
        "threshold": "30.00"
      }
    ]
  }
```

---

## 八、数据模型

```sql
-- 持仓表（实时快照，由交易引擎维护）
CREATE TABLE positions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    symbol              VARCHAR(10) NOT NULL,
    market              VARCHAR(5) NOT NULL DEFAULT 'US',
    quantity            NUMERIC(18,6) NOT NULL DEFAULT 0,
    settled_quantity    NUMERIC(18,6) NOT NULL DEFAULT 0,
    avg_cost            NUMERIC(18,4) NOT NULL DEFAULT 0,
    total_cost          NUMERIC(18,4) NOT NULL DEFAULT 0,   -- 总买入成本（用于重算均价）
    version             BIGINT NOT NULL DEFAULT 0,           -- 乐观锁版本号（交易引擎并发写入保护）
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, symbol, market)
);

-- 持仓更新使用乐观锁（CAS 模式）：
-- UPDATE positions
--   SET quantity = $1, settled_quantity = $2, avg_cost = $3, version = version+1, updated_at=NOW()
--   WHERE user_id = $4 AND symbol = $5 AND market = $6 AND version = $7
-- 若 rowsAffected = 0 则表示并发冲突，需重试

-- 未结算持仓明细（按批次跟踪 T+1 结算）
CREATE TABLE unsettled_positions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    order_id        UUID NOT NULL REFERENCES orders(id),
    symbol          VARCHAR(10) NOT NULL,
    quantity        NUMERIC(18,6) NOT NULL,
    cost_basis      NUMERIC(18,4) NOT NULL,
    trade_date      DATE NOT NULL,
    settle_date     DATE NOT NULL,          -- T+1 for US stocks（与 order_fills.settlement_date 关联）
    settled         BOOLEAN DEFAULT false,
    settled_at      TIMESTAMPTZ
);

CREATE INDEX idx_unsettled_settle_date ON unsettled_positions (settle_date)
    WHERE settled = false;

-- 已实现盈亏记录（只追加）
CREATE TABLE realized_pnl (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    symbol          VARCHAR(10) NOT NULL,
    sell_order_id   UUID NOT NULL REFERENCES orders(id),
    quantity        NUMERIC(18,6) NOT NULL,
    sell_price      NUMERIC(18,4) NOT NULL,
    avg_cost        NUMERIC(18,4) NOT NULL,
    pnl_amount      NUMERIC(18,4) NOT NULL,    -- 已实现盈亏金额
    pnl_pct         NUMERIC(8,4) NOT NULL,
    wash_sale_flag  BOOLEAN NOT NULL DEFAULT false,
                    -- true = 触发 Wash Sale Rule（30天内买入相同/基本相同证券）
                    -- 触发时，亏损不可立即抵税，需在后续仓位的成本基础中调整
    wash_sale_adj   NUMERIC(18,4),             -- Wash Sale 调整金额（负数=亏损延迟）
    trade_date      DATE NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 九、验收标准

| 场景 | 标准 |
|------|------|
| 实时盈亏更新 | 股价变动后 < 1 秒反映在持仓页浮动盈亏 |
| 均价计算准确性 | 加权平均算法，误差 < $0.001 |
| 空状态显示 | 无持仓时显示引导界面，不显示空白页 |
| 集中度预警 | 单只持仓超 30% 时自动显示预警卡片 |
| T+1 结算 | 卖出后次日结算前，卖出所得正确标记为未结算 |
| 可卖数量 | 卖出页显示的可卖数量仅包含已结算股数 |
