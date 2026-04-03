---
title: 设备管理系统设计
description: AMS 设备并发管理、超限踢出、远程注销的完整设计
version: 1.0
created: 2026-04-01
updated: 2026-04-01
related_specs:
  - auth-architecture.md
  - account-financial-model.md
  - kafka-events.md
related_prd:
  - ../prd/decisions-2026-03-29.md
  - ../../mobile/docs/prd/01-auth.md § 4.4
---

# 设备管理系统设计

## 一、概述

### 1.1 场景与价值

用户可在多个设备上登录账户（手机、平板、PC），AMS 需要：
- **并发限制**：同一账户最多 3 台设备同时在线，防止账户滥用
- **超限踢出**：新设备登录时自动踢出最早登录的设备（FIFO），并推送通知
- **主动注销**：用户可远程管理设备，注销他人设备需生物识别验证
- **安全告警**：新设备登录时推送通知，告知用户是否本人操作

### 1.2 设计目标

1. **用户体验**：无感知管理；新设备快速登录；被踢出时收到通知
2. **安全性**：防止账户被恶意登录；未授权设备操作需验证
3. **合规性**：记录所有设备操作日志（7 年审计保留）
4. **可扩展性**：支持未来扩大并发上限（当前 3 台）

---

## 二、核心业务规则

### 2.1 并发限制规则

| 规则 | 说明 |
|------|------|
| **最大并发设备数** | 3 台 |
| **新设备登录时** | 若账户已有 3 台设备，自动踢出"最早登录时间"的设备 |
| **踢出通知** | 被踢出的设备立即收到推送通知（优先级：高） |
| **新设备通知** | 当前设备收到"新设备已登录"通知（优先级：普通） |

### 2.2 设备标识

设备通过以下信息组合唯一标识：

```
device_id = UUID v4（在客户端生成，长期不变）
device_fingerprint = HMAC-SHA256(device_id || model || os_version)
                     （用于检测设备变更，如 iOS 越狱、Android root）
```

**设备名称规则**（用户可见）：
- iOS：`iPhone 15 Pro` 或自定义别名
- Android：`Xiaomi 13 Ultra` 或自定义别名
- PC：`MacBook Pro (M2)` 或自定义别名

**设备指纹设计**：

```go
type DeviceFingerprint struct {
    DeviceID    string // UUID v4
    ModelName   string // "iPhone 15 Pro", "SM-S918B" 等
    OSVersion   string // iOS 17.3, Android 14 等
    AppVersion  string // 客户端 app 版本
    BuildNumber string // 构建号
}

// 指纹 HMAC（用于检测设备变更）
fingerprint := HMAC-SHA256(json(DeviceFingerprint), hmacKey)
// 在设备变更时（重装系统、越狱等）重新绑定生物识别
```

### 2.3 设备状态机

```
ACTIVE
  ├─→ LOCALLY_LOGGED_OUT（用户在此设备上注销登录）
  ├─→ REMOTELY_KICKED（被其他设备踢出，设备即将下线）
  └─→ SESSION_EXPIRED（会话自然过期，刷新失败）

LOCALLY_LOGGED_OUT
REMOTELY_KICKED
SESSION_EXPIRED
  └─→ [状态转换终止，等待下次登录重新注册为 ACTIVE]
```

---

## 三、数据库设计

### 3.1 `devices` 表

