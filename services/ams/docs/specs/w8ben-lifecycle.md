# W-8BEN 税务表单完整生命周期规范

> **版本**: v1.0
> **日期**: 2026-03-31
> **作者**: AMS Engineer + Product Manager
> **状态**: Final — Ready for Implementation
>
> 本文档定义 W-8BEN 表单从签署、验证、到期通知、更新、以及到期后阻断交易的完整生命周期，包括 Cron Job、消息格式、账本记录，以及跨服务通知。

---

## 目录

1. [W-8BEN 背景与规则](#1-w-8ben-背景与规则)
2. [颁发与激活规则](#2-颁发与激活规则)
3. [生命周期状态机](#3-生命周期状态机)
4. [到期前通知策略](#4-到期前通知策略)
5. [到期后处理](#5-到期后处理)
6. [Cron Job 实现](#6-cron-job-实现)
7. [Ledger 与税务计算](#7-ledger-与税务计算)
8. [跨服务消息](#8-跨服务消息)
9. [用户 UI 流程](#9-用户-ui-流程)
10. [审计与报告](#10-审计与报告)

---

## 1. W-8BEN 背景与规则

### 1.1 IRS 税务表单要求

**W-8BEN** (非美国个人)、**W-9** (美国个人)、**CRS** (跨境)：

```
┌────────────────────────────────────────────────┐
│ 税务身份判断树                                  │
├────────────────────────────────────────────────┤
│ User.TaxResidence = US? (通过 KYC 或 W-9 声明) │
│  ├─ YES ──► W-9 (美国个人)                     │
│  │          ├─ 有效期：无固定期限（一次性）   │
│  │          └─ 无需更新（仅税务身份变更时）   │
│  │                                             │
│  └─ NO ──► W-8BEN (非美国个人)                 │
│             ├─ 必填：Full Name, TIN, Address  │
│             ├─ 有效期：3 年（签署之日起）    │
│             ├─ 更新：年度审查 + T-90 提醒   │
│             └─ 到期：自动冻结股利分配、加税  │
│                                             │
│ 港股居民交易 US 股票？                       │
│  └─ 建议上传 W-8BEN（用于美股）+ CRS（全球） │
└────────────────────────────────────────────────┘
```

### 1.2 W-8BEN 关键规则

```
有效期（IRS Publication 515）：
  签署日期 T
  →  T + 3年 (至第三个公历年度的最后一天)
  例：2024年5月1日签署 ──► 2027年12月31日失效

使用场景：
  ├─ 美股股利（Dividends）
  │   ├─ W-8BEN 有效：零预扣（若合格）
  │   ├─ W-8BEN 过期：30% FATCA 预扣
  │   └─ 无 W-8BEN：30% 默认预扣
  │
  ├─ 美股利息（Bond Interest）
  │   └─ 同上（需 W-8BEN）
  │
  └─ 美股交易（Trading）
      └─ 无 W-8BEN 影响（仅股利/利息）

更新触发：
  ├─ 税务身份变更（成为美国居民）→ 转换为 W-9（30 天内）
  ├─ T-90 系统提醒
  ├─ 用户主动更新
  └─ T+0（到期）→ 30% 预扣
```

---

## 2. 颁发与激活规则

### 2.1 谁需要 W-8BEN？

```
Trigger 条件（账户创建时的自动判断）：

IF jurisdiction = 'BOTH' OR 'US':
  IF user.tax_residence != 'US':
    ──► w8ben_required = TRUE
    ──► w8ben_status = REQUIRED (需在 KYC Step 5 提交)
  ELSE:
    ──► w9_required = TRUE

IF jurisdiction = 'HK':
  ──► w8ben_required = FALSE
  ──► w8ben_status = NOT_REQUIRED (可选)
```

### 2.2 签署与验证

```
用户提交 W-8BEN:
  1. UI 采集：Name, TIN, Address, Signature, SignatureDate
  2. AMS 后端验证：
     ├─ Full Name ✓ KYC 一致
     ├─ TIN 格式（9 位数字或等效值）
     ├─ Signature Date 不超过 30 天前（新鲜）
     ├─ IRS 表单版本 >= 2021
     └─ Date of Signature 与提交时间差 < 30 天
  3. 通过验证 ──► w8ben_status = ACTIVE
  4. 存储：表单 PDF 归档到 S3（审计用）
```

**Go 验证函数**:
```go
func (s *TaxFormService) ValidateW8BEN(
    ctx context.Context,
    form *W8BENForm,
    kycProfile *KYCProfile) error {

    // 1. 姓名匹配
    if normalizeString(form.FullName) != normalizeString(kycProfile.FullName) {
        return fmt.Errorf("W-8BEN full name mismatch KYC")
    }

    // 2. TIN 格式
    if !isValidTIN(form.TIN) && !form.TINNotAvailable {
        return fmt.Errorf("invalid TIN format")
    }

    // 3. 签署日期不超过 30 天
    daysAgo := time.Since(form.SignatureDate).Hours() / 24
    if daysAgo > 30 {
        return fmt.Errorf("signature date too old (%.0f days)", daysAgo)
    }

    // 4. 表单版本检查（示例）
    if form.FormVersion < "2021" {
        return fmt.Errorf("form version must be 2021 or later")
    }

    return nil
}
```

---

## 3. 生命周期状态机

### 3.1 状态转换图

```
┌─────────────────────────────────────────────────┐
│ W-8BEN 完整生命周期                              │
└─────────────────────────────────────────────────┘

NOT_REQUIRED (HK-only 账户，无需 W-8BEN)
    │
    └─ (无后续状态)

REQUIRED (必须提交，eg. 美股账户)
    │
    ├─ 用户上传 ──► PENDING_VALIDATION
    │
    └─ T-90 前未提交 ──► EXPIRATION_WARNING
                      │
                      └─ (继续 REQUIRED，重复提醒)

PENDING_VALIDATION (用户上传后等待 AMS 验证)
    │
    ├─ 验证通过 ──► ACTIVE (有效期：T+3 年)
    │
    └─ 验证失败 ──► VALIDATION_FAILED
                  │
                  └─ 用户重新上传 ──► PENDING_VALIDATION

ACTIVE (有效状态，允许交易与股利分配)
    │
    ├─ T-90 天时 ──► EXPIRATION_WARNING
    │                │ (发送通知，状态仍为 ACTIVE)
    │                │
    │                └─ T-30 天时 ──► FINAL_WARNING
    │                                 │ (最后催促)
    │                                 │
    │                                 └─ T-0 天时 ──► (转移下方)
    │
    └─ T+0 天(到期) ──► EXPIRED (终态)
                        │ (30% 预扣激活，交易受限)

EXPIRED
    │
    └─ 用户上传新表 ──► ACTIVE (重置有效期)

VALIDATION_FAILED
    │
    └─ 用户重新上传 ──► PENDING_VALIDATION

EXPIRATION_WARNING / FINAL_WARNING
    │
    └─ T+0 到期 ──► EXPIRED
```

---

## 4. 到期前通知策略

### 4.1 通知时间表

```
T-90 天：第一封提醒邮件 + 推送
  ├─ 频率：1 次（仅一次，避免邮件轰炸）
  ├─ 渠道：邮件 + FCM 推送 + 应用内通知
  ├─ 内容：
  │   Subject: Your W-8BEN expires on [DATE]. Please renew.
  │   Body: Your US tax form expires in 90 days. Renew now to avoid
  │           trading restrictions.
  └─ CTA: [Upload New W-8BEN] button

T-30 天：加强提醒
  ├─ 频率：1 次（若用户仍未更新）
  ├─ 渠道：邮件 + 推送（加强语气）
  ├─ 内容：
  │   Subject: URGENT: Your W-8BEN expires in 30 days
  │   Body: Your tax form will expire soon. Please upload a new W-8BEN
  │           to avoid trade restrictions on US stocks.
  └─ CTA: [Renew Now] (突出)

T-7 天：最后警告
  ├─ 频率：1 次（若用户仍未更新）
  ├─ 渠道：邮件 + 推送（标记为 critical）
  ├─ 内容：
  │   Subject: FINAL NOTICE: W-8BEN expires in 7 days
  │   Body: Your account will lose US trading privileges on [DATE].
  └─ CTA: [Renew Immediately]

T+1 天：到期通知 + 限制生效
  ├─ 频率：1 次
  ├─ 渠道：邮件 + 推送 + 应用内警告条
  ├─ 内容：
  │   Subject: Your W-8BEN has expired
  │   Body: US trading is now restricted. US dividends will have 30%
  │           tax withholding. Please upload a new W-8BEN to restore
  │           normal trading.
  └─ 限制生效：
      ├─ US 股票 BUY 订单：拒绝（403 "Tax form expired"）
      ├─ US 股票股利：30% FATCA 预扣
      └─ HK 股票：无影响

T+30 天：合规审查
  └─ 高风险：若用户超过 30 天未更新，标记为风险账户
```

### 4.2 通知去重

```go
// 防止用户收到多份相同通知

type NotificationLog struct {
    AccountID      string
    NotificationType string    // W8BEN_EXPIRY_90D, W8BEN_EXPIRY_30D, etc.
    SentAt         time.Time
}

func (s *NotificationService) ShouldNotify(
    ctx context.Context,
    accountID string,
    notiType string) bool {

    // 查询最近一次同类通知
    lastNotif, _ := s.repo.GetLastNotification(ctx, accountID, notiType)

    // 若已在 24 小时内发送，则跳过
    if lastNotif != nil && time.Since(lastNotif.SentAt) < 24*time.Hour {
        return false
    }

    return true
}
```

---

## 5. 到期后处理

### 5.1 自动处理流程

```
T+0 (到期日期) Cron Job 执行：

1. 标记账户
   ├─ w8ben_status = EXPIRED
   ├─ w8ben_expired_at = NOW()
   ├─ tax_form_status = EXPIRED (对外暴露)
   └─ 账户仍保持 ACTIVE（无需冻结）

2. 发布事件到 Kafka
   Topic: ams.tax_form_expired
   {
     "account_id": "acc-xxx",
     "account_owner_id": "user-yyy",
     "tax_form_type": "W8BEN",
     "jurisdiction": "HK",
     "expired_at": "2026-04-01T00:00:00Z",
   }

3. Fund Transfer 收到事件 ──► 更新本地缓存
   ├─ tax_form_status: ACTIVE → EXPIRED
   ├─ 出金限制：无改变（仍允许）
   └─ 查询 AMS: 验证税务状态

4. Trading Engine 收到事件 ──► 更新风险评分
   ├─ 检查：该账户是否持有 US 股票
   ├─ 若持有 US 股票 ──► 标记为 "tax_form_expired"
   └─ 下单时返回警告："Please renew W-8BEN to trade US stocks"

5. Fund Transfer 处理股利分配时
   ├─ 检查：w8ben_status == EXPIRED?
   ├─ 若是 ──► 30% FATCA 预扣
   │   记录：Ledger Entry (type: DIVIDEND_FATCA_WITHHOLDING)
   │   例：Dividend $100 ──► Withholding $30 ──► 到账 $70
   │
   └─ 若否 ──► 按 KYC 国家规则处理
```

### 5.2 限制执行

**AMS 侧**（无需强制冻结，而是通知）:
```go
func (h *OrderValidationHandler) CheckTaxFormStatus(
    ctx context.Context,
    accountID string) error {

    account, _ := h.amsClient.GetAccountSnapshot(ctx, accountID)

    if account.TaxFormStatus == "EXPIRED" && account.Jurisdiction == "US" {
        return fmt.Errorf("W-8BEN expired. Please renew to trade US stocks.")
    }

    return nil
}
```

**Trading Engine 侧**（实际阻止）:
```go
func (h *OrderHandler) SubmitOrder(ctx context.Context, req *OrderRequest) error {
    // 1. 获取账户信息
    account, _ := h.amsService.GetAccount(ctx, req.AccountID)

    // 2. 检查税务表单状态
    if account.TaxFormStatus == "EXPIRED" {
        // 检查符号是否为美股
        if IUSStock(req.Symbol) {
            return NewError(403, "TAX_FORM_EXPIRED",
                "Your W-8BEN has expired. BUY orders on US stocks are blocked.")
        }
    }

    // 3. 继续下单...
    return h.processOrder(ctx, req)
}
```

---

## 6. Cron Job 实现

### 6.1 W-8BEN 到期检查 Cron

```go
// internal/cron/w8ben_cron.go

package cron

import (
    "context"
    "time"
    "go.uber.org/zap"
)

type W8BENCronService struct {
    accountRepo  *repository.AccountRepository
    notifSvc     *service.NotificationService
    eventBus     *events.EventBus
    logger       *zap.Logger
}

// CheckW8BENExpiry 每日 02:00 UTC 执行
// 使用 Redis 分布式锁确保单实例执行
func (c *W8BENCronService) CheckW8BENExpiry(ctx context.Context) error {
    // 1. 获取分布式锁
    lockKey := "lock:w8ben_cron"
    locked, err := c.lockMgr.AcquireLock(ctx, lockKey, 5*time.Minute)
    if !locked {
        c.logger.Info("w8ben cron already running on another instance")
        return nil
    }
    defer c.lockMgr.ReleaseLock(ctx, lockKey)

    c.logger.Info("starting W-8BEN expiry check")

    now := time.Now().UTC()

    // T-90: 发送续期提醒
    expiringIn90 := now.AddDate(0, 0, 90)
    accounts, _ := c.accountRepo.FindW8BENExpiringBefore(ctx, expiringIn90)
    c.notifyAccounts(ctx, accounts, "W8BEN_EXPIRY_90D")

    // T-30: 发送加强提醒
    expiringIn30 := now.AddDate(0, 0, 30)
    accounts, _ = c.accountRepo.FindW8BENExpiringBefore(ctx, expiringIn30)
    c.notifyAccounts(ctx, accounts, "W8BEN_EXPIRY_30D")

    // T-7: 发送最后警告
    expiringIn7 := now.AddDate(0, 0, 7)
    accounts, _ = c.accountRepo.FindW8BENExpiringBefore(ctx, expiringIn7)
    c.notifyAccounts(ctx, accounts, "W8BEN_EXPIRY_7D")

    // T+0: 标记过期
    expiredAccounts, _ := c.accountRepo.FindW8BENExpiredBefore(ctx, now)
    c.markExpired(ctx, expiredAccounts)

    c.logger.Info("W-8BEN expiry check completed")
    return nil
}

func (c *W8BENCronService) notifyAccounts(
    ctx context.Context,
    accounts []Account,
    notifType string) {

    for _, acc := range accounts {
        // 1. 去重检查
        shouldNotify, _ := c.notifSvc.ShouldNotify(ctx, acc.AccountID, notifType)
        if !shouldNotify {
            continue
        }

        // 2. 发送通知
        c.notifSvc.SendEmailNotification(ctx, &EmailRequest{
            UserID:   acc.UserID,
            Template: "w8ben_expiry_" + notifType,
            Data: map[string]interface{}{
                "expiry_date": acc.W8BENExpiry,
                "days_left":   int(acc.W8BENExpiry.Sub(time.Now()).Hours() / 24),
            },
        })

        c.notifSvc.SendPushNotification(ctx, &PushRequest{
            UserID:  acc.UserID,
            Title:   "W-8BEN Renewal Required",
            Message: fmt.Sprintf("Your tax form expires on %s", acc.W8BENExpiry.Format("2006-01-02")),
        })

        // 3. 记录已通知
        c.notifSvc.LogNotificationSent(ctx, acc.AccountID, notifType)
    }
}

func (c *W8BENCronService) markExpired(
    ctx context.Context,
    accounts []Account) {

    for _, acc := range accounts {
        // 1. 更新账户状态
        c.accountRepo.UpdateW8BENStatus(ctx, acc.AccountID, "EXPIRED", time.Now().UTC())

        // 2. 发布 Kafka 事件
        c.eventBus.Publish(ctx, "ams.tax_form_expired", map[string]interface{}{
            "account_id": acc.AccountID,
            "user_id":    acc.UserID,
            "form_type":  "W8BEN",
            "jurisdiction": acc.Jurisdiction,
            "expired_at": time.Now().UTC(),
        })

        // 3. 发送用户通知
        c.notifSvc.SendEmailNotification(ctx, &EmailRequest{
            UserID:   acc.UserID,
            Template: "w8ben_expired",
            Data: map[string]interface{}{
                "action_required": true,
                "impact": "US stock trading is now restricted. Dividends will have 30% tax withholding.",
            },
        })

        c.logger.Info("W-8BEN marked as expired",
            zap.String("account_id", acc.AccountID),
            zap.Time("expired_at", time.Now().UTC()))
    }
}
```

### 6.2 Scheduler 配置（Robfig/Cron）

```go
// cmd/scheduler/main.go

import (
    "github.com/robfig/cron/v3"
)

func setupCronJobs(w8benSvc *W8BENCronService) {
    c := cron.New(cron.WithSeconds())

    // 每日 02:00 UTC 执行 W-8BEN 到期检查
    // Cron 格式：(second minute hour day month weekday)
    _, err := c.AddFunc("0 0 2 * * *", func() {
        ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
        defer cancel()

        if err := w8benSvc.CheckW8BENExpiry(ctx); err != nil {
            logger.Error("W8BEN cron job failed", zap.Error(err))
        }
    })

    if err != nil {
        logger.Fatal("failed to register cron job", zap.Error(err))
    }

    c.Start()
}
```

---

## 7. Ledger 与税务计算

### 7.1 股利分配时的预扣计算

```go
// internal/dividend/processor.go

func (p *DividendProcessor) ProcessDividend(
    ctx context.Context,
    div *Dividend) error {

    // 1. 查询账户税务状态
    account, _ := p.amsClient.GetAccount(ctx, div.AccountID)

    // 2. 决定预扣比例
    var withholdingRate decimal.Decimal
    var withholdingReason string

    if account.TaxFormStatus == "EXPIRED" {
        withholdingRate = decimal.NewFromFloat(0.30)  // 30% FATCA 默认
        withholdingReason = "W8BEN_EXPIRED"
    } else if account.TaxFormStatus == "ACTIVE" {
        // 根据国家判断
        if account.Jurisdiction == "HK" {
            withholdingRate = decimal.Zero
            withholdingReason = "HK_RESIDENT_NO_WITHHOLDING"
        } else {
            withholdingRate = decimal.Zero
            withholdingReason = "W8BEN_VALID"
        }
    } else {
        withholdingRate = decimal.NewFromFloat(0.30)  // 保守：无表单则预扣
        withholdingReason = "TAX_FORM_MISSING"
    }

    // 3. 计算预扣额
    grossAmount := div.Amount
    withholdingAmount := grossAmount.Mul(withholdingRate)
    netAmount := grossAmount.Sub(withholdingAmount)

    // 4. 写入 Ledger（两条记录）
    // 4a. 股利收入
    _ = p.ledger.Record(ctx, &LedgerEntry{
        AccountID:    div.AccountID,
        Type:         "DIVIDEND",
        Amount:       grossAmount,
        Currency:     div.Currency,
        Status:       "SETTLED",
        Description:  fmt.Sprintf("Dividend for %s", div.Symbol),
        RelatedID:    div.ID,
        Timestamp:    div.PaymentDate,
    })

    // 4b. 预扣税（若有）
    if withholdingAmount.GreaterThan(decimal.Zero) {
        _ = p.ledger.Record(ctx, &LedgerEntry{
            AccountID:    div.AccountID,
            Type:         "DIVIDEND_WITHHOLDING",
            Amount:       withholdingAmount.Neg(),  // 负数表示扣除
            Currency:     div.Currency,
            Status:       "SETTLED",
            Description:  fmt.Sprintf("FATCA withholding (%s) for %s", withholdingReason, div.Symbol),
            RelatedID:    div.ID,
            Timestamp:    div.PaymentDate,
        })
    }

    // 5. 发布事件（供 Fund Transfer 接收）
    p.eventBus.Publish(ctx, "dividend.processed", DividendProcessedEvent{
        AccountID:         div.AccountID,
        Amount:            netAmount,
        GrossAmount:       grossAmount,
        WithholdingAmount: withholdingAmount,
        WithholdingReason: withholdingReason,
        Symbol:            div.Symbol,
    })

    return nil
}
```

### 7.2 Ledger Schema

```sql
CREATE TABLE ledger_entries (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id CHAR(36) NOT NULL,
    type VARCHAR(30) NOT NULL,  -- DIVIDEND, DIVIDEND_WITHHOLDING, etc.
    amount DECIMAL(20, 4) NOT NULL,  -- 可以是负数（扣除）
    currency CHAR(3),
    description VARCHAR(255),
    status VARCHAR(20),  -- PENDING, SETTLED, REVERSED
    related_id VARCHAR(36),  -- 关联的 dividend_id
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_account (account_id),
    INDEX idx_timestamp (timestamp),
    INDEX idx_type (type),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
) ENGINE=InnoDB;
```

---

## 8. 跨服务消息

### 8.1 Kafka 事件格式

```protobuf
// events/tax_form_events.proto

syntax = "proto3";
package events;

import "google/protobuf/timestamp.proto";

message TaxFormExpired {
    string account_id = 1;
    string user_id = 2;
    string form_type = 3;           // W8BEN, W9, CRS
    string jurisdiction = 4;         // HK, US
    google.protobuf.Timestamp expired_at = 5;
}

message TaxFormRenewed {
    string account_id = 1;
    string form_type = 2;
    google.protobuf.Timestamp new_expiry_date = 3;
    google.protobuf.Timestamp renewed_at = 4;
}

message DividendWithholdingApplied {
    string account_id = 1;
    string dividend_id = 2;
    string symbol = 3;
    string gross_amount = 4;           // Decimal as string
    string withholding_amount = 5;
    string withholding_reason = 6;     // W8BEN_EXPIRED, etc.
    google.protobuf.Timestamp settled_at = 7;
}
```

### 8.2 消息消费

```go
// internal/kafka/consumer.go

func (c *EventConsumer) ConsumeTaxFormExpired(
    msg *events.TaxFormExpired) error {

    ctx := context.Background()

    // Trading Engine 消费：更新缓存
    c.tradingCache.SetTaxFormStatus(
        msg.AccountID,
        "EXPIRED",
        msg.ExpiredAt.AsTime(),
    )

    // Fund Transfer 消费：更新提现限制
    c.fundTransferCache.SetTaxFormStatus(
        msg.AccountID,
        "EXPIRED",
    )

    // Notification 消费：发送用户提醒
    c.notificationSvc.SendCriticalAlert(ctx, &AlertRequest{
        UserID:   msg.UserID,
        Title:    "Tax Form Expired",
        Message:  "Your W-8BEN has expired. Please renew.",
        Priority: HIGH,
    })

    return nil
}
```

---

## 9. 用户 UI 流程

### 9.1 Renewal Flow（Flutter）

```
[Dashboard]
    │
    ├─ W-8BEN Expiry Widget 显示
    │  ├─ Status: "Expires in 30 days"
    │  ├─ Date: "2026-04-30"
    │  └─ [Renew Now] Button
    │
    ▼
[W-8BEN Renewal Screen]
    │
    ├─ 预填：Full Name (from KYC)
    ├─ 输入：TIN (新)
    ├─ 输入：Address (可编辑)
    ├─ 输入：Signature (手写或电子)
    ├─ 日期选择：Signature Date
    │
    └─ [Submit] Button
           │
           ▼ (生物认证确认)
           │
           ▼
    [Processing...]
           │
           ├─ ✅ Success
           │  └─ "W-8BEN renewed successfully!"
           │     "Valid until: 2029-12-31"
           │
           └─ ❌ Failed
              └─ "Validation failed: [reason]"
                 [Retry] Button
```

### 9.2 Expiry Notice Widget

```dart
// lib/widgets/w8ben_expiry_notice.dart

class W8BENExpiryNotice extends StatelessWidget {
  final Account account;

  @override
  Widget build(BuildContext context) {
    if (account.taxFormStatus != 'EXPIRED' &&
        account.taxFormStatus != 'EXPIRATION_WARNING') {
      return SizedBox.shrink();
    }

    final daysLeft = account.w8benExpiry
        .difference(DateTime.now())
        .inDays;

    final severity = daysLeft > 30 ? 'warning' : 'critical';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/kyc/w8ben-renewal');
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: severity == 'critical'
              ? Colors.red.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          border: Border.all(
            color: severity == 'critical'
                ? Colors.red
                : Colors.orange,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              severity == 'critical'
                  ? 'W-8BEN Expired'
                  : 'W-8BEN Expiring Soon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your US tax form expires in $daysLeft days.\n'
              'Please renew to avoid trading restrictions.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/kyc/w8ben-renewal');
              },
              child: Text('Renew Now'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 10. 审计与报告

### 10.1 审计事件

```go
type TaxFormAuditEvent struct {
    EventID        string
    AccountID      string
    UserID         string
    EventType      string    // SUBMITTED, VALIDATED, APPROVED, EXPIRED, RENEWED
    FormType       string    // W8BEN, W9, CRS
    Details        string
    ActorID        string    // 若为系统自动，则为 "SYSTEM"
    Timestamp      time.Time
}

// 例
TaxFormAuditEvent{
    EventID: "evt-001",
    AccountID: "acc-xxx",
    UserID: "user-yyy",
    EventType: "W8BEN_SUBMITTED",
    FormType: "W8BEN",
    Details: "User uploaded W-8BEN form via mobile app",
    ActorID: "user-yyy",
    Timestamp: time.Now(),
}
```

### 10.2 合规报告

```sql
-- 月度 W-8BEN 过期统计
SELECT
    DATE_TRUNC('month', w8ben_expiry) AS month,
    COUNT(*) AS expired_count,
    COUNT(CASE WHEN jurisdiction='US' THEN 1 END) AS us_only,
    COUNT(CASE WHEN jurisdiction='BOTH' THEN 1 END) AS both_markets
FROM accounts
WHERE account_status = 'ACTIVE'
  AND tax_form_status = 'EXPIRED'
GROUP BY month
ORDER BY month DESC;

-- W-8BEN 续期完成率
SELECT
    DATE_TRUNC('month', w8ben_expiry) AS expiry_month,
    COUNT(*) AS total_expired,
    COUNT(CASE WHEN w8ben_renewed_at IS NOT NULL
               AND w8ben_renewed_at < w8ben_expiry + INTERVAL '30 days'
        THEN 1 END) AS renewed_within_30days,
    ROUND(
        100.0 * COUNT(CASE WHEN w8ben_renewed_at IS NOT NULL THEN 1 END) /
        COUNT(*),
        2
    ) AS renewal_rate_pct
FROM accounts
GROUP BY expiry_month
ORDER BY expiry_month DESC;
```

---

## 总结

本规范涵盖：
- ✅ W-8BEN 颁发、激活与验证
- ✅ 完整的生命周期状态机
- ✅ T-90/30/7/0 的分阶段通知策略
- ✅ Cron Job 与分布式锁实现
- ✅ 到期后自动阻断与预扣处理
- ✅ Ledger 与税务计算集成
- ✅ 跨服务消息与事件
- ✅ 用户 UI 与审计报告

**Implementation Checklist**:
1. W-8BEN 数据库字段（0.5 天）
2. 验证与激活逻辑（1 天）
3. Cron Job + 分布式锁（1 天）
4. Ledger 预扣计算（1 天）
5. Kafka 事件与消费（0.5 天）
6. Flutter UI Widget（1 天）
7. 审计与报告（0.5 天）

**Go 交付物**:
- `internal/taxform/service.go` — 核心业务逻辑
- `internal/cron/w8ben_cron.go` — Cron Job
- `internal/dividend/processor.go` — 预扣计算
- `migrations/*.sql` — 数据库扩展
