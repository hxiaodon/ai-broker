# PRD-09：Admin 管理后台

> **文档状态**: Phase 1 正式版
> **版本**: v1.0
> **日期**: 2026-03-13
> **负责模块**: Frontend（React Admin Panel）+ Backend（Admin API 端点）

---

## 一、模块概述

Admin 后台（管理运营平台）是供内部运营人员、合规专员、KYC 审核员使用的 Web 管理系统。它通过独立域名（如 `admin.brokerage.com`）访问，与用户端 App 完全隔离。

### 1.1 功能模块

| 模块 | 说明 | Phase 1 |
|------|------|---------|
| KYC 审核工作台 | 审核用户 KYC 申请，支持通过/拒绝/补件 | ✅ |
| 出金审批队列 | 三级出金审批工作流 | ✅ |
| 用户管理 | 查看/搜索用户信息，账户状态管理 | ✅ |
| 订单监控 | 跨用户全局订单实时监控 | ✅ |
| 热门股管理 | 维护首页热门股票榜单 | ✅ |
| 系统仪表盘 | 业务 KPI 概览：注册数、交易量、入金量等 | ✅ |
| SAR 管理 | 可疑交易报告的创建、跟踪、归档 | ✅ |
| Admin 权限管理 | Admin 用户管理、RBAC 角色分配 | ✅ |
| 通知广播 | 向用户发送系统公告（Phase 2 扩展） | ❌ Phase 2 |
| A/B 实验配置 | 功能开关、灰度实验 | ❌ Phase 2 |

### 1.2 访问角色（RBAC）

| 角色 | 权限范围 |
|------|---------|
| KYC Reviewer | 查看 KYC 申请；通过/拒绝/请求补件 |
| Senior KYC Reviewer | KYC Reviewer + 复审补件；升级合规 |
| Compliance Officer | 全部 KYC 权限 + SAR 创建/归档 + 查看 AML 报告 |
| Withdrawal Approver | 查看出金队列；L1 审批（通过/驳回/升级） |
| Senior Withdrawal Approver | Withdrawal Approver + L2 审批 |
| Order Monitor | 只读订单监控；不可操作 |
| Hot List Manager | 热门股管理 |
| System Admin | 全部功能 + Admin 用户/角色管理 |

---

## 二、Admin 认证与安全

### 2.1 登录方式

```
POST /admin/v1/auth/login
Request:
  {
    "email": "reviewer@brokerage.com",
    "password": "...",
    "totp_code": "123456"   // 强制启用 TOTP 二因素认证（Google Authenticator 等）
  }
Response:
  {
    "access_token": "...",    // 有效期 8 小时（工作日时长）
    "admin_id": "adm-uuid",
    "role": "KYC_REVIEWER",
    "permissions": ["kyc:read", "kyc:review"]
  }
```

**安全要求**：
- TOTP 二因素认证强制开启，无法禁用
- 所有 Admin API 请求必须携带 `X-Admin-Session` header
- Session 绑定 IP（变更 IP 需重新登录）
- 完整操作审计日志（见 Section 2.2）

### 2.2 操作审计日志

所有 Admin 操作自动记录到 `admin_audit_logs` 表：

```sql
CREATE TABLE admin_audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id        UUID NOT NULL,
    admin_email     VARCHAR(200) NOT NULL,  -- 冗余记录（防 admin 账号删除后失去溯源）
    action          VARCHAR(100) NOT NULL,   -- 'KYC_APPROVE', 'WITHDRAWAL_REJECT' 等
    target_type     VARCHAR(30) NOT NULL,    -- 'KYC_APPLICATION', 'WITHDRAWAL', 'USER' 等
    target_id       UUID NOT NULL,
    details         JSONB,                   -- 操作前后状态快照
    ip_address      INET NOT NULL,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 禁止 UPDATE/DELETE
);

CREATE INDEX idx_admin_audit_admin ON admin_audit_logs (admin_id, created_at DESC);
CREATE INDEX idx_admin_audit_target ON admin_audit_logs (target_type, target_id);
```

---

## 三、KYC 审核工作台

