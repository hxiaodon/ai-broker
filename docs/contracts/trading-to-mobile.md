---
provider: services/trading-engine
consumer: mobile
protocol: REST + WebSocket
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Trading Engine → Mobile 接口契约

## 契约范围

移动端交易下单、订单管理、持仓查看、盈亏展示。Trading Engine 为 Flutter 移动客户端提供完整的交易能力，包括订单提交与撤销、订单状态实时推送、持仓与 P&L 查询、以及投资组合概览。

## 接口列表

### REST Endpoints

| 方法 | 路径 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|------|-----|---------|
| POST | /api/v1/orders | 提交订单（需生物识别确认 + HMAC 签名） | REST | TBD | v1 |
| GET | /api/v1/orders | 订单列表（支持按状态、日期、市场筛选） | REST | TBD | v1 |
| GET | /api/v1/orders/:id | 订单详情（含成交明细） | REST | TBD | v1 |
| DELETE | /api/v1/orders/:id | 撤单（仅限 PENDING / OPEN 状态） | REST | TBD | v1 |
| GET | /api/v1/positions | 持仓列表（含实时市值与盈亏） | REST | TBD | v1 |
| GET | /api/v1/positions/:symbol | 单只持仓详情 + P&L 明细 | REST | TBD | v1 |
| GET | /api/v1/portfolio/summary | 组合概览：总资产、日盈亏、持仓分布 | REST | TBD | v1 |

### WebSocket Channels

| Channel | 用途 | 订阅格式 | 推送频率 |
|---------|------|---------|---------|
| `order.status` | 订单状态实时推送（PENDING → FILLED / REJECTED / CANCELLED） | `{"subscribe": "order.status"}` | 事件驱动 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体请求/响应 schema。

## 数据流向

Mobile 提交订单请求（含 symbol、side、qty、price、order type）并接收执行确认。订单状态变更（部分成交、全部成交、拒绝、撤销）通过 WebSocket `order.status` 频道实时推送至客户端。持仓和 P&L 数据通过 REST 按需刷新。

## 认证与安全

- **所有端点均需 JWT Bearer token**
- 订单提交（POST /orders）额外要求：
  - **生物识别认证**（biometric confirmation）
  - **HMAC-SHA256 请求签名**（覆盖 method + path + timestamp + body hash）
  - **时间戳校验**：拒绝 > 30 秒的过期请求（防重放）
- 限速：**10 orders/sec per user**
- **所有金额字段使用 string 编码的 decimal**，禁止浮点数

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`services/trading-engine/api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
