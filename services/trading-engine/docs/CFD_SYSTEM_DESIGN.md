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

## A-Book vs B-Book 业务模式

### 模式对比

CFD Broker 有两种主要业务模式，决定了风险承担方式和盈利来源：

| 维度 | A-Book (Agency Model) | B-Book (Market Maker) |
|------|---------------------|---------------------|
| **对手方** | 外部 LP（流动性提供商） | Broker 自己 |
| **订单处理** | 转发给 LP | 内部撮合 |
| **风险承担** | 无市场风险，仅信用风险 | 承担客户盈亏风险 |
| **收入来源** | 点差/佣金 | 客户亏损 + 点差 |
| **LP 依赖** | 高（必须对接 LP） | 低（可选对接） |
| **资本要求** | 低（无需对冲资本） | 高（需要风险准备金） |
| **盈利模式** | 稳定（交易量驱动） | 波动（客户盈亏驱动） |
| **监管风险** | 低 | 高（利益冲突） |

### A-Book 模式详解

**工作原理**：
```
客户下单 → Broker 风控 → 转发给 LP → LP 成交 → 回报给客户
                                ↓
                        Broker 赚取点差/佣金
```

**优势**：
- ✅ 无市场风险（客户盈亏与 Broker 无关）
- ✅ 监管友好（无利益冲突）
- ✅ 可扩展（不受资本限制）
- ✅ 客户盈利不影响 Broker 收入

**劣势**：
- ❌ 依赖 LP（LP 故障影响服务）
- ❌ 点差受 LP 限制（无法自主定价）
- ❌ 需要处理 LP 信用风险
- ❌ 客户负余额风险（NBP 成本）

### B-Book 模式详解

**工作原理**：
```
客户下单 → Broker 风控 → 内部撮合 → Broker 作为对手方
                                ↓
                    客户亏损 = Broker 盈利
                    客户盈利 = Broker 亏损
```

**优势**：
- ✅ 高利润（客户亏损即收入）
- ✅ 自主定价（可调整点差）
- ✅ 无 LP 依赖（内部撮合）
- ✅ 低延迟（无需外部通信）

**劣势**：
- ❌ 高风险（承担市场风险）
- ❌ 利益冲突（客户盈利 = Broker 亏损）
- ❌ 监管严格（需要充足资本）
- ❌ 需要对冲（大额订单转 A-Book）

### 混合模式（Hybrid A/B-Book）

**智能分类**：
```go
func ClassifyOrder(order Order, account Account) BookType {
    // 1. 盈利客户 → A-Book（避免支付）
    if account.TotalPnL > 0 && account.WinRate > 0.6 {
        return A_BOOK
    }
    
    // 2. 大额订单 → A-Book（降低风险）
    if order.NotionalValue > 100000 {
        return A_BOOK
    }
    
    // 3. 高波动品种 → A-Book（避免风险）
    if isHighVolatility(order.Symbol) {
        return A_BOOK
    }
    
    // 4. 默认：散户小单 → B-Book
    return B_BOOK
}
```

**动态对冲**：
```go
// B-Book 净敞口监控
func (e *HedgeEngine) MonitorNetExposure() {
    netExposure := e.calculateNetExposure()
    
    for symbol, exposure := range netExposure {
        // 净敞口超过阈值 → 向 LP 对冲
        if exposure.Abs() > e.riskThreshold {
            hedgeOrder := Order{
                Symbol:   symbol,
                Side:     oppositeSide(exposure),
                Quantity: exposure.Abs(),
                IsHedge:  true,
            }
            e.lpRouter.SubmitOrder(ctx, hedgeOrder)
        }
    }
}
```

### 本系统选择：A-Book 模式

**决策理由**：
1. **监管合规**：避免利益冲突，符合 SFC/ESMA 要求
2. **风险可控**：不承担市场风险，仅管理信用风险
3. **可扩展性**：不受资本限制，可快速扩张
4. **客户信任**：透明模式，客户盈利不影响 Broker

**关键风控点**：
- ✅ LP 故障转移（多 LP 对接）
- ✅ LP 信用风险管理（敞口限额）
- ✅ 客户负余额保护（NBP）
- ✅ 风险准备金（覆盖 NBP 成本）

---

## 合约管理详解

### 合约的本质

在 CFD 系统中，**Contract（合约）= 可交易产品的规格说明书**。

**正股交易 vs CFD 交易**：

| 维度 | 正股交易 | CFD 交易 |
|------|---------|---------|
| **是否是"合约"？** | ❌ 否（所有权凭证） | ✅ 是（买卖双方协议） |
| **是否拥有标的？** | ✅ 是（真实持有股票） | ❌ 否（只有价格敞口） |
| **是否有到期日？** | ❌ 否（永久持有） | 期货有，CFD 无 |
| **是否有股东权利？** | ✅ 是（分红、投票） | ❌ 否 |
| **交割方式** | 实物交割（股票入账） | 现金结算（差价） |

**核心区别**：
- **正股 = 买资产**（你拥有股票）
- **CFD = 买合约**（你只有价格敞口）

### 合约的 5 大作用

#### 1. 产品定义（Product Catalog）

```go
// 合约定义了 Broker 提供哪些产品
type Contract struct {
    ContractID      string           // "CFD-AAPL-US"
    ContractType    string           // "CFD"
    UnderlyingSymbol string          // "AAPL"
    Exchange        string           // "NASDAQ"
    Currency        string           // "USD"
    LotSize         int64            // 1（1 手 = 1 股）
    TickSize        decimal.Decimal  // 0.01（最小变动）
    
    // 杠杆和保证金
    MaxLeverage     int              // 10
    MarginRate      decimal.Decimal  // 0.10（10% 初始保证金）
    MaintenanceRate decimal.Decimal  // 0.05（5% 维持保证金）
    
    // 费用
    Spread          decimal.Decimal  // 0.02（2 美分点差）
    SwapLong        decimal.Decimal  // 0.0003（多头隔夜费率）
    SwapShort       decimal.Decimal  // -0.0001（空头隔夜费率）
    
    // 到期和展期
    ExpiryDate      *time.Time       // nil（无到期日）
    RolloverRule    string           // "AUTO"（自动展期）
    
    // 风控限制
    MaxPositionSize int64            // 10000（单账户最大持仓）
    MaxOrderSize    int64            // 1000（单笔最大订单）
}
```

**作用**：
- 客户端通过合约列表展示可交易品种
- 运营人员可以上架/下架合约
- 不同合约有不同的交易规则

#### 2. 订单路由（Order Routing）

**问题**：LP 如何知道你要交易什么？

```go
// 错误：只发送 Symbol
lpClient.SubmitOrder("AAPL", "BUY", 100, 150.00)
// LP 不知道：这是现货还是 CFD？杠杆是多少？

// 正确：发送完整合约信息
contract := repo.GetContract("CFD-AAPL-US")
lpClient.SubmitOrder(FIXMessage{
    Symbol:             contract.UnderlyingSymbol,  // "AAPL"
    SecurityType:       "CFD",                      // FIX Tag 167
    Currency:           contract.Currency,          // "USD"
    ContractMultiplier: contract.LotSize,           // 1
})
```

**FIX 协议示例**：
```
8=FIX.4.4|35=D|  // NewOrderSingle
55=AAPL|         // Symbol
167=CFD|         // SecurityType（关键！）
15=USD|          // Currency
231=1|           // ContractMultiplier
54=1|            // Side (BUY)
38=100|          // OrderQty
44=150.00|       // Price
```

#### 3. 风控计算（Risk Management）

**不同合约 = 不同风控参数**

```go
func (r *RiskEngine) CalculateMargin(order *Order) (decimal.Decimal, error) {
    contract := r.contractRepo.GetContract(order.ContractID)
    
    // 根据合约的保证金率计算
    notionalValue := order.Quantity * order.Price
    margin := notionalValue * contract.MarginRate
    
    return margin, nil
}

// 示例：
// AAPL CFD（杠杆 10:1）：保证金率 10%
// BTC CFD（杠杆 2:1）：保证金率 50%
// EUR/USD CFD（杠杆 30:1）：保证金率 3.33%
```

#### 4. 结算规则（Settlement）

**合约定义结算方式**

```go
// 期货合约：到期自动结算
type FuturesContract struct {
    Contract
    ExpiryDate      time.Time
    SettlementPrice decimal.Decimal
}

// CFD 合约：自动展期
func (s *SettlementEngine) ProcessRollover(contractID string) {
    contract := s.repo.GetContract(contractID)
    
    if contract.RolloverRule == "AUTO" {
        // T-2 自动切换到新合约
        newContract := s.getNextContract(contract)
        s.rolloverPositions(contractID, newContract.ContractID)
    }
}
```

**作用**：
- 期货到期时，系统知道如何结算
- CFD 展期时，系统知道切换到哪个新合约
- 隔夜费计算：根据合约的 `SwapLong/SwapShort` 费率

#### 5. 审计合规（Audit & Compliance）

**监管要求：记录每笔交易的合约详情**

```go
type AuditLog struct {
    EventID     string
    Timestamp   time.Time
    EventType   string  // "ORDER_SUBMITTED"
    AccountID   string
    OrderID     string
    
    // 合约详情（监管要求）
    ContractID      string
    ContractType    string  // "CFD"
    UnderlyingSymbol string // "AAPL"
    Leverage        int     // 10
    MarginRate      decimal.Decimal
    
    // 保留 7 年（SEC Rule 17a-4）
}
```

**作用**：
- 监管审计时，能追溯每笔交易的合约类型
- 证明 Broker 遵守了杠杆限制（如 ESMA 30:1 上限）
- 客户投诉时，能还原交易时的合约条款

### 合约 vs 订单 vs 持仓的关系

```
Contract（合约）
    ↓ 定义产品规格
Order（订单）
    ↓ 基于合约下单
Position（持仓）
    ↓ 订单成交后形成持仓
```

**数据模型**：
```go
// 1. 合约（产品定义）
type Contract struct {
    ContractID   string
    Symbol       string
    ContractType string
    MarginRate   decimal.Decimal
}

// 2. 订单（交易请求）
type Order struct {
    OrderID    string
    ContractID string  // 引用合约
    AccountID  string
    Side       string
    Quantity   int64
    Price      decimal.Decimal
}

// 3. 持仓（持有状态）
type Position struct {
    PositionID string
    ContractID string  // 引用合约
    AccountID  string
    Side       string
    Quantity   int64
    EntryPrice decimal.Decimal
    
    // 从合约继承的参数
    MarginRate decimal.Decimal
    Leverage   int
}
```

### 实际案例：提交订单到 LP

**场景**：客户下单买入 100 股 AAPL CFD

```go
// Step 1: 客户端发送订单（只需要 ContractID）
clientOrder := {
    "contract_id": "CFD-AAPL-US",
    "side": "BUY",
    "quantity": 100,
    "price": 150.00
}

// Step 2: 交易引擎查询合约详情
contract := contractRepo.GetContract("CFD-AAPL-US")

// Step 3: 风控检查（使用合约参数）
margin := 100 * 150.00 * 0.10  // $1,500
if account.Balance < margin {
    return errors.New("insufficient margin")
}

// Step 4: 提交到 LP（携带合约信息）
fixMessage := FIX44.NewOrderSingle{
    ClOrdID:      "ORDER123",
    Symbol:       contract.UnderlyingSymbol,  // "AAPL"
    SecurityType: contract.ContractType,      // "CFD"
    Currency:     contract.Currency,          // "USD"
    Side:         "BUY",
    OrderQty:     100,
    Price:        150.00,
}
lpClient.Send(fixMessage)

// Step 5: LP 返回成交报告
executionReport := {
    "order_id": "ORDER123",
    "symbol": "AAPL",
    "fill_price": 150.02,  // 加了 2 美分点差
    "fill_qty": 100,
    "status": "FILLED"
}

// Step 6: 创建持仓（记录合约 ID）
position := Position{
    PositionID: "POS456",
    ContractID: "CFD-AAPL-US",  // 关键！
    AccountID:  "ACC789",
    Side:       "LONG",
    Quantity:   100,
    EntryPrice: 150.02,
    MarginUsed: 1500.20,
}
```

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

### 2. LP 故障转移机制

#### 多 LP 配置

```yaml
liquidityProviders:
  - name: "LP-A (Tier 1 Bank)"
    weight: 0.5          # 50% 订单量
    creditLimit: 10M     # 单日最大敞口
    priority: 1          # 主 LP
    
  - name: "LP-B (Prime Broker)"
    weight: 0.3          # 30% 订单量
    creditLimit: 5M
    priority: 2          # 备用 LP
    
  - name: "LP-C (ECN)"
    weight: 0.2          # 20% 订单量
    creditLimit: 3M
    priority: 3          # 最后备用
```

