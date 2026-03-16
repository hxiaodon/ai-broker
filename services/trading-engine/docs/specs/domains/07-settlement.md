# 结算引擎（Settlement Engine）深度调研

> 美港股券商交易 APP -- 交易后处理（Post-Trade Processing）全景

---

## 1. 业务概述

### 1.1 结算的本质

结算（Settlement）是证券交易生命周期中的最后一环，也是资金和证券所有权真正发生转移的环节。当一笔交易在交易所撮合成交后，买方并不会立即获得证券，卖方也不会立即收到资金 -- 这中间存在一个"结算周期"（Settlement Cycle），由结算机构（Clearing House）担任中央对手方（CCP, Central Counterparty），保证交易的最终履行。

对于券商系统而言，结算引擎承担以下核心职责：

1. **成交确认与匹配**：确认交易所回报的成交记录，与内部订单记录一致
2. **资金计算**：计算每笔成交的净结算金额（Net Settlement Amount），包含所有费用和税费
3. **结算日追踪**：根据市场规则（US T+1 / HK T+2）计算并追踪结算日期
4. **每日结算批处理**：在结算日执行批量处理，更新结算状态
5. **资金划转触发**：通知 Fund Transfer 服务执行实际的资金交割
6. **持仓更新**：更新 settled_qty 和 unsettled_qty，影响用户的可卖出数量和可提取资金
7. **三向对账**：内部台账 vs 银行/托管账户 vs 成交记录的每日核对
8. **企业行动处理**：现金股息、股票拆分、配股等公司行动的结算处理
9. **失败处理**：结算失败的告警、Buy-in 机制、人工介入流程

### 1.2 为什么结算引擎是关键系统

| 风险维度 | 具体影响 |
|---------|---------|
| **资金安全** | 结算金额计算错误直接导致客户资金损失或券商亏损 |
| **监管合规** | SEC Rule 15c6-1 强制 T+1 结算（2024年5月起）；SFC 要求 T+2 结算 |
| **客户体验** | 结算状态直接影响用户的可提取资金和可卖出持仓 |
| **运营风险** | 结算失败（Fail to Deliver）会触发 Buy-in，造成额外成本 |
| **审计要求** | SEC Rule 17a-4 要求所有结算记录保留 7 年 |

### 1.3 结算流程总览

```
 T日（交易日）                 T+1日（美股结算日）           T+2日（港股结算日）
┌──────────────┐             ┌──────────────────┐         ┌──────────────────┐
│ 交易所撮合成交 │             │ 美股结算批处理     │         │ 港股结算批处理     │
│              │             │                  │         │                  │
│ 1. 成交回报   │             │ 1. 扫描待结算记录  │         │ 1. 扫描待结算记录  │
│ 2. 费用计算   │             │ 2. 按账户汇总     │         │ 2. 按账户汇总     │
│ 3. 写入成交表 │             │ 3. 触发资金划转   │         │ 3. 触发资金划转   │
│ 4. 计算结算日 │             │ 4. 更新结算状态   │         │ 4. 更新结算状态   │
│ 5. 状态=PEND │             │ 5. 更新持仓结算数 │         │ 5. 更新持仓结算数 │
└──────────────┘             └──────────────────┘         └──────────────────┘
```

---

## 2. 监管与合规要求

### 2.1 美国市场监管框架

#### SEC Rule 15c6-1: T+1 结算

自 2024 年 5 月 28 日起，SEC 将美国证券市场的标准结算周期从 T+2 缩短为 T+1。这是近年来最重大的市场结构改革之一。

**核心要求：**

- 所有在美国注册的交易所上成交的股票和公司债券，必须在成交日后第一个工作日（T+1）完成结算
- 例外情况：部分市政债券和国债仍遵循各自的结算周期
- 结算窗口：T+1 日 ET 时区的结算截止时间由 NSCC 确定（通常为 T+1 日 15:30 ET 之前确认）

**对系统的影响：**

| 影响领域 | T+2 时代 | T+1 时代 | 系统变更 |
|---------|---------|---------|---------|
| 对账时间窗口 | 2个工作日 | 1个工作日 | 自动化对账，减少人工干预窗口 |
| 资金可用性 | T+2 后可提取 | T+1 后可提取 | 更新 unsettled_qty 逻辑 |
| Fail to Deliver | 有更多时间修正 | 必须更快响应 | 加强实时监控 |
| 公司行动处理 | Record Date 有缓冲 | 缓冲时间缩短 | 更及时的持仓快照 |

#### 结算机构：NSCC + DTC

```
                        ┌──────────────────────────────┐
                        │        DTCC                   │
                        │  (Depository Trust &          │
                        │   Clearing Corporation)       │
                        │                              │
                        │  ┌────────────┐ ┌──────────┐ │
                        │  │    NSCC    │ │   DTC    │ │
                        │  │ (National  │ │(Depository│ │
                        │  │ Securities │ │  Trust   │ │
                        │  │ Clearing   │ │ Company) │ │
                        │  │ Corp.)     │ │          │ │
                        │  │            │ │          │ │
                        │  │ 清算：净额  │ │ 托管：证券│ │
                        │  │ 计算、风险  │ │ 保管与   │ │
                        │  │ 管理、CCP  │ │ 簿记转让  │ │
                        │  └────────────┘ └──────────┘ │
                        └──────────────────────────────┘
```

- **NSCC（National Securities Clearing Corporation）**：负责交易清算，作为中央对手方（CCP）对所有成交进行净额轧差（Netting），大幅降低每日实际需要交割的资金和证券数量
- **DTC（Depository Trust Company）**：负责证券的集中托管和簿记式转让（Book-entry Settlement），不需要物理证券交割

#### Fail to Deliver（交割失败）

当卖方在结算日未能交付证券时，即发生 Fail to Deliver（FTD）。SEC Regulation SHO Rule 204 规定：

- **Close-out 要求**：如果在 T+1 结算日未能交付，Clearing Member 必须在 T+2 的开盘前执行 Buy-in（强制买入等量证券以交付给买方）
- **Penalty Box**：连续 FTD 的证券会被列入 Threshold Securities List，受到更严格的 Short Sale 限制
- **成本后果**：Buy-in 的价格差异由原卖方承担

**系统实现要求：**

```
FTD 处理流程:
1. T+1 结算日结束 → 检查是否有未完成的结算
2. 标记 settlement_status = 'FAILED'
3. 自动告警 → 运营团队 + 合规团队
4. 如需 Buy-in → 触发市价买入订单 → 记录额外成本
5. 记录 FTD 事件到合规审计日志
```

#### SEC/FINRA 费用合规

**SEC Fee（Section 31 Fee）：**

- 仅对卖出方收取
- 费率由 SEC 每半年调整一次（每年 2 月和 8 月）
- 当前费率：$27.80 per million dollars of sales（即 0.00278%）
- 计算基础：成交总金额（Gross Sale Amount）
- 进位规则：以每笔交易为单位，向上取整到最近的 cent

**FINRA TAF（Trading Activity Fee）：**

- 仅对卖出方收取
- 费率：$0.000166 per share sold
- 上限：$8.30 per trade
- 适用于所有 FINRA 会员的卖出交易

### 2.2 香港市场监管框架

#### T+2 结算

港股市场目前仍执行 T+2 结算周期，即成交日后第二个工作日完成交割。

**CCASS（Central Clearing and Settlement System）：**

- 由 HKSCC（Hong Kong Securities Clearing Company）运营，隶属于 HKEX 集团
- 采用持续净额交收（CNS, Continuous Net Settlement）模式
- 结算时间：T+2 日 15:45 HKT 之前完成

**结算流程：**

```
T日:   成交 → CCASS 接收成交记录 → 计算 CNS 净额
T+1日: CCASS 发送结算指令 → 参与者确认
T+2日: DVP（Delivery vs Payment）交割
       - 证券：通过 CCASS 账户簿记转让
       - 资金：通过 RTGS（Real Time Gross Settlement）系统
```

#### 港股费用体系

