# 运营场景与边界情况处理

## 文档信息

| 属性 | 内容 |
|------|------|
| 文档路径 | `docs/specs/operations-and-edge-cases.md` |
| 领域 | Fund Transfer Service |
| 版本 | v1.0 |
| 日期 | 2026-03-15 |
| 状态 | Draft |

---

## 1. 节假日与银行维护窗口

### 1.1 美国联邦假日 — ACH 不处理

ACH 网络由 Federal Reserve 运营，联邦假日期间 Fedwire 和 ACH 均暂停处理。下列日期为美国联邦法定假日（每年具体日期按规则推算）：

| 假日名称 | 规则 | 2026年示例 |
|----------|------|------------|
| New Year's Day | 1月1日 | 2026-01-01 |
| Martin Luther King Jr. Day | 1月第三个周一 | 2026-01-19 |
| Presidents' Day | 2月第三个周一 | 2026-02-16 |
| Memorial Day | 5月最后一个周一 | 2026-05-25 |
| Juneteenth National Independence Day | 6月19日 | 2026-06-19 |
| Independence Day | 7月4日 | 2026-07-04 |
| Labor Day | 9月第一个周一 | 2026-09-07 |
| Columbus Day | 10月第二个周一 | 2026-10-12 |
| Veterans Day | 11月11日 | 2026-11-11 |
| Thanksgiving Day | 11月第四个周四 | 2026-11-26 |
| Christmas Day | 12月25日 | 2026-12-25 |

**注意事项：**
- 若假日落在周六，则前一个周五（周五）为观察日（Observed Holiday），ACH 同样不处理。
- 若假日落在周日，则后一个周一为观察日，ACH 同样不处理。
- Same Day ACH 仅在联邦储备银行营业日可用；若非营业日提交，自动降级为标准 ACH（T+1 或 T+2）。

系统需维护一份滚动更新的联邦假日日历（建议提前加载未来两年），存储在 Redis 中，Key 格式如下：

```
fed_holidays:{year}  →  SET of dates in "YYYY-MM-DD" format
```

### 1.2 香港银行维护窗口 — FPS 的特殊性

FPS（Faster Payment System）由香港金融管理局（HKMA）运营，名义上 7×24 小时可用，但存在以下窗口需要特殊处理：

**FPS 系统维护窗口（HKMA 定期公告）：**

| 维护类型 | 典型时间窗口 | 频率 |
|----------|------------|------|
| 计划性维护 | 周日 02:00–06:00 HKT | 不定期（提前公告） |
| 月末账户核对 | 月末最后一个工作日 23:30–00:30 HKT | 每月 |
| 年末系统升级 | 12月31日 23:00 – 1月1日 06:00 HKT | 每年 |

**处理策略：**

1. 订阅 HKMA 维护公告 API（或人工维护维护日历），提前将维护窗口写入系统配置。
2. 在维护窗口内提交的 FPS 入金请求，状态置为 `QUEUED_MAINTENANCE`，待窗口结束后自动重新提交。
3. 维护窗口内不向用户展示 FPS 为可用渠道，改为提示"FPS 系统维护中，预计 XX:XX 恢复"。

**香港公众假期 — CHATS 不处理：**

CHATS（Clearing House Automated Transfer System）遵循香港公众假期，假期内停止处理。FPS 虽然名义上在公众假期仍可运行，但香港银行间结算在假日暂停，可能导致 FPS 款项当日无法完成银行端入账（实际到账时间延迟至下一个香港银行营业日）。

香港常见公众假期包括：元旦、农历新年（3天）、清明节、复活节（4天）、劳动节、佛诞、端午节、香港回归纪念日、国庆日（2天）、重阳节、圣诞节（2天）。

### 1.3 节假日排队的出入金处理时序

**核心原则：节假日提交的请求不自动取消，但必须明确告知用户预计处理时间。**

```
提交时间              渠道           预计处理时间
-----------           ------         ----------------
联邦假日当天          ACH Standard   节后第一个银行工作日处理，T+1 或 T+2 到账
联邦假日当天          ACH Same Day   节后第一个银行工作日的第一批次（14:45 ET 截止）
联邦假日前最后工作日  ACH Standard   当天提交，假日后第一个工作日 T+1 到账
周五 16:00 ET 之后    ACH Standard   下周一处理（若无假日），T+1 到账
香港公众假期          FPS            技术上可提交，但银行端结算延至节后第一个香港银行工作日
香港公众假期          CHATS          不处理，节后第一个香港银行工作日处理
```

**"节后第一个工作日"的定义：**

系统中同时维护美国银行日历和香港银行日历两套日历。计算下一个有效处理日的函数签名如下：

```go
// NextBankingDay returns the next valid banking day for the given channel.
// For US ACH/Wire: skips US federal holidays and weekends.
// For HK FPS/CHATS: skips HK public holidays and weekends.
func NextBankingDay(from time.Time, channel Channel) time.Time
```

**状态流转：**

```
INITIATED
    │
    ▼ (节假日检测)
QUEUED_HOLIDAY  ──(节后第一个工作日 00:00 UTC)──▶  PROCESSING
    │
    │ (用户主动取消)
    ▼
CANCELLED
```

节假日排队期间，用户可以取消请求（出金为主；入金一旦银行已受理则不可取消）。

### 1.4 跨时区"工作日"定义

**系统统一使用 UTC 存储和比较时间，但 ACH 截止时间以美国东部时间（ET）为基准。**

关键映射关系：

| ACH 截止时间（ET） | UTC 偏移（EST，UTC-5） | UTC 偏移（EDT，UTC-4） |
|-------------------|----------------------|----------------------|
| 08:00 ET（Same Day 第一批） | 13:00 UTC | 12:00 UTC |
| 14:45 ET（Same Day 第一批截止） | 19:45 UTC | 18:45 UTC |
| 16:45 ET（Same Day 第二批截止） | 21:45 UTC | 20:45 UTC |
| 17:00 ET（Standard ACH 当日截止） | 22:00 UTC | 21:00 UTC |