```sql
CREATE TABLE devices (
    -- 主键
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    -- 业务标识
    account_id VARCHAR(36) NOT NULL,                          -- FK: accounts.id
    device_id VARCHAR(36) NOT NULL UNIQUE,                    -- 客户端生成的 UUID v4
    device_fingerprint VARCHAR(255),                           -- SHA256(device_id + model + os)
    
    -- 设备信息（用户可见）
    device_name VARCHAR(100) NOT NULL,                         -- "iPhone 15 Pro"
    os_type ENUM('ios', 'android', 'web', 'other') NOT NULL,  -- 操作系统
    os_version VARCHAR(50),                                    -- "17.3", "14.0"
    app_version VARCHAR(50),                                   -- 客户端版本
    build_number VARCHAR(50),                                  -- 构建号
    
    -- 设备状态
    status ENUM('ACTIVE', 'LOCALLY_LOGGED_OUT', 'REMOTELY_KICKED', 'SESSION_EXPIRED') DEFAULT 'ACTIVE',
    
    -- 时间戳
    login_time TIMESTAMP NOT NULL,                             -- 首次登录时间
    last_activity_time TIMESTAMP NOT NULL,                     -- 最后活跃时间（每次 API 调用更新）
    kicked_at TIMESTAMP,                                       -- 被踢出时间（status=REMOTELY_KICKED）
    logged_out_at TIMESTAMP,                                   -- 手动注销时间
    
    -- 安全信息
    ip_address VARCHAR(45),                                    -- 登录时的 IP（IPv4/IPv6）
    ip_range_/24 VARCHAR(45),                                  -- IP 段（用于会话绑定，如 192.168.1.0/24）
    location_country VARCHAR(2),                               -- ISO 3166-1 alpha-2（如 CN, US, HK）
    location_city VARCHAR(100),                                -- 城市名（基于 GeoIP）
    
    -- 索引
    UNIQUE KEY `uk_account_device` (`account_id`, `device_id`),
    INDEX `idx_account_id` (`account_id`),
    INDEX `idx_account_status` (`account_id`, `status`),
    INDEX `idx_login_time` (`account_id`, `login_time`),
    INDEX `idx_device_id` (`device_id`),
    
    -- 审计
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户登录设备记录表';

-- 辅助索引：用于 FIFO 踢出查询
CREATE INDEX idx_account_login_time ON devices(account_id, login_time ASC)
WHERE status = 'ACTIVE';
```

### 3.2 `device_session_bindings` 表（可选：优化并发查询）

```sql
CREATE TABLE device_session_bindings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    device_id VARCHAR(36) NOT NULL UNIQUE,
    account_id VARCHAR(36) NOT NULL,
    session_id VARCHAR(36) NOT NULL,                          -- Redis session key
    access_token_hash VARCHAR(255),                            -- SHA256(access_token)
    
    jwt_iat BIGINT,                                            -- JWT issued_at (Unix)
    jwt_exp BIGINT,                                            -- JWT expiry (Unix)
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uk_device_session` (`device_id`, `session_id`),
    INDEX `idx_account_id` (`account_id`),
    INDEX `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 四、核心流程

### 4.1 设备注册流程（首次登录）

```
OTP 验证成功
  ↓
用户服务器调用 /auth/register 或 /auth/login
  ↓
后端检查 device_id 是否已存在
  ├─ 是：设备重新登录（更新 last_activity_time 和 status=ACTIVE）
  └─ 否：创建新设备记录
  ↓
查询账户的所有 ACTIVE 设备数
  ├─ < 3 台：直接颁发 JWT + 会话
  ├─ = 3 台：触发 FIFO 踢出流程（见 4.2）
  └─ > 3 台：数据异常，触发告警并拒绝登录
  ↓
推送"新设备已登录"通知（可选，取决于地理位置）
```

**数据库操作（原子性）**：

```go
// 使用事务保证原子性
tx := db.BeginTx(ctx, nil)
defer tx.Rollback()

// 1. 插入或更新 device 记录
result, err := tx.ExecContext(ctx, `
    INSERT INTO devices 
    (account_id, device_id, device_name, os_type, os_version, 
     device_fingerprint, login_time, last_activity_time, ip_address, 
     ip_range_/24, location_country, location_city, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVE')
    ON DUPLICATE KEY UPDATE
        status = 'ACTIVE',
        last_activity_time = NOW(),
        ip_address = VALUES(ip_address),
        ip_range_/24 = VALUES(ip_range_/24)
`, accountID, deviceID, deviceName, osType, osVersion,
   fingerprint, time.Now(), time.Now(), ipAddr, ipRange,
   country, city)

// 2. 计算 ACTIVE 设备数
activeCount := tx.QueryRowContext(ctx, `
    SELECT COUNT(*) FROM devices 
    WHERE account_id = ? AND status = 'ACTIVE'
`, accountID).Scan(&count)

