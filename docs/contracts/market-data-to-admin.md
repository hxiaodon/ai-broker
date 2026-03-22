---
provider: services/market-data
consumer: services/admin-panel
protocol: REST
openapi_spec: docs/openapi/market_data/
status: APPROVED
version: 1
created: 2026-03-13
last_updated: 2026-03-22
last_reviewed: 2026-03-22
approved_by: market-data-engineer, admin-panel-engineer
approved_date: 2026-03-22
sync_strategy: provider-owns
---

# Market Data → Admin Panel 接口契约

## 契约范围

Admin Panel 需要查看 Market Data 服务提供的各市场交易状态、数据源健康度信息，以及管理股票元数据（如停牌标记），供运营团队进行市场状态监控和基础数据维护。

## 接口列表

| 端点 | 方法 | 用途 | SLA | 版本引入 |
|------|------|------|-----|---------|
| /admin/market/status | GET | 各市场交易状态（NYSE/NASDAQ/HKEX 开盘、收盘、休市） | < 200ms (P99) | v1 |
| /admin/market/feeds | GET | 数据源健康检查（各 feed 连接状态、延迟、最后更新时间） | < 300ms (P99) | v1 |
| /admin/stocks | GET | 股票元数据列表（支持按市场/状态筛选、分页） | < 500ms (P99) | v1 |
| /admin/stocks/:symbol | PUT | 股票元数据编辑（停牌标记、交易限制、备注） | < 300ms (P99) | v1 |

> **Note**: 端点列表为初始占位，待实现阶段填充具体路径和参数。

## 数据流向

Market Data 作为 Provider，向 Admin Panel 暴露市场状态、数据源健康度和股票元数据管理接口。Admin Panel 运营人员通过这些接口监控各交易所实时状态、排查数据源异常，并在必要时手动更新股票元数据（如标记停牌、设置交易限制）。元数据编辑操作写回 Market Data 服务。

## 访问控制

Admin Panel 所有请求需携带 admin JWT token，额外要求 RBAC 角色验证。
Provider 侧需检查请求来源为 admin-panel 服务且具备对应角色权限。

- 股票元数据编辑 (`PUT /admin/stocks/:symbol`) 需要 `market-ops` 或 `ops-manager` 角色
- 市场状态和数据源健康查看需要 `ops-staff` 及以上角色
- 所有操作记入审计日志

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

### v1 (2026-03-22)
- Initial contract approved
- Defined admin endpoints for market monitoring and stock metadata management
- Established SLA targets (P99 latency) for operational dashboards
- Defined RBAC requirements for ops staff access control