#### LP 健康监控

```go
type LPHealthMonitor struct {
    metrics map[string]*LPMetrics
}

type LPMetrics struct {
    AvgSpread       float64        // 平均点差
    QuoteLatency    time.Duration  // 报价延迟
    RejectRate      float64        // 拒单率
    SlippageRate    float64        // 滑点率
    LastQuoteTime   time.Time      // 最后报价时间
}

func (m *LPHealthMonitor) MonitorLP(lpName string) {
    metrics := m.metrics[lpName]
    
    // 1. 点差异常？
    if metrics.AvgSpread > m.config.MaxSpread {
        m.alertService.Alert("LP spread too wide", lpName)
        m.router.ReduceWeight(lpName, 0.5)  // 降低路由权重
    }
    
    // 2. 报价延迟？
    if metrics.QuoteLatency > 500*time.Millisecond {
        m.alertService.Alert("LP quote latency high", lpName)
    }
    
    // 3. 拒单率过高？
    if metrics.RejectRate > 0.05 {  // 5%
        m.router.DisableLP(lpName)  // 临时禁用
    }
    
    // 4. 报价中断？
    if time.Since(metrics.LastQuoteTime) > 10*time.Second {
        m.alertService.Alert("LP quote stale", lpName)
        m.router.FailoverToBackup(lpName)
    }
}
```

#### 故障转移流程

```go
func (r *LPRouter) SubmitOrder(ctx context.Context, order Order) (ExecutionReport, error) {
    // 1. 获取可用 LP 列表（按优先级排序）
    availableLPs := r.getAvailableLPs()
    
    var lastErr error
    
    // 2. 依次尝试每个 LP
    for _, lp := range availableLPs {
        // 检查信用额度
        if r.checkCreditLimit(lp.Name, order.NotionalValue) != nil {
            continue  // 跳过额度不足的 LP
        }
        
        // 提交订单
        report, err := lp.SubmitOrder(ctx, order)
        if err == nil {
            // 成功
            r.recordSuccess(lp.Name)
            return report, nil
        }
        
        // 失败，记录错误
        lastErr = err
        r.recordFailure(lp.Name, err)
        
        // 继续尝试下一个 LP
        logger.Warn("LP failed, trying next",
            "lp", lp.Name,
            "error", err)
    }
    
    // 3. 所有 LP 都失败
    r.alertService.SendCritical("All LPs failed", order.ID, lastErr)
    return nil, errors.New("all LPs failed")
}
```

#### LP 信用额度管理

```go
// 每笔订单前检查 LP 信用额度
func (r *LPRouter) checkCreditLimit(lpName string, orderValue decimal.Decimal) error {
    currentExposure := r.repo.GetLPExposure(lpName)
    creditLimit := r.config.GetCreditLimit(lpName)
    
    if currentExposure.Add(orderValue).GreaterThan(creditLimit) {
        return errors.New("LP credit limit exceeded")
    }
    
    return nil
}

// 实时更新 LP 敞口
func (r *LPRouter) updateLPExposure(lpName string, order Order) {
    exposure := r.cache.GetLPExposure(lpName)
    
    if order.Side == "BUY" {
        exposure = exposure.Add(order.NotionalValue)
    } else {
        exposure = exposure.Sub(order.NotionalValue)
    }
    
    r.cache.SetLPExposure(lpName, exposure)
}
```

#### LP 破产应急预案

```yaml
contingencyPlan:
  - trigger: "LP-A declares bankruptcy"
    actions:
      - "Immediately stop routing to LP-A"
      - "Redistribute orders to LP-B (60%) and LP-C (40%)"
      - "Contact backup LP-D for emergency onboarding"
      - "Notify regulator within 24 hours"
      - "Review all open positions with LP-A"
      - "Initiate legal proceedings for fund recovery"
```

**历史案例**：
- **2015 年 Alpari UK 破产**：瑞郎黑天鹅事件后，LP 拒绝执行部分订单，Alpari 无法对冲客户持仓，损失 $50M，申请破产

### 3. 数据流

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

## 高杠杆风控体系（50:1 杠杆防穿仓）

### 核心挑战

50:1 杠杆意味着价格波动 **2%** 就会导致客户保证金全部亏损。防穿仓的核心是**在客户余额归零之前强制平仓**，并且留出足够的安全边际应对滑点和跳空。

### 8 层防护机制

#### 第 1 层：实时保证金监控

**毫秒级保证金计算**

```go
// 保证金监控引擎（订阅实时报价流）
type MarginMonitor struct {
    priceStream   chan *PriceUpdate
    positionRepo  PositionRepository
    accountRepo   AccountRepository
    alertService  AlertService
    liquidationQ  LiquidationQueue
}

func (m *MarginMonitor) Start() {
    for priceUpdate := range m.priceStream {
        // 1. 获取该标的的所有持仓
        positions := m.positionRepo.GetBySymbol(priceUpdate.Symbol)
        
        for _, pos := range positions {
            // 2. 计算新的未实现盈亏
            var unrealizedPnL decimal.Decimal
            if pos.Side == "LONG" {
                // 多头用 Bid 价（卖出价）
                unrealizedPnL = (priceUpdate.BidPrice.Sub(pos.EntryPrice)).Mul(decimal.NewFromInt(pos.Quantity))
            } else {
                // 空头用 Ask 价（买入价）
                unrealizedPnL = (pos.EntryPrice.Sub(priceUpdate.AskPrice)).Mul(decimal.NewFromInt(pos.Quantity))
            }
            
            // 3. 计算账户净值
            account := m.accountRepo.Get(pos.AccountID)
            equity := account.Balance.Add(unrealizedPnL)
            
            // 4. 计算保证金率
            marginRatio := equity.Div(pos.MaintenanceMargin)
            
            // 5. 触发预警或强平
            m.checkMarginLevel(pos, marginRatio, priceUpdate)
        }
    }
}
```

**关键点**：
- 每次报价更新（100ms-1s）都重新计算保证金率
- 使用 **Bid/Ask 价差**（不是 Mid 价），更保守
- 多头用 Bid（卖出价），空头用 Ask（买入价）

#### 第 2 层：分层预警机制

**四级预警阈值**

```go
type MarginLevel int

const (
    GREEN  MarginLevel = iota  // >= 100%（安全）
    YELLOW                      // 75-100%（预警）
    ORANGE                      // 50-75%（警告）
    RED                         // < 50%（强平）
)

func (m *MarginMonitor) checkMarginLevel(pos *Position, marginRatio decimal.Decimal, price *PriceUpdate) {
    switch {
    case marginRatio.GreaterThanOrEqual(decimal.NewFromFloat(1.0)):
        // GREEN: 安全，无操作
        
    case marginRatio.GreaterThanOrEqual(decimal.NewFromFloat(0.75)):
        // YELLOW: 发送邮件/短信预警
        m.alertService.SendWarning(pos.AccountID, "Margin level: 75%", marginRatio)
        
    case marginRatio.GreaterThanOrEqual(decimal.NewFromFloat(0.50)):
        // ORANGE: 发送紧急通知 + 限制新开仓
        m.alertService.SendUrgent(pos.AccountID, "Margin level: 50%", marginRatio)
        m.accountRepo.SetTradingRestriction(pos.AccountID, "NO_NEW_POSITIONS")
        
    default:
        // RED: 立即强平
        m.liquidationQ.Enqueue(LiquidationTask{
            PositionID:   pos.ID,
            AccountID:    pos.AccountID,
            CurrentPrice: price,
            Reason:       "MARGIN_CALL",
            Priority:     HIGH,
        })
    }
}
```

**为什么是 50% 而非 0%？**
- 50:1 杠杆下，价格波动 1% = 保证金损失 50%
- 从 50% 到 0% 只需要 **1% 的价格波动**
- 必须留出安全边际应对：
  - 滑点（实际成交价差于预期）
  - 延迟（从触发到执行的时间差）
  - 跳空（价格跳跃）

#### 第 3 层：强平引擎

**强平队列 + 优先级**

```go
type LiquidationQueue struct {
    highPriorityQ  chan *LiquidationTask  // 保证金率 < 30%
    normalQ        chan *LiquidationTask  // 保证金率 30-50%
    lpRouter       LPRouter
    positionRepo   PositionRepository
}

func (q *LiquidationQueue) executeLiquidation(task *LiquidationTask) error {
    pos := q.positionRepo.Get(task.PositionID)
    
    // 1. 构造平仓订单（市价单，确保成交）
    closeOrder := Order{
        OrderID:     generateID(),
        ContractID:  pos.ContractID,
        AccountID:   pos.AccountID,
        Side:        oppositeSide(pos.Side),  // 多头 → 卖出，空头 → 买入
        Quantity:    pos.Quantity,
        OrderType:   "MARKET",  // 市价单
        TimeInForce: "IOC",     // Immediate or Cancel
    }
    
    // 2. 提交到 LP（带重试）
    var fillPrice decimal.Decimal
    var err error
    for retry := 0; retry < 3; retry++ {
        fillPrice, err = q.lpRouter.SubmitOrder(closeOrder)
        if err == nil {
            break
        }
        time.Sleep(100 * time.Millisecond)
    }
    
    if err != nil {
        // 3. LP 拒绝 → 记录异常 → 人工介入
        q.alertService.SendCritical("Liquidation failed", task)
        return err
    }
    
    // 4. 计算实际盈亏
    realizedPnL := q.calculatePnL(pos, fillPrice)
    finalEquity := pos.InitialMargin.Add(realizedPnL)
    
    // 5. 检查是否穿仓
    if finalEquity.LessThan(decimal.Zero) {
        // 穿仓了！触发负余额保护
        q.handleNegativeBalance(pos.AccountID, finalEquity)
    }
    
    // 6. 更新账户余额
    q.accountRepo.UpdateBalance(pos.AccountID, finalEquity)
    
    // 7. 记录审计日志
    q.auditLog.Record(AuditEvent{
        EventType:    "LIQUIDATION",
        PositionID:   pos.ID,
        FillPrice:    fillPrice,
        RealizedPnL:  realizedPnL,
        FinalEquity:  finalEquity,
    })
    
    return nil
}
```

**关键设计**：
- **市价单 + IOC**：确保立即成交，不等待
- **重试机制**：LP 拒绝时重试 3 次
- **优先级队列**：保证金率越低，优先级越高
- **异步执行**：不阻塞主流程

#### 第 4 层：滑点保护

**预留滑点缓冲**

```go
// 强平触发阈值需要考虑滑点
func calculateLiquidationThreshold(leverage int) decimal.Decimal {
    baseThreshold := decimal.NewFromFloat(0.50)  // 50%
    
    // 根据杠杆调整缓冲
    slippageBuffer := decimal.NewFromFloat(0.10)  // 预留 10% 缓冲
    
    // 最终阈值 = 50% + 10% = 60%
    return baseThreshold.Add(slippageBuffer)
}

// 示例：50:1 杠杆
// 初始保证金：$1,000（控制 $50,000 名义金额）
// 强平触发：保证金率 < 60%（即余额 < $600）
// 预期平仓价：余额 = $600
// 实际平仓价（考虑滑点）：余额 = $500-$600
// 安全边际：$500 > $0（不穿仓）
```

**滑点来源**：
- **点差**：Bid-Ask Spread（2-5 pips）
- **市场深度不足**：大单冲击价格
- **网络延迟**：从触发到执行的时间差（50-200ms）
- **LP 拒单**：需要重试或切换 LP

#### 第 5 层：跳空风险对冲

**周末持仓限制**

```go
// 周五收盘前检查
func (r *RiskEngine) CheckWeekendRisk() {
    if isWeekendApproaching() {
        positions := r.positionRepo.GetAllOpen()
        
        for _, pos := range positions {
            // 1. 计算周末跳空风险
            notionalValue := pos.Quantity * pos.CurrentPrice
            maxGapRisk := notionalValue * 0.05  // 假设最大跳空 5%
            
            // 2. 保证金充足？
            account := r.accountRepo.Get(pos.AccountID)
            if account.AvailableMargin.LessThan(maxGapRisk) {
                // 强制减仓 50%
                r.liquidationEngine.ReducePosition(pos.ID, 0.5)
                r.notifyClient(pos.AccountID, "Weekend position reduced due to gap risk")
            }
            
            // 3. 高波动品种禁止持仓过周末
            if r.isHighVolatility(pos.Symbol) {
                r.liquidationEngine.ClosePosition(pos.ID)
                r.notifyClient(pos.AccountID, "High volatility symbol closed before weekend")
            }
        }
    }
}

// 高波动品种列表
var highVolatilitySymbols = []string{
    "BTC", "ETH",  // 加密货币
    "TSLA",        // 特斯拉（财报前）
    "GME", "AMC",  // Meme 股
}
```