### 3.1 KYC 审核队列

```
GET /admin/v1/kyc/applications
Query Params:
  status=PENDING_REVIEW | UNDER_REVIEW | APPROVED | REJECTED | PENDING_SUPPLEMENT
  page=1&page_size=20
  search={phone|name|user_id}
  date_from, date_to
  sort=submitted_at:desc

Response:
  {
    "applications": [
      {
        "id": "kyc-uuid",
        "user_id": "user-uuid",
        "user_name": "Zhang San",
        "user_phone": "+1****5678",      // 脱敏
        "status": "PENDING_REVIEW",
        "submitted_at": "2026-03-13T10:00:00Z",
        "waiting_hours": 2.5,
        "sla_breached": false            // 超过 24h 未审核则 true（红色高亮）
      }
    ],
    "total": 150,
    "pending_count": 45
  }
```

### 3.2 KYC 申请详情

```
GET /admin/v1/kyc/applications/{application_id}
Response:
  {
    "application_id": "...",
    "user_id": "...",
    "status": "PENDING_REVIEW",
    "personal_info": { "first_name": "Zhang", "last_name": "San", "nationality": "CN", "dob": "1990-01-01", ... },
    "documents": [
      {
        "type": "PASSPORT",
        "side": "FRONT",
        "url": "https://s3.../presigned_url",  // Presigned URL，有效 15 分钟
        "ocr_result": { "name": "ZHANG SAN", "confidence": 0.98 }
      }
    ],
    "risk_assessment": { "computed_risk_level": "LOW" },
    "aml_check": { "status": "PASS", "checked_at": "..." },
    "reviewer_notes": "...",
    "history": [...]   // 状态变更历史
  }
```

### 3.3 KYC 审核操作

```
POST /admin/v1/kyc/applications/{application_id}/approve
Headers: X-Admin-Session: {token}
Request: { "notes": "所有材料核实无误" }
Response: { "status": "APPROVED", "approved_at": "..." }

POST /admin/v1/kyc/applications/{application_id}/reject
Request:
  {
    "rejection_reason": "DOCUMENT_MISMATCH",   // 标准化原因码
    "notes": "护照名字与申请人姓名不符",
    "notify_user": true                          // 是否触发推送通知
  }
Response: { "status": "REJECTED" }

POST /admin/v1/kyc/applications/{application_id}/request-supplement
Request:
  {
    "required_items": ["PASSPORT_BACK", "PROOF_OF_ADDRESS"],
    "message": "请补充护照背面照片和地址证明",
    "deadline_days": 7
  }
Response: { "status": "PENDING_SUPPLEMENT", "deadline": "2026-03-20" }
```

**拒绝原因标准码**：

| 原因码 | 用户可见文案 |
|--------|------------|
| DOCUMENT_MISMATCH | 提供的证件信息与申请信息不符 |
| DOCUMENT_EXPIRED | 提供的证件已过期 |
| IMAGE_QUALITY_POOR | 证件图片不清晰，无法核验 |
| AML_BLOCKED | 账户暂无法开通，请联系客服 |
| DUPLICATE_IDENTITY | 该身份信息已被注册，请联系客服 |
| UNSUPPORTED_NATIONALITY | 目前暂不支持该国籍用户开户 |

---

## 四、出金审批

### 4.1 出金审批队列

```
GET /admin/v1/withdrawals/pending
Query Params:
  review_level=1|2|3
  page=1&page_size=20
  sort=created_at:asc

Response:
  {
    "withdrawals": [
      {
        "withdrawal_id": "wdr-uuid",
        "user_id": "user-uuid",
        "user_name": "Zhang San",
        "amount": "50001.00",
        "currency": "USD",
        "method": "ACH",
        "bank_last4": "1234",
        "bank_name": "JPMorgan Chase",
        "status": "COMPLIANCE_REVIEW",
        "review_level": 1,
        "trigger_reasons": ["AMOUNT_EXCEEDS_50K"],
        "aml_result": "PASS",
        "submitted_at": "2026-03-13T09:00:00Z",
        "sla_hours": 24,
        "hours_waiting": 6.5
      }
    ],
    "total": 12
  }
```

