# PRD-08：设置与个人中心模块

> **文档状态**: Phase 1 正式版
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据 Backend/Frontend 工程师评审意见修订：settings 更新接口改为 PATCH + version 乐观锁；新增 GET /v1/users/w8ben/view-url 端点（替代前端直接嵌入 PDF URL）；user_settings 表增加 version 字段

---

## 一、模块概述

### 1.1 功能范围

| 功能区 | 功能项 | Phase 1 | Phase 2 |
|--------|-------|---------|---------|
| 个人中心 | 用户信息展示 | ✅ | - |
| 个人中心 | KYC 等级徽标 | ✅ | - |
| 安全设置 | 生物识别管理 | ✅ | - |
| 安全设置 | 登录设备管理 | ✅ | - |
| 安全设置 | 更改手机号 | ✅ | - |
| 安全设置 | 注销账户 | ✅（带限制条件）| - |
| 通用设置 | 涨跌颜色方案 | ✅ | - |
| 通用设置 | 推送通知管理 | ✅ | - |
| 通用设置 | 语言设置 | Phase 1 仅中文 | ✅ 多语言 |
| 通用设置 | 默认市场 | ✅ | - |
| 交易设置 | 默认订单类型 / TIF | ✅ | - |
| 交易设置 | 确认方式 | ✅ | - |
| 交易设置 | 大额委托阈值 | ✅ | - |
| 交易设置 | 盘前/盘后交易开关 | ✅ | - |
| 个人资料 | 只读 KYC 信息 | ✅ | - |
| 个人资料 | W-8BEN 查看/更新 | ✅ | - |
| 功能入口 | 资金管理 | ✅ | - |
| 功能入口 | 交易确认书 | ❌（Phase 2 占位） | ✅ |
| 功能入口 | 消息通知中心 | ❌（Phase 2 占位）| ✅ |

---

## 二、"我的"主页（Profile Hub）

### 2.1 页面结构

```
[用户卡片]
  头像（可更换）· 姓名 · UID
  KYC 等级徽标：✅ Tier 2 已认证

[资产摘要快捷卡]
  总资产：$XX,XXX.XX
  今日盈亏：+$XXX.XX
  [入金] [出金] 快捷按钮

[功能菜单列表]
  ─── 资金 ────────────────────
  💳  银行卡管理
  📋  交易记录
  📄  交易确认书         [Phase 2] 敬请期待
  ─── 消息 ────────────────────
  🔔  消息通知           [Phase 2] 敬请期待
  ─── 账户 ────────────────────
  👤  个人资料
  🔒  安全设置
  ⚙️  通用设置
  📊  交易设置
  ─── 帮助 ────────────────────
  ❓  帮助中心
  💬  联系客服
  ℹ️  关于我们
  ─────────────────────────────
  🚪  [退出登录] 红色文字
```

---

## 三、个人资料页

### 3.1 展示内容（全部只读）

| 字段 | 显示值 | 脱敏规则 |
|------|-------|---------|
| 姓名 | 张 三（或英文姓名） | 全显 |
| 证件类型 | 居民身份证 | 全显 |
| 证件号码 | 110101****0001 | 中间隐藏 |
| 手机号 | +86 138****8000 | 中间隐藏 |
| 邮箱 | zh***@example.com | 本地部分隐藏 |
| 开户日期 | 2026-03-13 | 全显 |
| 账户类型 | 现金账户 | 全显 |
| KYC 等级 | Tier 2（已认证） | 全显 |
| 账户号码 | GH123456 | 全显 |

### 3.2 税务信息区

| 字段 | 显示值 |
|------|-------|
| 税务状态 | 非美国税务居民 |
| W-8BEN 状态 | 有效（到期：2029-03-13）|
| W-8BEN 操作 | [查看表单] [申请更新]（到期前 90 天激活）|

**W-8BEN 查看**：以内嵌 PDF 查看器展示已签署的 W-8BEN 原件。

### 3.3 修改限制说明

Phase 1 所有 KYC 字段均为只读（注册时经过核实，不可自助修改）。

如需修改，显示：
```
"如需修改个人信息，请联系客服办理" → [联系客服] 按钮
```

---

## 四、安全设置页

### 4.1 生物识别管理

| 元素 | 规格 |
|------|------|
| Face ID 开关 | Toggle，开启 = 下次 OTP 登录后启用生物识别快捷登录 |
| 状态说明 | "开启后，下次登录时可使用 Face ID 替代验证码" |
| 关闭确认 | 弹窗确认关闭，需 OTP 验证 |

**生物识别注册流程**：
- 若已开启：显示"已启用"标签
- 若未开启：显示开启按钮，点击触发系统生物识别权限请求

### 4.2 登录设备管理

**设备列表规格**:

