# AML 制裁筛查方案选型

> 本文档对应 `fund-transfer-system.md` 中 Compliance Engine 的 AML screening 模块。
> 讨论开源自托管方案与商业 SaaS 的选型，给出接入指引和演进路径。
>
> 相关规则：`.claude/rules/fund-transfer-compliance.md` Rule 2（AML 筛查强制要求）

---

## 1. 方案选型矩阵

| 方案 | 类型 | OFAC/UN/EU | PEP 数据库 | 不良媒体监控 | 成本 | 推荐阶段 |
|------|------|-----------|------------|------------|------|---------|
| **moov-io/watchman** | 开源自托管 | ✅ | ❌ | ❌ | 免费 | 早期 / MVP |
| **ComplyAdvantage** | 商业 SaaS | ✅ | ✅ | ✅ | $1,000+/月 | 规模化 |
| **LexisNexis WorldCompliance** | 商业 SaaS | ✅ | ✅（最全） | ✅ | 协商 | 企业级 |
| **Refinitiv World-Check** | 商业 SaaS | ✅ | ✅ | ✅ | 协商 | 大型机构 |
| **Dow Jones Risk & Compliance** | 商业 SaaS | ✅ | ✅ | ✅ | 协商 | 企业级 |

**推荐演进路径**：

```
阶段 1（早期）：moov-io/watchman 自托管
  → 零成本，覆盖 OFAC/UN/EU/UK，满足基础合规要求

阶段 2（规模化后）：moov-io/watchman + ComplyAdvantage
  → watchman 继续处理制裁名单（低延迟）
  → ComplyAdvantage 补充 PEP 筛查 + 媒体监控（Enhanced Due Diligence）

阶段 3（机构化）：按监管要求全面升级
  → LexisNexis 或 Refinitiv（监管审计认可度更高）
```

---

## 2. moov-io/watchman 详细指引

### 2.1 资源

| 项目 | 链接 |
|------|------|
| GitHub | https://github.com/moov-io/watchman |
| 文档站 | https://moov-io.github.io/watchman/ |
| API 文档（OpenAPI） | https://moov-io.github.io/watchman/api/ |
| Docker Hub | `moov/watchman` |
| Go pkg | https://pkg.go.dev/github.com/moov-io/watchman |

### 2.2 支持的名单

| 名单 | 来源 | 说明 |
|------|------|------|
| OFAC SDN | US Treasury | 特别指定国民名单 |
| OFAC Consolidated | US Treasury | 合并制裁名单 |
| OFAC Sectoral Sanctions | US Treasury | 行业制裁名单（俄罗斯等） |
| OFAC Non-SDN | US Treasury | 非 SDN 制裁列表 |
| EU Consolidated | European Union | 欧盟制裁名单 |
| UN Consolidated | United Nations | 联合国制裁名单 |
| UK HMT | HM Treasury | 英国财政部制裁名单 |
| OFAC DPL | US Commerce | 出口管制（拒绝方名单） |

**AMLO HK 名单**：JFIU（香港联合财富情报组）发布，需手动处理（见第 5 节）。

### 2.3 本地部署

```bash
# 快速启动（Docker）
docker run -p 8084:8084 -p 9094:9094 moov/watchman:latest

# 验证服务就绪
curl -s http://localhost:8084/ping
# → {"ping":"pong"}
```

### 2.4 核心 API

**名字搜索（最常用）**：
```
GET /search?name={name}&limit=5

响应：
{
  "SDNs": [
    {
      "entityID": "...",
      "sdnName": "AL-QAEDA",
      "sdnType": "Entity",
      "match": 0.98,       ← 匹配分数（0-1）
      "programs": ["SDGT"]
    }
  ],
  "altNames": [...],
  "addresses": [...]
}
```

**批量搜索**：
```
POST /search/bulk
Content-Type: application/json

[
  {"name": "John Doe", "type": "individual"},
  {"name": "ABC Corp", "type": "entity"}
]
```

**Webhook（名单更新通知）**：
```
POST /webhooks
{
  "callbackURL": "https://our-service/aml/watchman-update",
  "authToken": "Bearer ..."
}
```

### 2.5 与 Fund Transfer Service 的集成方式

