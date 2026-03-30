# OTA (Over-The-Air) 更新框架 — 完整实现计划

## Context

用户需要在生产环境中支持代码热更新能力。选择自建 OTA 框架（而非 Shorebird）以获得完整的控制力、审计能力和金融特定的功能（如交易时段禁止更新、持仓保护等）。

该框架涉及：
1. **后端 OTA 服务**（services/ota/） — Go 微服务，遵循现有 DDD 模式
2. **Flutter OTA 客户端**（mobile/src/lib/core/update/） — 5 个核心服务
3. **API 合同**（docs/contracts/ams-to-mobile-ota.md） — RESTful + 灰度管理端点
4. **数据库**（MySQL + Goose 迁移） — 版本、部署、审计三大表
5. **金融特性** — 持仓保护、市场时段延迟、审计追踪、回滚机制

---

## Recommended Approach

### 架构决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| **后端架构** | 3 子域 DDD（version/rollout/manifest） | 符合 market-data 模式，清晰的职责分离 |
| **签名算法** | RSA-2048（Manifest）+ SHA-256（包体） | 金融系统标准，平衡安全和性能 |
| **灰度策略** | 5 层优先级（白名单→黑名单→地域→群组→百分比） | 灵活，支持逐步灰度和快速回滚 |
| **事件驱动** | Outbox Pattern（Kafka） | 强一致性，符合金融要求 |
| **版本编码** | int32 MMNNPP（Major.Minor.Patch） | 高效比较，避免字符串解析 |
| **检查策略** | 定期轮询（24h 间隔） | 简单、低负担，适合移动网络 |
| **回滚触发** | 手动（admin）+ 自动（5% 崩溃率阈值） | 快速响应，无需人工介入 |

---

## Implementation Steps

### Phase 1: 后端基础架构 (Week 1-2)

**目标**：建立 OTA 服务骨架，数据库和依赖注入

#### Step 1.1: 创建服务目录结构

```
services/ota/
├── src/
│   ├── cmd/server/
│   │   ├── main.go                 # 启动点
│   │   ├── app.go                  # 应用生命周期
│   │   └── wire.go                 # 依赖注入（@build wireinject）
│   ├── internal/
│   │   ├── version/
│   │   │   ├── domain/
│   │   │   │   ├── entity.go       # AppVersion 聚合根
│   │   │   │   ├── repo.go         # Repository 接口
│   │   │   │   └── service.go      # 域服务
│   │   │   ├── app/
│   │   │   │   ├── check_version.go      # 检查更新用例
│   │   │   │   ├── get_manifest.go       # 获取清单用例
│   │   │   │   └── publish_version.go    # 发布版本用例
│   │   │   ├── infra/
│   │   │   │   ├── mysql/
│   │   │   │   │   ├── repo.go     # GORM 实现
│   │   │   │   │   └── model.go    # ORM model
│   │   │   │   ├── crypto/
│   │   │   │   │   └── signature_verifier.go  # RSA 验证
│   │   │   │   └── storage/
│   │   │   │       └── manifest_cache.go      # Redis 缓存
│   │   │   ├── handler.go           # HTTP 路由
│   │   │   └── wire.go              # 子域 ProviderSet
│   │   ├── rollout/
│   │   │   ├── domain/
│   │   │   │   ├── entity.go       # DeploymentPolicy 聚合根
│   │   │   │   ├── repo.go
│   │   │   │   └── evaluator.go    # 灰度评估引擎
│   │   │   ├── app/
│   │   │   │   └── evaluate_rollout.go
│   │   │   ├── infra/
│   │   │   │   └── mysql/repo.go
│   │   │   ├── handler.go
│   │   │   └── wire.go
│   │   ├── manifest/
│   │   │   ├── domain/
│   │   │   │   ├── entity.go       # Manifest 实体
│   │   │   │   └── repo.go
│   │   │   ├── app/
│   │   │   │   └── generate_manifest.go
│   │   │   ├── infra/
│   │   │   │   ├── crypto/signer.go     # RSA 签名生成
│   │   │   │   └── mysql/repo.go
│   │   │   ├── handler.go
│   │   │   └── wire.go
│   │   ├── kafka/
│   │   │   └── outbox/worker.go   # Outbox 轮询线程
│   │   ├── server/
│   │   │   ├── http.go             # HTTP 服务器配置
│   │   │   ├── grpc.go             # gRPC 配置（可选）
│   │   │   └── routes.go           # 路由注册
│   │   └── conf/
│   │       └── conf.go             # 配置加载
│   ├── configs/
│   │   ├── config.yaml             # 默认配置
│   │   ├── config.prod.yaml        # 生产配置
│   │   └── config.dev.yaml         # 开发配置
│   ├── migrations/
│   │   ├── 001_init_ota.sql        # 初始化表
│   │   ├── 002_add_signatures.sql  # 签名字段
│   │   └── 003_add_audit.sql       # 审计日志扩展
│   ├── go.mod
│   ├── go.sum
│   └── Makefile
├── docs/
│   ├── CLAUDE.md                   # 热层文档
│   └── domain.yaml                 # 元数据
├── .claude/agents/
│   └── ota-engineer.md             # 专家代理（可选）
└── README.md
```

**关键文件引用**：
- 参考：`services/market-data/src/cmd/server/main.go`
- 参考：`services/market-data/src/cmd/server/wire.go`

---

#### Step 1.2: 定义核心 Domain 实体

