---
title: 访客模式系统设计
description: 无认证访客用户的完整系统设计、页面权限矩阵、SECレギュレーション遵守
version: 1.0
created: 2026-04-01
updated: 2026-04-01
related_specs:
  - auth-architecture.md
  - account-financial-model.md
  - kafka-events.md
related_prd:
  - ../prd/decisions-2026-03-29.md
  - ../../mobile/docs/prd/01-auth.md § 4.3
---

# 访客模式系统设计

## 一、概述

### 1.1 产品背景

许多用户在决定注册之前想先体验 App，查看实时行情、股票详情等。访客模式允许用户：
- **无需注册** 即可浏览延迟 15 分钟的行情数据
- **触发登录** 当用户想下单、查看持仓时
- **无缝转换** 从访客升级为认证用户

### 1.2 设计目标

1. **降低获客成本**：访客模式减少注册摩擦，提高首次体验转化率
2. **合规性**：所有延迟行情必须标注"Delayed 15 minutes"（SEC NMS 要求）
3. **用户体验**：访客和认证用户享受无缝的 UI 过渡
4. **数据安全**：访客会话不存储 PII，无用户个人信息泄露风险

---

## 二、核心业务规则

### 2.1 访客会话生命周期

```
用户点击"先逛逛"
  ↓
创建临时访客会话（无认证）
  ├─ guest_session_id = UUID v4
  ├─ ip_address = 当前请求 IP
  ├─ session_ttl = 7 天
  └─ 不存储任何 PII
  ↓
行情首页显示延迟数据
  ├─ 显示"延迟 15 分钟"标识（SEC 合规）
  └─ 所有行情数据来自 market_data_service 的延迟源
  ↓
用户操作：
  ├─ 浏览行情/搜索：继续访客模式
  ├─ 点击买入/卖出：弹出登录 Sheet
  ├─ 点击订单/持仓/我的：显示登录占位页
  └─ 手动点击"登录"：进入 OTP 流程
  ↓
用户完成 OTP 登录
  ├─ 新建账户（如果是新用户）
  ├─ 关联 guest_session_id 到 account_id（审计日志）
  ├─ 清除访客会话
  └─ 颁发认证 JWT，切换到完整 App 体验
  ↓
会话过期
  ├─ guest_session_ttl = 7 天
  └─ 过期时自动清理（无需主动登出）
```

**关键约束**：
- 访客会话与认证会话完全隔离
- 访客数据不持久化，仅 Redis 存储（内存）
- 无法跨登录存储访客偏好（watchlist 等）

### 2.2 页面权限矩阵

访客模式下，不同页面的可访问性：

| 页面 | 访客可用 | 说明 |
|------|--------|------|
| **行情首页（Quote Home）** | ✅ 是 | 显示实时价格 + "延迟 15 分钟"标识（不可隐藏） |
| **股票详情页** | ✅ 是 | K 线、财报、资讯均来自延迟数据源 |
| **搜索** | ✅ 是 | 支持股票搜索、代码补全 |
| **买入/卖出操作** | ❌ 否 | 点击时弹出登录引导 Sheet（见 § 2.3） |
| **订单管理（Orders）** | ❌ 否 | 显示登录占位页：包含登录按钮 + 文案说明 |
| **持仓（Holdings）** | ❌ 否 | 显示登录占位页 |
| **我的（Profile）** | ❌ 否 | 显示登录占位页 |
| **Watchlist / 自选股** | ⚠️ 有限制 | 可创建本地临时 watchlist，登录后同步到服务器 |
| **消息通知（Push）** | ❌ 否 | 无推送权限 |

### 2.3 登录引导交互

#### 2.3.1 买入/卖出按钮触发

```
用户在股票详情页点击"买入"或"卖出"
  ↓
弹出 Modal：
┌─────────────────────────────────┐
│  登录开户交易账户               │
├─────────────────────────────────┤
│                                 │
│  下单功能需要登录               │
│                                 │
│  [立即登录] [继续浏览]         │
└─────────────────────────────────┘
  ├─ 立即登录：进入 OTP 流程（同时记录来源 referer=stock_detail）
  └─ 继续浏览：关闭 Sheet，返回股票详情页
```

