---
provider: services/market-data
consumer: services/trading-engine
protocol: gRPC + Kafka
proto_file: services/market-data/api/grpc/market_data.proto
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Market Data → Trading Engine 接口契约

## 契约范围

交易引擎需要实时报价进行价格验证和风控检查，同时需获取市场状态以执行交易时段判断。

## 接口列表

| 方法 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|-----|---------|
| GetQuote | 获取指定标的最新报价（bid/ask/last） | gRPC | TBD | v1 |
| GetMarketStatus | 获取市场状态及当前交易时段（盘前/盘中/盘后/休市） | gRPC | TBD | v1 |
| Subscribe `quote.updated` | 实时报价推送（Kafka topic） | Kafka | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体方法签名。

## 数据流向

Market Data 通过 gRPC 同步接口提供按需查询的最新报价和市场状态，同时通过 Kafka topic `quote.updated` 向 Trading Engine 实时推送报价更新，用于下单时的价格验证、预交易风控检查（如涨跌幅限制、价格偏离度）以及交易时段执行控制。

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/grpc/` 或 `api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