| 费用名称 | 收取方 | 费率 | 适用方向 | 说明 |
|---------|-------|------|---------|------|
| **印花税（Stamp Duty）** | 香港税务局 | 0.13% | 买卖双方 | 不足 HK$1 按 HK$1 计，向上取整到最近的 HK$1 |
| **SFC 交易征费（Trading Levy）** | SFC | 0.0027% | 买卖双方 | 证监会征费 |
| **交易所交易费（Trading Fee）** | HKEX | 0.00565% | 买卖双方 | 联交所收取 |
| **中央结算费（CCASS Fee）** | HKSCC | 0.002%（最低 HK$2，最高 HK$100） | 买卖双方 | 结算参与者费用 |
| **佣金（Commission）** | 券商 | 0.03%（最低 HK$3） | 买卖双方 | 券商可自定义 |

**印花税特殊规则：**

- 印花税是港股交易中最大的政府收费项目
- 计算方式：成交金额 x 0.13%，向上取整到最近的 HK$1
- 2021 年 8 月 1 日起，印花税从 0.10% 上调至 0.13%
- 买方和卖方各承担全额（即买卖双方各付 0.13%）

### 2.3 结算记录保留要求

| 监管要求 | 保留期限 | 存储要求 |
|---------|---------|---------|
| SEC Rule 17a-4（美国） | 7 年 | WORM（Write Once Read Many）存储 |
| SFC 证券及期货条例（香港） | 6 年 | 可审计的电子记录 |
| FINRA Rule 4511 | 6 年 | 可检索、可再现 |
| 税务记录（IRS/IRD） | 7 年 | 成本基准、已实现盈亏 |

---

## 3. 市场差异（US vs HK）

### 3.1 核心差异对照表

| 维度 | 美股（US） | 港股（HK） |
|------|----------|----------|
| **结算周期** | T+1（自 2024-05-28） | T+2 |
| **结算机构** | NSCC/DTC（DTCC 子公司） | HKSCC/CCASS（HKEX 子公司） |
| **结算模式** | CNS 净额交收 | CNS 净额交收 |
| **结算货币** | USD | HKD |
| **交易时区** | ET（Eastern Time） | HKT（Hong Kong Time） |
| **工作日历** | US 联邦假日 + NYSE/NASDAQ 特殊休市 | HK 公众假期 + HKEX 恶劣天气休市 |
| **最小交易单位** | 1 股（支持碎股） | 1 手（手数因标的而异，如腾讯 100 股/手） |
| **涨跌幅限制** | 无（但有 LULD 熔断机制） | 无（但有市场波动调节机制 VCM） |
| **印花税** | 无 | 0.13%（买卖双方） |
| **SEC Fee** | 0.00278%（仅卖出） | 不适用 |
| **FINRA TAF** | $0.000166/股（仅卖出） | 不适用 |
| **SFC 征费** | 不适用 | 0.0027%（买卖双方） |
| **预扣税** | 非美国居民 15% 股息预扣税 | 无（但需关注大陆投资者的税务安排） |
| **DVP 结算** | DTC 簿记式 | CCASS 簿记式 |

### 3.2 结算日历差异

结算日的计算必须考虑各市场的工作日历。以下是关键规则：

**美股结算日计算：**

```
SettlementDate(US) = TradeDate + 1 Business Day (US Calendar)

US Business Day 排除:
- 周六、周日
- 元旦（Jan 1）
- 马丁路德金日（Jan 第三个周一）
- 总统日（Feb 第三个周一）
- 耶稣受难日（Good Friday）
- 阵亡将士纪念日（May 最后一个周一）
- 六月节（Jun 19）
- 独立日（Jul 4）
- 劳动节（Sep 第一个周一）
- 感恩节（Nov 第四个周四）
- 圣诞节（Dec 25）
- NYSE/NASDAQ 特殊休市日（如前总统葬礼日）

特殊规则:
- 如果假日落在周六，则周五休市
- 如果假日落在周日，则周一休市
- 感恩节后的周五为半日交易，但结算正常进行
```

**港股结算日计算：**

```
SettlementDate(HK) = TradeDate + 2 Business Days (HK Calendar)

HK Business Day 排除:
- 周六、周日
- 元旦（Jan 1）
- 农历新年（3天）
- 清明节
- 耶稣受难日 + 复活节星期一
- 劳动节（May 1）
- 佛诞
- 端午节
- 香港特别行政区成立纪念日（Jul 1）
- 中秋节翌日
- 国庆日（Oct 1）
- 重阳节
- 圣诞节 + 圣诞节后第一个周日
- HKEX 恶劣天气休市（台风信号 8 号或以上、黑色暴雨警告）

特殊规则:
- 台风/暴雨导致的临时休市不可提前预知
- 需要实时获取 HKEX 休市公告
- 半日交易日（如农历年除夕）结算正常
```

### 3.3 费用计算公式

#### 美股费用计算

```
成交金额 = 成交价格 x 成交数量

--- 买入方 ---
佣金      = 成交数量 x $0.005/share
交易所费用 = 成交数量 x $0.003/share
SEC费用   = $0（买入不收）
FINRA TAF = $0（买入不收）

净结算金额（买入） = 成交金额 + 佣金 + 交易所费用

--- 卖出方 ---
佣金      = 成交数量 x $0.005/share
交易所费用 = 成交数量 x $0.003/share
SEC费用   = 成交金额 x 0.0000278（向上取整到 $0.01）
FINRA TAF = 成交数量 x $0.000166（上限 $8.30，向上取整到 $0.01）

净结算金额（卖出） = 成交金额 - 佣金 - SEC费用 - FINRA_TAF - 交易所费用
```

**示例：卖出 1000 股 AAPL @ $150.00**

```
成交金额     = 1000 x $150.00 = $150,000.00
佣金         = 1000 x $0.005  = $5.00
交易所费用    = 1000 x $0.003  = $3.00
SEC费用      = $150,000 x 0.0000278 = $4.17 → 向上取整 = $4.17
FINRA TAF    = 1000 x $0.000166 = $0.17 → 向上取整 = $0.17
总费用       = $5.00 + $3.00 + $4.17 + $0.17 = $12.34
净结算金额   = $150,000.00 - $12.34 = $149,987.66
```

#### 港股费用计算

```
成交金额 = 成交价格 x 成交数量

--- 买入方/卖出方（相同） ---
佣金         = MAX(成交金额 x 0.0003, HK$3.00)
印花税       = CEIL(成交金额 x 0.0013)          -- 向上取整到 HK$1
SFC交易征费  = 成交金额 x 0.000027
交易所交易费  = 成交金额 x 0.0000565
平台费       = HK$0.50（固定）

净结算金额（买入） = 成交金额 + 佣金 + 印花税 + SFC征费 + 交易所费 + 平台费
净结算金额（卖出） = 成交金额 - 佣金 - 印花税 - SFC征费 - 交易所费 - 平台费
```

**示例：买入 2000 股腾讯 (0700.HK) @ HK$350.00**

```
成交金额     = 2000 x HK$350.00 = HK$700,000.00
佣金         = MAX(HK$700,000 x 0.0003, HK$3) = MAX(HK$210, HK$3) = HK$210.00
印花税       = CEIL(HK$700,000 x 0.0013) = CEIL(HK$910) = HK$910.00
SFC征费      = HK$700,000 x 0.000027 = HK$18.90
交易所费     = HK$700,000 x 0.0000565 = HK$39.55
平台费       = HK$0.50
总费用       = HK$210.00 + HK$910.00 + HK$18.90 + HK$39.55 + HK$0.50 = HK$1,178.95
净结算金额   = HK$700,000.00 + HK$1,178.95 = HK$701,178.95
```

### 3.4 企业行动差异

| 企业行动 | 美股处理 | 港股处理 |
|---------|---------|---------|
| **现金股息** | 除权日 Ex-Date 前一个工作日为 Record Date；T+1 下原 Record Date 与 Ex-Date 为同日 | Ex-Date 通常为 Record Date 前 2 个工作日 |
| **股息税** | 非美居民 15% 预扣税（W-8BEN 表格） | 港股无股息预扣税；通过港股通投资的 A 股有 10% 红利税 |
| **股票拆分** | Ex-Date 前收盘后生效 | Ex-Date 生效 |
| **配股（Rights Issue）** | 较少见 | 常见，需通知客户行权或放弃 |