系统必须在运行时动态判断 ET 当前是 EST（UTC-5，11月第一个周日至3月第二个周日）还是 EDT（UTC-4，其余时间），不能硬编码偏移量。

```go
// GetACHCutoffUTC returns the ACH same-day cutoff time in UTC for a given date.
// Handles EST/EDT transition automatically using the America/New_York timezone.
func GetACHCutoffUTC(date time.Time, batch ACHBatch) time.Time {
    loc, _ := time.LoadLocation("America/New_York")
    // batch 1 cutoff: 14:45 ET
    // batch 2 cutoff: 16:45 ET
    ...
}
```

"工作日"在业务层面的定义：
- **US ACH 工作日** = 非周末 + 非美国联邦假日
- **HK 银行工作日** = 非周末 + 非香港公众假期
- **系统内部工作日** = 不单独使用，总是指定渠道

### 1.5 ACH Same Day 截止时间详解

NACHA 规则下 Same Day ACH 分两个批次：

```
批次    提交截止（ET）    资金可用（ET）    适用场景
------  ---------------  ----------------  ---------
批次1   14:45            17:00             上午提交的入金
批次2   16:45            18:00             下午提交的入金（仅部分银行支持）

Standard ACH（T+1）
        17:00 当日        次日 08:00 左右   日常入金
```

**超过批次2截止时间（16:45 ET）的请求处理规则：**

- 若当前时间 > 16:45 ET，则本日无法以 Same Day ACH 处理。
- 系统自动降级为 Standard ACH，次日（下一个银行工作日）进入第一批次。
- 用户提交时应展示降级提示，并更新预计到账时间。
- 不允许在不通知用户的情况下静默降级。

### 1.6 用户界面预计到账时间展示

用户提交出入金请求时，系统须在确认页面展示动态计算的预计到账时间，计算逻辑如下：

```go
type ETAResult struct {
    EstimatedArrival     time.Time
    DisplayText          string  // 面向用户的文本，如 "预计3月17日（周二）到账"
    CaveatText           string  // 补充说明，如 "因3月16日为联邦假日，延后一个工作日"
    IsHolidayImpacted    bool
    IsMaintenanceImpacted bool
}

func CalculateDepositETA(
    channel Channel,
    submittedAt time.Time,
    isSameDay bool,
) ETAResult
```

展示规则：

| 场景 | 展示文本示例 |
|------|------------|
| 普通 ACH T+1 | "预计1-2个工作日到账（约3月17日）" |
| ACH T+1 遇节假日 | "预计3月19日（周四）到账，因3月17日为联邦假日" |
| ACH Same Day 批次内 | "预计今日17:00前到账" |
| ACH Same Day 超截止 | "当日截止时间已过，已转为标准ACH，预计明日到账" |
| FPS 正常 | "预计10分钟内到账" |
| FPS 维护窗口 | "FPS系统维护中（预计06:00恢复），维护结束后立即处理" |
| 香港假期 CHATS | "因明日为香港公众假期，预计3月18日（周三）处理" |

---

## 2. 用户限额完整检查逻辑

### 2.1 三种限额的定义与检查顺序

系统维护三层限额，**必须按顺序全部通过**，任一层不通过即拒绝请求：

```
检查顺序:
  1. 单笔限额 (per-transaction limit)   ← 最快，直接和请求金额比较
  2. 日限额   (daily limit)             ← 需查 Redis 当日累计值
  3. 月限额   (monthly limit)           ← 需查 Redis 当月累计值
```

**为什么按此顺序：** 单笔检查无需 I/O，最先做可以快速拒绝明显违规请求。日限额比月限额更频繁触发，且 Redis 操作代价相同，日限额在先可以减少月限额的无效查询（虽然差异小，但逻辑上层次更清晰）。

KYC 分级限额定义（来自 AMS 服务，fund-transfer 缓存30分钟）：

```go
type LimitConfig struct {
    KYCTier             string
    Currency            string
    // Deposit limits
    DepositMinPerTx     decimal.Decimal
    DepositMaxPerTx     decimal.Decimal
    DepositDailyMax     decimal.Decimal
    DepositMonthlyMax   decimal.Decimal
    // Withdrawal limits
    WithdrawMinPerTx    decimal.Decimal
    WithdrawMaxPerTx    decimal.Decimal
    WithdrawDailyMax    decimal.Decimal
    WithdrawMonthlyMax  decimal.Decimal
}
```

| KYC 层级 | 入金单笔最大 | 入金日限 | 入金月限 | 出金单笔最大 | 出金日限 | 出金月限 |
|----------|------------|--------|--------|------------|--------|--------|
| Basic | $2,000 | $2,000 | $10,000 | $1,000 | $1,000 | $5,000 |
| Standard | $50,000 | $50,000 | $200,000 | $25,000 | $25,000 | $100,000 |
| Enhanced | $500,000 | $500,000 | $2,000,000 | $250,000 | $250,000 | $1,000,000 |
| VIP | 自定义 | 自定义 | 自定义 | 自定义 | 自定义 | 自定义 |

### 2.2 日限额重置时间

**日限额以 UTC 00:00 为重置节点，不使用用户本地时间。**

理由：
1. 系统统一时区，避免用户通过切换时区规避限额。
2. 与银行端对账周期对齐（银行报表以 UTC 或固定时区计算当日汇总）。
3. 对用户的影响说明需在帮助文档中注明（例如，UTC+8 用户的"今日限额"在 08:00 本地时间重置）。

**用户界面**需展示：
- 今日已使用额度 / 今日剩余额度（附注"每日 08:00（北京时间）重置"）
- 本月已使用额度 / 本月剩余额度（附注"每月1日 08:00（北京时间）重置"）