// 3. 若超过 3 台，踢出最早的设备
if count > 3 {
    oldestDevice, _ := tx.QueryRowContext(ctx, `
        SELECT id, device_id, device_name 
        FROM devices
        WHERE account_id = ? AND status = 'ACTIVE'
        ORDER BY login_time ASC
        LIMIT 1
    `, accountID)
    
    // 更新为踢出状态
    tx.ExecContext(ctx, `
        UPDATE devices SET status = 'REMOTELY_KICKED', kicked_at = NOW()
        WHERE id = ?
    `, oldestID)
    
    // 发布 Kafka 事件（见 4.4）
    publishKickEvent(tx, accountID, oldestDeviceID, "AUTO_LIMIT")
}

// 4. 提交事务
tx.Commit()
```

### 4.2 超限踢出流程（FIFO）

当新设备登录且账户已有 3 台 ACTIVE 设备时：

```
查询 ACTIVE 设备，按 login_time 升序
  ↓
取最早的设备（oldest_device）
  ↓
标记 status = REMOTELY_KICKED，kicked_at = NOW()
  ↓
发布 Kafka 事件：device.kicked
  ├─ event_type: "DEVICE_KICKED"
  ├─ account_id: "user-123"
  ├─ kicked_device_id: "device-456"
  ├─ reason: "AUTO_LIMIT" / "MANUAL_REVOCATION"
  ├─ timestamp: 2026-04-01T10:30:00Z
  └─ initiator: "system" / "user-account-id"
  ↓
推送通知到被踢设备（FCM）
  ├─ 优先级：高
  ├─ 内容："{user_name} 的账号已在新设备登录，如非本人操作请立即联系客服"
  ├─ Action: 打开设备管理页面
  └─ 重试：最多 3 次（指数退避）
  ↓
被踢设备下次尝试 API 调用时
  ├─ JWT 验证通过（Token 未过期）
  ├─ 但 device_id 对应的设备状态 = REMOTELY_KICKED
  ├─ 返回 401 Unauthorized，reason="DEVICE_KICKED"
  └─ 客户端清除 session，提示用户"该设备已在其他地点退出登录"
```

### 4.3 主动注销流程（远程注销他人设备）

```
用户在 Device A 上打开"设备管理"页面
  ↓
选择 Device B，点击"注销此设备"
  ↓
触发生物识别验证（防误操作）
  ├─ 成功：继续
  └─ 失败：返回错误，不执行注销
  ↓
调用 DELETE /auth/devices/{device_b_id}
  ↓
后端验证：
  ├─ device_b_id 属于当前 account_id（认证 JWT 中）
  ├─ 执行者 device_a_id 的生物识别验证码有效（5 分钟内）
  └─ 若验证失败，返回 403 Forbidden
  ↓
更新 Device B 的状态
  ├─ status = LOCALLY_LOGGED_OUT
  ├─ logged_out_at = NOW()
  └─ 同步推送通知给 Device B（告知其已被远程注销）
  ↓
发布 Kafka 事件：device.revoked
  ├─ event_type: "DEVICE_REVOKED"
  ├─ account_id: "user-123"
  ├─ revoked_device_id: "device-b-id"
  ├─ initiator_device_id: "device-a-id"
  └─ timestamp: 2026-04-01T10:35:00Z
  ↓
Device B 收到推送后，清除会话
  ├─ 删除 refresh_token from Redis
  ├─ 清空本地 JWT
  └─ 返回冷启动页（"登录已过期，请重新登录"）
```

### 4.4 会话验证与设备强制下线

**每个 API 请求流程**：

```
请求头：Authorization: Bearer <access_token>
  ↓
中间件 1：JWT 验证 & Claims 解析
  ├─ 检查签名（RS256 公钥）
  ├─ 检查过期时间（iat + 15 min）
  ├─ 提取 claims：{account_id, device_id, ...}
  └─ 若失败，返回 401 Unauthorized
  ↓
