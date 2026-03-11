# 交易系统行业参考资料

> 互联网券商交易系统技术架构调研与最佳实践

本文档整理了互联网券商（美港股方向）交易系统的行业最佳实践、技术选型和架构设计参考资料。

---

## 1. 行业标杆券商技术方案

### 1.1 Robinhood（美国）

**公司背景**
- 美国最大的零佣金券商，2000万+ 用户
- 2021年上市（NASDAQ: HOOD）
- 主要市场：美股、期权、加密货币

**技术架构公开信息**

| 维度 | 方案 |
|------|------|
| 后端语言 | Python (Django) → Go 微服务化 |
| 数据库 | PostgreSQL (主) + MySQL |
| 缓存 | Redis Cluster |
| 消息队列 | Kafka |
| 基础设施 | AWS (全栈) |
| 订单路由 | 自研 SOR + Citadel Securities / Virtu |
| 清算 | Apex Clearing |

**架构演进**
- **2013-2015**: Django 单体应用
- **2016-2018**: 微服务化，拆分订单、账户、行情、清算服务
- **2019-2021**: Go 重写核心交易引擎，Python 保留业务逻辑层
- **2022+**: 应用层分片（Shard by User ID），支持千万级并发

**技术亮点**
- **零佣金模式**: 通过 PFOF (Payment for Order Flow) 向做市商出售订单流获利
- **实时行情**: WebSocket 推送，支持 Level 2 深度行情
- **Fractional Shares**: 支持碎股交易（0.000001 股起）

