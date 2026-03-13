---
provider: services/market-data
consumer: mobile
protocol: REST + WebSocket
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Market Data → Mobile 接口契约

## 契约范围

移动端行情展示、K 线图表、股票搜索、自选股管理、实时报价推送。Market Data 为 Flutter 移动客户端提供完整的行情数据能力，包括实时/延时报价、多周期 K 线、股票搜索与详情、用户自选股列表管理、以及市场开收盘状态。

## 接口列表

### REST Endpoints

| 方法 | 路径 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|------|-----|---------|
| GET | /api/v1/quotes/:symbol | 单只股票实时报价（最新价、涨跌幅、成交量） | REST | TBD | v1 |
| GET | /api/v1/quotes/batch | 批量报价（自选股列表，最多 50 只） | REST | TBD | v1 |
| GET | /api/v1/kline/:symbol | K 线数据（支持多周期：1min/5min/15min/30min/1h/1D/1W/1M） | REST | TBD | v1 |
| GET | /api/v1/stocks/search | 股票搜索（按名称、代码模糊匹配，支持 US + HK 市场） | REST | TBD | v1 |
| GET | /api/v1/stocks/:symbol | 股票详情：基本面数据、财报摘要、相关新闻 | REST | TBD | v1 |
| GET | /api/v1/watchlist | 自选股列表（用户维度，含最新报价） | REST | TBD | v1 |
| POST | /api/v1/watchlist | 添加自选（symbol + market） | REST | TBD | v1 |
| DELETE | /api/v1/watchlist/:symbol | 删除自选 | REST | TBD | v1 |
| GET | /api/v1/market/status | 市场状态：开盘 / 收盘 / 休市 / 盘前 / 盘后（US + HK） | REST | TBD | v1 |

### WebSocket Channels

| Channel | 用途 | 订阅格式 | 推送频率 |
|---------|------|---------|---------|
| `quote.realtime` | 实时报价推送，支持多 symbol 订阅/退订 | `{"subscribe": "quote.realtime", "symbols": ["AAPL", "00700"]}` | 逐笔 / 聚合（视行情源） |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体请求/响应 schema。

## 数据流向

Market Data 通过 WebSocket 向已订阅的 Mobile 客户端推送实时报价（最新价、买一卖一、成交量增量）。REST 端点提供报价快照、历史 K 线数据、股票搜索结果、以及股票基本面信息。自选股列表为用户维度，服务端持久化存储。

## 认证与安全

- **市场状态端点** (`/market/status`) 为公开端点，无需认证
- 其余 REST 端点及 **WebSocket 连接均需 JWT Bearer token**（token 由 AMS 签发）
- WebSocket 认证方式：连接时通过 query param 或首条消息传递 token
- 限速：**100 req/sec per IP**（REST），WebSocket 无额外限速
- K 线支持周期：`1min`, `5min`, `15min`, `30min`, `1h`, `1D`, `1W`, `1M`
- 批量报价单次最多 50 个 symbol

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`services/market-data/api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
