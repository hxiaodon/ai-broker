# AMS PRD 修改完成总结

**完成时间**: 2026-03-29 16:45 UTC+8  
**工作者**: Product Manager (Claude Sonnet 4.6)  
**Git Commit**: b1a4ca4

---

## 📋 工作成果

### ✅ P0（必须做）所有项目完成

#### 1. Mobile PRD-01 (01-auth.md)
- **Frontmatter**: ✅ 补充 YAML frontmatter，声明与 Domain PRD 的关系
  - `type: surface-prd`
  - `domain_prd: [kyc-flow.md]`
  - 完整的 revisions 历史
- **超链接**: ❌ 此文件未涉及 KYC 内容，不需要 Domain PRD 引用

#### 2. Mobile PRD-02 (02-kyc.md)
- **Frontmatter**: ✅ 补充完整的 Frontmatter
  - `type: surface-prd`
  - `domain_prd: [kyc-flow.md, aml-compliance.md]`
  - 完整的 revisions 历史
- **超链接**: ✅ 在以下位置添加了 Domain PRD 引用
  - § 4.1 开户总流程后：Sumsub 选型、制裁筛查规则
  - § 4.6 W-8BEN 说明：W-8BEN 续签工作流
  - § 7 合规要求后：AML 合规规则、KYC 流程细节
- **附录 A**: ✅ 新增"与 Domain PRD 的职责分工"
  - Surface 范围列表（7 项）
  - Domain 范围列表（7 项）
  - 跨 PRD 查询指南（5 个常见问题）
- **附录 B**: ✅ 新增"审核状态术语对照表"
  - 7 个用户显示状态
  - 对应的 11 个 Domain 状态
  - 完整的对照和说明

#### 3. AMS Domain PRD: kyc-flow.md
- **Frontmatter**: ✅ 补充完整的 Frontmatter
  - `type: domain-prd`
  - `surface_prd: [01-auth.md, 02-kyc.md]`
  - revisions 记录
- **新增 § 4.3.1**: ✅ 大陆居民官员职务信息采集
  - 采集字段定义（职务类型、具体职务、任职地区、任职年限、财富来源）
  - 系统行为说明（Level 1-3 自动分类）
  - 与 aml-compliance.md 的链接
- **新增 § 5.3**: ✅ 状态聚合规则表
  - 11 个 Domain 状态 → 5 个 Surface 状态的完整映射
  - 用户看到的"未开始"→ `NOT_STARTED`
  - 用户看到的"审核中"→ `KYC_UNDER_REVIEW` + 其他并发状态
  - 完整说明
- **新增 § 6**: ✅ 审核 SLA（包含 KYC + EDD 总时长）
  - § 6.1 SLA 定义矩阵（4 个账户类型）
  - § 6.2 SLA 计时规则（工作日定义、计时起点/终点、SLA 告知）
  - § 6.3 Admin Panel 显示设计（卡片布局示意）
- **扩展 § 10.3**: ✅ W-8BEN 到期冻结逻辑详细化
  - 决策背景和理由
  - 数据库操作（SQL 示例）
  - 用户通知时间表（5 个时间点）
  - API 返回值变化示例
- **章节重新编号**: ✅ 后续所有章节自动递增
  - 原 § 6 HK 非面对面 → § 7
  - 原 § 7 联名账户 → § 8
  - ... 以此类推到 § 14（原 § 13 开放决策点）

#### 4. AMS Domain PRD: aml-compliance.md
- **Frontmatter**: ✅ 补充完整的 Frontmatter
  - `type: domain-prd`
  - `surface_prd: [02-kyc.md]`
  - revisions 记录
- **新增快速指南**: ✅ 面向 Engineering 工程师的 1500 字快速导读
  - 3 个 PEP Level 的快速解释
  - 用户可见的影响
  - 账户 API 中的标记
  - 与 Surface PRD 的关系说明
- **新增 § 4.3**: ✅ Non-HK PEP 分类标准（平衡方案 Level 1-3）
  - Level 1 强制 EDD：300-500 人（中央级）
  - Level 2 人工评估：3,000-5,000 人（地市级）
  - Level 3 标记监控：10,000-20,000 人（县级）
  - 分类决策树（ASCII 流程图）
  - 详细的分类规则和处理流程
