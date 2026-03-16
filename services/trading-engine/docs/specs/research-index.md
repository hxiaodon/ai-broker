# 交易引擎子域调研索引 (Research Index)

> 美港股券商交易引擎 — 深度调研汇总

**文档体系版本**: v1.0  
**最后更新**: 2026-03-16  
**总文档量**: 8 个子域文档，约 13,000+ 行

---

## 快速导航

| 序号 | 子域 | 文档 | 行数 | 核心关键词 |
|------|------|------|------|-----------|
| 01 | 订单管理 (OMS) | [01-order-management.md](domains/01-order-management.md) | 1,456 | 状态机 / 幂等性 / Event Sourcing / CQRS |
| 02 | 预交易风控 | [02-pre-trade-risk.md](domains/02-pre-trade-risk.md) | 1,805 | 购买力 / PDT / Reg SHO / 8道风控门 |
| 03 | 智能路由 (SOR) | [03-smart-order-routing.md](domains/03-smart-order-routing.md) | 1,793 | Reg NMS / NBBO / 多因子评分 / 拆单 |
| 04 | 交易所对接 (FIX) | [04-execution-fix.md](domains/04-execution-fix.md) | 826 | FIX 4.4 / QuickFIX/Go / ExecutionReport |
| 05 | 持仓与盈亏 | [05-position-pnl.md](domains/05-position-pnl.md) | 1,719 | Mark-to-Market / FIFO / 企业行动 |
| 06 | 保证金与融资 | [06-margin.md](domains/06-margin.md) | 2,007 | Reg T / FINRA 4210 / Margin Call / 强平 |
| 07 | 清算与结算 | [07-settlement.md](domains/07-settlement.md) | 1,639 | T+1(US) / T+2(HK) / NSCC / CCASS |
| 08 | 合规与审计 | [08-compliance-audit.md](domains/08-compliance-audit.md) | 1,919 | SEC 17a-4 / CAT / WORM / Event Sourcing |

---

## 跨子域依赖关系图

```
                    ┌─────────────────────────────────────┐
                    │           外部依赖服务                │
                    │                                     │
                    │  AMS (账户/KYC)  Market Data (行情) │
                    └──────────┬──────────────┬───────────┘
                               │              │
                  账户状态/权限 │              │ 实时报价
                               │              │
                    ┌──────────▼──────────────▼──────────────────────────────────┐
                    │                    交易引擎核心                              │
                    │                                                             │
                    │   ┌──────────────────────────────────────────────────┐     │
                    │   │              订单管理 (OMS) [01]                  │     │
                    │   │         所有其他子域的协调入口                     │     │
                    │   └────────────────────┬─────────────────────────────┘     │
                    │                        │                                    │
                    │           ┌────────────▼────────────┐                      │
                    │           │  预交易风控 [02]          │                     │
                    │           │  ← 依赖 Market Data 报价  │                     │
                    │           │  ← 依赖 OMS 持仓状态      │                     │
                    │           │  ← 依赖 Margin Engine    │                     │
                    │           └────────────┬────────────┘                      │
                    │                        │                                    │
                    │           ┌────────────▼────────────┐                      │
                    │           │  智能路由 (SOR) [03]      │                     │
                    │           │  ← 依赖 Market Data NBBO  │                     │
                    │           └────────────┬────────────┘                      │
                    │                        │                                    │
                    │           ┌────────────▼────────────┐                      │
                    │           │  交易所对接 FIX [04]      │                     │
                    │           │  → NYSE / NASDAQ / HKEX  │                     │
                    │           └────────────┬────────────┘                      │
                    │                        │ ExecutionReport                    │
                    │           ┌────────────▼────────────┐                      │
                    │           │  持仓与盈亏 [05]          │                     │
                    │           │  ← 依赖 Market Data 报价  │                     │
                    │           │  → 触发 Settlement       │                     │
                    │           └────────────┬────────────┘                      │
                    │            │           │                                    │
                    │   ┌────────▼───┐  ┌───▼────────────┐                      │
                    │   │ 保证金 [06] │  │  结算 [07]      │                     │
                    │   │ ← 依赖持仓  │  │ → Fund Transfer│                     │
                    │   └────────────┘  └────────────────┘                      │
                    │                                                             │
                    │   ┌────────────────────────────────────────────────┐       │
                    │   │          合规与审计 [08]（横切关注点）            │       │
                    │   │  监听所有子域的 Kafka 事件，写入不可变审计日志     │       │
                    │   └────────────────────────────────────────────────┘       │
                    └─────────────────────────────────────────────────────────────┘
                                                │
                    ┌───────────────────────────▼───────────────────────────┐
                    │                     下游服务                           │
                    │                                                        │
                    │  Fund Transfer (结算资金划转)  Mobile (订单状态推送)    │
                    │  Admin Panel (风险监控)         Compliance (合规报告)   │
                    └────────────────────────────────────────────────────────┘
```

### 关键依赖链