---

## 4. 技术架构

### 4.1 结算引擎整体架构

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         Settlement Engine                                │
│                                                                          │
│  ┌───────────────┐   ┌────────────────┐   ┌──────────────────────────┐  │
│  │ Settlement     │   │ Corporate      │   │ Reconciliation           │  │
│  │ Batch Job      │   │ Action         │   │ Engine                   │  │
│  │                │   │ Processor      │   │                          │  │
│  │ • Daily scan   │   │                │   │ • Internal vs Exchange   │  │
│  │ • Aggregate    │   │ • Dividend     │   │ • Internal vs Custodian  │  │
│  │ • Trigger fund │   │ • Stock Split  │   │ • Position vs Ledger     │  │
│  │ • Update state │   │ • Rights Issue │   │ • Daily report           │  │
│  └───────┬───────┘   │ • Merger       │   └──────────┬───────────────┘  │
│          │           └────────┬───────┘              │                  │
│          │                    │                       │                  │
│          ▼                    ▼                       ▼                  │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                     Settlement Repository                          │  │
│  │                                                                    │  │
│  │  executions (settled/unsettled)                                    │  │
│  │  positions (settled_qty / unsettled_qty)                           │  │
│  │  corporate_actions (PENDING / PROCESSED)                          │  │
│  │  settlement_events (append-only audit log)                        │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                     External Integrations                          │  │
│  │                                                                    │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │  │
│  │  │ Fund Transfer │  │ Market Data  │  │ Kafka Event Bus          │ │  │
│  │  │ Service       │  │ Service      │  │                          │ │  │
│  │  │ (资金划转)     │  │ (企业行动   │  │ settlement.completed     │ │  │
│  │  │               │  │  数据源)     │  │ settlement.failed        │ │  │
│  │  │               │  │              │  │ corporate_action.applied │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

### 4.2 核心接口设计（已实现）

基于代码库中 `src/internal/settlement/settlement.go` 的接口定义：

```go
// Engine 结算引擎接口
type Engine interface {
    // ProcessDaily 每日结算批处理
    // 扫描指定结算日的待结算成交，按账户汇总后触发资金划转
    ProcessDaily(ctx context.Context, settlementDate time.Time) error

    // GetUnsettledExecutions 获取待结算成交
    // 查询 settlement_date = 指定日期 AND settled = FALSE 的记录
    GetUnsettledExecutions(ctx context.Context, settlementDate time.Time) ([]*UnsettledExecution, error)

    // ProcessCorporateAction 处理公司行动
    // 根据企业行动类型（股息/拆股/配股等）执行相应的持仓和资金调整
    ProcessCorporateAction(ctx context.Context, action *CorporateAction) error
}
```

### 4.3 每日结算批处理流程

结算批处理是整个结算引擎最核心的流程。它在每个工作日的固定时间运行（通常在美股收盘后或港股结算截止时间前），处理当日到期的所有待结算成交。

```
┌──────────────────────────────────────────────────────────────────────┐
│                Daily Settlement Batch Job                             │
│                                                                      │
│  Step 1: 扫描待结算成交                                                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  SELECT * FROM executions                                      │  │
│  │  WHERE settlement_date = :today                                │  │
│  │    AND settled = FALSE                                         │  │
│  │  ORDER BY account_id, executed_at                              │  │
│  │                                                                │  │
│  │  使用 idx_exec_settlement 索引                                  │  │
│  │  WHERE settled = FALSE 的 Partial Index 确保扫描高效             │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  Step 2: 按账户汇总净结算金额                                          │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  account_settlements = {}                                      │  │
│  │  FOR EACH execution:                                           │  │
│  │    key = (account_id, market, currency)                        │  │
│  │    IF side == BUY:                                             │  │
│  │      account_settlements[key].debit += net_amount              │  │
│  │    ELSE:                                                       │  │
│  │      account_settlements[key].credit += net_amount             │  │
│  │    account_settlements[key].executions.append(execution)       │  │
│  │                                                                │  │
│  │  net_amount = credit - debit (正数=净收入，负数=净支出)           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  Step 3: 触发 Fund Transfer 资金划转                                   │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  FOR EACH (account_id, net_amount) in account_settlements:     │  │
│  │    IF net_amount < 0 (净买入):                                  │  │
│  │      → 从客户资金账户扣款（已在下单时冻结）                        │  │
│  │      → 释放冻结资金，确认扣款                                    │  │
│  │    IF net_amount > 0 (净卖出):                                  │  │
│  │      → 将结算收入存入客户资金账户                                 │  │
│  │      → 标记为已结算可用资金（可提取）                             │  │
│  │                                                                │  │
│  │  通过 Kafka 事件通知 Fund Transfer 服务：                        │  │
│  │  Topic: settlement.fund_transfer                               │  │
│  │  Event: SettlementFundTransferRequest                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  Step 4: 更新结算状态                                                  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  BEGIN TRANSACTION:                                            │  │
│  │                                                                │  │
│  │  -- 更新成交记录为已结算                                         │  │
│  │  UPDATE executions                                             │  │
│  │  SET settled = TRUE, settled_at = NOW()                        │  │
│  │  WHERE settlement_date = :today AND settled = FALSE            │  │
│  │    AND execution_id IN (:settled_ids)                          │  │
│  │                                                                │  │
│  │  -- 更新持仓的结算/未结算数量                                    │  │
│  │  FOR EACH (account_id, symbol, market) in affected_positions:  │  │
│  │    settled_delta = SUM(buy_qty) - SUM(sell_qty) for settled    │  │
│  │    UPDATE positions                                            │  │
│  │    SET settled_qty = settled_qty + :settled_delta,             │  │
│  │        unsettled_qty = unsettled_qty - :settled_delta,         │  │
│  │        version = version + 1                                   │  │
│  │    WHERE account_id = :aid AND symbol = :sym                   │  │
│  │      AND market = :mkt AND version = :expected_version         │  │
│  │                                                                │  │
│  │  COMMIT                                                        │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              ▼                                       │
│  Step 5: 发布结算完成事件                                              │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Kafka Topic: settlement.completed                             │  │
│  │  Event: {                                                      │  │
│  │    settlement_date: "2026-03-16",                              │  │
│  │    market: "US",                                               │  │
│  │    accounts_settled: 1523,                                     │  │
│  │    executions_settled: 8742,                                   │  │
│  │    total_debit: "45,230,108.50",                               │  │
│  │    total_credit: "43,891,220.75",                              │  │
│  │    failed_count: 0,                                            │  │
│  │    duration_ms: 2340                                           │  │
│  │  }                                                             │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 4.4 结算日计算算法

```go
// CalculateSettlementDate 计算结算日期
// market: "US" 或 "HK"
// tradeDate: 成交日期（交易所时区的日期）
func CalculateSettlementDate(tradeDate time.Time, market string) time.Time {
    switch market {
    case "US":
        return addBusinessDays(tradeDate, 1, USBusinessCalendar)
    case "HK":
        return addBusinessDays(tradeDate, 2, HKBusinessCalendar)
    default:
        panic(fmt.Sprintf("unsupported market: %s", market))
    }
}

// addBusinessDays 在给定日期上加 N 个工作日
// 跳过周末和指定日历中的假日
func addBusinessDays(date time.Time, days int, calendar BusinessCalendar) time.Time {
    added := 0
    current := date
    for added < days {
        current = current.AddDate(0, 0, 1)
        if calendar.IsBusinessDay(current) {
            added++
        }
    }
    return current
}