**财报前强制平仓**

```go
// 财报日历
type EarningsCalendar struct {
    Symbol    string
    Date      time.Time
    EventType string  // "EARNINGS", "FDA_APPROVAL", "FOMC"
}

func (r *RiskEngine) CheckEarningsRisk() {
    upcomingEvents := r.calendarService.GetUpcomingEvents(24 * time.Hour)
    
    for _, event := range upcomingEvents {
        positions := r.positionRepo.GetBySymbol(event.Symbol)
        
        for _, pos := range positions {
            // 财报前 1 小时强制平仓
            if time.Until(event.Date) < 1*time.Hour {
                r.liquidationEngine.ClosePosition(pos.ID)
                r.notifyClient(pos.AccountID, 
                    fmt.Sprintf("%s earnings in 1 hour, position closed", event.Symbol))
            }
        }
    }
}
```

#### 第 6 层：负余额保护 (NBP)

```go
func (l *LiquidationEngine) handleNegativeBalance(accountID string, finalEquity decimal.Decimal) {
    if finalEquity.LessThan(decimal.Zero) {
        negativeAmount := finalEquity.Abs()
        
        logger.Error("Negative balance detected",
            "accountID", accountID,
            "negativeAmount", negativeAmount)
        
        // 1. Broker 承担负余额（不追缴客户）
        l.riskFund.DeductLoss(negativeAmount)
        
        // 2. 客户账户归零
        l.accountRepo.SetBalance(accountID, decimal.Zero)
        
        // 3. 冻结账户（防止继续交易）
        l.accountRepo.SetStatus(accountID, "FROZEN")
        
        // 4. 通知客户
        l.notificationService.Send(accountID, 
            "Your account has been liquidated. Balance reset to zero under NBP.")
        
        // 5. 记录审计日志
        l.auditLog.Record(AuditEvent{
            EventType:      "NEGATIVE_BALANCE_PROTECTION",
            AccountID:      accountID,
            NegativeAmount: negativeAmount,
            Timestamp:      time.Now(),
        })
        
        // 6. 触发风险报警（如果单笔损失过大）
        if negativeAmount.GreaterThan(decimal.NewFromInt(10000)) {
            l.alertService.SendCritical("Large NBP event", accountID, negativeAmount)
        }
    }
}
```

**监管要求**：
- **ESMA（欧洲）**：强制要求零售客户 NBP
- **SFC（香港）**：建议提供 NBP，但非强制
- **CFTC（美国）**：禁止零售 CFD

**NBP 成本**：
- Broker 需要维持**风险准备金**（Risk Fund）
- 通常为客户保证金总额的 **5-10%**
- 如果风险准备金耗尽，Broker 可能破产（如 2015 年 Alpari UK）

#### 第 7 层：风险准备金管理

```go
type RiskFund struct {
    balance       decimal.Decimal
    minThreshold  decimal.Decimal  // 最低余额阈值
    targetBalance decimal.Decimal  // 目标余额
    mu            sync.RWMutex
}

func (rf *RiskFund) DeductLoss(amount decimal.Decimal) error {
    rf.mu.Lock()
    defer rf.mu.Unlock()
    
    rf.balance = rf.balance.Sub(amount)
    
    // 检查是否低于阈值
    if rf.balance.LessThan(rf.minThreshold) {
        // 触发紧急预警
        alertService.SendCritical("Risk fund below threshold", rf.balance)
        
        // 自动补充（从 Broker 利润中划拨）
        topUpAmount := rf.targetBalance.Sub(rf.balance)
        rf.topUp(topUpAmount)
    }
    
    return nil
}

// 风险准备金来源
func (rf *RiskFund) topUp(amount decimal.Decimal) {
    // 1. 从点差收入中划拨 20%
    // 2. 从隔夜费收入中划拨 30%
    // 3. 从 B-Book 盈利中划拨 50%
    
    rf.balance = rf.balance.Add(amount)
    logger.Info("Risk fund topped up", "amount", amount, "newBalance", rf.balance)
}
```

**风险准备金规模**：
```
假设：
- 客户总保证金：$10M
- 风险准备金比例：10%
- 风险准备金规模：$1M

单日最大 NBP 损失：
- 正常情况：< $10K/天
- 极端情况（闪崩）：$100K-$500K/天
- 风险准备金可覆盖：10-100 天的极端损失
```

#### 第 8 层：极端熔断机制

**波动率熔断**

```go
func (cb *CircuitBreaker) CheckVolatility(symbol string, price decimal.Decimal) {
    lastPrice := cb.cache.GetLastPrice(symbol)
    priceChange := price.Sub(lastPrice).Div(lastPrice)
    
    // 1. 单次报价波动 > 3%？
    if priceChange.Abs().GreaterThan(decimal.NewFromFloat(0.03)) {
        logger.Warn("Extreme price move", "symbol", symbol, "change", priceChange)
        
        // 暂停新开仓 60 秒
        cb.tradingControl.SuspendNewOrders(symbol, 60*time.Second)
        
        // 降低所有客户杠杆到 10:1
        cb.riskEngine.ReduceLeverageForAll(symbol, 10)
        
        // 通知客户
        cb.notificationService.BroadcastAlert(
            fmt.Sprintf("%s: High volatility detected. Leverage reduced to 10:1", symbol))
    }
    
    // 2. 5 分钟内波动 > 5%？
    volatility5m := cb.calculateVolatility(symbol, 5*time.Minute)
    if volatility5m.GreaterThan(decimal.NewFromFloat(0.05)) {
        // 强制平掉所有该品种的持仓
        cb.liquidationEngine.CloseAllPositions(symbol)
        
        // 暂停交易，直到波动率恢复
        cb.tradingControl.HaltTrading(symbol)
    }
}
```

### 防护体系总结

| 防护层 | 触发条件 | 动作 | 目的 |
|-------|---------|------|------|
| **1. 实时监控** | 每次报价更新 | 重新计算保证金率 | 及时发现风险 |
| **2. 分层预警** | 保证金率 < 75% | 发送通知 | 提醒客户追加保证金 |
| **3. 强平引擎** | 保证金率 < 50% | 市价平仓 | 防止余额归零 |
| **4. 滑点保护** | 强平时 | 预留 10% 缓冲 | 应对成交价差 |
| **5. 跳空对冲** | 周末/财报前 | 强制减仓/平仓 | 防止跳空穿仓 |
| **6. 负余额保护** | 余额 < 0 | Broker 承担损失 | 保护客户 |
| **7. 风险准备金** | NBP 触发 | 从准备金扣除 | 覆盖 Broker 损失 |
| **8. 极端熔断** | 波动率 > 5% | 暂停交易 | 防止系统性风险 |

### 关键参数配置（50:1 杠杆）

```yaml
leverage: 50
marginRate: 0.02          # 2% 初始保证金
maintenanceRate: 0.01     # 1% 维持保证金

# 预警阈值
marginLevels:
  green: 1.00             # >= 100%
  yellow: 0.75            # 75-100%
  orange: 0.60            # 60-75%（考虑滑点缓冲）
  red: 0.50               # < 50%（立即强平）

# 滑点缓冲
slippageBuffer: 0.10      # 10%

# 跳空风险
weekendMaxGapRisk: 0.05   # 5%
earningsCloseWindow: 1h   # 财报前 1 小时

# 风险准备金
riskFundRatio: 0.10       # 客户保证金的 10%
minThreshold: 0.05        # 最低 5%

# 熔断阈值
maxPriceMove: 0.03        # 单次 3%
maxVolatility5m: 0.05     # 5 分钟 5%
```

### 防穿仓的核心原则

1. **提前强平**：在余额归零之前平仓（50% 阈值）
2. **预留缓冲**：考虑滑点、延迟、跳空（10-20% 缓冲）
3. **实时监控**：毫秒级保证金计算（不能等到日终）
4. **极端对冲**：周末、财报、闪崩时主动降低风险
5. **负余额保护**：Broker 承担穿仓损失（监管要求）
6. **风险准备金**：维持充足的资本缓冲（10% 保证金总额）
7. **熔断机制**：极端行情时暂停交易

**50:1 杠杆的风险**：
- 价格波动 **1%** = 保证金损失 **50%**
- 价格波动 **2%** = 保证金全部亏损
- 必须在 **1-2% 的价格波动内**完成强平，否则穿仓

**为什么 ESMA 限制杠杆 30:1？**
- 50:1 杠杆下，Broker 的风险极高
- 2015 年瑞郎黑天鹅，多家 Broker 破产
- 监管认为 30:1 是零售客户的合理上限

---

## 性能指标和 SLA 定义

### 核心性能指标

#### 1. 订单处理延迟

| 指标 | p50 | p95 | p99 | p99.9 | 目标 |
|------|-----|-----|-----|-------|------|
| **订单端到端延迟** | < 30ms | < 50ms | < 100ms | < 200ms | 99% < 100ms |
| **风控检查延迟** | < 2ms | < 3ms | < 5ms | < 10ms | 平均 < 3ms |
| **订单持久化** | < 5ms | < 10ms | < 20ms | < 50ms | 平均 < 10ms |
| **Kafka 发布延迟** | < 3ms | < 5ms | < 10ms | < 20ms | 平均 < 5ms |

**端到端延迟定义**：从客户端发送订单到收到成交确认的总时间。

#### 2. 保证金计算延迟

| 指标 | p50 | p95 | p99 | 目标 |
|------|-----|-----|-----|------|
| **单持仓保证金计算** | < 0.5ms | < 1ms | < 2ms | 平均 < 1ms |
| **账户保证金计算（10 持仓）** | < 5ms | < 10ms | < 20ms | 平均 < 10ms |
| **账户保证金计算（100 持仓）** | < 50ms | < 100ms | < 200ms | 平均 < 100ms |
| **价格更新到推送延迟** | < 30ms | < 50ms | < 100ms | 99% < 100ms |
| **5 分钟全量校准（10K 持仓）** | < 3s | < 5s | < 10s | 平均 < 5s |

#### 3. 强平执行时间

| 指标 | p50 | p95 | p99 | 目标 |
|------|-----|-----|-----|------|
| **触发到执行延迟** | < 1s | < 2s | < 5s | 99% < 5s |
| **持仓评分计算（50 持仓）** | < 50ms | < 100ms | < 200ms | 平均 < 100ms |
| **市价单执行（LP 响应）** | < 200ms | < 500ms | < 1s | 99% < 1s |
| **强平完成到账户更新** | < 100ms | < 200ms | < 500ms | 平均 < 200ms |

#### 4. 系统吞吐量

| 指标 | 目标 | 峰值 | 说明 |
|------|------|------|------|
| **订单吞吐量** | 500 orders/s | 1000 orders/s | 单实例 |
| **价格更新处理** | 10K updates/s | 20K updates/s | 全部持仓 |
| **保证金计算** | 1K accounts/s | 2K accounts/s | 5 分钟校准 |
| **Kafka 消息吞吐** | 5K msgs/s | 10K msgs/s | 所有 Topic |
| **Redis 操作** | 50K ops/s | 100K ops/s | 读写混合 |

#### 5. 数据一致性延迟

| 指标 | 目标 | 最大延迟 | 说明 |
|------|------|---------|------|
| **Redis vs DB（增量）** | < 100ms | < 1s | 实时更新 |
| **Redis vs DB（全量校准）** | 5 分钟 | 5 分钟 | 定时任务 |
| **Kafka vs DB（Outbox）** | < 1s | < 5s | 事件发布 |
| **LP 成交回报** | < 500ms | < 2s | FIX 协议 |
| **移动端推送** | < 2s | < 5s | WebSocket |

### 可用性目标

#### SLA 定义

| 服务 | 可用性目标 | 年度停机时间 | 月度停机时间 |
|------|-----------|-------------|-------------|
| **订单服务** | 99.95% | 4.38 小时 | 21.6 分钟 |
| **保证金服务** | 99.9% | 8.76 小时 | 43.2 分钟 |
| **强平服务** | 99.99% | 52.6 分钟 | 4.32 分钟 |
| **结算服务** | 99.5% | 43.8 小时 | 3.6 小时 |
| **数据库** | 99.99% | 52.6 分钟 | 4.32 分钟 |
| **Redis** | 99.9% | 8.76 小时 | 43.2 分钟 |
| **Kafka** | 99.9% | 8.76 小时 | 43.2 分钟 |

