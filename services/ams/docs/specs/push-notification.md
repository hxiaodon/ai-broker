---
title: 推送通知系统设计
description: 多渠道推送通知、优先级 SLA、Webhook 集成、重试与 DLQ 策略
version: 1.0
created: 2026-04-01
updated: 2026-04-01
related_specs:
  - device-management.md
  - auth-architecture.md
  - kafka-events.md
related_prd:
  - ../prd/decisions-2026-03-29.md
  - ../../mobile/docs/prd/01-auth.md § 9
---

# 推送通知系统设计

## 一、概述

### 1.1 场景与价值

用户需要及时了解账户和安全相关的重要事件：
- **新设备登录告警** —— 防止账户被恶意登录
- **设备被踢出通知** —— 通知用户设备已被远程注销
- **账户锁定告警** —— OTP 错误 5 次后账户被锁定

推送通知系统需要：
- **实时性**：高优先级事件秒级投递
- **可靠性**：失败重试，DLQ 处理
- **多渠道冗余**：推送 + 短信 + 邮件 + 应用内
- **用户控制**：用户可配置通知偏好

### 1.2 设计目标

1. **用户安全**：关键事件无延迟、无丢失
2. **体验优化**：低优先级事件批量发送，减少打扰
3. **可靠性**：99.9% 的关键通知在 5 秒内投递
4. **可运维性**：完整的日志、死信队列、重试统计

---

## 二、核心业务规则

### 2.1 通知事件分类与优先级

#### 2.1.1 高优先级（High Priority）

需要**实时投递**，在 5 秒内首次尝试：

| 事件类型 | 触发条件 | 投递通道 | 内容示例 |
|---------|--------|--------|---------|
| **DEVICE_KICKED** | 设备被超限踢出 | FCM + SMS | "您的账号已在新设备登录，如非本人操作请立即联系客服" |
| **ACCOUNT_LOCKED** | OTP 错误 5 次 | FCM + SMS | "多次登录失败，账号已暂时锁定，请 30 分钟后重试" |
| **UNAUTHORIZED_LOGIN** | 新设备首次登录 | FCM | "您的账号已在 [设备名] 登录，如非本人操作请立即联系客服" |

#### 2.1.2 普通优先级（Normal Priority）

可**批量发送**，在 5-60 分钟内投递：

| 事件类型 | 触发条件 | 投递通道 | 内容示例 |
|---------|--------|--------|---------|
| **KYC_STATUS_CHANGED** | KYC 审核完成 | FCM + Email | "您的身份验证已完成，可以开始交易" |
| **W8BEN_EXPIRING** | W-8BEN 距过期 T-90 | Email | "您的税务表单即将过期，请于 2026-07-01 前更新" |
| **ACCOUNT_WARNING** | 风险评分升高 | Email | "您的账户触发风险规则，请查看详情" |

#### 2.1.3 低优先级（Low Priority）

可**异步投递**，在 1 小时内完成：

| 事件类型 | 触发条件 | 投递通道 | 内容示例 |
|---------|--------|--------|---------|
| **DEVICE_ADDED** | 新设备登录成功 | 应用内 | "您已在 iPhone 登录，设备数：2/3" |
| **SESSION_EXPIRED** | 会话自然过期 | 应用内 | "登录已过期，请重新登录" |

### 2.2 投递通道选择

| 通道 | 优点 | 缺点 | SLA | 成本 |
|------|------|------|-----|------|
| **FCM（推送）** | 实时、无延迟、打开率高 | 需要 App 安装、需网络 | < 2s | 免费 |
| **短信** | 无需网络、打开率 100% | 速度稍慢、价格高 | < 30s | $0.01-0.05/条 |
| **邮件** | 支持富文本、保存备查 | 延迟大、易进垃圾箱 | < 5min | $0.001-0.01/封 |
| **应用内** | 无成本、用户体验好 | 仅登录状态可见 | 实时 | 免费 |

**选择规则**：
- **高优先级**：FCM（优先） + SMS（备选）—— 确保用户必定收到
- **普通优先级**：FCM + Email —— 平衡成本和时效性
- **低优先级**：应用内 + Email —— 可异步，成本最低