// BusinessCalendar 工作日日历接口
type BusinessCalendar interface {
    IsBusinessDay(date time.Time) bool
    NextBusinessDay(date time.Time) time.Time
    // 需要每年维护假日列表
    // US: 从 NYSE 官网获取年度休市日历
    // HK: 从 HKEX 官网获取年度休市日历
}
```

### 4.5 成交后费用计算引擎

费用计算必须基于 `fee_configs` 表中的配置，支持费率的动态调整和按日期生效。

```go
// FeeCalculator 费用计算器
type FeeCalculator struct {
    configs []FeeConfig // 从 fee_configs 表加载
}

// CalculateUS 计算美股成交费用
func (fc *FeeCalculator) CalculateUS(
    side string,
    quantity int64,
    price decimal.Decimal,
) *USFees {
    tradeValue := price.Mul(decimal.NewFromInt(quantity))
    fees := &USFees{}

    // 佣金: $0.005/share (买卖双方)
    fees.Commission = decimal.NewFromFloat(0.005).
        Mul(decimal.NewFromInt(quantity))

    // 交易所费: $0.003/share (买卖双方)
    fees.ExchangeFee = decimal.NewFromFloat(0.003).
        Mul(decimal.NewFromInt(quantity))

    if side == "SELL" {
        // SEC Fee: 成交金额 x 0.0000278 (仅卖出)
        // 向上取整到 $0.01
        secFee := tradeValue.Mul(decimal.NewFromFloat(0.0000278))
        fees.SECFee = ceilToCent(secFee)

        // FINRA TAF: $0.000166/share (仅卖出), 上限 $8.30
        taf := decimal.NewFromFloat(0.000166).
            Mul(decimal.NewFromInt(quantity))
        maxTAF := decimal.NewFromFloat(8.30)
        if taf.GreaterThan(maxTAF) {
            taf = maxTAF
        }
        fees.FINRATAF = ceilToCent(taf)
    }

    fees.TotalFees = fees.Commission.
        Add(fees.ExchangeFee).
        Add(fees.SECFee).
        Add(fees.FINRATAF)

    return fees
}

// CalculateHK 计算港股成交费用
func (fc *FeeCalculator) CalculateHK(
    side string,
    quantity int64,
    price decimal.Decimal,
) *HKFees {
    tradeValue := price.Mul(decimal.NewFromInt(quantity))
    fees := &HKFees{}

    // 佣金: MAX(成交金额 x 0.0003, HK$3)
    commission := tradeValue.Mul(decimal.NewFromFloat(0.0003))
    minCommission := decimal.NewFromFloat(3.00)
    if commission.LessThan(minCommission) {
        commission = minCommission
    }
    fees.Commission = commission

    // 印花税: 成交金额 x 0.0013, 向上取整到 HK$1
    stampDuty := tradeValue.Mul(decimal.NewFromFloat(0.0013))
    fees.StampDuty = ceilToHKD(stampDuty) // 向上取整到 HK$1

    // SFC 交易征费: 成交金额 x 0.000027
    fees.TradingLevy = tradeValue.Mul(decimal.NewFromFloat(0.000027))

    // 交易所交易费: 成交金额 x 0.0000565
    fees.TradingFee = tradeValue.Mul(decimal.NewFromFloat(0.0000565))

    // 平台费: HK$0.50
    fees.PlatformFee = decimal.NewFromFloat(0.50)

    fees.TotalFees = fees.Commission.
        Add(fees.StampDuty).
        Add(fees.TradingLevy).
        Add(fees.TradingFee).
        Add(fees.PlatformFee)

    return fees
}

// ceilToCent 向上取整到 $0.01
func ceilToCent(amount decimal.Decimal) decimal.Decimal {
    return amount.Mul(decimal.NewFromInt(100)).
        Ceil().
        Div(decimal.NewFromInt(100))
}

// ceilToHKD 向上取整到 HK$1
func ceilToHKD(amount decimal.Decimal) decimal.Decimal {
    return amount.Ceil()
}
```

### 4.6 三向对账（Reconciliation）

对账是确保资金和证券记录正确性的最后防线。每日必须执行，且任何差异都必须在当日解决。

```
┌────────────────────────────────────────────────────────────────────────┐
│                    Daily Reconciliation (三向对账)                      │
│                                                                        │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐           │
│  │   Source A    │     │   Source B    │     │   Source C    │           │
│  │              │     │              │     │              │           │
│  │ Internal     │     │ Exchange /   │     │ Custodian /  │           │
│  │ Ledger       │     │ NSCC / CCASS │     │ Bank         │           │
│  │ (executions  │     │ (成交确认    │     │ (资金余额    │           │
│  │  table)      │     │  文件)       │     │  对账单)     │           │
│  └──────┬───────┘     └──────┬───────┘     └──────┬───────┘           │
│         │                    │                    │                    │
│         ▼                    ▼                    ▼                    │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                    Reconciliation Engine                        │   │
│  │                                                                │   │
│  │  Match 1: Internal vs Exchange (成交记录核对)                   │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │ 逐笔匹配:                                                │  │   │
│  │  │   execution_id ↔ exchange_exec_id                        │  │   │
│  │  │   quantity ↔ fill_qty                                    │  │   │
│  │  │   price ↔ fill_price                                     │  │   │
│  │  │   side ↔ side                                            │  │   │
│  │  │                                                          │  │   │
│  │  │ 差异类型:                                                 │  │   │
│  │  │   MISSING_INTERNAL: 交易所有，内部无 → 严重！可能丢单       │  │   │
│  │  │   MISSING_EXCHANGE: 内部有，交易所无 → 严重！可能虚报       │  │   │
│  │  │   PRICE_MISMATCH: 价格不一致 → 调查原因                    │  │   │
│  │  │   QTY_MISMATCH: 数量不一致 → 调查原因                      │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │  Match 2: Internal vs Custodian (资金余额核对)                  │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │ 汇总级匹配:                                              │  │   │
│  │  │   SUM(client_balances) ↔ custodian_total_balance         │  │   │
│  │  │                                                          │  │   │
│  │  │ 差异阈值:                                                 │  │   │
│  │  │   < $0.01: 忽略（浮点取整误差）                            │  │   │
│  │  │   $0.01 - $100: 自动告警，人工调查                         │  │   │
│  │  │   > $100: 紧急告警，暂停新的资金操作                        │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  │  Match 3: Position vs Ledger (持仓与台账核对)                   │   │
│  │  ┌──────────────────────────────────────────────────────────┐  │   │
│  │  │ SUM(position.quantity) for each symbol                   │  │   │
│  │  │   ↔ SUM(execution buy_qty) - SUM(execution sell_qty)     │  │   │
│  │  │   ↔ custodian_security_balance (if available)            │  │   │
│  │  └──────────────────────────────────────────────────────────┘  │   │
│  │                                                                │   │
│  └────────────────────────────────────────────────────────────────┘   │
│                              │                                        │
│                              ▼                                        │
│  ┌────────────────────────────────────────────────────────────────┐   │
│  │                 Reconciliation Report                           │   │
│  │                                                                │   │
│  │  {                                                             │   │
│  │    "date": "2026-03-16",                                      │   │
│  │    "market": "US",                                            │   │
│  │    "status": "MATCHED" | "DISCREPANCY",                       │   │
│  │    "internal_execution_count": 8742,                          │   │
│  │    "exchange_execution_count": 8742,                          │   │
│  │    "matched_count": 8740,                                     │   │
│  │    "discrepancy_count": 2,                                    │   │
│  │    "discrepancies": [                                         │   │
│  │      { "type": "PRICE_MISMATCH", "exec_id": "...", ... }    │   │
│  │    ],                                                         │   │
│  │    "balance_check": {                                         │   │
│  │      "internal_total": "12,345,678.90",                       │   │
│  │      "custodian_total": "12,345,678.90",                      │   │
│  │      "difference": "0.00"                                     │   │
│  │    }                                                          │   │
│  │  }                                                             │   │
│  └────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

### 4.7 结算失败处理