**注意**：强平服务要求最高可用性，因为它直接影响风险管理。

#### 故障恢复时间

| 故障类型 | RTO（恢复时间目标） | RPO（数据丢失目标） |
|---------|-------------------|-------------------|
| **单实例故障** | < 30 秒 | 0（无数据丢失） |
| **Redis 故障** | < 1 分钟 | 0（降级到 DB） |
| **DB 主库故障** | < 2 分钟 | < 1 秒 |
| **Kafka 故障** | < 5 分钟 | 0（事件缓冲） |
| **LP 故障** | < 10 秒 | 0（故障转移） |
| **机房故障** | < 10 分钟 | < 5 秒 |

### 容量规划

#### 用户规模

| 阶段 | 用户数 | 活跃用户 | 并发订单 | 持仓数 |
|------|-------|---------|---------|-------|
| **Phase 1（MVP）** | 1K | 100 | 10/s | 1K |
| **Phase 2（增长）** | 10K | 1K | 100/s | 10K |
| **Phase 3（规模化）** | 100K | 10K | 500/s | 100K |
| **Phase 4（成熟）** | 1M | 100K | 1000/s | 1M |

#### 资源需求（Phase 3 规模）

| 资源 | 配置 | 数量 | 说明 |
|------|------|------|------|
| **应用服务器** | 8C16G | 4 实例 | 无状态，可水平扩展 |
| **Redis** | 16C32G | 2 实例 | 主从，50K ops/s |
| **PostgreSQL** | 16C64G | 1 主 + 2 从 | 分片（按 account_id） |
| **Kafka** | 8C16G | 3 broker | 10K msgs/s |
| **负载均衡** | - | 2 实例 | 主备 |

#### 数据增长预估

| 数据类型 | 日增量 | 月增量 | 年增量 | 保留期 |
|---------|-------|--------|--------|-------|
| **订单记录** | 100K | 3M | 36M | 7 年 |
| **持仓记录** | 10K | 300K | 3.6M | 7 年 |
| **保证金快照** | 10K | 300K | 3.6M | 1 年 |
| **审计日志** | 500K | 15M | 180M | 7 年 |
| **价格数据** | 1M | 30M | 360M | 1 年 |

**存储需求**：
- 热数据（1 年）：~500GB
- 冷数据（7 年）：~3TB
- 总计：~3.5TB

### 性能优化策略

#### 1. 缓存策略

```go
// 三层缓存架构
type CacheStrategy struct {
    L1 *LocalCache    // 进程内缓存（100ms TTL）
    L2 *RedisCache    // Redis 缓存（5 分钟 TTL）
    L3 *Database      // 数据库（持久化）
}

// 读取保证金
func (s *CacheStrategy) GetMargin(accountID string) (*MarginRequirement, error) {
    // 1. L1 缓存（最快）
    if val, ok := s.L1.Get(accountID); ok {
        return val, nil
    }
    
    // 2. L2 缓存（Redis）
    if val, err := s.L2.Get(accountID); err == nil {
        s.L1.Set(accountID, val, 100*time.Millisecond)
        return val, nil
    }
    
    // 3. L3 数据库（最慢）
    val, err := s.L3.Get(accountID)
    if err != nil {
        return nil, err
    }
    
    s.L2.Set(accountID, val, 5*time.Minute)
    s.L1.Set(accountID, val, 100*time.Millisecond)
    return val, nil
}
```

#### 2. 批量操作

```go
// 批量更新保证金（减少 DB 往返）
func (s *MarginService) BatchUpdateMargin(updates []MarginUpdate) error {
    // 1. 批量读取（单次查询）
    accountIDs := extractAccountIDs(updates)
    accounts := s.repo.BatchGet(accountIDs)
    
    // 2. 批量计算
    requirements := make([]*MarginRequirement, 0, len(updates))
    for _, update := range updates {
        req := s.calc.Calculate(accounts[update.AccountID], update.NewPrice)
        requirements = append(requirements, req)
    }
    
    // 3. 批量写入（单次事务）
    return s.repo.BatchSave(requirements)
}
```

#### 3. 异步处理

```go
// 非关键路径异步化
func (s *OrderService) SubmitOrder(order *Order) error {
    // 1. 同步：风控检查（关键路径）
    if err := s.riskEngine.Check(order); err != nil {
        return err
    }
    
    // 2. 同步：订单持久化（关键路径）
    if err := s.repo.Save(order); err != nil {
        return err
    }
    
    // 3. 异步：事件发布（非关键路径）
    go s.publisher.Publish(&OrderCreatedEvent{OrderID: order.ID})
    
    // 4. 异步：审计日志（非关键路径）
    go s.auditLog.Record(&AuditEvent{OrderID: order.ID})
    
    return nil
}
```

#### 4. 连接池优化

```yaml
# 数据库连接池配置
database:
  maxOpenConns: 100      # 最大连接数
  maxIdleConns: 20       # 最大空闲连接
  connMaxLifetime: 1h    # 连接最大生命周期
  connMaxIdleTime: 10m   # 空闲连接超时

# Redis 连接池配置
redis:
  poolSize: 100          # 连接池大小
  minIdleConns: 20       # 最小空闲连接
  maxRetries: 3          # 最大重试次数
  dialTimeout: 5s        # 连接超时
  readTimeout: 3s        # 读超时
  writeTimeout: 3s       # 写超时
```

---

## 异常处理和降级策略

### 故障场景和应对策略

#### 1. Redis 故障

**场景**：Redis 主库宕机或网络分区

**影响**：
- 保证金实时计算失败
- 订单幂等性检查失败
- 价格缓存不可用

**降级策略**：

```go
type MarginServiceWithFallback struct {
    redis *RedisCache
    db    *Database
}

func (s *MarginServiceWithFallback) GetMargin(accountID string) (*MarginRequirement, error) {
    // 1. 尝试 Redis
    val, err := s.redis.Get(accountID)
    if err == nil {
        return val, nil
    }
    
    // 2. Redis 失败，降级到 DB
    logger.Warn("Redis unavailable, falling back to DB", "error", err)
    metrics.RedisFailoverCount.Inc()
    
    val, err = s.db.GetLatestMarginSnapshot(accountID)
    if err != nil {
        return nil, err
    }
    
    // 3. 标记为降级模式
    val.IsDegraded = true
    val.LastUpdated = time.Now().Add(-5 * time.Minute)  // 可能过期
    
    return val, nil
}
```

**恢复流程**：
1. 检测到 Redis 恢复（健康检查）
2. 触发全量数据同步（从 DB 到 Redis）
3. 验证数据一致性
4. 切换回正常模式

**性能影响**：
- 保证金计算延迟：1ms → 50ms（50 倍）
- 订单延迟：50ms → 100ms（2 倍）
- 可接受时间：< 10 分钟

---

#### 2. LP 全部故障

**场景**：所有 LP 同时不可用（极端情况）

**影响**：
- 无法执行新订单
- 无法执行强平
- 价格数据可能中断

**降级策略**：

```go
func (r *LPRouter) SubmitOrder(order *Order) error {
    // 1. 尝试所有 LP
    for _, lp := range r.availableLPs {
        if err := lp.Submit(order); err == nil {
            return nil
        }
    }
    
    // 2. 所有 LP 都失败
    logger.Error("All LPs failed", "orderID", order.ID)
    
    // 3. 触发紧急降级
    r.emergencyMode.Activate()
    
    // 4. 暂停新订单
    r.tradingControl.SuspendNewOrders("ALL_SYMBOLS")
    
    // 5. 通知所有客户
    r.notificationService.BroadcastAlert(
        "Trading temporarily suspended due to technical issues. " +
        "Existing positions are safe. We are working to restore service.")
    
    // 6. 通知运维团队
    r.alertService.SendCritical("All LPs failed - trading suspended")
    
    return errors.New("all LPs unavailable - trading suspended")
}
```

**人工介入流程**：
1. 运维团队收到告警（< 1 分钟）
2. 评估 LP 故障原因
3. 联系 LP 技术支持
4. 如果 LP 长时间不可用（> 30 分钟）：
   - 考虑启用备用 LP
   - 考虑手动执行关键强平订单
5. LP 恢复后，逐步恢复交易

**恢复流程**：
1. 检测到至少 1 个 LP 恢复
2. 小流量测试（10% 订单）
3. 验证成交正常
4. 逐步放开流量（50% → 100%）
5. 发送恢复通知

---

#### 3. Kafka 延迟/宕机

**场景**：Kafka broker 故障或消息积压

**影响**：
- 事件发布延迟
- 下游服务收不到事件
- 审计日志延迟

**降级策略**：

```go
type EventPublisherWithBuffer struct {
    kafka  *KafkaProducer
    buffer *LocalBuffer  // 本地缓冲（内存 + 磁盘）
}

func (p *EventPublisherWithBuffer) Publish(event DomainEvent) error {
    // 1. 尝试发送到 Kafka
    err := p.kafka.Send(event)
    if err == nil {
        return nil
    }
    
    // 2. Kafka 失败，写入本地缓冲
    logger.Warn("Kafka unavailable, buffering event", "error", err)
    metrics.KafkaFailoverCount.Inc()
    
    if err := p.buffer.Append(event); err != nil {
        // 3. 本地缓冲也失败（磁盘满？）
        logger.Error("Failed to buffer event", "error", err)
        return err
    }
    
    // 4. 启动后台重试
    go p.retryBufferedEvents()
    
    return nil
}

func (p *EventPublisherWithBuffer) retryBufferedEvents() {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()
    
    for range ticker.C {
        events := p.buffer.GetPending()
        if len(events) == 0 {
            return  // 缓冲已清空
        }
        
        for _, event := range events {
            if err := p.kafka.Send(event); err == nil {
                p.buffer.MarkSent(event.ID)
            } else {
                break  // Kafka 仍然不可用，稍后重试
            }
        }
    }
}
```

**数据一致性保证**：
- 使用 Outbox Pattern（事件先写 DB，再发 Kafka）
- 即使 Kafka 宕机，事件也不会丢失
- Kafka 恢复后，从 Outbox 表重新发送

---

#### 4. DB 连接池耗尽

**场景**：慢查询或高并发导致连接池耗尽

**影响**：
- 新请求无法获取连接
- 订单提交失败
- 保证金查询失败

**降级策略**：

```go
type DBConnectionManager struct {
    pool *sql.DB
    sem  *semaphore.Weighted  // 信号量限流
}

func (m *DBConnectionManager) Execute(query string) error {
    // 1. 尝试获取连接（带超时）
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    
    if err := m.sem.Acquire(ctx, 1); err != nil {
        // 2. 超时，连接池耗尽
        logger.Warn("DB connection pool exhausted")
        metrics.DBConnectionPoolExhausted.Inc()
        
        // 3. 拒绝请求（快速失败）
        return errors.New("service temporarily unavailable - please retry")
    }
    defer m.sem.Release(1)
    
    // 4. 执行查询
    return m.pool.QueryRow(query).Scan()
}
```

**预防措施**：
- 设置查询超时（5 秒）
- 慢查询告警（> 1 秒）
- 连接池监控（使用率 > 80% 告警）
- 限流（API 网关层）

---

#### 5. 价格数据延迟/中断

**场景**：LP 报价延迟或中断

**影响**：
- 保证金计算使用过期价格
- 强平可能延迟
- 订单价格验证失败

**降级策略**：

```go
type PricingFeedWithStaleCheck struct {
    cache *PriceCache
}

func (f *PricingFeedWithStaleCheck) GetPrice(symbol string) (decimal.Decimal, error) {
    price, timestamp, err := f.cache.Get(symbol)
    if err != nil {
        return decimal.Zero, err
    }
    
    // 1. 检查价格新鲜度
    age := time.Since(timestamp)
    if age > 10*time.Second {
        // 2. 价格过期
        logger.Warn("Stale price detected", "symbol", symbol, "age", age)
        metrics.StalePriceCount.Inc()
        
        // 3. 根据过期程度决定策略
        if age > 60*time.Second {
            // 严重过期（> 1 分钟）：暂停该品种交易
            f.tradingControl.SuspendSymbol(symbol)
            return decimal.Zero, errors.New("price data unavailable")
        } else {
            // 轻微过期（10-60 秒）：使用但标记
            return price, &StalePriceWarning{Age: age}
        }
    }
    
    return price, nil
}
```