#### 2.3.2 订单/持仓占位页

```
用户切换到"订单"或"持仓" Tab
  ↓
显示占位页：
┌─────────────────────────────────┐
│                                 │
│  登录查看您的订单和持仓         │
│                                 │
│  [立即登录开户]                 │
│                                 │
│  已有账户？点击上方登录         │
│                                 │
└─────────────────────────────────┘
```

#### 2.3.3 登录 Sheet 的参数

当访客用户点击"登录"，跳转至 OTP 流程：

```
流程参数：
  ├─ referer: "guest_mode"（标记来源）
  ├─ return_to: "/quote/AAPL"（登录后返回路径）
  └─ welcome_kyc: true（首次登录后直接进入 KYC）

登录完成后：
  ├─ 关闭 OTP 登录 Sheet
  ├─ 显示"欢迎，请完成身份验证"引导
  └─ 引导进入 KYC 流程（见 mobile-ams-kyc-contract.md）
```

---

## 三、SEC 合规：延迟行情标注

### 3.1 合规要求

**SEC Regulation NMS（National Market System）** 要求：
> 非实时的市场数据（延迟 15 分钟或更多）必须在显著位置清晰标注延迟时间，用户不可以任何形式隐藏或缩小该标注。

### 3.2 设计规范

#### 3.2.1 标注位置与样式

```
┌────────────────────────────────┐
│  AAPL - Apple Inc.             │
│  $195.50 ↑ 2.50 (1.30%)        │
│  📍 延迟 15 分钟                │  ← 红色、粗体、固定显示
│                                │
│  52W 高: $224.99               │
│  52W 低: $134.22               │
└────────────────────────────────┘
```

**样式规范**：
- **颜色**：红色（#FF4444 或 Figma 设计色号）
- **字体**：15pt，粗体（Medium 或 SemiBold）
- **排版**：始终显示在价格区域下方，不允许折叠或删除
- **多语言**：
  - 中文：`延迟 15 分钟`
  - 英文：`Delayed 15 Minutes`
  - 繁体中文：`延遲 15 分鐘`

#### 3.2.2 所有延迟数据的标注范围

| 数据类型 | 标注位置 | 示例 |
|---------|---------|------|
| 实时价格 | 价格区域下方（见 3.2.1） | ✅ 必标注 |
| K 线图数据 | 图表标题右上角 + 悬停提示 | ✅ 必标注 |
| 逐笔成交 | 表格表头标注 | ✅ 必标注 |
| 股票列表（涨跌幅） | 列表右上角统一标注 | ✅ 必标注 |
| 财务数据（PE、市值） | 数据区域顶部 | ✅ 必标注 |
| 市场指数（SandP 500） | 指数价格旁 | ✅ 必标注 |

#### 3.2.3 设计评审清单

在高保真原型审批时，**设计评审必须确认以下项目**：

```
□ 所有延迟行情数据都有"延迟 15 分钟"标注
□ 标注颜色、字体、大小符合合规要求
□ 标注文案清晰明确，用户无法误解
□ 用户不能通过任何方式（按钮、设置、滑动等）隐藏标注
□ 用户不能将标注移出可见区域
□ 访客模式下所有页面均已审核
□ 国际化文案（中英文）已审核
```

**不合规示例**：
- ❌ "Data delayed" —— 应为具体时间（15 分钟）
- ❌ 将标注放在折叠菜单中
- ❌ 使用灰色低对比度字体
- ❌ 标注大小过小（< 12pt）

### 3.3 Market Data Service 协作

**访客行情数据源**：

AMS 需要与 Market Data Service 协商获取延迟 15 分钟的数据源：

```
AMS 接收到访客查询请求
  ├─ request.guest_session_id 存在 → 标记为访客
  ├─ 调用 market_data_service.GetQuote(symbol, delay=15min)
  └─ 返回 15 分钟延迟的价格数据

Market Data Service 职责：
  ├─ 维护两个数据源：实时 + 15分钟延迟
  ├─ 根据请求来源选择合适的数据源
  └─ 确保延迟数据的时间戳正确（last_update_time 准确）
```

---

## 四、数据库设计

### 4.1 `guest_sessions` 表

