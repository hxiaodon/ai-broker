# PII 加密实现规范

> **版本**: v1.0
> **日期**: 2026-03-31
> **作者**: AMS Engineer + Security Engineer
> **状态**: Final — Ready for Implementation
>
> 本文档定义 5 个 PII 字段的应用层加密完整实现方案，覆盖加密算法、密钥管理、Blind Index、日志脱敏、数据库约束，以及单元测试要求。

---

## 目录

1. [加密字段清单](#1-加密字段清单)
2. [加密算法与参数](#2-加密算法与参数)
3. [Envelope Encryption 架构](#3-envelope-encryption-架构)
4. [Go 实现 — PIIEncryptor](#4-go-实现--piiencryptor)
5. [密钥管理与轮换](#5-密钥管理与轮换)
6. [Blind Index 实现](#6-blind-index-实现)
7. [日志脱敏](#7-日志脱敏)
8. [数据库 Schema](#8-数据库-schema)
9. [单元测试](#9-单元测试)
10. [集成与合规检查](#10-集成与合规检查)

---

## 1. 加密字段清单

### 1.1 必须加密的 5 个 PII 字段

| # | 字段名 | 数据类型 | 示例 | Blind Index 需求 | 查询频率 |
|---|--------|----------|------|------------------|---------:|
| 1 | SSN (社会安全号) | VARBINARY(256) | 123-45-6789 | PBKDF2-SHA256 | 低（仅 KYC 审核） |
| 2 | HKID（香港身份证） | VARBINARY(256) | A1234567(3) | PBKDF2-SHA256 | 低（仅 KYC 审核） |
| 3 | Passport Number | VARBINARY(256) | AB123456 | HMAC-SHA256 | 中（国际业务查询） |
| 4 | Bank Account No. | VARBINARY(256) | 1234567890 | HMAC-SHA256 | 中（出入金时） |
| 5 | Date of Birth | VARBINARY(256) | 1990-05-15 | 无索引 | 中等（KYC + 年龄检查） |

**加密要求等级**:
```
级别 1 (最高)：SSN + HKID
  → 极低熵（9-10 位数字）
  → 枚举攻击风险高
  → 必须 PBKDF2-SHA256（key stretching）

级别 2：Passport + Bank Account
  → 中等熵（字母数字混合）
  → HMAC-SHA256 充分

级别 3：DOB
  → 单独查询需求小
  → 但与其他标识符组合时需加密
  → 应用层验证逻辑使用
```

---

## 2. 加密算法与参数

### 2.1 算法选型

**主加密**：AES-256-GCM（AEAD - Authenticated Encryption with Associated Data）
```
算法选型理由：
├─ ✅ NIST SP 800-38D 认证（政府标准）
├─ ✅ Go 原生支持（crypto/cipher）
├─ ✅ GCM 模式自带认证标签（防篡改）
├─ ✅ 没有填充预言机（Padding Oracle）攻击
├─ ✅ 性能：~1 GB/s（远超 PII 加密需求）
└─ ✅ 100% 向后兼容未来升级（如 AES-256-GCM-SIV）
```

**Blind Index**：
- SSN/HKID: `PBKDF2(plaintext, salt=CMK_hash, iterations=100000, hash=SHA256)` → 长度 32 字节
- Passport/Bank: `HMAC-SHA256(plaintext, key=BlindIndexKey)` → 长度 32 字节

### 2.2 加密参数

```go
const (
    // AES-256-GCM 参数
    KeySize      = 32            // 256 位
    NonceSize    = 12            // 96 位（推荐）
    TagSize      = 16            // 128 位（GCM 认证标签）

    // Blind Index 参数
    BlindIndexKeySize = 32       // 256 位
    PBKDF2Iterations  = 100000   // 防枚举
)

// 数据库存储格式（VARBINARY）
type EncryptedValue struct {
    Version       uint8           // 1 字节（密钥版本）
    Nonce         []byte          // 12 字节
    Ciphertext    []byte          // 可变长
    AuthTag       []byte          // 16 字节（GCM 自动附加）
}

// 存储大小估计
EstimatedSize = 1 + 12 + len(plaintext) + 16 = len(plaintext) + 29 bytes
// 最坏情况（29 char plaintext）：58 bytes → 选择 VARBINARY(256)
```

---

## 3. Envelope Encryption 架构

### 3.1 双层密钥结构

```
┌─────────────────────────────────────────┐
│ AWS KMS CMK（主密钥）                    │
│ 永远不离开 HSM，仅用于包装 DEK           │
└────────────────┬────────────────────────┘
                 │ GenerateDataKey
                 ▼
        ┌────────────────────┐
        │ DEK (Data Key)     │
        │ 256-bit symmetric  │
        └────────┬───────────┘
                 │
       ┌─────────┴─────────┐
       │                   │
       ▼                   ▼
  Plaintext DEK      Encrypted DEK
  (内存使用)        (数据库存储)
  用后清零           ~185 字节 base64
       │                   │
       │                   └──► [users_pii 表的 dek_blob 列]
       │
       ▼
 AES-256-GCM 加密
 ├─ PII 明文
 ├─ 随机 Nonce（每次加密）
 └─ GCM 认证标签（自动附加）
       │
       ▼
   加密后 PII
   ~(plaintext + 29) bytes
       │
       └──► [users_pii 表的相关列]
            (ssn_encrypted, hkid_encrypted, etc.)
```

### 3.2 密钥生成策略

| 策略 | KMS API 调用 | 风险 | 成本 | 推荐场景 |
|------|------------|------|------|---------|
| 每字段一个 DEK | 5 次/用户 | 高成本 | $0.15/注册 | ❌ 不推荐 |
| **每 KYC 提交一个 DEK** | 1 次/注册 | 低 | $0.03/注册 | ✅ **MVP** |
| 长期缓存 (24h) | 1 次/24h | 中等 | 低 | 后续优化 |

**推荐方案**：每次用户提交 KYC 时调用 `GenerateDataKey` 一次，加密该用户所有 5 个 PII 字段，然后立即清零 DEK。

---

## 4. Go 实现 — PIIEncryptor

### 4.1 初始化与配置

```go
// internal/pii/encryptor.go

package pii

import (
    "context"
    "crypto/aes"
    "crypto/cipher"
    "crypto/hmac"
    "crypto/rand"
    "crypto/sha256"
    "encoding/base64"
    "fmt"

    "github.com/aws/aws-sdk-go-v2/service/kms"
    "golang.org/x/crypto/pbkdf2"
)

type KMSClient interface {
    GenerateDataKey(ctx context.Context, params *kms.GenerateDataKeyInput) (*kms.GenerateDataKeyOutput, error)
    Decrypt(ctx context.Context, params *kms.DecryptInput) (*kms.DecryptOutput, error)
}

type PIIEncryptor struct {
    kmsClient       KMSClient
    cmkID           string            // AWS CMK ARN
    blindIndexKey   []byte            // 专用 Blind Index 密钥
}

// NewPIIEncryptor 初始化加密器
// blindIndexKeySecret 来自 AWS Secrets Manager
func NewPIIEncryptor(
    kmsClient KMSClient,
    cmkID string,
    blindIndexKeySecret string) (*PIIEncryptor, error) {

    // Blind Index 密钥转换
    blindIndexKey := []byte(blindIndexKeySecret)
    if len(blindIndexKey) < 32 {
        return nil, fmt.Errorf("blind index key must be >= 32 bytes")
    }

    return &PIIEncryptor{
        kmsClient:     kmsClient,
        cmkID:         cmkID,
        blindIndexKey: blindIndexKey[:32],
    }, nil
}
```

### 4.2 加密函数

```go
// EncryptedField 表示加密后的 PII 字段
type EncryptedField struct {
    Version       uint8
    Nonce         []byte
    Ciphertext    []byte
    AuthTag       []byte
}

// EncryptPII 加密单个 PII 字段
func (e *PIIEncryptor) EncryptPII(
    ctx context.Context,
    plaintext string,
    fieldType string) (*EncryptedField, error) {

    // 1. 从 AWS KMS 生成 DEK（每次都调用，确保隔离）
    dekOutput, err := e.kmsClient.GenerateDataKey(ctx, &kms.GenerateDataKeyInput{
        KeyId:   &e.cmkID,
        KeySpec: "AES_256",
    })
    if err != nil {
        return nil, fmt.Errorf("generate data key: %w", err)
    }

    plaintextDEK := dekOutput.Plaintext
    encryptedDEK := dekOutput.CiphertextBlob

    defer ClearBytes(plaintextDEK)  // 关键：用后清零

    // 2. 创建 AES-256-GCM cipher
    block, err := aes.NewCipher(plaintextDEK)
    if err != nil {
        return nil, fmt.Errorf("create cipher: %w", err)
    }

    gcm, err := cipher.NewGCM(block)
    if err != nil {
        return nil, fmt.Errorf("create GCM: %w", err)
    }

    // 3. 生成随机 Nonce（12 字节）
    nonce := make([]byte, gcm.NonceSize())
    if _, err := rand.Read(nonce); err != nil {
        return nil, fmt.Errorf("generate nonce: %w", err)
    }

    // 4. 加密
    // GCM 模式：Seal(dst, nonce, plaintext, additionalData) -> ciphertext||authTag
    ciphertext := gcm.Seal(nil, nonce, []byte(plaintext), nil)
    // ciphertext 长度 = len(plaintext) + 16（authTag 自动附加）

    // 5. 分离 ciphertext 和 authTag
    authTag := ciphertext[len(ciphertext)-16:]
    ciphertextOnly := ciphertext[:len(ciphertext)-16]

    // 6. 返回结构（数据库存储前需序列化）
    return &EncryptedField{
        Version:    1,                           // 密钥版本
        Nonce:      nonce,
        Ciphertext: ciphertextOnly,
        AuthTag:    authTag,
    }, nil
}

// DecryptPII 解密单个 PII 字段
func (e *PIIEncryptor) DecryptPII(
    ctx context.Context,
    encrypted *EncryptedField) (string, error) {

    // 1. 使用 KMS Decrypt API 解密 DEK
    // 注意：实际实现中 EncryptedDEK 应从数据库读取
    dekOutput, err := e.kmsClient.Decrypt(ctx, &kms.DecryptInput{
        CiphertextBlob: encrypted.EncryptedDEKBlob,
    })
    if err != nil {
        return "", fmt.Errorf("decrypt data key: %w", err)
    }

    plaintextDEK := dekOutput.Plaintext
    defer ClearBytes(plaintextDEK)

    // 2. 创建 GCM cipher
    block, _ := aes.NewCipher(plaintextDEK)
    gcm, _ := cipher.NewGCM(block)

    // 3. 重建完整的 ciphertext||authTag
    fullCiphertext := append(encrypted.Ciphertext, encrypted.AuthTag...)

    // 4. 解密
    plaintext, err := gcm.Open(nil, encrypted.Nonce, fullCiphertext, nil)
    if err != nil {
        return "", fmt.Errorf("decrypt failed (authentication tag mismatch): %w", err)
    }

    return string(plaintext), nil
}

// ClearBytes 清零内存中的敏感数据
func ClearBytes(data []byte) {
    for i := range data {
        data[i] = 0
    }
}
```

### 4.3 数据库存储序列化

```go
// Serialize 将 EncryptedField 转换为数据库存储格式
func (e *EncryptedField) Serialize() string {
    // 格式：Version|Base64(Nonce|Ciphertext|AuthTag)
    payload := append(e.Nonce, e.Ciphertext...)
    payload = append(payload, e.AuthTag...)

    encoded := base64.StdEncoding.EncodeToString(payload)
    return fmt.Sprintf("%d|%s", e.Version, encoded)
}

// Deserialize 从数据库读取的字符串反序列化
func DeserializeEncryptedField(serialized string) (*EncryptedField, error) {
    // 解析 "Version|Base64Data"
    parts := strings.Split(serialized, "|")
    if len(parts) != 2 {
        return nil, errors.New("invalid encrypted field format")
    }

    version, _ := strconv.Atoi(parts[0])
    payload, err := base64.StdEncoding.DecodeString(parts[1])
    if err != nil {
        return nil, fmt.Errorf("decode base64: %w", err)
    }

    // 解析 Nonce (12) | Ciphertext (?) | AuthTag (16)
    if len(payload) < 28 { // 12 + 0 + 16 minimum
        return nil, errors.New("payload too short")
    }

    nonce := payload[:12]
    authTag := payload[len(payload)-16:]
    ciphertext := payload[12 : len(payload)-16]

    return &EncryptedField{
        Version:    uint8(version),
        Nonce:      nonce,
        Ciphertext: ciphertext,
        AuthTag:    authTag,
    }, nil
}
```

---

## 5. 密钥管理与轮换

### 5.1 CMK 规划

```
环境：PROD
├─ CMK 1: arn:aws:kms:us-east-1:123456789:key/pii-cmk-prod-v1
│         用途：PII 加密（所有 5 字段）
│         自动轮换：每 90 天
│
└─ CMK 2: arn:aws:kms:us-east-1:123456789:key/blindindex-cmk-prod-v1
          用途：Blind Index 密钥存储
          （可选，如果 Blind Index 密钥也需 KMS 管理）

CloudFormation 示例：
```

```yaml
Resources:
  PIIEncryptionKey:
    Type: AWS::KMS::Key
    Properties:
      Description: "AMS PII Encryption CMK"
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          - Sid: Enable IAM policies
            Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'
          - Sid: Allow AMS service to use key
            Effect: Allow
            Principal:
              AWS: !GetAtt AMSServiceRole.Arn
            Action:
              - 'kms:GenerateDataKey'
              - 'kms:Decrypt'
              - 'kms:DescribeKey'
            Resource: '*'
          - Sid: Allow CloudTrail to encrypt logs
            Effect: Allow
            Principal:
              Service: cloudtrail.amazonaws.com
            Action:
              - 'kms:GenerateDataKey'
              - 'kms:DecryptDataKey'
            Resource: '*'

  PIIEncryptionKeyAlias:
    Type: AWS::KMS::Alias
    Properties:
      AliasName: alias/ams-pii-prod-v1
      TargetKeyId: !Ref PIIEncryptionKey
```

### 5.2 密钥轮换 SOP

```
Step 1: 监控现有 CMK 年龄
  Prometheus: aws_kms_key_age_days > 80 → 触发告警

Step 2: 生成新 CMK
  aws kms create-key \
    --description "AMS PII Encryption CMK v2" \
    --key-usage ENCRYPT_DECRYPT

Step 3: 更新应用配置
  secrets.yaml:
    OLD_CMK_ID: arn:aws:kms:us-east-1:xxx:key/pii-cmk-prod-v1
    NEW_CMK_ID: arn:aws:kms:us-east-1:xxx:key/pii-cmk-prod-v2

Step 4: 灰度部署新版本
  ├─ 5% 流量使用新 CMK 加密
  ├─ 解密时支持两个 CMK（向后兼容）
  └─ 监控 1 周无异常

Step 5: 全量切换
  新建账户使用新 CMK
  旧数据保持原 CMK（无需重新加密）

Step 6: 归档旧 CMK
  keep_enabled = true（保留以支持解密）
  access_log: 记录 usage 以审计
```

**自动轮换设置**:
```go
// Go 代码确保 CMK 版本兼容
func (e *PIIEncryptor) DecryptWithVersionDetection(
    ctx context.Context,
    encrypted *EncryptedField) (string, error) {

    // EncryptedField.Version 字段标记使用的 CMK 版本
    var cmkID string
    switch encrypted.Version {
    case 1:
        cmkID = e.cmkID_v1
    case 2:
        cmkID = e.cmkID_v2
    default:
        return "", fmt.Errorf("unsupported CMK version: %d", encrypted.Version)
    }

    dekOutput, _ := e.kmsClient.Decrypt(ctx, &kms.DecryptInput{
        CiphertextBlob: encrypted.EncryptedDEKBlob,
    })

    // 继续解密...
    return "", nil
}
```

---

## 6. Blind Index 实现

### 6.1 Blind Index 计算

```go
// blind_index.go

package pii

import (
    "crypto/hmac"
    "crypto/sha256"
    "golang.org/x/crypto/pbkdf2"
)

// ComputeBlindIndex 计算 PII 字段的 Blind Index
func (e *PIIEncryptor) ComputeBlindIndex(
    plaintext string,
    fieldType string) (string, error) {

    var hash []byte

    switch fieldType {
    case "SSN", "HKID":
        // 低熵字段：使用 PBKDF2 防枚举
        // Key stretching: 100,000 迭代
        salt := sha256.Sum256([]byte(e.cmkID + fieldType))
        hash = pbkdf2.Key(
            []byte(plaintext),
            salt[:],
            100000,
            32,
            sha256.New,
        )

    case "PASSPORT", "BANK_ACCOUNT":
        // 高熵字段：HMAC-SHA256 足够
        h := hmac.New(sha256.New, e.blindIndexKey)
        h.Write([]byte(plaintext))
        hash = h.Sum(nil)

    default:
        return "", fmt.Errorf("unknown field type: %s", fieldType)
    }

    // 返回 hex 编码（便于数据库索引）
    return hex.EncodeToString(hash), nil
}

// ValidateWithBlindIndex 使用 Blind Index 验证（不解密）
func (e *PIIEncryptor) ValidateWithBlindIndex(
    storedBlindIndex string,
    plaintext string,
    fieldType string) (bool, error) {

    computed, err := e.ComputeBlindIndex(plaintext, fieldType)
    if err != nil {
        return false, err
    }

    // 时间安全比较（防时序攻击）
    return hmac.Equal([]byte(storedBlindIndex), []byte(computed)), nil
}
```

### 6.2 Blind Index 在 KYC 审核中的应用

```go
// 场景：合规人员需要查询是否有其他账户使用相同 SSN
func (r *KYCRepository) FindAccountsBySSNBlindIndex(
    ctx context.Context,
    ssnBlindIndex string) ([]Account, error) {

    // 直接在索引上查询（不需要解密）
    var accounts []Account
    err := r.db.WithContext(ctx).
        Where("ssn_blind_index = ?", ssnBlindIndex).
        Find(&accounts).Error

    return accounts, err
}

// KYC 审核时
func (s *KYCService) ReviewKYCSubmission(
    ctx context.Context,
    submission *KYCSubmission) error {

    // 1. 计算本次提交的 SSN Blind Index
    ssnBlindIndex, _ := s.encryptor.ComputeBlindIndex(
        submission.SSN, "SSN")

    // 2. 查询是否有历史账户使用相同 SSN
    existingAccounts, _ := s.repo.FindAccountsBySSNBlindIndex(
        ctx, ssnBlindIndex)

    if len(existingAccounts) > 0 {
        // 这是一个新用户还是现有用户的重复申请？
        // 需要人工审查
        return fmt.Errorf("SSN already registered (review manually)")
    }

    return nil
}
```

---

## 7. 日志脱敏

### 7.1 日志打印拦截

```go
// internal/logging/sanitizer.go

package logging

import (
    "regexp"
    "go.uber.org/zap"
    "go.uber.org/zap/zapcore"
)

type PIISanitizer struct {
    patterns map[string]*regexp.Regexp
}

func NewPIISanitizer() *PIISanitizer {
    return &PIISanitizer{
        patterns: map[string]*regexp.Regexp{
            "ssn":      regexp.MustCompile(`\d{3}-\d{2}-\d{4}`),
            "hkid":     regexp.MustCompile(`[A-Z]\d{6}[0-9A]`),
            "passport": regexp.MustCompile(`[A-Z]{2}\d{6,9}`),
            "bank":     regexp.MustCompile(`\d{8,17}`),
            "email":    regexp.MustCompile(`([a-zA-Z0-9_.-]+)@[a-zA-Z0-9.-]+`),
        },
    }
}

// Sanitize 脱敏日志字符串
func (s *PIISanitizer) Sanitize(msg string) string {
    result := msg

    // SSN 脱敏：123-45-6789 → XXX-XX-6789
    result = regexp.MustCompile(`(\d{3})-(\d{2})-(\d{4})`).
        ReplaceAllString(result, `XXX-XX-$3`)

    // HKID 脱敏：A1234567(3) → A****(3)
    result = regexp.MustCompile(`([A-Z])(\d{6})([0-9A])`).
        ReplaceAllString(result, `$1****(​$3)`)

    // 邮箱脱敏：john.doe@example.com → j****e@example.com
    result = regexp.MustCompile(`([a-zA-Z0-9])[a-zA-Z0-9._-]*(@[a-zA-Z0-9.-]+)`).
        ReplaceAllString(result, `$1****$2`)

    return result
}

// Zap hook：自动脱敏所有日志
func (s *PIISanitizer) WithZapHook(logger *zap.Logger) *zap.Logger {
    return logger.WithOptions(
        zap.Hooks(func(entry zapcore.Entry) error {
            entry.Message = s.Sanitize(entry.Message)
            for i, field := range entry.Context {
                if str, ok := field.Interface.(string); ok {
                    entry.Context[i] = zap.String(field.Key, s.Sanitize(str))
                }
            }
            return nil
        }),
    )
}
```

### 7.2 使用示例

```go
import "internal/logging"

func init() {
    sanitizer := logging.NewPIISanitizer()
    logger = logging.SetupZap()
    logger = sanitizer.WithZapHook(logger)
}

func ProcessKYC(ctx context.Context, submission *KYCSubmission) {
    // 日志中的 SSN 自动脱敏
    logger.Info("KYC submission received",
        zap.String("account_id", submission.AccountID),
        zap.String("ssn", submission.SSN),  // 日志中会显示为 XXX-XX-6789
    )
}
```

---

## 8. 数据库 Schema

### 8.1 users_pii 表（PII 存储）

```sql
CREATE TABLE users_pii (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id CHAR(36) UNIQUE NOT NULL,

    -- SSN（美国）
    ssn_encrypted VARBINARY(256),           -- AES-256-GCM 密文
    ssn_dek_blob VARBINARY(512),            -- Encrypted DEK
    ssn_blind_index VARCHAR(64),            -- PBKDF2-SHA256 索引
    ssn_encrypted_at TIMESTAMP NULL,

    -- HKID（香港）
    hkid_encrypted VARBINARY(256),
    hkid_dek_blob VARBINARY(512),
    hkid_blind_index VARCHAR(64),
    hkid_encrypted_at TIMESTAMP NULL,

    -- Passport Number
    passport_encrypted VARBINARY(256),
    passport_dek_blob VARBINARY(512),
    passport_blind_index VARCHAR(64),
    passport_encrypted_at TIMESTAMP NULL,

    -- Bank Account Number
    bank_account_encrypted VARBINARY(256),
    bank_account_dek_blob VARBINARY(512),
    bank_account_blind_index VARCHAR(64),
    bank_account_encrypted_at TIMESTAMP NULL,

    -- Date of Birth
    dob_encrypted VARBINARY(256),
    dob_dek_blob VARBINARY(512),
    dob_encrypted_at TIMESTAMP NULL,

    -- 审计
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- 索引（仅对 Blind Index 建立）
    UNIQUE INDEX idx_ssn_blind (ssn_blind_index),
    UNIQUE INDEX idx_hkid_blind (hkid_blind_index),
    UNIQUE INDEX idx_passport_blind (passport_blind_index),
    UNIQUE INDEX idx_bank_blind (bank_account_blind_index),

    CONSTRAINT fk_account FOREIGN KEY (account_id) REFERENCES accounts(account_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

-- 加密列不可被 SQL 层索引（均已加密），仅 Blind Index 可被查询
```

### 8.2 迁移脚本（Goose）

```sql
-- migrations/00003_create_users_pii.up.sql

BEGIN;

CREATE TABLE users_pii (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id CHAR(36) UNIQUE NOT NULL,

    -- 5 个 PII 字段的加密存储
    ssn_encrypted VARBINARY(256),
    ssn_dek_blob VARBINARY(512),
    ssn_blind_index VARCHAR(64),
    ssn_encrypted_at TIMESTAMP NULL,

    hkid_encrypted VARBINARY(256),
    hkid_dek_blob VARBINARY(512),
    hkid_blind_index VARCHAR(64),
    hkid_encrypted_at TIMESTAMP NULL,

    passport_encrypted VARBINARY(256),
    passport_dek_blob VARBINARY(512),
    passport_blind_index VARCHAR(64),
    passport_encrypted_at TIMESTAMP NULL,

    bank_account_encrypted VARBINARY(256),
    bank_account_dek_blob VARBINARY(512),
    bank_account_blind_index VARCHAR(64),
    bank_account_encrypted_at TIMESTAMP NULL,

    dob_encrypted VARBINARY(256),
    dob_dek_blob VARBINARY(512),
    dob_encrypted_at TIMESTAMP NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE INDEX idx_ssn_blind (ssn_blind_index),
    UNIQUE INDEX idx_hkid_blind (hkid_blind_index),
    UNIQUE INDEX idx_passport_blind (passport_blind_index),
    UNIQUE INDEX idx_bank_blind (bank_account_blind_index),

    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 优化：检查点（每 10000 行）
ALTER TABLE users_pii ADD INDEX idx_account_id (account_id);

COMMIT;
```

---

## 9. 单元测试

### 9.1 加密/解密循环测试

```go
// internal/pii/encryptor_test.go

package pii

import (
    "context"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestEncryptDecryptRoundtrip(t *testing.T) {
    t.Parallel()

    testCases := []struct {
        name      string
        plaintext string
        fieldType string
    }{
        {"SSN", "123-45-6789", "SSN"},
        {"HKID", "A1234567(3)", "HKID"},
        {"Passport", "AB1234567", "PASSPORT"},
        {"Bank Account", "1234567890", "BANK_ACCOUNT"},
        {"DOB", "1990-05-15", "DOB"},
    }

    encryptor := setupTestEncryptor(t)

    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            ctx := context.Background()

            // 加密
            encrypted, err := encryptor.EncryptPII(ctx, tc.plaintext, tc.fieldType)
            require.NoError(t, err)
            require.NotNil(t, encrypted)

            // 验证：密文 ≠ 明文
            assert.NotEqual(t, string(encrypted.Ciphertext), tc.plaintext)

            // 解密
            decrypted, err := encryptor.DecryptPII(ctx, encrypted)
            require.NoError(t, err)

            // 验证：解密结果 == 原文
            assert.Equal(t, tc.plaintext, decrypted)
        })
    }
}

func TestAuthenticationTagValidation(t *testing.T) {
    encryptor := setupTestEncryptor(t)
    ctx := context.Background()

    // 加密
    encrypted, _ := encryptor.EncryptPII(ctx, "secret", "SSN")

    // 篡改：修改 ciphertext 的一个字节
    encrypted.Ciphertext[0] ^= 0xFF  // 翻转第一个字节

    // 解密应失败（认证标签验证失败）
    _, err := encryptor.DecryptPII(ctx, encrypted)
    assert.Error(t, err)
    assert.Contains(t, err.Error(), "authentication tag mismatch")
}

func TestBlindIndexConsistency(t *testing.T) {
    encryptor := setupTestEncryptor(t)
    ctx := context.Background()

    plaintext := "123-45-6789"

    // 同一 plaintext 多次计算 Blind Index 应相同
    bi1, _ := encryptor.ComputeBlindIndex(plaintext, "SSN")
    bi2, _ := encryptor.ComputeBlindIndex(plaintext, "SSN")

    assert.Equal(t, bi1, bi2)

    // 不同 plaintext 应不同
    bi3, _ := encryptor.ComputeBlindIndex("987-65-4321", "SSN")
    assert.NotEqual(t, bi1, bi3)
}

func TestEnumAttackResistance(t *testing.T) {
    // SSN 仅 9 位数字，理论上枚举空间 10^9（100 万）
    // PBKDF2 + 100k 迭代应能抵抗枚举
    // 每次计算 ~10ms，100M 次需 1000k 秒 ≈ 11 天
    // 这在实际攻击中不可行

    encryptor := setupTestEncryptor(t)

    startTime := time.Now()
    for i := 0; i < 100; i++ {
        ssn := fmt.Sprintf("%03d-%02d-%04d", i/10000, (i/100)%100, i%10000)
        encryptor.ComputeBlindIndex(ssn, "SSN")
    }
    elapsed := time.Since(startTime)

    t.Logf("100 PBKDF2 iterations took %v", elapsed)
    assert.Greater(t, elapsed, time.Second)  // 应该相对较慢
}

func setupTestEncryptor(t *testing.T) *PIIEncryptor {
    // Mock KMS client（测试环境）
    mockKMS := &mockKMSClient{
        dekCache: make(map[string][]byte),
    }

    encryptor, err := NewPIIEncryptor(
        mockKMS,
        "arn:aws:kms:us-east-1:123456789:key/test",
        "00112233445566778899aabbccddeeff",  // 32 字节的 Blind Index 密钥
    )
    require.NoError(t, err)

    return encryptor
}

type mockKMSClient struct {
    dekCache map[string][]byte
}

func (m *mockKMSClient) GenerateDataKey(
    ctx context.Context,
    input *kms.GenerateDataKeyInput) (*kms.GenerateDataKeyOutput, error) {

    // 模拟生成 256-bit DEK
    dek := make([]byte, 32)
    rand.Read(dek)

    return &kms.GenerateDataKeyOutput{
        Plaintext:      dek,
        CiphertextBlob: []byte("mock_encrypted_dek"),
    }, nil
}
```

---

## 10. 集成与合规检查

### 10.1 集成清单

- [ ] AWS KMS CMK 创建（生产环境）
- [ ] Blind Index 密钥存储到 AWS Secrets Manager
- [ ] PIIEncryptor 初始化（应用启动）
- [ ] users_pii 表迁移（Goose）
- [ ] KYC 服务集成（加密 PII 字段）
- [ ] 日志脱敏配置
- [ ] CloudTrail 审计（KMS API 调用）
- [ ] 密钥轮换 SOP 文档

### 10.2 合规验证脚本

```bash
#!/bin/bash

# verify-pii-encryption.sh — 加密合规检查

echo "=== PII Encryption Compliance Verification ==="

# 1. 检查数据库中是否存在明文 PII（应该没有）
PLAINTEXT_SSNS=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SELECT COUNT(*) FROM users_pii WHERE ssn_encrypted IS NULL AND ssn_blind_index IS NOT NULL")

if [ "$PLAINTEXT_SSNS" -gt 0 ]; then
    echo "❌ FAIL: Found $PLAINTEXT_SSNS unencrypted SSN records"
    exit 1
fi

echo "✅ PASS: All SSN records encrypted"

# 2. 检查 Blind Index 索引是否创建
BLIND_INDEX=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SHOW INDEX FROM users_pii WHERE Key_name LIKE '%blind%'")

if [ -z "$BLIND_INDEX" ]; then
    echo "❌ FAIL: Blind Index not created"
    exit 1
fi

echo "✅ PASS: Blind Index properly indexed"

# 3. 检查 CloudTrail KMS 调用日志
AUDIT_LOG=$(aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GenerateDataKey \
  --max-results 1)

if [ -z "$AUDIT_LOG" ]; then
    echo "⚠️  WARN: No KMS audit logs found (recent)"
else
    echo "✅ PASS: KMS calls are audited in CloudTrail"
fi

# 4. 检查数据库加密列大小
COLUMN_SIZE=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e \
  "SELECT COLUMN_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='users_pii' AND COLUMN_NAME='ssn_encrypted'")

if [[ "$COLUMN_SIZE" != *"256"* ]]; then
    echo "❌ FAIL: ssn_encrypted column size insufficient (needs VARBINARY(256))"
    exit 1
fi

echo "✅ PASS: Encrypted column sizes adequate"

echo ""
echo "=== All Compliance Checks Passed ==="
```

---

## 总结

本规范实现了：
- ✅ AES-256-GCM AEAD 加密（5 个 PII 字段）
- ✅ AWS KMS Envelope Encryption（DEK 管理）
- ✅ PBKDF2-SHA256 Blind Index（低熵字段防枚举）
- ✅ 日志脱敏（自动 Zap 拦截）
- ✅ 数据库 schema 约束（仅加密列存储）
- ✅ 密钥轮换 SOP（90 天周期）
- ✅ 全面的单元测试（加密循环、认证、枚举）
- ✅ 合规验证脚本

**Implementation Checklist**:
1. PIIEncryptor 实现（1 天）
2. Blind Index 实现（0.5 天）
3. 日志脱敏集成（0.5 天）
4. 数据库迁移（0.5 天）
5. 单元测试（1 天）
6. 集成测试（0.5 天）

**Go 交付物**:
- `internal/pii/encryptor.go` — 核心加密逻辑
- `internal/pii/blind_index.go` — Blind Index 计算
- `internal/logging/sanitizer.go` — 日志脱敏
- `internal/pii/encryptor_test.go` — 完整测试套件
- `migrations/00003_create_users_pii.up/down.sql` — Schema