**文件**：`services/ota/src/internal/version/domain/entity.go`

```go
package domain

import (
    "time"
    "github.com/shopspring/decimal"
)

// AppVersion — 应用版本聚合根
type AppVersion struct {
    ID              int64
    VersionCode     int32              // MMNNPP: Major.Minor.Patch
    VersionName     string             // "1.0.0" 格式
    Platform        Platform           // IOS / ANDROID
    MinOSVersion    string             // "14.0"
    ReleaseNotes    string
    FileSize        int64
    FileChecksum    string             // SHA-256 hex
    ManifestPayload json.RawMessage    // 清单 JSON（包含签名）
    ManifestSig     string             // RSA-2048(ManifestPayload) base64
    Status          VersionStatus      // DRAFT / RELEASED / DEPRECATED / BROKEN
    PublishedAt     time.Time          // UTC
    CreatedAt       time.Time          // UTC
    UpdatedAt       time.Time          // UTC
}

type Platform string
const (
    PlatformIOS     Platform = "IOS"
    PlatformAndroid Platform = "ANDROID"
)

type VersionStatus string
const (
    StatusDraft      VersionStatus = "DRAFT"
    StatusReleased   VersionStatus = "RELEASED"
    StatusDeprecated VersionStatus = "DEPRECATED"
    StatusBroken     VersionStatus = "BROKEN"
)

// Validate — 不变量检查
func (v *AppVersion) Validate() error {
    if v.VersionCode <= 0 {
        return errors.New("invalid version code")
    }
    if v.MinOSVersion == "" {
        return errors.New("min OS version required")
    }
    if v.FileSize <= 0 {
        return errors.New("file size must be positive")
    }
    if !isValidSHA256(v.FileChecksum) {
        return errors.New("invalid SHA-256 checksum format")
    }
    return nil
}

// DeploymentPolicy — 灰度发布策略
type DeploymentPolicy struct {
    ID              int64
    VersionCode     int32
    Platform        Platform
    Priority1       Whitelist       // 白名单用户
    Priority2       Blacklist       // 黑名单排除
    Priority3       GeographicLimit // 地域限制
    Priority4       UserGroupFilter // 用户群组
    Priority5       PercentageRamp  // 百分比灰度（0-100）
    MaxCrashRate    decimal.Decimal // 5% 自动回滚阈值
    Status          PolicyStatus    // DRAFT / ACTIVE / PAUSED / COMPLETED
    CreatedAt       time.Time       // UTC
    UpdatedAt       time.Time       // UTC
}

type Whitelist struct {
    UserIDs []int64
}

type Blacklist struct {
    UserIDs []int64
}

type GeographicLimit struct {
    AllowedRegions []string // "US", "HK", "CN"
}

type UserGroupFilter struct {
    AllowedGroups []string // "VIP", "STANDARD", "RESTRICTED"
}

type PercentageRamp struct {
    Percentage int32 // 0-100
}

type PolicyStatus string
const (
    PolicyDraft     PolicyStatus = "DRAFT"
    PolicyActive    PolicyStatus = "ACTIVE"
    PolicyPaused    PolicyStatus = "PAUSED"
    PolicyCompleted PolicyStatus = "COMPLETED"
)
```

**关键设计点**：
- ✅ 使用 int32 版本码（MMNNPP），快速比较
- ✅ ManifestPayload + ManifestSig 分离（签名验证不修改负载）
- ✅ 所有时间戳 UTC（time.Time）
- ✅ Status 状态机（DRAFT → RELEASED → DEPRECATED / BROKEN）

---

#### Step 1.3: 创建 Repository 接口

**文件**：`services/ota/src/internal/version/domain/repo.go`

```go
package domain

import "context"

// VersionRepo — 版本仓储接口（依赖倒置）
type VersionRepo interface {
    // 查询
    FindByVersionCode(ctx context.Context, code int32, platform Platform) (*AppVersion, error)
    FindLatestReleased(ctx context.Context, platform Platform) (*AppVersion, error)
    FindByStatus(ctx context.Context, status VersionStatus, platform Platform) ([]*AppVersion, error)

    // 修改
    Save(ctx context.Context, v *AppVersion) error
    UpdateStatus(ctx context.Context, versionCode int32, platform Platform, status VersionStatus) error
}

// DeploymentPolicyRepo — 灰度策略仓储
type DeploymentPolicyRepo interface {
    FindByVersionCode(ctx context.Context, code int32, platform Platform) (*DeploymentPolicy, error)
    FindActive(ctx context.Context, platform Platform) ([]*DeploymentPolicy, error)
    Save(ctx context.Context, p *DeploymentPolicy) error
    UpdateStatus(ctx context.Context, id int64, status PolicyStatus) error
}

// VersionCheckAuditRepo — 审计日志（append-only）
type VersionCheckAuditRepo interface {
    Record(ctx context.Context, log *VersionCheckLog) error
    FindByDeviceID(ctx context.Context, deviceID string, limit int) ([]*VersionCheckLog, error)
}

// VersionCheckLog — 审计日志实体
type VersionCheckLog struct {
    ID              int64
    DeviceID        string
    UserID          *int64
    Platform        Platform
    CurrentVersion  int32
    LatestVersion   int32
    UpdateRequired  bool
    EvaluatedPolicy *int64
    Timestamp       time.Time // UTC
}
```

---

#### Step 1.4: 创建数据库迁移

