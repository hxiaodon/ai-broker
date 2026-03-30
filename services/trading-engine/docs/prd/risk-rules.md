---
name: risk-rules
description: 预交易风控规则、PDT 计算、买入力公式、持仓集中度、市价单 collar 参数
type: domain-prd
surface_prd: mobile/docs/prd/04-trading.md (§六.2 价格保护、§九 PDT)
version: 1
status: DRAFT
created: 2026-03-30T00:00+08:00
last_updated: 2026-03-30T00:00+08:00
revisions:
  - rev: 1
    date: 2026-03-30T00:00+08:00
    author: trading-engineer
    summary: "初始版本：从 Surface PRD 提取风控参数、PDT 规则、市价单 collar"
---

# 预交易风险控制规则 (Pre-Trade Risk Rules) — Domain PRD

> **对应 Surface PRD**：`mobile/docs/prd/04-trading.md` §六.2（市价单保护）、§九（PDT）
> **依赖 Spec**：`services/trading-engine/docs/specs/domains/02-pre-trade-risk.md`

---

## 1. 预交易风控检查管道（Pre-Trade Pipeline）

订单从 RISK_APPROVED 进入前需要通过以下 8 道风控检查。任何检查失败都会导致订单状态转为 RISK_REJECTED。

| 序号 | 检查项 | 触发条件 | 拒绝条件 | 优先级 |
|------|--------|---------|---------|--------|
| 1 | 账户状态检查 | 所有订单 | 账户被冻结、KYC 不通过、交易权限禁用 | CRITICAL |
| 2 | 购买力检查 | 买入订单 | 可用资金不足以支付委托金额 + 费用 | CRITICAL |
| 3 | 持仓检查 | 卖出订单 | 持仓数量不足（含未结算限制） | CRITICAL |
| 4 | PDT 规则检查 | 融资账户日内交易 | 触发 PDT 限制 | CRITICAL |
| 5 | 集中度检查 | 所有订单 | 单只持仓占比 > 50%（可配置，Phase 1 仅警告） | WARNING |
| 6 | Reg SHO 检查 | 融券卖空订单 | 无定位证券（locate required） | CRITICAL |
| 7 | 股票停牌检查 | 所有订单 | 股票因停牌/整顿中止交易 | CRITICAL |
| 8 | 交易时段检查 | 所有订单 | 市场休市（仅限价单可在休市下 GTC） | WARNING |

---

## 2. Pattern Day Trader (PDT) 规则

### 2.1 定义与触发

**何为日内交易（Day Trade）**：
- 在同一个交易日内，购买并卖出同一只证券的交易
- 计数条件：`trade_date(buy) == trade_date(sell)`

**PDT 触发条件**（FINRA Rule 4210）：
```
在过去 5 个交易日内，日内交易次数 ≥ 4 次
```

**计数窗口**：
- 滚动窗口，往后回溯 5 个交易日
- 交易日仅计交易所开市日（不含周末、公共假日）
- 触发时刻：第 4 笔日内交易成交时刻

### 2.2 账户类型与 PDT 应用

| 账户类型 | Phase 1 | Phase 2 | 说明 |
|---------|--------|--------|------|
| 现金账户（Cash Account） | ❌ 不适用 | ❌ 不适用 | 现金账户不受 PDT 规则约束 |
| 融资账户（Margin Account） | ✅ 适用 | ✅ 适用 | 融资账户受 PDT 规则约束 |

### 2.3 PDT 限制的效果

一旦账户触发 PDT 标记：

```
1. 账户被标记为 PDT（`is_pdt_marked = true`）
2. 账户权益需维持最低 $25,000 USD（针对融资账户）
3. 如果权益降至 < $25,000，账户进入"PDT Call"状态
4. PDT Call 期间，仅允许卖出操作（closing only 模式）
5. PDT 标记有效期为 90 天；期间不进行新日内交易，自动解除标记
```

### 2.4 前端处理

**Phase 1**（现金账户）：
- 前端展示 PDT 教育内容（"交易设置 → 交易规则 → PDT 说明"）
- 不拦截任何交易

**Phase 2**（融资账户）：
- 下单时调用 `/api/v1/check-pdt-status` 检查账户 PDT 状态
- 如果触发 PDT Call，前端显示"您的账户已触发 Pattern Day Trader 限制，当前仅允许卖出"，阻断买入
- 实时推送 PDT 标记消息给用户

---

## 3. 市价单价格保护（Collar）

### 3.1 为什么需要 Collar

市价单（Market Order）会以最优市场价格立即成交，但在流动性差的时段（盘前、盘后、小盘股），可能出现极端价格波动。
Collar 机制通过对市价单设置**最高或最低价格界限**来保护用户。

### 3.2 Collar 参数定义

