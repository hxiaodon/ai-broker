# PRD-01：登录与认证模块

> **文档状态**: Phase 1 正式版（技术评审修订版）
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据 Backend、Flutter 工程师技术评审意见修订：修正 Token 存储方案（Native App 不适用 HttpOnly Cookie）、补充 Biometric Challenge 下发接口、修正并发注册竞态、修正 OTP purpose 校验、修正 user_devices 唯一约束、补充 token_version 机制、补充 Android SMS Retriever API 要求

---

## 一、模块概述

### 1.1 功能范围

本模块覆盖用户身份验证的全生命周期：

- 手机号 + OTP 登录（Phase 1 唯一登录方式）
- 生物识别快捷登录（Face ID / 指纹）
- 访客模式（延迟行情浏览）
- 设备管理（最多 3 台并发）
- Token 管理与会话安全

### 1.2 Phase 1 范围边界

| 功能 | Phase 1 | Phase 2 |
|------|---------|---------|
| 手机号 + OTP | ✅ | - |
| 生物识别登录 | ✅ 首次 OTP 后设置 | - |
| 访客模式 | ✅ | - |
| 设备管理 | ✅ | - |
| 邮箱 + 密码登录 | ❌ | ✅ |
| 找回密码 | ❌（Phase 1 无密码概念） | ✅ |

---

## 二、用户流程

### 2.1 主流程：首次登录 / 注册

```
冷启动页 → 输入手机号 → 发送 OTP → 验证 OTP
         ↓
    [新用户] → 自动创建账号 → 进入 KYC 流程（见 PRD-02）
    [已注册用户]
         ↓
    [KYC 已通过] → 进入首页（行情页）
    [KYC 审核中] → 进入 KYC 状态页
    [KYC 未开始] → 进入 KYC 流程
```

### 2.2 生物识别登录流程

```
冷启动页 → Face ID 图标（已注册设备）→ 生物识别验证
         ↓
    [验证通过] → 获取新 Access Token → 进入 App
    [验证失败（3 次）] → 降级至 OTP 登录
    [生物识别未注册] → 不显示该入口
```

### 2.3 访客模式流程

```
冷启动页 → "先逛逛" 链接 → 进入行情页（15 分钟延迟标识）
         ↓
    行情/详情页：正常浏览（延迟数据）
    订单/持仓/我的：显示登录占位页 + 登录按钮
    点击买/卖：底部弹出登录引导 Sheet
```

### 2.4 设备管理流程

```
我的 → 安全设置 → 登录设备管理
→ 列表显示最多 3 台设备（设备名、登录时间、最后活跃）
→ 当前设备标注 "本机"
→ 远程注销其他设备：需生物识别确认
→ 新设备登录时：若超过 3 台，踢出最老设备并推送通知
```

---

## 三、页面设计规格

### 3.1 冷启动页

| 元素 | 规格 |
|------|------|
| Logo / 品牌名 | 顶部居中，"环球通"品牌 |
| 主按钮 | "手机号登录" — 主色调，全宽 |
| 次级入口 | "注册" — 文字按钮 |
| 访客入口 | "先逛逛" — 小字链接，底部 |
| 法律链接 | 用户协议 / 隐私政策，最底部 |

### 3.2 手机号输入页

| 元素 | 规格 |
|------|------|
| 国家代码选择器 | Phase 1：+86（中国大陆）/ +852（香港）下拉 |
| 手机号输入 | tel 类型，最大 15 位，实时格式校验 |
| 发送验证码按钮 | 点击后禁用并显示 60 秒倒计时 |
| 服务条款提示 | "登录即代表同意《用户协议》和《隐私政策》" |

### 3.3 OTP 输入页

| 元素 | 规格 |
|------|------|
| OTP 输入框 | 6 位独立格子，数字键盘，等宽字体 |
| 倒计时重发 | 60 秒后可重发，重发上限 5 次/小时 |
| 自动填充 | iOS: `AutofillHints.oneTimeCode`（Flutter TextField，底层 UITextField，无需额外实现）；**Android: `smart_auth ^3.2.0`（SMS Retriever API / SMS User Consent），禁止使用 `READ_SMS` 权限（Google Play 拒绝）** |
| 错误提示 | 验证码错误：内联提示；5 次错误：锁定 30 分钟 |

### 3.4 生物识别设置页（首次 OTP 登录后弹出）

| 元素 | 规格 |
|------|------|
| 触发时机 | 首次 OTP 登录成功后，若设备支持生物识别则弹出 |
| 设置按钮 | "开启 Face ID / 指纹" — 主按钮 |
| 跳过按钮 | "以后再说" — 文字按钮 |
| 重新提示时机 | 跳过后，下次 OTP 登录时再次提示（最多 3 次） |