**恢复流程**：
1. 检测到价格恢复（新报价到达）
2. 验证价格合理性（与历史价格对比）
3. 恢复该品种交易
4. 触发保证金重算

---

#### 6. 强平执行失败

**场景**：LP 拒绝强平订单或执行超时

**影响**：
- 客户保证金继续恶化
- 可能导致负余额

**降级策略**：

```go
func (e *LiquidationEngine) ExecuteWithRetry(task *LiquidationTask) error {
    maxRetries := 3
    retryDelay := 100 * time.Millisecond
    
    for attempt := 1; attempt <= maxRetries; attempt++ {
        err := e.executeLiquidation(task)
        if err == nil {
            return nil
        }
        
        logger.Warn("Liquidation attempt failed",
            "attempt", attempt,
            "positionID", task.PositionID,
            "error", err)
        
        if attempt < maxRetries {
            time.Sleep(retryDelay)
            retryDelay *= 2  // 指数退避
        }
    }
    
    // 所有重试都失败
    logger.Error("Liquidation failed after retries", "positionID", task.PositionID)
    
    // 触发人工介入
    e.alertService.SendCritical("Liquidation failed - manual intervention required",
        "positionID", task.PositionID,
        "accountID", task.AccountID,
        "marginRatio", task.MarginRatio)
    
    // 记录到人工处理队列
    e.manualQueue.Enqueue(task)
    
    return errors.New("liquidation failed - escalated to manual processing")
}
```

**人工介入流程**：
1. 运维团队收到告警（< 30 秒）
2. 查看持仓详情和保证金状态
3. 评估风险（是否紧急）
4. 手动执行强平（通过管理后台）
5. 记录处理结果

---

### 降级模式总结

| 故障 | 降级策略 | 性能影响 | 可接受时间 |
|------|---------|---------|-----------|
| **Redis 故障** | 降级到 DB | 延迟 50 倍 | < 10 分钟 |
| **LP 全部故障** | 暂停交易 | 无法交易 | < 30 分钟 |
| **Kafka 故障** | 本地缓冲 | 事件延迟 | < 1 小时 |
| **DB 连接池耗尽** | 快速失败 + 限流 | 部分请求失败 | < 5 分钟 |
| **价格数据中断** | 使用缓存 + 暂停交易 | 无法交易 | < 5 分钟 |
| **强平失败** | 重试 + 人工介入 | 风险增加 | < 2 分钟 |

---

## 数据一致性保证

CFD 系统涉及多个数据源（Redis、MySQL、Kafka），需要明确一致性策略和容忍度。

### Redis vs MySQL 一致性

**策略**：最终一致性 + 定期校准

```go
// 5 分钟全量校准
func (s *MarginService) RecalculateAll(ctx context.Context, accountID string) error {
    // 1. 从 MySQL 读取所有持仓（权威数据源）
    positions, _ := s.positionRepo.ListByAccount(ctx, accountID)
    
    // 2. 获取最新市价
    for _, pos := range positions {
        latestPrice := s.pricing.GetPrice(pos.ContractID())
        pos.SetCurrentPrice(latestPrice)
    }
    
    // 3. 全量重算保证金
    requirement := s.calc.CalculateRequirement(positions, configs)
    
    // 4. 对比 Redis 缓存值
    cached, _ := s.cache.Get(ctx, accountID)
    diff := requirement.AvailableMargin.Sub(cached.AvailableMargin).Abs()
    diffPercent := diff.Div(requirement.AvailableMargin).Mul(decimal.NewFromInt(100))
    
    // 5. 差异检测
    if diffPercent.GreaterThan(decimal.NewFromFloat(0.1)) {  // > 0.1%
        s.logger.Warn("Margin discrepancy detected",
            "accountID", accountID,
            "redis", cached.AvailableMargin,
            "db", requirement.AvailableMargin,
            "diff_percent", diffPercent)
        
        // 触发告警
        s.alertService.Send("MarginDiscrepancy", accountID, diffPercent)
    }
    
    // 6. 以 MySQL 计算结果为准，更新 Redis
    s.cache.Set(ctx, requirement)
    
    // 7. 记录快照到 MySQL（审计）
    s.repo.SaveSnapshot(ctx, &MarginSnapshot{
        AccountID: accountID,
        Requirement: requirement,
        Timestamp: time.Now().UTC(),
    })
    
    return nil
}
```

**差异处理规则**：
- **< 0.01%**：正常误差，忽略
- **0.01% - 0.1%**：记录日志，不告警
- **0.1% - 1%**：告警，自动修复（以 MySQL 为准）
- **> 1%**：严重告警，暂停该账户交易，人工介入

**可接受延迟**：
- Redis 增量更新：实时（< 100ms）
- MySQL 全量校准：5 分钟
- 差异修复：< 10 秒

---

### Kafka vs MySQL 一致性

**策略**：Outbox Pattern（事务性发件箱）

```go
// 订单提交时的原子操作
func (s *OrderService) SubmitOrder(ctx context.Context, order *Order) error {
    // 开启数据库事务
    tx, _ := s.db.BeginTx(ctx, nil)
    defer tx.Rollback()
    
    // 1. 插入订单记录
    if err := s.orderRepo.SaveWithTx(ctx, tx, order); err != nil {
        return err
    }
    
    // 2. 插入 Outbox 事件（同一事务）
    event := &OutboxEvent{
        EventID:     uuid.New().String(),
        EventType:   "ORDER_CREATED",
        AggregateID: order.AccountID,
        Payload:     json.Marshal(order),
        CreatedAt:   time.Now().UTC(),
        Status:      "PENDING",
    }
    if err := s.outboxRepo.SaveWithTx(ctx, tx, event); err != nil {
        return err
    }
    
    // 3. 提交事务（原子性保证）
    if err := tx.Commit(); err != nil {
        return err
    }
    
    // 4. 异步发送到 Kafka（由独立的 Relay 进程处理）
    // 不在这里发送，避免阻塞
    
    return nil
}

// 独立的 Outbox Relay 进程
func (r *OutboxRelay) Run(ctx context.Context) {
    ticker := time.NewTicker(100 * time.Millisecond)  // 100ms 轮询
    
    for {
        select {
        case <-ticker.C:
            // 1. 查询待发送事件（批量）
            events, _ := r.outboxRepo.GetPending(ctx, 100)
            
            for _, event := range events {
                // 2. 发送到 Kafka
                err := r.kafkaProducer.Send(ctx, event.EventType, event.Payload)
                
                if err == nil {
                    // 3. 标记为已发送
                    r.outboxRepo.MarkSent(ctx, event.EventID)
                } else {
                    // 4. 重试计数
                    r.outboxRepo.IncrementRetry(ctx, event.EventID)
                    
                    // 5. 超过 3 次失败 → 告警
                    if event.RetryCount >= 3 {
                        r.alertService.Send("OutboxEventFailed", event.EventID)
                    }
                }
            }
            
        case <-ctx.Done():
            return
        }
    }
}
```

**Outbox 表结构**：
```sql
CREATE TABLE outbox_events (
    event_id VARCHAR(36) PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    aggregate_id VARCHAR(36) NOT NULL,
    payload JSON NOT NULL,
    created_at TIMESTAMP NOT NULL,
    sent_at TIMESTAMP NULL,
    status ENUM('PENDING', 'SENT', 'FAILED') NOT NULL,
    retry_count INT DEFAULT 0,
    INDEX idx_status_created (status, created_at)
) ENGINE=InnoDB;
```

**保证**：
- ✅ **At-least-once delivery**：事件至少发送一次（可能重复）
- ✅ **顺序性**：同一 aggregate_id 的事件按 created_at 顺序发送
- ✅ **幂等性**：消费者必须处理重复事件（通过 event_id 去重）

**清理策略**：
- 已发送事件保留 7 天（审计）
- 7 天后归档到 S3
- 失败事件永久保留（人工处理）

---

### 分布式事务保证

**场景**：订单成交后，需要原子更新 3 个实体：
1. 订单状态（FILLED）
2. 持仓（新增或更新）
3. 保证金（扣除初始保证金）

**方案**：Saga Pattern（编排式）

```go
type OrderFillSaga struct {
    orderRepo    OrderRepository
    positionRepo PositionRepository
    marginRepo   MarginRepository
    eventBus     EventBus
}

func (s *OrderFillSaga) Execute(ctx context.Context, fill *Fill) error {
    sagaID := uuid.New().String()
    
    // Step 1: 更新订单状态
    if err := s.updateOrder(ctx, sagaID, fill); err != nil {
        return err  // 第一步失败，无需补偿
    }
    
    // Step 2: 更新持仓
    if err := s.updatePosition(ctx, sagaID, fill); err != nil {
        // 补偿：回滚订单状态
        s.compensateOrder(ctx, sagaID, fill)
        return err
    }
    
    // Step 3: 更新保证金
    if err := s.updateMargin(ctx, sagaID, fill); err != nil {
        // 补偿：回滚持仓 + 订单
        s.compensatePosition(ctx, sagaID, fill)
        s.compensateOrder(ctx, sagaID, fill)
        return err
    }
    
    // 发布成功事件
    s.eventBus.Publish(ctx, &OrderFilledEvent{
        SagaID:  sagaID,
        OrderID: fill.OrderID,
        FillID:  fill.FillID,
    })
    
    return nil
}

func (s *OrderFillSaga) updateOrder(ctx context.Context, sagaID string, fill *Fill) error {
    tx, _ := s.orderRepo.BeginTx(ctx)
    defer tx.Rollback()
    
    // 更新订单
    order, _ := s.orderRepo.GetByIDWithTx(ctx, tx, fill.OrderID)
    order.Status = "FILLED"
    order.FilledQty = fill.Quantity
    order.AvgPrice = fill.Price
    s.orderRepo.SaveWithTx(ctx, tx, order)
    
    // 记录 Saga 步骤
    s.saveSagaStep(ctx, tx, sagaID, "UPDATE_ORDER", "COMPLETED")
    
    return tx.Commit()
}

func (s *OrderFillSaga) compensateOrder(ctx context.Context, sagaID string, fill *Fill) error {
    tx, _ := s.orderRepo.BeginTx(ctx)
    defer tx.Rollback()
    
    // 回滚订单状态
    order, _ := s.orderRepo.GetByIDWithTx(ctx, tx, fill.OrderID)
    order.Status = "SUBMITTED"  // 恢复到提交状态
    order.FilledQty = 0
    s.orderRepo.SaveWithTx(ctx, tx, order)
    
    // 记录补偿步骤
    s.saveSagaStep(ctx, tx, sagaID, "COMPENSATE_ORDER", "COMPLETED")
    
    return tx.Commit()
}
```

**Saga 状态表**：
```sql
CREATE TABLE saga_steps (
    saga_id VARCHAR(36) NOT NULL,
    step_name VARCHAR(50) NOT NULL,
    status ENUM('PENDING', 'COMPLETED', 'COMPENSATED', 'FAILED') NOT NULL,
    created_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NULL,
    error_message TEXT NULL,
    PRIMARY KEY (saga_id, step_name),
    INDEX idx_saga_status (saga_id, status)
) ENGINE=InnoDB;
```

**保证**：
- ✅ **最终一致性**：所有步骤最终成功或全部回滚
- ✅ **可观测性**：每个 Saga 的执行路径可追溯
- ✅ **幂等性**：补偿操作可重复执行

---

### 最终一致性场景

**场景 1：价格更新延迟**
- **问题**：市场数据延迟 1-2 秒到达
- **影响**：保证金计算基于稍旧的价格
- **可接受性**：✅ 可接受（2 秒内的价格变化对保证金影响 < 0.1%）
- **缓解**：使用 WebSocket 推送，减少延迟到 < 500ms

**场景 2：Kafka 事件延迟**
- **问题**：Kafka 消费者处理延迟 5-10 秒
- **影响**：移动端持仓显示延迟
- **可接受性**：✅ 可接受（用户体验可容忍 10 秒延迟）
- **缓解**：关键路径（订单状态）使用同步 API 查询

**场景 3：Redis 缓存过期**
- **问题**：Redis 缓存 5 分钟过期，期间数据可能不一致
- **影响**：保证金显示与实际有微小差异
- **可接受性**：✅ 可接受（差异 < 0.1%）
- **缓解**：5 分钟全量校准 + 差异告警

---

### 数据修复流程

**检测**：
1. 定期对账任务（每小时）
2. 差异告警触发
3. 用户投诉