| 交易时段 | Buy 单（上限） | Sell 单（下限） | 说明 |
|---------|-----------------|-----------------|------|
| 常规盘中 | 最新卖价 × (1 + 5%) | 最新买价 × (1 - 5%) | 常规市场条件，流动性充足 |
| 盘前（9:30 前） | 最新卖价 × (1 + 3%) | 最新买价 × (1 - 3%) | 流动性低，价差大 |
| 盘后（16:00 后） | 最新卖价 × (1 + 3%) | 最新买价 × (1 - 3%) | 流动性低，价差大 |
| 小盘股（ADV < 100K） | 最新卖价 × (1 + 10%) | 最新买价 × (1 - 10%) | 特别流动性限制 |

### 3.3 Collar 的影响

- **市价单转换为带保护的限价单**：系统自动计算上下界，用户不感知技术细节
- **如果市价越过 Collar 边界**：订单仍会成交，但仅在 Collar 价格范围内
- **用户界面**：在下单确认页显示"系统会对市价单设置价格保护区间，防止在流动性差时以极端价格成交"

### 3.4 实现细节

```python
def calculate_collar_price(side, current_price, time_of_day, avg_daily_volume):
    """
    side: 'BUY' | 'SELL'
    current_price: 最新成交价
    """
    if time_of_day == 'REGULAR' and avg_daily_volume >= 100000:
        collar_ratio = 0.05
    elif time_of_day in ['PRE', 'POST']:
        collar_ratio = 0.03
    else:  # 小盘股
        collar_ratio = 0.10

    if side == 'BUY':
        # Buy 订单：设置最高价（不愿意超过这个价格）
        max_price = current_price * (1 + collar_ratio)
        return max_price
    else:  # SELL
        # Sell 订单：设置最低价（不愿意低于这个价格）
        min_price = current_price * (1 - collar_ratio)
        return min_price
```

---

## 4. 购买力（Buying Power）计算

### 4.1 现金账户（Phase 1）

```
可用购买力 = 可用现金（经 T+1 结算）

限制条件：
  - 仅能用已结算现金购买
  - 未结算的卖出资金不可用于新买入（防止 Free-riding Violation）
  - 每笔买入订单需要：订单总金额 + 预估费用（交易所费用 + SEC 费用 + FINRA 费用）
```

**计算示例**：
```
账户状态：
  - 可用现金：$10,000
  - 今日卖出 AAPL 100 股，已成交 $15,000（但 T+1 日才结算）

下单买入 MSFT 100 股 @ $300：
  - 委托金额 = 100 × $300 = $30,000
  - 预估费用 ≈ $1.00
  - 所需现金 = $30,001

风控检查：可用现金 $10,000 < 所需 $30,001 → ❌ 拒绝
```

### 4.2 融资账户（Phase 2）

```
初始保证金要求（Reg T） = 委托金额 × 50%
维持保证金要求（FINRA 4210） = 头寸市值 × 25%

可用购买力 = 可用现金 + (账户净值 × 4)

示例：
  账户净值 = $50,000
  可用购买力 = $50,000（现金）+ ($50,000 × 4) = $250,000
```

**实现约束**：
- Phase 1 仅需实现现金账户购买力；融资账户延迟到 Phase 2
- 购买力缓存 TTL = 60 秒（实时更新，结合行情推送）
- 网络延迟场景：优先使用本地缓存的购买力，避免频繁 API 调用

---

## 5. 持仓集中度预警

### 5.1 预警触发

```
单只持仓市值 / 总持仓市值 > 30% → 显示警告横幅
```

### 5.2 前端表现

- **颜色**：⚠️ 黄色警示
- **文案**：`"[代码] 占您持仓的 XX%，集中度较高"`
- **可交互性**：可点击查看详情（不强制限制交易，仅提醒）

### 5.3 Note

- Phase 1 仅作警告，不强制限制（现金账户无杠杆风险）
- Phase 2 可考虑与保证金要求联动

---

## 6. Reg SHO 卖空规则（融券）

### 6.1 Locate 要求

```
融券卖空订单需要在下单前获得定位证书（locate）。
locate = 经纪商确认可以从某个来源（库存、借入）获得这些证券。
```

### 6.2 实现时机

- **Phase 1**：现金账户不支持融券，此规则不适用
- **Phase 2**：融资账户支持融券时，需要实现 locate 检查

---

## 7. 异常与边界场景

| 场景 | 处理 |
|------|------|
| 可用资金在下单后、执行前减少（如出金） | 订单仍按原购买力检查结果执行；如后续成交导致 margin call，由持仓管理系统处理 |
| PDT 标记在下单中途被触发 | 已提交的订单继续执行；新订单受 PDT 限制 |
| 股票停牌公告 | 立即拒绝该股票的新订单；已提交但未成交的订单标记为异常 |
| 市价 > Collar 边界 | 市价单仍按 Collar 边界价格成交（可能成交价与用户预期有差距） |

---

## 8. 与其他 Domain PRD 的关系

- **order-lifecycle.md**：RISK_APPROVED / RISK_REJECTED 状态由这些检查决定
- **position-pnl.md**：持仓市值用于集中度和保证金计算
- **settlement.md**：T+1 结算影响购买力计算（未结算资金冻结）
- **mobile/docs/prd/04-trading.md**：前端展示"可用资金""市价单保护"等用户提示
