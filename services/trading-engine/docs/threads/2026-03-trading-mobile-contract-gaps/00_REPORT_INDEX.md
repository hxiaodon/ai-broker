# Trading Engine REST API SLA 可行性评估 — 完整交付报告

**报告日期**: 2026-03-30
**报告人**: trading-engineer
**涉及方**: mobile-engineer, ams-engineer, trading-engineer, devops-engineer, product-manager

---

## 📌 报告概述

基于 Trading Engine 的详细技术分析，本报告评估了 Mobile 端对 5 个 REST API 端点的 SLA 建议的可行性。

**核心结论**:
- ✅ **4 个端点** (POST /orders, GET /orders, GET /positions, GET /portfolio/summary) 可以承诺建议的 SLA
- ⚠️ **1 个端点** (DELETE /orders/:id) 可以承诺但有风险，取决于 FIX 实现方案

**前提条件**: 5 个关键技术条件**全部满足**

---

## 📂 完整交付物清单

### Level 1: 执行摘要（给管理层）

**文件**: `EXECUTIVE_SUMMARY.md` (位置: `/services/trading-engine/docs/threads/2026-03-trading-mobile-contract-gaps/`)

**内容**:
- 核心评估结果（表格格式，易于阅读）
- 5 个关键技术条件的概览
- AMS 契约补充需求
- WebSocket 推送可行性
- 性能瓶颈排序和优先级
- 建议的协调步骤（4 个 Phase）
- 风险等级评估
- 成功指标定义

**适合读者**: CTO, PM, 业务负责人, 跨部门协调者

**使用场景**: 周会汇报、管理层决策、资源分配评估

---

### Level 2: 技术详细分析（给工程师）

**文件**: `SLA_FEASIBILITY_ASSESSMENT.md` (详细版本，约 800+ 行)

**第一部分: SLA 可行性评估表**
- 5 个端点逐个评估，包含：
  - 建议 SLA vs 实现能力
  - 详细理由
  - 关键条件

**第二部分: 性能瓶颈详细分解**
- POST /orders: 15-25ms 核心处理 + 网络往返 = 45-75ms P95 ✅
- GET /orders: <100ms (需要 DB 索引)
- DELETE /orders/:id: 50-310ms (FIX 往返不可控) ⚠️
- GET /positions: 70-150ms (需要市价缓存)
- GET /portfolio/summary: 60-100ms (需要多层缓存)

**第三部分: WebSocket 推送技术方案**
- position.updated: 15-30ms 延迟，完全可行
- portfolio.summary: 50-200ms 延迟，完全可行

**第四部分: 并发与峰值负载分析**
- 正常业务负载: 300 orders/s, 1000+ QPS
- 关键优化措施
- 监控指标和告警阈值

**第五部分: 数据库索引规划**
- 5 个必要索引的 SQL 语句
- 验证方法 (EXPLAIN)

**适合读者**: Trading Engineer, DevOps Engineer, Database Engineer

**使用场景**: 技术评审、实施计划制定、性能优化

---

### Level 3: 契约补充规范（给 AMS 工程师）

**文件**: `AMS_CONTRACT_SUPPLEMENT.md`

**第一部分: 新增字段定义**
- GetAccountStatus 返回的 4 个新字段：
  - `kyc_status` (PENDING | APPROVED | REJECTED | SUSPENDED)
  - `kyc_tier` (1 | 2，影响购买力和保证金比例)
  - `account_type` (CASH | MARGIN，影响 PDT 规则)
  - `is_restricted` (boolean，账户是否被限制)

**第二部分: Protobuf 和 OpenAPI 定义**
- 完整的数据类型定义
- 字段说明和枚举值
- REST 端点规范

**第三部分: 缓存策略**
- Trading Engine 60s TTL 缓存实现代码示例
- 缓存失效事件 (account.status_changed Kafka topic)

**第四部分: 实施时间表**
- 6 阶段计划，目标完成日期 2026-04-15
- 各阶段责任人和交付物

**适合读者**: AMS Engineer, 架构师

**使用场景**: AMS 实施计划、与 Trading Engine 联调

---

### Level 4: 决策流程（给协调者）

**文件**: `DECISION_TREE.md`

**第一部分: 快速决策路径**
- 是否能承诺 SLA? → 取决于 5 个条件是否满足

**第二部分: 5 个关键条件详解**
每个条件包含：
- 需求 (What)
- 原因 (Why)
- 实施方案 (How)
- 当前状态 (Status)
- 工作量估算
- 决策点 (YES/NO 分支)

