# Spec Organization Standard — 文档组织规范

> **版本**: v2.1
> **日期**: 2026-03-13T22:45+08:00
> **适用范围**: 本仓库所有文档、规格、设计、讨论线程的创建与放置
> **维护者**: SDD Expert / Tech Lead

---

## 核心原则

### 一句话总结

> **PRD 跟着产品界面（Surface）走，技术 Spec 跟着实现者走，接口契约放中间地带。**

### 三条铁律

1. **PRD 按类型归属：Surface PRD 跟界面走，Domain PRD 跟业务域走**
   描述"用户看到什么、怎么交互"的 Surface PRD 放 `mobile/docs/prd/` 或 `admin-panel/docs/prd/`；
   描述"业务规则、领域逻辑、合规要求"的 Domain PRD 放对应后端域的 `docs/prd/`；
   一份 PRD 如果两者都重，则**拆分**为 Surface PRD + Domain PRD，双向引用。

2. **域内 Spec 不暴露到全局**
   每个服务域有自己的 `docs/` 目录，域内的技术设计、讨论线程、评审记录留在域内，只有跨域接口契约和无主合规文档放根 `docs/`。

3. **CLAUDE.md 做上下文隔离**
   每个域有自己的 CLAUDE.md，AI agent 进入该目录时只加载本域上下文 + 全局规则，不加载其他域的知识。

4. **规范必须可跨 repo 扩展**
   所有跨域引用使用逻辑标识符（URI）+ 相对路径双写；每个域导出 `domain.yaml` 自描述清单；知识分三层管理（Hot/Warm/Cold）。单 repo 阶段零成本预埋，多 repo 阶段平滑过渡。

---

## 仓库目录结构

```
repo-root/
│
├── CLAUDE.md                              # 全局路由表（<100行，只做导航）
├── .claude/
│   ├── agents/                            # 全局 agents
│   ├── rules/                             # 全局硬规则（所有域继承）
│   │   ├── financial-coding-standards.md
│   │   ├── security-compliance.md
│   │   └── fund-transfer-compliance.md
│   └── skills/                            # 全局 skills
│
├── docs/                                  # 根级：仅放【无主的跨域】文档
│   ├── SPEC-ORGANIZATION.md               # ← 本文件
│   ├── active-threads.yaml                # 全局活跃 Thread 索引
│   ├── compliance/                        # 合规要求（不属于任何 surface）
│   ├── contracts/                         # 域间接口契约
│   ├── threads/                           # 跨域协作线程
│   └── references/                        # 行业研究、竞品分析
│
├── mobile/                                # ═══ 移动端域 ═══
│   ├── CLAUDE.md
│   ├── docs/
│   │   ├── prd/                           # ★ App 侧 Surface PRD
│   │   ├── design/                        # ★ UI/UX 设计
│   │   ├── specs/                         # 移动端技术 spec
│   │   └── threads/                       # 移动端域内讨论
│   └── lib/                               # 代码...
│
├── services/
│   ├── ams/                               # ═══ AMS 域（认证/鉴权/KYC）═══
│   │   ├── CLAUDE.md
│   │   ├── docs/
│   │   │   ├── prd/                       # AMS 域 Domain PRD（业务规则）
│   │   │   ├── specs/                     # 域内技术设计
│   │   │   ├── threads/                   # 域内讨论
│   │   │   └── db/                        # 数据模型
│   │   ├── api/
│   │   │   ├── grpc/                      # .proto + .pb.go
│   │   │   └── rest/                      # openapi.yaml
│   │   └── internal/
│   │
│   ├── trading-engine/                    # ═══ 交易域（OMS/路由/风控/清结算）═══
│   │   ├── CLAUDE.md
│   │   ├── docs/
│   │   │   ├── prd/                       # 交易域 Domain PRD（业务规则）
│   │   │   ├── specs/
│   │   │   ├── threads/
│   │   │   └── db/
│   │   ├── api/
│   │   │   ├── grpc/                      # .proto + .pb.go
│   │   │   └── rest/                      # openapi.yaml
│   │   └── internal/
│   │
│   ├── fund-transfer/                     # ═══ 资金域（出入金/通道/对账）═══
│   │   ├── CLAUDE.md
│   │   ├── docs/
│   │   │   ├── prd/                       # 资金域 Domain PRD（业务规则）
│   │   │   ├── specs/
│   │   │   ├── threads/
│   │   │   └── db/
│   │   └── internal/
│   │
│   ├── market-data/                       # ═══ 行情域 ═══
│   │   ├── CLAUDE.md
│   │   ├── docs/
│   │   └── internal/
│   │
│   └── admin-panel/                       # ═══ 管理后台域 ═══
│       ├── CLAUDE.md
│       ├── docs/
│       │   ├── prd/                       # ★ 后台侧 Surface PRD
│       │   ├── specs/
│       │   └── threads/
│       └── src/
```

---

## Spec 归属决策树

当你需要创建或放置一份文档时，按以下决策树判断：

