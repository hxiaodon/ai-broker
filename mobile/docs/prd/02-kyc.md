# PRD-02：KYC / 开户模块

> **文档状态**: Phase 1 正式版（技术评审修订版）
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据 Backend、Frontend（WebView）、Flutter 评审意见修订：修正 KYC 进度保存幂等性（PATCH + Idempotency-Key）、补充 KYC 提交完整性校验（步骤位图）、补充 W-8BEN 到期触发机制和 is_current 约束、补充财务状况/投资评估独立数据表、补充 Admin KYC API（见 PRD-09）、补充服务端风险披露已读验证、补充 flutter_secure_storage 图片安全上传、移除 OCR 高亮对比功能（无 bounding box 坐标，不可实现）

---

## 一、模块概述

### 1.1 功能范围

KYC（Know Your Customer）是用户从注册到真实交易的必要流程，包含：

- 7 步在线开户（个人信息 → 文件上传 → 财务状况 → 投资评估 → 税务申报 → 风险披露 → 协议签署）
- OCR 自动识别证件
- W-8BEN / W-9 税务表格
- KYC 审核状态追踪
- Admin Panel KYC 审核工作台

### 1.2 监管依据

| 监管要求 | 适用规定 |
|---------|---------|
| 身份验证 | SEC/FINRA KYC 规定，SFC KYC 指引（Phase 2） |
| 税务申报 | IRS W-8BEN（非美国居民）/ W-9（美国居民） |
| 反洗钱 | AMLO Part 4A，BSA，FINRA Rule 3310 |
| 风险披露 | FINRA Rule 2010，SEC Reg BI |
| 数据保留 | KYC 记录保留账户关闭后 6 年 |

### 1.3 Phase 1 vs Phase 2

| 功能 | Phase 1 | Phase 2 |
|------|---------|---------|
| 7 步 KYC 流程 | ✅ | - |
| OCR 证件识别 | ✅ 基础 OCR | - |
| 活体检测 | ❌（人工审核替代） | ✅ Onfido/Sumsub/Jumio |
| 手写签名 | ❌（勾选 + 打字姓名替代） | ✅ 电子签名 SDK |
| 自动审核 | ❌ | ✅ |
| 融资融券开户 | ❌ | ✅ |
| 机构开户 | ❌ | ✅ |

---

## 二、7 步开户流程

### 流程总览

```
Step 1: 个人信息 + 就业状况
Step 2: 证件上传（OCR）
Step 3: 财务状况
Step 4: 投资评估
Step 5: 税务申报（W-8BEN / W-9）
Step 6: 风险披露（5 份文档）
Step 7: 协议签署

→ 提交 → 审核中状态页 → 结果通知
```

### Step 1：个人信息 + 就业状况

**必填字段**:

| 字段 | 类型 | 验证规则 |
|------|------|---------|
| 名（英文） | 文本 | 仅允许英文字母、连字符、空格，最大 50 字 |
| 姓（英文） | 文本 | 同上 |
| 中文名 | 文本 | 选填，最大 20 字 |
| 出生日期 | 日期选择器 | 年龄 18-100 岁 |
| 国籍 | 下拉（国家列表） | 必选 |
| 证件类型 | 下拉 | 身份证 / 护照 / 港澳居民来往内地通行证 / 香港身份证（HKID） |
| 证件号码 | 文本 | 按证件类型正则校验 |
| 就业状况 | 单选 | 在职 / 自雇 / 退休 / 学生 / 其他 |
| 职业（就业时） | 文本 | 最大 100 字 |
| 雇主名称（就业时） | 文本 | 最大 200 字 |
| 是否政治敏感人士（PEP） | 复选框 | 默认未勾选 |
| 是否证券公司内部人员 | 复选框 | 默认未勾选 |

**业务规则**:
- 英文姓名必须与证件一致（OCR 在 Step 2 后回填对比）
- PEP / Insider 勾选 → 触发人工审核强制流程，不可自动审核通过
- 就业状态影响财务状况 Step 3 的字段显示

---

### Step 2：证件上传（OCR）

**上传要求**:

