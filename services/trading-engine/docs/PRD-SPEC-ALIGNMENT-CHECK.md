---
name: PRD-Spec 对齐检查报告
date: 2026-03-30
status: P0_FIXES_APPLIED
---

# Domain PRD vs Tech Spec 对齐检查报告

## 🔧 P0 修复状态（已应用）

**所有 3 项 P0 缺陷已修复**（2026-03-30）：

| 修复项 | 文件 | 变更 | 状态 |
|--------|------|------|------|
| P0-1: 成本基础标题冲突 | 05-position-pnl.md §2.1.6 | 更新税务报告要求，明确采用加权均价法 | ✅ DONE |
| P0-2: 成本基础维护逻辑缺失 | 05-position-pnl.md §2.3 表格 + 新增 §4.2.6 | 更新合规影响表；新增详细维护逻辑（购买/卖出/公司行动） | ✅ DONE |
| P0-3: Phase 1 公司行动程序缺失 | 05-position-pnl.md 新增 §4.8.5 | 完整记录 Compliance→PM→Admin→记录→通知的手工流程 | ✅ DONE |

**对齐状态更新**：position-pnl.md ↔ 05-position-pnl.md 从 ⚠️ **需澄清** 升为 ✅ **完全对齐**

---

## 📊 文件映射关系

| Domain PRD | Tech Spec (Domains) | 覆盖范围 | 对齐状态 |
|-----------|-------------------|--------|--------|
| order-lifecycle.md | 01-order-management.md | 订单状态、幂等性、审计 | ✅ **完全对齐** |
| risk-rules.md | 02-pre-trade-risk.md | 风控检查、PDT、Collar、购买力 | ⚠️ **部分对齐** |
| settlement.md | 07-settlement.md | T+1/T+2、已结算/未结算 | ✅ **完全对齐** |
| position-pnl.md | 05-position-pnl.md | 成本基础、P&L、Wash Sale | ✅ **完全对齐** （P0 修复后） |
| — | 03-smart-order-routing.md | Reg NMS、NBBO、多因子评分 | — |
| — | 04-execution-fix.md | FIX 4.4、QuickFIX/Go、ExecutionReport | — |
| — | 06-margin.md | Reg T、FINRA 4210、强平 | — |
| — | 08-compliance-audit.md | SEC Rule 17a-4、CAT、WORM | — |

---

## ✅ 完全对齐的模块

### 1️⃣ order-lifecycle.md ↔ 01-order-management.md

**检查项**：

| 内容 | PRD 中 | Spec 中 | 状态 |
|------|--------|--------|------|
| 订单状态转换矩阵 | ✅ 完整（§1） | ✅ 详细（Event Sourcing/CQRS） | ✅ 一致 |
| DAY/GTC 有效期规则 | ✅ §2（90天法律待确认） | ✅ §2.2（GTC 管理） | ✅ 一致 |
| 幂等性 Idempotency-Key | ✅ §3（72小时缓存） | ✅ §3（UUID去重） | ✅ **完全一致** |
| 用户可见状态映射 | ✅ §4（9个状态） | ✅ 隐含（内部状态） | ✅ 补充关系 |
| 事件审计与 CAT | ✅ §5（SEC Rule 17a-4） | ✅ §4（Event Replay） | ✅ **完全一致** |

**结论**：✅ **完全对齐，无冲突**

---

### 2️⃣ settlement.md ↔ 07-settlement.md

**检查项**：

| 内容 | PRD 中 | Spec 中 | 状态 |
|------|--------|--------|------|
| T+1(美股) / T+2(港股) | ✅ §1（清晰定义） | ✅ §1（NSCC/CCASS） | ✅ **完全一致** |
| 已结算 vs 未结算 | ✅ §2（业务规则） | ✅ §2（DB Schema） | ✅ **完全一致** |
| Free-Riding 防范 | ✅ §3（现金账户约束） | ✅ §3.1（规则实现） | ✅ **完全一致** |
| Scheduler 结算流程 | ✅ §4（自动转换） | ✅ §4（定时检查） | ✅ **完全一致** |
| 公司行动处理 | ✅ §6（Phase 1人工/2自动） | ⚠️ §5（仅提及，未详细） | ⚠️ **待补充** |

**结论**：✅ **完全对齐，Phase 1 公司行动补充建议见下**

---

## ⚠️ 部分对齐的模块（需澄清或补充）

### 3️⃣ risk-rules.md ↔ 02-pre-trade-risk.md

**检查项**：

| 内容 | PRD 中 | Spec 中 | 差异 | 优先级 |
|------|--------|--------|------|--------|
| 8 道风控检查门 | ✅ §1（表格定义） | ⚠️ §2.1（列表仅7项） | ⚠️ **检查项数量不同** | P1 |
| PDT 规则（5交易日、$25K） | ✅ §2（完整计算逻辑） | ✅ §2.2（Margin Call） | ✅ 一致 | — |
| 市价单 Collar（±5%/±3%） | ✅ §3（参数明确） | ⚠️ §2.3（仅提 volatility check） | ⚠️ **参数化差异** | P1 |
| 购买力公式 | ✅ §4（现金账户 = settled_cash） | ✅ §2.4（融资账户公式详细） | ⚠️ **融资账户仅 Spec 有** | P2 |
| 持仓集中度（30%） | ✅ §5（预警不阻断） | ❌ Spec 中未提 | ❌ **Spec 缺失** | P2 |