```
这个文档描述的是什么？
│
├─ 产品需求（PRD）
│   │
│   │  这份 PRD 主要描述的是...
│   │
│   ├─ 用户界面、交互流程、展示逻辑（Surface PRD）
│   │   → mobile/docs/prd/ 或 admin-panel/docs/prd/
│   │
│   ├─ 业务规则、领域逻辑、合规要求（Domain PRD）
│   │   → <service>/docs/prd/
│   │   例: 订单状态机规则 → services/trading-engine/docs/prd/
│   │   例: AML 筛查流程 → services/fund-transfer/docs/prd/
│   │
│   └─ 两者都重？
│       → 拆分！Surface PRD 只留界面相关内容，
│         业务逻辑提取为 Domain PRD 放到对应域，
│         双向用 frontmatter 引用
│
├─ "某个域如何实现需求（技术方案）"
│   │
│   ├─ 改变了对外接口？
│   │   → 该域的 docs/specs/ + 更新 docs/contracts/ 中对应契约
│   │
│   └─ 纯内部重构/优化，接口不变？
│       → 该域的 docs/specs/（不需要更新 contracts）
│
├─ "两个域之间怎么交互（接口、协议、数据格式）"
│   → docs/contracts/
│
├─ "全公司的合规/安全基线（不绑定某个 surface）"
│   → docs/compliance/（文档）或 .claude/rules/（AI 强制规则）
│
├─ "UI/UX 设计稿、设计系统、交互规格"
│   → mobile/docs/design/
│
└─ "关于某个问题的多方讨论"
    → 见下方 Thread 归属规则
```

---

## PRD 拆分规范：Surface PRD vs Domain PRD

### 为什么要拆分

大部分功能模块的 PRD 天然包含两种内容：

| 类型 | 描述 | 关心者 | 例子 |
|------|------|--------|------|
| **Surface PRD** | 用户看到什么、点什么、交互流程、展示格式 | 前端工程师 | 下单界面布局、订单列表样式、错误提示文案 |
| **Domain PRD** | 业务规则、领域逻辑、合规要求、状态机 | 后端工程师 | 订单状态转换矩阵、PDT 计算规则、T+1 清结算 |

如果混在一起，会导致：
- Mobile 工程师的上下文被 10 页清结算逻辑污染
- 后端工程师要去 mobile 目录找自己的业务规则
- AI agent 加载了大量无关内容

### 拆分判断标准

对 PRD 里的每个章节问：**"Mobile 工程师需要读这段吗？"**

| 内容 | Mobile 需要？ | 归属 |
|------|-------------|------|
| 下单界面布局、输入校验提示 | 需要 | Surface PRD (mobile) |
| 订单类型说明（限价/市价/止损）及选项 | 需要 | Surface PRD (mobile) |
| 订单状态枚举和标签文案 | 需要 | Surface PRD (mobile) |
| 状态机完整转换矩阵及触发条件 | **不需要** | Domain PRD (trading) |
| PDT 规则计算逻辑 | **不需要** | Domain PRD (trading) |
| 风控拒单错误码→文案映射表 | 需要 | Surface PRD (mobile) |
| 风控规则的判断逻辑和阈值 | **不需要** | Domain PRD (trading) |
| T+1/T+2 清结算规则 | **不需要** | Domain PRD (trading) |
| "可用余额"的计算公式 | **不需要** | Domain PRD (fund-transfer) |
| "可用余额"在界面上的显示位置和格式 | 需要 | Surface PRD (mobile) |

### 拆分后的文件示例（以交易模块为例）

```
mobile/docs/prd/
  04-trading.md                    # Surface PRD
                                   # 下单界面、订单列表、状态标签、
                                   # 错误提示文案、交互动效
                                   # 业务规则 → 引用 Domain PRD

services/trading-engine/docs/prd/
  order-lifecycle.md               # Domain PRD：订单状态机、
                                   # 订单类型规则、有效期规则
  risk-rules.md                    # Domain PRD：PDT、Reg SHO、
                                   # 持仓集中度、买入力检查
  settlement.md                    # Domain PRD：T+1/T+2 清结算、
                                   # 未结算资金冻结规则
```

### 双向引用格式

**Surface PRD 引用 Domain PRD：**

```markdown
# mobile/docs/prd/04-trading.md
---
type: surface-prd
domain_prd:
  - services/trading-engine/docs/prd/order-lifecycle.md
  - services/trading-engine/docs/prd/risk-rules.md
---

## 订单状态展示
用户在订单列表中看到以下状态标签：
- 待提交 / 已提交 / 部分成交 / 全部成交 / 已撤单 / 已拒绝

> 状态定义及完整转换规则见 [订单生命周期](../../../services/trading-engine/docs/prd/order-lifecycle.md)

## 风控拒单提示
| 错误码 | 用户看到的提示 |
|--------|-------------|
| RISK_PDT | "您的账户已触发日内交易限制，详情请查看规则说明" |
| RISK_BUYING_POWER | "可用资金不足，请入金后重试" |

> 风控规则逻辑详见 [风控规则](../../../services/trading-engine/docs/prd/risk-rules.md)
```

**Domain PRD 引用 Surface PRD：**

```markdown
# services/trading-engine/docs/prd/order-lifecycle.md
---
type: domain-prd
surface_prd: mobile/docs/prd/04-trading.md
---

# 订单生命周期（业务规则）

> 用户侧界面展示见 [交易 Surface PRD](../../../../mobile/docs/prd/04-trading.md)

## 订单状态转换矩阵
| 当前状态 | 事件 | 目标状态 | 条件 |
|---------|------|---------|------|
| PENDING | submit | SUBMITTED | 通过预交易风控 |
| PENDING | submit | REJECTED | 风控拒绝 |
| SUBMITTED | exchange_ack | OPEN | 交易所接受 |
| OPEN | fill | PARTIALLY_FILLED | 部分成交 |
| ... | ... | ... | ... |
```

### 不需要拆分的情况

如果一份 PRD 的业务逻辑很轻（例如"设置页面"、"个人资料页"），没有复杂的后端规则，则**不需要拆分**，整体放在 Surface 侧即可。

判断标准：如果 Domain 部分不超过该 PRD 总篇幅的 20%，可以不拆，用一个小节简述业务规则即可。

---

## Thread（协作线程）完整规范

Thread 是多角色之间围绕一个主题的异步讨论。

### 归属规则

归属原则：**Thread 放在讨论对象所在的域。**