- **新增 § 4.4**: ✅ PEP EDD 工作流
  - Level 1 自动 EDD 流程（5 步）
  - Level 2 人工评估流程（7 步 + 3 步检查清单）
  - Level 3 自动标记 + 监控流程（4 步）
  - Admin Panel 队列设计（PEP 审核队列入口）
  - Level 2 评估界面设计（完整的表单布局）

---

## 📊 数据统计

| 文件 | 行数变化 | 主要改动 |
|------|---------|---------|
| `mobile/docs/prd/01-auth.md` | +22 | Frontmatter + revisions |
| `mobile/docs/prd/02-kyc.md` | +90 | Frontmatter + 超链接 + 附录 A-B |
| `services/ams/docs/prd/kyc-flow.md` | +233 | Frontmatter + § 4.3.1 + § 5.3 + § 6 + § 10.3 扩展 + 章节重编 |
| `services/ams/docs/prd/aml-compliance.md` | +128 | Frontmatter + 快速指南 + § 4.3 + § 4.4 |
| **总计** | **+473** | **4 个 PRD 文件完整更新** |

---

## 🔗 关键超链接验证

### Mobile PRD-02 中的 Domain PRD 链接

✅ 所有链接都使用相对路径，兼容单 repo 和多 repo 场景：
```
../../../services/ams/docs/prd/kyc-flow.md
../../../services/ams/docs/prd/aml-compliance.md
```

### 跨 PRD 导航

**从 Mobile PRD-02 出发的查询路径**：

1. "为什么需要上传证件？"
   - 查 PRD-02 § 1.2 业务价值
   - 链接到 kyc-flow.md § 各用户群体开户路径

2. "审核要多久？"
   - 查 PRD-02 § 5 用户显示状态
   - 链接到 kyc-flow.md § 5.3 状态聚合规则 + § 6 SLA 定义

3. "PEP 审核流程？"
   - 查 PRD-02 § 4.2 PEP 触发人工审核
   - 链接到 aml-compliance.md § 4.3-4.4 PEP 分类与 EDD

4. "W-8BEN 到期续签？"
   - 查 PRD-02 § 4.6 W-8BEN 提醒时间
   - 链接到 kyc-flow.md § 10 W-8BEN 续签工作流

---

## 📝 Frontmatter 规范遵守

### Surface PRD（Mobile）

```yaml
---
type: surface-prd
version: v3.0
updated_date: 2026-03-29T15:XX+08:00
domain_prd:
  - path: ../../../services/ams/docs/prd/XXX.md
    description: "..."
revisions:
  - rev: 3
    date: 2026-03-29
    author: product-manager
    summary: "..."
---
```

✅ 规范检查：
- [x] `type` 字段明确标识为 `surface-prd`
- [x] `domain_prd` 数组列出关联的 Domain PRD
- [x] `revisions` 完整历史记录
- [x] 相对路径可在多 repo 环境中工作

### Domain PRD（AMS）

```yaml
---
type: domain-prd
version: v1.0
updated_date: 2026-03-29T16:XX+08:00
surface_prd:
  - path: ../../../mobile/docs/prd/XXX.md
    description: "..."
revisions:
  - rev: 1
    date: 2026-03-29
    author: product-manager
    summary: "..."
---
```

✅ 规范检查：
- [x] `type` 字段明确标识为 `domain-prd`
- [x] `surface_prd` 数组列出消费方的 Surface PRD
- [x] 双向引用关系已建立

---

## 🎯 与 decisions-2026-03-29.md 的对应关系

### 决策 1：W-8BEN 到期冻结时机
✅ 已实施在 kyc-flow.md § 10.3
- 24 小时冻结逻辑
- 用户通知时间表
- API 返回值变化
- SQL 示例代码

### 决策 2：Domain 状态机不简化
✅ 已实施在 kyc-flow.md § 5.3
- 11 个 Domain 状态保持不变
- 状态聚合规则表完整定义
- Mobile PRD-02 附录 B 用户状态对照表

### 决策 3：PEP 审核 SLA 包含 KYC + EDD
✅ 已实施在 kyc-flow.md § 6
- SLA 承诺矩阵（4 个账户类型）
- 计时规则清晰化
- Admin Panel SLA 显示设计
- 工作日和计时起点明确定义

