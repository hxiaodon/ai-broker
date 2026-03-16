# 合规审计（Compliance & Audit Trail）深度调研

> 美港股券商交易 APP -- 监管合规与审计追踪系统全景

---

## 1. 业务概述

### 1.1 合规审计的核心使命

在证券交易领域，合规审计不是"锦上添花"的功能，而是系统存在的法律基础。没有完善的审计追踪系统，券商将面临吊销牌照的风险。合规审计系统承担以下核心使命：

1. **完整记录（Complete Record-Keeping）**：每一笔订单从创建到终态的完整生命周期，必须以不可篡改的方式永久保存
2. **监管上报（Regulatory Reporting）**：按照 SEC/FINRA（美国）和 SFC/HKEX（香港）的要求，定期或实时上报交易数据
3. **可疑交易监控（Suspicious Activity Monitoring）**：检测内幕交易、市场操纵、洗钱等违规行为
4. **合规检查（Compliance Checks）**：PDT 规则、Short Sale 限制、Order Protection Rule 等
5. **数据保留（Data Retention）**：满足 7 年保留要求（SEC Rule 17a-4），使用 WORM 存储
6. **审计响应（Audit Response）**：当监管机构要求检查时，能够快速、准确地提供所需数据

### 1.2 合规审计的法律基础

| 监管机构 | 法律/规则 | 核心要求 |
|---------|----------|---------|
| **SEC** | Securities Exchange Act of 1934 | 证券交易的基本法律框架 |
| **SEC** | Rule 17a-4 | 记录保留：7 年 WORM 存储 |
| **SEC** | Rule 17a-3 | 必须保留的记录类型清单 |
| **SEC** | Regulation SHO | Short Sale 限制和报告 |
| **SEC** | Regulation NMS | 最佳执行义务和Order Protection |
| **FINRA** | Rule 3110 | 监管系统要求 |
| **FINRA** | Rule 4511 | 账簿和记录要求 |
| **FINRA** | CAT NMS Plan | Consolidated Audit Trail 上报 |
| **SFC** | Securities and Futures Ordinance (Cap. 571) | 香港证券法核心法规 |
| **SFC** | Code of Conduct | 持牌机构行为准则 |
| **SFC** | AML Guidelines | 反洗钱指引 |
| **HKEX** | Trading Rules | 交易规则和报告要求 |

### 1.3 审计追踪的完整范围

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     Compliance & Audit Trail Scope                       │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Layer 1: 订单生命周期审计                                          │  │
│  │  • 订单创建 → 校验 → 风控 → 路由 → 交易所确认 → 成交 → 结算        │  │
│  │  • 每个状态转换都产生一个 immutable event                           │  │
│  │  • 包含完整上下文：时间戳、操作者、IP、设备                           │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Layer 2: 监管报告                                                  │  │
│  │  • CAT（Consolidated Audit Trail）每日上报                          │  │
│  │  • TRF（Trade Reporting Facility）成交报告                          │  │
│  │  • STR（Suspicious Transaction Report）可疑交易报告                  │  │
│  │  • 蓝表/绿表（Blue Sheet / Green Sheet）按需提交                    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Layer 3: 合规规则引擎                                               │  │
│  │  • PDT 规则跟踪和执行                                               │  │
│  │  • Reg SHO Short Sale 限制                                         │  │
│  │  • Reg NMS Order Protection Rule                                   │  │
│  │  • Market Access Rule (SEC 15c3-5)                                 │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Layer 4: 市场监控与异常检测                                         │  │
│  │  • 内幕交易模式检测                                                 │  │
│  │  • Wash Trading 检测                                               │  │
│  │  • Spoofing / Layering 检测                                        │  │
│  │  • 大额交易预警                                                     │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Layer 5: 数据保留与归档                                             │  │
│  │  • 7 年 WORM 存储（SEC Rule 17a-4）                                │  │
│  │  • Hot → Warm → Cold 分层存储                                      │  │
│  │  • PII 脱敏和加密                                                   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 监管与合规要求

### 2.1 SEC Rule 17a-4: 记录保留的黄金标准

SEC Rule 17a-4 是证券行业记录保留的核心法规。对于电子记录，有以下关键要求：

#### 保留期限

| 记录类型 | 保留期限 | 具体内容 |
|---------|---------|---------|
| 订单和成交记录 | 7 年（前 2 年需即时可访问） | 所有订单创建、修改、取消、成交的完整记录 |
| 账户记录 | 6 年（关户后） | 开户信息、KYC 文档、账户变更历史 |
| 通信记录 | 3 年 | 与客户的所有通信（邮件、消息、通话记录） |
| 合规报告 | 7 年 | 内部合规检查报告、例外报告 |
| 审计日志 | 7 年 | 系统操作日志、访问日志、变更日志 |

#### WORM 存储要求

**Write Once Read Many (WORM)** 是 SEC 17a-4 的核心技术要求：

- 记录一旦写入，**不可修改、不可删除**
- 必须在保留期内维持记录的完整性
- 即使系统管理员也不能删除或篡改记录
- 2003 年 SEC 解释性发布（Release No. 34-47806）明确了电子存储的 WORM 要求

**合规的存储方案：**

| 方案 | WORM 合规 | 说明 |
|------|----------|------|
| AWS S3 Object Lock（Compliance Mode） | 是 | 锁定后即使 root 用户也无法删除 |
| AWS S3 Object Lock（Governance Mode） | 部分 | 特定 IAM 权限可覆盖，不满足严格的 17a-4 |
| Azure Immutable Blob Storage | 是 | 类似 S3 Object Lock |
| 专用 WORM 存储设备（如 NetApp SnapLock） | 是 | 传统合规存储方案 |
| PostgreSQL append-only 表 | 否 | 数据库管理员可以删除，不满足 17a-4 |

**关键结论：** `order_events` 表虽然设计为 append-only，但数据库本身不满足 WORM 要求。必须将记录额外归档到 S3 Object Lock 或等效存储。

#### SEC 2023 修订

2023 年 SEC 修订了 Rule 17a-4（Release No. 34-96858），关键变化：

- **Audit Trail 要求增强**：必须记录电子记录系统的所有访问和修改尝试
- **第三方验证**：如果使用第三方存储服务，必须获得服务提供商的合规认证
- **灾备要求**：WORM 记录必须有地理冗余备份

### 2.2 CAT（Consolidated Audit Trail）

CAT 是 FINRA/SEC 在 2012 年批准、2020 年开始实施的统一审计追踪系统，取代了旧的 OATS（Order Audit Trail System）。

#### CAT 上报范围

所有在 NMS（National Market System）交易所交易的证券都必须上报：

| 上报事件 | 时间要求 | 数据精度 |
|---------|---------|---------|
| 新订单接收 | T+1 日 08:00 ET 前 | 微秒级时间戳 |
| 订单路由（发送到交易所） | T+1 日 08:00 ET 前 | 微秒级时间戳 |
| 订单修改 | T+1 日 08:00 ET 前 | 微秒级时间戳 |
| 订单取消 | T+1 日 08:00 ET 前 | 微秒级时间戳 |
| 成交确认 | T+1 日 08:00 ET 前 | 微秒级时间戳 |

#### CAT 数据字段

```
CAT 上报记录必须包含:

┌────────────────────────────────────────────────────────────────┐
│  Order Event (新订单)                                          │
│                                                                │
│  - eventTimestamp: "2026-03-16T09:30:00.123456Z"  (微秒精度)   │
│  - orderID: 内部订单 ID                                        │
│  - CATReporterIMID: 券商的 IMID（Industry Member ID）          │
│  - fdidCustomer: FDID（Firm Designated ID，客户标识符）         │
│  - symbol: "AAPL"                                             │
│  - side: "B" (Buy) / "S" (Sell) / "SS" (Short Sell)          │
│  - orderType: "LMT" / "MKT" / "STP" / ...                    │
│  - price: "150.2500" (4位小数)                                 │
│  - quantity: 100                                               │
│  - timeInForce: "DAY" / "GTC" / "IOC" / ...                  │
│  - tradingSession: "REG" / "PREMARKET" / "POSTMARKET"         │
│  - handlingInstructions: 路由指令                                │
│  - routedOrderID: (如果路由到其他 venue)                        │
│  - senderIMID: 下单方 IMID                                     │
│  - destination: 目标交易所                                      │
│  - originatingIMID: 最初接收订单的 IMID                         │
│                                                                │
│  注意: 不上报真实客户姓名/SSN，使用 FDID 匿名标识               │
└────────────────────────────────────────────────────────────────┘
```

#### CAT 文件格式

CAT 使用 JSON Lines 格式上传（`.json` 文件，每行一个 JSON 对象），通过 SFTP 上传到 FINRA CAT Reporter Portal。