**文件**：`services/ota/src/migrations/001_init_ota.sql`

```sql
-- +goose Up

CREATE TABLE app_versions (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version_code    INT NOT NULL COMMENT 'MMNNPP: e.g., 010000 for 1.0.0',
    version_name    VARCHAR(20) NOT NULL COMMENT 'e.g., 1.0.0',
    platform        ENUM('IOS', 'ANDROID') NOT NULL,
    min_os_version  VARCHAR(10) NOT NULL COMMENT 'e.g., 14.0',
    release_notes   TEXT,
    file_size       BIGINT NOT NULL COMMENT 'bytes',
    file_checksum   VARCHAR(64) NOT NULL COMMENT 'SHA-256 hex',
    manifest_payload BLOB NOT NULL COMMENT 'JSON manifest',
    manifest_sig    TEXT NOT NULL COMMENT 'RSA-2048(manifest) base64',
    status          ENUM('DRAFT', 'RELEASED', 'DEPRECATED', 'BROKEN') DEFAULT 'DRAFT',
    published_at    TIMESTAMP(6),
    created_at      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at      TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    UNIQUE INDEX idx_version_platform (version_code, platform),
    INDEX idx_status_platform (status, platform),
    INDEX idx_published (published_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE deployment_policies (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    version_code    INT NOT NULL,
    platform        ENUM('IOS', 'ANDROID') NOT NULL,
    priority1_whitelist_users JSON COMMENT '白名单 user_id 列表',
    priority2_blacklist_users JSON COMMENT '黑名单 user_id 列表',
    priority3_regions       JSON COMMENT '地域限制 ["US", "HK"]',
    priority4_user_groups   JSON COMMENT '用户群组 ["VIP", "STANDARD"]',
    priority5_percentage    INT DEFAULT 100 COMMENT '0-100 百分比灰度',
    max_crash_rate          DECIMAL(5,2) DEFAULT 5.00 COMMENT '自动回滚阈值 %',
    status                  ENUM('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED') DEFAULT 'DRAFT',
    created_at              TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at              TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    FOREIGN KEY (version_code, platform) REFERENCES app_versions(version_code, platform),
    INDEX idx_status_platform (status, platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE app_version_checks (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id       VARCHAR(100) NOT NULL COMMENT 'SHA-256 hash',
    user_id         BIGINT,
    platform        ENUM('IOS', 'ANDROID') NOT NULL,
    current_version INT NOT NULL,
    latest_version  INT NOT NULL,
    update_required BOOLEAN DEFAULT FALSE,
    evaluated_policy BIGINT,
    correlation_id  VARCHAR(100),
    check_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_device_timestamp (device_id, check_timestamp DESC),
    INDEX idx_correlation (correlation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='OTA version check audit log — append-only';

CREATE TABLE app_update_reports (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id       VARCHAR(100) NOT NULL COMMENT 'SHA-256 hash',
    user_id         BIGINT,
    version_code    INT NOT NULL,
    platform        ENUM('IOS', 'ANDROID') NOT NULL,
    status          ENUM('DOWNLOADING', 'DOWNLOADED', 'INSTALLED', 'FAILED', 'ROLLED_BACK') DEFAULT 'DOWNLOADING',
    progress_bytes  BIGINT DEFAULT 0,
    total_bytes     BIGINT NOT NULL,
    error_code      VARCHAR(50),
    error_message   TEXT,
    started_at      TIMESTAMP(6) NOT NULL,
    completed_at    TIMESTAMP(6),
    correlation_id  VARCHAR(100),
    INDEX idx_device_version (device_id, version_code),
    INDEX idx_status (status, completed_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='OTA download progress and completion tracking';

CREATE TABLE outbox_events (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    topic        VARCHAR(255) NOT NULL,
    payload      BLOB NOT NULL,
    status       ENUM('PENDING', 'PUBLISHED', 'FAILED') DEFAULT 'PENDING',
    created_at   TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6),
    published_at TIMESTAMP(6),
    retry_count  TINYINT UNSIGNED DEFAULT 0,
    INDEX idx_status_created (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT='Kafka Outbox — strong consistency for OTA events';

-- +goose Down

DROP TABLE outbox_events;
DROP TABLE app_update_reports;
DROP TABLE app_version_checks;
DROP TABLE deployment_policies;
DROP TABLE app_versions;
```

**关键设计**：
- ✅ app_versions: 版本元数据 + 清单 + 签名
- ✅ deployment_policies: 灰度配置（JSON 存储数组）
- ✅ app_version_checks: 审计日志（append-only）
- ✅ app_update_reports: 下载追踪和完成报告
- ✅ outbox_events: Kafka Outbox（Kafka 事件强一致性）

---

### Phase 2: 应用层用例 (Week 2-3)

#### Step 2.1: 版本检查用例

**文件**：`services/ota/src/internal/version/app/check_version.go`