| 场景 | 放置位置 | 例子 |
|------|---------|------|
| 后端评审 App PRD | `mobile/docs/threads/` | 交易组对 PRD-04 提出 6 个问题 |
| 后端评审 Admin PRD | `services/admin-panel/docs/threads/` | 前端组对后台 PRD 的反馈 |
| 域内纯技术讨论 | `<service>/docs/threads/` | 交易引擎内部是否拆微服务 |
| 涉及多域的架构讨论 | `docs/threads/` | Admin Panel 整体范围定义 |
| 域间接口变更讨论 | `docs/threads/` | 清结算→资金划转的接口重新设计 |

### Thread 生命周期

```
                ┌─────────────┐
                │    OPEN     │  有人提出问题/议题
                └──────┬──────┘
                       │
                ┌──────▼──────┐
                │  IN_REVIEW  │  相关方正在讨论
                └──────┬──────┘
                       │
                ┌──────▼──────┐
                │  RESOLVED   │  决策已达成，但规格尚未同步
                └──────┬──────┘
                       │ 相关方更新受影响的规格文件
                ┌──────▼──────┐
                │INCORPORATED │  所有受影响的规格已实际更新
                └──────┬──────┘   （记录 commit hash）
                       │
                ┌──────▼──────┐
                │   FROZEN    │  永久冻结，不可追加消息
                └─────────────┘
                       │
                  新问题？→ 开新 Thread，用 continues 关联
```

**关键区分**：
- `RESOLVED` = 决策已达成，但 PRD/Spec/Design 文件**尚未更新**
- `INCORPORATED` = 所有 `affects_specs` 中的文件**已实际修改**并提交

一个 Thread **不应**长时间停留在 RESOLVED 状态。决策达成后应尽快更新规格并推进到 INCORPORATED。

### 重量级 Thread vs 轻量级决策记录

AI 推进开发速度极快，不是所有讨论都需要完整的 Thread 目录结构。按讨论复杂度选择格式：

| 模式 | 适用场景 | 格式 | 文件数 |
|------|---------|------|--------|
| **重量级 Thread** | 跨域决策、合规问题、架构变更、3+ 角色参与 | 独立目录 + 每条消息一个文件 | 3-8 个文件 |
| **轻量级决策记录** | 快速澄清、域内确认、1-3 轮预期 | 单个 .md 文件 | 1 个文件 |

**判断标准**：

```
参与方 > 3 个角色？              → 重量级
涉及合规/安全/架构决策？          → 重量级
预计讨论 > 5 轮？               → 重量级
快速澄清，预计 1-3 轮？          → 轻量级
域内确认，不影响其他域？          → 轻量级
```

### 重量级 Thread 格式

#### 目录结构

```
<域>/docs/threads/
  2026-03-prd-tech-review/
    _index.md                    # 线程元数据 + 状态
    01-trading-engine-review.md  # 交易组提出问题
    02-fund-transfer-review.md   # 资金组提出问题
    03-pm-decision.md            # PM 逐项回复
    04-design-update.md          # 设计师确认落实
```

#### _index.md 格式

```markdown
---
thread: prd-04-tech-review
type: heavyweight
status: INCORPORATED             # OPEN | IN_REVIEW | RESOLVED | INCORPORATED | FROZEN | DEFERRED
priority: P0
opened_by: trading-engine-engineer
opened_date: 2026-03-11T14:30+08:00
resolved_date: 2026-03-12T09:15+08:00
incorporated_date: 2026-03-12T11:00+08:00
participants:
  - trading-engine-engineer
  - fund-transfer-engineer
  - product-manager
  - ui-designer
requires_input_from: []          # 当前等待谁的输入（空 = 不等待）
affects_specs:
  - mobile/docs/prd/04-trading.md
  - mobile/docs/design/mobile-app-design.md
resolution: "PDT 改硬拦截；Margin 推 Phase 2；入金增加 AML 状态节点"
incorporated_commits:
  - hash: a1b2c3d
    files: [mobile/docs/prd/04-trading.md, mobile/docs/design/mobile-app-design.md]
continues: null                  # 如果是续篇，填前序 Thread 的目录名
continued_by: 2026-03-design-v3-post-review  # 如果有后续，填后续 Thread 的目录名
---

# PRD-04 交易模块技术评审

## 对话摘要
1. **交易组提出** (01): 6 项 CRITICAL，含 PDT 开关违规、Margin 缺失
2. **资金组提出** (02): AML 筛查节点缺失、Travel Rule 信息收集
3. **PM 决策** (03): 逐项回复，Margin 推 Phase 2
4. **设计落实** (04): 已从设计稿移除 PDT 开关
```

#### 单条消息格式

```markdown
---
seq: 01
author_role: trading-engine-engineer
date: 2026-03-11T14:30+08:00
action: RAISE_ISSUE             # RAISE_ISSUE | DECISION | FEEDBACK | SIGN_OFF | UPDATE
---

# 交易域技术评审意见

## CRITICAL-1: PDT 限制不能做成可关闭的开关
...

## 需要回复方
- [ ] product-manager: 确认是否删除 PDT 开关
- [ ] ui-designer: 评估设计影响
```

### 轻量级决策记录格式

单个 .md 文件，用 `@角色 时间戳` 标记每条发言：

```markdown
# <域>/docs/threads/2026-03-partial-fill-quick.md
---
thread: partial-fill-clarification
type: lightweight
status: INCORPORATED
priority: P1
opened_date: 2026-03-12T14:00+08:00
incorporated_date: 2026-03-12T14:30+08:00
participants: [trading-engine-engineer, product-manager]
affects_specs:
  - path: services/trading-engine/docs/prd/order-lifecycle.md
---

## 问题
@trading-engine-engineer 2026-03-12T14:00+08:00
部分成交后，剩余数量的订单状态是 OPEN 还是 PARTIALLY_FILLED？PRD 中两处描述矛盾。

## 回复
@product-manager 2026-03-12T14:15+08:00
状态应为 PARTIALLY_FILLED。OPEN 仅表示"已被交易所接受且未有任何成交"。

## 决策
保持 PARTIALLY_FILLED 直到全部成交或被撤单。PRD 第 3.2 节的描述有误，以第 4.1 节为准。已更新 order-lifecycle.md。
```

