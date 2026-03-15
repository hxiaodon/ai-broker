# FX 换汇完整业务流程设计规范

---

## 1. 业务背景

### 1.1 用户为什么需要换汇

券商平台同时支持美股（NYSE/NASDAQ，以 USD 结算）和港股（HKEX，以 HKD 结算）交易。用户在两个市场之间切换时，需要在平台内完成货币转换：

| 场景 | 方向 | 触发时机 |
|------|------|----------|
| 买入港股，账户只有 USD | USD → HKD | 下单前主动换汇，或平台自动换汇 |
| 港股卖出后，想投资美股 | HKD → USD | 手动发起，或自动结算触发 |
| 从港元银行账户入金后买美股 | HKD → USD | 入金完成后，用户主动换汇 |
| 美股卖出，想出金至港元账户 | USD → HKD | 出金前换汇 |

平台需要维护用户的多币种余额子账户（USD 子账户、HKD 子账户），换汇即为在两个子账户之间转移价值，并记录汇差收入。

### 1.2 券商换汇 vs 银行换汇

| 对比维度 | 券商内部换汇 | 用户去银行换汇 |
|----------|-------------|--------------|
| 资金流向 | 在平台内两个子账户之间流转，资金不离开平台 | 资金必须先出金到银行，换汇后再入金，经历 2 次出入金流程 |
| 时效 | 实时（秒级到账） | T+1 至 T+2，受出入金通道限制 |
| 费用 | Spread 0.1%~0.3%，无出入金手续费 | 银行换汇 Spread 通常 0.3%~1%，叠加出入金手续费 |
| 用户体验 | 无缝，直接在 App 内完成 | 操作繁琐，需要跨 App 操作 |
| 资金安全 | 资金始终在平台托管账户内，无出金风险 | 出金过程存在银行通道风险 |
| 监管处理 | 仅需记录换汇事件，无 AML 重新触发 | 出入金各需独立的 AML 筛查 |

结论：券商内部换汇对用户更优，对平台也节省了出入金通道成本，是首选路径。

### 1.3 换汇收入模型（Spread 定价）

平台通过在市场中间价基础上加收 Spread 作为换汇收入：

```
用户成交汇率 = 市场中间价 × (1 ± Spread%)
```

| Spread 策略 | USD → HKD（用户卖 USD 买 HKD） | HKD → USD（用户卖 HKD 买 USD） |
|-------------|-------------------------------|-------------------------------|
| 市场中间价示例 | 1 USD = 7.780 HKD | 1 HKD = 0.12853 USD |
| Spread 0.2% | 用户实际得到 7.780 × 0.998 = 7.7644 HKD | 用户实际得到 0.12853 × 0.998 = 0.12827 USD |
| 平台毛利 | 每 1,000 USD 换汇收入 ≈ USD 1.56 | 每 1,000 HKD 换汇收入 ≈ HKD 0.26 |

Spread 分级（可配置，不可硬编码）：

| 换汇金额（USD 等值） | Spread |
|--------------------|--------|
| < $5,000 | 0.30% |
| $5,000 ~ $50,000 | 0.20% |
| $50,000 ~ $500,000 | 0.15% |
| > $500,000（VIP） | 0.10%（谈判制） |

---

## 2. 完整换汇时序

### 2.1 时序图

