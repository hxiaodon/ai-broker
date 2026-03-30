# 出入金 PRD 结构问题 — 30 秒速览

## 三个问题（优先级从高到低）

### ❌ **问题 1：Domain PRD 缺失** [P0]
- **现状**：`services/fund-transfer/docs/prd/` 目录为空
- **影响**：Fund-engineer 无统一业务规则源头；跨域方无权威引用
- **违规**：SPEC-ORGANIZATION § 铁律 1（Domain PRD 应该存在）

### ⚠️ **问题 2：Mobile PRD-05 混入 Domain 内容** [P0]
- **现状**：§6-9 包含审批规则、计算公式、合规要求等 Domain 逻辑
- **影响**：Mobile 工程师加载了 30% 无关内容；职责边界不清
- **应该拆出**：审批矩阵、可提现公式、AML/CTR/Travel Rule 说明

### 🔄 **问题 3：合规规则与 PRD 同步缺失** [P1]
- **现状**：`.claude/rules` 中的 10 条规则与 PRD 有遗漏和不一致
- **遗漏**：Travel Rule、Idempotency、Ledger Integrity 在 PRD 中无踪影
- **风险**：实现时可能遗漏关键合规点

---

## 推荐方案：创建完整 Domain PRD

### 操作
1. 创建 `services/fund-transfer/docs/prd/fund-transfer-system.md`（业务规则源头）
2. 修改 Mobile PRD-05：
   - 删除 Domain 内容
   - 改为引用 Domain PRD
   - 保留 UI/交互部分
3. 补全合规规则-PRD 映射表

### 工作量
- ~3-4 小时

### 收益
- ✅ 符合规范
- ✅ 跨域协作更清晰
- ✅ 合规可追溯

---

## 文件位置
- **Thread Index**: `docs/threads/2026-03-funding-prd-structure/_index.md`
- **详细意见**: `docs/threads/2026-03-funding-prd-structure/01-fund-engineer-review.md`
- **活跃索引**: `docs/active-threads.yaml` 已注册

---

## 下一步
等待 PM + Code Reviewer 回复。预计 1-2 个工作日。
