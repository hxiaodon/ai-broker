# 交易引擎REST API SLA — 执行摘要（1页决策文档）

**日期**: 2026-03-30
**完成期限**: 2026-05-11（42天）
**优先级**: 🔴 关键路径（上线拦路虎）

---

## 📊 5个条件实现状态矩阵

| # | 条件 | 工作量 | 优先级 | 关键依赖 | 上游所有者 | 状态 |
|---|-----|--------|--------|----------|-----------|------|
| 1️⃣ | 市价本地缓存<br/>(Kafka → Redis) | **15天** | ⭐⭐⭐ | 无 | — | ✅ 可启动 |
| 2️⃣ | AMS账户缓存<br/>(TTL 60s + 4字段) | **6天** | ⭐⭐ | ✋ AMS 补充 kyc_status, kyc_tier, account_type, is_restricted | AMS team | ⏳ 待协调 |
| 3️⃣ | 现金余额+昨日市值<br/>缓存 | **5天** | ⭐⭐ | ✋ Fund Transfer 推送 balance_changed, daily_snapshot | Fund Transfer team | ⏳ 待协调 |
| 4️⃣ | DB索引优化<br/>(5个索引) | **3天** | ⭐ | 无 | — | ✅ 可启动 |
| 5️⃣ | 撤单异步模式<br/>+ WebSocket | **8天** | ⭐⭐ | ✅ 条件1 (行情缓存) | — | ⏳ 依赖条件1 |
| | **总计** | **23天** (关键路径) | | **2个外部依赖** | | |

---

## 🎯 关键路径分析

```
并行执行 (Week 1-3):
  ├─ 条件1 (15天)  ────────────────────────────────┐
  ├─ 条件4 (3天)   ────┐                             │
  ├─ 条件2 (6天)   ◄─AMS 补充字段 (2天) ────┐       │
  └─ 条件3 (5天)   ◄─Fund Transfer推送 (1天)│       │
                                             │       │
                                             ▼       ▼
  条件5 (8天) 依赖条件1完成 ◄────────────────────────┘

关键链: 条件1 (15天) → 条件5 (8天) = 23天 总耗时
缓冲期: 42天 - 23天 = 19天 用于集成/测试/上线准备
```

---

## ✅ 可行性结论

**完全可行 ✓✓✓**

| SLA 指标 | 目标 | 预期 P95 | 可行性 |
|---------|------|---------|--------|
| POST /orders | <500ms | **40-70ms** | ✅ 充分安全边际 |
| GET /orders | <200ms | **50-90ms** | ✅ 充分安全边际 |
| GET /positions | <200ms | **45-85ms** | ✅ 充分安全边际 |
| GET /portfolio/summary | <150ms | **45-75ms** | ✅ 充分安全边际 |
| DELETE /orders (202) | <500ms | **35-60ms** | ✅ 极为充分 |

**前提条件**（必须满足）：
1. ✅ 市价必须通过 Kafka 实时推送到 Redis（不能远程调用）
2. ✅ AMS 账户信息缓存 60s TTL（不能每次查询都远程调用）
3. ✅ 撤单采用异步模式 + WebSocket 推送（同步模式高风险）
4. ✅ 数据库索引在 Week 2 上线
5. ✅ Redis 和 Kafka 集群就位

**若上述任一条件无法满足，SLA 可能无法承诺。**

---

## 🚨 关键外部依赖（必须确认）

| 依赖 | 详情 | 所有者 | 截止日期 | 风险 |
|------|------|--------|---------|------|
| **AMS proto 补充** | 4 个新字段：kyc_status, kyc_tier, account_type, is_restricted | AMS team | 2026-04-07 (D7) | 🟡 中 |
| **Fund Transfer 事件推送** | balance_changed (每笔出入金), daily_snapshot (每日开盘前) | Fund Transfer team | 2026-04-14 (D14) | 🟡 中 |
| **Market Data Kafka topic** | market.quote, 吞吐量 10K+/s, 延迟 <100ms | Market Data team | 已有 | 🟢 低 |

