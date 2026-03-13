---
provider: services/trading-engine
consumer: services/fund-transfer
protocol: gRPC + Kafka
proto_file: services/trading-engine/api/grpc/settlement.proto
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Trading Engine → Fund Transfer 接口契约

## 契约范围

清结算完成后交易引擎触发资金划转，同时交易引擎需查询可用购买力以执行下单前的资金校验。

## 接口列表

| 方法 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|-----|---------|
| InitiateSettlement | 发起清结算资金划转 | gRPC | TBD | v1 |
| QuerySettlementStatus | 查询清结算划转状态 | gRPC | TBD | v1 |
| Subscribe `settlement.completed` | 清结算完成事件通知（Kafka topic） | Kafka | TBD | v1 |
| GetBuyingPower | 查询用户可用购买力（含已冻结/未结算资金扣减） | gRPC | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体方法签名。

## 数据流向

Trading Engine 在清结算完成后通过 gRPC 发起资金划转请求，并通过 Kafka topic `settlement.completed` 通知 Fund Transfer 处理后续资金变动；反向地，Trading Engine 在下单前通过 GetBuyingPower 向 Fund Transfer 查询用户可用购买力，用于预交易资金充足性校验。

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/grpc/` 或 `api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
