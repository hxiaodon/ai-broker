---
provider: services/ams
consumer: services/fund-transfer
protocol: gRPC
proto_file: services/ams/api/grpc/ams.proto
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# AMS → Fund Transfer 接口契约

## 契约范围

出入金操作前需验证用户 KYC 等级、账户状态及同名账户信息，以确定出入金额度上限并满足合规要求。

## 接口列表

| 方法 | 用途 | 协议 | SLA | 版本引入 |
|------|------|------|-----|---------|
| GetKYCTier | 获取用户 KYC 等级，决定出入金额度上限 | gRPC | TBD | v1 |
| VerifyAccountName | 同名账户验证，确保银行账户与券商账户同名 | gRPC | TBD | v1 |
| GetAccountStatus | 获取账户状态，确认账户可执行出入金操作 | gRPC | TBD | v1 |

> **Note**: 接口列表为初始占位，待各域工程师在实现阶段填充具体方法签名。

## 数据流向

AMS 向 Fund Transfer 提供 KYC 等级和身份验证信息，用于出入金前的合规校验，包括确认用户 KYC 等级对应的额度限制、验证银行账户与券商账户的同名关系、以及确认账户处于允许出入金的状态。

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/grpc/` 或 `api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