```json
{"actionType":"NEW","eventTimestamp":"2026-03-16T09:30:00.123456Z","orderID":"ORD-001","CATReporterIMID":"BRKR","symbol":"AAPL","side":"B","orderType":"LMT","price":"150.2500","quantity":100,"timeInForce":"DAY","fdidCustomer":"FDID-12345","tradingSession":"REG","handlingInstructions":"ALGO","destination":"XNYS","senderIMID":"BRKR"}
{"actionType":"ROUTE","eventTimestamp":"2026-03-16T09:30:00.234567Z","orderID":"ORD-001","routedOrderID":"ROUT-001","CATReporterIMID":"BRKR","symbol":"AAPL","side":"B","destination":"XNYS","quantity":100,"price":"150.2500"}
{"actionType":"FILL","eventTimestamp":"2026-03-16T09:30:01.345678Z","orderID":"ORD-001","CATReporterIMID":"BRKR","symbol":"AAPL","side":"B","fillQuantity":100,"fillPrice":"150.2400","venue":"XNYS"}
```

#### CAT 时间精度要求

**这是一个关键的工程挑战：**

- CAT 要求所有时间戳精确到**微秒**（即 `2026-03-16T09:30:00.123456Z`）
- 系统内部时钟必须与 NIST 时间源同步
- 时钟偏差不得超过 50 毫秒（FINRA CAT Clock Offset Requirements）
- Go 中 `time.Time` 支持纳秒精度，满足要求
- 当前代码中 `Order.CreatedAt` 使用 `int64`（Unix nanos），满足精度要求

**NTP 同步要求：**

```
系统时钟同步链路:

NIST Atomic Clock → NTP Server (stratum 1) → 系统服务器 (stratum 2/3)
                                                  │
                                                  ▼
                                            偏差 < 50ms

推荐方案:
- 使用 AWS Time Sync Service（基于卫星和原子钟）
- 或自建 NTP 集群，对接 NIST 或其他 stratum 1 源
- 定期校验和记录时钟偏差
```

### 2.3 香港 SFC 审计要求

#### SFC 证券及期货条例要求

| 要求 | 具体内容 |
|------|---------|
| **交易记录保留** | 所有订单和成交记录保留 6 年 |
| **账户记录保留** | 客户账户记录保留至关闭后 6 年 |
| **通信记录** | 与客户的交易相关通信保留 7 年 |
| **审计日志** | 系统访问和操作日志保留 7 年 |
| **可疑交易报告** | 发现可疑交易后 3 个工作日内向 JFIU 报告 |

#### STR（Suspicious Transaction Report）上报

香港的可疑交易报告上报给 JFIU（Joint Financial Intelligence Unit），联合 SFC 和 HKPF（Hong Kong Police Force）的金融情报部门。

触发 STR 的情景：

| 场景 | 描述 | 检测方法 |
|------|------|---------|
| **异常交易模式** | 在重大公告前大量买入/卖出 | 时间序列异常检测 |
| **频繁对倒** | 同一人/关联人之间频繁买卖同一标的 | 交易对手分析 |
| **洗售交易** | 快速买入卖出，无经济目的 | 短时间内同标的正反交易检测 |
| **大额现金交易** | 大额存款后立即用于交易 | 资金流向分析 |
| **账户行为异常** | 长期不活跃账户突然大量交易 | 行为基线偏差检测 |
| **结构化交易** | 拆分交易以规避报告阈值 | Structuring Pattern 检测 |

### 2.4 PDT（Pattern Day Trader）合规追踪

PDT 规则是美国特有的监管要求，对日内交易者施加额外限制。

#### 规则定义

```
PDT 规则（FINRA Rule 4210）:

条件:
- 保证金账户（Margin Account）
- 在 5 个连续工作日内执行 4 次或以上的日内交易
- 日内交易 = 同一标的在同一交易日内买入和卖出（或卖空后回补）

触发后果:
- 账户被标记为 Pattern Day Trader
- 必须维持最低 $25,000 的账户净值
- 如果净值低于 $25,000:
  → 限制日内交易（仅允许平仓卖出）
  → 直到账户净值恢复到 $25,000 以上

豁免:
- 现金账户不受 PDT 限制（但受 T+1 结算限制，可能触发 Free-Ride Violation）
- 净值 >= $25,000 的保证金账户可以无限制日内交易
```

#### 数据库追踪

当前 Schema 中已有 `day_trade_counts` 表：

```sql
CREATE TABLE day_trade_counts (
    id          BIGSERIAL PRIMARY KEY,
    account_id  BIGINT NOT NULL,
    trade_date  DATE NOT NULL,
    symbol      TEXT NOT NULL,
    count       INT NOT NULL DEFAULT 1,
    UNIQUE (account_id, trade_date, symbol)
);

CREATE INDEX idx_day_trades_account ON day_trade_counts (account_id, trade_date DESC);
```

#### PDT 检测算法

```go
// 判断一笔交易是否构成日内交易
func (s *pdtService) WouldCreateDayTrade(ctx context.Context, ord *order.Order) (bool, error) {
    if ord.Market != "US" {
        return false, nil // 仅适用于美股
    }

    today := time.Now().In(estLocation).Truncate(24 * time.Hour)

    if ord.Side == order.SideBuy {
        // 买入: 检查今天是否有同标的的卖出成交
        sellCount, err := s.repo.CountTodayExecutions(ctx, ord.AccountID, ord.Symbol, "SELL", today)
        if err != nil {
            return false, fmt.Errorf("count today sells: %w", err)
        }
        return sellCount > 0, nil
    }

    // 卖出: 检查今天是否有同标的的买入成交
    buyCount, err := s.repo.CountTodayExecutions(ctx, ord.AccountID, ord.Symbol, "BUY", today)
    if err != nil {
        return false, fmt.Errorf("count today buys: %w", err)
    }
    return buyCount > 0, nil
}

// 统计过去 N 个工作日的日内交易次数
func (s *pdtService) CountDayTrades(ctx context.Context, accountID int64, businessDays int) (int, error) {
    startDate := subtractBusinessDays(time.Now(), businessDays, USCalendar)

    // 从 day_trade_counts 表统计
    total, err := s.repo.SumDayTrades(ctx, accountID, startDate)
    if err != nil {
        return 0, fmt.Errorf("sum day trades since %s: %w", startDate, err)
    }
    return total, nil
}
```

---

## 3. 市场差异（US vs HK）

### 3.1 审计要求对比

| 维度 | 美国 (SEC/FINRA) | 香港 (SFC/HKEX) |
|------|-----------------|-----------------|
| **核心法规** | Rule 17a-3, 17a-4 | Securities and Futures Ordinance |
| **审计追踪系统** | CAT（取代 OATS） | 无统一审计追踪系统，但要求可审计 |
| **上报频率** | 每日（T+1 日 08:00 ET 前） | 按需（监管调查时提供） |
| **时间精度** | 微秒（CAT 要求） | 毫秒（实践中足够） |
| **记录保留** | 7 年 WORM | 6 年可审计记录 |
| **可疑交易报告** | SAR 向 FinCEN 报告 | STR 向 JFIU 报告 |
| **上报格式** | JSON Lines → SFTP | PDF/Excel → SFC 在线系统 |
| **客户标识** | FDID（匿名化） | 真实账户信息 |
| **日内交易限制** | PDT 规则（$25K 最低） | 无 |
| **Short Sale 报告** | Reg SHO / Short Interest Reporting | 卖空头寸申报 |
| **Best Execution** | Reg NMS Order Protection Rule | SFC Code of Conduct 3.1 |

### 3.2 时间戳精度差异

```
美股要求:
┌────────────────────────────────────────────────────────┐
│  CAT Timestamp: 2026-03-16T09:30:00.123456Z           │
│                                        ^^^^^^          │
│                                        微秒精度         │
│                                                        │
│  Go 实现: time.Now().UTC()                              │
│  存储: Unix nanoseconds (int64)                         │
│  输出: time.Format("2006-01-02T15:04:05.000000Z")      │
│                                                        │
│  时钟同步: NTP, 偏差 < 50ms                              │
└────────────────────────────────────────────────────────┘

港股要求:
┌────────────────────────────────────────────────────────┐
│  Timestamp: 2026-03-16T09:30:00.123Z                   │
│                                  ^^^                    │
│                                  毫秒精度足够             │
│                                                        │
│  实践中也使用微秒，因为系统统一处理                         │
│  无严格的 NTP 偏差要求，但良好实践建议 < 100ms             │
└────────────────────────────────────────────────────────┘
```

### 3.3 报告义务差异

#### 美股特有报告

| 报告 | 频率 | 内容 |
|------|------|------|
| **CAT Reports** | 每日 | 全量订单和成交事件 |
| **Short Interest Report** | 每月两次 | 空头头寸汇总 |
| **Blue Sheet** | 按需 | SEC 调查时要求的交易详细数据 |
| **Large Trader Report (Form 13H)** | 按需 | 大额交易者身份信息 |
| **SAR (Suspicious Activity Report)** | 发现后 30 天内 | 向 FinCEN 报告可疑活动 |

#### 港股特有报告

| 报告 | 频率 | 内容 |
|------|------|------|
| **STR (Suspicious Transaction Report)** | 发现后 3 个工作日 | 向 JFIU 报告可疑交易 |
| **卖空头寸申报** | 每周 | 净空头头寸超过阈值的标的 |
| **大额交易申报** | 按需 | 单笔成交超过一定金额 |
| **关联交易报告** | 按需 | 涉及关联方的交易 |