| 证件类型 | 需上传页面 |
|---------|---------|
| 身份证 | 正面 + 背面 |
| 护照 | 个人信息页 |
| 港澳通行证 | 正面 + 背面 |
| HKID | 正面（含地址区） |

**OCR 流程**:
```
用户上传图片 → 本地裁剪/压缩（< 5MB）→ 发送至后端 OCR 服务
             ↓
    [识别成功] → 返回结构化字段 → 自动填充 Step 1 字段 → 用户确认或修改
    [识别失败] → 提示用户手动填写 → 记录 OCR 失败原因（异常上报）
```

**图片质量要求**:
- 分辨率 ≥ 720p，文件格式 JPEG / PNG / HEIC
- 不可遮挡证件四角
- 图片不可模糊（服务端校验 Blur Score）
- 不接受过期证件（从 OCR 识别有效期判断）

**数据存储**:
- 证件图片加密存储（AES-256-GCM）于对象存储，不落入主数据库
- 应用层加密，密钥由 KMS 管理
- 审核完成后 6 年保留，账户关闭后另保留 6 年

---

### Step 3：财务状况

| 字段 | 类型 | 选项 |
|------|------|------|
| 年收入（USD） | 下拉 | < $30K / $30K-$75K / $75K-$200K / $200K-$500K / > $500K |
| 总净资产（USD） | 下拉 | < $50K / $50K-$200K / $200K-$1M / $1M-$5M / > $5M |
| 流动净资产（USD） | 下拉 | 同上 |
| 资金来源 | 多选 | 工资/薪金 / 经营收入 / 投资收益 / 遗产赠与 / 房产出租 / 其他 |

**业务规则**:
- 流动净资产不得超过总净资产（前端实时校验）
- 资金来源至少选 1 项
- 该数据用于 AML 评分和后续风险评估

---

### Step 4：投资评估

| 字段 | 类型 | 选项 |
|------|------|------|
| 投资经验年限 | 单选 | 无经验 / 1-3 年 / 3-5 年 / 5-10 年 / 10 年以上 |
| 投资频率 | 单选 | 很少（< 5 次/年）/ 偶尔（5-20 次/年）/ 频繁（> 20 次/年）|
| 产品知识 | 多选 | 股票 / ETF / 债券 / 期权 / 期货 / 外汇 |
| 投资目标 | 单选 | 资本保值 / 稳定收益 / 资本增值 / 高风险高回报 |
| 风险承受能力 | 单选 | 保守 / 稳健 / 平衡 / 进取 / 激进 |

**业务规则**:
- 根据评估结果系统自动生成风险等级（R1-R5）
- 风险等级影响可交易产品范围（Phase 1 仅美股，故不作拦截，但数据记录归档）
- Phase 2 期权 / 融资产品将依据此分级限制访问

---

### Step 5：税务申报（W-8BEN / W-9）

**流程分支**:
```
"您是否是美国税务居民？"
    ↓ 是 → W-9 填写流程 → TIN（SSN / EIN）
    ↓ 否 → W-8BEN 填写流程
```

**W-8BEN 字段**:

| 字段 | 说明 |
|------|------|
| 税务居住国 | 下拉（国家列表） |
| 纳税人识别号（TIN） | 各国 TIN（中国居民用身份证号，香港居民用 HKID 号） |
| 申请税收协定优惠 | 复选框（美中双边税收协定 Article 10，股息税 10%） |
| 协定国家 | 自动填充（基于税务居住国） |
| 适用条款 | Article 10 |
| 申报税率 | 10%（标准 30% → 协定 10%） |
| 电子签署确认 | "本人以电子方式确认上述信息真实准确" 复选框 |

**W-8BEN 有效期**:
- 签署后有效 3 年
- 到期前 90 天系统推送提醒更新
- 到期未更新：股息自动按 30% 扣税（后台标记，Admin 工作台提醒）

**数据存储**:
- W-8BEN 表单数据加密存储
- 生成 PDF 存档（供用户在"我的"页下载）
- 保留期：账户有效期间 + 关闭后 6 年

---

### Step 6：风险披露