### Thread 冻结与续篇规则

**规则：INCORPORATED 状态的 Thread 自动进入 FROZEN，永久不可追加消息。**

如果后续出现关于同一主题的新问题：

1. 创建新 Thread
2. 新 Thread 的 `continues` 字段填写前序 Thread 的目录名
3. 前序 Thread 的 `continued_by` 字段更新为新 Thread 的目录名

```yaml
# 新 Thread: 2026-03-design-v3-post-review/_index.md
---
thread: design-v3-post-review
continues: 2026-03-prd-04-review           # ← 关联前序
context: "PM 已决策删除 PDT 开关，设计师已更新稿件，但交易工程师发现更新后的设计仍有 2 个问题"
---
```

### 跨域参与者路由

当域内 Thread 需要其他域角色参与时，使用 `requires_input_from` 字段：

```yaml
# services/trading-engine/docs/threads/2026-03-partial-fill/_index.md
---
status: OPEN
requires_input_from:
  - product-manager              # 需要 PM 来澄清业务规则
  - fund-transfer-engineer       # 部分成交影响资金结算
---
```

同时在根目录维护**活跃 Thread 索引**（手动维护或 CI 自动生成）：

```yaml
# docs/active-threads.yaml
threads:
  - path: services/trading-engine/docs/threads/2026-03-partial-fill/
    status: OPEN
    requires: [product-manager, fund-transfer-engineer]
    priority: P0
    summary: "Domain PRD 对部分成交后的订单状态描述歧义"

  - path: mobile/docs/threads/2026-03-design-v3-post-review/
    status: IN_REVIEW
    requires: [product-manager]
    priority: P1
    summary: "设计稿更新后交易工程师发现 2 个新问题"
```

AI orchestrator 在路由任务时先读 `active-threads.yaml`，即可知道哪些讨论在等谁的输入。

---

## 规格文件变更追踪（Revision Log）

规格文件（PRD、Tech Spec）在 frontmatter 中记录变更历史，关联到触发变更的 Thread：

```yaml
# mobile/docs/prd/04-trading.md
---
type: surface-prd
revisions:
  - rev: 3
    date: 2026-03-12T14:30+08:00
    author: product-manager
    thread: services/trading-engine/docs/threads/2026-03-partial-fill-quick.md
    summary: "澄清部分成交后的订单状态展示逻辑"
  - rev: 2
    date: 2026-03-11T16:00+08:00
    author: product-manager
    thread: mobile/docs/threads/2026-03-prd-04-review/
    summary: "删除 PDT 开关；Margin 推 Phase 2；入金增加 AML 状态"
  - rev: 1
    date: 2026-03-10T09:00+08:00
    author: product-manager
    summary: "初始版本"
domain_prd:
  - services/trading-engine/docs/prd/order-lifecycle.md
---
```

**规则**：
- 每次因 Thread 决策而修改规格时，必须在 `revisions` 中追加一条记录
- `thread` 字段关联到触发变更的 Thread（可以是重量级目录或轻量级文件）
- 小的 typo 修复或格式调整不需要记录 revision
- 纯新建文档只需 rev: 1

---

## 技术 Spec 引用规范

每个技术 Spec 在头部用 frontmatter 声明与上游需求和跨域接口的关系：

```markdown
---
implements:                                       # 我实现的是哪些 PRD
  - mobile/docs/prd/04-trading.md                 # Surface PRD（界面需求）
  - services/trading-engine/docs/prd/order-lifecycle.md  # Domain PRD（业务规则）
contracts:
  - docs/contracts/trading-to-fund.md             # 我对外暴露的接口契约
depends_on:
  - services/ams/api/grpc/ams.proto                # 我依赖谁的接口
  - services/market-data/api/grpc/market.proto
---

# 订单状态机技术设计

本文档是 [交易 PRD](../../../mobile/docs/prd/04-trading.md) 中订单生命周期的技术实现方案。
```

### 引用规则

- 使用**相对路径**引用其他文档（保证 git 内可跳转）
- `implements` 指向上游 PRD（Source of Truth）
- `contracts` 指向本域对外暴露的接口契约
- `depends_on` 指向本域消费的外部接口
- 引用关系仅在 frontmatter 中声明，正文中用超链接辅助阅读

---

## 跨域接口契约（docs/contracts/）

接口契约是两个域之间的"合同"，由双方共同维护。

### 契约文件命名

```
<提供方>-to-<消费方>.md

例:
  ams-to-trading.md         # AMS 提供鉴权能力给交易域
  trading-to-fund.md        # 交易域发起清结算资金划转到资金域
  market-to-mobile.md       # 行情域推送数据给移动端
```

### 契约文件格式

```markdown
---
provider: services/ams
consumer: services/trading-engine
protocol: gRPC
proto_file: services/ams/api/grpc/ams.proto
last_reviewed: 2026-03-13T15:00+08:00
---

# AMS → Trading Engine 接口契约

## 契约范围
交易域下单前需要调用 AMS 验证用户身份和账户状态。

## 接口列表
| 方法 | 用途 | SLA |
|------|------|-----|
| VerifySession | 验证用户 session | < 10ms |
| GetAccountStatus | 获取账户交易权限 | < 20ms |

## 变更流程
任何接口变更需双方在 docs/threads/ 中开 thread 讨论后方可修改。
```