```go
package app

import (
    "context"
    "fmt"
    "github.com/brokerage-trading-app/services/ota/src/internal/version/domain"
    "time"
)

type CheckVersionInput struct {
    DeviceID        string // 设备标识（必须的）
    UserID          *int64 // 可选用户ID
    Platform        domain.Platform
    CurrentVersion  int32
    IPAddress       string
    Region          string // 地域代码
    UserGroup       string // 用户群组
    CorrelationID   string // 分布式追踪
}

type CheckVersionOutput struct {
    LatestVersion   int32
    UpdateRequired  bool
    Mandatory       bool
    DownloadURL     string
    ChecksumSHA256  string
    ManifestPayload string // 签名清单
    ReleaseNotes    string
}

type CheckVersionUsecase struct {
    versionRepo       domain.VersionRepo
    policyRepo        domain.DeploymentPolicyRepo
    auditRepo         domain.VersionCheckAuditRepo
    outboxRepo        OutboxRepo
    txFunc            TxFunc
    logger            *zap.Logger
}

func (uc *CheckVersionUsecase) Execute(ctx context.Context, input CheckVersionInput) (*CheckVersionOutput, error) {
    // 1. 从 cache/DB 获取最新发布版本
    latestVersion, err := uc.versionRepo.FindLatestReleased(ctx, input.Platform)
    if err != nil {
        uc.logger.Error("failed to find latest version", zap.Error(err))
        return nil, fmt.Errorf("check version: %w", err)
    }

    // 2. 检查是否需要更新
    updateRequired := latestVersion.VersionCode > input.CurrentVersion

    // 3. 评估灰度策略（如果更新可用）
    policyMatched := false
    if updateRequired {
        policy, _ := uc.policyRepo.FindByVersionCode(ctx, latestVersion.VersionCode, input.Platform)
        if policy == nil {
            // 无策略 → 100% 发布
            policyMatched = true
        } else {
            policyMatched = uc.evaluatePolicy(policy, &input)
        }
    }

    // 4. 事务：记录审计日志 + 发送 Outbox 事件
    err = uc.txFunc(ctx, func(txCtx context.Context) error {
        // 记录审计检查
        auditLog := &domain.VersionCheckLog{
            DeviceID:       input.DeviceID,
            UserID:         input.UserID,
            Platform:       input.Platform,
            CurrentVersion: input.CurrentVersion,
            LatestVersion:  latestVersion.VersionCode,
            UpdateRequired: updateRequired && policyMatched,
            Timestamp:      time.Now().UTC(),
        }
        if err := uc.auditRepo.Record(txCtx, auditLog); err != nil {
            return err
        }

        // 发送 Outbox 事件（用于后续分析和告警）
        payload, _ := json.Marshal(map[string]interface{}{
            "device_id":       input.DeviceID,
            "version_code":    latestVersion.VersionCode,
            "update_required": updateRequired && policyMatched,
        })
        return uc.outboxRepo.InsertEvent(txCtx, "ota.version.checked", payload)
    })

    if err != nil {
        return nil, fmt.Errorf("check version audit: %w", err)
    }

    // 5. 如果不需要更新或策略不匹配，返回空响应
    if !updateRequired || !policyMatched {
        return &CheckVersionOutput{
            LatestVersion:  latestVersion.VersionCode,
            UpdateRequired: false,
        }, nil
    }

    // 6. 构造响应（清单已签名）
    return &CheckVersionOutput{
        LatestVersion:   latestVersion.VersionCode,
        UpdateRequired:  true,
        Mandatory:       latestVersion.Status == domain.StatusReleased && isOlderVersion(input.CurrentVersion, latestVersion.VersionCode),
        DownloadURL:     fmt.Sprintf("https://api.trading.internal/v1/ota/download/%s/%d", input.Platform, latestVersion.VersionCode),
        ChecksumSHA256:  latestVersion.FileChecksum,
        ManifestPayload: string(latestVersion.ManifestPayload),
        ReleaseNotes:    latestVersion.ReleaseNotes,
    }, nil
}

// evaluatePolicy — 灰度策略评估
func (uc *CheckVersionUsecase) evaluatePolicy(policy *domain.DeploymentPolicy, input *CheckVersionInput) bool {
    // Priority 1: 白名单
    if len(policy.Priority1.UserIDs) > 0 {
        if input.UserID != nil && contains(policy.Priority1.UserIDs, *input.UserID) {
            return true
        }
        return false // 白名单模式，非白名单用户拒绝
    }

    // Priority 2: 黑名单排除
    if input.UserID != nil && contains(policy.Priority2.UserIDs, *input.UserID) {
        return false
    }

    // Priority 3: 地域限制
    if len(policy.Priority3.AllowedRegions) > 0 && !contains(policy.Priority3.AllowedRegions, input.Region) {
        return false
    }

    // Priority 4: 用户群组
    if len(policy.Priority4.AllowedGroups) > 0 && !contains(policy.Priority4.AllowedGroups, input.UserGroup) {
        return false
    }

    // Priority 5: 百分比灰度（确定性哈希）
    if policy.Priority5.Percentage < 100 {
        hash := md5.Sum([]byte(input.DeviceID))
        hashValue := binary.LittleEndian.Uint32(hash[:4]) % 100
        return hashValue < uint32(policy.Priority5.Percentage)
    }

    return true
}
```

---

#### Step 2.2: 获取清单用例

**文件**：`services/ota/src/internal/manifest/app/get_manifest.go`