```sql
CREATE TABLE guest_sessions (
    -- 主键
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    
    -- 会话标识
    guest_session_id VARCHAR(36) UNIQUE NOT NULL,  -- UUID v4
    
    -- 来源信息（审计用，无 PII）
    ip_address VARCHAR(45),                         -- IPv4/IPv6
    user_agent VARCHAR(500),                        -- 客户端 User-Agent
    device_type VARCHAR(20),                        -- ios, android, web
    
    -- 会话状态
    status ENUM('ACTIVE', 'UPGRADED', 'EXPIRED') DEFAULT 'ACTIVE',
    
    -- 关联账户（升级为认证用户后）
    upgraded_account_id VARCHAR(36),                -- FK: accounts.id（可空）
    upgraded_at TIMESTAMP,
    
    -- 访问统计（用于分析访客转化）
    page_views INT DEFAULT 0,                       -- 浏览页面数
    last_activity_time TIMESTAMP,
    
    -- 临时 Watchlist（JSON）
    local_watchlist JSON,                           -- [{"symbol": "AAPL", "name": "Apple"}]
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,                  -- created_at + 7 days
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 索引
    INDEX `idx_guest_session_id` (`guest_session_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='访客会话表（无 PII，内存优先）';

-- 定期清理过期会话（cron job）
-- DELETE FROM guest_sessions WHERE status = 'EXPIRED' AND expires_at < NOW();
```

### 4.2 Redis 会话存储（推荐）

由于访客会话临时性且无 PII，建议用 Redis 替代 MySQL：

```
Redis Key: guest_session:{guest_session_id}
Type: Hash
TTL: 7 days

Fields:
  - ip_address: "192.168.1.100"
  - user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3)"
  - device_type: "ios"
  - page_views: 12
  - last_activity_time: "2026-04-01T10:30:00Z"
  - local_watchlist: [{"symbol": "AAPL"}, ...]
  - created_at: "2026-04-01T03:30:00Z"
```

**优势**：
- 性能更好（内存操作，无磁盘 I/O）
- 自动过期（TTL）
- 无需数据保留义务（非 PII）

---

## 五、核心流程

### 5.1 创建访客会话

```
用户点击"先逛逛"按钮
  ↓
客户端生成 request：
  POST /api/v1/guest/session
  {
    "device_type": "ios",
    "app_version": "1.0.0"
  }
  ↓
后端逻辑：
  ├─ guest_session_id = UUID v4
  ├─ 提取 IP 地址 = X-Forwarded-For header
  ├─ 存储到 Redis（TTL = 7 days）
  ├─ 返回访客会话凭证
  └─ 发布 Kafka 事件：guest.session_created
  ↓
响应：
  {
    "guest_session_id": "uuid-v4",
    "expires_in_days": 7,
    "refresh_token": null
  }
  ↓
客户端：
  ├─ 保存 guest_session_id 到本地存储
  └─ 后续 API 请求添加 header：X-Guest-Session: {guest_session_id}
```

### 5.2 访客数据访问流程

```
客户端发送行情请求：
  GET /api/v1/quotes/AAPL
  Header: X-Guest-Session: uuid-v4

AMS 中间件：
  ├─ 检查 X-Guest-Session header 存在
  ├─ 验证 guest_session_id 在 Redis 中存在且未过期
  ├─ 标记 request.is_guest = true
  └─ 继续处理

处理器：
  ├─ 调用 market_data_service.GetQuote(symbol, delay=15min)
  ├─ 在响应中注入"延迟 15 分钟"元数据
  ├─ 返回延迟数据给客户端
  └─ 异步更新 guest_sessions.page_views++

客户端渲染：
  ├─ 显示行情数据
  ├─ 根据响应元数据显示"延迟 15 分钟"标注
  └─ 此标注不可隐藏（由客户端强制渲染）
```

### 5.3 访客升级为认证用户

```
用户完成 OTP 验证
  ├─ POST /api/v1/auth/otp/verify
  ├─ request.guest_session_id (可选)
  └─ request.phone_number
  ↓