**第三部分: 协商决策矩阵**
- 根据满足条件的个数，决定最终 SLA 承诺

**第四部分: 签署流程**
- 4 个 Phase: Requirement → Technical → Signature → Final
- 每个 Phase 的 Checklist

**第五部分: 红旗问题**
- 如果回答为 YES，立即暂停，重新评估

**适合读者**: 项目经理, 跨部门协调者, 决策者

**使用场景**: 团队协调会议、风险管理、流程管理

---

## 🎯 核心评估结果 (一表胜千言)

| 端点 | 建议 SLA | 评估结论 | 可行性 | 前提条件 |
|------|---------|--------|--------|---------|
| **POST /orders** | <500ms P95 | ✅ 可承诺 | 99% | 条件 2,4 |
| **GET /orders** | <200ms P95 | ✅ 可承诺 | 95% | 条件 4 |
| **DELETE /orders/:id** | <500ms P95 | ⚠️ 可承诺但风险 | 85% | 条件 5 |
| **GET /positions** | <200ms P95 | ✅ 可承诺 | 95% | 条件 1,4 |
| **GET /portfolio/summary** | <150ms P95 | ✅ 可承诺 | 95% | 条件 1,3,4 |

---

## 🔑 5 个关键技术条件速查表

| # | 条件 | 影响端点 | 状态 | 工作量 | 负责人 |
|---|------|--------|--------|--------|--------|
| 1 | 市价本地缓存 | GET /positions, /portfolio | ❌ | 2-3w | trading-eng |
| 2 | AMS 账户缓存 + 4 字段 | POST /orders | ❌ | 1-2w | ams-eng + trading-eng |
| 3 | 现金+昨日市值缓存 | GET /portfolio | ❌ | 1-2w | fund-eng + trading-eng |
| 4 | 数据库索引 (5个) | GET /orders, /positions | ❓ | 1d | trading-eng + devops |
| 5 | 撤单异步或 FIX 超时 | DELETE /orders | ❓ | 1-4w | trading-eng |

---

## 📊 性能瓶颈优先级排序

### P0 (高优，立即开始)
1. **AMS 账户信息缓存** - 改善 +50-100ms，影响最大的热路径 (POST /orders)
2. **市价本地缓存** - 改善 +50-100ms，影响 2 个查询端点

### P1 (中优，紧接着做)
3. **FIX 撤单优化** - 控制 P95 在 SLA 范围内
4. **数据库索引** - 改善 +50-100ms，低成本高回报

### P2 (低优，后续优化)
5. **并发竞争优化** - 高并发下的 DB 锁争用问题

---

## 📋 推荐的实施时间表

```
Week 1 (2026-03-30 ~ 04-06)
  ├─ Phase 1: 需求确认
  │  ├─ mobile-engineer 确认 SLA
  │  ├─ ams-engineer 评估字段补充
  │  └─ trading-engineer 评估工作量
  └─ 输出: 实施计划 + 资源分配

Week 2-4 (2026-04-07 ~ 04-27)
  ├─ Phase 2: 技术实施
  │  ├─ 条件 1: Kafka → Redis 市价同步
  │  ├─ 条件 2: AMS 字段 + 缓存层
  │  ├─ 条件 3: Fund Transfer 推送
  │  ├─ 条件 4: 数据库索引创建
  │  └─ 条件 5: 撤单异步模式或 FIX 超时
  └─ 输出: 功能代码 + 单测覆盖

Week 5 (2026-04-28 ~ 05-04)
  ├─ Phase 3: 测试验证
  │  ├─ 压力测试 (500+ orders/s)
  │  ├─ 故障模拟 (市价延迟, AMS 宕机等)
  │  ├─ P95 SLA 验证
  │  └─ 监控和告警配置
  └─ 输出: 测试报告 + 监控仪表板

Week 6 (2026-05-05 ~ 05-11)
  ├─ Phase 4: 签署契约
  │  ├─ 更新 trading-to-mobile.md
  │  ├─ 更新 ams-to-trading.md
  │  └─ 所有方签署
  └─ 输出: 最终契约文件
```

**总计**: 6 周 (1.5 个月)

---

## ✅ 验收标准

### 功能验收 (Functional)
- [ ] 所有 5 个端点均能在生产环境响应
- [ ] WebSocket 推送正常工作 (position.updated, portfolio.summary)
- [ ] AMS 新字段已补充到契约中
- [ ] 错误处理完善，用户获得清晰的错误提示