```
User          App           API Gateway        FX Service        Rate Provider        MySQL             Redis
 │             │                │                  │                   │                │                │
 │──请求报价──▶│                │                  │                   │                │                │
 │             │──GET /fx/quote▶│                  │                   │                │                │
 │             │                │──GetQuote()──────▶                   │                │                │
 │             │                │                  │──GetSpotRate()───▶│                │                │
 │             │                │                  │◀──market_rate─────│                │                │
 │             │                │                  │                   │                │                │
 │             │                │                  │ 计算用户汇率        │                │                │
 │             │                │                  │ (market ± spread) │                │                │
 │             │                │                  │                   │                │                │
 │             │                │                  │──SET fx:quote:{quoteId} TTL=30s ─────────────────▶│
 │             │                │                  │                   │                │                │
 │             │◀──quote_id,────│◀──QuoteResponse──│                   │                │                │
 │◀──报价展示──│   rate, expires│                  │                   │                │                │
 │             │                │                  │                   │                │                │
 │  (用户确认，30秒内有效)        │                  │                   │                │                │
 │             │                │                  │                   │                │                │
 │──确认换汇──▶│                │                  │                   │                │                │
 │             │──POST /fx/exec▶│                  │                   │                │                │
 │             │  {quote_id,    │                  │                   │                │                │
 │             │   idempotency} │──ExecuteFX()─────▶                   │                │                │
 │             │                │                  │──WATCH + GET fx:quote:{quoteId} ─────────────────▶│
 │             │                │                  │◀──quote (or nil if expired) ─────────────────────│
 │             │                │                  │                   │                │                │
 │             │                │         [expired → QuoteExpiredError]│                │                │
 │             │                │                  │                   │                │                │
 │             │                │                  │──BEGIN TX─────────────────────────▶                │
 │             │                │                  │  INSERT fx_orders (PROCESSING)    │                │
 │             │                │                  │  SELECT account_balances FOR UPDATE│               │
 │             │                │                  │  验证余额充足      │                │                │
 │             │                │                  │  UPDATE from_currency balance -X  │                │
 │             │                │                  │  UPDATE to_currency balance +Y    │                │
 │             │                │                  │  INSERT ledger_entries (3 rows)   │                │
 │             │                │                  │  UPDATE fx_orders (COMPLETED)     │                │
 │             │                │                  │──COMMIT───────────────────────────▶                │
 │             │                │                  │                   │                │                │
 │             │                │                  │──DEL fx:quote:{quoteId}（防重用）────────────────▶│
 │             │                │◀──FXResult───────│                   │                │                │
 │             │◀──换汇成功──────│                  │                   │                │                │
 │◀──通知推送──│                │                  │                   │                │                │
```

### 2.2 各步骤说明

**Step 1 — 用户请求报价（GetQuote）**
- 用户输入换汇金额和方向（USD → HKD 或 HKD → USD）
- 系统从汇率源拉取当前市场中间价（见 §3）
- 计算用户实际汇率 = 中间价 ± Spread
- 生成 `quote_id`（UUID v4），写入 Redis，TTL = 30 秒
- 返回：报价 ID、用户汇率、到期时间戳、预计到账金额

**Step 2 — 锁价有效期（30 秒窗口）**
- 30 秒内汇率锁定，App 前端同步倒计时
- 到期后 Redis Key 自动删除，报价失效
- 到期前 5 秒提示用户"汇率即将失效"

**Step 3 — 用户确认**
- 提交 `quote_id` + `idempotency_key`
- 大额换汇（> $50,000 USD 等值）要求生物识别或 2FA

**Step 4 — 系统执行换汇**
- Redis WATCH + MULTI/EXEC 原子标记报价为 used（防并发重用）
- MySQL 事务：余额验证 → 双账户更新 → 3 条 Ledger 分录 → 订单状态 COMPLETED
- 执行完成后 DEL Redis 报价 Key

**Step 5 — 通知**
- 推送通知 + App 余额实时刷新
- 可选：邮件确认单（含汇率、Spread、流水号）

---

## 3. 汇率来源与锁价机制

### 3.1 实时汇率来源

```
┌──────────────────────────────────────────────────────────┐
│                Rate Provider Aggregator                   │
│                                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐  │
│  │ Reuters     │  │ Bloomberg   │  │ Bank (HSBC/Citi) │  │
│  │ (Primary)   │  │ (Backup)    │  │ (Fallback)       │  │
│  └──────┬──────┘  └──────┬──────┘  └────────┬─────────┘  │
│         └────────────────┴──────────────────┘             │
│                          │                                │
│              ┌───────────▼──────────┐                    │
│              │  Rate Aggregation    │                    │
│              │  - Mid-price         │                    │
│              │  - Stale check (<60s)│                    │
│              │  - Spike detection   │                    │
│              └───────────┬──────────┘                    │
└──────────────────────────┼───────────────────────────────┘
                           │ 本地缓存 TTL=5s
                    ┌──────▼──────┐
                    │  FX Service │
                    └─────────────┘
```