后端逻辑：
  ├─ OTP 验证通过
  ├─ 创建/查询用户账户（account_id）
  ├─ 如果 request 包含 guest_session_id：
  │   ├─ 查询 guest_sessions 表
  │   ├─ 同步 local_watchlist → accounts.watchlist（如有）
  │   ├─ 更新状态：status = UPGRADED
  │   ├─ 记录关联：upgraded_account_id, upgraded_at
  │   └─ 发布 Kafka 事件：guest.upgraded_to_user
  ├─ 创建认证会话（JWT + refresh_token）
  └─ 返回响应
  ↓
客户端：
  ├─ 保存 JWT 和 refresh_token
  ├─ 删除 X-Guest-Session header
  └─ 刷新页面，显示完整 App（行情、订单、持仓等）
```

### 5.4 页面权限检查中间件

```go
// internal/transport/http/middleware/guest_access_control.go
func GuestAccessControlMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        isGuest := isGuestRequest(r)
        
        // 定义访客可访问的路由白名单
        guestAllowedRoutes := []string{
            "/api/v1/quotes",
            "/api/v1/stocks",
            "/api/v1/search",
            "/api/v1/market-data",
        }
        
        // 定义访客禁止访问的路由
        guestRestrictedRoutes := []string{
            "/api/v1/orders",
            "/api/v1/holdings",
            "/api/v1/profile",
            "/api/v1/notifications",
        }
        
        if isGuest {
            for _, restricted := range guestRestrictedRoutes {
                if strings.HasPrefix(r.URL.Path, restricted) {
                    respondError(w, 403, "GUEST_ACCESS_DENIED", 
                        "访客用户无法访问此功能，请登录")
                    return
                }
            }
        }
        
        next.ServeHTTP(w, r)
    })
}
```

---

## 六、Kafka 事件定义

### 6.1 事件列表

| 事件 | Topic | Partition Key | Consumer | SLA |
|------|-------|---------------|----------|-----|
| 访客会话创建 | `guest.session_created` | ip_address | Analytics | 实时 |
| 访客升级为用户 | `guest.upgraded_to_user` | account_id | AuditLog, Analytics | 实时 |
| 访客会话过期 | `guest.session_expired` | guest_session_id | Cleanup | 异步 |

### 6.2 事件 Payload

**事件：guest.session_created**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "GUEST_SESSION_CREATED",
  "timestamp": "2026-04-01T10:30:00.123Z",
  "guest_session_id": "session-uuid-v4",
  "device_type": "ios",
  "app_version": "1.0.0",
  "ip_address": "192.168.1.100",
  "location_country": "CN",
  "correlation_id": "req-abc"
}
```

**事件：guest.upgraded_to_user**

```json
{
  "event_id": "evt-uuid-v4",
  "event_type": "GUEST_UPGRADED_TO_USER",
  "timestamp": "2026-04-01T10:35:00.456Z",
  "guest_session_id": "session-uuid-v4",
  "account_id": "user-123",
  "guest_duration_seconds": 300,      // 访客会话持续时长
  "page_views_as_guest": 12,
  "watchlist_items_synced": 3,
  "correlation_id": "req-xyz"
}
```

---

## 七、与其他模块的协作

### 7.1 与 market-data-service 的协作

AMS 需要与 Market Data 服务协商：

```
AMS 接口：/api/v1/quotes/{symbol}
  ├─ query param: guest_session_id（可选）
  ├─ 若 guest_session_id 存在，调用 market_data_service.GetQuote(symbol, delay=15min)
  └─ 返回延迟数据

Market Data Service 职责：
  ├─ 提供两个数据源的 API
  ├─ 实时数据源：/quotes/realtime/{symbol}
  └─ 15分钟延迟源：/quotes/delayed/{symbol}
```

### 7.2 与 mobile PRD 的对应关系

| Mobile PRD 需求 | 本规范实现 |
|---------------|----------|
| § 4.3 访客模式流程 | ✅ § 5.1-5.4 核心流程 |
| § 6.4 页面权限矩阵 | ✅ § 2.2 页面权限矩阵 |
| § 6.4 延迟数据显示 | ✅ § 3.2 标注设计规范 |
| § 7 SEC 合规要求 | ✅ § 3 SEC 合规 |
| § 8 登录引导 Sheet | ✅ § 2.3 登录引导交互 |

