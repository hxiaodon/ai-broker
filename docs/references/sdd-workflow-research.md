# SDD 开发流程调研：AI 为执行方的规范驱动开发

> **日期**: 2026-03-14
> **调研目的**: 研究 AI Agent 作为执行方时，SDD 开发流程如何设计，人类仅在关键节点审核
> **关联**: 本文聚焦开发流程实操，与 `sdd-engineering-research.md`（侧重规范组织与扩展性）互补

---

## 一、行业背景：三大痛点

来源：[阿里 SDD 实操文章](https://mp.weixin.qq.com/s/WoEetgbDkNidf7Flmg8dUQ)

| 痛点 | 描述 | SDD 如何解决 |
|------|------|-------------|
| **上下文腐烂** | 对话越长越跑偏，new chat 丢上下文 | Spec 是"存档点"，任意时间恢复上下文 |
| **审查瘫痪** | AI 生成万行代码，人无法逐行 review | Review 变成"检查代码是否兑现文档承诺" |
| **维护断层** | 两月后修 bug，AI 也无法接手陌生代码 | Spec 是跨会话的"集体记忆" |

核心观点：
- _"文档不只是写给人看的，也是写给 AI 看的。Spec 是人和 AI 之间的通信协议。"_
- _"SDD 不是传统文档的复辟，而是 Vibe Coding 的存档点。"_
- _"代码会过时，工具会迭代，模型会换代。但 Spec 作为意图的载体可以持久存在。"_

---

## 二、主流 SDD 框架对比

### 2.1 OpenSpec (Fission AI)

- **来源**: [GitHub](https://github.com/Fission-AI/OpenSpec)
- **理念**: 单一活文档 + 变更驱动
- **工作流**: `propose → apply → archive`
- **文件结构**: 每个变更一个文件夹 (`openspec/changes/{name}/`)
  - `proposal.md` — 范围与理由
  - `specs/` — 需求与使用场景
  - `design.md` — 技术方案
  - `tasks.md` — 实施清单
- **特点**:
  - 超轻量（~250行/spec vs Spec Kit 的 ~800行）
  - Delta 标记（ADDED/MODIFIED/REMOVED）适合存量项目
  - `/opsx:ff` 快进命令跳过仪式性步骤
  - 无外部工具依赖（npm 安装即可）
- **适合**: 个人开发、快速迭代、存量项目增量改进
- **不足**: 无合规支持，无多 agent 协作机制

### 2.2 Spec Kit (GitHub)

- **来源**: [GitHub Blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- **理念**: Constitution 驱动 + 严格阶段门禁
- **工作流**: `Specify → Plan → Tasks → Implement`（四阶段）
- **特点**:
  - Constitution 文件 (`speckit.constitution`) 定义治理原则
  - 每阶段强制人工 review 才可进入下一步
  - 支持 22+ AI 代理平台
  - 72.7K GitHub Stars (截至 2026.02)
- **适合**: 绿地项目、团队协作、需要严格治理
- **不足**: 太重（Python CLI 依赖），仪式性步骤多，不适合快速迭代

### 2.3 BMAD-METHOD

- **来源**: [对比文章](https://redreamality.com/blog/-sddbmad-vs-spec-kit-vs-openspec-vs-promptx/)
- **理念**: AI 角色模拟（Analyst/PM/Architect Agent 协作）
- **工作流**: 敏捷规划（PRD + 架构）→ 超详细用户故事
- **特点**:
  - Scrum-Master agent 将规划文档转化为实施故事
  - 深度域规划能力强
  - 角色分工清晰
- **适合**: 高歧义性复杂领域
- **不足**: 执行链较弱，主要偏规划

### 2.4 阿里 RIPER 工作流

- **来源**: [微信公众号文章](https://mp.weixin.qq.com/s/WoEetgbDkNidf7Flmg8dUQ)
- **理念**: Manual SDD — "把 SDD 变成习惯，而非流程"
- **工作流**: `Initialization → Research → Innovate → Plan → Execute → Review`
- **文件结构**（每 feature 一套）:
  ```
  docs/specs/feature-xxx/
  ├── 01_requirement.md      # 需求意图（PM/业务）
  ├── 02_interface.md        # 接口契约（跨角色协议）
  ├── 03_implementation.md   # 实施细节（AI 执行指令）
  └── 04_test_spec.md        # 测试策略与用例
  ```
- **关键设计**:
  - 每阶段有明确验收门禁
  - LAFR 故障排查协议: Locate → Analyze → Fix → Record
  - "双态管理": 开发期（热数据/草稿）vs 归档期（冷数据/知识库）
  - AI_CHANGELOG.md 决策日志 — 记录"为什么这么改"
  - SKILL.md 规则库 — "错误即规则"的复利逻辑
- **每阶段门禁**:
  | 阶段 | 门禁 |
  |------|------|
  | Research | AI 复述需求，模糊点已全部澄清 |
  | Innovate | 设计方案已 review 并 sign-off |
  | Plan | 实施计划拆解到原子级，换模型可100%实施 |
  | Execute | Lint ✅ Compile ✅ 严禁跳步 |
  | Review | 自动测试全绿 + 接口契约完全一致 |
- **适合**: 单兵作战 + 团队协作，实操性最强
- **不足**: 面向人机1:1协作，未考虑多 agent 拓扑

### 2.5 Claude Code 原生 SDD

- **来源**: [Agent Factory](https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development)
- **理念**: 用 Claude Code 原生能力（CLAUDE.md + Subagents + Tasks + Hooks）实现 SDD
- **四阶段**: 并行调研 → 规范编写 → 访谈细化 → 任务实施
- **特点**: 无外部依赖，完全利用 Claude Code 内建机制
- **适合**: 已使用 Claude Code 的团队

### 对比总结

| 维度 | OpenSpec | Spec Kit | BMAD | 阿里 RIPER | CC 原生 |
|------|---------|----------|------|-----------|---------|
| 重量 | 超轻 | 重 | 中重 | 中 | 轻 |
| 阶段数 | 3 | 4 | 多角色 | 5+Init | 4 |
| 门禁机制 | 隐式 | 严格 | 角色驱动 | 显式 | 无 |
| 任务拆分 | 基本 | AI生成 | Story化 | 手动+AI | Tasks系统 |
| 外部依赖 | npm | Python | 无 | 无 | 无 |
| Brownfield | 好 | 弱 | 中 | 手动 | 好 |
| Agent 协作 | 无 | 无 | 角色模拟 | 无 | Subagent |
| 合规支持 | 无 | 无 | 无 | 无 | 无 |

---

## 三、Thoughtworks 的 SDD 分级

来源: [Thoughtworks Blog](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)

| 级别 | 定义 | 适用场景 |
|------|------|---------|
| **Spec-first** | 先写 spec 再开发，完成后 spec 可能不再维护 | 一次性功能、原型 |
| **Spec-anchored** | spec 持续维护，用于后续迭代与维护 | 长期维护的核心功能 |
| **Spec-as-source** | spec 是源文件，人只改 spec，AI 生成代码 | 高度标准化的领域 |

**关键洞察**:
- "Spec drift 和幻觉本质上难以避免，仍需要高度确定性的 CI/CD 实践来保障质量"
- Spec 应使用领域语言而非技术实现语言
- 半结构化的输入/输出可提升推理性能

**对我们项目的启示**: 核心业务流（交易、资金）应该做到 Spec-anchored，基础设施和工具性代码 Spec-first 即可。

---

## 四、阿里文章的关键工程实践（详录）

### 4.1 RIPER 每阶段详细要求

**Research（调研与意图锁定）**
- 输入: 模糊需求/Bug 现象
- 动作: 让 AI "反向复述"需求，指出不清晰之处
- 产出: 清晰的 Requirement Spec
- 门禁: AI 指出的模糊点是否都已解答

**Innovate（设计与推演）**
- 严禁写代码，进行"审讯游戏"
- 让 AI 生成《技术实施草案》
- 强制互问互答: "除了这个方案，还有没有更好的？""坏处是什么？"
- 逼 AI 反问: "如果你对业务逻辑有不确定的地方，立刻向我提问"
- 去拟人化: 不问"你怎么看"，问"顶尖专家将如何设计"
- 产出: Design Spec (技术选型 + Pros/Cons)
- 门禁: 人对设计方案 review 并 sign-off

**Plan（规划与契约）**
- 明确物理路径: 改哪几个文件、新增哪些方法/类
- 定义 Mock 数据: Request/Response 示例
- 认知对齐: "为什么在 Service 层做这个校验而不是 Controller 层？"
- 产出: Implementation Spec (详细实施文档)
- 门禁: 实施计划是否拆解到"原子级"，换模型可否100%实施

**Execute（执行与编码）**
- 分步指令，不要一次生成 500 行
- 实时自检: 每步完成后 AI 总结"完成了什么，是否符合 Spec"
- 人工干预: 发现跑偏立刻暂停，回滚并修正 Prompt
- 门禁: Lint ✅ + Compile ✅（不过禁止进入下一步）

**Review（验收与对齐）**
- New Chat / 换模型审查（对抗顺从性幻觉）
- 法医式审查: 将 Spec + Git Diff 喂给新 AI
- 旁观者视角: "如果 Google Principal Engineer 做 Review，会指出什么？"
- 门禁: 自动测试全绿 + 接口契约一致

### 4.2 LAFR 故障排查协议

| 步骤 | 动作 | 说明 |
|------|------|------|
| **L**ocate | 构建案发现场 | Spec 文档 + 代码 + 报错日志 |
| **A**nalyze | AI 判决错误类型 | 代码层错误 vs 设计层错误 |
| **F**ix | 对症修复 | 代码错→补丁; 文档错→先改文档再改代码 |
| **R**ecord | 留痕 | 更新 SKILL.md 防复发 + 文档打补丁 |

### 4.3 文档双态管理

| 状态 | 场景 | 维护方式 |
|------|------|---------|
| **热数据** | 开发期 | 本地/Feature 分支，私人草稿，随改随用 |
| **冷数据** | 归档期 | PR 合并时精简上传，沉淀为团队知识 |

### 4.4 团队协作铁三角

```
后端（定义者）──── 02_interface.md ────→ 前端（消费者）
    │                                      │
    └─── 01_requirement.md ───→ QA（验证者）
```

- 后端先产出接口契约，前端/QA 基于契约并行启动
- 前端用 AI 从契约生成 TypeScript 类型 + Mock Server
- QA 用 AI 从需求+契约生成测试用例 + 自动化脚本

### 4.5 "错误即规则"的复利逻辑

```
传统: Bug → 修代码 → 提交 → 下次还犯
SDD:  Bug → 修 SKILL.md（规则库）→ AI 重新生成代码 → 问题绝迹
```

---

## 五、我们项目的场景分析

### 5.1 独特约束

| 约束 | 说明 | 对 SDD 的影响 |
|------|------|-------------|
| AI 为执行方 | 15+ agent 各司其职 | 需要 agent 间的 spec 通信协议 |
| 金融合规 | SEC/SFC/AML 7年审计 | 每个决策需要文档留痕 |
| 多服务架构 | 6域独立演进 | 跨域变更需要 contract 协议 |
| 已有 agent 拓扑 | 无需引入外部工具 | 可以用 Claude Code 原生能力 |

### 5.2 已有基础设施

| 设施 | 状态 | 可复用程度 |
|------|------|-----------|
| Agent 拓扑 (15+ agents) | ✅ 完整 | 直接作为执行引擎 |
| CLAUDE.md 层级 | ✅ 完整 | 路由和上下文隔离已就绪 |
| 规则文件 (.claude/rules/) | ✅ 完整 | 金融编码标准+安全合规+出入金 |
| Surface PRD (mobile) | ✅ 完整 (8份) | 需求层已覆盖 |
| 跨域 Contract | ⚠️ DRAFT (14份) | 有框架但未激活 |
| Domain PRD (backend) | ❌ 空 | 需要从 Surface PRD 推导 |
| Thread 系统 | ⚠️ 极少 | 机制在但未使用 |
| SDD Expert agent | ⚠️ 偏治理 | 缺乏执行流水线 |
| /sdd skill | ⚠️ 偏审计 | 缺少 feature/status/verify |

### 5.3 与行业工具的差异定位

我们不需要引入外部 SDD 工具。原因：
1. 已有完整的 agent 拓扑，就是我们的执行引擎
2. CLAUDE.md 就是我们的 Constitution
3. .claude/rules/ 就是我们的 SKILL.md / 规则库
4. Claude Code 原生 Tasks 就是我们的任务管理

需要做的是：**在现有基础设施上，渐进式引入阿里 RIPER 的实操要点**。

---

## 六、渐进式引入建议

### Level 0: 现在就可以做（零成本）

- 每次做新功能时，先让 AI 在 `docs/specs/` 下建一个 feature 文件夹
- 至少写一个 `01_requirement.md`（AI 起草，人审核）
- 完成后更新一行 changelog
- **效果**: 解决上下文腐烂问题，下次 new chat 可以直接恢复

### Level 1: 团队基本纪律

- 采用 4 文件模式 (requirement, interface, implementation, test_spec)
- 后端先产出 interface spec，前端/测试并行启动
- 每次实施前人审核 requirement + interface
- Bug 修复走 LAFR 流程并更新规则库
- **效果**: 解决审查瘫痪 + 团队并行效率

### Level 2: AI Agent 自动化

- SDD Expert agent 增加执行流水线支持
- `/sdd feature` 初始化 feature spec 文件夹
- 自动门禁: lint/compile/test 通过才进入下一步
- code-reviewer + qa-engineer 自动并行审查
- **效果**: 3 次人类检查点完成整个 feature

### Level 3: 完整合规闭环（远期）

- status.md 跟踪每个 feature 的全生命周期
- 决策日志自动生成，满足 7 年审计要求
- 跨域变更自动触发 contract review
- Spec drift 自动检测
- **效果**: Spec-anchored 级别的规范驱动开发

---

## 七、参考资料

| 来源 | 链接 | 侧重点 |
|------|------|--------|
| 阿里 SDD 实操文章 | [微信](https://mp.weixin.qq.com/s/WoEetgbDkNidf7Flmg8dUQ) | RIPER 工作流 + 文档模板 + 团队 SOP |
| OpenSpec | [GitHub](https://github.com/Fission-AI/OpenSpec) | 轻量级变更驱动 SDD |
| Spec Kit | [GitHub Blog](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/) | 四阶段门禁 + Constitution |
| Thoughtworks | [Blog](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices) | SDD 分级 + 行业分析 |
| Martin Fowler SDD Tools | [Article](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) | Kiro, Spec Kit, Tessl 深度对比 |
| BMAD vs Spec Kit vs OpenSpec | [Blog](https://redreamality.com/blog/-sddbmad-vs-spec-kit-vs-openspec-vs-promptx/) | 四框架对比 + 选型建议 |
| Claude Code 原生 SDD | [Agent Factory](https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development) | CLAUDE.md + Subagents + Tasks |
| OpenSpec 实践体验 | [Blog](https://darrenonthe.net/2026/01/01/open-spec-a-lighter-approach-to-specification-driven-development/) | 54文件5409行一次会话完成 |
| SDD 框架全景图 2026 | [Medium](https://medium.com/@visrow/spec-driven-development-is-eating-software-engineering-a-map-of-30-agentic-coding-frameworks-6ac0b5e2b484) | 30+ 框架分类 |
| Augment 工具评测 | [Article](https://www.augmentcode.com/tools/best-spec-driven-development-tools) | 6 Best SDD Tools 2026 |
| GSD vs Spec Kit vs OpenSpec | [Medium](https://medium.com/@richardhightower/agentic-coding-gsd-vs-spec-kit-vs-openspec-vs-taskmaster-ai-where-sdd-tools-diverge-0414dcb97e46) | 工具分歧点分析 |
