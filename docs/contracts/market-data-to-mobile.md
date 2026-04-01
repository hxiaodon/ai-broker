---
provider: services/market-data
consumer: mobile
protocol: REST + WebSocket
openapi_spec: docs/openapi/market_data/
websocket_spec: services/market-data/docs/specs/websocket-spec.md
status: APPROVED
version: 1.1
created: 2026-03-13
last_updated: 2026-03-31
last_reviewed: 2026-03-22
approved_by: market-data-engineer, mobile-engineer
approved_date: 2026-03-22
sync_strategy: provider-owns
---

# Market Data → Mobile 接口契约

## 契约范围

移动端行情展示、K 线图表、股票搜索、自选股管理、实时报价推送。Market Data 为 Flutter 移动客户端提供完整的行情数据能力，包括实时/延时报价、多周期 K 线、股票搜索与详情、用户自选股列表管理、以及市场开收盘状态。

---

## 权威规范引用

本契约约束以下权威规范（实现时必读，所有详细定义均在本地 specs 中）：

| 规范 | 位置 | 版本 | 主要内容 |
|------|------|------|---------|
| **REST API 规范** | [`services/market-data/docs/specs/market-api-spec.md`](../../services/market-data/docs/specs/market-api-spec.md) | v2.0 | 10 个接口完整定义、请求/响应示例、错误码、限流规则、is_stale 字段 |
| **WebSocket 协议** | [`services/market-data/docs/specs/websocket-spec.md`](../../services/market-data/docs/specs/websocket-spec.md) | v2.0 | 认证流程、双轨推送、心跳机制、错误码、is_stale 字段 |
| **系统架构** | [`services/market-data/docs/specs/market-data-system.md`](../../services/market-data/docs/specs/market-data-system.md) | v2.1 | 合规前提、复权规范（附录 C）、Stale 处理（附录 D）、数据库 DDL（§7） |
| **场景加载指南** | [`services/market-data/docs/README-INDEX.md`](../../services/market-data/docs/README-INDEX.md) | v2.1 | 按使用场景加载 specs（避免全量阅读），关键约定速查表 |

> **重要**：契约本身仅定义边界和 SLA；所有接口细节（参数、响应字段、错误处理）均在上述权威规范中。实现或集成前，**必须阅读对应的 spec 章节**。

---

## 接口列表

### REST Endpoints