**若任一依赖延期 >1 周，上线日期将推后。**

---

## 📅 里程碑时间表

```
Week 1  (D1-5, 3月31-4月4)
├─ ✅ 条件1 启动 Kafka Consumer 框架
├─ ✅ 条件4 DB 索引设计 + 灰度测试
└─ 📞 AMS/Fund Transfer kickoff 会

Week 2  (D6-10, 4月7-11)
├─ ⏳ AMS 交付 proto (截止 D7)
├─ ⏳ Fund Transfer 交付推送接口 (截止 D10)
├─ ✅ 条件1 消费逻辑 + 错误处理
└─ ✅ 条件2/3 启动开发 (阻塞于上游)

Week 3  (D11-15, 4月14-18)
├─ ✅ 条件1 性能测试 + 监控告警
├─ ✅ 条件2/3 集成到风控/API
├─ ✅ 条件5 Redis 队列 + Cancel Worker
└─ ✅ 全系统烟雾测试

Week 4  (D16-20, 4月21-25)
├─ ✅ 条件1 上线到生产 (灰度 10% → 100%)
├─ ✅ 条件5 FIX 集成 + WebSocket
├─ ✅ 条件2/3 完整集成
└─ ✅ 数据库索引上线

Week 5  (D21-25, 4月28-5月2)
├─ ✅ 条件5 监控告警 + 最终测试
├─ ✅ 并发负载测试 (1000 QPS)
├─ ✅ SLA 基准测试 (P50/P95/P99)
└─ ✅ 文档编写 + runbook

Week 6  (D26-31, 5月5-11)
├─ ✅ 缓冲 + 问题修复
├─ ✅ 灾难恢复演练
├─ ✅ 值班 Engineer 培训
└─ 🚀 **上线检查清单 (D31 完成)**

**🎉 上线日期：2026-05-11 (留有 1 周缓冲)**
```

---

## 💾 数据库 Schema 变更

**总变更量**: 4 个新字段 + 5 个新索引

```sql
-- 新增字段 (orders 表)
ALTER TABLE orders
ADD COLUMN cancel_status VARCHAR(32),      -- 撤单状态追踪
ADD COLUMN cancel_attempt_count INT,       -- 重试计数
ADD COLUMN last_cancel_attempt_at DATETIME(3),
ADD COLUMN cancel_reason VARCHAR(255);

-- 新增索引 (快速查询)
ALTER TABLE orders
ADD INDEX idx_orders_account_created (account_id, created_at DESC),
ADD INDEX idx_orders_idempotency (idempotency_key),
ADD INDEX idx_orders_cancel_status (account_id, cancel_status);

ALTER TABLE positions
ADD INDEX idx_positions_account (account_id),
ADD INDEX idx_positions_account_market (account_id, market);

ALTER TABLE day_trade_counts
ADD UNIQUE INDEX idx_day_trade_counts_unique (account_id, trade_date, symbol);
```

**执行策略**: 使用 `pt-online-schema-change` 或 MySQL 8.0.23+ 的 ALGORITHM=INSTANT，避免表锁

---

## 📈 关键监控指标 (8个)

| 指标 | 告警阈值 | 优先级 |
|------|---------|--------|
| Quote Cache Hit Rate | <95% | 🟡 中 |
| Quote Cache DLQ Messages | >100 | 🔴 高 |
| AMS Cache Hit Rate | <90% | 🟡 中 |
| AMS gRPC Error Rate | >1% | 🔴 高 |
| Cash Balance Cache Freshness | >300s | 🔴 高 |
| Cancel Success Rate | <90% | 🔴 高 |
| FIX Cancel Timeout Rate | >10/min | 🔴 高 |
| Orders Query P95 Latency | >200ms | 🟡 中 |

**Grafana Dashboard**: 已设计（见完整文档 Section 4），包含 3 个仪表盘

---

## 🎁 交付物清单

