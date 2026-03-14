---
type: doc-index
version: v2.0
date: 2026-03-14
---

# Market Data Service — 文档索引

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