```go
package app

type GetManifestInput struct {
    VersionCode  int32
    Platform     domain.Platform
    DeviceID     string
}

type GetManifestOutput struct {
    VersionCode int32
    Payload     string // JSON 清单
    Signature   string // RSA-2048 签名（base64）
    Timestamp   int64  // Unix timestamp UTC
}

type GetManifestUsecase struct {
    manifestRepo domain.ManifestRepo
    versionRepo  domain.VersionRepo
    logger       *zap.Logger
}

func (uc *GetManifestUsecase) Execute(ctx context.Context, input GetManifestInput) (*GetManifestOutput, error) {
    // 从 cache 或 DB 获取清单
    version, err := uc.versionRepo.FindByVersionCode(ctx, input.VersionCode, input.Platform)
    if err != nil || version == nil {
        return nil, fmt.Errorf("version not found: %w", err)
    }

    // 验证版本已发布
    if version.Status != domain.StatusReleased {
        return nil, errors.New("version not released")
    }

    return &GetManifestOutput{
        VersionCode: version.VersionCode,
        Payload:     string(version.ManifestPayload),
        Signature:   version.ManifestSig,
        Timestamp:   version.PublishedAt.Unix(),
    }, nil
}
```

---

### Phase 3: Infrastructure 层与加密 (Week 3-4)

#### Step 3.1: RSA 签名验证器

**文件**：`services/ota/src/internal/version/infra/crypto/signature_verifier.go`

```go
package crypto

import (
    "crypto"
    "crypto/rand"
    "crypto/rsa"
    "crypto/sha256"
    "crypto/x509"
    "encoding/base64"
    "encoding/pem"
    "fmt"
)

type SignatureVerifier struct {
    publicKey *rsa.PublicKey
}

// LoadPublicKey — 从 PEM 格式加载公钥
func LoadPublicKey(pemData []byte) (*SignatureVerifier, error) {
    block, _ := pem.Decode(pemData)
    if block == nil {
        return nil, fmt.Errorf("failed to parse PEM block")
    }

    pub, err := x509.ParsePKIXPublicKey(block.Bytes)
    if err != nil {
        return nil, fmt.Errorf("failed to parse public key: %w", err)
    }

    rsaKey, ok := pub.(*rsa.PublicKey)
    if !ok {
        return nil, fmt.Errorf("not an RSA public key")
    }

    return &SignatureVerifier{publicKey: rsaKey}, nil
}

// Verify — 验证 RSA-2048 签名
func (v *SignatureVerifier) Verify(payload []byte, signatureB64 string) error {
    signature, err := base64.StdEncoding.DecodeString(signatureB64)
    if err != nil {
        return fmt.Errorf("failed to decode signature: %w", err)
    }

    hash := sha256.Sum256(payload)
    err = rsa.VerifyPKCS1v15(v.publicKey, crypto.SHA256, hash[:], signature)
    if err != nil {
        return fmt.Errorf("signature verification failed: %w", err)
    }

    return nil
}

// GenerateManifest — 生成签名清单（服务端用）
type ManifestSigner struct {
    privateKey *rsa.PrivateKey
}

func LoadPrivateKey(pemData []byte) (*ManifestSigner, error) {
    block, _ := pem.Decode(pemData)
    if block == nil {
        return nil, fmt.Errorf("failed to parse PEM block")
    }

    key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
    if err != nil {
        return nil, fmt.Errorf("failed to parse private key: %w", err)
    }

    rsaKey, ok := key.(*rsa.PrivateKey)
    if !ok {
        return nil, fmt.Errorf("not an RSA private key")
    }

    return &ManifestSigner{privateKey: rsaKey}, nil
}

func (s *ManifestSigner) Sign(payload []byte) (string, error) {
    hash := sha256.Sum256(payload)
    signature, err := rsa.SignPKCS1v15(rand.Reader, s.privateKey, crypto.SHA256, hash[:])
    if err != nil {
        return "", fmt.Errorf("signing failed: %w", err)
    }
    return base64.StdEncoding.EncodeToString(signature), nil
}
```

---

### Phase 4: API 合同与端点 (Week 4)

**文件**：`docs/contracts/ams-to-mobile-ota.md`

```yaml
---
provider: AMS
consumer: Mobile (Flutter)
service: OTA Updates
version: v1
status: DRAFT
last_updated: 2026-03-28
sla:
  availability: "99.9%"
  max_latency_ms: 1000
  rate_limit: "100 req/s per IP"
auth:
  type: JWT RS256
  header: "Authorization: Bearer {token}"
  device_binding: "device_id claim required"
---

# OTA Update Delivery Contract

## Endpoints

### 1. Check for Updates

```
POST /api/v1/ota/check
Content-Type: application/json
Authorization: Bearer {token}

Request:
{
  "device_id": "uuid-v4-sha256-hash",
  "current_version": 010000,
  "platform": "ios|android",
  "os_version": "18.0",
  "region": "US|HK|CN",
  "user_group": "VIP|STANDARD|RESTRICTED"
}

Response (200):
{
  "update_required": true,
  "latest_version": 010001,
  "mandatory": false,
  "download_url": "https://cdn.trading.internal/v1/ota/ios/010001.ipa",
  "checksum_sha256": "abc123...",
  "release_notes": "Bug fixes and performance improvements",
  "manifest": {
    "version": 010001,
    "payload": "{...}",
    "signature": "base64-encoded-rsa-2048-sig"
  }
}

Response (204):
No update available
```

### 2. Get Manifest (Signed)

```
GET /api/v1/ota/manifest/{version_code}
Accept: application/json
Authorization: Bearer {token}

Response (200):
{
  "version_code": 010001,
  "payload": "{\"file_size\": 123456, ...}",
  "signature": "base64-rsa-2048-sig",
  "timestamp": 1710672000
}
```

### 3. Report Download Progress

```
POST /api/v1/ota/report/download
Content-Type: application/json
Authorization: Bearer {token}