中间件 2：设备状态检查
  ├─ SELECT status FROM devices WHERE device_id = ?
  ├─ 若 status = 'REMOTELY_KICKED'：
  │   ├─ 返回 401 + reason="DEVICE_KICKED"
  │   ├─ 客户端清除会话，推送到前台：
  │   │  "该设备已在其他地点注销登录，请重新登录"
  │   └─ 前端清空 JWT + refresh_token，显示冷启动页
  ├─ 若 status = 'LOCALLY_LOGGED_OUT'：
  │   └─ 返回 401 + reason="LOCALLY_SIGNED_OUT"
  └─ 若 status = 'ACTIVE'：继续
  ↓
中间件 3：IP 范围检查（可选，加强安全）
  ├─ 提取当前请求 IP
  ├─ 查询 devices.ip_range_/24
  ├─ 若超出范围，要求重新验证（生物识别或 OTP）
  └─ （仅适用于检测异常地理位置，见 § 五）
  ↓
中间件 4：更新最后活跃时间
  ├─ UPDATE devices SET last_activity_time = NOW() WHERE device_id = ?
  └─ （异步执行，不阻塞请求）
  ↓
执行 API 处理器
```

---

## 五、安全与异常处理

### 5.1 地理位置异常检测（可选 Phase 2）

```
同一账户在短时间内从远距离地点登录
  ↓
检测逻辑：
  ├─ 若 Device A 距离 Device B > 1000 km
  └─ 且时间间隔 < 2 小时
  ↓
行为：
  ├─ 推送告警通知："{location} 新地点登录，如非本人操作请立即修改密码"
  ├─ 标记 risk_level = 'MEDIUM'
  └─ 记录审计日志
```

### 5.2 设备变更检测（指纹/面容更换）

若用户在设备上更换指纹或面容注册：

```
客户端检测到 Face ID / Touch ID 变更
  ↓
调用 POST /auth/biometric/register（新注册生物识别）
  ↓
后端收到请求：
  ├─ device_fingerprint 已变更（重装系统、越狱等）
  ├─ 清除旧的生物识别绑定
  ├─ 要求用户重新输入 OTP 以重新关联
  └─ 发布事件：device.biometric_reset
  ↓
生物识别重新关联成功后
  ├─ 更新 devices.device_fingerprint
  └─ 标记 biometric_verified_at = NOW()
```

### 5.3 错误处理矩阵

| 场景 | HTTP 状态 | 错误代码 | 用户提示 |
|------|----------|---------|---------|
| 设备已被踢出 | 401 | `DEVICE_KICKED` | "该设备已在其他地点登录，请重新登录" |
| 设备已手动注销 | 401 | `DEVICE_SIGNED_OUT` | "您已在该设备上注销登录" |
| 超过 3 台并发限制 | 403 | `DEVICE_LIMIT_EXCEEDED` | 自动踢出，不返回错误给新设备 |
| 设备指纹变更 | 403 | `DEVICE_INTEGRITY_CHECK_FAILED` | "设备信息已变更，请重新验证" |
| IP 范围异常 | 403 | `IP_RANGE_VIOLATION` | "检测到异常登录位置，请重新验证" |

---

## 六、Kafka 事件定义

### 6.1 事件模式

所有设备事件遵循 AMS 统一的 Kafka 事件格式（见 `kafka-events.md`）

| 事件 | Topic | Partition Key | Priority | Consumer |
|------|-------|---------------|----------|----------|
| 新设备登录 | `auth.device_added` | account_id | NORMAL | Notification Service |
| 设备被踢出 | `auth.device_kicked` | account_id | **HIGH** | Notification Service, AuditLog |
| 设备被注销 | `auth.device_revoked` | account_id | NORMAL | Notification Service, AuditLog |
| 会话过期 | `auth.session_expired` | account_id | LOW | AuditLog |

### 6.2 事件 Payload 定义

**事件：auth.device_added**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "DEVICE_ADDED",
  "timestamp": "2026-04-01T10:30:00.123Z",
  "account_id": "user-123",
  "device_id": "device-uuid-v4",
  "device_name": "iPhone 15 Pro",
  "os_type": "ios",
  "location_country": "CN",
  "location_city": "Beijing",
  "ip_address": "192.168.1.100",
  "initiator": "system",
  "correlation_id": "req-abc-def"
}
```