| 字段 | 说明 |
|------|------|
| 设备名称 | 如 iPhone 15 Pro |
| 设备类型图标 | 手机图标 |
| 上次活跃 | 如 "2 小时前" |
| 当前设备标识 | "本机" 蓝色标签 |
| 远程注销 | 非本机设备显示"注销"按钮 |

**远程注销流程**:
```
点击 [注销] → 需要生物识别验证 → 确认注销
    ↓
发送注销指令至服务端
    ↓
目标设备：Token 失效，下次打开 App 时强制重新登录，并推送通知
```

**最大设备数**：3 台并发。

### 4.3 更改手机号

**流程（高敏感操作）**:
```
输入新手机号 → 验证旧手机号 OTP → 验证新手机号 OTP
             ↓
[可选] 生物识别二次确认
             ↓
更新成功 → 推送通知至新旧号码 → 所有设备强制重新登录
```

**限制**：
- 新手机号不可与系统内其他账号重复
- 30 天内只可更改一次

### 4.4 注销账户

**前置条件（所有条件满足才可注销）**:
- 持仓市值 = $0（无持仓）
- 可用现金 = $0（无余额）
- 无待处理出入金申请
- 无未成交委托

**注销流程**:
```
点击 [注销账户] → 显示注意事项弹窗
    ↓
注意事项：
  "注销后，您的账户将被关闭，7 年内数据依法保留，
   您将无法使用相同手机号重新注册。"
  [我确认注销] → 需 OTP 验证 → [最终确认注销]
    ↓
后台操作：
  账户状态 → CLOSED
  所有 Token 失效
  Admin 工作台记录注销原因
  数据保留标记（7 年）
```

---

## 五、通用设置页

### 5.1 涨跌颜色方案

**选项（带实时预览）**:

| 选项 | 涨 | 跌 | 推荐 |
|------|----|----|------|
| 红涨绿跌 | 🔴 | 🟢 | +86 默认 |
| 绿涨红跌 | 🟢 | 🔴 | +852 默认 |

**实现规则**:
- 设置更改后**立即生效**，无需重启
- 全局 App 状态更新，所有行情页同步变更
- 平盘（±0%）始终显示灰色，不受此设置影响

### 5.2 默认市场

| 选项 | 说明 |
|------|------|
| 美股（US） | 行情首页默认展示美股 Tab |
| 港股（HK）| Phase 2 开放 |

Phase 1 默认美股，港股 Tab 不可设为默认。

### 5.3 语言设置

Phase 1：仅中文（简体），不提供切换选项（UI 显示"语言"但标注"目前仅支持中文"）。

### 5.4 推送通知管理

| 类别 | 开关 | 说明 |
|------|------|------|
| 交易通知 | Toggle | 成交、撤单、拒绝、GTC 到期 |
| 资金通知 | Toggle | 入金到账、出金完成、合规审查通知、微存款提醒 |
| 行情提醒 | Phase 2 Toggle | 自选股价格突破（Phase 2） |
| 系统公告 | Toggle | 系统维护、交易时间变更 |
| 安全通知 | **不可关闭** | 新设备登录、账户异常（强制推送） |

### 5.5 其他设置

| 项目 | 功能 |
|------|------|
| 清除缓存 | 清除本地行情缓存、图片缓存（不影响账户数据）|
| App 版本 | 显示当前版本号 + 构建号；有更新时显示"发现新版本" |

---

## 六、交易设置页

（与 PRD-04 交易设置章节保持一致，此处为 UI 呈现规格）

### 6.1 设置项

| 设置项 | 控件类型 | 默认值 | 选项 |
|--------|---------|--------|------|
| 默认订单类型 | Segmented | 限价单 | 市价单 / 限价单 |
| 默认有效期 | Segmented | DAY | DAY / GTC |
| 委托确认方式 | Radio | 滑动+生物识别 | 滑动+生物识别 / 仅滑动 / 限价单免确认 |
| 大额委托阈值 | Segmented | $10,000 | $5K / $10K / $20K |
| 盘前/盘后交易 | Toggle | 关闭 | 开启/关闭（开启需确认风险） |
| 价格偏离警告 | Segmented | 5% | 3% / 5% / 10% |

### 6.2 PDT 教育入口

```
[PDT 规则说明] → 跳转 PDT 规则详情页
  内容：PDT 定义、$25K 最低要求、Day Trade 计数、违规后果
  注意：Phase 1 为现金账户，不受 PDT 限制，仅展示教育内容
```

---

## 七、帮助与支持

### 7.1 帮助中心

Phase 1：静态 FAQ 页面（WebView 或原生）

分类：
- 开户 / KYC 问题
- 出入金问题
- 交易问题
- 账户安全
- 费用说明