```
结算失败处理流程:

┌─────────────────┐
│ 检测到结算失败    │
│ (交割失败/资金    │
│  不足/系统错误)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 标记状态 FAILED  │
│ 记录失败原因     │
│ 写入审计日志     │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────────────┐
│ 资金   │ │ 证券交割失败    │
│ 不足   │ │ (Fail to       │
│        │ │  Deliver)      │
└───┬────┘ └───────┬────────┘
    │              │
    ▼              ▼
┌────────┐ ┌────────────────┐
│ 通知   │ │ 启动 Buy-in    │
│ 客户   │ │ 流程           │
│ 补款   │ │                │
│        │ │ 1. 市价买入     │
│ 冻结   │ │ 2. 差价由原     │
│ 相关   │ │    卖方承担     │
│ 操作   │ │ 3. 报告给      │
│        │ │    NSCC/CCASS  │
└───┬────┘ └───────┬────────┘
    │              │
    ▼              ▼
┌─────────────────────┐
│ 告警通知             │
│ • 运营团队           │
│ • 合规团队           │
│ • 如超阈值→管理层    │
└─────────────────────┘
```

---

## 5. 性能要求与设计决策

### 5.1 性能目标

| 指标 | 目标 | 说明 |
|------|------|------|
| 每日结算批处理耗时 | < 5 分钟 | 处理当日所有待结算成交 |
| 单笔结算确认延迟 | < 100ms | 从确认到状态更新 |
| 对账处理耗时 | < 10 分钟 | 三向对账全量匹配 |
| 数据准确性 | 100% | 零容差，任何差异必须告警 |
| 系统可用性 | 99.99% | 结算失败不可接受 |

### 5.2 设计决策

#### Decision 1: Batch vs Real-time Settlement

**选择：批处理模式（Batch Processing）**

理由：
- 结算本身是批次性质的：NSCC/CCASS 按日进行净额交收
- 实时结算在当前监管框架下没有意义（即使 T+1，仍然是"日"级别）
- 批处理可以利用净额轧差（Netting）减少实际资金划转次数
- 批处理可以在市场收盘后低负载时段运行

但实时追踪是必要的：
- 用户随时可以查看其 unsettled_qty 和 settled_qty
- 下单时需要实时知道可用余额（settled cash vs unsettled proceeds）
- 因此成交时立即更新 unsettled_qty，结算批处理时转移到 settled_qty

#### Decision 2: 结算状态机

```
              ┌───────────┐
  成交写入 ──▶ │  PENDING   │ (成交已记录，等待结算日到来)
              └─────┬─────┘
                    │ 结算日到来，批处理开始
                    ▼
              ┌───────────┐
              │  SETTLING  │ (结算处理中，资金划转进行中)
              └─────┬─────┘
                   ╱ ╲
                  ╱   ╲
                 ▼     ▼
          ┌─────────┐ ┌─────────┐
          │ SETTLED  │ │ FAILED  │
          │ (已结算)  │ │ (失败)   │
          └─────────┘ └────┬────┘
                           │ 重试/人工处理
                           ▼
                      ┌─────────┐
                      │ SETTLED  │ (最终结算)
                      └─────────┘
```

#### Decision 3: Optimistic Locking for Position Updates

持仓表使用 `version` 字段实现乐观锁。在结算批处理更新 `settled_qty` 和 `unsettled_qty` 时：

```sql
UPDATE positions
SET settled_qty = settled_qty + :delta,
    unsettled_qty = unsettled_qty - :delta,
    version = version + 1,
    updated_at = NOW()
WHERE account_id = :account_id
  AND symbol = :symbol
  AND market = :market
  AND version = :expected_version;
```

如果 `affected_rows = 0`，说明持仓被并发修改（例如用户同时在交易），需要重新读取后重试。

#### Decision 4: Idempotency in Settlement

结算批处理必须是幂等的。如果批处理中途失败重启：

- 使用 `settled` 标志位：已标记 `settled = TRUE` 的记录不会被重复处理
- 使用事务：每个账户的结算更新在独立事务中完成
- 使用 Kafka 幂等发送：settlement event 使用 execution_id 作为 idempotency key

#### Decision 5: 费率的动态配置

费率配置存储在 `fee_configs` 表中，使用 `effective_from` 和 `effective_to` 字段支持费率变更：

- SEC Fee 每半年调整一次 → 插入新记录，设置 `effective_from` 为新费率生效日期
- 券商佣金调整 → 同上
- 查询时根据成交日期匹配有效的费率配置
- 内存缓存费率配置，每日重新加载

---

## 6. 接口设计（gRPC/REST/Kafka Events）

### 6.1 gRPC 接口

```protobuf
syntax = "proto3";
package trading.settlement.v1;

import "google/protobuf/timestamp.proto";
import "google/protobuf/empty.proto";

service SettlementService {
  // 触发指定日期的结算批处理
  rpc ProcessDailySettlement(ProcessDailySettlementRequest)
      returns (ProcessDailySettlementResponse);

  // 查询待结算成交列表
  rpc GetUnsettledExecutions(GetUnsettledExecutionsRequest)
      returns (GetUnsettledExecutionsResponse);

  // 查询结算历史
  rpc GetSettlementHistory(GetSettlementHistoryRequest)
      returns (GetSettlementHistoryResponse);

  // 查询账户的结算摘要
  rpc GetAccountSettlementSummary(GetAccountSettlementSummaryRequest)
      returns (AccountSettlementSummary);

  // 处理企业行动
  rpc ProcessCorporateAction(ProcessCorporateActionRequest)
      returns (ProcessCorporateActionResponse);

  // 手动重试失败的结算
  rpc RetryFailedSettlement(RetryFailedSettlementRequest)
      returns (RetryFailedSettlementResponse);

  // 触发对账
  rpc RunReconciliation(RunReconciliationRequest)
      returns (ReconciliationReport);
}

message ProcessDailySettlementRequest {
  string settlement_date = 1;  // "2026-03-16"
  string market = 2;           // "US" or "HK"
  bool dry_run = 3;            // true = 只计算不执行
}

message ProcessDailySettlementResponse {
  int32 accounts_processed = 1;
  int32 executions_settled = 2;
  string total_debit = 3;       // decimal string
  string total_credit = 4;      // decimal string
  int32 failed_count = 5;
  repeated SettlementFailure failures = 6;
  int64 duration_ms = 7;
}

message SettlementFailure {
  string execution_id = 1;
  int64 account_id = 2;
  string reason = 3;
  string error_code = 4;
}

message GetUnsettledExecutionsRequest {
  string settlement_date = 1;
  string market = 2;
  int64 account_id = 3;         // optional: filter by account
}

message GetUnsettledExecutionsResponse {
  repeated UnsettledExecution executions = 1;
  string total_net_amount = 2;
}

message UnsettledExecution {
  string execution_id = 1;
  string order_id = 2;
  int64 account_id = 3;
  string symbol = 4;
  string market = 5;
  string side = 6;
  int64 quantity = 7;
  string price = 8;             // decimal string
  string net_amount = 9;        // decimal string
  string settlement_date = 10;
  string fees_breakdown = 11;   // JSON: {commission, sec_fee, stamp_duty, ...}
}

message AccountSettlementSummary {
  int64 account_id = 1;
  string settled_cash = 2;       // 已结算可用资金
  string unsettled_cash = 3;     // 未结算资金
  string pending_settlement = 4; // 待结算金额
  repeated PositionSettlement positions = 5;
}

message PositionSettlement {
  string symbol = 1;
  string market = 2;
  int64 settled_qty = 3;
  int64 unsettled_qty = 4;
  string earliest_settlement_date = 5;
}

message ProcessCorporateActionRequest {
  string action_type = 1;       // "DIVIDEND" / "STOCK_SPLIT" / ...
  string symbol = 2;
  string market = 3;
  string record_date = 4;
  string ex_date = 5;
  string pay_date = 6;
  string dividend_per_share = 7; // decimal string
  string dividend_currency = 8;
  int32 split_ratio = 9;
}

message ProcessCorporateActionResponse {
  int32 accounts_affected = 1;
  string total_dividend_distributed = 2;
  repeated CorporateActionDetail details = 3;
}

message CorporateActionDetail {
  int64 account_id = 1;
  string symbol = 2;
  int64 position_qty = 3;       // ex-date 持仓量
  string amount = 4;            // 应收/应付金额
  string tax_withheld = 5;      // 预扣税
  string net_amount = 6;        // 净额
}
```