**事件：auth.device_kicked**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "DEVICE_KICKED",
  "timestamp": "2026-04-01T10:35:00.456Z",
  "account_id": "user-123",
  "kicked_device_id": "device-456",
  "kicked_device_name": "iPad Air",
  "reason": "AUTO_LIMIT",  // 可选值：AUTO_LIMIT, MANUAL_REVOCATION, SECURITY_POLICY
  "initiator": "system",    // system 或其他 device_id
  "correlation_id": "req-xyz-abc"
}
```

**事件：auth.device_revoked**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "DEVICE_REVOKED",
  "timestamp": "2026-04-01T10:40:00.789Z",
  "account_id": "user-123",
  "revoked_device_id": "device-789",
  "revoked_device_name": "MacBook Pro",
  "initiator_device_id": "device-999",
  "reason": "MANUAL_REVOCATION",
  "correlation_id": "req-123-456"
}
```

### 6.3 消费方协议

**Notification Service**：
- 订阅 `auth.device_kicked`，优先级 HIGH
- 立即推送：FCM + SMS（重试最多 3 次）
- SLA：5 秒内首次尝试投递

**AuditLog Service**：
- 订阅所有设备相关事件
- 存储到不可更改的审计表
- 保留 7 年

---

## 七、与其他模块的协作

### 7.1 与 auth-architecture.md 的关系

| 功能 | auth-architecture.md | device-management.md |
|------|---------------------|--------------------|
| JWT 签发 | ✅ 定义 Token Claims | ← 包含 device_id |
| 设备绑定 | ✅ Device ID in JWT | ✅ 设备并发管理 |
| Token 黑名单 | ✅ Redis key: token_blacklist | ← 用于快速下线 |
| 会话管理 | ✅ Refresh Token 轮换 | ✅ 跨设备会话隔离 |

### 7.2 与 mobile PRD 的对应关系

| Mobile PRD 需求 | 本规范实现 |
|---------------|----------|
| § 4.4 最多 3 台设备 | ✅ § 2.1 并发限制规则 |
| § 4.4 超限踢出 | ✅ § 4.2 超限踢出流程 |
| § 4.4 远程注销设备 | ✅ § 4.3 主动注销流程 |
| § 6.3 设备显示 | ✅ § 3.1 devices 表 |
| § 9 设备被踢通知 | ✅ § 4.2 推送通知 |

### 7.3 与 push-notification.md 的关系

本规范中的以下事件由 push-notification.md 定义投递规则：
- `auth.device_kicked` → 推送 + 短信（多渠道投递）
- `auth.device_added` → 推送通知
- `auth.device_revoked` → 推送通知

---

## 八、实现指南

### 8.1 Go 服务实现框架

```go
// internal/domain/device/device.go
type Device struct {
    ID              int64
    AccountID       string
    DeviceID        string
    DeviceName      string
    OSType          string
    DeviceFingerprint string
    Status          DeviceStatus
    LoginTime       time.Time
    LastActivityTime time.Time
    KickedAt        *time.Time
}

type DeviceStatus string
const (
    DeviceStatusActive        = "ACTIVE"
    DeviceStatusKicked        = "REMOTELY_KICKED"
    DeviceStatusLoggedOut     = "LOCALLY_LOGGED_OUT"
    DeviceStatusSessionExpired = "SESSION_EXPIRED"
)

// internal/application/device/service.go
type DeviceService interface {
    RegisterDevice(ctx context.Context, req *RegisterDeviceRequest) (*Device, error)
    ListDevices(ctx context.Context, accountID string) ([]*Device, error)
    RevokeDevice(ctx context.Context, accountID, deviceID string) error
    CheckDeviceStatus(ctx context.Context, deviceID string) (DeviceStatus, error)
    CheckConcurrentLimit(ctx context.Context, accountID string) (int, error)
}

// internal/infrastructure/repository/device_repository.go
type DeviceRepository interface {
    Create(ctx context.Context, device *Device) error
    FindByID(ctx context.Context, deviceID string) (*Device, error)
    FindActiveByAccount(ctx context.Context, accountID string) ([]*Device, error)
    UpdateStatus(ctx context.Context, deviceID string, status DeviceStatus) error
    CountActive(ctx context.Context, accountID string) (int, error)
}
```