### 2.3 推送模板与变量规范

所有推送通知使用模板化方式，确保内容一致、易维护：

```
模板ID: DEVICE_KICKED
标题: "账户安全通知"
正文: "您的账号已在 {{device_name}} 登录，如非本人操作请立即联系客服"
变量：
  - device_name: "iPhone 15 Pro"
  - device_os: "iOS"
  - device_location: "Beijing"

模板ID: ACCOUNT_LOCKED
标题: "账户已锁定"
正文: "多次登录失败，账号已暂时锁定，请 {{unlock_time_remaining}} 分钟后重试"
变量：
  - unlock_time_remaining: 30
```

---

## 三、数据库设计

### 3.1 `push_notifications` 表

记录所有已发送或待发送的通知：

```sql
CREATE TABLE push_notifications (
    -- 主键
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    -- 通知标识
    notification_id VARCHAR(36) UNIQUE NOT NULL,  -- UUID v4
    
    -- 业务关联
    account_id VARCHAR(36) NOT NULL,               -- FK: accounts.id
    device_id VARCHAR(36),                         -- 目标设备（可空，表示全设备）
    event_id VARCHAR(36),                          -- FK: Kafka event_id
    
    -- 通知内容
    template_id VARCHAR(100) NOT NULL,             -- DEVICE_KICKED, ACCOUNT_LOCKED 等
    title VARCHAR(200) NOT NULL,
    body VARCHAR(500) NOT NULL,
    deep_link VARCHAR(500),                        -- 点击推送后的跳转链接
    
    -- 优先级与 SLA
    priority ENUM('HIGH', 'NORMAL', 'LOW') NOT NULL,
    sla_minutes INT NOT NULL,                      -- 目标投递时间（分钟）
    
    -- 投递渠道
    channels SET('FCM', 'SMS', 'EMAIL', 'IN_APP') NOT NULL,
    
    -- 投递状态
    status ENUM('PENDING', 'SENT', 'FAILED', 'BOUNCED', 'OPTED_OUT') NOT NULL,
    
    -- 投递日志
    fcm_status VARCHAR(50),                        -- DELIVERED, FAILED, BOUNCED
    fcm_message_id VARCHAR(255),                   -- FCM 返回的消息 ID
    fcm_error_code VARCHAR(100),                   -- InvalidRegistration, MessageRateExceeded 等
    sms_status VARCHAR(50),                        -- DELIVERED, FAILED, QUEUED
    sms_message_id VARCHAR(100),
    email_status VARCHAR(50),                      -- SENT, BOUNCED, COMPLAINED
    
    -- 重试信息
    attempt_count INT DEFAULT 0,
    last_attempt_at TIMESTAMP,
    next_retry_at TIMESTAMP,
    max_retries INT DEFAULT 3,
    
    -- 发送时间
    scheduled_at TIMESTAMP,                        -- 计划发送时间
    sent_at TIMESTAMP,                             -- 实际发送时间
    delivered_at TIMESTAMP,
    
    -- 用户交互
    opened_at TIMESTAMP,                           -- 用户打开推送的时间
    clicked_at TIMESTAMP,
    
    -- 创建时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 索引
    UNIQUE KEY `uk_notification_id` (`notification_id`),
    INDEX `idx_account_id` (`account_id`),
    INDEX `idx_device_id` (`device_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_priority_status` (`priority`, `status`),
    INDEX `idx_scheduled_at` (`scheduled_at`),
    INDEX `idx_next_retry_at` (`next_retry_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='推送通知记录表';
