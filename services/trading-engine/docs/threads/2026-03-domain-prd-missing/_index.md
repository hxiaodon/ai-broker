---
thread: trading-domain-prd-missing
type: heavyweight
status: RESOLVED
priority: P0
opened_by: trading-engine-engineer
opened_date: 2026-03-27T16:00+08:00
resolved_date: 2026-03-30T18:00+08:00
incorporated_date: 2026-03-30T18:00+08:00
participants:
  - trading-engine-engineer
  - product-manager
requires_input_from: []
affects_specs:
  - mobile/docs/prd/04-trading.md ✅
  - mobile/docs/prd/06-portfolio.md ✅
  - services/trading-engine/docs/prd/order-lifecycle.md ✅
  - services/trading-engine/docs/prd/risk-rules.md ✅
  - services/trading-engine/docs/prd/settlement.md ✅
  - services/trading-engine/docs/prd/position-pnl.md ✅
resolution: |
  **RESOLVED**（2026-03-30）

  所有待澄清项已确认，Domain PRD 完整创建并通过 PM 审批。

  ✅ 成本基础方法：确认加权均价法（Phase 1 + Phase 2）
  ✅ 公司行动处理：Phase 1 人工 + Phase 2 自动化
  ✅ GTC 90 天上限：PM 确认合理，法务进行中（预计 2026-04-05）

  所有 Domain PRD 文件已完成初稿并包含 PM 决策说明。
  Surface PRD 已同步更新，移除"待澄清"标记。

incorporated_commits:
  - 443caeb (docs(prd): PM clarification — cost basis method, corporate actions, GTC confirmation)
continues: null
continued_by: null
---

# 交易域 Domain PRD 缺失 + Surface PRD 混入 Domain 内容 — RESOLVED

## 解决总结

✅ **已完全解决**（2026-03-30）

### 创建的 Domain PRD 文件（4 个）

1. **order-lifecycle.md** ✅
   - 订单完整状态转换矩阵
   - 用户可见状态 ↔ 内部状态映射
   - DAY / GTC 有效期规则（含法务进度说明）
   - 幂等性与重复检测
   - 审计追踪（SEC Rule 17a-4）

2. **risk-rules.md** ✅
   - 8 道风控检查管道
   - PDT 完整规则（5 个交易日、$25K 权益、90 天标记期）
   - 市价单 Collar 参数（±5% 常规 / ±3% 盘前盘后）
   - 购买力公式（现金账户）
   - 持仓集中度预警（30% 阈值）

3. **settlement.md** ✅
   - T+1（美股）/ T+2（港股）结算周期
   - 已结算 vs 未结算股数的业务规则
   - Free-Riding Violation 防范
   - 结算流程（Scheduler 定时检查）
   - **Phase 1 公司行动处理方案**（PM 确认：人工处理现金分红/股票分红/拆分）

4. **position-pnl.md** ✅
   - **成本基础方法**：加权均价法（PM 确认，Phase 1+2 统一）
   - 业务依据：实现简洁、税务合规、用户友好、美港股统一
   - 未实现/已实现/日内 P&L 定义与计算
   - **Wash Sale Rule** 识别算法（IRS 规则实现）
   - 持仓市值与占比计算

### 修复的 Surface PRD 文件（2 个）

1. **mobile/docs/prd/04-trading.md (v2.2)** ✅
   - 补充 frontmatter（type: surface-prd, domain_prd, revisions）
   - 提取订单状态机、PDT 规则、价格保护参数
   - 保留用户旅程和前端展示规则
   - 脚注指向 Domain PRD

2. **mobile/docs/prd/06-portfolio.md (v2.2)** ✅
   - 补充 frontmatter
   - 移除"待澄清"标记，改为 PM 确认方案说明
   - 确认成本基础方法：加权均价法
   - 脚注指向 Domain PRD

### 后续澄清项状态

| 澄清项 | 状态 | 说明 |
|--------|------|------|
| 成本基础方法 | ✅ DONE | PM 确认加权均价法，理由已文档化 |
| 公司行动处理 | ✅ DONE | PM 确认 Phase 1 人工 + Phase 2 自动化，支持清单已定义 |
| GTC 90 天上限 | ⏳ IN PROGRESS | PM 确认业务方案，法务审查中（预计 2026-04-05） |

---

## Commit 记录

```
443caeb — docs(prd): PM clarification — cost basis method, corporate actions, GTC confirmation

Changes:
- 6 files changed, 1,436 insertions(+), 156 deletions(-)
- Services: trading-engine/docs/prd/ (4 new Domain PRD files + 1 README.md)
- Mobile: docs/prd/ (updated Surface PRD with PM decisions)
```

---

## 验收清单 ✅

- [x] Domain PRD 内容完整性（4 个文件 + README）
- [x] Surface PRD 结构优化（脚注、frontmatter、澄清）
- [x] PM 澄清项决策（成本基础、公司行动）
- [x] 文档对齐一致（用户可见状态映射、风控参数、结算规则）
- [x] Threads 记录完整（开题、迭代、解决）
- [ ] **待后续**：法务确认 GTC 90 天上限（2026-04-05）

---

## 工作移交

**已完成并可进入实现阶段：**
- ✅ 订单状态机设计（order-lifecycle.md）
- ✅ 风控规则定义（risk-rules.md）
- ✅ 结算流程设计（settlement.md）
- ✅ 成本基础和 P&L 计算（position-pnl.md）
- ✅ Surface PRD 同步更新

**待处理：**
- ⏳ 法务确认 GTC 规则（Block：Phase 1 上线前）
- ⏳ Engineering 根据 Domain PRD 设计数据库 schema
- ⏳ 后台工具（Admin Panel）扩展：公司行动管理界面
- ⏳ 更新 tech spec（`docs/specs/domains/`）引用 Domain PRD

---

此 Thread 已完全解决，后续工作见 2026-03-position-cost-basis 和 2026-03-trading-mobile-contract-gaps。