实际展示的本地时间需在 Mobile 端转换，API 只返回 UTC 时间戳。

### 2.3 月限额重置时间

**月限额在每月1日 UTC 00:00 重置。**

边界情况：
- 2月、30天月份等短月，月底不产生特殊影响（以1日为重置点，不以月底为结算点）。
- 跨月连续请求：月末最后一秒提交的请求，使用旧月的余量；月初第一秒提交的请求，使用新月的全额限额。月份归属以请求**创建时间（`created_at` UTC）**为准，不以完成时间为准。

### 2.4 并发请求的竞态处理

**问题场景：** 用户同时在两个设备提交出金请求，每笔金额在单独看都在限额内，但两笔合计超出日限额。

**解决方案：Redis 原子 INCR + Lua 脚本**

限额计数器的 Key 设计：

```
limit:{user_id}:{direction}:{currency}:daily:{YYYY-MM-DD}   TTL: 25小时（跨日缓冲）
limit:{user_id}:{direction}:{currency}:monthly:{YYYY-MM}    TTL: 33天（跨月缓冲）
```

原子检查并更新（Lua 脚本，在 Redis 单线程中执行，保证原子性）：

```lua
-- KEYS[1]: daily counter key
-- KEYS[2]: monthly counter key
-- ARGV[1]: amount (in cents, integer)
-- ARGV[2]: daily limit (in cents, integer)
-- ARGV[3]: monthly limit (in cents, integer)
-- ARGV[4]: daily TTL (seconds)
-- ARGV[5]: monthly TTL (seconds)
-- Returns: 0 = OK, 1 = daily exceeded, 2 = monthly exceeded

local daily_current = tonumber(redis.call('GET', KEYS[1])) or 0
local monthly_current = tonumber(redis.call('GET', KEYS[2])) or 0
local amount = tonumber(ARGV[1])
local daily_limit = tonumber(ARGV[2])
local monthly_limit = tonumber(ARGV[3])

if daily_current + amount > daily_limit then
    return 1
end
if monthly_current + amount > monthly_limit then
    return 2
end

redis.call('INCRBY', KEYS[1], amount)
redis.call('EXPIRE', KEYS[1], tonumber(ARGV[4]))
redis.call('INCRBY', KEYS[2], amount)
redis.call('EXPIRE', KEYS[2], tonumber(ARGV[5]))
return 0
```

**注意：** 计数器使用整数（分/厘，即金额 × 100）存储，避免小数精度问题。

**Rollback：** 出金请求最终失败（银行侧拒绝）时，必须将计数器回滚：

```go
func RollbackLimitCounter(ctx context.Context, userID int64, direction string,
    currency string, amount decimal.Decimal) error {
    // DECRBY the daily and monthly counters
    // Never let counter go below 0 (use MAX(0, current - amount) in Lua)
}
```

**出金状态为 HOLD（已冻结余额但未提交银行）期间，计数器已扣除；若最终失败则回滚计数器，同时释放余额冻结。**

### 2.5 新用户冷却期额外限制

账户开立后30天内（`account_created_at + 30 days > now()`），在 KYC 层级限额基础上叠加以下限制：

| 限制项 | 规则 |
|--------|------|
| 单笔出金上限 | $1,000 USD / HK$8,000（无论 KYC 层级） |
| 日出金上限 | $1,000 USD / HK$8,000 |
| 出金银行账户 | 只能向唯一主账户（is_primary = 1）出金 |
| 入金渠道 | 全部渠道可用，无额外限制 |
| 大额入金 | > $5,000 USD 需触发人工审核（即便 KYC 层级足够） |

冷却期到期后自动解除，无需用户操作。冷却期状态在限额检查时实时计算，不存储为单独字段（避免状态不一致）。

### 2.6 限额来源与缓存策略

限额配置来自 AMS 服务（KYC tier 决定），fund-transfer 服务不本地存储限额标准，但在 Redis 中维护实时计数器：

```
数据来源          用途                        缓存策略
--------          ----                        --------
AMS gRPC         获取用户 KYC 层级和限额配置   Redis TTL 30分钟，失效后同步回源
Redis            维护当日/当月累计已用额度      Atomic INCR/DECR，永不读 DB
MySQL            持久化每笔交易记录             交易完成后异步同步
```

AMS 不可用时的降级策略：
- 使用 Redis 中的缓存限额配置（最多30分钟旧数据）。
- 若缓存也失效，则拒绝出金请求（保守策略），同时触发告警。
- 入金请求可使用本地默认最低限额（Basic 层级）继续处理，不拒绝（入金风险低于出金）。

---

## 3. CTR 申报操作细节

### 3.1 触发条件

**美国 CTR（Currency Transaction Report，向 FinCEN 申报）：**

| 触发类型 | 条件 | 备注 |
|----------|------|------|
| 单笔超阈值 | 单笔入金或出金 > $10,000 USD | 现金等价物，ACH/Wire 均适用 |
| 当日累计超阈值 | 同一用户当日多笔合计 > $10,000 USD | 包括不同渠道的合计 |
| 拆单行为（Structuring） | 24小时内多笔合计 > $10,000，且单笔均 ≤ $10,000 | 独立触发 SAR，见第4节 |

**香港大额交易报告（向 JFIU 申报）：**

| 触发类型 | 条件 |
|----------|------|
| 单笔超阈值 | 单笔入金或出金 > HK$120,000 |
| 当日累计超阈值 | 同一用户当日合计 > HK$120,000 |

**注意：** CTR 阈值以美元或港币计算，不做跨币种合并计算（USD 和 HKD 分别独立计算各自阈值）。

### 3.2 结构化交易检测（Structuring Detection）

拆单（Structuring）是故意将大额交易拆分为多笔小额以规避 CTR 阈值的行为，是独立的洗钱罪行（无论是否达到 CTR 阈值）。

**检测算法：**