**修复步骤**：
```go
func (s *DataRepairService) RepairMargin(ctx context.Context, accountID string) error {
    // 1. 锁定账户（防止并发修改）
    lock := s.redis.Lock(ctx, "repair:"+accountID, 60*time.Second)
    defer lock.Unlock()
    
    // 2. 从 MySQL 全量重算（权威数据源）
    positions, _ := s.positionRepo.ListByAccount(ctx, accountID)
    requirement := s.calc.CalculateRequirement(positions, configs)
    
    // 3. 对比当前 Redis 值
    cached, _ := s.cache.Get(ctx, accountID)
    diff := requirement.AvailableMargin.Sub(cached.AvailableMargin)
    
    // 4. 记录修复日志
    s.auditRepo.Save(ctx, &DataRepairLog{
        AccountID: accountID,
        Type:     "MARGIN_REPAIR",
        OldValue: cached.AvailableMargin,
        NewValue: requirement.AvailableMargin,
        Diff:     diff,
        Timestamp: time.Now().UTC(),
    })
    
    // 5. 更新 Redis（以 MySQL 为准）
    s.cache.Set(ctx, requirement)
    
    // 6. 通知用户（如果差异显著）
    if diff.Abs().GreaterThan(decimal.NewFromInt(100)) {  // > $100
        s.notifyUser(ctx, accountID, "保证金已校准", diff)
    }
    
    return nil
}
```

---

## 监控和告警系统

### Prometheus 指标定义

```go
// 订单延迟直方图
var orderLatencyHistogram = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name:    "cfd_order_latency_seconds",
        Help:    "Order processing latency from submission to response",
        Buckets: []float64{0.01, 0.03, 0.05, 0.1, 0.2, 0.5, 1.0},  // 10ms, 30ms, 50ms, ...
    },
    []string{"order_type", "status"},
)

// 保证金计算延迟
var marginCalcHistogram = prometheus.NewHistogram(
    prometheus.HistogramOpts{
        Name:    "cfd_margin_calc_duration_seconds",
        Help:    "Margin calculation duration per position",
        Buckets: []float64{0.0001, 0.0005, 0.001, 0.005, 0.01},  // 0.1ms, 0.5ms, 1ms, ...
    },
)

// LP 健康度
var lpHealthGauge = prometheus.NewGaugeVec(
    prometheus.GaugeOpts{
        Name: "cfd_lp_health_score",
        Help: "LP health score (0-1)",
    },
    []string{"lp_name"},
)

// 强平执行时间
var liquidationDurationHistogram = prometheus.NewHistogram(
    prometheus.HistogramOpts{
        Name:    "cfd_liquidation_duration_seconds",
        Help:    "Time from liquidation trigger to completion",
        Buckets: []float64{1, 2, 5, 10, 30, 60},  // 1s, 2s, 5s, ...
    },
)

// 保证金比率分布
var marginRatioGauge = prometheus.NewGaugeVec(
    prometheus.GaugeOpts{
        Name: "cfd_margin_ratio",
        Help: "Current margin ratio per account",
    },
    []string{"account_id", "status"},  // status: GREEN/YELLOW/ORANGE/RED
)

// 连接池使用率
var dbPoolUsageGauge = prometheus.NewGauge(
    prometheus.GaugeOpts{
        Name: "cfd_db_pool_usage_percent",
        Help: "Database connection pool usage percentage",
    },
)

// Redis 命中率
var redisCacheHitRate = prometheus.NewCounter(
    prometheus.CounterOpts{
        Name: "cfd_redis_cache_hits_total",
        Help: "Total number of Redis cache hits",
    },
)

var redisCacheMissRate = prometheus.NewCounter(
    prometheus.CounterOpts{
        Name: "cfd_redis_cache_misses_total",
        Help: "Total number of Redis cache misses",
    },
)
```

---

### 告警规则配置

```yaml
# prometheus/alerts.yml
groups:
  - name: cfd_trading_alerts
    interval: 10s
    rules:
      # 订单延迟告警
      - alert: HighOrderLatency
        expr: histogram_quantile(0.99, rate(cfd_order_latency_seconds_bucket[1m])) > 0.1
        for: 2m
        labels:
          severity: warning
          component: order_service
        annotations:
          summary: "Order latency p99 > 100ms"
          description: "Order processing is slow (p99: {{ $value }}s)"
      
      # 风控检查失败率
      - alert: HighRiskCheckFailureRate
        expr: rate(cfd_risk_check_failures_total[5m]) / rate(cfd_risk_checks_total[5m]) > 0.01
        for: 3m
        labels:
          severity: warning
          component: risk_service
        annotations:
          summary: "Risk check failure rate > 1%"
          description: "{{ $value | humanizePercentage }} of risk checks are failing"
      
      # 保证金计算异常
      - alert: MarginDiscrepancy
        expr: abs(cfd_margin_redis_value - cfd_margin_db_value) / cfd_margin_db_value > 0.001
        for: 1m
        labels:
          severity: critical
          component: margin_service
        annotations:
          summary: "Margin discrepancy > 0.1%"
          description: "Redis and DB margin values differ by {{ $value | humanizePercentage }}"
      
      # Margin Call 未触发
      - alert: MissedMarginCall
        expr: cfd_margin_ratio < 0.75 and cfd_margin_call_triggered == 0
        for: 30s
        labels:
          severity: critical
          component: margin_service
        annotations:
          summary: "Margin call not triggered"
          description: "Account {{ $labels.account_id }} has margin ratio {{ $value }} but no margin call"
      
      # 强平执行失败
      - alert: LiquidationFailed
        expr: increase(cfd_liquidation_failures_total[5m]) > 0
        for: 0s
        labels:
          severity: critical
          component: liquidation_engine
        annotations:
          summary: "Liquidation execution failed"
          description: "{{ $value }} liquidations failed in the last 5 minutes"
      
      # LP 拒单率过高
      - alert: HighLPRejectRate
        expr: rate(cfd_lp_rejects_total[5m]) / rate(cfd_lp_orders_total[5m]) > 0.05
        for: 2m
        labels:
          severity: warning
          component: lp_connector
        annotations:
          summary: "LP {{ $labels.lp_name }} reject rate > 5%"
          description: "Reject rate: {{ $value | humanizePercentage }}"
      
      # Daily MTM 延迟
      - alert: DailySettlementDelayed
        expr: time() - cfd_daily_settlement_last_completion_timestamp > 120
        for: 1m
        labels:
          severity: warning
          component: settlement_service
        annotations:
          summary: "Daily settlement delayed > 2 minutes"
          description: "Last settlement completed {{ $value }}s ago"
      
      # Redis 故障
      - alert: RedisDown
        expr: up{job="redis"} == 0
        for: 30s
        labels:
          severity: critical
          component: infrastructure
        annotations:
          summary: "Redis is down"
          description: "Redis instance {{ $labels.instance }} is unreachable"
      
      # DB 连接池耗尽
      - alert: DBPoolExhausted
        expr: cfd_db_pool_usage_percent > 90
        for: 1m
        labels:
          severity: critical
          component: infrastructure
        annotations:
          summary: "DB connection pool > 90%"
          description: "Pool usage: {{ $value }}%"
      
      # Kafka 消费延迟
      - alert: KafkaConsumerLag
        expr: kafka_consumer_lag{topic="cfd.order.created"} > 1000
        for: 5m
        labels:
          severity: warning
          component: messaging
        annotations:
          summary: "Kafka consumer lag > 1000 messages"
          description: "Consumer {{ $labels.consumer_group }} is lagging by {{ $value }} messages"
```

---

### Grafana 仪表盘设计

**Dashboard 1: 实时订单监控**
```json
{
  "title": "CFD Order Monitoring",
  "panels": [
    {
      "title": "Order Latency (p50/p95/p99)",
      "targets": [
        {
          "expr": "histogram_quantile(0.50, rate(cfd_order_latency_seconds_bucket[1m]))",
          "legendFormat": "p50"
        },
        {
          "expr": "histogram_quantile(0.95, rate(cfd_order_latency_seconds_bucket[1m]))",
          "legendFormat": "p95"
        },
        {
          "expr": "histogram_quantile(0.99, rate(cfd_order_latency_seconds_bucket[1m]))",
          "legendFormat": "p99"
        }
      ],
      "yAxis": { "format": "s" }
    },
    {
      "title": "Order Throughput",
      "targets": [
        {
          "expr": "rate(cfd_orders_total[1m])",
          "legendFormat": "{{ order_type }}"
        }
      ],
      "yAxis": { "format": "ops" }
    },
    {
      "title": "Risk Check Failure Rate",
      "targets": [
        {
          "expr": "rate(cfd_risk_check_failures_total[5m]) / rate(cfd_risk_checks_total[5m])",
          "legendFormat": "Failure Rate"
        }
      ],
      "yAxis": { "format": "percentunit" }
    }
  ]
}
```

**Dashboard 2: 保证金健康度**
```json
{
  "title": "CFD Margin Health",
  "panels": [
    {
      "title": "Margin Ratio Distribution",
      "targets": [
        {
          "expr": "count(cfd_margin_ratio{status='GREEN'})",
          "legendFormat": "GREEN (> 75%)"
        },
        {
          "expr": "count(cfd_margin_ratio{status='YELLOW'})",
          "legendFormat": "YELLOW (50-75%)"
        },
        {
          "expr": "count(cfd_margin_ratio{status='RED'})",
          "legendFormat": "RED (< 50%)"
        }
      ],
      "type": "piechart"
    },
    {
      "title": "Margin Calculation Duration",
      "targets": [
        {
          "expr": "histogram_quantile(0.99, rate(cfd_margin_calc_duration_seconds_bucket[1m]))",
          "legendFormat": "p99"
        }
      ],
      "yAxis": { "format": "s" }
    },
    {
      "title": "Margin Call Events",
      "targets": [
        {
          "expr": "increase(cfd_margin_call_triggered_total[1h])",
          "legendFormat": "Margin Calls"
        }
      ]
    }
  ]
}
```

**Dashboard 3: LP 健康度**
```json
{
  "title": "CFD LP Health",
  "panels": [
    {
      "title": "LP Health Score",
      "targets": [
        {
          "expr": "cfd_lp_health_score",
          "legendFormat": "{{ lp_name }}"
        }
      ],
      "yAxis": { "min": 0, "max": 1 }
    },
    {
      "title": "LP Latency",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, rate(cfd_lp_latency_seconds_bucket[1m]))",
          "legendFormat": "{{ lp_name }} p95"
        }
      ],
      "yAxis": { "format": "s" }
    },
    {
      "title": "LP Reject Rate",
      "targets": [
        {
          "expr": "rate(cfd_lp_rejects_total[5m]) / rate(cfd_lp_orders_total[5m])",
          "legendFormat": "{{ lp_name }}"
        }
      ],
      "yAxis": { "format": "percentunit" }
    }
  ]
}
```

**Dashboard 4: 系统资源**
```json
{
  "title": "CFD System Resources",
  "panels": [
    {
      "title": "DB Connection Pool Usage",
      "targets": [
        {
          "expr": "cfd_db_pool_usage_percent",
          "legendFormat": "Usage %"
        }
      ],
      "yAxis": { "min": 0, "max": 100 }
    },
    {
      "title": "Redis Cache Hit Rate",
      "targets": [
        {
          "expr": "rate(cfd_redis_cache_hits_total[1m]) / (rate(cfd_redis_cache_hits_total[1m]) + rate(cfd_redis_cache_misses_total[1m]))",
          "legendFormat": "Hit Rate"
        }
      ],
      "yAxis": { "format": "percentunit" }
    },
    {
      "title": "Kafka Consumer Lag",
      "targets": [
        {
          "expr": "kafka_consumer_lag",
          "legendFormat": "{{ topic }}"
        }
      ]
    }
  ]
}
```

---

### 日志采集和分析

**结构化日志格式**：
```json
{
  "timestamp": "2026-04-07T10:30:45.123Z",
  "level": "INFO",
  "service": "cfd-trading-engine",
  "component": "order_service",
  "trace_id": "abc123",
  "span_id": "def456",
  "account_id": "acc-789",
  "order_id": "ord-101112",
  "event": "ORDER_SUBMITTED",
  "latency_ms": 45,
  "message": "Order submitted successfully"
}
```

**ELK Stack 配置**：
- **Filebeat**：采集日志文件
- **Logstash**：解析和过滤
- **Elasticsearch**：存储和索引
- **Kibana**：可视化和查询

**关键查询**：
```
# 查找所有强平失败事件
event: "LIQUIDATION_FAILED" AND level: "ERROR"

# 查找特定账户的保证金历史
account_id: "acc-789" AND component: "margin_service"

# 查找高延迟订单
latency_ms: >100 AND event: "ORDER_SUBMITTED"
```

