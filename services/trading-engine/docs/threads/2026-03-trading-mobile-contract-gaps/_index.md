---
thread: trading-mobile-contract-gaps
type: lightweight
status: IN_PROGRESS
priority: P1
opened_by: trading-engineer
opened_date: 2026-03-27T16:15+08:00
participants:
  - trading-engineer
  - mobile-engineer
  - ams-engineer (✅ DONE)
requires_input_from: []
affects_specs:
  - docs/contracts/trading-to-mobile.md ✅ v1 SIGNED
  - docs/contracts/ams-to-trading.md ✅ v1.1 SIGNED
last_update: 2026-03-31
resolution: IN_IMPLEMENTATION_PHASE
incorporated_commits: []
---

# Trading → Mobile 契约 Gap — 实现进度跟踪

## 阶段进度（2026-03-31）

### ✅ 第 1 阶段：契约协商（COMPLETED 2026-03-30）
- [x] Mobile engineer SLA 评估
- [x] Trading engineer 可行性评估
- [x] AMS engineer 字段可行性评估
- [x] 更新 trading-to-mobile.md → v1
- [x] 更新 ams-to-trading.md → v1.1

### ⏳ 第 2 阶段：AMS 实现（COMPLETED 2026-03-31，提前 1 天）
- [x] DB 迁移文件：`00003_accounts_restriction_fields.sql` ✅
- [x] Protobuf 更新：`ams.proto` v1.1 ✅
- [x] 财务模型更新：`account-financial-model.md` v0.3 ✅

### ⏳ 第 3 阶段：Trading Engine 实现（进行中，2026-04-01 ~ 2026-05-11）

| 条件 | 工作项 | 优先级 | 目标完成 | 状态 |
|------|--------|--------|---------|------|
| 1. 市价缓存 | Kafka Consumer → Redis（Market Data 推送） | P0 | 2026-04-15 | ⏳ 待启动 |
| 2. AMS 缓存 | Redis TTL 60s + Kafka 事件驱动失效 | P0 | 2026-04-10 | ⏳ 待启动 |
| 3. 余额缓存 | Fund Transfer → Redis（现金 + 昨日市值） | P0 | 2026-04-15 | ⏳ 待启动 |
| 4. DB 索引 | 5 个查询索引（pt-online-schema-change） | P1 | 2026-04-05 | ⏳ 待启动 |
| 5. 撤单异步 | 202 Accepted + WebSocket 推送 | P1 | 2026-04-25 | ⏳ 待启动 |

### ⏳ 第 4 阶段：压力测试与上线（2026-05-05 ~ 2026-05-11）
- [ ] SLA 压力测试（POST<300ms, DELETE<400ms 等）
- [ ] 灰度上线 Beta
- [ ] 标记 Thread 为 RESOLVED

---

## 契约文档清单

| 文档 | 版本 | 状态 | 最后更新 |
|------|------|------|---------|
| `docs/contracts/trading-to-mobile.md` | v1 | ✅ AGREED | 2026-03-30 |
| `docs/contracts/ams-to-trading.md` | v1.1 | ✅ AGREED | 2026-03-30 |
| `services/ams/docs/specs/ams.proto` | v1.1 | ✅ DONE | 2026-03-31 |
| `services/ams/src/migrations/00003_*` | — | ✅ DONE | 2026-03-31 |

---

## 关键里程碑

- **2026-04-05**: DB 索引完成 → GET /orders, /positions 读取加速
- **2026-04-15**: 缓存层完成（市价、AMS、余额）→ POST/GET SLA 达成
- **2026-04-25**: 撤单异步完成 → DELETE SLA 达成 + WebSocket 事件推送
- **2026-05-05**: SLA 压力测试通过
- **2026-05-11**: 全量上线 + Thread RESOLVED

---

## 行动清单（立即执行）

**本周（2026-03-31 ~ 2026-04-06）**：
- [ ] trading-engineer 评估市价缓存架构（Kafka Consumer）
- [ ] trading-engineer 启动 DB 索引脚本（5 个索引定义）
- [ ] 发送需求至 Market Data team（quote.updated Kafka schema）
- [ ] 发送需求至 Fund Transfer team（balance.changed, daily_snapshot events）

**下周（2026-04-07 ~ 2026-04-13）**：
- [ ] AMS Kafka 事件推送上线
- [ ] Trading Engine Redis 缓存框架完成
- [ ] 集成测试框架搭建

**第 3 周（2026-04-14 ~ 2026-04-20）**：
- [ ] 5 个缓存条件全部上生产
- [ ] 撤单异步框架启动

**第 4 周（2026-04-21 ~ 2026-04-27）**：
- [ ] 撤单异步完成
- [ ] SLA 压力测试准备

**第 5-6 周（2026-04-28 ~ 2026-05-11）**：
- [ ] 压力测试、灰度、全量上线

---

## 关联文档

- 契约：`docs/contracts/trading-to-mobile.md` (v1)
- 契约：`docs/contracts/ams-to-trading.md` (v1.1)
- AMS 迁移：`services/ams/src/migrations/00003_accounts_restriction_fields.sql`
- AMS Proto：`services/ams/docs/specs/api/grpc/ams.proto` (v1.1)
- Domain PRD: `services/trading-engine/docs/prd/order-lifecycle.md`, `risk-rules.md`, `position-pnl.md`