- **主源**：Reuters Elektron（USD/HKD 实时 Spot Rate）
- **备源**：Bloomberg B-PIPE（主源故障时自动切换）
- **兜底**：汇丰/花旗银行 API 报价
- **本地缓存**：FX Service 内存缓存，TTL = 5 秒
- **汇率新鲜度**：超过 60 秒未更新视为 Stale，拒绝生成新报价并触发告警

### 3.2 锁价 Redis 数据结构

```
Key:   fx:quote:{quote_id}
TTL:   30 秒
Value: JSON
```

```json
{
  "quote_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": 100001,
  "from_currency": "USD",
  "to_currency": "HKD",
  "from_amount": "1000.00",
  "to_amount": "7764.40",
  "market_rate": "7.78000000",
  "spread_pct": "0.2000",
  "user_rate": "7.76440000",
  "spread_amount_hkd": "15.60",
  "rate_source": "REUTERS",
  "rate_fetched_at": "2026-03-15T09:30:00.123Z",
  "quote_created_at": "2026-03-15T09:30:01.456Z",
  "expires_at": "2026-03-15T09:30:31.456Z",
  "used": false
}
```

### 3.3 并发防重用（Redis 乐观锁）

```go
func (r *rateLocker) ClaimQuote(ctx context.Context, quoteID string) (*FXQuote, error) {
    var quote *FXQuote
    err := r.redisClient.Watch(ctx, func(tx *redis.Tx) error {
        raw, err := tx.Get(ctx, fxQuoteKey(quoteID)).Result()
        if errors.Is(err, redis.Nil) {
            return ErrQuoteExpired
        }
        if err != nil {
            return fmt.Errorf("get fx quote %s: %w", quoteID, err)
        }
        if err := json.Unmarshal([]byte(raw), &quote); err != nil {
            return fmt.Errorf("unmarshal fx quote: %w", err)
        }
        if quote.Used {
            return ErrQuoteAlreadyUsed
        }
        quote.Used = true
        updated, _ := json.Marshal(quote)
        _, err = tx.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
            pipe.Set(ctx, fxQuoteKey(quoteID), updated, 30*time.Second)
            return nil
        })
        return err
    }, fxQuoteKey(quoteID))
    return quote, err
}
```

三重防并发：
1. Redis WATCH + MULTI/EXEC 乐观锁（防同一报价被两个请求同时执行）
2. `idempotency_key` Redis 去重（防客户端重试）
3. `fx_orders.idempotency_key` 唯一索引（数据库层兜底）

### 3.4 锁价过期处理

```
用户点击确认
    │
    ▼
GET fx:quote:{quote_id}
    ├── Key 不存在（TTL 已到）
    │       → 返回 QUOTE_EXPIRED，App 自动触发重新报价
    └── used = true
            → 返回 QUOTE_ALREADY_USED（幂等重试场景）
```

---

## 4. 账本分录设计

### 4.1 完整双边记账（USD 1,000 → HKD 示例）

```
市场中间价：1 USD = 7.7800 HKD
Spread：0.2%
用户实际汇率：7.7644
用户实际到账：HKD 7,764.40
Spread 收入：HKD 15.60
```

```
── 分录 1：扣减用户 USD 余额 ─────────────────────────────────────────
entry_type:     FX_DEBIT
debit_account:  user:{user_id}:usd:available
credit_account: platform:fx_pool:usd
amount:         1000.00  USD

── 分录 2：增加用户 HKD 余额 ─────────────────────────────────────────
entry_type:     FX_CREDIT
debit_account:  platform:fx_pool:hkd
credit_account: user:{user_id}:hkd:available
amount:         7764.40  HKD

── 分录 3：平台 Spread 收入 ──────────────────────────────────────────
entry_type:     FX_SPREAD_INCOME
debit_account:  platform:fx_pool:hkd
credit_account: platform:income:fx_spread
amount:         15.60  HKD
```

三笔分录在同一 MySQL 事务中原子写入。

### 4.2 FX Rate Snapshot 表

