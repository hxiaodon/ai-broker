# AMS Tech Spec: PII 加密规格

> **版本**: v0.1
> **日期**: 2026-03-17
> **作者**: AMS Engineering
> **状态**: Draft — 待安全评审
>
> 本文档定义 AMS 对 PII（个人可识别信息）字段的加密存储方案，包括 KMS 选型、Envelope Encryption 实现、可检索加密（Blind Index）、Zap 日志脱敏，以及数据库存储设计。

---

## 目录

1. [强制合规要求](#1-强制合规要求)
2. [KMS 选型决策](#2-kms-选型决策)
3. [Envelope Encryption 架构](#3-envelope-encryption-架构)
4. [Go 实现（AWS KMS + Tink）](#4-go-实现aws-kms--tink)
5. [可检索加密：HMAC Blind Index](#5-可检索加密hmac-blind-index)
6. [PII 类型系统（日志脱敏）](#6-pii-类型系统日志脱敏)
7. [数据库存储设计](#7-数据库存储设计)
8. [密钥轮换 SOP](#8-密钥轮换-sop)
9. [开发环境配置](#9-开发环境配置)

---

## 1. 强制合规要求

来自 `.claude/rules/security-compliance.md`，以下 PII 字段**必须**在应用层进行 AES-256-GCM 加密后再写入 MySQL：

| 字段 | 加密级别 | Blind Index | 备注 |
|------|----------|-------------|------|
| SSN（美国社会安全号） | AES-256-GCM | PBKDF2-SHA256（防枚举） | 9位数字，低熵，须 key-stretching |
| HKID（香港身份证） | AES-256-GCM | PBKDF2-SHA256（防枚举） | 格式有限，须 key-stretching |
| 护照号 | AES-256-GCM | HMAC-SHA256 | 高熵，普通 HMAC 足够 |
| 银行账号 | AES-256-GCM | HMAC-SHA256 | 须保密，但空间大 |
| 出生日期（与其他标识符组合时） | AES-256-GCM | 无需索引 | 单独 DOB 无查询需求 |

---

## 2. KMS 选型决策

**选型：AWS KMS（标准对称 CMK）**

### 2.1 三方对比

| 维度 | **AWS KMS** | GCP Cloud KMS | Vault Transit |
|------|-------------|---------------|---------------|
| DEK 生成 | 服务端（`GenerateDataKey`） | 客户端生成 | 服务端（`datakey` 端点） |
| 可用性 SLA | **99.999%** | 99.9% | 自托管 / 99.9%（HCP） |
| HSM 背书 | **FIPS 140-2 Level 2（默认）** | Level 1（软件，默认） | 需额外配置 |
| 成本（每月） | $1/CMK + $0.03/1万次 API 调用 | $0.06/密钥版本 | 免费（OSS）/ ~$51k/yr（企业） |
| API p99 延迟（同区域） | ~20-50ms | ~15-30ms | ~0.63ms（服务端） |
| Go SDK | `aws-sdk-go-v2/service/kms` | `cloud.google.com/go/kms` | `hashicorp/vault/api` |
| 多区域 DR | ✅ 原生支持 | 手动复制 | 企业版专属 |
| CloudTrail 审计集成 | ✅ 开箱即用 | ❌ 额外配置 | 需 Vault Audit Logs |
| 创业团队适用性 | **最佳** | 若在 GCP 上可用 | 仅已有 Vault 基础设施时 |

### 2.2 选 AWS KMS 的理由

1. **99.999% SLA**：比 GCP（99.9%）高出两个九，对合规敏感的金融平台至关重要
2. **零运维**：无服务端需要维护；CloudTrail 自动记录所有密钥使用（满足 SEC 17a-4 审计要求）
3. **`GenerateDataKey` API**：服务端生成 DEK，比 GCP 的客户端生成模式更简洁，代码更少
4. **成本极低**：1 个 CMK（$1/月）+ 开户时 DEK 生成 + 读取时解密，月费 ~$2-5

### 2.3 CMK 规划

| 环境 | CMK 数量 | 命名约定 | 用途 |
|------|----------|----------|------|
| 生产 | 2 | `ams-pii-prod-v1`、`ams-blindindex-prod-v1` | PII 加密、Blind Index 密钥 |
| 预生产 | 2 | `ams-pii-staging-v1`、`ams-blindindex-staging-v1` | — |
| 开发/测试 | 本地 mock（无 KMS） | — | 测试用假密钥 |

---

## 3. Envelope Encryption 架构

### 3.1 原理

```
AWS KMS CMK（Master Key，永不离开 KMS HSM）
    │
    │ GenerateDataKey（每次 KYC 提交调用一次）
    ▼
DEK（数据加密密钥，32字节 AES-256）
    ├── Plaintext DEK：在内存中使用，用后立即清零
    └── Encrypted DEK（CiphertextBlob，~185字节）：存入 MySQL
            │
            │ 用 Plaintext DEK 加密
            ▼
    AES-256-GCM 加密的 PII（SSN/HKID/etc.）
    + 随机 12字节 Nonce
    + 16字节 GCM 认证标签（自动附加）
    = 存入 MySQL（VARBINARY 列）
```

**解密时**：取出 `Encrypted DEK` → 调用 KMS `Decrypt` → 获得 `Plaintext DEK` → 解密 PII → 清零 DEK。

### 3.2 每次请求 vs DEK 缓存

| 策略 | KMS API 调用 | 安全性 | 推荐场景 |
|------|-------------|--------|---------|
| 每字段一个 DEK | 最多（每个 PII 字段调用一次） | 最高（字段隔离） | 不推荐（成本高） |
| 每 KYC 提交一个 DEK | 1 次 `GenerateDataKey` | 高（单次提交隔离） | **推荐**（MVP） |
| 短期缓存（5分钟 TTL） | 最少 | 稍低（内存中更长时间） | 批量处理场景 |

**建议**：每次 KYC 提交调用一次 `GenerateDataKey`，获取 DEK 后加密该用户所有 PII 字段，然后立即清零。**不跨用户复用 DEK**。

---

## 4. Go 实现（AWS KMS + Tink）

### 4.1 为什么使用 Tink

`github.com/tink-crypto/tink-go/v2` 相比原生 `crypto/cipher`：
- **自动 Nonce 生成**：防止 GCM Nonce 复用（致命漏洞）
- **KeysetHandle 版本管理**：密文前缀自动嵌入 key_id（无需额外存储 key_version）
- **AWS KMS 原生集成**：`awskms.NewClientWithOptions` 一行代码
- **算法升级免代码变更**：将来切换 AES-256-GCM-SIV 只需更换 Key Template

> **注意**：`github.com/google/tink/go` 已归档，使用 `github.com/tink-crypto/tink-go/v2`。

### 4.2 PIIEncryptor 完整实现

```go
package piiencrypt

import (
    "context"
    "fmt"

    "github.com/tink-crypto/tink-go/v2/aead"
    "github.com/tink-crypto/tink-go/v2/integration/awskms"
    "github.com/tink-crypto/tink-go/v2/keyset"
    tinkaead "github.com/tink-crypto/tink-go/v2/aead"
)

type PIIEncryptor struct {
    aeadPrimitive tinkgo.AEAD
    keysetHandle  *keyset.Handle
}

// NewPIIEncryptor 初始化 AWS KMS 支持的 Tink AEAD
// cmkARN: AWS CMK ARN，格式 "arn:aws:kms:region:account:key/..."
func NewPIIEncryptor(ctx context.Context, cmkARN string) (*PIIEncryptor, error) {
    // 1. 注册 AWS KMS 客户端（使用默认 AWS SDK 凭证链）
    kmsClient, err := awskms.NewClientWithOptions("aws-kms://" + cmkARN)
    if err != nil {
        return nil, fmt.Errorf("init aws kms client: %w", err)
    }

    // 2. 为 CMK 创建关联的 AEAD（用于包装 Tink Keyset）
    // 在生产中，Keyset 从持久化存储加载（加密存储于 AWS Secrets Manager）
    // 首次初始化时创建新 Keyset：
    handle, err := keyset.NewHandle(aead.AES256GCMKeyTemplate())
    if err != nil {
        return nil, fmt.Errorf("create keyset: %w", err)
    }

    // 将 Keyset 以 KMS 加密保存到 Secrets Manager（此处仅示意）
    // 生产代码：从 Secrets Manager 加载已存在的 Keyset
    _ = kmsClient // 实际用于 keyset encryption/decryption

    a, err := tinkaead.New(handle)
    if err != nil {
        return nil, fmt.Errorf("init aead: %w", err)
    }

    return &PIIEncryptor{aeadPrimitive: a, keysetHandle: handle}, nil
}

// Encrypt 加密 PII 明文
// additionalData：关联数据，如 account_id（防止密文被移植到其他账户）
func (e *PIIEncryptor) Encrypt(plaintext, additionalData []byte) ([]byte, error) {
    ciphertext, err := e.aeadPrimitive.Encrypt(plaintext, additionalData)
    if err != nil {
        return nil, fmt.Errorf("encrypt pii: %w", err)
    }
    return ciphertext, nil
}

// Decrypt 解密 PII
func (e *PIIEncryptor) Decrypt(ciphertext, additionalData []byte) ([]byte, error) {
    plaintext, err := e.aeadPrimitive.Decrypt(ciphertext, additionalData)
    if err != nil {
        // 认证失败 = 密文被篡改或 additionalData 不匹配
        return nil, fmt.Errorf("decrypt pii (auth failed or wrong key): %w", err)
    }
    return plaintext, nil
}
```

**使用示例（KYC 提交时）**：

```go
func (s *KYCService) SaveKYCProfile(ctx context.Context, accountID string, profile *KYCSubmission) error {
    // additionalData 绑定加密到该账户，防止密文被复制到其他账户
    aad := []byte(accountID)

    encSSN, err := s.encryptor.Encrypt([]byte(profile.SSN.Plaintext()), aad)
    if err != nil {
        return fmt.Errorf("encrypt ssn: %w", err)
    }

    encHKID, err := s.encryptor.Encrypt([]byte(profile.HKID.Plaintext()), aad)
    if err != nil {
        return fmt.Errorf("encrypt hkid: %w", err)
    }

    // 计算 Blind Index（用于重复检测）
    ssnBidx := s.blindIndexer.ComputeSSN(profile.SSN.Plaintext())

    return s.repo.SaveEncryptedKYC(ctx, &EncryptedKYCRecord{
        AccountID:       accountID,
        SSNEncrypted:    encSSN,
        HKIDEncrypted:   encHKID,
        SSNBlindIndex:   ssnBidx,
    })
}
```

### 4.3 原生 crypto/cipher 实现（备选）

如果不使用 Tink，以下是手动 AES-256-GCM + AWS KMS 的实现：

```go
// EncryptedField 存储格式（MySQL VARBINARY 列中的 JSON）
type EncryptedField struct {
    CiphertextDEK []byte `json:"kdek"` // KMS 加密的 DEK（~185 bytes）
    Nonce         []byte `json:"n"`    // 12 bytes 随机 nonce
    Ciphertext    []byte `json:"c"`    // AES-256-GCM 密文（含 16 bytes GCM tag）
    KeyVersion    string `json:"kv"`   // CMK ARN，用于审计
}

func Encrypt(ctx context.Context, kmsClient *kms.Client, cmkARN string, plaintext []byte) (*EncryptedField, error) {
    // 1. 生成 DEK
    resp, err := kmsClient.GenerateDataKey(ctx, &kms.GenerateDataKeyInput{
        KeyId:   aws.String(cmkARN),
        KeySpec: types.DataKeySpecAes256,
    })
    if err != nil {
        return nil, fmt.Errorf("kms GenerateDataKey: %w", err)
    }
    defer zeroize(resp.Plaintext) // 用后立即清零

    // 2. 生成随机 Nonce
    nonce := make([]byte, 12)
    if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
        return nil, fmt.Errorf("rand nonce: %w", err)
    }

    // 3. AES-256-GCM 加密
    block, _ := aes.NewCipher(resp.Plaintext)
    gcm, _ := cipher.NewGCM(block)
    ciphertext := gcm.Seal(nil, nonce, plaintext, nil) // 自动附加 16 bytes GCM tag

    return &EncryptedField{
        CiphertextDEK: resp.CiphertextBlob,
        Nonce:         nonce,
        Ciphertext:    ciphertext,
        KeyVersion:    aws.ToString(resp.KeyId),
    }, nil
}

func zeroize(b []byte) {
    for i := range b { b[i] = 0 }
}
```

---

## 5. 可检索加密：HMAC Blind Index

### 5.1 问题

AES-256-GCM 加密后的字段无法直接使用 B-Tree 索引。但 AMS 有以下查询需求：
- **开户时重复检测**："该 SSN 是否已存在于系统中？"
- **HKID 去重**："该 HKID 是否已有账户？"

**绝不使用确定性加密**（如 AES-CBC 固定 IV）：会泄露相同值的存在，违反加密语义安全性。

### 5.2 解决方案：HMAC Blind Index

存储 `f(secret_key, plaintext)` 的不可逆摘要作为独立索引列。攻击者即使获得数据库也无法反推明文。

### 5.3 密钥选择

| 字段 | 算法 | 理由 |
|------|------|------|
| SSN（9位数字，10^9种可能） | **PBKDF2-SHA256**（10万次迭代） | 低熵，防止枚举攻击（每次 HMAC 计算耗时 ~100ms，枚举所有 SSN 需数年） |
| HKID（格式受限） | **PBKDF2-SHA256**（10万次迭代） | 同上 |
| 护照号（约 10^12 种可能） | **HMAC-SHA256** | 高熵，暴力枚举不可行 |
| 银行账号 | **HMAC-SHA256** | 高熵 |

Blind Index 密钥（`BLIND_INDEX_SECRET`）存储于 **AWS Secrets Manager**，独立于 KMS CMK。

### 5.4 实现

```go
package blindindex

import (
    "crypto/hmac"
    "crypto/sha256"
    "strings"
    "regexp"
    "unicode"

    "golang.org/x/crypto/pbkdf2"
)

// BlindIndexer 持有 Blind Index 密钥
type BlindIndexer struct {
    secret []byte // 从 AWS Secrets Manager 加载，不得硬编码
}

// ComputeSSN 计算 SSN 的 Blind Index（PBKDF2，防枚举）
// 返回 32 字节摘要，存入 BINARY(32) 列
func (b *BlindIndexer) ComputeSSN(ssn string) []byte {
    normalized := normalizeSSN(ssn) // "123-45-6789" → "123456789"
    return pbkdf2.Key([]byte(normalized), b.secret, 100_000, 32, sha256.New)
}

// ComputeHKID 计算 HKID 的 Blind Index（PBKDF2，防枚举）
func (b *BlindIndexer) ComputeHKID(hkid string) []byte {
    normalized := normalizeHKID(hkid) // "A123456(3)" → "A1234563"
    return pbkdf2.Key([]byte(normalized), b.secret, 100_000, 32, sha256.New)
}

// ComputePassport 计算护照号的 Blind Index（HMAC，高熵无需 key-stretching）
func (b *BlindIndexer) ComputePassport(passport string) []byte {
    normalized := normalizePassport(passport)
    mac := hmac.New(sha256.New, b.secret)
    mac.Write([]byte(normalized))
    return mac.Sum(nil)
}

// ComputeBankAccount 计算银行账号的 Blind Index
func (b *BlindIndexer) ComputeBankAccount(account string) []byte {
    normalized := strings.TrimSpace(account)
    mac := hmac.New(sha256.New, b.secret)
    mac.Write([]byte(normalized))
    return mac.Sum(nil)
}

// normalizeSSN 标准化 SSN 格式（去除连字符和空格）
func normalizeSSN(ssn string) string {
    return strings.Map(func(r rune) rune {
        if unicode.IsDigit(r) { return r }
        return -1
    }, ssn)
}

// normalizeHKID 标准化 HKID 格式（大写，去除特殊符号）
func normalizeHKID(hkid string) string {
    hkid = strings.ToUpper(strings.TrimSpace(hkid))
    return regexp.MustCompile(`[^A-Z0-9]`).ReplaceAllString(hkid, "")
}

func normalizePassport(p string) string {
    return strings.ToUpper(strings.TrimSpace(p))
}
```

### 5.5 查询示例

```go
// 检查 SSN 是否已存在（开户时去重）
func (r *KYCRepository) SSNExists(ctx context.Context, ssn string) (bool, error) {
    bidx := r.blindIndexer.ComputeSSN(ssn)
    var count int
    err := r.db.QueryRowContext(ctx,
        "SELECT COUNT(*) FROM account_kyc_profiles WHERE ssn_bidx = ?",
        bidx,
    ).Scan(&count)
    return count > 0, err
}
```

---

## 6. PII 类型系统（日志脱敏）

### 6.1 设计原则

将敏感字段封装为 Go 类型，使**脱敏成为默认行为**，明文访问需要显式调用。利用 Go 编译器作为安全守卫：
- `fmt.Sprintf("%v", ssn)` → `"***-**-1234"`（自动脱敏）
- `zap.Any("ssn", ssn)` → `"***-**-1234"`（自动脱敏）
- `ssn.Plaintext()` → `"123456789"`（显式访问，可 grep 审计）

### 6.2 核心类型

```go
// SSN 类型：不可反向的敏感字符串封装
type SSN struct{ value string } // 未导出字段

func NewSSN(v string) (SSN, error) {
    normalized := normalizeSSN(v)
    if !isValidSSN(normalized) {
        return SSN{}, errors.New("invalid SSN format")
    }
    return SSN{value: normalized}, nil
}

// String 实现 fmt.Stringer，所有格式化自动脱敏
func (s SSN) String() string {
    if len(s.value) < 4 { return "***-**-****" }
    return "***-**-" + s.value[len(s.value)-4:]
}

// MarshalJSON：JSON 序列化自动脱敏
func (s SSN) MarshalJSON() ([]byte, error) {
    return []byte(`"` + s.String() + `"`), nil
}

// MarshalLogObject：Zap 结构化日志自动脱敏
func (s SSN) MarshalLogObject(enc zapcore.ObjectEncoder) error {
    enc.AddString("ssn", s.String())
    return nil
}

// Plaintext：唯一能获取明文的方法，全局 grep 可审计
func (s SSN) Plaintext() string { return s.value }

// HKID 类型："A123456(3)" → "A****(3)"
type HKID struct{ value string }

func (h HKID) String() string {
    if len(h.value) == 0 { return "****" }
    // 保留字母前缀 + 括号内检查码
    prefixEnd := 0
    for prefixEnd < len(h.value) && h.value[prefixEnd] >= 'A' { prefixEnd++ }
    prefix := h.value[:prefixEnd]
    checkPart := ""
    if idx := strings.Index(h.value, "("); idx != -1 { checkPart = h.value[idx:] }
    return prefix + "****" + checkPart
}
func (h HKID) MarshalJSON() ([]byte, error) { return []byte(`"` + h.String() + `"`), nil }
func (h HKID) Plaintext() string { return h.value }

// BankAccount 类型：只显示末 4 位
type BankAccount struct{ value string }
func (b BankAccount) String() string {
    if len(b.value) <= 4 { return "****" }
    return "****" + b.value[len(b.value)-4:]
}
func (b BankAccount) MarshalJSON() ([]byte, error) { return []byte(`"` + b.String() + `"`), nil }
func (b BankAccount) Plaintext() string { return b.value }
```

### 6.3 领域结构体中使用 PII 类型

```go
// KYCProfile 中所有敏感字段使用 PII 类型，而非 string
type KYCProfile struct {
    AccountID    string
    FullName     string           // 姓名不在加密字段中（但不应出现在日志里）
    SSN          piitypes.SSN     // 自动脱敏
    HKID         piitypes.HKID    // 自动脱敏
    PassportNo   string           // TODO: 为护照号创建 piitypes.Passport
    BankAccounts []piitypes.BankAccount
    DOB          time.Time
}

// 日志记录（自动脱敏）
logger.Info("kyc profile submitted",
    zap.Object("profile", MaskedKYCProfile{
        AccountID: p.AccountID,
        SSN:       p.SSN,   // zap 调用 MarshalLogObject → "***-**-1234"
        HKID:      p.HKID,  // → "A****(3)"
    }),
)
```

### 6.4 Zap 兜底正则脱敏（防止漏网）

```go
// piiRedactCore 拦截所有 string 类型字段，做正则兜底检测
type piiRedactCore struct{ zapcore.Core }

var ssnPattern = regexp.MustCompile(`\b\d{3}-\d{2}-\d{4}\b`)
var hkidPattern = regexp.MustCompile(`\b[A-Z]{1,2}\d{6}\([0-9A]\)\b`)

func (c *piiRedactCore) Write(entry zapcore.Entry, fields []zapcore.Field) error {
    for i, f := range fields {
        if f.Type == zapcore.StringType {
            s := ssnPattern.ReplaceAllString(f.String, "***-**-****")
            s = hkidPattern.ReplaceAllString(s, "****REDACTED****")
            fields[i].String = s
        }
    }
    return c.Core.Write(entry, fields)
}
```

---

## 7. 数据库存储设计

### 7.1 列类型规范

| 存储内容 | MySQL 类型 | 理由 |
|----------|-----------|------|
| Tink 加密的 PII 字段 | `VARBINARY(1024)` | 二进制存储，无字符集转换，无 base64 开销 |
| HMAC Blind Index | `BINARY(32)` | 固定 32 字节，精确匹配 |
| Key version（仅原生实现） | `VARCHAR(255)` | CMK ARN 或版本标识 |

**绝不使用 TEXT/VARCHAR 存储密文**：MySQL 字符集转换会静默损坏字节。

### 7.2 account_kyc_profiles 字段更新

在 `account-financial-model.md` 的 `account_kyc_profiles` 表基础上：

```sql
ALTER TABLE account_kyc_profiles
    -- 加密列（Tink 格式：5字节前缀 + nonce + ciphertext + GCM tag）
    MODIFY id_number_encrypted  VARBINARY(1024) NOT NULL COMMENT 'Tink AES-256-GCM encrypted SSN/HKID/passport',
    MODIFY dob_encrypted        VARBINARY(512)  NOT NULL COMMENT 'Tink AES-256-GCM encrypted DOB',
    MODIFY full_name_encrypted  VARBINARY(1024) NOT NULL COMMENT 'Tink AES-256-GCM encrypted full name',

    -- Blind Index 列（精确匹配查询）
    ADD COLUMN id_number_bidx   BINARY(32)      NULL COMMENT 'PBKDF2/HMAC blind index for dup detection',
    ADD COLUMN full_name_bidx   BINARY(32)      NULL COMMENT 'HMAC blind index for name search',

    -- 密钥版本追踪（Tink 模式下此字段用于轮换审计）
    ADD COLUMN pii_key_version  VARCHAR(50)     NOT NULL DEFAULT '' COMMENT 'Tink keyset primary key ID',

    ADD UNIQUE INDEX uk_id_number_bidx (id_number_bidx),  -- 防止同一 SSN/HKID 重复开户
    ADD INDEX idx_pii_key_version (pii_key_version);

-- account_ubos 同步更新
ALTER TABLE account_ubos
    MODIFY full_name_encrypted  VARBINARY(1024) NOT NULL,
    MODIFY dob_encrypted        VARBINARY(512),
    MODIFY id_number_encrypted  VARBINARY(1024),
    ADD COLUMN id_number_bidx   BINARY(32) NULL,
    ADD COLUMN pii_key_version  VARCHAR(50) NOT NULL DEFAULT '',
    ADD INDEX idx_ubo_id_bidx (id_number_bidx);
```

### 7.3 存储大小预算

| 字段 | 明文大小 | Tink 开销 | 总大小（VARBINARY） |
|------|----------|----------|-------------------|
| SSN | 9 bytes | 5字节前缀 + 12字节nonce + 16字节tag = +33 bytes | ~42 bytes（VARBINARY(1024) 足够） |
| HKID | 12 bytes | +33 | ~45 bytes |
| 护照号 | 20 bytes | +33 | ~53 bytes |
| 银行账号 | 30 bytes | +33 | ~63 bytes |

> Tink 模式下无需存储独立 `CiphertextDEK`（DEK 由 Keyset Handle 管理，Keyset 加密后存于 Secrets Manager），字段更小。

---

## 8. 密钥轮换 SOP

### 8.1 Tink Keyset 轮换（推荐，零停机）

Tink KeysetHandle 支持同时持有多个 key，无需停机：

```
Step 1: 调用 manager.Add(aead.AES256GCMKeyTemplate()) 添加新 key 到 Keyset
Step 2: 调用 manager.SetPrimary(newKeyID) 设为主密钥（新加密用新 key）
Step 3: 将更新后的 Keyset 保存到 AWS Secrets Manager（加密存储）
Step 4: AMS 实例热重载 Keyset（无需重启）
Step 5: 旧 key 保持 ENABLED 状态（旧密文仍可解密）
Step 6: 运行后台 re-encryption job，将旧密文用新 key 重新加密
Step 7: 所有密文迁移完成后，将旧 key 设为 DISABLED（不可再加密，仍可解密）
Step 8: 确认无 DISABLED key 的密文后，删除旧 key
```

**总耗时**：视账户量而定，可在几小时到几天内完成，全程无停机。

### 8.2 AWS CMK 轮换

AWS CMK 自动年度轮换**不需要重新加密存储数据**（旧版本 CMK 永久保留在 KMS 中，旧密文仍可解密）。

如需主动重新包装 DEK（如怀疑密钥泄露）：

```go
// 调用 KMS ReEncrypt API，不暴露明文 DEK
resp, err := kmsClient.ReEncrypt(ctx, &kms.ReEncryptInput{
    CiphertextBlob:   encryptedDEK,
    DestinationKeyId: aws.String(cmkARN), // 同一 CMK，新版本
})
// 更新 MySQL 中的 CiphertextDEK 字段
```

### 8.3 Blind Index 密钥轮换

Blind Index 密钥轮换代价较高（需解密所有 PII 并重新计算）：

1. 在 Secrets Manager 创建新 `BLIND_INDEX_SECRET_V2`
2. 启动后台任务：对每个账户，解密 PII → 用新密钥计算 Blind Index → 更新 `id_number_bidx` 列
3. 切换至新密钥
4. 撤销旧密钥

**建议频率**：每 2 年或在怀疑密钥泄露时执行一次，而非每年。

---

## 9. 开发环境配置

### 9.1 本地开发（无 AWS KMS）

```go
// 开发环境使用内存 Tink Keyset（不依赖 AWS KMS）
// 通过环境变量 PII_ENCRYPTION_MODE 控制

func NewPIIEncryptorFromEnv(ctx context.Context) (*PIIEncryptor, error) {
    mode := os.Getenv("PII_ENCRYPTION_MODE")
    switch mode {
    case "aws-kms":
        cmkARN := os.Getenv("AWS_KMS_CMK_ARN") // 必须设置
        return NewPIIEncryptor(ctx, cmkARN)
    case "local-insecure": // 仅用于开发/测试，绝不用于生产
        handle, _ := keyset.NewHandle(aead.AES256GCMKeyTemplate())
        a, _ := tinkaead.New(handle)
        return &PIIEncryptor{aeadPrimitive: a}, nil
    default:
        return nil, errors.New("PII_ENCRYPTION_MODE must be 'aws-kms' or 'local-insecure'")
    }
}
```

### 9.2 环境变量清单

```bash
# 生产
PII_ENCRYPTION_MODE=aws-kms
AWS_KMS_CMK_ARN=arn:aws:kms:ap-east-1:123456789:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
AWS_BLIND_INDEX_SECRET_ARN=arn:aws:secretsmanager:ap-east-1:123456789:secret:ams/blind-index-key

# 开发/测试（本地）
PII_ENCRYPTION_MODE=local-insecure
# 不需要 AWS 凭证
```

### 9.3 代码审查守则

以下代码模式须在 PR 中标记并审查：
- `.Plaintext()` 调用在 `piiencrypt`、`blindindex`、gRPC handler 之外出现
- 任何 `string` 类型字段用于存储 SSN/HKID/银行账号
- 日志语句中直接打印 KYC 数据（未使用 `MaskedKYCProfile`）
- 硬编码的测试 SSN 或 HKID（应使用 `testdata/fake_kyc.go` 中的假数据）

---

*参考：KMS & PII Encryption Deep-Dive Research Report（2026-03-17）、NIST SP 800-38D（AES-GCM 规范）、AWS KMS 文档、Tink Go v2 文档、`.claude/rules/security-compliance.md`*