```
检测窗口: 滑动24小时窗口（非自然日）
检测范围: 同一用户，相同方向（入金或出金），相同货币
检测条件:
  1. 当前请求金额 < $10,000 USD（单笔未触发 CTR）
  2. 过去24小时内历史交易数量 >= 2笔
  3. 过去24小时累计金额 + 当前金额 > $8,000 USD（接近阈值，保守检测）
  4. 或：过去24小时内有任意连续N笔金额之和 > $10,000，N >= 2
```

**风险评分提升：**

```go
type StructuringSignal struct {
    UserID          int64
    WindowStart     time.Time   // now - 24h
    WindowEnd       time.Time   // now
    TransactionCount int
    TotalAmount     decimal.Decimal
    LargestSingleTx decimal.Decimal
    RiskScore       RiskLevel   // MEDIUM or HIGH
    SARRequired     bool
}
```

检测到拆单信号时：
- 将当前请求标记为 `AML_STATUS = REVIEW`
- 生成 SAR 候选记录（合规人员审核决定是否申报）
- 不阻止交易本身（除非 AML 风险评分为 HIGH）
- 不通知用户（Tipping-off 禁止，见第4节）

### 3.3 CTR 申报时限与流程

**FinCEN 要求：** 交易发生后 **15个日历日** 内提交 CTR（FinCEN Form 112）。

内部处理流程：

```
交易完成（COMPLETED）
        │
        ▼ (异步，< 1小时)
  CTR 触发检测
        │
        ├── 未触发 → 结束
        │
        └── 触发
              │
              ▼
       创建 CTR 草稿记录 (ctr_reports 表)
       status = DRAFT, deadline = created_at + 15天
              │
              ▼ (自动填充，< 24小时)
       填充 FinCEN 必填字段（见 3.4）
       status = PENDING_REVIEW
              │
              ▼ (合规人员确认，T+1 工作日)
       合规人员审核并补充信息
       status = READY_TO_FILE
              │
              ▼ (截止日 T-2 前自动提交)
       通过 FinCEN BSA E-Filing 系统提交
       status = FILED
              │
              ▼
       存档（5年）, status = ARCHIVED
```

**超时告警：**

| 时间节点 | 动作 |
|----------|------|
| 距截止日 5天 | 发送告警至合规团队（Slack + 邮件） |
| 距截止日 2天 | 升级告警，自动尝试以草稿状态提交 |
| 距截止日 0天 | 紧急告警，记录未及时申报风险事件 |

**申报失败的重试机制：**

```
提交到 FinCEN BSA E-Filing API 失败
        │
        ▼
  指数退避重试（最多5次）
  间隔: 1m, 5m, 15m, 60m, 240m
        │
        ├── 重试成功 → 更新状态 FILED
        │
        └── 5次全部失败
              │
              ▼
        status = FILING_FAILED
        立即触发 PagerDuty 告警（P1 级别）
        禁止相关用户发起新的大额出金
        合规人员手动处理
```

### 3.4 CTR 申报字段（FinCEN Form 112 核心字段）

```go
type CTRReport struct {
    // 元数据
    ReportID           string          `json:"report_id"`          // 内部唯一ID
    FinCENTrackingNum  string          `json:"fincen_tracking_num"` // 提交后由 FinCEN 返回
    FilingType         string          `json:"filing_type"`         // "INITIAL" / "CORRECT" / "AMENDMENT"
    FiledAt            *time.Time      `json:"filed_at"`
    Deadline           time.Time       `json:"deadline"`

    // Part I: 报告人信息 (Filing Institution)
    InstitutionName    string          `json:"institution_name"`   // 券商名称
    InstitutionEIN     string          `json:"institution_ein"`    // 税号
    InstitutionAddress Address         `json:"institution_address"`
    ContactName        string          `json:"contact_name"`
    ContactPhone       string          `json:"contact_phone"`

    // Part II: 交易信息
    TransactionDate    time.Time       `json:"transaction_date"`   // UTC，FinCEN 系统转换
    TransactionAmount  decimal.Decimal `json:"transaction_amount"` // USD
    TransactionType    string          `json:"transaction_type"`   // "DEPOSIT" / "WITHDRAWAL" / "WIRE_IN" / "WIRE_OUT"
    Channel            string          `json:"channel"`            // "ACH" / "WIRE" / "FPS" / "SWIFT"
    BankName           string          `json:"bank_name"`
    BankRoutingNumber  string          `json:"bank_routing_number"` // ABA routing number

    // Part III: 涉及人员信息
    PersonName         string          `json:"person_name"`        // 法定全名（来自 KYC）
    PersonDOB          string          `json:"person_dob"`         // YYYY-MM-DD
    PersonSSN          string          `json:"person_ssn"`         // 存储时加密，申报时解密
    PersonAddress      Address         `json:"person_address"`
    PersonOccupation   string          `json:"person_occupation"`
    IDType             string          `json:"id_type"`            // "PASSPORT" / "DL" / "STATE_ID"
    IDNumber           string          `json:"id_number"`          // 加密存储
    IDIssuingState     string          `json:"id_issuing_state"`

    // 内部字段
    TransferID         string          `json:"transfer_id"`        // 关联的 fund_transfers.transfer_id
    UserID             int64           `json:"user_id"`
    AggregatedTxIDs    []string        `json:"aggregated_tx_ids"`  // 当日累计触发时，列出所有关联交易
    ReviewedBy         int64           `json:"reviewed_by"`        // 合规人员 ID
    ReviewedAt         *time.Time      `json:"reviewed_at"`
    Notes              string          `json:"notes"`
}
```

### 3.5 CTR 记录存档要求

- CTR 记录（含草稿、已申报、被拒、申报失败各状态）保留 **5年**（FinCEN 要求）。
- 与 CTR 关联的交易记录、用户 KYC 信息快照（申报时的信息版本）一并存档。
- 存档格式：原始 JSON + FinCEN 系统返回的确认回执 PDF（存储至 S3 Object Lock，WORM 模式）。
- 不可删除、不可修改；如需修正，须通过 FinCEN 的"CORRECTION"申报流程提交修正版本，原版本保留。