---

### 告警通知渠道

```go
type AlertService struct {
    slack    *SlackClient
    pagerduty *PagerDutyClient
    email    *EmailClient
}

func (s *AlertService) Send(severity string, title string, details map[string]interface{}) {
    switch severity {
    case "critical":
        // PagerDuty（立即通知 oncall）
        s.pagerduty.TriggerIncident(title, details)
        
        // Slack（#alerts-critical 频道）
        s.slack.SendToChannel("#alerts-critical", title, details)
        
    case "warning":
        // Slack（#alerts-warning 频道）
        s.slack.SendToChannel("#alerts-warning", title, details)
        
    case "info":
        // Email（每日摘要）
        s.email.AddToDailySummary(title, details)
    }
}
```

**告警升级策略**：
1. **Critical 告警**：立即 PagerDuty + Slack
2. **Warning 告警**：Slack 通知
3. **Info 告警**：每日邮件摘要
4. **未响应升级**：15 分钟无响应 → 升级到 manager

---

## 用户主动平仓流程

用户可以随时主动平仓（部分或全部），与强制平仓不同，主动平仓需要经过完整的风控检查。

### 平仓订单类型

```go
type ClosePositionOrder struct {
    OrderID      string
    AccountID    string
    PositionID   string
    CloseType    string  // "FULL" 或 "PARTIAL"
    Quantity     int64   // PARTIAL 时指定数量
    OrderType    string  // "MARKET" 或 "LIMIT"
    LimitPrice   decimal.Decimal  // LIMIT 时指定价格
    TimeInForce  string  // "GTC", "IOC", "FOK"
    CreatedAt    time.Time
}
```

---

### 完整平仓流程

```go
func (s *PositionService) ClosePosition(ctx context.Context, req *ClosePositionRequest) error {
    // 1. 验证持仓存在
    position, err := s.positionRepo.GetByID(ctx, req.PositionID)
    if err != nil {
        return errors.New("position not found")
    }
    
    // 2. 验证持仓归属
    if position.AccountID != req.AccountID {
        return errors.New("unauthorized: position does not belong to account")
    }
    
    // 3. 验证持仓状态
    if position.Status != "OPEN" {
        return errors.New("position is not open")
    }
    
    // 4. 验证平仓数量
    if req.CloseType == "PARTIAL" {
        if req.Quantity <= 0 || req.Quantity > position.Quantity {
            return errors.New("invalid close quantity")
        }
    } else {
        req.Quantity = position.Quantity  // 全部平仓
    }
    
    // 5. 生成平仓订单（反向订单）
    closeOrder := &Order{
        OrderID:     uuid.New().String(),
        AccountID:   req.AccountID,
        ContractID:  position.ContractID,
        Side:        s.getOppositeSide(position.Side),  // LONG → SELL, SHORT → BUY
        Quantity:    req.Quantity,
        OrderType:   req.OrderType,
        LimitPrice:  req.LimitPrice,
        TimeInForce: req.TimeInForce,
        Metadata: map[string]string{
            "close_position_id": req.PositionID,
            "close_type":        req.CloseType,
        },
        CreatedAt: time.Now().UTC(),
    }
    
    // 6. 风控检查（市价单跳过部分检查）
    if closeOrder.OrderType == "LIMIT" {
        if err := s.riskService.ValidateOrder(ctx, closeOrder); err != nil {
            return fmt.Errorf("risk check failed: %w", err)
        }
    }
    
    // 7. 提交订单
    if err := s.orderService.SubmitOrder(ctx, closeOrder); err != nil {
        return fmt.Errorf("failed to submit close order: %w", err)
    }
    
    // 8. 标记持仓为 CLOSING（防止重复平仓）
    position.Status = "CLOSING"
    position.CloseOrderID = closeOrder.OrderID
    s.positionRepo.Save(ctx, position)
    
    // 9. 发布事件
    s.eventBus.Publish(ctx, &PositionClosingEvent{
        PositionID: req.PositionID,
        OrderID:    closeOrder.OrderID,
        CloseType:  req.CloseType,
        Quantity:   req.Quantity,
    })
    
    return nil
}

func (s *PositionService) getOppositeSide(side string) string {
    if side == "LONG" {
        return "SELL"
    }
    return "BUY"
}
```

---

### 平仓成交处理

```go
func (s *PositionService) OnCloseFilled(ctx context.Context, fill *Fill) error {
    // 1. 查找关联持仓
    positionID := fill.Order.Metadata["close_position_id"]
    position, _ := s.positionRepo.GetByID(ctx, positionID)
    
    // 2. 计算已实现 P&L
    realizedPnL := s.calculateRealizedPnL(position, fill)
    
    // 3. 更新持仓
    closeType := fill.Order.Metadata["close_type"]
    if closeType == "FULL" {
        // 全部平仓 → 关闭持仓
        position.Status = "CLOSED"
        position.ClosedAt = time.Now().UTC()
        position.ClosePrice = fill.Price
        position.RealizedPnL = realizedPnL
        
    } else {
        // 部分平仓 → 减少数量
        position.Quantity -= fill.Quantity
        position.RealizedPnL = position.RealizedPnL.Add(realizedPnL)
        position.Status = "OPEN"  // 恢复为 OPEN
        
        // 如果剩余数量为 0，自动关闭
        if position.Quantity == 0 {
            position.Status = "CLOSED"
            position.ClosedAt = time.Now().UTC()
        }
    }
    
    s.positionRepo.Save(ctx, position)
    
    // 4. 释放保证金
    s.marginService.ReleaseMargin(ctx, position.AccountID, realizedPnL)
    
    // 5. 更新账户现金（已实现 P&L）
    s.accountService.UpdateCash(ctx, position.AccountID, realizedPnL)
    
    // 6. 发布事件
    s.eventBus.Publish(ctx, &PositionClosedEvent{
        PositionID:   positionID,
        CloseType:    closeType,
        ClosePrice:   fill.Price,
        RealizedPnL:  realizedPnL,
        ClosedAt:     time.Now().UTC(),
    })
    
    return nil
}

func (s *PositionService) calculateRealizedPnL(position *Position, fill *Fill) decimal.Decimal {
    // P&L = (ClosePrice - EntryPrice) × Quantity × Direction
    priceDiff := fill.Price.Sub(position.EntryPrice)
    
    if position.Side == "SHORT" {
        priceDiff = priceDiff.Neg()  // 做空时反向
    }
    
    return priceDiff.Mul(decimal.NewFromInt(fill.Quantity))
}
```

---

### 部分平仓示例

**场景**：用户持有 1000 股 AAPL CFD（多头），分两次平仓

```
初始持仓：
  - Quantity: 1000
  - EntryPrice: $150.00
  - CurrentPrice: $155.00
  - UnrealizedPnL: +$5,000

第一次平仓（部分）：
  - CloseQuantity: 400
  - ClosePrice: $155.00
  - RealizedPnL: (155 - 150) × 400 = +$2,000
  
  更新后持仓：
  - Quantity: 600
  - EntryPrice: $150.00（不变）
  - RealizedPnL: +$2,000
  - UnrealizedPnL: (155 - 150) × 600 = +$3,000

第二次平仓（全部剩余）：
  - CloseQuantity: 600
  - ClosePrice: $157.00
  - RealizedPnL: (157 - 150) × 600 = +$4,200
  
  最终持仓：
  - Status: CLOSED
  - TotalRealizedPnL: $2,000 + $4,200 = $6,200
```

---

### 平仓限制和检查

```go
func (s *RiskService) ValidateCloseOrder(ctx context.Context, order *Order) error {
    // 1. 市场时间检查
    if !s.isMarketOpen(order.ContractID) {
        return errors.New("market is closed")
    }
    
    // 2. 价格合理性检查（LIMIT 订单）
    if order.OrderType == "LIMIT" {
        currentPrice := s.pricing.GetPrice(order.ContractID)
        
        // 平仓价格不能偏离市价太远（防止误操作）
        maxDeviation := currentPrice.Mul(decimal.NewFromFloat(0.05))  // 5%
        priceDiff := order.LimitPrice.Sub(currentPrice).Abs()
        
        if priceDiff.GreaterThan(maxDeviation) {
            return errors.New("limit price deviates too much from market price")
        }
    }
    
    // 3. 账户状态检查
    account, _ := s.accountRepo.GetByID(ctx, order.AccountID)
    if account.Status == "SUSPENDED" || account.Status == "CLOSED" {
        return errors.New("account is not active")
    }
    
    // 4. 持仓锁定检查（防止并发平仓）
    position, _ := s.positionRepo.GetByID(ctx, order.Metadata["close_position_id"])
    if position.Status == "CLOSING" {
        return errors.New("position is already being closed")
    }
    
    return nil
}
```

---

### 平仓失败处理

```go
func (s *PositionService) OnCloseOrderRejected(ctx context.Context, order *Order, reason string) error {
    // 1. 恢复持仓状态
    positionID := order.Metadata["close_position_id"]
    position, _ := s.positionRepo.GetByID(ctx, positionID)
    
    if position.Status == "CLOSING" {
        position.Status = "OPEN"  // 恢复为 OPEN
        position.CloseOrderID = ""
        s.positionRepo.Save(ctx, position)
    }
    
    // 2. 通知用户
    s.notifyUser(ctx, order.AccountID, "平仓失败", reason)
    
    // 3. 记录审计日志
    s.auditRepo.Save(ctx, &AuditLog{
        EventType:   "CLOSE_ORDER_REJECTED",
        AccountID:   order.AccountID,
        PositionID:  positionID,
        OrderID:     order.OrderID,
        Reason:      reason,
        Timestamp:   time.Now().UTC(),
    })
    
    return nil
}
```

---

### 批量平仓（一键平仓）

```go
func (s *PositionService) CloseAllPositions(ctx context.Context, accountID string) error {
    // 1. 获取所有开仓持仓
    positions, _ := s.positionRepo.ListByAccount(ctx, accountID)
    openPositions := filterOpenPositions(positions)
    
    if len(openPositions) == 0 {
        return errors.New("no open positions to close")
    }
    
    // 2. 并发提交平仓订单
    var wg sync.WaitGroup
    errChan := make(chan error, len(openPositions))
    
    for _, pos := range openPositions {
        wg.Add(1)
        go func(position *Position) {
            defer wg.Done()
            
            err := s.ClosePosition(ctx, &ClosePositionRequest{
                AccountID:  accountID,
                PositionID: position.ID,
                CloseType:  "FULL",
                OrderType:  "MARKET",  // 一键平仓使用市价单
            })
            
            if err != nil {
                errChan <- err
            }
        }(pos)
    }
    
    wg.Wait()
    close(errChan)
    
    // 3. 收集错误
    var errors []error
    for err := range errChan {
        errors = append(errors, err)
    }
    
    if len(errors) > 0 {
        return fmt.Errorf("failed to close %d positions: %v", len(errors), errors)
    }
    
    // 4. 发布批量平仓事件
    s.eventBus.Publish(ctx, &BatchCloseEvent{
        AccountID:      accountID,
        PositionCount:  len(openPositions),
        Timestamp:      time.Now().UTC(),
    })
    
    return nil
}
```

---

### 平仓 vs 强平对比

| 维度 | 用户主动平仓 | 系统强制平仓 |
|------|------------|------------|
| **触发方式** | 用户手动操作 | 保证金比率 < 50% |
| **订单类型** | MARKET 或 LIMIT | 仅 MARKET |
| **风控检查** | 完整检查 | 跳过部分检查 |
| **执行优先级** | 正常 | 最高（紧急） |
| **延迟** | 无延迟 | 可配置（0-30s） |
| **通知** | 成交后通知 | 触发前 1h + 5min 警告 |
| **审计** | 标准审计 | 强化审计（原因、触发条件） |
| **费用** | 正常手续费 | 可能额外收取强平费 |

---

## 回测引擎与算法验证

CFD系统的回测引擎不仅用于验证交易策略，更重要的是**验证风控系统在极端市场下不会穿仓**。

### 回测目标对比

| 维度 | 传统量化回测 | CFD系统回测 |
|------|------------|-----------|
| **目标** | 验证交易策略盈利性 | 验证系统组件安全性 |
| **关注点** | Alpha、夏普比率 | 风控有效性、穿仓概率 |
| **测试对象** | 用户策略 | 保证金算法、强平引擎、LP选择 |
| **极端场景** | 可选 | **必须**（2020-03、2015-08闪崩） |
| **数据需求** | OHLCV | OHLCV + 点差 + LP行为 + 波动率 |

---