### 6.2 REST API（通过 API Gateway 暴露给前端）

```yaml
# 用户查看自己的结算状态
GET /api/v1/accounts/{account_id}/settlement/summary
Response:
  settled_cash: "12,345.67"
  unsettled_cash: "5,678.90"
  pending_settlements:
    - symbol: "AAPL"
      side: "BUY"
      quantity: 100
      net_amount: "15,234.50"
      settlement_date: "2026-03-17"
    - symbol: "0700.HK"
      side: "SELL"
      quantity: 200
      net_amount: "70,120.30"
      settlement_date: "2026-03-18"

# 用户查看成交明细（含结算状态）
GET /api/v1/accounts/{account_id}/executions?from=2026-03-01&to=2026-03-16
Response:
  executions:
    - execution_id: "exec-001"
      order_id: "ord-001"
      symbol: "AAPL"
      side: "BUY"
      quantity: 100
      price: "150.25"
      commission: "0.50"
      total_fees: "1.30"
      net_amount: "15,026.30"
      settlement_date: "2026-03-17"
      settled: false
      executed_at: "2026-03-16T14:30:00Z"

# 查看企业行动记录
GET /api/v1/accounts/{account_id}/corporate-actions?from=2026-01-01
Response:
  corporate_actions:
    - action_type: "DIVIDEND"
      symbol: "AAPL"
      ex_date: "2026-02-07"
      pay_date: "2026-02-15"
      dividend_per_share: "0.25"
      position_qty: 100
      gross_amount: "25.00"
      tax_withheld: "3.75"
      net_amount: "21.25"
      status: "PAID"
```

### 6.3 Kafka Events

```
Topic: trading.settlement

--- 结算完成事件 ---
Key: {account_id}
Value: {
  "event_type": "SETTLEMENT_COMPLETED",
  "event_id": "evt-uuid",
  "timestamp": "2026-03-16T20:00:00Z",
  "data": {
    "settlement_date": "2026-03-16",
    "account_id": 12345,
    "market": "US",
    "executions": [
      {
        "execution_id": "exec-001",
        "symbol": "AAPL",
        "side": "BUY",
        "quantity": 100,
        "net_amount": "15,026.30"
      }
    ],
    "net_settlement_amount": "-15,026.30",
    "settled_cash_delta": "-15,026.30"
  }
}

--- 结算失败事件 ---
Key: {account_id}
Value: {
  "event_type": "SETTLEMENT_FAILED",
  "event_id": "evt-uuid",
  "timestamp": "2026-03-16T20:05:00Z",
  "data": {
    "settlement_date": "2026-03-16",
    "account_id": 12345,
    "execution_id": "exec-002",
    "reason": "INSUFFICIENT_CUSTODIAN_BALANCE",
    "error_code": "SETTLE_ERR_001",
    "requires_manual_review": true
  }
}

--- 企业行动已处理事件 ---
Key: {symbol}
Value: {
  "event_type": "CORPORATE_ACTION_PROCESSED",
  "event_id": "evt-uuid",
  "timestamp": "2026-02-15T08:00:00Z",
  "data": {
    "action_type": "DIVIDEND",
    "symbol": "AAPL",
    "market": "US",
    "pay_date": "2026-02-15",
    "accounts_affected": 523,
    "total_distributed": "13,075.00"
  }
}

--- 结算资金划转请求（发送给 Fund Transfer 服务） ---
Topic: settlement.fund_transfer
Key: {account_id}
Value: {
  "event_type": "SETTLEMENT_FUND_TRANSFER_REQUEST",
  "event_id": "evt-uuid",
  "idempotency_key": "settle-{settlement_date}-{account_id}-{market}",
  "timestamp": "2026-03-16T20:00:00Z",
  "data": {
    "account_id": 12345,
    "settlement_date": "2026-03-16",
    "market": "US",
    "currency": "USD",
    "direction": "DEBIT",
    "amount": "15,026.30",
    "description": "Settlement for 2026-03-16 US trades",
    "execution_ids": ["exec-001", "exec-003"]
  }
}
```

---

## 7. 开源参考实现

### 7.1 直接相关的开源项目

| 项目 | 语言 | 说明 | 参考价值 |
|------|------|------|---------|
| **quickfixgo/quickfix** | Go | FIX 协议引擎 | 交易所连接层，但不含结算逻辑 |
| **shopspring/decimal** | Go | 高精度十进制运算 | **必须使用** -- 所有金额计算 |
| **alpacahq/alpaca-trade-api-go** | Go | Alpaca 券商 API client | 参考其结算状态模型和 P&L 计算 |
| **interactivebrokers/tws-api** | Multi | IB TWS API | 参考其成交确认和结算通知模型 |
| **Open-Finance/Settlement** | Java | 开源结算引擎 PoC | 结算流程参考，但不适合生产 |

### 7.2 基础设施组件

| 组件 | 推荐方案 | 说明 |
|------|---------|------|
| **定时任务** | `robfig/cron/v3` | 每日结算批处理调度 |
| **分布式锁** | Redis + `go-redsync/redsync` | 确保结算批处理单节点执行 |
| **Kafka 客户端** | `segmentio/kafka-go` | 结算事件发布和消费 |
| **数据库** | `jackc/pgx/v5` | PostgreSQL driver（当前 schema 为 PostgreSQL） |
| **监控** | `prometheus/client_golang` | 结算延迟、成功率、对账差异 |
| **日志** | `uber-go/zap` | 结构化零分配日志 |
| **工作日历** | `rickar/cal/v2` | 工作日/假日计算 |

### 7.3 行业标准参考

| 标准 | 说明 | 参考用途 |
|------|------|---------|
| **ISO 15022** | 证券报文标准 | 结算指令格式 |
| **ISO 20022** | 金融报文新标准 | 逐步取代 15022 |
| **FIX 4.4 Allocation** | FIX 分配报文 | 成交分配到账户 |
| **SWIFT MT5xx** | 证券结算报文 | 跨境结算通信 |

---

## 8. PRD Review 检查清单

### 8.1 功能完整性

- [ ] 结算日计算是否正确处理了所有美国和香港的公众假期？
- [ ] 结算日计算是否处理了 HKEX 台风/暴雨临时休市的情况？
- [ ] 费用计算是否覆盖了所有费用类型（美股 4 种 + 港股 5 种）？
- [ ] 印花税的向上取整逻辑是否正确（港股：取整到 HK$1）？
- [ ] SEC Fee 的半年度费率更新是否有配置化支持？
- [ ] FINRA TAF 的 $8.30 上限是否实现？
- [ ] 企业行动是否覆盖：现金股息、股票拆分、反向拆分、合并、分拆、配股？
- [ ] 现金股息是否正确处理了非美居民的 15% 预扣税？
- [ ] 结算失败是否有明确的处理流程和告警机制？
- [ ] 三向对账是否每日执行且有明确的差异处理流程？

### 8.2 合规要求

- [ ] 结算周期是否正确：US T+1（2024年5月起）、HK T+2？
- [ ] 所有结算记录是否保留 7 年（SEC Rule 17a-4）？
- [ ] 结算记录是否为 append-only（WORM 要求）？
- [ ] Fail to Deliver 是否有 Buy-in 处理流程？
- [ ] 是否记录了完整的审计日志？
- [ ] 费用计算是否基于可配置的费率表（支持监管费率变更）？

### 8.3 资金安全

- [ ] 结算批处理是否幂等（中途失败重启不会重复处理）？
- [ ] 持仓更新是否使用乐观锁（version 字段）？
- [ ] 资金划转是否使用 idempotency key 防止重复？
- [ ] settled_qty 和 unsettled_qty 的更新是否在事务中完成？
- [ ] 对账差异 > $0.01 是否自动告警？
- [ ] 对账差异 > $100 是否暂停资金操作？
- [ ] 净结算金额计算是否使用 `shopspring/decimal`，而非 float64？

### 8.4 性能与可靠性