---

## 四、后端接口规格

### 4.1 发送 OTP

```
POST /v1/auth/otp/send
Request:
  {
    "phone": "+8613800138000",
    "purpose": "login" | "register"
  }
Response:
  {
    "request_id": "uuid",
    "expires_in": 300,
    "resend_available_at": "2026-03-13T09:00:00Z"
  }
```

**业务规则**:
- 同一手机号 60 秒内只能发送 1 次
- 1 小时内最多发送 5 次
- 超限后返回 429，并告知解锁时间

### 4.2 验证 OTP / 登录

```
POST /v1/auth/otp/verify
Request:
  {
    "phone": "+8613800138000",
    "otp": "123456",
    "request_id": "uuid",
    "device_id": "device-uuid",
    "device_name": "iPhone 15 Pro",
    "device_platform": "iOS"
  }
Response:
  {
    "access_token": "JWT",
    "refresh_token": "opaque-token",
    "expires_in": 900,
    "user_id": "usr-xxx",
    "is_new_user": true | false,
    "kyc_status": "NOT_STARTED" | "IN_PROGRESS" | "PENDING_REVIEW" | "APPROVED" | "REJECTED"
  }
```

**业务规则**:
- 连续 5 次错误：账号锁定 30 分钟
- Access Token 有效期：15 分钟（JWT RS256）
- Refresh Token 有效期：7 天（HttpOnly Secure Cookie）
- 同一设备登录不同账号：旧会话失效

### 4.3 刷新 Token

```
POST /v1/auth/token/refresh
Request: Bearer {refresh_token}（从 flutter_secure_storage 读取，放 Authorization Header）
Response:
  {
    "access_token": "新 JWT",
    "refresh_token": "新 Refresh Token",  // 旧 Token 原子消费后颁发
    "expires_in": 900
  }
```

**业务规则**:
- Refresh Token 单次使用制（使用 Redis Lua 脚本原子消费，防止并发竞态）
- 检测到二次使用 → 视为重放攻击 → 吊销所有 Token → 推送安全警告
- **[v1.1 修订]** 不再使用 HttpOnly Cookie，Refresh Token 以 Bearer Token 形式在请求体传递

### 4.4 生物识别 Challenge 下发（新增）

> **[v1.1 新增]** P0-Auth-04 修复：补充 Challenge 下发接口。

```
POST /v1/auth/biometric/challenge
Request:
  {
    "device_id": "uuid",
    "key_id": "key-uuid"
  }
Response:
  {
    "challenge": "base64(random_32_bytes)",
    "expires_in": 30
  }
```

**服务端处理**:
- 生成 32 字节随机数，Base64 编码
- Redis 存储 `biometric_challenge:{challenge_hash}` → `device_id`，TTL=30s
- 同一 device_id 并发 Challenge 请求：旧 Challenge 作废，颁发新 Challenge

### 4.5 生物识别密钥注册

```
POST /v1/auth/biometric/register
Request:
  {
    "device_id": "uuid",
    "public_key": "base64-encoded-public-key",  // 设备 Keystore/Keychain 生成
    "attestation": "..."
  }
Response:
  {
    "key_id": "key-uuid"
  }
```

### 4.6 生物识别登录

```
POST /v1/auth/biometric/login
Request:
  {
    "device_id": "uuid",
    "key_id": "key-uuid",
    "signature": "base64-signed-challenge",
    "challenge": "server-issued-challenge"   // 必须先调用 4.4 获取
  }
Response: 同 4.2 登录响应
```

### 4.6 登出

```
POST /v1/auth/logout
Request:
  {
    "device_id": "uuid"
  }
```

**业务规则**:
- 将当前 Access Token 加入 Redis 黑名单
- 清除设备对应的 Refresh Token

### 4.7 设备列表

```
GET /v1/auth/devices
Response:
  {
    "devices": [
      {
        "device_id": "uuid",
        "device_name": "iPhone 15 Pro",
        "platform": "iOS",
        "login_at": "ISO8601",
        "last_active_at": "ISO8601",
        "is_current": true
      }
    ]
  }
```

### 4.8 远程注销设备

```
DELETE /v1/auth/devices/{device_id}
Request Header: X-Biometric-Signature（生物识别签名验证）
```

---

## 五、安全规格

### 5.1 Token 安全

> **[v1.1 修订]** Refresh Token 存储方案从 HttpOnly Cookie 更改为 Native 安全存储。理由：HttpOnly Cookie 是 Web 安全最佳实践，但 Native App 中 `WKWebView`/`WebView` 独立 Cookie 存储，`Ktor HttpCookies` 插件无 Keychain/Keystore 集成，HttpOnly Cookie 在 Native App 中无安全语义。