```

### 3.2 `notification_preferences` 表

用户配置通知偏好：

```sql
CREATE TABLE notification_preferences (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    account_id VARCHAR(36) NOT NULL UNIQUE,        -- FK: accounts.id
    
    -- 按事件类型的偏好
    device_kicked_enabled BOOLEAN DEFAULT true,
    device_kicked_channels SET('FCM', 'SMS', 'EMAIL') DEFAULT 'FCM,SMS',
    
    account_locked_enabled BOOLEAN DEFAULT true,
    account_locked_channels SET('FCM', 'SMS', 'EMAIL') DEFAULT 'FCM,SMS',
    
    kyc_status_enabled BOOLEAN DEFAULT true,
    kyc_status_channels SET('FCM', 'EMAIL') DEFAULT 'FCM,EMAIL',
    
    w8ben_expiring_enabled BOOLEAN DEFAULT true,
    w8ben_expiring_channels SET('EMAIL') DEFAULT 'EMAIL',
    
    -- 全局设置
    quiet_hours_enabled BOOLEAN DEFAULT false,
    quiet_hours_start VARCHAR(5),                  -- HH:MM（24小时制）
    quiet_hours_end VARCHAR(5),
    
    -- 创建/更新时间
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_account_id` (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 3.3 `push_notification_dlq` 表

死信队列：记录投递失败且重试次数已尽的通知：

```sql
CREATE TABLE push_notification_dlq (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    notification_id VARCHAR(36) NOT NULL,          -- FK: push_notifications.id
    account_id VARCHAR(36) NOT NULL,
    template_id VARCHAR(100) NOT NULL,
    
    failure_reason VARCHAR(500),                   -- 最后一次失败的原因
    last_error_code VARCHAR(100),                  -- FCM/SMS 提供商返回的错误码
    
    -- 调查状态
    investigation_status ENUM('NEW', 'INVESTIGATING', 'RESOLVED', 'IGNORED') DEFAULT 'NEW',
    investigation_notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_account_id` (`account_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='推送通知死信队列';
```

---

## 四、核心流程

### 4.1 事件到推送的完整流程

```
Kafka 事件发布（来自 device-management.md / auth-architecture.md）
  ├─ auth.device_kicked
  ├─ auth.device_added
  ├─ auth.login_failed
  └─ auth.account_locked
  ↓
Notification Service 订阅 Kafka 事件
  ├─ 消费事件，校验签名和格式
  ├─ 根据 event_type 查表 notification_templates
  ├─ 提取模板内容，替换变量
  └─ 渲染最终通知文本
  ↓
查询用户通知偏好（notification_preferences）
  ├─ 用户是否已禁用此事件类型
  ├─ 用户偏好的投递通道
  ├─ 是否在静默时段内
  └─ 若用户禁用，流程终止
  ↓
写入 push_notifications 表
  ├─ status = PENDING
  ├─ 根据优先级设置 scheduled_at
  │   ├─ HIGH：立即发送（scheduled_at = NOW）
  │   ├─ NORMAL：30秒后发送
  │   └─ LOW：5分钟后发送
  └─ 发布 Kafka 事件：notification.scheduled
  ↓
通知投递任务队列（asynq）
  ├─ 任务类型：NotifyUser
  ├─ 执行时间：scheduled_at
  └─ 最大重试次数：根据优先级
      ├─ HIGH：3 次
      ├─ NORMAL：2 次
      └─ LOW：1 次
  ↓
执行投递任务
  ├─ 遍历 channels 列表
  ├─ 按顺序尝试投递（FCM → SMS → Email）
  └─ 记录每个通道的投递结果（见 4.2）
  ↓
更新通知状态
  ├─ status = SENT（至少一个通道成功）
  ├─ 若所有通道失败：
  │   ├─ 尝试重试（exponential backoff）
  │   └─ 若达到 max_retries，移至 DLQ
  └─ 异步发布 Kafka 事件：notification.delivered
```

### 4.2 多通道投递实现

```go
// internal/application/notification/delivery.go

type DeliveryResult struct {
    Channel   string        // FCM, SMS, EMAIL
    Status    string        // DELIVERED, FAILED, QUEUED
    MessageID string        // 投递商返回的消息 ID
    ErrorCode string        // 错误码（失败时）
    Error     string        // 错误信息
}

// 按通道优先级投递
func (svc *NotificationService) DeliverMultiChannel(
    ctx context.Context, 
    notification *Notification,
) ([]DeliveryResult, error) {
    
    results := make([]DeliveryResult, 0)
    
    // 优先级：FCM > SMS > Email
    channelOrder := []string{"FCM", "SMS", "EMAIL"}
    
    for _, channel := range channelOrder {
        if !notification.HasChannel(channel) {
            continue
        }
        
        // 根据用户偏好判断是否投递
        pref, _ := svc.prefRepo.Get(ctx, notification.AccountID)
        if !pref.IsChannelEnabled(notification.Template, channel) {
            continue
        }
        
        // 投递到该通道
        result := svc.deliverToChannel(ctx, notification, channel)
        results = append(results, result)
        
        // 更新通知表
        svc.updateDeliveryStatus(ctx, notification.ID, channel, result)
        
        // 若该通道成功，继续尝试其他备选通道
        if result.Status == "DELIVERED" || result.Status == "QUEUED" {
            continue
        }
    }
    
    return results, nil
}

// 投递到单个通道
func (svc *NotificationService) deliverToChannel(
    ctx context.Context,
    notification *Notification,
    channel string,
) DeliveryResult {
    
    switch channel {
    case "FCM":
        return svc.deliverFCM(ctx, notification)
    case "SMS":
        return svc.deliverSMS(ctx, notification)
    case "EMAIL":
        return svc.deliverEmail(ctx, notification)
    default:
        return DeliveryResult{Channel: channel, Status: "FAILED", Error: "unknown channel"}
    }
}

// Firebase Cloud Messaging 投递
func (svc *NotificationService) deliverFCM(
    ctx context.Context,
    notification *Notification,
) DeliveryResult {
    
    fcmClient := svc.fcmClient // Firebase Admin SDK
    
    message := &messaging.Message{
        Token: notification.FCMToken,
        Data: map[string]string{
            "event_type": notification.Template,
            "event_id": notification.EventID,
        },
        Notification: &messaging.Notification{
            Title: notification.Title,
            Body: notification.Body,
        },
        Android: &messaging.AndroidConfig{
            Priority: mapPriority(notification.Priority), // HIGH, NORMAL
        },
        APNS: &messaging.APNSConfig{
            Payload: &messaging.APNSPayload{
                Aps: &messaging.APS{
                    Alert: &messaging.APS Alert{
                        Title: notification.Title,
                        Body: notification.Body,
                    },
                    Sound: "default",
                    Badge: 1,
                },
            },
        },
    }
    
    messageID, err := fcmClient.Send(ctx, message)
    if err != nil {
        return DeliveryResult{
            Channel: "FCM",
            Status: "FAILED",
            Error: err.Error(),
            ErrorCode: extractFCMErrorCode(err),
        }
    }
    
    return DeliveryResult{
        Channel: "FCM",
        Status: "DELIVERED",
        MessageID: messageID,
    }
}

// SMS 投递（例：Twilio）
func (svc *NotificationService) deliverSMS(
    ctx context.Context,
    notification *Notification,
) DeliveryResult {
    
    twilioClient := svc.twilioClient
    
    msg, err := twilioClient.Messages.Create(ctx, &twilio.MessageInput{
        From: "+1234567890",
        To: notification.PhoneNumber,
        Body: notification.Body,
    })
    
    if err != nil {
        return DeliveryResult{
            Channel: "SMS",
            Status: "FAILED",
            Error: err.Error(),
        }
    }
    
    // Twilio 返回的状态可能是 queued, sending, sent, failed 等
    status := "QUEUED"
    if msg.Status == "sent" {
        status = "DELIVERED"
    } else if msg.Status == "failed" {
        status = "FAILED"
    }
    
    return DeliveryResult{
        Channel: "SMS",
        Status: status,
        MessageID: msg.Sid,
    }
}

// Email 投递（例：SendGrid）
func (svc *NotificationService) deliverEmail(
    ctx context.Context,
    notification *Notification,
) DeliveryResult {
    
    sgClient := svc.sendgridClient
    
    from := mail.NewEmail("Brokerage App", "notify@brokerage.com")
    to := mail.NewEmail("User", notification.Email)
    subject := notification.Title
    
    plainTextContent := notification.Body
    htmlContent := svc.renderEmailTemplate(notification) // 富文本模板
    
    message := mail.NewSingleEmail(from, subject, to, plainTextContent, htmlContent)
    
    response, err := sgClient.Send(message)
    if err != nil {
        return DeliveryResult{
            Channel: "EMAIL",
            Status: "FAILED",
            Error: err.Error(),
        }
    }
    
    // SendGrid 202 表示已接受，实际投递异步进行
    if response.StatusCode == 202 {
        return DeliveryResult{
            Channel: "EMAIL",
            Status: "QUEUED",
            MessageID: response.Headers.Get("X-Message-ID"),
        }
    }
    
    return DeliveryResult{
        Channel: "EMAIL",
        Status: "FAILED",
        Error: fmt.Sprintf("unexpected status: %d", response.StatusCode),
    }
}
```

### 4.3 重试策略（Exponential Backoff）

```
第 1 次失败 → 5 秒后重试
第 2 次失败 → 30 秒后重试
第 3 次失败 → 5 分钟后重试
第 4 次失败 → 移至 DLQ，告警

算法：
  delay = base_delay * (2 ^ attempt) + jitter
  base_delay = 5 秒
  jitter = random(0, 1) 秒 // 防止雷群效应
```

### 4.4 死信队列（DLQ）处理

```
Notification Service 投递失败且超过 max_retries
  ↓
写入 push_notification_dlq 表
  ├─ notification_id
  ├─ failure_reason
  ├─ last_error_code
  └─ investigation_status = 'NEW'
  ↓
Alerting Service 发送告警
  ├─ 对象：运维团队、Security 团队
  ├─ 内容：失败通知的 account_id、template_id、错误信息
  └─ 优先级：
      ├─ 若通知是 HIGH（如 ACCOUNT_LOCKED）→ P1 告警
      ├─ 若通知是 NORMAL → P3 告警
      └─ 若通知是 LOW → 日志记录
  ↓
运维人员查看 DLQ
  ├─ 分析失败原因（如 FCM token 失效、手机号不存在等）
  ├─ 标记 investigation_status
  │   ├─ RESOLVED：问题已解决，可重试
  │   ├─ IGNORED：此通知无需重新发送
  │   └─ INVESTIGATING：还在分析中
  └─ 若 RESOLVED，手动触发重试任务
  ↓
定期清理（每日）
  ├─ 删除 7 天前的 DLQ 记录（已 RESOLVED 或 IGNORED 的）
  └─ 保留最近 90 天的异常记录（用于趋势分析）
```

---

## 五、Webhook 集成与通知反馈

### 5.1 Provider Webhooks（来自 FCM、SMS、Email 提供商）

AMS 接收来自第三方的异步回调，更新通知状态：

```
Firebase Cloud Messaging Webhook：
  ↓
POST /webhooks/fcm
{
  "registration_token": "fcm_token",
  "message_id": "fcm_message_id",
  "data": {
    "notification_id": "uuid",
    "status": "DELIVERED"
  },
  "timestamp": "2026-04-01T10:30:00Z",
  "signature": "HMAC-SHA256(...)"  // 签名验证
}
  ↓
验证签名（HMAC-SHA256，密钥来自 env）
  ├─ header: X-FCM-Signature
  ├─ payload: raw request body
  └─ 若签名不匹配，返回 401
  ↓
更新 push_notifications 表
  ├─ WHERE notification_id = ? AND fcm_message_id = ?
  ├─ SET fcm_status = 'DELIVERED', delivered_at = NOW()
  └─ 发布 Kafka 事件：notification.delivered
```

**Webhook 签名规范**：

```
HMAC Key：环境变量 WEBHOOK_HMAC_KEY
算法：HMAC-SHA256
签名生成：
  signature = hex(HMAC-SHA256(request_body, WEBHOOK_HMAC_KEY))

验证流程（Go 示例）：
  mac := hmac.New(sha256.New, []byte(os.Getenv("WEBHOOK_HMAC_KEY")))
  mac.Write(requestBody)
  expectedSignature := hex.EncodeToString(mac.Sum(nil))
  
  providedSignature := r.Header.Get("X-Webhook-Signature")
  if !hmac.Equal([]byte(expectedSignature), []byte(providedSignature)) {
    return fmt.Errorf("signature verification failed")
  }
```

### 5.2 用户交互反馈（Mobile Client）

当用户在手机上打开/点击推送时，Mobile App 向 AMS 报告：

```
用户打开推送通知
  ↓
Mobile Client 调用：
  POST /api/v1/notifications/{notification_id}/opened
  ↓
后端更新：
  UPDATE push_notifications 
  SET opened_at = NOW() 
  WHERE notification_id = ?
  ↓
发布 Kafka 事件：notification.opened
  ├─ 用于用户行为分析
  └─ 追踪推送有效性
```

---

## 六、Kafka 事件定义

### 6.1 事件映射表

| Kafka 事件（来源） | Notification Service 反应 | 生成的推送模板 | 优先级 |
|------------------|--------------------------|---------------|-------|
| `auth.device_kicked` | 立即生成推送 | DEVICE_KICKED | HIGH |
| `auth.login_failed` | 失败 5 次时生成推送 | ACCOUNT_LOCKED | HIGH |
| `auth.device_added` | 生成推送 | UNAUTHORIZED_LOGIN | NORMAL |
| `kyc.completed` | 生成推送 + 邮件 | KYC_APPROVED | NORMAL |
| `w8ben.expiring_soon` | 生成邮件 | W8BEN_EXPIRING | NORMAL |
| `aml.flagged` | 生成邮件 | ACCOUNT_WARNING | NORMAL |

### 6.2 事件 Payload

**事件：notification.scheduled**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "NOTIFICATION_SCHEDULED",
  "timestamp": "2026-04-01T10:30:00.123Z",
  "notification_id": "notif-uuid",
  "account_id": "user-123",
  "template_id": "DEVICE_KICKED",
  "priority": "HIGH",
  "channels": ["FCM", "SMS"],
  "scheduled_at": "2026-04-01T10:30:00Z",
  "correlation_id": "req-abc"
}
```

**事件：notification.delivered**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "NOTIFICATION_DELIVERED",
  "timestamp": "2026-04-01T10:30:02.456Z",
  "notification_id": "notif-uuid",
  "account_id": "user-123",
  "channels_delivered": ["FCM"],
  "channels_failed": ["SMS"],
  "sms_error_code": "InvalidPhoneNumber",
  "correlation_id": "req-abc"
}
```

---

## 七、与其他模块的协作

### 7.1 事件来源

推送通知系统消费以下来源的 Kafka 事件：

| 事件来源 | 模块 | 事件 |
|--------|------|------|
| **device-management.md** | AMS | `auth.device_kicked`, `auth.device_added` |
| **auth-architecture.md** | AMS | `auth.login_failed`, `auth.account_locked` |
| **kyc-flow.md** | AMS | `kyc.completed`, `kyc.rejected` |
| **aml-compliance.md** | AMS | `aml.flagged`, `aml.cleared` |
| **w8ben-lifecycle.md** | AMS | `w8ben.expiring_soon`, `w8ben.renewed` |

### 7.2 与 mobile PRD 的对应关系

| Mobile PRD 需求 | 本规范实现 |
|---------------|----------|
| § 9 推送通知 | ✅ § 2.1 通知事件分类 |
| 新设备登录告警 | ✅ UNAUTHORIZED_LOGIN 事件 |
| 设备被踢通知 | ✅ DEVICE_KICKED 事件 |
| 账户被锁定通知 | ✅ ACCOUNT_LOCKED 事件 |
| 多渠道投递 | ✅ § 4.2 多通道投递实现 |

---

## 八、实现指南

### 8.1 Go 服务框架

```go
// internal/domain/notification/notification.go
type Notification struct {
    ID            int64
    NotificationID string
    AccountID     string
    DeviceID      *string
    TemplateID    string
    Title         string
    Body          string
    Priority      NotificationPriority
    Channels      []string // FCM, SMS, EMAIL, IN_APP
    Status        NotificationStatus
    ScheduledAt   time.Time
    SentAt        *time.Time
    DeliveredAt   *time.Time
}

// internal/application/notification/service.go
type NotificationService interface {
    OnDeviceKicked(ctx context.Context, event *DeviceKickedEvent) error
    OnAccountLocked(ctx context.Context, event *AccountLockedEvent) error
    Deliver(ctx context.Context, notification *Notification) error
    GetPreferences(ctx context.Context, accountID string) (*NotificationPreferences, error)
}
```

### 8.2 中间件：请求/响应签名验证

```go
// internal/transport/http/middleware/webhook_signature.go
func WebhookSignatureMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // 仅验证 /webhooks/* 路由
        if !strings.HasPrefix(r.URL.Path, "/webhooks/") {
            next.ServeHTTP(w, r)
            return
        }
        
        // 读取请求体
        body, err := ioutil.ReadAll(r.Body)
        r.Body = ioutil.NopCloser(bytes.NewBuffer(body))
        
        // 验证签名
        signature := r.Header.Get("X-Webhook-Signature")
        if !verifySignature(body, signature) {
            respondError(w, 401, "INVALID_SIGNATURE", "Webhook signature verification failed")
            return
        }
        
        next.ServeHTTP(w, r)
    })
}
```

### 8.3 数据库迁移

```sql
-- src/migrations/00006_create_notification_tables.sql
-- up

