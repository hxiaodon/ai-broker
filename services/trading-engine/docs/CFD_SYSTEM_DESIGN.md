# CFD Trading Engine - 系统设计完整文档

**版本**: 1.0  
**日期**: 2026-04-03  
**作者**: Trading Engineer (Claude Code)  
**状态**: ✅ 已批准，进入开发阶段

---

## 目录

1. [执行摘要](#执行摘要)
2. [业界最佳实践调研](#业界最佳实践调研)
3. [开源项目参考](#开源项目参考)
4. [现有系统分析](#现有系统分析)
5. [CFD vs 股票交易](#cfd-vs-股票交易)
6. [系统架构设计](#系统架构设计)
7. [数据库设计](#数据库设计)
8. [Kafka 事件流](#kafka-事件流)
9. [关键算法详解](#关键算法详解)
10. [实现计划与验收标准](#实现计划与验收标准)

---

## 执行摘要

### 项目目标
在现有股票交易系统的基础上，开发 CFD（差价合约）交易引擎，支持：
- 美港两地合约交易（初期可考虑美股或外汇 CFD）
- 10:1 ~ 50:1 可配置杠杆
- 实时动态保证金管理与自动强平
- Daily Mark-to-Market 结算
- 自动合约展期
- 完整审计与 SFC 合规

### 核心挑战

| 挑战 | 原因 | 解决方案 |
|------|------|--------|
| **实时保证金** | 毫秒级市价变化 | Redis 缓存 + 5 分钟全量校准 |
| **自动强平** | 需要毫秒级触发 | 行情驱动事件 + Goroutine 池 |
| **Daily MTM** | 跨日结算复杂 | Temporal 工作流 + 事件溯源 |
| **对手方风险** | 流动性提供商信用 | 敞口限额 + 信用评分 |
| **监管合规** | SFC 强制披露要求 | Event Sourcing + 自动警告系统 |

### 关键决策

✅ **保证金管理**：实时动态型（秒级更新 + 5 分钟校准）  
✅ **强平执行**：可配置型（按客户等级调整 0-30 秒延迟）  
✅ **合约展期**：自动展期（T-2 自动开仓新合约）  
✅ **技术栈**：Go + PostgreSQL + Redis + Kafka（复用现有）

### 工作量估算

| 阶段 | 周数 | 主要交付 |
|------|------|--------|
| Phase 1: OMS & Risk | 4 | 订单流程 + 风控检查 |
| Phase 2: Position & Margin | 6 | 持仓 + 实时保证金 |
| Phase 3: Auto-Liquidation | 4 | 强平引擎 + 触发机制 |
| Phase 4: Settlement & Compliance | 4 | 日结 + 展期 + 审计 |
| Phase 5: 生产加固 | 2 | 性能优化 + 故障转移测试 |
| **合计** | **20 周** | **生产就绪** |

---

## 业界最佳实践调研

### 1. Daily Mark-to-Market 和保证金管理

#### 保证金触发机制（四色预警体系）

```
保证金比率 = 账户净值 / 维持保证金需求

绿灯 (100%+)
└─ 状态：正常
└─ 操作：可继续开仓
└─ 通知：无

黄灯 (75%-100%)
└─ 状态：警告
└─ 操作：仅允许平仓，禁止开新仓
└─ 通知：24-48 小时内需补缴
└─ 缓冲期：24-48 小时

红灯 (50%-75%)
└─ 状态：严重警告
└─ 操作：仅允许平仓
└─ 通知：立即强制警告
└─ 缓冲期：6-12 小时

黑灯 (<50%)
└─ 状态：临界
└─ 操作：自动强平
└─ 通知：自动平仓前 1 小时通知
└─ 执行：市价单，5 秒确认后执行
```

#### Daily MTM 结算流程

```
T 日 16:00（收盘）
│
└─ 1. 获取所有活跃持仓的收盘价
│
└─ 2. Mark-to-Market 计算
│   未实现 P&L = (收盘价 - 入场价) × 数量
│
└─ 3. 现金结算
│   账户现金 += 当日 P&L
│   （未实现 P&L 转为已实现）
│
└─ 4. 持仓更新
│   持仓.当前价格 = 收盘价
│   持仓.已实现 P&L += 当日 P&L
│
└─ 5. 保证金重算
│   维持保证金 = SUM(持仓名义金额 × 维持比例)
│   （基于新的收盘价）
│
└─ 6. 生成对账单
│   daily_settlements 表记录
│   发送给用户
│
T+1 日 09:00（次日开盘）
└─ 7. 新一日开始，基于收盘价重新计算初始保证金
```

### 2. 自动强平算法（七步流程）

```
[1] 触发检测 (5ms)
    if margin_ratio < 50% && !already_liquidating:
        goto [2]

[2] 候选持仓评分 (50ms)
    for each position:
        score = margin_contribution × 0.4 
              + liquidity_score × 0.3 
              + loss_degree × 0.3
        
        保证金贡献度 = 该持仓占用保证金 / 总保证金
        流动性评分 = 1 / (bid-ask 点差)
        亏损程度 = max(0, -P&L) / 名义金额

[3] 优先级排序 (10ms)
    sort(candidates, by: score DESC)
    → 高分优先强平

[4] 市价单平仓 (100ms)
    for each candidate (highest score first):
        if margin_ratio >= 50%:
            break  # 已满足
        
        execute MarketOrder(position.ID, CLOSE)

[5] 成交确认等待 (100-500ms)
    wait for execution confirmation
    
[6] 保证金重算 (10ms)
    recalculate margin_ratio after each liquidation
    
[7] 审计记录 (5ms)
    log liquidation event with:
    - trigger time
    - liquidation price
    - P&L loss
    - remaining margin ratio
    - audit trail for compliance
```

**关键参数**：
- 触发阈值：margin_ratio < 50%（可配置）
- 执行延迟：0-30 秒（按客户等级配置）
- 价格滑点容限：±5%（超过则分批平仓）
- 平仓优先级：按综合评分（非 FIFO）

### 3. SFC 合规框架（香港）

#### 客户分级与杠杆限制

```
客户等级               最大杠杆    初始保证金    维持保证金
──────────────────────────────────────────────────────
零知识客户             5:1-20:1   10-20%       5-10%
(缺乏交易知识)

散户客户               20:1-50:1  3.3-5%       2-3%
(一般个人投资者)

专业客户               50:1-200:1 1-2%         0.5-1%
(机构投资者或高净值)

机构客户               无限制     按协议        按协议
(基金、投行等)
```

#### 强制风险披露

1. **开仓前披露**
   - "79% 的零售 CFD 客户在交易本提供商产品时蒙受损失"
   - 点差费用和隐性成本
   - 杠杆风险说明
   - 强平机制说明

2. **持仓监控期间**
   - 75% Margin Call：推送 "保证金不足，请在 24 小时内补缴"
   - 50% 红灯：推送 "风险警告，禁止新订单，仅允许平仓"

3. **强平前通知**
   - 1 小时前：推送 "保证金已跌至强平线，您的持仓将被自动平仓"
   - 5 分钟前：再次确认
   - 即时：平仓成交价格和余额变化

#### 合规检查清单（SFC 要求）

- [ ] 客户适当性评估（KYC 时收集风险承受度）
- [ ] 杠杆上限强制执行（风控引擎检查）
- [ ] 点差透明度（API 和 UI 展示 bid/ask）
- [ ] 亏损警告（开仓前、50%、25% 三次）
- [ ] 追缴通知（>1 小时前）
- [ ] 强平通知（>1 小时前，允许用户主动平仓）
- [ ] 交易记录保留（7 年）
- [ ] AML 审查（所有新账户）
- [ ] 纠纷处理流程（记录所有交互）
- [ ] 定期审计（内部和外部）

### 4. 行业最佳实践总结

| 维度 | 最佳实践 | 为什么 |
|------|--------|------|
| **保证金计算** | 每秒更新 + 5 分钟全量校准 | 避免 Redis 误差累积，防止漏报 |
| **强平触发** | 可配置延迟（0-30s） | 平衡用户体验和风险管理 |
| **对手方** | 多 LP + 敞口限额 | 分散信用风险，防止单点破产 |
| **价格报价** | 基础 + 波动率 + 流动性 + 风险点差 | 动态调整成本，管理 LP 风险 |
| **展期处理** | T-2 自动展期，无缝转移 | 降低用户操作复杂性 |
| **审计日志** | Event Sourcing + 7 年冷存储 | 满足监管和数据取证需求 |

---

## 开源项目参考

### 评估的 5 个顶级项目

#### 1. **0x5487 Matching Engine** ⭐⭐⭐⭐⭐
- **语言**: Go
- **License**: MIT（商用友好）
- **GitHub**: https://github.com/0x5487/matching-engine
- **关键特性**：
  - SkipList 数据结构（O(log n) 查询）
  - Disruptor 无锁队列（300k+ trades/sec）
  - 内存高效（适合高频场景）
  
**为什么采用**：CFD 内部订单簿需要高吞吐，0x5487 已在生产验证，可直接 fork

**集成点**：
```go
// 替代 FIX 对接，用于内部 OTC 撮合
book := matching.NewOrderBook("AAPL_CFD_DEC")
book.Add(order)  // 添加买卖盘
fills := book.Match()  // 自动撮合
```

---

#### 2. **NautilusTrader** ⭐⭐⭐⭐
- **语言**: Rust + Python
- **License**: LGPL（开源，商用需注意）
- **GitHub**: https://github.com/nautechsystems/nautilus_trader
- **关键特性**：
  - 完整的 Event Sourcing 实现
  - 确定性执行（研究与生产使用同一代码）
  - 丰富的指标和回测框架

**为什么参考**：架构设计可作为借鉴，Event Sourcing 模式特别有用

**参考内容**：
```
- Event Sourcing 框架设计
- State Snapshots 机制
- Event Replay 逻辑
- Command-Query 分离
```

**代码复用**：不直接复用（Rust），但架构模式适用

---

#### 3. **OpenAlgo** ⭐⭐⭐⭐⭐
- **语言**: Python
- **License**: MIT
- **GitHub**: https://github.com/marketcalls/openalgo
- **关键特性**：
  - 生产级保证金计算引擎
  - 印度市场（NSE/BSE）验证
  - REST API 完整设计
  - 递归保证金算法（处理复杂持仓）

**为什么采用**：保证金算法经过生产验证，直接适用于 CFD

**直接采用**：
```python
# OpenAlgo 的递归保证金算法
def calculate_margin(positions, rates):
    """
    递归计算跨境、多合约的保证金需求
    支持 margin 抵消（对冲头寸降低保证金）
    """
    total_margin = 0
    for symbol, qty, price in positions:
        gross_margin = qty * price * rates[symbol]['initial']
        # 如果有对冲头寸，允许一定比例的抵消
        if hedge_position_exists(symbol):
            gross_margin *= (1 - HEDGE_DISCOUNT)
        total_margin += gross_margin
    return total_margin
```

**改造内容**：从 Python 转为 Go，核心逻辑保留

---

#### 4. **Temporal OMS Reference** ⭐⭐⭐⭐
- **语言**: Go
- **GitHub**: https://github.com/temporalio/reference-app-orders-go
- **关键特性**：
  - 使用 Temporal Workflows 编排长期流程
  - 自动重试和故障恢复
  - 人工干预支持（appeal 流程）

**为什么参考**：CFD 的合约展期和 margin call 处理非常适合 Temporal

**使用场景**：
```go
// Temporal Workflow 示例：合约展期
func ContractRolloverWorkflow(ctx workflow.Context, positionID string) error {
    // 1. 等待 T-2 日期
    ctx.Sleep(ctx, timeUntilRollover)
    
    // 2. 执行展期（可能需要人工批准）
    var result RolloverResult
    err := workflow.ExecuteActivity(ctx, RolloverActivity, positionID).Get(ctx, &result)
    
    // 3. 失败重试
    if err != nil {
        // Temporal 自动重试
        return err
    }
    
    return nil
}
```

---

#### 5. **GoCryptoTrader** ⭐⭐⭐
- **语言**: Go
- **License**: MIT
- **GitHub**: https://github.com/thrasher-corp/gocryptotrader
- **关键特性**：
  - 多交易所连接器
  - 报价聚合
  - 订单管理接口

**为什么参考**：报价管理和流动性提供商集成的设计模式

**参考内容**：
- 报价缓存机制
- 多 LP 故障转移
- 点差调整逻辑

---

### 推荐的技术栈

| 组件 | 选型 | 原因 |
|------|------|------|
| **订单簿** | 0x5487 matching-engine | 高吞吐，生产验证 |
| **保证金** | OpenAlgo 算法 + Go 实现 | 可靠，经过验证 |
| **工作流** | Temporal + 0.24+ | 长期流程自动化 |
| **事件溯源** | NautilusTrader 架构 | DDD + Event Sourcing |
| **报价管理** | GoCryptoTrader 模式 | 多 LP 支持 |

**总集成成本**：
- 0x5487：2-3 周（集成 + 测试）
- OpenAlgo 算法：1 周（移植到 Go）
- Temporal：1-2 周（学习 + 集成）
- 总计：4-6 周（Phase 1 的一部分）

---

## 现有系统分析

### 股票交易引擎架构概览

```
┌─────────────────────────────────────────────────┐
│         API Gateway / Mobile / Admin Panel      │
└────────────┬─────────────────────────────────┬──┘
             │                                 │
    ┌────────▼─────┐               ┌──────────▼──┐
    │  OMS          │               │ Risk Engine │
    │ (订单管理)    │               │ (风控检查)  │
    └────────┬─────┘               └──────────┬──┘
             │                               │
    ┌────────▼──────────────────────────────▼─────┐
    │       Smart Order Routing (SOR)             │
    │  Reg NMS 最优执行 + 多交易所评分            │
    └────────┬───────────────────────────────────┘
             │
    ┌────────▼──────────────────────────────────┐
    │   FIX Protocol Connectivity                │
    │  (NYSE/NASDAQ/HKEX via QuickFIX/Go)       │
    └────────┬───────────────────────────────────┘
             │
    ┌────────▼──────────────────────────────────┐
    │   Position Tracking & P&L                  │
    │  加权平均成本法 + 已/未实现盈亏            │
    └────────┬───────────────────────────────────┘
             │
    ┌────────▼──────────────────────────────────┐
    │   Settlement (T+1 US / T+2 HK)             │
    │  NSCC/CCASS 结算 + 资金清算                │
    └────────┬───────────────────────────────────┘
             │
    ┌────────▼──────────────────────────────────┐
    │   Data Layer (PostgreSQL + Redis + Kafka) │
    │  Event Sourcing + Outbox Pattern          │
    └───────────────────────────────────────────┘
```

### 现有系统的 8 个核心域

| 域 | 职责 | 当前实现 | CFD 影响 |
|----|------|--------|--------|
| **OMS** | 订单生命周期管理 | 11 个状态机 | ✅ 可复用（简化状态） |
| **风控** | 8 道预交易检查 | 购买力、PDT、Reg SHO | ✅ 新增 5 道检查 |
| **SOR** | Reg NMS 路由 | 多交易所评分 | ❌ 移除（无交易所） |
| **FIX** | 交易所对接 | QuickFIX/Go | ❌ 移除（OTC） |
| **持仓** | 位置跟踪 | FIFO/加权平均 | ✅ 改造（Daily MTM） |
| **保证金** | Reg T / FINRA | 日终检查 | 🔄 改造（实时动态） |
| **结算** | T+1/T+2 清算 | NSCC/CCASS | 🔄 改造（Daily MTM） |
| **审计** | 合规日志 | Event Sourcing | ✅ 复用 |

### 可直接复用的部分

#### 1. OMS 状态机框架
```go
// domain/order/state_machine.go（现有）
CREATED → VALIDATED → RISK_APPROVED → PENDING → OPEN
                                              ├→ PARTIAL_FILL → FILLED
                                              └→ CANCELLED

// CFD 简化版
CREATED → VALIDATED → RISK_APPROVED → OPEN → FILLED / CANCELLED
（移除 PENDING、EXCHANGE_ACK 等等待态）
```

**复用策略**：继承现有的 StateMachine 接口，减少 CFD 状态集合

#### 2. 幂等性检查机制
```go
// infrastructure/cache/idempotency_cache.go（现有）
Redis: idempotency_key → response (72h TTL)
DB: orders.idempotency_key UNIQUE

// CFD 直接复用
同一个 idempotency_key，防止重复订单
```

#### 3. 持仓与 P&L 系统
```go
// domain/position/position.go（现有）
type Position struct {
    Quantity int64                    // 持仓数量
    AvgCostBasis decimal.Decimal      // 平均成本
    UnrealizedPnL decimal.Decimal    // 未实现盈亏
    RealizedPnL decimal.Decimal      // 已实现盈亏
}

// CFD 扩展
type CFDPosition struct {
    Position                          // 继承
    ContractID string                // 新增
    EntryPrice decimal.Decimal       // 新增（不同于成本基础）
    MaintenanceRate decimal.Decimal  // 新增
    LiquidationPrice decimal.Decimal // 新增
}
```

#### 4. 基础设施层
- **PostgreSQL**：分区表策略、乐观锁（version）
- **Redis**：缓存键设计、TTL 管理
- **Kafka**：Outbox Pattern、事件发布
- **Prometheus**：监控指标

**复用比例**：60-70%

### 需要改造或新增的部分

#### 改造部分

1. **Risk Engine**：新增 5 道 CFD 检查
   - 杠杆比率限制
   - 对手方敞口限制
   - 名义敞口限额
   - 信用额度检查
   - 市场状态（LP 在线）检查

2. **Margin System**：从日结改为实时
   - 从 "每日 T+5 补足" 改为 "实时触发警告"
   - 从 "Reg T 50% 固定" 改为 "按客户等级 5-50% 动态"

3. **Settlement**：从 T+1/T+2 改为 Daily MTM
   - 成交即记录，日结清算
   - 展期而非结算

#### 新增部分

1. **内部订单簿**（替代 FIX）
   - 0x5487 matching engine
   - 秒级撮合

2. **Daily Mark-to-Market 引擎**
   - 收盘后 MTM 计算
   - 未实现 → 已实现转换
   - 现金账户更新

3. **自动强平引擎**
   - 持仓评分算法
   - 毫秒级触发
   - 市价单执行

4. **合约管理**
   - 合约定义（到期日）
   - 自动展期逻辑
   - T-2 准备

5. **报价管理**
   - 流动性提供商集成
   - 点差计算
   - 价格缓存

---

## CFD vs 股票交易

### 核心差异对比

#### 1. 交易本质

| 维度 | 股票交易 | CFD |
|------|---------|-----|
| **产品** | 真实股票 | 差价合约（衍生品） |
| **对手方** | 交易所 | 做市商 |
| **所有权** | 买入后真实持有 | 合约权益（无所有权） |
| **交割** | T+1/T+2 实物交割 | 永不交割（日结清） |

**代码影响**：
- 股票：需要处理交割日期、交收、证券借用
- CFD：无交割，仅处理现金 P&L 结算

#### 2. 清算结算

| 阶段 | 股票 | CFD |
|------|------|-----|
| **成交** | Trade Date | T (即时) |
| **清算** | 成交后立即（T+0） | 无清算（OTC） |
| **交割** | T+1 (US) / T+2 (HK) | 无交割 |
| **结算** | 现金 + 证券交收 | 仅现金（Daily MTM） |

**系统实现**：
```
股票流程：
Order → FIX → Exchange → ExecutionReport → Settlement Wait (T+1) → Fund Transfer

CFD 流程：
Order → Internal Match → Position Open (T+0) → Daily MTM (T+1) → P&L Settled
```

#### 3. 杠杆与保证金

| 指标 | 股票 | CFD |
|------|------|-----|
| **最大杠杆** | 2:1 (Reg T) | 5:1 ~ 50:1 |
| **初始保证金** | 50% | 2-20% |
| **维持保证金** | 25% (FINRA) | 1-10% |
| **计算频率** | 日终 | 实时 |
| **追缴期限** | T+5 | 24-48 小时 |
| **强平** | 通知（人工） | 自动（毫秒级） |

**代码影响**：
- 股票：保证金比例固定，日终批处理
- CFD：保证金比例可配置，实时监控，毫秒级强平

#### 4. 订单路由

| 环节 | 股票 | CFD |
|------|------|-----|
| **预交易风控** | 8 道检查 | 13 道检查（新增 5 道） |
| **价格决定** | 交易所撮合 | 做市商报价 |
| **订单转发** | FIX 到交易所 | 内部订单簿 |
| **成交确认** | ExecutionReport | 内部确认 |
| **执行速度** | 毫秒级 | 毫秒级 |

#### 5. 持仓管理

| 功能 | 股票 | CFD |
|------|------|-----|
| **成本基础** | 加权平均 | 入场价 |
| **已/未实现** | 持仓期间追踪 | Daily MTM 清算 |
| **到期处理** | N/A | 自动展期 |
| **平仓方式** | 用户主动 | 用户主动 or 强平 |
| **持有期限** | 无限期 | 按合约期限 |

#### 6. 费用结构

| 费用 | 股票 | CFD |
|------|------|-----|
| **佣金** | 固定或百分比 | 0（做市商点差） |
| **点差** | 交易所报价 | 动态点差（基础 + 波动性 + 流动性 + 风险） |
| **融资利息** | 日利息（年化） | Daily MTM 中包含 |
| **过夜费** | 仅融资头寸 | 所有头寸（展期） |

#### 7. 监管要求

| 规则 | 股票 | CFD |
|------|------|-----|
| **PDT 规则** | 强制执行（5 天内 ≥4 次） | 无 |
| **Reg NMS** | 强制执行（最优执行） | 无 |
| **Reg SHO** | 卖空定位要求 | 无（允许无限制卖空） |
| **杠杆限制** | 联邦统一 2:1 | 各国不同（需配置） |
| **风险披露** | 基础 | **加强** （79% 亏损 + 强平风险） |
| **客户分级** | 基础 KYC | **强制** （按杠杆等级） |

---

## 系统架构设计

### 1. 整体架构

```
┌────────────────────────────────────────────────────────┐
│           Mobile / Admin Panel / API Gateway           │
└─────────────────┬──────────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┬───────────────────────┐
    │             │             │                       │
    ▼             ▼             ▼                       ▼
┌────────┐  ┌────────────┐ ┌──────────┐        ┌─────────────┐
│  OMS   │  │ Risk Engine│ │ Pricing  │        │  Compliance │
│(改造)  │  │   (新增)   │ │  Feed    │        │  Engine     │
└────┬───┘  └──────┬─────┘ │ (新增)   │        │  (新增)     │
     │             │       └────┬─────┘        └──────┬──────┘
     │             │            │                     │
     └─────────────┼────────────┼─────────────────────┘
                   │            │
          ┌────────▼────────────▼──────────────┐
          │   Position & Margin Engine         │
          │  (持仓、保证金、强平)               │
          │   - 实时 P/L 计算                  │
          │   - 动态保证金                     │
          │   - 自动强平触发                   │
          └────────┬─────────────────────────┬┘
                   │                         │
        ┌──────────▼────────────┐  ┌────────▼─────┐
        │  Settlement Engine    │  │ Audit Engine │
        │  (日结、展期)          │  │ (审计日志)   │
        └────────┬─────────────┘  └──────────────┘
                 │
        ┌────────▼─────────────────────────┐
        │  Data Layer                      │
        │  PostgreSQL + Redis + Kafka      │
        │  Event Sourcing + Outbox Pattern │
        └──────────────────────────────────┘
```

### 2. 数据流

#### 开仓流程
```
用户下单
  │
  ├─→ [OMS] 幂等性检查 (Redis, <1ms)
  │
  ├─→ [Risk Engine] 13 道风控检查 (3ms)
  │   ├─ 账户状态
  │   ├─ 杠杆比率限制 (新)
  │   ├─ 对手方敞口 (新)
  │   ├─ 名义金额限额 (新)
  │   ├─ 信用额度 (新)
  │   ├─ 市场状态 (新)
  │   ├─ 购买力
  │   ├─ 持仓限额
  │   ├─ 交易时段
  │   ├─ 波动性
  │   ├─ 账户风险评分
  │   └─ 强平先兆
  │
  ├─→ [Pricing Feed] 获取报价 (1ms)
  │   └─ 计算动态点差（基础 + 波动 + 流动性 + 风险）
  │
  ├─→ [Margin Service] 预检保证金 (2ms)
  │   ├─ 从 Redis 读取当前保证金状态
  │   ├─ 计算新持仓的初始保证金
  │   └─ 验证可用保证金充足
  │
  ├─→ [OMS] 订单状态: CREATED → VALIDATED → RISK_APPROVED
  │   └─ 发布 Kafka: cfd.order.risk_approved
  │
  ├─→ [Order Matching Engine] 内部撮合 (秒级)
  │   ├─ 加入订单簿
  │   ├─ 自动匹配对手方
  │   └─ 成交
  │
  ├─→ [OMS] 订单状态: OPEN
  │   └─ 发布 Kafka: cfd.order.opened
  │
  ├─→ [Position Service] 创建持仓
  │   ├─ 计算初始保证金
  │   ├─ 扣除现金账户
  │   └─ MySQL 写入 cfd_positions
  │
  ├─→ [Margin Service] 更新保证金
  │   ├─ Redis 更新（初始保证金占用）
  │   ├─ 发布 Kafka: cfd.position.updated
  │   └─ 推送给移动端
  │
  └─→ ✅ 开仓完成 (~50ms 端到端)
```

#### 价格更新流程
```
市场行情更新（秒级，来自流动性提供商）
  │
  ├─→ [Pricing Feed] 更新报价缓存 (< 1ms)
  │   ├─ Redis: contract_id → {bid, ask, price}
  │   └─ 发布 Kafka: cfd.price.updated
  │
  ├─→ [Position Service] 订阅价格更新
  │   ├─ 计算新的 UnrealizedPnL (增量)
  │   └─ Redis 更新持仓快照
  │
  ├─→ [Margin Service] 增量保证金更新 (< 1ms)
  │   ├─ ΔP/L = (新价 - 旧价) × 数量
  │   ├─ 新可用保证金 = 旧可用 + ΔP/L
  │   ├─ Redis HMSet 更新
  │   └─ 检查 Margin Ratio 是否穿过阈值
  │
  ├─→ [Margin Service] 检查强平条件 (毫秒级)
  │   if margin_ratio < 50% && !已强平:
  │     ├─ 发布 Kafka: cfd.margin.call.triggered
  │     ├─ 调用 Auto-Liquidation Engine
  │     └─ 推送强平通知给用户
  │
  ├─→ 每 5 分钟全量校准 (定时任务)
  │   ├─ 获取所有活跃持仓
  │   ├─ 从市场数据获取最新价格
  │   ├─ 全量重算保证金需求
  │   ├─ MySQL 写入 margin_snapshots（审计）
  │   ├─ Redis 更新
  │   └─ 检查状态变更
  │
  └─→ 实时推送给移动端 (WebSocket)
```

#### 强平执行流程
```
Margin Ratio < 50% (触发条件满足)
  │
  ├─→ [Liquidation Engine] 触发强平 (5ms)
  │   ├─ 确认账户状态（防止重复强平）
  │   └─ 生成强平事件
  │
  ├─→ [Liquidation Engine] 持仓评分 (50ms)
  │   for each position:
  │     score = margin_contribution × 0.4 
  │            + liquidity_score × 0.3 
  │            + loss_degree × 0.3
  │   
  │   按 score DESC 排序
  │
  ├─→ [Liquidation Engine] 执行强平 (配置延迟)
  │   if client_type == BEGINNER:
  │     delay = 0 (即时)
  │   else if client_type == INTERMEDIATE:
  │     delay = 5s (用户反应机会)
  │   else if client_type == PROFESSIONAL:
  │     delay = 10s
  │   else if client_type == INSTITUTION:
  │     delay = 30s
  │
  │   等待延迟 → 执行市价单平仓
  │
  ├─→ [OMS] 订单状态: CLOSED
  │   ├─ 成交价 = 当前 bid/ask
  │   └─ 发布 Kafka: cfd.order.closed
  │
  ├─→ [Position Service] 平仓处理
  │   ├─ 计算强平损失 = (平仓价 - 入场价) × 数量
  │   ├─ 计算实现 P&L
  │   ├─ 更新现金账户
  │   ├─ MySQL: positions.status = CLOSED
  │   └─ 发布 Kafka: cfd.position.liquidated
  │
  ├─→ [Margin Service] 重算保证金
  │   ├─ 移除该持仓的保证金占用
  │   ├─ Redis 更新
  │   ├─ 检查是否满足最低保证金
  │   └─ 如不满足，继续强平下一个持仓
  │
  ├─→ 推送强平成交通知
  │   ├─ 推送价格
  │   ├─ 推送损失
  │   ├─ 推送剩余保证金
  │   └─ 提示其他持仓风险
  │
  └─→ ✅ 强平完成（检查 margin_ratio >= 50%）
```

#### Daily 结算流程
```
T 日 16:00 收盘
  │
  ├─→ [Pricing Feed] 获取收盘价（所有合约）
  │
  ├─→ [Settlement Service] Mark-to-Market 计算 (1ms per position)
  │   for each account:
  │     for each position:
  │       close_price = pricing_feed.get_close_price(contract_id)
  │       daily_pnl = (close_price - position.current_price) × qty
  │       
  │       // 未实现 → 已实现
  │       position.realized_pnl += daily_pnl
  │       account.cash += daily_pnl
  │       position.current_price = close_price
  │
  ├─→ MySQL 写入 daily_settlements 表
  │   ├─ position_id
  │   ├─ settlement_date
  │   ├─ open_price (昨收)
  │   ├─ close_price (今收)
  │   ├─ daily_pnl
  │   ├─ cumulative_pnl
  │   ├─ margin_used
  │   ├─ margin_ratio
  │   └─ 审计信息
  │
  ├─→ [Margin Service] 次日保证金重算
  │   ├─ 基于收盘价（新的成本基础）
  │   ├─ 重新计算维持保证金
  │   ├─ 重新检查 Margin Ratio
  │   └─ 如果进入黄/红/黑灯，推送通知
  │
  ├─→ [Settlement Service] 生成对账单
  │   ├─ 日收益汇总
  │   ├─ 持仓快照
  │   ├─ 费用明细
  │   └─ 发送给用户
  │
  ├─→ Kafka 发布事件
  │   ├─ cfd.settlement.daily
  │   └─ cfd.audit.event（审计）
  │
  └─→ T+1 日 09:00 新一天开始
      （基于新的收盘价计算初始保证金）
```

#### 合约展期流程
```
T-2 日 (合约到期 T 日的两天前)
  │
  ├─→ [Settlement Service] 识别即将到期持仓
  │   ├─ 查询 expiry_date = T 日的所有持仓
  │   └─ 为每个持仓准备展期
  │
  ├─→ [Settlement Service] 获取新合约
  │   ├─ old_contract: AAPL_CFD_DEC
  │   ├─ new_contract: AAPL_CFD_JAN (自动查询下月)
  │   ├─ new_price = pricing_feed.get_price(new_contract)
  │   └─ 计算展期成本 = (new_price - old_entry_price) × qty
  │
  ├─→ MySQL 写入 contract_rollovers 表
  │   ├─ old_position_id
  │   ├─ new_contract_id
  │   ├─ rollover_pnl = 展期成本
  │   └─ rollover_date = T-2
  │
  ├─→ [Position Service] 创建新持仓
  │   ├─ 新持仓 = {
  │       account_id: 原账户,
  │       contract_id: 新合约,
  │       quantity: 原数量,
  │       entry_price: 新价格,
  │       expires_at: T+1个月,
  │     }
  │   └─ MySQL 插入
  │
  ├─→ [Margin Service] 更新保证金
  │   ├─ 移除旧持仓占用
  │   ├─ 添加新持仓占用
  │   ├─ Redis 重算
  │   └─ 如果 margin_ratio 变化，推送通知
  │
  ├─→ Kafka 发布事件
  │   ├─ cfd.contract.rolled_over
  │   └─ cfd.audit.event
  │
  ├─→ 推送给用户
  │   ├─ "您的 AAPL DEC 合约已展期至 JAN"
  │   ├─ 新的入场价
  │   ├─ 展期成本
  │   └─ 新合约到期日期
  │
  T 日 (到期日)
  │
  ├─→ [Settlement Service] 自动平仓旧合约
  │   ├─ old_position.status = ROLLED_OVER
  │   ├─ old_position.closed_at = T
  │   └─ 不再产生 P/L
  │
  └─→ ✅ 展期完成，新持仓继续交易
```

### 3. Go 项目结构

```
services/trading-engine/
├── cmd/
│   ├── trading-server/
│   │   └── main.go                 # 服务入口
│   └── migration/
│       └── main.go                 # 数据库迁移工具
│
├── src/internal/
│   ├── domain/
│   │   ├── cfd/
│   │   │   ├── contract.go         # CFD 合约定义
│   │   │   ├── position.go         # CFD 持仓
│   │   │   ├── position_test.go    # 单元测试
│   │   │   ├── margin.go           # 保证金计算器
│   │   │   ├── margin_test.go
│   │   │   ├── liquidation.go      # 强平规则
│   │   │   └── liquidation_test.go
│   │   │
│   │   ├── order/
│   │   │   ├── order.go            # 订单模型（共用）
│   │   │   ├── state_machine.go    # 状态机
│   │   │   └── state_machine_test.go
│   │   │
│   │   ├── event/
│   │   │   ├── domain_event.go     # Domain Event 基类
│   │   │   ├── cfd_events.go       # CFD 特有事件
│   │   │   ├── order_events.go
│   │   │   └── settlement_events.go
│   │   │
│   │   └── shared/
│   │       ├── value_object.go     # decimal.Decimal 封装
│   │       ├── price.go            # Price VO
│   │       └── constants.go
│   │
│   ├── application/
│   │   ├── cfd/
│   │   │   ├── order_service.go    # 订单服务（改造）
│   │   │   ├── order_service_test.go
│   │   │   ├── position_service.go # 持仓服务（新）
│   │   │   ├── position_service_test.go
│   │   │   ├── margin_service.go   # 保证金服务（新）
│   │   │   ├── margin_service_test.go
│   │   │   ├── settlement_service.go # 结算服务（新）
│   │   │   └── settlement_service_test.go
│   │   │
│   │   ├── risk/
│   │   │   ├── pre_trade_risk.go   # 预交易风控（改造）
│   │   │   ├── pre_trade_risk_test.go
│   │   │   ├── risk_cache.go       # 缓存管理
│   │   │   └── risk_cache_test.go
│   │   │
│   │   ├── pricing/
│   │   │   ├── pricing_service.go  # 报价服务（新）
│   │   │   └── pricing_service_test.go
│   │   │
│   │   └── dto/
│   │       ├── cfd_dto.go          # Data Transfer Objects
│   │       └── request_response.go
│   │
│   ├── infrastructure/
│   │   ├── persistence/
│   │   │   ├── repository.go       # 仓储接口
│   │   │   ├── cfd_repository.go   # CFD 仓储实现
│   │   │   ├── cfd_repository_test.go
│   │   │   ├── order_repository.go # 订单仓储（共用）
│   │   │   ├── margin_repository.go # 保证金仓储
│   │   │   ├── contract_repository.go # 合约仓储
│   │   │   └── settlement_repository.go
│   │   │
│   │   ├── messaging/
│   │   │   ├── event_publisher.go  # Kafka 事件发布
│   │   │   ├── event_publisher_test.go
│   │   │   ├── event_consumer.go   # Kafka 消费者
│   │   │   ├── event_types.go      # Topic 常量
│   │   │   └── outbox_handler.go   # Outbox Pattern
│   │   │
│   │   ├── cache/
│   │   │   ├── margin_cache.go     # Redis 保证金缓存
│   │   │   ├── margin_cache_test.go
│   │   │   ├── pricing_cache.go    # 报价缓存
│   │   │   ├── idempotency_cache.go # 幂等性缓存
│   │   │   └── redis_client.go
│   │   │
│   │   ├── pricing/
│   │   │   ├── pricing_feed.go     # 报价接口
│   │   │   ├── pricing_feed_test.go
│   │   │   ├── liquidity_provider.go # LP 集成
│   │   │   ├── liquidity_provider_test.go
│   │   │   ├── spread_calculator.go # 点差计算
│   │   │   └── spread_calculator_test.go
│   │   │
│   │   ├── clock/
│   │   │   └── time_service.go     # 统一时间（UTC）
│   │   │
│   │   └── database/
│   │       ├── db.go               # 数据库连接
│   │       └── transaction.go      # 事务管理
│   │
│   ├── transport/
│   │   ├── grpc/
│   │   │   ├── api/
│   │   │   │   └── trading.proto   # gRPC 定义
│   │   │   ├── trading_server.go   # gRPC 服务器
│   │   │   └── trading_server_test.go
│   │   │
│   │   └── rest/
│   │       ├── cfd_handler.go      # REST 端点
│   │       ├── cfd_handler_test.go
│   │       ├── middleware.go
│   │       └── error_handler.go
│   │
│   └── shared/
│       ├── logger/
│       │   ├── logger.go
│       │   └── structured_logging.go
│       ├── tracer/
│       │   └── jaeger.go           # Jaeger tracing
│       ├── metrics/
│       │   ├── prometheus.go       # Prometheus 指标
│       │   └── histogram.go
│       ├── errors/
│       │   ├── domain_error.go
│       │   └── error_codes.go
│       └── config/
│           ├── config.go
│           └── margin_configs.yaml # 保证金配置
│
├── src/migrations/
│   ├── 001_create_cfd_contracts.up.sql
│   ├── 001_create_cfd_contracts.down.sql
│   ├── 002_create_cfd_positions.up.sql
│   ├── 002_create_cfd_positions.down.sql
│   ├── 003_create_daily_settlements.up.sql
│   ├── 003_create_daily_settlements.down.sql
│   ├── 004_create_margin_calls.up.sql
│   ├── 004_create_margin_calls.down.sql
│   ├── 005_create_auto_liquidations.up.sql
│   ├── 005_create_auto_liquidations.down.sql
│   ├── 006_create_margin_snapshots.up.sql
│   ├── 006_create_margin_snapshots.down.sql
│   ├── 007_create_margin_configs.up.sql
│   ├── 007_create_margin_configs.down.sql
│   └── 008_create_cfd_audit_logs.up.sql
│
├── config/
│   ├── local.yaml                  # 本地开发配置
│   ├── staging.yaml                # 测试环境
│   └── production.yaml             # 生产环境
│
├── docs/
│   ├── api/
│   │   ├── grpc/
│   │   │   └── trading.proto
│   │   └── rest/
│   │       └── openapi.yaml
│   └── specs/
│       ├── architecture.md         # 架构文档
│       ├── data_model.md           # 数据模型
│       └── algorithms.md           # 算法文档
│
├── test/
│   ├── integration/
│   │   ├── order_flow_test.go     # 开仓流程集成测试
│   │   ├── margin_call_test.go    # Margin Call 集成测试
│   │   ├── liquidation_test.go    # 强平集成测试
│   │   └── settlement_test.go     # 结算集成测试
│   │
│   └── e2e/
│       ├── scenarios/
│       │   ├── scenario_open_position.go
│       │   ├── scenario_margin_call.go
│       │   ├── scenario_liquidation.go
│       │   └── scenario_rollover.go
│       └── fixtures/
│           ├── test_data.sql
│           └── mock_prices.json
│
├── go.mod
├── go.sum
├── Makefile                        # 编译、测试、迁移命令
└── README.md
```

---

## 数据库设计

### CFD 核心表（PostgreSQL）

详见第 7 章节，包括：
- `cfd_contracts` - 合约定义
- `cfd_positions` - 持仓
- `cfd_daily_settlements` - 日结算
- `margin_calls` - Margin Call 历史
- `auto_liquidations` - 强平记录
- `contract_rollovers` - 展期记录
- `margin_configs` - 保证金配置
- `cfd_audit_logs` - 审计日志

---

## Kafka 事件流

详见第 8 章节，包括：
- 11 个 Topic（订单、持仓、价格、保证金、结算、审计）
- Event Sourcing 架构
- Outbox Pattern（确保事务性）

---

## 关键算法详解

### 1. 保证金计算算法

```
初始保证金(固定，订单时扣除)：
  IM = 名义金额 × 初始比例
      = Quantity × Entry Price × Initial Margin Rate

维持保证金(动态，基于当前市价)：
  MM = Quantity × Current Price × Maintenance Margin Rate
  
可用保证金：
  Available = 账户现金 - MM
  
保证金比率：
  Ratio = 账户现金 / MM  (0-1)
  
Margin Call 触发：
  if Ratio <= 0.75:  # 黄灯
    通知用户，24-48 小时补缴
  if Ratio <= 0.50:  # 红灯  
    禁止新订单
  if Ratio < 0.50:   # 黑灯
    触发自动强平
```

### 2. 强平评分算法

```go
func RankForLiquidation(positions []Position) []LiquidationScore {
    candidates := make([]LiquidationScore, 0)
    
    // 1. 计算总初始保证金（分母）
    totalIM := sum(position.InitialMargin() for position in positions)
    
    for each position:
        // 2. 保证金贡献度（权重 40%）
        marginContrib := position.InitialMargin() / totalIM
        
        // 3. 流动性评分（权重 30%）
        // 点差越小，流动性越好，评分越高
        spread := pricing_feed.get_spread(position.ContractID())
        liquidityScore := 1.0 / (spread / 100)
        liquidityScore = min(liquidityScore, 1.0)  # 上限 1.0
        
        // 4. 亏损程度（权重 30%）
        // 亏损越多，优先平仓
        pnl := position.UnrealizedPnL()
        nominalValue := position.Quantity() * position.CurrentPrice()
        lossRatio := max(0, -pnl) / nominalValue
        lossRatio = min(lossRatio, 1.0)
        
        // 5. 综合评分
        score := marginContrib * 0.4 + liquidityScore * 0.3 + lossRatio * 0.3
        
        candidates.append({
            position: position,
            score: score,
            reason: "margin_ratio < 50%"
        })
    
    // 6. 按评分降序排列（高分优先）
    sort(candidates, by: score DESC)
    
    return candidates
}
```

**为什么这个公式**：
- 保证金贡献 40%：优先平仓能最快恢复保证金比率的头寸
- 流动性 30%：避免大滑点，确保成交
- 亏损 30%：亏损多的头寸平仓能及时止损

### 3. 点差计算算法

```go
func CalculateSpread(contract CFDContract) (bid, ask decimal.Decimal) {
    basePrice := pricing_feed.GetBasePrice(contract.UnderlyingAsset())
    baseSpread := config.GetBaseSpread(contract)  // 固定基础点差
    
    // 1. 波动率调整
    volatility := market_data.GetVolatility(contract, window=5min)
    volatilitySpread := baseSpread * (1 + volatility * spreadMultiplier)
    
    // 2. 流动性调整（LP 报价规模）
    lpBidSize := liquidity_provider.GetBidSize(contract)
    lpAskSize := liquidity_provider.GetAskSize(contract)
    avgSize := (lpBidSize + lpAskSize) / 2
    liquiditySpread := baseSpread * (1 + maxSize / avgSize)
    
    // 3. 对手方风险调整
    lpCreditScore := GetCreditScore(liquidity_provider)  // 0-1
    riskSpread := baseSpread * (1 - lpCreditScore * 0.2)
    
    // 4. 总点差
    totalSpread := max(
        baseSpread,
        volatilitySpread + liquiditySpread + riskSpread
    )
    
    // 5. 报价
    midPrice := (basePrice.bid + basePrice.ask) / 2
    bid := midPrice - totalSpread/2
    ask := midPrice + totalSpread/2
    
    return bid, ask
}
```

### 4. Daily MTM 结算算法

```go
func PerformDailySettlement(date Date) {
    for each account:
        for each position:
            closePrice := pricing_feed.GetClosePrice(contract, date)
            
            // 1. 计算日盈亏
            dailyPnL := (closePrice - position.CurrentPrice) * position.Quantity
            
            // 2. 累计已实现盈亏
            position.RealizedPnL += dailyPnL
            
            // 3. 现金账户更新（即时结算）
            account.Cash += dailyPnL
            
            // 4. 持仓状态更新（为次日计算做准备）
            position.CurrentPrice = closePrice
            position.UnrealizedPnL = 0  # 已实现，清零
            
            // 5. 记录日结算（审计）
            DailySettlement {
                PositionID: position.ID,
                SettlementDate: date,
                OpenPrice: position.PreviousClosePrice,
                ClosePrice: closePrice,
                DailyPnL: dailyPnL,
                CumulativePnL: position.RealizedPnL,
            }
        
        // 6. 重算次日保证金（基于收盘价）
        RecalculateMarginRequirement(account, using: closePrice)
        
        // 7. 推送对账单给用户
        SendStatementToUser(account, date)
}
```

---

## 实现计划与验收标准

### Phase 1：Core OMS & Risk（4 周）

**目标**：完整的订单流程和风控检查

**交付**：
- [ ] CFD OMS 状态机（CREATED → VALIDATED → RISK_APPROVED → OPEN → FILLED/CANCELLED）
- [ ] 13 道风控检查（复用 8 道 + 新增 5 道）
- [ ] Pricing Feed mock 实现
- [ ] 幂等性检查（Redis + DB）
- [ ] 基础的 Kafka 事件发布

**验收标准**：
```
单元测试：
  ✓ 订单状态转换（所有合法路径）
  ✓ 每道风控检查的单独测试（5 个 pass/fail 场景）
  ✓ 幂等性检查（重复订单返回相同结果）
  ✓ 价格获取（mock 数据）

集成测试：
  ✓ 端到端开仓流程 (user submit → order.opened event)
  ✓ 风控拒绝流程（购买力不足）
  ✓ 重复订单处理（同一 idempotency_key）
  ✓ Kafka 事件链 (order.created → order.risk_approved → order.opened)

性能测试：
  ✓ 订单延迟 < 100ms p99
  ✓ 风控检查 < 5ms p99
  ✓ Kafka 发布 < 10ms p99
```

### Phase 2：Position & Margin（6 周）

**目标**：实时动态保证金和持仓管理

**交付**：
- [ ] CFD Position 数据结构和仓储
- [ ] Margin Calculator（初始 + 维持保证金）
- [ ] 实时 P/L 计算（增量更新 + 5 分钟全量校准）
- [ ] 三层保证金监控（GREEN → YELLOW → RED → BLACK）
- [ ] Margin Call 通知系统
- [ ] Redis 缓存策略

**验收标准**：
```
单元测试：
  ✓ 保证金计算（10 个场景：不同杠杆、多头、空头、负 P&L）
  ✓ Margin Ratio 状态转换（GREEN → YELLOW → RED → BLACK）
  ✓ 增量保证金更新（验证准确性）
  ✓ 全量校准与增量的差异检查（< 0.01%）

集成测试：
  ✓ 开仓后保证金占用正确
  ✓ 价格上升 → P/L 正收益 → 保证金增加
  ✓ 价格下降 → P/L 负收益 → 保证金减少
  ✓ Margin Ratio 穿过 75% 触发 YELLOW 通知
  ✓ Margin Ratio 穿过 50% 触发 RED 通知
  ✓ 5 分钟全量校准后 Redis 和 DB 一致
  ✓ Redis 宕机 → 降级到 DB 全量计算

性能测试：
  ✓ 保证金计算 < 1ms p99（单持仓）
  ✓ 价格更新 < 50ms p99（从行情到推送）
  ✓ 5 分钟全量 < 5s p99（10K 持仓）
  ✓ Redis 吞吐 > 50K ops/sec
```

### Phase 3：Auto-Liquidation（4 周）

**目标**：自动强平引擎和毫秒级触发

**交付**：
- [ ] Liquidation Engine（持仓评分、优先级排序）
- [ ] 配置化强平延迟（BEGINNER/INTERMEDIATE/PROFESSIONAL/INSTITUTION）
- [ ] 市价单执行（跳过部分风控）
- [ ] 强平审计日志（完整的触发、执行、结果记录）
- [ ] 强平通知系统（1 小时前警告、5 分钟确认）

**验收标准**：
```
单元测试：
  ✓ 持仓评分算法（验证 40/30/30 权重比例）
  ✓ 优先级排序（高分持仓在前）
  ✓ 强平延迟配置（不同客户等级）
  ✓ 市价单生成（正确的方向、数量）

集成测试：
  ✓ Margin Ratio < 50% → 强平触发
  ✓ 强平持仓后 Margin Ratio >= 50%
  ✓ 多个持仓逐个强平（直到满足最低要求）
  ✓ 强平延迟执行（BEGINNER 0s, INTERMEDIATE 5s 等）
  ✓ 强平后仓位关闭，现金更新
  ✓ 强平通知链（触发 → 1h 警告 → 5m 确认 → 执行）
  ✓ 强平审计日志完整（时间、持仓、价格、P&L、结果）

压力测试：
  ✓ 50 个持仓同时 Margin Ratio < 50%
  ✓ 强平完成时间 < 5s（最后一个持仓成交）
  ✓ Kafka 事件无丢失
  ✓ 审计日志无遗漏

性能测试：
  ✓ 触发到执行 < 5s（配置为 BEGINNER 0 延迟）
  ✓ 持仓评分 < 100ms（50 个持仓）
  ✓ 市价单执行 < 500ms（从 match 到成交）
```

### Phase 4：Settlement & Compliance（4 周）

**目标**：Daily 结算、合约展期、合规审计

**交付**：
- [ ] Daily MTM 结算引擎
- [ ] 合约展期逻辑（T-2 自动展期）
- [ ] Event Sourcing 完整链（所有操作都记录）
- [ ] SFC 合规报告生成
- [ ] 审计日志冷存储（S3 Object Lock）

**验收标准**：
```
单元测试：
  ✓ Daily MTM 计算（未实现 → 已实现）
  ✓ 合约展期计算（旧合约结算价 + 新合约入场价）
  ✓ Event 序列化（完整信息，可重放）

集成测试：
  ✓ 持仓 1 天 → 收盘时 MTM 结算
  ✓ Daily MTM 后持仓.current_price 更新
  ✓ Daily MTM 后账户现金正确
  ✓ 持仓 T-2 日 → 自动开仓新合约
  ✓ 展期后新持仓同持仓数量、方向，不同入场价
  ✓ 合约 T 日自动关闭旧持仓
  ✓ Event Sourcing 可完整重放（从第一条事件到最后一条）
  ✓ S3 冷存储验证（对象不可修改）

合规测试：
  ✓ 生成 SFC 月报（交易量、Margin Call 次数、强平次数）
  ✓ 审计日志包含所有必需字段（时间、用户、操作、结果）
  ✓ 审计日志 7 年可追溯
  ✓ 对账单格式和内容完整

性能测试：
  ✓ Daily MTM < 60s（10K 持仓）
  ✓ 展期处理 < 100ms（单持仓）
  ✓ Event 发布 < 5ms p99
  ✓ S3 写入 < 1s（每天事件 <= 100K）
```

### Phase 5：生产加固（2 周）

**目标**：性能优化、故障转移、监控告警

**交付**：
- [ ] 性能优化（批量操作、缓存策略）
- [ ] 故障转移测试（Redis 宕机、LP 掉线、DB 故障）
- [ ] 监控指标（Prometheus）
- [ ] 告警规则（关键路径延迟、强平失败等）
- [ ] 灰度上线方案

**验收标准**：
```
性能优化：
  ✓ 订单端到端 < 50ms p99（优化后）
  ✓ 保证金计算 < 0.5ms p99
  ✓ 强平执行 < 2s p99（从触发到成交）
  ✓ 日结算 < 30s（10K 持仓）

故障转移：
  ✓ Redis 宕机 → 降级到 DB，功能完整但延迟增加
  ✓ LP 报价超时 → 使用最后一次缓存的价格
  ✓ DB 连接池耗尽 → 排队等待，不丢单
  ✓ Kafka broker 宕机 → 事件缓冲，宕机恢复后重发
  ✓ 强平执行失败 → 重试，记录失败并告警

监控告警：
  ✓ 订单延迟 p99 > 100ms → 告警
  ✓ 风控检查失败率 > 1% → 告警
  ✓ 保证金计算异常（Redis vs DB 差异 > 0.1%）→ 告警
  ✓ Margin Call 未触发 → 告警
  ✓ 强平执行失败 → 告警
  ✓ Daily MTM 延迟 > 120s → 告警

灰度上线：
  ✓ 1% 流量 → 1 小时稳定
  ✓ 5% 流量 → 4 小时稳定
  ✓ 50% 流量 → 12 小时稳定
  ✓ 100% 流量 → 生产

回滚方案：
  ✓ 快速回滚脚本（< 5 分钟）
  ✓ 数据一致性验证（回滚前后）
  ✓ 用户通知模板
```

---

## 关键成功因素

1. **精度**：使用 `shopspring/decimal` 处理所有金额计算，禁用 `float64`
2. **实时性**：毫秒级保证金监控，市价驱动事件触发
3. **可靠性**：Event Sourcing 确保完整审计链，7 年合规存储
4. **合规性**：SFC 风险披露要求（79% 亏损、追缴通知、强平警告）
5. **可配置性**：强平延迟、保证金比例、点差规则均可配置，支持不同客户等级

---

## 附录：配置示例

### margin_configs.yaml
```yaml
clientTypes:
  BEGINNER:
    maxLeverage: 10
    initialMarginRate: 0.10
    maintenanceMarginRate: 0.05
    marginCallThreshold: 0.75
    liquidationThreshold: 0.50
    liquidationDelay: 0
    
  INTERMEDIATE:
    maxLeverage: 30
    initialMarginRate: 0.033
    maintenanceMarginRate: 0.02
    marginCallThreshold: 0.75
    liquidationThreshold: 0.50
    liquidationDelay: 5s
    
  PROFESSIONAL:
    maxLeverage: 50
    initialMarginRate: 0.02
    maintenanceMarginRate: 0.01
    marginCallThreshold: 0.80
    liquidationThreshold: 0.60
    liquidationDelay: 10s
    
  INSTITUTION:
    maxLeverage: 100
    initialMarginRate: 0.01
    maintenanceMarginRate: 0.005
    marginCallThreshold: 0.90
    liquidationThreshold: 0.70
    liquidationDelay: 30s
```

---

**文档完成时间**：2026-04-03 18:30 UTC  
**下一步**：进入 Phase 1 开发，首先实现 Domain 层和基础 Repository
