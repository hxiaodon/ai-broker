# AMS PRD: AML 合规规格

> **版本**: v0.1
> **日期**: 2026-03-17
> **作者**: AMS Engineering
> **状态**: Draft — 待合规团队评审
>
> 本文档定义 AMS 的 AML（反洗钱）合规完整规格，覆盖制裁筛查供应商选型、风险评分算法、PEP 判定、SAR Tipping-off API 设计、CTR 责任边界、以及与 Fund Transfer 服务的职责分工。

---

## 目录

1. [AML 供应商选型决策](#1-aml-供应商选型决策)
2. [AML 架构设计](#2-aml-架构设计)
3. [制裁筛查规格](#3-制裁筛查规格)
4. [PEP 筛查规格](#4-pep-筛查规格)
5. [AML 风险评分算法](#5-aml-风险评分算法)
6. [SAR Tipping-off 防护设计](#6-sar-tipping-off-防护设计)
7. [CTR 责任边界（AMS vs Fund Transfer）](#7-ctr-责任边界ams-vs-fund-transfer)
8. [结构性交易检测（Structuring）](#8-结构性交易检测structuring)
9. [持续监控（Ongoing Monitoring）](#9-持续监控ongoing-monitoring)
10. [HK STR 申报（JFIU STREAMS 2）](#10-hk-str-申报jfiu-streams-2)
11. [AML 相关数据模型补充](#11-aml-相关数据模型补充)
12. [开放决策点](#12-开放决策点)

---

## 1. AML 供应商选型决策

### 1.1 选型结论

**首选：ComplyAdvantage**
**备选/补充（高风险 EDD 案件）：LSEG World-Check**

### 1.2 供应商对比（关键维度）

| 维度 | Dow Jones | LSEG World-Check | **ComplyAdvantage** | LexisNexis | Sanctions.io |
|------|-----------|-----------------|---------------------|------------|--------------|
| OFAC SDN/Sectoral | ✅ | ✅ | ✅ | ✅ | ✅ |
| UN 制裁名单 | ✅ | ✅ | ✅ | ✅ | ✅ |
| HK UNATMO/UNSO | ✅（聚合） | ✅（亚太团队） | ⚠️（需确认） | ✅ | ⚠️（需确认） |
| HK JFIU 国内名单 | ⚠️需确认 | **最佳覆盖** | ⚠️需确认 | ✅ | ⚠️需确认 |
| 中国大陆 PEP（Non-HK PEP） | ✅ | **最佳（亚太研究员）** | ✅（ML 驱动） | ✅（最大 DB） | ✅（100万+记录） |
| PEP 关联方（RCA） | ✅ | ✅ | ✅ | ✅ | ✅ |
| OFAC 更新速度 | 1 个工作日 | 接近实时 | **分钟级** | 每日 | 每 60 分钟 |
| API 模式 | REST（数据源） | REST（WC One） | **REST + Webhook** | XML/批处理 | REST + Webhook |
| 中文姓名模糊匹配 | 人工编辑 | 人工+引擎 | **ML 嵌入模型** | ML+人工 | NLP/ML |
| 误报率降低 | 取决于平台 | 可配置 | **82%（声称）** | 97%自动关闭 | NLP 描述 |
| SOC 2 Type II | 未确认 | 需确认 | ✅ | 部分确认 | ✅ |
| ISO 27001 | 未确认 | 需确认 | ✅ | 部分确认 | 未确认 |
| 定价模式 | 企业订阅 | 积分分层 | **按调用量** | 企业订阅 | **$899/5k次（公开）** |
| Webhook 持续监控 | 每周轮询 | 托管服务 | **是（Push）** | 平台驱动 | **是（Push）** |

### 1.3 ComplyAdvantage 选型理由

1. **分钟级 OFAC 更新**：竞争对手最快为 60 分钟（Sanctions.io）或 1 个工作日（Dow Jones）。对于经纪商，在 OFAC 更新和每日批量筛查之间的窗口期内，客户可能发起出金——实时更新消除此风险
2. **Webhook Push 持续监控**：当客户数据匹配新制裁条目时，主动推送 Webhook 到 AMS 服务，无需轮询。符合 Go 微服务事件驱动架构
3. **ML 嵌入模型处理中文姓名**：针对拼音变体（Wu/Woo）、简繁体转换、别名处理的技术文档公开可查，在中国大陆用户场景下表现最优
4. **REST API + OAuth2**：Go 集成最简洁，无 CGO，无 XML
5. **SOC 2 Type II + ISO 27001**：Revolut、Wise、Currencycloud 等受监管金融机构使用，监管可接受性高
6. **按调用量计费**：早期无需承诺高保底量

### 1.4 World-Check 作为补充

对于**高风险 EDD 案件**（AML 评分 HIGH、Non-HK PEP、PENDING_EDD 状态），建议使用 LSEG World-Check 进行**二次确认**：

- World-Check 是 HK HKMA 受监管机构的事实标准参考
- 其亚太研究员团队对中国大陆官员（Non-HK PEP）的覆盖深度和更新质量高于纯 ML 方案
- 在 HKMA 检查时，"我们用 World-Check 对所有 EDD 案件做二次确认"是有力的合规答复

**架构设计**：ComplyAdvantage 用于所有账户的实时 + 持续筛查；World-Check 仅用于 EDD 升级案件的人工增强查询（Admin Panel 侧，非 API 自动化）。

---

## 2. AML 架构设计

### 2.1 筛查层次

```
账户开立
    │
    ├── [同步，阻塞，<400ms] ──── 制裁筛查（OFAC SDN + UN）
    │                            ComplyAdvantage 同步 API
    │                            命中 → 立即拒绝（HTTP 451）
    │
    └── [异步，非阻塞] ─────── PEP + 不良媒体筛查
                                asynq 任务队列
                                结果 → 更新账户风险评分
                                HIGH 风险 → PENDING_EDD
```

### 2.2 AMS 与 Fund Transfer 的 AML 边界

```
AMS 负责：
  ├── 开户时制裁/PEP 筛查
  ├── 账户级 AML 风险评分
  ├── 每日全量账户重新筛查（批量任务）
  ├── ComplyAdvantage Webhook 处理（新制裁命中时）
  └── 向下游服务暴露 aml_risk_score（只读）

Fund Transfer 负责：
  ├── 单笔交易 AML 筛查（资金流向）
  ├── CTR 阈值监控 + 自动申报
  ├── 结构性交易检测（Structuring）
  └── SAR 触发建议（通知 AMS 升级风险评分）
```

---

## 3. 制裁筛查规格

### 3.1 筛查名单

| 名单 | 适用市场 | 更新频率（ComplyAdvantage） |
|------|----------|---------------------------|
| OFAC SDN List | US | 分钟级 |
| OFAC Sectoral Sanctions | US | 分钟级 |
| OFAC Non-SDN Lists | US | 分钟级 |
| UN Consolidated List（UNSO/UNATMO） | HK | 分钟级 |
| HK 内部指定名单 | HK | 待确认覆盖情况 |
| EU Consolidated Sanctions | 两地 | 分钟级 |

> **待决策**：ComplyAdvantage 对 HK JFIU 国内指定名单的覆盖情况须在合同谈判时明确。如不覆盖，需建立独立 JFIU 名单同步机制（每日从 JFIU 官网拉取）。

### 3.2 同步制裁筛查 API 调用模式

```go
// 开户时同步制裁筛查（阻塞，必须在账户激活前完成）
func (s *AMLService) ScreenForSanctions(ctx context.Context, profile *KYCProfile) (*SanctionsResult, error) {
    // 超时设置：400ms，防止影响开户 UX
    ctx, cancel := context.WithTimeout(ctx, 400*time.Millisecond)
    defer cancel()

    req := &complyadvantage.SearchRequest{
        SearchTerm: profile.FullName.Plaintext(),
        Filters: complyadvantage.Filters{
            Types:  []string{"sanction"}, // 仅制裁，PEP 走异步
            Entity: "individual",
        },
        ShareURL: false,
    }

    resp, err := s.caClient.Search(ctx, req)
    if err != nil {
        // 筛查服务超时或失败：默认通过，记录告警（不阻塞开户）
        // 监控指标：ams_aml_screening_timeout_total
        s.metrics.AMLTimeouts.Inc()
        s.logger.Error("aml sanctions screening timeout", zap.Error(err),
            zap.String("account_id", profile.AccountID))
        return &SanctionsResult{Status: SanctionsStatusClear}, nil
    }

    if resp.TotalHits > 0 && resp.HasConfirmedHit() {
        return &SanctionsResult{
            Status:  SanctionsStatusHit,
            HitList: resp.Hits[0].ListName,
        }, nil
    }
    return &SanctionsResult{Status: SanctionsStatusClear}, nil
}
```

> **超时策略**：制裁 API 超时时，**默认通过**并记录告警，不阻塞开户流程。原因：误报的代价（用户无法开户）高于漏报的代价（账户仍需通过后续监控捕获）。对于高优先级案件，可调整为默认拒绝。

### 3.3 每日全量重新筛查

```go
// 每天 UTC 03:00 批量重新筛查，防止制裁名单新增条目漏网
// 使用 asynq fan-out 模式（见 tech-stack.md 第 7 节）
func (d *AMLDailyScreeningDispatcher) Dispatch(ctx context.Context) error {
    var offset int
    for {
        accountIDs, _ := d.repo.FetchActiveAccountIDs(ctx, offset, 1000)
        if len(accountIDs) == 0 { break }

        for _, id := range accountIDs {
            payload, _ := json.Marshal(map[string]string{"account_id": id})
            d.asynqClient.Enqueue(asynq.NewTask("aml:screen-account", payload,
                asynq.MaxRetry(3),
                asynq.Timeout(30*time.Second),
                asynq.Queue("aml"),
            ))
        }
        offset += 1000
    }
    return nil
}
```

---

## 4. PEP 筛查规格

### 4.1 PEP 分类（依据 2023 AMLO 修订）

| 类别 | 定义 | EDD 要求 |
|------|------|----------|
| **非香港 PEP（Non-HK PEP）** | 外国政府/国际组织高级职位人士，**含中国内地 PEP** | **强制 EDD + 高管批准 + 财富来源证明** |
| 香港 PEP | 香港政府高级职位人士 | 风险评估后决定是否 EDD |
| 国际组织 PEP | 国际组织高级职位人士 | 风险评估后决定是否 EDD |
| 前非香港 PEP | 上述职位已卸任者 | 风险评估后可豁免 EDD |
| PEP 关联方（RCA） | 直系亲属、已知关联人 | 风险评估，不自动 EDD |

### 4.2 中国大陆官员（Non-HK PEP）的实操边界

依据 2023 年 6 月 1 日生效的 AMLO 修订：
- 大陆省部级及以上官员 = Non-HK PEP → **强制 EDD**
- 大陆县市级官员：风险评估后决定（实务中多家机构将县处级及以上均列为 Non-HK PEP）
- **建议**：在系统中将所有标记为 `NON_HK_PEP` 的账户统一要求 EDD，不区分级别，以防止监管争议

### 4.3 PEP 异步筛查流程

```go
// PEP + 不良媒体筛查任务（通过 asynq 异步执行）
func (w *AMLWorker) HandlePEPScreen(ctx context.Context, t *asynq.Task) error {
    var payload struct{ AccountID string }
    json.Unmarshal(t.Payload(), &payload)

    profile, _ := w.profileRepo.Get(ctx, payload.AccountID)

    resp, err := w.caClient.Search(ctx, &complyadvantage.SearchRequest{
        SearchTerm: profile.FullName.Plaintext(),
        Filters: complyadvantage.Filters{
            Types:  []string{"pep", "adverse-media"}, // PEP + 不良媒体
        },
    })
    if err != nil {
        return fmt.Errorf("pep screen %s: %w", payload.AccountID, err) // asynq 自动重试
    }

    // 更新账户风险评分
    riskScore := calculateRiskScore(profile, resp)
    w.amlRepo.UpdateRiskScore(ctx, payload.AccountID, riskScore, resp.Hits)

    // 触发后续流程
    if riskScore == RiskScoreHigh || resp.HasPEPHit() {
        w.eventBus.Publish(ctx, "ams.aml.flagged", AMLFlaggedEvent{
            AccountID: payload.AccountID,
            RiskScore: riskScore,
            PEPType:   extractPEPType(resp),
        })
    }
    return nil
}
```

---

## 5. AML 风险评分算法

### 5.1 风险因子及权重（建议值，须合规团队确认）

| 因子 | 低风险 | 中风险 | 高风险 | 权重 |
|------|--------|--------|--------|------|
| 居住地 | 本地居民 | 非香港/非美国居民 | FATF 高风险国家 | 25% |
| 职业 | 雇员/退休 | 商人/自雇 | 政府官员/律师/会计（高风险职业） | 15% |
| 资金来源 | 薪酬/投资 | 经营所得 | 复杂/不明 | 20% |
| PEP 状态 | 非 PEP | HK PEP/前非HK PEP | Non-HK PEP | 25% |
| 不良媒体 | 无命中 | 轻微/过往 | 洗钱/欺诈/制裁相关报道 | 15% |

**总分 = Σ(因子得分 × 权重)**：
- 0-30：`LOW`
- 31-60：`MEDIUM`
- 61-100：`HIGH`

> **注**：评分算法须由合规团队与外部 AML 顾问审核后最终确认。本文中的权重为工程占位值。

### 5.2 风险评分触发的业务影响

| 风险等级 | 业务限制 |
|----------|---------|
| `LOW` | 正常开户；出金可自动审批 |
| `MEDIUM` | 开户可正常进行；出金须**人工审核**（Fund Transfer 规则） |
| `HIGH` | 触发 EDD；账户进入 `PENDING_EDD`；须合规经理批准才能激活 |

---

## 6. SAR Tipping-off 防护设计

### 6.1 法律要求

依据 31 CFR §1023.320（美股）和 AMLO Part IV（港股）：
- 一旦提交 SAR/STR，**严禁向报告对象或任何相关方披露**
- 违规属于联邦犯罪（美）/ 刑事罪行（港）

### 6.2 数据模型设计：两层分离

```go
// 层一：客户端可见的账户状态（面向用户 API 使用）
type AccountPublicView struct {
    ID        string        `json:"id"`
    Status    AccountStatus `json:"status"`    // ACTIVE, SUSPENDED, RESTRICTED, CLOSED
    // 绝对不含任何 SAR/AML 内部状态
}

// 层二：合规内部视图（仅限 /internal/compliance/* 端点，需 PermViewSAR 权限）
type AccountComplianceView struct {
    AccountID       string        `json:"-"` // 内部使用，不序列化到外部响应
    SARStatus       SARStatus     `json:"-"` // SAR_NONE, SAR_PENDING, SAR_FILED
    SARFilingCount  int           `json:"-"` // 历史 SAR 申报次数
    CTRFilingCount  int           `json:"-"` // 历史 CTR 申报次数
    AMLRiskScore    RiskLevel     `json:"-"` // LOW, MEDIUM, HIGH
    AMLFlags        []AMLFlag     `json:"-"` // 活跃的 AML 标记
    WatchlistHits   []WatchlistHit `json:"-"`
}
```

### 6.3 API 路由层的物理隔离

```go
// 公开 API 路由（所有已认证用户可访问）
r.Route("/v1/accounts", func(r chi.Router) {
    r.Use(jwtAuthMiddleware)
    r.Get("/{id}", getAccountPublic)  // 只返回 AccountPublicView
})

// 内部合规路由（仅合规角色可访问，API Gateway 层额外鉴权）
r.Route("/internal/compliance", func(r chi.Router) {
    r.Use(internalNetworkOnly)           // 只允许内网调用（非公网）
    r.Use(RequirePermission(PermViewSAR))
    r.Get("/accounts/{id}/review", getAccountComplianceView)
    r.Get("/accounts/{id}/sar-status", getSARStatus) // 审计员专用
})
```

### 6.4 面向客户的账户限制说明

当账户因 SAR 调查被限制时，向用户展示的信息**必须使用泛化描述**：

```
✅ 正确：
"您的账户已被临时限制。如有疑问，请联系客服（support@broker.com）"

❌ 错误（触犯 Tipping-off）：
"您的账户正在进行 AML 审查"
"已就您的账户提交可疑活动报告"
"您的交易模式触发了反洗钱监控"
```

### 6.5 SAR 相关审计日志隔离

SAR 相关的审计记录须写入**独立的合规审计日志表**（`compliance_audit_events`），与常规 `account_status_events` 分离：

```sql
CREATE TABLE compliance_audit_events (
    id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id   CHAR(36) NOT NULL,
    event_type   VARCHAR(100) NOT NULL,  -- SAR_FILED, CTR_FILED, EDD_INITIATED
    event_data   JSON NOT NULL,          -- 加密存储敏感内容
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by   CHAR(36) NOT NULL,      -- 合规官 ID
    -- 严格访问控制：app_user 只有 INSERT 权限，无 SELECT/UPDATE/DELETE
    INDEX idx_account_id (account_id),
    INDEX idx_event_type (event_type)
) ENGINE=InnoDB;
```

数据权利（GDPR/PDPO 访问权请求）：SAR 相关记录**明确豁免**于用户数据访问权请求，依据 31 CFR §1023.320(e)(1)(ii) 和 HK PDPO s.58。

---

## 7. CTR 责任边界（AMS vs Fund Transfer）

### 7.1 微服务职责分工

**行业标准**：Fund Transfer 服务拥有 CTR 归档职责，AMS 提供账户级 AML 数据支撑。

| 职责 | 负责服务 |
|------|---------|
| 开户时 OFAC/PEP 筛查 | **AMS** |
| 账户级 AML 风险状态机 | **AMS** |
| 持续账户监控（制裁重新筛查） | **AMS** |
| 向下游暴露 `aml_risk_score` | **AMS**（只读接口） |
| 单笔交易 CTR 阈值监控 | **Fund Transfer** |
| 24 小时累计金额统计 | **Fund Transfer** |
| CTR 自动申报（FinCEN Form 104） | **Fund Transfer** |
| 结构性交易检测 | **Fund Transfer** |
| SAR 触发建议 | **Fund Transfer**（→ 事件通知 AMS 升级风险评分） |
| SAR 最终申报 | **Fund Transfer** 或**独立合规服务**（合规经理审批后） |
| STR 申报（JFIU STREAMS 2） | **Fund Transfer** 或**独立合规服务** |

### 7.2 AMS 提供给 Fund Transfer 的接口

```protobuf
// AMS gRPC 接口，供 Fund Transfer 调用
service AccountAMLService {
    // 获取账户 AML 风险评分（用于出金审批决策）
    rpc GetAMLStatus(GetAMLStatusRequest) returns (GetAMLStatusResponse);
}

message GetAMLStatusRequest {
    string account_id = 1;
}

message GetAMLStatusResponse {
    string aml_risk_score = 1;  // LOW, MEDIUM, HIGH
    bool   has_active_flags = 2; // 是否有活跃的 AML 标记
    // 注意：SAR 状态不在此响应中（Tipping-off 防护）
}
```

### 7.3 Fund Transfer → AMS 反向通知

当 Fund Transfer 触发 SAR 时，通过 Kafka 事件通知 AMS 升级账户风险：

```go
// Fund Transfer 发布事件
eventBus.Publish("ams.external.sar_triggered", SARTriggeredEvent{
    AccountID: accountID,
    Reason:    "suspicious_withdrawal_pattern",
    TriggeredAt: time.Now().UTC(),
})

// AMS 消费此事件，更新账户风险评分
func (s *AMLService) OnSARTriggered(ctx context.Context, event SARTriggeredEvent) error {
    return s.amlRepo.UpdateRiskScore(ctx, event.AccountID, RiskScoreHigh,
        []AMLFlag{{Type: "SAR_PENDING", Source: "fund_transfer", At: event.TriggeredAt}})
}
```

---

## 8. 结构性交易检测（Structuring）

### 8.1 职责归属

**结构性交易检测属于 Fund Transfer 服务**，不属于 AMS。

原因：
- 需要访问该用户的完整交易历史（AMS 不持有交易数据）
- 需要 24 小时/7 天滚动时间窗口聚合
- 每笔交易完成后实时触发

### 8.2 AMS 的配合职责

AMS 须向 Fund Transfer 暴露以下数据（通过 gRPC 只读接口）：
- `account_created_at`（账龄短的账户更高风险）
- `aml_risk_score`（影响监控强度）
- `kyc_tier`（影响 CTR 阈值）

### 8.3 结构性交易检测规则参考（供 Fund Transfer 服务使用）

以下规则由 FFIEC BSA/AML 指南定义，记录于此供跨服务参考：

```sql
-- 24 小时内累计入金接近 CTR 阈值
SELECT user_id, SUM(amount) AS total_24h, COUNT(*) AS tx_count
FROM fund_transactions
WHERE direction = 'DEPOSIT'
  AND created_at >= NOW() - INTERVAL 24 HOUR
  AND status = 'COMPLETED'
GROUP BY user_id
HAVING total_24h >= 9000          -- US: CTR 阈值 90% ($9,000)
    OR total_24h >= 108000        -- HK: CTR 阈值 90% (HK$108,000)
    OR (tx_count >= 3 AND total_24h >= 7000);  -- 多笔分散

-- 7 天内多笔 $3,000-$9,999 交易（典型分散模式）
SELECT user_id, COUNT(*) AS tx_count, SUM(amount) AS total_7d
FROM fund_transactions
WHERE amount BETWEEN 3000 AND 9999
  AND created_at >= NOW() - INTERVAL 7 DAY
GROUP BY user_id
HAVING tx_count >= 3;
```

---

## 9. 持续监控（Ongoing Monitoring）

### 9.1 ComplyAdvantage Webhook 持续监控

当客户数据与新制裁条目匹配时，ComplyAdvantage 主动 Push Webhook：

```go
// 持续监控 Webhook 处理器
func (h *AMLMonitoringHandler) HandleMonitoringAlert(w http.ResponseWriter, r *http.Request) {
    // 验证 ComplyAdvantage Webhook 签名（OAuth2 Bearer Token 或 HMAC）
    var alert ComplyAdvantageAlert
    json.NewDecoder(r.Body).Decode(&alert)

    switch alert.AlertType {
    case "SANCTIONS_MATCH":
        // 立即冻结账户
        h.amlService.FreezeAccountForSanctionsHit(r.Context(), alert.EntityID, alert.MatchedList)
        // 发布事件通知所有下游服务
        h.eventBus.Publish(r.Context(), "ams.aml.sanctions_hit", SanctionsHitEvent{
            AccountID:   alert.EntityID,
            MatchedList: alert.MatchedList,
        })
    case "PEP_STATUS_CHANGE":
        // 更新 PEP 状态，可能触发 EDD
        h.amlService.UpdatePEPStatus(r.Context(), alert.EntityID, alert.PEPType)
    }
    w.WriteHeader(http.StatusOK)
}
```

### 9.2 每日全量重新筛查

除了 Webhook 推送，每天 UTC 03:00 执行全量账户重新筛查（见第 3.3 节），作为 Webhook 的双重保障。

---

## 10. HK STR 申报（JFIU STREAMS 2）

### 10.1 STREAMS 2 关键变更（2026 年 2 月启用）

| 变更点 | 影响 |
|--------|------|
| 传统申报方式（邮件/传真/邮寄）永久终止 | 所有 SFC 持牌机构须使用 STREAMS 2 |
| 三种电子申报方式：XML / PDF / 网页填写 | 系统集成选 **XML 提交**（自动化） |
| XML 须附 HK Post e-cert 数字签名 | 机构须提前申请 e-cert 并在合规服务中集成 |
| 技术测试要求 | 上线前须与 JFIU 完成技术联调测试 |

### 10.2 STR XML 申报集成（Fund Transfer 或独立合规服务负责）

```go
// STR XML 申报（JFIU 提供 XML Schema）
// 此代码属于 Fund Transfer 或独立合规服务，非 AMS
// AMS 职责：提供账户 KYC 数据（姓名、HKID 等）供 STR 填充

type STRXMLRecord struct {
    AccountID   string
    KYCProfile  *KYCProfile // 从 AMS 获取
    Transactions []Transaction // 从 Fund Transfer 获取
    ReasonForReport string
    // ... JFIU XML Schema 字段
}
```

### 10.3 STR 记录保留

依据 JFIU 要求，STR 记录须保留 **5 年**，存储于 `compliance_audit_events` 表（append-only，WORM 存储），并记录 STREAMS 2 返回的参考号。

---

## 11. AML 相关数据模型补充

对 `account-financial-model.md` 中 AML 字段的补充说明：

### 11.1 `accounts` 表新增字段

```sql
-- AML 字段（部分已在 financial-model 中定义，此处补充）
aml_last_screened_at     TIMESTAMP NULL,          -- 最近一次完整 AML 筛查时间
aml_screening_provider   VARCHAR(50) NOT NULL DEFAULT 'complyadvantage',
aml_external_entity_id   VARCHAR(100) NULL,       -- ComplyAdvantage entityId，用于持续监控
sanctions_freeze_reason  TEXT NULL,               -- 制裁冻结原因（内部）
pep_type                 ENUM('NONE','NON_HK_PEP','HK_PEP','INTL_ORG_PEP','FORMER_NON_HK_PEP') DEFAULT 'NONE',
pep_verified_at          TIMESTAMP NULL,
edd_required             BOOLEAN NOT NULL DEFAULT FALSE,
edd_approved_by          CHAR(36) NULL,           -- 高管审批人 ID（Non-HK PEP 必填）
edd_approved_at          TIMESTAMP NULL,
```

### 11.2 持续监控订阅管理

```sql
CREATE TABLE aml_monitoring_subscriptions (
    id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id     CHAR(36) NOT NULL,
    provider       VARCHAR(50) NOT NULL,          -- 'complyadvantage'
    external_id    VARCHAR(100) NOT NULL,         -- 供应商侧实体 ID
    subscribed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    INDEX idx_account_id (account_id),
    INDEX idx_external_id (external_id)
) ENGINE=InnoDB;
```

---

## 12. 开放决策点

| # | 问题 | 影响 | 优先级 |
|---|------|------|--------|
| 1 | **ComplyAdvantage 对 HK JFIU 国内指定名单的覆盖情况** | 是否需要自建 JFIU 名单同步 | High |
| 2 | **AML 风险评分算法的具体因子权重** | 须合规团队 + 外部 AML 顾问确认 | High |
| 3 | **EDD 案件使用 LSEG World-Check 二次确认的合同安排** | EDD 工作流设计 | Medium |
| 4 | **制裁筛查 API 超时时的默认行为**：默认通过 or 默认拒绝？ | 用户体验 vs 合规风险取舍 | High |
| 5 | **STR 申报由 Fund Transfer 服务直接做，还是设立独立合规服务？** | 架构决策，影响两个服务的开发工作量 | Medium |
| 6 | **SAR 申报审批流程**：Fund Transfer 建议 → 合规经理审批 → 申报，这个工作流在哪个服务中实现？ | Admin Panel 设计 | Medium |
| 7 | **ComplyAdvantage vs Sanctions.io 最终选型**（若预算紧张） | 合规风险接受度 | High |

---

*参考：AML Screening Vendor Research Report（2026-03-17）、`docs/specs/account-financial-model.md`（AML 数据模型）、`.claude/rules/fund-transfer-compliance.md`（Fund Transfer AML 规则）、31 CFR §1023.320（SAR 规则）、JFIU STREAMS 2 官方公告*
