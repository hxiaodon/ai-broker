---
provider: services/ams
consumer: services/trading-engine
protocol: gRPC
proto_file: services/ams/api/grpc/ams.proto
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# AMS → Trading Engine 接口契约

## 契约范围

交易域下单前需要调用 AMS 验证用户身份和账户状态，确保用户具备交易权限且不受合规限制（如 PDT 标记）。

## 接口列表

| 方法 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|-----|---------|
| VerifySession | 验证用户 session 有效性 | gRPC | TBD | v1 |
| GetAccountStatus | 获取用户交易权限及账户状态 | gRPC | TBD | v1 |
| CheckAccountRestrictions | 检查账户限制（如 PDT 标记、冻结状态） | gRPC | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体方法签名。

## 数据流向

AMS 向 Trading Engine 提供身份验证令牌、账户状态及账户限制信息，用于下单前的预交易验证（pre-trade validation），包括确认用户 session 有效、账户处于可交易状态、以及是否存在 PDT 等合规限制。

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/grpc/` 或 `api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