| 项目 | 规格 |
|------|------|
| Access Token 算法 | JWT RS256（非对称签名） |
| Access Token 有效期 | 15 分钟 |
| Refresh Token 类型 | 不透明随机字符串（256 bit entropy） |
| **Refresh Token 存储（Native App）** | **iOS: Keychain（`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`）；Android: EncryptedSharedPreferences；Flutter: `flutter_secure_storage ^10.0.0`** |
| Token 绑定 | Device ID + IP Range（/24 掩码） |
| Token 黑名单 | Redis，TTL = Token 剩余有效期 |
| **token_version（新增）** | **`users` 表增加 `token_version INTEGER NOT NULL DEFAULT 0`，JWT payload 携带此值；手机号变更、密码重置时 +1，服务端验证 JWT 时额外校验（Redis 缓存，避免每次查 DB）** |

**[v1.1 新增] Refresh Token 轮换原子性（P0-Auth-03 修复）**

使用 Redis Lua 脚本原子消费 Refresh Token，防止多端并发刷新竞态：

```lua
-- Redis Lua 脚本：原子检查-标记-颁发
local val = redis.call('GET', KEYS[1])
if val == false then return {0, ''} end        -- Token 不存在
if val == 'consumed' then return {-1, ''} end  -- Token 已消费（视为重放攻击）
redis.call('SET', KEYS[1], 'consumed', 'EX', 300)
return {1, val}
```

检测到 Refresh Token 二次使用 → 视为 Token 重放攻击 → 吊销该账户所有 Refresh Token → 推送安全警告。

### 5.2 生物识别安全

> **[v1.1 新增]** 补充 Biometric Challenge 下发接口（P0-Auth-04 修复）；补充 Android `KeyPermanentlyInvalidatedException` 处理。

| 项目 | 规格 |
|------|------|
| iOS | LAContext，`.biometryCurrentSet` 策略（生物识别变更后自动失效） |
| Android | BiometricPrompt，`BIOMETRIC_STRONG` 级别；捕获 `KeyPermanentlyInvalidatedException`（指纹变更后删除旧密钥，引导用户重新注册生物识别） |
| 密钥存储 | iOS Keychain（kSecAttrAccessibleWhenUnlockedThisDeviceOnly）；Android Keystore（StrongBox 优先） |
| **Challenge 流程（新增）** | **客户端先调用 `POST /v1/auth/biometric/challenge` 获取服务端 Challenge；服务端 Redis 存储 `challenge → device_id`，TTL=30s，单次有效；签名验证时通过 challenge 查绑定 device_id，不一致则拒绝** |
| Flutter 实现 | `local_auth ^3.0.1`；Secure Enclave 密钥签名通过 Method Channel → `core/auth/biometric_key_manager.dart` |

### 5.3 OTP 安全

| 项目 | 规格 |
|------|------|
| OTP 长度 | 6 位数字 |
| OTP 有效期 | 5 分钟 |
| 错误上限 | 5 次/请求，超限锁定 30 分钟 |
| 发送频率 | 60 秒冷却，5 次/小时 |
| **purpose 绑定（新增）** | **OTP Redis value 包含 `purpose` 字段，验证时校验 purpose 一致性（防止 login OTP 被复用于 phone_change 场景）** |
| 存储 | Redis，OTP 哈希存储（HMAC-SHA256）；验证成功后立即删除 |

**OTP purpose 枚举值**:

| purpose 值 | 使用场景 |
|-----------|---------|
| `login` | 手机号 OTP 登录 |
| `register` | 注册（与 login 合并，由 is_new_user 区分） |
| `phone_change_old` | 更换手机号 — 验证旧号 |
| `phone_change_new` | 更换手机号 — 验证新号 |
| `account_close` | 注销账户确认 |

### 5.4 设备管理安全

| 项目 | 规格 |
|------|------|
| 最大并发设备 | 3 台 |
| 超限策略 | 踢出最早登录设备 + 推送通知 |
| 远程注销 | 需在当前设备完成生物识别验证 |
| 设备指纹 | 包含：OS 版本、设备型号、App 版本（不使用 IDFA/GAID） |

---

## 六、访客模式规格

| 页面 | 访客可用 | 访客限制 |
|------|---------|---------|
| 行情页 | ✅ 全功能（延迟 15 分钟） | 价格显示"延迟"徽标 |
| 股票详情页 | ✅ 查看（延迟数据） | 买/卖按钮替换为登录引导 |
| 搜索 | ✅ 可搜索 | 结果点击跳转详情（访客模式） |
| 订单页 | ❌ | 显示登录占位页 + "立即登录" 按钮 |
| 持仓页 | ❌ | 显示登录占位页 + "立即登录" 按钮 |
| 我的 | ❌ | 显示登录占位页 + "立即登录" 按钮 |
| 底部 Tab | 全部可见 | 订单/持仓/我的 Tab 点击触发登录引导 |