- [ ] 每日结算批处理是否能在 5 分钟内完成？
- [ ] 结算批处理是否使用分布式锁确保单节点执行？
- [ ] 对账是否能在 10 分钟内完成全量匹配？
- [ ] 是否有 dry_run 模式用于测试和验证？
- [ ] 结算失败是否有重试机制？
- [ ] 系统是否能处理跨时区的结算日期计算？

### 8.5 用户体验

- [ ] 用户是否能看到每笔成交的结算日期？
- [ ] 用户是否能区分 settled cash 和 unsettled cash？
- [ ] 用户是否能看到待结算的持仓数量？
- [ ] 企业行动是否在执行前通知用户？
- [ ] 结算完成后是否推送通知？
- [ ] 手续费明细是否在成交确认中展示？

---

## 9. 工程落地注意事项

### 9.1 数据库 Schema 关键点

基于当前迁移文件 `001_init_trading.sql`：

**executions 表的结算相关字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `settlement_date` | DATE | 结算日期，成交时由算法计算 |
| `settled` | BOOLEAN | 是否已结算 |
| `settled_at` | TIMESTAMPTZ | 结算完成时间 |
| `sec_fee` | NUMERIC(20,8) | SEC 费用（仅美股卖出） |
| `taf` | NUMERIC(20,8) | FINRA TAF（仅美股卖出） |
| `stamp_duty` | NUMERIC(20,8) | 印花税（仅港股） |
| `trading_levy` | NUMERIC(20,8) | SFC 征费（仅港股） |
| `trading_fee` | NUMERIC(20,8) | 交易所费（仅港股） |
| `platform_fee` | NUMERIC(20,8) | 平台费（仅港股） |
| `net_amount` | NUMERIC(20,8) | 净结算金额 |

**关键索引：**

```sql
-- 结算批处理的核心查询索引
-- Partial Index: 只索引未结算的记录，大幅提升查询效率
CREATE INDEX idx_exec_settlement ON executions (settlement_date, settled)
    WHERE settled = FALSE;
```

这个 Partial Index 是性能关键：随着时间推移，绝大多数记录都是 `settled = TRUE`，Partial Index 只包含未结算记录，索引体积小、查询快。

**positions 表的结算字段：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `settled_qty` | BIGINT | 已结算数量（可以卖出不违反 free-ride） |
| `unsettled_qty` | BIGINT | 未结算数量（近期买入，尚未结算） |
| `version` | INT | 乐观锁版本号 |

### 9.2 关键实现原则

#### 9.2.1 金额计算绝对禁止 float

```go
// 正确: 使用 shopspring/decimal
fee := tradeValue.Mul(decimal.NewFromString("0.0000278"))

// 错误: 绝对禁止!!! 会导致精度丢失
// fee := tradeValue * 0.0000278
```

这一点在 SEC Fee 的计算中尤为关键。SEC Fee 费率是 0.00278%（即 0.0000278），对于大额交易（如 $1,000,000 卖出），float64 的精度误差会导致收费错误。

#### 9.2.2 时区处理

```go
// 结算日计算必须在交易所当地时区进行
func CalculateSettlementDate(executedAt time.Time, market string) time.Time {
    var loc *time.Location
    switch market {
    case "US":
        loc, _ = time.LoadLocation("America/New_York")
    case "HK":
        loc, _ = time.LoadLocation("Asia/Hong_Kong")
    }

    // 先转换到交易所当地时间，确定交易日期
    localTime := executedAt.In(loc)
    tradeDate := localTime.Truncate(24 * time.Hour)

    // 然后按工作日历计算结算日
    settlementDate := addBusinessDays(tradeDate, getSettlementDays(market), getCalendar(market))

    // 存储为 UTC 日期（DATE 类型不含时区，但内部逻辑统一用 UTC）
    return settlementDate
}
```

#### 9.2.3 批处理的事务边界

```go
// 每个账户的结算在独立事务中完成
// 一个账户失败不影响其他账户
func (e *engine) ProcessDaily(ctx context.Context, settlementDate time.Time) error {
    executions, err := e.GetUnsettledExecutions(ctx, settlementDate)
    if err != nil {
        return fmt.Errorf("get unsettled executions for %s: %w", settlementDate, err)
    }

    // 按账户分组
    accountGroups := groupByAccount(executions)

    var failures []SettlementFailure
    for accountID, execs := range accountGroups {
        // 每个账户独立事务
        if err := e.settleAccount(ctx, accountID, execs); err != nil {
            failures = append(failures, SettlementFailure{
                AccountID: accountID,
                Reason:    err.Error(),
            })
            // 记录失败但继续处理其他账户
            logger.Error("settlement failed for account",
                zap.Int64("account_id", accountID),
                zap.Error(err),
            )
            continue
        }
    }

    if len(failures) > 0 {
        // 发送告警
        e.alertService.SendSettlementFailures(ctx, settlementDate, failures)
    }

    return nil
}
```

#### 9.2.4 分布式锁保证单实例执行

```go
// 结算批处理使用 Redis 分布式锁
// 确保即使部署多个实例，也只有一个在执行
func (e *engine) RunDailySettlement(ctx context.Context) error {
    lockKey := fmt.Sprintf("settlement:daily:%s:%s",
        time.Now().UTC().Format("2006-01-02"), e.market)

    lock, err := e.redisLock.Obtain(ctx, lockKey, 30*time.Minute, nil)
    if err != nil {
        return fmt.Errorf("failed to obtain settlement lock: %w", err)
    }
    defer lock.Release(ctx)

    return e.ProcessDaily(ctx, time.Now().UTC())
}
```

### 9.3 企业行动处理算法

#### 9.3.1 现金股息处理

```go
func (e *engine) ProcessDividend(ctx context.Context, action *CorporateAction) error {
    // 1. 获取 Ex-Date 前一日收盘时的持仓快照
    //    在 T+1 结算制度下，Record Date = Ex-Date
    //    持有人以 Ex-Date 前一个工作日收盘时的持仓为准
    positions, err := e.positionRepo.ListBySymbol(ctx, action.Symbol, action.Market)
    if err != nil {
        return fmt.Errorf("list positions for %s: %w", action.Symbol, err)
    }

    for _, pos := range positions {
        if pos.Quantity <= 0 {
            continue // 无持仓或空头不分红
        }

        // 2. 计算应收股息
        grossDividend := action.DividendPerShare.Mul(decimal.NewFromInt(pos.Quantity))

        // 3. 计算预扣税
        var taxWithheld decimal.Decimal
        if action.Market == "US" {
            // 非美居民 15% 预扣税（基于 W-8BEN）
            account, _ := e.accountService.Get(ctx, pos.AccountID)
            if account.TaxWithholdingRate.GreaterThan(decimal.Zero) {
                taxWithheld = grossDividend.Mul(account.TaxWithholdingRate)
            }
        }

        netDividend := grossDividend.Sub(taxWithheld)

        // 4. 在 PayDate 记录股息分配
        //    实际资金入账通过 Fund Transfer 服务
        err := e.recordDividend(ctx, DividendRecord{
            AccountID:      pos.AccountID,
            Symbol:         action.Symbol,
            Market:         action.Market,
            ExDate:         action.ExDate,
            PayDate:        action.PayDate,
            PositionQty:    pos.Quantity,
            DividendPerShare: action.DividendPerShare,
            Currency:       action.DividendCurrency,
            GrossAmount:    grossDividend,
            TaxWithheld:    taxWithheld,
            NetAmount:      netDividend,
        })
        if err != nil {
            return fmt.Errorf("record dividend for account %d: %w", pos.AccountID, err)
        }
    }

    return nil
}
```

**股息公式：**

```
应收股息总额 = 每股股息 x 除权日持仓数量
预扣税       = 应收股息总额 x 预扣税率
              （美股非美居民：15%，基于 W-8BEN 表格）
              （港股：0%，免税）
净到手股息   = 应收股息总额 - 预扣税
```

#### 9.3.2 股票拆分处理

