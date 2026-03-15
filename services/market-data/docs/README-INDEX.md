---
type: doc-index
version: v2.1
date: 2026-03-15
---

# Market Data Service — 文档索引

> 按需加载，避免全量阅读。先读本文，按场景找到目标文档。

---

## 文档体系

| 文档 | 版本 | 说明 | 主要读者 |
|------|------|------|---------|
| [market-data-system.md](./specs/market-data-system.md) | **v2.1** | 系统架构全貌（含合规前提、复权规范、Stale 处理、历史回填） | 后端工程师、架构师 |
| [market-api-spec.md](./specs/market-api-spec.md) | **v2.1** | REST API 完整规范（含 is_stale 字段、涨跌幅基准定义、复权说明） | 前端、移动端、后端 |
| [websocket-mock.md](./specs/websocket-mock.md) | **v2.1** | WebSocket 协议完整规范（含 is_stale 字段） | 前端、移动端、后端 |
| [data-flow.md](./specs/data-flow.md) | **v2.1** | 数据流架构（含历史数据冷启动方案） | 后端工程师 |

**关联文档：**
- 产品需求：[mobile/docs/prd/03-market.md](../../../../mobile/docs/prd/03-market.md)（权威 PRD）
- 行业调研：[docs/references/market-data-industry-research.md](../../../../docs/references/market-data-industry-research.md)（知识来源）
- 评审 Thread：[mobile/docs/threads/2026-03-prd-03-market-data-review/](../../../../mobile/docs/threads/2026-03-prd-03-market-data-review/_index.md)

---

## 按场景加载

### 场景 1：理解整体架构
```
market-data-system.md  §0 合规前提 + §1 系统概述 + §2 整体架构 + §4 访客双轨推送架构
```

### 场景 2：实现 REST API
```
market-api-spec.md  （全部，共 10 个接口）
market-data-system.md  §7 MySQL 数据模型
```

### 场景 3：实现 WebSocket 推送
```
websocket-mock.md        （全部，含认证流程、双轨推送、is_stale）
data-flow.md             §3 访客双轨推送 + §5 Mock/生产切换
market-data-system.md    §4 访客双轨推送架构（DelayedQuoteRingBuffer）
```

### 场景 4：实现 K 线图（含复权）
```
market-data-system.md    附录 C 复权处理规范（公式、各场景策略）
market-data-system.md    §3.3.2 KlineAggregator
market-api-spec.md       GET /v1/market/kline 接口规范（含 adjusted 说明）
```

### 场景 5：数据库 Schema
```
market-data-system.md    §7 MySQL 数据模型（8 张表完整 DDL）
scripts/init_db.sql      （已有实现，需按新 DDL 更新）
```

### 场景 6：配置数据源（Mock / Polygon / Kafka）
```
data-flow.md             §5 Mock vs 生产切换
config/config.yaml       data_source: mock | polygon | kafka
```

### 场景 7：历史数据初始化（冷启动）
```
market-data-system.md    §14 历史数据初始化与回填
data-flow.md             历史数据初始化（冷启动）章节
```

### 场景 8：数据质量监控（Stale 处理）
```
market-data-system.md    附录 D 数据质量与 Stale Quote 处理
market-api-spec.md       §1.7 is_stale 字段定义
```

### 场景 9：合规评审（数据授权）
```
market-data-system.md    §0 合规前提（必读）
docs/references/market-data-industry-research.md  §1 数据授权与合规
```

### 场景 10：部署和运维
```
market-data-system.md    §13 Phase 1 部署方案 + §11 监控告警
```

---

## 关键约定（所有文档统一遵守）

| 约定 | 规则 |
|------|------|
| 价格字段类型 | JSON 中全部用 `string`（如 `"182.5200"`），SQL 用 `DECIMAL(20,4)` |
| 时间戳格式 | JSON 中 ISO 8601（`"2026-03-13T14:30:00.000Z"`），SQL 用 `DATETIME(3)` UTC |
| `delayed` 字段 | 所有行情响应必须包含（`true` = 访客延迟15分钟行情） |
| `is_stale` 字段 | 所有行情响应必须包含（`true` = 数据超过5s展示阈值） |
| `market_status` 枚举 | `REGULAR \| PRE_MARKET \| AFTER_HOURS \| CLOSED \| HALTED` |
| WebSocket 消息 | 客户端→服务端用 `"action"` 字段；服务端→客户端用 `"type"` 字段 |
| `symbols` 上限 | 单次订阅/查询最多 50 个 |
| Watchlist 上限 | 每用户 100 只（应用层检查） |
| 涨跌幅基准 | 前一个交易日 Regular Session Close（16:00 ET），非盘后收盘价 |
| 复权策略 | 历史日线全复权（Split+Dividend 后复权）；实时报价和涨跌幅不复权 |
| 大盘指数 | Phase 1 使用 ETF 替代（SPY/QQQ/DIA），标注"追踪 XXX" |
| 数据来源披露 | 行情展示页面须标注"数据由 Polygon.io 提供" |

---

## 待办事项（Phase 1）

