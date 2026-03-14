# 清结算体系：出入金 vs 交易，两套独立系统

> 本文档澄清一个常见误区：出入金的"结算"和股票交易的"清结算"是两套
> 完全独立的体系，运营主体、参与机构、技术协议均不同。
> 两者在我们系统中只有一个交汇点。
>
> fund-engineer 在设计 Fund Transfer Service 时必须清楚这个边界。

---

## 一、两套体系一览

```
出入金的清结算                      交易的清结算
（资金进出平台）                    （股票买卖）
────────────────                   ────────────────
银行体系                            证券体系
ACH / Fedwire / FPS               DTCC / NSCC / DTC
Nacha / 美联储 运营                 DTCC 运营
资金在银行账户间流转                资金 + 证券同时交收（DVP）
T+0～T+3（看渠道）                 T+1（美股）/ T+2（港股）
我们主动发起或接收                  DTCC 驱动，我们被动接收结果
```

---

## 二、出入金的清结算（银行体系）

### 参与机构

```
用户的银行（RDFI，接收行）
券商的托管银行（ODFI，发起行）
ACH 清算所（FedACH 或 EPN）
美联储（最终在准备金账户间划拨）
```

### 清算过程

```
场景：用户 ACH 入金 $10,000

清算（当天批次）：
  ACH 清算所收集当天所有 ACH 指令
  核对双方银行指令是否匹配
  计算净额（多笔交易轧差，不逐笔结算）
  例：JP Morgan 当天应收 $500 万，应付 $300 万
      净额 = 收 $200 万

结算（次日）：
  美联储在各银行准备金账户间净额划拨
  用户银行准备金账户 -$10,000
  券商托管银行准备金账户 +$10,000

对我们的影响：
  资金 T+1～T+3 才真正到账
  到账前不应解冻用户余额（ACH 垫资风险）
```

### Wire 的清结算

```
场景：用户 Wire 入金 $500,000

清算 + 结算（同步，实时）：
  Fedwire 逐笔实时全额结算（RTGS）
  不批量、不轧差
  每笔单独在准备金账户间划拨
  完成即最终，不可撤销

对我们的影响：
  Wire 到账即可解冻余额
  无 ACH 的延迟 Return 风险
```

---

## 三、交易的清结算（证券体系）

### 参与机构

```
交易所（NYSE / NASDAQ / HKEX）
券商（买方和卖方的经纪商）
NSCC（National Securities Clearing Corporation）— 清算
DTC（Depository Trust Company）— 证券托管和结算
↑ NSCC + DTC 合称 DTCC（Depository Trust & Clearing Corporation）

香港对应：
HKEX（交易所）
HKSCC（香港中央结算有限公司）— 等同于 DTCC
```

### 清算过程（T+0，交易当天）

```
用户买入 AAPL 100股 × $150 = $15,000

NSCC 介入：
  汇总当天所有 AAPL 的买卖指令
  计算每家券商的净头寸（轧差）
  例：我们的券商当天买入 1000股，卖出 800股
      净头寸 = 应收 200股，应付 $30,000

  NSCC 成为中央对手方（CCP）：
    对买方券商：NSCC 是卖方
    对卖方券商：NSCC 是买方
    → 消除了对手方违约风险
```

### 结算过程（T+1，美股）

```
DTC 执行 DVP（Delivery vs Payment，货银对付）：

证券端：
  DTC 账簿上划转股权（不移动实物证券）
  卖方券商 DTC 账户 -200股 AAPL
  买方券商 DTC 账户 +200股 AAPL

资金端：
  通过 Fedwire 在 NSCC 成员间划拨
  买方券商 -$30,000
  卖方券商 +$30,000

关键：证券和资金同步交收，不会出现"钱给了但股票没来"的情况
```

### 香港（T+2）

```
HKSCC 执行类似机制
T+2 完成证券和资金的同步交收
时间更长的原因：历史上跨时区清算复杂度较高
（美股 2024 年 5 月从 T+2 缩短到 T+1）
```

