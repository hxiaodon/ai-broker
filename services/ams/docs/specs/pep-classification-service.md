---
type: technical-spec
version: v1.0
date: 2026-03-30T12:00+08:00
author: AMS Engineer
status: Final — Ready for Implementation
---

# PEP 分类服务（Go 实现规范）

> **本规范定义 Non-HK PEP 分类和 EDD（增强尽调）流程的 Go 后端实现细节**。相关的产品规格见 `docs/prd/aml-compliance.md` § 4.3-4.4。

---

## 目录

1. [PEP 分类标准（产品规格）](#1-pep-分类标准产品规格)
2. [数据库设计](#2-数据库设计)
3. [分类决策树实现](#3-分类决策树实现)
4. [Admin Panel API](#4-admin-panel-api)
5. [ComplyAdvantage 集成](#5-complyadvantagek集成)
6. [EDD 工作流服务](#6-edd-工作流服务)
7. [风险评分更新](#7-风险评分更新)
8. [实现检查清单](#8-实现检查清单)

---

## 1. PEP 分类标准（产品规格）

**来源参考**：`docs/prd/aml-compliance.md` § 4.3

### 1.1 三级分类体系

| Level | 定义 | 范围 | 处理方式 | EDD | 交易监控 |
|-------|------|------|---------|-----|---------|
| **Level 1** | 高风险官员 | 中央政治局、国务院部长、省级一把手 | **强制 EDD** | 自动升级，需高管批准 | 严格监控 |
| **Level 2** | 中风险官员 | 省副、地级市正职、央企一把手 | 人工评估 | 视评估结果 | 加强监控 |
| **Level 3** | 低风险官员 | 市副、县级、中层国企管理 | 标记+监控 | 无强制，交易监控 | 降低阈值 50% |
| **Non-PEP** | 非官员 | 普通用户 | 无特殊处理 | 无 | 常规监控 |

### 1.2 分类字段存储

```go
type PEPClassification struct {
    AccountID         string    // 账户ID
    IsPEP             bool      // 是否为 PEP
    PEPLevel          int       // 1 / 2 / 3 / 0(非PEP)
    ClassifiedAt      time.Time // 分类时间
    ClassifiedBy      string    // 分类者 ID（"SYSTEM" 或合规官ID）
    Reason            string    // 分类原因（如"central_politburo"）
    OfficialPosition  string    // 官职（若有）
    OfficialArea      string    // 任职地区
    WealthSourceOK    bool      // 财富来源是否可信
    TradingPatternOK  bool      // 交易模式是否正常
    Comments          string    // 合规官备注
    NextReviewDate    time.Time // 下次审查日期
}
```

---

## 2. 数据库设计

### 2.1 新增表：pep_classifications

```sql
CREATE TABLE pep_classifications (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id CHAR(36) NOT NULL,
    is_pep BOOLEAN NOT NULL DEFAULT FALSE,
    pep_level INT CHECK (pep_level IN (0, 1, 2, 3)),  -- 0=非PEP，1-3=PEP等级
    classified_at TIMESTAMP NOT NULL,
    classified_by VARCHAR(36) NOT NULL,  -- 分类者ID或"SYSTEM"
    reason VARCHAR(100),  -- 分类原因编码
    official_position VARCHAR(255),  -- 官职名称
    official_area VARCHAR(100),  -- 任职地区/部门
    wealth_source_ok BOOLEAN,  -- 财富来源是否合理
    trading_pattern_ok BOOLEAN,  -- 交易模式是否异常
    comments TEXT,
    next_review_date TIMESTAMP,  -- 下次审查日期
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_account (account_id),
    INDEX idx_pep_level (pep_level),
    INDEX idx_classified_at (classified_at),
    INDEX idx_next_review (next_review_date),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE
) ENGINE=InnoDB;
```

### 2.2 更新 accounts 表

```sql
-- 添加冗余字段便于快速查询（正规化权衡）
ALTER TABLE accounts ADD COLUMN pep_level INT DEFAULT 0;
ALTER TABLE accounts ADD COLUMN edd_required BOOLEAN DEFAULT FALSE;

-- 添加索引用于批量查询
CREATE INDEX idx_pep_edd ON accounts(pep_level, edd_required);
```

### 2.3 EDD 工作流表

```sql
CREATE TABLE edd_cases (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id CHAR(36) NOT NULL,
    pep_level INT NOT NULL,  -- 引发 EDD 的 PEP 等级
    case_status VARCHAR(30) NOT NULL,  -- PENDING, APPROVED, REJECTED, CLOSED

    -- EDD 详细信息
    wealth_source_statement TEXT,  -- 用户提供的财富来源说明
    wealth_source_verified BOOLEAN,  -- 是否已验证
    trading_pattern_analysis TEXT,  -- 交易模式分析
    trading_pattern_approved BOOLEAN,  -- 是否批准

    -- 审批信息
    assigned_to VARCHAR(36),  -- 分配给的合规官ID
    assigned_at TIMESTAMP,
    completed_by VARCHAR(36),
    completed_at TIMESTAMP,
    approval_notes TEXT,  -- 批准意见

    -- SLA 跟踪
    created_at TIMESTAMP NOT NULL,
    sla_deadline TIMESTAMP NOT NULL,  -- 根据Level和风险等级计算
    deadline_exceeded BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE CASCADE,
    INDEX idx_status (case_status),
    INDEX idx_assigned (assigned_to),
    INDEX idx_sla_deadline (sla_deadline)
) ENGINE=InnoDB;
```

---

## 3. 分类决策树实现

### 3.1 自动分类逻辑（Go Service）

```go
// internal/aml/pep_classifier.go

package aml

import (
    "context"
    "time"
)

type PEPClassifier struct {
    complyadv *ComplyAdvantageClient
    db        *sql.DB
}

// ClassifyPEP 执行自动 PEP 分类逻辑
func (c *PEPClassifier) ClassifyPEP(
    ctx context.Context,
    accountID string,
    kycData *KYCProfile,
    amlScreeningResult *AMLScreeningResult) (*PEPClassification, error) {

    // Step 1: 检查 ComplyAdvantage 结果
    if amlScreeningResult.IsSanctioned {
        // 制裁名单 → 自动 HIGH 风险，不是 PEP 分类
        return nil, fmt.Errorf("account is sanctioned, not applicable for PEP classification")
    }

    // Step 2: 检查是否被标记为 PEP
    if !amlScreeningResult.IsPEP {
        // 非 PEP → 无需进一步分类
        return &PEPClassification{
            AccountID:    accountID,
            IsPEP:        false,
            PEPLevel:     0,
            ClassifiedAt: time.Now().UTC(),
            ClassifiedBy: "SYSTEM",
            Reason:       "NON_PEP",
        }, nil
    }

    // Step 3: 若是 PEP，进行 Level 分类（仅限 Non-HK PEP）
    if amlScreeningResult.PEPJurisdiction == "HK" {
        // HK 官员：自动 Level 1（强制 EDD）
        return c.classifyHKPEP(ctx, accountID, amlScreeningResult)
    } else if amlScreeningResult.PEPJurisdiction == "MAINLAND_CHINA" {
        // 大陆官员：根据级别分类
        return c.classifyMainlandPEP(ctx, accountID, kycData, amlScreeningResult)
    } else {
        // 其他地区 PEP
        return c.classifyOtherPEP(ctx, accountID, amlScreeningResult)
    }
}

// classifyMainlandPEP 大陆官员分类决策树
func (c *PEPClassifier) classifyMainlandPEP(
    ctx context.Context,
    accountID string,
    kycData *KYCProfile,
    result *AMLScreeningResult) (*PEPClassification, error) {

    level := 0
    reason := ""

    // 根据官职级别判断
    switch result.PEPRank {
    case "CENTRAL_POLITBURO", "POLITBURO_STANDING_COMMITTEE":
        // 中央政治局 / 常委 → Level 1
        level = 1
        reason = "CENTRAL_POLITBURO"

    case "STATE_COUNCIL_MINISTER":
        // 国务院部长 → Level 1
        level = 1
        reason = "STATE_COUNCIL_MINISTER"

    case "PROVINCIAL_LEADER":
        // 省级一把手 → Level 1
        level = 1
        reason = "PROVINCIAL_LEADER"

    case "PROVINCIAL_DEPUTY", "CITY_MAYOR", "CITY_GOVERNOR":
        // 省副 / 地级市正职 → Level 2，需人工评估
        level = 2
        reason = "MIDDLE_RANK_OFFICIAL"

    case "CITY_DEPUTY", "COUNTY_LEADER", "SOE_MANAGER":
        // 市副 / 县级 / 国企中层 → Level 3
        level = 3
        reason = "LOW_RANK_OFFICIAL"

    default:
        // 未知级别 → 保守评估为 Level 2
        level = 2
        reason = "UNKNOWN_OFFICIAL_RANK"
    }

    classification := &PEPClassification{
        AccountID:       accountID,
        IsPEP:           true,
        PEPLevel:        level,
        ClassifiedAt:    time.Now().UTC(),
        ClassifiedBy:    "SYSTEM",
        Reason:          reason,
        OfficialPosition: result.PEPTitle,
        OfficialArea:    result.PEPArea,
    }

    // Level 1：自动进入 EDD
    if level == 1 {
        classification.EDDRequired = true
    }

    // 存储分类结果
    if err := c.savePEPClassification(ctx, classification); err != nil {
        return nil, err
    }

    return classification, nil
}

// savePEPClassification 保存分类结果到数据库
func (c *PEPClassifier) savePEPClassification(
    ctx context.Context,
    classification *PEPClassification) error {

    // 插入或更新 pep_classifications
    query := `
        INSERT INTO pep_classifications (
            account_id, is_pep, pep_level, classified_at, classified_by,
            reason, official_position, official_area
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            is_pep = VALUES(is_pep),
            pep_level = VALUES(pep_level),
            classified_at = VALUES(classified_at),
            classified_by = VALUES(classified_by),
            reason = VALUES(reason),
            official_position = VALUES(official_position),
            official_area = VALUES(official_area)
    `

    _, err := c.db.ExecContext(ctx, query,
        classification.AccountID,
        classification.IsPEP,
        classification.PEPLevel,
        classification.ClassifiedAt,
        classification.ClassifiedBy,
        classification.Reason,
        classification.OfficialPosition,
        classification.OfficialArea,
    )

    if err != nil {
        return fmt.Errorf("save PEP classification: %w", err)
    }

    // 同时更新 accounts 表
    updateQuery := `
        UPDATE accounts
        SET pep_level = ?, edd_required = ?, aml_risk_score = ?
        WHERE account_id = ?
    `

    riskScore := "LOW"
    if classification.PEPLevel >= 2 {
        riskScore = "MEDIUM"
    }
    if classification.PEPLevel == 1 {
        riskScore = "HIGH"
    }

    _, err = c.db.ExecContext(ctx, updateQuery,
        classification.PEPLevel,
        classification.PEPLevel == 1,  // Level 1 强制 EDD
        riskScore,
        classification.AccountID,
    )

    return err
}
```

---

## 4. Admin Panel API

### 4.1 PEP 分类查询 API

```go
// internal/api/admin/pep_handler.go

// GET /admin/api/v1/pep-classifications?pep_level=1&status=pending
func (h *AdminHandler) ListPEPClassifications(w http.ResponseWriter, r *http.Request) {
    pepLevel := r.URL.Query().Get("pep_level")  // 1, 2, 3
    eddStatus := r.URL.Query().Get("edd_status")  // pending, approved, rejected

    query := `
        SELECT p.account_id, p.pep_level, p.official_position, p.classified_at,
               a.account_status, e.case_status, e.sla_deadline
        FROM pep_classifications p
        JOIN accounts a ON p.account_id = a.account_id
        LEFT JOIN edd_cases e ON p.account_id = e.account_id
        WHERE 1=1
    `

    var args []interface{}

    if pepLevel != "" {
        query += " AND p.pep_level = ?"
        args = append(args, pepLevel)
    }

    if eddStatus != "" {
        query += " AND e.case_status = ?"
        args = append(args, eddStatus)
    }

    query += " ORDER BY e.sla_deadline ASC LIMIT 50"

    rows, err := h.db.QueryContext(r.Context(), query, args...)
    // ... 返回 JSON
}
```

### 4.2 EDD 案件队列 Admin Panel

```
Admin Panel 显示内容：

┌─────────────────────────────────────────────────────────────┐
│ EDD 案件队列                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ 筛选：PEP Level [ 1 ▼ ]  状态 [ PENDING ▼ ]  优先级 [ - ]   │
│                                                              │
├──┬──────────────┬─────────┬────────────┬──────────────────┤
│# │ 账户ID       │ 官职    │ 分类时间   │ SLA 倒计时        │
├──┼──────────────┼─────────┼────────────┼──────────────────┤
│1 │ user-001     │ 部长    │ 03-28     │ ⏰ 2 天（红）     │
│2 │ user-005     │ 省长    │ 03-27     │ ⏰ 0 天（超期）   │
│3 │ user-012     │ 市长    │ 03-20     │ ⏰ 1 天           │
└──┴──────────────┴─────────┴────────────┴──────────────────┘

点击案件 → 打开详情面板：
  ├─ 用户基本信息
  ├─ KYC 文件
  ├─ AML 筛查结果
  ├─ PEP 分类信息
  ├─ 财富来源说明（待输入）
  ├─ 交易模式分析（待输入）
  ├─ [批准] [驳回] 按钮
  └─ 备注字段
```

---

## 5. ComplyAdvantage 集成

### 5.1 AML 筛查结果回调处理

```go
// internal/kafka/aml_event_consumer.go

// 当 ComplyAdvantage 返回 PEP 匹配时触发
type AMLScreeningCompletedEvent struct {
    AccountID         string
    UserID            string
    ScreeningID       string
    IsPEP             bool
    PEPJurisdiction   string  // "HK", "MAINLAND_CHINA", etc.
    PEPRank           string  // "CENTRAL_POLITBURO", "PROVINCIAL_LEADER", etc.
    PEPTitle          string  // 官职标题
    PEPArea           string  // 任职地区
    RiskScore         string  // "LOW", "MEDIUM", "HIGH"
}

func (c *EventConsumer) ConsumAMLScreeningCompleted(
    ctx context.Context,
    event *AMLScreeningCompletedEvent) error {

    // 调用分类器
    classifier := aml.NewPEPClassifier(c.db, c.complyadv)
    classification, err := classifier.ClassifyPEP(ctx, event.AccountID, nil, &AMLScreeningResult{
        IsPEP:            event.IsPEP,
        PEPJurisdiction:  event.PEPJurisdiction,
        PEPRank:          event.PEPRank,
        PEPTitle:         event.PEPTitle,
        PEPArea:          event.PEPArea,
    })

    if err != nil {
        logger.Error("failed to classify PEP", zap.Error(err))
        return err
    }

    // 若 Level 1，自动创建 EDD 案件
    if classification.PEPLevel == 1 {
        eddCase := &EDDCase{
            AccountID:      event.AccountID,
            PEPLevel:       1,
            CaseStatus:     "PENDING",
            AssignedAt:     time.Now().UTC(),
            SLADeadline:    time.Now().UTC().AddDate(0, 0, 2),  // 2天
        }
        if err := c.eddService.CreateEDDCase(ctx, eddCase); err != nil {
            logger.Error("failed to create EDD case", zap.Error(err))
            return err
        }

        // 发布事件通知 Admin Panel
        c.eventBus.Publish(ctx, "edd.case_created", map[string]interface{}{
            "account_id": event.AccountID,
            "pep_level":  1,
            "sla_deadline": eddCase.SLADeadline,
        })
    }

    return nil
}
```

---

## 6. EDD 工作流服务

### 6.1 EDD 案件处理

```go
// internal/edd/service.go

type EDDService struct {
    db *sql.DB
}

// ApproveEDDCase 合规官批准 EDD 案件
func (s *EDDService) ApproveEDDCase(
    ctx context.Context,
    caseID string,
    complianceOfficerID string,
    notes string) error {

    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    // 1. 更新 EDD 案件状态
    query := `
        UPDATE edd_cases
        SET case_status = 'APPROVED', completed_by = ?, completed_at = ?, approval_notes = ?
        WHERE id = ?
    `
    _, err = tx.ExecContext(ctx, query, complianceOfficerID, time.Now().UTC(), notes, caseID)
    if err != nil {
        return err
    }

    // 2. 获取关联的 account_id
    var accountID string
    err = tx.QueryRowContext(ctx, "SELECT account_id FROM edd_cases WHERE id = ?", caseID).
        Scan(&accountID)
    if err != nil {
        return err
    }

    // 3. 更新 KYC 状态：EDD_APPROVED → KYC_APPROVED
    query = `
        UPDATE accounts
        SET kyc_status = 'KYC_APPROVED', account_status = 'ACTIVE'
        WHERE account_id = ?
    `
    _, err = tx.ExecContext(ctx, query, accountID)
    if err != nil {
        return err
    }

    // 4. 发布事件
    s.eventBus.Publish(ctx, "edd.case_approved", map[string]interface{}{
        "account_id": accountID,
        "case_id":    caseID,
    })

    return tx.Commit()
}

// RejectEDDCase 合规官拒绝 EDD 案件
func (s *EDDService) RejectEDDCase(
    ctx context.Context,
    caseID string,
    complianceOfficerID string,
    notes string) error {

    tx, err := s.db.BeginTx(ctx, nil)
    if err != nil {
        return err
    }
    defer tx.Rollback()

    // 1. 更新 EDD 案件状态
    query := `
        UPDATE edd_cases
        SET case_status = 'REJECTED', completed_by = ?, completed_at = ?, approval_notes = ?
        WHERE id = ?
    `
    _, err = tx.ExecContext(ctx, query, complianceOfficerID, time.Now().UTC(), notes, caseID)
    if err != nil {
        return err
    }

    // 2. 获取 account_id
    var accountID string
    err = tx.QueryRowContext(ctx, "SELECT account_id FROM edd_cases WHERE id = ?", caseID).
        Scan(&accountID)
    if err != nil {
        return err
    }

    // 3. 更新 KYC 状态：KYC_REJECTED，Account 状态：REJECTED
    query = `
        UPDATE accounts
        SET kyc_status = 'KYC_REJECTED', account_status = 'REJECTED'
        WHERE account_id = ?
    `
    _, err = tx.ExecContext(ctx, query, accountID)
    if err != nil {
        return err
    }

    // 4. 发布事件
    s.eventBus.Publish(ctx, "edd.case_rejected", map[string]interface{}{
        "account_id": accountID,
        "case_id":    caseID,
    })

    return tx.Commit()
}
```

---

## 7. 风险评分更新

### 7.1 PEP 对 AML 风险评分的影响

```
AML Risk Score 判断逻辑：

IF PEP Level = 1 OR Sanctioned:
  → AML_RISK = HIGH
  → Account 自动 SUSPENDED（若当前为 ACTIVE）
  → 自动创建 EDD 案件

ELSE IF PEP Level = 2:
  → AML_RISK = MEDIUM
  → 人工评估是否升级 EDD

ELSE IF PEP Level = 3:
  → AML_RISK = LOW（标记为 PEP，但无强制 EDD）
  → 降低交易监控阈值 50%

ELSE:
  → 依据其他因素判断（资金来源、交易模式等）
```

---

## 8. 实现检查清单

### 阶段 1：数据库与模型（0.5 天）
- [ ] 创建 `pep_classifications` 表
- [ ] 更新 `accounts` 表添加 `pep_level`, `edd_required` 字段
- [ ] 创建 `edd_cases` 表
- [ ] 定义 Go 数据模型 (struct)

### 阶段 2：分类逻辑（1 天）
- [ ] 实现 `PEPClassifier.ClassifyPEP()` 自动分类
- [ ] 实现大陆官员分类决策树 (`classifyMainlandPEP`)
- [ ] 实现 HK 官员分类 (`classifyHKPEP`)
- [ ] 单元测试（各分类等级）

### 阶段 3：EDD 工作流（1.5 天）
- [ ] 实现 `EDDService.CreateEDDCase()`
- [ ] 实现 `EDDService.ApproveEDDCase()`
- [ ] 实现 `EDDService.RejectEDDCase()`
- [ ] 实现 SLA 计算和超期告警
- [ ] Kafka 事件发送

### 阶段 4：Admin Panel API（1 天）
- [ ] 实现 `ListPEPClassifications` (列表 + 筛选)
- [ ] 实现 `GetPEPDetail` (详情)
- [ ] 实现 `GetEDDCase` (EDD 案件详情)
- [ ] 实现 `ApproveEDD` / `RejectEDD` (操作)

### 阶段 5：ComplyAdvantage 集成（0.5 天）
- [ ] 实现 Kafka consumer 处理 AML 事件
- [ ] 调用分类器并创建 EDD 案件

### 阶段 6：测试（1 天）
- [ ] 集成测试：KYC → AML → PEP 分类 → EDD
- [ ] 回归测试：既有流程无影响
- [ ] 性能测试：批量分类（1000+ 账户）

**总工作量**：约 5-6 天

---

## 参考资料

- 产品规格：`docs/prd/aml-compliance.md` § 4.3-4.4
- 研究资料：`docs/research/mainland-pep-*.md`
- 状态机规范：`docs/specs/state-machine-relations.md` § 3.1