Request:
{
  "device_id": "uuid-sha256",
  "version_code": 010001,
  "platform": "ios",
  "status": "DOWNLOADING|DOWNLOADED|INSTALLED|FAILED",
  "progress_bytes": 50000000,
  "total_bytes": 100000000,
  "error_code": "NETWORK_TIMEOUT|CHECKSUM_MISMATCH|...",
  "correlation_id": "req-uuid"
}

Response (200):
{
  "acknowledged": true
}
```

### 4. Get Deployment Policy (Admin Only)

```
GET /api/v1/ota/config?version_code={code}&platform={platform}
Authorization: Bearer {admin_token}

Response (200):
{
  "version_code": 010001,
  "platform": "ios",
  "whitelist_users": [123, 456],
  "blacklist_users": [789],
  "allowed_regions": ["US", "HK"],
  "user_groups": ["VIP", "STANDARD"],
  "percentage": 25,
  "max_crash_rate_percent": 5.0,
  "status": "ACTIVE"
}
```

### 5. Trigger Rollback (Admin Only)

```
POST /api/v1/ota/rollback
Authorization: Bearer {admin_token}
Content-Type: application/json

Request:
{
  "version_code": 010001,
  "platform": "ios",
  "reason": "HIGH_CRASH_RATE|CRITICAL_BUG|MANUAL",
  "rollback_to_version": 010000
}

Response (200):
{
  "rollback_id": "rb-uuid",
  "initiated_at": "2026-03-28T09:30:00Z",
  "status": "IN_PROGRESS"
}
```

---

## Kafka Events

**Topic**: `brokerage.ota.version.{event_type}`

```
brokerage.ota.version.released
brokerage.ota.version.deprecated
brokerage.ota.rollback.triggered
brokerage.ota.update.completed
brokerage.ota.check.failed
```
```

---

### Phase 5: Flutter OTA 客户端 (Week 4-5)

#### Step 5.1: 版本检查服务

**文件**：`mobile/src/lib/core/update/version_check_service.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'version_check_service.g.dart';

@riverpod
class VersionCheckService extends _$VersionCheckService {
  late final DioClient _dioClient;
  late final TokenService _tokenService;
  late final DeviceInfoService _deviceInfoService;

  @override
  Future<VersionCheckResult?> build() async {
    _dioClient = ref.watch(dioClientProvider);
    _tokenService = ref.watch(tokenServiceProvider);
    _deviceInfoService = ref.watch(deviceInfoServiceProvider);

    return _performVersionCheck();
  }

  Future<VersionCheckResult?> _performVersionCheck() async {
    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final currentVersion = packageInfo.version; // "1.0.0"

      final response = await _dioClient.post(
        '/api/v1/ota/check',
        data: {
          'device_id': deviceInfo.deviceId,
          'current_version': _parseVersionCode(currentVersion),
          'platform': _getPlatform(),
          'os_version': deviceInfo.osVersion,
          'region': _getUserRegion(),
          'user_group': _getUserGroup(),
        },
      );

      if (response.statusCode == 204) {
        return null; // No update
      }

      final data = response.data as Map<String, dynamic>;
      return VersionCheckResult.fromJson(data);
    } on AppException catch (e) {
      AppLogger.warning('Version check failed', error: e);
      return null; // Graceful failure
    }
  }

  int _parseVersionCode(String version) {
    // "1.0.0" → 010000 (MMNNPP)
    final parts = version.split('.');
    final major = int.parse(parts[0]);
    final minor = int.tryParse(parts[1]) ?? 0;
    final patch = int.tryParse(parts[2]) ?? 0;
    return (major * 10000) + (minor * 100) + patch;
  }

  String _getPlatform() => Platform.isIOS ? 'ios' : 'android';

  String _getUserRegion() => 'US'; // TODO: 从用户配置读取

  String _getUserGroup() => 'STANDARD'; // TODO: 从 AMS 读取
}

@freezed
class VersionCheckResult with _$VersionCheckResult {
  const factory VersionCheckResult({
    required bool updateRequired,
    required int latestVersion,
    required bool mandatory,
    required String downloadUrl,
    required String checksumSha256,
    required String releaseNotes,
    required ManifestData manifest,
  }) = _VersionCheckResult;

  factory VersionCheckResult.fromJson(Map<String, dynamic> json) =>
      _$VersionCheckResultFromJson(json);
}

@freezed
class ManifestData with _$ManifestData {
  const factory ManifestData({
    required int versionCode,
    required String payload,
    required String signature,
  }) = _ManifestData;

  factory ManifestData.fromJson(Map<String, dynamic> json) =>
      _$ManifestDataFromJson(json);
}
```

---

#### Step 5.2: 签名验证器

**文件**：`mobile/src/lib/core/update/signature_verifier.dart`

```dart
import 'dart:convert';
import 'package:pointycastle/export.dart';

class SignatureVerifier {
  final RSAPublicKey publicKey;

  SignatureVerifier(this.publicKey);

  /// 从 PEM 格式加载公钥
  static Future<SignatureVerifier> fromPem(String pemData) async {
    final bytes = _pemToBytes(pemData);
    final publicKey = RSAKeyParser().parse(bytes) as RSAPublicKey;
    return SignatureVerifier(publicKey);
  }

  /// 验证 RSA-2048 + SHA-256 签名
  bool verify(String payload, String signatureB64) {
    try {
      final signatureBytes = base64Decode(signatureB64);
      final payloadBytes = utf8.encode(payload);

      final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
        ..init(false, PublicKeyParameter(publicKey));

      return signer.verifySignature(payloadBytes, Signature(signatureBytes));
    } catch (e) {
      AppLogger.error('Signature verification failed', error: e);
      return false;
    }
  }

  static Uint8List _pemToBytes(String pem) {
    final lines = pem.split('\n');
    final base64 = lines
        .where((l) => !l.startsWith('-----'))
        .join();
    return base64Decode(base64);
  }
}
```