| 子域 | 上游依赖 | 下游触发 |
|------|---------|---------|
| OMS [01] | AMS（账户）, Market Data（标的） | Risk [02], SOR [03], Position [05], Audit [08] |
| Pre-Trade Risk [02] | OMS [01], Market Data（实时报价）, Position [05], Margin [06] | OMS（通过/拒绝） |
| SOR [03] | Market Data（NBBO/L2）, FIX Session 状态 | FIX Engine [04] |
| FIX Engine [04] | SOR [03] | Position [05], Settlement [07], Audit [08] |
| Position [05] | FIX Engine（成交回报）, Market Data（行情） | Margin [06], Settlement [07] |
| Margin [06] | Position [05]（持仓市值）, Risk [02]（Margin Check）| OMS（购买力）, 强平 |
| Settlement [07] | Position [05]（成交记录）| Fund Transfer（资金划转） |
| Audit [08] | 所有子域（Kafka 事件）| 无（只写） |

---

## 关键合规检查清单（PRD Review 用）

### 美股合规

| 法规 | 要求 | 涉及子域 | 验收标准 |
|------|------|---------|---------|
| **Reg NMS Rule 611** | 禁止 Trade-Through，必须路由到 NBBO | SOR [03] | trade_through_count = 0 |
| **FINRA Rule 5310** | Best Execution 举证，路由决策记录 | SOR [03] | 每笔订单 routing_decision 不为空 |
| **PDT Rule** | 5日内4+日内交易 → 最低$25K权益 | Risk [02] | day_trade_counts 正确计数 |
| **Reg T** | 保证金账户初始保证金50% | Margin [06] | margin_rate >= 50% |
| **FINRA Rule 4210** | 维持保证金25%（多头）| Margin [06] | Margin Call 在 <25% 时触发 |
| **Reg SHO** | 卖空前需 Locate（借券定位）| Risk [02], FIX [04] | 卖空订单有 locate token |
| **SEC 17a-4** | 订单记录7年 WORM 保留 | OMS [01], Audit [08] | S3 Object Lock Compliance |
| **CAT 上报** | 每日 T+1 08:00 ET 向 FINRA 上报 | Audit [08] | CAT 文件按时生成 |
| **T+1 结算** | 美股 T+1 结算（2024年5月起）| Settlement [07] | settlement_date = trade_date + 1 |

### 港股合规

| 法规 | 要求 | 涉及子域 | 验收标准 |
|------|------|---------|---------|
| **SFC Code of Conduct** | 最优执行义务 | SOR [03] | 所有港股订单路由到 HKEX |
| **SFO（证券及期货条例）** | 交易记录6年保留 | Audit [08] | 同 SEC 17a-4 架构 |
| **AMLO（洗黑钱条例）** | 可疑交易上报 JFIU | Audit [08] | STR 生成和上报流程 |
| **T+2 结算** | 港股 T+2 结算 | Settlement [07] | settlement_date = trade_date + 2 |
| **HKEX 订单规则** | 整手数量，收市竞价限价单 | OMS [01] | quantity % lot_size == 0 |

---

## 性能指标汇总

| 子域 | 关键指标 | P50 目标 | P99 目标 |
|------|---------|---------|---------|
| OMS [01] | 订单提交到风控通过 | 2ms | 5ms |
| Pre-Trade Risk [02] | 8道风控门全通过 | 2ms | 5ms |
| SOR [03] | 路由决策（含报价获取）| 3ms | 10ms |
| FIX Engine [04] | FIX 发出到 New 确认 | 1ms | 3ms |
| Position [05] | 成交到持仓更新 | 1ms | 3ms |
| P&L [05] | 行情变动到 P&L 刷新 | <1ms | 1ms |
| Margin [06] | 实时保证金监控（触发式）| 5ms | 20ms |
| Settlement [07] | 每日结算批处理（全量）| N/A | <30min |
| Audit [08] | 事件写入 Kafka | <1ms | 2ms |
| **系统端到端** | **用户下单到FIX发出** | **<10ms** | **<20ms** |

---

## 技术选型决策记录

### 为什么选 Go

| 优势 | 说明 |
|------|------|
| goroutine 并发模型 | 天然适合大量并发的订单处理和 FIX Session 管理 |
| 低延迟 GC | Stop-the-world 时间短（<1ms），适合毫秒级延迟要求 |
| shopspring/decimal | 精确小数处理，避免浮点精度问题（金融核心要求）|
| QuickFIX/Go | 成熟的 FIX 协议库，与 Java QuickFIX/J 接口一致 |

### 为什么选 MySQL（而非 PostgreSQL）

注意：`001_init_trading.sql` 使用了 PostgreSQL 语法（BIGSERIAL, TIMESTAMPTZ, JSONB, PARTITION BY RANGE），但 `CLAUDE.md` 说明使用 MySQL 8.0+。

实际上 MySQL 8.0 支持：
- `BIGINT AUTO_INCREMENT`（对应 BIGSERIAL）
- `DATETIME(3)`（毫秒精度，对应 TIMESTAMPTZ）
- `JSON`（对应 JSONB，但无索引优化）
- `PARTITION BY RANGE (YEAR(created_at))`（月分区略有差异）