### 契约版本管理

Contract 文件**始终反映当前态**（Single Source of Truth），不拆 v1/v2 文件。版本通过文件内的 `version` 字段和 changelog 追踪。

实际的 API 版本化由代码制品（proto 字段编号、OpenAPI 版本号）处理，contract 文件记录的是**协议层面的变更历史**。

**带版本的 contract 格式：**

```markdown
---
provider: services/trading-engine
consumer: services/fund-transfer
protocol: gRPC
proto_file: services/trading-engine/api/grpc/settlement.proto
version: 3
last_updated: 2026-05-20T16:30+08:00
last_reviewed: 2026-05-20T16:30+08:00
---

# Trading → Fund Transfer 接口契约

## 当前接口列表

| 方法 | 用途 | 版本引入 | SLA |
|------|------|---------|-----|
| InitiateSettlement | 发起清结算资金划转 | v1 | < 200ms |
| QuerySettlementStatus | 查询划转状态 | v1 | < 50ms |
| BatchSettlement | 批量清结算（日终） | v2 | < 5s |
| CancelSettlement | 撤销未完成的划转 | v3 | < 100ms |

## 变更日志

### v3 — 2026-05-20T16:30+08:00
- **新增** `CancelSettlement` 方法
- **触发 PRD**: [出金撤回流程](../../mobile/docs/prd/05-funding.md#withdrawal-cancel)
- **讨论 Thread**: [docs/threads/2026-05-settlement-cancel/]
- **Proto 变更**: settlement.proto 新增 `CancelSettlementRequest/Response`
- **向后兼容**: 是（新增方法，不影响现有接口）

### v2 — 2026-04-10T11:20+08:00
- **新增** `BatchSettlement` 方法
- **触发 PRD**: [日终批量清结算](../prd/settlement.md#batch)
- **向后兼容**: 是

### v1 — 2026-03-15T09:00+08:00
- 初始版本：`InitiateSettlement`, `QuerySettlementStatus`
```

**变更日志每条必须包含：**
- 变更内容（新增/修改/废弃/删除）
- 触发来源（PRD 链接或 Thread 链接）
- 向后兼容性说明

**破坏性变更额外需要：**
- 迁移计划（deprecated 日期 → 下线日期）
- 消费方影响说明
- 过渡期内双版本并行方案

### PRD 变更触发 contract 更新的工作流

```
PRD 变更（产品提出需求）
  │
  ├─ 不影响接口？→ 只改域内 spec，contract 不动
  │
  └─ 影响接口？
      │
      ▼
  开 Thread（在 docs/threads/）
      │
      ├─ 提供方评估：能做吗？向后兼容吗？SLA 影响？
      ├─ 消费方评估：需要改调用方代码吗？
      └─ 双方达成一致
          │
          ▼
  更新制品（并行）
      ├─ api/grpc/ 或 api/rest/：加新字段/方法
      ├─ contract 文件：version +1，更新接口列表，写 changelog
      └─ Thread 标记 RESOLVED
```

### 契约索引与全景图（docs/contracts/INDEX.md）

契约目录包含一个 `INDEX.md`，承担**系统全景图**角色：

- **服务拓扑图** — ASCII 依赖关系图，让非技术人员一眼看懂系统结构
- **契约索引表** — 所有 provider→consumer 关系、协议、状态的汇总
- **依赖规则** — DAG 无环约束、根节点约定、纯消费者标识

**INDEX.md 的维护时机：**

| 触发事件 | 更新动作 |
|---------|---------|
| 新增服务间依赖 | 创建契约文件 + INDEX 表格加行 + 拓扑图加边 |
| 移除依赖 | 契约状态改 DEPRECATED + INDEX 标注 + 拓扑图删边 |
| 新增服务域 | INDEX 拓扑图加节点 + 相关契约文件 |
| 服务拆分 repo | INDEX 标注 repo 归属，契约加 `mirror: true` 标记 |

### 契约演进治理

契约不是静态文档，系统关联关系会随业务演进而变化。SDD 流程必须跟踪这种变化：

**1. 定期健康检查（SDD Expert 驱动）**

```
每次 SDD 审计（/sdd audit）时：
  ├─ 检查 INDEX.md 拓扑图是否与各域 CLAUDE.md 的上下游依赖一致
  ├─ 检查每个 DRAFT 契约是否仍需要（可能设计变更后依赖不存在了）
  ├─ 检查每个 ACTIVE 契约的 proto/openapi 文件是否实际存在
  └─ 输出：契约健康报告（缺失、过期、不一致的契约列表）
```

**2. 新功能驱动的契约变更**

```
新功能 PRD
  │
  ├─ 需要新的跨域依赖？
  │   → 创建新契约 (DRAFT) + 更新 INDEX
  │
  ├─ 修改现有跨域接口？
  │   → 更新契约 (version +1) + changelog + INDEX 状态
  │
  └─ 移除跨域依赖？
      → 契约标记 DEPRECATED + INDEX 更新
```

**3. 服务拆分驱动的契约迁移**

当域从 monorepo 拆出独立 repo 时（Phase 2-3）：
- Provider 域的契约**原件**搬入新 repo 的 `docs/contracts/`
- 原 monorepo 保留**镜像副本**，frontmatter 加 `mirror: true`
- INDEX.md 标注每个契约的 repo 归属
- CI 自动同步 provider repo 的契约变更到 consumer repo

---

## 三层 CLAUDE.md 设计

### Layer 0: 根 CLAUDE.md（全局路由）