```sql
CREATE TABLE fx_rate_snapshots (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fx_order_id      CHAR(36) NOT NULL,
    from_currency    VARCHAR(8) NOT NULL,
    to_currency      VARCHAR(8) NOT NULL,
    market_rate      DECIMAL(16, 8) NOT NULL,
    spread_pct       DECIMAL(8, 4) NOT NULL,
    user_rate        DECIMAL(16, 8) NOT NULL,
    rate_source      VARCHAR(32) NOT NULL,
    rate_fetched_at  TIMESTAMP(3) NOT NULL,
    quote_created_at TIMESTAMP(3) NOT NULL,
    executed_at      TIMESTAMP(3) NOT NULL,
    INDEX idx_fx_snapshots_order (fx_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

用途：合规审计、P&L 分析、用户争议处理。

---

## 5. 失败与补偿

### 5.1 失败场景树

```
执行换汇
    ├── 锁价已过期                → 返回错误，无资金变动，无需补偿
    ├── 余额不足                  → 返回错误，事务回滚，无需补偿
    ├── MySQL 事务中途失败（回滚） → Redis Quote 重置为未使用，允许重试
    ├── MySQL 超时（状态未知）     → 见 §5.3
    └── 系统崩溃（写 Ledger 后）  → Recovery Job 检测 PROCESSING 超时订单并修复
```

### 5.2 Saga 补偿操作

| 正向步骤 | 补偿操作 |
|---------|---------|
| 标记 Quote 为 used | 重置 Quote used=false（或让其自然过期） |
| INSERT fx_orders (PROCESSING) | UPDATE fx_orders SET status='FAILED' |
| 扣减 USD 余额 | 写反向 Ledger Entry，恢复 USD 余额 |
| 增加 HKD 余额 | 写反向 Ledger Entry，恢复 HKD 余额 |
| 写 3 条 Ledger 分录 | 写 3 条反向冲销分录（不删除原记录） |
| UPDATE fx_orders (COMPLETED) | UPDATE fx_orders SET status='REVERSED' |

**关键原则**：补偿 ≠ 删除，账本永远 append-only，冲销通过写反向分录实现。

### 5.3 MySQL 超时（不确定状态）处理

```
FX Service 发出 COMMIT → 网络超时 → 不知道是否成功

处理流程：
  1. 将 fx_order 标记为 PROCESSING（不确定）
  2. Recovery Job 每 30 秒运行：
     - 查询 status='PROCESSING' 且 updated_at < now()-2min 的订单
     - 检查对应 ledger_entries 是否存在
     - 存在 → 事务已成功，更新为 COMPLETED
     - 不存在 → 事务已回滚，更新为 FAILED，释放 Quote
  3. 用户 App 显示"换汇处理中"直到 Recovery Job 确认
  4. 确认后推送最终通知