### 性能验收 (SLA Compliance)
- [ ] POST /orders: P95 <500ms (持续 7 天)
- [ ] GET /orders: P95 <200ms
- [ ] DELETE /orders/:id: P95 <500ms (或异步模式 <50ms)
- [ ] GET /positions: P95 <200ms
- [ ] GET /portfolio/summary: P95 <150ms

### 可靠性验收 (Reliability)
- [ ] WebSocket 推送延迟 <100ms (position.updated)
- [ ] WebSocket 推送延迟 <300ms (portfolio.summary)
- [ ] 无因技术原因导致 SLA 违反的告警
- [ ] 故障恢复时间 <1 分钟

### 监控验收 (Observability)
- [ ] Prometheus 指标齐全 (latency percentiles, throughput, error rate)
- [ ] Grafana 仪表板配置完成
- [ ] 告警规则配置 (SLA 违反时立即告警)
- [ ] 日志追踪完整 (correlation ID, request path)

---

## 🚨 风险评估与缓解方案

| 风险 | 等级 | 概率 | 缓解方案 |
|------|------|------|--------|
| FIX 往返延迟超过 400ms | 🔴 高 | 20% | 异步撤单 + WebSocket 或备用路由 |
| Kafka 消费延迟 > 50ms | 🟡 中 | 15% | 增加 Kafka partition 和消费者线程 |
| AMS 服务不可用 | 🟡 中 | 10% | 缓存降级 (使用过期缓存 5 分钟) |
| 数据库查询性能衰退 | 🟡 中 | 15% | 建立查询计划监控和自动告警 |
| 高并发时 Redis 瓶颈 | 🟢 低 | 5% | Redis Cluster 升级或读写分离 |

---

## 📞 联系方式

| 角色 | 姓名 | 邮箱 | 职责 |
|------|------|------|------|
| Trading Engineer | TBD | trading-engineer@company.com | 评估、实施、验收 |
| Mobile Engineer | TBD | mobile-engineer@company.com | 需求确认、集成测试 |
| AMS Engineer | TBD | ams-engineer@company.com | 新字段补充 |
| DevOps Engineer | TBD | devops-engineer@company.com | 基础设施优化 |
| Product Manager | TBD | product-manager@company.com | 业务方向、优先级 |

---

## 📚 相关文档列表

**本评估相关**:
- EXECUTIVE_SUMMARY.md (本报告的简化版)
- SLA_FEASIBILITY_ASSESSMENT.md (技术详解)
- AMS_CONTRACT_SUPPLEMENT.md (新字段规范)
- DECISION_TREE.md (决策流程)

**参考规范** (已读取):
- docs/specs/research-index.md (性能指标基准)
- docs/specs/trading-system.md (系统架构)
- docs/specs/domains/02-pre-trade-risk.md (风控流水线)
- docs/specs/domains/01-order-management.md (订单管理)
- docs/specs/domains/05-position-pnl.md (持仓计算)

**契约文件** (待更新):
- docs/contracts/trading-to-mobile.md (需补充 REST API SLA)
- docs/contracts/ams-to-trading.md (需补充新字段)

---

## 🎓 技术教科书参考

本评估基于以下关键技术原理：

1. **缓存分层** - 热数据 Redis, 温数据 DB, 冷数据 S3
2. **异步解耦** - Kafka 事件驱动，避免同步等待
3. **性能优化三角形** - 吞吐量 vs 延迟 vs 成本，需要平衡
4. **SLA 定义** - P50/P95/P99 分别代表不同的业务含义
5. **容量规划** - 根据峰值负载倒推所需的硬件和优化策略

---

## 📝 签署和批准

本报告由以下人员评审和批准：

**评估人** (1人)
- [ ] trading-engineer — 日期: _______

**审核人** (2人)
- [ ] product-manager — 日期: _______
- [ ] ams-engineer (可选) — 日期: _______

**批准人** (1人)
- [ ] CTO / Tech Lead — 日期: _______

---

## 🎉 报告完成

**报告生成日期**: 2026-03-30 23:59 CST
**预期签署日期**: 2026-04-06 (1 周内)
**实施启动日期**: 2026-04-07
**目标完成日期**: 2026-05-11

---

**附注**: 所有文档位于 `/services/trading-engine/docs/threads/2026-03-trading-mobile-contract-gaps/` 目录，可直接访问。