```go
func (e *engine) ProcessStockSplit(ctx context.Context, action *CorporateAction) error {
    // 股票拆分在 Ex-Date 生效
    // SplitRatio: e.g., 4 表示 4:1 拆股（1股变4股）
    ratio := decimal.NewFromInt(int64(action.SplitRatio))

    positions, err := e.positionRepo.ListBySymbol(ctx, action.Symbol, action.Market)
    if err != nil {
        return fmt.Errorf("list positions for split %s: %w", action.Symbol, err)
    }

    for _, pos := range positions {
        if pos.Quantity == 0 {
            continue
        }

        // 事务内更新
        err := e.db.WithTransaction(ctx, func(tx *sql.Tx) error {
            // 1. 新数量 = 原数量 x 拆股比率
            newQuantity := pos.Quantity * int64(action.SplitRatio)

            // 2. 新成本基准 = 原成本基准 / 拆股比率
            //    总成本不变，只是每股成本降低
            newCostBasis := pos.AvgCostBasis.Div(ratio)

            // 3. 更新已结算和未结算数量
            newSettledQty := pos.SettledQty * int64(action.SplitRatio)
            newUnsettledQty := pos.UnsettledQty * int64(action.SplitRatio)

            // 4. 使用乐观锁更新
            return e.positionRepo.UpdateForSplit(ctx, tx, UpdateSplitRequest{
                AccountID:     pos.AccountID,
                Symbol:        pos.Symbol,
                Market:        pos.Market,
                NewQuantity:   newQuantity,
                NewCostBasis:  newCostBasis,
                NewSettledQty: newSettledQty,
                NewUnsettledQty: newUnsettledQty,
                ExpectedVersion: pos.Version,
            })
        })

        if err != nil {
            return fmt.Errorf("update position for split, account %d: %w", pos.AccountID, err)
        }
    }

    return nil
}
```

**股票拆分公式：**

```
新持仓数量     = 原持仓数量 x 拆股比率
新成本基准     = 原成本基准 / 拆股比率
新已结算数量   = 原已结算数量 x 拆股比率
新未结算数量   = 原未结算数量 x 拆股比率

验证: 新持仓数量 x 新成本基准 = 原持仓数量 x 原成本基准（总成本不变）

反向拆股（Reverse Split）:
新持仓数量     = 原持仓数量 / 合并比率（取整，余数以现金返还）
新成本基准     = 原成本基准 x 合并比率
```

### 9.4 Prometheus 监控指标

```go
// 结算引擎关键监控指标
var (
    // 结算批处理
    settlementBatchDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "settlement_batch_duration_seconds",
            Help:    "Duration of daily settlement batch processing",
            Buckets: []float64{10, 30, 60, 120, 300},
        },
        []string{"market"},
    )

    settlementExecutionsProcessed = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "settlement_executions_processed_total",
            Help: "Total number of executions settled",
        },
        []string{"market", "status"}, // status: "success" or "failed"
    )

    settlementFailures = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "settlement_failures_total",
            Help: "Total number of settlement failures",
        },
        []string{"market", "reason"},
    )

    // 对账
    reconciliationDiscrepancies = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "reconciliation_discrepancies",
            Help: "Number of reconciliation discrepancies",
        },
        []string{"market", "type"},
    )

    reconciliationBalanceDiff = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "reconciliation_balance_difference",
            Help: "Balance difference found in reconciliation",
        },
        []string{"market", "currency"},
    )

    // 企业行动
    corporateActionsProcessed = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "corporate_actions_processed_total",
            Help: "Total corporate actions processed",
        },
        []string{"market", "action_type", "status"},
    )

    // 未结算数量
    unsettledExecutionsGauge = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "unsettled_executions_count",
            Help: "Current number of unsettled executions",
        },
        []string{"market"},
    )
)
```

### 9.5 测试策略

| 测试类型 | 覆盖范围 | 关键场景 |
|---------|---------|---------|
| **单元测试** | 费用计算、结算日计算 | 各种费率组合、假日边界、闰年 |
| **集成测试** | 完整结算流程 | 批处理 -> 资金划转 -> 状态更新 |
| **对账测试** | 三向对账 | 模拟差异场景 |
| **企业行动测试** | 股息/拆分/配股 | 零持仓、负持仓、大量账户 |
| **性能测试** | 批处理耗时 | 10 万笔成交的批处理 |
| **故障测试** | 中途失败和恢复 | 事务回滚、幂等重试 |
| **精度测试** | 金额计算精度 | 大额交易的 SEC Fee 精度 |

**关键测试用例：**

```go
// 测试1: 美股卖出费用计算精度
func TestUSSellingFees_LargeAmount(t *testing.T) {
    // 卖出 10,000 股 @ $500.00 = $5,000,000
    fees := calculator.CalculateUS("SELL", 10000, decimal.NewFromFloat(500.00))

    assert.Equal(t, "50.00", fees.Commission.StringFixed(2))          // 10000 x $0.005
    assert.Equal(t, "30.00", fees.ExchangeFee.StringFixed(2))         // 10000 x $0.003
    assert.Equal(t, "139.00", fees.SECFee.StringFixed(2))             // $5M x 0.0000278 = $139.00
    assert.Equal(t, "1.66", fees.FINRATAF.StringFixed(2))             // 10000 x $0.000166
}

// 测试2: 港股印花税向上取整
func TestHKStampDuty_CeilToHKD(t *testing.T) {
    // 买入 100 股 @ HK$100.50 = HK$10,050
    fees := calculator.CalculateHK("BUY", 100, decimal.NewFromFloat(100.50))

    // 印花税 = CEIL(HK$10,050 x 0.0013) = CEIL(HK$13.065) = HK$14
    assert.Equal(t, "14.00", fees.StampDuty.StringFixed(2))
}

// 测试3: 结算日跨假日计算
func TestSettlementDate_USHoliday(t *testing.T) {
    // 周四感恩节前一天（周三）交易 → T+1 = 感恩节后的周五
    // 2026年感恩节: Nov 26 (Thu)
    tradeDate := time.Date(2026, 11, 25, 0, 0, 0, 0, time.UTC) // Wed
    settlementDate := CalculateSettlementDate(tradeDate, "US")
    // 周四是感恩节（假日），跳过 → 周五
    expected := time.Date(2026, 11, 27, 0, 0, 0, 0, time.UTC) // Fri
    assert.Equal(t, expected, settlementDate)
}

// 测试4: 股票拆分后总成本不变
func TestStockSplit_TotalCostInvariant(t *testing.T) {
    original := Position{
        Quantity:     100,
        AvgCostBasis: decimal.NewFromFloat(400.00), // 总成本 = $40,000
    }
    splitRatio := 4 // 4:1 拆股

    newQty := original.Quantity * int64(splitRatio)                        // 400
    newCost := original.AvgCostBasis.Div(decimal.NewFromInt(int64(splitRatio))) // $100

    // 验证总成本不变
    originalTotal := original.AvgCostBasis.Mul(decimal.NewFromInt(original.Quantity))
    newTotal := newCost.Mul(decimal.NewFromInt(newQty))
    assert.True(t, originalTotal.Equal(newTotal))
}
```

### 9.6 上线检查清单

- [ ] fee_configs 表已导入所有市场的费率数据
- [ ] 美国和香港的工作日历已加载至少未来 2 年的假日数据
- [ ] 结算批处理的 Cron Job 已配置（US: 每日 21:00 UTC / HK: 每日 10:00 UTC）
- [ ] Redis 分布式锁配置正确，TTL 足够长
- [ ] Kafka topics 已创建：`trading.settlement`, `settlement.fund_transfer`
- [ ] Fund Transfer 服务已实现 settlement fund transfer 的消费者
- [ ] 对账报告的告警已接入运维告警系统
- [ ] WORM 存储（S3 Object Lock）已配置，用于结算记录归档
- [ ] 已执行至少 1 轮完整的端到端测试（含模拟交易和结算）
- [ ] 已验证 dry_run 模式可正确计算而不实际执行
- [ ] Prometheus 监控面板已创建
- [ ] 运营手册已编写：结算失败处理 SOP、对账差异处理 SOP
