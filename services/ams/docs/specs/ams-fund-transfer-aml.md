# AMS-Fund Transfer AML 交互契约

> **版本**: v1.0
> **日期**: 2026-03-31
> **作者**: AMS Engineer + Fund Transfer Engineer
> **状态**: Final — Ready for Implementation
>
> 本文档定义 AMS（Account Management Service）与 Fund Transfer（出入金服务）的 AML（反洗钱）交互协议，覆盖制裁筛查、PEP 监控、风险评分传播、SAR Tipping-off 防护、CTR 责任分工、W-8BEN 到期阻断，以及 Webhook 安全性。

---

## 目录

1. [AML 责任边界](#1-aml-责任边界)
2. [CTR/STR 分工模型](#2-ctrstr-分工模型)
3. [SAR Tipping-off 防护](#3-sar-tipping-off-防护)
4. [gRPC 接口规范](#4-grpc-接口规范)
5. [异步事件消息](#5-异步事件消息)
6. [Webhook 安全性](#6-webhook-安全性)
7. [Risk Score 传播](#7-risk-score-传播)
8. [W-8BEN 到期处理](#8-w-8ben-到期处理)
9. [制裁筛查集成](#9-制裁筛查集成)
10. [错误与重试策略](#10-错误与重试策略)
11. [监控与告警](#11-监控与告警)

---

## 1. AML 责任边界

### 1.1 AMS 负责

```
┌─────────────────────────────────────────────┐
│ AMS (Account Management Service)            │
├─────────────────────────────────────────────┤
│ ✅ 开户时 OFAC/HK 制裁列表同步筛查           │
│ ✅ 开户时 PEP/不良媒体异步筛查               │
│ ✅ 账户级 AML 风险评分（LOW/MEDIUM/HIGH）   │
│ ✅ 每日全量账户重新筛查（防止新制裁遗漏）   │
│ ✅ ComplyAdvantage Webhook 处理（新命中通知）│
│ ✅ 向下游服务暴露 aml_risk_score 只读字段   │
│ ✅ SAR 提交历史记录（严格访问控制）         │
│ ✅ PEP 状态管理与 EDD 升级决策               │
│ ✅ 市场监测（OFAC 列表新增）                │
└─────────────────────────────────────────────┘
```

### 1.2 Fund Transfer 负责

```
┌─────────────────────────────────────────────┐
│ Fund Transfer (Deposit & Withdrawal Service)│
├─────────────────────────────────────────────┤
│ ✅ 单笔出入金交易 AML 筛查（资金流向）      │
│ ✅ CTR 阈值监控 + 自动申报（>$10k USD）    │
│ ✅ 结构性交易检测（Structuring 检查）      │
│ ✅ 交易速度异常检测                        │
│ ✅ 受益所有人（Ultimate Beneficial Owner）识别│
│ ✅ SAR 触发（建议给 AMS，由合规提交）       │
│ ✅ 交易阻止决策（基于 AMS 的 risk_score）  │
│ ✅ 银行对账与异常报告                      │
│ ✅ 出金额度限制执行（基于 KYC 等级）       │
└─────────────────────────────────────────────┘
```

---

## 2. CTR/STR 分工模型

### 2.1 Currency Transaction Report (CTR) — 流程

```
User 存入 $15,000
        │
        ▼
Fund Transfer 服务检测：amount > $10,000 USD
        │
        ▼
触发 AML 筛查（调用 AMS gRPC）
        │
        ├─ 获取 account_id, aml_risk_score, sar_filing_count
        │
        ├─ CTR 阈值判断：
        │   ├─ 单笔 > $10k 且 aml_risk_score = LOW ──► 自动申报 CTR
        │   ├─ 单笔 > $10k 且 aml_risk_score = MEDIUM ──► 人工审核 + 申报
        │   └─ 单笔 > $10k 且 aml_risk_score = HIGH ──► 人工审核 + SAR 可能
        │
        ▼
Fund Transfer → Compliance Service: EnqueueCTRFiling {
  account_id,
  transaction_id,
  amount,
  currency,
  direction (DEPOSIT|WITHDRAWAL),
  bank_account,
  timestamp
}

Compliance Service：
  ├─ 验证 CTR 字段完整
  ├─ 每周四统一提交给 FinCEN
  └─ 记录 CTR 编号 + timestamp
```

### 2.2 Suspicious Activity Report (SAR) — 流程

```
异常交易检测（Fund Transfer 或 AMS）
        │
        ├─ 结构性交易：24h 内多笔 $3k 分散交易
        ├─ 异常大额：$200k+ 无交易历史
        ├─ 违规资金：已被冻结/被诉的政党关联人
        │
        ▼
Fund Transfer → AMS: EnqueueSARSuspicion {
  account_id,
  reason,
  amount,
  transaction_ids[],
  risk_level: HIGH|CRITICAL
}

AMS Service：
  ├─ 更新 aml_risk_score = HIGH / is_sared = true
  ├─ 发送消息给 Compliance Officer
  │
  ▼
Compliance Manager：
  ├─ 人工审查交易行为（30 日内）
  ├─ 决策：是否提交 SAR
  │
  ├─ 如决定提交：
  │   ├─ 填写 FinCEN Form 111（SAR）
  │   ├─ Compliance Service 提交至 FinCEN
  │   ├─ AMS 记录 sar_filing_count++
  │   └─ 账户转入 UNDER_REVIEW 状态
  │
  ├─ 如决定不提交：
  │   └─ 解除 HIGH 标记，回归 MEDIUM
  │
  ▼
关键：**绝不向用户透露 SAR 相关信息**（Tipping-off）
      AMS 必须在 API 响应中过滤掉 sar_filing_count 字段
```

### 2.3 责任矩阵

| 事件 | 检测方 | 报告方 | 提交方 |
|-----|--------|--------|--------|
| CTR (>$10k) | FT | FT → AMS | Compliance Service |
| 结构性交易 | FT | FT → AMS | Compliance Service |
| PEP 新增制裁 | AMS (Webhook) | AMS | Compliance Officer 审核 |
| 可疑交易模式 | FT | FT → AMS | Compliance Manager |
| SAR 提交 | — | Compliance | Compliance Manager |

---

## 3. SAR Tipping-off 防护

### 3.1 问题定义

**Tipping-off**: 向用户或第三方透露已提交或即将提交 SAR 的事实，构成严重合规违规（FinCEN、SFC 违规）。

**场景**：
- 用户查询账户状态 → API 返回字段包含 `sar_filing_count` → 用户知道已被 SAR
- 客服人员不小心透露 → "Your account is under SAR investigation"
- API 日志明文记录 SAR 相关字段 → 审计人员浏览日志泄露

### 3.2 防护措施

**措施 1：API 字段过滤（序列化层）**

```go
// AMS API 响应中自动过滤 SAR 字段
type AccountSnapshotResponse struct {
    AccountID string `json:"account_id"`
    Status string `json:"status"`
    // ...

    // ⚠️ 下列字段 NEVER 返回给客户端，仅内部服务可见
    // SARFilingCount int    `json:"-" perm:"sar:view"`  // 隐藏
    // IsSARed bool         `json:"-" perm:"sar:view"`  // 隐藏
}

func (a *AccountSnapshot) MarshalJSON() ([]byte, error) {
    type Alias AccountSnapshot
    return json.Marshal(&struct {
        *Alias
    }{
        Alias: (*Alias)(a),
        // SAR fields automatically omitted by struct tags
    })
}
```

**措施 2：gRPC 内部接口分层**

```protobuf
// 客户端可见的接口（自动过滤 SAR）
service AccountService {
  rpc GetAccountStatus(GetAccountStatusRequest)
    returns (GetAccountStatusResponse);  // SAR 字段过滤
}

// 内部合规接口（需特殊权限）
service ComplianceService {
  rpc GetAccountWithSARInfo(GetAccountRequest)
    returns (AccountWithSARInfo);  // SAR 字段完整
}
```

**措施 3：日志脱敏**

```go
// Zap logger 配置，自动脱敏 SAR 相关字段
type LogSARRedactor struct{}

func (r *LogSARRedactor) Redact(msg string) string {
    // 正则表达式替换 sar_filing_count/is_sared 的值
    redacted := regexp.MustCompile(
        `sar_filing_count":(\d+)`).ReplaceAllString(msg, `sar_filing_count":"[REDACTED]`)
    return redacted
}

logger := zap.NewProductionConfig()
logger.Hook = LogSARRedactor{}
```

**措施 4：数据库访问控制**

```sql
-- 创建视图：普通客户端可见
CREATE VIEW accounts_customer_view AS
SELECT account_id, status, kyc_tier, aml_risk_score
FROM accounts;

-- 创建视图：合规人员可见（包含 SAR 字段）
CREATE VIEW accounts_compliance_view AS
SELECT *, sar_filing_count, is_sared, sar_last_filed_at
FROM accounts;

-- 授权
GRANT SELECT ON accounts_customer_view TO 'customer_app'@'%';
GRANT SELECT ON accounts_compliance_view TO 'compliance_admin'@'%';
```

**措施 5：Fund Transfer 静默阻止**

```go
// Fund Transfer 在 AMS 返回 is_sared = true 时，静默拒绝，不暴露原因
func (h *WithdrawalHandler) ProcessWithdrawal(ctx context.Context, req WithdrawalRequest) error {
    // 1. 调用 AMS 获取账户状态（包含隐藏的 is_sared）
    resp, _ := h.amsClient.GetAccountSnapshot(ctx, &pb.GetAccountSnapshotRequest{
        AccountID: req.AccountID,
    })

    // 2. 检查是否被 SAR（NOT 返回 SAR 特定错误）
    if resp.IsHidden_IsSared { // 隐藏字段，仅内部可见
        // 静默拒绝，返回通用错误
        return fmt.Errorf("withdrawal cannot be processed (E101)")
    }

    // 3. 正常流程...
}
```

---

## 4. gRPC 接口规范

### 4.1 AMS 暴露给 Fund Transfer

```protobuf
// api/grpc/ams_aml_service.proto

syntax = "proto3";
package ams.aml;

import "google/protobuf/timestamp.proto";

service AMSAMLService {
  // 1. 单笔交易筛查
  rpc ScreenTransaction(ScreenTransactionRequest)
    returns (ScreenTransactionResponse);

  // 2. 账户快照（含隐藏 SAR 字段）
  rpc GetAccountSnapshotForFundTransfer(GetAccountSnapshotRequest)
    returns (AccountSnapshot);

  // 3. 获取风险评分
  rpc GetAMLRiskScore(GetAMLRiskScoreRequest)
    returns (GetAMLRiskScoreResponse);

  // 4. 查询 W-8BEN 状态
  rpc GetTaxFormStatus(GetTaxFormStatusRequest)
    returns (GetTaxFormStatusResponse);

  // 5. 报告异常交易（SAR 提议）
  rpc ReportSuspiciousActivity(ReportSuspiciousActivityRequest)
    returns (ReportSuspiciousActivityResponse);
}

message ScreenTransactionRequest {
  string account_id = 1;
  string direction = 2;              // DEPOSIT, WITHDRAWAL
  string amount = 3;                 // 使用 Decimal 为字符串
  string currency = 4;               // USD, HKD
  string bank_account = 5;           // 银行账号（末 4 位）
  string bank_country = 6;           // ISO 3166-1
  google.protobuf.Timestamp timestamp = 7;
}

message ScreenTransactionResponse {
  string screening_result = 1;       // PASS, REVIEW, BLOCK
  repeated string matching_lists = 2;  // OFAC_SDN, HK_JFIU, ...
  string risk_level = 3;             // LOW, MEDIUM, HIGH
  string reason = 4;
}

message AccountSnapshot {
  string account_id = 1;
  string kyc_tier = 2;
  string aml_risk_score = 3;
  bool is_pep = 4;
  google.protobuf.Timestamp aml_last_screened_at = 5;

  // ⚠️ 隐藏字段（仅内部访问，Fund Transfer 必须检查权限）
  int32 hidden_sar_filing_count = 6 [(deprecated) = true];
  bool hidden_is_sared = 7 [(deprecated) = true];
  google.protobuf.Timestamp hidden_sar_last_filed_at = 8 [(deprecated) = true];
}

message GetAMLRiskScoreRequest {
  string account_id = 1;
}

message GetAMLRiskScoreResponse {
  string risk_score = 1;           // LOW, MEDIUM, HIGH
  repeated string contributing_factors = 2;  // PEP, HIGH_RISK_COUNTRY, etc.
  google.protobuf.Timestamp last_updated = 3;
}

message GetTaxFormStatusRequest {
  string account_id = 1;
}

message GetTaxFormStatusResponse {
  string status = 1;               // REQUIRED, NOT_REQUIRED, ACTIVE, EXPIRED
  string form_type = 2;            // W9, W8BEN, CRS
  google.protobuf.Timestamp expiry_date = 3;
  int32 days_until_expiry = 4;
}

message ReportSuspiciousActivityRequest {
  string account_id = 1;
  string reason = 2;               // STRUCTURING, UNUSUAL_AMOUNT, VELOCITY, etc.
  repeated string transaction_ids = 3;
  string amount = 4;
  string risk_level = 5;           // HIGH, CRITICAL
}

message ReportSuspiciousActivityResponse {
  bool success = 1;
  string message = 2;
  string investigation_ticket_id = 3;
}
```

---

## 5. 异步事件消息

### 5.1 Kafka 事件格式

```protobuf
// events/aml_events.proto

syntax = "proto3";
package events;

import "google/protobuf/timestamp.proto";

// 账户 AML 风险评分变更
message AMLRiskScoreChanged {
  string account_id = 1;
  string old_risk_score = 2;
  string new_risk_score = 3;
  repeated string triggering_factors = 4;  // 触发因素列表
  string reason = 5;
  google.protobuf.Timestamp timestamp = 6;
}

// 制裁列表新增命中（ComplyAdvantage Webhook）
message SanctionListHitDetected {
  string account_id = 1;
  string matched_name = 2;
  string list_name = 3;              // OFAC_SDN, HK_JFIU, etc.
  float confidence_score = 4;         // 0.0-1.0
  string action_required = 5;         // FREEZE, REVIEW, etc.
  google.protobuf.Timestamp timestamp = 6;
}

// PEP 状态变更
message PEPStatusChanged {
  string account_id = 1;
  bool was_pep = 2;
  bool is_pep = 3;
  string pep_type = 4;               // NON_HK_PEP, HK_PEP, etc.
  google.protobuf.Timestamp timestamp = 5;
}

// W-8BEN 到期（发送给 Fund Transfer）
message TaxFormExpired {
  string account_id = 1;
  string form_type = 2;              // W8BEN
  string jurisdiction = 3;           // HK, US
  google.protobuf.Timestamp expired_at = 4;
}

// SAR 提交通知（仅合规/审计可见）
message SARFiled {
  string account_id = 1;
  string investigation_ticket_id = 2;
  string reason = 3;
  google.protobuf.Timestamp filed_at = 4;
  // User 绝不会收到此事件
}
```

**Kafka Topic 配置**:
```yaml
Topics:
  - aml.risk_score_changed       # AMS → Fund Transfer, Trading Engine
  - aml.sanctions_list_hit       # AMS → Compliance (内部)
  - aml.pep_status_changed       # AMS → Fund Transfer
  - aml.tax_form_expired         # AMS → Fund Transfer, Trading Engine
  - aml.sar_filed                # AMS → Compliance Officer (内部，绝不发给 User)

Retention:
  - 事件保留 7 天（审计合规）
  - SAR 相关 topic 额外加密存储
```

---

## 6. Webhook 安全性

### 6.1 ComplyAdvantage Webhook（制裁列表新增）

**签名验证**:
```go
func VerifyComplyAdvantageWebhook(r *http.Request, secret string) ([]byte, error) {
    // 1. 读取 body（可能被读过）
    body, _ := ioutil.ReadAll(r.Body)
    defer r.Body.Close()
    r.Body = ioutil.NopCloser(bytes.NewBuffer(body))

    // 2. 提取签名
    signature := r.Header.Get("X-Signature")
    alg := r.Header.Get("X-Signature-Algorithm")  // HMAC-SHA256

    // 3. 重建签名
    h := hmac.New(sha256.New, []byte(secret))
    h.Write(body)
    expected := base64.StdEncoding.EncodeToString(h.Sum(nil))

    // 4. 时间安全比较
    if !hmac.Equal([]byte(signature), []byte(expected)) {
        return nil, errors.New("invalid webhook signature")
    }

    return body, nil
}
```

**幂等处理**:
```go
func (h *AMLWebhookHandler) HandleSanctionHit(ctx context.Context, payload SanctionHitPayload) error {
    // 1. 检查 idempotency key（防止重复处理）
    idempotencyKey := payload.EventID  // ComplyAdvantage 提供的唯一事件 ID
    exists, _ := h.cache.Exists(ctx, "webhook:"+idempotencyKey)
    if exists {
        return nil  // 已处理，直接返回
    }

    // 2. 事务处理
    tx, _ := h.db.BeginTx(ctx, nil)
    defer tx.Rollback()

    // 3. 更新账户状态
    _ = h.repo.UpdateAMLRiskScore(ctx, payload.AccountID, "HIGH")

    // 4. 发布事件
    _ = h.eventBus.Publish(ctx, "aml.sanctions_list_hit", payload)

    // 5. 标记为已处理（24h 过期）
    _ = h.cache.Set(ctx, "webhook:"+idempotencyKey, true, 24*time.Hour)

    return tx.Commit().Error
}
```

**重试策略**（ComplyAdvantage 侧）:
```
ComplyAdvantage 若收到 HTTP !2xx 状态码：
  ├─ Retry 1: 5 分钟后
  ├─ Retry 2: 30 分钟后
  ├─ Retry 3: 2 小时后
  └─ 放弃，记录失败日志

AMS 侧需立即返回 2xx（所有验证/处理异步）
```

---

## 7. Risk Score 传播

### 7.1 评分决策树

```
AML 风险评分（开户时 + 每日更新）

┌─ LOW (默认)
│  ├─ 本地居民（同一司法管辖区）
│  ├─ 工薪/正当资金来源
│  └─ 无 PEP、无制裁、无异常

├─ MEDIUM
│  ├─ 非居民（跨司法管辖区）
│  ├─ 资金来源复杂（投资/经营）
│  ├─ PEP 关联人（非 PEP 本人）
│  ├─ 高风险国家转账
│  └─ 单笔 > $100k 首次交易

└─ HIGH
   ├─ PEP 本人（Non-HK PEP）
   ├─ 制裁列表命中
   ├─ 高风险国家居民
   ├─ 结构性交易嫌疑
   ├─ 异常交易速度
   └─ SAR 曾被提交
```

**传播影响**:
```
AMS Risk Score       Fund Transfer 行为
─────────────────────────────────────────
LOW                  • 自动批准出入金
                     • CTR 自动申报
                     • 无额外审核

MEDIUM               • 出入金需人工审核（T+4h SLA）
                     • CTR 申报前人工确认
                     • 24h 内无异常解除标记

HIGH                 • 出入金冻结，需合规官员批准
                     • 所有交易需人工审查
                     • SAR 倾向于提交
                     • 限制交易品种（仅现金账户）
```

---

## 8. W-8BEN 到期处理

### 8.1 Timeline

```
T-90 days:  AMS 发送续期通知（email + push）
            User 可上传新表
                │
T-30 days:  如仍未上传，发送警告邮件
                │
T-0 (到期):  AMS Cron Job 标记 tax_form_status = EXPIRED
            │
            ▼ Event: TaxFormExpired 发送到 Fund Transfer/Trading Engine
            │
Fund Transfer 行为：
  ├─ 中国（Non-HK Tax）：禁止 BUY US 股票
  │   "Tax form expired. Dividends will be subject to 30% withholding."
  │
  └─ 其他：允许交易（但股利预扣 30% FATCA）

Trading Engine 行为：
  ├─ US 股利 Payment → Fund Transfer 扣除 30% 作为 FATCA 预提
  └─ HK 股利正常分配（无预提）
```

**Ledger 记录**:
```json
{
  "transaction_id": "tx-w8ben-exp-2026-04-01",
  "account_id": "acc-xxx",
  "type": "DIVIDEND_FATCA_WITHHOLDING",
  "amount": "-30.00",
  "currency": "USD",
  "description": "FATCA withholding on dividend (30%, tax form expired)",
  "related_dividend_id": "div-yyy",
  "timestamp": "2026-04-01T00:00:00Z",
  "status": "SETTLED",
  "reason_code": "W8BEN_EXPIRED"
}
```

---

## 9. 制裁筛查集成

### 9.1 ComplyAdvantage 调用（同步 + 异步）

**开户时（同步，阻塞）**:
```go
func (s *AMLService) ScreenForSanctionAtSignup(
    ctx context.Context, profile *KYCProfile) (SanctionsResult, error) {

    // 超时 400ms，防止阻塞开户流程
    ctx, cancel := context.WithTimeout(ctx, 400*time.Millisecond)
    defer cancel()

    req := &complyadvantage.SearchRequest{
        SearchTerm: profile.FullName.Plaintext(),
        Filters: complyadvantage.Filters{
            Types: []string{"sanction"},
            Entity: "individual",
        },
    }

    resp, err := s.caClient.Search(ctx, req)
    if err != nil {
        // 超时：默认通过，但记录指标
        s.metrics.AMLScreeningTimeout.Inc()
        logger.Warn("sanctions screening timeout", zap.String("account_id", profile.AccountID))
        return SanctionsResult{Status: "CLEAR"}, nil
    }

    if resp.TotalHits > 0 && resp.HasConfirmedHit() {
        return SanctionsResult{
            Status: "HIT",
            ListName: resp.Hits[0].ListName,
            Confidence: resp.Hits[0].Score,
        }, nil
    }

    return SanctionsResult{Status: "CLEAR"}, nil
}
```

**每日全量重新筛查（异步）**:
```go
// 每日 03:00 UTC（夜间低峰）
func (c *CronService) DailyAMLScreening(ctx context.Context) error {
    logger.Info("starting daily AML screening")

    // 1. 获取所有活跃账户（批量）
    cursor := 0
    batchSize := 1000

    for {
        accounts, err := c.repo.FetchActiveAccountsWithCursor(ctx, cursor, batchSize)
        if err != nil || len(accounts) == 0 {
            break
        }

        // 2. 入队异步筛查任务
        for _, acc := range accounts {
            payload, _ := json.Marshal(map[string]string{
                "account_id": acc.AccountID,
            })
            _ = c.asynqClient.Enqueue(asynq.NewTask(
                "aml:screen-account",
                payload,
                asynq.MaxRetry(3),
                asynq.Timeout(30*time.Second),
                asynq.Queue("aml_batch"),
            ))
        }

        cursor += batchSize
    }

    logger.Info("daily AML screening enqueued")
    return nil
}
```

---

## 10. 错误与重试策略

### 10.1 Fund Transfer 调用 AMS gRPC 失败

```
场景 1: AMS 服务不可用（TCP 连接失败）
  ├─ Retry 1: 100ms 后
  ├─ Retry 2: 200ms 后
  ├─ Retry 3: 400ms 后
  └─ 降级策略：使用缓存的风险评分（TTL 60s），若无缓存则拒绝交易

场景 2: AMS 返回 gRPC error
  ├─ Code: UNAVAILABLE → 重试（指数退避，3 次）
  ├─ Code: DEADLINE_EXCEEDED → 不重试，使用缓存
  └─ Code: PERMISSION_DENIED → 不重试，拒绝交易

场景 3: AMS 响应超时（>5s）
  └─ 中止，使用缓存或拒绝交易
```

**Go 实现示例**:
```go
import "google/golang.org/grpc"
import "google/golang.org/grpc/codes"

func (f *FundTransferService) ScreenWithRetry(
    ctx context.Context, req *pb.ScreenTransactionRequest) (*pb.ScreenTransactionResponse, error) {

    var lastErr error

    for attempt := 0; attempt < 3; attempt++ {
        // 设置单次调用超时（不包括重试延迟）
        ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
        defer cancel()

        resp, err := f.amsClient.ScreenTransaction(ctx, req)
        if err == nil {
            return resp, nil
        }

        // 根据错误类型决策是否重试
        st, ok := status.FromError(err)
        if !ok {
            lastErr = err
            continue
        }

        switch st.Code() {
        case codes.Unavailable, codes.ResourceExhausted:
            // 可恢复错误，重试
            backoff := time.Duration(math.Pow(2, float64(attempt))) * 100 * time.Millisecond
            select {
            case <-time.After(backoff):
            case <-ctx.Done():
                return nil, ctx.Err()
            }
            lastErr = err
        case codes.DeadlineExceeded:
            // 超时：不再重试，使用缓存
            return f.getCachedScreeningResult(ctx, req.AccountID)
        default:
            // 其他错误：不重试
            return nil, err
        }
    }

    // 所有重试失败：使用缓存或降级
    return f.getCachedScreeningResult(ctx, req.AccountID)
}
```

---

## 11. 监控与告警

### 11.1 关键指标

```
Prometheus 指标：

ams_aml_risk_score_changes_total{score=HIGH,reason=PEP}
  → High risk score 变更次数（监测 PEP 新增频率）

ams_sanctions_screening_timeout_total
  → OFAC 筛查超时次数（监测 ComplyAdvantage 可用性）

ams_sar_filings_total{status=SUBMITTED,reason=STRUCTURING}
  → SAR 提交总数（按原因分类）

fund_transfer_aml_check_failures_total{reason=TIMEOUT,severity=HIGH}
  → 出入金 AML 检查失败数

fund_transfer_ctrs_auto_filed_total{risk_score=MEDIUM}
  → CTR 自动申报数（按风险等级）

ams_w8ben_expiry_violations_total
  → W-8BEN 到期导致的阻止交易数
```

### 11.2 告警规则

```yaml
告警:
  - rule_id: aml_screening_timeout_spike
    condition: rate(ams_sanctions_screening_timeout_total[5m]) > 0.5
    severity: critical
    action: Page on-call engineer (ComplyAdvantage 可能宕机)

  - rule_id: sar_filings_spike
    condition: rate(ams_sar_filings_total[1h]) > 2
    severity: warning
    action: Notify compliance manager (可能存在大规模异常)

  - rule_id: aml_risk_score_high_percentage
    condition: (ams_aml_high_risk_accounts_total / ams_total_active_accounts) > 0.05
    severity: warning
    action: Review risk scoring algorithm

  - rule_id: w8ben_expired_trading_blocks
    condition: rate(ams_w8ben_expiry_violations_total[1h]) > 10
    severity: info
    action: Send reminder campaign (税务表单续期)
```

---

## 总结

本合约规范了：
- ✅ AMS 与 Fund Transfer 的清晰 AML 责任分工
- ✅ CTR 与 SAR 的端到端流程（从检测到申报）
- ✅ Tipping-off 防护的多层机制（API、日志、DB、UI）
- ✅ gRPC 和 Kafka 的完整消息规范
- ✅ ComplyAdvantage Webhook 的安全集成
- ✅ W-8BEN 到期触发的自动阻断
- ✅ 风险评分的传播与影响决策
- ✅ 综合的错误处理与降级策略
- ✅ 全面的监控与告警体系

**Implementation Priority**:
1. gRPC 接口实现（2 天）
2. Kafka 事件生产（1 天）
3. ComplyAdvantage Webhook 处理（1 天）
4. W-8BEN 到期 Cron Job（1 天）
5. Tipping-off 防护代码审查（1 天）

**Go Deliverables**:
- `internal/aml/service.go` — AML 业务逻辑
- `api/grpc/aml_service.proto` + generated `.pb.go`
- `internal/events/aml_events.go` — Kafka 消息定义
- `internal/webhook/complyadvantage.go` — Webhook 处理
