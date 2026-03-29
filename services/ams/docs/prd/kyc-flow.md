---
type: domain-prd
version: v1.0
updated_date: 2026-03-29T16:00+08:00
surface_prd:
  - path: ../../../mobile/docs/prd/01-auth.md
    description: "用户登录与注册流程"
  - path: ../../../mobile/docs/prd/02-kyc.md
    description: "用户开户 UI 流程、7 步开户、审核状态显示"
revisions:
  - rev: 1
    date: 2026-03-29T16:00+08:00
    author: product-manager
    summary: "新增状态聚合规则表、W-8BEN 冻结逻辑、审核 SLA 完整定义、大陆居民 PEP 官职采集"
---
> 本文档定义 AMS KYC 流程的完整产品规格，覆盖供应商选型决策、各用户群体开户路径、状态机设计、W-8BEN 续签工作流，以及与移动端/Admin Panel 的集成接口。

---

## 目录

1. [KYC 供应商选型决策](#1-kyc-供应商选型决策)
2. [ISO/IEC 30107-3 活体检测等级](#2-isoiec-30107-3-活体检测等级)
3. [Go 后端集成架构](#3-go-后端集成架构)
4. [开户路径 — 各用户群体](#4-开户路径--各用户群体)
5. [KYC 状态机](#5-kyc-状态机)
6. [HK 非面对面开户合规要求](#6-hk-非面对面开户合规要求)
7. [联名账户 KYC 设计（Joint Account）](#7-联名账户-kyc-设计joint-account)
8. [公司账户 KYC（UBO 穿透）](#8-公司账户-kycubo-穿透)
9. [专业投资者（PI）认定流程](#9-专业投资者pi认定流程)
10. [W-8BEN 续签工作流](#10-w-8ben-续签工作流)
11. [Admin Panel KYC 审核队列](#11-admin-panel-kyc-审核队列)
12. [KYC 被拒申诉流程](#12-kyc-被拒申诉流程)
13. [开放决策点](#13-开放决策点)

---

## 1. KYC 供应商选型决策

### 1.1 选型结论

**首选：Sumsub**
**备选（大客户量企业谈判后）：Jumio**

### 1.2 评分矩阵

| 评估维度 | 权重 | Jumio | Onfido (Entrust) | Sumsub | iDenfy |
|----------|------|-------|-----------------|--------|--------|
| HKID 明确支持 | 20% | ✅ 5 | ✅ 5 | ✅ 5（97.89% 通过率） | ⚠️ 未确认 2 |
| 大陆身份证支持 | 20% | ✅ 5 | ✅ 4 | ✅ 5（中文界面） | ⚠️ 未确认 2 |
| PAD Level 2 认证 | 15% | ✅ 5（Oct 2025） | ✅ 5（Motion） | ✅ 5（0错误，May 2025） | ⚠️ 间接 3 |
| HK 监管合规定位 | 15% | ✅ 4（HKMA 页面） | ❌ 2（欧洲中心） | ✅ 5（SFC/AMLO/VATP） | ❌ 1 |
| 集成难度（Go+Flutter） | 15% | 中 3（4-8周） | 中 3（3-6周） | 易 5（2-4周） | 最易 4（1-2周） |
| 定价透明度 | 10% | ❌ 1（无公开） | ❌ 1（无公开） | ✅ 5（$1.35-$1.85/次） | ✅ 4（$1.30/次） |
| 可靠性 & 规模 | 5% | 中 3（113次中断记录） | 中 3（收购后不确定） | 高 5 | 低 2 |
| **加权总分** | | **4.0** | **3.2** | **4.9** | **2.3** |

### 1.3 Sumsub 选型理由

1. **文档库最广**（14,000+模板，220+国家）：覆盖新旧版 HKID、居民身份证、港澳通行证等所有目标用户群体文件
2. **HK 监管定位最强**：唯一有明确 SFC/AMLO/VATP/HKMA 页面的供应商；新加坡 APAC 总部；繁简中文 Dashboard；参与香港金融科技周
3. **PAD 认证最高**：2025 年 Level 1 + Level 2，均零错误（所有供应商中唯一）
4. **FATF 全球数字身份认证**：全球首个通过的供应商，对双司法管辖区合规意义重大
5. **定价透明**：$1.35-$1.85/次，按成功验证计费，早期可预算规划
6. **集成最快**（2-4周）：HMAC 签名 + Webhook 模式与 Go 微服务架构完美契合

### 1.4 Jumio 作为大规模备选

当月 KYC 量超过 **50,000 次** 时，与 Jumio 进行企业价格谈判，Jumio 的单价可大幅降低（Coinbase 级别合同），且其在 HSBC 等机构金融客户中的品牌背书更强，有助于 HKMA 检查时的供应商尽职调查答复。

---

## 2. ISO/IEC 30107-3 活体检测等级

### 2.1 Level 1 vs Level 2 技术差异

| 维度 | Level 1 | Level 2 |
|------|---------|---------|
| 攻击材料成本上限 | $30 | $300 |
| 测试攻击类型 | 2D：打印照片、视频回放 | 3D：树脂/硅胶面具、AI 合成人脸 |
| 最大欺骗接受率（APCER） | 0% | ≤1% |
| 最大真实用户拒绝率（BPCER） | ≤15% | ≤15% |

### 2.2 为何要求 Level 2

- 证券经纪商面临的欺诈攻击日趋复杂，3D 面具和 Deepfake 注入攻击频发
- Level 2 认证提供独立审计的证据（iBeta 确认函），在 SFC/HKMA 检查时构成有力抗辩材料
- Sumsub 在 2025 年 Level 1 + Level 2 测试中均达到**零错误**（行业最高标准）

---

## 3. Go 后端集成架构

### 3.1 标准三步流程（适用所有供应商）

```
Go AMS 后端                    Sumsub API               Flutter App
    │                              │                          │
    │──POST /resources/accessTokens/sdk──►│                  │
    │   (签名 HMAC-SHA256 请求)           │                  │
    │◄── {accessToken: "..."}            │                  │
    │                              │                          │
    │──accessToken──────────────────────────────────────────►│
    │                              │                          │
    │                              │◄──SDK 活体+文件采集──────│
    │                              │                          │
    │◄──Webhook POST (HMAC-SHA256 签名)──│                   │
    │   {event: "applicantReviewed",     │                   │
    │    reviewAnswer: "GREEN"}          │                   │
    │                              │                          │
    │──GET /applicants/{id}──────────►│                       │
    │◄── {full KYC data} ◄─────────── │                       │
```

### 3.2 Go Webhook 签名验证

```go
// Sumsub webhook 签名验证中间件
func verifySumsubWebhook(secret string) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            body, _ := io.ReadAll(r.Body)
            r.Body = io.NopCloser(bytes.NewBuffer(body)) // 重置供后续读取

            sig := r.Header.Get("x-payload-digest")
            alg := r.Header.Get("X-Payload-Digest-Alg") // "HMAC_SHA256_HEX"

            mac := hmac.New(sha256.New, []byte(secret))
            mac.Write(body)
            expected := hex.EncodeToString(mac.Sum(nil))

            // 时序安全比较，防止时序攻击
            if !hmac.Equal([]byte(expected), []byte(sig)) {
                http.Error(w, "invalid webhook signature", http.StatusUnauthorized)
                return
            }
            _ = alg // 当前仅支持 HMAC_SHA256_HEX，未来可扩展
            next.ServeHTTP(w, r)
        })
    }
}
```

### 3.3 Webhook 事件处理（幂等）

```go
type SumsubWebhookPayload struct {
    ApplicantID string `json:"applicantId"`
    Type        string `json:"type"` // applicantReviewed, applicantCreated 等
    ReviewResult *ReviewResult `json:"reviewResult,omitempty"`
}

type ReviewResult struct {
    ReviewAnswer string   `json:"reviewAnswer"` // GREEN, RED
    RejectType   string   `json:"rejectType"`   // FINAL, RETRY
    RejectLabels []string `json:"rejectLabels"`
}

func (h *KYCWebhookHandler) Handle(w http.ResponseWriter, r *http.Request) {
    var payload SumsubWebhookPayload
    json.NewDecoder(r.Body).Decode(&payload)

    switch payload.Type {
    case "applicantReviewed":
        // 幂等处理：同一 applicantID 可能多次触发
        h.kycService.ProcessReviewResult(r.Context(), payload.ApplicantID, payload.ReviewResult)
    case "applicantCreated":
        h.kycService.OnApplicantCreated(r.Context(), payload.ApplicantID)
    }
    w.WriteHeader(http.StatusOK)
}
```

> **关键**：Sumsub 可能对同一申请人发送多次 `applicantReviewed` 事件（如初次通过后被欺诈检测撤回），必须幂等处理。

---

## 4. 开户路径 — 各用户群体

### 4.1 美国居民（US Resident）

```
[1] 注册手机号/邮箱
[2] 基本信息录入（姓名、DOB、地址）
[3] 身份证件上传（驾照/护照）→ Sumsub OCR
[4] 活体检测（面部比对）
[5] SSN 录入（AES-256-GCM 加密存储）
[6] W-9 或 W-8BEN 税务表格（非美国税务居民填 W-8BEN）
[7] 风险问卷（投资目标、风险承受能力、资金来源）
[8] 受信联络人（TCP）信息（非机构账户须努力获取，可跳过）
[9] OFAC SDN 同步筛查 → 通过方可进入下一步
[10] 账户协议签署（电子签名）
[11] AML/PEP 异步筛查（后台，24小时内完成）
[12] 账户激活（ACTIVE）
```

**关键合规点**：
- 步骤 9（OFAC 筛查）为**同步阻塞**操作，命中立即拒绝（HTTP 451）
- 步骤 11（PEP/AML）为**异步**，账户进入 `PENDING_AML_REVIEW` 状态等待结果
- TCP 信息可以跳过（FINRA 要求"努力获取"，非强制）

### 4.2 香港居民（HK Resident）

```
[1] 注册手机号
[2] 基本信息录入
[3] HKID 上传 + 活体检测 → Sumsub（PAD Level 2）
[4] 地址证明上传（3 个月内水/电/银行账单）
[5] 风险问卷（SFC 适合性评估）
   → 注：SFC 要求问卷不能在短时间内反复修改（Circular 22EC52）
[6] 非面对面开户银行转账验证：
   → 须从香港持牌银行账户转入 ≥ HK$10,000
   → 同名账户原则：银行账户姓名须与 HKID 一致
   → 转账完成后触发自动对账确认
[7] CRS 税务自我声明（TIN 收集）
[8] UN/HK 制裁名单同步筛查
[9] PEP/AML 异步筛查
[10] 账户激活
```

**关键合规点**：
- 步骤 6（银行转账验证）是 AMLO 非面对面开户的核心要求，不可跳过
- "指定银行"接受范围：香港持牌银行（HKMA 认可，包括汇丰、恒生、中银香港、渣打等主流银行；虚拟银行（Mox、ZA、Airwallex）**需与合规团队确认是否在接受范围内**）

### 4.3 中国大陆居民（Mainland China Resident）

**路径**：与香港居民相似，但使用中国居民身份证代替 HKID。

```
[3'] 居民身份证（18位）上传 + 活体检测（Sumsub 14,000+模板覆盖）
[6'] 非面对面银行验证：
   → 须使用中国内地持牌银行或香港持牌银行账户（同名）
   → 大陆银行账户的 HK$10,000 验证：实际操作需确认跨境汇款是否满足 AMLO 要求
```

#### 4.3.1 官员职务信息采集（新增，仅大陆居民触发）

当大陆居民勾选"是否为中国政府官员或国企高管"时，引导用户进入新的职务信息采集步骤：

**采集字段：**
- 职务类型：中央政府 / 地方政府 / 国有企业 / 其他
- 具体职务：（文本输入，如"省长"、"地级市副市长"、"央企一把手"）
- 任职地区：（文本输入）
- 任职年限：（数字选择）
- 财富来源说明（可选）：继承 / 经营 / 薪资 / 投资等

**系统行为：**
- 根据职务自动分类为 Non-HK PEP 的 Level 1 / 2 / 3（详见 § 后续 AML Compliance PRD）
- Level 1（高风险）：立即进入强制 EDD，需合规高管批准
- Level 2（中等风险）：常规 KYC 后人工评估，根据财富来源决定是否升级 EDD
- Level 3（低风险）：标记监控，正常激活

详见 [AML 合规规格 § 4.3 Non-HK PEP 分类标准](../../../services/ams/docs/prd/aml-compliance.md#43-non-hk-pep-分类标准平衡方案)



**待确认的开放问题**：
- SFC 对大陆居民使用内地账户进行 HK$10,000 验证是否认可？还是必须是香港持牌银行账户？
- 大陆居民的 AML 风险评级：`MEDIUM`（非居民、资金来源跨境），须人工审核

### 4.4 双重 KYC（美股 + 港股）

同时开通 US + HK 账户（`jurisdiction = BOTH`）的用户须满足两套要求：
- 美股 KYC（SSN/护照 + W-8BEN/W-9）
- 港股 KYC（HKID/护照 + HK$10,000 银行转账验证）
- 建议引导用户分两步完成：先完成港股 KYC，再追加美股 KYC 资料

---

## 5. KYC 状态机

### 5.1 状态定义

```
APPLICATION_SUBMITTED
    │
    ▼
KYC_DOCUMENT_PENDING        ← 等待用户上传文件
    │
    ▼（Sumsub SDK 完成）
KYC_UNDER_REVIEW            ← Sumsub 自动审核中（< 60 秒）
    │              │
    │              ├──► KYC_MANUAL_REVIEW  ← AI 不确定，人工介入
    │              │         │
    │              │    通过  │  拒绝
    │              │         │
    ◄──────通过────┘    ──────┼──► KYC_REJECTED
    │                        │         │
    │                        │    用户申请重新提交（RETRY）
    │                        │         │
    ▼                        │    ──────┘
SANCTIONS_SCREENING          │
（同步 OFAC/UN）             │
    │         │              │
    通过     命中             │
    │         │              │
    │    ──────┼──► ACCOUNT_BLOCKED（立即冻结）
    │                        │
    ▼                        │
AML_PEP_REVIEW              │
（异步 24h）                 │
    │          │              │
    LOW/OK   MEDIUM/HIGH      │
    │          │              │
    │    ──────┼──► PENDING_EDD（等待强化尽职调查）
    │
    ▼
TAX_FORM_PENDING            ← 等待签署 W-9/W-8BEN
    │
    ▼
HK_BANK_VERIFICATION        ← 港股账户须完成 HK$10,000 转账验证
（仅 HK/BOTH 司法管辖）
    │
    ▼
AGREEMENT_PENDING           ← 等待签署账户协议
    │
    ▼
ACTIVE                      ← 账户完全激活
```

### 5.2 状态转换触发器

| 状态转换 | 触发方 | 描述 |
|----------|--------|------|
| → `KYC_UNDER_REVIEW` | Sumsub Webhook `applicantCreated` | SDK 提交完成 |
| → `KYC_MANUAL_REVIEW` | Sumsub Webhook `applicantReviewed` (RETRY) | 自动审核不确定 |
| → `KYC_REJECTED` | Sumsub Webhook `applicantReviewed` (RED+FINAL) 或 合规官操作 | KYC 失败 |
| → `SANCTIONS_SCREENING` | Sumsub Webhook `applicantReviewed` (GREEN) | KYC 通过，触发制裁筛查 |
| → `ACCOUNT_BLOCKED` | ComplyAdvantage 制裁命中回调 | 立即冻结，等待合规审查 |
| → `AML_PEP_REVIEW` | 制裁筛查通过，异步任务入队 | 后台 PEP/AML 筛查 |
| → `PENDING_EDD` | AML 筛查返回 MEDIUM/HIGH | 触发 EDD 工作流 |
| → `HK_BANK_VERIFICATION` | AML 通过（仅港股） | 等待 HK$10,000 入账 |
| → `ACTIVE` | 所有步骤完成 | 账户完全激活 |

---

---

## 6. 审核 SLA（包含 KYC + EDD 总时长）

根据 2026-03-29 的产品决策，所有 SLA 时间计算从 `APPLICATION_SUBMITTED` 状态开始，到 `ACTIVE` 或 `KYC_REJECTED` 状态结束，**包含所有步骤的总时长**（KYC + 制裁筛查 + AML/PEP + EDD）。

### 6.1 SLA 定义

| 账户类型 | 自动通过 | 需人工审核 | 触发 EDD |
|---------|---------|---------|---------|
| **普通个人** | **即时** (< 5 分钟) | **1 个工作日** | N/A |
| **PEP（高风险）** | N/A | **2-3 个工作日** | **包含**（自动触发） |
| **高风险 AML** | N/A | **3-5 个工作日** | **按需** |
| **公司账户** | N/A | **5 个工作日** | **按需** |

### 6.2 SLA 计时规则

**工作日定义**：周一至周五，排除中国公众假期和香港公众假期

**计时起点**：`APPLICATION_SUBMITTED` 时间戳（用户完成最后一步提交时）

**计时终点**：
- 通过：`ACTIVE` 时间戳
- 拒绝：`KYC_REJECTED` 时间戳
- 需补件：首次进入 `KYC_MANUAL_REVIEW` 状态，开始计时；补件重新提交后，计时**重置**

**SLA 告知**：
- 开户时：告知用户"您的审核预计需要 X-Y 个工作日"
- 进入 EDD：告知用户"由于风险评估要求，审核延长至 2-3 个工作日"

### 6.3 Admin Panel 显示设计

```
[审核卡片]
┌─────────────────────────────────────────┐
│ 申请人：张三                              │
│ 账户 ID：ACC-123                         │
│ KYC 状态：AML_PEP_REVIEW（审核中）        │
│ 应完成状态：ACTIVE                       │
│                                        │
│ ⏱️  已用时间：1.5 个工作日              │
│ 📌 SLA 承诺：2-3 个工作日（PEP）        │
│ 🚨 预警：还剩 1-1.5 个工作日（黄色）     │
│                                        │
│ [继续审核] [延期] [拒绝]                 │
└─────────────────────────────────────────┘
```

---

## 7. HK 非面对面开户合规要求


### 5.3 状态聚合规则（Domain 状态 → Surface 状态映射）

在 kyc-flow.md 中定义了 11 个细粒度的内部状态，以支持工程调试、合规追踪和可扩展性。但用户看到的应该是简化的 5 个状态，通过以下规则进行映射：

| 用户看到的状态（Surface）| 对应的 Domain 状态（组合） | 含义 |
|--------------------------|------------------------|------|
| 未开始 | `NOT_STARTED` | 用户尚未上传任何文件 |
| 审核中 | `KYC_UNDER_REVIEW` + `KYC_MANUAL_REVIEW` + `SANCTIONS_SCREENING` + `AML_PEP_REVIEW` + `PENDING_EDD` | 系统正在审核中（包括自动检查、人工审核、制裁筛查、EDD） |
| 需补件 | `KYC_MANUAL_REVIEW`（RejectType = RETRY） | 审核发现问题，需用户重新上传或补充信息 |
| 已通过 | `ACTIVE` | 账户完全激活，可开始交易 |
| 已拒绝 | `KYC_REJECTED` (RejectType = FINAL) 或 `ACCOUNT_BLOCKED` | 审核最终不通过，无法重试 |

**说明**：Mobile 工程师基于 Surface 状态编码，后端基于 Domain 状态转换。状态聚合规则确保两侧的映射清晰无歧义。

### 6.1 AMLO 要求

依据 SFC《可接受的账户开立方式》，非面对面开户须满足：
1. **文件核实**：通过 eKYC 验证 HKID/护照真实性
2. **活体检测**：确认申请人真人在场（ISO/IEC 30107-3 Level 2 认证）
3. **银行转账验证**：≥ HK$10,000 从香港持牌银行同名账户转入

### 6.2 银行转账验证流程

```
用户提交银行账户绑定申请（姓名须与 HKID 完全匹配）
    │
    ▼
系统生成唯一参考号（如 "KYC-XXXXXX"，用于辨别该笔验证款）
    │
    ▼
用户从香港持牌银行转入 ≥ HK$10,000
（备注填写参考号）
    │
    ▼
Fund Transfer 服务检测到入账，通知 AMS
    │
    ▼
AMS 比对：金额 ≥ HK$10,000？账户姓名匹配？参考号正确？
    │
    │ 验证成功                   │ 验证失败（72小时超时）
    ▼                            ▼
标记 HK 银行验证通过       通知用户重新操作，清除临时状态
```

### 6.3 银行名单管理

须在 `config/hk-accepted-banks.yaml` 中维护接受的香港银行名单，由合规团队负责更新：

```yaml
accepted_banks:
  - bank_code: "004"
    name: "The Hongkong and Shanghai Banking Corporation"
    swift: "HSBCHKHH"
  - bank_code: "012"
    name: "Bank of China (Hong Kong)"
    swift: "BKCHHKHH"
  # ... 其他持牌银行
  # 虚拟银行（Mox, ZA Bank 等）是否接受：待合规团队确认
```

---

## 8. 联名账户 KYC 设计（Joint Account）

### 7.1 MVP 范围建议

**建议 Phase 1 不包含联名账户（Joint Account）**，理由：
- 两位申请人 KYC 须同时通过，状态机复杂度翻倍
- 增加开户摩擦，影响转化率
- 合规审核 SLA 设定困难（其中一人在审核中怎么处理？）

如 PM 要求 MVP 包含，以下是最小化设计：

### 7.2 联名账户 KYC 状态机

```
申请人 A KYC 状态 ─────────────────────┐
申请人 B KYC 状态 ─────────────────────┤
                                        ▼
                             联名账户总体 KYC 状态：
                             - JOINT_KYC_PENDING（至少一人未完成）
                             - JOINT_KYC_A_COMPLETE（A 完成，等待 B）
                             - JOINT_KYC_B_COMPLETE（B 完成，等待 A）
                             - JOINT_KYC_BOTH_COMPLETE → 进入制裁筛查
                             - JOINT_KYC_ONE_REJECTED → 整体拒绝
```

**规则**：两位申请人 KYC 均通过后，系统对两人分别进行制裁筛查，任一命中则整个联名账户被阻断。

---

## 9. 公司账户 KYC（UBO 穿透）

### 8.1 UBO 穿透规则

| 司法管辖 | 持股门槛 | 穿透要求 |
|----------|----------|----------|
| 美股（FinCEN CDD） | ≥ 25% | 每位自然人完整 KYC + 1 名控制人 KYC |
| 港股（AMLO Schedule 2） | > 25% | 每位自然人完整 KYC；高风险时降至 10% |

**UBO 数量上限**：5 名自然人 UBO（理论上可能更多，超出须人工处理）。

### 8.2 企业文件要求

```
必须上传：
- 公司章程（M&A）
- 董事会决议（授权开户）
- 股权架构图（穿透至自然人）
- 注册证书
- 每位 UBO 的身份证明文件 + 完整 KYC
```

### 8.3 审核 SLA

公司账户人工审核 SLA：**5 个工作日**（相比个人账户的 1 个工作日更长，需在 UI 中明确告知用户）。

---

## 10. 专业投资者（PI）认定流程

### 9.1 PI 门槛（HK SFC）

| 类型 | 资产要求 |
|------|----------|
| 个人 PI | 投资组合 ≥ HK$800 万 或 总资产 ≥ HK$400 万 |
| 法人/机构 PI | 总资产 ≥ HK$4,000 万，或持牌金融机构 |

### 9.2 MVP 认定流程：自助 + 人工双轨

```
用户在 App 内触发"PI 认定申请"
    │
    ▼
用户上传资产证明文件（银行结单、投资账户月结单，最近 3 个月）
    │
    ▼
合规官人工审核（标准 SLA：3 个工作日）
    │
    │ 通过                    │ 拒绝
    ▼                         ▼
设置 investor_class = PROFESSIONAL   通知用户（可重新申请）
设置 pi_verified_at = NOW()
设置 pi_expires_at = NOW() + 12 months
    │
    ▼
解锁 PI 专属产品权限
```

> **SFC 注意事项**：SFC 2022 年在线平台审查（Circular Ref 22EC52）要求风险问卷不得在短时间内反复修改。PI 认定后，原有零售投资者风险问卷结果须存档，不可删除。

### 9.3 PI 到期提醒

```
pi_expires_at - 30 天：App 推送通知 + Email 通知
pi_expires_at - 7 天：再次提醒
pi_expires_at：investor_class 降回 RETAIL，限制 PI 专属产品访问
```

---


### 6.1 SLA 定义

| 账户类型 | 自动通过 | 需人工审核 | 触发 EDD |
|---------|---------|---------|---------|
| **普通个人** | **即时** (< 5 分钟) | **1 个工作日** | N/A |
| **PEP（高风险）** | N/A | **2-3 个工作日** | **包含**（自动触发） |
| **高风险 AML** | N/A | **3-5 个工作日** | **按需** |
| **公司账户** | N/A | **5 个工作日** | **按需** |

### 6.2 SLA 计时规则

**工作日定义**：周一至周五，排除中国公众假期和香港公众假期

**计时起点**：`APPLICATION_SUBMITTED` 时间戳（用户完成最后一步提交时）

**计时终点**：
- 通过：`ACTIVE` 时间戳
- 拒绝：`KYC_REJECTED` 时间戳
- 需补件：首次进入 `KYC_MANUAL_REVIEW` 状态，开始计时；补件重新提交后，计时**重置**

**SLA 告知**：
- 开户时：告知用户"您的审核预计需要 X-Y 个工作日"
- 进入 EDD：告知用户"由于风险评估要求，审核延长至 2-3 个工作日"

### 6.3 Admin Panel 显示设计

```
[审核卡片]
┌─────────────────────────────────────────┐
│ 申请人：张三                              │
│ 账户 ID：ACC-123                         │
│ KYC 状态：AML_PEP_REVIEW（审核中）        │
│ 应完成状态：ACTIVE                       │
│                                        │
│ ⏱️  已用时间：1.5 个工作日              │
│ 📌 SLA 承诺：2-3 个工作日（PEP）        │
│ 🚨 预警：还剩 1-1.5 个工作日（黄色）     │
│                                        │
│ [继续审核] [延期] [拒绝]                 │
└─────────────────────────────────────────┘
```

---

## 11. W-8BEN 续签工作流

### 10.1 W-8BEN 生命周期

| 节点 | 操作 |
|------|------|
| 签署之日 | `tax_form_signed_at = NOW()` |
| 到期日 = 签署年后第三个公历年度最后一天 | `tax_form_expires_at = last_day(year+3)` |
| 到期前 **90 天** | 系统推送续签提醒 |
| 到期前 **30 天** | 再次提醒（升级为必须处理） |
| 到期后未更新 | 冻结美股股息分配；开始预扣 30% FATCA 预提税 |
| 用户成为美国税务居民 | 须在 30 天内通知，切换为 W-9 |

### 10.2 续签 Job（robfig/cron + Redis 分布式锁）

```go
// 每天 UTC 02:00 执行，扫描 90 天内到期的 W-8BEN
c.AddFunc("0 2 * * *", func() {
    mu := rs.NewMutex("cron:w8ben-reminder", redsync.WithTries(1))
    if err := mu.Lock(); err != nil { return } // 另一个 Pod 正在运行
    defer mu.Unlock()

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
    defer cancel()

    var accounts []struct{ AccountID string; ExpiresAt time.Time }
    db.NewSelect().
        TableExpr("tax_forms").
        ColumnExpr("account_id, tax_form_expires_at").
        Where("form_type IN ('W8BEN', 'W8BENE')").
        Where("tax_form_expires_at BETWEEN ? AND ?",
            time.Now().UTC().Add(89*24*time.Hour),
            time.Now().UTC().Add(91*24*time.Hour),
        ).
        Scan(ctx, &accounts)

    for _, a := range accounts {
        // 通过 Kafka 发布事件，通知推送
        eventBus.Publish(ctx, "ams.tax_form.expiring", TaxFormExpiringEvent{
            AccountID: a.AccountID,
            ExpiresAt: a.ExpiresAt,
            DaysLeft:  90,
        })
    }
})
```

### 10.3 W-8BEN 到期冻结逻辑

#### 实施细节（参考 decisions-2026-03-29.md § 决策 1）

**决策**：到期后 **24 小时冻结股息分配**（而非立即冻结）

**理由**：
1. IRS 要求未提交 W-8BEN 的非美国税务居民在 30 天后启动预扣，24 小时给用户短暂的"补救窗口"
2. 给予用户通知后 24 小时的缓冲时间，避免体验问题
3. 与同行实践（Interactive Brokers、Saxo）一致

##### 数据库操作

```sql
-- 表结构（在 account_tax_forms 表中）
ALTER TABLE account_tax_forms ADD COLUMN dividend_hold_at TIMESTAMP NULL;

-- Cron Job 逻辑（每天 UTC 02:00 执行）
SELECT account_id, tax_form_expires_at
  FROM account_tax_forms
 WHERE form_type IN ('W8BEN', 'W8BENE')
   AND tax_form_expires_at < NOW()
   AND tax_form_expires_at > NOW() - INTERVAL 1 DAY  -- 到期后 24 小时内
   AND dividend_hold_at IS NULL;  -- 尚未记录

UPDATE account_tax_forms
   SET dividend_hold_at = NOW()
 WHERE id IN (...);

-- Fund Transfer 服务在计算可用余额时读取 dividend_hold_at，如果不为空则冻结股息
```

##### 用户通知时间表

| 时间 | 通知类型 | 内容 |
|------|--------|------|
| 到期前 90 天 | App Push + Email | "您的美国税务表 W-8BEN 将在 90 天后到期，请尽早续签" |
| 到期前 30 天 | App Push（红色）+ Email | "警告：W-8BEN 即将到期，续签后才能继续获得股息" |
| 到期前 7 天 | App Push（红色）+ SMS | "紧急：仅 7 天即过期，请立即续签" |
| 到期当天 | App Push（红色） | "W-8BEN 已过期，股息分配已暂停。请立即续签。" |
| 到期后 24 小时 | 内部日志（不通知用户） | 系统自动设置 `dividend_hold = true` |

##### API 返回值变化

```json
// 到期后 24 小时内的账户查询结果
{
  "account_id": "user-123",
  "tax_form": {
    "form_type": "W8BEN",
    "status": "EXPIRED",
    "expires_at": "2026-03-28T23:59:59Z",
    "dividend_hold": true,
    "dividend_hold_reason": "W-8BEN 已到期，股息分配已冻结。请立即续签。",
    "dividend_hold_until": "2026-03-28T23:59:59Z"
  }
}
```

---

## 12. Admin Panel KYC 审核队列

### 11.1 审核角色权限

| 角色 | 权限 |
|------|------|
| `compliance_officer` | 查看队列、批准/拒绝 KYC、添加备注 |
| `compliance_manager` | 同上 + 终审权（大额账户、高风险） |
| `auditor` | 只读查看所有 KYC 记录（含历史） |

### 11.2 审核队列 API

```
GET  /internal/compliance/kyc-queue                 # 获取待审核列表
GET  /internal/compliance/kyc/{kycID}               # 获取详情（含脱敏 PII）
POST /internal/compliance/kyc/{kycID}/approve       # 批准
POST /internal/compliance/kyc/{kycID}/reject        # 拒绝（须填写原因）
POST /internal/compliance/kyc/{kycID}/request-docs  # 要求补充材料
```

### 11.3 SLA 要求

| 账户类型 | 审核 SLA |
|----------|----------|
| 个人账户（自动通过） | 即时（<60 秒） |
| 个人账户（需人工） | 1 个工作日 |
| 公司账户 | 5 个工作日 |
| EDD 案件 | 10 个工作日（须合规经理终审） |

---

## 13. KYC 被拒申诉流程

### 12.1 申诉状态机

```
KYC_REJECTED（原因：文件模糊/信息不符/其他）
    │
    ▼（用户提交申诉）
APPEAL_PENDING
    │
    ▼（合规官重新审核）
    │ 申诉成功           │ 申诉失败
    ▼                    ▼
KYC_UNDER_REVIEW    APPEAL_REJECTED（最终拒绝，不可再申诉）
    │
    ▼
（回到正常 KYC 流程）
```

### 12.2 AMS 需要支撑的字段

```sql
-- 在 account_kyc_profiles 表新增
appeal_status        ENUM('NONE','PENDING','APPROVED','REJECTED') DEFAULT 'NONE',
appeal_submitted_at  TIMESTAMP NULL,
appeal_note          TEXT NULL,  -- 用户填写的申诉理由
appeal_resolved_at   TIMESTAMP NULL,
appeal_resolved_by   VARCHAR(36) NULL, -- 合规官 ID
```

---

## 14. 开放决策点

以下问题需 PM / 合规团队确认，再完成详细设计：

| # | 问题 | 影响 | 优先级 |
|---|------|------|--------|
| 1 | **MVP 是否包含联名账户？** | KYC 状态机复杂度、开户摩擦 | High |
| 2 | **MVP 是否包含公司账户？** | UBO 穿透流程、审核 SLA | High |
| 3 | **大陆居民用内地银行账户能否满足 AMLO HK$10,000 验证？** | 港股 KYC 可行性 | High |
| 4 | **虚拟银行（Mox, ZA Bank）是否在 HK 银行接受名单内？** | 影响港股用户开户路径 | Medium |
| 5 | **KYC 拒绝后最多允许申诉几次？** | 申诉状态机设计 | Medium |
| 6.1 | **PI 认定是否纯人工，还是支持部分自动化（资产金额超过 HK$800万直接通过）？** | PI 认定流程效率 | Medium |
| 6.2 | **Sumsub vs Jumio 最终选型** | 集成方式、合同谈判 | High |

---

*参考：eKYC Vendor Deep-Dive Research Report（2026-03-17）、`docs/specs/account-financial-model.md`（KYC 模型）、`.claude/rules/security-compliance.md`（合规规则）*