---

## 四、两套体系的唯一交汇点

```
用户卖出 AAPL 获得 $15,000
         │
         ▼
证券清结算（DTCC）完成（T+1）
DTCC 把资金划给我们券商的托管账户
         │
         ▼  ←── 这里是唯一交汇点
         │
Trading Engine 发出 Kafka 事件：
trading.settlement.completed
{
  "user_id": 789456,
  "direction": "SELL",
  "amount": "15000.00",
  "settlement_date": "2026-03-15"
}
         │
         ▼
Fund Transfer Service 消费事件：
  unsettled -$15,000
  available +$15,000
  写入 ledger_entries
         │
         ▼
用户现在可以提现这 $15,000（走银行出金渠道）
```

**在这个交汇点之前，两套体系完全独立，互不干涉。**

---

## 五、fund-engineer 的职责边界

基于以上理解，fund-engineer 只负责：

```
✅ 我们负责的（银行体系）：
  入金：ACH Pull / Wire Push / FPS 实时
  出金：ACH Push / Wire / FPS
  银行账户绑定和验证
  出入金 AML 筛查
  Bank Adapter Layer
  出入金的账本记录

✅ 我们被动接收的（证券体系的输出）：
  消费 trading.settlement.completed 事件
  将 unsettled 转为 available
  写入对应 ledger 分录

❌ 不是我们负责的（证券体系）：
  DTCC / NSCC / DTC 的清结算逻辑
  股票的 DVP 交收
  交易所报告
  → 这些由 Trading Engine 负责
```

---

## 六、常见误区纠正

### 误区 1：fund-transfer-system.md 中的"结算周期"描述有歧义

原文：
```
USD 账户：结算周期 T+1
HKD 账户：结算周期 T+2
```

**这里的 T+1/T+2 是指证券交易结算周期，不是出入金渠道的到账时间。**

正确理解：
```
T+1/T+2 = 股票卖出后，资金多久转为可提现
           （证券体系的时间）

出入金渠道的到账时间是另一回事：
  ACH 入金：T+1～T+3（银行体系）
  Wire 入金：T+0 当日（银行体系）
  FPS 入金：实时（银行体系）
```

### 误区 2：fund-engineer.md 账本分录中的"结算"

原文：
```
每笔交易扣款（买入）:
  DEBIT  user_available_balance  -$150.25
  CREDIT user_frozen_balance     +$150.25  (T+2 结算前冻结)

结算完成:
  DEBIT  user_frozen_balance     -$150.25
  CREDIT user_position_value     +$150.25
```

**这里的"结算完成"指的是证券交易的 DTCC 结算，不是银行的 ACH 结算。**

这个分录逻辑本身是对的，但描述不够清晰，容易与银行出入金结算混淆。
更准确的描述应该是：

```
买入下单（交易冻结）:
  DEBIT  user_available_balance  -$150.25
  CREDIT user_trade_frozen       +$150.25  ← 等待 DTCC 证券结算

DTCC 证券结算完成（T+1）:
  DEBIT  user_trade_frozen       -$150.25
  CREDIT user_position_value     +$150.25  ← 股票到账，资金转为持仓成本
```

---

## 七、完整资金状态流转图

```
用户资金在系统中的完整生命周期：

[入金]
用户银行账户
  │ ACH/Wire/FPS（银行清结算）
  ▼
available（可用余额）

[买入股票]
available → trade_frozen（交易冻结）
  │ 等待 DTCC 证券结算（T+1/T+2）
  ▼
position_value（持仓成本，不再是现金）

[卖出股票]
position_value → unsettled_proceeds（卖出待结算）
  │ DTCC 证券结算完成（T+1/T+2）
  ▼
available（重新变为可用现金）

[提现]
available → withdrawal_frozen（出金冻结）
  │ ACH/Wire/FPS（银行清结算）
  ▼
用户银行账户
```