**SEC 合规要求**: 延迟数据必须在显著位置标注"Delayed 15 minutes"，不可省略。

---

## 七、错误处理

| 错误场景 | 用户提示 | 操作 |
|---------|---------|------|
| OTP 发送失败（网络） | "验证码发送失败，请重试" | 30 秒后可重发 |
| OTP 超时（5 分钟） | "验证码已过期，请重新获取" | 清空输入框 |
| OTP 错误 | "验证码不正确，请重试（剩余 N 次）" | 剩余 1 次时加重提示 |
| 账号锁定 | "登录失败次数过多，请 30 分钟后重试" | 不提供解锁入口 |
| 生物识别失败 | "验证失败，请使用验证码登录" | 降级至 OTP |
| 网络断开 | 顶部 Banner："连接已断开，正在重试..." | 自动重连 |
| 设备超限 | 推送通知："您已在新设备登录，旧设备已退出" | - |

---

## 八、推送通知（认证相关）

| 事件 | 推送内容 | 优先级 |
|------|---------|--------|
| 新设备登录 | "您的账号已在新设备登录，若非本人操作请立即联系客服" | HIGH |
| 设备被远程注销 | "您的账号已在另一台设备注销当前设备" | HIGH |
| 账号被锁定 | "多次登录失败，账号已暂时锁定 30 分钟" | NORMAL |

---

## 九、数据模型

```sql
-- 用户表（v1.1 新增 token_version）
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone           VARCHAR(20) UNIQUE NOT NULL,
    country_code    VARCHAR(5) NOT NULL,  -- '+86', '+852'
    kyc_status      VARCHAR(20) NOT NULL DEFAULT 'NOT_STARTED',
    kyc_tier        SMALLINT NOT NULL DEFAULT 0,
    token_version   INTEGER NOT NULL DEFAULT 0,  -- [v1.1 新增] 手机号变更时 +1，JWT 校验此版本
    closed_at       TIMESTAMP WITH TIME ZONE,    -- [v1.1 新增] 注销账户时间
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 注册并发竞态处理（v1.1 说明）
-- INSERT INTO users ... ON CONFLICT (phone) DO NOTHING RETURNING id
-- 若 RETURNING 无结果，走已存在用户的登录路径，避免 TOCTOU 竞态（P0-Auth-05 修复）

-- 设备表（v1.1 修正：device_id 改为用户级唯一约束）
CREATE TABLE user_devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    device_id       VARCHAR(64) NOT NULL,         -- [v1.1 修正] 移除全局 UNIQUE，改为复合唯一
    device_name     VARCHAR(100),
    platform        VARCHAR(10),  -- 'iOS', 'Android', 'Flutter'
    biometric_key_id UUID,
    last_login_at   TIMESTAMP WITH TIME ZONE,
    last_active_at  TIMESTAMP WITH TIME ZONE,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_user_device UNIQUE (user_id, device_id)  -- [v1.1 修正] 用户级唯一
);
-- 重新登录处理：INSERT ... ON CONFLICT (user_id, device_id) DO UPDATE SET last_login_at = NOW(), is_active = true

-- 生物识别密钥表
CREATE TABLE biometric_keys (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    device_id   VARCHAR(64) NOT NULL,
    public_key  TEXT NOT NULL,   -- Base64 encoded
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at  TIMESTAMP WITH TIME ZONE
);

-- OTP 记录（Redis 实现，此为逻辑结构）
-- Key: otp:{phone}:{request_id}
-- Value: hashed_otp, expires_in: 300s

-- 审计日志
CREATE TABLE auth_audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id),
    event_type      VARCHAR(50) NOT NULL,  -- 'LOGIN', 'LOGOUT', 'OTP_SENT', 'OTP_FAILED', 'BIOMETRIC_LOGIN'
    device_id       VARCHAR(64),
    ip_address      INET,
    success         BOOLEAN,
    details         JSONB,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 十、验收标准

| 测试场景 | 验收标准 |
|---------|---------|
| OTP 发送 | < 10 秒内送达 |
| 登录流程 | 冷启动到首页 < 3 步操作 |
| 生物识别登录 | < 2 秒完成认证 |
| Token 刷新 | 用户无感知，背景自动完成 |
| 设备超限 | 新设备登录后旧设备立即收到推送 |
| 访客延迟标识 | 所有行情数据旁显示"延迟 15 分钟"标识 |
| 错误处理 | 所有错误有明确用户提示，无白屏或静默失败 |