### 3.6 香港大额交易报告（JFIU 申报）

对应香港的《有组织及严重罪行条例》（OSCO）和《联合国（反恐怖主义措施）条例》（UNATMO）要求，向联合财富情报组（JFIU）申报。

| 对应美国 CTR | 香港 JFIU 大额报告 |
|------------|-----------------|
| 阈值：$10,000 USD | 阈值：HK$120,000 |
| 系统：FinCEN BSA E-Filing | 系统：JFIU 在线申报平台 |
| 时限：15个日历日 | 时限：无强制法定时限，但内部规定7个工作日内 |
| 表格：FinCEN Form 112 | 表格：JFIU 指定格式 |

字段要求与美国 CTR 类似，但 ID 类型替换为 HKID / 护照，地址格式按香港标准。

---

## 4. SAR 申报操作细节

### 4.1 触发条件列表

SAR（Suspicious Activity Report，可疑交易报告）触发条件（满足任意一条即触发）：

| 类别 | 触发条件 | 风险等级 |
|------|----------|--------|
| 拆单行为 | 24小时内多笔合计超 $10,000，单笔均低于阈值 | HIGH |
| 快速资金转移 | 入金后24小时内出金，且未发生交易 | HIGH |
| 高频异常 | 7天内超过20笔出入金操作 | MEDIUM |
| 金额突变 | 本月出入金金额超过历史12个月平均值的10倍 | MEDIUM |
| 可疑地理位置 | 资金来源/去向涉及 FATF 高风险国家 | HIGH |
| 制裁名单匹配 | OFAC/SFC 匹配度 > 70%（模糊匹配后人工确认） | HIGH |
| 多账户关联 | 同一 IP / 设备绑定多个用户账户，疑似账户控制 | HIGH |
| 账户持续亏损 + 大额出金 | 持仓亏损 > 30% 后立即申请全额出金 | MEDIUM |
| 来源不明大额入金 | 单笔入金 > $50,000，用户无法说明资金来源 | MEDIUM |
| 内部黑名单 | 用户被标记为内部监控名单 | HIGH |

### 4.2 Tipping-off 禁止（反通风）

**这是 AML 合规中最严格的禁止性规则之一。**

根据《银行保密法》（BSA）、《香港联合国制裁条例》及 AMLO：

- **系统绝对不能**向涉嫌可疑活动的用户发送任何提示，无论是通知、错误信息、账户限制理由，还是任何暗示已被申报的信息。
- SAR 触发后，若账户受到限制，对用户的错误提示应使用**通用理由**（如"账户审核中"），而非提及可疑活动。
- 相关代码路径必须确保 SAR 状态字段（`sar_status`、`sar_report_id` 等）**永远不出现在任何面向用户的 API 响应中**。
- 内部日志、Admin Panel 中的 SAR 信息须设置独立权限（`ROLE_COMPLIANCE_OFFICER`），普通客服不可见。

代码层面的防护：

```go
// UserFacingTransferResponse must NEVER include SAR/AML internal fields.
// Use explicit allow-list projection, NOT exclude-list.
type UserFacingTransferResponse struct {
    TransferID      string          `json:"transfer_id"`
    Direction       string          `json:"direction"`
    Amount          decimal.Decimal `json:"amount"`
    Currency        string          `json:"currency"`
    Status          string          `json:"status"`      // generic status only
    CreatedAt       time.Time       `json:"created_at"`
    EstimatedArrival *time.Time     `json:"estimated_arrival,omitempty"`
    // NOTE: NO aml_status, NO risk_level, NO sar fields allowed here
}
```

### 4.3 申报时限

| 情况 | 时限 |
|------|------|
| 标准 SAR 申报 | 发现可疑交易后 **30个日历日** 内提交 |
| 需要额外调查 | 可延至 **60个日历日**，须在第30天记录延期理由 |
| 涉及紧急威胁（如恐怖融资） | **立即**通知 FinCEN（电话），SAR 书面申报跟进 |
| 香港 JFIU SAR | 发现后尽快申报，无强制法定时限，内部规定 **14个工作日** 内 |

**时限起算点：** 系统自动检测触发的 SAR 候选，起算点为系统检测到可疑信号的时间（`detected_at`）；合规人员通过人工审查发现的，起算点为人工发现记录的时间。

### 4.4 SAR 触发后账户处理

SAR 触发不等于立即限制账户，需区分阶段：

```
阶段1: 系统自动标记 (SAR_CANDIDATE)
  → 账户正常运行，不受任何限制
  → 仅内部标记，触发合规人员审核队列

阶段2: 合规人员初审 (SAR_UNDER_REVIEW)
  → 默认账户正常运行（避免 tipping-off）
  → 高风险情形（如恐怖融资）：合规主管可触发账户冻结
  → 冻结须走独立审批流程（双人确认），不由系统自动执行

阶段3: 决定申报 (SAR_TO_BE_FILED)
  → 账户处理由合规主管和法务共同决定
  → 选项A: 继续正常服务（多数情况，避免打草惊蛇）
  → 选项B: 限制出金（不限入金）
  → 选项C: 全账户冻结（须经法律顾问确认）

阶段4: 已申报 (SAR_FILED)
  → 后续处理遵照监管机构指令
  → 通常维持"继续服务"状态，除非监管机构明确要求暂停
```

任何账户限制操作均须记录在审计日志中，理由字段对外显示通用理由，内部字段记录真实原因（权限保护）。

### 4.5 内部升级流程