---

#### Step 5.3: 更新下载器

**文件**：`mobile/src/lib/core/update/update_downloader.dart`

```dart
import 'dart:io';
import 'package:dio/dio.dart';

@riverpod
class UpdateDownloader extends _$UpdateDownloader {
  late final DioClient _dioClient;

  @override
  Future<UpdateDownloadProgress> build() async {
    _dioClient = ref.watch(dioClientProvider);
    return const UpdateDownloadProgress();
  }

  Future<void> downloadUpdate(
    String downloadUrl,
    String expectedChecksum,
    void Function(double) onProgress,
  ) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final savePath = '${appDocDir.path}/update.zip';

      await _dioClient.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          final progress = received / total;
          onProgress(progress);
          state = AsyncValue.data(
            UpdateDownloadProgress(
              downloadedBytes: received,
              totalBytes: total,
              progress: progress,
            ),
          );
        },
      );

      // 验证 SHA-256
      final file = File(savePath);
      final actualChecksum = await _calculateSha256(file);

      if (actualChecksum != expectedChecksum) {
        file.deleteSync();
        throw SecurityException('Checksum mismatch: expected $expectedChecksum, got $actualChecksum');
      }

      AppLogger.info('Update downloaded and verified', additionalParameters: {
        'path': savePath,
        'size': file.lengthSync(),
      });
    } on AppException rethrow {
    } catch (e) {
      throw NetworkException('Download failed: $e');
    }
  }

  Future<String> _calculateSha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
}

@freezed
class UpdateDownloadProgress with _$UpdateDownloadProgress {
  const factory UpdateDownloadProgress({
    @Default(0) int downloadedBytes,
    @Default(0) int totalBytes,
    @Default(0.0) double progress,
  }) = _UpdateDownloadProgress;
}
```

---

#### Step 5.4: 更新应用服务

**文件**：`mobile/src/lib/core/update/update_applier.dart`

```dart
@riverpod
class UpdateApplier extends _$UpdateApplier {
  late final SecureStorageService _storage;

  @override
  AsyncValue<void> build() {
    _storage = ref.watch(secureStorageServiceProvider);
    return const AsyncValue.loading();
  }

  Future<void> applyUpdate(String updateFilePath) async {
    try {
      // 1. 验证设备不在持仓中（与 Trading Engine 通信）
      final accountStatus = await _checkAccountStatus();
      if (accountStatus.hasOpenPositions) {
        throw BusinessException(
          'Cannot update while holding positions. Please close all positions first.',
        );
      }

      // 2. 检查市场时段
      if (_isMarketOpen()) {
        throw BusinessException(
          'Update not allowed during market hours. Please try after market close.',
        );
      }

      // 3. 存储待应用的更新
      await _storage.write('pending_update_path', updateFilePath);
      await _storage.write('pending_update_version', _getCurrentAppVersion());

      AppLogger.info('Update scheduled for next app restart',
          additionalParameters: {'path': updateFilePath});

      // 4. 通知用户，建议重启应用
      state = const AsyncValue.data(null);
    } on AppException rethrow {
    } catch (e) {
      throw UnknownException('Failed to apply update: $e');
    }
  }

  Future<AccountStatus> _checkAccountStatus() async {
    // TODO: 调用 Trading Engine API
    final response = await ref.watch(dioClientProvider).get(
      '/api/v1/trading/account/status',
    );
    return AccountStatus.fromJson(response.data);
  }

  bool _isMarketOpen() {
    // ET: 09:30-16:00
    // HKT: 09:30-16:00
    final now = DateTime.now().toUtc();
    // TODO: 实现市场时段检查
    return false;
  }
}
```

---

#### Step 5.5: 回滚管理器

**文件**：`mobile/src/lib/core/update/rollback_manager.dart`

```dart
@riverpod
class RollbackManager extends _$RollbackManager {
  late final SecureStorageService _storage;
  late final DioClient _dioClient;

  @override
  Future<void> build() async {
    _storage = ref.watch(secureStorageServiceProvider);
    _dioClient = ref.watch(dioClientProvider);

    // 应用启动时检查是否需要回滚
    await _checkAndApplyRollback();
  }

  Future<void> _checkAndApplyRollback() async {
    try {
      final pendingUpdatePath = await _storage.read('pending_update_path');
      if (pendingUpdatePath == null) return; // 没有待应用的更新

      // 标记应用启动时的版本
      await _storage.write('update_applied_at', DateTime.now().toIso8601String());

      // 启动崩溃监听
      // 如果 5 分钟内崩溃 3 次，自动回滚
      _monitorForCrashes();
    } catch (e) {
      AppLogger.error('Rollback check failed', error: e);
    }
  }

  void _monitorForCrashes() {
    // TODO: 使用 Firebase Crashlytics 监听崩溃
    // 如果崩溃率超过 5%，触发回滚
  }

  Future<void> triggerManualRollback() async {
    try {
      final previousVersion = await _storage.read('pending_update_version');

      // 删除待应用的更新
      await _storage.delete('pending_update_path');
      await _storage.delete('update_applied_at');

      // 通知后端
      await _dioClient.post(
        '/api/v1/ota/rollback',
        data: {
          'version_code': int.parse(previousVersion ?? '0'),
          'reason': 'MANUAL_USER_REQUEST',
        },
      );

      AppLogger.info('Rollback triggered manually');
    } on AppException rethrow {
    } catch (e) {
      throw UnknownException('Rollback failed: $e');
    }
  }
}
```