**5 份必读文件**（可展开/收起）:

| 编号 | 文档名称 | 核心内容 |
|------|---------|---------|
| 1 | 证券风险声明书 | 投资风险通用说明 |
| 2 | 美国市场风险说明 | NYSE/NASDAQ 市场特有风险 |
| 3 | 香港市场风险说明（Phase 2 后激活） | HKEX 市场特有风险 |
| 4 | Pattern Day Trader（PDT）规则说明 | $25K 最低权益要求，4 次 Day Trade 规则 |
| 5 | 最优执行（Best Execution）说明 | 订单路由原则，PFOF 说明 |

**交互规则**:
- 5 份文件全部展开阅读（或滚动至底部）后，才激活"我已阅读全部文件"复选框
- 复选框未勾选：下一步按钮禁用
- 内容支持中英文双语

---

### Step 7：协议签署

**5 份协议**:

| 编号 | 协议名称 |
|------|---------|
| 1 | 客户协议（Client Agreement） |
| 2 | 隐私政策（Privacy Policy） |
| 3 | 电子通讯协议（E-Communications Agreement） |
| 4 | 交易所数据协议（Exchange Data Agreement）— 非专业投资者声明 |
| 5 | 反洗钱声明（AML Declaration） |

**签署方式（Phase 1）**:
- 在文本框中打字输入完整法定英文姓名（必须与 Step 1 一致）
- 系统比对：姓名不一致 → 报错提示（不区分大小写，去除首尾空格）
- 勾选"本人已阅读并同意上述所有协议"
- 点击"提交申请"

**业务规则**:
- 签署时间戳（UTC）、IP 地址、设备 ID 记录至审计日志
- 协议版本号与签署记录关联存储
- 签署后不可更改协议版本（版本升级需重新签署）

---

## 三、KYC 审核流程

### 3.1 状态机

```
NOT_STARTED
    → IN_PROGRESS（用户开始填写）
    → SUBMITTED（用户提交所有步骤）
    → PENDING_REVIEW（进入人工审核队列）
    → APPROVED（审核通过，账户激活）
    → NEEDS_MORE_INFO（需补充材料）
    → REJECTED（拒绝开户）
```

### 3.2 审核状态页（用户端）

| 状态 | 显示内容 |
|------|---------|
| 审核中 | 进度时间轴（5 个节点）+ 预计 1-2 个工作日 |
| 需补充材料 | 具体原因说明 + 补件入口 |
| 已通过 | 账号 UID + 开户成功确认 + "立即入金"按钮 |
| 已拒绝 | 拒绝原因概述 + 客服联系方式 |

**进度时间轴节点**:
1. 申请已提交
2. 身份核验
3. 人工审核
4. 合规审批
5. 账户已激活

### 3.3 SLA

| 状态 | 目标处理时间 |
|------|------------|
| 普通 KYC | 1 个工作日内完成审核 |
| PEP / 内部人员标记 | 2-3 个工作日（合规专项审核） |
| 补件后重审 | 1 个工作日 |

---

## 四、Admin Panel：KYC 审核工作台

### 4.1 审核队列

| 功能 | 说明 |
|------|------|
| 按提交时间排序 | 先进先出（FIFO）默认排序 |
| 过滤器 | 状态 / 国籍 / 证件类型 / 提交日期范围 / 是否 PEP |
| 批量操作 | 批量标记"需补件"（可选） |
| SLA 预警 | 超过 20 小时未处理标红预警 |

### 4.2 审核工作台页面

| 模块 | 内容 |
|------|------|
| 用户信息面板 | 所有 7 步填写的结构化数据 |
| 证件图片查看 | 原图查看（缩放、旋转）；OCR 识别结果高亮对比 |
| 风险信号 | PEP 标记 / OFAC 筛查结果 / 风险评分 |
| 操作区域 | 通过 / 需补件（填写原因）/ 拒绝（选择拒绝类型） |
| 审核备注 | 内部备注（不对用户展示） |
| 审核历史 | 该申请的所有审核操作记录 |

### 4.3 操作权限