```
系统自动检测可疑信号
        │
        ▼
  生成 SAR 候选记录 (sar_candidates 表)
  发送通知至合规人员工作队列
        │
        ▼
  合规分析师审核 (L1)
  目标: 2个工作日内完成初审
        │
        ├── 不可疑 → 标记 FALSE_POSITIVE，关闭，记录理由
        │
        └── 可疑 → 升级至合规主管 (L2)
                       │
                       ▼
              合规主管审核
              目标: 3个工作日内完成
                       │
                       ├── 确认不申报 → 记录决策理由（须有充分书面依据）
                       │
                       └── 确认申报 → 起草 SAR 报告
                                        │
                                        ▼
                               法务顾问最终确认（可选，高风险必须）
                                        │
                                        ▼
                               通过 FinCEN BSA E-Filing / JFIU 提交
```

所有流程节点均记录：操作人、操作时间、决策理由、关联文件，不可修改（审计日志）。

---

## 5. Admin Panel 审批队列设计

### 5.1 审批队列数据结构

```go
// WithdrawalApprovalQueueItem 是审批队列的核心数据结构，供 Admin Panel 展示
type WithdrawalApprovalQueueItem struct {
    // 基础信息
    TransferID         string          `json:"transfer_id"`
    UserID             int64           `json:"user_id"`
    Amount             decimal.Decimal `json:"amount"`
    Currency           string          `json:"currency"`
    Channel            string          `json:"channel"`
    SubmittedAt        time.Time       `json:"submitted_at"`
    DeadlineAt         *time.Time      `json:"deadline_at"`       // 审批超时时间
    Priority           int             `json:"priority"`          // 1(最高) - 5(最低)
    QueuePosition      int             `json:"queue_position"`

    // 用户信息快照（来自 AMS，审批时固化）
    UserDisplayName    string          `json:"user_display_name"`
    KYCTier            string          `json:"kyc_tier"`
    AccountAgeDays     int             `json:"account_age_days"`
    PreviousWithdrawals int            `json:"previous_withdrawals_count"`
    TotalDepositedUSD  decimal.Decimal `json:"total_deposited_usd"`   // 历史累计入金

    // AML 结果摘要
    AMLStatus          string          `json:"aml_status"`        // PASS / REVIEW / BLOCK
    AMLRiskLevel       string          `json:"aml_risk_level"`    // LOW / MEDIUM / HIGH
    AMLFlags           []string        `json:"aml_flags"`         // 触发的规则名称列表
    SanctionsMatchScore float64        `json:"sanctions_match_score"` // 0.0-1.0
    StructuringSignal  bool            `json:"structuring_signal"`

    // 银行账户信息
    BankAccountLast4   string          `json:"bank_account_last4"`
    BankName           string          `json:"bank_name"`
    BankAccountAgeDays int             `json:"bank_account_age_days"`
    BankAccountVerified bool           `json:"bank_account_verified"`
    PreviousTxWithSameBank int         `json:"previous_tx_same_bank"`

    // 资金来源说明（用户提交的）
    FundSourceDeclaration *string      `json:"fund_source_declaration,omitempty"`
    SupportingDocuments  []DocumentRef `json:"supporting_documents,omitempty"`

    // 审批级别
    ApprovalLevel      string          `json:"approval_level"`    // "L1_SINGLE" / "L2_DUAL" / "L3_COMPLIANCE"
    AssignedTo         *int64          `json:"assigned_to,omitempty"`
    AssignedAt         *time.Time      `json:"assigned_at,omitempty"`

    // 历史记录摘要（最近90天）
    RecentDepositCount     int          `json:"recent_deposit_count"`
    RecentWithdrawCount    int          `json:"recent_withdraw_count"`
    RecentAMLFlagCount     int          `json:"recent_aml_flag_count"`
    NetFundFlow            decimal.Decimal `json:"net_fund_flow"` // 入金 - 出金（90天）
}
```

### 5.2 优先级排序规则

队列优先级由以下因素综合计算，数值越小优先级越高（1 = 最高优先级）：

```go
func CalculatePriority(item WithdrawalApprovalQueueItem) int {
    score := 5  // 默认最低优先级

    // 规则1: 大额提升优先级（大额需要更快处理，避免用户等待过长）
    if item.Amount.GreaterThan(decimal.NewFromInt(100000)) {
        score = min(score, 1)
    } else if item.Amount.GreaterThan(decimal.NewFromInt(50000)) {
        score = min(score, 2)
    }

    // 规则2: 高 AML 风险提升优先级（需尽快审查，防止资金外逃）
    if item.AMLRiskLevel == "HIGH" {
        score = min(score, 1)
    } else if item.AMLRiskLevel == "MEDIUM" {
        score = min(score, 2)
    }

    // 规则3: 等待时长提升优先级（SLA 保障）
    waitHours := time.Since(item.SubmittedAt).Hours()
    if waitHours > 4 {
        score = min(score, 2)
    } else if waitHours > 2 {
        score = min(score, 3)
    }

    // 规则4: 临近超时提升优先级
    if item.DeadlineAt != nil && time.Until(*item.DeadlineAt) < 30*time.Minute {
        score = 1  // 强制最高优先级
    }

    return score
}
```

**同优先级内的排序：** 按提交时间升序（先到先审）。

### 5.3 审批人界面必须展示的信息清单

以下信息在审批页面中**必须全部展示**，审批人不得以"信息不足"为由拒绝审批（审批人有责任请求补充材料）：

**一、基础交易信息**
- 申请时间、金额、币种、渠道
- 目标银行账户（显示 `****XXXX`、银行名称、账户类型）
- 银行账户绑定时间、是否已验证、历史使用记录
- 预计到账时间（含节假日影响说明）

**二、用户 KYC 信息**
- 法定姓名（脱敏）、KYC 层级、账户注册日期
- KYC 验证时间、上次 KYC 更新时间
- 居住国家/地区（涉及制裁名单检查）

**三、账户资金历史（近90天）**
- 总入金金额 / 笔数
- 总出金金额 / 笔数
- 净资金流量（入金 - 出金）
- 最大单笔入金 / 出金
- 资金用途（是否有实质交易记录，还是纯出入金）