### 决策 4：Non-HK PEP 分类标准（平衡方案）
✅ 已实施在 aml-compliance.md § 4.3-4.4
- Level 1-3 三层分类规则
- 分类决策树
- 3 个 Level 的完整 EDD 工作流
- Admin Panel PEP 队列设计
- Level 2 评估界面完整规格

---

## ✨ 实现中的最佳实践

### 1. 文档链接的可追溯性
每个超链接都包含清晰的链接文本，帮助读者快速理解被链接内容的含义：
```markdown
[KYC 流程规格 § KYC 供应商选型决策](path)  ← 告诉读者具体是哪个章节
```

### 2. 状态术语的双向映射
PRD-02 附录 B 建立了完整的映射表，使得：
- Frontend 工程师可以查表决定何时显示"审核中"
- Backend 工程师可以查表理解 11 个 Domain 状态如何聚合
- QA 工程师可以查表验证每个 Domain 状态转换

### 3. 决策依据的完整性
每个新增规格都附加了"为什么这样设计"的解释：
- W-8BEN 24 小时冻结的"理由"章节
- Non-HK PEP 分层的"为什么不采用激进方案"说明
- SLA 定义的"工作日排除"规则说明

### 4. 工程师友好的章节组织
aml-compliance.md 开头的"快速指南"专门为 Engineering 工程师提供：
- 3 个 PEP Level 的 30 秒解释
- "你需要关心哪些字段"
- "与 Mobile PRD 的具体关系"

---

## 🚀 后续工程工作的入口点

### 对于 Mobile 工程师

1. 阅读 Mobile PRD-02 的附录 B（状态对照表）— 5 分钟
2. 点击链接阅读 kyc-flow.md § 5.3（状态聚合规则）— 10 分钟
3. 了解 PEP 采集流程：PRD-02 § 4.2 + aml-compliance.md § 4.3 快速指南 — 15 分钟
4. 开始实现用户界面

### 对于 AMS Backend 工程师

1. 阅读 aml-compliance.md 开头"快速指南" — 10 分钟
2. 学习 4 个关键决策：decisions-2026-03-29.md — 20 分钟
3. 深入学习 kyc-flow.md 的完整设计 — 60 分钟
4. 启动技术评估：数据库设计、API 规格、工作流实现

### 对于 Admin Panel 工程师

1. 查阅 kyc-flow.md § 6.3（SLA 显示设计）
2. 查阅 aml-compliance.md § 4.4（PEP 队列设计）
3. 与 PM 同步具体的 UI/UX 细节

---

## ✅ 交付清单

- [x] Mobile PRD-01 Frontmatter 补充
- [x] Mobile PRD-02 Frontmatter 补充
- [x] Mobile PRD-02 超链接添加（≥5 处）
- [x] Mobile PRD-02 附录 A 新增
- [x] Mobile PRD-02 附录 B 新增
- [x] kyc-flow.md Frontmatter 补充
- [x] kyc-flow.md § 4.3.1 官员职务采集新增
- [x] kyc-flow.md § 5.3 状态聚合规则新增
- [x] kyc-flow.md § 6 SLA 完整定义新增
- [x] kyc-flow.md § 10.3 W-8BEN 冻结逻辑扩展
- [x] aml-compliance.md Frontmatter 补充
- [x] aml-compliance.md 快速指南新增
- [x] aml-compliance.md § 4.3 PEP 分类新增
- [x] aml-compliance.md § 4.4 EDD 工作流新增
- [x] 所有文件的章节编号一致性验证
- [x] Git 提交（commit b1a4ca4）

---

## 📖 文件访问路径

**相对于项目根目录**：

```
brokerage-trading-app-agents/
├── mobile/docs/prd/
│   ├── 01-auth.md          ✅ 已修改
│   └── 02-kyc.md           ✅ 已修改 (包含附录 A-B)
└── services/ams/docs/prd/
    ├── kyc-flow.md         ✅ 已修改 (包含 4.3.1, 5.3, 6, 10.3 扩展)
    ├── aml-compliance.md   ✅ 已修改 (包含快速指南, 4.3, 4.4)
    ├── decisions-2026-03-29.md  (参考文档)
    └── SUMMARY-2026-03-29.md    (参考文档)
```

---

**修改完成。所有 P0 项目已完成。** ✨

下一步工作（由工程师负责）：
1. 工程可行性评估（3-4 小时）
2. 技术设计文档（API spec、DB schema）
3. 工程立项和任务分解