| 操作 | 所需角色 |
|------|---------|
| 审核通过 | KYC Reviewer |
| 要求补件 | KYC Reviewer |
| 拒绝开户 | KYC Senior Reviewer |
| PEP 专项审核 | Compliance Officer |
| 查看所有审核历史 | Admin / Compliance Officer |

---

## 五、后端接口规格

### 5.1 保存 KYC 进度（断点续传）

> **[v1.1 修订]** P0-KYC-01 修复：PUT → PATCH，增加 Idempotency-Key；去除 `resume_token`（无明确用途）。

```
PATCH /v1/kyc/progress
Headers:
  Authorization: Bearer {token}
  Idempotency-Key: {uuid-v4}         // [v1.1 新增] 防止断网重试重复调用 OCR
Request:
  {
    "step": 1,
    "data": { /* 该步骤的字段数据 */ }
  }
Response:
  {
    "step_status": "SAVED",
    "next_step": 2,
    "completed_steps_mask": 1         // [v1.1 新增] 位图，第 n 位表示第 n 步已完成
  }
```

**幂等处理**: Redis 存储 `kyc_progress_idem:{user_id}:{idempotency_key}` → 响应内容，TTL=72h。

### 5.2 OCR 识别

> **[v1.1 修订]** Flutter 图片上传使用 `image_picker ^1.2.1` + `image_cropper ^7.1.5`；HEIC 格式在 Android API 26-27 不支持，客户端强制转换为 JPEG（质量 85%，控制在 5MB 内）后再上传。

```
POST /v1/kyc/ocr
Content-Type: multipart/form-data
Headers:
  Idempotency-Key: {uuid-v4}
Request:
  file: 图片文件（JPEG/PNG，服务端限制 < 5MB）
  doc_type: "ID_CARD_FRONT" | "ID_CARD_BACK" | "PASSPORT" | "HKID"
Response:
  {
    "success": true,
    "fields": {
      "first_name": "San",
      "last_name": "Zhang",
      "id_number": "110101199001010001",
      "date_of_birth": "1990-01-01",
      "expiry_date": "2030-01-01"
    },
    "confidence": 0.95,
    "blur_score": 0.02
    // [v1.1 移除] ocr_highlight_boxes: 无 bounding box 数据，Admin 高亮对比功能不可实现，需改方案
  }
```

**证件图片安全访问（Presigned URL）**:
- 证件图片存储于对象存储（S3/OSS），加密存储，不可直接访问
- Admin 查看图片通过独立接口获取 Presigned URL（TTL=5分钟）
- 接口：`GET /v1/admin/kyc/applications/{id}/document-url?doc_type=xxx`（见 PRD-09）

### 5.3 提交 KYC 申请

> **[v1.1 修订]** 补充服务端步骤完整性校验（P1-KYC-07 修复）和幂等处理。

```
POST /v1/kyc/submit
Headers:
  Idempotency-Key: {uuid-v4}         // [v1.1 新增] 防止双击提交重复进队
Request:
  {
    "read_documents": [              // [v1.1 新增] 服务端验证 5 份风险披露全部已读
      "RISK_DISCLOSURE_1",
      "RISK_DISCLOSURE_2",
      "RISK_DISCLOSURE_3",
      "PDT_RULES",
      "BEST_EXECUTION"
    ]
  }
Response:
  {
    "application_id": "kyc-uuid",
    "status": "PENDING_REVIEW",
    "estimated_review_time": "1 business day"
  }
```

**服务端校验**:
1. `completed_steps_mask == 0b1111111`（7 步全部完成位图验证）
2. `read_documents` 包含全部 5 份必读文件
3. 协议签署姓名与 Step 1 英文姓名一致（大小写不敏感，去首尾空格）
4. 72h 幂等缓存，重复提交返回第一次响应

### 5.4 查询 KYC 状态