---

## 4. 技术架构

### 4.1 审计追踪系统架构

```
┌──────────────────────────────────────────────────────────────────────────┐
│                  Compliance & Audit Trail Architecture                    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │  Event Source Layer (事件产生层)                                     │  │
│  │                                                                    │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────────┐   │  │
│  │  │  Order   │ │ Risk     │ │ Position │ │ Settlement         │   │  │
│  │  │  Service │ │ Engine   │ │ Engine   │ │ Engine             │   │  │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬───────────┘   │  │
│  │       │            │            │                 │               │  │
│  │       ▼            ▼            ▼                 ▼               │  │
│  │  ┌────────────────────────────────────────────────────────────┐   │  │
│  │  │              Audit Event Producer                           │   │  │
│  │  │  (统一的审计事件生产者，确保所有状态变更都被记录)               │   │  │
│  │  └────────────────────────┬───────────────────────────────────┘   │  │
│  └───────────────────────────┼──────────────────────────────────────┘  │
│                              │                                        │
│                              ▼                                        │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │  Event Bus (Kafka)                                                ││
│  │                                                                    ││
│  │  Topics:                                                          ││
│  │  • trading.order_events    (订单事件，主审计流)                     ││
│  │  • trading.risk_events     (风控事件)                              ││
│  │  • trading.settlement      (结算事件)                              ││
│  │  • trading.compliance      (合规事件)                              ││
│  │                                                                    ││
│  │  特性:                                                             ││
│  │  • Log compaction OFF (保留所有消息)                                ││
│  │  • Retention: 90 days (Hot storage)                               ││
│  │  • 之后归档到 S3 Object Lock                                      ││
│  └──────────────┬───────────┬────────────┬───────────────────────────┘│
│                 │           │            │                            │
│          ┌──────┘     ┌─────┘      ┌─────┘                           │
│          ▼            ▼            ▼                                  │
│  ┌─────────────┐ ┌──────────┐ ┌──────────────┐                      │
│  │ PostgreSQL  │ │Elastic-  │ │ S3 Object    │                      │
│  │ order_events│ │search    │ │ Lock (WORM)  │                      │
│  │ (primary    │ │(search   │ │ (7-year      │                      │
│  │  store)     │ │ & query) │ │  archive)    │                      │
│  └─────────────┘ └──────────┘ └──────────────┘                      │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  Compliance Service (合规服务)                                   │  │
│  │                                                                │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────────────────┐ │  │
│  │  │ CAT Report   │ │ Surveillance │ │ Compliance Dashboard   │ │  │
│  │  │ Generator    │ │ Engine       │ │ (Admin Panel)          │ │  │
│  │  │              │ │              │ │                        │ │  │
│  │  │ 每日生成     │ │ 实时监控     │ │ 查询/导出/告警          │ │  │
│  │  │ CAT 文件     │ │ 异常交易     │ │ 管理界面              │ │  │
│  │  └──────────────┘ └──────────────┘ └────────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 4.2 Event Sourcing 模型

系统采用 Event Sourcing 模式，`order_events` 表是核心审计存储。

#### 当前 Schema（来自 `001_init_trading.sql`）

```sql
CREATE TABLE order_events (
    id          BIGSERIAL PRIMARY KEY,
    event_id    UUID UNIQUE NOT NULL,
    order_id    UUID NOT NULL,
    event_type  TEXT NOT NULL,
    event_data  JSONB NOT NULL,
    sequence    INT NOT NULL,         -- 同一订单内的事件序号
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_events_order ON order_events (order_id, sequence);
CREATE INDEX idx_order_events_type ON order_events (event_type, created_at DESC);
```

#### 事件类型清单

| event_type | 触发时机 | 说明 |
|-----------|---------|------|
| `ORDER_CREATED` | 订单创建 | 包含完整订单参数 |
| `ORDER_VALIDATED` | 校验通过 | 格式校验结果 |
| `ORDER_VALIDATION_FAILED` | 校验失败 | 失败原因 |
| `RISK_CHECK_PASSED` | 风控通过 | 所有风控检查结果 |
| `RISK_CHECK_FAILED` | 风控拒绝 | 拒绝原因和具体检查项 |
| `ORDER_SUBMITTED` | 发送到交易所 | FIX 消息 ID、目标交易所 |
| `ORDER_ACKNOWLEDGED` | 交易所确认 | 交易所 Order ID |
| `ORDER_PARTIALLY_FILLED` | 部分成交 | 成交数量、价格、交易所 Execution ID |
| `ORDER_FILLED` | 全部成交 | 最终平均价格、总费用 |
| `CANCEL_REQUESTED` | 用户请求取消 | 取消原因 |
| `CANCEL_SENT` | 取消已发送 | FIX Cancel Request ID |
| `ORDER_CANCELLED` | 取消确认 | 取消后的剩余数量 |
| `ORDER_REJECTED` | 内部拒绝 | 拒绝原因（风控/校验） |
| `EXCHANGE_REJECTED` | 交易所拒绝 | 交易所拒绝原因码 |
| `ORDER_EXPIRED` | 订单过期 | DAY 订单收盘后过期 |

#### event_data JSONB 结构

每种事件类型的 `event_data` 都有特定的 JSON 结构。以下是各类型的完整定义：

**ORDER_CREATED:**

```json
{
  "event_type": "ORDER_CREATED",
  "timestamp": "2026-03-16T09:30:00.123456Z",
  "actor_id": "user-12345",
  "actor_type": "CUSTOMER",
  "resource_type": "ORDER",
  "resource_id": "ord-001-uuid",
  "details": {
    "client_order_id": "client-uuid",
    "symbol": "AAPL",
    "market": "US",
    "exchange": "",
    "side": "BUY",
    "order_type": "LIMIT",
    "time_in_force": "DAY",
    "quantity": 100,
    "price": "150.2500",
    "stop_price": "0",
    "trail_amount": "0",
    "idempotency_key": "idem-uuid"
  },
  "ip_address": "203.0.113.42",
  "device_id": "iphone-14-pro-uuid",
  "source": "IOS",
  "correlation_id": "req-abc-123"
}
```

**RISK_CHECK_PASSED:**

```json
{
  "event_type": "RISK_CHECK_PASSED",
  "timestamp": "2026-03-16T09:30:00.125200Z",
  "actor_id": "system",
  "actor_type": "SYSTEM",
  "resource_type": "ORDER",
  "resource_id": "ord-001-uuid",
  "details": {
    "checks": [
      {"name": "AccountCheck", "result": "PASS", "duration_us": 120},
      {"name": "SymbolCheck", "result": "PASS", "duration_us": 85},
      {"name": "BuyingPowerCheck", "result": "PASS", "duration_us": 340,
       "buying_power": "52340.50", "estimated_cost": "15083.00"},
      {"name": "PositionLimitCheck", "result": "PASS", "duration_us": 95},
      {"name": "OrderRateCheck", "result": "PASS", "duration_us": 45},
      {"name": "PDTCheck", "result": "PASS", "duration_us": 210,
       "day_trade_count": 1, "would_create_day_trade": false},
      {"name": "MarginCheck", "result": "PASS", "duration_us": 180}
    ],
    "total_duration_us": 1075,
    "warnings": []
  },
  "ip_address": "203.0.113.42",
  "device_id": "iphone-14-pro-uuid",
  "source": "IOS",
  "correlation_id": "req-abc-123"
}
```

**RISK_CHECK_FAILED:**

```json
{
  "event_type": "RISK_CHECK_FAILED",
  "timestamp": "2026-03-16T09:30:00.125200Z",
  "actor_id": "system",
  "actor_type": "SYSTEM",
  "resource_type": "ORDER",
  "resource_id": "ord-002-uuid",
  "details": {
    "failed_check": "BuyingPowerCheck",
    "reason": "insufficient buying power: need 152,340.00, available 12,500.00",
    "checks_completed": [
      {"name": "AccountCheck", "result": "PASS"},
      {"name": "SymbolCheck", "result": "PASS"},
      {"name": "BuyingPowerCheck", "result": "FAIL",
       "buying_power": "12500.00", "estimated_cost": "152340.00"}
    ],
    "total_duration_us": 545
  },
  "ip_address": "203.0.113.42",
  "device_id": "iphone-14-pro-uuid",
  "source": "IOS",
  "correlation_id": "req-def-456"
}
```

**ORDER_PARTIALLY_FILLED:**

```json
{
  "event_type": "ORDER_PARTIALLY_FILLED",
  "timestamp": "2026-03-16T09:30:01.345678Z",
  "actor_id": "system",
  "actor_type": "EXCHANGE",
  "resource_type": "ORDER",
  "resource_id": "ord-001-uuid",
  "details": {
    "execution_id": "exec-uuid",
    "exchange_exec_id": "NYSE-EXEC-12345",
    "venue": "NYSE",
    "last_qty": 50,
    "last_price": "150.2400",
    "cumulative_qty": 50,
    "avg_price": "150.2400",
    "leaves_qty": 50,
    "commission": "0.25",
    "fees": {
      "exchange_fee": "0.15"
    }
  },
  "correlation_id": "req-abc-123"
}
```

### 4.3 PII 脱敏规则

在日志和审计记录中，PII（Personally Identifiable Information）必须按照以下规则脱敏：

```
┌──────────────────────────────────────────────────────────────────┐
│                     PII Masking Rules                              │
│                                                                    │
│  字段              原始值                    脱敏后                  │
│  ─────────────────────────────────────────────────────────────── │
│  SSN              "123-45-6789"             "***-**-6789"         │
│  HKID             "A123456(7)"              "A****(7)"            │
│  银行账号          "6222021234567890"         "****7890"            │
│  邮箱              "john@example.com"         "j***@example.com"   │
│  电话              "+852-9876-5432"           "+852-****-5432"      │
│  姓名              "张三"                     不脱敏（审计需要）      │
│  IP 地址           "203.0.113.42"             不脱敏（审计需要）      │
│  设备 ID           "iphone-14-uuid"           不脱敏（审计需要）      │
│  订单 ID           "ord-001-uuid"             不脱敏（审计需要）      │
│  账户 ID           12345                      不脱敏（审计需要）      │
│                                                                    │
│  注意:                                                              │
│  • 审计日志中保留 IP 和设备 ID（监管需要）                            │
│  • 应用日志（stdout/Elasticsearch）中也必须脱敏 PII                  │
│  • Kafka 消息中不应包含 SSN/HKID/银行账号                           │
│  • CAT 上报使用 FDID 而非真实身份信息                                │
└──────────────────────────────────────────────────────────────────┘
```

**Go 脱敏工具实现：**

```go
// masker.go - PII 脱敏工具
package audit

import (
    "regexp"
    "strings"
)

// MaskSSN 脱敏 SSN: "123-45-6789" → "***-**-6789"
func MaskSSN(ssn string) string {
    if len(ssn) < 4 {
        return "****"
    }
    return "***-**-" + ssn[len(ssn)-4:]
}

// MaskHKID 脱敏 HKID: "A123456(7)" → "A****(7)"
func MaskHKID(hkid string) string {
    if len(hkid) < 4 {
        return "****"
    }
    return string(hkid[0]) + "****" + hkid[len(hkid)-3:]
}

// MaskBankAccount 脱敏银行账号: "6222021234567890" → "****7890"
func MaskBankAccount(account string) string {
    if len(account) < 4 {
        return "****"
    }
    return "****" + account[len(account)-4:]
}

// MaskEmail 脱敏邮箱: "john@example.com" → "j***@example.com"
func MaskEmail(email string) string {
    parts := strings.SplitN(email, "@", 2)
    if len(parts) != 2 || len(parts[0]) < 1 {
        return "****@****"
    }
    return string(parts[0][0]) + "***@" + parts[1]
}

// SanitizeLogField 检查字段名是否为 PII，如果是则脱敏
// 用于结构化日志的 zap Field 处理
var piiFieldPatterns = map[string]func(string) string{
    "ssn":          MaskSSN,
    "tax_id":       MaskSSN,
    "hkid":         MaskHKID,
    "bank_account": MaskBankAccount,
    "email":        MaskEmail,
}

func SanitizeLogValue(fieldName, value string) string {
    for pattern, masker := range piiFieldPatterns {
        if strings.Contains(strings.ToLower(fieldName), pattern) {
            return masker(value)
        }
    }
    return value
}
```

### 4.4 WORM 存储实现

```
┌────────────────────────────────────────────────────────────────────┐
│              Data Lifecycle & WORM Archive Pipeline                  │
│                                                                    │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────────┐ │
│  │  Hot      │    │  Warm    │    │  Cold    │    │  Archive     │ │
│  │  Storage  │───▶│  Storage │───▶│  Storage │───▶│  (WORM)      │ │
│  │           │    │          │    │          │    │              │ │
│  │ PostgreSQL│    │Elastic-  │    │S3 Standard│   │S3 Object Lock│ │
│  │ + Redis   │    │search    │    │-IA       │    │(Compliance   │ │
│  │           │    │          │    │          │    │ Mode)        │ │
│  │ 0-90 days │    │ 0-1 year │    │ 1-3 year │    │ 0-7+ years   │ │
│  │           │    │          │    │          │    │              │ │
│  │ 实时查询   │    │ 全文检索  │    │ 按需访问  │    │ 不可修改     │ │
│  │ 低延迟    │    │ 合规查询  │    │ 归档     │    │ 不可删除     │ │
│  └──────────┘    └──────────┘    └──────────┘    └──────────────┘ │
│                                                                    │
│  归档流程:                                                          │
│  1. Kafka Consumer 消费 order_events                               │
│  2. 按天聚合为 JSON Lines 文件                                      │
│  3. 计算文件 SHA-256 哈希                                           │
│  4. 上传到 S3 Object Lock (Compliance Mode, 7年保留)                │
│  5. 记录归档元数据（文件名、哈希、记录数）到 archive_metadata 表      │
│  6. 90天后可以清理 PostgreSQL 中的旧 order_events（可选）            │
│                                                                    │
│  S3 Object Lock 配置:                                               │
│  {                                                                  │
│    "ObjectLockEnabled": true,                                      │
│    "Rule": {                                                       │
│      "DefaultRetention": {                                         │
│        "Mode": "COMPLIANCE",                                       │
│        "Years": 7                                                  │
│      }                                                             │
│    }                                                               │
│  }                                                                  │
└────────────────────────────────────────────────────────────────────┘
```

### 4.5 CAT 文件生成流程

```go
// CATReportGenerator 每日 CAT 报告生成器
type CATReportGenerator struct {
    eventRepo    OrderEventRepository
    accountRepo  AccountRepository
    config       CATConfig
}

type CATConfig struct {
    IMID           string // Industry Member ID
    SFTPHost       string
    SFTPUser       string
    SFTPKeyPath    string
    OutputDir      string
    ReportDeadline time.Duration // T+1 08:00 ET
}

// GenerateDaily 生成当日的 CAT 报告文件
func (g *CATReportGenerator) GenerateDaily(ctx context.Context, tradeDate time.Time) error {
    // 1. 查询当日所有订单事件
    events, err := g.eventRepo.GetByDateRange(ctx,
        tradeDate.Truncate(24*time.Hour),
        tradeDate.Truncate(24*time.Hour).Add(24*time.Hour),
    )
    if err != nil {
        return fmt.Errorf("query events for CAT: %w", err)
    }

    // 2. 过滤：只上报美股事件
    usEvents := filterUSMarketEvents(events)

    // 3. 转换为 CAT 格式
    var catRecords []CATRecord
    for _, evt := range usEvents {
        record, err := g.convertToCATRecord(evt)
        if err != nil {
            logger.Error("failed to convert event to CAT record",
                zap.String("event_id", evt.EventID),
                zap.Error(err),
            )
            continue
        }
        catRecords = append(catRecords, record)
    }

    // 4. 生成 JSON Lines 文件
    filename := fmt.Sprintf("CAT_%s_%s.json",
        g.config.IMID,
        tradeDate.Format("20060102"),
    )
    filepath := path.Join(g.config.OutputDir, filename)

    file, err := os.Create(filepath)
    if err != nil {
        return fmt.Errorf("create CAT file: %w", err)
    }
    defer file.Close()

    encoder := json.NewEncoder(file)
    for _, record := range catRecords {
        if err := encoder.Encode(record); err != nil {
            return fmt.Errorf("encode CAT record: %w", err)
        }
    }

    // 5. 计算文件哈希（用于上传验证）
    hash, err := calculateSHA256(filepath)
    if err != nil {
        return fmt.Errorf("calculate file hash: %w", err)
    }

    // 6. SFTP 上传到 FINRA CAT Reporter Portal
    if err := g.uploadToCAT(ctx, filepath, hash); err != nil {
        return fmt.Errorf("upload CAT file: %w", err)
    }

    logger.Info("CAT report generated and uploaded",
        zap.String("trade_date", tradeDate.Format("2006-01-02")),
        zap.Int("record_count", len(catRecords)),
        zap.String("filename", filename),
        zap.String("sha256", hash),
    )

    return nil
}

// convertToCATRecord 将内部事件转换为 CAT 格式
func (g *CATReportGenerator) convertToCATRecord(evt *OrderEvent) (CATRecord, error) {
    var data map[string]interface{}
    if err := json.Unmarshal(evt.EventData, &data); err != nil {
        return CATRecord{}, fmt.Errorf("unmarshal event data: %w", err)
    }

    details, _ := data["details"].(map[string]interface{})

    // 获取 FDID（客户匿名标识符）
    accountID := int64(data["actor_id"].(float64))
    fdid, err := g.accountRepo.GetFDID(context.Background(), accountID)
    if err != nil {
        return CATRecord{}, fmt.Errorf("get FDID for account %d: %w", accountID, err)
    }

    record := CATRecord{
        ActionType:     mapEventTypeToCAT(evt.EventType),
        EventTimestamp: evt.CreatedAt.Format("2006-01-02T15:04:05.000000Z"),
        OrderID:        evt.OrderID,
        CATReporterIMID: g.config.IMID,
        FDIDCustomer:   fdid,
        Symbol:         details["symbol"].(string),
        Side:           mapSideToCAT(details["side"].(string)),
        OrderType:      mapOrderTypeToCAT(details["order_type"].(string)),
        Quantity:       int64(details["quantity"].(float64)),
        TimeInForce:    mapTIFToCAT(details["time_in_force"].(string)),
    }

    if price, ok := details["price"]; ok {
        record.Price = price.(string)
    }

    return record, nil
}

// CATRecord CAT 上报记录
type CATRecord struct {
    ActionType      string `json:"actionType"`
    EventTimestamp  string `json:"eventTimestamp"`
    OrderID         string `json:"orderID"`
    CATReporterIMID string `json:"CATReporterIMID"`
    FDIDCustomer    string `json:"fdidCustomer"`
    Symbol          string `json:"symbol"`
    Side            string `json:"side"`
    OrderType       string `json:"orderType,omitempty"`
    Price           string `json:"price,omitempty"`
    Quantity        int64  `json:"quantity"`
    TimeInForce     string `json:"timeInForce,omitempty"`
    TradingSession  string `json:"tradingSession,omitempty"`
    Destination     string `json:"destination,omitempty"`
    RouteOrderID    string `json:"routedOrderID,omitempty"`
    FillQuantity    int64  `json:"fillQuantity,omitempty"`
    FillPrice       string `json:"fillPrice,omitempty"`
    Venue           string `json:"venue,omitempty"`
    SenderIMID      string `json:"senderIMID,omitempty"`
}
```

---

## 5. 性能要求与设计决策

### 5.1 性能目标

| 指标 | 目标 | 说明 |
|------|------|------|
| 审计事件写入延迟 | < 1ms (p99) | 不能阻塞订单处理主流程 |
| 审计日志查询延迟 | < 500ms (p99) | 通过 Elasticsearch |
| CAT 文件生成时间 | < 30 分钟 | 即使有 100 万条记录 |
| CAT 文件上传时间 | < 10 分钟 | SFTP 传输 |
| 对账数据查询 | < 5 秒 | 按日期范围查询 |
| WORM 归档延迟 | < 1 小时 | 事件产生后归档到 S3 |

### 5.2 设计决策

#### Decision 1: 异步写入 vs 同步写入

**选择：同步写入 PostgreSQL + 异步发布 Kafka**

理由：
- `order_events` 表的写入必须与订单状态更新在同一事务中（确保一致性）
- 如果只写 Kafka 而不写 PostgreSQL，一旦 Kafka 消费者出错，审计记录就会丢失
- Kafka 作为辅助通道，用于下游消费（Elasticsearch、CAT 生成、WORM 归档）
- Outbox Pattern：事件先写入 PostgreSQL，再由 CDC（Change Data Capture）或 Poller 发布到 Kafka

```go
// 在同一事务中写入订单更新和审计事件
func (s *orderService) processExecution(ctx context.Context, report *ExecutionReport) error {
    return s.db.WithTransaction(ctx, func(tx *sql.Tx) error {
        // 1. 更新订单状态
        if err := s.orderRepo.Update(ctx, tx, order); err != nil {
            return fmt.Errorf("update order %s: %w", order.OrderID, err)
        }

        // 2. 写入成交记录
        if err := s.execRepo.Create(ctx, tx, execution); err != nil {
            return fmt.Errorf("create execution: %w", err)
        }

        // 3. 写入审计事件（同一事务）
        event := &OrderEvent{
            EventID:   uuid.New().String(),
            OrderID:   order.OrderID,
            EventType: "ORDER_PARTIALLY_FILLED",
            EventData: buildEventData(report),
            Sequence:  order.EventSequence + 1,
        }
        if err := s.eventRepo.Create(ctx, tx, event); err != nil {
            return fmt.Errorf("create audit event: %w", err)
        }

        // 4. 更新持仓（同一事务）
        if err := s.positionEngine.ProcessExecution(ctx, tx, report); err != nil {
            return fmt.Errorf("process execution for position: %w", err)
        }

        return nil
    })
    // 事务提交后，异步发布到 Kafka
}
```

#### Decision 2: Elasticsearch vs PostgreSQL 查询

**选择：双写 -- PostgreSQL 做 Source of Truth，Elasticsearch 做 Search**

| 维度 | PostgreSQL | Elasticsearch |
|------|-----------|---------------|
| 一致性 | 强一致（事务） | 最终一致（异步索引） |
| 查询能力 | 精确查询、JOIN | 全文搜索、聚合、模糊匹配 |
| 写入性能 | 事务保证 | 异步批量索引 |
| 用途 | 审计记录的法律证据 | 合规团队的搜索和分析 |

#### Decision 3: Kafka 作为审计日志

Kafka 的 append-only 特性天然适合审计日志：

- 消息一旦写入，不可修改（只能追加新消息）
- 可配置长期保留（retention.ms 设为 -1 表示永不删除，或设置为 90 天后归档到 S3）
- 消费者可以重放（replay）任意时间段的消息
- 但 Kafka 本身不满足 WORM 要求（管理员可以删除 topic），需要配合 S3 Object Lock

#### Decision 4: 时间戳存储格式

```
当前实现: Order.CreatedAt = int64 (Unix nanoseconds)
CAT 要求: 微秒精度 ISO 8601

转换:
  nanosTimestamp := order.CreatedAt                          // 1710579000123456789
  t := time.Unix(0, nanosTimestamp).UTC()                   // time.Time
  catTimestamp := t.Format("2006-01-02T15:04:05.000000Z")   // "2026-03-16T09:30:00.123456Z"

注意:
  - PostgreSQL TIMESTAMPTZ 精度为微秒（6位小数），满足 CAT 要求
  - Go time.Time 精度为纳秒，超过 CAT 要求
  - int64 Unix nanos 可以精确表示到 2262 年，容量充足
```

---

## 6. 接口设计（gRPC/REST/Kafka Events）

### 6.1 gRPC 接口

```protobuf
syntax = "proto3";
package trading.compliance.v1;

import "google/protobuf/timestamp.proto";

service ComplianceService {
  // 查询订单审计事件
  rpc GetOrderAuditTrail(GetOrderAuditTrailRequest)
      returns (GetOrderAuditTrailResponse);

  // 按条件搜索审计事件
  rpc SearchAuditEvents(SearchAuditEventsRequest)
      returns (SearchAuditEventsResponse);

  // 生成 CAT 报告
  rpc GenerateCATReport(GenerateCATReportRequest)
      returns (GenerateCATReportResponse);

  // 获取 PDT 状态
  rpc GetPDTStatus(GetPDTStatusRequest)
      returns (PDTStatusResponse);

  // 提交可疑交易报告
  rpc SubmitSTR(SubmitSTRRequest)
      returns (SubmitSTRResponse);

  // 生成合规报告
  rpc GenerateComplianceReport(GenerateComplianceReportRequest)
      returns (ComplianceReport);

  // 获取对账报告
  rpc GetReconciliationReport(GetReconciliationReportRequest)
      returns (ReconciliationReport);
}

message GetOrderAuditTrailRequest {
  string order_id = 1;
}

message GetOrderAuditTrailResponse {
  string order_id = 1;
  repeated AuditEvent events = 2;
}

message AuditEvent {
  string event_id = 1;
  string event_type = 2;
  google.protobuf.Timestamp timestamp = 3;
  string actor_id = 4;
  string actor_type = 5;
  string event_data_json = 6;     // JSONB 原始数据
  int32 sequence = 7;
}

message SearchAuditEventsRequest {
  // 搜索条件（至少一个必填）
  string order_id = 1;
  int64 account_id = 2;
  string symbol = 3;
  string event_type = 4;
  google.protobuf.Timestamp from_time = 5;
  google.protobuf.Timestamp to_time = 6;
  string source = 7;              // "IOS" / "ANDROID" / "WEB" / "API"
  string ip_address = 8;

  // 分页
  int32 page_size = 10;
  string page_token = 11;

  // 排序
  string order_by = 12;           // "timestamp_asc" / "timestamp_desc"
}

message SearchAuditEventsResponse {
  repeated AuditEvent events = 1;
  string next_page_token = 2;
  int64 total_count = 3;
}

message GenerateCATReportRequest {
  string trade_date = 1;          // "2026-03-16"
  bool dry_run = 2;               // true = 只生成不上传
}

message GenerateCATReportResponse {
  string filename = 1;
  int64 record_count = 2;
  string file_hash_sha256 = 3;
  bool uploaded = 4;
  string upload_status = 5;       // "SUCCESS" / "PENDING" / "FAILED"
}

message GetPDTStatusRequest {
  int64 account_id = 1;
}

message PDTStatusResponse {
  int64 account_id = 1;
  bool is_pdt_flagged = 2;        // 是否已被标记为 PDT
  int32 day_trades_count = 3;     // 过去 5 个工作日的日内交易次数
  int32 day_trades_remaining = 4; // 剩余可用次数（3 - current）
  string account_equity = 5;      // 当前净值
  bool meets_equity_threshold = 6;// 是否满足 $25K 要求
  repeated DayTradeDetail recent_day_trades = 7;
}

message DayTradeDetail {
  string trade_date = 1;
  string symbol = 2;
  int32 count = 3;
  string buy_value = 4;
  string sell_value = 5;
}

message SubmitSTRRequest {
  int64 account_id = 1;
  string reason = 2;
  string description = 3;
  repeated string related_order_ids = 4;
  string submitted_by = 5;        // 提交人（合规官）
}

message SubmitSTRResponse {
  string str_id = 1;
  string status = 2;              // "SUBMITTED" / "PENDING_REVIEW"
  google.protobuf.Timestamp submitted_at = 3;
}

message GenerateComplianceReportRequest {
  string report_type = 1;         // "DAILY_SUMMARY" / "MONTHLY" / "STR_SUMMARY"
  string from_date = 2;
  string to_date = 3;
  string market = 4;              // "US" / "HK" / "ALL"
}

message ComplianceReport {
  string report_type = 1;
  string period = 2;
  string market = 3;

  // 交易摘要
  int64 total_orders = 4;
  int64 total_executions = 5;
  int64 rejected_orders = 6;
  int64 cancelled_orders = 7;
  string total_trade_value = 8;

  // 合规指标
  int64 risk_check_failures = 9;
  int64 pdt_violations = 10;
  int64 suspicious_activities = 11;
  int64 str_filed = 12;

  // 系统指标
  string avg_order_latency_ms = 13;
  string p99_order_latency_ms = 14;
  string system_availability_pct = 15;

  // 详细数据 (JSON)
  string details_json = 16;
}
```

### 6.2 REST API（Admin Panel 使用）

```yaml
# 审计追踪查询（Admin Panel）
GET /api/v1/admin/audit/orders/{order_id}/trail
Authorization: Bearer {admin_jwt}
Response:
  order_id: "ord-001-uuid"
  events:
    - event_id: "evt-001"
      event_type: "ORDER_CREATED"
      timestamp: "2026-03-16T09:30:00.123456Z"
      sequence: 1
      actor: "user-12345"
      summary: "Created LIMIT BUY 100 AAPL @ 150.25"
    - event_id: "evt-002"
      event_type: "RISK_CHECK_PASSED"
      timestamp: "2026-03-16T09:30:00.125200Z"
      sequence: 2
      actor: "system"
      summary: "All 7 risk checks passed (1.075ms)"
    - event_id: "evt-003"
      event_type: "ORDER_SUBMITTED"
      timestamp: "2026-03-16T09:30:00.126000Z"
      sequence: 3
      actor: "system"
      summary: "Submitted to NYSE via FIX"

# 搜索审计事件（合规团队使用）
POST /api/v1/admin/audit/search
Authorization: Bearer {admin_jwt}
Body:
  account_id: 12345
  symbol: "AAPL"
  from_time: "2026-03-01T00:00:00Z"
  to_time: "2026-03-16T23:59:59Z"
  event_types: ["ORDER_CREATED", "ORDER_FILLED", "RISK_CHECK_FAILED"]
  page_size: 50

# PDT 状态查询（Admin Panel）
GET /api/v1/admin/compliance/pdt/{account_id}
Authorization: Bearer {admin_jwt}
Response:
  account_id: 12345
  is_pdt_flagged: false
  day_trades_count: 2
  day_trades_remaining: 1
  account_equity: "18500.00"
  meets_equity_threshold: false
  warning: "Account below $25,000 threshold with 2 day trades"

# 合规报告生成
POST /api/v1/admin/compliance/reports
Authorization: Bearer {admin_jwt}
Body:
  report_type: "DAILY_SUMMARY"
  date: "2026-03-16"
  market: "ALL"
Response:
  report_id: "rpt-uuid"
  status: "GENERATED"
  download_url: "/api/v1/admin/compliance/reports/rpt-uuid/download"

# 可疑交易监控仪表板
GET /api/v1/admin/surveillance/alerts?status=OPEN&severity=HIGH
Authorization: Bearer {admin_jwt}
Response:
  alerts:
    - alert_id: "alert-001"
      type: "WASH_TRADE_SUSPECTED"
      severity: "HIGH"
      account_id: 67890
      symbol: "TSLA"
      description: "3 round-trip trades in 10 minutes"
      detected_at: "2026-03-16T10:15:00Z"
      status: "OPEN"
      related_orders: ["ord-010", "ord-011", "ord-012"]
```

### 6.3 Kafka Events

```
Topic: trading.compliance

--- 合规告警事件 ---
Key: {account_id}
Value: {
  "event_type": "COMPLIANCE_ALERT",
  "event_id": "evt-uuid",
  "timestamp": "2026-03-16T10:15:00Z",
  "data": {
    "alert_type": "WASH_TRADE_SUSPECTED",
    "severity": "HIGH",
    "account_id": 67890,
    "symbol": "TSLA",
    "market": "US",
    "description": "3 round-trip trades in 10 minutes with minimal price change",
    "related_orders": ["ord-010", "ord-011", "ord-012"],
    "detection_rule": "WASH_TRADE_V2",
    "confidence_score": 0.85,
    "requires_str": false
  }
}

--- PDT 状态变更事件 ---
Key: {account_id}
Value: {
  "event_type": "PDT_STATUS_CHANGED",
  "event_id": "evt-uuid",
  "timestamp": "2026-03-16T15:30:00Z",
  "data": {
    "account_id": 12345,
    "previous_status": "NORMAL",
    "new_status": "PDT_FLAGGED",
    "day_trade_count": 4,
    "window_start": "2026-03-10",
    "window_end": "2026-03-16",
    "account_equity": "18500.00",
    "action": "RESTRICT_DAY_TRADING"
  }
}

--- CAT 报告状态事件 ---
Key: {trade_date}
Value: {
  "event_type": "CAT_REPORT_STATUS",
  "event_id": "evt-uuid",
  "timestamp": "2026-03-17T07:45:00Z",
  "data": {
    "trade_date": "2026-03-16",
    "status": "UPLOADED",
    "record_count": 45230,
    "file_hash": "sha256:abc123...",
    "upload_time_seconds": 180,
    "validation_errors": 0
  }
}
```

---

## 7. 开源参考实现

### 7.1 直接相关的开源项目

| 项目 | 语言 | 说明 | 参考价值 |
|------|------|------|---------|
| **elastic/go-elasticsearch** | Go | Elasticsearch 官方 Go 客户端 | 审计日志索引和查询 |
| **olivere/elastic/v7** | Go | 社区 Elasticsearch 客户端 | 更友好的 API，搜索构建器 |
| **aws/aws-sdk-go-v2** | Go | AWS SDK | S3 Object Lock 操作 |
| **segmentio/kafka-go** | Go | Kafka 客户端 | 事件发布和消费 |
| **uber-go/zap** | Go | 结构化日志 | 高性能审计日志 |
| **robfig/cron/v3** | Go | Cron 调度器 | CAT 报告定时生成 |
| **pkg/sftp** | Go | SFTP 客户端 | CAT 文件上传 |

### 7.2 合规相关工具

| 工具 | 说明 | 参考用途 |
|------|------|---------|
| **FINRA CAT Reporter Portal** | FINRA 提供的 CAT 上报工具 | 文件格式验证 |
| **SEC EDGAR** | SEC 电子文件系统 | Blue Sheet 格式参考 |
| **Sumsub / Chainalysis** | AML/KYC 服务提供商 | 可疑交易检测算法参考 |

### 7.3 事件溯源参考

| 项目 | 语言 | 说明 |
|------|------|------|
| **EventStoreDB** | Multi | 专用事件存储数据库 |
| **ThreeDotsLabs/watermill** | Go | 事件驱动应用框架 |
| **looplab/eventhorizon** | Go | CQRS/Event Sourcing 框架 |

---

## 8. PRD Review 检查清单

### 8.1 审计完整性

- [ ] 每个订单状态转换是否都产生一个 immutable event？
- [ ] event_data 是否包含完整上下文（时间戳、操作者、IP、设备、关联 ID）？
- [ ] 拒绝原因是否明确记录（风控拒绝、交易所拒绝分别记录原因码）？
- [ ] 幂等 key 是否记录在审计事件中？
- [ ] 系统操作（风控检查、路由决策）是否也记录审计事件？
- [ ] 事件序号（sequence）是否严格递增，无间隔？

### 8.2 CAT 合规

- [ ] 时间戳精度是否达到微秒级（6 位小数秒）？
- [ ] 系统时钟是否与 NIST 同步，偏差 < 50ms？
- [ ] CAT 文件是否包含所有必需字段？
- [ ] FDID 映射是否正确（客户匿名标识符）？
- [ ] CAT 文件是否在 T+1 08:00 ET 前上传？
- [ ] 是否有 CAT 文件生成失败的告警和重试机制？
- [ ] 是否有 CAT 上报数据质量校验（验证记录完整性）？

### 8.3 记录保留（WORM）

- [ ] 是否使用 S3 Object Lock（Compliance Mode）存储审计记录？
- [ ] 保留期限是否设置为 7 年？
- [ ] 归档文件是否计算和验证 SHA-256 哈希？
- [ ] 是否有地理冗余备份？
- [ ] 前 2 年的记录是否"即时可访问"（SEC 要求）？
- [ ] 是否记录了归档元数据（文件名、哈希、记录数、归档时间）？

### 8.4 PII 保护

- [ ] 日志中的 SSN/HKID/银行账号是否脱敏？
- [ ] Kafka 消息中是否不包含 PII？
- [ ] Elasticsearch 索引中的 PII 字段是否加密或脱敏？
- [ ] CAT 上报是否使用 FDID 而非真实身份信息？
- [ ] 审计事件的 event_data 中是否不包含密码、Token？

### 8.5 监控与告警

- [ ] CAT 上传失败是否触发紧急告警？
- [ ] 审计事件写入失败是否触发告警（这意味着交易可能未被记录）？
- [ ] PDT 违规是否实时通知用户和合规团队？
- [ ] 可疑交易检测是否有明确的告警分级（LOW/MEDIUM/HIGH/CRITICAL）？
- [ ] 对账差异是否自动触发告警？

### 8.6 性能

- [ ] 审计事件写入是否不影响订单处理延迟（< 1ms 额外开销）？
- [ ] Elasticsearch 查询是否能在 500ms 内返回结果？
- [ ] CAT 文件生成是否能在 30 分钟内完成？
- [ ] WORM 归档是否在事件产生后 1 小时内完成？

---

## 9. 工程落地注意事项

### 9.1 Event Sourcing 实现要点

#### 9.1.1 事件序号的原子递增

```go
// 确保每个订单的事件序号严格递增
// 使用数据库序列或在事务中计算下一个序号
func (r *eventRepo) Create(ctx context.Context, tx *sql.Tx, event *OrderEvent) error {
    // 在事务中获取当前最大序号
    var maxSeq int
    err := tx.QueryRowContext(ctx,
        "SELECT COALESCE(MAX(sequence), 0) FROM order_events WHERE order_id = $1",
        event.OrderID,
    ).Scan(&maxSeq)
    if err != nil {
        return fmt.Errorf("get max sequence for order %s: %w", event.OrderID, err)
    }

    event.Sequence = maxSeq + 1

    _, err = tx.ExecContext(ctx,
        `INSERT INTO order_events (event_id, order_id, event_type, event_data, sequence, created_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        event.EventID, event.OrderID, event.EventType, event.EventData,
        event.Sequence, event.CreatedAt,
    )
    if err != nil {
        return fmt.Errorf("insert order event: %w", err)
    }

    return nil
}
```

#### 9.1.2 Outbox Pattern 实现

```go
// 使用 Outbox Pattern 确保事件可靠发布到 Kafka
// 避免"事务提交成功但 Kafka 发布失败"导致的不一致

// 方案 A: CDC（Change Data Capture）
// PostgreSQL → Debezium → Kafka
// 优点: 完全解耦，零侵入
// 缺点: 引入额外基础设施

// 方案 B: Polling Outbox
// 1. 事件写入 order_events 表（事务内）
// 2. 后台 Poller 定期扫描未发布的事件
// 3. 发布到 Kafka 后标记已发布

// 推荐方案 B（简单可靠）:
type OutboxPoller struct {
    db     *sql.DB
    kafka  *kafka.Writer
    logger *zap.Logger
}

func (p *OutboxPoller) Poll(ctx context.Context) error {
    // 扫描未发布的事件（使用 advisory lock 防止并发消费）
    rows, err := p.db.QueryContext(ctx,
        `SELECT event_id, order_id, event_type, event_data, created_at
         FROM order_events
         WHERE published_to_kafka = FALSE
         ORDER BY id ASC
         LIMIT 1000
         FOR UPDATE SKIP LOCKED`,
    )
    if err != nil {
        return fmt.Errorf("poll outbox: %w", err)
    }
    defer rows.Close()

    var events []*OrderEvent
    for rows.Next() {
        var e OrderEvent
        if err := rows.Scan(&e.EventID, &e.OrderID, &e.EventType, &e.EventData, &e.CreatedAt); err != nil {
            return fmt.Errorf("scan event: %w", err)
        }
        events = append(events, &e)
    }

    // 批量发布到 Kafka
    for _, e := range events {
        msg := kafka.Message{
            Key:   []byte(e.OrderID),
            Value: e.EventData,
            Headers: []kafka.Header{
                {Key: "event_type", Value: []byte(e.EventType)},
                {Key: "event_id", Value: []byte(e.EventID)},
            },
        }
        if err := p.kafka.WriteMessages(ctx, msg); err != nil {
            p.logger.Error("failed to publish event to kafka",
                zap.String("event_id", e.EventID),
                zap.Error(err),
            )
            continue // 下次 Poll 重试
        }

        // 标记已发布
        _, err := p.db.ExecContext(ctx,
            "UPDATE order_events SET published_to_kafka = TRUE WHERE event_id = $1",
            e.EventID,
        )
        if err != nil {
            p.logger.Error("failed to mark event as published",
                zap.String("event_id", e.EventID),
                zap.Error(err),
            )
        }
    }

    return nil
}
```

**注意**：当前 `order_events` 表 schema 中没有 `published_to_kafka` 字段，需要添加迁移：

```sql
ALTER TABLE order_events ADD COLUMN published_to_kafka BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX idx_order_events_unpublished ON order_events (id)
    WHERE published_to_kafka = FALSE;
```

### 9.2 可疑交易检测算法

```go
// SurveillanceEngine 市场监控引擎
type SurveillanceEngine struct {
    execRepo    ExecutionRepository
    alertRepo   AlertRepository
    alertSender AlertSender
    rules       []SurveillanceRule
}

// SurveillanceRule 监控规则接口
type SurveillanceRule interface {
    Name() string
    Evaluate(ctx context.Context, execution *Execution) (*Alert, error)
}

// WashTradeRule 洗售交易检测
// 同一账户在短时间内对同一标的进行买入和卖出，无明显经济目的
type WashTradeRule struct {
    execRepo   ExecutionRepository
    windowSize time.Duration // 检测窗口（如 10 分钟）
    threshold  int           // 最小往返次数
}

func (r *WashTradeRule) Evaluate(ctx context.Context, exec *Execution) (*Alert, error) {
    windowStart := exec.ExecutedAt.Add(-r.windowSize)

    // 查询窗口内同账户同标的的反方向成交
    oppositeExecs, err := r.execRepo.FindByAccountSymbolSide(ctx,
        exec.AccountID, exec.Symbol,
        oppositeSide(exec.Side),
        windowStart, exec.ExecutedAt,
    )
    if err != nil {
        return nil, fmt.Errorf("query opposite executions: %w", err)
    }

    roundTrips := countRoundTrips(exec, oppositeExecs)
    if roundTrips >= r.threshold {
        return &Alert{
            Type:        "WASH_TRADE_SUSPECTED",
            Severity:    "HIGH",
            AccountID:   exec.AccountID,
            Symbol:      exec.Symbol,
            Description: fmt.Sprintf("%d round-trip trades in %v", roundTrips, r.windowSize),
            RelatedOrders: collectOrderIDs(exec, oppositeExecs),
            Confidence:  0.85,
        }, nil
    }

    return nil, nil // 未触发
}

// SpoofingRule Spoofing/Layering 检测
// 大量下单后快速撤单，意图影响市场价格
type SpoofingRule struct {
    orderRepo  OrderRepository
    windowSize time.Duration // 检测窗口
    cancelRate float64       // 取消率阈值（如 90%）
    minOrders  int           // 最小订单数量
}

func (r *SpoofingRule) Evaluate(ctx context.Context, exec *Execution) (*Alert, error) {
    windowStart := exec.ExecutedAt.Add(-r.windowSize)

    orders, err := r.orderRepo.FindByAccountSymbol(ctx,
        exec.AccountID, exec.Symbol, windowStart, exec.ExecutedAt,
    )
    if err != nil {
        return nil, fmt.Errorf("query orders for spoofing check: %w", err)
    }

    if len(orders) < r.minOrders {
        return nil, nil
    }

    cancelledCount := 0
    for _, o := range orders {
        if o.Status == "CANCELLED" {
            cancelledCount++
        }
    }

    actualCancelRate := float64(cancelledCount) / float64(len(orders))
    if actualCancelRate >= r.cancelRate {
        return &Alert{
            Type:        "SPOOFING_SUSPECTED",
            Severity:    "CRITICAL",
            AccountID:   exec.AccountID,
            Symbol:      exec.Symbol,
            Description: fmt.Sprintf("%.0f%% cancel rate (%d/%d orders) in %v",
                actualCancelRate*100, cancelledCount, len(orders), r.windowSize),
            RelatedOrders: collectOrderIDs2(orders),
            Confidence:  0.75,
        }, nil
    }

    return nil, nil
}
```

### 9.3 Elasticsearch 索引设计

```json
{
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 1,
    "index.lifecycle.name": "audit_events_policy",
    "index.lifecycle.rollover_alias": "audit_events"
  },
  "mappings": {
    "properties": {
      "event_id":       { "type": "keyword" },
      "order_id":       { "type": "keyword" },
      "event_type":     { "type": "keyword" },
      "timestamp":      { "type": "date", "format": "strict_date_optional_time_nanos" },
      "actor_id":       { "type": "keyword" },
      "actor_type":     { "type": "keyword" },
      "account_id":     { "type": "long" },
      "symbol":         { "type": "keyword" },
      "market":         { "type": "keyword" },
      "side":           { "type": "keyword" },
      "source":         { "type": "keyword" },
      "ip_address":     { "type": "ip" },
      "device_id":      { "type": "keyword" },
      "correlation_id": { "type": "keyword" },
      "sequence":       { "type": "integer" },
      "details":        { "type": "object", "dynamic": true },
      "details_text":   { "type": "text", "analyzer": "standard" }
    }
  }
}
```

**ILM（Index Lifecycle Management）策略：**

```json
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_primary_shard_size": "50gb",
            "max_age": "7d"
          }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 }
        }
      },
      "cold": {
        "min_age": "365d",
        "actions": {
          "readonly": {}
        }
      },
      "delete": {
        "min_age": "2555d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### 9.4 Prometheus 监控指标

```go
var (
    // 审计事件
    auditEventsCreated = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "audit_events_created_total",
            Help: "Total audit events created",
        },
        []string{"event_type", "market"},
    )

    auditEventWriteLatency = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "audit_event_write_duration_seconds",
            Help:    "Latency of writing audit events to PostgreSQL",
            Buckets: []float64{0.0001, 0.0005, 0.001, 0.005, 0.01},
        },
        []string{"event_type"},
    )

    // Kafka 发布
    auditKafkaPublishLatency = prometheus.NewHistogram(
        prometheus.HistogramOpts{
            Name:    "audit_kafka_publish_duration_seconds",
            Help:    "Latency of publishing audit events to Kafka",
            Buckets: []float64{0.001, 0.005, 0.01, 0.05, 0.1},
        },
    )

    auditKafkaPublishFailures = prometheus.NewCounter(
        prometheus.CounterOpts{
            Name: "audit_kafka_publish_failures_total",
            Help: "Total Kafka publish failures for audit events",
        },
    )

    outboxLag = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "audit_outbox_lag",
            Help: "Number of audit events pending Kafka publication",
        },
    )

    // CAT 报告
    catReportRecordCount = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "cat_report_record_count",
            Help: "Number of records in the latest CAT report",
        },
        []string{"trade_date"},
    )

    catReportGenerationDuration = prometheus.NewHistogram(
        prometheus.HistogramOpts{
            Name:    "cat_report_generation_duration_seconds",
            Help:    "Duration of CAT report generation",
            Buckets: []float64{60, 120, 300, 600, 1800},
        },
    )

    catReportUploadStatus = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "cat_report_upload_status",
            Help: "CAT report upload status (1=success, 0=failed)",
        },
        []string{"trade_date"},
    )

    // 合规告警
    complianceAlertsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "compliance_alerts_total",
            Help: "Total compliance alerts generated",
        },
        []string{"alert_type", "severity"},
    )

    // PDT
    pdtViolationsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "pdt_violations_total",
            Help: "Total PDT rule violations detected",
        },
        []string{"action"}, // "WARNED" / "BLOCKED" / "FLAGGED"
    )

    // WORM 归档
    wormArchiveLatency = prometheus.NewHistogram(
        prometheus.HistogramOpts{
            Name:    "worm_archive_duration_seconds",
            Help:    "Duration of WORM archive operation",
            Buckets: []float64{10, 30, 60, 300, 600, 3600},
        },
    )

    wormArchiveRecords = prometheus.NewCounter(
        prometheus.CounterOpts{
            Name: "worm_archive_records_total",
            Help: "Total records archived to WORM storage",
        },
    )
)
```

### 9.5 测试策略

| 测试类型 | 覆盖范围 | 关键场景 |
|---------|---------|---------|
| **单元测试** | 事件构建、PII 脱敏、CAT 格式转换 | 各事件类型的 event_data 结构正确性 |
| **集成测试** | 完整审计流程 | 订单提交 -> 事件写入 -> Kafka 发布 -> ES 索引 |
| **CAT 格式测试** | CAT 文件生成 | 验证生成的文件符合 FINRA CAT 规范 |
| **PII 泄露测试** | 日志扫描 | 确保日志中无未脱敏的 PII |
| **WORM 完整性测试** | 归档验证 | 文件哈希、不可删除、保留期限 |
| **时间精度测试** | 时间戳精度 | 验证微秒精度保持 |
| **性能测试** | 写入吞吐 | 高并发下审计事件写入不影响主流程 |
| **合规场景测试** | PDT/Wash Trade 检测 | 模拟违规场景，验证检测和告警 |

**关键测试用例：**

```go
// 测试1: 事件序号严格递增
func TestEventSequence_StrictlyIncrementing(t *testing.T) {
    orderID := uuid.New().String()

    // 插入多个事件
    events := []string{
        "ORDER_CREATED",
        "RISK_CHECK_PASSED",
        "ORDER_SUBMITTED",
        "ORDER_PARTIALLY_FILLED",
        "ORDER_FILLED",
    }

    for _, eventType := range events {
        err := repo.Create(ctx, tx, &OrderEvent{
            EventID:   uuid.New().String(),
            OrderID:   orderID,
            EventType: eventType,
            EventData: []byte(`{}`),
        })
        require.NoError(t, err)
    }

    // 验证序号
    stored, err := repo.GetByOrderID(ctx, orderID)
    require.NoError(t, err)
    require.Len(t, stored, 5)

    for i, evt := range stored {
        assert.Equal(t, i+1, evt.Sequence)
    }
}

