---
provider: services/ams
consumer: services/market-data
protocol: gRPC
proto_file: services/ams/api/grpc/ams.proto
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# AMS → Market Data 接口契约

## 契约范围

WebSocket 连接建立时需要验证用户身份，并确认用户的行情数据访问权限等级（L1/L2），以决定推送的数据深度。

## 接口列表

| 方法 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|-----|---------|
| ValidateToken | JWT 令牌验证，确认 WebSocket 连接用户身份 | gRPC | TBD | v1 |
| GetDataEntitlements | 获取用户行情数据权限等级（L1/L2） | gRPC | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体方法签名。

## 数据流向

AMS 向 Market Data 提供令牌验证结果和数据权限等级信息，用于 WebSocket 网关的连接鉴权以及根据用户权限等级过滤推送的行情数据深度（如 L1 仅 BBO，L2 含完整 Order Book）。

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/grpc/` 或 `api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