```markdown
# Brokerage Trading App

## 域导航
| 域 | 路径 | 职责 | Surface PRD | Domain PRD |
|----|------|------|------------|------------|
| Mobile | mobile/ | Flutter 客户端 | mobile/docs/prd/ | — |
| AMS | services/ams/ | 认证/鉴权/KYC | 引用 mobile/docs/prd/01,02 | services/ams/docs/prd/ |
| Trading | services/trading-engine/ | 订单/路由/风控/清结算 | 引用 mobile/docs/prd/04 | services/trading-engine/docs/prd/ |
| Fund | services/fund-transfer/ | 出入金/通道/对账 | 引用 mobile/docs/prd/05 | services/fund-transfer/docs/prd/ |
| Market | services/market-data/ | 行情采集/分发/缓存 | 引用 mobile/docs/prd/03 | services/market-data/docs/prd/ |
| Admin | services/admin-panel/ | 运营后台 | services/admin-panel/docs/prd/ | — |

## 跨域接口契约 → docs/contracts/
## 全局编码标准 → .claude/rules/
## 文档组织规范 → docs/SPEC-ORGANIZATION.md
```

- 不超过 100 行
- 不包含任何具体业务知识
- 只做导航和路由

### Layer 1: 域 CLAUDE.md（域上下文入口）

```markdown
# Trading Engine Service

## 职责
订单管理(OMS)、智能路由(SOR)、预交易风控、清结算

## Domain PRD 索引（本域业务规则）
- 订单生命周期: docs/prd/order-lifecycle.md
- 风控规则: docs/prd/risk-rules.md
- 清结算规则: docs/prd/settlement.md

## Spec 索引（技术实现方案）
- 订单状态机: docs/specs/order-state-machine.md
- 智能路由: docs/specs/smart-order-routing.md
- 风控检查: docs/specs/risk-checks.md

## 上游需求（Surface PRD）
- App 交易界面: mobile/docs/prd/04-trading.md

## 上下游依赖
- ← AMS: 鉴权 (proto: services/ams/api/grpc/ams.proto)
- ← Market: 实时报价 (proto: services/market-data/api/grpc/market.proto)
- → Fund: 清结算划转 (contract: docs/contracts/trading-to-fund.md)

## 数据模型
核心表: orders, positions, executions, settlements
详见: docs/db/schema-overview.md
```

- 约 50-80 行
- 包含本域的完整知识索引
- 明确声明上游 PRD 和跨域依赖

### 上下文加载效果

| 工作目录 | 加载的 CLAUDE.md | 加载的 rules | 预估 tokens |
|---------|-----------------|-------------|------------|
| `repo-root/` | 根 | 全局 rules | ~2K |
| `services/trading-engine/` | 根 + 交易域 | 全局 rules | ~3K |
| `mobile/` | 根 + 移动端域 | 全局 rules | ~3K |

其他域的 spec 完全不进入上下文。需要时由 agent 主动查阅。

---

## 跨域知识发现顺序

当域内 agent 需要了解其他域时，按优先级查找：

```
1. 先查本域 CLAUDE.md 中的"上下游依赖"  → 有没有直接指引
2. 再查 docs/contracts/                  → 有没有现成的接口契约
3. 再查目标域的 api/grpc/                   → gRPC 接口定义（代码即文档）
4. 最后才读目标域的 docs/specs/           → 理解实现细节
```

**不要**直接读其他域的全部 docs/，而是按需精准查阅。

---

## 时间戳规范

本项目由 AI agent 推进开发，同一天内可能产生大量文档变更。所有时间戳**精确到分钟级别**，使用 ISO 8601 格式带时区偏移。

### 格式

```
YYYY-MM-DDTHH:MM+08:00      （北京时间）
YYYY-MM-DDTHH:MMZ           （UTC）

例: 2026-03-13T14:30+08:00
例: 2026-03-13T06:30Z
```

### 适用场景

| 场景 | 字段 | 精度 |
|------|------|------|
| Thread _index.md | `opened_date`, `resolved_date` | 分钟 |
| Thread 消息 | `date` | 分钟 |
| Contract | `last_updated`, `last_reviewed` | 分钟 |
| Contract changelog | 版本标题中的时间 | 分钟 |
| PRD/Spec frontmatter | `created`, `updated`（如使用） | 分钟 |

### 注意事项

- 优先使用带时区偏移的本地时间（`+08:00`），避免歧义
- AI agent 生成的文档应自动使用当前时间（不要用占位符）
- Thread 目录名中的日期保持 `YYYY-MM` 级别即可（目录名无需精确到分钟）

---

## 文档命名规范

| 文档类型 | 命名格式 | 例子 |
|---------|---------|------|
| Surface PRD | `<序号>-<模块>.md` | `04-trading.md` |
| Domain PRD | `<主题>.md`（kebab-case） | `order-lifecycle.md`, `risk-rules.md` |
| 技术 Spec | `<主题>.md`（kebab-case） | `order-state-machine.md` |
| 接口契约 | `<提供方>-to-<消费方>.md` | `trading-to-fund.md` |
| Thread 目录 | `<年月>-<主题>/` | `2026-03-pdt-hard-block/` |
| Thread 消息 | `<序号>-<动作>.md` | `01-tech-raise.md` |
| DB Schema | `schema-overview.md` | — |
| 设计文档 | `<主题>.md` | `mobile-app-design.md` |

---

## 多 Repo 扩展性设计

本章定义了当单 repo 无法容纳所有域时，规范如何平滑过渡到多 repo 架构。所有扩展点在单 repo 阶段**零成本预埋**。

### 逻辑标识符（Logical URI）

所有跨域引用采用 **URI + 路径双写**，确保单 repo 和多 repo 都能工作：