- [ ] `scripts/init_db.sql` 按 v2.1 DDL 更新（新增 pinyin_initials、shares_outstanding、is_stale 相关字段）
- [ ] **确认数据授权路径**（Poly.feed+ vs Vendor Agreement）→ 影响系统架构，**P0 阻塞项**
- [ ] 实现 `is_stale` 字段注入（Processing Engine 层）
- [ ] 实现 DelayedQuoteRingBuffer（见 market-data-system.md §4）
- [ ] 实现 `/v1/market/movers` 涨跌幅榜接口
- [ ] 实现复权处理（Split 用 Polygon adjusted=true；Dividend 在应用层叠加）
- [ ] 搜索接口补充 pinyin_initials 支持
- [ ] 历史数据回填脚本（见 market-data-system.md §14）
- [ ] NYSE 交易日历维护（见 §14.5）
- [ ] 确认新闻数据源（Polygon News API 或 Finnhub）
- [ ] 了解 LULD 熔断机制（market_status=HALTED 触发条件）

---

## 版本历史

| 版本 | 日期 | 主要变更 |
|------|------|---------|
| **v2.1** | **2026-03-15** | **新增：§0 合规前提（数据授权/ETF替代）、附录 C 复权处理、附录 D Stale 处理、§14 历史回填；更新：is_stale 字段加入所有响应、涨跌幅基准明确定义** |
| v2.0 | 2026-03-14 | 对齐 PRD-03 v1.1：访客双轨推送、WebSocket 协议重写、REST API 路径统一、MySQL DDL 完整化 |
| v1.0 | 2026-03-07 | 初始版本 |

> 按需加载，避免全量阅读。先读本文，按场景找到目标文档。

---

## 文档体系

| 文档 | 版本 | 说明 | 主要读者 |
|------|------|------|---------|
| [market-data-system.md](./specs/market-data-system.md) | v2.0 | 系统架构全貌（数据流、缓存、存储、高可用、部署） | 后端工程师、架构师 |
| [market-api-spec.md](./specs/market-api-spec.md) | v2.0 | REST API 完整规范（10 个接口，请求/响应示例） | 前端、移动端、后端 |
| [websocket-mock.md](./specs/websocket-mock.md) | v2.0 | WebSocket 协议完整规范（认证/订阅/双轨推送/心跳） | 前端、移动端、后端 |
| [data-flow.md](./specs/data-flow.md) | v2.0 | 数据流架构（Feed → Engine → Redis → WS → MySQL） | 后端工程师 |

**关联 PRD**：[mobile/docs/prd/03-market.md](../../../../mobile/docs/prd/03-market.md)（权威产品需求）

---

## 按场景加载

### 场景 1：理解整体架构
```
market-data-system.md  §1 系统概述 + §2 整体架构图 + §4 访客双轨推送架构
```

### 场景 2：实现 REST API
```
market-api-spec.md  （全部，共 10 个接口）
market-data-system.md  §7 MySQL 数据模型（DDL 参考）
```

### 场景 3：实现 WebSocket 推送
```
websocket-mock.md   （全部，含认证流程、双轨推送、错误码）
data-flow.md        §3 访客双轨推送 + §5 Mock/生产切换
market-data-system.md  §4 访客双轨推送架构（DelayedQuoteRingBuffer 实现）
```

### 场景 4：实现 K 线聚合
```
market-data-system.md  §3.3.2 Aggregator（KlineAggregator, KlineBuilder 代码）
market-data-system.md  §7 klines 表 DDL
market-api-spec.md     GET /v1/market/kline 接口规范
```

### 场景 5：数据库 Schema
```
market-data-system.md  §7 MySQL 数据模型（8 张表完整 DDL）
scripts/init_db.sql    （已有实现，需按新 DDL 更新）
```

### 场景 6：配置数据源（Mock / Polygon / Kafka）
```
data-flow.md  §5 Mock vs 生产切换
config/config.yaml    data_source: mock | polygon | kafka
```

### 场景 7：部署和运维
```
market-data-system.md  §13 Phase 1 部署方案 + §11 监控告警
```

---

## 关键约定（所有文档统一遵守）

| 约定 | 规则 |
|------|------|
| 价格字段类型 | JSON 中全部用 `string`（如 `"182.5200"`），SQL 用 `DECIMAL(20,4)` |
| 时间戳格式 | JSON 中 ISO 8601（`"2026-03-13T14:30:00.000Z"`），SQL 用 `DATETIME(3)` UTC |
| delayed 字段 | 所有行情响应必须包含（`true` = 访客延迟15分钟行情） |
| market_status 枚举 | `REGULAR \| PRE_MARKET \| AFTER_HOURS \| CLOSED \| HALTED` |
| WebSocket 消息 | 客户端→服务端用 `"action"` 字段；服务端→客户端用 `"type"` 字段 |
| symbols 上限 | 单次订阅/查询最多 50 个 |
| Watchlist 上限 | 每用户 100 只（应用层检查） |

---

## 待办事项（Phase 1 遗留）

- [ ] `scripts/init_db.sql` 按 v2.0 DDL 更新（新增 pinyin_initials、shares_outstanding 等字段）
- [ ] 新闻数据源确认（Polygon.io 新闻 API 或 Finnhub）— 见 thread [mobile/docs/threads/2026-03-prd-03-market-data-review](../../../../mobile/docs/threads/2026-03-prd-03-market-data-review/_index.md) H4
- [ ] `api/grpc/market_data.proto` 按系统架构 §3.3.1 补全所有消息类型
- [ ] 实现 DelayedQuoteRingBuffer（见 market-data-system.md §4）
- [ ] 实现 `/v1/market/movers` 涨跌幅榜接口
- [ ] 搜索接口补充 pinyin_initials 支持

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v2.0 | 2026-03-14 | 对齐 PRD-03 v1.1：新增访客双轨推送、重写 WebSocket 协议、REST API 路径统一、MySQL DDL 完整化 |
| v1.0 | 2026-03-07 | 初始版本 |