**四、AML 检查结果**
- 综合风险评级（LOW / MEDIUM / HIGH）
- 触发的具体 AML 规则（逐条列出）
- 制裁名单匹配得分（若 > 0）
- 近30天 AML 标记历史

**五、资金来源说明**（大额或 MEDIUM/HIGH 风险时必填）
- 用户填写的资金来源说明
- 上传的支持文件（工资单、合同、银行流水截图等）
- 文件审核状态

**六、审批历史**
- 本笔申请的历史审批记录（若曾被退回）
- 该用户过去审批记录摘要（通过率、拒绝原因）

### 5.4 单级审批 vs 双级审批的触发条件

| 审批级别 | 触发条件 | 审批人要求 | SLA |
|----------|----------|----------|-----|
| L1 单级审批 | 金额 $50,000 – $200,000；银行账户绑定7-30天；用户年龄 < 30天；AML = MEDIUM | 任意一名合规分析师 | 2小时 |
| L2 双级审批 | 金额 $200,000 – $500,000；AML = HIGH；结构化交易信号；SAR候选 | 合规分析师 + 合规主管（两人均须确认） | 4小时 |
| L3 合规官审批 | 金额 > $500,000；SAR 已触发；多次 AML 标记；用户在内部监控名单 | 首席合规官（CCO）或其授权代理 | 8小时 |

**双级审批（L2）的操作流程：**

```
审批人A（合规分析师）: 填写初审意见 → 选择 "同意" 或 "拒绝" 或 "需补充信息"
        │ (仅同意时继续)
        ▼
审批人B（合规主管）: 查看A的意见 + 独立审查 → 最终决定
        │
        ├── 两人均同意 → 执行出金
        ├── 任一方拒绝 → 拒绝出金，通知用户（通用理由）
        └── 任一方要求补充 → 通知用户补充材料，重新排队
```

双级审批中，A 和 B **不能为同一人**（系统层面强制校验）。A 的审批意见对 B 可见但不具约束力，B 必须独立做出判断。

### 5.5 审批超时处理

| 审批级别 | 超时时间 | 超时动作 |
|----------|----------|--------|
| L1 | 4小时（2小时 SLA + 2小时缓冲） | 升级为 L2，同时通知合规主管 |
| L2 | 8小时（4小时 SLA + 4小时缓冲） | 升级为 L3，通知 CCO |
| L3 | 24小时 | **自动拒绝**，通知用户"申请未能在规定时间内完成审核，请重新提交" |

**重要说明：** L1 和 L2 超时选择"升级"而非"自动拒绝"，是因为大额出金审批中如果误拒绝，对用户体验影响极大，且可能引发投诉。但 L3 超时自动拒绝，是因为 L3 涉及的案例通常具有更高风险，且 CCO 24小时未处理说明存在异常情况，保守处理（拒绝）风险更低。

**超时拒绝的后续处理：**
- 释放已冻结的用户余额（即如果余额已被 HOLD，需解冻）
- 用户可重新提交申请（如果超时拒绝是系统问题而非风控问题）
- 若是 L3 超时拒绝且用户重新提交，直接进入 L3 队列（不降级）

### 5.6 审批记录不可篡改要求

所有审批操作须写入 append-only 的 `approval_audit_log` 表，且通过以下机制保证不可篡改：

```sql
CREATE TABLE approval_audit_log (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    log_id          CHAR(36) UNIQUE NOT NULL,         -- UUID
    transfer_id     CHAR(36) NOT NULL,
    operator_id     BIGINT UNSIGNED NOT NULL,
    operator_role   VARCHAR(32) NOT NULL,
    action          VARCHAR(32) NOT NULL,             -- APPROVE / REJECT / REQUEST_INFO / ASSIGN / ESCALATE / TIMEOUT
    decision        VARCHAR(16),                      -- APPROVE / REJECT / PENDING
    reason_internal TEXT NOT NULL,                    -- 内部理由（高权限可见）
    reason_external TEXT,                             -- 对用户显示的理由（通用）
    amount_at_review DECIMAL(20,2) NOT NULL,          -- 审批时的金额（快照）
    risk_level_at_review VARCHAR(8) NOT NULL,         -- 审批时的风险等级（快照）
    ip_address      VARCHAR(64) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- No updated_at: this table is append-only
    INDEX idx_approval_log_transfer (transfer_id, created_at),
    INDEX idx_approval_log_operator (operator_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

- 数据库用户对该表只有 `INSERT` 权限，无 `UPDATE` / `DELETE` 权限。
- 每条审批记录包含操作时的**金额快照**和**风险等级快照**，防止事后数据被修改后影响历史审批记录的解读。
- 审批记录导出（用于监管审查）须通过专用导出接口，记录每次导出操作（`audit_log_exports` 表）。

---

## 6. 银行账户生命周期边界

### 6.1 最多5个银行账户的强制执行

**数量上限：** 每个用户最多绑定5个处于 `active` 状态的银行账户（`is_active = 1`）。被软删除（`is_active = 0`）的账户不计入上限。

**超出时的处理逻辑：**

```go
func (s *BankAccountService) AddBankAccount(ctx context.Context,
    userID int64, req AddBankAccountRequest) error {

    // 1. 查询当前 active 账户数量（SELECT ... FOR UPDATE 防并发）
    count, err := s.repo.CountActiveBankAccounts(ctx, userID)
    if err != nil {
        return fmt.Errorf("count active bank accounts for user %d: %w", userID, err)
    }

    if count >= 5 {
        return ErrBankAccountLimitReached{
            CurrentCount: count,
            MaxAllowed:   5,
            // 返回可操作的提示信息：列出哪些账户可以删除
        }
    }

    // 2. 继续添加流程...
}
```

**用户界面提示（当账户数量达到5个时）：**

- 在银行账户列表顶部展示提示："您已绑定5个银行账户（上限）。如需添加新账户，请先删除一个现有账户。"
- 添加按钮变为灰色不可点击状态。
- 若用户点击灰色按钮，弹出提示并导航至账户管理页面。

**并发添加防护：**

添加银行账户时使用 `SELECT COUNT(*) ... FOR UPDATE`（对用户行加锁）或 MySQL 的 `unique + trigger` 方式，防止两个并发请求同时绕过数量检查：

```sql
-- 在事务内先加锁，再插入
SELECT COUNT(*) FROM bank_accounts
WHERE user_id = ? AND is_active = 1
FOR UPDATE;
```

### 6.2 软删除规则

银行账户**永远不做物理删除**，仅做软删除（标记为不活跃）。

```sql
-- 软删除操作
UPDATE bank_accounts
SET
    is_active       = 0,
    is_primary      = 0,          -- 同时取消主账户标记
    deactivated_at  = NOW(),
    deactivated_by  = ?            -- 操作人（用户自己 or 管理员）
