# gstack 架构深度分析报告

> Garry Tan 开源软件工厂的技术剖析与借鉴价值评估
>
> **分析日期**: 2026-03-18
> **项目来源**: [github.com/garrytan/gstack](https://github.com/garrytan/gstack)
> **许可证**: MIT
> **分析目的**: 评估 gstack 对我们券商交易平台的技术借鉴价值

---

## 目录

1. [项目概述](#1-项目概述)
2. [核心架构设计](#2-核心架构设计)
3. [技术栈分析](#3-技术栈分析)
4. [Skill 系统深度解析](#4-skill-系统深度解析)
5. [浏览器自动化架构](#5-浏览器自动化架构)
6. [质量保障体系](#6-质量保障体系)
7. [工程效率创新](#7-工程效率创新)
8. [对我们项目的借鉴价值](#8-对我们项目的借鉴价值)
9. [实施建议](#9-实施建议)
10. [源码关键文件索引](#10-源码关键文件索引)

---

## 1. 项目概述

### 1.1 核心定位

gstack 是一个将 Claude Code 转化为"虚拟工程团队"的开源软件工厂，由 Y Combinator CEO Garry Tan 创建并开源。

**核心数据**：
- 13 个专业化 slash commands
- 60 天内生成 60 万行生产代码（35% 为测试代码）
- 单人日产出 10,000-20,000 行可用代码
- MIT 许可证，完全开源

### 1.2 设计哲学

```
传统开发：人类写代码 → AI 辅助
gstack 模式：AI 写代码 → 人类审查关键决策点
```

**三大核心理念**：

1. **角色专业化** — 每个 skill 模拟一个专业角色（CEO、工程经理、设计师、QA）
2. **智能路由** — 根据变更类型自动选择审查流程（CEO 不审查基础设施修复）
3. **自动化质量门禁** — 测试、覆盖率、代码审查、文档同步全自动化

### 1.3 与我们项目的相似性

| 维度 | gstack | 我们的券商平台 | 匹配度 |
|------|--------|--------------|-------|
| **Agent 架构** | 13 个专业 skills | 15+ 专业 agents | ✅ 高度相似 |
| **质量要求** | 自动化测试 + 审查 | 金融零容错 | ✅ 理念一致 |
| **文档驱动** | SKILL.md 模板 | SDD + CLAUDE.md | ✅ 都是规范驱动 |
| **并行执行** | Conductor 多会话 | Agent 并行调用 | ✅ 架构相似 |
| **领域特殊性** | 通用软件 | 金融合规 | ⚠️ 需要适配 |

---

## 2. 核心架构设计

### 2.1 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     Claude Code (主进程)                      │
└────────────┬────────────────────────────────────────────────┘
             │
             ├─→ ~/.claude/skills/gstack/  (全局安装)
             │   ├─ plan-ceo-review/
             │   ├─ plan-eng-review/
             │   ├─ design-consultation/
             │   ├─ review/
             │   ├─ qa/
             │   ├─ ship/
             │   └─ browse/  ← 浏览器 CLI
             │
             ├─→ Chromium Daemon (localhost HTTP)
             │   ├─ Port: 随机 10000-60000
             │   ├─ Auth: Bearer Token
             │   ├─ State: .gstack/browse.json
             │   └─ Lifecycle: 自动重启
             │
             └─→ Conductor (并行编排)
                 ├─ 10+ 隔离会话
                 ├─ 独立 git worktrees
                 └─ 并行执行 skills
```

### 2.2 关键设计决策

**决策 1：持久化浏览器守护进程**

```
问题：每次启动 Chromium 需要 3-5 秒
方案：localhost HTTP daemon + 状态文件
结果：首次调用后延迟降至 100-200ms
```

- 守护进程维护 cookies、tabs、登录会话
- 随机端口（10000-60000）支持多工作区
- Bearer Token 认证保证安全性
- 版本不匹配时自动重启

**决策 2：Bun 而非 Node.js**

| 原因 | 技术细节 |
|------|---------|
| **编译二进制** | 消除运行时依赖，用户无需安装 Node |
| **原生 SQLite** | 解密 Chrome cookies 无需编译 addon |
| **原生 TypeScript** | 开发时无需构建步骤 |
| **轻量 HTTP** | `Bun.serve()` 无需 Express 等框架 |

**决策 3：Ref 系统而非 DOM 选择器**

```typescript
// 传统方式（易失效）
await page.click('#submit-button')

// gstack 方式（基于 a11y tree）
await page.click('@e42')  // ref 从可访问性树生成
```

优势：
- 避免 CSP（内容安全策略）冲突
- 不受框架 hydration 影响
- 导航时自动清除，避免 stale refs

**决策 4：模板生成文档**

```
SKILL.md.tmpl (源码) → gen:skill-docs → SKILL.md (生成)
                                          ↓
                                    提交到 git
```

- 占位符 `{{COMMAND_REFERENCE}}` 从源码元数据填充
- 文档与实现强制同步
- 修改模板后自动重新生成

---

## 3. 技术栈分析

### 3.1 核心技术选型

| 技术 | 版本/工具 | 用途 | 选型理由 |
|------|----------|------|---------|
| **运行时** | Bun v1.0+ | 执行环境 | 编译二进制 + 原生 TS + SQLite |
| **语言** | TypeScript 74.8% | 主要开发语言 | 类型安全 + Claude 友好 |
| **浏览器** | Playwright + Chromium | 自动化测试 | 跨平台 + 稳定 API |
| **模板** | Go templates 23.4% | 文档生成 | 简单高效 |
| **版本控制** | Git | 代码管理 | 标准工具 |
| **AI 模型** | Claude Sonnet 4.6 | 代码生成 | 最强编码能力 |

### 3.2 依赖分析

```json
// package.json 关键依赖
{
  "dependencies": {
    "playwright": "^1.40.0",      // 浏览器自动化
    "@anthropic-ai/sdk": "^0.x",  // Claude API（测试用）
    "sqlite3": "native in Bun"    // Cookie 解密
  },
  "devDependencies": {
    "typescript": "^5.x",
    "bun-types": "^1.x"
  }
}
```

**零外部运行时依赖** — 编译后的二进制文件可独立运行

### 3.3 文件结构

```
gstack/
├── .claude/
│   └── skills/gstack/  ← 安装目标
├── browse/             ← 浏览器 CLI 源码
│   ├── server.ts       ← HTTP daemon
│   ├── cli.ts          ← 命令行入口
│   └── playwright.ts   ← 浏览器控制
├── plan-ceo-review/    ← Skill: CEO 审查
│   └── SKILL.md.tmpl
├── review/             ← Skill: 代码审查
│   └── SKILL.md.tmpl
├── qa/                 ← Skill: QA 测试
│   └── SKILL.md.tmpl
├── ship/               ← Skill: 发布流程
│   └── SKILL.md.tmpl
├── test/               ← 测试套件
│   ├── e2e/            ← 端到端测试
│   └── evals/          ← LLM-as-judge 评估
├── scripts/            ← 构建脚本
│   └── gen-skill-docs  ← 文档生成
├── CLAUDE.md           ← Claude Code 配置
├── ARCHITECTURE.md     ← 架构文档
└── setup               ← 安装脚本
```

---

## 4. Skill 系统深度解析

### 4.1 Skill 生命周期

```
1. 开发阶段
   ├─ 编写 SKILL.md.tmpl（模板）
   ├─ 实现 browse CLI 功能（如需要）
   └─ 编写测试用例

2. 构建阶段
   ├─ bun run gen:skill-docs
   ├─ 填充占位符 {{COMMAND_REFERENCE}}
   └─ 生成 SKILL.md

3. 安装阶段
   ├─ ./setup 脚本
   ├─ 复制到 ~/.claude/skills/gstack/
   └─ 注册为 slash command

4. 执行阶段
   ├─ 用户输入 /ship
   ├─ Claude 加载 ship/SKILL.md
   ├─ 执行 prompt 中的指令
   └─ 调用 browse CLI（如需要）
```

### 4.2 核心 Skills 深度分析

#### 4.2.1 `/ship` — 自动化发布流程

**执行流程**（8 个步骤）：

```
Step 1: Pre-flight checks
  ├─ 验证在 feature branch
  ├─ 检查 review gates
  └─ 确认 git 状态

Step 2: Merge base branch
  ├─ git fetch origin
  ├─ git merge origin/main
  └─ 处理冲突（如有）

Step 3: Run tests
  ├─ 并行执行 Rails + Vitest
  ├─ 失败则停止
  └─ 继续到覆盖率审计

Step 3.1-3.4: Coverage audit
  ├─ 追踪 diff 中的每个代码路径
  ├─ 生成 ASCII 覆盖率图
  ├─ 自动生成缺失的测试（最多 20 个）
  └─ 优先级：错误处理 > 边界条件

Step 3.5: Pre-landing review
  ├─ 结构化检查清单
  ├─ 自动修复（auto-fix）
  ├─ 需要判断的问题（ASK）
  └─ 修复后重新测试

Step 4-5: Version & Changelog
  ├─ 自动决定版本号（<50 行 = MICRO）
  ├─ 从 commits 生成 CHANGELOG
  └─ 分类：Added/Changed/Fixed/Removed

Step 6-7: Commit & Push
  ├─ 按依赖顺序拆分 commits
  ├─ 格式：基础设施 → 模型 → 控制器 → 版本
  └─ git push origin HEAD

Step 8: Create PR
  ├─ 生成详细 PR body
  ├─ 包含：测试覆盖率、审查发现、eval 结果
  └─ 返回 PR URL
```

**自动化哲学**：
- 仅在以下情况停止：测试失败、合并冲突、MINOR/MAJOR 版本决策、ASK 项
- 其他一切自动化：未提交变更、版本选择、CHANGELOG、commit 消息

#### 4.2.2 `/qa` — 浏览器自动化测试

**核心流程**：

```
Phase 1: Testing
  ├─ 打开 Chromium
  ├─ 模拟真实用户交互（点击、填表、导航）
  ├─ 捕获基线健康分数
  └─ 识别 bugs

Phase 2: Bug Triage
  ├─ 按严重性分类：critical/high/medium/low
  ├─ 用户选择修复层级（quick/standard/exhaustive）
  └─ 生成修复队列

Phase 3: Fix Loop（每个 bug）
  ├─ 定位源码
  ├─ 应用最小化修复
  ├─ 原子提交：fix(qa): ISSUE-NNN — description
  ├─ 重新测试 + 截图对比
  └─ 生成回归测试

Phase 4: Regression Testing
  ├─ 匹配项目现有测试模式
  ├─ 追踪触发 bug 的代码路径
  └─ 验证修复无副作用

Phase 5: Self-Regulation
  ├─ 跟踪 "WTF-likelihood" 分数
  ├─ 基于 reverts + 风险变更
  └─ >20% 时停止并请求确认

Phase 6: Reporting
  ├─ 健康分数 delta
  ├─ 修复证据 + 截图
  ├─ Ship-readiness 总结
  └─ 延迟问题 → TODOS.md
```

**关键创新**：
- 真实浏览器测试（非 headless mock）
- 自动生成回归测试防止复发
- 自我监管机制避免过度修改

#### 4.2.3 `/review` — 代码审查自动化

**审查维度**：

| 维度 | 检查项 | 处理方式 |
|------|--------|---------|
| **结构性问题** | 重复代码、过长函数、循环依赖 | Auto-fix |
| **安全漏洞** | SQL 注入、XSS、硬编码密钥 | ASK（需人工确认） |
| **性能问题** | N+1 查询、未索引字段 | ASK |
| **测试覆盖** | 缺失测试、边界条件 | Auto-generate |
| **文档缺失** | 无注释的复杂逻辑 | Auto-add |

**智能路由**：
- CEO review 跳过基础设施 bug 修复
- Design review 跳过纯后端变更
- 根据 diff 类型选择审查流程

---

## 5. 浏览器自动化架构

### 5.1 守护进程设计

**为什么需要守护进程？**

```
传统方式（每次启动）：
  启动 Chromium: 3-5 秒
  加载页面: 1-2 秒
  执行操作: 0.5 秒
  总计: 4.5-7.5 秒

守护进程方式（首次后）：
  HTTP 调用: 0.1-0.2 秒
  执行操作: 0.5 秒
  总计: 0.6-0.7 秒

性能提升: 7-12x
```

### 5.2 状态管理

**`.gstack/browse.json` 结构**：

```json
{
  "pid": 12345,
  "port": 45678,
  "token": "random-bearer-token-uuid",
  "version": "0.1.0",
  "started_at": "2026-03-18T10:00:00Z"
}
```

**生命周期管理**：
1. CLI 读取状态文件
2. 检查进程是否存活（`kill -0 $PID`）
3. 验证版本匹配
4. 不匹配则杀死旧进程，启动新进程
5. 更新状态文件

### 5.3 安全模型

| 安全措施 | 实现方式 |
|---------|---------|
| **网络隔离** | 仅绑定 localhost，拒绝外部连接 |
| **认证** | Bearer Token（UUID v4） |
| **Cookie 安全** | PBKDF2+AES-128-CBC 解密，内存处理 |
| **权限最小化** | 只读打开 Chrome cookie 数据库 |
| **Keychain 访问** | macOS 需用户批准 |

### 5.4 Ref 系统实现

**传统 DOM 选择器问题**：
```javascript
// 易失效
await page.click('#submit')  // ID 变化
await page.click('.btn-primary')  // 类名变化
await page.click('button:nth-child(3)')  // 结构变化
```

**gstack Ref 系统**：
```javascript
// 基于可访问性树
await page.click('@e42')  // 从 a11y tree 生成
await page.fill('@c5', 'text')  // 控件 ref
```

**优势**：
- 不依赖 DOM 结构
- 避免 CSP 冲突
- 框架无关（React/Vue/Svelte）
- 导航时自动失效（防止 stale refs）

---

## 6. 质量保障体系

### 6.1 三层测试策略

```
Layer 1: Static Validation（免费，<1秒）
  ├─ TypeScript 类型检查
  ├─ ESLint 规则
  └─ 格式验证

Layer 2: E2E via Claude（~$3.85/次）
  ├─ 基于 git diff 选择测试
  ├─ 独立子进程执行
  └─ NDJSON 流式结果

Layer 3: LLM-as-Judge（~$0.15/次）
  ├─ Claude 评估输出质量
  ├─ 对比预期 vs 实际
  └─ 生成评分报告
```

### 6.2 覆盖率审计机制

**追踪维度**：
1. **数据流** — 变量从定义到使用的路径
2. **条件分支** — if/else、switch、三元运算符
3. **错误处理** — try/catch、错误回调
4. **用户交互** — 点击、输入、导航

**ASCII 覆盖率图示例**：
```
src/auth/login.ts
  ├─ loginUser()
  │   ├─ [✓] 正常登录路径
  │   ├─ [✓] 错误密码
  │   ├─ [✗] 账户锁定  ← 缺失测试
  │   └─ [✗] 网络超时  ← 缺失测试
  └─ validateToken()
      ├─ [✓] 有效 token
      └─ [✓] 过期 token
```

### 6.3 自动测试生成

**生成策略**：
- 最多 20 个测试/次
- 优先级：错误处理 > 边界条件 > 正常路径
- 匹配项目现有测试风格（Jest/Vitest/RSpec）

---

## 7. 工程效率创新

### 7.1 并行执行架构

**Conductor 多会话编排**：

```
主会话（用户交互）
  ├─ 会话 1: /qa on feature-A
  ├─ 会话 2: /review on feature-B
  ├─ 会话 3: /ship on feature-C
  └─ 会话 N: /design-review on feature-N

每个会话：
  ├─ 独立 git worktree
  ├─ 隔离文件系统
  └─ 独立 Claude 实例
```

**性能提升**：
- 10+ 并行任务
- 无上下文污染
- 独立失败隔离

### 7.2 文档同步机制

**模板驱动生成**：

```bash
# 开发流程
1. 编辑 SKILL.md.tmpl
2. 运行 bun run gen:skill-docs
3. 自动生成 SKILL.md
4. 同时提交模板和生成文件

# 占位符系统
{{COMMAND_REFERENCE}}  → 从 CLI 源码提取
{{SNAPSHOT_FLAGS}}     → 从配置文件读取
{{VERSION}}            → 从 package.json 读取
```

**强制同步**：
- 文档从源码生成，不可能脱节
- CI 检查模板和生成文件是否匹配
- 修改实现必须更新模板

### 7.3 版本管理策略

**自动版本决策**：

| Diff 大小 | 版本类型 | 是否需要确认 |
|----------|---------|------------|
| < 50 行 | MICRO (0.0.x) | 否 |
| 50-500 行 | PATCH (0.x.0) | 否 |
| > 500 行 | MINOR (x.0.0) | 是 |
| 破坏性变更 | MAJOR (X.0.0) | 是 |

**CHANGELOG 自动生成**：
```markdown
## [0.2.5] - 2026-03-18

### Added
- New /qa-design-review skill for visual regression testing

### Changed
- Improved /ship coverage audit to detect async paths

### Fixed
- fix(qa): ISSUE-042 — handle timeout in login flow
- fix(browse): prevent stale refs after navigation

### Removed
- Deprecated /legacy-review command
```

---

## 8. 对我们项目的借鉴价值

### 8.1 高价值借鉴点

#### 8.1.1 自动化发布流程（`/ship` 启发）

**我们可以创建 `/ship-safe`**：

```
Step 1: Pre-flight
  ├─ 验证 feature branch
  ├─ 检查合规门禁
  └─ 确认无 PII 泄露

Step 2: Merge & Test
  ├─ 合并 main
  ├─ 运行单元测试
  └─ 运行集成测试

Step 3: 合规审计（金融特有）
  ├─ 检查 decimal 类型使用
  ├─ 验证 UTC 时间戳
  ├─ 审计日志完整性
  └─ PII 加密检查

Step 4: 安全扫描
  ├─ 依赖漏洞扫描
  ├─ 敏感信息检测
  └─ API 安全检查

Step 5: 覆盖率审计
  ├─ 追踪资金流路径
  ├─ 验证错误处理
  └─ 生成缺失测试

Step 6: 监管文档
  ├─ 更新审计日志
  ├─ 生成变更报告
  └─ 合规检查清单

Step 7: Version & Changelog
  ├─ 自动版本号
  └─ 生成 CHANGELOG

Step 8: Create PR
  ├─ 包含合规审查结果
  └─ 附加安全扫描报告
```

#### 8.1.2 浏览器自动化测试（`/qa` 启发）

**我们可以创建 `/qa-trading`**：

```
测试场景：
  ├─ 登录流程（生物识别）
  ├─ KYC 上传（文档验证）
  ├─ 入金流程（银行卡绑定）
  ├─ 下单流程（实时行情 → 下单 → 确认）
  ├─ 持仓查看（P&L 计算）
  └─ 出金流程（AML 检查）

金融特有检查：
  ├─ 风险揭示是否展示
  ├─ 费用是否透明
  ├─ 小数精度是否正确
  └─ 时区转换是否准确
```

**已有基础**：
- ✅ Playwright MCP 已配置
- ✅ Chrome DevTools MCP 可用
- ⚠️ 需要封装为 skill

#### 8.1.3 文档同步机制

**我们可以创建 `/sync-specs`**：

```
触发时机：
  ├─ 代码变更后
  ├─ API 接口修改
  └─ 数据模型变更

同步目标：
  ├─ docs/specs/{domain}/*.md
  ├─ docs/contracts/api/*.yaml
  └─ {service}/CLAUDE.md

检查项：
  ├─ Spec 是否描述了新功能
  ├─ API 文档是否更新
  └─ CLAUDE.md 是否反映架构变化
```

### 8.2 需要适配的部分

#### 8.2.1 合规审查层

gstack 缺少金融合规，我们需要增加：

```
/compliance-audit（已有，需增强）
  ├─ SEC/FINRA 规则检查
  ├─ SFC/AMLO 规则检查
  ├─ 资金流合规验证
  └─ 审计日志完整性

/aml-check（新建）
  ├─ 交易模式分析
  ├─ 结构化存款检测
  └─ 可疑活动标记

/security-review（已有，需增强）
  ├─ PII 加密验证
  ├─ API 签名检查
  └─ 证书 pinning 验证
```

#### 8.2.2 跨境复杂性

```
/cross-border-check（新建）
  ├─ 美股合规检查
  ├─ 港股合规检查
  ├─ FATCA/CRS 验证
  └─ 货币转换精度
```

#### 8.2.3 监管报告生成

```
/generate-audit-report（新建）
  ├─ 变更审计报告
  ├─ 测试覆盖率报告
  ├─ 安全扫描报告
  └─ 合规检查清单

/regulatory-filing（新建）
  ├─ SEC Form 报备
  ├─ SFC 变更申请
  └─ 监管问询响应
```

### 8.3 架构对比总结

| 维度 | gstack | 我们的项目 | 行动建议 |
|------|--------|-----------|---------|
| **发布自动化** | ✅ `/ship` 一键发布 | ⚠️ 手动流程 | 创建 `/ship-safe` |
| **浏览器测试** | ✅ `/qa` 真实浏览器 | ⚠️ 有 MCP 未封装 | 创建 `/qa-trading` |
| **文档同步** | ✅ 模板生成 | ❌ 手动维护 | 创建 `/sync-specs` |
| **合规审查** | ❌ 无 | ✅ `/compliance-audit` | 保持并增强 |
| **安全扫描** | ⚠️ 基础检查 | ✅ 专业 agent | 保持 |
| **并行执行** | ✅ Conductor | ✅ Agent 并行 | 已具备 |
| **质量门禁** | ✅ 自动化 | ⚠️ 部分自动 | 学习 `/ship` |

---

## 9. 实施建议

### 9.1 短期行动（1-2周）

**优先级 P0**：

1. **创建 `/ship-safe` skill**
   - 基于 gstack `/ship` 改造
   - 增加合规审计步骤
   - 集成现有 `code-reviewer` 和 `security-engineer`

2. **创建 `/sync-specs` skill**
   - 代码变更后提示更新 specs
   - 检查 API 文档一致性
   - 验证 CLAUDE.md 准确性

**优先级 P1**：

3. **封装浏览器测试为 `/qa-trading`**
   - 利用现有 Playwright MCP
   - 定义金融场景测试流程
   - 集成 `qa-engineer` agent

### 9.2 中期行动（1个月）

**优先级 P2**：

4. **建立三层审查流程**
   - PM review → Security review → Code review
   - 智能路由（根据变更类型）
   - 参考 gstack 的 plan-*-review 系列

5. **实现覆盖率审计**
   - 追踪资金流路径
   - 验证错误处理覆盖
   - 自动生成缺失测试

6. **创建监管报告生成 skills**
   - `/generate-audit-report`
   - `/regulatory-filing`

### 9.3 长期优化（3个月）

**优先级 P3**：

7. **持久化浏览器守护进程**
   - 参考 gstack browse daemon
   - 降低测试启动延迟
   - 维护登录会话

8. **建立 LLM-as-judge 评估**
   - 自动评估代码质量
   - 合规检查自动化
   - 持续改进 agents

### 9.4 不建议的行动

❌ **不要做**：
1. 直接复制 gstack skills（通用场景 ≠ 金融场景）
2. 放弃现有 agent 架构（我们的更适合金融）
3. 忽略合规要求追求速度（监管风险 > 效率）

---

## 10. 源码关键文件索引

### 10.1 核心架构文件

| 文件路径 | 作用 | 关键内容 |
|---------|------|---------|
| `ARCHITECTURE.md` | 系统设计文档 | 守护进程、Ref 系统、安全模型 |
| `CLAUDE.md` | Claude Code 配置 | Skills 列表、使用指南 |
| `conductor.json` | 并行编排配置 | 多会话管理 |
| `package.json` | 依赖管理 | Bun、TypeScript、Playwright |

### 10.2 浏览器自动化

| 文件路径 | 作用 | 关键技术 |
|---------|------|---------|
| `browse/server.ts` | HTTP daemon | Bun.serve、状态管理 |
| `browse/cli.ts` | 命令行入口 | 进程管理、版本检查 |
| `browse/playwright.ts` | 浏览器控制 | Playwright API、Ref 系统 |
| `.gstack/browse.json` | 守护进程状态 | PID、端口、token |

### 10.3 核心 Skills

| Skill 路径 | 功能 | 借鉴价值 |
|-----------|------|---------|
| `ship/SKILL.md.tmpl` | 自动化发布 | ⭐⭐⭐⭐⭐ 高 |
| `qa/SKILL.md.tmpl` | 浏览器测试 | ⭐⭐⭐⭐⭐ 高 |
| `review/SKILL.md.tmpl` | 代码审查 | ⭐⭐⭐⭐ 中高 |
| `plan-ceo-review/SKILL.md.tmpl` | CEO 审查 | ⭐⭐⭐ 中 |
| `design-consultation/SKILL.md.tmpl` | 设计咨询 | ⭐⭐ 低（我们有 ui-designer） |
| `document-release/SKILL.md.tmpl` | 文档同步 | ⭐⭐⭐⭐ 中高 |

### 10.4 测试基础设施

| 文件路径 | 作用 | 技术要点 |
|---------|------|---------|
| `test/e2e/` | 端到端测试 | Claude 子进程、NDJSON 流 |
| `test/evals/` | LLM 评估 | Claude API、评分系统 |
| `test/helpers/touchfiles.ts` | 依赖追踪 | 文件变更 → 测试选择 |

### 10.5 构建工具

| 文件路径 | 作用 | 实现方式 |
|---------|------|---------|
| `scripts/gen-skill-docs` | 文档生成 | Go templates、占位符替换 |
| `setup` | 安装脚本 | Shell、符号链接 |
| `bin/` | 编译产物 | Bun build 输出 |

---

## 附录：关键代码片段分析

### A.1 守护进程启动逻辑（伪代码）

```typescript
// browse/cli.ts
async function ensureDaemon() {
  const state = readStateFile('.gstack/browse.json')

  if (!state || !isProcessAlive(state.pid)) {
    // 启动新守护进程
    const port = randomPort(10000, 60000)
    const token = generateUUID()
    const pid = spawn('bun', ['run', 'browse/server.ts', port, token])

    writeStateFile({ pid, port, token, version })
    return { port, token }
  }

  if (state.version !== currentVersion) {
    // 版本不匹配，重启
    kill(state.pid)
    return ensureDaemon()
  }

  return { port: state.port, token: state.token }
}
```

### A.2 Ref 系统实现（伪代码）

```typescript
// browse/playwright.ts
async function snapshot(page: Page) {
  const tree = await page.accessibility.snapshot()
  const refs = new Map<string, Element>()

  function traverse(node: A11yNode, index: number) {
    if (node.role === 'button' || node.role === 'textbox') {
      const ref = `@e${index}`
      refs.set(ref, node)
    }
    node.children?.forEach((child, i) => traverse(child, index + i))
  }

  traverse(tree, 1)
  return { tree, refs }
}

async function click(page: Page, ref: string) {
  const element = refs.get(ref)
  if (!element) throw new Error(`Stale ref: ${ref}`)

  await page.locator(element.selector).click()
}
```

### A.3 覆盖率审计逻辑（伪代码）

```typescript
// ship/coverage-audit.ts
async function auditCoverage(diff: GitDiff) {
  const paths = extractCodePaths(diff)
  const tests = findRelatedTests(paths)
  const coverage = analyzeCoverage(paths, tests)

  const gaps = coverage.filter(p => !p.tested)
  const generated = []

  for (const gap of gaps.slice(0, 20)) {
    if (gap.type === 'error-handler') {
      generated.push(generateErrorTest(gap))
    } else if (gap.type === 'edge-case') {
      generated.push(generateEdgeCaseTest(gap))
    }
  }

  return { coverage, gaps, generated }
}
```

---

## 总结

gstack 提供了一套成熟的 AI 工程团队自动化方案，其核心价值在于：

1. **自动化质量门禁** — 测试、审查、发布全流程自动化
2. **持久化浏览器** — 真实环境测试，性能提升 7-12x
3. **智能路由** — 根据变更类型选择审查流程
4. **文档强制同步** — 模板生成，杜绝文档脱节

对我们券商交易平台的启示：

✅ **可直接借鉴**：
- `/ship` 的自动化发布流程（需增加合规步骤）
- `/qa` 的浏览器测试方法（已有 Playwright MCP）
- 文档同步机制（解决 specs 脱节问题）

⚠️ **需要适配**：
- 增加金融合规审查层
- 跨境监管复杂性处理
- 监管报告自动生成

❌ **不适用**：
- 通用场景的 skills（金融场景太特殊）
- 忽略合规的快速迭代（监管风险高）

**建议优先实施**：`/ship-safe` + `/sync-specs` + `/qa-trading`，在 1-2 周内快速验证价值。

---

**文档维护**：本分析基于 gstack 当前版本（2026-03-18），应随 gstack 更新定期 review。

**相关文档**：
- [Product Management Research](./product-management-research.md) — PM 框架参考
- [SDD Workflow Research](./sdd-workflow-research.md) — 规范驱动开发
- [`.claude/agents/`](../.claude/agents/) — 我们的 agent 定义
- [`.claude/skills/`](../.claude/skills/) — 我们的 skills 定义