// 测试2: PII 脱敏
func TestMaskSSN(t *testing.T) {
    assert.Equal(t, "***-**-6789", MaskSSN("123-45-6789"))
    assert.Equal(t, "***-**-1234", MaskSSN("987-65-1234"))
    assert.Equal(t, "****", MaskSSN("12"))
}

// 测试3: CAT 时间戳精度
func TestCATTimestamp_MicrosecondPrecision(t *testing.T) {
    ts := time.Date(2026, 3, 16, 9, 30, 0, 123456000, time.UTC)
    formatted := ts.Format("2006-01-02T15:04:05.000000Z")
    assert.Equal(t, "2026-03-16T09:30:00.123456Z", formatted)
}

// 测试4: PDT 检测逻辑
func TestPDTDetection_ThreeTradesInFiveDays(t *testing.T) {
    accountID := int64(12345)
    equity := decimal.NewFromFloat(18000) // 低于 $25,000

    // 模拟 5 个工作日内 3 次日内交易
    insertDayTrade(t, accountID, "AAPL", today.AddDate(0, 0, -4))
    insertDayTrade(t, accountID, "TSLA", today.AddDate(0, 0, -2))
    insertDayTrade(t, accountID, "GOOG", today)

    count, err := pdtService.CountDayTrades(ctx, accountID, 5)
    require.NoError(t, err)
    assert.Equal(t, 3, count)

    // 下一笔日内交易应被阻止
    result := pdtCheck.Check(ctx, &order.Order{
        AccountID: accountID,
        Symbol:    "MSFT",
        Market:    "US",
        Side:      order.SideBuy,
    }, &risk.Account{
        ID:     accountID,
        Type:   "MARGIN",
        Equity: equity,
    })

    assert.False(t, result.Approved)
    assert.Contains(t, result.Reason, "PDT restriction")
}
```

### 9.6 上线检查清单

- [ ] `order_events` 表已创建，索引已建立
- [ ] 添加 `published_to_kafka` 字段到 `order_events` 表
- [ ] Kafka topics 已创建：`trading.order_events`, `trading.compliance`
- [ ] Elasticsearch 索引模板和 ILM 策略已配置
- [ ] S3 Bucket 已创建，Object Lock（Compliance Mode, 7 年）已启用
- [ ] SFTP 连接到 FINRA CAT Reporter Portal 已测试
- [ ] IMID（Industry Member ID）和 FDID 映射已配置
- [ ] NTP 时钟同步已配置，偏差 < 50ms
- [ ] PII 脱敏工具已集成到日志框架
- [ ] CAT 报告生成 Cron Job 已配置（每日 T+1 06:00 ET）
- [ ] WORM 归档 Job 已配置（每小时运行）
- [ ] Outbox Poller 已配置（每 5 秒轮询）
- [ ] 可疑交易检测规则已配置：Wash Trade, Spoofing, 大额交易
- [ ] PDT 规则集成到风控流水线
- [ ] Prometheus 监控面板已创建
- [ ] 告警规则已配置：CAT 上传失败、审计写入失败、对账差异
- [ ] 合规团队已获得 Admin Panel 的审计查询权限
- [ ] 已执行 PII 泄露扫描，确认日志中无未脱敏数据
- [ ] 已执行合规场景测试（PDT、Wash Trade 模拟）
- [ ] 运营手册已编写：CAT 上传失败 SOP、STR 提交流程、PDT 处理流程