### 4.2 出金审批操作

```
POST /admin/v1/withdrawals/{withdrawal_id}/approve
Request: { "notes": "核实无误，批准放行" }
Response: { "status": "APPROVED", "next_action": "BANK_PROCESSING" }

POST /admin/v1/withdrawals/{withdrawal_id}/reject
Request:
  {
    "reason": "AML_CONCERN",
    "notes": "交易模式异常，拒绝本次提现",
    "notify_user": true
  }
Response: { "status": "REJECTED", "funds_released": true }
// 拒绝后资金自动解冻返回用户账户

POST /admin/v1/withdrawals/{withdrawal_id}/escalate
Request:
  {
    "target_level": 2,
    "notes": "金额较大，需高级审批"
  }
Response: { "review_level": 2 }
```

---

## 五、用户管理

### 5.1 用户查询

```
GET /admin/v1/users
Query Params:
  search={phone|name|user_id|email}
  kyc_status=APPROVED|REJECTED|PENDING_REVIEW
  account_status=ACTIVE|SUSPENDED|CLOSED
  page=1&page_size=20

Response:
  {
    "users": [
      {
        "user_id": "user-uuid",
        "phone": "+1****5678",          // 脱敏
        "name": "Zhang San",
        "kyc_status": "APPROVED",
        "kyc_tier": 2,
        "account_status": "ACTIVE",
        "registered_at": "2026-01-01T00:00:00Z",
        "last_login_at": "2026-03-13T09:00:00Z",
        "total_assets_usd": "15000.00"
      }
    ],
    "total": 10000
  }
```

### 5.2 用户详情与操作

```
GET /admin/v1/users/{user_id}
Response: 完整用户信息（含 KYC、账户余额、持仓摘要、最近订单、设备列表）

POST /admin/v1/users/{user_id}/suspend
Request: { "reason": "COMPLIANCE_INVESTIGATION", "notes": "..." }
// 暂停：禁止交易 + 禁止出入金；已有委托不自动撤销（需人工处理）

POST /admin/v1/users/{user_id}/unsuspend
Request: { "notes": "调查结束，恢复正常" }

POST /admin/v1/users/{user_id}/force-logout
// 踢出所有设备（清除 token_version，使所有 JWT 立即失效）
```

---

## 六、订单监控

### 6.1 全局订单实时监控

```
GET /admin/v1/orders
Query Params:
  user_id=          // 按用户过滤（可选）
  symbol=           // 按股票代码过滤
  status=PENDING_FILL|PARTIAL_FILL|FILLED|REJECTED
  side=BUY|SELL
  date_from, date_to
  page=1&page_size=50

Response:
  {
    "orders": [
      {
        "order_id": "ord-uuid",
        "user_id": "user-uuid",
        "user_name": "Zhang San",
        "symbol": "AAPL",
        "side": "BUY",
        "order_type": "LIMIT",
        "quantity": 100,
        "limit_price": "182.52",
        "status": "PENDING_FILL",
        "created_at": "2026-03-13T09:30:00Z"
      }
    ],
    "total": 5000
  }
```

**注**：Order Monitor 角色仅有只读权限，不可执行撤单等操作。

---

## 七、热门股管理

### 7.1 热门股列表维护

```
GET /admin/v1/market/hot-list
Response:
  {
    "items": [
      { "rank": 1, "symbol": "AAPL", "name": "Apple Inc.", "market": "US", "added_at": "..." }
    ]
  }

PUT /admin/v1/market/hot-list
// 全量替换热门股列表（保证排名顺序）
Request:
  {
    "items": [
      { "rank": 1, "symbol": "NVDA" },
      { "rank": 2, "symbol": "AAPL" },
      ...
    ]
  }
Response: { "updated": true, "count": 20 }
```

---

## 八、SAR 管理

### 8.1 SAR 数据模型