### 7.3 与 auth-architecture.md 的关系

访客模式是 auth-architecture.md 中定义的"无认证访问层"的实现：

```
auth-architecture.md § 概述
  ├─ 认证用户：JWT RS256 + Device Binding
  ├─ 访客用户：Guest Session ID + 临时会话（本规范）
  └─ 公开端点：Health check, 公开市场数据
```

---

## 八、实现指南

### 8.1 Go 服务框架

```go
// internal/domain/guest/guest_session.go
type GuestSession struct {
    ID              int64
    SessionID       string
    IPAddress       string
    DeviceType      string
    Status          GuestSessionStatus
    LocalWatchlist  []WatchlistItem
    PageViews       int
    CreatedAt       time.Time
    ExpiresAt       time.Time
}

type GuestSessionStatus string
const (
    GuestSessionActive  = "ACTIVE"
    GuestSessionUpgraded = "UPGRADED"
    GuestSessionExpired = "EXPIRED"
)

// internal/application/guest/service.go
type GuestService interface {
    CreateSession(ctx context.Context, deviceType string) (*GuestSession, error)
    ValidateSession(ctx context.Context, sessionID string) (*GuestSession, error)
    UpgradeSession(ctx context.Context, sessionID, accountID string) error
}
```

### 8.2 中间件实现

```go
// internal/transport/http/middleware/guest_auth.go
func GuestAuthMiddleware(guestService GuestService) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // 检查 JWT（优先）
            if token := extractBearerToken(r); token != "" {
                // 认证用户路径
                // ...
                next.ServeHTTP(w, r)
                return
            }
            
            // 检查访客会话 ID
            sessionID := r.Header.Get("X-Guest-Session")
            if sessionID == "" {
                // 公开端点或返回 401
                respondError(w, 401, "UNAUTHORIZED", "Missing authentication")
                return
            }
            
            session, err := guestService.ValidateSession(r.Context(), sessionID)
            if err != nil {
                respondError(w, 401, "INVALID_GUEST_SESSION", err.Error())
                return
            }
            
            // 将访客信息注入 context
            ctx := context.WithValue(r.Context(), "guest_session", session)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### 8.3 数据库迁移

```go
// src/migrations/00005_create_guest_sessions_table.sql
-- up

CREATE TABLE guest_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    guest_session_id VARCHAR(36) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    device_type VARCHAR(20),
    status ENUM('ACTIVE', 'UPGRADED', 'EXPIRED') DEFAULT 'ACTIVE',
    upgraded_account_id VARCHAR(36),
    upgraded_at TIMESTAMP,
    page_views INT DEFAULT 0,
    last_activity_time TIMESTAMP,
    local_watchlist JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_guest_session_id` (`guest_session_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- down

DROP TABLE IF EXISTS guest_sessions;
```

---

## 九、测试用例矩阵

| 场景 | 输入 | 预期输出 | 验收标准 |
|------|------|---------|---------|
| 创建访客会话 | 点击"先逛逛" | 返回 guest_session_id | Redis 中 TTL=7d |
| 访客查看行情 | 带 X-Guest-Session | 返回 15 分钟延迟数据 | 价格数据延迟正确 |
| 访客点击买入 | POST /orders | 返回 403 GUEST_ACCESS_DENIED | 弹出登录 Sheet |
| 访客升级为认证用户 | 完成 OTP | status=UPGRADED，关联 account_id | watchlist 同步成功 |
| 访客会话过期 | 7 天后 | status=EXPIRED，无法使用 | Redis key 自动删除 |
| SEC 合规标注 | 在访客模式查看 K 线 | "延迟 15 分钟"标注可见且不可隐藏 | 设计评审签字 |

---

## 十、Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| v1.0 | 2026-04-01 | 初版发布：访客模式、页面权限矩阵、SEC 合规标注、升级流程 |

---

## 参考资料

- `auth-architecture.md` — 认证体系与公开端点定义
- `account-financial-model.md` — 账户类型（访客 vs 正式）
- `kafka-events.md` — 事件驱动架构
- `../../mobile/docs/prd/01-auth.md` — Mobile PRD
- `../../.claude/rules/security-compliance.md` — 数据隐私与安全
