# AMS-Mobile KYC Contract

> **版本**: v1.0
> **日期**: 2026-03-31
> **作者**: AMS Engineer + H5 Engineer
> **状态**: Final — Ready for Implementation
>
> 本文档定义移动端与 AMS 后端的 KYC（了解你的客户）完整端到端交互契约，覆盖 7 步开户流程、数据验收标准、文件上传协议、Sumsub 集成、W-8BEN 生命周期，以及错误处理策略。

---

## 目录

1. [KYC 七步流程概览](#1-kyc-七步流程概览)
2. [OpenAPI 3.0 规范](#2-openapi-30-规范)
3. [数据模型与验证](#3-数据模型与验证)
4. [文件上传协议](#4-文件上传协议)
5. [Sumsub 集成细节](#5-sumsub-集成细节)
6. [W-8BEN 税务表单管理](#6-w-8ben-税务表单管理)
7. [状态轮询与 Webhook](#7-状态轮询与-webhook)
8. [错误处理与重试](#8-错误处理与重试)
9. [Dart 模型生成](#9-dart-模型生成)
10. [Go 处理函数签名](#10-go-处理函数签名)
11. [gRPC Protobuf 定义](#11-grpc-protobuf-定义)

---

## 1. KYC 七步流程概览

```
移动端 UI                    AMS 后端                    第三方服务
┌─────────────────────────────────────────────────────────────┐
│ [Step 1] 个人信息录入                                         │
│ name, dob, email, phone, jurisdiction                       │
└──────────┬──────────────────────────────────────────────────┘
           │ POST /v1/kyc/start
           ▼
┌─────────────────────────────────────────────────────────────┐
│ [Step 2] 身份证件上传                                         │
│ id_type, image (JPEG/PNG)                                  │
└──────────┬──────────────────────────────────────────────────┘
           │ POST /v1/kyc/documents/upload + Sumsub accessToken
           │
           ├──────────────────────────────────────►Sumsub SDK
           │                                       - OCR 识别
           │                                       - 活体检测（Level 2）
           │                                       - 归档
           │
           │◄──────Sumsub Webhook applicantReviewed─────────┤
           ▼
┌─────────────────────────────────────────────────────────────┐
│ [Step 3] 财务信息填报                                         │
│ income_range, savings_range, funds_source                  │
└──────────┬──────────────────────────────────────────────────┘
           │ POST /v1/kyc/financial-profile
           ▼
┌─────────────────────────────────────────────────────────────┐
│ [Step 4] 投资适合性问卷                                       │
│ investment_objective, risk_tolerance, time_horizon         │
└──────────┬──────────────────────────────────────────────────┘
           │ POST /v1/kyc/investment-assessment
           ▼
┌─────────────────────────────────────────────────────────────┐
│ [Step 5] 税务表单（W-8BEN/W-9/CRS）                          │
│ tax_form_type, w8ben_fields...                              │
└──────────┬──────────────────────────────────────────────────┘
           │ POST /v1/kyc/tax-forms
           ▼
┌─────────────────────────────────────────────────────────────┐
│ [Step 6] 风险披露与协议                                       │
│ options_trading, margin, leverage 等披露                    │
└──────────┬──────────────────────────────────────────────────┘
           │ POST /v1/kyc/agreements
           │
           ├──────────────► AML 同步筛查 (OFAC/HK)
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│ [Step 7] 确认并提交                                           │
│ 所有信息完整 → 账户进入 PENDING_AML_REVIEW                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. OpenAPI 3.0 规范

### 2.1 Step 1: 开始 KYC — POST /v1/kyc/start

**Request**:
```yaml
openapi: 3.0.0
paths:
  /v1/kyc/start:
    post:
      operationId: startKYC
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/KYCStartRequest'
      responses:
        '200':
          description: KYC 流程已开启
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/KYCStartResponse'
        '400':
          $ref: '#/components/responses/ValidationError'

components:
  schemas:
    KYCStartRequest:
      type: object
      required:
        - first_name
        - last_name
        - date_of_birth
        - email
        - phone_number
        - jurisdiction
      properties:
        first_name:
          type: string
          minLength: 1
          maxLength: 50
          pattern: '^[a-zA-Z\s-]+$'
          example: John
        last_name:
          type: string
          minLength: 1
          maxLength: 50
          pattern: '^[a-zA-Z\s-]+$'
          example: Doe
        date_of_birth:
          type: string
          format: date
          example: 1990-05-15
          description: 'ISO 8601 格式，用户必须 >= 18 岁'
        email:
          type: string
          format: email
          example: john.doe@example.com
        phone_number:
          type: string
          pattern: '^\+[1-9]\d{1,14}$'
          example: '+852987654321'
          description: 'E.164 格式'
        jurisdiction:
          type: string
          enum: [US, HK, BOTH]
          description: '意图交易的市场'
        nationality:
          type: string
          minLength: 2
          maxLength: 2
          example: US
          description: 'ISO 3166-1 alpha-2'

    KYCStartResponse:
      type: object
      properties:
        kyc_session_id:
          type: string
          format: uuid
          description: '后续请求用此 ID'
        current_step:
          type: integer
          example: 1
        estimated_time_minutes:
          type: integer
          example: 15
```

**验证规则**:
- `date_of_birth`: 必须 >= 18 岁（计算到今天）
- `phone_number`: E.164 格式，+ 开头，1-15 位数字
- `email`: 有效邮箱格式，不接受一次性邮箱域名（检查 Disposable Email 列表）
- `jurisdiction`: 与账户注册地一致

---

### 2.2 Step 2: 上传身份文件 — POST /v1/kyc/documents/upload

**Request** (multipart/form-data):
```yaml
paths:
  /v1/kyc/documents/upload:
    post:
      operationId: uploadIdentityDocument
      parameters:
        - name: kyc_session_id
          in: query
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              type: object
              required:
                - id_type
                - image_front
              properties:
                id_type:
                  type: string
                  enum:
                    - US_DRIVERS_LICENSE
                    - US_PASSPORT
                    - HKID
                    - INTL_PASSPORT
                    - CHINA_RESIDENT_ID
                  example: US_PASSPORT
                image_front:
                  type: string
                  format: binary
                  description: '身份证正面图片'
                image_back:
                  type: string
                  format: binary
                  description: 'HKID/Passport 需要；Driver License 需要'
                sumsub_access_token:
                  type: string
                  description: 'Sumsub SDK accessToken，从 /v1/kyc/sumsub-token 获取'
      responses:
        '202':
          description: 文件已接收，在后台处理
          content:
            application/json:
              schema:
                type: object
                properties:
                  document_id:
                    type: string
                    format: uuid
                  status:
                    type: string
                    enum: [UPLOADING, PENDING_VERIFICATION]
                  sumsub_applicant_id:
                    type: string
                    description: 'Sumsub 申请人 ID'
        '400':
          description: 文件格式错误、尺寸超限或参数缺失
```

**文件验证**:
```go
// Go 验证逻辑
const (
    MaxImageSize = 10 * 1024 * 1024  // 10 MB
    MinWidth     = 1200
    MaxWidth     = 4000
    MinHeight    = 1000
    MaxHeight    = 3000
)

// 接受的 MIME 类型
var AllowedMimeTypes = []string{
    "image/jpeg",   // JPEG quality >= 85
    "image/png",
}
```

---

### 2.3 Step 3: 财务信息 — POST /v1/kyc/financial-profile

```yaml
paths:
  /v1/kyc/financial-profile:
    post:
      operationId: submitFinancialProfile
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - annual_income_range
                - liquid_net_worth_range
                - funds_source
              properties:
                annual_income_range:
                  type: string
                  enum:
                    - UNDER_25K
                    - '25K_50K'
                    - '50K_100K'
                    - '100K_250K'
                    - '250K_500K'
                    - '500K_1M'
                    - OVER_1M
                liquid_net_worth_range:
                  type: string
                  enum:
                    - UNDER_25K
                    - '25K_100K'
                    - '100K_500K'
                    - '500K_1M'
                    - '1M_5M'
                    - OVER_5M
                funds_source:
                  type: array
                  minItems: 1
                  items:
                    type: string
                    enum:
                      - SALARY
                      - INVESTMENT_RETURNS
                      - BUSINESS_OPERATIONS
                      - REAL_ESTATE
                      - INHERITANCE
                      - OTHER
                employment_status:
                  type: string
                  enum: [EMPLOYED, SELF_EMPLOYED, RETIRED, STUDENT, OTHER]
                employer_name:
                  type: string
                  maxLength: 100
                  description: '仅 EMPLOYED 时需要'
```

---

### 2.4 Step 4: 投资适合性问卷 — POST /v1/kyc/investment-assessment

```yaml
paths:
  /v1/kyc/investment-assessment:
    post:
      operationId: submitInvestmentAssessment
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - investment_objective
                - risk_tolerance
                - time_horizon
                - stock_experience_years
              properties:
                investment_objective:
                  type: string
                  enum:
                    - CAPITAL_PRESERVATION
                    - INCOME
                    - GROWTH
                    - SPECULATION
                risk_tolerance:
                  type: string
                  enum: [CONSERVATIVE, MODERATE, AGGRESSIVE]
                time_horizon:
                  type: string
                  enum: [SHORT, MEDIUM, LONG]
                  description: 'SHORT: <1yr, MEDIUM: 1-5yr, LONG: >5yr'
                stock_experience_years:
                  type: integer
                  minimum: 0
                options_experience_years:
                  type: integer
                  minimum: 0
                margin_experience_years:
                  type: integer
                  minimum: 0
                liquidity_need:
                  type: string
                  enum: [LOW, MEDIUM, HIGH]
```

---

### 2.5 Step 5: 税务表单 — POST /v1/kyc/tax-forms

```yaml
paths:
  /v1/kyc/tax-forms:
    post:
      operationId: submitTaxForms
      requestBody:
        required: true
        content:
          application/json:
            schema:
              oneOf:
                - $ref: '#/components/schemas/W9FormRequest'
                - $ref: '#/components/schemas/W8BENFormRequest'
                - $ref: '#/components/schemas/CRSFormRequest'

components:
  schemas:
    W9FormRequest:
      type: object
      required:
        - form_type
        - full_name
        - ssn
        - address
      properties:
        form_type:
          type: string
          const: W9
        full_name:
          type: string
        ssn:
          type: string
          pattern: '^\d{3}-\d{2}-\d{4}$'
          description: '密钥加密存储'
        address:
          type: string

    W8BENFormRequest:
      type: object
      required:
        - form_type
        - full_name
        - country_of_tax_residence
        - tin
        - signature_date
      properties:
        form_type:
          type: string
          const: W8BEN
        full_name:
          type: string
        country_of_tax_residence:
          type: string
          minLength: 2
          maxLength: 2
          description: 'ISO 3166-1 alpha-2'
        tin:
          type: string
          description: 'Tax Identification Number，密钥加密'
        address:
          type: string
        tin_not_available:
          type: boolean
          description: '如 TIN 不可用，勾选此项'
        signature_date:
          type: string
          format: date

    CRSFormRequest:
      type: object
      required:
        - form_type
        - tax_residencies
      properties:
        form_type:
          type: string
          const: CRS
        tax_residencies:
          type: array
          minItems: 1
          items:
            type: object
            required:
              - country_code
              - tin
            properties:
              country_code:
                type: string
                minLength: 2
                maxLength: 2
              tin:
                type: string
              tin_not_available:
                type: boolean
```

---

### 2.6 Step 6: 风险披露与协议 — POST /v1/kyc/agreements

```yaml
paths:
  /v1/kyc/agreements:
    post:
      operationId: acknowledgeAgreements
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - terms_of_service_agreed
                - risk_disclosure_acknowledged
              properties:
                terms_of_service_agreed:
                  type: boolean
                  const: true
                risk_disclosure_acknowledged:
                  type: boolean
                  const: true
                options_risk_acknowledged:
                  type: boolean
                  description: '仅美股账户'
                margin_risk_acknowledged:
                  type: boolean
                  description: '如申请保证金账户'
                leverage_risk_acknowledged:
                  type: boolean
                agreed_at:
                  type: string
                  format: date-time
                  description: '协议接受时间戳'
```

---

### 2.7 Step 7: 完成提交 — POST /v1/kyc/submit

```yaml
paths:
  /v1/kyc/submit:
    post:
      operationId: submitKYC
      parameters:
        - name: kyc_session_id
          in: query
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                review_checklist:
                  type: object
                  description: '检查清单，user 确认所有信息准确无误'
      responses:
        '202':
          description: KYC 提交成功，账户进入审核流程
          content:
            application/json:
              schema:
                type: object
                properties:
                  account_id:
                    type: string
                    format: uuid
                  kyc_status:
                    type: string
                    enum: [PENDING, REVIEWING, APPROVED, REJECTED]
                  estimated_review_time_hours:
                    type: integer
                    example: 24
                  next_steps:
                    type: array
                    items:
                      type: string
```

---

## 3. 数据模型与验证

### 3.1 年龄验证

```go
func ValidateDateOfBirth(dob time.Time) error {
    age := time.Since(dob).Hours() / (24 * 365.25)
    if age < 18 {
        return errors.New("must be at least 18 years old")
    }
    return nil
}
```

### 3.2 电话号码国际化

```go
import "github.com/nyaruka/phonenumbers"

func ValidatePhoneNumber(phoneStr string) error {
    num, err := phonenumbers.Parse(phoneStr, "")
    if err != nil {
        return fmt.Errorf("invalid phone number: %w", err)
    }
    if !phonenumbers.IsValidNumber(num) {
        return errors.New("phone number validation failed")
    }
    return nil
}
```

### 3.3 SSN/HKID 格式验证

```go
// SSN: XXX-XX-XXXX
func ValidateSSN(ssn string) error {
    pattern := regexp.MustCompile(`^\d{3}-\d{2}-\d{4}$`)
    if !pattern.MatchString(ssn) {
        return errors.New("SSN must be in format XXX-XX-XXXX")
    }
    return nil
}

// HKID: Letter + 7 digits + (digit or letter)
func ValidateHKID(hkid string) error {
    pattern := regexp.MustCompile(`^[A-Z]\d{6}[0-9A]$`)
    if !pattern.MatchString(hkid) {
        return errors.New("invalid HKID format")
    }
    return nil
}
```

---

## 4. 文件上传协议

### 4.1 图像尺寸与压缩

```
原始 ID 照片要求：
├── 分辨率：1200x1000 ~ 4000x3000 像素
├── 宽高比：4:3 ~ 3:2（标准证件照比例）
├── 格式：JPEG (quality >= 85) 或 PNG
├── 文件大小：< 10 MB
├── 色彩空间：RGB 或 RGBA
├── DPI：>=96
└── 无物理遮挡、无反光、清晰可读
```

### 4.2 Upload 流程（S3 预签名 URL）

```
1. 客户端请求预签名 URL：
   GET /v1/kyc/upload-url?document_type=id_front&kyc_session_id=xxx

2. AMS 返回：
   {
     "upload_url": "https://s3.region.amazonaws.com/bucket/path?AWSAccessKeyId=...",
     "expiry": 3600,
     "checksum_algorithm": "SHA256"
   }

3. 客户端直接 PUT 到 S3：
   PUT <upload_url>
   Content-Type: image/jpeg
   x-amz-checksum-sha256: <sha256_hash>

4. S3 上传成功后，客户端通知 AMS：
   POST /v1/kyc/documents/confirm-upload
   {
     "kyc_session_id": "xxx",
     "document_id": "doc-xxx",
     "s3_key": "accounts/acc-xxx/id_front.jpg",
     "file_hash": "sha256:...",
     "file_size": 2048576
   }
```

### 4.3 S3 存储结构

```
s3://brokerage-kyc-documents/
├── prod/
│   └── accounts/{account_id}/
│       ├── id_front_{timestamp}.jpg      (版本化)
│       ├── id_back_{timestamp}.jpg
│       ├── address_proof_{timestamp}.pdf
│       └── w8ben_{timestamp}.pdf
└── dev/
    └── ... (同上)
```

**加密与访问**:
- S3 bucket 启用 `encryption: AES-256` (默认)
- 启用版本管理，禁用 public access
- 仅 AMS 和审计服务的 IAM role 可访问
- 审计人员访问需记录（CloudTrail）

---

## 5. Sumsub 集成细节

### 5.1 获取 Sumsub Access Token

```yaml
GET /v1/kyc/sumsub-token:
  parameters:
    - kyc_session_id (query)
  response:
    access_token: string (JWT)
    applicant_id: string (UUID)
    ttl: integer (秒)
    timestamp: integer (Unix timestamp)
```

**Go 实现**:
```go
func (h *KYCHandler) GetSumsubToken(w http.ResponseWriter, r *http.Request) {
    sessionID := r.URL.Query().Get("kyc_session_id")

    // 1. 从数据库获取 KYC 会话和用户信息
    session, err := h.kycRepo.GetSession(r.Context(), sessionID)

    // 2. 调用 Sumsub REST API GenerateAccessToken
    req := sumsub.GenerateAccessTokenRequest{
        ExternalUserID: session.AccountID,
        // ... 其他参数
    }

    token, err := h.sumsubClient.GenerateAccessToken(r.Context(), req)

    // 3. 返回 token
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "access_token": token.AccessToken,
        "applicant_id": token.ApplicantID,
        "ttl": 600,
    })
}
```

### 5.2 Webhook 处理（异步 KYC 结果）

**Webhook 签名验证**:
```go
func verifySumsubWebhookSignature(payload []byte, signature, secret string) bool {
    h := hmac.New(sha256.New, []byte(secret))
    h.Write(payload)
    expected := hex.EncodeToString(h.Sum(nil))
    return hmac.Equal([]byte(signature), []byte(expected))
}
```

**Webhook 事件类型**:
```go
type SumsubWebhookEvent struct {
    ApplicantID string       `json:"applicantId"`
    Type        string       `json:"type"` // applicantReviewed, applicantCreated
    ReviewResult ReviewResult `json:"reviewResult,omitempty"`
}

type ReviewResult struct {
    ReviewAnswer string   `json:"reviewAnswer"` // GREEN, RED, YELLOW
    RejectType   string   `json:"rejectType"`   // FINAL, RETRY
    RejectLabels []string `json:"rejectLabels"` // 具体拒绝原因
}
```

**处理流程**:
```go
// 事务性处理 + 幂等
func (s *AMLService) HandleSumsubReviewResult(ctx context.Context, event SumsubWebhookEvent) error {
    // 1. 检查 idempotency token（防止重复处理）
    processed, _ := s.idempotencyStore.Get(ctx, "sumsub:"+event.ApplicantID)
    if processed {
        return nil // 已处理，返回成功以确认 webhook
    }

    // 2. 事务开始
    tx, _ := s.db.BeginTx(ctx, nil)
    defer tx.Rollback()

    // 3. 更新 KYC 状态
    switch event.ReviewResult.ReviewAnswer {
    case "GREEN":
        // 自动批准（低风险路径）
        _ = s.updateKYCStatus(ctx, event.ApplicantID, "APPROVED")
        _ = s.updateAccountStatus(ctx, "ACTIVE")
    case "RED":
        // 拒绝
        _ = s.updateKYCStatus(ctx, event.ApplicantID, "REJECTED")
        _ = s.sendNotification(ctx, "kyc_rejected", event.RejectLabels)
    case "YELLOW":
        // 转移到人工审核队列
        _ = s.updateKYCStatus(ctx, event.ApplicantID, "MANUAL_REVIEW")
    }

    // 4. 标记为已处理
    _ = s.idempotencyStore.Set(ctx, "sumsub:"+event.ApplicantID, true, 24*time.Hour)

    return tx.Commit().Error
}
```

---

## 6. W-8BEN 税务表单管理

### 6.1 表单生命周期

```
用户开户（US-resident 或 trading US stocks）
        │
        ▼
需要 W-8BEN? (based on jurisdiction + tax residency)
        │
        ├─ 是 ──► 在 KYC Step 5 提示上传
        │
        └─ 否 ──► 标记为 NOT_REQUIRED
                （但 HK 居民仍可选上传 CRS W-9）

用户上传 W-8BEN
        │
        ▼
AMS 验证：
  ├─ SSN/TIN 格式正确
  ├─ 签署日期有效
  ├─ 姓名与 KYC 一致
        │
        ▼
设置 tax_form_status = ACTIVE
设置 tax_form_expiry = now() + 3年
        │
        ▼
T-90 天自动发送续期通知 (Cron Job)
        │
        ├─ 用户上传新表 ──► 重置 expiry
        │
        └─ 无响应 ────► T+0 标记 EXPIRED
                       ├─ US 股利预扣 30% FATCA
                       └─ US 交易禁止新建 BUY 订单
```

### 6.2 到期检查 Cron Job

```go
// 每日 UTC 02:00 执行
func (c *CronService) CheckW8BENExpiry(ctx context.Context) error {
    now := time.Now().UTC()

    // T-90 天：发送续期通知
    expiringIn90 := now.AddDate(0, 0, 90)
    accounts, _ := c.repo.FindW8BENExpiringBefore(ctx, expiringIn90)
    for _, acc := range accounts {
        _ = c.notificationService.SendPushNotification(
            ctx,
            acc.UserID,
            "W-8BEN Renewal Required",
            fmt.Sprintf("Your W-8BEN expires on %s. Please renew to avoid trading restrictions.",
                acc.TaxFormExpiry.Format("2006-01-02")),
        )
    }

    // T+0：标记为 EXPIRED
    expired := now
    accounts, _ = c.repo.FindW8BENExpiringBefore(ctx, expired)
    for _, acc := range accounts {
        _ = c.repo.UpdateTaxFormStatus(ctx, acc.AccountID, "EXPIRED")

        // 发布事件给 Fund Transfer 服务
        _ = c.eventBus.Publish(ctx, "ams.tax_form_expired", map[string]interface{}{
            "account_id": acc.AccountID,
            "jurisdiction": acc.Jurisdiction,
        })
    }

    return nil
}
```

---

## 7. 状态轮询与 Webhook

### 7.1 移动端轮询

```
移动端 ──► GET /v1/kyc/status?kyc_session_id=xxx
           (轮询间隔 5 秒，最多 10 分钟 = 120 次请求)
                │
                ▼
AMS 返回状态    {
                  "kyc_status": "PENDING|REVIEWING|APPROVED|REJECTED",
                  "step": 5,
                  "reason_if_rejected": "Document unclear",
                  "estimated_time_minutes": 45
                }

如果状态 = APPROVED：
  移动端 ──► GET /v1/accounts/me
             返回 account_id, 引导到 trading UI

如果状态 = REJECTED：
  移动端显示拒绝原因，允许重新开户
```

### 7.2 Push Notification 备用机制

```
AMS 内部状态变更时（同时触发）：
  1. 轮询 client 获取状态
  2. Push notification 通知 user
     (FCM → Flutter app)

好处：即使轮询掉线，user 仍能收到结果通知
```

---

## 8. 错误处理与重试

### 8.1 常见错误

```yaml
错误代码            HTTP Code   原因                          用户消息
─────────────────────────────────────────────────────────────
INVALID_AGE         400         用户 < 18 岁                  "Must be 18+"
INVALID_PHONE       400         E.164 格式错误                "Invalid phone format"
FILE_TOO_LARGE      413         > 10 MB                       "File size exceeds 10MB"
FILE_UNSUPPORTED    415         不支持的格式                  "Only JPEG/PNG accepted"
IMAGE_DIMENSIONS    400         分辨率不符                    "Image too small (min 1200x1000)"
SUMSUB_TIMEOUT      504         Sumsub 响应超时 (>5s)         "Identity verification timeout"
SANCTIONS_HIT       451          命中 OFAC/HK 制裁名单        "Account restricted (legal)"
INCOMPLETE_KYC      422         信息不完整                    "Please complete all steps"
ALREADY_VERIFIED    409         已通过 KYC，无需重复          "KYC already completed"
```

### 8.2 重试策略

```go
const (
    MaxRetries  = 3
    BackoffBase = 100 * time.Millisecond
)

func RetryWithBackoff(ctx context.Context, fn func() error) error {
    var lastErr error
    for attempt := 0; attempt < MaxRetries; attempt++ {
        if err := fn(); err == nil {
            return nil
        } else {
            lastErr = err
        }

        if attempt < MaxRetries-1 {
            backoff := BackoffBase * (1 << uint(attempt))
            select {
            case <-time.After(backoff):
            case <-ctx.Done():
                return ctx.Err()
            }
        }
    }
    return lastErr
}
```

---

## 9. Dart 模型生成

### 9.1 Dart 数据类 (使用 freezed)

```dart
// lib/models/kyc/kyc_models.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'kyc_models.freezed.dart';
part 'kyc_models.g.dart';

@freezed
class KYCStartRequest with _$KYCStartRequest {
  const factory KYCStartRequest({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    required String email,
    required String phoneNumber,
    required String jurisdiction, // US, HK, BOTH
    String? nationality,
  }) = _KYCStartRequest;

  factory KYCStartRequest.fromJson(Map<String, dynamic> json) =>
      _$KYCStartRequestFromJson(json);
}

@freezed
class KYCStartResponse with _$KYCStartResponse {
  const factory KYCStartResponse({
    @JsonKey(name: 'kyc_session_id') required String kycSessionId,
    @JsonKey(name: 'current_step') required int currentStep,
    @JsonKey(name: 'estimated_time_minutes') required int estimatedTimeMinutes,
  }) = _KYCStartResponse;

  factory KYCStartResponse.fromJson(Map<String, dynamic> json) =>
      _$KYCStartResponseFromJson(json);
}

@freezed
class W8BENFormRequest with _$W8BENFormRequest {
  const factory W8BENFormRequest({
    @JsonKey(name: 'form_type') required String formType, // W8BEN
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'country_of_tax_residence') required String countryOfTaxResidence,
    required String tin,
    String? address,
    @JsonKey(name: 'tin_not_available') required bool tinNotAvailable,
    @JsonKey(name: 'signature_date') required DateTime signatureDate,
  }) = _W8BENFormRequest;

  factory W8BENFormRequest.fromJson(Map<String, dynamic> json) =>
      _$W8BENFormRequestFromJson(json);
}
```

### 9.2 API Service Layer

```dart
// lib/services/kyc_service.dart

import 'package:dio/dio.dart';

class KYCService {
  final Dio _dio;

  KYCService(this._dio);

  Future<KYCStartResponse> startKYC(KYCStartRequest request) async {
    try {
      final response = await _dio.post(
        '/v1/kyc/start',
        data: request.toJson(),
      );
      return KYCStartResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UploadTokenResponse> getUploadUrl(String kycSessionId) async {
    try {
      final response = await _dio.get(
        '/v1/kyc/upload-url',
        queryParameters: {'kyc_session_id': kycSessionId},
      );
      return UploadTokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<KYCStatusResponse> checkStatus(String kycSessionId) async {
    try {
      final response = await _dio.get(
        '/v1/kyc/status',
        queryParameters: {'kyc_session_id': kycSessionId},
      );
      return KYCStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
```

---

## 10. Go 处理函数签名

### 10.1 Handler 函数

```go
package handlers

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

// KYC handlers in Go
type KYCHandler struct {
    kycService    *service.KYCService
    sumsubService *service.SumsubService
    amlService    *service.AMLService
}

// Step 1: 开始 KYC
func (h *KYCHandler) StartKYC(c *gin.Context) {
    var req models.KYCStartRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
        return
    }

    // 验证年龄、邮箱等
    if err := h.kycService.ValidateStartRequest(c.Request.Context(), req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // 创建 KYC 会话
    session, err := h.kycService.CreateSession(c.Request.Context(), req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create session"})
        return
    }

    c.JSON(http.StatusOK, models.KYCStartResponse{
        KYCSessionID:           session.ID,
        CurrentStep:            1,
        EstimatedTimeMinutes:   15,
    })
}

// Step 2: 上传身份文件
func (h *KYCHandler) UploadIdentityDocument(c *gin.Context) {
    kycSessionID := c.Query("kyc_session_id")

    file, _ := c.FormFile("image_front")
    if file == nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "missing image_front"})
        return
    }

    // 1. 验证文件大小、格式、尺寸
    if err := h.kycService.ValidateImageFile(file); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    // 2. 上传到 S3
    s3Key, err := h.kycService.UploadToS3(c.Request.Context(), file, kycSessionID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "upload failed"})
        return
    }

    // 3. 调用 Sumsub API
    sumsubResult, _ := h.sumsubService.SubmitDocument(c.Request.Context(), kycSessionID, s3Key)

    // 4. 返回 202 (已接收，后台处理)
    c.JSON(http.StatusAccepted, models.DocumentUploadResponse{
        DocumentID:       "doc-" + uuid.NewString(),
        Status:           "UPLOADING",
        SumsubApplicantID: sumsubResult.ApplicantID,
    })
}

// 获取 Sumsub Access Token
func (h *KYCHandler) GetSumsubToken(c *gin.Context) {
    kycSessionID := c.Query("kyc_session_id")

    token, err := h.sumsubService.GenerateAccessToken(c.Request.Context(), kycSessionID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "access_token": token.AccessToken,
        "applicant_id": token.ApplicantID,
        "ttl":          600,
    })
}

// 状态检查
func (h *KYCHandler) CheckKYCStatus(c *gin.Context) {
    kycSessionID := c.Query("kyc_session_id")

    status, err := h.kycService.GetStatus(c.Request.Context(), kycSessionID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "session not found"})
        return
    }

    c.JSON(http.StatusOK, status)
}

// Webhook 处理（Sumsub）
func (h *KYCHandler) HandleSumsubWebhook(c *gin.Context) {
    // 1. 验证签名
    if !h.sumsubService.VerifyWebhookSignature(c.Request) {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid signature"})
        return
    }

    var payload models.SumsubWebhookPayload
    c.ShouldBindJSON(&payload)

    // 2. 异步处理（不阻塞 webhook 响应）
    go h.amlService.HandleSumsubReviewResult(context.Background(), payload)

    // 3. 立即返回 200 确认
    c.JSON(http.StatusOK, nil)
}

// 提交 KYC
func (h *KYCHandler) SubmitKYC(c *gin.Context) {
    kycSessionID := c.Query("kyc_session_id")

    // 1. 验证所有步骤已完成
    if err := h.kycService.ValidateCompletion(c.Request.Context(), kycSessionID); err != nil {
        c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
        return
    }

    // 2. 触发同步 OFAC 筛查
    sanctionsResult, _ := h.amlService.ScreenForSanctions(c.Request.Context(), kycSessionID)
    if sanctionsResult.Status == "HIT" {
        c.JSON(http.StatusUnavailableForLegalReasons, gin.H{"error": "Account restricted"})
        return
    }

    // 3. 账户进入 PENDING_AML_REVIEW
    account, _ := h.kycService.MarkKYCSubmitted(c.Request.Context(), kycSessionID)

    // 4. 发布异步 AML 筛查任务
    h.amlService.EnqueuePEPScreening(c.Request.Context(), account.AccountID)

    c.JSON(http.StatusAccepted, models.KYCSubmitResponse{
        AccountID:                account.ID,
        KYCStatus:                "PENDING",
        EstimatedReviewTimeHours: 24,
    })
}
```

---

## 11. gRPC Protobuf 定义

```protobuf
// api/grpc/kyc.proto

syntax = "proto3";

package ams.kyc;

import "google/protobuf/timestamp.proto";

service KYCService {
  rpc GetKYCStatus(GetKYCStatusRequest) returns (GetKYCStatusResponse);
  rpc SubmitKYCProfile(SubmitKYCProfileRequest) returns (SubmitKYCProfileResponse);
  rpc GetTaxFormStatus(GetTaxFormStatusRequest) returns (GetTaxFormStatusResponse);
}

message GetKYCStatusRequest {
  string account_id = 1;
}

message GetKYCStatusResponse {
  string status = 1; // PENDING, VERIFIED, REJECTED
  string tier = 2;   // BASIC, STANDARD, ENHANCED
  google.protobuf.Timestamp verified_at = 3;
  string rejection_reason = 4;
}

message SubmitKYCProfileRequest {
  string account_id = 1;
  string first_name = 2;
  string last_name = 3;
  google.protobuf.Timestamp date_of_birth = 4;
  string jurisdiction = 5;
  string ssn_encrypted = 6;     // 应用层加密前的密文
  string hkid_encrypted = 7;
}

message SubmitKYCProfileResponse {
  bool success = 1;
  string error_message = 2;
  string account_id = 3;
}

message GetTaxFormStatusRequest {
  string account_id = 1;
}

message GetTaxFormStatusResponse {
  string status = 1;                        // REQUIRED, NOT_REQUIRED, ACTIVE, EXPIRED, RENEWAL_PENDING
  string form_type = 2;                     // W9, W8BEN, CRS
  google.protobuf.Timestamp expiry_date = 3;
  int32 days_until_expiry = 4;
}
```

---

## 总结

本合约覆盖：
- ✅ 7 步完整 KYC 流程与 OpenAPI 3.0 规范
- ✅ Sumsub 集成（文件上传、活体检测、Webhook 处理）
- ✅ W-8BEN 生命周期与到期管理
- ✅ PII 加密存储（SSN/HKID）
- ✅ 文件存储协议（S3 预签名 URL）
- ✅ 状态轮询与 Push 通知
- ✅ 详细的错误处理与重试策略
- ✅ Dart 和 Go 代码生成规范
- ✅ gRPC 定义供下游服务调用

**Implementation Timeline**:
- Mobile (Flutter): 3 天（KYC UI + Sumsub SDK 集成）
- AMS (Go): 3 天（API handlers + Sumsub webhook + database）
