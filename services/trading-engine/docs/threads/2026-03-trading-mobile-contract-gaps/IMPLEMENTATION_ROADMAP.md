# Trading-Mobile 契约实现路线图

> **生成日期**: 2026-03-31
> **目标上线日期**: 2026-05-11
> **总工期**: 6 周

---

## 进度概览

```
Week 1  │ Week 2  │ Week 3  │ Week 4  │ Week 5  │ Week 6
(3.31)  │(4.7)   │(4.14)  │(4.21)  │(4.28)  │(5.5)
────────┼─────────┼─────────┼─────────┼─────────┼─────────
  🟢    │   🟢   │   🟡   │   🟡   │   🟡   │   🟡
  AMS   │ 缓存   │  异步  │  异步  │ 测试   │ 灰度上线
  DONE  │ 启动   │  启动  │  完成  │ 验证   │

🟢 = 完成   🟡 = 进行中   🔵 = 规划中   🔴 = 风险
```

---

## 详细日程

### Week 1: 3/31 ~ 4/6（基础准备）

**目标**: 启动市价缓存和DB索引工作

| 日期 | 任务 | 负责方 | SLA |
|------|------|--------|-----|
| 3/31 | ✅ AMS 迁移文件 + Proto 完成 | ams-engineer | DONE |
| 4/1  | 市价缓存架构设计评审 | trading-engineer | Design |
| 4/2  | DB 索引脚本编写 | trading-engineer | Scripts |
| 4/3  | 向 Market Data team 发送 quote 推送需求 | trading-engineer | RFC |
| 4/4  | 向 Fund Transfer team 发送 balance 推送需求 | trading-engineer | RFC |
| 4/5  | Kafka Consumer 框架搭建 | trading-engineer | MVP |
| 4/6  | Redis 缓存键值设计完成 | trading-engineer | Design |

### Week 2: 4/7 ~ 4/13（缓存层实现）

**目标**: 3 个缓存条件实现上生产

| 日期 | 任务 | 优先级 | 预期结果 |
|------|------|--------|---------|
| 4/7  | 市价缓存实现 + 单测 | P0 | 100% 覆盖 |
| 4/8  | AMS 缓存实现 + Kafka 消费 | P0 | 缓存命中率 >95% |
| 4/9  | 余额缓存实现 + 日更新逻辑 | P0 | 5min freshness |
| 4/10 | DB 索引上线（pt-osc） | P0 | 0 downtime |
| 4/11 | 集成测试套件 | P0 | E2E 验证 |
| 4/12 | 性能基准测试 | P1 | POST<300ms baseline |
| 4/13 | Code review + merge to main | P0 | LGTM |

**关键指标**:
- GET /orders P95: <200ms ✓
- GET /positions P95: <200ms ✓
- GET /portfolio/summary P95: <150ms ✓

### Week 3: 4/14 ~ 4/20（撤单异步启动）

**目标**: 撤单异步框架完成 50%

| 日期 | 任务 | 进度 |
|------|------|------|
| 4/14 | DELETE 异步处理框架设计 | Design |
| 4/15 | Cancel Worker + FIX 集成 | Impl |
| 4/16 | WebSocket 事件推送（order.updated） | Impl |
| 4/17 | 单测 + 集成测试 | Testing |
| 4/18 | 性能基准（DELETE P95 目标 <400ms） | Perf |
| 4/19 | Code review | Review |
| 4/20 | Merge to staging | Integration |

**关键指标**:
- POST /orders P95: <300ms ✓
- DELETE /orders P95: <400ms (202 response) ✓
- WebSocket order.updated 推送延迟: <100ms ✓

### Week 4: 4/21 ~ 4/27（撤单异步完成）

**目标**: 所有 5 条件上生产

| 任务 | 状态 |
|------|------|
| 撤单异步生产部署 | ⏳ In Progress |
| Portfolio summary WebSocket 推送 | ⏳ In Progress |
| Settlement updated 事件推送 | ⏳ In Progress |
| 端到端集成测试 | ⏳ Pending |
| 性能验证 | ⏳ Pending |

### Week 5: 4/28 ~ 5/4（压力测试）

**目标**: SLA 验证通过

| 指标 | 目标 | 实测 | 状态 |
|------|------|------|------|
| POST /orders P95 | <300ms | TBD | ⏳ |
| GET /orders P95 | <200ms | TBD | ⏳ |
| DELETE /orders P95 | <400ms | TBD | ⏳ |
| GET /positions P95 | <200ms | TBD | ⏳ |
| GET /portfolio P95 | <150ms | TBD | ⏳ |
| WebSocket order.updated | <100ms | TBD | ⏳ |
| 缓存命中率 | >95% | TBD | ⏳ |
| 错误率 | <0.1% | TBD | ⏳ |

### Week 6: 5/5 ~ 5/11（上线）

**目标**: 灰度 → 全量上线

| 日期 | 阶段 | 进度 |
|------|------|------|
| 5/5  | 灰度 1%（Canary） | Rollout |
| 5/6  | 灰度 5% | Observe |
| 5/7  | 灰度 20% | Monitor |
| 5/8  | 灰度 50% | Validate |
| 5/9  | 灰度 100% | Prepare |
| 5/10 | 全量上线 + 通知 Mobile | Deploy |
| 5/11 | Thread RESOLVED | ✅ |

---

## 依赖关键路径

```
AMS Kafka 事件 (Done 3/31)
        ↓
Kafka Consumer + Redis (Week 1-2, P0)
        ↓
POST/GET SLA 达成 (Week 2, <300ms/<200ms)
        ↓
DELETE 异步 (Week 3-4, <400ms)
        ↓
全量 SLA 验证 (Week 5)
        ↓
灰度上线 (Week 6, 5/11)
```

---

## 风险与缓解

| 风险 | 概率 | 影响 | 缓解方案 |
|------|------|------|---------|
| Market Data Kafka 延迟 | Medium | High | 备用 REST 轮询 fallback |
| Fund Transfer 推送延迟 | Low | Medium | 按需同步拉取 + 缓存刷新 |
| DB 索引 pt-osc 超时 | Low | High | 预演、升级窗口安排 |
| Redis OOM（缓存膨胀） | Low | High | 设置 maxmemory policy + 监控 |
| FIX 超时导致撤单失败 | Medium | High | 异步 retry + WebSocket 推送失败恢复 |

---

## 交付清单（5/11）

- [ ] 5 个技术条件全部上生产
- [ ] SLA 基准测试通过
- [ ] 灰度日志无异常
- [ ] Mobile 端集成验证 ✓
- [ ] Compliance 审查通过
- [ ] Thread RESOLVED + Changelog 更新