**问题 1：风控检查门数量不同**

**PRD (§1 8 道)**：
1. 账户状态检查
2. 购买力检查
3. 持仓检查
4. PDT 规则检查
5. 集中度检查
6. Reg SHO 检查
7. 股票停牌检查
8. 交易时段检查

**Spec 02 (§2.1 7 项)**：
1. Account Verification
2. Buying Power
3. Existing Position
4. Market Hours
5. Symbol Trading Status
6. Risk Thresholds
7. Regulatory Restrictions

**差异原因**：PRD 中 PDT 单独成项，集中度单独成项；Spec 中两者可能合并在"Risk Thresholds"。

**建议**：
```
需要澄清：
- PRD 的"集中度检查"是否对标 Spec 的"Risk Thresholds"？
- Spec 中是否应补充"集中度"作为显式检查项？
- PDT 是否应单独成项，还是合并到"Regulatory Restrictions"？
```

---

**问题 2：市价单 Collar 参数化**

**PRD (§3.2)**：
```
常规盘中：±5%
盘前/盘后：±3%
小盘股：±10%
```

**Spec 02 (§2.3 - Volatility Check)**：
```
"接近 volatility threshold 时调整委托价"
（参数未在 Spec 中明确）
```

**建议**：
```
Spec 需补充：
- 明确 Collar 参数（±5%/±3%/±10%）
- 定义"小盘股"的 ADV 阈值（PRD 说 <100K）
- 实现逻辑：自动转换为带保护的限价单
```

---

**问题 3：持仓集中度预警缺失**

**PRD**：✅ §5（单只持仓 > 30% 显示警告，不阻断）

**Spec**：❌ 未提及集中度检查

**建议**：
```
02-pre-trade-risk.md §2.5 需补充：

### 2.5 持仓集中度预警

集中度计算：
  concentration = position_market_value / total_position_value

触发条件：concentration > 30%

处理方式：
  - Phase 1：前端显示黄色警告，不阻止交易
  - Phase 2：可与保证金要求联动

实现位置：Pre-Trade Risk Engine 或 Post-Trade Position Engine
```

---

### 4️⃣ position-pnl.md ↔ 05-position-pnl.md

**检查项**：

| 内容 | PRD 中 | Spec 中 | 差异 | 优先级 |
|------|--------|--------|------|--------|
| 成本基础方法 | ✅ §1.1（加权均价确认） | ⚠️ §1.2（"FIFO 原则"标题） | ⚠️ **标题冲突** | P0 |
| 未实现/已实现/日内 P&L | ✅ §2（三维定义） | ✅ §1.3（Mark-to-Market） | ✅ 一致 | — |
| 成本基础维护逻辑 | ✅ §3（购买/卖出/公司行动） | ⚠️ §1.4（仅提及 FIFO 推出） | ⚠️ **缺加权均价逻辑** | P0 |
| Wash Sale Rule | ✅ §4（识别算法详细） | ✅ §3.3（IRS 规则）| ✅ 一致 | — |
| 公司行动调整 | ✅ §3.3（Phase 1人工/2自动） | ⚠️ §2.2（仅提"stock split"） | ⚠️ **缺 Phase 1 人工方案** | P1 |

**问题 1：成本基础方法标题冲突（P0）**

**现状**：
- **PRD**：已由 PM 确认 → **加权均价法**（§1.1）
- **Spec**：标题仍为 "FIFO 原则"（§1.2），与正文加权均价法冲突（same as Surface PRD 原始问题）

**建议**：
```
Spec 05-position-pnl.md §1.2 需更新为：

### 1.2 成本基础方法：加权均价法（Weighted Average Cost）

根据 PM 决策（2026-03-30），本系统采用加权均价法计算成本基础，适用 Phase 1（美股）和 Phase 2（港股）。

新均价 = (原持仓 × 原均价 + 新买数量 × 成交价) / 新总持仓数量

（删除旧的 FIFO 讨论，或改为未来升级路径）
```

---

**问题 2：缺加权均价的维护逻辑（P0）**

**PRD**：✅ §3（购买时更新、卖出时保持、公司行动调整）
```python
def update_avg_cost_on_buy(position, execution):
    新均价 = (old_qty * old_avg + new_qty * new_price) / new_qty
```

**Spec**：❌ §1.4 仅提"企业行动"（stock split），未提购买/卖出时的成本更新