```
GET /v1/kyc/status
Response:
  {
    "status": "PENDING_REVIEW" | "APPROVED" | "NEEDS_MORE_INFO" | "REJECTED",
    "kyc_tier": 0 | 1 | 2,
    "account_number": "XXX123456",  // 通过后返回
    "needs_info_reason": "证件图片模糊，请重新上传",
    "rejection_reason": null,
    "timeline": [
      {"node": "submitted", "completed_at": "2026-03-13T10:00:00Z"},
      {"node": "identity_verified", "completed_at": null}
    ]
  }
```

### 5.5 补充材料

```
POST /v1/kyc/resubmit
Request:
  {
    "step": 2,
    "data": { /* 补充的字段/文件 */ }
  }
```

---

## 六、数据模型

```sql
-- KYC 申请主表（v1.1 新增 completed_steps_mask、started_at、expires_at）
CREATE TABLE kyc_applications (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users(id),
    status               VARCHAR(30) NOT NULL DEFAULT 'NOT_STARTED',
    kyc_tier             SMALLINT DEFAULT 0,
    account_number       VARCHAR(20) UNIQUE,
    completed_steps_mask SMALLINT NOT NULL DEFAULT 0, -- [v1.1 新增] 位图，7 步全完成=0b1111111=127
    started_at           TIMESTAMP WITH TIME ZONE,    -- [v1.1 新增] 首次进入 KYC 时间
    expires_at           TIMESTAMP WITH TIME ZONE,    -- [v1.1 新增] IN_PROGRESS 超时：started_at + 60 days
    submitted_at         TIMESTAMP WITH TIME ZONE,
    reviewed_at          TIMESTAMP WITH TIME ZONE,
    reviewer_id          UUID,
    rejection_reason     TEXT,
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- 定时任务（每日 00:00 UTC）：超时处理
-- UPDATE kyc_applications SET status = 'EXPIRED' WHERE status = 'IN_PROGRESS' AND expires_at < NOW()

-- KYC 个人信息（加密存储敏感字段，v1.1 移除 risk_level 至独立表）
CREATE TABLE kyc_personal_info (
    kyc_id            UUID PRIMARY KEY REFERENCES kyc_applications(id),
    first_name        VARCHAR(100) NOT NULL,
    last_name         VARCHAR(100) NOT NULL,
    chinese_name      VARCHAR(50),
    date_of_birth     DATE NOT NULL,
    nationality       VARCHAR(5) NOT NULL,  -- ISO 3166-1 alpha-2
    id_type           VARCHAR(30) NOT NULL,
    id_number_enc     BYTEA NOT NULL,       -- AES-256-GCM 加密
    employment_status VARCHAR(20),
    occupation        VARCHAR(100),
    employer_name     VARCHAR(200),
    is_pep            BOOLEAN DEFAULT false,
    is_insider        BOOLEAN DEFAULT false
    -- [v1.1 移除] risk_level 归入 kyc_risk_assessment 表
);

-- [v1.1 新增] 财务状况（KYC Step 3 原始数据，原缺失）
CREATE TABLE kyc_financial_profile (
    kyc_id              UUID PRIMARY KEY REFERENCES kyc_applications(id),
    annual_income_range VARCHAR(30) NOT NULL,
    net_worth_range     VARCHAR(30) NOT NULL,
    liquid_assets_range VARCHAR(30) NOT NULL,
    fund_sources        TEXT[] NOT NULL,      -- ARRAY of source codes
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- [v1.1 新增] 投资评估（KYC Step 4 原始数据 + 计算结果，原只存 risk_level）
CREATE TABLE kyc_risk_assessment (
    kyc_id                UUID PRIMARY KEY REFERENCES kyc_applications(id),
    investment_exp_years  VARCHAR(20) NOT NULL,
    investment_frequency  VARCHAR(20) NOT NULL,
    product_knowledge     TEXT[] NOT NULL,
    investment_objective  VARCHAR(30) NOT NULL,
    risk_tolerance        VARCHAR(20) NOT NULL,
    computed_risk_level   SMALLINT NOT NULL,   -- 1-5
    computed_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- W-8BEN 表单（v1.1 新增 status、is_current 字段及约束）
CREATE TABLE w8ben_forms (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kyc_id          UUID NOT NULL REFERENCES kyc_applications(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    tax_country     VARCHAR(5) NOT NULL,
    tin_enc         BYTEA,               -- TIN 加密存储
    treaty_claim    BOOLEAN DEFAULT false,
    treaty_article  VARCHAR(20),
    withholding_rate NUMERIC(5,2),       -- 10.00 for treaty rate
    signed_name     VARCHAR(200) NOT NULL,
    signed_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    signed_ip       INET NOT NULL,
    signed_device_id VARCHAR(64) NOT NULL,
    valid_until     DATE NOT NULL,       -- 签署日期 + 3 年
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- [v1.1 新增] ACTIVE / EXPIRED / SUPERSEDED
    is_current      BOOLEAN NOT NULL DEFAULT true,          -- [v1.1 新增]
    pdf_storage_key VARCHAR(500),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- [v1.1 新增] 同一用户同时只有一条当前有效记录
    CONSTRAINT uq_user_w8ben_current UNIQUE (user_id, is_current) WHERE is_current = true
);
-- W-8BEN 到期定时任务（每日 00:00 UTC）：
-- SELECT user_id FROM w8ben_forms WHERE is_current = true AND valid_until < NOW()
-- → 标记 status='EXPIRED', is_current=false → Kafka 事件 → 推送通知 → 交易引擎切换 30% 税率
-- W-8BEN 90 天提前提醒：
-- WHERE is_current = true AND valid_until BETWEEN NOW() AND NOW() + INTERVAL '90 days'

-- 协议签署记录
CREATE TABLE agreement_signatures (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kyc_id            UUID NOT NULL REFERENCES kyc_applications(id),
    agreement_type    VARCHAR(50) NOT NULL,
    agreement_version VARCHAR(20) NOT NULL,
    signed_name       VARCHAR(200) NOT NULL,
    signed_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    signed_ip         INET NOT NULL,
    signed_device_id  VARCHAR(64) NOT NULL
);

-- KYC 审核历史（只追加，不修改）
CREATE TABLE kyc_review_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kyc_id          UUID NOT NULL REFERENCES kyc_applications(id),
    action          VARCHAR(30) NOT NULL,  -- 'APPROVE', 'REJECT', 'REQUEST_INFO'
    reviewer_id     UUID NOT NULL,
    reason          TEXT,
    internal_notes  TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- [v1.1 新增] 必要审计索引
CREATE INDEX idx_kyc_applications_user    ON kyc_applications (user_id, created_at DESC);
CREATE INDEX idx_kyc_applications_status  ON kyc_applications (status, created_at DESC);
CREATE INDEX idx_w8ben_user_current       ON w8ben_forms (user_id, is_current) WHERE is_current = true;
CREATE INDEX idx_w8ben_valid_until        ON w8ben_forms (valid_until) WHERE is_current = true;
```