### 8.2 中间件实现

```go
// internal/transport/http/middleware/device_check.go
func DeviceCheckMiddleware(deviceRepo DeviceRepository) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // 从 JWT claims 获取 device_id
            claims := r.Context().Value("claims").(*AMSClaims)
            
            // 查询设备状态
            status, err := deviceRepo.FindStatus(r.Context(), claims.DeviceID)
            if err != nil {
                respondError(w, 401, "DEVICE_CHECK_FAILED", err.Error())
                return
            }
            
            // 检查是否被踢出
            switch status {
            case DeviceStatusKicked:
                respondError(w, 401, "DEVICE_KICKED", 
                    "该设备已在其他地点登录，请重新登录")
                return
            case DeviceStatusLoggedOut:
                respondError(w, 401, "DEVICE_SIGNED_OUT",
                    "您已在该设备上注销登录")
                return
            }
            
            // 更新最后活跃时间（异步）
            go deviceRepo.UpdateLastActivity(context.Background(), claims.DeviceID)
            
            next.ServeHTTP(w, r)
        })
    }
}
```

### 8.3 数据库迁移

```go
// src/migrations/00004_create_devices_table.sql
-- up

CREATE TABLE devices (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    account_id VARCHAR(36) NOT NULL,
    device_id VARCHAR(36) NOT NULL UNIQUE,
    device_fingerprint VARCHAR(255),
    device_name VARCHAR(100) NOT NULL,
    os_type ENUM('ios', 'android', 'web', 'other') NOT NULL,
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    build_number VARCHAR(50),
    status ENUM('ACTIVE', 'LOCALLY_LOGGED_OUT', 'REMOTELY_KICKED', 'SESSION_EXPIRED') DEFAULT 'ACTIVE',
    login_time TIMESTAMP NOT NULL,
    last_activity_time TIMESTAMP NOT NULL,
    kicked_at TIMESTAMP,
    logged_out_at TIMESTAMP,
    ip_address VARCHAR(45),
    ip_range_/24 VARCHAR(45),
    location_country VARCHAR(2),
    location_city VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `uk_account_device` (`account_id`, `device_id`),
    INDEX `idx_account_id` (`account_id`),
    INDEX `idx_account_status` (`account_id`, `status`),
    INDEX `idx_login_time` (`account_id`, `login_time`),
    INDEX `idx_device_id` (`device_id`),
    INDEX `idx_account_login_time` (`account_id`, `login_time` ASC) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户登录设备记录表';

-- down

DROP TABLE IF EXISTS devices;
```

---

## 九、测试用例矩阵

| 场景 | 输入 | 预期输出 | 验收标准 |
|------|------|---------|---------|
| 新设备首次登录 | 新 device_id，OTP 验证通过 | 设备入库，status=ACTIVE | devices 表记录 +1 |
| 第 4 台设备登录 | 账户已有 3 台 ACTIVE 设备 | 自动踢出最早设备，推送通知 | devices.status=REMOTELY_KICKED，FCM 发送 |
| 设备 A 远程注销设备 B | POST /auth/devices/{device_b}/revoke + 生物识别 | Device B status=LOCALLY_LOGGED_OUT，推送通知 | Device B 会话失效 |
| 被踢出设备尝试 API 调用 | 旧 access_token，device_status=REMOTELY_KICKED | 返回 401 DEVICE_KICKED | 客户端清空会话 |
| 设备指纹变更 | 用户重装系统，重新注册生物识别 | 清除旧绑定，要求 OTP 重新验证 | biometric_verified_at 更新 |

---

## 十、Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-04-01 | 初版发布：设备并发管理、超限踢出、远程注销、Kafka 事件定义 |

---

## 参考资料

- `auth-architecture.md` — JWT 和认证体系
- `kafka-events.md` — Kafka 事件驱动架构
- `../../mobile/docs/prd/01-auth.md` — Mobile 用户需求
- `../../.claude/rules/financial-coding-standards.md` — Decimal、UTC 时间戳等
- `../../.claude/rules/security-compliance.md` — PII 加密、速率限制等