```go
// 推荐：通过 REST 调用，不引入 Go 包依赖（服务解耦）
type WatchmanClient struct {
    baseURL    string
    httpClient *http.Client
}

func (w *WatchmanClient) SearchName(ctx context.Context, name string) (*SearchResult, error) {
    url := fmt.Sprintf("%s/search?name=%s&limit=5", w.baseURL, url.QueryEscape(name))
    // ... HTTP GET
}

// 匹配阈值处理
func (w *WatchmanClient) EvaluateResult(result *SearchResult) AMLDecision {
    highestMatch := result.HighestMatchScore()
    switch {
    case highestMatch >= 0.95:
        return AMLDecision{Status: "BLOCK", Reason: "HIGH_CONFIDENCE_MATCH"}
    case highestMatch >= 0.80:
        return AMLDecision{Status: "REVIEW", Reason: "POSSIBLE_MATCH"}
    default:
        return AMLDecision{Status: "PASS"}
    }
}
```

### 2.6 名单更新频率

- OFAC 每周更新（不定期，通常周四发布）
- 建议定时任务：每日 `02:00 UTC` 触发 watchman 自动拉取最新名单
- watchman 支持 `--download-cron` 参数配置自动更新：

```bash
docker run -e DOWNLOAD_CRON="0 2 * * *" moov/watchman:latest
```

---

## 3. 商业 SaaS 对比

### 3.1 ComplyAdvantage

| 项目 | 内容 |
|------|------|
| 开发者文档 | https://docs.complyadvantage.com/ |
| AML 数据库说明 | https://complyadvantage.com/insights/aml-database/ |
| 定价 | 企业协商，月费 $1,000+ 起 |

**超出 moov-io/watchman 的能力**：
- PEP（政治公众人物）数据库：覆盖 200+ 国家，含家属和关联企业
- 不良媒体监控（Adverse Media）：实时新闻监控
- 名单更新频率：分钟级（实时推送）
- 批量搜索 API：支持高并发，SLA ≥ 99.9%

**接入要点**：
- REST API，`Authorization: Token {api_key}`
- 主要端点：`POST /searches`（返回匹配结果和风险评分）
- Webhook 订阅监控对象状态变更

### 3.2 LexisNexis WorldCompliance

| 项目 | 链接 |
|------|------|
| 数据库介绍 | https://risk.lexisnexis.com/financial-services/aml-compliance/worldcompliance-data |
| 接入咨询 | 联系 LexisNexis 企业销售 |

**特点**：PEP 层级数据最完整（含家属 3 代、受益所有人），历史变迁追踪，适合监管审计高压场景。

### 3.3 Refinitiv World-Check

- 官方介绍：https://www.refinitiv.com/en/financial-crime/world-check-kyc-screening
- 被大量全球性银行和机构券商使用，监管认可度高
- 适合需要向 SEC/SFC 展示 AML 合规体系时

---

## 4. 名字模糊匹配策略

AML 名字匹配是技术和合规的交汇点，需要在误报率和漏报率之间取得平衡。

### 4.1 算法选型

| 算法 | 特点 | 适用场景 |
|------|------|---------|
| **Jaro-Winkler** | 对字符串前缀权重更高 | 英文姓名（推荐） |
| Levenshtein Distance | 编辑距离，对长字符串效果好 | 实体名称 |
| Phonetic（Soundex/Metaphone） | 发音相似匹配 | 英文音译名 |
| 中文特殊处理 | 简繁体转换 + 拼音对照 | 中文姓名 |

moov-io/watchman 内置 Jaro-Winkler + phonetic 组合，直接使用即可。

### 4.2 阈值建议

```
匹配分数（watchman 返回 0-1）：

≥ 0.95  → BLOCK（直接阻断）
           自动拒绝入金/出金，生成 AML 事件，通知合规团队

0.80 ~ 0.95 → REVIEW（人工审核队列）
              挂起当前操作，合规团队 24 小时内审核
              审核通过 → 放行；审核拒绝 → 触发 SAR 流程

< 0.80  → PASS（通过，记录原始分数）
           继续正常流程，但分数写入 fund_transfers.aml_metadata
```