```yaml
# 技术 Spec 的 frontmatter
implements:
  - path: mobile/docs/prd/04-trading.md                        # 人类阅读 + git 跳转
    uri: brokerage://mobile/prd/04-trading                     # 工具解析 + 跨 repo
  - path: services/trading-engine/docs/prd/order-lifecycle.md
    uri: brokerage://trading-engine/prd/order-lifecycle
contracts:
  - path: docs/contracts/trading-to-fund.md
    uri: brokerage://contracts/trading-to-fund
```

**URI 格式**：`<namespace>://<domain>/<doc-type>/<doc-name>`

| 阶段 | `brokerage://trading-engine/prd/order-lifecycle` 解析为 |
|------|------------------------------------------------------|
| 单 repo | `services/trading-engine/docs/prd/order-lifecycle.md`（直接拼路径） |
| 多 repo | `https://github.com/org/trading-engine/blob/main/docs/prd/order-lifecycle.md`（查 registry） |

**规则**：
- `path` 字段在单 repo 阶段是主要使用方式，多 repo 阶段退化为 repo 内路径
- `uri` 字段在单 repo 阶段可选（建议预埋），多 repo 阶段必填
- 当只有 `path` 没有 `uri` 时，解析器假定在同一 repo 内

### 域自描述清单（domain.yaml）

每个域在根目录维护一份 `domain.yaml`，作为该域的机器可读名片：

```yaml
# services/trading-engine/domain.yaml
domain: trading-engine
namespace: brokerage
description: "订单管理(OMS)、智能路由(SOR)、预交易风控、清结算"
owner: trading-team
repo: brokerage-trading-app                  # 多 repo 后改为独立 repo 名

knowledge:
  claude_md: CLAUDE.md
  domain_prd:
    - uri: brokerage://trading-engine/prd/order-lifecycle
      path: docs/prd/order-lifecycle.md
    - uri: brokerage://trading-engine/prd/risk-rules
      path: docs/prd/risk-rules.md
  specs:
    - docs/specs/order-state-machine.md
    - docs/specs/smart-order-routing.md
  db_schema: docs/db/schema-overview.md

contracts:
  provides:
    - uri: brokerage://contracts/trading-to-fund
      proto: api/grpc/settlement.proto
    - uri: brokerage://contracts/trading-to-mobile
      proto: api/grpc/trading.proto
  consumes:
    - uri: brokerage://contracts/ams-to-trading
    - uri: brokerage://contracts/market-to-trading

dependencies:
  surface_prd:
    - uri: brokerage://mobile/prd/04-trading
  upstream: [ams, market-data]
  downstream: [fund-transfer, mobile, admin-panel]
```

**用途**：
- **单 repo 阶段**：AI agent 读 `domain.yaml` 即可了解本域全貌，不需要逐个文件搜索
- **多 repo 阶段**：中央 registry 聚合所有 repo 的 `domain.yaml`，构建全局服务地图
- **替代根 CLAUDE.md 中的路由表**：根 CLAUDE.md 可以自动从各域的 `domain.yaml` 生成路由表

### 三层知识架构（Hot / Warm / Cold）

参考 Codified Context 论文（知识/代码比 ≈ 24%），将域内知识显式分为三层：

```markdown
# Trading Engine — CLAUDE.md

## [HOT] 始终加载（进入本域自动在 AI 上下文中）
- 本文件（CLAUDE.md，<200 行）
- 全局规则（.claude/rules/*）
总预算: < 3K tokens

## [WARM] 按需加载（处理相关任务时主动读取）
- Domain PRD: docs/prd/*.md
- Tech Specs: docs/specs/*.md
- DB Schema: docs/db/schema-overview.md
- 活跃 Thread: docs/threads/（status=OPEN）
规则: 单次加载 < 5 个文件

## [COLD] 深度参考（仅在深入分析时检索）
- 已关闭 Thread: docs/threads/（status=RESOLVED）
- 行业研究: <root>/docs/references/
- 合规基线: <root>/docs/compliance/
- 其他域的 docs/（通过 domain.yaml 发现后定向读取）
规则: 按需逐个文件读取，不批量加载
```

**知识预算参考**：

| 层级 | 行数预算 | Token 预算 | 加载时机 |
|------|---------|-----------|---------|
| Hot | < 200 行 | < 1K | 始终 |
| Warm | 按需 | 单次 < 10K | Agent 处理任务时 |
| Cold | 无限 | 按需 | Agent 遇到陌生问题时 |

### Contract 跨 repo 归属规则

当 repo 拆分后，contract 文件的归属遵循：**provider 持有原件，consumer 持有副本**。

| 阶段 | contract 位置 | 同步机制 |
|------|-------------|---------|
| 单 repo | `docs/contracts/` 统一目录 | 不需要同步 |
| 混合 repo | provider repo 的 `docs/contracts/` | CI 检查 hash，变更时自动创建 consumer PR |
| 完全多 repo | 每个 provider repo 各自持有 | CI 同步 + 中央 registry 索引 |

在 contract frontmatter 中预埋归属信息：

```yaml
---
provider: services/trading-engine     # owner of this contract
consumer: services/fund-transfer
sync_strategy: provider-owns          # provider-owns | shared-repo
---
```

### 多 Repo 演进路径

```
Phase 1: 单 Repo（当前）
  ├── 所有域在一个 repo
  ├── 相对路径直接可用
  ├── domain.yaml 作为索引（预埋）
  ├── contracts/ 在根目录
  └── CLAUDE.md 三层标注

Phase 2: 混合态（部分域拆出）
  ├── 高频迭代的域（如 trading-engine）拆成独立 repo
  ├── 原 repo 保留 contracts/ 中对应文件（标记为 mirror）
  ├── 拆出的 repo 持有 domain.yaml + contract 原件
  ├── CI 自动同步 contract
  ├── URI 开始替代 path 用于跨 repo 引用
  └── 其他域仍在单 repo 内

Phase 3: 完全多 Repo
  ├── 每个域独立 repo + domain.yaml
  ├── 中央 registry repo 聚合所有 domain.yaml
  ├── contracts/ 归 provider repo
  ├── IDP（如 Backstage）做可视化发现层
  ├── URI 是跨 repo 的唯一标识
  └── path 退化为 repo 内使用
```