WHERE id = ? AND user_id = ?;
```

**软删除后的业务影响：**

| 操作 | 是否允许 |
|------|--------|
| 新发起入金到此账户 | 不允许（渠道选择时不展示非 active 账户） |
| 新发起出金到此账户 | 不允许 |
| 历史交易记录关联 | 允许（历史记录通过 `bank_account_id` 关联，软删除不影响历史） |
| 审计查询 | 允许（合规查询时可查出已删除账户的历史记录） |
| 重新激活 | 需要重新走完整的绑定验证流程（相当于重新绑定） |

**软删除的数据保留期限：** 按照 Rule 9 的规范，银行账户数据在账户关闭后保留6年（满足 KYC 要求）。即便平台用户账户注销，银行账户记录也保留至法定最短期限。

### 6.3 银行账户变更与冷却期重置规则

**"变更"的定义：**

| 操作 | 是否属于"变更"（重置冷却期） |
|------|--------------------------|
| 解绑后重新绑定完全相同的账号 | **是**，视为新绑定，冷却期重置 |
| 修改账户昵称 | 否，不重置 |
| 从非主账户设为主账户 | 否，不重置 |
| 银行名称变更（如银行合并后行名更新） | 否（由系统管理员批量更新），不重置 |
| 更换账号（即使同一家银行） | 是，视为新绑定 |

**重新绑定相同账号重置冷却期的理由：**

从风控角度，解绑再重新绑定可能是用户试图绕过冷却期限制（例如：绑定账户 → 发现冷却期太长 → 解绑 → 重绑以刷新状态）。系统不应允许通过此操作规避冷却期，因此重新绑定相同账号须重置冷却期计时。

**冷却期计算逻辑：**

```go
func (ba *BankAccount) WithdrawalCooldownExpired() bool {
    if ba.CooldownUntil == nil {
        return true  // 无冷却期限制（如老用户历史账户）
    }
    return time.Now().UTC().After(*ba.CooldownUntil)
}

func NewBankAccountCooldownUntil(bindAt time.Time) time.Time {
    // 冷却期3天（Rule 3），从绑定时间起算
    return bindAt.UTC().Add(3 * 24 * time.Hour)
}
```

**银行账户变更需要重新验证（身份确认）：**

任何银行账户的添加或更改（包括重新绑定），均需通过以下任一方式进行身份确认：
- 生物识别（Face ID / Touch ID）
- 短信 OTP（发送至 KYC 绑定的手机号）
- 2FA（如 TOTP）

验证通过后，才能进入 Micro-deposit 验证流程（发送小额验证金额确认账户所有权）。

### 6.4 主账户（is_primary）切换规则

**主账户的业务含义：**
- 用户在新用户冷却期（账户开立30天内）只能向主账户出金。
- 出金渠道默认展示主账户，减少用户误操作。
- 仅一个银行账户可标记为主账户（`is_primary = 1`），其余均为 `is_primary = 0`。

**切换主账户的规则：**

| 条件 | 规则 |
|------|------|
| 目标账户必须已验证 | `verified = 1`，否则不允许设为主账户 |
| 目标账户必须为 active | `is_active = 1` |
| 目标账户不在冷却期 | `cooldown_until IS NULL OR cooldown_until < NOW()` |
| 身份验证 | 切换主账户操作须通过生物识别或 2FA 验证 |
| 原主账户 | 自动取消主账户标记（不需要额外操作） |

**切换主账户时的数据库操作（必须在一个事务内）：**

```sql
BEGIN;

-- 取消旧主账户
UPDATE bank_accounts
SET is_primary = 0
WHERE user_id = ? AND is_primary = 1;

-- 设置新主账户（同时检查验证状态和冷却期）
UPDATE bank_accounts
SET is_primary = 1
WHERE id = ?
  AND user_id = ?
  AND is_active = 1
  AND verified = 1
  AND (cooldown_until IS NULL OR cooldown_until < NOW());

-- 检查影响行数，若为0则回滚
COMMIT;
```

**注意：** 若用户只有一个 active 银行账户，不允许取消其主账户标记（必须至少有一个主账户，或0个主账户）。实际上，系统允许 `is_primary = 0`（无主账户）的状态存在，此时用户可以选择任意已验证账户进行出金，但新用户冷却期出金受限。

**主账户被软删除时的处理：**

删除当前主账户时，系统须：
1. 将该账户的 `is_primary` 置为 0（软删除操作已包含）。
2. 检查是否有其他 active + verified + 非冷却期的账户，若有，**不自动设置主账户**（避免未经用户授权的自动切换）。
3. 通知用户："您的主账户已删除，请设置新的主账户。" （若用户处于冷却期且无主账户，出金功能将暂时不可用。）

---

*文档末尾 — 本文档为工程实现参考规范，如需调整请通过 PR 流程更新并知会合规团队。*