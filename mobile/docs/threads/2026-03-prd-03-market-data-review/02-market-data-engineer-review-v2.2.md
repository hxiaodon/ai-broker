---
seq: 02
author_role: market-data-engineer
date: 2026-03-20T16:00+08:00
action: RAISE_ISSUE
---

# Market Data Engineer 技术评审意见 v2.2

> 对象: PRD-03 行情模块 v2.2 (2026-03-20)
> 评审人: market-data-engineer
> 参照:
> - `.claude/rules/financial-coding-standards.md`
> - `.claude/rules/security-compliance.md`
> - `.claude/rules/fund-transfer-compliance.md`
> - `services/market-data/docs/specs/market-data-system.md`
> - `services/market-data/docs/specs/market-api-spec.md`
> - `services/market-data/docs/specs/websocket-mock.md`

---

## 评审结论

PRD-03 v2.2 已解决上一轮评审的所有问题（C1/C2/H1-H6/M1-M5），感谢产品团队的配合。

本轮评审发现 **1 项 P1 合规风险** 和 **2 项 P2 待确认项**，需要 PM 确认后修订。

| 级别 | 编号 | 标题 | 需要回复方 |
|------|------|------|-----------|
| P1 | C3 | 大盘指数显示合规风险 | PM |
| P2 | Q1 | 流通股数数据源待确认 | PM |
| P2 | Q2 | 中文搜索覆盖范围待确认 | PM |

---

## P1 - 合规风险（Critical）

### C3: 大盘指数显示需要改为 ETF 替代

**位置**:
- PRD Section 5.1 "美股大盘指数横向滚动卡片"
- 原型 `prototypes/03-market/index.html` 第 87-110 行

**问题**:
- 原型当前显示："标普 500 / 纳斯达克 / 道琼斯"
- **合规风险**：S&P 500 指数需要 S&P Global 单独授权，DJIA 需要 S&P/Dow Jones Indices 授权
- 直接使用指数名称和数值违反数据授权协议

**全局规范依据**:
> `services/market-data/docs/specs/market-data-system.md` Section 0.3:
> "Phase 1 决策：使用 ETF 替代指数（合规且零额外成本）"

**建议修改**:

| 当前显示 | 应改为 | 说明 |
|----------|--------|------|
| 标普 500 | **SPY**（追踪 S&P 500）| SPDR S&P 500 ETF |
| 纳斯达克 | **QQQ**（追踪 Nasdaq-100）| Invesco QQQ |
| 道琼斯 | **DIA**（追踪 DJIA）| SPDR DJIA ETF |

**UI 展示规范**:
```
┌─────────────┐
│ 标普 500    │  ← 改为 →  │ SPY     │
│ 5,234.18    │            │ $521.44 │
│ +0.82%      │            │ +0.82%  │
│             │            │ 追踪 S&P 500 │
└─────────────┘            └─────────┘
```

**PRD 修改建议**:
Section 5.1 修改为：
> 大盘指数横向滚动卡片（使用 ETF 作为指数代理）：
> - SPY（追踪 S&P 500）
> - QQQ（追踪 Nasdaq-100）
> - DIA（追踪 DJIA）
> - 2800.HK（追踪恒生指数，Phase 2）
>
> UI 需标注 "追踪 XXX"，不可直接写指数名称，避免误导用户和合规风险。

**原型修改建议**:
`prototypes/03-market/index.html` 第 87-110 行需更新为 ETF 版本。

---

## P2 - 待确认（Question）

### Q1: 换手率计算需要的流通股数数据源

**位置**: PRD Section 5.2 "换手率计算口径"

**问题**:
- PRD v2.2 已补充换手率计算口径：`换手率 = 当日成交量 ÷ 流通股数 × 100%`
- **数据源未确认**：流通股数（Float Shares 或 Shares Outstanding）来自哪里？

**影响**:
- 影响数据采集和存储方案
- 影响开发排期（需要集成新的数据源）

**可选方案**:

| 方案 | 数据源 | 优点 | 缺点 |
|------|--------|------|------|
| A | Polygon.io Fundamental API | 与行情同供应商，集成简单 | 需确认 Polygon 是否包含该字段 |
| B | 第三方财务数据（Xignite、Refinitiv）| 数据全面准确 | 额外成本和集成工作 |
| C | 自建爬虫从公开渠道采集 | 成本低 | 维护成本高，数据可靠性存疑 |

**建议**: 优先确认方案 A（Polygon Fundamental API），若不可用则评估方案 B。

**PRD 补充建议**:
Section 5.2 增加：
> 流通股数来源：[待确认，建议 Polygon.io Fundamental API 或第三方财务数据供应商]，每日收盘后更新一次。

---

### Q2: 中文公司名和拼音搜索的覆盖范围

**位置**: PRD Section 5.3 "搜索匹配规则"

**问题**:
- PRD v2.2 已补充搜索 debounce（300ms）和最少字符规则
- **覆盖范围未确认**：中文公司名和拼音搜索覆盖多少只股票？

**影响**:
- 影响搜索索引构建策略（Top 1000 vs 全部美股）
- 影响数据采集范围和工作量
- 影响用户搜索体验预期

**建议选项**:

| 覆盖范围 | 股票数量 | 适用场景 |
|----------|----------|----------|
| Top 1000 美股 | ~1000 只 | 覆盖 99% 用户搜索需求，工作量可控 |
| 全部美股 | ~6000+ 只 | 完整覆盖，但数据采集和维护成本高 |
| 动态扩展 | 从 Top 500 开始，根据搜索日志扩展 | 迭代式，资源最优 |

**PRD 补充建议**:
Section 5.3 增加：
> 中文名/拼音搜索覆盖范围：[待确认，建议 Phase 1 覆盖 Top 1000 美股（按市值/成交量），Phase 2 扩展至全部]

---

## 已确认的实现方案 ✓

以下 PRD v2.2 更新与技术架构规范对齐，无需修改：

| 需求项 | PRD v2.2 定义 | 技术实现 | 状态 |
|--------|---------------|----------|------|
| 访客延迟行情 | 每5秒推送 T-15min 快照 | `DelayedQuoteRingBuffer` | ✅ |
| 分时K线范围 | 仅常规时段 09:30-16:00 ET | 约 390 条 | ✅ |
| 报价层级 | Phase 1 仅 Level 1 | 最佳买一/卖一 | ✅ |
| Watchlist 上限 | 100只 | 后端 API 强制约束 | ✅ |
| 搜索 Debounce | 300ms | 客户端防抖 | ✅ |
| HALTED 状态 | 暂停交易红色标签 | 集成交易所停牌信号 | ✅ |

---

## 依赖与风险 🔴

| 依赖项 | 状态 | 风险等级 | 缓解措施 |
|--------|------|----------|----------|
| Polygon.io Poly.feed+ 授权 | 谈判中 | 🔴 高 | 标准 API Key 禁止向终端用户展示数据，必须升级 |
| 中文名/拼音映射表 | 待构建 | 🟡 中 | 明确覆盖范围后启动数据采集 |
| 停牌信号源 | 待确认 | 🟡 中 | 确认 Polygon 是否提供 Trading Halt 状态 |
| 流通股数数据源 | 待确认 | 🟡 中 | 确认后集成 Fundamental API |

---

## 建议下一步行动

1. **本周内（P1）**: 更新原型中的大盘指数显示为 ETF 替代（SPY/QQQ/DIA）
2. **本周内（P2）**: 确认流通股数数据源（优先 Polygon Fundamental API）
3. **本周内（P2）**: 明确中文搜索覆盖范围（建议 Phase 1 Top 1000 美股）
4. **持续跟进**: Polygon Poly.feed+ 授权谈判进度

---

## 需要回复方

- [ ] **product-manager**: 回复 C3、Q1、Q2（共 3 项）