### 回测引擎架构

```go
type BacktestEngine struct {
    // 数据源
    marketData    HistoricalDataProvider
    lpSimulator   LPBehaviorSimulator
    
    // 被测系统组件
    marginCalc    MarginCalculator
    liquidation   LiquidationEngine
    router        SmartOrderRouter
    riskEngine    RiskEngine
    
    // 回测配置
    config        BacktestConfig
    
    // 结果收集
    metrics       *BacktestMetrics
    events        []BacktestEvent
}

type BacktestConfig struct {
    StartDate       time.Time
    EndDate         time.Time
    InitialCash     decimal.Decimal
    Leverage        int
    
    // 风控参数（待测试）
    MarginCallThreshold    float64  // 0.75
    LiquidationThreshold   float64  // 0.50
    
    // LP配置
    LPSpreadModel   string  // "FIXED", "DYNAMIC", "HISTORICAL"
    LPLatency       time.Duration
    LPRejectRate    float64
    
    // 测试场景
    Scenario        string  // "NORMAL", "FLASH_CRASH", "GAP_OPEN", "HIGH_VOLATILITY"
}
```

---

### 功能 1：风控参数回测

**目标**：找到最优的强平阈值，平衡用户体验和平台风险

```go
func (e *BacktestEngine) TestMarginThresholds(ctx context.Context) *ThresholdTestResult {
    // 测试不同的强平阈值组合
    thresholds := []struct {
        marginCall   float64
        liquidation  float64
    }{
        {0.80, 0.60},  // 宽松
        {0.75, 0.50},  // 标准
        {0.70, 0.40},  // 严格
    }
    
    results := make([]*ThresholdResult, 0)
    
    for _, threshold := range thresholds {
        // 1. 配置回测参数
        e.config.MarginCallThreshold = threshold.marginCall
        e.config.LiquidationThreshold = threshold.liquidation
        
        // 2. 运行回测
        result := e.runBacktest(ctx)
        
        // 3. 收集关键指标
        results = append(results, &ThresholdResult{
            MarginCallThreshold:  threshold.marginCall,
            LiquidationThreshold: threshold.liquidation,
            
            // 用户体验指标
            MarginCallCount:      result.MarginCallCount,
            LiquidationCount:     result.LiquidationCount,
            AvgTimeToLiquidation: result.AvgTimeToLiquidation,
            
            // 平台风险指标
            MaxDrawdown:          result.MaxDrawdown,
            NegativeBalanceCount: result.NegativeBalanceCount,  // 穿仓次数
            TotalLoss:            result.TotalLoss,
            
            // 财务指标
            TotalCommission:      result.TotalCommission,
            LiquidationFees:      result.LiquidationFees,
        })
    }
    
    // 4. 找到最优配置
    optimal := e.findOptimalThreshold(results)
    
    return &ThresholdTestResult{
        Results: results,
        Optimal: optimal,
    }
}
```

**输出示例**：
```
回测结果（2020-01-01 至 2020-12-31，包含3月闪崩）

配置 A（宽松）：
  - Margin Call: 80%, Liquidation: 60%
  - 强平次数: 45
  - 穿仓次数: 3 ⚠️
  - 平台损失: $12,500

配置 B（标准）：
  - Margin Call: 75%, Liquidation: 50%
  - 强平次数: 89
  - 穿仓次数: 0 ✅
  - 平台损失: $0

配置 C（严格）：
  - Margin Call: 70%, Liquidation: 40%
  - 强平次数: 156
  - 穿仓次数: 0 ✅
  - 平台损失: $0

推荐：配置 B（标准）
```

---

### 功能 2：算法订单回测

**目标**：验证新的Smart Routing算法是否真的降低了交易成本

```go
func (e *BacktestEngine) CompareRoutingAlgorithms(ctx context.Context) *AlgorithmComparisonResult {
    algorithms := []SmartOrderRouter{
        NewPriceOnlyRouter(),           // 基线：只看价格
        NewMultiFactorRouter(),         // 新算法：价格+速度+成交率
        NewMLBasedRouter(),             // ML算法：基于历史数据预测
    }
    
    results := make([]*RoutingResult, 0)
    
    for _, algo := range algorithms {
        e.router = algo
        result := e.runBacktest(ctx)
        
        results = append(results, &RoutingResult{
            AlgorithmName:    algo.Name(),
            AvgSpread:        result.AvgSpread,
            AvgSlippage:      result.AvgSlippage,
            AvgLatency:       result.AvgLatency,
            FillRate:         result.FillRate,
            TotalCost:        result.TotalCost,
        })
    }
    
    return &AlgorithmComparisonResult{
        Results: results,
        Winner:  findBestAlgorithm(results),
    }
}
```

---

### 功能 3：极端场景压力测试

```go
var HistoricalCrashes = []StressTestScenario{
    {
        Name:        "2020-03 COVID Crash",
        Description: "S&P 500 跌 34% in 23 days",
        DataRange:   DateRange{"2020-02-19", "2020-03-23"},
        Conditions: []MarketCondition{
            {Type: "VOLATILITY", Value: 80},
            {Type: "GAP_DOWN", Value: -12},
            {Type: "CIRCUIT_BREAKER", Count: 4},
        },
    },
    {
        Name:        "2015-08 China Crash",
        Description: "A股单日跌停潮",
        DataRange:   DateRange{"2015-08-24", "2015-08-25"},
        Conditions: []MarketCondition{
            {Type: "GAP_DOWN", Value: -8.5},
            {Type: "LIQUIDITY_DRY", Value: 0.1},
        },
    },
    {
        Name:        "2010-05 Flash Crash",
        Description: "9分钟跌 9%",
        DataRange:   DateRange{"2010-05-06 14:42", "2010-05-06 14:51"},
        Conditions: []MarketCondition{
            {Type: "RAPID_DROP", Value: -9},
            {Type: "SPREAD_EXPLOSION", Value: 10},
        },
    },
}
```

**压力测试输出**：
```
压力测试：2020-03 COVID Crash

杠杆 10x：
  - 强平时间: 2020-03-12 15:23:45
  - 最终余额: $1,250 ✅
  - 穿仓: 否

杠杆 30x：
  - 强平时间: 2020-03-09 09:35:12
  - 最终余额: -$340 ⚠️ 穿仓
  - 平台损失: $340

杠杆 50x：
  - 强平时间: 2020-03-09 09:31:08
  - 最终余额: -$1,820 ⚠️ 穿仓
  - 平台损失: $1,820

结论：
  - 10x 杠杆安全 ✅
  - 30x 杠杆有 15% 穿仓概率 ⚠️
  - 50x 杠杆有 45% 穿仓概率 ❌

建议：
  1. 限制最大杠杆为 30x
  2. 50x 杠杆仅对机构客户开放
  3. 增加风险基金至 $500K
```

---

### 功能 4：LP 行为模拟

```go
type LPBehaviorSimulator struct {
    historicalSpreads map[string][]SpreadSnapshot
    historicalLatency map[string][]LatencySnapshot
    rejectRate        float64
    requoteRate       float64
    maxSlippage       decimal.Decimal
}

func (s *LPBehaviorSimulator) SimulateQuote(
    ctx context.Context,
    contractID string,
    quantity int64,
    marketCondition MarketCondition,
) (*SimulatedQuote, error) {
    
    // 1. 基础点差（从历史数据）
    baseSpread := s.getHistoricalSpread(contractID, marketCondition.Timestamp)
    
    // 2. 根据市场条件调整点差
    adjustedSpread := baseSpread
    
    if marketCondition.Volatility > 30 {
        adjustedSpread = baseSpread.Mul(decimal.NewFromFloat(1.5))
    }
    
    if quantity > 10000 {
        adjustedSpread = adjustedSpread.Mul(decimal.NewFromFloat(1.2))
    }
    
    if marketCondition.Type == "GAP_OPEN" {
        adjustedSpread = baseSpread.Mul(decimal.NewFromFloat(4.0))
    }
    
    // 3. 模拟延迟
    latency := s.simulateLatency(marketCondition)
    
    // 4. 模拟拒单
    if rand.Float64() < s.rejectRate {
        return nil, errors.New("LP rejected order")
    }
    
    // 5. 模拟重新报价
    if rand.Float64() < s.requoteRate {
        return nil, errors.New("LP requoted - price changed")
    }
    
    return &SimulatedQuote{
        Bid:      marketCondition.Price.Sub(adjustedSpread.Div(decimal.NewFromInt(2))),
        Ask:      marketCondition.Price.Add(adjustedSpread.Div(decimal.NewFromInt(2))),
        Spread:   adjustedSpread,
        Latency:  latency,
        LP:       "SimulatedLP",
    }, nil
}
```

---

### 算法订单适用性分析

| 算法类型 | 传统证券 | CFD 适用性 | 改造方向 |
|---------|---------|-----------|---------|
| **VWAP** | ✅ 常用 | ❌ 不适用 | 无市场成交量数据 |
| **TWAP** | ✅ 常用 | ⚠️ 意义不大 | CFD 不影响市场价格 |
| **POV** | ✅ 常用 | ❌ 不适用 | 无市场成交量数据 |
| **Iceberg** | ✅ 常用 | ✅ 适用 | 改为对 LP 隐藏总量 |
| **Smart Routing** | ✅ 常用 | ✅ **非常适用** | 多 LP 之间选择最优报价 |
| **Spread-Sensitive** | ❌ 无 | ✅ **CFD 特有** | 等待点差收窄 |
| **Slippage Control** | ⚠️ 较少 | ✅ **CFD 重要** | 保护用户免受滑点损失 |
| **Rollover Optimizer** | ❌ 无 | ✅ **CFD 特有** | 优化展期成本 |

**CFD特有算法示例**：

```go
// 1. Spread-Sensitive Order（点差敏感订单）
type SpreadSensitiveOrder struct {
    ContractID      string
    Quantity        int64
    MaxSpread       decimal.Decimal  // 最大可接受点差
    TimeInForce     string
    ExpiresAt       time.Time
}

// 2. Slippage Control Order（滑点控制订单）
type SlippageControlOrder struct {
    ContractID      string
    Quantity        int64
    ReferencePrice  decimal.Decimal
    MaxSlippage     decimal.Decimal
    RetryCount      int
}

// 3. Iceberg Order（冰山订单 - CFD改造版）
type CFDIcebergOrder struct {
    TotalQuantity   int64
    SliceSize       int64
    MaxSlippage     decimal.Decimal
}
```

---

### 回测数据需求

```go
type BacktestDataProvider interface {
    // 基础市场数据
    GetOHLCV(symbol string, start, end time.Time) []OHLCV
    
    // CFD 特有数据
    GetHistoricalSpreads(symbol string, start, end time.Time) []SpreadSnapshot
    GetHistoricalVolatility(symbol string, start, end time.Time) []VolatilitySnapshot
    
    // LP 历史行为
    GetLPLatency(lpName string, start, end time.Time) []LatencySnapshot
    GetLPRejectRate(lpName string, start, end time.Time) []RejectRateSnapshot
    
    // 特殊事件
    GetCircuitBreakers(start, end time.Time) []CircuitBreakerEvent
    GetTradingHalts(start, end time.Time) []TradingHaltEvent
}
```

**数据来源**：
1. **市场数据**：Bloomberg、Reuters、交易所历史数据
2. **点差数据**：自己的生产环境记录（最准确）
3. **LP行为**：FIX日志分析
4. **波动率**：VIX、VHSI等波动率指数

---

### 回测引擎部署

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cfd-backtest-engine
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: backtest
        image: cfd-backtest:latest
        resources:
          requests:
            cpu: "4"
            memory: "16Gi"
        volumeMounts:
        - name: historical-data
          mountPath: /data
          readOnly: true
      volumes:
      - name: historical-data
        persistentVolumeClaim:
          claimName: historical-data-pvc
```

**回测引擎的价值**：

✅ **风控参数优化**：找到最优强平阈值  
✅ **算法验证**：证明新算法确实更好  
✅ **极端场景测试**：确保不会穿仓  
✅ **LP行为模拟**：真实反映执行环境  
✅ **合规验证**：满足监管要求  

**没有回测引擎 = 盲目上线 = 巨大风险**

建议在Phase 2就开始构建回测引擎，与风控系统并行开发。

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

**文档完成时间**：2026-04-07 12:00 UTC  
**最后更新**：2026-04-07 12:00 UTC（新增：数据一致性保证、监控告警系统、用户主动平仓流程、回测引擎与算法验证）  
**下一步**：进入 Phase 1 开发，首先实现 Domain 层和基础 Repository