```sql
CREATE TABLE sar_filings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    created_by          UUID NOT NULL,      -- admin_id
    status              VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
                        -- DRAFT | UNDER_REVIEW | SUBMITTED | ARCHIVED
    suspicious_activity TEXT NOT NULL,      -- 可疑行为描述
    transaction_ids     UUID[] NOT NULL,    -- 关联交易 ID 数组
    amount_total        NUMERIC(18,4),      -- 可疑交易总额
    currency            VARCHAR(5) DEFAULT 'USD',
    fincen_tracking_id  VARCHAR(100),       -- FinCEN/JFIU 受理号（提交后填写）
    submitted_at        TIMESTAMPTZ,        -- 提交给监管机构的时间
    deadline_at         TIMESTAMPTZ NOT NULL, -- 法定申报截止（发现后 30 天）
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 8.2 SAR API

```
GET /admin/v1/compliance/sars
Query Params: status=DRAFT|SUBMITTED page=1&page_size=20

POST /admin/v1/compliance/sars
Headers: X-Admin-Session: {token}   // 需 Compliance Officer 角色
Request:
  {
    "user_id": "user-uuid",
    "suspicious_activity": "用户在 24 小时内频繁小额入金后迅速出金，疑似洗钱",
    "transaction_ids": ["dep-uuid-1", "wdr-uuid-1"],
    "amount_total": "9800.00"
  }

PUT /admin/v1/compliance/sars/{sar_id}
// 更新 SAR 内容，状态流转

POST /admin/v1/compliance/sars/{sar_id}/submit
// 标记为已向 FinCEN/JFIU 提交，记录 fincen_tracking_id
```

**注意**：SAR 信息绝对不能暴露给被调查用户（法律禁止）。所有 SAR API 端点仅 Compliance Officer 可访问，审计日志完整记录。

---

## 九、系统仪表盘

### 9.1 KPI 概览 API

```
GET /admin/v1/dashboard/overview
Query Params: date=2026-03-13  // 默认今日

Response:
  {
    "registrations_today": 150,
    "kyc_submissions_today": 80,
    "kyc_pending_review": 45,
    "kyc_avg_review_hours": 3.2,
    "deposits_today_usd": "500000.00",
    "withdrawals_today_usd": "120000.00",
    "orders_today": 3500,
    "trading_volume_usd": "8500000.00",
    "active_users_today": 620,
    "compliance_alerts": 3    // 待处理 AML/SAR 警报
  }
```

---

## 十、Admin 用户与角色管理

### 10.1 Admin 用户管理（System Admin 角色专属）

```
GET    /admin/v1/admin-users
POST   /admin/v1/admin-users         // 创建 Admin 账号
PATCH  /admin/v1/admin-users/{id}    // 修改角色/状态
DELETE /admin/v1/admin-users/{id}    // 停用账号（软删除）

POST /admin/v1/admin-users/{id}/reset-totp  // 重置 TOTP（如丢失设备）
```

### 10.2 Admin 数据模型

```sql
CREATE TABLE admin_users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(200) UNIQUE NOT NULL,
    name        VARCHAR(100) NOT NULL,
    role        VARCHAR(50) NOT NULL,    -- 见 Section 1.2
    totp_secret VARCHAR(200),           -- AES-256-GCM 加密存储
    status      VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE | INACTIVE
    last_login_at TIMESTAMPTZ,
    last_login_ip INET,
    created_by  UUID,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 十一、验收标准

| 场景 | 标准 |
|------|------|
| TOTP 强制 | 未绑定 TOTP 无法登录，无法绕过 |
| KYC SLA | 超 24h 未处理自动红色高亮 + 发送内部邮件提醒 |
| 出金 SLA | 超 24h 未审批自动告警，超 48h 通知 System Admin |
| 权限隔离 | KYC Reviewer 无法访问出金审批队列（API 级别 403） |
| SAR 保密 | SAR 相关 API 不在用户端有任何入口 |
| 操作审计 | 100% Admin 操作写入 admin_audit_logs，不可删除 |
| 图片访问 | KYC 图片 Presigned URL 有效期 15 分钟，过期后需重新获取 |
| 搜索响应 | 用户/订单搜索 < 1 秒返回结果 |
