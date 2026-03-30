# 交易域 Domain PRD 创建完成

**创建日期**：2026-03-30
**创建者**：trading-engineer
**Status**：DRAFT（等待 PM 澄清和最终审批）

---

## 📋 创建的文件

### Domain PRD（4 个）

1. **order-lifecycle.md** — 订单生命周期
   - 订单完整状态转换矩阵（CREATED → VALIDATED → RISK_APPROVED → PENDING → OPEN → FILLED/CANCELLED/EXPIRED）
   - 用户可见状态与内部状态的映射
   - DAY / GTC 有效期规则（含法律待确认项）
   - 幂等性与重复检测机制
   - 审计追踪（SEC Rule 17a-4）

2. **risk-rules.md** — 预交易风险控制
   - 8 道风控检查管道
   - PDT（Pattern Day Trader）完整规则与计算逻辑
   - 市价单价格保护（Collar）参数定义（±5% 常规 / ±3% 盘前盘后）
   - 购买力计算公式（现金账户和融资账户）
   - 持仓集中度预警阈值（30%）
   - Reg SHO 卖空规则（Phase 2）

3. **settlement.md** — 结算流程
   - T+1（美股）/ T+2（港股）结算周期详解
   - 已结算 vs 未结算股数的业务规则
   - Free-Riding Violation 防范机制
   - 结算处理流程（Scheduler 定时检查）
   - 结算日期计算（考虑交易所假日）
   - 出金与结算的关系

4. **position-pnl.md** — 持仓与盈亏管理
   - **成本基础方法选择（待 PM 确认）**：当前使用加权均价法，可改为 FIFO
   - 未实现 P&L / 已实现 P&L / 日内 P&L 的定义与计算
   - 成本基础维护逻辑（购买时更新、卖出时保持、公司行动调整）
   - **Wash Sale Rule 识别算法**（IRS 税务规则）
   - 持仓市值与占比计算
   - 1099-B 报税逻辑（Phase 2）

---

## 🔗 Surface PRD 同步更新

### mobile/docs/prd/04-trading.md (v2.2)

已提取 Domain PRD 内容，保留用户旅程和前端展示规则：

| 章节 | 变更 | Domain PRD 引用 |
|------|------|-----------------|
| §五 订单状态 | 删除完整状态机图，保留用户可见状态表 | order-lifecycle.md §4 |
| §六.2 市价单保护 | 删除具体参数（±5%/±3%），保留用户提示文案 | risk-rules.md §3 |
| §九 PDT 规则 | 简化为教育内容，删除计算规则本体 | risk-rules.md §2 |
| §十一 合规要求 | 改为"前端展示方式"，删除规则详解 | order-lifecycle.md §5 |

### mobile/docs/prd/06-portfolio.md (v2.2)

已提取 Domain PRD 内容，加入澄清脚注：

| 章节 | 变更 | Domain PRD 引用 |
|------|------|-----------------|
| §六.1 成本计算 | 加入"待澄清"脚注（FIFO vs 加权均价） | position-pnl.md §1 |
| §六.2 已结算 | 删除 Free-Riding 监管细节 | settlement.md §3 |
| §七 合规要求 | 删除 Wash Sale 规则详解，仅保留前端标记 | position-pnl.md §4 |

---

## ⚠️ 待澄清项（Blocking Issues）

### P0: 成本基础方法确认（position-pnl.md §1）

**问题**：mobile/docs/prd/06-portfolio.md 当前采用**加权均价法**，但标题说"FIFO 原则"。

**PM 需要确认**：
1. 实现 FIFO 还是加权均价？
2. 是否需要修改 Surface PRD 的标题和说明？
3. Phase 1（美股）和 Phase 2（港股）是否使用相同方法？

**后续行动**：
- [ ] PM 在 position-pnl.md §1.4 中补充澄清
- [ ] 更新 mobile/docs/prd/06-portfolio.md §6.1 的澄清脚注
- [ ] 修改数据库 schema 和实现代码（如有需要）

### P1: GTC 90 天上限法律确认（order-lifecycle.md §2.2）

**问题**：GTC（长期有效单）的 90 天上限是否符合 SEC/SFC 监管要求？

**法务需要确认**：
1. SEC 对 GTC 有效期是否有规定？
2. SFC（港股）对 GTC 有效期是否有规定？
3. 能否延长至 180 天或其他期限？

**后续行动**：
- [ ] 法务确认并在 order-lifecycle.md §2.2 补充
- [ ] 如有变更，同步更新 mobile/docs/prd/04-trading.md

