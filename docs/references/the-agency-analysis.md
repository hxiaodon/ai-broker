# The Agency 项目深度分析

> 142 个专业化 AI Agent 定义文件的开源项目分析
>
> **项目地址**: [github.com/msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)
> **Stars**: 10k+ (7天内获得)
> **许可证**: 开源
> **分析日期**: 2026-03-18

---

## 目录

1. [项目概述](#1-项目概述)
2. [Agent 组织架构](#2-agent-组织架构)
3. [核心 Agent 分析](#3-核心-agent-分析)
4. [文件格式与结构](#4-文件格式与结构)
5. [与我们项目的对比](#5-与我们项目的对比)
6. [可借鉴的 Agent 定义](#6-可借鉴的-agent-定义)
7. [实施建议](#7-实施建议)

---

## 1. 项目概述

### 1.1 核心理念

**"将 AI 结构化为一家公司"**

The Agency 不是提供单一通用 AI 助手，而是提供 142 个专业化 agents，每个都有：
- 独特的身份和个性
- 明确的工作流程
- 具体的交付物（真实代码）
- 可衡量的成功指标

### 1.2 项目起源

- 起源于 Reddit 讨论
- 经过数月打磨
- 7 天内获得 10k+ GitHub stars
- 从最初 61 个 agents 扩展到 142 个

### 1.3 支持的工具

| 工具 | 格式 | 集成方式 |
|------|------|---------|
| **Claude Code** | `.md` 文件 | 复制到 `~/.claude/agents/` |
| **Cursor** | `.mdc` rule 文件 | 转换脚本 |
| **Aider** | 配置文件 | 转换脚本 |
| **Windsurf** | 配置文件 | 转换脚本 |
| **Gemini CLI** | 配置文件 | 转换脚本 |
| **GitHub Copilot** | 参考文档 | 手动适配 |

---

## 2. Agent 组织架构

### 2.1 11 大部门（142 个 Agents）

| 部门 | Agent 数量 | 覆盖领域 |
|------|-----------|---------|
| **Engineering** | 24 | 前端、后端、移动、AI、DevOps、安全、数据库 |
| **Design** | 8 | UI/UX、品牌、视觉叙事、包容性设计 |
| **Paid Media** | 7 | PPC、搜索、社交、程序化广告 |
| **Sales** | 8 | 外呼、发现、交易策略、客户管理 |
| **Marketing** | 28 | 内容、社交平台、SEO、电商 |
| **Product** | 5 | Sprint 规划、趋势研究、反馈综合 |
| **Project Management** | 6 | 工作室制作、运营、实验跟踪 |
| **Testing** | 8 | QA、性能、可访问性、API 测试 |
| **Support** | 6 | 客服、分析、财务、合规 |
| **Spatial Computing** | 6 | XR/VR、Vision Pro、WebXR |
| **Specialized** | 20 | 多 agent 编排、区块链、合规、文化策略 |

### 2.2 Engineering 部门详细分解（24 个 Agents）

| Agent 名称 | 专业领域 | 关键技能 |
|-----------|---------|---------|
| **Frontend Developer** | React/Vue/Angular | UI 实现、Core Web Vitals |
| **Backend Architect** | API 设计、数据库架构 | 可扩展性、微服务 |
| **Mobile App Builder** | iOS/Android | 原生开发、跨平台 |
| **AI Engineer** | ML/LLM 集成 | 模型训练、推理优化 |
| **DevOps Engineer** | CI/CD、基础设施 | Kubernetes、监控 |
| **Security Engineer** | 威胁建模、代码审查 | 渗透测试、合规 |
| **Database Optimizer** | SQL 优化、索引 | 查询性能、数据建模 |
| **API Specialist** | RESTful/GraphQL | 文档、版本管理 |
| **Cloud Architect** | AWS/Azure/GCP | 成本优化、高可用 |
| **Data Engineer** | ETL、数据管道 | Spark、Airflow |

### 2.3 Testing 部门详细分解（8 个 Agents）

| Agent 名称 | 专业领域 | 测试类型 |
|-----------|---------|---------|
| **QA Engineer** | 端到端测试 | 功能测试、回归测试 |
| **Performance Tester** | 负载测试、压力测试 | JMeter、K6 |
| **Accessibility Tester** | WCAG 合规 | 屏幕阅读器、键盘导航 |
| **API Tester** | API 自动化 | Postman、REST Assured |
| **Security Tester** | 漏洞扫描 | OWASP Top 10 |
| **Mobile Tester** | 移动端测试 | Appium、Detox |
| **Visual Regression Tester** | UI 一致性 | Percy、Chromatic |
| **Test Automation Architect** | 测试框架设计 | Selenium、Playwright |

---

## 3. 核心 Agent 分析

### 3.1 Frontend Developer Agent

**身份定义**：
```markdown
你是一位专注于现代 Web 应用的前端开发专家。
你的代码优雅、高性能，并且始终考虑用户体验。
```

**核心使命**：
- 构建像素完美的用户界面
- 优化 Core Web Vitals（LCP、FID、CLS）
- 确保跨浏览器兼容性
- 实现响应式设计

**工作流程**：
1. 分析设计稿和需求
2. 选择合适的技术栈（React/Vue/Angular）
3. 实现组件化架构
4. 性能优化和测试
5. 代码审查和文档

**技术交付物**（示例）：
```jsx
// React 组件示例
const Button = ({ variant, children, onClick }) => {
  return (
    <button
      className={`btn btn-${variant}`}
      onClick={onClick}
      aria-label={children}
    >
      {children}
    </button>
  );
};
```

**成功指标**：
- Lighthouse 性能分数 > 90
- 零可访问性错误
- 组件复用率 > 70%
- 代码审查通过率 > 95%

### 3.2 Backend Architect Agent

**身份定义**：
```markdown
你是一位系统架构师，专注于构建可扩展、高性能的后端系统。
你深谙微服务、数据库设计和云原生架构。
```

**核心使命**：
- 设计 RESTful/GraphQL API
- 数据库架构和优化
- 微服务拆分和通信
- 云基础设施规划

**工作流程**：
1. 需求分析和架构设计
2. API 规范定义（OpenAPI）
3. 数据模型设计
4. 服务拆分和边界定义
5. 性能和安全审查

**技术交付物**（示例）：
```go
// Go 微服务示例
type OrderService struct {
    repo OrderRepository
    cache Cache
}

func (s *OrderService) CreateOrder(ctx context.Context, order *Order) error {
    // 验证订单
    if err := order.Validate(); err != nil {
        return err
    }

    // 保存到数据库
    if err := s.repo.Save(ctx, order); err != nil {
        return err
    }

    // 更新缓存
    s.cache.Set(order.ID, order)
    return nil
}
```

**成功指标**：
- API 响应时间 < 200ms (P95)
- 系统可用性 > 99.9%
- 数据库查询优化率 > 80%
- 代码覆盖率 > 85%

### 3.3 Security Engineer Agent

**身份定义**：
```markdown
你是一位安全专家，专注于识别和修复安全漏洞。
你的目标是构建零信任架构，保护用户数据和系统安全。
```

**核心使命**：
- 威胁建模和风险评估
- 安全代码审查
- 渗透测试和漏洞扫描
- 合规性验证（OWASP、PCI DSS）

**工作流程**：
1. 威胁建模（STRIDE）
2. 代码静态分析（SAST）
3. 动态安全测试（DAST）
4. 漏洞修复和验证
5. 安全文档和培训

**技术交付物**（示例）：
```python
# 安全审计示例
def audit_sql_injection(code):
    """检测 SQL 注入漏洞"""
    patterns = [
        r'execute\(["\'].*\+.*["\']',  # 字符串拼接
        r'cursor\.execute\(.*%.*\)',    # 格式化字符串
    ]

    vulnerabilities = []
    for pattern in patterns:
        matches = re.findall(pattern, code)
        if matches:
            vulnerabilities.append({
                'type': 'SQL Injection',
                'severity': 'HIGH',
                'matches': matches
            })

    return vulnerabilities
```

**成功指标**：
- 零高危漏洞上线
- 安全扫描覆盖率 100%
- 渗透测试通过率 > 95%
- 合规检查通过率 100%

### 3.4 QA Engineer Agent

**身份定义**：
```markdown
你是一位质量保证专家，专注于确保软件质量和用户体验。
你的测试全面、自动化程度高，并且能快速发现潜在问题。
```

**核心使命**：
- 端到端测试自动化
- 回归测试和冒烟测试
- 性能和负载测试
- Bug 追踪和报告

**工作流程**：
1. 测试计划和用例设计
2. 自动化测试脚本编写
3. 执行测试和结果分析
4. Bug 报告和跟踪
5. 测试报告和度量

**技术交付物**（示例）：
```javascript
// Playwright 测试示例
test('用户登录流程', async ({ page }) => {
  await page.goto('https://app.example.com/login');

  // 填写表单
  await page.fill('[name="email"]', 'user@example.com');
  await page.fill('[name="password"]', 'SecurePass123!');

  // 点击登录
  await page.click('button[type="submit"]');

  // 验证跳转
  await expect(page).toHaveURL('/dashboard');
  await expect(page.locator('h1')).toContainText('欢迎回来');
});
```

**成功指标**：
- 测试覆盖率 > 80%
- 自动化测试占比 > 70%
- Bug 发现率 > 90%（上线前）
- 测试执行时间 < 30 分钟

---

## 4. 文件格式与结构

### 4.1 Agent 定义文件结构

每个 agent 的 markdown 文件包含以下部分：

```markdown
# [Agent 名称]

## 身份 (Identity)
- 角色定义
- 个性特征
- 沟通风格

## 核心使命 (Core Mission)
- 主要职责
- 目标和价值

## 工作流程 (Workflows)
1. 步骤 1
2. 步骤 2
3. ...

## 技术交付物 (Technical Deliverables)
- 代码示例
- 文档模板
- 工具推荐

## 成功指标 (Success Metrics)
- KPI 1
- KPI 2
- ...

## 沟通风格 (Communication Style)
- 语气和用词
- 反馈方式
```

### 4.2 与 Claude Code 集成

**安装方式**：
```bash
# 复制单个 agent
cp agency-agents/engineering/frontend-developer.md ~/.claude/agents/

# 批量安装
./install.sh
```

**使用方式**：
```bash
# 在 Claude Code 中激活
@frontend-developer 帮我实现一个响应式导航栏
```

### 4.3 转换为其他工具格式

**Cursor 格式**：
```bash
./convert.sh --tool cursor --agent frontend-developer
# 生成 .mdc rule 文件
```

**Aider 格式**：
```bash
./convert.sh --tool aider --agent backend-architect
# 生成 Aider 配置
```

---

## 5. 与我们项目的对比

### 5.1 架构对比

| 维度 | The Agency | 我们的项目 | 差异 |
|------|-----------|-----------|------|
| **Agent 数量** | 142 个 | 15+ 个 | The Agency 更全面 |
| **组织方式** | 11 个部门 | 按角色分类 | 类似 |
| **文件格式** | Markdown | Markdown | 一致 |
| **领域覆盖** | 通用软件开发 | 金融证券 | 我们更专业化 |
| **合规支持** | 无 | 强（SEC/SFC） | 我们的优势 |

### 5.2 Agent 定义质量对比

**The Agency 的优势**：
- ✅ 每个 agent 有明确的个性和沟通风格
- ✅ 包含真实代码示例
- ✅ 定义了可衡量的成功指标
- ✅ 工作流程清晰

**我们项目的优势**：
- ✅ 金融领域专业化（合规、风控、审计）
- ✅ 跨境监管支持（美股/港股）
- ✅ 资金安全验证（decimal、双重记账）
- ✅ 与项目架构深度集成

---

## 6. 可借鉴的 Agent 定义

### 6.1 立即可用的 Agents

**优先级 P0**（直接复制使用）：

1. **Frontend Developer** → 用于 Admin Panel 开发
2. **Backend Architect** → 用于微服务架构设计
3. **API Specialist** → 用于 API 设计和文档
4. **Database Optimizer** → 用于 MySQL 查询优化
5. **DevOps Engineer** → 用于 CI/CD 和 Kubernetes

### 6.2 需要适配的 Agents

**优先级 P1**（需要增加金融特性）：

6. **Security Engineer** → 增加金融合规检查
   - 增加：PII 加密验证
   - 增加：资金流安全检查
   - 增加：SEC/SFC 合规验证

7. **QA Engineer** → 增加金融场景测试
   - 增加：交易流程测试
   - 增加：出入金测试
   - 增加：KYC 流程测试

8. **Data Engineer** → 增加审计日志处理
   - 增加：7 年审计日志保留
   - 增加：不可篡改验证
   - 增加：监管报告生成

### 6.3 需要新建的 Agents

**优先级 P2**（The Agency 没有，我们需要）：

9. **Compliance Officer** — 合规审查专家
   - SEC/FINRA 规则检查
   - SFC/AMLO 规则检查
   - 监管报备文档生成

10. **AML Analyst** — 反洗钱分析师
    - 交易模式分析
    - 可疑活动检测
    - CTR/SAR 报告生成

11. **Fund Transfer Specialist** — 出入金专家
    - 同名账户验证
    - AML 筛选
    - 结算周期管理

12. **Cross-Border Compliance Expert** — 跨境合规专家
    - FATCA/CRS 验证
    - 双重监管协调
    - 多时区/多货币处理

---

## 7. 实施建议

### 7.1 短期行动（1-2周）

**Step 1: 评估和选择**
```bash
# 克隆 The Agency 仓库
git clone https://github.com/msitarzewski/agency-agents.git

# 浏览 Engineering 和 Testing 部门
cd agency-agents/engineering
ls -la
```

**Step 2: 试用核心 Agents**
```bash
# 复制到 Claude Code
cp frontend-developer.md ~/.claude/agents/
cp backend-architect.md ~/.claude/agents/
cp security-engineer.md ~/.claude/agents/

# 测试使用
# 在 Claude Code 中：@frontend-developer 帮我实现一个交易订单表单
```

**Step 3: 评估效果**
- 对比通用 prompt vs agent 定义的输出质量
- 记录哪些 agents 最有用
- 识别需要适配的部分

### 7.2 中期行动（1个月）

**Step 4: 适配金融场景**

创建 `~/.claude/agents/financial-security-engineer.md`：
```markdown
# Financial Security Engineer

## 身份
你是一位金融系统安全专家，专注于证券经纪平台的安全合规。

## 核心使命
- 确保资金安全和数据保护
- 验证 SEC/FINRA/SFC 合规性
- 防范金融欺诈和洗钱

## 工作流程
1. 威胁建模（金融场景）
2. PII 加密验证
3. 资金流安全检查
4. 合规性验证
5. 渗透测试

## 技术交付物
```go
// 资金转账安全检查
func ValidateFundTransfer(transfer *FundTransfer) error {
    // 1. 同名账户验证
    if !transfer.IsSameNameAccount() {
        return errors.New("third-party transfer not allowed")
    }

    // 2. AML 筛选
    if err := aml.Screen(transfer); err != nil {
        return fmt.Errorf("AML screening failed: %w", err)
    }

    // 3. 金额精度检查
    if !transfer.Amount.IsDecimal() {
        return errors.New("amount must use decimal type")
    }

    return nil
}
```

## 成功指标
- 零资金安全事故
- 合规检查通过率 100%
- PII 加密覆盖率 100%
- 渗透测试通过率 > 95%
```

**Step 5: 创建金融专属 Agents**

参考 The Agency 的格式，创建：
- `compliance-officer.md`
- `aml-analyst.md`
- `fund-transfer-specialist.md`
- `cross-border-compliance-expert.md`

### 7.3 长期优化（3个月）

**Step 6: 建立 Agent 库**

```
.claude/agents/
├── general/              # 通用 agents（来自 The Agency）
│   ├── frontend-developer.md
│   ├── backend-architect.md
│   └── devops-engineer.md
├── financial/            # 金融专属 agents
│   ├── compliance-officer.md
│   ├── aml-analyst.md
│   └── fund-transfer-specialist.md
└── domain/               # 领域专属 agents
    ├── ams-engineer.md
    ├── trading-engineer.md
    └── market-data-engineer.md
```

**Step 7: 持续优化**
- 根据使用反馈调整 agent 定义
- 增加更多代码示例
- 完善成功指标
- 定期同步 The Agency 更新

---

## 总结

**The Agency 的核心价值**：
1. 提供了 142 个高质量的 agent 定义模板
2. 每个 agent 有明确的身份、工作流程和交付物
3. 支持多种 AI 编码工具（Claude Code、Cursor、Aider）
4. 开源且持续更新

**对我们项目的启示**：
1. ✅ 可直接使用通用开发 agents（前端、后端、DevOps）
2. ⚠️ 需要适配金融场景（增加合规、安全、资金验证）
3. ❌ 缺少金融专属 agents（需要自己创建）

**建议行动**：
- **短期**：试用 5-10 个核心 agents，评估效果
- **中期**：适配金融场景，创建专属 agents
- **长期**：建立完整的 agent 库，持续优化

**相关文档**：
- [gstack Architecture Analysis](./gstack-architecture-analysis.md) — 软件工厂架构
- [Developer AI Agents Survey](./developer-ai-agents-survey.md) — 开源项目调研
- [Product Management Research](./product-management-research.md) — PM 框架
- [`.claude/agents/`](../.claude/agents/) — 我们当前的 agents

---

**Sources**:
- [The Agency GitHub Repository](https://github.com/msitarzewski/agency-agents)
- [Medium: The Agency Analysis](https://medium.com)
- [Popular AI Tools: The Agency](https://popularaitools.ai)
- [Reddit: The Agency Discussion](https://reddit.com)