**调参建议**：
- 初期可将 REVIEW 阈值降低到 0.75（宁可多审，避免漏报）
- 根据合规团队人工审核结果，逐步调高阈值减少误报
- 对高风险国家（OFAC 制裁国）用户，降低阈值至 0.70

### 4.3 中文姓名处理

中文用户（香港/台湾/大陆）的姓名在制裁名单中通常以英文音译形式出现：

```
用户 KYC 姓名：张伟（Zhang Wei）
制裁名单可能记录为：CHANG WEI / CHEUNG WAI / ZHANG WEI

处理步骤：
1. 将中文姓名转换为拼音（普通话 + 粤语两套）
2. 对每套拼音分别运行 Jaro-Winkler 匹配
3. 取最高分作为最终匹配分
```

---

## 5. AMLO HK（香港）名单接入

### 5.1 名单来源

| 名单 | 来源 | 格式 |
|------|------|------|
| 指定制裁人士/实体 | JFIU（联合财富情报组） | PDF（需解析） / 可向 JFIU 申请机读 |
| 联合国制裁名单（HK 执行） | 香港特区政府 | 与 UN Consolidated 一致，watchman 已覆盖 |
| 财务行动特别工作组（FATF） | FATF 官方 | 灰名单/黑名单国家列表 |

**官方页面**：https://www.jfiu.gov.hk/en/aml_cft/designated_entities.html

### 5.2 接入方案

JFIU 名单目前以 PDF 形式发布，机读格式需向 JFIU 申请。

**过渡方案**：
1. 每日 `03:00 HKT` 自动下载 JFIU 页面，检查是否有更新
2. 若有更新，触发人工解析（或 PDF 解析脚本）生成结构化 CSV
3. 通过 watchman 的 Custom List API 导入：

```bash
# watchman 支持自定义名单导入（CSV 格式）
curl -X POST http://localhost:8084/custom-lists \
  -F "file=@jfiu_list.csv" \
  -F "name=JFIU_HK"
```

### 5.3 FATF 高风险国家

对来自 FATF 黑名单/灰名单国家的用户，适用增强尽职调查（Enhanced Due Diligence）：
- 所有入金自动进入人工审核（无自动通过）
- 要求提供资金来源证明
- 当前黑名单/灰名单：https://www.fatf-gafi.org/en/topics/high-risk-and-other-monitored-jurisdictions.html

---

## 6. 与 Fund Transfer Service 的集成点

| 触发时机 | 筛查对象 | 处理结果 |
|---------|---------|---------|
| 银行卡绑定 | 用户姓名 + 银行名称 | BLOCK → 拒绝绑定；REVIEW → 人工审核 |
| 每笔入金请求 | 用户姓名 | BLOCK → 拒绝入金，生成 AML 事件；REVIEW → 挂起 |
| 每笔出金请求 | 用户姓名 + 收款行名称 | BLOCK → 拒绝；REVIEW → 人工审核队列 |
| 每日定时复查 | 所有活跃用户 | 名单更新后触发，命中则冻结账户 |
| KYC 升级 | 增强尽职调查时 | 全量筛查，包含 PEP（需商业 SaaS） |

**关键设计要求**：
- 每次筛查结果写入 `aml_screening_results` 表（append-only，不可删除）
- 保留 7 年（BSA/AMLO Rule 9）
- 筛查失败（服务不可用）时：默认拒绝操作，不允许降级为"跳过筛查"

---

## 7. 监控与告警

```
AML 筛查服务监控指标：

P1 告警（立即响应）：
  - watchman 服务不可用（连续 3 次 health check 失败）
  - 筛查超时率 > 1%（影响用户操作）
  - BLOCK 事件 > 10 次/小时（可能系统误判或攻击）

P2 告警（1小时内响应）：
  - REVIEW 队列积压 > 100 条（合规团队处理能力不足）
  - 名单更新失败（watchman 下载 OFAC 文件失败）

P3 信息：
  - 每日 BLOCK/REVIEW/PASS 统计报告
  - 各名单最后更新时间
```

---

*文档版本：v1.0 | 日期：2026-03-25 | 作者：Fund Transfer Engineering*
*适用范围：AML 制裁筛查实现，不覆盖 KYC 身份核验（属 AMS 域）*