```

---

## 6. 风控规则

### 6.1 单次换汇金额限制

| KYC 等级 | 单次最大（USD 等值） |
|----------|-------------------|
| Basic | $5,000 |
| Standard | $100,000 |
| Enhanced | $1,000,000 |
| VIP | 无上限（RM 确认） |

### 6.2 单日累计换汇限额

| KYC 等级 | 单日上限（USD 等值） | 重置时间 |
|----------|-------------------|---------|
| Basic | $5,000 | 00:00 UTC |
| Standard | $200,000 | 00:00 UTC |
| Enhanced | $2,000,000 | 00:00 UTC |

### 6.3 异常汇率检测

USD/HKD 联系汇率制，合法区间 7.70~7.90：

```go
const (
    USDHKDHardFloor      = "7.70"
    USDHKDHardCeil       = "7.90"
    SpikeAlertThreshold  = "0.005"  // 偏离5分钟均价 >0.5% 告警
    SpikeRejectThreshold = "0.010"  // 偏离5分钟均价 >1.0% 拒绝报价
)
```

触发后：拒绝报价 → 降级备源重试 → 告警通知风控团队。

### 6.4 新账户限制

注册 < 7 天的账户：单笔上限 $2,000 USD 等值，日累计 $5,000 USD 等值。

---

## 7. 系统设计

### 7.1 换汇订单表

```sql
CREATE TABLE fx_orders (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fx_order_id      CHAR(36) UNIQUE NOT NULL,
    user_id          BIGINT UNSIGNED NOT NULL,
    from_currency    VARCHAR(8) NOT NULL,
    to_currency      VARCHAR(8) NOT NULL,
    from_amount      DECIMAL(20, 2) NOT NULL,
    to_amount        DECIMAL(20, 2) NOT NULL,
    market_rate      DECIMAL(16, 8) NOT NULL,
    spread_pct       DECIMAL(8, 4) NOT NULL,
    user_rate        DECIMAL(16, 8) NOT NULL,
    spread_amount    DECIMAL(20, 6) NOT NULL,
    rate_source      VARCHAR(32) NOT NULL,
    quote_id         CHAR(36) NOT NULL,
    idempotency_key  CHAR(36) UNIQUE NOT NULL,
    status           VARCHAR(16) NOT NULL,
    -- PENDING / PROCESSING / COMPLETED / FAILED / EXPIRED / REVERSED
    failure_reason   TEXT,
    rate_fetched_at  TIMESTAMP(3) NOT NULL,
    quote_created_at TIMESTAMP(3) NOT NULL,
    executed_at      TIMESTAMP(3) NULL,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_fx_orders_user   (user_id, created_at),
    INDEX idx_fx_orders_status (status),
    INDEX idx_fx_orders_quote  (quote_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 7.2 与 fund_transfers 表的关系

| 维度 | fund_transfers | fx_orders |
|------|---------------|-----------|
| 资金流向 | 平台内外（银行 ↔ 托管账户） | 平台内（USD子账户 ↔ HKD子账户） |
| 是否触达银行 | 是 | 否 |
| AML 筛查 | 每笔必须 | 否（入金时已筛查） |
| 结算周期 | T+1～T+3 | 实时 |
| 锁价机制 | 无 | 是（30秒 TTL） |

两者共享 `ledger_entries` 表，通过 `entry_type` 区分。

### 7.3 多账户事务原子性

```go
func (s *FXService) ExecuteConversion(ctx context.Context, order *FXOrder) error {
    return s.db.WithTx(ctx, func(tx *sqlx.Tx) error {
        // 按 currency 字典序加锁（防死锁：HKD 先于 USD）
        fromBal, err := lockAccountBalance(ctx, tx, order.UserID, order.FromCurrency)
        if err != nil {
            return fmt.Errorf("lock from account: %w", err)
        }
        toBal, err := lockAccountBalance(ctx, tx, order.UserID, order.ToCurrency)
        if err != nil {
            return fmt.Errorf("lock to account: %w", err)
        }
        if fromBal.Available.LessThan(order.FromAmount) {
            return ErrInsufficientBalance
        }
        if err := debitAccount(ctx, tx, order.UserID, order.FromCurrency,
            order.FromAmount, fromBal.Version); err != nil {
            return fmt.Errorf("debit account: %w", err)
        }
        if err := creditAccount(ctx, tx, order.UserID, order.ToCurrency,
            order.ToAmount, toBal.Version); err != nil {
            return fmt.Errorf("credit account: %w", err)
        }
        if err := insertFXLedgerEntries(ctx, tx, order); err != nil {
            return fmt.Errorf("insert ledger entries: %w", err)
        }
        return completeFXOrder(ctx, tx, order.FXOrderID)
    })
}
```

死锁防御：多账户加锁时始终按 currency 字典序（HKD 先于 USD），确保全局一致的加锁顺序。

---

## 8. 对账与监控

### 8.1 EOD 对账不变量验证

```sql
-- 验证换汇金额与 Ledger 一致
SELECT
  SUM(from_amount) AS fx_orders_from,
  (SELECT SUM(amount) FROM ledger_entries
   WHERE entry_type = 'FX_DEBIT' AND currency = 'USD'
     AND DATE(created_at) = CURDATE()) AS ledger_debit_usd
FROM fx_orders
WHERE status = 'COMPLETED'
  AND from_currency = 'USD'
  AND DATE(executed_at) = CURDATE();
-- 两列必须相等，差异 > $0.01 自动告警
```

### 8.2 关键监控指标

| 指标 | 告警阈值 |
|------|---------|
| 报价成功率 | < 99% |
| 报价过期率（用户未确认） | > 20% |
| 换汇执行耗时 p99 | > 500ms |
| 异常汇率拦截次数 | > 3次/小时 |
| PROCESSING 状态超时订单 | > 0 立即告警 |
| Spread 收入偏差 | 偏离预期 > 5% |