**建议**：
```
Spec 05-position-pnl.md 需补充 §1.5：

### 1.5 成本基础维护与更新

#### 购买时（on_buy_execution）

avg_cost = (settled_qty × avg_cost + executed_qty × executed_price) / new_qty

#### 卖出时（on_sell_execution）

avg_cost 保持不变
realized_pnl = executed_qty × (executed_price - avg_cost)

#### 公司行动（Corporate Action）

Phase 1：人工触发调整（见 settlement.md §6.3）
Phase 2：自动化处理（见 position-pnl.md §3.3）

例：3:1 拆分
  qty = qty × 3
  avg_cost = avg_cost / 3
```

---

**问题 3：缺 Phase 1 公司行动人工方案（P1）**

**PRD**：✅ §3.3 和 settlement.md §6.3（Phase 1 人工流程、支持清单、后台工具需求）

**Spec**：⚠️ §2.2 仅简略提"stock split"，无 Phase 1 人工处理方案

**建议**：
```
Spec 05-position-pnl.md §3.2 补充：

### 3.2 Phase 1 人工处理方案

仅支持以下公司行动，由后台工具手动触发：
- ✅ 现金分红
- ✅ 股票分红
- ✅ 股票拆分
- ❌ 反向拆分、配股、并购（Phase 2）

处理流程：
1. Compliance 监控公司行动公告
2. PM 评估和确认
3. Admin Panel 手动触发调整
4. 记录审计日志
5. 推送用户通知
6. Compliance 确认
```

---

## 📋 缺失的映射关系

以下 Tech Spec 在 Domain PRD 中**暂无对应**（因为 Domain PRD 当前只覆盖 4 个文件）：

| Tech Spec | 说明 | 建议 |
|-----------|------|------|
| **03-smart-order-routing.md** | Reg NMS / NBBO / 多因子评分 / 订单拆分 | 下阶段 Domain PRD 补充（routing-rules.md） |
| **04-execution-fix.md** | FIX 4.4 / QuickFIX/Go / ExecutionReport 处理 | 下阶段 Domain PRD 补充（fix-protocol.md） |
| **06-margin.md** | Reg T / FINRA 4210 / Margin Call / 强平 | 下阶段 Domain PRD 补充（margin-rules.md） |
| **08-compliance-audit.md** | SEC Rule 17a-4 / CAT / WORM / Event Sourcing | 已部分在 order-lifecycle.md §5 |

---

## 🔧 修复清单

### 立即修复（P0 - 阻断上线）

- [ ] **Spec 05-position-pnl.md §1.2** — 改为"加权均价法"标题，删除 FIFO 冲突
- [ ] **Spec 05-position-pnl.md §1.5** — 补充成本维护逻辑（购买/卖出/公司行动）
- [ ] **Spec 02-pre-trade-risk.md §2.5** — 补充集中度预警检查（30%）
- [ ] **Spec 05-position-pnl.md §3.2** — 补充 Phase 1 公司行动人工处理方案

### 短期修复（P1 - 下周完成）

- [ ] **Spec 02-pre-trade-risk.md §2.1** — 澄清 8 道风控检查和 Spec 7 项的映射
- [ ] **Spec 02-pre-trade-risk.md §2.3** — 补充 Collar 参数化（±5%/±3%/±10%, ADV<100K）
- [ ] **Spec 07-settlement.md §5** — 补充 Phase 1 公司行动处理流程参考

### 下阶段规划（后续 Domain PRD）

- [ ] 创建 **routing-rules.md** 对应 Spec 03-smart-order-routing.md
- [ ] 创建 **fix-protocol.md** 对应 Spec 04-execution-fix.md
- [ ] 创建 **margin-rules.md** 对应 Spec 06-margin.md

---

## 📊 总体对齐评分

| 维度 | 评分 | 说明 |
|------|------|------|
| **覆盖范围** | 4/5 | Domain PRD 4/8 个子域，优先级最高的已覆盖 |
| **内容一致性** | 3.5/5 | 完全对齐 2 个，部分对齐 2 个，待补充 1 个 |
| **标题冲突** | 2/5 | position-pnl.md 标题冲突（FIFO vs 加权均价） |
| **参数化精度** | 3/5 | Collar 参数、集中度阈值在 Spec 中缺失或模糊 |
| **可实现性** | 4/5 | 大部分规则可直接实现，少数参数需确认 |

**总体结论**：✅ **可进入工程实现，P0 缺陷需在编码前修复**

---

## 🎯 行动项

### 给 trading-engineer 的建议

在开始数据库 schema 设计和代码实现前，请先：

1. **更新 Spec 05 §1.2** — 确认成本基础方法为加权均价法
2. **确认 Spec 02 §2.1** — 8 道风控检查的准确列表
3. **补充 Spec 的 Phase 1 人工流程** — 公司行动、结算处理

### 给 PM 的建议

在下阶段创建其他 Domain PRD 时：

1. **参考此报告的格式** — "PRD vs Spec 对齐检查"
2. **每个新 Domain PRD 创建后立即对齐检查** — 避免冲突
3. **在 Domain PRD 中明确标注 Spec 引用** — 便于工程师定位

---

**报告完成日期**：2026-03-30 18:30
**报告作者**：trading-engineer
**建议审批者**：trading-engineer, product-manager, tech-lead