- [x] 完整实现方案文档 (8,000+ 行，Section 1-8)
- [x] Goose 数据库迁移脚本 (Schema 变更)
- [x] 5 个 Kafka Consumer 配置模板
- [x] Redis 缓存 Schema 设计
- [x] WebSocket 协议规范 (撤单推送)
- [x] Prometheus 告警规则 (YAML)
- [x] Grafana Dashboard JSON (3 个仪表盘)
- [x] 性能基准测试脚本 (sysbench 命令)
- [x] Runbook (常见问题 + 解决方案)
- [x] 灾难恢复测试计划

---

## ⚠️ 风险与缓解

| 风险 | 概率 | 缓解 |
|------|------|------|
| AMS 补充字段延期 | 中 | 早期协调，备选 fallback 方案 |
| Fund Transfer 推送不稳定 | 中 | 幂等处理 + 定期对账 |
| 市价缓存消费延迟 | 低 | 增加消费者 Pod，分区优化 |
| FIX 网络超时 | 中 | 异步模式规避此风险 |
| Redis 缓存雪崩 | 低 | 随机 TTL，本地备份缓存 |
| DB 连接池耗尽 | 中 | 扩容至 100+，异步池化 |

---

## 🚀 立即行动（本周）

**优先级 P0**（必须本周完成）：

1. **AMS Kickoff** (今天)
   - [ ] 发送 4 字段需求到 AMS team
   - [ ] 确认 proto 修改时间表
   - [ ] Assign owner

2. **Fund Transfer Kickoff** (今天)
   - [ ] 发送 event schema 需求
   - [ ] 确认 balance_changed + daily_snapshot 事件
   - [ ] Assign owner

3. **Trading Engine 框架启动** (本周)
   - [ ] 条件1: Kafka Consumer 框架搭建
   - [ ] 条件4: DB 索引迁移脚本编写
   - [ ] 建立跨团队同步机制 (daily standup)

---

## 📞 决策者问题与答案

**Q: 能否在 2026-05-11 前完成所有 5 个条件？**
A: ✅ 能。关键路径只需 23 天，留有 19 天缓冲。但前提是 AMS 和 Fund Transfer 在 Week 1-2 完成上游需求。

**Q: 若 AMS 或 Fund Transfer 延期，如何应对？**
A: 条件2/3 会被 block，其他条件可继续。最多延期 1-2 周。建议提前启动上游团队。

**Q: 撤单为什么必须异步？**
A: 同步模式需要等待 FIX 响应 50-300ms，可能超时。异步模式 API 响应 <50ms，用户体验更好。

**Q: 现有 REST API SLA 是多少？**
A: POST /orders <500ms, GET /positions <200ms, GET /portfolio/summary <150ms。我们的预测都远低于目标（充分安全边际）。

**Q: 需要修改多少代码？**
A: ~5,000 行新代码（5 个条件合计）+ 500 行 DB 迁移 + 300 行监控配置。中等规模变更。

**Q: 何时可以开始开发？**
A: 条件1、4 可立即开始。条件2 需要等 AMS proto（预计 D7），条件3 需要等 Fund Transfer（预计 D10），条件5 依赖条件1（预计 D15）。

---

## 签字确认

| 角色 | 姓名 | 日期 | 备注 |
|------|------|------|------|
| Trading Engineer | — | 2026-03-30 | 可行性评估：✅ 充分自信 |
| AMS Engineer | — | ⏳ 待签 | 需确认 4 字段补充时间表 |
| Fund Transfer Engineer | — | ⏳ 待签 | 需确认事件推送时间表 |
| Project Manager | — | ⏳ 待签 | 需确认资源分配 |
| DevOps Engineer | — | ⏳ 待签 | 需确认 Redis/Kafka/DB 资源 |

---

**详细文档**: `05_TECHNICAL_CONDITIONS_IMPLEMENTATION_PLAN.md` (8,000+ 行)

**完整方案表**: 见 Section 1（5个条件详细设计）

**参考规范**:
- `docs/specs/research-index.md` — 系统性能指标
- `docs/specs/domains/02-pre-trade-risk.md` — 风控流水线
- `docs/specs/domains/05-position-pnl.md` — 持仓计算