CREATE TABLE push_notifications (
    -- 表定义见 § 三
);

CREATE TABLE notification_preferences (
    -- 表定义见 § 三
);

CREATE TABLE push_notification_dlq (
    -- 表定义见 § 三
);

-- down

DROP TABLE IF EXISTS push_notification_dlq;
DROP TABLE IF EXISTS notification_preferences;
DROP TABLE IF EXISTS push_notifications;
```

---

## 九、监控与告警

### 9.1 关键指标（Prometheus）

```
# 推送成功率
push_notification_delivery_success_rate{template_id="DEVICE_KICKED", channel="FCM"}
push_notification_delivery_success_rate{template_id="DEVICE_KICKED", channel="SMS"}

# 投递延迟（P50, P95, P99）
push_notification_delivery_latency_seconds{priority="HIGH"}
push_notification_delivery_latency_seconds{priority="NORMAL"}

# DLQ 数量
push_notification_dlq_size{template_id="DEVICE_KICKED"}
push_notification_dlq_size{template_id="ACCOUNT_LOCKED"}

# 用户偏好（禁用推送的占比）
notification_preferences_opt_out_rate{template_id="DEVICE_KICKED"}
```

### 9.2 告警规则

```
告警 1：高优先级推送失败率 > 5%
  ├─ 条件：push_notification_delivery_success_rate{priority="HIGH"} < 0.95
  ├─ 持续时间：5 分钟
  └─ 严重级别：P1（页面通知）