**注意**：当前 schema 迁移脚本使用 PostgreSQL 语法，若使用 MySQL 需要调整。

### 为什么选 Redis 作为热路径缓存

| 用途 | 说明 |
|------|------|
| 购买力缓存（60s TTL）| 避免每次下单都计算 |
| 幂等 Key（72h TTL）| 防止重复下单 |
| 实时持仓缓存 | P&L 毫秒响应 |
| 断路器状态（跨实例共享）| SOR 断路器 |
| PDT 计数缓存 | 避免频繁 DB 查询 |

### 为什么选 Kafka 作为事件总线

| 优势 | 说明 |
|------|------|
| append-only 日志 | 天然适合审计追踪（不可删除）|
| 高吞吐量 | 支持 10,000+ events/s |
| Consumer Group | Position Engine / Settlement Engine / Audit 各自独立消费 |
| Retention 可配置 | 可设置 7 年保留（合规审计） |

### 为什么选 QuickFIX/Go（而非自研 FIX）

- FIX 协议细节复杂（序列号管理、GapFill、HeartBeat），自研风险极高
- QuickFIX 系列（Java/Go/C++）是行业标准，经过数千家机构验证
- 缺点：封装层较厚，调试时需要理解 QuickFIX 内部机制

---

## Kafka Topics 汇总

| Topic | Producer | Consumer | 用途 |
|-------|---------|---------|------|
| `order.created` | OMS | Audit | 新订单审计 |
| `order.risk_approved` | Risk Engine | SOR | 触发路由 |
| `order.risk_rejected` | Risk Engine | Audit, Mobile | 拒单通知 |
| `order.route_decided` | SOR | FIX Engine | 触发发单 |
| `order.submitted` | FIX Engine | OMS | 更新状态为 PENDING |
| `order.open` | FIX Engine | OMS, Mobile | 交易所已确认 |
| `order.partially_filled` | FIX Engine | Position, Settlement, Mobile | 部分成交 |
| `order.filled` | FIX Engine | Position, Settlement, Mobile | 完全成交 |
| `order.cancelled` | FIX Engine | OMS, Mobile | 撤单确认 |
| `order.exchange_rejected` | FIX Engine | OMS, Mobile | 交易所拒单 |
| `position.updated` | Position Engine | Mobile, Margin, Audit | 持仓变更 |
| `margin.call_triggered` | Margin Engine | Mobile, Compliance | Margin Call |
| `settlement.completed` | Settlement Engine | Fund Transfer, Audit | 结算完成 |
| `audit.event` | 所有子域 | Audit Sink (ES/S3) | 合规审计 |

---

## 数据模型关键表汇总

| 表名 | 主要用途 | 关键字段 | 注意事项 |
|------|---------|---------|---------|
| `orders` | 订单主表 | order_id(UUID), status, idempotency_key | 按月分区 |
| `executions` | 成交明细 | execution_id, settlement_date, settled | 按 settlement_date 索引 |
| `order_events` | 事件溯源 | event_id, order_id, event_type, sequence | Append-Only，不可更新 |
| `positions` | 持仓 | account_id+symbol+market 唯一, version | 乐观锁（version 字段）|
| `margin_snapshots` | 保证金历史 | account_id, margin_call_status, calculated_at | 仅追加，不更新 |
| `day_trade_counts` | PDT 计数 | account_id, trade_date, symbol, count | 唯一索引防重复 |
| `fee_configs` | 费率配置 | market, name, rate_type, rate, effective_from | 支持费率历史版本 |
| `corporate_actions` | 企业行动 | symbol, ex_date, action_type, status | 需要在 ex_date 前处理 |

---

## 已知设计风险与待解决问题

| 风险 | 描述 | 建议解决方案 | 优先级 |
|------|------|------------|--------|
| **DB 方言不一致** | `001_init_trading.sql` 使用 PostgreSQL 语法，但项目规定 MySQL 8.0 | 重写迁移脚本为 MySQL 语法 | 高 |
| **CAT 时间戳精度** | FIX TransactTime 仅精确到毫秒，CAT 要求微秒 | 在 ExecutionReport 处理时记录服务器接收时间（微秒）| 中 |
| **断路器跨实例共享** | 多 Pod 部署时断路器状态不一致 | 使用 Redis 存储断路器状态 | 中 |
| **结算日历** | 美股/港股节假日需要专门维护 | 集成金融日历库或维护静态日历配置 | 中 |
| **Margin Call 强平优先级** | 哪个持仓先平的算法未最终确定 | 按"保证金贡献度/流动性"综合评分 | 低 |
| **港股暗盘交易** | 8:00-9:20 HKT 的暗盘成交不通过 HKEX，需要特殊处理 | 暗盘独立通道，或不支持 | 低 |

---

## 文档维护说明

- 每个子域文档独立维护，变更时只需更新对应文档
- 本索引文档在子域文档有重大变更时同步更新
- 合规要求变更（如 SEC 费率调整、CAT 规则更新）需优先更新对应子域文档
- 相关代码变更后，应检查子域文档中的代码示例是否需要同步更新