### 7.2 联系客服

Phase 1：
- 显示客服邮箱 + 工作时间
- "提交工单"按钮（跳转 Email 客户端预填邮件模板）

Phase 2：
- 在线客服（IM 聊天）
- AI 客服（FAQ 机器人）

---

## 八、后端接口规格

### 8.1 获取用户设置

```
GET /v1/users/settings
Response:
  {
    "color_scheme": "RED_UP" | "GREEN_UP",
    "default_market": "US",
    "language": "zh-CN",
    "notifications": {
      "trade": true,
      "funding": true,
      "market_alert": false,
      "system": true
    },
    "trading": {
      "default_order_type": "LIMIT",
      "default_tif": "DAY",
      "confirm_method": "SLIDE_BIOMETRIC",
      "large_order_threshold": "10000",
      "extended_hours": false,
      "price_deviation_alert": "0.05"
    }
  }
```

### 8.2 更新用户设置

```
PATCH /v1/users/settings
Headers:
  Idempotency-Key: {uuid}   // 防止重复提交（网络重试）
Request:
  {
    "version": 5,            // 乐观锁版本号（从 GET /settings 获取）
    // 仅传需要修改的字段（Partial Update）
    "color_scheme": "GREEN_UP",
    "trading": {
      "default_order_type": "MARKET"
    }
  }

Response 200:
  { "updated": true, "version": 6 }  // 返回新版本号供下次使用

Response 409（版本冲突，说明另一设备已更新设置）:
  {
    "error": "VERSION_CONFLICT",
    "current_version": 7,
    "message": "设置已在其他设备更新，请重新获取后再修改"
  }
```

**客户端处理**：409 时自动重新 GET /settings 获取最新设置和 version，再次发起 PATCH。

### 8.3 W-8BEN 查看 URL（签署原件）

```
GET /v1/users/w8ben/view-url

Response 200:
  {
    "url": "https://s3.amazonaws.com/...",  // Presigned S3 URL，有效期 15 分钟
    "expires_at": "2026-03-13T15:00:00Z",
    "form_date": "2026-03-13",
    "status": "ACTIVE",
    "expiry_date": "2029-03-13"
  }

Response 404（用户未签署 W-8BEN）:
  { "error": "W8BEN_NOT_FOUND" }
```

**前端实现**（Flutter）：
- 获取 URL 后用 `pdfx ^2.9.2`（原生 PDFKit/PdfRenderer）内嵌展示 PDF
- 不使用 WebView（App Store/Play Store 审核风险）
- URL 缓存时间 < 10 分钟（避免过期），通过 url 中 X-Amz-Expires 判断

### 8.4 更改手机号

```
POST /v1/users/phone/change
Request:
  {
    "new_phone": "+8613900139000",
    "old_otp": "123456",
    "new_otp": "654321"
  }
```

### 8.4 提交注销申请

```
POST /v1/users/close-account
Request:
  {
    "otp": "123456",
    "confirmation": "I confirm to close my account"
  }
```

---

## 九、数据模型

```sql
-- 用户设置表
CREATE TABLE user_settings (
    user_id             UUID PRIMARY KEY REFERENCES users(id),
    color_scheme        VARCHAR(20) DEFAULT 'RED_UP',
    language            VARCHAR(10) DEFAULT 'zh-CN',
    default_market      VARCHAR(5) DEFAULT 'US',
    notify_trade        BOOLEAN DEFAULT true,
    notify_funding      BOOLEAN DEFAULT true,
    notify_market       BOOLEAN DEFAULT false,
    notify_system       BOOLEAN DEFAULT true,
    trading_order_type  VARCHAR(10) DEFAULT 'LIMIT',
    trading_tif         VARCHAR(5) DEFAULT 'DAY',
    trading_confirm     VARCHAR(30) DEFAULT 'SLIDE_BIOMETRIC',
    large_order_threshold NUMERIC(18,4) DEFAULT 10000,
    extended_hours      BOOLEAN DEFAULT false,
    price_deviation_pct NUMERIC(5,2) DEFAULT 5.00,
    version             BIGINT NOT NULL DEFAULT 0,    -- 乐观锁：多设备并发更新防覆盖
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 十、验收标准

| 场景 | 标准 |
|------|------|
| 颜色方案切换 | 切换后全局即时生效，无需重启 App |
| 生物识别关闭 | 关闭时需 OTP 验证，不可绕过 |
| 设备注销 | 被注销设备下次打开 App 强制重新登录 |
| 注销账户 | 有持仓/余额时注销按钮应禁用并提示原因 |
| 设置持久化 | 设置保存后，重启 App、换设备登录均保持一致 |
| W-8BEN 到期提醒 | 到期前 90 天推送通知且在个人资料页显示提醒 |