---

## 七、安全与合规

| 项目 | 规格 |
|------|------|
| 证件图片加密 | AES-256-GCM，密钥由 KMS 管理 |
| PII 字段加密 | 证件号、TIN、DOB（与其他字段组合时）加密存储 |
| 传输加密 | TLS 1.3 全程 |
| 访问控制 | 证件图片仅 KYC Reviewer 及以上角色可查看 |
| 审计追踪 | 所有审核操作记录至 `kyc_review_log`，不可修改 |
| 数据保留 | KYC 记录：账户关闭后 6 年 |
| OFAC 筛查 | KYC 提交时自动触发，结果记录（见 PRD-05 AML 部分） |

---

## 八、验收标准

| 场景 | 标准 |
|------|------|
| 7 步流程完整性 | 每步数据验证通过后方可进入下一步 |
| 断点续传 | App 关闭重开后可从上次完成的步骤继续 |
| OCR 识别率 | 清晰证件图片识别成功率 ≥ 85% |
| 提交审核时间 | 材料完整情况下 1 工作日内完成审核 |
| W-8BEN 生效 | 签署后立即生效，股息税率调整为 10%（后台配置） |
| 补件流程 | 用户收到补件通知后可直接从指定步骤重新上传 |
| 审核工作台 | Reviewer 可在单页面完成查看 + 操作，无需切换多页 |