### 迁移检查清单（域拆出独立 repo 时）

- [ ] 域目录完整搬出（docs/, api/, internal/, migrations/）
- [ ] CLAUDE.md 更新：移除对根目录的相对路径依赖，改为 URI 或独立引用
- [ ] domain.yaml 更新：`repo` 字段改为新 repo 名
- [ ] 所有 frontmatter 中的 `path` 字段更新为 repo 内路径
- [ ] contract 原件搬入新 repo，原 repo 的副本标记为 `mirror: true`
- [ ] CI 配置 contract 同步 job
- [ ] 中央 registry 注册新 repo 的 domain.yaml
- [ ] 验证：其他域的 agent 能否通过 URI 发现并读取新 repo 的知识

---

## FAQ

### Q: 一个 PRD 模块既有 UI 内容又有重业务逻辑，怎么办？
A: **拆分**。UI/交互/展示部分作为 Surface PRD 留在 `mobile/docs/prd/`，业务规则/状态机/合规逻辑提取为 Domain PRD 放到对应后端域的 `docs/prd/`，双向用 frontmatter 引用。判断标准：对每段内容问"Mobile 工程师需要读吗？"，不需要的就属于 Domain PRD。

### Q: 如果业务逻辑很轻，还需要拆分吗？
A: 不需要。如果 Domain 部分不超过 PRD 总篇幅的 20%，可以不拆，用一个小节简述业务规则即可，整体放 Surface 侧。

### Q: Domain PRD 和技术 Spec (docs/specs/) 的区别是什么？
A: **Domain PRD** 是产品经理写的业务规则（"订单在什么条件下从 OPEN 变为 REJECTED"），用业务语言描述。**Tech Spec** 是工程师写的实现方案（"用 PostgreSQL 状态机 + Kafka 事件驱动实现订单状态转换"），用技术语言描述。Domain PRD 是 Tech Spec 的上游输入。

### Q: Admin Panel 的 PRD 和 App 的 PRD 有重叠怎么办？
A: Admin PRD 引用 App PRD 或 Domain PRD，不复制。例如 `admin-panel/docs/prd/order-monitoring.md` 中写"订单状态定义见 `services/trading-engine/docs/prd/order-lifecycle.md`"。

### Q: 设计师的评审意见发给 PM，属于哪个域的 thread？
A: 评审对象是 App 设计 → 放 `mobile/docs/threads/`。

### Q: 某个域内部重构不影响接口，需要通知其他域吗？
A: 不需要。Spec 和 thread 都留在域内 `docs/specs/` 和 `docs/threads/`，不更新 `docs/contracts/`。

### Q: 合规要求（如 AML 规则）放哪？
A: 如果是全局性的合规基线 → `docs/compliance/` 或 `.claude/rules/`。如果是某域对合规要求的具体业务规则 → 该域的 `docs/prd/`。如果是某域对合规要求的技术实现方案 → 该域的 `docs/specs/`。

### Q: Thread RESOLVED 后谁负责更新规格文件？
A: 原则上由 `affects_specs` 中文件的 owner 负责。PRD 由 PM 更新，设计稿由设计师更新，Tech Spec 由对应工程师更新。更新完毕后将 Thread 状态推进到 INCORPORATED 并记录 commit hash。

### Q: INCORPORATED 之后又发现新问题怎么办？
A: 开新 Thread，用 `continues` 字段关联前序。不要重开已冻结的 Thread。新 Thread 的 `context` 字段简述前序讨论的结论，避免参与者需要回翻完整历史。

### Q: 什么时候用轻量级决策记录 vs 重量级 Thread？
A: 参与方 ≤ 2 个角色、预计 1-3 轮讨论、不涉及合规/架构 → 轻量级。其他情况 → 重量级。如果轻量级讨论超过 5 轮，应升级为重量级 Thread 目录。

### Q: active-threads.yaml 需要实时维护吗？
A: 不需要实时。建议在开新 Thread 和关闭 Thread 时同步更新。可以用 CI 脚本自动扫描所有 `_index.md` 中 status=OPEN/IN_REVIEW 的 Thread 来生成。

### Q: 能不能在域的 docs/ 下再建子目录细分？
A: 可以，按需扩展。例如交易域如果拆出风控子域：`services/trading-engine/docs/prd/risk/`。但不要过度细分——如果文件数 < 5，一个 `prd/` 目录足够。

### Q: domain.yaml 在单 repo 阶段是否必须创建？
A: 建议创建但不强制。它的价值是让 AI agent 快速了解一个域的全貌而不需要逐个文件搜索。如果域的文件数量少（< 10 个 spec），CLAUDE.md 的手动索引已足够。

### Q: URI 在单 repo 阶段怎么解析？
A: 单 repo 阶段 URI 是可选的。解析规则：`brokerage://<domain>/<type>/<name>` → `services/<domain>/docs/<type>/<name>.md`。如果 domain 是 `mobile` 则路径为 `mobile/docs/<type>/<name>.md`。工具端不实现也不影响，此时 `path` 字段是主要引用方式。

### Q: 什么时候应该把一个域拆成独立 repo？
A: 满足以下任意两条即可考虑：(1) 代码量超过 100K 行；(2) 独立的发布节奏（不想被其他域的变更阻塞）；(3) 独立的团队负责（不和其他域共享开发者）；(4) AI agent 上下文经常溢出。