### P1: 公司行动处理（settlement.md §6.2、position-pnl.md §3.3）

**问题**：股票拆分、分红等公司行动如何自动调整？

**Phase 1**：人工处理（PM 确认后手动触发）
**Phase 2**：自动化处理（需要专门设计）

**后续行动**：
- [ ] 在 Phase 2 规划时细化自动化流程

---

## ✅ 验收清单

### Domain PRD 内容完整性

- [x] order-lifecycle.md：订单状态机、有效期、幂等性、审计
- [x] risk-rules.md：风控检查、PDT、Collar、购买力、集中度
- [x] settlement.md：T+1/T+2、已结算/未结算、Free-Riding、出金关系
- [x] position-pnl.md：成本基础（待确认）、P&L、Wash Sale、市值占比

### Surface PRD 结构优化

- [x] mobile/docs/prd/04-trading.md：补充 frontmatter，提取 Domain 内容，脚注引用
- [x] mobile/docs/prd/06-portfolio.md：补充 frontmatter，加入澄清脚注，脚注引用

### 契约与 Domain PRD 的对齐

- [x] trading-to-mobile.md 中的用户状态 ← order-lifecycle.md §4 映射表
- [ ] **待补充**：API 响应中应同时返回内部状态（用于 webhook）和用户状态（用于 UI）

### Threads 维护

- [x] Thread 2026-03-domain-prd-missing 更新：01-trading-engineer-review.md 中确认 Domain PRD 已创建
- [ ] **等待 PM 回复**：Thread 中确认成本基础方法选择

---

## 📊 Domain PRD 映射关系图

```
Surface PRD (Mobile 用户旅程)
  │
  ├─ mobile/prd/04-trading.md
  │   ├─→ order-lifecycle.md (订单状态、幂等性、审计)
  │   ├─→ risk-rules.md (PDT、价格保护、购买力、集中度)
  │   └─→ settlement.md (结算周期影响出金)
  │
  └─ mobile/prd/06-portfolio.md
      ├─→ position-pnl.md (成本基础、P&L、Wash Sale)
      └─→ settlement.md (已结算/未结算、结算日期)

Contracts (API 接口)
  │
  ├─ trading-to-mobile.md
  │   ├─→ order-lifecycle.md §4 (用户状态映射)
  │   └─→ risk-rules.md (买入力、集中度警告)
  │
  └─ ams-to-trading.md
      └─→ risk-rules.md (账户状态检查)
```

---

## 🚀 后续工作

### 立即（1-2 天）

1. **PM 澄清** (§1.4、§3.3)：
   - [ ] 确认成本基础方法（FIFO vs 加权均价）
   - [ ] 确认公司行动处理方案

2. **法务确认** (order-lifecycle.md §2.2)：
   - [ ] GTC 90 天上限是否符合监管要求

3. **Engineer Review**：
   - [ ] trading-engineer 评审 Domain PRD 内容是否可实现
   - [ ] 确认数据库 schema 设计

### 短期（1-2 周）

4. **更新契约**：
   - [ ] trading-to-mobile.md 补充 SLA 定义
   - [ ] ams-to-trading.md 补充 GetAccountStatus 返回字段

5. **Tech Spec 对齐**：
   - [ ] 更新 `services/trading-engine/docs/specs/domains/` 各文件，引用 Domain PRD

6. **Threads 关闭**：
   - [ ] 2026-03-domain-prd-missing → RESOLVED（Domain PRD 完成）
   - [ ] 2026-03-position-cost-basis → RESOLVED（成本基础确认）
   - [ ] 2026-03-trading-mobile-contract-gaps → 迭代更新契约

---

## 📝 文件引用

| 文件 | 状态 | 上次更新 |
|------|------|---------|
| services/trading-engine/docs/prd/order-lifecycle.md | DRAFT | 2026-03-30 |
| services/trading-engine/docs/prd/risk-rules.md | DRAFT | 2026-03-30 |
| services/trading-engine/docs/prd/settlement.md | DRAFT | 2026-03-30 |
| services/trading-engine/docs/prd/position-pnl.md | DRAFT | 2026-03-30 |
| mobile/docs/prd/04-trading.md | v2.2 | 2026-03-30 |
| mobile/docs/prd/06-portfolio.md | v2.2 | 2026-03-30 |
| docs/active-threads.yaml | 更新 | 2026-03-27 |