告警 2：推送延迟 > 10 秒（HIGH 优先级）
  ├─ 条件：push_notification_delivery_latency_seconds{priority="HIGH", quantile="0.95"} > 10
  ├─ 持续时间：10 分钟
  └─ 严重级别：P2

告警 3：DLQ 大小 > 100
  ├─ 条件：sum(push_notification_dlq_size) > 100
  ├─ 持续时间：15 分钟
  └─ 严重级别：P2（运维调查）
```

---

## 十、测试用例矩阵

| 场景 | 输入 | 预期输出 | 验收标准 |
|------|------|---------|---------|
| 设备被踢出 | `auth.device_kicked` Kafka 事件 | 推送 + SMS 在 5s 内发送 | 5s SLA 满足 |
| 账户被锁定 | 5 次 OTP 失败 | 推送 + SMS 通知 | 用户收到告警 |
| 用户禁用推送 | 设置 notification_preferences.device_kicked_enabled = false | 无推送发送 | 偏好被尊重 |
| 推送失败重试 | 第 1 次 FCM 失败 | 5s 后重试 SMS | 重试逻辑生效 |
| DLQ 处理 | 推送失败 3 次 | 移至 DLQ，告警发送 | 可追溯查询 |
| 多通道投递 | 指定 channels=["FCM", "SMS"] | 优先尝试 FCM，若失败尝试 SMS | 备选通道逻辑 |

---

## 十一、Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-04-01 | 初版发布：多通道推送、优先级 SLA、重试与 DLQ、Webhook 集成 |

---

## 参考资料

- `device-management.md` — 设备管理事件源
- `auth-architecture.md` — 认证相关事件源
- `kafka-events.md` — Kafka 事件驱动架构
- `../../mobile/docs/prd/01-auth.md § 9` — 移动端推送需求
- `../../.claude/rules/security-compliance.md` — API 安全与签名验证
