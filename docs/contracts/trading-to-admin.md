---
provider: services/trading-engine
consumer: services/admin-panel
protocol: REST
status: DRAFT
version: 0
created: 2026-03-13
last_updated: 2026-03-13
last_reviewed: null
sync_strategy: provider-owns
---

# Trading Engine → Admin Panel 接口契约

## 契约范围

Admin Panel 需要监控 Trading Engine 提供的订单状态、全量持仓、风控告警数据，供运营团队进行交易监控、风险管理和合规审查，并支持管理员强制撤单操作。

## 接口列表

| 端点 | 方法 | 用途 | SLA | 版本引入 |
|------|------|------|-----|---------|
| /admin/orders | GET | 订单列表+筛选（按状态/用户/股票/时间范围） | TBD | v1 |
| /admin/orders/:id | GET | 订单详情（含完整生命周期事件、执行记录） | TBD | v1 |
| /admin/positions | GET | 全量持仓（支持按用户/股票/市场筛选） | TBD | v1 |
| /admin/risk/alerts | GET | 风控告警列表（PDT 违规、集中度超限、异常交易） | TBD | v1 |
| /admin/orders/:id/cancel | POST | 管理员强制撤单（需记录原因和操作人） | TBD | v1 |

> **Note**: 端点列表为初始占位，待实现阶段填充具体路径和参数。

## 数据流向

Trading Engine 作为 Provider，向 Admin Panel 暴露订单、持仓、风控告警等监控接口。Admin Panel 运营人员通过这些接口实时监控交易状态、排查异常订单、查看风控告警并在必要时执行强制撤单。强制撤单操作写回 Trading Engine，触发订单取消流程。

## 访问控制

Admin Panel 所有请求需携带 admin JWT token，额外要求 RBAC 角色验证。
Provider 侧需检查请求来源为 admin-panel 服务且具备对应角色权限。

- 强制撤单操作 (`POST /admin/orders/:id/cancel`) 需要 `trading-supervisor` 或 `compliance-officer` 角色
- 风控告警查看需要 `risk-manager` 及以上角色
- 订单和持仓查看需要 `ops-staff` 及以上角色
- 所有操作记入审计日志

## 变更流程

1. 任何一方发起变更 → 在 `docs/threads/` 开 thread
2. 双方评估影响（向后兼容性、SLA、消费方改动量）
3. 达成一致后并行更新：`api/rest/` + 本契约文件 (version +1)
4. Thread 标记 RESOLVED

## Changelog

暂无变更记录。