---

### Phase 6: 金融特定功能 (Week 5-6)

#### Step 6.1: 持仓保护集成

在 `update_applier.dart` 中集成 Trading Engine 查询：

```dart
Future<AccountStatus> _checkAccountStatus() async {
  final response = await ref.watch(dioClientProvider).get(
    '/api/v1/trading/account/{account_id}/status',
    options: Options(
      headers: {'Authorization': 'Bearer ${await _getAdminToken()}'},
    ),
  );

  final data = response.data as Map<String, dynamic>;
  final openPositions = data['open_positions'] as int;
  final pendingOrders = data['pending_orders'] as int;

  return AccountStatus(
    hasOpenPositions: openPositions > 0,
    hasPendingOrders: pendingOrders > 0,
  );
}
```

#### Step 6.2: 市场时段延迟

```dart
bool _isMarketOpen() {
  final now = DateTime.now();

  // ET (NYSE/NASDAQ): 09:30-16:00 EST/EDT
  final etZone = tz.getLocation('America/New_York');
  final etTime = tz.TZDateTime.from(now, etZone);

  // HKT (HKEX): 09:30-16:00 HKT
  final hktZone = tz.getLocation('Asia/Hong_Kong');
  final hktTime = tz.TZDateTime.from(now, hktZone);

  final isETOpen = etTime.weekday < 6 && // Mon-Fri
      etTime.hour >= 9 && etTime.hour < 17;

  final isHKTOpen = hktTime.weekday < 6 && // Mon-Fri
      hktTime.hour >= 9 && hktTime.hour < 17;

  return isETOpen || isHKTOpen;
}
```

---

### Phase 7: 测试与部署 (Week 6-7)

#### Step 7.1: 单元测试

**文件**：`services/ota/src/internal/version/app/check_version_test.go`

```go
package app_test

import (
    "context"
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

func TestCheckVersion_UpdateRequired(t *testing.T) {
    // Arrange
    mockVersionRepo := new(MockVersionRepo)
    mockVersionRepo.On("FindLatestReleased", mock.Anything, domain.PlatformIOS).
        Return(&domain.AppVersion{
            VersionCode: 010001,
            Status:      domain.StatusReleased,
        }, nil)

    uc := app.NewCheckVersionUsecase(mockVersionRepo, nil, nil, nil, nil, nil)

    // Act
    result, err := uc.Execute(context.Background(), app.CheckVersionInput{
        DeviceID:       "device-123",
        Platform:       domain.PlatformIOS,
        CurrentVersion: 010000,
    })

    // Assert
    assert.NoError(t, err)
    assert.True(t, result.UpdateRequired)
    assert.Equal(t, int32(010001), result.LatestVersion)
}

func TestCheckVersion_GrayscalePolicy(t *testing.T) {
    // Test that 20% grayscale rollout correctly rejects 80% of devices
    // via deterministic hash
    // ...
}
```

---

## Critical Files to Create/Modify

### Backend Services

```
services/ota/
├── src/cmd/server/main.go
├── src/cmd/server/wire.go
├── src/internal/version/domain/entity.go
├── src/internal/version/domain/repo.go
├── src/internal/version/app/check_version.go
├── src/internal/version/infra/mysql/repo.go
├── src/internal/version/infra/crypto/signature_verifier.go
├── src/migrations/001_init_ota.sql
├── go.mod
└── Makefile
```

### Flutter Client

```
mobile/src/lib/core/update/
├── version_check_service.dart
├── signature_verifier.dart
├── update_downloader.dart
├── update_applier.dart
└── rollback_manager.dart
```

### API Contract

```
docs/contracts/ams-to-mobile-ota.md
```

---

## Verification

1. **Backend**：
   - `make test` — 单元测试通过
   - `make migrate` — 数据库迁移无错误
   - `make build` — Go 编译成功
   - 手动测试 `/api/v1/ota/check` 端点返回正确格式

2. **Flutter**：
   - `flutter analyze` — 无警告
   - `flutter test` — 单元测试通过
   - 集成测试：模拟版本检查和下载流程

3. **Integration**：
   - 灰度策略评估准确
   - 审计日志正确记录
   - Kafka Outbox 事件可靠发送
   - RSA 签名验证正确

---

## Next Steps After Plan Approval

1. 创建 services/ota 服务目录和 go.mod
2. 实现 Domain 层（3 个子域的实体 + 接口）
3. 创建数据库迁移文件
4. 实现 Infra 层（GORM 仓储 + 加密模块）
5. 实现 App 层用例（CheckVersion、GetManifest、Report）
6. 创建 HTTP Handler 和路由
7. 配置 Wire 依赖注入
8. 编写 API 合同文档
9. 实现 Flutter 客户端（5 个服务）
10. 编写集成测试和负载测试