完整接口规范及请求/响应示例详见：
**[services/market-data/docs/specs/market-api-spec.md §2](../../services/market-data/docs/specs/market-api-spec.md#2-接口列表)**

| 方法 | 路径 | 用途 | SLA | Spec 链接 |
|------|------|------|-----|-----------|
| GET | /v1/market/quotes | 批量行情快照（最多 50 只） | < 200ms (P99) | [§2.1](../../services/market-data/docs/specs/market-api-spec.md#21-getv1marketquotes) |
| GET | /v1/market/kline | K 线数据（1min/5min/15min/30min/1h/1D/1W/1M） | < 200ms (P99, Redis); < 500ms (MySQL) | [§2.2](../../services/market-data/docs/specs/market-api-spec.md#22-getv1marketkline) |
| GET | /v1/market/search | 股票搜索（名称、代码、拼音模糊匹配，US + HK） | < 300ms (P99) | [§2.3](../../services/market-data/docs/specs/market-api-spec.md#23-getv1marketsearch) |
| GET | /v1/market/movers | 涨跌幅榜 / 热门榜 | < 500ms (P99) | [§2.4](../../services/market-data/docs/specs/market-api-spec.md#24-getv1marketmovers) |
| GET | /v1/market/stocks/{symbol} | 股票详情：基本面、财报摘要 | < 500ms (P99) | [§2.5](../../services/market-data/docs/specs/market-api-spec.md#25-getv1marketstockssymbol) |
| GET | /v1/market/news/{symbol} | 相关新闻 | < 500ms (P99) | [§2.6](../../services/market-data/docs/specs/market-api-spec.md#26-getv1marketnewssymbol) |
| GET | /v1/market/financials/{symbol} | 财报数据 | < 500ms (P99) | [§2.7](../../services/market-data/docs/specs/market-api-spec.md#27-getv1marketfinancialssymbol) |
| GET | /v1/watchlist | 获取自选股列表（含最新报价） | < 300ms (P99) | [§2.8](../../services/market-data/docs/specs/market-api-spec.md#28-getv1watchlist) |
| POST | /v1/watchlist | 添加自选（symbol + market） | < 200ms (P99) | [§2.9](../../services/market-data/docs/specs/market-api-spec.md#29-postv1watchlist) |
| DELETE | /v1/watchlist/{symbol} | 删除自选 | < 200ms (P99) | [§2.10](../../services/market-data/docs/specs/market-api-spec.md#210-deletev1watchlistsymbol) |

**关键字段说明**：
- `is_stale` — 所有行情响应必须包含，详见 [market-api-spec.md §1.7](../../services/market-data/docs/specs/market-api-spec.md#17-数据质量字段is_stale)
- `delayed` — 游客访问行情时为 `true`（延迟 15 分钟），注册用户为 `false`
- `market_status` 枚举 — 详见 [market-api-spec.md §1.4](../../services/market-data/docs/specs/market-api-spec.md#14-市场状态枚举)
- 价格精度 — 美股 4 位小数，港股 3 位小数，详见 [market-api-spec.md §1.2](../../services/market-data/docs/specs/market-api-spec.md#12-数据类型规范)

### WebSocket 推送

完整协议规范详见：
**[services/market-data/docs/specs/websocket-spec.md](../../services/market-data/docs/specs/websocket-spec.md)**

| 频道 | 用途 | 认证要求 | Spec 链接 |
|------|------|---------|-----------|
| `quote.realtime` | 实时报价推送（支持多 symbol 订阅/退订） | JWT Bearer token（消息级认证） | [§3.1](../../services/market-data/docs/specs/websocket-spec.md#31-实时报价推送频道) |

**WebSocket 特性**：
- **认证方式** — 连接后 5s 内发送消息级 JWT，不使用 URL query param（安全最佳实践），详见 [websocket-spec.md §2](../../services/market-data/docs/specs/websocket-spec.md#2-认证流程)
- **双轨推送** — 注册用户获实时 tick；游客获 T-15min 快照（每 5s 推送一次），详见 [websocket-spec.md §3](../../services/market-data/docs/specs/websocket-spec.md#3-推送频道)
- **心跳机制** — Ping/Pong，详见 [websocket-spec.md §4](../../services/market-data/docs/specs/websocket-spec.md#4-心跳机制)
- **是否陈旧** — 所有推送包含 `is_stale` 字段，详见 [websocket-spec.md §1.7](../../services/market-data/docs/specs/websocket-spec.md#17-数据质量字段is_stale)

## 数据流向

Market Data 通过以下模式为 Mobile 客户端提供行情数据：

- **REST 快照** — 客户端主动查询行情快照、K 线、搜索结果、自选股列表（详见上述接口规范）
- **WebSocket 推送** — 服务端向已订阅的客户端推送实时报价增量（价格、成交量、市场状态变化）
  - 注册用户 — 实时 tick 推送，无延迟
  - 游客 — T-15 分钟快照，每 5 秒推送一次（内存中 DelayedQuoteRingBuffer）
- **自选股列表** — 用户维度持久化存储（MySQL），支持 CRUD 操作

详细数据流架构见 **[market-data-system.md §2](../../services/market-data/docs/specs/market-data-system.md#2-整体架构)** 和 **[data-flow.md](../../services/market-data/docs/specs/data-flow.md)**。

## 业务规则与合规要求

本契约受以下业务规则约束（实现时必须遵守）：

| 规则 | 描述 | Spec 链接 |
|------|------|-----------|
| **数据陈旧检测** | `is_stale=true` 时交易风控拒绝市价单；前端 stale_since_ms ≥ 5s 时显示警告横幅 | [market-data-system.md 附录 D](../../services/market-data/docs/specs/market-data-system.md#附录-d-数据质量与-stale-quote-处理) |
| **复权处理** | 历史日线/周线/月线使用 Split + Dividend 完全后复权；实时报价和涨跌幅不复权；涨跌幅基准 = 前一交易日 Regular Session Close（16:00 ET） | [market-data-system.md 附录 C](../../services/market-data/docs/specs/market-data-system.md#附录-c-公司行动与价格调整) + [market-api-spec.md §1.9](../../services/market-data/docs/specs/market-api-spec.md#19-复权说明) |
| **市场时段感知** | NYSE/NASDAQ 9:30-16:00 ET（含盘前、盘后），HKEX 9:30-16:00 HKT；市场状态 HALTED 时客户端禁止新市价单 | [market-data-system.md §1.2](../../services/market-data/docs/specs/market-data-system.md#12-市场覆盖范围与时段) |
| **指数数据** | Phase 1 使用 ETF 代理（SPY/QQQ/DIA），显示须标注"追踪 XXX 指数"而非指数本身 | [market-data-system.md §0](../../services/market-data/docs/specs/market-data-system.md#0-合规前提与业务约束) |
| **数据授权** | Polygon Poly.feed+ 用于客户端显示；合规数据来源见  [`docs/references/market-data-industry-research.md`](../../docs/references/market-data-industry-research.md) | [market-data-system.md §0](../../services/market-data/docs/specs/market-data-system.md#0-合规前提与业务约束) |

## 变更流程

所有接口或业务规则的变更遵循以下流程（详见 **[services/market-data/docs/specs/market-api-spec.md §0](../../services/market-data/docs/specs/market-api-spec.md)** 的变更流程）：

1. **发起变更** — 任何一方在 `docs/threads/` 开 thread（命名：`market-to-mobile-{feature}`）
2. **评估影响** — 双方讨论
   - 接口兼容性（向后兼容 vs 新版本）
   - SLA 影响
   - 消费方改动量（客户端适配）
3. **方案一致** — 双方达成共识后，同步更新：
   - Market Data 本地 spec（`services/market-data/docs/specs/*.md`）
   - 本契约文件（`docs/contracts/market-data-to-mobile.md`），version +1
4. **闭环** — Thread 标记 RESOLVED，changelog 更新

## Changelog

### v1.1 (2026-03-31)
- **补充权威规范引用** — 所有接口细节现已链接到 market-data 本地 specs（market-api-spec v2.0、websocket-spec v2.0、market-data-system v2.1）
- **清除占位符** — 接口列表已完整定义，不再是初始占位
- **补充业务规则** — 新增"业务规则与合规要求"章节，覆盖 Stale 处理、复权规范、市场时段感知、指数数据、数据授权
- **优化变更流程** — 明确化本契约与本地 specs 的同步关系
- **路径统一** — REST 接口路径统一为 `/v1/market/{endpoint}` 和 `/v1/watchlist`

### v1 (2026-03-22)
- Initial contract approved
- Defined REST endpoints with SLA targets (P99 latency)
- Defined WebSocket real-time quote push channel
- Established authentication requirements and rate limits
