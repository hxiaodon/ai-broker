# SDD 与大规模工程协作调研报告

> **日期**: 2026-03-13T22:45+08:00
> **调研目的**: 评估当前 Spec 组织规范的扩展性，为多 repo 演进提供行业参考

---

## 一、SDD 方法论的行业现状

### 成熟度模型（Martin Fowler）

- **spec-first**: 先写 spec 再写代码
- **spec-anchored**: 完成后保留 spec 用于维护
- **spec-as-source**: spec 是主制品，人不直接碰代码

### 已知失败模式

| 失败模式 | 来源 | 影响 |
|---------|------|------|
| 上下文窗口被吃掉 | BMAD 框架 105K tokens | Agent 工作内存不足 |
| Spec 膨胀 | Fowler: 一个 bug fix → 4 用户故事 16 验收标准 | 过度工程化 |
| 维护税 | 代码变更必须同步 Spec | 复杂度线性增长 |
| 完整性幻觉 | 详细 Spec ≠ 正确理解 | 隐性知识丢失 |
| 审查加倍 | 审 Spec + 审代码 | 工作量翻倍 |

### 24% 法则

Codified Context 论文（arXiv:2602.20478）：108K 行 C# 项目需要 26K 行知识文档。知识/代码比 ≈ 24%。

### 来源

- [ThoughtWorks: Spec-Driven Development](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
- [Martin Fowler: Understanding SDD Tools](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- [Martin Fowler: Context Engineering](https://martinfowler.com/articles/exploring-gen-ai/context-engineering-coding-agents.html)
- [Arcturus Labs: Why SDD Breaks at Scale](http://arcturus-labs.com/blog/2025/10/17/why-spec-driven-development-breaks-at-scale-and-how-to-fix-it/)
- [Brandon Dennis: SDD Eating Context Window](https://medium.com/@toady00/your-sdd-framework-is-eating-your-context-window-e288615c608b)
- [arXiv: Codified Context Infrastructure (2602.20478)](https://arxiv.org/abs/2602.20478)

---

## 二、大规模团队跨 Repo 文档管理

### 公司案例

| 公司 | 方案 | 结果 |
|------|------|------|
| Spotify | Backstage + TechDocs + catalog-info.yaml | 5000+ 文档站点，~10K 日均访问 |
| Google | GooWiki → 结构化设计文档 | GooWiki 失败（无 owner），设计文档成功 |
| Uber | 早期 RFC 工具，集中存储 | 从几十人扩展到几千人 |
| Stripe | 写作优先文化，全覆盖模板 | RFC 消灭重复口头沟通 |

### Internal Developer Portal (IDP) 是 2025 主流方案

| 工具 | 特点 |
|------|------|
| Backstage (Spotify/CNCF) | 开源，TechDocs，软件目录 |
| Cortex | 自动更新服务目录，SLO 追踪 |
| Port | 可自定义 Blueprint，合规 Scorecard |

### 来源

- [Backstage TechDocs](https://backstage.io/docs/features/techdocs/)
- [Design Docs at Google](https://www.industrialempathy.com/posts/design-docs-at-google/)
- [Pragmatic Engineer: Scaling via Writing Things Down](https://blog.pragmaticengineer.com/scaling-engineering-teams-via-writing-things-down-rfcs/)

---

## 三、AI Agent 跨 Repo 协作

### 关键数据

- Claude Code 2026 初最受欢迎率 46%（vs Cursor 19%，Copilot 9%）
- 资深开发者平均使用 2.3 个 AI 工具
- 200K 上下文窗口上传 34K 文档后饱和度 70%

### 跨 Repo 模式

| 模式 | 来源 | 核心思路 |
|------|------|---------|
| 三层知识架构 | Codified Context | Hot/Warm/Cold 分级加载 |
| 渐进式披露 | Fowler | 告诉 AI 如何找信息，而非给全部信息 |
| 合成单 Repo | Nx | 多 repo 连成统一依赖图 |
| 知识图谱 | LogicLens | 多 repo 语义查询 |
| AGENTS.md | Linux Foundation | 标准化上下文文件 |

### 来源

- [arXiv: Codified Context (2602.20478)](https://arxiv.org/abs/2602.20478)
- [arXiv: LogicLens (2601.10773)](https://arxiv.org/html/2601.10773v1)
- [arXiv: Cross-Team Orchestration (2406.08979)](https://arxiv.org/abs/2406.08979)
- [InfoQ: AGENTS.md Reassessment](https://www.infoq.com/news/2026/03/agents-context-file-value-review/)

---

## 四、知识在 Repo 分裂中的存活

### 关键模式

| 模式 | 机制 |
|------|------|
| InnerSource 标准基础文档 | 每个 repo 必须有 README + CONTRIBUTING + COMMUNICATION |
| ADR 跟随服务 | 存在 repo 的 docs/adr/，分 repo 直接带走 |
| 联邦化文档组装 | 每个服务拥有文档，组装服务组合成完整视图 |
| Cell-based 架构 | 文档边界 = Cell 边界，Cell 内自文档化 |
| 合成单 Repo | 多 repo 连接成统一依赖图（Nx） |

### 来源

- [InnerSource Commons](https://innersourcecommons.org/)
- [InnerSource Standard Base Documentation](https://patterns.innersourcecommons.org/p/base-documentation)
- [WSO2: Cell-Based Architecture](https://github.com/wso2/reference-architecture/blob/master/reference-architecture-cell-based.md)

---

## 五、对本项目规范的影响

### 已应用到规范 v2.0 的改进

1. **逻辑 URI + 路径双写** — 跨域引用在多 repo 下不断裂
2. **domain.yaml 服务清单** — 类似 Backstage catalog-info.yaml，机器可读域索引
3. **三层知识架构 Hot/Warm/Cold** — 控制 AI 上下文预算
4. **Contract 归属规则** — provider 持有原件，CI 同步到 consumer
5. **多 repo 演进路径** — Phase 1 (单 repo) → Phase 2 (混合) → Phase 3 (完全多 repo)
6. **迁移检查清单** — 域拆出独立 repo 时的逐项验证
