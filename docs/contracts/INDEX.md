---
title: Service Dependency Map & Contract Index
last_updated: 2026-03-13
maintainer: sdd-expert
---

# Service Dependency Map

> **读者**: 任何需要理解系统全貌的人 — PM、架构师、新工程师、合规审计。
> 不需要读代码，只需要知道"谁依赖谁、通过什么接口、承诺什么 SLA"。

## System Topology

```
                    ┌─────────────────────────────────────────┐
                    │              Clients                     │
                    │  Flutter Mobile / H5 WebView / Admin    │
                    └──────────────────┬──────────────────────┘
                                       │ REST / WebSocket
                                       ▼
                              ┌─────────────────┐
                              │   API Gateway    │
                              └────────┬────────┘
                        ┌──────┬───────┼───────┬──────┐
                        ▼      ▼       ▼       ▼      ▼
                    ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
                    │ AMS  ││Trade ││Market││ Fund ││Admin │
                    │      ││Engine││ Data ││Xfer  ││Panel │
                    └──┬───┘└──┬───┘└──┬───┘└──┬───┘└──────┘
                       │       │       │       │
                       └───────┴───┬───┴───────┘
                                   │
                          MySQL / Redis / Kafka
```

## Service Dependency Graph

```
AMS (Account Management)
 │
 ├──→ Trading Engine     [auth, account status]
 ├──→ Fund Transfer      [KYC tier, account verification]
 ├──→ Market Data        [WebSocket auth]
 └──→ Admin Panel        [user data, KYC queue]

Market Data
 │
 ├──→ Trading Engine     [real-time quotes, price validation]
 └──→ Admin Panel        [market status, stock metadata]

Trading Engine
 │
 ├──→ Fund Transfer      [settlement, buying power]
 └──→ Admin Panel        [orders, positions, risk alerts]

Fund Transfer
 │
 └──→ Admin Panel        [withdrawal queue, reconciliation]

External
 │
 ├──→ Market Data        [Polygon API (US), HKEX feed (HK)]
 └──→ Fund Transfer      [Bank channels (ACH/Wire/FPS)]
```

**箭头方向**: Provider → Consumer（数据/能力的流向）

## Contract Index

| # | Contract | Provider | Consumer | Protocol | Status |
|---|----------|----------|----------|----------|--------|
| 1 | [ams-to-trading](ams-to-trading.md) | AMS | Trading Engine | gRPC | DRAFT |
| 2 | [ams-to-fund](ams-to-fund.md) | AMS | Fund Transfer | gRPC | DRAFT |
| 3 | [ams-to-market-data](ams-to-market-data.md) | AMS | Market Data | gRPC | DRAFT |
| 4 | [market-data-to-trading](market-data-to-trading.md) | Market Data | Trading Engine | gRPC + Kafka | DRAFT |
| 5 | [trading-to-fund](trading-to-fund.md) | Trading Engine | Fund Transfer | gRPC + Kafka | DRAFT |
| 6 | [ams-to-admin](ams-to-admin.md) | AMS | Admin Panel | REST | DRAFT |
| 7 | [trading-to-admin](trading-to-admin.md) | Trading Engine | Admin Panel | REST | DRAFT |
| 8 | [market-data-to-admin](market-data-to-admin.md) | Market Data | Admin Panel | REST | DRAFT |
| 9 | [fund-to-admin](fund-to-admin.md) | Fund Transfer | Admin Panel | REST | DRAFT |

### Status Lifecycle

```
DRAFT → ACTIVE → DEPRECATED
  │                    │
  └─ 接口定义完成、      └─ 被新契约替代，
     双方确认后升级          保留供审计参考
```

## Dependency Rules

1. **无环依赖** — 依赖图必须是 DAG（有向无环图）。如果发现环形依赖，立即开 thread 讨论拆解方案。
2. **AMS 是根节点** — 所有服务都依赖 AMS 的 auth，但 AMS 不依赖任何业务服务。
3. **Admin Panel 是纯消费者** — 只读取其他服务的数据，不提供业务接口给后端服务。
4. **外部依赖隔离** — 外部 API (Polygon, HKEX, Bank) 通过各域内部的 adapter 层隔离，不暴露到契约层。

## Evolution Notes

> 本文件随系统演进而更新。每次新增/变更服务间依赖时，同步更新此索引。
>
> - **新增依赖**: 创建新的契约文件 + 在此表格中添加条目
> - **移除依赖**: 契约状态改为 DEPRECATED，不删除文件
> - **拆分 repo**: 契约原件跟 provider 走，consumer repo 保留 mirror 副本（见 SPEC-ORGANIZATION.md Phase 2-3）