**参考资料**
- [Robinhood Engineering Blog](https://robinhood.engineering/)
- [Scaling to Millions of Users (2019)](https://robinhood.engineering/scaling-robinhoods-brokerage-platform-7bb3c5e0c18d)

---

### 1.2 Tiger Brokers 老虎证券（中国）

**公司背景**
- 中国领先的美港股券商，2019年上市（NASDAQ: TIGR）
- 800万+ 注册用户
- 主要市场：美股、港股、A股（沪港通）、新加坡、澳洲

**技术架构**

| 维度 | 方案 |
|------|------|
| 后端语言 | Java (Spring Boot) + Go (交易引擎) |
| 数据库 | MySQL (分库分表) + TiDB |
| 缓存 | Redis Cluster |
| 消息队列 | RocketMQ |
| 基础设施 | 阿里云 + AWS (多云) |
| 订单路由 | 自研 + Interactive Brokers |
| 清算 | 盈透证券 (IBKR) |

**技术亮点**
- **多市场支持**: 统一交易引擎支持美港股 A 股新加坡澳洲
- **Tiger Trade API**: 开放 API 供量化交易者使用
- **社区功能**: 内置社交网络（类似雪球）

**参考资料**
- [老虎证券技术博客](https://www.laohu8.com/tech)
- Tiger Trade API 文档

---

### 1.3 Futu 富途证券（中国香港）

**公司背景**
- 香港持牌券商，2019年上市（NASDAQ: FUTU）
- 1500万+ 注册用户
- 主要市场：港股、美股、A股（沪深港通）、新加坡

**技术架构**

| 维度 | 方案 |
|------|------|
| 后端语言 | C++ (核心引擎) + Java + Python |
| 数据库 | MySQL + PostgreSQL |
| 缓存 | Redis |
| 消息队列 | Kafka |
| 基础设施 | 自建 IDC + 腾讯云 |
| 行情数据 | HKEX OMD + Polygon (美股) |
| 清算 | 自有清算牌照 (香港) |

**技术亮点**
- **OpenD 网关**: 开源的行情/交易网关，支持 Python/C++/C#/Java
- **免费 Level 2**: 港股 Level 2 行情免费（行业首创）
- **FutuQuant**: 量化交易平台，支持回测和实盘

**开源项目**
- [futu-api-doc](https://github.com/FutunnOpen/futu-api-doc) - OpenD 协议文档
- [py-futu-api](https://github.com/FutunnOpen/py-futu-api) - Python SDK

**参考资料**
- [富途开放平台](https://openapi.futunn.com/)
- OpenD 架构设计文档

---

### 1.4 Longbridge 长桥证券（新加坡）

**公司背景**
- 新加坡持牌券商，2021年成立
- 主要市场：美股、港股、新加坡、A股
- 技术驱动型券商，公开技术信息最多

**技术架构**

| 维度 | 方案 |
|------|------|
| 后端语言 | **Rust (核心引擎) + Go (业务服务)** |
| 数据库 | PostgreSQL + TiDB |
| 缓存 | Redis Cluster |
| 消息队列 | Pulsar |
| 时序数据库 | ClickHouse |
| 基础设施 | AWS + 阿里云 (多云多活) |
| 行情数据 | HKEX OMD + Polygon |
| 清算 | 自有清算牌照 |

**技术亮点**
- **Rust 交易引擎**: 微秒级延迟，内存安全
- **云原生架构**: Kubernetes + Istio 服务网格
- **Whale 平台**: B2B SaaS，为 60+ 券商提供技术服务
- **端到端延迟**: 港股 < 20ms, 美股 < 100ms
- **99.95% 可用性**: 两地三中心异地多活

**公开技术分享**
- [长桥证券技术博客](https://longbridge.cloud/zh-CN/blog)
- [Rust 在金融交易系统中的实践](https://longbridge.cloud/zh-CN/blog/rust-in-trading)
- [微服务架构下的高可用设计](https://longbridge.cloud/zh-CN/blog/high-availability)

---

### 1.5 Interactive Brokers 盈透证券（美国）

**公司背景**
- 全球最大的电子券商，1978年成立
- 专业交易者首选，支持全球 150+ 市场
- 低佣金、高性能、专业工具

**技术架构**

| 维度 | 方案 |
|------|------|
| 后端语言 | C++ (核心) + Java |
| 数据库 | 自研分布式数据库 |
| 基础设施 | 自建全球数据中心 |
| 订单路由 | SmartRouting (自研 SOR) |
| API | TWS API (支持 10+ 语言) |

**技术亮点**
- **SmartRouting**: 智能订单路由，自动寻找最优价格和流动性
- **IB Gateway**: 轻量级交易网关，支持 API 交易
- **全球市场**: 支持股票、期权、期货、外汇、债券、基金
- **低延迟**: 直连交易所，延迟 < 1ms

**参考资料**
- [IB API 文档](https://interactivebrokers.github.io/)
- [TWS API 架构](https://www.interactivebrokers.com/en/trading/tws-api.php)

---

## 2. 订单管理系统 (OMS) 最佳实践

### 2.1 订单状态机设计

**行业标准状态机**（基于 FIX 协议）

```
CREATED → VALIDATED → RISK_APPROVED → PENDING → OPEN
                                                   ↓
                                          PARTIAL_FILL ⇄ (循环)
                                                   ↓
                                          FILLED / CANCELLED / REJECTED
```

**关键设计原则**
1. **状态转换必须原子**: 使用数据库事务或分布式锁
2. **Event Sourcing**: 所有状态变更记录为不可变事件
3. **幂等性**: 同一事件重复处理不改变最终状态
4. **终态不可逆**: FILLED/CANCELLED/REJECTED 后不允许任何转换

### 2.2 订单类型支持

| 订单类型 | 美股 | 港股 | 实现复杂度 | 说明 |
|---------|------|------|-----------|------|
| Market | ✅ | ✅ | 低 | 市价单，立即成交 |
| Limit | ✅ | ✅ | 低 | 限价单，指定价格或更优 |
| Stop | ✅ | ✅ | 中 | 止损单，触发后转为市价单 |
| Stop Limit | ✅ | ✅ | 中 | 止损限价，触发后转为限价单 |
| Trailing Stop | ✅ | ❌ | 高 | 追踪止损，动态调整触发价 |
| MOO | ✅ | ✅ | 中 | 开盘市价单 |
| MOC | ✅ | ✅ | 中 | 收盘市价单 |
| IOC | ✅ | ✅ | 中 | 立即成交或取消 |
| AON | ✅ | ❌ | 高 | 全部成交或不成交 |
| GTC | ✅ | ✅ | 低 | 有效直至取消 |

**实现建议**
- 先实现 Market + Limit + GTC/Day，覆盖 90% 用户需求
- Stop/Stop Limit 需要实时监控行情触发
- Trailing Stop 需要维护每个订单的动态触发价

---

## 3. 风控系统最佳实践

### 3.1 Pre-Trade 风控流水线

**8 级检查流水线**（按顺序执行，任一失败则拒单）

```
1. 账户状态检查 → 2. 标的检查 → 3. 订单有效性 → 4. 购买力
   ↓
5. 持仓限额 → 6. 频率限制 → 7. PDT 规则 → 8. 保证金要求
```

**各级检查详情**

| 级别 | 检查项 | 拒绝条件 | 响应时间 |
|------|--------|---------|---------|
| 1 | 账户状态 | 冻结/关闭/未激活 | < 1ms |
| 2 | 标的检查 | 停牌/退市/不支持 | < 1ms |
| 3 | 订单有效性 | 价格/数量/类型非法 | < 1ms |
| 4 | 购买力 | 可用资金不足 | < 2ms |
| 5 | 持仓限额 | 单标的/单市场超限 | < 1ms |
| 6 | 频率限制 | 单位时间订单数超限 | < 1ms |
| 7 | PDT 规则 | 日内交易次数超限 | < 2ms |
| 8 | 保证金 | 保证金不足 | < 2ms |

**总目标**: 全流程 < 5ms (p99)

### 3.2 PDT (Pattern Day Trader) 规则

**美国 FINRA 规定**
- 5 个交易日内进行 4 次或以上日内交易 → 标记为 PDT
- PDT 账户最低净值要求: $25,000
- 低于 $25,000 的 PDT 账户禁止日内交易

**实现方案**
```sql
-- 统计过去 5 个交易日的日内交易次数
SELECT COUNT(*) FROM day_trades
WHERE account_id = ? AND trade_date >= ?
```

**日内交易判定**
- 同一标的在同一交易日内 **先买后卖** 或 **先卖后买**
- 必须是 **完全平仓** 才算一次日内交易

---

## 4. FIX 协议集成

### 4.1 FIX 协议版本

| 交易所 | FIX 版本 | 连接方式 |
|--------|---------|---------|
| NYSE | FIX 4.2 | TCP + TLS |
| NASDAQ | FIX 4.4 | TCP + TLS |
| HKEX | FIX 4.2 | TCP (专线) |

### 4.2 核心消息类型

| MsgType | 名称 | 方向 | 用途 |
|---------|------|------|------|
| D | NewOrderSingle | 券商 → 交易所 | 提交新订单 |
| F | OrderCancelRequest | 券商 → 交易所 | 取消订单 |
| G | OrderCancelReplaceRequest | 券商 → 交易所 | 改单 |
| 8 | ExecutionReport | 交易所 → 券商 | 订单状态更新/成交回报 |
| 9 | OrderCancelReject | 交易所 → 券商 | 取消请求被拒绝 |
| j | BusinessMessageReject | 交易所 → 券商 | 消息格式错误 |

### 4.3 FIX 引擎选型

| 方案 | 语言 | 优点 | 缺点 |
|------|------|------|------|
| QuickFIX | C++/Java/Go | 成熟稳定，社区活跃 | 配置复杂 |
| QuickFIX/Go | Go | 原生 Go，性能好 | 文档较少 |
| 自研 | Go/Rust | 完全可控，极致性能 | 开发成本高 |

**推荐**: QuickFIX/Go (开源 + 性能平衡)

---

## 5. 智能订单路由 (SOR)

### 5.1 Best Execution 义务

**美国 Reg NMS 要求**
- 券商必须将订单路由至 **NBBO (National Best Bid and Offer)** 或更优价格
- 必须考虑价格、速度、成交概率、成本

**评分模型示例**

```
Score = w1 × PriceScore + w2 × LiquidityScore + w3 × LatencyScore + w4 × CostScore

其中:
- PriceScore: 价格优势 (与 NBBO 的差距)
- LiquidityScore: 流动性深度
- LatencyScore: 延迟 (ms)
- CostScore: 手续费 + Rebate
```

### 5.2 美股主要交易所

| 交易所 | 市场份额 | 特点 |
|--------|---------|------|
| NYSE | ~25% | 传统交易所，大盘股流动性好 |
| NASDAQ | ~20% | 科技股主场 |
| IEX | ~3% | 反高频交易，350μs 延迟 |
| CBOE BZX | ~5% | 低费用 |
| Dark Pools | ~15% | 大单匿名交易 |

---

## 6. 持仓与 P&L 计算

### 6.1 成本计算方法

**FIFO (First In First Out)** — 美国税法要求

```
买入: AAPL 100股 @ $150
买入: AAPL 50股 @ $155
卖出: AAPL 120股 @ $160

成本计算:
- 前 100 股成本 = $150
- 后 20 股成本 = $155
- 平均成本 = (100×150 + 20×155) / 120 = $151.67
```

**平均成本法** — 港股常用

```
买入: 0700.HK 1000股 @ HK$300
买入: 0700.HK 500股 @ HK$310
平均成本 = (1000×300 + 500×310) / 1500 = HK$303.33
```

### 6.2 P&L 计算公式

```
未实现盈亏 = (当前市价 - 平均成本) × 持仓数量
已实现盈亏 = Σ (卖出价 - 成本价) × 卖出数量
日内盈亏 = (当前市价 - 昨收价) × 持仓数量
```

---

## 7. 结算系统

### 7.1 结算周期

| 市场 | 结算周期 | 说明 |
|------|---------|------|
| 美股 | T+1 | 2024年5月起从 T+2 缩短至 T+1 |
| 港股 | T+2 | 交易日后第 2 个工作日 |
| A股 | T+1 | 当日卖出，次日可取 |

### 7.2 公司行动处理

**分红 (Dividend)**
```
Ex-Date: 除息日，持有股票的最后一天
Record Date: 登记日
Pay Date: 派息日

处理逻辑:
- Ex-Date 前持有 → 有权获得分红
- 自动入账到现金余额
- 扣除预提税 (美股 30%, 港股 0%)
```

**拆股 (Stock Split)**
```
4:1 拆股 (Forward Split)
- 持仓: 100股 @ $400 → 400股 @ $100
- 成本不变: $40,000

1:4 并股 (Reverse Split)
- 持仓: 400股 @ $10 → 100股 @ $40
- 成本不变: $4,000
```

---

## 8. 手续费计算

### 8.1 美股手续费

| 费用项 | 计算方式 | 收取方 |
|--------|---------|--------|
| 佣金 | 固定 (如 $0) 或按股 | 券商 |
| SEC Fee | $8 / $1M 成交额 | SEC |
| TAF | $0.000166 / 股 (卖出) | FINRA |
| 交易所费用 | 按交易所规则 | 交易所 |

**示例**
```
卖出 AAPL 100股 @ $150
成交额 = $15,000
SEC Fee = 15,000 × 8 / 1,000,000 = $0.12
TAF = 100 × 0.000166 = $0.0166
总费用 = $0.12 + $0.02 = $0.14
```

### 8.2 港股手续费

| 费用项 | 计算方式 | 收取方 |
|--------|---------|--------|
| 佣金 | 0.03% (最低 HK$3) | 券商 |
| 印花税 | 0.13% | 香港政府 |
| 交易征费 | 0.0027% | SFC |
| 交易费 | 0.00565% | HKEX |
| 结算费 | 0.002% (最低 HK$2, 最高 HK$100) | HKSCC |

**示例**
```
买入 0700.HK 1000股 @ HK$300
成交额 = HK$300,000
佣金 = 300,000 × 0.0003 = HK$90
印花税 = 300,000 × 0.0013 = HK$390
交易征费 = 300,000 × 0.000027 = HK$8.1
交易费 = 300,000 × 0.0000565 = HK$16.95
结算费 = 300,000 × 0.00002 = HK$6
总费用 = HK$511.05
```

---

## 9. 技术选型建议

### 9.1 编程语言

| 语言 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| **Go** | 交易引擎、API 网关 | 高并发、低延迟、易部署 | 生态不如 Java |
| **Rust** | 核心引擎、行情处理 | 极致性能、内存安全 | 学习曲线陡 |
| Java | 业务服务、后台管理 | 生态成熟、人才多 | 内存占用大 |
| Python | 数据分析、回测 | 开发快、库丰富 | 性能差 |

**推荐组合**: Go (主力) + Rust (可选，极致性能场景)

### 9.2 数据库

| 数据库 | 用途 | 理由 |
|--------|------|------|
| PostgreSQL | 订单、账户、持仓 | ACID、JSON 支持、成熟 |
| Redis | 缓存、会话、行情 | 高性能、Pub/Sub |
| TimescaleDB | 行情历史、K线 | 时序数据优化 |
| ClickHouse | 审计日志、分析 | 列存、查询快 |

### 9.3 消息队列

| MQ | 适用场景 | 优点 | 缺点 |
|-----|---------|------|------|
| **Kafka** | 订单事件、行情分发 | 高吞吐、持久化、回溯 | 运维复杂 |
| RocketMQ | 业务消息 | 国内生态好 | 社区不如 Kafka |
| Pulsar | 多租户场景 | 存储计算分离 | 相对新 |

**推荐**: Kafka (行业标准)

---

## 10. 监控与告警

### 10.1 核心指标

| 指标 | 目标 | 告警阈值 |
|------|------|---------|
| 订单提交延迟 | < 10ms (p99) | > 50ms |
| 风控检查延迟 | < 5ms (p99) | > 20ms |
| FIX 消息延迟 | < 5ms (p99) | > 30ms |
| 订单成功率 | > 99.9% | < 99% |
| 系统可用性 | > 99.99% | < 99.9% |
| 持仓计算误差 | 0 | > $0.01 |

### 10.2 告警规则

```yaml
# Prometheus 告警规则示例
groups:
  - name: trading_engine
    rules:
      - alert: HighOrderLatency
        expr: histogram_quantile(0.99, order_submit_duration_seconds) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "订单提交延迟过高"

      - alert: OrderRejectionRateHigh
        expr: rate(orders_rejected_total[5m]) / rate(orders_submitted_total[5m]) > 0.01
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "订单拒绝率超过 1%"
```

---

## 11. 合规与审计

### 11.1 审计日志要求

**SEC Rule 17a-4 要求**
- 所有订单、成交、账户变更必须记录
- 保留期: 最少 7 年
- 不可篡改 (WORM: Write Once Read Many)

**实现方案**
- 使用 Event Sourcing 模式
- 存储到 S3 Object Lock 或 Elasticsearch
- 每日备份到离线存储

### 11.2 必须记录的事件

```json
{
  "event_type": "ORDER_SUBMITTED",
  "timestamp": "2026-03-15T09:30:00.123Z",
  "user_id": 12345,
  "account_id": 67890,
  "order_id": "ord-abc123",
  "symbol": "AAPL",
  "side": "BUY",
  "quantity": 100,
  "price": "150.25",
  "order_type": "LIMIT",
  "ip_address": "192.168.1.1",
  "device_id": "ios-device-xyz",
  "risk_result": {"approved": true},
  "correlation_id": "req-456def"
}
```

---

## 12. 参考资源

### 12.1 官方文档

- [FINRA Rules](https://www.finra.org/rules-guidance)
- [SEC Regulations](https://www.sec.gov/rules)
- [HKEX Trading Rules](https://www.hkex.com.hk/Rules-and-Regulations)
- [FIX Protocol Specification](https://www.fixtrading.org/standards/)

### 12.2 开源项目

- [QuickFIX/Go](https://github.com/quickfixgo/quickfix) - FIX 协议引擎
- [Futu OpenD](https://github.com/FutunnOpen/futu-api-doc) - 富途开放网关
- [Alpaca Trade API](https://github.com/alpacahq/alpaca-trade-api-go) - 美股交易 API

### 12.3 技术博客

- [Robinhood Engineering](https://robinhood.engineering/)
- [Longbridge Tech Blog](https://longbridge.cloud/zh-CN/blog)
- [Interactive Brokers API](https://interactivebrokers.github.io/)

---

## 总结

本文档整理了互联网券商交易系统的行业最佳实践，核心要点：

1. **技术栈**: Go/Rust 为主，PostgreSQL + Redis + Kafka
2. **订单管理**: 11 级状态机 + Event Sourcing
3. **风控**: 8 级 Pre-Trade 流水线，< 5ms
4. **FIX 协议**: QuickFIX/Go，支持 NYSE/NASDAQ/HKEX
5. **智能路由**: Best Execution 算法，符合 Reg NMS
6. **持仓 P&L**: FIFO (美股) / 平均成本 (港股)
7. **结算**: T+1 (美股) / T+2 (港股)
8. **合规**: SEC 17a-4，7 年审计日志

**行业标杆**: Longbridge (技术最先进)、Robinhood (用户最多)、Interactive Brokers (专业首选)
